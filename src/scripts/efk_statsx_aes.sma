/*
*	EFK StatsX AES. Based on AES: StatsX
*	Original CSStatsX author: serfreeman1337	http://1337.uz/
*/

#include <amxmodx>
#include <hamsandwich>
#include <time>

#include <efk_core>
#include <efk_statsx>

new const PLUGIN[] = "EFK: StatsX AES"
new const AUTHOR[] = "serfreeman1337, Next21 Team"

new const GAME_TAG[] = EFK_GAME_TAG

/* - CVARS - */
enum _:cvars {
	CVAR_MOTD_DESC,
	CVAR_CHAT_DESC,
	CVAR_MOTD_ONLINE_DESC,
	CVAR_MOTD_ASSISTANS_DESC,
	CVAR_MOTD_LEVEL_DESC
}

new cvar[cvars]
new g_iXPStep
new Float:g_fXPScale

#define MAX_TOP			10

#define BUFF_LEN 1535

new theBuffer[BUFF_LEN + 1] = 0

#define MENU_LEN 512

new g_MenuStatus[MAX_PLAYERS + 1][2]

public SayStatsMe           = 0 // displays user's stats and rank
public SayRankStats         = 0 // displays user's rank stats
public SayRank              = 0 // displays user's rank
public SayTop15             = 0 // displays first 15 players
public SayStatsAll          = 0 // displays all players stats and rank
public SayHot               = 0	// displays top from current players

//*** LEVELS ***//

new g_GotLevelUp[MAX_PLAYERS + 1]
new g_CurRank[MAX_PLAYERS + 1]
new g_iOldLevel[MAX_PLAYERS + 1]
new g_hudDisable

public client_disconnected(id)
{
	g_iOldLevel[id] = 0
}

public csxsql_stats_loaded(id)
{
	new rank, stats[STATS_END]
	rank = get_user_stats_sql(id, stats)

	if (rank >= 1)
	{
		g_CurRank[id] = rank

		new curLevel = frags_to_level(stats[STATS_KILLS], stats[STATS_ASSISTS])
		g_iOldLevel[id] = curLevel
		kc_player_set_level(id, curLevel)
		kc_player_set_favknife(id, stats[STATS_FAVKNIFE] - 1)
	}
}

public fw_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
 		return HAM_IGNORED

	g_GotLevelUp[id] = 0

	new rank, stats[STATS_END], stats_num

	rank = get_user_stats_sql(id,stats)
	stats_num = get_statsnum_sql()

	if (rank < 1)
		return HAM_IGNORED

	new curLevel = frags_to_level(stats[STATS_KILLS], stats[STATS_ASSISTS])
	if (g_iOldLevel[id] != curLevel)
	{
		g_iOldLevel[id] = curLevel
		kc_player_set_level(id, curLevel)
	}

	if (!(g_hudDisable & (1 << id)) && g_CurRank[id] > 0)
	{
		new message[191], len

		len += formatex(message[len],charsmax(message)- len,"^4[%s] ^1",GAME_TAG)

		if (rank < g_CurRank[id])
			client_print_color(id, print_team_default, "%s%L", message, id, "AES_YOUR_RANK_IS_UP", g_CurRank[id] - rank)
		else if (rank > g_CurRank[id])
			client_print_color(id, print_team_default, "%s%L", message, id, "AES_YOUR_RANK_IS_DOWN", rank - g_CurRank[id])

		len += formatex(message[len],charsmax(message) - len,"%L ",id,"AES_YOUR_RANK_IS",rank,stats_num)
		len += parse_rank_desc(id,message[len],charsmax(message)-len,stats)

		client_print_color(id,print_team_default,message)

		g_hudDisable |= (1 << id)
	}

	g_CurRank[id] = rank

	return HAM_IGNORED
}

public print_level(id)
{
	new rank, stats[STATS_END]

	rank = get_user_stats_sql(id, stats)

	if (rank < 1)
		return

	new iLevel, iNextXP
	iLevel = frags_to_level(stats[STATS_KILLS], stats[STATS_ASSISTS], iNextXP)

	client_print_color(id, print_team_red, "^4[%s] ^1%L",
		GAME_TAG, id, "AES_LEVELFRAGS", iLevel, iNextXP)
}

public fw_DeathMsg()
{
	new
	iAttacker = get_msg_arg_int(1),
	iVictim = get_msg_arg_int(2)

	new rank, stats[STATS_END]

	rank = get_user_stats_sql(iAttacker, stats)

	if (rank < 1 || iAttacker == iVictim)
		return

	new iOldLevel = frags_to_level(stats[STATS_KILLS], stats[STATS_ASSISTS])
	new iNewLevel = frags_to_level(stats[STATS_KILLS] + 1, stats[STATS_ASSISTS])

	if(iOldLevel != iNewLevel && !g_GotLevelUp[iAttacker])
	{
		new sPlayerName[32]
		get_user_name(iAttacker, sPlayerName, 31)

		// Сообщение о достижении нового уровне
		client_print_color(0, print_team_red, "^4[%s] ^1%L",
			GAME_TAG,
			LANG_PLAYER, "AES_NEWLEVEL", sPlayerName, iNewLevel)

		g_GotLevelUp[iAttacker] = 1
	}
}

public event_NewRound()
{
	g_hudDisable = 0
}

public client_putinserver(id)
{
	g_CurRank[id] = 0
}

public plugin_precache()
{
	register_plugin(PLUGIN, EFK_VERSION, AUTHOR)

	/*
	// Display /top15 and /rank
	// Important! The MOTD cannot show more than 1534 characters, and the chat message cannot show more than 192 characters.
	// If something is displayed incompletely, then you need to reduce the number of characters (the top does not show more than 10 players).
	//   * - Rank
	//   a - Name (Only /top15)
	//   b - Kills
	//   c - Deaths
	//   d - Heal
	//   e - Skill
	//   f - Favorite Knife
	//   h - Effectiveness
	//   l - Level
	//   k - K:D
	//   n - Online Time
	//   s - Assists
	*/

	cvar[CVAR_MOTD_DESC] = register_cvar("efk_aes_top", "*abcsfiel")
	cvar[CVAR_MOTD_ONLINE_DESC] = register_cvar("efk_aes_online", "*anl")
	cvar[CVAR_MOTD_ASSISTANS_DESC] = register_cvar("efk_aes_assistans", "*asdl")
	cvar[CVAR_MOTD_LEVEL_DESC] = register_cvar("efk_aes_level", "*al")
	cvar[CVAR_CHAT_DESC] = register_cvar("efk_aes_rank", "bcs")
	bind_pcvar_num(register_cvar("efk_aes_xp_step", "100"), g_iXPStep)
	bind_pcvar_float(register_cvar("efk_aes_xp_scale", "1.0"), g_fXPScale)

	register_dictionary("statsx.txt")
	register_dictionary("efk_aes.txt")

	register_dictionary("time.txt")
}

