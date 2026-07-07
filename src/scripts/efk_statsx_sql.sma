/*
*	EFK StatsX SQL. Based on CSStatsX SQL
*	Original CSStatsX author: serfreeman1337	http://1337.uz/
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <sqlx>

#include <efk_core>
#include <efk_duels>

new const PLUGIN[] = "EFK: StatsX SQL"
new const AUTHOR[] = "serfreeman1337, Next21 Team"

/* - SQL - */

new Handle:sql
new Handle:sql_con

/* -  CONSTANTS - */

enum _:sql_que_type	// sql query type
{
	SQL_DUMMY,
	SQL_INITDB,
	SQL_LOAD,
	SQL_UPDATE,
	SQL_INSERT,
	SQL_UPDATERANK,		// get player ranks
	SQL_GETSTATS,		// thread request to get_stats

	SQL_GETKNFSTATS,	// knives stats
	SQL_AUTOCLEAR		// clear the database of inactive records
}

enum _:load_state_type	// getting stats status
{
	LOAD_NO,		// no data
	LOAD_WAIT,		// wait for data
	LOAD_NEWWAIT,	// new record, wait for a response
	LOAD_UPDATE,	// restart after update
	LOAD_NEW,		// new record
	LOAD_OK			// there is data
}

enum _:STATS
{
	STATS_KILLS,
	STATS_DEATHS,
	STATS_ASSISTS,
	STATS_DMG,
	STATS_HEAL,
	STATS_DUELS,

	STATS_FAVKNIFE,

	STATS_END
}

enum _:row_ids
{
	ROW_ID,
	ROW_STEAMID,
	ROW_NAME,
	ROW_IP,
	ROW_SKILL,
	ROW_KILLS,
	ROW_DEATHS,
	ROW_ASSISTS,
	ROW_DMG,
	ROW_HEAL,
	ROW_DUELS,
	ROW_ONLINETIME,

	ROW_FAVKNIFE,

	ROW_FIRSTJOIN,
	ROW_LASTJOIN
}

new const row_names[row_ids][] =
{
	"id",
	"steamid",
	"name",
	"ip",
	"skill",
	"kills",
	"deaths",
	"assists",
	"dmg",
	"heal",
	"duels",
	"connection_time",

	"favknife",

	"first_join",
	"last_join"
}

enum _:
{
	CSXSQL_RANK_DEF,
	CSXSQL_RANK_K,
	CSXSQL_RANK_SKILL,
	CSXSQL_RANK_TIME,
	CSXSQL_RANK_LEVEL,
	CSXSQL_RANK_ASSISTS
}

const QUERY_LENGTH =	1472

new const task_rankupdate	=	31337
new const task_confin		=	21337
new const task_flush		=	11337

enum _:row_knives_ids
{
	ROW_KNIFE_ID,
	ROW_KNIFE_PLAYER,
	ROW_KNIFE_NAME,
	ROW_KNIFE_KILLS,
	ROW_KNIFE_DEATHS,
	ROW_KNIFE_ASSISTS,
	ROW_KNIFE_DMG,
	ROW_KNIFE_HEAL
}

new const row_knives_names[row_knives_ids][] =
{
	"id",
	"player_id",
	"knife",
	"kills",
	"deaths",
	"assists",
	"dmg",
	"heal"
}

enum _:player_data_struct
{
	PLAYER_ID,						// player ID in DB
	PLAYER_LOADSTATE,
	PLAYER_RANK,
	PLAYER_STATS[STATS_END],		// player stats
	PLAYER_STATSLAST[STATS_END],	// player diff stats
	Float:PLAYER_SKILL,
	PLAYER_ONLINE,					// connection time
	Float:PLAYER_SKILLLAST,
	PLAYER_ONLINEDIFF,
	PLAYER_ONLINELAST,

	PLAYER_NAME[MAX_NAME_LENGTH * 3],
	PLAYER_STEAMID[30],
	PLAYER_IP[16],

	PLAYER_FIRSTJOIN,
	PLAYER_LASTJOIN
}

enum _:stats_cache_struct	// cache for get_stats
{
	CACHE_NAME[32],
	CACHE_STEAMID[30],
	CACHE_STATS[STATS_END],
	CACHE_SKILL,
	bool:CACHE_LAST,

	CACHE_ID,
	CACHE_TIME,

	CACHE_FIRSTJOIN,
	CACHE_LASTJOIN
}

enum _:cvar_set
{
	CVAR_SQL_HOST,
	CVAR_SQL_USER,
	CVAR_SQL_PASS,
	CVAR_SQL_DB,
	CVAR_SQL_TABLE,
	CVAR_SQL_TYPE,
	CVAR_SQL_CREATE_DB,

	CVAR_UPDATESTYLE,
	CVAR_RANKFORMULA,
	CVAR_RANKBOTS,

	CVAR_KNIFESTATS,

	CVAR_AUTOCLEAR,
	CVAR_CACHETIME,
	CVAR_AUTOCLEAR_DAY
}

enum _:stats_cache_queue_struct
{
	CACHE_QUE_START,
	CACHE_QUE_TOP,
}

#define	MAX_DATA_PARAMS	32

/* - VARS - */

new player_data[MAX_PLAYERS + 1][player_data_struct]
new flush_que[QUERY_LENGTH * 3],flush_que_len
new statsnum

//
// Common knives stats
//
// 1st STATS_END - current common knives stats
// 2nd STATS_END - last player_knfstats for diff calculation
// last index - INSERT or UPDATE for request
//
new player_aknfstats[MAX_PLAYERS + 1][MAX_KNIVES + 1][((STATS_END) * 2) + 1]

new cvar[cvar_set]

new Trie:stats_cache_trie	// cache trie for get_stats // key - rank

new tbl_name[32]

/* - EFKSTATS CORE - */

 #pragma dynamic 32768

new player_knfstats[MAX_PLAYERS + 1][MAX_KNIVES + 1][STATS_END]

new FW_Initialized, FW_StatsLoaded

new Trie:knives_names_map			// tree for quickly determining the knife ID by name

new Array:stats_cache_queue
new bool:knife_stats_enabled

new init_seq = -1
new bool:is_ready = false

new HamHook:g_pHamTakeDamagePost
new g_iHealthDiff


public plugin_precache()
{
	register_plugin(PLUGIN, EFK_VERSION, AUTHOR)
	register_cvar("efk_statsx_sql", EFK_VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED)

	/*
	* mysql host
	*/
	cvar[CVAR_SQL_HOST] = register_cvar("efk_statsx_host","localhost",FCVAR_UNLOGGED|FCVAR_PROTECTED)

	/*
	* mysql user
	*/
	cvar[CVAR_SQL_USER] = register_cvar("efk_statsx_user","root",FCVAR_UNLOGGED|FCVAR_PROTECTED)

	/*
	* mysql password
	*/
	cvar[CVAR_SQL_PASS] = register_cvar("efk_statsx_pass","",FCVAR_UNLOGGED|FCVAR_PROTECTED)

	/*
	* mysql or sqlite DB name
	*/
	cvar[CVAR_SQL_DB] = register_cvar("efk_statsx_db","amxx",FCVAR_UNLOGGED|FCVAR_PROTECTED)

	/*
	* table name in DB
	*/
	cvar[CVAR_SQL_TABLE] = register_cvar("efk_statsx_table","efkstats",FCVAR_UNLOGGED|FCVAR_PROTECTED)

	/*
	* DB type
	*	mysql - MySQL
	*	sqlite - local SQLite
	*/
	cvar[CVAR_SQL_TYPE] = register_cvar("efk_statsx_type","sqlite")

	/*
	* send a request to create a table
	*	0 - do not send a request
	*	1 - send a request after loading the map
	*/
	cvar[CVAR_SQL_CREATE_DB] = register_cvar("efk_statsx_create_db","1")

	/*
	* record stats for bots
	*	0			- do not record
	*	1			- record
	*/
	cvar[CVAR_RANKBOTS] = register_cvar("efk_statsx_rankbots","0")

	/*
	* how to update player stats in the DB
	*	-2 			- at death and disconnect
	*	-1			- at the round end and disconnect
	*	0 			- at disconnect
	*	> 0 		- at the specified number of seconds and disconnect
	*/
	cvar[CVAR_UPDATESTYLE] = register_cvar("efk_statsx_update","-1")

	/*
	* formula for calculating the rank
	*	0			- kills - deaths
	*	1			- kills
	*	2			- skill
	*	3			- online time
	*	4			- kills + assists / 3
	*	5			- assists
	*/
	cvar[CVAR_RANKFORMULA] = register_cvar("efk_statsx_rankformula","4")

	/*
	* enable knives stats
	*/
	cvar[CVAR_KNIFESTATS] = register_cvar("efk_statsx_knives","1")

	/*
	* automatic cleaning of inactive players in the DB
	*/
	cvar[CVAR_AUTOCLEAR] = register_cvar("efk_statsx_autoclear","0")

	/*
	* use the cache for get_stats
	*	-1 - update at the end of the round or at the time of csstats_sql_update
	*	0 - disable cache
	*/
	cvar[CVAR_CACHETIME] = register_cvar("efk_statsx_cachetime","-1")

	/*
	* automatic cleaning of all game stats in the DB on a specific day
	*/
	cvar[CVAR_AUTOCLEAR_DAY] = register_cvar("efk_statsx_autoclear_day","0")
}

