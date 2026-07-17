#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Swap Knife"

#define KNIFE_CLASSNAME "weapon_next21_swap"
#define KNIFE_MENUDESC  "KNIFE_SWAP_DESC"
#define KNIFE_CHATDESC  "KNIFE_SWAP_CHAT"

#define HP				100.0
#define GRAVITY			1.0
#define SPEED			255.0
#define MINDAMAGE		5.0
#define MAXDAMAGE		10.0

#define KNIFE_LEVEL     2

#define ABIL1_NAME		"Swap"
#define ABIL1_CHARGE	6.25
#define ABIL1_TYPE		ABIL_TARGET_PLAYER
#define ABIL1_MINDIST	150.0
#define ABIL1_MAXDIST	880.0

#define ABIL2_NAME		"Concent Block"
#define ABIL2_CHARGE	12.5

#define ABIL3_NAME		"Ribs"
#define ABIL3_CHARGE	12.5
#define ABIL3_DURATION	3.5

#define ABIL3_COLOR_R	65
#define ABIL3_COLOR_G	0
#define ABIL3_COLOR_B	100

new const ABIL3_ICON[] = "suit_empty"

#define ABIL3_COLOR			{ABIL3_COLOR_R, ABIL3_COLOR_G, ABIL3_COLOR_B}
#define ABIL3_COLOR_VEC		Float:{ABIL3_COLOR_R.0, ABIL3_COLOR_G.0, ABIL3_COLOR_B.0}

#define CONCENTBLOCK_TIME	2.5

#define SWAP_TIME		3.0

new const MODEL_V_KNIFE[]	= "models/next21_efk/v_swap_knife_b03.mdl"
new const MODEL_P_KNIFE[]	= "models/next21_efk/p_swap_knife_r2.mdl"
new const MODEL_REFLECTOR[]	= "models/next21_efk/reflector.mdl"

new const SOUND_SWAP[]			= "next21_efk/swap.wav"
new const SOUND_RIBS_START[]	= "next21_efk/swap_ribs_start.wav"
new const SOUND_RIBS_CATCH[]	= "next21_efk/swap_ribs_catch.wav"
new const SOUND_RIBS_END[]		= "next21_efk/swap_ribs_end.wav"

new g_pKnifePMdl, g_iKnifeId
new bool:g_playerHasKnife[MAX_PLAYERS + 1]
new g_playerReflectionRibs[MAX_PLAYERS + 1]

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_CONCENTRATION,
	VIEW_SEQ_CONCENTBLOCK,
	VIEW_SEQ_UNCONCENTRATION = 8
}

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	precache_model(MODEL_REFLECTOR)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_RIBS_START)
	precache_sound(SOUND_RIBS_CATCH)
	precache_sound(SOUND_RIBS_END)
	precache_sound(SOUND_SWAP)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		engfunc(EngFunc_AllocString, MODEL_V_KNIFE), engfunc(EngFunc_AllocString, MODEL_P_KNIFE),
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, ABIL1_CHARGE, ABIL1_TYPE, ABIL1_MINDIST, ABIL1_MAXDIST)
	kc_register_ability2(g_iKnifeId, ABIL2_NAME, ABIL2_CHARGE)
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)

	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLEABLE)
	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_DUAL_KNIVES)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	reflection_ribs_kill(iPlayer)
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (!g_playerHasKnife[iPlayer])
		return PLUGIN_CONTINUE

	if (!is_entity_player(iTarget))
		return PLUGIN_CONTINUE

	if (get_member(iPlayer, m_iTeam) == get_member(iTarget, m_iTeam))
	{
		if (kc_player_in_debuffed(iTarget))
			return _:CROSSHAIR_HELP
	}

	iAbilType = ABIL_TARGET_ENEMY
	return PLUGIN_CONTINUE
}

public efk_ability_pre(iPlayer, iTarget)
{
	if (!g_playerHasKnife[iPlayer])
		return PLUGIN_CONTINUE

	if (is_entity_player(iTarget))
	{
		if (get_member(iPlayer, m_iTeam) == get_member(iTarget, m_iTeam))
		{
			if (kc_player_swap(iPlayer, iTarget, SWAP_TIME))
			{
				send_msg_ScreenFade((1<<12), (1<<8), (1<<4), ABIL3_COLOR, 255, MSG_ONE, _, iTarget)
				engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SWAP, 1.0, ATTN_NORM, 0, PITCH_NORM)
				kc_player_set_abil1_charge(iPlayer, 65.0)
			}
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer, iTarget)
{
	if (!kc_player_swap(iPlayer, iTarget, SWAP_TIME))
		return PLUGIN_HANDLED

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SWAP, 1.0, ATTN_NORM, 0, PITCH_NORM)

	return PLUGIN_CONTINUE
}

