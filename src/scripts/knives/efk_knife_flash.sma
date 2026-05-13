#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Flash Knife"

new const GAME_TAG[] = EFK_GAME_TAG

#define KNIFE_CLASSNAME "weapon_next21_flash"
#define KNIFE_MENUDESC  "KNIFE_FLASH_DESC"
#define KNIFE_CHATDESC  "KNIFE_FLASH_CHAT"

#define HP				90.0
#define GRAVITY			1.0
#define SPEED			270.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define ABIL1_NAME		"Flash"
#define ABIL1_CHARGE	6.667
#define ABIL1_TYPE		ABIL_TARGET_ENEMY
#define ABIL1_MINDIST	75.0
#define ABIL1_MAXDIST	1200.0

#define ABIL2_NAME		"Silence"
#define ABIL2_CHARGE	3.704

#define ABIL3_NAME		"Bug"
#define ABIL3_CHARGE	8.334

new const MODEL_V_KNIFE[] = "models/next21_efk/v_flash_knife_b02.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_flash_knife.mdl"

new const SOUND_VIC_FLASHED[] = "next21_efk/flashed.wav"
new const SOUND_FLASH[] = "next21_efk/flash_activation.wav"
new const SOUND_SILENCE[] = "next21_efk/silence.wav"

new const SOUND_KNIFE_HIT1[] = "next21_efk/flash_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[] = "next21_efk/flash_knife_hit2.wav"
new const SOUND_KNIFE_HIT3[] = "next21_efk/flash_knife_hit3.wav"
new const SOUND_KNIFE_HIT4[] = "next21_efk/flash_knife_hit4.wav"
new const SOUND_KNIFE_SLASH1[] = "next21_efk/flash_knife_slash1.wav"
new const SOUND_KNIFE_SLASH2[] = "next21_efk/flash_knife_slash2.wav"

new const MODEL_BUG[] = "models/next21_efk/bug.mdl"

new const SOUND_BUG_THROW[] = "next21_efk/bug_throw.wav"

#define BLIND_TIME		4.0
#define BLIND_DAMAGE		90.0
#define SILENCE_TIME		6.0

#define var_bug_realowner			var_iuser2
#define var_bug_thinkstep			var_iuser4
#define var_bug_touchstep			var_iuser3

#define var_bug_nextattack			var_fuser2
#define var_bug_nexthit      		var_fuser3
#define var_bug_nexthunt     		var_fuser4

#define var_bug_prevpos				var_vuser2
#define var_bug_target				var_vuser3

#define BUG_HEALTH_REF			10000.0

#define BUG_HEALTH					2.0
#define BUG_GRAVITY 				0.5
#define BUG_FRICTION				0.5
#define BUG_DAMAGE				24.0
#define BUG_SEARCH_RADIUS  512.0
#define BUG_FOV						0

#define BUG_SEQ_IDLE		0
#define BUG_SEQ_FIDGET	1
#define BUG_SEQ_JUMP		2
#define BUG_SEQ_RUN		3

#define BUG_THINK_HUNT			0
#define BUG_THINK_SBT			1
#define BUG_THINK_REMOVE		2

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_THROW
}

new const SZ_INFO_TARGET[]			= "info_target"

enum _:Player_Properties
{
	PlrKnife,
	PlrLastBlinded,
	PlrBugCuts,
	bool:PlrFlashedSomeone
}

#define Player[%1][%2]	g_player_data[%1 - 1][%2]

new
g_iKnifeId, g_player_data[MAX_PLAYERS][Player_Properties], Float:g_fBlindedTime[MAX_PLAYERS + 1],
sprSmokebeam, sprBloodSpray, sprBlood,
g_pKnifeVStr, g_pKnifePMdl

