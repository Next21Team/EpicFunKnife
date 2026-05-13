#include <amxmodx>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <efk_core>
#include <efk_utils>

new const PLUGIN[] = "Frost Knife"

#define KNIFE_CLASSNAME "weapon_next21_frost"
#define KNIFE_MENUDESC  "KNIFE_FROST_DESC"
#define KNIFE_CHATDESC  "KNIFE_FROST_CHAT"

#define HP				90.0
#define GRAVITY			1.0
#define SPEED			255.0
#define MINDAMAGE		0.0
#define MAXDAMAGE		0.0

#define ABIL1_NAME		"Frost"
#define ABIL1_CHARGE	5.0

#define ABIL2_NAME		"Icicles"
#define ABIL2_CHARGE	14.286

new const ABIL3_NAME[] = "Ice Clone"
#define ABIL3_CHARGE	7.693

#define START_CRIT_CHANCE	2.77
#define CON_CRIT_CHANCE		4.54
#define LIMIT_CRIT_CHANCE	30.0
#define ADD_CRIT_CHANCE		1.0

#define Player[%1][%2]		g_player_data[%1 - 1][%2]
#define PlayerF[%1][%2]		g_player_data_f[%1 - 1][%2]

new const MODEL_V_KNIFE[] =	"models/next21_efk/v_frost_knife_b08.mdl"
new const MODEL_P_KNIFE[] =	"models/next21_efk/p_frost_knife_b07.mdl"

new const SOUND_KNIFE_DEPLOY[] = "next21_efk/frost_knife_deploy.wav"
new const SOUND_KNIFE_HIT1[] = "next21_efk/frost_knife_hit1.wav"
new const SOUND_KNIFE_HIT2[] = "next21_efk/frost_knife_hit2.wav"
new const SOUND_KNIFE_HITWALL[] = "next21_efk/frost_knife_hitwall.wav"
new const SOUND_KNIFE_SLASH1[] = "next21_efk/frost_knife_slash1.wav"
new const SOUND_KNIFE_SLASH2[] = "next21_efk/frost_knife_slash2.wav"

#define FROST_BUFF_TIME		5.0

#define FROST_REFLECTION_TIME	5.0

#define FREEZE_MAXCHANCE	100.0
#define FREEZE_MINCHANCE	40.0

#define ICICLE_DAMAGE			15.0
#define ICICLE_DAMAGE_WEAK		10.0
#define ICICLE_DAMAGE_STRONG	23.0
#define ICICLE_START_AMMO		3
#define ICICLE_MAX_GROW_AMMO	3
#define ICICLE_MAX_AMMO			5
#define ICICLE_AMMO_ADD_DMG		30.0
#define ICICLE_GROWTH_TIME		5.0
#define ICICLE_NEXTTHROW_TIME	1.5
#define ICICLE_SPEED			2000.0
#define ICICLE_FLY_DISTANCE		8192.0
#define ICICLE_WEAK_DISTANCE	750.0
#define DEFAULT_ATTACK_SPEED	3

#define CHARGE_COMP_RAISE_ICICLE	45.0
#define CHARGE_COMP_TEAMMATE_HELP	45.0

#define BACKJUMP_FORCE		220.0

#define FROST_RADIUS		240.0
new const SOUND_FROST[] = "next21_efk/frost_ativation.wav"

new const MODEL_ICICLE[] = "models/next21_efk/icicle_b01.mdl"
new const SOUND_ICICLE_LAUNCH[] = "next21_efk/icicle_launch.wav"
new const SOUND_ICICLE_DAMAGE[] = "next21_efk/icicle_damage.wav"

new const CLASSNAME_ICE_CLONE[] = "next21_iceclone"
new const CLASSNAME_ICE_CLONE_PART_[] = CLASSNAME_ICE_CLONE_PART
#define	ICE_CLONE_LIFE			5.0

#define FREEEZE_ABIL_SLOW_TIME 	0.5

#define FROST_REFLECTION_COLOR_R	0
#define FROST_REFLECTION_COLOR_G	164
#define FROST_REFLECTION_COLOR_B	255
new const COLOR_FROST_REFLECTION[]	= {FROST_REFLECTION_COLOR_R, FROST_REFLECTION_COLOR_G, FROST_REFLECTION_COLOR_B}

new const FROST_REFLECTION_ICON[] 	= "suit_full"

new const SZ_INFO_TARGET[]			= "info_target"

#define var_icicle_trace			var_iuser1
#define var_icicle_strong			var_iuser2
#define var_icicle_buffed			var_iuser3
#define var_icicle_spawntime		var_fuser1
#define var_icicle_spawnorigin		var_vuser1

#define var_clone_buffed			var_iuser2

enum _:Player_Properties
{
	Knife,
	AttackSpeed,
	AccessFlag,
	IcicleAmmo,
	IcicleMaxAmmo,
	IcicleMaxGrowAmmo,
	bool:GotIcicleForDmg,
	Float:FrostBuffTime,
	Float:FrostReflectionTime
}

enum _:Player_Properties_F
{
	Float:IcicleNextGrowthTime,
	Float:IcicleNextThrowTime,
	Float:AttackSpeedTime,
	Float:CritChance,
	Float:DamageCounter
}

enum _:ViewSeq
{
	VIEW_SEQ_IDLE,
	VIEW_SEQ_DRAW = 3,
	VIEW_SEQ_STAB,
	VIEW_SEQ_STABMISS,
	VIEW_SEQ_MIDSLASH1,
	VIEW_SEQ_MIDSLASH2,
	VIEW_SEQ_SHOOT0,
	VIEW_SEQ_SHOOT1,
	VIEW_SEQ_SHOOT2,
	VIEW_SEQ_SHOOT3,
	VIEW_SEQ_SHOOT4,
	VIEW_SEQ_SHOOT5,
	VIEW_SEQ_SET_BUFF,
	VIEW_SEQ_IDLE_BUFF,
	VIEW_SEQ_STAB_BUFF,
	VIEW_SEQ_STABMISS_BUFF,
	VIEW_SEQ_MIDSLASH1_BUFF,
	VIEW_SEQ_MIDSLASH2_BUFF,
	VIEW_SEQ_UNSET_BUFF
}

enum _:AttackState
{
	AD_ATTACKER,
	AD_VICTIM,
	bool:AD_WAS_HIT,
	AD_VIEW_SEQ
}

new
	g_iKnifeId, g_player_data[MAX_PLAYERS][Player_Properties], Float:g_player_data_f[32][Player_Properties_F],
	g_eAttackState[AttackState],
	g_pKnifeVStr, g_pKnifePMdl,
	g_pLaserbeamSpr, g_pShockwaveSpr,
	HookChain:g_hcFrostClearMultiDamage

public plugin_precache()
{
	precache_generic(fmt("sprites/%s.txt", KNIFE_CLASSNAME))

	g_pKnifeVStr = engfunc(EngFunc_AllocString, MODEL_V_KNIFE)
	precache_model(MODEL_V_KNIFE)
	g_pKnifePMdl = precache_model(MODEL_P_KNIFE)

	precache_sound(SOUND_KNIFE_DEPLOY)
	precache_sound(SOUND_KNIFE_HIT1)
	precache_sound(SOUND_KNIFE_HIT2)
	precache_sound(SOUND_KNIFE_HITWALL)
	precache_sound(SOUND_KNIFE_SLASH1)
	precache_sound(SOUND_KNIFE_SLASH2)

	precache_model(MODEL_ICICLE)

	precache_sound(SOUND_ICICLE_LAUNCH)
	precache_sound(SOUND_ICICLE_DAMAGE)

	precache_sound(SOUND_FROST)

	g_pLaserbeamSpr = precache_model("sprites/laserbeam.spr")
	g_pShockwaveSpr = precache_model("sprites/shockwave.spr")
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
	kc_register_ability3(g_iKnifeId, ABIL3_NAME, ABIL3_CHARGE)

	kc_knife_set_sound(g_iKnifeId, "weapons/knife_deploy1.wav", SOUND_KNIFE_DEPLOY)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit1.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit2.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit3.wav", SOUND_KNIFE_HIT1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hit4.wav", SOUND_KNIFE_HIT2)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_hitwall1.wav", SOUND_KNIFE_HITWALL)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash1.wav", SOUND_KNIFE_SLASH1)
	kc_knife_set_sound(g_iKnifeId, "weapons/knife_slash2.wav", SOUND_KNIFE_SLASH2)

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)

	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)
	RegisterHam(Ham_Player_PreThink, "player", "fw_PreThink")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_PrimaryAttack_Pre")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_SecondaryAttack_Pre")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_SecondaryAttack_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerDamage")
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG_CBasePlayer_TraceAttack_Pre")
	RegisterHookChain(RG_CBasePlayerWeapon_SendWeaponAnim, "RG_CBasePlayerWeapon_SendWeaponAnim_Pre")

	g_hcFrostClearMultiDamage = RegisterHookChain(RG_ClearMultiDamage, "RG_Frost_ClearMultiDamage_Post", true)

	DisableHookChain(g_hcFrostClearMultiDamage)

	register_impulse(100, "fw_PlayerFlashlight")
}

