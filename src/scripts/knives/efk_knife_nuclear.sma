#include <amxmodx>
#include <fakemeta>
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

#define HP				160.0
#define GRAVITY			1.0
#define SPEED			165.0
#define MINDAMAGE		10.0
#define MAXDAMAGE		25.0

#define ABIL1_NAME		"Nuclear"
#define ABIL1_CHARGE	5.2632

#define ABIL2_NAME		"Hammer"
#define ABIL2_CHARGE	8.3333

#define ABIL3_NAME		"Hot Speed"
#define ABIL3_CHARGE	10.0

#define RUSH_SPEED			280.0
#define RUSH_TIME			5.0
#define RUSH_SELF_DAMAGE	15.0
#define RUSH_MIN_HEALTH		31.0

#define UNABILITY_TIME		10.0
#define START_PAIR			0.8
#define VELOCITY_BACK		2000.0
#define BURN_CYCLES			3

#define THROW_SPEED				275.0
#define HAMMER_FLIGHT_SPEED		900.0
#define HAMMER_RECALL_SPEED		1200.0
#define HAMMER_AUTO_RETURN_DELAY	6.0

#define HAMMER_SEQ_IDLE		0
#define HAMMER_SEQ_ROTATE	1

#define HAMMER_BODY_EFFECT_OFF	0
#define HAMMER_BODY_EFFECT_ON	1


#define HAMMER_GLOW_R	255
#define HAMMER_GLOW_G	255
#define HAMMER_GLOW_B	180
#define HAMMER_GLOW_TIME	30.0

#define IMPACT_RADIUS		150.0
#define IMPACT_KNOCKBACK	1600.0
#define IMPACT_SLOW_MUL		0.5
#define IMPACT_SLOW_TIME	2.5

#define HIT_PLAYER_DAMAGE		10.0
#define HIT_PLAYER_KNOCKBACK	900.0

#define VIEW_SEQ_STAB	4
#define VIEW_SEQ_DRAW		3
#define HAMMER_WINDUP_TIME	0.3

#define TASK_HAMMER_THROW	32674
#define TASK_HAMMER_HIDE_VIEWMODEL	32675
#define TASK_HAMMER_FLIGHT_TIMEOUT	32676
#define TASK_HAMMER_LOOP_SOUND	32677

#define HAMMER_FLIGHT_TIMEOUT	12.0
#define HAMMER_LOOP_SOUND_DURATION	2.3
#define HAMMER_LOOP_SOUND_NEAR_DISTANCE	800.0

#define HAMMER_THROW_DELAY	0.1

new const MODEL_V_KNIFE[]		= "models/next21_efk/v_nuclear_knife_b02.mdl"
new const MODEL_P_KNIFE[]		= "models/next21_efk/p_nuclear_knife_a.mdl"

new const ANIM_EXT_HAMMER_STR[]	= "hammer"
new const ANIM_EXT_NO_HAMMER[]	= "claws"

new const SZ_INFO_TARGET[]		= "info_target"
new const COFFIN_CLASSNAME[]	= "next21_coffin"

new const MODEL_HAMMER[]		= "models/next21_efk/hammer_b01.mdl"

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
new const SOUND_HAMMER_LOOP[]	= "next21_efk/nuclear_hammer_loop.wav"
new const SOUND_HAMMER_HITWALL[]	= "next21_efk/nuclear_hammer_hitwall.wav"

#define TASK_UNABILITY		32673

enum _:PlayerData
{
	PlrKnife,
	Float:PairEndTime,
	PlrHammerEnt,
	bool:PlrHammerReturning,
	bool:PlrHammerWindup
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
	g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
	g_pSteamSpr, g_pBallSmokeSpr, g_pShockWaveSpr,
	g_pKnifePMdl, g_pKnifeVStr, g_pKnifePStr, g_pRockGibsMdl, g_pLightningSpr,
	Float:g_fHammerHitDelay[MAX_PLAYERS + 1],
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

