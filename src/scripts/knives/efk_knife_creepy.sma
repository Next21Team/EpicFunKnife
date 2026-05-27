#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <beams>
#include <xs>
#include <efk_core>
#include <efk_utils>
#include <object/efk_web_utils>

new const PLUGIN[] = "EFK: Creepy Knife"

#define KNIFE_CLASSNAME "weapon_next21_creepy"
#define KNIFE_MENUDESC  "KNIFE_CREEPY_DESC"
#define KNIFE_CHATDESC  "KNIFE_CREEPY_CHAT"

#define ABIL1_NAME				"Creepy"
#define ABIL1_CHARGE			8.0

#define ABIL2_NAME				"Iron Maiden"
#define ABIL2_CHARGE			7.5

#define ABIL3_NAME				"Transghost"
#define ABIL3_CHARGE			8.334

new const COFFIN_CLASSNAME[] = "next21_coffin"
new const GHOST_CAMERA_CLASSNAME[] = "next21_camera_ghost"

#define WEB_ACUM_SPEED			15000.0
#define WEB_LIFETIME			8.0
#define WEB_STUNEDTIME			5.0

#define COFFIN_DELAY						0.25
#define COFFIN_DAMAGE						5.0
#define COFFIN_DAMAGE_DELAY					1.0
#define COFFIN_DAMAGE_START					18.0
#define COFFIN_ACTIVATE_TAKEHEALTH_DELAY	1.0

#define GHOST_TIME				40.0
#define GHOST_SPEED				255.0
#define GHOST_SLOW_SPEED		120.0
#define GHOST_DAMAGE1 			60.0
#define GHOST_DAMAGE2 			70.0
#define GHOST_ATTACK_DISTANCE 	80.0
#define GHOST_HEIGHT_RANGE 		30.0
#define GHOST_TRANSPARENT		200.0

#define GHOST_CAMERA_ROTCOF		0.5
#define GHOST_CAMERA_DISTANCE	130.0
#define GHOST_CAMERA_UP			20.0

#define UNGHOST_SLOWTIME		0.125
#define UNGHOST_SLOWPOWER		0.5

#define DAMAGE_CHARGE_MUL		0.25
#define MAX_DAMAGE_CHARGE		30.0

new const MODEL_WEB[] = "models/next21_efk/spider_web.mdl"
new const MODEL_COFFIN[] = "models/next21_efk/iron_maiden.mdl"
new const MODEL_GHOST[] = "models/next21_efk/ghost_v2_a02.mdl"

new const MODEL_V_KNIFE[] = "models/next21_efk/v_creepy_knife_b02.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_creepy_knife_r2.mdl"

new const SPRITE_GHOST_BEAM[] = "sprites/next21_efk/razorbeam.spr"

new const SOUND_KNIFE_HIT1[] = "next21_efk/creepy_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[] = "next21_efk/creepy_knife_hit2.wav"
new const SOUND_KNIFE_STAB[] = "next21_efk/creepy_knife_stab.wav"
new const SOUND_KNIFE_HITWALL[] = "next21_efk/creepy_knife_hitwall1.wav"
new const SOUND_KNIFE_SLASH1[] = "next21_efk/creepy_knife_slash1.wav"
new const SOUND_KNIFE_SLASH2[] = "next21_efk/creepy_knife_slash1.wav"
new const SOUND_KNIFE_DEPLOY[] = "next21_efk/creepy_knife_deploy.wav"

new const SOUND_IRON_MAIDEN[] = "next21_efk/iron_maiden.wav"
new const SOUND_SHADOWJUMP[] = "next21_efk/shadow_jump.wav"

new const SOUND_GHOST_ATTACK1[] = "next21_efk/ghost_attack1.wav"
new const SOUND_GHOST_ATTACK2[] = "next21_efk/ghost_attack2.wav"
new const SOUND_GHOST_HIT1[] = "next21_efk/ghost_hit1.wav"
new const SOUND_GHOST_HIT2[] = "next21_efk/ghost_hit2.wav"
new const SOUND_GHOST_SPAWN[] = "next21_efk/ghost_spawn.wav"

new const SOUNDS_FIELD_BREAK[][] = { "next21_efk/field_break1.wav", "next21_efk/field_break2.wav" }

#define HP						95.0
#define GRAVITY					1.0
#define SPEED					255.0
#define MINDAMAGE				0.0
#define MAXDAMAGE				0.0

#define KNIFE_LEVEL     		1

#define LONGJUMP_FORCE			470.0
#define LONGJUMP_HEIGHT			275.0

#define MAX_REBOUND_FORCE		600.0

#define is_user_has_knife(%0)	(g_ePlayerData[%0][CUR_KNIFE] == g_iKnifeId)

#define TASK_DAMAGE				64
#define TASK_WEB_STUNNED		128

new const SZ_INFO_TARGET[]		= "info_target"

#define var_target_camera		var_iuser2
#define var_target_beam			var_iuser3

enum _:GHOST_STATES
{
	GHOST_ST_ACTIVE,
	GHOST_ST_SPAWN,
	GHOST_ST_ATTACK,
	GHOST_ST_DEATH
}

enum _:GhostSeq
{
	GHOST_SEQ_IDLE,
	GHOST_SEQ_SPAWN,
	GHOST_SEQ_WALK,
	GHOST_SEQ_RUN,
	GHOST_SEQ_BACK,
	GHOST_SEQ_ATTACK1,
	GHOST_SEQ_ATTACK2,
	GHOST_SEQ_DEATH
}

enum _:PlayerData
{
	CUR_KNIFE,
	bool:IS_ALIVE,
	Float:COFFIN_LASTUSE,
	bool:IN_COFFIN,
	Float:LAST_WEB_TOUCH,
	Float:LAST_WEB_TEAM_TOUCH,
	Float:POWER_WEB,
	STUNED_WEB,
	GHOST_ENT,
	GHOST_STATE,
	Float:GHOST_FIRST_ORIGIN[3],
	Float:GHOST_FIRST_ANGLES[3],
	Float:GHOST_SPAWN_TIME,
	Float:LAST_TAKEHEALTH_TIME,
	CURRENT_COMBO_BUTTON,
	POST_REGENERATION_HP
}

new
	g_ePlayerData[MAX_PLAYERS + 1][PlayerData],
	Float:g_vPlayerOrigin[MAX_PLAYERS + 1][3], g_iKnifeId,
	g_iPlayerCoffin[MAX_PLAYERS + 1], g_pKnifePMdl

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(MODEL_WEB)
	precache_model(MODEL_COFFIN)
	precache_model(MODEL_GHOST)

	precache_model(SPRITE_GHOST_BEAM)

	engfunc(EngFunc_PrecacheSound, SOUND_KNIFE_DEPLOY)
	engfunc(EngFunc_PrecacheSound, SOUND_KNIFE_HIT1)
	engfunc(EngFunc_PrecacheSound, SOUND_KNIFE_HIT2)
	engfunc(EngFunc_PrecacheSound, SOUND_KNIFE_HITWALL)
	engfunc(EngFunc_PrecacheSound, SOUND_KNIFE_SLASH1)
	engfunc(EngFunc_PrecacheSound, SOUND_KNIFE_SLASH2)
	engfunc(EngFunc_PrecacheSound, SOUND_KNIFE_STAB)

	engfunc(EngFunc_PrecacheGeneric, "sprites/weapon_next21_creepy.txt")

	engfunc(EngFunc_PrecacheSound, SOUND_IRON_MAIDEN)
	engfunc(EngFunc_PrecacheSound, SOUND_SHADOWJUMP)

	engfunc(EngFunc_PrecacheSound, SOUND_GHOST_ATTACK1)
	engfunc(EngFunc_PrecacheSound, SOUND_GHOST_ATTACK2)
	engfunc(EngFunc_PrecacheSound, SOUND_GHOST_HIT1)
	engfunc(EngFunc_PrecacheSound, SOUND_GHOST_HIT2)
	engfunc(EngFunc_PrecacheSound, SOUND_GHOST_SPAWN)

	for (new i; i < sizeof SOUNDS_FIELD_BREAK; i++)
		engfunc(EngFunc_PrecacheSound, SOUNDS_FIELD_BREAK[i])
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

	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_DUAL_KNIVES)
	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLABLE)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Ham_Knife_PrimaryAttack_Post", true)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "Ham_Knife_SecondaryAttack_Post", true)
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", true)
	RegisterHam(Ham_Player_ImpulseCommands, "player", "Ham_Player_ImpulseCommands_Pre", false)
	RegisterHam(Ham_Player_PreThink, "player", "Ham_Player_PreThink_Pre")
	RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Pre", false)
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage_Pre", false)
	RegisterHam(Ham_TakeHealth, "player", "fw_PlayerTakeHealth_Pre", false)

	register_forward(FM_EmitSound, "fw_EmitSound")
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (g_ePlayerData[iSubject][GHOST_ENT] && g_ePlayerData[iSubject][GHOST_STATE] != GHOST_ST_SPAWN)
	{
		set_hudmessage(255, 255, 255, -1.0, -0.30, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "%L", iPlayer, "GHOST_TIMER",
			g_ePlayerData[iSubject][GHOST_SPAWN_TIME] + GHOST_TIME - get_gametime())
	}

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	g_ePlayerData[iPlayer][CUR_KNIFE] = iKnifeId
	g_ePlayerData[iPlayer][POST_REGENERATION_HP] = 0

	if (g_ePlayerData[iPlayer][IN_COFFIN] || g_ePlayerData[iPlayer][GHOST_ENT])
		kc_player_set_capture(iPlayer, CAPTURE_NONE)
}

