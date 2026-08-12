#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <next_client_api>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Blink Knife"

#define KNIFE_CLASSNAME "weapon_next21_blink"
#define KNIFE_MENUDESC  "KNIFE_BLINK_DESC"
#define KNIFE_CHATDESC  "KNIFE_BLINK_CHAT"

#define HP				100.0
#define GRAVITY			1.0
#define SPEED			250.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL     2

#define ABIL1_NAME		"Blink"
#define ABIL1_CHARGE	6.6667
#define ABIL1_TYPE		ABIL_TARGET_PLAYER
#define ABIL1_MINDIST	75.0
#define ABIL1_MAXDIST	1300.0

#define ABIL3_NAME		"Front (F) Back Portal"
#define ABIL3_CHARGE	10.0

#define START_CRIT_CHANCE	2.77
#define CON_CRIT_CHANCE		4.54
#define LIMIT_CRIT_CHANCE	40.0
#define ADD_CRIT_CHANCE		2.0

#define SPRINT_SPEED			400.0
#define SPRINT_CHARGE_REWARD	35

new const SPRINT_COLORS[][] =
{
	{100, 0, 0},
	{0, 192, 255}
}

#define MAX_DOUBLE_JUMPS				1
#define DOUBLEJUMP_SPEED_NORMALIZATION	450.0

new const CLASSNAME_PORTAL[] = "next21_blinkportal"

#define var_delay           var_fuser1

new const MODEL_V_KNIFE[] = "models/next21_efk/v_blink_knife_b04.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_blink_knife_b04.mdl"
new const MODEL_PORTAL[]  = "models/next21_efk/portal.mdl"

new const SPRITE_SPRINT_TRAIL[]	= "sprites/next21_efk/sprint_trail.spr"

new const SOUND_TELEPORT[]      = "next21_efk/portal_blink.wav"
new const SOUND_KNIFE_HITWALL[] = "next21_efk/blink_knife_hitwall.wav"
new const SOUND_KNIFE_DEPLOY[]  = "next21_efk/blink_knife_deploy.wav"

new const SOUNDS_CRIT[][] =
{
	"next21_efk/frash_explosion01.wav",
	"next21_efk/frash_explosion02.wav",
	"next21_efk/frash_explosion03.wav"
}

new const INFO_TARGET[] = "info_target"

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_SPRINT_ON,
	VIEW_SEQ_SPRINT_OUT
}

enum _:PortalSeq
{
	PORTAL_SEQ_FULL,
	PORTAL_SEQ_IDLE,
	PORTAL_SEQ_OPEN,
	PORTAL_SEQ_CLOSE
}

enum _:PlayerData
{
	PlrKnife,
	bool:PlrIsAlive,
	PlrSprintPt,
	bool:PlrInSprint,
	Float:PlrSprintExpectedSpeed,
	PlrMultiJumpNum,
	bool:PlrMultiJumpOnceInAir,
	Float:PlrCritChance,
	Float:PlrRushTime,
	Float:PlrTargetFov,
	Float:PlrCurrentFov
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData], g_pKnifePMdl, g_pSprintSpr

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_KNIFE_DEPLOY)
	precache_sound(SOUND_KNIFE_HITWALL)

	precache_model(MODEL_PORTAL)

	g_pSprintSpr = precache_model(SPRITE_SPRINT_TRAIL)

	precache_sound(SOUND_TELEPORT)

	for (new i; i < sizeof SOUNDS_CRIT; i++)
		precache_sound(SOUNDS_CRIT[i])

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
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)

	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLEABLE)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Pre")
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Pre")

	RegisterHookChain(RG_CBasePlayer_SetAnimation, "RG_CBasePlayer_SetAnimation_Pre", false)
	RegisterHookChain(RG_CBasePlayer_SetAnimation, "RG_CBasePlayer_SetAnimation_Post", true)

	register_impulse(100, "fw_PlayerFlashlight")
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
	Player[iPlayer][PlrCritChance] = START_CRIT_CHANCE
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][PlrIsAlive] = false
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		Player[iPlayer][PlrIsAlive] = true
		Player[iPlayer][PlrRushTime] = 0.0
		Player[iPlayer][PlrMultiJumpNum] = 0
		Player[iPlayer][PlrSprintPt] = 100

		if (Player[iPlayer][PlrInSprint])
		{
			Player[iPlayer][PlrInSprint] = false
			send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)
		}

		Player[iPlayer][PlrCurrentFov] = 90.0
		Player[iPlayer][PlrTargetFov] = 90.0
	}
}