public plugin_precache()
{
	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_HIT3)
	precache_sound(SOUND_KNIFE_HIT4)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)

	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(MODEL_BUG)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	precache_sound(SOUND_VIC_FLASHED)
	precache_sound(SOUND_FLASH)
	precache_sound(SOUND_SILENCE)
	precache_sound(SOUND_BUG_THROW)

	sprSmokebeam = precache_model("sprites/smoke.spr")
	sprBloodSpray = precache_model ("sprites/bloodspray.spr")
	sprBlood = precache_model ("sprites/blood.spr")
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

	kc_knife_set_flags(g_iKnifeId, KNFF_FULL_VISION)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT3)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT4)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)

	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)
	RegisterHam(Ham_TakeDamage, SZ_INFO_TARGET, "fw_InfoTargetDamage")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_SecondaryAttack", 1)

	// register_forward(FM_ShouldCollide, "fw_ShouldCollide")
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][PlrLastBlinded] = 0

	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_BUG))) {
		if (get_entvar(iEnt, var_bug_realowner) == iPlayer)
		{
			kill_bug(iEnt)
			break
		}
	}
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_BUG)))
		kill_bug(iEnt)

	for (new i = 1; i <= MaxClients; i++)
		Player[i][PlrFlashedSomeone] = false
}

public fw_PlayerDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (GetHamReturnStatus() != HAM_SUPERCEDE
		&& iAttacker && is_entity_player(iInflictor)
		&& Player[iVictim][PlrLastBlinded] == iAttacker
		&& (iFlags & DMG_BULLET)
		&& get_user_weapon(iAttacker) == CSW_KNIFE)
	{
		if (fDamage < BLIND_DAMAGE)
			SetHamParamFloat(4, BLIND_DAMAGE)

		client_print_color(iAttacker, print_team_default, "^4[%s] ^1%L", PLUGIN, iAttacker, "CRIT_ATTACKER")
		client_print_color(iVictim, print_team_default, "^4[%s] ^1%L", PLUGIN, iVictim, "CRIT_VICTIM")
	}
}

public fw_PlayerKilled(iVictim, attacker)
{
	Player[iVictim][PlrLastBlinded] = 0
	new iEnt = NULLENT, iRealOwner
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_BUG)))
	{
		iRealOwner = get_entvar(iEnt, var_bug_realowner)

		if (get_entvar(iEnt, var_owner) == iVictim)
			set_entvar(iEnt, var_owner, iRealOwner)

		if (iRealOwner == iVictim)
		{
			kill_bug(iEnt)
			break
		}
	}
}

public fw_InfoTargetDamage(iEnt, inflictor, attacker, Float:damage, bits)
{
	if (is_bug(iEnt) && is_user_alive(attacker))
		return (get_member(attacker, m_iTeam) == get_entvar(iEnt, var_skin) + 1) ? HAM_SUPERCEDE : HAM_IGNORED

	return HAM_IGNORED
}

/*public fw_ShouldCollide(iEnt, iOther)
{
	if (!is_bug(iEnt))
		return FMRES_IGNORED

	if (is_entity_player(iOther) && get_member(iOther, m_iTeam) == get_entvar(iEnt, var_skin) + 1)
	{
		forward_return(FMV_CELL, 0)
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}*/

public efk_status_draw(iPlayer, iSubject)
{
	if (!Player[iSubject][PlrFlashedSomeone])
		return PLUGIN_CONTINUE

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrLastBlinded] == iSubject)
		{
			set_hudmessage(255, 255, 255, -1.0, -0.30, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
			show_hudmessage(iPlayer, "%L", iPlayer, "CRIT_BLIND", i, g_fBlindedTime[i] - get_gametime())

			break
		}
	}

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][PlrKnife] = iKnifeId
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	new Float:vStartOrigin[3], Float:vEndOrigin[3]
	get_entvar(iPlayer, var_origin, vStartOrigin)
	get_entvar(iPlayer, var_view_ofs, vEndOrigin)
	xs_vec_add(vStartOrigin, vEndOrigin, vStartOrigin)
	get_tr2(0, TR_vecEndPos, vEndOrigin)

	new Float:fDist, iGhost = check_ghost(iPlayer, vStartOrigin, vEndOrigin, fDist)
	if (iGhost)
	{
		kc_player_set_crosshair(iPlayer, (ABIL1_MINDIST > fDist || fDist > ABIL1_MAXDIST) ? CROSSHAIR_FAR : CROSSHAIR_OK)
		return PLUGIN_HANDLED
	}

	if (is_entity_player(iTarget) && Player[iTarget][PlrLastBlinded] > 0)
		return _:CROSSHAIR_CANNOT

	return PLUGIN_CONTINUE
}