public plugin_init()
{
	register_logevent("LogEventHooK_RoundEnd", 2, "1=Round_End")

	register_srvcmd("efk_statsx_reset","SrvCmd_DBReset")

	knives_names_map = TrieCreate()

	new iKnivesNum = kc_get_knives_num()
	for (new iKnifeId, knf_name[MAX_NAME_LENGTH]; iKnifeId < iKnivesNum; iKnifeId++)
	{
		if (kc_knife_get_abil1_name(iKnifeId, knf_name, charsmax(knf_name)))
			TrieSetCell(knives_names_map, knf_name, iKnifeId + 1)
	}

	RegisterHam(Ham_TakeDamage, "player", "HamHook_PlayerDamage_Pre", false)
	DisableHamForward(g_pHamTakeDamagePost = RegisterHam(Ham_TakeDamage, "player", "HamHook_PlayerDamage_Post", true))
}

public OnAutoConfigsBuffered()
{
	new host[128],user[64],pass[64],db[64],type[10]
	get_pcvar_string(cvar[CVAR_SQL_HOST],host,charsmax(host))
	get_pcvar_string(cvar[CVAR_SQL_USER],user,charsmax(user))
	get_pcvar_string(cvar[CVAR_SQL_PASS],pass,charsmax(pass))
	get_pcvar_string(cvar[CVAR_SQL_DB],db,charsmax(db))
	get_pcvar_string(cvar[CVAR_SQL_TABLE],tbl_name,charsmax(tbl_name))
	get_pcvar_string(cvar[CVAR_SQL_TYPE],type,charsmax(type))

	if(!SQL_SetAffinity(type))
	{
		new error_msg[128]
		formatex(error_msg,charsmax(error_msg),"failed to use ^"%s^" for db driver",
			error_msg)

		set_fail_state(error_msg)

		return
	}

	sql = SQL_MakeDbTuple(host,user,pass,db)

	SQL_SetCharset(sql,"utf8")

	knife_stats_enabled = get_pcvar_num(cvar[CVAR_KNIFESTATS]) != 0

	new query[QUERY_LENGTH * 2],que_len

	new sql_data[1]
	sql_data[0] = SQL_INITDB

	// request to create a table
	if(get_pcvar_num(cvar[CVAR_SQL_CREATE_DB]))
	{
		if(strcmp(type,"mysql") == 0)
		{
			que_len += formatex(query[que_len],charsmax(query) - que_len,"\
				CREATE TABLE IF NOT EXISTS `%s` (\
					`%s` int(11) NOT NULL AUTO_INCREMENT,\
					`%s` varchar(30) NOT NULL,\
					`%s` varchar(32) NOT NULL,\
					`%s` varchar(16) NOT NULL,\
					`%s` float NOT NULL DEFAULT '0.0',\
					`%s` int(11) NOT NULL DEFAULT '0',\
					`%s` int(11) NOT NULL DEFAULT '0',\
					`%s` int(11) NOT NULL DEFAULT '0',",

					tbl_name,

					row_names[ROW_ID],
					row_names[ROW_STEAMID],
					row_names[ROW_NAME],
					row_names[ROW_IP],
					row_names[ROW_SKILL],
					row_names[ROW_KILLS],
					row_names[ROW_DEATHS],
					row_names[ROW_ASSISTS]
			)

			que_len += formatex(query[que_len],charsmax(query) - que_len,"`%s` int(11) NOT NULL DEFAULT '0',\
					`%s` int(11) NOT NULL DEFAULT '0',\
					`%s` int(11) NOT NULL DEFAULT '0',\
					`%s` int(11) NOT NULL DEFAULT '0',\
					`%s` int(11) NOT NULL DEFAULT '0',",

					row_names[ROW_DMG],
					row_names[ROW_HEAL],
					row_names[ROW_DUELS],
					row_names[ROW_ONLINETIME],
					row_names[ROW_FAVKNIFE]
			)

			que_len += formatex(query[que_len],charsmax(query) - que_len,"`%s` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,\
				`%s` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,\
					PRIMARY KEY (%s),\
					KEY `%s` (`%s`(16)),\
					KEY `%s` (`%s`(16)),\
					KEY `%s` (`%s`)\
				) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;",

				row_names[ROW_FIRSTJOIN],
				row_names[ROW_LASTJOIN],

				row_names[ROW_ID],
				row_names[ROW_STEAMID],row_names[ROW_STEAMID],
				row_names[ROW_NAME],row_names[ROW_NAME],
				row_names[ROW_IP],row_names[ROW_IP]
			)
		}
		else if(strcmp(type,"sqlite") == 0)
		{
			que_len += formatex(query[que_len],charsmax(query) - que_len,"\
				CREATE TABLE IF NOT EXISTS `%s` (\
					`%s` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,\
					`%s`	TEXT NOT NULL,\
					`%s`	TEXT NOT NULL,\
					`%s`	TEXT NOT NULL,\
					`%s`	REAL NOT NULL DEFAULT 0.0,\
					`%s`	INTEGER NOT NULL DEFAULT 0,\
					`%s`	INTEGER NOT NULL DEFAULT 0,\
					`%s`	INTEGER NOT NULL DEFAULT 0,",

					tbl_name,

					row_names[ROW_ID],
					row_names[ROW_STEAMID],
					row_names[ROW_NAME],
					row_names[ROW_IP],
					row_names[ROW_SKILL],
					row_names[ROW_KILLS],
					row_names[ROW_DEATHS],
					row_names[ROW_ASSISTS]
			)

			que_len += formatex(query[que_len],charsmax(query) - que_len,"`%s`	INTEGER NOT NULL DEFAULT 0,\
					`%s`	INTEGER NOT NULL DEFAULT 0,\
					`%s`	INTEGER NOT NULL DEFAULT 0,\
					`%s`	INTEGER NOT NULL DEFAULT 0,\
					`%s`	INTEGER NOT NULL DEFAULT 0,",

					row_names[ROW_DMG],
					row_names[ROW_HEAL],
					row_names[ROW_DUELS],
					row_names[ROW_ONLINETIME],
					row_names[ROW_FAVKNIFE]
			)

			que_len += formatex(query[que_len],charsmax(query) - que_len,"`%s`	TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,\
					`%s`	TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);",

				row_names[ROW_FIRSTJOIN],
				row_names[ROW_LASTJOIN]
			)
		}
		else
		{
			set_fail_state("invalid ^"csstats_sql_type^" cvar value")
		}

		DB_AddInitSeq()
		SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data)

		if(knife_stats_enabled)
		{
			que_len = 0

			if(strcmp(type,"mysql") == 0)
			{
				que_len += formatex(query[que_len],charsmax(query) - que_len,"\
					CREATE TABLE IF NOT EXISTS `%s_knives` (\
						`%s` int(11) NOT NULL AUTO_INCREMENT,\
						`%s` int(11) NOT NULL,\
						`%s` varchar(32) NOT NULL,\
						`%s` int(11) NOT NULL DEFAULT '0',\
						`%s` int(11) NOT NULL DEFAULT '0',\
						`%s` int(11) NOT NULL DEFAULT '0',",

						tbl_name,
						row_knives_names[ROW_KNIFE_ID],
						row_knives_names[ROW_KNIFE_PLAYER],
						row_knives_names[ROW_KNIFE_NAME],
						row_knives_names[ROW_KNIFE_KILLS],
						row_knives_names[ROW_KNIFE_DEATHS],
						row_knives_names[ROW_KNIFE_ASSISTS]
				)
				que_len += formatex(query[que_len],charsmax(query) - que_len,"`%s` int(11) NOT NULL DEFAULT '0',\
						`%s` int(11) NOT NULL DEFAULT '0',",

						row_knives_names[ROW_KNIFE_DMG],
						row_knives_names[ROW_KNIFE_HEAL]
				)
				que_len += formatex(query[que_len],charsmax(query) - que_len,"\
						PRIMARY KEY (%s),\
						KEY `%s` (`%s`(16))\
					) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;",

					row_knives_names[ROW_KNIFE_ID],
					row_knives_names[ROW_KNIFE_NAME],
					row_knives_names[ROW_KNIFE_NAME]
				)
			}
			else if(strcmp(type,"sqlite") == 0)
			{
				que_len += formatex(query[que_len],charsmax(query) - que_len,"\
					CREATE TABLE IF NOT EXISTS `%s_knives` (\
						`%s` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,\
						`%s`	INTEGER NOT NULL,\
						`%s`	TEXT NOT NULL,\
						`%s`	INTEGER NOT NULL DEFAULT 0,\
						`%s`	INTEGER NOT NULL DEFAULT 0,\
						`%s`	INTEGER NOT NULL DEFAULT 0,",

						tbl_name,
						row_knives_names[ROW_KNIFE_ID],
						row_knives_names[ROW_KNIFE_PLAYER],
						row_knives_names[ROW_KNIFE_NAME],
						row_knives_names[ROW_KNIFE_KILLS],
						row_knives_names[ROW_KNIFE_DEATHS],
						row_knives_names[ROW_KNIFE_ASSISTS]
				)
				que_len += formatex(query[que_len],charsmax(query) - que_len,"`%s`	INTEGER NOT NULL DEFAULT 0,\
						`%s`	INTEGER NOT NULL DEFAULT 0",

						row_knives_names[ROW_KNIFE_DMG],
						row_knives_names[ROW_KNIFE_HEAL]
				)
				que_len += formatex(query[que_len],charsmax(query) - que_len,");")
			}
			else
			{
				set_fail_state("invalid ^"csstats_sql_type^" cvar value")
			}

			if(que_len)
			{
				DB_AddInitSeq()
				SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data)
			}
		}
	}

	DB_AutoClearOpt()

	// stats update in the DB every n seconds
	if(get_pcvar_num(cvar[CVAR_UPDATESTYLE]) > 0)
	{
		set_task(
			float(get_pcvar_num(cvar[CVAR_UPDATESTYLE])),
			"DB_SaveAll",
			.flags = "b"
		)
	}

	FW_Initialized = CreateMultiForward("csxsql_initialized", ET_IGNORE)
	FW_StatsLoaded = CreateMultiForward("csxsql_stats_loaded", ET_IGNORE, FP_CELL)

	if(
		(get_pcvar_num(cvar[CVAR_UPDATESTYLE]) == -2) ||
		(get_pcvar_num(cvar[CVAR_UPDATESTYLE]) == 0)
	)
	{
		set_pcvar_num(cvar[CVAR_CACHETIME],0)
	}

	DB_InitSeq()
}

