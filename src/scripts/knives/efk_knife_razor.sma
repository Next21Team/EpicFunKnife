#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <beams>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Razor Knife"

#define KNIFE_CLASSNAME "weapon_next21_razor"
#define KNIFE_MENUDESC  "KNIFE_RAZOR_DESC"
#define KNIFE_CHATDESC  "KNIFE_RAZOR_CHAT"

#define HP				90.0
#define GRAVITY			1.0
#define SPEED			270.0
#define MINDAMAGE		5.0
#define MAXDAMAGE		10.0

#define KNIFE_LEVEL     1

#define ABIL1_NAME		"Razor"
#define ABIL1_CHARGE	6.25
#define ABIL1_TYPE		ABIL_TARGET_ENEMY
#define ABIL1_MINDIST	75.0
#define ABIL1_MAXDIST	400.0

#define ABIL2_NAME		"Power Release"
#define ABIL2_CHARGE	25.0

#define ABIL3_NAME		"Power Punch"
#define ABIL3_CHARGE	7.69

#define ABIL2_MIN_POWER_SPEED		0.0
#define ABIL2_MIN_SPEED			10

#define ABIL3_FORCE					650
#define ABIL3_RED_COLOR				{219, 15, 43}
#define ABIL3_GREEN_COLOR			{44, 227, 57}
#define ABIL3_SCREENSHAKE_RADIUS	150.0
#define ABIL3_SCREENSHAKE_VELOCITY	400.0
#define ABIL3_FALLDMGDIVIDER		9.0
#define ABIL3_SLOW_MUL				0.5
#define ABIL3_SLOW_TIME				2.5

new const MODEL_V_KNIFE[]		= "models/next21_efk/v_razor_knife_b02.mdl"
new const MODEL_P_KNIFE[]		= "models/next21_efk/p_razor_knife_r2.mdl"

new const MODEL_BEAM[]			= "sprites/next21_efk/razorbeam.spr"

new const MODEL_SPHERE[]			= "sprites/next21_efk/energysphere.spr"
new const MODEL_SPHERE_EXPLOSION[]	= "sprites/next21_efk/sphere_explosion.spr"

new const SOUND_KNIFE_HIT1[]	= "next21_efk/razor_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[]	= "next21_efk/razor_knife_hit2.wav"
new const SOUND_KNIFE_HIT3[]	= "next21_efk/razor_knife_hit3.wav"
new const SOUND_KNIFE_HITWALL[]	= "next21_efk/razor_knife_hitwall1.wav"
new const SOUND_KNIFE_SLASH1[]	= "next21_efk/razor_knife_slash1.wav"
new const SOUND_KNIFE_SLASH2[]	= "next21_efk/razor_knife_slash2.wav"
new const SOUND_KNIFE_DEPLOY[]	= "next21_efk/razor_knife_deploy.wav"

new const SOUND_STEAL_START[]		= "next21_efk/razor_start.wav"
new const SOUND_STEAL_LOOP[]		= "next21_efk/razor_steal.wav"
new const SOUND_STEAL_END[]			= "next21_efk/razor_end.wav"

new const SOUND_PUNCH[]				= "next21_efk/razor_punch.wav"
new const SOUND_JUMP[]				= "next21_efk/razor_jump.wav"

new const SOUND_SPHERE_EXPLOSION[]	= "next21_efk/energy_explosion.wav"

new const CLASSNAME_RAZOR_SPHERE[]	= "next21_razor_sphere"
new const CLASSNAME_SPHERE_SHELL[]	= "next21_razor_sphere_sh"

#define MIN_POWER_SPEED_STEAL		-80.0

#define SPHERE_MAXSPEED				1300.0
#define SPHERE_STEAL_SPEED			12
#define SPHERE_LIFETIME				14.0
#define SPHERE_RADIUS_EXPLOSION		200.0
#define SPHERE_CORRECTION_DELAY		1.25

#define DEATH_STEAL_RADIUS			300.0
#define DEATH_STEAL_CAP				50.0
#define DEATH_STEAL_MAX_ADDITION	20.0
#define DEATH_STEAL_MIN_ADDITION	5.0

#define var_sphere_shell			var_iuser3
#define var_sphere_power			var_damage_sphere

new const SZ_DMG_SHOCK[]	= "dmg_shock"
new const SZ_ENV_SPRITE[]	= "env_sprite"

new const SOUNDS_SPHERE_BOUNCE[2][] = {
	"next21_efk/energy_bounce1.wav",
	"next21_efk/energy_bounce2.wav"
}

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_SHOOT
}

