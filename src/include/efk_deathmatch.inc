#if defined _efk_deathmatch_included
  #endinput
#endif
#define _efk_deathmatch_included

/**
 * Called after a death zone is created
 *
 * @param 	iWinTeam		- Winning team (0: tie, -1: zone removed)
 * @noreturn
 */
forward efk_death_zone_started(iWinTeam);
