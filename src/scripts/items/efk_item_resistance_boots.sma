#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Resistance Boots"
new const GAME_TAG[] = EFK_GAME_TAG

const ITEM_RESISTANCE = 300
const ITEM_PRICE = 14000
const Float:DAMAGE_RESTORE_PERCENT = 0.40

#define DAMAGE_RESTORE_START_TIME	2.0
#define DAMAGE_RESTORE_HEAL			4
#define DAMAGE_RESTORE_DELAY		1.0

new g_iItemId
new bool:g_bIsRoundEnded
new g_iFallRestore[MAX_PLAYERS + 1]
new Float:g_flFallRestoreTime[MAX_PLAYERS + 1]

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "SUMY")

	g_iItemId = kc_register_item("ITEM_RESISTANCE_BOOTS","BUY_RESISTANCE_BOOTS","efk_give_item",ITEM_PRICE,.iFlags = ITMF_INVENTORY|ITMF_MENU_REDRAW)

	if (g_iItemId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	RegisterHam(Ham_TakeDamage,"player","Ham_Player_TakeDamage_Post",true)
	RegisterHam(Ham_Player_PreThink,"player","Ham_Player_PreThink_Post")
	register_event("TextMsg","event_NewGame","a","2=#Game_Commencing","2=#Game_will_restart_in")

	register_logevent("logevent_RoundStart",2,"1=Round_Start")
	register_logevent("logevent_RoundEnd",2,"1=Round_End")
}

public client_putinserver(iPlayer)
{
	kc_player_set_item_value(iPlayer, g_iItemId, -1)
	g_iFallRestore[iPlayer] = 0
}

public client_disconnected(iPlayer)
{
	g_iFallRestore[iPlayer] = 0
}

public event_NewGame()
{
	g_bIsRoundEnded = false

	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (is_user_connected(iPlayer))
			kc_player_set_item_value(iPlayer, g_iItemId, -1)

		g_iFallRestore[iPlayer] = 0
	}
}

public logevent_RoundStart()
{
	g_bIsRoundEnded = false
}

public logevent_RoundEnd()
{
	g_bIsRoundEnded = true
}

public Ham_Player_TakeDamage_Post(iVictim,iInflictor,iAttacker,Float:fDamage,iDamageBits)
{
	if (!is_user_alive(iVictim))
		return HAM_IGNORED

	if (!(iDamageBits & DMG_FALL) || (iAttacker && iAttacker != iVictim))
		return HAM_IGNORED

	if (fDamage <= 0.0)
		return HAM_IGNORED

	new iResistance = kc_player_get_item_value(iVictim,g_iItemId)

	if (iResistance <= 0)
		return HAM_IGNORED

	if (!kc_player_item_get_enabled(iVictim,g_iItemId))
	{
		return HAM_IGNORED
	}

	new iHeal = floatround(fDamage * DAMAGE_RESTORE_PERCENT, floatround_floor)

	if (iHeal <= 0)
		return HAM_IGNORED

	if (iHeal > iResistance)
		iHeal = iResistance

	if (iHeal <= 0)
		return HAM_IGNORED

	if (!g_iFallRestore[iVictim])
		g_flFallRestoreTime[iVictim] = get_gametime() + DAMAGE_RESTORE_START_TIME

	g_iFallRestore[iVictim] += iHeal
	
	spend_resistance(iVictim, iHeal)

	return HAM_IGNORED
}


