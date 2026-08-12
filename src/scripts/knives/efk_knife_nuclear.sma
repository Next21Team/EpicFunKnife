#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>
#include <object/efk_web_utils>
#include <object/efk_tornado_utils>

new const PLUGIN[] = "EFK: Nuclear Knife"

#define KNIFE_CLASSNAME "weapon_next21_nuclear"
#define KNIFE_MENUDESC  "KNIFE_NUCLEAR_DESC"
#define KNIFE_CHATDESC  "KNIFE_NUCLEAR_CHAT"

#define HP				160.0
#define GRAVITY			1.0
#define SPEED			165.0
#define MINDAMAGE		10.0
#define MAXDAMAGE		25.0

#define ABIL1_NAME		"Nuclear"
#define ABIL1_CHARGE	5.2632

#define ABIL2_NAME		"Explosion"
#define ABIL2_CHARGE	5.0

#define ABIL3_NAME		"Hot Speed"
#define ABIL3_CHARGE	10.0

#define RUSH_SPEED			280.0
#define RUSH_TIME			5.0
#define RUSH_SELF_DAMAGE	15.0
#define RUSH_MIN_HEALTH		31.0

#define UNABILITY_TIME		10.0
#define START_PAIR			0.8
#define EXPLOSION_RADIUS	160.0
#define EXPLOSION_DAMAGE	100.0
#define VELOCITY_BACK		2000.0
#define BURN_CYCLES			3

new const MODEL_V_KNIFE[]		= "models/next21_efk/v_nuclear_knife_b02.mdl"
new const MODEL_P_KNIFE[]		= "models/next21_efk/p_nuclear_knife_a.mdl"

new const SOUND_KNIFE_DEPLOY[]	= "next21_efk/nuclear_knife_deploy.wav"
new const SOUND_KNIFE_HIT1[]	= "next21_efk/nuclear_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[]	= "next21_efk/nuclear_knife_hit1.wav"
new const SOUND_KNIFE_STAB[]	= "next21_efk/nuclear_knife_stab.wav"
new const SOUND_KNIFE_HITWALL[]	= "next21_efk/nuclear_knife_hitwall.wav"
new const SOUND_KNIFE_SLASH[]	= "next21_efk/nuclear_knife_slash.wav"

new const SOUND_ABILITY[]		= "next21_efk/nuclear_ability.wav"
new const SOUND_EXPLOSION[]		= "next21_efk/nuclear_explosion.wav"
new const SOUND_HOTSPEED[]		= "next21_efk/hot_speed.wav"
new const SOUND_HEAVYFALL[]		= "next21_efk/heavy_fall.wav"

#define TASK_UNABILITY		32673
#define TASK_RUSH_SPEED		50000

enum _:PlayerData
{
	PlrKnife,
	Float:PairEndTime
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
	g_pExplosionSpr, g_pSteamSpr, g_pBallSmokeSpr, g_pShockWaveSpr,
	g_pKnifePMdl

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_ABILITY)
	precache_sound(SOUND_EXPLOSION)
	precache_sound(SOUND_HOTSPEED)
	precache_sound(SOUND_HEAVYFALL)

	precache_sound(SOUND_KNIFE_DEPLOY)
	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_STAB)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	g_pExplosionSpr = precache_model("sprites/next21_efk/nuclear_explosion.spr")
	g_pSteamSpr = precache_model("sprites/steam1.spr")
	g_pBallSmokeSpr = precache_model("sprites/ballsmoke.spr")
	g_pShockWaveSpr = precache_model("sprites/shockwave.spr")
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		engfunc(EngFunc_AllocString, MODEL_V_KNIFE), engfunc(EngFunc_AllocString, MODEL_P_KNIFE),
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, ABIL1_CHARGE)
	kc_register_ability2(g_iKnifeId, ABIL2_NAME, ABIL2_CHARGE)
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)

	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_HAMMER)
	kc_knife_set_charge_boost_coeff(g_iKnifeId, 0.25)
	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLEABLE | KNFF_BAN_BUNNYHOP)

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Pre")
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG_CBasePlayer_TraceAttack_Pre")
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_Damage")
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_PostDamage", true)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH)
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][PlrKnife] = -1
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	Player[iPlayer][PairEndTime] = 0.0
	remove_task(TASK_UNABILITY + iPlayer)
}