public efk_ability(iPlayer)
{
	new Float:vPlayerOrigin[3], Float:vWebOrigin[3]
	get_entvar(iPlayer, var_origin, vPlayerOrigin)

	vWebOrigin = Float:{0.0, 0.0, -8192.0}
	xs_vec_add(vPlayerOrigin, vWebOrigin, vWebOrigin)

	engfunc(EngFunc_TraceLine, vPlayerOrigin, vWebOrigin, IGNORE_MONSTERS, iPlayer, 0)
	get_tr2(0, TR_vecEndPos, vWebOrigin)
	vWebOrigin[2] += WEB_OFFSET

	new Float:vNormal[3]
	get_tr2(0, TR_vecPlaneNormal, vNormal)

	web_create(vWebOrigin, vNormal, iPlayer)
}

public efk_ability2(iPlayer)
{
	if (!g_ePlayerData[iPlayer][IN_COFFIN])
	{
		if (g_ePlayerData[iPlayer][LAST_TAKEHEALTH_TIME] + COFFIN_ACTIVATE_TAKEHEALTH_DELAY > get_gametime())
			return PLUGIN_HANDLED

		return coffin_set_status(iPlayer, true)
	}

	return PLUGIN_HANDLED
}

public efk_ability3(iPlayer)
{
	if (kc_player_in_burn(iPlayer))
		return PLUGIN_HANDLED

	if (!kc_player_set_capture(iPlayer, CAPTURE_WEAK, CAP_ANIM_GHOST_RELEASE, GHOST_TIME))
		return PLUGIN_HANDLED

	kc_player_add_glow(iPlayer, 9999.0, 255, 1, 1)

	new Float:vOrigin[3], Float:vAngles[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_v_angle, vAngles)

	vOrigin[2] += 80.0
	vAngles[0] = 0.0
	vAngles[2] = 0.0

	new Float:vCameraOrigin[3]
	xs_vec_copy(vOrigin, vCameraOrigin)

	new iContents = engfunc(EngFunc_PointContents, vCameraOrigin)
	if (iContents != CONTENTS_EMPTY && iContents != CONTENTS_WATER)
	{
		kc_player_set_capture(iPlayer, CAPTURE_NONE)
		kc_player_sub_glow(iPlayer, 255, 1, 1)
		return PLUGIN_HANDLED
	}

	xs_vec_copy(vOrigin, g_ePlayerData[iPlayer][GHOST_FIRST_ORIGIN])
	xs_vec_copy(vAngles, g_ePlayerData[iPlayer][GHOST_FIRST_ANGLES])

	new iGhostEnt = NULLENT
	while ((iGhostEnt = rg_find_ent_by_class(iGhostEnt, CLASSNAME_GHOST)))
		if (get_entvar(iGhostEnt, var_owner) == iPlayer)
			rg_remove_entity(iGhostEnt)

	iGhostEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iGhostEnt))
	{
		kc_player_set_capture(iPlayer, CAPTURE_NONE)
		kc_player_sub_glow(iPlayer, 255, 1, 1)
		return PLUGIN_HANDLED
	}

	new iCameraEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iCameraEnt))
	{
		rg_remove_entity(iGhostEnt)
		kc_player_set_capture(iPlayer, CAPTURE_NONE)
		kc_player_sub_glow(iPlayer, 255, 1, 1)
		return PLUGIN_HANDLED
	}

	new iBeam = Beam_Create(SPRITE_GHOST_BEAM, 10.0)
	if (is_nullent(iBeam))
	{
		rg_remove_entity(iGhostEnt)
		rg_remove_entity(iCameraEnt)
		kc_player_set_capture(iPlayer, CAPTURE_NONE)
		kc_player_sub_glow(iPlayer, 255, 1, 1)
		return PLUGIN_HANDLED
	}

	set_entvar(iGhostEnt, var_classname, CLASSNAME_GHOST)

	engfunc(EngFunc_SetModel, iGhostEnt, MODEL_GHOST)
	engfunc(EngFunc_SetSize, iGhostEnt, { -12.0, -12.0, 8.0 }, { 12.0,  12.0,  54.0 })
	engfunc(EngFunc_SetOrigin, iGhostEnt, vOrigin)

	set_entvar(iGhostEnt, var_origin, vOrigin)
	set_entvar(iGhostEnt, var_angles, vAngles)
	set_entvar(iGhostEnt, var_solid, SOLID_NOT)
	set_entvar(iGhostEnt, var_movetype, MOVETYPE_NOCLIP)
	set_entvar(iGhostEnt, var_rendermode, kRenderTransAlpha)
	set_entvar(iGhostEnt, var_renderamt, GHOST_TRANSPARENT)

	new Float:fGameTime = get_gametime()
	new iTeam = get_member(iPlayer, m_iTeam)

	set_entvar(iGhostEnt, var_skin, iTeam - 1)
	set_entvar(iGhostEnt, var_team, iTeam)
	set_entvar(iGhostEnt, var_owner, iPlayer)
	set_entvar(iGhostEnt, var_impulse, IMPULSE_GHOST)

	g_ePlayerData[iPlayer][CURRENT_COMBO_BUTTON] = random(2) ? IN_ATTACK : IN_ATTACK2
	set_hudmessage(
		.red = 255,
		.green = 255,
		.blue = 255,
		.x = -1.0,
		.y = -0.40,
		.fxtime = 0.0,
		.holdtime = 1.0,
		.fadeintime = 0.0,
		.fadeouttime = 0.0,
		.channel = HUDCHANNEL_STATUS
	)
	show_hudmessage(iPlayer, "%s", g_ePlayerData[iPlayer][CURRENT_COMBO_BUTTON] == IN_ATTACK ? "L L L" : "R R R")

	set_entvar(iGhostEnt, var_nextthink, fGameTime + 1.0)

	set_entvar(iGhostEnt, var_animtime, fGameTime)
	set_entvar(iGhostEnt, var_sequence, GHOST_SEQ_SPAWN)
	set_entvar(iGhostEnt, var_frame, 0)
	set_entvar(iGhostEnt, var_framerate, 1.0)

	SetThink(iGhostEnt, "ghost_think")

	set_entvar(iCameraEnt, var_classname, GHOST_CAMERA_CLASSNAME)
	engfunc(EngFunc_SetModel, iCameraEnt, "models/rpgrocket.mdl")
	engfunc(EngFunc_SetSize, iCameraEnt, { -8.0, -8.0, -8.0 }, { 8.0,  8.0,  8.0 })

	set_entvar(iCameraEnt, var_solid, SOLID_NOT)
	set_entvar(iCameraEnt, var_movetype, MOVETYPE_FLYMISSILE)
	set_entvar(iCameraEnt, var_owner, iGhostEnt)
	set_entvar(iCameraEnt, var_nextthink, fGameTime)

	set_entvar(iCameraEnt, var_rendermode, kRenderTransAlpha)
	set_entvar(iCameraEnt, var_renderamt, 0)

	SetThink(iCameraEnt, "ghostcamera_think")

	Beam_EntsInit(iBeam, iPlayer, iGhostEnt)
	Beam_SetColor(iBeam, {255.0, 255.0, 255.0})
	Beam_SetBrightness(iBeam, 100.0)
	set_entvar(iBeam, var_impulse, IMPULSE_GHOST_BEAM)

	kc_player_set_camera(iPlayer, iCameraEnt)

	set_entvar(iGhostEnt, var_target_beam, iBeam)
	set_entvar(iGhostEnt, var_target_camera, iCameraEnt)

	engfunc(EngFunc_EmitSound, iGhostEnt, CHAN_STATIC, SOUND_GHOST_SPAWN, 1.0, ATTN_STATIC, 0, PITCH_NORM)

	g_ePlayerData[iPlayer][GHOST_ENT] = iGhostEnt
	g_ePlayerData[iPlayer][GHOST_STATE] = GHOST_ST_SPAWN
	g_ePlayerData[iPlayer][GHOST_SPAWN_TIME] = fGameTime

	return PLUGIN_CONTINUE
}