public client_putinserver(iPlayer)
{
	PlayerF[iPlayer][CritChance] = START_CRIT_CHANCE
	Player[iPlayer][AccessFlag] = get_user_flags(iPlayer)
}

public client_disconnected(iPlayer)
{
	Player[iPlayer][FrostBuffTime] = 0.0
	remove_frost_reflection(iPlayer)

	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ICE_CLONE)))
		if (get_entvar(iEnt, var_owner) == iPlayer)
			ice_clone_remove(iEnt)
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ICE_CLONE)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ICE_CLONE_PART_)))
		rg_remove_entity(iEnt)

	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, CLASSNAME_ICICLE)))
		rg_remove_entity(iEnt)
}

public event_CurWeapon(const iPlayer)
{
	Player[iPlayer][FrostBuffTime] = 0.0
}

public fw_PlayerSpawn(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return

	Player[iPlayer][AttackSpeed] = Player[iPlayer][Knife] == g_iKnifeId ? DEFAULT_ATTACK_SPEED : 0
	Player[iPlayer][IcicleAmmo] = 0
	Player[iPlayer][IcicleMaxAmmo] = ICICLE_MAX_GROW_AMMO
	Player[iPlayer][IcicleMaxGrowAmmo] = ICICLE_MAX_GROW_AMMO
	PlayerF[iPlayer][IcicleNextGrowthTime] = 0.0
	player_icicle_afterthrow_delay(iPlayer)
	PlayerF[iPlayer][AttackSpeedTime] = 0.0
	Player[iPlayer][FrostBuffTime] = 0.0
	remove_frost_reflection(iPlayer)
}

public fw_PlayerKilled(iVictim, attacker)
{
	Player[iVictim][FrostBuffTime] = 0.0
	remove_frost_reflection(iVictim)

	if (!is_entity_player(attacker))
		return HAM_IGNORED

	if (attacker == iVictim)
		return HAM_IGNORED

	if (Player[attacker][Knife] != g_iKnifeId)
		return HAM_IGNORED

	try_increase_max_icicles_ammo(attacker)
	if (!Player[attacker][GotIcicleForDmg])
		try_increase_icicles_ammo(attacker)

	if (PlayerF[attacker][CritChance] >= LIMIT_CRIT_CHANCE)
	{
		PlayerF[attacker][CritChance] = CON_CRIT_CHANCE
		kc_player_set_crit_chance(attacker, CON_CRIT_CHANCE)
	}
	else
	{
		PlayerF[attacker][CritChance] = koef_to_chance(chance_to_koef(PlayerF[attacker][CritChance]) - ADD_CRIT_CHANCE)
		kc_player_set_crit_chance(attacker, PlayerF[attacker][CritChance])
	}

	return HAM_IGNORED
}

try_increase_max_icicles_ammo(iPlayer, iAdd=1)
{
	if (Player[iPlayer][IcicleMaxAmmo] < ICICLE_MAX_AMMO)
		Player[iPlayer][IcicleMaxAmmo] += iAdd
}

try_increase_icicles_ammo(iPlayer, iAdd=1)
{
	if (Player[iPlayer][IcicleAmmo] < Player[iPlayer][IcicleMaxAmmo])
		Player[iPlayer][IcicleAmmo] += iAdd
}

public fw_PreThink(iPlayer)
{
	static iIcicleButton
	new Float:fGameTime = get_gametime()
	new iButtons = get_entvar(iPlayer, var_button)

	if (Player[iPlayer][FrostBuffTime] > 0.0 && Player[iPlayer][FrostBuffTime] < fGameTime)
	{
		if (get_entvar(iPlayer, var_weaponanim) == VIEW_SEQ_IDLE_BUFF)
			play_unset_buff_anim(iPlayer)
		Player[iPlayer][FrostBuffTime] = 0.0
	}

	if (Player[iPlayer][FrostReflectionTime] > 0.0 &&
		(Player[iPlayer][FrostReflectionTime] < fGameTime || kc_player_in_burn(iPlayer)))
	{
		remove_frost_reflection(iPlayer)
	}

	if (Player[iPlayer][AttackSpeed] > DEFAULT_ATTACK_SPEED)
	{
		if(PlayerF[iPlayer][AttackSpeedTime] < fGameTime)
		{
			Player[iPlayer][AttackSpeed]--
			PlayerF[iPlayer][AttackSpeedTime] = fGameTime + 1.0
		}
	}

	if (Player[iPlayer][Knife] == g_iKnifeId)
	{
		if (fGameTime < kc_player_get_swap(iPlayer))
			iIcicleButton = IN_RELOAD
		else
			iIcicleButton = IN_USE

		if ((iButtons & iIcicleButton) && !kc_player_in_silence(iPlayer) && kc_player_get_capture(iPlayer) == CAPTURE_NONE)
		{
			if (fGameTime > PlayerF[iPlayer][IcicleNextThrowTime])
			{
				if (Player[iPlayer][IcicleAmmo] > 0)
				{
					player_throw_icicle(iPlayer)
				}
				else if (Player[iPlayer][FrostBuffTime] > 0.0)
				{
					try_increase_icicles_ammo(iPlayer)
					player_icicle_afterthrow_delay(iPlayer)

					kc_player_set_abil1_charge(iPlayer,
						floatmin(kc_player_get_abil1_charge(iPlayer) + CHARGE_COMP_RAISE_ICICLE, 99.0))

					play_unset_buff_anim(iPlayer)
					Player[iPlayer][FrostBuffTime] = 0.0
				}
			}
		}

		if (PlayerF[iPlayer][IcicleNextGrowthTime] != 0.0)
		{
			if (fGameTime > PlayerF[iPlayer][IcicleNextGrowthTime])
			{
				Player[iPlayer][IcicleAmmo]++

				if (Player[iPlayer][IcicleAmmo] < Player[iPlayer][IcicleMaxGrowAmmo] && is_user_can_grow_icicles(iPlayer))
					PlayerF[iPlayer][IcicleNextGrowthTime] = fGameTime + ICICLE_GROWTH_TIME
				else
					PlayerF[iPlayer][IcicleNextGrowthTime] = 0.0
			}
		}
		else if (is_user_can_grow_icicles(iPlayer) && Player[iPlayer][IcicleAmmo] < Player[iPlayer][IcicleMaxGrowAmmo])
		{
			PlayerF[iPlayer][IcicleNextGrowthTime] = fGameTime + ICICLE_GROWTH_TIME
		}
	}
}

bool:is_user_can_grow_icicles(iPlayer)
{
	#pragma unused iPlayer
	return false
}

public efk_disenergy(iPlayer)
{
	if (Player[iPlayer][Knife] == g_iKnifeId)
	{
		if(Player[iPlayer][IcicleAmmo] > 0)
			Player[iPlayer][IcicleAmmo]--

		PlayerF[iPlayer][IcicleNextGrowthTime] = 0.0
		player_icicle_afterthrow_delay(iPlayer)
		remove_frost_reflection(iPlayer)
	}
}

public efk_capture(iPlayer, CaptureType:iType)
{
	remove_frost_reflection(iPlayer)
}

