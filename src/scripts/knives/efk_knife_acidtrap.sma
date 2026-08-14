#include <amxmodx>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <beams>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Acidtrap Knife"

#define KNIFE_CLASSNAME "weapon_next21_acidtrap_r02"
#define KNIFE_MENUDESC  "KNIFE_ACIDTRAP_DESC"
#define KNIFE_CHATDESC  "KNIFE_ACIDTRAP_CHAT"

#define HP				80.0
#define GRAVITY			1.0
#define SPEED			260.0
#define MINDAMAGE		5.0
#define MAXDAMAGE		10.0

#define KNIFE_LEVEL     2

#define ABIL1_NAME		"Acidtrap"
#define ABIL1_CHARGE	6.25

#define ABIL3_NAME		"Acid Spit"
#define ABIL3_CHARGE	7.693

new const MODEL_V_KNIFE[] = "models/next21_efk/v_acidtrap_knife_r03.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_acidtrap_knife_r02.mdl"

new const SOUND_KNIFE_HIT1[] = "next21_efk/acidtrap_knife_hit1_r02.wav"
new const SOUND_KNIFE_HIT2[] = "next21_efk/acidtrap_knife_hit2_r02.wav"
new const SOUND_KNIFE_HITWALL[] = "next21_efk/acidtrap_knife_hitwall_r02.wav"
new const SOUND_KNIFE_SLASH1[] = "next21_efk/acidtrap_knife_slash1_r02.wav"
new const SOUND_KNIFE_SLASH2[] = "next21_efk/acidtrap_knife_slash1_r02.wav"
new const SOUND_KNIFE_STAB[] = "next21_efk/acidtrap_knife_stab_r02.wav"
new const SOUND_KNIFE_DEPLOY[] = "next21_efk/acidtrap_knife_deploy_r02.wav"

new const MODEL_ACIDTRAP[]			= "models/next21_efk/acidtrap_b02.mdl"
new const MODEL_ACID_BALL[]			= "models/next21_efk/poison_spore1.mdl"
new const MODEL_POISON[]			= "sprites/next21_efk/poison_spr.spr"
new const MODEL_POISON_PARTICLES[]	= "sprites/next21_efk/poison_particles.spr"
new const MODEL_ACID_CLOUD[]		= "sprites/next21_efk/posion_gas.spr"
new const MODEL_ACID_WALL[]			= "models/next21_efk/poison_spore2.mdl"
new const MODEL_BEAM[]				= "sprites/laserbeam.spr"

new const SOUND_TRAP_EXPLOSION[]	= "next21_efk/acidtrap_explosion.wav"
new const SOUND_TRAP_ACTIVATE[]		= "next21_efk/acidtrap_activate.wav"
new const SOUND_TRAP_UNBIND[]		= "next21_efk/acidtrap_unbind.wav"
new const SOUND_ACID_BALL[]			= "next21_efk/acid_launch.wav"

new const SOUND_DETONATE[] 			= "next21_efk/acidtrap_detonate.wav"

new const MODELS_SMOKE[][] =
{
	"sprites/pistol_smoke1.spr",
	"sprites/wall_puff1.spr",
	"sprites/wall_puff3.spr",
	"sprites/wall_puff4.spr"
}

#define ACID_SPEED		1200.0
#define ACID_GRAVITY		0.7

#define MAX_ACIDTRAPS				30
#define ACIDTRAP_FREEZE_TIME		2.2
#define ACIDTRAP_ADDTIME_FREEZE		0.8
#define ACIDTRAP_CATCH_RADIUS		150.0
#define ACIDTRAP_EXPLODE_RADIUS		150.0
#define ACIDTRAP_BASE_DAMAGE		25.0
#define ACIDTRAP_EXPLOSION_DELAY	0.8
#define ACIDTRAP_TACTICAL_DELAY		1.75

#define CLOUD_UPDATERATE			2.0
#define CLOUD_TIMESTODIE			5

#define POISON_UPDATERATE		0.5
#define POISON_TIMESTODIE		15

#define DETONATE_AIM_RADIUS		96.0

#define HIGHLIGHT_MIN_DOT 			0.95
#define HIGHLIGHT_UPDATE_TIME 		0.2

#define TASK_ACIDTRAPS_COUNTER		100

new const Float:ACID_AIM_OFFSET[3] = { 13.4, -5.0, -5.95 }
new const Float:ACID_AIM_OFFSET_DIST[3] = { 26.8, -10.0, -11.9 }

new const COLOR_ACID[]			= {ACID_COLOR_R, ACID_COLOR_G, ACID_COLOR_B}

new const CLASSNAME_ACIDTRAP_[]	= CLASSNAME_ACIDTRAP
new const CLASSNAME_ACIDB_[]	= CLASSNAME_ACIDB
new const CLASSNAME_ACIDP_[]	= CLASSNAME_ACIDP
new const CLASSNAME_ACIDG_[]	= CLASSNAME_ACIDG

new const SZ_BEAM[]			= "beam"
new const SZ_EXPLOSION[]	= "env_explosion"
new const SZ_INFO_TARGET[]	= "info_target"

new const TRAP_TYPE_NAMES[][] =
{
	"Binding",
	"Active",
	"Tactical"
}

enum AcidTrapType
{
	TRAP_BIND,
	TRAP_ACTIVE,
	TRAP_TACTICAL
}

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_AIM,
	VIEW_SEQ_UNAIM
}

enum _:PlayerData
{
	PlrKnife,
	bool:PlrIsAlive,
	PlrTeam,
	AcidTrapType:PlrTrapType,
	PlrWallPt,
	bool:PlrInWall,
	bool:PlrInSpit,
	PlrSpitEnt,
	Float:PlrWallTime,
	Float:PlrUnWallTime,
	Float:PlrWallChargeDeploy,
	Float:PlrSpitTime,
	Float:PlrKillTrail
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId,
	g_ePlayerData[MAX_PLAYERS][PlayerData],
	g_iTacticalTrapsNum[MAX_PLAYERS + 1],
	sprStream, Float:g_fWorldGravity, g_pKnifeVStr, g_pKnifePMdl,
	g_pPoisonModel, g_pPoisonParticlesModel, g_pBeamModel, g_pCloudModel,
	g_pSmokeModels[sizeof MODELS_SMOKE]

public plugin_precache()
{
	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)
	precache_sound(SOUND_KNIFE_STAB)
	precache_sound(SOUND_KNIFE_DEPLOY)

	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(MODEL_ACIDTRAP)
	precache_model(MODEL_ACID_BALL)
	precache_model(MODEL_ACID_WALL)

	precache_sound(SOUND_TRAP_EXPLOSION)
	precache_sound(SOUND_TRAP_ACTIVATE)
	precache_sound(SOUND_TRAP_UNBIND)
	precache_sound(SOUND_ACID_BALL)

	precache_sound(SOUND_DETONATE)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	sprStream = precache_model("sprites/steam1.spr")
	g_pPoisonModel = precache_model(MODEL_POISON)
	g_pPoisonParticlesModel = precache_model(MODEL_POISON_PARTICLES)
	g_pBeamModel = precache_model(MODEL_BEAM)
	g_pCloudModel = precache_model(MODEL_ACID_CLOUD)

	for (new i; i < sizeof MODELS_SMOKE; i++)
		g_pSmokeModels[i] = precache_model(MODELS_SMOKE[i])

