# Epic Fun Knife

**Epic Fun Knife** is a Knife Arena mod for Counter-Strike 1.6 where every knife has unique abilities and a distinct playstyle, now featuring a team deathmatch mode. Enhanced by supportive items, the mod transforms knife fights into fast-paced, unpredictable battles that reward creativity, teamwork, and quick thinking.

TODO: demo video

## Controls

- **MOUSE2 (attack2)** – Activate primary ability
- **E (use)** – Activate secondary ability
- **R (reload)** – Activate third ability
- **F (impulse 100)** – Activate fourth ability
- **T (impulse 201)** – Toggle activation of the knife's primary ability on MOUSE2
- **M (chooseteam)** – Open main menu
- **Z (radio1)** – Open knife selection menu
- **X (radio2)** or **N (nightvision)** – Open item shop menu
- **G (drop)** – Open inventory menu
- **C (radio3)** – Quick camera change

## Plugins list

The mod uses a modular architecture. You can disable unnecessary plugins in `addons/amxmodx/configs/plugins-efk.ini`, except for `efk_core.amxx`, which is required. Below is a brief description of each plugin.

<details>
<summary>Click to expand</summary>

| Plugin                             | Description                                    |
| :--------------------------------- | :--------------------------------------------- |
| efk_core.amxx                      | Core module containing the main game logic |
| efk_unprecacher.amxx               | Removes unused vanilla resources to avoid hitting precache limits |
| efk_knife_*.amxx                   | Knife plugin |
| efk_item_*.amxx                    | Item plugin |
| efk_statsx_sql.amxx                | Manages and stores player stats in a database |
| efk_statsx_aes.amxx                | Implements stats commands like `/top15`, `/rankstats`, etc. |
| efk_balancer.amxx                  | Automatically balances teams by number and skill level |
| efk_deathmatch.amxx                | Dynamic game mode with respawns and a damage zone. The team with the most kills at round end becomes immune to the zone; the losing team loses respawn ability |
| efk_hats.amxx                      | Enables hat customization |
| efk_presents.amxx                  | Random chance to drop a gift with a random item after killing an enemy |
| efk_dominations.amxx               | Domination system inspired by Team Fortress 2 |
| efk_duels.amxx                     | Duel system inspired by Team Fortress 2 |
| efk_sayme.amxx                     | Adds chat commands `/me` and `/hp` |
| efk_damage_table.amxx              | Displays top players by damage dealt at the end of the round |
| efk_radioblock.amxx                | Blocks "fire in the hole" radio commands |
| efk_nextclient_features.amxx       | Adds special visual effects for NextClient users |
| addon_floating_damage.amxx         | Damager |
| next21_save_spec_money.amxx        | Preserves player money when switching to spectator team |
</details>

## Configuration

### Stats

The mod uses a modified version of CSStatsX SQL for managing player statistics, implemented in `efk_statsx_sql.amxx` and `efk_statsx_aes.amxx`. Use the following cvars to configure it:

<details>
<summary>Click to expand</summary>

| CVar                               | Default   | Description                                    |
| :--------------------------------- | :-------: | :--------------------------------------------- |
| efk_statsx_host                    | localhost | MySQL host address |
| efk_statsx_user                    | root      | MySQL username  |
| efk_statsx_pass                    |           | MySQL password |
| efk_statsx_db                      | amxx      | Database name (MySQL or SQLite) |
| efk_statsx_table                   | efkstats  | Table name in the database |
| efk_statsx_type                    | mysql     | Database type (`mysql` or `sqlite`) |
| efk_statsx_create_db               | 1         | Create table if it doesn't exist |
| efk_statsx_rankbots                | 0         | Record stats for bots |
| efk_statsx_update                  | -1        | How to update player stats in the database<br/>`-2` at death and disconnect<br/>`-1` at the round end and disconnect<br/>`0` at disconnect<br/>`> 0` at the specified number of seconds and disconnect|
| efk_statsx_rankformula             | 4         | Formula for rank calculation<br/>`0`  kills - deaths<br/>`1` kills<br/>`2` skill<br/>`3` online time<br/>`4` kills + assists / 3<br/>`5` assists|
| efk_statsx_knives                  | 1         | Enable knives stats |
| efk_statsx_autoclear               | 0         | Automatically remove inactive players from database |
| efk_statsx_cachetime               | -1        | Use the cache for get_stats<br/>`-1` update at the end of the round or at the time of csstats_sql_update<br/>`0` disable cache |
| efk_statsx_autoclear_day           | 0         | Automatically clear all stats on a specific day |
| efk_aes_top                        | *abcsfiel | Columns shown in `/top` columns |
| efk_aes_online                     | *anl      | Columns shown in `/online` columns |
| efk_aes_assistans                  | *asdl     | Columns shown in `/assist` columns |
| efk_aes_level                      | *al       | Columns shown in `/level` columns |
| efk_aes_rank                       | bcs       | Columns shown in `/rankstats` columns |

Columns tags:<br/>
`*` - Rank<br/>
`a` - Name (only in `/top15`)<br/>
`b` - Kills<br/>
`c` - Deaths<br/>
`d` - Heal<br/>
`e` - Skill<br/>
`f` - Favorite Knife<br/>
`h` - Effectiveness<br/>
`l` - Level<br/>
`k` - K:D ratio<br/>
`n` - Online Time<br/>
`s` - Assists<br/>

> **Note:** The MOTD supports up to 1534 characters, and chat messages are limited to 192 characters. If output is cut off, reduce the number of displayed columns or players (e.g., limit `/top` to 10 entries).
</details>

### Hats
Hat configurations are stored in `addons/amxmodx/configs/efk_hats.json` (create the file if it does not exist). The syntax is similar to the [Hats plugin](https://github.com/Next21Team/Hats), but includes a `level` field to restrict access by player level.

Config example:
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
- Clone repository with submodules:
```bash
git clone --recurse-submodules https://github.com/Next21Team/EpicFunKnife.git
```
- Install dependencies and download latest assets: `npm i`

### Customize builder
Use `.amxxpack.json` configuration file

### Build project
`npm run build`

## Assets
Assets for the mod:
https://www.dropbox.com/scl/fi/4s941jrbeenkau96inph8/efk_assets.zip?rlkey=dth0ou65a4537jec7anubmolh&dl=1

## Special thanks

* [ChakkiSkrip](https://github.com/ChakkiSkrip)
* [AllanZed](https://github.com/AllanZed)
* [SUMY](https://github.com/SUMY-MAN)
* [Chrescoe1](https://github.com/Chrescoe1)
