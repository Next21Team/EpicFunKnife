#if defined _efk_core_included
  #endinput
#endif
#define _efk_core_included

#include <efk_const>

static NULL_PLAYERS[MAX_PLAYERS + 1];

/**
 * Called before activating the first ability
 *
 * @param 	iPlayer			- Player ID
 * @param	iTarget			- Target ID
 * @return					- Specify PLUGIN_HANDLED if you want to block the ability
 */
forward efk_ability_pre(iPlayer, iTarget);

/**
 * Called after activating the first ability
 *
 * @param 	iPlayer			- Player ID
 * @param	iTarget			- Target ID
 * @noreturn
 */
forward efk_ability_post(iPlayer, iTarget);

/**
 * Called before the plugin core changes the knife
 *
 * @param 	iPlayer			- Player ID
 * @param	iKnifeId		- Knife ID
 * @return					- Specify PLUGIN_HANDLED if you want to block the knife change
 */
forward efk_change_knife_core_pre(iPlayer, iKnifeId);

/**
 * Called after the plugin core changes the knife
 *
 * @param 	iPlayer			- Player ID
 * @param	iKnifeId		- Knife ID
 * @noreturn
 */
forward efk_change_knife_core_post(iPlayer, iKnifeId);

/**
 * Called before the second ability is activated, before the Capture state is checked
 *
 * @param 	iPlayer			- Player ID
 * @return					- Specify PLUGIN_HANDLED if you want to block the ability
 */
forward efk_ability2_pre(iPlayer);

/**
 * Called after activating the second ability
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_ability2_post(iPlayer);

/**
 * Called before the third ability is activated, before the Capture state is checked
 *
 * @param 	iPlayer			- Player ID
 * @return					- Specify PLUGIN_HANDLED if you want to block the ability
 */
forward efk_ability3_pre(iPlayer);

/**
 * Called after activating the third ability
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_ability3_post(iPlayer);

/**
 * Called before the fourth ability is activated, before the Capture state is checked
 *
 * @param 	iPlayer			- Player ID
 * @return					- Specify PLUGIN_HANDLED if you want to block the ability
 */
forward efk_ability4_pre(iPlayer);

/**
 * Called after activating the fourth ability
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_ability4_post(iPlayer);

/**
 * Called before setting the HUD crosshair
 *
 * @param 	iPlayer				- Player ID
 * @param 	iTarget				- Target ID
 * @param 	iAbilType			- Ability type
 * @param 	bDistanceAllowed	- Is the distance acceptable for using the ability
 * @return						- KnifeCrosshair for default crosshair, PLUGIN_CONTINUE for skipping, PLUGIN_HANDLED for blocking
 */
forward efk_crosshair_draw_pre(iPlayer, iTarget, &AbilityType:iAbilType, bool:bDistanceAllowed);

/**
 * Called before the core draws the second channel HUD (charge of the second and third abilities)
 *
 * @param 	iPlayer			- Player ID
 * @param	iSubject		- Player ID, whose data is being drawn
 * @param	iKnifeId		- Knife ID
 * @return					- Specify PLUGIN_HANDLED if you want to block HUD draw
 */
forward efk_charge_draw_pre(iPlayer, iSubject, iKnifeId);

/**
 * Called to draw the first HUD channel
 *
 * @param 	iPlayer			- Player ID
 * @param	iSubject		- Player ID, whose data is being drawn
 * @param	iKnifeId		- Knife ID
 * @noreturn
 */
forward efk_status_draw(iPlayer, iSubject, iKnifeId);

/**
 * Called before checking for a crit (during the call to kc_player_try_crit)
 *
 * @param 	iVictim			- Victim ID
 * @param 	iAttacker		- Attacker ID
 * @return					- Specify PLUGIN_HANDLED if you want to block the crit
 */
forward efk_preuse_crit(iVictim, iAttacker);

/**
 * Called before damage is applied to the player. Damage values ​​can be changed via this link
 *
 * @param 	iVictim			- Victim ID
 * @param 	iAttacker		- Attacker ID
 * @param 	fBaseDamage		- Base damage
 * @param 	fPowerDamage	- Power damage modifier
 * @param 	fAddDamage		- Passive knife damage modifier
 * @noreturn
 */
forward efk_apply_damage(iVictim, iAttacker, &Float:fBaseDamage, &Float:fPowerDamage, &Float:fAddDamage);

/**
 * Called after killing the player with a knife
 *
 * @param 	iVictim			- Victim ID
 * @param 	iAttacker		- Attacker ID
 * @param	iKnifeId		- Knife ID
 * @noreturn
 */
forward efk_player_knife_killed(iVictim, iAttacker, iKnifeId);

/**
 * Called when a player scores a kill
 *
 * @param 	iVictim			- Victim ID
 * @param 	iAttacker		- Attacker ID
 * @param 	iAssistant		- Assistant ID (0 if there is no assistant)
 * @noreturn
 */
forward efk_player_death(iVictim, iAttacker, iAssistant);

