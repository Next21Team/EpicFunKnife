#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <beams>
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

#define ABIL3_NAME	"Shadow Link"
#define ABIL3_CHARGE	50.0

#define SHADOWLINK_MAX_MEMBERS	10
#define SHADOWLINK_ANGLE	50.0
#define SHADOWLINK_RADIUS	550.0
#define SHADOWLINK_THINK_TIME	0.2
#define SHADOWLINK_HEAL_AMOUNT	2.0
#define SHADOWLINK_HEAL_DELAY	1.0

#define SHADOWLINK_NOISE_MAX	random_num(5, 10)
#define SHADOWLINK_WIDTH_MIN	3.0
#define SHADOWLINK_WIDTH_MAX	18.0
#define SHADOWLINK_FREQ_MIN	0.05
#define SHADOWLINK_FREQ_MAX	0.10
#define SHADOWLINK_SINE_MIN_DIST	160.0

#define SHADOWLINK_BEAM_KEY	8739

#define ABIL4_NAME	"Shadow Jump"
#define ABIL4_CHARGE	50.0


new const MODEL_V_KNIFE[]	= "models/next21_efk/v_dark_knife_b02.mdl"
new const MODEL_P_KNIFE[]	= "models/next21_efk/p_dark_knife.mdl"

new const MODEL_BLACKBOX[]	= "models/next21_efk/blackbox.mdl"

new const SOUND_DARKNESS[]		= "next21_efk/darkness.wav"
new const SOUND_SHADOWLINK[]	= "next21_efk/shadow_link.wav"
new const SOUND_SHADOWINFEST[]	= "next21_efk/shadow_infest.wav"
new const SOUND_SHADOWJUMP[]	= "next21_efk/shadow_jump.wav"

new const SOUND_VIC_FLASHED[]    = "next21_efk/flashed.wav"

new const SOUND_KNIFE_HIT1[]	= "next21_efk/dark_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[]	= "next21_efk/dark_knife_hit2.wav"
new const SOUND_KNIFE_HITWALL[]	= "next21_efk/dark_knife_hitwall.wav"
new const SOUND_KNIFE_SLASH1[]	= "next21_efk/dark_knife_slash1.wav"
new const SOUND_KNIFE_SLASH2[]	= "next21_efk/dark_knife_slash2.wav"
new const SOUND_KNIFE_STAB[]	= "next21_efk/dark_knife_stab.wav"

new const MODEL_SHADOW_LINK[]		= "sprites/next21_efk/razorbeam.spr"
new const SZ_INFO_TARGET[]	= "info_target"

enum _:PlayerData
{
	PlrKnife,
	PlrShadow,
	PlrLink,
	PlrBeam
}

new Float:g_flNextShadowThink[MAX_PLAYERS]
new Float:g_flNextShadowHeal[MAX_PLAYERS]

new Float:g_flBlindStamp[MAX_PLAYERS]

new g_eShadowLink[MAX_PLAYERS][SHADOWLINK_MAX_MEMBERS][PlayerData]
new bool:g_bShadowJump[MAX_PLAYERS]

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
	precache_sound(SOUND_SHADOWLINK)
	precache_sound(SOUND_SHADOWINFEST)
	precache_sound(SOUND_SHADOWJUMP)
	
	precache_sound(SOUND_VIC_FLASHED)

	precache_model(MODEL_SHADOW_LINK)

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
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)
	kc_register_ability4(g_iKnifeId, ABIL4_NAME, ABIL4_CHARGE)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)

	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Post", true)
	register_forward(FM_CheckVisibility, "FM_CheckVisibility_Pre", false)

	RegisterHam(Ham_TakeDamage, "player", "fw_Player_PostDamage", true)
	RegisterHam(Ham_Think, "beam", "shadowlink_beam_think_post", true)
}

public client_disconnected(iPlayer)
{
	g_bShadowJump[iPlayer] = false
	g_flNextShadowThink[iPlayer] = 0.0
	g_flNextShadowHeal[iPlayer] = 0.0
	remove_darkness_player_activity(iPlayer)
	shadowlink_delete(iPlayer)
}

