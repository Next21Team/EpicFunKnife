#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>
#include <object/efk_web_utils>
#include <object/efk_tornado_utils>

new const PLUGIN[] = "EFK: Nuclear Knife"

#define KNIFE_CLASSNAME "weapon_next21_nuclear"
#define KNIFE_MENUDESC  "KNIFE_NUCLEAR_DESC"
#define KNIFE_CHATDESC  "KNIFE_NUCLEAR_CHAT"

#define HP				140.0
#define GRAVITY			1.0
#define SPEED			165.0
#define MINDAMAGE		10.0
#define MAXDAMAGE		25.0

#define ABIL1_NAME		"Nuclear"
#define ABIL1_CHARGE	5.2632

#define ABIL2_NAME		"Hammer Toss"
#define ABIL2_CHARGE	8.3333

#define ABIL3_NAME		"Hot Speed"
#define ABIL3_CHARGE	10.0

#define RUSH_SPEED			280.0
#define RUSH_TIME			5.0
#define RUSH_SELF_DAMAGE	15.0
#define RUSH_MIN_HEALTH		31.0

#define HAMMER_PULL_SPEED		2000.0
#define HAMMER_PULL_SELF_DAMAGE	15.0
#define HAMMER_ARRIVE_PUSH_FORCE	300.0

#define UNABILITY_TIME		10.0
#define START_PAIR			0.8
#define VELOCITY_BACK		2000.0
#define BURN_CYCLES			3

#define THROW_SPEED				275.0
#define HAMMER_FLIGHT_SPEED		900.0
#define HAMMER_RECALL_SPEED		1200.0
#define HAMMER_AUTO_RETURN_DELAY	6.0
#define HAMMER_RETURN_COOLDOWN		0.3

#define HAMMER_SEQ_IDLE			0
#define HAMMER_SEQ_ROTATE_RIGHT	1
#define HAMMER_SEQ_ROTATE_LEFT	2

#define HAMMER_BODY_EFFECT_OFF	0
#define HAMMER_BODY_EFFECT2_ON	2


#define HAMMER_GLOW_R	255
#define HAMMER_GLOW_G	255
#define HAMMER_GLOW_B	180

#define HAMMER_GLOW_T_R		255
#define HAMMER_GLOW_T_G		40
#define HAMMER_GLOW_T_B		40

#define HAMMER_GLOW_CT_R	40
#define HAMMER_GLOW_CT_G	80
#define HAMMER_GLOW_CT_B	255

#define HAMMER_GLOW_TIME	9999.0
#define HAMMER_GLOW_DIM_AMT	8.0
#define HAMMER_GLOW_AMT	16.0

#define HAMMER_CATCH_RADIUS	24.0

#define HAMMER_PAIR_GLOW_R	255
#define HAMMER_PAIR_GLOW_G	130
#define HAMMER_PAIR_GLOW_B	0
#define HAMMER_PAIR_GLOW_AMT	24.0

#define HAMMER_CORRECTION_GAIN	1.0
#define HAMMER_CORRECTION_LOOKAHEAD	400.0
#define HAMMER_ARC_BOW_FACTOR	0.8
#define HAMMER_ARC_MIN_DURATION	0.15

#define IMPACT_RADIUS		150.0
#define IMPACT_KNOCKBACK	1600.0
#define IMPACT_SLOW_MUL		0.5
#define IMPACT_SLOW_TIME	1.5

#define HIT_PLAYER_DAMAGE		10.0
#define HIT_PLAYER_KNOCKBACK	900.0

#define VIEW_SEQ_STAB	4
#define VIEW_SEQ_THROW	8
#define VIEW_SEQ_DRAW		3
#define HAMMER_WINDUP_TIME	0.3

#define TASK_HAMMER_THROW	32674
#define TASK_HAMMER_FLIGHT_TIMEOUT	32676
#define TASK_HAMMER_LOOP_SOUND	32677
#define TASK_HAMMER_RETURN_RETRY	32700
#define HAMMER_RETURN_RETRY_DELAY	0.2

#define HAMMER_FLIGHT_TIMEOUT	12.0
#define HAMMER_LOOP_SOUND_DURATION	2.3
#define HAMMER_LOOP_SOUND_NEAR_DISTANCE	800.0

#define HAMMER_THROW_DELAY	0.1

new const MODEL_V_KNIFE[]		= "models/next21_efk/v_nuclear_knife_b03.mdl"
new const MODEL_P_KNIFE[]		= "models/next21_efk/p_nuclear_knife_a02.mdl"

new const ANIM_EXT_HAMMER_STR[]	= "hammer"
new const ANIM_EXT_NO_HAMMER[]	= "claws"

new const SZ_INFO_TARGET[]		= "info_target"
new const COFFIN_CLASSNAME[]	= "next21_coffin"

new const MODEL_HAMMER[]		= "models/next21_efk/hammer_b02.mdl"

new const SOUND_KNIFE_DEPLOY[]	= "next21_efk/nuclear_knife_deploy.wav"
new const SOUND_KNIFE_HIT1[]	= "next21_efk/nuclear_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[]	= "next21_efk/nuclear_knife_hit1.wav"
new const SOUND_KNIFE_STAB[]	= "next21_efk/nuclear_knife_stab.wav"
new const SOUND_KNIFE_HITWALL[]	= "next21_efk/nuclear_knife_hitwall.wav"
new const SOUND_KNIFE_SLASH[]	= "next21_efk/nuclear_knife_slash.wav"

new const SOUND_ABILITY[]		= "next21_efk/nuclear_ability.wav"
new const SOUND_EXPLOSION[]		= "next21_efk/nuclear_explosion.wav"
new const SOUND_HOTSPEED[]		= "next21_efk/hot_speed.wav"
new const SOUND_HEAVYFALL[]		= "next21_efk/heavy_fall.wav"
new const SOUND_HAMMER_LOOP[]	= "next21_efk/nuclear_hammer_loop_b02.wav"
new const SOUND_HAMMER_HITWALL[]	= "next21_efk/nuclear_hammer_hitwall.wav"

#define TASK_UNABILITY		32673

enum _:PlayerData
{
	PlrKnife,
	Float:PairEndTime,
	PlrHammerEnt,
	bool:PlrHammerReturning,
	bool:PlrHammerWindup,
	bool:PlrHammerRecallBoosted,
	PlrHammerStuckCoffin,
	bool:PlrHammerInTornado,
	Float:PlrHammerViewHideTime,
	Float:PlrHammerCoffinStickTime,
	Float:PlrHammerThrowTime,
	bool:PlrHammerCarriesPair,
	Float:PlrHammerPairEndTime,
	bool:PlrHammerCorrectionActive,
	Float:PlrHammerCorrectionBaseReal[3],
	Float:PlrHammerCorrectionBasePseudo[3],
	bool:PlrHammerArcReturn,
	Float:PlrHammerArcStart[3],
	Float:PlrHammerArcPerp[3],
	Float:PlrHammerArcBowMagnitude,
	Float:PlrHammerArcDuration,
	Float:PlrHammerArcStartTime
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
	g_pBallSmokeSpr,
	g_pKnifePMdl, g_pKnifeVStr, g_pKnifePStr, g_pRockGibsMdl, g_pLightningSpr,
	bool:g_bHammerThrowHit[MAX_PLAYERS + 1][MAX_PLAYERS + 1],
	bool:g_bHammerReturnHit[MAX_PLAYERS + 1][MAX_PLAYERS + 1],
	bool:g_bHammerLoopNearPlayed[MAX_PLAYERS + 1][MAX_PLAYERS + 1]

public plugin_precache()
{
	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	g_pKnifePStr = engfunc(EngFunc_AllocString, MODEL_P_KNIFE)

	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)
	precache_model(MODEL_HAMMER)

	precache_sound(SOUND_ABILITY)
	precache_sound(SOUND_EXPLOSION)
	precache_sound(SOUND_HOTSPEED)
	precache_sound(SOUND_HEAVYFALL)
	precache_sound(SOUND_HAMMER_LOOP)
	precache_sound(SOUND_HAMMER_HITWALL)

	precache_sound(SOUND_KNIFE_DEPLOY)
	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_STAB)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	g_pBallSmokeSpr = precache_model("sprites/ballsmoke.spr")
	g_pRockGibsMdl = precache_model("models/rockgibs.mdl")
	g_pLightningSpr = precache_model("sprites/lgtning.spr")
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	g_iKnifeId = kc_register_knife(KNIFE_CLASSNAME, KNIFE_MENUDESC, KNIFE_CHATDESC,
		g_pKnifeVStr, g_pKnifePStr,
		g_pKnifePMdl, HP, GRAVITY, SPEED, MINDAMAGE, MAXDAMAGE)

	if (g_iKnifeId < 0)
		set_fail_state("[%s] error registration", PLUGIN)

	kc_register_ability1(g_iKnifeId, ABIL1_NAME, ABIL1_CHARGE)
	kc_register_ability2(g_iKnifeId, ABIL2_NAME, ABIL2_CHARGE)
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)

	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_HAMMER)
	kc_knife_set_charge_boost_coeff(g_iKnifeId, 0.25)
	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLEABLE | KNFF_BAN_BUNNYHOP)

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Pre")
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG_CBasePlayer_TraceAttack_Pre")
	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Post", true)
	RegisterHookChain(RG_CBasePlayer_PostThink, "RG_CBasePlayer_PostThink_Post", true)
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_Damage")
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_PostDamage", true)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Hammer_PrimaryAttack_Pre")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Hammer_PrimaryAttack_Pre")
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_Knife_Deploy_Pre")
	RegisterHam(Ham_Item_CanDeploy, "weapon_hegrenade", "fw_OtherWeapon_CanDeploy_Pre")
	RegisterHam(Ham_Item_CanDeploy, "weapon_flashbang", "fw_OtherWeapon_CanDeploy_Pre")
	RegisterHam(Ham_Item_CanDeploy, "weapon_smokegrenade", "fw_OtherWeapon_CanDeploy_Pre")

	register_impulse(100, "fw_HammerCorrection")

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH)
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][PlrKnife] = -1
	hammer_cleanup(iPlayer)
	hammer_cancel_windup(iPlayer)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	Player[iPlayer][PairEndTime] = 0.0
	remove_task(TASK_UNABILITY + iPlayer)
	hammer_cleanup(iPlayer)
	hammer_cancel_windup(iPlayer)
}