public fw_PrimaryAttack_Pre(iItem)
{
	if (is_nullent(iItem))
		return HAM_IGNORED

	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	new iPlayer = get_member(iItem, m_pPlayer)

	frost_buff_attack_pre(iPlayer)

	return HAM_IGNORED
}

public fw_PrimaryAttack_Post(iItem)
{
	if (is_nullent(iItem))
		return HAM_IGNORED

	new iPlayer = get_member(iItem, m_pPlayer)

	frost_buff_attack_post(iPlayer)

	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	new Float:fNextAttack = Float:get_member(iItem, m_Weapon_flNextPrimaryAttack)

	if (Player[iPlayer][AttackSpeed] && fNextAttack < 1.0)
		set_member(iItem, m_Weapon_flNextPrimaryAttack, 0.33 - (Player[iPlayer][AttackSpeed] * 0.03))

	return HAM_IGNORED
}

public fw_SecondaryAttack_Pre(iItem)
{
	if (is_nullent(iItem))
		return HAM_IGNORED

	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	new iPlayer = get_member(iItem, m_pPlayer)

	frost_buff_attack_pre(iPlayer)

	return HAM_IGNORED
}

public fw_SecondaryAttack_Post(iItem)
{
	if (is_nullent(iItem))
		return HAM_IGNORED

	new iPlayer = get_member(iItem, m_pPlayer)

	frost_buff_attack_post(iPlayer)

	return HAM_IGNORED
}

public RG_CBasePlayer_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:vDirection[3], iTraceId, iFlags)
{
	if (!is_entity_player(iAttacker))
		return HC_CONTINUE

	if (get_user_weapon(iAttacker) != CSW_KNIFE)
		return HC_CONTINUE

	if (g_eAttackState[AD_ATTACKER] == iAttacker)
	{
		g_eAttackState[AD_VICTIM] = iVictim

		if (Player[iAttacker][FrostBuffTime] > 0.0)
			SetHookChainArg(6, ATYPE_INTEGER, iFlags | DMG_FREEZE)
	}

	return HC_CONTINUE
}

public fw_PlayerDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (GetHamReturnStatus() == HAM_SUPERCEDE)
		return HAM_SUPERCEDE

	if (!is_entity_player(iAttacker))
		return HAM_IGNORED

	if (!iInflictor || iVictim == iAttacker)
		return HAM_IGNORED

	if (Player[iVictim][FrostReflectionTime] > 0.0 && iInflictor == iAttacker && (iFlags & DMG_BULLET))
	{
		if (!kc_player_check_game_flag(iAttacker, PLGF_IN_UNABILITY))
			kc_player_freeze(iAttacker, FREEZE_TIME, iVictim)

		remove_frost_reflection(iVictim)

		return HAM_IGNORED
	}

	if (iInflictor == iAttacker || get_entvar(iInflictor, var_impulse) == IMPULSE_ICILCE)
	{
		if (Player[iAttacker][Knife] == g_iKnifeId)
		{
			if(Player[iAttacker][AttackSpeed] <= 6)
				Player[iAttacker][AttackSpeed]++
			PlayerF[iAttacker][AttackSpeedTime] = get_gametime() + 3.0

			PlayerF[iAttacker][DamageCounter] += fDamage
			if (PlayerF[iAttacker][DamageCounter] >= ICICLE_AMMO_ADD_DMG)
			{
				try_increase_icicles_ammo(iAttacker)
				PlayerF[iAttacker][DamageCounter] = 0.0
				Player[iAttacker][GotIcicleForDmg] = true
			}
			else Player[iAttacker][GotIcicleForDmg] = false
		}
	}

	return HAM_IGNORED
}

public RG_CBasePlayerWeapon_SendWeaponAnim_Pre(const iItem, iAnim, iSkiplocal)
{
	if (get_member(iItem, m_iId) != WEAPON_KNIFE)
		return HC_CONTINUE

	new iPlayer = get_member(iItem, m_pPlayer)
	if (!is_user_alive(iPlayer))
		return HC_CONTINUE

	if (g_eAttackState[AD_ATTACKER] == iPlayer)
	{
		g_eAttackState[AD_VIEW_SEQ] = iAnim
		return HC_SUPERCEDE
	}

	if (iAnim == VIEW_SEQ_IDLE)
	{
		if (Player[iPlayer][FrostBuffTime] > 0.0)
		{
			SetHookChainArg(2, ATYPE_INTEGER, VIEW_SEQ_IDLE_BUFF)
		}
		else if (get_entvar(iPlayer, var_weaponanim) == VIEW_SEQ_IDLE_BUFF)
		{
			SetHookChainArg(2, ATYPE_INTEGER, VIEW_SEQ_UNSET_BUFF)
			set_member(iItem, m_Weapon_flTimeWeaponIdle, 0.625)
		}
	}

	return HC_CONTINUE
}

public RG_Frost_ClearMultiDamage_Post()
{
	g_eAttackState[AD_WAS_HIT] = true
}

public fw_PlayerFlashlight(const iPlayer)
{
	if (Player[iPlayer][Knife] != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (!kc_player_can_ability(iPlayer, 1))
		return PLUGIN_HANDLED

	new iItem = get_member(iPlayer, m_pActiveItem)

	if (!FClassnameIs(iItem, "weapon_knife"))
		return PLUGIN_HANDLED

	kc_player_unburn(iPlayer)

	kc_player_set_view_anim(iPlayer, VIEW_SEQ_SET_BUFF)
	set_member(iItem, m_Weapon_flTimeWeaponIdle, 1.0)

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FROST, 1.0, ATTN_NORM, 0, PITCH_NORM)

	Player[iPlayer][FrostBuffTime] = get_gametime() + FROST_BUFF_TIME

	kc_player_set_abil1_charge(iPlayer, -1.0)
	return PLUGIN_HANDLED
}

public icicle_think(iIcicleEnt)
{
	if (fm_get_speed(iIcicleEnt) > 0.0)
	{
		new Float:fMaxLiveTime = ICICLE_FLY_DISTANCE / ICICLE_SPEED
		new Float:fLiveTime = get_gametime() - Float:get_entvar(iIcicleEnt, var_icicle_spawntime)
		const Float:FADE_INTERVAL = 0.1

		if (fMaxLiveTime - fLiveTime < FADE_INTERVAL)
		{
			set_entvar(iIcicleEnt, var_renderfx, kRenderFxNone)
			new Float:fFadeTime = floatmax(0.0, fMaxLiveTime - fLiveTime)
			new Float:fAmt = 255.0 * (fFadeTime / FADE_INTERVAL)

			if (fAmt > 0.0)
				set_entvar(iIcicleEnt, var_renderamt, fAmt)
			else
				rg_remove_entity(iIcicleEnt)
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (is_user_alive(i) && fm_entity_range(i, iIcicleEnt) < 10.0)
				icicle_touch(iIcicleEnt, i)
		}

		set_entvar(iIcicleEnt, var_nextthink, get_gametime())
	}
	else if (get_entvar(iIcicleEnt, var_renderfx) != kRenderFxGlowShell)
	{
		new Float:fAmt = Float:get_entvar(iIcicleEnt, var_renderamt) - 5.0

		if (fAmt > 0.0)
		{
			set_entvar(iIcicleEnt, var_renderamt, fAmt)
			set_entvar(iIcicleEnt, var_nextthink, get_gametime() + 0.05)
		}
		else
			rg_remove_entity(iIcicleEnt)
	}
}

