#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <beams>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Leap Knife"

#define KNIFE_CLASSNAME "weapon_next21_leap"
#define KNIFE_MENUDESC  "KNIFE_LEAP_DESC"
#define KNIFE_CHATDESC  "KNIFE_LEAP_CHAT"

#define HP				90.0
#define GRAVITY			1.0
#define SPEED			270.0
#define MINDAMAGE		7.0
#define MAXDAMAGE		10.0

#define KNIFE_LEVEL     1

#define ABIL1_NAME		"Leap"
#define ABIL1_CHARGE	5.56
#define ABIL1_TYPE		ABIL_TARGET_PLAYER
#define ABIL1_MINDIST	75.0
#define ABIL1_MAXDIST	740.0

#define ABIL2_NAME		"Upper Punch"
#define ABIL2_CHARGE	8.34

#define START_CRIT_CHANCE	2.17
#define CON_CRIT_CHANCE		3.57
#define LIMIT_CRIT_CHANCE	40.0
#define ADD_CRIT_CHANCE		2.0

new const MODEL_V_KNIFE[]	= "models/next21_efk/v_leap_knife_b03.mdl"
new const MODEL_P_KNIFE[]	= "models/next21_efk/p_leap_knife.mdl"

new const MODEL_STEAM[]		= "sprites/steam1.spr"
new const MODEL_KUNAI[]		= "models/next21_efk/tknife_a01.mdl"

new const SOUND_ABILITY[]	= "next21_efk/leap_activation.wav"
new const SOUND_LJ[]		= "next21_efk/leap_jump.wav"

#define SOUND_KNIFE_HIT1	"next21_efk/leap_knife_hit1.wav"
#define SOUND_KNIFE_STAB	"next21_efk/leap_knife_stab.wav"
#define SOUND_KNIFE_HITWALL	"next21_efk/leap_knife_hitwall.wav"
#define SOUND_KNIFE_SLASH1	"next21_efk/leap_knife_slash1.wav"
#define SOUND_KNIFE_SLASH2	"next21_efk/leap_knife_slash2.wav"

new const SOUND_THROW_TKNIFE[]	= "next21_efk/tknife_shoot1.wav"
new const SOUND_KUNAI_WALL[] 	= "next21_efk/tknife_wall.wav"
new const SOUND_KUNAI_BIND[] 	= "next21_efk/tknife_bind.wav"
new const SOUND_KUNAI_UNBIND[] 	= "next21_efk/tknife_unbind.wav"
new const SOUND_KUNAI_HIT[] 	= "next21_efk/tknife_hit.wav"

#define Player[%1][%2]		g_player_data[%1 - 1][%2]
#define PlayerF[%1][%2]		g_player_data_f[%1 - 1][%2]

#define LONGJUMP_FORCE		470.0
#define LONGJUMP_HEIGHT		275.0
#define LONGJUMP_COOLDOWN 	5.0

#define SLOW_TIME		2.3
#define UPPER_PUNCH_SLOW_TIME		1.5

#define UPPER_PUNCH_ATTACK_DELAY	1.0
#define UPPER_PUNCH_ATTACK_DISTANCE	32.0
#define UPPER_PUNCH_DAMAGE 			15.0
#define UPPER_PUNCH_FORCE 			500.0
#define UPPER_PUNCH_REPULSION 		400.0

#define FLY_FORCE 					500.0

#define KUNAI_ATTACK_DELAY			0.7
#define KUNAI_CHARGE_VAL			16.67
#define KUNAI_SPEED					2000.0
#define KUNAI_LIFETIME				10.0
#define KUNAI_DAMAGE				5.0
#define KUNAI_ACTIVATE_BIND_RADIUS	500.0
#define KUNAI_ACTIVATE_PULL_RADIUS	400.0

#define BIND_RADIUS					300.0
#define BIND_PULL_MIN_RADIUS		80.0
#define BIND_PULL_FORCE				5.0
#define BIND_PULL_FULL_FORCE		15.0
#define BIND_DESTROY_RADIUS			600.0
#define BIND_TIME					6.0
new const BIND_COLOR[3]				= {255, 146, 0}
new const Float:BIND_COLOR_VEC[3]	= {255.0, 146.0, 0.0}

new const CLASSNAME_KUNAI_[]		= CLASSNAME_KUNAI

#define INSTANCE(%0) ((%0 == -1) ? 0 : %0)

#define TASK_KUNAI_CHARGE			1000

new const SZ_INFO_TARGET[]			= "info_target"

#define var_kunai_pair				var_iuser2
#define var_kunai_target			var_iuser3

new const g_CritSounds[][] =
{
	"next21_efk/frash_explosion01.wav",
	"next21_efk/frash_explosion02.wav",
	"next21_efk/frash_explosion03.wav"
}

new const KUNAI_MODE_NAMES[][] =
{
	"Bind",
	"Pull"
}

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_UPPERPUNCH,
	VIEW_SEQ_PULL,
	VIEW_SEQ_DRAW,
	VIEW_SEQ_STAB,
	VIEW_SEQ_STABMISS,
	VIEW_SEQ_MIDSLASH1,
	VIEW_SEQ_MIDSLASH2,
	VIEW_SEQ_SHOOT,
	VIEW_SEQ_TO_TKNIFE,
	VIEW_SEQ_IDLE_TKNIFE,
	VIEW_SEQ_UPPERPUNCH_TKNIFE,
	VIEW_SEQ_PULL_TKNIFE,
	VIEW_SEQ_DRAW_TKNIFE,
	VIEW_SEQ_STAB_TKNIFE,
	VIEW_SEQ_STABMISS_TKNIFE,
	VIEW_SEQ_MIDSLASH1_TKNIFE,
	VIEW_SEQ_MIDSLASH2_TKNIFE,
	VIEW_SEQ_SHOOT_TKNIFE
}

enum KunaiMode
{
	KUNAI_MODE_BIND,
	KUNAI_MODE_PULL
}

enum _:Player_Properties
{
	Knife,
	bool:IsAlive,
	UpperPunchTarget,
	KunaiNum,
	Float:KunaiCharge,
	KunaiMode:PlrKunaiMode,
	bool:IsBinded,
	KunaiMode:BindMode,
	BindKunaiEnt,
	BindAttachEnt,
	bool:IsBindFreeMove,
	BindBeamEnt
}

enum _:Player_Properties_F
{
	Float:CritChance,
	Float:TrailTime,
	Float:LongJumpTime,
	Float:FlyDelay
}

new
	g_iKnifeId, g_pKnifeVStr, g_pKnifePMdl,
	g_player_data[32][Player_Properties], Float:g_player_data_f[32][Player_Properties_F],
	g_iStealedItem, HookChain:g_hcRadio, HookChain:g_hcThrowGrenade,
	g_pSteamSpr

public plugin_precache()
{
	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(MODEL_KUNAI)

	precache_sound(SOUND_ABILITY)
	precache_sound(SOUND_LJ)

	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_STAB)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)
	precache_sound(SOUND_THROW_TKNIFE)
	precache_sound(SOUND_KUNAI_WALL)
	precache_sound(SOUND_KUNAI_BIND)
	precache_sound(SOUND_KUNAI_UNBIND)
	precache_sound(SOUND_KUNAI_HIT)

	for (new i; i < sizeof(g_CritSounds); i++)
		precache_sound(g_CritSounds[i])

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	g_pSteamSpr = precache_model(MODEL_STEAM)
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

	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_KNIFE2)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Pre", false)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Pre")
	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Pre")
	RegisterHookChain(RG_CBasePlayerWeapon_SendWeaponAnim, "RG_CBasePlayerWeapon_SendWeaponAnim_Pre")

	register_impulse(100, "fw_PlayerFlashlight")
	register_impulse(201, "fw_PlayerSpray")

	g_hcRadio = RegisterHookChain(RG_CBasePlayer_Radio, "RG_CBasePlayer_Radio_Pre", false)
	g_hcThrowGrenade = RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "RG_CBasePlayer_ThrowGrenade_Post", true)
	DisableHookChain(g_hcRadio)
	DisableHookChain(g_hcThrowGrenade)
}

