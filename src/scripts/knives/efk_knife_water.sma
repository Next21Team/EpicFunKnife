#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Water Knife"

#define KNIFE_CLASSNAME "weapon_next21_water_r01"
#define KNIFE_MENUDESC  "KNIFE_WATER_DESC"
#define KNIFE_CHATDESC  "KNIFE_WATER_CHAT"

#define HP				95.0
#define GRAVITY			1.0
#define SPEED			260.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL     1

#define ABIL1_NAME		"Water"
#define ABIL1_CHARGE	8.334
#define ABIL1_TYPE		ABIL_TARGET_FRIEND
#define ABIL1_MINDIST	75.0
#define ABIL1_MAXDIST	1300.0

#define ABIL2_NAME		"Dragon Guard"
#define ABIL2_CHARGE	8.334

#define ABIL3_NAME		"Aqua Sphere"
#define ABIL3_CHARGE	4.0

#define DRAGON_GUARD_DAMAGE			15.0
#define DRAGON_GUARD_KNOCKBACK_XY	500.0
#define DRAGON_GUARD_KNOCKBACK_Z	550.0
#define DRAGON_GUARD_DISTANCE		100.0
#define DRAGON_GUARD_LIFETIME		7.0
new const DRAGON_GUARD_ICON[] = "vipsafety"

#define EMBODIMENT_SPEED        500.0
#define EMBODIMENT_RADIUS       340.0
#define EMBODIMENT_HEALTH       6.0
#define EMBODIMENT_DAMAGE       7.0

#define WATER_SPHERE_LIFETIME	    12.0
#define WATER_SPHERE_REGEN_HP       1.0
#define WATER_SPHERE_REGEN_DELAY    0.4

new const WATER_SPHERE_TNAME[] = "next21_watersphere"

#define var_dg_lifetime        var_fuser2

#define var_emb_touches        var_iuser2
#define var_emb_dir            var_iuser3

#define TASK_RESTOREAIR			100
#define TASK_DRAGONGUARD		200
#define TASK_WATERSPHERE		1000

#define AIRTIME                 12.0

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_ABILITY_START,
	VIEW_SEQ_ABILITY_END,
	VIEW_SEQ_ABILITY_IDLE = 8,
	VIEW_SEQ_ABILITY_USE
}

new const MODEL_V_KNIFE[] =	"models/next21_efk/v_water_knife_b02.mdl"
new const MODEL_P_KNIFE[] =	"models/next21_efk/p_water_knife_b01.mdl"
new const SPRITE_LIFEBAR[] = "sprites/next21_efk/lifebar_water_mod2.spr"

new const SOUND_KNIFE_DEPLOY[] =	"next21_efk/water_knife_draw_b01.wav"
new const SOUND_KNIFE_HIT1[] =		"next21_efk/water_knife_hit1.wav"
new const SOUND_KNIFE_HITWALL[] =	"next21_efk/water_knife_hitwall_b01.wav"
new const SOUND_KNIFE_SLASH1[] =	"next21_efk/water_knife_slash1_b01.wav"
new const SOUND_KNIFE_SLASH2[] =	"next21_efk/water_knife_slash2_b01.wav"
new const SOUND_KNIFE_EMBODIMENT[] = "next21_efk/embodiment_switch.wav"

new const MODEL_DRAGON_GUARD[] = "models/next21_efk/water_guard_b02.mdl"
new const MODEL_EMBODIMENT[] = "models/next21_efk/water_embodiment_b01.mdl"

new const MODEL_WATER_SPHERE[] = "models/next21_efk/sphere256.bsp"
new const MODEL_WATER_SPHERE_SHELL[] = "models/next21_efk/water_sphere_b01.mdl"

new const SOUND_DRAGON_GUARD[] = "next21_efk/dragon_guard.wav"
new const SOUND_DRAGON_GUARD_HIT[] = "next21_efk/dragon_guard_hit.wav"
new const SOUND_EMBODIMENT[] = "next21_efk/embodiment_b01.wav"
new const SOUND_WATER_SPHERE[] = "next21_efk/water_sphere.wav"

new const EMBODIMENT_HUD[] = "Embodiment (F)"

new const WEAPON_KNIFE_STR[] = "weapon_knife"


new g_iPlrKnifeId[MAX_PLAYERS + 1], bool:g_bPlayerAlive[MAX_PLAYERS + 1]
new g_iDragonGuard[MAX_PLAYERS + 1], bool:g_bInEmbodiment[MAX_PLAYERS + 1]
new g_iKnifeId, g_pKnifePMdl, g_pWaterLifeBar
new g_pBloodSpr, g_pBloodSpraySpr


