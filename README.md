# Epic Fun Knife

TODO: description

## Configuration

### Stats

The mod for managing player statistics uses a special modified version of CSStatsX SQL, implemented in `efk_statsx_sql.amxx` and `efk_statsx_aes.amxx`. To configure stats, use the following cvars:

<details>
<summary>Click to expand</summary>

| CVar                               | Default   | Description                                    |
| :--------------------------------- | :-------: | :--------------------------------------------- |
| efk_statsx_host                    | localhost | MySQL host |
| efk_statsx_user                    | root      | MySQL user |
| efk_statsx_pass                    |           | MySQL password |
| efk_statsx_db                      | amxx      | MySQL or SQLite DB name |
| efk_statsx_table                   | efkstats  | Table name in DB |
| efk_statsx_type                    | mysql     | DB type (`mysql` or `sqlite`) |
| efk_statsx_create_db               | 1         | Send a request to create a table |
| efk_statsx_rankbots                | 0         | Record stats for bots |
| efk_statsx_update                  | -1        | How to update player stats in the DB<br/>`-2` at death and disconnect<br/>`-1` at the round end and disconnect<br/>`0` at disconnect<br/>`> 0` at the specified number of seconds and disconnect|
| efk_statsx_rankformula             | 4         | Formula for calculating the rank<br/>`0`  kills - deaths<br/>`1` kills<br/>`2` skill<br/>`3` online time<br/>`4` kills + assists / 3<br/>`5` assists|
| efk_statsx_knives                  | 1         | Enable knives stats |
| efk_statsx_autoclear               | 0         | Automatic cleaning of inactive players in the DB |
| efk_statsx_cachetime               | -1        | Use the cache for get_stats<br/>`-1` update at the end of the round or at the time of csstats_sql_update<br/>`0` disable cache |
| efk_statsx_autoclear_day           | 0         | Automatic cleaning of all game stats in the DB on a specific day |
| efk_aes_top                        | *abcsfiel | /top columns |
| efk_aes_online                     | *anl      | /online columns |
| efk_aes_assistans                  | *asdl     | /assist columns |
| efk_aes_level                      | *al       | /level columns |
| efk_aes_rank                       | bcs       | /rankstats columns |
</details>

**Important!** The MOTD cannot show more than 1534 characters, and the chat message cannot show more than 192 characters.
If something is displayed incompletely, then you need to reduce the number of points (the top does not show more than 10 players).
Columns tags:<br/>
`*` - Rank<br/>
`a` - Name (Only /top15)<br/>
`b` - Kills<br/>
`c` - Deaths<br/>
`d` - Heal<br/>
`e` - Skill<br/>
`f` - Favorite Knife<br/>
`h` - Effectiveness<br/>
`l` - Level<br/>
`k` - K:D<br/>
`n` - Online Time<br/>
`s` - Assists<br/>

### Hats
The list of hats is stored in `addons/amxmodx/configs/efk_hats.json` (create the file if it does not exist). The syntax of `efk_hats.json` is similar to [Hats plugin](https://github.com/Next21Team/Hats), except for the possibility to set player access level using the `level` field. Config example:
```json
{
	"EFK March 2025": {
		"model": "march2025_rc01.mdl",
		"tag": "b",
		"level": 4
	},
	"Santa": {
		"model": "santa_hat_v3.mdl",
		"tag": "s",
		"level": 0,
		"items": [
			"Red Santa",
			"Blue Santa",
			"Magenta Santa",
			"Cyan Santa",
			"Green Santa",
			"Yellow Santa"
		]
	},
	"Zed": {
		"model": "zed_v02.mdl",
		"tag": "n",
		"level": 21
	}
}
```

## Requirements
- [Metamod-R](https://github.com/theAsmodai/metamod-r) + [ReHLDS](https://github.com/dreamstalker/rehlds) or [Metamod-P](https://github.com/Bots-United/metamod-p)
- [RegameDLL](https://github.com/s1lentq/ReGameDLL_CS)
- [Amx Mod X 1.9.0+](https://www.amxmodx.org/downloads-new.php)
- [ReAPI](https://github.com/s1lentq/reapi)
- [NextClientServerApi](https://github.com/CS-NextClient/NextClientServerApi)

## Deployment
- Clone repository with submodules: `git clone --recurse-submodules https://github.com/Next21Team/EpicFunKnife.git`
- Install dependencies and download latest assets: `npm i`

### Customize builder
Use `.amxxpack.json` configuration file

### Build project
`npm run build`

## Assets
Assets for the mod:
https://www.dropbox.com/scl/fi/4s941jrbeenkau96inph8/efk_assets.zip?rlkey=dth0ou65a4537jec7anubmolh&dl=1
