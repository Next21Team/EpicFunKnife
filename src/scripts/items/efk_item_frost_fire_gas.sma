#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <efk_core>
#include <efk_utils>
#include <object/efk_tornado_utils>

new const PLUGIN[] = "EFK: Frost, Fire & Gas Grenade Items"

new const GAME_TAG[] = EFK_GAME_TAG

const ITEM_FROSTFIRE_PRICE			= 3000
const ITEM_GAS_PRICE				= 3000

const PRESENT_FROSTFIRE_AMMO		= 3
const PRESENT_GAS_AMMO				= 3

new const MODEL_FROST_V[] 			= "models/next21_efk/v_frost_nade_b03.mdl"
new const MODEL_FIRE_V[] 			= "models/next21_efk/v_fire_nade_b03.mdl"
new const MODEL_GAS_V[] 			= "models/next21_efk/v_gas_nade_b02.mdl"
new const MODEL_FROST_P[] 			= "models/next21_efk/p_frost_nade.mdl"
new const MODEL_FIRE_P[] 			= "models/next21_efk/p_fire_nade.mdl"
new const MODEL_GAS_P[] 			= "models/next21_efk/p_gas_nade_r2.mdl"
new const MODEL_FROST_W[] 			= "models/next21_efk/w_frost_nade.mdl"
new const MODEL_GAS_W[] 			= "models/next21_efk/w_gas_nade_r2.mdl"
new const MODEL_WORLD[] 			= "models/next21_efk/frost_nade_wbox.mdl"

new const SOUND_FROST_EXPLOSION[] 	= "next21_efk/frost_explosion.wav"
new const SOUND_FROST_PINPUL[] 		= "next21_efk/frost_fire_pinpul.wav"
new const SOUND_FROST_DEPLOY[] 		= "next21_efk/frost_fire_deploy.wav"
new const SOUND_FIRE_EXPLOSION[] 	= "next21_efk/fire_explosion.wav"
new const SOUND_GAS_PINPUL[] 		= "weapons/stickybomb_pullpin.wav"
new const SOUND_GAS_DEPLOY[] 		= "weapons/stickybomb_red_depoly.wav"

new const SOUND_COUGH1[] 			= "next21_efk/cough1.wav"
new const SOUND_COUGH2[] 			= "next21_efk/cough2.wav"

new const SPRITE_FROST_EXPLOSION[] 	= "sprites/next21_efk/frost_explosion.spr"
new const SPRITE_FIRE_EXPLOSION[] 	= "sprites/next21_efk/fire_eff.spr"

new const MODEL_DEFAULT[]			= "models/w_smokegrenade.mdl"

new const CLASSNAME_FROSTNADE[]		= "weapon_next21_frost_nade_"
new const CLASSNAME_FIRENADE[]		= "weapon_next21_fire_nade_"
new const CLASSNAME_GASNADE[]		= "weapon_next21_gas_nade_"
new const WEAPON_REFERENCE[]		= "weapon_smokegrenade"

new const CLASSNAME_GAS[] 			= "efk_gas"
new const CLASSNAME_SMOKE[]			= "efk_smoke"

new const SPRITES_SMOKE[][] = {
	"sprites/next21_efk/gas_puff_r01.spr",
	"sprites/next21_efk/gas_puff_b01.spr"
}

#define CSW_DUMMY 					2

#define SMOKE_LIVE_TIME				25.0

#define ARMOURY_NADE 				18

#define MAX_AMMO					100

#define FROST_RADIUS				200.0

#define BURN_CYCLES					13

#define FREEZE_MAXCHANCE			100.0
#define FREEZE_MINCHANCE			40.0

#define GAS_DAMAGE 					20.0
#define GAS_ENHANCED_DAMAGE 		30.0
#define GAS_RADIUS 					165.0

#define GAS_DAMAGE_RESTORE_HEAL		10
#define GAS_DAMAGE_RESTORE_DELAY	1.0

new const COLOR_FROST[]	= {FROST_COLOR_R, FROST_COLOR_G, FROST_COLOR_B}
new const COLOR_FIRE[]	= {FIRE_COLOR_R, FIRE_COLOR_G, FIRE_COLOR_B}

new const SZ_INFO_TARGET[]	= "info_target"

#define var_nadetype			var_iuser4

enum _:ViewSeq
{
	VIEW_SEQ_THROW = 3
}

enum _:NadeType
{
	NADE_FROST,
	NADE_FIRE,
	NADE_GAS
}

enum TermoMode
{
	TERMO_FROST,
	TERMO_FIRE
}

