#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>
#include <object/efk_tornado_utils>

new const PLUGIN[] = "EFK: Fire Knife"

#define KNIFE_CLASSNAME "weapon_next21_fire"
#define KNIFE_MENUDESC  "KNIFE_FIRE_DESC"
#define KNIFE_CHATDESC  "KNIFE_FIRE_CHAT"

#define HP				100.0
#define GRAVITY			1.0
#define SPEED			275.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define KNIFE_LEVEL     1

#define ABIL1_NAME		"Fire"
#define ABIL1_CHARGE	5.883
#define ABIL1_TYPE		ABIL_TARGET_FLOOR
#define ABIL1_MINDIST	25.0
#define ABIL1_MAXDIST	1500.0

#define ABIL2_NAME		"Burner Rush"
#define ABIL2_CHARGE	4.167

#define ABIL3_NAME		"Time Reburn"
#define ABIL3_CHARGE	3.0

#define Player[%1][%2]		g_player_data[%1 - 1][%2]
#define PlayerF[%1][%2]		g_player_data_f[%1 - 1][%2]
#define var_laserlife				var_iuser1
#define var_creator					var_iuser4 // don't set var_iuser3!!!

#define MODEL_V_KNIFE		"models/next21_efk/v_fire_knife_b03.mdl"
#define MODEL_P_KNIFE		"models/next21_efk/p_fire_knife.mdl"
#define MODEL_CROSSHAIR		"models/next21_efk/fire_crosshair_b01.mdl"

#define SOUND_FIRE		"next21_efk/fire_activation.wav"
#define SOUND_TIMEREBURN	"next21_efk/time_reburn.wav"
#define SOUND_LASER		"next21_efk/fire_laser.wav"
#define SOUND_LASER_HIT		"next21_efk/fire_laser_hit.wav"

#define CLASSNAME_LASER				"next21_firelaser"
#define LASER_CYCLES				20
#define LASER_RADIUS				120.0

#define RUSH_TIME					0.4
#define RUSH_SPEED					2000.0
#define RUSH_JUMP					600.0
#define RUSH_RADIUS					160.0
#define RUSH_FOV					100

#define BURN_CYCLES					13

new const SZ_INFO_TARGET[]			= "info_target"
new const SZ_BEAM[]					= "beam"

enum _:Player_Properties
{
	bool:IsAlive,
	Knife,
	Laser,
	bool:IsBurnerRushAttacker[MAX_PLAYERS + 1]
}

enum _:Player_Properties_F
{
	Float:RushTime,
	Float:RushVector[3],
	Float:StartRushTime,
	Float:EndRushTime
}

new
g_iKnifeId, g_player_data[32][Player_Properties], Float:g_player_data_f[32][Player_Properties_F],
sprRush, sprFire, sprShadowCircle, sprBeam,
g_pKnifePMdl

public plugin_precache()
{
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)
	precache_model(MODEL_CROSSHAIR)

	precache_sound(SOUND_FIRE)
	precache_sound(SOUND_TIMEREBURN)
	precache_sound(SOUND_LASER)
	precache_sound(SOUND_LASER_HIT)

	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	sprRush = engfunc(EngFunc_PrecacheModel, "sprites/next21_efk/fire_sphere.spr")
	sprFire = engfunc(EngFunc_PrecacheModel, "sprites/next21_efk/fire_eff.spr")
	sprShadowCircle = engfunc(EngFunc_PrecacheModel, "sprites/shadow_circle.spr")
	sprBeam = precache_model("sprites/laserbeam.spr")
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

	kc_knife_set_flags(g_iKnifeId, KNFF_ABIL1_TOGGLABLE)
	kc_knife_set_anim_ext(g_iKnifeId, ANIM_EXT_KNIFE2)
	kc_knife_set_level(g_iKnifeId, KNIFE_LEVEL)

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Player_PreThink, "player", "fw_PreThink")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage_Post", 1)

	register_forward(FM_Touch, "fw_Touch")

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
}

public client_putinserver(iPlayer)
{
	Player[iPlayer][IsAlive] = false
	PlayerF[iPlayer][RushTime] = 0.0
	PlayerF[iPlayer][StartRushTime] = 0.0
}

