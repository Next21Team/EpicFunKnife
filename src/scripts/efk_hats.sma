#include <amxmodx>
#include <amxmisc>
#include <time>
#include <nvault>
#include <json>
#include <reapi>
#include <efk_core>

new const PLUGIN[] = "EFK: Hats"

new const GAME_TAG[] = EFK_GAME_TAG

new const HATS_PATH[]           = "models/next21_hats"

new const CHAT_SET_HAT_FORMAT[]	= "^4[%s] ^1%L ^4%s"

new const _SOUND_GUI_CLICK[]	= SOUND_GUI_CLICK
new const _SOUND_GUI_ERROR[]	= SOUND_GUI_ERROR

#define MAX_HATS 			    64
#define VAULT_DAYS 		        30

#define MAXSTUDIOBODYPARTS		32
#define NAME_LEN 		        64

new
	g_szHatModels[MAX_HATS][32],
	g_szHatNames[MAX_HATS][NAME_LEN],
	g_cHatTypes[MAX_HATS], // s - skin only, b - bodies only, c - bodies and skin, n - normal hat
	g_iHatSkinsNums[MAX_HATS],
	g_iHatBodiesNums[MAX_HATS],
	g_iHatLevels[MAX_HATS],
	g_iHatModelIds[MAX_HATS],
	g_szHatBodyNames[MAX_HATS][MAXSTUDIOBODYPARTS][NAME_LEN],
	g_iMenuHatId[MAX_PLAYERS + 1],
	g_nvHats,
	g_iTotalHats

public plugin_precache()
{
	new szCfgDir[32], szHatFile[64], szCurrFile[128]
	get_configsdir(szCfgDir, charsmax(szCfgDir))
	formatex(szHatFile, charsmax(szHatFile), "%s/efk_hats.json", szCfgDir)

	if (load_hats(szHatFile))
	{
		for (new i = 0; i < g_iTotalHats; i++)
		{
			formatex(szCurrFile, charsmax(szCurrFile), "%s/%s", HATS_PATH, g_szHatModels[i])
			g_iHatModelIds[i] = precache_model(szCurrFile)
		}

		server_print("[%s] Loaded %i hats", PLUGIN, g_iTotalHats)
	}
	else
		server_print("[%s] Failed load %s", PLUGIN, szHatFile)
}

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	register_dictionary("efk_hats.txt")

	register_clcmd("say /hats", "clcmd_hats", -1, "Shows Hats menu")
	register_clcmd("say_team /hats", "clcmd_hats", -1, "Shows Hats menu")
	register_clcmd("hats", "clcmd_hats", -1, "Shows Hats menu")

	kc_register_menu_item("HATS_MENUNAME", "hats_show_menu")
}

public plugin_end()
{
	nvault_close(g_nvHats)
}

public plugin_cfg()
{
	g_nvHats = nvault_open("next21_hat")

	if (g_nvHats == INVALID_HANDLE)
		set_fail_state("[%s] error opening hats nVault!", PLUGIN)

	nvault_prune(g_nvHats, 0, get_systime() - (SECONDS_IN_DAY * VAULT_DAYS))
}

public client_authorized(iPlayer)
{
	static szKey[24], szValue[128]
	get_user_authid(iPlayer, szKey, charsmax(szKey))
	nvault_get(g_nvHats, szKey, szValue, charsmax(szValue))

	new iHatId = -1, iPartId
	if (!szValue[0])
		goto set_hat_and_return

	nvault_touch(g_nvHats, szKey)

	static szHatModel[120], szHatPart[5]
	split(szValue, szHatModel, charsmax(szHatModel), szHatPart, charsmax(szHatPart), "|")

	if (equal(szHatModel, "{NULL}"))
		goto set_hat_and_return

	for (new i = 0; i < g_iTotalHats; i++)
	{
		if (equal(szHatModel, g_szHatModels[i]))
		{
			iHatId = i
			iPartId = str_to_num(szHatPart)
			goto set_hat_and_return
		}
	}

	set_hat_and_return:
	set_hat(iPlayer, iHatId, iPartId)
}