	g_pSteamSpr = precache_model("sprites/steam1.spr")
	g_pBallSmokeSpr = precache_model("sprites/ballsmoke.spr")
	g_pShockWaveSpr = precache_model("sprites/shockwave.spr")
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
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_Damage")
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_PostDamage", true)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Hammer_PrimaryAttack_Pre")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Hammer_PrimaryAttack_Pre")
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_Knife_Deploy_Post", true)

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

		kc_player_set_abil2_charge(iVictim, floatmin(85.0, kc_player_get_abil2_charge(iVictim)))

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

public efk_status_draw(iPlayer, iSubject)
{
	new Float:fPair = Player[iSubject][PairEndTime] - get_gametime()
	if (fPair > 0.0)
	{
		fPair = fPair / UNABILITY_TIME * START_PAIR * 100.0

		set_hudmessage(255, 255, 255, -1.0, -0.30, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "%L %..1f%%", iPlayer, "DAMAGE_REFLECTED_COEFF", fPair)
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

	kc_player_slow(iPlayer, 1.0, 0.0)
	kc_player_set_def_maxspeed(iPlayer, THROW_SPEED)

	Player[iPlayer][PlrHammerWindup] = true
	kc_player_set_view_anim(iPlayer, VIEW_SEQ_STAB)
	rg_set_animation(iPlayer, PLAYER_ATTACK1)
	set_member(iPlayer, m_szAnimExtention, ANIM_EXT_NO_HAMMER)
	kc_player_add_glow(iPlayer, HAMMER_GLOW_TIME, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)

	if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B}, 60, MSG_ONE, _, iPlayer)

	new iItem = get_member(iPlayer, m_pActiveItem)
	if (!is_nullent(iItem))
	{
		set_member(iItem, m_Weapon_flTimeWeaponIdle, HAMMER_WINDUP_TIME + 0.5)
		set_member(iItem, m_Weapon_flNextPrimaryAttack, HAMMER_WINDUP_TIME)
		set_member(iItem, m_Weapon_flNextSecondaryAttack, HAMMER_WINDUP_TIME)
	}

	remove_task(TASK_HAMMER_THROW + iPlayer)
	set_task(HAMMER_THROW_DELAY, "task_hammer_throw", TASK_HAMMER_THROW + iPlayer)

	remove_task(TASK_HAMMER_HIDE_VIEWMODEL + iPlayer)
	set_task(HAMMER_WINDUP_TIME, "task_hide_viewmodel", TASK_HAMMER_HIDE_VIEWMODEL + iPlayer)

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

public task_hide_viewmodel(iTaskId)
{
	new iPlayer = iTaskId - TASK_HAMMER_HIDE_VIEWMODEL

	if (!is_user_alive(iPlayer) || Player[iPlayer][PlrKnife] != g_iKnifeId || !Player[iPlayer][PlrHammerEnt])
		return

	set_pev(iPlayer, pev_viewmodel, 0)
}

hammer_cancel_windup(iPlayer)
{
	remove_task(TASK_HAMMER_HIDE_VIEWMODEL + iPlayer)

	if (!Player[iPlayer][PlrHammerWindup])
		return

	Player[iPlayer][PlrHammerWindup] = false
	remove_task(TASK_HAMMER_THROW + iPlayer)
	kc_player_sub_glow(iPlayer, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)
}