/**
 * Called when a player healed
 *
 * @param 	iPlayer			- Player ID
 * @param 	iHealer			- Healer ID
 * @param 	fHealth			- Health value
 * @noreturn
 */
forward efk_player_heal(iPlayer, iHealer, Float:fHealth);

/**
 * Called when providing indirect assistance (for example, during healing)
 *
 * @param 	iVictim			- Victim ID
 * @param 	iAttacker		- Attacker ID
 * @param 	iAssistant		- Assistant ID
 * @noreturn
 */
forward efk_indirect_assist(iVictim, iAttacker, iAssistant);

/**
 * Called after a player's team changes
 *
 * @param 	iPlayer			- Player ID
 * @param 	iTeam			- Team
 * @noreturn
 */
forward efk_player_change_team(iPlayer, iTeam);

/**
 * Called after the player's blindness is removed
 *
 * @param 	iPlayer			- Player ID
 * @param	bBreaked		- true if the blinding time has not yet ended
 * @noreturn
 */
forward efk_unblind(iPlayer, bool:bBreaked);

/**
 * Called after the player's invisibility is set
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_invisible(iPlayer);

/**
 * Called after the player's invisibility is removed
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_uninvisible(iPlayer);

/**
 * Called after the player's possession of entity is removed
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_unshadow(iPlayer);

/**
 * Called after the player's disguise is removed from another player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_unclone(iPlayer);

/**
 * Called after the Disenergy effect is applied
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_disenergy(iPlayer);

/**
 * Called after the freeze is completely removed from the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_unchill(iPlayer);

/**
 * Called after burning is removed from the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_unburn(iPlayer);

/**
 * Called after using kc_player_reburn
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_reburn(iPlayer);

/**
 * Called after the colors for the player's glow effect have been recalculated
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_calculate_render_colors(iPlayer);

/**
 * Called after rendering for the player has been reset
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_reset_player_render(iPlayer);

/**
 * Called after capturing the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iType			- Capture type
 * @noreturn
 */
forward efk_capture(iPlayer, CaptureType:iType);

/**
 * Called after the player's capture is removed
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_uncapture(iPlayer);

/**
 * Called after freezing the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_freeze(iPlayer);

/**
 * Called after the player is unfrozen
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_unfreeze(iPlayer);

/**
 * Called after the player is swaped with an enemy
 *
 * @param 	iPlayer			- Player ID
 * @param 	iTarget			- Target ID
 * @noreturn
 */
forward efk_swap(iPlayer, iTarget);

/**
 * Called after a concentrated block is removed from the player after a time has elapsed
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_concentblock_timeout(iPlayer);

/**
 * Called after the Darkness effect ends
 *
 * @noreturn
 */
forward efk_undarkness();

/**
 * Called after changing the Wind Boost type
 *
 * @param 	iPlayer			- Player ID
 * @param 	iWindBoostType	- Wind Boost type
 * @noreturn
 */
forward efk_update_windboost(iPlayer, WindBoostType:iWindBoostType);

/**
 * Called after using a reflection ability
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
forward efk_reflection_start(iPlayer);

/**
 * Called after reflecting an ability
 *
 * @param 	iPlayer			- Player ID
 * @param 	iTarget			- Target ID
 * @noreturn
 */
forward efk_reflection(iPlayer, iTarget);

/**
 * Called after the reflection ability ends
 *
 * @param 	iPlayer			- Player ID
 * @param 	bIsDeath		- Ending due to player death
 * @noreturn
 */
forward efk_reflection_end(iPlayer, bool:bIsDeath);

/**
 * Called after changing the player's options
 *
 * @param 	iPlayer			- Player ID
 * @param 	iOptions		- Options
 * @noreturn
 */
forward efk_player_options_update(iPlayer, iOptions);

/**
 * Called when the player presses the Ability 1 toggle key (T)
 *
 * @param	iPlayer		- Player ID
 * @noreturn
 */
forward efk_ability_toggle(iPlayer);

/**
 * Get the number of registered knives
 *
 * @return					- Number of registered knives
 */
native kc_get_knives_num();

/**
 * Activate Darkness
 *
 * @param 	iTeam			- Activating team
 * @param 	fTime			- Darkness time
 * @return 					- Call result
 */
native bool:kc_darkness(const iTeam, const Float:fTime);

/**
 * Activate Silence
 *
 * @param 	iTeam			- Activating team
 * @param 	fTime			- Silence time
 * @return 					- Call result
 */
native bool:kc_silence(const iTeam, const Float:fTime);

/**
 * Register a event when an item is enabled/disabled
 *
 * @param 	iItemId			- Item ID
 * @param 	szCallback		- Handler. Function prototype: func(iPlayer, bool:bEnabled, bool:bIsRoundEnded)
 * @return					- Call result
 */
native bool:kc_item_register_enable_handler(const iItemId, const szCallback[]);

/**
 * Get knife/first ability name
 *
 * @param	iKnifeId		- Knife ID
 * @param 	szName			- String to write
 * @param	iLen			- String length
 * @return					- Call result
 */