public client_disconnected(iPlayer)
{
	PlayerF[iPlayer][RushTime] = 0.0
	Player[iPlayer][IsAlive] = true
	arrayset(Player[iPlayer][IsBurnerRushAttacker], false, MAX_PLAYERS + 1)

	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_LASER)))
	{
		if (get_entvar(iEnt, var_owner) == iPlayer)
			crosshair_ent_remove(iEnt)
	}
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_LASER)))
		crosshair_ent_remove(iEnt)
}

public fw_PlayerSpawn(iPlayer)
{
	if (is_user_alive(iPlayer))
	{
		PlayerF[iPlayer][RushTime] = 0.0
		PlayerF[iPlayer][StartRushTime] = 0.0
		Player[iPlayer][IsAlive] = true
		Player[iPlayer][Laser] = 0
		kc_player_unset_game_flag(iPlayer, PLGF_IN_BURNRUSH)

		if (Player[iPlayer][Knife] == g_iKnifeId)
			kc_player_set_abil2_charge(iPlayer, 100.0 - ABIL2_CHARGE * RESET_ABIL_AFTER_SPAWN)
	}
}

public fw_PreThink(iPlayer)
{
	if (!Player[iPlayer][IsAlive])
		return HAM_IGNORED

	static Float:vOrigin[3], Float:vAimOrigin[3]
	new Float:fGameTime = get_gametime()

	if (Player[iPlayer][Laser])
	{
		if (get_entvar(Player[iPlayer][Laser], var_owner) == iPlayer)
		{
			get_aim_origin(iPlayer, vOrigin, vAimOrigin)

			if (get_distance_f(vOrigin, vAimOrigin) <= ABIL1_MAXDIST)
			{
				engfunc(EngFunc_SetOrigin, Player[iPlayer][Laser], vAimOrigin)
				engfunc(EngFunc_SetOrigin, get_entvar(Player[iPlayer][Laser], var_crosshair), vAimOrigin)
				vAimOrigin[2] += 500.0
				set_entvar(Player[iPlayer][Laser], var_angles, vAimOrigin)
			}
		}
		else
			Player[iPlayer][Laser] = 0
	}

	if (PlayerF[iPlayer][RushTime] > 0.0)
	{
		if(PlayerF[iPlayer][RushTime] <= fGameTime)
		{
			stop_rush(iPlayer)
			return HAM_IGNORED
		}

		if (kc_player_get_capture(iPlayer) != CAPTURE_NONE || kc_player_in_freeze(iPlayer) || kc_player_in_chill(iPlayer))
		{
			PlayerF[iPlayer][RushTime] = 0.0
			set_entvar(iPlayer, var_velocity, NULL_VECTOR)
			kc_player_unset_game_flag(iPlayer, PLGF_IN_BURNRUSH)

			restore_fov(iPlayer)
			return HAM_IGNORED
		}

		static Float:vOrigin[3]
		get_entvar(iPlayer, var_origin, vOrigin)

		engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vOrigin, 0)
		write_byte(TE_SPRITE)
		engfunc(EngFunc_WriteCoord, vOrigin[0] + random_float(-5.0, 5.0))
		engfunc(EngFunc_WriteCoord, vOrigin[1] + random_float(-5.0, 5.0))
		engfunc(EngFunc_WriteCoord, vOrigin[2] + random_float(-10.0, 10.0))
		write_short(sprRush)
		write_byte(random_num(5, 10))
		write_byte(200)
		message_end()

		create_red_waves(vOrigin)

		kc_player_unfreeze(iPlayer)
		kc_player_unchill(iPlayer)

		new iTeam = get_member(iPlayer, m_iTeam)
		new ent = engfunc(EngFunc_FindEntityInSphere, -1, vOrigin, RUSH_RADIUS)
		while (ent)
		{
			if (is_entity_player(ent) && ent != iPlayer)
			{
				if (Player[ent][IsBurnerRushAttacker][iPlayer])
				{
					new iBurnCycles = kc_player_in_burn(ent)
					if (iBurnCycles < BURN_CYCLES)
						kc_player_burn(ent, iPlayer, BURN_CYCLES - iBurnCycles)
				}
				else
				{
					if (kc_player_burn(ent, iPlayer, BURN_CYCLES))
						Player[ent][IsBurnerRushAttacker][iPlayer] = true
				}
			}
			else if (get_entvar(ent, var_impulse) == IMPULSE_TORNADO && iTeam == get_entvar(ent, var_team))
				tornado_burn(ent)

			ent = engfunc(EngFunc_FindEntityInSphere, ent, vOrigin, RUSH_RADIUS)
		}

		static Float:vRushVector[3]
		xs_vec_copy(PlayerF[iPlayer][RushVector], vRushVector)
		if (PlayerF[iPlayer][RushVector][2] != RUSH_JUMP)
			vRushVector[2] = get_entvar(iPlayer, var_button) & IN_JUMP ? RUSH_JUMP : 10.0
		set_entvar(iPlayer, var_velocity, vRushVector)
	}

	return HAM_IGNORED
}