//
// Sequence before starting the plugin
//
DB_AddInitSeq()
{
	init_seq --
}

//
// Check the sequence initialization before execution
//
DB_InitSeq()
{
	if(init_seq ==0)
	{
		log_amx("!?!?!?!?!?")
		return
	}

	init_seq ++

	if(init_seq == 0)
	{
		ExecuteForward(FW_Initialized)
	}
}

//
// Clear DB of inactive players
//
DB_AutoClearOpt()
{
	new autoclear_days = get_pcvar_num(cvar[CVAR_AUTOCLEAR])

	if(autoclear_days > 0)
	{
		DB_ClearTables(autoclear_days)
	}

	autoclear_days = get_pcvar_num(cvar[CVAR_AUTOCLEAR_DAY])

	if(autoclear_days > 0)
	{
		  new s_data[10]
		  get_time("%d",s_data,charsmax(s_data))

		  if(str_to_num(s_data) == autoclear_days)
		  {
		  	s_data[0] = 0
		  	get_vaultdata("csxsql_clear",s_data,charsmax(s_data))

			if(!str_to_num(s_data))
			{
				set_vaultdata("csxsql_clear","1")
				DB_ClearTables(-1)
			}
		  }
		  else
		  {
		  	set_vaultdata("csxsql_clear","0")
		  }
	}
}

//
// Getting started with the DB
//
public csxsql_initialized()
{
	is_ready = true

	new players[MAX_PLAYERS],pnum
	get_players(players,pnum)

	for(new i ; i < pnum ; i++)
	{
		client_putinserver(players[i])
	}
}

public SrvCmd_DBReset()
{
	DB_ClearTables(-1)
}

//
// Clear tables of inactive records
//
DB_ClearTables(by_days)
{
	if(by_days == -1)
	{
		log_amx("database reset")
	}

	new query[QUERY_LENGTH],que_len

	new type[10]
	get_pcvar_string(cvar[CVAR_SQL_TYPE],type,charsmax(type))

	if(strcmp(type,"mysql") == 0)
	{
		que_len += formatex(query[que_len],charsmax(query) - que_len,"DELETE `%s`",
			tbl_name
		)

		if(knife_stats_enabled)
		{
			que_len += formatex(query[que_len],charsmax(query) - que_len,",`%s_knives`",tbl_name)
		}

		que_len += formatex(query[que_len],charsmax(query) - que_len," FROM `%s`",
			tbl_name
		)

		if(knife_stats_enabled)
		{
			que_len += formatex(query[que_len],charsmax(query) - que_len,"\
				LEFT JOIN `%s_knives` ON `%s`.`%s` = `%s_knives`.`%s`",
				tbl_name,
				tbl_name,row_names[ROW_ID],
				tbl_name,row_knives_names[ROW_KNIFE_PLAYER]
			)
		}

		if(by_days > 0)
		{
			que_len += formatex(query[que_len],charsmax(query) - que_len,"WHERE `%s`.`%s` <= DATE_SUB(NOW(),INTERVAL %d DAY) OR (`%s`.`%s` <= DATE_SUB(NOW(),INTERVAL 7 DAY) AND `%s`.`%s` = 0 AND `%s`.`%s` = 0);",
				tbl_name,row_names[ROW_LASTJOIN],by_days,tbl_name,row_names[ROW_LASTJOIN],tbl_name,row_names[ROW_KILLS],tbl_name,row_names[ROW_DEATHS]
			)
		}
		else
		{
			que_len += formatex(query[que_len],charsmax(query) - que_len,"WHERE 1")
		}
	}
	else if(strcmp(type,"sqlite") == 0)
	{
		if(knife_stats_enabled)
		{
			if(by_days > 0)
			{
				que_len += formatex(query[que_len],charsmax(query) - que_len,"\
						DELETE FROM `%s_knives` WHERE `%s` IN (\
							SELECT `%s` FROM `%s` WHERE `%s` <= DATETIME('now','-%d day')\
						);",
						tbl_name,row_knives_names[ROW_KNIFE_PLAYER],
						row_names[ROW_ID],tbl_name,row_names[ROW_LASTJOIN],
						by_days
				)
			}
			else
			{
				que_len += formatex(query[que_len],charsmax(query) - que_len,"\
						DELETE FROM `%s_knives` WHERE `%s` IN (\
							SELECT `%s` FROM `%s` WHERE 1\
						);",
						tbl_name,row_knives_names[ROW_KNIFE_PLAYER],
						row_names[ROW_ID],tbl_name
					)
			}
		}

		if(by_days > 0)
		{
			que_len += formatex(query[que_len],charsmax(query) - que_len,"\
					DELETE FROM `%s` WHERE `%s` <= DATETIME('now','-%d day');",
					tbl_name,row_names[ROW_LASTJOIN],by_days
			)
		}
		else
		{
			que_len += formatex(query[que_len],charsmax(query) - que_len,"\
					DELETE FROM `%s` WHERE 1;",tbl_name
			)
		}
	}

	new sql_data[1]
	sql_data[0] = SQL_AUTOCLEAR

	DB_AddInitSeq()
	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data)
}

public plugin_end()
{
	DB_FlushQuery()

	SQL_FreeHandle(sql)

	if(sql_con != Empty_Handle)
	{
		SQL_FreeHandle(sql_con)
	}
}

public client_putinserver(id)
{
	if(!is_ready)
	{
		return PLUGIN_CONTINUE
	}

	reset_user_allstats(id)

	arrayset(player_data[id],0,player_data_struct)

	for(new knf ; knf <= MAX_KNIVES ; knf ++)
	{
		arrayset(player_aknfstats[id][knf],0,sizeof player_aknfstats[][])
	}

	DB_LoadPlayerData(id)

	return PLUGIN_CONTINUE
}

public client_disconnected(id)
{
	DB_SavePlayerData(id)
	player_data[id][PLAYER_LOADSTATE] = LOAD_NO
}

public HamHook_PlayerDamage_Pre(victim, inflictor, attacker, Float:damage, bits)
{
	if (GetHamReturnStatus() != HAM_SUPERCEDE)
	{
		g_iHealthDiff = pev(victim, pev_health)
		EnableHamForward(g_pHamTakeDamagePost)
	}
}

public HamHook_PlayerDamage_Post(victim, inflictor, attacker, Float:damage, bits)
{
	DisableHamForward(g_pHamTakeDamagePost)
	new iHealth = pev(victim, pev_health)
	if (iHealth > 0) g_iHealthDiff -= iHealth

	if (is_user_connected(attacker) && attacker != victim)
		Stats_SaveHit(attacker, g_iHealthDiff)
}

bool:Stats_SaveAssist(player)
{
	new knf_id = kc_player_get_knife(player) + 1

	player_knfstats[player][0][STATS_ASSISTS] ++
	player_knfstats[player][knf_id][STATS_ASSISTS] ++

	return true
}

bool:Stats_SaveHit(attacker, damage)
{
	player_knfstats[attacker][0][STATS_DMG] += damage

	new iKnifeId = kc_player_get_knife(attacker)

	player_knfstats[attacker][iKnifeId + 1][STATS_DMG] += damage

	new knife_name[MAX_NAME_LENGTH]
	kc_knife_get_abil1_name(iKnifeId, knife_name, charsmax(knife_name))

	return true
}

public efk_player_death(iVictim, iAttacker, iAssistant)
{
	if (iAttacker < 1 || iAttacker == iVictim || iAttacker > MaxClients)
		return

	new attacker_knf_id = kc_player_get_knife(iAttacker) + 1

	player_knfstats[iAttacker][0][STATS_KILLS] ++
	player_knfstats[iAttacker][attacker_knf_id][STATS_KILLS] ++

	player_knfstats[iVictim][0][STATS_DEATHS] ++

	if (iAssistant)
		Stats_SaveAssist(iAssistant)

	new victim_knf_id = kc_player_get_knife(iVictim) + 1

	player_knfstats[iVictim][victim_knf_id][STATS_DEATHS] ++

	calculate_players_skill_by_elo(iVictim, iAttacker)

	if(get_pcvar_num(cvar[CVAR_UPDATESTYLE]) == -2)
	{
		DB_SavePlayerData(iVictim)
	}

	return
}