native bool:kc_knife_get_abil1_name(const iKnifeId, const szName[], const iLen);

/**
 * Set an animations set for the knife
 *
 * @param	iKnifeId		- Knife ID
 * @param	iAnimExt		- Anim Ext
 * @noreturn
 */
native kc_knife_set_anim_ext(const iKnifeId, const AnimExt:iAnimExt);

/**
 * Set the reduction factor for the charge time of the first ability for the charge booster
 *
 * @param 	iKnifeId		- Knife ID
 * @param 	fCoeff			- Coefficient value
 * @noreturn
 */
native kc_knife_set_charge_boost_coeff(const iKnifeId, const Float:fCoeff);

/**
 * Get knife class name
 *
 * @param 	iKnifeId		- Knife ID
 * @param 	szClassName		- String to write
 * @param 	iLen			- String length
 * @noreturn
 */
native kc_knife_get_classname(const iKnifeId, const szClassName[], const iLen);

/**
 * Set flags for the knife
 *
 * @param 	iKnifeId		- Knife ID
 * @param 	iFlags			- Knife flags
 * @noreturn
 */
native kc_knife_set_flags(const iKnifeId, const iFlags);

/**
 * Set the required level for access to the knife
 *
 * @param 	iKnifeId		- Knife ID
 * @param 	iLevel			- Level
 * @noreturn
 */
native kc_knife_set_level(const iKnifeId, const iLevel);

/**
 * Set a custom sound for the knife
 *
 * @param	iKnifeId		- Knife ID
 * @param 	szDefPath		- Default sound path
 * @param 	szNewPath		- New sound path
 * @noreturn
 */
native kc_knife_set_sound(const iKnifeId, const szDefPath[], const szNewPath[]);

/**
 * Get the player's first ability charge
 *
 * @param 	iPlayer			- Player ID
 * @return					- Charge value
 */
native Float:kc_player_get_abil1_charge(const iPlayer);

/**
 * Set the player's first ability charge
 *
 * @param 	iPlayer			- Player ID
 * @param 	fAbilCharge		- Charge value. At -1.0 the charge booster item is used if possible
 * @noreturn
 */
native kc_player_set_abil1_charge(const iPlayer, const Float:fAbilCharge);

/**
 * Set the range of the player's first ability
 *
 * @param 	iPlayer			- Player ID
 * @param 	fMinDist		- Minimum distance
 * @param 	fMaxDist		- Maximum distance
 * @noreturn
 */
native kc_player_set_abil1_dist(const iPlayer, const Float:fMinDist=-1.0, const Float:fMaxDist=-1.0);

/**
 * Check whether the player's first ability is charged and enabled
 *
 * @param 	iPlayer			- Player ID
 * @return					- true/false
 */
native bool:kc_player_is_abil1_ready(const iPlayer);

/**
 * Set the first ability type for the player
 *
 * @param	iPlayer			- Player ID
 * @param 	iAbilType		- Ability type
 * @noreturn
 */
native kc_player_set_abil1_type(const iPlayer, const AbilityType:iAbilType);

/**
 * Get the player's second ability charge
 *
 * @param 	iPlayer			- Player ID
 * @return					- Ability charge
 */
native Float:kc_player_get_abil2_charge(const iPlayer);

/**
 * Set the player's second ability charge
 *
 * @param 	iPlayer			- Player ID
 * @param 	fAbilCharge		- Ability charge
 * @noreturn
 */
native kc_player_set_abil2_charge(const iPlayer, const Float:fAbilCharge);

/**
 * Get the player's third ability charge
 *
 * @param 	iPlayer			- Player ID
 * @return					- Ability charge
 */
native Float:kc_player_get_abil3_charge(const iPlayer);

/**
 * Set the player's third ability charge
 *
 * @param 	iPlayer			- Player ID
 * @param 	fAbilCharge		- Ability charge
 * @noreturn
 */
native kc_player_set_abil3_charge(const iPlayer, const Float:fAbilCharge);

/**
 * Get the player's fourth ability charge
 *
 * @param 	iPlayer			- Player ID
 * @return					- Ability charge
 */
native Float:kc_player_get_abil4_charge(const iPlayer);

/**
 * Set the player's fourth ability charge
 *
 * @param 	iPlayer			- Player ID
 * @param 	fAbilCharge		- Ability charge
 * @noreturn
 */
native kc_player_set_abil4_charge(const iPlayer, const Float:fAbilCharge);

/**
 * Check whether the player can use the ability (regardless of the player's active weapon)
 *
 * @param 	iPlayer			- Player ID
 * @param 	iAbil			- Ability number (1, 2, 3, 4)
 * @return					- Call result
 */
native bool:kc_player_can_ability(const iPlayer, const iAbil);

/**
 * Set the animation for the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iSeq			- Sequence
 * @param 	iCrouchSeq		- Sequence for crouch
 * @param 	fFrameRate		- Frame rate
 * @param 	fTime			- Animation time
 * @noreturn
 */
native kc_player_set_anim(const iPlayer, const iSeq, const iCrouchSeq, const Float:fFrameRate, const Float:fTime);

