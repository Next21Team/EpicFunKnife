#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Necro Knife"

#define KNIFE_CLASSNAME "weapon_next21_necro"
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
#define MINION_SLOT_CENTAUR	0
#define MINION_RESPAWN_TIME	15.0
#define MINION_SPAWN_DELAY	5.0
#define MINION_SPAWN_DISTANCE	100.0
#define MINION_SPAWN_ANGLE	45.0
#define MINION_ATTACK_INTERVAL	0.8
#define FORM_SWITCH_COOLDOWN	10.0

#define MINION_FOLLOW_RADIUS	600.0
#define MINION_TARGET_RADIUS	800.0
#define MINION_RECALL_DISTANCE	500.0
#define MINION_MOVE_COMMAND_RANGE	500.0
#define MINION_FORMATION_LEASH	150.0
#define MOVE_WINDUP_TIME	0.3
#define ATTACK_WINDUP_TIME	0.3
#define ATTACK_RANGE_TOLERANCE	30.0
#define ATTACK_ANIM_LOCK_TIME	0.5
#define MOVE_HIT_IGNORE_TIME	0.5
#define CENTAUR_FOLLOW_STOP_DISTANCE	100.0
#define CENTAUR_AGGRESSION_RADIUS	1000.0
#define MINION_RETURN_SPEED	250.0
#define ZOMBIE_SPEED		250.0
#define CANNIBALIZE_WINDUP_TIME	0.3
#define IMPULSE_NECRO_LIFEBAR	30000100

new const MODEL_V_KNIFE[] = "models/next21_efk/v_necro_knife_b02.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_necro_knife.mdl"

new const SOUND_KNIFE_HIT1[] = "next21_efk/necro_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[] = "next21_efk/necro_knife_hit2.wav"
new const SOUND_KNIFE_STAB[] = "next21_efk/necro_knife_stab.wav"
new const SOUND_KNIFE_HITWALL[] = "next21_efk/necro_knife_hitwall.wav"
new const SOUND_KNIFE_SLASH[] = "next21_efk/necro_knife_slash.wav"

new const MODEL_ZOMBIE[] = "models/next21_efk/zombie_v2.mdl"
new const MODEL_CENTAUR[] = "models/next21_efk/centaur.mdl"

#define SPIT_DAMAGE		20.0
#define SPIT_LIFETIME	45.0

new const MODEL_SPIT[] = "models/next21_efk/crimson_spore.mdl"
new const MODEL_MINION_LIFEBAR[] = "sprites/next21_efk/lifebar_necro.spr"
new const MODEL_MINION_LIFEBAR_B[] = "sprites/next21_efk/lifebar_necro2.spr"
new const SZ_ENV_SPRITE[] = "env_sprite"

new const SOUND_SOUL[] = "next21_efk/soul_pulse.wav"

#define NPC_TEAMMATE_DAMAGE_TIME 5.0

#define ZOMBIE_HEALTH			90.0
#define ZOMBIE_MIN_DAMAGE		20.0
#define ZOMBIE_MAX_DAMAGE		30.0
#define ZOMBIE_HIT_HEAL_PERCENT	0.25
#define ZOMBIE_ATTACK_RANGE		90.0
#define ZOMBIE_REGEN_DELAY		5.0
#define ZOMBIE_REGEN_RATE		5.0

#define CENTAUR_HEALTH			180.0
#define CENTAUR_MIN_DAMAGE		30.0
#define CENTAUR_MAX_DAMAGE		40.0
#define CENTAUR_ATTACK_RANGE	90.0
#define CENTAUR_SPIT_MIN_RANGE	250.0
#define CENTAUR_SPIT_SEARCH_RANGE	4000.0

#define LASER_CHARGE_TIME		1.0
#define LASER_INDICATE_TIME	0.5
#define LASER_DAMAGE			30.0
#define LASER_TRACE_OVERSHOOT	24.0
#define FOLLOW_TAP_TIME	0.3
#define ZOMBIE_JUMP_SPEED	650.0
#define ZOMBIE_JUMP_LIFT	250.0
#define ZOMBIE_JUMP_MAX_TIME	1.0

#define CORPSE_HEAL				50.0

#define MINION_CHILL_SPEED_MUL		0.4
#define MINION_SLOW_SPEED_MUL		0.35
#define MINION_SLOW_TIME			3.0
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

new const _CLASSNAME_ZOMBIE[]		= CLASSNAME_ZOMBIE
new const _CLASSNAME_ZOMBIE_SPIT[]	= CLASSNAME_ZOMBIE_SPIT

new const SOUNDS_CRIT[][] =
{
	"next21_efk/frash_explosion01.wav",
	"next21_efk/frash_explosion02.wav",
	"next21_efk/frash_explosion03.wav"
}

new const SOUNDS_ZOMBIE_ATTACK[][] =
{
	"next21_efk/zombie_attack01.wav",
	"next21_efk/zombie_attack02.wav",
	"next21_efk/zombie_attack03.wav",
	"next21_efk/zombie_attack04.wav"
}

new const SOUNDS_ZOMBIE_PAIN[][] =
{
	"next21_efk/zombie_pain01.wav",
	"next21_efk/zombie_pain02.wav",
	"next21_efk/zombie_pain03.wav",
	"next21_efk/zombie_pain04.wav"
}

enum NecroForm
{
	FORM_ZOMBIES,
	FORM_CENTAUR
}

enum NpcAction
{
	NPC_ACTION_FOLLOW,
	NPC_ACTION_MOVE,
	NPC_ACTION_TARGET
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
	Float:PlrZombieCharge[MAX_MINION_SLOTS],
	Float:PlrMinionJumpUntil[MAX_MINION_SLOTS],
	Float:PlrChargeLastTick,
	Float:PlrMergeAt,
	bool:PlrMergeOrdered,
	PlrSouls
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
	Float:g_fMinionFrozenUntil[MAX_ENTITIES_NUM + 1], Float:g_fMinionChilledUntil[MAX_ENTITIES_NUM + 1],
	Float:g_fMinionSlowUntil[MAX_ENTITIES_NUM + 1],
	g_iMinionBurnCycles[MAX_ENTITIES_NUM + 1], g_iMinionBurnAttacker[MAX_ENTITIES_NUM + 1],
	Float:g_fMinionBurnNextTick[MAX_ENTITIES_NUM + 1], g_iMinionIceBlock[MAX_ENTITIES_NUM + 1],
	bool:g_bMinionDot,
	g_pShockwaveSpr, g_pBloodSpr, g_pBloodSpraySpr, g_pGibs[5], g_pKnifePMdl,
	g_pFlameSpr, g_pPointSpr, g_pLaserbeamSpr

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

	for (new i; i < sizeof SOUNDS_CRIT; i++)
		precache_sound(SOUNDS_CRIT[i])

	for (new i; i < sizeof SOUNDS_ZOMBIE_ATTACK; i++)
		precache_sound(SOUNDS_ZOMBIE_ATTACK[i])

	for (new i; i < sizeof SOUNDS_ZOMBIE_PAIN; i++)
		precache_sound(SOUNDS_ZOMBIE_PAIN[i])

	precache_model(MODEL_ZOMBIE)
	precache_model(MODEL_ICEBLOCK)
	precache_sound(SOUND_FROST_HIT)
	precache_sound(SOUND_ICEBLOCK_CRASH)
	g_pFlameSpr = precache_model(SPRITE_FLAME)
	precache_model(MODEL_CENTAUR)
	precache_model(MODEL_SPIT)
	precache_model(MODEL_MINION_LIFEBAR)
	precache_model(MODEL_MINION_LIFEBAR_B)

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
	g_pLaserbeamSpr = precache_model("sprites/laserbeam.spr")
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		engfunc(EngFunc_AllocString, MODEL_V_KNIFE), engfunc(EngFunc_AllocString, MODEL_P_KNIFE),
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, 0.0, ABIL1_TYPE, ABIL1_MINDIST, ABIL1_MAXDIST)
	kc_register_ability4(g_iKnifeId, ABIL4_NAME, ABIL4_CHARGE)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH)

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
	Player[iPlayer][PlrForm] = FORM_ZOMBIES
	Player[iPlayer][PlrSouls] = 0
	necro_reset_npc_actions(iPlayer)
	arrayset(Player[iPlayer][PlrMinionEnt], 0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionBarEnt], 0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionRespawnAt], 0.0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionNextAttackAt], 0.0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrZombieCharge], 0.0, MAX_MINION_SLOTS)
	arrayset(Player[iPlayer][PlrMinionJumpUntil], 0.0, MAX_MINION_SLOTS)
	Player[iPlayer][PlrChargeLastTick] = 0.0
	Player[iPlayer][PlrLaserPendingAt] = 0.0
	Player[iPlayer][PlrLaserLockTime] = 0.0
	Player[iPlayer][PlrLaserIndicateEndAt] = 0.0
	Player[iPlayer][PlrLastFormSwitch] = 0.0
	Player[iPlayer][PlrMergeAt] = 0.0
	Player[iPlayer][PlrMergeOrdered] = false
}

necro_reset_npc_actions(iOwner)
{
	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		Player[iOwner][PlrNpcAction][i] = NPC_ACTION_FOLLOW
		Player[iOwner][PlrNpcActionTarget][i] = 0
		Player[iOwner][PlrMinionWalking][i] = false
		Player[iOwner][PlrMoveWindupTarget][i] = 0
		Player[iOwner][PlrZombieCharge][i] = 0.0
		Player[iOwner][PlrMinionJumpUntil][i] = 0.0
		Player[iOwner][PlrMoveIgnoreTarget][i] = 0
		Player[iOwner][PlrMoveIgnoreUntil][i] = 0.0
	}
}

