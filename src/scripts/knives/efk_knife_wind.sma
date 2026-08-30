#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Wind Knife"

#define KNIFE_CLASSNAME "weapon_next21_wind"
#define KNIFE_MENUDESC  "KNIFE_WIND_DESC"
#define KNIFE_CHATDESC  "KNIFE_WIND_CHAT"

#define HP				90.0
#define GRAVITY			1.0
#define SPEED			250.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL     1

#define ABIL1_NAME		"Wind"
#define ABIL1_CHARGE	7.693
#define ABIL1_TYPE		ABIL_TARGET_PLAYER
#define ABIL1_MINDIST	75.0
#define ABIL1_MAXDIST	1300.0

#define ABIL2_NAME		"Tornado"
#define ABIL2_CHARGE	3.34

#define ABIL3_NAME		"Airflow"
#define ABIL3_CHARGE	11.12

#define ABIL4_NAME		"Wind Boost"
#define ABIL4_CHARGE	7.693

new const MODEL_V_KNIFE[]			= "models/next21_efk/v_wind_knife_b02.mdl"
new const MODEL_P_KNIFE[]			= "models/next21_efk/p_wind_knife.mdl"

new const MODEL_WIND_BOOSTER[]		= "models/next21_efk/wind_boost.mdl"
new const MODEL_TORNADO[]			= "models/next21_efk/tornado_b02.mdl"
new const MODEL_WIND_WAVE[]			= "models/next21_efk/wind_wave.mdl"

new const SPRITE_SPRINT_TRAIL[]		= "sprites/next21_efk/sprint_trail.spr"

new const SOUND_KNIFE_DEPLOY[]		= "next21_efk/wind_knife_draw.wav"
new const SOUND_KNIFE_HIT1[]		= "next21_efk/wind_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[]		= "next21_efk/wind_knife_hit2.wav"
new const SOUND_KNIFE_HITWALL[]		= "next21_efk/wind_knife_hitwall.wav"
new const SOUND_KNIFE_STAB[]		= "next21_efk/wind_knife_stab.wav"
new const SOUND_KNIFE_SLASH1[]		= "next21_efk/wind_knife_slash1.wav"
new const SOUND_KNIFE_SLASH2[]		= "next21_efk/wind_knife_slash2.wav"

new const SOUND_WIND_BOOST_UP[]		= "next21_efk/wind_boost_up.wav"
new const SOUND_WIND_BOOST_DOWN[]	= "next21_efk/wind_boost_down.wav"

new const SOUND_TORNADO[]			= "next21_efk/tornado.wav"
new const SOUND_TORNADO_JUMP[]		= "next21_efk/tornado_jump.wav"
new const SOUND_WIND_WAVE[]			= "next21_efk/wind_wave.wav"

#define BACKJUMP_FORCE				260.0

#define WIND_BOOST_SELF_TIME		10.0
#define WIND_BOOST_TARGET_TIME		16.0

#define TORNADO_LIFETIME			7.0
#define TORNADO_RADIUS				175.0
#define TORNADO_INNER_RADIUS		40.0
#define TORNADO_HALF_HEIGHT			90.0
#define TORNADO_CIRCULAR_FORCE		280.0
#define TORNADO_CENTER_FORCE		160.0
#define TORNADO_WAVE_PUSH_FORCE		800.0
#define TORNADO_V_SPEED_WITH_PLRS	35.0
#define TORNADO_H_SPEED_WITH_PLRS	100.0

#define WIND_WAVE_LIFETIME			3.0
#define WIND_WAVE_RADIUS			100.0
#define WIND_WAVE_HALF_HEIGHT		15.0
#define WIND_WAVE_SPEED				1000.0
#define WIND_WAVE_START_OFFSET		30.0
#define WIND_WAVE_FORCE				200.0

enum _:ViewSeq
{
	VIEW_SEQ_WIND_WAVE = 5
}

#define TASK_WIND_BOOST				2000

new const SZ_INFO_TARGET[]			= "info_target"

#define var_tornado_endtime			var_fuser1

new const COLOR_RED[]	= {255, 0, 0}
new const COLOR_GREEN[]	= {0, 255, 0}

