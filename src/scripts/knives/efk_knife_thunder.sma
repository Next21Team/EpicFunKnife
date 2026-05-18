#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>
#include <next_client_api>

new const PLUGIN[] = "EFK: Thunder Knife"

#define KNIFE_CLASSNAME "weapon_next21_thunder"
#define KNIFE_MENUDESC  "KNIFE_THUNDER_DESC"
#define KNIFE_CHATDESC  "KNIFE_THUNDER_CHAT"

#define HP				70.0
#define GRAVITY			1.0
#define SPEED			260.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL     1

#define ABIL1_NAME		"Thunder"
#define ABIL1_CHARGE	6.25
#define ABIL1_TYPE		ABIL_TARGET_SURFACES
#define ABIL1_MINDIST	0.0
#define ABIL1_MAXDIST	3000.0

#define ABIL2_NAME		"Reborn"
#define ABIL2_CHARGE	2.64

#define ABIL3_NAME		"Last Light"
#define ABIL3_CHARGE	2.86

new CLASSNAME_STRIKE_BEAM[]			= "next21_thunder_strike_beam"

#define STRIKE_BEAM_LIFE			0.85
#define STRIKE_BEAM_UPDATE_FREQ		0.1
#define STRIKE_CHARGE_TIME			3.0
#define STRIKE_CHARGE_DAMAGE		20.0
#define STRIKE_CHARGE_SPEED_ADD		10.0
#define STRIKE_RADIUS				150.0
#define STRIKE_MIN_DAMAGE			30.0
#define STRIKE_MAX_DAMAGE			40.0
#define STRIKE_MONSTER_DAMAGE		50.0
#define STRIKE_REBORN_DAMAGE		25.0
#define STRIKE_SELF_MUL				0.5

#define DAMAGE_RESTORE_HEAL			4
#define DAMAGE_RESTORE_DELAY		1.0
#define DAMAGE_RESTORE_START_TIME	3.0

#define REBORN_MINHP				HP

#define var_strikebeam_time			var_fuser1

new const MODEL_V_KNIFE[] = "models/next21_efk/v_thunder_knife_b02.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_thunder_knife.mdl"
new const MODEL_CROSSHAIR[] = "models/next21_efk/thunder_crosshair.mdl"

new const SOUND_THUNDER[] = "next21_efk/thunder.wav"

#define VELOCITY_BACK		2000.0

new const GUNSHOT_DECALS[] = { 46, 47, 48 }

enum _:PlayerData
{
	bool:PlrIsAlive,
	bool:PlrWasJump,
	PlrKnife,
	PlrStrikeBeamEnt,
	PlrStrikeDamageRestore,
	Float:PlrStrikeDamageRestoreTime,
	bool:PlrLastStrikeAvailable,
	Float:PlrLastStrikeDelay,
	Float:PlrLastStrikeOrigin[3],
	Float:PlrLastStrikeNormal[3]
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
g_pLightningSpr, g_pCircleSpr, g_pBeamSpr, g_pParticleSpr, g_pKnifePMdl

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	precache_model(MODEL_CROSSHAIR)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_THUNDER)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	g_pLightningSpr = precache_model("sprites/lgtning.spr")
	g_pCircleSpr = precache_model("sprites/shadow_circle.spr")
	g_pBeamSpr = precache_model("sprites/laserbeam.spr")
	g_pParticleSpr = precache_model("sprites/mommaspit.spr")
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

	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_KNIFE2)
	kc_knife_set_flags(g_iKnifeId, KNFF_ZOOM | KNFF_ABIL1_TOGGLABLE)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Pre")
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Pre")

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false

	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_STRIKE_BEAM)))
	{
		if (get_entvar(iEnt, var_owner) != iPlayer)
			continue

		crosshair_ent_remove(iEnt)
	}
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_STRIKE_BEAM)))
	{
		crosshair_ent_remove(iEnt)
	}
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		Player[iPlayer][PlrIsAlive] = true
		Player[iPlayer][PlrWasJump] = true
		Player[iPlayer][PlrStrikeDamageRestore] = 0
		Player[iPlayer][PlrLastStrikeAvailable] = false
	}
}

