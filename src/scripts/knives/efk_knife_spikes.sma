#include <amxmodx>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>
#include <object/efk_web_utils>

new const PLUGIN[] = "EFK: Spikes Knife"

#define KNIFE_CLASSNAME "weapon_next21_spikes_r02"
#define KNIFE_MENUDESC  "KNIFE_SPIKES_DESC"
#define KNIFE_CHATDESC  "KNIFE_SPIKES_CHAT"

#define HP				100.0
#define GRAVITY			1.0
#define SPEED			270.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL     1

#define ABIL1_NAME		"Spikes"
#define ABIL1_CHARGE	6.667

#define ABIL2_NAME		"Spiky Spine"
#define ABIL2_CHARGE	5.883

#define ABIL3_NAME		"Turn Back"
#define ABIL3_CHARGE	100.0

new const MODEL_V_KNIFE[] =			"models/next21_efk/v_spikes_knife_b02.mdl"
new const MODEL_P_KNIFE[] =			"models/next21_efk/p_spikes_knife_r02.mdl"

new const SOUND_KNIFE_IDLE[] =		"next21_efk/spikes_knife_idle.wav"
new const SOUND_KNIFE_HIT1[] =		"next21_efk/spikes_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[] =		"next21_efk/spikes_knife_hit2.wav"
new const SOUND_KNIFE_DEPLOY[] =	"next21_efk/spikes_knife_deploy.wav"
new const SOUND_KNIFE_SLASH[] =		"next21_efk/spikes_knife_slash.wav"

new const SPIKES_MODEL[] =			"models/next21_efk/spikes_b01.mdl"
new const SPIKES_SPINE_MODEL[] =	"models/next21_efk/spikes_spine_r2.mdl"

new const SPIKES_UP_SOUND[] =		"next21_efk/spikes_up.wav"
new const SPIKES_SPINE_SOUND[] =	"next21_efk/spikes_spine.wav"
new const SPIKES_JUMP_SOUND[] =		"next21_efk/spikes_jump.wav"

new const SPIKES_CLASSNAME[] =		"next21_spikes"

#define Player[%1][%2]		g_player_data[%1 - 1][%2]
#define PlayerF[%1][%2]		g_player_data_f[%1 - 1][%2]

#define	SPIKES_NUM			9

#define HIGHJUMP_FORCE		500.0
#define DROWN_FORCE			440.0
#define HIGHJUMP_COOLDOWN	12.0
#define DROWN_COOLDOWN		14.0

#define MAX_STOMP_SPIKES		10
#define MAX_STOMP_CENTER_SPIKES	3
#define FALLDMGDIVIDER			7.0

#define SPINE_SPIKES_DAMAGE 			15.0
#define SPINE_SPIKES_MAX_TAKEDAMAGE 	10.0
#define SPINE_SPIKES_MAX_CHARGE	(100.0 - ABIL2_CHARGE * 4.0)

#define SPIKES_START_MINDAMAGE 25.0
#define SPIKES_START_MAXDAMAGE 35.0

#define SPIKES_MINDAMAGE 15.0
#define SPIKES_MAXDAMAGE 20.0

#define DAMAGE_RESTORE_HEAL			4
#define DAMAGE_RESTORE_DELAY		1.0
#define DAMAGE_RESTORE_START_TIME	3.0

new const SZ_INFO_TARGET[] = "info_target"

#define var_spike_lifetime	var_fuser1

enum _:ViewSeq
{
	VIEW_SEQ_STAB = 4
}

enum _:SpikeSeq
{
	SPIKE_SEQ_IDLE,
	SPIKE_SEQ_IDLE_DOWN,
	SPIKE_SEQ_UP,
	SPIKE_SEQ_DOWN,
	SPIKE_SEQ_UP_UNCOMPLETE
}

enum _:Player_Properties
{
	Knife,
	IsAlive,
	Team,
	SpikesSpineEnt,
	JumpState,
	FallDamageRestore,
	bool:WasFallStompDamage
}

enum _:Player_Properties_F
{
	Float:HighJumpTime,
	Float:StompAttackTime,
	Float:TrailTime,
	Float:SpikesDamagedTime,
	Float:FallDamageRestoreTime
}