/**
 * Check if the player's movement in the air is blocked
 *
 * @param	iPlayer			- Player ID
 * @return 					- FL_BAIR_* flags or 0
 */
native kc_player_get_bair(const iPlayer);

/**
 * Block the player's movement in the air for 1 second before landing
 *
 * @param	iPlayer			- Player ID
 * @param	iFlags			- FL_BAIR_* flags
 * @noreturn
 */
native kc_player_set_bair(const iPlayer, const iFlags=FL_BAIR_NORMAL);

/**
 * Blind the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iMode			- 0 - smooth screen fade, 1 - instant screen fade
 * @param 	fTime			- Blind time
 * @return					- Call result
 */
native kc_player_blind(const iPlayer, const iMode, const Float:fTime);

/**
 * Remove blindness from the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_unblind(const iPlayer);

/**
 * Check if the player has an active bunny hop
 *
 * @param 	iPlayer			- Player ID
 * @return					- true/false
 */
native bool:kc_player_get_bunnyhop(const iPlayer);

/**
 * Enable/disable bunny hop for the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	bEnable			- Enable/disable
 * @noreturn
 */
native kc_player_set_bunnyhop(const iPlayer, bool:bEnable);

/**
 * Check if the player is on fire
 *
 * @param 	iPlayer			- Player ID
 * @return					- Number of burn iterations
 */
native kc_player_in_burn(const iPlayer);

/**
 * Set the player on fire
 *
 * @param 	iPlayer			- Player ID
 * @param 	iAttacker		- Attacker ID
 * @param 	iCycles			- Number of burn iterations
 * @return 					- Call result
 */
native bool:kc_player_burn(const iPlayer, const iAttacker, const iCycles);

/**
 * Remove burning from the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_unburn(const iPlayer);

/**
 * Get the player's camera
 *
 * @param 	iPlayer			- Player ID
 * @return					- CAMERA_MODE_* or entity ID
 */
native kc_player_get_camera(const iPlayer);

/**
 * Set the camera for the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iMode			- CAMERA_MODE_* or entity ID (not player). CAMERA_MODE_1ST - resets to the player's value. Entity ID - blocks the player from switching the camera and attach to the entity
 * @noreturn
 */
native kc_player_set_camera(const iPlayer, const iMode);


/**
 * Get the player's capture type
 *
 * @param 	iPlayer			- Player ID
 * @return 					- Capture type
 */
native CaptureType:kc_player_get_capture(const iPlayer);

/**
 * Set the capture type for the player.
 * Completely stops the player, blocks attack and abilities. Resets upon receiving damage depending on the capture type
 *
 * @param 	iPlayer				- Player ID
 * @param 	iCaptureType		- Capture type
 * @param 	iCaptureAnim		- Capture player animation
 * @param 	fTime				- Capture time
 * @param	bIgnoreFloorDist	- Do not check the distance to the ground
 * @param	bHideHat			- Hide hat
 * @return 						- Call result
 */
native bool:kc_player_set_capture(const iPlayer, CaptureType:iCaptureType,
	const CaptureAnim:iCaptureAnim=CAP_ANIM_NONE,
	const Float:fTime=0.0,
	const bool:bIgnoreFloorDist=false,
	const bool:bHideHat=false);

/**
 * Get a list of damage dealt by players.
 * Damage resets at the round end and after a team change
 *
 * @param 	iPlayer			- Player ID
 * @param 	iVictims		- Array of players according to damage dealt
 * @return					- Total player damage
 */
native kc_player_get_caused_damage(const iPlayer, iVictims[MAX_PLAYERS + 1]=NULL_PLAYERS);

/**
 * Check if a player with a chill effect
 *
 * @param 	iPlayer			- Player ID
 * @return 					- true/false
 */
native bool:kc_player_in_chill(const iPlayer);

/**
 * Chill the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	fTime			- Chill time
 * @param 	iAttacker		- Attacker ID
 * @return 					- Call result
 */
native bool:kc_player_chill(const iPlayer, const Float:fTime, const iAttacker);

/**
 * Unchill the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_unchill(const iPlayer);

/**
 * Make the player look like an enemy player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iTarget			- Target ID
 * @return 					- Call result
 */
native bool:kc_player_clone(const iPlayer, const iTarget);

/**
 * Remove enemy disguise from the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_unclone(const iPlayer);

/**
 * Apply a concentrated block
 *
 * @param 	iPlayer				- Player ID
 * @param 	iTarget				- Target ID
 * @param 	iAttackHeaviness	- Attack heaviness
 * @param 	fFov				- Field of view
 * @param 	bUseVelocity		- Use the entity velocity instead of origin
 * @return						- Call result
 */
native bool:kc_player_apply_concentblock(const iPlayer, const iTarget,
	const AttackHeaviness:iAttackHeaviness=ATTACK_HEAVINESS_NORM,
	const Float:fFov=CONCENTBLOCK_DEFAULT_FOV, const bool:bUseVelocity=false);