public RG_CBasePlayer_Killed_Pre(iPlayer)
{
	Player[iPlayer][PairEndTime] = 0.0
	remove_task(TASK_UNABILITY + iPlayer)
}

public RG_CBasePlayer_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vDirection[3], iTraceId)
{
	if (!is_entity_player(iAttacker))
		return HC_CONTINUE

	if (Player[iAttacker][PlrKnife] != g_iKnifeId || get_user_weapon(iAttacker) != CSW_KNIFE)
		return HC_CONTINUE

	if (get_member(iVictim, m_iTeam) == get_member(iAttacker, m_iTeam))
		return HC_CONTINUE

	if (~get_entvar(iVictim, var_flags) & FL_ONGROUND)
		return HC_CONTINUE

	if (get_tr2(iTraceId, TR_iHitgroup) == HIT_SHIELD)
		return HC_CONTINUE

	new CaptureType:iCaptureType = kc_player_get_capture(iVictim)
	if (iCaptureType == CAPTURE_NORMAL || iCaptureType == CAPTURE_STRONG)
		return HC_CONTINUE

	new Float:vVictimOrigin[3], Float:vAttackerOrigin[3]
	get_entvar(iVictim, var_origin, vVictimOrigin)
	get_entvar(iAttacker, var_origin, vAttackerOrigin)

	if (get_distance_f(vVictimOrigin, vAttackerOrigin) > 100)
		return HC_CONTINUE

	new Float:vVictimVelocity[3]
	get_entvar(iVictim, var_velocity, vVictimVelocity)

	new Float:vForceVelocity[3]
	xs_vec_mul_scalar(vDirection, fDamage, vForceVelocity)

	new bool:bInDucking = get_entvar(iVictim, var_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	if (bInDucking)
		xs_vec_mul_scalar(vForceVelocity, 0.5, vForceVelocity)

	xs_vec_mul_scalar(vForceVelocity, random_float(7.0, 11.0), vForceVelocity)
	xs_vec_add(vVictimVelocity, vForceVelocity, vForceVelocity)
	vForceVelocity[2] = 400.0

	set_entvar(iVictim, var_velocity, vForceVelocity)

	kc_player_set_override_attacker(iVictim, iAttacker, 3.0)

	return HC_CONTINUE
}

public fw_Player_Damage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (Player[iVictim][PlrKnife] == g_iKnifeId)
	{
		if (iFlags & DMG_BURN)
			return HAM_IGNORED

		kc_player_set_abil2_charge(iVictim, floatmin(85.0, kc_player_get_abil2_charge(iVictim)))

		if ((iFlags & DMG_FALL) && iVictim == iInflictor && !entity_in_any_web(iVictim))
		{
			new iEnt = NULLENT, Float:vOrigin[3]
			get_entvar(iVictim, var_origin, vOrigin)

			new Float:vVelocity[3], Float:vEntOrigin[3], Float:fDistance, Float:fNewSpeed, Float:fRadius
			fRadius = floatmin(fDamage * 5.0, 150.0)

			engfunc(EngFunc_EmitSound, iVictim, CHAN_AUTO, SOUND_HEAVYFALL, 1.0, ATTN_NORM, 0, PITCH_NORM)
			draw_landing_effect(iVictim)

			new iTeam = get_user_team(iVictim)

			while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, fRadius)))
			{
				if (iEnt != iVictim && is_user_alive(iEnt)
					&& iTeam != get_user_team(iEnt)
					&& !kc_player_check_game_flag(iEnt, PLGF_IN_UNABILITY))
				{
					kc_player_set_override_attacker(iEnt, iVictim, 4.0)

					get_entvar(iEnt, var_origin, vEntOrigin)

					fDistance = get_distance_f(vOrigin, vEntOrigin)
					fNewSpeed = VELOCITY_BACK * (1.0 - (fDistance / fRadius))
					get_speed_vector(vOrigin, vEntOrigin, fNewSpeed, vVelocity)

					vVelocity[2] = 400.0
					set_entvar(iEnt, var_velocity, vVelocity)

					new iDmg = random_num(10, 15)

					kc_player_set_death_reason(iEnt, "DEATH_REASON_FALL")
					set_member(iEnt, m_LastHitGroup, HIT_GENERIC)
					ExecuteHamB(Ham_TakeDamage, iEnt, iVictim, iVictim, float(iDmg), DMG_ENERGYBEAM)
				}
				else
				{
					if (get_entvar(iEnt, var_flags) & FL_MONSTER)
					{
						if (iTeam != get_entvar(iEnt, var_skin) + 1)
						{
							get_entvar(iEnt, var_origin, vEntOrigin)

							fDistance = get_distance_f(vOrigin, vEntOrigin)
							fNewSpeed = VELOCITY_BACK * (1.0 - (fDistance / fRadius))
							get_speed_vector(vOrigin, vEntOrigin, fNewSpeed, vVelocity)

							vVelocity[2] = 400.0
							set_entvar(iEnt, var_velocity, vVelocity)

							new iDmg = random_num(10, 15)

							ExecuteHamB(Ham_TakeDamage, iEnt, 0, iEnt, float(iDmg), DMG_ENERGYBEAM)
						}
					}
				}
			}
		}
	}

	if (!iInflictor || iAttacker == iVictim || !is_entity_player(iAttacker))
		return HAM_IGNORED

	new Float:fPair = Player[iVictim][PairEndTime]
	new Float:fGameTime = get_gametime()

	if (fPair < fGameTime)
		return HAM_IGNORED

	switch (get_entvar(iInflictor, var_impulse))
	{
		case IMPULSE_ZOMBIE:
		{
			if (kc_player_get_vision(iVictim) != VISION_BLIND && !kc_player_in_freeze(iVictim) && !kc_player_in_chill(iVictim))
				send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {0, 255, 0}, 35, MSG_ONE, _, iVictim)

			ExecuteHamB(Ham_TakeDamage, iInflictor, iVictim, iVictim, 1337.0, iFlags)

			return HAM_SUPERCEDE
		}
		case IMPULSE_ZOMBIE_SPIT:
			return HAM_SUPERCEDE
	}

	if (!(iFlags & (DMG_BULLET | DMG_FALL)))
		return HAM_IGNORED

	if ((iFlags & DMG_FALL) && iVictim == iInflictor)
		return HAM_IGNORED

	if (Player[iAttacker][PairEndTime] >= fGameTime)
		return HAM_IGNORED

	if (kc_player_get_vision(iAttacker) != VISION_BLIND && !kc_player_in_freeze(iAttacker) && !kc_player_in_chill(iAttacker))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 0, 0}, 35, MSG_ONE, _, iAttacker)

	if (kc_player_get_vision(iVictim) != VISION_BLIND && !kc_player_in_freeze(iVictim) && !kc_player_in_chill(iVictim))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {0, 255, 0}, 35, MSG_ONE, _, iVictim)

	new iDamage, Float:fReflect
	fReflect = (fPair - fGameTime) / UNABILITY_TIME * START_PAIR
	iDamage = min(floatround(fDamage * fReflect), 75)

	kc_player_set_death_reason(iAttacker, "DEATH_REASON_PAIR")
	set_member(iAttacker, m_LastHitGroup, get_member(iVictim, m_LastHitGroup))
	ExecuteHamB(Ham_TakeDamage, iAttacker, iInflictor, iVictim, iDamage + 0.0, iFlags & ~(DMG_BULLET | DMG_FALL))

	client_print(iVictim, print_center, "%L %d", iVictim, "DAMAGE_REFLECTED", iDamage)

	return HAM_IGNORED
}

