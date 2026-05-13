#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Duels"

new const GAME_TAG[] = EFK_GAME_TAG

new const SPRITE_DUEL[]			= "sprites/next21_efk/duel.spr"

new const SOUND_DUEL_ACCEPTED[]	= "next21_efk/duel_accepted.wav"
new const SOUND_DUEL_END[]		= "next21_efk/duel_end.wav"

new const _SOUND_GUI_CLICK[]	= SOUND_GUI_CLICK
new const _SOUND_GUI_ERROR[]	= SOUND_GUI_ERROR

#define DUEL_COMPENSATION			3000
#define DUEL_REWARD			    	7500
#define DUEL_LOSING			    	3000
#define DUEL_WIN_FRAGS			    3
#define DUEL_WAITING_TIME			10.0

new const CLASSNAME_DUELSPRITE[]	= "next21_duelsprite"

#define TASK_DUEL_WAITING			100

new
	g_iDuelTarget[MAX_PLAYERS + 1],
	bool:g_bDuelWaiting[MAX_PLAYERS + 1],
	g_iDuelFrags[MAX_PLAYERS + 1],
	g_fwdWinDuel

public plugin_precache()
{
	precache_sound(SOUND_DUEL_ACCEPTED)
	precache_sound(SOUND_DUEL_END)

	precache_model(SPRITE_DUEL)
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	register_dictionary("efk_duels.txt")

	register_clcmd("say /duel", "clcmd_duel")
	register_clcmd("say_team /duel", "clcmd_duel")

	register_clcmd("say /unduel", "clcmd_unduel")
	register_clcmd("say_team /unduel", "clcmd_unduel")

	kc_register_menu_item("DUEL_MENUNAME", "duel_show_menu")

	g_fwdWinDuel = CreateMultiForward("efk_duel_win", ET_IGNORE, FP_CELL, FP_CELL)
}

public client_disconnected(iPlayer)
{
	new iDuelTarget = g_iDuelTarget[iPlayer]
	if (iDuelTarget)
	{
		if (is_user_connected(iDuelTarget))
		{
			if (g_bDuelWaiting[iDuelTarget])
			{
				client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L",
					GAME_TAG, iDuelTarget, "DUEL_DISCONNECT_W", iPlayer)
			}
			else
			{
				client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L",
					GAME_TAG, iDuelTarget, "DUEL_DISCONNECT", iPlayer)

				duel_compensation(iDuelTarget, iPlayer)
			}
		}

		duel_clear(iPlayer, iDuelTarget)
	}
}

public efk_player_death(iVictim, iAttacker, iAssistant)
{
	if (is_entity_player(iAttacker) && get_member(iAttacker, m_iTeam) != get_member(iVictim, m_iTeam))
		duel_add_frag(iAttacker, iVictim)
}

public efk_player_change_team(iPlayer, iTeam)
{
	new iDuelTarget = g_iDuelTarget[iPlayer]
	if (iDuelTarget && (iTeam == get_member(iDuelTarget, m_iTeam) || iTeam == _:TEAM_UNASSIGNED || iTeam == _:TEAM_SPECTATOR))
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_TEAM")
		client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L", GAME_TAG, iDuelTarget, "DUEL_TEAM")

		if (!g_bDuelWaiting[iDuelTarget])
		{
			duel_compensation(iDuelTarget, iPlayer)
			duel_compensation(iPlayer, iDuelTarget)
		}

		duel_clear(iPlayer, iDuelTarget)
	}
}

public clcmd_duel(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return PLUGIN_HANDLED

	duel_show_menu(iPlayer)
	return PLUGIN_HANDLED
}