public RG_CBasePlayer_Killed_Pre(iPlayer)
{
	Player[iPlayer][PairEndTime] = 0.0
	remove_task(TASK_UNABILITY + iPlayer)
	hammer_cleanup(iPlayer)
	hammer_cancel_windup(iPlayer)
}

public RG_CBasePlayer_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vDirection[3], iTraceId)
{
	if (!is_entity_player(iAttacker))
		return HC_CONTINUE

	if (Player[iAttacker][PlrKnife] != g_iKnifeId || get_user_weapon(iAttacker) != CSW_KNIFE)
		return HC_CONTINUE

	if (get_member(iVictim, m_iTeam) == get_member(iAttacker, m_iTeam))
		return HC_CONTINUE

	if (~get_entvar(iVictim, var_flags) & FL_ONGROUND)
		return HC_CONTINUE

	if (get_tr2(iTraceId, TR_iHitgroup) == HIT_SHIELD)
		return HC_CONTINUE

	new CaptureType:iCaptureType = kc_player_get_capture(iVictim)
	if (iCaptureType == CAPTURE_NORMAL || iCaptureType == CAPTURE_STRONG)
		return HC_CONTINUE

	new Float:vVictimOrigin[3], Float:vAttackerOrigin[3]
	get_entvar(iVictim, var_origin, vVictimOrigin)
	get_entvar(iAttacker, var_origin, vAttackerOrigin)

	if (get_distance_f(vVictimOrigin, vAttackerOrigin) > 100)
		return HC_CONTINUE

	new Float:vVictimVelocity[3]
	get_entvar(iVictim, var_velocity, vVictimVelocity)

	new Float:vForceVelocity[3]
	xs_vec_mul_scalar(vDirection, fDamage, vForceVelocity)

	new bool:bInDucking = get_entvar(iVictim, var_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	if (bInDucking)
		xs_vec_mul_scalar(vForceVelocity, 0.5, vForceVelocity)

	xs_vec_mul_scalar(vForceVelocity, random_float(7.0, 11.0), vForceVelocity)
	xs_vec_add(vVictimVelocity, vForceVelocity, vForceVelocity)
	vForceVelocity[2] = 400.0

	set_entvar(iVictim, var_velocity, vForceVelocity)

	kc_player_set_override_attacker(iVictim, iAttacker, 3.0)

	return HC_CONTINUE
}

public fw_Player_Damage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (Player[iVictim][PlrKnife] == g_iKnifeId)
	{
		if (iFlags & DMG_BURN)
			return HAM_IGNORED

		if ((iFlags & DMG_FALL) && iVictim == iInflictor && !entity_in_any_web(iVictim) && !Player[iVictim][PlrHammerEnt])
		{
			new iEnt = NULLENT, Float:vOrigin[3]
			get_entvar(iVictim, var_origin, vOrigin)

			new Float:vVelocity[3], Float:vEntOrigin[3], Float:fDistance, Float:fNewSpeed, Float:fRadius
			fRadius = floatmin(fDamage * 5.0, 150.0)

			engfunc(EngFunc_EmitSound, iVictim, CHAN_AUTO, SOUND_HEAVYFALL, 1.0, ATTN_NORM, 0, PITCH_NORM)
			draw_landing_effect(iVictim)

			new iTeam = get_user_team(iVictim)

			while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, fRadius)))
			{
				if (iEnt != iVictim && is_user_alive(iEnt)
					&& iTeam != get_user_team(iEnt)
					&& !kc_player_check_game_flag(iEnt, PLGF_IN_UNABILITY))
				{
					kc_player_set_override_attacker(iEnt, iVictim, 4.0)

					get_entvar(iEnt, var_origin, vEntOrigin)

					fDistance = get_distance_f(vOrigin, vEntOrigin)
					fNewSpeed = VELOCITY_BACK * (1.0 - (fDistance / fRadius))
					get_speed_vector(vOrigin, vEntOrigin, fNewSpeed, vVelocity)

					vVelocity[2] = 400.0
					set_entvar(iEnt, var_velocity, vVelocity)

					new iDmg = random_num(10, 15)

					kc_player_set_death_reason(iEnt, "DEATH_REASON_FALL")
					set_member(iEnt, m_LastHitGroup, HIT_GENERIC)
					ExecuteHamB(Ham_TakeDamage, iEnt, iVictim, iVictim, float(iDmg), DMG_ENERGYBEAM)
				}
				else
				{
					if (get_entvar(iEnt, var_flags) & FL_MONSTER)
					{
						if (iTeam != get_entvar(iEnt, var_skin) + 1)
						{
							get_entvar(iEnt, var_origin, vEntOrigin)

							fDistance = get_distance_f(vOrigin, vEntOrigin)
							fNewSpeed = VELOCITY_BACK * (1.0 - (fDistance / fRadius))
							get_speed_vector(vOrigin, vEntOrigin, fNewSpeed, vVelocity)

							vVelocity[2] = 400.0
							set_entvar(iEnt, var_velocity, vVelocity)

							new iDmg = random_num(10, 15)

							ExecuteHamB(Ham_TakeDamage, iEnt, 0, iEnt, float(iDmg), DMG_ENERGYBEAM)
						}
					}
				}
			}
		}
	}

	if (!iInflictor || iAttacker == iVictim || !is_entity_player(iAttacker))
		return HAM_IGNORED

	new Float:fPair = Player[iVictim][PairEndTime]
	new Float:fGameTime = get_gametime()

	if (fPair < fGameTime)
		return HAM_IGNORED

	switch (get_entvar(iInflictor, var_impulse))
	{
		case IMPULSE_ZOMBIE:
		{
			if (kc_player_get_vision(iVictim) != VISION_BLIND && !kc_player_in_freeze(iVictim) && !kc_player_in_chill(iVictim))
				send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {0, 255, 0}, 35, MSG_ONE, _, iVictim)

			ExecuteHamB(Ham_TakeDamage, iInflictor, iVictim, iVictim, 1337.0, iFlags)

			return HAM_SUPERCEDE
		}
		case IMPULSE_ZOMBIE_SPIT:
			return HAM_SUPERCEDE
	}

	if (!(iFlags & (DMG_BULLET | DMG_FALL)))
		return HAM_IGNORED

	if ((iFlags & DMG_FALL) && iVictim == iInflictor)
		return HAM_IGNORED

	if (Player[iAttacker][PairEndTime] >= fGameTime)
		return HAM_IGNORED

	if (kc_player_get_vision(iAttacker) != VISION_BLIND && !kc_player_in_freeze(iAttacker) && !kc_player_in_chill(iAttacker))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 0, 0}, 35, MSG_ONE, _, iAttacker)

	if (kc_player_get_vision(iVictim) != VISION_BLIND && !kc_player_in_freeze(iVictim) && !kc_player_in_chill(iVictim))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {0, 255, 0}, 35, MSG_ONE, _, iVictim)

	new iDamage, Float:fReflect
	fReflect = (fPair - fGameTime) / UNABILITY_TIME * START_PAIR
	iDamage = min(floatround(fDamage * fReflect), 75)

	kc_player_set_death_reason(iAttacker, "DEATH_REASON_PAIR")
	set_member(iAttacker, m_LastHitGroup, get_member(iVictim, m_LastHitGroup))
	ExecuteHamB(Ham_TakeDamage, iAttacker, iInflictor, iVictim, iDamage + 0.0, iFlags & ~(DMG_BULLET | DMG_FALL))

	client_print(iVictim, print_center, "%L %d", iVictim, "DAMAGE_REFLECTED", iDamage)

	return HAM_IGNORED
}

public fw_Player_PostDamage(iPlayer, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (Player[iPlayer][PlrKnife] == g_iKnifeId && is_user_alive(iPlayer) && kc_player_check_game_flag(iPlayer, PLGF_IN_UNABILITY))
		set_member(iPlayer, m_flVelocityModifier, 1.0)
}

public efk_calculate_render_colors(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return

	new Float:fGameTime = get_gametime()

	if (Player[iPlayer][PairEndTime] > fGameTime)
	{
		new Float:fFraction = (Player[iPlayer][PairEndTime] - fGameTime) / UNABILITY_TIME
		set_entvar(iPlayer, var_renderamt, HAMMER_PAIR_GLOW_AMT * fFraction)
		return
	}

	if (Player[iPlayer][PlrHammerEnt] || Player[iPlayer][PlrHammerWindup])
		set_entvar(iPlayer, var_renderamt, HAMMER_GLOW_DIM_AMT)
}

public efk_status_draw(iPlayer, iSubject)
{
	new Float:fGameTime = get_gametime()
	new Float:fPair = Player[iSubject][PairEndTime] - fGameTime
	new bool:bOnHammer = false

	if (fPair <= 0.0 && Player[iSubject][PlrHammerCarriesPair])
	{
		fPair = Player[iSubject][PlrHammerPairEndTime] - fGameTime
		bOnHammer = true
	}

	if (fPair > 0.0)
	{
		fPair = fPair / UNABILITY_TIME * START_PAIR * 100.0

		set_hudmessage(255, 255, 255, -1.0, -0.30, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "%L %..1f%%%s", iPlayer, bOnHammer ? "DAMAGE_REFLECTED_COEFF_HAMMER" : "DAMAGE_REFLECTED_COEFF", fPair,
			(bOnHammer && !Player[iSubject][PlrHammerReturning]) ? "^nCorrection (F)" : "")
	}
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	if (Player[iPlayer][PairEndTime] >= get_gametime())
	{
		kc_player_unset_game_flag(iPlayer, PLGF_IN_UNABILITY)
		kc_player_sub_glow(iPlayer, 255, 130, 0)
		Player[iPlayer][PairEndTime] = 0.0
		remove_task(TASK_UNABILITY + iPlayer)
	}

	if (Player[iPlayer][PlrKnife] == g_iKnifeId && iKnifeId != g_iKnifeId)
	{
		hammer_cleanup(iPlayer)
		hammer_cancel_windup(iPlayer)
	}

	Player[iPlayer][PlrKnife] = iKnifeId
}

hammer_glow_color(iPlayer, &r, &g, &b)
{
	if (get_member(iPlayer, m_iTeam) == CS_TEAM_CT)
	{
		r = HAMMER_GLOW_CT_R
		g = HAMMER_GLOW_CT_G
		b = HAMMER_GLOW_CT_B
	}
	else
	{
		r = HAMMER_GLOW_T_R
		g = HAMMER_GLOW_T_G
		b = HAMMER_GLOW_T_B
	}
}