public plugin_init()
{
	register_clcmd("say","Say_Catch")
	register_clcmd("say_team","Say_Catch")

	register_menucmd(register_menuid("Stats Menu"), 1023, "actionStatsMenu")

	register_message(get_user_msgid("DeathMsg"), "fw_DeathMsg")

	register_clcmd("say /lv", "print_level")
	register_clcmd("say_team /lv", "print_level")
	register_clcmd("say /lvl", "print_level")
	register_clcmd("say_team /lvl", "print_level")

	register_event("HLTV", "event_NewRound", "a", "1=0", "2=0")

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
}

public OnAutoConfigsBuffered()
{
	new addStast[] = "amx_statscfg add ^"%s^" %s"

	server_cmd(addStast, "ST_SAY_STATSME", "SayStatsMe")
	server_cmd(addStast, "ST_SAY_RANKSTATS", "SayRankStats")
	server_cmd(addStast, "ST_SAY_RANK", "SayRank")
	server_cmd(addStast, "ST_SAY_TOP15", "SayTop15")
	server_cmd(addStast, "ST_SAY_STATS", "SayStatsAll")
	server_cmd(addStast, "AES_SAY_HOT", "SayHot")
}

//
// Команда /hot
//
public ShowCurrentTop(id)
{
	if(!SayHot)
	{
		client_print_color(id,print_team_red,"^4[%s] ^1%L",GAME_TAG, id,"DISABLED_MSG")

		return PLUGIN_HANDLED
	}

	new players[MAX_PLAYERS],pnum
	get_players(players,pnum, "ch")

	new current_top[MAX_PLAYERS][2]

	for(new i,stats[STATS_END]; i < pnum ; i++)
	{
		current_top[i][0] = players[i]
		current_top[i][1] = get_user_stats_sql(players[i],stats)
	}

	SortCustom2D(current_top,sizeof current_top,"Sort_CurrentTop")

	new len,title[64]
	formatex(title,charsmax(title),"%L",id,"AES_HOT_PLAYERS")

	// заголовок
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_META")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_STYLE")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_TOP_BODY",id,"AES_HOT_PLAYERS")

	// таблица со статистикой
	new row_str[512],cell_str[MAX_NAME_LENGTH * 3],row_len
	new desc_str[10],desc_char,bool:odd

	get_pcvar_string(cvar[CVAR_MOTD_DESC],desc_str,charsmax(desc_str))
	trim(desc_str)

	new desc_length = strlen(desc_str)

	len += parse_top_desc_header(id,theBuffer,BUFF_LEN,len,false,desc_str)

	for(new i,stats[STATS_END],player_id ,name[MAX_NAME_LENGTH] ; i < sizeof current_top ; i++)
	{
		player_id = current_top[i][0]

		if(!player_id)
		{
			continue
		}

		get_user_name(player_id,name,charsmax(name))

		get_user_stats_sql(player_id,stats)

		for(new desc_index ; desc_index < desc_length ; desc_index++)
		{
			cell_str[0] = 0
			desc_char = desc_str[desc_index]

			switch(desc_char)
			{
				case '*':
				{
					formatex(cell_str,charsmax(cell_str),"%d",current_top[i][1])
				}
				case 'a':
				{

					formatex(cell_str,charsmax(cell_str),"%s",name)

					replace_all(cell_str,charsmax(cell_str),"<","&lt")
					replace_all(cell_str,charsmax(cell_str),">","&gt")
				}
				case 'b':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats[STATS_KILLS])
				}
				case 'c':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats[STATS_DEATHS])
				}
				case 'd':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats[STATS_HEAL])
				}
				case 'f':
				{
					new knf_name[MAX_NAME_LENGTH]
					kc_knife_get_abil1_name(stats[STATS_FAVKNIFE] - 1, knf_name, charsmax(knf_name))
					formatex(cell_str,charsmax(cell_str),"%s", knf_name)
				}
				case 'h':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f%%",
						effec(stats)
					)
				}
				case 's':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats[STATS_ASSISTS])
				}
				case 'l':
				{
					formatex(cell_str,charsmax(cell_str),"%d", frags_to_level(stats[STATS_KILLS], stats[STATS_ASSISTS]))
				}
				case 'k':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f",
						kd_ratio(stats)
					)
				}
				case 'n':
				{
					new ot = get_user_gametime(player_id)
					func_format_ot(ot,cell_str,charsmax(cell_str),id)
				}
				case 'e':
				{
					new Float:skill; get_user_skill(player_id, skill)
					formatex(cell_str,charsmax(cell_str),"%.2f", skill)
				}
				default: continue
			}

			// выводим отформатированные данные
			row_len += formatex(row_str[row_len],charsmax(row_str)-row_len,"%L",id,"AES_BODY_CELL",cell_str)
		}

		row_len = len
		len += formatex(theBuffer[len],charsmax(theBuffer)-len,"%L",id,"AES_BODY_ROW",odd ? " id=b" : " id=q",row_str)

		if(len >= BUFF_LEN)
		{
			theBuffer[row_len] = 0
		}

		row_len = 0
		odd ^= true
	}

	show_motd(id,theBuffer,title)

	return PLUGIN_HANDLED
}

public Sort_CurrentTop(const elem1[], const elem2[])
{
	if(elem1[1] < elem2[1])
	{
		return -1
	}
	else if(elem1[1] > elem2[1])
	{
		return 1
	}

	return 0
}

// Ловим сообщения чата
public Say_Catch(id){
	new msg[191]
	read_args(msg,190)

	trim(msg)
	remove_quotes(msg)

	if(msg[0] == '/'){
		if(strcmp(msg[1],"rank",true) == 0)
		{
			return RankSay(id)
		}
		if(strcmp(msg[1],"hot",true) == 0 || strcmp(msg[1],"topnow",true) == 0)
		{
			return ShowCurrentTop(id)
		}
		if(containi(msg[1],"top") == 0)
		{
			replace(msg,190,"/top","")

			return SayTop(id,str_to_num(msg))
		}
		if(containi(msg[1],"online") == 0)
		{
			replace(msg,190,"/online","")

			return SayTopOnline(id,str_to_num(msg))
		}
		if(containi(msg[1],"assist") == 0)
		{
			replace(msg,190,"/assist","")

			return SayTopAssist(id,str_to_num(msg))
		}
		if(containi(msg[1],"level") == 0)
		{
			replace(msg,190,"/level","")

			return SayTopLevel(id,str_to_num(msg))
		}
		if(strcmp(msg[1],"rankstats",true) == 0)
		{
			return RankStatsSay(id,id)
		}

		if(strcmp(msg[1],"statsme",true) == 0)
		{
			return StatsMeSay(id,id)
		}

		if(strcmp(msg[1],"stats",true) == 0)
		{
			arrayset(g_MenuStatus[id],0,2)
			return ShowStatsMenu(id,0)
		}
	}

	return PLUGIN_CONTINUE
}