public efk_uncapture(iPlayer)
{
	if (g_ePlayerData[iPlayer][IN_COFFIN])
		coffin_set_status(iPlayer, false)

	if (g_ePlayerData[iPlayer][GHOST_ENT])
	{
		if (g_ePlayerData[iPlayer][IS_ALIVE])
		{
			set_entvar(iPlayer, var_angles, g_ePlayerData[iPlayer][GHOST_FIRST_ANGLES])
			set_entvar(iPlayer, var_v_angle, g_ePlayerData[iPlayer][GHOST_FIRST_ANGLES])
			set_entvar(iPlayer, var_fixangle, 1)
		}

		ghost_kill(iPlayer)
	}
}

public client_disconnected(iPlayer)
{
	remove_task(iPlayer + TASK_WEB_STUNNED)
	g_ePlayerData[iPlayer][IS_ALIVE] = false
}

public Ham_PlayerSpawn_Post(iPlayer)
{
	g_ePlayerData[iPlayer][STUNED_WEB] = 0
	g_ePlayerData[iPlayer][POST_REGENERATION_HP] = 0
	remove_task(iPlayer + TASK_WEB_STUNNED)

	if (is_user_alive(iPlayer))
		g_ePlayerData[iPlayer][IS_ALIVE] = true
}

public Ham_Player_ImpulseCommands_Pre(iPlayer)
{
	if (get_entvar(iPlayer, var_impulse) != 100)
		return HAM_IGNORED

	new iGhost = g_ePlayerData[iPlayer][GHOST_ENT]
	if (iGhost)
	{
		new iGhostCamera = get_entvar(iGhost, var_target_camera)
		if (kc_player_get_camera(iPlayer) == iGhostCamera)
			kc_player_set_camera(iPlayer, CAMERA_MODE_3RD)
		else
			kc_player_set_camera(iPlayer, iGhostCamera)
	}

	return HAM_IGNORED
}

public Ham_Player_PreThink_Pre(iPlayer)
{
	static iButtons, iGhost
	new Float:fGameTime = get_gametime()

	if (g_ePlayerData[iPlayer][IN_COFFIN])
	{
		iButtons = get_entvar(iPlayer, var_button)

		if ((iButtons & IN_ATTACK) || (iButtons & IN_ATTACK2))
		{
			new iItem = get_member(iPlayer, m_pActiveItem)
			if (!is_nullent(iItem))
				coffin_release(iPlayer, iItem)
		}
	}

	if (g_ePlayerData[iPlayer][GHOST_ENT]
		&& (
			g_ePlayerData[iPlayer][GHOST_STATE] == GHOST_ST_ACTIVE
			|| g_ePlayerData[iPlayer][GHOST_STATE] == GHOST_ST_SPAWN
		)
	) {
		iButtons = get_entvar(iPlayer, var_button)
		iGhost = g_ePlayerData[iPlayer][GHOST_ENT]

		new currentSingleButton =
			iButtons & IN_ATTACK && ~iButtons & IN_ATTACK2
			? IN_ATTACK
			: iButtons & IN_ATTACK2 && ~iButtons & IN_ATTACK
			? IN_ATTACK2
			: 0

		if (g_ePlayerData[iPlayer][GHOST_STATE] != GHOST_ST_SPAWN || (
			g_ePlayerData[iPlayer][CURRENT_COMBO_BUTTON]
			&& g_ePlayerData[iPlayer][CURRENT_COMBO_BUTTON] == currentSingleButton
		)) {
			if (iButtons & IN_ATTACK)
			{
				set_entvar(iGhost, var_animtime, fGameTime)
				set_entvar(iGhost, var_sequence, GHOST_SEQ_ATTACK1)
				set_entvar(iGhost, var_frame, 0)
				set_entvar(iGhost, var_nextthink, fGameTime + 1.16)
				set_entvar(iGhost, var_renderamt, GHOST_TRANSPARENT)

				g_ePlayerData[iPlayer][GHOST_STATE] = GHOST_ST_ATTACK

				engfunc(EngFunc_EmitSound, iGhost, CHAN_STATIC,
					ghost_attack(iPlayer, iGhost, GHOST_DAMAGE1, 0.0) ? SOUND_GHOST_HIT1 : SOUND_GHOST_ATTACK1,
					1.0, ATTN_NORM, 0, PITCH_NORM
				)
			}
			else if (iButtons & IN_ATTACK2)
			{
				set_entvar(iGhost, var_animtime, fGameTime)
				set_entvar(iGhost, var_sequence, GHOST_SEQ_ATTACK2)
				set_entvar(iGhost, var_frame, 0)
				set_entvar(iGhost, var_nextthink, fGameTime + 1.375)
				set_entvar(iGhost, var_renderamt, GHOST_TRANSPARENT)

				g_ePlayerData[iPlayer][GHOST_STATE] = GHOST_ST_ATTACK

				engfunc(EngFunc_EmitSound, iGhost, CHAN_STATIC,
					ghost_attack(iPlayer, iGhost, GHOST_DAMAGE2, 0.0) ? SOUND_GHOST_HIT2 : SOUND_GHOST_ATTACK2,
					1.0, ATTN_NORM, 0, PITCH_NORM
				)
			}
		}

		if (currentSingleButton && g_ePlayerData[iPlayer][CURRENT_COMBO_BUTTON])
		{
			set_hudmessage(
				.red = 255,
				.green = 255,
				.blue = 255,
				.x = -1.0,
				.y = -0.40,
				.fxtime = 0.0,
				.holdtime = 1.0,
				.fadeintime = 0.0,
				.fadeouttime = 0.0,
				.channel = HUDCHANNEL_STATUS
			)
			show_hudmessage(iPlayer, "%s", g_ePlayerData[iPlayer][CURRENT_COMBO_BUTTON] == currentSingleButton ? "X X X" : "* * *")

			g_ePlayerData[iPlayer][CURRENT_COMBO_BUTTON] = 0;
		}
	}

	if (g_ePlayerData[iPlayer][LAST_WEB_TEAM_TOUCH] + 0.1 >= fGameTime)
	{
		iButtons = get_entvar(iPlayer, var_button)

		if ((iButtons & IN_JUMP) && (iButtons & IN_DUCK) && allow_long_jump(iPlayer))
		{
			new Float:vAngles[3]
			get_entvar(iPlayer, var_v_angle, vAngles)

			new iLjButtons = IN_FORWARD
			if (!(kc_player_get_options(iPlayer) & OPTION_ONE_DIRECTION_LJ))
				iLjButtons = iButtons

			new Float:vVelocity[3]
			calc_omni_direction(vAngles[1], iLjButtons, vVelocity)
			xs_vec_mul_scalar(vVelocity, LONGJUMP_FORCE, vVelocity)
			vVelocity[2] = LONGJUMP_HEIGHT

			set_entvar(iPlayer, var_velocity, vVelocity)
		}
	}

	static Float:fNextRegenTime[MAX_PLAYERS + 1]
	if (fGameTime > fNextRegenTime[iPlayer])
	{
		new Float:fCurrentHealth = Float:get_entvar(iPlayer, var_health)
		new Float:fMaxHealth = Float:get_entvar(iPlayer, var_max_health)

		new bool:bCanRegenerate =
			g_ePlayerData[iPlayer][POST_REGENERATION_HP] > 0
			&& !g_ePlayerData[iPlayer][IN_COFFIN]
			&& fCurrentHealth < fMaxHealth
			&& !kc_player_in_burn(iPlayer)
			// && kc_player_get_powerdamage(iPlayer) <= 0.0

		if (bCanRegenerate)
		{
			set_entvar(iPlayer, var_health, fCurrentHealth + 1.0)
			g_ePlayerData[iPlayer][POST_REGENERATION_HP]--

			fNextRegenTime[iPlayer] = fGameTime + 0.6
		}
	}

	return HAM_IGNORED
}

