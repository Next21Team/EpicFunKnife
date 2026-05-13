#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Ninja Knife"

#define KNIFE_CLASSNAME "weapon_next21_ninja"
#define KNIFE_MENUDESC  "KNIFE_NINJA_DESC"
#define KNIFE_CHATDESC  "KNIFE_NINJA_CHAT"

#define HP				115.0
#define GRAVITY			0.75
#define SPEED			255.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define ABIL1_NAME		"Ninja"
#define ABIL1_CHARGE	6.667

#define Player[%1][%2]		g_player_data[%1 - 1][%2]
#define PlayerF[%1][%2]		g_player_data_f[%1 - 1][%2]

new const MODEL_V_KNIFE[] = "models/next21_efk/v_ninja_knife_b02.mdl"
new const MODEL_V_KNIFE_I[] = "models/next21_efk/v_ninja_knife_i_b02.mdl"
new const MODEL_P_KNIFE[] = "models/next21_efk/p_ninja_knife.mdl"

#define SOUND_KNIFE_HIT1	"next21_efk/ninja_knife_hit1.wav"
#define SOUND_KNIFE_STAB	"next21_efk/ninja_knife_stab.wav"
#define SOUND_KNIFE_HITWALL	"next21_efk/ninja_knife_hitwall1.wav"
#define SOUND_KNIFE_SLASH1	"next21_efk/ninja_knife_slash1.wav"
#define SOUND_KNIFE_SLASH2	"next21_efk/ninja_knife_slash2.wav"
#define SOUND_KNIFE_DEPLOY	"next21_efk/ninja_knife_deploy.wav"

#define HEAD_MODEL 		"models/GIB_Skull.mdl"

#define SOUND_UNINVIS		"next21_efk/ninja_uninvisible.wav"
#define SOUND_FAILABILITY	"next21_efk/fail_ability.wav"
#define SOUND_KAMUI			"next21_efk/kamui.wav"

#define CLASSNAME_FAKEPART	"next21_fakepart"

#define INVISTIME		7.0

#define MODE_LASTMOVE		0
#define MODE_FOLLOW		1

#define TIME_FAKE		10.0

enum _:ViewSeq
{
	VIEW_SEQ_IDLE
}

new const SZ_INFO_TARGET[]			= "info_target"

#define var_fakeowner				var_iuser2

enum _:Player_Properties
{
	bool:IsAlive,
	Knife,
	Team,
	InvisMode,
	FakeSeq,
	FakeMode,
	FakeSkeleton,
	FakeShell,
	FakeKnife,
	FakeHat,
	CanSwap
}

enum _:Player_Properties_F
{
	Float:InvisibleTime,
	Float:FakeVelocity[3],
	Float:FakeModeDelay,
	Float:FakeSolidDelay,
	Float:FakeInvisTimeDelay,
	Float:FakeRenderDalay,
	Float:FakeAttackDalay,
	Float:FakeStepDelay
}

new g_iKnifeId,
g_player_data[MAX_PLAYERS][Player_Properties], Float:g_player_data_f[32][Player_Properties_F],
sprIllusion, g_pKnifeVStr, g_pKnifeInvisVStr, g_pKnifePMdl

public plugin_precache()
{
	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	g_pKnifeInvisVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE_I)
	precache_model(MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE_I)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_STAB)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)
	precache_sound(SOUND_KNIFE_DEPLOY)

	precache_sound(SOUND_UNINVIS)
	precache_sound(SOUND_FAILABILITY)
	precache_sound(SOUND_KAMUI)

	sprIllusion = precache_model("sprites/next21_efk/illusion_destroy.spr")

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
	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLABLE)
	kc_knife_set_charge_boost_coeff(g_iKnifeId, 0.25)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_stab.wav", SOUND_KNIFE_STAB)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Player_PostThink, "player", "fw_PostThink", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_PrePrimaryAttack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_PreSecondaryAttack")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	register_impulse(100, "fw_PlayerFlashlight")

	register_forward(FM_EmitSound, "fw_EmitSound")
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][IsAlive] = false
	Player[iPlayer][Team] = 0
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][IsAlive] = false
	Player[iPlayer][Team] = 0

	if (Player[iPlayer][FakeSkeleton])
		fakeplayer_think(Player[iPlayer][FakeSkeleton])
}

public fw_PlayerSpawn(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		Player[iPlayer][IsAlive] = true
		PlayerF[iPlayer][FakeRenderDalay] = 0.0
		PlayerF[iPlayer][InvisibleTime] = 0.0

		if (Player[iPlayer][FakeSkeleton])
			fakeplayer_think(Player[iPlayer][FakeSkeleton])
	}
}

new const Float:STEP_DELAY = 0.308333333334
new const STEP_SOUNDS[][] = {
	"player/pl_step1.wav",
	"player/pl_step2.wav",
	"player/pl_step3.wav",
	"player/pl_step4.wav"
}

