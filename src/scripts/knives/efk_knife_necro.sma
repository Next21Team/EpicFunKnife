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

#define HP				85.0
#define GRAVITY			1.0
#define SPEED			240.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL		10

#define ABIL1_NAME		"Necro"
#define ABIL1_CHARGE	4.0
#define ABIL1_TYPE		ABIL_TARGET_FLOOR
#define ABIL1_MINDIST	120.0
#define ABIL1_MAXDIST	3000.0

#define ABIL_ZOMBIES_PER_USE 	2

#define ACTION_CIRCLE_RADIUS 	100.0

new const MODEL_V_KNIFE[] = "models/next21_efk/v_necro_knife_b02.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_necro_knife.mdl"

new const SOUND_KNIFE_HIT1[] = "next21_efk/necro_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[] = "next21_efk/necro_knife_hit2.wav"
new const SOUND_KNIFE_STAB[] = "next21_efk/necro_knife_stab.wav"
new const SOUND_KNIFE_HITWALL[] = "next21_efk/necro_knife_hitwall.wav"
new const SOUND_KNIFE_SLASH[] = "next21_efk/necro_knife_slash.wav"

new const MODEL_ZOMBIE[] = "models/next21_efk/zombie.mdl"
new const MODEL_CENTAUR[] = "models/next21_efk/centaur.mdl"

#define SPIT_DAMAGE		20.0
#define SPIT_LIFETIME	45.0

new const MODEL_SPIT[] = "models/next21_efk/crimson_spore.mdl"

new const SOUND_SOUL[] = "next21_efk/soul_pulse.wav"

#define PARASITE_LIFE		4.0

#define MAX_ZOMBIES		4

#define NPC_TEAMMATE_DAMAGE_TIME 5.0

#define ZOMBIE_HEALTH			40.0
#define ZOMBIE_MIN_DAMAGE		20.0
#define ZOMBIE_MAX_DAMAGE		30.0
#define ZOMBIE_ATTACK_RANGE		90.0

#define CENTAUR_HEALTH			50.0
#define CENTAUR_MIN_DAMAGE		30.0
#define CENTAUR_MAX_DAMAGE		40.0
#define CENTAUR_ATTACK_RANGE	90.0
#define CENTAUR_SPIT_MIN_RANGE	250.0

#define SOUL_HEAL_VALUE			15.0
#define SOUL_HEAL_RADIUS		200.0

#define CORPSE_HEAL				50.0

new const COLOR_SOUL[]			= {0, 255, 0}

new const SZ_EXPLOSION[]		= "env_explosion"

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

new const NPC_ACTIONS_NAMES[][] =
{
	"NPC_ACTION_HUNTER",
	"NPC_ACTION_MOVE",
	"NPC_ACTION_FOLLOW",
	"NPC_ACTION_TARGET",
	"NPC_ACTION_CIRCLE",
	"NPC_ACTION_CANNIBAL"
}

enum NpcAction
{
	NPC_ACTION_NONE = -1,
	NPC_ACTION_HUNTER,
	NPC_ACTION_MOVE,
	NPC_ACTION_FOLLOW,
	NPC_ACTION_TARGET,
	NPC_ACTION_CIRCLE,
	NPC_ACTION_CANNIBAL
}

enum _:PlayerData
{
	bool:PlrIsAlive,
	PlrTeam,
	PlrKnife,
	NpcAction:PlrNpcAction,
	PlrNpcActionTarget,
	Float:PlrNpcActionYaw,
	PlrSouls,
	PlrParasite
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
	Float:g_vTargetOrigin[MAX_PLAYERS + 1][3], Float:g_fParasiteLife[MAX_PLAYERS + 1],
	g_iZombieTeamCount[2],
	g_pShockwaveSpr, g_pPointSpr, g_pBloodSpr, g_pBloodSpraySpr, g_pGibs[5], g_pKnifePMdl

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
	precache_model(MODEL_CENTAUR)
	precache_model(MODEL_SPIT)

	precache_sound(SOUND_SOUL)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	g_pBloodSpr = precache_model("sprites/blood.spr")
	g_pBloodSpraySpr = precache_model("sprites/bloodspray.spr")
	g_pGibs[0] = precache_model("models/Fleshgibs.mdl")
	g_pGibs[1] = precache_model("models/GIB_B_Gib.mdl")
	g_pGibs[2] = precache_model("models/GIB_Skull.mdl")
	g_pGibs[3] = precache_model("models/GIB_B_Bone.mdl")
	g_pGibs[4] = precache_model("models/GIB_Lung.mdl")

	g_pPointSpr = precache_model("sprites/next21_efk/npc_point.spr")
	g_pShockwaveSpr = precache_model("sprites/shockwave.spr")
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
	kc_knife_set_flags(g_iKnifeId, KNFF_ZOOM)
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

	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", true)

	RegisterHam(Ham_TakeDamage, SZ_EXPLOSION, "npc_TakeDamage")
	RegisterHam(Ham_Classify, SZ_EXPLOSION, "npc_Classify")
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0
	Player[iPlayer][PlrKnife] = -1
	Player[iPlayer][PlrParasite] = 0
}

public client_disconnected(iPlayer)
{
	clear_npc_action_target(iPlayer)

	kill_all_npc(iPlayer)

	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0
	Player[iPlayer][PlrKnife] = -1

	for (new i = 1; i <= MaxClients; i++)
		if (Player[i][PlrParasite] == iPlayer)
			Player[i][PlrParasite] = 0
}