public client_putinserver(iPlayer)
{
	PlayerF[iPlayer][CritChance] = START_CRIT_CHANCE
	Player[iPlayer][IsAlive] = false
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][IsAlive] = false

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][UpperPunchTarget] == iPlayer)
		{
			Player[i][UpperPunchTarget] = 0
			break
		}
	}

	bind_remove(iPlayer)
	remove_task(TASK_KUNAI_CHARGE + iPlayer)

	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_KUNAI_)))
		if (get_entvar(iEnt, var_owner) == iPlayer || get_entvar(iEnt, var_aiment) == iPlayer)
			kunai_remove(iEnt)
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_KUNAI_)))
		kunai_remove(iEnt)
}

public RG_CBasePlayer_Spawn_Pre(iPlayer)
{
	Player[iPlayer][KunaiNum] = 0
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		Player[iPlayer][IsAlive] = true
		PlayerF[iPlayer][LongJumpTime] = 0.0
		Player[iPlayer][UpperPunchTarget] = 0
		bind_remove(iPlayer)
		remove_task(TASK_KUNAI_CHARGE + iPlayer)

		if (Player[iPlayer][Knife] == g_iKnifeId)
			start_kunai_charge_task(iPlayer)
	}
}

public RG_CBasePlayer_PreThink_Pre(iPlayer)
{
	if (!Player[iPlayer][IsAlive])
		return HC_CONTINUE

	if (kc_player_check_game_flag(iPlayer, PLGF_IN_UNABILITY))
		bind_remove(iPlayer)

	static iFlags, iUpperPunchTarget, Float:vOrigin[3], Float:vTargetOrigin[3]

	new Float:fGameTime = get_gametime()
	iUpperPunchTarget = Player[iPlayer][UpperPunchTarget]

	if (iUpperPunchTarget)
	{
		if (PlayerF[iPlayer][FlyDelay] < fGameTime
			&& !kc_player_check_game_flag(iUpperPunchTarget, PLGF_IN_UNABILITY))
		{
			new iButton = get_entvar(iPlayer, var_button), iFlyAction

			if (fGameTime < kc_player_get_swap(iPlayer))
			{
				if (iButton & IN_RELOAD)
					iFlyAction = 1
				else if (iButton & IN_USE)
					iFlyAction = 2
			}
			else
			{
				if (iButton & IN_USE)
					iFlyAction = 1
				else if (iButton & IN_RELOAD)
					iFlyAction = 2
			}

			if (iFlyAction)
			{
				new Float:vVector[3], Float:vTargetVector[3]

				get_entvar(iPlayer, var_origin, vOrigin)
				get_entvar(iPlayer, var_v_angle, vVector)

				engfunc(EngFunc_MakeVectors, vVector)
				global_get(glb_v_forward, vVector)

				get_entvar(iUpperPunchTarget, var_origin, vTargetOrigin)
				xs_vec_sub(vTargetOrigin, vOrigin, vTargetVector)

				if (xs_vec_dot(vVector, vTargetVector) >= 0.0
					&& pev(iPlayer, pev_viewmodel) == g_pKnifeVStr)
				{
					if (kc_player_get_vision(iUpperPunchTarget) != VISION_BLIND
						&& !kc_player_in_freeze(iUpperPunchTarget)
						&& !kc_player_in_chill(iUpperPunchTarget))
					{
						send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {237, 230, 33}, 40, MSG_ONE, _, iUpperPunchTarget)
					}

					kc_player_set_capture(iUpperPunchTarget, CAPTURE_NONE)
					kc_player_uninvision(iUpperPunchTarget)
					kc_player_unfreeze(iUpperPunchTarget)
					kc_player_unlevitation(iUpperPunchTarget)

					kc_player_set_anim(iPlayer, 33, 31, 350.0, 1.0)

					engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_ABILITY, 1.0, ATTN_NORM, 0, PITCH_NORM)

					kc_player_set_view_anim(iPlayer, Player[iPlayer][KunaiNum] > 0 ? VIEW_SEQ_PULL_TKNIFE : VIEW_SEQ_PULL)

					send_msg_TE_BEAMENTPOINT(iPlayer|0x1000, vTargetOrigin, g_pSteamSpr, 0, 5, 2, 10, 0, {100, 100, 100}, 250, 5)

					new Float:vVelocity[3]
					xs_vec_normalize(vTargetVector, vVelocity)

					if (iFlyAction == 1)
					{
						kc_player_unlevitation(iPlayer)
						kc_player_unfreeze(iPlayer)
						xs_vec_mul_scalar(vVelocity, FLY_FORCE, vVelocity)
						set_entvar(iPlayer, var_velocity, vVelocity)
						set_entvar(iUpperPunchTarget, var_velocity, NULL_VECTOR)
						kc_player_set_bair(iUpperPunchTarget)
					}
					else
					{
						kc_player_unlevitation(iUpperPunchTarget)
						kc_player_unfreeze(iUpperPunchTarget)
						xs_vec_mul_scalar(vVelocity, -FLY_FORCE, vVelocity)
						set_entvar(iPlayer, var_velocity, NULL_VECTOR)
						set_entvar(iUpperPunchTarget, var_velocity, vVelocity)
						kc_player_set_bair(iPlayer, FL_BAIR_LEAP)
						kc_player_set_bair(iUpperPunchTarget, FL_BAIR_NORMAL | FL_BAIR_LEAP | FL_BAIR_CLIMB)
					}

					kc_player_slow(iUpperPunchTarget, 0.25, SLOW_TIME)
					kc_player_add_glow(iUpperPunchTarget, SLOW_TIME, 255, 255, 255)

					if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
						send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 0, 0}, 35, MSG_ONE, _, iPlayer)

					iUpperPunchTarget = 0
				}

				PlayerF[iPlayer][FlyDelay] = fGameTime + 0.3
			}
		}

		if (iUpperPunchTarget)
		{
			iFlags = get_entvar(iPlayer, var_flags)

			if ((iFlags & FL_ONGROUND) || get_entvar(iPlayer, var_waterlevel) >= 2)
				iUpperPunchTarget = 0
			else
			{
				iFlags = get_entvar(iUpperPunchTarget, var_flags)
				if ((iFlags & FL_ONGROUND) || get_entvar(iUpperPunchTarget, var_waterlevel) >= 2)
					iUpperPunchTarget = 0
				else
				{
					get_entvar(iPlayer, var_origin, vOrigin)
					get_entvar(iUpperPunchTarget, var_origin, vTargetOrigin)

					if (get_distance_f(vOrigin, vTargetOrigin) > ABIL1_MAXDIST)
						iUpperPunchTarget = 0
				}
			}
		}

		Player[iPlayer][UpperPunchTarget] = iUpperPunchTarget
	}

	if (Player[iPlayer][IsBinded])
	{
		static Float:fDistance, Float:vBindOrigin[3], Float:vVelocity[3]

		get_entvar(iPlayer, var_origin, vOrigin)
		get_entvar(Player[iPlayer][BindAttachEnt], var_origin, vBindOrigin)
		fDistance = get_distance_f(vOrigin, vBindOrigin)

		if (fDistance <= BIND_DESTROY_RADIUS)
		{
			new KunaiMode:iBindMode = Player[iPlayer][BindMode]
			switch (iBindMode)
			{
				case KUNAI_MODE_BIND:
				{
					if (fDistance > BIND_RADIUS && !Player[iPlayer][IsBindFreeMove])
					{
						get_speed_vector(vOrigin, vBindOrigin, fDistance, vVelocity)
						set_entvar(iPlayer, var_velocity, vVelocity)
					}
				}
				case KUNAI_MODE_PULL:
				{
					get_speed_vector(vOrigin, vBindOrigin, fDistance, vVelocity)
					if (fDistance <= BIND_PULL_MIN_RADIUS)
					{
						xs_vec_mul_scalar(vVelocity, BIND_PULL_FULL_FORCE, vVelocity)
						vVelocity[2] = floatmin(vVelocity[2], 300.0)
						bind_remove(iPlayer)
					}
					else
					{
						xs_vec_mul_scalar(vVelocity, BIND_PULL_FORCE, vVelocity)
					}
					set_entvar(iPlayer, var_velocity, vVelocity)
				}
			}
		}
		else
			bind_remove(iPlayer)
	}

	if (Player[iPlayer][Knife] != g_iKnifeId)
		return HC_CONTINUE

	if (PlayerF[iPlayer][TrailTime] && PlayerF[iPlayer][TrailTime] <= fGameTime)
	{
		if (!kc_player_in_chill(iPlayer))
		{
			send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)
		}
		PlayerF[iPlayer][TrailTime] = 0.0
	}

	static iButtons
	iButtons = get_entvar(iPlayer, var_button)

	if (PlayerF[iPlayer][LongJumpTime] < fGameTime && (iButtons & IN_JUMP) && (iButtons & IN_DUCK) && allow_long_jump(iPlayer))
	{
		send_msg_TE_BEAMFOLLOW(iPlayer, g_pSteamSpr, 10, 5, {255, 126, 0}, 192)

		new Float:vAngles[3]
		get_entvar(iPlayer, var_v_angle, vAngles)

		new iLjButtons = IN_FORWARD
		if (!(kc_player_get_options(iPlayer) & OPTION_ONE_DIRECTION_LJ))
			iLjButtons = iButtons

		new Float:vVelocity[3]
		calc_omni_direction(vAngles[1], iLjButtons, vVelocity)
		xs_vec_mul_scalar(vVelocity, LONGJUMP_FORCE, vVelocity)
		vVelocity[2] = LONGJUMP_HEIGHT

		set_entvar(iPlayer, var_velocity, vVelocity)

		PlayerF[iPlayer][TrailTime] = fGameTime + 0.5
		PlayerF[iPlayer][LongJumpTime] = fGameTime + LONGJUMP_COOLDOWN

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_BODY, SOUND_LJ, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_Killed_Pre(iVictim, iAttacker)
{
	Player[iVictim][IsAlive] = false
	PlayerF[iVictim][LongJumpTime] = 0.0
	bind_remove(iVictim)
	remove_task(TASK_KUNAI_CHARGE + iVictim)

	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_KUNAI_)))
		if (get_entvar(iEnt, var_aiment) == iVictim)
			kunai_remove(iEnt)

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][UpperPunchTarget] == iVictim)
		{
			Player[i][UpperPunchTarget] = 0
			break
		}
	}

	if (PlayerF[iVictim][TrailTime])
	{
		if (!kc_player_in_chill(iVictim))
		{
			send_msg_TE_KILLBEAM(iVictim, MSG_ALL)
		}
		PlayerF[iVictim][TrailTime] = 0.0
	}

	if (!is_entity_player(iAttacker))
		return HC_CONTINUE

	if (iAttacker == iVictim)
		return HC_CONTINUE

	if (Player[iAttacker][Knife] != g_iKnifeId)
		return HC_CONTINUE

	if (PlayerF[iAttacker][CritChance] >= LIMIT_CRIT_CHANCE)
	{
		PlayerF[iAttacker][CritChance] = CON_CRIT_CHANCE
		kc_player_set_crit_chance(iAttacker, CON_CRIT_CHANCE)
	}
	else
	{
		PlayerF[iAttacker][CritChance] = koef_to_chance(chance_to_koef(PlayerF[iAttacker][CritChance]) - ADD_CRIT_CHANCE)
		kc_player_set_crit_chance(iAttacker, PlayerF[iAttacker][CritChance])
	}

	return HC_CONTINUE
}