enum _:PlayerData
{
	bool:PlrIsAlive,
	PlrKnife,
	PlrTeam,
	PlrStealingTarget,
	Float:PlrStolenSpeed[MAX_PLAYERS + 1],
	bool:PlrInPush,
	Float:PlrStealDelay,
	Float:PlrCorrectionDelay,
	Float:PlrStartSpeed,
	Float:PlrPushSpeed,
	Float:PlrLastVelocity[3],
	PlrRazorBeam,
	PlrSphereEnt
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId,
	g_ePlayerData[MAX_PLAYERS][PlayerData],
	g_pExplosionSpr, g_pBeamSpr, g_pRockGibsMdl,
	g_pKnifeVStr, g_pKnifePMdl

public plugin_precache()
{
	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_HIT3)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)
	precache_sound(SOUND_KNIFE_DEPLOY)

	precache_sound(SOUND_STEAL_START)
	precache_sound(SOUND_STEAL_LOOP)
	precache_sound(SOUND_STEAL_END)

	g_pBeamSpr = precache_model(MODEL_BEAM)
	g_pRockGibsMdl = precache_model("models/rockgibs.mdl")
	g_pExplosionSpr = precache_model(MODEL_SPHERE_EXPLOSION)

	for (new i; i < sizeof SOUNDS_SPHERE_BOUNCE; i++)
		precache_sound(SOUNDS_SPHERE_BOUNCE[i])

	precache_sound(SOUND_PUNCH)
	precache_sound(SOUND_JUMP)

	precache_model(MODEL_SPHERE)
	precache_sound(SOUND_SPHERE_EXPLOSION)

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

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, ABIL1_CHARGE, ABIL1_TYPE, ABIL1_MINDIST, ABIL1_MAXDIST)
	kc_register_ability2(g_iKnifeId, ABIL2_NAME, ABIL2_CHARGE)
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)

	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_DUAL_KNIVES)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT3)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Post", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Pre")

	RegisterHam(Ham_TraceAttack, "player", "Ham_PlayerTraceAttack_Pre")
	RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage_Pre")
	RegisterHam(Ham_TakeDamage, "env_explosion", "Ham_EnvExplosionTakeDamage_Post", true)

	register_impulse(100, "fw_PlayerFlashlight")
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
}

public client_disconnected(iPlayer)
{
	if (Player[iPlayer][PlrStealingTarget])
		out_stealing(iPlayer, Player[iPlayer][PlrStealingTarget])

	for (new iTarget = 1; iTarget <= MaxClients; iTarget++)
	{
		if (Player[iTarget][PlrStealingTarget] == iPlayer)
			out_stealing(iTarget, iPlayer)

		return_stolen_speed(iPlayer, iTarget)
	}

	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrTeam] = 0

	razor_punch_end(iPlayer)

	new iSphereEnt = Player[iPlayer][PlrSphereEnt]
	if (iSphereEnt && get_entvar(iSphereEnt, var_owner) == iPlayer)
		sphere_remove(iSphereEnt)
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iSphereEnt = NULLENT
	while ((iSphereEnt = rg_find_ent_by_class(iSphereEnt, CLASSNAME_RAZOR_SPHERE)))
		sphere_remove(iSphereEnt)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		if (Player[iPlayer][PlrStealingTarget])
		{
			out_stealing(iPlayer, Player[iPlayer][PlrStealingTarget])
		}
		else
		{
			for (new iTarget = 1; iTarget <= MaxClients; iTarget++)
			{
				if (Player[iTarget][PlrStealingTarget] == iPlayer)
				{
					out_stealing(iTarget, iPlayer)
					break
				}
			}
		}

		Player[iPlayer][PlrIsAlive] = true
		razor_punch_end(iPlayer)
	}
}

public RG_CBasePlayer_PreThink_Post(iPlayer)
{
	new Float:fGameTime = get_gametime()
	new iStealingTarget = Player[iPlayer][PlrStealingTarget]

	if (iStealingTarget && Player[iPlayer][PlrStealDelay] <= fGameTime)
	{
		if ((get_entvar(iPlayer, var_flags) & FL_INWATER) || (get_entvar(iStealingTarget, var_flags) & FL_INWATER)
			|| rg_entity_range(iPlayer, iStealingTarget) > ABIL1_MAXDIST + 40.0
			|| kc_player_in_silence(iPlayer)
			|| kc_player_check_game_flag(iStealingTarget, PLGF_IN_UNABILITY)
			|| kc_player_get_powerspeed(iStealingTarget) < MIN_POWER_SPEED_STEAL)
		{
			out_stealing(iPlayer, iStealingTarget)
		}
		else
		{
			if (kc_player_in_reflection(iStealingTarget))
			{
				steal_speed(iStealingTarget, iPlayer, 6.0, 6.0)
			}
			else
			{
				Player[iPlayer][PlrStolenSpeed][iStealingTarget] += 4.0
				steal_speed(iPlayer, iStealingTarget, 5.0, 4.0)
			}

			Player[iPlayer][PlrStealDelay] += 0.5
		}
	}

	new iSphereExplodeButton
	if (fGameTime < kc_player_get_swap(iPlayer))
		iSphereExplodeButton = IN_RELOAD
	else
		iSphereExplodeButton = IN_USE

	new iSphereEnt = Player[iPlayer][PlrSphereEnt]
	if (iSphereEnt)
	{
		if (get_entvar(iSphereEnt, var_owner) != iPlayer)
			Player[iPlayer][PlrSphereEnt] = 0
		else if ((get_entvar(iPlayer, var_button) & iSphereExplodeButton) && !(get_entvar(iPlayer, var_oldbuttons) & iSphereExplodeButton))
			sphere_think(iSphereEnt)
	}

	if (Player[iPlayer][PlrInPush])
	{
		static Float:vVelocity[3]
		get_entvar(iPlayer, var_velocity, vVelocity)
		vVelocity[2] = 0.0

		if (Player[iPlayer][PlrStartSpeed] - xs_vec_len(vVelocity) > 100.0 || get_entvar(iPlayer, var_flags) & FL_ONGROUND)
			razor_punch_explosion(iPlayer)

		xs_vec_copy(vVelocity, Player[iPlayer][PlrLastVelocity])
	}
}