hammer_throw(iPlayer)
{
	rg_set_animation(iPlayer, PLAYER_IDLE)

	kc_player_set_abil2_charge(iPlayer, 0.0)

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
	set_entvar(iHammerEnt, var_impulse, IMPULSE_KUNAI)

	new Float:vVelocity[3]
	velocity_by_aim(iPlayer, floatround(HAMMER_FLIGHT_SPEED), vVelocity)

	new Float:vAngles[3]
	vector_to_angle(vVelocity, vAngles)

	engfunc(EngFunc_SetOrigin, iHammerEnt, vOrigin)
	set_entvar(iHammerEnt, var_origin, vOrigin)
	set_entvar(iHammerEnt, var_velocity, vVelocity)
	set_entvar(iHammerEnt, var_angles, vAngles)

	set_entvar(iHammerEnt, var_body, HAMMER_BODY_EFFECT_ON)
	set_entvar(iHammerEnt, var_sequence, HAMMER_SEQ_ROTATE)
	set_entvar(iHammerEnt, var_framerate, 1.0)
	set_entvar(iHammerEnt, var_animtime, get_gametime())

	SetTouch(iHammerEnt, "hammer_touch")

	set_pev(iPlayer, pev_weaponmodel, 0)

	kc_player_set_def_maxspeed(iPlayer, THROW_SPEED)

	Player[iPlayer][PlrHammerEnt] = iHammerEnt
	Player[iPlayer][PlrHammerReturning] = false

	remove_task(TASK_HAMMER_FLIGHT_TIMEOUT + iPlayer)
	set_task(HAMMER_FLIGHT_TIMEOUT, "task_hammer_flight_timeout", TASK_HAMMER_FLIGHT_TIMEOUT + iPlayer)

	hammer_start_loop_sound(iPlayer, iHammerEnt)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_HOTSPEED, 1.0, ATTN_NORM, 0, PITCH_NORM)
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
		if (is_user_alive(iOther) && !kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY))
		{
			if (get_user_team(iOther) != get_user_team(iOwner))
			{
				if (kc_player_apply_concentblock(iOther, iHammerEnt, ATTACK_HEAVINESS_LOW, 150.0, true))
				{
					if (!Player[iOwner][PlrHammerReturning])
						hammer_start_return(iOwner, iHammerEnt)
				}
				else
					hammer_damage_player(iHammerEnt, iOwner, iOther)
			}
			else if (kc_player_in_freeze(iOther))
				hammer_break_ice(iHammerEnt, iOther)
		}

		return HC_CONTINUE
	}

	new szClassname[32]
	get_entvar(iOther, var_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, COFFIN_CLASSNAME))
	{
		engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, random(2) ? SOUND_KNIFE_HIT1 : SOUND_KNIFE_HIT2, 1.0, ATTN_NORM, 0, PITCH_NORM)
		return HC_CONTINUE
	}

	if (!Player[iOwner][PlrHammerReturning])
		hammer_hit_world(iHammerEnt, iOwner)

	return HC_CONTINUE
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
		new Float:fGameTime = get_gametime()
		if (g_fHammerHitDelay[iTarget] > fGameTime)
			return

		g_fHammerHitDelay[iTarget] = fGameTime + 0.5
	}

	new Float:vHammerOrigin[3]
	get_entvar(iHammerEnt, var_origin, vHammerOrigin)
	draw_lightning_strike(vHammerOrigin)

	new Float:vVelocity[3]
	get_entvar(iHammerEnt, var_velocity, vVelocity)

	xs_vec_normalize(vVelocity, vVelocity)
	xs_vec_mul_scalar(vVelocity, HIT_PLAYER_KNOCKBACK, vVelocity)
	vVelocity[2] = 250.0

	new Float:vTargetOrigin[3]
	get_entvar(iTarget, var_origin, vTargetOrigin)
	vTargetOrigin[2] += 8.0

	if (is_hull_vacant(vTargetOrigin, get_entvar(iTarget, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, iTarget))
	{
		engfunc(EngFunc_SetOrigin, iTarget, vTargetOrigin)
		set_entvar(iTarget, var_origin, vTargetOrigin)
	}

	set_entvar(iTarget, var_velocity, vVelocity)
	kc_player_set_bair(iTarget, FL_BAIR_NORMAL | FL_BAIR_CLIMB)
	kc_player_unfreeze(iTarget)

	kc_player_set_death_reason(iTarget, "DEATH_REASON_EXPLODE")
	set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
	ExecuteHamB(Ham_TakeDamage, iTarget, iOwner, iOwner, HIT_PLAYER_DAMAGE, DMG_CLUB)

	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, random(2) ? SOUND_KNIFE_HIT1 : SOUND_KNIFE_HIT2, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

hammer_break_ice(iHammerEnt, iTarget)
{
	kc_player_unfreeze(iTarget)
	engfunc(EngFunc_EmitSound, iHammerEnt, CHAN_STATIC, random(2) ? SOUND_KNIFE_HIT1 : SOUND_KNIFE_HIT2, 1.0, ATTN_NORM, 0, PITCH_NORM)
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

		if (get_user_team(iTarget) == iTeam)
			continue

		if (g_fHammerHitDelay[iTarget] > get_gametime())
			continue

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

	set_entvar(iHammerEnt, var_velocity, NULL_VECTOR)
	set_entvar(iHammerEnt, var_avelocity, NULL_VECTOR)
	set_entvar(iHammerEnt, var_movetype, MOVETYPE_NONE)
	set_entvar(iHammerEnt, var_solid, SOLID_NOT)
	SetTouch(iHammerEnt, "")

	SetThink(iHammerEnt, "hammer_ground_think")
	set_entvar(iHammerEnt, var_nextthink, get_gametime() + HAMMER_AUTO_RETURN_DELAY)
}

public hammer_ground_think(iHammerEnt)
{
	if (is_nullent(iHammerEnt))
		return

	new iOwner = get_entvar(iHammerEnt, var_owner)
	if (!is_entity_player(iOwner) || !Player[iOwner][PlrHammerEnt])
		return

	if (!Player[iOwner][PlrHammerReturning])
		hammer_start_return(iOwner, iHammerEnt)
}

hammer_start_return(iOwner, iHammerEnt)
{
	Player[iOwner][PlrHammerReturning] = true

	remove_task(TASK_HAMMER_FLIGHT_TIMEOUT + iOwner)

	set_entvar(iHammerEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iHammerEnt, var_movetype, MOVETYPE_NOCLIP)

	set_entvar(iHammerEnt, var_body, HAMMER_BODY_EFFECT_ON)
	set_entvar(iHammerEnt, var_sequence, HAMMER_SEQ_ROTATE)
	set_entvar(iHammerEnt, var_framerate, 1.0)
	set_entvar(iHammerEnt, var_animtime, get_gametime())

	hammer_start_loop_sound(iOwner, iHammerEnt)

	SetTouch(iHammerEnt, "hammer_touch")

	hammer_update_return_velocity(iOwner, iHammerEnt)
}

public RG_CBasePlayer_PreThink_Post(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return

	new iHammerEnt = Player[iPlayer][PlrHammerEnt]

	if (iHammerEnt && !is_nullent(iHammerEnt))
	{
		hammer_check_nearby_loop_sound(iPlayer, iHammerEnt)

		if (Player[iPlayer][PlrHammerReturning])
		{
			hammer_update_return_velocity(iPlayer, iHammerEnt)
		}
		else
		{
			new iButton = get_entvar(iPlayer, var_button)
			new iOldButtons = get_entvar(iPlayer, var_oldbuttons)

			if ((iButton & IN_USE) && !(iOldButtons & IN_USE))
				hammer_start_return(iPlayer, iHammerEnt)
			else if (hammer_touching_field_wall(iHammerEnt))
				hammer_start_return(iPlayer, iHammerEnt)
		}
	}
}

bool:hammer_touching_field_wall(iHammerEnt)
{
	new Float:vOrigin[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)

	new iEnt = 0
	while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, 24.0)))
	{
		if (iEnt != iHammerEnt && get_entvar(iEnt, var_impulse) == IMPULSE_FIELD_WALL)
			return true
	}

	return false
}

