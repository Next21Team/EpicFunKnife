#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Necro Knife"

#define KNIFE_CLASSNAME "weapon_next21_necro_r02"
#define KNIFE_MENUDESC  "KNIFE_NECRO_DESC"
#define KNIFE_CHATDESC  "KNIFE_NECRO_CHAT"

#define HP				110.0
#define GRAVITY			1.0
#define SPEED			210.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL		10

#define ABIL1_NAME		"Necro"
#define ABIL4_NAME		"Soul Pulse"

#define ABIL1_CHARGE_TIME		12.0

#define ABIL1_CHARGE	(100.0 / ABIL1_CHARGE_TIME)
#define ABIL4_CHARGE	20.0
#define ABIL1_TYPE		ABIL_NORMAL
#define ABIL1_MINDIST	-1.0
#define ABIL1_MAXDIST	-1.0

#define MAX_MINION_SLOTS	2
#define MINION_SLOT_HEAVY	0
#define MINION_RESPAWN_TIME	15.0
#define MINION_SPAWN_DELAY	5.0
#define MINION_KNIFE_CHANGE_SPAWN_DELAY	15.0
#define SPAWN_KNIFE_SET_WINDOW	0.5
#define MINION_SPAWN_DISTANCE	100.0
#define MINION_SPAWN_ANGLE	45.0
#define MINION_ATTACK_INTERVAL	0.8
#define FORM_SWITCH_COOLDOWN	10.0

#define MINION_FOLLOW_RADIUS	600.0
#define MINION_TARGET_RADIUS	800.0
#define MINION_RECALL_DISTANCE	500.0
#define MINION_MOVE_COMMAND_RANGE	500.0
#define MINION_FORMATION_LEASH	150.0
#define MINION_FORMATION_OWNER_SLACK	60.0
#define MOVE_WINDUP_TIME	0.3
#define ATTACK_WINDUP_TIME	0.3
#define ATTACK_RANGE_TOLERANCE	30.0
#define ATTACK_ANIM_LOCK_TIME	0.5
#define ZERGLING_HULL_RADIUS	12.0
#define HEAVY_SPIT_FORWARD	30.0
#define MINION_BLOOD_COLOR	199
#define MOVE_HIT_IGNORE_TIME	0.5
#define HEAVY_FOLLOW_STOP_DISTANCE	100.0
#define MINION_RETURN_SPEED	250.0
#define MINION_SPEED		250.0
#define MODE_CHANGE_WINDUP_TIME	0.3
#define IMPULSE_NECRO_LIFEBAR	30000100
#define var_spit_source		var_iuser1
#define var_spit_reflected	var_iuser3

new const MODEL_V_KNIFE[] = "models/next21_efk/v_necro_knife_b03.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_necro_knife_b02.mdl"

new const SOUND_KNIFE_HIT1[] = "next21_efk/necro_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[] = "next21_efk/necro_knife_hit2.wav"
new const SOUND_KNIFE_STAB[] = "next21_efk/necro_knife_stab.wav"
new const SOUND_KNIFE_HITWALL[] = "next21_efk/necro_knife_hitwall.wav"
new const SOUND_KNIFE_SLASH[] = "next21_efk/necro_knife_slash.wav"
new const SOUND_KNIFE_DEPLOY[] = "next21_efk/necro_knife_deploy.wav"

new const MODEL_ZERGLING[] = "models/next21_efk/zergling.mdl"
new const MODEL_ULTRALISK[] = "models/next21_efk/ultralisk.mdl"
new const MODEL_HYDRA[] = "models/next21_efk/hydralisk.mdl"
new const MODEL_BURROW_MARK[] = "models/next21_efk/necro_burrow_mark.mdl"

#define SPIT_DAMAGE		20.0
#define HYDRA_SPIT_DAMAGE	30.0
#define SPIT_LIFETIME	45.0
#define SPIT_SCAN_INTERVAL	0.02
#define SPIT_SCAN_PAD	8.0
#define SPIT_MOVE_DELAY	0.5
#define HYDRA_SPIT_RELEASE	0.4
#define SPIT_CLEAR_TOLERANCE	40.0
#define SPIT_SCAN_RADIUS	160.0
#define HYDRA_SLOW_SPIT_SPEED	800.0
#define HYDRA_SPIT_SPEED	1300.0

new const MODEL_SPIT[] = "models/next21_efk/crimson_spore.mdl"
new g_iLifebarEnemy, g_iLifebarEnemyHydra

new const MODEL_MINION_LIFEBAR[] = "sprites/next21_efk/lifebar_necro.spr"
new const MODEL_MINION_LIFEBAR_B[] = "sprites/next21_efk/lifebar_necro2.spr"
new const MODEL_MINION_LIFEBAR_H[] = "sprites/next21_efk/lifebar_necro_h.spr"
new const MODEL_MINION_LIFEBAR_B_H[] = "sprites/next21_efk/lifebar_necro2_h.spr"
new const MODEL_MINION_LIFEBAR_ENEMY[] = "sprites/next21_efk/lifebar_necro_enemy.spr"
new const MODEL_MINION_LIFEBAR_ENEMY_H[] = "sprites/next21_efk/lifebar_necro_h_enemy.spr"
new const SZ_ENV_SPRITE[] = "env_sprite"

new const SOUND_SOUL[] = "next21_efk/soul_pulse.wav"

#define NPC_TEAMMATE_DAMAGE_TIME 5.0

#define ZERGLING_HEALTH			75.0
#define ZERGLING_MIN_DAMAGE		20.0
#define ZERGLING_MAX_DAMAGE		30.0
#define MINION_HIT_HEAL_PERCENT	0.25
#define ZERGLING_ATTACK_RANGE		60.0
#define MINION_REGEN_DELAY		5.0
#define MINION_REGEN_RATE		5.0

#define HEAVY_HEALTH			180.0
#define HEAVY_MIN_DAMAGE		30.0
#define HEAVY_MAX_DAMAGE		40.0
#define HEAVY_ATTACK_RANGE	90.0
#define HYDRA_SPIT_RANGE	1600.0
#define HYDRA_SPIT_PAUSE	0.6
#define HYDRA_CLOSE_RANGE	700.0
#define HYDRA_SPIT_HEIGHT	50.0
#define HYDRA_HEALTH		100.0
#define HYDRA_HULL_HEIGHT	64.0
#define ULTRALISK_HULL_RADIUS	26.0
#define ULTRALISK_HULL_HEIGHT	64.0
#define HYDRA_HULL_RADIUS	18.0
#define ULTRALISK_RAGE_TIME	3.5
#define ULTRALISK_RAGE_COOLDOWN	15.0
#define ULTRALISK_RAGE_SPEED	320.0
#define ULTRALISK_RAGE_ATTACK_INTERVAL	0.6
#define ULTRALISK_BURROW_TOGGLE_PAUSE	1.5
#define ULTRALISK_WAKE_TIME	1.9
#define ULTRALISK_BURY_TIME	1.0
#define ULTRALISK_BURROW_REGEN_MUL	4.0
#define HYDRA_MELEE_DAMAGE_MUL	0.5

#define LASER_CHARGE_TIME		1.0
#define LASER_INDICATE_TIME	0.5
#define LASER_DAMAGE			30.0
#define LASER_TRACE_OVERSHOOT	24.0
#define LASER_START_FORWARD	30.0
#define LASER_RANGE		800.0
#define HYDRA_LASER_RANGE	2500.0
#define FOLLOW_TAP_TIME	0.3
#define ZERGLING_JUMP_SPEED	650.0
#define ZERGLING_JUMP_LIFT	250.0
#define ZERGLING_JUMP_MAX_TIME	1.0
#define CLIMB_MIN_RISE		64.0
#define CLIMB_MARK_MIN_RISE	24.0
#define CLIMB_MIN_WALL_HEIGHT	40.0
#define CLIMB_SPEED		240.0
#define CLIMB_WALL_REACH	28.0
#define CLIMB_WALL_PRESS	150.0
#define CLIMB_CORNER_DEPTH	14.0
#define CLIMB_CORNER_PROBE	48.0
#define CLIMB_EDGE_DROP		48.0
#define CLIMB_FACE_OPEN		24.0
#define CLIMB_FACE_SOLID	10.0
#define CLIMB_FACE_VERTICAL	80.0
#define CLIMB_MODEL_SHIFT	24.0
#define CLIMB_HEAVY_TIME	3.0
#define MOVE_BLOCK_AFTER_CLIMB	0.5
#define CLIMB_EXPIRE_PUSH	120.0
#define CLIMB_EXPIRE_LIFT	40.0
#define CLIMB_MODEL_MARGIN	1.5
#define CLIMB_PITCH		90.0
#define CLIMB_ROLL_SIGN		1.0
#define CLIMB_VERTICAL_DOT	0.85
#define CLIMB_ARRIVE_DIST	24.0
#define CLIMB_WALL_ATTACH_DIST	60.0
#define CLIMB_BEYOND_DROP	150.0
#define CLIMB_VAULT_SPEED	260.0
#define CLIMB_VAULT_LIFT	140.0
#define CLIMB_DASH_AIM_LIFT	0.12
#define CLIMB_NO_GRAVITY	0.00001

#define MINION_CHILL_SPEED_MUL		0.4
#define MINION_SLOW_SPEED_MUL		0.35
#define MINION_SLOW_TIME			3.0
#define MINION_BLIND_TIME			4.0
#define MINION_PAIN_TIME			0.8
#define MINION_PAIN_MIN_MUL			0.2
#define MINION_ACID_GLOW_TIME		1.0
#define MINION_BURN_CYCLES			13
#define MINION_BURN_TICK			0.2
#define MINION_BURN_DAMAGE			2.0
#define MINION_BURN_CRIT_DAMAGE		6.0
#define MINION_BURN_CRIT_CHANCE		8
#define MINION_FROZEN_HIT_DAMAGE	20.0
#define MINION_STATUS_TICK			0.1
#define TASK_MINION_STATUS			35100
#define MAX_ENTITIES_NUM			2048

#define SOUL_HEAL_VALUE			15.0
#define SOUL_HEAL_RADIUS		200.0

new const SZ_EXPLOSION[]		= "env_explosion"
new const SZ_INFO_TARGET[]		= "info_target"

new const MODEL_ICEBLOCK[]		= "models/next21_efk/ice_block.mdl"
new const SOUND_FROST_HIT[]		= "next21_efk/frost_hit.wav"
new const SOUND_ICEBLOCK_CRASH[]	= "next21_efk/ice_block_crash.wav"
new const SPRITE_FLAME[]		= "sprites/next21_efk/flame.spr"

new const _CLASSNAME_MINION[]		= CLASSNAME_MINION
new const _CLASSNAME_MINION_SPIT[]	= CLASSNAME_MINION_SPIT

new const SOUNDS_CRIT[][] =
{
	"next21_efk/frash_explosion01.wav",
	"next21_efk/frash_explosion02.wav",
	"next21_efk/frash_explosion03.wav"
}

new const SOUNDS_ZERGLING_YES[][] =
{
	"next21_efk/ling/zergling_yes0.wav",
	"next21_efk/ling/zergling_yes1.wav",
	"next21_efk/ling/zergling_yes2.wav",
	"next21_efk/ling/zergling_yes3.wav",
	"next21_efk/ling/zergling_yes4.wav",
	"next21_efk/ling/zergling_yes5.wav",
	"next21_efk/ling/zergling_yes6.wav"
}

new const SOUNDS_ZERGLING_ATTACK[][] =
{
	"next21_efk/ling/zergling_attack0.wav",
	"next21_efk/ling/zergling_attack1.wav",
	"next21_efk/ling/zergling_attack2.wav",
	"next21_efk/ling/zergling_attack3.wav",
	"next21_efk/ling/zergling_attack4.wav"
}

new const SOUNDS_ZERGLING_DEATH[][] =
{
	"next21_efk/ling/zergling_death0.wav",
	"next21_efk/ling/zergling_death1.wav",
	"next21_efk/ling/zergling_death2.wav",
	"next21_efk/ling/zergling_death3.wav",
	"next21_efk/ling/zergling_death4.wav"
}

new const SOUNDS_ZERGLING_MOVE[][] =
{
	"next21_efk/ling/zzergling_move2li.wav",
	"next21_efk/ling/zzergling_move2lj.wav",
	"next21_efk/ling/zzergling_move2lk.wav"
}

new const Float:ZERGLING_MOVE_VOICE_DELAY[] = {0.62, 0.56, 0.6}
new const Float:ULTRALISK_MOVE_VOICE_DELAY[] = {1.65, 1.65, 1.65}

new const SOUNDS_ZERGLING_HIT[][] =
{
	"next21_efk/ling/zerg_attackimpactsmallpiercing0.wav",
	"next21_efk/ling/zerg_attackimpactsmallpiercing1.wav",
	"next21_efk/ling/zerg_attackimpactsmallpiercing2.wav"
}

new const SOUND_MINION_SWING[] = "next21_efk/ling/swing_lv3.wav"

new const SOUNDS_ULTRALISK_YES[][] =
{
	"next21_efk/ultralisk/ultralisk_yes0.wav",
	"next21_efk/ultralisk/ultralisk_yes1.wav",
	"next21_efk/ultralisk/ultralisk_yes2.wav",
	"next21_efk/ultralisk/ultralisk_yes3.wav",
	"next21_efk/ultralisk/ultralisk_yes4.wav"
}

new const SOUNDS_ULTRALISK_ATTACK[][] =
{
	"next21_efk/ultralisk/ultralisk_attack0.wav",
	"next21_efk/ultralisk/ultralisk_attack1.wav",
	"next21_efk/ultralisk/ultralisk_attack2.wav",
	"next21_efk/ultralisk/ultralisk_attack3.wav"
}

new const SOUNDS_ULTRALISK_DEATH[][] =
{
	"next21_efk/ultralisk/ultralisk_death0.wav",
	"next21_efk/ultralisk/ultralisk_death1.wav",
	"next21_efk/ultralisk/ultralisk_death2.wav",
	"next21_efk/ultralisk/ultralisk_death3.wav",
	"next21_efk/ultralisk/ultralisk_death4.wav"
}

new const SOUNDS_ULTRALISK_HIT[][] =
{
	"next21_efk/ultralisk/ultralisk_attackimpactmelee1.wav",
	"next21_efk/ultralisk/ultralisk_attackimpactmelee2.wav",
	"next21_efk/ultralisk/ultralisk_attackimpactmelee3.wav"
}

new const SOUNDS_ULTRALISK_MOVE[][] =
{
	"next21_efk/ultralisk/ultralisk_movement_00.wav",
	"next21_efk/ultralisk/ultralisk_movement_01.wav",
	"next21_efk/ultralisk/ultralisk_movement_02.wav"
}

new const SOUNDS_ULTRALISK_READY[][] =
{
	"next21_efk/ultralisk/ultralisk_ready0.wav",
	"next21_efk/ultralisk/ultralisk_ready1.wav",
	"next21_efk/ultralisk/ultralisk_ready2.wav"
}

new const SOUNDS_ULTRALISK_BURROW[][] =
{
	"next21_efk/ultralisk/ultralisk_burrow0.wav",
	"next21_efk/ultralisk/ultralisk_burrow1.wav",
	"next21_efk/ultralisk/ultralisk_burrow2.wav",
	"next21_efk/ultralisk/ultralisk_burrow3.wav"
}

new const SOUND_ULTRALISK_RAGE[] = "next21_efk/ultralisk/ultralisk_attack4.wav"

new const SOUNDS_HYDRA_YES[][] =
{
	"next21_efk/hydralisk/hydralisk_yes0.wav",
	"next21_efk/hydralisk/hydralisk_yes1.wav",
	"next21_efk/hydralisk/hydralisk_yes2.wav",
	"next21_efk/hydralisk/hydralisk_yes3.wav",
	"next21_efk/hydralisk/hydralisk_yes4.wav",
	"next21_efk/hydralisk/hydralisk_yes5.wav",
	"next21_efk/hydralisk/hydralisk_yes6.wav"
}

new const SOUNDS_HYDRA_READY[][] =
{
	"next21_efk/hydralisk/hydralisk_ready0.wav",
	"next21_efk/hydralisk/hydralisk_ready1.wav",
	"next21_efk/hydralisk/hydralisk_ready2.wav",
	"next21_efk/hydralisk/hydralisk_ready3.wav"
}

new const SOUNDS_HYDRA_ATTACK[][] =
{
	"next21_efk/hydralisk/hydralisk_attack0.wav",
	"next21_efk/hydralisk/hydralisk_attack1.wav",
	"next21_efk/hydralisk/hydralisk_attack2.wav",
	"next21_efk/hydralisk/hydralisk_attack3.wav",
	"next21_efk/hydralisk/hydralisk_attack4.wav",
	"next21_efk/hydralisk/hydralisk_attack5.wav"
}

new const SOUNDS_HYDRA_DEATH[][] =
{
	"next21_efk/hydralisk/hydralisk_death0.wav",
	"next21_efk/hydralisk/hydralisk_death1.wav",
	"next21_efk/hydralisk/hydralisk_death2.wav",
	"next21_efk/hydralisk/hydralisk_death3.wav"
}

new const SOUNDS_HYDRA_LAUNCH[][] =
{
	"next21_efk/hydralisk/hydralisk_attacklaunchranged0.wav",
	"next21_efk/hydralisk/hydralisk_attacklaunchranged1.wav",
	"next21_efk/hydralisk/hydralisk_attacklaunchranged2.wav",
	"next21_efk/hydralisk/hydralisk_attacklaunchranged3.wav"
}

new const SOUNDS_HYDRA_SPIT_IMPACT[][] =
{
	"next21_efk/hydralisk/hydralisk_attackimpactranged0.wav",
	"next21_efk/hydralisk/hydralisk_attackimpactranged2.wav",
	"next21_efk/hydralisk/hydralisk_attackimpactranged3.wav"
}

enum NecroForm
{
	FORM_ZERGLINGS,
	FORM_HEAVY
}

enum NpcAction
{
	NPC_ACTION_FOLLOW,
	NPC_ACTION_MOVE,
	NPC_ACTION_TARGET,
	NPC_ACTION_SHOOT
}

enum _:PlayerData
{
	bool:PlrIsAlive,
	PlrTeam,
	PlrKnife,
	NpcAction:PlrNpcAction[MAX_MINION_SLOTS],
	PlrNpcActionTarget[MAX_MINION_SLOTS],
	bool:PlrMinionWalking[MAX_MINION_SLOTS],
	PlrMoveWindupTarget[MAX_MINION_SLOTS],
	Float:PlrMoveWindupEndAt[MAX_MINION_SLOTS],
	PlrMoveIgnoreTarget[MAX_MINION_SLOTS],
	Float:PlrMoveIgnoreUntil[MAX_MINION_SLOTS],
	NecroForm:PlrForm,
	PlrMinionEnt[MAX_MINION_SLOTS],
	PlrMinionBarEnt[MAX_MINION_SLOTS],
	Float:PlrMinionRespawnAt[MAX_MINION_SLOTS],
	Float:PlrMinionNextAttackAt[MAX_MINION_SLOTS],
	Float:PlrLastFormSwitch,
	Float:PlrLaserLockTime,
	Float:PlrLaserPendingAt,
	Float:PlrLaserIndicateEndAt,
	Float:PlrLaserLockedEnd[3],
	Float:PlrMinionCharge[MAX_MINION_SLOTS],
	Float:PlrMinionJumpUntil[MAX_MINION_SLOTS],
	PlrJumpPrevAction[MAX_MINION_SLOTS],
	Float:PlrChargeLastTick,
	Float:PlrModeChangeAt,
	bool:PlrModeChangeOrdered,
	bool:PlrHydraForm,
	bool:PlrModeChangeHydra,
	PlrSouls
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	Float:g_fPlayerSpawnTime[MAX_PLAYERS + 1],
	g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
	Float:g_fMinionFrozenUntil[MAX_ENTITIES_NUM + 1], Float:g_fMinionChilledUntil[MAX_ENTITIES_NUM + 1],
	Float:g_fMinionSlowUntil[MAX_ENTITIES_NUM + 1], Float:g_fMinionBlindUntil[MAX_ENTITIES_NUM + 1],
	Float:g_fMinionAcidUntil[MAX_ENTITIES_NUM + 1], Float:g_fMinionPainStart[MAX_ENTITIES_NUM + 1],
	g_iMinionBurnCycles[MAX_ENTITIES_NUM + 1], g_iMinionBurnAttacker[MAX_ENTITIES_NUM + 1],
	Float:g_fMinionBurnNextTick[MAX_ENTITIES_NUM + 1], g_iMinionIceBlock[MAX_ENTITIES_NUM + 1],
	Float:g_fMinionNextMoveVoice[MAX_ENTITIES_NUM + 1], Float:g_fMinionHoldUntil[MAX_ENTITIES_NUM + 1], bool:g_bMinionHoldAcid[MAX_ENTITIES_NUM + 1], bool:g_bMinionHoldNoGlow[MAX_ENTITIES_NUM + 1],
	Float:g_fUltraRageUntil[MAX_ENTITIES_NUM + 1], Float:g_fUltraRageReadyAt[MAX_ENTITIES_NUM + 1], bool:g_bUltraBurrowed[MAX_ENTITIES_NUM + 1], bool:g_bUltraHidden[MAX_ENTITIES_NUM + 1], Float:g_fUltraBuryDoneAt[MAX_ENTITIES_NUM + 1], Float:g_fUltraBurrowToggleAt[MAX_ENTITIES_NUM + 1], g_iUltraBurrowMark[MAX_ENTITIES_NUM + 1], Float:g_fUltraWakeUntil[MAX_ENTITIES_NUM + 1],
	Float:g_fSpitReadyAt[MAX_ENTITIES_NUM + 1], bool:g_bMinionClimb[MAX_ENTITIES_NUM + 1], Float:g_fClimbWallDist[MAX_ENTITIES_NUM + 1], Float:g_vClimbDir[MAX_ENTITIES_NUM + 1][3], Float:g_vClimbFace[MAX_ENTITIES_NUM + 1][3], bool:g_bThinkHeld, bool:g_bMinionDot,
	g_pShockwaveSpr, g_pBloodSpr, g_pBloodSpraySpr, g_pGibs[5], g_pKnifePMdl,
	g_pRockGibsMdl, g_pSmokeSpr, g_pFlameSpr, g_pPointSpr, g_pPointRedSpr, g_pPointYellowSpr, g_pLaserbeamSpr

new Float:g_fNpcActionOrigin[MAX_PLAYERS][MAX_MINION_SLOTS][3]
#define PlrActionOrigin(%1,%2) g_fNpcActionOrigin[%1 - 1][%2]

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_STAB)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH)
	precache_sound(SOUND_KNIFE_DEPLOY)

	for (new i; i < sizeof SOUNDS_CRIT; i++)
		precache_sound(SOUNDS_CRIT[i])

	necro_precache_sounds(SOUNDS_ZERGLING_YES, sizeof SOUNDS_ZERGLING_YES)
	necro_precache_sounds(SOUNDS_ZERGLING_ATTACK, sizeof SOUNDS_ZERGLING_ATTACK)
	necro_precache_sounds(SOUNDS_ZERGLING_DEATH, sizeof SOUNDS_ZERGLING_DEATH)
	necro_precache_sounds(SOUNDS_ZERGLING_MOVE, sizeof SOUNDS_ZERGLING_MOVE)
	necro_precache_sounds(SOUNDS_ZERGLING_HIT, sizeof SOUNDS_ZERGLING_HIT)
	necro_precache_sounds(SOUNDS_ULTRALISK_YES, sizeof SOUNDS_ULTRALISK_YES)
	necro_precache_sounds(SOUNDS_ULTRALISK_ATTACK, sizeof SOUNDS_ULTRALISK_ATTACK)
	necro_precache_sounds(SOUNDS_ULTRALISK_DEATH, sizeof SOUNDS_ULTRALISK_DEATH)
	necro_precache_sounds(SOUNDS_ULTRALISK_HIT, sizeof SOUNDS_ULTRALISK_HIT)
	necro_precache_sounds(SOUNDS_ULTRALISK_MOVE, sizeof SOUNDS_ULTRALISK_MOVE)
	necro_precache_sounds(SOUNDS_ULTRALISK_READY, sizeof SOUNDS_ULTRALISK_READY)
	necro_precache_sounds(SOUNDS_ULTRALISK_BURROW, sizeof SOUNDS_ULTRALISK_BURROW)
	precache_sound(SOUND_ULTRALISK_RAGE)
	g_pRockGibsMdl = precache_model("models/rockgibs.mdl")
	precache_model(MODEL_BURROW_MARK)
	necro_precache_sounds(SOUNDS_HYDRA_YES, sizeof SOUNDS_HYDRA_YES)
	necro_precache_sounds(SOUNDS_HYDRA_READY, sizeof SOUNDS_HYDRA_READY)
	necro_precache_sounds(SOUNDS_HYDRA_ATTACK, sizeof SOUNDS_HYDRA_ATTACK)
	necro_precache_sounds(SOUNDS_HYDRA_DEATH, sizeof SOUNDS_HYDRA_DEATH)
	necro_precache_sounds(SOUNDS_HYDRA_LAUNCH, sizeof SOUNDS_HYDRA_LAUNCH)
	necro_precache_sounds(SOUNDS_HYDRA_SPIT_IMPACT, sizeof SOUNDS_HYDRA_SPIT_IMPACT)
	precache_sound(SOUND_MINION_SWING)

	precache_model(MODEL_ZERGLING)
	precache_model(MODEL_ICEBLOCK)
	precache_sound(SOUND_FROST_HIT)
	precache_sound(SOUND_ICEBLOCK_CRASH)
	g_pFlameSpr = precache_model(SPRITE_FLAME)
	precache_model(MODEL_ULTRALISK)
	precache_model(MODEL_HYDRA)
	precache_model(MODEL_SPIT)
	precache_model(MODEL_MINION_LIFEBAR)
	precache_model(MODEL_MINION_LIFEBAR_B)
	precache_model(MODEL_MINION_LIFEBAR_H)
	precache_model(MODEL_MINION_LIFEBAR_B_H)
	g_iLifebarEnemy = precache_model(MODEL_MINION_LIFEBAR_ENEMY)
	g_iLifebarEnemyHydra = precache_model(MODEL_MINION_LIFEBAR_ENEMY_H)

	precache_sound(SOUND_SOUL)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	g_pBloodSpr = precache_model("sprites/blood.spr")
	g_pBloodSpraySpr = precache_model("sprites/bloodspray.spr")
	g_pGibs[0] = precache_model("models/Fleshgibs.mdl")
	g_pGibs[1] = precache_model("models/GIB_B_Gib.mdl")
	g_pGibs[2] = precache_model("models/GIB_Skull.mdl")
	g_pGibs[3] = precache_model("models/GIB_B_Bone.mdl")
	g_pGibs[4] = precache_model("models/GIB_Lung.mdl")

	g_pShockwaveSpr = precache_model("sprites/shockwave.spr")
	g_pPointSpr = precache_model("sprites/next21_efk/npc_point.spr")
	g_pPointRedSpr = precache_model("sprites/next21_efk/npc_point_red.spr")
	g_pPointYellowSpr = precache_model("sprites/next21_efk/npc_point_yellow.spr")
	g_pLaserbeamSpr = precache_model("sprites/laserbeam.spr")
	g_pSmokeSpr = precache_model("sprites/black_smoke3.spr")
}