public efk_ability2(iPlayer)
{
	if (kc_player_set_concentblock(iPlayer, VIEW_SEQ_CONCENTBLOCK, CONCENTBLOCK_TIME))
	{
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_CONCENTRATION)
		return PLUGIN_CONTINUE
	}

	return PLUGIN_HANDLED
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	if (iKnifeId == g_iKnifeId)
	{
		g_playerHasKnife[iPlayer] = true
		if (kc_player_in_freeze(iPlayer))
			efk_freeze(iPlayer)
	}
	else
		g_playerHasKnife[iPlayer] = false
}

public efk_apply_damage(iVictim, iAttacker, &Float:fBaseDamage, &Float:fPowerDamage, &Float:fAddDamage)
{
	if (g_playerHasKnife[iAttacker])
	{
		new Float:fHealth
		get_entvar(iAttacker, var_health, fHealth)

		if (fHealth < HP)
			fAddDamage = 0.0
	}
}

public efk_ability3(iPlayer)
{
	if (!kc_player_reflection_start(iPlayer, ABIL3_DURATION))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public efk_reflection_start(iPlayer)
{
	if (reflection_ribs_create(iPlayer) == NULLENT)
		return

	send_msg_StatusIcon(true, ABIL3_ICON, brighter(ABIL3_COLOR, 3.0), MSG_ONE, _, iPlayer)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_RIBS_START, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public efk_reflection_end(iPlayer, bool:bIsDeath)
{
	reflection_ribs_kill(iPlayer, bIsDeath ? 5.0 : 0.0)

	send_msg_StatusIcon(false, ABIL3_ICON, _, MSG_ONE, _, iPlayer)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_RIBS_END, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public efk_reflection(iPlayer)
{
	send_msg_ScreenFade((1<<12), (1<<8), (1<<4), brighter(ABIL3_COLOR, 3.0), 150, MSG_ONE, _, iPlayer)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_RIBS_CATCH, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public efk_freeze(iPlayer)
{
	if (g_playerHasKnife[iPlayer])
		kc_player_set_abil1_dist(iPlayer, 65.0)
}

public efk_unfreeze(iPlayer)
{
	if (g_playerHasKnife[iPlayer])
		kc_player_set_abil1_dist(iPlayer)
}

public efk_disenergy(iPlayer)
{
	if (kc_player_get_concentblock(iPlayer))
	{
		kc_player_set_concentblock(iPlayer, 0)
		play_unconcentblock_anim(iPlayer)
	}
}

public efk_concentblock_timeout(iPlayer)
{
	play_unconcentblock_anim(iPlayer)
}

reflection_ribs_create(iPlayer)
{
	new iEnt = rg_create_entity("info_target")
	if (is_nullent(iEnt))
		return NULLENT

	engfunc(EngFunc_SetModel, iEnt, MODEL_REFLECTOR)

	set_entvar(iEnt, var_solid, SOLID_NOT)
	set_entvar(iEnt, var_movetype, MOVETYPE_FOLLOW)

	set_entvar(iEnt, var_owner, iPlayer)
	set_entvar(iEnt, var_aiment, iPlayer)

	set_entvar(iEnt, var_renderfx, kRenderFxGlowShell)
	set_entvar(iEnt, var_rendercolor, ABIL3_COLOR_VEC)
	set_entvar(iEnt, var_renderamt, 0.0)

	SetThink(iEnt, "reflection_ribs_think")

	if (g_playerReflectionRibs[iPlayer])
		rg_remove_entity(g_playerReflectionRibs[iPlayer])

	g_playerReflectionRibs[iPlayer] = iEnt

	return iEnt
}

reflection_ribs_kill(iPlayer, Float:fTimeout = 0.0)
{
	new iEnt = g_playerReflectionRibs[iPlayer]
	if (!iEnt)
		return

	set_entvar(iEnt, var_renderfx, kRenderFxNone)
	set_entvar(iEnt, var_nextthink, get_gametime() + fTimeout)
}

public reflection_ribs_think(iEnt)
{
	new iOwner = get_entvar(iEnt, var_owner)
	g_playerReflectionRibs[iOwner] = 0

	rg_remove_entity(iEnt)
}

brighter(const ivColor[3], Float:fMul)
{
	static ivRes[3]
	ivRes[0] = floatround(floatmin(ivColor[0] * fMul, 255.0))
	ivRes[1] = floatround(floatmin(ivColor[1] * fMul, 255.0))
	ivRes[2] = floatround(floatmin(ivColor[2] * fMul, 255.0))

	return ivRes
}

play_unconcentblock_anim(iPlayer)
{
	new iItem = get_member(iPlayer, m_pActiveItem)
	if (is_nullent(iItem))
		return

	set_member(iItem, m_Weapon_flTimeWeaponIdle, 0.5)
	kc_player_set_view_anim(iPlayer, VIEW_SEQ_UNCONCENTRATION)
}