public fw_Player_PostDamage(iPlayer, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (Player[iPlayer][PlrKnife] == g_iKnifeId && is_user_alive(iPlayer) && kc_player_check_game_flag(iPlayer, PLGF_IN_UNABILITY))
		set_member(iPlayer, m_flVelocityModifier, 1.0)
}

public efk_status_draw(iPlayer, iSubject)
{
	new Float:fPair = Player[iSubject][PairEndTime] - get_gametime()
	if (fPair > 0.0)
	{
		fPair = fPair / UNABILITY_TIME * START_PAIR * 100.0

		set_hudmessage(255, 255, 255, -1.0, -0.30, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "%L %..1f%%", iPlayer, "DAMAGE_REFLECTED_COEFF", fPair)
	}
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	if (Player[iPlayer][PairEndTime] >= get_gametime())
	{
		kc_player_unset_game_flag(iPlayer, PLGF_IN_UNABILITY)
		kc_player_sub_glow(iPlayer, 255, 130, 0)
		Player[iPlayer][PairEndTime] = 0.0
		remove_task(TASK_UNABILITY + iPlayer)
	}

	Player[iPlayer][PlrKnife] = iKnifeId
}

public efk_ability(iPlayer)
{
	kc_player_unprotection(iPlayer)

	kc_player_add_glow(iPlayer, UNABILITY_TIME, 255, 130, 0)

	if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {8, 37, 103}, 130, MSG_ONE, _, iPlayer)

	kc_player_set_game_flag(iPlayer, PLGF_IN_UNABILITY)
	remove_task(TASK_UNABILITY + iPlayer)
	set_task(UNABILITY_TIME, "task_remove_unability", TASK_UNABILITY + iPlayer)

	if (kc_player_get_windboost(iPlayer) == WINDBOOST_NEGATIVE)
		kc_player_set_windboost(iPlayer, WINDBOOST_NONE)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_ABILITY, 1.0, ATTN_NORM, 0, PITCH_NORM)

	Player[iPlayer][PairEndTime] = get_gametime() + UNABILITY_TIME
}

