#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Tentacle Knife"

#define KNIFE_CLASSNAME "weapon_next21_tentacles"
#define KNIFE_MENUDESC  "KNIFE_TENTACLES_DESC"
#define KNIFE_CHATDESC  "KNIFE_TENTACLES_CHAT"

#define HP				90.0
#define GRAVITY			1.0
#define SPEED			240.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL     1

#define ABIL1_NAME		"Tentacles"
#define ABIL1_CHARGE	5.2632
#define ABIL1_TYPE		ABIL_TARGET_ENEMY
#define ABIL1_MINDIST	75.0
#define ABIL1_MAXDIST	1300.0

#define ABIL2_NAME		"Tentacles"
#define ABIL2_CHARGE	50.0

#define ABIL3_NAME		"Hack"
#define ABIL3_CHARGE	6.667

#define MODEL_V_KNIFE		"models/next21_efk/v_tentacles_knife_b02.mdl"
#define MODEL_P_KNIFE		"models/next21_efk/p_tentacles_knife_a.mdl"

#define MODEL_P_TENTACLES	"models/next21_efk/p_tentacles.mdl"
#define MODEL_W_TENTACLES	"models/next21_efk/w_tentacles.mdl"

#define SOUND_KNIFE_HIT1	"next21_efk/tentacles_knife_hit1.wav"
#define SOUND_KNIFE_HIT2	"next21_efk/tentacles_knife_hit2.wav"
#define SOUND_KNIFE_DEPLOY	"next21_efk/tentacles_knife_deploy.wav"
#define SOUND_KNIFE_IDLE	"next21_efk/tentacles_knife_idle.wav"
#define SOUND_KNIFE_STAB	"next21_efk/tentacles_knife_stab.wav"
#define SOUND_KNIFE_SLASH1	"next21_efk/tentacles_knife_slash1.wav"
#define SOUND_KNIFE_SLASH2	"next21_efk/tentacles_knife_slash2.wav"

#define SOUND_TENTACLES_HIT1	"next21_efk/tentacles_hit1.wav"
#define SOUND_TENTACLES_HIT2	"next21_efk/tentacles_hit2.wav"
#define SOUND_TENTACLES_SWING	"next21_efk/tentacles_swing1.wav"
#define SOUND_TENTACLES_DEPLOY	"next21_efk/tentacles_deploy.wav"
#define SOUND_TENTACLES_HOLSTER	"next21_efk/tentacles_holster.wav"
#define SOUND_TENTACLES_CAPTURE	"next21_efk/tentacles_capture.wav"

new const SOUND_HACK[] =		"next21_efk/hack_b01.wav"

#define SPRITE_TENTACLE		"sprites/next21_efk/tentacle.spr"

#define CAPTURE_TIME		12.0

#define MONEY_BONUS			400

#define TENTACLE_DAMAGE 	65.0
#define TENTACLE_DISTANCE 	70.0

#define HACK_RADIUS 		300.0
#define HACK_MONEY_BONUS	600
#define HACK_TIME			7.0

#define is_entity_player(%1)	(1<=%1&&%1<=MaxClients)
#define INSTANCE(%0) ((%0 == -1) ? 0 : %0)

#define TASK_HACK			1000

new const INFO_TARGET[] = "info_target"

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_TENTACLES_HOLSTER,
	VIEW_SEQ_TENTACLES_DRAW,
	VIEW_SEQ_TENTACLES_IDLE = 8,
	VIEW_SEQ_TENTACLES_ATTACK1,
	VIEW_SEQ_TENTACLES_ATTACK2
}

enum HackFlags (<<= 1)
{
	HF_INVENTORY = 1,
	HF_UNCRIT,
	HF_CHARGE
}

enum PlayerData
{
	PlrTentacles,
	PlrCapture,
	PlrKnife,
	PlrCombo,
	HackFlags:PlrHackFlags
}

#define Player[%1][%2]	g_ePlayerData[%1 - 1][%2]