public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)
	g_pWaterLifeBar = precache_model(SPRITE_LIFEBAR)

	precache_model(MODEL_DRAGON_GUARD)
	precache_model(MODEL_EMBODIMENT)
	precache_model(MODEL_WATER_SPHERE)
	precache_model(MODEL_WATER_SPHERE_SHELL)

	precache_sound(SOUND_KNIFE_DEPLOY)
	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)
	precache_sound(SOUND_KNIFE_EMBODIMENT)

	precache_sound(SOUND_DRAGON_GUARD)
	precache_sound(SOUND_DRAGON_GUARD_HIT)
	precache_sound(SOUND_EMBODIMENT)
	precache_sound(SOUND_WATER_SPHERE)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	g_pBloodSpr = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
	g_pBloodSpraySpr = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		engfunc(EngFunc_AllocString, MODEL_V_KNIFE), engfunc(EngFunc_AllocString, MODEL_P_KNIFE),
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, ABIL1_CHARGE, ABIL1_TYPE, ABIL1_MINDIST, ABIL1_MAXDIST)
	kc_register_ability2(g_iKnifeId, ABIL2_NAME, ABIL2_CHARGE)
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)
	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLABLE)
	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_NUNCHAKU)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_HIT1)

	register_logevent("fw_StartRound", 2, "1=Round_Start")

	RegisterHookChain(RG_CBasePlayer_Spawn, "fw_PlayerSpawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "fw_PlayerKilled_Post", true)

	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage_Pre")
	RegisterHam(Ham_Item_Deploy, WEAPON_KNIFE_STR, "fw_KnifeDeploy_Post", true)
	RegisterHam(Ham_Item_Holster, WEAPON_KNIFE_STR, "fw_KnifeHolster_Post", true)
	RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_KNIFE_STR, "fw_KnifeWeaponIdle_Pre", false)
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_KNIFE_STR, "fw_KnifePrimaryAttack_Pre", false)
	RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_KNIFE_STR, "fw_KnifeSecondaryAttack_Pre", false)

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", true)
	register_forward(FM_AddToFullPack, "fw_AddToFullPack", true)

	register_impulse(100, "fw_PlayerFlashlight")
}

public client_disconnected(iPlayer)
{
	clear_player(iPlayer)
}

public efk_ability(iPlayer, iTarget)
{
	if (g_iDragonGuard[iTarget] > 0)
	{
		new iDragonGuard = g_iDragonGuard[iTarget]
		set_entvar(iDragonGuard, var_dg_lifetime, get_gametime() + DRAGON_GUARD_LIFETIME)
		change_task(TASK_DRAGONGUARD + iTarget, DRAGON_GUARD_LIFETIME)
		return PLUGIN_CONTINUE
	}

	new iDragonGuard = create_dragon_guard(iTarget, iPlayer)
	if (iDragonGuard <= 0)
		return PLUGIN_HANDLED

	g_iDragonGuard[iTarget] = iDragonGuard

	return PLUGIN_CONTINUE
}

public efk_ability2(iPlayer)
{
	if (g_iDragonGuard[iPlayer] > 0)
	{
		new iDragonGuard = g_iDragonGuard[iPlayer]
		set_entvar(iDragonGuard, var_dg_lifetime, get_gametime() + DRAGON_GUARD_LIFETIME)
		change_task(TASK_DRAGONGUARD + iPlayer, DRAGON_GUARD_LIFETIME)
		return PLUGIN_CONTINUE
	}

	new iDragonGuard = create_dragon_guard(iPlayer, iPlayer)
	if (iDragonGuard <= 0)
		return PLUGIN_HANDLED

	g_iDragonGuard[iPlayer] = iDragonGuard

	return PLUGIN_CONTINUE
}