public efk_ability2(iPlayer)
{
	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	new Float:fHealth = get_entvar(iPlayer, var_health)
	new Float:fRadius = EXPLOSION_RADIUS + fHealth

	new Float:vVecA[3], Float:vVecB[3]
	vVecA[0] = vOrigin[0]
	vVecA[1] = vOrigin[1]
	vVecB[0] = vOrigin[0]
	vVecB[1] = vOrigin[1]

	vVecA[2] = vOrigin[2] + 5.0
	send_msg_TE_EXPLOSION(vVecA, g_pExplosionSpr, 30, 12, TE_EXPLFLAG_NOSOUND)

	vVecA[2] = vOrigin[2] + 15.0
	send_msg_TE_SMOKE(vVecA, g_pSteamSpr, 60, 10, MSG_PVS, vOrigin)

	vVecA[2] = vOrigin[2] - 10.0
	vVecB[2] = vOrigin[2] + fRadius
	send_msg_TE_BEAMCYLINDER(vVecA, vVecB, g_pShockWaveSpr, 0, 0, 2, 5, 0, {255, 130, 0}, 100, 0)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_EXPLOSION, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new Float:vEntOrigin[3], Float:fDamage, Float:vVelocity[3]
	new iTeam = get_user_team(iPlayer)

	new iEnt = -1
	while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, fRadius)) > 0)
	{
		if (iEnt == iPlayer)
			continue

		if (is_user_alive(iEnt))
		{
			if (iTeam != get_user_team(iEnt) && !kc_player_check_game_flag(iEnt, PLGF_IN_UNABILITY))
			{
				get_entvar(iEnt, var_origin, vEntOrigin)
				fDamage = floatmax(1.0 - get_distance_f(vOrigin, vEntOrigin) / fRadius, 0.05)

				kc_player_set_override_attacker(iEnt, iPlayer, 4.0)
				kc_player_set_death_reason(iEnt, "DEATH_REASON_EXPLODE")
				set_member(iEnt, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iEnt, iPlayer, iPlayer, fDamage * EXPLOSION_DAMAGE, DMG_ENERGYBEAM | DMG_ALWAYSGIB)

				xs_vec_sub(vEntOrigin, vOrigin, vVelocity)
				xs_vec_normalize(vVelocity, vVelocity)
				xs_vec_mul_scalar(vVelocity, fDamage * VELOCITY_BACK, vVelocity)
				vVelocity[2] = 400.0
				set_entvar(iEnt, var_velocity, vVelocity)
			}

			kc_player_burn(iEnt, iPlayer, BURN_CYCLES)
		}
		else if (get_entvar(iEnt, var_flags) & FL_MONSTER)
		{
			if (iTeam != get_entvar(iEnt, var_skin) + 1)
			{
				get_entvar(iEnt, var_origin, vEntOrigin)
				fDamage = floatmax(1.0 - get_distance_f(vOrigin, vEntOrigin) / fRadius, 0.05)

				xs_vec_sub(vEntOrigin, vOrigin, vVelocity)
				xs_vec_normalize(vVelocity, vVelocity)
				xs_vec_mul_scalar(vVelocity, fDamage * VELOCITY_BACK, vVelocity)
				vVelocity[2] = 400.0
				set_entvar(iEnt, var_velocity, vVelocity)

				ExecuteHamB(Ham_TakeDamage, iEnt, 0, iEnt, fDamage * EXPLOSION_DAMAGE, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
			}
		}
		else if (get_entvar(iEnt, var_impulse) == IMPULSE_TORNADO)
		{
			if (iTeam == get_entvar(iEnt, var_team))
				tornado_burn(iEnt)
		}
	}

	new Float:fFrags = Float:get_entvar(iPlayer, var_frags)
	kc_player_set_death_reason(iPlayer, "DEATH_REASON_EXPLODE")
	set_member(iPlayer, m_LastHitGroup, HIT_GENERIC)
	ExecuteHamB(Ham_TakeDamage, iPlayer, iPlayer, iPlayer, 2000.0, DMG_GENERIC | DMG_ALWAYSGIB)
	set_entvar(iPlayer, var_frags, fFrags)
}