public Ham_PlayerKilled_Pre(iPlayer)
{
	g_ePlayerData[iPlayer][STUNED_WEB] = 0
	g_ePlayerData[iPlayer][IS_ALIVE] = false
	g_ePlayerData[iPlayer][LAST_WEB_TEAM_TOUCH] = _:0.0
	g_ePlayerData[iPlayer][POST_REGENERATION_HP] = 0
	remove_task(iPlayer + TASK_WEB_STUNNED)
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iWebEnt = NULLENT
	while ((iWebEnt = rg_find_ent_by_class(iWebEnt, CLASSNAME_WEB)))
		rg_remove_entity(iWebEnt)
}

public Ham_Knife_PrimaryAttack_Post(iItem)
{
	if (is_nullent(iItem))
		return HAM_IGNORED

	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	new iPlayer = get_member(iItem, m_pPlayer)
	new Float:fNextAttack = Float:get_member(iItem, m_Weapon_flNextPrimaryAttack)

	if (g_ePlayerData[iPlayer][STUNED_WEB] && fNextAttack < 1.0)
		set_member(iItem, m_Weapon_flNextPrimaryAttack, fNextAttack * 1.5)

	return HAM_IGNORED
}

public Ham_Knife_SecondaryAttack_Post(iItem)
{
	if (is_nullent(iItem))
		return HAM_IGNORED

	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	new iPlayer = get_member(iItem, m_pPlayer)
	new Float:fNextAttack = Float:get_member(iItem, m_Weapon_flNextSecondaryAttack)

	if (g_ePlayerData[iPlayer][STUNED_WEB] && fNextAttack == 1.0)
		set_member(iItem, m_Weapon_flNextSecondaryAttack, fNextAttack * 1.5)

	return HAM_IGNORED
}

coffin_release(const iPlayer, const iWeapon)
{
	new Float:fCoffinTime = get_gametime() - g_ePlayerData[iPlayer][COFFIN_LASTUSE]

	if (is_user_has_knife(iPlayer) && g_ePlayerData[iPlayer][IN_COFFIN] && fCoffinTime > COFFIN_DELAY)
	{
		coffin_set_status(iPlayer, false)
		kc_player_rush(iPlayer, 300.0, fCoffinTime * 2.0)
		kc_player_add_glow(iPlayer, fCoffinTime * 2.0, 255, 0, 0)
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_SHADOWJUMP, 1.0, ATTN_NORM, 0, PITCH_NORM)

		#pragma unused iWeapon
		// set_member(iWeapon, m_Weapon_flNextPrimaryAttack, -1.0)
		// set_member(iWeapon, m_Weapon_flNextSecondaryAttack, -1.0)
		// set_member(iPlayer, m_flNextAttack, 0.0)
	}
}

public fw_Player_TakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if ((iFlags & DMG_FALL) && rebound(iVictim))
		return HAM_SUPERCEDE

	if (is_entity_player(iAttacker) && is_user_has_knife(iAttacker) && (iFlags & DMG_BULLET))
		add_damage_charge(iAttacker, fDamage)

	return HAM_IGNORED
}

public fw_PlayerTakeHealth_Pre(iPlayer, Float:fHelath, iFlags)
{
	if (g_ePlayerData[iPlayer][IN_COFFIN])
		return HAM_SUPERCEDE

	if (!is_user_has_knife(iPlayer))
		return HAM_IGNORED

	if (iFlags == DMG_GENERIC && fHelath > 2.0)
	{
		g_ePlayerData[iPlayer][LAST_TAKEHEALTH_TIME] = get_gametime()
		SetHamParamFloat(2, 2.0)
		return HAM_OVERRIDE
	}

	return HAM_IGNORED
}

web_create(Float:vOrigin[3], Float:vNormal[3], iOwner)
{
	new iWebEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iWebEnt))
		return NULLENT

	new Float:vAngles[3]
	vector_to_angle(vNormal, vAngles)
	vAngles[0] -= 90.0

	new Float:mTr[3][3], Float:mInvTr[3][3]

	new Float:mInvY[3][3] = {
		{1.0, 0.0, 0.0},
		{0.0, 0.0, 1.0},
		{0.0, -1.0, 0.0}
	}
	trans_vector(vNormal, mInvY, mInvTr[1])
	xs_vec_cross(mInvTr[1], vNormal, mInvTr[0])
	xs_vec_copy(vNormal, mInvTr[2])
	inverse_matrix(mInvTr, mTr)

	new Float:vDim[3]
	vDim[0] = WEB_RADIUS
	vDim[1] = WEB_RADIUS
	vDim[2] = WEB_HEIGHT * 0.5

	new Float:vMins[3], Float:vMaxs[3]
	calc_bbox(vDim, mTr, vMins, vMaxs)

	new Float:fOffset = (WEB_HEIGHT * 0.5) - WEB_OFFSET
	vMins[2] += fOffset
	vMaxs[2] += fOffset

	set_entvar(iWebEnt, var_classname, CLASSNAME_WEB)
	engfunc(EngFunc_SetModel, iWebEnt, MODEL_WEB)
	engfunc(EngFunc_SetSize, iWebEnt, vMins, vMaxs)
	engfunc(EngFunc_SetOrigin, iWebEnt, vOrigin)

	set_entvar(iWebEnt, var_origin, vOrigin)
	set_entvar(iWebEnt, var_angles, vAngles)
	set_entvar(iWebEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iWebEnt, var_movetype, MOVETYPE_FLYMISSILE)
	set_entvar(iWebEnt, var_rendermode, kRenderNormal)

	set_entvar(iWebEnt, var_invaxis_x, mInvTr[0])
	set_entvar(iWebEnt, var_invaxis_y, mInvTr[1])
	set_entvar(iWebEnt, var_invaxis_z, mInvTr[2])

	new Float:fGameTime = get_gametime()
	new iTeam = get_member(iOwner, m_iTeam)

	set_entvar(iWebEnt, var_skin, iTeam - 1)
	set_entvar(iWebEnt, var_team, iTeam)
	set_entvar(iWebEnt, var_owner, iOwner)
	set_entvar(iWebEnt, var_impulse, IMPULSE_WEB)
	set_entvar(iWebEnt, var_nextthink, fGameTime + WEB_LIFETIME)

	set_entvar(iWebEnt, var_animtime, fGameTime)
	set_entvar(iWebEnt, var_frame, 0.0)
	set_entvar(iWebEnt, var_framerate, 0.5)

	SetThink(iWebEnt, "web_think")
	SetTouch(iWebEnt, "web_touch")

	return iWebEnt
}