public efk_ability3(iPlayer)
{
	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	if (create_water_sphere(iPlayer, vOrigin) == NULLENT)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	if (g_iKnifeId == iKnifeId)
	{
		set_restore_air_task(iPlayer)
		kc_player_set_water_transparent(iPlayer, true)
	}
	else
	{
		remove_task(TASK_RESTOREAIR + iPlayer)
		kc_player_set_water_transparent(iPlayer, false)
	}
	g_iPlrKnifeId[iPlayer] = iKnifeId
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (g_iKnifeId != iKnifeId)
		return PLUGIN_CONTINUE

	set_hudmessage(255, 255, 255, 0.01, -0.72, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
	show_hudmessage(iPlayer, EMBODIMENT_HUD)

	return PLUGIN_CONTINUE
}

public efk_swap(iPlayer, iTarget)
{
	if (g_iDragonGuard[iTarget] > 0)
	{
		new Float:fGameTime = get_gametime()
		new Float:fLifeTime = Float:get_entvar(g_iDragonGuard[iTarget], var_dg_lifetime) - fGameTime

		remove_task(TASK_DRAGONGUARD + iTarget)
		remove_dragon_guard(iTarget)
		g_iDragonGuard[iTarget] = 0

		if (g_iDragonGuard[iPlayer] > 0)
		{
			new iDragonGuard = g_iDragonGuard[iPlayer]
			set_entvar(iDragonGuard, var_owner, iPlayer)
			set_entvar(iDragonGuard, var_dg_lifetime, fLifeTime)
			change_task(TASK_DRAGONGUARD + iPlayer, fLifeTime)
		}
		else
		{
			new iDragonGuard = create_dragon_guard(iPlayer, iPlayer, fLifeTime)
			if (iDragonGuard > 0)
				g_iDragonGuard[iPlayer] = iDragonGuard
		}
	}
}

public fw_StartRound()
{
	new iEnt = NULLENT
	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "targetname", WATER_SPHERE_TNAME)))
	{
		remove_task(TASK_WATERSPHERE + iEnt)
		remove_water_sphere(iEnt)
	}
}

public fw_PlayerSpawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		clear_player(iPlayer)
		new iKnifeId = kc_player_get_knife(iPlayer)
		if (g_iKnifeId == iKnifeId)
			set_restore_air_task(iPlayer)

		g_bPlayerAlive[iPlayer] = true
	}
}

public fw_PlayerKilled_Post(iPlayer, iAttacker, iGib)
{
	clear_player(iPlayer)
	g_bPlayerAlive[iPlayer] = false
}

public fw_PlayerTakeDamage_Pre(iPlayer, iInflictor, iAttacker, Float:fDamage, bits)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	new iWaterGuard = g_iDragonGuard[iPlayer]
	if (iWaterGuard <= 0)
		return HAM_IGNORED

	if (!iInflictor || iAttacker == iPlayer || !iAttacker)
		return HAM_IGNORED

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	new iWaterGuardOwner = get_entvar(iWaterGuard, var_owner)
	new iInflictorImpulse = get_entvar(iInflictor, var_impulse)

	if (iInflictorImpulse == IMPULSE_ZOMBIE)
	{
		new Float:vInflictorOrigin[3]
		get_entvar(iInflictor, var_origin, vInflictorOrigin)
		if (get_distance_f(vOrigin, vInflictorOrigin) > DRAGON_GUARD_DISTANCE)
			return HAM_IGNORED

		ExecuteHamB(Ham_TakeDamage, iInflictor, iWaterGuard, iWaterGuardOwner, DRAGON_GUARD_DAMAGE, DMG_ENERGYBEAM)

		remove_task(TASK_DRAGONGUARD + iPlayer)
		remove_dragon_guard(iPlayer)
		g_iDragonGuard[iPlayer] = 0

		create_dragon_guard_attack(vOrigin, vInflictorOrigin)
		return HAM_IGNORED
	}

	if (iInflictorImpulse == IMPULSE_BUG)
	{
		ExecuteHamB(Ham_TakeDamage, iInflictor, iWaterGuard, iWaterGuardOwner, DRAGON_GUARD_DAMAGE, DMG_ENERGYBEAM)

		remove_task(TASK_DRAGONGUARD + iPlayer)
		remove_dragon_guard(iPlayer)
		g_iDragonGuard[iPlayer] = 0

		return HAM_IGNORED
	}

	if (is_user_alive(iAttacker)
		&& get_member(iPlayer, m_iTeam) != get_member(iAttacker, m_iTeam)
		&& fDamage >= 5.0)
	{
		new Float:vAttackerOrigin[3], Float:vVelocity[3]
		get_entvar(iAttacker, var_origin, vAttackerOrigin)
		if (get_distance_f(vOrigin, vAttackerOrigin) > DRAGON_GUARD_DISTANCE)
		{
			if (iInflictorImpulse == IMPULSE_EMBODIMENT)
				return HAM_IGNORED

			remove_task(TASK_DRAGONGUARD + iPlayer)
			remove_dragon_guard(iPlayer)
			g_iDragonGuard[iPlayer] = 0

			return HAM_IGNORED
		}

		if (g_iDragonGuard[iAttacker])
		{
			remove_task(TASK_DRAGONGUARD + iAttacker)
			remove_dragon_guard(iAttacker)
			g_iDragonGuard[iAttacker] = 0
		}

		kc_player_set_override_attacker(iAttacker, iWaterGuardOwner, 4.0)
		kc_player_set_bair(iAttacker, FL_BAIR_NORMAL | FL_BAIR_CLIMB)

		xs_vec_sub(vAttackerOrigin, vOrigin, vVelocity)
		xs_vec_normalize(vVelocity, vVelocity)
		xs_vec_mul_scalar(vVelocity, DRAGON_GUARD_KNOCKBACK_XY, vVelocity)
		vVelocity[2] = DRAGON_GUARD_KNOCKBACK_Z
		set_entvar(iAttacker, var_velocity, vVelocity)

		new iShadowActivator = kc_player_get_shadow_activator(iAttacker)
		if (iShadowActivator)
		{
			kc_player_unshadow(iShadowActivator)
			set_entvar(iShadowActivator, var_velocity, vVelocity)
		}

		kc_player_set_death_reason(iAttacker, "DEATH_REASON_DRAGON_GUARD")
		set_member(iAttacker, m_LastHitGroup, HIT_GENERIC)
		engfunc(EngFunc_EmitSound, iAttacker, CHAN_STATIC, SOUND_DRAGON_GUARD_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM)
		ExecuteHamB(Ham_TakeDamage, iAttacker, iWaterGuard, iWaterGuardOwner,
			DRAGON_GUARD_DAMAGE, DMG_ENERGYBEAM)

		remove_task(TASK_DRAGONGUARD + iPlayer)
		remove_dragon_guard(iPlayer)
		g_iDragonGuard[iPlayer] = 0

		create_dragon_guard_attack(vOrigin, vAttackerOrigin)
	}

	return HAM_IGNORED
}

