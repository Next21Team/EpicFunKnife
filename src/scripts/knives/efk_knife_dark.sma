#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Dark Knife"

#define KNIFE_CLASSNAME "weapon_next21_dark"
#define KNIFE_MENUDESC  "KNIFE_DARK_DESC"
#define KNIFE_CHATDESC  "KNIFE_DARK_CHAT"

#define HP				110.0
#define GRAVITY			1.0
#define SPEED			275.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define ABIL1_NAME		"Dark"
#define ABIL1_CHARGE	5.883
#define ABIL1_TYPE		ABIL_TARGET_FRIEND
#define ABIL1_MINDIST	30.0
#define ABIL1_MAXDIST	600.0

#define ABIL2_NAME		"Darkness"
#define ABIL2_CHARGE	2.5

#define DARKNESS_TIME		5.0

new const MODEL_V_KNIFE[]	= "models/next21_efk/v_dark_knife_b02.mdl"
new const MODEL_P_KNIFE[]	= "models/next21_efk/p_dark_knife.mdl"

new const MODEL_BLACKBOX[]	= "models/next21_efk/blackbox.mdl"

new const SOUND_DARKNESS[]		= "next21_efk/darkness.wav"
new const SOUND_SHADOWINFEST[]	= "next21_efk/shadow_infest.wav"
new const SOUND_SHADOWJUMP[]	= "next21_efk/shadow_jump.wav"

new const SOUND_KNIFE_HIT1[]	= "next21_efk/dark_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[]	= "next21_efk/dark_knife_hit2.wav"
new const SOUND_KNIFE_HITWALL[]	= "next21_efk/dark_knife_hitwall.wav"
new const SOUND_KNIFE_SLASH1[]	= "next21_efk/dark_knife_slash1.wav"
new const SOUND_KNIFE_SLASH2[]	= "next21_efk/dark_knife_slash2.wav"
new const SOUND_KNIFE_STAB[]	= "next21_efk/dark_knife_stab.wav"

new const SZ_INFO_TARGET[]	= "info_target"

enum _:PlayerData
{
	PlrKnife,
	PlrShadow
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
	g_iDarknessInitiator, g_iDarknessShadow,
	g_iBlackboxEnt,
	Float:g_vDarknessOrigin[3], Float:g_vDarknessAngles[3],
	g_pKnifePMdl

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)
	precache_sound(SOUND_KNIFE_STAB)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	precache_sound(SOUND_DARKNESS)
	precache_sound(SOUND_SHADOWINFEST)
	precache_sound(SOUND_SHADOWJUMP)

	precache_model(MODEL_BLACKBOX)
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

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)

	RegisterHam(Ham_TakeDamage, "player", "fw_Player_PostDamage", true)
}

public client_disconnected(iPlayer)
{
	remove_darkness_player_activity(iPlayer)
}

public fw_Player_PostDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (iVictim == g_iDarknessInitiator && iAttacker != iVictim && is_entity_player(iAttacker))
	{
		if (!is_user_alive(iVictim))
			return HAM_IGNORED

		if (iFlags & DMG_BURN)
			return HAM_IGNORED

		g_iDarknessShadow = 0
		reset_darkness_initator()
		kc_player_slow(iVictim, 0.5, 0.5)
	}

	return HAM_IGNORED
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (!is_entity_player(iTarget))
	{
		if (get_entvar(iTarget, var_impulse) == IMPULSE_ZOMBIE && get_entvar(iTarget, var_skin) + 1 == get_member(iPlayer, m_iTeam))
		{
			kc_player_set_crosshair(iPlayer, bDistanceAllowed ? CROSSHAIR_OK : CROSSHAIR_FAR)
			return PLUGIN_HANDLED
		}
		return PLUGIN_CONTINUE
	}

	if (Player[iTarget][PlrKnife] == g_iKnifeId)
		return _:CROSSHAIR_CANNOT

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrShadow] == iTarget || Player[i][PlrShadow] == iPlayer)
			return _:CROSSHAIR_CANNOT
	}

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][PlrKnife] = iKnifeId
	if (iPlayer == g_iDarknessInitiator)
	{
		g_iDarknessShadow = 0
		reset_darkness_initator()
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrShadow] == iPlayer)
		{
			if (iKnifeId == g_iKnifeId)
				kc_player_unshadow(i)
			break
		}
	}
}