public clcmd_hats(iPlayer)
{
	if (!is_user_connected(iPlayer))
		return PLUGIN_HANDLED

	hats_show_menu_ex(iPlayer)
	return PLUGIN_HANDLED
}

public hats_show_menu(iPlayer)
{
	hats_show_menu_ex(iPlayer)
	return PLUGIN_CONTINUE
}

hats_show_menu_ex(iPlayer, iPage=0)
{
	new szItemPrefix[16], szItemPostfix[8]
	new iMenu = menu_create(fmt("\yHats Menu [\r%s\y]", GAME_TAG), "hats_handler_menu")

	menu_additem(iMenu, fmt("\r%L", iPlayer, "HATS_MENU_REMOVE"))

	for (new i; i < g_iTotalHats; i++)
	{
		szItemPrefix[0] = 0
		szItemPostfix[0] = 0

		if (g_iHatLevels[i])
			formatex(szItemPrefix, charsmax(szItemPrefix), "\r[%i lvl] ", g_iHatLevels[i])

		if (g_cHatTypes[i])
			formatex(szItemPostfix, charsmax(szItemPostfix), " \y>>")

		menu_additem(iMenu, fmt("%s\w%s%s", szItemPrefix, g_szHatNames[i], szItemPostfix))
	}

	set_menu_common_prop(iMenu, iPlayer)

	menu_display(iPlayer, iMenu, iPage)
	return PLUGIN_HANDLED
}

hats_show_skins_menu(iPlayer)
{
	new iHatId = g_iMenuHatId[iPlayer]
	new iMenu = menu_create(fmt("\yHat Shins Menu [\r%s\y]", GAME_TAG), "hats_handler_submenu")

	for (new i; i < g_iHatSkinsNums[iHatId]; i++)
		menu_additem(iMenu, g_szHatBodyNames[iHatId][i])

	set_menu_common_prop(iMenu, iPlayer)

	menu_display(iPlayer, iMenu)
	return PLUGIN_HANDLED
}

hats_show_bodies_menu(iPlayer)
{
	new iHatId = g_iMenuHatId[iPlayer]
	new iMenu = menu_create(fmt("\yHat Models Menu [\r%s\y]", GAME_TAG), "hats_handler_submenu")

	for (new i; i < g_iHatBodiesNums[iHatId]; i++)
		menu_additem(iMenu, g_szHatBodyNames[iHatId][i])

	set_menu_common_prop(iMenu, iPlayer)

	menu_display(iPlayer, iMenu)
	return PLUGIN_HANDLED
}

public hats_handler_menu(iPlayer, iMenu, iItem)
{
	if (iItem == MENU_EXIT)
	{
		menu_destroy(iMenu)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	new iHatId = iItem - 1

	// Remove hat
	if (!iItem)
	{
		menu_destroy(iMenu)
		set_hat(iPlayer, -1, 0, true)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	new iPage = floatround((iItem / 7.0), floatround_floor)

	if (g_iHatLevels[iHatId] > kc_player_get_level(iPlayer))
	{
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)
		client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L",
			GAME_TAG, iPlayer, "HATS_NEED_LEVEL", g_iHatLevels[iHatId])
		menu_display(iPlayer, iMenu, iPage)
		return PLUGIN_HANDLED
	}

	if (g_cHatTypes[iHatId])
	{
		menu_destroy(iMenu)
		g_iMenuHatId[iPlayer] = iHatId
		switch (g_cHatTypes[iHatId])
		{
			case 's': hats_show_skins_menu(iPlayer)
			case 'b', 'c': hats_show_bodies_menu(iPlayer)
		}

		return PLUGIN_HANDLED
	}

	if (set_hat(iPlayer, iHatId, 0, true) != NULLENT)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
	else
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)

	menu_display(iPlayer, iMenu, iPage)

	return PLUGIN_HANDLED
}

