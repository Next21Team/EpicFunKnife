#if defined _efk_tornado_utils_included
  #endinput
#endif
#define _efk_tornado_utils_included

#include <efk_const>

/**
 * Set the tornado on fire
 *
 * @param 	iEnt			- Tornado entity
 * @noreturn
 */
stock tornado_burn(const iEnt)
{
	if (get_entvar(iEnt, var_body) != 1)
	{
		set_entvar(iEnt, var_body, 1)
		set_entvar(iEnt, var_skin, get_entvar(iEnt, var_skin) + 3)
		engfunc(EngFunc_EmitSound, iEnt, CHAN_AUTO, SOUND_TORNADO_FLAME, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}