enum _:PlayerData
{
	PlrWindBoostEnt,
	CaptureType:PlrCaptureType
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new g_iKnifeId, g_pKnifeVStr, g_pKnifePMdl,
	g_ePlayerData[MAX_PLAYERS][PlayerData],
	g_sprWindWave


public plugin_precache()
{
	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(MODEL_WIND_BOOSTER)
	precache_model(MODEL_TORNADO)
	precache_model(MODEL_WIND_WAVE)

	g_sprWindWave = precache_model(SPRITE_SPRINT_TRAIL)

	precache_sound(SOUND_KNIFE_DEPLOY)
	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_STAB)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)

	precache_sound(SOUND_WIND_BOOST_UP)
	precache_sound(SOUND_WIND_BOOST_DOWN)

	precache_sound(SOUND_TORNADO)
	precache_sound(SOUND_TORNADO_JUMP)
	precache_sound(SOUND_WIND_WAVE)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		g_pKnifeVStr, engfunc(EngFunc_AllocString, MODEL_P_KNIFE),
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, ABIL1_CHARGE, ABIL1_TYPE, ABIL1_MINDIST, ABIL1_MAXDIST)
	kc_register_ability2(g_iKnifeId, ABIL2_NAME, ABIL2_CHARGE)
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)
	kc_register_ability4(g_iKnifeId, ABIL4_NAME, ABIL4_CHARGE)
	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_KNIFE2)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
}

public efk_ability(iPlayer, iTarget)
{
	remove_task(iTarget + TASK_WIND_BOOST)
	set_task(WIND_BOOST_TARGET_TIME, "windboost_task", iTarget + TASK_WIND_BOOST)
	if (get_member(iPlayer, m_iTeam) != get_member(iTarget, m_iTeam))
	{
		if (kc_player_in_reflection(iTarget))
		{
			kc_player_set_windboost(iPlayer, WINDBOOST_NEGATIVE)
			kc_player_set_override_attacker(iPlayer, iTarget, 2.5)
			kc_player_reflection_done(iTarget, iPlayer)
		}
		else
		{
			kc_player_set_windboost(iTarget, WINDBOOST_NEGATIVE)
			kc_player_set_override_attacker(iTarget, iPlayer, 2.5)
		}
	}
	else
		kc_player_set_windboost(iTarget, WINDBOOST_POSITIVE)

	return PLUGIN_CONTINUE
}

public efk_ability2(iPlayer)
{
	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	vOrigin[2] += TORNADO_HALF_HEIGHT - 36.0
	if (get_entvar(iPlayer, var_flags) & FL_DUCKING)
		vOrigin[2] += 18.0

	if (create_tornado(iPlayer, vOrigin) == FM_NULLENT)
		return PLUGIN_HANDLED

	kc_player_unfreeze(iPlayer)

	new Float:vVelocity[3]
	get_entvar(iPlayer, var_v_angle, vVelocity)
	angle_vector(vVelocity, ANGLEVECTOR_FORWARD, vVelocity)
	if (!(get_entvar(iPlayer, var_button) & IN_FORWARD))
	{
		vVelocity[0] = -vVelocity[0]
		vVelocity[1] = -vVelocity[1]
	}
	vVelocity[2] = 1.5
	xs_vec_mul_scalar(vVelocity, BACKJUMP_FORCE, vVelocity)
	set_entvar(iPlayer, var_velocity, vVelocity)

	return PLUGIN_CONTINUE
}

public efk_ability3(iPlayer)
{
	new iItem = get_member(iPlayer, m_pActiveItem)

	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return PLUGIN_HANDLED

	if (create_windwave(iPlayer) == NULLENT)
		return PLUGIN_HANDLED

	if (get_member(iItem, m_Weapon_flNextSecondaryAttack) <= 0.0)
	{
		new Float:fAbilCharge = kc_player_get_abil1_charge(iPlayer)
		kc_player_set_abil1_charge(iPlayer, 0.0)
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iItem)
		kc_player_set_abil1_charge(iPlayer, fAbilCharge)
	}
	else
	{
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_WIND_WAVE)
		rg_set_animation(iPlayer, PLAYER_ATTACK1)
	}

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_WIND_WAVE, 1.0, ATTN_NORM, 0, PITCH_NORM)

	return PLUGIN_CONTINUE
}