new
g_iKnifeId, g_player_data[MAX_PLAYERS][Player_Properties], Float:g_player_data_f[MAX_PLAYERS][Player_Properties_F],
rockGibs, sprSteam, g_pKnifePMdl

public plugin_precache()
{
	precache_sound(SOUND_KNIFE_IDLE)
	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_DEPLOY)
	precache_sound(SOUND_KNIFE_SLASH)

	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(SPIKES_MODEL)
	precache_model(SPIKES_SPINE_MODEL)
	precache_sound(SPIKES_UP_SOUND)
	precache_sound(SPIKES_SPINE_SOUND)
	precache_sound(SPIKES_JUMP_SOUND)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	rockGibs = precache_model("models/rockgibs.mdl")
	sprSteam = precache_model("sprites/steam1.spr")
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

	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLEABLE)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH)

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Player_PreThink, "player", "fw_PlayerPreThink")
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerDamage_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][IsAlive] = 0
	Player[iPlayer][Team] = 0
}

public client_disconnected(iPlayer)
{
	if (Player[iPlayer][SpikesSpineEnt])
		remove_spikes_spine(iPlayer)

	Player[iPlayer][IsAlive] = 0
	Player[iPlayer][Team] = 0
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, SPIKES_CLASSNAME)))
		rg_remove_entity(iEnt)
}

public fw_PlayerSpawn(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		if (Player[iPlayer][SpikesSpineEnt])
			remove_spikes_spine(iPlayer)

		Player[iPlayer][IsAlive] = 1
		PlayerF[iPlayer][HighJumpTime] = get_gametime() + RESET_ABIL_AFTER_SPAWN
		Player[iPlayer][JumpState] = 0
		Player[iPlayer][FallDamageRestore] = 0
	}
}