public fw_SecondaryAttack(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HAM_IGNORED

	if (!kc_player_can_ability(iPlayer, 1) || !kc_player_is_abil1_ready(iPlayer))
		return HAM_IGNORED

	new Float:vStartOrigin[3], Float:vEndOrigin[3]
	get_entvar(iPlayer, var_origin, vStartOrigin)
	get_entvar(iPlayer, var_view_ofs, vEndOrigin)
	xs_vec_add(vStartOrigin, vEndOrigin, vStartOrigin)
	get_entvar(iPlayer, var_v_angle, vEndOrigin)
	engfunc(EngFunc_MakeVectors, vEndOrigin)
	global_get(glb_v_forward, vEndOrigin)
	xs_vec_mul_scalar(vEndOrigin, 9999.9, vEndOrigin)
	xs_vec_add(vStartOrigin, vEndOrigin, vEndOrigin)
	engfunc(EngFunc_TraceLine, vStartOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, iPlayer, 0)
	get_tr2(0, TR_vecEndPos, vEndOrigin)

	new Float:fDist, iGhost = check_ghost(iPlayer, vStartOrigin, vEndOrigin, fDist)
	if (iGhost && ABIL1_MINDIST <= fDist && fDist <= ABIL1_MAXDIST)
	{
		new iVictim = get_entvar(iGhost, var_owner)
		if (is_user_alive(iVictim) && !efk_ability(iPlayer, iVictim))
			kc_player_set_abil1_charge(iPlayer, -1.0)
	}

	return HAM_IGNORED
}