enum _:PlayerData
{
	bool:PlrIsAlive,
	PlrTeam,
	PlrDamageRes,
	PlrAmmo[2],
	TermoMode:PlrTermoMode,
	PlrNextSpawn[2]
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_ePlayerData[MAX_PLAYERS][PlayerData], Float:g_fGasDelay[MAX_PLAYERS + 1][2],
	m_usCreateSmoke,
	g_iVFrostModelIndex, g_iVFireModelIndex, g_iVGasModelIndex,
	g_iPFrostModelIndex, g_iPFireModelIndex, g_iPGasModelIndex,
	g_iWFrostModelIndex, g_iWGasModelIndex, g_iWBoxModelIndex,
	sprFrostExplosion, sprFireExplosion, sprLaserbeam, sprShockwave

public plugin_precache()
{
	g_iVFrostModelIndex = engfunc(EngFunc_AllocString, MODEL_FROST_V)
	g_iVFireModelIndex = engfunc(EngFunc_AllocString, MODEL_FIRE_V)
	g_iVGasModelIndex = engfunc(EngFunc_AllocString, MODEL_GAS_V)

	precache_model(MODEL_FROST_V)
	precache_model(MODEL_FIRE_V)
	precache_model(MODEL_GAS_V)

	g_iPFrostModelIndex = engfunc(EngFunc_AllocString, MODEL_FROST_P)
	g_iPFireModelIndex = engfunc(EngFunc_AllocString, MODEL_FIRE_P)
	g_iPGasModelIndex = engfunc(EngFunc_AllocString, MODEL_GAS_P)

	precache_model(MODEL_FROST_P)
	precache_model(MODEL_FIRE_P)
	precache_model(MODEL_GAS_P)

	g_iWFrostModelIndex = precache_model(MODEL_FROST_W)
	g_iWGasModelIndex = precache_model(MODEL_GAS_W)
	g_iWBoxModelIndex = precache_model(MODEL_WORLD)

	precache_sound(SOUND_FROST_EXPLOSION)
	precache_sound(SOUND_FROST_PINPUL)
	precache_sound(SOUND_FROST_DEPLOY)
	precache_sound(SOUND_FIRE_EXPLOSION)
	precache_sound(SOUND_GAS_PINPUL)
	precache_sound(SOUND_GAS_DEPLOY)

	precache_sound(SOUND_COUGH1)
	precache_sound(SOUND_COUGH2)

	sprLaserbeam = precache_model("sprites/laserbeam.spr")
	sprShockwave = precache_model("sprites/shockwave.spr")
	sprFrostExplosion = precache_model(SPRITE_FROST_EXPLOSION)
	sprFireExplosion = precache_model(SPRITE_FIRE_EXPLOSION)

	precache_generic(fmt("sprites/%s.txt", CLASSNAME_FROSTNADE))
	precache_generic(fmt("sprites/%s.txt", CLASSNAME_FIRENADE))
	precache_generic(fmt("sprites/%s.txt", CLASSNAME_GASNADE))

	for (new i; i < sizeof SPRITES_SMOKE; i++)
	{
		engfunc(EngFunc_PrecacheModel, SPRITES_SMOKE[i])
		force_unmodified(force_exactfile, {0, 0, 0}, {0, 0, 0}, SPRITES_SMOKE[i])
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	kc_register_weapon_hud(WEAPON_REFERENCE, CLASSNAME_FROSTNADE)
	kc_register_weapon_hud(WEAPON_REFERENCE, CLASSNAME_FIRENADE)
	kc_register_weapon_hud(WEAPON_REFERENCE, CLASSNAME_GASNADE)

	kc_register_item("ITEM_FROSTFIRE", "BUY_FROSTFIRE", "efk_give_ffnade_item", ITEM_FROSTFIRE_PRICE)
	kc_register_item("ITEM_GAS", "BUY_GAS", "efk_give_gasnade_item", ITEM_GAS_PRICE)

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Pre")
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Post", true)

	RegisterHam(Ham_Item_Deploy, WEAPON_REFERENCE, "fw_ItemDeploy", 1)
	RegisterHam(Ham_Item_CanDeploy, WEAPON_REFERENCE, "fw_ItemCanDeploy")
	RegisterHam(Ham_Item_Holster, WEAPON_REFERENCE, "fw_ItemHolster")
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_REFERENCE, "fw_Item_AddToPlayer", 1)
	RegisterHam(Ham_Weapon_RetireWeapon, WEAPON_REFERENCE, "fw_Item_RetireWeapon", 0)

	RegisterHam(Ham_Spawn, "weaponbox", "fw_WeaponBoxSpawn", true)
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeaponBox")

	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchArmoury")
	RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_REFERENCE, "fw_SecondaryAttack")

	register_clcmd(CLASSNAME_FROSTNADE, "fw_SelectFrost")
	register_clcmd(CLASSNAME_FIRENADE, "fw_SelectFire")
	register_clcmd(CLASSNAME_GASNADE, "fw_SelectGas")

	register_event("TextMsg", "event_NewGame", "a", "2=#Game_Commencing", "2=#Game_will_restart_in")

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
	RegisterHookChain(RG_CGrenade_ExplodeSmokeGrenade, "RG_CGrenade_ExplodeSmokeGrenade_Pre", false)
	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "RG_CBasePlayer_ThrowGrenade_Post", true)

	register_forward(FM_EmitSound, "FM_EmitSound_Pre")
	register_forward(FM_PlaybackEvent, "FM_PlaybackEvent_Pre")

	new iEnt = NULLENT
	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "model", MODEL_DEFAULT)))
	{
		set_entvar(iEnt, var_modelindex, g_iWBoxModelIndex)
		set_entvar(iEnt, var_body, random(2) ? 2 : 0)
	}

	m_usCreateSmoke = engfunc(EngFunc_PrecacheEvent, 1, "events/createsmoke.sc")
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0
	Player[iPlayer][PlrAmmo][0] = 0
	Player[iPlayer][PlrAmmo][1] = 0
	Player[iPlayer][PlrNextSpawn][0] = 0
	Player[iPlayer][PlrNextSpawn][1] = 0
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0
}

