#include <amxmodx>
#include <fakemeta_util>
#include <engine>
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

#define DAMAGE_RESTORE_HEAL			4
#define DAMAGE_RESTORE_DELAY		1.0
#define DAMAGE_RESTORE_START_TIME	3.0

#define REBORN_MINHP				HP

#define var_strikebeam_time			var_fuser1

#define Player[%1][%2]		g_player_data[%1 - 1][%2]
#define PlayerF[%1][%2]		g_player_data_f[%1 - 1][%2]

new const MODEL_V_KNIFE[] = "models/next21_efk/v_thunder_knife_b02.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_thunder_knife.mdl"
new const MODEL_CROSSHAIR[] = "models/next21_efk/thunder_crosshair.mdl"

new const SOUND_THUNDER[] = "next21_efk/thunder.wav"

#define VELOCITY_BACK		2000.0

new const GUNSHOT_DECALS[] = { 46, 47, 48 }

enum _:Player_Properties
{
	IsAlive,
	DoJump,
	Knife,
	StrikeBeam,
	ThunderDamageRestore
}

enum _:Player_Properties_F
{
	Float:LastOrigin[3],
	Float:LastDelay,
	Float:ThunderDamageRestoreTime
}

new
g_iKnifeId, g_player_data[32][Player_Properties], Float:g_player_data_f[32][Player_Properties_F],
sprLightning, sprCircle, sprBeam, sprParticle, g_pKnifePMdl

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	precache_model(MODEL_CROSSHAIR)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_THUNDER)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	sprLightning = precache_model("sprites/lgtning.spr")
	sprCircle = precache_model("sprites/shadow_circle.spr")
	sprBeam = precache_model("sprites/laserbeam.spr")
	sprParticle = precache_model("sprites/mommaspit.spr")
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

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Player_PreThink, "player", "fw_PreThink")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	register_think(CLASSNAME_STRIKE_BEAM, "fw_StrikeBeamThink")

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][IsAlive] = 0
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][IsAlive] = 0

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

public fw_PlayerSpawn(iPlayer)
{
	PlayerF[iPlayer][LastOrigin][0] = 0.0
	PlayerF[iPlayer][LastOrigin][1] = 0.0
	PlayerF[iPlayer][LastOrigin][2] = 0.0

	if (is_user_alive(iPlayer))
	{
		Player[iPlayer][IsAlive] = 1
		Player[iPlayer][DoJump] = 1
		Player[iPlayer][ThunderDamageRestore] = 0
	}
}

public fw_PreThink(iPlayer)
{
	if (!Player[iPlayer][IsAlive] || Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	new Float:fGameTime = get_gametime()

	if (Player[iPlayer][ThunderDamageRestore]
		&& PlayerF[iPlayer][ThunderDamageRestoreTime] <= fGameTime
		&& !kc_player_in_burn(iPlayer))
	{
		new Float:fMaxHealth = kc_player_get_maxhealth(iPlayer)
		new Float:fHealth = Float:get_entvar(iPlayer, var_health)
		new iRest = min(Player[iPlayer][ThunderDamageRestore], DAMAGE_RESTORE_HEAL)

		if (fHealth + float(iRest) >= fMaxHealth)
		{
			if (fHealth < fMaxHealth)
				set_entvar(iPlayer, var_health, fMaxHealth)
			Player[iPlayer][ThunderDamageRestore] = 0
		}
		else
		{
			set_entvar(iPlayer, var_health, fHealth + float(iRest))
			Player[iPlayer][ThunderDamageRestore] -= iRest
			PlayerF[iPlayer][ThunderDamageRestoreTime] = fGameTime + DAMAGE_RESTORE_DELAY
		}
	}

	static nbut, obut, flags
	nbut = get_entvar(iPlayer, var_button)
	obut = get_entvar(iPlayer, var_oldbuttons)
	flags = get_entvar(iPlayer, var_flags)

	if (nbut & IN_JUMP)
	{
		if (!(flags & FL_ONGROUND) && !(obut & IN_JUMP))
		{
			if (!Player[iPlayer][DoJump])
			{
				Player[iPlayer][DoJump] = 1
				kc_player_levitation(iPlayer)
			}
			else kc_player_unlevitation(iPlayer)
		}
		else if (flags & FL_ONGROUND)
			Player[iPlayer][DoJump] = 0
	}

	return PLUGIN_CONTINUE
}

public fw_PlayerKilled(iVictim)
{
	Player[iVictim][IsAlive] = 0
	Player[iVictim][ThunderDamageRestore] = 0
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][Knife] = iKnifeId

	if (iKnifeId == g_iKnifeId)
		kc_player_set_abil2_charge(iPlayer, 0.0)

	Player[iPlayer][ThunderDamageRestore] = 0
}