public efk_player_heal(iPlayer, iHealer, Float:fHealth)
{
	if (iHealer < 1 || iHealer == iPlayer || iHealer > MaxClients)
		return

	new knf_id = kc_player_get_knife(iHealer) + 1
	new heal = floatround(fHealth)

	player_knfstats[iHealer][0][STATS_HEAL] += heal
	player_knfstats[iHealer][knf_id][STATS_HEAL] += heal
}

public efk_indirect_assist(iVictim, iAttacker, iAssistant)
{
	Stats_SaveAssist(iAssistant)
}

public efk_duel_win(iWinner, iLooser)
{
	player_knfstats[iWinner][0][STATS_DUELS] ++
}

calculate_players_skill_by_elo(victim, killer)
{
	new Float:delta =
		1.0 / (1.0 + floatpower(10.0, (player_data[killer][PLAYER_SKILL] - player_data[victim][PLAYER_SKILL]) / 100.0))

	new Float:coeff = 1.0;

	player_data[killer][PLAYER_SKILL] += delta * coeff

	if(	player_data[killer][PLAYER_ONLINE] >= 3600
		&& player_data[killer][PLAYER_STATS][STATS_KILLS] >= 50
	) {
		player_data[victim][PLAYER_SKILL] -= delta * coeff
	}
}

public client_infochanged(id)
{
	new cur_name[MAX_NAME_LENGTH],new_name[MAX_NAME_LENGTH]
	get_user_name(id,cur_name,charsmax(cur_name))
	get_user_info(id,"name",new_name,charsmax(new_name))

	if(strcmp(cur_name,new_name) != 0)
	{
		copy(player_data[id][PLAYER_NAME],charsmax(player_data[][PLAYER_NAME]),new_name)
		mysql_escape_string(player_data[id][PLAYER_NAME],charsmax(player_data[][PLAYER_NAME]))
	}
}

public LogEventHooK_RoundEnd()
{
	if(get_pcvar_num(cvar[CVAR_UPDATESTYLE]) == -1)
	{
		DB_SaveAll()
	}
}

//
// Load player stats from the DB
//
bool:DB_LoadPlayerData(id)
{
	if(is_user_hltv(id))
	{
		return false
	}

	if(is_user_bot(id) && !get_pcvar_num(cvar[CVAR_RANKBOTS]))
	{
		return false
	}

	get_user_info(id,"name",player_data[id][PLAYER_NAME],charsmax(player_data[][PLAYER_NAME]))
	mysql_escape_string(player_data[id][PLAYER_NAME],charsmax(player_data[][PLAYER_NAME]))

	get_user_authid(id,player_data[id][PLAYER_STEAMID],charsmax(player_data[][PLAYER_STEAMID]))
	get_user_ip(id,player_data[id][PLAYER_IP],charsmax(player_data[][PLAYER_IP]),true)

	new query[QUERY_LENGTH],len,sql_data[2]

	sql_data[0] = SQL_LOAD
	sql_data[1] = id
	player_data[id][PLAYER_LOADSTATE] = LOAD_WAIT

	len += formatex(query[len],charsmax(query)-len,"SELECT *,(")
	len += DB_QueryBuildScore(query[len],charsmax(query)-len)
	len += formatex(query[len],charsmax(query)-len,"),(")
	len += DB_QueryBuildStatsnum(query[len],charsmax(query)-len)
	len += formatex(query[len],charsmax(query)-len,")")

	len += formatex(query[len],charsmax(query)-len," FROM `%s` AS `a` WHERE `steamid` = '%s'",
		tbl_name,player_data[id][PLAYER_STEAMID]
	)

	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data)

	return true
}

//
// Load knives stats from the DB
//
bool:DB_LoadPlayerKnfstats(id)
{
	if(!player_data[id][PLAYER_ID])
	{
		return false
	}

	new query[QUERY_LENGTH],sql_data[2]

	sql_data[0] = SQL_GETKNFSTATS
	sql_data[1] = id

	formatex(query,charsmax(query),"SELECT * FROM `%s_knives` WHERE `player_id` = '%d'",
		tbl_name,player_data[id][PLAYER_ID]
	)

	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data)

	return true

}

find_fav_knife(id)
{
	new fav_knife_id = 1, knife_frags,
	fav_knife_frags = player_knfstats[id][1][STATS_KILLS] + player_aknfstats[id][1][STATS_KILLS]

	for (new iKnf = 2; iKnf <= MAX_KNIVES; iKnf++)
	{
		knife_frags = player_knfstats[id][iKnf][STATS_KILLS] + player_aknfstats[id][iKnf][STATS_KILLS]
		if (knife_frags > fav_knife_frags)
		{
			fav_knife_frags = knife_frags
			fav_knife_id = iKnf
		}
	}

	return fav_knife_id
}

//
// Save player stats to the DB
//
bool:DB_SavePlayerData(id,bool:reload = false)
{
	if(player_data[id][PLAYER_LOADSTATE] < LOAD_NEW)
	{
		return false
	}

	new query[QUERY_LENGTH],i,len
	new sql_data[2]

	sql_data[1] = id

	new stats[STATS_END]
	get_user_knfstats(id,0,stats)

	stats[STATS_FAVKNIFE] = find_fav_knife(id)

	switch(player_data[id][PLAYER_LOADSTATE])
	{
		case LOAD_OK: // update
		{
			if(reload)
			{
				player_data[id][PLAYER_LOADSTATE] = LOAD_UPDATE
			}

			sql_data[0] = SQL_UPDATE

			new diffstats[sizeof player_data[][PLAYER_STATS]]
			new to_save

			len += formatex(query[len],charsmax(query) - len,"UPDATE `%s` SET",tbl_name)

			// update based on the difference with the previous data
			for(i = 0 ; i < sizeof player_data[][PLAYER_STATS] ; i++)
			{
				if (i == STATS_FAVKNIFE)
				{
					if (player_data[id][PLAYER_STATSLAST][i] != stats[i])
					{
						len += formatex(query[len],charsmax(query) - len,"%s`%s` = %d",
							to_save ? "," : " ",
							row_names[ROW_FAVKNIFE],
							stats[STATS_FAVKNIFE]
						)

						to_save ++

						player_data[id][PLAYER_STATSLAST][STATS_FAVKNIFE] = stats[STATS_FAVKNIFE]
						player_data[id][PLAYER_STATS][STATS_FAVKNIFE] = stats[STATS_FAVKNIFE]
					}
					continue
				}

				diffstats[i] = stats[i] - player_data[id][PLAYER_STATSLAST][i]
				player_data[id][PLAYER_STATSLAST][i] = stats[i]

				if(diffstats[i])
				{
					len += formatex(query[len],charsmax(query) - len,"%s`%s` = `%s` + %d",
						to_save ? "," : " ",
						row_names[i + ROW_KILLS],
						row_names[i + ROW_KILLS],
						diffstats[i]
					)

					to_save ++
				}
			}

			new Float:diffskill = player_data[id][PLAYER_SKILL] - player_data[id][PLAYER_SKILLLAST]
			player_data[id][PLAYER_SKILLLAST] = _:player_data[id][PLAYER_SKILL]

			if(diffskill != 0.0)
			{
				len += formatex(query[len],charsmax(query) - len,"%s`%s` = `%s` + %.2f",
					to_save ? "," : " ",
					row_names[ROW_SKILL],
					row_names[ROW_SKILL],
					diffskill
				)

				to_save ++
			}

			player_data[id][PLAYER_ONLINE] += get_user_time(id) - player_data[id][PLAYER_ONLINEDIFF]
			player_data[id][PLAYER_ONLINEDIFF] = get_user_time(id)

			new diffonline = player_data[id][PLAYER_ONLINE] - player_data[id][PLAYER_ONLINELAST]
			player_data[id][PLAYER_ONLINELAST] = player_data[id][PLAYER_ONLINE]

			if(diffonline)
			{
				len += formatex(query[len],charsmax(query) - len,"%s`%s` = `%s` + %d",
					to_save ? "," : " ",
					row_names[ROW_ONLINETIME],
					row_names[ROW_ONLINETIME],
					diffonline
				)

				to_save ++
			}

			// update the last connection time, nickname, IP and steamid
			len += formatex(query[len],charsmax(query) - len,",\
				`last_join` = CURRENT_TIMESTAMP,\
				`%s` = '%s',\
				`%s` = '%s'",


				row_names[ROW_STEAMID],player_data[id][PLAYER_STEAMID],
				row_names[ROW_IP],player_data[id][PLAYER_IP],

				row_names[ROW_ID],player_data[id][PLAYER_ID]
			)

			if(!reload) // do not update the nickname when it is changed
			{
				len += formatex(query[len],charsmax(query) - len,",`%s` = '%s'",
					row_names[ROW_NAME],player_data[id][PLAYER_NAME]
				)
			}

			len += formatex(query[len],charsmax(query) - len,"WHERE `%s` = '%d'",row_names[ROW_ID],player_data[id][PLAYER_ID])

			if(to_save <= 0)
			{
				if(player_data[id][PLAYER_LOADSTATE] == LOAD_UPDATE)
				{
					player_data[id][PLAYER_LOADSTATE] = LOAD_NO
					DB_LoadPlayerData(id)
				}

				return false
			}
			else
			{
				for(new i ; i < sizeof player_data[][PLAYER_STATS] ; i++)
				{
					player_data[id][PLAYER_STATS][i] += diffstats[i]
				}
			}
		}
		case LOAD_NEW: // insert
		{
			sql_data[0] = SQL_INSERT

			new Float:skill = 100.0

			formatex(query,charsmax(query),"INSERT INTO `%s` \
							(`%s`,`%s`,`%s`,`%s`,`%s`,`%s`,`%s`,`%s`,`%s`,`%s`,`%s`,`%s`)\
							VALUES('%s','%s','%s','%.2f','%d','%d','%d','%d','%d','%d','%d',CURRENT_TIMESTAMP)\
							",tbl_name,

					row_names[ROW_STEAMID],
					row_names[ROW_NAME],
					row_names[ROW_IP],
					row_names[ROW_SKILL],
					row_names[ROW_KILLS],
					row_names[ROW_DEATHS],
					row_names[ROW_ASSISTS],
					row_names[ROW_FAVKNIFE],
					row_names[ROW_DMG],
					row_names[ROW_HEAL],
					row_names[ROW_DUELS],
					row_names[ROW_LASTJOIN],

					player_data[id][PLAYER_STEAMID],
					player_data[id][PLAYER_NAME],
					player_data[id][PLAYER_IP],

					skill,

					stats[STATS_KILLS],
					stats[STATS_DEATHS],
					stats[STATS_ASSISTS],
					stats[STATS_FAVKNIFE],
					stats[STATS_DMG],
					stats[STATS_HEAL],
					stats[STATS_DUELS]
			)

			for(new i ; i < sizeof player_data[][PLAYER_STATS] ; i++)
			{
				player_data[id][PLAYER_STATS][i] = stats[i]
			}

			player_data[id][PLAYER_SKILL] = _:player_data[id][PLAYER_SKILLLAST] = _:skill

			if(reload)
			{
				player_data[id][PLAYER_LOADSTATE] = LOAD_UPDATE
			}
			else
			{
				player_data[id][PLAYER_LOADSTATE] = LOAD_NEWWAIT
			}
		}
	}

	if(query[0])
	{
		if(knife_stats_enabled)
		{
			DB_SavePlayerKnfstats(id)
		}

		switch(sql_data[0])
		{
			// accumulate requests
			case SQL_UPDATE:
			{
				// there are enough requests, so drop them
				DB_AddQuery(query,len)

				return true
			}
		}

		SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data)
	}

	return true
}