public hats_handler_submenu(iPlayer, iMenu, iItem)
{
	new iHatId = g_iMenuHatId[iPlayer]
	menu_destroy(iMenu)
	hats_show_menu_ex(iPlayer, floatround(((iHatId + 1) / 7.0), floatround_floor))

	if (iItem == MENU_EXIT)
	{
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
		return PLUGIN_HANDLED
	}

	if (set_hat(iPlayer, iHatId, iItem, true) != NULLENT)
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_CLICK)
	else
		client_cmd(iPlayer, "spk %s", _SOUND_GUI_ERROR)

	return PLUGIN_HANDLED
}

set_menu_common_prop(iMenu, iLangId)
{
	menu_setprop(iMenu, MPROP_NEXTNAME, fmt("%L", iLangId, "MENU_NEXT"))
	menu_setprop(iMenu, MPROP_BACKNAME, fmt("%L", iLangId, "MENU_BACK"))
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", iLangId, "MENU_EXIT"))
}

set_hat(iPlayer, iHatId, iPartId=0, bool:bSaveData=false)
{
	new iSkin, iBody

	if (iHatId == -1)
	{
		if (bSaveData)
		{
			client_print_color(iPlayer, print_team_default, "^4[%s] ^1%L", GAME_TAG, iPlayer, "HATS_REMOVE")

			new szKey[24]
			get_user_authid(iPlayer, szKey, charsmax(szKey))
			nvault_set(g_nvHats, szKey, "{NULL}|0")
		}

		kc_player_set_hat(iPlayer, -1)

		return NULLENT
	}

	switch (g_cHatTypes[iHatId])
	{
		case 's':
		{
			iSkin = iPartId
			iBody = 0
			if (bSaveData)
			{
				client_print_color(iPlayer, print_team_default, CHAT_SET_HAT_FORMAT,
					GAME_TAG, iPlayer, "HATS_SET", g_szHatBodyNames[iHatId][iPartId])
			}
		}
		case 'b':
		{
			iSkin = 0
			iBody = iPartId
			if (bSaveData)
			{
				client_print_color(iPlayer, print_team_default, CHAT_SET_HAT_FORMAT,
					GAME_TAG, iPlayer, "HATS_SET", g_szHatBodyNames[iHatId][iPartId])
			}
		}
		case 'c':
		{
			iSkin = iPartId
			iBody = iPartId
			if (bSaveData)
			{
				client_print_color(iPlayer, print_team_default, CHAT_SET_HAT_FORMAT,
					GAME_TAG, iPlayer, "HATS_SET", g_szHatBodyNames[iHatId][iPartId])
			}
		}
		default:
		{
			iSkin = 0
			iBody = 0
			if (bSaveData)
			{
				client_print_color(iPlayer, print_team_default, CHAT_SET_HAT_FORMAT,
					GAME_TAG, iPlayer, "HATS_SET", g_szHatNames[iHatId])
			}
		}
	}

	if (bSaveData)
	{
		new szKey[24]
		get_user_authid(iPlayer, szKey, charsmax(szKey))
		nvault_set(g_nvHats, szKey, fmt("%s|%i", g_szHatModels[iHatId], iPartId))
	}

	kc_player_set_hat(iPlayer, g_iHatModelIds[iHatId], iBody, iSkin)

	return kc_player_get_hat_ent(iPlayer)
}