hammer_update_return_velocity(iOwner, iHammerEnt)
{
	new Float:vOrigin[3], Float:vTargetOrigin[3], Float:vViewOfs[3], Float:vVelocity[3]
	get_entvar(iHammerEnt, var_origin, vOrigin)
	get_entvar(iOwner, var_origin, vTargetOrigin)
	get_entvar(iOwner, var_view_ofs, vViewOfs)
	xs_vec_add(vTargetOrigin, vViewOfs, vTargetOrigin)

	xs_vec_sub(vTargetOrigin, vOrigin, vVelocity)
	new Float:fDist = xs_vec_len(vVelocity)

	if (fDist < 24.0)
	{
		hammer_return_complete(iOwner, iHammerEnt)
		return
	}

	xs_vec_normalize(vVelocity, vVelocity)
	xs_vec_mul_scalar(vVelocity, HAMMER_RECALL_SPEED, vVelocity)
	set_entvar(iHammerEnt, var_velocity, vVelocity)

	new Float:vAngles[3]
	vector_to_angle(vVelocity, vAngles)
	set_entvar(iHammerEnt, var_angles, vAngles)
}

hammer_return_complete(iOwner, iHammerEnt)
{
	hammer_stop_loop_sound(iOwner, iHammerEnt)

	rg_remove_entity(iHammerEnt)

	Player[iOwner][PlrHammerEnt] = 0
	Player[iOwner][PlrHammerReturning] = false

	set_pev(iOwner, pev_viewmodel, g_pKnifeVStr)
	set_pev(iOwner, pev_weaponmodel, g_pKnifePStr)
	set_member(iOwner, m_szAnimExtention, ANIM_EXT_HAMMER_STR)
	kc_player_sub_glow(iOwner, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)

	new iItem = get_member(iOwner, m_pActiveItem)
	if (!is_nullent(iItem))
		ExecuteHamB(Ham_Item_Deploy, iItem)

	kc_player_set_def_maxspeed(iOwner, SPEED)

	engfunc(EngFunc_EmitSound, iOwner, CHAN_WEAPON, SOUND_KNIFE_DEPLOY, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

hammer_cleanup(iPlayer)
{
	new iHammerEnt = Player[iPlayer][PlrHammerEnt]
	if (!iHammerEnt)
		return

	remove_task(TASK_HAMMER_FLIGHT_TIMEOUT + iPlayer)

	if (!is_nullent(iHammerEnt))
	{
		hammer_stop_loop_sound(iPlayer, iHammerEnt)
		rg_remove_entity(iHammerEnt)
	}
	else
		remove_task(TASK_HAMMER_LOOP_SOUND + iPlayer)

	Player[iPlayer][PlrHammerEnt] = 0
	Player[iPlayer][PlrHammerReturning] = false

	if (Player[iPlayer][PlrKnife] == g_iKnifeId)
	{
		set_pev(iPlayer, pev_viewmodel, g_pKnifeVStr)
		set_pev(iPlayer, pev_weaponmodel, g_pKnifePStr)
		set_member(iPlayer, m_szAnimExtention, ANIM_EXT_HAMMER_STR)
		kc_player_set_def_maxspeed(iPlayer, SPEED)
	}

	kc_player_sub_glow(iPlayer, HAMMER_GLOW_R, HAMMER_GLOW_G, HAMMER_GLOW_B)
}

public fw_Hammer_PrimaryAttack_Pre(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (Player[iPlayer][PlrKnife] == g_iKnifeId && (Player[iPlayer][PlrHammerEnt] || Player[iPlayer][PlrHammerWindup]))
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public fw_Knife_Deploy_Post(iWeapon)
{
	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return HAM_IGNORED

	if (Player[iPlayer][PlrHammerEnt])
	{
		set_pev(iPlayer, pev_viewmodel, 0)
		set_pev(iPlayer, pev_weaponmodel, 0)
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