public RG_CBasePlayer_Killed_Pre(iVictim, iAttacker)
{
	new iTarget

	if (Player[iVictim][PlrStealingTarget])
		out_stealing(iVictim, Player[iVictim][PlrStealingTarget])

	for (iTarget = 1; iTarget <= MaxClients; iTarget++)
	{
		if (Player[iTarget][PlrStealingTarget] == iVictim)
			out_stealing(iTarget, iVictim)

		return_stolen_speed(iVictim, iTarget)
	}

	new Float:vOrigin[3]
	get_entvar(iVictim, var_origin, vOrigin)
	new Float:fGameTime = get_gametime()

	iTarget = NULLENT
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, DEATH_STEAL_RADIUS)))
	{
		if (iTarget > MaxClients)
			break

		if (iTarget == iVictim || !Player[iTarget][PlrIsAlive] || Player[iTarget][PlrKnife] != g_iKnifeId)
			continue

		new Float:fPowerSpeed = kc_player_get_powerspeed(iTarget)
		if (fPowerSpeed >= DEATH_STEAL_CAP)
			fPowerSpeed += DEATH_STEAL_MIN_ADDITION
		else
			fPowerSpeed += DEATH_STEAL_MAX_ADDITION
		kc_player_set_powerspeed(iTarget, fPowerSpeed)

		if (Player[iTarget][PlrStealDelay] <= fGameTime)
			Player[iTarget][PlrStealDelay] = fGameTime + 0.5

		send_msg_TE_BEAMENTPOINT(iTarget, vOrigin, g_pBeamSpr, 0, 0, 5, 30, 30, {0, 0, 255}, 255, 15)
	}

	Player[iVictim][PlrIsAlive] = false
	razor_punch_end(iVictim)
}

public fw_PlayerFlashlight(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId || !Player[iPlayer][PlrIsAlive])
		return PLUGIN_CONTINUE

	new iSphereEnt = Player[iPlayer][PlrSphereEnt]
	if (iSphereEnt && Player[iPlayer][PlrCorrectionDelay] <= get_gametime())
	{
		new Float:vOrigin[3], Float:vEndOrigin[3]
		get_entvar(iPlayer, var_origin, vOrigin)
		get_entvar(iPlayer, var_view_ofs, vEndOrigin)
		xs_vec_add(vOrigin, vEndOrigin, vOrigin)

		get_entvar(iPlayer, var_v_angle, vEndOrigin)
		engfunc(EngFunc_MakeVectors, vEndOrigin)
		global_get(glb_v_forward, vEndOrigin)

		xs_vec_mul_scalar(vEndOrigin, 8192.0, vEndOrigin)
		xs_vec_add(vOrigin, vEndOrigin, vEndOrigin)
		engfunc(EngFunc_TraceLine, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, iPlayer, 0)
		get_tr2(0, TR_vecEndPos, vEndOrigin)
		get_entvar(iSphereEnt, var_origin, vOrigin)

		xs_vec_sub(vEndOrigin, vOrigin, vOrigin)
		xs_vec_normalize(vOrigin, vOrigin)
		xs_vec_mul_scalar(vOrigin, SPHERE_MAXSPEED, vEndOrigin)

		set_entvar(iSphereEnt, var_velocity, vEndOrigin)

		Player[iPlayer][PlrCorrectionDelay] = get_gametime() + SPHERE_CORRECTION_DELAY
	}

	return PLUGIN_HANDLED
}

public Ham_PlayerTraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vDir[3], iTraceId, iFlags)
{
	if (!(iFlags & DMG_BULLET))
		return HAM_IGNORED

	if (Player[iAttacker][PlrTeam] == Player[iVictim][PlrTeam])
		return HAM_IGNORED

	if (kc_player_check_game_flag(iVictim, PLGF_IN_UNABILITY))
		return HAM_IGNORED

	if (get_tr2(iTraceId, TR_iHitgroup) == HIT_SHIELD)
		return HAM_IGNORED

	if (Player[iAttacker][PlrKnife] == g_iKnifeId && Player[iVictim][PlrKnife] != g_iKnifeId)
	{
		Player[iAttacker][PlrStolenSpeed][iVictim] += 4.0

		kc_player_set_powerspeed(iAttacker, kc_player_get_powerspeed(iAttacker) + 4.0)
		kc_player_set_powerspeed(iVictim, kc_player_get_powerspeed(iVictim) - 4.0)

		new Float:fGameTime = get_gametime()

		if (Player[iAttacker][PlrStealDelay] <= fGameTime)
			Player[iAttacker][PlrStealDelay] = fGameTime + 0.5

		if (Player[iVictim][PlrStealDelay] <= fGameTime)
			Player[iVictim][PlrStealDelay] = fGameTime + 0.5
	}
	else if (Player[iAttacker][PlrKnife] != g_iKnifeId && Player[iVictim][PlrKnife] == g_iKnifeId)
	{
		Player[iVictim][PlrStolenSpeed][iAttacker] += 4.0

		kc_player_set_powerspeed(iAttacker, kc_player_get_powerspeed(iAttacker) - 4.0)
		kc_player_set_powerspeed(iVictim, kc_player_get_powerspeed(iVictim) + 4.0)

		new Float:fGameTime = get_gametime()

		if (Player[iAttacker][PlrStealDelay] <= fGameTime)
			Player[iAttacker][PlrStealDelay] = fGameTime + 0.5

		if (Player[iVictim][PlrStealDelay] <= fGameTime)
			Player[iVictim][PlrStealDelay] = fGameTime + 0.5
	}

	return HAM_IGNORED
}

public Ham_PlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (Player[iVictim][PlrInPush] && (iFlags & DMG_FALL))
	{
		SetHamParamFloat(4, fDamage / ABIL3_FALLDMGDIVIDER)
		return HAM_OVERRIDE
	}

	if (Player[iVictim][PlrKnife] == g_iKnifeId && Player[iVictim][PlrStealingTarget]
		&& fDamage >= 1.0 && !(iFlags & DMG_BURN))
	{
		discharge_stealer(iVictim)
	}

	return HAM_IGNORED
}