public fw_PlayerKilled(iVictim, iAttacker)
{
	Player[iVictim][IsAlive] = false
	PlayerF[iVictim][RushTime] = 0.0
	arrayset(Player[iVictim][IsBurnerRushAttacker], false, MAX_PLAYERS + 1)
	kc_player_unset_game_flag(iVictim, PLGF_IN_BURNRUSH)

	return HAM_IGNORED
}

public fw_PlayerTakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bits)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (fDamage < 1.0)
		return HAM_IGNORED

	if (!Player[iVictim][IsAlive] || Player[iVictim][Knife] != g_iKnifeId)
		return HAM_IGNORED

	if (bits & DMG_BURN)
		return HAM_IGNORED

	static const Float:ABIL2_RESET = 90.0

	if (kc_player_get_abil2_charge(iVictim) > ABIL2_RESET)
		kc_player_set_abil2_charge(iVictim, ABIL2_RESET)

	return HAM_IGNORED
}

public beam_think(iBeamEnt)
{
	new iLife = get_entvar(iBeamEnt, var_laserlife)

	if (iLife)
	{
		static Float:vColor[3]
		vColor[1] = 0.0
		vColor[2] = 255.0 * iLife / LASER_CYCLES
		vColor[0] = 255.0 - vColor[2]

		set_entvar(iBeamEnt, var_rendercolor, vColor)
		set_entvar(iBeamEnt, var_laserlife, iLife - 1)
		set_entvar(iBeamEnt, var_nextthink, get_gametime() + 0.1)
	}
	else
	{
		new Float:vOrigin[3]
		get_entvar(iBeamEnt, var_origin, vOrigin)
		new iOwner = get_entvar(iBeamEnt, var_owner)

		send_msg_TE_DLIGHT(vOrigin, floatround(LASER_RADIUS / 3.0),
			{FIRE_COLOR_R, FIRE_COLOR_G, FIRE_COLOR_B}, 16, 10)

		for (new i, Float:vSpriteOrigin[3]; i < 6; i++)
		{
			vSpriteOrigin[0] = vOrigin[0] + floatcos(i * 60.0, degrees) * LASER_RADIUS / 2.0
			vSpriteOrigin[1] = vOrigin[1] + floatsin(i * 60.0, degrees) * LASER_RADIUS / 2.0
			vSpriteOrigin[2] = vOrigin[2] + 30.0
			send_msg_TE_SPRITE(vSpriteOrigin, sprFire, 8, 255)
		}

		engfunc(EngFunc_EmitSound, iBeamEnt, CHAN_AUTO, SOUND_LASER_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM)

		new ent = -1
		new iTeam = get_member(iOwner, m_iTeam)
		while ((ent = engfunc(EngFunc_FindEntityInSphere, ent, vOrigin, LASER_RADIUS)))
		{
			if (is_entity_player(ent))
				kc_player_burn(ent, iOwner, BURN_CYCLES)
			else if ((get_entvar(ent, var_flags) & FL_MONSTER) && get_entvar(ent, var_skin) != get_entvar(iBeamEnt, var_skin))
				ExecuteHamB(Ham_TakeDamage, ent, iOwner, iOwner, 45.0, DMG_BURN)
			else if (get_entvar(ent, var_impulse) == IMPULSE_TORNADO && iTeam == get_entvar(ent, var_team))
				tornado_burn(ent)

		}

		new iCreator = get_entvar(iBeamEnt, var_creator)
		if (Player[iCreator][Laser] == iBeamEnt)
			Player[iCreator][Laser] = 0

		rg_remove_entity(get_entvar(iBeamEnt, var_crosshair))
		rg_remove_entity(iBeamEnt)
	}
}