new
g_iKnifeId, g_ePlayerData[MAX_PLAYERS][PlayerData],
HookChain:g_hcCBasePlayer_AddAccountBonus,
g_iMoneyBonus,
g_pTentacleSpr,
g_pKnifePMdl


public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(MODEL_P_TENTACLES)
	precache_model(MODEL_W_TENTACLES)

	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_DEPLOY)
	precache_sound(SOUND_KNIFE_IDLE)
	precache_sound(SOUND_KNIFE_STAB)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)

	precache_sound(SOUND_TENTACLES_HIT1)
	precache_sound(SOUND_TENTACLES_HIT2)
	precache_sound(SOUND_TENTACLES_SWING)
	precache_sound(SOUND_TENTACLES_DEPLOY)
	precache_sound(SOUND_TENTACLES_HOLSTER)
	precache_sound(SOUND_TENTACLES_CAPTURE)
	precache_sound(SOUND_HACK)

	g_pTentacleSpr = precache_model(SPRITE_TENTACLE)

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

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)

	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_AXE)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)
	kc_knife_set_flags(g_iKnifeId, KNFF_BAN_BUNNYHOP)

	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_KnifeDeploy", 1)
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Pre", false)
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Post", true)
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_knife", "fw_Item_WeaponIdle")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Item_PrimaryAttack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Item_SecondaryAttack")

	g_hcCBasePlayer_AddAccountBonus = RegisterHookChain(RG_CBasePlayer_AddAccount, "RG_CBasePlayer_AddAccountBonus_Pre", false)
	DisableHookChain(g_hcCBasePlayer_AddAccountBonus)
}

public client_disconnected(iPlayer)
{
	clear_player_data(iPlayer)
}

public client_putinserver(iPlayer)
{
	clear_player_data(iPlayer)
}

clear_player_data(iPlayer)
{
	remove_tentacles(iPlayer)
	remove_capture(iPlayer)

	Player[iPlayer][PlrCombo] = 0
	unset_hack(iPlayer)
}

public event_CurWeapon(const iPlayer)
{
	unset_tentacles(iPlayer)
}

public fw_UpdateClientData_Post(const iPlayer, const iSendWeapons, const CD_Handle)
{
	if (!Player[iPlayer][PlrTentacles] || !is_user_alive(iPlayer))
		return FMRES_IGNORED

	set_cd(CD_Handle, CD_ID, 0)

	return FMRES_HANDLED
}

public fw_PlayerSpawn(const iPlayer)
{
	if (!is_user_alive(iPlayer))
		return HAM_IGNORED

	Player[iPlayer][PlrCombo] = 0
	unset_tentacles(iPlayer)
	unset_hack(iPlayer)

	return HAM_IGNORED
}

public fw_KnifeDeploy(const iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_member(iWeapon, m_pPlayer)
	if (is_nullent(iPlayer))
		return HAM_IGNORED

	unset_tentacles(iPlayer)

	return HAM_IGNORED
}

public RG_CBasePlayer_Killed_Pre(const iPlayer, const iAttacker)
{
	unset_tentacles(iPlayer)

	if (Player[iPlayer][PlrHackFlags])
	{
		g_iMoneyBonus = HACK_MONEY_BONUS
		EnableHookChain(g_hcCBasePlayer_AddAccountBonus)
		unset_hack(iPlayer)
	}
	else if (is_entity_player(iAttacker) && Player[iAttacker][PlrKnife] == g_iKnifeId)
	{
		g_iMoneyBonus = MONEY_BONUS
		EnableHookChain(g_hcCBasePlayer_AddAccountBonus)
	}
}

public RG_CBasePlayer_Killed_Post(const iPlayer)
{
	DisableHookChain(g_hcCBasePlayer_AddAccountBonus)
}