//
// Save knives stats to the DB
//
public DB_SavePlayerKnfstats(id)
{
	if(player_data[id][PLAYER_LOADSTATE] < LOAD_OK)
	{
		return false
	}

	new query[QUERY_LENGTH],len,knf_name[MAX_NAME_LENGTH],knf,stats_index,stats_index_last,to_save
	new diff[STATS_END]

	const load_index = sizeof player_aknfstats[][] - 1

	new iKnivesNum = kc_get_knives_num()
	for(knf = 1; knf <= iKnivesNum ; knf++)
	{
		kc_knife_get_abil1_name(knf - 1, knf_name, charsmax(knf_name))

		to_save = 0
		len = 0

		// calculate the diff in stats
		for(stats_index = 0;  stats_index < STATS_END;  stats_index++)
		{
			stats_index_last = stats_index + (STATS_END)

			diff[stats_index] = player_knfstats[id][knf][stats_index] - player_aknfstats[id][knf][stats_index_last]
			player_aknfstats[id][knf][stats_index_last] = player_knfstats[id][knf][stats_index]
		}

		switch(player_aknfstats[id][knf][load_index])
		{
			case LOAD_NEW: // insert
			{
				new id_row

				len += formatex(query[len],charsmax(query) - len,"INSERT INTO `%s_knives` (`%s`,`%s`",
					tbl_name,

					row_knives_names[ROW_KNIFE_PLAYER],
					row_knives_names[ROW_KNIFE_NAME]
				)

				for(stats_index = 0;  stats_index < STATS_DUELS;  stats_index++)
				{
					id_row = ROW_KNIFE_KILLS + stats_index

					if(diff[stats_index])
					{
						len += formatex(query[len],charsmax(query) - len,",`%s`",
							row_knives_names[id_row]
						)

						to_save ++
					}
				}

				if(to_save)
				{
					len += formatex(query[len],charsmax(query) - len,") VALUES('%d','%s'",
						player_data[id][PLAYER_ID],
						knf_name
					)

					for(stats_index = 0;  stats_index < STATS_DUELS;  stats_index++)
					{
						id_row = ROW_KNIFE_KILLS + stats_index

						if(diff[stats_index])
						{
							len += formatex(query[len],charsmax(query) - len,",'%d'",
								diff[stats_index]
							)
						}
					}

					len += formatex(query[len],charsmax(query) - len,")")
					player_aknfstats[id][knf][load_index]  = _:LOAD_OK
				}
			}
			case LOAD_OK: // update
			{
				new id_row

				len += formatex(query[len],charsmax(query) - len,"UPDATE `%s_knives` SET",tbl_name)

				for(stats_index = 0;  stats_index < STATS_DUELS;  stats_index++)
				{
					id_row = ROW_KNIFE_KILLS + stats_index

					if(diff[stats_index])
					{
						len += formatex(query[len],charsmax(query) - len,"%s`%s` = `%s` + '%d'",
							to_save ? "," : "",
							row_knives_names[id_row],
							row_knives_names[id_row],
							diff[stats_index]
						)

						to_save ++
					}
				}

				len += formatex(query[len],charsmax(query) - len,"WHERE `%s` = '%s' AND `%s` = '%d'",
					row_knives_names[ROW_KNIFE_NAME],knf_name,
					row_knives_names[ROW_KNIFE_PLAYER],player_data[id][PLAYER_ID]
				)
			}
		}

		if(to_save)
		{
			DB_AddQuery(query,len)
		}
	}

	return true
}

DB_AddQuery(query[],len)
{
	if((flush_que_len + len + 1) > charsmax(flush_que))
	{
		DB_FlushQuery()
	}

	flush_que_len += formatex(
		flush_que[flush_que_len],
		charsmax(flush_que) - flush_que_len,
		"%s%s",flush_que_len ? ";" : "",
		query
	)

	// task to reset accumulated requests
	remove_task(task_flush)
	set_task(0.1,"DB_FlushQuery",task_flush)
}

//
// Reset accumulated requests
//
public DB_FlushQuery()
{
	if(flush_que_len)
	{
		new sql_data[1] = SQL_UPDATE
		SQL_ThreadQuery(sql,"SQL_Handler",flush_que,sql_data,sizeof sql_data)

		flush_que_len = 0
	}
}

#define falos false

public DB_GetPlayerRanks()
{
	new players[32],pnum
	get_players(players,pnum)

	new query[QUERY_LENGTH],len

	len += formatex(query[len],charsmax(query) - len,"SELECT `id`,(")
	len += DB_QueryBuildScore(query[len],charsmax(query) - len)
	len += formatex(query[len],charsmax(query) - len,") FROM `%s` as `a` WHERE `id` IN(",tbl_name)

	new bool:letsgo

	for(new i,player,bool:y  ; i < pnum ; i++)
	{
		player = players[i]

		if(player_data[player][PLAYER_ID])
		{
			len += formatex(query[len],charsmax(query) - len,"%s'%d'",y ? "," : "",player_data[player][PLAYER_ID])
			y = true
			letsgo = true
		}
	}

	len += formatex(query[len],charsmax(query) - len,")")

	if(letsgo)
	{
		new data[1] = SQL_UPDATERANK
		SQL_ThreadQuery(sql,"SQL_Handler",query,data,sizeof data)
	}
}

new bool:update_cache = false

//
// Save all players stats
//
public DB_SaveAll()
{
	new players[32],pnum
	get_players(players,pnum)

	if(get_pcvar_num(cvar[CVAR_CACHETIME]) == -1)
	{
		update_cache = true
	}

	for(new i ; i < pnum ; i++)
	{
		DB_SavePlayerData(players[i])
	}
}

