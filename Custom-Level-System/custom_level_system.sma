/*
	-----------------------------------------------
	Copyright(C). 2015. zmd94 ;)
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	-----------------------------------------------
*/
//Uncomment 'IM_USING_ZP50' if your server is running ZP50 and above
#define IM_USING_ZP50

// if you are using this Custom Level for ZPA, 
// just change line below into #include <zombie_plague_advance> 
#include <zombieplague> 

//Uncomment 'CUSTOM_CHAT' if your want to use custom chat
#define CUSTOM_CHAT

//Uncomment 'DATA_EXPIRED' if your want to enable data expired function
//#define DATA_EXPIRED

//Uncomment 'CHANGE_NAME' if your want to enable player to change their name
#define CHANGE_NAME

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <nvault_util>
#include <nvault>
#include <engine>
#include <fun>

#if defined IM_USING_ZP50
#include <zp50_core>
#include <zp50_class_zombie>
#endif

new const VERSION[] = "3.1"
new const VAULTNAME[] = "custom_level"
new const RANKS[][]=
{
	"0", // 0
	"1", // 1
	"2", // 2
	"3", // 3
	"4", // 4
	"5", // 5
	"6", // 6
	"7", // 7
	"8", // 8
	"9", // 9
	"10", // 10
	"11", // 11
	"12", // 12
	"13", // 13
	"14", // 14
	"15", // 15
	"16", // 16
	"17", // 17
	"18" // 18
}

new const EXP[] =
{
	0, // 0
	25, // 1
	85, // 2
	145, // 3
	245, // 4
	417, // 5
	709, // 6
	1206, // 7
	2051, // 8
	3487, // 9
	5929, // 10
	10079, // 11
	17135, // 12
	29131, // 13
	49522, // 14
	84188, // 15
	143121, // 16
	243305, // 17
	413620 // 18
}

#define ADMIN_FLAG	ADMIN_IMMUNITY
#define MAXPLAYERS 32
#define TOPLEVEL 15
#define TASK_INFO 2399

// Bool
new bool:g_bKilledZombie[MAXPLAYERS+1][33]

// Float
new Float:g_fIconTime

// String
new g_szMotd[1536]
new g_sName[MAXPLAYERS+1][32]

// Variables
new g_iLevel[MAXPLAYERS+1], g_iXP[MAXPLAYERS+1] 
new g_iDamage[MAXPLAYERS+1][33], g_iSprite[MAXPLAYERS+1]
new g_iSteamID[MAXPLAYERS+1][32]

new g_iZombieScore, g_iHumanScore
new g_iVault, g_msgSayText

new g_iELevelBonus, g_iEAPRewards, g_iEHitRecieved, g_iEHitDealt, g_iEShowScore, g_iEHumanWin
, g_iEHPBonus, g_iEArmorBonus

new g_iSaveType, g_iConnectMessage, g_iELevelIcon, g_iLevelIconTime, g_iEInformHud, g_iHudLocation
, g_iHudColors, g_iScoreColors, g_iHumanEXP, g_iHeadShotEXP, g_iLevelEXPBonus, g_iLevelHPBonus
, g_iLevelArBonus, g_iLevelAPBonus

new g_CHumanEXP, g_CHeadEXP, g_CLevelEXP, g_CIcon, g_CSaveType

#if defined IM_USING_ZP50
new g_iMaxHealth[MAXPLAYERS+1]
new g_iEAssistEXP, g_iAssistEXP, g_iAssistDivide
new g_CAssistEXP, g_CAssistDivide
#endif

#if defined DATA_EXPIRED
new g_iDataExpired
#endif

public plugin_precache()
{
	new szFile[35]
	for(new i = 0; i < sizeof(RANKS); i++)
	{
		formatex(szFile, charsmax(szFile), "sprites/zombie_plague/level/%i.spr", i)
		g_iSprite[i] = precache_model(szFile)
	}
}