public web_think(iWeb)
{
	if (!is_nullent(iWeb))
		rg_remove_entity(iWeb)
}

public web_touch(iEnt, iOther)
{
	if (is_nullent(iOther))
		return

	static Float:vVelocity[3], Float:fResist, Float:fSpeed, iImpulse

	if (iOther <= MaxClients)
	{
		if (!entity_in_web(iOther, iEnt))
			return

		if (get_entvar(iEnt, var_team) != get_member(iOther, m_iTeam))
		{
			if (!kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY))
			{
				new Float:fGameTime = get_gametime()

				if (g_ePlayerData[iOther][LAST_WEB_TOUCH] + 0.1 < fGameTime)
					g_ePlayerData[iOther][POWER_WEB] = _:0.0

				if (g_ePlayerData[iOther][POWER_WEB] < WEB_ACUM_SPEED)
				{
					get_entvar(iOther, var_velocity, vVelocity)
					fSpeed = xs_vec_len(vVelocity)
					fResist = floatmin(1.0, 1.0 - g_ePlayerData[iOther][POWER_WEB] / (WEB_ACUM_SPEED * 3.5))

					vVelocity[0] *= fResist
					vVelocity[1] *= fResist

					set_entvar(iOther, var_velocity, vVelocity)
					g_ePlayerData[iOther][POWER_WEB] += fSpeed
				}
				else
				{
					set_player_stun_web(iOther)
				}

				g_ePlayerData[iOther][LAST_WEB_TOUCH] = _:fGameTime
			}
		}
		else
		{
			g_ePlayerData[iOther][LAST_WEB_TEAM_TOUCH] = _:get_gametime()

			get_entvar(iOther, var_velocity, vVelocity)
			if (vVelocity[2] < -500.0)
			{
				vVelocity[2] = floatmin(MAX_REBOUND_FORCE, vVelocity[2] * -0.7)
				set_entvar(iOther, var_velocity, vVelocity)
			}
		}
	}
	else
	{
		iImpulse = get_entvar(iOther, var_impulse)
		if (iImpulse == IMPULSE_BUG || iImpulse == IMPULSE_ZOMBIE)
		{
			if (!entity_in_web(iOther, iEnt))
				return

			if (get_entvar(iEnt, var_skin) != get_entvar(iOther, var_skin))
			{
				get_entvar(iOther, var_velocity, vVelocity)
				if (floatsqroot(vVelocity[0] * vVelocity[0] + vVelocity[1] * vVelocity[1]) > 50.0)
				{
					vVelocity[0] *= 0.5
					vVelocity[1] *= 0.5
					set_entvar(iOther, var_velocity, vVelocity)
				}
			}
		}
	}
}