hammer_apply_team_glow(iHammerEnt, iOwner)
{
	new r, g, b
	hammer_glow_color(iOwner, r, g, b)

	new Float:vColor[3]
	vColor[0] = float(r)
	vColor[1] = float(g)
	vColor[2] = float(b)

	set_entvar(iHammerEnt, var_rendermode, kRenderNormal)
	set_entvar(iHammerEnt, var_renderfx, kRenderFxGlowShell)
	set_entvar(iHammerEnt, var_rendercolor, vColor)
	set_entvar(iHammerEnt, var_renderamt, HAMMER_GLOW_AMT)
}

public efk_uncapture(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return

	if (Player[iPlayer][PlrHammerEnt] || Player[iPlayer][PlrHammerWindup])
	{
		kc_player_add_glow(iPlayer, HAMMER_GLOW_TIME, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)

		if (Player[iPlayer][PlrHammerEnt] && Player[iPlayer][PlrHammerCarriesPair])
			hammer_apply_team_glow(Player[iPlayer][PlrHammerEnt], iPlayer)
		return
	}

	set_pev(iPlayer, pev_viewmodel, g_pKnifeVStr)
	set_pev(iPlayer, pev_weaponmodel, g_pKnifePStr)
}

public efk_ability_pre(iPlayer, iTarget)
{
	if (Player[iPlayer][PlrKnife] == g_iKnifeId && (Player[iPlayer][PlrHammerEnt] || Player[iPlayer][PlrHammerWindup]))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer)
{
	kc_player_unprotection(iPlayer)

	kc_player_add_glow(iPlayer, UNABILITY_TIME, 255, 130, 0)

	if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {8, 37, 103}, 130, MSG_ONE, _, iPlayer)

	kc_player_set_game_flag(iPlayer, PLGF_IN_UNABILITY)
	remove_task(TASK_UNABILITY + iPlayer)
	set_task(UNABILITY_TIME, "task_remove_unability", TASK_UNABILITY + iPlayer)

	if (kc_player_get_windboost(iPlayer) == WINDBOOST_NEGATIVE)
		kc_player_set_windboost(iPlayer, WINDBOOST_NONE)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_ABILITY, 1.0, ATTN_NORM, 0, PITCH_NORM)

	Player[iPlayer][PairEndTime] = get_gametime() + UNABILITY_TIME
}

public fw_HammerCorrection(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	new iHammerEnt = Player[iPlayer][PlrHammerEnt]
	if (!iHammerEnt || Player[iPlayer][PlrHammerReturning] || !Player[iPlayer][PlrHammerCarriesPair])
		return PLUGIN_CONTINUE

	new Float:vRealAim[3]
	get_entvar(iPlayer, var_v_angle, vRealAim)
	xs_vec_copy(vRealAim, Player[iPlayer][PlrHammerCorrectionBaseReal])

	new Float:vEyeOrigin[3], Float:vViewOfs[3]
	get_entvar(iPlayer, var_origin, vEyeOrigin)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vEyeOrigin, vViewOfs, vEyeOrigin)

	new Float:vHammerOrigin[3], Float:vToHammer[3]
	get_entvar(iHammerEnt, var_origin, vHammerOrigin)
	xs_vec_sub(vHammerOrigin, vEyeOrigin, vToHammer)

	new Float:fToHammerLen = xs_vec_len(vToHammer)
	if (fToHammerLen < 1.0)
		xs_vec_copy(vRealAim, Player[iPlayer][PlrHammerCorrectionBasePseudo])
	else
	{
		Player[iPlayer][PlrHammerCorrectionBasePseudo][0] = -floatasin(vToHammer[2] / fToHammerLen, degrees)
		Player[iPlayer][PlrHammerCorrectionBasePseudo][1] = floatatan2(vToHammer[1], vToHammer[0], degrees)
		Player[iPlayer][PlrHammerCorrectionBasePseudo][2] = 0.0
	}

	Player[iPlayer][PlrHammerCorrectionActive] = true

	return PLUGIN_HANDLED
}

Float:hammer_angle_diff(Float:fA, Float:fB)
{
	new Float:fDiff = fA - fB
	while (fDiff > 180.0)
		fDiff -= 360.0
	while (fDiff < -180.0)
		fDiff += 360.0
	return fDiff
}

public efk_ability2(iPlayer)
{
	new iHammerEnt = Player[iPlayer][PlrHammerEnt]

	if (iHammerEnt)
	{
		if (!Player[iPlayer][PlrHammerReturning])
			hammer_start_return(iPlayer, iHammerEnt)

		return PLUGIN_HANDLED
	}

	if (Player[iPlayer][PlrHammerWindup])
		return PLUGIN_HANDLED

	if (get_user_weapon(iPlayer) != CSW_KNIFE)
		return PLUGIN_HANDLED

	if (Float:get_member(iPlayer, m_flNextAttack) > 0.0)
		return PLUGIN_HANDLED

	kc_player_slow(iPlayer, 1.0, 0.0)
	kc_player_set_def_maxspeed(iPlayer, THROW_SPEED)

	Player[iPlayer][PlrHammerWindup] = true
	kc_player_set_view_anim(iPlayer, VIEW_SEQ_THROW)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_KNIFE_SLASH, 1.0, ATTN_NORM, 0, PITCH_NORM)
	rg_set_animation(iPlayer, PLAYER_ATTACK1)
	set_member(iPlayer, m_szAnimExtention, ANIM_EXT_NO_HAMMER)

	kc_player_add_glow(iPlayer, HAMMER_GLOW_TIME, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)

	if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
	{
		new r, g, b
		hammer_glow_color(iPlayer, r, g, b)

		new iFadeColor[3]
		iFadeColor[0] = r
		iFadeColor[1] = g
		iFadeColor[2] = b
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), iFadeColor, 60, MSG_ONE, _, iPlayer)
	}

	new iItem = get_member(iPlayer, m_pActiveItem)
	if (!is_nullent(iItem))
	{
		set_member(iItem, m_Weapon_flTimeWeaponIdle, HAMMER_WINDUP_TIME + 0.5)
		set_member(iItem, m_Weapon_flNextPrimaryAttack, HAMMER_WINDUP_TIME)
		set_member(iItem, m_Weapon_flNextSecondaryAttack, HAMMER_WINDUP_TIME)
	}

	remove_task(TASK_HAMMER_THROW + iPlayer)
	set_task(HAMMER_THROW_DELAY, "task_hammer_throw", TASK_HAMMER_THROW + iPlayer)

	Player[iPlayer][PlrHammerViewHideTime] = get_gametime() + HAMMER_WINDUP_TIME

	return PLUGIN_HANDLED
}

public task_hammer_throw(iTaskId)
{
	new iPlayer = iTaskId - TASK_HAMMER_THROW

	Player[iPlayer][PlrHammerWindup] = false

	if (!is_user_alive(iPlayer) || Player[iPlayer][PlrKnife] != g_iKnifeId)
		return

	hammer_throw(iPlayer)
}

hammer_cancel_windup(iPlayer)
{
	if (!Player[iPlayer][PlrHammerWindup])
		return

	Player[iPlayer][PlrHammerWindup] = false
	Player[iPlayer][PlrHammerViewHideTime] = 0.0
	remove_task(TASK_HAMMER_THROW + iPlayer)

	kc_player_sub_glow(iPlayer, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)
}

hammer_throw(iPlayer)
{
	rg_set_animation(iPlayer, PLAYER_IDLE)

	kc_player_set_abil2_charge(iPlayer, 0.0)

	arrayset(g_bHammerThrowHit[iPlayer], false, MAX_PLAYERS + 1)
	arrayset(g_bHammerReturnHit[iPlayer], false, MAX_PLAYERS + 1)
	arrayset(g_bHammerLoopNearPlayed[iPlayer], false, MAX_PLAYERS + 1)

	new iHammerEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iHammerEnt))
		return

	new Float:vOrigin[3], Float:vViewOfs[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vOrigin, vViewOfs, vOrigin)

	engfunc(EngFunc_SetModel, iHammerEnt, MODEL_HAMMER)
	engfunc(EngFunc_SetSize, iHammerEnt, Float:{-4.0, -4.0, -2.0}, Float:{4.0, 4.0, 2.0})
	set_entvar(iHammerEnt, var_skin, get_member(iPlayer, m_iTeam) == CS_TEAM_CT ? 1 : 0)
	set_entvar(iHammerEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iHammerEnt, var_movetype, MOVETYPE_BOUNCEMISSILE)
	set_entvar(iHammerEnt, var_takedamage, DAMAGE_NO)
	set_entvar(iHammerEnt, var_owner, iPlayer)
	set_entvar(iHammerEnt, var_impulse, IMPULSE_HAMMER)

	new Float:vVelocity[3]
	velocity_by_aim(iPlayer, floatround(HAMMER_FLIGHT_SPEED), vVelocity)

	new Float:vAngles[3]
	vector_to_angle(vVelocity, vAngles)

	engfunc(EngFunc_SetOrigin, iHammerEnt, vOrigin)
	set_entvar(iHammerEnt, var_origin, vOrigin)
	set_entvar(iHammerEnt, var_velocity, vVelocity)
	set_entvar(iHammerEnt, var_angles, vAngles)

	set_entvar(iHammerEnt, var_body, HAMMER_BODY_EFFECT2_ON)
	set_entvar(iHammerEnt, var_sequence, HAMMER_SEQ_ROTATE_RIGHT)
	set_entvar(iHammerEnt, var_framerate, 1.0)
	set_entvar(iHammerEnt, var_animtime, get_gametime())

	SetTouch(iHammerEnt, "hammer_touch")
	SetThink(iHammerEnt, "hammer_think")
	set_entvar(iHammerEnt, var_nextthink, get_gametime())

	set_pev(iPlayer, pev_weaponmodel, 0)

	kc_player_set_def_maxspeed(iPlayer, THROW_SPEED)

	kc_player_set_game_flag(iPlayer, PLGF_IN_HAMMER_THROWN)

	Player[iPlayer][PlrHammerEnt] = iHammerEnt
	Player[iPlayer][PlrHammerReturning] = false
	Player[iPlayer][PlrHammerRecallBoosted] = false
	Player[iPlayer][PlrHammerStuckCoffin] = 0
	Player[iPlayer][PlrHammerInTornado] = false
	Player[iPlayer][PlrHammerThrowTime] = get_gametime()
	Player[iPlayer][PlrHammerCorrectionActive] = false
	Player[iPlayer][PlrHammerArcReturn] = false

	if (Player[iPlayer][PairEndTime] > get_gametime())
	{
		Player[iPlayer][PlrHammerCarriesPair] = true
		Player[iPlayer][PlrHammerPairEndTime] = Player[iPlayer][PairEndTime]

		Player[iPlayer][PairEndTime] = 0.0
		remove_task(TASK_UNABILITY + iPlayer)
		kc_player_unset_game_flag(iPlayer, PLGF_IN_UNABILITY)
		kc_player_sub_glow(iPlayer, 255, 130, 0)

		hammer_apply_team_glow(iHammerEnt, iPlayer)
	}
	else
	{
		Player[iPlayer][PlrHammerCarriesPair] = false
	}

	kc_player_set_ability3_name(iPlayer, "Force Recall")
	kc_player_set_ability2_name(iPlayer, "Recall")

	remove_task(TASK_HAMMER_FLIGHT_TIMEOUT + iPlayer)
	set_task(HAMMER_FLIGHT_TIMEOUT, "task_hammer_flight_timeout", TASK_HAMMER_FLIGHT_TIMEOUT + iPlayer)

	hammer_start_loop_sound(iPlayer, iHammerEnt)
}

