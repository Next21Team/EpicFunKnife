#include <amxmodx>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Crit Protection Item"

new const GAME_TAG[] = EFK_GAME_TAG

const ITEM_BUY_ANTICRITS 	= 1
const ITEM_PRIZE_ANTICRITS 	= 6
const ITEM_PRICE 			= 3000

#define CHECK_PRESENT_CHANCE	(!random(2))

new g_iItemId

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iItemId = kc_register_item("ITEM_CRITS", "BUY_CRITS", "efk_give_item", ITEM_PRICE, .iFlags=ITMF_INVENTORY|ITMF_MENU_REDRAW)
	if (g_iItemId < 0)
		set_fail_state("[%s] error registration", PLUGIN)
}

public efk_preuse_crit(iVictim, iAttacker)
{
	new iValue = kc_player_get_item_value(iVictim, g_iItemId)
	if (iValue <= 0)
		return PLUGIN_CONTINUE

	if (kc_player_check_game_flag(iVictim, PLGF_IS_DISABLED_INVENTORY))
		return PLUGIN_CONTINUE

	if (!kc_player_item_get_enabled(iVictim, g_iItemId))
		return PLUGIN_CONTINUE

	iValue--
	if (iValue <= 0)
	{
		client_print_color(iVictim, print_team_default, "^4[%s] ^1%L", GAME_TAG, iVictim, "PCRIT_OVER")
		kc_player_set_item_value(iVictim, g_iItemId, -1)
	}
	else
	{
		kc_player_set_item_value(iVictim, g_iItemId, iValue)
	}

	return PLUGIN_HANDLED
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		if (!CHECK_PRESENT_CHANCE)
			return ITEM_NOT_AVAILABLE

		give_crits(iPlayer, ITEM_PRIZE_ANTICRITS)

		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_CRITS", ITEM_PRIZE_ANTICRITS)

		return ITEM_OK
	}
	else
	{
		give_crits(iPlayer, ITEM_BUY_ANTICRITS)
	}

	return ITEM_OK
}

give_crits(iPlayer, iValue)
{
	new iCurrValue = kc_player_get_item_value(iPlayer, g_iItemId)
	if (iCurrValue == -1)
	{
		iCurrValue = 0
		kc_player_item_set_enabled(iPlayer, g_iItemId, true)
	}

	kc_player_set_item_value(iPlayer, g_iItemId, iCurrValue + iValue)

	if (is_user_alive(iPlayer) && kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 216, 0}, 100, MSG_ONE, _, iPlayer)

	return iValue
}