public RG_CSGameRules_RestartRound_Pre()
{
	arrayset(g_iZombieTeamCount, 0, sizeof g_iZombieTeamCount)

	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		Player[iPlayer][PlrNpcAction] = NPC_ACTION_NONE
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_ZOMBIE)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_ZOMBIE_SPIT)))
		rg_remove_entity(iEnt)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return HC_CONTINUE

	Player[iPlayer][PlrIsAlive] = true
	Player[iPlayer][PlrParasite] = 0
	Player[iPlayer][PlrSouls] = 0

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	new iEnt = MaxClients
	while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, 64.0)))
	{
		if (get_entvar(iEnt, var_impulse) == IMPULSE_ZOMBIE)
			ExecuteHamB(Ham_TakeDamage, iEnt, 0, iEnt, 9000.0, DMG_BLAST)
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_ImpulseCommands_Pre(iPlayer)
{
	if (get_entvar(iPlayer, var_impulse) != 201)
		return HC_CONTINUE

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HC_CONTINUE

	if (get_entvar(iPlayer, var_button) & IN_USE)
	{
		try_apply_cannibalism(iPlayer)
		set_entvar(iPlayer, var_impulse, 0)
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_PostThink_Pre(iPlayer)
{
	if (!Player[iPlayer][PlrIsAlive])
		return HC_CONTINUE

	if (Player[iPlayer][PlrParasite] && g_fParasiteLife[iPlayer] <= get_gametime())
		Player[iPlayer][PlrParasite] = 0

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HC_CONTINUE

	new iButtons = get_entvar(iPlayer, var_button)
	new iTeam = Player[iPlayer][PlrTeam]

	if (Player[iPlayer][PlrSouls] && (iButtons & IN_USE) && (iButtons & ~IN_RELOAD)
		&& !kc_player_in_silence(iPlayer) && kc_player_get_capture(iPlayer) == CAPTURE_NONE)
	{
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SOUL, 1.0, ATTN_NORM, 0, PITCH_NORM)

		new Float:vOrigin[3], Float:vAxis[3]
		get_entvar(iPlayer, var_origin, vOrigin)
		xs_vec_copy(vOrigin, vAxis)
		vAxis[2] += 255.0

		send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, g_pShockwaveSpr, 0, 0, 2, 5, 0, COLOR_SOUL, 255, 0, MSG_PAS, vOrigin)

		new iEnt = NULLENT, iOwner, Float:fHealth
		while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, SOUL_HEAL_RADIUS)))
		{
			if (is_entity_player(iEnt))
			{
				if (Player[iEnt][PlrIsAlive] && Player[iEnt][PlrTeam] == iTeam)
				{
					fHealth = Float:get_entvar(iEnt, var_health)
					set_entvar(iEnt, var_health, floatmin(fHealth + SOUL_HEAL_VALUE * Player[iPlayer][PlrSouls], MAX_PLAYER_HEALTH))
				}
			}
			else
			{
				if (get_entvar(iEnt, var_impulse) == IMPULSE_ZOMBIE)
				{
					iOwner = get_entvar(iEnt, var_npcowner)
					if (is_entity_player(iOwner) && Player[iOwner][PlrTeam] == iTeam)
					{
						fHealth = Float:get_entvar(iEnt, var_health)
						set_entvar(iEnt, var_health, floatmin(fHealth + SOUL_HEAL_VALUE * Player[iPlayer][PlrSouls], MAX_PLAYER_HEALTH))
					}
				}
			}
		}

		Player[iPlayer][PlrSouls] = 0
	}

	if (Player[iPlayer][PlrNpcAction] != NPC_ACTION_NONE)
	{
		static Float:fCommandDelay[MAX_PLAYERS + 1], bool:bLastChoosedAction[MAX_PLAYERS + 1], bool:bLastPressedReload[MAX_PLAYERS + 1]
		new Float:fGameTime = get_gametime()

		if (iButtons & IN_RELOAD)
		{
			if (fGameTime > fCommandDelay[iPlayer])
			{
				if ((iButtons & IN_ATTACK) || (iButtons & IN_USE))
				{
					new iTarget = rg_get_aim_origin(iPlayer, g_vTargetOrigin[iPlayer])
					if (iButtons & IN_ATTACK)
					{
						if (is_entity_player(iTarget) && iTeam != Player[iTarget][PlrTeam])
						{
							Player[iPlayer][PlrNpcAction] = NPC_ACTION_TARGET
							Player[iPlayer][PlrNpcActionTarget] = iTarget
						}
						else
							Player[iPlayer][PlrNpcAction] = NPC_ACTION_MOVE
					}
					else
					{
						Player[iPlayer][PlrNpcAction] = NPC_ACTION_CIRCLE

						new Float:vAngles[3]
						get_entvar(iPlayer, var_v_angle, vAngles)
						Player[iPlayer][PlrNpcActionYaw] = vAngles[1] < 0.0 ? 360.0 + vAngles[1] : vAngles[1]
					}

					new Float:vSpriteOrigin[3]
					xs_vec_copy(g_vTargetOrigin[iPlayer], vSpriteOrigin)
					vSpriteOrigin[2] += 30.0
					send_msg_TE_SPRITE(vSpriteOrigin, g_pPointSpr, 8, 100, MSG_ONE, _, iPlayer)

					fCommandDelay[iPlayer] = fGameTime + 0.1
					bLastChoosedAction[iPlayer] = true
				}
				else if (iButtons & IN_ATTACK2)
				{
					Player[iPlayer][PlrNpcAction] = NPC_ACTION_FOLLOW
					fCommandDelay[iPlayer] = fGameTime + 0.1
					bLastChoosedAction[iPlayer] = true
				}
			}
			bLastPressedReload[iPlayer] = true
		}
		else if (bLastPressedReload[iPlayer])
		{
			if (!bLastChoosedAction[iPlayer])
				Player[iPlayer][PlrNpcAction] = NPC_ACTION_HUNTER

			bLastChoosedAction[iPlayer] = false
			bLastPressedReload[iPlayer] = false
		}
	}

	return HC_CONTINUE
}

public fw_PlayerDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (!is_entity_player(iAttacker))
		return HAM_IGNORED

	if (!(iFlags & DMG_BULLET))
		return HAM_IGNORED

	if (Player[iAttacker][PlrKnife] != g_iKnifeId)
		return HAM_IGNORED

	Player[iVictim][PlrParasite] = iAttacker
	g_fParasiteLife[iAttacker] = get_gametime() + PARASITE_LIFE

	return HAM_IGNORED
}

public fw_PlayerKilled(iVictim, iAttacker)
{
	Player[iVictim][PlrIsAlive] = false
	Player[iVictim][PlrSouls] = 0

	clear_npc_action_target(iVictim)

	if (is_entity_player(iAttacker) && iAttacker != iVictim)
		if (Player[iAttacker][PlrKnife] == g_iKnifeId)
			Player[iAttacker][PlrSouls]++

	if (Player[iVictim][PlrKnife] == g_iKnifeId)
		kill_all_npc(iVictim)

	if (Player[iVictim][PlrParasite])
		SetHamParamInteger(3, 2)
}

public fw_PlayerKilled_Post(iVictim, iAttacker)
{
	new iParasite = Player[iVictim][PlrParasite]
	if (iParasite)
	{
		new Float:vOrigin[3]
		get_entvar(iVictim, var_origin, vOrigin)

		new Float:vAngles[3]
		get_entvar(iVictim, var_v_angle, vAngles)
		vAngles[0] = vAngles[2] = 0.0

		if (Player[iParasite][PlrIsAlive])
			create_zombie(vOrigin, vAngles, iParasite)

		Player[iVictim][PlrParasite] = 0
	}
}

public efk_player_change_team(iPlayer, iTeam)
{
	Player[iPlayer][PlrTeam] = iTeam
}

public spit_think(iSpitEnt)
{
	rg_remove_entity(iSpitEnt)
}