public fw_EmitSound(iEnt, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (is_user_alive(iEnt) && equal(sample, "common/bodysplat.wav") && rebound(iEnt))
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

public ghost_think(iGhost)
{
	new iOwner = get_entvar(iGhost, var_owner)

	switch(g_ePlayerData[iOwner][GHOST_STATE])
	{
		case GHOST_ST_SPAWN:
		{
			g_ePlayerData[iOwner][GHOST_STATE] = GHOST_ST_ACTIVE
		}
		case GHOST_ST_ATTACK:
		{
			g_ePlayerData[iOwner][GHOST_STATE] = GHOST_ST_ACTIVE
		}
		case GHOST_ST_DEATH:
		{
			set_entvar(iGhost, var_flags, FL_KILLME)
		}
	}
}

public ghostcamera_think(iCamera)
{
	static iOwner, iGhost, Float:vOrigin[3], Float:vAngles[3],
		Float:vVector[3], Float:vVectorSide[3], Float:fVecAdd[3],
		Float:fPitch, Float:vVelocity[3],
		Float:fGameTime

	iGhost = get_entvar(iCamera, var_owner)
	iOwner = get_entvar(iGhost, var_owner)

	get_entvar(iGhost, var_origin, vOrigin)
	get_entvar(iOwner, var_v_angle, vAngles)

	fPitch = vAngles[0]
	vAngles[0] = 0.0
	vAngles[2] = 0.0

	fGameTime = get_gametime()

	set_entvar(iGhost, var_angles, vAngles)

	vAngles[0] = fPitch * GHOST_CAMERA_ROTCOF

	vVector[0] = floatcos(vAngles[1], degrees)
	vVector[1] = floatsin(vAngles[1], degrees)
	vVector[2] = -floatsin(vAngles[0], degrees)

	new iGhostState = g_ePlayerData[iOwner][GHOST_STATE]

	if (iGhostState == GHOST_ST_ACTIVE || iGhostState == GHOST_ST_ATTACK)
	{
		new iButtons = get_entvar(iOwner, var_button)

		if (iButtons & (IN_RELOAD | IN_USE))
		{
			if (kc_player_get_abil3_charge(iOwner) >= 100.0 - ABIL3_CHARGE)
				kc_player_set_abil3_charge(iOwner, 100.0 - ABIL3_CHARGE * 2.0)

			kc_player_set_capture(iOwner, CAPTURE_NONE)
			return
		}

		new bool:bIsGhostAttack = iGhostState == GHOST_ST_ATTACK
		new Float:fSpeed = bIsGhostAttack ? GHOST_SLOW_SPEED : GHOST_SPEED
		new iAnim = GHOST_SEQ_IDLE

		if (iButtons & IN_FORWARD)
		{
			xs_vec_copy(vVector, vVectorSide)

			if (iButtons & IN_MOVERIGHT)
			{
				vVectorSide[0] += floatcos(vAngles[1] - 90.0, degrees)
				vVectorSide[1] += floatsin(vAngles[1] - 90.0, degrees)
			}
			else if (iButtons & IN_MOVELEFT)
			{
				vVectorSide[0] += floatcos(vAngles[1] + 90.0, degrees)
				vVectorSide[1] += floatsin(vAngles[1] + 90.0, degrees)
			}

			if (iButtons & IN_JUMP)
				vVectorSide[2] = 1.0
			else if (iButtons & IN_DUCK)
				vVectorSide[2] = -1.0

			xs_vec_normalize(vVectorSide, vVectorSide)
			xs_vec_mul_scalar(vVectorSide, fSpeed, vVelocity)
			iAnim = GHOST_SEQ_RUN
		}
		else if (iButtons & IN_BACK)
		{
			xs_vec_copy(vVector, vVectorSide)

			if (iButtons & IN_MOVERIGHT)
			{
				vVectorSide[0] += floatcos(vAngles[1] + 90.0, degrees)
				vVectorSide[1] += floatsin(vAngles[1] + 90.0, degrees)
			}
			else if (iButtons & IN_MOVELEFT)
			{
				vVectorSide[0] += floatcos(vAngles[1] - 90.0, degrees)
				vVectorSide[1] += floatsin(vAngles[1] - 90.0, degrees)
			}

			if (iButtons & IN_JUMP)
				vVectorSide[2] = -1.0
			else if (iButtons & IN_DUCK)
				vVectorSide[2] = 1.0

			xs_vec_normalize(vVectorSide, vVectorSide)
			xs_vec_mul_scalar(vVectorSide, -fSpeed, vVelocity)
			iAnim = GHOST_SEQ_BACK
		}
		else if (iButtons & IN_MOVERIGHT)
		{
			vVectorSide[0] = floatcos(vAngles[1] - 90.0, degrees)
			vVectorSide[1] = floatsin(vAngles[1] - 90.0, degrees)

			if (iButtons & IN_JUMP)
				vVectorSide[2] = 1.0
			else if (iButtons & IN_DUCK)
				vVectorSide[2] = -1.0
			else
				vVectorSide[2] = 0.0

			xs_vec_normalize(vVectorSide, vVectorSide)
			xs_vec_mul_scalar(vVectorSide, fSpeed, vVelocity)
			iAnim = GHOST_SEQ_WALK
		}
		else if (iButtons & IN_MOVELEFT)
		{
			vVectorSide[0] = floatcos(vAngles[1] + 90.0, degrees)
			vVectorSide[1] = floatsin(vAngles[1] + 90.0, degrees)

			if (iButtons & IN_JUMP)
				vVectorSide[2] = 1.0
			else if (iButtons & IN_DUCK)
				vVectorSide[2] = -1.0
			else
				vVectorSide[2] = 0.0

			xs_vec_normalize(vVectorSide, vVectorSide)
			xs_vec_mul_scalar(vVectorSide, fSpeed, vVelocity)
			iAnim = GHOST_SEQ_WALK
		}
		else
		{
			vVelocity[0] = vVelocity[1] = 0.0

			if (iButtons & IN_JUMP)
				vVelocity[2] = fSpeed
			else if (iButtons & IN_DUCK)
				vVelocity[2] = -fSpeed
			else
				vVelocity[2] = 0.0

			if (get_entvar(iGhost, var_sequence) == GHOST_SEQ_SPAWN
				&& Float:get_entvar(iGhost, var_animtime) + 1.9 > fGameTime)
			{
				iAnim = GHOST_SEQ_SPAWN
			}
			else if (vVelocity[2] != 0.0)
			{
				iAnim = GHOST_SEQ_WALK
			}
		}

		set_entvar(iGhost, var_velocity, vVelocity)
		if (!bIsGhostAttack && get_entvar(iGhost, var_sequence) != iAnim)
		{
			set_entvar(iGhost, var_animtime, fGameTime)
			set_entvar(iGhost, var_sequence, iAnim)
			set_entvar(iGhost, var_frame, 0)
		}

		if (iAnim == GHOST_SEQ_IDLE)
		{
			new Float:fTransparent = floatmax(0.0, Float:get_entvar(iGhost, var_renderamt) - 2.0)
			set_entvar(iGhost, var_renderamt, fTransparent)
		}
		else
		{
			set_entvar(iGhost, var_renderamt, GHOST_TRANSPARENT)
		}
	}

	xs_vec_neg(vVector, vVector)
	xs_vec_mul_scalar(vVector, GHOST_CAMERA_DISTANCE, fVecAdd)
	fVecAdd[2] += GHOST_CAMERA_UP

	xs_vec_add(vOrigin, fVecAdd, vVector)
	engfunc(EngFunc_TraceLine, vOrigin, vVector, DONT_IGNORE_MONSTERS, iGhost, 0)
	get_tr2(0, TR_vecEndPos, vOrigin)

	engfunc(EngFunc_SetOrigin, iCamera, vOrigin)

	set_entvar(iCamera, var_origin, vOrigin)
	set_entvar(iCamera, var_angles, vAngles)

	static Float:fDelay[MAX_PLAYERS + 1], iContents, iResetPts[MAX_PLAYERS + 1]
	if (fDelay[iOwner] < fGameTime && kc_player_get_vision(iOwner) != VISION_BLIND && !kc_player_in_chill(iOwner))
	{
		iContents = engfunc(EngFunc_PointContents, vOrigin)
		if (iContents != CONTENTS_EMPTY && iContents != CONTENTS_WATER)
		{
			send_msg_ScreenFade(409, (1<<12), 0, {0, 0, 0}, 255, MSG_ONE, _, iOwner)
			if (++iResetPts[iOwner] == 5)
			{
				engfunc(EngFunc_SetOrigin, iGhost, g_ePlayerData[iOwner][GHOST_FIRST_ORIGIN])
				set_entvar(iGhost, var_origin, g_ePlayerData[iOwner][GHOST_FIRST_ORIGIN])

				send_msg_ScreenFade(0, 0, 0, {0, 0, 0}, 255, MSG_ONE, _, iOwner)
				iResetPts[iOwner] = 0
			}
		}
		else iResetPts[iOwner] = 0

		fDelay[iOwner] = fGameTime + 0.5
	}

	set_entvar(iCamera, var_nextthink, fGameTime + 0.01)
}

public unstun_web(iPlayer)
{
	g_ePlayerData[iPlayer - TASK_WEB_STUNNED][STUNED_WEB] = 0
}

coffin_set_status(iPlayer, bool:bStatus)
{
	if (g_ePlayerData[iPlayer][IN_COFFIN] == bStatus)
		return PLUGIN_HANDLED

	if (!bStatus)
	{
		g_ePlayerData[iPlayer][IN_COFFIN] = false
		kc_player_set_capture(iPlayer, CAPTURE_NONE)
		kc_player_unset_game_flag(iPlayer, PLGF_IN_UNABILITY | PLGF_IN_LOCK_POWER_DAMAGE)
		kc_player_set_camera(iPlayer, CAMERA_MODE_1ST)
		remove_task(iPlayer + TASK_DAMAGE)
		coffin_remove(iPlayer)
	}
	else
	{
		new Float:fHealth = Float:get_entvar(iPlayer, var_health)
		if (fHealth < COFFIN_DAMAGE_START + COFFIN_DAMAGE)
			return PLUGIN_HANDLED

		if (!kc_player_set_capture(iPlayer, CAPTURE_STRONG, CAP_ANIM_IRON_MAIDEN, 999.0, true, true) || coffin_spawn(iPlayer) == NULLENT)
			return PLUGIN_HANDLED

		kc_player_unburn(iPlayer)
		set_entvar(iPlayer, var_velocity, NULL_VECTOR)

		g_ePlayerData[iPlayer][COFFIN_LASTUSE] = _:get_gametime()
		g_ePlayerData[iPlayer][IN_COFFIN] = true
		kc_player_set_game_flag(iPlayer, PLGF_IN_UNABILITY | PLGF_IN_LOCK_POWER_DAMAGE)
		kc_player_set_camera(iPlayer, CAMERA_MODE_3RD)
		get_entvar(iPlayer, var_origin, g_vPlayerOrigin[iPlayer])

		if (get_entvar(iPlayer, var_flags) & FL_DUCKING)
			g_vPlayerOrigin[iPlayer][2] += 18.0

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_IRON_MAIDEN, 1.0, ATTN_NORM, 0, PITCH_NORM)

		set_task(0.5, "Task_CoffinFirstDamage", TASK_DAMAGE + iPlayer)
	}

	return PLUGIN_CONTINUE
}

coffin_remove(iOwner)
{
	if (!is_nullent(g_iPlayerCoffin[iOwner]))
	{
		set_entvar(g_iPlayerCoffin[iOwner], var_flags, FL_KILLME)
		g_iPlayerCoffin[iOwner] = 0
	}
}

coffin_spawn(iOwner)
{
	new iCoffinEnt = rg_create_entity(SZ_INFO_TARGET)
	g_iPlayerCoffin[iOwner] = iCoffinEnt

	if (is_nullent(iCoffinEnt))
		return NULLENT

	engfunc(EngFunc_SetModel, iCoffinEnt, MODEL_COFFIN)
	engfunc(EngFunc_SetSize, iCoffinEnt, {-5.0, -5.0, -16.0}, {5.0, 5.0, 32.0})
	set_entvar(iCoffinEnt, var_classname, COFFIN_CLASSNAME)
	set_entvar(iCoffinEnt, var_rendermode, kRenderNormal)
	set_entvar(iCoffinEnt, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iCoffinEnt, var_aiment, iOwner)
	set_entvar(iCoffinEnt, var_solid, SOLID_NOT)

	set_entvar(iCoffinEnt, var_skin, get_member(iOwner, m_iTeam) - 1)

	set_entvar(iCoffinEnt, var_frame, 0.0)
	set_entvar(iCoffinEnt, var_framerate, 1.0)
	set_entvar(iCoffinEnt, var_animtime, get_gametime())

	set_entvar(iCoffinEnt, var_impulse, IMPULSE_FOLLOWENT)
	set_entvar(iCoffinEnt, var_owner, iOwner)

	return iCoffinEnt
}