/**
 * Check if the player has a concentrated block activated
 *
 * @param 	iPlayer			- Player ID
 * @return					- true/false
 */
native bool:kc_player_get_concentblock(const iPlayer);

/**
 * Set a concentrated knife hit block
 *
 * @param 	iPlayer			- Player ID
 * @param 	iSeq			- Sequence number for view model that will be played after blocking a hit. 0 - remove block
 * @param 	fTime			- Block time
 * @return					- Call result
 */
native bool:kc_player_set_concentblock(const iPlayer, const iSeq, const Float:fTime=0.0);

/**
 * Set the player's critical hit chance. Only affects the HUD display
 *
 * @param 	iPlayer			- Player ID
 * @param 	fChance			- Crit chance
 * @noreturn
 */
native kc_player_set_crit_chance(const iPlayer, const Float:fChance);

/**
 * Checks whether the player can be critically hit.
 * This function executes efk_preuse_crit forward for crit check
 *
 * @param 	iPlayer			- Player ID
 * @param 	iAttacker		- Attacker ID
 * @return 					- true/false
 */
native bool:kc_player_try_crit(const iPlayer, const iAttacker);

/**
 * Set the crosshair for the player. Effective only in the forward efk_crosshair_draw_pre
 *
 * @param	iPlayer			- Player ID
 * @param	iCrosshair		- Knife crosshair
 * @noreturn
 */
native kc_player_set_crosshair(const iPlayer, const KnifeCrosshair:iCrosshair);

/**
 * Set the death reason message.
 * If the player dies from the next damage received, the message will be displayed
 *
 * @param 	iPlayer			- Player ID
 * @param	szMessage		- Death reason text
 * @noreturn
 */
native kc_player_set_death_reason(const iPlayer, const szMessage[]);

/**
 * Check if the player has any negative effects (blinding, reduced damage, burning, freezing, etc.)
 *
 * @param 	iPlayer			- Player ID
 * @return					- true/false
 */
native bool:kc_player_in_debuffed(const iPlayer);

/**
 * Applies the Disenergy effect to the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_disenergy(const iPlayer);

/**
 * Check if the player is in Darkness without VISION_FULL or VISION_NIGHT
 *
 * @param 	iPlayer			- Player ID
 * @return 					- true/false
 */
native bool:kc_player_in_darkness(const iPlayer);

/**
 * Set the player's best knife.
 * The knife will be given to the player automatically upon connecting.
 * The player must be at least level 1
 *
 * @param 	iPlayer			- Player ID
 * @param 	iKnifeId		- Knife ID
 * @noreturn
 */
native kc_player_set_favknife(const iPlayer, const iKnifeId);

/**
 * Check if a player is frozen
 *
 * @param 	iPlayer			- Player ID
 * @return 					- true/false
 */
native bool:kc_player_in_freeze(const iPlayer);

/**
 * Freeze the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	fTime			- Freeze time
 * @param 	iAttacker		- Attacker ID
 * @return 					- Call result
 */
native bool:kc_player_freeze(const iPlayer, const Float:fTime, const iAttacker);

/**
 * Unfreeze the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_unfreeze(const iPlayer);

/**
 * Check the game flag (PLGF_*) for the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iFlag			- Player game flag
 * @return					- true/false
 */
native bool:kc_player_check_game_flag(const iPlayer, const iFlag);

/**
 * Set the game flag (PLGF_*) for the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iFlag			- Player game flag
 * @noreturn
 */
native kc_player_set_game_flag(const iPlayer, const iFlag);

/**
 * Clear the game flag (PLGF_*) for the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iFlag			- Player game flag
 * @noreturn
 */
native kc_player_unset_game_flag(const iPlayer, const iFlag);

/**
 * Give a knife to the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iKnifeId		- Knife ID
 * @param 	bChangeDelay	- Set a time delay until the next knife change
 * @param 	bCheckLevel		- Check player level to access the knife
 * @return					- Knife ID on success or -1
 */
native kc_player_give_knife(const iPlayer, const iKnifeId, const bool:bChangeDelay=true, const bool:bCheckLevel=true);

/**
 * Set glow to the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	fGlowTime		- Glow time
 * @param 	r				- Red
 * @param 	g				- Green
 * @param 	b				- Blue
 * @return 					- Layer index
 */
native kc_player_add_glow(const iPlayer, const Float:fGlowTime, const r, const g, const b);

/**
 * Remove glow from the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	r				- Red
 * @param 	g				- Green
 * @param 	b				- Blue
 * @noreturn
 */
native kc_player_sub_glow(const iPlayer, const r, const g, const b);

/**
 * Get the player's hat entity
 *
 * @param 	iPlayer			- Player ID
 * @return					- Hat entity ID
 */
native kc_player_get_hat_ent(const iPlayer);

/**
 * Set the player's hat
 *
 * @param 	iPlayer			- Player ID
 * @param 	iModelId		- Hat model
 * @param 	iBody			- Hat body
 * @param 	iSkin			- Hat skin
 * @noreturn
 */
