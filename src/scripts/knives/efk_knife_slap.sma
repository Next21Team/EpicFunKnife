#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Slap Knife"

#define KNIFE_CLASSNAME "weapon_next21_slap"
#define KNIFE_MENUDESC  "KNIFE_SLAP_DESC"
#define KNIFE_CHATDESC  "KNIFE_SLAP_CHAT"

#define HP				90.0
#define GRAVITY			1.0
#define SPEED			210.0
#define MINDAMAGE		10.0
#define MAXDAMAGE		25.0

#define ABIL1_NAME		"Slap"
#define ABIL1_CHARGE	7.143

#define ABIL2_NAME		"Disenergy Sphere"
#define ABIL2_CHARGE	14.286

#define ABIL3_NAME		"Trap Field"
#define ABIL3_CHARGE	10.0

#define START_CRIT_CHANCE	2.77
#define CON_CRIT_CHANCE		4.54
#define LIMIT_CRIT_CHANCE	40.0
#define ADD_CRIT_CHANCE		2.0

#define SLAP_DAMAGE_MIN		30
#define SLAP_DAMAGE_MAX		42
#define SLAP_PUSH_FORCE		2000.0

#define FILED_LIFE			7.0
#define FIELD_HEIGHT		75.0
#define FIELD_CREATE_TIME	0.7

#define DISENERGY_RADIUS	300.0

new const MODEL_V_KNIFE[]	= "models/next21_efk/v_slap_knife_b04.mdl"
new const MODEL_P_KNIFE[]	= "models/next21_efk/p_slap_knife_a.mdl"
new const MODEL_SPHERE[]	= "models/next21_efk/disenergy_sphere.mdl"
new const MODEL_FIELD[]		= "models/next21_efk/field_v2.mdl"

new const SOUND_KNIFE_HIT1[]	= "next21_efk/slap_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[]	= "next21_efk/slap_knife_hit2.wav"
new const SOUND_KNIFE_HITWALL[]	= "next21_efk/slap_knife_hitwall1.wav"

new const SOUND_SLAP[]				= "next21_efk/slap_ativation.wav"
new const SOUND_SPHERE[]			= "next21_efk/disenergy_sphere.wav"
new const SOUND_FIELD_ACTIVATION[]	= "next21_efk/field_activation.wav"

new const CLASSNAME_DISENERGY_SPHERE[]	= "next21_disenergy"
new const CLASSNAME_FIELD_BASE[] 		= "next21_field_base"
new const _CLASSNAME_FIELD_PART[]		= CLASSNAME_FIELD_PART

new const SZ_INFO_TARGET[]	= "info_target"
new const SZ_GRENADE[]		= "grenade"

new const COLOR_CRIT[] = {255, 0, 0}
new const COLOR_SLAP[] = {102, 0, 255}

new const SOUNDS_CRIT[][] =
{
	"next21_efk/frash_explosion01.wav",
	"next21_efk/frash_explosion02.wav",
	"next21_efk/frash_explosion03.wav"
}

new const SOUNDS_SPARK[][] =
{
	"buttons/spark1.wav",
	"buttons/spark2.wav",
	"buttons/spark3.wav",
	"buttons/spark4.wav",
	"buttons/spark5.wav",
	"buttons/spark6.wav"
}

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_ABILITY2
}

enum _:FieldSeq
{
	FIELD_SEQ_CREATE,
	FIELD_SEQ_IDLE
}

enum _:PlayerData
{
	Knife,
	Float:CritChance
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
	g_pKnifeVStr, g_pKnifePMdl,
	g_pCircleSpr

public plugin_precache()
{
	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(MODEL_SPHERE)
	precache_model(MODEL_FIELD)

	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_HITWALL)

	precache_sound(SOUND_SLAP)
	precache_sound(SOUND_SPHERE)
	precache_sound(SOUND_FIELD_ACTIVATION)

