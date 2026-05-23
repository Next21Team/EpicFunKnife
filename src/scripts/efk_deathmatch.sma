#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Deathmatch"

new const GAME_TAG[] = EFK_GAME_TAG

new const MODEL_ZONE[] = "models/next21_efk/zone_b01.mdl"
#define ZONE_RADIUS 		2560.0
#define ZONE_DAMAGE 		4.0

new const SOUND_ZONE_START[] = "sound/next21_efk/zone_start_b01.wav"
new const SOUND_GAME_MODE1[] = "sound/next21_efk/game_mode_1b01.wav"

#define ENDROUND_RESPAWN_TIME 		30.0
#define RESPAWN_TIME 				8.0
#define RESPAWN_COST 				10000

#define RESPAWN_MESSAGE_START_TIME	4.5

#define TASK_ROUND_GAME 		1210
#define TASK_CHECK_ZONE 		1310
#define TASK_ZONE_SCREENFADE 	1410
#define TASK_DHUD_MESSAGE 		1510

enum
{
    GAME_MODE_DEFAULT = 0,
	GAME_MODE_RANDOM_KNIFE,
	GAME_MODE_ONE_LIFE
}

enum
{
    ROUND_START_NONE = 0,
	ROUND_START_PRE,
	ROUND_START_POST
}

new forward_death_zone_started

//>0 - CT WIN, <0 - T WIN
new g_iBalance

new bool:g_bConnected[MAX_PLAYERS + 1]
new bool:g_bAuthorized[MAX_PLAYERS + 1]
new Float:g_fRespawnTime[MAX_PLAYERS + 1]
new bool:g_bDoRevive[MAX_PLAYERS + 1]
new g_iRoundStart, g_iWinTeam
new Float:g_fRespawnMessageTime[MAX_PLAYERS + 1]
new g_bWasRespawned[MAX_PLAYERS + 1]
new bool:g_bRespawnCompensation[MAX_PLAYERS + 1]

new g_iGameMode, g_iRoundNum
new Trie:g_pUids, g_szUid[32]
new Array:g_aAvailableRandomKnives
new g_iLastSelectedKnifeId[MAX_PLAYERS + 1]

new g_iZoneEnt
new Float:g_vZoneOrigin[3]
new Float:g_fZoneStartTime
new g_iOldZvmax


public plugin_precache()
{
	precache_model(MODEL_ZONE)
	precache_generic(SOUND_ZONE_START)
	precache_generic(SOUND_GAME_MODE1)
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	kc_register_item("ITEM_RESPAWN", "BUY_RESPAWN", "efk_give_item", RESPAWN_COST)

	register_event("HLTV", "event_round_new", "a", "1=0", "2=0")
	register_logevent("event_round_start", 2, "1=Round_Start")

	register_event("SendAudio", "event_round_end", "a", "2&%!MRAD_terwin")
	register_event("SendAudio", "event_round_end", "a", "2&%!MRAD_ctwin")
	register_event("SendAudio", "event_round_end", "a", "2&%!MRAD_rounddraw")

	register_event("TextMsg", "event_round_restart", "a", "2&#Game_C", "2&#Game_w")

	register_message(get_user_msgid("TeamInfo"), "fw_TeamInfo")
	register_message(get_user_msgid("RoundTime"), "fw_RoundTime")

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_PostThink, "RG_CBasePlayer_PostThink_Post", true)
	RegisterHam(Ham_TakeHealth, "player", "fw_PlayerTakeHealth_Pre")

	register_clcmd("say /score", "clcmd_score")
	register_clcmd("say_team /score", "clcmd_score")

	forward_death_zone_started = CreateMultiForward("efk_death_zone_started", ET_IGNORE, FP_CELL)

	g_pUids = TrieCreate()
	g_aAvailableRandomKnives = ArrayCreate()
}

public client_putinserver(iPlayer)
{
	g_bDoRevive[iPlayer] = false
	g_bConnected[iPlayer] = true

	if (g_bAuthorized[iPlayer])
	{
		g_iLastSelectedKnifeId[iPlayer] = -1
		give_saved_random_knife(iPlayer)
	}
}