	precache_generic("sound/next21_efk/acidtrap_knife_deploy_p01.wav")
	precache_generic("sound/next21_efk/acidtrap_knife_deploy_p02.wav")
	precache_generic("sound/next21_efk/acidtrap_knife_deploy_p03.wav")
	precache_generic("sound/next21_efk/acidtrap_knife_rotate.wav")
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		g_pKnifeVStr, engfunc(EngFunc_AllocString, MODEL_P_KNIFE),
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, ABIL1_CHARGE)
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)

	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLEABLE)
	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_KNIFE2)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHam(Ham_Player_PreThink, "player", "fw_PreThink")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)

	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")

	register_impulse(100, "fw_PlayerFlashlight")
	set_task(0.4, "tactical_traps_counter", TASK_ACIDTRAPS_COUNTER, .flags="b")

	new szEntity[][] =
	{
		"worldspawn", "func_wall", "func_door", "func_door_rotating",
		"func_wall_toggle", "func_breakable", "func_pushable", "func_train",
		"func_illusionary", "func_button", "func_rot_button", "func_rotating",
		"func_vehicle",
		"player"
	}

	for (new i; i < sizeof szEntity; i++)
		register_touch("player", szEntity[i], "fw_WallTouch")

	bind_pcvar_float(get_cvar_pointer("sv_gravity"), g_fWorldGravity)
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0
	Player[iPlayer][PlrKillTrail] = 0.0
	Player[iPlayer][PlrTrapType] = TRAP_BIND
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0
	remove_acidtraps(iPlayer)

	new iEnt

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ACIDB_)))
		if (get_entvar(iEnt, var_owner) == iPlayer)
			rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ACIDP_)))
		if (get_entvar(iEnt, var_owner) == iPlayer)
			rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ACIDG_)))
		if (get_entvar(iEnt, var_owner) == iPlayer)
			rg_remove_entity(iEnt)
}

public RG_CSGameRules_CleanUpMap_Post()
{
	remove_acidtraps()

	new iEnt

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ACIDB_)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ACIDP_)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ACIDG_)))
		rg_remove_entity(iEnt)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		Player[iPlayer][PlrIsAlive] = true
		Player[iPlayer][PlrInSpit] = false
		Player[iPlayer][PlrWallTime] = 0.0
		Player[iPlayer][PlrWallPt] = 100

		if (Player[iPlayer][PlrInWall])
		{
			send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)
			Player[iPlayer][PlrInWall] = false
		}

		new iAcidtrapEnt = NULLENT
		while ((iAcidtrapEnt = rg_find_ent_by_class(iAcidtrapEnt, CLASSNAME_ACIDTRAP_)))
		{
			if (get_entvar(iAcidtrapEnt, var_owner) == iPlayer)
			{
				// Reset explosion delay for active traps
				if (get_entvar(iAcidtrapEnt, var_traptype) == TRAP_ACTIVE)
					set_entvar(iAcidtrapEnt, var_trapholdtime, ACIDTRAP_EXPLOSION_DELAY)
			}
		}
	}
}