	for (new i; i < sizeof SOUNDS_CRIT; i++)
		precache_sound(SOUNDS_CRIT[i])

	for (new i; i < sizeof SOUNDS_SPARK; i++)
		precache_sound(SOUNDS_SPARK[i])

	g_pCircleSpr = precache_model("sprites/shadow_circle.spr")

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		g_pKnifeVStr, engfunc(EngFunc_AllocString, MODEL_P_KNIFE),
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, ABIL1_CHARGE)
	kc_register_ability2(g_iKnifeId, ABIL2_NAME, ABIL2_CHARGE)
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)

	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_AXE)
	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLEABLE | KNFF_BAN_BUNNYHOP)

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Post", true)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][Knife] = -1
	Player[iPlayer][CritChance] = START_CRIT_CHANCE
}

public client_disconnected(iPlayer)
{
	new iEnt

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_FIELD_BASE)))
		if (get_entvar(iEnt, var_owner) == iPlayer)
			rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_FIELD_PART)))
		if (get_entvar(iEnt, var_owner) == iPlayer)
			rg_remove_entity(iEnt)
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_FIELD_BASE)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_FIELD_PART)))
		rg_remove_entity(iEnt)
}

public RG_CBasePlayer_Killed_Post(iVictim, iAttacker)
{
	if (!is_entity_player(iAttacker))
		return HC_CONTINUE

	if (iAttacker == iVictim)
		return HC_CONTINUE

	if (Player[iAttacker][Knife] != g_iKnifeId)
		return HC_CONTINUE

	if (Player[iAttacker][CritChance] >= LIMIT_CRIT_CHANCE)
	{
		Player[iAttacker][CritChance] = CON_CRIT_CHANCE
		kc_player_set_crit_chance(iAttacker, CON_CRIT_CHANCE)
	}
	else
	{
		Player[iAttacker][CritChance] = koef_to_chance(chance_to_koef(Player[iAttacker][CritChance]) - ADD_CRIT_CHANCE)
		kc_player_set_crit_chance(iAttacker, Player[iAttacker][CritChance])
	}

	return HC_CONTINUE
}

public disenergy_sphere_think(iEnt)
{
	rg_remove_entity(iEnt)
}

public field_base_think(iEnt)
{
	if (get_entvar(iEnt, var_sequence) == FIELD_SEQ_CREATE)
	{
		new Float:fGameTime = get_gametime()
		new iOwner = get_entvar(iEnt, var_owner)
		new iSkin = get_entvar(iEnt, var_skin)

		new Float:vOrigin[3]
		get_entvar(iEnt, var_origin, vOrigin)

		set_entvar(iEnt, var_body, 0b1111)
		set_entvar(iEnt, var_sequence, FIELD_SEQ_IDLE)
		set_entvar(iEnt, var_framerate,  1.0)
		set_entvar(iEnt, var_animtime, fGameTime)
		set_entvar(iEnt, var_nextthink, fGameTime + FILED_LIFE)

		new iFieldPartEnts[4]
		for (new i = 0, iPartEnt; i < 4; i++)
		{
			iPartEnt = rg_create_entity(SZ_INFO_TARGET)

			engfunc(EngFunc_SetOrigin, iPartEnt, vOrigin)

			set_entvar(iPartEnt, var_origin, vOrigin)
			set_entvar(iPartEnt, var_movetype, MOVETYPE_FLY)
			set_entvar(iPartEnt, var_solid, SOLID_TRIGGER)
			set_entvar(iPartEnt, var_rendermode, kRenderNormal)
			set_entvar(iPartEnt, var_classname, _CLASSNAME_FIELD_PART)
			set_entvar(iPartEnt, var_impulse, IMPULSE_FIELD_WALL)
			set_entvar(iPartEnt, var_owner, iOwner)
			set_entvar(iPartEnt, var_skin, iSkin)
			set_entvar(iPartEnt, var_nextthink, fGameTime + FILED_LIFE)
			set_entvar(iPartEnt, var_aiment, iEnt)
			set_entvar(iPartEnt, var_fieldside, i)

			SetThink(iPartEnt, "field_part_think")
			SetTouch(iPartEnt, "field_part_touch")

			iFieldPartEnts[i] = iPartEnt
		}

		engfunc(EngFunc_SetSize, iFieldPartEnts[0], Float:{-100.0, -90.0, 0.0}, Float:{-80.0, 90.0, FIELD_HEIGHT})
		engfunc(EngFunc_SetSize, iFieldPartEnts[1], Float:{80.0, -90.0, 0.0}, Float:{100.0, 90.0, FIELD_HEIGHT})
		engfunc(EngFunc_SetSize, iFieldPartEnts[2], Float:{-90.0, -100.0, 0.0}, Float:{90.0, -80.0, FIELD_HEIGHT})
		engfunc(EngFunc_SetSize, iFieldPartEnts[3], Float:{-90.0, 80.0, 0.0}, Float:{90.0, 100.0, FIELD_HEIGHT})
	}
	else
	{
		rg_remove_entity(iEnt)
	}
}