public Task_CoffinFirstDamage(iTaskId)
{
	new iPlayer = iTaskId - TASK_DAMAGE
	TakeCoffinDamage(iPlayer, COFFIN_DAMAGE_START)
	kc_player_set_powerdamage(iPlayer, kc_player_get_powerdamage(iPlayer) + 4.0)
	set_task(COFFIN_DAMAGE_DELAY, "Task_CoffinDamage", iTaskId, .flags="b")
}

public Task_CoffinDamage(iTaskId)
{
	new iPlayer = iTaskId - TASK_DAMAGE
	TakeCoffinDamage(iPlayer, COFFIN_DAMAGE)
	kc_player_set_powerdamage(iPlayer, kc_player_get_powerdamage(iPlayer) + 9.0)
}

TakeCoffinDamage(iPlayer, Float:fDamage)
{
	new Float:fHealth = Float:get_entvar(iPlayer, var_health)
	fHealth -= fDamage
	g_ePlayerData[iPlayer][POST_REGENERATION_HP] += floatround(fDamage)

	if (fHealth >= 1.0)
	{
		set_entvar(iPlayer, var_health, fHealth)
		static Float:fLastBleeding[MAX_PLAYERS + 1]
		new Float:fGameTime = get_gametime()
		if (fLastBleeding[iPlayer] - fGameTime < 0.0)
		{
			new Float:vBloodDirection[3]
			vBloodDirection[0] = random_float(-10.0, 10.0)
			vBloodDirection[1] = random_float(-10.0, 10.0)
			vBloodDirection[2] = random_float(-1.0, 1.0)
			send_msg_TE_BLOODSTREAM(g_vPlayerOrigin[iPlayer], vBloodDirection, 70, random_num(50, 100))

			if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_chill(iPlayer))
				send_msg_ScreenFade((1<<10), (1<<12), 0, {200, 0, 0}, 45, MSG_ONE, _, iPlayer)

			fLastBleeding[iPlayer] = fGameTime + random_float(1.0, 2.5)
			new Float:vEndOrigin[3]
			vEndOrigin[0] = g_vPlayerOrigin[iPlayer][0]
			vEndOrigin[1] = g_vPlayerOrigin[iPlayer][1]
			vEndOrigin[2] = -8192.0
			engfunc(EngFunc_TraceLine, g_vPlayerOrigin[iPlayer], vEndOrigin, IGNORE_MONSTERS, iPlayer, 0)
			get_tr2(0, TR_vecEndPos, vEndOrigin)
			UTIL_SprayBlood(vEndOrigin, 5)
			add_damage_charge(iPlayer, fDamage)
		}
	}
	else
		ExecuteHamB(Ham_Killed, iPlayer, iPlayer, 2)
}

set_player_stun_web(iPlayer)
{
	if (!g_ePlayerData[iPlayer][STUNED_WEB])
	{
		g_ePlayerData[iPlayer][POWER_WEB] = _:0.0
		g_ePlayerData[iPlayer][STUNED_WEB] = 1

		kc_player_unfreeze(iPlayer)
		kc_player_slow(iPlayer, 0.01, WEB_STUNEDTIME)
		kc_player_add_glow(iPlayer, WEB_STUNEDTIME, 255, 255, 255)
		set_task(WEB_STUNEDTIME, "unstun_web", TASK_WEB_STUNNED + iPlayer)
	}
}

bool:rebound(iPlayer)
{
	new bool:bIsWeb, bool:bIsTemmateWeb

	new Float:vPlayerMins[3], Float:vPlayerMaxs[3], Float:vVelocity[3],
		Float:vWebMins[3], Float:vWebMaxs[3]

	get_entvar(iPlayer, var_absmin, vPlayerMins)
	get_entvar(iPlayer, var_absmax, vPlayerMaxs)
	get_entvar(iPlayer, var_velocity, vVelocity)

	new iWebEnt = NULLENT
	while ((iWebEnt = rg_find_ent_by_class(iWebEnt, CLASSNAME_WEB)))
	{
		get_entvar(iWebEnt, var_absmin, vWebMins)
		get_entvar(iWebEnt, var_absmax, vWebMaxs)

		if (!boxes_intersect(vPlayerMins, vPlayerMaxs, vWebMins, vWebMaxs))
			continue

		if (!entity_in_web(iPlayer, iWebEnt))
			continue

		if (get_entvar(iWebEnt, var_team) == get_member(iPlayer, m_iTeam))
			bIsTemmateWeb = true

		bIsWeb = true
	}

	if (bIsTemmateWeb)
	{
		if (vVelocity[2] <= 0.0)
		{
			vVelocity[2] = MAX_REBOUND_FORCE
			set_entvar(iPlayer, var_velocity, vVelocity)
		}
		return true
	}

	if (bIsWeb)
	{
		if (!kc_player_check_game_flag(iPlayer, PLGF_IN_UNABILITY))
			set_player_stun_web(iPlayer)
	}

	return false
}