public client_authorized(iPlayer)
{
	g_bAuthorized[iPlayer] = true

	if (g_bConnected[iPlayer])
	{
		g_iLastSelectedKnifeId[iPlayer] = -1
		give_saved_random_knife(iPlayer)
	}
}

public client_disconnected(iPlayer)
{
	g_bConnected[iPlayer] = false
	g_bAuthorized[iPlayer] = false
	g_bDoRevive[iPlayer] = false
	remove_task(TASK_CHECK_ZONE + iPlayer)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		remove_task(TASK_CHECK_ZONE + iPlayer)
		if (g_iZoneEnt)
			set_task(0.5, "task_check_zone", TASK_CHECK_ZONE + iPlayer, _, _, "b")

		if (g_iGameMode == GAME_MODE_DEFAULT)
			set_task(1.5, "task_show_promt_message", iPlayer + TASK_DHUD_MESSAGE)
	}
}

//Events
public event_round_new()
{
	g_iRoundNum++

	if (g_iRoundNum % 8 == 0)
	{
		client_cmd(0, "spk %s", SOUND_GAME_MODE1[6])
		g_iGameMode = GAME_MODE_ONE_LIFE
		set_task(0.5, "show_gamemode", TASK_DHUD_MESSAGE)
	}
	else if (g_iRoundNum % 4 == 0)
	{
		ArrayClear(g_aAvailableRandomKnives)
		new iKnivesNum = kc_get_knives_num()
		for (new iKnifeId; iKnifeId < iKnivesNum; iKnifeId++)
			ArrayPushCell(g_aAvailableRandomKnives, iKnifeId)

		TrieClear(g_pUids)
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!g_bConnected[i])
				continue

			g_iLastSelectedKnifeId[i] = kc_player_get_knife(i)
			give_random_knife(i)
		}
		client_cmd(0, "spk %s", SOUND_GAME_MODE1[6])
		g_iGameMode = GAME_MODE_RANDOM_KNIFE
		set_task(0.5, "show_gamemode", TASK_DHUD_MESSAGE)
	}
	else
	{
		new iPrevGameMode = g_iGameMode
		g_iGameMode = GAME_MODE_DEFAULT

		if (iPrevGameMode == GAME_MODE_RANDOM_KNIFE)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!g_bConnected[i] || g_iLastSelectedKnifeId[i] < 0)
					continue

				kc_player_give_knife(i, g_iLastSelectedKnifeId[i], false)
			}
		}
	}
}

public task_show_promt_message(iTaskId)
{
	new iPlayer = iTaskId - TASK_DHUD_MESSAGE
	if (is_user_alive(iPlayer))
	{
		set_dhudmessage(11, 218, 81, -1.0, 0.70, 0, 1.0, 4.0, 0.1, 2.0)
		show_dhudmessage(iPlayer, "%L", iPlayer, "DHUD_BUY")
	}
}

public show_gamemode(iTaskId)
{
	switch (g_iGameMode)
	{
		case GAME_MODE_RANDOM_KNIFE:
		{
			set_dhudmessage(255, 255, 255, -1.0, 0.3, 0, 1.0, 4.0, 0.1, 2.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "DHUD_GM_RANDOM_KNIFE")
		}
		case GAME_MODE_ONE_LIFE:
		{
			set_dhudmessage(255, 255, 255, -1.0, 0.3, 0, 1.0, 4.0, 0.1, 2.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "DHUD_GM_ONE_LIFE")
		}
	}
}

public event_round_start()
{
	g_iBalance = 0
	g_iRoundStart = ROUND_START_PRE
	g_iWinTeam = -1
	arrayset(g_bWasRespawned, false, sizeof g_bWasRespawned)
	remove_zone()
	ExecuteForward(forward_death_zone_started, _, -1)
}

public event_round_restart()
{
	remove_task(TASK_ROUND_GAME)
	remove_zone()
}

