#include <amxmodx>
#include <efk_const>

new const PLUGIN[] = "EFK: Radio Block"

public plugin_init()
{
	register_plugin(PLUGIN, EFK_VERSION, "Next21 Team")

	register_message(get_user_msgid("TextMsg"), "Message_TextMsg")
	register_message(get_user_msgid("SendAudio"), "Message_SendAudio")
}

public Message_TextMsg()
{
	if (get_msg_args() != 5)
		return PLUGIN_CONTINUE

	return check_message(5, "#Fire_in_the_hole")
}

public Message_SendAudio()
{
	return check_message(2, "%!MRAD_FIREINHOLE")
}

check_message(const iParam, const szString[])
{
	new szTemp[18]
	get_msg_arg_string(iParam, szTemp, charsmax(szTemp))

	return equal(szTemp, szString) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}
