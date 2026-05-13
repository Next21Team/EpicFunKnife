#include <amxmodx>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Charge Booster Item"

new const GAME_TAG[] = EFK_GAME_TAG

const ITEM_BUY_VALUE	= 1
const ITEM_PRIZE_VALUE	= 15
const ITEM_PRICE		= 1000

new g_iItemId

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iItemId = kc_register_item("ITEM_CHARGEBOOSTER", "BUY_CHARGEBOOSTER", "efk_give_item", ITEM_PRICE, .iFlags=ITMF_INVENTORY|ITMF_MENU_REDRAW)
	if (g_iItemId < 0)
		set_fail_state("[%s] error registration", PLUGIN)
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		add_charge_booster(iPlayer, ITEM_PRIZE_VALUE)

		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_CHARGEBOOSTER", ITEM_PRIZE_VALUE)
	}
	else
	{
		add_charge_booster(iPlayer, ITEM_BUY_VALUE)
	}

	return ITEM_OK
}

add_charge_booster(iPlayer, iValue)
{
	new iCurrValue = kc_player_get_item_value(iPlayer, g_iItemId)
	if (iCurrValue == -1)
	{
		iCurrValue = 0
		kc_player_item_set_enabled(iPlayer, g_iItemId, true)
	}

	kc_player_set_item_value(iPlayer, g_iItemId, iCurrValue + iValue)

	if (is_user_alive(iPlayer) && kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {178, 0, 255}, 100, MSG_ONE, _, iPlayer)
}