bool:ghost_attack(iPlayer, iGhost, Float:fDamage, Float:fRangeLimit)
{
	new Float:vOrigin[3], Float:vTargetOrigin[3], iTarget = NULLENT, bool:bWasHit, iTeam, iOwner,
		Float:vAngles[3], Float:vVectors[2][3], Float:vMins[3], Float:vMaxs[3]

	get_entvar(iGhost, var_origin, vOrigin)
	get_entvar(iGhost, var_angles, vAngles)
	vVectors[0][0] = floatcos(vAngles[1], degrees)
	vVectors[0][1] = floatsin(vAngles[1], degrees)

	iTeam = get_entvar(iGhost, var_team)

	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, GHOST_ATTACK_DISTANCE)))
	{
		if (iTarget == iGhost)
			continue

		get_entvar(iTarget, var_origin, vTargetOrigin)

		vVectors[1][0] = vTargetOrigin[0] - vOrigin[0]
		vVectors[1][1] = vTargetOrigin[1] - vOrigin[1]

		if (xs_vec_dot(vVectors[0], vVectors[1]) < fRangeLimit)
			continue

		get_entvar(iTarget, var_absmin, vMins)
		get_entvar(iTarget, var_absmax, vMaxs)

		if (vMins[2] > vOrigin[2] + GHOST_HEIGHT_RANGE)
			continue

		if (vMaxs[2] < vOrigin[2] - GHOST_HEIGHT_RANGE)
			continue

		if (iTarget <= MaxClients)
		{
			if (!g_ePlayerData[iTarget][IS_ALIVE]
				|| (get_entvar(iTarget, var_solid) == SOLID_NOT && !kc_player_get_shadow_target(iTarget))
				|| iPlayer == iTarget
			)
				continue

			if (iTeam == get_member(iTarget, m_iTeam))
			{
				ExecuteHamB(Ham_TakeDamage, iTarget, iGhost, iPlayer, fDamage, DMG_BULLET | DMG_ALWAYSGIB)
				continue
			}

			if (kc_player_apply_concentblock(iTarget, iGhost, ATTACK_HEAVINESS_HIGH))
			{
				set_entvar(g_ePlayerData[iPlayer][GHOST_ENT], var_nextthink, get_gametime() + 2.0)
				continue
			}

			if (kc_player_in_reflection(iTarget))
			{
				kc_player_reflection_done(iTarget, iPlayer)
				swap(iTarget, iPlayer)
			}

			kc_player_set_death_reason(iTarget, "DEATH_REASON_GHOST")

			if (kc_player_get_shadow_target(iTarget))
			{
				new Float:fHealth = Float:get_entvar(iTarget, var_health) - fDamage
				if (fHealth > 0.0)
					set_entvar(iTarget, var_health, fHealth)
				else
					ExecuteHamB(Ham_Killed, iTarget, iPlayer, 0)
			}
			else
			{
				new Float:fVelocityModifier = Float:get_member(iTarget, m_flVelocityModifier)
				set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iTarget, iGhost, iPlayer, fDamage, DMG_BULLET | DMG_ALWAYSGIB)
				set_member(iTarget, m_flVelocityModifier, fVelocityModifier)
			}

			bWasHit = true
		}
		else
		{
			switch (get_entvar(iTarget, var_impulse))
			{
				case IMPULSE_GHOST:
				{
					if (iTeam != get_entvar(iTarget, var_team))
					{
						kc_player_set_capture(get_entvar(iTarget, var_owner), CAPTURE_NONE)
						bWasHit = true
					}
				}
				case IMPULSE_PRESENT:
				{
					dllfunc(DLLFunc_Touch, iTarget, iPlayer)
				}
				case IMPULSE_FAKEPLAYER:
				{
					if (iTeam != get_entvar(iTarget, var_team))
					{
						set_entvar(iTarget, var_nextthink, get_gametime() + 0.1)
						bWasHit = true
					}
				}
				case IMPULSE_RAZOR_SPHERE:
				{
					iOwner = get_entvar(iTarget, var_owner)
					if (is_entity_player(iOwner) && iTeam != get_member(iOwner, m_iTeam))
					{
						set_entvar(iTarget, var_owner, iPlayer)
						set_entvar(iTarget, var_damage_sphere, 0)
						set_entvar(iTarget, var_nextthink, get_gametime())
					}
				}
				case IMPULSE_ICILCE, IMPULSE_KUNAI:
				{
					iOwner = get_entvar(iTarget, var_owner)
					if (is_user_alive(iOwner) && iTeam != get_member(iOwner, m_iTeam))
					{
						new Float:vTargetVelocity[3], Float:vTargetAngles[3]
						get_entvar(iTarget, var_velocity, vTargetVelocity)
						xs_vec_neg(vTargetVelocity, vTargetVelocity)
						set_entvar(iTarget, var_velocity, vTargetVelocity)

						get_entvar(iTarget, var_angles, vTargetAngles)
						xs_vec_neg(vTargetAngles, vTargetAngles)
						set_entvar(iTarget, var_angles, vTargetAngles)

						set_entvar(iTarget, var_owner, iPlayer)
					}
				}
				case IMPULSE_WIND_WAVE:
				{
					if (iTeam != get_entvar(iTarget, var_team))
					{
						new Float:vTargetVelocity[3], Float:vTargetAngles[3]
						get_entvar(iTarget, var_velocity, vTargetVelocity)
						xs_vec_neg(vTargetVelocity, vTargetVelocity)
						set_entvar(iTarget, var_velocity, vTargetVelocity)

						get_entvar(iTarget, var_angles, vTargetAngles)
						xs_vec_neg(vTargetAngles, vTargetAngles)
						set_entvar(iTarget, var_angles, vTargetAngles)
					}
				}
				case IMPULSE_FIELD_WALL:
				{
					if (iTeam != get_entvar(iTarget, var_skin) + 1)
					{
						new iFieldBaseEnt = get_entvar(iTarget, var_aiment)
						new iFieldSide = get_entvar(iTarget, var_fieldside)

						set_entvar(iFieldBaseEnt, var_body, get_entvar(iFieldBaseEnt, var_body) & ~(1<<iFieldSide))
						set_entvar(iTarget, var_flags, FL_KILLME)

						engfunc(EngFunc_EmitSound, iTarget, CHAN_STATIC, SOUNDS_FIELD_BREAK[random(sizeof SOUNDS_FIELD_BREAK)], VOL_NORM, ATTN_STATIC, 0, PITCH_NORM)

						new Float:vMins[3], Float:vMaxs[3], Float:vOrigin[3]
						get_entvar(iTarget, var_absmin, vMins)
						get_entvar(iTarget, var_absmax, vMaxs)

						vOrigin[0] = vMins[0]
						vOrigin[1] = vMins[1]
						vOrigin[2] = vMaxs[2]

						send_msg_TE_SPARKS(vOrigin)

						vOrigin[0] = vMaxs[0]
						vOrigin[1] = vMaxs[1]

						send_msg_TE_SPARKS(vOrigin)
					}
				}
				default:
				{
					if ((get_entvar(iTarget, var_flags) & FL_MONSTER) && iTeam != get_entvar(iTarget, var_skin) + 1)
					{
						ExecuteHamB(Ham_TakeDamage, iTarget, iGhost, iPlayer, fDamage, DMG_BULLET | DMG_ALWAYSGIB)
						bWasHit = true
					}
					else
					{
						if (FClassnameIs(iTarget, "grenade"))
						{
							if (iTeam != get_member(iTarget, m_Grenade_iTeam))
							{
								new Float:vVelocity[3]
								get_entvar(iTarget, var_velocity, vVelocity)
								vVelocity[0] = -vVelocity[0]
								vVelocity[1] = -vVelocity[1]
								vVelocity[2] = floatabs(vVelocity[2])
								set_entvar(iTarget, var_velocity, vVelocity)
							}
						}
					}
				}
			}
		}
	}

	return bWasHit
}

ghost_kill(iOwner)
{
	new iGhost = g_ePlayerData[iOwner][GHOST_ENT]
	new Float:fGameTime = get_gametime()

	set_entvar(iGhost, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iGhost, var_nextthink, fGameTime + 1.08)

	set_entvar(iGhost, var_animtime, fGameTime)
	set_entvar(iGhost, var_sequence, GHOST_SEQ_DEATH)
	set_entvar(iGhost, var_frame, 0)

	set_entvar(iGhost, var_renderamt, GHOST_TRANSPARENT)

	rg_remove_entity(get_entvar(iGhost, var_target_camera))
	rg_remove_entity(get_entvar(iGhost, var_target_beam))

	g_ePlayerData[iOwner][GHOST_STATE] = GHOST_ST_DEATH

	kc_player_sub_glow(iOwner, 255, 1, 1)

	kc_player_set_camera(iOwner, CAMERA_MODE_1ST)

	if (!kc_player_in_freeze(iOwner))
	{
		kc_player_slow(iOwner, UNGHOST_SLOWPOWER, UNGHOST_SLOWTIME)

		if (kc_player_get_vision(iOwner) != VISION_BLIND && !kc_player_in_chill(iOwner))
			send_msg_ScreenFade((1<<10), (1<<12), 0, {255, 80, 80}, 45, MSG_ONE, _, iOwner)
	}

	set_entvar(iOwner, var_punchangle, Float:{0.0, 0.0, 25.0})

	g_ePlayerData[iOwner][GHOST_ENT] = 0
}

add_damage_charge(iPlayer, Float:fDamage)
{
	if (fDamage <= 0.0)
		return

	new Float:fCharge = kc_player_get_abil1_charge(iPlayer) + floatmin(fDamage * DAMAGE_CHARGE_MUL, MAX_DAMAGE_CHARGE)
	kc_player_set_abil1_charge(iPlayer, floatmin(fCharge, 100.0))
}

UTIL_SprayBlood(Float:fPos[3], iNum = 1)
{
	new Float:vDecalOrigin[3]

	for (new i; i < iNum; i++)
	{
		vDecalOrigin[0] = fPos[0] + random_float(-25.0, 25.0)
		vDecalOrigin[1] = fPos[1] + random_float(-25.0, 25.0)
		vDecalOrigin[2] = fPos[2]
		send_msg_TE_WORLDDECAL(vDecalOrigin, random_num(190, 197))
	}
}

bool:allow_long_jump(iPlayer)
{
	if (!(get_entvar(iPlayer, var_flags) & FL_ONGROUND) || fm_get_speed(iPlayer) < 100)
		return false

	if (Float:get_entvar(iPlayer, var_maxspeed) < SPEED)
		return false

	return true
}

swap(&a, &b)
{
	if (a != b)
	{
		a ^= b
		b ^= a
		a ^= b
	}
}