public client_disconnected(iPlayer)
{
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
			necro_reset_npc_actions(iPlayer)
			kill_all_npc(iPlayer)
			necro_schedule_form(iPlayer, MINION_SPAWN_DELAY)
		}
	}
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_ZOMBIE)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_ZOMBIE_SPIT)))
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

	if (get_entvar(iPlayer, var_button) & IN_RELOAD)
	{
		if (Player[iPlayer][PlrForm] == FORM_ZOMBIES)
			necro_order_merge(iPlayer)
		else
			necro_finish_split(iPlayer)

		set_entvar(iPlayer, var_impulse, 0)
	}

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
		if (Player[iPlayer][PlrForm] == FORM_CENTAUR && iSlot == 1)
			continue

		if (iReleased & iSlotKeys[iSlot])
		{
			if (!bKeyUsed[iPlayer][iSlot] && fGameTime - fKeyDownAt[iPlayer][iSlot] <= FOLLOW_TAP_TIME)
			{
				Player[iPlayer][PlrNpcAction][iSlot] = NPC_ACTION_FOLLOW
				Player[iPlayer][PlrNpcActionTarget][iSlot] = 0
				Player[iPlayer][PlrMinionWalking][iSlot] = true
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
			necro_command_target(iPlayer, iSlot)
		}
		else if (bRmb)
		{
			bKeyUsed[iPlayer][iSlot] = true
			necro_use_ultimate(iPlayer, iSlot)
		}
	}

	return HC_CONTINUE
}

necro_use_ultimate(iPlayer, iSlot)
{
	if (kc_player_in_silence(iPlayer) || kc_player_in_darkness(iPlayer) || kc_player_get_capture(iPlayer) != CAPTURE_NONE)
		return

	if (Player[iPlayer][PlrForm] == FORM_CENTAUR)
		necro_centaur_laser(iPlayer)
	else
		necro_zombie_dash(iPlayer, iSlot)
}