hammer_start_loop_sound(iOwner, iHammerEnt)
{
	remove_task(TASK_HAMMER_LOOP_SOUND + iOwner)
	set_task(HAMMER_LOOP_SOUND_DURATION, "task_hammer_loop_sound", TASK_HAMMER_LOOP_SOUND + iOwner, .flags = "b")

	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, SOUND_HAMMER_LOOP, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM)
	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, SOUND_HAMMER_LOOP, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

hammer_stop_loop_sound(iOwner, iHammerEnt)
{
	remove_task(TASK_HAMMER_LOOP_SOUND + iOwner)
	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, SOUND_HAMMER_LOOP, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM)
}

public task_hammer_loop_sound(iTaskId)
{
	new iPlayer = iTaskId - TASK_HAMMER_LOOP_SOUND

	new iHammerEnt = Player[iPlayer][PlrHammerEnt]
	if (!iHammerEnt || is_nullent(iHammerEnt))
	{
		remove_task(TASK_HAMMER_LOOP_SOUND + iPlayer)
		return
	}

	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, SOUND_HAMMER_LOOP, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

hammer_check_nearby_loop_sound(iOwner, iHammerEnt)
{
	new Float:vHammerOrigin[3]
	get_entvar(iHammerEnt, var_origin, vHammerOrigin)

	new bool:bAnyoneJustEntered = false

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue

		new Float:vOrigin[3], Float:vDelta[3]
		get_entvar(i, var_origin, vOrigin)
		xs_vec_sub(vHammerOrigin, vOrigin, vDelta)

		new bool:bNear = xs_vec_len(vDelta) <= HAMMER_LOOP_SOUND_NEAR_DISTANCE

		if (bNear && !g_bHammerLoopNearPlayed[iOwner][i])
		{
			g_bHammerLoopNearPlayed[iOwner][i] = true
			bAnyoneJustEntered = true
		}
		else if (!bNear)
			g_bHammerLoopNearPlayed[iOwner][i] = false
	}

	if (bAnyoneJustEntered)
	{
		engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, SOUND_HAMMER_LOOP, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM)
		engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, SOUND_HAMMER_LOOP, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public task_hammer_flight_timeout(iTaskId)
{
	new iPlayer = iTaskId - TASK_HAMMER_FLIGHT_TIMEOUT

	new iHammerEnt = Player[iPlayer][PlrHammerEnt]
	if (!iHammerEnt || is_nullent(iHammerEnt) || Player[iPlayer][PlrHammerReturning])
		return

	hammer_start_return(iPlayer, iHammerEnt)
}

public task_hammer_return_retry(iTaskId)
{
	new iOwner = iTaskId - TASK_HAMMER_RETURN_RETRY

	new iHammerEnt = Player[iOwner][PlrHammerEnt]
	if (!iHammerEnt || is_nullent(iHammerEnt))
		return

	if (Player[iOwner][PlrHammerReturning])
		hammer_return_complete(iOwner, iHammerEnt)
	else
		hammer_start_return(iOwner, iHammerEnt)
}

public hammer_touch(iHammerEnt, iOther)
{
	if (is_nullent(iHammerEnt))
		return HC_CONTINUE

	new iOwner = get_entvar(iHammerEnt, var_owner)
	if (!is_entity_player(iOwner))
	{
		rg_remove_entity(iHammerEnt)
		return HC_CONTINUE
	}

	if (iOther == iOwner)
	{
		if (Player[iOwner][PlrHammerReturning])
			hammer_return_complete(iOwner, iHammerEnt)

		return HC_CONTINUE
	}

	if (iOther > 0 && iOther <= MaxClients)
	{
		if (is_user_alive(iOther) && get_user_team(iOther) == get_user_team(iOwner)
			&& !kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY) && kc_player_in_freeze(iOther))
			hammer_break_ice(iHammerEnt, iOther)

		return HC_CONTINUE
	}

	new szClassname[32]
	get_entvar(iOther, var_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, COFFIN_CLASSNAME))
		Player[iOwner][PlrHammerStuckCoffin] = iOther

	if (FClassnameIs(iOther, "grenade"))
	{
		new Float:vVelocity[3]
		get_entvar(iOther, var_velocity, vVelocity)
		vVelocity[0] = -vVelocity[0]
		vVelocity[1] = -vVelocity[1]
		vVelocity[2] = floatabs(vVelocity[2])
		set_entvar(iOther, var_velocity, vVelocity)

		hammer_emit_hit_sound(iHammerEnt)
		return HC_CONTINUE
	}

	if (equal(szClassname, "func_breakable") && get_entvar(iOther, var_rendermode) != kRenderNormal)
	{
		ExecuteHamB(Ham_TakeDamage, iOther, iHammerEnt, iOwner, 8000.0, DMG_GENERIC)
		hammer_emit_hit_sound(iHammerEnt)
		return HC_CONTINUE
	}

	switch (get_entvar(iOther, var_impulse))
	{
		case IMPULSE_ACIDTRAP:
		{
			dllfunc(DLLFunc_Use, iOther, iHammerEnt, iHammerEnt, USE_TOGGLE, 0.0)
			hammer_emit_hit_sound(iHammerEnt)
			return HC_CONTINUE
		}
		case IMPULSE_ICICLE:
		{
			new iIcicleOwner = get_entvar(iOther, var_owner)
			if (is_entity_player(iIcicleOwner) && get_user_team(iIcicleOwner) == get_user_team(iOwner))
				return HC_CONTINUE

			dllfunc(DLLFunc_Touch, iOther, iHammerEnt)
			if (is_entity(iOther))
				rg_remove_entity(iOther)
			hammer_emit_hit_sound(iHammerEnt)
			return HC_CONTINUE
		}
		case IMPULSE_ICE_CLONE:
		{
			return HC_CONTINUE
		}
		case IMPULSE_FOLLOWENT:
		{
			if (equal(szClassname, COFFIN_CLASSNAME) && !Player[iOwner][PlrHammerReturning])
				hammer_stick_coffin(iHammerEnt, iOwner, iOther)

			return HC_CONTINUE
		}
		case IMPULSE_EMBODIMENT:
		{
			return HC_CONTINUE
		}
		case IMPULSE_HAMMER:
		{
			return HC_CONTINUE
		}
		case IMPULSE_ACIDB:
		{
			new iAcidOwner = get_entvar(iOther, var_owner)
			if (is_entity_player(iAcidOwner) && get_user_team(iAcidOwner) == get_user_team(iOwner))
				return HC_CONTINUE

			engfunc(EngFunc_SetModel, iOther, "")
			engfunc(EngFunc_SetSize, iOther, Float:{-32.0, -32.0, -32.0}, Float:{32.0, 32.0, 32.0})

			set_entvar(iOther, var_classname, CLASSNAME_ACIDG)
			set_entvar(iOther, var_impulse, IMPULSE_ACIDG)
			set_entvar(iOther, var_solid, SOLID_TRIGGER)
			set_entvar(iOther, var_movetype, MOVETYPE_NONE)
			set_entvar(iOther, var_iuser1, 0)
			set_entvar(iOther, var_nextthink, get_gametime())

			SetThink(iOther, "acidcloud_think")
			SetTouch(iOther, "acidcloud_touch")

			dllfunc(DLLFunc_Think, iOther)

			hammer_emit_hit_sound(iHammerEnt)
			return HC_CONTINUE
		}
		case IMPULSE_FAKEPLAYER:
		{
			if (get_entvar(iOther, var_team) != get_user_team(iOwner))
			{
				ExecuteHamB(Ham_TakeDamage, iOther, iHammerEnt, iOwner, 50.0, DMG_CLUB)
				hammer_emit_hit_sound(iHammerEnt)
			}
			return HC_CONTINUE
		}
		case IMPULSE_KUNAI, IMPULSE_RAZOR_SPHERE:
		{
			new iOtherOwner = get_entvar(iOther, var_owner)
			if (is_entity_player(iOtherOwner) && get_user_team(iOtherOwner) == get_user_team(iOwner))
				return HC_CONTINUE

			dllfunc(DLLFunc_Think, iOther)
			hammer_emit_hit_sound(iHammerEnt)
			return HC_CONTINUE
		}
		case IMPULSE_FIELD_WALL:
		{
			if (get_entvar(iOther, var_skin) + 1 == get_user_team(iOwner))
				return HC_CONTINUE
		}
		case IMPULSE_BUG:
		{
			if (get_entvar(iOther, var_skin) + 1 != get_user_team(iOwner))
			{
				ExecuteHamB(Ham_TakeDamage, iOther, iHammerEnt, iOwner, 10.0, DMG_CLUB)
				hammer_emit_hit_sound(iHammerEnt)
			}

			return HC_CONTINUE
		}
		case IMPULSE_ZOMBIE:
		{
			if (get_entvar(iOther, var_skin) + 1 != get_user_team(iOwner))
			{
				new Float:vVelocity[3]
				get_entvar(iHammerEnt, var_velocity, vVelocity)
				xs_vec_normalize(vVelocity, vVelocity)
				xs_vec_mul_scalar(vVelocity, HIT_PLAYER_KNOCKBACK, vVelocity)
				vVelocity[2] = 250.0
				set_entvar(iOther, var_velocity, vVelocity)

				ExecuteHamB(Ham_TakeDamage, iOther, iHammerEnt, iOwner, HIT_PLAYER_DAMAGE, DMG_CLUB)
				hammer_emit_hit_sound(iHammerEnt)
			}

			return HC_CONTINUE
		}
	}

	if (!Player[iOwner][PlrHammerReturning])
		hammer_hit_world(iHammerEnt, iOwner)

	return HC_CONTINUE
}