public efk_ability3(iPlayer)
{
	new Float:fHealth = Float:get_entvar(iPlayer, var_health)
	if (fHealth < RUSH_MIN_HEALTH)
		return PLUGIN_HANDLED

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_HOTSPEED, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_entvar(iPlayer, var_health, fHealth - RUSH_SELF_DAMAGE)

	kc_player_rush(iPlayer, RUSH_SPEED + kc_player_get_powerspeed(iPlayer), RUSH_TIME)

	// Keep re-adding the live (still decaying) powerspeed on top of the rush base for as
	// long as the rush lasts, instead of freezing it at the value from the moment of cast.
	remove_task(iPlayer + TASK_RUSH_SPEED)
	set_task(0.5, "task_nuclear_rush_update", iPlayer + TASK_RUSH_SPEED, _, _, "a",
		floatround(RUSH_TIME / 0.5, floatround_ceil))

	return PLUGIN_CONTINUE
}

public task_nuclear_rush_update(iTaskId)
{
	new iPlayer = iTaskId - TASK_RUSH_SPEED

	if (!is_user_alive(iPlayer))
	{
		remove_task(iTaskId)
		return
	}

	kc_player_set_maxspeed(iPlayer, RUSH_SPEED + kc_player_get_powerspeed(iPlayer))
}

public task_remove_unability(iTaskId)
{
	new iPlayer = iTaskId - TASK_UNABILITY
	kc_player_unset_game_flag(iPlayer, PLGF_IN_UNABILITY)
}

draw_landing_effect(iEnt)
{
	new Float:vOrigin[3]
	get_entvar(iEnt, var_origin, vOrigin)

	new Float:vFloorOrigin[3]
	xs_vec_copy(vOrigin, vFloorOrigin)
	vFloorOrigin[2] -= 64.0

	new iTrace, Float:fFraction, iHit
	engfunc(EngFunc_TraceLine, vOrigin, vFloorOrigin, IGNORE_MONSTERS, iEnt, iTrace)
	get_tr2(iTrace, TR_vecEndPos, vFloorOrigin)
	get_tr2(iTrace, TR_flFraction, fFraction)
	get_tr2(iTrace, TR_pHit)
	free_tr2(iTrace)

	if (fFraction == 1.0)
		return

	new iDecal = random_num(138, 141)

	if (iHit)
	{
		if (!is_nullent(iHit) && (~get_entvar(iHit, var_flags) & FL_KILLME) && (get_entvar(iHit, var_solid) == SOLID_BSP))
			send_msg_TE_DECAL(vFloorOrigin, iDecal, iHit, MSG_PAS, vFloorOrigin)
	}
	else
	{
		send_msg_TE_WORLDDECAL(vFloorOrigin, iDecal, MSG_PAS, vFloorOrigin)
	}

	send_msg_TE_SPRITE(vFloorOrigin, g_pBallSmokeSpr, 8, 80, MSG_PAS, vFloorOrigin)
}