public RG_CBasePlayerWeapon_SendWeaponAnim_Pre(const iItem, iAnim, iSkiplocal)
{
	if (get_member(iItem, m_iId) != WEAPON_KNIFE)
		return HC_CONTINUE

	new iPlayer = get_member(iItem, m_pPlayer)
	if (!is_user_alive(iPlayer))
		return HC_CONTINUE

	if (Player[iPlayer][KunaiNum] == 0)
		return HC_CONTINUE

	if (iAnim == VIEW_SEQ_IDLE && get_entvar(iPlayer, var_weaponanim) < VIEW_SEQ_TO_TKNIFE)
	{
		SetHookChainArg(2, ATYPE_INTEGER, VIEW_SEQ_TO_TKNIFE)
		set_member(iItem, m_Weapon_flTimeWeaponIdle, 0.76)
		return HC_CONTINUE
	}

	if (iAnim < VIEW_SEQ_TO_TKNIFE)
		SetHookChainArg(2, ATYPE_INTEGER, iAnim + VIEW_SEQ_IDLE_TKNIFE)

	return HC_CONTINUE
}

public RG_CBasePlayer_Radio_Pre(const iPlayer, const szMessageId[], szMessageVerbose[], iPitch, bool:bShowIcon)
{
	if (szMessageVerbose[0] && szMessageVerbose[3] == 'r')
		return HC_SUPERCEDE
	return HC_CONTINUE
}

public RG_CBasePlayer_ThrowGrenade_Post(const iPlayer, const iItem, Float:vSrc[3], Float:vThrow[3], Float:fTime, const usEvent)
{
	if (iItem == g_iStealedItem)
	{
		new iEnt = GetHookChainReturn(ATYPE_INTEGER)
		if (!is_nullent(iEnt))
		{
			set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME)
			set_entvar(iEnt, var_nextthink, get_gametime())
			g_iStealedItem = 0
		}
	}
}

public fw_PlayerFlashlight(iPlayer)
{
	if (!Player[iPlayer][IsAlive])
		return PLUGIN_CONTINUE

	if (Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	new iKunaiNum = Player[iPlayer][KunaiNum]

	if (iKunaiNum > 0)
	{
		if (kc_player_in_silence(iPlayer) || kc_player_get_capture(iPlayer) != CAPTURE_NONE)
			return PLUGIN_HANDLED

		if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
			return PLUGIN_HANDLED

		new iItem = get_member(iPlayer, m_pActiveItem)
		if (is_nullent(iItem))
			return PLUGIN_HANDLED

		new Float:fAttackDelay = Float:get_member(iItem, m_Weapon_flNextPrimaryAttack)

		new iLastWeaponAnim = get_entvar(iPlayer, var_weaponanim)
		if (iLastWeaponAnim == VIEW_SEQ_UPPERPUNCH_TKNIFE || iLastWeaponAnim == VIEW_SEQ_UPPERPUNCH)
			fAttackDelay -= (UPPER_PUNCH_ATTACK_DELAY - 0.8)
		else if (iLastWeaponAnim == VIEW_SEQ_SHOOT_TKNIFE || iLastWeaponAnim == VIEW_SEQ_SHOOT)
			fAttackDelay -= (KUNAI_ATTACK_DELAY * 0.3)

		if (fAttackDelay > 0.0)
			return PLUGIN_HANDLED

		new iKunaiEnt = kunai_create(iPlayer)
		if (is_nullent(iKunaiEnt))
			return PLUGIN_HANDLED

		iKunaiNum--

		set_member(iPlayer, m_flNextAttack, KUNAI_ATTACK_DELAY)
		set_member(iItem, m_Weapon_flNextPrimaryAttack, KUNAI_ATTACK_DELAY)
		set_member(iItem, m_Weapon_flNextSecondaryAttack, KUNAI_ATTACK_DELAY)
		set_member(iItem, m_Weapon_flTimeWeaponIdle, 0.86)

		kc_player_set_view_anim(iPlayer, iKunaiNum > 0 ? VIEW_SEQ_SHOOT_TKNIFE : VIEW_SEQ_SHOOT)
		rg_set_animation(iPlayer, PLAYER_ATTACK1)

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_THROW_TKNIFE, 1.0, ATTN_NORM, 0, PITCH_NORM)

		if (!task_exists(TASK_KUNAI_CHARGE + iPlayer))
			start_kunai_charge_task(iPlayer)

		Player[iPlayer][KunaiNum] = iKunaiNum
	}


	return PLUGIN_HANDLED
}