necro_zombie_dash(iPlayer, iSlot)
{
	if (Player[iPlayer][PlrZombieCharge][iSlot] < 100.0)
		return

	new iMinion = Player[iPlayer][PlrMinionEnt][iSlot]
	if (!iMinion || !is_entity(iMinion) || (get_entvar(iMinion, var_flags) & FL_KILLME) || necro_minion_is_frozen(iMinion))
		return

	new Float:fGameTime = get_gametime()
	if (Player[iPlayer][PlrMinionJumpUntil][iSlot] > fGameTime)
		return

	new Float:vOrigin[3], Float:vTargetOrigin[3], Float:vAimOrigin[3]
	get_entvar(iMinion, var_origin, vOrigin)

	new iAimEnt = rg_get_aim_origin(iPlayer, vAimOrigin)
	new iTarget
	if (is_entity_player(iAimEnt) && necro_is_enemy_entity(iPlayer, iAimEnt))
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
	}

	if (!iTarget)
		return

	new Float:vVelocity[3]
	xs_vec_sub(vTargetOrigin, vOrigin, vVelocity)
	new Float:fDistance = xs_vec_len(vVelocity)
	if (fDistance < 1.0)
		return

	npc_TurnToTarget(iMinion, vOrigin, vTargetOrigin)
	xs_vec_mul_scalar(vVelocity, ZOMBIE_JUMP_SPEED / fDistance, vVelocity)
	vVelocity[2] = floatmax(vVelocity[2] + ZOMBIE_JUMP_LIFT, ZOMBIE_JUMP_LIFT)
	set_entvar(iMinion, var_velocity, vVelocity)
	set_entvar(iMinion, var_flags, get_entvar(iMinion, var_flags) & ~FL_ONGROUND)

	Player[iPlayer][PlrNpcAction][iSlot] = NPC_ACTION_TARGET
	Player[iPlayer][PlrNpcActionTarget][iSlot] = iTarget
	Player[iPlayer][PlrMinionJumpUntil][iSlot] = fGameTime + ZOMBIE_JUMP_MAX_TIME
	Player[iPlayer][PlrZombieCharge][iSlot] = 0.0

	engfunc(EngFunc_EmitSound, iMinion, CHAN_AUTO, SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

necro_command_target(iPlayer, iSlot)
{
	new Float:vAimOrigin[3], Float:vPlayerOrigin[3]
	new iAimEnt = rg_get_aim_origin(iPlayer, vAimOrigin)
	get_entvar(iPlayer, var_origin, vPlayerOrigin)

	new Float:fAimDistance = get_distance_f(vPlayerOrigin, vAimOrigin)

	new bool:bTargetable = bool:(necro_is_enemy_entity(iPlayer, iAimEnt)
		|| (is_entity(iAimEnt) && get_entvar(iAimEnt, var_impulse) == IMPULSE_PRESENT
			&& !(get_entvar(iAimEnt, var_flags) & FL_KILLME)))

	if (bTargetable)
	{
		if (fAimDistance > MINION_TARGET_RADIUS)
			return

		Player[iPlayer][PlrNpcAction][iSlot] = NPC_ACTION_TARGET
		Player[iPlayer][PlrNpcActionTarget][iSlot] = iAimEnt
	}
	else
	{
		if (fAimDistance > MINION_MOVE_COMMAND_RANGE)
			return

		Player[iPlayer][PlrNpcAction][iSlot] = NPC_ACTION_MOVE
		Player[iPlayer][PlrNpcActionTarget][iSlot] = 0
		xs_vec_copy(vAimOrigin, PlrActionOrigin(iPlayer, iSlot))
	}

	new Float:vSpriteOrigin[3]
	xs_vec_copy(vAimOrigin, vSpriteOrigin)
	vSpriteOrigin[2] += 30.0
	send_msg_TE_SPRITE(vSpriteOrigin, g_pPointSpr, 8, 100, MSG_ONE, _, iPlayer)
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
		Player[iVictim][PlrMergeOrdered] = false
		Player[iVictim][PlrMergeAt] = 0.0
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
		Player[iPlayer][PlrMinionRespawnAt][i] = Player[iPlayer][PlrForm] == FORM_CENTAUR && i == 1 ? 0.0 : fRespawnAt
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

Float:necro_get_aggression_radius(iOwner)
{
	new Float:fRadius = Player[iOwner][PlrForm] == FORM_CENTAUR
		? CENTAUR_AGGRESSION_RADIUS : MINION_FOLLOW_RADIUS
	return fRadius
}

Float:necro_get_move_speed(iMinion, bool:bReturning=false)
{
	new Float:fSpeed = bReturning ? MINION_RETURN_SPEED : ZOMBIE_SPEED
	new Float:fMul = 1.0
	if (necro_minion_is_chilled(iMinion))
		fMul = MINION_CHILL_SPEED_MUL
	if (g_fMinionSlowUntil[iMinion] > get_gametime())
		fMul = floatmin(fMul, MINION_SLOW_SPEED_MUL)
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
	if (Player[iPlayer][PlrMergeAt] > 0.0 && Player[iPlayer][PlrMergeAt] <= fGameTime)
	{
		Player[iPlayer][PlrMergeAt] = 0.0
		necro_finish_cannibalize(iPlayer)
	}

	if (Player[iPlayer][PlrMergeOrdered] && !necro_form_complete(iPlayer))
	{
		Player[iPlayer][PlrMergeOrdered] = false
		Player[iPlayer][PlrMergeAt] = 0.0
	}

	if (Player[iPlayer][PlrLaserPendingAt] > 0.0)
	{
		if (kc_player_in_silence(iPlayer) || kc_player_in_darkness(iPlayer) || kc_player_get_capture(iPlayer) != CAPTURE_NONE)
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
		necro_fire_centaur_laser(iPlayer)
		necro_clear_laser_glow(iPlayer)
		Player[iPlayer][PlrLaserLockTime] = fGameTime + 1.0
	}


	new Float:fChargeDt = Player[iPlayer][PlrChargeLastTick] > 0.0 ? floatmin(fGameTime - Player[iPlayer][PlrChargeLastTick], 0.5) : 0.0
	Player[iPlayer][PlrChargeLastTick] = fGameTime
	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		new iChargeEnt = Player[iPlayer][PlrMinionEnt][i]
		if (iChargeEnt && is_entity(iChargeEnt) && !(get_entvar(iChargeEnt, var_flags) & FL_KILLME))
			Player[iPlayer][PlrZombieCharge][i] = floatmin(100.0, Player[iPlayer][PlrZombieCharge][i] + ABIL1_CHARGE * fChargeDt)
	}

	new szSoulHint[24]
	if (Player[iPlayer][PlrSouls])
		formatex(szSoulHint, charsmax(szSoulHint), "+%dHP", floatround(SOUL_HEAL_VALUE * Player[iPlayer][PlrSouls]))
	kc_player_set_ability4_hint(iPlayer, szSoulHint)

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		if (Player[iPlayer][PlrForm] == FORM_CENTAUR && i == 1)
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

		new Float:fMaxHealth = get_entvar(iMinion, var_npctype) ? CENTAUR_HEALTH : ZOMBIE_HEALTH
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

	new Float:fMaxHealth = Player[iOwner][PlrForm] == FORM_CENTAUR && iSlot == MINION_SLOT_CENTAUR
		? CENTAUR_HEALTH : ZOMBIE_HEALTH
	new Float:fHealth = floatmax(0.0, Float:get_entvar(iMinion, var_health))
	set_entvar(iBar, var_frame, floatclamp(fHealth * 100.0 / fMaxHealth, 0.0, 99.0))
}

minion_create_lifebar(iOwner, iSlot, iMinion)
{
	new iBar = rg_create_entity(SZ_ENV_SPRITE)
	if (is_nullent(iBar))
		return

	engfunc(EngFunc_SetModel, iBar, iSlot == 1 ? MODEL_MINION_LIFEBAR_B : MODEL_MINION_LIFEBAR)
	set_entvar(iBar, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iBar, var_aiment, iMinion)
	set_entvar(iBar, var_view_ofs, Float:{0.0, 0.0, 48.0})
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

bool:necro_is_minion_target(iHost, iTarget)
{
	new iOwner = is_user_alive(iHost) ? iHost : get_entvar(iHost, var_iuser2)
	if (!is_entity_player(iOwner) || iOwner == iTarget || Player[iOwner][PlrKnife] != g_iKnifeId)
		return false

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		new iMinion = Player[iOwner][PlrMinionEnt][i]
		if (Player[iOwner][PlrNpcAction][i] == NPC_ACTION_TARGET && Player[iOwner][PlrNpcActionTarget][i] == iTarget
			&& iMinion && is_entity(iMinion) && !(get_entvar(iMinion, var_flags) & FL_KILLME))
			return true
	}

	return false
}

public necro_AddToFullPack(es_state, e, ent, host, hostflags, player)
{
	if (is_nullent(ent))
		return FMRES_IGNORED

	if (player)
	{
		if (necro_is_minion_target(host, ent))
		{
			set_es(es_state, ES_RenderMode, kRenderNormal)
			set_es(es_state, ES_RenderFx, kRenderFxGlowShell)
			set_es(es_state, ES_RenderColor, Float:{255.0, 0.0, 0.0})
			set_es(es_state, ES_RenderAmt, 16.0)
		}
		return FMRES_IGNORED
	}

	new iImpulse = get_entvar(ent, var_impulse)

	if (iImpulse == IMPULSE_ZOMBIE)
	{
		new Float:vVariant[3]
		get_entvar(ent, var_vuser1, vVariant)
		if (vVariant[0] > 0.5)
			set_es(es_state, ES_Skin, get_entvar(ent, var_skin) + 2)

		if (necro_is_minion_target(host, ent))
		{
			set_es(es_state, ES_RenderMode, kRenderNormal)
			set_es(es_state, ES_RenderFx, kRenderFxGlowShell)
			set_es(es_state, ES_RenderColor, Float:{255.0, 0.0, 0.0})
			set_es(es_state, ES_RenderAmt, 16.0)
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

	if (host != iOwner && get_entvar(host, var_iuser2) != iOwner)
	{
		set_es(es_state, ES_Effects, EF_NODRAW)
		return FMRES_IGNORED
	}

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
	if (Player[iOwner][PlrForm] == FORM_CENTAUR)
		iEnt = create_centaur(vSpawnOrigin, vAngles, 0.0, iOwner)
	else
		iEnt = create_zombie(vSpawnOrigin, vAngles, iOwner, iSlot)

	if (is_nullent(iEnt))
		return false

	Player[iOwner][PlrMinionEnt][iSlot] = iEnt
	minion_create_lifebar(iOwner, iSlot, iEnt)
	return true
}

bool:necro_order_merge(iOwner)
{
	if (!Player[iOwner][PlrIsAlive] || Player[iOwner][PlrKnife] != g_iKnifeId
		|| Player[iOwner][PlrForm] != FORM_ZOMBIES || !necro_form_complete(iOwner)
		|| kc_player_in_silence(iOwner) || kc_player_in_darkness(iOwner)
		|| kc_player_get_capture(iOwner) != CAPTURE_NONE)
		return false

	if (get_gametime() - Player[iOwner][PlrLastFormSwitch] < FORM_SWITCH_COOLDOWN)
		return false

	new iZombieA = Player[iOwner][PlrMinionEnt][0]
	new iZombieB = Player[iOwner][PlrMinionEnt][1]
	if (!(get_entvar(iZombieA, var_flags) & FL_ONGROUND) || !(get_entvar(iZombieB, var_flags) & FL_ONGROUND))
		return false

	Player[iOwner][PlrMergeOrdered] = true
	return true
}

bool:necro_finish_cannibalize(iOwner)
{
	if (kc_player_in_silence(iOwner) || kc_player_in_darkness(iOwner)
		|| kc_player_get_capture(iOwner) != CAPTURE_NONE)
		return false

	new iZombieA = Player[iOwner][PlrMinionEnt][0]
	new iZombieB = Player[iOwner][PlrMinionEnt][1]

	if (!iZombieA || !iZombieB || !is_entity(iZombieA) || !is_entity(iZombieB)
		|| (get_entvar(iZombieA, var_flags) & FL_KILLME) || (get_entvar(iZombieB, var_flags) & FL_KILLME))
		return false

	if (!(get_entvar(iZombieA, var_flags) & FL_ONGROUND) || !(get_entvar(iZombieB, var_flags) & FL_ONGROUND))
		return false

	new Float:vOrigin[3], Float:vAngles[3]
	get_entvar(iZombieA, var_origin, vOrigin)
	get_entvar(iZombieA, var_angles, vAngles)
	vAngles[0] = vAngles[2] = 0.0

	new Float:fHealth = floatmin(CENTAUR_HEALTH,
		Float:get_entvar(iZombieA, var_health) + Float:get_entvar(iZombieB, var_health))

	new Float:fMergedCharge = (Player[iOwner][PlrZombieCharge][0] + Player[iOwner][PlrZombieCharge][1]) / 2.0

	ExecuteHamB(Ham_TakeDamage, iZombieA, 0, iZombieA, 9000.0, DMG_BLAST)
	ExecuteHamB(Ham_TakeDamage, iZombieB, 0, iZombieB, 9000.0, DMG_BLAST)

	arrayset(Player[iOwner][PlrMinionRespawnAt], 0.0, MAX_MINION_SLOTS)
	Player[iOwner][PlrLaserPendingAt] = 0.0
	Player[iOwner][PlrLaserLockTime] = 0.0

	Player[iOwner][PlrForm] = FORM_CENTAUR

	new iCentaur = create_centaur(vOrigin, vAngles, fHealth, iOwner)
	if (!is_nullent(iCentaur))
	{
		Player[iOwner][PlrMinionEnt][MINION_SLOT_CENTAUR] = iCentaur
		minion_create_lifebar(iOwner, MINION_SLOT_CENTAUR, iCentaur)
	}

	Player[iOwner][PlrLastFormSwitch] = get_gametime()
	necro_reset_npc_actions(iOwner)
	Player[iOwner][PlrZombieCharge][MINION_SLOT_CENTAUR] = fMergedCharge
	Player[iOwner][PlrMergeOrdered] = false
	return true
}

bool:necro_form_complete(iPlayer)
{
	if (Player[iPlayer][PlrForm] == FORM_CENTAUR)
	{
		new iCentaur = Player[iPlayer][PlrMinionEnt][MINION_SLOT_CENTAUR]
		return bool:(iCentaur && is_entity(iCentaur) && !(get_entvar(iCentaur, var_flags) & FL_KILLME))
	}

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		new iZombie = Player[iPlayer][PlrMinionEnt][i]
		if (!iZombie || !is_entity(iZombie) || (get_entvar(iZombie, var_flags) & FL_KILLME))
			return false
	}

	return true
}

necro_spawn_split_zombie(iOwner, iSlot, const Float:vBase[3], Float:vAngles[3], Float:fHealth, Float:fYaw)
{
	new Float:vSpawn[3], iZombie = 0
	if (necro_find_spawn_point(vBase, fYaw, iOwner, vSpawn))
		iZombie = create_zombie(vSpawn, vAngles, iOwner, iSlot)

	if (!is_nullent(iZombie))
	{
		set_entvar(iZombie, var_health, fHealth)
		Player[iOwner][PlrMinionEnt][iSlot] = iZombie
		minion_create_lifebar(iOwner, iSlot, iZombie)
	}
	else
		Player[iOwner][PlrMinionRespawnAt][iSlot] = get_gametime() + 0.5
}

bool:necro_finish_split(iOwner)
{
	if (!Player[iOwner][PlrIsAlive] || Player[iOwner][PlrKnife] != g_iKnifeId
		|| kc_player_in_silence(iOwner) || kc_player_in_darkness(iOwner)
		|| kc_player_get_capture(iOwner) != CAPTURE_NONE)
		return false

	if (get_gametime() - Player[iOwner][PlrLastFormSwitch] < FORM_SWITCH_COOLDOWN)
		return false

	new iCentaur = Player[iOwner][PlrMinionEnt][MINION_SLOT_CENTAUR]
	if (!iCentaur || !is_entity(iCentaur) || (get_entvar(iCentaur, var_flags) & FL_KILLME))
		return false

	if (!(get_entvar(iCentaur, var_flags) & FL_ONGROUND))
		return false

	new Float:vOrigin[3], Float:vAngles[3]
	get_entvar(iCentaur, var_origin, vOrigin)
	get_entvar(iCentaur, var_angles, vAngles)
	vAngles[0] = vAngles[2] = 0.0

	new Float:fZombieHealth = floatmin(ZOMBIE_HEALTH, Float:get_entvar(iCentaur, var_health) / 2.0)

	new Float:fSplitCharge = Player[iOwner][PlrZombieCharge][MINION_SLOT_CENTAUR] / 2.0

	ExecuteHamB(Ham_TakeDamage, iCentaur, 0, iCentaur, 9000.0, DMG_BLAST)

	arrayset(Player[iOwner][PlrMinionRespawnAt], 0.0, MAX_MINION_SLOTS)
	Player[iOwner][PlrLaserPendingAt] = 0.0
	Player[iOwner][PlrLaserLockTime] = 0.0

	Player[iOwner][PlrForm] = FORM_ZOMBIES

	new Float:vBase[3]
	xs_vec_copy(vOrigin, vBase)
	vBase[2] += 36.0

	necro_spawn_split_zombie(iOwner, 0, vBase, vAngles, fZombieHealth, vAngles[1] + MINION_SPAWN_ANGLE)
	necro_spawn_split_zombie(iOwner, 1, vBase, vAngles, fZombieHealth, vAngles[1] - MINION_SPAWN_ANGLE)

	Player[iOwner][PlrLastFormSwitch] = get_gametime()
	necro_reset_npc_actions(iOwner)
	Player[iOwner][PlrZombieCharge][0] = fSplitCharge
	Player[iOwner][PlrZombieCharge][1] = fSplitCharge
	Player[iOwner][PlrMergeOrdered] = false
	return true
}

public spit_think(iSpitEnt)
{
	rg_remove_entity(iSpitEnt)
}

public spit_touch(iSpitEnt, iOther)
{
	new iOwner = get_entvar(iSpitEnt, var_owner)
	if (!is_entity_player(iOwner))
	{
		spit_kill(iSpitEnt)
		return
	}

	if (is_entity_player(iOther))
	{
		if (!Player[iOther][PlrIsAlive] || (iOther != iOwner && Player[iOwner][PlrTeam] == Player[iOther][PlrTeam]))
		{
			spit_kill(iSpitEnt)
			return
		}

		if (iOther != iOwner && kc_player_apply_concentblock(iOther, iSpitEnt, ATTACK_HEAVINESS_LOW))
		{
			spit_kill(iSpitEnt, .bStabbed=true)
			return
		}

		kc_player_set_death_reason(iOther, "DEATH_REASON_ZOMBIE")
		set_member(iOther, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iOther, iSpitEnt, iOwner, SPIT_DAMAGE, DMG_BLAST)
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

	if (get_entvar(iOther, var_impulse) == IMPULSE_ZOMBIE && get_entvar(iOther, var_skin) + 1 == Player[iOwner][PlrTeam])
		return

	switch (get_entvar(iOther, var_impulse))
	{
		case IMPULSE_ZOMBIE:
		{
			ExecuteHamB(Ham_TakeDamage, iOther, iSpitEnt, iOwner, SPIT_DAMAGE, DMG_BLAST)
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
	send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, 70, 5)
	engfunc(EngFunc_EmitSound, iSpitEnt, CHAN_AUTO,
		SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	rg_remove_entity(iSpitEnt)
}

spit_kill(iSpitEnt, bool:bStabbed=false)
{
	new Float:vOrigin[3]
	get_entvar(iSpitEnt, var_origin, vOrigin)

	send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, 70, 5)

	engfunc(EngFunc_EmitSound, iSpitEnt, CHAN_AUTO,
		SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)],
		1.0, ATTN_NORM, 0,
		bStabbed ? random_num(90, 95) : PITCH_NORM
	)

	rg_remove_entity(iSpitEnt)
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	if (Player[iPlayer][PlrKnife] == g_iKnifeId)
	{
		Player[iPlayer][PlrLaserPendingAt] = 0.0
		Player[iPlayer][PlrLaserLockTime] = 0.0
		kill_all_npc(iPlayer)
	}

	Player[iPlayer][PlrKnife] = iKnifeId
	if (iKnifeId == g_iKnifeId && Player[iPlayer][PlrIsAlive])
		necro_schedule_form(iPlayer, MINION_SPAWN_DELAY)
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	static szMessage[192], szLabel[32], szAction[64], szValue[48]
	static iLen
	szMessage[0] = 0
	iLen = 0

	if (Player[iSubject][PlrSouls])
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%L", iPlayer, "NECRO_SOUL_HEAL_HINT",
			floatround(SOUL_HEAL_VALUE * Player[iSubject][PlrSouls]))

	if (Player[iSubject][PlrForm] == FORM_CENTAUR)
	{
		formatex(szLabel, charsmax(szLabel), "%L", iPlayer, "NECRO_CENTAUR")
		new iEnt = Player[iSubject][PlrMinionEnt][MINION_SLOT_CENTAUR]
		if (iEnt && is_entity(iEnt) && !(get_entvar(iEnt, var_flags) & FL_KILLME))
		{
			formatex(szValue, charsmax(szValue), "%L", iPlayer, "NECRO_HP", floatround(Float:get_entvar(iEnt, var_health), floatround_floor))
			iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%s%s: [%s | %d%%]", iLen ? "^n" : "", szLabel, szValue,
				floatround(Player[iSubject][PlrZombieCharge][MINION_SLOT_CENTAUR], floatround_floor))
		}
		else
		{
			formatex(szValue, charsmax(szValue), "%L", iPlayer, "NECRO_RESPAWN", necro_respawn_percent(iSubject, MINION_SLOT_CENTAUR))
			iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%s%s: [%s]", iLen ? "^n" : "", szLabel, szValue)
		}
	}
	else
	{
		formatex(szLabel, charsmax(szLabel), "%L", iPlayer, "NECRO_ZOMBIES")
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "%s%s: ", iLen ? "^n" : "", szLabel)
		for (new i; i < MAX_MINION_SLOTS; i++)
		{
			new iEnt = Player[iSubject][PlrMinionEnt][i]
			if (i)
				iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, " | ")

			if (iEnt && is_entity(iEnt) && !(get_entvar(iEnt, var_flags) & FL_KILLME))
			{
				formatex(szValue, charsmax(szValue), "%L", iPlayer, "NECRO_HP", floatround(Float:get_entvar(iEnt, var_health), floatround_floor))
				iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "[%s | %d%%]", szValue,
					floatround(Player[iSubject][PlrZombieCharge][i], floatround_floor))
			}
			else
			{
				formatex(szValue, charsmax(szValue), "%L", iPlayer, "NECRO_RESPAWN", necro_respawn_percent(iSubject, i))
				iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "[%s]", szValue)
			}
		}
	}

	new Float:fMergeElapsed = get_gametime() - Player[iSubject][PlrLastFormSwitch]
	new iMergeCharge = clamp(floatround(fMergeElapsed * 100.0 / FORM_SWITCH_COOLDOWN), 0, 100)
	new szMergeKey[24]
	if (Player[iSubject][PlrForm] == FORM_CENTAUR)
		copy(szMergeKey, charsmax(szMergeKey), "NECRO_SPLIT")
	else
		copy(szMergeKey, charsmax(szMergeKey), "NECRO_MERGE")
	formatex(szValue, charsmax(szValue), "%L", iPlayer, szMergeKey, iMergeCharge)
	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n%s", szValue)

	for (new i; i < MAX_MINION_SLOTS; i++)
	{
		if (Player[iSubject][PlrForm] == FORM_CENTAUR && i == 1)
			continue

		szAction[0] = 0
		switch (Player[iSubject][PlrNpcAction][i])
		{
			case NPC_ACTION_MOVE: formatex(szAction, charsmax(szAction), "%L", iPlayer, "NPC_ACTION_MOVE")
			case NPC_ACTION_TARGET: formatex(szAction, charsmax(szAction), "%L", iPlayer, "NPC_ACTION_TARGET")
			case NPC_ACTION_FOLLOW: formatex(szAction, charsmax(szAction), "%L", iPlayer, "NPC_ACTION_FOLLOW")
		}
		if (szAction[0])
			iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n%s: %s", i == 0 ? "E" : "R", szAction)
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

necro_trace_aim_point(iPlayer, iCentaur, Float:vEnd[3])
{
	new Float:vStart[3], Float:vViewOfs[3], Float:vAngles[3], Float:vDirection[3]
	get_entvar(iPlayer, var_origin, vStart)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vStart, vViewOfs, vStart)
	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vDirection)
	xs_vec_mul_scalar(vDirection, 800.0, vDirection)
	xs_vec_add(vStart, vDirection, vEnd)

	new iOldSolid = get_entvar(iCentaur, var_solid)
	set_entvar(iCentaur, var_solid, SOLID_NOT)
	engfunc(EngFunc_TraceLine, vStart, vEnd, DONT_IGNORE_MONSTERS, iPlayer, 0)
	set_entvar(iCentaur, var_solid, iOldSolid)
	get_tr2(0, TR_vecEndPos, vEnd)
	return get_tr2(0, TR_pHit)
}

