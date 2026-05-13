#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Vampirizm Item"

new const GAME_TAG[] = EFK_GAME_TAG

new const MODEL_V_MASK[]	= "models/next21_efk/v_vampmask_b02.mdl"
new const MODEL_CELLS[]		= "models/next21_efk/vampmask_cells.mdl"

const ITEM_MAX_HP	= 350
const ITEM_PRICE	= 15000

#define WEAR_TIME			0.7

enum _:ViewSeq
{
	VIEW_SEQ_WAER = 1
}

new Float:g_fWearTime[MAX_PLAYERS + 1],
	g_iItemId, g_pVModel, g_iMaskCells,
	bool:g_bIsRoundEnded

public plugin_precache()
{
	g_iMaskCells = precache_model(MODEL_CELLS)
	g_pVModel = engfunc(EngFunc_AllocString, MODEL_V_MASK)
	precache_model(MODEL_V_MASK)
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iItemId = kc_register_item("ITEM_VAMPIRISM", "BUY_VAMPIRISM", "efk_give_item", ITEM_PRICE, .iFlags=ITMF_INVENTORY)
	if (g_iItemId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Pre")

	RegisterHam(Ham_TakeDamage, "player", "Ham_Player_TakeDamage_Post", true)

	register_event("TextMsg", "event_NewGame", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")
	register_logevent("logevent_RoundStart", 2, "1=Round_Start")
	register_logevent("logevent_RoundEnd", 2, "1=Round_End")
	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")
}

public client_putinserver(iPlayer)
{
	g_fWearTime[iPlayer] = 0.0
}

public event_NewGame()
{
	arrayset(g_fWearTime, 0.0, sizeof g_fWearTime)
}

public logevent_RoundStart()
{
	g_bIsRoundEnded = false
}

public logevent_RoundEnd()
{
	g_bIsRoundEnded = true
}

public event_CurWeapon(iPlayer)
{
	if (g_fWearTime[iPlayer] > 0.0)
	{
		g_fWearTime[iPlayer] = 0.0
		client_print(iPlayer, print_center, "%L", iPlayer, "ITEM_CASHBACK")
		rg_add_account(iPlayer, ITEM_PRICE)
	}
}

public RG_CBasePlayer_PreThink_Pre(iPlayer)
{
	if (g_fWearTime[iPlayer] > 0.0)
	{
		if (!is_user_alive(iPlayer))
		{
			g_fWearTime[iPlayer] = 0.0
			client_print(iPlayer, print_center, "%L", iPlayer, "ITEM_CASHBACK")
			rg_add_account(iPlayer, ITEM_PRICE)
			return HC_CONTINUE
		}

		if (g_fWearTime[iPlayer] <= get_gametime())
		{
			new iItem = get_member(iPlayer, m_pActiveItem)
			if (!is_nullent(iItem))
				ExecuteHamB(Ham_Item_Deploy, iItem)

			create_mask_cells(iPlayer)

			give_vamp(iPlayer, ITEM_MAX_HP)
			g_fWearTime[iPlayer] = 0.0
		}
	}

	return HC_CONTINUE
}

public Ham_Player_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (!iInflictor || !is_user_alive(iAttacker))
		return HAM_IGNORED

	new iValue = kc_player_get_item_value(iAttacker, g_iItemId)
	if (iValue <= 0)
		return HAM_IGNORED

	if (!kc_player_item_get_enabled(iAttacker, g_iItemId))
		return HAM_IGNORED

	if (kc_player_check_game_flag(iAttacker, PLGF_IS_DISABLED_INVENTORY))
		return HAM_IGNORED

	if (!(iFlags & DMG_BULLET))
		return HAM_IGNORED

	if (get_user_weapon(iAttacker) != CSW_KNIFE)
		return HAM_IGNORED

	// non-blocking damage modes must be removed
	if (kc_player_get_capture(iVictim) != CAPTURE_NONE)
		return HAM_IGNORED

	new Float:fMaxHelath = MAX_PLAYER_HEALTH
	if (kc_player_get_options(iAttacker) & OPTION_LIMITED_VAMP)
		fMaxHelath = Float:get_entvar(iAttacker, var_max_health)

	new Float:fHealth = Float:get_entvar(iAttacker, var_health)
	if (fHealth >= fMaxHelath)
		return HAM_IGNORED

	new Float:fVamp = floatmin(50.0, fDamage * 0.25)

	if (fHealth + fVamp > fMaxHelath)
	{
		set_entvar(iAttacker, var_health, fMaxHelath)
		iValue -= floatround(fMaxHelath - fHealth)
		kc_player_set_item_value(iAttacker, g_iItemId, iValue)
	}
	else
	{
		set_entvar(iAttacker, var_health, fHealth + fVamp)
		iValue -= floatround(fVamp)
		kc_player_set_item_value(iAttacker, g_iItemId, iValue)
	}

	if (iValue <= 0)
	{
		client_print(iAttacker, print_center, "%L", iAttacker, "VAMPIRISM_EXHAUSTED")
		kc_player_set_item_value(iAttacker, g_iItemId, -1)
	}

	return HAM_IGNORED
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		if (kc_player_get_item_value(iPlayer, g_iItemId) > 0)
			return ITEM_ALREADY_HAVE

		give_vamp(iPlayer, ITEM_MAX_HP)

		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_VAMPIRISM")

		return ITEM_OK
	}

	if (iSenderImpulse != iPlayer || !is_user_alive(iPlayer))
	{
		give_vamp(iPlayer, ITEM_MAX_HP)
		return ITEM_OK
	}

	if (g_bIsRoundEnded)
		return ITEM_NOT_AVAILABLE

	if (Float:get_member(iPlayer, m_flNextAttack) > 0.0)
		return ITEM_NOT_AVAILABLE

	if (kc_player_get_capture(iPlayer) != CAPTURE_NONE)
		return ITEM_NOT_AVAILABLE

	new VisibilityType:iVisibility = kc_player_get_visibility(iPlayer)
	if (iVisibility >= VIS_TRANS && iVisibility != VIS_CLONE)
		return ITEM_NOT_AVAILABLE

	set_pev(iPlayer, pev_viewmodel, g_pVModel)
	kc_player_set_view_anim(iPlayer, VIEW_SEQ_WAER)

	if (get_member(iPlayer, m_iFOV) != 90)
	{
		set_member(iPlayer, m_iFOV, 90)
		set_member(iPlayer, m_iClientFOV, 90)
		set_entvar(iPlayer, var_fov, 90.0)
		send_msg_SetFOV(90, MSG_ONE, _, iPlayer)
	}

	set_member(iPlayer, m_flNextAttack, WEAR_TIME)

	new iItem = get_member(iPlayer, m_pActiveItem)
	if (!is_nullent(iItem))
		set_member(iItem, m_Weapon_flTimeWeaponIdle, WEAR_TIME)

	g_fWearTime[iPlayer] = get_gametime() + WEAR_TIME

	return ITEM_OK
}

give_vamp(iPlayer, iValue)
{
	if (is_user_alive(iPlayer) && kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 0, 0}, 100, MSG_ONE, _, iPlayer)

	new iCurrValue = kc_player_get_item_value(iPlayer, g_iItemId)
	if (iCurrValue == -1)
	{
		iCurrValue = 0
		kc_player_item_set_enabled(iPlayer, g_iItemId, true)
	}

	kc_player_set_item_value(iPlayer, g_iItemId, iCurrValue + iValue)
	client_print(iPlayer, print_center, "%L", iPlayer, "VAMPIRISM_CHARGE", iValue)
}

create_mask_cells(iPlayer)
{
	new Float:vOrigin[3], Float:vAngles[3], Float:vVelocity[3]
	engfunc(EngFunc_GetBonePosition, iPlayer, 7, vOrigin, vAngles)
	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vVelocity)
	vVelocity[0] *= 30.0
	vVelocity[1] *= 30.0
	vVelocity[2] *= 30.0

	send_msg_TE_BREAKMODEL(vOrigin, Float:{12.0, 12.0, 12.0}, vVelocity, 3, g_iMaskCells, 5, 50, BREAK_2)
}