//
// Команда /rank
//
public RankSay(id){
	// команда /rank выключена
	if(!SayRank)
	{
		client_print_color(id,print_team_red,"^4[%s] ^1%L",GAME_TAG, id,"DISABLED_MSG")

		return PLUGIN_HANDLED
	}

	new message[191],len,rank,stats_num,stats[STATS_END]

	len += formatex(message[len],charsmax(message)- len,"^4[%s] ^1",GAME_TAG)

	rank = get_user_stats_sql(id,stats)
	stats_num = get_statsnum_sql()

	if(rank > 0)
	{
		len += formatex(message[len],charsmax(message) - len,"%L ",id,"AES_YOUR_RANK_IS",rank,stats_num)
		len += parse_rank_desc(id,message[len],charsmax(message)-len,stats)
	}
	else
	{
		len += formatex(message[len],charsmax(message) - len,"%L ",id,"AES_STATS_INFO2")
	}

	client_print_color(id,print_team_default,message)

	return PLUGIN_HANDLED
}

//
// Формирование сообщения /rank
//
parse_rank_desc(id,msg[],maxlen,stats[STATS_END]){
	new cnt,theChar[4],len

	new desc_str[10]
	get_pcvar_string(cvar[CVAR_CHAT_DESC],desc_str,charsmax(desc_str))

	// Проверяем всё флаги
	for(new i,length = strlen(desc_str) ; i < length ; ++i){
		theChar[0] = desc_str[i]	// фз почему напрямую не рабатает

		// если это первое значение, то рисуем в начале скобку, иначе запятую с пробелом
		if(cnt != length)
			len += formatex(msg[len],maxlen - len,cnt <= 0 ? "(" : ", ")

		// добавляем в сообщение информацию в соотв. с флагами
		switch(theChar[0]){
			 // убийства
			case 'b':
			{
				len += formatex(msg[len],maxlen - len,"%L ^3%d^1",id,"KILLS",stats[STATS_KILLS])
			}
			 // смерти
			case 'c':
			{
				len += formatex(msg[len],maxlen - len,"%L ^3%d^1",id,"DEATHS",stats[STATS_DEATHS])
			}
			case 'd':
			{
				len += formatex(msg[len],maxlen - len,"%L ^3%d^1",id,"AES_HEAL",stats[STATS_HEAL])
			}
			// эффективность
			case 'h':
			{
				len += formatex(msg[len],maxlen - len,"%L ^3%d%%^1",id,"EFF",effec(stats))
			}
			// K:D
			case 'k':
			{
				len += formatex(msg[len],maxlen - len,"%L ^3%.2f^1",
					id,"AES_KS",
					kd_ratio(stats)
				)
			}
			case 'n':
			{
				new ot = get_user_gametime(id)

				len += formatex(msg[len],maxlen - len,"%L: ^3",id,"AES_TIME")
				len += func_format_ot(ot,msg[len],maxlen - len,id)
				len += formatex(msg[len],maxlen - len,"^1")
			}
			case 's':
			{
				new Float:skill; get_user_skill(id, skill)
				len += formatex(msg[len],maxlen - len,"%L ^3%.2f^1",id,"AES_SKILL",skill)
			}
		}

		theChar[0] = 0
		cnt ++
	}

	// завершаем всё сообщение скобкой, если была подстановка параметров
	if(cnt)
	{
		len += formatex(msg[len],maxlen - len,")")
	}

	return len
}