public event_NewGame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		Player[i][PlrAmmo][0] = 0
		Player[i][PlrAmmo][1] = 0
		Player[i][PlrNextSpawn][0] = 0
		Player[i][PlrNextSpawn][1] = 0
	}
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		Player[iPlayer][PlrIsAlive] = true

		new iNextSpawnFrost = Player[iPlayer][PlrNextSpawn][0]
		new iNextSpawnGas = Player[iPlayer][PlrNextSpawn][1]

		if (iNextSpawnFrost)
		{
			give_frostfire(iPlayer, iNextSpawnFrost)
			Player[iPlayer][PlrNextSpawn][0] = 0
		}

		if (iNextSpawnGas)
		{
			give_gas(iPlayer, iNextSpawnGas)
			Player[iPlayer][PlrNextSpawn][1] = 0
		}

		Player[iPlayer][PlrDamageRes] = 0
	}
}

public RG_CBasePlayer_PreThink_Pre(iPlayer)
{
	if (!Player[iPlayer][PlrIsAlive])
		return HC_CONTINUE

	if (!Player[iPlayer][PlrDamageRes])
		return HC_CONTINUE

	static Float:fGametime
	fGametime = get_gametime()

	if (g_fGasDelay[iPlayer][0] + 0.1 > fGametime || g_fGasDelay[iPlayer][1] > fGametime)
		return HC_CONTINUE

	if (kc_player_in_burn(iPlayer))
		return HC_CONTINUE

	new Float:fMaxHealth = kc_player_get_maxhealth(iPlayer)
	new Float:fHealth = Float:get_entvar(iPlayer, var_health)
	new iRest = min(Player[iPlayer][PlrDamageRes], GAS_DAMAGE_RESTORE_HEAL)

	if (fHealth + float(iRest) >= fMaxHealth)
	{
		if (fHealth < fMaxHealth)
			set_entvar(iPlayer, var_health, fMaxHealth)
		Player[iPlayer][PlrDamageRes] = 0
	}
	else
	{
		set_entvar(iPlayer, var_health, fHealth + float(iRest))
		Player[iPlayer][PlrDamageRes] -= iRest
		g_fGasDelay[iPlayer][1] = fGametime + GAS_DAMAGE_RESTORE_DELAY
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_Killed_Post(iVictim)
{
	Player[iVictim][PlrIsAlive] = false
	Player[iVictim][PlrAmmo][0] = 0
	Player[iVictim][PlrAmmo][1] = 0
	Player[iVictim][PlrDamageRes] = 0
}

public efk_player_change_team(iPlayer, iTeam)
{
	Player[iPlayer][PlrTeam] = iTeam
}

public fw_ItemDeploy(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (is_nullent(iPlayer))
		return HAM_IGNORED

	new iNadeType = get_entvar(iWeapon, var_nadetype)
	switch (iNadeType)
	{
		case NADE_FROST:
		{
			set_pev(iPlayer, pev_viewmodel, g_iVFrostModelIndex)
			set_pev(iPlayer, pev_weaponmodel, g_iPFrostModelIndex)
			set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][0], AMMO_SMOKEGRENADE)
		}
		case NADE_FIRE:
		{
			set_pev(iPlayer, pev_viewmodel, g_iVFireModelIndex)
			set_pev(iPlayer, pev_weaponmodel, g_iPFireModelIndex)
			set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][0], AMMO_SMOKEGRENADE)
		}
		case NADE_GAS:
		{
			set_pev(iPlayer, pev_viewmodel, g_iVGasModelIndex)
			set_pev(iPlayer, pev_weaponmodel, g_iPGasModelIndex)
			set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][1], AMMO_SMOKEGRENADE)
		}
	}

	return HAM_IGNORED
}

public fw_ItemCanDeploy(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)
	if (!is_nullent(iPlayer) && kc_player_check_game_flag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
	{
		SetHamReturnInteger(0)
		return HAM_OVERRIDE
	}

	return HAM_IGNORED
}

public fw_ItemHolster(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)
	if (!is_nullent(iPlayer) && get_member(iPlayer, m_rgAmmo, AMMO_SMOKEGRENADE) == 0)
		fw_Item_RetireWeapon(iWeapon)
}

public fw_Item_AddToPlayer(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (is_nullent(iPlayer))
		return HAM_IGNORED

	if (Player[iPlayer][PlrAmmo][0])
	{
		set_entvar(iWeapon, var_nadetype, NADE_FROST)
		kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_FROSTNADE)
		Player[iPlayer][PlrTermoMode] = TERMO_FROST
	}
	else
	{
		set_entvar(iWeapon, var_nadetype, NADE_GAS)
		kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_GASNADE)
	}

	return HAM_IGNORED
}