public fw_PlayerSpray(iPlayer)
{
	if (!Player[iPlayer][IsAlive])
		return PLUGIN_CONTINUE

	if (Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	Player[iPlayer][PlrKunaiMode] = _:((_:Player[iPlayer][PlrKunaiMode] + 1) % _:KunaiMode)

	return PLUGIN_HANDLED
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	static szMessage[256], iLen
	iLen = 0

	new iKunaiMode = _:Player[iSubject][PlrKunaiMode]

	iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Kunai Mode (T): %s", KUNAI_MODE_NAMES[iKunaiMode])

	if (kc_player_in_silence(iSubject))
	{
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^n...NO SIGNAL...")
	}
	else
	{
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "^nKunai Throw (F) | %d", Player[iSubject][KunaiNum])

		if (Player[iSubject][KunaiCharge] < 100.0)
			iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen,
				" (%dpt)", floatround(Player[iSubject][KunaiCharge], floatround_floor))
	}

	if (Player[iSubject][UpperPunchTarget])
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen,
			"^nHeaven (E)^nHell (R)")

	new Float:fGameTime = get_gametime()
	if (PlayerF[iSubject][LongJumpTime] > fGameTime)
		iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen,
			"^nLong Jump: (%..1f)", PlayerF[iSubject][LongJumpTime] - fGameTime)

	set_hudmessage(255, 255, 255, 0.01, -0.68, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_STATUS)
	show_hudmessage(iPlayer, szMessage)

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][Knife] = iKnifeId
	Player[iPlayer][KunaiNum] = 0
	remove_task(TASK_KUNAI_CHARGE + iPlayer)

	if (g_iKnifeId == iKnifeId)
	{
		kc_player_set_crit_chance(iPlayer, PlayerF[iPlayer][CritChance])
		start_kunai_charge_task(iPlayer)
	}
	else if (PlayerF[iPlayer][TrailTime])
	{
		if (!kc_player_in_chill(iPlayer))
		{
			send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)
		}
		PlayerF[iPlayer][TrailTime] = 0.0
	}
}

bool:teammate_can_be_leaped(iPlayer)
{
	return (~kc_player_get_options(iPlayer) & OPTION_FORBID_TEAMMATES_HELP) && (
		Float:get_member(iPlayer, m_flVelocityModifier) < 1.0
		|| Float:get_entvar(iPlayer, var_maxspeed) < 50.0
		|| kc_player_in_freeze(iPlayer)
		|| kc_player_in_chill(iPlayer)
		|| are_enemies_nearby(iPlayer)
	)
}

bool:are_enemies_nearby(iPlayer, Float:fRadius = 500.0)
{
	new iTeam = get_member(iPlayer, m_iTeam)
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][IsAlive] && iTeam != get_member(i, m_iTeam) && fm_entity_range(i, iPlayer) <= fRadius)
			return true
	}
	return false
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][Knife] != g_iKnifeId)
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

	if (get_member(iPlayer, m_iTeam) == get_member(iTarget, m_iTeam) && teammate_can_be_leaped(iTarget))
		return _:CROSSHAIR_HELP

	iAbilType = ABIL_TARGET_ENEMY
	return PLUGIN_CONTINUE
}

public efk_ability_pre(iPlayer, iTarget)
{
	if (Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (is_entity_player(iTarget))
	{
		if (get_member(iPlayer, m_iTeam) == get_member(iTarget, m_iTeam))
		{
			if (teammate_can_be_leaped(iTarget))
			{
				kc_player_unfreeze(iTarget)
				kc_player_set_bair(iTarget, FL_BAIR_LEAP)
				attract(iPlayer, iTarget, 600.0, LONGJUMP_HEIGHT)
				engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_ABILITY, 1.0, ATTN_NORM, 0, PITCH_NORM)

				kc_player_add_glow(iTarget, 0.25, 255, 255, 255)
				kc_player_set_abil1_charge(iPlayer, 65.0)
			}
			return PLUGIN_HANDLED
		}
	}
	else
	{
		new iImpulse = get_entvar(iTarget, var_impulse)

		if (iImpulse == IMPULSE_PRESENT)
		{
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_ABILITY, 1.0, ATTN_NORM, 0, PITCH_NORM)
			attract(iPlayer, iTarget, 2000.0)
			kc_player_set_abil1_charge(iPlayer, 70.0)

			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer, iTarget)
{
	if (kc_player_in_reflection(iTarget))
	{
		if (!leap(iTarget, iPlayer))
			return PLUGIN_HANDLED

		kc_player_reflection_done(iTarget, iPlayer)
	}
	else if (!leap(iPlayer, iTarget))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

bool:leap(iPlayer, iTarget)
{
	if (!steal_nade(iPlayer, iTarget))
	{
		kc_player_set_abil1_charge(iPlayer, 70.0)
		return false
	}

	if (kc_player_get_vision(iTarget) != VISION_BLIND && !kc_player_in_freeze(iTarget) && !kc_player_in_chill(iTarget))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {237, 230, 33}, 40, MSG_ONE, _, iTarget)

	new iShadowActivator = kc_player_get_shadow_activator(iTarget)
	if (iShadowActivator)
	{
		kc_player_unshadow(iShadowActivator)
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {237, 230, 33}, 40, MSG_ONE, _, iShadowActivator)
		iTarget = iShadowActivator
	}

	kc_player_uninvision(iTarget)
	kc_player_unfreeze(iTarget)
	kc_player_unlevitation(iTarget)

	kc_player_set_bair(iTarget, FL_BAIR_NORMAL | FL_BAIR_LEAP | FL_BAIR_CLIMB)
	attract(iPlayer, iTarget, 600.0, LONGJUMP_HEIGHT)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_ABILITY, 1.0, ATTN_NORM, 0, PITCH_NORM)

	kc_player_slow(iTarget, 0.25, SLOW_TIME)
	kc_player_add_glow(iTarget, SLOW_TIME, 255, 255, 255)
	kc_player_set_override_attacker(iTarget, iPlayer, 4.0)

	PlayerF[iPlayer][FlyDelay] = get_gametime() + 1.0

	if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 0, 0}, 35, MSG_ONE, _, iPlayer)

	if (random_float(0.0, 100.0) <= PlayerF[iPlayer][CritChance] && kc_player_try_crit(iTarget, iPlayer))
	{
		engfunc(EngFunc_EmitSound, iTarget, CHAN_AUTO, g_CritSounds[random(sizeof g_CritSounds)], 1.0, ATTN_NORM, 0, PITCH_NORM)
		kc_player_set_death_reason(iTarget, "DEATH_REASON_RIPPED_LEAP")
		set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iTarget, iPlayer, iPlayer, 2000.0, DMG_GENERIC | DMG_ALWAYSGIB)
	}

	return true
}