func_format_ot(ot,string[],len,idLang = LANG_SERVER)
{
	new d,h,m,s

	d = (ot / SECONDS_IN_DAY)
	ot -= (d * SECONDS_IN_DAY)
	h = (ot / SECONDS_IN_HOUR)
	ot -= (h * SECONDS_IN_HOUR)
	m = (ot / SECONDS_IN_MINUTE)
	ot -= (m * SECONDS_IN_MINUTE)
	s = ot

	if(d)
	{
		return formatex(string,len,"%L",idLang,"AES_STATS_DESC1",d,h,m)
	}
	else if(h)
	{
		return formatex(string,len,"%L",idLang,"AES_STATS_DESC2",h,m)
	}
	else if(m)
	{
		return formatex(string,len,"%L",idLang,"AES_STATS_DESC3",m)
	}

	return formatex(string,len,"%L",idLang,"AES_STATS_DESC4",s)
}
//
// Формирование окна /rankstats
// 	id - кому показывать
// 	player_id - кого показывать
//
public RankStatsSay(id,player_id){
	// Команда /rankstats выключена
	if(!SayRankStats)
	{
		client_print_color(id,print_team_default,"^4[%s] ^1%L",GAME_TAG, id,"DISABLED_MSG")

		return PLUGIN_HANDLED
	}

	if(!is_user_connected(player_id))
	{
		client_print_color(id,print_team_default,"^4[%s] ^1%L",GAME_TAG,id,"AES_STATS_INFO2")

		return PLUGIN_HANDLED
	}

	new len,motd_title[MAX_NAME_LENGTH]
	new name[MAX_NAME_LENGTH],rank,stats[STATS_END],stats_num

	theBuffer[0] = 0

	formatex(motd_title,charsmax(motd_title),"%L",id,"RANKSTATS_TITLE")

	len += formatex(theBuffer[len],BUFF_LEN-len,"%L",id,"AES_META")
	len += formatex(theBuffer[len],BUFF_LEN-len,"%L",id,"AES_STYLE")

	rank = get_user_stats_sql(player_id,stats)
	stats_num = get_statsnum_sql()

	if(id == player_id)
	{
		formatex(name,charsmax(name),"%L",id,"AES_YOU")
	}
	else
	{
		get_user_name(player_id,name,charsmax(name))
	}

	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<table cellspacing=10 cellpadding=0><tr>")

	//
	// Общая статистика
	//
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<td valign=top width=%d%% class=q><table cellspacing=0><tr><th colspan=2>", 40)

	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"%L",
		id,"AES_RANKSTATS_TSTATS",
		name,rank,stats_num
	)

	new Float:skill; get_user_skill(id, skill);

	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=b><td>%L<td>%d",id,"AES_LEVEL",frags_to_level(stats[STATS_KILLS], stats[STATS_ASSISTS]),id)
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=q><td>%L<td>%d",id,"AES_KILLS",stats[STATS_KILLS])
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=b><td>%L<td>%d (%L %.2f)",id,"AES_DEATHS",stats[STATS_DEATHS],id,"AES_KS",kd_ratio(stats))
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=b><td>%L<td>%d",id,"AES_ASSISTS",stats[STATS_ASSISTS],id)
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=b><td>%L<td>%.2f",id,"AES_SKILL",skill,id)
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=q><td>%L<td>%d",id,"AES_DMG",stats[STATS_DMG])
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=q><td>%L<td>%d",id,"AES_HEAL",stats[STATS_HEAL])
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=q><td>%L<td>%.2f%%",id,"AES_EFF",effec(stats))

	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=q><td>%L<td>",id,"AES_TIME")
	len += func_format_ot(
		get_user_gametime(player_id),
		theBuffer[len],charsmax(theBuffer)-len,
		id
	)

	/*
	new from = get_systime() - get_user_lastjoin_sql(player_id)
	new from_str[40]
	get_time_length(id,from,timeunit_seconds,from_str,charsmax(from_str))

	len += formatex(theBuffer[len],charsmax(theBuffer)-len," (%L. %s %L)",
		id,"LAST",
		from_str,
		id,"AGO"
	)
	*/

	new firstjoin = get_user_firstjoin_sql(player_id)

	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=q><td>%L<td>",id,"CSXSQL_FIRSTJOIN")

	if(firstjoin > 0)
	{
		len += format_time(theBuffer[len],charsmax(theBuffer)-len,"%m/%d/%Y - %H:%M:%S",firstjoin)
	}
	else
	{
		len += formatex(theBuffer[len],charsmax(theBuffer)-len,"-")
	}
	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"</td></tr></table></td>")

	//
	// Статистика по используемому оружию
	//
	len += formatex(theBuffer[len],BUFF_LEN-len,"<td valign=top width=60%% class=q><table cellspacing=0 width=100%%><tr><th>%L<th>%L<th>%L<th>%L<th>%L",
		id,"AES_KNIFE",
		id,"AES_KILLS",
		id,"AES_DEATHS",
		id,"AES_DMG",
		id,"AES_EFF"
	)

	new bool:odd
	new knf_stats[STATS_END + 1],Array:knf_stats_array = ArrayCreate(sizeof knf_stats)

	new iKnivesNum = kc_get_knives_num()
	for (new knfId = 1; knfId <= iKnivesNum ; knfId++)
	{
		if (get_user_knfstats_sql(player_id, knfId, stats))
		{
			knf_stats[STATS_KILLS] = stats[STATS_KILLS]
			knf_stats[STATS_DEATHS] = stats[STATS_DEATHS]
			knf_stats[STATS_ASSISTS] = stats[STATS_ASSISTS]
			knf_stats[STATS_DMG] = stats[STATS_DMG]
			knf_stats[STATS_HEAL] = stats[STATS_HEAL]
			knf_stats[STATS_DUELS] = stats[STATS_DUELS]
			knf_stats[STATS_END] = knfId

			ArrayPushArray(knf_stats_array,knf_stats)
		}
	}

	ArraySort(knf_stats_array,"Sort_KnifeStats")

	for(new lena,i,knfId,knf_name[MAX_NAME_LENGTH],length = ArraySize(knf_stats_array) ; i < length && charsmax(theBuffer)-len > 0; i++)
	{
		ArrayGetArray(knf_stats_array,i,knf_stats)

		knfId = knf_stats[STATS_END]
		stats[STATS_KILLS] = knf_stats[STATS_KILLS]
		stats[STATS_DEATHS] = knf_stats[STATS_DEATHS]
		stats[STATS_ASSISTS] = knf_stats[STATS_ASSISTS]
		stats[STATS_DMG] = knf_stats[STATS_DMG]
		stats[STATS_HEAL] = knf_stats[STATS_HEAL]
		stats[STATS_DUELS] = knf_stats[STATS_DUELS]

		kc_knife_get_abil1_name(knfId - 1, knf_name, charsmax(knf_name))

		lena = len

		len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=%s><td>%s<td>%d<td>%d<td>%d<td>%.2f%%",
			odd ? "b" : "q",
			knf_name,
			stats[STATS_KILLS],
			stats[STATS_DEATHS],
			stats[STATS_DMG],
			effec(stats)
		)

		// LENA FIX
		if(len >= BUFF_LEN)
		{
			len = lena
			theBuffer[len] = 0

			break
		}

		odd ^= true
	}

	ArrayDestroy(knf_stats_array)

	show_motd(id,theBuffer,motd_title)

	return PLUGIN_HANDLED
}

public Sort_KnifeStats(Array:array, item1, item2)
{
	new knf_stats1[9],knf_stats2[9]
	ArrayGetArray(array,item1,knf_stats1)
	ArrayGetArray(array,item2,knf_stats2)

	if(knf_stats1[0] > knf_stats2[0])
	{
		return -1
	}
	else if(knf_stats1[0] < knf_stats2[0])
	{
		return 1
	}

	return 0
}


//
// Личная статистка за карту
//
// id - кому показывать
// stId - кого показывать
public StatsMeSay(id,player_id){
	if(!SayStatsMe){
		client_print_color(id,0,"^4[%s] ^1%L",GAME_TAG, id,"DISABLED_MSG")

		return PLUGIN_HANDLED
	}

	new len,stats[STATS_END],motd_title[64]

	formatex(motd_title,charsmax(motd_title),"%L",id,"STATS_TITLE")

	if(id != player_id){
		new name[32]
		get_user_name(player_id,name,charsmax(name))
	}

	theBuffer[0] = 0

	get_user_knfstats(player_id,0,stats)

	len += formatex(theBuffer[len],BUFF_LEN-len,"%L%L",id,"AES_META",id,"AES_STYLE")
	len += formatex(theBuffer[len],BUFF_LEN-len,"%L",id,"AES_STATS_BODY")

	len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<table cellspacing=10 cellpadding=0><tr>")

	len += formatex(theBuffer[len],BUFF_LEN-len,"<td valign=top width=20%% class=q><table cellspacing=0 width=100%%><tr><th colspan=2>%L<tr><td>%L<td>%d<tr><td>%L<td>%d<tr class=b><td>%L<td>%d<tr class=b><td>%L<td>%d<tr class=b><td>%L<td>%0.2f%%</table>",
		id,"AES_STATS_HEADER1",
		id,"AES_KILLS",stats[STATS_KILLS],
		id,"AES_DEATHS",stats[STATS_DEATHS],
		id,"AES_DMG",stats[STATS_DMG],
		id,"AES_HEAL",stats[STATS_HEAL],
		id,"AES_EFF",effec(stats))

	len += formatex(theBuffer[len],BUFF_LEN-len,"<td valign=top width=80%% class=q><table cellspacing=0 width=100%%><tr><th>%L<th>%L<th>%L<th>%L",
		id,"AES_KNIFE",
		id,"AES_KILLS",
		id,"AES_DEATHS",
		id,"AES_DMG"
	)

	new bool:odd

	new iKnivesNum = kc_get_knives_num()
	for (new knf_name[32],knfId = 1 ; knfId <= iKnivesNum && charsmax(theBuffer)-len > 0 ; knfId++)
	{
		if (get_user_knfstats(player_id, knfId, stats))
		{
			kc_knife_get_abil1_name(knfId - 1, knf_name, charsmax(knf_name))

			len += formatex(theBuffer[len],charsmax(theBuffer)-len,"<tr id=%s><td>%s<td>%d<td>%d<td>%d",
				odd ? "b" : "q",
				knf_name,
				stats[STATS_KILLS],
				stats[STATS_DEATHS],
				stats[STATS_DMG]
			)

			odd ^= true
		}
	}

	show_motd(id,theBuffer,motd_title)

	return PLUGIN_HANDLED
}