native kc_player_set_hat(const iPlayer, const iModelId, const iBody=0, const iSkin=0);

/**
 * Heal player
 *
 * @param 	iPlayer			- Player ID
 * @param 	fValue			- Additional health value
 * @param 	iHealer			- Healer ID
 * @return					- Call result
 */
native bool:kc_player_heal(const iPlayer, Float:fValue, const iHealer);

/**
 * Check whether the player has influenced the events in the game.
 * Can be used to refund money for useless respawn
 *
 * @param 	iPlayer			- Player ID
 * @return					- true/false
 */
native bool:kc_player_is_influenced(const iPlayer);

/**
 * Give an item to the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iItemId			- Item ID
 * @param 	iSenderImpulse	- Sender player ID or sender IMPULSE_*
 * @return					- Call result
 */
native ItemGiveCode:kc_player_give_item(const iPlayer, const iItemId, const iSenderImpulse);

/**
 * Gives a random available item to the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iSenderImpulse	- Sender player ID or sender IMPULSE_*
 * @return					- Item ID if giving is successful, otherwise -1
 */
native kc_player_give_random_item(const iPlayer, const iSenderImpulse);

/**
 * Check if an item is enable in the player's inventory
 *
 * @param 	iPlayer			- Player ID
 * @param 	iItemId			- Item ID
 * @return					- true/false
 */
native bool:kc_player_item_get_enabled(const iPlayer, const iItemId);

/**
 * Toggle an item in the player's inventory
 *
 * @param 	iPlayer			- Player ID
 * @param 	iItemId			- Item ID
 * @param 	bEnabled		- Enable/disable
 * @noreturn
 */
native kc_player_item_set_enabled(const iPlayer, const iItemId, const bool:bEnabled);

/**
 * Get the item value in the player's inventory (item ammo)
 *
 * @param 	iPlayer			- Player ID
 * @param 	iItemId			- Item ID
 * @return					- Item value (-1 - the player has no item)
 */
native kc_player_get_item_value(const iPlayer, const iItemId);

/**
 * Set the item value in the player's inventory (item ammo)
 *
 * @param 	iPlayer			- Player ID
 * @param 	iItemId			- Item ID
 * @param 	iValue			- Item value (-1 - remove item)
 * @noreturn
 */
native kc_player_set_item_value(const iPlayer, const iItemId, const iValue);

/**
 * Make the player invisible
 *
 * @param 	iPlayer			- Player ID
 * @param 	fTime			- Invisibility time
 * @param 	iFakeEnt		- Illusion entity
 * @param 	iMode			- Invisibility mode (0 - full, 1 - distort)
 * @noreturn
 */
native kc_player_invision(const iPlayer, const Float:fTime, const iFakeEnt, const iMode);

/**
 * Remove invisibility from the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_uninvision(const iPlayer);

/**
 * Signal that the illusion has been removed
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_invision_unfake(const iPlayer);

/**
 * Check if a knife is available to the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iKnifeId		- Knife ID
 * @return					- true/false
 */
native bool:kc_player_check_knife_access(const iPlayer, const iKnifeId);

/**
 * Get the player's active knife
 *
 * @param 	iPlayer			- Player ID
 * @return					- Knife ID
 */
native kc_player_get_knife(const iPlayer);

/**
 * Get the player's level
 *
 * @param 	iPlayer			- Player ID
 * @return 					- Level
 */
native kc_player_get_level(const iPlayer);

/**
 * Set the player's level
 *
 * @param 	iPlayer			- Player ID
 * @param 	iLevel			- Level
 * @noreturn
 */
native kc_player_set_level(const iPlayer, const iLevel);

/**
 * Enable levitation for the player
 *
 * @param 	iPlayer			- Player ID
 * @return					- Call result
 */
native bool:kc_player_levitation(const iPlayer);

/**
 * Disable levitation for the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_unlevitation(const iPlayer);

/**
 * Get the player's maximum health
 *
 * @param 	iPlayer			- Player ID
 * @return					- Max health
 */
native Float:kc_player_get_maxhealth(const iPlayer);

/**
 * Get the player's maximum walk speed
 *
 * @param 	iPlayer			- Player ID
 * @return					- Maximum speed
 */
native Float:kc_player_get_maxspeed(const iPlayer);

/**
 * Set the player's maximum walk speed
 *
 * @param 	iPlayer			- Player ID
 * @param 	fSpeed			- Maximum speed
 * @noreturn
 */
native kc_player_set_maxspeed(const iPlayer, const Float:fSpeed);

/**
 * Get player's options
 *
 * @param 	iPlayer			- Player ID
 * @return					- Player options
 */
native kc_player_get_options(const iPlayer);

/**
 * If a player dies from the world within the specified time, the kill is credited to the specified attacker
 *
 * @param 	iPlayer			- Player ID
 * @param	iAttacker		- Attacker ID
 * @param	fTime			- Override time
 * @noreturn
 */
native kc_player_set_override_attacker(const iPlayer, const iAttacker, const Float:fTime);