public plugin_init()
{
	// Original plugin is by Excalibur007. ;)
	register_plugin("Custom Level", VERSION, "zmd94")
	
	register_dictionary("custom_level.txt")
	
	#if defined CUSTOM_CHAT
	register_clcmd("say", "custom_say")
	register_clcmd("say_team", "custom_say_team")
	#endif
	
	register_clcmd("say /cles", "custom_menu")
	register_clcmd("say_team /cles", "custom_menu")
	register_clcmd("say /clnext", "show_stats")
	register_clcmd("say_team /clnext", "show_stats")
	register_clcmd("say /cltop", "show_global_top")
	register_clcmd("say_team /cltop", "show_global_top")
	register_clcmd("say /ontop", "show_online_top")
	register_clcmd("say_team /ontop", "show_online_top")
	register_clcmd("say /savecl", "save_data")
	register_clcmd("say_team /savecl", "save_data")
	
	register_clcmd("free_give","cl_give", ADMIN_FLAG, "Enable to give free EXP")

	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_event("Damage", "event_Damage", "be", "2!0", "3=0", "4!0")
	register_event("DeathMsg", "event_DeathMsg", "a", "1>0")
	register_event("StatusValue", "event_StatusValue", "be", "1=2", "2!0")
	register_event("TextMsg", "event_Restart", "a", "2&#Game_C", "2&#Game_w")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerRespawn", 1)
	
	#if defined CHANGE_NAME
	register_forward( FM_ClientUserInfoChanged, "FwdClientUserInfoChanged" )
	#endif
	
	g_iSaveType = register_cvar("cl_save_type", "2") // 1; Save the EXP via player steamID | 2; Save the EXP via player name 
	#if defined DATA_EXPIRED
	g_iDataExpired = register_cvar("cl_data_expired", "5") // This will remove all entries in the vault that are X days old 
	#endif
	g_iConnectMessage = register_cvar("cl_connect_message", "1") // Enable connect message
	g_iHumanEXP = register_cvar("cl_human_EXP", "1") // Amount of EXP gain from killing a zombie without headshot
	// g_iZombieEXP = register_cvar("cl_zombie_EXP", "1") // Amount of EXP gain from killing a human
	g_iHeadShotEXP = register_cvar("cl_level_head_EXP", "2") //  Amount of EXP gain from killing a zombie with headshot
	g_iELevelIcon = register_cvar("cl_level_icon", "1") // Enable level icon
	g_iLevelIconTime = register_cvar("cl_level_icon_time", "1.5") // The time for the icon to stay displaying
	g_iELevelBonus = register_cvar("cl_level_bonus", "1") // Enable level bonus
	g_iLevelEXPBonus = register_cvar("cl_EXP_bonus", "3") // Amount of EXP gain when level up 
	g_iEHPBonus = register_cvar("cl_enable_health_bonus", "1") // Enable HP bonus
	g_iLevelHPBonus = register_cvar("cl_health_bonus", "25")  // The values of health reward 
	g_iEArmorBonus = register_cvar("cl_enable_armor_bonus", "1") // Enable armor bonus
	g_iLevelArBonus = register_cvar("cl_armor_bonus", "10") // The values of armor reward 
	g_iEAPRewards = register_cvar("cl_enable_AP_bonus", "1") // Enable ammo packs reward when level up
	g_iLevelAPBonus = register_cvar("cl_AP_amount", "10") // The values of ammo packs reward 
	g_iEInformHud = register_cvar("cl_level_hud", "1") // Enable level hud information
	g_iHudColors = register_cvar("cl_hud_colors", "255 0 0")
	g_iHudLocation = register_cvar("cl_hud_position", "2") // 1; The position of hud information is in the left | 2; The position of hud information is in the right
	// g_iEDamageEXP = register_cvar("cl_level_damage", "1") // Enable human to recieve EXP from dealing a damage 
	// g_iDamageAmount = register_cvar("cl_damage_amount", "950") // Amount of damage need to recieve EXP for human
	// g_iDamageEXP = register_cvar("cl_damage_EXP_amount", "1") // Amount of EXP gain from dealing a damage
	g_iEHitRecieved = register_cvar("cl_show_hit_recieved", "1") // Enable showing recieved damage 
	g_iEHitDealt = register_cvar("cl_show_hit_dealt", "1") // Enable showing dealt damage
	g_iEShowScore = register_cvar("cl_show_score", "1") // Enable showing score for zombie and human
	g_iScoreColors = register_cvar("cl_score_colors", "0 255 0")
	g_iEHumanWin = register_cvar("cl_human_win", "1") // Enable human to be a winner if nobody win
	// g_iEHumanWinBonus = register_cvar("cl_human_win_bonus", "1") // Enable win bonus for human
	// g_iHumanWinEXP = register_cvar("cl_human_win_amount", "1") // EXP given to human for winning
	// g_iEZombieWinBonus = register_cvar("cl_zombie_win_bonus", "1") // Enable win bonus for zombie
	// g_iZombieWinEXP = register_cvar("cl_zombie_win_amount", "1") // EXP given to zombie for winning
	// g_iEZombieInfectBonus = register_cvar("cl_zombie_infect_bonus", "1") // Enable EXP bonus for zombie when infecting human
	// g_iInfectEXP = register_cvar("cl_zombie_infect_amount", "1") // EXP given to zombie for infecting human
	// g_iESurvKillBonus = register_cvar("cl_survivor_kill_bonus", "1") // Enable kill bonus when killing survivor
	// g_iSurKillEXP = register_cvar("cl_survivor_bonus_amount", "1") // Then amount of EXP bonus by killing survivor
	// g_iENemKillBonus = register_cvar("cl_nemesis_kill_bonus", "1") // Enable kill bonus when killing nemesis
	// g_iNemKillEXP = register_cvar("cl_nemesis_bonus_amount", "1") // Then amount of EXP bonus by killing nemesis
	#if defined IM_USING_ZP50
	g_iEAssistEXP = register_cvar("cl_enable_assist", "1") // Enable EXP given for assisting players
	g_iAssistEXP = register_cvar("cl_level_assist_EXP", "1") // Amount of EXP gain from assisting a non-zombie killer.
	g_iAssistDivide = register_cvar("cl_level_assist_divide", "5") // Amount of damage [Zombie Max health / CVAR] needed to get an assist
	#endif
	
	g_msgSayText = get_user_msgid("SayText")
	
	#if defined CUSTOM_CHAT
	register_message(g_msgSayText, "message_SayText")
	#endif
	
	// Score Inform. ;)
	if(get_pcvar_num(g_iEShowScore))
	{
		set_task(1.0, "ShowScore", 0, _, _, "b")
	}
}