public fw_PreThink(iPlayer)
{
	if (!Player[iPlayer][PlrIsAlive])
		return HAM_IGNORED

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HAM_IGNORED

	static Float:fGameTime, button, oldbuttons, iSpitButton, iWallRunButton
	fGameTime = get_gametime()

	if (fGameTime < kc_player_get_swap(iPlayer))
	{
		iWallRunButton = IN_RELOAD
		iSpitButton = IN_USE
	}
	else
	{
		iWallRunButton = IN_USE
		iSpitButton = IN_RELOAD
	}

	if (Player[iPlayer][PlrInSpit])
	{
		set_member(iPlayer, m_flNextAttack, 1.0)
		button = get_entvar(iPlayer, var_button)

		if (!(button & iSpitButton) || Player[iPlayer][PlrSpitTime] + 8.0 <= fGameTime
			|| kc_player_get_capture(iPlayer) != CAPTURE_NONE)
		{
			kc_player_set_view_anim(iPlayer, VIEW_SEQ_UNAIM)

			Player[iPlayer][PlrInSpit] = false

			new ent = rg_create_entity(SZ_EXPLOSION)
			if (!is_nullent(ent))
			{
				engfunc(EngFunc_SetModel, ent, MODEL_ACID_BALL)
				engfunc(EngFunc_SetSize, ent, Float:{-0.5, -0.5, -0.5}, Float:{0.5, 0.5, 0.5})
				set_entvar(ent, var_solid, SOLID_TRIGGER)
				set_entvar(ent, var_movetype, MOVETYPE_TOSS)
				set_entvar(ent, var_takedamage, DAMAGE_NO)

				set_entvar(ent, var_classname, CLASSNAME_ACIDB_)
				set_entvar(ent, var_impulse, IMPULSE_ACIDB)
				set_entvar(ent, var_owner, iPlayer)
				set_entvar(ent, var_gravity, ACID_GRAVITY)
				set_entvar(ent, var_rendermode, kRenderTransAdd)
				set_entvar(ent, var_renderamt, 160.0)

				new Float:vOrigin[3], Float:vViewOfs[3], Float:vVelocity[3], Float:vAngles[3]
				get_entvar(iPlayer, var_origin, vOrigin)
				get_entvar(iPlayer, var_view_ofs, vViewOfs)
				xs_vec_add(vOrigin, vViewOfs, vOrigin)

				get_entvar(iPlayer, var_v_angle, vVelocity)
				engfunc(EngFunc_MakeVectors, vVelocity)
				global_get(glb_v_forward, vVelocity)

				if (kc_player_get_capture(iPlayer) != CAPTURE_NONE)
					vVelocity[2] = floatmin(1.0, vVelocity[2] + 0.4)

				xs_vec_mul_scalar(vVelocity, 8192.0, vVelocity)
				xs_vec_add(vOrigin, vVelocity, vVelocity)
				engfunc(EngFunc_TraceLine, vOrigin, vVelocity, DONT_IGNORE_MONSTERS, iPlayer, 0)
				get_tr2(0, TR_vecEndPos, vVelocity)

				projectile_startpos(vOrigin, ACID_AIM_OFFSET_DIST, vOrigin)

				xs_vec_sub(vVelocity, vOrigin, vVelocity)
				xs_vec_mul_scalar(vVelocity, ACID_SPEED / xs_vec_len(vVelocity), vVelocity)

				vector_to_angle(vVelocity, vAngles)

				engfunc(EngFunc_SetOrigin, ent, vOrigin)
				set_entvar(ent, var_origin, vOrigin)
				set_entvar(ent, var_velocity, vVelocity)
				set_entvar(ent, var_angles, vAngles)

				if (vVelocity[2] > 0.0)
					vAngles[0] = -vAngles[0] / (vVelocity[2] / (ACID_GRAVITY * g_fWorldGravity))
				else
					vAngles[0] = -20.0

				vAngles[1] = 0.0
				vAngles[2] = random_float(-360.0, 360.0)

				set_entvar(ent, var_avelocity, vAngles)
				set_entvar(ent, var_nextthink, fGameTime + 0.2)

				engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_ACID_BALL, 1.0, ATTN_NORM, 0, PITCH_NORM)

				new iItem = get_member(iPlayer, m_pActiveItem)
				if (!is_nullent(iItem))
					set_member(iItem, m_Weapon_flTimeWeaponIdle, 1.4)

				SetThink(ent, "acidball_think")
				SetTouch(ent, "acidball_touch")

				Player[iPlayer][PlrSpitEnt] = ent
			}
		}
		else
		{
			if (Player[iPlayer][PlrSpitTime] <= fGameTime)
			{
				static Float:fUpdateTime[MAX_PLAYERS + 1]

				if (fUpdateTime[iPlayer] < fGameTime)
				{
					static Float:vOrigin[3], Float:vViewOfs[3], Float:vVelocity[3], Float:vEndOrigin[3]
					get_entvar(iPlayer, var_origin, vOrigin)
					get_entvar(iPlayer, var_view_ofs, vViewOfs)
					xs_vec_add(vOrigin, vViewOfs, vOrigin)

					get_entvar(iPlayer, var_v_angle, vEndOrigin)
					engfunc(EngFunc_MakeVectors, vEndOrigin)
					global_get(glb_v_forward, vEndOrigin)
					xs_vec_mul_scalar(vEndOrigin, 8192.0, vEndOrigin)
					xs_vec_add(vOrigin, vEndOrigin, vEndOrigin)
					engfunc(EngFunc_TraceLine, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, iPlayer, 0)
					get_tr2(0, TR_vecEndPos, vEndOrigin)

					projectile_startpos(vOrigin, ACID_AIM_OFFSET, vOrigin)

					xs_vec_sub(vEndOrigin, vOrigin, vVelocity)
					xs_vec_mul_scalar(vVelocity, ACID_SPEED / xs_vec_len(vVelocity), vVelocity)

					static Float:fAliveTime, Float:fFraction
					fAliveTime = 0.0

					for (fAliveTime = 0.0; fAliveTime < 2.0; fAliveTime += 0.1)
					{
						vEndOrigin[0] = vOrigin[0] + vVelocity[0] * 0.1
						vEndOrigin[1] = vOrigin[1] + vVelocity[1] * 0.1
						vEndOrigin[2] = vOrigin[2] + vVelocity[2] * 0.1

						engfunc(EngFunc_TraceLine, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, iPlayer, 0)
						get_tr2(0, TR_flFraction, fFraction)

						if(fFraction < 1.0)
							break

						if (fAliveTime == 0.0)
						{
							send_msg_TE_BEAMENTPOINT(iPlayer|0x2000, vEndOrigin, sprStream, 0, 1, 1,
								3, 0, COLOR_ACID, 255, 0, MSG_ONE_UNRELIABLE, _, iPlayer)
						}
						else
							create_acid_beam(iPlayer, vOrigin, vEndOrigin, 1, 3)

						xs_vec_copy(vEndOrigin, vOrigin)
						vVelocity[2] -= ACID_GRAVITY * g_fWorldGravity * 0.1
					}
					create_acid_beam(iPlayer, vOrigin, vEndOrigin, 1, 35)

					fUpdateTime[iPlayer] = fGameTime + 0.05
				}
			}
		}
	}
	else if (Player[iPlayer][PlrSpitEnt])
	{
		static ent
		ent = Player[iPlayer][PlrSpitEnt]

		if (is_entity(ent) && get_entvar(ent, var_impulse) == IMPULSE_ACIDB
			&& get_entvar(ent, var_owner) == iPlayer)
		{
			button = get_entvar(iPlayer, var_button)
			oldbuttons = get_entvar(iPlayer, var_oldbuttons)

			if ((button & iSpitButton) && !(oldbuttons & iSpitButton))
			{
				set_entvar(ent, var_solid, SOLID_NOT)
				set_entvar(ent, var_nextthink, fGameTime)
				Player[iPlayer][PlrSpitEnt] = 0
			}
		}
		else
			Player[iPlayer][PlrSpitEnt] = 0
	}

	if (Player[iPlayer][PlrInWall])
	{
		button = get_entvar(iPlayer, var_button)

		if (!(button & iWallRunButton) || fGameTime >= Player[iPlayer][PlrWallTime] || (get_entvar(iPlayer, var_flags) & FL_ONGROUND)
			|| !Player[iPlayer][PlrWallPt] || Float:get_entvar(iPlayer, var_maxspeed) - floatmin(kc_player_get_powerspeed(iPlayer), 0.0) < SPEED)
		{
			Player[iPlayer][PlrKillTrail] = fGameTime + 0.2
			Player[iPlayer][PlrInWall] = false
			Player[iPlayer][PlrWallTime] = 0.0
			return HAM_IGNORED
		}

		oldbuttons = get_entvar(iPlayer, var_oldbuttons)

		if((button & IN_JUMP)  && !(oldbuttons & IN_JUMP) && Player[iPlayer][PlrWallPt] >= 20)
		{
			new Float:vVelocity[3]
			velocity_by_aim(iPlayer, 600, vVelocity)
			vVelocity[2] = floatmax(vVelocity[2], -150.0)
			set_entvar(iPlayer, var_velocity, vVelocity)

			Player[iPlayer][PlrWallPt] -= 20
			Player[iPlayer][PlrKillTrail] = fGameTime + 0.2

			Player[iPlayer][PlrInWall] = false
			Player[iPlayer][PlrWallTime] = 0.0
			Player[iPlayer][PlrUnWallTime] = fGameTime + 0.2
			return HAM_IGNORED
		}

		wallclimb(iPlayer)

		if (Player[iPlayer][PlrWallChargeDeploy] < fGameTime)
		{
			Player[iPlayer][PlrWallPt] = max(0, Player[iPlayer][PlrWallPt] - 5)
			Player[iPlayer][PlrWallChargeDeploy] = fGameTime + 0.2
		}
	}
	else
	{
		if (get_entvar(iPlayer, var_flags) & FL_ONGROUND)
		{
			if (Player[iPlayer][PlrWallPt] < 100)
			{
				if (Player[iPlayer][PlrWallChargeDeploy] < fGameTime)
				{
					static Float:vVelocity[3]
					get_entvar(iPlayer, var_velocity, vVelocity)
					Player[iPlayer][PlrWallPt] = min(100, Player[iPlayer][PlrWallPt] + 1 + (xs_vec_len(vVelocity) > 1.0 ? 1 : 2))
					Player[iPlayer][PlrWallChargeDeploy] = fGameTime + 0.2
				}
			}
		}
		else
		{
			if (Player[iPlayer][PlrWallPt] && fGameTime < Player[iPlayer][PlrWallTime] && Player[iPlayer][PlrUnWallTime] <= fGameTime
				&& Float:get_entvar(iPlayer, var_maxspeed) - floatmin(kc_player_get_powerspeed(iPlayer), 0.0) >= SPEED
				&& (get_entvar(iPlayer, var_button) & iWallRunButton)
				&& Float:get_member(iPlayer, m_flVelocityModifier) == 1.0)
			{
				Player[iPlayer][PlrInWall] = true

				send_msg_TE_BEAMFOLLOW(iPlayer, sprStream, 300, 5, COLOR_ACID, 192)

				Player[iPlayer][PlrKillTrail] = 0.0

				wallclimb(iPlayer)

				if (Player[iPlayer][PlrWallChargeDeploy] < fGameTime)
				{
					Player[iPlayer][PlrWallPt] = max(0, Player[iPlayer][PlrWallPt] - 5)
					Player[iPlayer][PlrWallChargeDeploy] = fGameTime + 0.2
				}
			}
		}
	}

	if (Player[iPlayer][PlrKillTrail] > 0.0 && Player[iPlayer][PlrKillTrail] < fGameTime)
	{
		if (!kc_player_in_chill(iPlayer))
		{
			send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)
		}
		Player[iPlayer][PlrKillTrail] = 0.0
	}

	static Float:fLastTrapHighlightTime[MAX_PLAYERS + 1]
	if (g_iTacticalTrapsNum[iPlayer] && fLastTrapHighlightTime[iPlayer] < fGameTime)
	{
		new iTargetAcidtrap = find_highlighted_acidtrap(iPlayer)
		if (!is_nullent(iTargetAcidtrap))
			set_entvar(iTargetAcidtrap, var_traphighlighter, iPlayer)

		fLastTrapHighlightTime[iPlayer] = fGameTime + HIGHLIGHT_UPDATE_TIME
	}

	return HAM_IGNORED
}