public Ham_Player_PreThink_Post(iPlayer)
{
	if (!g_iFallRestore[iPlayer])
		return HAM_IGNORED


	if (!is_user_alive(iPlayer))
	{
		g_iFallRestore[iPlayer] = 0
		return HAM_IGNORED
	}


	new Float:fGameTime = get_gametime()

	if (g_flFallRestoreTime[iPlayer] > fGameTime)
		return HAM_IGNORED


	new Float:fMaxHealth = kc_player_get_maxhealth(iPlayer)
	new Float:fHealth = Float:get_entvar(iPlayer, var_health)

	if (fHealth >= fMaxHealth)
	{
		refund_resistance(iPlayer, g_iFallRestore[iPlayer])
		g_iFallRestore[iPlayer] = 0
		return HAM_IGNORED
	}

	new iChunk = min(g_iFallRestore[iPlayer], DAMAGE_RESTORE_HEAL)
	new iActual = iChunk

	if (fHealth + float(iChunk) > fMaxHealth)
		iActual = floatround(fMaxHealth - fHealth, floatround_floor)

	if (iActual <= 0)
	{
		refund_resistance(iPlayer, g_iFallRestore[iPlayer])
		g_iFallRestore[iPlayer] = 0
		return HAM_IGNORED
	}

	set_entvar(iPlayer, var_health, fHealth + float(iActual))

	if (iActual < iChunk)
		refund_resistance(iPlayer, iChunk - iActual)

	g_iFallRestore[iPlayer] -= iChunk

	if (g_iFallRestore[iPlayer] > 0)
		g_flFallRestoreTime[iPlayer] = fGameTime + DAMAGE_RESTORE_DELAY

	return HAM_IGNORED
}

spend_resistance(iPlayer, iAmount)
{
	new iResistance = kc_player_get_item_value(iPlayer,g_iItemId)

	if (iResistance <= 0)
		return

	iResistance -= iAmount

	if (iResistance > 0)
	{
		kc_player_set_item_value(iPlayer,g_iItemId,iResistance)
	}
	else
	{
		kc_player_set_item_value(iPlayer,g_iItemId,-1)

		client_print(iPlayer,print_center,"%L",iPlayer,"RESISTANCE_EXHAUSTED")
	}
}

refund_resistance(iPlayer, iAmount)
{
	if (iAmount <= 0)
		return

	new iResistance = kc_player_get_item_value(iPlayer,g_iItemId)

	if (iResistance < 0)
		return

	kc_player_set_item_value(iPlayer,g_iItemId,iResistance + iAmount)
}

public ItemGiveCode:efk_give_item(iPlayer,iSenderImpulse)
{
	if (iSenderImpulse == IMPULSE_PRESENT)
	{
		give_resistance(iPlayer,ITEM_RESISTANCE)
		client_print_color(iPlayer,print_team_default,"^4[%s] ^1%L ^3%L",GAME_TAG,iPlayer,"PRESENT_GET",iPlayer,"PRESENT_RESISTANCE_BOOTS")
		return ITEM_OK
	}

	if (iSenderImpulse != iPlayer || !is_user_alive(iPlayer))
	{
		give_resistance(iPlayer,ITEM_RESISTANCE)
		return ITEM_OK
	}

	if (g_bIsRoundEnded)
		return ITEM_NOT_AVAILABLE

	if (Float:get_member(iPlayer, m_flNextAttack) > 0.0)
		return ITEM_NOT_AVAILABLE

	if (kc_player_get_capture(iPlayer) != CAPTURE_NONE)
		return ITEM_NOT_AVAILABLE

	new VisibilityType:iVisibility =
		kc_player_get_visibility(iPlayer)

	if (iVisibility >= VIS_TRANS && iVisibility != VIS_CLONE)
		return ITEM_NOT_AVAILABLE

	give_resistance(iPlayer,ITEM_RESISTANCE)

	return ITEM_OK
}

give_resistance(iPlayer,iValue)
{
	if (!is_user_connected(iPlayer))
		return

	new iCurrValue = kc_player_get_item_value(iPlayer,g_iItemId)

	if (iCurrValue == -1)
	{
		iCurrValue = 0

		kc_player_item_set_enabled(iPlayer,g_iItemId,true)
	}

	iCurrValue += iValue
	kc_player_set_item_value(iPlayer,g_iItemId,iCurrValue)
	client_print(iPlayer,print_center,"%L",iPlayer,"RESISTANCE_CHARGE",iValue)
}
