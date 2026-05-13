#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "EFK: Telekinesis Knife"

#define KNIFE_CLASSNAME "weapon_next21_telekinesis"
#define KNIFE_MENUDESC  "KNIFE_TELEKINESIS_DESC"
#define KNIFE_CHATDESC  "KNIFE_TELEKINESIS_CHAT"

#define HP				80.0
#define GRAVITY			1.0
#define SPEED			260.0
#define MINDAMAGE		5.0
#define MAXDAMAGE		10.0

#define KNIFE_LEVEL     2

#define ABIL1_NAME		"Telekinesis"
#define ABIL1_CHARGE	5.556
#define ABIL1_TYPE		ABIL_NORMAL
#define ABIL1_MINDIST	75.0
#define ABIL1_MAXDIST	750.0

new const MODEL_V_KNIFE[]	= "models/next21_efk/v_telekinesis_knife_b04.mdl"
new const MODEL_P_KNIFE[]	= "models/next21_efk/p_telekinesis_knife_b04.mdl"

#define MODEL_CLAWS_SWING	"models/next21_efk/telekinesis_claws_swing.mdl"
new const CLASS_CLAWS_SWING[]	= "next21_claws_swing"

#define SOUND_TELEKINESIS	"next21_efk/telekinesis.wav"

#define FALLDMGDIVIDER			9.0
#define DISTANCE_ATTACK_DELAY	1.0
#define DISTANCE_ATTACK_DAMAGE	15.0
#define DISTANCE_ATTACK_STEP_LEN		32.0
#define DISTANCE_ATTACK_STEP_MUL		3.0

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_DISTANCE_ATTACK
}

#define Player[%1][%2]		g_player_data[%1 - 1][%2]
#define PlayerF[%1][%2]		g_player_data_f[%1 - 1][%2]

enum AbilityMode
{
	MODE_PUSH_TO,
	MODE_PUSH_AWAY,
	MODE_GROUP1_END,

	MODE_PUSH_ENEMY = MODE_GROUP1_END,
	MODE_SPREADINGOF,
	MODE_CONTRACTION,
	MODE_GROUP2_END
}

#define ANIM_STABMISS		5

#define START_CRIT_CHANCE	2.17
#define CON_CRIT_CHANCE		3.57
#define LIMIT_CRIT_CHANCE	40.0
#define ADD_CRIT_CHANCE		2.0

new const DISTANCE_ATTACK_HUD[]		= "Distance Attack (F)"

new const SZ_INFO_TARGET[]			= "info_target"

new const g_CritSounds[][] =
{
	"next21_efk/frash_explosion01.wav",
	"next21_efk/frash_explosion02.wav",
	"next21_efk/frash_explosion03.wav"
}

enum _:PlayerProperties
{
	Knife,
	IsAlive,
	// AbilityType:AbilType,
	AbilityMode:AbilMode
}

enum _:PlayerPropertiesF
{
	Float:AbilSelfCharge,
	Float:AbilTargetCharge,
	Float:CritChance,
}

enum _:TelekinesisTargetProperties
{
	TargetId,
	bool:TargetUsed,
	Float:TargetOrigin[3]
}

new g_iKnifeId, g_player_data[32][PlayerProperties], g_player_data_f[32][PlayerPropertiesF],
sprShockwave, g_pKnifeVStr, g_pKnifePMdl

public plugin_precache()
{
	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_model(MODEL_CLAWS_SWING)

	precache_sound(SOUND_TELEKINESIS)

	for (new i; i < sizeof g_CritSounds; i++)
		precache_sound(g_CritSounds[i])

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	sprShockwave = precache_model("sprites/shockwave.spr")
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

	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLABLE | KNFF_BAN_BUNNYHOP)
	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_CLAWS)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Player_PreThink, "player", "fw_PreThink")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_SecondaryAttack", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	register_impulse(100, "fw_PlayerFlashlight")
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][IsAlive] = 0
	PlayerF[iPlayer][CritChance] = START_CRIT_CHANCE
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][IsAlive] = 0
}

public fw_PlayerSpawn(iPlayer)
{
	if (is_user_alive(iPlayer))
		Player[iPlayer][IsAlive] = 1

	PlayerF[iPlayer][AbilSelfCharge] = PlayerF[iPlayer][AbilTargetCharge] = kc_player_get_abil1_charge(iPlayer)
}

