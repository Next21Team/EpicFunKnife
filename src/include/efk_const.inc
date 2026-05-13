#if defined _efk_const_included
  #endinput
#endif
#define _efk_const_included

#define EFK_VERSION "1.0"

enum _:PlayerGameFlags(<<=1)
{
	PLGF_IS_ONLINE = 1,
	PLGF_IS_ALIVE,
	PLGF_IN_UNABILITY,
	PLGF_IN_BURNRUSH,
	PLGF_IN_LOCK_POWER_DAMAGE,
	PLGF_IN_FIXED_ANIMATION,
	PLGF_IS_DISABLED_CHARGE,
	PLGF_IS_DISABLED_INVENTORY,
	PLGF_IS_AUTHORIZED
};

enum _:KnifeFlags(<<=1)
{
	KNFF_ZOOM = 1,			// The knife can increase the FOV
	KNFF_BAN_BUNNYHOP,		// Bunny hop is prohibited
	KNFF_ABIL1_TOGGLABLE,	// Activation of the first ability can be disabled
	KNFF_FULL_VISION,		// The knife can see in the dark and hidden objects
	KNFF_HIDDEN				// The knife is hidden in the menu and cannot be selected
};

enum _:ItemFlags(<<=1)
{
	ITMF_INVENTORY = 1,		// Available in the inventory menu
	ITMF_MENU_REDRAW		// Doesn't close the shop menu after buy
};

enum AbilityType
{
	ABIL_NORMAL,			// Normal ability
	ABIL_TARGET_SURFACES,	// On any surface
	ABIL_TARGET_FLOOR,		// On floor
	ABIL_TARGET_PLAYER,		// On players
	ABIL_TARGET_FRIEND,		// On teammates
	ABIL_TARGET_ENEMY		// On enemies
}; // do not change

enum VisibilityType
{
	VIS_NORMAL,				// Normal visibility
	VIS_GLOW,				// Glow
	VIS_TRANS,				// Translucent
	VIS_INVISION,			// Invision (translucent for teammates)
	VIS_CLONE,				// Disguise as an enemy
	VIS_SHADOW
}; // do not change

enum VisionType
{
	VISION_NORMAL,			// Normal vision
	VISION_FULL,			// The player can see in the dark and hidden objects
	VISION_BLIND,			// The player is blinded
	VISION_NIGHT			// The player sees in the dark
};

enum CaptureType
{
	CAPTURE_NONE,
	CAPTURE_NORMAL,			// Damage is blocked and released, Unshadow is not working
	CAPTURE_WEAK,			// Damage is not blocked and is released
	CAPTURE_STRONG			// Damage is blocked and not released
};

enum WindBoostType
{
	WINDBOOST_NONE,
	WINDBOOST_POSITIVE,		// Wind Boost with positive effects
	WINDBOOST_NEGATIVE		// Wind Boost with negative effects
};

enum CaptureAnim
{
	CAP_ANIM_NONE,
	CAP_ANIM_TENTACLES = 114,
	CAP_ANIM_IRON_MAIDEN,
	CAP_ANIM_GHOST_RELEASE
};

enum
{
	CAMERA_MODE_1ST,
	CAMERA_MODE_3RD,
	CAMERA_MODE_BACK
};

enum AttackHeaviness
{
	ATTACK_HEAVINESS_LOW,
	ATTACK_HEAVINESS_NORM,
	ATTACK_HEAVINESS_HIGH
};

enum KnifeHitGroup
{
	KHITGROUP_GENERIC,
	KHITGROUP_BACK,
	KHITGROUP_HEAD
};

enum KnifeCrosshair
{
	CROSSHAIR_DISABLED,		// Disabled
	CROSSHAIR_HIDDEN,		// Hidden
	CROSSHAIR_DEFAULT,		// Default, white
	CROSSHAIR_CANNOT,		// Can't use ability, red
	CROSSHAIR_FAR,			// The target is too far or too close, red
	CROSSHAIR_TIME,			// No charge, red
	CROSSHAIR_OK,			// Ability is ready, green
	CROSSHAIR_HELP			// Teammate help, green
};

enum ItemGiveCode
{
	ITEM_OK,
	ITEM_NEXT_SPAWN,
	ITEM_ALREADY_HAVE,
	ITEM_NOT_AVAILABLE,
	ITEM_DEAD,
	ITEM_ALIVE
}; // do not change