new g_trRender
new bool:g_bWaterKnife[MAX_PLAYERS + 1]
#define WATER_KNIFE_CLASSNAME	"weapon_next21_water_r01"
new Float:g_fMoveBlockUntil[MAX_ENTITIES_NUM + 1]

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")
	g_trRender = create_tr2()
	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		engfunc(EngFunc_AllocString, MODEL_V_KNIFE), engfunc(EngFunc_AllocString, MODEL_P_KNIFE),
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, 0.0, ABIL1_TYPE, ABIL1_MINDIST, ABIL1_MAXDIST)
	kc_register_ability4(g_iKnifeId, ABIL4_NAME, ABIL4_CHARGE)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)
	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_HAMMER)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)

	RegisterHookChain(RG_CSGameRules_RestartRound, "RG_CSGameRules_RestartRound_Pre")
	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_ImpulseCommands, "RG_CBasePlayer_ImpulseCommands_Pre", false)
	RegisterHookChain(RG_CBasePlayer_PostThink, "RG_CBasePlayer_PostThink_Pre", false)
	register_forward(FM_AddToFullPack, "necro_AddToFullPack", true)

	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	RegisterHam(Ham_TakeDamage, SZ_EXPLOSION, "npc_TakeDamage")
	RegisterHam(Ham_Classify, SZ_EXPLOSION, "npc_Classify")

	set_task(MINION_STATUS_TICK, "necro_status_tick", TASK_MINION_STATUS, _, _, "b")
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0
	Player[iPlayer][PlrKnife] = -1
	Player[iPlayer][PlrForm] = FORM_ZERGLINGS
	Player[iPlayer][PlrHydraForm] = false
	Player[iPlayer][PlrSouls] = 0
	necro_reset_npc_actions(iPlayer)
	arrayset(Player[iPlayer][PlrMinionEnt], 0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionBarEnt], 0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionRespawnAt], 0.0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionNextAttackAt], 0.0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionCharge], 0.0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionJumpUntil], 0.0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrJumpPrevAction], -1, MAX_MINION_SLOTS)
	Player[iPlayer][PlrChargeLastTick] = 0.0
	Player[iPlayer][PlrLaserPendingAt] = 0.0
	Player[iPlayer][PlrLaserLockTime] = 0.0
	Player[iPlayer][PlrLaserIndicateEndAt] = 0.0
	Player[iPlayer][PlrLastFormSwitch] = 0.0
	Player[iPlayer][PlrModeChangeAt] = 0.0
	Player[iPlayer][PlrModeChangeOrdered] = false
}

necro_reset_form(iPlayer)
{
	Player[iPlayer][PlrLaserPendingAt] = 0.0
	Player[iPlayer][PlrLaserLockTime] = 0.0
	Player[iPlayer][PlrLaserIndicateEndAt] = 0.0
	Player[iPlayer][PlrModeChangeOrdered] = false
	Player[iPlayer][PlrModeChangeAt] = 0.0
	Player[iPlayer][PlrForm] = FORM_ZERGLINGS
	Player[iPlayer][PlrHydraForm] = false
}

necro_reset_npc_actions(iOwner)
{
	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		Player[iOwner][PlrNpcAction][i] = NPC_ACTION_FOLLOW
		Player[iOwner][PlrNpcActionTarget][i] = 0
		Player[iOwner][PlrMinionWalking][i] = false
		Player[iOwner][PlrMoveWindupTarget][i] = 0
		Player[iOwner][PlrMinionCharge][i] = 0.0
		Player[iOwner][PlrMinionJumpUntil][i] = 0.0
		Player[iOwner][PlrJumpPrevAction][i] = -1
		Player[iOwner][PlrMoveIgnoreTarget][i] = 0
		Player[iOwner][PlrMoveIgnoreUntil][i] = 0.0
	}
}

public client_disconnected(iPlayer)
{
	g_bWaterKnife[iPlayer] = false
	clear_npc_action_target(iPlayer)
	kill_all_npc(iPlayer)

	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0
	Player[iPlayer][PlrKnife] = -1

}

public RG_CSGameRules_RestartRound_Pre()
{
	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (Player[iPlayer][PlrKnife] == g_iKnifeId)
		{
			necro_reset_form(iPlayer)
			necro_reset_npc_actions(iPlayer)
			kill_all_npc(iPlayer)
			necro_schedule_form(iPlayer, MINION_SPAWN_DELAY)
		}
	}
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_MINION)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_MINION_SPIT)))
		rg_remove_entity(iEnt)

	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		for (new i; i < MAX_MINION_SLOTS; i++)
			minion_remove_lifebar(iPlayer, i)

		arrayset(Player[iPlayer][PlrMinionEnt], 0, MAX_MINION_SLOTS)
	}
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return HC_CONTINUE

	g_fPlayerSpawnTime[iPlayer] = get_gametime()
	Player[iPlayer][PlrIsAlive] = true
	Player[iPlayer][PlrSouls] = 0
	kill_all_npc(iPlayer)

	if (Player[iPlayer][PlrKnife] == g_iKnifeId)
		necro_schedule_form(iPlayer, MINION_SPAWN_DELAY)

	return HC_CONTINUE
}

public RG_CBasePlayer_ImpulseCommands_Pre(iPlayer)
{
	if (get_entvar(iPlayer, var_impulse) != 201)
		return HC_CONTINUE

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HC_CONTINUE

	new iButtons = get_entvar(iPlayer, var_button)
	if (Player[iPlayer][PlrForm] == FORM_ZERGLINGS)
		necro_order_mode_change(iPlayer)
	else if (iButtons & (IN_USE | IN_RELOAD))
		necro_swap_heavy(iPlayer, bool:(iButtons & IN_RELOAD))
	else
		necro_set_zerglings_mode(iPlayer)

	set_entvar(iPlayer, var_impulse, 0)

	return HC_CONTINUE
}

public RG_CBasePlayer_PostThink_Pre(iPlayer)
{
	if (!Player[iPlayer][PlrIsAlive])
		return HC_CONTINUE

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HC_CONTINUE

	new Float:fGameTime = get_gametime()
	necro_tick(iPlayer, fGameTime)

	static iLastButtons[MAX_PLAYERS + 1], Float:fKeyDownAt[MAX_PLAYERS + 1][MAX_MINION_SLOTS], bool:bKeyUsed[MAX_PLAYERS + 1][MAX_MINION_SLOTS]
	new iButtons = get_entvar(iPlayer, var_button)
	new iPressed = iButtons & ~iLastButtons[iPlayer]
	new iReleased = ~iButtons & iLastButtons[iPlayer]
	iLastButtons[iPlayer] = iButtons
	static const iSlotKeys[MAX_MINION_SLOTS] = {IN_USE, IN_RELOAD}

	for (new iSlot; iSlot < MAX_MINION_SLOTS; iSlot++)
	{
		new iMinionSlot = Player[iPlayer][PlrForm] == FORM_HEAVY ? MINION_SLOT_HEAVY : iSlot

		if (iReleased & iSlotKeys[iSlot])
		{
			if (!bKeyUsed[iPlayer][iSlot] && fGameTime - fKeyDownAt[iPlayer][iSlot] <= FOLLOW_TAP_TIME)
			{
				Player[iPlayer][PlrNpcAction][iMinionSlot] = NPC_ACTION_FOLLOW
				Player[iPlayer][PlrNpcActionTarget][iMinionSlot] = 0
				Player[iPlayer][PlrMinionWalking][iMinionSlot] = true
			}
			continue
		}

		if (!(iButtons & iSlotKeys[iSlot]))
			continue

		new bool:bKeyEdge = bool:(iPressed & iSlotKeys[iSlot])
		if (bKeyEdge)
		{
			fKeyDownAt[iPlayer][iSlot] = fGameTime
			bKeyUsed[iPlayer][iSlot] = false
		}

		new bool:bLmb = bool:((iPressed & IN_ATTACK) || (bKeyEdge && (iButtons & IN_ATTACK)))
		new bool:bRmb = bool:((iPressed & IN_ATTACK2) || (bKeyEdge && (iButtons & IN_ATTACK2)))

		if (bLmb)
		{
			bKeyUsed[iPlayer][iSlot] = true
			necro_command_target(iPlayer, iMinionSlot, iSlot)
		}
		else if (bRmb)
		{
			bKeyUsed[iPlayer][iSlot] = true
			necro_use_ultimate(iPlayer, iMinionSlot, iSlot)
		}
	}

	return HC_CONTINUE
}

necro_restore_after_jump(iOwner, iSlot, iJumpTarget)
{
	new iPrevAction = Player[iOwner][PlrJumpPrevAction][iSlot]
	Player[iOwner][PlrJumpPrevAction][iSlot] = -1

	if (iPrevAction < 0 || Player[iOwner][PlrNpcAction][iSlot] != NPC_ACTION_TARGET
		|| Player[iOwner][PlrNpcActionTarget][iSlot] != iJumpTarget)
		return

	Player[iOwner][PlrNpcAction][iSlot] = NpcAction:iPrevAction
	Player[iOwner][PlrNpcActionTarget][iSlot] = 0
}

necro_use_ultimate(iPlayer, iSlot, iKey)
{
	if (kc_player_in_silence(iPlayer) || kc_player_in_darkness(iPlayer))
		return

	if (Player[iPlayer][PlrForm] != FORM_HEAVY)
		necro_zergling_dash(iPlayer, iSlot)
	else if (Player[iPlayer][PlrHydraForm])
		necro_heavy_laser(iPlayer)
	else if (iKey == 1)
		necro_ultralisk_burrow(iPlayer)
	else
		necro_ultralisk_rage(iPlayer)
}

necro_ultralisk_get(iPlayer)
{
	if (Player[iPlayer][PlrForm] != FORM_HEAVY || Player[iPlayer][PlrHydraForm])
		return 0

	new iMinion = Player[iPlayer][PlrMinionEnt][MINION_SLOT_HEAVY]
	if (!iMinion || !is_entity(iMinion) || (get_entvar(iMinion, var_flags) & FL_KILLME))
		return 0

	return iMinion
}

bool:necro_ultralisk_disabled(iMinion)
{
	return bool:(necro_minion_is_frozen(iMinion) || necro_minion_is_held(iMinion) || necro_minion_is_blind(iMinion) || necro_owner_blind(iMinion) || g_bMinionClimb[iMinion])
}

necro_ultralisk_rage(iPlayer)
{
	new iMinion = necro_ultralisk_get(iPlayer)
	if (!iMinion || g_bUltraBurrowed[iMinion] || g_bMinionClimb[iMinion] || necro_owner_blind(iMinion))
		return

	new Float:fGameTime = get_gametime()
	if (g_fUltraRageReadyAt[iMinion] > fGameTime)
		return

	if (necro_minion_is_frozen(iMinion))
		necro_minion_unfreeze(iMinion)
	g_fMinionHoldUntil[iMinion] = 0.0
	g_fMinionBlindUntil[iMinion] = 0.0
	g_fMinionSlowUntil[iMinion] = 0.0
	g_fMinionChilledUntil[iMinion] = 0.0
	g_fMinionPainStart[iMinion] = 0.0
	necro_minion_update_glow(iMinion)

	g_fUltraRageUntil[iMinion] = fGameTime + ULTRALISK_RAGE_TIME
	g_fUltraRageReadyAt[iMinion] = fGameTime + ULTRALISK_RAGE_COOLDOWN

	set_entvar(iMinion, var_rendermode, kRenderNormal)
	set_entvar(iMinion, var_renderfx, kRenderFxGlowShell)
	set_entvar(iMinion, var_rendercolor, Float:{255.0, 0.0, 0.0})
	set_entvar(iMinion, var_renderamt, 16.0)

	engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUND_ULTRALISK_RAGE, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

bool:necro_rage_active(iMinion)
{
	return bool:(g_fUltraRageUntil[iMinion] > get_gametime())
}

Float:necro_attack_interval(iMinion)
{
	return necro_rage_active(iMinion) ? ULTRALISK_RAGE_ATTACK_INTERVAL : MINION_ATTACK_INTERVAL
}

necro_rage_check_end(iMinion, Float:fGameTime)
{
	if (g_fUltraRageUntil[iMinion] <= 0.0 || fGameTime < g_fUltraRageUntil[iMinion])
		return

	g_fUltraRageUntil[iMinion] = 0.0
	necro_clear_rage_glow(iMinion)
}

necro_clear_rage_glow(iMinion)
{
	new Float:vColor[3]
	get_entvar(iMinion, var_rendercolor, vColor)
	if (get_entvar(iMinion, var_renderfx) == kRenderFxGlowShell && vColor[0] == 255.0 && vColor[1] == 0.0 && vColor[2] == 0.0)
	{
		set_entvar(iMinion, var_renderfx, kRenderFxNone)
		set_entvar(iMinion, var_renderamt, 0.0)
	}
}

necro_burrow_effects(const Float:vOrigin[3])
{
	new aPlayers[MAX_PLAYERS], iPlayerNum
	get_players(aPlayers, iPlayerNum, "c")

	for (new i, iPlayer; i < iPlayerNum; i++)
	{
		iPlayer = aPlayers[i]
		if (kc_player_get_options(iPlayer) & OPTION_DISABLE_PARTICLES)
			continue

		send_msg_TE_BREAKMODEL(vOrigin, Float:{40.0, 40.0, 16.0}, Float:{0.0, 0.0, 40.0}, 30, g_pRockGibsMdl, 20, 30, 0, MSG_ONE_UNRELIABLE, _, iPlayer)
		send_msg_TE_SMOKE(vOrigin, g_pSmokeSpr, random_num(30, 40), 10, MSG_ONE_UNRELIABLE, _, iPlayer)
	}

	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, SOUNDS_ULTRALISK_BURROW[random(sizeof SOUNDS_ULTRALISK_BURROW)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

necro_burrow_create_mark(iMinion, const Float:vOrigin[3])
{
	new iMark = rg_create_entity("info_target")
	if (is_nullent(iMark))
		return

	engfunc(EngFunc_SetModel, iMark, MODEL_BURROW_MARK)
	engfunc(EngFunc_SetSize, iMark, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 4.0})
	set_entvar(iMark, var_skin, Player[get_entvar(iMinion, var_npcowner)][PlrTeam] - 1)
	set_entvar(iMark, var_rendermode, kRenderNormal)
	set_entvar(iMark, var_sequence, 0)
	set_entvar(iMark, var_framerate, 1.0)
	set_entvar(iMark, var_animtime, get_gametime())
	set_entvar(iMark, var_movetype, MOVETYPE_PUSH)
	set_entvar(iMark, var_gravity, 0.0)
	engfunc(EngFunc_SetOrigin, iMark, vOrigin)
	g_iUltraBurrowMark[iMinion] = iMark
	set_entvar(iMark, var_iuser1, iMinion)
	SetThink(iMark, "necro_burrow_mark_think")
	set_entvar(iMark, var_nextthink, get_gametime() + 0.2)
}

public necro_burrow_mark_think(iMark)
{
	new iMinion = get_entvar(iMark, var_iuser1)
	if (!iMinion || !is_entity(iMinion) || (get_entvar(iMinion, var_flags) & FL_KILLME) || !g_bUltraBurrowed[iMinion])
	{
		rg_remove_entity(iMark)
		return
	}

	set_entvar(iMark, var_nextthink, get_gametime() + 0.2)
}

necro_burrow_remove_mark(iMinion)
{
	new iMark = g_iUltraBurrowMark[iMinion]
	g_iUltraBurrowMark[iMinion] = 0
	if (iMark && is_entity(iMark))
		rg_remove_entity(iMark)
}

necro_ultralisk_burrow(iPlayer)
{
	new iMinion = necro_ultralisk_get(iPlayer)
	if (!iMinion)
		return

	new Float:fGameTime = get_gametime()
	if (g_fUltraBurrowToggleAt[iMinion] > fGameTime)
		return

	if (g_bUltraBurrowed[iMinion])
	{
		necro_ultralisk_emerge(iMinion)
		return
	}

	if (necro_ultralisk_disabled(iMinion) || !(get_entvar(iMinion, var_flags) & FL_ONGROUND))
		return

	new Float:vOrigin[3]
	get_entvar(iMinion, var_origin, vOrigin)

	g_bUltraBurrowed[iMinion] = true
	g_fUltraBuryDoneAt[iMinion] = fGameTime + ULTRALISK_BURY_TIME
	g_fUltraBurrowToggleAt[iMinion] = g_fUltraBuryDoneAt[iMinion] + ULTRALISK_BURROW_TOGGLE_PAUSE

	g_fUltraRageUntil[iMinion] = 0.0
	necro_clear_rage_glow(iMinion)

	minion_halt(iMinion)
	set_entvar(iMinion, var_npctarget, 0)

	Player[iPlayer][PlrNpcAction][MINION_SLOT_HEAVY] = NPC_ACTION_MOVE
	Player[iPlayer][PlrNpcActionTarget][MINION_SLOT_HEAVY] = 0
	xs_vec_copy(vOrigin, PlrActionOrigin(iPlayer, MINION_SLOT_HEAVY))

	necro_burrow_effects(vOrigin)
	set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
}

necro_ultralisk_hide(iMinion)
{
	new Float:vOrigin[3]
	get_entvar(iMinion, var_origin, vOrigin)

	g_bUltraHidden[iMinion] = true
	set_entvar(iMinion, var_solid, SOLID_NOT)
	set_entvar(iMinion, var_takedamage, 0.0)
	set_entvar(iMinion, var_effects, get_entvar(iMinion, var_effects) | EF_NODRAW)

	necro_burrow_effects(vOrigin)
	necro_burrow_create_mark(iMinion, vOrigin)
}

necro_ultralisk_emerge(iMinion)
{
	if (!g_bUltraBurrowed[iMinion])
		return

	g_bUltraBurrowed[iMinion] = false
	g_bUltraHidden[iMinion] = false
	g_fUltraBuryDoneAt[iMinion] = 0.0
	g_fUltraBurrowToggleAt[iMinion] = get_gametime() + ULTRALISK_BURROW_TOGGLE_PAUSE
	necro_burrow_remove_mark(iMinion)

	new Float:vOrigin[3]
	get_entvar(iMinion, var_origin, vOrigin)

	set_entvar(iMinion, var_solid, SOLID_BBOX)
	set_entvar(iMinion, var_takedamage, 1.0)
	set_entvar(iMinion, var_effects, get_entvar(iMinion, var_effects) & ~EF_NODRAW)
	necro_spawn_unstick(iMinion, vOrigin)
	set_entvar(iMinion, var_origin, vOrigin)

	new i
	for (i = 1; i <= MaxClients; i++)
		if (Player[i][PlrIsAlive])
			check_stuck(i, iMinion, vOrigin)

	necro_burrow_effects(vOrigin)

	new Float:fGameTime = get_gametime()
	necro_voice_ready(iMinion)
	g_fUltraWakeUntil[iMinion] = fGameTime + ULTRALISK_WAKE_TIME
	set_entvar(iMinion, var_fuser4, fGameTime + ULTRALISK_WAKE_TIME)
	set_entvar(iMinion, var_animtime, fGameTime)
	set_entvar(iMinion, var_frame, 0.0)
	set_entvar(iMinion, var_framerate, 1.0)
	set_entvar(iMinion, var_sequence, 1)
	set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
}

necro_burrow_think(iMinion, Float:fGameTime)
{
	minion_halt(iMinion)

	new Float:fMaxHealth = necro_minion_max_health(iMinion)
	new Float:fHealth = Float:get_entvar(iMinion, var_health)
	if (fHealth < fMaxHealth)
	{
		new Float:fLastRegen = Float:get_entvar(iMinion, var_fuser2)
		new Float:fDt = fLastRegen > 0.0 ? floatmin(fGameTime - fLastRegen, 1.0) : 0.0
		set_entvar(iMinion, var_health, floatmin(fMaxHealth, fHealth + MINION_REGEN_RATE * ULTRALISK_BURROW_REGEN_MUL * fDt))
	}
	set_entvar(iMinion, var_fuser2, fGameTime)

	new iOwner = get_entvar(iMinion, var_npcowner), iSlot = MINION_SLOT_HEAVY
	if (Player[iOwner][PlrMinionEnt][iSlot] == iMinion)
		minion_update_lifebar(iOwner, iSlot)

	set_entvar(iMinion, var_nextthink, fGameTime + 0.1)
}

necro_zergling_dash(iPlayer, iSlot)
{
	if (Player[iPlayer][PlrMinionCharge][iSlot] < 100.0)
		return

	new iMinion = Player[iPlayer][PlrMinionEnt][iSlot]
	if (!iMinion || !is_entity(iMinion) || (get_entvar(iMinion, var_flags) & FL_KILLME) || necro_minion_is_frozen(iMinion) || necro_minion_is_held(iMinion) || necro_minion_is_blind(iMinion) || necro_owner_blind(iMinion))
		return

	new Float:fGameTime = get_gametime()
	if (Player[iPlayer][PlrMinionJumpUntil][iSlot] > fGameTime)
		return

	new Float:vOrigin[3], Float:vTargetOrigin[3], Float:vAimOrigin[3]
	get_entvar(iMinion, var_origin, vOrigin)

	new iAimEnt = rg_get_aim_origin(iPlayer, vAimOrigin)
	new iTarget
	if (necro_is_enemy_entity(iPlayer, iAimEnt) && !(get_entvar(iAimEnt, var_flags) & FL_KILLME))
	{
		get_entvar(iAimEnt, var_origin, vTargetOrigin)
		if (get_distance_f(vOrigin, vTargetOrigin) <= MINION_TARGET_RADIUS)
			iTarget = iAimEnt
	}

	if (!iTarget)
	{
		new iCurrent = Player[iPlayer][PlrNpcAction][iSlot] == NPC_ACTION_TARGET ? Player[iPlayer][PlrNpcActionTarget][iSlot] : 0
		new Float:fBest = MINION_TARGET_RADIUS, Float:vCandidate[3]
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!necro_is_enemy_entity(iPlayer, i) || kc_player_get_visibility(i) >= VIS_TRANS)
				continue

			get_entvar(i, var_origin, vCandidate)
			new Float:fDist = get_distance_f(vOrigin, vCandidate)
			if (i == iCurrent)
				fDist = 0.0

			if (fDist <= fBest)
			{
				fBest = fDist
				iTarget = i
				xs_vec_copy(vCandidate, vTargetOrigin)
			}
		}

		new iEnemyMinion = NULLENT
		while ((iEnemyMinion = rg_find_ent_by_class(iEnemyMinion, _CLASSNAME_MINION)))
		{
			if (!necro_is_enemy_entity(iPlayer, iEnemyMinion) || (get_entvar(iEnemyMinion, var_flags) & FL_KILLME))
				continue

			get_entvar(iEnemyMinion, var_origin, vCandidate)
			new Float:fDist = get_distance_f(vOrigin, vCandidate)
			if (iEnemyMinion == iCurrent)
				fDist = 0.0

			if (fDist <= fBest)
			{
				fBest = fDist
				iTarget = iEnemyMinion
				xs_vec_copy(vCandidate, vTargetOrigin)
			}
		}
	}

	if (!iTarget)
		return

	new Float:vVelocity[3]
	xs_vec_sub(vTargetOrigin, vOrigin, vVelocity)
	new Float:fDistance = xs_vec_len(vVelocity)
	if (fDistance < 1.0)
		return

	new bool:bFromWall = g_bMinionClimb[iMinion]
	necro_climb_end(iMinion)
	npc_TurnToTarget(iMinion, vOrigin, vTargetOrigin)
	if (bFromWall)
	{
		vVelocity[2] += fDistance * CLIMB_DASH_AIM_LIFT
		fDistance = xs_vec_len(vVelocity)
	}

	xs_vec_mul_scalar(vVelocity, ZERGLING_JUMP_SPEED / fDistance, vVelocity)
	if (!bFromWall)
		vVelocity[2] = floatmax(vVelocity[2] + ZERGLING_JUMP_LIFT, ZERGLING_JUMP_LIFT)
	set_entvar(iMinion, var_velocity, vVelocity)
	set_entvar(iMinion, var_flags, get_entvar(iMinion, var_flags) & ~FL_ONGROUND)

	Player[iPlayer][PlrJumpPrevAction][iSlot] = Player[iPlayer][PlrNpcAction][iSlot] == NPC_ACTION_TARGET
		? -1 : _:Player[iPlayer][PlrNpcAction][iSlot]
	Player[iPlayer][PlrNpcAction][iSlot] = NPC_ACTION_TARGET
	Player[iPlayer][PlrNpcActionTarget][iSlot] = iTarget
	Player[iPlayer][PlrMinionJumpUntil][iSlot] = fGameTime + ZERGLING_JUMP_MAX_TIME
	Player[iPlayer][PlrMinionCharge][iSlot] = 0.0

	necro_voice_attack(iMinion)
}

necro_command_target(iPlayer, iSlot, iKey)
{
	if (g_bUltraBurrowed[Player[iPlayer][PlrMinionEnt][iSlot]])
		return

	new Float:vAimOrigin[3], Float:vPlayerOrigin[3]
	new iAimEnt = rg_get_aim_origin(iPlayer, vAimOrigin)
	get_entvar(iPlayer, var_origin, vPlayerOrigin)

	new Float:fAimDistance = get_distance_f(vPlayerOrigin, vAimOrigin)

	new bool:bTargetable = bool:(necro_is_enemy_entity(iPlayer, iAimEnt)
		|| (is_entity(iAimEnt) && get_entvar(iAimEnt, var_impulse) == IMPULSE_PRESENT
			&& !(get_entvar(iAimEnt, var_flags) & FL_KILLME)))

	new bool:bShoot = bool:(iKey == 1 && Player[iPlayer][PlrForm] == FORM_HEAVY && Player[iPlayer][PlrHydraForm])
	new Float:fShootRange = HYDRA_SPIT_RANGE
	if (bShoot && (!bTargetable || fAimDistance > fShootRange))
		return

	if (bTargetable)
	{
		if (fAimDistance > (bShoot ? fShootRange : MINION_TARGET_RADIUS))
			return
		Player[iPlayer][PlrJumpPrevAction][iSlot] = -1
		Player[iPlayer][PlrNpcAction][iSlot] = bShoot ? NPC_ACTION_SHOOT : NPC_ACTION_TARGET
		Player[iPlayer][PlrNpcActionTarget][iSlot] = iAimEnt
	}
	else
	{
		if (bShoot)
			return

		if (fAimDistance > MINION_MOVE_COMMAND_RANGE)
			return

		new iBlocked = Player[iPlayer][PlrMinionEnt][iSlot]
		if (iBlocked && g_fMoveBlockUntil[iBlocked] > get_gametime())
			return

		Player[iPlayer][PlrNpcAction][iSlot] = NPC_ACTION_MOVE
		Player[iPlayer][PlrNpcActionTarget][iSlot] = 0
		xs_vec_copy(vAimOrigin, PlrActionOrigin(iPlayer, iSlot))
	}

	new Float:vSpriteOrigin[3]
	xs_vec_copy(vAimOrigin, vSpriteOrigin)
	vSpriteOrigin[2] += 30.0
	send_msg_TE_SPRITE(vSpriteOrigin, bShoot ? g_pPointYellowSpr : (necro_is_enemy_entity(iPlayer, iAimEnt) ? g_pPointRedSpr : g_pPointSpr), 8, 100, MSG_ONE, _, iPlayer)

	new iMinion = Player[iPlayer][PlrMinionEnt][iSlot]
	if (iMinion && is_entity(iMinion) && !(get_entvar(iMinion, var_flags) & FL_KILLME))
	{
		if (bTargetable)
			necro_voice_attack(iMinion)
		else
			necro_voice_yes(iMinion)
	}
}