public fw_PostThink(iPlayer)
{
	if (!Player[iPlayer][IsAlive] || Player[iPlayer][Knife] != g_iKnifeId)
		return HAM_IGNORED

	static iPlayerSeq, iFakeModeButton, iSwapButton
	new Float:fGameTime = get_gametime()

	if (fGameTime < kc_player_get_swap(iPlayer))
	{
		iFakeModeButton = IN_RELOAD
		iSwapButton = IN_USE
	}
	else
	{
		iFakeModeButton = IN_USE
		iSwapButton = IN_RELOAD
	}

	if (PlayerF[iPlayer][FakeRenderDalay] > 0.0 && PlayerF[iPlayer][FakeRenderDalay] <= fGameTime)
	{
		if (Player[iPlayer][FakeSkeleton])
		{
			set_entvar(Player[iPlayer][FakeShell], var_renderamt, 16.0)
			set_entvar(Player[iPlayer][FakeShell], var_rendermode, kRenderNormal)
		}
		PlayerF[iPlayer][FakeRenderDalay] = 0.0

		if (pev(iPlayer, pev_viewmodel) != g_pKnifeInvisVStr)
		{
			PlayerF[iPlayer][InvisibleTime] = 0.0
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_UNINVIS, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		else
			kc_player_invision(iPlayer, INVISTIME, Player[iPlayer][FakeSkeleton], 0)
	}

	static iFakeSkeleton
	iFakeSkeleton = Player[iPlayer][FakeSkeleton]

	if (!iFakeSkeleton)
		return HAM_IGNORED

	static iSeq
	iSeq = get_entvar(iFakeSkeleton, var_sequence)
	if (iSeq == 6 || iSeq == 7 || iSeq == 16 || iSeq == 17)
	{
		if (PlayerF[iPlayer][FakeStepDelay] < fGameTime
			&& get_entvar(iFakeSkeleton, var_flags) & FL_ONGROUND)
			{
				PlayerF[iPlayer][FakeStepDelay] = fGameTime + STEP_DELAY
				emit_sound(iFakeSkeleton, CHAN_BODY, STEP_SOUNDS[random(4)], 1.0, ATTN_IDLE, 0, PITCH_NORM)
			}
	}

	if (PlayerF[iPlayer][FakeModeDelay] < fGameTime)
	{
		if ((get_entvar(iPlayer, var_button) & iFakeModeButton) && !kc_player_in_silence(iPlayer))
		{
			PlayerF[iPlayer][FakeModeDelay] = fGameTime + 0.25
			Player[iPlayer][FakeMode] = Player[iPlayer][FakeMode] == MODE_LASTMOVE ? MODE_FOLLOW : MODE_LASTMOVE
		}
	}

	if (Player[iPlayer][CanSwap] && PlayerF[iPlayer][InvisibleTime] == 0.0 && (get_entvar(iPlayer, var_button) & iSwapButton)
		&& kc_player_get_capture(iPlayer) == CAPTURE_NONE && !kc_player_in_silence(iPlayer))
	{
		static seq
		iPlayerSeq = get_entvar(iPlayer, var_gaitsequence)

		switch (iPlayerSeq)
		{
			case 1: seq = 0 // idle
			case 2: seq = 2 // crouch_idle
			case 3: seq = 4 // walk
			case 4: seq = 6 // run
			case 5: seq = 8 // crouch_run
			default: seq = -1
		}

		if (seq != -1)
		{
			new Float:vOrigin[2][3], Float:vVelocity[3], Float:vAngles[2][3], blend[2]

			get_entvar(iPlayer, var_origin, vOrigin[0])
			get_entvar(iFakeSkeleton, var_origin, vOrigin[1])

			get_entvar(iPlayer, var_velocity, PlayerF[iPlayer][FakeVelocity])
			get_entvar(iFakeSkeleton, var_velocity, vVelocity)

			vAngles[0][0] = 0.0
			vAngles[0][1] = get_member(iPlayer, m_flGaityaw)
			vAngles[0][2] = 0.0

			get_entvar(iFakeSkeleton, var_angles, vAngles[1])

			pev(iPlayer, pev_blending, blend)

			if (blend[0] <= 128)
			{
				blend[0] = min(blend[0], 127)
				set_pev(iFakeSkeleton, pev_blending_0, blend[0] * 2)
			}
			else
			{
				set_pev(iFakeSkeleton, pev_blending_0, (blend[0] - 128) * 2)
				seq++
			}

			if ((iPlayerSeq == 2 || iPlayerSeq == 5) && Player[iPlayer][FakeSeq] != 2 && Player[iPlayer][FakeSeq] != 5)
			{
				vOrigin[1][2] += 18.0

				engfunc(EngFunc_SetSize, iFakeSkeleton, {-16.0, -16.0, -18.0 }, { 16.0,  16.0,  32.0 })
			}
			else if ((Player[iPlayer][FakeSeq] == 2 || Player[iPlayer][FakeSeq] == 5) && iPlayerSeq != 2 && iPlayerSeq != 5)
			{
				set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) | FL_DUCKING)
				engfunc(EngFunc_SetSize, iPlayer, {-16.0, -16.0, -18.0 }, { 16.0,  16.0,  32.0 })

				engfunc(EngFunc_SetSize, iFakeSkeleton, {-16.0, -16.0, -36.0 }, { 16.0,  16.0,  36.0 })
			}

			engfunc(EngFunc_SetOrigin, iFakeSkeleton, vOrigin[0])
			engfunc(EngFunc_SetOrigin, iPlayer, vOrigin[1])

			set_entvar(iFakeSkeleton, var_origin, vOrigin[0])
			set_entvar(iPlayer, var_origin, vOrigin[1])
			set_entvar(iFakeSkeleton, var_angles, vAngles[0])
			set_entvar(iFakeSkeleton, var_sequence, seq)
			set_entvar(iFakeSkeleton, var_framerate, (iPlayerSeq == 3 ? 2.0 : 1.0))

			set_entvar(iPlayer, var_velocity, vVelocity)
			set_entvar(iPlayer, var_angles, vAngles[1])
			set_entvar(iPlayer, var_fixangle, 1)

			checkstuck(iPlayer)

			Player[iPlayer][FakeSeq] = iPlayerSeq
			Player[iPlayer][CanSwap] = 0
		}
	}

	if (PlayerF[iPlayer][FakeSolidDelay] && PlayerF[iPlayer][FakeSolidDelay] <= fGameTime)
	{
		set_entvar(iFakeSkeleton, var_solid, SOLID_BBOX)
		set_entvar(iFakeSkeleton, var_gravity, GRAVITY)

		PlayerF[iPlayer][FakeSolidDelay] = 0.0

		new Float:vMins[3], Float:vMaxs[3]
		get_entvar(iFakeSkeleton, var_mins, vMins)
		get_entvar(iFakeSkeleton, var_maxs, vMaxs)

		engfunc(EngFunc_SetSize, iFakeSkeleton, vMins, vMaxs)
	}

	if (!PlayerF[iPlayer][FakeAttackDalay])
	{
		if (Player[iPlayer][FakeMode] == MODE_FOLLOW)
		{
			static blend[2], seq, Float:vecAngles[3]
			pev(iPlayer, pev_blending, blend)
			iPlayerSeq = get_entvar(iPlayer, var_gaitsequence)

			switch (iPlayerSeq)
			{
				case 1: seq = 0 // idle
				case 2: seq = 2 // crouch_idle
				case 3: seq = 4 // walk
				case 4: seq = 6 // run
				case 5: seq = 8 // crouch_run
				default: seq = -1
			}

			if (seq != -1)
			{
				get_entvar(iPlayer, var_velocity, PlayerF[iPlayer][FakeVelocity])

				if (blend[0] <= 128)
				{
					blend[0] = min(blend[0], 127)
					set_pev(iFakeSkeleton, pev_blending_0, blend[0] * 2)
				}
				else
				{
					set_pev(iFakeSkeleton, pev_blending_0, (blend[0] - 128) * 2)
					seq++
				}

				vecAngles[0] = 0.0
				vecAngles[1] = get_member(iPlayer, m_flGaityaw)
				vecAngles[2] = 0.0

				if (Player[iPlayer][FakeSeq] != iPlayerSeq)
				{
					if ((iPlayerSeq == 2 || iPlayerSeq == 5) && Player[iPlayer][FakeSeq] != 2 && Player[iPlayer][FakeSeq] != 5)
					{
						new Float:vOrigin[3]
						get_entvar(iFakeSkeleton, var_origin, vOrigin)
						vOrigin[2] -= 18.0
						engfunc(EngFunc_SetOrigin, iFakeSkeleton, vOrigin)
						set_entvar(iFakeSkeleton, var_origin, vOrigin)
						engfunc(EngFunc_SetSize, iFakeSkeleton, {-16.0, -16.0, -18.0 }, { 16.0,  16.0,  32.0 })
					}
					else if ((Player[iPlayer][FakeSeq] == 2 || Player[iPlayer][FakeSeq] == 5) && iPlayerSeq != 2 && iPlayerSeq != 5)
					{
						new Float:vOrigin[3]
						get_entvar(iFakeSkeleton, var_origin, vOrigin)
						vOrigin[2] += 18.0
						engfunc(EngFunc_SetOrigin, iFakeSkeleton, vOrigin)
						set_entvar(iFakeSkeleton, var_origin, vOrigin)
						engfunc(EngFunc_SetSize, iFakeSkeleton, {-16.0, -16.0, -36.0 }, { 16.0,  16.0,  36.0 })

						checkstuck(iPlayer)
					}

					set_entvar(iFakeSkeleton, var_frame, 0.0)

					Player[iPlayer][FakeSeq] = iPlayerSeq
				}

				set_entvar(iFakeSkeleton, var_angles, vecAngles)
				set_entvar(iFakeSkeleton, var_sequence, seq)
				set_entvar(iFakeSkeleton, var_framerate, (iPlayerSeq == 3 ? 2.0 : 1.0))
			}
		}
	}
	else if (PlayerF[iPlayer][FakeAttackDalay] <= fGameTime)
	{
		set_entvar(iFakeSkeleton, var_sequence, get_entvar(iFakeSkeleton, var_sequence) - 10)
		set_entvar(iFakeSkeleton, var_framerate, (iPlayerSeq == 3 ? 2.0 : 1.0))

		PlayerF[iPlayer][FakeAttackDalay] = 0.0
	}

	static Float:vVelocity[3]
	get_entvar(iFakeSkeleton, var_velocity, vVelocity)
	PlayerF[iPlayer][FakeVelocity][2] = vVelocity[2]
	set_entvar(iFakeSkeleton, var_velocity, PlayerF[iPlayer][FakeVelocity])

	return HAM_IGNORED
}