public clcmd_unduel(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return PLUGIN_HANDLED

	new iDuelTarget = g_iDuelTarget[iPlayer]
	if (!iDuelTarget)
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_NOEXIST")
		return PLUGIN_HANDLED
	}

	client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L", GAME_TAG, iDuelTarget, "DUEL_BREAK", iPlayer)
	client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_BREAK_V")

	if (!g_bDuelWaiting[iPlayer])
	{
		if (g_iDuelFrags[iPlayer] < g_iDuelFrags[iDuelTarget])
		{
			rg_add_account(iPlayer, -DUEL_LOSING)
			client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_BREAK_FINE", DUEL_LOSING)
		}
		duel_compensation(iDuelTarget, iPlayer)
	}

	duel_clear(iPlayer, iDuelTarget)

	return PLUGIN_HANDLED
}

public duel_show_menu(iPlayer)
{
	new iDuelTarget = g_iDuelTarget[iPlayer]
	if (iDuelTarget)
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer,
			g_bDuelWaiting[iPlayer] ? "DUEL_EXIST_W" : "DUEL_EXIST", iDuelTarget)

		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_UNDUEL")
		return PLUGIN_HANDLED
	}

	new TeamName:iPlayerTeam = get_member(iPlayer, m_iTeam)
	if (iPlayerTeam == TEAM_UNASSIGNED || iPlayerTeam == TEAM_SPECTATOR)
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_WRONG_TEAM")
		return PLUGIN_HANDLED
	}

	new iMenu = menu_create(fmt("\r%L", iPlayer, "DUEL_HEADNAME"), "duel_handler_menu")
	new szItemName[24], szItemInfo[4]
	new TeamName:iTargetTeam = (iPlayerTeam == TEAM_CT) ? TEAM_TERRORIST : TEAM_CT

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i) || get_member(i, m_iTeam) != iTargetTeam)
			continue

		if (g_iDuelTarget[i])
			continue

		get_entvar(i, var_netname, szItemName, charsmax(szItemName))
		num_to_str(i, szItemInfo, charsmax(szItemInfo))

		menu_additem(iMenu, szItemName, szItemInfo)
	}

	menu_setprop(iMenu, MPROP_NEXTNAME, fmt("%L", iPlayer, "MENU_NEXT"))
	menu_setprop(iMenu, MPROP_BACKNAME, fmt("%L", iPlayer, "MENU_BACK"))
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", iPlayer, "MENU_EXIT"))

	menu_display(iPlayer, iMenu)

	return PLUGIN_CONTINUE
}

public duel_handler_menu(iPlayer, iMenu, iItem)
{
	if (iItem == MENU_EXIT)
	{
		menu_destroy(iMenu)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	new TeamName:iPlayerTeam = get_member(iPlayer, m_iTeam)
	if (iPlayerTeam == TEAM_UNASSIGNED || iPlayerTeam == TEAM_SPECTATOR)
	{
		menu_destroy(iMenu)
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_WRONG_TEAM")
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		return PLUGIN_HANDLED
	}

	new szItemInfo[4]
	menu_item_getinfo(iMenu, iItem, .info=szItemInfo, .infolen=charsmax(szItemInfo))
	menu_destroy(iMenu)

	new iDuelTarget = str_to_num(szItemInfo)
	new TeamName:iTargetTeam = get_member(iDuelTarget, m_iTeam)

	if (!is_user_connected(iDuelTarget) || iPlayerTeam == iTargetTeam || iTargetTeam == TEAM_UNASSIGNED || iTargetTeam == TEAM_SPECTATOR)
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_ERROR_PLAYER")
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		duel_show_menu(iPlayer)
		return PLUGIN_HANDLED
	}

	if (g_iDuelTarget[iDuelTarget])
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_WARNING_PLAYER")
		duel_show_menu(iPlayer)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		return PLUGIN_HANDLED
	}

	client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_WAITING", iDuelTarget)
	g_iDuelTarget[iPlayer] = iDuelTarget
	g_iDuelTarget[iDuelTarget] = iPlayer
	g_bDuelWaiting[iPlayer] = true
	g_bDuelWaiting[iDuelTarget] = true

	new iChallengeMenu = menu_create(fmt("\r%L", iDuelTarget, "DUEL_CHALLENGE", iPlayer), "duel_handler_challenge")
	new szMenuItem[64]

	formatex(szMenuItem, charsmax(szMenuItem), "\w%L", iDuelTarget, "DUEL_AGREE")
	menu_additem(iChallengeMenu, szMenuItem)
	formatex(szMenuItem, charsmax(szMenuItem), "\w%L", iDuelTarget, "DUEL_REFUSE")
	menu_additem(iChallengeMenu, szMenuItem)

	menu_setprop(iChallengeMenu, MPROP_EXIT, -1)
	menu_display(iDuelTarget, iChallengeMenu)

	client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)

	set_task(DUEL_WAITING_TIME, "task_duel_waiting", iPlayer + TASK_DUEL_WAITING)

	if (is_user_bot(iDuelTarget))
		duel_handler_challenge(iDuelTarget, iChallengeMenu, 0)

	return PLUGIN_CONTINUE
}