necro_centaur_laser(iPlayer)
{
	new iCentaur = Player[iPlayer][PlrMinionEnt][MINION_SLOT_CENTAUR]
	new Float:fGameTime = get_gametime()
	if (!iCentaur || !is_entity(iCentaur) || (get_entvar(iCentaur, var_flags) & FL_KILLME) || necro_minion_is_frozen(iCentaur)
		|| Player[iPlayer][PlrLaserLockTime] > fGameTime
		|| Player[iPlayer][PlrLaserPendingAt] > 0.0 || Player[iPlayer][PlrLaserIndicateEndAt] > 0.0
		|| Player[iPlayer][PlrZombieCharge][MINION_SLOT_CENTAUR] < 100.0)
		return PLUGIN_HANDLED

	Player[iPlayer][PlrZombieCharge][MINION_SLOT_CENTAUR] = 0.0
	Player[iPlayer][PlrLaserPendingAt] = fGameTime + LASER_CHARGE_TIME
	necro_track_laser_aim(iPlayer)
	return PLUGIN_CONTINUE
}

necro_track_laser_aim(iPlayer)
{
	new iCentaur = Player[iPlayer][PlrMinionEnt][MINION_SLOT_CENTAUR]
	if (!iCentaur || !is_entity(iCentaur) || (get_entvar(iCentaur, var_flags) & FL_KILLME))
		return

	new Float:vCentaurOrigin[3], Float:vAimEnd[3]
	get_entvar(iCentaur, var_origin, vCentaurOrigin)
	necro_trace_aim_point(iPlayer, iCentaur, vAimEnd)
	npc_TurnToTarget(iCentaur, vCentaurOrigin, vAimEnd)
}

necro_start_laser_indicate(iPlayer)
{
	new iCentaur = Player[iPlayer][PlrMinionEnt][MINION_SLOT_CENTAUR]
	if (!iCentaur || !is_entity(iCentaur) || (get_entvar(iCentaur, var_flags) & FL_KILLME))
		return

	necro_trace_aim_point(iPlayer, iCentaur, Player[iPlayer][PlrLaserLockedEnd])
	Player[iPlayer][PlrLaserIndicateEndAt] = get_gametime() + LASER_INDICATE_TIME

	set_entvar(iCentaur, var_rendermode, kRenderNormal)
	set_entvar(iCentaur, var_renderfx, kRenderFxGlowShell)
	set_entvar(iCentaur, var_rendercolor, Float:{255.0, 0.0, 0.0})
	set_entvar(iCentaur, var_renderamt, 16.0)

	set_entvar(iCentaur, var_animtime, get_gametime())
	set_entvar(iCentaur, var_frame, 0.0)
	set_entvar(iCentaur, var_sequence, 5)
	engfunc(EngFunc_EmitSound, iCentaur, CHAN_AUTO, SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_LOW)
}