public fw_PlayerPreThink(iPlayer)
{
	if (!Player[iPlayer][IsAlive])
		return HAM_IGNORED

	if (Player[iPlayer][Knife] != g_iKnifeId)
		return HAM_IGNORED

	static flags
	flags = get_entvar(iPlayer, var_flags)

	new Float:fGameTime = get_gametime()

	if (Player[iPlayer][FallDamageRestore]
		&& PlayerF[iPlayer][FallDamageRestoreTime] <= fGameTime
		&& !kc_player_in_burn(iPlayer))
	{
		new Float:fMaxHealth = kc_player_get_maxhealth(iPlayer)
		new Float:fHealth = Float:get_entvar(iPlayer, var_health)
		new iRest = min(Player[iPlayer][FallDamageRestore], DAMAGE_RESTORE_HEAL)

		if (fHealth + float(iRest) >= fMaxHealth)
		{
			if (fHealth < fMaxHealth)
				set_entvar(iPlayer, var_health, fMaxHealth)
			Player[iPlayer][FallDamageRestore] = 0
		}
		else
		{
			set_entvar(iPlayer, var_health, fHealth + float(iRest))
			Player[iPlayer][FallDamageRestore] -= iRest
			PlayerF[iPlayer][FallDamageRestoreTime] = fGameTime + DAMAGE_RESTORE_DELAY
		}
	}

	if ((flags & FL_INWATER) || (flags & FL_ONGROUND))
	{
		if (Player[iPlayer][JumpState])
			PlayerF[iPlayer][HighJumpTime] = fGameTime + HIGHJUMP_COOLDOWN

		Player[iPlayer][JumpState] = 0

		if (PlayerF[iPlayer][TrailTime] && PlayerF[iPlayer][TrailTime] <= fGameTime)
			remove_trail(iPlayer)

		return HAM_IGNORED
	}

	if (Player[iPlayer][JumpState] && kc_player_get_bair(iPlayer))
	{
		PlayerF[iPlayer][HighJumpTime] = fGameTime + HIGHJUMP_COOLDOWN
		Player[iPlayer][JumpState] = 0
	}

	if (PlayerF[iPlayer][TrailTime] && PlayerF[iPlayer][TrailTime] <= fGameTime)
		remove_trail(iPlayer)

	if (PlayerF[iPlayer][HighJumpTime] >= fGameTime)
		return HAM_IGNORED

	static nbut, obut
	nbut = get_entvar(iPlayer, var_button)
	obut = get_entvar(iPlayer, var_oldbuttons)

	if (nbut & IN_JUMP)
	{
		if (!(flags & FL_ONGROUND) && !(obut & IN_JUMP))
		{
			if (is_player_slowed(iPlayer, SPEED))
				return HAM_IGNORED

			static Float:vOrigin[5][3]

			get_entvar(iPlayer, var_origin, vOrigin[0])
			xs_vec_copy(vOrigin[0], vOrigin[1])
			xs_vec_copy(vOrigin[0], vOrigin[2])
			xs_vec_copy(vOrigin[0], vOrigin[3])
			xs_vec_copy(vOrigin[0], vOrigin[4])

			vOrigin[1][0] -= 16.0
			vOrigin[1][1] -= 16.0

			vOrigin[2][0] += 16.0
			vOrigin[2][1] += 16.0

			vOrigin[3][0] -= 16.0
			vOrigin[3][1] += 16.0

			vOrigin[4][0] += 16.0
			vOrigin[4][1] -= 16.0

			static Float:fDistance
			get_entvar(iPlayer, var_gravity, fDistance)
			fDistance = GRAVITY / (floatmin(1.0, fDistance + 0.2)) * 180.0

			if (Player[iPlayer][JumpState] != 2 &&
				check_floor_disnace(iPlayer, vOrigin[0], fDistance) && check_floor_disnace(iPlayer, vOrigin[1], fDistance)
				&& check_floor_disnace(iPlayer, vOrigin[2], fDistance) && check_floor_disnace(iPlayer, vOrigin[3], fDistance)
				&& check_floor_disnace(iPlayer, vOrigin[4], fDistance))
			{
				send_msg_TE_BEAMFOLLOW(iPlayer, sprSteam, 10, 5, {255, 0, 0}, 192)

				engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SPIKES_JUMP_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)

				new Float:vAngles[3]
				get_entvar(iPlayer, var_v_angle, vAngles)
				vOrigin[0][0] = 0.0
				vOrigin[0][1] = 0.0
				vOrigin[0][2] = -1.0

				if (vAngles[0] > 20.0)
				{
					vAngles[0] = floatmax(vAngles[0], 25.0)
					angle_vector(vAngles, ANGLEVECTOR_FORWARD, vOrigin[0])
				}

				xs_vec_mul_scalar(vOrigin[0], -DROWN_FORCE / vOrigin[0][2], vOrigin[0])

				set_entvar(iPlayer, var_velocity, vOrigin[0])

				PlayerF[iPlayer][TrailTime] = fGameTime + 0.5
				PlayerF[iPlayer][StompAttackTime] = fGameTime + 5.0
				Player[iPlayer][JumpState] = 2
			}
			else if (!is_player_slowed(iPlayer, SPEED) && (nbut & IN_DUCK)
				&& !Player[iPlayer][JumpState])
			{
				send_msg_TE_BEAMFOLLOW(iPlayer, sprSteam, 10, 5, {255, 0, 0}, 192)

				engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SPIKES_JUMP_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_entvar(iPlayer, var_velocity, {0.0, 0.0, HIGHJUMP_FORCE})

				PlayerF[iPlayer][TrailTime] = fGameTime + 0.5
				Player[iPlayer][JumpState] = 1
			}
		}
	}

	return HAM_IGNORED
}