public plugin_cfg()
{
	new sCFGdir[32]
	get_configsdir(sCFGdir, charsmax(sCFGdir))
	server_cmd("exec %s/cl_system.cfg", sCFGdir)
	
	g_CSaveType = get_pcvar_num(g_iSaveType)
	g_CHumanEXP = get_pcvar_num(g_iHumanEXP)
	g_CHeadEXP = get_pcvar_num(g_iHeadShotEXP)
	g_CLevelEXP = get_pcvar_num(g_iLevelEXPBonus)
	g_CIcon = get_pcvar_num(g_iELevelIcon)
	g_fIconTime = get_pcvar_float(g_iLevelIconTime)
	#if defined IM_USING_ZP50
	g_CAssistEXP = get_pcvar_num(g_iAssistEXP)
	g_CAssistDivide = get_pcvar_num(g_iAssistDivide)
	#endif
	
	g_iVault = nvault_open(VAULTNAME)
	if(g_iVault == INVALID_HANDLE)
	{
		new szText[128]; formatex(szText, 127, "Error opening CLeS database [%s]", VAULTNAME);
		set_fail_state(szText)
	}
	else
	{
		server_print("CLeS database [%s] successfully loaded!", VAULTNAME)
	
		#if defined DATA_EXPIRED
		nvault_prune(g_iVault, 0, get_systime() - (86400 * get_pcvar_num(g_iDataExpired)))
		#endif
	
		FormatTop(TOPLEVEL)
	}
}

public plugin_end()
{
	nvault_close(g_iVault)
}

public zp_round_ended(iTeam)
{
	switch(iTeam)
	{
		case WIN_ZOMBIES: 
		{
			if(get_pcvar_num(g_iEShowScore))
			{
				g_iZombieScore ++ 
			}
		}
		case WIN_HUMANS: 
		{
			if(get_pcvar_num(g_iEShowScore))
			{
				g_iHumanScore ++ 
			}
		}
		case WIN_NO_ONE: 
		{
			if(get_pcvar_num(g_iEHumanWin))
			{
				g_iHumanScore ++
			}
		}
	}
}

public client_authorized(id)
{
	// Just get the connecting users authid and store it in our global string array so it
    // will not need to be retrieved every time we want to do an nvault transaction
	switch(g_CSaveType)
	{
		case 1:
		{
			get_user_authid(id, g_iSteamID[id], charsmax(g_iSteamID))
		}
		case 2:
		{
			get_user_name(id, g_sName[id], charsmax(g_sName))
		}
	}
}

public client_putinserver(id)
{
	if(is_user_connected(id))
	{
		LoadData(id)
		
		if(get_pcvar_num(g_iConnectMessage))
		{
			new szName[32]
			get_user_name(id, szName, charsmax(szName))
			sChatColor(0, "^x04[CL]^x01 %L", LANG_PLAYER, "CL_CONNECT_MESSAGE", szName, RANKS[g_iLevel[id]], g_iXP[id])
		}
		
		if(get_pcvar_num(g_iEInformHud))
		{
			set_task(1.0, "InfoHud", id+TASK_INFO, _, _, "b")
		}
	}
}

public client_disconnect(id)
{
	SaveData(id)
	
	remove_task(id+TASK_INFO)
	
	g_iLevel[id] = 0
	g_iXP[id] = 0
}