public fw_PrePrimaryAttack(iWeapon)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (!Player[iPlayer][IsAlive])
		return HAM_IGNORED

	if (Player[iPlayer][Knife] != g_iKnifeId)
		return HAM_IGNORED

	if (Player[iPlayer][InvisMode] == 1 && PlayerF[iPlayer][InvisibleTime] > 0.0)
	{
		kc_player_uninvision(iPlayer)
		set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 0.35)
		set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 0.35)
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public fw_PreSecondaryAttack(iWeapon)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_member(iWeapon, m_pPlayer)

	if (!Player[iPlayer][IsAlive])
		return HAM_IGNORED

	if (Player[iPlayer][Knife] != g_iKnifeId)
		return HAM_IGNORED

	if (Player[iPlayer][InvisMode] == 1 && PlayerF[iPlayer][InvisibleTime] > 0.0)
	{
		kc_player_uninvision(iPlayer)
		set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 0.35)
		set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 0.35)
		return HAM_SUPERCEDE
	}

	if (kc_player_in_silence(iPlayer))
		return HAM_IGNORED

	if (!kc_player_is_abil1_ready(iPlayer))
		return HAM_IGNORED

	if (!pev(iPlayer, pev_maxspeed))
		return HAM_IGNORED

	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return HAM_IGNORED

	if (!check_stab_hit(iPlayer))
	{
		set_member(iPlayer, m_flNextAttack, 1.0)
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_IDLE)

		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public fw_PlayerKilled(iVictim)
{
	Player[iVictim][IsAlive] = false
	PlayerF[iVictim][FakeRenderDalay] = 0.0

	if (Player[iVictim][FakeSkeleton])
		fakeplayer_think(Player[iVictim][FakeSkeleton])
}