public field_part_think(iEnt)
{
	rg_remove_entity(iEnt)
}

public field_part_touch(iEnt, iOther)
{
	if (!is_entity(iOther))
		return HC_CONTINUE

	static Float:vEntVector[3], Float:vOtherVector[3], iOwner

	if (is_entity_player(iOther))
	{
		if (is_user_alive(iOther) && get_entvar(iEnt, var_skin) + 1 != get_member(iOther, m_iTeam))
		{
			get_entvar(get_entvar(iEnt, var_aiment), var_origin, vEntVector)
			get_entvar(iOther, var_origin, vOtherVector)

			if (vOtherVector[0] > vEntVector[0] - 90.0
				&& vOtherVector[1] > vEntVector[1] - 90.0
				&& vOtherVector[0] < vEntVector[0] + 90.0
				&& vOtherVector[1] < vEntVector[1] + 90.0)
			{
				xs_vec_sub(vEntVector, vOtherVector, vOtherVector)
			}
			else
			{
				xs_vec_sub(vOtherVector, vEntVector, vOtherVector)
			}

			vOtherVector[0] *= 2.0
			vOtherVector[1] *= 2.0
			vOtherVector[2] = -110.0

			set_entvar(iOther, var_velocity, vOtherVector)
		}
	}
	else
	{
		switch (get_entvar(iOther, var_impulse))
		{
			case IMPULSE_ICICLE, IMPULSE_ZOMBIE_SPIT:
			{
				iOwner = get_entvar(iOther, var_owner)
				if (is_user_connected(iOwner) && get_entvar(iEnt, var_skin) + 1 != get_member(iOwner, m_iTeam))
					rg_remove_entity(iOther)
			}
			case IMPULSE_BUG, IMPULSE_ZOMBIE:
			{
				if (get_entvar(iEnt, var_skin) != get_entvar(iOther, var_skin))
				{
					get_entvar(iOther, var_velocity, vOtherVector)
					xs_vec_neg(vOtherVector, vOtherVector)
					set_entvar(iOther, var_velocity, vOtherVector)

					get_entvar(iOther, var_angles, vOtherVector)
					xs_vec_neg(vOtherVector, vOtherVector)
					set_entvar(iOther, var_angles, vOtherVector)
				}
			}
			case IMPULSE_RAZOR_SPHERE:
			{
				iOwner = get_entvar(iOther, var_owner)
				if (is_entity_player(iOwner) && get_entvar(iEnt, var_skin) + 1 != get_member(iOwner, m_iTeam))
				{
					get_entvar(iOther, var_velocity, vOtherVector)
					xs_vec_neg(vOtherVector, vOtherVector)
					set_entvar(iOther, var_velocity, vOtherVector)

					get_entvar(iOther, var_angles, vOtherVector)
					xs_vec_neg(vOtherVector, vOtherVector)
					set_entvar(iOther, var_angles, vOtherVector)
				}
			}
			case IMPULSE_EMBODIMENT:
			{
				iOwner = get_entvar(iOther, var_owner)
				if (is_user_connected(iOwner) && get_entvar(iEnt, var_skin) + 1 != get_member(iOwner, m_iTeam))
				{
					get_entvar(iOther, var_velocity, vOtherVector)
					new Float:fSpeed = xs_vec_len(vOtherVector)

					vOtherVector[0] = 0.0
					vOtherVector[1] = 0.0
					vOtherVector[2] = fSpeed
					set_entvar(iOther, var_velocity, vOtherVector)

					vector_to_angle(vOtherVector, vOtherVector)
					set_entvar(iOther, var_angles, vOtherVector)
				}
			}
			case IMPULSE_KUNAI:
			{
				iOwner = get_entvar(iOther, var_owner)
				if (is_user_connected(iOwner) && get_entvar(iEnt, var_skin) + 1 != get_member(iOwner, m_iTeam))
				{
					set_entvar(iOther, var_solid, SOLID_NOT)
					set_entvar(iOther, var_nextthink, get_gametime())
				}
			}
			default:
			{
				if (FClassnameIs(iOther, SZ_GRENADE))
				{
					if (get_entvar(iEnt, var_skin) + 1 != get_member(iOther, m_Grenade_iTeam))
					{
						get_entvar(iOther, var_velocity, vOtherVector)
						vOtherVector[0] = -vOtherVector[0]
						vOtherVector[1] = -vOtherVector[1]
						vOtherVector[2] = floatabs(vOtherVector[2])
						set_entvar(iOther, var_velocity, vOtherVector)
					}
				}
			}
		}
	}

	return HC_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][Knife] = iKnifeId
	if (iKnifeId == g_iKnifeId)
		kc_player_set_crit_chance(iPlayer, Player[iPlayer][CritChance])
}