public fw_Item_WeaponIdle(const iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_member(iWeapon, m_pPlayer)
	if (is_nullent(iPlayer))
		return HAM_IGNORED

	if (!Player[iPlayer][PlrTentacles] || Float:get_member(iWeapon, m_Weapon_flTimeWeaponIdle) > 0.0)
		return HAM_IGNORED

	Player[iPlayer][PlrCombo] = 0

	kc_player_set_view_anim(iPlayer, VIEW_SEQ_TENTACLES_IDLE)
	set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 17.0)

	return HAM_IGNORED
}

public fw_Item_PrimaryAttack(const iWeapon)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	return tentacle_attack(iWeapon, 1)
}

public fw_Item_SecondaryAttack(const iWeapon)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	return tentacle_attack(iWeapon, 0)
}

public RG_CBasePlayer_AddAccountBonus_Pre(const iPlayer, iAmount, RewardType:iType, bool:bTrackChange)
{
	if (iType == RT_ENEMY_KILLED)
		SetHookChainArg(2, ATYPE_INTEGER, iAmount + g_iMoneyBonus)
}

tentacle_attack(const iWeapon, const iAttackType)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_member(iWeapon, m_pPlayer)
	if (is_nullent(iPlayer))
		return HAM_IGNORED

	new iTentaclesEnt = Player[iPlayer][PlrTentacles]
	if (!iTentaclesEnt)
		return HAM_IGNORED

	new iNumCombo = Player[iPlayer][PlrCombo] & 7

	if (iNumCombo)
	{
		new iNextCombo = (Player[iPlayer][PlrCombo] & (4 << iNumCombo)) >> 2 + iNumCombo
		if (iNextCombo == iAttackType)
		{
			new Float:fNextAttack = Float:get_member(iWeapon, m_Weapon_flNextPrimaryAttack)

			Player[iPlayer][PlrCombo] = 0

			if (fNextAttack >= -0.5)
			{
				set_member(iWeapon, m_Weapon_flNextPrimaryAttack, fNextAttack + 0.75)
				set_member(iWeapon, m_Weapon_flNextSecondaryAttack, fNextAttack + 0.75)

				return HAM_SUPERCEDE
			}
		}

		if (iNumCombo == 4)
		{
			set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 1.1)
			set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 1.1)
			Player[iPlayer][PlrCombo] = 0
		}
		else
		{
			if (iNumCombo)
			{
				iNumCombo++
				iNextCombo = (Player[iPlayer][PlrCombo] & (4 << iNumCombo)) >> 2 + iNumCombo
				Player[iPlayer][PlrCombo] = iNumCombo + (Player[iPlayer][PlrCombo] & ~7)
			}

			set_member(iWeapon, _:m_Weapon_flNextPrimaryAttack + iNextCombo, 0.5)
			set_member(iWeapon, _:m_Weapon_flNextPrimaryAttack + (1 - iNextCombo), 0.35)
		}
	}

	kc_player_set_view_anim(iPlayer, VIEW_SEQ_TENTACLES_ATTACK1 + iAttackType)

	new Float:fGameTime = get_gametime()
	set_entvar(iTentaclesEnt, var_sequence, iAttackType + 2)
	set_entvar(iTentaclesEnt, var_framerate, 1.0)
	set_entvar(iTentaclesEnt, var_animtime, fGameTime)
	set_entvar(iTentaclesEnt, var_nextthink, fGameTime + 1.0)

	set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 1.6)

	new Float:vOrigin[3], Float:vVector[3], Float:vEndOrigin[3], Float:fFraction, pHit, tr
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vVector)
	xs_vec_add(vOrigin, vVector, vOrigin)

	get_entvar(iPlayer, var_v_angle, vVector)
	engfunc(EngFunc_MakeVectors, vVector)
	global_get(glb_v_forward, vVector)
	xs_vec_mul_scalar(vVector, TENTACLE_DISTANCE, vEndOrigin)
	xs_vec_add(vOrigin, vEndOrigin, vEndOrigin)

	engfunc(EngFunc_TraceLine, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, iPlayer, (tr = create_tr2()))
	get_tr2(tr, TR_flFraction, fFraction)

	if (fFraction >= 1.0)
	{
		engfunc(EngFunc_TraceHull, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, tr)
		get_tr2(tr, TR_flFraction, fFraction)

		if (fFraction < 1.0)
		{
			pHit = INSTANCE(get_tr2(tr, TR_pHit))

			if (!pHit || ExecuteHamB(Ham_IsBSPModel, pHit))
			{
				FindHullIntersection(vOrigin, tr, Float:{-16.0, -16.0, -18.0}, Float:{16.0,  16.0,  18.0}, iPlayer)
			}
		}
	}

	get_tr2(tr, TR_flFraction, fFraction)

	if (fFraction < 1.0)
	{
		global_get(glb_v_forward, vOrigin)

		pHit = INSTANCE(get_tr2(tr, TR_pHit))
		if (!is_nullent(pHit))
		{
			rg_multidmg_clear()
			ExecuteHamB(Ham_TraceAttack, pHit, iPlayer, TENTACLE_DAMAGE, vVector, tr, DMG_BULLET | DMG_NEVERGIB)
			rg_multidmg_apply(iPlayer, iPlayer)
		}

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, !random(2) ? SOUND_TENTACLES_HIT1 : SOUND_TENTACLES_HIT2, 1.0, ATTN_NORM, 0, PITCH_NORM)
		if (!iNumCombo)
		{
			Player[iPlayer][PlrCombo] = 1 + 8 * random(14)
			new iNextCombo = (Player[iPlayer][PlrCombo] & 8) >> 3

			set_member(iWeapon, _:m_Weapon_flNextPrimaryAttack + iNextCombo, 0.5)
			set_member(iWeapon, _:m_Weapon_flNextPrimaryAttack + (1 - iNextCombo), 0.35)
		}
	}
	else
	{
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_TENTACLES_SWING, 1.0, ATTN_NORM, 0, PITCH_NORM)

		if (!iNumCombo)
		{
			set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 0.8)
			set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 0.8)
		}
	}

	free_tr2(tr)

	return HAM_SUPERCEDE
}