public fw_KnifeDeploy_Post(iItem)
{
	new iPlayer = get_member(iItem, m_pPlayer)
	g_bInEmbodiment[iPlayer] = false
}

public fw_KnifeHolster_Post(iItem)
{
	new iPlayer = get_member(iItem, m_pPlayer)
	g_bInEmbodiment[iPlayer] = false
}

public fw_KnifeWeaponIdle_Pre(iItem)
{
	new iPlayer = get_member(iItem, m_pPlayer)

	if (!g_bInEmbodiment[iPlayer] || Float:get_member(iItem, m_Weapon_flTimeWeaponIdle) > 0.0)
		return HAM_IGNORED

	kc_player_set_view_anim(iPlayer, VIEW_SEQ_ABILITY_IDLE)

	set_member(iItem, m_Weapon_flTimeWeaponIdle, 1.7)
	return HAM_IGNORED
}

public fw_KnifePrimaryAttack_Pre(iItem)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	return use_embodiment(iItem, 1)
}

public fw_KnifeSecondaryAttack_Pre(iItem)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	return use_embodiment(iItem, 0)
}

public fw_UpdateClientData_Post(iPlayer, iSendWeapons, CD_Handle)
{
	if (!g_bInEmbodiment[iPlayer] || !is_user_alive(iPlayer))
		return FMRES_IGNORED

	set_cd(CD_Handle, CD_ID, 0)
	return FMRES_HANDLED
}

public fw_AddToFullPack(es_state, e, ent, host, hostflags, player)
{
	if (g_iPlrKnifeId[host] == g_iKnifeId
		&& g_bPlayerAlive[host]
		&& !is_nullent(ent)
		&& get_entvar(ent, var_impulse) == IMPULSE_LIFEBAR
	) {
		new owner = get_entvar(ent, var_aiment)
		new VisibilityType:iVisibility = kc_player_get_visibility(owner)
		new bool:bSameTeam = (get_member(host, m_iTeam) == get_member(owner, m_iTeam)
			|| iVisibility == VIS_CLONE)

		if (host != owner && bSameTeam && iVisibility != VIS_SHADOW)
		{
			set_es(es_state, ES_Effects, get_es(es_state, ES_Effects) & ~EF_NODRAW)
			set_es(es_state, ES_ModelIndex, g_pWaterLifeBar)
		}
	}
}