public efk_ability(iPlayer, iTarget)
{
	if (kc_player_in_reflection(iTarget))
	{
		if (!player_flash(iTarget, iPlayer))
			return PLUGIN_HANDLED

		kc_player_reflection_done(iTarget, iPlayer)
	}
	else if (!player_flash(iPlayer, iTarget))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

bool:player_flash(iPlayer, iTarget)
{
	if (!kc_player_blind(iTarget, 0, BLIND_TIME))
		return false

	kc_player_set_override_attacker(iTarget, iPlayer, BLIND_TIME)
	Player[iTarget][PlrLastBlinded] = iPlayer
	g_fBlindedTime[iTarget] = get_gametime() + BLIND_TIME
	Player[iPlayer][PlrFlashedSomeone] = true

	client_cmd(iPlayer, "spk %s", SOUND_FLASH)
	client_cmd(iTarget, "spk %s", SOUND_VIC_FLASHED)

	return true
}

public efk_ability2(iPlayer)
{
	new iTeam = get_member(iPlayer, m_iTeam)

	if (kc_silence(iTeam, SILENCE_TIME))
	{
		client_print_color(0, iTeam == 1 ? print_team_blue : print_team_red, "^4[%s] ^1%L",
			GAME_TAG, LANG_PLAYER, iTeam == 1 ? "SILENCE_CT" : "SILENCE_T")

		client_cmd(0, "spk %s", SOUND_SILENCE)
		return PLUGIN_CONTINUE
	}

	return PLUGIN_HANDLED
}

public efk_ability3(iPlayer)
{
	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return PLUGIN_HANDLED

	new Float:vOrigin[3], Float:vAngles[3], Float:vVector[3], Float:vEndOrigin[3], Float:fFraction, pTrace
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vVector)
	xs_vec_add(vOrigin, vVector, vOrigin)

	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vVector)
	xs_vec_mul_scalar(vVector, 30.0, vVector)
	xs_vec_add(vOrigin, vVector, vEndOrigin)

	pTrace = create_tr2()
	engfunc(EngFunc_TraceLine, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, iPlayer, pTrace)
	get_tr2(pTrace, TR_vecEndPos, vEndOrigin)
	get_tr2(pTrace, TR_flFraction, fFraction)

	if (get_tr2(pTrace, TR_AllSolid) || get_tr2(pTrace, TR_StartSolid) || fFraction < 1.0)
	{
		free_tr2(pTrace)
		return PLUGIN_HANDLED
	}
	free_tr2(pTrace)

	pTrace = create_tr2()
	engfunc(EngFunc_TraceHull, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, pTrace)
	get_tr2(pTrace, TR_flFraction, fFraction)
	free_tr2(pTrace)

	if (fFraction < 1.0)
		return PLUGIN_HANDLED

	new ent = NULLENT
	while ((ent = rg_find_ent_by_class(ent, CLASSNAME_BUG)))
		if (get_entvar(ent, var_bug_realowner) == iPlayer)
		{
			kill_bug(ent)
			break
		}

	ent = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(ent))
		return PLUGIN_HANDLED

	set_entvar(ent, var_movetype, MOVETYPE_BOUNCE)
	set_entvar(ent, var_solid, SOLID_BBOX)

	engfunc(EngFunc_SetModel, ent, MODEL_BUG)
	engfunc(EngFunc_SetSize, ent, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 8.0})
	engfunc(EngFunc_SetOrigin, ent, vEndOrigin)

	new Float:fGameTime = get_gametime()

	set_entvar(ent, var_origin, vEndOrigin)
	set_entvar(ent, var_classname, CLASSNAME_BUG)
	set_entvar(ent, var_impulse, IMPULSE_BUG)
	set_entvar(ent, var_owner, iPlayer)
	set_entvar(ent, var_bug_realowner, iPlayer)
	set_entvar(ent, var_angles, vAngles)

	xs_vec_mul_scalar(vVector, 6.6, vVector)

	new Float:vUp[3]
	angle_vector(vAngles, ANGLEVECTOR_UP, vUp)
	xs_vec_mul_scalar(vUp, 100.0, vUp)
	xs_vec_add(vVector, vUp, vVector)

	set_entvar(ent, var_velocity, vVector)

	set_entvar(ent, var_bug_thinkstep, BUG_THINK_HUNT)
	set_entvar(ent, var_bug_touchstep, BUG_THINK_SBT)

	set_entvar(ent, var_nextthink, fGameTime + 0.1)
	set_entvar(ent, var_bug_nexthunt, fGameTime + 1000000.0)

	set_entvar(ent, var_flags, get_entvar(ent, var_flags) | FL_MONSTER)
	set_entvar(ent, var_takedamage, DAMAGE_AIM)
	set_entvar(ent, var_health, BUG_HEALTH_REF + BUG_HEALTH)
	set_entvar(ent, var_gravity, BUG_GRAVITY)
	set_entvar(ent, var_friction, BUG_FRICTION)
	set_entvar(ent, var_dmg, BUG_DAMAGE)
	set_entvar(ent, var_skin, get_member(iPlayer, m_iTeam) - 1)

	set_entvar(ent, var_rendermode, kRenderTransAdd)
	set_entvar(ent, var_renderfx, kRenderFxDistort)
	set_entvar(ent, var_renderamt, 150.0)

	set_entvar(ent, var_sequence, BUG_SEQ_RUN)
	set_entvar(ent, var_framerate,  1.0)
	set_entvar(ent, var_animtime, fGameTime)

	SetThink(ent, "bug_think")
	SetTouch(ent, "bug_touch")

	send_msg_TE_BEAMFOLLOW(ent, sprSmokebeam, 40, 2, {255, 255, 255}, 200, MSG_ALL)

	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, SOUND_BUG_THROW, 1.0, ATTN_NORM, 0, PITCH_NORM)

	kc_player_set_view_anim(iPlayer, VIEW_SEQ_THROW)

	new iWeapon = get_member(iPlayer, m_pActiveItem)
	if (!is_nullent(iWeapon))
	{
		set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 0.7)
		set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 0.7)
		set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 0.7)
	}

	Player[iPlayer][PlrBugCuts] = 3

	return PLUGIN_CONTINUE
}