public fw_Item_RetireWeapon(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (is_nullent(iPlayer))
		return HAM_IGNORED

	if (!user_has_weapon(iPlayer, CSW_DUMMY))
		return HAM_IGNORED

	user_has_weapon(iPlayer, CSW_DUMMY, 0)
	set_member(iWeapon, m_flReleaseThrow, -1.0)
	set_member(iPlayer, m_flTimeWeaponIdle, random_float(10.0, 15.0))

	if (get_entvar(iWeapon, var_nadetype) == NADE_GAS)
	{
		set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][0], AMMO_SMOKEGRENADE)
		if (Player[iPlayer][PlrTermoMode] == TERMO_FROST)
		{
			kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_FROSTNADE)
			set_entvar(iWeapon, var_nadetype, NADE_FROST)
		}
		else
		{
			kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_FIRENADE)
			set_entvar(iWeapon, var_nadetype, NADE_FIRE)
		}
	}
	else
	{
		set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][1], AMMO_SMOKEGRENADE)
		kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_GASNADE)
		set_entvar(iWeapon, var_nadetype, NADE_GAS)
	}

	ExecuteHamB(Ham_Item_Deploy, iWeapon)
	return HAM_SUPERCEDE
}

public fw_SecondaryAttack(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	if (get_member(iWeapon, m_flReleaseThrow) > 0)
		return HAM_IGNORED

	static iPlayer, iNadeType
	iPlayer = get_member(iWeapon, m_pPlayer)

	if (is_nullent(iPlayer))
		return HAM_IGNORED

	if (!Player[iPlayer][PlrIsAlive])
		return HAM_IGNORED

	if (get_member(iPlayer, m_flNextAttack) > 0.0)
		return HAM_IGNORED

	iNadeType = get_entvar(iWeapon, var_nadetype)

	if (iNadeType == NADE_FROST)
	{
		Player[iPlayer][PlrTermoMode] = TERMO_FIRE
		kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_FIRENADE)
		set_member(iWeapon, m_flStartThrow, 0.0)
		select_nade(iPlayer, NADE_FIRE)
	}
	else if (iNadeType == NADE_FIRE)
	{
		Player[iPlayer][PlrTermoMode] = TERMO_FROST
		kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_FROSTNADE)
		set_member(iWeapon, m_flStartThrow, 0.0)
		select_nade(iPlayer, NADE_FROST)
	}

	return HAM_IGNORED
}

public fw_SelectFrost(iPlayer)
{
	select_nade(iPlayer, NADE_FROST)
}

public fw_SelectFire(iPlayer)
{
	select_nade(iPlayer, NADE_FIRE)
}

public fw_SelectGas(iPlayer)
{
	select_nade(iPlayer, NADE_GAS)
}

select_nade(iPlayer, iNadeType)
{
	if (!Player[iPlayer][PlrIsAlive])
		return

	new iWeapon = rg_find_weapon_bpack_by_name(iPlayer, WEAPON_REFERENCE)
	if (!iWeapon)
		return

	if (get_member(iWeapon, m_flReleaseThrow) > 0)
		return

	if (get_entvar(iWeapon, var_nadetype) == iNadeType)
		return

	set_entvar(iWeapon, var_nadetype, iNadeType)

	if (iWeapon == get_member(iPlayer, m_pActiveItem))
	{
		fw_ItemDeploy(iWeapon)
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_THROW)
		set_member(iPlayer, m_flNextAttack, 0.75)
	}
	else
		rg_switch_weapon(iPlayer, iWeapon)
}

public fw_WeaponBoxSpawn(iEnt)
{
	new iWeapon = get_entvar(iEnt, var_stealitem)
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	if (get_member(iWeapon, m_iId) != CSW_SMOKEGRENADE)
		return HAM_IGNORED

	set_entvar(iEnt, var_modelindex, g_iWBoxModelIndex)
	set_entvar(iEnt, var_body, get_entvar(iWeapon, var_nadetype))

	return HAM_IGNORED
}

public fw_TouchWeaponBox(iWeaponBox, iOther)
{
	if (!iOther || iOther > MaxClients || get_entvar(iWeaponBox, var_stealowner) == iOther)
		return HAM_IGNORED

	if (get_entvar(iWeaponBox, var_modelindex) != g_iWBoxModelIndex)
		return HAM_IGNORED

	switch (get_entvar(iWeaponBox, var_body))
	{
		case NADE_FROST, NADE_FIRE:
		{
			if (give_frostfire(iOther))
			{
				remove_weaponbox(iWeaponBox)
				return HAM_SUPERCEDE
			}
		}
		case NADE_GAS:
		{
			if (give_gas(iOther))
			{
				remove_weaponbox(iWeaponBox)
				return HAM_SUPERCEDE
			}
		}
	}

	return HAM_IGNORED
}