public fw_PlayerKilled(iVictim, iAttacker)
{
	Player[iVictim][PlrIsAlive] = false
	Player[iVictim][PlrSouls] = 0
	clear_npc_action_target(iVictim)

	if (is_entity_player(iAttacker))
	{
		if (iAttacker != iVictim && Player[iAttacker][PlrKnife] == g_iKnifeId)
		{
			Player[iAttacker][PlrSouls] = min(5, Player[iAttacker][PlrSouls] + 1)
			necro_register_kill(iAttacker)
		}
	}

	if (Player[iVictim][PlrKnife] == g_iKnifeId)
	{
		Player[iVictim][PlrLaserPendingAt] = 0.0
		Player[iVictim][PlrLaserLockTime] = 0.0
		Player[iVictim][PlrLaserIndicateEndAt] = 0.0
		Player[iVictim][PlrModeChangeOrdered] = false
		Player[iVictim][PlrModeChangeAt] = 0.0
		necro_reset_npc_actions(iVictim)
		necro_execute_minions(iVictim)
		kill_all_npc(iVictim)
		necro_schedule_form(iVictim, MINION_SPAWN_DELAY)
	}
}

public efk_player_change_team(iPlayer, iTeam)
{
	if (Player[iPlayer][PlrTeam] != iTeam && Player[iPlayer][PlrKnife] == g_iKnifeId)
		kill_all_npc(iPlayer)

	Player[iPlayer][PlrTeam] = iTeam
	if (Player[iPlayer][PlrIsAlive] && Player[iPlayer][PlrKnife] == g_iKnifeId)
		necro_schedule_form(iPlayer, MINION_SPAWN_DELAY)
}

necro_respawn_percent(iPlayer, iSlot)
{
	new Float:fRespawnAt = Player[iPlayer][PlrMinionRespawnAt][iSlot]
	if (fRespawnAt <= 0.0)
		return 0

	return clamp(floatround((1.0 - floatmax(0.0, fRespawnAt - get_gametime()) / MINION_RESPAWN_TIME) * 100.0), 0, 99)
}

necro_schedule_form(iPlayer, Float:fDelay)
{
	new Float:fRespawnAt = get_gametime() + fDelay
	for (new i; i < MAX_MINION_SLOTS; i++)
		Player[iPlayer][PlrMinionRespawnAt][i] = Player[iPlayer][PlrForm] == FORM_HEAVY && i == 1 ? 0.0 : fRespawnAt
}

necro_register_kill(iOwner)
{
	if (!is_entity_player(iOwner))
		return

	new Float:fGameTime = get_gametime()
	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		if (Player[iOwner][PlrMinionRespawnAt][i] > fGameTime)
			Player[iOwner][PlrMinionRespawnAt][i] = floatmax(fGameTime, Player[iOwner][PlrMinionRespawnAt][i] - 5.0)
	}
}

Float:necro_get_move_speed(iMinion, bool:bReturning=false)
{
	if (necro_rage_active(iMinion))
		return ULTRALISK_RAGE_SPEED

	new Float:fSpeed = bReturning ? MINION_RETURN_SPEED : MINION_SPEED
	new Float:fMul = 1.0
	if (necro_minion_is_chilled(iMinion))
		fMul = MINION_CHILL_SPEED_MUL
	if (g_fMinionSlowUntil[iMinion] > get_gametime())
		fMul = floatmin(fMul, MINION_SLOW_SPEED_MUL)

	new Float:fPainElapsed = get_gametime() - g_fMinionPainStart[iMinion]
	if (fPainElapsed < MINION_PAIN_TIME)
		fMul = floatmin(fMul, MINION_PAIN_MIN_MUL + (1.0 - MINION_PAIN_MIN_MUL) * fPainElapsed / MINION_PAIN_TIME)

	fSpeed *= fMul

	return fSpeed
}

bool:necro_find_minion_slot(iEnt, &iOwner, &iSlot)
{
	for (iOwner = 1; iOwner <= MaxClients; iOwner++)
	{
		for (iSlot = 0; iSlot < MAX_MINION_SLOTS; iSlot++)
		{
			if (Player[iOwner][PlrMinionEnt][iSlot] == iEnt)
				return true
		}
	}

	return false
}

necro_tick(iPlayer, Float:fGameTime)
{
	if (Player[iPlayer][PlrModeChangeAt] > 0.0 && Player[iPlayer][PlrModeChangeAt] <= fGameTime)
	{
		Player[iPlayer][PlrModeChangeAt] = 0.0
		necro_finish_mode_change(iPlayer)
	}

	if (Player[iPlayer][PlrModeChangeOrdered] && !necro_form_complete(iPlayer))
	{
		Player[iPlayer][PlrModeChangeOrdered] = false
		Player[iPlayer][PlrModeChangeAt] = 0.0
	}

	if (Player[iPlayer][PlrLaserPendingAt] > 0.0)
	{
		if (kc_player_in_silence(iPlayer) || kc_player_in_darkness(iPlayer) || kc_player_get_vision(iPlayer) == VISION_BLIND)
		{
			Player[iPlayer][PlrLaserPendingAt] = 0.0
			Player[iPlayer][PlrLaserLockTime] = 0.0
			necro_clear_laser_glow(iPlayer)
		}
		else
		{
			necro_track_laser_aim(iPlayer)
			if (Player[iPlayer][PlrLaserPendingAt] <= fGameTime)
			{
				Player[iPlayer][PlrLaserPendingAt] = 0.0
				necro_start_laser_indicate(iPlayer)
			}
		}
	}
	else if (Player[iPlayer][PlrLaserIndicateEndAt] > 0.0 && Player[iPlayer][PlrLaserIndicateEndAt] <= fGameTime)
	{
		Player[iPlayer][PlrLaserIndicateEndAt] = 0.0
		if (kc_player_get_vision(iPlayer) != VISION_BLIND)
			necro_fire_heavy_laser(iPlayer)
		necro_clear_laser_glow(iPlayer)
		Player[iPlayer][PlrLaserLockTime] = fGameTime + 1.0
	}


	new Float:fChargeDt = Player[iPlayer][PlrChargeLastTick] > 0.0 ? floatmin(fGameTime - Player[iPlayer][PlrChargeLastTick], 0.5) : 0.0
	Player[iPlayer][PlrChargeLastTick] = fGameTime
	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		new iChargeEnt = Player[iPlayer][PlrMinionEnt][i]
		if (iChargeEnt && is_entity(iChargeEnt) && !(get_entvar(iChargeEnt, var_flags) & FL_KILLME))
			Player[iPlayer][PlrMinionCharge][i] = floatmin(100.0, Player[iPlayer][PlrMinionCharge][i] + ABIL1_CHARGE * fChargeDt)
	}

	new szSoulHint[24]
	if (Player[iPlayer][PlrSouls])
		formatex(szSoulHint, charsmax(szSoulHint), "+%dHP", floatround(SOUL_HEAL_VALUE * Player[iPlayer][PlrSouls]))
	kc_player_set_abil4_hint(iPlayer, szSoulHint)

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		if (Player[iPlayer][PlrForm] == FORM_HEAVY && i == 1)
			continue

		new iMinionEnt = Player[iPlayer][PlrMinionEnt][i]
		if (iMinionEnt && (!is_entity(iMinionEnt) || (get_entvar(iMinionEnt, var_flags) & FL_KILLME)))
		{
			minion_remove_lifebar(iPlayer, i)
			Player[iPlayer][PlrMinionEnt][i] = 0
			Player[iPlayer][PlrMinionNextAttackAt][i] = 0.0
			if (Player[iPlayer][PlrMinionRespawnAt][i] <= 0.0)
				Player[iPlayer][PlrMinionRespawnAt][i] = fGameTime + MINION_RESPAWN_TIME
		}

		if (Player[iPlayer][PlrMinionEnt][i])
			minion_update_lifebar(iPlayer, i)

		if (!Player[iPlayer][PlrMinionEnt][i] && Player[iPlayer][PlrMinionRespawnAt][i] > 0.0
			&& Player[iPlayer][PlrMinionRespawnAt][i] <= fGameTime)
		{
			if (minion_spawn_slot(iPlayer, i))
				Player[iPlayer][PlrMinionRespawnAt][i] = 0.0
		}
	}
}

public efk_ability4(iPlayer)
{
	if (!Player[iPlayer][PlrSouls] || kc_player_in_silence(iPlayer) || kc_player_get_capture(iPlayer) != CAPTURE_NONE)
		return PLUGIN_HANDLED

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	new Float:fHeal = SOUL_HEAL_VALUE * Player[iPlayer][PlrSouls]
	new iEnt = NULLENT

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SOUL, 1.0, ATTN_NORM, 0, PITCH_NORM)
	new Float:vAxis[3]
	xs_vec_copy(vOrigin, vAxis)
	vAxis[2] += 255.0
	send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, g_pShockwaveSpr, 0, 0, 2, 5, 0, {0, 255, 0}, 180, 0)

	while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, SOUL_HEAL_RADIUS)))
	{
		if (is_entity_player(iEnt))
		{
			if (Player[iEnt][PlrIsAlive] && Player[iEnt][PlrTeam] == Player[iPlayer][PlrTeam])
				kc_player_heal(iEnt, fHeal, iPlayer)
		}
	}

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		new iMinion = Player[iPlayer][PlrMinionEnt][i]
		if (!iMinion || !is_entity(iMinion) || (get_entvar(iMinion, var_flags) & FL_KILLME))
			continue

		new Float:fMaxHealth = necro_minion_max_health(iMinion)
		set_entvar(iMinion, var_health, floatmin(Float:get_entvar(iMinion, var_health) + fHeal, fMaxHealth))
	}

	Player[iPlayer][PlrSouls] = 0
	return PLUGIN_CONTINUE
}

minion_update_lifebar(iOwner, iSlot)
{
	new iBar = Player[iOwner][PlrMinionBarEnt][iSlot]
	new iMinion = Player[iOwner][PlrMinionEnt][iSlot]
	if (!iBar || !iMinion || is_nullent(iBar) || is_nullent(iMinion))
		return

	new Float:fMaxHealth = necro_minion_max_health(iMinion)
	new Float:fHealth = floatmax(0.0, Float:get_entvar(iMinion, var_health))
	set_entvar(iBar, var_frame, floatclamp(fHealth * 100.0 / fMaxHealth, 0.0, 99.0))
}

minion_create_lifebar(iOwner, iSlot, iMinion)
{
	new iBar = rg_create_entity(SZ_ENV_SPRITE)
	if (is_nullent(iBar))
		return

	new bool:bHydra = get_entvar(iMinion, var_npctype) != 0
	if (iSlot == 1)
		engfunc(EngFunc_SetModel, iBar, bHydra ? MODEL_MINION_LIFEBAR_B_H : MODEL_MINION_LIFEBAR_B)
	else
		engfunc(EngFunc_SetModel, iBar, bHydra ? MODEL_MINION_LIFEBAR_H : MODEL_MINION_LIFEBAR)
	set_entvar(iBar, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iBar, var_aiment, iMinion)
	new Float:vBarOfs[3]
	vBarOfs[2] = 48.0
	set_entvar(iBar, var_view_ofs, vBarOfs)
	set_entvar(iBar, var_scale, 0.15)
	set_entvar(iBar, var_effects, 0)
	set_entvar(iBar, var_rendercolor, Float:{0.0, 255.0, 0.0})
	set_entvar(iBar, var_rendermode, kRenderNormal)
	set_entvar(iBar, var_impulse, IMPULSE_NECRO_LIFEBAR)
	Player[iOwner][PlrMinionBarEnt][iSlot] = iBar
	minion_update_lifebar(iOwner, iSlot)
}

minion_remove_lifebar(iOwner, iSlot)
{
	new iBar = Player[iOwner][PlrMinionBarEnt][iSlot]
	if (iBar && !is_nullent(iBar))
		rg_remove_entity(iBar)
	Player[iOwner][PlrMinionBarEnt][iSlot] = 0
}

public necro_AddToFullPack(es_state, e, ent, host, hostflags, player)
{
	if (is_nullent(ent))
		return FMRES_IGNORED

	if (player)
		return FMRES_IGNORED

	new iImpulse = get_entvar(ent, var_impulse)

	if (iImpulse == IMPULSE_MINION)
	{
		new Float:vVariant[3]
		get_entvar(ent, var_vuser1, vVariant)
		if (vVariant[0] > 0.5)
			set_es(es_state, ES_Skin, get_entvar(ent, var_skin) + 2)

		if (g_bMinionClimb[ent])
		{
			new Float:vRenderOrigin[3], Float:vShift[3], Float:vProbeStart[3], Float:vProbeEnd[3], Float:fFraction
			get_es(es_state, ES_Origin, vRenderOrigin)
			get_entvar(ent, var_origin, vProbeStart)
			vProbeStart[2] += 4.0
			xs_vec_mul_scalar(g_vClimbDir[ent], necro_wall_reach(ent), vProbeEnd)
			xs_vec_add(vProbeStart, vProbeEnd, vProbeEnd)
			engfunc(EngFunc_TraceLine, vProbeStart, vProbeEnd, IGNORE_MONSTERS, ent, g_trRender)
			get_tr2(g_trRender, TR_flFraction, fFraction)
			xs_vec_mul_scalar(g_vClimbDir[ent], floatclamp(fFraction * necro_wall_reach(ent) - CLIMB_MODEL_MARGIN, 0.0, CLIMB_MODEL_SHIFT), vShift)
			xs_vec_add(vRenderOrigin, vShift, vRenderOrigin)
			set_es(es_state, ES_Origin, vRenderOrigin)
		}

		return FMRES_IGNORED
	}

	if (iImpulse != IMPULSE_NECRO_LIFEBAR)
		return FMRES_IGNORED

	new iMinion = get_entvar(ent, var_aiment)
	new iOwner = is_entity(iMinion) ? get_entvar(iMinion, var_npcowner) : 0
	if (!is_entity_player(host) || !is_entity_player(iOwner))
	{
		set_es(es_state, ES_Effects, EF_NODRAW)
		return FMRES_IGNORED
	}

	if (g_bUltraHidden[iMinion] && Player[host][PlrTeam] != Player[iOwner][PlrTeam])
	{
		set_es(es_state, ES_Effects, EF_NODRAW)
		return FMRES_IGNORED
	}

	if (host != iOwner && get_entvar(host, var_iuser2) != iOwner
		&& !(Player[host][PlrTeam] != Player[iOwner][PlrTeam] && kc_player_has_hpscan(host))
		&& !(Player[host][PlrTeam] == Player[iOwner][PlrTeam] && g_bWaterKnife[host]))
	{
		set_es(es_state, ES_Effects, EF_NODRAW)
		return FMRES_IGNORED
	}

	if (Player[host][PlrTeam] != Player[iOwner][PlrTeam])
		set_es(es_state, ES_ModelIndex, get_entvar(iMinion, var_npctype) ? g_iLifebarEnemyHydra : g_iLifebarEnemy)
	else
		set_es(es_state, ES_ModelIndex, get_entvar(ent, var_modelindex))
	set_es(es_state, ES_Effects, get_es(es_state, ES_Effects) & ~EF_NODRAW)
	set_es(es_state, ES_RenderColor, Float:{0.0, 255.0, 0.0})
	return FMRES_IGNORED
}

bool:necro_find_spawn_point(const Float:vBase[3], Float:fYaw, iIgnoreEnt, Float:vResult[3])
{
	new bool:bVacant
	new Float:vCandidate[3]

	xs_vec_copy(vBase, vCandidate)
	vCandidate[0] += floatcos(fYaw, degrees) * MINION_SPAWN_DISTANCE
	vCandidate[1] += floatsin(fYaw, degrees) * MINION_SPAWN_DISTANCE
	vCandidate[2] += 5.0
	bVacant = bool:is_hull_vacant(vCandidate, HULL_LARGE, iIgnoreEnt)

	if (!bVacant)
	{
		new Float:fBackYaw = fYaw + 180.0
		xs_vec_copy(vBase, vCandidate)
		vCandidate[0] += floatcos(fBackYaw, degrees) * MINION_SPAWN_DISTANCE
		vCandidate[1] += floatsin(fBackYaw, degrees) * MINION_SPAWN_DISTANCE
		vCandidate[2] += 5.0
		bVacant = bool:is_hull_vacant(vCandidate, HULL_LARGE, iIgnoreEnt)
	}

	if (!bVacant)
	{
		for (new i; i < 8; i++)
		{
			new Float:fScanYaw = i * 45.0
			xs_vec_copy(vBase, vCandidate)
			vCandidate[0] += floatcos(fScanYaw, degrees) * MINION_SPAWN_DISTANCE
			vCandidate[1] += floatsin(fScanYaw, degrees) * MINION_SPAWN_DISTANCE
			vCandidate[2] += 5.0
			if (is_hull_vacant(vCandidate, HULL_LARGE, iIgnoreEnt))
			{
				bVacant = true
				break
			}
		}
	}

	if (!bVacant)
		return false

	xs_vec_copy(vCandidate, vResult)
	return true
}

bool:minion_spawn_slot(iOwner, iSlot)
{
	if (!Player[iOwner][PlrIsAlive] || Player[iOwner][PlrKnife] != g_iKnifeId)
		return false

	new Float:vOrigin[3], Float:vAngles[3]
	get_entvar(iOwner, var_origin, vOrigin)
	get_entvar(iOwner, var_v_angle, vAngles)
	vAngles[0] = vAngles[2] = 0.0

	new Float:fYaw = vAngles[1] + (iSlot == 0 ? MINION_SPAWN_ANGLE : -MINION_SPAWN_ANGLE)

	new Float:vSpawnOrigin[3]
	if (!necro_find_spawn_point(vOrigin, fYaw, iOwner, vSpawnOrigin))
		return false

	new iEnt
	if (Player[iOwner][PlrForm] == FORM_HEAVY)
		iEnt = create_heavy(vSpawnOrigin, vAngles, 0.0, iOwner, Player[iOwner][PlrHydraForm])
	else
		iEnt = create_zergling(vSpawnOrigin, vAngles, iOwner, iSlot)

	if (is_nullent(iEnt))
		return false

	Player[iOwner][PlrMinionEnt][iSlot] = iEnt
	minion_create_lifebar(iOwner, iSlot, iEnt)
	return true
}

bool:necro_order_mode_change(iOwner)
{
	if (!(get_entvar(iOwner, var_button) & (IN_USE | IN_RELOAD)))
		return false

	if (!Player[iOwner][PlrIsAlive] || Player[iOwner][PlrKnife] != g_iKnifeId
		|| Player[iOwner][PlrForm] != FORM_ZERGLINGS || !necro_form_complete(iOwner)
		|| kc_player_in_silence(iOwner) || kc_player_in_darkness(iOwner))
		return false

	if (get_gametime() - Player[iOwner][PlrLastFormSwitch] < FORM_SWITCH_COOLDOWN)
		return false

	new iZerglingA = Player[iOwner][PlrMinionEnt][0]
	new iZerglingB = Player[iOwner][PlrMinionEnt][1]
	if (g_bMinionClimb[iZerglingA] || g_bMinionClimb[iZerglingB] || !(get_entvar(iZerglingA, var_flags) & FL_ONGROUND) || !(get_entvar(iZerglingB, var_flags) & FL_ONGROUND))
		return false

	Player[iOwner][PlrModeChangeOrdered] = true
	Player[iOwner][PlrModeChangeHydra] = bool:(get_entvar(iOwner, var_button) & IN_RELOAD)
	return true
}

bool:necro_finish_mode_change(iOwner)
{
	if (kc_player_in_silence(iOwner) || kc_player_in_darkness(iOwner))
		return false

	new iZerglingA = Player[iOwner][PlrMinionEnt][0]
	new iZerglingB = Player[iOwner][PlrMinionEnt][1]

	if (!iZerglingA || !iZerglingB || !is_entity(iZerglingA) || !is_entity(iZerglingB)
		|| (get_entvar(iZerglingA, var_flags) & FL_KILLME) || (get_entvar(iZerglingB, var_flags) & FL_KILLME))
		return false

	if (g_bMinionClimb[iZerglingA] || g_bMinionClimb[iZerglingB] || !(get_entvar(iZerglingA, var_flags) & FL_ONGROUND) || !(get_entvar(iZerglingB, var_flags) & FL_ONGROUND))
		return false

	new Float:vOrigin[3], Float:vAngles[3]
	get_entvar(iZerglingA, var_origin, vOrigin)
	get_entvar(iZerglingA, var_angles, vAngles)
	vAngles[0] = vAngles[2] = 0.0

	new bool:bHydra = Player[iOwner][PlrModeChangeHydra]
	Player[iOwner][PlrModeChangeHydra] = false

	new Float:fNewMax = bHydra ? HYDRA_HEALTH : HEAVY_HEALTH
	new Float:fHealth = floatmin(fNewMax, Float:get_entvar(iZerglingA, var_health) + Float:get_entvar(iZerglingB, var_health))

	new Float:fModeCharge = (Player[iOwner][PlrMinionCharge][0] + Player[iOwner][PlrMinionCharge][1]) / 2.0

	ExecuteHamB(Ham_TakeDamage, iZerglingA, 0, iZerglingA, 9000.0, DMG_BLAST)
	ExecuteHamB(Ham_TakeDamage, iZerglingB, 0, iZerglingB, 9000.0, DMG_BLAST)

	arrayset(Player[iOwner][PlrMinionRespawnAt], 0.0, MAX_MINION_SLOTS)
	Player[iOwner][PlrLaserPendingAt] = 0.0
	Player[iOwner][PlrLaserLockTime] = 0.0

	Player[iOwner][PlrForm] = FORM_HEAVY
	Player[iOwner][PlrHydraForm] = bHydra

	new iHeavy = create_heavy(vOrigin, vAngles, fHealth, iOwner, bHydra)
	if (!is_nullent(iHeavy))
	{
		Player[iOwner][PlrMinionEnt][MINION_SLOT_HEAVY] = iHeavy
		minion_create_lifebar(iOwner, MINION_SLOT_HEAVY, iHeavy)
	}

	Player[iOwner][PlrLastFormSwitch] = get_gametime()
	necro_reset_npc_actions(iOwner)
	Player[iOwner][PlrMinionCharge][MINION_SLOT_HEAVY] = fModeCharge
	Player[iOwner][PlrModeChangeOrdered] = false
	return true
}

bool:necro_form_complete(iPlayer)
{
	if (Player[iPlayer][PlrForm] == FORM_HEAVY)
	{
		new iHeavy = Player[iPlayer][PlrMinionEnt][MINION_SLOT_HEAVY]
		return bool:(iHeavy && is_entity(iHeavy) && !(get_entvar(iHeavy, var_flags) & FL_KILLME))
	}

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		new iMinion = Player[iPlayer][PlrMinionEnt][i]
		if (!iMinion || !is_entity(iMinion) || (get_entvar(iMinion, var_flags) & FL_KILLME))
			return false
	}

	return true
}

necro_spawn_zergling_mode(iOwner, iSlot, const Float:vBase[3], Float:vAngles[3], Float:fHealth, Float:fYaw)
{
	new Float:vSpawn[3], iMinion = 0
	if (necro_find_spawn_point(vBase, fYaw, iOwner, vSpawn))
		iMinion = create_zergling(vSpawn, vAngles, iOwner, iSlot)

	if (!is_nullent(iMinion))
	{
		set_entvar(iMinion, var_health, fHealth)
		Player[iOwner][PlrMinionEnt][iSlot] = iMinion
		minion_create_lifebar(iOwner, iSlot, iMinion)
	}
	else
		Player[iOwner][PlrMinionRespawnAt][iSlot] = get_gametime() + 0.5
}

bool:necro_swap_heavy(iOwner, bool:bHydra)
{
	if (!Player[iOwner][PlrIsAlive] || Player[iOwner][PlrKnife] != g_iKnifeId || Player[iOwner][PlrForm] != FORM_HEAVY)
		return false

	if (Player[iOwner][PlrHydraForm] == bHydra)
		return false

	if (kc_player_in_silence(iOwner) || kc_player_in_darkness(iOwner))
		return false

	if (get_gametime() - Player[iOwner][PlrLastFormSwitch] < FORM_SWITCH_COOLDOWN)
		return false

	new iOld = Player[iOwner][PlrMinionEnt][MINION_SLOT_HEAVY]
	if (!iOld || !is_entity(iOld) || (get_entvar(iOld, var_flags) & FL_KILLME))
		return false

	if (g_bUltraBurrowed[iOld] || g_bMinionClimb[iOld] || !(get_entvar(iOld, var_flags) & FL_ONGROUND))
		return false

	new Float:fGameTime = get_gametime()
	new Float:vOrigin[3], Float:vAngles[3]
	get_entvar(iOld, var_origin, vOrigin)
	get_entvar(iOld, var_angles, vAngles)
	vAngles[0] = vAngles[2] = 0.0

	new Float:fNewMax = bHydra ? HYDRA_HEALTH : HEAVY_HEALTH
	new Float:fHealth = floatmin(fNewMax, Float:get_entvar(iOld, var_health))
	new Float:fCharge = Player[iOwner][PlrMinionCharge][MINION_SLOT_HEAVY]

	necro_voice_death(iOld)
	create_gore(vOrigin)

	minion_remove_lifebar(iOwner, MINION_SLOT_HEAVY)
	Player[iOwner][PlrMinionEnt][MINION_SLOT_HEAVY] = 0
	set_entvar(iOld, var_solid, SOLID_NOT)
	set_entvar(iOld, var_health, 0.0)
	set_entvar(iOld, var_flags, FL_KILLME)
	set_entvar(iOld, var_nextthink, fGameTime)

	arrayset(Player[iOwner][PlrMinionRespawnAt], 0.0, MAX_MINION_SLOTS)
	Player[iOwner][PlrLaserPendingAt] = 0.0
	Player[iOwner][PlrLaserLockTime] = 0.0
	Player[iOwner][PlrHydraForm] = bHydra

	new iNew = create_heavy(vOrigin, vAngles, fHealth, iOwner, bHydra)
	if (!is_nullent(iNew))
	{
		Player[iOwner][PlrMinionEnt][MINION_SLOT_HEAVY] = iNew
		minion_create_lifebar(iOwner, MINION_SLOT_HEAVY, iNew)
	}

	Player[iOwner][PlrLastFormSwitch] = fGameTime
	necro_reset_npc_actions(iOwner)
	Player[iOwner][PlrMinionCharge][MINION_SLOT_HEAVY] = fCharge
	Player[iOwner][PlrModeChangeOrdered] = false
	return true
}