public icicle_touch(iIcicleEnt, iOther)
{
	new iOwner = get_entvar(iIcicleEnt, var_owner)
	new Float:fGameTime = get_gametime()

	if (is_user_alive(iOther))
	{
		if (iOwner != iOther || fGameTime - Float:get_entvar(iIcicleEnt, var_icicle_spawntime) > 0.1)
		{
			if (get_user_team(iOwner) != get_user_team(iOther) || iOwner == iOther)
			{
				new bool:bTraceIcicle = bool:get_entvar(iIcicleEnt, var_icicle_trace)

				if (kc_player_apply_concentblock(iOther, iIcicleEnt,
					bTraceIcicle ? ATTACK_HEAVINESS_HIGH : ATTACK_HEAVINESS_LOW, 150.0, true))
				{
					new Float:vOrigin[3]; get_entvar(iIcicleEnt, var_origin, vOrigin)

					send_msg_TE_SPARKS(vOrigin)

					new Float:vVelocity[3]; get_entvar(iIcicleEnt, var_velocity, vVelocity)
					new Float:fSpeed = xs_vec_len(vVelocity)
					velocity_by_aim(iOther, floatround(fSpeed), vVelocity)

					new Float:vAngles[3]
					vector_to_angle(vVelocity, vAngles)

					set_entvar(iIcicleEnt, var_velocity, vVelocity)
					set_entvar(iIcicleEnt, var_angles, vAngles)
					set_entvar(iIcicleEnt, var_nextthink, fGameTime + 10.0)
					set_entvar(iIcicleEnt, var_owner, iOther)
					set_entvar(iIcicleEnt, var_icicle_spawntime, fGameTime)
					set_entvar(iIcicleEnt, var_icicle_spawnorigin, vOrigin)

					return
				}

				new bool:bBuffed = get_entvar(iIcicleEnt, var_icicle_buffed)
				new Float:fDamage = icicle_get_damage(iIcicleEnt)

				new iDamageFlags = DMG_GENERIC | DMG_NEVERGIB
				if (bBuffed)
					iDamageFlags |= DMG_FREEZE

				kc_player_set_death_reason(iOther, "DEATH_REASON_ICICLE")
				set_member(iOther, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iOther, iIcicleEnt, iOwner, fDamage, iDamageFlags)

				engfunc(EngFunc_EmitSound, iOther, CHAN_WEAPON, SOUND_ICICLE_DAMAGE, 1.0, ATTN_NORM, 0, PITCH_NORM)
				create_directed_bloodstream(iIcicleEnt)
				rg_remove_entity(iIcicleEnt)

				if (bBuffed && is_user_alive(iOther)
					&& !kc_player_check_game_flag(iOther, PLGF_IN_UNABILITY))
				{
					new bool:bIsCrit = random_float(0.0, 100.0) <= PlayerF[iOwner][CritChance]
					if (bIsCrit && Player[iOwner][Knife] == g_iKnifeId && kc_player_try_crit(iOther, iOwner))
					{
						kc_player_set_death_reason(iOther, "DEATH_REASON_FROZEN")
						set_member(iOther, m_LastHitGroup, HIT_GENERIC)
						ExecuteHamB(Ham_TakeDamage, iOther, iOwner, iOwner, 2000.0, DMG_FREEZE | DMG_NEVERGIB)
					}
					else
					{
						kc_player_freeze(iOther, FREEZE_TIME, iOwner)
					}

					if (Player[iOwner][Knife] == g_iKnifeId)
						try_increase_icicles_ammo(iOwner)
				}
			}
			else
			{
				new Float:fDamage = icicle_get_damage(iIcicleEnt)
				ExecuteHamB(Ham_TakeDamage, iOther, iIcicleEnt, iOwner, fDamage, DMG_GENERIC)
			}
		}
		return
	}

	if (!iOther)
	{
		stop_icicle(iIcicleEnt)
		return
	}

	if (is_entity(iOther))
	{
		if (get_entvar(iOther, var_solid) > SOLID_TRIGGER)
		{
			if (get_entvar(iOther, var_flags) & FL_MONSTER)
			{
				if (get_user_team(iOwner) != get_entvar(iOther, var_skin) + 1)
				{
					new Float:fDamage = icicle_get_damage(iIcicleEnt)
					ExecuteHamB(Ham_TakeDamage, iOther, iIcicleEnt, iOwner, fDamage, DMG_FREEZE)

					engfunc(EngFunc_EmitSound, iOther, CHAN_WEAPON, SOUND_ICICLE_DAMAGE, 1.0, ATTN_NORM, 0, PITCH_NORM)
					rg_remove_entity(iIcicleEnt)
					create_directed_bloodstream(iIcicleEnt)
					return
				}
			}
			else
			{
				if (get_entvar(iOther, var_impulse) == IMPULSE_PRESENT)
					return
			}

			stop_icicle(iIcicleEnt)
		}
		else if (get_entvar(iOther, var_impulse) == IMPULSE_ICE_CLONE)
		{
			if (get_user_team(iOwner) == get_entvar(iOther, var_team))
				ice_clone_think(iOther)
		}
	}
}

Float:icicle_get_damage(iIcicleEnt)
{
	if (get_entvar(iIcicleEnt, var_icicle_strong))
		return ICICLE_DAMAGE_STRONG

	new Float:vIcicleOrigin[3], Float:vIcicleSpawnOrigin[3]
	get_entvar(iIcicleEnt, var_origin, vIcicleOrigin)
	get_entvar(iIcicleEnt, var_icicle_spawnorigin, vIcicleSpawnOrigin)

	if (get_distance_f(vIcicleOrigin, vIcicleSpawnOrigin) >= ICICLE_WEAK_DISTANCE)
		return ICICLE_DAMAGE_WEAK

	return ICICLE_DAMAGE
}