public Ham_EnvExplosionTakeDamage_Post(iEnt, iInflictor, iPlayer, Float:fDamage, iFlags)
{
	if (!is_entity_player(iPlayer))
		return HAM_IGNORED

	if (!(iFlags & DMG_BULLET))
		return HAM_IGNORED

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HAM_IGNORED

	if (get_entvar(iEnt, var_impulse) == IMPULSE_ZOMBIE)
	{
		if (Player[iPlayer][PlrTeam] == get_entvar(iEnt, var_skin) + 1)
			return HAM_IGNORED

		new Float:fHealth = Float:get_entvar(iEnt, var_health)
		if (fHealth <= 0.0)
			kc_player_set_powerspeed(iPlayer, kc_player_get_powerspeed(iPlayer) + 9.0)
	}

	return HAM_IGNORED
}

public sphere_think(iSphereEnt)
{
	new Float:vOrigin[3], iOwner = get_entvar(iSphereEnt, var_owner)
	get_entvar(iSphereEnt, var_origin, vOrigin)

	new Float:fRaidusKoef = floatmin(floatmax(get_entvar(iSphereEnt, var_sphere_power) / 60.0, 1.0), 2.5)
	new iSphereInitialSpeed = get_entvar(iSphereEnt, var_sphere_power)

	send_msg_TE_EXPLOSION(vOrigin, g_pExplosionSpr, 7 * floatround(fRaidusKoef), 12, TE_EXPLFLAG_NOSOUND)

	engfunc(EngFunc_EmitSound, iSphereEnt, CHAN_AUTO, SOUND_SPHERE_EXPLOSION, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new iTarget = NULLENT, iTargets[32], iTargetsNum
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, fRaidusKoef * SPHERE_RADIUS_EXPLOSION)) && iTargetsNum < sizeof iTargets)
	{
		if (is_user_alive(iTarget))
		{
			if (!kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
				iTargets[iTargetsNum++] = iTarget
		}
		else
		{
			switch (get_entvar(iTarget, var_impulse))
			{
				case IMPULSE_GHOST:
				{
					if (iSphereInitialSpeed >= 10 && Player[iOwner][PlrTeam] != get_entvar(iTarget, var_team))
						kc_player_set_capture(get_entvar(iTarget, var_owner), CAPTURE_NONE)
				}
				case IMPULSE_ZOMBIE:
				{
					if (Player[iOwner][PlrTeam] != get_entvar(iTarget, var_skin) + 1)
						iTargets[iTargetsNum++] = iTarget
				}
			}
		}
	}

	if (iTargetsNum)
	{
		new iSpeed = floatround((float(get_entvar(iSphereEnt, var_sphere_power))) / iTargetsNum)

		for (new i; i < iTargetsNum; i++)
		{
			iTarget = iTargets[i]
			if (is_user_alive(iTarget))
			{
				if (Player[iOwner][PlrTeam] == Player[iTarget][PlrTeam])
				{
					kc_player_set_powerspeed(iTarget, kc_player_get_powerspeed(iTarget) + iSpeed)
				}
				else
				{
					if (kc_player_in_reflection(iTarget))
					{
						kc_player_set_powerspeed(iTarget, kc_player_get_powerspeed(iTarget) + iSpeed)
					}
					else
					{
						kc_player_set_powerspeed(iTarget, kc_player_get_powerspeed(iTarget) - iSpeed)

						kc_player_set_death_reason(iTarget, "DEATH_REASON_ENERGY_WAVE")
						set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
						ExecuteHamB(Ham_TakeDamage, iTarget, iSphereEnt, iOwner, 0.0, DMG_ENERGYBEAM | DMG_ALWAYSGIB)

						if (Player[iTarget][PlrStealingTarget])
							discharge_stealer(iTarget)
					}
				}
			}
			else if (iSpeed > 0)
			{
				ExecuteHamB(Ham_TakeDamage, iTarget, iSphereEnt, iOwner, float(iSpeed), DMG_ENERGYBEAM | DMG_ALWAYSGIB)
			}
		}
	}

	sphere_remove(iSphereEnt)
}