public InfoHud(id)
{
	id -= TASK_INFO
	
	new PlayerInfoHud = CreateHudSyncObj()
	new iHudLocation = get_pcvar_num(g_iHudLocation)
	
	new szColors[16]
	new szRed[4], szGreen[4], szBlue[4]
	new iRed, iGreen, iBlue
	
	get_pcvar_string(g_iHudColors, szColors, charsmax(szColors))
	parse(szColors, szRed, charsmax(szRed), szGreen, charsmax(szGreen), szBlue, charsmax(szBlue))
	iRed = str_to_num(szRed); iGreen = str_to_num(szGreen); iBlue = str_to_num(szBlue); 
	
	if(!is_user_alive(id))
	{
		static iSpec; iSpec = entity_get_int(id, EV_INT_iuser2)
		
		if(!is_user_alive(iSpec)) 
			return
		
		new iSpecName[32]
		get_user_name(iSpec, iSpecName, charsmax(iSpecName))
		
		switch(iHudLocation)
		{
			case 1:
			{
				if(g_iLevel[iSpec] == 18)
				{
					set_hudmessage(iRed, iGreen, iBlue, 0.01, 0.28, 0, 6.0, 12.0, 0.0, 0.0, -1) 
					ShowSyncHudMsg(id, PlayerInfoHud,"[Spectating: %s] ^n[Level: Complete] ^n[EXP: Complete]", iSpecName) 
				}
				else
				{
					set_hudmessage(iRed, iGreen, iBlue, 0.01, 0.28, 0, 6.0, 12.0, 0.0, 0.0, -1) 
					ShowSyncHudMsg(id, PlayerInfoHud,"[Spectating: %s] ^n[Level: %s] ^n[EXP: %d/ %d]", iSpecName, RANKS[g_iLevel[iSpec]], g_iXP[iSpec], EXP[g_iLevel[iSpec] + 1]) 
				}
			}
			case 2:
			{
				if(g_iLevel[iSpec] == 18)
				{
					set_hudmessage(iRed, iGreen, iBlue, 0.75, 0.28, 0, 6.0, 12.0, 0.0, 0.0, -1) 
					ShowSyncHudMsg(id, PlayerInfoHud,"[Spectating: %s] ^n[Level: Complete] ^n[EXP: Complete]", iSpecName) 
				}
				else
				{
					set_hudmessage(iRed, iGreen, iBlue, 0.75, 0.28, 0, 6.0, 12.0, 0.0, 0.0, -1) 
					ShowSyncHudMsg(id, PlayerInfoHud,"[Spectating: %s] ^n[Level: %s] ^n[EXP: %d/ %d]", iSpecName, RANKS[g_iLevel[iSpec]], g_iXP[iSpec], EXP[g_iLevel[iSpec] + 1]) 
				}
			}
		}
	}
	else
	{
		switch(iHudLocation)
		{
			case 1:
			{
				if(g_iLevel[id] == 18)
				{
					set_hudmessage(iRed, iGreen, iBlue, 0.01, 0.28, 0, 6.0, 12.0, 0.0, 0.0, -1) 
					ShowSyncHudMsg(id, PlayerInfoHud,"[Level: Complete] ^n[EXP: Complete]") 
				}
				else
				{
					set_hudmessage(iRed, iGreen, iBlue, 0.01, 0.28, 0, 6.0, 12.0, 0.0, 0.0, -1) 
					ShowSyncHudMsg(id, PlayerInfoHud,"[Level: %s] ^n[EXP: %d/ %d]",RANKS[g_iLevel[id]], g_iXP[id], EXP[g_iLevel[id] + 1]) 
				}
			}
			case 2:
			{
				if(g_iLevel[id] == 18)
				{
					set_hudmessage(iRed, iGreen, iBlue, 0.75, 0.28, 0, 6.0, 12.0, 0.0, 0.0, -1) 
					ShowSyncHudMsg(id, PlayerInfoHud,"[Level: Complete] ^n[EXP: Complete]") 
				}
				else
				{
					set_hudmessage(iRed, iGreen, iBlue, 0.75, 0.28, 0, 6.0, 12.0, 0.0, 0.0, -1) 
					ShowSyncHudMsg(id, PlayerInfoHud,"[Level: %s] ^n[EXP: %d/ %d]",RANKS[g_iLevel[id]], g_iXP[id], EXP[g_iLevel[id] + 1]) 
				}
			}
		}
	}
} 

public ShowScore()
{
	new ScoreHud = CreateHudSyncObj()
	
	new szColors[16]
	new szRed[4], szGreen[4], szBlue[4]
	new iRed, iGreen, iBlue
	
	get_pcvar_string(g_iScoreColors, szColors, charsmax(szColors))
	parse(szColors, szRed, charsmax(szRed), szGreen, charsmax(szGreen), szBlue, charsmax(szBlue))
	iRed = str_to_num(szRed); iGreen = str_to_num(szGreen); iBlue = str_to_num(szBlue);  
	
	set_hudmessage(iRed, iGreen, iBlue, -1.0, 0.02, 0, 12.0, 12.0, 0.0, 0.0, -1)
	ShowSyncHudMsg(0, ScoreHud, "[Zombie] - [Human]^n[%s%d] ----- [%s%d]",g_iZombieScore >= 10 ? "" : "0", g_iZombieScore, g_iHumanScore >= 10 ? "" : "0", g_iHumanScore)
}

public custom_menu(id)
{
	new sMenu = menu_create("\yLevel Menu \r3.1", "custom_handler")
	
	menu_additem(sMenu, "\wShow global top player!", "1", 0)
	menu_additem(sMenu, "\wShow online top player!", "2", 0)
	menu_additem(sMenu, "\wEXP for next level", "3", 0)
	menu_additem(sMenu, "\wSave your EXP!", "4", 0)
	
	menu_display(id, sMenu, 0)
}

public custom_handler(id, menu, item)
{
	switch(item)
	{
		case 0: show_global_top(id)
		case 1: show_online_top(id)
		case 2: show_stats(id)
		case 3: save_data(id)
	}
	
	menu_destroy(menu)
}