hammer_check_view_hide(iOwner)
{
	if (Player[iOwner][PlrHammerViewHideTime] <= 0.0 || get_gametime() < Player[iOwner][PlrHammerViewHideTime])
		return

	set_pev(iOwner, pev_viewmodel, 0)
	set_pev(iOwner, pev_weaponmodel, 0)
}

public hammer_think(iHammerEnt)
{
	if (is_nullent(iHammerEnt))
		return

	new iOwner = get_entvar(iHammerEnt, var_owner)
	if (!is_entity_player(iOwner) || !Player[iOwner][PlrHammerEnt])
		return

	hammer_check_view_hide(iOwner)

	if (get_entvar(iHammerEnt, var_hammer_recall) && !Player[iOwner][PlrHammerReturning])
	{
		set_entvar(iHammerEnt, var_hammer_recall, 0)
		hammer_start_return(iOwner, iHammerEnt)
	}

	if (get_entvar(iHammerEnt, var_movetype) != MOVETYPE_NONE)
	{
		hammer_check_players_hitbox(iHammerEnt, iOwner)
		hammer_handle_tornado(iHammerEnt, iOwner)
	}

	hammer_update_pair_glow(iOwner, iHammerEnt)

	set_entvar(iHammerEnt, var_nextthink, get_gametime())
}

hammer_update_pair_glow(iOwner, iHammerEnt)
{
	if (!Player[iOwner][PlrHammerCarriesPair])
		return

	new Float:fGameTime = get_gametime()

	if (fGameTime >= Player[iOwner][PlrHammerPairEndTime])
	{
		Player[iOwner][PlrHammerCarriesPair] = false
		Player[iOwner][PlrHammerCorrectionActive] = false
		set_entvar(iHammerEnt, var_renderfx, kRenderFxNone)
		set_entvar(iHammerEnt, var_renderamt, 0.0)
		return
	}

	new Float:fFraction = (Player[iOwner][PlrHammerPairEndTime] - fGameTime) / UNABILITY_TIME

	new r, g, b
	hammer_glow_color(iOwner, r, g, b)

	new Float:vColor[3]
	vColor[0] = float(r)
	vColor[1] = float(g)
	vColor[2] = float(b)

	set_entvar(iHammerEnt, var_rendermode, kRenderNormal)
	set_entvar(iHammerEnt, var_renderfx, kRenderFxGlowShell)
	set_entvar(iHammerEnt, var_rendercolor, vColor)
	set_entvar(iHammerEnt, var_renderamt, HAMMER_PAIR_GLOW_AMT * fFraction)

	if (Player[iOwner][PlrHammerCorrectionActive] && !Player[iOwner][PlrHammerReturning]
		&& get_entvar(iHammerEnt, var_movetype) != MOVETYPE_NONE)
		hammer_apply_correction(iOwner, iHammerEnt)
}

hammer_apply_correction(iOwner, iHammerEnt)
{
	new Float:vVelocity[3]
	get_entvar(iHammerEnt, var_velocity, vVelocity)

	new Float:fSpeed = xs_vec_len(vVelocity)
	if (fSpeed <= 0.0)
		return

	new Float:vRealAim[3]
	get_entvar(iOwner, var_v_angle, vRealAim)

	new Float:vPseudoAim[3]
	vPseudoAim[0] = Player[iOwner][PlrHammerCorrectionBasePseudo][0]
		+ hammer_angle_diff(vRealAim[0], Player[iOwner][PlrHammerCorrectionBaseReal][0]) * HAMMER_CORRECTION_GAIN
	vPseudoAim[1] = Player[iOwner][PlrHammerCorrectionBasePseudo][1]
		+ hammer_angle_diff(vRealAim[1], Player[iOwner][PlrHammerCorrectionBaseReal][1]) * HAMMER_CORRECTION_GAIN
	vPseudoAim[2] = 0.0

	if (vPseudoAim[0] > 89.0)
		vPseudoAim[0] = 89.0
	else if (vPseudoAim[0] < -89.0)
		vPseudoAim[0] = -89.0

	new Float:vDir[3]
	angle_vector(vPseudoAim, ANGLEVECTOR_FORWARD, vDir)

	new Float:vEye[3], Float:vViewOfs[3], Float:vHammerOrigin[3], Float:vFromEye[3]
	get_entvar(iOwner, var_origin, vEye)
	get_entvar(iOwner, var_view_ofs, vViewOfs)
	xs_vec_add(vEye, vViewOfs, vEye)
	get_entvar(iHammerEnt, var_origin, vHammerOrigin)
	xs_vec_sub(vHammerOrigin, vEye, vFromEye)

	new Float:vTarget[3], Float:vNewVelocity[3]
	xs_vec_mul_scalar(vDir, xs_vec_len(vFromEye) + HAMMER_CORRECTION_LOOKAHEAD, vTarget)
	xs_vec_add(vEye, vTarget, vTarget)
	xs_vec_sub(vTarget, vHammerOrigin, vNewVelocity)
	xs_vec_normalize(vNewVelocity, vNewVelocity)
	xs_vec_mul_scalar(vNewVelocity, fSpeed, vNewVelocity)
	set_entvar(iHammerEnt, var_velocity, vNewVelocity)

	new Float:vAngles[3]
	vector_to_angle(vNewVelocity, vAngles)
	set_entvar(iHammerEnt, var_angles, vAngles)
}

hammer_handle_tornado(iHammerEnt, iOwner)
{
	static const Float:TORNADO_FIND_RADIUS = 200.0

	new Float:vOrigin[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)

	new bool:bInTornado = false
	new iEnt = -1
	while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, TORNADO_FIND_RADIUS)) > 0)
	{
		if (get_entvar(iEnt, var_impulse) == IMPULSE_TORNADO)
		{
			bInTornado = true
			break
		}
	}

	new Float:vVelocity[3]
	get_entvar(iHammerEnt, var_velocity, vVelocity)

	if (bInTornado)
	{
		if (xs_vec_len(vVelocity) > 0.0)
		{
			new Float:vAngles[3]
			vector_to_angle(vVelocity, vAngles)
			set_entvar(iHammerEnt, var_angles, vAngles)
		}
	}
	else if (Player[iOwner][PlrHammerInTornado] && xs_vec_len(vVelocity) > 0.0)
	{
		xs_vec_normalize(vVelocity, vVelocity)
		xs_vec_mul_scalar(vVelocity, Player[iOwner][PlrHammerReturning] ? HAMMER_RECALL_SPEED : HAMMER_FLIGHT_SPEED, vVelocity)
		set_entvar(iHammerEnt, var_velocity, vVelocity)

		new Float:vAngles[3]
		vector_to_angle(vVelocity, vAngles)
		set_entvar(iHammerEnt, var_angles, vAngles)
	}

	Player[iOwner][PlrHammerInTornado] = bInTornado
}

hammer_check_players_hitbox(iHammerEnt, iOwner)
{
	new Float:vOrigin[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)

	new Float:vBoxMins[3] = {-8.0, -8.0, -2.0}
	new Float:vBoxMaxs[3] = {8.0, 8.0, 2.0}

	new iTeam = get_user_team(iOwner)

	new iTarget = -1
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, 64.0)) > 0)
	{
		if (iTarget > MaxClients || iTarget == iOwner || !is_user_alive(iTarget) || get_user_team(iTarget) == iTeam
			|| get_entvar(iTarget, var_solid) == SOLID_NOT
			|| kc_player_in_protection(iTarget))
			continue

		new Float:vTargetOrigin[3], Float:vTargetMins[3], Float:vTargetMaxs[3]
		get_entvar(iTarget, var_origin, vTargetOrigin)
		get_entvar(iTarget, var_mins, vTargetMins)
		get_entvar(iTarget, var_maxs, vTargetMaxs)

		new bool:bOverlap = true
		for (new i; i < 3; i++)
		{
			if (vOrigin[i] + vBoxMaxs[i] < vTargetOrigin[i] + vTargetMins[i]
				|| vOrigin[i] + vBoxMins[i] > vTargetOrigin[i] + vTargetMaxs[i])
			{
				bOverlap = false
				break
			}
		}

		if (!bOverlap)
			continue

		if (kc_player_apply_concentblock(iTarget, iHammerEnt, ATTACK_HEAVINESS_LOW, 150.0, true))
		{
			if (!Player[iOwner][PlrHammerReturning])
			{
				hammer_setup_arc_return(iOwner, iHammerEnt)
				hammer_start_return(iOwner, iHammerEnt)
			}
		}
		else
			hammer_damage_player(iHammerEnt, iOwner, iTarget)
	}
}

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) || !get_tr2(0, TR_AllSolid)
}