public fw_PlayerDamage(iVictim, inflictor, attacker, Float:damage, bits)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if ((bits & DMG_FALL) && Player[iVictim][JumpState] == 2 && !entity_in_any_web(iVictim))
	{
		new Float:fGameTime = get_gametime()
		if (PlayerF[iVictim][StompAttackTime] > fGameTime)
		{
			if (PlayerF[iVictim][StompAttackTime] - fGameTime < 4.8)
			{
				new Float:vPlayerOrigin[3], Float:vEntOrigin[3], Float:vFloorOrigin[3], Float:vAngles[3], iSpikeEnt
				get_entvar(iVictim, var_origin, vPlayerOrigin)

				iSpikeEnt = rg_create_entity(SZ_INFO_TARGET)
				if (is_entity(iSpikeEnt))
				{
					get_floor_origin(iSpikeEnt, vPlayerOrigin, vFloorOrigin)

					if (engfunc(EngFunc_PointContents, vFloorOrigin) == CONTENTS_EMPTY)
					{
						vAngles[1] = 0.0
						spike_setup(iSpikeEnt, iVictim, vFloorOrigin, vAngles, fGameTime)
					}
					else
						set_entvar(iSpikeEnt, var_flags, FL_KILLME)
				}

				for (new i; i < MAX_STOMP_CENTER_SPIKES; i++)
				{
					iSpikeEnt = rg_create_entity(SZ_INFO_TARGET)
					if (!is_entity(iSpikeEnt))
						break

					vEntOrigin[0] = vPlayerOrigin[0] + floatcos(i * 360.0 / MAX_STOMP_CENTER_SPIKES, degrees) * 30.0
					vEntOrigin[1] = vPlayerOrigin[1] + floatsin(i * 360.0 / MAX_STOMP_CENTER_SPIKES, degrees) * 30.0
					vEntOrigin[2] = vPlayerOrigin[2]

					get_floor_origin(iSpikeEnt, vEntOrigin, vFloorOrigin)

					if (engfunc(EngFunc_PointContents, vFloorOrigin) != CONTENTS_EMPTY)
					{
						set_entvar(iSpikeEnt, var_flags, FL_KILLME)
						continue
					}

					vAngles[1] = i * 360.0 / MAX_STOMP_CENTER_SPIKES

					spike_setup(iSpikeEnt, iVictim, vFloorOrigin, vAngles, fGameTime)
					set_entvar(iSpikeEnt, var_spike_lifetime, 0.45)
				}

				for (new i; i < MAX_STOMP_SPIKES; i++)
				{
					iSpikeEnt = rg_create_entity(SZ_INFO_TARGET)
					if (!is_entity(iSpikeEnt))
						break

					vEntOrigin[0] = vPlayerOrigin[0] + floatcos(i * 360.0 / MAX_STOMP_SPIKES, degrees) * 100.0
					vEntOrigin[1] = vPlayerOrigin[1] + floatsin(i * 360.0 / MAX_STOMP_SPIKES, degrees) * 100.0
					vEntOrigin[2] = vPlayerOrigin[2]

					get_floor_origin(iSpikeEnt, vEntOrigin, vFloorOrigin)

					if (engfunc(EngFunc_PointContents, vFloorOrigin) != CONTENTS_EMPTY)
					{
						set_entvar(iSpikeEnt, var_flags, FL_KILLME)
						continue
					}

					vAngles[1] = i * 360.0 / MAX_STOMP_SPIKES

					spike_setup(iSpikeEnt, iVictim, vFloorOrigin, vAngles, fGameTime)
				}

				if (PlayerF[iVictim][StompAttackTime] - fGameTime < 4.55)
				{
					for (new i; i < MAX_STOMP_SPIKES; i++)
					{
						iSpikeEnt = rg_create_entity(SZ_INFO_TARGET)
						if (!is_entity(iSpikeEnt))
							break

						vEntOrigin[0] = vPlayerOrigin[0] + floatcos(i * 360.0 / MAX_STOMP_SPIKES + 180.0 / MAX_STOMP_SPIKES, degrees) * 160.0
						vEntOrigin[1] = vPlayerOrigin[1] + floatsin(i * 360.0 / MAX_STOMP_SPIKES + 180.0 / MAX_STOMP_SPIKES, degrees) * 160.0
						vEntOrigin[2] = vPlayerOrigin[2]

						get_floor_origin(iSpikeEnt, vEntOrigin, vFloorOrigin)

						if (engfunc(EngFunc_PointContents, vFloorOrigin) != CONTENTS_EMPTY)
						{
							set_entvar(iSpikeEnt, var_flags, FL_KILLME)
							continue
						}

						vAngles[1] = i * 360.0 / MAX_STOMP_SPIKES + 180.0 / MAX_STOMP_SPIKES

						spike_setup(iSpikeEnt, iVictim, vFloorOrigin, vAngles, fGameTime + 0.2)
					}
				}

				SetHamParamFloat(4, floatround(damage / FALLDMGDIVIDER, floatround_floor) + 0.0)
				Player[iVictim][WasFallStompDamage] = true

				PlayerF[iVictim][StompAttackTime] = 0.0
				PlayerF[iVictim][HighJumpTime] = fGameTime + DROWN_COOLDOWN
				Player[iVictim][JumpState] = 0
			}
			else
				SetHamParamFloat(4, 0.0)

			return HAM_OVERRIDE
		}
	}

	if (!is_entity_player(attacker))
		return HAM_IGNORED

	if (!Player[iVictim][SpikesSpineEnt])
		return HAM_IGNORED

	if (!(bits & DMG_BULLET))
		return HAM_IGNORED

	if (Player[iVictim][Team] == Player[attacker][Team])
		return HAM_IGNORED

	if (check_back_hit(iVictim, inflictor))
	{
		SetHamParamFloat(4, floatmin(damage, SPINE_SPIKES_MAX_TAKEDAMAGE))

		if (!kc_player_in_protection(attacker) && attacker == inflictor)
		{
			kc_player_set_death_reason(attacker, "DEATH_REASON_SPIKES")
			set_member(attacker, m_LastHitGroup, HIT_GENERIC)
			ExecuteHamB(Ham_TakeDamage, attacker, Player[iVictim][SpikesSpineEnt], iVictim, SPINE_SPIKES_DAMAGE, DMG_BULLET)
		}

		if (damage >= 1.0)
		{
			remove_spikes_spine(iVictim)
			set_spikes_spine_cooldown_charge(iVictim)
		}

		return HAM_OVERRIDE
	}

	return HAM_IGNORED
}