public fw_PlayerKilled(iVictim)
{
	Player[iVictim][PlrIsAlive] = false

	if (Player[iVictim][PlrKnife] == g_iKnifeId)
		clear_highlighted_acidtrap(iVictim)

	if ((Player[iVictim][PlrInWall] || Player[iVictim][PlrKillTrail] > 0.0) && !kc_player_in_chill(iVictim))
	{
		send_msg_TE_KILLBEAM(iVictim, MSG_ALL)

		Player[iVictim][PlrInWall] = false
		Player[iVictim][PlrKillTrail] = 0.0
	}

	if (Player[iVictim][PlrInSpit])
	{
		Player[iVictim][PlrInSpit] = false

		new Float:vOrigin[3]
		get_entvar(iVictim, var_origin, vOrigin)

		new iAcidcloudEnt = acidcloud_create(0, vOrigin)
		if (iAcidcloudEnt != NULLENT)
		{
			set_entvar(iAcidcloudEnt, var_owner, iVictim)

			engfunc(EngFunc_EmitSound, iVictim, CHAN_WEAPON, SOUND_ACID_BALL, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
}

public fw_WallTouch(iPlayer)
{
	if (Player[iPlayer][PlrIsAlive])
		Player[iPlayer][PlrWallTime] = get_gametime() + 0.2
}

public event_CurWeapon(iPlayer)
{
	Player[iPlayer][PlrInSpit] = false
}

public fw_PlayerFlashlight(iPlayer)
{
	if (!Player[iPlayer][PlrIsAlive] || Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (!g_iTacticalTrapsNum[iPlayer])
		return PLUGIN_HANDLED

	new iTargetAcidtrap = find_highlighted_acidtrap(iPlayer)
	if (is_nullent(iTargetAcidtrap))
		return PLUGIN_HANDLED

	client_cmd(iPlayer, "spk %s", SOUND_DETONATE)
	acidtrap_detonate(iTargetAcidtrap)
	return PLUGIN_HANDLED
}

public efk_player_change_team(iPlayer, iTeam)
{
	Player[iPlayer][PlrTeam] = iTeam
	remove_acidtraps(iPlayer)
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	if (Player[iPlayer][PlrKnife] == g_iKnifeId)
		clear_highlighted_acidtrap(iPlayer)

	Player[iPlayer][PlrKnife] = iKnifeId
	Player[iPlayer][PlrInSpit] = false
	Player[iPlayer][PlrTrapType] = TRAP_BIND

	if ((Player[iPlayer][PlrInWall] || Player[iPlayer][PlrKillTrail] > 0.0) && !kc_player_in_chill(iPlayer))
	{
		send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)

		Player[iPlayer][PlrInWall] = false
		Player[iPlayer][PlrKillTrail] = 0.0
	}
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	new AcidTrapType:iTrapType = Player[iSubject][PlrTrapType]

	set_hudmessage(ACID_COLOR_R, ACID_COLOR_G, ACID_COLOR_B, 0.01, -0.78, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_STATUS)

	show_hudmessage(iPlayer, "Wall Run (E): %d%%^nTrap (T): %s%s",
		Player[iSubject][PlrWallPt], TRAP_TYPE_NAMES[_:iTrapType],
		g_iTacticalTrapsNum[iSubject] ? "^nDetonate (F)" : "")

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer)
{
	if (acidtrap_create(iPlayer) == NULLENT)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public efk_ability3(iPlayer)
{
	if (Player[iPlayer][PlrInSpit])
		return PLUGIN_HANDLED

	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return PLUGIN_HANDLED

	Player[iPlayer][PlrInSpit] = true
	Player[iPlayer][PlrSpitTime] = get_gametime() + 0.5

	kc_player_set_view_anim(iPlayer, VIEW_SEQ_AIM)

	set_member(iPlayer, m_flNextAttack, 1.0)

	return PLUGIN_CONTINUE
}

public efk_ability_toggle(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	switch_trap_type(iPlayer)
	return PLUGIN_HANDLED
}

public tactical_traps_counter(iTaskId)
{
	arrayset(g_iTacticalTrapsNum, 0, sizeof g_iTacticalTrapsNum)

	new iOwner
	new iAcidtrapEnt = MaxClients
	while ((iAcidtrapEnt = rg_find_ent_by_class(iAcidtrapEnt, CLASSNAME_ACIDTRAP_)))
	{
		if (!is_entity_tactical_fixed_acidtrap(iAcidtrapEnt))
			continue

		iOwner = get_entvar(iAcidtrapEnt, var_owner)
		if (iOwner <= 0 || iOwner > MaxClients)
			continue

		g_iTacticalTrapsNum[iOwner]++
	}
}

wallclimb(iPlayer)
{
	static iButton, Float:vVelocity[3]
	iButton = get_entvar(iPlayer, var_button)

	if (iButton & IN_FORWARD)
		velocity_by_aim(iPlayer, floatround(SPEED), vVelocity)

	else if (iButton & IN_BACK)
		velocity_by_aim(iPlayer, -floatround(SPEED), vVelocity)

	else
		velocity_by_aim(iPlayer, 0, vVelocity)

	set_entvar(iPlayer, var_velocity, vVelocity)
}

find_highlighted_acidtrap(iPlayer)
{
	static Float:vViewOrigin[3], Float:vViewOfs[3], Float:vAimVector[3], Float:vAcidtrapVector[3]
	get_entvar(iPlayer, var_origin, vViewOrigin)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vViewOrigin, vViewOfs, vViewOrigin)

	get_entvar(iPlayer, var_v_angle, vAimVector)
	engfunc(EngFunc_MakeVectors, vAimVector)
	global_get(glb_v_forward, vAimVector)

	new iBestAcidtrapByDistance = NULLENT
	new iBestAcidtrapByDot = NULLENT

	new Float:fBestDistance = 8192.0, Float:fBestDot
	new Float:fAcidtrapDistance, Float:fAcidtrapDot

	new iAcidtrapEnt = MaxClients
	while ((iAcidtrapEnt = rg_find_ent_by_class(iAcidtrapEnt, CLASSNAME_ACIDTRAP_)))
	{
		if (get_entvar(iAcidtrapEnt, var_owner) != iPlayer)
			continue

		set_entvar(iAcidtrapEnt, var_traphighlighter, 0)

		if (!is_entity_tactical_fixed_acidtrap(iAcidtrapEnt))
			continue

		get_entvar(iAcidtrapEnt, var_origin, vAcidtrapVector)
		xs_vec_sub(vAcidtrapVector, vViewOrigin, vAcidtrapVector)
		fAcidtrapDistance = xs_vec_len(vAcidtrapVector)
		xs_vec_normalize(vAcidtrapVector, vAcidtrapVector)

		fAcidtrapDot = xs_vec_dot(vAimVector, vAcidtrapVector)
		if (fAcidtrapDot > fBestDot)
		{
			fBestDot = fAcidtrapDot
			iBestAcidtrapByDot = iAcidtrapEnt
		}

		if (fAcidtrapDistance < fBestDistance)
		{
			fBestDistance = fAcidtrapDistance
			iBestAcidtrapByDistance = iAcidtrapEnt
		}
	}

	if (fBestDot >= HIGHLIGHT_MIN_DOT)
		return iBestAcidtrapByDot

	return iBestAcidtrapByDistance
}

clear_highlighted_acidtrap(iPlayer)
{
	new iAcidtrapEnt = MaxClients
	while ((iAcidtrapEnt = rg_find_ent_by_class(iAcidtrapEnt, CLASSNAME_ACIDTRAP_)))
	{
		if (get_entvar(iAcidtrapEnt, var_owner) != iPlayer)
			continue

		set_entvar(iAcidtrapEnt, var_traphighlighter, 0)
	}
}

acidtrap_create(iPlayer)
{
	new AcidTrapType:iTrapType = Player[iPlayer][PlrTrapType]

	new iAcidtrapEnt = NULLENT, iSummaryTrapsNum, iSelectedTrapsNum
	while ((iAcidtrapEnt = rg_find_ent_by_class(iAcidtrapEnt, CLASSNAME_ACIDTRAP_)))
	{
		if (get_entvar(iAcidtrapEnt, var_owner) == iPlayer)
		{
			if (get_entvar(iAcidtrapEnt, var_traptype) == iTrapType)
				iSelectedTrapsNum++
		}
		iSummaryTrapsNum++
	}

	if (iSummaryTrapsNum >= MAX_ACIDTRAPS)
		return NULLENT

	iAcidtrapEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iAcidtrapEnt))
		return NULLENT

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	new Float:vAngles[3]
	get_entvar(iPlayer, var_angles, vAngles)
	vAngles[0] = 0.0
	vAngles[2] = 0.0

	engfunc(EngFunc_SetModel, iAcidtrapEnt, MODEL_ACIDTRAP)
	engfunc(EngFunc_SetOrigin, iAcidtrapEnt, vOrigin)

	set_entvar(iAcidtrapEnt, var_origin, vOrigin)
	set_entvar(iAcidtrapEnt, var_angles, vAngles)
	set_entvar(iAcidtrapEnt, var_owner, iPlayer)
	set_entvar(iAcidtrapEnt, var_classname, CLASSNAME_ACIDTRAP_)
	set_entvar(iAcidtrapEnt, var_impulse, IMPULSE_ACIDTRAP)
	set_entvar(iAcidtrapEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iAcidtrapEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iAcidtrapEnt, var_skin, Player[iPlayer][PlrTeam] - 1)
	set_entvar(iAcidtrapEnt, var_body, iTrapType)

	engfunc(EngFunc_SetSize, iAcidtrapEnt, Float:{-5.0, -5.0, 0.0}, Float:{5.0, 5.0, 23.0})

	set_entvar(iAcidtrapEnt, var_rendermode, kRenderTransAlpha)
	set_entvar(iAcidtrapEnt, var_renderamt, 120.0)

	set_entvar(iAcidtrapEnt, var_sequence, 0)
	set_entvar(iAcidtrapEnt, var_framerate, 0.0)
	set_entvar(iAcidtrapEnt, var_trapstate, TRAPSTATE_FREE)
	set_entvar(iAcidtrapEnt, var_traptype, iTrapType)
	set_entvar(iAcidtrapEnt, var_traphighlighter, 0)
	set_entvar(iAcidtrapEnt, var_trapcreatetime, get_gametime())

	switch (iTrapType)
	{
		case TRAP_BIND:
		{
			set_entvar(iAcidtrapEnt, var_trapholdtime, ACIDTRAP_FREEZE_TIME)
		}
		case TRAP_ACTIVE:
		{
			new Float:fExplosionDelay = ACIDTRAP_EXPLOSION_DELAY + iSelectedTrapsNum * 0.1
			set_entvar(iAcidtrapEnt, var_trapholdtime, fExplosionDelay)
			set_entvar(iAcidtrapEnt, var_trapdamage, ACIDTRAP_BASE_DAMAGE)
		}
		case TRAP_TACTICAL:
		{
			set_entvar(iAcidtrapEnt, var_trapholdtime, ACIDTRAP_EXPLOSION_DELAY)
			set_entvar(iAcidtrapEnt, var_trapdamage, ACIDTRAP_BASE_DAMAGE)
		}
	}

	SetThink(iAcidtrapEnt, "acidtrap_think")
	SetTouch(iAcidtrapEnt, "acidtrap_touch")
	SetUse(iAcidtrapEnt, "acidtrap_use")

	return iAcidtrapEnt
}

public acidtrap_think(iAcidtrapEnt)
{
	new iBeamEnt = NULLENT
	while ((iBeamEnt = rg_find_ent_by_class(iBeamEnt, SZ_BEAM)))
		if (get_entvar(iBeamEnt, var_owner) == iAcidtrapEnt)
			rg_remove_entity(iBeamEnt)

	new AcidTrapType:iTrapType = get_entvar(iAcidtrapEnt, var_traptype)

	if (iTrapType == TRAP_BIND)
	{
		engfunc(EngFunc_EmitSound, iAcidtrapEnt, CHAN_STATIC, SOUND_TRAP_UNBIND, 1.0, ATTN_NORM, 0, PITCH_NORM)
		rg_remove_entity(iAcidtrapEnt)
		return
	}

	new Float:vOrigin[3], Float:fGameTime
	get_entvar(iAcidtrapEnt, var_origin, vOrigin)
	fGameTime = get_gametime()

	static Float:fLastEffTime, iEffNum

	if (fLastEffTime != fGameTime)
	{
		fLastEffTime = fGameTime
		iEffNum = 0
	}
	else
		iEffNum++

	if (iEffNum < 3)
	{
		new Float:vSprOrigin[3]
		vSprOrigin[0] = vOrigin[0]
		vSprOrigin[1] = vOrigin[1]
		vSprOrigin[2] = vOrigin[2] + 50.0
		send_msg_TE_SPRITE(vSprOrigin, g_pPoisonModel, 8, 200)

		send_msg_TE_DLIGHT(vOrigin, 40, COLOR_ACID, 8, 60)

		draw_acid_particles(vOrigin)
	}

	engfunc(EngFunc_EmitSound, iAcidtrapEnt, CHAN_STATIC, SOUND_TRAP_EXPLOSION, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new Float:fDamage = get_entvar(iAcidtrapEnt, var_trapdamage)
	new iOwner = get_entvar(iAcidtrapEnt, var_owner)

	new iTarget = NULLENT
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, ACIDTRAP_EXPLODE_RADIUS)))
	{
		if (is_entity_player(iTarget))
		{
			if (Player[iTarget][PlrIsAlive]
				&& Player[iTarget][PlrTeam] != Player[iOwner][PlrTeam]
				&& !kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
			{
				kc_player_set_death_reason(iTarget, "DEATH_REASON_ACID")
				set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iTarget, iOwner, iOwner, fDamage, DMG_ACID)

				if (Player[iTarget][PlrIsAlive] && kc_player_get_vision(iTarget) != VISION_BLIND && !kc_player_in_freeze(iTarget) && !kc_player_in_chill(iTarget))
				{
					send_msg_ScreenFade((1<<12), (1<<8), (1<<4), COLOR_ACID, 20, MSG_ONE, _, iTarget)
				}
			}
		}
		else
		{
			if ((get_entvar(iTarget, var_flags) & FL_MONSTER) && get_entvar(iTarget, var_skin) + 1 != Player[iOwner][PlrTeam])
				ExecuteHamB(Ham_TakeDamage, iTarget, iOwner, iOwner, fDamage, DMG_ACID)
		}
	}

	rg_remove_entity(iAcidtrapEnt)
}