public FM_CheckVisibility_Pre(iBeam)
{
	if (pev_valid(iBeam) && get_entvar(iBeam, var_impulse) == SHADOWLINK_BEAM_KEY)
	{
		forward_return(FMV_CELL, true)
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

public RG_CBasePlayer_PreThink_Post(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return HC_CONTINUE;

	if (!is_user_alive(iPlayer))
	{
		shadowlink_reset(iPlayer)
		return HC_CONTINUE
	}

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
	{
		shadowlink_delete_owned(iPlayer)
		return HC_CONTINUE
	}

	if (g_flNextShadowThink[iPlayer] > get_gametime())
		return HC_CONTINUE

	g_flNextShadowThink[iPlayer] = get_gametime() + SHADOWLINK_THINK_TIME

	if (kc_player_in_silence(iPlayer))
	{
		shadowlink_delete(iPlayer)
		return HC_CONTINUE
	}

	shadowlink_think_player(iPlayer)

	return HC_CONTINUE
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

	/* iPlayer may currently occupy a Shadow Link member slot he never
	 * created himself - inherited via Swap Knife (see efk_swap() /
	 * shadowlink_transfer_member()). Whatever knife he's switching to
	 * now (including back to Dark Knife itself, which is exactly the
	 * scenario that caused real problems - a Swap Knife enemy who is
	 * also, independently, a member of someone else's group becoming a
	 * Dark Knife owner himself), that inherited membership no longer
	 * makes sense and must be dropped. */
	shadowlink_break_external_links(0, iPlayer)
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

	new iOldAnchor = Player[iPlayer][PlrShadow]

	if (kc_player_shadow(iPlayer, iTarget))
	{
		engfunc(EngFunc_EmitSound, iTarget, CHAN_STATIC, SOUND_SHADOWINFEST, 1.0, ATTN_NORM, 0, PITCH_NORM)
		Player[iPlayer][PlrShadow] = iTarget

		shadowlink_break_external_links(iPlayer, iTarget)

		if (iPlayer == g_iDarknessInitiator)
			g_iDarknessShadow = iTarget

		if (iOldAnchor && iOldAnchor != iTarget && is_user_alive(iOldAnchor))
		{
			shadowlink_refresh_anchor(iPlayer)
			shadowlink_add_member(iPlayer, iOldAnchor)
		}

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

public efk_ability3(iPlayer)
{
	new iAnchor = Player[iPlayer][PlrShadow]

	if (!is_user_alive(iAnchor))
		return PLUGIN_HANDLED

	new iTarget = find_player_in_view(iPlayer, SHADOWLINK_ANGLE, SHADOWLINK_RADIUS, iAnchor)

	if (!iTarget || !is_user_alive(iTarget))
		return PLUGIN_HANDLED

	if (get_member(iPlayer, m_iTeam) != get_member(iTarget, m_iTeam))
		return PLUGIN_HANDLED


	if (Player[iTarget][PlrKnife] == g_iKnifeId)
		return PLUGIN_HANDLED

	if (!shadowlink_in_radius(iAnchor, iTarget))
		return PLUGIN_HANDLED

	if (shadowlink_is_active(iPlayer, iTarget))
		return PLUGIN_HANDLED

	if (shadowlink_is_full(iPlayer))
		return PLUGIN_HANDLED

	if (!shadowlink_add_member(iPlayer, iTarget))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public efk_ability4(iPlayer)
{
	new iAnchor = Player[iPlayer][PlrShadow]

	if (!is_user_alive(iAnchor))
		return PLUGIN_HANDLED

	new iTarget = find_player_in_view(iPlayer, SHADOWLINK_ANGLE, SHADOWLINK_RADIUS, iAnchor)

	if (!iTarget || !is_user_alive(iTarget))
		return PLUGIN_HANDLED

	if (!shadowlink_is_active(iPlayer, iTarget))
		return PLUGIN_HANDLED

	if (get_member(iPlayer, m_iTeam) != get_member(iTarget, m_iTeam))
		return PLUGIN_HANDLED

	g_bShadowJump[iPlayer] = true

	new bool:bShadowed = kc_player_shadow(iPlayer, iTarget)
	if (!bShadowed)
	{
		g_bShadowJump[iPlayer] = false
		return PLUGIN_HANDLED
	}

	Player[iPlayer][PlrShadow] = iTarget
	g_bShadowJump[iPlayer] = false

	if (iPlayer == g_iDarknessInitiator)
		g_iDarknessShadow = iTarget


	shadowlink_refresh_anchor(iPlayer)
	shadowlink_add_member(iPlayer, iAnchor)

	return PLUGIN_CONTINUE
}

public efk_player_knife_killed(iVictim, iAttacker, iKnifeId)
{
	if (g_iKnifeId == iKnifeId)
		kc_player_clone(iAttacker, iVictim)

	remove_darkness_player_activity(iVictim)
	shadowlink_reset(iVictim)
}

public efk_unshadow(iPlayer)
{
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC,g_bShadowJump[iPlayer] ? SOUND_SHADOWLINK : SOUND_SHADOWJUMP,1.0, ATTN_NORM, 0, PITCH_NORM)

	new iOwner = iPlayer

	if (!Player[iOwner][PlrShadow])
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (Player[i][PlrShadow] == iPlayer)
			{
				iOwner = i
				break
			}
		}
	}

	if (!g_bShadowJump[iOwner])
		Player[iOwner][PlrShadow] = 0

	if (iPlayer == g_iDarknessInitiator)
	{
		get_entvar(iPlayer, var_origin, g_vDarknessOrigin)
		get_entvar(iPlayer, var_v_angle, g_vDarknessAngles)
		set_entvar(iPlayer, var_movetype, MOVETYPE_NOCLIP)

		g_iDarknessShadow = 0
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

public efk_swap(iPlayer, iTarget)
{
	/* iPlayer might already be embedded in a different Dark Knife
	 * owner's group from an earlier swap (or from having switched
	 * knives and back). This swap physically relocates him again, so
	 * that earlier membership no longer makes sense and must be
	 * dropped before we possibly establish a new one below. */
	shadowlink_break_external_links(0, iPlayer)

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrKnife] != g_iKnifeId)
			continue

		new iSlot = shadowlink_find_slot(i, iTarget)
		if (iSlot < 0)
			continue

		shadowlink_transfer_member(i, iSlot, iPlayer)
	}
}

public efk_blind(iPlayer, iMode, Float:fBlindTime)
{
	if (Player[iPlayer][PlrKnife] == g_iKnifeId)
	{
		shadowlink_blind_owner_group(iPlayer, iMode, fBlindTime, iPlayer)
		return
	}

	new iOwner = shadowlink_owner_possessing(iPlayer)
	if (iOwner)
	{
		shadowlink_blind_owner_group(iOwner, iMode, fBlindTime, iPlayer)
		return
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrKnife] != g_iKnifeId)
			continue

		if (!shadowlink_is_active(i, iPlayer))
			continue

		shadowlink_blind_owner_group(i, iMode, fBlindTime, iPlayer)
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

	new iOwner = (Player[iPlayer][PlrKnife] == g_iKnifeId) ? iPlayer : shadowlink_owner_possessing(iPlayer)

	if (iOwner)
		shadowlink_delete(iOwner)

	shadowlink_break_external_links(0, iPlayer)
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
		shadowlink_delete(iPlayer)
		return
	}

	if (!is_user_alive(iShadow) && get_entvar(iShadow, var_impulse) != IMPULSE_ZOMBIE)
	{
		move_to_darkness_position(iPlayer)
		shadowlink_delete(iPlayer)
		return
	}

	if (iShadow == Player[iPlayer][PlrShadow])
		return

	if (efk_ability(iPlayer, iShadow))
	{
		move_to_darkness_position(iPlayer)
		shadowlink_delete(iPlayer)
	}
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