public efk_uncapture(iPlayer)
{
	unset_capture(iPlayer)
}

public efk_preuse_crit(iVictim, iAttacker)
{
	if (is_entity_player(iAttacker) && (Player[iAttacker][PlrHackFlags] & HF_UNCRIT))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][PlrKnife] = iKnifeId
	Player[iPlayer][PlrCombo] = 0

	remove_tentacles(iPlayer)
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (Player[iSubject][PlrCombo])
	{
		static i, szCombo[16], iNumCombo
		iNumCombo = Player[iSubject][PlrCombo] & 7
		szCombo = ""
		for (i = 0; i < iNumCombo; i++)
			add(szCombo, charsmax(szCombo), " X")

		for (i = iNumCombo; i < 5; i++)
			add(szCombo, charsmax(szCombo), ((Player[iSubject][PlrCombo] & (4 << i)) >> 2 + i) ? " R" : " L")

		set_hudmessage(255, 255, 255, -1.0, -0.44, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "Combo:%s", szCombo)
	}

	return PLUGIN_CONTINUE
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][PlrKnife] != g_iKnifeId || !is_entity_player(iTarget))
		return PLUGIN_CONTINUE

	if (get_entvar(iTarget, var_waterlevel) >= 2)
		return _:CROSSHAIR_CANNOT

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer, iTarget)
{
	if (Player[iPlayer][PlrTentacles])
		return PLUGIN_HANDLED

	if (kc_player_in_reflection(iTarget))
	{
		if (!tentacles_capture(iPlayer))
			return PLUGIN_HANDLED

		kc_player_reflection_done(iTarget, iPlayer)
	}
	else if (!tentacles_capture(iTarget))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

bool:tentacles_capture(iTarget)
{
	if (!is_entity_player(iTarget))
		return false

	if (!kc_player_set_capture(iTarget, CAPTURE_NORMAL, CAP_ANIM_TENTACLES, CAPTURE_TIME))
		return false

	new iCaptureEnt = Player[iTarget][PlrCapture]
	if (iCaptureEnt)
		set_entvar(iCaptureEnt, var_flags, FL_KILLME)

	iCaptureEnt = rg_create_entity(INFO_TARGET, true)
	if (is_nullent(iCaptureEnt))
	{
		Player[iTarget][PlrCapture] = 0
		return false
	}

	set_entvar(iTarget, var_velocity, NULL_VECTOR)
	kc_player_unburn(iTarget)

	kc_player_reset_visibility(iTarget)
	kc_player_set_camera(iTarget, CAMERA_MODE_3RD)
	kc_player_set_game_flag(iTarget, PLGF_IN_UNABILITY)

	engfunc(EngFunc_SetModel, iCaptureEnt, MODEL_W_TENTACLES)

	new Float:fGameTime = get_gametime()

	set_entvar(iCaptureEnt, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iCaptureEnt, var_aiment, iTarget)
	set_entvar(iCaptureEnt, var_framerate, 1.0)
	set_entvar(iCaptureEnt, var_animtime, fGameTime)
	set_entvar(iCaptureEnt, var_sequence, 0)
	set_entvar(iCaptureEnt, var_solid, SOLID_NOT)
	set_entvar(iCaptureEnt, var_effects, 0)
	set_entvar(iCaptureEnt, var_rendermode, kRenderNormal)
	set_entvar(iCaptureEnt, var_nextthink, fGameTime + 1.0)
	set_entvar(iCaptureEnt, var_impulse, IMPULSE_FOLLOWENT)

	SetThink(iCaptureEnt, "capture_think")

	unset_tentacles(iTarget)

	if (kc_player_get_windboost(iTarget) == WINDBOOST_POSITIVE)
		kc_player_set_windboost(iTarget, WINDBOOST_NONE)

	if (Player[iTarget][PlrHackFlags])
	{
		kc_player_set_game_flag(iTarget, PLGF_IS_DISABLED_CHARGE)
		Player[iTarget][PlrHackFlags] |= HF_CHARGE
		remove_task(TASK_HACK + iTarget)
	}

	engfunc(EngFunc_EmitSound, iTarget, CHAN_AUTO, SOUND_TENTACLES_CAPTURE, 1.0, ATTN_NORM, 0, PITCH_NORM)
	Player[iTarget][PlrCapture] = iCaptureEnt

	return true
}

public efk_ability2(iPlayer)
{
	if (Float:get_member(iPlayer, m_flNextAttack) > 0.0)
		return PLUGIN_HANDLED

	if (get_user_weapon(iPlayer) != CSW_KNIFE)
		return PLUGIN_HANDLED

	new iTentaclesEnt = Player[iPlayer][PlrTentacles]
	if (!iTentaclesEnt)
	{
		iTentaclesEnt = rg_create_entity(INFO_TARGET, true)
		if (is_nullent(iTentaclesEnt))
			return PLUGIN_HANDLED

		set_entvar(iTentaclesEnt, var_movetype, MOVETYPE_FOLLOW)
		set_entvar(iTentaclesEnt, var_aiment, iPlayer)
		set_entvar(iTentaclesEnt, var_rendermode, kRenderNormal)

		engfunc(EngFunc_SetModel, iTentaclesEnt, MODEL_P_TENTACLES)

		new Float:fGameTime = get_gametime()
		set_entvar(iTentaclesEnt, var_sequence, 1)
		set_entvar(iTentaclesEnt, var_framerate, 1.0)
		set_entvar(iTentaclesEnt, var_animtime, fGameTime)
		set_entvar(iTentaclesEnt, var_nextthink, fGameTime + 1.0)

		SetThink(iTentaclesEnt, "tentacles_think")

		kc_player_set_view_anim(iPlayer, VIEW_SEQ_TENTACLES_DRAW)

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_TENTACLES_DEPLOY, 1.0, ATTN_NORM, 0, PITCH_NORM)

		new iWeapon = get_member(iPlayer, m_pActiveItem)
		if (!is_nullent(iWeapon))
		{
			set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 1.0)
			set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 1.0)
			set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 1.0)
		}

		kc_player_set_abil1_type(iPlayer, ABIL_NORMAL)

		Player[iPlayer][PlrTentacles] = iTentaclesEnt
	}
	else
	{
		unset_tentacles(iPlayer)

		kc_player_set_view_anim(iPlayer, VIEW_SEQ_TENTACLES_HOLSTER)

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_TENTACLES_HOLSTER, 1.0, ATTN_NORM, 0, PITCH_NORM)

		new iWeapon = get_member(iPlayer, m_pActiveItem)
		if (!is_nullent(iWeapon))
			set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 1.0)
	}

	return PLUGIN_CONTINUE
}