public ice_clone_think(iCloneEnt)
{
	new Float:vOrigin[3]
	get_entvar(iCloneEnt, var_origin, vOrigin)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(21)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2] + 385.0)
	write_short(g_pShockwaveSpr)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(60)
	write_byte(0)
	write_byte(FROST_COLOR_R)
	write_byte(FROST_COLOR_G)
	write_byte(FROST_COLOR_B)
	write_byte(100)
	write_byte(0)
	message_end()

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(21)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2] + 470.0)
	write_short(g_pShockwaveSpr)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(60)
	write_byte(0)
	write_byte(FROST_COLOR_R)
	write_byte(FROST_COLOR_G)
	write_byte(FROST_COLOR_B)
	write_byte(100)
	write_byte(0)
	message_end()

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(21)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2] + 555.0)
	write_short(g_pShockwaveSpr)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(60)
	write_byte(0)
	write_byte(FROST_COLOR_R)
	write_byte(FROST_COLOR_G)
	write_byte(FROST_COLOR_B)
	write_byte(100)
	write_byte(0)
	message_end()

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(27)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_byte(floatround(FROST_RADIUS / 5.0))
	write_byte(FROST_COLOR_R)
	write_byte(FROST_COLOR_G)
	write_byte(FROST_COLOR_B)
	write_byte(8)
	write_byte(60)
	message_end()

	emit_sound(iCloneEnt, CHAN_WEAPON, SOUND_FROST, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new iOwner = get_entvar(iCloneEnt, var_owner)
	new iTeam = is_user_connected(iOwner) ? get_member(iOwner, m_iTeam) : 0

	new iTarget = NULLENT
	while ((iTarget = engfunc(EngFunc_FindEntityInSphere, iTarget, vOrigin, FROST_RADIUS)))
	{
		if (iTarget > MaxClients)
			break

		if (iTarget == iOwner || !is_user_alive(iTarget))
			continue

		if (get_member(iTarget, m_iTeam) == iTeam)
		{
			kc_player_chill(iTarget, CHILL_TIME, iOwner)
			continue
		}

		new Float:vTargetOrigin[3]
		get_entvar(iTarget, var_origin, vTargetOrigin)

		if (calc_freeze_level_by_distance(get_distance_f(vTargetOrigin, vOrigin), FROST_RADIUS) == 2)
			kc_player_freeze(iTarget, FREEZE_TIME, iOwner)
		else
			kc_player_chill(iTarget, CHILL_TIME, iOwner)

		try_increase_icicles_ammo(iOwner)
	}

	if (get_entvar(iCloneEnt, var_clone_buffed) && is_user_alive(iOwner))
	{
		new Float:vViewOfs[3], Float:vAimOrigin[3], Float:vAimAngles[3]
		get_entvar(iOwner, var_origin, vAimOrigin)
		get_entvar(iOwner, var_view_ofs, vViewOfs)
		xs_vec_add(vAimOrigin, vViewOfs, vAimOrigin)
		get_entvar(iOwner, var_v_angle, vAimAngles)

		new Float:vAimDirection[3]
		engfunc(EngFunc_MakeVectors, vAimAngles)
		global_get(glb_v_forward, vAimDirection)

		new Float:vTargetOrigin[3]
		xs_vec_mul_scalar(vAimDirection, 8192.0, vTargetOrigin)
		xs_vec_add(vAimOrigin, vTargetOrigin, vTargetOrigin)
		engfunc(EngFunc_TraceLine, vAimOrigin, vTargetOrigin, DONT_IGNORE_MONSTERS, iOwner, 0)
		get_tr2(0, TR_vecEndPos, vTargetOrigin)

		new Float:vIcicleOrigin[3], Float:vDirection[3]
		xs_vec_add(vOrigin, vViewOfs, vIcicleOrigin)
		xs_vec_sub(vTargetOrigin, vIcicleOrigin, vDirection)
		xs_vec_normalize(vDirection, vDirection)

		new iIcicleEnt = create_icicle(vIcicleOrigin, vDirection, iOwner)
		if (!is_nullent(iIcicleEnt))
		{
			set_entvar(iIcicleEnt, var_icicle_buffed, 0)
			set_entvar(iIcicleEnt, var_icicle_spawntime, get_gametime())

			create_beamfollow(iIcicleEnt)

			engfunc(EngFunc_EmitSound, iCloneEnt, CHAN_WEAPON, SOUND_ICICLE_LAUNCH, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}

	ice_clone_remove(iCloneEnt)
}

public ice_clone_touch(iEnt, iOther)
{
	if (is_user_alive(iOther))
	{
		new iOwner = get_entvar(iEnt, var_owner)
		if (get_user_team(iOwner) != get_user_team(iOther))
		{
			if (kc_player_freeze(iOther, FREEZE_TIME, iOwner))
				try_increase_icicles_ammo(iOwner)

			ice_clone_remove(iEnt)
		}
	}
}

ice_clone_remove(iEnt)
{
	new iClonePart = NULLENT
	while ((iClonePart = rg_find_ent_by_class(iClonePart, CLASSNAME_ICE_CLONE_PART_)))
		if (get_entvar(iClonePart, var_aiment) == iEnt)
			rg_remove_entity(iClonePart)

	rg_remove_entity(iEnt)
}

public efk_change_knife_core_post(iPlayer, iKnifeId)
{
	Player[iPlayer][AttackSpeed] = 0
	PlayerF[iPlayer][AttackSpeedTime] = 0.0
	PlayerF[iPlayer][IcicleNextGrowthTime] = 0.0
	Player[iPlayer][FrostBuffTime] = 0.0
	Player[iPlayer][Knife] = iKnifeId
	remove_frost_reflection(iPlayer)

	if (Player[iPlayer][Knife] == g_iKnifeId)
	{
		kc_player_set_crit_chance(iPlayer, PlayerF[iPlayer][CritChance])
		Player[iPlayer][AttackSpeed] = DEFAULT_ATTACK_SPEED
	}
}

public efk_ability(iPlayer)
{
	return PLUGIN_HANDLED
}

public efk_charge_draw_pre(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (kc_player_in_silence(iSubject))
		return PLUGIN_CONTINUE

	static szChargingText[128]; szChargingText[0] = 0
	new iLen = 0

	iLen += formatex(szChargingText[iLen], charsmax(szChargingText), "%s (R) (%dpt)",
		ABIL3_NAME, floatround(kc_player_get_abil3_charge(iPlayer), floatround_floor))

	if (kc_player_can_ability(iSubject, 1))
	{
		new iItem = get_member(iSubject, m_pActiveItem)
		if (!is_nullent(iItem) && get_member(iItem, m_iId) == WEAPON_KNIFE)
			iLen += formatex(szChargingText[iLen], charsmax(szChargingText), "^nFrost (F)")
	}

	set_hudmessage(255, 255, 255, 0.01, -0.75, 0, 0.0, 1.2, 0.0, 0.0, HUDCHANNEL_ALTABILITY)
	show_hudmessage(iPlayer, szChargingText)

	return PLUGIN_HANDLED
}

public efk_status_draw(iPlayer, iSubject, iKnifeId)
{
	if (iKnifeId != g_iKnifeId)
		return PLUGIN_CONTINUE

	if (kc_player_in_silence(iSubject))
	{
		set_hudmessage(255, 255, 255, 0.01, -0.72, 0, 0.0, 0.1, 0.1, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "...NO SIGNAL...")
		return PLUGIN_CONTINUE
	}

	if (Player[iSubject][FrostBuffTime] > 0.0 && Player[iSubject][IcicleAmmo] <= 0)
	{
		set_hudmessage(0, 20, 255, 0.01, -0.8, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_STATUS)
		show_hudmessage(iPlayer, "Raise Icicle (E)")
		return PLUGIN_CONTINUE
	}

	new szGrowthTimer[16], Float:fGameTime = get_gametime()
	new iHudColor[] = {FROST_COLOR_R, FROST_COLOR_G, FROST_COLOR_B}
	new Float:flNextGrowthTime = PlayerF[iSubject][IcicleNextGrowthTime]

	if (flNextGrowthTime != 0.0 && flNextGrowthTime > fGameTime)
		formatex(szGrowthTimer, charsmax(szGrowthTimer), "(%.1f)", flNextGrowthTime - fGameTime)

	if (PlayerF[iSubject][IcicleNextThrowTime] > fGameTime || Player[iSubject][IcicleAmmo] <= 0)
		iHudColor = {20, 20, 20}
	else if (user_can_trace_icicle(iSubject))
		iHudColor = {0, 20, 255}

	set_hudmessage(iHudColor[0], iHudColor[1], iHudColor[2], 0.01, -0.8, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_STATUS)
	show_hudmessage(iPlayer, "%s (E): (%d/%d) %s", ABIL2_NAME, Player[iSubject][IcicleAmmo], Player[iSubject][IcicleMaxAmmo], szGrowthTimer)

	return PLUGIN_CONTINUE
}

frost_buff_attack_pre(iPlayer)
{
	if (Player[iPlayer][FrostBuffTime] > 0.0)
	{
		g_eAttackState[AD_ATTACKER] = iPlayer
		g_eAttackState[AD_VICTIM] = 0
		g_eAttackState[AD_WAS_HIT] = false

		EnableHookChain(g_hcFrostClearMultiDamage)
	}
}

frost_buff_attack_post(iPlayer)
{
	if (g_eAttackState[AD_ATTACKER] == iPlayer)
	{
		g_eAttackState[AD_ATTACKER] = 0

		new iVictim = g_eAttackState[AD_VICTIM]
		if (Player[iPlayer][FrostBuffTime] > 0.0 && is_user_alive(iVictim)
			&& !kc_player_check_game_flag(iVictim, PLGF_IN_UNABILITY))
		{
			if (get_member(iVictim, m_iTeam) == get_member(iPlayer, m_iTeam))
			{
				if (kc_player_in_burn(iVictim))
				{
					kc_player_chill(iVictim, CHILL_TIME, iPlayer)
					kc_player_set_abil1_charge(iPlayer,
						floatmin(kc_player_get_abil1_charge(iPlayer) + CHARGE_COMP_TEAMMATE_HELP, 99.0))
				}
			}
			else
			{
				new bool:bIsCrit = random_float(0.0, 100.0) <= PlayerF[iPlayer][CritChance]
				if (bIsCrit && kc_player_try_crit(iVictim, iPlayer))
				{
					kc_player_set_death_reason(iVictim, "DEATH_REASON_FROZEN")
					set_member(iVictim, m_LastHitGroup, HIT_GENERIC)
					ExecuteHamB(Ham_TakeDamage, iVictim, iPlayer, iPlayer, 2000.0, DMG_FREEZE | DMG_NEVERGIB)
				}
				else
				{
					kc_player_freeze(iVictim, FREEZE_TIME, iPlayer)
				}

				kc_player_slow(iPlayer, 0.5, FREEEZE_ABIL_SLOW_TIME)
				try_increase_icicles_ammo(iPlayer)
			}
		}

		if (g_eAttackState[AD_WAS_HIT])
		{
			kc_player_set_view_anim(iPlayer, g_eAttackState[AD_VIEW_SEQ])
			Player[iPlayer][FrostBuffTime] = 0.0
		}
		else
		{
			new iViewSeq = g_eAttackState[AD_VIEW_SEQ]
			switch (iViewSeq)
			{
				case VIEW_SEQ_STAB: iViewSeq = VIEW_SEQ_STAB_BUFF
				case VIEW_SEQ_STABMISS: iViewSeq = VIEW_SEQ_STABMISS_BUFF
				case VIEW_SEQ_MIDSLASH1: iViewSeq = VIEW_SEQ_MIDSLASH1_BUFF
				case VIEW_SEQ_MIDSLASH2: iViewSeq = VIEW_SEQ_MIDSLASH2_BUFF
			}
			kc_player_set_view_anim(iPlayer, iViewSeq)
		}

		DisableHookChain(g_hcFrostClearMultiDamage)
	}
}

player_throw_icicle(iPlayer)
{
	if (throw_icicle(iPlayer, Player[iPlayer][FrostBuffTime] > 0.0))
	{
		Player[iPlayer][IcicleAmmo]--
		player_icicle_afterthrow_delay(iPlayer)
		Player[iPlayer][FrostBuffTime] = 0.0
	}
}

player_icicle_afterthrow_delay(iPlayer)
{
	new Float:fGameTime = get_gametime()
	PlayerF[iPlayer][IcicleNextThrowTime] = (fGameTime + ICICLE_NEXTTHROW_TIME) - (Player[iPlayer][AttackSpeed] * 0.2)

	if(PlayerF[iPlayer][IcicleNextGrowthTime] == 0.0
		&& Player[iPlayer][IcicleAmmo] < Player[iPlayer][IcicleMaxGrowAmmo]
		&& is_user_can_grow_icicles(iPlayer)
	) {
		PlayerF[iPlayer][IcicleNextGrowthTime] = fGameTime + ICICLE_GROWTH_TIME
	}
}

bool:user_can_trace_icicle(iPlayer)
{
	return bool:(get_entvar(iPlayer, var_waterlevel) >= 1)
}

bool:throw_icicle(iPlayer, bool:bBuffed=false)
{
	if (pev(iPlayer, pev_viewmodel) != g_pKnifeVStr)
		return false

	new iItem = get_member(iPlayer, m_pActiveItem)
	if (is_nullent(iItem))
		return false

	if (Float:get_member(iItem, m_Weapon_flNextPrimaryAttack) > 0.0)
		return false

	new iIcicleAmmo = Player[iPlayer][IcicleAmmo] - 1
	// if (iIcicleAmmo < Player[iPlayer][IcicleMaxAmmo] && get_gametime() + 1.0 > PlayerF[iPlayer][IcicleNextGrowthTime])
	// 	iIcicleAmmo++

	kc_player_set_view_anim(iPlayer, clamp(VIEW_SEQ_SHOOT0 + iIcicleAmmo, VIEW_SEQ_SHOOT0, VIEW_SEQ_SHOOT5))
	set_member(iItem, m_Weapon_flTimeWeaponIdle, iIcicleAmmo > 0 ? 5.0 : 1.375)

	rg_set_animation(iPlayer, PLAYER_ATTACK1)
	set_member(iItem, m_Weapon_flNextPrimaryAttack, 0.4)
	set_member(iItem, m_Weapon_flNextSecondaryAttack, 0.5)

	set_member(iPlayer, m_flNextAttack, 1.0)

	new Float:vOrigin[3], Float:vViewOfs[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vViewOfs)
	xs_vec_add(vOrigin, vViewOfs, vOrigin)

	new Float:vAngles[3], Float:vDirection[3]
	get_entvar(iPlayer, var_v_angle, vAngles)
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vDirection)

	new Float:vIcicleOrigin[3]
	xs_vec_mul_scalar(vDirection, 15.0, vIcicleOrigin)
	xs_vec_add(vOrigin, vIcicleOrigin, vIcicleOrigin)

	new iIcicleEnt = create_icicle(vIcicleOrigin, vDirection, iPlayer)
	if (is_nullent(iIcicleEnt))
		return false

	set_entvar(iIcicleEnt, var_icicle_buffed, bBuffed)
	set_entvar(iIcicleEnt, var_icicle_spawntime, get_gametime())

	new bool:bCanTrace = user_can_trace_icicle(iPlayer)

	if (bCanTrace || kc_player_get_windboost(iPlayer) == WINDBOOST_POSITIVE)
	{
		set_entvar(iIcicleEnt, var_icicle_trace, 1)
		set_entvar(iIcicleEnt, var_icicle_strong, bCanTrace)

		new Float:vStart[3], Float:vViewOfs[3],
			Float:vDest[3], Float:vHitPos[3], Float:vDirection[3]

		get_entvar(iPlayer, var_origin, vStart)
		get_entvar(iPlayer, var_view_ofs, vViewOfs)
		xs_vec_add(vStart, vViewOfs, vStart)
		get_entvar(iPlayer, var_v_angle, vDirection)
		engfunc(EngFunc_MakeVectors, vDirection)
		global_get(glb_v_forward, vDirection)
		xs_vec_mul_scalar(vDirection, 8192.0, vDest)
		xs_vec_add(vStart, vDest, vDest)

		engfunc(EngFunc_TraceLine, vStart, vDest, DONT_IGNORE_MONSTERS, iPlayer, 0)
		get_tr2(0, TR_vecEndPos, vHitPos)

		new Float:fFieldDist, iFieldEnt = check_field_part_on_line(iPlayer, vStart, vHitPos, fFieldDist)
		if (iFieldEnt)
		{
			xs_vec_add_scaled(vStart, vDirection, fFieldDist, vDest)
			engfunc(EngFunc_TraceLine, vStart, vDest, DONT_IGNORE_MONSTERS, iPlayer, 0)
			get_tr2(0, TR_vecEndPos, vHitPos)
		}

		create_beam(0, vStart, vHitPos, 7, 6)
		engfunc(EngFunc_SetOrigin, iIcicleEnt, vHitPos)

		new iHit = get_tr2(0, TR_pHit)
		if (!is_nullent(iHit))
			icicle_touch(iIcicleEnt, iHit)

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_ICICLE_LAUNCH, 1.0, ATTN_NORM, 0, random_num(100, 110))
		set_entvar(iPlayer, var_punchangle, !random(1) ? {0.0, 0.0, 7.0} : {0.0, 0.0, -7.0})

		new iCloneEnt = check_owner_ice_clone_on_line(iPlayer, vStart, vHitPos)
		if (iCloneEnt)
			icicle_touch(iIcicleEnt, iCloneEnt)
	}
	else
	{
		create_beamfollow(iIcicleEnt)

		engfunc(EngFunc_EmitSound, iIcicleEnt, CHAN_WEAPON, SOUND_ICICLE_LAUNCH, 1.0, ATTN_NORM, 0, PITCH_NORM)
		set_entvar(iPlayer, var_punchangle, !random(1) ? {0.0, 0.0, 3.0} : {0.0, 0.0, -3.0})
	}
	return true
}