public efk_player_change_team(iPlayer, iTeam)
{
	Player[iPlayer][Team] = iTeam
}

public fw_FakeDamage(iEnt, iInflictor, iAttacker)
{
	if (is_nullent(iEnt))
		return HAM_IGNORED

	if (get_entvar(iEnt, var_impulse) != IMPULSE_FAKEPLAYER)
		return HAM_IGNORED

	for (new i = 1; i <= MaxClients; i++)
	{
		if (iEnt != Player[i][FakeSkeleton])
			continue

		if (is_entity_player(iAttacker))
		{
			if (iAttacker != i && Player[iAttacker][Team] == Player[i][Team])
				return HAM_SUPERCEDE

			if (iAttacker == iInflictor && Player[iAttacker][Team] != Player[i][Team] &&
				kc_player_get_vision(iAttacker) != VISION_BLIND && !kc_player_in_freeze(iAttacker) && !kc_player_in_chill(iAttacker))
			{
				send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 255, 255}, 100, MSG_ONE, _, iAttacker)
			}
		}

		new Float:vOrigin[3]
		get_entvar(iEnt, var_origin, vOrigin)

		send_msg_TE_SPRITE(vOrigin, sprIllusion, 8, 100)

		Player[i][FakeSkeleton] = 0
		Player[i][FakeShell] = 0
		Player[i][FakeKnife] = 0
		Player[i][FakeHat] = 0

		Player[i][CanSwap] = 0

		kc_invision_unfake(i)
	}

	new iPartEnt = NULLENT
	while ((iPartEnt = rg_find_ent_by_aiment(iPartEnt, CLASSNAME_FAKEPART, iEnt)))
		rg_remove_entity(iPartEnt)

	return HAM_IGNORED
}

public fakeplayer_think(iEnt)
{
	new iPartEnt = NULLENT
	while ((iPartEnt = rg_find_ent_by_aiment(iPartEnt, CLASSNAME_FAKEPART, iEnt)))
		rg_remove_entity(iPartEnt)

	new Float:vOrigin[3]
	get_entvar(iEnt, var_origin, vOrigin)

	send_msg_TE_SPRITE(vOrigin, sprIllusion, 8, 100)

	new iOwner = get_entvar(iEnt, var_fakeowner)

	Player[iOwner][FakeSkeleton] = 0
	Player[iOwner][FakeShell] = 0
	Player[iOwner][FakeKnife] = 0
	Player[iOwner][FakeHat] = 0

	Player[iOwner][CanSwap] = 0

	kc_invision_unfake(iOwner)

	rg_remove_entity(iEnt)
}