public spit_touch(iSpitEnt, iOther)
{
	if (is_entity_player(iOther))
	{
		new iOwner = get_entvar(iSpitEnt, var_owner)
		if (Player[iOwner][PlrTeam] != Player[iOther][PlrTeam])
		{
			if (kc_player_apply_concentblock(iOther, iSpitEnt, ATTACK_HEAVINESS_LOW))
			{
				spit_kill(iSpitEnt, .bStabbed=true)
				return
			}

			Player[iOther][PlrParasite] = iOwner
			g_fParasiteLife[iOther] = get_gametime() + PARASITE_LIFE

			kc_player_set_death_reason(iOther, "DEATH_REASON_ZOMBIE")
			set_member(iOther, m_LastHitGroup, HIT_GENERIC)
		}

		ExecuteHamB(Ham_TakeDamage, iOther, iSpitEnt, iOwner, SPIT_DAMAGE, DMG_BLAST)

		spit_kill(iSpitEnt)
	}
	else
	{
		if (get_entvar(iOther, var_solid) > SOLID_TRIGGER)
		{
			switch (get_entvar(iOther, var_impulse))
			{
				case IMPULSE_ZOMBIE:
				{
					new iOwner = get_entvar(iSpitEnt, var_owner)
					if (Player[iOwner][PlrTeam] != get_entvar(iOther, var_npcowner))
						ExecuteHamB(Ham_TakeDamage, iOther, iSpitEnt, iOwner, SPIT_DAMAGE, DMG_BLAST)
				}
				case IMPULSE_PRESENT:
				{
					new iOwner = get_entvar(iSpitEnt, var_owner)
					dllfunc(DLLFunc_Touch, iOther, iOwner)
				}
				case IMPULSE_FAKEPLAYER:
				{
					new iOwner = get_entvar(iSpitEnt, var_owner)
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
	}
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
		kill_all_npc(iPlayer)

	Player[iPlayer][PlrKnife] = iKnifeId
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	static szMessage[80]; szMessage[0] = 0

	if (Player[iSubject][PlrSouls])
		formatex(szMessage, charsmax(szMessage), "Soul Pulse (%d) (E)", Player[iSubject][PlrSouls])

	new NpcAction:iNpcAction = Player[iSubject][PlrNpcAction]
	if (iNpcAction != NPC_ACTION_NONE)
		format(szMessage, charsmax(szMessage), "%s^nZombie: %L", szMessage, iPlayer, NPC_ACTIONS_NAMES[_:iNpcAction])

	if (szMessage[0] != 0)
	{
		set_hudmessage(0, 255, 0, 0.01, -0.73, 0, 0.0, 0.2, 0.2, 0.0, HUDCHANNEL_ALTABILITY)
		show_hudmessage(iPlayer, szMessage)
	}

	return PLUGIN_CONTINUE
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	static Float:fDelay[MAX_PLAYERS + 1]
	new Float:fGameTime = get_gametime()

	if (fDelay[iPlayer] > fGameTime)
		return PLUGIN_HANDLED

	fDelay[iPlayer] = fGameTime + 0.2

	if (!is_user_can_spawn_zombies(iPlayer))
		return _:CROSSHAIR_CANNOT

	return PLUGIN_CONTINUE
}

public efk_ability_pre(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (!is_user_can_spawn_zombies(iPlayer))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer)
{
	new iZombiesToSpawn = get_user_max_zombies_to_spawn(iPlayer)
	new Array:aPositions = get_user_zombies_spawn_positions(iPlayer, iZombiesToSpawn)
	new iRes = PLUGIN_CONTINUE

	new Float:vAngles[3]
	get_entvar(iPlayer, var_v_angle, vAngles)
	vAngles[0] = vAngles[2] = 0.0

	for (new i, Float:vPos[3]; i < ArraySize(aPositions); i++)
	{
		ArrayGetArray(aPositions, i, vPos)
		if (create_zombie(vPos, vAngles, iPlayer) == NULLENT)
			iRes = PLUGIN_HANDLED
	}
	ArrayDestroy(aPositions)

	return iRes
}

public zombie_think(iZombieEnt)
{
	new iOwner = get_entvar(iZombieEnt, var_npcowner)
	new iTargetEnt = get_entvar(iZombieEnt, var_npctarget)
	new Float:fGameTime = get_gametime()

	new Float:vOrigin[3], Float:vTargetOrigin[3]
	get_entvar(iZombieEnt, var_origin, vOrigin)

	if (!is_nullent(iTargetEnt) && !(get_entvar(iTargetEnt, var_flags) & FL_KILLME))
	{
		get_entvar(iTargetEnt, var_origin, vTargetOrigin)

		if (get_distance_f(vOrigin, vTargetOrigin) <= ZOMBIE_ATTACK_RANGE)
		{
			if (iTargetEnt <= MaxClients && Player[iTargetEnt][PlrIsAlive])
			{
				if (kc_player_apply_concentblock(iTargetEnt, iZombieEnt))
				{
					set_entvar(iZombieEnt, var_npctarget, 0)
					set_entvar(iZombieEnt, var_nextthink, fGameTime + 1.2)
					return
				}

				if (Player[iTargetEnt][PlrTeam] != Player[iOwner][PlrTeam])
				{
					Player[iTargetEnt][PlrParasite] = iOwner
					g_fParasiteLife[iTargetEnt] = fGameTime + PARASITE_LIFE

					kc_player_set_death_reason(iTargetEnt, "DEATH_REASON_ZOMBIE")
					set_member(iTargetEnt, m_LastHitGroup, HIT_GENERIC)
				}

				new Float:fDamage = float(floatround(random_float(ZOMBIE_MIN_DAMAGE, ZOMBIE_MAX_DAMAGE)))
				ExecuteHamB(Ham_TakeDamage, iTargetEnt, iZombieEnt, iOwner, fDamage, DMG_SLASH | DMG_ALWAYSGIB)
			}
			else
			{
				switch (get_entvar(iTargetEnt, var_impulse))
				{
					case IMPULSE_ZOMBIE:
					{
						if (get_entvar(iTargetEnt, var_npctype) == 0 && get_entvar(iZombieEnt, var_skin) == get_entvar(iTargetEnt, var_skin))
						{
							new Float:vAngles[3]
							get_entvar(iZombieEnt, var_angles, vAngles)

							new Float:fHealth =
								(Float:get_entvar(iZombieEnt, var_health) + Float:get_entvar(iTargetEnt, var_health)) / 2.0

							ExecuteHamB(Ham_TakeDamage, iTargetEnt, 0, iZombieEnt, 9000.0, DMG_BLAST)
							ExecuteHamB(Ham_TakeDamage, iZombieEnt, 0, iZombieEnt, 9000.0, DMG_BLAST)

							create_centaur(vOrigin, vAngles, fHealth, iOwner)

							return
						}
						else
						{
							ExecuteHamB(Ham_TakeDamage, iTargetEnt, 0, iTargetEnt, random_float(ZOMBIE_MIN_DAMAGE, ZOMBIE_MAX_DAMAGE), DMG_BULLET)
						}
					}
					case IMPULSE_CORPSE:
					{
						new Float:vAngles[3]
						get_entvar(iZombieEnt, var_angles, vAngles)

						if (create_centaur(vOrigin, vAngles, Float:get_entvar(iZombieEnt, var_health), iOwner) != NULLENT)
							ExecuteHamB(Ham_TakeDamage, iZombieEnt, 0, iZombieEnt, 9000.0, DMG_BLAST)
						else
							set_entvar(iZombieEnt, var_health, Float:get_entvar(iZombieEnt, var_health) + CORPSE_HEAL)

						rg_remove_entity(iTargetEnt)

						return
					}
					case IMPULSE_PRESENT:
					{
						dllfunc(DLLFunc_Touch, iTargetEnt, iOwner)
					}
					case IMPULSE_FAKEPLAYER:
					{
						ExecuteHamB(Ham_TakeDamage, iTargetEnt, iZombieEnt, iOwner, 10.0, DMG_BULLET)
					}
					default:
					{
						new Float:fDamage = random_float(ZOMBIE_MIN_DAMAGE, ZOMBIE_MAX_DAMAGE)
						ExecuteHamB(Ham_TakeDamage, iTargetEnt, 0, iTargetEnt, fDamage, DMG_BULLET)
					}
				}
			}
		}

		set_entvar(iZombieEnt, var_npctarget, 0)
		set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.5)

		return
	}

	if (!is_user_can_lead_zombies(iOwner))
	{
		zombie_play_idle(iZombieEnt)
		return
	}

	iTargetEnt = find_closes_target(Player[iOwner][PlrTeam], vOrigin, vTargetOrigin)

	new NpcAction:iNpcAction = Player[iOwner][PlrNpcAction]
	switch (iNpcAction)
	{
		case NPC_ACTION_HUNTER:
		{
			if (iTargetEnt)
			{
				npc_TurnToTarget(iZombieEnt, vOrigin, vTargetOrigin)

				if (get_distance_f(vOrigin, vTargetOrigin) <= ZOMBIE_ATTACK_RANGE)
				{
					set_entvar(iZombieEnt, var_npctarget, iTargetEnt)
					set_entvar(iZombieEnt, var_animtime, fGameTime)
					set_entvar(iZombieEnt, var_frame, 0.0)
					switch (get_entvar(iZombieEnt, var_sequence))
					{
						case 2: set_entvar(iZombieEnt, var_sequence, 3)
						case 3: set_entvar(iZombieEnt, var_sequence, 2)
						default: set_entvar(iZombieEnt, var_sequence, random_num(2, 3))
					}
					set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.3)

					engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
						SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)

				}
				else
				{
					npc_Move(iZombieEnt, 300.0)

					if (get_entvar(iZombieEnt, var_sequence) != 1)
					{
						set_entvar(iZombieEnt, var_animtime, 0.0)
						set_entvar(iZombieEnt, var_frame, 0.0)
						set_entvar(iZombieEnt, var_sequence, 1)
					}
					set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.3)
				}
			}
			else
				zombie_play_idle(iZombieEnt)
		}
		case NPC_ACTION_MOVE:
		{
			if (iTargetEnt && get_distance_f(vOrigin, vTargetOrigin) <= ZOMBIE_ATTACK_RANGE)
			{
				npc_TurnToTarget(iZombieEnt, vOrigin, vTargetOrigin)

				set_entvar(iZombieEnt, var_npctarget, iTargetEnt)
				set_entvar(iZombieEnt, var_animtime, fGameTime)
				set_entvar(iZombieEnt, var_frame, 0.0)
				set_entvar(iZombieEnt, var_sequence, random_num(2, 3))
				set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.3)

				engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
					SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			else
			{
				if (get_distance_f(vOrigin, g_vTargetOrigin[iOwner]) <= 60.0)
					zombie_play_idle(iZombieEnt)
				else
				{
					npc_TurnToTarget(iZombieEnt, vOrigin, g_vTargetOrigin[iOwner])
					npc_Move(iZombieEnt, 300.0)

					if(get_entvar(iZombieEnt, var_sequence) != 1)
					{
						set_entvar(iZombieEnt, var_animtime, 0.0)
						set_entvar(iZombieEnt, var_frame, 0.0)
						set_entvar(iZombieEnt, var_sequence, 1)
					}
					set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.1)
				}
			}
		}
		case NPC_ACTION_CANNIBAL:
		{
			if (iTargetEnt && get_distance_f(vOrigin, vTargetOrigin) <= ZOMBIE_ATTACK_RANGE)
			{
				npc_TurnToTarget(iZombieEnt, vOrigin, vTargetOrigin)

				set_entvar(iZombieEnt, var_npctarget, iTargetEnt)
				set_entvar(iZombieEnt, var_animtime, fGameTime)
				set_entvar(iZombieEnt, var_frame, 0.0)
				set_entvar(iZombieEnt, var_sequence, random_num(2, 3))
				set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.3)

				engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
					SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			else
			{
				new zombie = FM_NULLENT, zombieToEat
				new Stack:zombiesToEat = CreateStack();

				while ((zombie = find_zombie_by_owner(zombie, iOwner)))
				{
					if (get_entvar(zombie, var_npctype) != 0)
						continue

					PushStackCell(zombiesToEat, zombie)
				}

				while (!IsStackEmpty(zombiesToEat))
				{
					new a, b
					if (!PopStackCell(zombiesToEat, a) || !PopStackCell(zombiesToEat, b))
						break

					if (a == iZombieEnt)
					{
						zombieToEat = b;
						break
					}
					else if (b == iZombieEnt)
					{
						zombieToEat = a;
						break
					}
				}

				DestroyStack(zombiesToEat);

				if(zombieToEat) {
					get_entvar(zombieToEat, var_origin, vTargetOrigin)

					if (get_distance_f(vOrigin, vTargetOrigin) <= 60.0)
					{
						npc_TurnToTarget(iZombieEnt, vOrigin, vTargetOrigin)

						set_entvar(iZombieEnt, var_npctarget, zombieToEat)
						set_entvar(iZombieEnt, var_animtime, fGameTime)
						set_entvar(iZombieEnt, var_frame, 0.0)
						set_entvar(iZombieEnt, var_sequence, random_num(2, 3))
						set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.3)

						engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
							SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
					}
					else
					{
						npc_TurnToTarget(iZombieEnt, vOrigin, vTargetOrigin)
						npc_Move(iZombieEnt, 300.0)

						if(get_entvar(iZombieEnt, var_sequence) != 1)
						{
							set_entvar(iZombieEnt, var_animtime, 0.0)
							set_entvar(iZombieEnt, var_frame, 0.0)
							set_entvar(iZombieEnt, var_sequence, 1)
						}
						set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.1)
					}
				}
				else set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.1)
			}
		}
		case NPC_ACTION_CIRCLE:
		{
			if (iTargetEnt && get_distance_f(vOrigin, vTargetOrigin) <= ZOMBIE_ATTACK_RANGE)
			{
				npc_TurnToTarget(iZombieEnt, vOrigin, vTargetOrigin)

				set_entvar(iZombieEnt, var_npctarget, iTargetEnt)
				set_entvar(iZombieEnt, var_animtime, fGameTime)
				set_entvar(iZombieEnt, var_frame, 0.0)
				set_entvar(iZombieEnt, var_sequence, random_num(2, 3))
				set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.3)

				engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
					SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			else
			{
				new iZombieIndex = 0, iZombiesCount = 0, iFoundZombie = FM_NULLENT;
				while ((iFoundZombie = find_zombie_by_owner(iFoundZombie, iOwner)))
				{
					iZombiesCount++
					if (iFoundZombie <= iZombieEnt)
						iZombieIndex++
				}

				new Float:fYawAngle = iZombieIndex / float(iZombiesCount) * 360.0 + Player[iOwner][PlrNpcActionYaw]
				if(fYawAngle > 360.0) fYawAngle -= 360.0

				new Float:vZombieCirclePosition[3]
				vZombieCirclePosition[0] = g_vTargetOrigin[iOwner][0] + floatcos(fYawAngle, degrees) * ACTION_CIRCLE_RADIUS
				vZombieCirclePosition[1] = g_vTargetOrigin[iOwner][1] + floatsin(fYawAngle, degrees) * ACTION_CIRCLE_RADIUS
				vZombieCirclePosition[2] = g_vTargetOrigin[iOwner][2]

				if (get_distance_f(vOrigin, vZombieCirclePosition) <= 60.0)
					zombie_play_idle(iZombieEnt)
				else
				{
					npc_TurnToTarget(iZombieEnt, vOrigin, vZombieCirclePosition)
					npc_Move(iZombieEnt, 300.0)

					if (get_entvar(iZombieEnt, var_sequence) != 1)
					{
						set_entvar(iZombieEnt, var_animtime, 0.0)
						set_entvar(iZombieEnt, var_frame, 0.0)
						set_entvar(iZombieEnt, var_sequence, 1)
					}
					set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.1)
				}
			}
		}
		case NPC_ACTION_FOLLOW, NPC_ACTION_TARGET:
		{
			if (iTargetEnt && get_distance_f(vOrigin, vTargetOrigin) <= ZOMBIE_ATTACK_RANGE)
			{
				npc_TurnToTarget(iZombieEnt, vOrigin, vTargetOrigin)

				set_entvar(iZombieEnt, var_npctarget, iTargetEnt)
				set_entvar(iZombieEnt, var_animtime, fGameTime)
				set_entvar(iZombieEnt, var_frame, 0.0)
				set_entvar(iZombieEnt, var_sequence, random_num(2, 3))
				set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.3)

				engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
					SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			else
			{
				if (iNpcAction == NPC_ACTION_TARGET)
				{
					new iTarget = Player[iOwner][PlrNpcActionTarget]
					if (kc_player_get_visibility(iTarget) < VIS_TRANS)
						get_entvar(iTarget, var_origin, vTargetOrigin)
					else if (!iTargetEnt)
						zombie_play_idle(iZombieEnt)
				}
				else
					get_entvar(iOwner, var_origin, vTargetOrigin)

				if (get_distance_f(vOrigin, vTargetOrigin) <= 60.0)
					zombie_play_idle(iZombieEnt)
				else
				{
					npc_TurnToTarget(iZombieEnt, vOrigin, vTargetOrigin)
					npc_Move(iZombieEnt, 300.0)

					if(get_entvar(iZombieEnt, var_sequence) != 1)
					{
						set_entvar(iZombieEnt, var_animtime, 0.0)
						set_entvar(iZombieEnt, var_frame, 0.0)
						set_entvar(iZombieEnt, var_sequence, 1)
					}
					set_entvar(iZombieEnt, var_nextthink, fGameTime + 0.1)
				}
			}
		}
	}
}