public fw_PlayerFlashlight(iPlayer)
{
	if (g_iPlrKnifeId[iPlayer] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (!g_bInEmbodiment[iPlayer] && Float:get_member(iPlayer, m_flNextAttack) > 0.0)
		return PLUGIN_HANDLED

	new iActiveItem = get_member(iPlayer, m_pActiveItem)
	if (is_nullent(iActiveItem) || get_member(iActiveItem, m_iId) != CSW_KNIFE)
		return PLUGIN_CONTINUE

	if (g_bInEmbodiment[iPlayer])
	{
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_ABILITY_END)
		g_bInEmbodiment[iPlayer] = false
	}
	else
	{
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_ABILITY_START)
		g_bInEmbodiment[iPlayer] = true
	}

	set_member(iPlayer, m_flNextAttack, floatmax(Float:get_member(iPlayer, m_flNextAttack), 0.4))
	set_member(iActiveItem, m_Weapon_flNextPrimaryAttack,
		floatmax(Float:get_member(iActiveItem, m_Weapon_flNextPrimaryAttack), 0.36))
	set_member(iActiveItem, m_Weapon_flNextSecondaryAttack,
		floatmax(Float:get_member(iActiveItem, m_Weapon_flNextSecondaryAttack), 0.36))
	set_member(iActiveItem, m_Weapon_flTimeWeaponIdle,
		floatmax(Float:get_member(iActiveItem, m_Weapon_flTimeWeaponIdle), 0.36))

	return PLUGIN_HANDLED
}

public embodiment_think(iEmbEnt)
{
	if (get_entvar(iEmbEnt, var_emb_dir))
	{
		set_entvar(iEmbEnt, var_flags, FL_KILLME)
		return HC_CONTINUE
	}

	new iOwner = get_entvar(iEmbEnt, var_owner)
	if (!is_user_alive(iOwner))
	{
		set_entvar(iEmbEnt, var_flags, FL_KILLME)
		return HC_CONTINUE
	}

	new Float:vOrigin[3], Float:vVelocity[3], Float:vAngles[3]
	get_entvar(iOwner, var_origin, vVelocity)
	get_entvar(iOwner, var_view_ofs, vOrigin)
	xs_vec_add(vVelocity, vOrigin, vVelocity)
	get_entvar(iEmbEnt, var_origin, vOrigin)
	xs_vec_sub(vVelocity, vOrigin, vVelocity)
	xs_vec_normalize(vVelocity, vVelocity)
	vector_to_angle(vVelocity, vAngles)
	xs_vec_mul_scalar(vVelocity, EMBODIMENT_SPEED, vVelocity)

	set_entvar(iEmbEnt, var_velocity, vVelocity)
	set_entvar(iEmbEnt, var_angles, vAngles)

	new iTouches = get_entvar(iEmbEnt, var_emb_touches)
	set_entvar(iEmbEnt, var_emb_touches, iTouches & ~(1 << (iOwner & 31)))

	set_entvar(iEmbEnt, var_emb_dir, 1)
	set_entvar(iEmbEnt, var_nextthink, get_gametime() + EMBODIMENT_RADIUS / EMBODIMENT_SPEED)

	return HC_CONTINUE
}