// Формирование окна /top
// В Pos указывается с какой позиции рисовать
public SayTop(id,Pos)
{
	if(!SayTop15){
		client_print_color(id,0,"^4[%s] ^1%L",GAME_TAG, id,"DISABLED_MSG")

		return PLUGIN_HANDLED
	}

	if(Pos == 15 || Pos <= 0)
		Pos = 10

	if(!get_stats_sql_thread(id,Pos,MAX_TOP,"SayTopHandler"))
	{
		client_print_color(id,print_team_red,"^4[%s] ^1%L",GAME_TAG,id,"AES_STATS_INFO1")
	}

	return PLUGIN_HANDLED
}

enum _:stats_former_array
{
	STATSF_NAME[MAX_NAME_LENGTH],
	STATSF_AUTHID[30],
	STATSF_DATA[STATS_END],
	STATSF_RANK,
	STATSF_OT,
	Float:STATSF_SKILL
}

//
// Сбор статистики
//
public SayTopHandler(id,Pos)
{
	new Array:stats_array = ArrayCreate(stats_former_array)
	new stats_info[stats_former_array],last_rank

	new size = min(get_statsnum_sql(),Pos)

	new rank,stats[STATS_END],name[MAX_NAME_LENGTH],authid[30]

	for(new i = size - MAX_TOP < 0 ? 0 : size - MAX_TOP; i < size ; i++){
		rank = get_stats_sql(i,stats,name,charsmax(name),authid,charsmax(authid))
		get_stats_gametime(i,stats_info[STATSF_OT])
		get_skill(i, stats_info[STATSF_SKILL])

		if(!rank)
			rank = last_rank

		for(new i ; i < STATS_END ; i++)
		{
			stats_info[STATSF_DATA][i] = stats[i]
		}

		copy(stats_info[STATSF_NAME],
			charsmax(stats_info[STATSF_NAME]),
			name
		)

		copy(stats_info[STATSF_AUTHID],
			charsmax(stats_info[STATSF_AUTHID]),
			authid
		)

		last_rank = rank
		stats_info[STATSF_RANK] = rank

		// формируем статистику
		ArrayPushArray(stats_array,stats_info)
	}

	new stats_data[2]

	stats_data[0] = _:stats_array

	SayTopFormer(id,stats_data)
}

public SayTopOnline(id,Pos)
{
	if(Pos == 15 || Pos <= 0)
		Pos = 10

	if(!get_stats_sql_thread(id,Pos,MAX_TOP,"SayTopOnlineHandler",CSXSQL_RANK_TIME))
	{
		client_print_color(id,print_team_red,"^4[%s] ^1%L",GAME_TAG,id,"AES_STATS_INFO1")
	}

	return PLUGIN_HANDLED
}

public SayTopOnlineHandler(id,Pos)
{
	new Array:stats_array = ArrayCreate(stats_former_array)
	new stats_info[stats_former_array],last_rank

	new size = min(get_statsnum_sql(),Pos)

	new rank,stats[STATS_END],name[MAX_NAME_LENGTH],authid[30]

	for(new i = size - MAX_TOP < 0 ? 0 : size - MAX_TOP; i < size ; i++){
		rank = get_stats_sql(i,stats,name,charsmax(name),authid,charsmax(authid))
		get_stats_gametime(i,stats_info[STATSF_OT])
		get_skill(i, stats_info[STATSF_SKILL])

		if(!rank)
			rank = last_rank

		for(new i ; i < STATS_END ; i++)
		{
			stats_info[STATSF_DATA][i] = stats[i]
		}

		copy(stats_info[STATSF_NAME],
			charsmax(stats_info[STATSF_NAME]),
			name
		)

		copy(stats_info[STATSF_AUTHID],
			charsmax(stats_info[STATSF_AUTHID]),
			authid
		)

		last_rank = rank
		stats_info[STATSF_RANK] = rank

		// формируем статистику
		ArrayPushArray(stats_array,stats_info)
	}

	new stats_data[2]

	stats_data[0] = _:stats_array

	SayOnlineFormer(id,stats_data)
}

public SayTopAssist(id,Pos)
{
	if(Pos == 15 || Pos <= 0)
		Pos = 10

	if(!get_stats_sql_thread(id,Pos,MAX_TOP,"SayTopAssistHandler",CSXSQL_RANK_ASSISTS))
	{
		client_print_color(id,print_team_red,"^4[%s] ^1%L",GAME_TAG,id,"AES_STATS_INFO1")
	}

	return PLUGIN_HANDLED
}

public SayTopAssistHandler(id,Pos)
{
	new Array:stats_array = ArrayCreate(stats_former_array)
	new stats_info[stats_former_array],last_rank

	new size = min(get_statsnum_sql(),Pos)

	new rank,stats[STATS_END],name[MAX_NAME_LENGTH],authid[30]

	for(new i = size - MAX_TOP < 0 ? 0 : size - MAX_TOP; i < size ; i++){
		rank = get_stats_sql(i,stats,name,charsmax(name),authid,charsmax(authid))
		get_stats_gametime(i,stats_info[STATSF_OT])
		get_skill(i, stats_info[STATSF_SKILL])

		if(!rank)
			rank = last_rank

		for(new i ; i < STATS_END ; i++)
		{
			stats_info[STATSF_DATA][i] = stats[i]
		}

		copy(stats_info[STATSF_NAME],
			charsmax(stats_info[STATSF_NAME]),
			name
		)

		copy(stats_info[STATSF_AUTHID],
			charsmax(stats_info[STATSF_AUTHID]),
			authid
		)

		last_rank = rank
		stats_info[STATSF_RANK] = rank

		// формируем статистику
		ArrayPushArray(stats_array,stats_info)
	}

	new stats_data[2]

	stats_data[0] = _:stats_array

	SayAssistsFormer(id,stats_data)
}