public fw_TouchArmoury(ent, id)
{
	if (!id || id > MaxClients)
		return HAM_IGNORED

	if (get_pdata_int(ent, 34, 4) != ARMOURY_NADE) //m_iItem
		return HAM_IGNORED

	new iNum = get_pdata_int(ent, 35, 4)

	if (!iNum)
		return HAM_IGNORED

	if (!get_entvar(ent, var_body))
	{
		if (Player[id][PlrAmmo][0] || !give_frostfire(id))
			return HAM_SUPERCEDE
	}
	else
	{
		if (Player[id][PlrAmmo][1] || !give_gas(id))
			return HAM_SUPERCEDE
	}

	set_pdata_int(ent, 35, --iNum, 4)

	if (!iNum)
		set_entvar(ent, var_effects, get_entvar(ent, var_effects) | EF_NODRAW)

	return HAM_SUPERCEDE
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_GAS)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_SMOKE)))
		rg_remove_entity(iEnt)
}

public RG_CGrenade_ExplodeSmokeGrenade_Pre(const iEnt)
{
	if (get_entvar(iEnt, var_modelindex) == g_iWFrostModelIndex)
	{
		if (!get_entvar(iEnt, var_body))
			frost_explode(iEnt)
		else
			fire_explode(iEnt)

		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME)
		set_entvar(iEnt, var_nextthink, get_gametime())
		return HC_SUPERCEDE
	}

	gas_explode(iEnt)
	return HC_CONTINUE
}

public RG_CBasePlayer_ThrowGrenade_Post(const iPlayer, const iGrenade,
	Float:vSrc[3], Float:vThrow[3], Float:fTime, const usEvent)
{
	new iEnt = GetHookChainReturn(ATYPE_INTEGER)
	if (is_nullent(iEnt))
		return HC_CONTINUE

	if (get_member(iGrenade, m_iId) != WEAPON_SMOKEGRENADE)
		return HC_CONTINUE

	new iNadeType = get_entvar(iGrenade, var_nadetype)

	switch (iNadeType)
	{
		case NADE_FROST, NADE_FIRE:
		{
			set_entvar(iEnt, var_modelindex, g_iWFrostModelIndex)
			set_entvar(iEnt, var_body, iNadeType)
			set_entvar(iEnt, var_nextthink, get_gametime() + 10.0)
			set_entvar(iEnt, var_nade_touch, 1)

			new ivColor[3], Float:vColor[3]
			if (iNadeType == NADE_FROST)
				ivColor = COLOR_FROST
			else
				ivColor = COLOR_FIRE
			IVecFVec(ivColor, vColor)

			set_entvar(iEnt, var_renderfx, kRenderFxGlowShell)
	 		set_entvar(iEnt, var_rendercolor, vColor)
	 		set_entvar(iEnt, var_rendermode, kRenderNormal)
	 		set_entvar(iEnt, var_renderamt, 16.0)

			send_msg_TE_BEAMFOLLOW(iEnt, sprLaserbeam, 10, 10, ivColor, 100)

			Player[iPlayer][PlrAmmo][0]--
		}
		case NADE_GAS:
		{
			Player[iPlayer][PlrAmmo][1]--
			set_entvar(iEnt, var_modelindex, g_iWGasModelIndex)
		}
	}

	return HC_CONTINUE
}

public FM_EmitSound_Pre(iEnt, channel, sample[])
{
	if (get_entvar(iEnt, var_modelindex) == g_iWFrostModelIndex &&
		get_entvar(iEnt, var_nade_touch) && contain(sample[8], "grenade_hit") != -1)
	{
		RG_CGrenade_ExplodeSmokeGrenade_Pre(iEnt)
	}
}