public efk_unblind(iPlayer, bool:bBreaked)
{
	Player[iPlayer][PlrLastBlinded] = 0
	if (bBreaked)
		client_cmd(iPlayer, "stopsound")
}

public bug_think(iEnt)
{
	switch (get_entvar(iEnt, var_bug_thinkstep))
	{
		case BUG_THINK_HUNT:
		{
			static Float:vOrigin[3], Float:vVelocity[3]

			get_entvar(iEnt, var_origin, vOrigin)
			get_entvar(iEnt, var_velocity, vVelocity)

			if (!in_world(vOrigin, vVelocity))
			{
				set_entvar(iEnt, var_bug_thinkstep, 0)
				set_entvar(iEnt, var_flags, FL_KILLME)
				return
			}

			static Float:fNextHunt, Float:fHealth
			new Float:fGameTime = get_gametime()
			fHealth = Float:get_entvar(iEnt, var_health)

			set_entvar(iEnt, var_nextthink, fGameTime + 0.1)

			if (fHealth < BUG_HEALTH_REF + BUG_HEALTH)
			{
				set_entvar(iEnt, var_health, -1.0)
				set_pev(iEnt, pev_model, 0)
				set_entvar(iEnt, var_bug_thinkstep, BUG_THINK_REMOVE)
				set_entvar(iEnt, var_bug_touchstep, 0)

				set_entvar(iEnt, var_takedamage, DAMAGE_NO)
				set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) &~ FL_MONSTER)

				send_msg_TE_BLOODSPRITE(vOrigin, sprBloodSpray, sprBlood, 8, 16)

				return
			}

			if (get_entvar(iEnt, var_waterlevel))
			{
				if (get_entvar(iEnt, var_movetype) == MOVETYPE_BOUNCE)
					set_entvar(iEnt, var_movetype, MOVETYPE_FLY)

				xs_vec_mul_scalar(vVelocity, 0.9, vVelocity)
				vVelocity[2] += 8.0
				set_entvar(iEnt, var_velocity, vVelocity)
			}
			else if (get_entvar(iEnt, var_movetype ) == MOVETYPE_FLY)
				set_entvar(iEnt, var_movetype, MOVETYPE_BOUNCE)

			fNextHunt = Float:get_entvar(iEnt, var_bug_nexthunt)

			if (fNextHunt > fGameTime)
				return

			set_entvar(iEnt, var_bug_nexthunt, fGameTime + 2.0)

			static Float:vDir[3], Float:vAngles[3]
			static iEnemy

			get_entvar(iEnt, var_angles, vAngles)
			engfunc(EngFunc_MakeVectors, vAngles)

			iEnemy = get_entvar(iEnt, var_enemy)

			if (!iEnemy || !is_user_alive(iEnemy))
				iEnemy = best_visible_enemy(iEnt, vOrigin)

			if (iEnemy)
			{
				static Float:vTarget[3]

				static Float:vEyePosition[3]
				get_eye_position(iEnemy, vEyePosition)

				xs_vec_sub(vEyePosition, vOrigin, vDir)
				xs_vec_normalize(vDir, vTarget)

				set_entvar(iEnt, var_bug_target, vTarget)

				static Float:fVel, Float:fAdj
				get_entvar(iEnt, var_velocity, vVelocity)

				fVel = xs_vec_len(vVelocity)
				fAdj = 50.0 / (fVel + 10.0)

				if (fAdj > 1.2)
					fAdj = 1.2

				get_entvar(iEnt, var_bug_target, vTarget)

				vVelocity[0] = vVelocity[0] * fAdj + vTarget[0] * 300.0
				vVelocity[1] = vVelocity[1] * fAdj + vTarget[1] * 300.0
				vVelocity[2] = vVelocity[2] * fAdj + vTarget[2] * 300.0

				set_entvar(iEnt, var_velocity, vVelocity)
			}

			if (get_entvar(iEnt, var_flags) & FL_ONGROUND)
				set_entvar(iEnt, var_avelocity, NULL_VECTOR)
			else
			{
				static Float:vAvelocity[3]
				get_entvar(iEnt, var_avelocity, vAvelocity)

				if (vAvelocity[0] == 0.0 && vAvelocity[1] == 0.0 && vAvelocity[2] == 0.0)
				{
					vAvelocity[0] = random_float(-100.0, 100.0)
					vAvelocity[1] = random_float(-100.0, 100.0)

					set_entvar(iEnt, var_avelocity, vAvelocity)
				}
			}

			static Float:vPrevPos[3]

			get_entvar(iEnt, var_bug_prevpos, vPrevPos)
			get_entvar(iEnt, var_velocity, vVelocity)

			xs_vec_sub(vOrigin, vPrevPos, vPrevPos)

			if (xs_vec_len(vPrevPos) < 1.0)
			{
				vVelocity[0] = random_float(-100.0, 100.0);
				vVelocity[1] = random_float(-100.0, 100.0);

				set_entvar(iEnt, var_velocity, vVelocity)
			}

			xs_vec_copy(vOrigin, vPrevPos)
			set_entvar(iEnt, var_bug_prevpos, vPrevPos)

			engfunc(EngFunc_VecToAngles, vVelocity, vAngles)

			vAngles[2] = 0.0
			vAngles[0] = 0.0

			set_entvar(iEnt, var_angles, vAngles)
		}
		case BUG_THINK_REMOVE:
		{
			set_entvar(iEnt, var_flags, FL_KILLME)
		}
	}
}