hammer_damage_player(iHammerEnt, iOwner, iTarget)
{
	if (Player[iOwner][PlrHammerReturning])
	{
		if (g_bHammerReturnHit[iOwner][iTarget])
			return

		g_bHammerReturnHit[iOwner][iTarget] = true
	}
	else
	{
		if (g_bHammerThrowHit[iOwner][iTarget])
			return

		g_bHammerThrowHit[iOwner][iTarget] = true
	}

	new Float:vHammerOrigin[3]
	get_entvar(iHammerEnt, var_origin, vHammerOrigin)
	draw_lightning_strike(vHammerOrigin)

	new Float:vForward[3]
	get_entvar(iHammerEnt, var_velocity, vForward)
	xs_vec_normalize(vForward, vForward)

	new Float:vTargetOrigin[3]
	get_entvar(iTarget, var_origin, vTargetOrigin)

	new Float:vOffset[3]
	xs_vec_sub(vTargetOrigin, vHammerOrigin, vOffset)
	vOffset[2] = 0.0

	new Float:fForwardDist = xs_vec_dot(vOffset, vForward)
	new Float:vLateral[3]
	vLateral[0] = vOffset[0] - vForward[0] * fForwardDist
	vLateral[1] = vOffset[1] - vForward[1] * fForwardDist
	vLateral[2] = 0.0

	new Float:vVelocity[3]
	if (xs_vec_len(vLateral) > 4.0)
		xs_vec_normalize(vLateral, vVelocity)
	else
		xs_vec_copy(vForward, vVelocity)

	xs_vec_mul_scalar(vVelocity, HIT_PLAYER_KNOCKBACK, vVelocity)
	vVelocity[2] = 250.0

	vTargetOrigin[2] += 8.0

	if (is_hull_vacant(vTargetOrigin, get_entvar(iTarget, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, iTarget))
	{
		engfunc(EngFunc_SetOrigin, iTarget, vTargetOrigin)
		set_entvar(iTarget, var_origin, vTargetOrigin)
	}

	set_entvar(iTarget, var_velocity, vVelocity)
	kc_player_set_bair(iTarget, FL_BAIR_NORMAL | FL_BAIR_CLIMB)
	kc_player_unfreeze(iTarget)
	kc_player_set_override_attacker(iTarget, iOwner, 4.0)

	kc_player_set_death_reason(iTarget, "DEATH_REASON_EXPLODE")
	set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
	ExecuteHamB(Ham_TakeDamage, iTarget, iOwner, iOwner, HIT_PLAYER_DAMAGE, DMG_CLUB)

	hammer_emit_hit_sound(iHammerEnt)
}

hammer_break_ice(iHammerEnt, iTarget)
{
	kc_player_unfreeze(iTarget)
	hammer_emit_hit_sound(iHammerEnt)
}

hammer_emit_hit_sound(iHammerEnt)
{
	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, random(2) ? SOUND_KNIFE_HIT1 : SOUND_KNIFE_HIT2, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

hammer_impact_knockback(iOwner, const Float:vOrigin[3])
{
	new Float:vTargetOrigin[3], Float:vTargetVelocity[3]
	new iTeam = get_user_team(iOwner)

	new iTarget = 0
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, IMPACT_RADIUS)) <= MaxClients)
	{
		if (iTarget < 1)
			break

		if (iTarget == iOwner)
		{
			send_msg_ScreenShake((1<<14), (1<<14), (1<<14), MSG_ONE, _, iTarget)
			continue
		}

		if (!is_user_alive(iTarget) || kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
			continue

		send_msg_ScreenShake((1<<14), (1<<14), (1<<14), MSG_ONE, _, iTarget)

		if (get_user_team(iTarget) == iTeam || kc_player_in_protection(iTarget))
			continue

		if (g_bHammerThrowHit[iOwner][iTarget])
			continue

		g_bHammerThrowHit[iOwner][iTarget] = true

		get_entvar(iTarget, var_origin, vTargetOrigin)
		xs_vec_sub(vTargetOrigin, vOrigin, vTargetVelocity)
		xs_vec_normalize(vTargetVelocity, vTargetVelocity)
		xs_vec_mul_scalar(vTargetVelocity, IMPACT_KNOCKBACK, vTargetVelocity)
		vTargetVelocity[2] = 250.0

		kc_player_unfreeze(iTarget)
		set_member(iTarget, m_flVelocityModifier, 0.0)
		set_entvar(iTarget, var_flags, get_entvar(iTarget, var_flags) & ~FL_ONGROUND)
		set_entvar(iTarget, var_velocity, vTargetVelocity)
		kc_player_slow(iTarget, IMPACT_SLOW_MUL, IMPACT_SLOW_TIME)
	}
}

hammer_hit_world(iHammerEnt, iOwner)
{
	remove_task(TASK_HAMMER_FLIGHT_TIMEOUT + iOwner)

	hammer_stop_loop_sound(iOwner, iHammerEnt)

	new Float:vOrigin[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)

	new Float:vVelocity[3]
	get_entvar(iHammerEnt, var_velocity, vVelocity)
	xs_vec_normalize(vVelocity, vVelocity)

	new Float:vTraceEnd[3]
	vTraceEnd[0] = vOrigin[0] + vVelocity[0] * 32.0
	vTraceEnd[1] = vOrigin[1] + vVelocity[1] * 32.0
	vTraceEnd[2] = vOrigin[2] + vVelocity[2] * 32.0

	new pTrace = create_tr2()
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, iHammerEnt, pTrace)

	new Float:fFraction
	get_tr2(pTrace, TR_flFraction, fFraction)

	if (fFraction < 1.0)
	{
		new Float:vNormal[3], Float:vAngles[3], Float:vStickOrigin[3]
		get_tr2(pTrace, TR_vecEndPos, vStickOrigin)
		get_tr2(pTrace, TR_vecPlaneNormal, vNormal)

		xs_vec_neg(vNormal, vNormal)
		vector_to_angle(vNormal, vAngles)
		xs_vec_neg(vNormal, vNormal)

		vAngles[0] += 15.0
		vAngles[2] += 15.0


		engfunc(EngFunc_SetOrigin, iHammerEnt, vStickOrigin)
		set_entvar(iHammerEnt, var_origin, vStickOrigin)
		set_entvar(iHammerEnt, var_angles, vAngles)

		xs_vec_copy(vStickOrigin, vOrigin)
	}

	free_tr2(pTrace)

	set_entvar(iHammerEnt, var_body, HAMMER_BODY_EFFECT_OFF)
	set_entvar(iHammerEnt, var_sequence, HAMMER_SEQ_IDLE)
	set_entvar(iHammerEnt, var_framerate, 1.0)
	set_entvar(iHammerEnt, var_animtime, get_gametime())

	draw_landing_effect(iHammerEnt)
	draw_rocks(vOrigin)
	draw_lightning_strike(vOrigin)
	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, SOUND_HAMMER_HITWALL, 1.0, ATTN_NORM, 0, PITCH_NORM)

	hammer_impact_knockback(iOwner, vOrigin)

	set_entvar(iHammerEnt, var_velocity, NULL_VECTOR)
	set_entvar(iHammerEnt, var_avelocity, NULL_VECTOR)
	set_entvar(iHammerEnt, var_movetype, MOVETYPE_NONE)
	set_entvar(iHammerEnt, var_solid, SOLID_NOT)
	SetTouch(iHammerEnt, "")

	Player[iOwner][PlrHammerViewHideTime] = get_gametime()
	hammer_check_view_hide(iOwner)

	SetThink(iHammerEnt, "hammer_ground_think")
	set_entvar(iHammerEnt, var_nextthink, get_gametime() + HAMMER_AUTO_RETURN_DELAY)
}

hammer_stick_coffin(iHammerEnt, iOwner, iCoffin)
{
	remove_task(TASK_HAMMER_FLIGHT_TIMEOUT + iOwner)

	hammer_stop_loop_sound(iOwner, iHammerEnt)

	new Float:vOrigin[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)

	new Float:vVelocity[3]
	get_entvar(iHammerEnt, var_velocity, vVelocity)
	xs_vec_normalize(vVelocity, vVelocity)

	new Float:vTraceEnd[3]
	vTraceEnd[0] = vOrigin[0] + vVelocity[0] * 32.0
	vTraceEnd[1] = vOrigin[1] + vVelocity[1] * 32.0
	vTraceEnd[2] = vOrigin[2] + vVelocity[2] * 32.0

	new pTrace = create_tr2()
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, iHammerEnt, pTrace)

	new Float:fFraction
	get_tr2(pTrace, TR_flFraction, fFraction)

	if (fFraction < 1.0)
	{
		new Float:vNormal[3], Float:vAngles[3], Float:vStickOrigin[3]
		get_tr2(pTrace, TR_vecEndPos, vStickOrigin)
		get_tr2(pTrace, TR_vecPlaneNormal, vNormal)

		xs_vec_neg(vNormal, vNormal)
		vector_to_angle(vNormal, vAngles)
		xs_vec_neg(vNormal, vNormal)

		vAngles[0] += 15.0
		vAngles[2] += 15.0

		engfunc(EngFunc_SetOrigin, iHammerEnt, vStickOrigin)
		set_entvar(iHammerEnt, var_origin, vStickOrigin)
		set_entvar(iHammerEnt, var_angles, vAngles)

		xs_vec_copy(vStickOrigin, vOrigin)
	}

	free_tr2(pTrace)

	set_entvar(iHammerEnt, var_body, HAMMER_BODY_EFFECT_OFF)
	set_entvar(iHammerEnt, var_sequence, HAMMER_SEQ_IDLE)
	set_entvar(iHammerEnt, var_framerate, 1.0)
	set_entvar(iHammerEnt, var_animtime, get_gametime())

	draw_landing_effect(iHammerEnt)
	draw_rocks(vOrigin)
	draw_lightning_strike(vOrigin)

	if (get_entvar(iCoffin, var_skin) + 1 == get_user_team(iOwner))
	{
		new Float:vCoffinOrigin[3]
		get_entvar(iCoffin, var_origin, vCoffinOrigin)
		hammer_impact_knockback(iOwner, vCoffinOrigin)
	}
	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, SOUND_HAMMER_HITWALL, 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_entvar(iHammerEnt, var_velocity, NULL_VECTOR)
	set_entvar(iHammerEnt, var_avelocity, NULL_VECTOR)
	set_entvar(iHammerEnt, var_movetype, MOVETYPE_NONE)
	set_entvar(iHammerEnt, var_solid, SOLID_NOT)
	SetTouch(iHammerEnt, "")

	Player[iOwner][PlrHammerViewHideTime] = get_gametime()
	hammer_check_view_hide(iOwner)

	Player[iOwner][PlrHammerStuckCoffin] = iCoffin
	Player[iOwner][PlrHammerCoffinStickTime] = get_gametime()

	SetThink(iHammerEnt, "hammer_coffin_ground_think")
	set_entvar(iHammerEnt, var_nextthink, get_gametime())
}