public acidtrap_touch(iAcidtrapEnt, iOther)
{
	if (iOther && !is_entity(iOther))
		return HC_CONTINUE

	new iTeam = get_entvar(iAcidtrapEnt, var_skin) + 1
	new AcidTrapType:iTrapType = get_entvar(iAcidtrapEnt, var_traptype)

	if (iTrapType == TRAP_TACTICAL)
		return HC_CONTINUE

	if (is_entity_player(iOther))
	{
		if (Player[iOther][PlrIsAlive] && !kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY)
			&& Player[iOther][PlrTeam] != iTeam
			&& kc_player_get_visibility(iOther) < VIS_INVISION)
		{
			acidtrap_activate(iAcidtrapEnt)
		}

		return HC_CONTINUE
	}

	if (iOther && get_entvar(iOther, var_flags) & FL_MONSTER)
	{
		if (get_entvar(iOther, var_skin) + 1 != iTeam)
			acidtrap_activate(iAcidtrapEnt)

		return HC_CONTINUE
	}

	if (!iOther || get_entvar(iOther, var_solid) >= SOLID_BBOX)
	{
		if (get_entvar(iAcidtrapEnt, var_trapstate) == TRAPSTATE_FREE)
		{
			engfunc(EngFunc_SetSize, iAcidtrapEnt, Float:{-40.0, -40.0, 0.0}, Float:{40.0, 40.0, 23.0})
			set_entvar(iAcidtrapEnt, var_velocity, NULL_VECTOR)
			set_entvar(iAcidtrapEnt, var_trapstate, TRAPSTATE_FIXED)

			new Float:vOrigin[3], Float:vAxis[3]
			get_entvar(iAcidtrapEnt, var_origin, vOrigin)
			vAxis[0] = vOrigin[0]
			vAxis[1] = vOrigin[1]
			vAxis[2] = vOrigin[2] + 200.0

			for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			{
				if (Player[iPlayer][PlrTeam] == iTeam)
				{
					send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, g_pBeamModel, 0, 0, 1, 10, 0, COLOR_ACID, 100, 0,
						MSG_ONE_UNRELIABLE, _, iPlayer)
				}
			}
		}
	}

	return HC_CONTINUE
}