public bug_touch(iEnt, iOther)
{
	if (is_entity_player(iOther) && get_entvar(iEnt, var_skin) + 1 == get_member(iOther, m_iTeam))
		set_entvar(iEnt, var_owner, iOther)

	if (get_entvar(iEnt, var_bug_touchstep) && !is_bug(iOther))
	{
		static Float:vAngles[3], Float:fNextHit, Float:fNextAttack

		if (iOther && iOther == get_entvar(iEnt, var_bug_realowner))
			return

		new Float:fGameTime = get_gametime()

		get_entvar(iEnt, var_angles, vAngles)
		fNextHit = Float:get_entvar(iEnt, var_bug_nexthit)

		vAngles[0] = 0.0;
		vAngles[2] = 0.0;

		set_entvar(iEnt, var_angles, vAngles)

		if (fNextHit > fGameTime)
			return

		fNextAttack = Float:get_entvar(iEnt, var_bug_nextattack)

		if (fNextAttack < fGameTime && is_user_alive(iOther))
		{
			new iOwner = get_entvar(iEnt, var_bug_realowner)
			if (get_user_team(iOwner) != get_user_team(iOther))
			{
				if (kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY)
					&& kc_player_get_visibility(iOther) != VIS_CLONE)
				{
					kill_bug(iEnt)
					return
				}

				kc_player_set_death_reason(iOther, "DEATH_REASON_BUG")
				set_member(iOther, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iOwner, BUG_DAMAGE, DMG_SLASH)

				if (is_user_alive(iOther) && kc_player_get_vision(iOther) != VISION_BLIND &&
					!kc_player_in_freeze(iOther) && !kc_player_in_chill(iOther))
				{
					send_msg_ScreenFade((1<<12), 200, (1<<12), {255, 255, 255}, 255, MSG_ONE, _, iOther)
				}

				if (--Player[iOwner][PlrBugCuts] == 0)
				{
					kill_bug(iEnt)
					return
				}

				set_entvar(iEnt, var_bug_nextattack, fGameTime + 0.5)
			}
		}

		set_entvar(iEnt, var_bug_nexthit, fGameTime + 0.1)
		set_entvar(iEnt, var_bug_nexthunt, fGameTime)
	}
}

