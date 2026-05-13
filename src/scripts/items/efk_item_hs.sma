#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Headshots Protection Item"

new const GAME_TAG[] = EFK_GAME_TAG

const ITEM_BUY_SHOTS	= 1
const ITEM_PRIZE_SHOTS	= 5
const ITEM_PRICE		= 3000

new g_iItemId

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iItemId = kc_register_item("ITEM_HS", "BUY_HS", "efk_give_item", ITEM_PRICE, .iFlags=ITMF_INVENTORY|ITMF_MENU_REDRAW)
	if (g_iItemId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
}

public fw_TraceAttack(const iVictim, const iAttacker, const Float:fDamage, const Float:vDir[3], const iTraceId, const DMG_BYTES)
{
	if (get_tr2(iTraceId, TR_iHitgroup) != HIT_HEAD || get_user_team(iVictim) == get_user_team(iAttacker))
		return HAM_IGNORED

	new iValue = kc_player_get_item_value(iVictim, g_iItemId)
	if (iValue <= 0)
		return HAM_IGNORED

	if (!kc_player_item_get_enabled(iVictim, g_iItemId))
		return HAM_IGNORED

	if (kc_player_check_game_flag(iVictim, PLGF_IS_DISABLED_INVENTORY))
		return HAM_IGNORED

	new CaptureType:iCaptureType = kc_player_get_capture(iVictim)
	if (iCaptureType == CAPTURE_NORMAL || iCaptureType == CAPTURE_STRONG)
		return HAM_IGNORED

	set_tr2(iTraceId, TR_iHitgroup, HIT_CHEST)

	iValue--
	if (iValue <= 0)
	{
		client_print_color(iVictim, print_team_default, "^4[%s] ^1%L", GAME_TAG, iVictim, "PHS_OVER")
		kc_player_set_item_value(iVictim, g_iItemId, -1)
	}
	else
		kc_player_set_item_value(iVictim, g_iItemId, iValue)

	return HAM_IGNORED
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		give_hs(iPlayer, ITEM_PRIZE_SHOTS)

		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_HS", ITEM_PRIZE_SHOTS)
	}
	else
	{
		give_hs(iPlayer, ITEM_BUY_SHOTS)
	}

	return ITEM_OK
}

give_hs(iPlayer, iValue)
{
	new iCurrValue = kc_player_get_item_value(iPlayer, g_iItemId)
	if (iCurrValue == -1)
	{
		iCurrValue = 0
		kc_player_item_set_enabled(iPlayer, g_iItemId, true)
	}

	kc_player_set_item_value(iPlayer, g_iItemId, iCurrValue + iValue)

	if (is_user_alive(iPlayer) && kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 0, 220}, 100, MSG_ONE, _, iPlayer)
}