#if defined CUSTOM_CHAT
public custom_say(id)
{
	new szMessage[192], szName[32]
	
	read_args(szMessage, charsmax(szMessage))
	remove_quotes(szMessage)
	get_user_name(id, szName, charsmax(szName))
	
	if(equali(szMessage[0], " ") || equali(szMessage[0], "") || !is_valid_msg(szMessage))
		return PLUGIN_HANDLED_MAIN
	
	if(is_user_alive(id))
	{
		format(szMessage, charsmax(szMessage), "^4[%s] ^3%s : ^1%s", RANKS[g_iLevel[id]], szName, szMessage)
	}
	else
	{
		format(szMessage, charsmax(szMessage), "^1*DEAD* ^4[%s] ^3%s : ^1%s", RANKS[g_iLevel[id]], szName, szMessage)
	}
	
	new iPlayers[32], iPlayerCount, i, player
	
	get_players(iPlayers, iPlayerCount, "ch") 
	for(i = 0; i < iPlayerCount; i++)
	{
		player = iPlayers[i]
		if(is_user_alive(id) && is_user_alive(player) || !is_user_alive(id) && !is_user_alive(player))
		{
			message_begin(MSG_ONE, g_msgSayText, {0, 0, 0}, player)
			write_byte(id)
			write_string(szMessage)
			message_end()
		}
	}
	
	return PLUGIN_CONTINUE
}

public custom_say_team(id)
{
	new szMessage[192], szName[32]
	
	read_args(szMessage, charsmax(szMessage))
	remove_quotes(szMessage)
	get_user_name(id, szName, charsmax(szName))
	
	if(equali(szMessage[0], " ") || equali(szMessage[0], "") || !is_valid_msg(szMessage))
		return PLUGIN_HANDLED_MAIN
	
	if(is_user_alive(id))
	{
		format(szMessage, charsmax(szMessage), "^4[%s] ^3%s : ^1%s", RANKS[g_iLevel[id]], szName, szMessage)
	}
	else
	{
		format(szMessage, charsmax(szMessage), "^1*DEAD* ^4[%s] ^3%s : ^1%s", RANKS[g_iLevel[id]], szName, szMessage)
	}
	
	new iPlayers[32], iPlayerCount, i, player
	get_players(iPlayers, iPlayerCount, "ch") 
	for(i = 0; i < iPlayerCount; i++)
	{
		player = iPlayers[i]
		if(is_user_alive(id) && is_user_alive(player) && get_user_team(id) == get_user_team(player) || !is_user_alive(id) && !is_user_alive(player) && get_user_team(id) == get_user_team(player))
		{
			message_begin(MSG_ONE, g_msgSayText, {0, 0, 0}, player)
			write_byte(id)
			write_string(szMessage)
			message_end()
		}
	}
	
	return PLUGIN_CONTINUE
}
#endif

public cl_give(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
	{				
		return PLUGIN_HANDLED
	}
	
	new iTarget[32], iCount[32]	
	read_argv(1, iTarget, charsmax(iTarget))
	read_argv(2, iCount, charsmax(iCount))
	
	new target_id, iName[32], iNameID[32]
	target_id = find_player("bl", iTarget)
	
	get_user_name(target_id, iName, charsmax(iName)) 
	get_user_name(id, iNameID, charsmax(iNameID))
	
	if(!target_id) 
	{
		console_print(id, "Can't find that player")
		return PLUGIN_HANDLED
	}
	
	if(read_argc() != 3)
	{
		return PLUGIN_HANDLED	
	}
	
	if(str_to_num(iCount) < (EXP[g_iLevel[target_id] + 1] - g_iXP[target_id]))
	{
		if(str_to_num(iCount) == 0)
		{
			console_print(id, "EXP for %s is %i / %i", iName, g_iXP[target_id], EXP[g_iLevel[target_id] + 1])
		}
		else
		{
			console_print(id, "%s has been given %i EXP", iName, str_to_num(iCount))
			g_iXP[target_id] += str_to_num(iCount)
		}
	}
	else
	{
		console_print(id, "Maximum EXP allowed for %s: %i", iName, (EXP[g_iLevel[target_id] + 1] - g_iXP[target_id]))
	}
	
	return PLUGIN_HANDLED;
}

public show_stats(id)
{
	if(is_user_connected(id))
	{
		sChatColor(id, "^x04[CL]^x03 %L", id, "CL_SHOW_STAT", RANKS[g_iLevel[id]], (EXP[g_iLevel[id] + 1] - g_iXP[id]))
	}
}