public embodiment_touch(iEmbEnt, iEnt)
{
	if (!iEnt)
	{
		set_entvar(iEmbEnt, var_nextthink, get_gametime())
		return HC_CONTINUE
	}

	if (iEnt > MaxClients)
	{
		if (get_entvar(iEnt, var_solid) >= SOLID_BBOX)
		{
			new szModel[2]
			get_entvar(iEnt, var_model, szModel, charsmax(szModel))
			if (szModel[0] == '*')
				set_entvar(iEmbEnt, var_nextthink, get_gametime())
		}
		return HC_CONTINUE
	}

	new iTouches = get_entvar(iEmbEnt, var_emb_touches)
	if (iTouches & (1 << (iEnt & 31)))
		return HC_CONTINUE

	new iOwner = get_entvar(iEmbEnt, var_owner)
	if (!is_user_connected(iOwner))
		return HC_CONTINUE

	new iMode = get_entvar(iEmbEnt, var_skin)
	new bool:bSameTeam = (get_member(iOwner, m_iTeam) == get_member(iEnt, m_iTeam)
		|| kc_player_get_visibility(iEnt) == VIS_CLONE)

	if (iMode == 0 && bSameTeam)
	{
		kc_player_unburn(iEnt)

		kc_player_heal(iEnt, EMBODIMENT_HEALTH, iOwner)
		iTouches |= (1 << (iEnt & 31))

		new iShadowActivator = kc_player_get_shadow_activator(iEnt)
		if (iShadowActivator)
		{
			kc_player_heal(iShadowActivator, EMBODIMENT_HEALTH, iOwner)
			iTouches |= (1 << (iShadowActivator & 31))
		}

		set_entvar(iEmbEnt, var_emb_touches, iTouches)
	}
	else if (iMode == 1 && !bSameTeam)
	{
		if (!kc_player_check_game_flag(iEnt, PLGF_IN_UNABILITY))
		{
			new Float:fVelocityModifier = get_member(iEnt, m_flVelocityModifier)
			set_member(iEnt, m_LastHitGroup, HIT_GENERIC)
			ExecuteHamB(Ham_TakeDamage, iEnt, iEmbEnt, iOwner, EMBODIMENT_DAMAGE, DMG_ENERGYBEAM)
			set_member(iEnt, m_flVelocityModifier, fVelocityModifier)
			iTouches |= (1 << (iEnt & 31))

			new iShadowActivator = kc_player_get_shadow_activator(iEnt)
			if (iShadowActivator)
			{
				set_member(iShadowActivator, m_LastHitGroup, HIT_GENERIC)
				new Float:fHealth = Float:get_entvar(iShadowActivator, var_health) - EMBODIMENT_DAMAGE
				if (fHealth > 0.0) set_entvar(iShadowActivator, var_health, fHealth)
				else ExecuteHamB(Ham_Killed, iShadowActivator, iOwner, 0)

				iTouches |= (1 << (iShadowActivator & 31))
			}

			set_entvar(iEmbEnt, var_emb_touches, iTouches)

			new Float:vOrigin[3]
			get_entvar(iEmbEnt, var_origin, vOrigin)
			send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, 208, random_num(1, 5))
		}
	}

	return HC_CONTINUE
}

public dragon_guard_task(iTaskId)
{
	new iPlayer = iTaskId - TASK_DRAGONGUARD
	remove_dragon_guard(iPlayer)
	g_iDragonGuard[iPlayer] = 0
}

public water_sphere_task(iTaskId)
{
	new iEnt = iTaskId - TASK_WATERSPHERE
	remove_water_sphere(iEnt)
}

public restore_air_task(iTaskId)
{
	new iPlayer = iTaskId - TASK_RESTOREAIR
	set_entvar(iPlayer, var_air_finished, get_gametime() + AIRTIME)
}

clear_player(iPlayer)
{
	remove_task(TASK_RESTOREAIR + iPlayer)
	remove_task(TASK_DRAGONGUARD + iPlayer)

	remove_dragon_guard(iPlayer)
	g_iDragonGuard[iPlayer] = 0
	g_bInEmbodiment[iPlayer] = false
}

create_dragon_guard(iPlayer, iOwner, Float:fLifeTime = DRAGON_GUARD_LIFETIME)
{
	new iEnt = rg_create_entity("info_target", true)
	if (is_nullent(iEnt))
		return NULLENT

	new Float:fGameTime = get_gametime()

	engfunc(EngFunc_SetModel, iEnt, MODEL_DRAGON_GUARD)

	set_entvar(iEnt, var_solid, SOLID_NOT)
	set_entvar(iEnt, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iEnt, var_impulse, IMPULSE_DRAGON_GUARD)

	set_entvar(iEnt, var_owner, iOwner)
	set_entvar(iEnt, var_aiment, iPlayer)

	set_entvar(iEnt, var_sequence, 0)
	set_entvar(iEnt, var_animtime, fGameTime)
	set_entvar(iEnt, var_frame, 0.0)
	set_entvar(iEnt, var_framerate, 1.0)

	set_entvar(iEnt, var_dg_lifetime, fGameTime + fLifeTime)

	send_msg_StatusIcon(true, DRAGON_GUARD_ICON, {38, 149, 216}, MSG_ONE, _, iPlayer)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_DRAGON_GUARD, 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_task(fLifeTime, "dragon_guard_task", TASK_DRAGONGUARD + iPlayer)
	return iEnt
}

remove_dragon_guard(iPlayer)
{
	new iEnt = g_iDragonGuard[iPlayer]
	if (iEnt > 0)
	{
		rg_remove_entity(iEnt)

		send_msg_StatusIcon(false, DRAGON_GUARD_ICON, _, MSG_ONE, _, iPlayer)
	}
}