public acidtrap_use(iAcidtrapEnt, iActivator, iCaller, USE_TYPE:iUseType, Float:fValue)
{
	acidtrap_activate(iAcidtrapEnt)
}

acidtrap_activate(iAcidtrapEnt)
{
	if (get_entvar(iAcidtrapEnt, var_trapstate) == TRAPSTATE_ACTIVE)
		return

	new Float:fGameTime = get_gametime()
	new iTeam = get_entvar(iAcidtrapEnt, var_skin) + 1
	new AcidTrapType:iTrapType = get_entvar(iAcidtrapEnt, var_traptype)
	new Float:fTimeExplosion = get_entvar(iAcidtrapEnt, var_trapholdtime)

	switch (iTrapType)
	{
		case TRAP_BIND:
		{
			new Float:vOrigin[3]
			get_entvar(iAcidtrapEnt, var_origin, vOrigin)

			new Float:fFreezeTime = get_entvar(iAcidtrapEnt, var_trapholdtime)

			new iTarget = NULLENT
			while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, ACIDTRAP_CATCH_RADIUS)))
			{
				if (is_entity_player(iTarget))
				{
					if (!Player[iTarget][PlrIsAlive]
						|| Player[iTarget][PlrTeam] == iTeam
						|| kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY)
						|| kc_player_get_visibility(iTarget) >= VIS_INVISION)
					{
						continue
					}

					kc_player_slow(iTarget, 0.1, fFreezeTime + ACIDTRAP_ADDTIME_FREEZE)
					kc_player_add_glow(iTarget, fFreezeTime + ACIDTRAP_ADDTIME_FREEZE,
						ACID_COLOR_R, ACID_COLOR_G, ACID_COLOR_B)

					acidtrap_create_beam(iAcidtrapEnt, iTarget)
				}
				else if (get_entvar(iTarget, var_flags) & FL_MONSTER)
				{
					if (get_entvar(iTarget, var_skin) + 1 == iTeam)
						continue

					new Float:vVelocity[3]
					get_entvar(iTarget, var_velocity, vVelocity)
					vVelocity[2] = 0.0

					set_entvar(iTarget, var_velocity, vVelocity)
					set_entvar(iTarget, var_nextthink, fGameTime + fFreezeTime)

					acidtrap_create_beam(iAcidtrapEnt, iTarget)
				}
			}

			set_entvar(iAcidtrapEnt, var_body, 3)
		}
		case TRAP_ACTIVE:
		{
			set_entvar(iAcidtrapEnt, var_body, 7)
		}
	}

	set_entvar(iAcidtrapEnt, var_nextthink, fGameTime + fTimeExplosion)
	set_entvar(iAcidtrapEnt, var_solid, SOLID_NOT)
	set_entvar(iAcidtrapEnt, var_rendermode, kRenderNormal)
	set_entvar(iAcidtrapEnt, var_framerate, 1.0)
	set_entvar(iAcidtrapEnt, var_animtime, fGameTime)
	set_entvar(iAcidtrapEnt, var_trapstate, TRAPSTATE_ACTIVE)

	engfunc(EngFunc_EmitSound, iAcidtrapEnt, CHAN_STATIC, SOUND_TRAP_ACTIVATE, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

acidtrap_detonate(iAcidtrapEnt)
{
	set_entvar(iAcidtrapEnt, var_nextthink, get_gametime())
}

acidtrap_create_beam(iAcidtrapEnt, iTarget)
{
	new iBeamEnt = Beam_Create(MODEL_BEAM, 10.0)
	if (!is_nullent(iBeamEnt))
	{
		Beam_EntsInit(iBeamEnt, iAcidtrapEnt, iTarget)
		Beam_SetColor(iBeamEnt, Float:{ACID_COLOR_R.0, ACID_COLOR_G.0, ACID_COLOR_B.0})
		set_entvar(iBeamEnt, var_owner, iAcidtrapEnt)
		set_entvar(iBeamEnt, var_impulse, IMPULSE_ACIDTRAP_BEAM)
	}
}

remove_acidtraps(const iOwner=0)
{
	new iBeamEnt, iAcidtrapEnt = NULLENT
	while ((iAcidtrapEnt = rg_find_ent_by_class(iAcidtrapEnt, CLASSNAME_ACIDTRAP_)))
	{
		if (iOwner && get_entvar(iAcidtrapEnt, var_owner) != iOwner)
			continue

		iBeamEnt = NULLENT
		while ((iBeamEnt = rg_find_ent_by_class(iBeamEnt, SZ_BEAM)))
			if (get_entvar(iBeamEnt, var_owner) == iAcidtrapEnt)
				rg_remove_entity(iBeamEnt)
		rg_remove_entity(iAcidtrapEnt)
	}
}

bool:is_entity_tactical_fixed_acidtrap(iEnt)
{
	if (get_entvar(iEnt, var_impulse) != IMPULSE_ACIDTRAP)
		return false

	if (get_entvar(iEnt, var_traptype) != TRAP_TACTICAL)
		return false

	new AcidTrapState:iTrapState = get_entvar(iEnt, var_trapstate)
	if (iTrapState == TRAPSTATE_FREE)
	{
		if (Float:get_entvar(iEnt, var_trapcreatetime) + ACIDTRAP_TACTICAL_DELAY < get_gametime())
		{
			iTrapState = TRAPSTATE_FIXED
			set_entvar(iEnt, var_trapstate, iTrapState)
		}
	}

	return iTrapState == TRAPSTATE_FIXED
}

public acidball_think(iAcidballEnt)
{
	if (is_nullent(iAcidballEnt))
		return HC_CONTINUE

	if (get_entvar(iAcidballEnt, var_solid) == SOLID_NOT)
	{
		acidcloud_create(iAcidballEnt)
		return HC_CONTINUE
	}

	new Float:vVelocity[3]
	get_entvar(iAcidballEnt, var_velocity, vVelocity)

	if (vVelocity[2] == 0.0)
	{
		acidball_touch(iAcidballEnt, 0)
		return HC_CONTINUE
	}

	engfunc(EngFunc_SetSize, iAcidballEnt, Float:{-16.0, -16.0, -16.0}, Float:{16.0, 16.0, 16.0})
	set_entvar(iAcidballEnt, var_nextthink, get_gametime() + 0.75)

	return HC_CONTINUE
}

public acidball_touch(iAcidballEnt, iOther)
{
	if (iOther > 0)
	{
		new iOwner = get_entvar(iAcidballEnt, var_owner)

		if (iOther <= MaxClients)
		{
			if (!Player[iOther][PlrIsAlive] || Player[iOther][PlrTeam] == Player[iOwner][PlrTeam] || kc_player_get_visibility(iOther) >= VIS_CLONE)
				return HC_CONTINUE

			new Float:vOrigin[3]
			get_entvar(iAcidballEnt, var_origin, vOrigin)

			new Float:vSprOrigin[3]
			vSprOrigin[0] = vOrigin[0]
			vSprOrigin[1] = vOrigin[1]
			vSprOrigin[2] = vOrigin[2] + 50.0
			send_msg_TE_SPRITE(vSprOrigin, g_pPoisonModel, 8, 200)

			draw_acid_particles(vOrigin)

			if (!kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY))
			{
				new Float:fDamage = random_float(15.0, 25.0)

				kc_player_set_death_reason(iOther, "DEATH_REASON_ACID")
				set_member(iOther, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iOther, iOwner, iOwner, fDamage, DMG_ACID)

				if (Player[iOther][PlrIsAlive])
				{
					kc_player_add_glow(iOther, 1.0, ACID_COLOR_R, ACID_COLOR_G, ACID_COLOR_B)
					if (kc_player_get_vision(iOther) != VISION_BLIND && !kc_player_in_freeze(iOther) && !kc_player_in_chill(iOther))
					{
						send_msg_ScreenFade((1<<12), (1<<8), (1<<4), COLOR_ACID, 20, MSG_ONE, _, iOther)
					}
				}
			}

			rg_remove_entity(iAcidballEnt)
			return HC_CONTINUE
		}

		if ((get_entvar(iOther, var_flags) & FL_MONSTER) && get_entvar(iOther, var_skin) + 1 != Player[iOwner][PlrTeam])
		{
			new Float:vOrigin[3]
			get_entvar(iAcidballEnt, var_origin, vOrigin)

			new Float:vSprOrigin[3]
			vSprOrigin[0] = vOrigin[0]
			vSprOrigin[1] = vOrigin[1]
			vSprOrigin[2] = vOrigin[2] + 50.0
			send_msg_TE_SPRITE(vSprOrigin, g_pPoisonModel, 8, 200)

			draw_acid_particles(vOrigin)

			ExecuteHamB(Ham_TakeDamage, iOther, iOwner, iOwner, random_float(15.0, 25.0), DMG_ACID)

			rg_remove_entity(iAcidballEnt)
			return HC_CONTINUE
		}
	}

	new Float:vOrigin[3]
	get_entvar(iAcidballEnt, var_origin, vOrigin)

	new Float:vLastOrigin[3]
	get_entvar(iAcidballEnt, var_vuser1, vLastOrigin)
	set_entvar(iAcidballEnt, var_vuser1, vOrigin)

	new Float:vTemp[3]
	xs_vec_sub(vOrigin, vLastOrigin, vTemp)
	xs_vec_normalize(vTemp, vTemp)
	xs_vec_mul_scalar(vTemp, 60.0, vTemp)

	new Float:vEnd[3]
	xs_vec_add(vOrigin, vTemp, vEnd)

	new pTrace = create_tr2()
	engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, iAcidballEnt, pTrace)

	new Float:fFraction, iHit
	get_tr2(pTrace, TR_flFraction, fFraction)
	iHit = get_tr2(pTrace, TR_pHit)

	if (fFraction < 1.0)
	{
		new szTextureName[4]
		engfunc(EngFunc_TraceTexture, 0, vOrigin, vEnd, szTextureName, charsmax(szTextureName))
		if (equal(szTextureName, "sky"))
			fFraction = 1.0
	}
	else
	{
		free_tr2(pTrace)
		pTrace = create_tr2()

		vEnd[0] = vOrigin[0]
		vEnd[1] = vOrigin[1]
		vEnd[2] = vOrigin[2] - 32.0

		engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, iAcidballEnt, pTrace)
		get_tr2(pTrace, TR_flFraction, fFraction)
		iHit = get_tr2(pTrace, TR_pHit)
	}

	if (fFraction < 1.0 && (iHit <= 0 || get_entvar(iHit, var_solid) != SOLID_SLIDEBOX))
	{
		get_tr2(pTrace, TR_vecEndPos, vEnd)

		new Float:vNormal[3], Float:vAngles[3], Float:fGameTime
		get_tr2(pTrace, TR_vecPlaneNormal, vNormal)
		fGameTime = get_gametime()

		set_entvar(iAcidballEnt, var_vuser1, vNormal)
		xs_vec_add(vEnd, vNormal, vEnd)

		vector_to_angle(vNormal, vAngles)
		vAngles[0] -= 90.0
		if (vAngles[0] <= -180.0)
			vAngles[0] += 360.0

		engfunc(EngFunc_SetModel, iAcidballEnt, MODEL_ACID_WALL)
		engfunc(EngFunc_SetOrigin, iAcidballEnt, vEnd)

		set_entvar(iAcidballEnt, var_origin, vEnd)
		set_entvar(iAcidballEnt, var_classname, CLASSNAME_ACIDP_)
		set_entvar(iAcidballEnt, var_impulse, IMPULSE_ACIDP)

		set_entvar(iAcidballEnt, var_angles, vAngles)
		set_entvar(iAcidballEnt, var_solid, SOLID_TRIGGER)
		set_entvar(iAcidballEnt, var_movetype, MOVETYPE_NONE)
		set_entvar(iAcidballEnt, var_nextthink, fGameTime + 0.1)

		set_entvar(iAcidballEnt, var_animtime, fGameTime)
		set_entvar(iAcidballEnt, var_frame, 0.0)
		set_entvar(iAcidballEnt, var_framerate, 1.0)
		set_entvar(iAcidballEnt, var_sequence, 0)

		new Float:vMin[3], Float:vMax[3]

		if (floatabs(vNormal[2]) == 1.0)
		{
			vMin[0] = -32.0
			vMax[0] = 32.0

			vMin[1] = -32.0
			vMax[1] = 32.0

			if (vNormal[2] > 0.0)
			{
				vMin[2] = 0.0
				vMax[2] = 4.0
			}
			else
			{
				vMin[2] = -4.0
				vMax[2] = 0.0
			}
		}
		else
		{
			new Float:vCenterAcid[3]
			xs_vec_mul_scalar(vNormal, 24.0, vCenterAcid)

			vMin[0] = vCenterAcid[0] - 24.0
			vMin[1] = vCenterAcid[1] - 24.0
			vMin[2] = vCenterAcid[2] - 24.0

			vMax[0] = vCenterAcid[0] + 24.0
			vMax[1] = vCenterAcid[1] + 24.0
			vMax[2] = vCenterAcid[2] + 24.0
		}

		engfunc(EngFunc_SetSize, iAcidballEnt, vMin, vMax)

		SetThink(iAcidballEnt, "acidpool_think")
		SetTouch(iAcidballEnt, "acidcloud_touch")
	}
	else
	{
		acidcloud_create(iAcidballEnt)
	}

	free_tr2(pTrace)

	return HC_CONTINUE
}