public efk_disenergy(iPlayer)
{
	PlayerF[iPlayer][AbilSelfCharge] = floatmax(0.0, PlayerF[iPlayer][AbilSelfCharge] - random_float(20.0, 25.0))
	PlayerF[iPlayer][AbilTargetCharge] = floatmax(0.0, PlayerF[iPlayer][AbilTargetCharge] - random_float(20.0, 25.0))
}

public fw_PreThink(iPlayer)
{
	if (!Player[iPlayer][IsAlive])
		return HAM_IGNORED

	if (Player[iPlayer][Knife] != g_iKnifeId)
		return HAM_IGNORED

	new iButton = get_entvar(iPlayer, var_button)
	new iOldButtons = get_entvar(iPlayer, var_oldbuttons)

	if ((iButton & IN_USE) && !(iOldButtons & IN_USE))
	{
		if (++Player[iPlayer][AbilMode] >= MODE_GROUP1_END)
    		Player[iPlayer][AbilMode] = MODE_PUSH_TO

		kc_player_set_abil1_type(iPlayer, ABIL_NORMAL)

		// if(Player[iPlayer][AbilType] != ABIL_NORMAL)
		// {
		// 	PlayerF[iPlayer][AbilTargetCharge] = kc_player_get_abil1_charge(iPlayer)
		// 	kc_player_set_abil1_charge(iPlayer, PlayerF[iPlayer][AbilSelfCharge])

		// 	Player[iPlayer][AbilType] = ABIL_NORMAL
		// }
	}

	if ((iButton & IN_RELOAD) && !(iOldButtons & IN_RELOAD))
	{
		if (++Player[iPlayer][AbilMode] >= MODE_GROUP2_END || Player[iPlayer][AbilMode] < MODE_GROUP1_END)
			Player[iPlayer][AbilMode] = MODE_GROUP1_END

		kc_player_set_abil1_type(iPlayer, ABIL_TARGET_PLAYER)

		// if(Player[iPlayer][AbilType] != ABIL_TARGET_PLAYER)
		// {
		// 	PlayerF[iPlayer][AbilSelfCharge] = kc_player_get_abil1_charge(iPlayer)
		// 	kc_player_set_abil1_charge(iPlayer, PlayerF[iPlayer][AbilTargetCharge])

		// 	Player[iPlayer][AbilType] = ABIL_TARGET_PLAYER
		// }
	}

	return HAM_IGNORED
}

public fw_SecondaryAttack(iWeapon)
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

	if (Player[iPlayer][AbilMode] >= MODE_GROUP1_END)
	{
		new Float:fAbilCharge = kc_player_get_abil1_charge(iPlayer)
		if (fAbilCharge == 0.0 || fAbilCharge == 50.0)
			return HAM_IGNORED
	}

	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return HAM_IGNORED

	if (get_entvar(iPlayer, var_weaponanim) == ANIM_STABMISS
		&& distance_attack(iPlayer, true) > 0)
	{
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_DISTANCE_ATTACK)
		set_member(iWeapon, m_Weapon_flNextPrimaryAttack, DISTANCE_ATTACK_DELAY)
		set_member(iWeapon, m_Weapon_flNextSecondaryAttack, DISTANCE_ATTACK_DELAY)
		set_member(iWeapon, m_Weapon_flTimeWeaponIdle, DISTANCE_ATTACK_DELAY + 1.0)
	}

	return HAM_IGNORED
}