enum AnimExt
{
	ANIM_EXT_KNIFE,
	ANIM_EXT_KNIFE2,
	ANIM_EXT_AXE,
	ANIM_EXT_HAMMER,
	ANIM_EXT_DUAL_KNIVES,
    ANIM_EXT_CLAWS,
    ANIM_EXT_TOMAHAWK,
    ANIM_EXT_NATAKNIFE,
	ANIM_EXT_NUNCHAKU
};

enum
{
	TRAPMODE_FREE,
	TRAPMODE_FIXED,
	TRAPMODE_ACTIVE
};

#define MAX_KNIVES			32
#define MAX_ITEMS			32
#define MAX_MENUITEMS		32
#define MAX_MIXCOLORS		8

enum _:BlockAirFlags(<<=1)
{
	FL_BAIR_NORMAL = 1,		// Block AirMove. Ignored with WINDBOOST_POSITIVE
	FL_BAIR_LEAP,			// Reserved for Leap Knife
	FL_BAIR_TORNADO,		// Reserved for tornado ability
	FL_BAIR_CLIMB			// Block ladder climb
};

#define EFK_GAME_TAG				"Epic Fun Knife" // Тэг игры меню и чата
#define RESET_ABIL_AFTER_SPAWN		5.0 			// сколько секунд заряжать оружие после спавна
#define ADMIN_FLAG					ADMIN_IMMUNITY
#define CLASSNAME_ZOMBIE			"next21_npc"
#define CLASSNAME_ACIDTRAP			"next21_acidtrap"
#define CLASSNAME_CORPSE    		"next21_corpse"
#define CLASSNAME_FAKEPLAYER		"next21_fakeplayer"
#define CLASSNAME_ICICLE			"next21_icicle"
#define CLASSNAME_KUNAI				"next21_kunai"
#define CLASSNAME_ZOMBIE_SPIT		"next21_zombie_spit"
#define CLASSNAME_ACIDB				"next21_toxical_ball"
#define CLASSNAME_ACIDP				"next21_toxical_poison"
#define CLASSNAME_ACIDG				"next21_toxical_gas"
#define CLASSNAME_BUG				"next21_bug"
#define CLASSNAME_WEB				"next21_web"
#define CLASSNAME_GHOST				"next21_ghost"
#define CLASSNAME_TORNADO			"next21_tornado"
#define CLASSNAME_WIND_WAVE			"next21_wind_wave"
#define CLASSNAME_EMBODIMENT		"next21_embodiment"
#define CLASSNAME_ICE_CLONE_PART	"next21_iceclone_pt"
#define CLASSNAME_FIELD_PART		"next21_field_pt"
#define CLASSNAME_PRESENT			"next21_present"

#define IMPULSE_PRESENT				30000001
#define IMPULSE_FIELD				30000002
#define IMPULSE_FIELD_WALL			30000003
#define IMPULSE_ICILCE				30000004
#define IMPULSE_ZOMBIE_SPIT			30000005
#define IMPULSE_ACIDB				30000006
#define IMPULSE_RAZOR_SPHERE		30000007
#define IMPULSE_LASER				30000008
#define IMPULSE_BUG					30000009
#define IMPULSE_FAKEPLAYER			30000010
#define IMPULSE_ZOMBIE				30000011
#define IMPULSE_SPIKES				30000012
#define IMPULSE_ACIDG				30000013
#define IMPULSE_ACIDP				30000014
#define IMPULSE_CORPSE				30000015
#define IMPULSE_ICE_CLONE			30000016
#define IMPULSE_GHOST				30000017
#define IMPULSE_GHOST_BEAM			30000018
#define IMPULSE_WEB					30000019
#define IMPULSE_ACIDTRAP			30000020
#define IMPULSE_LIFEBAR				30000021
#define IMPULSE_HAT					30000022
#define IMPULSE_PLAYERCLONE			30000023
#define IMPULSE_TORNADO				30000024
#define IMPULSE_WIND_WAVE			30000025
#define IMPULSE_WEAPONBOX			30000026
#define IMPULSE_RAZOR_BEAM			30000027
#define IMPULSE_ACIDTRAP_BEAM		30000028
#define IMPULSE_FAKEHAT				30000029
#define IMPULSE_DUELSPRITE			30000030
#define IMPULSE_FOLLOWENT			30000031
#define IMPULSE_FAKEPLAYER_SHELL	30000032
#define IMPULSE_BLACKBOX			30000033
#define IMPULSE_EMBODIMENT			30000034
#define IMPULSE_DRAGON_GUARD		30000035
#define IMPULSE_THUNDER_STRIKE_BEAM	30000036
#define IMPULSE_KUNAI				30000037