public event_round_end()
{
	remove_task(TASK_ROUND_GAME)
	force_round_end()
	remove_zone()
	arrayset(g_bDoRevive, false, sizeof g_bDoRevive)

	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bRespawnCompensation[i] && kc_player_is_influenced(i))
		{
			client_print_color(i, print_team_red, "^4[%s] ^3%L", GAME_TAG, i, "RESPAWN_COMPENSATION")
			rg_add_account(i, RESPAWN_COST)
		}
	}

	arrayset(g_bRespawnCompensation, false, sizeof g_bRespawnCompensation)
}

force_round_end()
{
	if (!g_iBalance || g_iGameMode == GAME_MODE_ONE_LIFE)
	{
		arrayset(g_bDoRevive, false, sizeof g_bDoRevive)
		g_iWinTeam = 0
	}
	else
	{
		g_iWinTeam = g_iBalance > 0 ? 2 : 1

		for (new i = 1; i <= MaxClients; i++)
		{
			if (!g_bConnected[i])
				continue

			if (g_iBalance > 0)
			{
				if (get_member(i, m_iTeam) == TEAM_TERRORIST)
					g_bDoRevive[i] = false
			}
			else
			{
				if (get_member(i, m_iTeam) == TEAM_CT)
					g_bDoRevive[i] = false
			}
		}
	}

	g_iBalance = 0
	g_iRoundStart = ROUND_START_NONE
	ExecuteForward(forward_death_zone_started, _, g_iWinTeam)
}

public force_round_end_task()
{
	force_round_end()
	create_zone()
}

public fw_TeamInfo()
{
	new team[2], id = get_msg_arg_int(1)

	if (!g_bConnected[id])
		return

	if (get_member(id, m_iJoiningState) != JOINED)
		return

	get_msg_arg_string(2, team, 1)

	if (g_iGameMode != GAME_MODE_ONE_LIFE && g_iWinTeam == -1 && !is_user_alive(id))
	{
		if ((team[0] == 'T' || team[0] == 'C') && g_fRespawnTime[id] < get_gametime())
		{
			g_bDoRevive[id] = true
			g_fRespawnTime[id] = get_gametime() + RESPAWN_TIME
		}
	}
}

public fw_RoundTime()
{
	if (g_iRoundStart != ROUND_START_PRE)
		return

	g_iRoundStart = ROUND_START_POST
	set_task(float(get_msg_arg_int(1)), "force_round_end_task", TASK_ROUND_GAME)
}

public RG_CBasePlayer_PostThink_Post(iPlayer)
{
	if (!g_bDoRevive[iPlayer])
		return HC_CONTINUE

	new iTeam = get_member(iPlayer, m_iTeam)
	if (is_user_alive(iPlayer) || !iTeam || iTeam > 2)
	{
		g_bDoRevive[iPlayer] = false
		return HC_CONTINUE
	}

	new Float:fGameTime = get_gametime()
	if (g_fRespawnTime[iPlayer] <= fGameTime)
	{
		g_bDoRevive[iPlayer] = false
		ExecuteHamB(Ham_CS_RoundRespawn, iPlayer)
	}
	else
	{
		static szMessage[256]
		if (g_fRespawnMessageTime[iPlayer] < fGameTime)
		{
			g_fRespawnMessageTime[iPlayer] = fGameTime + 0.5

			format(szMessage, charsmax(szMessage), "%L", iPlayer, "DEATHMATCH_SPAWNTIME", floatround(g_fRespawnTime[iPlayer] - fGameTime))

			if (g_iBalance && g_iWinTeam == -1)
			{
				if ((g_iBalance > 0 && iTeam == 2) || (g_iBalance < 0 && iTeam == 1))
					format(szMessage, charsmax(szMessage), "%s^n%L", szMessage, iPlayer, "DEATHMATCH_WIN", abs(g_iBalance))
				else
					format(szMessage, charsmax(szMessage), "%s^n%L", szMessage, iPlayer, "DEATHMATCH_LOSE", abs(g_iBalance))
			}

			set_dhudmessage(0, 100, 215, -1.0, 0.2, .holdtime=0.6)
			show_dhudmessage(iPlayer, szMessage)
		}
	}
	return HC_CONTINUE
}