public fw_PlayerDamage_Post(iVictim, inflictor, attacker, Float:fDamage, bits)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (!Player[iVictim][IsAlive])
		return HAM_IGNORED

	if ((bits & DMG_FALL) && (!iVictim || iVictim == attacker))
	{
		if (Player[iVictim][WasFallStompDamage])
		{
			Player[iVictim][WasFallStompDamage] = false

			if (!Player[iVictim][FallDamageRestore])
				PlayerF[iVictim][FallDamageRestoreTime] = get_gametime() + DAMAGE_RESTORE_START_TIME

			Player[iVictim][FallDamageRestore] += floatround(fDamage, floatround_floor)
		}
	}

	return HAM_IGNORED
}

public fw_PlayerKilled(iVictim)
{
	if (Player[iVictim][SpikesSpineEnt])
		remove_spikes_spine(iVictim)

	Player[iVictim][IsAlive] = 0
	PlayerF[iVictim][HighJumpTime] = 0.0
	Player[iVictim][JumpState] = 0
	Player[iVictim][FallDamageRestore] = 0

	if (PlayerF[iVictim][TrailTime])
		remove_trail(iVictim)
}

public efk_player_change_team(iPlayer, iTeam)
{
	Player[iPlayer][Team] = iTeam
}

spike_setup(iEnt, iOwner, Float:vOrigin[3], Float:vAngles[3], Float:fSpawnTime)
{
	engfunc(EngFunc_SetModel, iEnt, SPIKES_MODEL)
	engfunc(EngFunc_SetOrigin, iEnt, vOrigin)
	engfunc(EngFunc_SetSize, iEnt, Float:{-6.0, -6.0, -3.0}, Float:{6.0, 6.0, 18.0})

	set_entvar(iEnt, var_origin, vOrigin)
	set_entvar(iEnt, var_angles, vAngles)
	set_entvar(iEnt, var_classname, SPIKES_CLASSNAME)
	set_entvar(iEnt, var_impulse, IMPULSE_SPIKES)

	set_entvar(iEnt, var_skin, Player[iOwner][Team] - 1)
	set_entvar(iEnt, var_owner, iOwner)

	set_entvar(iEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iEnt, var_rendermode, kRenderNormal)
	set_entvar(iEnt, var_effects, EF_NODRAW)

	set_entvar(iEnt, var_sequence, SPIKE_SEQ_IDLE_DOWN)
	set_entvar(iEnt, var_framerate, 1.0)
	set_entvar(iEnt, var_nextthink, fSpawnTime)

	set_entvar(iEnt, var_spike_lifetime, 3.2)

	SetThink(iEnt, "spike_think")
	SetTouch(iEnt, "spike_touch")
}