#define MAX_PLAYER_MONEY			55000
#define MAX_PLAYER_HEALTH			180.0

#define HUDCHANNEL_STATUS			1
#define HUDCHANNEL_REGENERATION		2
#define HUDCHANNEL_ABILITY			3
#define HUDCHANNEL_ALTABILITY		4

#define CORPSES_LIFE				30.0
#define CONCENTBLOCK_DEFAULT_FOV	90.0

#define FROST_COLOR_R				0
#define FROST_COLOR_G				180
#define FROST_COLOR_B				215

#define FIRE_COLOR_R				255
#define FIRE_COLOR_G				51
#define FIRE_COLOR_B				0

#define ACID_COLOR_R				32
#define ACID_COLOR_G				255
#define ACID_COLOR_B				0

#define FREEZE_TIME					3.5
#define CHILL_TIME					3.0

#define FALL_DAMAGE					0.9
#define FALL_EASING					0.4

#define CORP_NORMAL					0
#define CORP_CUSTOM					1

#define WEB_RADIUS					140.0
#define WEB_HEIGHT					6.0
#define WEB_OFFSET					1.0

#define var_invaxis_x			var_vuser1
#define var_invaxis_y			var_vuser2
#define var_invaxis_z			var_vuser3

#define var_nade_touch			var_iuser4
#define var_crosshair			var_iuser3
#define var_damage_sphere		var_iuser2

#define var_stealowner 			var_iuser3
#define var_stealitem 			var_iuser4

#define var_trapdamage			var_fuser1
#define var_trapholdtime		var_fuser2
#define var_trapcreatetime		var_fuser3
#define var_trapmode			var_iuser3
#define var_traphighlighter		var_iuser4

#define var_fieldside			var_iuser3

#define var_iceclone_shell		var_iuser4

#define var_npctarget			var_iuser1
#define var_npctype				var_iuser2
#define var_npcspit				var_iuser3
#define var_npcowner			var_iuser4
#define var_npcspawntime		var_fuser1

#define var_dueltarget			var_iuser1

#define MODEL_PLAYER_ANIMATIONS 	"models/next21_efk/player_animations5.mdl"

#define SOUND_TORNADO_FLAME 		"next21_efk/tornado_flame.wav"

#define SOUND_GUI_CLICK				"next21_efk/gui_menu1.wav"
#define SOUND_GUI_ERROR				"next21_efk/gui_menu2.wav"

#define CUSTOM_PLAYER_MODEL 		"efk_player_b7"

#define OPTION_HIDE_HATS				(1<<0)
#define OPTION_LOWPOLY_PLAYER			(1<<1)
#define OPTION_DISABLE_PARTICLES		(1<<2)
#define OPTION_VIEW_MODEL_FX			(1<<3)
#define OPTION_FORBID_TEAMMATES_HELP	(1<<4)
#define OPTION_DAMAGER					(1<<5)
#define OPTION_LIMITED_VAMP				(1<<6)
#define OPTION_ONE_DIRECTION_LJ			(1<<7)

enum _:PlayerSeq
{
	PLAYER_SEQ_DUMMY,
	PLAYER_SEQ_IDLE,
	PLAYER_SEQ_IDLE_CROUCH,
	PLAYER_SEQ_WALK,
	PLAYER_SEQ_RUN,
	PLAYER_SEQ_RUN_CROUCH,
	PLAYER_SEQ_JUMP,
	PLAYER_SEQ_JUMP_CROUCH,
	PLAYER_SEQ_SWIM,
	PLAYER_SEQ_TREADWATER,
	PLAYER_SEQ_SPRINT = 94,
	PLAYER_SEQ_SHOOT_SPRINT,
	PLAYER_SEQ_SHOOT_C4_CROUCH,
	PLAYER_SEQ_SHOOT_C4,
	PLAYER_SEQ_DEATH_UNHEAD_CROUCH = 110,
	PLAYER_SEQ_DEATH_UNHEAD
};

enum AmmoType
{
	AMMO_NONE,
	AMMO_338MAGNUM,
	AMMO_762NATO,
	AMMO_556NATOBOX,
	AMMO_556NATO,
	AMMO_BUCKSHOT,
	AMMO_45ACP,
	AMMO_57MM,
	AMMO_50AE,
	AMMO_357SIG,
	AMMO_9MM,
	AMMO_FLASHBANG,
	AMMO_HEGRENADE,
	AMMO_SMOKEGRENADE,
	AMMO_C4,

	AMMO_MAX_TYPES
};