public duel_handler_challenge(iPlayer, iMenu, iItem)
{
	menu_destroy(iMenu)

	if (!is_user_connected(iPlayer))
		return PLUGIN_HANDLED

	new iDuelTarget = g_iDuelTarget[iPlayer]
	if (!iDuelTarget || !g_bDuelWaiting[iPlayer])
	{
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_WAITING_TIME")
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		return PLUGIN_HANDLED
	}

	g_bDuelWaiting[iPlayer] = false
	g_bDuelWaiting[iDuelTarget] = false

	remove_task(TASK_DUEL_WAITING + iDuelTarget)

	switch (iItem)
	{
		case 0:
		{
			client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L", GAME_TAG, iDuelTarget, "DUEL_PLAYER_AGREE", iPlayer)
			client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L", GAME_TAG, iDuelTarget, "DUEL_RULE", DUEL_WIN_FRAGS)
			client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_RULE", DUEL_WIN_FRAGS)

			client_cmd(iPlayer, "spk %s", SOUND_DUEL_ACCEPTED)
			client_cmd(iDuelTarget, "spk %s", SOUND_DUEL_ACCEPTED)

			duel_sprite_create(iDuelTarget, iPlayer)
			duel_sprite_create(iPlayer, iDuelTarget)
		}
		case 1:
		{
			client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
			client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L", GAME_TAG, iDuelTarget, "DUEL_PLAYER_REFUSE", iPlayer)

			g_iDuelTarget[iPlayer] = 0
			g_iDuelTarget[iDuelTarget] = 0
		}
	}

	return PLUGIN_HANDLED
}

duel_add_frag(iPlayer, iDuelTarget)
{
	if (g_iDuelTarget[iPlayer] != iDuelTarget || g_bDuelWaiting[iPlayer])
		return

	new szPlayerName[24], szTargetName[24]
	get_entvar(iDuelTarget, var_netname, szTargetName, charsmax(szTargetName))
	get_entvar(iPlayer, var_netname, szPlayerName, charsmax(szPlayerName))

	new iDuelFrags = g_iDuelFrags[iPlayer] + 1

	if (iDuelFrags == DUEL_WIN_FRAGS)
	{
		client_print_color(0, print_team_red, "^4[%s] ^3%L",
			GAME_TAG, LANG_PLAYER, "DUEL_WIN", szPlayerName, szTargetName,
			szPlayerName, iDuelFrags, g_iDuelFrags[iDuelTarget])

		rg_add_account(iPlayer, DUEL_REWARD)
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_REWARD", DUEL_REWARD)

		rg_add_account(iDuelTarget, -DUEL_LOSING)
		client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L", GAME_TAG, iDuelTarget, "DUEL_LOOSE", DUEL_LOSING)

		client_cmd(iPlayer, "spk %s", SOUND_DUEL_END)
		client_cmd(iDuelTarget, "spk %s", SOUND_DUEL_END)

		duel_clear(iPlayer, iDuelTarget)

		ExecuteForward(g_fwdWinDuel, _, iPlayer, iDuelTarget)

		return
	}

	g_iDuelFrags[iPlayer] = iDuelFrags

	client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L",
		GAME_TAG, iPlayer, "DUEL_FRAG_A", DUEL_WIN_FRAGS - iDuelFrags)
	client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L",
		GAME_TAG, iDuelTarget, "DUEL_FRAG_V", DUEL_WIN_FRAGS - iDuelFrags)
}