public RG_CBasePlayer_PreThink_Pre(iPlayer)
{
	if (!Player[iPlayer][PlrIsAlive])
		return HC_CONTINUE

	static Float:fGameTime; fGameTime = get_gametime()

	if (Player[iPlayer][PlrKnife] == g_iKnifeId)
	{
		if (0.0 < Player[iPlayer][PlrRushTime] && Player[iPlayer][PlrRushTime] <= fGameTime)
		{
			if (kc_player_get_maxspeed(iPlayer) > SPEED)
				kc_player_set_maxspeed(iPlayer, SPEED)

			Player[iPlayer][PlrRushTime] = 0.0
			kc_player_unset_game_flag(iPlayer, PLGF_IN_SPEED_OVERRIDE)
		}
	}

	static Float:fFovUpdateTime[MAX_PLAYERS + 1]
	if (Player[iPlayer][PlrCurrentFov] != Player[iPlayer][PlrTargetFov])
	{
		if (fFovUpdateTime[iPlayer] < fGameTime)
		{
			fFovUpdateTime[iPlayer] = !fFovUpdateTime[iPlayer] ? (fGameTime + 0.01) : (fFovUpdateTime[iPlayer] + 0.01)

			Player[iPlayer][PlrCurrentFov] += Float:Player[iPlayer][PlrTargetFov] > Float:Player[iPlayer][PlrCurrentFov] ? 2.5 : -2.5

			set_entvar(iPlayer, var_fov, Float:Player[iPlayer][PlrCurrentFov])
			if (!ncl_is_client_api_ready(iPlayer))
			{
				send_msg_SetFOV(floatround(Player[iPlayer][PlrCurrentFov]), MSG_ONE, _, iPlayer)
			}
		}
	}
	else
		fFovUpdateTime[iPlayer] = 0.0

	static Float:fSprintAnimTime[MAX_PLAYERS + 1][2]
	if (Player[iPlayer][PlrInSprint])
	{
		// Keep re-adding the live (still decaying) powerspeed on top of the sprint speed
		// instead of freezing it at the value from the moment sprint started - refresh our
		// own snapshot together with the real speed so the allow-sprint check below still
		// sees them matching, and only genuinely external changes trip it.
		new Float:fLiveExpectedSpeed = SPRINT_SPEED + kc_player_get_powerspeed(iPlayer)
		if (Player[iPlayer][PlrSprintExpectedSpeed] != fLiveExpectedSpeed)
		{
			Player[iPlayer][PlrSprintExpectedSpeed] = fLiveExpectedSpeed
			kc_player_set_maxspeed(iPlayer, fLiveExpectedSpeed)
		}

		if (!player_allow_sprint(iPlayer, Player[iPlayer][PlrSprintExpectedSpeed]))
		{
			if (kc_player_get_maxspeed(iPlayer) == Player[iPlayer][PlrSprintExpectedSpeed])
				engfunc(EngFunc_SetClientMaxspeed, iPlayer, Player[iPlayer][PlrSprintExpectedSpeed])

			if (get_user_weapon(iPlayer) == CSW_KNIFE)
			{
				if (fGameTime - fSprintAnimTime[iPlayer][1] >= 0.5 && Float:get_member(iPlayer, m_flNextAttack) < 0.2)
				{
					kc_player_set_view_anim(iPlayer, VIEW_SEQ_SPRINT_OUT)
					fSprintAnimTime[iPlayer][1] = fGameTime
				}

				set_member(iPlayer, m_szAnimExtention, "knife")
			}

			if (!kc_player_in_chill(iPlayer))
			{
				send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)
			}

			if (ncl_is_client_api_ready(iPlayer))
				ncl_setfov(iPlayer, 90, 0.5)

			Player[iPlayer][PlrInSprint] = false
			Player[iPlayer][PlrTargetFov] = 90.0
			kc_player_unset_game_flag(iPlayer, PLGF_IN_SPEED_OVERRIDE)
		}

		set_member(iPlayer, m_flNextAttack, 0.2)
	}
	else
	{
		// Snapshot core's own bookkeeping value (not SPEED + powerspeed recomputed here) -
		// core clamps it to MIN_PLAYER_SPEED when powerspeed cancels SPEED out entirely,
		// and a manual recompute here would miss that clamp and never match, blocking sprint.
		new Float:fExpectedSpeed = kc_player_get_maxspeed(iPlayer)
		if (player_allow_sprint(iPlayer, fExpectedSpeed) && Player[iPlayer][PlrSprintPt] >= 20)
		{
			Player[iPlayer][PlrSprintExpectedSpeed] = fExpectedSpeed
			engfunc(EngFunc_SetClientMaxspeed, iPlayer, SPRINT_SPEED)

			if (fGameTime - fSprintAnimTime[iPlayer][0] >= 0.5)
			{
				kc_player_set_view_anim(iPlayer, VIEW_SEQ_SPRINT_ON)
				fSprintAnimTime[iPlayer][0] = fGameTime
			}

			send_msg_TE_BEAMFOLLOW(iPlayer, g_pSprintSpr, 5, 20,
				SPRINT_COLORS[get_member(iPlayer, m_iTeam) == TEAM_CT], 192)

			if (ncl_is_client_api_ready(iPlayer))
				ncl_setfov(iPlayer, 98, 0.3)

			Player[iPlayer][PlrInSprint] = true
			Player[iPlayer][PlrTargetFov] = 97.5
			// Tells core's PowerSpeed decay/update logic to leave our maxspeed alone
			// while sprint is actively driving it - otherwise it gets stomped every
			// 0.5s by the decay tick for as long as PowerSpeed stays non-zero.
			kc_player_set_game_flag(iPlayer, PLGF_IN_SPEED_OVERRIDE)
		}
	}

	static iButtons, iOldButtons, iPlayerFlags
	iButtons = get_entvar(iPlayer, var_button)
	iOldButtons = get_entvar(iPlayer, var_oldbuttons)
	iPlayerFlags = get_entvar(iPlayer, var_flags)

	static bool:bPlayerAfterDJump[MAX_PLAYERS + 1]

	if (bPlayerAfterDJump[iPlayer] && iPlayerFlags & FL_ONGROUND)
	{
		if (!kc_player_get_bunnyhop(iPlayer))
		{
			new Float:vVelocity[3]; get_entvar(iPlayer, var_velocity, vVelocity)
			new Float:flSpeedExcess = xs_vec_len_2d(vVelocity) / DOUBLEJUMP_SPEED_NORMALIZATION
			if (flSpeedExcess > 1.0)
			{
				vVelocity[0] /= flSpeedExcess
				vVelocity[1] /= flSpeedExcess

				set_entvar(iPlayer, var_velocity, vVelocity)
			}
		}
		bPlayerAfterDJump[iPlayer] = false
	}

	if ((iButtons & IN_JUMP) && (Player[iPlayer][PlrMultiJumpOnceInAir] || Player[iPlayer][PlrKnife] == g_iKnifeId))
	{
		if (!(iPlayerFlags & FL_ONGROUND) && !(iOldButtons & IN_JUMP))
		{
			// Compensate for a Razor speed theft (negative powerspeed) so it doesn't
			// count against this threshold - a real slow (frost, chill, etc.) still
			// lowers var_maxspeed on its own and correctly blocks the double jump.
			if ((Player[iPlayer][PlrMultiJumpOnceInAir] || Player[iPlayer][PlrMultiJumpNum] < MAX_DOUBLE_JUMPS)
				&& Float:get_entvar(iPlayer, var_maxspeed) - floatmin(kc_player_get_powerspeed(iPlayer), 0.0) >= 200.0
			) {
				Player[iPlayer][PlrMultiJumpNum]++

				new Float:vVelocity[3]
				get_entvar(iPlayer, var_velocity, vVelocity)
				vVelocity[2] = random_float(215.0, 225.0)
				set_entvar(iPlayer, var_velocity, vVelocity)
				set_entvar(iPlayer, var_gaitsequence, 98)

				bPlayerAfterDJump[iPlayer] = true
				Player[iPlayer][PlrMultiJumpOnceInAir] = false
			}
		}
		else if (iPlayerFlags & FL_ONGROUND) {
			Player[iPlayer][PlrMultiJumpNum] = 0
			Player[iPlayer][PlrMultiJumpOnceInAir] = false
		}
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_Killed_Pre(iVictim, iAttacker)
{
	Player[iVictim][PlrIsAlive] = false

	if (Player[iVictim][PlrInSprint])
	{
		Player[iVictim][PlrInSprint] = false
		send_msg_TE_KILLBEAM(iVictim, MSG_ALL)
	}

	if (!is_entity_player(iAttacker))
		return HC_CONTINUE

	if (iAttacker == iVictim)
		return HC_CONTINUE

	if (Player[iAttacker][PlrKnife] != g_iKnifeId)
		return HC_CONTINUE

	Player[iAttacker][PlrSprintPt] = clamp(Player[iAttacker][PlrSprintPt] + SPRINT_CHARGE_REWARD, 0, 100)

	if (Player[iAttacker][PlrCritChance] >= LIMIT_CRIT_CHANCE)
	{
		Player[iAttacker][PlrCritChance] = CON_CRIT_CHANCE
		kc_player_set_crit_chance(iAttacker, CON_CRIT_CHANCE)
	}
	else
	{
		Player[iAttacker][PlrCritChance] = koef_to_chance(chance_to_koef(Player[iAttacker][PlrCritChance]) - ADD_CRIT_CHANCE)
		kc_player_set_crit_chance(iAttacker, Player[iAttacker][PlrCritChance])
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_SetAnimation_Pre(const iPlayer, PLAYER_ANIM:iPlayerAnim)
{
	if (!Player[iPlayer][PlrMultiJumpNum])
		return HC_CONTINUE

	if (iPlayerAnim == PLAYER_JUMP || iPlayerAnim == PLAYER_SUPERJUMP)
		return HC_SUPERCEDE

	return HC_CONTINUE
}

public RG_CBasePlayer_SetAnimation_Post(const iPlayer, PLAYER_ANIM:iPlayerAnim)
{
	if (Player[iPlayer][PlrInSprint] && get_entvar(iPlayer, var_gaitsequence) == PLAYER_SEQ_RUN)
	{
		set_entvar(iPlayer, var_gaitsequence, PLAYER_SEQ_SPRINT)
		set_entvar(iPlayer, var_sequence, PLAYER_SEQ_SPRINT)
		set_entvar(iPlayer, var_frame, Float:get_member(iPlayer, m_flGaitframe))
		set_member(iPlayer, m_flLastFired, 0.0)
	}
}

public portal_think(iPortalEnt)
{
	if (get_entvar(iPortalEnt, var_sequence) == PORTAL_SEQ_CLOSE)
		set_entvar(iPortalEnt, var_flags, FL_KILLME)
	else
		portal_close(iPortalEnt)
}

bool:player_can_blink_behind(iPlayer, iTarget, Float:vEndOrigin[3]=NULL_VECTOR, Float:vEndAngles[3]=NULL_VECTOR)
{
	static Float:vAngles[3]
	get_entvar(iTarget, var_angles, vAngles)

	static Float:vOrigin[3]
	get_entvar(iTarget, var_origin, vOrigin)

	static Float:vPlayerOrigin[3]
	get_entvar(iPlayer, var_origin, vPlayerOrigin)

	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vAngles)
	vector_to_angle(vAngles, vEndAngles)
	xs_vec_neg(vAngles, vAngles)

	xs_vec_mul_scalar(vAngles, 75.0, vEndOrigin)
	xs_vec_add(vOrigin, vEndOrigin, vEndOrigin)
	vEndOrigin[2] = vOrigin[2] + 17.0

	if (is_wall_between(vOrigin, vEndOrigin, iPlayer))
		return false

	if (!is_hull_vacant(vEndOrigin, get_entvar(iPlayer, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, iPlayer))
		return false

	if (check_players_cross(vEndOrigin, iPlayer))
		return false

	return true
}

bool:teammate_should_be_blinked(iPlayer)
{
	return (~kc_player_get_options(iPlayer) & OPTION_FORBID_TEAMMATES_HELP) && (
		kc_player_in_freeze(iPlayer)
		|| kc_player_in_chill(iPlayer)
		|| Float:get_member(iPlayer, m_flVelocityModifier) < 1.0
		|| Float:get_entvar(iPlayer, var_maxspeed) < 50.0
		|| Float:get_entvar(iPlayer, var_health) < 30.0
		|| Float:get_entvar(iPlayer, var_gravity) > 1.0
		|| kc_player_get_powerdamage(iPlayer) < -16.0
		|| kc_player_get_vision(iPlayer) == VISION_BLIND
	)
}

bool:teammate_can_be_blinked(iPlayer, iTeammate, bool:bSkipSpaceCheck=false)
{
	// There is no point in helping a teammate if the player in trouble
	if (Float:get_entvar(iPlayer, var_maxspeed) < 50.0)
		return false

	if (!teammate_should_be_blinked(iTeammate))
		return false

	return bSkipSpaceCheck || player_can_blink_behind(iTeammate, iPlayer)
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (!is_entity_player(iTarget))
	{
		if (get_entvar(iTarget, var_impulse) == IMPULSE_PRESENT)
		{
			kc_player_set_crosshair(iPlayer, bDistanceAllowed ? CROSSHAIR_OK : CROSSHAIR_FAR)
			return PLUGIN_HANDLED
		}
		return PLUGIN_CONTINUE
	}

	if (!bDistanceAllowed)
		return PLUGIN_CONTINUE

	static Float:fDelay[MAX_PLAYERS + 1]
	new Float:fGameTime = get_gametime()

	if (fDelay[iPlayer] > fGameTime)
		return PLUGIN_HANDLED

	fDelay[iPlayer] = fGameTime + 0.2

	if (get_member(iPlayer, m_iTeam) == get_member(iTarget, m_iTeam))
	{
		if (teammate_can_be_blinked(iPlayer, iTarget))
			return _:CROSSHAIR_HELP

		if (!player_can_blink_behind(iPlayer, iTarget))
			return _:CROSSHAIR_CANNOT
	}
	else
	{
		if (!player_can_blink_behind(iPlayer, iTarget))
			return _:CROSSHAIR_CANNOT
	}

	return PLUGIN_CONTINUE
}

public efk_ability_pre(iPlayer, iTarget)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (get_entvar(iTarget, var_impulse) == IMPULSE_PRESENT)
	{
		new Float:vOrigin[3]
		get_entvar(iTarget, var_origin, vOrigin)
		vOrigin[2] += 20.0

		new Float:vPlayerOrigin[3]
		get_entvar(iPlayer, var_origin, vPlayerOrigin)

		new Float:vAngles[3]
		get_entvar(iPlayer, var_angles, vAngles)

		engfunc(EngFunc_EmitSound, iTarget, CHAN_STATIC, SOUND_TELEPORT, 1.0, ATTN_NORM, 0, PITCH_NORM)
		send_msg_TE_TELEPORT(vOrigin)

		if (!create_portal_pair(vOrigin, vAngles, vPlayerOrigin, vAngles, PORTAL_SEQ_CLOSE))
			return PLUGIN_HANDLED

		engfunc(EngFunc_SetOrigin, iTarget, vPlayerOrigin)
		set_entvar(iTarget, var_origin, vPlayerOrigin)

		kc_player_set_abil1_charge(iPlayer, 70.0)

	}
	else if (is_entity_player(iTarget) && get_member(iPlayer, m_iTeam) == get_member(iTarget, m_iTeam))
	{
		if (teammate_can_be_blinked(iPlayer, iTarget, .bSkipSpaceCheck=true))
		{
			if (blink_ability(iTarget, iPlayer))
				kc_player_set_abil1_charge(iPlayer, 70.0)
		}
		else if (blink_ability(iPlayer, iTarget))
		{
			kc_player_set_abil1_charge(iPlayer, 50.0)
		}

		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer, iTarget)
{
	if (kc_player_in_reflection(iTarget))
	{
		if (!blink_ability(iTarget, iPlayer))
			return PLUGIN_HANDLED

		kc_player_reflection_done(iTarget, iPlayer)
	}
	else if (!blink_ability(iPlayer, iTarget))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

bool:blink_ability(iPlayer, iTarget)
{
	new Float:vNewOrigin[3], Float:vNewAngles[3]
	if (!player_can_blink_behind(iPlayer, iTarget, vNewOrigin, vNewAngles))
		return false

	new Float:vOldOrigin[3], Float:vOldAngles[3]
	get_entvar(iPlayer, var_origin, vOldOrigin)
	get_entvar(iPlayer, var_angles, vOldAngles)
	xs_vec_neg(vOldAngles, vOldAngles)

	new bool:bIsCrit = get_member(iPlayer, m_iTeam) != get_member(iTarget, m_iTeam)
		&& random_float(0.0, 100.0) <= Player[iPlayer][PlrCritChance]
		&& kc_player_try_crit(iTarget, iPlayer)

	if (bIsCrit)
		get_entvar(iTarget, var_origin, vNewOrigin)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_TELEPORT, 1.0, ATTN_NORM, 0, PITCH_NORM)

	kc_player_unfreeze(iPlayer)

	if (kc_player_get_maxspeed(iPlayer) == SPEED)
	{
		Player[iPlayer][PlrRushTime] = get_gametime() + 0.9
		kc_player_set_maxspeed(iPlayer, 400.0)
		kc_player_set_game_flag(iPlayer, PLGF_IN_SPEED_OVERRIDE)
	}

	if (bIsCrit)
	{
		new iFlags = get_entvar(iPlayer, var_flags)
		if (!(iFlags & FL_DUCKING) && (get_entvar(iTarget, var_flags) & FL_DUCKING))
		{
			set_entvar(iPlayer, var_flags, iFlags | FL_DUCKING)
			engfunc(EngFunc_SetSize, iPlayer, {-16.0, -16.0, -18.0}, {16.0,  16.0,  32.0})
		}
	}

	engfunc(EngFunc_SetOrigin, iPlayer, vNewOrigin)
	set_entvar(iPlayer, var_origin, vNewOrigin)
	set_entvar(iPlayer, var_angles, vNewAngles)
	set_entvar(iPlayer, var_fixangle, 1)

	create_portal_pair(vOldOrigin, vOldAngles, vNewOrigin, vNewAngles, PORTAL_SEQ_FULL)

	send_msg_TE_TELEPORT(vOldOrigin)

	if (bIsCrit)
	{
		send_msg_TE_LAVASPLASH(vNewOrigin)
		send_msg_TE_LAVASPLASH(vOldOrigin)

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUNDS_CRIT[random(sizeof SOUNDS_CRIT)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		kc_player_set_death_reason(iTarget, "DEATH_REASON_RIPPED_INSIDE")
		set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iTarget, iPlayer, iPlayer, 2000.0, DMG_GENERIC | DMG_ALWAYSGIB)
	}
	else
	{
		new iWeapon = get_member(iPlayer, m_pActiveItem)
		if (!is_nullent(iWeapon))
			set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 0.3)
		send_msg_TE_IMPLOSION(vNewOrigin, 100, 45, 3)
		kc_player_check_stuck_delayed(iPlayer, 0.3)
	}

	Player[iPlayer][PlrMultiJumpOnceInAir] = true

	return true
}

public efk_ability3(iPlayer)
{
	return portal_ability(iPlayer, -250.0)
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][PlrKnife] = iKnifeId
	Player[iPlayer][PlrRushTime] = 0.0
	Player[iPlayer][PlrMultiJumpNum] = 0

	if (g_iKnifeId == iKnifeId)
		kc_player_set_crit_chance(iPlayer, Player[iPlayer][PlrCritChance])
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	new iSprintCharge = Player[iSubject][PlrSprintPt]

	if (iPlayer == iSubject)
	{
		if (Player[iPlayer][PlrInSprint])
			iSprintCharge -= 3
		else if (get_entvar(iPlayer, var_flags) & FL_ONGROUND)
			iSprintCharge += 1

		iSprintCharge = clamp(iSprintCharge, 0, 100)
		Player[iPlayer][PlrSprintPt] = iSprintCharge
	}

	if (iSprintCharge >= 20)
		set_hudmessage(0, 255, 255, 0.01, -0.77, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_STATUS)
	else
		set_hudmessage(255, 0, 0, 0.01, -0.77, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_STATUS)

	show_hudmessage(iPlayer, "Sprint (E): %d%%", iSprintCharge)

	return PLUGIN_CONTINUE
}

public fw_PlayerFlashlight(iPlayer)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (!kc_player_can_ability(iPlayer, 3))
		return PLUGIN_HANDLED

	kc_player_set_abil3_charge(iPlayer, !portal_ability(iPlayer, 250.0) ? 0.0 : 99.9)
	return PLUGIN_HANDLED
}