bool:necro_set_zerglings_mode(iOwner)
{
	if (!Player[iOwner][PlrIsAlive] || Player[iOwner][PlrKnife] != g_iKnifeId
		|| kc_player_in_silence(iOwner) || kc_player_in_darkness(iOwner))
		return false

	if (get_gametime() - Player[iOwner][PlrLastFormSwitch] < FORM_SWITCH_COOLDOWN)
		return false

	new iHeavy = Player[iOwner][PlrMinionEnt][MINION_SLOT_HEAVY]
	if (!iHeavy || !is_entity(iHeavy) || (get_entvar(iHeavy, var_flags) & FL_KILLME))
		return false

	if (g_bUltraBurrowed[iHeavy] || g_bMinionClimb[iHeavy] || !(get_entvar(iHeavy, var_flags) & FL_ONGROUND))
		return false

	new Float:vOrigin[3], Float:vAngles[3]
	get_entvar(iHeavy, var_origin, vOrigin)
	get_entvar(iHeavy, var_angles, vAngles)
	vAngles[0] = vAngles[2] = 0.0

	new Float:fZerglingHealth = floatclamp(Float:get_entvar(iHeavy, var_health) / 2.0, 1.0, ZERGLING_HEALTH)

	new Float:fModeCharge = Player[iOwner][PlrMinionCharge][MINION_SLOT_HEAVY] / 2.0

	ExecuteHamB(Ham_TakeDamage, iHeavy, 0, iHeavy, 9000.0, DMG_BLAST)

	arrayset(Player[iOwner][PlrMinionRespawnAt], 0.0, MAX_MINION_SLOTS)
	Player[iOwner][PlrLaserPendingAt] = 0.0
	Player[iOwner][PlrLaserLockTime] = 0.0

	Player[iOwner][PlrForm] = FORM_ZERGLINGS
	Player[iOwner][PlrHydraForm] = false

	new Float:vBase[3]
	xs_vec_copy(vOrigin, vBase)
	vBase[2] += 36.0

	necro_spawn_zergling_mode(iOwner, 0, vBase, vAngles, fZerglingHealth, vAngles[1] + MINION_SPAWN_ANGLE)
	necro_spawn_zergling_mode(iOwner, 1, vBase, vAngles, fZerglingHealth, vAngles[1] - MINION_SPAWN_ANGLE)

	Player[iOwner][PlrLastFormSwitch] = get_gametime()
	necro_reset_npc_actions(iOwner)
	Player[iOwner][PlrMinionCharge][0] = fModeCharge
	Player[iOwner][PlrMinionCharge][1] = fModeCharge
	Player[iOwner][PlrModeChangeOrdered] = false
	return true
}

public spit_think(iSpitEnt)
{
	if (get_gametime() >= Float:get_entvar(iSpitEnt, var_fuser1))
	{
		rg_remove_entity(iSpitEnt)
		return
	}

	set_entvar(iSpitEnt, var_nextthink, get_gametime() + SPIT_SCAN_INTERVAL)

	new iOwner = get_entvar(iSpitEnt, var_owner)
	if (is_entity_player(iOwner))
	{
		new Float:vPrev[3], Float:vNow[3], Float:vMins[3], Float:vMaxs[3], Float:vEnd[3], Float:fFraction
		get_entvar(iSpitEnt, var_vuser1, vPrev)
		get_entvar(iSpitEnt, var_origin, vNow)
		set_entvar(iSpitEnt, var_vuser1, vNow)

		engfunc(EngFunc_TraceLine, vPrev, vNow, IGNORE_MONSTERS, iSpitEnt, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction < 1.0)
		{
			get_tr2(0, TR_vecEndPos, vEnd)
			engfunc(EngFunc_SetOrigin, iSpitEnt, vEnd)
			set_entvar(iSpitEnt, var_origin, vEnd)
			set_entvar(iSpitEnt, var_vuser1, vEnd)
			new iHit = get_tr2(0, TR_pHit)
			spit_touch(iSpitEnt, iHit > 0 ? iHit : 0)
			return
		}

		if (get_entvar(iSpitEnt, var_spit_reflected))
		{
			new iTargetMinion = get_entvar(iSpitEnt, var_spit_source)
			if (!is_entity(iTargetMinion) || (get_entvar(iTargetMinion, var_flags) & FL_KILLME))
			{
				spit_kill(iSpitEnt)
				return
			}

			get_entvar(iTargetMinion, var_absmin, vMins)
			get_entvar(iTargetMinion, var_absmax, vMaxs)
			spit_pad_box(vMins, vMaxs)
			if (line_intersects_box(vPrev, vNow, vMins, vMaxs))
				spit_touch(iSpitEnt, iTargetMinion)

			return
		}

		for (new i = 1; i <= MaxClients; i++)
		{
			if (i == iOwner || !is_user_alive(i))
				continue

			get_entvar(i, var_absmin, vMins)
			get_entvar(i, var_absmax, vMaxs)
			spit_pad_box(vMins, vMaxs)

			if (line_intersects_box(vPrev, vNow, vMins, vMaxs))
			{
				spit_touch(iSpitEnt, i)
				return
			}
		}

		new iEnt = NULLENT
		while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vNow, SPIT_SCAN_RADIUS)) > 0)
		{
			if (iEnt <= MaxClients || (get_entvar(iEnt, var_flags) & FL_KILLME))
				continue

			new iImpulse = get_entvar(iEnt, var_impulse)
			if (iImpulse == IMPULSE_MINION)
			{
				if (g_bUltraHidden[iEnt] || get_entvar(iEnt, var_skin) + 1 == Player[iOwner][PlrTeam])
					continue
			}
			else if (iImpulse != IMPULSE_FAKEPLAYER && iImpulse != IMPULSE_PRESENT)
				continue

			get_entvar(iEnt, var_absmin, vMins)
			get_entvar(iEnt, var_absmax, vMaxs)
			spit_pad_box(vMins, vMaxs)

			if (line_intersects_box(vPrev, vNow, vMins, vMaxs))
			{
				spit_touch(iSpitEnt, iEnt)
				return
			}
		}
	}
}

spit_pad_box(Float:vMins[3], Float:vMaxs[3])
{
	for (new i; i < 3; i++)
	{
		vMins[i] -= SPIT_SCAN_PAD
		vMaxs[i] += SPIT_SCAN_PAD
	}
}


necro_spit_heal(iSpitEnt, iOwner, Float:fDamage)
{
	if (get_entvar(iSpitEnt, var_spit_reflected))
		return

	if (get_entvar(iSpitEnt, var_npctype) == 2)
		kc_player_heal(iOwner, fDamage * MINION_HIT_HEAL_PERCENT, iOwner)
}

necro_spit_reflect(iSpitEnt, iBlocker)
{
	new iMinion = get_entvar(iSpitEnt, var_spit_source)
	if (get_entvar(iSpitEnt, var_spit_reflected) || !is_entity(iMinion) || (get_entvar(iMinion, var_flags) & FL_KILLME)
		|| get_entvar(iMinion, var_impulse) != IMPULSE_MINION)
	{
		spit_kill(iSpitEnt, .bStabbed=true)
		return
	}

	new Float:vOrigin[3], Float:vTarget[3], Float:vVelocity[3], Float:vAngles[3]
	get_entvar(iSpitEnt, var_origin, vOrigin)
	get_entvar(iSpitEnt, var_velocity, vVelocity)
	new Float:fSpeed = xs_vec_len(vVelocity)

	get_entity_center(iMinion, vTarget)
	xs_vec_sub(vTarget, vOrigin, vVelocity)
	xs_vec_normalize(vVelocity, vVelocity)
	vector_to_angle(vVelocity, vAngles)
	xs_vec_mul_scalar(vVelocity, fSpeed, vVelocity)

	set_entvar(iSpitEnt, var_owner, iBlocker)
	set_entvar(iSpitEnt, var_spit_reflected, 1)
	set_entvar(iSpitEnt, var_vuser1, vOrigin)
	set_entvar(iSpitEnt, var_velocity, vVelocity)
	set_entvar(iSpitEnt, var_angles, vAngles)
}

public spit_touch(iSpitEnt, iOther)
{
	new iOwner = get_entvar(iSpitEnt, var_owner)
	if (!is_entity_player(iOwner))
	{
		spit_kill(iSpitEnt)
		return
	}

	new Float:fSpitDamage = get_entvar(iSpitEnt, var_npctype) == 2 ? HYDRA_SPIT_DAMAGE : SPIT_DAMAGE

	if (is_entity_player(iOther))
	{
		if (!Player[iOther][PlrIsAlive] || (iOther != iOwner && Player[iOwner][PlrTeam] == Player[iOther][PlrTeam]))
		{
			spit_kill(iSpitEnt)
			return
		}

		if (get_entvar(iSpitEnt, var_spit_reflected) && iOther != get_entvar(iSpitEnt, var_spit_source))
			return

		if (iOther != iOwner && kc_player_apply_concentblock(iOther, iSpitEnt, ATTACK_HEAVINESS_LOW))
		{
			necro_spit_reflect(iSpitEnt, iOther)
			return
		}

		kc_player_set_death_reason(iOther, "DEATH_REASON_MINION")
		set_member(iOther, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iOther, iSpitEnt, iOwner, fSpitDamage, DMG_BLAST)
		if (iOther != iOwner)
			necro_spit_heal(iSpitEnt, iOwner, fSpitDamage)
		spit_kill(iSpitEnt)
		return
	}

	if (!is_entity(iOther))
	{
		spit_kill(iSpitEnt)
		return
	}

	if (get_entvar(iOther, var_solid) <= SOLID_TRIGGER)
		return

	if (get_entvar(iSpitEnt, var_spit_reflected) && get_entvar(iOther, var_impulse) == IMPULSE_MINION && iOther != get_entvar(iSpitEnt, var_spit_source))
		return

	if (get_entvar(iOther, var_impulse) == IMPULSE_MINION && get_entvar(iOther, var_skin) + 1 == Player[iOwner][PlrTeam])
		return

	switch (get_entvar(iOther, var_impulse))
	{
		case IMPULSE_MINION:
		{
			g_bMinionDot = true
			ExecuteHamB(Ham_TakeDamage, iOther, iSpitEnt, iOwner, fSpitDamage, DMG_BLAST)
			g_bMinionDot = false
			necro_spit_heal(iSpitEnt, iOwner, fSpitDamage)
		}
		case IMPULSE_PRESENT:
		{
			dllfunc(DLLFunc_Touch, iOther, iOwner)
		}
		case IMPULSE_FAKEPLAYER:
		{
			ExecuteHamB(Ham_TakeDamage, iOther, iSpitEnt, iOwner, 10.0, DMG_BLAST)
		}
	}

	new Float:vOrigin[3]
	get_entvar(iSpitEnt, var_origin, vOrigin)
	send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, MINION_BLOOD_COLOR, 5)
	necro_spit_impact_sound(iSpitEnt, PITCH_NORM)
	rg_remove_entity(iSpitEnt)
}

spit_kill(iSpitEnt, bool:bStabbed=false)
{
	new Float:vOrigin[3]
	get_entvar(iSpitEnt, var_origin, vOrigin)

	send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, MINION_BLOOD_COLOR, 5)

	necro_spit_impact_sound(iSpitEnt, bStabbed ? random_num(90, 95) : PITCH_NORM)

	rg_remove_entity(iSpitEnt)
}

public efk_disenergy(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return

	new Float:fCut = random_float(20.0, 25.0)

	for (new i; i < MAX_MINION_SLOTS; i++)
		Player[iPlayer][PlrMinionCharge][i] = floatmax(0.0, Player[iPlayer][PlrMinionCharge][i] - fCut)

	new Float:fGameTime = get_gametime()
	new Float:fModeElapsed = floatmin(fGameTime - Player[iPlayer][PlrLastFormSwitch], FORM_SWITCH_COOLDOWN)
	fModeElapsed = floatmax(0.0, fModeElapsed - FORM_SWITCH_COOLDOWN * fCut / 100.0)
	Player[iPlayer][PlrLastFormSwitch] = fGameTime - fModeElapsed
}

necro_cache_water_knife(iPlayer, iKnifeId)
{
	new szClassName[32]
	kc_knife_get_classname(iKnifeId, szClassName, charsmax(szClassName))
	g_bWaterKnife[iPlayer] = bool:equal(szClassName, WATER_KNIFE_CLASSNAME)
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	if (Player[iPlayer][PlrKnife] == g_iKnifeId)
	{
		necro_reset_form(iPlayer)
		necro_reset_npc_actions(iPlayer)
		kill_all_npc(iPlayer)
	}

	Player[iPlayer][PlrKnife] = iKnifeId
	necro_cache_water_knife(iPlayer, iKnifeId)
	if (iKnifeId == g_iKnifeId && Player[iPlayer][PlrIsAlive])
	{
		new bool:bJustSpawned = get_gametime() - g_fPlayerSpawnTime[iPlayer] < SPAWN_KNIFE_SET_WINDOW
		necro_schedule_form(iPlayer, bJustSpawned ? MINION_SPAWN_DELAY : MINION_KNIFE_CHANGE_SPAWN_DELAY)
	}
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	static szMessage[192], szLabel[32], szAction[64]
	static iLen
	szMessage[0] = 0
	iLen = 0

	new Float:fModeElapsed = get_gametime() - Player[iSubject][PlrLastFormSwitch]
	new iModeCharge = clamp(floatround(fModeElapsed * 100.0 / FORM_SWITCH_COOLDOWN), 0, 100)
	new szModeKey[8]
	copy(szModeKey, charsmax(szModeKey), Player[iSubject][PlrForm] == FORM_HEAVY ? (Player[iSubject][PlrHydraForm] ? "R + T" : "E + T") : "T")
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%L: %L (%dpt)", iPlayer, "NECRO_MODE", szModeKey,
		iPlayer, Player[iSubject][PlrForm] == FORM_HEAVY ? (Player[iSubject][PlrHydraForm] ? "NECRO_HYDRA" : "NECRO_ULTRALISK") : "NECRO_ZERGLINGS", iModeCharge)

	new bool:bHeavyForm = bool:(Player[iSubject][PlrForm] == FORM_HEAVY)
	new iSlots = bHeavyForm ? 1 : MAX_MINION_SLOTS

	for (new i; i < iSlots; i++)
	{
		new iEnt = Player[iSubject][PlrMinionEnt][i]
		if (iEnt && is_entity(iEnt) && !(get_entvar(iEnt, var_flags) & FL_KILLME))
			formatex(szLabel, charsmax(szLabel), "%L", iPlayer, "NECRO_HP", floatround(Float:get_entvar(iEnt, var_health), floatround_floor))
		else
			formatex(szLabel, charsmax(szLabel), "%L", iPlayer, "NECRO_RESPAWN", necro_respawn_percent(iSubject, i))

		szAction[0] = 0
		switch (Player[iSubject][PlrNpcAction][i])
		{
			case NPC_ACTION_MOVE: formatex(szAction, charsmax(szAction), "%L", iPlayer, "NPC_ACTION_MOVE")
			case NPC_ACTION_TARGET: formatex(szAction, charsmax(szAction), "%L", iPlayer, "NPC_ACTION_TARGET")
			case NPC_ACTION_SHOOT: formatex(szAction, charsmax(szAction), "%L", iPlayer, "NPC_ACTION_SHOOT")
			case NPC_ACTION_FOLLOW: formatex(szAction, charsmax(szAction), "%L", iPlayer, "NPC_ACTION_FOLLOW")
		}

		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n%s [%s] (%dpt)%s%s",
			bHeavyForm ? "E/R" : (i == 0 ? "E" : "R"), szLabel,
			floatround(Player[iSubject][PlrMinionCharge][i], floatround_floor),
			szAction[0] ? " : " : "", szAction)
	}

	new iUltralisk = necro_ultralisk_get(iSubject)
	if (iUltralisk)
	{
		new Float:fRageLeft = g_fUltraRageReadyAt[iUltralisk] - get_gametime()
		new iRageCharge = fRageLeft > 0.0 ? clamp(floatround((1.0 - fRageLeft / ULTRALISK_RAGE_COOLDOWN) * 100.0, floatround_floor), 0, 100) : 100
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n%L", iPlayer, "NECRO_RAGE", iRageCharge)
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n%L", iPlayer, "NECRO_BURROW", g_bUltraBurrowed[iUltralisk] ? "ON" : "OFF")
	}

	if (szMessage[0])
	{
		set_hudmessage(0, 255, 0, 0.01, 0.27, 0, 0.0, 0.2, 0.2, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "%s", szMessage)
	}

	return PLUGIN_CONTINUE
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	return PLUGIN_CONTINUE
}

public efk_ability_pre(iPlayer, iTarget)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	return PLUGIN_HANDLED
}

public efk_ability(iPlayer, iTarget)
{
	return PLUGIN_HANDLED
}

necro_trace_aim_point(iPlayer, iHeavy, Float:vEnd[])
{
	new Float:vStart[3], Float:vViewOfs[3], Float:vAngles[3], Float:vDirection[3]
	get_entvar(iPlayer, var_origin, vStart)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vStart, vViewOfs, vStart)
	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vDirection)
	xs_vec_mul_scalar(vDirection, Player[iPlayer][PlrHydraForm] ? HYDRA_LASER_RANGE : LASER_RANGE, vDirection)
	xs_vec_add(vStart, vDirection, vEnd)

	new iOldSolid = get_entvar(iHeavy, var_solid)
	set_entvar(iHeavy, var_solid, SOLID_NOT)
	engfunc(EngFunc_TraceLine, vStart, vEnd, DONT_IGNORE_MONSTERS, iPlayer, 0)
	set_entvar(iHeavy, var_solid, iOldSolid)
	get_tr2(0, TR_vecEndPos, vEnd)
	return get_tr2(0, TR_pHit)
}

necro_heavy_laser(iPlayer)
{
	new iHeavy = Player[iPlayer][PlrMinionEnt][MINION_SLOT_HEAVY]
	new Float:fGameTime = get_gametime()
	if (!iHeavy || !is_entity(iHeavy) || (get_entvar(iHeavy, var_flags) & FL_KILLME) || necro_minion_is_frozen(iHeavy) || g_bMinionClimb[iHeavy]
		|| Player[iPlayer][PlrLaserLockTime] > fGameTime
		|| Player[iPlayer][PlrLaserPendingAt] > 0.0 || Player[iPlayer][PlrLaserIndicateEndAt] > 0.0
		|| Player[iPlayer][PlrMinionCharge][MINION_SLOT_HEAVY] < 100.0)
		return PLUGIN_HANDLED

	Player[iPlayer][PlrMinionCharge][MINION_SLOT_HEAVY] = 0.0
	Player[iPlayer][PlrLaserPendingAt] = fGameTime + LASER_CHARGE_TIME
	necro_track_laser_aim(iPlayer)
	return PLUGIN_CONTINUE
}

necro_track_laser_aim(iPlayer)
{
	new iHeavy = Player[iPlayer][PlrMinionEnt][MINION_SLOT_HEAVY]
	if (!iHeavy || !is_entity(iHeavy) || (get_entvar(iHeavy, var_flags) & FL_KILLME))
		return

	new Float:vHeavyOrigin[3], Float:vAimEnd[3]
	get_entvar(iHeavy, var_origin, vHeavyOrigin)
	necro_trace_aim_point(iPlayer, iHeavy, vAimEnd)
	npc_TurnToTarget(iHeavy, vHeavyOrigin, vAimEnd)
}

necro_start_laser_indicate(iPlayer)
{
	new iHeavy = Player[iPlayer][PlrMinionEnt][MINION_SLOT_HEAVY]
	if (!iHeavy || !is_entity(iHeavy) || (get_entvar(iHeavy, var_flags) & FL_KILLME))
		return

	necro_trace_aim_point(iPlayer, iHeavy, Player[iPlayer][PlrLaserLockedEnd])
	Player[iPlayer][PlrLaserIndicateEndAt] = get_gametime() + LASER_INDICATE_TIME

	set_entvar(iHeavy, var_rendermode, kRenderNormal)
	set_entvar(iHeavy, var_renderfx, kRenderFxGlowShell)
	set_entvar(iHeavy, var_rendercolor, Float:{255.0, 0.0, 0.0})
	set_entvar(iHeavy, var_renderamt, 16.0)

	set_entvar(iHeavy, var_animtime, get_gametime())
	set_entvar(iHeavy, var_frame, 0.0)
	set_entvar(iHeavy, var_sequence, 5)
	necro_voice_attack(iHeavy)
}

necro_clear_laser_glow(iPlayer)
{
	new iHeavy = Player[iPlayer][PlrMinionEnt][MINION_SLOT_HEAVY]
	if (!iHeavy || !is_entity(iHeavy))
		return

	set_entvar(iHeavy, var_rendermode, kRenderNormal)
	set_entvar(iHeavy, var_renderfx, kRenderFxNone)
	set_entvar(iHeavy, var_renderamt, 0.0)
}

necro_fire_heavy_laser(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId || Player[iPlayer][PlrForm] != FORM_HEAVY)
		return

	new iHeavy = Player[iPlayer][PlrMinionEnt][MINION_SLOT_HEAVY]
	if (!iHeavy || !is_entity(iHeavy) || (get_entvar(iHeavy, var_flags) & FL_KILLME))
		return

	if (!Player[iPlayer][PlrHydraForm])
		return

	new Float:vLockedEnd[3]
	xs_vec_copy(Player[iPlayer][PlrLaserLockedEnd], vLockedEnd)

	new Float:vHeavyOrigin[3], Float:vBeamStart[3], Float:vHeavyAngles[3]
	get_entvar(iHeavy, var_origin, vHeavyOrigin)
	get_entvar(iHeavy, var_angles, vHeavyAngles)
	engfunc(EngFunc_MakeVectors, vHeavyAngles)
	global_get(glb_v_forward, vBeamStart)
	xs_vec_mul_scalar(vBeamStart, LASER_START_FORWARD, vBeamStart)
	xs_vec_add(vHeavyOrigin, vBeamStart, vBeamStart)
	vBeamStart[2] += 40.0

	new Float:vBeamDir[3]
	xs_vec_sub(vLockedEnd, vBeamStart, vBeamDir)
	xs_vec_normalize(vBeamDir, vBeamDir)

	new iHit, Float:fBeamDistance = necro_laser_trace(iPlayer, iHeavy, vBeamStart, vBeamDir, HYDRA_LASER_RANGE, iHit)

	new Float:vEnd[3]
	xs_vec_mul_scalar(vBeamDir, fBeamDistance, vEnd)
	xs_vec_add(vBeamStart, vEnd, vEnd)

	send_msg_TE_BEAMPOINTS(vBeamStart, vEnd, g_pLaserbeamSpr, 0, 1, 7, 10, 0, {60, 220, 60}, 200, 0)
	engfunc(EngFunc_EmitAmbientSound, 0, vEnd, SOUNDS_HYDRA_SPIT_IMPACT[random(sizeof SOUNDS_HYDRA_SPIT_IMPACT)], 1.0, ATTN_NORM, 0, PITCH_NORM)

	if (is_entity_player(iHit))
	{
		kc_player_set_death_reason(iHit, "DEATH_REASON_MINION")
		set_member(iHit, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iHit, iHeavy, iPlayer, LASER_DAMAGE, DMG_ENERGYBEAM)
	}
	else if (iHit)
		ExecuteHamB(Ham_TakeDamage, iHit, iHeavy, iPlayer, LASER_DAMAGE, DMG_ENERGYBEAM)
}

Float:necro_ray_box(const Float:vStart[3], const Float:vDir[3], const Float:vMins[3], const Float:vMaxs[3], Float:fMaxDistance)
{
	new Float:fNear, Float:fFar = fMaxDistance, Float:fT1, Float:fT2, Float:fTemp
	for (new i; i < 3; i++)
	{
		if (floatabs(vDir[i]) < 0.00001)
		{
			if (vStart[i] < vMins[i] || vStart[i] > vMaxs[i])
				return -1.0

			continue
		}

		fT1 = (vMins[i] - vStart[i]) / vDir[i]
		fT2 = (vMaxs[i] - vStart[i]) / vDir[i]
		if (fT1 > fT2)
		{
			fTemp = fT1
			fT1 = fT2
			fT2 = fTemp
		}

		fNear = floatmax(fNear, fT1)
		fFar = floatmin(fFar, fT2)
		if (fNear > fFar)
			return -1.0
	}

	return fNear
}

Float:necro_laser_trace(iPlayer, iHeavy, const Float:vStart[3], const Float:vDir[3], Float:fRange, &iHit)
{
	iHit = 0

	new Float:fDistance = fRange, Float:vFrom[3], Float:vEnd[3], Float:vHitPos[3], Float:fFraction, Float:fTraveled
	xs_vec_copy(vStart, vFrom)
	for (new i; i < 8 && fTraveled < fRange; i++)
	{
		xs_vec_mul_scalar(vDir, fRange - fTraveled, vEnd)
		xs_vec_add(vFrom, vEnd, vEnd)
		engfunc(EngFunc_TraceLine, vFrom, vEnd, IGNORE_MONSTERS, iHeavy, 0)
		get_tr2(0, TR_flFraction, fFraction)
		get_tr2(0, TR_vecEndPos, vHitPos)
		new iWorldHit = get_tr2(0, TR_pHit)
		fTraveled += fFraction * (fRange - fTraveled)
		if (fFraction >= 1.0 || !is_entity(iWorldHit) || get_entvar(iWorldHit, var_impulse) != IMPULSE_MINION)
		{
			fDistance = fFraction >= 1.0 ? fRange : fTraveled
			break
		}

		xs_vec_mul_scalar(vDir, 2.0, vEnd)
		xs_vec_add(vHitPos, vEnd, vFrom)
		fTraveled += 2.0
	}

	new Float:vMins[3], Float:vMaxs[3], Float:fEntry, iEnt
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == iPlayer || !Player[i][PlrIsAlive] || Player[i][PlrTeam] == Player[iPlayer][PlrTeam])
			continue

		get_entvar(i, var_absmin, vMins)
		get_entvar(i, var_absmax, vMaxs)
		fEntry = necro_ray_box(vStart, vDir, vMins, vMaxs, fDistance)
		if (fEntry >= 0.0 && fEntry < fDistance)
		{
			fDistance = fEntry
			iHit = i
		}
	}

	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_MINION)))
	{
		if ((get_entvar(iEnt, var_flags) & FL_KILLME) || g_bUltraHidden[iEnt] || get_entvar(iEnt, var_skin) + 1 == Player[iPlayer][PlrTeam])
			continue

		get_entvar(iEnt, var_absmin, vMins)
		get_entvar(iEnt, var_absmax, vMaxs)
		fEntry = necro_ray_box(vStart, vDir, vMins, vMaxs, fDistance)
		if (fEntry >= 0.0 && fEntry < fDistance)
		{
			fDistance = fEntry
			iHit = iEnt
		}
	}

	iEnt = 0
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_FIELD_PART)))
	{
		if (get_entvar(iEnt, var_skin) + 1 == Player[iPlayer][PlrTeam])
			continue

		get_entvar(iEnt, var_absmin, vMins)
		get_entvar(iEnt, var_absmax, vMaxs)
		fEntry = necro_ray_box(vStart, vDir, vMins, vMaxs, fDistance)
		if (fEntry >= 0.0 && fEntry < fDistance)
		{
			fDistance = fEntry
			iHit = 0
		}
	}

	return fDistance
}

