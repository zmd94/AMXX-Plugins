/*		
		Copyright © 2014, zmd94.

		This plugin is free software;
		you can redistribute it and/or modify it under the terms of the
		GNU General Public License as published by the Free Software Foundation.

		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.

*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

// Custom forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_LAST_TERRORIST = 0,
	FW_USER_LAST_COUNTER,
	FW_USER_SPAWN_POST,
	FW_USER_FIRST_BLOOD
}

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

#define MAXPLAYERS 32

new const Flags[][] =
{
   "e",
   "ae",
   "be"
}

// Bool
new bool:g_bFirstBlood

// Variables
new g_ForwardResult
new g_Forwards[TOTAL_FORWARDS]

new g_iMaxPlayers
new g_isTerrorist
new g_iLastTerrorist, g_iLastCounter

new g_iPlayers[MAXPLAYERS]
new g_iCount

public plugin_init()
{
	register_plugin("[API] CS Core", "6.1", "zmd94")
	
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_event("TeamInfo", "event_TeamInfo", "a")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerRespawn", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)
	
	g_Forwards[FW_USER_SPAWN_POST] = CreateMultiForward("cs_fw_spawn_post", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_LAST_TERRORIST] = CreateMultiForward("cs_fw_last_terrorist", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_LAST_COUNTER] = CreateMultiForward("cs_fw_last_counter", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_FIRST_BLOOD] = CreateMultiForward("cs_fw_first_blood", ET_IGNORE, FP_CELL, FP_CELL)
	
	for(new i; i < TOTAL_FORWARDS; i++) 
	{ 
		if(g_Forwards[i] < 0)
		{
			log_error(AMX_ERR_NONE, "Error creating forward on cs_core plugin")
		}
	}
	
	g_iMaxPlayers = get_maxplayers()
}

public plugin_natives()
{
	register_library("cs_core")
	register_native("cs_is_terrorist", "native_is_terrorist")
	register_native("cs_is_last_terrorist", "native_is_last_terrorist")
	register_native("cs_is_last_counter", "native_is_last_counter")
	register_native("cs_get_terrorist_count", "native_get_terrorist_count")
	register_native("cs_get_counter_count", "native_get_counter_count")
}

public native_is_terrorist(iPlugin, iParams)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
		return 0
	
	return flag_get_boolean(g_isTerrorist, id);
}

public native_is_last_terrorist(iPlugin, iParams)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
		return 0
	
	return flag_get_boolean(g_iLastTerrorist, id);
}

public native_is_last_counter(iPlugin, iParams)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
		return 0
	
	return flag_get_boolean(g_iLastCounter, id);
}

public native_get_terrorist_count(iPlugin, iParams)
{
	new iType = get_param(1)
	
	if (iType < 0 || iType > 2)
	{
		log_error(AMX_ERR_NATIVE, "cs_get_terrorist_count native is incorrect. iType must not less than 0 or more than 2")
		return 0
	}
	
	get_players(g_iPlayers, g_iCount, Flags[iType], "TERRORIST") 
	
	return g_iCount
}

public native_get_counter_count(iPlugin, iParams)
{
	new iType = get_param(1)
	
	if (iType < 0 || iType > 2)
	{
		log_error(AMX_ERR_NATIVE, "cs_get_counter_count native is incorrect. iType must not less than 0 or more than 2")
		return 0
	}
	
	get_players(g_iPlayers, g_iCount, Flags[iType], "CT") 
	
	return g_iCount
}

public event_new_round()
{
    g_bFirstBlood = false
} 

public client_disconnect(id)
{
	flag_unset(g_isTerrorist, id)
}

public event_TeamInfo()
{
    new id; id = read_data(1)
    new szTeam[2]; read_data(2 , szTeam , charsmax(szTeam))

    static szOldTeam[33][15]
    
    if(!equal(szTeam, szOldTeam[id]))
    {       
        switch(szTeam[0])
        {
            // Terrorist
            case 'T': 
            {
                flag_set(g_isTerrorist, id)
            }
            default: 
            {
                flag_unset(g_isTerrorist, id)
            }
        }
    }
	
    copy(szOldTeam[id], charsmax(szOldTeam), szTeam)
}

public fw_PlayerRespawn(id)
{
	// Players not alive 
	if(!is_user_alive(id))
		return
	
	new CsTeams:Team = cs_get_user_team(id)
	
	// Players didn't join a team yet
	if(Team == CS_TEAM_UNASSIGNED)
		return
	
	// Spawn forward
	ExecuteForward(g_Forwards[FW_USER_SPAWN_POST], g_ForwardResult, id)
	
	switch(Team)
	{
		// If the player is terrorist
		case CS_TEAM_T:
		{
			flag_set(g_isTerrorist, id)
		}
		default:
		{
			flag_unset(g_isTerrorist, id)
		}
	}
}

public fw_PlayerKilled(victim, attacker)  
{
	LastPlayer()
	
	if (g_bFirstBlood || victim == attacker || !is_user_alive(attacker)) 
		return
		
	g_bFirstBlood = true
    
	ExecuteForward(g_Forwards[FW_USER_FIRST_BLOOD], g_ForwardResult, victim, attacker)
}  

// Last terrorist or counter-terrorist
LastPlayer()
{
	new num, id
	
	get_players(g_iPlayers, num, "ae", "TERRORIST")
	if (num == 1) /* only one terrorist is alive */
	{
		g_iLastTerrorist = 0 /* reset bitsum to zero */
		
		id = g_iPlayers[0] /* get id */
		flag_set(g_iLastTerrorist, id)
	}
	else
	{
		g_iLastTerrorist = 0 /* reset bitsum to zero */
	}
	
	// Last terrorist forward
	if (1 <= id <= g_iMaxPlayers)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_TERRORIST], g_ForwardResult, id)
	}
	
	get_players(g_iPlayers, num, "ae", "CT") /* get alive counter's */
	if (num == 1) /* only one counter is alive */
	{
		g_iLastCounter = 0 /* reset bitsum to zero */
		
		id = g_iPlayers[0] /* get id */
		flag_set(g_iLastCounter, id)
	}
	else
	{
		g_iLastCounter = 0 /* reset bitsum to zero (no one) */
	}
	
	// Last counter-terrorist forward
	if (1 <= id <= g_iMaxPlayers)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_COUNTER], g_ForwardResult, id)
	}
}