public sphere_touch(iSphereEnt, iOther)
{
	if (!is_entity(iSphereEnt))
		return HC_CONTINUE

	if (is_entity_player(iOther))
	{
		static Float:fDelay[MAX_PLAYERS + 1]

		new iSpeedSphere = get_entvar(iSphereEnt, var_sphere_power)
		if (iSpeedSphere <= 0)
			return HC_CONTINUE

		new Float:fGameTime = get_gametime()
		if (fDelay[iOther] > fGameTime)
			return HC_CONTINUE

		new iOwner = get_entvar(iSphereEnt, var_owner)
		if (!Player[iOther][PlrIsAlive] || Player[iOwner][PlrTeam] == Player[iOther][PlrTeam] || kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY))
			return HC_CONTINUE

		if (kc_player_in_reflection(iOther))
		{
			kc_player_set_powerspeed(iOther, kc_player_get_powerspeed(iOther) + SPHERE_STEAL_SPEED)
			set_entvar(iSphereEnt, var_sphere_power, max(0, iSpeedSphere - SPHERE_STEAL_SPEED))
		}
		else
		{
			Player[iOwner][PlrStolenSpeed][iOther] += SPHERE_STEAL_SPEED
			kc_player_set_powerspeed(iOther, kc_player_get_powerspeed(iOther) - SPHERE_STEAL_SPEED)
			set_entvar(iSphereEnt, var_sphere_power, iSpeedSphere + SPHERE_STEAL_SPEED)
		}

		fDelay[iOther] = fGameTime + 0.5
	}
	else
	{
		if (get_entvar(iOther, var_solid) > SOLID_TRIGGER)
		{
			engfunc(EngFunc_EmitSound, iSphereEnt, CHAN_AUTO,
				SOUNDS_SPHERE_BOUNCE[random(sizeof SOUNDS_SPHERE_BOUNCE)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}

	return HC_CONTINUE
}

sphere_remove(iSphereEnt)
{
	new iShellEnt = get_entvar(iSphereEnt, var_sphere_shell)
	if (!is_nullent(iShellEnt))
		rg_remove_entity(iShellEnt)

	rg_remove_entity(iSphereEnt)

	new iOwner = get_entvar(iSphereEnt, var_owner)
	if (is_entity_player(iOwner))
		Player[iOwner][PlrSphereEnt] = 0
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId || !Player[iSubject][PlrSphereEnt])
		return PLUGIN_CONTINUE

	set_hudmessage(255, 255, 255, 0.01, -0.7, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_STATUS)
	show_hudmessage(iPlayer, "Blow Up (E): %i power%s",
		get_entvar(Player[iSubject][PlrSphereEnt], var_sphere_power),
		Player[iSubject][PlrCorrectionDelay] > get_gametime() ? "" : "^nCorrection (F)")

	return PLUGIN_CONTINUE
}

public efk_player_change_team(iPlayer, iTeam)
{
	Player[iPlayer][PlrTeam] = iTeam
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][PlrKnife] = iKnifeId

	if (g_iKnifeId != iKnifeId)
	{
		if (Player[iPlayer][PlrStealingTarget])
			out_stealing(iPlayer, Player[iPlayer][PlrStealingTarget])

		for (new iTarget = 1; iTarget <= MaxClients; iTarget++)
			return_stolen_speed(iPlayer, iTarget)

		if (kc_player_get_powerspeed(iPlayer) > 0.0)
			kc_player_set_powerspeed(iPlayer, 0.0)

		razor_punch_end(iPlayer)
	}
	else
	{
		for (new iTarget = 1; iTarget <= MaxClients; iTarget++)
		{
			if (Player[iTarget][PlrStealingTarget] == iPlayer)
			{
				out_stealing(iTarget, iPlayer)
				break
			}
		}
	}
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (!is_entity_player(iTarget))
		return PLUGIN_CONTINUE

	for (new i = 1; i <= MaxClients; i++)
		if (Player[i][PlrStealingTarget] == iTarget)
			return _:CROSSHAIR_CANNOT

	if (Player[iPlayer][PlrStealingTarget] || Player[iTarget][PlrKnife] == g_iKnifeId
		|| (get_entvar(iPlayer, var_flags) & FL_INWATER)
		|| (get_entvar(iTarget, var_flags) & FL_INWATER)
		|| kc_player_get_powerspeed(iTarget) < MIN_POWER_SPEED_STEAL)
	{
		return _:CROSSHAIR_CANNOT
	}

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer, iTarget)
{
	for (new i = 1; i <= MaxClients; i++)
		if (Player[i][PlrStealingTarget] == iTarget)
			return PLUGIN_HANDLED

	if (Player[iPlayer][PlrStealingTarget] || Player[iTarget][PlrKnife] == g_iKnifeId
		|| (get_entvar(iPlayer, var_flags) & FL_INWATER)
		|| (get_entvar(iTarget, var_flags) & FL_INWATER)
		|| kc_player_get_powerspeed(iTarget) < MIN_POWER_SPEED_STEAL)
	{
		return PLUGIN_HANDLED
	}

	new iBeamEnt = Beam_Create(MODEL_BEAM, 30.0)
	if (is_nullent(iBeamEnt))
	{
		Player[iPlayer][PlrRazorBeam] = 0
		return PLUGIN_HANDLED
	}

	Beam_EntsInit(iBeamEnt, iPlayer, iTarget)
	Beam_SetColor(iBeamEnt, {0.0, 0.0, 255.0})
	Beam_SetNoise(iBeamEnt, 30)
	set_entvar(iBeamEnt, var_impulse, IMPULSE_RAZOR_BEAM)

	Player[iPlayer][PlrRazorBeam] = iBeamEnt

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_STEAL_START, 1.0, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STREAM, SOUND_STEAL_LOOP, 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_stealing_icon(iPlayer)
	set_stealing_icon(iTarget)

	Player[iPlayer][PlrStealingTarget] = iTarget
	Player[iPlayer][PlrStealDelay] = get_gametime() + 0.5

	kc_player_set_game_flag(iPlayer, PLGF_IN_LOCK_POWER_DAMAGE)

	return PLUGIN_CONTINUE
}