necro_clear_laser_glow(iPlayer)
{
	new iCentaur = Player[iPlayer][PlrMinionEnt][MINION_SLOT_CENTAUR]
	if (!iCentaur || !is_entity(iCentaur))
		return

	set_entvar(iCentaur, var_rendermode, kRenderNormal)
	set_entvar(iCentaur, var_renderfx, kRenderFxNone)
	set_entvar(iCentaur, var_renderamt, 0.0)
}

necro_fire_centaur_laser(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId || Player[iPlayer][PlrForm] != FORM_CENTAUR)
		return

	new iCentaur = Player[iPlayer][PlrMinionEnt][MINION_SLOT_CENTAUR]
	if (!iCentaur || !is_entity(iCentaur) || (get_entvar(iCentaur, var_flags) & FL_KILLME))
		return

	new Float:vLockedEnd[3]
	xs_vec_copy(Player[iPlayer][PlrLaserLockedEnd], vLockedEnd)

	new Float:vCentaurOrigin[3], Float:vBeamStart[3], Float:vCentaurAngles[3]
	get_entvar(iCentaur, var_origin, vCentaurOrigin)
	get_entvar(iCentaur, var_angles, vCentaurAngles)
	engfunc(EngFunc_MakeVectors, vCentaurAngles)
	global_get(glb_v_forward, vBeamStart)
	xs_vec_mul_scalar(vBeamStart, 50.0, vBeamStart)
	xs_vec_add(vCentaurOrigin, vBeamStart, vBeamStart)
	vBeamStart[2] += 40.0

	new Float:vBeamDir[3], Float:vTraceEnd[3]
	xs_vec_sub(vLockedEnd, vBeamStart, vBeamDir)
	xs_vec_normalize(vBeamDir, vBeamDir)
	xs_vec_mul_scalar(vBeamDir, LASER_TRACE_OVERSHOOT, vBeamDir)
	xs_vec_add(vLockedEnd, vBeamDir, vTraceEnd)

	engfunc(EngFunc_TraceLine, vBeamStart, vTraceEnd, DONT_IGNORE_MONSTERS, iCentaur, 0)
	new Float:vEnd[3]
	get_tr2(0, TR_vecEndPos, vEnd)
	new iHit = get_tr2(0, TR_pHit)

	send_msg_TE_BEAMPOINTS(vBeamStart, vEnd, g_pLaserbeamSpr, 0, 1, 7, 10, 0, {180, 0, 40}, 200, 0)

	if (is_entity_player(iHit))
	{
		if (Player[iHit][PlrIsAlive] && (iHit == iPlayer || Player[iHit][PlrTeam] != Player[iPlayer][PlrTeam]))
		{
			kc_player_set_death_reason(iHit, "DEATH_REASON_ZOMBIE")
			set_member(iHit, m_LastHitGroup, HIT_GENERIC)
			ExecuteHamB(Ham_TakeDamage, iHit, iCentaur, iPlayer, LASER_DAMAGE, DMG_ENERGYBEAM)
		}
	}
	else if (is_entity(iHit) && get_entvar(iHit, var_impulse) == IMPULSE_ZOMBIE
		&& get_entvar(iHit, var_skin) + 1 != Player[iPlayer][PlrTeam])
	{
		ExecuteHamB(Ham_TakeDamage, iHit, iCentaur, iPlayer, LASER_DAMAGE, DMG_ENERGYBEAM)
	}
}

bool:necro_is_enemy_entity(iOwner, iEnt)
{
	if (is_entity_player(iEnt))
		return bool:(Player[iEnt][PlrIsAlive] && Player[iEnt][PlrTeam] != Player[iOwner][PlrTeam])

	if (!is_entity(iEnt) || get_entvar(iEnt, var_impulse) != IMPULSE_ZOMBIE)
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
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_ZOMBIE)))
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
		return true

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

bool:necro_command_destination(iOwner, iSelfSlot, bool:bCentaur, const Float:vOrigin[3], Float:vDestination[3], &iTarget, &bool:bReturning)
{
	new Float:vOwnerOrigin[3]
	get_entvar(iOwner, var_origin, vOwnerOrigin)
	xs_vec_copy(vOwnerOrigin, vDestination)
	bReturning = false
	iTarget = 0

	if (!bCentaur && Player[iOwner][PlrMergeOrdered] && iSelfSlot >= 0)
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
				Player[iOwner][PlrNpcAction][iSelfSlot] = NPC_ACTION_FOLLOW
				Player[iOwner][PlrNpcActionTarget][iSelfSlot] = 0
				necro_get_formation_point(iOwner, iSelfSlot, vDestination)
				bReturning = true
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
			if (bCentaur)
				fStopDistance = CENTAUR_FOLLOW_STOP_DISTANCE
			else
				necro_get_formation_point(iOwner, iSelfSlot, vDestination)

			new Float:fDistance = get_distance_f(vOrigin, vDestination)
			if (!Player[iOwner][PlrMinionWalking][iSelfSlot] && fDistance > MINION_FORMATION_LEASH)
				Player[iOwner][PlrMinionWalking][iSelfSlot] = true
			else if (Player[iOwner][PlrMinionWalking][iSelfSlot] && fDistance <= fStopDistance)
				Player[iOwner][PlrMinionWalking][iSelfSlot] = false

			if (!Player[iOwner][PlrMinionWalking][iSelfSlot])
				xs_vec_copy(vOrigin, vDestination)
		}
	}

	return true
}

necro_set_move_animation(iEnt, bool:bCentaur)
{
	new iSequence = bCentaur ? 2 : 1
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

bool:necro_start_centaur_spit(iCentaurEnt, const Float:vOrigin[3], iTarget)
{
	if (!iTarget || random(5))
		return false

	new Float:vTargetOrigin[3], Float:vSelfOrigin[3], Float:vStart[3], Float:fFraction
	get_entvar(iTarget, var_origin, vTargetOrigin)
	if (get_distance_f(vOrigin, vTargetOrigin) <= CENTAUR_SPIT_MIN_RANGE)
		return false

	xs_vec_copy(vOrigin, vSelfOrigin)
	xs_vec_copy(vOrigin, vStart)
	vStart[2] += 40.0
	engfunc(EngFunc_TraceLine, vStart, vTargetOrigin, 0, iCentaurEnt, 0)
	get_tr2(0, TR_flFraction, fFraction)
	if (fFraction <= 0.9)
		return false

	new Float:fGameTime = get_gametime()
	npc_TurnToTarget(iCentaurEnt, vSelfOrigin, vTargetOrigin)

	set_entvar(iCentaurEnt, var_animtime, fGameTime)
	set_entvar(iCentaurEnt, var_frame, 0.0)
	set_entvar(iCentaurEnt, var_sequence, 5)
	set_entvar(iCentaurEnt, var_npcspit, iTarget)
	set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.6)

	engfunc(EngFunc_EmitSound, iCentaurEnt, CHAN_AUTO, SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_LOW)
	return true
}

bool:necro_release_centaur_spit(iCentaurEnt, iOwner, const Float:vOrigin[3])
{
	new iTarget = get_entvar(iCentaurEnt, var_npcspit)
	if (!iTarget)
		return false

	set_entvar(iCentaurEnt, var_npcspit, 0)
	if (is_nullent(iTarget) || (get_entvar(iTarget, var_flags) & FL_KILLME))
		return false

	new iSpitEnt = rg_create_entity(SZ_EXPLOSION)
	if (is_nullent(iSpitEnt))
		return false

	new Float:vTargetOrigin[3], Float:vSelfOrigin[3], Float:vStart[3], Float:vAngles[3]
	get_entity_center(iTarget, vTargetOrigin)
	xs_vec_copy(vOrigin, vSelfOrigin)

	get_entvar(iCentaurEnt, var_angles, vAngles)
	engfunc(EngFunc_MakeVectors, vAngles)
	global_get(glb_v_forward, vStart)
	xs_vec_mul_scalar(vStart, 50.0, vStart)
	xs_vec_add(vSelfOrigin, vStart, vStart)
	vStart[2] += 40.0

	engfunc(EngFunc_SetModel, iSpitEnt, MODEL_SPIT)
	engfunc(EngFunc_SetOrigin, iSpitEnt, vStart)
	engfunc(EngFunc_SetSize, iSpitEnt, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0})
	set_entvar(iSpitEnt, var_origin, vStart)
	set_entvar(iSpitEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iSpitEnt, var_movetype, MOVETYPE_FLYMISSILE)
	set_entvar(iSpitEnt, var_rendermode, kRenderNormal)
	set_entvar(iSpitEnt, var_gravity, 0.0)
	set_entvar(iSpitEnt, var_classname, _CLASSNAME_ZOMBIE_SPIT)
	set_entvar(iSpitEnt, var_impulse, IMPULSE_ZOMBIE_SPIT)
	set_entvar(iSpitEnt, var_owner, iOwner)
	set_entvar(iSpitEnt, var_nextthink, get_gametime() + SPIT_LIFETIME)

	send_msg_TE_BEAMFOLLOW(iSpitEnt, g_pShockwaveSpr, 4, 2, {195, 41, 28}, 100)

	new Float:vDirection[3]
	xs_vec_sub(vTargetOrigin, vStart, vAngles)
	xs_vec_normalize(vAngles, vDirection)
	vector_to_angle(vDirection, vAngles)
	xs_vec_mul_scalar(vDirection, 1000.0, vDirection)

	set_entvar(iSpitEnt, var_velocity, vDirection)
	set_entvar(iSpitEnt, var_angles, vAngles)

	SetThink(iSpitEnt, "spit_think")
	SetTouch(iSpitEnt, "spit_touch")

	set_entvar(iCentaurEnt, var_nextthink, get_gametime() + 0.4)
	return true
}