//
// Request to calculate the rank
//
DB_QueryBuildScore(sql_que[] = "",sql_que_len = 0,bool:only_rows = falos,overide_order = 0)
{
	if(only_rows)
	{
		switch(overide_order ? overide_order : get_pcvar_num(cvar[CVAR_RANKFORMULA]))
		{
			case CSXSQL_RANK_K: return formatex(sql_que,sql_que_len,"`kills`")
			case CSXSQL_RANK_SKILL: return formatex(sql_que,sql_que_len,"`skill`")
			case CSXSQL_RANK_TIME: return formatex(sql_que,sql_que_len,"`connection_time`")
			case CSXSQL_RANK_LEVEL: return formatex(sql_que,sql_que_len,"`kills`+`assists`/3")
			case CSXSQL_RANK_ASSISTS: return formatex(sql_que,sql_que_len,"`assists`")
			default: return formatex(sql_que,sql_que_len,"`kills`-`deaths`")
		}
	}
	else
	{
		switch(overide_order ? overide_order : get_pcvar_num(cvar[CVAR_RANKFORMULA]))
		{
			case CSXSQL_RANK_K: return formatex(sql_que,sql_que_len,"SELECT COUNT(*) FROM %s WHERE (kills)>=(a.kills)",tbl_name)
			case CSXSQL_RANK_SKILL: return formatex(sql_que,sql_que_len,"SELECT COUNT(*) FROM %s WHERE (skill)>=(a.skill)",tbl_name)
			case CSXSQL_RANK_TIME: return formatex(sql_que,sql_que_len,"SELECT COUNT(*) FROM %s WHERE (connection_time)>=(a.connection_time)",tbl_name)
			case CSXSQL_RANK_LEVEL: return formatex(sql_que,sql_que_len,"SELECT COUNT(*) FROM %s WHERE (kills+assists/3)>=(a.kills+a.assists/3)",tbl_name)
			case CSXSQL_RANK_ASSISTS: return formatex(sql_que,sql_que_len,"SELECT COUNT(*) FROM %s WHERE (assists)>=(a.assists)",tbl_name)
			default: return formatex(sql_que,sql_que_len,"SELECT COUNT(*) FROM %s WHERE (kills-deaths)>=(a.kills-a.deaths)",tbl_name)
		}
	}

	return 0
}

//
// Request for the total records number in the DB
//
DB_QueryBuildStatsnum(sql_que[] = "",sql_que_len = 0)
{
	return formatex(sql_que,sql_que_len,"SELECT COUNT(*) FROM %s WHERE 1",tbl_name)
}

DB_QueryBuildGetstats(query[],query_max,len = 0,index,index_count = 2,overide_order = 0)
{
	len += formatex(query[len],query_max-len,"SELECT *")

	// request for a rank
	len += formatex(query[len],query_max-len,",(")
	len += DB_QueryBuildScore(query[len],query_max-len,true,overide_order)
	len += formatex(query[len],query_max-len,") as `rank`")

	// request for next record (index + 1)
	len += formatex(query[len],query_max-len," FROM `%s` as `a` ORDER BY `rank` DESC LIMIT %d,%d",
		tbl_name,index,index_count
	)

	return len
}

//
// Read the get_stats result of a request
//
DB_ReadGetStats(Handle:sqlQue,name[] = "",name_len = 0,authid[] = "",authid_len = 0,stats[STATS_END] = 0,&stats_count = 0,index)
{
	stats_count = SQL_NumResults(sqlQue)

	if(!stats_count)
	{
		return false
	}

	new stats_cache[stats_cache_struct]

	SQL_ReadResult(sqlQue,ROW_STEAMID,stats_cache[CACHE_STEAMID],charsmax(stats_cache[CACHE_STEAMID]))
	SQL_ReadResult(sqlQue,ROW_NAME,stats_cache[CACHE_NAME],charsmax(stats_cache[CACHE_NAME]))

	copy(name,name_len,stats_cache[CACHE_NAME])
	copy(authid,authid_len,stats_cache[CACHE_STEAMID])

	new i

	for(i = ROW_SKILL ; i <= ROW_LASTJOIN ; i++)
	{
		switch(i)
		{
			case ROW_SKILL: SQL_ReadResult(sqlQue,i,stats_cache[CACHE_SKILL])
			case ROW_KILLS..ROW_DUELS:
			{
				stats_cache[CACHE_STATS][i - ROW_KILLS] = stats[i - ROW_KILLS] = SQL_ReadResult(sqlQue,i)
			}
			case ROW_FAVKNIFE:
			{
				stats_cache[CACHE_STATS][STATS_FAVKNIFE] = stats[STATS_FAVKNIFE] = SQL_ReadResult(sqlQue,i)
			}
			case ROW_FIRSTJOIN..ROW_LASTJOIN:
			{
				new date_str[32]
				SQL_ReadResult(sqlQue,i,date_str,charsmax(date_str))

				stats_cache[(CACHE_FIRSTJOIN + (i - ROW_FIRSTJOIN))] = parse_time(date_str,"%Y-%m-%d %H:%M:%S")
			}
		}

	}

	if(!stats_cache_trie)
	{
		stats_cache_trie = TrieCreate()
	}

	stats_cache[CACHE_LAST] = SQL_NumResults(sqlQue) <= 1
	SQL_ReadResult(sqlQue,ROW_SKILL,stats_cache[CACHE_SKILL])
	stats_cache[CACHE_ID] = SQL_ReadResult(sqlQue,ROW_ID)
	stats_cache[CACHE_TIME] = SQL_ReadResult(sqlQue,ROW_ONLINETIME)

	new index_str[10]
	num_to_str(index,index_str,charsmax(index_str))

	TrieSetArray(stats_cache_trie,index_str,stats_cache,stats_cache_struct)

	SQL_NextRow(sqlQue)

	return SQL_MoreResults(sqlQue)
}

//
// Setup a queue for updating the cache
//
bool:Cache_Stats_SetQueue(start_index,top)
{
	// queue has already been created
	if(Cache_Stats_CheckQueue(start_index,top))
	{
		return false
	}

	if(!stats_cache_queue)
	{
		stats_cache_queue = ArrayCreate(stats_cache_queue_struct)
	}

	new length = ArraySize(stats_cache_queue)

	new cache_queue_info[stats_cache_queue_struct]
	cache_queue_info[CACHE_QUE_START] = start_index
	cache_queue_info[CACHE_QUE_TOP] = top

	if(!length)
	{
		ArrayPushArray(stats_cache_queue,cache_queue_info)
	}
	else
	{
		ArrayInsertArrayBefore(stats_cache_queue,0,cache_queue_info)
	}

	length ++

	if(length > 5)
	{
		ArrayDeleteItem(stats_cache_queue,5)
		length --
	}

	return true
}

//
// Update the cache via a queue
//
bool:Cache_Stats_UpdateQueue()
{
	if(!stats_cache_queue)
	{
		return false
	}

	for(new i,length = ArraySize(stats_cache_queue),cache_queue_info[stats_cache_queue_struct] ; i < length ; i++)
	{
		ArrayGetArray(stats_cache_queue,i,cache_queue_info)
		DB_QueryTop15(0,-1,-1,-1,cache_queue_info[CACHE_QUE_START],cache_queue_info[CACHE_QUE_TOP],-1)
	}

	return true
}

bool:Cache_Stats_CheckQueue(start_index,top)
{
	if(!stats_cache_queue)
	{
		return false
	}

	for(new i,length = ArraySize(stats_cache_queue),cache_queue_info[stats_cache_queue_struct] ; i < length ; i++)
	{
		ArrayGetArray(stats_cache_queue,i,cache_queue_info)

		if(start_index == cache_queue_info[0] &&
			top == cache_queue_info[1]
		)
		{
			return true
		}
	}

	return false
}

//
// Thread request to Top15
//
bool:DB_QueryTop15(id,plugin_id,func_id,position,start_index,top,params)
{
	if((get_pcvar_num(cvar[CVAR_CACHETIME]) != 0) && stats_cache_trie)
	{
		Cache_Stats_SetQueue(start_index,top)

		new bool:use_cache = true

		for(new i = start_index,index_str[10]; i < (start_index + top) ; i++)
		{
			num_to_str(i,index_str,charsmax(index_str))

			if(!TrieKeyExists(stats_cache_trie,index_str))
			{
				use_cache = false
			}
		}

		if(use_cache)
		{
			if(func_id > -1)
			{
				if(callfunc_begin_i(func_id,plugin_id))
				{
					callfunc_push_int(id)
					callfunc_push_int(position)
					callfunc_end()
				}
			}

			return true
		}
	}

	new query[QUERY_LENGTH]

	if(params == 5)
	{
		DB_QueryBuildGetstats(query,charsmax(query),.index = start_index,.index_count = top,.overide_order = get_param(5))
	}
	else
	{
		DB_QueryBuildGetstats(query,charsmax(query),.index = start_index,.index_count = top)
	}

	new sql_data[6]

	sql_data[0] = SQL_GETSTATS
	sql_data[1] = id
	sql_data[2] = plugin_id
	sql_data[3] = func_id
	sql_data[4] = position
	sql_data[5] = start_index

	SQL_ThreadQuery(sql,"SQL_Handler",query,sql_data,sizeof sql_data)

	return true
}

//
// Update the cache for get_stats
//
bool:Cache_Stats_Update()
{
	if(!stats_cache_trie)
		return false

	TrieClear(stats_cache_trie)

	return true
}