stock shadowlink_find_slot(iPlayer, iTarget)
{
	for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
	{
		if (g_eShadowLink[iPlayer - 1][i][PlrLink] == iTarget)
			return i
	}

	return -1
}

stock shadowlink_count_members(iPlayer)
{
	new iAnchor = Player[iPlayer][PlrShadow]
	new iCount

	for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
	{
		new iTarget = g_eShadowLink[iPlayer - 1][i][PlrLink]

		if (iTarget && iTarget != iAnchor)
			iCount++
	}

	return iCount
}

stock bool:shadowlink_is_active(iPlayer, iTarget)
{
	return (iTarget > 0 && shadowlink_find_slot(iPlayer, iTarget) >= 0)
}

stock bool:shadowlink_is_full(iPlayer)
{
	return shadowlink_count_members(iPlayer) >= SHADOWLINK_MAX_MEMBERS
}

stock bool:shadowlink_can_link(iPlayer, iTarget)
{
	if (!is_user_alive(iPlayer) || !is_user_alive(iTarget))
		return false

	new iAnchor = Player[iPlayer][PlrShadow]

	if (!iAnchor)
		return false

	if (get_member(iPlayer, m_iTeam) != get_member(iTarget, m_iTeam))
		return false

	if (Player[iTarget][PlrKnife] == g_iKnifeId)
		return false

	new iOtherOwner = shadowlink_owner_possessing(iTarget)
	if (iOtherOwner && iOtherOwner != iPlayer)
		return false

	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == iPlayer)
			continue

		if (Player[i][PlrKnife] != g_iKnifeId)
			continue

		if (shadowlink_is_active(i, iTarget))
			return false
	}

	if (iTarget == iPlayer || iTarget == iAnchor)
		return false

	if (!shadowlink_in_radius(iAnchor, iTarget))
		return false

	if (shadowlink_is_active(iPlayer, iTarget))
		return false

	if (shadowlink_is_full(iPlayer))
		return false

	return true
}