public efk_ability2(iPlayer)
{
	if (Player[iPlayer][PlrSphereEnt])
		return PLUGIN_HANDLED

	new Float:fPowerSpeed = kc_player_get_powerspeed(iPlayer)

	if (fPowerSpeed < ABIL2_MIN_POWER_SPEED)
		return PLUGIN_HANDLED

	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return PLUGIN_HANDLED

	new iSphereEnt = rg_create_entity(SZ_ENV_SPRITE)
	if (is_nullent(iSphereEnt))
		return PLUGIN_HANDLED

	new Float:vOrigin[3], Float:vVelocity[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vVelocity)
	xs_vec_add(vOrigin, vVelocity, vOrigin)

	get_entvar(iPlayer, var_v_angle, vVelocity)
	engfunc(EngFunc_MakeVectors, vVelocity)
	global_get(glb_v_forward, vVelocity)
	xs_vec_mul_scalar(vVelocity, SPHERE_MAXSPEED, vVelocity)

	engfunc(EngFunc_SetOrigin, iSphereEnt, vOrigin)
	engfunc(EngFunc_SetModel, iSphereEnt, "models/rpgrocket.mdl")
	engfunc(EngFunc_SetSize, iSphereEnt, Float:{-4.0, -4.0, -4.0}, Float:{4.0, 4.0, 4.0})

	new iSphereSpeed = fPowerSpeed > 0.0 ? max(1, floatround(fPowerSpeed / 2.0)) : 0

	kc_player_set_powerspeed(iPlayer, fPowerSpeed - float(iSphereSpeed))

	set_entvar(iSphereEnt, var_origin, vOrigin)
	set_entvar(iSphereEnt, var_velocity, vVelocity)
	set_entvar(iSphereEnt, var_movetype, MOVETYPE_BOUNCE)
	set_entvar(iSphereEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iSphereEnt, var_owner, iPlayer)
	set_entvar(iSphereEnt, var_sphere_power, iSphereSpeed)
	set_entvar(iSphereEnt, var_classname, CLASSNAME_RAZOR_SPHERE)
	set_entvar(iSphereEnt, var_impulse, IMPULSE_RAZOR_SPHERE)
	set_entvar(iSphereEnt, var_gravity, 0.000001)
	set_entvar(iSphereEnt, var_renderamt, 0.0)
	set_entvar(iSphereEnt, var_rendermode, kRenderTransAdd)
	set_entvar(iSphereEnt, var_nextthink, get_gametime() + SPHERE_LIFETIME)

	SetThink(iSphereEnt, "sphere_think")
	SetTouch(iSphereEnt, "sphere_touch")

	new iShellEnt = rg_create_entity(SZ_ENV_SPRITE)
	if (is_nullent(iShellEnt))
	{
		rg_remove_entity(iSphereEnt)
		return PLUGIN_HANDLED
	}

	engfunc(EngFunc_SetModel, iShellEnt, MODEL_SPHERE)

	set_entvar(iShellEnt, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iShellEnt, var_aiment, iSphereEnt)
	set_entvar(iShellEnt, var_scale, 0.3)
	set_entvar(iShellEnt, var_classname, CLASSNAME_SPHERE_SHELL)

	set_entvar(iShellEnt, var_renderfx, kRenderFxNone)
	set_entvar(iShellEnt, var_rendercolor, Float:{255.0, 255.0, 255.0})
	set_entvar(iShellEnt, var_rendermode, kRenderTransAdd)
	set_entvar(iShellEnt, var_renderamt, 255.0)

	set_entvar(iSphereEnt, var_sphere_shell, iShellEnt)

	set_entvar(iShellEnt, var_framerate, 10.0)
	set_entvar(iShellEnt, var_spawnflags, SF_SPRITE_STARTON)
	dllfunc(DLLFunc_Spawn, iShellEnt)

	kc_player_set_view_anim(iPlayer, VIEW_SEQ_SHOOT)

	engfunc(EngFunc_EmitSound, iSphereEnt, CHAN_AUTO,
		SOUNDS_SPHERE_BOUNCE[random(sizeof SOUNDS_SPHERE_BOUNCE)], 1.0, ATTN_NORM, 0, PITCH_NORM)

	new iItem = get_member(iPlayer, m_pActiveItem)
	if (!is_nullent(iItem))
	{
		set_member(iItem, m_Weapon_flNextPrimaryAttack, 1.0)
		set_member(iItem, m_Weapon_flNextSecondaryAttack, 1.0)
		set_member(iItem, m_Weapon_flTimeWeaponIdle, 1.0)
	}

	set_entvar(iPlayer, var_oldbuttons, get_entvar(iPlayer, var_oldbuttons) | IN_USE | IN_RELOAD)

	Player[iPlayer][PlrSphereEnt] = iSphereEnt

	return PLUGIN_CONTINUE
}

public efk_ability3(iPlayer)
{
	if (!(get_entvar(iPlayer, var_flags) & FL_ONGROUND) && get_entvar(iPlayer, var_movetype) != MOVETYPE_FLY)
		return PLUGIN_HANDLED

	kc_player_unfreeze(iPlayer)
	kc_player_set_bair(iPlayer, FL_BAIR_CLIMB)

	Player[iPlayer][PlrInPush] = true

	new Float:fPunchSpeed = kc_player_get_powerspeed(iPlayer) * 0.25
	if (fPunchSpeed > 0.0)
	{
		Player[iPlayer][PlrPushSpeed] = fPunchSpeed
	}
	else
	{
		Player[iPlayer][PlrPushSpeed] = 0.0
	}

	new Float:vVelocity[3]
	velocity_by_aim(iPlayer, ABIL3_FORCE, vVelocity)
	fix_velocity(vVelocity)
	set_entvar(iPlayer, var_velocity, vVelocity)
	set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) & ~FL_ONGROUND)
	vVelocity[2] = 0.0
	Player[iPlayer][PlrStartSpeed] = xs_vec_len(vVelocity)

	emit_sound(iPlayer, CHAN_BODY, SOUND_JUMP, VOL_NORM, ATTN_NORM, 0, 90)
	send_msg_TE_BEAMFOLLOW(iPlayer | 0x1000, g_pBeamSpr, 5, 2, ABIL3_GREEN_COLOR, 150)
	send_msg_TE_BEAMFOLLOW(iPlayer | 0x2000, g_pBeamSpr, 5, 2, ABIL3_RED_COLOR, 150)

	return PLUGIN_CONTINUE
}

public efk_disenergy(iPlayer)
{
	if (Player[iPlayer][PlrStealingTarget])
		discharge_stealer(iPlayer)
}