//
// Process responses to SQL queries
//
public SQL_Handler(failstate,Handle:sqlQue,err[],errNum,data[],dataSize)
{
	switch(failstate)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("SQL connection failed")
			log_amx("[ %d ] %s",errNum,err)

			return PLUGIN_HANDLED
		}
		case TQUERY_QUERY_FAILED:
		{
			new lastQue[QUERY_LENGTH]
			SQL_GetQueryString(sqlQue,lastQue,charsmax(lastQue))

			log_amx("SQL query failed")
			log_amx("[ %d ] %s",errNum,err)
			log_amx("[ SQL ] %s",lastQue)

			return PLUGIN_HANDLED
		}
	}

	switch(data[0])
	{
		case SQL_INITDB:
		{
			DB_InitSeq()
		}
		case SQL_LOAD:
		{
			new id = data[1]

			if(!is_user_connected(id))
			{
				return PLUGIN_HANDLED
			}

			if(SQL_NumResults(sqlQue))
			{
				player_data[id][PLAYER_LOADSTATE] = LOAD_OK
				player_data[id][PLAYER_ID] = SQL_ReadResult(sqlQue,ROW_ID)

				player_data[id][PLAYER_STATS][STATS_KILLS] = SQL_ReadResult(sqlQue,ROW_KILLS)
				player_data[id][PLAYER_STATS][STATS_DEATHS] = SQL_ReadResult(sqlQue,ROW_DEATHS)
				player_data[id][PLAYER_STATS][STATS_ASSISTS] = SQL_ReadResult(sqlQue,ROW_ASSISTS)
				player_data[id][PLAYER_STATS][STATS_FAVKNIFE] = SQL_ReadResult(sqlQue,ROW_FAVKNIFE)
				player_data[id][PLAYER_STATS][STATS_DMG] = SQL_ReadResult(sqlQue,ROW_DMG)
				player_data[id][PLAYER_STATS][STATS_HEAL] = SQL_ReadResult(sqlQue,ROW_HEAL)
				player_data[id][PLAYER_STATS][STATS_DUELS] = SQL_ReadResult(sqlQue,ROW_DUELS)

				player_data[id][PLAYER_ONLINE] = player_data[id][PLAYER_ONLINELAST] = SQL_ReadResult(sqlQue,ROW_ONLINETIME)

				SQL_ReadResult(sqlQue,ROW_SKILL,player_data[id][PLAYER_SKILL])
				player_data[id][PLAYER_SKILLLAST] = _:player_data[id][PLAYER_SKILL]

				new date_str[32]

				SQL_ReadResult(sqlQue,ROW_FIRSTJOIN,date_str,charsmax(date_str))
				player_data[id][PLAYER_FIRSTJOIN] = parse_time(date_str,"%Y-%m-%d %H:%M:%S")
				SQL_ReadResult(sqlQue,ROW_LASTJOIN,date_str,charsmax(date_str))
				player_data[id][PLAYER_LASTJOIN] = parse_time(date_str,"%Y-%m-%d %H:%M:%S")

				player_data[id][PLAYER_RANK] = SQL_ReadResult(sqlQue,row_ids)
				statsnum = SQL_ReadResult(sqlQue,row_ids + 1)

				if(knife_stats_enabled)
				{
					DB_LoadPlayerKnfstats(id)
				}

				ExecuteForward(FW_StatsLoaded, _, id)
			}
			else // new record
			{
				player_data[id][PLAYER_LOADSTATE] = LOAD_NEW

				DB_SavePlayerData(id)
			}
		}
		case SQL_INSERT:
		{
			new id = data[1]

			if(is_user_connected(id))
			{
				if(player_data[id][PLAYER_LOADSTATE] == LOAD_UPDATE)
				{
					player_data[id][PLAYER_LOADSTATE] = LOAD_NO
					DB_LoadPlayerData(id)

					return PLUGIN_HANDLED
				}

				player_data[id][PLAYER_ID] = SQL_GetInsertId(sqlQue)
				player_data[id][PLAYER_LOADSTATE] = LOAD_OK

				statsnum++

				if(knife_stats_enabled)
				{
					DB_LoadPlayerKnfstats(id)
				}
			}

			if(!task_exists(task_rankupdate))
			{
				set_task(1.0,"DB_GetPlayerRanks",task_rankupdate)
			}
		}
		case SQL_UPDATE:
		{
			if(!task_exists(task_rankupdate))
			{
				set_task(0.1,"DB_GetPlayerRanks",task_rankupdate)
			}

			new players[MAX_PLAYERS],pnum
			get_players(players,pnum)

			for(new i,player ; i < pnum ; i++)
			{
				player = players[i]

				if(player_data[player][PLAYER_LOADSTATE] == LOAD_UPDATE)
				{
					player_data[player][PLAYER_LOADSTATE] = LOAD_NO
					DB_LoadPlayerData(player)
				}
			}

			if(update_cache)
			{
				update_cache = false

				Cache_Stats_Update()
				Cache_Stats_UpdateQueue()
			}
		}
		case SQL_UPDATERANK:
		{
			while(SQL_MoreResults(sqlQue))
			{
				new pK =  SQL_ReadResult(sqlQue,0)
				new rank = SQL_ReadResult(sqlQue,1)

				for(new i ; i < MAX_PLAYERS ; i++)
				{
					if(player_data[i][PLAYER_ID] == pK)
					{
						player_data[i][PLAYER_RANK] = rank
					}
				}

				SQL_NextRow(sqlQue)
			}
		}
		case SQL_GETSTATS:
		{
			new id = data[1]

			if(id && !is_user_connected(id))
			{
				return PLUGIN_HANDLED
			}

			new index = data[5]
			new name[32],authid[30]

			while(DB_ReadGetStats(sqlQue,name,charsmax(name),authid,charsmax(authid),.index = index ++))
			{
			}

			if(data[3] > -1)
			{
				if(callfunc_begin_i(data[3],data[2]))
				{
					callfunc_push_int(id)
					callfunc_push_int(data[4])
					callfunc_end()
				}
			}
		}

		case SQL_GETKNFSTATS:
		{
			new id = data[1]

			if(!is_user_connected(id))
			{
				return PLUGIN_HANDLED
			}

			const load_index = sizeof player_aknfstats[][] - 1

			while(SQL_MoreResults(sqlQue))
			{
				new knife_name[MAX_NAME_LENGTH]
				SQL_ReadResult(sqlQue,ROW_KNIFE_NAME,knife_name,charsmax(knife_name))

				new knf
				if (TrieGetCell(knives_names_map, knife_name, knf))
				{
					for(new i ; i < STATS_DUELS ; i++)
					{
						player_aknfstats[id][knf][i] = SQL_ReadResult(sqlQue,i + ROW_KNIFE_KILLS)
					}

					player_aknfstats[id][knf][load_index] = _:LOAD_OK
				}
				SQL_NextRow(sqlQue)
			}

			for(new knf ; knf <= MAX_KNIVES ; knf++)
			{
				if(_:player_aknfstats[id][knf][load_index] != _:LOAD_OK)
				{
					player_aknfstats[id][knf][load_index] = _:LOAD_NEW
				}
			}
		}
		case SQL_AUTOCLEAR:
		{
			if(SQL_AffectedRows(sqlQue))
			{
				log_amx("deleted %d inactive entries",
					SQL_AffectedRows(sqlQue)
				)
			}

			DB_InitSeq()
		}
	}

	return PLUGIN_HANDLED
}

/*
*
* API
*
*/

#define CHECK_PLAYER(%1) \
	if (%1 < 1 || %1 > MaxClients) { \
		log_error(AMX_ERR_NATIVE, "Player out of range (%d)", %1); \
		return 0; \
	} else { \
		if (!is_user_connected(%1) || pev_valid(%1) != 2) { \
			log_error(AMX_ERR_NATIVE, "Invalid player %d", %1); \
			return 0; \
		} \
	}

#define CHECK_PLAYERRANGE(%1) \
	if(%1 < 0 || %1 > MaxClients) {\
		log_error(AMX_ERR_NATIVE,"Player out of range (%d)",%1);\
		return 0;\
	}

#define CHECK_KNIFE(%1) \
	if(!(0 <= %1 <= MAX_KNIVES)){\
		log_error(AMX_ERR_NATIVE,"Invalid knife id %d",%1);\
		return 0;\
	}

public plugin_natives()
{
	register_library("efk_statsx_sql")

	register_native("get_statsnum_sql","native_get_statsnum")
	register_native("get_user_stats_sql","native_get_user_stats")
	register_native("get_stats_sql","native_get_stats")
	register_native("get_stats_sql_thread","native_get_stats_thread")
	register_native("get_user_skill","native_get_user_skill")
	register_native("get_skill","native_get_skill")

	register_native("get_user_gametime","native_get_user_gametime")
	register_native("get_stats_gametime","native_get_stats_gametime")
	register_native("get_user_stats_id","native_get_user_stats_id")
	register_native("get_stats_id","native_get_stats_id")
	register_native("update_stats_cache","native_update_stats_cache")

	register_native("get_user_firstjoin_sql","native_get_user_firstjoin_sql")
	register_native("get_user_lastjoin_sql","native_get_user_lastjoin_sql")

	register_native("get_user_knfstats_sql","native_get_user_knfstats_sql")
	register_native("get_user_knfstats","native_get_user_knfstats")
}

public native_get_user_firstjoin_sql(plugin_id,params)
{
	new id = get_param(1)
	CHECK_PLAYERRANGE(id)

	if(player_data[id][PLAYER_LOADSTATE] == LOAD_NO)
	{
		return -1
	}

	return player_data[id][PLAYER_FIRSTJOIN]
}

public native_get_user_lastjoin_sql(plugin_id,params)
{
	new id = get_param(1)
	CHECK_PLAYERRANGE(id)

	if(player_data[id][PLAYER_LOADSTATE] == LOAD_NO)
	{
		return -1
	}

	return player_data[id][PLAYER_LASTJOIN]
}

