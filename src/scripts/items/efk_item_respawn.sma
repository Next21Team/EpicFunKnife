// NOTE: This plugin is not compatible with Deathmatch

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <efk_core>

new const PLUGIN[] = "EFK: Respawn Item"

new const GAME_TAG[] = EFK_GAME_TAG

const ITEM_PRICE	= 10000

new bool:g_bWasRespawned[MAX_PLAYERS + 1]

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	kc_register_item("ITEM_RESPAWN", "BUY_RESPAWN", "efk_give_item", ITEM_PRICE)

	register_event("HLTV", "event_NewRound", "a", "1=0", "2=0")
	register_logevent("logevent_RoundEnd", 2, "1=Round_End")
}

public event_NewRound()
{
	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		g_bWasRespawned[iPlayer] = false
}

public logevent_RoundEnd()
{
	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (g_bWasRespawned[iPlayer] && kc_player_is_influenced(iPlayer))
		{
			client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "RESPAWN_COMPENSATION")
			rg_add_account(iPlayer, ITEM_PRICE)
			g_bWasRespawned[iPlayer] = false
		}
	}
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (is_user_alive(iPlayer))
		return ITEM_ALIVE

	if (g_bWasRespawned[iPlayer])
		return ITEM_NOT_AVAILABLE

	new TeamName:iTeam = get_member(iPlayer, m_iTeam)
	if (iTeam == TEAM_UNASSIGNED || iTeam == TEAM_SPECTATOR)
		return ITEM_NOT_AVAILABLE

	ExecuteHamB(Ham_CS_RoundRespawn, iPlayer)
	g_bWasRespawned[iPlayer] = true

	return ITEM_OK
}