create_icicle(Float:vOrigin[3], Float:vDirection[3], iOwner)
{
	new iIcicleEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iIcicleEnt))
		return FM_NULLENT

	new Float:vAngles[3], Float:vVelocity[3]

	vector_to_angle(vDirection, vAngles)
	xs_vec_mul_scalar(vDirection, ICICLE_SPEED, vVelocity)

	engfunc(EngFunc_SetModel, iIcicleEnt, MODEL_ICICLE)
	engfunc(EngFunc_SetOrigin, iIcicleEnt, vOrigin)
	engfunc(EngFunc_SetSize, iIcicleEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})

	set_entvar(iIcicleEnt, var_origin, vOrigin)
	set_entvar(iIcicleEnt, var_angles, vAngles)
	set_entvar(iIcicleEnt, var_velocity, vVelocity)

	set_entvar(iIcicleEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iIcicleEnt, var_movetype, MOVETYPE_FLY)
	set_entvar(iIcicleEnt, var_classname, CLASSNAME_ICICLE)
	set_entvar(iIcicleEnt, var_impulse, IMPULSE_ICILCE)
	set_entvar(iIcicleEnt, var_owner, iOwner)
	set_entvar(iIcicleEnt, var_rendermode, kRenderNormal)
	set_entvar(iIcicleEnt, var_renderfx, kRenderFxGlowShell)
	set_entvar(iIcicleEnt, var_rendercolor, Float:{FROST_COLOR_R.0, FROST_COLOR_G.0, FROST_COLOR_B.0})
	set_entvar(iIcicleEnt, var_renderamt, 40.0)
	set_entvar(iIcicleEnt, var_icicle_spawnorigin, vOrigin)
	set_entvar(iIcicleEnt, var_nextthink, get_gametime())

	SetThink(iIcicleEnt, "icicle_think")
	SetTouch(iIcicleEnt, "icicle_touch")

	return iIcicleEnt
}