portal_ability(iPlayer, Float:fOffset)
{
	static Float:vOrigin[3], Float:vAngles[3], Float:vVector[3], Float:vEndOrigin[3]

	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_angles, vAngles)

	vAngles[0] = 0.0
	vAngles[2] = 0.0
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vVector)

	xs_vec_mul_scalar(vVector, fOffset, vEndOrigin)
	xs_vec_add(vOrigin, vEndOrigin, vEndOrigin)
	vEndOrigin[2] += 17.0

	if (is_wall_between(vOrigin, vEndOrigin, iPlayer))
		return PLUGIN_HANDLED

	if (!is_hull_vacant(vEndOrigin, get_entvar(iPlayer, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, iPlayer))
		return PLUGIN_HANDLED

	if (check_players_cross(vEndOrigin, iPlayer))
		return PLUGIN_HANDLED

	if (!create_portal_pair(vOrigin, vAngles, vEndOrigin, vAngles, PORTAL_SEQ_FULL))
		return PLUGIN_HANDLED

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_TELEPORT, 1.0, ATTN_NORM, 0, PITCH_NORM)

	send_msg_TE_TELEPORT(vOrigin)
	send_msg_TE_IMPLOSION(vEndOrigin, 100, 45, 3)

	kc_player_unfreeze(iPlayer)

	engfunc(EngFunc_SetOrigin, iPlayer, vEndOrigin)
	set_entvar(iPlayer, var_origin, vEndOrigin)

	kc_player_check_stuck_delayed(iPlayer, 0.3)

	Player[iPlayer][PlrMultiJumpNum] = 0

	return PLUGIN_CONTINUE
}