public FM_PlaybackEvent_Pre(iFlags, iEntity, iEventindex, Float:fDelay, Float:vOrigin[3], Float:vAngles[3], Float:fParam1, Float:fParam2, iParam1, iParam2, iBparam1, iBparam2)
{
	if (iEventindex == m_usCreateSmoke && !iBparam2)
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

public gas_think(iEnt)
{
	rg_remove_entity(iEnt)
}

public gas_touch(iGasEnt, iOtherEnt)
{
	if (!is_entity_player(iOtherEnt) || !Player[iOtherEnt][PlrIsAlive])
		return

	if (Player[iOtherEnt][PlrTeam] == get_entvar(iGasEnt, var_team))
		return

	new Float:fGameTime = get_gametime()

	if (g_fGasDelay[iOtherEnt][0] > fGameTime)
		return

	if (kc_player_check_game_flag(iOtherEnt, PLGF_IN_UNABILITY))
		return

	g_fGasDelay[iOtherEnt][0] = fGameTime + 1.0

	new Float:vOrigin[3]
	get_entvar(iGasEnt, var_origin, vOrigin)
	send_msg_Damage(0, 10, DMG_SLOWFREEZE, vOrigin, MSG_ONE, _, iOtherEnt)

	new Float:fVelocityModifier = Float:get_member(iOtherEnt, m_flVelocityModifier)
	new Float:fHealth = Float:get_entvar(iOtherEnt, var_health)
	new Float:fDamage = fHealth > kc_player_get_maxhealth(iOtherEnt) ? GAS_ENHANCED_DAMAGE : GAS_DAMAGE

	kc_player_set_death_reason(iOtherEnt, "DEATH_REASON_GAS")
	set_member(iOtherEnt, m_LastHitGroup, HIT_GENERIC)

	ExecuteHamB(Ham_TakeDamage, iOtherEnt, iGasEnt, get_entvar(iGasEnt, var_owner), fDamage, DMG_GENERIC)
	set_member(iOtherEnt, m_flVelocityModifier, fVelocityModifier)

	if (Player[iOtherEnt][PlrIsAlive])
	{
		emit_sound(iOtherEnt, CHAN_VOICE, random(2) ? SOUND_COUGH1 : SOUND_COUGH2, 1.0, ATTN_NORM, 0, PITCH_NORM)
		fDamage = fHealth - Float:get_entvar(iOtherEnt, var_health)
		Player[iOtherEnt][PlrDamageRes] += floatround(fDamage, floatround_floor)
	}
}

public ItemGiveCode:efk_give_ffnade_item(iPlayer, iSenderImpulse)
{
	if (!Player[iPlayer][PlrIsAlive])
	{
		Player[iPlayer][PlrNextSpawn][0]++
		return ITEM_NEXT_SPAWN
	}

	if (Player[iPlayer][PlrAmmo][0] >= MAX_AMMO)
		return ITEM_ALREADY_HAVE

	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		if (!give_frostfire(iPlayer, PRESENT_FROSTFIRE_AMMO))
			return ITEM_NOT_AVAILABLE

		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_FROSTFIRE", PRESENT_FROSTFIRE_AMMO)
	}
	else
	{
		if (!give_frostfire(iPlayer))
			return ITEM_NOT_AVAILABLE
	}

	return ITEM_OK
}

public ItemGiveCode:efk_give_gasnade_item(iPlayer, iSenderImpulse)
{
	if (!Player[iPlayer][PlrIsAlive])
	{
		Player[iPlayer][PlrNextSpawn][1]++
		return ITEM_NEXT_SPAWN
	}

	if (Player[iPlayer][PlrAmmo][1] >= MAX_AMMO)
		return ITEM_ALREADY_HAVE

	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		if (!give_gas(iPlayer, PRESENT_GAS_AMMO))
			return ITEM_NOT_AVAILABLE

		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_GAS", PRESENT_GAS_AMMO)
	}
	else
	{
		if (!give_gas(iPlayer))
			return ITEM_NOT_AVAILABLE
	}

	return ITEM_OK
}

bool:give_frostfire(iPlayer, iNum=1)
{
	new iWeapon = rg_find_weapon_bpack_by_name(iPlayer, WEAPON_REFERENCE)
	if (iWeapon && get_member(iWeapon, m_flReleaseThrow) > 0)
		return false

	Player[iPlayer][PlrAmmo][0] += iNum

	if (!iWeapon)
	{
		rg_give_item(iPlayer, WEAPON_REFERENCE)
		set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][0], AMMO_SMOKEGRENADE)
		return true
	}

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	if (!Player[iPlayer][PlrAmmo][1])
	{
		set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][0], AMMO_SMOKEGRENADE)
		return true
	}

	if (user_has_weapon(iPlayer, CSW_DUMMY))
	{
		if (get_entvar(iWeapon, var_nadetype) != NADE_GAS)
			set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][0], AMMO_SMOKEGRENADE)
		return true
	}

	user_has_weapon(iPlayer, CSW_DUMMY, 1)

	kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE, CLASSNAME_FROSTNADE)

	send_msg_WeaponList(CLASSNAME_GASNADE, 13, 1, -1, -1, 3, 4, CSW_DUMMY, 0, MSG_ONE, _, iPlayer)

	if (get_pdata_int(iPlayer, 509) == 1)
		select_nade(iPlayer, NADE_FROST)

	return true
}

bool:give_gas(iPlayer, iNum=1)
{
	new iWeapon = rg_find_weapon_bpack_by_name(iPlayer, WEAPON_REFERENCE)
	if (iWeapon && get_member(iWeapon, m_flReleaseThrow) > 0)
		return false

	Player[iPlayer][PlrAmmo][1] += iNum

	if (!iWeapon)
	{
		rg_give_item(iPlayer, WEAPON_REFERENCE)
		set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][1], AMMO_SMOKEGRENADE)
		return true
	}

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

	if (!Player[iPlayer][PlrAmmo][0])
	{
		set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][1], AMMO_SMOKEGRENADE)
		return true
	}

 	if (user_has_weapon(iPlayer, CSW_DUMMY))
 	{
 		if (get_entvar(iWeapon, var_nadetype) == NADE_GAS)
			set_member(iPlayer, m_rgAmmo, Player[iPlayer][PlrAmmo][1], AMMO_SMOKEGRENADE)
 		return true
 	}

	user_has_weapon(iPlayer, CSW_DUMMY, 1)

	kc_player_set_weapon_hud(iPlayer, WEAPON_REFERENCE,
		Player[iPlayer][PlrTermoMode] == TERMO_FIRE ? CLASSNAME_FIRENADE : CLASSNAME_FROSTNADE)

	send_msg_WeaponList(CLASSNAME_GASNADE, 13, 1, -1, -1, 3, 4, CSW_DUMMY, 0, MSG_ONE, _, iPlayer)

	if (get_pdata_int(iPlayer, 509) == 1)
		select_nade(iPlayer, NADE_GAS)

	return true
}