public native_get_user_knfstats_sql(plugin_id,params)
{
	if(params != 3)
	{
		log_error(AMX_ERR_NATIVE,"Bad arguments num, expected 4, passed %d",params)

		return false
	}

	if(!knife_stats_enabled)
	{
		return -1
	}

	new player_id = get_param(1)
	CHECK_PLAYERRANGE(player_id)

	new knf_id = get_param(2)
	CHECK_KNIFE(knf_id)

	new stats[STATS_END]

	const stats_index_last = STATS_END

	for(new i ; i < STATS_END ; i++)
	{
		stats[i] = player_aknfstats[player_id][knf_id][i] + player_aknfstats[player_id][knf_id][i + stats_index_last]
	}

	/*if(!stats[STATS_KILLS])
	{
		return false
	}*/

	set_array(3,stats,sizeof stats)

	return true
}

public native_update_stats_cache()
{
	return Cache_Stats_Update()
}

// native get_user_gametime(id)
public native_get_user_gametime(plugin_id,params)
{
	new id = get_param(1)
	CHECK_PLAYERRANGE(id)

	if(player_data[id][PLAYER_LOADSTATE] == LOAD_NO)
	{
		return -1
	}

	return player_data[id][PLAYER_ONLINE]
}

// native get_stats_gametime(index,&game_time)
public native_get_stats_gametime(plugin_id,params)
{
	new index = get_param(1)

	new index_str[10],stats_cache[stats_cache_struct]
	num_to_str(index,index_str,charsmax(index_str))

	if(stats_cache_trie && TrieGetArray(stats_cache_trie,index_str,stats_cache,stats_cache_struct))
	{
		set_param_byref(2,stats_cache[CACHE_TIME])
		return !stats_cache[CACHE_LAST] ? index + 1 : 0
	}

	return 0
}

// native get_user_stats_id(id)
public native_get_user_stats_id(plugin_id,params)
{
	new id = get_param(1)
	CHECK_PLAYERRANGE(id)

	return player_data[id][PLAYER_ID]
}

// native get_stats_id(index,&db_id)
public native_get_stats_id(plugin_id,params)
{
	new index = get_param(1)

	new index_str[10],stats_cache[stats_cache_struct]
	num_to_str(index,index_str,charsmax(index_str))

	if(stats_cache_trie && TrieGetArray(stats_cache_trie,index_str,stats_cache,stats_cache_struct))
	{
		set_param_byref(2,stats_cache[CACHE_ID])
		return !stats_cache[CACHE_LAST] ? index + 1 : 0
	}

	return 0
}

// native get_user_skill(player,&Float:skill)
public native_get_user_skill(plugin_id,params)
{
	new id = get_param(1)
	CHECK_PLAYERRANGE(id)

	set_float_byref(2,player_data[id][PLAYER_SKILL])

	return true
}

// native get_skill(index,&Float:skill)
public native_get_skill(plugin_id,params)
{
	new index = get_param(1)

	new index_str[10],stats_cache[stats_cache_struct]

	if(index < 0)
		index = 0

	num_to_str(index,index_str,charsmax(index_str))

	if(stats_cache_trie && TrieGetArray(stats_cache_trie,index_str,stats_cache,stats_cache_struct))
	{
		set_float_byref(2,Float:stats_cache[CACHE_SKILL])
		return !stats_cache[CACHE_LAST] ? index + 1 : 0
	}

	return 0
}

// native get_user_knfstats(index, knfindex, stats[STATS_END])
public native_get_user_knfstats(plugin_id,params)
{
	new id = get_param(1)

	CHECK_PLAYERRANGE(id)

	new knf_id = get_param(2)

	CHECK_KNIFE(knf_id)

	new stats[STATS_END]
	get_user_knfstats(id,knf_id,stats)

	set_array(3,stats,STATS_END)

	//return stats[STATS_DEATHS]
	return 1
}

// native get_user_stats(index, stats[STATS_END])
public native_get_user_stats(plugin_id,params)
{
	new id = get_param(1)

	CHECK_PLAYERRANGE(id)

	if(player_data[id][PLAYER_LOADSTATE] < LOAD_OK)
	{
		return 0
	}

	set_array(2,player_data[id][PLAYER_STATS],STATS_END)

	return player_data[id][PLAYER_RANK]
}

// native get_statsnum()
public native_get_statsnum(plugin_id,params)
{
	return statsnum
}

// native get_stats(index, stats[STATS_END], name[], len, authid[] = "", authidlen = 0);
public native_get_stats(plugin_id,params)
{
	if(!is_ready)
	{
		return 0
	}

	if(params < 4)
	{
		log_error(AMX_ERR_NATIVE,"Bad arguments num, expected 4, passed %d",params)

		return 0
	}
	else if(params > 4 && params != 6)
	{
		log_error(AMX_ERR_NATIVE,"Bad arguments num, expected 6, passed %d",params)

		return 0
	}

	new index = get_param(1)

	new index_str[10],stats_cache[stats_cache_struct]
	num_to_str(index,index_str,charsmax(index_str))

	if(stats_cache_trie && TrieGetArray(stats_cache_trie,index_str,stats_cache,stats_cache_struct))
	{
		set_array(2,stats_cache[CACHE_STATS],sizeof stats_cache[CACHE_STATS])
		set_string(3,stats_cache[CACHE_NAME],get_param(4))

		if(params == 6)
		{
			set_string(5,stats_cache[CACHE_STEAMID],get_param(6))
		}

		return !stats_cache[CACHE_LAST] ? index + 1 : 0
	}

	if(!DB_OpenConnection())
	{
		return false
	}
	else
	{
		if(!task_exists(task_confin))
		{
			set_task(0.1,"DB_CloseConnection",task_confin)
		}
	}

	new query[QUERY_LENGTH]
	DB_QueryBuildGetstats(query,charsmax(query),.index = index)
	new Handle:sqlQue = SQL_PrepareQuery(sql_con,query)

	if(!SQL_Execute(sqlQue))
	{
		new errNum,err[256]
		errNum = SQL_QueryError(sqlQue,err,charsmax(err))

		log_amx("SQL query failed")
		log_amx("[ %d ] %s",errNum,err)
		log_amx("[ SQL ] %s",query)

		SQL_FreeHandle(sqlQue)

		return 0
	}

	new name[32],steamid[30],stats[STATS_END],stats_count

	DB_ReadGetStats(sqlQue,
		name,charsmax(name),
		steamid,charsmax(steamid),
		stats,
		.stats_count = stats_count,
		.index = index
	)

	if(!stats_count)
	{
		return false
	}

	SQL_FreeHandle(sqlQue)

	set_array(2,stats,sizeof player_data[][PLAYER_STATS])
	set_string(3,name,get_param(4))

	if(params == 6)
	{
		set_string(5,steamid,get_param(6))
	}

	return stats_count > 1 ? index + 1 : 0
}

// native get_stats_sql_thread(id,position,top,callback[]);
public native_get_stats_thread(plugin_id,params)
{
	if(!is_ready)
	{
		return false
	}

	if(params < 4)
	{
		log_error(AMX_ERR_NATIVE,"Bad arguments num, expected 4, passed %d",params)

		return false
	}

	new id = get_param(1)
	new position = min(statsnum,get_param(2))
	new top = get_param(3)
	new start_index = max((position - top),0)

	new callback[20]
	get_string(4,callback,charsmax(callback))

	new func_id = get_func_id(callback,plugin_id)

	if(func_id == -1)
	{
		log_error(AMX_ERR_NATIVE,"Unable to locate ^"%s^" handler.",callback)

		return false
	}

	return DB_QueryTop15(id,plugin_id,func_id,position,start_index,top,params)
}

/*
*
* FUNCTIONS FOR STATS CALCULATION
*
*/

get_user_knfstats(index, knfindex, stats[STATS_END])
{
	for(new i ; i < STATS_END ; i++)
	{
		stats[i] = player_knfstats[index][knfindex][i]
	}
}

bool:reset_user_allstats(index)
{
	for(new i ; i <= MAX_KNIVES ; i++)
	{
		arrayset(player_knfstats[index][i],0,sizeof player_knfstats[][])
	}

	return true
}

public bool:DB_OpenConnection()
{
	if(!is_ready)
	{
		return false
	}

	if(sql_con != Empty_Handle)
	{
		return true
	}

	new errNum,err[256]
	sql_con = SQL_Connect(sql,errNum,err,charsmax(err))

	SQL_SetCharset(sql_con,"utf8")

	if(errNum)
	{
		log_amx("SQL query failed")
		log_amx("[ %d ] %s",errNum,err)

		return false
	}

	return true
}

public DB_CloseConnection()
{
	if(sql_con != Empty_Handle)
	{
		SQL_FreeHandle(sql_con)
		sql_con = Empty_Handle
	}
}

/*********    mysql escape functions     ************/
mysql_escape_string(dest[],len)
{
	//copy(dest, len, source);
	replace_all(dest,len,"\\","\\\\");
	replace_all(dest,len,"\0","\\0");
	replace_all(dest,len,"\n","\\n");
	replace_all(dest,len,"\r","\\r");
	replace_all(dest,len,"\x1a","\Z");
	replace_all(dest,len,"'","''");
	replace_all(dest,len,"^"","^"^"");
}