public efk_ability4(iPlayer)
{
	remove_task(iPlayer + TASK_WIND_BOOST)
	set_task(WIND_BOOST_SELF_TIME, "windboost_task", iPlayer + TASK_WIND_BOOST)
	kc_player_set_windboost(iPlayer, WINDBOOST_POSITIVE)

	return PLUGIN_CONTINUE
}

public efk_update_windboost(iPlayer, WindBoostType:iType)
{
	if (iType == WINDBOOST_NONE)
		remove_windboost(iPlayer)
	else
		set_windboost(iPlayer, iType)
}

public efk_capture(iPlayer, CaptureType:iType)
{
	Player[iPlayer][PlrCaptureType] = iType
}

public efk_uncapture(iPlayer)
{
	Player[iPlayer][PlrCaptureType] = CAPTURE_NONE
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_TORNADO)))
		remove_tornado(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_WIND_WAVE)))
		remove_windwave(iEnt)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return HC_CONTINUE

	if (kc_player_get_knife(iPlayer) == g_iKnifeId)
		kc_player_set_abil4_charge(iPlayer, 100.0 - ABIL4_CHARGE * RESET_ABIL_AFTER_SPAWN)

	return HC_CONTINUE
}

set_windboost(iPlayer, WindBoostType:iType)
{
	send_msg_StatusIcon(true, "dmg_rad", (iType == WINDBOOST_POSITIVE ? COLOR_GREEN : COLOR_RED), MSG_ONE, _, iPlayer)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC,
		iType == WINDBOOST_POSITIVE ? SOUND_WIND_BOOST_UP : SOUND_WIND_BOOST_DOWN,
		1.0, ATTN_NORM, 0, PITCH_NORM)

	if (!Player[iPlayer][PlrWindBoostEnt])
	{
		new iEnt = rg_create_entity(SZ_INFO_TARGET)
		if (!is_nullent(iEnt))
		{
			//set_entvar(iEnt, var_classname, CLASSNAME_WINDBOOSTER)
			engfunc(EngFunc_SetModel, iEnt, MODEL_WIND_BOOSTER)

			set_entvar(iEnt, var_solid, SOLID_NOT)
			set_entvar(iEnt, var_movetype, MOVETYPE_FOLLOW)

			new Float:fGameTime = get_gametime()

			set_entvar(iEnt, var_skin, iType == WINDBOOST_POSITIVE ? 0 : 1)
			set_entvar(iEnt, var_owner, iPlayer)
			set_entvar(iEnt, var_aiment, iPlayer)
			//set_entvar(iEnt, var_impulse, IMPULSE_WIND_BOOSTER)
			//set_entvar(iEnt, var_nextthink, fGameTime + TORNADO_LIFETIME)

			set_entvar(iEnt, var_animtime, fGameTime)
			set_entvar(iEnt, var_frame, 0.0)
			set_entvar(iEnt, var_framerate, 1.0)

			Player[iPlayer][PlrWindBoostEnt] = iEnt
		}
	}
	else
	{
		set_entvar(Player[iPlayer][PlrWindBoostEnt], var_skin, iType == WINDBOOST_POSITIVE ? 0 : 1)
	}

	if (!task_exists(iPlayer + TASK_WIND_BOOST))
		set_task(5.0, "windboost_task", iPlayer + TASK_WIND_BOOST)
}

remove_windboost(iPlayer)
{
	send_msg_StatusIcon(false, "dmg_rad", _, MSG_ONE, _, iPlayer)

	if (Player[iPlayer][PlrWindBoostEnt])
	{
		new iEnt = Player[iPlayer][PlrWindBoostEnt]
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME)
		set_entvar(iEnt, var_nextthink, get_gametime())
		Player[iPlayer][PlrWindBoostEnt] = 0
	}
	remove_task(iPlayer + TASK_WIND_BOOST)
}

public windboost_task(iPlayer)
{
	iPlayer -= TASK_WIND_BOOST
	kc_player_set_windboost(iPlayer, WINDBOOST_NONE)
}