public efk_ability3(iPlayer)
{
	new iEnt = -1, Float:vOrigin[3]
	new iTargetsNum

	get_entvar(iPlayer, var_origin, vOrigin)
	while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vOrigin, HACK_RADIUS)))
	{
		if (iEnt != iPlayer && is_user_alive(iEnt)
			&& get_member(iPlayer, m_iTeam) != get_member(iEnt, m_iTeam)
			&& !kc_player_check_game_flag(iEnt, PLGF_IN_UNABILITY)
			&& kc_player_get_visibility(iEnt) != VIS_INVISION)
		{
			send_msg_TE_BEAMENTS(iPlayer, iEnt, g_pTentacleSpr, 0, 0, 15, 20, 1, {192, 192, 56}, 255, 15)

			set_hack(iEnt)
			iTargetsNum++
		}
	}

	if (!iTargetsNum)
		return PLUGIN_HANDLED

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_HACK, 1.0, ATTN_NORM, 0, PITCH_NORM)

	return PLUGIN_CONTINUE
}

public tentacles_think(iTentaclesEnt)
{
	new Float:fGameTime = get_gametime()

	set_entvar(iTentaclesEnt, var_sequence, 0)
	set_entvar(iTentaclesEnt, var_animtime, fGameTime)
	set_entvar(iTentaclesEnt, var_nextthink, fGameTime + 5.8)
}