stock shadowlink_create_beam(iPlayer, iTarget)
{
	new iAnchor = Player[iPlayer][PlrShadow]

	if (!is_user_alive(iAnchor) || !is_user_alive(iTarget))
		return 0

	new Float:vAnchor[3], Float:vTarget[3]
	get_entvar(iAnchor, var_origin, vAnchor)
	get_entvar(iTarget, var_origin, vTarget)

	new Float:fDistance = get_distance_f(vAnchor, vTarget)
	new Float:fBreakPercent = fDistance / SHADOWLINK_RADIUS

	if (fBreakPercent > 1.0)
		fBreakPercent = 1.0

	new Float:fWidth = SHADOWLINK_WIDTH_MAX - (SHADOWLINK_WIDTH_MAX - SHADOWLINK_WIDTH_MIN) * fBreakPercent

	new iBeam = Beam_Create(MODEL_SHADOW_LINK, fWidth)
	if (is_nullent(iBeam))
		return 0

	Beam_EntsInit(iBeam, iAnchor, iTarget)
	Beam_SetColor(iBeam, {0.0, 0.0, 0.0})

	if (fDistance <= SHADOWLINK_SINE_MIN_DIST)
		Beam_SetFlags(iBeam, BEAM_FSOLID)
	else
		Beam_SetFlags(iBeam, BEAM_FSINE | BEAM_FSOLID)

	Beam_SetNoise(iBeam, 1)
	Beam_SetScrollRate(iBeam, 35.0)

	set_entvar(iBeam, var_impulse, SHADOWLINK_BEAM_KEY)
	set_pev(iBeam, var_shadowlink_owner, iPlayer)
	set_pev(iBeam, pev_nextthink, get_gametime() + 0.05)

	return iBeam
}

public shadowlink_beam_think_post(iBeam)
{
	if (get_entvar(iBeam, var_impulse) != SHADOWLINK_BEAM_KEY)
		return

	new iAnchor = pev(iBeam, pev_owner)
	new iTarget = pev(iBeam, pev_aiment)

	if (!is_user_alive(iAnchor) || !is_user_alive(iTarget))
		return

	new Float:vAnchor[3], Float:vTarget[3]
	get_entvar(iAnchor, var_origin, vAnchor)
	get_entvar(iTarget, var_origin, vTarget)

	new Float:fDistance = get_distance_f(vAnchor, vTarget)
	new Float:fBreakPercent = fDistance / SHADOWLINK_RADIUS

	if (fBreakPercent > 1.0)
		fBreakPercent = 1.0

	new Float:fUpdateRate = SHADOWLINK_FREQ_MAX - (SHADOWLINK_FREQ_MAX - SHADOWLINK_FREQ_MIN) * fBreakPercent
	new Float:fWidth = SHADOWLINK_WIDTH_MAX - (SHADOWLINK_WIDTH_MAX - SHADOWLINK_WIDTH_MIN) * fBreakPercent

	if (fDistance <= SHADOWLINK_SINE_MIN_DIST)
		Beam_SetFlags(iBeam, BEAM_FSOLID)
	else
		Beam_SetFlags(iBeam, BEAM_FSINE | BEAM_FSOLID)

	new iNoise = Beam_GetNoise(iBeam)
	new iResizeDir = pev(iBeam, var_shadowlink_resizedir)
	new iMaxNoise = pev(iBeam, var_shadowlink_noisemax)

	if (!iMaxNoise)
		iMaxNoise = SHADOWLINK_NOISE_MAX
	if (!iResizeDir)
		iResizeDir = 1

	iNoise += iResizeDir
	if ((iResizeDir > 0 && iNoise > iMaxNoise) || !iNoise)
	{
		iResizeDir = -iResizeDir
		set_pev(iBeam, var_shadowlink_noisemax, SHADOWLINK_NOISE_MAX)
	}

	Beam_SetNoise(iBeam, iNoise)
	Beam_SetWidth(iBeam, fWidth)
	set_pev(iBeam, var_shadowlink_resizedir, iResizeDir)

	set_pev(iBeam, pev_nextthink, get_gametime() + fUpdateRate)
}