/**
 * Get the player's damage modifier
 *
 * @param	iPlayer			- Player ID
 * @return					- Addition damage
 */
native Float:kc_player_get_powerdamage(const iPlayer);

/**
 * Set the player's damage modifier
 *
 * @param	iPlayer			- Player ID
 * @param 	fPowerDamage	- Addition damage
 * @noreturn
 */
native kc_player_set_powerdamage(const iPlayer, const Float:fPowerDamage);

/**
 * Check if the player is in protection on spawning
 *
 * @param 	iPlayer			- Player ID
 * @return					- true/false
 */
native bool:kc_player_in_protection(const iPlayer);

/**
 * Remove player protection on spawning
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_unprotection(const iPlayer);

/**
 * Check the player for an activated reflection effect
 *
 * @param 	iPlayer			- Player ID
 * @return					- true/false
 */
native bool:kc_player_in_reflection(const iPlayer);

/**
 * Apply the effect of reflecting targeted abilities on the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	fTime			- Reflection time
 * @return					- Call result
 */
native bool:kc_player_reflection_start(const iPlayer, const Float:fTime);

/**
 * Remove the effect of reflecting targeted abilities on the player
 *
 * @param 	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_reflection_stop(const iPlayer);

/**
 * Should be called when ability reflection occurs
 *
 * @param 	iPlayer			- Player ID
 * @param 	iTarget			- Target ID
 * @noreturn
 */
native kc_player_reflection_done(const iPlayer, const iTarget);

/**
 * Increases player movement speed and negates all slowing effects
 *
 * @param 	iPlayer			- Player ID
 * @param 	fRush			- Rush speed
 * @param 	fRushTime		- Rush time
 * @noreturn
 */
native kc_player_rush(const iPlayer, const Float:fRush, const Float:fRushTime);

/**
 * Return the player to the state 4 seconds ago
 *
 * @param 	iPlayer			- Player ID
 * @return 					- Call result
 */
native bool:kc_player_reburn(const iPlayer);

/**
 * Get the player's state game time after calling kc_player_reburn
 *
 * @param	iPlayer			- Player ID
 * @return					- Game time
 */
native Float:kc_player_get_reburn_timestate(const iPlayer);

/**
 * Check if the player is stuck after a period of time
 *
 * @param 	iPlayer			- Player ID
 * @param 	fCheckDelay		- Time delay
 */
native kc_player_check_stuck_delayed(const iPlayer, const Float:fCheckDelay);

/**
 * Swaps players with each other. If the target is a temmate, it only removes negative effects
 *
 * @param 	iPlayer			- Player ID
 * @param 	iTarget			- Target ID
 * @param 	fSwapTime		- Confusing buttons time
 * @return					- Call result. If the teammate had no negative effects, it will return false
 */
native bool:kc_player_swap(const iPlayer, const iTarget, const Float:fSwapTime);

/**
 * Get the end time of the swap effect
 *
 * @param 	iPlayer			- Player ID
 * @return					- Confusing buttons time
 */
native Float:kc_player_get_swap(const iPlayer);

/**
 * Possesses the player into another entity
 *
 * @param 	iPlayer			- Player ID
 * @param 	iTarget			- Target ID
 * @return					- Call result
 */
native bool:kc_player_shadow(const iPlayer, const iTarget);

/**
 * Remove the possession of entity from the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	bCanClone		- Allow Clone Visibility to be set
 * @return					- Call result
 */
native kc_player_unshadow(const iPlayer, const bool:bCanClone=false);

/**
 * Get the entity the player is possessed into
 *
 * @param 	iPlayer			- Player ID
 * @return					- Entity ID or 0
 */
native kc_player_get_shadow_target(const iPlayer);

/**
 * Get the player who has been possessed into another player
 *
 * @param 	iPlayer			- Player ID
 * @return					- Player ID or 0
 */
native kc_player_get_shadow_activator(const iPlayer);

/**
 * Check if the player is in Silence
 *
 * @param 	iPlayer			- Player ID
 * @return					- true/false
 */
native bool:kc_player_in_silence(const iPlayer);

/**
 * Slow the player down and reset kc_player_rush
 *
 * @param 	iPlayer			- Player ID
 * @param 	fSlow			- Slow power (speed * fSlow)
 * @param 	fSlowTime		- Slow time
 * @noreturn
 */
native kc_player_slow(const iPlayer, const Float:fSlow, const Float:fSlowTime);

/**
 * Play first-person animation for the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	iSeq			- Sequence
 * @noreturn
 */
native kc_player_set_view_anim(const iPlayer, const iSeq);

/**
 * Get the player's visibility
 *
 * @param	iPlayer			- Player ID
 * @return 					- Visibility
 */
native VisibilityType:kc_player_get_visibility(const iPlayer);

/**
 * Get the player's vision type
 *
 * @param	iPlayer			- Player ID
 * @return					- Vision type
 */
native VisionType:kc_player_get_vision(const iPlayer);

/**
 * Remove all player visibility effects
 *
 * @param	iPlayer			- Player ID
 * @noreturn
 */