bool:check_wind_impact(iEnt, iOther)
{
	if (iOther <= MaxClients)
	{
		if (get_member(iOther, m_iTeam) == get_entvar(iEnt, var_team))
			return false

		if (!get_entvar(iOther, var_solid))
			return false

		if (kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY))
			return false

		return true
	}

	static iOwner
	switch (get_entvar(iOther, var_impulse))
	{
		case IMPULSE_ICICLE, IMPULSE_ZOMBIE_SPIT, IMPULSE_ACIDB, IMPULSE_RAZOR_SPHERE, IMPULSE_KUNAI:
		{
			iOwner = get_entvar(iOther, var_owner)
			if (is_entity_player(iOwner) && get_member(iOwner, m_iTeam) != get_entvar(iEnt, var_team))
				return true
		}
		case IMPULSE_FAKEPLAYER:
		{
			if (get_entvar(iOther, var_team) != get_entvar(iEnt, var_team))
				return true
		}
		case IMPULSE_ZOMBIE, IMPULSE_BUG:
		{
			if (get_entvar(iOther, var_skin) != get_entvar(iEnt, var_skin) % 3)
				return true
		}
		case IMPULSE_PRESENT:
		{
			return true
		}
		default:
		{
			static szClassName[5]
			get_entvar(iOther, var_classname, szClassName, charsmax(szClassName))
			if (equal(szClassName, "gren"))
			{
				if (get_entvar(iEnt, var_team) != get_member(iOther, m_Grenade_iTeam))
					return true
			}
		}
	}

	return false
}

create_tornado(iOwner, Float:vOrigin[])
{
	new iTornado = rg_create_entity(SZ_INFO_TARGET)
	if (!is_nullent(iTornado))
	{
		set_entvar(iTornado, var_classname, CLASSNAME_TORNADO)
		engfunc(EngFunc_SetModel, iTornado, MODEL_TORNADO)
		engfunc(EngFunc_SetSize, iTornado, { -1.0, -1.0, -1.0 }, { 1.0, 1.0, 1.0 })
		engfunc(EngFunc_SetOrigin, iTornado, vOrigin)

		set_entvar(iTornado, var_origin, vOrigin)
		set_entvar(iTornado, var_solid, SOLID_TRIGGER)
		set_entvar(iTornado, var_movetype, MOVETYPE_TOSS)
		set_entvar(iTornado, var_gravity, 0.000001)
		set_entvar(iTornado, var_friction, 0.01)

		new Float:fGameTime = get_gametime()
		new iTeam = 3
		if (iOwner)
			iTeam = get_member(iOwner, m_iTeam)

		set_entvar(iTornado, var_skin, iTeam - 1)
		set_entvar(iTornado, var_team, iTeam)
		set_entvar(iTornado, var_owner, iOwner)
		set_entvar(iTornado, var_impulse, IMPULSE_TORNADO)
		set_entvar(iTornado, var_tornado_endtime, fGameTime + TORNADO_LIFETIME)

		set_entvar(iTornado, var_animtime, fGameTime)
		set_entvar(iTornado, var_frame, 0.0)
		set_entvar(iTornado, var_framerate, 1.0)
		set_entvar(iTornado, var_effects, EF_FORCEVISIBILITY)

		SetThink(iTornado, "tornado_think")
		set_entvar(iTornado, var_nextthink, get_gametime())

		engfunc(EngFunc_EmitSound, iTornado, CHAN_STATIC, SOUND_TORNADO, 1.0, ATTN_STATIC, 0, PITCH_NORM)
		engfunc(EngFunc_EmitSound, iOwner, CHAN_AUTO, SOUND_TORNADO_JUMP, 1.0, ATTN_NORM, 0, PITCH_NORM)
		return iTornado
	}
	return FM_NULLENT
}

remove_tornado(iTornado)
{
	engfunc(EngFunc_EmitSound, iTornado, CHAN_STATIC, SOUND_TORNADO, 1.0, ATTN_STATIC, SND_STOP, PITCH_NORM)
	set_entvar(iTornado, var_flags, get_entvar(iTornado, var_flags) | FL_KILLME)
	set_entvar(iTornado, var_nextthink, get_gametime())
}

public tornado_think(iTornado)
{
	new Float:fGameTime = get_gametime()
	if (fGameTime > Float:get_entvar(iTornado, var_tornado_endtime))
	{
		remove_tornado(iTornado)
		return
	}

	new Float:fRadius = floatsqroot((TORNADO_RADIUS * TORNADO_RADIUS) + (TORNADO_HALF_HEIGHT * TORNADO_HALF_HEIGHT));

	new iTarget, Float:vOrigin[3]
	get_entvar(iTornado, var_origin, vOrigin)
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, fRadius)))
		tornado_touch(iTornado, iTarget)

	set_entvar(iTornado, var_nextthink, fGameTime)
}