stop_icicle(iIcicleEnt)
{
	engfunc(EngFunc_EmitSound, iIcicleEnt, CHAN_STATIC, SOUND_ICICLE_DAMAGE, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_entvar(iIcicleEnt, var_solid, SOLID_NOT)
	set_entvar(iIcicleEnt, var_velocity, NULL_VECTOR)
	set_entvar(iIcicleEnt, var_renderfx, kRenderFxNone)
	set_entvar(iIcicleEnt, var_rendermode, kRenderTransAlpha)
	set_entvar(iIcicleEnt, var_renderamt, 255.0)
}

public efk_ability3(iPlayer)
{
	kc_player_unburn(iPlayer)

	new iItem = get_member(iPlayer, m_pActiveItem)
	if (!is_nullent(iItem) && get_member(iItem, m_iId) == WEAPON_KNIFE && Float:get_member(iItem, m_Weapon_flNextPrimaryAttack) <= 0.0)
		play_unset_buff_anim(iPlayer)

	new bool:bBuffed = Player[iPlayer][FrostBuffTime] > 0.0

	if (bBuffed)
	{
		send_msg_StatusIcon(true, FROST_REFLECTION_ICON, COLOR_FROST_REFLECTION, MSG_ONE, _, iPlayer)
		kc_player_add_glow(iPlayer, FROST_REFLECTION_TIME,
			FROST_REFLECTION_COLOR_R, FROST_REFLECTION_COLOR_G, FROST_REFLECTION_COLOR_B)

		if (kc_player_get_vision(iPlayer) != VISION_BLIND && !kc_player_in_freeze(iPlayer) && !kc_player_in_chill(iPlayer))
			send_msg_ScreenFade((1<<12), (1<<8), (1<<4), COLOR_FROST_REFLECTION, 100, MSG_ONE, _, iPlayer)

		Player[iPlayer][FrostBuffTime] = 0.0
		Player[iPlayer][FrostReflectionTime] = get_gametime() + FROST_REFLECTION_TIME
	}

	new Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	new Float:vVelocity[3]
	get_entvar(iPlayer, var_v_angle, vVelocity)
	angle_vector(vVelocity, ANGLEVECTOR_FORWARD, vVelocity)
	if (!(get_entvar(iPlayer, var_button) & IN_FORWARD))
	{
		vVelocity[0] = -vVelocity[0]
		vVelocity[1] = -vVelocity[1]
	}
	vVelocity[2] = 1.0
	xs_vec_mul_scalar(vVelocity, BACKJUMP_FORCE, vVelocity)

	new iCloneSkeleton = rg_create_entity(SZ_INFO_TARGET)
	if(!iCloneSkeleton)
		return PLUGIN_HANDLED

	engfunc(EngFunc_SetOrigin, iCloneSkeleton, vOrigin)
	engfunc(EngFunc_SetModel, iCloneSkeleton, MODEL_PLAYER_ANIMATIONS)

	set_entvar(iCloneSkeleton, var_origin, vOrigin)
	set_entvar(iCloneSkeleton, var_classname, CLASSNAME_ICE_CLONE)
	set_entvar(iCloneSkeleton, var_impulse, IMPULSE_ICE_CLONE)
	set_entvar(iCloneSkeleton, var_framerate, 0.0)
	set_entvar(iCloneSkeleton, var_gravity, 0.000001)
	set_entvar(iCloneSkeleton, var_movetype, MOVETYPE_FLY)
	set_entvar(iCloneSkeleton, var_solid, SOLID_TRIGGER)
	set_entvar(iCloneSkeleton, var_owner, iPlayer)
	set_entvar(iCloneSkeleton, var_team, get_user_team(iPlayer))
	set_entvar(iCloneSkeleton, var_rendermode, kRenderTransAlpha)
	set_entvar(iCloneSkeleton, var_renderamt, 0.0)
	set_entvar(iCloneSkeleton, var_clone_buffed, bBuffed)

	new iBlend[2], iSeq, iPlayerSeq
	pev(iPlayer, pev_blending, iBlend)
	iPlayerSeq = get_entvar(iPlayer, var_gaitsequence)

	switch (iPlayerSeq)
	{
		case 1: iSeq = 0 // idle
		case 2: iSeq = 2 // crouch_idle
		case 3: iSeq = 4 // walk
		case 4: iSeq = 6 // run
		case 5: iSeq = 8 // crouch_run
		case 6: iSeq = 22 // jump
		case 7: iSeq = 22 // longjump
		default: iSeq = 0
	}

	if (iBlend[0] <= 128)
	{
		iBlend[0] = min(iBlend[0], 127)
		set_pev(iCloneSkeleton, pev_blending_0, iBlend[0] * 2)
	}
	else
	{
		set_pev(iCloneSkeleton, pev_blending_0, (iBlend[0] - 128) * 2)
		iSeq++
	}

	if (iPlayerSeq == 2 || iPlayerSeq == 5)
		engfunc(EngFunc_SetSize, iCloneSkeleton, {-16.0, -16.0, -18.0}, {16.0,  16.0,  32.0})
	else
		engfunc(EngFunc_SetSize, iCloneSkeleton, {-16.0, -16.0, -36.0}, {16.0,  16.0,  36.0})

	set_entvar(iCloneSkeleton, var_sequence, iSeq)
	set_entvar(iCloneSkeleton, var_frame, Float:get_member(iPlayer, m_flGaitframe))

	new Float:vAngles[3]
	vAngles[0] = 0.0
	vAngles[1] = Float:get_member(iPlayer, m_flGaityaw)
	vAngles[2] = 0.0
	set_entvar(iCloneSkeleton, var_angles, vAngles)

	set_entvar(iCloneSkeleton, var_nextthink, get_gametime() + ICE_CLONE_LIFE)

	SetThink(iCloneSkeleton, "ice_clone_think")
	SetTouch(iCloneSkeleton, "ice_clone_touch")

	new iCloneShell = rg_create_entity(SZ_INFO_TARGET)
	if (!iCloneShell)
	{
		rg_remove_entity(iCloneSkeleton)
		return PLUGIN_HANDLED
	}

	set_entvar(iCloneShell, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iCloneShell, var_aiment, iCloneSkeleton)
	set_entvar(iCloneShell, var_classname, CLASSNAME_ICE_CLONE_PART_)
	set_entvar(iCloneShell, var_owner, iPlayer)
	//set_entvar(iCloneShell, var_modelindex, get_entvar(iPlayer, var_modelindex))
	engfunc(EngFunc_SetModel, iCloneShell, fmt("models/player/%s/%s.mdl",
		CUSTOM_PLAYER_MODEL, CUSTOM_PLAYER_MODEL))
	set_entvar(iCloneShell, var_skin, get_entvar(iPlayer, var_skin))
	set_entvar(iCloneShell, var_rendermode, kRenderNormal)
	set_entvar(iCloneShell, var_renderfx, kRenderFxGlowShell)
	set_entvar(iCloneShell, var_rendercolor, Float:{FROST_COLOR_R.0, FROST_COLOR_G.0, FROST_COLOR_B.0})
	set_entvar(iCloneShell, var_renderamt, 16.0)

	set_entvar(iCloneSkeleton, var_iceclone_shell, iCloneShell)

	new iCloneKnife = rg_create_entity(SZ_INFO_TARGET)
	if (!iCloneKnife)
	{
		rg_remove_entity(iCloneSkeleton)
		rg_remove_entity(iCloneShell)
		return PLUGIN_HANDLED
	}

	set_entvar(iCloneKnife, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iCloneKnife, var_aiment, iCloneSkeleton)
	set_entvar(iCloneKnife, var_classname, CLASSNAME_ICE_CLONE_PART_)
	set_entvar(iCloneKnife, var_owner, iPlayer)

	set_entvar(iCloneKnife, var_modelindex, g_pKnifePMdl)

	set_entvar(iCloneKnife, var_rendermode, kRenderNormal)
	set_entvar(iCloneKnife, var_renderfx, kRenderFxGlowShell)
	set_entvar(iCloneKnife, var_rendercolor, Float:{FROST_COLOR_R.0, FROST_COLOR_G.0, FROST_COLOR_B.0})
	set_entvar(iCloneKnife, var_renderamt, 16.0)

	new iHatEnt = kc_player_get_hat_ent(iPlayer)
	if (iHatEnt)
	{
		new iCloneHat = rg_create_entity(SZ_INFO_TARGET)
		if (!iCloneHat)
		{
			rg_remove_entity(iCloneSkeleton)
			rg_remove_entity(iCloneShell)
			rg_remove_entity(iCloneKnife)
			return PLUGIN_HANDLED
		}

		set_entvar(iCloneHat, var_movetype, MOVETYPE_FOLLOW)
		set_entvar(iCloneHat, var_aiment, iCloneSkeleton)
		set_entvar(iCloneHat, var_impulse, IMPULSE_FAKEHAT)
		set_entvar(iCloneHat, var_classname, CLASSNAME_ICE_CLONE_PART_)
		set_entvar(iCloneHat, var_owner, iPlayer)
		set_entvar(iCloneHat, var_modelindex, get_entvar(iHatEnt, var_modelindex))

		new iHatBody = get_entvar(iHatEnt, var_body)

		set_entvar(iCloneHat, var_skin, get_entvar(iHatEnt, var_skin))
		set_entvar(iCloneHat, var_body, iHatBody)

		set_entvar(iCloneHat, var_sequence, iHatBody)
		set_entvar(iCloneHat, var_framerate, 0.0)
		set_entvar(iCloneHat, var_frame, get_entvar(iHatEnt, var_frame))

		set_entvar(iCloneHat, var_rendermode, kRenderNormal)
		set_entvar(iCloneHat, var_renderfx, kRenderFxGlowShell)
		set_entvar(iCloneHat, var_rendercolor, Float:{FROST_COLOR_R.0, FROST_COLOR_G.0, FROST_COLOR_B.0})
		set_entvar(iCloneHat, var_renderamt, 16.0)
	}

	kc_player_unfreeze(iPlayer)
	set_entvar(iPlayer, var_velocity, vVelocity)
	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FROST, 1.0, ATTN_NORM, 0, PITCH_NORM)

	return PLUGIN_CONTINUE
}