frost_explode(iEnt)
{
	new Float:vOrigin[3]
	get_entvar(iEnt, var_origin, vOrigin)

	new Float:vOrigin2[3]
	vOrigin2[0] = vOrigin[0]
	vOrigin2[1] = vOrigin[1]

	vOrigin2[2] = vOrigin[2] + 10.0
	send_msg_TE_EXPLOSION(vOrigin2, sprFrostExplosion, 17, 15, TE_EXPLFLAG_NOSOUND)

	vOrigin2[2] = vOrigin[2] + 385.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vOrigin2, sprShockwave, 0, 0, 4, 60, 0, COLOR_FROST, 100, 0)

	vOrigin2[2] = vOrigin[2] + 470.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vOrigin2, sprShockwave, 0, 0, 4, 60, 0, COLOR_FROST, 100, 0)

	vOrigin2[2] = vOrigin[2] + 555.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vOrigin2, sprShockwave, 0, 0, 4, 60, 0, COLOR_FROST, 100, 0)

	send_msg_TE_DLIGHT(vOrigin, floatround(FROST_RADIUS / 5.0), COLOR_FROST, 8, 60)

	emit_sound(iEnt, CHAN_WEAPON, SOUND_FROST_EXPLOSION, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new iOwner = get_entvar(iEnt, var_owner)
	new iTarget = NULLENT

	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, FROST_RADIUS)))
	{
		if (iTarget > MaxClients)
			break

		get_entvar(iTarget, var_origin, vOrigin2)
		if (random_num(1, 100) <= floatround(radius_calucation(vOrigin2, vOrigin)))
			kc_player_freeze(iTarget, FREEZE_TIME, iOwner)
		else
			kc_player_chill(iTarget, CHILL_TIME, iOwner)
	}
}

fire_explode(iEnt)
{
	new Float:vOrigin[3]
	get_entvar(iEnt, var_origin, vOrigin)

	new Float:vOrigin2[3]
	vOrigin2[0] = vOrigin[0]
	vOrigin2[1] = vOrigin[1]

	vOrigin2[2] = vOrigin[2] + 10.0
	send_msg_TE_EXPLOSION(vOrigin2, sprFireExplosion, 17, 15, TE_EXPLFLAG_NOSOUND)

	vOrigin2[2] = vOrigin[2] + 385.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vOrigin2, sprShockwave, 0, 0, 4, 60, 0, COLOR_FIRE, 100, 0)

	vOrigin2[2] = vOrigin[2] + 470.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vOrigin2, sprShockwave, 0, 0, 4, 60, 0, COLOR_FIRE, 100, 0)

	vOrigin2[2] = vOrigin[2] + 555.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vOrigin2, sprShockwave, 0, 0, 4, 60, 0, COLOR_FIRE, 100, 0)

	send_msg_TE_DLIGHT(vOrigin, floatround(FROST_RADIUS / 5.0), COLOR_FIRE, 12, 60)

	emit_sound(iEnt, CHAN_WEAPON, SOUND_FIRE_EXPLOSION, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new iOwner = get_entvar(iEnt, var_owner)
	new iTarget = NULLENT

	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, FROST_RADIUS)))
	{
		if (is_entity_player(iTarget))
			kc_player_burn(iTarget, iOwner, BURN_CYCLES)
		else if (get_entvar(iTarget, var_impulse) == IMPULSE_TORNADO && Player[iOwner][PlrTeam] == get_entvar(iTarget, var_team))
			tornado_burn(iTarget)
	}
}

gas_explode(iNadeEnt)
{
	new Float:vOrigin[3]
	get_entvar(iNadeEnt, var_origin, vOrigin)

	new iGasEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iGasEnt))
		return

	new iTeam = get_member(iNadeEnt, m_Grenade_iTeam)

	set_entvar(iGasEnt, var_classname, CLASSNAME_GAS)
	set_entvar(iGasEnt, var_solid, SOLID_TRIGGER)

	engfunc(EngFunc_SetOrigin, iGasEnt, vOrigin)
	engfunc(EngFunc_SetSize, iGasEnt,
		Float:{-GAS_RADIUS, -GAS_RADIUS, -GAS_RADIUS},
		Float:{GAS_RADIUS, GAS_RADIUS, GAS_RADIUS})

	set_entvar(iGasEnt, var_origin, vOrigin)
	set_entvar(iGasEnt, var_owner, get_entvar(iNadeEnt, var_owner))
	set_entvar(iGasEnt, var_team, iTeam)
	set_entvar(iGasEnt, var_nextthink, get_gametime() + SMOKE_LIVE_TIME)

	SetThink(iGasEnt, "gas_think")
	SetTouch(iGasEnt, "gas_touch")

	smoke_field_create(vOrigin, iTeam)
}