public fw_Touch(iEnt, iOther)
{
	if (!is_entity_player(iOther) || PlayerF[iOther][RushTime] == 0.0 || is_nullent(iEnt))
		return

	if (get_entvar(iEnt, var_impulse) == IMPULSE_FIELD_WALL)
	{
		if (get_entvar(iEnt, var_skin) + 1 != get_member(iOther, m_iTeam))
		{
			PlayerF[iOther][RushVector][0] = 0.0
			PlayerF[iOther][RushVector][1] = 0.0
			PlayerF[iOther][RushVector][2] = RUSH_JUMP
		}
	}
}

public efk_ability(iPlayer)
{
	new iCrossEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iCrossEnt))
		return PLUGIN_HANDLED

	engfunc(EngFunc_SetModel, iCrossEnt, MODEL_CROSSHAIR)
	engfunc(EngFunc_SetSize, iCrossEnt, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 4.0})
	set_entvar(iCrossEnt, var_skin, get_member(iPlayer, m_iTeam) - 1)
	set_entvar(iCrossEnt, var_rendermode, kRenderNormal)
	set_entvar(iCrossEnt, var_sequence, 0)
	set_entvar(iCrossEnt, var_framerate,  1.0)
	set_entvar(iCrossEnt, var_animtime, get_gametime())
	set_entvar(iCrossEnt, var_movetype, MOVETYPE_PUSHSTEP)

	new iBeamEnt = rg_create_entity(SZ_BEAM)
	if (is_nullent(iBeamEnt))
	{
		rg_remove_entity(iCrossEnt)
		return PLUGIN_HANDLED
	}

	set_entvar(iBeamEnt, var_classname, CLASSNAME_LASER)
	set_entvar(iBeamEnt, var_impulse, IMPULSE_LASER)
	set_entvar(iBeamEnt, var_flags, FL_CUSTOMENTITY)
	set_entvar(iBeamEnt, var_rendermode, kRenderNormal)
	set_entvar(iBeamEnt, var_rendercolor, Float:{0.0, 0.0, 255.0})
	set_entvar(iBeamEnt, var_renderamt, 255.0)
	set_entvar(iBeamEnt, var_modelindex, sprBeam)
	set_entvar(iBeamEnt, var_scale, 6.0)
	set_entvar(iBeamEnt, var_owner, iPlayer)
	set_entvar(iBeamEnt, var_creator, iPlayer)
	set_entvar(iBeamEnt, var_crosshair, iCrossEnt)

	new Float:vOrigin[3], Float:vAimOrigin[3]
	get_aim_origin(iPlayer, vOrigin, vAimOrigin)

	engfunc(EngFunc_SetOrigin, iBeamEnt, vAimOrigin)
	engfunc(EngFunc_SetOrigin, iCrossEnt, vAimOrigin)
	vAimOrigin[2] += 500.0
	set_entvar(iBeamEnt, var_angles, vAimOrigin)

	set_entvar(iBeamEnt, var_nextthink, get_gametime() + 0.1)
	set_entvar(iBeamEnt, var_laserlife, LASER_CYCLES)

	set_entvar(iBeamEnt, var_mins, Float:{0.0, 0.0, 0.0})
	set_entvar(iBeamEnt, var_maxs, Float:{0.0, 0.0, 500.0})
	engfunc(EngFunc_SetSize, iBeamEnt, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 500.0})

	SetThink(iBeamEnt, "beam_think")

	engfunc(EngFunc_EmitSound, iBeamEnt, CHAN_AUTO, SOUND_LASER, 1.0, ATTN_NORM, 0, PITCH_NORM)

	Player[iPlayer][Laser] = iBeamEnt

	return PLUGIN_CONTINUE
}

public efk_ability2(iPlayer)
{
	burn_rush(iPlayer, RUSH_TIME)
}

public efk_ability3(iPlayer)
{
	if (!kc_player_reburn(iPlayer))
		return PLUGIN_HANDLED

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_STATIC, SOUND_TIMEREBURN, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	send_msg_TE_DLIGHT(vOrigin, 40, {255, 100, 0}, 8, 60)

	Player[iPlayer][Laser] = 0

	new Float:fGameTime = kc_player_get_reburn_timestate(iPlayer)
	if (PlayerF[iPlayer][StartRushTime] > 0.0
		&& PlayerF[iPlayer][StartRushTime] <= fGameTime && fGameTime < PlayerF[iPlayer][EndRushTime])
	{
		burn_rush(iPlayer, RUSH_TIME - (fGameTime - PlayerF[iPlayer][StartRushTime]))
	}
	else if (PlayerF[iPlayer][RushTime] > 0.0)
	{
		restore_fov(iPlayer)
		PlayerF[iPlayer][RushTime] = 0.0
		kc_player_unset_game_flag(iPlayer, PLGF_IN_BURNRUSH)
	}

	return PLUGIN_CONTINUE
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][Knife] = iKnifeId
	Player[iPlayer][Laser] = 0

	if (g_iKnifeId != iKnifeId && PlayerF[iPlayer][RushTime] > 0.0)
		stop_rush(iPlayer)
}