native kc_player_reset_visibility(const iPlayer);

/**
 * Make the player translucent in water
 *
 * @param 	iPlayer			- Player ID
 * @param 	bEnable			- Enable/disable
 * @noreturn
 */
native kc_player_set_water_transparent(const iPlayer, const bool:bEnable);

/**
 * Set a custom weapon HUD for the player
 *
 * @param 	iPlayer			- Player ID
 * @param 	szOldWeapon		- Default weapon class name
 * @param 	szNewWeapon		- New weapon class name
 * @return					- Call result
 */
native bool:kc_player_set_weapon_hud(const iPlayer, const szOldWeapon[], const szNewWeapon[]);

/**
 * Get the player's Wind Boost type
 *
 * @param	iPlayer			- Player ID
 * @return 					- Wind Boost type
 */
native WindBoostType:kc_player_get_windboost(const iPlayer);

/**
 * Set the Wind Boost type for the player
 *
 * @param	iPlayer			- Player ID
 * @param 	iWindBoostType	- Wind Boost type
 * @noreturn
 */
native kc_player_set_windboost(const iPlayer, const WindBoostType:iWindBoostType);

/**
 * Register a new knife
 *
 * @param	szClassName			- Knife class name (like weapon_next21_*)
 * @param 	szMenuDesc			- Knife description in the menu
 * @param	szChatDesc			- Knife description in the chat after selection
 * @param	pModelVStr			- Allocated string for view model. Use EngFunc_AllocString
 * @param	pModelPStr			- Allocated string for player attached model. Use EngFunc_AllocString
 * @param	pModelPMdl			- Player attached model. Use precache_model
 * @param	fHealth				- Max health
 * @param	fGravity			- Gravity factor
 * @param	fSpeed				- Max walk speed
 * @param	fMinDamage			- Minimal additional damage from knife attack
 * @param	fMaxDamage			- Maximum additional damage from knife attack
 * @return						- Knife ID if registration is successful, otherwise -1
 */
native kc_register_knife(const szClassName[]="NULL", const szMenuDesc[],
	const szChatDesc[], const pModelVStr, const pModelPStr,
	const pModelPMdl, const Float:fHealth, const Float:fGravity,
	const Float:fSpeed, const Float:fMinDamage=0.0, const Float:fMaxDamage=0.0);

/**
 * Register the first ability for the knife
 *
 * @param	iKnifeId		- Knife ID
 * @param 	szName			- Ability/Knife name
 * @param	fCharge			- Ability charge percentage per second
 * @param	iAbilType		- Ability type
 * @param	fMinDist		- Minimum ability distance
 * @param	fMaxDist		- Maximum ability distance
 * @return					- Call result
 */
native bool:kc_register_ability1(const iKnifeId, const szName[], const Float:fCharge, const AbilityType:iAbilType=ABIL_NORMAL, const Float:fMinDist=-1.0, const Float:fMaxDist=-1.0);

/**
 * Register the second ability for the knife
 *
 * @param	iKnifeId		- Knife ID
 * @param 	szName			- Ability name
 * @param	fCharge			- Ability charge percentage per second
 * @return					- Call result
 */
native bool:kc_register_ability2(const iKnifeId, const szName[], const Float:fCharge);

/**
 * Register the third ability for the knife
 *
 * @param	iKnifeId		- Knife ID
 * @param 	szName			- Ability name
 * @param	fCharge			- Ability charge percentage per second
 * @return					- Call result
 */
native bool:kc_register_ability3(const iKnifeId, const szName[], const Float:fCharge);

/**
 * Register the fourth ability for the knife
 *
 * @param	iKnifeId		- Knife ID
 * @param 	szName			- Ability name
 * @param	fCharge			- Ability charge percentage per second
 * @return					- Call result
 */
native bool:kc_register_ability4(const iKnifeId, const szName[], const Float:fCharge);

/**
 * Register an item for the shop
 *
 * @param 	szMenuText		- Item name in the shop menu
 * @param 	szChatText		- Message that will be displayed upon successful purchase of an item
 * @param 	szGiveCallback	- Handler for giving an item. Function prototype: func(iPlayer, iSender)
 * @param 	iCost			- Item cost (-1 without shop access)
 * @param 	iLevel			- Required player level
 * @param 	iFlags			- Item flags
 * @return					- Item ID if registration is successful, otherwise -1
 */
native kc_register_item(const szMenuText[], const szChatText[], const szGiveCallback[], const iCost, const iLevel=0, const iFlags=0);

/**
 * Register an item in the main menu
 *
 * @param 	szName			- Menu item name
 * @param 	szCallback		- Menu item handler
 * @return					- Menu item ID if registration is successful, otherwise -1
 */
native kc_register_menu_item(const szName[], const szCallback[]);

/**
 * Register a custom weapon HUD
 *
 * @param 	szOldWeapon		- Default weapon class name
 * @param 	szNewWeapon		- New weapon class name
 * @return					- Call result
 */
native bool:kc_register_weapon_hud(const szOldWeapon[], const szNewWeapon[]);