public SayAssistsFormer(id,stats_data[])
{
	theBuffer[0] = 0

	new Array:stats_array = Array:stats_data[0]

	new len,title[64]
	formatex(title,charsmax(title),"%L",id,"AES_ASSISTS_TOP")

	// заголовок
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_META")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_STYLE")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_TOP_BODY",id,"AES_ASSISTS_TOP")

	// таблица со статистикой
	new stats_info[stats_former_array],row_str[512],cell_str[MAX_NAME_LENGTH * 3],row_len
	new desc_str[10],desc_char,bool:odd

	get_pcvar_string(cvar[CVAR_MOTD_ASSISTANS_DESC],desc_str,charsmax(desc_str))
	trim(desc_str)

	new desc_length = strlen(desc_str)

	len += parse_top_desc_header(id,theBuffer,BUFF_LEN,len,false,desc_str)

	for(new stats_index,length = ArraySize(stats_array);stats_index < length; stats_index ++){
		ArrayGetArray(stats_array,stats_index,stats_info)

		for(new desc_index ; desc_index < desc_length ; desc_index++)
		{
			cell_str[0] = 0
			desc_char = desc_str[desc_index]

			switch(desc_char)
			{
				case '*':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_RANK])
				}
				case 'a':
				{
					formatex(cell_str,charsmax(cell_str),"%s",stats_info[STATSF_NAME])

					replace_all(cell_str,charsmax(cell_str),"<","&lt")
					replace_all(cell_str,charsmax(cell_str),">","&gt")
				}
				case 'b':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_KILLS])
				}
				case 'c':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_DEATHS])
				}
				case 'd':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_HEAL])
				}
				case 's':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_ASSISTS])
				}
				case 'h':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f%%",
						effec(stats_info[STATSF_DATA])
					)
				}
				case 'l':
				{
					formatex(cell_str,charsmax(cell_str),"%d",frags_to_level(stats_info[STATSF_DATA][STATS_KILLS], stats_info[STATSF_DATA][STATS_ASSISTS]))
				}
				case 'k':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f",
						kd_ratio(stats_info[STATSF_DATA])
					)
				}
				case 'n':
				{
					new ot = stats_info[STATSF_OT]
					func_format_ot(ot,cell_str,charsmax(cell_str),id)
				}
				default: continue
			}

			// выводим отформатированные данные
			row_len += formatex(row_str[row_len],charsmax(row_str)-row_len,"%L",id,"AES_BODY_CELL",cell_str)
		}

		row_len = 0

		len += formatex(theBuffer[len],charsmax(theBuffer)-len,"%L",id,"AES_BODY_ROW",odd ? " id=b" : " id=q",row_str)
		odd ^= true
	}

	ArrayDestroy(stats_array)

	show_motd(id,theBuffer,title)
}

public SayTopLevel(id,Pos)
{
	if(Pos == 15 || Pos <= 0)
		Pos = 10

	if(!get_stats_sql_thread(id,Pos,MAX_TOP,"SayTopLevelHandler",CSXSQL_RANK_LEVEL))
	{
		client_print_color(id,print_team_red,"^4[%s] ^1%L",GAME_TAG,id,"AES_STATS_INFO1")
	}

	return PLUGIN_HANDLED
}

public SayTopLevelHandler(id,Pos)
{
	new Array:stats_array = ArrayCreate(stats_former_array)
	new stats_info[stats_former_array],last_rank

	new size = min(get_statsnum_sql(),Pos)

	new rank,stats[STATS_END],name[MAX_NAME_LENGTH],authid[30]

	for(new i = size - MAX_TOP < 0 ? 0 : size - MAX_TOP; i < size ; i++){
		rank = get_stats_sql(i,stats,name,charsmax(name),authid,charsmax(authid))
		get_stats_gametime(i,stats_info[STATSF_OT])
		get_skill(i, stats_info[STATSF_SKILL])

		if(!rank)
			rank = last_rank

		for(new i ; i < STATS_END ; i++)
		{
			stats_info[STATSF_DATA][i] = stats[i]
		}

		copy(stats_info[STATSF_NAME],
			charsmax(stats_info[STATSF_NAME]),
			name
		)

		copy(stats_info[STATSF_AUTHID],
			charsmax(stats_info[STATSF_AUTHID]),
			authid
		)

		last_rank = rank
		stats_info[STATSF_RANK] = rank

		// формируем статистику
		ArrayPushArray(stats_array,stats_info)
	}

	new stats_data[2]

	stats_data[0] = _:stats_array

	SayLevelFormer(id,stats_data)
}

public SayLevelFormer(id,stats_data[])
{
	theBuffer[0] = 0

	new Array:stats_array = Array:stats_data[0]

	new len,title[64]
	formatex(title,charsmax(title),"%L",id,"AES_LEVEL_TOP")

	// заголовок
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_META")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_STYLE")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_TOP_BODY",id,"AES_LEVEL_TOP")

	// таблица со статистикой
	new stats_info[stats_former_array],row_str[512],cell_str[MAX_NAME_LENGTH * 3],row_len
	new desc_str[10],desc_char,bool:odd

	get_pcvar_string(cvar[CVAR_MOTD_LEVEL_DESC],desc_str,charsmax(desc_str))
	trim(desc_str)

	new desc_length = strlen(desc_str)

	len += parse_top_desc_header(id,theBuffer,BUFF_LEN,len,false,desc_str)

	for(new stats_index,length = ArraySize(stats_array);stats_index < length; stats_index ++){
		ArrayGetArray(stats_array,stats_index,stats_info)

		for(new desc_index ; desc_index < desc_length ; desc_index++)
		{
			cell_str[0] = 0
			desc_char = desc_str[desc_index]

			switch(desc_char)
			{
				case '*':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_RANK])
				}
				case 'a':
				{
					formatex(cell_str,charsmax(cell_str),"%s",stats_info[STATSF_NAME])

					replace_all(cell_str,charsmax(cell_str),"<","&lt")
					replace_all(cell_str,charsmax(cell_str),">","&gt")
				}
				case 'b':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_KILLS])
				}
				case 'c':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_DEATHS])
				}
				case 'd':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_HEAL])
				}
				case 's':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_ASSISTS])
				}
				case 'h':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f%%",
						effec(stats_info[STATSF_DATA])
					)
				}
				case 'l':
				{
					formatex(cell_str,charsmax(cell_str),"%d",frags_to_level(stats_info[STATSF_DATA][STATS_KILLS], stats_info[STATSF_DATA][STATS_ASSISTS]))
				}
				case 'k':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f",
						kd_ratio(stats_info[STATSF_DATA])
					)
				}
				case 'n':
				{
					new ot = stats_info[STATSF_OT]
					func_format_ot(ot,cell_str,charsmax(cell_str),id)
				}
				default: continue
			}

			// выводим отформатированные данные
			row_len += formatex(row_str[row_len],charsmax(row_str)-row_len,"%L",id,"AES_BODY_CELL",cell_str)
		}

		row_len = 0

		len += formatex(theBuffer[len],charsmax(theBuffer)-len,"%L",id,"AES_BODY_ROW",odd ? " id=b" : " id=q",row_str)
		odd ^= true
	}

	ArrayDestroy(stats_array)

	show_motd(id,theBuffer,title)
}