unset_tentacles(iPlayer)
{
	new iTentaclesEnt = Player[iPlayer][PlrTentacles]
	if (iTentaclesEnt)
	{
		set_entvar(iTentaclesEnt, var_flags, FL_KILLME)
		Player[iPlayer][PlrTentacles] = 0
		Player[iPlayer][PlrCombo] = 0

		if (Player[iPlayer][PlrKnife] == g_iKnifeId)
			kc_player_set_abil1_type(iPlayer, ABIL_TARGET_ENEMY)
	}
}

remove_tentacles(iPlayer)
{
	new iTentaclesEnt = Player[iPlayer][PlrTentacles]
	if (iTentaclesEnt)
	{
		set_entvar(iTentaclesEnt, var_flags, FL_KILLME)
		Player[iPlayer][PlrTentacles] = 0
	}
}

public capture_think(iCaptureEnt)
{
	switch (get_entvar(iCaptureEnt, var_sequence))
	{
		case 0:
		{
			set_entvar(iCaptureEnt, var_animtime, get_gametime())
			set_entvar(iCaptureEnt, var_sequence, 2)
			set_entvar(iCaptureEnt, var_body, 1)
		}
		case 1:
		{
			set_entvar(iCaptureEnt, var_flags, FL_KILLME)
		}
	}
}