bool:necro_is_enemy_entity(iOwner, iEnt)
{
	if (is_entity_player(iEnt))
		return bool:(Player[iEnt][PlrIsAlive] && Player[iEnt][PlrTeam] != Player[iOwner][PlrTeam])

	if (!is_entity(iEnt) || get_entvar(iEnt, var_impulse) != IMPULSE_MINION || g_bUltraHidden[iEnt])
		return false

	return bool:(get_entvar(iEnt, var_skin) + 1 != Player[iOwner][PlrTeam])
}

find_necro_target(iOwner, const Float:vOrigin[3], Float:fRadius, iPreferred, Float:vTargetOrigin[3], iExclude = 0)
{
	if (iPreferred && necro_is_enemy_entity(iOwner, iPreferred))
	{
		get_entvar(iPreferred, var_origin, vTargetOrigin)
		if (get_distance_f(vOrigin, vTargetOrigin) <= fRadius)
			return iPreferred
	}

	new iTarget, iEnt = 0
	new Float:fBestDistance = fRadius, Float:fDistance, Float:vCandidateOrigin[3]
	for (iEnt = 1; iEnt <= MaxClients; iEnt++)
	{
		if (iEnt == iExclude || !necro_is_enemy_entity(iOwner, iEnt) || kc_player_get_visibility(iEnt) >= VIS_TRANS)
			continue

		get_entvar(iEnt, var_origin, vCandidateOrigin)
		fDistance = get_distance_f(vOrigin, vCandidateOrigin)
		if (fDistance <= fBestDistance)
		{
			fBestDistance = fDistance
			iTarget = iEnt
			xs_vec_copy(vCandidateOrigin, vTargetOrigin)
		}
	}

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_MINION)))
	{
		if (iEnt == iExclude || !necro_is_enemy_entity(iOwner, iEnt) || (get_entvar(iEnt, var_flags) & FL_KILLME))
			continue

		get_entvar(iEnt, var_origin, vCandidateOrigin)
		fDistance = get_distance_f(vOrigin, vCandidateOrigin)
		if (fDistance <= fBestDistance)
		{
			fBestDistance = fDistance
			iTarget = iEnt
			xs_vec_copy(vCandidateOrigin, vTargetOrigin)
		}
	}

	return iTarget
}

bool:necro_valid_manual_target(iOwner, iTarget)
{
	if (necro_is_enemy_entity(iOwner, iTarget))
		return bool:!(is_entity_player(iTarget) && kc_player_get_visibility(iTarget) >= VIS_TRANS)

	return bool:(is_entity(iTarget) && !is_entity_player(iTarget) && get_entvar(iTarget, var_impulse) == IMPULSE_PRESENT
		&& !(get_entvar(iTarget, var_flags) & FL_KILLME))
}

necro_get_formation_point(iOwner, iSlot, Float:vResult[3])
{
	new Float:vOwnerOrigin[3], Float:vAngles[3]
	get_entvar(iOwner, var_origin, vOwnerOrigin)
	get_entvar(iOwner, var_v_angle, vAngles)

	new Float:fYaw = vAngles[1] + 180.0 + (iSlot == 0 ? -MINION_SPAWN_ANGLE : MINION_SPAWN_ANGLE)
	vResult[0] = vOwnerOrigin[0] + floatcos(fYaw, degrees) * MINION_SPAWN_DISTANCE
	vResult[1] = vOwnerOrigin[1] + floatsin(fYaw, degrees) * MINION_SPAWN_DISTANCE
	vResult[2] = vOwnerOrigin[2]
}

necro_hold_position(iOwner, iSlot, const Float:vOrigin[3])
{
	Player[iOwner][PlrNpcAction][iSlot] = NPC_ACTION_MOVE
	Player[iOwner][PlrNpcActionTarget][iSlot] = 0
	xs_vec_copy(vOrigin, PlrActionOrigin(iOwner, iSlot))
}

bool:necro_command_destination(iOwner, iSelfSlot, bool:bHeavy, const Float:vOrigin[3], Float:vDestination[3], &iTarget, &bool:bReturning)
{
	new Float:vOwnerOrigin[3]
	get_entvar(iOwner, var_origin, vOwnerOrigin)
	xs_vec_copy(vOwnerOrigin, vDestination)
	bReturning = false
	iTarget = 0

	if (!bHeavy && Player[iOwner][PlrModeChangeOrdered] && iSelfSlot >= 0)
	{
		new iSiblingSlot = iSelfSlot == 0 ? 1 : 0
		new iSibling = Player[iOwner][PlrMinionEnt][iSiblingSlot]
		if (iSibling && is_entity(iSibling) && !(get_entvar(iSibling, var_flags) & FL_KILLME))
		{
			iTarget = iSibling
			get_entvar(iSibling, var_origin, vDestination)
			return true
		}
	}

	new NpcAction:iAction = iSelfSlot >= 0 ? Player[iOwner][PlrNpcAction][iSelfSlot] : NPC_ACTION_FOLLOW

	switch (iAction)
	{
		case NPC_ACTION_TARGET:
		{
			iTarget = Player[iOwner][PlrNpcActionTarget][iSelfSlot]
			if (!necro_valid_manual_target(iOwner, iTarget))
			{
				necro_hold_position(iOwner, iSelfSlot, vOrigin)
				iTarget = 0
				xs_vec_copy(vOrigin, vDestination)
				return true
			}

			get_entvar(iTarget, var_origin, vDestination)
			if (get_distance_f(vOrigin, vDestination) > MINION_TARGET_RADIUS)
			{
				bReturning = true
				xs_vec_copy(vOwnerOrigin, vDestination)
				iTarget = 0
			}
		}
		case NPC_ACTION_SHOOT:
		{
			new iShootTarget = Player[iOwner][PlrNpcActionTarget][iSelfSlot]
			new Float:vShootOrigin[3]
			if (necro_valid_manual_target(iOwner, iShootTarget))
				get_entvar(iShootTarget, var_origin, vShootOrigin)

			if (!necro_valid_manual_target(iOwner, iShootTarget) || get_distance_f(vOrigin, vShootOrigin) > HYDRA_SPIT_RANGE)
			{
				necro_hold_position(iOwner, iSelfSlot, vOrigin)
				iTarget = 0
				xs_vec_copy(vOrigin, vDestination)
				return true
			}

			xs_vec_copy(vOrigin, vDestination)
		}
		case NPC_ACTION_MOVE:
		{
			xs_vec_copy(PlrActionOrigin(iOwner, iSelfSlot), vDestination)
			if (get_distance_f(vOrigin, vDestination) > MINION_FOLLOW_RADIUS + 200.0)
			{
				bReturning = true
				xs_vec_copy(vOwnerOrigin, vDestination)
			}
		}
		default:
		{
			bReturning = true

			if (iSelfSlot < 0)
				return true

			new Float:fStopDistance = 60.0
			if (bHeavy)
				fStopDistance = HEAVY_FOLLOW_STOP_DISTANCE
			else
				necro_get_formation_point(iOwner, iSelfSlot, vDestination)

			new Float:fDistance = get_distance_f(vOrigin, vDestination)
			if (!Player[iOwner][PlrMinionWalking][iSelfSlot] && fDistance > MINION_FORMATION_LEASH && get_distance_f(vOrigin, vOwnerOrigin) > MINION_SPAWN_DISTANCE + MINION_FORMATION_OWNER_SLACK)
				Player[iOwner][PlrMinionWalking][iSelfSlot] = true
			else if (Player[iOwner][PlrMinionWalking][iSelfSlot] && fDistance <= fStopDistance)
				Player[iOwner][PlrMinionWalking][iSelfSlot] = false

			if (!Player[iOwner][PlrMinionWalking][iSelfSlot])
				xs_vec_copy(vOrigin, vDestination)
		}
	}

	return true
}

Float:necro_minion_max_health(iMinion)
{
	new iType = get_entvar(iMinion, var_npctype)
	if (!iType)
		return ZERGLING_HEALTH
	return iType == 2 ? HYDRA_HEALTH : HEAVY_HEALTH
}

necro_set_move_animation(iEnt, bool:bHeavy)
{
	new iSequence = bHeavy ? 2 : 1
	if (get_entvar(iEnt, var_sequence) != iSequence && get_gametime() >= Float:get_entvar(iEnt, var_fuser4))
	{
		set_entvar(iEnt, var_animtime, 0.0)
		set_entvar(iEnt, var_frame, 0.0)
		set_entvar(iEnt, var_sequence, iSequence)
	}
}

get_entity_center(iEnt, Float:vCenter[3])
{
	new Float:vMins[3], Float:vMaxs[3]
	get_entvar(iEnt, var_absmin, vMins)
	get_entvar(iEnt, var_absmax, vMaxs)
	vCenter[0] = (vMins[0] + vMaxs[0]) * 0.5
	vCenter[1] = (vMins[1] + vMaxs[1]) * 0.5
	vCenter[2] = (vMins[2] + vMaxs[2]) * 0.5
}

bool:necro_start_heavy_spit(iHeavyEnt, const Float:vOrigin[3], iTarget, bool:bMoveOrder=false)
{
	if (g_bMinionClimb[iHeavyEnt])
		return false

	if (get_entvar(iHeavyEnt, var_npctype) != 2)
		return false

	new bool:bDelayed = bMoveOrder

	if (!iTarget)
	{
		g_fSpitReadyAt[iHeavyEnt] = 0.0
		return false
	}

	new Float:vTargetOrigin[3], Float:vSelfOrigin[3], Float:vStart[3], Float:fFraction
	get_entvar(iTarget, var_origin, vTargetOrigin)
	new Float:fDistance = get_distance_f(vOrigin, vTargetOrigin)

	xs_vec_copy(vOrigin, vSelfOrigin)
	xs_vec_copy(vOrigin, vStart)
	vStart[2] += HYDRA_SPIT_HEIGHT
	engfunc(EngFunc_TraceLine, vStart, vTargetOrigin, IGNORE_MONSTERS, iHeavyEnt, 0)
	get_tr2(0, TR_flFraction, fFraction)

	if (fDistance <= HEAVY_ATTACK_RANGE || fDistance > HYDRA_SPIT_RANGE || (1.0 - fFraction) * fDistance > SPIT_CLEAR_TOLERANCE)
	{
		g_fSpitReadyAt[iHeavyEnt] = 0.0
		return false
	}

	new Float:fGameTime = get_gametime()
	if (bDelayed)
	{
		if (g_fSpitReadyAt[iHeavyEnt] <= 0.0)
			g_fSpitReadyAt[iHeavyEnt] = fGameTime + SPIT_MOVE_DELAY

		if (fGameTime < g_fSpitReadyAt[iHeavyEnt])
			return false
	}
	g_fSpitReadyAt[iHeavyEnt] = 0.0

	npc_TurnToTarget(iHeavyEnt, vSelfOrigin, vTargetOrigin)

	set_entvar(iHeavyEnt, var_animtime, fGameTime)
	set_entvar(iHeavyEnt, var_frame, 0.0)
	set_entvar(iHeavyEnt, var_sequence, 5)
	set_entvar(iHeavyEnt, var_npcspit, iTarget)
	set_entvar(iHeavyEnt, var_nextthink, fGameTime + HYDRA_SPIT_RELEASE)
	return true
}

bool:necro_launch_spit(iHeavyEnt, iOwner, const Float:vOrigin[3], const Float:vTargetOrigin[3], Float:fSpeed)
{
	new iSpitEnt = rg_create_entity(SZ_EXPLOSION)
	if (is_nullent(iSpitEnt))
		return false

	new Float:vSelfOrigin[3], Float:vStart[3], Float:vAngles[3]
	xs_vec_copy(vOrigin, vSelfOrigin)

	get_entvar(iHeavyEnt, var_angles, vAngles)
	engfunc(EngFunc_MakeVectors, vAngles)
	global_get(glb_v_forward, vStart)
	xs_vec_mul_scalar(vStart, HEAVY_SPIT_FORWARD, vStart)
	xs_vec_add(vSelfOrigin, vStart, vStart)
	vStart[2] += HYDRA_SPIT_HEIGHT

	new Float:vBody[3], Float:fStartFraction
	xs_vec_copy(vSelfOrigin, vBody)
	vBody[2] += HYDRA_SPIT_HEIGHT
	engfunc(EngFunc_TraceLine, vBody, vStart, IGNORE_MONSTERS, iHeavyEnt, 0)
	get_tr2(0, TR_flFraction, fStartFraction)
	if (fStartFraction < 1.0)
		xs_vec_copy(vBody, vStart)

	engfunc(EngFunc_SetModel, iSpitEnt, MODEL_SPIT)
	engfunc(EngFunc_SetOrigin, iSpitEnt, vStart)
	engfunc(EngFunc_SetSize, iSpitEnt, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0})
	set_entvar(iSpitEnt, var_origin, vStart)
	set_entvar(iSpitEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iSpitEnt, var_movetype, MOVETYPE_NOCLIP)
	set_entvar(iSpitEnt, var_vuser1, vStart)
	set_entvar(iSpitEnt, var_rendermode, kRenderNormal)
	set_entvar(iSpitEnt, var_gravity, 0.0)
	set_entvar(iSpitEnt, var_classname, _CLASSNAME_MINION_SPIT)
	set_entvar(iSpitEnt, var_impulse, IMPULSE_MINION_SPIT)
	set_entvar(iSpitEnt, var_owner, iOwner)
	set_entvar(iSpitEnt, var_npctype, get_entvar(iHeavyEnt, var_npctype))
	set_entvar(iSpitEnt, var_spit_source, iHeavyEnt)
	set_entvar(iSpitEnt, var_spit_reflected, 0)
	set_entvar(iSpitEnt, var_fuser1, get_gametime() + SPIT_LIFETIME)
	set_entvar(iSpitEnt, var_nextthink, get_gametime() + SPIT_SCAN_INTERVAL)

	send_msg_TE_BEAMFOLLOW(iSpitEnt, g_pShockwaveSpr, 4, 2, {60, 220, 60}, 100)

	new Float:vDirection[3]
	xs_vec_sub(vTargetOrigin, vStart, vAngles)
	xs_vec_normalize(vAngles, vDirection)
	vector_to_angle(vDirection, vAngles)
	xs_vec_mul_scalar(vDirection, fSpeed, vDirection)

	set_entvar(iSpitEnt, var_velocity, vDirection)
	set_entvar(iSpitEnt, var_angles, vAngles)

	SetThink(iSpitEnt, "spit_think")
	SetTouch(iSpitEnt, "spit_touch")
	return true
}

bool:necro_release_heavy_spit(iHeavyEnt, iOwner, const Float:vOrigin[3])
{
	new iTarget = get_entvar(iHeavyEnt, var_npcspit)
	if (!iTarget)
		return false

	set_entvar(iHeavyEnt, var_npcspit, 0)
	if (is_nullent(iTarget) || (get_entvar(iTarget, var_flags) & FL_KILLME))
		return false

	new Float:vTargetOrigin[3]
	get_entity_center(iTarget, vTargetOrigin)

	new Float:vNearOrigin[3]
	new Float:fSpitSpeed = find_necro_target(iOwner, vOrigin, HYDRA_CLOSE_RANGE, 0, vNearOrigin) ? HYDRA_SLOW_SPIT_SPEED : HYDRA_SPIT_SPEED

	if (!necro_launch_spit(iHeavyEnt, iOwner, vOrigin, vTargetOrigin, fSpitSpeed))
		return false

	set_entvar(iHeavyEnt, var_nextthink, get_gametime() + (get_entvar(iHeavyEnt, var_npctype) == 2 ? HYDRA_SPIT_PAUSE : 0.4))
	necro_launch_sound(iHeavyEnt)
	return true
}

Float:necro_minion_melee_damage(iMinion, bool:bHeavy)
{
	new Float:fDamage = bHeavy ? random_float(HEAVY_MIN_DAMAGE, HEAVY_MAX_DAMAGE) : random_float(ZERGLING_MIN_DAMAGE, ZERGLING_MAX_DAMAGE)
	return get_entvar(iMinion, var_npctype) == 2 ? fDamage * HYDRA_MELEE_DAMAGE_MUL : fDamage
}

necro_attack_entity(iMinion, iOwner, iTarget, bool:bHeavy)
{
	if (is_entity_player(iTarget))
	{
		if (Player[iTarget][PlrTeam] == Player[iOwner][PlrTeam])
			return

		if (kc_player_apply_concentblock(iTarget, iMinion))
			return

		new Float:fDamage = necro_minion_melee_damage(iMinion, bHeavy)
		kc_player_set_death_reason(iTarget, "DEATH_REASON_MINION")
		set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iTarget, iMinion, iOwner, fDamage, DMG_SLASH | DMG_ALWAYSGIB)
		necro_voice_hit(iMinion)

		kc_player_heal(iOwner, fDamage * MINION_HIT_HEAL_PERCENT, iOwner)
	}
	else if (is_entity(iTarget) && get_entvar(iTarget, var_impulse) == IMPULSE_MINION
		&& get_entvar(iTarget, var_npctype) == 0 && get_entvar(iTarget, var_npcowner) == iOwner)
	{
		if (Player[iOwner][PlrModeChangeAt] <= 0.0)
			Player[iOwner][PlrModeChangeAt] = get_gametime() + MODE_CHANGE_WINDUP_TIME
	}
	else if (is_entity(iTarget))
	{
		new Float:fDamage = necro_minion_melee_damage(iMinion, bHeavy)
		ExecuteHamB(Ham_TakeDamage, iTarget, iMinion, iOwner, fDamage, DMG_SLASH | DMG_ALWAYSGIB)
		necro_voice_hit(iMinion)

		kc_player_heal(iOwner, fDamage * MINION_HIT_HEAL_PERCENT, iOwner)
	}
}