public spike_think(iEnt)
{
	switch (get_entvar(iEnt, var_sequence))
	{
		case SPIKE_SEQ_IDLE:
		{
			new Float:fGameTime = get_gametime()

			set_entvar(iEnt, var_sequence, SPIKE_SEQ_DOWN)
			set_entvar(iEnt, var_animtime, fGameTime)
			set_entvar(iEnt, var_nextthink, fGameTime + 0.6)
		}
		case SPIKE_SEQ_IDLE_DOWN:
		{
			new Float:vOrigin[3], Float:fGameTime = get_gametime()
			get_entvar(iEnt, var_origin, vOrigin)

			engfunc(EngFunc_EmitSound, iEnt, CHAN_AUTO, SPIKES_UP_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)

			set_entvar(iEnt, var_effects, 0)
			set_entvar(iEnt, var_animtime, fGameTime)

			new iWebEnt = MaxClients
			while ((iWebEnt = engfunc(EngFunc_FindEntityInSphere, iWebEnt, vOrigin, 12.0)))
			{
				if (get_entvar(iWebEnt, var_impulse) == IMPULSE_WEB
					&& get_entvar(iWebEnt, var_skin) != get_entvar(iEnt, var_skin)
					&& entity_in_web(iEnt, iWebEnt))
				{
					set_entvar(iEnt, var_solid, SOLID_NOT)
					set_entvar(iEnt, var_sequence, SPIKE_SEQ_UP_UNCOMPLETE)
					set_entvar(iEnt, var_nextthink, fGameTime + Float:get_entvar(iEnt, var_spike_lifetime))

					return
				}
			}

			draw_rocks(vOrigin)

			set_entvar(iEnt, var_sequence, SPIKE_SEQ_UP)
			set_entvar(iEnt, var_nextthink, fGameTime + 0.3)
		}
		case SPIKE_SEQ_UP:
		{
			new Float:fGameTime = get_gametime()

			set_entvar(iEnt, var_sequence, SPIKE_SEQ_IDLE)
			set_entvar(iEnt, var_animtime, fGameTime)
			set_entvar(iEnt, var_nextthink, fGameTime + Float:get_entvar(iEnt, var_spike_lifetime))
		}
		case SPIKE_SEQ_DOWN..SPIKE_SEQ_UP_UNCOMPLETE: set_entvar(iEnt, var_flags, FL_KILLME)
	}
}

public spike_touch(iEnt, iOther)
{
	if (!is_entity(iOther))
		return

	if (is_entity_player(iOther))
	{
		if (!Player[iOther][IsAlive])
			return

		new iAttacker = get_entvar(iEnt, var_owner)

		if (Player[iOther][Team] == Player[iAttacker][Team])
			return

		if (kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY))
			return

		new iSeq = get_entvar(iEnt, var_sequence)

		switch (iSeq)
		{
			case SPIKE_SEQ_IDLE:
			{
				new Float:fGameTime = get_gametime()

				if (PlayerF[iOther][SpikesDamagedTime] > fGameTime)
					return

				kc_player_unfreeze(iOther)

				new Float:fDamage = random_float(SPIKES_MINDAMAGE, SPIKES_MAXDAMAGE)

				kc_player_set_death_reason(iOther, "DEATH_REASON_SPIKES")
				set_member(iOther, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iAttacker, fDamage, DMG_CLUB)

				PlayerF[iOther][SpikesDamagedTime] = fGameTime + 0.5
			}
			case SPIKE_SEQ_UP:
			{
				new Float:fGameTime = get_gametime()

				if(PlayerF[iOther][SpikesDamagedTime] > fGameTime)
					return

				kc_player_unfreeze(iOther)
				kc_player_slow(iOther, 0.35, 3.0)

				if (get_pdata_int(iOther, 350) > 0) // m_iTrain
				{
					set_pdata_int(iOther, 350, 0xc0)
					set_pdata_int(iOther, 257, get_pdata_int(iOther, 257) & ~(1<<1))  // m_afPhysicsFlags
					set_pdata_cbase(get_entvar(iOther, var_groundentity), 85, -1, 4) // m_pDriver
				}

				new Float:fDamage = random_float(SPIKES_START_MINDAMAGE, SPIKES_START_MAXDAMAGE)

				kc_player_set_death_reason(iOther, "DEATH_REASON_SPIKES")
				set_member(iOther, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iAttacker, fDamage, DMG_CLUB)

				new Float:vVelocity[3]
				vVelocity[2] = (get_entvar(iOther, var_flags) & FL_ONGROUND) ? 800.0 : 500.0
				vVelocity[2] *= Float:get_entvar(iOther, var_gravity)
				set_entvar(iOther, var_velocity, vVelocity)

				PlayerF[iOther][SpikesDamagedTime] = fGameTime + 0.3
			}
		}

	}
	else if (get_entvar(iOther, var_flags) & FL_MONSTER)
	{
		new iSeq = get_entvar(iEnt, var_sequence)

		if (iSeq == SPIKE_SEQ_IDLE || iSeq == SPIKE_SEQ_UP)
		{
			new iAttacker = get_entvar(iEnt, var_owner)

			if (Player[iAttacker][Team] == get_entvar(iOther, var_skin) + 1)
				return

			ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iAttacker, 60.0, DMG_BLAST)
		}
	}
}