public efk_ability(iPlayer)
{
	new Float:vOrigin[3], Float:vAxis[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	xs_vec_copy(vOrigin, vAxis)

	new bool:bIsCrit = random_float(0.0, 100.0) <= Player[iPlayer][CritChance]
	new iTeam = get_member(iPlayer, m_iTeam)

	if (bIsCrit)
	{
		send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, g_pCircleSpr, 0, 0, 4, 49, 0, COLOR_CRIT, 255, 0, MSG_PAS, vOrigin)

		vAxis[2] += 20.0
		send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, g_pCircleSpr, 0, 0, 4, 49, 0, COLOR_CRIT, 255, 0, MSG_PAS, vOrigin)

		vAxis[2] += 20.0
		send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, g_pCircleSpr, 0, 0, 4, 49, 0, COLOR_CRIT, 255, 0, MSG_PAS, vOrigin)
	}
	else
	{
		vAxis[2] += 220.0
		send_msg_TE_BEAMCYLINDER(vOrigin, vAxis, g_pCircleSpr, 0, 0, 4, 49, 0, COLOR_SLAP, 255, 0, MSG_PAS, vOrigin)
	}

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SLAP, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new Float:vVelocity[3], Float:vTargetOrigin[3], Float:fDistance, Float:fNewSpeed
	new Float:fRadius = bIsCrit ? 250.0 : 150.0

	new iTarget = NULLENT
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, fRadius)))
	{
		if (iTarget == iPlayer)
			continue

		if (is_user_alive(iTarget)
			&& iTeam != get_member(iTarget, m_iTeam)
			&& !kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
		{
			kc_player_set_override_attacker(iTarget, iPlayer, 4.0)

			get_entvar(iTarget, var_origin, vTargetOrigin)

			fDistance = get_distance_f(vOrigin, vTargetOrigin)
			fNewSpeed = SLAP_PUSH_FORCE * (1.0 - (fDistance / fRadius))
			get_speed_vector(vOrigin, vTargetOrigin, fNewSpeed, vVelocity)
			vVelocity[2] = 400.0
			set_entvar(iTarget, var_velocity, vVelocity)

			new Float:fDamage

			if (bIsCrit && kc_player_try_crit(iTarget, iPlayer))
			{
				fDamage = 2000.0

				engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
				send_msg_TE_LAVASPLASH(vTargetOrigin)
			}
			else
			{
				fDamage = float(random_num(SLAP_DAMAGE_MIN, SLAP_DAMAGE_MAX))
			}

			kc_player_set_death_reason(iTarget, "DEATH_REASON_ENERGY_WAVE")
			set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
			ExecuteHamB(Ham_TakeDamage, iTarget, iPlayer, iPlayer, fDamage, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
		}
		else
		{
			if ((get_entvar(iTarget, var_flags) & FL_MONSTER) && iTeam != get_entvar(iTarget, var_skin) + 1)
			{
				get_entvar(iTarget, var_origin, vTargetOrigin)

				fDistance = get_distance_f(vOrigin, vTargetOrigin)
				fNewSpeed = SLAP_PUSH_FORCE * (1.0 - (fDistance / fRadius))
				get_speed_vector(vOrigin, vTargetOrigin, fNewSpeed, vVelocity)
				vVelocity[2] = 400.0
				set_entvar(iTarget, var_velocity, vVelocity)

				ExecuteHamB(Ham_TakeDamage, iTarget, 0, iTarget, bIsCrit ? 500.0 : 50.0, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
			}
		}
	}

	return PLUGIN_CONTINUE
}

public efk_ability2(iPlayer)
{
	new iSphereEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iSphereEnt))
		return PLUGIN_HANDLED

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	new Float:vAngles[3]
	get_entvar(iPlayer, var_v_angle, vAngles)

	new Float:fGameTime = get_gametime()
	new iTeam = get_member(iPlayer, m_iTeam)

	set_entvar(iSphereEnt, var_origin, vOrigin)
	set_entvar(iSphereEnt, var_angles, vAngles)
	set_entvar(iSphereEnt, var_classname, CLASSNAME_DISENERGY_SPHERE)

	engfunc(EngFunc_SetModel, iSphereEnt, MODEL_SPHERE)
	engfunc(EngFunc_SetSize, iSphereEnt, Float:{-300.0, -300.0, -300.0}, Float:{300.0, 300.0, 300.0})

	set_entvar(iSphereEnt, var_rendermode, kRenderTransAlpha)
	set_entvar(iSphereEnt, var_renderamt, 80.0)

	set_entvar(iSphereEnt, var_framerate, 1.0)
	set_entvar(iSphereEnt, var_animtime, fGameTime)
	set_entvar(iSphereEnt, var_frame, 0.0)
	set_entvar(iSphereEnt, var_sequence, 0)

	set_entvar(iSphereEnt, var_nextthink, fGameTime + 0.3)

	SetThink(iSphereEnt, "disenergy_sphere_think")

	engfunc(EngFunc_EmitSound, iSphereEnt, CHAN_AUTO, SOUND_SPHERE, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new iTarget = NULLENT, iTargetOwner, iTargetImpulse
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, DISENERGY_RADIUS)))
	{
		if (iTarget == iPlayer)
			continue

		if (is_entity_player(iTarget))
		{
			if (is_user_alive(iTarget) && iTeam != get_member(iTarget, m_iTeam) && get_entvar(iTarget, var_solid))
				kc_player_disenergy(iTarget)
		}
		else
		{
			iTargetImpulse = get_entvar(iTarget, var_impulse)
			switch (iTargetImpulse)
			{
				case IMPULSE_ICICLE, IMPULSE_ZOMBIE_SPIT, IMPULSE_ACIDB, IMPULSE_EMBODIMENT:
				{
					iTargetOwner = get_entvar(iTarget, var_owner)
					if (is_user_connected(iTargetOwner) && iTeam != get_member(iTargetOwner, m_iTeam))
						rg_remove_entity(iTarget)
				}
				case IMPULSE_WIND_WAVE:
				{
					if (iTeam != get_entvar(iTarget, var_team))
						rg_remove_entity(iTarget)
				}
				case IMPULSE_GHOST:
				{
					iTargetOwner = get_entvar(iTarget, var_owner)
					if (iTeam != get_entvar(iTarget, var_team))
						kc_player_set_capture(iTargetOwner, CAPTURE_NONE)
				}
				case IMPULSE_RAZOR_SPHERE:
				{
					iTargetOwner = get_entvar(iTarget, var_owner)
					if (is_entity_player(iTargetOwner) && iTeam != get_member(iTargetOwner, m_iTeam))
					{
						set_entvar(iTarget, var_owner, iPlayer)
						set_entvar(iTarget, var_damage_sphere, 0)
						set_entvar(iTarget, var_nextthink, get_gametime())
					}
				}
				case IMPULSE_LASER, IMPULSE_THUNDER_STRIKE_BEAM:
				{
					iTargetOwner = get_entvar(iTarget, var_owner)
					if (is_user_connected(iTargetOwner) && iTeam != get_member(iTargetOwner, m_iTeam))
					{
						new iCrosshairEnt = get_entvar(iTarget, var_crosshair)
						set_entvar(iCrosshairEnt, var_skin, iTeam - 1)

						new Float:vOwnerOrigin[3]
						get_entvar(iTargetOwner, var_origin, vOwnerOrigin)

						if (iTargetImpulse != IMPULSE_THUNDER_STRIKE_BEAM)
							get_floor_origin(iTarget, vOwnerOrigin, vOwnerOrigin)

						engfunc(EngFunc_SetOrigin, iTarget, vOwnerOrigin)
						engfunc(EngFunc_SetOrigin, iCrosshairEnt, vOwnerOrigin)

						vOwnerOrigin[2] += 500.0
						set_entvar(iTarget, var_angles, vOwnerOrigin)
						set_entvar(iTarget, var_owner, iPlayer)
					}
				}
				case IMPULSE_SPIKES:
				{
					if (get_entvar(iTarget, var_sequence) == 1)
					{
						iTargetOwner = get_entvar(iTarget, var_owner)
						if (is_user_connected(iTargetOwner) && iTeam != get_member(iTargetOwner, m_iTeam))
							rg_remove_entity(iTarget)
					}
				}
				case IMPULSE_ICE_CLONE:
				{
					if (iTeam != get_entvar(iTarget, var_team))
					{
						set_entvar(iTarget, var_owner, iPlayer)
						set_entvar(iTarget, var_team, iTeam)

						new iCloneShell = get_entvar(iTarget, var_iceclone_shell)
						if (!is_nullent(iCloneShell))
							set_entvar(iCloneShell, var_skin, get_entvar(iPlayer, var_skin))

						new iClonePart = NULLENT
						while ((iClonePart = rg_find_ent_by_class(iClonePart, CLASSNAME_ICE_CLONE_PART)))
							if (get_entvar(iClonePart, var_aiment) == iTarget)
								set_entvar(iClonePart, var_owner, iPlayer)
					}
				}
				case IMPULSE_KUNAI:
				{
					iTargetOwner = get_entvar(iTarget, var_owner)
					if (is_user_connected(iTargetOwner) && iTeam != get_member(iTargetOwner, m_iTeam))
					{
						set_entvar(iTarget, var_solid, SOLID_NOT)
						set_entvar(iTarget, var_nextthink, get_gametime())
					}
				}
				case IMPULSE_ACIDTRAP:
				{
					if (iTeam != get_entvar(iTarget, var_skin) + 1)
					{
						set_entvar(iTarget, var_owner, iPlayer)
						set_entvar(iTarget, var_skin, iTeam - 1)

						ExecuteHamB(Ham_Use, iTarget, iPlayer, iPlayer, USE_SET, 1.0)
					}
				}
				default:
				{
					if (FClassnameIs(iTarget, SZ_GRENADE))
					{
						if (iTeam != get_member(iTarget, m_Grenade_iTeam))
						{
							set_entvar(iTarget, var_nextthink, fGameTime + 10.0)
							set_entvar(iTarget, var_velocity, NULL_VECTOR)
							set_entvar(iTarget, var_nade_touch, 0)

							engfunc(EngFunc_EmitSound, iTarget, CHAN_AUTO, SOUNDS_SPARK[random(sizeof SOUNDS_SPARK)], 1.0, ATTN_NORM, 0, PITCH_NORM)

							new Float:vTargetOrigin[3]
							get_entvar(iTarget, var_origin, vTargetOrigin)

							set_entvar(iTarget, var_owner, iPlayer)
							set_member(iTarget, m_Grenade_iTeam, iTeam)

							send_msg_TE_SPARKS(vTargetOrigin)
						}
					}
				}
			}
		}
	}

	if (pev(iPlayer, pev_viewmodel) == g_pKnifeVStr)
	{
		new iItem = get_member(iPlayer, m_pActiveItem)
		if (!is_nullent(iItem))
		{
			set_member(iItem, m_Weapon_flNextPrimaryAttack, 1.1)
			set_member(iItem, m_Weapon_flTimeWeaponIdle, 1.1)
			kc_player_set_view_anim(iPlayer, VIEW_SEQ_ABILITY2)
		}
	}

	return PLUGIN_CONTINUE
}