tornado_touch(iTornado, iOther)
{
	if (is_nullent(iOther))
		return

	if (iOther > MaxClients && get_entvar(iOther, var_impulse) == IMPULSE_WIND_WAVE && fm_get_speed(iTornado) == 0.0)
	{
		new iWaveTeam = get_entvar(iOther, var_team)
		new iWaveOwner = get_entvar(iOther, var_iuser1)
		new iTornadoTeam = get_entvar(iTornado, var_team)

		if (iWaveTeam != iTornadoTeam || iWaveOwner == get_entvar(iTornado, var_owner))
		{
			new Float:vVelocity[3]
			get_entvar(iOther, var_velocity, vVelocity)
			xs_vec_normalize(vVelocity, vVelocity)
			xs_vec_mul_scalar(vVelocity, TORNADO_WAVE_PUSH_FORCE, vVelocity)

			set_entvar(iTornado, var_velocity, vVelocity)
			set_entvar(iTornado, var_framerate, 2.0)

			set_entvar(iTornado, var_skin, iWaveTeam - 1)
			set_entvar(iTornado, var_team, iWaveTeam)
			set_entvar(iTornado, var_owner, iWaveOwner)

			set_entvar(iOther, var_flags, FL_KILLME)
		}
	}

	if (!check_wind_impact(iTornado, iOther))
		return

	if (iOther <= MaxClients)
	{
		if (kc_player_get_windboost(iOther) == WINDBOOST_POSITIVE)
			return

		if (kc_player_get_bair(iOther) & FL_BAIR_LEAP)
			return

		if (kc_player_check_game_flag(iOther, PLGF_IN_BURNRUSH))
			return
	}

	static Float:vTornadoOrigin[3], Float:vEntOrigin[3]
	get_entvar(iTornado, var_origin, vTornadoOrigin)
	get_entvar(iOther, var_origin, vEntOrigin)

	static Float:vDirection[2], Float:fVecLen, Float:fTornadoDistance
	vDirection[0] = vTornadoOrigin[0] - vEntOrigin[0]
	vDirection[1] = vTornadoOrigin[1] - vEntOrigin[1]
	fTornadoDistance = xs_vec_len_2d(vDirection)

	if (fTornadoDistance > TORNADO_RADIUS)
		return

	fVecLen = 1.0 / fTornadoDistance
	vDirection[0] *= fVecLen
	vDirection[1] *= fVecLen

	static Float:fAcos
	fAcos = floatacos(vDirection[0], radian)
	if (vDirection[1] < 0.0)
		fAcos = M_PI + M_PI - fAcos
	fAcos += M_PI * 0.1

	static Float:vStartOrigin[2], Float:vEndOrigin[2]
	vStartOrigin[0] = vDirection[0] * TORNADO_RADIUS
	vStartOrigin[1] = vDirection[1] * TORNADO_RADIUS
	vEndOrigin[0] = floatcos(fAcos) * TORNADO_RADIUS
	vEndOrigin[1] = floatsin(fAcos) * TORNADO_RADIUS

	static Float:vVelocity[3]
	new Float:framerate = Float:get_entvar(iTornado, var_framerate)
	vVelocity[0] = vEndOrigin[0] - vStartOrigin[0]
	vVelocity[1] = vEndOrigin[1] - vStartOrigin[1]
	vVelocity[2] = 0.0
	xs_vec_normalize(vVelocity, vVelocity)
	xs_vec_mul_scalar(vVelocity, TORNADO_CIRCULAR_FORCE * framerate, vVelocity)

	static Float:vTornadoVelocity[3]
	get_entvar(iTornado, var_velocity, vTornadoVelocity)
	xs_vec_add(vVelocity, vTornadoVelocity, vVelocity)

	if (fTornadoDistance >= TORNADO_INNER_RADIUS)
	{
		vVelocity[0] += vDirection[0] * TORNADO_CENTER_FORCE
		vVelocity[1] += vDirection[1] * TORNADO_CENTER_FORCE
	}
	else
	{
		vVelocity[0] -= vDirection[0] * TORNADO_CENTER_FORCE
		vVelocity[1] -= vDirection[1] * TORNADO_CENTER_FORCE
	}
	vVelocity[2] = (vTornadoOrigin[2] - vEntOrigin[2]) * 5.0

	if (iOther <= MaxClients)
	{
		new iTornadoOwner = get_entvar(iTornado, var_owner)

		if (Player[iOther][PlrCaptureType] == CAPTURE_WEAK)
			kc_player_set_capture(iOther, CAPTURE_NONE)
		kc_player_set_bair(iOther, FL_BAIR_NORMAL | FL_BAIR_TORNADO | FL_BAIR_CLIMB)

		if (get_entvar(iTornado, var_body) == 1 && !kc_player_in_burn(iOther))
		{
			new Float:fTornadoLifeTime = Float:get_entvar(iTornado, var_tornado_endtime) - get_gametime()
			kc_player_burn(iOther, iTornadoOwner, floatround(fTornadoLifeTime / 0.2))
		}

		vTornadoVelocity[0] = floatclamp(vTornadoVelocity[0], -TORNADO_H_SPEED_WITH_PLRS, TORNADO_H_SPEED_WITH_PLRS)
		vTornadoVelocity[1] = floatclamp(vTornadoVelocity[1], -TORNADO_H_SPEED_WITH_PLRS, TORNADO_H_SPEED_WITH_PLRS)
		vTornadoVelocity[2] = floatclamp(vTornadoVelocity[2], -TORNADO_V_SPEED_WITH_PLRS, TORNADO_V_SPEED_WITH_PLRS)
		set_entvar(iTornado, var_velocity, vTornadoVelocity)

		kc_player_set_override_attacker(iOther, iTornadoOwner, 4.0)
	}

	set_entvar(iOther, var_velocity, vVelocity)
}