public fakeplayer_touch(iEnt, iOther)
{
	if (!iEnt)
		return HC_CONTINUE

	new iOwner = get_entvar(iEnt, var_fakeowner)

	if (is_entity_player(iOther))
	{
		if (PlayerF[iOwner][FakeSolidDelay])
			PlayerF[iOwner][FakeSolidDelay] = get_gametime() + 0.1
	}
	else
	{
		if (get_entvar(iOther, var_impulse) == IMPULSE_FIELD_WALL)
		{
			if (Player[get_entvar(iOther, var_owner)][Team] != Player[iOwner][Team])
				fakeplayer_think(iEnt)
		}
	}

	return HC_CONTINUE
}

public fw_PlayerFlashlight(iPlayer)
{
	if (Player[iPlayer][Knife] != g_iKnifeId || PlayerF[iPlayer][InvisibleTime] > 0.0)
		return PLUGIN_CONTINUE

	Player[iPlayer][InvisMode] = !Player[iPlayer][InvisMode]

	return PLUGIN_HANDLED
}

public fw_EmitSound(iEnt, channel, const sample[])
{
	return (iEnt <= MaxClients && Player[iEnt][FakeSkeleton] && equal(sample[7], "wpn_denyselect.wav"))
		? FMRES_SUPERCEDE : FMRES_IGNORED
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (PlayerF[iSubject][InvisibleTime] > 0.0)
	{
		set_hudmessage(255, 255, 255, -1.0, -0.30, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "%L", iPlayer, Player[iSubject][InvisMode] == 1 ? "KAMUI_TIMER" : "INVISION_TIMER",
			floatmax(0.0, PlayerF[iSubject][InvisibleTime] - get_gametime()))
	}

	set_hudmessage(255, 255, 255, 0.01, -0.73, 0, 0.0, 0.2, 0.2, 0.0, HUDCHANNEL_ALTABILITY)
	static szAbilName[128]
	szAbilName[0] = 0

	if (Player[iSubject][FakeSkeleton])
	{
		switch(Player[iSubject][FakeMode])
		{
			case MODE_LASTMOVE: formatex(szAbilName, charsmax(szAbilName), "%L", iPlayer, "FAKE_MODE_LASTMOVE")
			case MODE_FOLLOW: formatex(szAbilName, charsmax(szAbilName), "%L", iPlayer, "FAKE_MODE_FOLLOW")
		}

		if (Player[iSubject][CanSwap] && PlayerF[iSubject][InvisibleTime] == 0.0)
		{
			if (kc_player_in_silence(iSubject))
				add(szAbilName, charsmax(szAbilName), "^n...NO SIGNAL...")
			else
				format(szAbilName, charsmax(szAbilName), "%s^n%L", szAbilName, iPlayer, "FAKE_SWAP")
		}
	}

	if (!kc_player_in_silence(iSubject))
		format(szAbilName, charsmax(szAbilName), "%s^nMode: %s (F)", szAbilName, Player[iSubject][InvisMode] == 1 ? "Kamui" : "Invision")

	show_hudmessage(iPlayer, szAbilName)

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][Knife] = iKnifeId
	PlayerF[iPlayer][FakeRenderDalay] = 0.0

	if (Player[iPlayer][FakeSkeleton])
		fakeplayer_think(Player[iPlayer][FakeSkeleton])
}