public hammer_coffin_ground_think(iHammerEnt)
{
	if (is_nullent(iHammerEnt))
		return

	new iOwner = get_entvar(iHammerEnt, var_owner)
	if (!is_entity_player(iOwner) || !Player[iOwner][PlrHammerEnt])
		return

	hammer_check_view_hide(iOwner)

	if (!Player[iOwner][PlrHammerReturning])
	{
		new iCoffin = Player[iOwner][PlrHammerStuckCoffin]
		new bool:bCoffinGone = iCoffin && (!is_entity(iCoffin) || (get_entvar(iCoffin, var_flags) & FL_KILLME))

		if (bCoffinGone || get_gametime() >= Player[iOwner][PlrHammerCoffinStickTime] + HAMMER_AUTO_RETURN_DELAY)
			hammer_start_return(iOwner, iHammerEnt)
	}

	set_entvar(iHammerEnt, var_nextthink, get_gametime() + 0.1)
}

public hammer_ground_think(iHammerEnt)
{
	if (is_nullent(iHammerEnt))
		return

	new iOwner = get_entvar(iHammerEnt, var_owner)
	if (!is_entity_player(iOwner) || !Player[iOwner][PlrHammerEnt])
		return

	hammer_check_view_hide(iOwner)

	if (!Player[iOwner][PlrHammerReturning])
		hammer_start_return(iOwner, iHammerEnt)
}

hammer_start_return(iOwner, iHammerEnt)
{
	if (kc_player_check_game_flag(iOwner, PLGF_IN_ITEM_ANIMATION))
	{
		remove_task(TASK_HAMMER_RETURN_RETRY + iOwner)
		set_task(HAMMER_RETURN_RETRY_DELAY, "task_hammer_return_retry", TASK_HAMMER_RETURN_RETRY + iOwner)
		return
	}

	Player[iOwner][PlrHammerReturning] = true
	kc_player_set_game_flag(iOwner, PLGF_IN_HAMMER_RETURNING)

	remove_task(TASK_HAMMER_FLIGHT_TIMEOUT + iOwner)

	set_entvar(iHammerEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iHammerEnt, var_movetype, MOVETYPE_NOCLIP)

	set_entvar(iHammerEnt, var_body, HAMMER_BODY_EFFECT2_ON)
	set_entvar(iHammerEnt, var_sequence, HAMMER_SEQ_ROTATE_RIGHT)
	set_entvar(iHammerEnt, var_framerate, 1.0)
	set_entvar(iHammerEnt, var_animtime, get_gametime())

	hammer_start_loop_sound(iOwner, iHammerEnt)

	SetTouch(iHammerEnt, "hammer_touch")
	SetThink(iHammerEnt, "hammer_think")
	set_entvar(iHammerEnt, var_nextthink, get_gametime())

	hammer_update_return_velocity(iOwner, iHammerEnt)
}

hammer_enforce_hidden_hands(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return

	if (Player[iPlayer][PlrHammerEnt])
	{
		if (!kc_player_check_game_flag(iPlayer, PLGF_IN_ITEM_ANIMATION))
			set_pev(iPlayer, pev_viewmodel, 0)
		set_pev(iPlayer, pev_weaponmodel, 0)
		set_member(iPlayer, m_szAnimExtention, ANIM_EXT_NO_HAMMER)
		return
	}

	if (Player[iPlayer][PlrHammerWindup])
	{
		hammer_check_view_hide(iPlayer)

		if (Player[iPlayer][PlrHammerViewHideTime] > 0.0 && get_gametime() >= Player[iPlayer][PlrHammerViewHideTime])
			set_member(iPlayer, m_szAnimExtention, ANIM_EXT_NO_HAMMER)
	}
}

public RG_CBasePlayer_PostThink_Post(iPlayer)
{
	hammer_enforce_hidden_hands(iPlayer)
}

public RG_CBasePlayer_PreThink_Post(iPlayer)
{
	hammer_enforce_hidden_hands(iPlayer)

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return

	new iHammerEnt = Player[iPlayer][PlrHammerEnt]

	if (iHammerEnt && (is_nullent(iHammerEnt)
		|| (get_entvar(iHammerEnt, var_flags) & FL_KILLME)))
	{
		hammer_cleanup(iPlayer)
		iHammerEnt = 0
	}

	if (iHammerEnt && !is_nullent(iHammerEnt))
	{
		if (get_entvar(iHammerEnt, var_movetype) != MOVETYPE_NONE)
			hammer_check_nearby_loop_sound(iPlayer, iHammerEnt)

		new iButton = get_entvar(iPlayer, var_button)
		new iOldButtons = get_entvar(iPlayer, var_oldbuttons)

		if (Player[iPlayer][PlrHammerReturning])
		{
			hammer_update_return_velocity(iPlayer, iHammerEnt)
		}
		else
		{
			if ((iButton & IN_USE) && !(iOldButtons & IN_USE) && hammer_return_ready(iPlayer))
				hammer_start_return(iPlayer, iHammerEnt)
			else if (get_entvar(iHammerEnt, var_movetype) != MOVETYPE_NONE
				&& hammer_touching_coffin(iHammerEnt))
				hammer_touch(iHammerEnt, Player[iPlayer][PlrHammerStuckCoffin])
			else if (hammer_touching_field_wall(iHammerEnt, iPlayer))
				hammer_start_return(iPlayer, iHammerEnt)
			else if (Player[iPlayer][PlrHammerStuckCoffin]
				&& (!is_entity(Player[iPlayer][PlrHammerStuckCoffin])
					|| (get_entvar(Player[iPlayer][PlrHammerStuckCoffin], var_flags) & FL_KILLME)))
				hammer_start_return(iPlayer, iHammerEnt)
		}

		if ((iButton & IN_RELOAD) && !(iOldButtons & IN_RELOAD))
			hammer_pull_activate(iPlayer, iHammerEnt)
	}
}

hammer_pull_activate(iPlayer, iHammerEnt)
{
	if (Player[iPlayer][PlrHammerWindup])
		return

	if (!hammer_return_ready(iPlayer))
		return

	if (Float:get_entvar(iPlayer, var_health) < RUSH_MIN_HEALTH)
		return

	if (!Player[iPlayer][PlrHammerReturning])
		hammer_start_return(iPlayer, iHammerEnt)

	Player[iPlayer][PlrHammerRecallBoosted] = true

	kc_player_set_abil3_charge(iPlayer, 0.0)
}

bool:hammer_touching_coffin(iHammerEnt)
{
	new Float:vOrigin[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)

	new iEnt = 0
	while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, 24.0)))
	{
		if (iEnt == iHammerEnt)
			continue

		new szClassname[32]
		get_entvar(iEnt, var_classname, szClassname, charsmax(szClassname))
		if (equal(szClassname, COFFIN_CLASSNAME))
		{
			new iOwner = get_entvar(iHammerEnt, var_owner)
			Player[iOwner][PlrHammerStuckCoffin] = iEnt
			return true
		}
	}

	return false
}

bool:hammer_return_ready(iPlayer)
{
	return get_gametime() - Player[iPlayer][PlrHammerThrowTime] >= HAMMER_RETURN_COOLDOWN
}

bool:hammer_touching_field_wall(iHammerEnt, iOwner)
{
	new Float:vOrigin[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)

	new iTeam = get_user_team(iOwner)

	new iEnt = 0
	while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, 24.0)))
	{
		if (iEnt != iHammerEnt && get_entvar(iEnt, var_impulse) == IMPULSE_FIELD_WALL
			&& get_entvar(iEnt, var_skin) + 1 != iTeam)
			return true
	}

	return false
}

hammer_setup_arc_return(iOwner, iHammerEnt)
{
	Player[iOwner][PlrHammerArcReturn] = true

	new Float:vOrigin[3], Float:vTargetOrigin[3], Float:vViewOfs[3], Float:vToTarget[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)
	get_entvar(iOwner, var_origin, vTargetOrigin)
	get_entvar(iOwner, var_view_ofs, vViewOfs)
	xs_vec_add(vTargetOrigin, vViewOfs, vTargetOrigin)

	xs_vec_sub(vTargetOrigin, vOrigin, vToTarget)
	new Float:fDist = xs_vec_len(vToTarget)

	xs_vec_copy(vOrigin, Player[iOwner][PlrHammerArcStart])

	new Float:vDir[3]
	xs_vec_copy(vToTarget, vDir)
	if (fDist > 0.0)
		xs_vec_normalize(vDir, vDir)

	new Float:vPerp[3]
	vPerp[0] = -vDir[1]
	vPerp[1] = vDir[0]
	vPerp[2] = 0.0

	if (xs_vec_len(vPerp) > 0.0)
		xs_vec_normalize(vPerp, vPerp)
	else
		vPerp[0] = 1.0

	if (random(2))
		xs_vec_neg(vPerp, vPerp)

	xs_vec_copy(vPerp, Player[iOwner][PlrHammerArcPerp])

	new Float:fSpeed = Player[iOwner][PlrHammerRecallBoosted] ? HAMMER_PULL_SPEED : HAMMER_RECALL_SPEED
	Player[iOwner][PlrHammerArcBowMagnitude] = fDist * HAMMER_ARC_BOW_FACTOR
	Player[iOwner][PlrHammerArcDuration] = floatmax(HAMMER_ARC_MIN_DURATION, fDist / fSpeed)
	Player[iOwner][PlrHammerArcStartTime] = get_gametime()
}

hammer_update_return_velocity(iOwner, iHammerEnt)
{
	new Float:vOrigin[3], Float:vTargetOrigin[3], Float:vViewOfs[3], Float:vToTarget[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)
	get_entvar(iOwner, var_origin, vTargetOrigin)
	get_entvar(iOwner, var_view_ofs, vViewOfs)
	xs_vec_add(vTargetOrigin, vViewOfs, vTargetOrigin)

	xs_vec_sub(vTargetOrigin, vOrigin, vToTarget)
	new Float:fDist = xs_vec_len(vToTarget)

	if (fDist < HAMMER_CATCH_RADIUS)
	{
		hammer_return_complete(iOwner, iHammerEnt)
		return
	}

	new Float:fSpeed = Player[iOwner][PlrHammerRecallBoosted] ? HAMMER_PULL_SPEED : HAMMER_RECALL_SPEED

	new Float:vAimPoint[3]
	xs_vec_copy(vTargetOrigin, vAimPoint)

	if (Player[iOwner][PlrHammerArcReturn])
	{
		new Float:fProgress = floatmin(1.0,
			(get_gametime() - Player[iOwner][PlrHammerArcStartTime]) / Player[iOwner][PlrHammerArcDuration])
		new Float:fOffset = Player[iOwner][PlrHammerArcBowMagnitude] * floatsin(fProgress * 180.0, degrees)

		vAimPoint[0] += Player[iOwner][PlrHammerArcPerp][0] * fOffset
		vAimPoint[1] += Player[iOwner][PlrHammerArcPerp][1] * fOffset
		vAimPoint[2] += Player[iOwner][PlrHammerArcPerp][2] * fOffset
	}

	new Float:vNewVelocity[3]
	xs_vec_sub(vAimPoint, vOrigin, vNewVelocity)

	if (xs_vec_len(vNewVelocity) <= 0.0)
		xs_vec_copy(vToTarget, vNewVelocity)

	xs_vec_normalize(vNewVelocity, vNewVelocity)
	xs_vec_mul_scalar(vNewVelocity, fSpeed, vNewVelocity)
	set_entvar(iHammerEnt, var_velocity, vNewVelocity)

	new Float:vAngles[3]
	vector_to_angle(vNewVelocity, vAngles)
	set_entvar(iHammerEnt, var_angles, vAngles)
}