public centaur_think(iCentaurEnt)
{
	new iTargetEnt = get_entvar(iCentaurEnt, var_npctarget)
	new iOwner = get_entvar(iCentaurEnt, var_npcowner)
	new Float:fGameTime = get_gametime()

	new Float:vOrigin[3], Float:vTargetOrigin[3]
	get_entvar(iCentaurEnt, var_origin, vOrigin)

	if (!is_nullent(iTargetEnt) && !(get_entvar(iTargetEnt, var_flags) & FL_KILLME))
	{
		get_entvar(iTargetEnt, var_origin, vTargetOrigin)

		if (get_distance_f(vOrigin, vTargetOrigin) <= CENTAUR_ATTACK_RANGE)
		{
			if (iTargetEnt <= MaxClients && Player[iTargetEnt][PlrIsAlive])
			{
				if (kc_player_apply_concentblock(iTargetEnt, iCentaurEnt))
				{
					set_entvar(iCentaurEnt, var_npctarget, 0)
					set_entvar(iCentaurEnt, var_nextthink, fGameTime + 1.2)
					return
				}

				if(Player[iTargetEnt][PlrTeam] != Player[iOwner][PlrTeam])
				{
					Player[iTargetEnt][PlrParasite] = iOwner
					g_fParasiteLife[iTargetEnt] = fGameTime + PARASITE_LIFE

					kc_player_set_death_reason(iTargetEnt, "DEATH_REASON_ZOMBIE")
					set_member(iTargetEnt, m_LastHitGroup, HIT_GENERIC)
				}

				new Float:fDamage = float(floatround(random_float(CENTAUR_MIN_DAMAGE, CENTAUR_MAX_DAMAGE)))
				ExecuteHamB(Ham_TakeDamage, iTargetEnt, iCentaurEnt, iOwner, fDamage, DMG_SLASH | DMG_ALWAYSGIB)
			}
			else
			{
				switch (get_entvar(iTargetEnt, var_impulse))
				{
					case IMPULSE_CORPSE:
					{
						send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, 70, 5)

						engfunc(EngFunc_EmitSound, iTargetEnt, CHAN_AUTO,
							SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)

						set_entvar(iCentaurEnt, var_health, Float:get_entvar(iCentaurEnt, var_health) + CORPSE_HEAL)

						rg_remove_entity(iTargetEnt)
					}
					case IMPULSE_PRESENT:
					{
						dllfunc(DLLFunc_Touch, iTargetEnt, iOwner)
					}
					case IMPULSE_FAKEPLAYER:
					{
						ExecuteHamB(Ham_TakeDamage, iTargetEnt, iCentaurEnt, iOwner, 10.0, DMG_BULLET)
					}
					default:
					{
						new Float:fDamage = random_float(CENTAUR_MIN_DAMAGE, CENTAUR_MAX_DAMAGE)
						ExecuteHamB(Ham_TakeDamage, iTargetEnt, 0, iTargetEnt, fDamage, DMG_BULLET)
					}
				}
			}
		}

		set_entvar(iCentaurEnt, var_npctarget, 0)
		set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.5)

		return
	}

	if (!is_user_can_lead_zombies(iOwner))
	{
		zombie_play_idle(iCentaurEnt)
		return
	}

	iTargetEnt = get_entvar(iCentaurEnt, var_npcspit)
	if (!is_nullent(iTargetEnt) && !(get_entvar(iTargetEnt, var_flags) & FL_KILLME))
	{
		new iSpitEnt = rg_create_entity(SZ_EXPLOSION)

		if (!is_nullent(iSpitEnt))
		{
			get_entity_center(iTargetEnt, vTargetOrigin)

			engfunc(EngFunc_SetModel, iSpitEnt, MODEL_SPIT)

			new Float:vVector[3]
			get_entvar(iCentaurEnt, var_angles, vVector)
			engfunc(EngFunc_MakeVectors, vVector)
			global_get(glb_v_forward, vVector)
			xs_vec_mul_scalar(vVector, 50.0, vVector)
			xs_vec_add(vOrigin, vVector, vVector)
			vVector[2] += 40.0

			engfunc(EngFunc_SetOrigin, iSpitEnt, vVector)
			engfunc(EngFunc_SetSize, iSpitEnt, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0})
			set_entvar(iSpitEnt, var_origin, vVector)
			set_entvar(iSpitEnt, var_solid, SOLID_TRIGGER)
			set_entvar(iSpitEnt, var_movetype, MOVETYPE_FLYMISSILE)
			set_entvar(iSpitEnt, var_rendermode, kRenderNormal)
			set_entvar(iSpitEnt, var_gravity, 0.0)
			set_entvar(iSpitEnt, var_classname, _CLASSNAME_ZOMBIE_SPIT)
			set_entvar(iSpitEnt, var_impulse, IMPULSE_ZOMBIE_SPIT)
			set_entvar(iSpitEnt, var_owner, iOwner)
			set_entvar(iSpitEnt, var_nextthink, fGameTime + SPIT_LIFETIME)

			send_msg_TE_BEAMFOLLOW(iSpitEnt, g_pShockwaveSpr, 4, 2, {195, 41, 28}, 100)

			new Float:vAngles[3]
			xs_vec_sub(vTargetOrigin, vVector, vAngles)
			xs_vec_normalize(vAngles, vVector)
			vector_to_angle(vVector, vAngles)
			xs_vec_mul_scalar(vVector, 1000.0, vVector)

			set_entvar(iSpitEnt, var_velocity, vVector)
			set_entvar(iSpitEnt, var_angles, vAngles)

			SetThink(iSpitEnt, "spit_think")
			SetTouch(iSpitEnt, "spit_touch")

			npc_TurnToTarget(iCentaurEnt, vOrigin, vTargetOrigin)

			set_entvar(iCentaurEnt, var_npcspit, 0)
			set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.4)

			return
		}
	}

	iTargetEnt = find_closes_target(Player[iOwner][PlrTeam], vOrigin, vTargetOrigin,
		Float:get_entvar(iCentaurEnt, var_health) > ZOMBIE_HEALTH)

	if (iTargetEnt && !random(5) && get_distance_f(vOrigin, vTargetOrigin) > CENTAUR_SPIT_MIN_RANGE)
	{
		if (get_entvar(iTargetEnt, var_impulse) != IMPULSE_CORPSE)
		{
			new Float:vVector[3], Float:fFraction
			xs_vec_copy(vOrigin, vVector)
			vVector[2] += 40.0
			engfunc(EngFunc_TraceLine, vVector, vTargetOrigin, 0, iCentaurEnt, 0)
			get_tr2(0, TR_flFraction, fFraction)

			if (fFraction > 0.9)
			{
				npc_TurnToTarget(iCentaurEnt, vOrigin, vTargetOrigin)

				set_entvar(iCentaurEnt, var_animtime, fGameTime)
				set_entvar(iCentaurEnt, var_frame, 0.0)
				set_entvar(iCentaurEnt, var_sequence, 5)
				set_entvar(iCentaurEnt, var_npcspit, iTargetEnt)
				set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.6)

				engfunc(EngFunc_EmitSound, iCentaurEnt, CHAN_AUTO, SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_LOW)

				return
			}
		}
	}

	new NpcAction:iNpcAction = Player[iOwner][PlrNpcAction]
	switch (iNpcAction)
	{
		case NPC_ACTION_HUNTER, NPC_ACTION_CANNIBAL:
		{
			if (iTargetEnt)
			{
				npc_TurnToTarget(iCentaurEnt, vOrigin, vTargetOrigin)

				if (get_distance_f(vOrigin, vTargetOrigin) <= CENTAUR_ATTACK_RANGE)
				{
					set_entvar(iCentaurEnt, var_npctarget, iTargetEnt)
					set_entvar(iCentaurEnt, var_animtime, fGameTime)
					set_entvar(iCentaurEnt, var_frame, 0.0)
					set_entvar(iCentaurEnt, var_sequence, random_num(3, 4))
					set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.3)

					engfunc(EngFunc_EmitSound, iCentaurEnt, CHAN_AUTO,
						SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_LOW)

				}
				else
				{
					npc_Move(iCentaurEnt, 200.0)

					if (get_entvar(iCentaurEnt, var_sequence) != 2)
					{
						set_entvar(iCentaurEnt, var_animtime, 0.0)
						set_entvar(iCentaurEnt, var_frame, 0.0)
						set_entvar(iCentaurEnt, var_sequence, 2)
					}
					set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.1)
				}
			}
			else
				zombie_play_idle(iCentaurEnt)
		}
		case NPC_ACTION_MOVE:
		{
			if (iTargetEnt && get_distance_f(vOrigin, vTargetOrigin) <= CENTAUR_ATTACK_RANGE)
			{
				npc_TurnToTarget(iCentaurEnt, vOrigin, vTargetOrigin)

				set_entvar(iCentaurEnt, var_npctarget, iTargetEnt)
				set_entvar(iCentaurEnt, var_animtime, fGameTime)
				set_entvar(iCentaurEnt, var_frame, 0.0)
				set_entvar(iCentaurEnt, var_sequence, random_num(3, 4))
				set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.3)

				engfunc(EngFunc_EmitSound, iCentaurEnt, CHAN_AUTO,
					SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_LOW)
			}
			else
			{
				if (get_distance_f(vOrigin, g_vTargetOrigin[iOwner]) <= 60.0)
				{
					zombie_play_idle(iCentaurEnt)
				}
				else
				{
					npc_TurnToTarget(iCentaurEnt, vOrigin, g_vTargetOrigin[iOwner])
					npc_Move(iCentaurEnt, 200.0)

					if(get_entvar(iCentaurEnt, var_sequence) != 2)
					{
						set_entvar(iCentaurEnt, var_animtime, 0.0)
						set_entvar(iCentaurEnt, var_frame, 0.0)
						set_entvar(iCentaurEnt, var_sequence, 2)
					}
					set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.1)
				}
			}
		}
		case NPC_ACTION_CIRCLE:
		{
			if (iTargetEnt && get_distance_f(vOrigin, vTargetOrigin) <= CENTAUR_ATTACK_RANGE)
			{
				npc_TurnToTarget(iCentaurEnt, vOrigin, vTargetOrigin)

				set_entvar(iCentaurEnt, var_npctarget, iTargetEnt)
				set_entvar(iCentaurEnt, var_animtime, fGameTime)
				set_entvar(iCentaurEnt, var_frame, 0.0)
				set_entvar(iCentaurEnt, var_sequence, random_num(2, 3))
				set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.3)

				engfunc(EngFunc_EmitSound, iCentaurEnt, CHAN_AUTO,
					SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			else
			{
				new iZombieIndex = 0, iZombiesCount = 0, iFoundZombie = FM_NULLENT;
				while ((iFoundZombie = find_zombie_by_owner(iFoundZombie, iOwner)))
				{
					iZombiesCount++
					if (iFoundZombie <= iCentaurEnt)
						iZombieIndex++
				}

				new Float:fYawAngle = iZombieIndex / float(iZombiesCount) * 360.0 + Player[iOwner][PlrNpcActionYaw];
				if(fYawAngle > 360.0) fYawAngle -= 360.0;

				new Float:vZombieCirclePosition[3]
				vZombieCirclePosition[0] = g_vTargetOrigin[iOwner][0] + floatcos(fYawAngle, degrees) * ACTION_CIRCLE_RADIUS
				vZombieCirclePosition[1] = g_vTargetOrigin[iOwner][1] + floatsin(fYawAngle, degrees) * ACTION_CIRCLE_RADIUS
				vZombieCirclePosition[2] = g_vTargetOrigin[iOwner][2]

				if (get_distance_f(vOrigin, vZombieCirclePosition) <= 60.0)
				{
					zombie_play_idle(iCentaurEnt)
				}
				else
				{
					npc_TurnToTarget(iCentaurEnt, vOrigin, vZombieCirclePosition)
					npc_Move(iCentaurEnt, 200.0)

					if(get_entvar(iCentaurEnt, var_sequence) != 1)
					{
						set_entvar(iCentaurEnt, var_animtime, 0.0)
						set_entvar(iCentaurEnt, var_frame, 0.0)
						set_entvar(iCentaurEnt, var_sequence, 1)
					}
					set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.1)
				}
			}
		}
		case NPC_ACTION_FOLLOW, NPC_ACTION_TARGET:
		{
			if (iTargetEnt && get_distance_f(vOrigin, vTargetOrigin) <= CENTAUR_ATTACK_RANGE)
			{
				npc_TurnToTarget(iCentaurEnt, vOrigin, vTargetOrigin)

				set_entvar(iCentaurEnt, var_npctarget, iTargetEnt)
				set_entvar(iCentaurEnt, var_animtime, fGameTime)
				set_entvar(iCentaurEnt, var_frame, 0.0)
				set_entvar(iCentaurEnt, var_sequence, random_num(3, 4))
				set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.3)

				engfunc(EngFunc_EmitSound, iCentaurEnt, CHAN_AUTO,
					SOUNDS_ZOMBIE_ATTACK[random(sizeof SOUNDS_ZOMBIE_ATTACK)], 1.0, ATTN_NORM, 0, PITCH_LOW)
			}
			else
			{
				if (iNpcAction == NPC_ACTION_TARGET)
				{
					new iTarget = Player[iOwner][PlrNpcActionTarget]
					if (kc_player_get_visibility(iTarget) < VIS_TRANS)
						get_entvar(iTarget, var_origin, vTargetOrigin)
					else if (!iTargetEnt)
						zombie_play_idle(iCentaurEnt)
				}
				else
					get_entvar(iOwner, var_origin, vTargetOrigin)

				if (get_distance_f(vOrigin, vTargetOrigin) <= 60.0)
				{
					zombie_play_idle(iCentaurEnt)
				}
				else
				{
					npc_TurnToTarget(iCentaurEnt, vOrigin, vTargetOrigin)
					npc_Move(iCentaurEnt, 200.0)

					if(get_entvar(iCentaurEnt, var_sequence) != 2)
					{
						set_entvar(iCentaurEnt, var_animtime, 0.0)
						set_entvar(iCentaurEnt, var_frame, 0.0)
						set_entvar(iCentaurEnt, var_sequence, 2)
					}
					set_entvar(iCentaurEnt, var_nextthink, fGameTime + 0.1)
				}
			}
		}
	}
}