public efk_ability(iPlayer)
{
	new Float:vAimOrigin[3]
	fm_get_aim_origin(iPlayer, vAimOrigin)
	PlayerF[iPlayer][LastDelay] = get_gametime() + 1.0

	spawn_thunder_strike_beam(iPlayer, vAimOrigin)

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
	set_entvar(iBeamEnt, var_modelindex, sprBeam)
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

	set_entvar(iBeamEnt, var_mins, Float:{0.0, 0.0, 0.0})
	set_entvar(iBeamEnt, var_maxs, Float:{0.0, 0.0, 1500.0})
	engfunc(EngFunc_SetSize, iBeamEnt, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 1500.0})

	Player[iPlayer][StrikeBeam] = iBeamEnt

	return true
}

public fw_StrikeBeamThink(iBeamEnt)
{
	static Float:strikeTime
	strikeTime = Float:get_entvar(iBeamEnt, var_strikebeam_time)
	new Float:fGameTime = get_gametime()

	if (fGameTime < strikeTime)
	{
		static Float:vColor[3]
		for(new i; i < 3; i++)
			vColor[i] = 20.0 + (255.0 - 20.0) * (1.0 - ((strikeTime - fGameTime) / STRIKE_BEAM_LIFE))

		set_entvar(iBeamEnt, var_rendercolor, vColor)
		set_entvar(iBeamEnt, var_nextthink, fGameTime + STRIKE_BEAM_UPDATE_FREQ)
	}
	else
	{
		new owner = get_entvar(iBeamEnt, var_owner)
		new team = get_user_team(owner)
		new crosshair = get_entvar(iBeamEnt, var_crosshair)

		const Float:MIN_DAMAGE = 30.0
		const Float:MAX_DAMAGE = 40.0

		if (!is_nullent(crosshair))
		{
			new Float:strikeOrigin[3]
			get_entvar(crosshair, var_origin, strikeOrigin)

			new bool:striked = false

			new i = FM_NULLENT
			while ((i = engfunc(EngFunc_FindEntityInSphere, i, strikeOrigin, STRIKE_RADIUS)))
			{
				if (i >= MaxClients)
					break

				if (Player[i][IsAlive] && get_user_team(i) != team && kc_player_in_reflection(i))
				{
					new Float:vAttackerOrigin[3]
					get_entvar(owner, var_origin, vAttackerOrigin)
					thunder_attack(i, vAttackerOrigin, MIN_DAMAGE, MAX_DAMAGE)
					kc_player_reflection_done(i, owner)

					striked = true
					break
				}
			}

			if (!striked) {
				thunder_attack(owner, strikeOrigin, MIN_DAMAGE, MAX_DAMAGE)
				xs_vec_copy(strikeOrigin, PlayerF[owner][LastOrigin])
				PlayerF[owner][LastOrigin][2] += 50.0
			}

			rg_remove_entity(crosshair)
		}

		if (Player[owner][StrikeBeam] == iBeamEnt)
			Player[owner][StrikeBeam] = 0

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

	thunder_attack(iPlayer, vOrigin, 20.0, 26.0)
}

public efk_ability3(iPlayer)
{
	if (!PlayerF[iPlayer][LastOrigin][0] && !PlayerF[iPlayer][LastOrigin][1] && !PlayerF[iPlayer][LastOrigin][2])
		return PLUGIN_HANDLED

	new Float:fGameTime = get_gametime()

	if (PlayerF[iPlayer][LastDelay] > fGameTime)
		return PLUGIN_HANDLED

	static Float:vOrigin[3]
	xs_vec_copy(PlayerF[iPlayer][LastOrigin], vOrigin)

	if (!is_hull_vacant(vOrigin, get_entvar(iPlayer, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, iPlayer))
	{
		PlayerF[iPlayer][LastDelay] = fGameTime + 1.0
		return PLUGIN_HANDLED
	}

	vOrigin[2] -= 50.0
	thunder_attack(iPlayer, vOrigin, 20.0, 26.0)
	vOrigin[2] += 50.0

	set_entvar(iPlayer, var_velocity, NULL_VECTOR)
	engfunc(EngFunc_SetOrigin, iPlayer, vOrigin)
	set_entvar(iPlayer, var_origin, vOrigin)

	kc_player_unfreeze(iPlayer)
	kc_player_unlevitation(iPlayer)
	kc_player_check_stuck_delayed(iPlayer, 0.3)

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

	return PLUGIN_CONTINUE
}

thunder_attack(iPlayer, Float:vOrigin[3], Float:fMinDamage, Float:fMaxDamage)
{
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, SOUND_THUNDER, 0.000000, 0.000000, 32, 0)
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, SOUND_THUNDER, 1.000000, 0.000000, 0, 100)

	send_msg_TE_WORLDDECAL(vOrigin, GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS - 1)])

	new Float:vStartBeamOrigin[3], Float:vEndBeamOrigin[3]
	vStartBeamOrigin[0] = vOrigin[0]
	vStartBeamOrigin[1] = vOrigin[1]
	vStartBeamOrigin[2] = vOrigin[2] - 50.0
	vEndBeamOrigin[0] = vOrigin[0]
	vEndBeamOrigin[1] = vOrigin[1]
	vEndBeamOrigin[2] = vOrigin[2] + 1500.0
	send_msg_TE_BEAMPOINTS(vStartBeamOrigin, vEndBeamOrigin, sprLightning, 0, 1, 2, 120, 10, {255, 255, 255}, 255, 0)

	new Float:vAxis[3]
	vAxis[0] = vOrigin[0]
	vAxis[1] = vOrigin[1]
	vAxis[2] = vOrigin[2] + 220.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, sprCircle, 0, 0, 4, 49, 0, {255, 255, 255}, 255, 0)

	new Float:vVelocity[3], Float:fVicOrigin[3],
	Float:fDistance, Float:fDamage,
	Float:fRadius = STRIKE_RADIUS,
	Float:fDmgMultiplier,
	Float:fHealth,
	team = get_user_team(iPlayer),
	ent = engfunc(EngFunc_FindEntityInSphere, -1, vOrigin, fRadius)

	while (ent)
	{
		if (is_user_alive(ent) && !kc_player_check_game_flag(ent, PLGF_IN_UNABILITY))
		{
			if (ent == iPlayer || team != get_user_team(ent))
			{
				fDmgMultiplier = ent == iPlayer ? 0.5 : 1.0
				fDamage = random_float(fMinDamage, fMaxDamage) * fDmgMultiplier
				fHealth = Float:get_entvar(ent, var_health)

				kc_player_set_override_attacker(ent, iPlayer, 4.0)
				kc_player_set_death_reason(ent, "DEATH_REASON_THUNDER")
				set_member(ent, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, ent, iPlayer, ent == iPlayer ? 0 : iPlayer, fDamage, DMG_ENERGYBEAM | DMG_ALWAYSGIB)

				if (ent == iPlayer && is_user_alive(iPlayer))
				{
					fDamage = fHealth - Float:get_entvar(iPlayer, var_health)
					if (fDamage >= 1.0)
					{
						if (!Player[iPlayer][ThunderDamageRestore])
							PlayerF[iPlayer][ThunderDamageRestoreTime] = get_gametime() + DAMAGE_RESTORE_START_TIME

						Player[iPlayer][ThunderDamageRestore] += floatround(fDamage, floatround_floor)
					}
				}

				get_entvar(ent, var_origin, fVicOrigin)
				fDistance = 1.0 - get_distance_f(vOrigin, fVicOrigin) / fRadius

				xs_vec_sub(fVicOrigin, vOrigin, vVelocity)
				xs_vec_normalize(vVelocity, vVelocity)
				xs_vec_mul_scalar(vVelocity, fDistance * VELOCITY_BACK, vVelocity)
				vVelocity[2] = 400.0
				set_entvar(ent, var_velocity, vVelocity)
			}
			if(team == get_user_team(ent))
				thunder_charge(ent);
		}
		else if (get_entvar(ent, var_impulse) == IMPULSE_GHOST && team != get_entvar(ent, var_team))
		{
			new iOwner = get_entvar(ent, var_owner)
			fDamage = 20.0

			kc_player_set_override_attacker(iOwner, iPlayer, 4.0)
			kc_player_set_death_reason(iOwner, "DEATH_REASON_THUNDER")
			set_member(iOwner, m_LastHitGroup, HIT_GENERIC)
			ExecuteHamB(Ham_TakeDamage, iOwner, iPlayer, iPlayer, fDamage, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
		}
		else if (get_entvar(ent, var_flags) & FL_MONSTER)
		{
			if (get_user_team(iPlayer) != get_entvar(ent, var_skin) + 1)
			{
				get_entvar(ent, var_origin, fVicOrigin)
				fDistance = 1.0 - get_distance_f(vOrigin, fVicOrigin) / fRadius

				xs_vec_sub(fVicOrigin, vOrigin, vVelocity)
				xs_vec_normalize(vVelocity, vVelocity)
				xs_vec_mul_scalar(vVelocity, fDistance * VELOCITY_BACK, vVelocity)
				vVelocity[2] = 400.0
				set_entvar(ent, var_velocity, vVelocity)

				ExecuteHamB(Ham_TakeDamage, ent, 0, ent, 50.0, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
			}
		}

		ent = engfunc(EngFunc_FindEntityInSphere, ent, vOrigin, fRadius)
	}
}

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) || !get_tr2(0, TR_AllSolid)
}