public efk_capture(iPlayer, CaptureType:iType)
{
	if (Player[iPlayer][SpikesSpineEnt])
	{
		remove_spikes_spine(iPlayer)
		set_spikes_spine_cooldown_charge(iPlayer)
	}
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	new Float:fGameTime = get_gametime()

	if (PlayerF[iSubject][HighJumpTime] > fGameTime)
	{
		set_hudmessage(255, 0, 0, 0.01, -0.7, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "High | Drown jump (%..1f)", PlayerF[iSubject][HighJumpTime] - fGameTime)
	}

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	if (Player[iPlayer][SpikesSpineEnt])
		remove_spikes_spine(iPlayer)

	Player[iPlayer][Knife] = iKnifeId

	if (PlayerF[iPlayer][TrailTime])
		remove_trail(iPlayer)

	Player[iPlayer][JumpState] = 0
	Player[iPlayer][FallDamageRestore] = 0
}

public efk_ability(iPlayer)
{
	kc_player_set_view_anim(iPlayer, VIEW_SEQ_STAB)

	new Float:vOrigin[3], Float:vAngles[3], Float:vVector[3], Float:fDistance[3], up_koef, iSpikeEnt

	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_angles, vAngles)

	vAngles[0] = 0.0
	vAngles[2] = 0.0
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vVector)

	new Float:distance = 40.0, owner = iPlayer

	for (new i = 1; i <= SPIKES_NUM; i++)
	{
		iSpikeEnt = rg_create_entity(SZ_INFO_TARGET)
		if (!is_entity(iSpikeEnt))
			break

		xs_vec_mul_scalar(vVector, distance, fDistance)
		xs_vec_add(vOrigin, fDistance, vOrigin)

		get_floor_origin(iSpikeEnt, vOrigin, fDistance)

		if (engfunc(EngFunc_PointContents, fDistance) != CONTENTS_EMPTY)
		{
			up_koef++
			fDistance[2] = vOrigin[2] + 36.0 + up_koef * 15.0
			get_floor_origin(iSpikeEnt, fDistance, fDistance)

			if (engfunc(EngFunc_PointContents, fDistance) != CONTENTS_EMPTY)
			{
				set_entvar(iSpikeEnt, var_flags, FL_KILLME)
				continue
			}
		}

		spike_setup(iSpikeEnt, owner, fDistance, vAngles, get_gametime() + i * 0.05)

		if (distance > 0.0)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (Player[i][IsAlive] && Player[i][Team] != Player[iPlayer][Team]
					&& kc_player_in_reflection(i)
					&& fm_entity_range(i, iSpikeEnt) < 130.0)
				{
					distance = -distance * 1.5
					vAngles[1] = -vAngles[1]
					owner = i

					kc_player_reflection_done(i, iPlayer)
					break
				}
			}
		}
	}
}

public efk_ability2_pre(iPlayer)
{
	if (Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (Player[iPlayer][SpikesSpineEnt])
		return PLUGIN_HANDLED

	kc_player_set_capture(iPlayer, CAPTURE_NONE)
	return PLUGIN_CONTINUE
}

public efk_ability2(iPlayer)
{
	new iSpineEnt = rg_create_entity(SZ_INFO_TARGET)
	if (!is_entity(iSpineEnt))
		return PLUGIN_CONTINUE

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SPIKES_SPINE_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)

	Player[iPlayer][SpikesSpineEnt] = iSpineEnt

	set_entvar(iSpineEnt, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iSpineEnt, var_aiment, iPlayer)
	set_entvar(iSpineEnt, var_rendermode, kRenderNormal)
	set_entvar(iSpineEnt, var_skin, Player[iPlayer][Team] - 1)
	engfunc(EngFunc_SetModel, iSpineEnt, SPIKES_SPINE_MODEL)

	send_msg_StatusIcon(true, "dmg_bio", {255, 0, 0}, MSG_ONE, _, iPlayer)

	return PLUGIN_CONTINUE
}