acidcloud_create(iAcidballEnt = 0, Float:vOrigin[3] = NULL_VECTOR)
{
	if (!iAcidballEnt)
	{
		iAcidballEnt = rg_create_entity(SZ_EXPLOSION)
		if (is_nullent(iAcidballEnt))
			return NULLENT

		engfunc(EngFunc_SetOrigin, iAcidballEnt, vOrigin)

		set_entvar(iAcidballEnt, var_origin, vOrigin)
		set_entvar(iAcidballEnt, var_solid, SOLID_TRIGGER)
		set_entvar(iAcidballEnt, var_takedamage, DAMAGE_NO)
		set_entvar(iAcidballEnt, var_rendermode, kRenderNormal)
	}

	engfunc(EngFunc_SetModel, iAcidballEnt, "")
	engfunc(EngFunc_SetSize, iAcidballEnt, Float:{-32.0, -32.0, -32.0}, Float:{32.0, 32.0, 32.0})

	set_entvar(iAcidballEnt, var_classname, CLASSNAME_ACIDG_)
	set_entvar(iAcidballEnt, var_impulse, IMPULSE_ACIDG)
	set_entvar(iAcidballEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iAcidballEnt, var_movetype, MOVETYPE_NONE)
	set_entvar(iAcidballEnt, var_nextthink, get_gametime() + 0.1)

	SetThink(iAcidballEnt, "acidcloud_think")
	SetTouch(iAcidballEnt, "acidcloud_touch")

	return iAcidballEnt
}