public efk_uninvisible(iPlayer)
{
	PlayerF[iPlayer][InvisibleTime] = 0.0
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_UNINVIS, 1.0, ATTN_NORM, 0, PITCH_NORM)

	if (Player[iPlayer][InvisMode] == 1)
	{
		kc_player_unset_game_flag(iPlayer, PLGF_IN_UNABILITY)
		set_entvar(iPlayer, var_solid, SOLID_SLIDEBOX)
	}

	if (Player[iPlayer][IsAlive] && Player[iPlayer][Knife] == g_iKnifeId)
	{
		if (pev(iPlayer, pev_viewmodel) == g_pKnifeInvisVStr)
			set_pev(iPlayer, pev_viewmodel, g_pKnifeVStr)
	}
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (!iTarget || (iAbilType != ABIL_TARGET_PLAYER && iAbilType != ABIL_TARGET_ENEMY))
		return PLUGIN_CONTINUE

	if (get_entvar(iTarget, var_impulse) == IMPULSE_FAKEPLAYER)
	{
		new iOwner = get_entvar(iTarget, var_fakeowner)
		if (Player[iPlayer][Team] != Player[iOwner][Team])
		{
			kc_player_set_crosshair(iPlayer, bDistanceAllowed ? CROSSHAIR_OK : CROSSHAIR_FAR)
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}

public efk_ability_pre(iPlayer, iTarget)
{
	if (!iTarget)
		return PLUGIN_CONTINUE

	for (new i = 1, Float:fDist; i < MaxClients; i++)
	{
		if (Player[i][FakeSkeleton] == iTarget && Player[iPlayer][Team] != Player[i][Team])
		{
			fDist = rg_entity_range(iPlayer, iTarget)

			if (75.0 > fDist ||  fDist > 700.0)
				return PLUGIN_CONTINUE

			ExecuteHamB(Ham_TakeDamage, iTarget, i, iPlayer, 10.0, DMG_BULLET)

			if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
				send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 255, 255}, 100, MSG_ONE, _, iPlayer)

			client_cmd(iPlayer, "spk %s", SOUND_FAILABILITY)

			if (kc_player_get_vision(iPlayer) != VISION_FULL)
				kc_player_set_abil1_charge(iPlayer, -1.0)

			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer)
{
	if (Player[iPlayer][InvisMode] != 1 && !pev(iPlayer, pev_maxspeed))
		return PLUGIN_HANDLED

	set_pev(iPlayer, pev_viewmodel, g_pKnifeInvisVStr)

	if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {8, 37, 103}, 130, MSG_ONE, _, iPlayer)

	new Float:fGameTime = get_gametime()

	PlayerF[iPlayer][InvisibleTime] = fGameTime + INVISTIME

	if (Player[iPlayer][InvisMode] == 1)
	{
		Player[iPlayer][CanSwap] = 0
		PlayerF[iPlayer][FakeRenderDalay] = 0.0

		kc_player_unfreeze(iPlayer)
		kc_player_unchill(iPlayer)
		kc_player_unburn(iPlayer)
		kc_player_invision(iPlayer, INVISTIME, 0, 1)
		kc_player_set_game_flag(iPlayer, PLGF_IN_UNABILITY)
		set_entvar(iPlayer, var_solid, SOLID_NOT)

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_KAMUI, 1.0, ATTN_NORM, 0, PITCH_NORM)

		checkstuck(iPlayer)

		return PLUGIN_CONTINUE
	}

	PlayerF[iPlayer][FakeRenderDalay] = fGameTime + 0.1

	new plFlags = get_entvar(iPlayer, var_flags)
	if (!(plFlags & FL_ONGROUND) || (plFlags & FL_INWATER))
		return PLUGIN_CONTINUE

	new plBut = get_entvar(iPlayer, var_button)
	if ((plBut & IN_DUCK) && !(plFlags & FL_DUCKING))
		return PLUGIN_CONTINUE

	new iFakeSkeleton = Player[iPlayer][FakeSkeleton]

	if (iFakeSkeleton)
		fakeplayer_think(iFakeSkeleton)

	iFakeSkeleton = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iFakeSkeleton))
	{
		Player[iPlayer][FakeSkeleton] = 0
		return PLUGIN_CONTINUE
	}

	Player[iPlayer][FakeSkeleton] = iFakeSkeleton

	set_fake_params(iPlayer, iFakeSkeleton)
	set_pev(iFakeSkeleton, pev_nextthink, fGameTime + TIME_FAKE)

	PlayerF[iPlayer][FakeSolidDelay] = fGameTime + 0.1

	new iFakeShell = rg_create_entity(SZ_INFO_TARGET)
	Player[iPlayer][FakeShell] = iFakeShell

	set_entvar(iFakeShell, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iFakeShell, var_aiment, iFakeSkeleton)
	set_entvar(iFakeShell, var_classname, CLASSNAME_FAKEPART)
	set_entvar(iFakeShell, var_impulse, IMPULSE_FAKEPLAYER_SHELL)

	//set_entvar(iFakeShell, var_modelindex, get_entvar(iPlayer, var_modelindex))
	engfunc(EngFunc_SetModel, iFakeShell, fmt("models/player/%s/%s.mdl",
		CUSTOM_PLAYER_MODEL, CUSTOM_PLAYER_MODEL))

	set_entvar(iFakeShell, var_body, get_entvar(iPlayer, var_body))
	set_entvar(iFakeShell, var_skin, get_entvar(iPlayer, var_skin))

	set_entvar(iFakeShell, var_rendermode, kRenderTransAlpha)
	set_entvar(iFakeShell, var_renderamt, 0.1)

	new iFakeKnife = rg_create_entity(SZ_INFO_TARGET)
	Player[iPlayer][FakeKnife] = iFakeKnife

	set_entvar(iFakeKnife, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iFakeKnife, var_rendermode, kRenderNormal)
	set_entvar(iFakeKnife, var_aiment, iFakeSkeleton)
	set_entvar(iFakeKnife, var_classname, CLASSNAME_FAKEPART)

	set_entvar(iFakeKnife, var_modelindex, g_pKnifePMdl)

	new iHatEnt = kc_player_get_hat_ent(iPlayer)
	if (iHatEnt)
	{
		new iFakeHat = rg_create_entity(SZ_INFO_TARGET)
		Player[iPlayer][FakeHat] = iFakeHat

		set_entvar(iFakeHat, var_movetype, MOVETYPE_FOLLOW)
		set_entvar(iFakeHat, var_rendermode, kRenderNormal)
		set_entvar(iFakeHat, var_aiment, iFakeSkeleton)
		set_entvar(iFakeHat, var_classname, CLASSNAME_FAKEPART)
		set_entvar(iFakeHat, var_modelindex, get_entvar(iHatEnt, var_modelindex))

		new iHatBody = get_entvar(iHatEnt, var_body)

		set_entvar(iFakeHat, var_impulse, IMPULSE_FAKEHAT)
		set_entvar(iFakeHat, var_skin, get_entvar(iHatEnt, var_skin))
		set_entvar(iFakeHat, var_body, iHatBody)

		set_entvar(iFakeHat, var_sequence, iHatBody)
		set_entvar(iFakeHat, var_framerate, 1.0)
		set_entvar(iFakeHat, var_animtime, fGameTime)
	}

	Player[iPlayer][CanSwap] = 1

	return PLUGIN_CONTINUE
}