public efk_ability2(iPlayer)
{
	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return PLUGIN_HANDLED

	new iItem = get_member(iPlayer, m_pActiveItem)

	if (is_nullent(iItem))
		return PLUGIN_HANDLED

	new Float:fGameTime = get_gametime()

	if (PlayerF[iPlayer][FlyDelay] <= fGameTime)
	{
		new iLastWeaponAnim = get_entvar(iPlayer, var_weaponanim)
		if (iLastWeaponAnim != VIEW_SEQ_SHOOT_TKNIFE && iLastWeaponAnim != VIEW_SEQ_SHOOT)
		{
			if (Float:get_member(iItem, m_Weapon_flNextSecondaryAttack) > 0.0)
				return PLUGIN_HANDLED
		}
	}
	else if (PlayerF[iPlayer][FlyDelay] - fGameTime > 0.8)
		return PLUGIN_HANDLED

	set_member(iItem, m_Weapon_flNextPrimaryAttack, UPPER_PUNCH_ATTACK_DELAY)
	set_member(iItem, m_Weapon_flNextSecondaryAttack, UPPER_PUNCH_ATTACK_DELAY)
	set_member(iItem, m_Weapon_flTimeWeaponIdle, 1.4667)

	kc_player_set_view_anim(iPlayer, Player[iPlayer][KunaiNum] > 0 ? VIEW_SEQ_UPPERPUNCH_TKNIFE : VIEW_SEQ_UPPERPUNCH)

	kc_player_set_anim(iPlayer, 33, 31, 350.0, 1.0)

	new Float:vOrigin[3], Float:vVector[3], Float:vEndOrigin[3], Float:fFraction, pHit, iTraceId
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vVector)
	xs_vec_add(vOrigin, vVector, vOrigin)

	get_entvar(iPlayer, var_v_angle, vVector)
	engfunc(EngFunc_MakeVectors, vVector)
	global_get(glb_v_forward, vVector)
	xs_vec_mul_scalar(vVector, UPPER_PUNCH_ATTACK_DISTANCE, vEndOrigin)
	xs_vec_add(vOrigin, vEndOrigin, vEndOrigin)

	engfunc(EngFunc_TraceLine, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, iPlayer, (iTraceId = create_tr2()))
	get_tr2(iTraceId, TR_flFraction, fFraction)

	if (fFraction >= 1.0)
	{
		engfunc(EngFunc_TraceHull, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTraceId)
		get_tr2(iTraceId, TR_flFraction, fFraction)

		if (fFraction < 1.0)
		{
			pHit = INSTANCE(get_tr2(iTraceId, TR_pHit))

			if (!pHit || ExecuteHamB(Ham_IsBSPModel, pHit))
			{
				find_hull_intersection(vOrigin, iTraceId, Float:{-16.0, -16.0, -18.0}, Float:{16.0,  16.0,  18.0}, iPlayer)
			}
		}
	}

	get_tr2(iTraceId, TR_flFraction, fFraction)

	if (fFraction < 1.0)
	{
		global_get(glb_v_forward, vOrigin)

		pHit = INSTANCE(get_tr2(iTraceId, TR_pHit))
		if (!is_nullent(pHit))
		{
			new CaptureType:iCaptureType
			if (is_entity_player(pHit))
			{
				iCaptureType = kc_player_get_capture(pHit)
				engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_KNIFE_STAB, 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			else if (get_entvar(pHit, var_flags) & FL_MONSTER)
			{
				engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_KNIFE_STAB, 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			else
			{
				engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_KNIFE_HITWALL, 1.0, ATTN_NORM, 0, PITCH_NORM)
			}

			rg_multidmg_clear()
			ExecuteHamB(Ham_TraceAttack, pHit, iPlayer, UPPER_PUNCH_DAMAGE, vVector, iTraceId, DMG_BULLET | DMG_NEVERGIB)
			rg_multidmg_apply(iPlayer, iPlayer)

			if (is_entity_player(pHit) && Player[pHit][IsAlive]
				&& get_member(iPlayer, m_iTeam) != get_member(pHit, m_iTeam)
				&& get_tr2(iTraceId, TR_iHitgroup) != HIT_SHIELD // blocked attack
				&& !kc_player_in_protection(pHit)
				&& (iCaptureType == CAPTURE_NONE || iCaptureType == CAPTURE_WEAK))
			{
				kc_player_unlevitation(pHit)
				kc_player_unfreeze(pHit)

				set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) & ~FL_ONGROUND)
				set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) | FL_DUCKING)
				set_entvar(iPlayer, var_velocity, Float:{0.0, 0.0, UPPER_PUNCH_FORCE})

				vVector[2] = 0.0
				xs_vec_normalize(vVector, vVector)
				xs_vec_mul_scalar(vVector, UPPER_PUNCH_REPULSION, vEndOrigin)
				vEndOrigin[2] = UPPER_PUNCH_FORCE

				set_entvar(pHit, var_flags, get_entvar(iPlayer, var_flags) & ~FL_ONGROUND)
				set_entvar(pHit, var_velocity, vEndOrigin)

				kc_player_set_bair(pHit)

				Player[iPlayer][UpperPunchTarget] = pHit
				PlayerF[iPlayer][FlyDelay] = fGameTime + 0.3

				kc_player_slow(iPlayer, 0.35, UPPER_PUNCH_SLOW_TIME)

				kc_player_set_override_attacker(pHit, iPlayer, 4.0)
			}
		}
	}
	else
	{
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, !random(2) ? SOUND_KNIFE_SLASH1 : SOUND_KNIFE_SLASH2, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	free_tr2(iTraceId)

	return PLUGIN_CONTINUE
}

public efk_disenergy(iPlayer)
{
	if (Player[iPlayer][Knife] == g_iKnifeId)
	{
		if (Player[iPlayer][KunaiNum] == 2)
			Player[iPlayer][KunaiNum]--

		Player[iPlayer][KunaiCharge] = floatmin(Player[iPlayer][KunaiCharge], 50.0)

		if (!task_exists(TASK_KUNAI_CHARGE + iPlayer))
			start_kunai_charge_task(iPlayer)
	}
}

public efk_reburn(iPlayer)
{
	bind_remove(iPlayer)

	new iKunaiEnt = NULLENT
	while ((iKunaiEnt = rg_find_ent_by_class(iKunaiEnt, CLASSNAME_KUNAI_)))
		if (get_entvar(iKunaiEnt, var_aiment) == iPlayer)
			kunai_remove(iKunaiEnt)
}

public efk_swap(iPlayer, iTarget)
{
	new iKunaiEnt = NULLENT
	while ((iKunaiEnt = rg_find_ent_by_class(iKunaiEnt, CLASSNAME_KUNAI_)))
	{
		if (get_entvar(iKunaiEnt, var_owner) == iTarget
			&& get_entvar(iKunaiEnt, var_solid) != SOLID_NOT)
		{
			set_entvar(iKunaiEnt, var_owner, iPlayer)
		}
	}

	bind_retarget(iPlayer, iTarget)
}

steal_nade(iPlayer, iTarget)
{
	new iActiveItem = get_member(iTarget, m_pActiveItem)

	if (is_nullent(iActiveItem))
		return PLUGIN_HANDLED

	new iItemGrenade
	switch (get_member(iActiveItem, m_iId))
	{
		case CSW_HEGRENADE:
		{
			if (!get_pdata_int(iTarget, 388) || get_member(iActiveItem, m_flReleaseThrow) > 0)
				return PLUGIN_HANDLED

			iItemGrenade = rg_create_entity("weapon_hegrenade")
			if (is_nullent(iItemGrenade))
				return PLUGIN_HANDLED
		}
		case CSW_FLASHBANG:
		{
			if (!get_pdata_int(iTarget, 387) || get_member(iActiveItem, m_flReleaseThrow) > 0)
				return PLUGIN_HANDLED

			iItemGrenade = rg_create_entity("weapon_flashbang")
			if (is_nullent(iItemGrenade))
				return PLUGIN_HANDLED
		}
		case CSW_SMOKEGRENADE:
		{
			if (!get_pdata_int(iTarget, 389) || get_member(iActiveItem, m_flReleaseThrow) > 0)
				return PLUGIN_HANDLED

			iItemGrenade = rg_create_entity("weapon_smokegrenade")
			if (is_nullent(iItemGrenade))
				return PLUGIN_HANDLED
		}
		default: return PLUGIN_HANDLED
	}

	g_iStealedItem = iActiveItem
	EnableHookChain(g_hcRadio)
	EnableHookChain(g_hcThrowGrenade)

	set_member(iActiveItem, m_Weapon_flTimeWeaponIdle, -1.0)
	set_member(iActiveItem, m_flStartThrow, 1.0)
	set_member(iActiveItem, m_flReleaseThrow, 0)
	ExecuteHamB(Ham_Weapon_WeaponIdle, iActiveItem)

	DisableHookChain(g_hcRadio)
	DisableHookChain(g_hcThrowGrenade)
	if (g_iStealedItem)
	{
		g_iStealedItem = 0
		set_entvar(iItemGrenade, var_flags, get_entvar(iItemGrenade, var_flags) | FL_KILLME)
		set_entvar(iItemGrenade, var_nextthink, get_gametime())
		return PLUGIN_HANDLED
	}

	new iWeaponBox = rg_create_entity("weaponbox")
	if (is_nullent(iWeaponBox))
	{
		set_entvar(iItemGrenade, var_flags, get_entvar(iItemGrenade, var_flags) | FL_KILLME)
		set_entvar(iItemGrenade, var_nextthink, get_gametime())
		return PLUGIN_HANDLED
	}

	dllfunc(DLLFunc_Spawn, iItemGrenade)
	engfunc(EngFunc_SetOrigin, iItemGrenade, NULL_VECTOR)
	set_entvar(iItemGrenade, var_origin, NULL_VECTOR)

	new Float:vOrigin[3], Float:vTargetOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iTarget, var_origin, vTargetOrigin)

	set_entvar(iWeaponBox, var_stealowner, iTarget)
	set_entvar(iWeaponBox, var_stealitem, iActiveItem)

	dllfunc(DLLFunc_Spawn, iWeaponBox)
	engfunc(EngFunc_SetOrigin, iWeaponBox, vTargetOrigin)
	set_entvar(iWeaponBox, var_origin, vTargetOrigin)
	set_entvar(iWeaponBox, var_impulse, IMPULSE_WEAPONBOX)

	set_pdata_cbase(iWeaponBox, 38, iItemGrenade, 4) // m_rgpPlayerItems_CWeaponBox + 4
	set_pdata_int(iWeaponBox, 73, 1, 4) // m_rgAmmo_CWeaponBox + 1

	new Float:vVelocity[3]
	vVelocity[0] = vOrigin[0] - vTargetOrigin[0]
	vVelocity[1] = vOrigin[1] - vTargetOrigin[1]
	vVelocity[2] = vOrigin[2] - vTargetOrigin[2] + 30.0

	new Float:fLength = xs_vec_len(vVelocity)
	vVelocity[0] *= 1750.0 / fLength
	vVelocity[1] *= 1500.0 / fLength
	vVelocity[2] *= 1500.0 / fLength

	set_entvar(iWeaponBox, var_velocity, vVelocity)

	set_entvar(iItemGrenade, var_spawnflags, get_entvar(iItemGrenade, var_spawnflags) | SF_NORESPAWN)
	set_entvar(iItemGrenade, var_movetype, MOVETYPE_NONE)
	set_entvar(iItemGrenade, var_solid, SOLID_NOT)
	set_entvar(iItemGrenade, var_effects, EF_NODRAW)
	set_entvar(iItemGrenade, var_owner, iWeaponBox)
	set_member(iItemGrenade, m_Weapon_iClip, 1)

	set_pdata_cbase(iItemGrenade, 41, -1, 4) // m_pPlayer
	set_pdata_cbase(iItemGrenade, 42, -1, 4) // m_pNext

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_ABILITY, 1.0, ATTN_NORM, 0, PITCH_NORM)

	send_msg_TE_BEAMENTPOINT(iPlayer, vTargetOrigin, g_pSteamSpr, 0, 1, 2, 10, 0, {100, 100, 100}, 250, 5)

	set_task(0.1, "clear_steal_owner", iWeaponBox)

	return PLUGIN_HANDLED
}

