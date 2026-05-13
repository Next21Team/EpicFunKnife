#include <amxmodx>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: HP Scan Item"

new const GAME_TAG[] = EFK_GAME_TAG

const ITEM_MAX_ROUNDS		= 10
const ITEM_PRICE			= 10000

#define TASK_ROUND_USE_CHECK		100

new g_iItemId
new bool:g_bPlrItemUsed[MAX_PLAYERS + 1]

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iItemId = kc_register_item("ITEM_HPSCAN", "BUY_HPSCAN", "efk_give_item", ITEM_PRICE, .iFlags=ITMF_INVENTORY)
	if (g_iItemId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_item_register_enable_handler(g_iItemId, "efk_enable_item")

	register_event("HLTV", "event_NewRound", "a", "1=0", "2=0")
}

public event_NewRound()
{
	for (new iPlayer = 1, iValue; iPlayer <= MaxClients; iPlayer++)
	{
		iValue = kc_player_get_item_value(iPlayer, g_iItemId)
		if (iValue == -1)
			continue

		if (!g_bPlrItemUsed[iPlayer])
			continue

		iValue--
		if (iValue <= 0)
			kc_player_set_item_value(iPlayer, g_iItemId, -1)
		else
		{
			kc_player_set_item_value(iPlayer, g_iItemId, iValue)
			if (iValue == 1)
				client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "HPSCAN_LAST_ROUND")
		}
	}

	arrayset(g_bPlrItemUsed, false, sizeof g_bPlrItemUsed)

	remove_task(TASK_ROUND_USE_CHECK)
	set_task(8.0, "task_round_use_check", TASK_ROUND_USE_CHECK)
}

public ItemGiveCode:efk_give_item(iPlayer, iSenderImpulse)
{
	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		give_hpscan(iPlayer, ITEM_MAX_ROUNDS)

		client_print_color(iPlayer, print_team_default,
			"^4[%s] ^1%L ^3%L", GAME_TAG, iPlayer, "PRESENT_GET", iPlayer, "PRESENT_HPSCAN")
	}
	else
	{
		give_hpscan(iPlayer, ITEM_MAX_ROUNDS)
	}

	return ITEM_OK
}

public efk_enable_item(iPlayer, bool:bEnabled, bool:bIsRoundEnded)
{
	if (!bIsRoundEnded)
	{
		if (bEnabled)
			g_bPlrItemUsed[iPlayer] = true
		else if (task_exists(TASK_ROUND_USE_CHECK))
			g_bPlrItemUsed[iPlayer] = false
	}
}

public task_round_use_check()
{
	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (kc_player_get_item_value(iPlayer, g_iItemId) == -1)
			continue

		if (kc_player_item_get_enabled(iPlayer, g_iItemId))
			g_bPlrItemUsed[iPlayer] = true
	}
}

give_hpscan(iPlayer, iValue)
{
	new iCurrValue = kc_player_get_item_value(iPlayer, g_iItemId)
	if (iCurrValue == -1)
	{
		iCurrValue = 0
		kc_player_item_set_enabled(iPlayer, g_iItemId, true)
	}

	kc_player_set_item_value(iPlayer, g_iItemId, iCurrValue + iValue)

	if (is_user_alive(iPlayer) && kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {0, 255, 0}, 100, MSG_ONE, _, iPlayer)

	return iValue
}