unset_capture(iPlayer)
{
	new iCaptureEnt = Player[iPlayer][PlrCapture]
	if (iCaptureEnt)
	{
		new Float:vOrigin[3], Float:vAngles[3]
		new Float:fGameTime = get_gametime()

		get_entvar(iPlayer, var_origin, vOrigin)
		get_entvar(iPlayer, var_angles, vAngles)
		vAngles[0] = vAngles[2] = 0.0
		if (get_entvar(iPlayer, var_flags) & FL_DUCKING)
			vOrigin[2] += 18.0

		engfunc(EngFunc_SetOrigin, iCaptureEnt, vOrigin)
		set_entvar(iCaptureEnt, var_origin, vOrigin)
		set_entvar(iCaptureEnt, var_angles, vAngles)
		set_entvar(iCaptureEnt, var_movetype, MOVETYPE_NONE)

		set_entvar(iCaptureEnt, var_animtime, fGameTime)
		set_entvar(iCaptureEnt, var_sequence, 1)
		set_entvar(iCaptureEnt, var_nextthink, fGameTime + 1.0)
		set_entvar(iCaptureEnt, var_body, 0)
		set_entvar(iCaptureEnt, var_impulse, 0)

		kc_player_unset_game_flag(iPlayer, PLGF_IN_UNABILITY)
		kc_player_set_camera(iPlayer, CAMERA_MODE_1ST)

		new iWeapon = get_member(iPlayer, m_pActiveItem)
		if (!is_nullent(iWeapon))
		{
			set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 0.35)
			set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 0.35)
		}
		set_member(iPlayer, m_flNextAttack, 0.35)

		unset_hack(iPlayer)

		Player[iPlayer][PlrCapture] = 0
	}
}

remove_capture(iPlayer)
{
	new iCaptureEnt = Player[iPlayer][PlrCapture]
	if (iCaptureEnt)
	{
		set_entvar(iCaptureEnt, var_flags, FL_KILLME)
		Player[iPlayer][PlrCapture] = 0
	}
}

set_hack(iPlayer)
{
	new iTaskId = TASK_HACK + iPlayer

	if (task_exists(iTaskId))
	{
		change_task(iTaskId, HACK_TIME)
		return
	}

	kc_player_set_game_flag(iPlayer, PLGF_IS_DISABLED_INVENTORY)
	kc_player_add_glow(iPlayer, HACK_TIME, 170, 175, 70)

	engclient_cmd(iPlayer, "weapon_knife")
	send_msg_StatusIcon(true, "dollar", {170, 175, 70}, MSG_ONE, _, iPlayer)

	set_task(HACK_TIME, "task_hack", iTaskId)

	Player[iPlayer][PlrHackFlags] = HF_INVENTORY | HF_UNCRIT
}

unset_hack(iPlayer)
{
	new HackFlags:iHackFlags = Player[iPlayer][PlrHackFlags]
	if (iHackFlags)
	{
		send_msg_StatusIcon(false, "dollar", _, MSG_ONE, _, iPlayer)

		if (iHackFlags & HF_INVENTORY)
			kc_player_unset_game_flag(iPlayer, PLGF_IS_DISABLED_INVENTORY)
		if (iHackFlags & HF_CHARGE)
			kc_player_unset_game_flag(iPlayer, PLGF_IS_DISABLED_CHARGE)

		remove_task(TASK_HACK + iPlayer)
	}

	Player[iPlayer][PlrHackFlags] = _:0
}

public task_hack(iTaskId)
{
	new iPlayer = iTaskId - TASK_HACK
	unset_hack(iPlayer)
}

FindHullIntersection(const Float:vSrc[3], &iTrace, const Float:vMins[3], const Float:vMaxs[3], const iEntity)
{
	new iTempTrace;

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

	engfunc(EngFunc_TraceLine, vSrc, vHullEnd, DONT_IGNORE_MONSTERS, iEntity, (iTempTrace = create_tr2()))
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

				engfunc(EngFunc_TraceLine, vSrc, vEnd, DONT_IGNORE_MONSTERS, iEntity, iTempTrace)
				get_tr2(iTempTrace, TR_flFraction, fFraction)

				if (fFraction < 1.0)
				{
					get_tr2(iTempTrace, TR_vecEndPos, vEndPos)
					xs_vec_sub(vEndPos, vSrc, vEndPos)

					if ((fThisDistance = xs_vec_len(vEndPos)) < fDistance)
					{
						free_tr2(iTrace)

						iTrace = iTempTrace
						fDistance = fThisDistance
					}
				}
			}
		}
	}
}
