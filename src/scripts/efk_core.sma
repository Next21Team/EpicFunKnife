#pragma dynamic 32768

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta_util>
#include <engine>
#include <xs>
#include <beams>
#include <nvault>
#include <reapi>
#include <next_client_api>
#include <efk_const>
#include <efk_utils>

new const PLUGIN[] = "EFK Core"

new const GAME_TAG[] = EFK_GAME_TAG

#define DEFAULT_PLAYER_OPTIONS		OPTION_VIEW_MODEL_FX

#define Player[%1][%2]				g_player_data[%1-1][%2]
#define PlayerF[%1][%2]				g_player_data_f[%1-1][%2]
#define PlayerState[%1][%2][%3]		g_player_state[%1-1][%2][%3]
#define PlayerStateF[%1][%2][%3]	g_player_state_f[%1-1][%2][%3]
#define Knife[%1][%2]				g_knife_data[%1][%2]
#define KnifeF[%1][%2]				g_knife_data_f[%1][%2]
#define Item[%1][%2]				g_item_data[%1][%2]
#define MenuItem[%1][%2]			g_menu_item_data[%1][%2]

#define SetPlayerGameFlag(%1,%2)      (Player[%1][PlrGameFlags] |= %2)
#define ClearPlayerGameFlag(%1,%2)    (Player[%1][PlrGameFlags] &= ~%2)
#define CheckPlayerGameFlag(%1,%2)    (Player[%1][PlrGameFlags] & %2)

#define SetKnifeFlag(%1,%2)      (Knife[%1][KNF_FLAGS] |= %2)
#define ClearKnifeFlag(%1,%2)    (Knife[%1][KNF_FLAGS] &= ~%2)
#define CheckKnifeFlag(%1,%2)    (Knife[%1][KNF_FLAGS] & %2)

#define get_weapon_owner(%1)	get_member(%1, m_pPlayer)
#define get_active_weapon(%1)	get_member(%1, m_pActiveItem)
#define is_valid_knife(%1)		(0<=%1&&%1<g_iTotalKnives)

#define LEN_CLASS_NAME				32
#define LEN_CLASS_DESCRIPTION 		32
#define LEN_CLASS_CHATDESCRIPTION 	32
#define LEN_CLASS_MODEL				64
#define LEN_ABILITY_NAME			24
#define LEN_ITEM_DESCRIPTION 		32
#define LEN_ITEM_CHATDESCRIPTION 	32
#define LEN_ITEM_FUNC				32
#define LEN_MENU_ITEM_NAME			32
#define LEN_MENU_ITEM_FUNC			32
#define LEN_DEATH_REASON			32

new const PLAYER_MODEL_PATH[]		= "models/player/%s/%s.mdl"

new const BASE_PLAYER_MODEL[]		= "efk_base_b02"
new const BURN_PLAYER_MODEL[]		= "next21_burndead"

#define DEATH_ANIM_UNHEAD_BODY		7

#define DEATH_ANIM_SLASH_START		112
#define DEATH_ANIM_SLASH_NUM		2
#define DEATH_ANIM_SLASH_BODY		14

#define LOWPOLY_BODY_ADD			21

new const MODEL_PLAYER_HEAD_TE[]	= "models/next21_efk/player_head_te.mdl"
new const MODEL_PLAYER_HEAD_CT[]	= "models/next21_efk/player_head_ct.mdl"

new const SPRITE_AIM_CANNOT[]		= "sprites/next21_knife_v2/chair/n21_hud_cannot.spr"
new const SPRITE_AIM_DEFAULT[]		= "sprites/next21_knife_v2/chair/n21_hud_default.spr"
new const SPRITE_AIM_OK[]			= "sprites/next21_knife_v2/chair/n21_hud_ok.spr"
new const SPRITE_AIM_FAR[]			= "sprites/next21_knife_v2/chair/n21_hud_far.spr"
new const SPRITE_AIM_TIME[]			= "sprites/next21_knife_v2/chair/n21_hud_time.spr"
new const SPRITE_AIM_HELP[]			= "sprites/next21_knife_v2/chair/n21_hud_help.spr"

new const SPRITE_SILENCE[]			= "sprites/next21_efk/silence.spr"
new const SPRITE_FLAME[]			= "sprites/next21_efk/flame.spr"
new const SPRITE_CRIT_FLAME[]		= "sprites/next21_efk/flame_blue.spr"

new const SOUND_FROST_HIT[]			= "next21_efk/frost_hit.wav"
new const SOUND_DUCT2[]				= "player/pl_duct2.wav"
new const SOUND_CRASH_ICEBLOCK[]	= "next21_efk/ice_block_crash.wav"
new const MODEL_ICEBLOCK[]			= "models/next21_efk/ice_block.mdl"

new const _SOUND_GUI_CLICK[]		= SOUND_GUI_CLICK
new const _SOUND_GUI_ERROR[]		= SOUND_GUI_ERROR

new const SOUND_KNIFE_BLOCK[]		= "next21_efk/knife_block.wav"

new const SOUND_SILENCE_OUT[]		= "next21_efk/silence_out_b01.wav"

new const MODEL_ICE_DEATH[]			= "models/next21_efk/ice_death.mdl"
new const MODEL_ACID_DEATH[]		= "models/next21_efk/acid_death.mdl"

new const MODEL_HEALTH_BAR[]		= "sprites/next21_efk/lifebar_def.spr"

new const MODEL_BLIND[]				= "models/next21_efk/blind_eff_a01.mdl"

new const SPRITE_KNIFE_ICON[]		= "sprites/next21_efk/ncl/hud_knife.spr"

new const CAMERA_MODEL[]			= "models/rpgrocket.mdl"

#define CHANCE_BLINDED_MISS			(!random(3))
#define SPAWN_PROTECTION_TIME		2.5
#define PREGAME_TIME				8.0

#define SHADOW_JUMP_DAMAGE_COST		20.0
#define SHADOW_JUMP_DAMAGE			25.0
#define SHADOW_JUMP_RADIUS			150.0
#define SHADOW_REGEN				1.0

#define INVISIBLE_AMT_FRIEND		100
#define INVISIBLE_AMT_INWATER		30

#define MIN_GRAVITY					0.000001
#define MIN_PLAYER_SPEED			0.000001

enum _:LevitationFlags(<<=1)
{
	LEVITATION_ON = 1,
	LEVITATION_UP,
	LEVITATION_FORWARD
}

#define WIND_SLOW_SUB				0.45
#define WIND_GRAVITY_MUL			0.6
#define WIND_GRAVITY_NEG_MUL		1.7

#define WIND_NADE_FORCE				1.5
#define WIND_NADE_DOWNFORCE			0.5

#define BURN_DMG					2
#define BURN_CRIT_DMG				6
#define BURN_CRIT_CHANCE			8

#define FROZEN_DAMAGE				20.0

#define CHILL_SLOW					0.4

#define FIND_SPAWN_ENEMY_RANGE 		700.0

#define BHOP_HORIZONTAL_SPEED		350.0

new const TOPCOLOR_TEAM_VALUES[][]	= {"0", "138"}

#define var_camera_owner			var_iuser1
#define var_camera_mode				var_iuser2
new const CLASSNAME_CAMERA[]		= "efk_player_camera"

#define CAMERA_3RD_DISTANCE			150.0

new const _CLASSNAME_CORPSE[]		= CLASSNAME_CORPSE

#define KILL_ASSIST_KOEF			0.6
#define KILL_ASSIST_REWARD			150
#define HEAL_ASSIST_MIN_HP			1

#define CHECK_STUCK_DELAY			0.3

#define DUEL_SPRITE_DISTANCE		10.0

#define LIFEBAR_FRAMES_NUM			100

#define TASK_DARKNESS				100
#define TASK_SILENCE				200

new const SZ_ENV_SPRITE[]			= "env_sprite"
new const SZ_INFO_TARGET[]			= "info_target"
new const SZ_TRIGGER_CAMERA[]		= "trigger_camera"
new const SZ_FUNC_BUYZONE[]			= "func_buyzone"
new const SZ_BEAM[]					= "beam"
new const SZ_WEAPON_C4[]			= "weapon_c4"
new const SZ_WEAPON_FLASHBANG[]		= "weapon_flashbang"
new const SZ_WEAPON_HEGRENADE[]		= "weapon_hegrenade"
new const SZ_WEAPON_KNIFE[]			= "weapon_knife"
new const SZ_WEAPON_SMOKEGRENADE[]	= "weapon_smokegrenade"

new const ANIM_EXTENSIONS[][] =
{
	"knife",
	"knife2",
	"skullaxe",
	"hammer",
	"knife3",
	"claws",
	"tomahawk",
	"nataknife",
	"nunchaku"
}

new const SOUNDS_SCREAM[][] =
{
	"next21_efk/scream1.wav",
	"next21_efk/scream2.wav",
	"next21_efk/scream3.wav"
}

new const LANG_ITEM_ERRORS[][] =
{
	"",
	"",
	"ITEM_RET_HAVE",
	"ITEM_RET_NOT",
	"ITEM_RET_DEAD",
	"ITEM_RET_ALIVE"
}

new const WEAPONS_NAMES[][] =
{
	"weapon_hegrenade",
	"weapon_c4",
	"weapon_smokegrenade",
	"weapon_flashbang",
	"weapon_knife"
}

new const WEAPON_LIST_DATA[] =
{
	12, 1, -1, -1, 3, 1, 4, 24,		// weapon_hegrenade
	-1, -1, -1, -1, 4, 3, 6, 24,	// weapon_c4
	13, 1, -1, -1, 3, 3, 9, 24,		// weapon_smokegrenade
	11, 2, -1, -1, 3, 2, 25, 24,	// weapon_flashbang
	-1, -1, -1, -1, 2, 1, 29, 0		// weapon_knife
}

new const REMOVE_MAP_CLASSNAMES[][] =
{
	"player_weaponstrip",
	"func_bomb_target",
	"func_escapezone",
	"func_hostage_rescue",
	"func_vip_safetyzone",
	"game_player_equip",
	"game_end",
	"info_bomb_target",
	"info_hostage_rescue",
	"info_vip_start"
}

enum _:PlayerProperties
{
	PlrGameFlags,
	PlrTeam,
	PlrLevel,
	PlrFavKnife,
	PlrKnife,
	KnifeCrosshair:PlrCrosshair,
	VisionType:PlrVision,
	VisibilityType:PlrVisibility,
	PlrClone,
	PlrHatEnt,
	PlrHatModelIndex,
	PlrHatBody,
	PlrHatSkin,
	PlrKinfeModelIndex,
	PlrBurned,
	PlrBurnAttacker,
	PlrLevitation,
	PlrLevitationPt,
	PlrLevitationPressedButton,
	WindBoostType:PlrWindBoostType,
	PlrBlockAttack,
	CaptureType:PlrCaptureType,
	PlrConcentBlock,
	bool:PlrWasBlocked,
	PlrIceblockEnt,
	PlrGlowR[MAX_MIXCOLORS],
	PlrGlowG[MAX_MIXCOLORS],
	PlrGlowB[MAX_MIXCOLORS],
	PlrGlowCount,
	bool:PlrWaterTransparent,
	bool:PlrAbility1Disabled,
	AbilityType:PlrAbility1Type,
	KnifeHitGroup:PlrHitGroupAttacked,
	PlrBlockAirAcFlags,
	PlrCorpseType,
	PlrAttacker,
	PlrDeathReasonText[LEN_DEATH_REASON],
	bool:PlrDeathReasonApplied,
	PlrHpBarEnt,
	PlrBlindEffEnt,
	PlrCameraEnt,
	PlrCameraMode,
	PlrCustomCameraEnt,
	PlrFavCamera,
	PlrModelAnim[3],
	PlrItemValue[MAX_ITEMS],
	PlrItemMode,
	PlrOptionsFlags,
	PlrTopColorTeam,
	PlrSGSGround,
	bool:PlrIsBhopEnabled,
	bool:PlrIsBypassChangeKnfDelay,
	PlrHealthTmp,
	PlrDamageAccept[MAX_PLAYERS + 1],
	PlrDamageAcceptRnd[MAX_PLAYERS + 1],
	bool:PlrBlockUseAbility2
}

enum _:PlayerPropertiesF
{
	Float:PlrMaxDamage,
	Float:PlrMinDamage,
	Float:PlrPowerDamage,
	Float:PlrPowerDamageDelay,
	Float:PlrMaxHP,
	Float:PlrMaxSpeed,
	Float:PlrGravity,
	Float:PlrAbility1Charge,
	Float:PlrAbility2Charge,
	Float:PlrAbility3Charge,
	Float:PlrAbility4Charge,
	Float:PlrAbility1LastChange,
	Float:PlrAbility2LastChange,
	Float:PlrAbility3LastChange,
	Float:PlrAbility4LastChange,
	Float:PlrAbility1MinDist,
	Float:PlrAbility1MaxDist,
	Float:PlrSpawnProtectionTime,
	Float:PlrCritChance,
	Float:PlrKnifeChangeDelay,
	Float:PlrSlowTime[3],
	Float:PlrSlowSpeed[3],
	Float:PlrRushTime,
	Float:PlrRushSpeed,
	Float:PlrFrozen,
	Float:PlrCaptured,
	Float:PlrBlockAirAcTime,
	Float:PlrLevitationDelay[2],
	Float:PlrLevitationRushDelay,
	Float:PlrLevitationAngle,
	Float:PlrChilled,
	Float:PlrSwapTime,
	Float:PlrAttackerTime,
	Float:PlrAssistTime,
	Float:PlrBlindTime,
	Float:PlrGlowTime[MAX_MIXCOLORS],
	Float:PlrInvisionTime,
	Float:PlrInvisionStartTime,
	Float:PlrCloneTimeValue,
	Float:PlrCloneRegenTime,
	Float:PlrScreenFadeTime,
	Float:PlrNightvisionTime,
	Float:PlrPreGameTime,
	Float:PlrModelAnimTime,
	Float:PlrModelAnimFrame,
	Float:PlrModelAnimFPS,
	Float:PlrModelAnimStart,
	Float:PlrCheckStuckTime,
	Float:PlrNextSpawnChargeCheck,
	Float:PlrReflectionEndTime,
	Float:PlrHealedBy[MAX_PLAYERS + 1],
	Float:PlrCaptureAngles[3],
	Float:PlrFixedCaptureAngles[3]
}

enum _:PlayerPropertiesState
{
	StateFlags,
	StateBurned,
	StateBurnAttacker,
	StateGlowR[MAX_MIXCOLORS],
	StateGlowG[MAX_MIXCOLORS],
	StateGlowB[MAX_MIXCOLORS],
	StateGlowCount,
	CaptureType:StateCaptureType,
	WindBoostType:StateWindBoostType
}

enum _:PlayerPropertiesStateF
{
	Float:StateGametime,
	Float:StateOrigin[3],
	Float:StateVelocity[3],
	Float:StateVAngles[3],
	Float:StateHealth,
	Float:StateMaxHP,
	Float:StateMaxSpeed,
	Float:StateAbility1Charge,
	Float:StateAbility2Charge,
	Float:StateAbility3Charge,
	Float:StateAbility4Charge,
	Float:StateSlowTime[3],
	Float:StateSlowSpeed[3],
	Float:StateFrozen,
	Float:StateChilled,
	Float:StateSwapTime,
	Float:StateBlindTime,
	Float:StateGlowTime[MAX_MIXCOLORS],
	Float:StateNextPrimAttack,
	Float:StateNextSecondAttack
}

enum _:KnifeProperties
{
	KNF_NAME[LEN_CLASS_NAME],
	KNF_DESCRIPTION[LEN_CLASS_DESCRIPTION],
	KNF_CHAT_DESCRIPTION[LEN_CLASS_CHATDESCRIPTION],
	KNF_MODEL_V_STRID,
	KNF_MODEL_P_STRID,
	KNF_MODEL_P,
	KNF_ABILITY1_NAME[LEN_ABILITY_NAME],
	AbilityType:KNF_ABILITY1_TYPE,
	KNF_ABILITY1_CALLBACK,
	KNF_ABILITY2_NAME[LEN_ABILITY_NAME],
	KNF_ABILITY2_CALLBACK,
	KNF_ABILITY3_NAME[LEN_ABILITY_NAME],
	KNF_ABILITY3_CALLBACK,
	KNF_ABILITY4_NAME[LEN_ABILITY_NAME],
	KNF_ABILITY4_CALLBACK,
	KNF_ACCESS_LEVEL,
	KNF_FLAGS,
	KNF_ANIM_EXT
}

enum _:KnifePropertiesF
{
	Float:KNF_ABILITY1_MAX_DIST,
	Float:KNF_ABILITY1_MIN_DIST,
	Float:KNF_ABILITY1_CHARGE,
	Float:KNF_ABILITY2_CHARGE,
	Float:KNF_ABILITY3_CHARGE,
	Float:KNF_ABILITY4_CHARGE,
	Float:KNF_MAX_HEALTH,
	Float:KNF_MAX_DAMAGE,
	Float:KNF_MIN_DAMAGE,
	Float:KNF_MAX_SPEED,
	Float:KNF_GRAVITY,
	Float:KNF_CHARGE_BOOST_COEF
}

enum _:ItemProperties
{
	ItmDescription[LEN_ITEM_DESCRIPTION],
	ItmChatDescription[LEN_ITEM_CHATDESCRIPTION],
	ItmCost,
	ItmGiveCallback,
	ItmModeCallback,
	ItmLevel,
	ItmFlags
}

enum _:MenuItemProperties
{
	MItmName[LEN_MENU_ITEM_NAME],
	MItmCallback
}

new
g_player_data[MAX_PLAYERS][PlayerProperties], Float:g_player_data_f[MAX_PLAYERS][PlayerPropertiesF],
g_player_state[MAX_PLAYERS][4][PlayerPropertiesState], Float:g_player_state_f[MAX_PLAYERS][4][PlayerPropertiesStateF],
g_knife_data[MAX_KNIVES][KnifeProperties], Float:g_knife_data_f[MAX_KNIVES][KnifePropertiesF],
g_item_data[MAX_ITEMS][ItemProperties],
g_menu_item_data[MAX_MENUITEMS][MenuItemProperties],

forward_abil_pre, forward_abil_post, forward_core_change_knife_pre, forward_core_change_knife_post,
forward_crosshair_draw_pre,
forward_abil2_pre, forward_abil2_post, forward_abil3_pre, forward_abil3_post, forward_abil4_pre, forward_abil4_post,
forward_charge_draw_pre, forward_player_knife_killed, forward_player_death, forward_player_change_team, forward_status_draw,
forward_invisible, forward_indirect_assist, forward_player_heal,
forward_unblind, forward_unchill, forward_unburn, forward_reburn, forward_uninvisible, forward_unshadow, forward_unclone,
forward_calculate_render_colors, forward_player_reset_render,
forward_freeze, forward_unfreeze,
forward_capture, forward_uncapture, forward_swap, forward_undarkness, forward_update_windboost,
forward_disenergy, forward_preuse_crit,
forward_apply_damage, forward_reflection_start, forward_reflection_stop, forward_reflection,
forward_concentblock_timeout, forward_player_options_update, forward_ability1_toggle,

g_iTotalKnives, g_iTotalItems, g_iTotalMenuItems,
HookChain:g_pSV_WriteFullClientUpdate, g_szDeathString[32], g_iAssistKiller,
HookChain:g_hcCBasePlayer_PainSoundBlock,
g_msgHideWeapon, g_msgStatusText,
g_msgCorpse, g_msgCurWeapon,
bool:g_bIsRoundEnded, g_iDarknessTeam = -1, g_iSilenceTeam = -1,
g_nvSettings,
g_iRegenItemId = -1, g_iChargeBoosterItemId = -1, g_iHPScanItemId = -1,
g_iSkyColors[3], g_pCvarSkyColors[3],

g_iPlayerHeadIndexes[2],

Trie:g_tSoundKnife[MAX_KNIVES],
Trie:g_tFogData,
Trie:g_tInventoryCache,

g_pSilenceSpr, g_pSmokeSpr, g_pFlameSpr, g_pCritFlameSpr, g_pGlassGibsMdl,

g_ptBlockItemCallback,

g_msgWeaponList, Array:g_aOldWeapon, Array:g_aNewWeapon

public plugin_natives()
{
	register_native("kc_register_knife", "_21kc_register_knife")

	register_native("kc_get_knives_num", "_21kc_get_knives_num")
	register_native("kc_knife_get_abil1_name", "_21kc_knife_get_abil1_name")

	register_native("kc_register_ability1", "_21kc_register_ability1")
	register_native("kc_register_ability2", "_21kc_register_ability2")
	register_native("kc_register_ability3", "_21kc_register_ability3")
	register_native("kc_register_ability4", "_21kc_register_ability4")

	register_native("kc_knife_set_anim_ext", "_21kc_knife_set_anim_ext")
	register_native("kc_knife_set_level", "_21kc_knife_set_level")
	register_native("kc_knife_set_sound", "_21kc_knife_set_sound")

	register_native("kc_register_weapon_hud", "_21kc_register_weapon_hud")
	register_native("kc_player_set_weapon_hud", "_21kc_player_set_weapon_hud")

	register_native("kc_knife_set_charge_boost_coeff", "_21kc_knife_set_charge_boost_coeff")

	register_native("kc_player_set_game_flag", "_21kc_player_set_game_flag")
	register_native("kc_player_unset_game_flag", "_21kc_player_unset_game_flag")
	register_native("kc_player_check_game_flag", "_21kc_player_check_game_flag")

	register_native("kc_knife_set_flags", "_21kc_knife_set_flags")

	register_native("kc_player_get_bunnyhop", "_21kc_player_get_bunnyhop")
	register_native("kc_player_set_bunnyhop", "_21kc_player_set_bunnyhop")

	register_native("kc_player_in_protection", "_21kc_player_in_protection")
	register_native("kc_player_unprotection", "_21kc_player_unprotection")

	register_native("kc_player_give_knife", "_21kc_player_give_knife")
	register_native("kc_player_check_knife_access", "_21kc_player_check_knife_access")

	register_native("kc_register_item", "_21kc_register_item")

	register_native("kc_player_set_crosshair", "_21kc_player_set_crosshair")

	register_native("kc_player_get_powerdamage", "_21kc_player_get_powerdamage")
	register_native("kc_player_set_powerdamage", "_21kc_player_set_powerdamage")

	register_native("kc_player_set_abil1_type", "_21kc_player_set_abil1_type")

	register_native("kc_player_get_vision", "_21kc_player_get_vision")

	register_native("kc_register_menu_item", "_21kc_register_menu_item")
	register_native("kc_item_register_enable_handler", "_21kc_item_register_enable_handler")

	register_native("kc_player_give_item", "_21kc_player_give_item")
	register_native("kc_player_give_random_item", "_21kc_player_give_random_item")

	register_native("kc_player_get_item_value", "_21kc_player_get_item_value")
	register_native("kc_player_set_item_value", "_21kc_player_set_item_value")

	register_native("kc_player_item_get_enabled", "_21kc_player_item_get_enabled")
	register_native("kc_player_item_set_enabled", "_21kc_player_item_set_enabled")

	register_native("kc_player_get_knife", "_21kc_player_get_knife")
	register_native("kc_knife_get_classname", "_21kc_knife_get_classname")

	register_native("kc_player_get_maxspeed", "_21kc_player_get_maxspeed")
	register_native("kc_player_set_maxspeed", "_21kc_player_set_maxspeed")

	register_native("kc_player_get_maxhealth", "_21kc_player_get_maxhealth")

	register_native("kc_player_can_ability", "_21kc_player_can_ability")

	register_native("kc_player_is_abil1_ready", "_21kc_player_is_abil1_ready")
	register_native("kc_player_get_abil1_charge", "_21kc_player_get_abil1_charge")
	register_native("kc_player_set_abil1_charge", "_21kc_player_set_abil1_charge")
	register_native("kc_player_set_abil1_dist", "_21kc_player_set_abil1_dist")

	register_native("kc_player_get_abil2_charge", "_21kc_player_get_abil2_charge")
	register_native("kc_player_set_abil2_charge", "_21kc_player_set_abil2_charge")

	register_native("kc_player_get_abil3_charge", "_21kc_player_get_abil3_charge")
	register_native("kc_player_set_abil3_charge", "_21kc_player_set_abil3_charge")

	register_native("kc_player_get_abil4_charge", "_21kc_player_get_abil4_charge")
	register_native("kc_player_set_abil4_charge", "_21kc_player_set_abil4_charge")

	register_native("kc_player_set_crit_chance", "_21kc_player_set_crit_chance")
	register_native("kc_player_get_visibility", "_21kc_player_get_visibility")
	register_native("kc_player_reset_visibility", "_21kc_player_reset_visibility")

	register_native("kc_player_set_level", "_21kc_player_set_level")
	register_native("kc_player_get_level", "_21kc_player_get_level")

	register_native("kc_player_set_favknife", "_21kc_player_set_favknife")

	register_native("kc_player_blind", "_21kc_player_blind")
	register_native("kc_player_unblind", "_21kc_player_unblind")

	register_native("kc_player_add_glow", "_21kc_player_add_glow")
	register_native("kc_player_sub_glow", "_21kc_player_sub_glow")

	register_native("kc_player_invision", "_21kc_player_invision")
	register_native("kc_player_uninvision", "_21kc_player_uninvision")
	register_native("kc_invision_unfake", "_21kc_invision_unfake")

	register_native("kc_player_shadow", "_21kc_player_shadow")
	register_native("kc_player_get_shadow_target", "_21kc_player_get_shadow_target")
	register_native("kc_player_get_shadow_activator", "_21kc_player_get_shadow_activator")
	register_native("kc_player_unshadow", "_21kc_player_unshadow")

	register_native("kc_player_clone", "_21kc_player_clone")
	register_native("kc_player_unclone", "_21kc_player_unclone")

	register_native("kc_darkness", "_21kc_darkness")
	register_native("kc_player_in_darkness", "_21kc_player_in_darkness")

	register_native("kc_silence", "_21kc_silence")
	register_native("kc_player_in_silence", "_21kc_player_in_silence")

	register_native("kc_player_slow", "_21kc_player_slow")
	register_native("kc_player_rush", "_21kc_player_rush")

	register_native("kc_player_get_windboost", "_21kc_player_get_windboost")
	register_native("kc_player_set_windboost", "_21kc_player_set_windboost")

	register_native("kc_player_reflection_start", "_21kc_player_reflection_start")
	register_native("kc_player_in_reflection", "_21kc_player_in_reflection")
	register_native("kc_player_reflection_stop", "_21kc_player_reflection_stop")
	register_native("kc_player_reflection_done", "_21kc_player_reflection_done")

	register_native("kc_player_heal", "_21kc_player_heal")

	register_native("kc_player_get_bair", "_21kc_player_get_bair")
	register_native("kc_player_set_bair", "_21kc_player_set_bair")

	register_native("kc_player_burn", "_21kc_player_burn")
	register_native("kc_player_in_burn", "_21kc_player_in_burn")
	register_native("kc_player_unburn", "_21kc_player_unburn")

	register_native("kc_player_freeze", "_21kc_player_freeze")
	register_native("kc_player_in_freeze", "_21kc_player_in_freeze")
	register_native("kc_player_unfreeze", "_21kc_player_unfreeze")
	register_native("kc_player_chill", "_21kc_player_chill")
	register_native("kc_player_in_chill", "_21kc_player_in_chill")
	register_native("kc_player_unchill", "_21kc_player_unchill")

	register_native("kc_player_set_capture", "_21kc_player_set_capture")
	register_native("kc_player_get_capture", "_21kc_player_get_capture")

	register_native("kc_player_disenergy", "_21kc_player_disenergy")

	register_native("kc_player_levitation", "_21kc_player_levitation")
	register_native("kc_player_unlevitation", "_21kc_player_unlevitation")

	register_native("kc_player_in_debuffed", "_21kc_player_in_debuffed")

	register_native("kc_player_swap", "_21kc_player_swap")
	register_native("kc_player_get_swap", "_21kc_player_get_swap")

	register_native("kc_player_set_water_transparent", "_21kc_player_set_water_transparent")

	register_native("kc_player_apply_concentblock", "_21kc_player_apply_concentblock")
	register_native("kc_player_get_concentblock", "_21kc_player_get_concentblock")
	register_native("kc_player_set_concentblock", "_21kc_player_set_concentblock")

	register_native("kc_player_reburn", "_21kc_player_reburn")

	register_native("kc_player_get_reburn_timestate", "_21kc_player_get_reburn_timestate")

	register_native("kc_player_set_override_attacker", "_21kc_player_set_override_attacker")

	register_native("kc_player_try_crit", "_21kc_player_try_crit")

	register_native("kc_player_set_death_reason", "_21kc_player_set_death_reason")

	register_native("kc_player_is_influenced", "_21kc_player_is_influenced")

	register_native("kc_player_set_anim", "_21kc_player_set_anim")
	register_native("kc_player_set_view_anim", "_21kc_player_set_view_anim")

	register_native("kc_player_set_hat", "_21kc_player_set_hat")
	register_native("kc_player_get_hat_ent", "_21kc_player_get_hat_ent")

	register_native("kc_player_get_camera", "_21kc_player_get_camera")
	register_native("kc_player_set_camera", "_21kc_player_set_camera")

	register_native("kc_player_check_stuck_delayed", "_21kc_player_check_stuck_delayed")

	register_native("kc_player_get_options", "_21kc_player_get_options")
	register_native("kc_player_get_caused_damage", "_21kc_player_get_caused_damage")
}

public plugin_cfg()
{
	g_nvSettings = nvault_open("next21_efk_settings")

	if (g_nvSettings == INVALID_HANDLE)
		set_fail_state("[%s] error opening settings nVault!", PLUGIN)

	nvault_prune(g_nvSettings, 0, get_systime() - (86400 * 30))
}

public plugin_precache()
{
	precache_generic("sprites/weapon_next21_cross_cnot.txt")
	precache_generic("sprites/weapon_next21_cross_def.txt")
	precache_generic("sprites/weapon_next21_cross_far.txt")
	precache_generic("sprites/weapon_next21_cross_ok.txt")
	precache_generic("sprites/weapon_next21_cross_time.txt")
	precache_generic("sprites/weapon_next21_cross_help.txt")

	precache_generic(SPRITE_AIM_CANNOT)
	precache_generic(SPRITE_AIM_DEFAULT)
	precache_generic(SPRITE_AIM_FAR)
	precache_generic(SPRITE_AIM_OK)
	precache_generic(SPRITE_AIM_TIME)
	precache_generic(SPRITE_AIM_HELP)

	precache_generic("sprites/next21_knife_v2/hud/hud_items_0[2].spr")
	precache_generic("sprites/next21_knife_v2/hud/hud_knives_0.spr")
	precache_generic("sprites/next21_knife_v2/hud/hud_knives_1.spr")
	precache_generic("sprites/next21_knife_v2/hud/hud_knives_2.spr")
	precache_generic("sprites/next21_knife_v2/hud/hud_knives_2s.spr")
	precache_generic("sprites/next21_knife_v2/hud/hud_knives_3.spr")
	precache_generic("sprites/next21_knife_v2/hud/hud_knives_3u2.spr")
	precache_generic("sprites/next21_efk/hud_nades_.spr")

	new i, szModel[128]
	format(szModel, charsmax(szModel), PLAYER_MODEL_PATH, CUSTOM_PLAYER_MODEL, CUSTOM_PLAYER_MODEL)
	precache_model(szModel)
	force_unmodified(force_exactfile, {0, 0, 0}, {0, 0, 0}, szModel)

	format(szModel, charsmax(szModel), PLAYER_MODEL_PATH, BASE_PLAYER_MODEL, BASE_PLAYER_MODEL)
	precache_model(szModel)
	force_unmodified(force_exactfile, {0, 0, 0}, {0, 0, 0}, szModel)

	format(szModel, charsmax(szModel), PLAYER_MODEL_PATH, BURN_PLAYER_MODEL, BURN_PLAYER_MODEL)
	precache_model(szModel)

	g_iPlayerHeadIndexes[0] = precache_model(MODEL_PLAYER_HEAD_TE)
	g_iPlayerHeadIndexes[1] = precache_model(MODEL_PLAYER_HEAD_CT)

	precache_model(MODEL_PLAYER_ANIMATIONS)

	precache_model(MODEL_ACID_DEATH)
	precache_model(MODEL_ICE_DEATH)

	precache_sound(SOUND_FROST_HIT)
	precache_sound(SOUND_DUCT2)
	precache_sound(SOUND_CRASH_ICEBLOCK)
	precache_model(MODEL_ICEBLOCK)

	precache_sound(SOUND_KNIFE_BLOCK)

	precache_sound(_SOUND_GUI_CLICK)
	precache_sound(_SOUND_GUI_ERROR)

	precache_sound(SOUND_TORNADO_FLAME)

	precache_sound(SOUND_SILENCE_OUT)

	for (i = 0; i < sizeof SOUNDS_SCREAM; i++)
		precache_sound(SOUNDS_SCREAM[i])

	g_pSilenceSpr = precache_model(SPRITE_SILENCE)
	g_pSmokeSpr = precache_model("sprites/black_smoke3.spr")
	g_pFlameSpr = precache_model(SPRITE_FLAME)
	g_pCritFlameSpr = precache_model(SPRITE_CRIT_FLAME)
	g_pGlassGibsMdl = precache_model("models/glassgibs.mdl")

	precache_model(MODEL_HEALTH_BAR)

	precache_model(MODEL_BLIND)

	precache_model(CAMERA_MODEL)

	precache_generic(SPRITE_KNIFE_ICON)

	g_aOldWeapon = ArrayCreate(64)
	g_aNewWeapon = ArrayCreate(64)

	new iFakeBuyZone = rg_create_entity(SZ_FUNC_BUYZONE, true)
	engfunc(EngFunc_SetSize, iFakeBuyZone, Float:{-8192.0, -8192.0, -8192.0}, Float:{-8192.0, -8192.0, -8192.0})
	set_entvar(iFakeBuyZone, var_iuser2, 7777)
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	register_dictionary("next21_efk.txt")

	g_tInventoryCache = TrieCreate()

	forward_abil_pre = CreateMultiForward("efk_ability_pre", ET_STOP, FP_CELL, FP_CELL)
	forward_abil_post = CreateMultiForward("efk_ability_post", ET_IGNORE, FP_CELL, FP_CELL)
	forward_core_change_knife_pre = CreateMultiForward("efk_change_knife_core_pre", ET_STOP, FP_CELL, FP_CELL)
	forward_core_change_knife_post = CreateMultiForward("efk_change_knife_core_post", ET_IGNORE, FP_CELL, FP_CELL)
	forward_abil2_pre = CreateMultiForward("efk_ability2_pre", ET_STOP, FP_CELL)
	forward_abil2_post = CreateMultiForward("efk_ability2_post", ET_IGNORE, FP_CELL)
	forward_abil3_pre = CreateMultiForward("efk_ability3_pre", ET_STOP, FP_CELL)
	forward_abil3_post = CreateMultiForward("efk_ability3_post", ET_IGNORE, FP_CELL)
	forward_abil4_pre = CreateMultiForward("efk_ability4_pre", ET_STOP, FP_CELL)
	forward_abil4_post = CreateMultiForward("efk_ability4_post", ET_IGNORE, FP_CELL)
	forward_crosshair_draw_pre = CreateMultiForward("efk_crosshair_draw_pre", ET_STOP, FP_CELL, FP_CELL, FP_VAL_BYREF, FP_CELL)
	forward_charge_draw_pre = CreateMultiForward("efk_charge_draw_pre", ET_STOP, FP_CELL, FP_CELL, FP_CELL)
	forward_status_draw = CreateMultiForward("efk_status_draw", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	forward_player_knife_killed = CreateMultiForward("efk_player_knife_killed", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	forward_player_death = CreateMultiForward("efk_player_death", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	forward_player_heal = CreateMultiForward("efk_player_heal", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	forward_player_change_team = CreateMultiForward("efk_player_change_team", ET_IGNORE, FP_CELL, FP_CELL)
	forward_indirect_assist = CreateMultiForward("efk_indirect_assist", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	forward_unblind = CreateMultiForward("efk_unblind", ET_IGNORE, FP_CELL, FP_CELL)
	forward_invisible = CreateMultiForward("efk_invisible", ET_IGNORE, FP_CELL)
	forward_uninvisible = CreateMultiForward("efk_uninvisible", ET_IGNORE, FP_CELL)
	forward_unshadow = CreateMultiForward("efk_unshadow", ET_IGNORE, FP_CELL)
	forward_disenergy = CreateMultiForward("efk_disenergy", ET_IGNORE, FP_CELL)
	forward_unclone = CreateMultiForward("efk_unclone", ET_IGNORE, FP_CELL)
	forward_unchill = CreateMultiForward("efk_unchill", ET_IGNORE, FP_CELL)
	forward_unburn = CreateMultiForward("efk_unburn", ET_IGNORE, FP_CELL)
	forward_reburn = CreateMultiForward("efk_reburn", ET_IGNORE, FP_CELL)
	forward_calculate_render_colors = CreateMultiForward("efk_calculate_render_colors", ET_IGNORE, FP_CELL)
	forward_player_reset_render = CreateMultiForward("efk_reset_player_render", ET_IGNORE, FP_CELL)
	forward_capture = CreateMultiForward("efk_capture", ET_IGNORE, FP_CELL, FP_CELL)
	forward_uncapture = CreateMultiForward("efk_uncapture", ET_IGNORE, FP_CELL)
	forward_freeze = CreateMultiForward("efk_freeze", ET_IGNORE, FP_CELL)
	forward_unfreeze = CreateMultiForward("efk_unfreeze", ET_IGNORE, FP_CELL)
	forward_swap = CreateMultiForward("efk_swap", ET_IGNORE, FP_CELL, FP_CELL)
	forward_undarkness = CreateMultiForward("efk_undarkness", ET_IGNORE)
	forward_update_windboost = CreateMultiForward("efk_update_windboost", ET_IGNORE, FP_CELL, FP_CELL)
	forward_preuse_crit = CreateMultiForward("efk_preuse_crit", ET_STOP, FP_CELL, FP_CELL)
	forward_apply_damage = CreateMultiForward("efk_apply_damage", ET_IGNORE, FP_CELL, FP_CELL, FP_VAL_BYREF, FP_VAL_BYREF, FP_VAL_BYREF)
	forward_reflection = CreateMultiForward("efk_reflection", ET_IGNORE, FP_CELL, FP_CELL)
	forward_reflection_start = CreateMultiForward("efk_reflection_start", ET_IGNORE, FP_CELL)
	forward_reflection_stop = CreateMultiForward("efk_reflection_end", ET_IGNORE, FP_CELL, FP_CELL)
	forward_concentblock_timeout = CreateMultiForward("efk_concentblock_timeout", ET_IGNORE, FP_CELL)
	forward_player_options_update = CreateMultiForward("efk_player_options_update", ET_IGNORE, FP_CELL, FP_CELL)
	forward_ability1_toggle = CreateMultiForward("efk_ability_toggle", ET_STOP, FP_CELL)

	register_clcmd("efk_menu", "clcmd_show_main_menu")
	register_clcmd("chooseteam", "clcmd_show_main_menu")
	register_clcmd("nightvision", "clcmd_show_shop_menu")

	register_clcmd("radio1", "clcmd_show_knives_menu")
	register_clcmd("radio2", "clcmd_show_shop_menu")

	register_clcmd("say /knife", "clcmd_show_knives_menu")
	register_clcmd("say_team /knife", "clcmd_show_knives_menu")

	register_clcmd("say knife", "clcmd_show_knives_menu")
	register_clcmd("say_team knife", "clcmd_show_knives_menu")

	register_clcmd("say /knifes", "clcmd_show_knives_menu")
	register_clcmd("say_team /knifes", "clcmd_show_knives_menu")

	register_clcmd("say knifes", "clcmd_show_knives_menu")
	register_clcmd("say_team knifes", "clcmd_show_knives_menu")

	register_clcmd("say /menu", "clcmd_show_main_menu")
	register_clcmd("say_team /menu", "clcmd_show_knives_menu")

	register_clcmd("say menu", "clcmd_show_main_menu")
	register_clcmd("say_team menu", "clcmd_show_main_menu")

	register_clcmd("say /shop", "clcmd_show_shop_menu")
	register_clcmd("say_team /shop", "clcmd_show_shop_menu")

	register_clcmd("say shop", "clcmd_show_shop_menu")
	register_clcmd("say_team shop", "clcmd_show_shop_menu")

	register_clcmd("say shopmenu", "clcmd_show_shop_menu")
	register_clcmd("say_team shopmenu", "clcmd_show_shop_menu")

	register_clcmd("say /shopmenu", "clcmd_show_shop_menu")
	register_clcmd("say_team /shopmenu", "clcmd_show_shop_menu")

	register_clcmd("say /cam", "clcmd_show_camera_menu")
	register_clcmd("say_team /cam", "clcmd_show_camera_menu")
	register_clcmd("say /camera", "clcmd_show_camera_menu")
	register_clcmd("say_team /camera", "clcmd_show_camera_menu")
	register_clcmd("radio3", "quick_camera_change")

	register_clcmd("toggle_knf_change_delay", "clcmd_toggle_knf_change_delay")
	AddMenuItem("Toggle knife change delay", "toggle_knf_change_delay", ADMIN_FLAG, PLUGIN)

	RegisterHookChain(RG_CSGameRules_RestartRound, "RG_CSGameRules_RestartRound_Pre")
	RegisterHookChain(RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_CBasePlayer_Spawn_Post", true)
	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Pre")
	RegisterHookChain(RG_CBasePlayer_PostThink, "RG_CBasePlayer_PostThink_Post", true)
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_Damage")
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_PostDamage", true)
	RegisterHam(Ham_TakeDamage, "env_explosion", "fw_EnvExposion_Damage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Pre")
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_CBasePlayer_Killed_Post", true)
	RegisterHam(Ham_Weapon_WeaponIdle, SZ_WEAPON_KNIFE, "fw_KnifeIdle")
	RegisterHam(Ham_Weapon_PrimaryAttack, SZ_WEAPON_KNIFE, "fw_PrimaryAttack", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, SZ_WEAPON_KNIFE, "fw_PreSecondaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, SZ_WEAPON_KNIFE, "fw_PrePrimaryAttack")
	RegisterHam(Ham_Weapon_SecondaryAttack, SZ_WEAPON_KNIFE, "fw_SecondaryAttack", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, SZ_WEAPON_HEGRENADE, "fw_Nade_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, SZ_WEAPON_FLASHBANG, "fw_Nade_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, SZ_WEAPON_SMOKEGRENADE, "fw_Nade_PrimaryAttack")
	RegisterHam(Ham_Item_Deploy, SZ_WEAPON_KNIFE, "fw_KnifeDeploy", 1)
	RegisterHam(Ham_Item_PreFrame, "player", "fw_Item_PreFrame", 1)
	RegisterHam(Ham_Touch, "player", "fw_PlayerTouch")
	RegisterHookChain(RG_CBasePlayer_Duck, "RG_CBasePlayer_Duck_Pre")
	RegisterHookChain(RG_CBasePlayer_Jump, "RG_CBasePlayer_Jump_Pre")
	RegisterHookChain(RG_CBaseAnimating_ResetSequenceInfo, "RG_ResetSequenceInfo_Pre")
	RegisterHookChain(RG_CBasePlayer_SetAnimation, "RG_CBasePlayer_SetAnimation_Pre")
	RegisterHookChain(RG_PM_AirMove, "RG_PM_AirMove_Pre")
	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "RG_CBasePlayer_ThrowGrenade_Post", true)
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "RG_CBasePlayer_GiveDefaultItems_Pre")
	RegisterHookChain(RG_CBasePlayer_Observer_FindNextPlayer, "RG_CBasePlayer_Observer_FindNextPlayer_Post", true)

	DisableHookChain((g_hcCBasePlayer_PainSoundBlock = RegisterHookChain(RG_CBasePlayer_Pain, "RG_CBasePlayer_Pain_Pre")))
	DisableHookChain((g_pSV_WriteFullClientUpdate = RegisterHookChain(RH_SV_WriteFullClientUpdate, "RH_SV_WriteFullClientUpdate_Pre")))

	register_impulse(100, "fw_PlayerFlashlight")
	register_impulse(201, "fw_PlayerSpray")

	RegisterHam(Ham_GiveAmmo, "player", "Ham_Player_GiveAmmo_Pre")
	RegisterHam(Ham_Use, "func_vehicle", "Ham_Vehicle_Use_Pre")
	RegisterHam(Ham_Spawn, "weapon_c4", "Ham_C4_Spawn_Pre")

	register_clcmd("drop", "clcmd_show_items_menu")

	register_logevent("logevent_StartRound", 2, "1=Round_Start")
	register_logevent("logevent_RoundEnd", 2, "1=Round_End")
	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")
	register_event("Health", "event_Health", "be")

	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_GetGameDescription, "fw_GameDesc")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack", true)
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", true)
	register_forward(FM_EmitSound, "fw_EmitSound")

	g_msgHideWeapon = get_user_msgid("HideWeapon")
	g_msgWeaponList = get_user_msgid("WeaponList")
	g_msgStatusText = get_user_msgid("StatusText")
	g_msgCorpse = get_user_msgid("ClCorpse")
	g_msgCurWeapon = get_user_msgid("CurWeapon")
	g_ptBlockItemCallback = menu_makecallback("callback_block_item")

	g_pCvarSkyColors[0] = get_cvar_pointer("sv_skycolor_r")
	g_pCvarSkyColors[1] = get_cvar_pointer("sv_skycolor_g")
	g_pCvarSkyColors[2] = get_cvar_pointer("sv_skycolor_b")

	register_message(get_user_msgid("TeamInfo"), "Message_TeamInfo")
	register_message(g_msgStatusText, "Message_StatusText")
	register_message(get_user_msgid("StatusValue"), "Message_StatusValue")
	register_message(g_msgCorpse, "Message_ClCorpse")
	register_message(get_user_msgid("HealthInfo"), "Message_HealthInfo")
	register_message(get_user_msgid("Radar"), "Message_Radar")

	set_task(2.0, "register_client_switches")

	register_hud(SZ_WEAPON_C4, "weapon_next21_cross_cnot")
	register_hud(SZ_WEAPON_C4, "weapon_next21_cross_def")
	register_hud(SZ_WEAPON_C4, "weapon_next21_cross_far")
	register_hud(SZ_WEAPON_C4, "weapon_next21_cross_ok")
	register_hud(SZ_WEAPON_C4, "weapon_next21_cross_time")
	register_hud(SZ_WEAPON_C4, "weapon_next21_cross_help")

	remove_map_entities()

	set_cvar_num("mp_flashlight", 0)
}

public plugin_end()
{
	nvault_close(g_nvSettings)
}

public pfn_keyvalue(iEnt)
{
	new szClassname[24], szKey[24], szValue[24]
	copy_keyvalue(szClassname, charsmax(szClassname),
		szKey, charsmax(szKey), szValue, charsmax(szValue))

	if (equal(szClassname, "env_fog"))
	{
		if (!g_tFogData)
			g_tFogData = TrieCreate()

		if (equal(szKey, "classname"))
			return

		TrieSetString(g_tFogData, szKey, szValue)
	}

	// Reduce extreme health on some maps
	if (equal(szClassname, "trigger_hurt") && equal(szKey, "dmg") && str_to_num(szValue) < -10)
		DispatchKeyValue("dmg", "-10")
}

public client_putinserver(iPlayer)
{
	SetPlayerGameFlag(iPlayer, PLGF_IS_ONLINE);
	Player[iPlayer][PlrKnife] = -1
	Player[iPlayer][PlrFavKnife] = -1

	Player[iPlayer][PlrCameraMode] = CAMERA_MODE_1ST
	Player[iPlayer][PlrFavCamera] = CAMERA_MODE_3RD

	arrayset(Player[iPlayer][PlrItemValue], -1, MAX_ITEMS)
	Player[iPlayer][PlrItemMode] = 0

	Player[iPlayer][PlrTopColorTeam] = -1

	create_hat_entity(iPlayer)
	create_lifebar_entity(iPlayer)

	if (CheckPlayerGameFlag(iPlayer, PLGF_IS_AUTHORIZED))
		load_authorized_client_data(iPlayer)
}

public client_authorized(iPlayer)
{
	SetPlayerGameFlag(iPlayer, PLGF_IS_AUTHORIZED);

	if (is_user_connected(iPlayer))
		load_authorized_client_data(iPlayer)
}

load_authorized_client_data(iPlayer)
{
	new szAuthId[24]
	get_user_authid(iPlayer, szAuthId, charsmax(szAuthId))

	new iOptionsFlags = DEFAULT_PLAYER_OPTIONS

	new szValue[32]
	nvault_get(g_nvSettings, szAuthId, szValue, charsmax(szValue))
	if (szValue[0])
	{
		nvault_touch(g_nvSettings, szAuthId)
		iOptionsFlags = str_to_num(szValue)
	}

	Player[iPlayer][PlrOptionsFlags] = iOptionsFlags
	ExecuteForward(forward_player_options_update, _, iPlayer, iOptionsFlags)

	load_inventory_from_cache(iPlayer)
}

public client_disconnected(iPlayer)
{
	save_inventory_to_cache(iPlayer)

	Player[iPlayer][PlrGameFlags] = 0

	if (!is_user_connected(iPlayer))
		return

	Player[iPlayer][PlrTeam] = 0
	Player[iPlayer][PlrCrosshair] = CROSSHAIR_DISABLED
	player_reset_visibility(iPlayer)
	Player[iPlayer][PlrVision] = VISION_NORMAL
	Player[iPlayer][PlrCorpseType] = CORP_NORMAL

	Player[iPlayer][PlrBurned] = 0
	player_unfreeze(iPlayer)
	PlayerF[iPlayer][PlrChilled] = 0.0
	player_uncapture(iPlayer)
	player_reflection_stop(iPlayer)
	player_set_windboost(iPlayer, WINDBOOST_NONE, false)

	PlayerF[iPlayer][PlrPreGameTime] = 0.0
	PlayerF[iPlayer][PlrKnifeChangeDelay] = 0.0
	Player[iPlayer][PlrAttacker] = 0

	Player[iPlayer][PlrIsBhopEnabled] = false

	Player[iPlayer][PlrLevel] = 0

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrClone] == iPlayer)
		{
			switch (Player[i][PlrVisibility])
			{
				case VIS_CLONE: player_remove_clone(i, true)
				case VIS_SHADOW: player_remove_shadow(i)
			}
		}

		if (Player[i][PlrBurnAttacker] == iPlayer)
			Player[i][PlrBurnAttacker] = 0

		if (Player[i][PlrAttacker] == iPlayer)
			Player[i][PlrAttacker] = 0

		Player[i][PlrDamageAccept][iPlayer] = 0
		Player[iPlayer][PlrDamageAccept][i] = 0
		Player[i][PlrDamageAcceptRnd][iPlayer] = 0
		Player[iPlayer][PlrDamageAcceptRnd][i] = 0
	}

	if (Player[iPlayer][PlrHatEnt])
	{
		set_entvar(Player[iPlayer][PlrHatEnt], var_flags, FL_KILLME)
		Player[iPlayer][PlrHatEnt] = 0
	}
	Player[iPlayer][PlrHatBody] = 0
	Player[iPlayer][PlrHatSkin] = 0

	if (Player[iPlayer][PlrHpBarEnt])
	{
		rg_remove_entity(Player[iPlayer][PlrHpBarEnt])
		Player[iPlayer][PlrHpBarEnt] = 0
	}

	new iBeamEnt = NULLENT
	while ((iBeamEnt = rg_find_ent_by_class(iBeamEnt, SZ_BEAM)))
		if (get_entvar(iBeamEnt, var_aiment) == iPlayer)
			set_entvar(iBeamEnt, var_flags, FL_KILLME)

	remove_blind_effect(iPlayer)
	player_set_camera(iPlayer, CAMERA_MODE_1ST, false)
}

public RG_CSGameRules_RestartRound_Pre()
{
	if (task_exists(TASK_DARKNESS))
	{
		remove_task(TASK_DARKNESS)
		task_darkness(TASK_DARKNESS)
	}

	if (task_exists(TASK_SILENCE))
	{
		remove_task(TASK_SILENCE)
		task_silence(TASK_SILENCE)
	}

	if (get_member_game(m_bCompleteReset))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			arrayset(Player[i][PlrItemValue], -1, MAX_ITEMS)
			Player[i][PlrIsBhopEnabled] = false
		}

		TrieClear(g_tInventoryCache)
	}

	g_bIsRoundEnded = false
}

public RG_CSGameRules_CleanUpMap_Post()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, _CLASSNAME_CORPSE)))
		rg_remove_entity(iEnt)
}

public RG_CBasePlayer_Spawn_Post(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return HC_CONTINUE

	new iTeam = get_member(iPlayer, m_iTeam)
	if (Player[iPlayer][PlrTeam] != iTeam)
	{
		Player[iPlayer][PlrTeam] = iTeam
		ExecuteForward(forward_player_change_team, _, iPlayer, iTeam)
	}

	SetPlayerGameFlag(iPlayer, PLGF_IS_ALIVE);

	new iKnifeId = Player[iPlayer][PlrKnife]
	if (!is_valid_knife(iKnifeId))
	{
		if (Player[iPlayer][PlrLevel] > 1)
			iKnifeId = Player[iPlayer][PlrFavKnife]

		if (iKnifeId == -1 || !check_knife_access(iPlayer, iKnifeId))
			iKnifeId = choose_random_knife(iPlayer)

		set_knife_params(iPlayer, iKnifeId)
		ExecuteForward(forward_core_change_knife_post, _, iPlayer, iKnifeId)

		if (!is_user_bot(iPlayer))
			show_knives_menu(iPlayer)
	}

	player_deploy_knife(iPlayer)

	rg_reset_user_model(iPlayer)
	rg_set_user_model(iPlayer, CUSTOM_PLAYER_MODEL, true)
	set_member(iPlayer, m_modelIndexPlayer,
		engfunc(EngFunc_ModelIndex, fmt(PLAYER_MODEL_PATH, BASE_PLAYER_MODEL, BASE_PLAYER_MODEL)))

	set_entvar(iPlayer, var_skin, Player[iPlayer][PlrTeam] - 1)
	set_entvar(iPlayer, var_body, 0)

	player_reset_visibility(iPlayer)
	player_reset_vision(iPlayer)

	new iHatEnt = Player[iPlayer][PlrHatEnt]
	if (!is_nullent(iHatEnt))
	{
		set_entvar(iHatEnt, var_effects, 0)
		if (Player[iPlayer][PlrHatModelIndex])
		{
			set_entvar(iHatEnt, var_renderamt, 0.0)
			set_entvar(iHatEnt, var_rendermode, kRenderNormal)
			set_entvar(iHatEnt, var_renderfx, kRenderFxNone)
		}
	}

	set_task(0.1, "set_params_after_apawn", iPlayer)

	Player[iPlayer][PlrAbility1Disabled] = false

	PlayerF[iPlayer][PlrAbility1Charge] = 100.0 - KnifeF[iKnifeId][KNF_ABILITY1_CHARGE] * RESET_ABIL_AFTER_SPAWN
	PlayerF[iPlayer][PlrAbility2Charge] = 0.0
	PlayerF[iPlayer][PlrAbility3Charge] = 0.0
	PlayerF[iPlayer][PlrAbility4Charge] = 0.0

	new Float:fGameTime = get_gametime()
	PlayerF[iPlayer][PlrAbility1LastChange] = fGameTime
	PlayerF[iPlayer][PlrAbility2LastChange] = fGameTime
	PlayerF[iPlayer][PlrAbility3LastChange] = fGameTime
	PlayerF[iPlayer][PlrAbility4LastChange] = fGameTime;

	ClearPlayerGameFlag(iPlayer, PLGF_IN_LOCK_POWER_DAMAGE);
	PlayerF[iPlayer][PlrPowerDamage] = 0.0
	Player[iPlayer][PlrDeathReasonText][0] = EOS
	Player[iPlayer][PlrDeathReasonApplied] = false

	PlayerF[iPlayer][PlrSlowTime][0] = 0.0
	PlayerF[iPlayer][PlrSlowTime][1] = 0.0
	PlayerF[iPlayer][PlrSlowTime][2] = 0.0
	PlayerF[iPlayer][PlrRushTime] = 0.0
	PlayerF[iPlayer][PlrBlockAirAcTime] = 0.0
	Player[iPlayer][PlrBlockAirAcFlags] = 0

	Player[iPlayer][PlrConcentBlock] = 0
	player_set_windboost(iPlayer, WINDBOOST_NONE, false)

	PlayerF[iPlayer][PlrMaxSpeed] = KnifeF[iKnifeId][KNF_MAX_SPEED]
	engfunc(EngFunc_SetClientMaxspeed, iPlayer, PlayerF[iPlayer][PlrMaxSpeed])

	PlayerF[iPlayer][PlrGravity] = KnifeF[iKnifeId][KNF_GRAVITY]
	set_entvar(iPlayer, var_gravity, PlayerF[iPlayer][PlrGravity])

	Player[iPlayer][PlrAttacker] = 0

	arrayset(PlayerF[iPlayer][PlrHealedBy], 0.0, MAX_PLAYERS + 1)

	Player[iPlayer][PlrHitGroupAttacked] = KHITGROUP_GENERIC

	PlayerF[iPlayer][PlrCheckStuckTime] = 0.0
	Player[iPlayer][PlrCorpseType] = CORP_NORMAL

	player_unburn(iPlayer)
	player_unfreeze(iPlayer)
	player_unchill(iPlayer)
	player_unlevitation(iPlayer)
	player_uncapture(iPlayer)

	ClearPlayerGameFlag(iPlayer, PLGF_IN_FIXED_ANIMATION);
	ClearPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_CHARGE);
	ClearPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY);

	new i = NULLENT
	while ((i = rg_find_ent_by_class(i, SZ_BEAM)))
		if (get_entvar(i, var_aiment) == iPlayer)
			set_entvar(i, var_flags, FL_KILLME)

	PlayerF[iPlayer][PlrSwapTime] = 0.0

	if (Player[iPlayer][PlrTeam] == 1)
		player_add_glow(iPlayer, SPAWN_PROTECTION_TIME, 255, 0, 0)
	else
		player_add_glow(iPlayer, SPAWN_PROTECTION_TIME, 0, 0, 255)

	PlayerF[iPlayer][PlrSpawnProtectionTime] = fGameTime + SPAWN_PROTECTION_TIME;
	SetPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY);

	PlayerF[iPlayer][PlrPreGameTime] = fGameTime + PREGAME_TIME

	for (i = 1; i <= MaxClients; i++)
		Player[i][PlrDamageAccept][iPlayer] = 0

	new iLifeBarEnt = Player[iPlayer][PlrHpBarEnt]
	if (iLifeBarEnt)
	{
		set_entvar(iLifeBarEnt, var_effects, 0)
		set_entvar(iLifeBarEnt, var_frame, float(LIFEBAR_FRAMES_NUM - 1))
	}

	player_set_camera(iPlayer, Player[iPlayer][PlrCameraMode])
	Player[iPlayer][PlrCustomCameraEnt] = 0

	set_entvar(iPlayer, var_health, KnifeF[iKnifeId][KNF_MAX_HEALTH])
	set_entvar(iPlayer, var_max_health, KnifeF[iKnifeId][KNF_MAX_HEALTH])

	set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) & ~PLAYER_PREVENT_CLIMB)

	player_set_topcolor_team(iPlayer, Player[iPlayer][PlrTeam] == 2 ? 1 : 0)

	return HC_CONTINUE
}

public RG_CBasePlayer_PreThink_Pre(iPlayer)
{
	static iSubject, i, j

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
	{
		iSubject = get_entvar(iPlayer, var_iuser2)
		if (!is_entity_player(iSubject) || !CheckPlayerGameFlag(iSubject, PLGF_IS_ALIVE))
			return HC_CONTINUE

	}
	else iSubject = iPlayer

	new Float:fGameTime = get_gametime()
	static Float:fHudUpdate[MAX_PLAYERS + 1],
		Float:fStatusUpdate[MAX_PLAYERS + 1],
		Float:fOldCharge[MAX_PLAYERS + 1],
		Float:fRegenUpdate[MAX_PLAYERS + 1],
		Float:fRegenRemainder[MAX_PLAYERS + 1]
	static iKnifeId; iKnifeId = Player[iPlayer][PlrKnife]
	static iTeam; iTeam = Player[iPlayer][PlrTeam]
	static VisionType:iVision; iVision = Player[iPlayer][PlrVision]
	static Float:vOrigin[3]

	if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
	{
		Player_BhopThink(iPlayer)
		spawn_abil1_charge_check(iPlayer)

		if (PlayerF[iPlayer][PlrAbility1Charge] < 100.0
			&& fGameTime - PlayerF[iPlayer][PlrAbility1LastChange] >= 1.0
			&& Knife[iKnifeId][KNF_ABILITY1_NAME][0] != EOS)
		{
			if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_CHARGE))
				PlayerF[iPlayer][PlrAbility1Charge] = floatmin(100.0, PlayerF[iPlayer][PlrAbility1Charge] + KnifeF[iKnifeId][KNF_ABILITY1_CHARGE])
			PlayerF[iPlayer][PlrAbility1LastChange] = fGameTime
		}

		if (PlayerF[iPlayer][PlrAbility2Charge] < 100.0
			&& fGameTime - PlayerF[iPlayer][PlrAbility2LastChange] >= 1.0
			&& Knife[iKnifeId][KNF_ABILITY2_NAME][0] != EOS)
		{
			if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_CHARGE))
				PlayerF[iPlayer][PlrAbility2Charge] = floatmin(100.0, PlayerF[iPlayer][PlrAbility2Charge] + KnifeF[iKnifeId][KNF_ABILITY2_CHARGE])
			PlayerF[iPlayer][PlrAbility2LastChange] = fGameTime
		}

		if (PlayerF[iPlayer][PlrAbility3Charge] < 100.0
			&& fGameTime - PlayerF[iPlayer][PlrAbility3LastChange] >= 1.0
			&& Knife[iKnifeId][KNF_ABILITY3_NAME][0] != EOS)
		{
			if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_CHARGE))
				PlayerF[iPlayer][PlrAbility3Charge] = floatmin(100.0, PlayerF[iPlayer][PlrAbility3Charge] + KnifeF[iKnifeId][KNF_ABILITY3_CHARGE])
			PlayerF[iPlayer][PlrAbility3LastChange] = fGameTime
		}

		if (PlayerF[iPlayer][PlrAbility4Charge] < 100.0
			&& fGameTime - PlayerF[iPlayer][PlrAbility4LastChange] >= 1.0
			&& Knife[iKnifeId][KNF_ABILITY4_NAME][0] != EOS)
		{
			if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_CHARGE))
				PlayerF[iPlayer][PlrAbility4Charge] = floatmin(100.0, PlayerF[iPlayer][PlrAbility4Charge] + KnifeF[iKnifeId][KNF_ABILITY4_CHARGE])
			PlayerF[iPlayer][PlrAbility4LastChange] = fGameTime
		}

		if (PlayerF[iPlayer][PlrAttackerTime] <= fGameTime)
			Player[iPlayer][PlrAttacker] = 0

		for (i = 0; i < 3; i++)
		{
			if (PlayerF[iPlayer][PlrSlowTime][i] > 0.0 && PlayerF[iPlayer][PlrSlowTime][i] <= fGameTime)
			{
				PlayerF[iPlayer][PlrSlowTime][i] = 0.0
				if (PlayerF[iPlayer][PlrFrozen] == 0.0 && Player[iPlayer][PlrCaptureType] == CAPTURE_NONE)
					player_update_maxspeed(iPlayer)
			}
		}

		if (PlayerF[iPlayer][PlrSpawnProtectionTime] > 0.0 && PlayerF[iPlayer][PlrSpawnProtectionTime] <= fGameTime)
		{
			player_unprotection(iPlayer)
		}

		if (PlayerF[iPlayer][PlrPreGameTime] > 0.0 && PlayerF[iPlayer][PlrPreGameTime] <= fGameTime)
		{
			PlayerF[iPlayer][PlrPreGameTime] = 0.0
		}

		if (PlayerF[iPlayer][PlrRushTime] > 0.0 && PlayerF[iPlayer][PlrRushTime] <= fGameTime)
		{
			new Float:fKnifeMaxSpeed = player_get_knife_maxspeed(iPlayer)
			engfunc(EngFunc_SetClientMaxspeed, iPlayer, fKnifeMaxSpeed)
			PlayerF[iPlayer][PlrMaxSpeed] = fKnifeMaxSpeed
			PlayerF[iPlayer][PlrRushTime] = 0.0
		}

		if(PlayerF[iPlayer][PlrReflectionEndTime] != 0.0 && !player_in_reflection(iPlayer))
			player_reflection_stop(iPlayer)

		if (iVision == VISION_BLIND)
		{
			if (PlayerF[iPlayer][PlrBlindTime] <= fGameTime)
				screenfades_out(iPlayer, false)
			else if (PlayerF[iPlayer][PlrScreenFadeTime] <= fGameTime)
			{
				send_msg_ScreenFade((1<<12), (1<<8), (1<<2), {255, 255, 255}, 255, MSG_ONE, _, iPlayer)
			}
		}
		else if (g_iDarknessTeam > -1 && PlayerF[iPlayer][PlrNightvisionTime] <= fGameTime)
		{
			get_entvar(Player[iPlayer][PlrCustomCameraEnt] <= MaxClients ? iPlayer : Player[iPlayer][PlrCustomCameraEnt], var_origin, vOrigin)

			if (iVision == VISION_NIGHT)
			{
				send_msg_TE_DLIGHT(vOrigin, 100, {0, 180, 255}, 2, 0, MSG_ONE, _, iPlayer)
				PlayerF[iPlayer][PlrNightvisionTime] = fGameTime + 0.1
			}
			else if (iVision == VISION_FULL)
			{
				send_msg_TE_DLIGHT(vOrigin, 100, {180, 180, 180}, 2, 0, MSG_ONE, _, iPlayer)
				PlayerF[iPlayer][PlrNightvisionTime] = fGameTime + 0.1
			}
		}

		switch (Player[iPlayer][PlrVisibility])
		{
			case VIS_TRANS:
			{
				if (PlayerF[iPlayer][PlrInvisionTime] <= fGameTime)
					player_remove_trans(iPlayer)
			}
			case VIS_INVISION:
			{
				if (PlayerF[iPlayer][PlrInvisionTime] <= fGameTime)
					player_remove_invision(iPlayer)
			}
			case VIS_GLOW:
			{
				for (i = 0; i < Player[iPlayer][PlrGlowCount]; i++)
				{
					if (PlayerF[iPlayer][PlrGlowTime][i] <= fGameTime)
					{
						for (j = i; j < Player[iPlayer][PlrGlowCount] - 1; j++)
						{
							Player[iPlayer][PlrGlowR][j] = Player[iPlayer][PlrGlowR][j + 1]
							Player[iPlayer][PlrGlowG][j] = Player[iPlayer][PlrGlowG][j + 1]
							Player[iPlayer][PlrGlowB][j] = Player[iPlayer][PlrGlowB][j + 1]
							PlayerF[iPlayer][PlrGlowTime][j] = PlayerF[iPlayer][PlrGlowTime][j + 1]
						}

						Player[iPlayer][PlrGlowCount]--

						if (!Player[iPlayer][PlrGlowCount])
							player_reset_render(iPlayer)
						else
							player_calculate_render_colors(iPlayer)
					}
				}
			}
			case VIS_SHADOW:
			{
				if (!is_nullent(Player[iPlayer][PlrClone]))
				{
					static Float:fHealth, iClone, bool:bClonePlayer

					fHealth = Float:get_entvar(iPlayer, var_health)
					iClone = Player[iPlayer][PlrClone]
					get_entvar(iClone, var_origin, vOrigin)
					bClonePlayer = is_entity_player(iClone)

					if (!bClonePlayer)
						vOrigin[2] += 45.0

					if (PlayerF[iPlayer][PlrCloneRegenTime] <= fGameTime)
					{
						if (bClonePlayer)
							player_heal(iClone, SHADOW_REGEN, iPlayer, true)

						player_heal(iPlayer, SHADOW_REGEN, iPlayer, true)

						PlayerF[iPlayer][PlrCloneRegenTime] += 0.5
					}

					engfunc(EngFunc_SetOrigin, iPlayer, vOrigin)
					set_entvar(iPlayer, var_origin, vOrigin)
					set_entvar(iPlayer, var_velocity, NULL_VECTOR)

					static Float:fBlockFlood[MAX_PLAYERS + 1]
					if (fBlockFlood[iPlayer] < fGameTime)
					{
						if ((bClonePlayer && Player[iClone][PlrCaptureType] == CAPTURE_NORMAL)
							|| (g_iSilenceTeam != -1 && g_iSilenceTeam != iTeam))
						{
							if (PlayerF[iPlayer][PlrCloneTimeValue] > 0.0)
							{
								message_begin(MSG_ONE_UNRELIABLE, 108, {0,0,0}, iPlayer)
								write_short(0)
								message_end()

								fBlockFlood[iPlayer] = fGameTime + 0.75
								PlayerF[iPlayer][PlrCloneTimeValue] = 0.0
							}
						}
						else
						{
							if (get_entvar(iPlayer, var_button) & IN_ATTACK)
							{
								if (PlayerF[iPlayer][PlrCloneTimeValue] == 0.0)
								{
									message_begin(MSG_ONE_UNRELIABLE, 108, {0,0,0}, iPlayer)
									write_short(1)
									message_end()

									PlayerF[iPlayer][PlrCloneTimeValue] = fGameTime
								}

								if (fGameTime - PlayerF[iPlayer][PlrCloneTimeValue] >= 1.0
									|| fHealth - 1.0 <= (fGameTime - PlayerF[iPlayer][PlrCloneTimeValue]) * SHADOW_JUMP_DAMAGE_COST)
								{
									message_begin(MSG_ONE_UNRELIABLE, 108, {0, 0, 0}, iPlayer)
									write_short(0)
									message_end()

									if (!player_remove_shadow(iPlayer, true, true))
									{
										fBlockFlood[iPlayer] = fGameTime + 0.75
										PlayerF[iPlayer][PlrCloneTimeValue] = 0.0
									}
								}
							}
							else if (PlayerF[iPlayer][PlrCloneTimeValue] > 0.0)
							{
								message_begin(MSG_ONE_UNRELIABLE, 108, {0,0,0}, iPlayer)
								write_short(0)
								message_end()

								if (!player_remove_shadow(iPlayer, true, true))
								{
									fBlockFlood[iPlayer] = fGameTime + 0.75
									PlayerF[iPlayer][PlrCloneTimeValue] = 0.0
								}
							}
						}
					}
				}
				else
				{
					player_remove_shadow(iPlayer, true)
				}
			}
		}

		if (!CheckPlayerGameFlag(iPlayer, PLGF_IN_LOCK_POWER_DAMAGE) && PlayerF[iPlayer][PlrPowerDamage] != 0.0 && PlayerF[iPlayer][PlrPowerDamageDelay] <= fGameTime)
		{
			new Float:fPowerDamage = PlayerF[iPlayer][PlrPowerDamage]
			new Float:fAddPowerDamage = fPowerDamage > 0.0 ? -1.0 : 1.0
			if (get_entvar(iPlayer, var_waterlevel) >= 2)
				fAddPowerDamage *= 3.0

			if (PlayerF[iPlayer][PlrFrozen] > 0.0 || PlayerF[iPlayer][PlrChilled] > 0.0 || Player[iPlayer][PlrBurned])
				fAddPowerDamage *= 3.0

			new Float:fNewPowerDamage = fPowerDamage + fAddPowerDamage
			if (fNewPowerDamage * fPowerDamage < 0.0)
				fNewPowerDamage = 0.0

			PlayerF[iPlayer][PlrPowerDamage] = fNewPowerDamage
			PlayerF[iPlayer][PlrPowerDamageDelay] += 0.5
		}

		if (PlayerF[iPlayer][PlrModelAnimTime] > fGameTime)
		{
			PlayerF[iPlayer][PlrModelAnimFrame] = (fGameTime - PlayerF[iPlayer][PlrModelAnimStart]) * PlayerF[iPlayer][PlrModelAnimFPS]
			Player[iPlayer][PlrModelAnim][0] = (get_entvar(iPlayer, var_flags) & FL_DUCKING)
				? Player[iPlayer][PlrModelAnim][2] : Player[iPlayer][PlrModelAnim][1]
		}
		else
			PlayerF[iPlayer][PlrModelAnimTime] = 0.0

		if (Player[iPlayer][PlrBurned])
		{
			if (!Player[iPlayer][PlrBurnAttacker] || (get_entvar(iPlayer, var_flags) & FL_INWATER))
			{
				player_unburn(iPlayer)
			}
			else
			{
				static Float:fBurnDelay[MAX_PLAYERS + 1]
				if (fBurnDelay[iPlayer] <= fGameTime)
				{
					fBurnDelay[iPlayer] = fGameTime + 0.2

					new iBurnAttacker = Player[iPlayer][PlrBurnAttacker]
					new bool:bBurnCrit = random_num(0, 100) <= BURN_CRIT_CHANCE
					new iBurnDamage = (bBurnCrit ? BURN_CRIT_DMG : BURN_DMG)

					new Float:fVelocityModifier = get_member(iPlayer, m_flVelocityModifier)

					EnableHookChain(g_hcCBasePlayer_PainSoundBlock)
					set_member(iPlayer, m_LastHitGroup, HIT_GENERIC)
					ExecuteHamB(Ham_TakeDamage, iPlayer, 0, iBurnAttacker, float(iBurnDamage), DMG_BURN)
					DisableHookChain(g_hcCBasePlayer_PainSoundBlock)

					if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
					{
						set_member(iPlayer, m_flVelocityModifier, fVelocityModifier)

						static Float:fScreamDelay[MAX_PLAYERS + 1]
						if (fScreamDelay[iPlayer] <= fGameTime && Player[iPlayer][PlrVisibility] != VIS_INVISION)
						{
							fScreamDelay[iPlayer] = fGameTime + 1.5
							engfunc(EngFunc_EmitSound, iPlayer, CHAN_VOICE, SOUNDS_SCREAM[random(sizeof SOUNDS_SCREAM)], 1.0, ATTN_NORM, 0, PITCH_NORM)
						}

						if (Player[iPlayer][PlrVisibility] != VIS_INVISION)
						{
							get_entvar(iPlayer, var_origin, vOrigin)

							engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0)
							write_byte(TE_SPRITE)
							engfunc(EngFunc_WriteCoord, vOrigin[0] + random_float(-5.0, 5.0))
							engfunc(EngFunc_WriteCoord, vOrigin[1] + random_float(-5.0, 5.0))
							engfunc(EngFunc_WriteCoord, vOrigin[2] + random_float(-10.0, 10.0))
							if (bBurnCrit)
							{
								write_short(g_pCritFlameSpr)
								write_byte(30)
							}
							else
							{
								write_short(g_pFlameSpr)
								write_byte(random_num(5, 10))
							}
							write_byte(200)
							message_end()
						}

						if (Player[iPlayer][PlrBurned] > 1)
							Player[iPlayer][PlrBurned]--
						else
							player_unburn(iPlayer)
					}
				}
			}
		}
		else if (PlayerF[iPlayer][PlrFrozen] > 0.0)
		{
			if (PlayerF[iPlayer][PlrFrozen] > fGameTime)
			{
				if (Player[iPlayer][PlrIceblockEnt])
				{
					get_entvar(iPlayer, var_origin, vOrigin)

					if (!(get_entvar(iPlayer, var_flags) & FL_DUCKING))
						vOrigin[2] -= 18.0

					vOrigin[2] -= 18.0
					engfunc(EngFunc_SetOrigin, Player[iPlayer][PlrIceblockEnt], vOrigin)
					set_entvar(Player[iPlayer][PlrIceblockEnt], var_origin, vOrigin)
				}
			}
			else
				player_unfreeze(iPlayer)
		}
		else if (PlayerF[iPlayer][PlrChilled] > 0.0)
		{
			if (PlayerF[iPlayer][PlrChilled] <= fGameTime)
				player_unchill(iPlayer)
		}

		if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
		{
			if (PlayerF[iPlayer][PlrCaptured] <= fGameTime || get_entvar(iPlayer, var_waterlevel) >= 2)
				player_uncapture(iPlayer)
		}

		if (0.0 < PlayerF[iPlayer][PlrBlockAirAcTime] < fGameTime
			|| (PlayerF[iPlayer][PlrBlockAirAcTime] - fGameTime < 0.9
				&& (get_entvar(iPlayer, var_flags) & FL_ONGROUND)))
		{
			PlayerF[iPlayer][PlrBlockAirAcTime] = 0.0
			Player[iPlayer][PlrBlockAirAcFlags] = 0
			set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) & ~PLAYER_PREVENT_CLIMB)
		}

		if (Player[iPlayer][PlrLevitation])
		{
			if ((get_entvar(iPlayer, var_flags) & FL_ONGROUND) || get_entvar(iPlayer, var_waterlevel) >= 2)
			{
				player_unlevitation(iPlayer)
			}
			else if (PlayerF[iPlayer][PlrLevitationDelay][1] <= fGameTime)
			{
				if (PlayerF[iPlayer][PlrLevitationDelay][1] > 0.0)
				{
					PlayerF[iPlayer][PlrLevitationDelay][1] = 0.0
					PlayerF[iPlayer][PlrLevitationRushDelay] = fGameTime + 0.75
				}

				static Float:fPressDelay[MAX_PLAYERS + 1]
				if (fPressDelay[iPlayer] <= fGameTime)
					Player[iPlayer][PlrLevitationPressedButton] = 0

				static iButton, iOldButtons, iLevitationDir
				iButton = get_entvar(iPlayer, var_button)
				iOldButtons = get_entvar(iPlayer, var_oldbuttons)
				iLevitationDir = 0

				if (PlayerF[iPlayer][PlrLevitationRushDelay] <= fGameTime)
				{
					if ((iButton & IN_FORWARD))
					{
						if (!(iOldButtons & IN_FORWARD) && (Player[iPlayer][PlrLevitationPressedButton] & IN_FORWARD))
						{
							static Float:vAngles[3]
							get_entvar(iPlayer, var_v_angle, vAngles)

							if (!(Player[iPlayer][PlrLevitation] & LEVITATION_FORWARD))
							{
								PlayerF[iPlayer][PlrLevitationAngle] = vAngles[1] > 180.0 ? vAngles[1] - 180.0 : vAngles[1] + 180.0
								iLevitationDir = LEVITATION_FORWARD
							}
							else
								iLevitationDir = validate_levitation_dir(vAngles[1], PlayerF[iPlayer][PlrLevitationAngle])
						}

						fPressDelay[iPlayer] = fGameTime + 0.2
						Player[iPlayer][PlrLevitationPressedButton] = iButton
					}
					else if ((iButton & IN_BACK))
					{
						if (!(iOldButtons & IN_BACK) && (Player[iPlayer][PlrLevitationPressedButton] & IN_BACK))
						{
							static Float:vAngles[3]
							get_entvar(iPlayer, var_v_angle, vAngles)

							if (!(Player[iPlayer][PlrLevitation] & LEVITATION_FORWARD))
							{
								PlayerF[iPlayer][PlrLevitationAngle] = vAngles[1]
								iLevitationDir = LEVITATION_FORWARD
							}
							else
								iLevitationDir = validate_levitation_dir(vAngles[1] > 180.0 ? vAngles[1] - 180.0 : vAngles[1] + 180.0, PlayerF[iPlayer][PlrLevitationAngle])
						}

						fPressDelay[iPlayer] = fGameTime + 0.2
						Player[iPlayer][PlrLevitationPressedButton] = iButton
					}
					else if ((iButton & IN_MOVELEFT))
					{
						if (!(iOldButtons & IN_MOVELEFT) && (Player[iPlayer][PlrLevitationPressedButton] & IN_MOVELEFT))
						{
							static Float:vAngles[3]
							get_entvar(iPlayer, var_v_angle, vAngles)

							if (!(Player[iPlayer][PlrLevitation] & LEVITATION_FORWARD))
							{
								PlayerF[iPlayer][PlrLevitationAngle] = vAngles[1] >= 90.0 ? vAngles[1] - 90.0 : vAngles[1] + 270.0
								iLevitationDir = LEVITATION_FORWARD
							}
							else
								iLevitationDir = validate_levitation_dir(vAngles[1] < 270.0 ? vAngles[1] + 90.0 : vAngles[1] - 270.0, PlayerF[iPlayer][PlrLevitationAngle])
						}

						fPressDelay[iPlayer] = fGameTime + 0.2
						Player[iPlayer][PlrLevitationPressedButton] = iButton
					}
					else if ((iButton & IN_MOVERIGHT))
					{
						if (!(iOldButtons & IN_MOVERIGHT) && (Player[iPlayer][PlrLevitationPressedButton] & IN_MOVERIGHT))
						{
							static Float:vAngles[3]
							get_entvar(iPlayer, var_v_angle, vAngles)

							if (!(Player[iPlayer][PlrLevitation] & LEVITATION_FORWARD))
							{
								PlayerF[iPlayer][PlrLevitationAngle] = vAngles[1] < 270.0 ? vAngles[1] + 90.0 : vAngles[1] - 270.0
								iLevitationDir = LEVITATION_FORWARD
							}
							else
								iLevitationDir = validate_levitation_dir(vAngles[1] >= 90.0 ? vAngles[1] - 90.0 : vAngles[1] + 270.0, PlayerF[iPlayer][PlrLevitationAngle])
						}

						fPressDelay[iPlayer] = fGameTime + 0.2
						Player[iPlayer][PlrLevitationPressedButton] = iButton
					}
				}

				if (iLevitationDir == LEVITATION_FORWARD)
				{
					new Float:vVector[3]
					vVector[0] = floatcos(PlayerF[iPlayer][PlrLevitationAngle], degrees)
					vVector[1] = floatsin(PlayerF[iPlayer][PlrLevitationAngle], degrees)
					vVector[2] = 0.0
					xs_vec_mul_scalar(vVector, Player[iPlayer][PlrLevitation] & LEVITATION_FORWARD ? 2000.0 : -2000.0, vVector)
					set_entvar(iPlayer, var_velocity, vVector)

					if (Player[iPlayer][PlrLevitation] & LEVITATION_FORWARD)
						Player[iPlayer][PlrLevitation] &= ~LEVITATION_FORWARD
					else
						Player[iPlayer][PlrLevitation] |= LEVITATION_FORWARD

					PlayerF[iPlayer][PlrLevitationDelay][1] = fGameTime + 0.1
				}
				else if (PlayerF[iPlayer][PlrLevitationDelay][0] <= fGameTime)
				{
					if (Player[iPlayer][PlrLevitation] & LEVITATION_UP)
					{
						set_entvar(iPlayer, var_velocity, Float:{0.0, 0.0, 30.0})
						Player[iPlayer][PlrLevitationPt]++
					}
					else
					{
						set_entvar(iPlayer, var_velocity, Float:{0.0, 0.0, -30.0})
						Player[iPlayer][PlrLevitationPt]--
					}

					if (Player[iPlayer][PlrLevitationPt] >= 20)
						Player[iPlayer][PlrLevitation] &= ~LEVITATION_UP
					else if (Player[iPlayer][PlrLevitationPt] <= 0)
						Player[iPlayer][PlrLevitation] |= LEVITATION_UP

					PlayerF[iPlayer][PlrLevitationDelay][0] += 0.1
				}
			}
		}

		if (PlayerF[iPlayer][PlrCheckStuckTime] > 0.0 && PlayerF[iPlayer][PlrCheckStuckTime] <= fGameTime)
		{
			player_check_stuck(iPlayer)
			PlayerF[iPlayer][PlrCheckStuckTime] = 0.0
		}

		static Float:fStateUpdateTime[MAX_PLAYERS + 1]
		if (fStateUpdateTime[iPlayer] <= fGameTime)
		{
			g_player_state[iPlayer - 1][3] = g_player_state[iPlayer - 1][2]
			g_player_state[iPlayer - 1][2] = g_player_state[iPlayer - 1][1]
			g_player_state[iPlayer - 1][1] = g_player_state[iPlayer - 1][0]
			g_player_state_f[iPlayer - 1][3] = g_player_state_f[iPlayer - 1][2]
			g_player_state_f[iPlayer - 1][2] = g_player_state_f[iPlayer - 1][1]
			g_player_state_f[iPlayer - 1][1] = g_player_state_f[iPlayer - 1][0];

			PlayerState[iPlayer][0][StateFlags] = get_entvar(iPlayer, var_flags)
			get_entvar(iPlayer, var_origin, PlayerStateF[iPlayer][0][StateOrigin])
			get_entvar(iPlayer, var_velocity, PlayerStateF[iPlayer][0][StateVelocity])
			get_entvar(iPlayer, var_v_angle, PlayerStateF[iPlayer][0][StateVAngles])
			PlayerStateF[iPlayer][0][StateHealth] = get_entvar(iPlayer, var_health)

			PlayerState[iPlayer][0][StateCaptureType] = Player[iPlayer][PlrCaptureType]
			PlayerState[iPlayer][0][StateWindBoostType] = Player[iPlayer][PlrWindBoostType]

			new iWeapon = get_active_weapon(iPlayer)
			if (!is_nullent(iWeapon) && get_member(iWeapon, m_iId) == CSW_KNIFE)
			{
				PlayerStateF[iPlayer][0][StateNextPrimAttack] = Float:get_member(iWeapon, m_Weapon_flNextPrimaryAttack)
				PlayerStateF[iPlayer][0][StateNextSecondAttack] = Float:get_member(iWeapon, m_Weapon_flNextSecondaryAttack)
			}

			PlayerStateF[iPlayer][0][StateGametime] = fGameTime
			PlayerState[iPlayer][0][StateBurned] = Player[iPlayer][PlrBurned]
			PlayerState[iPlayer][0][StateBurnAttacker] = Player[iPlayer][PlrBurnAttacker]
			PlayerState[iPlayer][0][StateGlowCount] = Player[iPlayer][PlrGlowCount]

			PlayerStateF[iPlayer][0][StateMaxHP] = PlayerF[iPlayer][PlrMaxHP]
			PlayerStateF[iPlayer][0][StateMaxSpeed] = PlayerF[iPlayer][PlrMaxSpeed]
			PlayerStateF[iPlayer][0][StateAbility1Charge] = PlayerF[iPlayer][PlrAbility1Charge]
			PlayerStateF[iPlayer][0][StateAbility2Charge] = PlayerF[iPlayer][PlrAbility2Charge]
			PlayerStateF[iPlayer][0][StateAbility3Charge] = PlayerF[iPlayer][PlrAbility3Charge]
			PlayerStateF[iPlayer][0][StateAbility4Charge] = PlayerF[iPlayer][PlrAbility4Charge]
			PlayerStateF[iPlayer][0][StateSlowTime][0] = PlayerF[iPlayer][PlrSlowTime][0]
			PlayerStateF[iPlayer][0][StateSlowTime][1] = PlayerF[iPlayer][PlrSlowTime][1]
			PlayerStateF[iPlayer][0][StateSlowTime][2] = PlayerF[iPlayer][PlrSlowTime][2]
			PlayerStateF[iPlayer][0][StateSlowSpeed][0] = PlayerF[iPlayer][PlrSlowSpeed][0]
			PlayerStateF[iPlayer][0][StateSlowSpeed][1] = PlayerF[iPlayer][PlrSlowSpeed][1]
			PlayerStateF[iPlayer][0][StateSlowSpeed][2] = PlayerF[iPlayer][PlrSlowSpeed][2]
			PlayerStateF[iPlayer][0][StateFrozen] = PlayerF[iPlayer][PlrFrozen]
			PlayerStateF[iPlayer][0][StateChilled] = PlayerF[iPlayer][PlrChilled]
			PlayerStateF[iPlayer][0][StateSwapTime] = PlayerF[iPlayer][PlrSwapTime]
			PlayerStateF[iPlayer][0][StateBlindTime] = PlayerF[iPlayer][PlrBlindTime]

			for (i = 0; i < Player[iPlayer][PlrGlowCount]; i++)
			{
				PlayerState[iPlayer][0][StateGlowR][i] = Player[iPlayer][PlrGlowR][i]
				PlayerState[iPlayer][0][StateGlowG][i] = Player[iPlayer][PlrGlowG][i]
				PlayerState[iPlayer][0][StateGlowB][i] = Player[iPlayer][PlrGlowB][i]
				PlayerStateF[iPlayer][0][StateGlowTime][i] = PlayerF[iPlayer][PlrGlowTime][i]
			}

			fStateUpdateTime[iPlayer] = 1.0 + fGameTime
		}

		if (get_entvar(iPlayer, var_flags) & FL_ONGROUND)
		{
			if (Player[iPlayer][PlrWindBoostType] != WINDBOOST_POSITIVE
				&& PlayerF[iPlayer][PlrMaxSpeed] < player_get_knife_maxspeed(iPlayer))
			{
				if (995 <= get_entvar(iPlayer, var_flDuckTime) && !(get_entvar(iPlayer, var_button) & IN_DUCK))
				{
					new Float:fVelocity[3]
					get_entvar(iPlayer, var_velocity, fVelocity)
					fVelocity[0] = 0.0
					fVelocity[1] = 0.0
					// fVelocity[2] -= 10.0
					set_entvar(iPlayer, var_velocity, fVelocity)
				}
			}
			Player[iPlayer][PlrSGSGround]++
		}
		else
			Player[iPlayer][PlrSGSGround] = 0
	}

	static iSubjectKnifeId; iSubjectKnifeId = Player[iSubject][PlrKnife]

	if (fStatusUpdate[iPlayer] < fGameTime)
	{
		fStatusUpdate[iPlayer] = fGameTime + 0.1
		ExecuteForward(forward_status_draw, _, iPlayer, iSubject, iSubjectKnifeId)
	}

	if (g_iRegenItemId > -1 && player_item_get_value(iSubject, g_iRegenItemId) > 0)
	{
		new iHealth
		if (!g_bIsRoundEnded
			&& fRegenUpdate[iPlayer] < fGameTime
			&& !Player[iSubject][PlrBurned]
			&& (player_item_get_mode(iSubject, g_iRegenItemId))
			&& !CheckPlayerGameFlag(iSubject, PLGF_IS_DISABLED_INVENTORY)
			&& (iHealth = floatround(get_entvar(iSubject, var_health), floatround_floor)) < PlayerF[iSubject][PlrMaxHP])
		{
			if (iSubject == iPlayer)
			{
				fRegenRemainder[iPlayer] += PlayerF[iPlayer][PlrMaxHP] / 100.0
				new iRegenStep = floatround(fRegenRemainder[iPlayer], floatround_floor)
				fRegenRemainder[iPlayer] -= float(iRegenStep)

				set_entvar(iPlayer, var_health, floatmin(float(iHealth + iRegenStep), PlayerF[iPlayer][PlrMaxHP]))

				if (player_item_sub_value(iPlayer, g_iRegenItemId, 1) == 0)
				{
					player_item_set_value(iPlayer, g_iRegenItemId, -1)
					client_print(iPlayer, print_center, "%L", iPlayer, "REGENERATION_EXHAUSTED")
				}
			}

			if (iHealth <= 25)
			{
				set_hudmessage(255, 0, 0, 0.01, 0.77, 0, 0.0, 0.4, 0.0, 0.0, HUDCHANNEL_REGENERATION)
				show_hudmessage(iPlayer, "%L %d%% (turbo)", iPlayer, "REGENERATION",
					max(0, player_item_get_value(iSubject, g_iRegenItemId)))
				fRegenUpdate[iPlayer] = fGameTime + 0.35
			}
			else
			{
				set_hudmessage(0, 255, 0, 0.01, 0.77, 0, 0.0, 0.8, 0.0, 0.0, HUDCHANNEL_REGENERATION)
				show_hudmessage(iPlayer, "%L %d%%", iPlayer, "REGENERATION",
					max(0, player_item_get_value(iSubject, g_iRegenItemId)))
				fRegenUpdate[iPlayer] = fGameTime + 0.7
			}
		}
	}
	else
		fRegenRemainder[iSubject] = 0.0

	if (fHudUpdate[iPlayer] < fGameTime)
	{
		fHudUpdate[iPlayer] = fGameTime + 0.5

		static szChargingText[128]; szChargingText[0] = 0
		static iLen; iLen = 0
		if (PlayerF[iSubject][PlrCritChance] > 0.0)
			iLen += formatex(szChargingText, charsmax(szChargingText), "%L %.1f%%", iPlayer, "CRIT_CHANCE", PlayerF[iSubject][PlrCritChance])

		if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iSubject][PlrTeam])
		{
			iLen += formatex(szChargingText, charsmax(szChargingText), "...NO SIGNAL...")
		}
		else
		{
			if (PlayerF[iSubject][PlrAbility1Charge] < 100.0)
			{
				iLen += formatex(szChargingText[iLen], charsmax(szChargingText), "^n%L", iPlayer, "ABILITY_CHARGING",
					floatround((100.0 - PlayerF[iSubject][PlrAbility1Charge]) / KnifeF[iSubjectKnifeId][KNF_ABILITY1_CHARGE], floatround_ceil))
				fOldCharge[iSubject] = PlayerF[iSubject][PlrAbility1Charge]
			}
			else if (fOldCharge[iSubject] < 100.0)
			{
				iLen += formatex(szChargingText[iLen], charsmax(szChargingText), "^n%L", iPlayer, "ABILITY_CHARGED")
				fOldCharge[iSubject] = 100.0
			}
			else if (Player[iSubject][PlrAbility1Disabled])
			{
				iLen += formatex(szChargingText[iLen], charsmax(szChargingText), "^n%L (T)", iPlayer, "ABILITY_DISABLED")
			}
		}

		if (PlayerF[iSubject][PlrPowerDamage] != 0.0)
			formatex(szChargingText[iLen], charsmax(szChargingText), "^n%L", iPlayer, "RAZOR_POWER_DAMAGE", floatround(PlayerF[iSubject][PlrPowerDamage], floatround_floor))

		if (szChargingText[0] && !g_bIsRoundEnded)
		{
			set_hudmessage(255, 255, 255, 0.01, 0.71, 0, 0.0, 1.1, 0.0, 0.0, HUDCHANNEL_ABILITY)
			show_hudmessage(iPlayer, "%s", szChargingText)
		}

		new iDrawReturn = PLUGIN_CONTINUE
		ExecuteForward(forward_charge_draw_pre, iDrawReturn, iPlayer, iSubject, iSubjectKnifeId)
		if (iDrawReturn != PLUGIN_HANDLED)
		{
			szChargingText[0] = 0
			iLen = 0

			if (Knife[iSubjectKnifeId][KNF_ABILITY2_NAME][0] != EOS)
				iLen = formatex(szChargingText, charsmax(szChargingText), "%s (E) (%dpt)",
					Knife[iSubjectKnifeId][KNF_ABILITY2_NAME],
					floatround(PlayerF[iSubject][PlrAbility2Charge], floatround_floor))

			if (Knife[iSubjectKnifeId][KNF_ABILITY3_NAME][0] != EOS)
				iLen += formatex(szChargingText[iLen], charsmax(szChargingText), "^n%s (R) (%dpt)",
					Knife[iSubjectKnifeId][KNF_ABILITY3_NAME],
					floatround(PlayerF[iSubject][PlrAbility3Charge], floatround_floor))

			if (Knife[iSubjectKnifeId][KNF_ABILITY4_NAME][0] != EOS)
				formatex(szChargingText[iLen], charsmax(szChargingText), "^n%s (F) (%dpt)",
					Knife[iSubjectKnifeId][KNF_ABILITY4_NAME],
					floatround(PlayerF[iSubject][PlrAbility4Charge], floatround_floor))

			if (szChargingText[0])
			{
				if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iSubject][PlrTeam])
					formatex(szChargingText, charsmax(szChargingText), "...NO SIGNAL...")
				set_hudmessage(255, 255, 255, 0.01, -0.75, 0, 0.0, 1.2, 0.0, 0.0, HUDCHANNEL_ALTABILITY)
				show_hudmessage(iPlayer, szChargingText)
			}
		}
	}

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return HC_CONTINUE

	if (Player[iPlayer][PlrCrosshair] == CROSSHAIR_DISABLED)
		return HC_CONTINUE

	if (iVision == VISION_BLIND)
	{
		player_set_crosshair(iPlayer, CROSSHAIR_HIDDEN)
		return HC_CONTINUE
	}

	static AbilityType:iAbilType; iAbilType = Player[iPlayer][PlrAbility1Type]

	if (iAbilType == ABIL_NORMAL || Player[iPlayer][PlrAbility1Disabled])
	{
		player_set_crosshair(iPlayer, CROSSHAIR_HIDDEN)
		return HC_CONTINUE
	}

	if (PlayerF[iPlayer][PlrAbility1Charge] < 100.0)
	{
		player_set_crosshair(iPlayer, CROSSHAIR_TIME)
		return HC_CONTINUE
	}

	if (g_iSilenceTeam > -1 && g_iSilenceTeam != iTeam)
	{
		player_set_crosshair(iPlayer, CROSSHAIR_CANNOT)
		return HC_CONTINUE
	}

	static iTarget, Float:vAimOrigin[3], Float:vWallNormal[3]

	if (iAbilType < ABIL_TARGET_PLAYER)
	{
		get_aim_data(iPlayer, vOrigin, vAimOrigin, vWallNormal)
		iTarget = 0
	}
	else
	{
		get_entvar(iPlayer, var_origin, vOrigin)
		get_entvar(iPlayer, var_view_ofs, vAimOrigin)
		xs_vec_add(vOrigin, vAimOrigin, vOrigin)

		get_entvar(iPlayer, var_v_angle, vAimOrigin)
		engfunc(EngFunc_MakeVectors, vAimOrigin)
		global_get(glb_v_forward, vAimOrigin)
		xs_vec_mul_scalar(vAimOrigin, 8192.0, vAimOrigin)
		xs_vec_add(vOrigin, vAimOrigin, vAimOrigin)
		engfunc(EngFunc_TraceLine, vOrigin, vAimOrigin, DONT_IGNORE_MONSTERS, iPlayer, 0)
		get_tr2(0, TR_vecEndPos, vAimOrigin)
		iTarget = max(0, get_tr2(0, TR_pHit))
	}

	static Float:fDistance, bool:bDistanceAllowed, KnifeCrosshair:iResCrosshair
	fDistance = get_distance_f(vOrigin, vAimOrigin)
	bDistanceAllowed = PlayerF[iPlayer][PlrAbility1MinDist] <= fDistance && fDistance <= PlayerF[iPlayer][PlrAbility1MaxDist]
	iResCrosshair = KnifeCrosshair:PLUGIN_CONTINUE

	ExecuteForward(forward_crosshair_draw_pre, _:iResCrosshair, iPlayer, iTarget, iAbilType, bDistanceAllowed)

	if (iResCrosshair == KnifeCrosshair:PLUGIN_HANDLED)
		return HC_CONTINUE

	if (iResCrosshair == KnifeCrosshair:PLUGIN_CONTINUE)
		iResCrosshair = CROSSHAIR_OK

	switch (iAbilType)
	{
		case ABIL_TARGET_SURFACES:
		{
			if (!bDistanceAllowed)
				player_set_crosshair(iPlayer, CROSSHAIR_FAR)
			else
				player_set_crosshair(iPlayer, iResCrosshair)
		}
		case ABIL_TARGET_FLOOR:
		{
			if (1.0 < vWallNormal[2] || 0.0 >= vWallNormal[2])
				player_set_crosshair(iPlayer, CROSSHAIR_CANNOT)
			else if (!bDistanceAllowed)
				player_set_crosshair(iPlayer, CROSSHAIR_FAR)
			else
				player_set_crosshair(iPlayer, iResCrosshair)
		}
		case ABIL_TARGET_PLAYER:
		{
			if (!is_entity_player(iTarget)
				|| (Player[iTarget][PlrVisibility] == VIS_INVISION && iTeam != Player[iTarget][PlrTeam])
				|| (Player[iTarget][PlrWaterTransparent] && (get_entvar(iTarget, var_flags) & FL_INWATER)))
			{
				player_set_crosshair(iPlayer, CROSSHAIR_DEFAULT)
			}
			else if (CheckPlayerGameFlag(iTarget, PLGF_IN_UNABILITY))
				player_set_crosshair(iPlayer, CROSSHAIR_CANNOT)
			else if (!bDistanceAllowed)
				player_set_crosshair(iPlayer, CROSSHAIR_FAR)
			else
				player_set_crosshair(iPlayer, iResCrosshair)
		}
		case ABIL_TARGET_ENEMY:
		{
			if (!is_entity_player(iTarget) || iTeam == Player[iTarget][PlrTeam]
				|| ((Player[iTarget][PlrVisibility] == VIS_INVISION
				|| Player[iTarget][PlrVisibility] == VIS_CLONE
				|| (Player[iTarget][PlrWaterTransparent] && (get_entvar(iTarget, var_flags) & FL_INWATER)))
				&& iVision != VISION_FULL))
			{
				player_set_crosshair(iPlayer, CROSSHAIR_DEFAULT)
			}
			else if (CheckPlayerGameFlag(iTarget, PLGF_IN_UNABILITY) && (Player[iTarget][PlrVisibility] != VIS_CLONE || iVision != VISION_FULL))
				player_set_crosshair(iPlayer, CROSSHAIR_CANNOT)
			else if (!bDistanceAllowed)
				player_set_crosshair(iPlayer, CROSSHAIR_FAR)
			else
				player_set_crosshair(iPlayer, iResCrosshair)
		}
		case ABIL_TARGET_FRIEND:
		{
			if (!is_entity_player(iTarget)
				|| (iTeam != Player[iTarget][PlrTeam] && Player[iTarget][PlrVisibility] != VIS_CLONE))
			{
				player_set_crosshair(iPlayer, CROSSHAIR_DEFAULT)
			}
			else if (CheckPlayerGameFlag(iTarget, PLGF_IN_UNABILITY))
				player_set_crosshair(iPlayer, CROSSHAIR_CANNOT)
			else if (!bDistanceAllowed)
				player_set_crosshair(iPlayer, CROSSHAIR_FAR)
			else
				player_set_crosshair(iPlayer, iResCrosshair)
		}
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_PostThink_Post(iPlayer)
{
	if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
	{
		if (get_entvar(iPlayer, var_button) & IN_USE)
		{
			if (!Player[iPlayer][PlrBlockUseAbility2])
			{
				new iKnifeId = Player[iPlayer][PlrKnife]
				if (get_gametime() < PlayerF[iPlayer][PlrSwapTime])
					activate_ability3(iPlayer, iKnifeId)
				else
					activate_ability2(iPlayer, iKnifeId)
			}
		}
		else
		{
			Player[iPlayer][PlrBlockUseAbility2] = false
		}
	}
}

public fw_Player_Damage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (is_nullent(iVictim))
		return HAM_IGNORED

	new iVictimTeam = Player[iVictim][PlrTeam]

	switch (Player[iVictim][PlrCaptureType])
	{
		case CAPTURE_NORMAL, CAPTURE_STRONG: return HAM_SUPERCEDE
		case CAPTURE_WEAK:
		{
			if (!is_entity_player(iAttacker) || iAttacker == iVictim
				|| (Player[iAttacker][PlrTeam] != iVictimTeam && fDamage >= 1.0))
			{
				player_uncapture(iVictim)
			}
		}
	}

	new VisibilityType:iVisibility = Player[iVictim][PlrVisibility]

	if (iVisibility == VIS_SHADOW
		|| (PlayerF[iVictim][PlrSpawnProtectionTime] > 0.0 && is_entity_player(iAttacker)))
	{
		return HAM_SUPERCEDE
	}

	if (iVisibility == VIS_TRANS)
		return HAM_SUPERCEDE

	new Float:fNewDamage = fDamage
	new iNewAttacker = iAttacker

	if (iFlags & DMG_FALL)
	{
		new iGroundEnt = get_entvar(iVictim, var_groundentity)

		if (is_entity_player(iGroundEnt))
		{
			set_member(iGroundEnt, m_LastHitGroup, HIT_GENERIC)
			ExecuteHamB(Ham_TakeDamage, iGroundEnt, iVictim, iVictim, fDamage * FALL_DAMAGE, DMG_FALL)
			fNewDamage = fDamage * FALL_EASING
			SetHamParamFloat(4, fNewDamage)
		}
		else if (!is_nullent(iGroundEnt) && get_entvar(iGroundEnt, var_impulse) == IMPULSE_ZOMBIE)
		{
			ExecuteHamB(Ham_TakeDamage, iGroundEnt, 0, iGroundEnt, 9000.0, DMG_FALL)
			fNewDamage = fDamage * FALL_EASING
			SetHamParamFloat(4, fNewDamage)
		}
	}

	if (is_entity_player(iAttacker))
	{
		if (iAttacker != iVictim && Player[iAttacker][PlrTeam] == iVictimTeam)
		{
			if (PlayerF[iVictim][PlrFrozen] > 0.0 && (iFlags & DMG_BULLET) && get_user_weapon(iAttacker) == CSW_KNIFE)
				player_unfreeze(iVictim)

			return HAM_SUPERCEDE
		}

		if (fDamage >= 1.0)
		{
			switch (iVisibility)
			{
				case VIS_INVISION:
				{
					if (!(iFlags & DMG_BURN) && get_gametime() - PlayerF[iVictim][PlrInvisionStartTime] > 1.0)
						player_remove_invision(iVictim)
				}
				case VIS_CLONE:
				{
					if (!(iFlags & DMG_BURN))
						player_remove_clone(iVictim)
				}
			}
		}

		PlayerF[iAttacker][PlrPreGameTime] = 0.0

		if (is_entity_player(iInflictor) && (iFlags & DMG_BULLET) && get_user_weapon(iAttacker) == CSW_KNIFE)
		{
			if (get_member(iVictim, m_LastHitGroup) == HITGROUP_HEAD)
				Player[iVictim][PlrHitGroupAttacked] = KHITGROUP_HEAD
			else if (fDamage == 195.0)
				Player[iVictim][PlrHitGroupAttacked] = KHITGROUP_BACK
			else
				Player[iVictim][PlrHitGroupAttacked] = KHITGROUP_GENERIC

			new Float:fPowerDamage = PlayerF[iAttacker][PlrPowerDamage]
			new Float:fKnifeAddDamage = random_float(PlayerF[iAttacker][PlrMinDamage], PlayerF[iAttacker][PlrMaxDamage])

			ExecuteForward(forward_apply_damage, _, iVictim, iAttacker, fDamage, fPowerDamage, fKnifeAddDamage)

			fNewDamage = floatmax(fDamage + fPowerDamage + fKnifeAddDamage, 0.0)
			SetHamParamFloat(4, fNewDamage)
		}
	}

	if (!is_entity_player(iAttacker) || (iAttacker == iVictim && (iFlags & DMG_FALL)))
	{
		new iOverrideAttacker = Player[iVictim][PlrAttacker]
		if (iOverrideAttacker && Player[iOverrideAttacker][PlrTeam] != iVictimTeam)
		{
			PlayerF[iVictim][PlrAttackerTime] = get_gametime() + 1.0
			iNewAttacker = iOverrideAttacker
			SetHamParamEntity2(3, iNewAttacker)
		}
	}

	Player[iVictim][PlrHealthTmp] = pev(iVictim, pev_health)

	if (iAttacker != iNewAttacker || fNewDamage != fDamage)
		return HAM_OVERRIDE

	return HAM_IGNORED
}

public fw_Player_PostDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (is_nullent(iVictim))
		return HAM_IGNORED

	accept_dealt_damage(iVictim, iAttacker)

	if (GetHamReturnStatus() == HAM_SUPERCEDE)
	{
		if (Player[iVictim][PlrCaptureType] == CAPTURE_NORMAL && fDamage > 5.0)
			player_uncapture(iVictim)

		return HAM_SUPERCEDE
	}

	if (Player[iVictim][PlrWindBoostType] == WINDBOOST_POSITIVE)
		set_member(iVictim, m_flVelocityModifier, 1.0)

	if (is_entity_player(iAttacker) && !(iFlags & DMG_BURN))
		player_unlevitation(iVictim)

	new Float:fHealth = get_entvar(iVictim, var_health)
	if (fHealth < 1.0)
	{
		if (is_entity_player(iInflictor) && (iFlags & DMG_BULLET) && get_user_weapon(iAttacker) == CSW_KNIFE)
			ExecuteForward(forward_player_knife_killed, _, iVictim, iAttacker, Player[iAttacker][PlrKnife])

		if (fHealth > 0.0)
			ExecuteHamB(Ham_Killed, iVictim, iAttacker, GIB_NORMAL)

		gen_death_reason(iVictim, iAttacker, iFlags)
		show_death_reason(iVictim)

		if (Player[iVictim][PlrCorpseType] != CORP_CUSTOM)
		{
			if (iFlags & DMG_ACID)
			{
				new Float:vOrigin[3], Float:vAngles[3]
				get_entvar(iVictim, var_origin, vOrigin)
				get_entvar(iVictim, var_angles, vAngles)
				vOrigin[2] += 36.0

				new iCorpseEnt = corpse_create(vOrigin, vAngles, MODEL_ACID_DEATH)
				if (iCorpseEnt != NULLENT)
				{
					new Float:fGameTime = get_gametime()

					set_entvar(iCorpseEnt, var_sequence, 0)
					set_entvar(iCorpseEnt, var_animtime, fGameTime)
					set_entvar(iCorpseEnt, var_rendermode, kRenderNormal)
					set_entvar(iCorpseEnt, var_nextthink, fGameTime + CORPSES_LIFE)

					drop_to_floor(iCorpseEnt)

					player_hide(iVictim)
					Player[iVictim][PlrCorpseType] = CORP_CUSTOM
				}
			}
			else if (iFlags & DMG_FREEZE)
			{
				new Float:vOrigin[3], Float:vAngles[3]
				get_entvar(iVictim, var_origin, vOrigin)
				get_entvar(iVictim, var_angles, vAngles)
				vOrigin[2] += 36.0

				new iCorpseEnt = corpse_create(vOrigin, vAngles, MODEL_ICE_DEATH)
				if (iCorpseEnt != NULLENT)
				{
					new Float:fGameTime = get_gametime()

					emit_sound(iVictim, CHAN_BODY, SOUND_CRASH_ICEBLOCK, 1.0, ATTN_NORM, 0, PITCH_LOW)

					set_entvar(iCorpseEnt, var_rendermode, kRenderNormal)
					set_entvar(iCorpseEnt, var_sequence, 0)
					set_entvar(iCorpseEnt, var_animtime, fGameTime)
					set_entvar(iCorpseEnt, var_renderfx, kRenderFxGlowShell)
					set_entvar(iCorpseEnt, var_rendercolor, Float:{FROST_COLOR_R.0, FROST_COLOR_G.0, FROST_COLOR_B.0} )
					set_entvar(iCorpseEnt, var_renderamt, 8.0)
					set_entvar(iCorpseEnt, var_nextthink, fGameTime + 8.0)

					drop_to_floor(iCorpseEnt)

					player_hide(iVictim)
					Player[iVictim][PlrCorpseType] = CORP_CUSTOM
				}
			}
			else if (iFlags & DMG_BURN)
			{
				rg_set_user_model(iVictim, BURN_PLAYER_MODEL)
				Player[iVictim][PlrCorpseType] = CORP_CUSTOM

				new iHatEnt = Player[iVictim][PlrHatEnt]
				if (iHatEnt)
					set_entvar(iHatEnt, var_effects, EF_NODRAW)
			}
		}
	}
	else
	{
		Player[iVictim][PlrDeathReasonText][0] = EOS
	}

	Player[iVictim][PlrHitGroupAttacked] = KHITGROUP_GENERIC

	return HAM_IGNORED
}

public fw_EnvExposion_Damage(iVictim, iInflictor, iAttacker, Float:fDamage, iFlags)
{
	if (is_nullent(iVictim))
		return HAM_IGNORED

	if (!is_entity_player(iAttacker))
		return HAM_IGNORED

	if (get_entvar(iVictim, var_impulse) == IMPULSE_ZOMBIE)
	{
		new iOwner = get_entvar(iVictim, var_npcowner)

		if (Player[iAttacker][PlrTeam] == get_entvar(iVictim, var_skin) + 1 && iOwner != iAttacker)
			return HAM_SUPERCEDE

		if ((iFlags & DMG_BULLET) && get_user_weapon(iAttacker) == CSW_KNIFE)
		{
			new Float:fNewDamage = floatmax(0.0, fDamage + PlayerF[iAttacker][PlrPowerDamage] +
				(floatround(random_float(PlayerF[iAttacker][PlrMinDamage], PlayerF[iAttacker][PlrMaxDamage])) + 0.0))

			SetHamParamFloat(4, fNewDamage)
			return HAM_OVERRIDE
		}
	}

	return HAM_IGNORED
}

public fw_TraceAttack(iVictim, iAttacker, Float:fDamage, Float:vDir[3], iTraceId, iFlags)
{
	if (PlayerF[iVictim][PlrSpawnProtectionTime] > 0.0)
		return HAM_SUPERCEDE

	if (is_entity_player(iAttacker))
	{
		if (Player[iAttacker][PlrVision] == VISION_BLIND && CHANCE_BLINDED_MISS)
			return HAM_SUPERCEDE

		if (Player[iVictim][PlrTeam] == Player[iAttacker][PlrTeam])
			return HAM_IGNORED

		new iAttackerItem = get_active_weapon(iAttacker)
		if (is_nullent(iAttackerItem))
			return HAM_IGNORED

		if (get_member(iAttackerItem, m_iId) == CSW_KNIFE)
		{
			new HitBoxGroup:iHitGroup = HitBoxGroup:get_tr2(iTraceId, TR_Hitgroup)
			if (iHitGroup != HITGROUP_GENERIC && iHitGroup != HITGROUP_HEAD && iHitGroup != HITGROUP_SHIELD)
				set_tr2(iTraceId, TR_Hitgroup, HITGROUP_GENERIC)

			if (Player[iVictim][PlrConcentBlock])
			{
				if (!player_apply_concentblock(iVictim, iAttacker))
					return HAM_IGNORED

				Player[iAttacker][PlrWasBlocked] = true
				set_entvar(iAttacker, var_punchangle, Float:{0.0, 0.0, 25.0})

				new Float:vAngles[3], Float:vVector[3]
				get_entvar(iVictim, var_v_angle, vAngles)
				angle_vector(vAngles, ANGLEVECTOR_FORWARD, vVector)

				new Float:vEndPos[3]
				get_tr2(iTraceId, TR_vecEndPos, vEndPos)
				xs_vec_mul_scalar(vDir, -3.0, vVector)
				xs_vec_add(vEndPos, vVector, vVector)

				send_msg_TE_SPARKS(vVector)

				set_tr2(iTraceId, TR_Hitgroup, HIT_SHIELD)

				return HAM_SUPERCEDE
			}

			if (Player[iVictim][PlrCaptureType] == CAPTURE_WEAK && (iFlags & DMG_BULLET))
			{
				if (fDamage == 65.0 || fDamage == 195.0)
				{
					new Float:vAttackerAngles[3], Float:vVictimAngles[3]
					get_entvar(iAttacker, var_v_angle, vAttackerAngles)
					xs_vec_copy(PlayerF[iVictim][PlrCaptureAngles], vVictimAngles)

					new bool:bBackStab = check_back_stab(vAttackerAngles, vVictimAngles)
					SetHamParamFloat(3, bBackStab ? 195.0 : 65.0)
				}
			}
		}
	}

	return HAM_IGNORED
}

public RG_CBasePlayer_Killed_Pre(iVictim, iAttacker)
{
	accept_dealt_damage(iVictim, iAttacker)

	if (CheckPlayerGameFlag(iVictim, PLGF_IN_FIXED_ANIMATION))
	{
		new iHatEnt = Player[iVictim][PlrHatEnt]
		if (iHatEnt)
			set_entvar(iHatEnt, var_effects, 0)

		ClearPlayerGameFlag(iVictim, PLGF_IN_FIXED_ANIMATION);
	}

	new iNewAttacker = iAttacker
	new iHealAssistant = (iAttacker != iVictim ? get_heal_assistant(iNewAttacker) : 0)
	new iAssistant = get_kill_assistant(iVictim, iNewAttacker)

	if (!iAssistant)
	{
		iAssistant = iHealAssistant
		iHealAssistant = 0
	}

	if (!is_entity_player(iAttacker) || Player[iAttacker][PlrTeam] == Player[iVictim][PlrTeam])
	{
		if (iAssistant)
		{
			iNewAttacker = iAssistant
			iAssistant = iHealAssistant
			iHealAssistant = 0
		}
	}

	if (iAttacker != iNewAttacker)
		SetHookChainArg(2, ATYPE_INTEGER, iNewAttacker)

	if (is_user_connected(iAssistant))
	{
		g_iAssistKiller = iNewAttacker

		add_player_frags(iAssistant, 1)
		rg_add_account(iAssistant, KILL_ASSIST_REWARD)

		ExecuteForward(forward_player_death, _, iVictim, iNewAttacker, iAssistant)

		if (is_user_connected(iHealAssistant))
			ExecuteForward(forward_indirect_assist, _, iVictim, iNewAttacker, iHealAssistant)

		new szName[2][32], iLen[2]

		get_user_name(iNewAttacker, szName[0], charsmax(szName[]))
		iLen[0] = strlen(szName[0])

		get_user_name(iAssistant, szName[1], charsmax(szName[]))
		iLen[1] = strlen(szName[1])

		new iLenSum = (iLen[0] + iLen[1])
		new iExcess = iLenSum - 28

		if (iExcess > 0)
		{
			new iLongest = iLen[0] > iLen[1] ? 0 : 1
			new iShortest = iLongest == 1 ? 0 : 1

			if (float(iExcess) / float(iLen[iLongest]) > 0.60)
			{
				new iNewLongest = floatround(float(iLen[iLongest]) / float(iLenSum) * float(iExcess))
				strclip(szName[iLongest], iNewLongest)
				strclip(szName[iShortest], iExcess - iNewLongest)
			}
			else
				strclip(szName[iLongest], iExcess)
		}
		formatex(g_szDeathString, charsmax(g_szDeathString), "%s + %s", szName[0], szName[1])

		EnableHookChain(g_pSV_WriteFullClientUpdate)
		rh_update_user_info(iNewAttacker)
		DisableHookChain(g_pSV_WriteFullClientUpdate)
	}
	else
	{
		g_iAssistKiller = 0

		ExecuteForward(forward_player_death, _, iVictim, iNewAttacker, 0)
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_Killed_Post(iVictim, iAttacker, iFlags)
{
	if (g_iAssistKiller)
	{
		new iAssistKiller = g_iAssistKiller
		g_iAssistKiller = 0
		rh_update_user_info(iAssistKiller)
	}

	if (Player[iVictim][PlrCaptureType] != CAPTURE_NONE)
		player_uncapture(iVictim)

	ClearPlayerGameFlag(iVictim, PLGF_IS_ALIVE);
	Player[iVictim][PlrConcentBlock] = 0
	player_set_windboost(iVictim, WINDBOOST_NONE, false)

	player_reset_visibility(iVictim)
	player_reset_vision(iVictim)

	if (iFlags == GIB_ALWAYS)
	{
		Player[iVictim][PlrCorpseType] = CORP_CUSTOM
		player_hide(iVictim)
	}

	ClearPlayerGameFlag(iVictim, PLGF_IN_UNABILITY);
	ClearPlayerGameFlag(iVictim, PLGF_IS_DISABLED_CHARGE);
	ClearPlayerGameFlag(iVictim, PLGF_IS_DISABLED_INVENTORY);

	player_unburn(iVictim)
	player_unfreeze(iVictim)
	player_unchill(iVictim)
	player_unlevitation(iVictim)
	player_uncapture(iVictim)
	player_reflection_stop(iVictim, true)

	new iBeamEnt = NULLENT
	while ((iBeamEnt = rg_find_ent_by_class(iBeamEnt, SZ_BEAM)))
		if (get_entvar(iBeamEnt, var_aiment) == iVictim)
			set_entvar(iBeamEnt, var_flags, FL_KILLME)

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrVisibility] == VIS_SHADOW && Player[i][PlrClone] == iVictim)
			player_remove_shadow(i, true)
	}

	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iVictim][PlrTeam])
	{
		send_msg_TE_KILLPLAYERATTACHMENTS(iVictim, MSG_ALL)
	}

	Player[iVictim][PlrAttacker] = 0
	PlayerF[iVictim][PlrSpawnProtectionTime] = 0.0
	PlayerF[iVictim][PlrPreGameTime] = 0.0
	PlayerF[iVictim][PlrModelAnimTime] = 0.0
	PlayerF[iVictim][PlrCheckStuckTime] = 0.0

	if (Player[iVictim][PlrHpBarEnt])
		set_entvar(Player[iVictim][PlrHpBarEnt], var_effects, EF_NODRAW)

	player_set_camera(iVictim, CAMERA_MODE_1ST, false)

	if (is_entity_player(iAttacker))
		PlayerF[iAttacker][PlrPreGameTime] = 0.0
}

public RH_SV_WriteFullClientUpdate_Pre(const iPlayer, const pBuffer)
{
	if (iPlayer == g_iAssistKiller)
		set_key_value(pBuffer, "name", g_szDeathString)
}

public Message_TeamInfo()
{
	new iPlayer = get_msg_arg_int(1)

	new szTeam[3]
	get_msg_arg_string(2, szTeam, charsmax(szTeam))

	new iOldTeam = Player[iPlayer][PlrTeam]

	new iNewTeam
	switch (szTeam[0])
	{
		case 'T': iNewTeam = 1
		case 'C': iNewTeam = 2
		case 'S': iNewTeam = 3
		default: iNewTeam = 0
	}
	Player[iPlayer][PlrTeam] = iNewTeam

	if (iOldTeam != iNewTeam)
	{
		arrayset(Player[iPlayer][PlrDamageAccept], 0, MAX_PLAYERS + 1)
		arrayset(Player[iPlayer][PlrDamageAcceptRnd], 0, MAX_PLAYERS + 1)
		ExecuteForward(forward_player_change_team, _, iPlayer, iNewTeam)
	}
}

public fw_AddToFullPack(es_state, e, ent, host, hostflags, player)
{
	static i, VisibilityType:iVisibility, iHostTeam, iClone,
		iImpulse, Float:vOrigin[3], iFlags

	if (is_nullent(ent))
		return FMRES_IGNORED

	iHostTeam = Player[host][PlrTeam]

	if (player)
	{
		iFlags = get_entvar(ent, var_flags)

		if (PlayerF[ent][PlrModelAnimTime] > 0.0)
		{
			set_es(es_state, ES_Sequence, Player[ent][PlrModelAnim][0])
			set_es(es_state, ES_FrameRate, 0.0)
			set_es(es_state, ES_Frame, PlayerF[ent][PlrModelAnimFrame])
		}

		if ((iFlags & FL_ONGROUND) && (get_entvar(ent, var_iuser3) & PLAYER_PREVENT_JUMP))
			set_es(es_state, ES_Gravity, 999999.0)

		if (CheckPlayerGameFlag(host, PLGF_IS_ALIVE) && Player[host][PlrVision] != VISION_FULL && Player[ent][PlrTeam] != iHostTeam)
		{
			if (Player[ent][PlrVisibility] == VIS_INVISION)
			{
				if (CheckPlayerGameFlag(ent, PLGF_IN_LOCK_POWER_DAMAGE) || (iFlags & FL_INWATER))
					set_es(es_state, ES_RenderAmt, INVISIBLE_AMT_INWATER)
				else
					set_es(es_state, ES_Effects, EF_NODRAW)
			}
			else if (Player[ent][PlrVisibility] == VIS_CLONE)
			{
				set_es(es_state, ES_Skin, !(Player[ent][PlrTeam] - 1))
				if (get_user_weapon(ent) == CSW_KNIFE)
					set_es(es_state, ES_WeaponModel, Player[Player[ent][PlrClone]][PlrKinfeModelIndex])
			}
			else if (Player[ent][PlrWaterTransparent]
				&& (iFlags & FL_INWATER)
				&& get_entvar(ent, var_rendermode) == kRenderNormal)
			{
				set_es(es_state, ES_RenderMode, kRenderTransAlpha)
				set_es(es_state, ES_RenderAmt, INVISIBLE_AMT_INWATER)
				// set_es(es_state, ES_RenderFx, kRenderFxNone)
			}
		}

		if (CheckPlayerGameFlag(ent, PLGF_IN_FIXED_ANIMATION))
			set_es(es_state, ES_Angles, PlayerF[ent][PlrFixedCaptureAngles])

		if (Player[host][PlrOptionsFlags] & OPTION_LOWPOLY_PLAYER)
			set_es(es_state, ES_Body, get_entvar(ent, var_body) + LOWPOLY_BODY_ADD)

		return FMRES_IGNORED
	}

	iImpulse = get_entvar(ent, var_impulse)

	if ((Player[host][PlrOptionsFlags] & OPTION_HIDE_HATS)
		&& (iImpulse == IMPULSE_HAT || iImpulse == IMPULSE_FAKEHAT))
	{
		set_es(es_state, ES_Effects, EF_NODRAW)
		return FMRES_IGNORED
	}

	if ((Player[host][PlrOptionsFlags] & OPTION_LOWPOLY_PLAYER)
		&& iImpulse == IMPULSE_FAKEPLAYER_SHELL)
	{
		set_es(es_state, ES_Body, get_entvar(ent, var_body) + LOWPOLY_BODY_ADD)
		return FMRES_IGNORED
	}

	if (iImpulse == IMPULSE_LIFEBAR)
	{
		if (CheckPlayerGameFlag(host, PLGF_IS_ALIVE)
			&& is_hp_scan_available(host)
			&& (g_iDarknessTeam == -1 || g_iDarknessTeam == iHostTeam))
		{
			i = get_entvar(ent, var_aiment)
			iVisibility = Player[i][PlrVisibility]

			if (Player[i][PlrTeam] != iHostTeam && iVisibility != VIS_CLONE && iVisibility != VIS_SHADOW
				&& !(Player[i][PlrWaterTransparent] && (get_entvar(i, var_flags) & FL_INWATER)))
			{
				if (iVisibility == VIS_INVISION)
				{
					if (Player[host][PlrVision] == VISION_FULL)
						return FMRES_IGNORED

					if ((iClone = Player[i][PlrClone]))
					{
						set_es(es_state, ES_AimEnt, iClone)
						return FMRES_IGNORED
					}
				}
				else
					return FMRES_IGNORED
			}
		}

		set_es(es_state, ES_Effects, EF_NODRAW)
		return FMRES_IGNORED
	}

	if (iImpulse == IMPULSE_FOLLOWENT)
	{
		set_es(es_state, ES_Angles, PlayerF[get_entvar(ent, var_aiment)][PlrFixedCaptureAngles])
		return FMRES_IGNORED
	}

	if (iImpulse == IMPULSE_GHOST)
	{
		if (get_entvar(ent, var_owner) == host)
			return FMRES_IGNORED

		if (Player[host][PlrVision] == VISION_FULL || get_entvar(ent, var_team) == iHostTeam)
			set_es(es_state, ES_RenderAmt, 200)

		return FMRES_IGNORED
	}

	if (iImpulse == IMPULSE_GHOST_BEAM)
	{
		if (Player[host][PlrVision] != VISION_FULL ||
			Player[get_entvar(ent, var_owner)][PlrTeam] == iHostTeam)
				set_es(es_state, ES_RenderAmt, 0)

		return FMRES_IGNORED
	}

	if (iImpulse == IMPULSE_ACIDTRAP)
	{
		if (get_entvar(ent, var_trapstate) == TRAPSTATE_ACTIVE)
			return FMRES_IGNORED

		if (get_entvar(ent, var_skin) + 1 != iHostTeam)
		{
			if (Player[host][PlrVision] == VISION_FULL)
			{
				set_es(es_state, ES_RenderMode, kRenderTransAdd)
				set_es(es_state, ES_RenderAmt, 255)
			}
			else
				set_es(es_state, ES_Effects, EF_NODRAW)
		}
		else if (get_entvar(ent, var_traphighlighter) == host)
		{
			set_es(es_state, ES_RenderFx, kRenderFxGlowShell)
			set_es(es_state, ES_RenderAmt, 40)
			set_es(es_state, ES_RenderColor, Float:{ACID_COLOR_R, ACID_COLOR_G, ACID_COLOR_B})
		}

		return FMRES_IGNORED
	}

	if (iImpulse == IMPULSE_BLACKBOX)
	{
		get_entvar(host, var_origin, vOrigin)
		set_es(es_state, ES_Origin, vOrigin)
		return FMRES_IGNORED
	}

	if (!CheckPlayerGameFlag(host, PLGF_IS_ALIVE))
		return FMRES_IGNORED

	if (Player[host][PlrVision] != VISION_FULL)
	{
		if (iImpulse == IMPULSE_HAT)
		{
			i = get_entvar(ent, var_owner)
			if (Player[i][PlrTeam] == iHostTeam)
				return FMRES_IGNORED

			iVisibility = Player[i][PlrVisibility]

			if (iVisibility == VIS_CLONE)
			{
				iClone = Player[i][PlrClone]
				if (Player[iClone][PlrHatModelIndex])
				{
					set_es(es_state, ES_RenderMode, kRenderNormal)
					set_es(es_state, ES_ModelIndex, Player[iClone][PlrHatModelIndex])
					set_es(es_state, ES_Body, Player[iClone][PlrHatBody])
					set_es(es_state, ES_Skin, Player[iClone][PlrHatSkin])
					return FMRES_IGNORED
				}

				set_es(es_state, ES_Effects, EF_NODRAW)
				return FMRES_IGNORED
			}

			if (iVisibility == VIS_INVISION)
			{
				if (CheckPlayerGameFlag(i, PLGF_IN_LOCK_POWER_DAMAGE) || (get_entvar(i, var_flags) & FL_INWATER))
					set_es(es_state, ES_RenderAmt, INVISIBLE_AMT_INWATER)
				else
					set_es(es_state, ES_Effects, EF_NODRAW)
				return FMRES_IGNORED
			}

			if (Player[i][PlrWaterTransparent]
				&& (get_entvar(i, var_flags) & FL_INWATER)
				&& get_entvar(ent, var_rendermode) == kRenderNormal)
			{
				set_es(es_state, ES_RenderMode, kRenderTransAlpha)
				set_es(es_state, ES_RenderAmt, INVISIBLE_AMT_INWATER)
			}

			return FMRES_IGNORED
		}

		if (iImpulse == IMPULSE_PLAYERCLONE)
		{
			i = get_entvar(ent, var_owner)
			if (Player[i][PlrTeam] != iHostTeam)
				set_es(es_state, ES_RenderAmt, 255.0)

			return FMRES_IGNORED
		}

		if (iImpulse == IMPULSE_DRAGON_GUARD || iImpulse == IMPULSE_BLIND_EFFECT)
		{
			i = get_entvar(ent, var_aiment)
			if (!i || Player[i][PlrTeam] == iHostTeam)
				return FMRES_IGNORED

			if (Player[i][PlrVisibility] == VIS_INVISION)
			{
				if (CheckPlayerGameFlag(i, PLGF_IN_LOCK_POWER_DAMAGE) || (get_entvar(i, var_flags) & FL_INWATER))
					set_es(es_state, ES_RenderAmt, INVISIBLE_AMT_INWATER)
				else
					set_es(es_state, ES_Effects, EF_NODRAW)
				return FMRES_IGNORED
			}

			if (Player[i][PlrWaterTransparent]
				&& (get_entvar(i, var_flags) & FL_INWATER)
				&& get_entvar(ent, var_rendermode) == kRenderNormal)
			{
				set_es(es_state, ES_RenderMode, kRenderTransAlpha)
				set_es(es_state, ES_RenderAmt, INVISIBLE_AMT_INWATER)
			}

			return FMRES_IGNORED
		}
	}

	if (iImpulse == IMPULSE_DUELSPRITE)
	{
		if (Player[host][PlrVision] == VISION_BLIND)
		{
			set_es(es_state, ES_Effects, EF_NODRAW)
			return FMRES_IGNORED
		}

		new iDuelTarget = get_entvar(ent, var_dueltarget)

		if (!CheckPlayerGameFlag(iDuelTarget, PLGF_IS_ALIVE))
		{
			set_es(es_state, ES_Effects, EF_NODRAW)
			return FMRES_IGNORED
		}

		if (Player[host][PlrVision] != VISION_FULL)
		{
			if (g_iDarknessTeam > -1 && g_iDarknessTeam != iHostTeam)
			{
				set_es(es_state, ES_Effects, EF_NODRAW)
				return FMRES_IGNORED
			}

			if (Player[iDuelTarget][PlrVisibility] > VIS_INVISION)
			{
				set_es(es_state, ES_Effects, EF_NODRAW)
				return FMRES_IGNORED
			}
		}

		static Float:vEndPosition[3], Float:vVector[3], Float:vVectorNormal[3],
			Float:vView[3], Float:vEndCurPosition[3]

		if (Player[iDuelTarget][PlrVisibility] == VIS_INVISION)
		{
			iClone = Player[iDuelTarget][PlrClone]
			if (iClone)
			{
				get_entvar(iClone, var_origin, vEndPosition)
				vEndPosition[2] += 60.0
			}
			else
			{
				set_es(es_state, ES_Effects, EF_NODRAW)
				return FMRES_IGNORED
			}
		}
		else
		{
			get_entvar(iDuelTarget, var_origin, vEndPosition)
			vEndPosition[2] += 60.0
		}

		if (Player[host][PlrCustomCameraEnt] <= MaxClients)
		{
			get_entvar(host, var_origin, vOrigin)
			get_entvar(host, var_view_ofs, vView)
			xs_vec_add(vOrigin, vView, vOrigin)
		}
		else
			get_entvar(Player[host][PlrCustomCameraEnt], var_origin, vOrigin)

		xs_vec_sub(vEndPosition, vOrigin, vVector)
		xs_vec_normalize(vVector, vVectorNormal)

		engfunc(EngFunc_TraceLine, vOrigin, vEndPosition, IGNORE_MONSTERS, host, 0)
		get_tr2(0, TR_vecEndPos, vEndCurPosition)

		xs_vec_mul_scalar(vVectorNormal, -DUEL_SPRITE_DISTANCE, vVector)
		xs_vec_add(vEndCurPosition, vVector, vEndCurPosition)

		if (get_distance_f(vOrigin, vEndCurPosition) - get_distance_f(vEndPosition, vEndCurPosition) < 100.0)
		{
			xs_vec_mul_scalar(vVectorNormal, floatmin(100.0, get_distance_f(vOrigin, vEndCurPosition)), vEndCurPosition)
			xs_vec_add(vOrigin, vEndCurPosition, vEndCurPosition)

			set_es(es_state, ES_Scale, get_distance_f(vOrigin, vEndCurPosition) / 100.0 * 0.5)
		}

		set_es(es_state, ES_Origin, vEndCurPosition)
	}

	return FMRES_IGNORED
}

public fw_UpdateClientData_Post(iPlayer, iSendWeapons, iCD)
{
	if (CheckPlayerGameFlag(iPlayer, PLGF_IN_FIXED_ANIMATION))
		set_cd(iCD, CD_Flags, get_cd(iCD, CD_Flags) | FL_ONTRAIN)

	return FMRES_IGNORED
}

public fw_EmitSound(iEnt, iChannel, const szSample[], Float:fVolume, Float:fAttn, iFlags, iPitch)
{
	if (is_entity_player(iEnt))
	{
		new iKnifeId = Player[iEnt][PlrKnife]

		if (!is_valid_knife(iKnifeId))
			return FMRES_IGNORED

		if (equal(szSample, "common/wpn_select.wav"))
			Player[iEnt][PlrBlockUseAbility2] = true

		static szNewSound[256]
		if (g_tSoundKnife[iKnifeId] && TrieGetString(g_tSoundKnife[iKnifeId], szSample, szNewSound, 255))
		{
			emit_sound(iEnt, iChannel, szNewSound, fVolume, fAttn, iFlags, iPitch)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

new g_iStatusTextTarget[MAX_PLAYERS + 1], g_szStatusTextContent[24]

generate_status_text(iPlayer)
{
	new iDrawHealth, iTarget = global_get(glb_trace_ent)
	if (!is_entity_player(iTarget))
		return

	formatex(g_szStatusTextContent, charsmax(g_szStatusTextContent), "%s", "1 %p2")

	if (Player[iPlayer][PlrVision] != VISION_BLIND)
	{
		g_iStatusTextTarget[iPlayer] = iTarget

		if (Player[iTarget][PlrTeam] == Player[iPlayer][PlrTeam])
		{
			add(g_szStatusTextContent, charsmax(g_szStatusTextContent), fmt(" | HP: %s", "%i3%%"))
			iDrawHealth = 1
		}
		else if (Player[iPlayer][PlrVision] != VISION_FULL)
		{
			switch (Player[iTarget][PlrVisibility])
			{
				case VIS_INVISION:
				{
					g_iStatusTextTarget[iPlayer] = 0
				}
				case VIS_CLONE:
				{
					add(g_szStatusTextContent, charsmax(g_szStatusTextContent), fmt(" | HP: %i%s",
						floatround(get_entvar(iTarget, var_health), floatround_floor), "%%"))
					g_iStatusTextTarget[iPlayer] = Player[iTarget][PlrClone]
					iDrawHealth = 1
				}
			}
		}

		if (g_iStatusTextTarget[iPlayer] && !iDrawHealth && is_hp_scan_available(iPlayer))
		{
			new iHealth = floatround(get_entvar(iTarget, var_health), floatround_floor)
			add(g_szStatusTextContent, charsmax(g_szStatusTextContent), fmt(" | HP: %i%s", iHealth, "%%"))
		}
	}
	else
		g_iStatusTextTarget[iPlayer] = 0
}

public Message_StatusText(msgID, msgDest, msgEnt)
{
	generate_status_text(msgEnt)
	set_msg_arg_string(2, g_szStatusTextContent)
}

public Message_StatusValue(msgID, msgDest, msgEnt)
{
	static iType, iVal
	iVal = get_msg_arg_int(2)

	if (!iVal)
		return PLUGIN_CONTINUE

	iType = get_msg_arg_int(1)
	switch (iType)
	{
		case 1:
		{
			generate_status_text(msgEnt)
			message_begin(MSG_ONE, g_msgStatusText, _, msgEnt)
			write_byte(0)
			write_string(g_szStatusTextContent)
			message_end()

			if (!g_iStatusTextTarget[msgEnt])
				set_msg_arg_int(2, ARG_BYTE, 0)
		}
		case 2:
		{
			if (g_iStatusTextTarget[msgEnt] != iVal)
			{
				generate_status_text(msgEnt)
				message_begin(MSG_ONE, g_msgStatusText, _, msgEnt)
				write_byte(0)
				write_string(g_szStatusTextContent)
				message_end()
			}

			set_msg_arg_int(2, ARG_BYTE, g_iStatusTextTarget[msgEnt])
		}
		case 3:
		{
			set_msg_arg_int(2, ARG_BYTE,
				floatround(get_entvar(g_iStatusTextTarget[msgEnt], var_health), floatround_floor))
		}
	}

	return PLUGIN_CONTINUE
}

public fw_KnifeIdle(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_weapon_owner(iWeapon)

	if (Player[iPlayer][PlrConcentBlock] && Float:get_member(iWeapon, m_Weapon_flTimeWeaponIdle) <= 0.0)
	{
		Player[iPlayer][PlrConcentBlock] = 0

		ExecuteForward(forward_concentblock_timeout, _, iPlayer)
	}

	return HAM_IGNORED
}

public fw_PrePrimaryAttack(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_weapon_owner(iWeapon)

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return HAM_IGNORED

	if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
		return HAM_SUPERCEDE

	new Float:fGameTime = get_gametime()

	if (fGameTime < PlayerF[iPlayer][PlrSwapTime])
	{
		if (!(Player[iPlayer][PlrBlockAttack] & (1<<0)))
		{
			Player[iPlayer][PlrBlockAttack] |= (1<<0)
			Player[iPlayer][PlrBlockAttack] |= (1<<1)
			ExecuteHamB(Ham_Weapon_SecondaryAttack, iWeapon)

			new Float:fNextPrimAttack = get_member(iWeapon, m_Weapon_flNextPrimaryAttack)
			new Float:fNextSecAttack = get_member(iWeapon, m_Weapon_flNextSecondaryAttack)

			if (fGameTime + floatmin(fNextPrimAttack, fNextSecAttack) < PlayerF[iPlayer][PlrSwapTime])
			{
				set_member(iWeapon, m_Weapon_flNextPrimaryAttack, fNextSecAttack)
				set_member(iWeapon, m_Weapon_flNextSecondaryAttack, fNextPrimAttack)
			}

			return HAM_SUPERCEDE
		}
		else
			Player[iPlayer][PlrBlockAttack] &= ~(1<<0)
	}

	if (Player[iPlayer][PlrVisibility] == VIS_SHADOW)
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public fw_PreSecondaryAttack(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_weapon_owner(iWeapon)

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return HAM_IGNORED

	if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
		return HAM_SUPERCEDE

	new Float:fGameTime = get_gametime()

	if (fGameTime < PlayerF[iPlayer][PlrSwapTime])
	{
		if (!(Player[iPlayer][PlrBlockAttack] & (1<<0)))
		{
			Player[iPlayer][PlrBlockAttack] |= (1<<0)
			Player[iPlayer][PlrBlockAttack] |= (1<<2)
			ExecuteHamB(Ham_Weapon_PrimaryAttack, iWeapon)

			new Float:fNextPrimAttack = get_member(iWeapon, m_Weapon_flNextPrimaryAttack)
			new Float:fNextSecAttack = get_member(iWeapon, m_Weapon_flNextSecondaryAttack)

			if (fGameTime + floatmin(fNextPrimAttack, fNextSecAttack) < PlayerF[iPlayer][PlrSwapTime])
			{
				set_member(iWeapon, m_Weapon_flNextPrimaryAttack, fNextSecAttack)
				set_member(iWeapon, m_Weapon_flNextSecondaryAttack, fNextPrimAttack)
			}

			return HAM_SUPERCEDE
		}
		else
			Player[iPlayer][PlrBlockAttack] &= ~(1<<0)
	}

	if (Player[iPlayer][PlrVisibility] == VIS_SHADOW)
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public fw_PrimaryAttack(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_weapon_owner(iWeapon)

	if (Player[iPlayer][PlrWasBlocked])
	{
		set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 1.1)
		set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 1.1)
		set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 1.1)
		Player[iPlayer][PlrWasBlocked] = false
	}

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return HAM_IGNORED

	Player[iPlayer][PlrConcentBlock] = 0

	if (Player[iPlayer][PlrBlockAttack] & (1<<1))
	{
		Player[iPlayer][PlrBlockAttack] &= ~(1<<1)
		return HAM_SUPERCEDE
	}

	if (Player[iPlayer][PlrVisibility] == VIS_INVISION)
		player_remove_invision(iPlayer)
	else if (Player[iPlayer][PlrVisibility] == VIS_CLONE && PlayerF[iPlayer][PlrCloneTimeValue] <= get_gametime())
		player_remove_clone(iPlayer)

	PlayerF[iPlayer][PlrModelAnimTime] = 0.0

	return HAM_IGNORED
}

public fw_SecondaryAttack(iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_weapon_owner(iWeapon)

	if (Player[iPlayer][PlrWasBlocked])
	{
		set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 1.1)
		set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 1.1)
		set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 1.1)
		Player[iPlayer][PlrWasBlocked] = false
	}

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return HAM_IGNORED

	Player[iPlayer][PlrConcentBlock] = 0

	PlayerF[iPlayer][PlrModelAnimTime] = 0.0

	if (Player[iPlayer][PlrBlockAttack] & (1<<2))
	{
		Player[iPlayer][PlrBlockAttack] &= ~(1<<2)
		return HAM_SUPERCEDE
	}

	if (Player[iPlayer][PlrVisibility] == VIS_INVISION)
		player_remove_invision(iPlayer)
	else if (Player[iPlayer][PlrVisibility] == VIS_CLONE && PlayerF[iPlayer][PlrCloneTimeValue] <= get_gametime())
		player_remove_clone(iPlayer)

	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
		return HAM_IGNORED

	if (PlayerF[iPlayer][PlrAbility1Charge] < 100.0 || Player[iPlayer][PlrAbility1Disabled])
		return HAM_IGNORED

	if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
		return HAM_IGNORED

	new iKnifeId = Player[iPlayer][PlrKnife]
	new AbilityType:iAbilType = Player[iPlayer][PlrAbility1Type]

	new iTarget
	new Float:fDistance = get_user_aiming(iPlayer, iTarget)

	if (is_entity_player(iTarget))
	{
		if (iAbilType == ABIL_TARGET_ENEMY && Player[iPlayer][PlrTeam] == Player[iTarget][PlrTeam])
			return HAM_IGNORED

		if (iAbilType == ABIL_TARGET_FRIEND && Player[iPlayer][PlrTeam] != Player[iTarget][PlrTeam])
			return HAM_IGNORED
	}

	if (iAbilType == ABIL_NORMAL && !is_entity_player(iTarget))
		iTarget = -1

	if (ABIL_TARGET_PLAYER <= iAbilType && iAbilType <= ABIL_TARGET_ENEMY && !is_nullent(iTarget))
	{
		if (PlayerF[iPlayer][PlrAbility1MinDist] > fDistance || fDistance > PlayerF[iPlayer][PlrAbility1MaxDist])
			return HAM_IGNORED

		if (is_entity_player(iTarget) && CheckPlayerGameFlag(iTarget, PLGF_IN_UNABILITY) && (Player[iTarget][PlrVisibility] != VIS_CLONE || Player[iPlayer][PlrVision] != VISION_FULL))
			return HAM_IGNORED
	}

	switch (iAbilType)
	{
		case ABIL_TARGET_FLOOR:
		{
			new Float:fWallNormal[3], Float:vOrigin[3], Float:fAimOrigin[3]
			get_aim_data(iPlayer, vOrigin, fAimOrigin, fWallNormal)

			if (1.0 < fWallNormal[2] || 0.0 >= fWallNormal[2])
				return HAM_IGNORED

			if (PlayerF[iPlayer][PlrAbility1MinDist] > get_distance_f(vOrigin, fAimOrigin)
				|| get_distance_f(vOrigin, fAimOrigin) > PlayerF[iPlayer][PlrAbility1MaxDist])
				return HAM_IGNORED
		}
		case ABIL_TARGET_SURFACES:
		{
			new Float:vOrigin[3], Float:fAimOrigin[3];
			get_aim_data(iPlayer, vOrigin, fAimOrigin);

			new Float:distance = get_distance_f(vOrigin, fAimOrigin);

			if (PlayerF[iPlayer][PlrAbility1MinDist] > distance || distance > PlayerF[iPlayer][PlrAbility1MaxDist])
				return HAM_IGNORED
		}
	}

	new abilReturn = PLUGIN_CONTINUE
	ExecuteForward(forward_abil_pre, abilReturn, iPlayer, iTarget)
	if (abilReturn == PLUGIN_HANDLED)
		return HAM_IGNORED

	if (ABIL_TARGET_PLAYER <= iAbilType && iAbilType <= ABIL_TARGET_ENEMY && !is_entity_player(iTarget))
		return HAM_IGNORED

	ExecuteForward(Knife[iKnifeId][KNF_ABILITY1_CALLBACK], abilReturn, iPlayer, iTarget)

	if (abilReturn != PLUGIN_HANDLED && abilReturn != PLUGIN_HANDLED_MAIN)
	{
		player_reset_abil1_charge(iPlayer)
		ExecuteForward(forward_abil_post, _, iPlayer, iTarget)
	}

	return HAM_IGNORED
}

public fw_Nade_PrimaryAttack(const iWeapon)
{
	if (is_nullent(iWeapon))
		return HAM_IGNORED

	new iPlayer = get_weapon_owner(iWeapon)
	if (is_nullent(iPlayer))
		return HAM_IGNORED

	if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public fw_CmdStart(iPlayer, UC_Handle)
{
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return

	if (get_uc(UC_Handle, UC_Buttons) & IN_RELOAD)
	{
		new iKnifeId = Player[iPlayer][PlrKnife]
		if (get_gametime() < PlayerF[iPlayer][PlrSwapTime])
			activate_ability2(iPlayer, iKnifeId)
		else
			activate_ability3(iPlayer, iKnifeId)
	}
}

activate_ability2(iPlayer, iKnifeId)
{
	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
		return

	if (g_bIsRoundEnded)
		return

	if (PlayerF[iPlayer][PlrAbility2Charge] == 100.0
		&& Knife[iKnifeId][KNF_ABILITY2_NAME][0] != EOS)
	{
		new iAbilReturn = PLUGIN_CONTINUE
		ExecuteForward(forward_abil2_pre, iAbilReturn, iPlayer)

		if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
			return

		if (iAbilReturn == PLUGIN_CONTINUE)
		{
			ExecuteForward(Knife[iKnifeId][KNF_ABILITY2_CALLBACK], iAbilReturn, iPlayer)

			if (iAbilReturn != PLUGIN_HANDLED)
			{
				PlayerF[iPlayer][PlrAbility2Charge] = 0.0
				PlayerF[iPlayer][PlrAbility2LastChange] = get_gametime()
				ExecuteForward(forward_abil2_post, _, iPlayer)
			}
			else
				PlayerF[iPlayer][PlrAbility2Charge] = 99.9
		}
	}
}

activate_ability3(iPlayer, iKnifeId)
{
	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
		return

	if (g_bIsRoundEnded)
		return

	if (PlayerF[iPlayer][PlrAbility3Charge] == 100.0
		&& Knife[iKnifeId][KNF_ABILITY3_NAME][0] != EOS)
	{
		new iAbilReturn = PLUGIN_CONTINUE
		ExecuteForward(forward_abil3_pre, iAbilReturn, iPlayer)

		if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
			return

		if (iAbilReturn == PLUGIN_CONTINUE)
		{
			ExecuteForward(Knife[iKnifeId][KNF_ABILITY3_CALLBACK], iAbilReturn, iPlayer)

			if (iAbilReturn != PLUGIN_HANDLED)
			{
				PlayerF[iPlayer][PlrAbility3Charge] = 0.0
				PlayerF[iPlayer][PlrAbility3LastChange] = get_gametime()
				ExecuteForward(forward_abil3_post, _, iPlayer)
			}
			else
				PlayerF[iPlayer][PlrAbility3Charge] = 99.9
		}
	}
}

activate_ability4(iPlayer, iKnifeId)
{
	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
		return

	if (g_bIsRoundEnded)
		return

	if (PlayerF[iPlayer][PlrAbility4Charge] == 100.0
		&& Knife[iKnifeId][KNF_ABILITY4_NAME][0] != EOS)
	{
		new iAbilReturn = PLUGIN_CONTINUE
		ExecuteForward(forward_abil4_pre, iAbilReturn, iPlayer)

		if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
			return

		if (iAbilReturn == PLUGIN_CONTINUE)
		{
			ExecuteForward(Knife[iKnifeId][KNF_ABILITY4_CALLBACK], iAbilReturn, iPlayer)

			if (iAbilReturn != PLUGIN_HANDLED)
			{
				PlayerF[iPlayer][PlrAbility4Charge] = 0.0
				PlayerF[iPlayer][PlrAbility4LastChange] = get_gametime()
				ExecuteForward(forward_abil4_post, _, iPlayer)
			}
			else
				PlayerF[iPlayer][PlrAbility4Charge] = 99.9
		}
	}
}

public fw_KnifeDeploy(iWeapon)
{
	new iPlayer = get_weapon_owner(iWeapon)
	new iKnifeId = Player[iPlayer][PlrKnife]

	Player[iPlayer][PlrConcentBlock] = 0

	if (!is_valid_knife(iKnifeId))
		return HAM_IGNORED

	set_pev(iPlayer, pev_viewmodel, Knife[iKnifeId][KNF_MODEL_V_STRID])
	set_pev(iPlayer, pev_weaponmodel, Knife[iKnifeId][KNF_MODEL_P_STRID])
	Player[iPlayer][PlrKinfeModelIndex] = Knife[iKnifeId][KNF_MODEL_P]

	if (Player[iPlayer][PlrVisibility] == VIS_CLONE)
		iKnifeId = Player[Player[iPlayer][PlrClone]][PlrKnife]

	set_member(iPlayer, m_szAnimExtention, ANIM_EXTENSIONS[Knife[iKnifeId][KNF_ANIM_EXT]])

	return HAM_IGNORED
}

public fw_Item_PreFrame(iPlayer)
{
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return HAM_IGNORED

	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
		case VIS_SHADOW: player_remove_shadow(iPlayer, true)
	}

	if (Player[iPlayer][PlrLevitation])
		engfunc(EngFunc_SetClientMaxspeed, iPlayer, MIN_PLAYER_SPEED)
	else
		engfunc(EngFunc_SetClientMaxspeed, iPlayer, PlayerF[iPlayer][PlrMaxSpeed])

	return HAM_IGNORED
}

public event_CurWeapon(iPlayer)
{
	Player[iPlayer][PlrConcentBlock] = 0

	if (get_user_weapon(iPlayer) != CSW_KNIFE)
	{
		Player[iPlayer][PlrCrosshair] = CROSSHAIR_DISABLED

		message_begin(MSG_ONE, g_msgHideWeapon, _, iPlayer)
		write_byte(1>>7)
		message_end()
	}
	else
	{
		Player[iPlayer][PlrCrosshair] = CROSSHAIR_HIDDEN

		message_begin(MSG_ONE, g_msgCurWeapon, _, iPlayer)
		write_byte(1)
		write_byte(CSW_C4)
		write_byte(0)
		message_end()

		message_begin(MSG_ONE, g_msgWeaponList, _, iPlayer)
		write_string(SZ_WEAPON_C4)
		write_byte(-1)
		write_byte(-1)
		write_byte(-1)
		write_byte(-1)
		write_byte(4)
		write_byte(3)
		write_byte(CSW_C4)
		write_byte(24)
		message_end()
	}
}

public event_Health(iPlayer)
{
	if (Player[iPlayer][PlrHpBarEnt])
	{
		new iHealth = floatround(get_entvar(iPlayer, var_health), floatround_floor)
		new Float:fMaxHealth = PlayerF[iPlayer][PlrMaxHP]

		new Float:fMinFrame = 0.0
		new Float:fMaxFrame = float(LIFEBAR_FRAMES_NUM - 1)

		set_entvar(Player[iPlayer][PlrHpBarEnt], var_frame,
			floatclamp(float(iHealth * LIFEBAR_FRAMES_NUM) / fMaxHealth - 1.0, fMinFrame, fMaxFrame))
	}
}

public fw_PlayerTouch(iPlayer, iOther)
{
	if (is_entity_player(iOther))
	{
		if (Player[iPlayer][PlrBurned])
			player_burn(iOther, Player[iPlayer][PlrBurnAttacker], Player[iPlayer][PlrBurned], true)

		if (Player[iPlayer][PlrTeam] != Player[iOther][PlrTeam])
		{
			if (Player[iPlayer][PlrVisibility] == VIS_INVISION && get_gametime() - PlayerF[iPlayer][PlrInvisionStartTime] > 1.0)
				player_remove_invision(iPlayer)
		}
	}
}

public RG_CBasePlayer_Duck_Pre(const iPlayer)
{
	if (Player[iPlayer][PlrWindBoostType] != WINDBOOST_POSITIVE)
	{
		new iSGSGround = Player[iPlayer][PlrSGSGround]
		if (PlayerF[iPlayer][PlrMaxSpeed] < player_get_knife_maxspeed(iPlayer))
		{
			if (iSGSGround && iSGSGround < 5)
				set_entvar(iPlayer, var_oldbuttons, get_entvar(iPlayer, var_oldbuttons) | IN_DUCK)
		}
	}

	return HC_CONTINUE
}

Player_BhopThink(iPlayer)
{
	if (!Player[iPlayer][PlrIsBhopEnabled] || CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
		return PLUGIN_CONTINUE

	if (get_entvar(iPlayer, var_button) & IN_JUMP)
	{
		if (PlayerF[iPlayer][PlrMaxSpeed] < 100.0)
			return PLUGIN_HANDLED

		if (CheckKnifeFlag(Player[iPlayer][PlrKnife], KNFF_BAN_BUNNYHOP))
			return PLUGIN_HANDLED

		new iFlags = get_entvar(iPlayer, var_flags)
		if ((iFlags & FL_WATERJUMP) || !(iFlags & FL_ONGROUND))
			return PLUGIN_HANDLED

		if (get_member(iPlayer, m_flVelocityModifier) != 1.0)
			return PLUGIN_HANDLED

		if (get_entvar(iPlayer, var_waterlevel) >= 2)
			return PLUGIN_HANDLED

		if (PlayerF[iPlayer][PlrChilled] != 0.0)
			return PLUGIN_HANDLED

		if (Player[iPlayer][PlrVisibility] == VIS_INVISION)
			return PLUGIN_HANDLED

		static Float:fLastBhopTime[MAX_PLAYERS + 1]
		new Float:fGameTime = get_gametime()
		if (fGameTime < fLastBhopTime[iPlayer])
			return PLUGIN_HANDLED

		if (get_entvar(iPlayer, var_solid) == SOLID_NOT)
			fLastBhopTime[iPlayer] = fGameTime + 0.5

		static Float:vVelocity[3], Float:fHorizontalSpeed
		get_entvar(iPlayer, var_velocity, vVelocity)

		fHorizontalSpeed = xs_vec_len_2d(vVelocity)
		if (fHorizontalSpeed > BHOP_HORIZONTAL_SPEED)
		{
			vVelocity[0] *= BHOP_HORIZONTAL_SPEED / fHorizontalSpeed
			vVelocity[1] *= BHOP_HORIZONTAL_SPEED / fHorizontalSpeed
		}
		vVelocity[2] += 250.0
		set_entvar(iPlayer, var_velocity, vVelocity)
		set_entvar(iPlayer, var_gaitsequence, 6)

		new szSound[32]
		formatex(szSound, charsmax(szSound), "player/pl_step%d.wav", random_num(1, 3))
		emit_sound(iPlayer, CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	return PLUGIN_CONTINUE
}

public RG_CBasePlayer_Jump_Pre(const iPlayer)
{
	if (Player[iPlayer][PlrWindBoostType] != WINDBOOST_POSITIVE)
	{
		new iSGSGround = Player[iPlayer][PlrSGSGround]
		if (PlayerF[iPlayer][PlrMaxSpeed] < player_get_knife_maxspeed(iPlayer))
		{
			if (iSGSGround && iSGSGround < 5)
				set_entvar(iPlayer, var_oldbuttons, get_entvar(iPlayer, var_oldbuttons) | IN_JUMP)
		}
	}

	return HC_CONTINUE
}

public RG_ResetSequenceInfo_Pre(const iPlayer)
{
	if (get_member(iPlayer, m_Activity) == ACT_DIESIMPLE)
	{
		if (Player[iPlayer][PlrHitGroupAttacked] == KHITGROUP_HEAD &&
			get_member(iPlayer, m_LastHitGroup) == HITGROUP_HEAD)
		{
			if (get_entvar(iPlayer, var_flags) & FL_DUCKING)
				set_entvar(iPlayer, var_sequence, PLAYER_SEQ_DEATH_UNHEAD_CROUCH)
			else
				set_entvar(iPlayer, var_sequence, PLAYER_SEQ_DEATH_UNHEAD)
			set_entvar(iPlayer, var_body, DEATH_ANIM_UNHEAD_BODY)

			new Float:vOrigin[3], Float:vDirection[3]
			get_entvar(iPlayer, var_origin, vOrigin)
			vOrigin[2] += 32.0

			for (new i; i < 3; i++)
			{
				vDirection[0] = random_float(-0.3, 0.3)
				vDirection[1] = random_float(-0.3, 0.3)
				vDirection[2] = 1.0
				xs_vec_normalize(vDirection, vDirection)

				send_msg_TE_BLOODSTREAM(vOrigin, vDirection, 70, random_num(120, 150))
			}

			new iHeadIndex = g_iPlayerHeadIndexes[get_entvar(iPlayer, var_skin)]
			new Float:vVelocity[3]
			vVelocity[0] = random_float(-30.0, 30.0)
			vVelocity[1] = random_float(-30.0, 30.0)
			vVelocity[2] = random_float(300.0, 400.0)
			send_msg_TE_MODEL(vOrigin, vVelocity, random(360), iHeadIndex, 0, 400)

			new iHatEnt = Player[iPlayer][PlrHatEnt]
			if (iHatEnt)
				set_entvar(iHatEnt, var_effects, EF_NODRAW)
		}
		else if (Player[iPlayer][PlrHitGroupAttacked] == KHITGROUP_BACK)
		{
			new Float:vOrigin[3], Float:vDecalOrigin[3], Float:vDirection[3]
			get_entvar(iPlayer, var_origin, vOrigin)

			vDirection[0] = random_float(-0.5, 0.5)
			vDirection[1] = random_float(-0.5, 0.5)
			vDirection[2] = 1.0
			xs_vec_normalize(vDirection, vDirection)

			send_msg_TE_BLOODSTREAM(vOrigin, vDirection, 70, random_num(120, 150))

			vDecalOrigin[0] = vOrigin[0]
			vDecalOrigin[1] = vOrigin[1]
			vDecalOrigin[2] = -8912.0

			new pTr = create_tr2()
			engfunc(EngFunc_TraceLine, vOrigin, vDecalOrigin, IGNORE_MONSTERS, iPlayer, pTr)
			get_tr2(pTr, TR_vecEndPos, vDecalOrigin)
			free_tr2(pTr)

			send_msg_TE_WORLDDECAL(vDecalOrigin, random_num(204, 205))

			set_entvar(iPlayer, var_sequence, random(DEATH_ANIM_SLASH_NUM) + DEATH_ANIM_SLASH_START)
			set_entvar(iPlayer, var_body, DEATH_ANIM_SLASH_BODY)
		}
	}
}

public RG_CBasePlayer_SetAnimation_Pre(const iPlayer, PLAYER_ANIM:playerAnim)
{
	return CheckPlayerGameFlag(iPlayer, PLGF_IN_FIXED_ANIMATION) ? HC_SUPERCEDE : HC_CONTINUE
}

public RG_PM_AirMove_Pre(const PlayerMove:pPMove, const server)
{
	static iPlayer; iPlayer = get_pmove(pm_player_index) + 1
	if ((PlayerF[iPlayer][PlrBlockAirAcTime] > 0.0 && (Player[iPlayer][PlrBlockAirAcFlags] & FL_BAIR_NORMAL))
		|| Player[iPlayer][PlrLevitation])
	{
		set_movevar(mv_airaccelerate, 0.0)
	}
}

public RG_CBasePlayer_ThrowGrenade_Post(const iPlayer, const iGrenade,
	Float:vSrc[3], Float:vThrow[3], Float:fTime, const usEvent)
{
	new iEnt = GetHookChainReturn(ATYPE_INTEGER)
	if (is_nullent(iEnt))
		return HC_CONTINUE

	if (get_member(iGrenade, m_iId) != WEAPON_HEGRENADE)
		set_member(iEnt, m_Grenade_iTeam, get_member(iPlayer, m_iTeam))

	new WindBoostType:iWindBoostType = Player[iPlayer][PlrWindBoostType]

	if (iWindBoostType != WINDBOOST_NONE)
	{
		if (iWindBoostType == WINDBOOST_POSITIVE)
			xs_vec_mul_scalar(vThrow, WIND_NADE_FORCE, vThrow)
		else
			xs_vec_mul_scalar(vThrow, WIND_NADE_DOWNFORCE, vThrow)

		set_entvar(iEnt, var_velocity, vThrow)
	}

	return HC_CONTINUE
}

public RG_CBasePlayer_GiveDefaultItems_Pre(const iPlayer)
{
	rg_remove_all_items(iPlayer)
	rg_give_item(iPlayer, SZ_WEAPON_KNIFE)
	return HC_SUPERCEDE
}

public RG_CBasePlayer_Observer_FindNextPlayer_Post(const iPlayer, bool:bReverse, szName[])
{
	new iTarget = get_entvar(iPlayer, var_iuser2)
	if (is_entity_player(iTarget))
		player_set_topcolor_team(iPlayer, Player[iTarget][PlrTeam] == 2 ? 1 : 0)
}

public RG_CBasePlayer_Pain_Pre(const iPlayer)
{
	return HC_SUPERCEDE
}

public fw_PlayerFlashlight(iPlayer)
{
	if (!is_entity_player(iPlayer) || !CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return PLUGIN_CONTINUE

	new iKnifeId = Player[iPlayer][PlrKnife]
	if (!is_valid_knife(iKnifeId))
		return PLUGIN_CONTINUE

	activate_ability4(iPlayer, iKnifeId)

	if (CheckKnifeFlag(iKnifeId, KNFF_ZOOM)
		&& Float:get_member(iPlayer, m_flNextAttack) <= 0.0
		&& get_user_weapon(iPlayer) == CSW_KNIFE)
	{
		if (get_member(iPlayer, m_iFOV) != 90)
		{
			set_member(iPlayer, m_iFOV, 90)
			set_member(iPlayer, m_iClientFOV, 90)
			set_entvar(iPlayer, var_fov, 90)

			if (ncl_is_client_api_ready(iPlayer))
			{
				ncl_setfov(iPlayer, 90, 0.2)
			}
			else
			{
				send_msg_SetFOV(90, MSG_ONE, _, iPlayer)
			}
		}
		else
		{
			set_member(iPlayer, m_iFOV, 55)
			set_member(iPlayer, m_iClientFOV, 55)
			set_entvar(iPlayer, var_fov, 55)

			if (ncl_is_client_api_ready(iPlayer))
			{
				ncl_setfov(iPlayer, 55, 0.4)
			}
			else
			{
				send_msg_SetFOV(55, MSG_ONE, _, iPlayer)
			}
		}
	}

	return PLUGIN_CONTINUE
}

public fw_PlayerSpray(iPlayer)
{
	if (!is_entity_player(iPlayer) || !CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return PLUGIN_CONTINUE

	new iKnifeId = Player[iPlayer][PlrKnife]
	if (!is_valid_knife(iKnifeId) || !CheckKnifeFlag(iKnifeId, KNFF_ABIL1_TOGGLEABLE))
		return PLUGIN_CONTINUE

	new iRet
	ExecuteForward(forward_ability1_toggle, iRet, iPlayer)

	// Default behavior
	if (iRet == PLUGIN_CONTINUE)
	{
		new bool:bNewVal = !Player[iPlayer][PlrAbility1Disabled]
		Player[iPlayer][PlrAbility1Disabled] = bNewVal

		client_print(iPlayer, print_center, "%L", iPlayer, bNewVal ? "ABILITY_DISABLED_ON" : "ABILITY_DISABLED_OFF")
	}

	client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)

	return PLUGIN_HANDLED
}

public Ham_Vehicle_Use_Pre(iEnt, iCaller, iActivator, iUseType, Float:fValue)
{
	if (Player[iCaller][PlrCaptureType] != CAPTURE_NONE)
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public Ham_Player_GiveAmmo_Pre(iPlayer, iAmount, const szAmmo[])
{
	if (equal(szAmmo, "45acp") || equal(szAmmo, "9mm"))
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public Ham_C4_Spawn_Pre(iEnt)
{
	return HAM_SUPERCEDE
}

public logevent_StartRound()
{
	for (new iPlayer = 1, iTeam; iPlayer <= MaxClients; iPlayer++)
	{
		arrayset(Player[iPlayer][PlrDamageAcceptRnd], 0, MAX_PLAYERS + 1)

		if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		{
			iTeam = get_member(iPlayer, m_iTeam)
			if (Player[iPlayer][PlrTeam] != iTeam)
			{
				Player[iPlayer][PlrTeam] = iTeam
				ExecuteForward(forward_player_change_team, _, iPlayer, iTeam)
			}
		}
	}
}

public logevent_RoundEnd()
{
	if (task_exists(TASK_DARKNESS))
	{
		remove_task(TASK_DARKNESS)
		task_darkness(TASK_DARKNESS)
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrVisibility] == VIS_SHADOW)
		{
			if (PlayerF[i][PlrCloneTimeValue] > 0.0)
			{
				message_begin(MSG_ONE_UNRELIABLE, 108, {0,0,0}, i)
				write_short(0)
				message_end()

				PlayerF[i][PlrCloneTimeValue] = 0.0
			}

			player_remove_shadow(i)
		}

		player_unlevitation(i)
		player_uncapture(i)
	}

	g_bIsRoundEnded = true
}

public Message_ClCorpse()
{
	new iPlayer = get_msg_arg_int(12)

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ONLINE))
		return PLUGIN_HANDLED

	if (Player[iPlayer][PlrCorpseType] == CORP_CUSTOM)
	{
		Player[iPlayer][PlrCorpseType] = CORP_NORMAL
		return PLUGIN_HANDLED
	}

	player_hide(iPlayer)

	new Float:vOrigin[3], Float:vAngles[3], iSequence

	vOrigin[0] = get_msg_arg_int(2) / 128.0
	vOrigin[1] = get_msg_arg_int(3) / 128.0
	vOrigin[2] = get_msg_arg_int(4) / 128.0
	vAngles[0] = get_msg_arg_float(5)
	vAngles[1] = get_msg_arg_float(6)
	vAngles[2] = get_msg_arg_float(7)
	iSequence = get_msg_arg_int(9)

	new iCorpseEnt = corpse_create(vOrigin, vAngles, fmt(PLAYER_MODEL_PATH, CUSTOM_PLAYER_MODEL, CUSTOM_PLAYER_MODEL))
	if (iCorpseEnt == NULLENT)
		return PLUGIN_CONTINUE

	set_entvar(iCorpseEnt, var_rendermode, kRenderNormal)
	set_entvar(iCorpseEnt, var_sequence, iSequence)
	set_entvar(iCorpseEnt, var_animtime, 0.0)
	set_entvar(iCorpseEnt, var_skin, get_entvar(iPlayer, var_skin))
	set_entvar(iCorpseEnt, var_body, get_entvar(iPlayer, var_body))
	set_entvar(iCorpseEnt, var_nextthink, get_gametime() + CORPSES_LIFE)

	return PLUGIN_HANDLED
}

public Message_HealthInfo(iMsgId, iDest, iPlayer)
{
	if (!is_entity_player(iPlayer))
		return PLUGIN_CONTINUE

	if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
	{
		new iTarget = get_msg_arg_int(1)
		new iTargetHealth = get_user_health(iTarget)

		if (iTargetHealth > 0 && is_hp_scan_available(iPlayer))
			set_msg_arg_int(2, ARG_LONG, iTargetHealth)
	}

	return PLUGIN_CONTINUE
}

public Message_Radar()
{
	return PLUGIN_HANDLED
}

bool:is_hp_scan_available(iPlayer)
{
	return g_iHPScanItemId > -1
		&& player_item_get_value(iPlayer, g_iHPScanItemId) > -1
		&& player_item_get_mode(iPlayer, g_iHPScanItemId)
		&& !CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY)
}

corpse_create(Float:vOrigin[3], Float:vAngles[3], const szModel[])
{
	new iCorpseEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iCorpseEnt))
		return NULLENT

	engfunc(EngFunc_SetModel, iCorpseEnt, szModel)
	engfunc(EngFunc_SetOrigin, iCorpseEnt, vOrigin)

	set_entvar(iCorpseEnt, var_origin, vOrigin)
	set_entvar(iCorpseEnt, var_angles, vAngles)
	set_entvar(iCorpseEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iCorpseEnt, var_framerate, 1.0)
	set_entvar(iCorpseEnt, var_classname, _CLASSNAME_CORPSE)
	set_entvar(iCorpseEnt, var_impulse, IMPULSE_CORPSE)

	SetThink(iCorpseEnt, "corpse_think")

	return iCorpseEnt
}

public corpse_think(iEnt)
{
	rg_remove_entity(iEnt)
}

public fw_GameDesc()
{
	forward_return(FMV_STRING, "Epic Fun Knife")
	return FMRES_SUPERCEDE
}

public register_client_switches()
{
	new iSize = ArraySize(g_aNewWeapon)
	new szNewClassName[64]
	new szOldClassName[64]

	for (new i; i < iSize; i++)
	{
		ArrayGetString(g_aNewWeapon, i, szNewClassName, charsmax(szNewClassName))
		ArrayGetString(g_aOldWeapon, i, szOldClassName, charsmax(szOldClassName))
		register_clcmd(szNewClassName, fmt("switch_to_%s", szOldClassName))
	}
}

public switch_to_weapon_hegrenade(iPlayer) switch_item(iPlayer, SZ_WEAPON_HEGRENADE);
public switch_to_weapon_c4(iPlayer) switch_item(iPlayer, SZ_WEAPON_C4);
public switch_to_weapon_smokegrenade(iPlayer) switch_item(iPlayer, SZ_WEAPON_SMOKEGRENADE);
public switch_to_weapon_flashbang(iPlayer) switch_item(iPlayer, SZ_WEAPON_FLASHBANG);
public switch_to_weapon_knife(iPlayer) switch_item(iPlayer, SZ_WEAPON_KNIFE);
public switch_item(iPlayer, const szItem[]) engclient_cmd(iPlayer, szItem);

public set_custom_hud(iPlayer, const szOldWeapon[], const szNewWeapon[])
{
	new iOffset, i

	for (i = 0; i < sizeof WEAPONS_NAMES; i++)
	{
		if (equal(szOldWeapon, WEAPONS_NAMES[i]))
		{
			iOffset = i
			break
		}
	}

	message_begin(MSG_ONE, g_msgWeaponList, _, iPlayer)
	write_string(szNewWeapon)
	for (i = 0; i < 8; i++)
		write_byte(WEAPON_LIST_DATA[iOffset * 8 + i])
	message_end()
}

bool:player_set_weapon_hud(iPlayer, const szOldWeapon[], const szNewWeapon[])
{
	if (equal(szOldWeapon, szNewWeapon))
	{
		set_custom_hud(iPlayer, szOldWeapon, szOldWeapon)
		return true
	}

	new iSize = ArraySize(g_aNewWeapon)
	new szTmpBuffer[64]

	for (new i; i < iSize; i++)
	{
		ArrayGetString(g_aNewWeapon, i, szTmpBuffer, 63)

		if (equal(szNewWeapon, szTmpBuffer))
		{
			set_custom_hud(iPlayer, szOldWeapon, szNewWeapon)
			return true
		}
	}

	return false
}

bool:register_hud(const szOldWeapon[], const szNewWeapon[])
{
	for (new i; i < sizeof WEAPONS_NAMES; i++)
	{
		if (equal(szOldWeapon, WEAPONS_NAMES[i]))
		{
			ArrayPushString(g_aNewWeapon, szNewWeapon)
			ArrayPushString(g_aOldWeapon, szOldWeapon)

			return true
		}
	}

	return false
}

public callback_block_item()
{
	return ITEM_DISABLED
}

public clcmd_show_main_menu(iPlayer)
{
	if (!is_entity_player(iPlayer) || !CheckPlayerGameFlag(iPlayer, PLGF_IS_ONLINE))
		return PLUGIN_HANDLED

	new iMainMenu = menu_create(fmt("\yMain Menu [\r%s\y]", GAME_TAG),
		"handler_main_menu")

	menu_additem(iMainMenu, fmt("%L", iPlayer, "KNIVES_MENUNAME"))
	menu_additem(iMainMenu, fmt("%L", iPlayer, "SHOP_MENUNAME"))
	menu_additem(iMainMenu, fmt("%L", iPlayer, "TEAM_MENUNAME"))
	menu_additem(iMainMenu, fmt("%L", iPlayer, "CAM_MENU_EFK"))
	menu_addblank(iMainMenu, 0)

	static szTmpBuffer[LEN_MENU_ITEM_NAME], szNumStr[5]
	for (new i; i < g_iTotalMenuItems; i++)
	{
		formatex(szTmpBuffer, charsmax(szTmpBuffer), "%L", iPlayer, MenuItem[i][MItmName])
		num_to_str(i + 1000, szNumStr, charsmax(szNumStr))
		menu_additem(iMainMenu, szTmpBuffer, szNumStr)
	}

	num_to_str(g_iTotalMenuItems + 1000, szNumStr, charsmax(szNumStr))
	menu_additem(iMainMenu, fmt("%L", iPlayer, "SETTINGS_MENU"), szNumStr)

	menu_setprop(iMainMenu, MPROP_NEXTNAME, fmt("%L", iPlayer, "MENU_NEXT"))
	menu_setprop(iMainMenu, MPROP_BACKNAME, fmt("%L", iPlayer, "MENU_BACK"))
	menu_setprop(iMainMenu, MPROP_EXITNAME, fmt("%L", iPlayer, "MENU_EXIT"))
	menu_setprop(iMainMenu, MPROP_EXIT, MEXIT_ALL)

	menu_display(iPlayer, iMainMenu)

	return PLUGIN_HANDLED
}

public clcmd_show_knives_menu(iPlayer)
{
	show_knives_menu(iPlayer)
	return PLUGIN_HANDLED
}

show_knives_menu(iPlayer)
{
	if (!is_entity_player(iPlayer) || !CheckPlayerGameFlag(iPlayer, PLGF_IS_ONLINE))
		return

	new iKnivesMenu = menu_create(fmt("\yKnives Menu [\r%s\y]", GAME_TAG),
		"handler_knives_menu")

	static szTmpBuffer[64], szNumStr[4]
	for (new i; i < g_iTotalKnives; i++)
	{
		if (CheckKnifeFlag(i, KNFF_HIDDEN))
			continue

		formatex(szTmpBuffer, charsmax(szTmpBuffer), "%L", iPlayer, Knife[i][KNF_DESCRIPTION])
		num_to_str(i, szNumStr, charsmax(szNumStr))

		if (Knife[i][KNF_ACCESS_LEVEL] && Knife[i][KNF_ACCESS_LEVEL] > Player[iPlayer][PlrLevel])
		{
			replace_all(szTmpBuffer, charsmax(szTmpBuffer), "\r", "")
			replace_all(szTmpBuffer, charsmax(szTmpBuffer), "\y", "")
			format(szTmpBuffer, charsmax(szTmpBuffer), "\y[\r%i\y]\d %s", Knife[i][KNF_ACCESS_LEVEL],
				szTmpBuffer)
		}

		if (Player[iPlayer][PlrKnife] == i)
		{
			replace_all(szTmpBuffer, charsmax(szTmpBuffer), "\r", "")
			replace_all(szTmpBuffer, charsmax(szTmpBuffer), "\y", "")
			format(szTmpBuffer, charsmax(szTmpBuffer), "\d%s", szTmpBuffer)
			menu_additem(iKnivesMenu, szTmpBuffer, szNumStr, .callback=g_ptBlockItemCallback)
		}
		else
			menu_additem(iKnivesMenu, szTmpBuffer, szNumStr)
	}

	menu_setprop(iKnivesMenu, MPROP_NEXTNAME, fmt("%L", iPlayer, "MENU_NEXT"))
	menu_setprop(iKnivesMenu, MPROP_BACKNAME, fmt("%L", iPlayer, "MENU_BACK"))
	menu_setprop(iKnivesMenu, MPROP_EXITNAME, fmt("%L", iPlayer, "MENU_EXIT"))
	menu_setprop(iKnivesMenu, MPROP_EXIT, MEXIT_ALL)

	menu_display(iPlayer, iKnivesMenu)
}

public clcmd_show_shop_menu(iPlayer)
{
	show_shop_menu(iPlayer)
	return PLUGIN_HANDLED
}

show_shop_menu(iPlayer, iPage=0)
{
	if (!is_entity_player(iPlayer) || !CheckPlayerGameFlag(iPlayer, PLGF_IS_ONLINE))
		return

	new iShopMenu = menu_create(fmt("\yShop Menu [\r%s\y]", GAME_TAG), "handler_shop_menu")

	static szTmpBuffer[96], szItemId[3]

	for (new i; i < g_iTotalItems; i++)
	{
		if (Item[i][ItmCost] < 0)
			continue

		new bool:shouldBlockItem = false

		if (CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
		{
			generate_glitch_string(szTmpBuffer, random_num(4, 16))
			shouldBlockItem = true
		}
		else if (Item[i][ItmLevel] > Player[iPlayer][PlrLevel])
		{
			formatex(szTmpBuffer, charsmax(szTmpBuffer),
				"\y[\r%d lvl\y] \d%L", Item[i][ItmLevel], iPlayer, Item[i][ItmDescription])

			shouldBlockItem = true
		}
		else
		{
			new bool:isEnoughMoney = get_member(iPlayer, m_iAccount) >= Item[i][ItmCost]

			formatex(
				szTmpBuffer, charsmax(szTmpBuffer),
				"\y[\r$%d\y] %s%L",
				Item[i][ItmCost],
				isEnoughMoney ? "\y" : "\d",
				iPlayer, Item[i][ItmDescription]
			)

			shouldBlockItem = !isEnoughMoney
		}

		num_to_str(i, szItemId, charsmax(szItemId))
		menu_additem(iShopMenu, szTmpBuffer, szItemId,
			.callback=shouldBlockItem ? g_ptBlockItemCallback : -1)
	}

	menu_setprop(iShopMenu, MPROP_NEXTNAME, fmt("%L", iPlayer, "MENU_NEXT"))
	menu_setprop(iShopMenu, MPROP_BACKNAME, fmt("%L", iPlayer, "MENU_BACK"))
	menu_setprop(iShopMenu, MPROP_EXITNAME, fmt("%L", iPlayer, "MENU_EXIT"))
	menu_setprop(iShopMenu, MPROP_EXIT, MEXIT_ALL)

	menu_display(iPlayer, iShopMenu, iPage)
}

public handler_main_menu(iPlayer, iMenu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(iMenu)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	new szInfo[5]
	menu_item_getinfo(iMenu, item, .info=szInfo, .infolen=charsmax(szInfo))
	menu_destroy(iMenu)

	new iKey = str_to_num(szInfo)
	new mreturn

	for (new i; i < g_iTotalMenuItems; i++)
	{
		if (iKey == 1000 + i)
		{
			ExecuteForward(MenuItem[i][MItmCallback], mreturn, iPlayer)
			client_cmd(iPlayer, "spk %s", mreturn ? _SOUND_GUI_ERROR : _SOUND_GUI_CLICK)
			return PLUGIN_CONTINUE
		}
	}

	if (iKey == 1000 + g_iTotalMenuItems)
	{
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		show_settings_menu(iPlayer)
		return PLUGIN_CONTINUE
	}

	switch (item)
	{
		case 0: show_knives_menu(iPlayer)
		case 1: show_shop_menu(iPlayer)
		case 2: engclient_cmd(iPlayer, "chooseteam")
		case 3: show_camera_menu(iPlayer)
	}

	client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
	return PLUGIN_CONTINUE
}

public handler_knives_menu(iPlayer, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	new szInfo[5]
	menu_item_getinfo(menu, item, .info=szInfo, .infolen=charsmax(szInfo))
	menu_destroy(menu)

	new iKnifeId = str_to_num(szInfo)

	if (Knife[iKnifeId][KNF_ACCESS_LEVEL]
		&& Knife[iKnifeId][KNF_ACCESS_LEVEL] > Player[iPlayer][PlrLevel])
	{
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L",
			GAME_TAG, iPlayer, "KNIFE_LEVEL", Knife[iKnifeId][KNF_ACCESS_LEVEL])
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		return PLUGIN_CONTINUE
	}

	if (Player[iPlayer][PlrKnife] == iKnifeId)
	{
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L",
			GAME_TAG, iPlayer, "KNIFE_ALREADY_HAVE")
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		return PLUGIN_CONTINUE
	}

	if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
	{
		new Float:fChangeDelay = PlayerF[iPlayer][PlrKnifeChangeDelay] - get_gametime()
		if (!get_user_bypass_knf_change_delay(iPlayer) && fChangeDelay > 0.0)
		{
			client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L",
				GAME_TAG, iPlayer, "KNIFE_CHANGE_DELAY", floatround(fChangeDelay))
			client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
			return PLUGIN_CONTINUE
		}
	}

	change_knife_core(iPlayer, iKnifeId)
	client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)

	return PLUGIN_CONTINUE
}

public clcmd_toggle_knf_change_delay(iPlayer)
{
	if (~get_user_flags(iPlayer) & ADMIN_FLAG)
		return PLUGIN_HANDLED

	toggle_user_bypass_knf_change_delay(iPlayer)
	client_print(iPlayer, print_center, "*** Knife change delay: %s ***",
		get_user_bypass_knf_change_delay(iPlayer) ? "disabled" : "enabled")

	return PLUGIN_CONTINUE
}

bool:get_user_bypass_knf_change_delay(iPlayer)
{
	return Player[iPlayer][PlrIsBypassChangeKnfDelay]
}

set_user_bypass_knf_change_delay(iPlayer, bool:bStatus)
{
	Player[iPlayer][PlrIsBypassChangeKnfDelay] = bStatus
}

toggle_user_bypass_knf_change_delay(iPlayer)
{
	set_user_bypass_knf_change_delay(iPlayer, !get_user_bypass_knf_change_delay(iPlayer))
}

public handler_shop_menu(iPlayer, iMenu, iItem)
{
	if (iItem == MENU_EXIT || CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
	{
		menu_destroy(iMenu)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	new szItemId[3], iPage = iItem / 7
	menu_item_getinfo(iMenu, iItem, .info=szItemId, .infolen=charsmax(szItemId))
	menu_destroy(iMenu)

	if (!is_user_connected(iPlayer))
		return PLUGIN_HANDLED

	new iItemId = str_to_num(szItemId)

	if (Item[iItemId][ItmLevel] > Player[iPlayer][PlrLevel])
	{
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L",
			GAME_TAG, iPlayer, "ITEM_NEED_LEVEL", Item[iItemId][ItmLevel])
		show_shop_menu(iPlayer, iPage)
		return PLUGIN_HANDLED
	}

	new iPlayerMoney = get_member(iPlayer, m_iAccount)

	if (iPlayerMoney < Item[iItemId][ItmCost])
	{
		send_msg_BlinkAcct(2, MSG_ONE, _, iPlayer)

		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "ITEM_NOT_MONEY")
		show_shop_menu(iPlayer, iPage)
		return PLUGIN_HANDLED
	}

	new ItemGiveCode:iGiveRes = player_give_item(iPlayer, iItemId, iPlayer)

	if (iGiveRes > ITEM_NEXT_SPAWN)
	{
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		if (_:iGiveRes < sizeof LANG_ITEM_ERRORS)
			client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, LANG_ITEM_ERRORS[_:iGiveRes])
		show_shop_menu(iPlayer, iPage)
		return PLUGIN_HANDLED
	}

	rg_add_account(iPlayer, -Item[iItemId][ItmCost])
	client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)

	if (iGiveRes == ITEM_NEXT_SPAWN)
	{
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "ITEM_NEXT_SPAWN")
		show_shop_menu(iPlayer, iPage)
		return PLUGIN_HANDLED
	}

	client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, Item[iItemId][ItmChatDescription])

	if (Item[iItemId][ItmFlags] & ITMF_MENU_REDRAW)
		show_shop_menu(iPlayer, iPage)

	return PLUGIN_HANDLED
}

new bool:g_bShowingInvMenu[MAX_PLAYERS + 1]

public clcmd_show_items_menu(iPlayer)
{
	show_items_menu(iPlayer)
	return PLUGIN_HANDLED
}

redraw_items_menu_if_needed(iPlayer)
{
	if (g_bShowingInvMenu[iPlayer])
		show_items_menu(iPlayer)
}

show_items_menu(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return

	static szTmpBuffer[128]
	new i, iItemsNum, iItems[MAX_ITEMS]

	for (i = g_iTotalItems - 1; i >= 0; i--)
	{
		if ((Item[i][ItmFlags] & ITMF_INVENTORY) && player_item_get_value(iPlayer, i) != -1)
			iItems[iItemsNum++] = i
	}

	if (!iItemsNum)
	{
		if (CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
		{
			generate_glitch_string(szTmpBuffer, random_num(4, 16))
			client_print_color(iPlayer, print_team_default, "^4[%s] ^1%s", GAME_TAG, szTmpBuffer)
		}
		else
		{
			client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "INVENTORY_EMPTY")
		}

		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		return
	}

	static sMenuName[64]
	formatex(sMenuName, charsmax(sMenuName), "\yInventory [\r%s\y]", GAME_TAG)
	new iItemsMenu = menu_create(sMenuName, "handler_items_menu")
	new szNumStr[3], iItemId

	for (i = 0; i < iItemsNum; i++)
	{
		iItemId = iItems[i]

		if (CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
		{
			generate_glitch_string(szTmpBuffer, random_num(4, 16))
		}
		else if (player_item_get_mode(iPlayer, iItemId))
		{
			formatex(szTmpBuffer, charsmax(szTmpBuffer), "\y%L [\r%i\y]",
				iPlayer, Item[iItemId][ItmDescription], player_item_get_value(iPlayer, iItemId))
		}
		else
		{
			formatex(szTmpBuffer, charsmax(szTmpBuffer), "\d%L [%i]",
				iPlayer, Item[iItemId][ItmDescription], player_item_get_value(iPlayer, iItemId))
		}

		num_to_str(iItemId, szNumStr, charsmax(szNumStr))

		menu_additem(iItemsMenu, szTmpBuffer, szNumStr)
	}

	new sMenuProp[3][16]
	formatex(sMenuProp[0], 15, "%L", iPlayer, "MENU_NEXT")
	formatex(sMenuProp[1], 15, "%L", iPlayer, "MENU_BACK")
	formatex(sMenuProp[2], 15, "%L", iPlayer, "MENU_EXIT")

	menu_setprop(iItemsMenu, MPROP_NEXTNAME, sMenuProp[0])
	menu_setprop(iItemsMenu, MPROP_BACKNAME, sMenuProp[1])
	menu_setprop(iItemsMenu, MPROP_EXITNAME, sMenuProp[2])
	menu_setprop(iItemsMenu, MPROP_EXIT, MEXIT_ALL)

	menu_display(iPlayer, iItemsMenu)
	g_bShowingInvMenu[iPlayer] = true
}

public handler_items_menu(iPlayer, iMenu, iItem)
{
	if (iItem == MENU_EXIT || CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
	{
		menu_destroy(iMenu)
		g_bShowingInvMenu[iPlayer] = false

		return PLUGIN_HANDLED
	}

	new szData[3], szName[2], iAccess, iCallback
	menu_item_getinfo(iMenu, iItem, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback)
	menu_destroy(iMenu)

	if (!is_user_connected(iPlayer))
		return PLUGIN_HANDLED

	new iItemId = str_to_num(szData)

	if (!(Item[iItemId][ItmFlags] & ITMF_INVENTORY) || player_item_get_value(iPlayer, iItemId) == -1)
	{
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		return PLUGIN_CONTINUE
	}

	new bool:bMode = !player_item_get_mode(iPlayer, iItemId)
	if (player_item_set_enabled(iPlayer, iItemId, bMode))
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
	else
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)

	show_items_menu(iPlayer)
	return PLUGIN_CONTINUE
}

change_knife_core(iPlayer, iKnifeId, bool:bChangeDelay=true)
{
	new iChangeReturn = PLUGIN_CONTINUE
	ExecuteForward(forward_core_change_knife_pre, iChangeReturn, iPlayer, iKnifeId)
	if (iChangeReturn == PLUGIN_HANDLED)
		return -1

	if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
	{
		new iPrevKnifeId = Player[iPlayer][PlrKnife]

		new Float:fChargeKoef = floatmin(1.0, KnifeF[iKnifeId][KNF_ABILITY2_CHARGE] / KnifeF[iPrevKnifeId][KNF_ABILITY2_CHARGE])
		PlayerF[iPlayer][PlrAbility2Charge] *= fChargeKoef
		fChargeKoef = floatmin(1.0, KnifeF[iKnifeId][KNF_ABILITY3_CHARGE] / KnifeF[iPrevKnifeId][KNF_ABILITY3_CHARGE])
		PlayerF[iPlayer][PlrAbility3Charge] *= fChargeKoef
		fChargeKoef = floatmin(1.0, KnifeF[iKnifeId][KNF_ABILITY4_CHARGE] / KnifeF[iPrevKnifeId][KNF_ABILITY4_CHARGE])
		PlayerF[iPlayer][PlrAbility4Charge] *= fChargeKoef

		new Float:fHp = get_entvar(iPlayer, var_health)

		fHp *= KnifeF[iKnifeId][KNF_MAX_HEALTH] / KnifeF[iPrevKnifeId][KNF_MAX_HEALTH]
		set_entvar(iPlayer, var_health, floatmin(floatround(floatmax(fHp, 1.0), floatround_floor) + 0.0, MAX_PLAYER_HEALTH))
		set_entvar(iPlayer, var_max_health, KnifeF[iKnifeId][KNF_MAX_HEALTH])

		PlayerF[iPlayer][PlrRushTime] = 0.0
		player_unlevitation(iPlayer)

		new Float:fOldKnifeMaxSpeed = player_get_knife_maxspeed(iPlayer)

		set_knife_params(iPlayer, iKnifeId)

		apply_change_knife_maxspeed(iPlayer, fOldKnifeMaxSpeed)
		player_update_gravity(iPlayer)

		Player[iPlayer][PlrAbility1Disabled] = false

		new Float:fChangeDelay = Player[iPlayer][PlrLevel] ? 140.0 : 40.0

		if (bChangeDelay)
			PlayerF[iPlayer][PlrKnifeChangeDelay] = get_gametime() + fChangeDelay
	}
	else
		set_knife_params(iPlayer, iKnifeId)

	client_print_color(iPlayer, print_team_default, "%L", iPlayer, Knife[iKnifeId][KNF_CHAT_DESCRIPTION])

	PlayerF[iPlayer][PlrCritChance] = 0.0

	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
		case VIS_CLONE: player_remove_clone(iPlayer)
		case VIS_SHADOW: player_remove_shadow(iPlayer)
	}

	if (Player[iPlayer][PlrVision] != VISION_BLIND)
		Player[iPlayer][PlrVision] = CheckKnifeFlag(iKnifeId, KNFF_FULL_VISION) ? VISION_FULL : VISION_NORMAL

	if (-1 < g_iDarknessTeam && g_iDarknessTeam <= 2)
	{
		if (Player[iPlayer][PlrVision] == VISION_NORMAL && g_iDarknessTeam == Player[iPlayer][PlrTeam])
			Player[iPlayer][PlrVision] = VISION_NIGHT
	}

	ExecuteForward(forward_core_change_knife_post, _, iPlayer, iKnifeId)

	player_deploy_knife(iPlayer)

	return iKnifeId
}

public set_params_after_apawn(iPlayer)
{
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return

	player_update_gravity(iPlayer)

	engclient_cmd(iPlayer, SZ_WEAPON_KNIFE)

	new Flaot:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)

	PlayerF[iPlayer][PlrNextSpawnChargeCheck] = get_gametime() + 0.1
}

bool:spawn_abil1_charge_check(iPlayer)
{
	new Float:fGameTime = get_gametime()

	if (PlayerF[iPlayer][PlrNextSpawnChargeCheck] == 0.0
		|| fGameTime > PlayerF[iPlayer][PlrSpawnProtectionTime]
		|| fGameTime < PlayerF[iPlayer][PlrNextSpawnChargeCheck]
	)
		return false

	new Float:vOrigin[3], i
	get_entvar(iPlayer, var_origin, vOrigin)

	while ((i = engfunc(EngFunc_FindEntityInSphere, i, vOrigin, FIND_SPAWN_ENEMY_RANGE)))
	{
		if (i > MaxClients)
			break

		if (CheckPlayerGameFlag(i, PLGF_IS_ALIVE) && Player[iPlayer][PlrTeam] != Player[i][PlrTeam])
		{
			PlayerF[iPlayer][PlrAbility1Charge] = 100.0
			PlayerF[iPlayer][PlrNextSpawnChargeCheck] = 0.0
			return true
		}
	}

	return false
}

player_set_crosshair(iPlayer, KnifeCrosshair:iCrosshair)
{
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ONLINE))
		return

	if (Player[iPlayer][PlrCrosshair] == iCrosshair)
		return

	if (iCrosshair == CROSSHAIR_HIDDEN)
	{
		message_begin(MSG_ONE, g_msgHideWeapon, _, iPlayer)
		write_byte(1>>7)
		message_end()
	}
	else
	{
		static szSpriteTxt[LEN_CLASS_NAME + 4]

		switch (iCrosshair)
		{
			case CROSSHAIR_DEFAULT: formatex(szSpriteTxt, charsmax(szSpriteTxt), "weapon_next21_cross_def")
			case CROSSHAIR_CANNOT: formatex(szSpriteTxt, charsmax(szSpriteTxt), "weapon_next21_cross_cnot")
			case CROSSHAIR_FAR: formatex(szSpriteTxt, charsmax(szSpriteTxt), "weapon_next21_cross_far")
			case CROSSHAIR_TIME: formatex(szSpriteTxt, charsmax(szSpriteTxt), "weapon_next21_cross_time")
			case CROSSHAIR_OK: formatex(szSpriteTxt, charsmax(szSpriteTxt), "weapon_next21_cross_ok")
			case CROSSHAIR_HELP: formatex(szSpriteTxt, charsmax(szSpriteTxt), "weapon_next21_cross_help")
		}

		player_set_weapon_hud(iPlayer, SZ_WEAPON_C4, szSpriteTxt)

		message_begin(MSG_ONE, g_msgHideWeapon, _, iPlayer)
		write_byte(1<<7)
		message_end()
	}

	Player[iPlayer][PlrCrosshair] = iCrosshair
}

set_knife_params(iPlayer, iKnifeId)
{
	PlayerF[iPlayer][PlrMaxHP] = KnifeF[iKnifeId][KNF_MAX_HEALTH]
	PlayerF[iPlayer][PlrMaxDamage] = KnifeF[iKnifeId][KNF_MAX_DAMAGE]
	PlayerF[iPlayer][PlrMinDamage] = KnifeF[iKnifeId][KNF_MIN_DAMAGE]
	PlayerF[iPlayer][PlrAbility1MinDist] = KnifeF[iKnifeId][KNF_ABILITY1_MIN_DIST]
	PlayerF[iPlayer][PlrAbility1MaxDist] = KnifeF[iKnifeId][KNF_ABILITY1_MAX_DIST]
	Player[iPlayer][PlrAbility1Type] = Knife[iKnifeId][KNF_ABILITY1_TYPE]

	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrVisibility] != VIS_CLONE || Player[i][PlrClone] != iPlayer)
			continue

		if (get_user_weapon(i) != CSW_KNIFE)
			continue

		set_pdata_string(i, 492 * 4, ANIM_EXTENSIONS[Knife[iKnifeId][KNF_ANIM_EXT]], -1, 5 * 4)
	}

	Player[iPlayer][PlrKnife] = iKnifeId
}

player_reset_abil1_charge(iPlayer)
{
	new iKnifeId = Player[iPlayer][PlrKnife]

	new iChargeBooster = player_item_get_value(iPlayer, g_iChargeBoosterItemId)
	if (g_iChargeBoosterItemId > -1 && iChargeBooster > 0
		&& player_item_get_mode(iPlayer, g_iChargeBoosterItemId)
		&& !g_bIsRoundEnded
		&& !CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
	{
		PlayerF[iPlayer][PlrAbility1Charge] = 100.0 * KnifeF[iKnifeId][KNF_CHARGE_BOOST_COEF]
		if (--iChargeBooster == 0)
		{
			iChargeBooster = -1
			client_print(iPlayer, print_center, "%L", iPlayer, "CHARGEBOOSTER_EXHAUSTED")
		}
		player_item_set_value(iPlayer, g_iChargeBoosterItemId, iChargeBooster)
	}
	else
		PlayerF[iPlayer][PlrAbility1Charge] = 0.0

	PlayerF[iPlayer][PlrAbility1LastChange] = get_gametime()
}

get_aim_data(iPlayer, Float:vOrigin[3]=NULL_VECTOR, Float:vAimOrigin[3]=NULL_VECTOR, Float:vAimNormal[3]=NULL_VECTOR)
{
	static Float:vStartOrigin[3], Float:vEndOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	get_entvar(iPlayer, var_view_ofs, vEndOrigin)
	xs_vec_add(vOrigin, vEndOrigin, vStartOrigin)

	get_entvar(iPlayer, var_v_angle, vEndOrigin)
	engfunc(EngFunc_MakeVectors, vEndOrigin)
	global_get(glb_v_forward, vEndOrigin)
	xs_vec_mul_scalar(vEndOrigin, 8192.0, vEndOrigin)
	xs_vec_add(vStartOrigin, vEndOrigin, vEndOrigin)

	engfunc(EngFunc_TraceLine, vStartOrigin, vEndOrigin, IGNORE_MISSILE | IGNORE_MONSTERS, iPlayer, 0)
	get_tr2(0, TR_vecEndPos, vAimOrigin)
	get_tr2(0, TR_vecPlaneNormal, vAimNormal)
}

player_deploy_knife(iPlayer)
{
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return

	if (is_user_bot(iPlayer))
		return

	engclient_cmd(iPlayer, SZ_WEAPON_KNIFE)

	new iWeapon = get_active_weapon(iPlayer)
	if (!is_nullent(iWeapon))
		ExecuteHamB(Ham_Item_Deploy, iWeapon)

	player_set_weapon_hud(iPlayer, SZ_WEAPON_KNIFE, Knife[Player[iPlayer][PlrKnife]][KNF_NAME])
}

choose_random_knife(iPlayer)
{
	new Array:aAvailableKnives = ArrayCreate()
	for (new iKnifeId; iKnifeId < g_iTotalKnives; iKnifeId++)
	{
		if (check_knife_access(iPlayer, iKnifeId))
			ArrayPushCell(aAvailableKnives, iKnifeId)
	}
	new iAvailableKnivesNum = ArraySize(aAvailableKnives)

	new iAvailableKnifeId
	if (iAvailableKnivesNum > 0)
		iAvailableKnifeId = ArrayGetCell(aAvailableKnives, random(iAvailableKnivesNum))

	ArrayDestroy(aAvailableKnives)

	return iAvailableKnifeId
}

bool:check_knife_access(iPlayer, iKnifeId)
{
	return Knife[iKnifeId][KNF_ACCESS_LEVEL] <= Player[iPlayer][PlrLevel]
		&& !CheckKnifeFlag(iKnifeId, KNFF_HIDDEN)
}

gen_death_reason(iVictim, iAttacker, iFlags)
{
	if (Player[iVictim][PlrDeathReasonText][0])
		return

	if (iFlags & DMG_FALL)
	{
		player_set_death_reason(iVictim, "DEATH_REASON_FALL")
		return
	}

	if (iFlags & DMG_DROWN)
	{
		player_set_death_reason(iVictim, "DEATH_REASON_DROWN")
		return
	}

	if (iFlags & DMG_GRENADE)
	{
		player_set_death_reason(iVictim, "DEATH_REASON_EXPLODE")
		return
	}

	if (iFlags & DMG_BURN)
	{
		player_set_death_reason(iVictim, "DEATH_REASON_BURNED")
		return
	}

	if (is_entity_player(iAttacker))
	{
		if (iFlags & DMG_BULLET && Player[iAttacker][PlrTeam] != Player[iVictim][PlrTeam])
		{
			if (get_user_weapon(iAttacker) != CSW_KNIFE)
			{
				player_set_death_reason(iVictim, "DEATH_REASON_SHOOT")
				return
			}

			if (get_member(iVictim, m_LastHitGroup) == HIT_HEAD)
			{
				player_set_death_reason(iVictim, "DEATH_REASON_STAB_HEAD")
				return
			}

			if (Player[iVictim][PlrHitGroupAttacked] == KHITGROUP_BACK)
			{
				player_set_death_reason(iVictim, "DEATH_REASON_STAB_BACK")
				return
			}

			player_set_death_reason(iVictim, "DEATH_REASON_STAB")
			return
		}
	}

	player_set_death_reason(iVictim, "DEATH_REASON_WASTED")
}

show_death_reason(iPlayer)
{
	if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE) || Player[iPlayer][PlrDeathReasonApplied])
		return

	set_dhudmessage(255, 0, 0, -1.0, 0.3, 0, 0.0, 5.0, 1.0, 1.0)
	show_dhudmessage(iPlayer, "%L", iPlayer, Player[iPlayer][PlrDeathReasonText])
	Player[iPlayer][PlrDeathReasonApplied] = true
}

player_set_death_reason(iPlayer, szDeathReason[])
{
	if (!Player[iPlayer][PlrDeathReasonApplied])
		copy(Player[iPlayer][PlrDeathReasonText], LEN_DEATH_REASON - 1, szDeathReason)
}

accept_dealt_damage(iVictim, iAttacker)
{
	new iHealthTmp = Player[iVictim][PlrHealthTmp]
	if (iHealthTmp > 0)
	{
		if (is_entity_player(iAttacker) && iAttacker != iVictim)
		{
			new iHealth = pev(iVictim, pev_health)
			if (iHealth > 0) iHealthTmp -= iHealth

			Player[iAttacker][PlrDamageAccept][iVictim] += iHealthTmp
			Player[iAttacker][PlrDamageAcceptRnd][iVictim] += iHealthTmp
		}

		Player[iVictim][PlrHealthTmp] = 0
	}
}

get_kill_assistant(iPlayer, iAttacker)
{
	new iAssistant = 0

	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == iAttacker)
			continue

		if ((!iAssistant || Player[i][PlrDamageAccept][iPlayer] > Player[iAssistant][PlrDamageAccept][iPlayer])
			&& float(Player[i][PlrDamageAccept][iPlayer]) * 0.01 >= KILL_ASSIST_KOEF)
		{
			iAssistant = i
		}
	}

	return iAssistant
}

get_heal_assistant(iPlayer)
{
	if (!is_entity_player(iPlayer))
		return 0

	new iAssistant = 0

	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == iPlayer)
			continue

		if ((!iAssistant || PlayerF[iPlayer][PlrHealedBy][i] > PlayerF[iPlayer][PlrHealedBy][iAssistant])
			&& PlayerF[iPlayer][PlrHealedBy][i] > HEAL_ASSIST_MIN_HP)
		{
			iAssistant = i
		}
	}

	return iAssistant
}

player_item_get_value(iPlayer, iItemId)
{
	return Player[iPlayer][PlrItemValue][iItemId]
}

player_item_set_value(iPlayer, iItemId, iValue)
{
	if (Player[iPlayer][PlrItemValue][iItemId] == iValue)
		return iValue

	Player[iPlayer][PlrItemValue][iItemId] = iValue
	redraw_items_menu_if_needed(iPlayer)

	return iValue
}

player_item_sub_value(iPlayer, iItemId, iSub)
{
	return player_item_set_value(iPlayer, iItemId, max(player_item_get_value(iPlayer, iItemId) - iSub, 0))
}

bool:player_item_set_enabled(iPlayer, iItemId, bool:bEnabled)
{
	if (player_item_get_mode(iPlayer, iItemId) == bEnabled)
		return false

	new pCallback = Item[iItemId][ItmModeCallback]
	if (pCallback)
	{
		new iRes = PLUGIN_CONTINUE
		ExecuteForward(pCallback, iRes, iPlayer, bEnabled, g_bIsRoundEnded)
		if (iRes != PLUGIN_CONTINUE)
			return false
	}

	if (bEnabled)
		Player[iPlayer][PlrItemMode] |= (1<<iItemId)
	else
		Player[iPlayer][PlrItemMode] &= ~(1<<iItemId)

	redraw_items_menu_if_needed(iPlayer)
	return true
}

bool:player_item_get_mode(iPlayer, iItemId)
{
	return bool:(Player[iPlayer][PlrItemMode] & (1<<iItemId))
}

ItemGiveCode:player_give_item(iPlayer, iItemId, iSenderImpulse)
{
	new iGiveRes
	ExecuteForward(Item[iItemId][ItmGiveCallback], iGiveRes, iPlayer, iSenderImpulse)
	return ItemGiveCode:iGiveRes
}

public clcmd_show_camera_menu(iPlayer)
{
	show_camera_menu(iPlayer)
	return PLUGIN_HANDLED
}

show_camera_menu(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return

	new iMenu = menu_create(fmt("\y%L", iPlayer, "CAM_MENU"), "cammenu_command")
	menu_additem(iMenu, fmt("%L", iPlayer, "CAM_1ST"))
	menu_additem(iMenu, fmt("%L", iPlayer, "CAM_3RD"))
	menu_additem(iMenu, fmt("%L", iPlayer, "CAM_BACK"))
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", iPlayer, "MENU_EXIT"))
	menu_display(iPlayer, iMenu)
}

public cammenu_command(iPlayer, iMenu, iItem)
{
	menu_destroy(iMenu)

	if (iItem == MENU_EXIT)
	{
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	Player[iPlayer][PlrCameraMode] = iItem

	if (!Player[iPlayer][PlrCustomCameraEnt])
		player_set_camera(iPlayer, iItem)

	if (iItem != CAMERA_MODE_1ST)
		Player[iPlayer][PlrFavCamera] = iItem

	client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
	show_camera_menu(iPlayer)

	return PLUGIN_HANDLED
}

public quick_camera_change(iPlayer)
{
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return PLUGIN_HANDLED

	new iCameraMode = Player[iPlayer][PlrCameraMode] == CAMERA_MODE_1ST ? Player[iPlayer][PlrFavCamera] : CAMERA_MODE_1ST

	if (!Player[iPlayer][PlrCustomCameraEnt])
		player_set_camera(iPlayer, iCameraMode)
	Player[iPlayer][PlrCameraMode] = iCameraMode

	client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
	return PLUGIN_HANDLED
}

player_set_camera(iPlayer, iCameraMode, bool:bAttachView=true)
{
	if (iCameraMode == CAMERA_MODE_1ST)
	{
		if (bAttachView)
			fm_attach_view(iPlayer, iPlayer)

		new iCameraEnt = Player[iPlayer][PlrCameraEnt]
		if (!is_nullent(iCameraEnt))
		{
			set_entvar(iCameraEnt, var_flags, FL_KILLME)
			Player[iPlayer][PlrCameraEnt] = NULLENT
		}
	}
	else
	{
		new iCameraEnt = Player[iPlayer][PlrCameraEnt]
		if (is_nullent(iCameraEnt))
		{
			iCameraEnt = rg_create_entity(SZ_TRIGGER_CAMERA)
			if (is_nullent(iCameraEnt))
				return

			Player[iPlayer][PlrCameraEnt] = iCameraEnt

			engfunc(EngFunc_SetModel, iCameraEnt, CAMERA_MODEL)
			set_entvar(iCameraEnt, var_camera_owner, iPlayer)
			set_entvar(iCameraEnt, var_classname, CLASSNAME_CAMERA)
			set_entvar(iCameraEnt, var_solid, SOLID_NOT)
			set_entvar(iCameraEnt, var_movetype, MOVETYPE_NOCLIP)
			set_entvar(iCameraEnt, var_rendermode, kRenderTransTexture)
			set_entvar(iCameraEnt, var_target, "")

			SetThink(iCameraEnt, "fw_CameraThink")
			set_entvar(iCameraEnt, var_nextthink, get_gametime())
		}

		set_entvar(iCameraEnt, var_camera_mode, iCameraMode)
		fm_attach_view(iPlayer, iCameraEnt)
	}
}

public fw_CameraThink(iCameraEnt)
{
	static iPlayer, iCameraMode,
		Float:vPlayerOrigin[3], Float:vCameraOrigin[3], Float:vAngles[3],
		Float:vForward[3], Float:vDir[3], Float:fFraction

	iPlayer = get_entvar(iCameraEnt, var_camera_owner)
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return

	get_entvar(iPlayer, var_origin, vPlayerOrigin)
	get_entvar(iPlayer, var_view_ofs, vAngles)
	vPlayerOrigin[2] += vAngles[2]
	get_entvar(iPlayer, var_v_angle, vAngles)

	iCameraMode = get_entvar(iCameraEnt, var_camera_mode)
	switch (iCameraMode)
	{
		case CAMERA_MODE_3RD:
		{
			angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForward)

			vDir[0] = -vForward[0] * CAMERA_3RD_DISTANCE
			vDir[1] = -vForward[1] * CAMERA_3RD_DISTANCE
			vDir[2] = -vForward[2] * CAMERA_3RD_DISTANCE
		}
		case CAMERA_MODE_BACK:
		{
			angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForward)

			vDir[0] = vForward[0] * CAMERA_3RD_DISTANCE
			vDir[1] = vForward[1] * CAMERA_3RD_DISTANCE
			vDir[2] = -vForward[2] * CAMERA_3RD_DISTANCE

			if (vAngles[1] >= 0.0)
				vAngles[1] -= 180.0
			else
				vAngles[1] += 180.0
		}
	}

	xs_vec_add(vPlayerOrigin, vDir, vCameraOrigin)

	engfunc(EngFunc_TraceLine, vPlayerOrigin, vCameraOrigin, IGNORE_MONSTERS, iPlayer, 0)
	get_tr2(0, TR_flFraction, fFraction)
	if (fFraction != 1.0)
	{
		xs_vec_mul_scalar(vDir, fFraction, vDir)
		xs_vec_add(vPlayerOrigin, vDir, vCameraOrigin)
	}

	set_entvar(iCameraEnt, var_origin, vCameraOrigin)
	set_entvar(iCameraEnt, var_angles, vAngles)
	set_entvar(iCameraEnt, var_nextthink, get_gametime())
}

on_off_label(langKeyFor, state_)
{
	static buffer[32]
	if (state_) formatex(buffer, charsmax(buffer), "\y[%L]", langKeyFor, "ON")
	else formatex(buffer, charsmax(buffer), "\r[%L]", langKeyFor, "OFF")

	return buffer
}

show_settings_menu(iPlayer, iPage=0)
{
	new iMenu = menu_create(fmt("\y%L", iPlayer, "SETTINGS_MENU"), "setmenu_handler")
	new iOptionsFlags = Player[iPlayer][PlrOptionsFlags]

	menu_additem(iMenu, fmt("%L %s", iPlayer, "SETTINGS_HIDEHATS",
		on_off_label(iPlayer, ~iOptionsFlags & OPTION_HIDE_HATS)))

	menu_additem(iMenu, fmt("%L %s", iPlayer, "SETTINGS_LOWPOLY_PLAYER",
		on_off_label(iPlayer, iOptionsFlags & OPTION_LOWPOLY_PLAYER)))

	menu_additem(iMenu, fmt("%L %s", iPlayer, "SETTINGS_DISABLE_PARTICLES",
		on_off_label(iPlayer, ~iOptionsFlags & OPTION_DISABLE_PARTICLES)))

	menu_additem(iMenu, fmt("%L %s", iPlayer, "SETTINGS_VIEW_MODEL_FX",
		on_off_label(iPlayer, iOptionsFlags & OPTION_VIEW_MODEL_FX)))

	menu_additem(iMenu, fmt("%L %s", iPlayer, "SETTINGS_FORBID_TEAMMATES_HELP",
		on_off_label(iPlayer, ~iOptionsFlags & OPTION_FORBID_TEAMMATES_HELP)))

	menu_additem(iMenu, fmt("%L %s", iPlayer, "SETTINGS_DAMAGER",
		on_off_label(iPlayer, iOptionsFlags & OPTION_DAMAGER)))

	menu_additem(iMenu, fmt("%L %s", iPlayer, "SETTINGS_LIMITED_VAMP",
		on_off_label(iPlayer, iOptionsFlags & OPTION_LIMITED_VAMP)))

	menu_additem(iMenu, fmt("%L %s", iPlayer, "SETTINGS_ONE_DIRECTION_LJ",
		on_off_label(iPlayer, iOptionsFlags & OPTION_ONE_DIRECTION_LJ)))

	menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(iMenu, MPROP_NEXTNAME, fmt("%L", iPlayer, "MENU_NEXT"))
	menu_setprop(iMenu, MPROP_BACKNAME, fmt("%L", iPlayer, "MENU_BACK"))
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", iPlayer, "MENU_EXIT"))
	menu_display(iPlayer, iMenu, iPage)
	return PLUGIN_HANDLED
}

public setmenu_handler(iPlayer, iMenu, iItem)
{
	menu_destroy(iMenu)

	if (iItem == MENU_EXIT)
	{
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	if (iItem < 0)
		return PLUGIN_HANDLED

	new iOption = 1 << iItem
	if (Player[iPlayer][PlrOptionsFlags] & iOption)
		Player[iPlayer][PlrOptionsFlags] &= ~iOption
	else
		Player[iPlayer][PlrOptionsFlags] |= iOption

	new iOptionsFlags = Player[iPlayer][PlrOptionsFlags]

	ExecuteForward(forward_player_options_update, _, iPlayer, iOptionsFlags)

	new szAuthId[24]
	get_user_authid(iPlayer, szAuthId, charsmax(szAuthId))

	nvault_set(g_nvSettings, szAuthId, fmt("%i", iOptionsFlags))

	client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
	show_settings_menu(iPlayer, iItem / 7)

	return PLUGIN_HANDLED
}

player_reset_visibility(iPlayer)
{
	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
		case VIS_GLOW: player_remove_glow(iPlayer)
		case VIS_CLONE: player_remove_clone(iPlayer)
		case VIS_SHADOW: player_remove_shadow(iPlayer)
	}
}

player_reset_vision(iPlayer)
{
	if (Player[iPlayer][PlrVision] == VISION_BLIND)
		screenfades_out(iPlayer, true)

	new iKnifeId = Player[iPlayer][PlrKnife]
	Player[iPlayer][PlrVision] = (is_valid_knife(iKnifeId) && CheckKnifeFlag(iKnifeId, KNFF_FULL_VISION)) ? VISION_FULL : VISION_NORMAL

	if (-1 < g_iDarknessTeam && g_iDarknessTeam <= 2)
	{
		if (Player[iPlayer][PlrVision] == VISION_NORMAL && g_iDarknessTeam == Player[iPlayer][PlrTeam])
			Player[iPlayer][PlrVision] = VISION_NIGHT
	}
}

new const Float:fUnstuckSize[][3] = {
	{0.0, 0.0, 2.2}, {0.0, 0.0, -2.2}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.2}, {2.0, 2.0, 2.2}, {2.0, -2.0, 2.2}, {2.0, 2.0, -2.2}, {-2.0, -2.0, 2.2}, {2.0, -2.0, -2.2}, {-2.0, 2.0, -2.2}, {-2.0, -2.0, -2.2},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 6.0}, {0.0, 0.0, -6.0}, {0.0, 6.0, 0.0}, {0.0, -6.0, 0.0}, {6.0, 0.0, 0.0}, {-6.0, 0.0, 0.0}, {-6.0, 6.0, 6.0}, {6.0, 6.0, 6.0}, {6.0, -6.0, 6.0}, {6.0, 6.0, -6.0}, {-6.0, -6.0, 6.0}, {6.0, -6.0, -6.0}, {-6.0, 6.0, -6.0}, {-6.0, -6.0, -6.0},
	{0.0, 0.0, 8.0}, {0.0, 0.0, -8.0}, {0.0, 8.0, 0.0}, {0.0, -8.0, 0.0}, {8.0, 0.0, 0.0}, {-8.0, 0.0, 0.0}, {-8.0, 8.0, 8.0}, {8.0, 8.0, 8.0}, {8.0, -8.0, 8.0}, {8.0, 8.0, -8.0}, {-8.0, -8.0, 8.0}, {8.0, -8.0, -8.0}, {-8.0, 8.0, -8.0}, {-8.0, -8.0, -8.0},
	{0.0, 0.0, 10.0}, {0.0, 0.0, -10.0}, {0.0, 10.0, 0.0}, {0.0, -10.0, 0.0}, {10.0, 0.0, 0.0}, {-10.0, 0.0, 0.0}, {-10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}, {10.0, -10.0, 10.0}, {10.0, 10.0, -10.0}, {-10.0, -10.0, 10.0}, {10.0, -10.0, -10.0}, {-10.0, 10.0, -10.0}, {-10.0, -10.0, -10.0}
}

bool:player_check_stuck(iPlayer)
{
	new Float:vOrigin[3], Float:vMins[3], Float:vVec[3], iHull, i

	get_entvar(iPlayer, var_origin, vOrigin)

	iHull = get_entvar(iPlayer, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
	if (!is_hull_vacant(vOrigin, iHull, iPlayer)/* && get_entvar(iPlayer, var_movetype) != MOVETYPE_NOCLIP && !(get_entvar(iPlayer, var_solid) & SOLID_NOT)*/)
	{
		get_entvar(iPlayer, var_mins, vMins)
		new iSizeNum = sizeof fUnstuckSize
		for (i = 0; i < iSizeNum; i++)
		{
			vVec[0] = vOrigin[0] - vMins[0] * fUnstuckSize[i][0]
			vVec[1] = vOrigin[1] - vMins[1] * fUnstuckSize[i][1]
			vVec[2] = vOrigin[2] - vMins[2] * fUnstuckSize[i][2]

			if (is_hull_vacant(vVec, iHull, iPlayer))
			{
				engfunc(EngFunc_SetOrigin, iPlayer, vVec)
				set_entvar(iPlayer, var_origin, vVec)
				return true
			}
		}
	}

	return false
}

bool:is_hull_vacant(Float:vOrigin[3], iHullType, iEnt)
{
	engfunc(EngFunc_TraceHull, vOrigin, vOrigin, DONT_IGNORE_MONSTERS, iHullType, iEnt, 0)
	return !get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)
}

validate_levitation_dir(Float:fAngle1, Float:fAngle2)
{
	static Float:l, Float:r
	if (fAngle1 > fAngle2)
	{
		l = fAngle1 - fAngle2
		r = fAngle2 - fAngle1 + 360.0
	}
	else
	{
		r = fAngle2 - fAngle1
		l = fAngle1 - fAngle2 + 360.0
	}

	if (r < 60.0 || l < 60.0)
		return LEVITATION_FORWARD

	return 0
}

Float:player_get_knife_maxspeed(iPlayer)
{
	new iKnifeId = Player[iPlayer][PlrKnife]

	if (Player[iPlayer][PlrVisibility] == VIS_CLONE)
	{
		new iClone = Player[iPlayer][PlrClone]
		new iCloneKnifeId = Player[iClone][PlrKnife]
		return floatmin(KnifeF[iKnifeId][KNF_MAX_SPEED], KnifeF[iCloneKnifeId][KNF_MAX_SPEED])
	}

	return KnifeF[iKnifeId][KNF_MAX_SPEED]
}

apply_change_knife_maxspeed(iPlayer, Float:fOldKnifeMaxSpeed)
{
	new Float:fDifSpeed = player_get_knife_maxspeed(iPlayer) - fOldKnifeMaxSpeed
	for (new i, Float:fSlowSpeed; i < 3; i++)
	{
		if (PlayerF[iPlayer][PlrSlowTime][i] == 0.0)
			continue

		fSlowSpeed = PlayerF[iPlayer][PlrSlowSpeed][i] + fDifSpeed
		if (fSlowSpeed < MIN_PLAYER_SPEED)
			fSlowSpeed = MIN_PLAYER_SPEED
		PlayerF[iPlayer][PlrSlowSpeed][i] = fSlowSpeed
	}

	if (PlayerF[iPlayer][PlrFrozen] == 0.0 && Player[iPlayer][PlrCaptureType] == CAPTURE_NONE)
		player_update_maxspeed(iPlayer)
}

player_drop_train(iPlayer)
{
	if (get_member(iPlayer, m_iTrain) > 0)
	{
		set_member(iPlayer, m_iTrain, 0xc0)
		set_member(iPlayer, m_afPhysicsFlags, get_member(iPlayer, m_afPhysicsFlags) & ~(1<<1))

		new iTrain = get_entvar(iPlayer, var_groundentity)
		if (!is_nullent(iTrain))
			set_pdata_cbase(iTrain, 85, -1, 4) // m_pDriver
	}
}

player_hide(iPlayer)
{
	new iHatEnt = Player[iPlayer][PlrHatEnt]
	if (!is_nullent(iHatEnt))
		set_entvar(iHatEnt, var_effects, EF_NODRAW)
	set_entvar(iPlayer, var_effects, EF_NODRAW)
}

player_set_topcolor_team(iPlayer, iTopColorTeam)
{
	if (Player[iPlayer][PlrTopColorTeam] != iTopColorTeam)
	{
		set_user_info(iPlayer, "topcolor", TOPCOLOR_TEAM_VALUES[iTopColorTeam])
		Player[iPlayer][PlrTopColorTeam] = iTopColorTeam
	}
}

create_hat_entity(iPlayer)
{
	new iHatEnt = Player[iPlayer][PlrHatEnt]
	if (iHatEnt > 0)
		return iHatEnt

	iHatEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iHatEnt))
	{
		Player[iPlayer][PlrHatEnt] = 0
		return NULLENT
	}

	set_entvar(iHatEnt, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iHatEnt, var_effects, EF_NODRAW)
	set_entvar(iHatEnt, var_impulse, IMPULSE_HAT)
	set_entvar(iHatEnt, var_owner, iPlayer)
	set_entvar(iHatEnt, var_aiment, iPlayer)
	set_entvar(iHatEnt, var_rendermode, kRenderTransAlpha)
	set_entvar(iHatEnt, var_renderamt, 0.0)
	set_entvar(iHatEnt, var_renderfx, kRenderFxNone)

	new iModelId = Player[iPlayer][PlrHatModelIndex]
	if (iModelId > 0)
	{
		new iBody = Player[iPlayer][PlrHatBody]
		new iSkin = Player[iPlayer][PlrHatSkin]

		set_entvar(iHatEnt, var_modelindex, iModelId)
		set_entvar(iHatEnt, var_skin, iSkin)
		set_entvar(iHatEnt, var_body, iBody)

		set_entvar(iHatEnt, var_sequence, iBody)
		set_entvar(iHatEnt, var_framerate, 1.0)
		set_entvar(iHatEnt, var_animtime, get_gametime())
	}

	Player[iPlayer][PlrHatEnt] = iHatEnt

	return iHatEnt
}

create_lifebar_entity(iPlayer)
{
	new iLifeBarEnt = Player[iPlayer][PlrHpBarEnt]
	if (iLifeBarEnt > 0)
		return iLifeBarEnt

	iLifeBarEnt = rg_create_entity(SZ_ENV_SPRITE)
	if (is_nullent(iLifeBarEnt))
	{
		Player[iPlayer][PlrHpBarEnt] = 0
		return NULLENT
	}

	engfunc(EngFunc_SetModel, iLifeBarEnt, MODEL_HEALTH_BAR)

	set_entvar(iLifeBarEnt, var_scale, 0.15)
	set_entvar(iLifeBarEnt, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iLifeBarEnt, var_aiment, iPlayer)

	set_entvar(iLifeBarEnt, var_effects, EF_NODRAW)
	set_entvar(iLifeBarEnt, var_renderfx, kRenderFxNone)
	set_entvar(iLifeBarEnt, var_rendercolor, NULL_VECTOR)
	set_entvar(iLifeBarEnt, var_rendermode, kRenderNormal)
	set_entvar(iLifeBarEnt, var_impulse, IMPULSE_LIFEBAR)

	Player[iPlayer][PlrHpBarEnt] = iLifeBarEnt

	return iLifeBarEnt
}

create_blind_effect(iPlayer)
{
	new iBlindEffEnt = Player[iPlayer][PlrBlindEffEnt]
	if (iBlindEffEnt > 0)
		return iBlindEffEnt

	iBlindEffEnt = rg_create_entity(SZ_INFO_TARGET)
	if (is_nullent(iBlindEffEnt))
	{
		Player[iPlayer][PlrBlindEffEnt] = 0
		return NULLENT
	}

	engfunc(EngFunc_SetModel, iBlindEffEnt, MODEL_BLIND)

	set_entvar(iBlindEffEnt, var_solid, SOLID_NOT)
	set_entvar(iBlindEffEnt, var_movetype, MOVETYPE_FOLLOW)
	set_entvar(iBlindEffEnt, var_aiment, iPlayer)
	set_entvar(iBlindEffEnt, var_impulse, IMPULSE_BLIND_EFFECT)

	set_entvar(iBlindEffEnt, var_sequence, 0)
	set_entvar(iBlindEffEnt, var_animtime, get_gametime())
	set_entvar(iBlindEffEnt, var_frame, 0.0)
	set_entvar(iBlindEffEnt, var_framerate, 1.0)

	Player[iPlayer][PlrBlindEffEnt] = iBlindEffEnt

	return iBlindEffEnt
}

remove_blind_effect(iPlayer)
{
	new iBlindEffEnt = Player[iPlayer][PlrBlindEffEnt]
	if (iBlindEffEnt > 0)
	{
		rg_remove_entity(iBlindEffEnt)
		Player[iPlayer][PlrBlindEffEnt] = 0
	}
}

add_player_frags(iPlayer, iAmount)
{
	new Float:fFrags = Float:get_entvar(iPlayer, var_frags) + iAmount
	set_entvar(iPlayer, var_frags, fFrags)

	static msgScoreInfo
	if (!msgScoreInfo)
		msgScoreInfo = get_user_msgid("ScoreInfo")

	message_begin(MSG_ALL, msgScoreInfo)
	write_byte(iPlayer)
	write_short(floatround(fFrags))
	write_short(get_member(iPlayer, m_iDeaths))
	write_short(0)
	write_short(get_member(iPlayer, m_iTeam))
	message_end()
}

generate_glitch_string(szString[], iSteLen)
{
	for (new i; i < iSteLen; i++)
		szString[i] = random_num(33, 126)
	szString[iSteLen] = 0
}

player_unprotection(iPlayer)
{
	ClearPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY);
	PlayerF[iPlayer][PlrSpawnProtectionTime] = 0.0

	new iTeam = Player[iPlayer][PlrTeam]

	if (g_iSilenceTeam > -1 && g_iSilenceTeam != iTeam)
	{
		send_msg_TE_PLAYERATTACHMENT(iPlayer, 35.0, g_pSilenceSpr, 100, MSG_ALL)
	}

	new i, Float:vOrigin[3]
	get_entvar(iPlayer, var_origin, vOrigin)
	while ((i = engfunc(EngFunc_FindEntityInSphere, i, vOrigin, FIND_SPAWN_ENEMY_RANGE)))
	{
		if (i > MaxClients)
			break

		if (CheckPlayerGameFlag(i, PLGF_IS_ALIVE) && iTeam != Player[i][PlrTeam])
		{
			new iKnifeId = Player[iPlayer][PlrKnife]
			if (KnifeF[iKnifeId][KNF_ABILITY2_CHARGE] > 3.0)
				PlayerF[iPlayer][PlrAbility2Charge] = floatmin(100.0, PlayerF[iPlayer][PlrAbility2Charge] + 45.0)

			if (KnifeF[iKnifeId][KNF_ABILITY3_CHARGE] > 3.0)
				PlayerF[iPlayer][PlrAbility3Charge] = floatmin(100.0, PlayerF[iPlayer][PlrAbility3Charge] + 45.0)

			if (KnifeF[iKnifeId][KNF_ABILITY4_CHARGE] > 3.0)
				PlayerF[iPlayer][PlrAbility4Charge] = floatmin(100.0, PlayerF[iPlayer][PlrAbility4Charge] + 45.0)

			break
		}
	}
}

bool:player_blind(iPlayer, iMode, Float:fBlindTime)
{
	if (Player[iPlayer][PlrVision] == VISION_BLIND)
		return false

	if (fBlindTime > 1.0)
	{
		new Float:fGameTime = get_gametime()

		Player[iPlayer][PlrVision] = VISION_BLIND

		send_msg_ScreenFade((1<<12), (1<<8), (1<<(iMode * 2)), {255, 255, 255}, 255, MSG_ONE, _, iPlayer)

		PlayerF[iPlayer][PlrBlindTime] = fGameTime  + fBlindTime
		PlayerF[iPlayer][PlrScreenFadeTime] = fGameTime  + 0.8

		create_blind_effect(iPlayer)
	}
	else
	{
		send_msg_ScreenFade((1<<12), floatround(fBlindTime * 4096), 0, {255, 255, 255}, 255, MSG_ONE, _, iPlayer)
	}

	return true
}

screenfades_out(iPlayer, bool:bBreaked)
{
	new iKnifeId = Player[iPlayer][PlrKnife]

	Player[iPlayer][PlrVision] = CheckKnifeFlag(iKnifeId, KNFF_FULL_VISION) ? VISION_FULL : VISION_NORMAL
	PlayerF[iPlayer][PlrBlindTime] = 0.0
	PlayerF[iPlayer][PlrScreenFadeTime] = 0.0

	if (PlayerF[iPlayer][PlrFrozen] == 0.0 && PlayerF[iPlayer][PlrChilled] == 0.0)
	{
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 255, 255}, 255, MSG_ONE, _, iPlayer)
	}
	else
	{
		send_msg_ScreenFade(~0, ~0, (1<<2), {FROST_COLOR_R, FROST_COLOR_G, FROST_COLOR_B}, 100, MSG_ONE, _, iPlayer)
	}

	if (Player[iPlayer][PlrVision] == VISION_NORMAL && g_iDarknessTeam == Player[iPlayer][PlrTeam])
		Player[iPlayer][PlrVision] = VISION_NIGHT

	remove_blind_effect(iPlayer)

	ExecuteForward(forward_unblind, _, iPlayer, bBreaked)
}

player_add_glow(iPlayer, Float:fGlowTime, r, g, b)
{
	new Float:fGameTime = get_gametime()

	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
		case VIS_CLONE: player_remove_clone(iPlayer)
		case VIS_SHADOW: player_remove_shadow(iPlayer)
	}

	Player[iPlayer][PlrVisibility] = VIS_GLOW

	new iGlowNum = Player[iPlayer][PlrGlowCount]

	if (iGlowNum == MAX_MIXCOLORS)
	{
		for (new i; i < MAX_MIXCOLORS - 1; i++)
		{
			Player[iPlayer][PlrGlowR][i] = Player[iPlayer][PlrGlowR][i + 1]
			Player[iPlayer][PlrGlowG][i] = Player[iPlayer][PlrGlowG][i + 1]
			Player[iPlayer][PlrGlowB][i] = Player[iPlayer][PlrGlowB][i + 1]
			PlayerF[iPlayer][PlrGlowTime][i] = PlayerF[iPlayer][PlrGlowTime][i + 1]
		}

		Player[iPlayer][PlrGlowR][MAX_MIXCOLORS - 1] = r
		Player[iPlayer][PlrGlowG][MAX_MIXCOLORS - 1] = g
		Player[iPlayer][PlrGlowB][MAX_MIXCOLORS - 1] = b
		PlayerF[iPlayer][PlrGlowTime][MAX_MIXCOLORS - 1] = fGameTime + fGlowTime

		player_calculate_render_colors(iPlayer)

		return MAX_MIXCOLORS - 1
	}

	Player[iPlayer][PlrGlowR][iGlowNum] = r
	Player[iPlayer][PlrGlowG][iGlowNum] = g
	Player[iPlayer][PlrGlowB][iGlowNum] = b
	PlayerF[iPlayer][PlrGlowTime][iGlowNum] = fGameTime + fGlowTime

	Player[iPlayer][PlrGlowCount] = iGlowNum + 1

	player_calculate_render_colors(iPlayer)

	return iGlowNum
}

player_remove_glow(iPlayer)
{
	Player[iPlayer][PlrGlowCount] = 0
	player_reset_render(iPlayer)
}

player_calculate_render_colors(iPlayer)
{
	new Float:vSum[3]
	for (new i; i < Player[iPlayer][PlrGlowCount]; i++)
	{
		vSum[0] += Player[iPlayer][PlrGlowR][i]
		vSum[1] += Player[iPlayer][PlrGlowG][i]
		vSum[2] += Player[iPlayer][PlrGlowB][i]
	}

	vSum[0] = vSum[0] / Player[iPlayer][PlrGlowCount] + 0.0
	vSum[1] = vSum[1] / Player[iPlayer][PlrGlowCount] + 0.0
	vSum[2] = vSum[2] / Player[iPlayer][PlrGlowCount] + 0.0

	if (Player[iPlayer][PlrCaptureType] == CAPTURE_NONE)
		set_entvar(iPlayer, var_effects, 0)

	set_entvar(iPlayer, var_rendercolor, vSum)
	set_entvar(iPlayer, var_renderamt, 16.0)
	set_entvar(iPlayer, var_rendermode, kRenderNormal)
	set_entvar(iPlayer, var_renderfx, kRenderFxGlowShell)

	new iHatEnt = Player[iPlayer][PlrHatEnt]
	if (Player[iPlayer][PlrHatModelIndex] && !is_nullent(iHatEnt))
	{
		if (get_entvar(iPlayer, var_body) != DEATH_ANIM_UNHEAD_BODY)
			set_entvar(iHatEnt, var_effects, 0)
		set_entvar(iHatEnt, var_rendercolor, vSum)
		set_entvar(iHatEnt, var_renderamt, 16.0)
		set_entvar(iHatEnt, var_rendermode, kRenderNormal)
		set_entvar(iHatEnt, var_renderfx, kRenderFxGlowShell)
	}

	ExecuteForward(forward_calculate_render_colors, _, iPlayer)
}

player_reset_render(iPlayer)
{
	Player[iPlayer][PlrVisibility] = VIS_NORMAL

	set_entvar(iPlayer, var_renderamt, 0.0)
	set_entvar(iPlayer, var_rendermode, kRenderNormal)
	set_entvar(iPlayer, var_renderfx, kRenderFxNone)

	if (Player[iPlayer][PlrCaptureType] == CAPTURE_NONE)
		set_entvar(iPlayer, var_effects, 0)

	new iHatEnt = Player[iPlayer][PlrHatEnt]

	if (Player[iPlayer][PlrHatModelIndex] && !is_nullent(iHatEnt))
	{
		set_entvar(iHatEnt, var_renderamt, 0.0)
		set_entvar(iHatEnt, var_rendermode, kRenderNormal)
		set_entvar(iHatEnt, var_renderfx, kRenderFxNone)

		if (get_entvar(iPlayer, var_body) != DEATH_ANIM_UNHEAD_BODY)
			set_entvar(iHatEnt, var_effects, 0)
	}

	ExecuteForward(forward_player_reset_render, _, iPlayer)
}

player_remove_invision(iPlayer)
{
	new Float:fGameTime = get_gametime()

	PlayerF[iPlayer][PlrInvisionTime] = 0.0

	for (new i, j; i < Player[iPlayer][PlrGlowCount]; i++)
	{
		if (PlayerF[iPlayer][PlrGlowTime][i] <= fGameTime)
		{
			for (j = i; j < Player[iPlayer][PlrGlowCount] - 1; j++)
			{
				Player[iPlayer][PlrGlowR][j] = Player[iPlayer][PlrGlowR][j + 1]
				Player[iPlayer][PlrGlowG][j] = Player[iPlayer][PlrGlowG][j + 1]
				Player[iPlayer][PlrGlowB][j] = Player[iPlayer][PlrGlowB][j + 1]
				PlayerF[iPlayer][PlrGlowTime][j] = PlayerF[iPlayer][PlrGlowTime][j + 1]
			}

			Player[iPlayer][PlrGlowCount]--
		}
	}

	if (Player[iPlayer][PlrGlowCount])
	{
		Player[iPlayer][PlrVisibility] = VIS_GLOW
		player_calculate_render_colors(iPlayer)
	}
	else
		player_reset_render(iPlayer)

	rg_set_user_footsteps(iPlayer, false)

	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
	{
		send_msg_TE_PLAYERATTACHMENT(iPlayer, 35.0, g_pSilenceSpr, 100, MSG_ALL)
	}

	ExecuteForward(forward_uninvisible, _, iPlayer)
}

player_remove_trans(iPlayer)
{
	new Float:fGameTime = get_gametime()

	PlayerF[iPlayer][PlrInvisionTime] = 0.0

	for (new i, j; i < Player[iPlayer][PlrGlowCount]; i++)
	{
		if (PlayerF[iPlayer][PlrGlowTime][i] <= fGameTime)
		{
			for (j = i; j < Player[iPlayer][PlrGlowCount] - 1; j++)
			{
				Player[iPlayer][PlrGlowR][j] = Player[iPlayer][PlrGlowR][j + 1]
				Player[iPlayer][PlrGlowG][j] = Player[iPlayer][PlrGlowG][j + 1]
				Player[iPlayer][PlrGlowB][j] = Player[iPlayer][PlrGlowB][j + 1]
				PlayerF[iPlayer][PlrGlowTime][j] = PlayerF[iPlayer][PlrGlowTime][j + 1]
			}

			Player[iPlayer][PlrGlowCount]--
		}
	}

	if (Player[iPlayer][PlrGlowCount])
	{
		Player[iPlayer][PlrVisibility] = VIS_GLOW
		player_calculate_render_colors(iPlayer)
	}
	else
		player_reset_render(iPlayer)

	ExecuteForward(forward_uninvisible, _, iPlayer)
}

player_get_shadow_target(iPlayer)
{
	return (Player[iPlayer][PlrVisibility] == VIS_SHADOW && Player[iPlayer][PlrClone])
		? Player[iPlayer][PlrClone]
		: 0
}

bool:player_remove_shadow(iPlayer, bool:bSetClone=false, bDirectJump=false)
{
	new Float:vStartOrigin[3], Float:vNewOrigin[3]
	get_entvar(iPlayer, var_origin, vStartOrigin)

	new iHull = get_entvar(iPlayer, var_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN

	if (bDirectJump)
	{
		new Float:fDirection[3], Float:vVelocity[3], Float:fPlaneNormal[3]
		get_entvar(iPlayer, var_v_angle, fDirection)
		get_entvar(iPlayer, var_view_ofs, vVelocity)
		angle_vector(fDirection, ANGLEVECTOR_FORWARD, fDirection)

		xs_vec_add(vStartOrigin, vVelocity, vNewOrigin)
		xs_vec_mul_scalar(fDirection,
			(get_gametime() - PlayerF[iPlayer][PlrCloneTimeValue]) * 250.0, vVelocity)
		xs_vec_add(vNewOrigin, vVelocity, vVelocity)

		engfunc(EngFunc_TraceLine, vNewOrigin, vVelocity, IGNORE_MONSTERS, iPlayer, 0)
		get_tr2(0, TR_vecEndPos, vNewOrigin)
		get_tr2(0, TR_vecPlaneNormal, fPlaneNormal)

		if (fPlaneNormal[2] > 0.0)
			vNewOrigin[2] += 45.0

		if (!is_hull_vacant(vNewOrigin, iHull, iPlayer))
			return false

		new iCarrier = Player[iPlayer][PlrClone]

		if (is_entity_player(iCarrier) && CheckPlayerGameFlag(iCarrier, PLGF_IS_ALIVE))
		{
			new Float:fCarrierOrigin[3], Float:fCarrierVelocity[3],
				Float:vMins[3], Float:vMaxs[3],
				Float:fCarrierMins[3], Float:fCarrierMaxs[3]

			get_entvar(iPlayer, var_mins, vMins)
			get_entvar(iPlayer, var_maxs, vMaxs)
			xs_vec_add(vNewOrigin, vMins, vMins)
			xs_vec_add(vNewOrigin, vMaxs, vMaxs)

			get_entvar(iCarrier, var_velocity, fCarrierVelocity)
			get_entvar(iCarrier, var_origin, fCarrierOrigin)
			get_entvar(iCarrier, var_mins, fCarrierMins)
			get_entvar(iCarrier, var_maxs, fCarrierMaxs)
			xs_vec_mul_scalar(fCarrierVelocity, 0.1, fCarrierVelocity)
			xs_vec_add(fCarrierOrigin, fCarrierVelocity, fCarrierOrigin)
			xs_vec_add(fCarrierOrigin, fCarrierMins, fCarrierMins)
			xs_vec_add(fCarrierOrigin, fCarrierMaxs, fCarrierMaxs)

			new isInters = 1
			for (new j = 0; j < 3; j++)
				if (vMins[j] > fCarrierMaxs[j] || vMaxs[j] < fCarrierMins[j])
					isInters = 0

			if (isInters)
				return false
		}

		engfunc(EngFunc_SetOrigin, iPlayer, vNewOrigin)
		set_entvar(iPlayer, var_origin, vNewOrigin)
		xs_vec_mul_scalar(fDirection, 300.0, vVelocity)
		set_entvar(iPlayer, var_velocity, vVelocity)
	}
	else
	{
		new const Float:vAdditionOffsets[][3] =
		{
			{ 0.0, 0.0, 64.0 },
			{ 64.0, 0.0, 0.0 }, { -64.0, 0.0, 0.0 }, { 0.0, 64.0, 0.0 }, { 0.0, -64.0, 0.0 },
			{ 64.0, 64.0, 0.0 }, { -64.0, 64.0, 0.0 }, { 64.0, -64.0, 0.0 }, { -64.0, -64.0, 0.0 }
		}

		for (new j; j < sizeof vAdditionOffsets; j++)
		{
			vNewOrigin[0] = vStartOrigin[0] + vAdditionOffsets[j][0]
			vNewOrigin[1] = vStartOrigin[1] + vAdditionOffsets[j][1]
			vNewOrigin[2] = vStartOrigin[2] + vAdditionOffsets[j][2]

			if (is_hull_vacant(vNewOrigin, iHull, iPlayer) && !is_wall_between(vStartOrigin, vNewOrigin, iPlayer))
			{
				set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) | FL_DUCKING)
				engfunc(EngFunc_SetSize, iPlayer, {-16.0, -16.0, -18.0}, {16.0,  16.0,  32.0})
				engfunc(EngFunc_SetOrigin, iPlayer, vNewOrigin)
				set_entvar(iPlayer, var_origin, vNewOrigin)

				//player_check_stuck(iPlayer)
				break
			}
		}
	}

	if (PlayerF[iPlayer][PlrCloneTimeValue] > 0.0)
	{
		new Float:fHealth, Float:fDamage, iEnt = NULLENT

		fHealth = get_entvar(iPlayer, var_health)
		fDamage = get_gametime() - PlayerF[iPlayer][PlrCloneTimeValue]

		if (floatround(fHealth - fDamage * SHADOW_JUMP_DAMAGE_COST, floatround_floor) > 0)
			set_entvar(iPlayer, var_health, fHealth - fDamage * SHADOW_JUMP_DAMAGE_COST)
		else
			set_entvar(iPlayer, var_health, 1.0)

		while ((iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, vNewOrigin, SHADOW_JUMP_RADIUS)))
		{
			if (iEnt <= MaxClients && CheckPlayerGameFlag(iEnt, PLGF_IS_ALIVE)
				&& Player[iPlayer][PlrTeam] != Player[iEnt][PlrTeam] && !CheckPlayerGameFlag(iEnt, PLGF_IN_UNABILITY))
			{
				player_set_death_reason(iEnt, "DEATH_REASON_SHADOW_WAVE")
				set_member(iEnt, m_LastHitGroup, HIT_GENERIC)
				ExecuteHamB(Ham_TakeDamage, iEnt, iPlayer, iPlayer, fDamage * SHADOW_JUMP_DAMAGE, DMG_ENERGYBEAM | DMG_ALWAYSGIB)
			}
			else if ((get_entvar(iEnt, var_flags) & FL_MONSTER) && get_entvar(iEnt, var_skin) + 1 != Player[iPlayer][PlrTeam])
			{
				ExecuteHamB(Ham_TakeDamage, iEnt, iPlayer, iPlayer, fDamage * SHADOW_JUMP_DAMAGE, DMG_ENERGYBEAM)
			}
		}
	}

	player_reset_render(iPlayer)

	set_entvar(iPlayer, var_movetype, 3)
	set_entvar(iPlayer, var_solid, SOLID_SLIDEBOX)
	set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) & ~PLAYER_PREVENT_JUMP)

	player_set_camera(iPlayer, Player[iPlayer][PlrCameraMode])
	Player[iPlayer][PlrCustomCameraEnt] = 0;

	ClearPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY);
	Player[iPlayer][PlrClone] = 0
	PlayerF[iPlayer][PlrCloneTimeValue] = 0.0
	PlayerF[iPlayer][PlrCloneRegenTime] = 0.0

	PlayerF[iPlayer][PlrCheckStuckTime] = get_gametime() + CHECK_STUCK_DELAY

	new iWeapon = get_active_weapon(iPlayer)
	if (!is_nullent(iWeapon))
		ExecuteHamB(Ham_Item_Deploy, iWeapon)

	if (bSetClone)
	{
		new iTargets[32], iTargetsNum = 0
		for (new i = 1; i <= MaxClients; i++)
			if (CheckPlayerGameFlag(i, PLGF_IS_ALIVE) && Player[iPlayer][PlrTeam] != Player[i][PlrTeam])
				iTargets[iTargetsNum++] = i

		if (iTargetsNum)
			player_clone(iPlayer, iTargets[random(iTargetsNum)])
	}

	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
	{
		send_msg_TE_PLAYERATTACHMENT(iPlayer, 35.0, g_pSilenceSpr, 100, MSG_ALL)
	}

	ExecuteForward(forward_unshadow, _, iPlayer)

	return true
}

bool:can_shadow(iPlayer, iTarget)
{
	static i

	if (g_bIsRoundEnded)
		return false

	for (i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrVisibility] == VIS_SHADOW && (Player[i][PlrClone] == iTarget || Player[i][PlrClone] == iPlayer))
			return false
	}

	return true
}

bool:player_clone(iPlayer, iTarget)
{
	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
		return false

	if (Player[iPlayer][PlrVisibility] == VIS_CLONE)
		player_remove_clone(iPlayer)

	player_reset_visibility(iPlayer)
	player_reset_render(iPlayer)

	if (get_user_weapon(iPlayer) == CSW_KNIFE)
	{
		new iKnifeId = Player[iTarget][PlrKnife]
		set_pdata_string(iPlayer, 492 * 4, ANIM_EXTENSIONS[Knife[iKnifeId][KNF_ANIM_EXT]], -1, 5 * 4)
	}

	if (ncl_is_client_api_ready(iPlayer))
	{
		new iKnifeId = Player[iTarget][PlrKnife]

		ncl_send_hud_sprite(
			.id = iPlayer,
			.channel = 0,
			.sprite_path = SPRITE_KNIFE_ICON,
			.sprite_color = {0, 128, 255},
			.alpha = 170,
			.frame = iKnifeId,
			.framerate = _,
			.in_time = 0.0,
			.hold_time = 999.0,
			.out_time = 0.0,
			.x = -0.01,
			.y = 0.6,
			.sprite_rect = { 0, 0, 0, 0 },
			.scale_x = 0.45,
			.scale_y = 0.45,
			.rendermode = kRenderTransAlpha
		)
	}
	else
	{
		send_msg_StatusIcon(true, "dmg_gas", {0, 0, 128}, MSG_ONE, _, iPlayer)
	}

	new Float:fOldKnifeMaxSpeed = player_get_knife_maxspeed(iPlayer)
	Player[iPlayer][PlrVisibility] = VIS_CLONE
	Player[iPlayer][PlrClone] = iTarget
	apply_change_knife_maxspeed(iPlayer, fOldKnifeMaxSpeed)

	SetPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY);
	PlayerF[iPlayer][PlrCloneTimeValue] = get_gametime() + 0.7

	return true
}

player_remove_clone(iPlayer, bool:bBreaked=false)
{
	new aEnemies[32], iEnemiesNum
	if (bBreaked)
	{
		for (new i = 1; i <= MaxClients; i++)
			if (CheckPlayerGameFlag(i, PLGF_IS_ALIVE) && Player[iPlayer][PlrTeam] != Player[i][PlrTeam])
				aEnemies[iEnemiesNum++] = i
	}

	if (!iEnemiesNum)
	{
		player_reset_render(iPlayer)

		if (get_user_weapon(iPlayer) == CSW_KNIFE)
		{
			new iKnifeId = Player[iPlayer][PlrKnife]
			set_member(iPlayer, m_szAnimExtention, ANIM_EXTENSIONS[Knife[iKnifeId][KNF_ANIM_EXT]])
		}

		if (ncl_is_client_api_ready(iPlayer))
		{
			ncl_clear_hud_sprite(iPlayer, 0)
		}
		else
		{
			send_msg_StatusIcon(false, "dmg_gas", _, MSG_ONE, _, iPlayer)
		}

		ClearPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY);

		new Float:fOldKnifeMaxSpeed = player_get_knife_maxspeed(iPlayer)
		Player[iPlayer][PlrClone] = 0
		apply_change_knife_maxspeed(iPlayer, fOldKnifeMaxSpeed)

		if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
		{
			send_msg_TE_PLAYERATTACHMENT(iPlayer, 35.0, g_pSilenceSpr, 100, MSG_ALL)
		}

		ExecuteForward(forward_unclone, _, iPlayer)
	}
	else
	{
		new iEnemyClone = aEnemies[random(iEnemiesNum)]
		new Float:fOldKnifeMaxSpeed = player_get_knife_maxspeed(iPlayer)
		Player[iPlayer][PlrClone] = iEnemyClone
		apply_change_knife_maxspeed(iPlayer, fOldKnifeMaxSpeed)
	}
}

public task_darkness(iTaskId)
{
	set_lights("#OFF")

	set_pcvar_num(g_pCvarSkyColors[0], g_iSkyColors[0])
	set_pcvar_num(g_pCvarSkyColors[1], g_iSkyColors[1])
	set_pcvar_num(g_pCvarSkyColors[2], g_iSkyColors[2])

	if (g_tFogData)
	{
		new iFogEnt = rg_create_entity("env_fog", true)
		if (!is_nullent(iFogEnt))
		{
			new TrieIter:tiFogData = TrieIterCreate(g_tFogData)
			new szKey[24], szValue[24], szR[4], szG[4], szB[4]
			new ivFogColor[3], Float:fFogDistance

			while (!TrieIterEnded(tiFogData))
			{
				TrieIterGetKey(tiFogData, szKey, charsmax(szKey))
				TrieIterGetString(tiFogData, szValue, charsmax(szValue))
				DispatchKeyValue(iFogEnt, szKey, szValue)
				TrieIterNext(tiFogData)
			}
			DispatchSpawn(iFogEnt)
			TrieIterDestroy(tiFogData)

			TrieGetString(g_tFogData, "rendercolor", szValue, charsmax(szValue))
			parse(szValue, szR, charsmax(szR), szG, charsmax(szG), szB, charsmax(szB))
			ivFogColor[0] = str_to_num(szR)
			ivFogColor[1] = str_to_num(szG)
			ivFogColor[2] = str_to_num(szB)

			TrieGetString(g_tFogData, "density", szValue, charsmax(szValue))
			fFogDistance = str_to_float(szValue)

			send_msg_Fog(fFogDistance, ivFogColor, MSG_ALL)
		}
	}

	g_iDarknessTeam = -1
	for (new i = 1; i <= MaxClients; i++)
	{
		if (Player[i][PlrVision] == VISION_NIGHT || Player[i][PlrVision] == VISION_FULL)
		{
			send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {255, 255, 255}, 100, MSG_ONE, _, i)
		}

		if (Player[i][PlrVision] == VISION_NIGHT)
			Player[i][PlrVision] = VISION_NORMAL
	}

	ExecuteForward(forward_undarkness)
}

public task_silence(iTaskId)
{
	for (new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE) && Player[iPlayer][PlrVisibility] < VIS_INVISION && g_iSilenceTeam != Player[iPlayer][PlrTeam])
		{
			send_msg_TE_KILLPLAYERATTACHMENTS(iPlayer, MSG_ALL)
		}
	}

	if (task_exists(TASK_SILENCE))
	{
		client_print_color(0, g_iSilenceTeam == 1 ? print_team_blue : print_team_red, "^4[%s] ^1%L",
			GAME_TAG, LANG_PLAYER, g_iSilenceTeam == 1 ? "SILENCE_OUT_CT" : "SILENCE_OUT_T")

		client_cmd(0, "spk %s", SOUND_SILENCE_OUT)
	}

	g_iSilenceTeam = -1
}

bool:player_heal(iPlayer, Float:fValue, iHealer, bool:bPrivate=false)
{
	new Float:fHealth = Float:get_entvar(iPlayer, var_health)
	new Float:fMaxHealth = Float:get_entvar(iPlayer, var_max_health)

	if (fHealth >= fMaxHealth)
		return false

	if (bPrivate)
	{
		fValue = floatmin(fValue, fMaxHealth - fHealth)
		set_entvar(iPlayer, var_health, fHealth + fValue)
	}
	else
	{
		ExecuteHamB(Ham_TakeHealth, iPlayer, fValue, DMG_ENERGYBEAM)
		fValue = Float:get_entvar(iPlayer, var_health) - fHealth
	}

	if (iPlayer != iHealer && is_entity_player(iHealer))
		PlayerF[iPlayer][PlrHealedBy][iHealer] += fValue

	ExecuteForward(forward_player_heal, _, iPlayer, iHealer, fValue)

	return true
}

player_slow(iPlayer, Float:fSlow, Float:fSlowTime)
{
	PlayerF[iPlayer][PlrRushTime] = 0.0

	if (Player[iPlayer][PlrWindBoostType] == WINDBOOST_POSITIVE)
		fSlow = floatmin(1.0, fSlow + WIND_SLOW_SUB)
	else if (Player[iPlayer][PlrWindBoostType] == WINDBOOST_NEGATIVE)
		fSlow = floatmax(MIN_PLAYER_SPEED, fSlow - WIND_SLOW_SUB)

	new Float:fGameTime = get_gametime(),
		Float:fSpeed = player_get_knife_maxspeed(iPlayer) * fSlow

	for (new i; i < 3; i++)
	{
		if (PlayerF[iPlayer][PlrSlowTime][i] == 0.0)
		{
			if (PlayerF[iPlayer][PlrMaxSpeed] > fSpeed)
			{
				engfunc(EngFunc_SetClientMaxspeed, iPlayer, fSpeed)
				PlayerF[iPlayer][PlrMaxSpeed] = fSpeed
			}

			PlayerF[iPlayer][PlrSlowTime][i] = fSlowTime + fGameTime
			PlayerF[iPlayer][PlrSlowSpeed][i] = fSpeed

			break
		}
	}
}

player_update_maxspeed(iPlayer)
{
	new Float:fMinSpeed = player_get_knife_maxspeed(iPlayer)
	for (new i, Float:fSlowSpeed; i < 3; i++)
	{
		if (PlayerF[iPlayer][PlrSlowTime][i] == 0.0)
			continue

		fSlowSpeed = PlayerF[iPlayer][PlrSlowSpeed][i]
		if (fSlowSpeed < fMinSpeed)
			fMinSpeed = fSlowSpeed
	}

	engfunc(EngFunc_SetClientMaxspeed, iPlayer, fMinSpeed)
	PlayerF[iPlayer][PlrMaxSpeed] = fMinSpeed
}

player_update_gravity(iPlayer)
{
	new iKnifeId = Player[iPlayer][PlrKnife]

	new Float:fGravity = KnifeF[iKnifeId][KNF_GRAVITY],
		WindBoostType:iWindBoostType = Player[iPlayer][PlrWindBoostType]

	if (iWindBoostType == WINDBOOST_POSITIVE)
		fGravity *= WIND_GRAVITY_MUL
	else if (iWindBoostType == WINDBOOST_NEGATIVE)
		fGravity *= WIND_GRAVITY_NEG_MUL

	new Float:fRealGravity = get_entvar(iPlayer, var_gravity)
	if (fRealGravity != MIN_GRAVITY)
		set_entvar(iPlayer, var_gravity, fGravity)

	PlayerF[iPlayer][PlrGravity] = fGravity
}

player_rush(iPlayer, Float:fRush, Float:fRushTime)
{
	PlayerF[iPlayer][PlrSlowTime][0] = 0.0
	PlayerF[iPlayer][PlrSlowTime][1] = 0.0
	PlayerF[iPlayer][PlrSlowTime][2] = 0.0
	PlayerF[iPlayer][PlrMaxSpeed] = player_get_knife_maxspeed(iPlayer)

	player_uncapture(iPlayer)
	player_unfreeze(iPlayer)
	player_unchill(iPlayer)

	engfunc(EngFunc_SetClientMaxspeed, iPlayer, fRush)
	PlayerF[iPlayer][PlrRushSpeed] = fRush
	PlayerF[iPlayer][PlrRushTime] = fRushTime + get_gametime()
}

player_set_windboost(iPlayer, WindBoostType:iType, bool:bUpdateState=true)
{
	new WindBoostType:iOldType = Player[iPlayer][PlrWindBoostType]
	if (iType == iOldType)
		return

	if (!bUpdateState)
	{
		Player[iPlayer][PlrWindBoostType] = iType
		ExecuteForward(forward_update_windboost, _, iPlayer, iType)
		return
	}

	new Float:fSlowAdd
	switch (iType)
	{
		case WINDBOOST_NONE: fSlowAdd = (iOldType == WINDBOOST_NEGATIVE) ? (-WIND_SLOW_SUB) : (WIND_SLOW_SUB)
		case WINDBOOST_POSITIVE:
		{
			fSlowAdd = (iOldType == WINDBOOST_NEGATIVE) ? (WIND_SLOW_SUB * 2.0) : (WIND_SLOW_SUB)
			PlayerF[iPlayer][PlrBlockAirAcTime] = 0.0
			Player[iPlayer][PlrBlockAirAcFlags] = 0
			set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) & ~PLAYER_PREVENT_CLIMB)
		}
		case WINDBOOST_NEGATIVE: fSlowAdd = (iOldType == WINDBOOST_NONE) ? (-WIND_SLOW_SUB) : (WIND_SLOW_SUB * -2.0)
	}

	Player[iPlayer][PlrWindBoostType] = iType

	new Float:fKnifeSpeed = player_get_knife_maxspeed(iPlayer)
	for (new i, Float:fSlowSpeed; i < 3; i++)
	{
		if (PlayerF[iPlayer][PlrSlowTime][i] == 0.0)
			continue

		fSlowSpeed = floatclamp(PlayerF[iPlayer][PlrSlowSpeed][i] / fKnifeSpeed + fSlowAdd,
			MIN_PLAYER_SPEED, 1.0)
		PlayerF[iPlayer][PlrSlowSpeed][i] = fKnifeSpeed * fSlowSpeed
	}

	if (PlayerF[iPlayer][PlrFrozen] == 0.0
		&& Player[iPlayer][PlrCaptureType] == CAPTURE_NONE
		&& !Player[iPlayer][PlrLevitation])
		player_update_maxspeed(iPlayer)

	player_update_gravity(iPlayer)

	ExecuteForward(forward_update_windboost, _, iPlayer, iType)
}

bool:player_burn(iPlayer, iAttacker, iCycles, bool:bOverlap=false)
{
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return false

	if ((iPlayer != iAttacker && Player[iPlayer][PlrTeam] == Player[iAttacker][PlrTeam])
		|| (get_entvar(iPlayer, var_flags) & FL_INWATER))
	{
		player_unfreeze(iPlayer)
		player_unchill(iPlayer)
		return false
	}

	if (CheckPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY) && Player[iPlayer][PlrVisibility] != VIS_CLONE)
		return false

	new iCurrentCycles = Player[iPlayer][PlrBurned]

	if (iCurrentCycles)
	{
		if (bOverlap)
		{
			if (iCurrentCycles > iCycles)
				iCycles = iCurrentCycles
		}
		else
			iCycles += iCurrentCycles
	}
	else
	{
		player_uncapture(iPlayer)
		player_unfreeze(iPlayer)
		player_unchill(iPlayer)
	}

	Player[iPlayer][PlrBurned] = iCycles
	Player[iPlayer][PlrBurnAttacker] = iAttacker

	return true
}

player_unburn(iPlayer)
{
	if (Player[iPlayer][PlrBurned])
	{
		if (Player[iPlayer][PlrVisibility] != VIS_INVISION)
		{
			new Float:vOrigin[3]
			get_entvar(iPlayer, var_origin, vOrigin)
			vOrigin[2] -= 50.0

			send_msg_TE_SMOKE(vOrigin, g_pSmokeSpr, random_num(15, 20), random_num(10, 20), MSG_PVS, vOrigin)
		}

		Player[iPlayer][PlrBurned] = 0

		ExecuteForward(forward_unburn, _, iPlayer)
	}
}

bool:player_freeze(iPlayer, Float:fFreezeTime, iAttacker)
{
	if (iPlayer != iAttacker && Player[iPlayer][PlrTeam] == Player[iAttacker][PlrTeam])
	{
		player_unburn(iPlayer)
		return false
	}

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return false

	if (CheckPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY) && Player[iPlayer][PlrVisibility] != VIS_CLONE)
		return false

	if (PlayerF[iPlayer][PlrFrozen] > 0.0)
	{
		player_set_death_reason(iPlayer, "DEATH_REASON_FROZEN")
		set_member(iPlayer, m_LastHitGroup, HIT_GENERIC)
		ExecuteHamB(Ham_TakeDamage, iPlayer, iAttacker, iAttacker, FROZEN_DAMAGE, DMG_FREEZE)
		return true
	}

	player_unlevitation(iPlayer)
	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
	}
	player_unchill(iPlayer)

	player_drop_train(iPlayer)

	player_add_glow(iPlayer, fFreezeTime, FROST_COLOR_R, FROST_COLOR_G, FROST_COLOR_B)

	new Float:vVelocity[3]
	get_entvar(iPlayer, var_velocity, vVelocity)
	vVelocity[0] = 0.0
	vVelocity[1] = 0.0
	set_entvar(iPlayer, var_velocity, vVelocity)

	engfunc(EngFunc_SetClientMaxspeed, iPlayer, MIN_PLAYER_SPEED)
	PlayerF[iPlayer][PlrMaxSpeed] = MIN_PLAYER_SPEED
	PlayerF[iPlayer][PlrRushTime] = 0.0

	emit_sound(iPlayer, CHAN_BODY, SOUND_FROST_HIT, 1.0, ATTN_NORM, 0, PITCH_HIGH)

	set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) | PLAYER_PREVENT_JUMP)

	new iIceBlockEnt = rg_create_entity(SZ_INFO_TARGET)
	if (!is_nullent(iIceBlockEnt))
	{
		engfunc(EngFunc_SetModel, iIceBlockEnt, MODEL_ICEBLOCK)

		set_entvar(iIceBlockEnt, var_animtime, get_gametime())
		set_entvar(iIceBlockEnt, var_frame, 0.0)
		set_entvar(iIceBlockEnt, var_framerate, 0.7)
		set_entvar(iIceBlockEnt, var_sequence, 0)

		set_entvar(iIceBlockEnt, var_rendermode, kRenderNormal)
		set_entvar(iIceBlockEnt, var_renderfx, kRenderFxGlowShell)
		set_entvar(iIceBlockEnt, var_rendercolor, Float:{FROST_COLOR_R.0, FROST_COLOR_G.0, FROST_COLOR_B.0} )
		set_entvar(iIceBlockEnt, var_renderamt, 16.0)

		new Float:vAngles[3], Float:vOrigin[3]
		vAngles[1] = random_float(0.0, 359.9)

		set_entvar(iIceBlockEnt, var_angles, vAngles)
		get_entvar(iPlayer, var_origin, vOrigin)
		engfunc(EngFunc_SetOrigin, iIceBlockEnt, vOrigin)
		set_entvar(iIceBlockEnt, var_origin, vOrigin)

		engfunc(EngFunc_SetSize, iIceBlockEnt, Float:{-8.0, -8.0, -4.0}, Float:{8.0, 8.0, 4.0})
		Player[iPlayer][PlrIceblockEnt] = iIceBlockEnt
	}
	else
	{
		Player[iPlayer][PlrIceblockEnt] = 0
	}

	if (Player[iPlayer][PlrVision] != VISION_BLIND)
	{
		send_msg_ScreenFade(~0, ~0, (1<<2), {FROST_COLOR_R, FROST_COLOR_G, FROST_COLOR_B}, 100, MSG_ONE, _, iPlayer)
	}

	PlayerF[iPlayer][PlrFrozen] = fFreezeTime + get_gametime()
	player_unburn(iPlayer)

	ExecuteForward(forward_freeze, _, iPlayer)

	return true
}

player_unfreeze(iPlayer)
{
	if (PlayerF[iPlayer][PlrFrozen] <= 0.0)
		return

	for (new i; i < Player[iPlayer][PlrGlowCount]; i++)
	{
		if (Player[iPlayer][PlrGlowR][i] == FROST_COLOR_R && Player[iPlayer][PlrGlowG][i] == FROST_COLOR_G && Player[iPlayer][PlrGlowB][i] == FROST_COLOR_B)
			PlayerF[iPlayer][PlrGlowTime][i] = 0.1
	}

	if (Player[iPlayer][PlrCaptureType] == CAPTURE_NONE)
		player_update_maxspeed(iPlayer)

	if (Player[iPlayer][PlrVision] != VISION_BLIND)
	{
		send_msg_ScreenFade(0, 0, 0, _, _, MSG_ONE, _, iPlayer)
	}

	if (Player[iPlayer][PlrIceblockEnt])
	{
		new Float:vOrigin[3]
		get_entvar(iPlayer, var_origin, vOrigin)

		send_msg_TE_IMPLOSION(vOrigin, 64, 10, 3)
		send_msg_TE_SPARKS(vOrigin)

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(108)
		engfunc(EngFunc_WriteCoord, vOrigin[0])
		engfunc(EngFunc_WriteCoord, vOrigin[1])
		engfunc(EngFunc_WriteCoord, vOrigin[2] + 24.0)
		write_coord(16)
		write_coord(16)
		write_coord(16)
		write_coord(random_num(-50, 50))
		write_coord(random_num(-50, 50))
		write_coord(25)
		write_byte(10)
		write_short(g_pGlassGibsMdl)
		write_byte(10)
		write_byte(25)
		write_byte(0x01)
		message_end()

		emit_sound(Player[iPlayer][PlrIceblockEnt], CHAN_BODY, SOUND_CRASH_ICEBLOCK, 1.0, ATTN_NORM, 0, PITCH_LOW)
		set_entvar(Player[iPlayer][PlrIceblockEnt], var_flags, FL_KILLME)
		Player[iPlayer][PlrIceblockEnt] = 0
	}

	if (Player[iPlayer][PlrCaptureType] == CAPTURE_NONE)
		set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) & ~PLAYER_PREVENT_JUMP)

	send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)

	PlayerF[iPlayer][PlrFrozen] = 0.0
	player_chill(iPlayer, CHILL_TIME, iPlayer)

	ExecuteForward(forward_unfreeze, _, iPlayer)
}

bool:player_chill(iPlayer, Float:fChillTime, iAttacker)
{
	if (iPlayer != iAttacker && Player[iPlayer][PlrTeam] == Player[iAttacker][PlrTeam])
	{
		player_unburn(iPlayer)
		return false
	}

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return false

	if (CheckPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY))
		return false

	if (PlayerF[iPlayer][PlrChilled] > 0.0)
		return false

	if (PlayerF[iPlayer][PlrFrozen] > 0.0)
		return false

	player_unlevitation(iPlayer)
	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
	}

	player_add_glow(iPlayer, fChillTime, FROST_COLOR_R, FROST_COLOR_G, FROST_COLOR_B)
	player_slow(iPlayer, CHILL_SLOW, fChillTime)
	emit_sound(iPlayer, CHAN_BODY, SOUND_DUCT2, 1.0, ATTN_NORM, 0, PITCH_LOW)

	if (Player[iPlayer][PlrVision] != VISION_BLIND)
		send_msg_ScreenFade(~0, ~0, (1<<2), {FROST_COLOR_R, FROST_COLOR_G, FROST_COLOR_B}, 100, MSG_ONE, _, iPlayer)

	PlayerF[iPlayer][PlrChilled] = fChillTime + get_gametime()
	player_unburn(iPlayer)

	return true
}

player_unchill(iPlayer)
{
	if (PlayerF[iPlayer][PlrChilled] > 0.0)
	{
		new i
		for (i = 0; i < Player[iPlayer][PlrGlowCount]; i++)
		{
			if (Player[iPlayer][PlrGlowR][i] == FROST_COLOR_R && Player[iPlayer][PlrGlowG][i] == FROST_COLOR_G && Player[iPlayer][PlrGlowB][i] == FROST_COLOR_B)
				PlayerF[iPlayer][PlrGlowTime][i] = 0.1
		}

		for (i = 0; i < 3; i++)
		{
			if (PlayerF[iPlayer][PlrSlowTime][i] > 0.0 && PlayerF[iPlayer][PlrSlowSpeed][i] == player_get_knife_maxspeed(iPlayer) * CHILL_SLOW)
				PlayerF[iPlayer][PlrSlowTime][i] = 0.1
		}

		if (Player[iPlayer][PlrVision] != VISION_BLIND)
		{
			send_msg_ScreenFade(0, 0, 0, _, _, MSG_ONE, _, iPlayer)
		}

		send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)

		PlayerF[iPlayer][PlrChilled] = 0.0

		ExecuteForward(forward_unchill, _, iPlayer)
	}
}

player_uncapture(iPlayer)
{
	if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
	{
		if (PlayerF[iPlayer][PlrFrozen] == 0.0) {
			player_update_maxspeed(iPlayer)
			set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) & ~(PLAYER_PREVENT_DUCK | PLAYER_PREVENT_JUMP))
		}

		PlayerF[iPlayer][PlrCaptured] = 0.0
		Player[iPlayer][PlrCaptureType] = CAPTURE_NONE

		if (CheckPlayerGameFlag(iPlayer, PLGF_IN_FIXED_ANIMATION))
		{
			new iHatEnt = Player[iPlayer][PlrHatEnt]
			if (iHatEnt && get_entvar(iPlayer, var_body) != DEATH_ANIM_UNHEAD_BODY)
				set_entvar(iHatEnt, var_effects, 0)

			ClearPlayerGameFlag(iPlayer, PLGF_IN_FIXED_ANIMATION);
		}

		rg_set_user_footsteps(iPlayer, false)

		new iWeapon = get_active_weapon(iPlayer)
		if (!is_nullent(iWeapon))
			ExecuteHamB(Ham_Item_Deploy, iWeapon)

		ExecuteForward(forward_uncapture, _, iPlayer)
	}
}

bool:player_levitation(iPlayer)
{
	if (Player[iPlayer][PlrLevitation])
		return false

	if (PlayerF[iPlayer][PlrMaxSpeed] < player_get_knife_maxspeed(iPlayer))
		return false

	if (get_entvar(iPlayer, var_waterlevel) >= 2)
		return false

	if (g_bIsRoundEnded)
		return false

	engfunc(EngFunc_SetClientMaxspeed, iPlayer, MIN_PLAYER_SPEED)
	set_entvar(iPlayer, var_gravity, MIN_GRAVITY)
	set_entvar(iPlayer, var_velocity, Float:{0.0, 0.0, 30.0})

	PlayerF[iPlayer][PlrRushTime] = 0.0

	new Float:fGameTime = get_gametime()

	Player[iPlayer][PlrLevitation] = LEVITATION_ON | LEVITATION_UP
	Player[iPlayer][PlrLevitationPt] = -5
	PlayerF[iPlayer][PlrLevitationDelay][0] = fGameTime + 0.1
	PlayerF[iPlayer][PlrLevitationRushDelay] = fGameTime + 0.65

	return true
}

player_unlevitation(iPlayer)
{
	if (Player[iPlayer][PlrLevitation])
	{
		engfunc(EngFunc_SetClientMaxspeed, iPlayer, PlayerF[iPlayer][PlrMaxSpeed])
		set_entvar(iPlayer, var_gravity, PlayerF[iPlayer][PlrGravity])
		set_entvar(iPlayer, var_velocity, NULL_VECTOR)
		Player[iPlayer][PlrLevitation] = 0
	}
}

bool:is_user_debuffed(iPlayer)
{
	if (PlayerF[iPlayer][PlrPowerDamage] < 0.0)
		return true

	if (Player[iPlayer][PlrVision] == VISION_BLIND)
		return true

	for (new i; i < 3; i++)
	{
		if (PlayerF[iPlayer][PlrSlowTime][i] > 0.0)
			return true
	}

	if (Player[iPlayer][PlrWindBoostType] == WINDBOOST_NEGATIVE)
		return true

	if (Player[iPlayer][PlrBurned])
		return true

	if (PlayerF[iPlayer][PlrFrozen] > 0.0 || PlayerF[iPlayer][PlrChilled] > 0.0)
		return true

	return false
}

bool:friendly_swap(iPlayer, iTarget)
{
	new bool:bRes = false
	new Float:fGameTime = get_gametime()

	if (PlayerF[iTarget][PlrPowerDamage] < 0.0)
	{
		PlayerF[iPlayer][PlrPowerDamage] += PlayerF[iTarget][PlrPowerDamage]
		PlayerF[iPlayer][PlrPowerDamageDelay] = PlayerF[iTarget][PlrPowerDamageDelay]

		PlayerF[iTarget][PlrPowerDamage] = 0.0
		PlayerF[iTarget][PlrPowerDamageDelay] = 0.0
		bRes = true
	}

	if (Player[iTarget][PlrVision] == VISION_BLIND)
	{
		player_blind(iPlayer, 1, PlayerF[iTarget][PlrBlindTime] - fGameTime)
		screenfades_out(iTarget, true)
		bRes = true
	}

	for (new i; i < 3; i++)
	{
		if (PlayerF[iTarget][PlrSlowTime][i] > 0.0)
		{
			player_slow(iPlayer, PlayerF[iTarget][PlrSlowSpeed][i] / player_get_knife_maxspeed(iTarget), PlayerF[iTarget][PlrSlowTime][i] - fGameTime)
			PlayerF[iTarget][PlrSlowTime][i] = 0.1
			bRes = true
		}
	}

	if (Player[iTarget][PlrCaptureType] == CAPTURE_NONE)
		engfunc(EngFunc_SetClientMaxspeed, iTarget, player_get_knife_maxspeed(iTarget))

	if (Player[iTarget][PlrWindBoostType] == WINDBOOST_NEGATIVE)
	{
		player_set_windboost(iTarget, WINDBOOST_NONE, false)
		player_update_gravity(iTarget)

		player_set_windboost(iPlayer, WINDBOOST_NEGATIVE, false)
		player_update_gravity(iPlayer)

		bRes = true
	}

	if (Player[iTarget][PlrBurned])
	{
		player_burn(iPlayer, iPlayer, Player[iTarget][PlrBurned], true)
		player_unburn(iTarget)
		bRes = true
	}
	else if (PlayerF[iTarget][PlrFrozen] > 0.0)
	{
		player_freeze(iPlayer, PlayerF[iTarget][PlrFrozen] - fGameTime, iPlayer)
		player_unfreeze(iTarget)
		bRes = true
	}

	if (PlayerF[iTarget][PlrChilled] > 0.0)
	{
		player_chill(iPlayer, PlayerF[iTarget][PlrChilled] - fGameTime, iPlayer)
		player_unchill(iTarget)
		bRes = true
	}

	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, SZ_BEAM)))
		if (get_entvar(iEnt, var_aiment) == iTarget && get_entvar(iEnt, var_impulse) == IMPULSE_ACIDTRAP_BEAM)
			Beam_EntsInit(iEnt, get_entvar(iEnt, var_owner), iPlayer)

	return bRes
}

bool:player_apply_concentblock(iPlayer, iAttacker,
	AttackHeaviness:iAttackHeaviness=ATTACK_HEAVINESS_NORM,
	Float:fFov=CONCENTBLOCK_DEFAULT_FOV, bool:bUseVelocity=false)
{
	if (!Player[iPlayer][PlrConcentBlock])
		return false

	if (Float:get_member(iPlayer, m_flNextAttack) > 0.0)
		return false

	new iWeapon = get_active_weapon(iPlayer)
	if (is_nullent(iWeapon))
		return false

	if (!player_can_concentblock_attack(iPlayer, iAttacker, fFov, bUseVelocity))
		return false

	new iPitch = PITCH_NORM
	new Float:vPunchAngle[3] = {0.0, 0.0, 25.0}

	player_set_view_anim(iPlayer, Player[iPlayer][PlrConcentBlock])
	rg_set_animation(iPlayer, PLAYER_ATTACK1)

	switch (iAttackHeaviness)
	{
		case ATTACK_HEAVINESS_LOW:
		{
			vPunchAngle = Float:{0.0, 0.0, 10.0}
		}
		case ATTACK_HEAVINESS_HIGH:
		{
			vPunchAngle = Float:{0.0, 0.0, 35.0}
			iPitch = random_num(90, 96)
		}
	}

	set_entvar(iPlayer, var_punchangle, vPunchAngle)

	set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 1.0)
	set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 1.0)
	set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 1.0)

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_AUTO, SOUND_KNIFE_BLOCK, 1.0, ATTN_NORM, 0, iPitch)

	if (iAttackHeaviness != ATTACK_HEAVINESS_LOW)
		Player[iPlayer][PlrConcentBlock] = 0

	return true
}

bool:player_can_concentblock_attack(iPlayer, iAttacker,
	Float:fFov=CONCENTBLOCK_DEFAULT_FOV, bool:bUseVelocity=false)
{
	new Float:vAngles[3]
	get_entvar(iPlayer, var_angles, vAngles)

	new Float:vPlayerDir[3]
	engfunc(EngFunc_MakeVectors, vAngles)
	global_get(glb_v_forward, vPlayerDir)
	vPlayerDir[2] = 0.0

	new Float:vAttackDir[3]
	if (bUseVelocity)
	{
		get_entvar(iAttacker, var_velocity, vAttackDir)
		xs_vec_neg(vAttackDir, vAttackDir)
	}
	else
	{
		new Float:vOrigin[3], Float:vHit[3]
		get_entvar(iPlayer, var_origin, vOrigin)
		get_entvar(iAttacker, var_origin, vHit)
		xs_vec_sub(vHit, vOrigin, vAttackDir)
	}

	vAttackDir[2] = 0.0
	xs_vec_normalize(vAttackDir, vAttackDir)

	if (fFov == 0.0)
		fFov = Float:get_entvar(iPlayer, var_fov)

	return xs_vec_dot(vAttackDir, vPlayerDir) >= floatcos(fFov * M_PI / 360.0)
}

bool:player_reflection_start(iPlayer, Float:fTime)
{
	if (PlayerF[iPlayer][PlrReflectionEndTime] != 0.0)
		return false

	PlayerF[iPlayer][PlrReflectionEndTime] = get_gametime() + fTime

	ExecuteForward(forward_reflection_start, _, iPlayer)
	return true
}

player_reflection_stop(iPlayer, bool:bIsDeath=false)
{
	if (PlayerF[iPlayer][PlrReflectionEndTime] == 0.0)
		return

	PlayerF[iPlayer][PlrReflectionEndTime] = 0.0

	ExecuteForward(forward_reflection_stop, _, iPlayer, bIsDeath)
}

bool:player_in_reflection(iPlayer)
{
	return PlayerF[iPlayer][PlrReflectionEndTime] > get_gametime()
}

player_set_override_attacker(iPlayer, iAttacker, Float:fTime)
{
	Player[iPlayer][PlrAttacker] = iAttacker
	PlayerF[iPlayer][PlrAttackerTime] = get_gametime() + fTime
}

player_set_anim(const iPlayer, const iSeq, const iCrouchSeq, const Float:fFrameRate, const Float:fTime)
{
	new Float:fGameTime = get_gametime()

	Player[iPlayer][PlrModelAnim][1] = iSeq
	Player[iPlayer][PlrModelAnim][2] = iCrouchSeq
	Player[iPlayer][PlrModelAnim][0] = (get_entvar(iPlayer, var_flags) & FL_DUCKING) ? iCrouchSeq : iSeq

	PlayerF[iPlayer][PlrModelAnimFrame] = 0.0
	PlayerF[iPlayer][PlrModelAnimFPS] = fFrameRate
	PlayerF[iPlayer][PlrModelAnimTime] = fGameTime + fTime
	PlayerF[iPlayer][PlrModelAnimStart] = fGameTime
}

player_set_view_anim(const iPlayer, const iSeq)
{
	set_entvar(iPlayer, var_weaponanim, iSeq)
	message_begin(MSG_ONE, SVC_WEAPONANIM, .player = iPlayer)
	write_byte(iSeq)
	write_byte(0)
	message_end()

	if (get_entvar(iPlayer, var_iuser1))
		return

	new i, iSpecNum, iSpectator, aSpectators[MAX_PLAYERS]
	get_players(aSpectators, iSpecNum, "bch")

	for (i = 0; i < iSpecNum; i++)
	{
		iSpectator = aSpectators[i]
		if (get_entvar(iSpectator, var_iuser1) != 4 || get_entvar(iSpectator, var_iuser2) != iPlayer)
			continue

		set_entvar(iSpectator, var_weaponanim, iSeq)
		message_begin(MSG_ONE, SVC_WEAPONANIM, .player = iSpectator)
		write_byte(iSeq)
		write_byte(0)
		message_end()
	}
}

strclip(szString[], iClip, szEnding[] = "..")
{
	new iLen = strlen(szString) - 1 - strlen(szEnding) - iClip
	format(szString[iLen], iLen, szEnding)
}

save_inventory_to_cache(iPlayer)
{
	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ONLINE))
		return

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_AUTHORIZED))
		return

	new szAuthId[24]
	get_user_authid(iPlayer, szAuthId, charsmax(szAuthId))

	TrieSetArray(g_tInventoryCache, fmt("%s_item_value", szAuthId), Player[iPlayer][PlrItemValue], MAX_ITEMS)
	TrieSetCell(g_tInventoryCache, fmt("%s_item_mode", szAuthId), Player[iPlayer][PlrItemMode])
	TrieSetCell(g_tInventoryCache, fmt("%s_bhop", szAuthId), Player[iPlayer][PlrIsBhopEnabled])
}

remove_map_entities()
{
	// Remove buyzones
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, SZ_FUNC_BUYZONE, true)))
		if (get_entvar(iEnt, var_iuser2) != 7777)
			rg_remove_entity(iEnt)

	// Remove armoury
	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, "armoury_entity", true)))
	{
		new ArmouryItemPack:iItem = ArmouryItemPack:get_member(iEnt, m_Armoury_iItem)
		if (iItem != ARMOURY_FLASHBANG && iItem != ARMOURY_HEGRENADE && iItem != ARMOURY_SMOKEGRENADE)
			rg_remove_entity(iEnt)
	}

	// Remove usable cameras
	iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, SZ_TRIGGER_CAMERA, true)))
	{
		new szTargetName[4]
		get_entvar(iEnt, var_targetname, szTargetName, charsmax(szTargetName))
		if (szTargetName[0])
			rg_remove_entity(iEnt)
	}

	// Remove other entities
	for (new i; i < sizeof REMOVE_MAP_CLASSNAMES; i++)
	{
		iEnt = NULLENT
		while ((iEnt = rg_find_ent_by_class(iEnt, REMOVE_MAP_CLASSNAMES[i], true)))
			rg_remove_entity(iEnt)
	}
}

load_inventory_from_cache(iPlayer)
{
	new szAuthID[24]
	get_user_authid(iPlayer, szAuthID, charsmax(szAuthID))

	TrieGetArray(g_tInventoryCache, fmt("%s_item_value", szAuthID), Player[iPlayer][PlrItemValue], MAX_ITEMS)
	TrieGetCell(g_tInventoryCache, fmt("%s_item_mode", szAuthID), Player[iPlayer][PlrItemMode])
	TrieGetCell(g_tInventoryCache, fmt("%s_bhop", szAuthID), Player[iPlayer][PlrIsBhopEnabled])
}

// NATIVES

public bool:_21kc_player_set_weapon_hud(plugin, num_params)
{
	new szOldWeapon[64], szNewWeapon[64]
	get_string(2, szOldWeapon, charsmax(szOldWeapon))
	get_string(3, szNewWeapon, charsmax(szNewWeapon))
	return player_set_weapon_hud(get_param(1), szOldWeapon, szNewWeapon)
}

public bool:_21kc_register_weapon_hud(plugin, num_params)
{
	new szOldWeapon[64], szNewWeapon[64]
	get_string(1, szOldWeapon, charsmax(szOldWeapon))
	get_string(2, szNewWeapon, charsmax(szNewWeapon))
	return register_hud(szOldWeapon, szNewWeapon)
}

public _21kc_knife_set_charge_boost_coeff(plugin, num_params)
{
	KnifeF[get_param(1)][KNF_CHARGE_BOOST_COEF] = get_param_f(2)
}

public _21kc_knife_set_level(plugin, num_params)
{
	Knife[get_param(1)][KNF_ACCESS_LEVEL] = get_param(2)
}

public _21kc_player_set_game_flag(plugin, num_params)
{
	SetPlayerGameFlag(get_param(1), get_param(2))
}

public _21kc_player_unset_game_flag(plugin, num_params)
{
	ClearPlayerGameFlag(get_param(1), get_param(2))
}

public bool:_21kc_player_check_game_flag(plugin, num_params)
{
	return bool:CheckPlayerGameFlag(get_param(1), get_param(2))
}

public _21kc_player_get_item_value(plugin, num_params)
{
	return player_item_get_value(get_param(1), get_param(2))
}

public _21kc_player_set_item_value(plugin, num_params)
{
	player_item_set_value(get_param(1), get_param(2), get_param(3))
}

public bool:_21kc_player_item_get_enabled(plugin, num_params)
{
	return player_item_get_mode(get_param(1), get_param(2))
}

public _21kc_player_item_set_enabled(plugin, num_params)
{
	player_item_set_enabled(get_param(1), get_param(2), bool:get_param(3))
}

public _21kc_register_knife(plugin, num_params)
{
	if (g_iTotalKnives == MAX_KNIVES)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_knife) Knife registration limit exceeded", PLUGIN)
		return -1
	}

	new iKnifeId = g_iTotalKnives

	get_string(1, Knife[iKnifeId][KNF_NAME], LEN_CLASS_NAME - 1)
	get_string(2, Knife[iKnifeId][KNF_DESCRIPTION], LEN_CLASS_DESCRIPTION - 1)
	get_string(3, Knife[iKnifeId][KNF_CHAT_DESCRIPTION], LEN_CLASS_CHATDESCRIPTION - 1)
	Knife[iKnifeId][KNF_MODEL_V_STRID] = get_param(4)
	Knife[iKnifeId][KNF_MODEL_P_STRID] = get_param(5)
	Knife[iKnifeId][KNF_MODEL_P] = get_param(6)

	KnifeF[iKnifeId][KNF_MAX_HEALTH] = get_param_f(7)
	KnifeF[iKnifeId][KNF_GRAVITY] = get_param_f(8)
	KnifeF[iKnifeId][KNF_MAX_SPEED] = get_param_f(9)
	KnifeF[iKnifeId][KNF_MIN_DAMAGE] = get_param_f(10)
	KnifeF[iKnifeId][KNF_MAX_DAMAGE] = get_param_f(11)

	g_iTotalKnives++

	return iKnifeId
}

public _21kc_get_knives_num(plugin, num_params)
{
	return g_iTotalKnives
}

public bool:_21kc_knife_get_abil1_name(plugin, num_params)
{
	new iKnifeId = get_param(1)

	if (!is_valid_knife(iKnifeId))
		return false

	set_array(2, Knife[iKnifeId][KNF_ABILITY1_NAME], get_param(3))

	return true
}

public bool:_21kc_register_ability1(plugin, num_params)
{
	new iKnifeId = get_param(1)
	get_string(2, Knife[iKnifeId][KNF_ABILITY1_NAME], LEN_ABILITY_NAME - 1)

	if (Knife[iKnifeId][KNF_ABILITY1_NAME][0] == EOS)
		return false

	KnifeF[iKnifeId][KNF_ABILITY1_CHARGE] = get_param_f(3)
	Knife[iKnifeId][KNF_ABILITY1_TYPE] = AbilityType:get_param(4)
	KnifeF[iKnifeId][KNF_ABILITY1_MIN_DIST] = get_param_f(5)
	KnifeF[iKnifeId][KNF_ABILITY1_MAX_DIST] = get_param_f(6)
	KnifeF[iKnifeId][KNF_CHARGE_BOOST_COEF] = 0.5

	Knife[iKnifeId][KNF_ABILITY1_CALLBACK] = CreateOneForward(plugin, "efk_ability", FP_CELL, FP_CELL)
	if (Knife[iKnifeId][KNF_ABILITY1_CALLBACK] < 0)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_ability1) Callback first ability function not found (Knife ID: %d)", PLUGIN, iKnifeId)
		return false
	}

	if (!equal(Knife[iKnifeId][KNF_NAME], "NULL"))
		register_hud(SZ_WEAPON_KNIFE, Knife[iKnifeId][KNF_NAME])

	return true
}

public bool:_21kc_register_ability2(plugin, num_params)
{
	new iKnifeId = get_param(1)
	get_string(2, Knife[iKnifeId][KNF_ABILITY2_NAME], LEN_ABILITY_NAME - 1)

	if (Knife[iKnifeId][KNF_ABILITY2_NAME][0] == EOS)
		return false

	KnifeF[iKnifeId][KNF_ABILITY2_CHARGE] = get_param_f(3)

	Knife[iKnifeId][KNF_ABILITY2_CALLBACK] = CreateOneForward(plugin, "efk_ability2", FP_CELL)
	if (Knife[iKnifeId][KNF_ABILITY2_CALLBACK] < 0)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_ability2) Callback second ability function not found (Knife ID: %d)", PLUGIN, iKnifeId)
		return false
	}

	return true
}

public bool:_21kc_register_ability3(plugin, num_params)
{
	new iKnifeId = get_param(1)
	get_string(2, Knife[iKnifeId][KNF_ABILITY3_NAME], LEN_ABILITY_NAME - 1)

	if (Knife[iKnifeId][KNF_ABILITY3_NAME][0] == EOS)
		return false

	KnifeF[iKnifeId][KNF_ABILITY3_CHARGE] = get_param_f(3)

	Knife[iKnifeId][KNF_ABILITY3_CALLBACK] = CreateOneForward(plugin, "efk_ability3", FP_CELL)
	if (Knife[iKnifeId][KNF_ABILITY3_CALLBACK] < 0)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_ability3) Callback third ability function not found (Knife ID: %d)", PLUGIN, iKnifeId)
		return false
	}

	return true
}

public bool:_21kc_register_ability4(plugin, num_params)
{
	new iKnifeId = get_param(1)
	get_string(2, Knife[iKnifeId][KNF_ABILITY4_NAME], LEN_ABILITY_NAME - 1)

	if (Knife[iKnifeId][KNF_ABILITY4_NAME][0] == EOS)
		return false

	KnifeF[iKnifeId][KNF_ABILITY4_CHARGE] = get_param_f(3)

	Knife[iKnifeId][KNF_ABILITY4_CALLBACK] = CreateOneForward(plugin, "efk_ability4", FP_CELL)
	if (Knife[iKnifeId][KNF_ABILITY4_CALLBACK] < 0)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_ability4) Callback fourth ability function not found (Knife ID: %d)", PLUGIN, iKnifeId)
		return false
	}

	return true
}

public _21kc_knife_set_anim_ext(plugin, num_params)
{
	Knife[get_param(1)][KNF_ANIM_EXT] = get_param(2)
}

public _21kc_knife_set_flags(plugin, num_params)
{
	SetKnifeFlag(get_param(1), get_param(2))
}

public _21kc_knife_set_sound(plugin, num_params)
{
	new iKnifeId = get_param(1)

	if (!g_tSoundKnife[iKnifeId])
		g_tSoundKnife[iKnifeId] = TrieCreate()

	new szOldPath[256], szNewPath[256]
	get_string(2, szOldPath, charsmax(szOldPath))
	get_string(3, szNewPath, charsmax(szNewPath))

	TrieSetString(g_tSoundKnife[iKnifeId], szOldPath, szNewPath)
}

public bool:_21kc_player_get_bunnyhop()
{
	new iPlayer = get_param(1)

	if (CheckPlayerGameFlag(iPlayer, PLGF_IS_DISABLED_INVENTORY))
		return false

	return Player[iPlayer][PlrIsBhopEnabled]
}

public _21kc_player_set_bunnyhop()
{
	Player[get_param(1)][PlrIsBhopEnabled] = bool:get_param(2)
}

public bool:_21kc_player_in_protection(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrSpawnProtectionTime] > get_gametime()
}

public _21kc_player_unprotection(plugin, num_params)
{
	player_unprotection(get_param(1))
}

public _21kc_player_give_knife(plugin, num_params)
{
	new iPlayer = get_param(1)
	new iKnifeId = get_param(2)
	new bool:bChangeDelay = bool:get_param(3)
	new bool:bCheckLevel = bool:get_param(4)

	if (Player[iPlayer][PlrKnife] == iKnifeId)
		return iKnifeId

	if (bCheckLevel && Knife[iKnifeId][KNF_ACCESS_LEVEL] > Player[iPlayer][PlrLevel])
		return -1

	return change_knife_core(iPlayer, iKnifeId, bChangeDelay)
}

public bool:_21kc_player_check_knife_access(plugin, num_params)
{
	new iPlayer = get_param(1)
	new iKnifeId = get_param(2)
	return check_knife_access(iPlayer, iKnifeId)
}

public _21kc_player_set_crosshair(plugin, num_params)
{
	player_set_crosshair(get_param(1), KnifeCrosshair:get_param(2))
}

public _21kc_player_set_powerdamage(plugin, num_params)
{
	new iPlayer = get_param(1)
	PlayerF[iPlayer][PlrPowerDamage] = get_param_f(2)
	PlayerF[iPlayer][PlrPowerDamageDelay] = get_gametime() + 0.5
}

public Float:_21kc_player_get_powerdamage(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrPowerDamage]
}

public _21kc_player_set_abil1_type(plugin, num_params)
{
	Player[get_param(1)][PlrAbility1Type] = AbilityType:get_param(2)
}

public VisionType:_21kc_player_get_vision(plugin, num_params)
{
	return Player[get_param(1)][PlrVision]
}

public _21kc_register_menu_item(plugin, num_params)
{
	if (g_iTotalMenuItems == MAX_MENUITEMS)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_menu_item) Menu item registration limit exceeded", PLUGIN)
		return -1
	}

	new iItem = g_iTotalMenuItems

	new szCallback[LEN_MENU_ITEM_FUNC]

	get_string(1, MenuItem[iItem][MItmName], LEN_MENU_ITEM_NAME - 1)
	get_string(2, szCallback, charsmax(szCallback))

	new pCallback = CreateOneForward(plugin, szCallback, FP_CELL)
	if (pCallback < 0)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_menu_item) Callback menu function not found ('%s')", PLUGIN, szCallback)
		return -1
	}

	MenuItem[iItem][MItmCallback] = pCallback

	g_iTotalMenuItems++

	return iItem
}

public _21kc_register_item(plugin, num_params)
{
	if (g_iTotalItems == MAX_ITEMS)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_item) Item registration limit exceeded", PLUGIN)
		return -1
	}

	new iItem = g_iTotalItems
	new szCallback[LEN_ITEM_FUNC]

	get_string(1, Item[iItem][ItmDescription], LEN_ITEM_DESCRIPTION - 1)
	get_string(2, Item[iItem][ItmChatDescription], LEN_ITEM_CHATDESCRIPTION - 1)

	get_string(3, szCallback, charsmax(szCallback))
	new pGiveCallback = CreateOneForward(plugin, szCallback, FP_CELL, FP_CELL)
	if (pGiveCallback < 0)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_register_item) Callback function %s not found", PLUGIN, szCallback)
		return -1
	}

	Item[iItem][ItmGiveCallback] = pGiveCallback
	Item[iItem][ItmCost] = get_param(4)
	Item[iItem][ItmLevel] = get_param(5)
	Item[iItem][ItmFlags] = get_param(6)

	if (equal(Item[iItem][ItmDescription], "ITEM_REGENERATION"))
		g_iRegenItemId = iItem
	else if (equal(Item[iItem][ItmDescription], "ITEM_CHARGEBOOSTER"))
		g_iChargeBoosterItemId = iItem
	else if (equal(Item[iItem][ItmDescription], "ITEM_HPSCAN"))
		g_iHPScanItemId = iItem

	g_iTotalItems++

	return iItem
}

public bool:_21kc_item_register_enable_handler(plugin, num_params)
{
	new iItem = get_param(1)

	if (iItem >= g_iTotalItems)
		return false

	new szCallback[LEN_ITEM_FUNC]
	get_string(2, szCallback, charsmax(szCallback))

	new pCallback = CreateOneForward(plugin, szCallback, FP_CELL, FP_CELL, FP_CELL)
	if (pCallback < 0)
	{
		log_error(AMX_ERR_NATIVE, "[%s] (kc_item_register_enable_handler) Callback function %s not found", PLUGIN, szCallback)
		return false
	}

	Item[iItem][ItmModeCallback] = pCallback

	return true
}

public ItemGiveCode:_21kc_player_give_item(plugin, num_params)
{
	return player_give_item(get_param(1), get_param(2), get_param(3))
}

public _21kc_player_give_random_item(plugin, num_params)
{
	new iPlayer = get_param(1)
	new iSenderImpulse = get_param(2)

	if (!g_iTotalItems)
		return -1

	new iPlayerLevel = Player[iPlayer][PlrLevel]

	new iAvailableItems[MAX_ITEMS]
	for (new i; i < g_iTotalItems; i++)
		iAvailableItems[i] = i

	new iAvailableItemsNum = g_iTotalItems
	for (new i, iItemId; iAvailableItemsNum > 0; iAvailableItemsNum--)
	{
		i = random(iAvailableItemsNum)
		iItemId = iAvailableItems[i]
		iAvailableItems[i] = iAvailableItems[iAvailableItemsNum - 1]

		if (Item[iItemId][ItmLevel] > iPlayerLevel)
			continue

		if (player_give_item(iPlayer, iItemId, iSenderImpulse) <= ITEM_NEXT_SPAWN)
			return iItemId
	}

	return -1
}

public _21kc_player_get_knife(plugin, num_params)
{
	return Player[get_param(1)][PlrKnife]
}

public _21kc_knife_get_classname(plugin, num_params)
{
	new iKnifeId = get_param(1)
	new iNameLen = get_param(3)
	set_string(2, Knife[iKnifeId][KNF_NAME], iNameLen)
}

public Float:_21kc_player_get_maxspeed(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrMaxSpeed]
}

public _21kc_player_set_maxspeed(plugin, num_params)
{
	new iPlayer = get_param(1)
	new Float:fSpeed = get_param_f(2)

	engfunc(EngFunc_SetClientMaxspeed, iPlayer, fSpeed)
	PlayerF[iPlayer][PlrMaxSpeed] = fSpeed
}

public Float:_21kc_player_get_maxhealth(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrMaxHP]
}

public _21kc_player_set_level(plugin, num_params)
{
	Player[get_param(1)][PlrLevel] = get_param(2)
}

public _21kc_player_get_level(plugin, num_params)
{
	return Player[get_param(1)][PlrLevel]
}

public _21kc_player_set_favknife(plugin, num_params)
{
	new iKnifeId = get_param(2)
	if (is_valid_knife(iKnifeId))
		Player[get_param(1)][PlrFavKnife] = iKnifeId
}

public _21kc_player_set_crit_chance(plugin, num_params)
{
	PlayerF[get_param(1)][PlrCritChance] = get_param_f(2)
}

public bool:_21kc_player_can_ability(plugin, num_params)
{
	new iPlayer = get_param(1)

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return false

	if (g_iSilenceTeam > -1 && g_iSilenceTeam != Player[iPlayer][PlrTeam])
		return false

	if (g_bIsRoundEnded)
		return false

	if (Player[iPlayer][PlrCaptureType] != CAPTURE_NONE)
		return false

	switch (get_param(2))
	{
		case 1:
		{
			if (PlayerF[iPlayer][PlrAbility1Charge] != 100.0
				|| Knife[Player[iPlayer][PlrKnife]][KNF_ABILITY1_NAME][0] == EOS)
				return false
		}
		case 2:
		{
			if (PlayerF[iPlayer][PlrAbility2Charge] != 100.0
				|| Knife[Player[iPlayer][PlrKnife]][KNF_ABILITY2_NAME][0] == EOS)
				return false
		}
		case 3:
		{
			if (PlayerF[iPlayer][PlrAbility3Charge] != 100.0
				|| Knife[Player[iPlayer][PlrKnife]][KNF_ABILITY3_NAME][0] == EOS)
				return false
		}
		case 4:
		{
			if (PlayerF[iPlayer][PlrAbility4Charge] != 100.0
				|| Knife[Player[iPlayer][PlrKnife]][KNF_ABILITY4_NAME][0] == EOS)
				return false
		}
	}

	return true
}

public bool:_21kc_player_is_abil1_ready(plugin, num_params)
{
	new iPlayer = get_param(1)
	return PlayerF[iPlayer][PlrAbility1Charge] >= 100.0 && !Player[iPlayer][PlrAbility1Disabled]
}

public Float:_21kc_player_get_abil1_charge(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrAbility1Charge]
}

public _21kc_player_set_abil1_charge(plugin, num_params)
{
	new iPlayer = get_param(1)
	new Float:fCharge = get_param_f(2)

	if (fCharge != -1.0)
	{
		PlayerF[iPlayer][PlrAbility1Charge] = fCharge
		PlayerF[iPlayer][PlrAbility1LastChange] = get_gametime()
	}
	else
	{
		player_reset_abil1_charge(iPlayer)
	}
}

public _21kc_player_set_abil1_dist(plugin, num_params)
{
	new iPlayer = get_param(1)
	new Float:fMinDist = get_param_f(2)
	new Float:fMaxDist = get_param_f(3)

	new iKnifeId = Player[iPlayer][PlrKnife]

	if (fMinDist == -1.0)
		fMinDist = KnifeF[iKnifeId][KNF_ABILITY1_MIN_DIST]

	if (fMaxDist == -1.0)
		fMaxDist = KnifeF[iKnifeId][KNF_ABILITY1_MAX_DIST]

	PlayerF[iPlayer][PlrAbility1MinDist] = fMinDist
	PlayerF[iPlayer][PlrAbility1MaxDist] = fMaxDist
}

public Float:_21kc_player_get_abil2_charge(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrAbility2Charge]
}

public _21kc_player_set_abil2_charge(plugin, num_params)
{
	new iPlayer = get_param(1)
	new Float:fValue = get_param_f(2)

	if (Knife[Player[iPlayer][PlrKnife]][KNF_ABILITY2_NAME][0] == EOS)
		return

	PlayerF[iPlayer][PlrAbility2Charge] = fValue
}

public Float:_21kc_player_get_abil3_charge(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrAbility3Charge]
}

public _21kc_player_set_abil3_charge(plugin, num_params)
{
	new iPlayer = get_param(1)
	new Float:fValue = get_param_f(2)

	if (Knife[Player[iPlayer][PlrKnife]][KNF_ABILITY3_NAME][0] == EOS)
		return

	PlayerF[iPlayer][PlrAbility3Charge] = fValue
}

public Float:_21kc_player_get_abil4_charge(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrAbility4Charge]
}

public _21kc_player_set_abil4_charge(plugin, num_params)
{
	new iPlayer = get_param(1)
	new Float:fValue = get_param_f(2)

	if (Knife[Player[iPlayer][PlrKnife]][KNF_ABILITY4_NAME][0] == EOS)
		return

	PlayerF[iPlayer][PlrAbility4Charge] = fValue
}

public bool:_21kc_player_blind(plugin, num_params)
{
	return player_blind(get_param(1), get_param(2), get_param_f(3))
}

public _21kc_player_unblind(plugin, num_params)
{
	new iPlayer = get_param(1)
	if (Player[iPlayer][PlrVision] == VISION_BLIND)
		screenfades_out(iPlayer, true)
}

public _21kc_player_add_glow(plugin, num_params)
{
	return player_add_glow(get_param(1), get_param_f(2), get_param(3), get_param(4), get_param(5))
}

public _21kc_player_sub_glow(plugin, num_params)
{
	new iPlayer = get_param(1)
	new r = get_param(2)
	new g = get_param(3)
	new b = get_param(4)

	for (new i; i < Player[iPlayer][PlrGlowCount]; i++)
	{
		if (Player[iPlayer][PlrGlowR][i] == r && Player[iPlayer][PlrGlowG][i] == g && Player[iPlayer][PlrGlowB][i] == b)
			PlayerF[iPlayer][PlrGlowTime][i] = 0.1
	}
}

public _21kc_player_invision(plugin, num_params)
{
	new iPlayer = get_param(1)
	new Float:fGameTime = get_gametime()
	new iMode = get_param(4)

	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
		case VIS_CLONE: player_remove_clone(iPlayer)
		case VIS_SHADOW: player_remove_shadow(iPlayer)
	}

	set_entvar(iPlayer, var_effects, 0)
	set_entvar(iPlayer, var_rendercolor, NULL_VECTOR)
	set_entvar(iPlayer, var_rendermode, kRenderTransAlpha)
	set_entvar(iPlayer, var_renderamt, INVISIBLE_AMT_FRIEND + 0.0)
	set_entvar(iPlayer, var_renderfx, iMode ? kRenderFxDistort : kRenderFxNone)

	new iHatEnt = Player[iPlayer][PlrHatEnt]
	if (Player[iPlayer][PlrHatModelIndex] && !is_nullent(iHatEnt))
	{
		set_entvar(iHatEnt, var_effects, 0)
		set_entvar(iHatEnt, var_rendercolor, NULL_VECTOR)
		set_entvar(iHatEnt, var_rendermode, kRenderTransAlpha)
		set_entvar(iHatEnt, var_renderamt, INVISIBLE_AMT_FRIEND + 0.0)
		set_entvar(iHatEnt, var_renderfx, iMode ? kRenderFxDistort : kRenderFxNone)
	}

	if (!iMode)
	{
		Player[iPlayer][PlrVisibility] = VIS_INVISION
		Player[iPlayer][PlrClone] = get_param(3)

		rg_set_user_footsteps(iPlayer, true)
	}
	else
		Player[iPlayer][PlrVisibility] = VIS_TRANS

	if (PlayerF[iPlayer][PlrChilled] > 0.0)
	{
		send_msg_TE_KILLBEAM(iPlayer, MSG_ALL)
	}

	PlayerF[iPlayer][PlrInvisionTime] = fGameTime  + get_param_f(2)
	PlayerF[iPlayer][PlrInvisionStartTime] = fGameTime

	ExecuteForward(forward_invisible, _, iPlayer)
}

public _21kc_player_uninvision(plugin, num_params)
{
	new iPlayer = get_param(1)
	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
	}
}

public _21kc_invision_unfake(plugin, num_params)
{
	Player[get_param(1)][PlrClone] = 0
}

public bool:_21kc_player_shadow(plugin, num_params)
{
	new iPlayer = get_param(1)
	new iTarget = get_param(2)

	if (!can_shadow(iPlayer, iTarget))
		return false

	player_unburn(iPlayer)
	player_unfreeze(iPlayer)
	player_unchill(iPlayer)
	player_reset_visibility(iPlayer)
	player_set_windboost(iPlayer, WINDBOOST_NONE)

	new iEnt = NULLENT, iBeamOwner
	while ((iEnt = rg_find_ent_by_class(iEnt, SZ_BEAM)))
		if (get_entvar(iEnt, var_aiment) == iPlayer)
		{
			iBeamOwner = get_entvar(iEnt, var_owner)
			if (!is_entity_player(iBeamOwner))
				set_entvar(iBeamOwner, var_nextthink, get_gametime())
		}

	set_entvar(iPlayer, var_effects, EF_NODRAW)
	set_entvar(iPlayer, var_movetype, MOVETYPE_NOCLIP)
	set_entvar(iPlayer, var_solid, SOLID_NOT)
	set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) | PLAYER_PREVENT_JUMP)

	player_set_camera(iPlayer, CAMERA_MODE_3RD)
	Player[iPlayer][PlrCustomCameraEnt] = iPlayer

	new iHatEnt = Player[iPlayer][PlrHatEnt]
	if (!is_nullent(iHatEnt))
		set_entvar(iHatEnt, var_effects, EF_NODRAW)

	if (Player[iPlayer][PlrVision] == VISION_BLIND)
		screenfades_out(iPlayer, true)
	else
	{
		send_msg_ScreenFade((1<<12), (1<<8), (1<<4), {0, 0, 255}, 100, MSG_ONE, _, iPlayer)
	}

	Player[iPlayer][PlrVisibility] = VIS_SHADOW;
	SetPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY);
	Player[iPlayer][PlrClone] = iTarget
	PlayerF[iPlayer][PlrCloneTimeValue] = 0.0
	PlayerF[iPlayer][PlrCloneRegenTime] = get_gametime() + 0.5

	return true
}

public _21kc_player_get_shadow_target()
{
	return player_get_shadow_target(get_param(1))
}

public _21kc_player_get_shadow_activator()
{
	new iPlayer = get_param(1)
	for (new i = 1; i <= MaxClients; i++)
	{
		if (CheckPlayerGameFlag(i, PLGF_IS_ALIVE) && player_get_shadow_target(i) == iPlayer)
			return i
	}
	return 0
}

public bool:_21kc_player_unshadow(plugin, num_params)
{
	new iPlayer = get_param(1)
	if (Player[iPlayer][PlrVisibility] == VIS_SHADOW)
		return player_remove_shadow(iPlayer, bool:get_param(2))

	return false
}

public bool:_21kc_player_clone(plugin, num_params)
{
	return player_clone(get_param(1), get_param(2))
}

public _21kc_player_unclone(plugin, num_params)
{
	new iPlayer = get_param(1)
	if (Player[iPlayer][PlrVisibility] == VIS_CLONE)
		player_remove_clone(iPlayer)
}

public bool:_21kc_darkness(plugin, num_params)
{
	new iTeam = get_param(1)

	if (g_iDarknessTeam > -1 || g_bIsRoundEnded)
		return false

	for (new i = 1; i <= MaxClients; i++)
	{
		if (CheckPlayerGameFlag(i, PLGF_IS_ALIVE) && Player[i][PlrVision] == VISION_NORMAL && iTeam == Player[i][PlrTeam])
			Player[i][PlrVision] = VISION_NIGHT
	}

	g_iSkyColors[0] = get_pcvar_num(g_pCvarSkyColors[0])
	g_iSkyColors[1] = get_pcvar_num(g_pCvarSkyColors[1])
	g_iSkyColors[2] = get_pcvar_num(g_pCvarSkyColors[2])

	if (g_tFogData)
	{
		new iFogEnt = rg_find_ent_by_class(MaxClients, "env_fog", true)
		if (iFogEnt)
		{
			set_entvar(iFogEnt, var_flags, FL_KILLME)
			send_msg_Fog(1.0 / 524288.0, _, MSG_ALL)
		}
	}

	set_task(get_param_f(2), "task_darkness", TASK_DARKNESS)
	set_lights("a")
	g_iDarknessTeam = iTeam

	return true
}

public bool:_21kc_player_in_darkness(plugin, num_params)
{
	new iPlayer = get_param(1)
	return g_iDarknessTeam > 0
		&& Player[iPlayer][PlrTeam] != g_iDarknessTeam
		&& Player[iPlayer][PlrVision] != VISION_NIGHT
}

public bool:_21kc_silence(plugin, num_params)
{
	new iTeam = get_param(1)

	if (g_iSilenceTeam > -1 || g_bIsRoundEnded)
		return false

	for (new i = 1; i <= MaxClients; i++)
	{
		if (CheckPlayerGameFlag(i, PLGF_IS_ALIVE))
		{
			if (iTeam != Player[i][PlrTeam])
			{
				if (Player[i][PlrVisibility] < VIS_INVISION)
				{
					send_msg_TE_PLAYERATTACHMENT(i, 35.0, g_pSilenceSpr, 100, MSG_ALL)
				}
			}
			else if (Player[i][PlrConcentBlock])
			{
				new iWeapon = get_active_weapon(i)
				if (!is_nullent(iWeapon))
					set_member(iWeapon, m_Weapon_flTimeWeaponIdle, 0.1)
			}
		}
	}

	set_task(get_param_f(2), "task_silence", TASK_SILENCE)
	g_iSilenceTeam = iTeam

	return true
}

public bool:_21kc_player_in_silence(plugin, num_params)
{
	return g_iSilenceTeam > -1 && g_iSilenceTeam != Player[get_param(1)][PlrTeam]
}

public _21kc_player_disenergy(plugin, num_params)
{
	new iPlayer = get_param(1)
	new Float:fValue = random_float(20.0, 25.0)

	PlayerF[iPlayer][PlrAbility1Charge] = floatmax(0.0, PlayerF[iPlayer][PlrAbility1Charge] - fValue)
	PlayerF[iPlayer][PlrAbility2Charge] = floatmax(0.0, PlayerF[iPlayer][PlrAbility2Charge] - fValue)
	PlayerF[iPlayer][PlrAbility3Charge] = floatmax(0.0, PlayerF[iPlayer][PlrAbility3Charge] - fValue)
	PlayerF[iPlayer][PlrAbility4Charge] = floatmax(0.0, PlayerF[iPlayer][PlrAbility4Charge] - fValue)

	player_unlevitation(iPlayer)

	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
		case VIS_CLONE: player_remove_clone(iPlayer)
		case VIS_SHADOW: player_remove_shadow(iPlayer, true)
	}

	ExecuteForward(forward_disenergy, _, iPlayer)
}

public _21kc_player_slow(plugin, num_params)
{
	player_slow(get_param(1), get_param_f(2), get_param_f(3))
}

public _21kc_player_rush(plugin, num_params)
{
	player_rush(get_param(1), get_param_f(2), get_param_f(3))
}

public WindBoostType:_21kc_player_get_windboost(plugin, num_params)
{
	return Player[get_param(1)][PlrWindBoostType]
}

public _21kc_player_set_windboost(plugin, num_params)
{
	player_set_windboost(get_param(1), WindBoostType:get_param(2))
}

public _21kc_player_get_bair(plugin, num_params)
{
	new iPlayer = get_param(1)
	if (PlayerF[iPlayer][PlrBlockAirAcTime] > 0.0)
		return Player[iPlayer][PlrBlockAirAcFlags]
	return 0
}

public _21kc_player_set_bair(plugin, num_params)
{
	new iPlayer = get_param(1), iFlags = get_param(2)

	if (Player[iPlayer][PlrWindBoostType] == WINDBOOST_POSITIVE)
		iFlags &= FL_BAIR_CLIMB

	if (!iFlags)
		return

	PlayerF[iPlayer][PlrBlockAirAcTime] = get_gametime() + 1.0
	Player[iPlayer][PlrBlockAirAcFlags] |= iFlags
	if (iFlags & FL_BAIR_CLIMB)
	{
		new iUser3 = get_entvar(iPlayer, var_iuser3)
		set_entvar(iPlayer, var_iuser3, iUser3 | PLAYER_PREVENT_CLIMB)
	}
}

public bool:_21kc_player_burn(plugin, num_params)
{
	return player_burn(get_param(1), get_param(2), get_param(3))
}

public _21kc_player_in_burn()
{
	return Player[get_param(1)][PlrBurned]
}

public _21kc_player_unburn(plugin, num_params)
{
	player_unburn(get_param(1))
}

public bool:_21kc_player_freeze(plugin, num_params)
{
	return player_freeze(get_param(1), get_param_f(2), get_param(3))
}

public bool:_21kc_player_in_freeze(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrFrozen] > 0.0
}

public _21kc_player_unfreeze(plugin, num_params)
{
	player_unfreeze(get_param(1))
}

public bool:_21kc_player_chill(plugin, num_params)
{
	return player_chill(get_param(1), get_param_f(2), get_param(3))
}

public bool:_21kc_player_in_chill(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrChilled] > 0.0
}

public _21kc_player_unchill(plugin, num_params)
{
	player_unchill(get_param(1))
}

public bool:_21kc_player_set_capture(plugin, num_params)
{
	new iPlayer = get_param(1)
	new CaptureType:iCaptureType = CaptureType:get_param(2)

	if (iCaptureType == CAPTURE_NONE)
	{
		player_uncapture(iPlayer)
		return true
	}

	new CaptureAnim:iCaptureAnim = CaptureAnim:get_param(3)
	new Float:fCaptureTime = get_param_f(4)
	new bool:bIgnoreGroundDist = bool:get_param(5)
	new bool:bHideHat = bool:get_param(6)

	if (CheckPlayerGameFlag(iPlayer, PLGF_IN_UNABILITY))
		return false

	if (!CheckPlayerGameFlag(iPlayer, PLGF_IS_ALIVE))
		return false

	if (get_entvar(iPlayer, var_waterlevel) >= 2)
		return false

	if (!bIgnoreGroundDist && !(get_entvar(iPlayer, var_flags) & FL_ONGROUND))
	{
		new Float:vOrigin[3], Float:vFloorOrigin[3], Float:fFraction
		get_entvar(iPlayer, var_origin, vOrigin)
		xs_vec_copy(vOrigin, vFloorOrigin)
		vFloorOrigin[2] -= 96.0

		new iTrace = create_tr2()
		engfunc(EngFunc_TraceHull, vOrigin, vFloorOrigin, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTrace)
		get_tr2(iTrace, TR_flFraction, fFraction)
		free_tr2(iTrace)

		if (fFraction == 1.0)
			return false
	}

	player_uncapture(iPlayer)
	player_unlevitation(iPlayer)
	player_unfreeze(iPlayer)

	player_drop_train(iPlayer)

	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_TRANS: player_remove_trans(iPlayer)
		case VIS_INVISION: player_remove_invision(iPlayer)
	}

	set_entvar(iPlayer, var_iuser3, get_entvar(iPlayer, var_iuser3) | PLAYER_PREVENT_DUCK | PLAYER_PREVENT_JUMP)

	engfunc(EngFunc_SetClientMaxspeed, iPlayer, MIN_PLAYER_SPEED)
	PlayerF[iPlayer][PlrMaxSpeed] = MIN_PLAYER_SPEED
	PlayerF[iPlayer][PlrRushTime] = 0.0

	PlayerF[iPlayer][PlrCaptured] = fCaptureTime + get_gametime()
	Player[iPlayer][PlrCaptureType] = iCaptureType
	get_entvar(iPlayer, var_v_angle, PlayerF[iPlayer][PlrCaptureAngles])

	rg_set_user_footsteps(iPlayer, true)

	new iWeapon = get_member(iPlayer, m_pActiveItem)

	if (!is_nullent(iWeapon))
	{
		set_member(iWeapon, m_Weapon_flNextPrimaryAttack, 1.0)
		set_member(iWeapon, m_Weapon_flNextSecondaryAttack, 1.0)

		new iWeaponType = get_member(iWeapon, m_iId)

		if (iWeaponType == CSW_HEGRENADE || iWeaponType == CSW_SMOKEGRENADE || iWeaponType == CSW_FLASHBANG)
		{
			set_member(iWeapon, m_flReleaseThrow, -1.0)
			set_member(iWeapon, m_flStartThrow, 0.0)
			ExecuteHamB(Ham_Item_Deploy, iWeapon)
		}
	}

	if (iCaptureType == CAPTURE_NORMAL
		&& Player[iPlayer][PlrVisibility] == VIS_SHADOW
		&& PlayerF[iPlayer][PlrCloneTimeValue] > 0.0)
	{
			message_begin(MSG_ONE_UNRELIABLE, 108, {0, 0, 0}, iPlayer)
			write_short(0)
			message_end()

			PlayerF[iPlayer][PlrCloneTimeValue] = 0.0
	}

	if (iCaptureAnim != CAP_ANIM_NONE)
	{
		set_entvar(iPlayer, var_sequence, iCaptureAnim)
		set_entvar(iPlayer, var_gaitsequence, iCaptureAnim)

		switch (iCaptureAnim)
		{
			case CAP_ANIM_TENTACLES: set_member(iPlayer, m_flFrameRate, 640.0)
			case CAP_ANIM_IRON_MAIDEN: set_member(iPlayer, m_flFrameRate, 284.4)
			case CAP_ANIM_GHOST_RELEASE: set_member(iPlayer, m_flFrameRate, 320.0)
		}

		set_entvar(iPlayer, var_frame, 0.0)
		set_entvar(iPlayer, var_framerate, 1.0)
		set_entvar(iPlayer, var_animtime, get_gametime())

		set_member(iPlayer, m_fSequenceLoops, 0)
		set_member(iPlayer, m_fSequenceFinished, 0)
		set_member(iPlayer, m_flGroundSpeed, 0.0)
		set_member(iPlayer, m_Activity, ACT_SLEEP)
		set_member(iPlayer, m_IdealActivity, ACT_SLEEP)

		get_entvar(iPlayer, var_angles, PlayerF[iPlayer][PlrFixedCaptureAngles])
		PlayerF[iPlayer][PlrFixedCaptureAngles][0] = 0.0
		PlayerF[iPlayer][PlrFixedCaptureAngles][2] = 0.0;

		SetPlayerGameFlag(iPlayer, PLGF_IN_FIXED_ANIMATION);
	}

	if (bHideHat)
	{
		new iHatEnt = Player[iPlayer][PlrHatEnt]
		if (iHatEnt)
			set_entvar(iHatEnt, var_effects, EF_NODRAW)
	}

	ExecuteForward(forward_capture, _, iPlayer, iCaptureType)

	return true
}

public CaptureType:_21kc_player_get_capture(plugin, num_params)
{
	return Player[get_param(1)][PlrCaptureType]
}

public _21kc_player_levitation(plugin, num_params)
{
	return player_levitation(get_param(1))
}

public _21kc_player_unlevitation(plugin, num_params)
{
	player_unlevitation(get_param(1))
}

public bool:_21kc_player_in_debuffed(plugin, num_params)
{
	return is_user_debuffed(get_param(1))
}

public bool:_21kc_player_swap(plugin, num_params)
{
	new iPlayer = get_param(1)
	new iTarget = get_param(2)

	if (Player[iPlayer][PlrTeam] == Player[iTarget][PlrTeam])
		return friendly_swap(iPlayer, iTarget)

	new Float:fGameTime = get_gametime(),
		Float:fPlayerHealth, Float:fTargetHealth,
		Float:vPlayerOrigin[3], Float:vTargetOrigin[3],
		Float:vPlayerVelocity[3], Float:vTargetVelocity[3],
		Float:vPlayerVAngles[3], Float:vTargetVAngles[3],
		iPlayerFlags, vTargetFlags

	player_unlevitation(iTarget)
	player_uncapture(iTarget)

	fPlayerHealth = get_entvar(iPlayer, var_health)
	fTargetHealth = get_entvar(iTarget, var_health)

	get_entvar(iPlayer, var_origin, vPlayerOrigin)
	get_entvar(iTarget, var_origin, vTargetOrigin)

	iPlayerFlags = get_entvar(iPlayer, var_flags)
	vTargetFlags = get_entvar(iTarget, var_flags)

	if (!(iPlayerFlags & FL_DUCKING) && (vTargetFlags & FL_DUCKING))
	{
		set_entvar(iPlayer, var_flags, iPlayerFlags | FL_DUCKING)
		engfunc(EngFunc_SetSize, iPlayer, {-16.0, -16.0, -18.0 }, { 16.0,  16.0,  32.0 })
		engfunc(EngFunc_SetOrigin, iPlayer, vTargetOrigin)
		set_entvar(iPlayer, var_origin, vTargetOrigin)

		vPlayerOrigin[2] -= 18.0
		engfunc(EngFunc_SetOrigin, iTarget, vPlayerOrigin)
		set_entvar(iTarget, var_origin, vPlayerOrigin)
	}
	else if ((iPlayerFlags & FL_DUCKING) && !(vTargetFlags & FL_DUCKING))
	{
		set_entvar(iTarget, var_flags, iPlayerFlags | FL_DUCKING)
		engfunc(EngFunc_SetSize, iTarget, {-16.0, -16.0, -18.0}, {16.0,  16.0, 32.0})
		engfunc(EngFunc_SetOrigin, iTarget, vPlayerOrigin)
		set_entvar(iTarget, var_origin, vPlayerOrigin)

		vTargetOrigin[2] -= 18.0
		engfunc(EngFunc_SetOrigin, iPlayer, vTargetOrigin)
		set_entvar(iPlayer, var_origin, vTargetOrigin)
	}
	else
	{
		engfunc(EngFunc_SetOrigin, iPlayer, vTargetOrigin)
		engfunc(EngFunc_SetOrigin, iTarget, vPlayerOrigin)
		set_entvar(iPlayer, var_origin, vTargetOrigin)
		set_entvar(iTarget, var_origin, vPlayerOrigin)
	}

	player_check_stuck(iPlayer)
	player_check_stuck(iTarget)
	PlayerF[iPlayer][PlrCheckStuckTime] = fGameTime + CHECK_STUCK_DELAY
	PlayerF[iTarget][PlrCheckStuckTime] = fGameTime + CHECK_STUCK_DELAY

	get_entvar(iPlayer, var_v_angle, vPlayerVAngles)
	get_entvar(iTarget, var_v_angle, vTargetVAngles)

	get_entvar(iPlayer, var_velocity, vPlayerVelocity)
	get_entvar(iTarget, var_velocity, vTargetVelocity)

	set_entvar(iPlayer, var_health, fTargetHealth)
	set_entvar(iTarget, var_health, fPlayerHealth)

	set_entvar(iPlayer, var_angles, vTargetVAngles)
	set_entvar(iTarget, var_angles, vPlayerVAngles)

	set_entvar(iPlayer, var_v_angle, vTargetVAngles)
	set_entvar(iTarget, var_v_angle, vPlayerVAngles)

	set_entvar(iPlayer, var_fixangle, 1)
	set_entvar(iTarget, var_fixangle, 1)

	set_entvar(iPlayer, var_velocity, vTargetVelocity)
	set_entvar(iTarget, var_velocity, vPlayerVelocity)

	float_swap(PlayerF[iPlayer][PlrPowerDamage], PlayerF[iTarget][PlrPowerDamage])
	float_swap(PlayerF[iPlayer][PlrPowerDamageDelay], PlayerF[iTarget][PlrPowerDamageDelay])

	if (Player[iPlayer][PlrVision] == VISION_BLIND)
	{
		player_blind(iTarget, 1, PlayerF[iPlayer][PlrBlindTime] - fGameTime)
		screenfades_out(iPlayer, true)
	}

	for (new i; i < 3; i++)
	{
		if (PlayerF[iPlayer][PlrSlowTime][i] > 0.0)
		{
			player_slow(iTarget, PlayerF[iPlayer][PlrSlowSpeed][i] / player_get_knife_maxspeed(iPlayer), PlayerF[iPlayer][PlrSlowTime][i] - fGameTime)
			PlayerF[iPlayer][PlrSlowTime][i] = 0.1
		}
	}
	engfunc(EngFunc_SetClientMaxspeed, iPlayer, player_get_knife_maxspeed(iPlayer))

	if (Player[iPlayer][PlrWindBoostType] == WINDBOOST_NEGATIVE)
	{
		player_set_windboost(iPlayer, WINDBOOST_NONE, false)
		player_update_gravity(iPlayer)

		player_set_windboost(iTarget, WINDBOOST_NEGATIVE, false)
		player_update_gravity(iTarget)
	}

	if (Player[iPlayer][PlrBurned])
	{
		player_burn(iTarget, iPlayer, Player[iPlayer][PlrBurned], true)
		player_unburn(iPlayer)
	}
	else if (PlayerF[iPlayer][PlrFrozen] > 0.0)
	{
		player_freeze(iTarget, PlayerF[iPlayer][PlrFrozen] - fGameTime, iPlayer)
		player_unfreeze(iPlayer)
	}

	if (PlayerF[iPlayer][PlrChilled] > 0.0)
	{
		player_chill(iTarget, PlayerF[iPlayer][PlrChilled] - fGameTime, iPlayer)
		player_unchill(iPlayer)
	}

	new iBeamEnt = NULLENT
	while ((iBeamEnt = rg_find_ent_by_class(iBeamEnt, SZ_BEAM)))
		if (get_entvar(iBeamEnt, var_aiment) == iPlayer && get_entvar(iBeamEnt, var_impulse) == IMPULSE_ACIDTRAP_BEAM)
			Beam_EntsInit(iBeamEnt, get_entvar(iBeamEnt, var_owner), iTarget)

	PlayerF[iTarget][PlrSwapTime] = fGameTime + get_param_f(3)

	player_set_override_attacker(iTarget, iPlayer, 2.0)

	ExecuteForward(forward_swap, _, iPlayer, iTarget)

	return true
}

public Float:_21kc_player_get_swap(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrSwapTime]
}

public _21kc_player_set_water_transparent(plugin, num_params)
{
	Player[get_param(1)][PlrWaterTransparent] = bool:get_param(2)
}

public _21kc_player_get_concentblock(plugin, num_params)
{
	return Player[get_param(1)][PlrConcentBlock] != 0
}

public bool:_21kc_player_set_concentblock(plugin, num_params)
{
	new iPlayer = get_param(1)

	if (Float:get_member(iPlayer, m_flNextAttack) > 0.0)
		return false

	new iWeapon = get_active_weapon(iPlayer)
	if (is_nullent(iWeapon) || get_member(iWeapon, m_iId) != CSW_KNIFE)
		return false

	new iSeq = get_param(2)
	if (!iSeq)
	{
		Player[iPlayer][PlrConcentBlock] = 0
		return false
	}

	Player[iPlayer][PlrConcentBlock] = iSeq
	set_member(iWeapon, m_Weapon_flTimeWeaponIdle, get_param_f(3))

	return true
}

public _21kc_player_apply_concentblock(plugin, num_params)
{
	return player_apply_concentblock(get_param(1), get_param(2),
		AttackHeaviness:get_param(3),
		get_param_f(4), bool:get_param(5))
}

public bool:_21kc_player_reflection_start(plugin, num_params)
{
	return player_reflection_start(get_param(1), get_param_f(2))
}

public bool:_21kc_player_in_reflection(plugin, num_params)
{
	new iPlayer = get_param(1)
	return is_entity_player(iPlayer) && player_in_reflection(iPlayer)
}

public _21kc_player_reflection_stop(plugin, num_params)
{
	player_reflection_stop(get_param(1))
}

public _21kc_player_reflection_done(plugin, num_params)
{
	ExecuteForward(forward_reflection, _, get_param(1), get_param(1))
}

public bool:_21kc_player_heal()
{
	return player_heal(get_param(1), get_param_f(2), get_param(3))
}

public bool:_21kc_player_reburn(plugin, num_params)
{
	new iPlayer = get_param(1)

	if (PlayerState[iPlayer][3][StateCaptureType] != CAPTURE_NONE)
		return false

	new iFlags = get_entvar(iPlayer, var_flags)
	new Float:fGameTime = get_gametime()

	if (!(iFlags & FL_DUCKING) && (PlayerState[iPlayer][3][StateFlags] & FL_DUCKING))
	{
		set_entvar(iPlayer, var_flags, iFlags | FL_DUCKING)
		engfunc(EngFunc_SetSize, iPlayer, {-16.0, -16.0, -18.0 }, { 16.0,  16.0,  32.0 })
	}

	engfunc(EngFunc_SetOrigin, iPlayer, PlayerStateF[iPlayer][3][StateOrigin])
	set_entvar(iPlayer, var_origin, PlayerStateF[iPlayer][3][StateOrigin])

	player_check_stuck(iPlayer)
	PlayerF[iPlayer][PlrCheckStuckTime] = fGameTime + CHECK_STUCK_DELAY

	set_entvar(iPlayer, var_velocity, PlayerStateF[iPlayer][3][StateVelocity])
	set_entvar(iPlayer, var_angles, PlayerStateF[iPlayer][3][StateVAngles])
	set_entvar(iPlayer, var_v_angle, PlayerStateF[iPlayer][3][StateVAngles])
	set_entvar(iPlayer, var_fixangle, 1)

	new iWeapon = get_active_weapon(iPlayer)
	if (!is_nullent(iWeapon) && get_member(iWeapon, m_iId) == CSW_KNIFE)
	{
		set_member(iWeapon, m_Weapon_flNextPrimaryAttack,
			PlayerStateF[iPlayer][3][StateNextPrimAttack], 4)
		set_member(iWeapon, m_Weapon_flNextSecondaryAttack,
			PlayerStateF[iPlayer][3][StateNextSecondAttack], 4)
	}

	new Float:fDeltaHealth = floatmax(PlayerStateF[iPlayer][3][StateMaxHP] - PlayerF[iPlayer][PlrMaxHP], 0.0)
	if (PlayerStateF[iPlayer][3][StateHealth] > PlayerStateF[iPlayer][3][StateMaxHP] - fDeltaHealth)
		set_entvar(iPlayer, var_health, PlayerStateF[iPlayer][3][StateHealth] - fDeltaHealth)
	else
		set_entvar(iPlayer, var_health, PlayerStateF[iPlayer][3][StateHealth])

	if (PlayerF[iPlayer][PlrBlindTime] > fGameTime)
		screenfades_out(iPlayer, true)

	player_remove_glow(iPlayer)
	player_unburn(iPlayer)
	player_unfreeze(iPlayer)
	player_unchill(iPlayer)

	PlayerF[iPlayer][PlrAbility1Charge] = PlayerStateF[iPlayer][3][StateAbility1Charge]
	PlayerF[iPlayer][PlrAbility2Charge] = PlayerStateF[iPlayer][3][StateAbility2Charge]
	PlayerF[iPlayer][PlrAbility3Charge] = PlayerStateF[iPlayer][3][StateAbility3Charge]
	PlayerF[iPlayer][PlrAbility4Charge] = PlayerStateF[iPlayer][3][StateAbility4Charge]

	engfunc(EngFunc_SetClientMaxspeed, iPlayer, PlayerStateF[iPlayer][3][StateMaxSpeed])
	PlayerF[iPlayer][PlrMaxSpeed] = PlayerStateF[iPlayer][3][StateMaxSpeed]
	for (new i = 0; i < 3; i++)
	{
		PlayerF[iPlayer][PlrSlowTime][i] = PlayerStateF[iPlayer][3][StateSlowTime][i] ? PlayerStateF[iPlayer][3][StateSlowTime][i] + 4.0 : 0.0
		PlayerF[iPlayer][PlrSlowSpeed][i] = PlayerStateF[iPlayer][3][StateSlowSpeed][i]
	}

	for (new i; i < PlayerState[iPlayer][3][StateGlowCount]; i++)
	{
		player_add_glow(iPlayer, PlayerStateF[iPlayer][3][StateGlowTime][i] - PlayerStateF[iPlayer][3][StateGametime],
		PlayerState[iPlayer][3][StateGlowR][i], PlayerState[iPlayer][3][StateGlowG][i], PlayerState[iPlayer][3][StateGlowB][i])
	}

	if (PlayerState[iPlayer][3][StateBurned])
		player_burn(iPlayer, PlayerState[iPlayer][3][StateBurnAttacker], PlayerState[iPlayer][3][StateBurned])

	if (PlayerStateF[iPlayer][3][StateBlindTime])
		player_blind(iPlayer, 1, PlayerStateF[iPlayer][3][StateBlindTime] - PlayerStateF[iPlayer][3][StateGametime])

	if (PlayerStateF[iPlayer][3][StateFrozen])
		player_freeze(iPlayer, PlayerStateF[iPlayer][3][StateFrozen] - PlayerStateF[iPlayer][3][StateGametime], iPlayer)

	if (PlayerStateF[iPlayer][3][StateChilled])
		player_chill(iPlayer, PlayerStateF[iPlayer][3][StateChilled] - PlayerStateF[iPlayer][3][StateGametime], iPlayer)

	player_set_windboost(iPlayer, PlayerState[iPlayer][3][StateWindBoostType], false)
	player_update_gravity(iPlayer)

	PlayerF[iPlayer][PlrSwapTime] = PlayerStateF[iPlayer][3][StateSwapTime]

	new ent = -1, iBeamOwner
	while ((ent = rg_find_ent_by_class(ent, SZ_BEAM)))
		if (get_entvar(ent, var_aiment) == iPlayer)
		{
			iBeamOwner = get_entvar(ent, var_owner)
			if (!is_entity_player(iBeamOwner))
				set_entvar(iBeamOwner, var_nextthink, get_gametime())
		}

	ExecuteForward(forward_reburn, _, iPlayer)

	return true
}

public Float:_21kc_player_get_reburn_timestate(plugin, num_params)
{
	return PlayerStateF[get_param(1)][3][StateGametime]
}

public _21kc_player_set_override_attacker(plugin, num_params)
{
	player_set_override_attacker(get_param(1), get_param(2), get_param_f(3))
}

public bool:_21kc_player_try_crit(plugin, num_params)
{
	new iRet
	ExecuteForward(forward_preuse_crit, iRet, get_param(1), get_param(2))
	return !iRet
}

public _21kc_player_set_death_reason(plugin, num_params)
{
	new iPlayer = get_param(1)
	if (!Player[iPlayer][PlrDeathReasonApplied])
		get_string(2, Player[iPlayer][PlrDeathReasonText], LEN_DEATH_REASON - 1)
}

public VisibilityType:_21kc_player_get_visibility(plugin, num_params)
{
	return Player[get_param(1)][PlrVisibility]
}

public _21kc_player_reset_visibility(plugin, num_params)
{
	player_reset_visibility(get_param(1))
}

public bool:_21kc_player_is_influenced(plugin, num_params)
{
	return PlayerF[get_param(1)][PlrPreGameTime] > 0.0
}

public _21kc_player_set_anim(plugin, num_params)
{
	player_set_anim(get_param(1), get_param(2), get_param(3), get_param_f(4), get_param_f(5))
}

public _21kc_player_set_view_anim(plugin, num_params)
{
	player_set_view_anim(get_param(1), get_param(2))
}

public _21kc_player_set_hat(plugin, num_params)
{
	new iPlayer = get_param(1)
	new iModelId = get_param(2)
	new iHatEnt = Player[iPlayer][PlrHatEnt]

	if (iModelId <= 0)
	{
		if (iHatEnt)
		{
			set_entvar(iHatEnt, var_rendermode, kRenderTransAlpha)
			set_entvar(iHatEnt, var_renderamt, 0.0)
			set_entvar(iHatEnt, var_modelindex, 0)
		}

		Player[iPlayer][PlrHatModelIndex] = 0
		return
	}

	new iBody = get_param(3)
	new iSkin = get_param(4)

	Player[iPlayer][PlrHatModelIndex] = iModelId
	Player[iPlayer][PlrHatBody] = iBody
	Player[iPlayer][PlrHatSkin] = iSkin

	if (!iHatEnt)
		return

	set_entvar(iHatEnt, var_modelindex, iModelId)
	set_entvar(iHatEnt, var_skin, iSkin)
	set_entvar(iHatEnt, var_body, iBody)

	set_entvar(iHatEnt, var_sequence, iBody)
	set_entvar(iHatEnt, var_framerate, 1.0)
	set_entvar(iHatEnt, var_animtime, get_gametime())

	switch (Player[iPlayer][PlrVisibility])
	{
		case VIS_GLOW:
		{
			new Float:vGlowColors[3]
			get_entvar(iPlayer, var_rendercolor, vGlowColors)
			set_entvar(iHatEnt, var_rendermode, kRenderNormal)
			set_entvar(iHatEnt, var_rendercolor, vGlowColors)
			set_entvar(iHatEnt, var_renderfx, kRenderFxGlowShell)
			set_entvar(iHatEnt, var_renderamt, 16.0)
		}
		case VIS_TRANS:
		{
			set_entvar(iHatEnt, var_rendermode, kRenderTransAlpha)
			set_entvar(iHatEnt, var_renderamt, float(INVISIBLE_AMT_FRIEND))
			set_entvar(iHatEnt, var_renderfx, kRenderFxDistort)
		}
		case VIS_INVISION:
		{
			set_entvar(iHatEnt, var_rendermode, kRenderTransAlpha)
			set_entvar(iHatEnt, var_renderamt, float(INVISIBLE_AMT_FRIEND))
			set_entvar(iHatEnt, var_renderfx, kRenderFxNone)
		}
		default:
		{
			set_entvar(iHatEnt, var_rendermode, kRenderNormal)
			set_entvar(iHatEnt, var_renderamt, 0.0)
			set_entvar(iHatEnt, var_renderfx, kRenderFxNone)
		}
	}
}

public _21kc_player_get_hat_ent(plugin, num_params)
{
	return Player[get_param(1)][PlrHatEnt]
}

public _21kc_player_get_camera(plugin, num_params)
{
	return Player[get_param(1)][PlrCustomCameraEnt]
}

public _21kc_player_set_camera(plugin, num_params)
{
	new iPlayer = get_param(1)
	new iMode = get_param(2)

	if (iMode > MaxClients)
	{
		player_set_camera(iPlayer, CAMERA_MODE_1ST)
		Player[iPlayer][PlrCustomCameraEnt] = iMode

		if (is_entity(iMode))
			fm_attach_view(iPlayer, iMode)
	}
	else if (iMode == CAMERA_MODE_1ST)
	{
		player_set_camera(iPlayer, Player[iPlayer][PlrCameraMode])
		Player[iPlayer][PlrCustomCameraEnt] = 0
	}
	else
	{
		player_set_camera(iPlayer, iMode)
		Player[iPlayer][PlrCustomCameraEnt] = iPlayer
	}
}

public _21kc_player_check_stuck_delayed(plugin, num_params)
{
	PlayerF[get_param(1)][PlrCheckStuckTime] = get_gametime() + get_param_f(2)
}

public _21kc_player_get_options(plugin, num_params)
{
	return Player[get_param(1)][PlrOptionsFlags]
}

public _21kc_player_get_caused_damage()
{
	new iPlayer = get_param(1)
	new iVictims[MAX_PLAYERS + 1], iDamageSum

	for (new i = 1; i <= MaxClients; i++)
	{
		iVictims[i] += Player[iPlayer][PlrDamageAcceptRnd][i]
		iDamageSum += Player[iPlayer][PlrDamageAcceptRnd][i]
	}

	set_array(2, iVictims, sizeof(iVictims))
	return iDamageSum
}