steal_speed(iPlayer, iTarget, Float:fAdd, Float:fSub)
{
	kc_player_set_powerspeed(iPlayer, kc_player_get_powerspeed(iPlayer) + fAdd)
	kc_player_set_powerspeed(iTarget, kc_player_get_powerspeed(iTarget) - fSub)
}

bool:razor_punch_explosion(iPlayer)
{
	new iPushedPlayers[MAX_PLAYERS], iPushedPlayersNum, Float:vVec[3]

	get_ahead_origin(iPlayer, Player[iPlayer][PlrLastVelocity], 35.0, vVec)
	new iTarget = NULLENT
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vVec, 45.0)) <= MaxClients)
	{
		if (iTarget < 1)
			break

		if (iTarget == iPlayer || !Player[iTarget][PlrIsAlive])
			continue

		if (Player[iTarget][PlrTeam] != Player[iPlayer][PlrTeam] && !kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
			iPushedPlayers[iPushedPlayersNum++] = iTarget
	}

	if (iPushedPlayersNum)
	{
		xs_vec_copy(Player[iPlayer][PlrLastVelocity], vVec)
		fix_velocity(vVec)

		for (new i; i < iPushedPlayersNum; i++)
		{
			iTarget = iPushedPlayers[i]

			kc_player_unfreeze(iTarget)

			kc_player_slow(iTarget, ABIL3_SLOW_MUL, ABIL3_SLOW_TIME)
			steal_speed(iPlayer, iTarget, 20.0, 20.0)

			set_member(iTarget, m_flVelocityModifier, 1.0)
			set_entvar(iTarget, var_velocity, vVec)
		}

		xs_vec_neg(Player[iPlayer][PlrLastVelocity], vVec)
		xs_vec_mul_scalar(vVec, 0.5, vVec)
		set_entvar(iPlayer, var_velocity, vVec)
		emit_sound(iPlayer, CHAN_STATIC, SOUND_PUNCH, VOL_NORM, ATTN_NORM, 0, 90)
	}
	else if (Player[iPlayer][PlrPushSpeed] == 0.0)
	{
		razor_punch_end(iPlayer)
		return false
	}
	else
	{
		new Float:vVecEnd[3]
		xs_vec_copy(Player[iPlayer][PlrLastVelocity], vVecEnd)
		get_entvar(iPlayer, var_origin, vVec)

		new iHit
		xs_vec_add(vVecEnd, vVec, vVecEnd)
		engfunc(EngFunc_TraceLine, vVec, vVecEnd, IGNORE_MONSTERS, iPlayer, 0)
		get_tr2(0, TR_vecEndPos, vVecEnd)

		if (get_distance_f(vVec, vVecEnd) > 32.0)
		{
			if (~get_entvar(iPlayer, var_flags) & FL_ONGROUND)
			{
				razor_punch_end(iPlayer)
				return false
			}

			vVecEnd = vVec
			vVecEnd[2] -= 8192.0
			engfunc(EngFunc_TraceLine, vVec, vVecEnd, IGNORE_MONSTERS, iPlayer, 0)
			get_tr2(0, TR_vecEndPos, vVecEnd)
		}

		iHit = (iHit = get_tr2(0, TR_pHit)) == -1 ? 0 : iHit

		if (!iHit
			|| (!is_nullent(iHit) && (~get_entvar(iHit, var_flags) & FL_KILLME) && (get_entvar(iHit, var_solid) == SOLID_BSP || get_entvar(iHit, var_movetype) == MOVETYPE_PUSHSTEP)))
		{
			write_decal_break(vVecEnd, iHit)
			write_decal_break(vVecEnd, iHit)
			draw_rocks(vVecEnd)

			new Float:vAxis[3]
			vAxis[0] = vVecEnd[0]
			vAxis[1] = vVecEnd[1]
			vAxis[2] = vVecEnd[2] + 32.0 + 100 * 2
			send_msg_TE_BEAMCYLINDER(vVecEnd, vAxis, g_pBeamSpr,
				0, 0, 2, 25, 0, {255, 255, 255}, 50, 0, MSG_PVS, vVecEnd)

			emit_sound(iPlayer, CHAN_STATIC, SOUND_PUNCH, VOL_NORM, ATTN_NORM, 0, 90)

			new Float:vNormal[3], Float:vTargetOrigin[3], Float:vTargetVelocity[3]
			get_tr2(0, TR_vecPlaneNormal, vNormal)
			vNormal[0] = -vNormal[0]
			vNormal[1] = -vNormal[1]

			iTarget = 0
			while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vVecEnd, ABIL3_SCREENSHAKE_RADIUS)) <= MaxClients)
			{
				if (iTarget < 1)
					break

				if (iTarget == iPlayer)
				{
					send_msg_ScreenShake((1<<14), (1<<14), (1<<14), MSG_ONE, _, iTarget)
					continue
				}

				if (!Player[iTarget][PlrIsAlive] || kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
					continue

				get_entvar(iTarget, var_origin, vTargetOrigin)
				xs_vec_sub(vTargetOrigin, vVecEnd, vTargetVelocity)
				xs_vec_normalize(vTargetVelocity, vTargetVelocity)

				if (-0.3 < vNormal[2] < 0.3)
				{
					if (xs_vec_dot(vNormal, vTargetVelocity) < -0.2)
						continue

					xs_vec_normalize(vTargetVelocity, vTargetVelocity)
					vTargetVelocity[2] = 0.5
				}
				else
				{
					xs_vec_normalize(vTargetVelocity, vTargetVelocity)
					vTargetVelocity[2] = 0.8
				}

				send_msg_ScreenShake((1<<14), (1<<14), (1<<14), MSG_ONE, _, iTarget)
				if (Player[iTarget][PlrTeam] == Player[iPlayer][PlrTeam])
					continue

				kc_player_unfreeze(iTarget)
				set_member(iTarget, m_flVelocityModifier, 0.0)
				set_entvar(iTarget, var_flags, get_entvar(iTarget, var_flags) & ~FL_ONGROUND)

				xs_vec_mul_scalar(vTargetVelocity, ABIL3_SCREENSHAKE_VELOCITY, vTargetVelocity)
				set_entvar(iTarget, var_velocity, vTargetVelocity)
				kc_player_slow(iTarget, ABIL3_SLOW_MUL, ABIL3_SLOW_TIME)
			}
		}
	}

	razor_punch_end(iPlayer)
	return true
}

