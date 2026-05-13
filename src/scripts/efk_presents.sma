#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Presents"

new const GAME_TAG[] = EFK_GAME_TAG

#define PRESENT_MONEY			7000
#define PRESENT_CHANCE			(!random(10))
#define ITEM_CHANCE				(random(5))

#define LEN_PRESENT_DESCRIPTION		32

new const MODEL_PRESENT[]       = "models/next21_efk/present.mdl"
new const SOUND_PRESENT[]       = "next21_efk/present_pickup.wav"

new const SZ_INFO_TARGET[]      = "info_target"

public plugin_precache()
{
	precache_model(MODEL_PRESENT)
	precache_sound(SOUND_PRESENT)
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	register_dictionary("efk_presents.txt")
}

public efk_player_death(iVictim, iAttacker, iAssistant)
{
	if (is_entity_player(iAttacker) && iAttacker != iVictim && PRESENT_CHANCE)
	{
		new Float:vOrigin[3]
		get_entvar(iVictim, var_origin, vOrigin)
		present_create(vOrigin)
	}
}

present_create(const Float:vOrigin[3])
{
	new iPresentEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iPresentEnt))
		return NULLENT

	engfunc(EngFunc_SetOrigin, iPresentEnt, vOrigin)
	engfunc(EngFunc_SetModel, iPresentEnt, MODEL_PRESENT)
	engfunc(EngFunc_SetSize, iPresentEnt, Float:{-15.0, -15.0, 0.0}, Float:{15.0, 15.0, 30.0})

	set_entvar(iPresentEnt, var_origin, vOrigin)
	set_entvar(iPresentEnt, var_classname, CLASSNAME_PRESENT)
	set_entvar(iPresentEnt, var_impulse, IMPULSE_PRESENT)
	set_entvar(iPresentEnt, var_solid, SOLID_BBOX)
	set_entvar(iPresentEnt, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iPresentEnt, var_gravity, 1.0)
	set_entvar(iPresentEnt, var_velocity, Float:{0.0, 0.0, 60.0})
	set_entvar(iPresentEnt, var_rendermode, kRenderNormal)

	set_entvar(iPresentEnt, var_skin, random(5))
	set_entvar(iPresentEnt, var_body, random(4))

	set_entvar(iPresentEnt, var_animtime, get_gametime())
	set_entvar(iPresentEnt, var_sequence, 0)
	set_entvar(iPresentEnt, var_framerate, 1.0)

	SetThink(iPresentEnt, "present_think")
	SetTouch(iPresentEnt, "present_touch")

	return iPresentEnt
}

public present_think(iPresentEnt)
{
	set_entvar(iPresentEnt, var_renderfx, kRenderFxNone)
	set_entvar(iPresentEnt, var_rendercolor, {255, 255, 255})
}

public present_touch(iPresentEnt, iOther)
{
	if (!is_entity_player(iOther))
		return HC_CONTINUE

	if (get_entvar(iPresentEnt, var_flags) & FL_KILLME)
		return HC_CONTINUE

	engfunc(EngFunc_EmitSound, iPresentEnt, CHAN_AUTO, SOUND_PRESENT, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_entvar(iPresentEnt, var_flags, FL_KILLME)

	if (get_member(iOther, m_iAccount) == MAX_PLAYER_MONEY || ITEM_CHANCE)
	{
		if (kc_player_give_random_item(iOther, IMPULSE_PRESENT) > -1)
			return HC_CONTINUE
	}

	client_print_color(iOther, print_team_default,
		"^4[%s] ^1%L ^3%L", GAME_TAG, iOther, "PRESENT_GET", iOther, "PRESENT_MONEY", PRESENT_MONEY)
	rg_add_account(iOther, PRESENT_MONEY)

	return HC_CONTINUE
}