set_fake_params(iOwner, iFakeSkeleton)
{
	engfunc(EngFunc_SetModel, iFakeSkeleton, MODEL_PLAYER_ANIMATIONS)

	new blend[2], seq, iPlayerSeq, Float:vAngles[3]
	pev(iOwner, pev_blending, blend)
	iPlayerSeq = get_entvar(iOwner, var_gaitsequence)

	new Float:fFrameRate = (iPlayerSeq == 3 ? 2.0 : 1.0)

	set_entvar(iFakeSkeleton, var_classname, CLASSNAME_FAKEPLAYER)
	set_entvar(iFakeSkeleton, var_impulse, IMPULSE_FAKEPLAYER)
	set_entvar(iFakeSkeleton, var_team, Player[iOwner][Team])
	set_entvar(iFakeSkeleton, var_framerate, fFrameRate)
	set_entvar(iFakeSkeleton, var_gravity, 0.000001)
	set_entvar(iFakeSkeleton, var_movetype, MOVETYPE_PUSHSTEP)
	set_entvar(iFakeSkeleton, var_solid, SOLID_TRIGGER)
	set_entvar(iFakeSkeleton, var_rendermode, kRenderTransAlpha)
	set_entvar(iFakeSkeleton, var_renderamt, 0.0)
	set_entvar(iFakeSkeleton, var_takedamage, 1.0)
	set_entvar(iFakeSkeleton, var_health, 1.0)
	set_entvar(iFakeSkeleton, var_fakeowner, iOwner)

	switch (iPlayerSeq)
	{
		case 1: seq = 0 // idle
		case 2: seq = 2 // crouch_idle
		case 3: seq = 4 // walk
		case 4: seq = 6 // run
		case 5: seq = 8 // crouch_run
	}

	if(blend[0] <= 128)
	{
		blend[0] = min(blend[0], 127)
		set_pev(iFakeSkeleton, pev_blending_0, blend[0] * 2)
	}
	else
	{
		set_pev(iFakeSkeleton, pev_blending_0, (blend[0] - 128) * 2)
		seq++
	}

	if (iPlayerSeq == 2 || iPlayerSeq == 5)
		engfunc(EngFunc_SetSize, iFakeSkeleton, {-16.0, -16.0, -18.0 }, { 16.0,  16.0,  32.0 })
	else
		engfunc(EngFunc_SetSize, iFakeSkeleton, {-16.0, -16.0, -36.0 }, { 16.0,  16.0,  36.0 })

	vAngles[0] = 0.0
	vAngles[1] = get_member(iOwner, m_flGaityaw)
	vAngles[2] = 0.0

	new main_seq = get_entvar(iOwner, var_sequence)
	if(main_seq  == 74 || main_seq  == 76)
	{
		new Float:fGameTime = get_gametime()

		set_entvar(iFakeSkeleton, var_sequence, seq + 10)
		set_entvar(iFakeSkeleton, var_frame, 0.0)
		set_entvar(iFakeSkeleton, var_animtime, fGameTime)
		PlayerF[iOwner][FakeAttackDalay] = fGameTime + 1.366666 / fFrameRate
	}
	else
	{
		set_entvar(iFakeSkeleton, var_sequence, seq)
		set_entvar(iFakeSkeleton, var_frame, Float:get_member(iOwner, m_flGaitframe))
	}

	set_entvar(iFakeSkeleton, var_angles, vAngles)

	new Float:vOrigin[3]
	get_entvar(iOwner, var_origin, vOrigin)
	get_entvar(iOwner, var_velocity, PlayerF[iOwner][FakeVelocity])

	engfunc(EngFunc_SetOrigin, iFakeSkeleton, vOrigin)
	set_entvar(iFakeSkeleton, var_origin, vOrigin)

	Player[iOwner][FakeMode] = MODE_LASTMOVE
	Player[iOwner][FakeSeq] = iPlayerSeq

	static fakeSoldReg
	if (!fakeSoldReg)
	{
		RegisterHamFromEntity(Ham_TakeDamage, iFakeSkeleton, "fw_FakeDamage")
		fakeSoldReg = true
	}

	SetThink(iFakeSkeleton, "fakeplayer_think")
	SetTouch(iFakeSkeleton, "fakeplayer_touch")
}