public efk_unburn(iPlayer)
{
	arrayset(Player[iPlayer][IsBurnerRushAttacker], false, MAX_PLAYERS + 1)
}

public efk_disenergy(iPlayer)
{
	if (PlayerF[iPlayer][RushTime] > 0.0)
		stop_rush(iPlayer)
}

burn_rush(iPlayer, Float:fRushTime)
{
	kc_player_unfreeze(iPlayer)
	kc_player_unchill(iPlayer)

	new Float:vVector[3]
	get_entvar(iPlayer, var_v_angle, vVector)
	angle_vector(vVector, ANGLEVECTOR_FORWARD, vVector)
	xs_vec_mul_scalar(vVector, RUSH_SPEED, vVector)
	vVector[2] = 10.0
	PlayerF[iPlayer][RushVector] = vVector

	set_member(iPlayer, m_flNextAttack, fRushTime)

	set_member(iPlayer, m_iFOV, RUSH_FOV)
	set_member(iPlayer, m_iClientFOV, RUSH_FOV)
	set_entvar(iPlayer, var_fov, RUSH_FOV)

	send_msg_SetFOV(RUSH_FOV, MSG_ONE, _, iPlayer)

	set_pev(iPlayer, pev_viewmodel, 0)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new Float:fGameTime = get_gametime()
	PlayerF[iPlayer][RushTime] = fGameTime + fRushTime
	PlayerF[iPlayer][StartRushTime] = fGameTime
	kc_player_set_game_flag(iPlayer, PLGF_IN_BURNRUSH)
}

stop_rush(iPlayer)
{
	xs_vec_div_scalar(PlayerF[iPlayer][RushVector], RUSH_SPEED, PlayerF[iPlayer][RushVector])
	PlayerF[iPlayer][RushVector][2] = 10.0
	set_entvar(iPlayer, var_velocity, PlayerF[iPlayer][RushVector])

	restore_fov(iPlayer)
	PlayerF[iPlayer][RushTime] = 0.0
	PlayerF[iPlayer][EndRushTime] = get_gametime()
	kc_player_unset_game_flag(iPlayer, PLGF_IN_BURNRUSH)
}

restore_fov(iPlayer)
{
	if (get_member(iPlayer, m_iFOV) != 90)
	{
		set_member(iPlayer, m_iFOV, 90)
		set_member(iPlayer, m_iClientFOV, 90)
		set_entvar(iPlayer, var_fov, 90)

		send_msg_SetFOV(90, MSG_ONE, _, iPlayer)
	}

	new iItem = get_member(iPlayer, m_pActiveItem)
	if (!is_nullent(iItem))
		ExecuteHamB(Ham_Item_Deploy, iItem)
}

create_red_waves(Float:vOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vOrigin)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	write_short(300)
	write_short(sprShadowCircle)
	write_byte(0)
	write_byte(0)
	write_byte(1)
	write_byte(8)
	write_byte(0)
	write_byte(255)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	write_byte(0)
	message_end()
}

get_aim_origin(iPlayer, Float:vOrigin[3], Float:vAimOrigin[3])
{
	static Float:vStart[3], Float:vViewOfs[3], Float:vDest[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vOrigin, vViewOfs, vStart)

	get_entvar(iPlayer, var_v_angle, vDest)
	engfunc(EngFunc_MakeVectors, vDest)
	global_get(glb_v_forward, vDest)
	xs_vec_mul_scalar(vDest, 8192.0, vDest)
	xs_vec_add(vStart, vDest, vDest)

	engfunc(EngFunc_TraceLine, vStart, vDest, 0, iPlayer, 0)
	get_tr2(0, TR_vecEndPos, vAimOrigin)

	return 1
}

crosshair_ent_remove(iEnt)
{
	new iCrosshairEnt = get_entvar(iEnt, var_crosshair)
	if (!is_nullent(iCrosshairEnt))
		rg_remove_entity(iCrosshairEnt)

	rg_remove_entity(iEnt)
}