public acidcloud_think(iAcidcloudEnt)
{
	if (is_nullent(iAcidcloudEnt))
		return HC_CONTINUE

	new iUser1, Float:vOrigin[3]
	iUser1 = get_entvar(iAcidcloudEnt, var_iuser1)
	get_entvar(iAcidcloudEnt, var_origin, vOrigin)

	send_msg_TE_FIREFIELD(vOrigin, 65, g_pCloudModel, 15, TEFIRE_FLAG_ALPHA, 25)
	send_msg_TE_FIREFIELD(vOrigin, 45, g_pCloudModel, 10, TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT, 35)

	if (iUser1 > CLOUD_TIMESTODIE)
	{
		rg_remove_entity(iAcidcloudEnt)
		return HC_CONTINUE
	}

	set_entvar(iAcidcloudEnt, var_iuser1, iUser1 + 1)
	set_entvar(iAcidcloudEnt, var_nextthink, get_gametime() + CLOUD_UPDATERATE)

	return HC_CONTINUE
}

public acidcloud_touch(iAcidcloudEnt, iOther)
{
	if (!iOther)
		return HC_CONTINUE

	new iOwner = get_entvar(iAcidcloudEnt, var_owner)

	if (iOther <= MaxClients)
	{
		if (!Player[iOther][PlrIsAlive] || Player[iOther][PlrTeam] == Player[iOwner][PlrTeam] ||
			kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY))
		{
			return HC_CONTINUE
		}

		static Float:fDamageDelay[MAX_PLAYERS + 1]
		new Float:fGameTime = get_gametime()

		if (fDamageDelay[iOther] > fGameTime)
			return HC_CONTINUE

		kc_player_set_death_reason(iOther, "DEATH_REASON_ACID")
		set_member(iOther, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iOther, iOwner, iOwner, 5.0, DMG_ACID)

		fDamageDelay[iOther] = fGameTime + 0.5
	}
	else if ((get_entvar(iOther, var_flags) & FL_MONSTER) && get_entvar(iOther, var_skin) + 1 != Player[iOwner][PlrTeam])
	{
		static Float:fOtherDamageDelay[MAX_PLAYERS + 1]
		new Float:fGameTime = get_gametime()

		if (fOtherDamageDelay[iOwner] > fGameTime)
			return HC_CONTINUE

		ExecuteHamB(Ham_TakeDamage, iOther, iOwner, iOwner, 5.0, DMG_ACID)

		fOtherDamageDelay[iOwner] = fGameTime + 0.5
	}

	return HC_CONTINUE
}

public acidpool_think(iAcidpoolEnt)
{
	if (is_nullent(iAcidpoolEnt))
		return HC_CONTINUE

	new iUser1 = get_entvar(iAcidpoolEnt, var_iuser1)
	new Float:vOrigin[3], Float:vNormal[3], Float:vSprOrigin[3]

	get_entvar(iAcidpoolEnt, var_origin, vOrigin)
	get_entvar(iAcidpoolEnt, var_vuser1, vNormal)

	vSprOrigin[0] = vOrigin[0] + vNormal[0] * 24.0
	vSprOrigin[1] = vOrigin[1] + vNormal[1] * 24.0
	vSprOrigin[2] = vOrigin[2] + vNormal[2] * 24.0

	send_msg_TE_SPRITE(vSprOrigin, g_pSmokeModels[random(sizeof g_pSmokeModels)], random_num(18, 24), 125)

	if (iUser1 > POISON_TIMESTODIE)
	{
		rg_remove_entity(iAcidpoolEnt)
		return HC_CONTINUE
	}

	set_entvar(iAcidpoolEnt, var_iuser1, iUser1 + 1)
	set_entvar(iAcidpoolEnt, var_nextthink, get_gametime() + POISON_UPDATERATE)

	return HC_CONTINUE
}

create_acid_beam(iPlayer, Float:vStart[3], Float:vEnd[3], iLife, iWidth)
{
	send_msg_TE_BEAMPOINTS(vStart, vEnd, sprStream, 0, 1, iLife, iWidth, 0,
		COLOR_ACID, 255, 0, MSG_ONE_UNRELIABLE, _, iPlayer)
}

projectile_startpos(const Float:vStart[3], const Float:vOfs[3], Float:vSrc[3])
{
	static Float:vForward[3], Float:vRight[3], Float:vUp[3]

	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)

	xs_vec_mul_scalar(vForward, vOfs[0], vForward)
	xs_vec_mul_scalar(vRight, vOfs[1], vRight)
	xs_vec_mul_scalar(vUp, vOfs[2], vUp)

	xs_vec_add(vStart, vForward, vSrc)
	xs_vec_add(vStart, vRight, vSrc)
	xs_vec_add(vStart, vUp, vSrc)
}

draw_acid_particles(Float:vOrigin[3])
{
	new Float:vEndOrigin[3]
	vEndOrigin[0] = vOrigin[0]
	vEndOrigin[1] = vOrigin[1]
	vEndOrigin[2] = vOrigin[2] + 50.0

	new aPlayers[MAX_PLAYERS], iPlayerNum
	get_players(aPlayers, iPlayerNum, "c")

	for (new i, iPlayer; i < iPlayerNum; i++)
	{
		iPlayer = aPlayers[i]
		if (kc_player_get_options(iPlayer) & OPTION_DISABLE_PARTICLES)
			continue

		send_msg_TE_SPRITETRAIL(vOrigin, vEndOrigin, g_pPoisonParticlesModel, 25, 1, 4, 28, 20,
			MSG_ONE_UNRELIABLE, _, iPlayer)
	}
}

switch_trap_type(iPlayer)
{
	new iTrapType = _:Player[iPlayer][PlrTrapType]
	iTrapType = (iTrapType + 1) % _:AcidTrapType

	client_print(iPlayer, print_center, "Trap: %s", TRAP_TYPE_NAMES[iTrapType])
	Player[iPlayer][PlrTrapType] = AcidTrapType:iTrapType
}
