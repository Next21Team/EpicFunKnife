#include <amxmodx>
#include <reapi>

new const PLUGIN[] = "Save Spec Money"
new const VERSION[] = "0.1"
new const AUTHOR[] = "Next21 Team"

new g_iSaveAccount[MAX_PLAYERS + 1]


public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    RegisterHookChain(RG_CBasePlayer_AddAccount, "RG_CBasePlayer_AddAccount_Pre", false)
}

public client_putinserver(iPlayer)
{
    g_iSaveAccount[iPlayer] = 0
}

public client_disconnected(iPlayer)
{
    g_iSaveAccount[iPlayer] = 0
}

public RG_CBasePlayer_AddAccount_Pre(const iPlayer, iAmount, RewardType:iType, bool:bTrackChange)
{
    if (iType == RT_PLAYER_SPEC_JOIN)
    {
        if (iAmount == 0)
        {
            g_iSaveAccount[iPlayer] = get_member(iPlayer, m_iAccount)
        }
        else if (iAmount < g_iSaveAccount[iPlayer])
        {
            SetHookChainArg(2, ATYPE_INTEGER, g_iSaveAccount[iPlayer])
            g_iSaveAccount[iPlayer] = 0
        }
    }
}