stock bool:shadowlink_add_member(iPlayer, iTarget)
{
	if (!shadowlink_can_link(iPlayer, iTarget))
		return false

	new iAnchor = Player[iPlayer][PlrShadow]
	new iSlot = -1

	for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
	{
		if (!g_eShadowLink[iPlayer - 1][i][PlrLink])
		{
			iSlot = i
			break
		}
	}

	if (iSlot < 0)
	{
		for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
		{
			if (g_eShadowLink[iPlayer - 1][i][PlrLink] == iAnchor)
			{
				shadowlink_remove_slot(iPlayer, i)
				iSlot = i
				break
			}
		}
	}

	if (iSlot < 0)
		return false

	new iBeam = shadowlink_create_beam(iPlayer, iTarget)
	if (!iBeam)
		return false

	g_eShadowLink[iPlayer - 1][iSlot][PlrLink] = iTarget
	g_eShadowLink[iPlayer - 1][iSlot][PlrBeam] = iBeam

	return true
}

stock shadowlink_remove_slot(iPlayer, iSlot)
{
	if (iSlot < 0 || iSlot >= SHADOWLINK_MAX_MEMBERS)
		return

	new iBeam = g_eShadowLink[iPlayer - 1][iSlot][PlrBeam]
	if (iBeam && pev_valid(iBeam))
		rg_remove_entity(iBeam)

	g_eShadowLink[iPlayer - 1][iSlot][PlrLink] = 0
	g_eShadowLink[iPlayer - 1][iSlot][PlrBeam] = 0
}

stock shadowlink_remove_member(iPlayer, iTarget)
{
	new iSlot = shadowlink_find_slot(iPlayer, iTarget)
	if (iSlot >= 0)
		shadowlink_remove_slot(iPlayer, iSlot)
}

stock shadowlink_transfer_member(iOwner, iSlot, iNewTarget)
{
	new iBeam = g_eShadowLink[iOwner - 1][iSlot][PlrBeam]
	if (iBeam && pev_valid(iBeam))
		rg_remove_entity(iBeam)

	g_eShadowLink[iOwner - 1][iSlot][PlrLink] = iNewTarget
	g_eShadowLink[iOwner - 1][iSlot][PlrBeam] = 0
}

stock shadowlink_blind_player(iPlayer, iMode, Float:fBlindTime, bool:bPlaySound)
{
	if (iPlayer < 1 || iPlayer > MaxClients || !is_user_alive(iPlayer))
		return

	new Float:fNow = get_gametime()

	if (g_flBlindStamp[iPlayer - 1] == fNow)
		return

	g_flBlindStamp[iPlayer - 1] = fNow
	kc_player_blind(iPlayer, iMode, fBlindTime)

	if (bPlaySound)
		client_cmd(iPlayer, "spk %s", SOUND_VIC_FLASHED)
}

stock shadowlink_blind_owner_group(iOwner, iMode, Float:fBlindTime, iOriginalVictim)
{
	shadowlink_blind_player(iOwner, iMode, fBlindTime, iOwner != iOriginalVictim)

	new iShadow = Player[iOwner][PlrShadow]
	if (iShadow && iShadow != iOwner && is_user_alive(iShadow))
	{
		shadowlink_blind_player(iShadow, iMode, fBlindTime, iShadow != iOriginalVictim)
	}

	for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
	{
		new iMember = g_eShadowLink[iOwner - 1][i][PlrLink]
		if (!iMember || !is_user_alive(iMember))
			continue

		new bool:bPlaySound = (iMember != iOriginalVictim) && (shadowlink_owner_possessing(iMember) == 0)
		shadowlink_blind_player(iMember, iMode, fBlindTime, bPlaySound)
	}
}

