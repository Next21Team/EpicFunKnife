#if defined _efk_duels_included
  #endinput
#endif
#define _efk_duels_included

/**
 * Called after the duel ends
 *
 * @param 	iWinner				- Winner ID
 * @param 	iLooser				- Looser ID
 * @noreturn
 */
forward efk_duel_win(iWinner, iLooser);