public show_online_top(id)
{
	static Sort[33][2]
	new szName[MAXPLAYERS+1][32]
	new players[32], num, count, index
	
	get_players(players, num)
	for(new i = 0; i < num; i++)
	{
		index = players[i]
		get_user_name(index, szName[index], charsmax(szName))
		
		Sort[count][0] = index
		Sort[count][1] = g_iXP[index]
		count++
	}
	
	SortCustom2D(Sort, count, "CompareEXP")
	
	new y = clamp(count, 0, 10)
	new kindex, szMotd2[1536], len
	szMotd2[0] = 0
	
	add(szMotd2, charsmax(szMotd2),
	"<html><style>\
	body{background:#040404;font-family:Verdana, Arial, Sans-Serif;font-size:19pt;}\
	.t{color:#808080;text-align:left; }\
	#h{background: #0066CC url('http://onlyarg.com/foro/images/Amiral/thead.png') repeat-x;color:#E0E0E0;font-weight:bold;}\
	#p{color:#D41313;}\
	#n{color:#fff;}\
	</style><body>\
	<table cellspacing=0 width=100% class=t>")
	
	add(szMotd2, charsmax(szMotd2),
	"<tr><td id=h width=7%>#</td>\
	<td id=h>NAME</td>\
	<td id=h>LEVEL</td>\
	<td id=h>EXP</td></tr>")
	
	len = strlen(szMotd2)
	for(new x = 0; x < y; x++)
	{
		kindex = Sort[x][0]
		
		replace_all(szName[kindex], charsmax(szName), "<", "&lt")
		replace_all(szName[kindex], charsmax(szName), ">", "&gt")
		
		len += formatex(szMotd2[len], charsmax(szMotd2)-len,
		"<tr><td id=p>%d</td>\
		<td id=n>%s</td>\
		<td>%d</td>\
		<td>%d</td>", (x+1), szName[kindex], g_iLevel[kindex], g_iXP[kindex])
	}
	
	add(szMotd2, charsmax(szMotd2), "</table></body></html>")
	show_motd(id, szMotd2, "ONLINE PLAYERS")
}

public CompareEXP(elem1[], elem2[])
{
	if(elem1[1] > elem2[1]) return -1;
	else if(elem1[1] < elem2[1]) return 1;
	
	return 0;
}

public show_global_top(id)
{
	show_motd(id, g_szMotd, "GLOBAL PLAYERS")
}

FormatTop(iNum)
{
    enum _:sVaultData
	{
		VD_Key[64],
		VD_Value
	}
	
    new sVault = nvault_util_open(VAULTNAME)
    new Array:entries = ArrayCreate(sVaultData)
	
    new sizeEntries;
    new numEntries = nvault_util_count(sVault)
    new data[sVaultData], value[128], data2[sVaultData]
    
    for(new i = 0, pos, timestamp; i < numEntries; i++) 
	{
        pos = nvault_util_read(sVault, pos, data[VD_Key], charsmax(data[VD_Key]), value, charsmax(value), timestamp);
        data[VD_Value] = str_to_num(value)
        
        if(sizeEntries == 0) 
		{
            ArrayPushArray(entries, data)
            sizeEntries++
        } 
		else 
		{
            for(timestamp = 0; timestamp <= sizeEntries; timestamp++) 
			{
                if(timestamp == sizeEntries) 
				{
                    if(sizeEntries < iNum) 
					{
                        ArrayPushArray(entries, data)
                        sizeEntries++
                    }
					
                    break
                }
                
                ArrayGetArray(entries, timestamp, data2)
                if(data[VD_Value] >= data2[VD_Value]) 
				{
                    ArrayInsertArrayBefore(entries, timestamp, data)
                    if(sizeEntries < iNum) 
					{
                        sizeEntries++
                    } 
					else 
					{
                        ArrayDeleteItem(entries, sizeEntries);
                    }
                    
                    break
                }
            }
        }
    }
	
    nvault_util_close(sVault)
	
    new iLen
    new len = charsmax(g_szMotd)
	
    iLen = formatex(g_szMotd, len, "<STYLE>body{background:#212121;color:#d1d1d1;font-family:Arial}table{width:100%%;font-size:19px}</STYLE><table cellpadding=1 cellspacing=1 border=0>")
    iLen += formatex(g_szMotd[iLen], len - iLen, "<tr bgcolor=#333333><th width=1%%><align=left font color=white> %s <th width=5%%> %-22.22s <th width=5%%> %s", "#", "NAME", "LEVEL")

    new i
    for(i = 0; i < sizeEntries; i++)
    {
        ArrayGetArray(entries, i, data); 
        data[VD_Key][20] = 0;
		
        replace_all(data[VD_Key], charsmax(data[VD_Key]), "<", "&lt;")
        replace_all(data[VD_Key], charsmax(data[VD_Key]), ">", "&gt;")
        
        iLen += formatex(g_szMotd[iLen], len - iLen, "<tr align=left%s><td align=left><font color=white> %d. <td> %-22.22s <td> %d", " bgcolor=#2b5b95",(i+1), data[VD_Key], data[VD_Value])
    }
    
    ArrayDestroy(entries);
    iLen += formatex(g_szMotd[iLen], len - iLen, "</table></body>")
}

public save_data(id)
{
	if(is_user_alive(id))
	{
		SaveData(id)
		sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_SAVE")
	}
}