public fw_PlayerDamage(iVictim, gun, attacker, Float:damage, bits)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (Player[iVictim][Knife] == g_iKnifeId)
	{
		if (bits & DMG_FALL)
		{
			damage /= FALLDMGDIVIDER
			SetHamParamFloat(4, damage)
			return HAM_OVERRIDE
		}
	}

	if (!is_entity_player(attacker))
		return HAM_IGNORED

	if (Player[attacker][Knife] != g_iKnifeId)
		return HAM_IGNORED

	if (!(bits & DMG_BULLET))
		return HAM_IGNORED

	if (kc_player_in_silence(attacker))
		return HAM_IGNORED

	if (damage < 50.0)
		return HAM_IGNORED

	new ent = -1, Float:vOrigin[3]
	get_entvar(iVictim, var_origin, vOrigin)
	new Float:fCurDamage

	while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, vOrigin, 250.0)))
	{
		if (is_entity_player(ent)
			&& ent != iVictim && Player[ent][IsAlive]
			&& !kc_player_check_game_flag(ent, PLGF_IN_UNABILITY)
			&& kc_player_get_visibility(ent) != VIS_INVISION
			&& get_user_team(attacker) != get_user_team(ent))
		{
			fCurDamage = damage / 3

			if (fCurDamage > 45.0)
				fCurDamage = 45.0

			kc_player_set_death_reason(ent, "DEATH_REASON_TELEKINESIS")
			set_member(ent, m_LastHitGroup, HIT_GENERIC)
			ExecuteHamB(Ham_TakeDamage, ent, attacker, attacker, fCurDamage, DMG_ENERGYBEAM | DMG_ALWAYSGIB)

			new Float:vClawsOrigin[3]
			get_entvar(ent, var_origin, vClawsOrigin)
			claws_swing_create(vClawsOrigin, vOrigin)
		}
	}

	return HAM_IGNORED
}

public efk_player_death(iVictim, iAttacker)
{
	if (!is_entity_player(iAttacker))
		return

	if (iAttacker == iVictim)
		return

	if (Player[iAttacker][Knife] != g_iKnifeId)
		return

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
}

public fw_PlayerKilled(iVictim, iAttacker)
{
	Player[iVictim][IsAlive] = 0
}

public fw_PlayerFlashlight(iPlayer)
{
	if (!Player[iPlayer][IsAlive])
		return PLUGIN_CONTINUE

	if (Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return PLUGIN_CONTINUE

	new iItem = get_member(iPlayer, m_pActiveItem)

	if (is_nullent(iItem))
		return PLUGIN_CONTINUE

	if (get_member(iPlayer, m_flNextAttack) > 0.0)
		return PLUGIN_CONTINUE

	if (get_member(iItem, m_Weapon_flNextSecondaryAttack) > 0.0)
		return PLUGIN_CONTINUE

	if (distance_attack(iPlayer, false) > -1)
	{
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_DISTANCE_ATTACK)
		set_member(iItem, m_Weapon_flNextPrimaryAttack, DISTANCE_ATTACK_DELAY)
		set_member(iItem, m_Weapon_flNextSecondaryAttack, DISTANCE_ATTACK_DELAY)
		set_member(iItem, m_Weapon_flTimeWeaponIdle, DISTANCE_ATTACK_DELAY + 1.0)

		rg_set_animation(iPlayer, PLAYER_ATTACK1)

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO,
			fmt("weapons/knife_slash%i.wav", random_num(1, 2)), 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	return PLUGIN_HANDLED
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][Knife] = iKnifeId

	if (g_iKnifeId == iKnifeId)
	{
		Player[iPlayer][AbilMode] = MODE_PUSH_TO
		kc_player_set_crit_chance(iPlayer, PlayerF[iPlayer][CritChance])
	}
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	set_hudmessage(100, 0, 225, 0.01, -0.73, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_ALTABILITY)

	switch (Player[iSubject][AbilMode])
	{
		case MODE_CONTRACTION: show_hudmessage(iPlayer, "%L^n%s", iPlayer, "TELEKINESIS_MODE_CONTRACTION", DISTANCE_ATTACK_HUD)
		case MODE_SPREADINGOF: show_hudmessage(iPlayer, "%L^n%s", iPlayer, "TELEKINESIS_MODE_SPREADINGOF", DISTANCE_ATTACK_HUD)
		case MODE_PUSH_TO: show_hudmessage(iPlayer, "%L^n%s", iPlayer, "TELEKINESIS_MODE_PUSH_TO", DISTANCE_ATTACK_HUD)
		case MODE_PUSH_AWAY: show_hudmessage(iPlayer, "%L^n%s", iPlayer, "TELEKINESIS_MODE_PUSH_AWAY", DISTANCE_ATTACK_HUD)
		case MODE_PUSH_ENEMY: show_hudmessage(iPlayer, "%L^n%s", iPlayer, "TELEKINESIS_MODE_PUSH_ENEMY", DISTANCE_ATTACK_HUD)
	}

	return PLUGIN_CONTINUE
}