new const Float:fUnstuckSize[][3] = {
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 6.0}, {0.0, 0.0, -6.0}, {0.0, 6.0, 0.0}, {0.0, -6.0, 0.0}, {6.0, 0.0, 0.0}, {-6.0, 0.0, 0.0}, {-6.0, 6.0, 6.0}, {6.0, 6.0, 6.0}, {6.0, -6.0, 6.0}, {6.0, 6.0, -6.0}, {-6.0, -6.0, 6.0}, {6.0, -6.0, -6.0}, {-6.0, 6.0, -6.0}, {-6.0, -6.0, -6.0},
	{0.0, 0.0, 8.0}, {0.0, 0.0, -8.0}, {0.0, 8.0, 0.0}, {0.0, -8.0, 0.0}, {8.0, 0.0, 0.0}, {-8.0, 0.0, 0.0}, {-8.0, 8.0, 8.0}, {8.0, 8.0, 8.0}, {8.0, -8.0, 8.0}, {8.0, 8.0, -8.0}, {-8.0, -8.0, 8.0}, {8.0, -8.0, -8.0}, {-8.0, 8.0, -8.0}, {-8.0, -8.0, -8.0},
	{0.0, 0.0, 10.0}, {0.0, 0.0, -10.0}, {0.0, 10.0, 0.0}, {0.0, -10.0, 0.0}, {10.0, 0.0, 0.0}, {-10.0, 0.0, 0.0}, {-10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}, {10.0, -10.0, 10.0}, {10.0, 10.0, -10.0}, {-10.0, -10.0, 10.0}, {10.0, -10.0, -10.0}, {-10.0, 10.0, -10.0}, {-10.0, -10.0, -10.0}
}

checkstuck(const iPlayer)
{
	new Float:vOrigin[3], Float:vMins[3], Float:vVec[3]

	get_entvar(iPlayer, var_origin, vOrigin)
	new iHull = get_entvar(iPlayer, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
	if (!is_hull_vacant(vOrigin, iHull, iPlayer) && get_entvar(iPlayer, var_movetype) != MOVETYPE_NOCLIP && get_entvar(iPlayer, var_solid) != SOLID_NOT)
	{
		get_entvar(iPlayer, var_mins, vMins)
		vVec[2] = vOrigin[2]
		for (new i; i < sizeof fUnstuckSize; ++i)
		{
			vVec[0] = vOrigin[0] - vMins[0] * fUnstuckSize[i][0]
			vVec[1] = vOrigin[1] - vMins[1] * fUnstuckSize[i][1]
			vVec[2] = vOrigin[2] - vMins[2] * fUnstuckSize[i][2]
			if (is_hull_vacant(vVec, iHull, iPlayer))
			{
				set_entvar(iPlayer, var_origin, vVec)
				break
			}
		}
	}
}

bool:is_hull_vacant(Float:vOrigin[3], iHull, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHull, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) || !get_tr2(0, TR_AllSolid)
}

Float:rg_entity_range(iEntA, iEntB)
{
	static Float:vOriginA[3], Float:vOriginB[3]
	get_entvar(iEntA, var_origin, vOriginA)
	get_entvar(iEntB, var_origin, vOriginB)

	return get_distance_f(vOriginA, vOriginB)
}

rg_find_ent_by_aiment(iEnt, const szClassName[], iAimEnt)
{
	while ((iEnt = rg_find_ent_by_class(iEnt, szClassName)) && get_entvar(iEnt, var_aiment) != iAimEnt) {}
	return iEnt
}

check_stab_hit(iPlayer)
{
	new tr = create_tr2()
	new Float:vSrc[3], Float:vEnd[3], Float:vAdd[3]

	get_entvar(iPlayer, var_origin, vSrc)
	get_entvar(iPlayer, var_view_ofs, vEnd)
	xs_vec_add(vSrc, vEnd, vSrc)

	get_entvar(iPlayer, var_v_angle, vAdd)
	engfunc(EngFunc_MakeVectors, vAdd)
	global_get(glb_v_forward, vAdd)
	xs_vec_mul_scalar(vAdd, 32.0, vAdd)
	xs_vec_add(vSrc, vAdd, vEnd)

	new Float:fFraction
	engfunc(EngFunc_TraceLine, vSrc, vEnd, DONT_IGNORE_MONSTERS, iPlayer, tr)
	get_tr2(tr, TR_flFraction, fFraction)

	if (fFraction >= 1.0)
	{
		engfunc(EngFunc_TraceHull, vSrc, vEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, tr)
		get_tr2(tr, TR_flFraction, fFraction)
	}

	free_tr2(tr)
	return fFraction < 1.0
}
