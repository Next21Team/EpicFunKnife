#include <amxmodx>
#include <amxmisc>
#include <efk_core>

const TASKID_DISPLAY = 1;
const MESSAGE_MAX_LEN = 512;
const MAX_DISPLAY_TEAM_SIZE = 7;

new tableContentT[MESSAGE_MAX_LEN], tableContentCt[MESSAGE_MAX_LEN];

public plugin_init() {
	register_plugin("EFK: Damage table", "0.1", "ekke bea?");

	register_logevent("@on_round_start", 2, "1=Round_Start");
	register_logevent("@on_round_end", 2, "1=Round_End");
}

@on_round_start() {
	remove_task(TASKID_DISPLAY);
}

@on_round_end() {
	table_prepare();
	table_display();
	table_print_console();

	remove_task(TASKID_DISPLAY);
	set_task(1.0, "@task_display_table", TASKID_DISPLAY, .flags = "b");
}

@task_display_table() {
	table_display()
}

table_prepare() {
	new partT[MESSAGE_MAX_LEN], partCt[MESSAGE_MAX_LEN];
	table_format_part(1, partT);
	table_format_part(2, partCt);

	formatex(tableContentT, charsmax(tableContentT), "%s^n^n%s", partT, partCt);
	formatex(tableContentCt, charsmax(tableContentCt), "%s^n^n%s", partCt, partT);
}

public @sort_players_by_caused_damage(a, b) {
	return clamp(
		kc_player_get_caused_damage(b) - kc_player_get_caused_damage(a),
		-1, 1
	);
}

table_format_part(const iTeam, output[MESSAGE_MAX_LEN]) {
	new players[MAX_PLAYERS], num;

	for(new i = 1; i <= MaxClients; i++)
		if(is_user_connected(i) && get_user_team(i) == iTeam)
			players[num++] = i;

	if(!num)
		return;

	SortCustom1D(players, num, "@sort_players_by_caused_damage");
	formatex(output, charsmax(output), "[%s dmg]^n", iTeam == 2 ? "Blue" : "Red");

	if (num > MAX_DISPLAY_TEAM_SIZE)
		num = MAX_DISPLAY_TEAM_SIZE;

	for(new i, name[MAX_NAME_LENGTH], len, id; i < num; i++) {
		id = players[i];
		get_user_name(id, name, charsmax(name));
		len = strlen(name);
		if(len > 16)
			mb_strclip(name, len - 16);

		add(output, charsmax(output), fmt("%s — %d dmg^n", name, kc_player_get_caused_damage(id)));
	}
}

table_display() {
	set_hudmessage(255, 255, 255, 0.7, 0.2, 0, 0.0, 1.1, 0.0, 0.0, HUDCHANNEL_ABILITY);

	for(new id = 1; id <= MaxClients; id++) {
		if(is_user_connected(id))
			show_hudmessage(id, get_user_team(id) == 1 ? tableContentT : tableContentCt);
	}
}

table_print_console() {
	new partsT[36][32], partsCt[36][32];

	new totalPartsT = explode_string(tableContentT, "^n", partsT, sizeof(partsT), sizeof(partsT[]))
	new totalPartsCt = explode_string(tableContentCt, "^n", partsCt, sizeof(partsCt), sizeof(partsCt[]))

	for(new id = 1; id <= MaxClients; id++) {
		if(!is_user_connected(id))
			continue

		if(get_user_team(id) == 1) {
			client_print(id, print_console, "")
			for(new i; i < totalPartsT; i++) {
				client_print(id, print_console, partsT[i])
			}
			client_print(id, print_console, "")
		}
		else {
			client_print(id, print_console, "")
			for(new i; i < totalPartsCt; i++) {
				client_print(id, print_console, partsCt[i])
			}
			client_print(id, print_console, "")
		}
	}
}

mb_strclip(string[], clip, ending[] = "..") {
	if(clip <= 0) return

	new Stack:stack = CreateStack();
	new string_len = strlen(string);

	for(new i = 0, ch_size; i < string_len; ) {
		ch_size = _is_char_mb(string[i]);
		PushStackCell(stack, ch_size);

		i += ch_size;
	}

	new popped_chars_pos;
	new ending_len = strlen(ending);

	do {
		new ch_pos;
		PopStackCell(stack, ch_pos);
		popped_chars_pos += ch_pos;
	}
	while (popped_chars_pos < clip + ending_len)

	new len = string_len - popped_chars_pos;
	format(string[len], ending_len, ending);

	DestroyStack(stack);
}

_is_char_mb(ch) {
	return max(1, is_char_mb(ch));
}