public efk_ability_pre(iPlayer, iTarget)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (get_entvar(iTarget, var_impulse) == IMPULSE_ZOMBIE && get_entvar(iTarget, var_skin) + 1 == get_member(iPlayer, m_iTeam))
	{
		if (!efk_ability(iPlayer, iTarget))
		{
			kc_player_set_abil1_charge(iPlayer, -1.0)
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer, iTarget)
{
	if (is_entity_player(iTarget) && Player[iTarget][PlrKnife] == g_iKnifeId)
		return PLUGIN_HANDLED

	if (kc_player_shadow(iPlayer, iTarget))
	{
		engfunc(EngFunc_EmitSound, iTarget, CHAN_STATIC, SOUND_SHADOWINFEST, 1.0, ATTN_NORM, 0, PITCH_NORM)
		Player[iPlayer][PlrShadow] = iTarget
		return PLUGIN_CONTINUE
	}

	return PLUGIN_HANDLED
}

public efk_ability2(iPlayer)
{
	new iTeam = get_member(iPlayer, m_iTeam)

	if (kc_darkness(iTeam, DARKNESS_TIME))
	{
		client_cmd(0, "spk %s", SOUND_DARKNESS)

		g_iDarknessShadow = Player[iPlayer][PlrShadow]
		get_entvar(iPlayer, var_origin, g_vDarknessOrigin)
		get_entvar(iPlayer, var_v_angle, g_vDarknessAngles)

		g_iDarknessInitiator = iPlayer
		set_entvar(iPlayer, var_movetype, MOVETYPE_NOCLIP)
		kc_player_rush(iPlayer, 400.0, DARKNESS_TIME)

		g_iBlackboxEnt = rg_create_entity(SZ_INFO_TARGET, true)
		if (!is_nullent(g_iBlackboxEnt))
		{
			engfunc(EngFunc_SetModel, g_iBlackboxEnt, MODEL_BLACKBOX)
			engfunc(EngFunc_SetOrigin, g_iBlackboxEnt, NULL_VECTOR)
			engfunc(EngFunc_SetSize, g_iBlackboxEnt, Float:{-2048.0, -2048.0, -2048.0 }, Float:{ 2048.0,  2048.0, 2048.0 })

			set_entvar(g_iBlackboxEnt, var_origin, NULL_VECTOR)
			set_entvar(g_iBlackboxEnt, var_solid, SOLID_NOT)
			set_entvar(g_iBlackboxEnt, var_movetype, MOVETYPE_NONE)
			set_entvar(g_iBlackboxEnt, var_rendermode, kRenderNormal)

			set_entvar(g_iBlackboxEnt, var_impulse, IMPULSE_BLACKBOX)
		}

		return PLUGIN_CONTINUE
	}

	return PLUGIN_HANDLED
}

public efk_player_knife_killed(iVictim, iAttacker, iKnifeId)
{
	if (g_iKnifeId == iKnifeId)
		kc_player_clone(iAttacker, iVictim)

	remove_darkness_player_activity(iVictim)
}

public efk_unshadow(iPlayer)
{
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_SHADOWJUMP, 1.0, ATTN_NORM, 0, PITCH_NORM)
	Player[iPlayer][PlrShadow] = 0

	if (iPlayer == g_iDarknessInitiator)
	{
		get_entvar(iPlayer, var_origin, g_vDarknessOrigin)
		get_entvar(iPlayer, var_v_angle, g_vDarknessAngles)
		set_entvar(iPlayer, var_movetype, MOVETYPE_NOCLIP)
	}
}

public efk_undarkness()
{
	reset_darkness_initator()
	if (g_iBlackboxEnt)
	{
		rg_remove_entity(g_iBlackboxEnt)
		g_iBlackboxEnt = 0
	}
}

public efk_disenergy(iPlayer)
{
	if (iPlayer == g_iDarknessInitiator)
	{
		g_iDarknessShadow = 0
		reset_darkness_initator()
		kc_player_slow(iPlayer, 0.5, 0.5)
	}
}

remove_darkness_player_activity(iPlayer)
{
	if (g_iDarknessInitiator == iPlayer)
		g_iDarknessInitiator = 0

	if (g_iDarknessShadow == iPlayer)
		g_iDarknessShadow = 0
}

reset_darkness_initator()
{
	new iPlayer = g_iDarknessInitiator
	new iShadow = g_iDarknessShadow

	g_iDarknessInitiator = 0
	g_iDarknessShadow = 0

	if (!iPlayer)
		return

	if (!iShadow || is_nullent(iShadow))
	{
		move_to_darkness_position(iPlayer)
		return
	}

	if (!is_user_alive(iShadow) && get_entvar(iShadow, var_impulse) != IMPULSE_ZOMBIE)
	{
		move_to_darkness_position(iPlayer)
		return
	}

	if (iShadow == Player[iPlayer][PlrShadow])
		return

	if (efk_ability(iPlayer, iShadow))
		move_to_darkness_position(iPlayer)
}

move_to_darkness_position(iPlayer)
{
	engfunc(EngFunc_SetOrigin, iPlayer, g_vDarknessOrigin)
	set_entvar(iPlayer, var_origin, g_vDarknessOrigin)
	set_entvar(iPlayer, var_angles, g_vDarknessAngles)
	set_entvar(iPlayer, var_v_angle, g_vDarknessAngles)
	set_entvar(iPlayer, var_fixangle, 1)
	set_entvar(iPlayer, var_movetype, MOVETYPE_WALK)

	kc_player_check_stuck_delayed(iPlayer, 0.3)
}