stock shadowlink_owner_possessing(iTarget)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrKnife] != g_iKnifeId)
			continue

		if (Player[i][PlrShadow] == iTarget)
			return i
	}

	return 0
}

stock shadowlink_break_external_links(iOwner, iTarget)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == iOwner)
			continue

		if (Player[i][PlrKnife] != g_iKnifeId)
			continue

		shadowlink_remove_member(i, iTarget)
	}
}

stock bool:shadowlink_in_radius(iAnchor, iTarget)
{
	if (!is_user_alive(iAnchor) || !is_user_alive(iTarget))
		return false

	new Float:vAnchor[3], Float:vTarget[3]
	get_entvar(iAnchor, var_origin, vAnchor)
	get_entvar(iTarget, var_origin, vTarget)

	return get_distance_f(vAnchor, vTarget) <= SHADOWLINK_RADIUS
}

stock shadowlink_rebuild_beam(iPlayer, iSlot, iAnchor, bool:bForce)
{
	new iTarget = g_eShadowLink[iPlayer - 1][iSlot][PlrLink]
	new iBeam = g_eShadowLink[iPlayer - 1][iSlot][PlrBeam]

	if (iAnchor == iTarget)
	{
		if (iBeam && pev_valid(iBeam))
			rg_remove_entity(iBeam)

		g_eShadowLink[iPlayer - 1][iSlot][PlrBeam] = 0
		return
	}

	if (bForce && iBeam && pev_valid(iBeam))
	{
		rg_remove_entity(iBeam)
		iBeam = 0
	}

	if (iBeam && pev_valid(iBeam))
		return

	iBeam = shadowlink_create_beam(iPlayer, iTarget)
	if (iBeam)
		g_eShadowLink[iPlayer - 1][iSlot][PlrBeam] = iBeam
	else
		shadowlink_remove_slot(iPlayer, iSlot)
}

stock shadowlink_think_player(iPlayer)
{
	new iAnchor = Player[iPlayer][PlrShadow]
	new bool:bHasLink = false

	for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
	{
		new iTarget = g_eShadowLink[iPlayer - 1][i][PlrLink]
		if (!iTarget)
			continue

		if (!shadowlink_in_radius(iAnchor, iTarget))
		{
			shadowlink_remove_slot(iPlayer, i)
			continue
		}

		bHasLink = true
		shadowlink_rebuild_beam(iPlayer, i, iAnchor, false)
	}

	if (!bHasLink || g_flNextShadowHeal[iPlayer] > get_gametime())
		return

	g_flNextShadowHeal[iPlayer] = get_gametime() + SHADOWLINK_HEAL_DELAY

	for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
	{
		new iTarget = g_eShadowLink[iPlayer - 1][i][PlrLink]
		if (!iTarget || iTarget == iAnchor || !is_user_alive(iTarget))
			continue

		new Float:fMaxHealth = kc_player_get_maxhealth(iTarget)
		new Float:fHealth = Float:get_entvar(iTarget, var_health)

		if (fHealth >= fMaxHealth)
			continue

		new Float:fNewHealth = fHealth + SHADOWLINK_HEAL_AMOUNT
		if (fNewHealth > fMaxHealth)
			fNewHealth = fMaxHealth

		set_entvar(iTarget, var_health, fNewHealth)
	}
}

stock shadowlink_refresh_anchor(iPlayer)
{
	new iAnchor = Player[iPlayer][PlrShadow]

	for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
	{
		if (!g_eShadowLink[iPlayer - 1][i][PlrLink])
			continue

		shadowlink_rebuild_beam(iPlayer, i, iAnchor, true)
	}
}

stock shadowlink_delete(iPlayer)
{
	for (new i = 0; i < SHADOWLINK_MAX_MEMBERS; i++)
		shadowlink_remove_slot(iPlayer, i)
}

stock shadowlink_delete_owned(iPlayer)
{
	shadowlink_delete(iPlayer)
}

stock shadowlink_reset(iPlayer)
{
	shadowlink_delete(iPlayer)
}