public efk_ability3(iPlayer)
{
	new Float:vAngles[3]
	get_entvar(iPlayer, var_angles, vAngles)

	vAngles[1] += vAngles[1] >= 180.0 ? -180.0 : 180.0
	set_entvar(iPlayer, var_angles, vAngles)
	set_entvar(iPlayer, var_fixangle, 1)

	if (!(kc_player_get_bair(iPlayer) & FL_BAIR_NORMAL))
	{
		new Float:vVelocity[3]
		get_entvar(iPlayer, var_velocity, vVelocity)

		vVelocity[0] *= -1.0
		vVelocity[1] *= -1.0
		set_entvar(iPlayer, var_velocity, vVelocity)
	}
}

remove_spikes_spine(iPlayer)
{
	send_msg_StatusIcon(false, "dmg_bio", _, MSG_ONE, _, iPlayer)

	set_entvar(Player[iPlayer][SpikesSpineEnt], var_flags, FL_KILLME)
	Player[iPlayer][SpikesSpineEnt] = 0
}

set_spikes_spine_cooldown_charge(iPlayer)
{
	new Float:fCharge = kc_player_get_abil2_charge(iPlayer)
	if (fCharge > SPINE_SPIKES_MAX_CHARGE)
		kc_player_set_abil2_charge(iPlayer, SPINE_SPIKES_MAX_CHARGE)
}

bool:check_floor_disnace(iEnt, Float:vStart[3], Float:fDist)
{
	static Float:vEnd[3], Float:fFraction
	vEnd[0] = 0.0
	vEnd[1] = 0.0
	vEnd[2] = -fDist
	xs_vec_add(vStart, vEnd, vEnd)

	engfunc(EngFunc_TraceLine, vStart, vEnd, DONT_IGNORE_MONSTERS, iEnt, 0)
	get_tr2(0, TR_flFraction, fFraction)

	return fFraction == 1.0
}

bool:check_back_hit(iVictim, iInflictor)
{
	new Float:vVicOrigin[3], Float:vInfOrigin[3], Float:vAngles[3],
		Float:vForwardDirA[3], Float:vForwardDirB[3]

	get_entvar(iVictim, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForwardDirA)

	get_entity_center(iVictim, vVicOrigin)
	get_entity_center(iInflictor, vInfOrigin)
	xs_vec_sub(vVicOrigin, vInfOrigin, vForwardDirB)

	vForwardDirA[2] = vForwardDirB[2] = 0.0
	xs_vec_normalize(vForwardDirA, vForwardDirA)
	xs_vec_normalize(vForwardDirB, vForwardDirB)

	return xs_vec_dot(vForwardDirA, vForwardDirB) > 0.3
}

get_entity_center(iEnt, Float:vCenter[3])
{
	new Float:vTargetMins[3], Float:vTargetMaxs[3]
	get_entvar(iEnt, var_absmin, vTargetMins)
	get_entvar(iEnt, var_absmax, vTargetMaxs)
	vCenter[0] = (vTargetMins[0] + vTargetMaxs[0]) * 0.5
	vCenter[1] = (vTargetMins[1] + vTargetMaxs[1]) * 0.5
	vCenter[2] = (vTargetMins[2] + vTargetMaxs[2]) * 0.5
}

remove_trail(iPlayer)
{
	if (!kc_player_in_chill(iPlayer))
		send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)
	PlayerF[iPlayer][TrailTime] = 0.0
}

draw_rocks(Float:vOrigin[3])
{
	new aPlayers[MAX_PLAYERS], iPlayerNum
	get_players(aPlayers, iPlayerNum, "c")

	for (new i, iPlayer; i < iPlayerNum; i++)
	{
		iPlayer = aPlayers[i]
		if (kc_player_get_options(iPlayer) & OPTION_DISABLE_PARTICLES)
			continue

		send_msg_TE_BREAKMODEL(vOrigin, Float:{0.0, 0.0, 0.0}, Float:{5.0, 5.0, 5.0},
			15, rockGibs, 25, 30, 0, MSG_ONE_UNRELIABLE, _, iPlayer)
	}
}