public clear_steal_owner(iWeaponBox)
{
	if (!is_nullent(iWeaponBox) && get_entvar(iWeaponBox, var_impulse) == IMPULSE_WEAPONBOX)
		set_entvar(iWeaponBox, var_stealowner, 0)
}

attract(iPlayer, iTarget, Float:fForce, Float:fZForce = 0.0)
{
	clear_train_driver(iTarget)

	new Float:vOrigin[3], Float:vTargetOrigin[3], Float:vVelocity[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iTarget, var_origin, vTargetOrigin)

	send_msg_TE_BEAMENTPOINT(iPlayer, vTargetOrigin, g_pSteamSpr, 0, 1, 2, 10, 0, {100, 100, 100}, 250, 5)

	vVelocity[0] = vOrigin[0] - vTargetOrigin[0]
	vVelocity[1] = vOrigin[1] - vTargetOrigin[1]
	vVelocity[2] = vOrigin[2] - vTargetOrigin[2]

	new Float:fLength = xs_vec_len(vVelocity)

	vVelocity[0] *= fForce / fLength
	vVelocity[1] *= fForce / fLength
	if (fZForce == 0.0)
		vVelocity[2] = fForce / fLength
	else
		vVelocity[2] = fZForce

	set_entvar(iTarget, var_velocity, vVelocity)
}

clear_train_driver(iPlayer)
{
	if (!is_entity_player(iPlayer))
		return

	new iTrain = get_entvar(iPlayer, var_groundentity)
	new afPhysicsFlags = get_member(iPlayer, m_afPhysicsFlags)
	new iTrainFlags = get_member(iPlayer, m_iTrain)

	if (!is_nullent(iTrain) && (afPhysicsFlags & (1<<1)) && iTrainFlags != 0xc0)
	{
		set_member(iPlayer, m_iTrain, 0xc0 | 0x00)
		set_member(iPlayer, m_afPhysicsFlags, afPhysicsFlags & ~(1<<1))
		set_pdata_cbase(iTrain, 85, -1, 4) // m_pDriver
	}
}

bool:allow_long_jump(iPlayer)
{
	if (!(get_entvar(iPlayer, var_flags) & FL_ONGROUND))
		return false

	if (get_entvar(iPlayer, var_maxspeed) < SPEED)
		return false

	return true
}

find_hull_intersection(const Float:vSrc[3], &iTrace, const Float:vMins[3], const Float:vMaxs[3], const iEnt)
{
	new iTempTrace

	new Float:fFraction
	new Float:fThisDistance

	new Float:vEnd[3]
	new Float:vEndPos[3]
	new Float:vHullEnd[3]
	new Float:vMinMaxs[2][3]

	new Float:fDistance = 8192.0

	xs_vec_copy(vMins, vMinMaxs[0])
	xs_vec_copy(vMaxs, vMinMaxs[1])

	get_tr2(iTrace, TR_vecEndPos, vHullEnd)

	xs_vec_sub(vHullEnd, vSrc, vHullEnd)
	xs_vec_mul_scalar(vHullEnd, 2.0, vHullEnd)
	xs_vec_add(vHullEnd, vSrc, vHullEnd)

	engfunc(EngFunc_TraceLine, vSrc, vHullEnd, DONT_IGNORE_MONSTERS, iEnt, (iTempTrace = create_tr2()))
	get_tr2(iTempTrace, TR_flFraction, fFraction)

	if (fFraction < 1.0)
	{
		free_tr2(iTrace)

		iTrace = iTempTrace
		return
	}

	for (new j, k, i = 0; i < 2; i++)
	{
		for (j = 0; j < 2; j++)
		{
			for (k = 0; k < 2; k++)
			{
				vEnd[0] = vHullEnd[0] + vMinMaxs[i][0]
				vEnd[1] = vHullEnd[1] + vMinMaxs[j][1]
				vEnd[2] = vHullEnd[2] + vMinMaxs[k][2]

				engfunc(EngFunc_TraceLine, vSrc, vEnd, DONT_IGNORE_MONSTERS, iEnt, iTempTrace)
				get_tr2(iTempTrace, TR_flFraction, fFraction)

				if (fFraction < 1.0)
				{
					get_tr2(iTempTrace, TR_vecEndPos, vEndPos)
					xs_vec_sub(vEndPos, vSrc, vEndPos)

					if ((fThisDistance = xs_vec_len(vEndPos)) < fDistance)
					{
						free_tr2(iTrace)

						iTrace = iTempTrace;
						fDistance = fThisDistance
					}
				}
			}
		}
	}
}

start_kunai_charge_task(iPlayer)
{
	Player[iPlayer][KunaiCharge] = 0.0
	set_task(1.0, "kunai_charge_task", TASK_KUNAI_CHARGE + iPlayer, .flags = "b")
}

public kunai_charge_task(iTaskId)
{
	new iPlayer = iTaskId - TASK_KUNAI_CHARGE

	new Float:fKunaiCharge = Player[iPlayer][KunaiCharge]
	new iKunaiNum = Player[iPlayer][KunaiNum]

	fKunaiCharge += KUNAI_CHARGE_VAL
	if (fKunaiCharge >= 100.0)
	{
		if (iKunaiNum == 0)
		{
			new iItem = get_member(iPlayer, m_pActiveItem)
			if (!is_nullent(iItem)
				&& pev(iPlayer, pev_viewmodel) == g_pKnifeVStr
				&& get_entvar(iPlayer, var_weaponanim) == VIEW_SEQ_IDLE)
			{
				kc_player_set_view_anim(iPlayer, VIEW_SEQ_TO_TKNIFE)
				set_member(iItem, m_Weapon_flTimeWeaponIdle, 0.76)
			}
		}

		fKunaiCharge = 0.0
		iKunaiNum++
	}

	if (iKunaiNum >= 2)
	{
		fKunaiCharge = 100.0
		remove_task(iTaskId)
	}

	Player[iPlayer][KunaiCharge] = fKunaiCharge
	Player[iPlayer][KunaiNum] = iKunaiNum
}