necro_attack_entity(iMinion, iOwner, iTarget, bool:bCentaur)
{
	if (is_entity_player(iTarget))
	{
		if (Player[iTarget][PlrTeam] == Player[iOwner][PlrTeam])
			return

		if (kc_player_apply_concentblock(iTarget, iMinion))
			return

		new Float:fDamage = bCentaur ? random_float(CENTAUR_MIN_DAMAGE, CENTAUR_MAX_DAMAGE) : random_float(ZOMBIE_MIN_DAMAGE, ZOMBIE_MAX_DAMAGE)
		kc_player_set_death_reason(iTarget, "DEATH_REASON_ZOMBIE")
		set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iTarget, iMinion, iOwner, fDamage, DMG_SLASH | DMG_ALWAYSGIB)

		kc_player_heal(iOwner, fDamage * ZOMBIE_HIT_HEAL_PERCENT, iOwner)
	}
	else if (is_entity(iTarget) && get_entvar(iTarget, var_impulse) == IMPULSE_ZOMBIE
		&& get_entvar(iTarget, var_npctype) == 0 && get_entvar(iTarget, var_npcowner) == iOwner)
	{
		if (Player[iOwner][PlrMergeAt] <= 0.0)
			Player[iOwner][PlrMergeAt] = get_gametime() + CANNIBALIZE_WINDUP_TIME
	}
	else if (is_entity(iTarget))
	{
		new Float:fDamage = bCentaur ? random_float(CENTAUR_MIN_DAMAGE, CENTAUR_MAX_DAMAGE) : random_float(ZOMBIE_MIN_DAMAGE, ZOMBIE_MAX_DAMAGE)
		ExecuteHamB(Ham_TakeDamage, iTarget, iMinion, iOwner, fDamage, DMG_SLASH | DMG_ALWAYSGIB)

		kc_player_heal(iOwner, fDamage * ZOMBIE_HIT_HEAL_PERCENT, iOwner)
	}
}