Float:radius_calucation(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:fDistance = vector_distance(vOrigin1, vOrigin2)
	if (fDistance < 40.0)
		return FREEZE_MAXCHANCE

	new Float:fPercent = 1.0 - fDistance / FROST_RADIUS
	return FREEZE_MINCHANCE + (fPercent * (FREEZE_MAXCHANCE - FREEZE_MINCHANCE))
}

remove_weaponbox(iWeaponBox)
{
	new iWeapon = get_member(iWeaponBox, m_WeaponBox_rgpPlayerItems, CS_WEAPONSLOT_GRENADE)
	if (!is_nullent(iWeapon))
	{
		set_entvar(iWeapon, var_flags, FL_KILLME)
		dllfunc(DLLFunc_Think, iWeapon)
	}
	set_entvar(iWeaponBox, var_flags, FL_KILLME)
	dllfunc(DLLFunc_Think, iWeaponBox)
}

smoke_field_create(Float:vOrigin[3], iTeam)
{
	#define SMOKES_COUNT			10
	#define SMOKE_HEIGHT			60.0
	#define SMOKE_SCALE_BOUNDS		1.4, 1.8
	#define SMOKE_DISTANCE_BOUNDS	50.0, 125.0

	new Float:vSmokeOrigin[3], Float:fDistance
	vSmokeOrigin = vOrigin
	vSmokeOrigin[2] += SMOKE_HEIGHT
	smoke_create(vSmokeOrigin, iTeam, .fScale = random_float(SMOKE_SCALE_BOUNDS))

	for (new i, Float:fAngle; i < SMOKES_COUNT; i++)
	{
		vSmokeOrigin = vOrigin
		fDistance = random_float(SMOKE_DISTANCE_BOUNDS)

		fAngle = (360.0 / SMOKES_COUNT.0) * float(i)
		vSmokeOrigin[0] = vOrigin[0] + floatcos(fAngle, degrees) * fDistance
		vSmokeOrigin[1] = vOrigin[1] + floatsin(fAngle, degrees) * fDistance
		vSmokeOrigin[2] += SMOKE_HEIGHT + random_float(-10.0, 10.0)

		if (is_free_trace(vOrigin, vSmokeOrigin))
			smoke_create(vSmokeOrigin, iTeam, .fScale = random_float(SMOKE_SCALE_BOUNDS))
	}
}

smoke_create(Float:vOrigin[3], iTeam, Float:fLiveTime=SMOKE_LIVE_TIME, Float:fAlpha=255.0, Float:fScale=1.0, Float:fFadeTime=-1.0)
{
	new iSmoke = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iSmoke))
		return NULLENT

	engfunc(EngFunc_SetOrigin, iSmoke, vOrigin)
	engfunc(EngFunc_SetModel, iSmoke, SPRITES_SMOKE[iTeam == 2])

	new Float:fGameTime = get_gametime()
	set_entvar(iSmoke, var_rendermode, kRenderTransAlpha)
	set_entvar(iSmoke, var_renderamt, fAlpha)
	set_entvar(iSmoke, var_scale, fScale)
	set_entvar(iSmoke, var_health, fGameTime + fLiveTime)
	set_entvar(iSmoke, var_animtime, fFadeTime == -1.0 ? random_float(5.0, 2.0) : fFadeTime)
	set_entvar(iSmoke, var_classname, CLASSNAME_SMOKE)
	set_entvar(iSmoke, var_nextthink, fGameTime)

	SetThink(iSmoke, "smoke_think")

	return iSmoke
}

public smoke_think(iSmoke)
{
	new Float:fDeathTime = Float:get_entvar(iSmoke, var_health)
	new Float:fFadeTime = Float:get_entvar(iSmoke, var_animtime)
	new Float:fGameTime = get_gametime()

	if (fGameTime > fDeathTime)
	{
		rg_remove_entity(iSmoke)
		return HC_CONTINUE
	}
	else if (fGameTime > fDeathTime - fFadeTime)
	{
		new Float:fFadePercent = (fDeathTime - fGameTime) / fFadeTime
		set_entvar(iSmoke, var_renderamt, 255.0 * fFadePercent)
	}

	new Float:vAngles[3]
	get_entvar(iSmoke, var_angles, vAngles)
	vAngles[random(3)] += 0.1
	set_entvar(iSmoke, var_angles, vAngles)

	set_entvar(iSmoke, var_nextthink, fGameTime + 0.01)

	return HC_CONTINUE
}

bool:is_free_trace(Float:vStart[3], Float:vEnd[3], iFlags=IGNORE_MONSTERS, iIgnoreEnt=0)
{
	new iTrace = create_tr2(), Float:fFraction
	engfunc(EngFunc_TraceLine, vStart, vEnd, iFlags, iIgnoreEnt, iTrace)
	get_tr2(iTrace, TR_flFraction, fFraction)
	free_tr2(iTrace)

	return fFraction == 1.0
}