thunder_charge(iPlayer, Float:fTime=STRIKE_CHARGE_TIME)
{
	if (kc_player_get_visibility(iPlayer) < VIS_TRANS)
		kc_player_add_glow(iPlayer, fTime, 255, 255, 255)

	kc_player_set_powerdamage(iPlayer, kc_player_get_powerdamage(iPlayer) + STRIKE_CHARGE_DAMAGE)

	if (kc_player_get_capture(iPlayer) != CAPTURE_WEAK)
		kc_player_rush(iPlayer, kc_player_get_maxspeed(iPlayer) + STRIKE_CHARGE_SPEED_ADD, STRIKE_CHARGE_TIME)
}

spawn_thunder_particles(Float:vOrigin[3], Float:fRange, Float:fHeight = 128.0, iNum = 12, Float:fSpeed = 6.0)
{
	new Float:vMins[3] = {-1.0, -1.0, 0.0}
	new Float:vMaxs[3] = {1.0, 1.0, 1.0}

	xs_vec_mul_scalar(vMins, fRange, vMins)
	xs_vec_mul_scalar(vMaxs, fRange, vMaxs)
	xs_vec_add(vOrigin, vMins, vMins)
	xs_vec_add(vOrigin, vMaxs, vMaxs)

	send_msg_TE_BUBBLES(vMins, vMaxs, fHeight, sprParticle, iNum, fSpeed)
}

crosshair_ent_remove(iEnt)
{
	new iCrosshairEnt = get_entvar(iEnt, var_crosshair)
	if (!is_nullent(iCrosshairEnt))
		rg_remove_entity(iCrosshairEnt)

	rg_remove_entity(iEnt)
}