public efk_ability3(iPlayer)
{
	new iEnt = rg_create_entity(SZ_INFO_TARGET)

	if (!is_entity(iEnt))
		return PLUGIN_HANDLED

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	new iFlags = get_entvar(iPlayer, var_flags)
	new Float:fGameTime = get_gametime()

	if (!(iFlags & FL_ONGROUND) || (!(iFlags & FL_DUCKING) && (get_entvar(iPlayer, var_button) & IN_DUCK)))
		get_floor_origin(iEnt, vOrigin, vOrigin)
	else
		vOrigin[2] -= (iFlags & FL_DUCKING) ? 18.0 : 36.0

	engfunc(EngFunc_SetModel, iEnt, MODEL_FIELD)
	engfunc(EngFunc_SetSize, iEnt, Float:{-90.0, -90.0, 0.0}, Float:{90.0, 90.0, 75.0})
	engfunc(EngFunc_SetOrigin, iEnt, vOrigin)

	set_entvar(iEnt, var_origin, vOrigin)
	set_entvar(iEnt, var_owner, iPlayer)
	set_entvar(iEnt, var_skin, get_member(iPlayer, m_iTeam) - 1)
	set_entvar(iEnt, var_sequence, FIELD_SEQ_CREATE)
	set_entvar(iEnt, var_framerate,  1.5)
	set_entvar(iEnt, var_animtime, fGameTime)
	set_entvar(iEnt, var_classname, CLASSNAME_FIELD_BASE)
	set_entvar(iEnt, var_impulse, IMPULSE_FIELD)
	set_entvar(iEnt, var_nextthink, fGameTime + FIELD_CREATE_TIME)

	SetThink(iEnt, "field_base_think")

	engfunc(EngFunc_EmitSound, iEnt, CHAN_AUTO, SOUND_FIELD_ACTIVATION, 1.0, ATTN_NORM, 0, PITCH_NORM)

	kc_player_set_anim(iPlayer, PLAYER_SEQ_SHOOT_C4, PLAYER_SEQ_SHOOT_C4_CROUCH, 150.0, 0.4)

	return PLUGIN_CONTINUE
}