bool:create_portal_pair(
	Float:vEnterOrigin[3], Float:vEnterAngles[3],
	Float:vExitOrigin[3], Float:vExitAngles[3],
	iSeq)
{
	new iEnterPortalEnt = portal_create(vEnterOrigin, vEnterAngles, iSeq)
	if (iEnterPortalEnt == NULLENT)
		return false

	new iExitPortalEnt = portal_create(vExitOrigin, vExitAngles, iSeq)
	if (iExitPortalEnt == NULLENT)
	{
		rg_remove_entity(iEnterPortalEnt)
		return false
	}

	return true
}

portal_create(Float:vOrigin[3], Float:vAngles[3], iSeq)
{
	new iPortalEnt = rg_create_entity(INFO_TARGET)
	if (is_nullent(iPortalEnt))
		return NULLENT

	new Float:fGameTime = get_gametime()

	engfunc(EngFunc_SetModel, iPortalEnt, MODEL_PORTAL)
	engfunc(EngFunc_SetOrigin, iPortalEnt, vOrigin)

	set_entvar(iPortalEnt, var_origin, vOrigin)
	set_entvar(iPortalEnt, var_angles, vAngles)

	set_entvar(iPortalEnt, var_classname, CLASSNAME_PORTAL)
	set_entvar(iPortalEnt, var_solid, SOLID_NOT)
	set_entvar(iPortalEnt, var_movetype, MOVETYPE_FLY)
	set_entvar(iPortalEnt, var_rendermode, kRenderNormal)

	set_entvar(iPortalEnt, var_sequence, iSeq)
	set_entvar(iPortalEnt, var_framerate, 1.0)
	set_entvar(iPortalEnt, var_animtime, fGameTime)

	set_entvar(iPortalEnt, var_nextthink, fGameTime + 0.3)

	SetThink(iPortalEnt, "portal_think")

	return iPortalEnt
}