hammer_return_complete(iOwner, iHammerEnt)
{
	if (kc_player_check_game_flag(iOwner, PLGF_IN_ITEM_ANIMATION))
	{
		set_entvar(iHammerEnt, var_velocity, Float:{0.0, 0.0, 0.0})
		remove_task(TASK_HAMMER_RETURN_RETRY + iOwner)
		set_task(HAMMER_RETURN_RETRY_DELAY, "task_hammer_return_retry", TASK_HAMMER_RETURN_RETRY + iOwner)
		return
	}

	remove_task(TASK_HAMMER_RETURN_RETRY + iOwner)

	hammer_stop_loop_sound(iOwner, iHammerEnt)

	if (Player[iOwner][PlrHammerCarriesPair])
	{
		new Float:fLeftover = Player[iOwner][PlrHammerPairEndTime] - get_gametime()
		if (fLeftover > 0.0)
		{
			new Float:fLeftoverPercent = fLeftover / UNABILITY_TIME * START_PAIR * 100.0
			kc_player_set_abil2_charge(iOwner, floatmin(100.0, kc_player_get_abil2_charge(iOwner) + fLeftoverPercent))
		}

		Player[iOwner][PlrHammerCarriesPair] = false
	}

	Player[iOwner][PlrHammerCorrectionActive] = false
	Player[iOwner][PlrHammerArcReturn] = false

	if (kc_player_get_capture(iOwner) != CAPTURE_NONE)
		kc_player_set_capture(iOwner, CAPTURE_NONE)

	if (Player[iOwner][PlrHammerRecallBoosted])
	{
		new Float:vPush[3]
		get_entvar(iHammerEnt, var_velocity, vPush)
		xs_vec_normalize(vPush, vPush)
		xs_vec_mul_scalar(vPush, HAMMER_ARRIVE_PUSH_FORCE, vPush)

		new Float:vVelocity[3]
		get_entvar(iOwner, var_velocity, vVelocity)

		if (vPush[2] > 0.0 && vVelocity[2] < 0.0)
			vVelocity[2] = 0.0

		xs_vec_add(vVelocity, vPush, vVelocity)
		set_entvar(iOwner, var_velocity, vVelocity)
	}

	rg_remove_entity(iHammerEnt)

	if (Player[iOwner][PlrHammerRecallBoosted])
	{
		new Float:fHealth = Float:get_entvar(iOwner, var_health)
		set_entvar(iOwner, var_health, floatmax(1.0, fHealth - HAMMER_PULL_SELF_DAMAGE))
	}

	Player[iOwner][PlrHammerEnt] = 0
	Player[iOwner][PlrHammerReturning] = false
	Player[iOwner][PlrHammerRecallBoosted] = false
	Player[iOwner][PlrHammerStuckCoffin] = 0

	kc_player_set_ability3_name(iOwner, "")
	kc_player_set_ability2_name(iOwner, "")

	kc_player_sub_glow(iOwner, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)
	kc_player_set_def_maxspeed(iOwner, SPEED)
	kc_player_unset_game_flag(iOwner, PLGF_IN_HAMMER_THROWN)
	kc_player_unset_game_flag(iOwner, PLGF_IN_HAMMER_RETURNING)

	hammer_reclaim_knife(iOwner)
}

hammer_reclaim_knife(iOwner)
{
	if (Player[iOwner][PlrKnife] != g_iKnifeId)
		return

	set_pev(iOwner, pev_viewmodel, g_pKnifeVStr)
	set_pev(iOwner, pev_weaponmodel, g_pKnifePStr)
	set_member(iOwner, m_szAnimExtention, ANIM_EXT_HAMMER_STR)

	new iItem = get_member(iOwner, m_pActiveItem)
	if (!is_nullent(iItem))
		ExecuteHamB(Ham_Item_Deploy, iItem)
}

hammer_cleanup(iPlayer)
{
	new iHammerEnt = Player[iPlayer][PlrHammerEnt]
	if (!iHammerEnt)
		return

	remove_task(TASK_HAMMER_FLIGHT_TIMEOUT + iPlayer)
	remove_task(TASK_HAMMER_RETURN_RETRY + iPlayer)

	if (!is_nullent(iHammerEnt))
	{
		hammer_stop_loop_sound(iPlayer, iHammerEnt)
		rg_remove_entity(iHammerEnt)
	}
	else
		remove_task(TASK_HAMMER_LOOP_SOUND + iPlayer)

	Player[iPlayer][PlrHammerEnt] = 0
	Player[iPlayer][PlrHammerReturning] = false
	Player[iPlayer][PlrHammerRecallBoosted] = false
	Player[iPlayer][PlrHammerStuckCoffin] = 0
	Player[iPlayer][PlrHammerCarriesPair] = false
	Player[iPlayer][PlrHammerCorrectionActive] = false
	Player[iPlayer][PlrHammerArcReturn] = false

	kc_player_set_ability3_name(iPlayer, "")
	kc_player_set_ability2_name(iPlayer, "")

	if (Player[iPlayer][PlrKnife] == g_iKnifeId)
	{
		set_pev(iPlayer, pev_viewmodel, g_pKnifeVStr)
		set_pev(iPlayer, pev_weaponmodel, g_pKnifePStr)
		set_member(iPlayer, m_szAnimExtention, ANIM_EXT_HAMMER_STR)
		kc_player_set_def_maxspeed(iPlayer, SPEED)
	}

	kc_player_sub_glow(iPlayer, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)

	kc_player_unset_game_flag(iPlayer, PLGF_IN_HAMMER_THROWN)
	kc_player_unset_game_flag(iPlayer, PLGF_IN_HAMMER_RETURNING)
}

public fw_Hammer_PrimaryAttack_Pre(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (Player[iPlayer][PlrKnife] == g_iKnifeId && (Player[iPlayer][PlrHammerEnt] || Player[iPlayer][PlrHammerWindup]))
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public fw_Knife_Deploy_Pre(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HAM_IGNORED

	if (Player[iPlayer][PlrHammerEnt])
	{
		set_pev(iPlayer, pev_viewmodel, 0)
		set_pev(iPlayer, pev_weaponmodel, 0)

		SetHamReturnInteger(1)
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public fw_OtherWeapon_CanDeploy_Pre(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (is_nullent(iPlayer))
		return HAM_IGNORED

	if (Player[iPlayer][PlrKnife] == g_iKnifeId && (Player[iPlayer][PlrHammerEnt] || Player[iPlayer][PlrHammerWindup]))
	{
		SetHamReturnInteger(0)
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public efk_ability3(iPlayer)
{
	if (Player[iPlayer][PlrHammerEnt] || Player[iPlayer][PlrHammerWindup])
		return PLUGIN_HANDLED

	new Float:fHealth = Float:get_entvar(iPlayer, var_health)
	if (fHealth < RUSH_MIN_HEALTH)
		return PLUGIN_HANDLED

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_HOTSPEED, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_entvar(iPlayer, var_health, fHealth - RUSH_SELF_DAMAGE)

	kc_player_rush(iPlayer, RUSH_SPEED, RUSH_TIME)

	return PLUGIN_CONTINUE
}

public task_remove_unability(iTaskId)
{
	new iPlayer = iTaskId - TASK_UNABILITY
	kc_player_unset_game_flag(iPlayer, PLGF_IN_UNABILITY)
}

draw_landing_effect(iEnt)
{
	new Float:vOrigin[3]
	get_entvar(iEnt, var_origin, vOrigin)

	new Float:vFloorOrigin[3]
	xs_vec_copy(vOrigin, vFloorOrigin)
	vFloorOrigin[2] -= 64.0

	new iTrace, Float:fFraction, iHit
	engfunc(EngFunc_TraceLine, vOrigin, vFloorOrigin, IGNORE_MONSTERS, iEnt, iTrace)
	get_tr2(iTrace, TR_vecEndPos, vFloorOrigin)
	get_tr2(iTrace, TR_flFraction, fFraction)
	get_tr2(iTrace, TR_pHit)
	free_tr2(iTrace)

	if (fFraction == 1.0)
		return

	new iDecal = random_num(138, 141)

	if (iHit)
	{
		if (!is_nullent(iHit) && (~get_entvar(iHit, var_flags) & FL_KILLME) && (get_entvar(iHit, var_solid) == SOLID_BSP))
			send_msg_TE_DECAL(vFloorOrigin, iDecal, iHit, MSG_PAS, vFloorOrigin)
	}
	else
	{
		send_msg_TE_WORLDDECAL(vFloorOrigin, iDecal, MSG_PAS, vFloorOrigin)
	}

	send_msg_TE_SPRITE(vFloorOrigin, g_pBallSmokeSpr, 8, 80, MSG_PAS, vFloorOrigin)
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

draw_lightning_strike(Float:vOrigin[3])
{
	new Float:vStartBeamOrigin[3], Float:vEndBeamOrigin[3]
	vStartBeamOrigin[0] = vOrigin[0]
	vStartBeamOrigin[1] = vOrigin[1]
	vStartBeamOrigin[2] = vOrigin[2]
	vEndBeamOrigin[0] = vOrigin[0]
	vEndBeamOrigin[1] = vOrigin[1]
	vEndBeamOrigin[2] = vOrigin[2] + 1500.0
	send_msg_TE_BEAMPOINTS(vStartBeamOrigin, vEndBeamOrigin, g_pLightningSpr, 0, 1, 2, 30, 10, {255, 255, 255}, 255, 0)
}