bool:load_hats(const szHatFile[])
{
	new JSON:jsonRoot = json_parse(szHatFile, true)
	if (jsonRoot == Invalid_JSON)
		return false

	g_iTotalHats = 0

	new szCurrentFile[256], szHatModel[NAME_LEN], szTag[2], cTag, iLevel

	new iHatsNum = json_object_get_count(jsonRoot)
	for (new i, JSON:jsonHat, JSON:jsonHatItems; i < iHatsNum; i++)
	{
		jsonHat = json_object_get_value_at(jsonRoot, i)
		json_object_get_string(jsonHat, "model", szHatModel, charsmax(szHatModel))
		formatex(szCurrentFile, charsmax(szCurrentFile), "%s/%s", HATS_PATH, szHatModel)

		if (!file_exists(szCurrentFile))
		{
			json_free(jsonHat)
			server_print("[%s] Failed to precache %s", PLUGIN, szCurrentFile)
			continue
		}

		json_object_get_name(jsonRoot, i, g_szHatNames[g_iTotalHats], NAME_LEN - 1)
		iLevel = json_object_get_number(jsonHat, "level")
		json_object_get_string(jsonHat, "tag", szTag, charsmax(szTag))
		cTag = szTag[0]

		new iSkinsNum = 1, iBodiesNum = 1
		if (cTag == 's' || cTag == 'b' || cTag == 'c')
			parse_submodel_names(szCurrentFile, g_iTotalHats, iSkinsNum, iBodiesNum)

		validate_hat_tag(cTag, iSkinsNum, iBodiesNum)
		if (cTag == 's')
			set_hat_default_skin_names(g_iTotalHats, g_szHatNames[g_iTotalHats], iSkinsNum)

		new iPartsNum = max(iSkinsNum, iBodiesNum)
		jsonHatItems = json_object_get_value(jsonHat, "items")
		if (jsonHatItems != Invalid_JSON)
		{
			iPartsNum = min(iPartsNum, json_object_get_count(jsonRoot))
			for (new j; j < iPartsNum; j++)
			{
				json_array_get_string(jsonHatItems, j,
					g_szHatBodyNames[g_iTotalHats][j], NAME_LEN - 1)
			}
			json_free(jsonHatItems)
		}

		json_free(jsonHat)

		copy(g_szHatModels[g_iTotalHats], NAME_LEN - 1, szHatModel)
		g_cHatTypes[g_iTotalHats] = cTag
		g_iHatSkinsNums[g_iTotalHats] = iSkinsNum
		g_iHatBodiesNums[g_iTotalHats] = iBodiesNum
		g_iHatLevels[g_iTotalHats] = iLevel

		if (++g_iTotalHats == MAX_HATS)
		{
			server_print("[%s] Reached hat limit", PLUGIN)
			break
		}
	}

	json_free(jsonRoot)
	return true
}

parse_submodel_names(const szModelPath[], iHatId, &iSkinsNum, &iBodiesNum)
{
	new studiomodel = fopen(szModelPath, "rb"),
		bodypartindex, numbodyparts, nummodels

	fseek(studiomodel, 196, SEEK_SET)
	fread(studiomodel, iSkinsNum, BLOCK_INT)

	fseek(studiomodel, 204, SEEK_SET)
	fread(studiomodel, numbodyparts, BLOCK_INT)
	fread(studiomodel, bodypartindex, BLOCK_INT)

	fseek(studiomodel, bodypartindex, SEEK_SET)
	for (new i = 0, j; i < numbodyparts; i++)
	{
		fseek(studiomodel, 64, SEEK_CUR)
		fread(studiomodel, nummodels, BLOCK_INT)
		fseek(studiomodel, 4, SEEK_CUR)
		new modelindex; fread(studiomodel, modelindex, BLOCK_INT)

		if (nummodels > iBodiesNum)
		{
			iBodiesNum = nummodels

			new nextpos = ftell(studiomodel)
			fseek(studiomodel, modelindex, SEEK_SET)
			for (j = 0; j < nummodels; j++)
			{
				fread_blocks(studiomodel, g_szHatBodyNames[iHatId][j], NAME_LEN, BLOCK_CHAR)
				fseek(studiomodel, 48, SEEK_CUR)
			}
			fseek(studiomodel, nextpos, SEEK_SET)
		}
	}
	fclose(studiomodel)

	// There may be more skins in the studiomodel, but they may not fit into the array
	iSkinsNum = min(iSkinsNum, MAXSTUDIOBODYPARTS)
}

set_hat_default_skin_names(iHatId, const szHatName[], iSkinsNum)
{
	for (new i; i < iSkinsNum; i++)
		formatex(g_szHatBodyNames[iHatId][i], NAME_LEN - 1, "%s (skin %i)", szHatName, i + 1)
}

validate_hat_tag(&cTag, iSkinsNum, iBodiesNum)
{
	switch (cTag)
	{
		case 's': if (iSkinsNum <= 1) cTag = 0
		case 'b': if (iBodiesNum <= 1) cTag = 0
		case 'c': if (iBodiesNum <= 1) cTag = iSkinsNum > 1 ? 's' : 0
		default: cTag = 0
	}
}