portal_close(iPortalEnt)
{
	new Float:fGameTime = get_gametime()

	set_entvar(iPortalEnt, var_sequence, PORTAL_SEQ_CLOSE)
	set_entvar(iPortalEnt, var_framerate, 1.0)
	set_entvar(iPortalEnt, var_animtime, fGameTime)
	set_entvar(iPortalEnt, var_nextthink, fGameTime + 0.3)
}

bool:player_allow_sprint(iPlayer, Float:fExpectedSpeed)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId)
		return false

	if (Player[iPlayer][PlrSprintPt] <= 0)
		return false

	// Compared against a snapshot of SPEED + powerspeed taken when sprint
	// started/is starting, not a freshly re-read powerspeed - powerspeed decays
	// every 0.5s in the core independently of sprint, so comparing against a live
	// value here would desync from our own frozen (PLGF_IN_SPEED_OVERRIDE) bookkeeping
	// and cut sprint every 0.5s.
	if (kc_player_get_maxspeed(iPlayer) != fExpectedSpeed)
		return false

	if (get_user_weapon(iPlayer) != CSW_KNIFE)
		return false

	if (Float:get_member(iPlayer, m_flNextAttack) > 0.0 && Float:Player[iPlayer][PlrTargetFov] == 90.0)
		return false

	if (!(get_entvar(iPlayer, var_flags) & FL_ONGROUND))
		return false

	if (get_entvar(iPlayer, var_waterlevel) >= 2)
		return false

	new iButtons = get_entvar(iPlayer, var_button)
	new iSprintButton = get_gametime() < kc_player_get_swap(iPlayer) ? IN_RELOAD : IN_USE

	if (!(iButtons & iSprintButton) || (!(iButtons & IN_FORWARD)) || ((iButtons & IN_DUCK)))
		return false

	return true
}

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)
}