public fw_PlayerTakeHealth_Pre(iPlayer, Float:fHelath, iFlags)
{
	if (get_member(iPlayer, m_iTeam) == g_iWinTeam)
		return HAM_IGNORED

	if (g_iZoneEnt && (iFlags == DMG_GENERIC || is_user_inzone(iPlayer)))
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public clcmd_score(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return PLUGIN_HANDLED

	if (g_iWinTeam > -1 || g_iGameMode == GAME_MODE_ONE_LIFE)
		return PLUGIN_HANDLED

	if (!g_iBalance)
	{
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "DM_CHAT_COMMON_DEF_SCORE")
		return PLUGIN_HANDLED
	}

	new TeamName:iTeam = get_member(iPlayer, m_iTeam)
	new iScore = abs(g_iBalance)

	if (iTeam == TEAM_UNASSIGNED || iTeam == TEAM_SPECTATOR)
	{
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG,
			iPlayer, g_iBalance < 0 ? "DM_CHAT_COMMON_TE_SCORE" : "DM_CHAT_COMMON_CT_SCORE", iScore)

		return PLUGIN_HANDLED
	}

	if ((g_iBalance < 0 && iTeam == TEAM_TERRORIST) || (g_iBalance > 0 && iTeam == TEAM_CT))
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "DEATHMATCH_WIN", iScore)
	else
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "DEATHMATCH_LOSE", iScore)

	return PLUGIN_HANDLED
}

public efk_player_death(iVictim, iAttacker, iAssistant)
{
	if (g_iGameMode != GAME_MODE_ONE_LIFE)
	{
		new iTeam = get_member(iVictim, m_iTeam)
		new Float:fGameTime = get_gametime()

		if (g_iWinTeam == -1)
		{
			g_bDoRevive[iVictim] = true
			g_fRespawnTime[iVictim] = fGameTime + RESPAWN_TIME

			new Float:fNextSuicideTime = get_member(iVictim, m_fNextSuicideTime)
			if (fGameTime - fNextSuicideTime <= 1.0)
				g_fRespawnTime[iVictim] += RESPAWN_TIME

			if (iAttacker && iAttacker != iVictim && g_bConnected[iVictim] && g_bConnected[iAttacker])
			{
				if (iTeam == 1)
					g_iBalance++
				else if (iTeam == 2)
					g_iBalance--
			}
		}
		else if (g_iWinTeam == iTeam)
		{
			g_bDoRevive[iVictim] = true
			g_fRespawnTime[iVictim] = fGameTime + ENDROUND_RESPAWN_TIME
		}

		g_fRespawnMessageTime[iVictim] = fGameTime + RESPAWN_MESSAGE_START_TIME
	}

	remove_task(TASK_CHECK_ZONE + iVictim)
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (g_iGameMode != GAME_MODE_ONE_LIFE && g_iWinTeam == -1)
		return ITEM_NOT_AVAILABLE

	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		new iTeam = get_member(iPlayer, m_iTeam)
		if (!iTeam || iTeam > 2 || g_iWinTeam == iTeam)
			return ITEM_NOT_AVAILABLE

		new iTargetsNum, iTargets[MAX_PLAYERS]
		for (new i = 1, iPlayerTeam; i <= MaxClients; i++)
		{
			if (!g_bConnected[i] || is_user_alive(i))
				continue

			if (g_bWasRespawned[i])
				continue

			iPlayerTeam = get_member(i, m_iTeam)
			if (iTeam == iPlayerTeam)
				iTargets[iTargetsNum++] = i
		}

		if (!iTargetsNum)
			return ITEM_NOT_AVAILABLE

		new iTarget = iTargets[random(iTargetsNum)]
		ExecuteHamB(Ham_CS_RoundRespawn, iTarget)
		g_bWasRespawned[iTarget] = true

		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "PRESENT_RESPAWN")
	}
	else
	{
		if (is_user_alive(iPlayer))
			return ITEM_ALIVE

		if (g_bWasRespawned[iPlayer])
			return ITEM_NOT_AVAILABLE

		new iTeam = get_member(iPlayer, m_iTeam)
		if (!iTeam || iTeam > 2 || g_iWinTeam == iTeam)
			return ITEM_NOT_AVAILABLE

		ExecuteHamB(Ham_CS_RoundRespawn, iPlayer)
		g_bWasRespawned[iPlayer] = true
		g_bRespawnCompensation[iPlayer] = true
	}

	return ITEM_OK
}

