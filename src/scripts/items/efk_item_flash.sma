#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Flash Grenade Item"

new const GAME_TAG[] = EFK_GAME_TAG

const ITEM_MAX_AMMO 	= 100
const ITEM_PRICE		= 3500

new const MODEL_V_NADE[]	= "models/next21_efk/v_flashbang_b02.mdl"
new const MODEL_P_NADE[]	= "models/next21_efk/p_flashbang.mdl"
new const MODEL_W_NADE[]	= "models/next21_efk/w_flashbang.mdl"

new const SPRITE_LIGHT[]	= "sprites/next21_efk/flashbang_light.spr"

new WEAPON_REFERENCE[]		= "weapon_flashbang"
new CLASSNAME_FLASHNADE[]	= "weapon_next21_flash_nade_"

new const SZ_WEAPONBOX[]	= "weaponbox"

new g_iNextSpawnGive[MAX_PLAYERS + 1],
	g_pSprLight, g_pVModel, g_pPModel, g_iBoxModelIndex

public plugin_precache()
{
	g_pVModel = engfunc(EngFunc_AllocString, MODEL_V_NADE)
	g_pPModel = engfunc(EngFunc_AllocString, MODEL_P_NADE)
	precache_model(MODEL_V_NADE)
	precache_model(MODEL_P_NADE)
	g_iBoxModelIndex = precache_model(MODEL_W_NADE)

	g_pSprLight = precache_model(SPRITE_LIGHT)

	precache_generic(fmt("sprites/%s.txt", CLASSNAME_FLASHNADE))
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	new iItemId = kc_register_item("ITEM_FLASH", "BUY_FLASH", "efk_give_item", ITEM_PRICE)
	if (iItemId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_weapon_hud(WEAPON_REFERENCE, CLASSNAME_FLASHNADE)

	register_event("TextMsg", "event_NewGame", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)

	RegisterHam(Ham_Item_AddToPlayer, WEAPON_REFERENCE, "Ham_Nade_AddToPlayer_Post", true)
	RegisterHam(Ham_Item_Deploy, WEAPON_REFERENCE, "Ham_Nade_Deploy_Post", true)
	RegisterHam(Ham_Item_CanDeploy, WEAPON_REFERENCE, "Ham_Nade_CanDeploy_Pre")

	RegisterHam(Ham_Spawn, SZ_WEAPONBOX, "Ham_WeaponBox_Spawn_Post", true)
	RegisterHam(Ham_Touch, SZ_WEAPONBOX, "Ham_WeaponBox_Touch_Pre")

	RegisterHookChain(RG_CGrenade_ExplodeFlashbang, "RG_CGrenade_ExplodeFlashbang_Pre")
	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "RG_CBasePlayer_ThrowGrenade_Post", true)
	RegisterHookChain(RG_PlayerBlind, "RG_PlayerBlind_Pre")

	new iEnt = NULLENT
	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "model", "models/w_flashbang.mdl")))
		set_entvar(iEnt, var_modelindex, g_iBoxModelIndex)
}

public client_putinserver(iPlayer)
{
	g_iNextSpawnGive[iPlayer] = 0
}

public event_NewGame()
{
	arrayset(g_iNextSpawnGive, 0, sizeof g_iNextSpawnGive)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (g_iNextSpawnGive[iPlayer] && is_user_alive(iPlayer))
	{
		add_flashbang(iPlayer, g_iNextSpawnGive[iPlayer])
		g_iNextSpawnGive[iPlayer] = 0
	}
}

public Ham_Nade_AddToPlayer_Post(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)
	if (!is_nullent(iPlayer))
	{
		kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_FLASHNADE)
	}
}

public Ham_Nade_Deploy_Post(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)
	if (!is_nullent(iPlayer))
	{
		set_pev(iPlayer, pev_viewmodel, g_pVModel)
		set_pev(iPlayer, pev_weaponmodel, g_pPModel)
	}
}

public Ham_Nade_CanDeploy_Pre(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)
	if (!is_nullent(iPlayer) && kc_player_check_game_flag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
	{
		SetHamReturnInteger(false)
		return HAM_OVERRIDE
	}

	return HAM_IGNORED
}

public RG_CGrenade_ExplodeFlashbang_Pre(iEnt, pTraceHandle, iFlags)
{
	new Float:vOrigin[3]
	get_entvar(iEnt, var_origin, vOrigin)

	send_msg_TE_EXPLOSION(vOrigin, g_pSprLight, random_num(8, 16), 3,
		TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES,
		MSG_PVS, vOrigin)

	send_msg_TE_DLIGHT(vOrigin, 40, {255, 255, 255}, 8, 60)
}

public Ham_WeaponBox_Spawn_Post(iEnt)
{
	new iWeapon = get_entvar(iEnt, var_stealitem)
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	if (get_member(iWeapon, m_iId) != CSW_FLASHBANG)
		return HAM_IGNORED

	set_entvar(iEnt, var_modelindex, g_iBoxModelIndex)
	return HAM_IGNORED
}

public Ham_WeaponBox_Touch_Pre(iWeaponBox, iOther)
{
	if (!is_user_alive(iOther) || get_entvar(iWeaponBox, var_stealowner) == iOther)
		return HAM_IGNORED

	if (get_entvar(iWeaponBox, var_modelindex) == g_iBoxModelIndex)
	{
		add_flashbang(iOther)

		new iWeapon = get_member(iWeaponBox, m_WeaponBox_rgpPlayerItems, GRENADE_SLOT)
		if (!is_nullent(iWeapon))
		{
			set_entvar(iWeapon, var_flags, FL_KILLME)
			dllfunc(DLLFunc_Think, iWeapon)
		}
		set_entvar(iWeaponBox, var_flags, FL_KILLME)
		dllfunc(DLLFunc_Think, iWeaponBox)

		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public RG_CBasePlayer_ThrowGrenade_Post(const iPlayer, const iWeapon, Float:vSrc[3], Float:vThrow[3], Float:fTime, const usEvent)
{
	new iEnt = GetHookChainReturn(ATYPE_INTEGER)
	if (!is_nullent(iEnt) && get_member(iWeapon, m_iId) == CSW_FLASHBANG)
		set_entvar(iEnt, var_modelindex, g_iBoxModelIndex)
}

public RG_PlayerBlind_Pre(const iPlayer, const iInflictor, const iAttacker, const Float:fFadeTime, const Float:fFadeHold, const iAlpha, Float:vColor[3])
{
	if (!is_user_connected(iAttacker) || get_member(iPlayer, m_iTeam) != get_member(iAttacker, m_iTeam))
		kc_player_blind(iPlayer, 1, fFadeHold)

	return HC_SUPERCEDE
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (!is_user_alive(iPlayer))
	{
		g_iNextSpawnGive[iPlayer]++
		return ITEM_NEXT_SPAWN
	}

	if (get_member(iPlayer, m_rgAmmo, AMMO_FLASHBANG) >= ITEM_MAX_AMMO)
		return ITEM_ALREADY_HAVE

	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_FLASH")
	}

	add_flashbang(iPlayer)
	return ITEM_OK
}

add_flashbang(iPlayer, iNum=1)
{
	new iAmmo = get_member(iPlayer, m_rgAmmo, AMMO_FLASHBANG)
	if (user_has_weapon(iPlayer, CSW_FLASHBANG))
		emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	else
		rg_give_item(iPlayer, WEAPON_REFERENCE)
	set_member(iPlayer, m_rgAmmo, iAmmo + iNum, AMMO_FLASHBANG)
}
