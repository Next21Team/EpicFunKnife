#include <amxmodx>
#include <reapi>
#include <efk_core>
#include <next_client_api>

new const PLUGIN[] = "EFK: Next Client Features"

new const DEATHMSG_KNIFE_ICONS[] = "sprites/next21_efk/ncl/deathmsg_wpns_b02.spr"

new const DEATHMSG_FRAMES_MAP[][] =
{
	"_blink",
	"_slap",
	"_flash",
	"_ninja",
	"_leap",
	"_fire",
	"_nuclear",
	"_frost",
	"_thunder",
	"_razor",
	"_telekinesis",
	"_swap",
	"_necro",
	"_spikes",
	"_dark",
	"_acidtrap",
	"_tentacles",
	"_creepy",
	"_wind",
	"_water"
}

new g_iLastRenderMode[MAX_PLAYERS + 1]
new g_iLastRenderR[MAX_PLAYERS + 1]
new g_iLastRenderG[MAX_PLAYERS + 1]
new g_iLastRenderB[MAX_PLAYERS + 1]
new g_iLastRenderFx[MAX_PLAYERS + 1]
new g_iLastRenderAmt[MAX_PLAYERS + 1]

new Trie:g_tKnifeWpnIcons

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")
	RegisterHookChain(RG_CBasePlayer_Observer_FindNextPlayer, "RG_CBasePlayer_Observer_FindNextPlayer_Post", true)

	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")

	init_knives_icons_table()
}

public plugin_precache()
{
	precache_generic(DEATHMSG_KNIFE_ICONS)
}

public Message_DeathMsg()
{
	new szTruncatedWeaponName[32]
	new iKiller = get_msg_arg_int(1)
	get_msg_arg_string(4, szTruncatedWeaponName, charsmax(szTruncatedWeaponName))

	if (equal(szTruncatedWeaponName, "knife"))
	{
		new szKnifeName[32], iFrame
		kc_knife_get_classname(kc_player_get_knife(iKiller), szKnifeName, charsmax(szKnifeName))

		if (TrieGetCell(g_tKnifeWpnIcons, szKnifeName, iFrame))
			ncl_set_wpn_icon_for_next_deathmsg(DEATHMSG_KNIFE_ICONS, iFrame)
	}
}

init_knives_icons_table()
{
	g_tKnifeWpnIcons = TrieCreate()

	new iKnivesNum = kc_get_knives_num()
	for (new iKnifeId, iFrame, szKnifeName[32]; iKnifeId < iKnivesNum; iKnifeId++)
	{
		kc_knife_get_classname(iKnifeId, szKnifeName, charsmax(szKnifeName))
		iFrame = find_deathmsg_frame(szKnifeName)
		if (iFrame != -1)
			TrieSetCell(g_tKnifeWpnIcons, szKnifeName, iFrame)
	}
}

public client_putinserver(iPlayer)
{
	reset_player_vars(iPlayer)
}

public ncl_client_api_ready(iPlayer)
{
	ncl_sandbox_cvar_begin(iPlayer)
	ncl_write_sandbox_cvar(SC_cl_minmodels, "0")
	ncl_sandbox_cvar_end()
}

public efk_player_options_update(iPlayer, iOptions)
{
	if (!(iOptions & OPTION_VIEW_MODEL_FX) && ncl_is_client_api_ready(iPlayer))
	{
		ncl_viewmodelfx_begin(iPlayer)
		ncl_write_rendermode(kRenderNormal)
		ncl_write_rendercolor(255, 255, 255)
		ncl_write_renderfx(kRenderFxNone)
		ncl_write_renderamt(0)
		ncl_viewmodelfx_end()
	}
}

public efk_invisible(iPlayer)
{
	calculate_view_render(iPlayer, iPlayer)
}

public efk_calculate_render_colors(iPlayer)
{
	calculate_view_render(iPlayer, iPlayer)
}

public efk_reset_player_render(iPlayer)
{
	update_view_render(iPlayer, kRenderNormal, 255, 255, 255, kRenderFxNone, 0)
}

public RG_CBasePlayer_Observer_FindNextPlayer_Post(iPlayer, bool:bReverse, szName[])
{
	if (!is_user_connected(iPlayer))
		return

	new iTarget = get_entvar(iPlayer, var_iuser2)
	if (is_nullent(iTarget))
		return

	calculate_view_render(iPlayer, iTarget)
}

