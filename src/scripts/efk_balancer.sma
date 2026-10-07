#include <amxmodx>
#include <reapi>
#include <efk_statsx>
#include <efk_const>

new const PLUGIN[] = "EFK: Balancer"

new const GAME_TAG[] = EFK_GAME_TAG

#define TASK_ROUND_GAME 		1210


new bool:g_bUserConnected[MAX_PLAYERS + 1]
new TeamName:g_iUserNewTeam[MAX_PLAYERS + 1]
new bool:g_bIsRoundStart


public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	register_event("HLTV", "event_round_new", "a", "1=0", "2=0")
	register_logevent("event_round_start", 2, "1=Round_Start")

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Pre")
}

public client_putinserver(iPlayer)
{
	g_iUserNewTeam[iPlayer] = TEAM_UNASSIGNED
	g_bUserConnected[iPlayer] = true
}

public client_disconnected(iPlayer)
{
	g_iUserNewTeam[iPlayer] = TEAM_UNASSIGNED
	g_bUserConnected[iPlayer] = false
}

public event_round_new()
{
	g_bIsRoundStart = false
	balance_players()
}

public event_round_start()
{
	g_bIsRoundStart = true
}

public RG_CBasePlayer_Spawn_Pre(iPlayer)
{
	if (g_iUserNewTeam[iPlayer] != TEAM_UNASSIGNED)
	{
		if (player_switch_team(iPlayer, g_iUserNewTeam[iPlayer]))
			client_print(iPlayer, print_center, "%L", iPlayer, "AUTO_BALANCE_TEAM_CHANGED")

		g_iUserNewTeam[iPlayer] = TEAM_UNASSIGNED

		return HC_CONTINUE
	}

	if (g_bIsRoundStart)
	{
		new iBalance
		for (new i = 1, TeamName:iTeam; i <= MaxClients; i++)
		{
			if (!g_bUserConnected[i])
				continue

			iTeam = get_member(i, m_iTeam)
			if (iTeam == TEAM_TERRORIST)
				iBalance--
			else if (iTeam == TEAM_CT)
				iBalance++
		}

		if (iBalance <= -2)
			player_switch_team(iPlayer, TEAM_CT)
		else if (iBalance >= 2)
			player_switch_team(iPlayer, TEAM_TERRORIST)
	}

	return HC_CONTINUE
}

#define MAGIC_VAR		10

balance_players()
{
	new aPlayers[2][MAX_PLAYERS], iPlayersNum[2]
	new Float:aPlayerSkills[MAX_PLAYERS + 1], Float:fSkillSum[2]

	for (new iPlayer = 1, iTeam; iPlayer <= MaxClients; iPlayer++)
	{
		if (!g_bUserConnected[iPlayer])
			continue

		iTeam = get_member(iPlayer, m_iTeam) - 1
		if (iTeam < 0 || iTeam > 1)
			continue

		get_user_skill(iPlayer, aPlayerSkills[iPlayer])
		fSkillSum[iTeam] += aPlayerSkills[iPlayer]
		aPlayers[iTeam][iPlayersNum[iTeam]++] = iPlayer
	}

	new iTotalPlayersNum = iPlayersNum[0] + iPlayersNum[1]

	if (iTotalPlayersNum > 3)
	{
		if (floatabs(fSkillSum[0] - fSkillSum[1]) < (MAGIC_VAR * (iTotalPlayersNum) / 2))
			return

		new bool:bIsCTLeading = (fSkillSum[1] > fSkillSum[0])
		new Float:fTeamDiff = floatabs(fSkillSum[0] - fSkillSum[1]) / 2
		new Float:fMinDiff = 9999.0, iPair[2]

		for (new i, iTT, iCT; i < iPlayersNum[0]; i++)
		{
			iTT = aPlayers[0][i]
			for (new j, Float:fDistance; j < iPlayersNum[1]; j++)
			{
				iCT = aPlayers[1][j]
				if ((bIsCTLeading && (aPlayerSkills[iCT] < aPlayerSkills[iTT])) || (!bIsCTLeading && (aPlayerSkills[iCT] > aPlayerSkills[iTT])))
					continue

				fDistance = floatabs(fTeamDiff - floatabs(aPlayerSkills[iCT] - aPlayerSkills[iTT]))

				if (fDistance < fMinDiff)
				{
					fMinDiff = fDistance
					iPair[0] = iTT
					iPair[1] = iCT
				}
			}
		}

		if (iPair[0] && iPair[1] && fMinDiff < fTeamDiff)
		{
			g_iUserNewTeam[iPair[0]] = TEAM_CT
			g_iUserNewTeam[iPair[1]] = TEAM_TERRORIST
		}
	}
	else if (iTotalPlayersNum == 3)
	{
		new Float:fMaxSkill, iMaxSkiller, iMaxSkillerTeam

		for (new iTeam; iTeam < 2; iTeam++)
		{
			for (new i, iPlayer; i < iPlayersNum[iTeam]; i++)
			{
				iPlayer = aPlayers[iTeam][i]
				if (aPlayerSkills[iPlayer] > fMaxSkill)
				{
					fMaxSkill = aPlayerSkills[iPlayer]
					iMaxSkiller = iPlayer
					iMaxSkillerTeam = iTeam
				}
			}
		}

		if ((iPlayersNum[0] > iPlayersNum[1] && iMaxSkillerTeam == 0)
			|| (iPlayersNum[1] > iPlayersNum[0] && iMaxSkillerTeam == 1))
		{
			for (new i, iPlayer; i < iPlayersNum[iMaxSkillerTeam]; i++)
			{
				iPlayer = aPlayers[iMaxSkillerTeam][i]
				if (iPlayer != iMaxSkiller)
				{
					g_iUserNewTeam[iPlayer] = iMaxSkillerTeam == 0 ? TEAM_CT : TEAM_TERRORIST
					return
				}
			}
		}
	}
}

bool:player_switch_team(iPlayer, TeamName:iTeam)
{
	new TeamName:iCurrTeam = get_member(iPlayer, m_iTeam)
	if (iCurrTeam == TEAM_UNASSIGNED || iCurrTeam == TEAM_SPECTATOR || iCurrTeam == iTeam)
		return false

	rg_switch_team(iPlayer)

	if (iTeam == TEAM_TERRORIST)
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^1%L",
			GAME_TAG, iPlayer, "AUTO_BALANCE_TEAM_TE")
	}
	else
	{
		client_print_color(iPlayer, print_team_blue, "^4[%s] ^1%L",
			GAME_TAG, iPlayer, "AUTO_BALANCE_TEAM_CT")
	}

	return true
}