create_windwave(iOwner)
{
	new iWaveEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iWaveEnt))
		return NULLENT

	new Float:vOrigin[3], Float:vViewOfs[3]
	get_entvar(iOwner, var_origin, vOrigin)
	get_entvar(iOwner, var_view_ofs, vViewOfs)
	xs_vec_add(vOrigin, vViewOfs, vOrigin)

	new Float:vAngles[3], Float:vDirection[3]
	get_entvar(iOwner, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vDirection)
	vAngles[0] = -vAngles[0]

	new Float:vVelocity[3]
	xs_vec_mul_scalar(vDirection, WIND_WAVE_SPEED, vVelocity)

	xs_vec_mul_scalar(vDirection, WIND_WAVE_START_OFFSET, vDirection)
	xs_vec_add(vOrigin, vDirection, vOrigin)

	set_entvar(iWaveEnt, var_classname, CLASSNAME_WIND_WAVE)
	engfunc(EngFunc_SetModel, iWaveEnt, MODEL_WIND_WAVE)
	engfunc(EngFunc_SetSize, iWaveEnt,
		{ -WIND_WAVE_RADIUS, -WIND_WAVE_RADIUS, -WIND_WAVE_HALF_HEIGHT },
		{ WIND_WAVE_RADIUS, WIND_WAVE_RADIUS, WIND_WAVE_HALF_HEIGHT })
	engfunc(EngFunc_SetOrigin, iWaveEnt, vOrigin)

	set_entvar(iWaveEnt, var_origin, vOrigin)
	set_entvar(iWaveEnt, var_angles, vAngles)
	set_entvar(iWaveEnt, var_velocity, vVelocity)

	set_entvar(iWaveEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iWaveEnt, var_movetype, MOVETYPE_NOCLIP)

	new Float:fGameTime = get_gametime()
	new iTeam = get_member(iOwner, m_iTeam)

	set_entvar(iWaveEnt, var_skin, iTeam - 1)
	set_entvar(iWaveEnt, var_team, iTeam)
	set_entvar(iWaveEnt, var_iuser1, iOwner) // fake owner
	set_entvar(iWaveEnt, var_impulse, IMPULSE_WIND_WAVE)
	set_entvar(iWaveEnt, var_nextthink, fGameTime + WIND_WAVE_LIFETIME)

	send_msg_TE_BEAMFOLLOW(iWaveEnt, g_sprWindWave, 5, 20,
		iTeam == 1 ? {100, 100, 0} : {0, 100, 100}, 192)

	SetThink(iWaveEnt, "windwave_think")
	SetTouch(iWaveEnt, "windwave_touch")

	return iWaveEnt
}