discharge_stealer(const iPlayer)
{
	out_stealing(iPlayer, Player[iPlayer][PlrStealingTarget])

	new Float:fPowerSpeed = kc_player_get_powerspeed(iPlayer)
	if (fPowerSpeed > 0.0)
		kc_player_set_powerspeed(iPlayer, fPowerSpeed * 0.5)
}

out_stealing(const iPlayer, const iTarget)
{
	if (!is_nullent(Player[iPlayer][PlrRazorBeam]))
		rg_remove_entity(Player[iPlayer][PlrRazorBeam])
	Player[iPlayer][PlrRazorBeam] = 0

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STREAM, SOUND_STEAL_END, 1.0, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_EmitSound, iTarget, CHAN_STREAM, SOUND_STEAL_END, 1.0, ATTN_NORM, 0, PITCH_NORM)

	remove_stealing_icon(iPlayer)
	remove_stealing_icon(iTarget)

	kc_player_unset_game_flag(iPlayer, PLGF_IN_LOCK_POWER_DAMAGE)
	kc_player_unset_game_flag(iTarget, PLGF_IN_LOCK_POWER_DAMAGE)

	Player[iPlayer][PlrStealingTarget] = 0
}

return_stolen_speed(const iPlayer, const iTarget)
{
	new Float:fStolenSpeed = Player[iPlayer][PlrStolenSpeed][iTarget]
	if (fStolenSpeed <= 0.0)
		return

	new Float:fCurrSpeed = kc_player_get_powerspeed(iTarget)
	if (fCurrSpeed < 0.0)
	{
		new Float:fTotalSpeed = floatmin(fCurrSpeed + fStolenSpeed, 0.0)
		kc_player_set_powerspeed(iTarget, fTotalSpeed)
	}

	Player[iPlayer][PlrStolenSpeed][iTarget] = 0.0
}

razor_punch_end(iPlayer)
{
	if (Player[iPlayer][PlrInPush])
	{
		Player[iPlayer][PlrInPush] = false
		if (Player[iPlayer][PlrIsAlive])
		{
			send_msg_TE_KILLBEAM(iPlayer | 0x1000, MSG_ALL)
			send_msg_TE_KILLBEAM(iPlayer | 0x2000, MSG_ALL)
		}
	}
}

set_stealing_icon(const iPlayer)
{
	send_msg_StatusIcon(true, SZ_DMG_SHOCK, {0, 125, 255}, MSG_ONE, _, iPlayer)
}

remove_stealing_icon(const iPlayer)
{
	send_msg_StatusIcon(false, SZ_DMG_SHOCK, _, MSG_ONE, _, iPlayer)
}

fix_velocity(Float:vVelocity[3])
{
	if (vVelocity[2] < 0.0)
		vVelocity[2] = 250.0
	else
		vVelocity[2] += 250.0
}

write_decal_break(Float:vOrigin[3], iHit)
{
	if (iHit)
		send_msg_TE_DECAL(vOrigin, random_num(138, 141), iHit, MSG_PAS, vOrigin)
	else
		send_msg_TE_WORLDDECAL(vOrigin, random_num(138, 141), MSG_PAS, vOrigin)
}

draw_rocks(Float:vOrigin[3])
{
	new aPlayers[MAX_PLAYERS], iPlayerNum
	get_players(aPlayers, iPlayerNum, "c")

	for (new i, iPlayer; i < iPlayerNum; i++)
	{
		iPlayer = aPlayers[i]
		if (kc_player_get_options(iPlayer) & OPTION_DISABLE_PARTICLES)
			continue

		send_msg_TE_BREAKMODEL(vOrigin, Float:{16.0, 16.0, 16.0}, Float:{0.0, 0.0, 0.0}, 20, g_pRockGibsMdl, 125, 30, 0, MSG_ONE_UNRELIABLE, _, iPlayer)
	}
}

get_ahead_origin(iPlayer, const Float:vDir[], Float:fLen, Float:vOriginPosition[3])
{
	new Float:vViewOffset[3], Float:vOrigin[3]
	get_entvar(iPlayer, var_view_ofs, vViewOffset)
	get_entvar(iPlayer, var_origin, vOrigin)
	xs_vec_add(vOrigin, vViewOffset, vOrigin)
	xs_vec_normalize(vDir, vViewOffset)
	xs_vec_mul_scalar(vViewOffset, fLen, vViewOffset)
	xs_vec_add(vOrigin, vViewOffset, vOriginPosition)
}

Float:rg_entity_range(iEnt1, iEnt2)
{
	static Float:vOrigin1[3], Float:vOrigin2[3]
	get_entvar(iEnt1, var_origin, vOrigin1)
	get_entvar(iEnt2, var_origin, vOrigin2)

	return get_distance_f(vOrigin1, vOrigin2)
}