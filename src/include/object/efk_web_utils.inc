#if defined _efk_web_utils_included
  #endinput
#endif
#define _efk_web_utils_included

#include <efk_const>
#include <efk_utils>

stock bool:entity_in_web(iEnt, iWebEnt)
{
	static Float:vEntOrigin[3], Float:vWebOrigin[3], Float:mWebInvTr[3][3],
		Float:vEntMins[3], Float:fEpsilon, Float:fHalfHeight

	get_entvar(iWebEnt, var_invaxis_x, mWebInvTr[0])
	get_entvar(iWebEnt, var_invaxis_y, mWebInvTr[1])
	get_entvar(iWebEnt, var_invaxis_z, mWebInvTr[2])

	get_entvar(iEnt, var_origin, vEntOrigin)
	get_entvar(iEnt, var_mins, vEntMins)

	// Ideally, all the extreme points of the entity in the cylinder should be checked,
	// but for simplifications we will increase the height of the cylinder
	fEpsilon = floatsqroot(1 - mWebInvTr[2][2] * mWebInvTr[2][2]) * floatsqroot(vEntMins[0] * vEntMins[0] + vEntMins[1] * vEntMins[1])

	get_entvar(iWebEnt, var_origin, vWebOrigin)
	vWebOrigin[2] -= WEB_OFFSET
	fHalfHeight = WEB_HEIGHT + fEpsilon - vEntMins[2]

	return point_in_cylinder(vEntOrigin, vWebOrigin, WEB_RADIUS, fHalfHeight * 2.0, mWebInvTr)
}

stock bool:entity_in_any_web(iEnt)
{
	static Float:vEntMins[3], Float:vEntMaxs[3],
		Float:vWebMins[3], Float:vWebMaxs[3]

	get_entvar(iEnt, var_absmin, vEntMins)
	get_entvar(iEnt, var_absmax, vEntMaxs)

	new iWebEnt = NULLENT
	while ((iWebEnt = rg_find_ent_by_class(iWebEnt, CLASSNAME_WEB)))
	{
		get_entvar(iWebEnt, var_absmin, vWebMins)
		get_entvar(iWebEnt, var_absmax, vWebMaxs)

		if (boxes_intersect(vEntMins, vEntMaxs, vWebMins, vWebMaxs))
			if (entity_in_web(iEnt, iWebEnt))
				return true
	}

	return false
}