necro_play_attack_animation(iMinion, bool:bCentaur)
{
	set_entvar(iMinion, var_fuser4, get_gametime() + ATTACK_ANIM_LOCK_TIME)
	set_entvar(iMinion, var_animtime, get_gametime())
	set_entvar(iMinion, var_frame, 0.0)

	if (bCentaur)
	{
		set_entvar(iMinion, var_sequence, get_entvar(iMinion, var_sequence) == 3 ? 4 : 3)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_AUTO, SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_LOW)
	}
	else
	{
		set_entvar(iMinion, var_sequence, get_entvar(iMinion, var_sequence) == 2 ? 3 : 2)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_AUTO, SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

necro_minion_think(iMinion, bool:bCentaur)
{
	new iOwner = get_entvar(iMinion, var_npcowner)
	if (!is_entity_player(iOwner))
	{
		set_entvar(iMinion, var_flags, FL_KILLME)
		return
	}

	if (!Player[iOwner][PlrIsAlive] || Player[iOwner][PlrKnife] != g_iKnifeId
		|| bCentaur != (Player[iOwner][PlrForm] == FORM_CENTAUR))
	{
		set_entvar(iMinion, var_flags, FL_KILLME)
		return
	}

	new Float:fGameTime = get_gametime(), Float:vOrigin[3], Float:vDestination[3]
	get_entvar(iMinion, var_origin, vOrigin)

	if (necro_minion_is_frozen(iMinion))
	{
		new Float:vFrozenVelocity[3]
		get_entvar(iMinion, var_velocity, vFrozenVelocity)
		vFrozenVelocity[0] = 0.0
		vFrozenVelocity[1] = 0.0
		set_entvar(iMinion, var_velocity, vFrozenVelocity)
		set_entvar(iMinion, var_nextthink, fGameTime + MINION_STATUS_TICK)
		return
	}

	new Float:fLastDamage = Float:get_entvar(iMinion, var_fuser3)
	if (fLastDamage > 0.0 && fGameTime - fLastDamage >= ZOMBIE_REGEN_DELAY)
	{
		new Float:fMaxHealth = bCentaur ? CENTAUR_HEALTH : ZOMBIE_HEALTH
		new Float:fHealth = Float:get_entvar(iMinion, var_health)
		if (fHealth < fMaxHealth)
		{
			new Float:fLastRegen = Float:get_entvar(iMinion, var_fuser2)
			new Float:fDt = fLastRegen > 0.0 ? floatmin(fGameTime - fLastRegen, 1.0) : 0.0
			set_entvar(iMinion, var_health, floatmin(fMaxHealth, fHealth + ZOMBIE_REGEN_RATE * fDt))
		}
		set_entvar(iMinion, var_fuser2, fGameTime)
	}

	new iPendingTarget = get_entvar(iMinion, var_npctarget)
	if (iPendingTarget)
	{
		set_entvar(iMinion, var_npctarget, 0)
		set_entvar(iMinion, var_nextthink, fGameTime + MINION_ATTACK_INTERVAL - ATTACK_WINDUP_TIME)

		if (!kc_player_in_silence(iOwner) && is_entity(iPendingTarget) && !(get_entvar(iPendingTarget, var_flags) & FL_KILLME)
			&& !(is_entity_player(iPendingTarget) && !Player[iPendingTarget][PlrIsAlive]))
		{
			new Float:vPendingOrigin[3]
			get_entvar(iPendingTarget, var_origin, vPendingOrigin)
			if (get_distance_f(vOrigin, vPendingOrigin) <= (bCentaur ? CENTAUR_ATTACK_RANGE : ZOMBIE_ATTACK_RANGE) + ATTACK_RANGE_TOLERANCE)
				necro_attack_entity(iMinion, iOwner, iPendingTarget, bCentaur)
		}
		return
	}

	if (Player[iOwner][PlrLaserPendingAt] > 0.0 || Player[iOwner][PlrLaserIndicateEndAt] > 0.0
		|| Player[iOwner][PlrLaserLockTime] > fGameTime)
	{
		if (Player[iOwner][PlrLaserPendingAt] > 0.0)
			zombie_play_idle(iMinion)
		else
			set_entvar(iMinion, var_nextthink, fGameTime + 0.1)

		set_entvar(iMinion, var_velocity, NULL_VECTOR)
		return
	}

	if (kc_player_in_silence(iOwner))
	{
		zombie_play_idle(iMinion)
		set_entvar(iMinion, var_velocity, NULL_VECTOR)
		return
	}

	if (bCentaur && necro_release_centaur_spit(iMinion, iOwner, vOrigin))
		return

	new bool:bReturning, iTarget, iAttackSlot = -1
	new iAttackOwner, iFoundSlot
	if (necro_find_minion_slot(iMinion, iAttackOwner, iFoundSlot) && iAttackOwner == iOwner)
		iAttackSlot = iFoundSlot

	if (iAttackSlot >= 0 && !bCentaur && Player[iOwner][PlrMinionJumpUntil][iAttackSlot] > fGameTime)
	{
		new iJumpTarget = Player[iOwner][PlrNpcActionTarget][iAttackSlot]
		new bool:bLanded = fGameTime > Player[iOwner][PlrMinionJumpUntil][iAttackSlot] - ZOMBIE_JUMP_MAX_TIME + 0.25
			&& (get_entvar(iMinion, var_flags) & FL_ONGROUND)

		if (necro_valid_manual_target(iOwner, iJumpTarget))
		{
			new Float:vJumpTarget[3]
			get_entvar(iJumpTarget, var_origin, vJumpTarget)
			if (get_distance_f(vOrigin, vJumpTarget) <= ZOMBIE_ATTACK_RANGE)
			{
				necro_attack_entity(iMinion, iOwner, iJumpTarget, false)
				necro_play_attack_animation(iMinion, false)
				Player[iOwner][PlrMinionJumpUntil][iAttackSlot] = 0.0
				Player[iOwner][PlrMinionNextAttackAt][iAttackSlot] = fGameTime + MINION_ATTACK_INTERVAL
				set_entvar(iMinion, var_nextthink, fGameTime + MINION_ATTACK_INTERVAL)
				return
			}
		}
		else
			bLanded = true

		if (bLanded)
			Player[iOwner][PlrMinionJumpUntil][iAttackSlot] = 0.0
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

	necro_command_destination(iOwner, iAttackSlot, bCentaur, vOrigin, vDestination, iTarget, bReturning)

	if (kc_player_in_darkness(iOwner))
	{
		get_entvar(iOwner, var_origin, vDestination)
		iTarget = 0
		bReturning = false
	}

	if (iTarget && is_entity(iTarget) && get_entvar(iTarget, var_impulse) == IMPULSE_PRESENT
		&& get_distance_f(vOrigin, vDestination) <= (bCentaur ? CENTAUR_ATTACK_RANGE : ZOMBIE_ATTACK_RANGE))
	{
		dllfunc(DLLFunc_Touch, iTarget, iOwner)
		set_entvar(iMinion, var_npctarget, 0)
		set_entvar(iMinion, var_nextthink, fGameTime + 0.2)
		return
	}

	if (iTarget && is_entity(iTarget) && get_entvar(iTarget, var_impulse) == IMPULSE_CORPSE
		&& get_distance_f(vOrigin, vDestination) <= (bCentaur ? CENTAUR_ATTACK_RANGE : ZOMBIE_ATTACK_RANGE))
	{
		new Float:fMaxHealth = bCentaur ? CENTAUR_HEALTH : ZOMBIE_HEALTH
		set_entvar(iMinion, var_health,
			floatmin(Float:get_entvar(iMinion, var_health) + CORPSE_HEAL, fMaxHealth))

		send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, 70, 5)
		engfunc(EngFunc_EmitSound, iMinion, CHAN_AUTO,
			SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		rg_remove_entity(iTarget)

		necro_play_attack_animation(iMinion, bCentaur)
		set_entvar(iMinion, var_npctarget, 0)
		set_entvar(iMinion, var_nextthink, fGameTime + 0.2)
		return
	}

	if (iTarget && get_distance_f(vOrigin, vDestination) <= (bCentaur ? CENTAUR_ATTACK_RANGE : ZOMBIE_ATTACK_RANGE))
	{
		if (iAttackSlot >= 0 && Player[iOwner][PlrMinionNextAttackAt][iAttackSlot] > fGameTime)
		{
			set_entvar(iMinion, var_velocity, NULL_VECTOR)
			zombie_play_idle(iMinion, 0.1)
			return
		}

		npc_TurnToTarget(iMinion, vOrigin, vDestination)
		set_entvar(iMinion, var_velocity, NULL_VECTOR)
		necro_play_attack_animation(iMinion, bCentaur)
		set_entvar(iMinion, var_npctarget, iTarget)
		if (iAttackSlot >= 0)
			Player[iOwner][PlrMinionNextAttackAt][iAttackSlot] = fGameTime + MINION_ATTACK_INTERVAL
		set_entvar(iMinion, var_nextthink, fGameTime + ATTACK_WINDUP_TIME)
		return
	}

	if (bCentaur && iTarget && necro_start_centaur_spit(iMinion, vOrigin, iTarget))
		return

	if (bCentaur && iAttackSlot >= 0 && Player[iOwner][PlrNpcAction][iAttackSlot] == NPC_ACTION_MOVE)
	{
		new Float:vSpitTarget[3]
		new iSpitTarget = find_necro_target(iOwner, vOrigin, CENTAUR_SPIT_SEARCH_RANGE, 0, vSpitTarget)
		if (iSpitTarget && necro_start_centaur_spit(iMinion, vOrigin, iSpitTarget))
			return
	}

	if (iAttackSlot >= 0)
	{
		if (Player[iOwner][PlrNpcAction][iAttackSlot] != NPC_ACTION_MOVE)
			Player[iOwner][PlrMoveWindupTarget][iAttackSlot] = 0
		else if (necro_move_mode_attack(iMinion, iOwner, iAttackSlot, bCentaur, vOrigin, bReturning))
			return
	}

	if (get_distance_f(vOrigin, vDestination) <= 60.0)
	{
		zombie_play_idle(iMinion)
		set_entvar(iMinion, var_nextthink, fGameTime + 0.1)
		return
	}

	npc_TurnToTarget(iMinion, vOrigin, vDestination)
	npc_Move(iMinion, necro_get_move_speed(iMinion, bReturning))
	necro_set_move_animation(iMinion, bCentaur)
	set_entvar(iMinion, var_nextthink, fGameTime + 0.1)
}

bool:necro_move_mode_attack(iMinion, iOwner, iSlot, bool:bCentaur, const Float:vOrigin[3], bool:bReturning)
{
	new Float:fGameTime = get_gametime()
	new Float:fRange = bCentaur ? CENTAUR_ATTACK_RANGE : ZOMBIE_ATTACK_RANGE
	new iWindupTarget = Player[iOwner][PlrMoveWindupTarget][iSlot]

	if (iWindupTarget)
	{
		if (fGameTime < Player[iOwner][PlrMoveWindupEndAt][iSlot])
		{
			set_entvar(iMinion, var_velocity, NULL_VECTOR)
			set_entvar(iMinion, var_nextthink, fGameTime + 0.1)
			return true
		}

		Player[iOwner][PlrMoveWindupTarget][iSlot] = 0

		if (necro_is_enemy_entity(iOwner, iWindupTarget))
		{
			new Float:vWindupOrigin[3]
			get_entvar(iWindupTarget, var_origin, vWindupOrigin)
			if (get_distance_f(vOrigin, vWindupOrigin) <= fRange)
				necro_attack_entity(iMinion, iOwner, iWindupTarget, bCentaur)
		}

		Player[iOwner][PlrMoveIgnoreTarget][iSlot] = iWindupTarget
		Player[iOwner][PlrMoveIgnoreUntil][iSlot] = fGameTime + MOVE_HIT_IGNORE_TIME
		return false
	}

	if (bReturning)
		return false

	new iIgnore = Player[iOwner][PlrMoveIgnoreUntil][iSlot] > fGameTime ? Player[iOwner][PlrMoveIgnoreTarget][iSlot] : 0
	new Float:vEnemyOrigin[3]
	new iEnemy = find_necro_target(iOwner, vOrigin, fRange, 0, vEnemyOrigin, iIgnore)
	if (!iEnemy)
		return false

	new Float:vSelfOrigin[3]
	xs_vec_copy(vOrigin, vSelfOrigin)
	npc_TurnToTarget(iMinion, vSelfOrigin, vEnemyOrigin)
	necro_play_attack_animation(iMinion, bCentaur)
	set_entvar(iMinion, var_velocity, NULL_VECTOR)

	Player[iOwner][PlrMoveWindupTarget][iSlot] = iEnemy
	Player[iOwner][PlrMoveWindupEndAt][iSlot] = fGameTime + MOVE_WINDUP_TIME
	set_entvar(iMinion, var_nextthink, fGameTime + MOVE_WINDUP_TIME)
	return true
}

public necro_zombie_think(iZombieEnt)
{
	necro_minion_think(iZombieEnt, false)
}

public necro_centaur_think(iCentaurEnt)
{
	necro_minion_think(iCentaurEnt, true)
}

public npc_TakeDamage(iZombieEnt, iInflictor, iAttacker, Float:fDamage, iDmgBits)
{
	if (get_entvar(iZombieEnt, var_impulse) != IMPULSE_ZOMBIE)
		return HAM_IGNORED

	if (get_entvar(iZombieEnt, var_flags) & FL_KILLME)
		return HAM_IGNORED

	new iOwner = get_entvar(iZombieEnt, var_npcowner)
	new Float:fGameTime = get_gametime()

	if (!is_entity_player(iOwner))
		return HAM_SUPERCEDE

	if (!Player[iOwner][PlrIsAlive])
		return HAM_SUPERCEDE

	if (kc_player_in_silence(iOwner))
		return HAM_SUPERCEDE

	new iDamagedSlot, iDamagedOwner
	necro_find_minion_slot(iZombieEnt, iDamagedOwner, iDamagedSlot)

	new Float:vMinionOrigin[3], Float:vReference[3], Float:fRadius = necro_get_aggression_radius(iOwner)
	get_entvar(iZombieEnt, var_origin, vMinionOrigin)
	get_entvar(iOwner, var_origin, vReference)
	if (iDamagedOwner == iOwner && Player[iOwner][PlrNpcAction][iDamagedSlot] == NPC_ACTION_TARGET)
	{
		new iTarget = Player[iOwner][PlrNpcActionTarget][iDamagedSlot]
		if (is_entity_player(iTarget))
		{
			if (Player[iTarget][PlrIsAlive])
				get_entvar(iTarget, var_origin, vReference)
		}
		fRadius = MINION_TARGET_RADIUS
	}
	if (get_distance_f(vMinionOrigin, vReference) > fRadius)
		return HAM_SUPERCEDE

	if (is_entity_player(iAttacker))
	{
		if (Player[iOwner][PlrTeam] == Player[iAttacker][PlrTeam] && iOwner != iAttacker)
		{
			if (Float:get_entvar(iZombieEnt, var_npcspawntime) + NPC_TEAMMATE_DAMAGE_TIME < fGameTime)
				return HAM_SUPERCEDE
		}
	}

	new Float:vOrigin[3]
	new Float:fHealth = Float:get_entvar(iZombieEnt, var_health)
	get_entvar(iZombieEnt, var_origin, vOrigin)

	new bool:bDamageChanged
	if (!g_bMinionDot && (iDmgBits & DMG_NPC_SLOW))
		necro_minion_slow(iZombieEnt)

	if (g_bMinionDot)
	{
		if (fDamage < fHealth)
		{
			set_entvar(iZombieEnt, var_health, fHealth - fDamage)
			set_entvar(iZombieEnt, var_fuser3, fGameTime)
			return HAM_SUPERCEDE
		}
	}
	else if (iDmgBits & DMG_SLOWFREEZE)
	{
		necro_minion_chill(iZombieEnt)
		return HAM_SUPERCEDE
	}
	else if (iDmgBits & DMG_BURN)
	{
		necro_minion_burn(iZombieEnt, iAttacker)
		return HAM_SUPERCEDE
	}
	else if (iDmgBits & DMG_FREEZE)
	{
		if (necro_minion_freeze(iZombieEnt))
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
		set_entvar(iZombieEnt, var_fuser3, fGameTime)

		engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
			SOUNDS_ZOMBIE_PAIN[random(sizeof SOUNDS_ZOMBIE_PAIN)],
			1.0, ATTN_NORM, 0, !get_entvar(iZombieEnt, var_npctype) ? PITCH_NORM : PITCH_LOW)

		send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, 70, 5)
	}
	else
	{
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
			Player[iDamagedOwner][PlrZombieCharge][iDamagedSlot] = 0.0
			Player[iDamagedOwner][PlrMinionJumpUntil][iDamagedSlot] = 0.0
			Player[iDamagedOwner][PlrMinionRespawnAt][iDamagedSlot] = fGameTime + MINION_RESPAWN_TIME
		}

		engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
			SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		create_gore(vOrigin)

		set_entvar(iZombieEnt, var_solid, SOLID_NOT)
		set_entvar(iZombieEnt, var_health, 0.0)
		set_entvar(iZombieEnt, var_flags, FL_KILLME)
		set_entvar(iZombieEnt, var_nextthink, fGameTime)
		return HAM_SUPERCEDE
	}

	return bDamageChanged ? HAM_OVERRIDE : HAM_IGNORED
}

zombie_play_idle(iZombieEnt, Float:fNextThink=0.1)
{
	if (get_entvar(iZombieEnt, var_sequence) != 0 && get_gametime() >= Float:get_entvar(iZombieEnt, var_fuser4))
	{
		set_entvar(iZombieEnt, var_animtime, 0.0)
		set_entvar(iZombieEnt, var_frame, 0.0)
		set_entvar(iZombieEnt, var_sequence, 0)
	}
	set_entvar(iZombieEnt, var_nextthink, get_gametime() + fNextThink)
}