kunai_create(iPlayer)
{
	new iKunaiEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iKunaiEnt))
		return NULLENT

	new Float:vOrigin[3], Float:vViewOfs[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vOrigin, vViewOfs, vOrigin)

	new Float:vAngles[3], Float:vForward[3]
	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForward)

	new Float:vVelocity[3], Float:vOffset[3]
	xs_vec_mul_scalar(vForward, 15.0, vOffset)
	xs_vec_add(vOrigin, vOffset, vOrigin)
	xs_vec_mul_scalar(vForward, KUNAI_SPEED, vVelocity)

	engfunc(EngFunc_SetModel, iKunaiEnt, MODEL_KUNAI)
	engfunc(EngFunc_SetOrigin, iKunaiEnt, vOrigin)
	engfunc(EngFunc_SetSize, iKunaiEnt, Float:{-4.0, -4.0, -2.0}, Float:{4.0, 4.0, 2.0})
	set_entvar(iKunaiEnt, var_velocity, vVelocity)

	vector_to_angle(vForward, vAngles)
	set_entvar(iKunaiEnt, var_origin, vOrigin)
	set_entvar(iKunaiEnt, var_angles, vAngles)

	set_entvar(iKunaiEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iKunaiEnt, var_movetype, MOVETYPE_BOUNCEMISSILE)
	set_entvar(iKunaiEnt, var_classname, CLASSNAME_KUNAI_)
	set_entvar(iKunaiEnt, var_impulse, IMPULSE_KUNAI)
	set_entvar(iKunaiEnt, var_owner, iPlayer)
	set_entvar(iKunaiEnt, var_aiment, 0)
	set_entvar(iKunaiEnt, var_nextthink, get_gametime() + KUNAI_LIFETIME)

	set_entvar(iKunaiEnt, var_kunai_pair, 0)
	set_entvar(iKunaiEnt, var_kunai_target, 0)

	SetThink(iKunaiEnt, "kunai_think")
	SetTouch(iKunaiEnt, "kunai_touch")

	send_msg_TE_BEAMFOLLOW(iKunaiEnt, g_pSteamSpr, 4, 1, BIND_COLOR, 100)

	return iKunaiEnt
}

public kunai_think(iEnt)
{
	kunai_remove(iEnt)
}

public kunai_touch(iEnt, iOther)
{
	if (!iOther)
	{
		kunai_stop(iEnt)
		return HC_CONTINUE
	}

	if (is_entity_player(iOther))
	{
		if (!Player[iOther][IsAlive])
			return HC_CONTINUE

		new iOwner = get_entvar(iEnt, var_owner)

		if (is_entity_player(iOwner) && get_member(iOwner, m_iTeam) == get_member(iOther, m_iTeam))
			return HC_CONTINUE

		if (kc_player_apply_concentblock(iOther, iEnt,
			ATTACK_HEAVINESS_LOW, 150.0, true))
		{
			new Float:vOrigin[3]
			get_entvar(iEnt, var_origin, vOrigin)

			send_msg_TE_SPARKS(vOrigin)

			new Float:vVelocity[3]
			get_entvar(iEnt, var_velocity, vVelocity)

			new Float:fSpeed = xs_vec_len(vVelocity)
			velocity_by_aim(iOther, floatround(fSpeed), vVelocity)

			new Float:vAngles[3]
			vector_to_angle(vVelocity, vAngles)

			set_entvar(iEnt, var_velocity, vVelocity)
			set_entvar(iEnt, var_angles, vAngles)
			set_entvar(iEnt, var_owner, iOther)

			return HC_CONTINUE
		}

		kc_player_set_death_reason(iOther, "DEATH_REASON_KUNAI")
		set_member(iOther, m_LastHitGroup, HIT_GENERIC)
		engfunc(EngFunc_EmitSound, iOther, CHAN_WEAPON, SOUND_KUNAI_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM)
		create_directed_bloodstream(iEnt)

		ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iOwner, KUNAI_DAMAGE, DMG_GENERIC)

		if (!Player[iOther][IsAlive] || !is_entity_player(iOwner))
		{
			kunai_remove(iEnt)
			return HC_CONTINUE
		}

		set_entvar(iEnt, var_aiment, iOther)
		set_entvar(iEnt, var_effects, EF_NODRAW)

		set_entvar(iEnt, var_solid, SOLID_NOT)
		set_entvar(iEnt, var_velocity, NULL_VECTOR)
		set_entvar(iEnt, var_nextthink, get_gametime() + KUNAI_LIFETIME)

		if (!kunai_is_target_available(iOther, iOwner))
			return HC_CONTINUE

		new Float:fActivateRadius = KUNAI_ACTIVATE_BIND_RADIUS
		if (Player[iOwner][PlrKunaiMode] == KUNAI_MODE_PULL)
			fActivateRadius = KUNAI_ACTIVATE_PULL_RADIUS

		new iPairKunaiEnt = kunai_find_best_pair(iEnt, iOwner, fActivateRadius, false)
		if (iPairKunaiEnt > 0)
			kunai_activate(iEnt, iPairKunaiEnt, iOwner)

		return HC_CONTINUE
	}

	switch (get_entvar(iOther, var_impulse))
	{
		case IMPULSE_FAKEPLAYER:
		{
			new iOwner = get_entvar(iEnt, var_owner)
			if (is_entity_player(iOwner) && get_member(iOwner, m_iTeam) != get_entvar(iOther, var_team))
				ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iOwner, KUNAI_DAMAGE, DMG_GENERIC)
		}
		case IMPULSE_ZOMBIE:
		{
			new iOwner = get_entvar(iEnt, var_owner)
			if (is_entity_player(iOwner) && get_member(iOwner, m_iTeam) != get_entvar(iOther, var_skin) + 1)
			{
				ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iOwner, KUNAI_DAMAGE, DMG_GENERIC)
				kunai_remove(iEnt)
			}
		}
		case IMPULSE_BUG:
		{
			new iOwner = get_entvar(iEnt, var_owner)
			if (is_entity_player(iOwner) && get_member(iOwner, m_iTeam) != get_entvar(iOther, var_skin) + 1)
			{
				ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iOwner, KUNAI_DAMAGE, DMG_GENERIC)
				kunai_remove(iEnt)
			}
		}
		default:
		{
			if (get_entvar(iOther, var_solid) > SOLID_TRIGGER)
			{
				if (FClassnameIs(iOther, "func_breakable")
					&& get_entvar(iOther, var_rendermode) != kRenderNormal)
				{
					new iOwner = get_entvar(iEnt, var_owner)
					ExecuteHamB(Ham_TakeDamage, iOther, iEnt, iOwner, 8000.0, DMG_GENERIC)

					set_entvar(iEnt, var_movetype, MOVETYPE_BOUNCE)

					new Float:vVelocity[3]
					get_entvar(iEnt, var_velocity, vVelocity)
					xs_vec_mul_scalar(vVelocity, -0.5, vVelocity)
					set_entvar(iEnt, var_velocity, vVelocity)
				}
				else
				{
					kunai_stop(iEnt)
				}
			}
		}
	}

	return HC_CONTINUE
}

kunai_stop(iEnt)
{
	engfunc(EngFunc_EmitSound, iEnt, CHAN_AUTO, SOUND_KUNAI_WALL, 1.0, ATTN_NORM, 0, PITCH_NORM)

	// Stuck in the wall
	new Float:vMins[3], Float:vMaxs[3]
	get_entvar(iEnt, var_mins, vMins)
	get_entvar(iEnt, var_maxs, vMaxs)
	xs_vec_add(vMins, Float:{-0.5, -0.5, -0.5}, vMins)
	xs_vec_add(vMaxs, Float:{0.5, 0.5, 0.5}, vMaxs)
	engfunc(EngFunc_SetSize, iEnt, vMins, vMaxs)

	set_entvar(iEnt, var_solid, SOLID_NOT)
	set_entvar(iEnt, var_movetype, MOVETYPE_TOSS)
	set_entvar(iEnt, var_velocity, NULL_VECTOR)
	set_entvar(iEnt, var_nextthink, get_gametime() + KUNAI_LIFETIME)

	new iOwner = get_entvar(iEnt, var_owner)

	if (!is_entity_player(iOwner))
		return

	new Float:fActivateRadius = KUNAI_ACTIVATE_BIND_RADIUS
	if (Player[iOwner][PlrKunaiMode] == KUNAI_MODE_PULL)
		fActivateRadius = KUNAI_ACTIVATE_PULL_RADIUS

	new iPairKunaiEnt = kunai_find_best_pair(iEnt, iOwner, fActivateRadius, true)
	if (iPairKunaiEnt > 0)
		kunai_activate(iPairKunaiEnt, iEnt, iOwner)
}