public SayOnlineFormer(id, stats_data[])
{
	theBuffer[0] = 0

	new Array:stats_array = Array:stats_data[0]

	new len,title[64]
	formatex(title,charsmax(title),"%L",id,"AES_ONLINE_TOP")

	// заголовок
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_META")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_STYLE")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_TOP_BODY",id,"AES_ONLINE_TOP")

	// таблица со статистикой
	new stats_info[stats_former_array],row_str[512],cell_str[MAX_NAME_LENGTH * 3],row_len
	new desc_str[10],desc_char,bool:odd

	get_pcvar_string(cvar[CVAR_MOTD_ONLINE_DESC],desc_str,charsmax(desc_str))
	trim(desc_str)

	new desc_length = strlen(desc_str)

	len += parse_top_desc_header(id,theBuffer,BUFF_LEN,len,false,desc_str)

	for(new stats_index,length = ArraySize(stats_array);stats_index < length; stats_index ++){
		ArrayGetArray(stats_array,stats_index,stats_info)

		for(new desc_index ; desc_index < desc_length ; desc_index++)
		{
			cell_str[0] = 0
			desc_char = desc_str[desc_index]

			switch(desc_char)
			{
				case '*':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_RANK])
				}
				case 'a':
				{
					formatex(cell_str,charsmax(cell_str),"%s",stats_info[STATSF_NAME])

					replace_all(cell_str,charsmax(cell_str),"<","&lt")
					replace_all(cell_str,charsmax(cell_str),">","&gt")
				}
				case 'b':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_KILLS])
				}
				case 'c':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_DEATHS])
				}
				case 'd':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_HEAL])
				}
				case 'h':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f%%",
						effec(stats_info[STATSF_DATA])
					)
				}
				case 'l':
				{
					formatex(cell_str,charsmax(cell_str),"%d",frags_to_level(stats_info[STATSF_DATA][STATS_KILLS], stats_info[STATSF_DATA][STATS_ASSISTS]))
				}
				case 'k':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f",
						kd_ratio(stats_info[STATSF_DATA])
					)
				}
				case 'n':
				{
					new ot = stats_info[STATSF_OT]
					func_format_ot(ot,cell_str,charsmax(cell_str),id)
				}
				default: continue
			}

			// выводим отформатированные данные
			row_len += formatex(row_str[row_len],charsmax(row_str)-row_len,"%L",id,"AES_BODY_CELL",cell_str)
		}

		row_len = 0

		len += formatex(theBuffer[len],charsmax(theBuffer)-len,"%L",id,"AES_BODY_ROW",odd ? " id=b" : " id=q",row_str)
		odd ^= true
	}

	ArrayDestroy(stats_array)

	show_motd(id,theBuffer,title)
}

public SayTopFormer(id,stats_data[])
{
	theBuffer[0] = 0

	new Array:stats_array = Array:stats_data[0]

	new len,title[64]
	formatex(title,charsmax(title),"%L",id,"AES_PLAYER_TOP")

	// заголовок
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_META")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_STYLE")
	len += formatex(theBuffer[len],BUFF_LEN - len,"%L",id,"AES_TOP_BODY",id,"AES_PLAYER_TOP")

	// таблица со статистикой
	new stats_info[stats_former_array],row_str[512],cell_str[MAX_NAME_LENGTH * 3],row_len
	new desc_str[10],desc_char,bool:odd

	get_pcvar_string(cvar[CVAR_MOTD_DESC],desc_str,charsmax(desc_str))
	trim(desc_str)

	new desc_length = strlen(desc_str)

	len += parse_top_desc_header(id,theBuffer,BUFF_LEN,len,false,desc_str)

	for(new stats_index,length = ArraySize(stats_array);stats_index < length; stats_index ++){
		ArrayGetArray(stats_array,stats_index,stats_info)

		for(new desc_index ; desc_index < desc_length ; desc_index++)
		{
			cell_str[0] = 0
			desc_char = desc_str[desc_index]

			switch(desc_char)
			{
				case '*':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_RANK])
				}
				case 'a':
				{
					formatex(cell_str,charsmax(cell_str),"%s",stats_info[STATSF_NAME])

					replace_all(cell_str,charsmax(cell_str),"<","&lt")
					replace_all(cell_str,charsmax(cell_str),">","&gt")
				}
				case 'b':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_KILLS])
				}
				case 'c':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_DEATHS])
				}
				case 'd':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_HEAL])
				}
				case 'f':
				{
					new knf_name[MAX_NAME_LENGTH]
					kc_knife_get_abil1_name(stats_info[STATSF_DATA][STATS_FAVKNIFE] - 1, knf_name, charsmax(knf_name))
					formatex(cell_str,charsmax(cell_str),"%s", knf_name)
				}
				case 'h':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f%%",
						effec(stats_info[STATSF_DATA])
					)
				}
				case 's':
				{
					formatex(cell_str,charsmax(cell_str),"%d",stats_info[STATSF_DATA][STATS_ASSISTS])
				}
				case 'l':
				{
					formatex(cell_str,charsmax(cell_str),"%d",frags_to_level(stats_info[STATSF_DATA][STATS_KILLS], stats_info[STATSF_DATA][STATS_ASSISTS]))
				}
				case 'k':
				{
					formatex(cell_str,charsmax(cell_str),"%.2f",
						kd_ratio(stats_info[STATSF_DATA])
					)
				}
				case 'n':
				{
					new ot = stats_info[STATSF_OT]
					func_format_ot(ot,cell_str,charsmax(cell_str),id)
				}
				case 'e': {
					formatex(cell_str,charsmax(cell_str),"%.2f", stats_info[STATSF_SKILL])
				}
				default: continue
			}

			// выводим отформатированные данные
			row_len += formatex(row_str[row_len],charsmax(row_str)-row_len,"%L",id,"AES_BODY_CELL",cell_str)
		}

		row_len = 0

		len += formatex(theBuffer[len],charsmax(theBuffer)-len,"%L",id,"AES_BODY_ROW",odd ? " id=b" : " id=q",row_str)
		odd ^= true
	}

	ArrayDestroy(stats_array)

	show_motd(id,theBuffer,title)
}

Float:effec(izStats[])
{
	if (!izStats[STATS_KILLS])
		return (0.0)

	return (100.0 * float(izStats[STATS_KILLS]) / float(izStats[STATS_KILLS] + izStats[STATS_DEATHS]))
}

