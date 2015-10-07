#if defined _cs_war_included
  #endinput
#endif
#define _cs_war_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib cs_war
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib cs_war
	#endif
#else
	#pragma library cs_war
#endif

/*
 * Return whether current round is war round
*/
native cs_is_war_round();

/*
 * Return current war name
 * param const szWarName[] - the name of current weapon war round
 * param iLen - maximum size of buffer
*/
native cs_current_war(const szWarName[], iLen);

/*
 * Return last war name
 * param const szWarName[] - the name of current weapon war round
 * param iLen - maximum size of buffer
*/
native cs_last_war(const szWarName[], iLen);

/*
 * Return war ID
 * param const szWarName[] - the name of weapon war round
 * param const szWarID[] - the name of weapon ID
*/
native cs_war_set(const szWarName[], const szWarID[]);

/**
 * Return auto-start war round
 */
native cs_start_war();

/**
 * Return auto-start war vote
 * param Float:fVoteTime - the durations for voting
 */
native cs_start_vote(Float:fVoteTime);

/**
 * Return point leader
 * param id - ID of client
 */
native cs_is_point_leader(id);

/******************************
*          Forwards
*******************************/

/**
 * This is called during a war round is started
 */
forward cs_fw_war_start();

/**
 * This is called during a war round is end
 */
forward cs_fw_war_end();

/**
 * This is called during a war vote is started
 */
forward cs_fw_vote_start();

/**
 * This is called during a war vote is end
 */
forward cs_fw_vote_end();
