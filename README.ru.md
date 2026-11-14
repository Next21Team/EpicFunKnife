<p align="right"><a href="README.md">English</a> | <b>Русский</b></p>

# Epic Fun Knife

**Epic Fun Knife** — это мод режима Knife Arena для Counter-Strike 1.6, в котором каждый нож обладает уникальными способностями и собственным стилем игры. Дополненный вспомогательными предметами, мод превращает бои на ножах в динамичные и непредсказуемые сражения, где ценятся креативность, командная работа и быстрая реакция.

[![Epic Fun Knife](https://img.youtube.com/vi/nRDhHmKucS0/0.jpg)](https://youtu.be/nRDhHmKucS0)

[Видео](https://youtu.be/nRDhHmKucS0)

Подробное описание ножей и других игровых механик доступно в разделе [Wiki](https://github.com/Next21Team/EpicFunKnife/wiki/Home-ru-RU).

## Управление

- **MOUSE2 (attack2)** – Активировать основную способность
- **E (use)** – Активировать вторую способность
- **R (reload)** – Активировать третью способность
- **F (impulse 100)** – Активировать четвертую способность
- **T (impulse 201)** – Переключить активацию основной способности ножа на кнопку MOUSE2
- **M (chooseteam)** – Открыть главное меню
- **Z (radio1)** – Открыть меню выбора ножей
- **X (radio2)** или **N (nightvision)** – Открыть меню магазина предметов
- **G (drop)** – Открыть меню инвентаря
- **C (radio3)** – Быстрое переключение камеры

## Список плагинов

Мод имеет модульную архитектуру. Вы можете отключить ненужные плагины в файле `addons/amxmodx/configs/plugins-efk.ini`, за исключением обязательного ядра `efk_core.amxx`. Ниже приведено краткое описание каждого плагина.

<details>
<summary>Развернуть</summary>

| Плагин                             | Описание                                    |
| :--------------------------------- | :--------------------------------------------- |
| efk_core.amxx                      | Основной модуль, содержащий главную игровую логику |
| efk_unprecacher.amxx               | Удаляет неиспользуемые стандартные ресурсы во избежание превышения лимитов прекэша |
| efk_knife_*.amxx                   | Плагин ножа |
| efk_item_*.amxx                    | Плагин предмета |
| efk_statsx_sql.amxx                | Управляет статистикой игроков и сохраняет её в базу данных |
| efk_statsx_aes.amxx                | Реализует команды статистики, такие как `/top15`, `/rankstats` и др. |
| efk_balancer.amxx                  | Автоматически балансирует команды по количеству игроков и уровню навыка |
| efk_deathmatch.amxx                | Динамичный игровой режим с возрождениями и сужающейся зоной. Команда с наибольшим количеством убийств в конце раунда получает иммунитет к зоне; проигравшая команда теряет возможность возрождаться |
| efk_hats.amxx                      | Включает кастомизацию шапок |
| efk_presents.amxx                  | Случайный шанс выпадения подарка со случайным предметом после убийства врага |
| efk_dominations.amxx               | Система превосходства (доминирования), вдохновленная Team Fortress 2 |
| efk_duels.amxx                     | Система дуэлей, вдохновленная Team Fortress 2 |
| efk_sayme.amxx                     | Добавляет чат-команды `/me` и `/hp` |
| efk_damage_table.amxx              | Отображает топ игроков по нанесенному урону в конце раунда |
| efk_radioblock.amxx                | Блокирует радиокоманды «Fire in the hole» |
| efk_nextclient_features.amxx       | Добавляет специальные визуальные эффекты для пользователей NextClient |
| addon_floating_damage.amxx         | Отображение нанесенного урона |
| next21_save_spec_money.amxx        | Сохраняет деньги игрока при переходе в команду наблюдателей |
</details>

## Настройка

### Статистика

Мод использует модифицированную версию CSStatsX SQL для управления статистикой игроков, реализованную в `efk_statsx_sql.amxx` и `efk_statsx_aes.amxx`. Используйте следующие квары для её настройки:

<details>
<summary>Развернуть</summary>

| CVar                               | По умолчанию | Описание                                       |
| :--------------------------------- | :----------: | :--------------------------------------------- |
| efk_statsx_host                    | localhost    | Адрес хоста MySQL |
| efk_statsx_user                    | root         | Имя пользователя MySQL |
| efk_statsx_pass                    |              | Пароль MySQL |
| efk_statsx_db                      | amxx         | Имя базы данных (MySQL или SQLite) |
| efk_statsx_table                   | efkstats     | Имя таблицы в базе данных |
| efk_statsx_type                    | sqlite       | Тип базы данных (`mysql` или `sqlite`) |
| efk_statsx_create_db               | 1            | Создавать таблицу, если она не существует |
| efk_statsx_rankbots                | 0            | Записывать статистику для ботов |
| efk_statsx_update                  | -1           | Способ обновления статистики игроков в базе данных<br/>`-2` при смерти и отключении<br/>`-1` в конце раунда и при отключении<br/>`0` при отключении<br/>`> 0` каждые указанные секунды и при отключении |
| efk_statsx_rankformula             | 4            | Формула расчета ранга<br/>`0` убийства - смерти<br/>`1` убийства<br/>`2` скилл<br/>`3` время в игре<br/>`4` убийства + помощь / 3<br/>`5` помощь |
| efk_statsx_knives                  | 1            | Включить статистику по ножам |
| efk_statsx_autoclear               | 0            | Автоматически удалять неактивных игроков из базы данных |
| efk_statsx_cachetime               | -1           | Использовать кэш для get_stats<br/>`-1` обновлять в конце раунда или во время csstats_sql_update<br/>`0` отключить кэш |
| efk_statsx_autoclear_day           | 0            | Автоматически очищать всю статистику в определенный день |
| efk_aes_top                        | *abcsfiel    | Столбцы, отображаемые в `/top` |
| efk_aes_online                     | *anl         | Столбцы, отображаемые в `/online` |
| efk_aes_assistans                  | *asdl        | Столбцы, отображаемые в `/assist` |
| efk_aes_level                      | *al          | Столбцы, отображаемые в `/level` |
| efk_aes_rank                       | bcs          | Столбцы, отображаемые в `/rankstats` |
| efk_aes_xp_step                    | 100          | Количество очков, необходимое для достижения следующего уровня |
| efk_aes_xp_scale                   | 1.0          | Дополнительный множитель необходимых очков за уровень, применяемый к базовому значению `efk_aes_xp_step` при каждом повышении уровня. Например, при `efk_aes_xp_step 100` и `efk_aes_xp_scale 0.5` для достижения 1-го уровня потребуется 100 очков, 2-го уровня — 250 очков (100 + (100 + 100 * 1 * 0.5)), 3-го уровня — 450 очков (250 + (100 + 100 * 2 * 0.5)) и так далее. При `efk_aes_xp_scale 0.0` множитель отсутствует, и для каждого уровня потребуется ровно 100 очков |

Теги столбцов:<br/>
`*` - Ранг<br/>
`a` - Имя (только в `/top15`)<br/>
`b` - Убийства<br/>
`c` - Смерти<br/>
`d` - Лечение<br/>
`e` - Скилл<br/>
`f` - Любимый нож<br/>
`h` - Эффективность<br/>
`l` - Уровень<br/>
`k` - Соотношение У/С (K:D)<br/>
`n` - Время в игре<br/>
`s` - Помощь в убийствах<br/>

> **Примечание:** Окно MOTD поддерживает до 1534 символов, а сообщения в чате ограничены 192 символами. Если вывод обрезается, уменьшите количество отображаемых столбцов или игроков (например, ограничьте команду `/top` 10 записями).
</details>

### Шапки
Конфигурации шапок хранятся в файле `addons/amxmodx/configs/efk_hats.json` (создайте файл, если он отсутствует). Синтаксис аналогичен [плагину Hats](https://github.com/Next21Team/Hats), но включает поле `level` для ограничения доступа по уровню игрока.

Пример конфигурации:
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

## Требования
- [Metamod-R](https://github.com/theAsmodai/metamod-r) + [ReHLDS](https://github.com/dreamstalker/rehlds) or [Metamod-P](https://github.com/Bots-United/metamod-p)
- [RegameDLL](https://github.com/s1lentq/ReGameDLL_CS)
- [Amx Mod X 1.9.0+](https://www.amxmodx.org/downloads-new.php)
- [ReAPI](https://github.com/s1lentq/reapi)
- [NextClientServerApi](https://github.com/CS-NextClient/NextClientServerApi)

## Развертывание
- Клонируйте репозиторий с подмодулями:
```bash
git clone --recurse-submodules https://github.com/Next21Team/EpicFunKnife.git
```
- Установите зависимости и загрузите последние ассеты: `npm i`

### Настройка сборки
Используйте конфигурационный файл `.amxxpack.json`

### Сборка проекта
`npm run build`

## Ассеты
Ассеты мода:
https://www.dropbox.com/scl/fi/4s941jrbeenkau96inph8/efk_assets.zip?rlkey=dth0ou65a4537jec7anubmolh&dl=1

## Особая благодарность

* [ChakkiSkrip](https://github.com/ChakkiSkrip)
* [AllanZed](https://github.com/AllanZed)
* [Razavik](https://github.com/Razavik)
* [SUMY](https://github.com/SUMY-MAN)
* [Chrescoe1](https://github.com/Chrescoe1)