remove_windwave(iWaveEnt)
{
	set_entvar(iWaveEnt, var_flags, get_entvar(iWaveEnt, var_flags) | FL_KILLME)
	set_entvar(iWaveEnt, var_nextthink, get_gametime())
}

public windwave_think(iWaveEnt)
{
	remove_windwave(iWaveEnt)
}

public windwave_touch(iWaveEnt, iOther)
{
	static Float:vWaveOrigin[3], Float:vWaveAngles[3], Float:vEntOrigin[3]
	static Float:vForward[3], Float:vRight[3], Float:vVelocity[3]

	if (is_nullent(iOther))
		return

	new iOtherImpulse = get_entvar(iOther, var_impulse)

	if (iOtherImpulse == IMPULSE_FIELD_WALL)
	{
		if (get_entvar(iWaveEnt, var_skin) != get_entvar(iOther, var_skin))
			remove_windwave(iWaveEnt)
		return
	}

	/*if (iOtherImpulse == IMPULSE_WIND_WAVE)
	{
		new Float:vOrigin[2][3], Float:vCenter[3]
		get_entvar(iWaveEnt, var_origin, vOrigin[0])
		get_entvar(iOther, var_origin, vOrigin[1])

		xs_vec_sub(vOrigin[1], vOrigin[0], vCenter)
		xs_vec_mul_scalar(vCenter, 0.5, vCenter)
		xs_vec_add(vOrigin[0], vCenter, vCenter)

		create_tornado(0, vCenter)

		remove_windwave(iWaveEnt)
		remove_windwave(iOther)
		return
	}*/

	if (!check_wind_impact(iWaveEnt, iOther))
		return

	new iWaveOwner = get_entvar(iWaveEnt, var_iuser1)

	get_entvar(iWaveEnt, var_origin, vWaveOrigin)

	if (kc_player_in_reflection(iOther))
	{
		set_entvar(iWaveEnt, var_iuser1, iOther)
		set_entvar(iWaveEnt, var_team, get_member(iOther, m_iTeam))

		new Float:vWaveOwnerOrigin[3]
		get_entvar(iWaveOwner, var_origin, vWaveOwnerOrigin)

		new Float:vReflectedVelocity[3]
		xs_vec_sub(vWaveOwnerOrigin, vWaveOrigin, vReflectedVelocity)
		xs_vec_normalize(vReflectedVelocity, vReflectedVelocity)
		xs_vec_mul_scalar(vReflectedVelocity, WIND_WAVE_SPEED, vReflectedVelocity)

		set_entvar(iWaveEnt, var_velocity, vReflectedVelocity)

		new Float:vReflectedAngles[3]
		vector_to_angle(vReflectedVelocity, vReflectedAngles)

		set_entvar(iWaveEnt, var_angles, vReflectedAngles)

		kc_player_reflection_done(iOther, iWaveOwner)
		return
	}

	get_entvar(iWaveEnt, var_angles, vWaveAngles)
	get_entvar(iOther, var_origin, vEntOrigin)

	angle_vector(vWaveAngles, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vWaveAngles, ANGLEVECTOR_RIGHT, vRight)
	vForward[2] = vRight[2] = 0.0

	xs_vec_normalize(vForward, vForward)
	xs_vec_normalize(vRight, vRight)

	xs_vec_sub(vEntOrigin, vWaveOrigin, vVelocity)
	vVelocity[2] = 0.0
	xs_vec_normalize(vVelocity, vVelocity)

	if (vForward[0] * vVelocity[1] - vForward[1] * vVelocity[0] > 0.0)
	{
		vRight[0] = -vRight[0]
		vRight[1] = -vRight[1]
	}
	vRight[2] = 1.0
	xs_vec_mul_scalar(vRight, WIND_WAVE_FORCE, vVelocity)

	set_entvar(iOther, var_velocity, vVelocity)

	if (iOther <= MaxClients)
	{
		kc_player_set_bair(iOther, FL_BAIR_NORMAL | FL_BAIR_CLIMB)
		kc_player_set_override_attacker(iOther, iWaveOwner, 4.0)
	}
}