necro_play_attack_animation(iMinion, bool:bHeavy)
{
	set_entvar(iMinion, var_fuser4, get_gametime() + ATTACK_ANIM_LOCK_TIME)
	set_entvar(iMinion, var_animtime, get_gametime())
	set_entvar(iMinion, var_frame, 0.0)

	if (bHeavy)
		set_entvar(iMinion, var_sequence, get_entvar(iMinion, var_sequence) == 3 ? 4 : 3)
	else
		set_entvar(iMinion, var_sequence, get_entvar(iMinion, var_sequence) == 2 ? 3 : 2)

	engfunc(EngFunc_EmitSound, iMinion, CHAN_WEAPON, SOUND_MINION_SWING, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_minion_think(iMinion, bool:bHeavy)
{
	new iOwner = get_entvar(iMinion, var_npcowner)
	if (!is_entity_player(iOwner))
	{
		set_entvar(iMinion, var_flags, FL_KILLME)
		return
	}

	if (!Player[iOwner][PlrIsAlive] || Player[iOwner][PlrKnife] != g_iKnifeId
		|| bHeavy != (Player[iOwner][PlrForm] == FORM_HEAVY))
	{
		set_entvar(iMinion, var_flags, FL_KILLME)
		return
	}

	new Float:fGameTime = get_gametime(), Float:vOrigin[3], Float:vDestination[3]
	get_entvar(iMinion, var_origin, vOrigin)

	if (bHeavy && g_bUltraBurrowed[iMinion])
	{
		if (!g_bUltraHidden[iMinion])
		{
			if (fGameTime < g_fUltraBuryDoneAt[iMinion])
			{
				minion_halt(iMinion)
				set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
				return
			}

			necro_ultralisk_hide(iMinion)
		}

		necro_burrow_think(iMinion, fGameTime)
		return
	}

	if (bHeavy && g_fUltraWakeUntil[iMinion] > fGameTime)
	{
		minion_halt(iMinion)
		set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
		return
	}

	necro_rage_check_end(iMinion, fGameTime)

	if (necro_climb_expired(iMinion))
		return

	if (necro_minion_is_frozen(iMinion))
	{
		necro_climb_end(iMinion)
		new Float:vFrozenVelocity[3]
		get_entvar(iMinion, var_velocity, vFrozenVelocity)
		vFrozenVelocity[0] = 0.0
		vFrozenVelocity[1] = 0.0
		set_entvar(iMinion, var_velocity, vFrozenVelocity)
		set_entvar(iMinion, var_nextthink, fGameTime + MINION_STATUS_TICK)
		return
	}

	g_bThinkHeld = necro_minion_is_held(iMinion)

	if (necro_minion_is_blind(iMinion) || necro_owner_blind(iMinion))
	{
		necro_climb_end(iMinion)
		new Float:vBlindVelocity[3]
		get_entvar(iMinion, var_velocity, vBlindVelocity)
		vBlindVelocity[0] = 0.0
		vBlindVelocity[1] = 0.0
		set_entvar(iMinion, var_velocity, vBlindVelocity)
		set_entvar(iMinion, var_npctarget, 0)
		set_entvar(iMinion, var_npcspit, 0)
		minion_play_idle(iMinion, MINION_STATUS_TICK)
		return
	}

	new Float:fLastDamage = Float:get_entvar(iMinion, var_fuser3)
	if (fLastDamage > 0.0 && fGameTime - fLastDamage >= MINION_REGEN_DELAY)
	{
		new Float:fMaxHealth = necro_minion_max_health(iMinion)
		new Float:fHealth = Float:get_entvar(iMinion, var_health)
		if (fHealth < fMaxHealth)
		{
			new Float:fLastRegen = Float:get_entvar(iMinion, var_fuser2)
			new Float:fDt = fLastRegen > 0.0 ? floatmin(fGameTime - fLastRegen, 1.0) : 0.0
			set_entvar(iMinion, var_health, floatmin(fMaxHealth, fHealth + MINION_REGEN_RATE * fDt))
		}
		set_entvar(iMinion, var_fuser2, fGameTime)
	}

	new iPendingTarget = get_entvar(iMinion, var_npctarget)
	if (iPendingTarget)
	{
		set_entvar(iMinion, var_npctarget, 0)
		set_entvar(iMinion, var_nextthink, fGameTime + necro_attack_interval(iMinion) - ATTACK_WINDUP_TIME)

		if (!kc_player_in_silence(iOwner) && is_entity(iPendingTarget) && !(get_entvar(iPendingTarget, var_flags) & FL_KILLME)
			&& !(is_entity_player(iPendingTarget) && !Player[iPendingTarget][PlrIsAlive]))
		{
			new Float:vPendingOrigin[3]
			get_entvar(iPendingTarget, var_origin, vPendingOrigin)
			if (get_distance_f(vOrigin, vPendingOrigin) <= (bHeavy ? HEAVY_ATTACK_RANGE : ZERGLING_ATTACK_RANGE) + ATTACK_RANGE_TOLERANCE)
				necro_attack_entity(iMinion, iOwner, iPendingTarget, bHeavy)
		}
		return
	}

	if (Player[iOwner][PlrLaserPendingAt] > 0.0 || Player[iOwner][PlrLaserIndicateEndAt] > 0.0
		|| Player[iOwner][PlrLaserLockTime] > fGameTime)
	{
		if (Player[iOwner][PlrLaserPendingAt] > 0.0)
			minion_play_idle(iMinion)
		else
			set_entvar(iMinion, var_nextthink, fGameTime + 0.1)

		minion_halt(iMinion)
		return
	}

	if (kc_player_in_silence(iOwner))
	{
		minion_play_idle(iMinion)
		minion_halt(iMinion)
		return
	}

	if (bHeavy && necro_release_heavy_spit(iMinion, iOwner, vOrigin))
		return

	new bool:bReturning, iTarget, iAttackSlot = -1
	new iAttackOwner, iFoundSlot
	if (necro_find_minion_slot(iMinion, iAttackOwner, iFoundSlot) && iAttackOwner == iOwner)
		iAttackSlot = iFoundSlot

	if (!g_bThinkHeld && iAttackSlot >= 0 && !bHeavy && Player[iOwner][PlrMinionJumpUntil][iAttackSlot] > fGameTime)
	{
		new iJumpTarget = Player[iOwner][PlrNpcActionTarget][iAttackSlot]
		new bool:bLanded = fGameTime > Player[iOwner][PlrMinionJumpUntil][iAttackSlot] - ZERGLING_JUMP_MAX_TIME + 0.25
			&& (get_entvar(iMinion, var_flags) & FL_ONGROUND)

		if (necro_valid_manual_target(iOwner, iJumpTarget))
		{
			new Float:vJumpTarget[3]
			get_entvar(iJumpTarget, var_origin, vJumpTarget)
			if (get_distance_f(vOrigin, vJumpTarget) <= ZERGLING_ATTACK_RANGE)
			{
				necro_attack_entity(iMinion, iOwner, iJumpTarget, false)
				necro_play_attack_animation(iMinion, false)
				Player[iOwner][PlrMinionJumpUntil][iAttackSlot] = 0.0
				necro_restore_after_jump(iOwner, iAttackSlot, iJumpTarget)
				Player[iOwner][PlrMinionNextAttackAt][iAttackSlot] = fGameTime + MINION_ATTACK_INTERVAL
				set_entvar(iMinion, var_nextthink, fGameTime + MINION_ATTACK_INTERVAL)
				return
			}
		}
		else
			bLanded = true

		if (bLanded)
		{
			Player[iOwner][PlrMinionJumpUntil][iAttackSlot] = 0.0
			necro_restore_after_jump(iOwner, iAttackSlot, iJumpTarget)
		}
		else
		{
			set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
			return
		}
	}

	if (iAttackSlot >= 0 && Player[iOwner][PlrNpcAction][iAttackSlot] != NPC_ACTION_FOLLOW)
	{
		new Float:vOwnerPos[3]
		get_entvar(iOwner, var_origin, vOwnerPos)
		new Float:fRecallDistance = Player[iOwner][PlrNpcAction][iAttackSlot] == NPC_ACTION_TARGET
			? MINION_TARGET_RADIUS : MINION_RECALL_DISTANCE
		if (get_distance_f(vOrigin, vOwnerPos) > fRecallDistance)
		{
			Player[iOwner][PlrNpcAction][iAttackSlot] = NPC_ACTION_FOLLOW
			Player[iOwner][PlrNpcActionTarget][iAttackSlot] = 0
		}
	}

	necro_command_destination(iOwner, iAttackSlot, bHeavy, vOrigin, vDestination, iTarget, bReturning)

	if (kc_player_in_darkness(iOwner))
	{
		get_entvar(iOwner, var_origin, vDestination)
		iTarget = 0
		bReturning = false
	}

	if (iTarget && is_entity(iTarget) && get_entvar(iTarget, var_impulse) == IMPULSE_PRESENT
		&& get_distance_f(vOrigin, vDestination) <= (bHeavy ? HEAVY_ATTACK_RANGE : ZERGLING_ATTACK_RANGE))
	{
		dllfunc(DLLFunc_Touch, iTarget, iOwner)
		set_entvar(iMinion, var_npctarget, 0)
		set_entvar(iMinion, var_nextthink, fGameTime + 0.2)
		return
	}

	if (iTarget && get_distance_f(vOrigin, vDestination) <= (bHeavy ? HEAVY_ATTACK_RANGE : ZERGLING_ATTACK_RANGE))
	{
		if (iAttackSlot >= 0 && Player[iOwner][PlrMinionNextAttackAt][iAttackSlot] > fGameTime)
		{
			minion_halt(iMinion)
			minion_play_idle(iMinion, 0.1)
			return
		}

		npc_TurnToTarget(iMinion, vOrigin, vDestination)
		minion_halt(iMinion)
		necro_play_attack_animation(iMinion, bHeavy)
		set_entvar(iMinion, var_npctarget, iTarget)
		if (iAttackSlot >= 0)
			Player[iOwner][PlrMinionNextAttackAt][iAttackSlot] = fGameTime + necro_attack_interval(iMinion)
		set_entvar(iMinion, var_nextthink, fGameTime + ATTACK_WINDUP_TIME)
		return
	}

	if (bHeavy && iAttackSlot >= 0 && Player[iOwner][PlrNpcAction][iAttackSlot] == NPC_ACTION_SHOOT)
	{
		new iShootTarget = Player[iOwner][PlrNpcActionTarget][iAttackSlot]
		if (necro_start_heavy_spit(iMinion, vOrigin, iShootTarget))
			return

		new Float:vShootOrigin[3]
		get_entvar(iShootTarget, var_origin, vShootOrigin)
		npc_TurnToTarget(iMinion, vOrigin, vShootOrigin)
		minion_halt(iMinion)
		minion_play_idle(iMinion, 0.1)
		return
	}

	if (iAttackSlot >= 0)
	{
		if (Player[iOwner][PlrNpcAction][iAttackSlot] != NPC_ACTION_MOVE)
			Player[iOwner][PlrMoveWindupTarget][iAttackSlot] = 0
		else if (necro_move_mode_attack(iMinion, iOwner, iAttackSlot, bHeavy, vOrigin, bReturning))
			return
	}

	if (necro_climb_tick(iMinion, vDestination))
		return

	if (!g_bThinkHeld && necro_climb_try_down(iMinion, vOrigin, vDestination))
	{
		set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
		return
	}

	new bool:bFollowing = bool:(iAttackSlot < 0 || Player[iOwner][PlrNpcAction][iAttackSlot] == NPC_ACTION_FOLLOW)
	new Float:fFlatDistance = floatsqroot((vDestination[0] - vOrigin[0]) * (vDestination[0] - vOrigin[0]) + (vDestination[1] - vOrigin[1]) * (vDestination[1] - vOrigin[1]))
	if (g_bThinkHeld || get_distance_f(vOrigin, vDestination) <= 60.0 || (bFollowing && fFlatDistance <= 40.0))
	{
		minion_play_idle(iMinion)
		set_entvar(iMinion, var_nextthink, fGameTime + 0.1)
		return
	}

	npc_TurnToTarget(iMinion, vOrigin, vDestination)

	if (!g_bThinkHeld && necro_climb_try(iMinion, vOrigin, vDestination))
	{
		set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
		return
	}

	npc_Move(iMinion, necro_get_move_speed(iMinion, bReturning))
	necro_set_move_animation(iMinion, bHeavy)
	necro_voice_move(iMinion)
	set_entvar(iMinion, var_nextthink, fGameTime + 0.1)
}

new Float:g_fClimbEndAt[MAX_ENTITIES_NUM + 1]

Float:necro_climb_gap(iMinion)
{
	new Float:vMaxs[3]
	get_entvar(iMinion, var_maxs, vMaxs)
	return vMaxs[0] + 1.0
}

Float:necro_probe_dist(iMinion)
{
	return floatmax(22.0, necro_climb_gap(iMinion) + 4.0)
}

Float:necro_wall_reach(iMinion)
{
	return floatmax(CLIMB_WALL_REACH, necro_climb_gap(iMinion) + 8.0)
}

bool:necro_climb_limited(iMinion)
{
	new Float:vMaxs[3]
	get_entvar(iMinion, var_maxs, vMaxs)
	return bool:(vMaxs[0] > ZERGLING_HULL_RADIUS + 1.0)
}

necro_climb_started(iMinion)
{
	g_fClimbEndAt[iMinion] = necro_climb_limited(iMinion) ? get_gametime() + CLIMB_HEAVY_TIME : 0.0
}

necro_climb_end(iMinion)
{
	if (!g_bMinionClimb[iMinion])
		return

	g_bMinionClimb[iMinion] = false

	new Float:vAngles[3]
	get_entvar(iMinion, var_angles, vAngles)
	vAngles[0] = vAngles[2] = 0.0
	set_entvar(iMinion, var_angles, vAngles)
	set_entvar(iMinion, var_gravity, 0.0)
}

bool:necro_climb_allowed(iMinion)
{
	if (!necro_climb_limited(iMinion))
		return true

	new iOwner, iSlot
	if (!necro_find_minion_slot(iMinion, iOwner, iSlot) || iSlot < 0)
		return true

	return bool:(Player[iOwner][PlrNpcAction][iSlot] == NPC_ACTION_FOLLOW)
}

bool:necro_climb_expired(iMinion)
{
	if (!g_bMinionClimb[iMinion])
		return false

	new bool:bTimeout = bool:(g_fClimbEndAt[iMinion] > 0.0 && get_gametime() >= g_fClimbEndAt[iMinion])
	if (!bTimeout && necro_climb_allowed(iMinion))
		return false

	if (bTimeout)
	{
		g_fMoveBlockUntil[iMinion] = get_gametime() + MOVE_BLOCK_AFTER_CLIMB

		new iOwner, iSlot
		if (necro_find_minion_slot(iMinion, iOwner, iSlot) && iSlot >= 0)
			Player[iOwner][PlrNpcAction][iSlot] = NPC_ACTION_FOLLOW
	}

	new Float:vPush[3]
	xs_vec_mul_scalar(g_vClimbDir[iMinion], -CLIMB_EXPIRE_PUSH, vPush)
	vPush[2] = CLIMB_EXPIRE_LIFT
	necro_climb_end(iMinion)
	set_entvar(iMinion, var_velocity, vPush)
	set_entvar(iMinion, var_flags, get_entvar(iMinion, var_flags) & ~FL_ONGROUND)
	set_entvar(iMinion, var_nextthink, get_gametime() + 0.3)
	return true
}

bool:necro_climb_try(iMinion, const Float:vOrigin[3], const Float:vDestination[3])
{
	if (!necro_climb_allowed(iMinion))
		return false

	new Float:vAngles[3], Float:vDir[3], Float:vStart[3], Float:vEnd[3], Float:fFraction, Float:vNormal[3]
	if (vDestination[2] < vOrigin[2] + CLIMB_MARK_MIN_RISE)
	{
		if (vDestination[2] < vOrigin[2] - CLIMB_BEYOND_DROP)
			return false

		xs_vec_copy(vOrigin, vStart)
		vStart[2] += 6.0
		engfunc(EngFunc_TraceLine, vStart, vDestination, IGNORE_MONSTERS, iMinion, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction >= 1.0)
			return false
	}

	get_entvar(iMinion, var_angles, vAngles)
	vDir[0] = floatcos(vAngles[1], degrees)
	vDir[1] = floatsin(vAngles[1], degrees)

	xs_vec_copy(vOrigin, vStart)
	vStart[2] += 6.0
	xs_vec_mul_scalar(vDir, necro_wall_reach(iMinion), vEnd)
	xs_vec_add(vStart, vEnd, vEnd)
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
	get_tr2(0, TR_flFraction, fFraction)
	if (fFraction >= 1.0)
		return false

	get_tr2(0, TR_vecPlaneNormal, vNormal)
	if (floatabs(vNormal[2]) > 0.3)
		return false

	vStart[2] = vOrigin[2] + CLIMB_MIN_WALL_HEIGHT
	xs_vec_mul_scalar(vDir, necro_wall_reach(iMinion), vEnd)
	xs_vec_add(vStart, vEnd, vEnd)
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
	get_tr2(0, TR_flFraction, fFraction)
	if (fFraction >= 1.0)
		return false

	vNormal[2] = 0.0
	xs_vec_normalize(vNormal, vNormal)
	xs_vec_neg(vNormal, g_vClimbDir[iMinion])

	g_bMinionClimb[iMinion] = true
	necro_climb_started(iMinion)
	g_vClimbFace[iMinion][0] = 0.0
	g_vClimbFace[iMinion][1] = 0.0
	g_vClimbFace[iMinion][2] = 1.0

	vector_to_angle(g_vClimbDir[iMinion], vAngles)
	vAngles[0] = CLIMB_PITCH
	set_entvar(iMinion, var_angles, vAngles)
	set_entvar(iMinion, var_gravity, CLIMB_NO_GRAVITY)
	set_entvar(iMinion, var_flags, get_entvar(iMinion, var_flags) & ~FL_ONGROUND)
	return true
}

necro_climb_set_angles(iMinion, const Float:vForward[3])
{
	new Float:vAngles[3], Float:vDirYaw[3]
	vector_to_angle(g_vClimbDir[iMinion], vDirYaw)

	vAngles[0] = floatasin(floatclamp(vForward[2], -1.0, 1.0), degrees)

	if (floatabs(vForward[2]) >= CLIMB_VERTICAL_DOT)
	{
		vAngles[0] = vForward[2] >= 0.0 ? 90.0 : -90.0
		vAngles[1] = vForward[2] >= 0.0 ? vDirYaw[1] : vDirYaw[1] + 180.0
		vAngles[2] = 0.0
	}
	else
	{
		new Float:vUp[3], Float:vRight[3], Float:vWorldUp[3] = {0.0, 0.0, 1.0}, Float:vWantUp[3]
		vAngles[1] = floatatan2(vForward[1], vForward[0], degrees)
		xs_vec_neg(g_vClimbDir[iMinion], vWantUp)
		xs_vec_mul_scalar(vForward, vForward[2], vUp)
		xs_vec_sub(vWorldUp, vUp, vUp)
		xs_vec_normalize(vUp, vUp)
		xs_vec_cross(vForward, vUp, vRight)
		vAngles[2] = CLIMB_ROLL_SIGN * floatatan2(xs_vec_dot(vWantUp, vRight), xs_vec_dot(vWantUp, vUp), degrees)
	}

	set_entvar(iMinion, var_angles, vAngles)
}

bool:necro_climb_fits(iMinion, const Float:vPos[3])
{
	engfunc(EngFunc_TraceMonsterHull, iMinion, vPos, vPos, IGNORE_MONSTERS, iMinion, 0)
	return bool:(!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid))
}

bool:necro_climb_inner_corner(iMinion, const Float:vOrigin[3], const Float:vTan[3])
{
	new Float:vStart[3], Float:vEnd[3], Float:vNormal[3], Float:fFraction
	xs_vec_copy(vOrigin, vStart)
	vStart[2] += 4.0
	xs_vec_mul_scalar(vTan, necro_wall_reach(iMinion), vEnd)
	xs_vec_add(vStart, vEnd, vEnd)
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
	get_tr2(0, TR_flFraction, fFraction)
	if (fFraction >= 1.0)
		return false

	get_tr2(0, TR_vecPlaneNormal, vNormal)
	if (floatabs(vNormal[2]) > 0.3 || xs_vec_dot(vNormal, vTan) > -0.7)
		return false

	vNormal[2] = 0.0
	xs_vec_normalize(vNormal, vNormal)
	xs_vec_neg(vNormal, g_vClimbDir[iMinion])
	g_fClimbWallDist[iMinion] = fFraction * necro_wall_reach(iMinion)
	g_vClimbFace[iMinion] = Float:{0.0, 0.0, 1.0}
	return true
}

bool:necro_climb_outer_corner(iMinion, const Float:vOrigin[3], const Float:vTan[3])
{
	new Float:vStart[3], Float:vEnd[3], Float:vNormal[3], Float:vHit[3], Float:fFraction
	xs_vec_mul_scalar(g_vClimbDir[iMinion], necro_climb_gap(iMinion) + CLIMB_CORNER_DEPTH, vStart)
	xs_vec_add(vOrigin, vStart, vStart)
	vStart[2] += 4.0
	xs_vec_mul_scalar(vTan, -CLIMB_CORNER_PROBE, vEnd)
	xs_vec_add(vStart, vEnd, vEnd)
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
	get_tr2(0, TR_flFraction, fFraction)
	if (fFraction >= 1.0 || fFraction < 0.01)
		return false

	get_tr2(0, TR_vecPlaneNormal, vNormal)
	if (floatabs(vNormal[2]) > 0.3 || xs_vec_dot(vNormal, vTan) < 0.7)
		return false

	get_tr2(0, TR_vecEndPos, vHit)
	vNormal[2] = 0.0
	xs_vec_normalize(vNormal, vNormal)

	new Float:vNewOrigin[3]
	xs_vec_mul_scalar(vNormal, necro_climb_gap(iMinion), vNewOrigin)
	xs_vec_add(vHit, vNewOrigin, vNewOrigin)
	vNewOrigin[2] = vOrigin[2]
	engfunc(EngFunc_SetOrigin, iMinion, vNewOrigin)

	xs_vec_neg(vNormal, g_vClimbDir[iMinion])
	g_fClimbWallDist[iMinion] = necro_climb_gap(iMinion)
	g_vClimbFace[iMinion] = Float:{0.0, 0.0, 1.0}
	return true
}

bool:necro_climb_try_down(iMinion, const Float:vOrigin[3], const Float:vDestination[3])
{
	if (!necro_climb_allowed(iMinion))
		return false

	if (vDestination[2] > vOrigin[2] - CLIMB_MARK_MIN_RISE)
		return false

	new Float:vAngles[3], Float:vDir[3], Float:vStart[3], Float:vEnd[3], Float:vNormal[3], Float:vHit[3], Float:fFraction
	get_entvar(iMinion, var_angles, vAngles)
	vDir[0] = floatcos(vAngles[1], degrees)
	vDir[1] = floatsin(vAngles[1], degrees)

	new Float:fReach = necro_climb_gap(iMinion) + CLIMB_CORNER_DEPTH
	xs_vec_copy(vOrigin, vStart)
	vStart[2] += 4.0
	xs_vec_mul_scalar(vDir, fReach, vEnd)
	xs_vec_add(vStart, vEnd, vEnd)
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
	get_tr2(0, TR_flFraction, fFraction)
	if (fFraction < 1.0)
		return false

	xs_vec_copy(vEnd, vStart)
	xs_vec_copy(vStart, vEnd)
	vEnd[2] -= CLIMB_EDGE_DROP
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
	get_tr2(0, TR_flFraction, fFraction)
	if (fFraction < 1.0)
		return false

	new Float:vProbe[3]
	new bool:bFace
	xs_vec_copy(vStart, vProbe)
	for (new d = 1; d <= 4 && !bFace; d++)
	{
		vStart[2] = vProbe[2] - d * 14.0
		xs_vec_mul_scalar(vDir, -(fReach + 24.0), vEnd)
		xs_vec_add(vStart, vEnd, vEnd)
		engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction >= 1.0 || fFraction < 0.01)
			continue

		get_tr2(0, TR_vecPlaneNormal, vNormal)
		if (floatabs(vNormal[2]) > 0.3 || xs_vec_dot(vNormal, vDir) < 0.7)
			continue

		bFace = true
	}

	if (!bFace)
		return false

	get_tr2(0, TR_vecEndPos, vHit)
	vNormal[2] = 0.0
	xs_vec_normalize(vNormal, vNormal)

	new Float:vToMark[3]
	xs_vec_sub(vDestination, vHit, vToMark)
	if (floatabs(xs_vec_dot(vToMark, vNormal)) > CLIMB_WALL_ATTACH_DIST)
		return false

	new Float:vNewOrigin[3]
	xs_vec_mul_scalar(vNormal, necro_climb_gap(iMinion), vNewOrigin)
	xs_vec_add(vHit, vNewOrigin, vNewOrigin)
	vNewOrigin[2] = vHit[2]
	engfunc(EngFunc_SetOrigin, iMinion, vNewOrigin)

	xs_vec_neg(vNormal, g_vClimbDir[iMinion])
	g_bMinionClimb[iMinion] = true
	necro_climb_started(iMinion)
	g_fClimbWallDist[iMinion] = necro_climb_gap(iMinion)
	g_vClimbFace[iMinion] = Float:{0.0, 0.0, -1.0}
	necro_climb_set_angles(iMinion, g_vClimbFace[iMinion])
	set_entvar(iMinion, var_gravity, CLIMB_NO_GRAVITY)
	set_entvar(iMinion, var_flags, get_entvar(iMinion, var_flags) & ~FL_ONGROUND)
	return true
}

bool:necro_climb_dest_face(iMinion, const Float:vDestination[3], Float:vFace[3])
{
	new Float:vTan[3], Float:vWorldUp[3] = {0.0, 0.0, 1.0}
	xs_vec_cross(vWorldUp, g_vClimbDir[iMinion], vTan)
	xs_vec_normalize(vTan, vTan)

	new Float:vStart[3], Float:vEnd[3], Float:fFraction
	for (new i; i < 2; i++)
	{
		xs_vec_mul_scalar(vTan, i ? -1.0 : 1.0, vFace)

		xs_vec_mul_scalar(vFace, 2.0, vStart)
		xs_vec_add(vDestination, vStart, vStart)
		xs_vec_mul_scalar(vFace, CLIMB_FACE_OPEN, vEnd)
		xs_vec_add(vStart, vEnd, vEnd)
		engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction < 1.0)
			continue

		xs_vec_mul_scalar(vFace, -CLIMB_FACE_SOLID, vEnd)
		xs_vec_add(vStart, vEnd, vEnd)
		engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction < 1.0)
			return true
	}

	return false
}

bool:necro_climb_tick(iMinion, const Float:vDestination[3])
{
	if (!g_bMinionClimb[iMinion])
		return false

	new Float:fGameTime = get_gametime()

	if (necro_climb_expired(iMinion))
		return false

	if (necro_minion_is_frozen(iMinion) || necro_minion_is_held(iMinion) || necro_minion_is_blind(iMinion) || necro_owner_blind(iMinion))
	{
		necro_climb_end(iMinion)
		return false
	}

	new Float:vOrigin[3], Float:vStart[3], Float:vEnd[3], Float:fFraction, Float:vVelocity[3]
	get_entvar(iMinion, var_origin, vOrigin)

	if (!necro_climb_fits(iMinion, vOrigin))
	{
		new bool:bFree, Float:vNudge[3]
		for (new i = 1; i <= 8 && !bFree; i++)
		{
			for (new k; k < 3 && !bFree; k++)
			{
				xs_vec_mul_scalar(g_vClimbDir[iMinion], -4.0 * i, vNudge)
				xs_vec_add(vOrigin, vNudge, vNudge)
				if (k)
					vNudge[2] += (k == 1 ? 1.0 : -1.0) * 4.0 * i
				if (necro_climb_fits(iMinion, vNudge))
				{
					engfunc(EngFunc_SetOrigin, iMinion, vNudge)
					xs_vec_copy(vNudge, vOrigin)
					bFree = true
				}
			}
		}

		if (!bFree)
		{
			necro_climb_end(iMinion)
			return false
		}
	}

	new Float:vWanted[3], Float:vPlane[3], Float:vForward[3]
	xs_vec_sub(vDestination, vOrigin, vWanted)
	new Float:fOffWall = xs_vec_dot(vWanted, g_vClimbDir[iMinion])
	xs_vec_mul_scalar(g_vClimbDir[iMinion], fOffWall, vPlane)
	xs_vec_sub(vWanted, vPlane, vPlane)
	new Float:fPlaneDist = xs_vec_len(vPlane)

	new bool:bBeyondWall = bool:(fOffWall > CLIMB_WALL_ATTACH_DIST)
	new Float:vFace[3]
	new bool:bAdjacent = bool:(floatabs(fOffWall) > CLIMB_WALL_ATTACH_DIST && necro_climb_dest_face(iMinion, vDestination, vFace))
	if (bAdjacent)
		bBeyondWall = false

	if ((bBeyondWall && vDestination[2] < vOrigin[2] - CLIMB_BEYOND_DROP)
		|| (!bAdjacent && !bBeyondWall && floatabs(fOffWall) > CLIMB_WALL_ATTACH_DIST && vDestination[2] < vOrigin[2] - CLIMB_MIN_RISE)
		|| (!bAdjacent && fOffWall < -CLIMB_WALL_ATTACH_DIST && vDestination[2] <= vOrigin[2] + CLIMB_MIN_RISE))
	{
		necro_climb_end(iMinion)
		return false
	}

	new bool:bArrived = bool:(!bAdjacent && !bBeyondWall && fPlaneDist < CLIMB_ARRIVE_DIST)
	if (bAdjacent)
	{
		vForward[0] = fOffWall < 0.0 ? -vFace[0] : vFace[0]
		vForward[1] = fOffWall < 0.0 ? -vFace[1] : vFace[1]
		vForward[2] = floatclamp((vDestination[2] - vOrigin[2]) / CLIMB_FACE_VERTICAL, -1.0, 1.0)
		xs_vec_normalize(vForward, vForward)
	}
	else if (bBeyondWall)
		vForward = Float:{0.0, 0.0, 1.0}
	else if (!bArrived)
		xs_vec_normalize(vPlane, vForward)

	new Float:vTan[3]
	vTan[0] = vForward[0]
	vTan[1] = vForward[1]
	new bool:bSide = bool:(!bArrived && !bBeyondWall && xs_vec_len(vTan) > 0.25)
	if (bSide)
	{
		xs_vec_normalize(vTan, vTan)
		if (necro_climb_inner_corner(iMinion, vOrigin, vTan))
		{
			xs_vec_mul_scalar(g_vClimbDir[iMinion], CLIMB_WALL_PRESS, vVelocity)
			set_entvar(iMinion, var_velocity, vVelocity)
			set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
			return true
		}
	}

	if (!bArrived && vForward[2] > 0.3)
	{
		xs_vec_copy(vOrigin, vStart)
		vStart[2] += 20.0
		xs_vec_copy(vStart, vEnd)
		vEnd[2] += 30.0
		engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction < 1.0)
		{
			necro_climb_end(iMinion)
			return false
		}
	}

	xs_vec_copy(vOrigin, vStart)
	vStart[2] += 4.0
	xs_vec_mul_scalar(g_vClimbDir[iMinion], necro_wall_reach(iMinion), vEnd)
	xs_vec_add(vStart, vEnd, vEnd)
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
	get_tr2(0, TR_flFraction, fFraction)
	g_fClimbWallDist[iMinion] = fFraction * necro_wall_reach(iMinion)

	if (fFraction >= 1.0)
	{
		if (bSide && necro_climb_outer_corner(iMinion, vOrigin, vTan))
		{
			xs_vec_mul_scalar(g_vClimbDir[iMinion], CLIMB_WALL_PRESS, vVelocity)
			set_entvar(iMinion, var_velocity, vVelocity)
			set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
			return true
		}

		if (!bArrived && vForward[2] > 0.3)
		{
			xs_vec_mul_scalar(g_vClimbDir[iMinion], CLIMB_VAULT_SPEED, vVelocity)
			vVelocity[2] = CLIMB_VAULT_LIFT
			necro_climb_end(iMinion)
			set_entvar(iMinion, var_velocity, vVelocity)
			set_entvar(iMinion, var_nextthink, fGameTime + 0.1)
			return true
		}

		necro_climb_end(iMinion)
		return false
	}

	xs_vec_mul_scalar(g_vClimbDir[iMinion], CLIMB_WALL_PRESS, vVelocity)
	if (bArrived)
	{
		set_entvar(iMinion, var_velocity, vVelocity)
		necro_climb_set_angles(iMinion, g_vClimbFace[iMinion])
		minion_play_idle(iMinion, 0.1)
		return true
	}

	if (vForward[2] < -0.3)
	{
		xs_vec_copy(vOrigin, vStart)
		xs_vec_copy(vOrigin, vEnd)
		vEnd[2] -= 6.0
		engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iMinion, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction < 1.0)
		{
			necro_climb_end(iMinion)
			return false
		}
	}

	xs_vec_copy(vForward, g_vClimbFace[iMinion])
	necro_climb_set_angles(iMinion, vForward)
	xs_vec_mul_scalar(vForward, CLIMB_SPEED, vForward)
	xs_vec_add(vVelocity, vForward, vVelocity)
	set_entvar(iMinion, var_velocity, vVelocity)
	necro_set_move_animation(iMinion, necro_climb_limited(iMinion))
	necro_voice_move(iMinion)
	set_entvar(iMinion, var_nextthink, fGameTime + 0.05)
	return true
}

minion_halt(iMinion)
{
	if (!g_bThinkHeld)
		set_entvar(iMinion, var_velocity, NULL_VECTOR)
}

bool:necro_player_stuck(iPlayer)
{
	return bool:(Player[iPlayer][PlrIsAlive] && (kc_player_in_freeze(iPlayer) || kc_player_get_capture(iPlayer) == CAPTURE_NORMAL))
}

necro_free_player(iPlayer)
{
	if (kc_player_in_freeze(iPlayer))
		kc_player_unfreeze(iPlayer)

	if (kc_player_get_capture(iPlayer) == CAPTURE_NORMAL)
		kc_player_set_capture(iPlayer, CAPTURE_NONE)
}

necro_find_stuck_ally(iOwner, const Float:vOrigin[3], Float:fRange, iIgnore, Float:vTargetOrigin[3])
{
	new iTarget, Float:fBestDistance = fRange, Float:fDistance, Float:vCandidateOrigin[3]
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == iIgnore || !Player[i][PlrIsAlive] || Player[i][PlrTeam] != Player[iOwner][PlrTeam] || !necro_player_stuck(i))
			continue

		get_entvar(i, var_origin, vCandidateOrigin)
		fDistance = get_distance_f(vOrigin, vCandidateOrigin)
		if (fDistance <= fBestDistance)
		{
			fBestDistance = fDistance
			iTarget = i
			xs_vec_copy(vCandidateOrigin, vTargetOrigin)
		}
	}

	return iTarget
}

bool:necro_move_mode_attack(iMinion, iOwner, iSlot, bool:bHeavy, const Float:vOrigin[3], bool:bReturning)
{
	new Float:fGameTime = get_gametime()
	new Float:fRange = bHeavy ? HEAVY_ATTACK_RANGE : ZERGLING_ATTACK_RANGE
	new iWindupTarget = Player[iOwner][PlrMoveWindupTarget][iSlot]

	if (iWindupTarget)
	{
		if (fGameTime < Player[iOwner][PlrMoveWindupEndAt][iSlot])
		{
			minion_halt(iMinion)
			set_entvar(iMinion, var_nextthink, fGameTime + 0.1)
			return true
		}

		Player[iOwner][PlrMoveWindupTarget][iSlot] = 0

		if (is_entity_player(iWindupTarget) && Player[iWindupTarget][PlrTeam] == Player[iOwner][PlrTeam])
		{
			new Float:vAllyOrigin[3]
			get_entvar(iWindupTarget, var_origin, vAllyOrigin)
			if (necro_player_stuck(iWindupTarget) && get_distance_f(vOrigin, vAllyOrigin) <= fRange)
				necro_free_player(iWindupTarget)
		}
		else if (necro_is_enemy_entity(iOwner, iWindupTarget))
		{
			new Float:vWindupOrigin[3]
			get_entvar(iWindupTarget, var_origin, vWindupOrigin)
			if (get_distance_f(vOrigin, vWindupOrigin) <= fRange)
				necro_attack_entity(iMinion, iOwner, iWindupTarget, bHeavy)
		}

		Player[iOwner][PlrMoveIgnoreTarget][iSlot] = iWindupTarget
		Player[iOwner][PlrMoveIgnoreUntil][iSlot] = fGameTime + MOVE_HIT_IGNORE_TIME
		return false
	}

	if (bReturning || Player[iOwner][PlrMinionNextAttackAt][iSlot] > fGameTime)
		return false

	new iIgnore = Player[iOwner][PlrMoveIgnoreUntil][iSlot] > fGameTime ? Player[iOwner][PlrMoveIgnoreTarget][iSlot] : 0
	new Float:vEnemyOrigin[3]
	new iEnemy = necro_find_stuck_ally(iOwner, vOrigin, fRange, iIgnore, vEnemyOrigin)

	if (!iEnemy)
		iEnemy = find_necro_target(iOwner, vOrigin, fRange, 0, vEnemyOrigin, iIgnore)

	if (!iEnemy)
		return false

	new Float:vSelfOrigin[3]
	xs_vec_copy(vOrigin, vSelfOrigin)
	npc_TurnToTarget(iMinion, vSelfOrigin, vEnemyOrigin)
	necro_play_attack_animation(iMinion, bHeavy)
	minion_halt(iMinion)

	Player[iOwner][PlrMinionNextAttackAt][iSlot] = fGameTime + necro_attack_interval(iMinion)
	Player[iOwner][PlrMoveWindupTarget][iSlot] = iEnemy
	Player[iOwner][PlrMoveWindupEndAt][iSlot] = fGameTime + MOVE_WINDUP_TIME
	set_entvar(iMinion, var_nextthink, fGameTime + MOVE_WINDUP_TIME)
	return true
}