bool:is_bug(const iEnt)
{
	if (is_nullent(iEnt))
		return false

	return get_entvar(iEnt, var_impulse) == IMPULSE_BUG
}

kill_bug(const iEnt)
{
	new Float:vOrigin[3]
	get_entvar(iEnt, var_origin, vOrigin)
	send_msg_TE_BLOODSPRITE(vOrigin, sprBloodSpray, sprBlood, 8, 16)

	rg_remove_entity(iEnt)
}

in_world(const Float:vOrigin[], const Float:vVelocity[])
{
	if (vOrigin[0] >=  4096.0) return 0
	if (vOrigin[0] >=  4096.0) return 0
	if (vOrigin[0] >=  4096.0) return 0
	if (vOrigin[0] <= -4096.0) return 0
	if (vOrigin[0] <= -4096.0) return 0
	if (vOrigin[0] <= -4096.0) return 0

	if (vVelocity[0] >=  2000.0) return 0
	if (vVelocity[0] >=  2000.0) return 0
	if (vVelocity[0] >=  2000.0) return 0
	if (vVelocity[0] <= -2000.0) return 0
	if (vVelocity[0] <= -2000.0) return 0
	if (vVelocity[0] <= -2000.0) return 0

	return 1
}

best_visible_enemy(iEnt, const Float:vOrigin[])
{
	static iTarget, iOwner

	static Float:vMins[3], Float:vMaxs[3]
	static Float:vAbsMins[3], Float:vAbsMaxs[3]

	xs_vec_sub(vOrigin, Float:{BUG_SEARCH_RADIUS, BUG_SEARCH_RADIUS, BUG_SEARCH_RADIUS}, vMins)
	xs_vec_add(vOrigin, Float:{BUG_SEARCH_RADIUS, BUG_SEARCH_RADIUS, BUG_SEARCH_RADIUS}, vMaxs)

	iOwner = get_entvar(iEnt, var_bug_realowner)

	for (iTarget = 1; iTarget <= MaxClients; iTarget++)
	{
		if (!is_user_alive(iTarget))
			continue

		if (get_user_team(iOwner) == get_user_team(iTarget))
			continue

		get_entvar(iTarget, var_absmin, vAbsMins)
		get_entvar(iTarget, var_absmax, vAbsMaxs)

		if (vMins[0] > vAbsMaxs[0] || vMins[1] > vAbsMaxs[1] || vMins[2] > vAbsMaxs[2] ||
			vMaxs[0] < vAbsMins[0 ] || vMaxs[1] < vAbsMins[1] || vMaxs[2] < vAbsMins[2])
				continue

		set_entvar(iEnt, var_enemy, iTarget)
		return iTarget
	}

	return 0
}

get_eye_position(const iPlayer, Float:vOrigin[])
{
	static Float:vViewOfs[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vOrigin, vViewOfs, vOrigin)
}

check_ghost(iPlayer, Float:vStartOrigin[3], Float:vEndOrigin[3], &Float:fDist)
{
	new iGhostEnt = NULLENT, Float:vGhostMins[3], Float:vGhostMaxs[3],
		iFindedGhost, Float:fGhostDist, Float:fMinDist = 8192.0,
		iTeam = get_member(iPlayer, m_iTeam)

	while ((iGhostEnt = rg_find_ent_by_class(iGhostEnt, CLASSNAME_GHOST)))
	{
		if (get_entvar(iGhostEnt, var_team) == iTeam)
			continue

		get_entvar(iGhostEnt, var_absmin, vGhostMins)
		get_entvar(iGhostEnt, var_absmax, vGhostMaxs)

		if (line_intersects_box(vStartOrigin, vEndOrigin, vGhostMins, vGhostMaxs, fGhostDist))
		{
			if (fMinDist > fGhostDist)
			{
				fMinDist = fGhostDist
				iFindedGhost = iGhostEnt
			}
		}
	}

	fDist = fMinDist
	return iFindedGhost
}