public npc_TakeDamage(iZombieEnt, iInflictor, iAttacker, Float:fDamage)
{
	if (get_entvar(iZombieEnt, var_impulse) != IMPULSE_ZOMBIE)
		return HAM_IGNORED

	if (get_entvar(iZombieEnt, var_flags) & FL_KILLME)
		return HAM_IGNORED

	new iOwner = get_entvar(iZombieEnt, var_npcowner)
	new Float:fGameTime = get_gametime()

	if (is_entity_player(iAttacker) && Player[iOwner][PlrTeam] == Player[iAttacker][PlrTeam] && iOwner != iAttacker)
	{
		if (Float:get_entvar(iZombieEnt, var_npcspawntime) + NPC_TEAMMATE_DAMAGE_TIME < fGameTime)
			return HAM_SUPERCEDE
	}

	new Float:vOrigin[3]
	new Float:fHealth = Float:get_entvar(iZombieEnt, var_health)
	get_entvar(iZombieEnt, var_origin, vOrigin)

	if (fDamage < fHealth)
	{
		engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
			SOUNDS_ZOMBIE_PAIN[random(sizeof SOUNDS_ZOMBIE_PAIN)],
			1.0, ATTN_NORM, 0, !get_entvar(iZombieEnt, var_npctype) ? PITCH_NORM : PITCH_LOW)

		send_msg_TE_BLOODSPRITE(vOrigin, g_pBloodSpraySpr, g_pBloodSpr, 70, 5)
	}
	else
	{
		g_iZombieTeamCount[Player[iOwner][PlrTeam] - 1]--

		engfunc(EngFunc_EmitSound, iZombieEnt, CHAN_AUTO,
			SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		create_gore(vOrigin)

		set_entvar(iZombieEnt, var_solid, SOLID_NOT)
		set_entvar(iZombieEnt, var_health, 0.0)
		set_entvar(iZombieEnt, var_flags, FL_KILLME)
		set_entvar(iZombieEnt, var_nextthink, fGameTime)

		if (Player[iOwner][PlrNpcAction] != NPC_ACTION_NONE)
		{
			new iZombiesNum = 0, iEnt = NULLENT
			while ((iEnt = find_zombie_by_owner(iEnt, iOwner)))
				iZombiesNum++

			if (iZombiesNum == 1)
				Player[iOwner][PlrNpcAction] = NPC_ACTION_NONE
		}
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

zombie_play_idle(iZombieEnt, Float:fNextThink=0.1)
{
	if (get_entvar(iZombieEnt, var_sequence) != 0)
	{
		set_entvar(iZombieEnt, var_animtime, 0.0)
		set_entvar(iZombieEnt, var_frame, 0.0)
		set_entvar(iZombieEnt, var_sequence, 0)
	}
	set_entvar(iZombieEnt, var_nextthink, get_gametime() + fNextThink)
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

	fRadians = floatatan(z / x, radian)
	vAngles[1] = fRadians * (180.0 / 3.14)

	if (vOrigin[0] > vTargetOrigin[0])
		vAngles[1] -= 180.0

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

create_zombie(Float:vOrigin[3], Float:vAngles[3], iOwner)
{
	new iTeam = Player[iOwner][PlrTeam]

	if (g_iZombieTeamCount[iTeam - 1] >= MAX_ZOMBIES)
		return NULLENT

	new iZombieEnt = rg_create_entity(SZ_EXPLOSION)
	if (is_nullent(iZombieEnt))
		return NULLENT

	engfunc(EngFunc_SetOrigin, iZombieEnt, vOrigin)
	engfunc(EngFunc_SetModel, iZombieEnt, MODEL_ZOMBIE)
	engfunc(EngFunc_SetSize, iZombieEnt, Float:{-18.0, -18.0, 0.0}, Float:{18.0, 18.0, 20.0})

	set_entvar(iZombieEnt, var_origin, vOrigin)
	set_entvar(iZombieEnt, var_angles, vAngles)

	set_entvar(iZombieEnt, var_flags, FL_MONSTER)
	set_entvar(iZombieEnt, var_solid, SOLID_BBOX)
	set_entvar(iZombieEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iZombieEnt, var_skin, iTeam - 1)
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

	SetThink(iZombieEnt, "zombie_think")

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

	g_iZombieTeamCount[iTeam - 1]++

	if (Player[iOwner][PlrNpcAction] == NPC_ACTION_NONE)
		Player[iOwner][PlrNpcAction] = NPC_ACTION_HUNTER

	return iZombieEnt
}

create_centaur(Float:vOrigin[3], Float:vAngles[3], Float:fHealth, iOwner)
{
	new iCentaurEnt = rg_create_entity(SZ_EXPLOSION)
	if (is_nullent(iCentaurEnt))
		return NULLENT

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
	set_entvar(iCentaurEnt, var_health, fHealth + CENTAUR_HEALTH)

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

	SetThink(iCentaurEnt, "centaur_think")

	g_iZombieTeamCount[iTeam - 1]++

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

kill_all_npc(iOwner)
{
	Player[iOwner][PlrNpcAction] = NPC_ACTION_NONE
	new iZombieEnt = NULLENT
	while ((iZombieEnt = find_zombie_by_owner(iZombieEnt, iOwner)))
		ExecuteHamB(Ham_TakeDamage, iZombieEnt, 0, iZombieEnt, 9000.0, DMG_BLAST)
}

bool:is_user_can_lead_zombies(iPlayer)
{
	return bool:(!kc_player_in_silence(iPlayer)
		&& !kc_player_in_darkness(iPlayer)
		&& kc_player_get_vision(iPlayer) != VISION_BLIND)
}

get_user_max_zombies_to_spawn(iPlayer)
{
	return min(MAX_ZOMBIES - g_iZombieTeamCount[Player[iPlayer][PlrTeam] - 1], ABIL_ZOMBIES_PER_USE)
}

bool:is_user_can_spawn_zombies(iPlayer)
{
	new iZombiesToSpawn = get_user_max_zombies_to_spawn(iPlayer)

	if (iZombiesToSpawn == 0)
		return false

	new Array:aPositions = get_user_zombies_spawn_positions(iPlayer, iZombiesToSpawn)
	for(new i, Float:vPos[3]; i < ArraySize(aPositions); i++)
	{
		ArrayGetArray(aPositions, i, vPos)
		vPos[2] += 30.0

		if (!is_hull_vacant(vPos, HULL_LARGE, 0))
		{
			ArrayDestroy(aPositions)
			return false
		}
	}

	ArrayDestroy(aPositions)
	return true
}

Array:get_user_zombies_spawn_positions(iPlayer, iZombiesNum)
{
	new Array:aPositions = ArrayCreate(3), Float:vAimOrigin[3]
	rg_get_aim_origin(iPlayer, vAimOrigin)
	vAimOrigin[2] += 5.0

	switch (iZombiesNum)
	{
		case 1:
		{
			ArrayPushArray(aPositions, vAimOrigin)
		}
		case 2, 3, 4, 5:
		{
			new Float:vAngles[3]; get_entvar(iPlayer, var_v_angle, vAngles)
			vAngles[1] += 90.0
			new Float:fFixedYaw = vAngles[1] < 0.0 ? 360.0 + vAngles[1] : vAngles[1]

			for(new i = 0, Float:vAngle, Float:vPos[3]; i < iZombiesNum; i++) {
				vAngle = i / float(iZombiesNum) * 360.0 + fFixedYaw
				if (vAngle > 360.0)
					vAngle -= 360.0

				vPos[0] = vAimOrigin[0] + floatcos(vAngle, degrees) * 40.0
				vPos[1] = vAimOrigin[1] + floatsin(vAngle, degrees) * 40.0
				vPos[2] = vAimOrigin[2]

				ArrayPushArray(aPositions, vPos)
			}
		}
	}

	return aPositions
}

bool:try_apply_cannibalism(iOwner)
{
	new iZombiesNum, iZombieEnt = NULLENT

	while ((iZombieEnt = find_zombie_by_owner(iZombieEnt, iOwner)))
	{
		if (get_entvar(iZombieEnt, var_npctype) != 0)
			continue

		iZombiesNum++

		if (iZombiesNum >= 2)
		{
			Player[iOwner][PlrNpcAction] = NPC_ACTION_CANNIBAL
			return true
		}
	}

	return false
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

	new Float:vVec[3]
	for (new i; i < sizeof fUnstuckSize; i++)
	{
		vVec[0] = vOrigin[0] + vZmbMaxs[0] * fUnstuckSize[i][0]
		vVec[1] = vOrigin[1] + vZmbMaxs[1] * fUnstuckSize[i][1]
		vVec[2] = vOrigin[2] + vZmbMaxs[2] * fUnstuckSize[i][2]

		xs_vec_add(vZmbMins, vVec, vMins[0])
		xs_vec_add(vZmbMaxs, vVec, vMaxs[0])

		if (!boxes_intersect(vMins[0], vMaxs[0], vMins[1], vMaxs[1]))
		{
			engfunc(EngFunc_SetOrigin, zmb, vVec)
			set_entvar(zmb, var_origin, vVec)
			break
		}
	}
}

find_zombie_by_owner(iEnt, iOwner)
{
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_ZOMBIE)) && get_entvar(iEnt, var_npcowner) != iOwner) {}
	return iEnt
}

find_closes_target(iTeam, Float:vOrigin[3], Float:vTargetOrigin[3], bool:bIgnoreCorpses=false)
{
	new Float:fMaxDist = 4000.0
	new iTarget = 0

	static iEnt, Float:fDist

	for (iEnt = 1; iEnt <= MaxClients; iEnt++)
	{
		if (!Player[iEnt][PlrIsAlive])
			continue

		if (iTeam == Player[iEnt][PlrTeam] && kc_player_get_capture(iEnt) != CAPTURE_NORMAL)
			continue

		if (kc_player_get_visibility(iEnt) >= VIS_TRANS)
			continue

		get_entvar(iEnt, var_origin, vTargetOrigin)
		fDist = get_distance_f(vOrigin, vTargetOrigin)
		if (fDist <= fMaxDist)
		{
			fMaxDist = fDist
			iTarget = iEnt
		}
	}

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_ZOMBIE)))
	{
		if (get_entvar(iEnt, var_skin) + 1 != iTeam)
		{
			get_entvar(iEnt, var_origin, vTargetOrigin)
			fDist = get_distance_f(vOrigin, vTargetOrigin)
			if (fDist <= fMaxDist)
			{
				fMaxDist = fDist
				iTarget = iEnt
			}
		}
	}

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_FAKEPLAYER)))
	{
		if (iTeam == get_entvar(iEnt, var_team))
			continue

		get_entvar(iEnt, var_origin, vTargetOrigin)
		fDist = get_distance_f(vOrigin, vTargetOrigin)
		if (fDist <= fMaxDist)
		{
			fMaxDist = fDist
			iTarget = iEnt
		}
	}

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_PRESENT)))
	{
		get_entvar(iEnt, var_origin, vTargetOrigin)
		fDist = get_distance_f(vOrigin, vTargetOrigin)
		if (fDist <= fMaxDist)
		{
			fMaxDist = fDist
			iTarget = iEnt
		}
	}

	if (!bIgnoreCorpses)
	{
		iEnt = NULLENT
		while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_CORPSE)))
		{
			get_entvar(iEnt, var_origin, vTargetOrigin)
			fDist = get_distance_f(vOrigin, vTargetOrigin)
			if (fDist <= fMaxDist)
			{
				fMaxDist = fDist
				iTarget = iEnt
			}
		}
	}

	get_entvar(iTarget, var_origin, vTargetOrigin)
	return iTarget
}

clear_npc_action_target(iTarget)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrKnife] != g_iKnifeId)
			continue

		if (Player[i][PlrNpcAction] != NPC_ACTION_TARGET)
			continue

		if (Player[i][PlrNpcActionTarget] == iTarget)
		{
			Player[i][PlrNpcAction] = NPC_ACTION_HUNTER
			Player[i][PlrNpcActionTarget] = 0
		}
	}
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

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)
}