Float:kd_ratio(stats[])
{
	if(!stats[STATS_DEATHS])
	{
		return float(stats[STATS_KILLS])
	}

	return float(stats[STATS_KILLS]) / float(stats[STATS_DEATHS])
}

// Формируем заголовок таблицы для топа игроков
parse_top_desc_header(id,buff[],maxlen,len,bool:isAstats,desc_str[]){
	new tmp[256],len2,theChar[4],lCnt

	lCnt = isAstats != true ? strlen(desc_str) : 0//strlen(aStatsDescCap)

	for(new i ; i < lCnt ; ++i){
		theChar[0] = isAstats != true ? desc_str[i] : desc_str[i]//aStatsDescCap[i]

		switch(theChar[0]){
			case '*':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_POS")
			}
			case 'a':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_PLAYER")
			}
			case 'b':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_KILLS")
			}
			case 'c':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_DEATHS")
			}
			case 'd':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_HEAL")
			}
			case 'f':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_FAV_KNIFE")
			}
			case 'h':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_EFF")
			}
			case 'l':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_LEVEL")
			}
			case 'k':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_KS")
			}
			case 'n':{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_TIME")
			}
			case 'p':
			{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"CSXSQL_DATE")
			}
			case 'q':
			{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"CSXSQL_MAP")
			}
			case 's':
			{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_ASSISTS")
			}
			case 'e':
			{
				len2 += formatex(tmp[len2],charsmax(tmp)-len2,"%L",id,"AES_HEADER_CELL","",id,"AES_SKILL")
			}
		}

		theChar[0] = 0
	}

	return formatex(buff[len],maxlen-len,"%L",id,"AES_TOP_HEADER_ROW",tmp)
}

// формирование меню для просмотра статистики игроков
public ShowStatsMenu(id,page){
	if(!SayStatsAll){
		client_print_color(id,0,"^4[%s] ^1%L",GAME_TAG, id,"DISABLED_MSG")

		return PLUGIN_HANDLED
	}

	new menuKeys,menuText[512],menuLen
	new tName[42],players[32],pCount

	get_players(players,pCount)

	new maxPages = ((pCount - 1) / 7) + 1 // находим макс. кол-во страниц

	// отображаем с начала, если такой страницы не существует
	if(page > maxPages)
		page = 0

	// начальный индекс игрока согласно странице
	new usrIndex = (7 * page)

	menuLen += formatex(menuText[menuLen],MENU_LEN - 1 - menuLen,"%L %L\R\y%d/%d^n",
		id,"MENU_TAG",id,"MENU_TITLE",page + 1,maxPages)

	// добавляем игроков в меню
	while(usrIndex < pCount){
		get_user_name(players[usrIndex],tName,31)
		menuKeys |= (1 << usrIndex % 7)

		menuLen += formatex(menuText[menuLen],MENU_LEN - 1 - menuLen,"^n\r%d.\w %s",
			(usrIndex % 7) + 1,tName)

		usrIndex ++

		// перываем заполнение
		// если данная страница уже заполнена
		if(!(usrIndex % 7))
			break
	}

	// вариант просмотра статистики

	switch(g_MenuStatus[id][0])
	{
		case 0: menuLen += formatex(menuText[menuLen],MENU_LEN - 1 - menuLen,"^n^n\r%d.\w %L",8,id,"MENU_RANK")
		case 1: menuLen += formatex(menuText[menuLen],MENU_LEN - 1 - menuLen,"^n^n\r%d.\w %L",8,id,"MENU_STATS")

	}

	menuKeys |= MENU_KEY_8

	if(!(usrIndex % 7)){
		menuLen += formatex(menuText[menuLen],MENU_LEN - 1 - menuLen,"^n^n\r%d.\w %L",9,id,"MORE")
		menuKeys |= MENU_KEY_9
	}

	if((7 * page)){
		menuLen += formatex(menuText[menuLen],MENU_LEN - 1 - menuLen,"^n^n\r%d.\w %L",0,id,"BACK")
		menuKeys |= MENU_KEY_0
	}else{
		menuLen += formatex(menuText[menuLen],MENU_LEN - 1 - menuLen,"^n^n\r%d.\w %L",0,id,"EXIT")
		menuKeys |= MENU_KEY_0
	}


	show_menu(id,menuKeys,menuText,-1,"Stats Menu")

	return PLUGIN_HANDLED
}

public actionStatsMenu(id,key){
	switch(key){
		case 0..6:{
			new usrIndex = key + (7 * g_MenuStatus[id][1]) + 1

			if(!is_user_connected(id)){
				ShowStatsMenu(id,g_MenuStatus[id][1])

				return PLUGIN_HANDLED
			}

			switch(g_MenuStatus[id][0])
			{
				case 0: RankStatsSay(id,usrIndex)
				case 1: StatsMeSay(id,usrIndex)
			}

			ShowStatsMenu(id,g_MenuStatus[id][1])
		}
		case 7:{
			g_MenuStatus[id][0] = (g_MenuStatus[id][0] + 1) % 2

			ShowStatsMenu(id,g_MenuStatus[id][1])
		}
		case 8:{
			g_MenuStatus[id][1] ++
			ShowStatsMenu(id,g_MenuStatus[id][1])
		}
		case 9:{
			if(g_MenuStatus[id][1]){
				g_MenuStatus[id][1] --
				ShowStatsMenu(id,g_MenuStatus[id][1])
			}
		}
	}

	return PLUGIN_HANDLED
}

frags_to_level(const iKills, const iAssists, &iNextXP = 0)
{
	new iXP = iKills + iAssists / 3
	iNextXP = g_iXPStep - iXP

	if (iXP < g_iXPStep)
		return 0

	if (g_fXPScale == 0.0)
	{
		iNextXP = g_iXPStep - (iXP % g_iXPStep)
		return iXP / g_iXPStep
	}

	new iStepIncrease = floatround(g_iXPStep * g_fXPScale)
	new Float:fInvStepIncrease = 1.0 / iStepIncrease
	new Float:fB = float(2 * g_iXPStep) * fInvStepIncrease - 1.0
	new Float:fC = -float(2 * iXP) * fInvStepIncrease
	new Float:fD = fB * fB - 4.0 * fC

	if (fD < 0.0)
		return 0

	new iLevel = floatround((-fB + floatsqroot(fD)) / 2.0, floatround_floor)
	new iBaseXP = iLevel * g_iXPStep + (iLevel * (iLevel - 1) * iStepIncrease) / 2

	if (iBaseXP > iXP)
	{
		iLevel--
		iNextXP = iBaseXP - iXP
	}
	else
	{
		iNextXP = iBaseXP + (g_iXPStep + iLevel * iStepIncrease) - iXP
	}

	return iLevel
}