calculate_view_render(iPlayer, iTarget)
{
	new iMode = get_entvar(iTarget, var_rendermode)
	new iFx = get_entvar(iTarget, var_renderfx)
	new iAmt = floatround(Float:get_entvar(iTarget, var_renderamt))

	new ivColor[3], Float:vColor[3]
	get_entvar(iTarget, var_rendercolor, vColor)
	FVecIVec(vColor, ivColor)

	update_view_render(iPlayer, iMode, ivColor[0], ivColor[1], ivColor[2], iFx, iAmt)
}

update_view_render(iPlayer, iMode, iRed, iGreen, iBlue, iFx, iAmt)
{
	send_view_render(iPlayer, iMode, iRed, iGreen, iBlue, iFx, iAmt)

	if (get_entvar(iPlayer, var_iuser1))
		return

	new i, iSpecNum, iSpectator, aSpectators[MAX_PLAYERS]
	get_players(aSpectators, iSpecNum, "bch")

	for (i = 0; i < iSpecNum; i++)
	{
		iSpectator = aSpectators[i]
		if (get_entvar(iSpectator, var_iuser1) != 4 || get_entvar(iSpectator, var_iuser2) != iPlayer)
			continue

		send_view_render(iSpectator, iMode, iRed, iGreen, iBlue, iFx, iAmt)
	}
}

send_view_render(iPlayer, iMode, iRed, iGreen, iBlue, iFx, iAmt)
{
	if (!(kc_player_get_options(iPlayer) & OPTION_VIEW_MODEL_FX))
	{
		reset_player_vars(iPlayer)
		return
	}

	if (!ncl_is_client_api_ready(iPlayer))
		return

	if (iMode == kRenderTransAlpha)
		iMode = kRenderTransAdd
	else if (iAmt > 1)
		iAmt = 1

	new iLastMode = g_iLastRenderMode[iPlayer]
	new iLastR = g_iLastRenderR[iPlayer]
	new iLastG = g_iLastRenderG[iPlayer]
	new iLastB = g_iLastRenderB[iPlayer]
	new iLastFx = g_iLastRenderFx[iPlayer]
	new iLastAmt = g_iLastRenderAmt[iPlayer]

	new bool:bNewRender = iLastMode != iMode || iLastFx != iFx || iLastAmt != iAmt
	new bool:bNewColors = iLastR != iRed || iLastG != iGreen || iLastB != iBlue

	if (!bNewRender && !bNewColors)
		return

	ncl_viewmodelfx_begin(iPlayer)
	if (iLastMode != iMode) ncl_write_rendermode(iMode)
	// if (iLastFx != iFx) ncl_write_renderfx(iFx)
	// if (iLastAmt != iAmt) ncl_write_renderamt(iAmt)
	// if (bNewColors) ncl_write_rendercolor(iRed, iGreen, iBlue)
	ncl_write_renderfx(iFx)
	ncl_write_renderamt(iAmt)
	ncl_write_rendercolor(iRed, iGreen, iBlue)
	ncl_viewmodelfx_end()

	g_iLastRenderMode[iPlayer] = iMode
	g_iLastRenderR[iPlayer] = iRed
	g_iLastRenderG[iPlayer] = iGreen
	g_iLastRenderB[iPlayer] = iBlue
	g_iLastRenderFx[iPlayer] = iFx
	g_iLastRenderAmt[iPlayer] = iAmt
}

reset_player_vars(iPlayer)
{
	g_iLastRenderMode[iPlayer] = kRenderNormal
	g_iLastRenderR[iPlayer] = 255
	g_iLastRenderG[iPlayer] = 255
	g_iLastRenderB[iPlayer] = 255
	g_iLastRenderFx[iPlayer] = kRenderFxNone
	g_iLastRenderAmt[iPlayer] = 0
}

find_deathmsg_frame(const szKnifeName[])
{
	for (new iFrame; iFrame < sizeof DEATHMSG_FRAMES_MAP; iFrame++)
	{
		if (contain(szKnifeName, DEATHMSG_FRAMES_MAP[iFrame]) != -1)
			return iFrame
	}

	return -1
}