public event_new_round()
{
	new iPlayers[32], iPlayerCount, i, player
	get_players(iPlayers, iPlayerCount, "a") 
	for(i = 0; i < iPlayerCount; i++)
	{
		player = iPlayers[i]
		g_iDamage[player][player] = 0
	}
}

public event_Restart()
{
	if(get_pcvar_num(g_iEShowScore))
	{
		g_iZombieScore = 0
		g_iHumanScore = 0
	}
}

public event_Damage(iVictim)
{
	static iAttacker; iAttacker = get_user_attacker(iVictim)
	
	new AttackerHud = CreateHudSyncObj()
	new VictimHud = CreateHudSyncObj()
	
	if(iAttacker == iVictim || !is_user_alive(iAttacker) || !is_user_alive(iVictim))
		return
		
	if(get_pcvar_num(g_iEHitRecieved))
	{
		static iHit; iHit = read_data(2)
		set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(iVictim, VictimHud, "%i^n", iHit)	
	}
	
	if(get_pcvar_num(g_iEHitDealt))
	{
		static iHit; iHit = read_data(2)
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(iAttacker, AttackerHud, "%i^n", iHit)
	}
	#if defined IM_USING_ZP50
	if(zp_core_is_zombie(iVictim) && !zp_get_user_survivor(iAttacker))
	#else
	if(zp_get_user_zombie(iVictim) && !zp_get_user_survivor(iAttacker))
	#endif
	{
		g_iDamage[iAttacker][iVictim] += read_data(2)
	}
}

public event_DeathMsg()
{
	new iKiller; iKiller = read_data(1)
	new iVictim; iVictim = read_data(2)
	new iIsHeadshot; iIsHeadshot = read_data(3)
	
	if(iVictim == iKiller || !is_user_alive(iKiller))
		return
	
	#if defined IM_USING_ZP50
	if(!zp_core_is_zombie(iKiller))
	#else
	if(!zp_get_user_zombie(iKiller))
	#endif
	{
		if(iIsHeadshot)
		{
			g_bKilledZombie[iKiller][iVictim] = true
			
			g_iXP[iKiller] += g_CHeadEXP
			sChatColor(iKiller, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_HEADSHOT_KILL", g_CHeadEXP)
		}
		else
		{
			g_bKilledZombie[iKiller][iVictim] = true
			
			g_iXP[iKiller] += g_CHumanEXP
			sChatColor(iKiller, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_KILL", g_CHumanEXP)
		}
			
		ReviewLevel(iKiller)
			
		#if defined IM_USING_ZP50
		if(get_pcvar_num(g_iEAssistEXP))
		{
			new iPlayers[32], iPlayerCount, i, id
			get_players(iPlayers, iPlayerCount, "ah") 
			for(i = 0; i < iPlayerCount; i++)
			{
				id = iPlayers[i]
					
				if(g_iDamage[id][iVictim] >= g_iMaxHealth[iVictim]/ g_CAssistDivide)
				{	
					if(!g_bKilledZombie[id][iVictim] && !zp_core_is_zombie(id))
					{
						g_iXP[id] += g_CAssistEXP
						
						new szName[32]
						get_user_name(iKiller, szName, charsmax(szName))
						sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_ASSIST", g_CAssistEXP, RANKS[g_iLevel[iKiller]], szName)
						
						ReviewLevel(id)
						
						g_iDamage[id][iVictim] = 0
					}
					else
					{
						g_bKilledZombie[id][iVictim] = false
					}
				}
			}
		}
		#endif
	}
}

public ReviewLevel(id)
{
	while((g_iLevel[id] < 18 && g_iXP[id] >= EXP[g_iLevel[id] + 1]))
	{
		g_iLevel[id] += 1
		sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_LEVEL_UP", RANKS[g_iLevel[id]])
		
		if(get_pcvar_num(g_iELevelBonus))
		{
			g_iXP[id] += g_CLevelEXP
			sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_BONUS_EXP", get_pcvar_num(g_iLevelEXPBonus))
		
			iBonus(id)
		}
		
		if(get_pcvar_num(g_iEAPRewards))
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + get_pcvar_num(g_iLevelAPBonus))
			sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_BONUS_AP", get_pcvar_num(g_iLevelAPBonus))
		}
	}
}

public event_StatusValue(id)
{
	if(!g_CIcon)
		return
	
	new pid = read_data(2)
	new pidlevel = g_iLevel[pid]
	
	#if defined IM_USING_ZP50
	if(!pev_valid(pid) || !is_user_alive(pid) || zp_core_is_zombie(pid))
		return
	#else
	if(!pev_valid(pid) || !is_user_alive(pid) || zp_get_user_zombie(pid))
		return
	#endif
	
	new flTime = floatround(g_fIconTime * 10)
	if (flTime > 0)
	{
		Create_TE_PLAYERATTACHMENT(id, pid, 55, g_iSprite[pidlevel], flTime)
	}
}

public fw_PlayerRespawn(id)
{
	if(is_user_alive(id))
	{
		if(get_pcvar_num(g_iELevelBonus))
		{
			set_task(5.0, "iBonus", id)
		}
		
		set_task(4.0, "iInform", id)
		set_task(120.0, "iSave", id)
	}
}