bool:kunai_is_target_available(iTarget, iOwner)
{
	if (is_entity_player(iTarget))
	{
		if (!Player[iTarget][IsAlive]
			|| (is_entity_player(iOwner) && get_member(iTarget, m_iTeam) == get_member(iOwner, m_iTeam))
			|| kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
		{
			return false
		}

		return true
	}

	return false
}

kunai_find_best_pair(iEnt, iOwner, Float:fMaxDistance, bool:bOnlyAttached)
{
	new iBestKunaiEnt, Float:fBestDistance = fMaxDistance
	new Float:vOrigin[3], Float:vPairOrigin[3], Float:fDistance, iAimEnt

	iAimEnt = get_entvar(iEnt, var_aiment)
	get_entvar(iAimEnt ? iAimEnt : iEnt, var_origin, vOrigin)

	new iPairKunaiEnt = NULLENT, iPairAimEnt
	while ((iPairKunaiEnt = rg_find_ent_by_class(iPairKunaiEnt, CLASSNAME_KUNAI_)))
	{
		if (iEnt == iPairKunaiEnt || get_entvar(iPairKunaiEnt, var_owner) != iOwner)
			continue

		iPairAimEnt = get_entvar(iPairKunaiEnt, var_aiment)
		if (iPairAimEnt)
		{
			if (iPairAimEnt == iAimEnt)
				continue

			if (!kunai_is_target_available(iPairAimEnt, iOwner))
				continue

			get_entvar(iPairAimEnt, var_origin, vPairOrigin)
		}
		else
		{
			if (bOnlyAttached)
				continue

			get_entvar(iPairKunaiEnt, var_origin, vPairOrigin)
		}

		fDistance = get_distance_f(vOrigin, vPairOrigin)
		if (fDistance > fMaxDistance)
			continue

		if (is_wall_between(vOrigin, vPairOrigin, iEnt))
			continue

		if (fDistance < fBestDistance)
		{
			fBestDistance = fDistance
			iBestKunaiEnt = iPairKunaiEnt
		}
	}

	return iBestKunaiEnt
}

kunai_activate(iEnt, iPairKunaiEnt, iOwner)
{
	new iTarget = get_entvar(iEnt, var_aiment)
	if (!iTarget)
		return

	new iPairAimEnt = get_entvar(iPairKunaiEnt, var_aiment)
	new KunaiMode:iBindMode = Player[iOwner][PlrKunaiMode]

	bind_set(iTarget, iEnt, iPairKunaiEnt, iBindMode, false)
	kc_player_set_override_attacker(iTarget, iOwner, 4.0)

	if (is_entity_player(iPairAimEnt))
	{
		bind_set(iPairAimEnt, iPairKunaiEnt, iEnt, iBindMode, true)
		kc_player_set_override_attacker(iPairAimEnt, iOwner, 4.0)
	}

	new Float:fLifeTime
	switch (iBindMode)
	{
		case KUNAI_MODE_BIND: fLifeTime = get_gametime() + BIND_TIME
		case KUNAI_MODE_PULL: fLifeTime = get_gametime() + 1.0
	}

	engfunc(EngFunc_EmitSound, iEnt, CHAN_AUTO, SOUND_KUNAI_BIND, 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_entvar(iEnt, var_owner, 0)
	set_entvar(iEnt, var_nextthink, fLifeTime)
	set_entvar(iEnt, var_kunai_pair, iPairKunaiEnt)
	set_entvar(iEnt, var_kunai_target, iTarget)

	set_entvar(iPairKunaiEnt, var_owner, 0)
	set_entvar(iPairKunaiEnt, var_nextthink, fLifeTime)
	set_entvar(iPairKunaiEnt, var_kunai_pair, iEnt)
	set_entvar(iPairKunaiEnt, var_kunai_target, iPairAimEnt)
}

kunai_remove(iEnt)
{
	new iTarget = get_entvar(iEnt, var_kunai_target)
	if (is_entity_player(iTarget))
	{
		if (Player[iTarget][IsBinded] && Player[iTarget][BindKunaiEnt] == iEnt)
		{
			Player[iTarget][BindKunaiEnt] = 0
			bind_remove(iTarget)
		}
	}

	new iPairKunaiEnt = get_entvar(iEnt, var_kunai_pair)
	if (iPairKunaiEnt)
	{
		set_entvar(iPairKunaiEnt, var_kunai_pair, 0)
		kunai_remove(iPairKunaiEnt)
	}

	set_entvar(iEnt, var_kunai_pair, 0)
	set_entvar(iEnt, var_owner, 0)
	set_entvar(iEnt, var_aiment, 0)
	rg_remove_entity(iEnt)
}

bind_set(iPlayer, iKunaiEnt, iPairKunaiEnt, KunaiMode:iBindMode, bool:bFreeMove)
{
	bind_remove(iPlayer)

	new iAttachEnt = get_entvar(iPairKunaiEnt, var_aiment)
	if (!iAttachEnt)
		iAttachEnt = iPairKunaiEnt

	Player[iPlayer][IsBinded] = true
	Player[iPlayer][BindKunaiEnt] = iKunaiEnt
	Player[iPlayer][BindAttachEnt] = iAttachEnt
	Player[iPlayer][BindMode] = iBindMode
	Player[iPlayer][IsBindFreeMove] = bFreeMove

	if (iBindMode == KUNAI_MODE_PULL)
	{
		clear_train_driver(iPlayer)
		kc_player_set_bair(iPlayer, FL_BAIR_CLIMB)
	}

	if (!bFreeMove)
	{
		new iBeamEnt = Beam_Create(MODEL_STEAM, 20.0)
		if (!is_nullent(iBeamEnt))
		{
			Beam_EntsInit(iBeamEnt, iPlayer, iAttachEnt)
			Beam_SetColor(iBeamEnt, BIND_COLOR_VEC)
		}
		Player[iPlayer][BindBeamEnt] = iBeamEnt
	}
}

bind_remove(iPlayer)
{
	if (!Player[iPlayer][IsBinded])
		return

	Player[iPlayer][IsBinded] = false

	new iKunaiEnt = Player[iPlayer][BindKunaiEnt]
	if (!is_nullent(iKunaiEnt))
	{
		set_entvar(iKunaiEnt, var_kunai_target, 0)
		kunai_remove(iKunaiEnt)
	}

	new iBeamEnt = Player[iPlayer][BindBeamEnt]
	if (!is_nullent(iBeamEnt))
	{
		if (Player[iPlayer][IsAlive])
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_KUNAI_UNBIND, 1.0, ATTN_NORM, 0, PITCH_NORM)
		rg_remove_entity(iBeamEnt)
	}
	Player[iPlayer][BindBeamEnt] = 0
}

bind_retarget(iPlayer, iTarget)
{
	if (!Player[iPlayer][IsBinded])
		return

	if (Player[iTarget][IsBinded])
	{
		bind_remove(iPlayer)
		return
	}

	new iKunaiEnt = Player[iPlayer][BindKunaiEnt]
	new iAttachEnt = Player[iPlayer][BindAttachEnt]
	new iBeamEnt = Player[iPlayer][BindBeamEnt]

	set_entvar(iKunaiEnt, var_aiment, iTarget)
	set_entvar(iKunaiEnt, var_kunai_target, iTarget)

	if (!is_nullent(iBeamEnt))
	{
		Beam_SetStartEntity(iBeamEnt, iTarget)
	}

	if (is_entity_player(iAttachEnt))
	{
		new iAttachBeamEnt = Player[iAttachEnt][BindAttachEnt]

		if (!is_nullent(iAttachBeamEnt))
		{
			Beam_SetEndEntity(iAttachBeamEnt, iTarget)
		}

		Player[iAttachEnt][BindAttachEnt] = iTarget
	}

	Player[iTarget][IsBinded] = true
	Player[iTarget][BindMode] = Player[iPlayer][BindMode]
	Player[iTarget][BindKunaiEnt] = iKunaiEnt
	Player[iTarget][BindAttachEnt] = iAttachEnt
	Player[iTarget][IsBindFreeMove] = Player[iPlayer][IsBindFreeMove]
	Player[iTarget][BindBeamEnt] = iBeamEnt

	Player[iPlayer][IsBinded] = false
	Player[iPlayer][BindKunaiEnt] = 0
	Player[iPlayer][BindAttachEnt] = 0
	Player[iPlayer][BindBeamEnt] = 0
}

create_directed_bloodstream(iEnt)
{
	new Float:vOrigin[3], Float:vVelocity[3]
	get_entvar(iEnt, var_origin, vOrigin)
	get_entvar(iEnt, var_velocity, vVelocity)

	send_msg_TE_BLOODSTREAM(vOrigin, vVelocity, 70, random_num(50, 100))
}