public necro_zergling_think(iMinionEnt)
{
	necro_minion_think(iMinionEnt, false)
}

public necro_heavy_think(iHeavyEnt)
{
	necro_minion_think(iHeavyEnt, true)
}

public npc_TakeDamage(iMinionEnt, iInflictor, iAttacker, Float:fDamage, iDmgBits)
{
	if (get_entvar(iMinionEnt, var_impulse) != IMPULSE_MINION)
		return HAM_IGNORED

	if (get_entvar(iMinionEnt, var_flags) & FL_KILLME)
		return HAM_IGNORED

	new iOwner = get_entvar(iMinionEnt, var_npcowner)
	new Float:fGameTime = get_gametime()

	if (!is_entity_player(iOwner))
		return HAM_IGNORED

	if (g_bUltraHidden[iMinionEnt])
		return HAM_SUPERCEDE

	if (iDmgBits & DMG_NPC_HEAL)
	{
		if (is_entity_player(iAttacker) && Player[iOwner][PlrTeam] == Player[iAttacker][PlrTeam])
		{
			new Float:fCurrentHealth = Float:get_entvar(iMinionEnt, var_health)
			set_entvar(iMinionEnt, var_health, floatmin(necro_minion_max_health(iMinionEnt), fCurrentHealth + fDamage))
		}

		return HAM_SUPERCEDE
	}

	new iDamagedSlot, iDamagedOwner
	necro_find_minion_slot(iMinionEnt, iDamagedOwner, iDamagedSlot)

	if (is_entity_player(iAttacker))
	{
		if (Player[iOwner][PlrTeam] == Player[iAttacker][PlrTeam] && iOwner != iAttacker)
		{
			if (Float:get_entvar(iMinionEnt, var_npcspawntime) + NPC_TEAMMATE_DAMAGE_TIME < fGameTime)
				return HAM_SUPERCEDE
		}
	}

	new Float:vOrigin[3]
	new Float:fHealth = Float:get_entvar(iMinionEnt, var_health)
	get_entvar(iMinionEnt, var_origin, vOrigin)

	new bool:bDamageChanged
	if (!g_bMinionDot && (iDmgBits & DMG_NPC_SLOW))
		necro_minion_slow(iMinionEnt)

	if (!g_bMinionDot && (iDmgBits & DMG_ACID) && fDamage > 0.0)
		necro_minion_acid_hit(iMinionEnt, bool:(iDmgBits & DMG_NPC_ACID))

	if (g_bMinionDot)
	{
		if (fDamage < fHealth)
		{
			set_entvar(iMinionEnt, var_health, fHealth - fDamage)
			set_entvar(iMinionEnt, var_fuser3, fGameTime)
			necro_show_damage(iAttacker, iOwner, iMinionEnt, fDamage)
			return HAM_SUPERCEDE
		}
	}
	else if (iDmgBits & DMG_NPC_HOLD)
	{
		necro_minion_hold(iMinionEnt, fDamage, bool:(iDmgBits & DMG_NPC_ACID), bool:(iDmgBits & DMG_NPC_NOGLOW))
		return HAM_SUPERCEDE
	}
	else if (iDmgBits & DMG_NPC_BLIND)
	{
		necro_minion_blind(iMinionEnt)
		return HAM_SUPERCEDE
	}
	else if (iDmgBits & DMG_SLOWFREEZE)
	{
		necro_minion_chill(iMinionEnt)
		return HAM_SUPERCEDE
	}
	else if (iDmgBits & DMG_BURN)
	{
		necro_minion_burn(iMinionEnt, iAttacker)
		return HAM_SUPERCEDE
	}
	else if (iDmgBits & DMG_FREEZE)
	{
		if (necro_minion_freeze(iMinionEnt))
		{
			fDamage += MINION_FROZEN_HIT_DAMAGE
			SetHamParamFloat(4, fDamage)
			bDamageChanged = true
		}
		else if (fDamage <= 0.0)
			return HAM_SUPERCEDE
	}

	if (fDamage < fHealth)
	{
		set_entvar(iMinionEnt, var_fuser3, fGameTime)
		necro_show_damage(iAttacker, iOwner, iMinionEnt, fDamage)

		send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, MINION_BLOOD_COLOR, 5)
	}
	else
	{
		necro_show_damage(iAttacker, iOwner, iMinionEnt, fHealth)

		if (is_entity_player(iAttacker))
		{
			if (Player[iAttacker][PlrKnife] == g_iKnifeId)
				necro_register_kill(iAttacker)
		}

		if (iDamagedOwner)
		{
			minion_remove_lifebar(iDamagedOwner, iDamagedSlot)
			Player[iDamagedOwner][PlrMinionEnt][iDamagedSlot] = 0
			Player[iDamagedOwner][PlrMinionNextAttackAt][iDamagedSlot] = 0.0
			Player[iDamagedOwner][PlrMinionCharge][iDamagedSlot] = 0.0
			Player[iDamagedOwner][PlrMinionJumpUntil][iDamagedSlot] = 0.0
			Player[iDamagedOwner][PlrJumpPrevAction][iDamagedSlot] = -1
			Player[iDamagedOwner][PlrNpcAction][iDamagedSlot] = NPC_ACTION_FOLLOW
			Player[iDamagedOwner][PlrNpcActionTarget][iDamagedSlot] = 0
			Player[iDamagedOwner][PlrMinionWalking][iDamagedSlot] = false
			Player[iDamagedOwner][PlrMinionRespawnAt][iDamagedSlot] = fGameTime + MINION_RESPAWN_TIME
		}

		necro_voice_death(iMinionEnt)
		create_gore(vOrigin)

		set_entvar(iMinionEnt, var_solid, SOLID_NOT)
		set_entvar(iMinionEnt, var_health, 0.0)
		set_entvar(iMinionEnt, var_flags, FL_KILLME)
		set_entvar(iMinionEnt, var_nextthink, fGameTime)
		return HAM_SUPERCEDE
	}

	return bDamageChanged ? HAM_OVERRIDE : HAM_IGNORED
}

necro_show_damage(iAttacker, iOwner, iMinion, Float:fDamage)
{
	if (!is_entity_player(iAttacker) || !Player[iAttacker][PlrIsAlive]
		|| Player[iAttacker][PlrTeam] == Player[iOwner][PlrTeam])
		return

	kc_creature_take_damage(iMinion, iAttacker, fDamage)
}

minion_play_idle(iMinionEnt, Float:fNextThink=0.1)
{
	if (get_entvar(iMinionEnt, var_sequence) != 0 && get_gametime() >= Float:get_entvar(iMinionEnt, var_fuser4))
	{
		set_entvar(iMinionEnt, var_animtime, 0.0)
		set_entvar(iMinionEnt, var_frame, 0.0)
		set_entvar(iMinionEnt, var_sequence, 0)
	}
	set_entvar(iMinionEnt, var_nextthink, get_gametime() + fNextThink)
}

bool:necro_minion_is_frozen(iMinion)
{
	return bool:(g_fMinionFrozenUntil[iMinion] > get_gametime())
}

bool:necro_owner_blind(iMinion)
{
	new iOwner = get_entvar(iMinion, var_npcowner)
	return bool:(is_entity_player(iOwner) && kc_player_get_vision(iOwner) == VISION_BLIND)
}

bool:necro_minion_is_blind(iMinion)
{
	return bool:(g_fMinionBlindUntil[iMinion] > get_gametime())
}

necro_minion_blind(iMinion)
{
	g_fMinionBlindUntil[iMinion] = get_gametime() + MINION_BLIND_TIME
	necro_minion_update_glow(iMinion)
}

bool:necro_minion_is_held(iMinion)
{
	return bool:(g_fMinionHoldUntil[iMinion] > get_gametime())
}

necro_minion_hold(iMinion, Float:fTime, bool:bAcid, bool:bNoGlow)
{
	if (!bNoGlow || !necro_minion_is_held(iMinion))
	{
		g_bMinionHoldAcid[iMinion] = bAcid
		g_bMinionHoldNoGlow[iMinion] = bNoGlow
	}

	new Float:fUntil = get_gametime() + fTime
	if (fUntil > g_fMinionHoldUntil[iMinion])
		g_fMinionHoldUntil[iMinion] = fUntil

	new Float:vVelocity[3]
	get_entvar(iMinion, var_velocity, vVelocity)
	vVelocity[0] = 0.0
	vVelocity[1] = 0.0
	set_entvar(iMinion, var_velocity, vVelocity)
	set_entvar(iMinion, var_npctarget, 0)
	set_entvar(iMinion, var_npcspit, 0)

	necro_minion_update_glow(iMinion)
}

necro_minion_acid_hit(iMinion, bool:bGlow)
{
	new Float:fGameTime = get_gametime()

	if (bGlow)
		g_fMinionAcidUntil[iMinion] = fGameTime + MINION_ACID_GLOW_TIME
	g_fMinionPainStart[iMinion] = fGameTime

	new Float:vVelocity[3]
	get_entvar(iMinion, var_velocity, vVelocity)
	vVelocity[0] *= MINION_PAIN_MIN_MUL
	vVelocity[1] *= MINION_PAIN_MIN_MUL
	set_entvar(iMinion, var_velocity, vVelocity)

	necro_minion_update_glow(iMinion)
}

bool:necro_minion_is_chilled(iMinion)
{
	return bool:(g_fMinionChilledUntil[iMinion] > get_gametime())
}

necro_minion_update_glow(iMinion)
{
	if (necro_minion_is_frozen(iMinion) || necro_minion_is_chilled(iMinion))
	{
		set_entvar(iMinion, var_rendermode, kRenderNormal)
		set_entvar(iMinion, var_renderfx, kRenderFxGlowShell)
		set_entvar(iMinion, var_rendercolor, Float:{0.0, 180.0, 215.0})
		set_entvar(iMinion, var_renderamt, 16.0)
	}
	else if (g_iMinionBurnCycles[iMinion])
	{
		set_entvar(iMinion, var_rendermode, kRenderNormal)
		set_entvar(iMinion, var_renderfx, kRenderFxGlowShell)
		set_entvar(iMinion, var_rendercolor, Float:{255.0, 110.0, 0.0})
		set_entvar(iMinion, var_renderamt, 16.0)
	}
	else if (necro_minion_is_held(iMinion) && !g_bMinionHoldNoGlow[iMinion])
	{
		set_entvar(iMinion, var_rendermode, kRenderNormal)
		set_entvar(iMinion, var_renderfx, kRenderFxGlowShell)
		if (g_bMinionHoldAcid[iMinion])
			set_entvar(iMinion, var_rendercolor, Float:{ACID_COLOR_R.0, ACID_COLOR_G.0, ACID_COLOR_B.0})
		else
			set_entvar(iMinion, var_rendercolor, Float:{255.0, 255.0, 255.0})
		set_entvar(iMinion, var_renderamt, 16.0)
	}
	else if (g_fMinionAcidUntil[iMinion] > get_gametime())
	{
		set_entvar(iMinion, var_rendermode, kRenderNormal)
		set_entvar(iMinion, var_renderfx, kRenderFxGlowShell)
		set_entvar(iMinion, var_rendercolor, Float:{ACID_COLOR_R.0, ACID_COLOR_G.0, ACID_COLOR_B.0})
		set_entvar(iMinion, var_renderamt, 16.0)
	}
	else if (necro_minion_is_blind(iMinion))
	{
		set_entvar(iMinion, var_rendermode, kRenderNormal)
		set_entvar(iMinion, var_renderfx, kRenderFxGlowShell)
		set_entvar(iMinion, var_rendercolor, Float:{255.0, 255.0, 255.0})
		set_entvar(iMinion, var_renderamt, 16.0)
	}
	else
		set_entvar(iMinion, var_renderfx, kRenderFxNone)
}

necro_minion_remove_iceblock(iMinion, bool:bShatter)
{
	new iBlock = g_iMinionIceBlock[iMinion]
	g_iMinionIceBlock[iMinion] = 0
	if (!iBlock || !is_entity(iBlock))
		return

	if (bShatter)
	{
		new Float:vOrigin[3]
		get_entvar(iBlock, var_origin, vOrigin)
		send_msg_TE_IMPLOSION(vOrigin, 64, 10, 3)
		send_msg_TE_SPARKS(vOrigin)
		engfunc(EngFunc_EmitSound, iBlock, CHAN_BODY, SOUND_ICEBLOCK_CRASH, 1.0, ATTN_NORM, 0, PITCH_LOW)
	}

	rg_remove_entity(iBlock)
}

necro_minion_reset_status(iMinion)
{
	necro_minion_remove_iceblock(iMinion, false)
	g_fMinionFrozenUntil[iMinion] = 0.0
	g_fMinionChilledUntil[iMinion] = 0.0
	g_fMinionSlowUntil[iMinion] = 0.0
	g_fMinionBlindUntil[iMinion] = 0.0
	g_fMinionAcidUntil[iMinion] = 0.0
	g_fMinionPainStart[iMinion] = 0.0
	g_fMinionHoldUntil[iMinion] = 0.0
	g_iMinionBurnCycles[iMinion] = 0
	g_iMinionBurnAttacker[iMinion] = 0
	g_fMinionBurnNextTick[iMinion] = 0.0
	g_fMinionNextMoveVoice[iMinion] = 0.0
	g_fMoveBlockUntil[iMinion] = 0.0
	g_bMinionClimb[iMinion] = false
	g_fUltraRageUntil[iMinion] = 0.0
	g_fUltraRageReadyAt[iMinion] = 0.0
	g_bUltraBurrowed[iMinion] = false
	g_bUltraHidden[iMinion] = false
	g_fUltraBuryDoneAt[iMinion] = 0.0
	g_fUltraBurrowToggleAt[iMinion] = 0.0
	g_iUltraBurrowMark[iMinion] = 0
	g_fUltraWakeUntil[iMinion] = 0.0
}

necro_precache_sounds(const szSounds[][], iCount)
{
	for (new i; i < iCount; i++)
		precache_sound(szSounds[i])
}