public iBonus(id)
{
	if(is_user_alive(id))
	{
		#if defined IM_USING_ZP50
		if (zp_core_is_zombie(id))
			return
		#else
		if (zp_get_user_zombie(id))	
			return
		#endif
		
		new iHealth = g_iLevel[id]* get_pcvar_num(g_iLevelHPBonus)
		new iArmor = g_iLevel[id]* get_pcvar_num(g_iLevelArBonus)
		
		if(get_pcvar_num(g_iEHPBonus))
		{
			set_user_health(id, get_user_health(id) + iHealth)
		}
		
		if(get_pcvar_num(g_iEArmorBonus))
		{
			set_user_armor(id, get_user_armor(id) + iArmor)
		}
		
		if(get_pcvar_num(g_iEHPBonus) && get_pcvar_num(g_iEArmorBonus))
		{
			sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_INFORM", RANKS[g_iLevel[id]], iHealth, iArmor)
		}
	}
}

public iInform(id)
{
	if(is_user_alive(id))
	{
		sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_INFORM_2")
	}
}

public iSave(id)
{
	if(is_user_alive(id))
	{
		sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_INFORM_3")
	}
}

#if defined CUSTOM_CHAT
public message_SayText(id)
{
	return PLUGIN_HANDLED
}
#endif

#if defined IM_USING_ZP50
public zp_fw_core_infect_post(id, attacker)
{
	if(zp_class_zombie_get_current(id) == ZP_INVALID_ZOMBIE_CLASS)
		return;
	
	g_iMaxHealth[id] = zp_class_zombie_get_max_health(id, zp_class_zombie_get_current(id))
}
#endif

#if defined CHANGE_NAME
public FwdClientUserInfoChanged( id, szBuffer )
{
	if ( !is_user_connected( id ) )
		return FMRES_IGNORED;
		
	static szNewName[32];
 
	engfunc( EngFunc_InfoKeyValue, szBuffer, "name", szNewName, charsmax(szNewName));
	
	if(equal(szNewName, g_sName[id]))
		return FMRES_IGNORED;
	
	SaveData(id)
	
	sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_CHANGE_NAME2", g_sName[id], szNewName)
	sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_CHANGE_NAME3", szNewName)
	
	copy(g_sName[id], charsmax(g_sName[]), szNewName)
	LoadData(id)
	
	sChatColor(id, "^x04[CL]^x03 %L", LANG_PLAYER, "CL_CHANGE_NAME4")
	
	return FMRES_IGNORED;
} 
#endif

SaveData(id)
{
	new szData[32], szKey[40]
	switch(g_CSaveType)
	{
		case 1:
		{
			formatex(szKey, charsmax(szKey), "%s", g_iSteamID[id])
		}
		case 2:
		{
			formatex(szKey, charsmax(szKey), "%s", g_sName[id])
		}
	}
	
	formatex(szData, charsmax(szData), "%d %d", g_iLevel[id], g_iXP[id])
	nvault_set(g_iVault, szKey, szData)
}

LoadData(id)
{
	new szData[32], szKey[40]
	switch(g_CSaveType)
	{
		case 1:
		{
			formatex(szKey, charsmax(szKey), "%s" , g_iSteamID[id])
		}
		case 2:
		{
			formatex(szKey, charsmax(szKey), "%s", g_sName[id])
		}
	}
	
	if(nvault_get(g_iVault, szKey, szData, charsmax(szData)))
	{
		new iSpacePos = contain(szData, " ")
		if(iSpacePos > -1)
		{    
			new szLevel[8], szXP[32]
			
			parse(szData, szLevel, charsmax(szLevel), szXP, charsmax(szXP))
			
			g_iLevel[id] = str_to_num(szLevel)
			g_iXP[id] = str_to_num(szXP)
		}
	}
}

#if defined CUSTOM_CHAT
bool:is_valid_msg(const szMessage[])
{
	if(szMessage[0] == '@' || szMessage[0] == '/' || szMessage[0] == '!' || !strlen(szMessage))
		return false
		
	return true
}
#endif

stock Create_TE_PLAYERATTACHMENT(id, entity, vOffset, iSprite, life)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(entity)
	write_coord(vOffset)
	write_short(iSprite)
	write_short(life)
	message_end()
}

stock sChatColor(const id, const input[], any:...)
{
    new count = 1, players[32], i, player
    static msg[191]

    if(numargs() == 2)
        copy(msg, 190, input)
    else
        vformat(msg, 190, input, 3)

    replace_all(msg, 190, "!g", "^4")
    replace_all(msg, 190, "!y", "^1")
    replace_all(msg, 190, "!t", "^3")
    
    if(id) {
        if(!is_user_connected(id)) return
        players[0] = id
    }
    else get_players(players, count, "ch")

    for(i = 0; i < count; i++)
    {
		player = players[i]
		
		message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
		write_byte(player)
		write_string(msg)
		message_end()
	}
} 