public RG_CBasePlayer_PreThink_Pre(iPlayer)
{
	if (!Player[iPlayer][PlrIsAlive] || Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	new Float:fGameTime = get_gametime()

	if (Player[iPlayer][PlrStrikeDamageRestore]
		&& Float:Player[iPlayer][PlrStrikeDamageRestoreTime] <= fGameTime
		&& !kc_player_in_burn(iPlayer))
	{
		new Float:fMaxHealth = kc_player_get_maxhealth(iPlayer)
		new Float:fHealth = Float:get_entvar(iPlayer, var_health)
		new iRest = min(Player[iPlayer][PlrStrikeDamageRestore], DAMAGE_RESTORE_HEAL)

		if (fHealth + float(iRest) >= fMaxHealth)
		{
			if (fHealth < fMaxHealth)
				set_entvar(iPlayer, var_health, fMaxHealth)
			Player[iPlayer][PlrStrikeDamageRestore] = 0
		}
		else
		{
			set_entvar(iPlayer, var_health, fHealth + float(iRest))
			Player[iPlayer][PlrStrikeDamageRestore] -= iRest
			Player[iPlayer][PlrStrikeDamageRestoreTime] = fGameTime + DAMAGE_RESTORE_DELAY
		}
	}

	static iButton, iOldButtons, iFlags
	iButton = get_entvar(iPlayer, var_button)
	iOldButtons = get_entvar(iPlayer, var_oldbuttons)
	iFlags = get_entvar(iPlayer, var_flags)

	if (iButton & IN_JUMP)
	{
		if (!(iFlags & FL_ONGROUND) && !(iOldButtons & IN_JUMP))
		{
			if (!Player[iPlayer][PlrWasJump])
			{
				Player[iPlayer][PlrWasJump] = true
				kc_player_levitation(iPlayer)
			}
			else
				kc_player_unlevitation(iPlayer)
		}
		else if (iFlags & FL_ONGROUND)
			Player[iPlayer][PlrWasJump] = false
	}

	return PLUGIN_CONTINUE
}

public RG_CBasePlayer_Killed_Pre(iVictim)
{
	Player[iVictim][PlrIsAlive] = false
	Player[iVictim][PlrStrikeDamageRestore] = 0
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][PlrKnife] = iKnifeId

	if (iKnifeId == g_iKnifeId)
		kc_player_set_abil2_charge(iPlayer, 0.0)

	Player[iPlayer][PlrStrikeDamageRestore] = 0
}

public efk_ability(iPlayer)
{
	new Float:vAimOrigin[3]
	fm_get_aim_origin(iPlayer, vAimOrigin)
	Player[iPlayer][PlrLastStrikeDelay] = get_gametime() + 1.0

	spawn_thunder_strike_beam(iPlayer, vAimOrigin)

	player_reset_fov(iPlayer)
}