public efk_change_knife_core_pre(iPlayer, iKnifeId)
{
	if (g_iGameMode != GAME_MODE_RANDOM_KNIFE)
		return PLUGIN_CONTINUE

	if (kc_player_get_knife(iPlayer) < 0)
		return PLUGIN_CONTINUE

	get_user_authid(iPlayer, g_szUid, charsmax(g_szUid))
	if (TrieKeyExists(g_pUids, g_szUid))
	{
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "KNIFE_CHANGE_GM")
		g_iLastSelectedKnifeId[iPlayer] = iKnifeId
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

create_zone()
{
	remove_zone()

	new iPlrNum, aPlayers[MAX_PLAYERS]
	get_players(aPlayers, iPlrNum, "ah")

	if (!iPlrNum)
		return

	new iZoneEnt = rg_create_entity("info_target", true)
	if (!is_nullent(iZoneEnt))
	{
		new Float:vOrigin[3], Float:fGameTime
		fGameTime = get_gametime()

		new Array:aOriginsX = ArrayCreate()
		new Array:aOriginsY = ArrayCreate()
		new Array:aOriginsZ = ArrayCreate()

		for (new i; i < iPlrNum; i++)
		{
			get_entvar(aPlayers[i], var_origin, vOrigin)
			ArrayPushCell(aOriginsX, vOrigin[0])
			ArrayPushCell(aOriginsY, vOrigin[1])
			ArrayPushCell(aOriginsZ, vOrigin[2])
		}

		ArraySortEx(aOriginsX, "sort_float")
		ArraySortEx(aOriginsY, "sort_float")
		ArraySortEx(aOriginsZ, "sort_float")

		vOrigin[0] = ArrayGetCell(aOriginsX, iPlrNum / 2)
		vOrigin[1] = ArrayGetCell(aOriginsY, iPlrNum / 2)
		vOrigin[2] = ArrayGetCell(aOriginsZ, iPlrNum / 2)

		if (iPlrNum % 2  == 0)
		{
			new Float:vSupOrigin[3]
			vSupOrigin[0] = ArrayGetCell(aOriginsX, iPlrNum / 2 - 1)
			vSupOrigin[1] = ArrayGetCell(aOriginsY, iPlrNum / 2 - 1)
			vSupOrigin[2] = ArrayGetCell(aOriginsZ, iPlrNum / 2 - 1)

			vOrigin[0] = (vOrigin[0] + vSupOrigin[0]) / 2.0
			vOrigin[1] = (vOrigin[1] + vSupOrigin[1]) / 2.0
			vOrigin[2] = (vOrigin[2] + vSupOrigin[2]) / 2.0
		}

		ArrayDestroy(aOriginsX)
		ArrayDestroy(aOriginsY)
		ArrayDestroy(aOriginsZ)

		engfunc(EngFunc_SetModel, iZoneEnt, MODEL_ZONE)
		engfunc(EngFunc_SetOrigin, iZoneEnt, vOrigin)
		engfunc(EngFunc_SetSize, iZoneEnt, { -ZONE_RADIUS, -ZONE_RADIUS, -ZONE_RADIUS },
			{ ZONE_RADIUS,  ZONE_RADIUS,  ZONE_RADIUS } )

		set_entvar(iZoneEnt, var_origin, vOrigin)
		set_entvar(iZoneEnt, var_solid, SOLID_NOT)
		set_entvar(iZoneEnt, var_movetype, MOVETYPE_NONE)

		set_entvar(iZoneEnt, var_skin, g_iWinTeam)

		set_entvar(iZoneEnt, var_sequence, 0)
		set_entvar(iZoneEnt, var_framerate, 0.25)
		set_entvar(iZoneEnt, var_animtime, fGameTime)

		set_entvar(iZoneEnt, var_rendermode, kRenderTransAdd)
		set_entvar(iZoneEnt, var_renderamt, 0.0)

		set_entvar(iZoneEnt, var_nextthink, fGameTime + 0.05)

		SetThink(iZoneEnt, "zone_fade_in")

		g_iZoneEnt = iZoneEnt
		g_vZoneOrigin[0] = vOrigin[0]
		g_vZoneOrigin[1] = vOrigin[1]
		g_vZoneOrigin[2] = vOrigin[2]
		g_fZoneStartTime = fGameTime

		if (g_iWinTeam == 1)
			get_players(aPlayers, iPlrNum, "aeh", "CT")
		else if (g_iWinTeam == 2)
			get_players(aPlayers, iPlrNum, "aeh", "TERRORIST")
		else
			get_players(aPlayers, iPlrNum, "ah")

		for (new i; i < iPlrNum; i++)
			set_task(0.5, "task_check_zone", TASK_CHECK_ZONE + aPlayers[i], _, _, "b")

		client_print(0, print_center, "%L", LANG_PLAYER, "ZONE_START")
		client_cmd(0, "spk %s", SOUND_ZONE_START[6])

		g_iOldZvmax = get_cvar_num("sv_zmax")
		if (g_iOldZvmax < 8192)
			set_cvar_num("sv_zmax", 8192)
	}
}

remove_zone()
{
	if (g_iZoneEnt)
	{
		SetThink(g_iZoneEnt, "zone_fade_out")
		set_entvar(g_iZoneEnt, var_nextthink, get_gametime() + 0.05)
		g_iZoneEnt = 0
		set_cvar_num("sv_zmax", g_iOldZvmax)
	}

	for (new i = 1; i <= MaxClients; i++)
		remove_task(TASK_CHECK_ZONE + i)
}

public zone_fade_in(iEnt)
{
	new Float:fAmt = get_entvar(iEnt, var_renderamt)
	if (fAmt >= 255.0)
		return

	fAmt = floatmin(fAmt + 2.0, 255.0)
	set_entvar(iEnt, var_renderamt, fAmt)
	set_entvar(iEnt, var_nextthink, get_gametime() + 0.05)
}

public zone_fade_out(iEnt)
{
	new Float:fAmt = get_entvar(iEnt, var_renderamt)
	if (fAmt <= 0.0)
	{
		rg_remove_entity(iEnt)
		return
	}

	fAmt = floatmax(fAmt - 5.0, 0.0)
	set_entvar(iEnt, var_renderamt, fAmt)
	set_entvar(iEnt, var_nextthink, get_gametime() + 0.05)
}

public task_check_zone(iTaskId)
{
	new iPlayer = iTaskId - TASK_CHECK_ZONE

	if (get_member(iPlayer, m_iTeam) == g_iWinTeam)
	{
		remove_task(iTaskId)
		return
	}

	if (is_user_inzone(iPlayer))
	{
		kc_player_unshadow(iPlayer, true)

		set_pdata_int(iPlayer, 75, HIT_GENERIC)
		new Float:fVelocityModifier = Float:get_member(iPlayer, m_flVelocityModifier)
		ExecuteHamB(Ham_TakeDamage, iPlayer, g_iZoneEnt, 0, ZONE_DAMAGE, DMG_SONIC | DMG_ALWAYSGIB)
		set_member(iPlayer, m_flVelocityModifier, fVelocityModifier)

		zone_set_screenfade(iPlayer)
	}
}

bool:is_user_inzone(iPlayer)
{
	new const Float:FRAME_RADIUS = ZONE_RADIUS / 29.0 * 0.25

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	vOrigin[0] -= g_vZoneOrigin[0]
	vOrigin[1] -= g_vZoneOrigin[1]

	new Float:fZoneRadius = floatmax(ZONE_RADIUS - (get_gametime() - g_fZoneStartTime) * FRAME_RADIUS, 0.0)
	return float_sqr(vOrigin[0]) + float_sqr(vOrigin[1]) > float_sqr(fZoneRadius)
}

zone_set_screenfade(iPlayer)
{
	if (kc_player_get_vision(iPlayer) == VISION_BLIND || kc_player_in_freeze(iPlayer) || kc_player_in_chill(iPlayer))
		return

	new iTaskId = TASK_ZONE_SCREENFADE + iPlayer

	if (task_exists(iTaskId))
		return

	send_msg_ScreenFade((1<<12), (1<<12), (1<<0), {255, 230, 45}, 50, MSG_ONE_UNRELIABLE, _, iPlayer)

	set_task(2.0, "zone_remove_screenfade", iTaskId)
}

public zone_remove_screenfade(iTaskId)
{
	new iPlayer = iTaskId - TASK_ZONE_SCREENFADE
	if (!is_user_connected(iPlayer))
		return

	if (kc_player_get_vision(iPlayer) == VISION_BLIND || kc_player_in_freeze(iPlayer) || kc_player_in_chill(iPlayer))
		return

	send_msg_ScreenFade((1<<12), (1<<8), (1<<1), {255, 230, 45}, 50, MSG_ONE, _, iPlayer)
}

give_saved_random_knife(iPlayer)
{
	if (g_iGameMode == GAME_MODE_RANDOM_KNIFE)
	{
		new iSavedKnifeId
		get_user_authid(iPlayer, g_szUid, charsmax(g_szUid))
		if (TrieGetCell(g_pUids, g_szUid, iSavedKnifeId))
			return kc_player_give_knife(iPlayer, iSavedKnifeId)

		return give_random_knife(iPlayer)
	}

	return -1
}

give_random_knife(iPlayer)
{
	new Array:aAvailableKnives = ArrayCreate()
	new iAvailableKnivesNum = ArraySize(g_aAvailableRandomKnives)
	for (new i, iKnifeId; i < iAvailableKnivesNum; i++)
	{
		iKnifeId = ArrayGetCell(g_aAvailableRandomKnives, i)
		if (kc_player_check_knife_access(iPlayer, iKnifeId))
			ArrayPushCell(aAvailableKnives, iKnifeId)
	}
	iAvailableKnivesNum = ArraySize(aAvailableKnives)

	if (iAvailableKnivesNum == 0)
	{
		new iKnivesNum = kc_get_knives_num()
		for (new iKnifeId; iKnifeId < iKnivesNum; iKnifeId++)
		{
			if (kc_player_check_knife_access(iPlayer, iKnifeId))
				ArrayPushCell(aAvailableKnives, iKnifeId)
		}
		iAvailableKnivesNum = ArraySize(aAvailableKnives)
	}

	new iKnifeId = ArrayGetCell(aAvailableKnives, random(iAvailableKnivesNum))
	ArrayDestroy(aAvailableKnives)

	new idx = ArrayFindValue(g_aAvailableRandomKnives, iKnifeId)
	if (idx > -1)
		ArrayDeleteItem(g_aAvailableRandomKnives, idx)

	iKnifeId = kc_player_give_knife(iPlayer, iKnifeId, false, false)
	if (iKnifeId < 0)
		return -1

	get_user_authid(iPlayer, g_szUid, charsmax(g_szUid))
	TrieSetCell(g_pUids, g_szUid, iKnifeId)
	return iKnifeId
}

public sort_float(Array:aArray, Float:fEl1, Float:fEl2)
{
	if (fEl1 > fEl2) return 1
	if (fEl1 < fEl2) return -1
	return 0
}