necro_voice_yes(iMinion)
{
	new iType = get_entvar(iMinion, var_npctype)
	if (iType == 2)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_HYDRA_YES[random(sizeof SOUNDS_HYDRA_YES)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else if (iType)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ULTRALISK_YES[random(sizeof SOUNDS_ULTRALISK_YES)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ZERGLING_YES[random(sizeof SOUNDS_ZERGLING_YES)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_voice_attack(iMinion)
{
	new iType = get_entvar(iMinion, var_npctype)
	if (iType == 2)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_HYDRA_ATTACK[random(sizeof SOUNDS_HYDRA_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else if (iType)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ULTRALISK_ATTACK[random(sizeof SOUNDS_ULTRALISK_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ZERGLING_ATTACK[random(sizeof SOUNDS_ZERGLING_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_voice_death(iMinion)
{
	new iType = get_entvar(iMinion, var_npctype)
	if (iType == 2)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_HYDRA_DEATH[random(sizeof SOUNDS_HYDRA_DEATH)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else if (iType)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ULTRALISK_DEATH[random(sizeof SOUNDS_ULTRALISK_DEATH)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ZERGLING_DEATH[random(sizeof SOUNDS_ZERGLING_DEATH)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_voice_ready(iMinion)
{
	if (get_entvar(iMinion, var_npctype) == 2)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_HYDRA_READY[random(sizeof SOUNDS_HYDRA_READY)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ULTRALISK_READY[random(sizeof SOUNDS_ULTRALISK_READY)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_launch_sound(iMinion)
{
	engfunc(EngFunc_EmitSound, iMinion, CHAN_WEAPON, SOUNDS_HYDRA_LAUNCH[random(sizeof SOUNDS_HYDRA_LAUNCH)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_spit_impact_sound(iSpitEnt, iPitch)
{
	engfunc(EngFunc_EmitSound, iSpitEnt, CHAN_AUTO, SOUNDS_HYDRA_SPIT_IMPACT[random(sizeof SOUNDS_HYDRA_SPIT_IMPACT)], 1.0, ATTN_NORM, 0, iPitch)
}

necro_voice_move(iMinion)
{
	if (get_entvar(iMinion, var_npctype) == 2)
		return

	new Float:fGameTime = get_gametime()
	if (g_fMinionNextMoveVoice[iMinion] > fGameTime)
		return

	if (get_entvar(iMinion, var_npctype))
	{
		new iUltraSound = random(sizeof SOUNDS_ULTRALISK_MOVE)
		g_fMinionNextMoveVoice[iMinion] = fGameTime + ULTRALISK_MOVE_VOICE_DELAY[iUltraSound]
		engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ULTRALISK_MOVE[iUltraSound], 1.0, ATTN_NORM, 0, PITCH_NORM)
		return
	}

	new iSound = random(sizeof SOUNDS_ZERGLING_MOVE)
	g_fMinionNextMoveVoice[iMinion] = fGameTime + ZERGLING_MOVE_VOICE_DELAY[iSound]
	engfunc(EngFunc_EmitSound, iMinion, CHAN_VOICE, SOUNDS_ZERGLING_MOVE[iSound], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_voice_hit(iMinion)
{
	if (get_entvar(iMinion, var_npctype))
		engfunc(EngFunc_EmitSound, iMinion, CHAN_ITEM, SOUNDS_ULTRALISK_HIT[random(sizeof SOUNDS_ULTRALISK_HIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else
		engfunc(EngFunc_EmitSound, iMinion, CHAN_ITEM, SOUNDS_ZERGLING_HIT[random(sizeof SOUNDS_ZERGLING_HIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_minion_slow(iMinion)
{
	if (g_fMinionFrozenUntil[iMinion] > get_gametime())
		necro_minion_unfreeze(iMinion)

	g_fMinionSlowUntil[iMinion] = get_gametime() + MINION_SLOW_TIME
}

bool:necro_minion_freeze(iMinion)
{
	if (necro_minion_is_frozen(iMinion))
		return true

	new Float:fGameTime = get_gametime()

	g_iMinionBurnCycles[iMinion] = 0
	g_fMinionChilledUntil[iMinion] = 0.0
	g_fMinionFrozenUntil[iMinion] = fGameTime + FREEZE_TIME

	new Float:vVelocity[3], Float:vOrigin[3], Float:vAngles[3]
	get_entvar(iMinion, var_velocity, vVelocity)
	vVelocity[0] = 0.0
	vVelocity[1] = 0.0
	set_entvar(iMinion, var_velocity, vVelocity)
	set_entvar(iMinion, var_npctarget, 0)
	set_entvar(iMinion, var_framerate, 0.0)
	set_entvar(iMinion, var_nextthink, fGameTime + MINION_STATUS_TICK)

	engfunc(EngFunc_EmitSound, iMinion, CHAN_BODY, SOUND_FROST_HIT, 1.0, ATTN_NORM, 0, PITCH_HIGH)

	new iBlock = rg_create_entity(SZ_INFO_TARGET)
	if (!is_nullent(iBlock))
	{
		engfunc(EngFunc_SetModel, iBlock, MODEL_ICEBLOCK)
		set_entvar(iBlock, var_animtime, fGameTime)
		set_entvar(iBlock, var_frame, 0.0)
		set_entvar(iBlock, var_framerate, 0.7)
		set_entvar(iBlock, var_sequence, 0)
		set_entvar(iBlock, var_rendermode, kRenderNormal)
		set_entvar(iBlock, var_renderfx, kRenderFxGlowShell)
		set_entvar(iBlock, var_rendercolor, Float:{0.0, 180.0, 215.0})
		set_entvar(iBlock, var_renderamt, 16.0)

		vAngles[1] = random_float(0.0, 359.9)
		set_entvar(iBlock, var_angles, vAngles)
		get_entvar(iMinion, var_origin, vOrigin)
		vOrigin[2] += 18.0
		engfunc(EngFunc_SetOrigin, iBlock, vOrigin)
		set_entvar(iBlock, var_origin, vOrigin)
		engfunc(EngFunc_SetSize, iBlock, Float:{-8.0, -8.0, -4.0}, Float:{8.0, 8.0, 4.0})
		set_entvar(iBlock, var_owner, iMinion)

		SetThink(iBlock, "necro_iceblock_think")
		set_entvar(iBlock, var_nextthink, fGameTime + 0.2)
		g_iMinionIceBlock[iMinion] = iBlock
	}

	necro_minion_update_glow(iMinion)
	return false
}

necro_minion_unfreeze(iMinion)
{
	g_fMinionFrozenUntil[iMinion] = 0.0
	necro_minion_remove_iceblock(iMinion, true)
	set_entvar(iMinion, var_framerate, 1.0)
	set_entvar(iMinion, var_nextthink, get_gametime() + MINION_STATUS_TICK)
	g_fMinionChilledUntil[iMinion] = get_gametime() + CHILL_TIME
	necro_minion_update_glow(iMinion)
}

necro_minion_chill(iMinion)
{
	if (necro_minion_is_frozen(iMinion) || necro_minion_is_chilled(iMinion))
		return

	g_iMinionBurnCycles[iMinion] = 0
	g_fMinionChilledUntil[iMinion] = get_gametime() + CHILL_TIME
	engfunc(EngFunc_EmitSound, iMinion, CHAN_BODY, SOUND_FROST_HIT, 1.0, ATTN_NORM, 0, PITCH_LOW)
	necro_minion_update_glow(iMinion)
}

necro_minion_burn(iMinion, iAttacker)
{
	if (get_entvar(iMinion, var_flags) & FL_INWATER)
		return

	if (!g_iMinionBurnCycles[iMinion])
	{
		if (g_fMinionFrozenUntil[iMinion] > 0.0)
		{
			necro_minion_remove_iceblock(iMinion, true)
			set_entvar(iMinion, var_framerate, 1.0)
		}

		g_fMinionFrozenUntil[iMinion] = 0.0
		g_fMinionChilledUntil[iMinion] = 0.0
		g_fMinionBurnNextTick[iMinion] = get_gametime()
	}

	g_iMinionBurnCycles[iMinion] = max(g_iMinionBurnCycles[iMinion], MINION_BURN_CYCLES)
	g_iMinionBurnAttacker[iMinion] = iAttacker
	necro_minion_update_glow(iMinion)
}

public necro_iceblock_think(iBlock)
{
	if (is_nullent(iBlock))
		return

	new iMinion = get_entvar(iBlock, var_owner)
	if (!is_entity(iMinion) || (get_entvar(iMinion, var_flags) & FL_KILLME) || g_iMinionIceBlock[iMinion] != iBlock)
	{
		new Float:vOrigin[3]
		get_entvar(iBlock, var_origin, vOrigin)
		send_msg_TE_IMPLOSION(vOrigin, 64, 10, 3)
		send_msg_TE_SPARKS(vOrigin)
		rg_remove_entity(iBlock)
		return
	}

	set_entvar(iBlock, var_nextthink, get_gametime() + 0.2)
}

public necro_status_tick()
{
	new Float:fGameTime = get_gametime()
	new iMinion = NULLENT
	while ((iMinion = rg_find_ent_by_class(iMinion, _CLASSNAME_MINION)))
	{
		if (get_entvar(iMinion, var_impulse) != IMPULSE_MINION || (get_entvar(iMinion, var_flags) & FL_KILLME))
			continue

		if (g_fMinionFrozenUntil[iMinion] > 0.0 && g_fMinionFrozenUntil[iMinion] <= fGameTime)
			necro_minion_unfreeze(iMinion)

		if (g_fMinionChilledUntil[iMinion] > 0.0 && g_fMinionChilledUntil[iMinion] <= fGameTime)
		{
			g_fMinionChilledUntil[iMinion] = 0.0
			necro_minion_update_glow(iMinion)
		}

		if (g_fMinionBlindUntil[iMinion] > 0.0 && g_fMinionBlindUntil[iMinion] <= fGameTime)
		{
			g_fMinionBlindUntil[iMinion] = 0.0
			necro_minion_update_glow(iMinion)
		}

		if (g_fMinionHoldUntil[iMinion] > 0.0 && g_fMinionHoldUntil[iMinion] <= fGameTime)
		{
			g_fMinionHoldUntil[iMinion] = 0.0
			necro_minion_update_glow(iMinion)
		}

		if (g_fMinionAcidUntil[iMinion] > 0.0 && g_fMinionAcidUntil[iMinion] <= fGameTime)
		{
			g_fMinionAcidUntil[iMinion] = 0.0
			necro_minion_update_glow(iMinion)
		}

		if (!g_iMinionBurnCycles[iMinion])
			continue

		if (get_entvar(iMinion, var_flags) & FL_INWATER)
		{
			g_iMinionBurnCycles[iMinion] = 0
			necro_minion_update_glow(iMinion)
			continue
		}

		if (g_fMinionBurnNextTick[iMinion] > fGameTime)
			continue

		g_fMinionBurnNextTick[iMinion] = fGameTime + MINION_BURN_TICK

		new bool:bCrit = bool:(random_num(0, 100) <= MINION_BURN_CRIT_CHANCE)
		new Float:vOrigin[3]
		get_entvar(iMinion, var_origin, vOrigin)
		vOrigin[0] += random_float(-5.0, 5.0)
		vOrigin[1] += random_float(-5.0, 5.0)
		vOrigin[2] += random_float(0.0, 20.0)
		send_msg_TE_SPRITE(vOrigin, g_pFlameSpr, bCrit ? 30 : random_num(5, 10), 200)

		g_iMinionBurnCycles[iMinion]--
		new iAttacker = g_iMinionBurnAttacker[iMinion]
		if (!g_iMinionBurnCycles[iMinion])
			necro_minion_update_glow(iMinion)

		g_bMinionDot = true
		ExecuteHamB(Ham_TakeDamage, iMinion, 0, is_entity_player(iAttacker) ? iAttacker : 0,
			bCrit ? MINION_BURN_CRIT_DAMAGE : MINION_BURN_DAMAGE, DMG_BURN)
		g_bMinionDot = false
	}
}

public npc_Classify(const iEnt)
{
	if (is_nullent(iEnt))
		return HAM_IGNORED

	if (get_entvar(iEnt, var_impulse) != IMPULSE_MINION)
		return HAM_IGNORED

	SetHamReturnInteger(7) // CLASS_ALIEN_MONSTER
	return HAM_OVERRIDE
}

npc_TurnToTarget(iEnt, Float:vOrigin[3], Float:vTargetOrigin[3])
{
	if (g_bMinionClimb[iEnt])
	{
		new Float:vWanted[3], Float:vOffWall[3]
		xs_vec_sub(vTargetOrigin, vOrigin, vWanted)
		xs_vec_mul_scalar(g_vClimbDir[iEnt], xs_vec_dot(vWanted, g_vClimbDir[iEnt]), vOffWall)
		xs_vec_sub(vWanted, vOffWall, vWanted)
		if (xs_vec_len(vWanted) > 1.0)
		{
			xs_vec_normalize(vWanted, vWanted)
			xs_vec_copy(vWanted, g_vClimbFace[iEnt])
			necro_climb_set_angles(iEnt, vWanted)
		}
		return
	}

	static Float:x, Float:z, Float:fRadians, Float:vAngles[3]
	get_entvar(iEnt, var_angles, vAngles)
	vAngles[0] = vAngles[2] = 0.0
	x = vTargetOrigin[0] - vOrigin[0]
	z = vTargetOrigin[1] - vOrigin[1]

	if (floatabs(x) < 0.001)
		vAngles[1] = z >= 0.0 ? 90.0 : 270.0
	else
	{
		fRadians = floatatan(z / x, radian)
		vAngles[1] = fRadians * (180.0 / 3.14)

		if (vOrigin[0] > vTargetOrigin[0])
			vAngles[1] -= 180.0
	}

	set_entvar(iEnt, var_angles, vAngles)
}

bool:necro_wall_high(iEnt, Float:fYaw)
{
	new Float:vStart[3], Float:vEnd[3], Float:vNormal[3], Float:fFraction
	new Float:fNear = necro_probe_dist(iEnt), Float:fFar = necro_probe_dist(iEnt) + 8.0
	get_entvar(iEnt, var_origin, vStart)
	vStart[2] += 2.0
	for (new i = -1; i <= 1; i++)
	{
		vEnd[0] = floatcos(fYaw + i * 45.0, degrees) * fFar + vStart[0]
		vEnd[1] = floatsin(fYaw + i * 45.0, degrees) * fFar + vStart[1]
		vEnd[2] = vStart[2]
		engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iEnt, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction >= 1.0)
			continue

		get_tr2(0, TR_vecPlaneNormal, vNormal)
		if (vNormal[2] > 0.2 && vNormal[2] < 0.75)
			return true
	}

	vStart[2] += 42.0
	for (new i = -1; i <= 1; i++)
	{
		vEnd[0] = floatcos(fYaw + i * 45.0, degrees) * fNear + vStart[0]
		vEnd[1] = floatsin(fYaw + i * 45.0, degrees) * fNear + vStart[1]
		vEnd[2] = vStart[2]
		engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iEnt, 0)
		get_tr2(0, TR_flFraction, fFraction)
		if (fFraction < 0.9)
			return true
	}

	return false
}

npc_Move(ent, Float:fSpeed)
{
	static Float:vflVelocity[3]
	get_entvar(ent,var_velocity,vflVelocity)
	new Float:fProbe = necro_probe_dist(ent)
	new Float:fHopSpeed = necro_climb_limited(ent) ? 300.0 : 200.0
	new Float:fKeepVz = vflVelocity[2]

	static Float:vflAngles[3]
	get_entvar(ent, var_angles, vflAngles)

	static Float:vOrigin[3]
	get_entvar(ent, var_origin, vOrigin)
	vOrigin[2] += 2.0

	static Float:vflCheckPos[3]
	vflCheckPos[2] = vOrigin[2]

	// save forward velocity
	vflVelocity[0] = floatcos(vflAngles[1], degrees) * fSpeed
	vflVelocity[1] = floatsin(vflAngles[1], degrees) * fSpeed

	vflCheckPos[0] = floatcos(vflAngles[1], degrees) * fProbe + vOrigin[0]
	vflCheckPos[1] = floatsin(vflAngles[1], degrees) * fProbe + vOrigin[1]

	static Float:flFract, tr

	tr = create_tr2()
	engfunc(EngFunc_TraceLine, vOrigin, vflCheckPos, IGNORE_MONSTERS, ent, tr)
	get_tr2(tr, TR_flFraction, flFract)
	free_tr2(tr)

	if (flFract < 0.9)
	{
		vflVelocity[2] = fHopSpeed
	}
	else
	{
		// check Left
		vflCheckPos[0] = floatcos(vflAngles[1] - 45.0, degrees) * fProbe + vOrigin[0]
		vflCheckPos[1] = floatsin(vflAngles[1] - 45.0, degrees) * fProbe + vOrigin[1]

		tr = create_tr2()
		engfunc(EngFunc_TraceLine, vOrigin, vflCheckPos, IGNORE_MONSTERS, ent, tr)
		get_tr2(tr, TR_flFraction, flFract)
		free_tr2(tr)

		if(flFract < 0.9)
		{
			vflVelocity[2] = fHopSpeed
		}
		else
		{
			// check Right
			vflCheckPos[0] = floatcos(vflAngles[1] + 45.0, degrees) * fProbe + vOrigin[0]
			vflCheckPos[1] = floatsin(vflAngles[1] + 45.0, degrees) * fProbe + vOrigin[1]

			tr = create_tr2()
			engfunc(EngFunc_TraceLine, vOrigin, vflCheckPos, IGNORE_MONSTERS, ent, tr)
			get_tr2(tr, TR_flFraction, flFract)
			free_tr2(tr)

			if (flFract < 0.9)
				vflVelocity[2] = fHopSpeed
		}
	}
	if (vflVelocity[2] == fHopSpeed && necro_climb_limited(ent) && necro_wall_high(ent, vflAngles[1]))
		vflVelocity[2] = fKeepVz

	set_entvar(ent, var_velocity, vflVelocity)
}

create_zergling(Float:vOrigin[3], Float:vAngles[3], iOwner, iSlot = 0)
{
	new iTeam = Player[iOwner][PlrTeam]
	new iMinionEnt = rg_create_entity(SZ_EXPLOSION)
	if (is_nullent(iMinionEnt))
		return NULLENT

	necro_minion_reset_status(iMinionEnt)

	engfunc(EngFunc_SetOrigin, iMinionEnt, vOrigin)
	engfunc(EngFunc_SetModel, iMinionEnt, MODEL_ZERGLING)
	engfunc(EngFunc_SetSize, iMinionEnt, Float:{-ZERGLING_HULL_RADIUS, -ZERGLING_HULL_RADIUS, 0.0}, Float:{ZERGLING_HULL_RADIUS, ZERGLING_HULL_RADIUS, 20.0})

	set_entvar(iMinionEnt, var_origin, vOrigin)
	set_entvar(iMinionEnt, var_angles, vAngles)

	set_entvar(iMinionEnt, var_flags, FL_MONSTER)
	set_entvar(iMinionEnt, var_solid, SOLID_BBOX)
	set_entvar(iMinionEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iMinionEnt, var_skin, iTeam - 1)
	new Float:vVariant[3]
	vVariant[0] = iSlot == 1 ? 1.0 : 0.0
	set_entvar(iMinionEnt, var_vuser1, vVariant)
	set_entvar(iMinionEnt, var_rendermode, kRenderNormal)

	set_entvar(iMinionEnt, var_takedamage, 1.0)
	set_entvar(iMinionEnt, var_health, ZERGLING_HEALTH)

	set_entvar(iMinionEnt, var_classname, _CLASSNAME_MINION)
	set_entvar(iMinionEnt, var_impulse, IMPULSE_MINION)
	set_entvar(iMinionEnt, var_npcowner, iOwner)

	new Float:fGameTime = get_gametime()

	set_entvar(iMinionEnt, var_animtime, fGameTime)
	set_entvar(iMinionEnt, var_frame, 0.0)
	set_entvar(iMinionEnt, var_framerate, 1.0)
	set_entvar(iMinionEnt, var_sequence, 0)

	set_entvar(iMinionEnt, var_npctarget, 0)
	set_entvar(iMinionEnt, var_npctype, 0)
	set_entvar(iMinionEnt, var_npcspawntime, fGameTime)
	set_entvar(iMinionEnt, var_fuser3, fGameTime)
	set_entvar(iMinionEnt, var_nextthink, fGameTime + 0.7)

	SetThink(iMinionEnt, "necro_zergling_think")

	set_member(iMinionEnt, m_bloodColor, MINION_BLOOD_COLOR)

	drop_to_floor(iMinionEnt)

	new i
	for (i = 1; i <= MaxClients; i++)
		if (Player[i][PlrIsAlive])
			check_stuck(i, iMinionEnt, vOrigin)

	i = -1
	while ((i = find_ent_by_class(i, _CLASSNAME_MINION)))
		if (i != iMinionEnt)
			check_stuck_minions(i, iMinionEnt, vOrigin)

	return iMinionEnt
}

necro_spawn_unstick(iEnt, Float:vOrigin[3])
{
	if (necro_climb_fits(iEnt, vOrigin))
		return

	new Float:vCandidate[3]
	for (new iLift; iLift <= 8; iLift++)
	{
		for (new iRing; iRing <= 3; iRing++)
		{
			for (new iDir; iDir < (iRing ? 8 : 1); iDir++)
			{
				vCandidate[0] = vOrigin[0] + floatcos(iDir * 45.0, degrees) * iRing * 10.0
				vCandidate[1] = vOrigin[1] + floatsin(iDir * 45.0, degrees) * iRing * 10.0
				vCandidate[2] = vOrigin[2] + iLift * 6.0
				if (necro_climb_fits(iEnt, vCandidate))
				{
					xs_vec_copy(vCandidate, vOrigin)
					engfunc(EngFunc_SetOrigin, iEnt, vOrigin)
					return
				}
			}
		}
	}
}

create_heavy(Float:vOrigin[3], Float:vAngles[3], Float:fHealth, iOwner, bool:bHydra=false)
{
	new iHeavyEnt = rg_create_entity(SZ_EXPLOSION)
	if (is_nullent(iHeavyEnt))
		return NULLENT

	necro_minion_reset_status(iHeavyEnt)

	new iTeam = Player[iOwner][PlrTeam]

	engfunc(EngFunc_SetOrigin, iHeavyEnt, vOrigin)
	engfunc(EngFunc_SetModel, iHeavyEnt, bHydra ? MODEL_HYDRA : MODEL_ULTRALISK)
	new Float:fHullRadius = bHydra ? HYDRA_HULL_RADIUS : ULTRALISK_HULL_RADIUS
	new Float:vHullMins[3], Float:vHullMaxs[3]
	vHullMins[0] = vHullMins[1] = -fHullRadius
	vHullMaxs[0] = vHullMaxs[1] = fHullRadius
	vHullMaxs[2] = bHydra ? HYDRA_HULL_HEIGHT : ULTRALISK_HULL_HEIGHT
	engfunc(EngFunc_SetSize, iHeavyEnt, vHullMins, vHullMaxs)
	necro_spawn_unstick(iHeavyEnt, vOrigin)

	set_entvar(iHeavyEnt, var_origin, vOrigin)
	set_entvar(iHeavyEnt, var_flags, FL_MONSTER)
	set_entvar(iHeavyEnt, var_angles, vAngles)
	set_entvar(iHeavyEnt, var_solid, SOLID_BBOX)
	set_entvar(iHeavyEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iHeavyEnt, var_skin, iTeam - 1)
	set_entvar(iHeavyEnt, var_rendermode, kRenderNormal)

	set_entvar(iHeavyEnt, var_takedamage, 1.0)
	set_entvar(iHeavyEnt, var_health, fHealth > 0.0 ? fHealth : (bHydra ? HYDRA_HEALTH : HEAVY_HEALTH))

	set_entvar(iHeavyEnt, var_classname, _CLASSNAME_MINION)
	set_entvar(iHeavyEnt, var_impulse, IMPULSE_MINION)
	set_entvar(iHeavyEnt, var_npcowner, iOwner)

	new Float:fGameTime = get_gametime()

	set_entvar(iHeavyEnt, var_animtime, fGameTime)
	set_entvar(iHeavyEnt, var_frame, 0.0)
	set_entvar(iHeavyEnt, var_framerate, 1.0)
	set_entvar(iHeavyEnt, var_sequence, 1)

	set_entvar(iHeavyEnt, var_npctarget, 0)
	set_entvar(iHeavyEnt, var_npctype, bHydra ? 2 : 1)
	set_entvar(iHeavyEnt, var_npcspawntime, fGameTime)
	set_entvar(iHeavyEnt, var_fuser3, fGameTime)
	set_entvar(iHeavyEnt, var_nextthink, fGameTime + 1.13)

	SetThink(iHeavyEnt, "necro_heavy_think")

	necro_voice_ready(iHeavyEnt)

	set_member(iHeavyEnt, m_bloodColor, MINION_BLOOD_COLOR)

	new i
	for (i = 1; i <= MaxClients; i++)
		if (Player[i][PlrIsAlive])
			check_stuck(i, iHeavyEnt, vOrigin)

	i = -1
	while ((i = find_ent_by_class(i, _CLASSNAME_MINION)))
		if (i != iHeavyEnt)
			check_stuck_minions(i, iHeavyEnt, vOrigin)

	drop_to_floor(iHeavyEnt)
	return iHeavyEnt
}

create_gore(const Float:vOrigin[3])
{
	new iDecal = engfunc(EngFunc_DecalIndex, fmt("{yblood%d", random_num(1, 6)))
	if (iDecal > 0)
	{
		new Float:vDecalOrigin[3]
		vDecalOrigin[0] = vOrigin[0] + random_float(-50.0, 50.0)
		vDecalOrigin[1] = vOrigin[1] + random_float(-50.0, 50.0)
		vDecalOrigin[2] = vOrigin[2]
		send_msg_TE_WORLDDECAL(vDecalOrigin, iDecal)
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2] + 40.0)
	write_coord(random_num(-200, 200))
	write_coord(random_num(-200, 200))
	write_coord(random_num(80, 300))
	write_angle(random_num(0, 360))
	write_short(g_pGibs[2])
	write_byte(0)
	write_byte(400)
	message_end()

	for (new i; i < 4; i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		engfunc(EngFunc_WriteCoord, vOrigin[0])
		engfunc(EngFunc_WriteCoord, vOrigin[1])
		engfunc(EngFunc_WriteCoord, vOrigin[2] + 40.0)
		write_coord(random_num(-200, 200))
		write_coord(random_num(-200, 200))
		write_coord(random_num(80, 300))
		write_angle(random_num(0, 360))
		write_short(g_pGibs[random(2)])
		write_byte(0)
		write_byte(400)
		message_end()
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2] + 30.0)
	write_coord(random_num(-200, 200))
	write_coord(random_num(-200, 200))
	write_coord(random_num(80, 300))
	write_angle(random_num(0, 360))
	write_short(g_pGibs[3])
	write_byte(0)
	write_byte(400)
	message_end()

	for (new i; i <= 1; i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		engfunc(EngFunc_WriteCoord, vOrigin[0])
		engfunc(EngFunc_WriteCoord, vOrigin[1])
		engfunc(EngFunc_WriteCoord, vOrigin[2] + 10.0)
		write_coord(random_num(-200, 200))
		write_coord(random_num(-200, 200))
		write_coord(random_num(80, 300))
		write_angle(random_num(0, 360))
		write_short(g_pGibs[4])
		write_byte(0)
		write_byte(400)
		message_end()
	}

	for (new i, j, x, y, z; i < 3; i++)
	{
		x = random_num(-15, 15)
		y = random_num(-15, 15)
		z = random_num(-20, 25)

		for (j = 0; j < 2; j++)
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			engfunc(EngFunc_WriteCoord, vOrigin[0] + (x * j))
			engfunc(EngFunc_WriteCoord, vOrigin[1] + (y * j))
			engfunc(EngFunc_WriteCoord, vOrigin[2] + (z * j))
			write_short(g_pBloodSpraySpr)
			write_short(g_pBloodSpr)
			write_byte(MINION_BLOOD_COLOR)
			write_byte(15)
			message_end()
		}
	}
}

necro_execute_minions(iOwner)
{
	new Float:fGameTime = get_gametime()

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		new iMinionEnt = Player[iOwner][PlrMinionEnt][i]
		if (!iMinionEnt || !is_entity(iMinionEnt) || (get_entvar(iMinionEnt, var_flags) & FL_KILLME))
			continue

		new Float:vOrigin[3]
		get_entvar(iMinionEnt, var_origin, vOrigin)

		necro_voice_death(iMinionEnt)
		create_gore(vOrigin)

		minion_remove_lifebar(iOwner, i)
		Player[iOwner][PlrMinionEnt][i] = 0
		Player[iOwner][PlrMinionNextAttackAt][i] = 0.0

		set_entvar(iMinionEnt, var_solid, SOLID_NOT)
		set_entvar(iMinionEnt, var_health, 0.0)
		set_entvar(iMinionEnt, var_flags, FL_KILLME)
		set_entvar(iMinionEnt, var_nextthink, fGameTime)
	}
}

kill_all_npc(iOwner)
{
	Player[iOwner][PlrLaserPendingAt] = 0.0
	Player[iOwner][PlrLaserLockTime] = 0.0
	Player[iOwner][PlrModeChangeOrdered] = false

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		new iMinionEnt = Player[iOwner][PlrMinionEnt][i]
		minion_remove_lifebar(iOwner, i)
		if (iMinionEnt && !is_nullent(iMinionEnt))
			rg_remove_entity(iMinionEnt)

		Player[iOwner][PlrMinionEnt][i] = 0
		Player[iOwner][PlrMinionNextAttackAt][i] = 0.0
	}

	new iSpitEnt = NULLENT
	while ((iSpitEnt = rg_find_ent_by_class(iSpitEnt, _CLASSNAME_MINION_SPIT)))
	{
		if (get_entvar(iSpitEnt, var_owner) == iOwner)
			rg_remove_entity(iSpitEnt)
	}
}

rg_get_aim_origin(iPlayer, Float:vOrigin[3])
{
	new Float:vStart[3], Float:vViewOfs[3]
	get_entvar(iPlayer, var_origin, vStart)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vStart, vViewOfs, vStart)

	new Float:vDest[3]
	get_entvar(iPlayer, var_v_angle, vDest)
	engfunc(EngFunc_MakeVectors, vDest)
	global_get(glb_v_forward, vDest)
	xs_vec_mul_scalar(vDest, 8192.0, vDest)
	xs_vec_add(vStart, vDest, vDest)

	new Float:vDir[3]
	xs_vec_sub(vDest, vStart, vDir)
	xs_vec_normalize(vDir, vDir)

	new iIgnore = iPlayer, iHit
	for (new i; i < 8; i++)
	{
		engfunc(EngFunc_TraceLine, vStart, vDest, 0, iIgnore, 0)
		get_tr2(0, TR_vecEndPos, vOrigin)
		iHit = get_tr2(0, TR_pHit)

		if (iHit <= MaxClients || !is_entity(iHit) || get_entvar(iHit, var_impulse) != IMPULSE_MINION
			|| get_entvar(iHit, var_skin) + 1 != Player[iPlayer][PlrTeam])
			break

		xs_vec_add(vOrigin, vDir, vStart)
		iIgnore = iHit
		iHit = 0
	}

	return iHit
}

new const Float:fUnstuckSize[][3] =
{
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 6.0}, {0.0, 0.0, -6.0}, {0.0, 6.0, 0.0}, {0.0, -6.0, 0.0}, {6.0, 0.0, 0.0}, {-6.0, 0.0, 0.0}, {-6.0, 6.0, 6.0}, {6.0, 6.0, 6.0}, {6.0, -6.0, 6.0}, {6.0, 6.0, -6.0}, {-6.0, -6.0, 6.0}, {6.0, -6.0, -6.0}, {-6.0, 6.0, -6.0}, {-6.0, -6.0, -6.0},
	{0.0, 0.0, 8.0}, {0.0, 0.0, -8.0}, {0.0, 8.0, 0.0}, {0.0, -8.0, 0.0}, {8.0, 0.0, 0.0}, {-8.0, 0.0, 0.0}, {-8.0, 8.0, 8.0}, {8.0, 8.0, 8.0}, {8.0, -8.0, 8.0}, {8.0, 8.0, -8.0}, {-8.0, -8.0, 8.0}, {8.0, -8.0, -8.0}, {-8.0, 8.0, -8.0}, {-8.0, -8.0, -8.0},
	{0.0, 0.0, 10.0}, {0.0, 0.0, -10.0}, {0.0, 10.0, 0.0}, {0.0, -10.0, 0.0}, {10.0, 0.0, 0.0}, {-10.0, 0.0, 0.0}, {-10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}, {10.0, -10.0, 10.0}, {10.0, 10.0, -10.0}, {-10.0, -10.0, 10.0}, {10.0, -10.0, -10.0}, {-10.0, 10.0, -10.0}, {-10.0, -10.0, -10.0},
	{0.0, 0.0, 20.0}, {0.0, 0.0, -20.0}, {0.0, 20.0, 0.0}, {0.0, -20.0, 0.0}, {20.0, 0.0, 0.0}, {-20.0, 0.0, 0.0}, {-20.0, 20.0, 20.0}, {20.0, 20.0, 20.0}, {20.0, -20.0, 20.0}, {20.0, 20.0, -20.0}, {-20.0, -20.0, 20.0}, {20.0, -20.0, -20.0}, {-20.0, 20.0, -20.0}, {-20.0, -20.0, -20.0},
	{0.0, 0.0, 30.0}, {0.0, 0.0, -30.0}, {0.0, 30.0, 0.0}, {0.0, -30.0, 0.0}, {30.0, 0.0, 0.0}, {-30.0, 0.0, 0.0}, {-30.0, 30.0, 30.0}, {30.0, 30.0, 30.0}, {30.0, -30.0, 30.0}, {30.0, 30.0, -30.0}, {-30.0, -30.0, 30.0}, {30.0, -30.0, -30.0}, {-30.0, 30.0, -30.0}, {-30.0, -30.0, -30.0}
}

check_stuck(id, ent, Float:vNpcOrigin[3])
{
	new Float:vOrigin[3]
	get_entvar(id, var_origin, vOrigin)

	if (get_distance_f(vNpcOrigin, vOrigin) > 60.0)
		return

	if (get_entvar(id, var_movetype) == MOVETYPE_NOCLIP || (get_entvar(id, var_solid) & SOLID_NOT))
		return

	new Float:vPlrMins[3], Float:vPlrMaxs[3], Float:vMins[2][3], Float:vMaxs[2][3]
	get_entvar(id, var_mins, vPlrMins)
	get_entvar(id, var_maxs, vPlrMaxs)
	get_entvar(ent, var_mins, vMins[1])
	get_entvar(ent, var_maxs, vMaxs[1])

	xs_vec_add(vPlrMins, vOrigin, vMins[0])
	xs_vec_add(vPlrMaxs, vOrigin, vMaxs[0])
	xs_vec_add(vMins[1], vNpcOrigin, vMins[1])
	xs_vec_add(vMaxs[1], vNpcOrigin, vMaxs[1])

	if (!boxes_intersect(vMins[0], vMaxs[0], vMins[1], vMaxs[1]))
		return

	new Float:vVec[3],
	hull = get_entvar(id, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN

	for (new i; i < sizeof fUnstuckSize; i++)
	{
		vVec[0] = vOrigin[0] - vPlrMins[0] * fUnstuckSize[i][0]
		vVec[1] = vOrigin[1] - vPlrMins[1] * fUnstuckSize[i][1]
		vVec[2] = vOrigin[2] - floatmin(vPlrMins[2],6.0) * fUnstuckSize[i][2]

		xs_vec_add(vPlrMins, vVec, vMins[0])
		xs_vec_add(vPlrMaxs, vVec, vMaxs[0])

		if (is_hull_vacant(vVec, hull, id))
		{
			engfunc(EngFunc_SetOrigin, id, vVec)
			set_entvar(id, var_origin, vVec)
			break
		}
	}
}

check_stuck_minions(zmb, ent, Float:vNpcOrigin[3])
{
	if (get_entvar(zmb, var_flags) & FL_KILLME)
		return

	new Float:vOrigin[3]
	get_entvar(zmb, var_origin, vOrigin)

	if (get_distance_f(vNpcOrigin, vOrigin) > 60.0)
		return

	new Float:vZmbMins[3], Float:vZmbMaxs[3], Float:vMins[2][3], Float:vMaxs[2][3]
	get_entvar(zmb, var_mins, vZmbMins)
	get_entvar(zmb, var_maxs, vZmbMaxs)
	get_entvar(ent, var_mins, vMins[1])
	get_entvar(ent, var_maxs, vMaxs[1])

	xs_vec_add(vZmbMins, vOrigin, vMins[0])
	xs_vec_add(vZmbMaxs, vOrigin, vMaxs[0])
	xs_vec_add(vMins[1], vNpcOrigin, vMins[1])
	xs_vec_add(vMaxs[1], vNpcOrigin, vMaxs[1])

	if (!boxes_intersect(vMins[0], vMaxs[0], vMins[1], vMaxs[1]))
		return

	new Float:vVec[3], Float:vCheck[3]
	for (new i; i < sizeof fUnstuckSize; i++)
	{
		vVec[0] = vOrigin[0] + vZmbMaxs[0] * fUnstuckSize[i][0]
		vVec[1] = vOrigin[1] + vZmbMaxs[1] * fUnstuckSize[i][1]
		vVec[2] = vOrigin[2] + vZmbMaxs[2] * fUnstuckSize[i][2]

		xs_vec_add(vZmbMins, vVec, vMins[0])
		xs_vec_add(vZmbMaxs, vVec, vMaxs[0])

		xs_vec_copy(vVec, vCheck)
		vCheck[2] += 36.0

		if (!boxes_intersect(vMins[0], vMaxs[0], vMins[1], vMaxs[1])
			&& is_hull_vacant(vCheck, HULL_LARGE, zmb))
		{
			engfunc(EngFunc_SetOrigin, zmb, vVec)
			set_entvar(zmb, var_origin, vVec)
			break
		}
	}
}

clear_npc_action_target(iTarget)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrKnife] != g_iKnifeId)
			continue

		for (new iSlot; iSlot < MAX_MINION_SLOTS; iSlot++)
		{
			if ((Player[i][PlrNpcAction][iSlot] == NPC_ACTION_TARGET || Player[i][PlrNpcAction][iSlot] == NPC_ACTION_SHOOT) && Player[i][PlrNpcActionTarget][iSlot] == iTarget)
			{
				new iMinion = Player[i][PlrMinionEnt][iSlot]
				if (iMinion && is_entity(iMinion))
				{
					new Float:vMinionOrigin[3]
					get_entvar(iMinion, var_origin, vMinionOrigin)
					necro_hold_position(i, iSlot, vMinionOrigin)
				}
				else
				{
					Player[i][PlrNpcAction][iSlot] = NPC_ACTION_FOLLOW
					Player[i][PlrNpcActionTarget][iSlot] = 0
				}
			}
		}
	}
}

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)
}
