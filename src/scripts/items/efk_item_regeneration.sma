#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Regeneration Item"

new const GAME_TAG[] = EFK_GAME_TAG

new const MODEL_V_STIMPAK[]	= "models/next21_efk/v_stimpak_b02.mdl"
new const SOUND_STIMPAK[]	= "next21_efk/stimpak_inject.wav"

const ITEM_PRICE		= 15000
const ITEM_REGEN_VALUE	= 300

#define STIMPAK_TIME		2.5

enum _:ViewSeq
{
	VIEW_SEQ_USE
}

new g_iItemId, g_iVActId, g_pVModel, bool:g_bIsRoundEnded

public plugin_precache()
{
	g_pVModel = engfunc(EngFunc_AllocString, MODEL_V_STIMPAK)
	precache_model(MODEL_V_STIMPAK)
	precache_sound(SOUND_STIMPAK)
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iItemId = kc_register_item("ITEM_REGENERATION", "BUY_REGENERATION", "efk_give_item", ITEM_PRICE, .iFlags=ITMF_INVENTORY)
	g_iVActId = kc_register_view_action("efk_vact_item")
	if (g_iItemId < 0 || g_iVActId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	register_logevent("logevent_RoundStart", 2, "1=Round_Start")
	register_logevent("logevent_RoundEnd", 2, "1=Round_End")
}

public logevent_RoundStart()
{
	g_bIsRoundEnded = false
}

public logevent_RoundEnd()
{
	g_bIsRoundEnded = true
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		give_regen(iPlayer, ITEM_REGEN_VALUE)

		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_REGENERATION")

		return ITEM_OK
	}

	if (iSenderImpulse != iPlayer || !is_user_alive(iPlayer))
	{
		give_regen(iPlayer, ITEM_REGEN_VALUE)
		return ITEM_OK
	}

	if (g_bIsRoundEnded)
		return ITEM_NOT_AVAILABLE

	if (Float:get_member(iPlayer, m_flNextAttack) > 0.0)
		return ITEM_NOT_AVAILABLE

	if (kc_player_check_game_flag(iPlayer, PLGF_IN_HAMMER_RETURNING))
		return ITEM_NOT_AVAILABLE

	if (!kc_player_set_view_action(iPlayer, g_iVActId, STIMPAK_TIME, g_pVModel, VIEW_SEQ_USE))
		return ITEM_NOT_AVAILABLE

	return ITEM_OK
}

public efk_vact_item(iPlayer, bool:bComplete)
{
	if (bComplete)
	{
		new iItem = get_member(iPlayer, m_pActiveItem)
		if (!is_nullent(iItem))
			ExecuteHamB(Ham_Item_Deploy, iItem)

		give_regen(iPlayer, ITEM_REGEN_VALUE)
	}
	else
	{
		client_print(iPlayer, print_center, "%L", iPlayer, "ITEM_CASHBACK")
		rg_add_account(iPlayer, ITEM_PRICE)
	}
}

give_regen(iPlayer, iValue)
{
	if (is_user_alive(iPlayer) && kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {0, 255, 0}, 25, MSG_ONE, _, iPlayer)

	new iCurrValue = kc_player_get_item_value(iPlayer, g_iItemId)
	if (iCurrValue == -1)
	{
		iCurrValue = 0
		kc_player_item_set_enabled(iPlayer, g_iItemId, true)
	}

	kc_player_set_item_value(iPlayer, g_iItemId, iCurrValue + iValue)
	client_print(iPlayer, print_center, "%L", iPlayer, "REGENERATION_CHARGE", iValue)
}