use_embodiment(iItem, iMode)
{
	new iPlayer = get_member(iItem, m_pPlayer)

	if (!g_bInEmbodiment[iPlayer])
		return HAM_IGNORED

	new iEmbEnt = rg_create_entity("info_target")
	if (is_nullent(iEmbEnt))
		return HAM_SUPERCEDE

	new Float:fGameTime = get_gametime()

	new Float:vOrigin[3], Float:vVelocity[3], Float:vAngles[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vVelocity)
	xs_vec_add(vOrigin, vVelocity, vOrigin)

	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vVelocity)
	xs_vec_mul_scalar(vVelocity, EMBODIMENT_SPEED, vVelocity)
	vAngles[0] = -vAngles[0]

	engfunc(EngFunc_SetModel, iEmbEnt, MODEL_EMBODIMENT)
	engfunc(EngFunc_SetOrigin, iEmbEnt, vOrigin)
	engfunc(EngFunc_SetSize, iEmbEnt, Float:{-12.0, -12.0, -12.0}, Float:{12.0, 12.0, 12.0})

	set_entvar(iEmbEnt, var_origin, vOrigin)
	set_entvar(iEmbEnt, var_angles, vAngles)
	set_entvar(iEmbEnt, var_velocity, vVelocity)

	set_entvar(iEmbEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iEmbEnt, var_movetype, MOVETYPE_FLY)
	set_entvar(iEmbEnt, var_classname, CLASSNAME_EMBODIMENT)
	set_entvar(iEmbEnt, var_impulse, IMPULSE_EMBODIMENT)
	set_entvar(iEmbEnt, var_owner, iPlayer)
	set_entvar(iEmbEnt, var_skin, iMode)
	set_entvar(iEmbEnt, var_nextthink, fGameTime + EMBODIMENT_RADIUS / EMBODIMENT_SPEED)

	set_entvar(iEmbEnt, var_framerate, 1.0)
	set_entvar(iEmbEnt, var_animtime, fGameTime)
	set_entvar(iEmbEnt, var_frame, 0.0)
	set_entvar(iEmbEnt, var_sequence, 0)

	set_entvar(iEmbEnt, var_emb_touches, 1 << (iPlayer & 31))
	set_entvar(iEmbEnt, var_emb_dir, 0)

	SetThink(iEmbEnt, "embodiment_think")
	SetTouch(iEmbEnt, "embodiment_touch")

	kc_player_set_view_anim(iPlayer, VIEW_SEQ_ABILITY_USE)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_EMBODIMENT, 0.5, ATTN_NORM, 0, PITCH_NORM)

	set_member(iPlayer, m_flNextAttack, floatmax(Float:get_member(iPlayer, m_flNextAttack), 0.6))
	set_member(iItem, m_Weapon_flNextPrimaryAttack,
		floatmax(Float:get_member(iItem, m_Weapon_flNextPrimaryAttack), 0.6))
	set_member(iItem, m_Weapon_flNextSecondaryAttack,
		floatmax(Float:get_member(iItem, m_Weapon_flNextSecondaryAttack), 0.6))
	set_member(iItem, m_Weapon_flTimeWeaponIdle,
		floatmax(Float:get_member(iItem, m_Weapon_flTimeWeaponIdle), 0.6))

	return HAM_SUPERCEDE
}

create_dragon_guard_attack(Float:vOrigin[3], Float:vTargetOrigin[3])
{
	new iEnt = rg_create_entity("info_target")
	if (is_nullent(iEnt))
		return NULLENT

	new Float:fGameTime = get_gametime()

	engfunc(EngFunc_SetModel, iEnt, MODEL_DRAGON_GUARD)
	engfunc(EngFunc_SetOrigin, iEnt, vOrigin)
	engfunc(EngFunc_SetSize, iEnt, Float:{-12.0, -12.0, -12.0}, Float:{12.0, 12.0, 12.0})

	new Float:vVelocity[3], Float:vAngles[3]
	xs_vec_sub(vTargetOrigin, vOrigin, vVelocity)
	xs_vec_normalize(vVelocity, vVelocity)
	vector_to_angle(vVelocity, vAngles)
	xs_vec_mul_scalar(vVelocity, EMBODIMENT_SPEED, vVelocity)

	set_entvar(iEnt, var_origin, vOrigin)
	set_entvar(iEnt, var_angles, vAngles)
	set_entvar(iEnt, var_velocity, vVelocity)

	set_entvar(iEnt, var_solid, SOLID_NOT)
	set_entvar(iEnt, var_movetype, MOVETYPE_FLY)
	set_entvar(iEnt, var_classname, CLASSNAME_EMBODIMENT)
	set_entvar(iEnt, var_impulse, IMPULSE_EMBODIMENT)

	set_entvar(iEnt, var_sequence, 1)
	set_entvar(iEnt, var_animtime, fGameTime)
	set_entvar(iEnt, var_frame, 0.0)
	set_entvar(iEnt, var_framerate, 1.0)

	set_entvar(iEnt, var_nextthink, fGameTime + 0.3)
	set_entvar(iEnt, var_emb_dir, 1)

	SetThink(iEnt, "embodiment_think")
	return iEnt
}