bool:check_players_cross(const Float:vOrigin[3], const iPlayer)
{
	new i, j, isInters,
		Float:vPlayerOrigin[3], Float:vVelocity[3],
		Float:vMins[3], Float:vMaxs[3],
		Float:vPlayerMins[3], Float:vPlayerMaxs[3]

	get_entvar(iPlayer, var_mins, vMins)
	get_entvar(iPlayer, var_maxs, vMaxs)
	xs_vec_add(vOrigin, vMins, vMins)
	xs_vec_add(vOrigin, vMaxs, vMaxs)

	for (i = 1; i <= MaxClients; i++)
	{
		if (iPlayer == i || !Player[i][PlrIsAlive])
			continue

		get_entvar(i, var_origin, vPlayerOrigin)
		get_entvar(i, var_mins, vPlayerMins)
		get_entvar(i, var_maxs, vPlayerMaxs)
		get_entvar(i, var_velocity, vVelocity)

		xs_vec_mul_scalar(vVelocity, 0.1, vVelocity)
		xs_vec_add(vPlayerOrigin, vVelocity, vPlayerOrigin)
		xs_vec_add(vPlayerOrigin, vPlayerMins, vPlayerMins)
		xs_vec_add(vPlayerOrigin, vPlayerMaxs, vPlayerMaxs)

		isInters = 1
		for (j = 0; j < 3; j++)
			if (vMins[j] > vPlayerMaxs[j] || vMaxs[j] < vPlayerMins[j])
				isInters = 0

		if (isInters)
			return true
	}

	return false
}