spawn_thunder_strike_beam(iPlayer, Float:vOrigin[3])
{
	new iCrossEnt = rg_create_entity("info_target")
	if (is_nullent(iCrossEnt))
		return false

	new Float:fGameTime = get_gametime()

	engfunc(EngFunc_SetModel, iCrossEnt, MODEL_CROSSHAIR)
	engfunc(EngFunc_SetSize, iCrossEnt, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 4.0})
	set_entvar(iCrossEnt, var_skin, get_member(iPlayer, m_iTeam) - 1)
	set_entvar(iCrossEnt, var_rendermode, kRenderNormal)
	set_entvar(iCrossEnt, var_sequence, 0)
	set_entvar(iCrossEnt, var_framerate,  1.0)
	set_entvar(iCrossEnt, var_animtime, fGameTime)
	set_entvar(iCrossEnt, var_movetype, MOVETYPE_PUSH)
	set_entvar(iCrossEnt, var_gravity, 0.0);

	new iBeamEnt = rg_create_entity("beam")
	if (is_nullent(iBeamEnt))
	{
		rg_remove_entity(iCrossEnt)
		return false
	}

	set_entvar(iBeamEnt, var_classname, CLASSNAME_STRIKE_BEAM)
	set_entvar(iBeamEnt, var_impulse, IMPULSE_THUNDER_STRIKE_BEAM)
	set_entvar(iBeamEnt, var_flags, FL_CUSTOMENTITY)
	set_entvar(iBeamEnt, var_rendermode, kRenderNormal)
	set_entvar(iBeamEnt, var_rendercolor, Float:{20.0, 20.0, 20.0})
	set_entvar(iBeamEnt, var_renderamt, 255.0)
	set_entvar(iBeamEnt, var_modelindex, g_pBeamSpr)
	set_entvar(iBeamEnt, var_scale, 6.0)
	set_entvar(iBeamEnt, var_owner, iPlayer)
	set_entvar(iBeamEnt, var_crosshair, iCrossEnt)

	spawn_thunder_particles(vOrigin, 64.0)

	engfunc(EngFunc_SetOrigin, iBeamEnt, vOrigin)
	engfunc(EngFunc_SetOrigin, iCrossEnt, vOrigin)
	vOrigin[2] += 1500.0
	set_entvar(iBeamEnt, var_angles, vOrigin)

	set_entvar(iBeamEnt, var_nextthink, fGameTime + STRIKE_BEAM_UPDATE_FREQ)
	set_entvar(iBeamEnt, var_strikebeam_time, fGameTime + STRIKE_BEAM_LIFE)

	set_entvar(iBeamEnt, var_mins, NULL_VECTOR)
	set_entvar(iBeamEnt, var_maxs, Float:{0.0, 0.0, 1500.0})
	engfunc(EngFunc_SetSize, iBeamEnt, NULL_VECTOR, Float:{0.0, 0.0, 1500.0})

	SetThink(iBeamEnt, "thunder_strike_beam_think")

	Player[iPlayer][PlrStrikeBeamEnt] = iBeamEnt

	return true
}

public thunder_strike_beam_think(iBeamEnt)
{
	static Float:fStrikeTime
	fStrikeTime = Float:get_entvar(iBeamEnt, var_strikebeam_time)
	new Float:fGameTime = get_gametime()

	if (fGameTime < fStrikeTime)
	{
		static Float:vColor[3]
		for (new i; i < 3; i++)
			vColor[i] = 20.0 + (255.0 - 20.0) * (1.0 - ((fStrikeTime - fGameTime) / STRIKE_BEAM_LIFE))

		set_entvar(iBeamEnt, var_rendercolor, vColor)
		set_entvar(iBeamEnt, var_nextthink, fGameTime + STRIKE_BEAM_UPDATE_FREQ)
	}
	else
	{
		new iOwner = get_entvar(iBeamEnt, var_owner)
		new iTeam = get_user_team(iOwner)
		new iCrosshairEnt = get_entvar(iBeamEnt, var_crosshair)

		if (!is_nullent(iCrosshairEnt))
		{
			new Float:vStrikeOrigin[3]
			get_entvar(iCrosshairEnt, var_origin, vStrikeOrigin)

			new bool:bStriked = false

			new i = FM_NULLENT
			while ((i = engfunc(EngFunc_FindEntityInSphere, i, vStrikeOrigin, STRIKE_RADIUS)))
			{
				if (i >= MaxClients)
					break

				if (Player[i][PlrIsAlive] && get_user_team(i) != iTeam && kc_player_in_reflection(i))
				{
					new Float:vAttackerOrigin[3]
					get_entvar(iOwner, var_origin, vAttackerOrigin)
					thunder_attack(i, vAttackerOrigin, STRIKE_MIN_DAMAGE, STRIKE_MAX_DAMAGE)
					kc_player_reflection_done(i, iOwner)

					bStriked = true
					break
				}
			}

			if (!bStriked)
			{
				Player[iOwner][PlrLastStrikeAvailable] = false
				thunder_attack(iOwner, vStrikeOrigin, STRIKE_MIN_DAMAGE, STRIKE_MAX_DAMAGE)

				new Float:vStrikeNormal[3]
				if (get_surface_normal_at_origin(vStrikeOrigin, vStrikeNormal, iOwner))
				{
					xs_vec_copy(vStrikeOrigin, Player[iOwner][PlrLastStrikeOrigin])
					xs_vec_copy(vStrikeNormal, Player[iOwner][PlrLastStrikeNormal])
					Player[iOwner][PlrLastStrikeAvailable] = true
				}
			}

			rg_remove_entity(iCrosshairEnt)
		}

		if (Player[iOwner][PlrStrikeBeamEnt] == iBeamEnt)
			Player[iOwner][PlrStrikeBeamEnt] = 0

		rg_remove_entity(iBeamEnt)
	}
}