duel_compensation(iPlayer, iDuelTarget)
{
	if (g_iDuelFrags[iPlayer] > g_iDuelFrags[iDuelTarget])
	{
		// rg_add_account(id, DUEL_COMPENSATION) // CRASH SERVER from fw_TeamInfo()
		set_member(iPlayer, m_iAccount, min(MAX_PLAYER_MONEY, get_member(iPlayer, m_iAccount) + DUEL_COMPENSATION))
		client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_COMPENSATION", DUEL_COMPENSATION)
	}
}

duel_clear(iPlayerA, iPlayerB)
{
	g_iDuelTarget[iPlayerA] = 0
	g_iDuelTarget[iPlayerB] = 0

	g_iDuelFrags[iPlayerA] = 0
	g_iDuelFrags[iPlayerB] = 0

	remove_task(TASK_DUEL_WAITING + iPlayerA)
	remove_task(TASK_DUEL_WAITING + iPlayerB)

	new iDuelSpriteEnt = NULLENT, iDuelSpriteOwner
	while ((iDuelSpriteEnt = rg_find_ent_by_class(iDuelSpriteEnt, CLASSNAME_DUELSPRITE)))
	{
		iDuelSpriteOwner = get_entvar(iDuelSpriteEnt, var_owner)
		if (iDuelSpriteOwner == iPlayerA || iDuelSpriteOwner == iPlayerB)
			rg_remove_entity(iDuelSpriteEnt)
	}
}

duel_sprite_create(iTarget, iOwner)
{
	new iDuelSpriteEnt = rg_create_entity("info_target")
	if (is_nullent(iDuelSpriteEnt))
		return NULLENT

	engfunc(EngFunc_SetSize, iDuelSpriteEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	engfunc(EngFunc_SetModel, iDuelSpriteEnt, SPRITE_DUEL)

	set_entvar(iDuelSpriteEnt, var_impulse, IMPULSE_DUELSPRITE)
	set_entvar(iDuelSpriteEnt, var_classname, CLASSNAME_DUELSPRITE)
	set_entvar(iDuelSpriteEnt, var_owner, iOwner)
	set_entvar(iDuelSpriteEnt, var_dueltarget, iTarget)

	set_entvar(iDuelSpriteEnt, var_renderfx, kRenderFxNone)
	set_entvar(iDuelSpriteEnt, var_rendercolor, Float:{255.0, 255.0, 255.0})
	set_entvar(iDuelSpriteEnt, var_rendermode, kRenderTransAdd)
	set_entvar(iDuelSpriteEnt, var_renderamt, 255.0)

	set_entvar(iDuelSpriteEnt, var_solid, SOLID_NOT)
	set_entvar(iDuelSpriteEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iDuelSpriteEnt, var_effects, EF_OWNER_VISIBILITY | EF_FORCEVISIBILITY)

	return iDuelSpriteEnt
}

public task_duel_waiting(iTaskId)
{
	new iPlayer = iTaskId - TASK_DUEL_WAITING
	new iDuelTarget = g_iDuelTarget[iPlayer]

	client_print_color(iPlayer, print_team_red, "^4[%s] ^3%L", GAME_TAG, iPlayer, "DUEL_WAITING_TIME")
	client_print_color(iDuelTarget, print_team_red, "^4[%s] ^3%L", GAME_TAG, iDuelTarget, "DUEL_WAITING_TIME")

	duel_clear(iPlayer, iDuelTarget)
}
