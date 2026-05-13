#include <amxmodx>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Dominations"

new const GAME_TAG[] = EFK_GAME_TAG

new const SOUND_DOM_ADD[]		= "next21_efk/domination_add.wav"
new const SOUND_DOM_REVENGE[]	= "next21_efk/domination_revenge.wav"
new const SOUND_DOM_KILL[]		= "next21_efk/domination_kill.wav"

#define MIN_DOMANATE_FRAGS	5

#define MAX_NAME_LEN		12

new g_iDominateFrags[MAX_PLAYERS + 1][MAX_PLAYERS + 1]

public plugin_precache()
{
	precache_sound(SOUND_DOM_ADD)
	precache_sound(SOUND_DOM_REVENGE)
	precache_sound(SOUND_DOM_KILL)
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	register_dictionary("efk_dominations.txt")
}

public client_disconnected(iPlayer)
{
	new iDominators[MAX_PLAYERS + 1], iDominationsNum
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_iDominateFrags[i][iPlayer] >= MIN_DOMANATE_FRAGS)
			iDominators[iDominationsNum++] = i
		g_iDominateFrags[i][iPlayer] = 0
	}

	if (iDominationsNum > 1)
	{
		new szPlayerName[24]
		get_entvar(iPlayer, var_netname, szPlayerName, charsmax(szPlayerName))
		strip_name(szPlayerName)

		client_print_color(0, print_team_red, "^4[%s] ^3%L",
			GAME_TAG, LANG_PLAYER, "DOMINATION_DISCONNECT_MULT", szPlayerName, iDominationsNum)
	}
	else if (iDominationsNum == 1)
	{
		new szPlayerName[24], szDominatorName[24]
		get_entvar(iPlayer, var_netname, szPlayerName, charsmax(szPlayerName))
		get_entvar(iDominators[0], var_netname, szDominatorName, charsmax(szDominatorName))

		strip_name(szPlayerName)
		strip_name(szDominatorName)

		client_print_color(0, print_team_red, "^4[%s] ^3%L",
			GAME_TAG, LANG_PLAYER, "DOMINATION_DISCONNECT_ONE", szPlayerName, szDominatorName)
	}

	arrayset(g_iDominateFrags[iPlayer], 0, MAX_PLAYERS + 1)
}

public efk_player_death(iVictim, iAttacker, iAssistant)
{
	if (is_entity_player(iAttacker) && get_member(iAttacker, m_iTeam) != get_member(iVictim, m_iTeam))
		set_domination_frag(iAttacker, iVictim)
}

set_domination_frag(iPlayer, iTarget)
{
	g_iDominateFrags[iPlayer][iTarget]++
	new szTargetName[24], szPlayerName[24]
	get_entvar(iTarget, var_netname, szTargetName, charsmax(szTargetName))
	get_entvar(iPlayer, var_netname, szPlayerName, charsmax(szPlayerName))

	strip_name(szPlayerName)
	strip_name(szTargetName)

	if (g_iDominateFrags[iPlayer][iTarget] == MIN_DOMANATE_FRAGS)
	{
		client_print_color(0, print_team_red, "^4[%s] ^3%L",
			GAME_TAG, LANG_PLAYER, "DOMINATION_ADD", szPlayerName, szTargetName)
		emit_sound(iPlayer, CHAN_AUTO, SOUND_DOM_ADD, 1.0, 1.0, 0, 100)

		new iDominationsNum
		for (new i = 1; i <= MaxClients; i++)
			if (g_iDominateFrags[iPlayer][i] >= MIN_DOMANATE_FRAGS)
				iDominationsNum++

		if (iDominationsNum > 1)
			client_print_color(0, print_team_red, "^4[%s] %s ^3%L",
				GAME_TAG, szPlayerName, LANG_PLAYER, "DOMINATION_COUNT", iDominationsNum)
	}
	else if (g_iDominateFrags[iPlayer][iTarget] > MIN_DOMANATE_FRAGS)
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L",
			GAME_TAG, iPlayer, "DOMINATION_KILL_A", szTargetName)
		client_print_color(iTarget, print_team_red, "^4[%s] ^3%L",
			GAME_TAG, iTarget, "DOMINATION_KILL_V", szPlayerName)
		client_cmd(iTarget, "spk %s", SOUND_DOM_KILL)
	}
	else if (g_iDominateFrags[iTarget][iPlayer] >= MIN_DOMANATE_FRAGS)
	{
		client_print_color(0, print_team_red, "^4[%s] ^3%L",
			GAME_TAG, LANG_PLAYER, "DOMINATION_REVENGE", szPlayerName, szTargetName)
		emit_sound(iPlayer, CHAN_AUTO, SOUND_DOM_REVENGE, 1.0, 1.0, 0, 100)
	}

	g_iDominateFrags[iTarget][iPlayer] = 0
}

strip_name(szName[])
{
	if (strlen(szName) > MAX_NAME_LEN)
	{
		szName[MAX_NAME_LEN] = 0
		add(szName, 23, "..")
	}
}