calc_freeze_level_by_distance(Float:fDistance, Float:fRadius)
{
	if (fDistance > fRadius)
		return 0

	return fDistance > fRadius * 0.65 ? 1 : 2
}

check_owner_ice_clone_on_line(iPlayer, Float:vStartOrigin[3], Float:vEndOrigin[3])
{
	new iCloneEnt = NULLENT, Float:vCloneMins[3], Float:vCloneMaxs[3],
		iFindedClone, Float:fMinDist = 8192.0

	while ((iCloneEnt = rg_find_ent_by_class(iCloneEnt, CLASSNAME_ICE_CLONE)))
	{
		if (get_entvar(iCloneEnt, var_owner) != iPlayer)
			continue

		get_entvar(iCloneEnt, var_absmin, vCloneMins)
		get_entvar(iCloneEnt, var_absmax, vCloneMaxs)

		if (line_intersects_box(vStartOrigin, vEndOrigin, vCloneMins, vCloneMaxs))
		{
			new Float:vCloneOrigin[3]
			get_entvar(iCloneEnt, var_origin, vCloneOrigin)

			new Float:fCloneDist = get_distance_f(vStartOrigin, vCloneOrigin)
			if (fMinDist > fCloneDist)
			{
				fMinDist = fCloneDist
				iFindedClone = iCloneEnt
			}
		}
	}

	return iFindedClone
}

check_field_part_on_line(iPlayer, Float:vStartOrigin[3], Float:vEndOrigin[3], &Float:fDist)
{
	new iFieldEnt = NULLENT, Float:vFieldMins[3], Float:vFieldMaxs[3],
		iFindedField, Float:fFieldDist, Float:fMinDist = 8192.0,
		iTeam = get_member(iPlayer, m_iTeam)

	while ((iFieldEnt = rg_find_ent_by_class(iFieldEnt, CLASSNAME_FIELD_PART)))
	{
		if (get_entvar(iFieldEnt, var_skin) + 1 == iTeam)
			continue

		get_entvar(iFieldEnt, var_absmin, vFieldMins)
		get_entvar(iFieldEnt, var_absmax, vFieldMaxs)

		if (line_intersects_box(vStartOrigin, vEndOrigin, vFieldMins, vFieldMaxs, fFieldDist))
		{
			if (fMinDist > fFieldDist)
			{
				fMinDist = fFieldDist
				iFindedField = iFieldEnt
			}
		}
	}

	fDist = fMinDist
	return iFindedField
}

play_unset_buff_anim(iPlayer)
{
	kc_player_set_view_anim(iPlayer, VIEW_SEQ_UNSET_BUFF)

	new iItem = get_member(iPlayer, m_pActiveItem)
	if (!is_nullent(iItem))
		set_member(iItem, m_Weapon_flTimeWeaponIdle, 0.625)
}

remove_frost_reflection(iPlayer)
{
	if (Player[iPlayer][FrostReflectionTime] == 0.0)
		return

	send_msg_StatusIcon(false, FROST_REFLECTION_ICON, _, MSG_ONE, _, iPlayer)
	kc_player_sub_glow(iPlayer, FROST_REFLECTION_COLOR_R, FROST_REFLECTION_COLOR_G, FROST_REFLECTION_COLOR_B)

	Player[iPlayer][FrostReflectionTime] = 0.0
}

create_beamfollow(iTarget, iLife=4, iWidth=2, iBrightness=100)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(iTarget)
	write_short(g_pLaserbeamSpr)
	write_byte(iLife)
	write_byte(iWidth)
	write_byte(FROST_COLOR_R)
	write_byte(FROST_COLOR_G)
	write_byte(FROST_COLOR_B)
	write_byte(iBrightness)
	message_end()
}

create_beam(iPlayer, Float:vStart[3], Float:vEnd[3], iLife, iWidth)
{
	message_begin(iPlayer ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_TEMPENTITY, _, iPlayer)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, vStart[0])
	engfunc(EngFunc_WriteCoord, vStart[1])
	engfunc(EngFunc_WriteCoord, vStart[2])
	engfunc(EngFunc_WriteCoord, vEnd[0])
	engfunc(EngFunc_WriteCoord, vEnd[1])
	engfunc(EngFunc_WriteCoord, vEnd[2])
	write_short(g_pLaserbeamSpr)
	write_byte(0)
	write_byte(1)
	write_byte(iLife)
	write_byte(iWidth)
	write_byte(0)
	write_byte(FROST_COLOR_R)
	write_byte(FROST_COLOR_G)
	write_byte(FROST_COLOR_B)
	write_byte(150)
	write_byte(0)
	message_end()
}

create_bloodstream(Float:origin[3], Float:direction[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BLOODSTREAM)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	engfunc(EngFunc_WriteCoord, direction[0])
	engfunc(EngFunc_WriteCoord, direction[1])
	engfunc(EngFunc_WriteCoord, direction[2])
	write_byte(70)
	write_byte(random_num(50, 100))
	message_end()
}

create_directed_bloodstream(iEnt)
{
	new Float:vOrigin[3], Float:vVelocity[3]
	get_entvar(iEnt, var_origin, vOrigin)
	get_entvar(iEnt, var_velocity, vVelocity)

	create_bloodstream(vOrigin, vVelocity)
}