is_extra_abil1_case(iPlayer, iTarget)
{
	if (Player[iPlayer][AbilMode] >= MODE_GROUP1_END)
	{
		if (is_entity(iTarget) && get_entvar(iTarget, var_impulse) == IMPULSE_PRESENT)
			return 1

		if (is_entity_player(iTarget) && get_member(iPlayer, m_iTeam) == get_member(iTarget, m_iTeam))
			return 2
	}
	return 0
}

public efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed)
{
	if (Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	new iAbilCase = is_extra_abil1_case(iPlayer, iTarget)

	if (iAbilCase == 1)
	{
		kc_player_set_crosshair(iPlayer, bDistanceAllowed ? CROSSHAIR_OK : CROSSHAIR_FAR)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public efk_ability_pre(iPlayer, iTarget)
{
	if (Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	new extraCase = is_extra_abil1_case(iPlayer, iTarget)

	switch (extraCase)
	{
		case 1:
		{
			emit_sound(iTarget, CHAN_WEAPON, SOUND_TELEKINESIS, 1.0, ATTN_NORM, 0, PITCH_NORM)

			new Float:vOrigin[2][3], Float:vVelocity[3]
			get_entvar(iPlayer, var_origin, vOrigin[0])
			get_entvar(iTarget, var_origin, vOrigin[1])

			xs_vec_sub(vOrigin[0], vOrigin[1], vVelocity)

			new Float:fLength = xs_vec_len(vVelocity)
			vVelocity[0] *= 2000.0 / fLength
			vVelocity[1] *= 2000.0 / fLength
			vVelocity[2] *= 2000.0 / fLength

			set_entvar(iTarget, var_velocity, vVelocity)

			set_entvar(iTarget, var_rendermode, kRenderNormal)
			set_entvar(iTarget, var_renderfx, kRenderFxGlowShell)
			set_entvar(iTarget, var_rendercolor, {100.0, 0.0, 255.0})
			set_entvar(iTarget, var_renderamt, 16.0)

			set_entvar(iTarget, var_nextthink, get_gametime() + 1.0)

			kc_player_set_abil1_charge(iPlayer, 75.0)
			return PLUGIN_HANDLED
		}
		case 2:
		{
			if (telekinesis_target(iPlayer, iTarget, Player[iPlayer][AbilMode], false))
				kc_player_set_abil1_charge(iPlayer, -1.0)
			return PLUGIN_HANDLED
		}
	}

	return PLUGIN_CONTINUE
}

public efk_ability(iPlayer, iTarget)
{
	if (Player[iPlayer][AbilMode] >= MODE_GROUP1_END)
	{
		if (kc_player_in_reflection(iTarget))
		{
			telekinesis_target(iTarget, iPlayer, Player[iPlayer][AbilMode])
			kc_player_reflection_done(iTarget, iPlayer)
		}
		else
			telekinesis_target(iPlayer, iTarget, Player[iPlayer][AbilMode])
	}
	else
	{
		telekinesis_self(iPlayer)
		kc_player_set_abil1_charge(iPlayer, 27.78)

		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

bool:telekinesis_target(iPlayer, iVictim, AbilityMode:iMode, bool:bIgnoreTeammates=true)
{
	new Float:vPlrOrigin[3], iPlrTeam,
		aTargetData[MAX_PLAYERS + 1][TelekinesisTargetProperties],
		i, iTarget, iTargetsNum, iUsedTargetsNum,
		Float:vTargetOrigin[3], Float:vCenterOrigin[3], Float:vVelocity[3]

	iPlrTeam = get_member(iPlayer, m_iTeam)

	get_entvar(iPlayer, var_origin, vPlrOrigin)
	get_entvar(iVictim, var_origin, vCenterOrigin)

	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vCenterOrigin, 400.0)))
	{
		if (iTarget == iPlayer || !is_entity_player(iTarget) || !Player[iTarget][IsAlive])
			continue

		get_entvar(iTarget, var_origin, vTargetOrigin)

		if (iPlrTeam == get_member(iTarget, m_iTeam))
		{
			if (bIgnoreTeammates)
				continue

			aTargetData[iTargetsNum][TargetUsed] = false
		}
		else
		{
			if (kc_player_get_visibility(iTarget) == VIS_INVISION
				|| kc_player_check_game_flag(iTarget, PLGF_IN_UNABILITY))
				continue

			aTargetData[iTargetsNum][TargetUsed] = true

			kc_player_set_override_attacker(iTarget, iPlayer, 4.0)
			kc_player_set_capture(iTarget, CAPTURE_NONE)
			kc_player_unlevitation(iTarget)
			kc_player_unfreeze(iTarget)
			kc_player_add_glow(iTarget, 1.0, 100, 0, 225)

			if (get_pdata_int(iTarget, 350) > 0) // m_iTrain
			{
				set_pdata_int(iTarget, 350, 0xc0)
				set_pdata_int(iTarget, 257, get_pdata_int(iTarget, 257) & ~(1<<1))  // m_afPhysicsFlags

				new iGroundEnt = get_entvar(iTarget, var_groundentity)
				if (iGroundEnt > 0)
					set_pdata_cbase(iGroundEnt, 85, -1, 4) // m_pDriver
			}

			new Float:damage =
				random_float(0.0, 100.0) <= PlayerF[iPlayer][CritChance] && kc_player_try_crit(iTarget, iPlayer)
				? 1337.0
				: 10.0

			kc_player_set_death_reason(iTarget, "DEATH_REASON_TELEKINESIS")
			new Float:fVelocityModifier = get_member(iTarget, m_flVelocityModifier)
			set_member(iTarget, m_LastHitGroup, HIT_GENERIC)
			ExecuteHamB(Ham_TakeDamage, iTarget, iPlayer, iPlayer, damage, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
			set_member(iTarget, m_flVelocityModifier, fVelocityModifier)

			if (!Player[iTarget][IsAlive])
			{
				engfunc(EngFunc_EmitSound, iTarget, CHAN_AUTO,
					g_CritSounds[random(sizeof g_CritSounds)], 1.0, ATTN_NORM, 0, PITCH_NORM)

				send_msg_TE_LAVASPLASH(vTargetOrigin)

				fx_headshot(vTargetOrigin)
			}

			iUsedTargetsNum++
		}

		aTargetData[iTargetsNum][TargetId] = iTarget
		xs_vec_copy(vTargetOrigin, aTargetData[iTargetsNum][TargetOrigin])
		iTargetsNum++
	}

	if (!iUsedTargetsNum)
		return false

	emit_sound(iVictim, CHAN_WEAPON, SOUND_TELEKINESIS, 1.0, ATTN_NORM, 0, PITCH_NORM)

	if (iMode == MODE_PUSH_ENEMY)
	{
		for (i = 0; i < iTargetsNum; i++)
		{
			if (!aTargetData[i][TargetUsed])
				continue

			iTarget = aTargetData[i][TargetId]
			if (!Player[iTarget][IsAlive])
				continue

			xs_vec_copy(aTargetData[i][TargetOrigin], vTargetOrigin)

			get_speed_vector(vPlrOrigin, vTargetOrigin, 1200.0, vVelocity)
			vTargetOrigin[2] += 8.0

			if (is_hull_vacant(vTargetOrigin, get_entvar(iTarget, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, iTarget))
			{
				engfunc(EngFunc_SetOrigin, iTarget, vTargetOrigin)
				set_entvar(iTarget, var_origin, vTargetOrigin)
			}

			set_entvar(iTarget, var_velocity, vVelocity)
			kc_player_set_bair(iTarget, FL_BAIR_NORMAL | FL_BAIR_CLIMB)
		}
	}
	else
	{
		if (iMode == MODE_SPREADINGOF && iPlrTeam != get_member(iVictim, m_iTeam))
		{
			xs_vec_set(vCenterOrigin, 0.0, 0.0, 0.0)
			for (i = 0; i < iTargetsNum; i++)
				xs_vec_add(vCenterOrigin, aTargetData[i][TargetOrigin], vCenterOrigin)
			xs_vec_div_scalar(vCenterOrigin, float(iTargetsNum), vCenterOrigin)
		}
		else if (iMode == MODE_CONTRACTION)
		{
			xs_vec_set(vCenterOrigin, 0.0, 0.0, 0.0)
			for (i = 0; i < iTargetsNum; i++)
				if (aTargetData[i][TargetUsed])
					xs_vec_add(vCenterOrigin, aTargetData[i][TargetOrigin], vCenterOrigin)
			xs_vec_div_scalar(vCenterOrigin, float(iTargetsNum), vCenterOrigin)
		}

		new Float:vCylinderOrigin[3], Float:vAxis[3]
		vCylinderOrigin[0] = vCenterOrigin[0]
		vCylinderOrigin[1] = vCenterOrigin[1]
		vCylinderOrigin[2] = vCenterOrigin[2] + 70.0
		vAxis[0] = vCenterOrigin[0]
		vAxis[1] = vCenterOrigin[1]
		vAxis[2] = vCenterOrigin[2] + 325.0
		send_msg_TE_BEAMCYLINDER(vCylinderOrigin, vAxis, sprShockwave, 0, 0, 2, 5, 0, {100, 0, 255}, 100, 0)

		for (i = 0; i < iTargetsNum; i++)
		{
			if (!aTargetData[i][TargetUsed])
				continue

			iTarget = aTargetData[i][TargetId]
			if (!Player[iTarget][IsAlive])
				continue

			xs_vec_copy(aTargetData[i][TargetOrigin], vTargetOrigin)

			xs_vec_set(vVelocity, 0.0, 0.0, 0.0)

			if (iMode == MODE_SPREADINGOF)
				get_speed_vector(vCenterOrigin, vTargetOrigin, 500.0, vVelocity)
			else if (iMode == MODE_CONTRACTION)
				get_speed_vector(vTargetOrigin, vCenterOrigin, 500.0, vVelocity)

			vVelocity[2] = 400.0
			set_entvar(iTarget, var_velocity, vVelocity)
			kc_player_set_bair(iTarget, FL_BAIR_NORMAL | FL_BAIR_CLIMB)
		}
	}

	if (Player[iPlayer][Knife] == g_iKnifeId)
		kc_player_set_view_anim(iPlayer, VIEW_SEQ_DISTANCE_ATTACK)

	return true
}

telekinesis_self(iPlayer)
{
	new Float:vOrigin[3]

	kc_player_unfreeze(iPlayer)

	new Float:vVelocity[3], Float:vAngles[3],
	Float:fForce = Player[iPlayer][AbilMode] == MODE_PUSH_TO ? 1600.0 : -1600.0
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vVelocity)
	xs_vec_mul_scalar(vVelocity, fForce, vVelocity)

	vOrigin[2] += 8.0
	if (is_hull_vacant(vOrigin, get_entvar(iPlayer, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, iPlayer))
	{
		engfunc(EngFunc_SetOrigin, iPlayer, vOrigin)
		set_entvar(iPlayer, var_origin, vOrigin)
	}

	set_entvar(iPlayer, var_velocity, vVelocity)

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_TELEKINESIS, 1.0, ATTN_NORM, 0, PITCH_NORM)

	kc_player_add_glow(iPlayer, 1.0, 100, 0, 225)

	return PLUGIN_HANDLED
}

distance_attack(iPlayer, bool:bOnlyDistance=true)
{
	if (kc_player_get_capture(iPlayer) != CAPTURE_NONE)
		return -1

	if (kc_player_in_silence(iPlayer))
		return -1

	new Float:vOrigin[3], Float:vVector[3], Float:vEndOrigin[3], Float:fFraction
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vVector)
	xs_vec_add(vOrigin, vVector, vOrigin)

	new Float:vAngles[3]
	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vVector)

	xs_vec_mul_scalar(vVector, DISTANCE_ATTACK_STEP_LEN, vVector)
	xs_vec_add(vOrigin, vVector, vEndOrigin)

	new iTrace = create_tr2()

	engfunc(EngFunc_TraceLine, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, iPlayer, iTrace)
	get_tr2(iTrace, TR_flFraction, fFraction)

	if (fFraction < 1.0)
	{
		if (bOnlyDistance)
		{
			free_tr2(iTrace)
			return 0
		}
	}
	else
	{
		engfunc(EngFunc_TraceHull, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTrace)
		get_tr2(iTrace, TR_flFraction, fFraction)
	}

	if (fFraction < 1.0)
	{
		if (bOnlyDistance)
		{
			free_tr2(iTrace)
			return 0
		}
	}
	else
	{
		xs_vec_mul_scalar(vVector, DISTANCE_ATTACK_STEP_MUL, vVector)
		xs_vec_add(vOrigin, vVector, vEndOrigin)

		engfunc(EngFunc_TraceHull, vOrigin, vEndOrigin, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTrace)
	}

	new pHit = get_tr2(iTrace, TR_pHit)

	free_tr2(iTrace)

	if (is_nullent(pHit))
		return 0

	if (is_entity_player(pHit))
	{
		if (!Player[pHit][IsAlive])
			return 0

		if (get_user_team(iPlayer) == get_user_team(pHit))
			return 0

		if (kc_player_get_visibility(pHit) >= VIS_INVISION)
			return 0

		if (kc_player_check_game_flag(pHit, PLGF_IN_UNABILITY))
			return 0

		kc_player_set_death_reason(pHit, "DEATH_REASON_TELEKINESIS")
		set_member(pHit, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, DISTANCE_ATTACK_DAMAGE, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
	}
	else
	{
		new iImpulse = get_entvar(pHit, var_impulse)
		if (iImpulse == IMPULSE_ZOMBIE || iImpulse == IMPULSE_BUG)
		{
			if (get_member(iPlayer, m_iTeam) == get_entvar(pHit, var_skin) + 1)
				return 0
			ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, DISTANCE_ATTACK_DAMAGE, DMG_ENERGYBEAM)
		}
		else if (iImpulse == IMPULSE_FAKEPLAYER)
		{
			if (get_member(iPlayer, m_iTeam) == get_entvar(pHit, var_team))
				return 0
			ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, DISTANCE_ATTACK_DAMAGE, DMG_ENERGYBEAM)
		}
		else
			return 0
	}

	new Float:vClawsOrigin[3]
	get_entvar(pHit, var_origin, vClawsOrigin)
	claws_swing_create(vClawsOrigin, vOrigin)

	return pHit
}

claws_swing_create(const Float:vOrigin[3], const Float:vOwnerOrigin[3])
{
	new iEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iEnt))
		return NULLENT

	engfunc(EngFunc_SetModel, iEnt, MODEL_CLAWS_SWING)

	engfunc(EngFunc_SetOrigin, iEnt, vOrigin)
	engfunc(EngFunc_SetSize, iEnt, {-16.0, -16.0, -36.0}, {16.0,  16.0,  36.0})

	set_entvar(iEnt, var_origin, vOrigin)
	set_entvar(iEnt, var_solid, SOLID_NOT)
	set_entvar(iEnt, var_rendermode, kRenderNormal)
	set_entvar(iEnt, var_classname, CLASS_CLAWS_SWING)

	new Float:vAngles[3]
	vAngles[0] = vOrigin[0] - vOwnerOrigin[0]
	vAngles[1] = vOrigin[1] - vOwnerOrigin[1]
	vAngles[1] = floatacos(vAngles[0] / xs_vec_len_2d(vAngles), degrees)
	vAngles[0] = 0.0
	set_entvar(iEnt, var_angles, vAngles)

	new iSeq = random(3)
	new Float:fGameTime = get_gametime()

	set_entvar(iEnt, var_sequence, iSeq)
	set_entvar(iEnt, var_framerate, 1.0)
	set_entvar(iEnt, var_animtime, fGameTime)

	switch (iSeq)
	{
		case 0: set_entvar(iEnt, var_nextthink, fGameTime + 0.5)
		case 1: set_entvar(iEnt, var_nextthink, fGameTime + 0.43)
		case 2: set_entvar(iEnt, var_nextthink, fGameTime + 0.63)
	}

	SetThink(iEnt, "claws_swing_think")

	return iEnt
}

public claws_swing_think(iEnt)
{
	rg_remove_entity(iEnt)
}

fx_headshot(const Float:vOrigin[3])
{
	new Float:vEffOrigin[3], Float:vDirection[3]
	vEffOrigin[0] = vOrigin[0]
	vEffOrigin[1] = vOrigin[1]
	vEffOrigin[2] = vOrigin[2] + 40.0

	for (new i; i < 3; i++)
	{
		vDirection[0] = random_float(-0.3, 0.3)
		vDirection[1] = random_float(-0.3, 0.3)
		vDirection[2] = 1.0
		xs_vec_normalize(vDirection, vDirection)

		send_msg_TE_BLOODSTREAM(vEffOrigin, vDirection, 70, random_num(100, 150))
	}
}

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) || !get_tr2(0, TR_AllSolid)
}