bool:necro_minion_is_frozen(iMinion)
{
	return bool:(g_fMinionFrozenUntil[iMinion] > get_gametime())
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
	g_iMinionBurnCycles[iMinion] = 0
	g_iMinionBurnAttacker[iMinion] = 0
	g_fMinionBurnNextTick[iMinion] = 0.0
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
	while ((iMinion = rg_find_ent_by_class(iMinion, _CLASSNAME_ZOMBIE)))
	{
		if (get_entvar(iMinion, var_impulse) != IMPULSE_ZOMBIE || (get_entvar(iMinion, var_flags) & FL_KILLME))
			continue

		if (g_fMinionFrozenUntil[iMinion] > 0.0 && g_fMinionFrozenUntil[iMinion] <= fGameTime)
			necro_minion_unfreeze(iMinion)

		if (g_fMinionChilledUntil[iMinion] > 0.0 && g_fMinionChilledUntil[iMinion] <= fGameTime)
		{
			g_fMinionChilledUntil[iMinion] = 0.0
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

	if (get_entvar(iEnt, var_impulse) != IMPULSE_ZOMBIE)
		return HAM_IGNORED

	SetHamReturnInteger(7) // CLASS_ALIEN_MONSTER
	return HAM_OVERRIDE
}

npc_TurnToTarget(iEnt, Float:vOrigin[3], Float:vTargetOrigin[3])
{
	static Float:x, Float:z, Float:fRadians, Float:vAngles[3]
	get_entvar(iEnt, var_angles, vAngles)
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

npc_Move(ent, Float:fSpeed)
{
	static Float:vflVelocity[3]
	get_entvar(ent,var_velocity,vflVelocity)

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

	vflCheckPos[0] = floatcos(vflAngles[1], degrees) * 22.0 + vOrigin[0]
	vflCheckPos[1] = floatsin(vflAngles[1], degrees) * 22.0 + vOrigin[1]

	static Float:flFract, tr

	tr = create_tr2()
	engfunc(EngFunc_TraceLine, vOrigin, vflCheckPos, IGNORE_MONSTERS, ent, tr)
	get_tr2(tr, TR_flFraction, flFract)
	free_tr2(tr)

	if (flFract < 0.9)
	{
		vflVelocity[2] = 200.0
	}
	else
	{
		// check Left
		vflCheckPos[0] = floatcos(vflAngles[1] - 45.0, degrees) * 22.0 + vOrigin[0]
		vflCheckPos[1] = floatsin(vflAngles[1] - 45.0, degrees) * 22.0 + vOrigin[1]

		tr = create_tr2()
		engfunc(EngFunc_TraceLine, vOrigin, vflCheckPos, IGNORE_MONSTERS, ent, tr)
		get_tr2(tr, TR_flFraction, flFract)
		free_tr2(tr)

		if(flFract < 0.9)
		{
			vflVelocity[2] = 200.0
		}
		else
		{
			// check Right
			vflCheckPos[0] = floatcos(vflAngles[1] + 45.0, degrees) * 22.0 + vOrigin[0]
			vflCheckPos[1] = floatsin(vflAngles[1] + 45.0, degrees) * 22.0 + vOrigin[1]

			tr = create_tr2()
			engfunc(EngFunc_TraceLine, vOrigin, vflCheckPos, IGNORE_MONSTERS, ent, tr)
			get_tr2(tr, TR_flFraction, flFract)
			free_tr2(tr)

			if (flFract < 0.9)
				vflVelocity[2] = 200.0
		}
	}
	set_entvar(ent, var_velocity, vflVelocity)
}

create_zombie(Float:vOrigin[3], Float:vAngles[3], iOwner, iSlot = 0)
{
	new iTeam = Player[iOwner][PlrTeam]
	new iZombieEnt = rg_create_entity(SZ_EXPLOSION)
	if (is_nullent(iZombieEnt))
		return NULLENT

	necro_minion_reset_status(iZombieEnt)

	engfunc(EngFunc_SetOrigin, iZombieEnt, vOrigin)
	engfunc(EngFunc_SetModel, iZombieEnt, MODEL_ZOMBIE)
	engfunc(EngFunc_SetSize, iZombieEnt, Float:{-18.0, -18.0, 0.0}, Float:{18.0, 18.0, 20.0})

	set_entvar(iZombieEnt, var_origin, vOrigin)
	set_entvar(iZombieEnt, var_angles, vAngles)

	set_entvar(iZombieEnt, var_flags, FL_MONSTER)
	set_entvar(iZombieEnt, var_solid, SOLID_BBOX)
	set_entvar(iZombieEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iZombieEnt, var_skin, iTeam - 1)
	new Float:vVariant[3]
	vVariant[0] = iSlot == 1 ? 1.0 : 0.0
	set_entvar(iZombieEnt, var_vuser1, vVariant)
	set_entvar(iZombieEnt, var_rendermode, kRenderNormal)

	set_entvar(iZombieEnt, var_takedamage, 1.0)
	set_entvar(iZombieEnt, var_health, ZOMBIE_HEALTH)

	set_entvar(iZombieEnt, var_classname, _CLASSNAME_ZOMBIE)
	set_entvar(iZombieEnt, var_impulse, IMPULSE_ZOMBIE)
	set_entvar(iZombieEnt, var_npcowner, iOwner)

	new Float:fGameTime = get_gametime()

	set_entvar(iZombieEnt, var_animtime, fGameTime)
	set_entvar(iZombieEnt, var_frame, 0.0)
	set_entvar(iZombieEnt, var_framerate, 1.0)
	set_entvar(iZombieEnt, var_sequence, 4)

	set_entvar(iZombieEnt, var_npctarget, 0)
	set_entvar(iZombieEnt, var_npctype, 0)
	set_entvar(iZombieEnt, var_npcspawntime, fGameTime)
	set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.7)

	SetThink(iZombieEnt, "necro_zombie_think")

	set_member(iZombieEnt, m_bloodColor, 71)

	drop_to_floor(iZombieEnt)

	new i
	for (i = 1; i <= MaxClients; i++)
		if (Player[i][PlrIsAlive])
			check_stuck(i, iZombieEnt, vOrigin)

	i = -1
	while ((i = find_ent_by_class(i, _CLASSNAME_ZOMBIE)))
		if (i != iZombieEnt)
			check_stuck_zombies(i, iZombieEnt, vOrigin)

	return iZombieEnt
}

create_centaur(Float:vOrigin[3], Float:vAngles[3], Float:fHealth, iOwner)
{
	new iCentaurEnt = rg_create_entity(SZ_EXPLOSION)
	if (is_nullent(iCentaurEnt))
		return NULLENT

	necro_minion_reset_status(iCentaurEnt)

	new iTeam = Player[iOwner][PlrTeam]

	engfunc(EngFunc_SetOrigin, iCentaurEnt, vOrigin)
	engfunc(EngFunc_SetModel, iCentaurEnt, MODEL_CENTAUR)
	engfunc(EngFunc_SetSize, iCentaurEnt, Float:{-18.0, -18.0, 0.0}, Float:{18.0, 18.0, 30.0})

	set_entvar(iCentaurEnt, var_origin, vOrigin)
	set_entvar(iCentaurEnt, var_flags, FL_MONSTER)
	set_entvar(iCentaurEnt, var_angles, vAngles)
	set_entvar(iCentaurEnt, var_solid, SOLID_BBOX)
	set_entvar(iCentaurEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iCentaurEnt, var_skin, iTeam - 1)
	set_entvar(iCentaurEnt, var_rendermode, kRenderNormal)

	set_entvar(iCentaurEnt, var_takedamage, 1.0)
	set_entvar(iCentaurEnt, var_health, fHealth > 0.0 ? fHealth : CENTAUR_HEALTH)

	set_entvar(iCentaurEnt, var_classname, _CLASSNAME_ZOMBIE)
	set_entvar(iCentaurEnt, var_impulse, IMPULSE_ZOMBIE)
	set_entvar(iCentaurEnt, var_npcowner, iOwner)

	new Float:fGameTime = get_gametime()

	set_entvar(iCentaurEnt, var_animtime, fGameTime)
	set_entvar(iCentaurEnt, var_frame, 0.0)
	set_entvar(iCentaurEnt, var_framerate, 1.0)
	set_entvar(iCentaurEnt, var_sequence, 1)

	set_entvar(iCentaurEnt, var_npctarget, 0)
	set_entvar(iCentaurEnt, var_npctype, 1)
	set_entvar(iCentaurEnt, var_npcspawntime, fGameTime)
	set_entvar(iCentaurEnt, var_nextthink, fGameTime + 1.13)

	SetThink(iCentaurEnt, "necro_centaur_think")

	set_member(iCentaurEnt, m_bloodColor, 71)

	new i
	for (i = 1; i <= MaxClients; i++)
		if (Player[i][PlrIsAlive])
			check_stuck(i, iCentaurEnt, vOrigin)

	i = -1
	while ((i = find_ent_by_class(i, _CLASSNAME_ZOMBIE)))
		if (i != iCentaurEnt)
			check_stuck_zombies(i, iCentaurEnt, vOrigin)

	drop_to_floor(iCentaurEnt)
	return iCentaurEnt
}

create_gore(const Float:vOrigin[3])
{
	new const blood_large[] = {204, 205}

	new Float:vDecalOrigin[3]
	vDecalOrigin[0] = vOrigin[0] + random_float(-50.0, 50.0)
	vDecalOrigin[1] = vOrigin[1] + random_float(-50.0, 50.0)
	vDecalOrigin[2] = vOrigin[2]
	send_msg_TE_WORLDDECAL(vDecalOrigin, blood_large[random(2)])

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
			write_byte(248)
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

		engfunc(EngFunc_EmitSound, iMinionEnt, CHAN_AUTO,
			SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
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
	Player[iOwner][PlrMergeOrdered] = false

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
	while ((iSpitEnt = rg_find_ent_by_class(iSpitEnt, _CLASSNAME_ZOMBIE_SPIT)))
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

	engfunc(EngFunc_TraceLine, vStart, vDest, 0, iPlayer, 0)
	get_tr2(0, TR_vecEndPos, vOrigin)

	return get_tr2(0, TR_pHit)
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

check_stuck_zombies(zmb, ent, Float:vNpcOrigin[3])
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
			if (Player[i][PlrNpcAction][iSlot] == NPC_ACTION_TARGET && Player[i][PlrNpcActionTarget][iSlot] == iTarget)
			{
				Player[i][PlrNpcAction][iSlot] = NPC_ACTION_FOLLOW
				Player[i][PlrNpcActionTarget][iSlot] = 0
			}
		}
	}
}

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)
}
