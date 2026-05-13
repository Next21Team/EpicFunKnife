#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <efk_statsx>
#include <efk_const>

new const PLUGIN[] = "EFK: Balancer"

new const GAME_TAG[] = EFK_GAME_TAG

#define TASK_ROUND_GAME 		1210


new bool:g_bUserConnected[MAX_PLAYERS + 1]
new g_iUserNewTeam[MAX_PLAYERS + 1]
new bool:g_bIsRoundStart


public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	register_event("HLTV", "event_round_new", "a", "1=0", "2=0")
	register_logevent("event_round_start", 2, "1=Round_Start")

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn")
}

public client_putinserver(id)
{
	g_iUserNewTeam[id] = 0
	g_bUserConnected[id] = true
}

public client_disconnected(id)
{
	g_iUserNewTeam[id] = 0
	g_bUserConnected[id] = false
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

public fw_PlayerSpawn(id)
{
	if (g_iUserNewTeam[id])
	{
		if (g_iUserNewTeam[id] == 1 && get_member(id, m_iTeam) != 1)
		{
			rg_switch_team(id)
			client_print_color(id, print_team_red, "^4[%s] ^1%L", GAME_TAG, id, "AUTO_BALANCE_TEAM_T")
			client_print(id, print_center, "%L", id, "AUTO_BALANCE_TEAM_CHANGED")
		}
		else if (get_member(id, m_iTeam) != 2)
		{
			rg_switch_team(id)
			client_print_color(id, print_team_blue, "^4[%s] ^1%L", GAME_TAG, id, "AUTO_BALANCE_TEAM_CT")
			client_print(id, print_center, "%L", id, "AUTO_BALANCE_TEAM_CHANGED")
		}
		g_iUserNewTeam[id] = 0

		return HAM_IGNORED
	}

	if (g_bIsRoundStart)
	{
		new pnum[2], iTeam[MAX_PLAYERS + 1]
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!g_bUserConnected[i])
				continue

			iTeam[i] = get_member(i, m_iTeam)

			if (iTeam[i] == 1)
				pnum[0]++
			else if (iTeam[i] == 2)
				pnum[1]++
		}

		if (abs(pnum[0] - pnum[1]) / 2 > 0)
		{
			if (pnum[0] > pnum[1] && iTeam[id] == 1)
			{
				rg_switch_team(id)
				client_print_color(id, print_team_blue, "^4[%s] ^1%L", GAME_TAG, id, "AUTO_BALANCE_TEAM_CT")
			}
			else if (pnum[0] < pnum[1] && iTeam[id] == 2)
			{
				rg_switch_team(id)
				client_print_color(id, print_team_red, "^4[%s] ^1%L", GAME_TAG, id, "AUTO_BALANCE_TEAM_T")
			}
		}
	}

	return HAM_IGNORED
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
			g_iUserNewTeam[iPair[0]] = 2
			g_iUserNewTeam[iPair[1]] = 1
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
					g_iUserNewTeam[iPlayer] = iMaxSkillerTeam == 0 ? 2 : 1
					return
				}
			}
		}
	}
}
