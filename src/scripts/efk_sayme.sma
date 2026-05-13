#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <efk_core>

new const PLUGIN[] = "EFK: Say me/hp"

new const GAME_TAG[] = EFK_GAME_TAG

new const MESSAGE_FMT[]	= "^4[%s] ^1%L"
#define NAME_MAXLEN		31

new
	g_iKiller[MAX_PLAYERS + 1],
	g_iKillerHealth[MAX_PLAYERS + 1],
	g_iKillerName[MAX_PLAYERS + 1][NAME_MAXLEN + 1],
	g_iDamage[MAX_PLAYERS + 1],
	g_iHealthDiff,
	HamHook:g_pHamTakeDamagePost

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", true)
	RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage_Pre", false)
	DisableHamForward(g_pHamTakeDamagePost = RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage_Post", true))

	register_clcmd("say /me", "clcmd_say_me")
	register_clcmd("say_team /me", "clcmd_say_me")
	register_clcmd("say /hp", "clcmd_say_hp")
	register_clcmd("say_team /hp", "clcmd_say_hp")

	register_event("HLTV", "event_NewRound", "a", "1=0", "2=0")

	register_dictionary("efk_sayme.txt")
}

public Ham_PlayerTakeDamage_Pre(iVictim)
{
	if (GetHamReturnStatus() != HAM_SUPERCEDE)
	{
		g_iHealthDiff = pev(iVictim, pev_health)
		EnableHamForward(g_pHamTakeDamagePost)
	}
}

public Ham_PlayerTakeDamage_Post(iVictim, iInflictor, iAttacker)
{
	DisableHamForward(g_pHamTakeDamagePost)
	new iHealth = pev(iVictim, pev_health)
	if (iHealth > 0) g_iHealthDiff -= iHealth

	if (is_user_connected(iAttacker) && iAttacker != iVictim)
		g_iDamage[iAttacker] += g_iHealthDiff
}

public Ham_PlayerSpawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		g_iDamage[iPlayer] = 0
		g_iKiller[iPlayer] = 0
	}
}

public client_disconnected(iPlayer)
{
	g_iDamage[iPlayer] = 0
	g_iKiller[iPlayer] = 0
}


public efk_player_death(iVictim, iAttacker, iAssistant)
{
	if (is_user_connected(iAttacker) && iVictim != iAttacker)
	{
		g_iKillerHealth[iVictim] = get_user_health(iAttacker)
		get_user_name(iAttacker, g_iKillerName[iVictim], NAME_MAXLEN)
		g_iKiller[iVictim] = iAttacker
	}
	else
	{
		g_iKiller[iVictim] = 0
	}
}

public clcmd_say_me(iPlayer)
{
	if (g_iDamage[iPlayer])
		client_print_color(iPlayer, print_team_default, MESSAGE_FMT, GAME_TAG, iPlayer, "SM_DEALT_DAMAGE", g_iDamage[iPlayer])
	else
		client_print_color(iPlayer, print_team_default, MESSAGE_FMT, GAME_TAG, iPlayer, "SM_NO_DEALT_DAMAGE")

	return PLUGIN_HANDLED
}

public clcmd_say_hp(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		client_print_color(iPlayer, print_team_default, MESSAGE_FMT, GAME_TAG, iPlayer, "SM_NOT_AVAILABLE")
		return PLUGIN_HANDLED
	}

	if (g_iKiller[iPlayer])
		client_print_color(iPlayer, print_team_default, MESSAGE_FMT, GAME_TAG, iPlayer, "SM_DEATH", g_iKillerName[iPlayer], g_iKillerHealth[iPlayer])
	else
		client_print_color(iPlayer, print_team_default, MESSAGE_FMT, GAME_TAG, iPlayer, "SM_NO_DEATH")

	return PLUGIN_HANDLED
}

public event_NewRound()
{
	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		g_iKiller[iPlayer] = 0
		g_iDamage[iPlayer] = 0
	}
}