public efk_ability2(iPlayer)
{
	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	new Float:fHealth
	get_entvar(iPlayer, var_health, fHealth)
	ExecuteHamB(Ham_CS_RoundRespawn, iPlayer)
	if (fHealth <= REBORN_MINHP)
		set_entvar(iPlayer, var_health, REBORN_MINHP)

	send_msg_TE_IMPLOSION(vOrigin, 100, 45, 3)

	thunder_attack(iPlayer, vOrigin, STRIKE_REBORN_DAMAGE, STRIKE_REBORN_DAMAGE)
}

public efk_ability3(iPlayer)
{
	if (!Player[iPlayer][PlrLastStrikeAvailable])
		return PLUGIN_HANDLED

	new Float:fGameTime = get_gametime()

	if (Float:Player[iPlayer][PlrLastStrikeDelay] > fGameTime)
		return PLUGIN_HANDLED

	new Float:vOrigin[3], Float:vNormal[3]
	xs_vec_copy(Player[iPlayer][PlrLastStrikeOrigin], vOrigin)
	xs_vec_copy(Player[iPlayer][PlrLastStrikeNormal], vNormal)

	new iHull = get_entvar(iPlayer, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
	new Float:vTargetOrigin[3], bool:bEmptySpace

	// find empty space by surface normal offset
	for (new i; i < 4; i++)
	{
		xs_vec_add_scaled(vOrigin, vNormal, 24.0 * i, vTargetOrigin)

		if (is_hull_vacant(vTargetOrigin, iHull, iPlayer))
		{
			bEmptySpace = true
			break
		}
	}

	if (!bEmptySpace)
	{
		Player[iPlayer][PlrLastStrikeDelay] = fGameTime + 1.0
		return PLUGIN_HANDLED
	}

	thunder_attack(iPlayer, vOrigin, STRIKE_MIN_DAMAGE, STRIKE_MAX_DAMAGE)

	set_entvar(iPlayer, var_velocity, NULL_VECTOR)
	engfunc(EngFunc_SetOrigin, iPlayer, vTargetOrigin)
	set_entvar(iPlayer, var_origin, vTargetOrigin)

	kc_player_unfreeze(iPlayer)
	kc_player_unlevitation(iPlayer)
	kc_player_check_stuck_delayed(iPlayer, 0.3)

	player_reset_fov(iPlayer)

	Player[iPlayer][PlrWasJump] = false

	return PLUGIN_CONTINUE
}

thunder_attack(iPlayer, Float:vOrigin[3], Float:fMinDamage, Float:fMaxDamage)
{
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, SOUND_THUNDER, VOL_NORM, ATTN_NONE, SND_STOP, PITCH_NORM)
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, SOUND_THUNDER, VOL_NORM, ATTN_NONE, 0, PITCH_NORM)

	send_msg_TE_WORLDDECAL(vOrigin, GUNSHOT_DECALS[random(sizeof GUNSHOT_DECALS)])

	new Float:vStartBeamOrigin[3], Float:vEndBeamOrigin[3]
	vStartBeamOrigin[0] = vOrigin[0]
	vStartBeamOrigin[1] = vOrigin[1]
	vStartBeamOrigin[2] = vOrigin[2] - 50.0
	vEndBeamOrigin[0] = vOrigin[0]
	vEndBeamOrigin[1] = vOrigin[1]
	vEndBeamOrigin[2] = vOrigin[2] + 1500.0
	send_msg_TE_BEAMPOINTS(vStartBeamOrigin, vEndBeamOrigin, g_pLightningSpr, 0, 1, 2, 120, 10, {255, 255, 255}, 255, 0)

	new Float:vAxis[3]
	vAxis[0] = vOrigin[0]
	vAxis[1] = vOrigin[1]
	vAxis[2] = vOrigin[2] + 220.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, g_pCircleSpr, 0, 0, 4, 49, 0, {255, 255, 255}, 255, 0)

	new Float:vVelocity[3], Float:vTargetOrigin[3],
		Float:fDistance, Float:fDamage,
		Float:fRadius = STRIKE_RADIUS,
		Float:fDmgMultiplier,
		Float:fHealth,
		iTeam = get_user_team(iPlayer),
		iTarget = NULLENT

	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, fRadius)))
	{
		if (is_user_alive(iTarget) && !kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
		{
			if (iTeam == get_user_team(iTarget))
				thunder_charge(iTarget)

			if (iTarget == iPlayer || iTeam != get_user_team(iTarget))
			{
				fDmgMultiplier = iTarget == iPlayer ? STRIKE_SELF_MUL : 1.0
				fDamage = random_float(fMinDamage, fMaxDamage) * fDmgMultiplier
				fHealth = Float:get_entvar(iTarget, var_health)

				kc_player_set_override_attacker(iTarget, iPlayer, 4.0)
				kc_player_set_death_reason(iTarget, "DEATH_REASON_THUNDER")
				set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iTarget, iPlayer,
					iTarget == iPlayer ? 0 : iPlayer, fDamage, DMG_ENERGYBEAM | DMG_ALWAYSGIB)

				if (iTarget == iPlayer && is_user_alive(iPlayer))
				{
					fDamage = fHealth - Float:get_entvar(iPlayer, var_health)
					if (fDamage >= 1.0)
					{
						if (!Player[iPlayer][PlrStrikeDamageRestore])
							Player[iPlayer][PlrStrikeDamageRestoreTime] = get_gametime() + DAMAGE_RESTORE_START_TIME

						Player[iPlayer][PlrStrikeDamageRestore] += floatround(fDamage, floatround_floor)
					}
				}

				get_entvar(iTarget, var_origin, vTargetOrigin)
				fDistance = 1.0 - get_distance_f(vOrigin, vTargetOrigin) / fRadius

				xs_vec_sub(vTargetOrigin, vOrigin, vVelocity)
				xs_vec_normalize(vVelocity, vVelocity)
				xs_vec_mul_scalar(vVelocity, fDistance * VELOCITY_BACK, vVelocity)
				vVelocity[2] = 400.0
				set_entvar(iTarget, var_velocity, vVelocity)
			}
		}
		else if (get_entvar(iTarget, var_impulse) == IMPULSE_GHOST)
		{
			if (iTeam != get_entvar(iTarget, var_team))
			{
				new iOwner = get_entvar(iTarget, var_owner)
				fDamage = 20.0

				kc_player_set_override_attacker(iOwner, iPlayer, 4.0)
				kc_player_set_death_reason(iOwner, "DEATH_REASON_THUNDER")
				set_member(iOwner, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iOwner, iPlayer, iPlayer, fDamage, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
			}
		}
		else if (get_entvar(iTarget, var_flags) & FL_MONSTER)
		{
			if (iTeam != get_entvar(iTarget, var_skin) + 1)
			{
				get_entvar(iTarget, var_origin, vTargetOrigin)
				fDistance = 1.0 - get_distance_f(vOrigin, vTargetOrigin) / fRadius

				xs_vec_sub(vTargetOrigin, vOrigin, vVelocity)
				xs_vec_normalize(vVelocity, vVelocity)
				xs_vec_mul_scalar(vVelocity, fDistance * VELOCITY_BACK, vVelocity)
				vVelocity[2] = 400.0
				set_entvar(iTarget, var_velocity, vVelocity)

				ExecuteHamB(Ham_TakeDamage, iTarget, 0, iTarget, STRIKE_MONSTER_DAMAGE, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
			}
		}
	}
}

player_reset_fov(iPlayer)
{
	if (get_member(iPlayer, m_iFOV) != 90)
	{
		set_member(iPlayer, m_iFOV, 90)
		set_member(iPlayer, m_iClientFOV, 90)
		set_entvar(iPlayer, var_fov, 90)

		if (ncl_is_client_api_ready(iPlayer))
		{
			ncl_setfov(iPlayer, 90, 0.2)
		}
		else
		{
			send_msg_SetFOV(90, MSG_ONE, _, iPlayer)
		}
	}
}

thunder_charge(iPlayer, Float:fTime=STRIKE_CHARGE_TIME)
{
	if (kc_player_get_visibility(iPlayer) < VIS_TRANS)
		kc_player_add_glow(iPlayer, fTime, 255, 255, 255)

	kc_player_set_powerdamage(iPlayer, kc_player_get_powerdamage(iPlayer) + STRIKE_CHARGE_DAMAGE)

	if (kc_player_get_capture(iPlayer) != CAPTURE_WEAK)
		kc_player_rush(iPlayer, kc_player_get_maxspeed(iPlayer) + STRIKE_CHARGE_SPEED_ADD, STRIKE_CHARGE_TIME)
}

spawn_thunder_particles(Float:vOrigin[3], Float:fRange, Float:fHeight=128.0, iNum=12, Float:fSpeed=6.0)
{
	new Float:vMins[3] = {-1.0, -1.0, 0.0}
	new Float:vMaxs[3] = {1.0, 1.0, 1.0}

	xs_vec_mul_scalar(vMins, fRange, vMins)
	xs_vec_mul_scalar(vMaxs, fRange, vMaxs)
	xs_vec_add(vOrigin, vMins, vMins)
	xs_vec_add(vOrigin, vMaxs, vMaxs)

	send_msg_TE_BUBBLES(vMins, vMaxs, fHeight, g_pParticleSpr, iNum, fSpeed)
}

crosshair_ent_remove(iEnt)
{
	new iCrosshairEnt = get_entvar(iEnt, var_crosshair)
	if (!is_nullent(iCrosshairEnt))
		rg_remove_entity(iCrosshairEnt)

	rg_remove_entity(iEnt)
}

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) || !get_tr2(0, TR_AllSolid)
}

bool:get_surface_normal_at_origin(Float:vOrigin[3], Float:vNormal[3], iEnt)
{
	static Float:TRACE_DIRS[][3] = {
		{-8.0, 0.0, -8.0},
		{8.0, 0.0, -8.0},
		{0.0, -8.0, 8.0},
		{0.0, 8.0, 8.0}
	}

	if (engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY)
		return false

	new Float:vEnd[3]
	new Float:fFraction
	new bool:bRes

	new iTrace = create_tr2()

	for (new i; i < sizeof TRACE_DIRS; i++)
	{
		xs_vec_add(vOrigin, TRACE_DIRS[i], vEnd)
		engfunc(EngFunc_TraceLine, vOrigin, vEnd, IGNORE_MONSTERS, iEnt, iTrace)
		get_tr2(iTrace, TR_flFraction, fFraction)

		if (fFraction < 1.0)
		{
			get_tr2(iTrace, TR_vecPlaneNormal, vNormal)
			bRes = true
			break
		}
	}

	free_tr2(iTrace)

	return bRes
}