create_water_sphere(iOwner, Float:vOrigin[3])
{
	new iEnt = rg_create_entity("func_water", true)
	if (is_nullent(iEnt))
		return NULLENT

	engfunc(EngFunc_SetModel, iEnt, MODEL_WATER_SPHERE)
	set_entvar(iEnt, var_skin, -3)
	set_entvar(iEnt, var_origin, vOrigin)
	dllfunc(DLLFunc_Spawn, iEnt)
	set_entvar(iEnt, var_effects, EF_NODRAW)
	set_entvar(iEnt, var_targetname, WATER_SPHERE_TNAME)

	new iShellEnt = rg_create_entity("info_target", true)
	if (is_nullent(iShellEnt))
	{
		set_entvar(iEnt, var_flags, FL_KILLME)
		return NULLENT
	}
	new Float:flGameTime = get_gametime()
	set_entvar(iShellEnt, var_origin, vOrigin)

	engfunc(EngFunc_SetModel, iShellEnt, MODEL_WATER_SPHERE_SHELL)
	engfunc(EngFunc_SetSize, iShellEnt, Float:{-256.0, -256.0, -256.0},
		Float:{256.0, 256.0, 256.0})

	set_entvar(iShellEnt, var_rendermode, kRenderTransAlpha)
	set_entvar(iShellEnt, var_renderamt, 200.0)
	set_entvar(iShellEnt, var_movetype, MOVETYPE_NONE)
	set_entvar(iShellEnt, var_framerate, 1.0)
	set_entvar(iShellEnt, var_animtime, flGameTime)
	set_entvar(iShellEnt, var_frame, 0.0)
	set_entvar(iShellEnt, var_sequence, 0)
	set_entvar(iShellEnt, var_team, get_member(iOwner, m_iTeam))
	set_entvar(iShellEnt, var_owner, iOwner)

	engfunc(EngFunc_EmitSound, iShellEnt, CHAN_STATIC, SOUND_WATER_SPHERE, 1.0, ATTN_NORM, 0, PITCH_NORM)

	SetThink(iShellEnt, "watershell_think")
	set_entvar(iShellEnt, var_nextthink, flGameTime + WATER_SPHERE_REGEN_DELAY)

	set_entvar(iEnt, var_aiment, iShellEnt)
	set_task(WATER_SPHERE_LIFETIME, "water_sphere_task", TASK_WATERSPHERE + iEnt)

	return iEnt
}

public watershell_think(iSphere)
{
	new iOwner = get_entvar(iSphere, var_owner)
	new iSphereTeam = get_entvar(iSphere, var_team)

	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (is_user_alive(iPlayer)
			&& fm_entity_range(iPlayer, iSphere) < 256.0
			&& iSphereTeam == get_member(iPlayer, m_iTeam)
		) {
			kc_player_heal(iPlayer, WATER_SPHERE_REGEN_HP, iOwner)
			set_entvar(iPlayer, var_air_finished, get_gametime() + AIRTIME)
		}
	}

	set_entvar(iSphere, var_nextthink, get_gametime() + WATER_SPHERE_REGEN_DELAY)
}

remove_water_sphere(iEnt)
{
	set_entvar(iEnt, var_flags, FL_KILLME)
	new iShellEnt = get_entvar(iEnt, var_aiment)
	if (!is_nullent(iShellEnt))
		set_entvar(iShellEnt, var_flags, FL_KILLME)
}

set_restore_air_task(iPlayer)
{
	set_task(5.0, "restore_air_task", TASK_RESTOREAIR + iPlayer, .flags="b")
	set_entvar(iPlayer, var_air_finished, get_gametime() + AIRTIME)
}
