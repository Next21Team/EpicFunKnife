#if defined _efk_utils_included
  #endinput
#endif
#define _efk_utils_included

#include <xs>

#define is_entity_player(%1)	(1<=%1&&%1<=MaxClients)

stock bool:boxes_intersect(Float:vMinsA[], Float:vMaxsA[], Float:vMinsB[], Float:vMaxsB[])
{
    return bool:!(
        vMinsB[0] > vMaxsA[0] ||
        vMinsB[1] > vMaxsA[1] ||
        vMinsB[2] > vMaxsA[2] ||
        vMaxsB[0] < vMinsA[0] ||
        vMaxsB[1] < vMinsA[1] ||
        vMaxsB[2] < vMinsA[2]
    )
}

stock calc_bbox(const Float:vDim[], const Float:mTr[][], Float:vMins[], Float:vMaxs[])
{
	new Float:x = vDim[0], Float:y = vDim[1], Float:z = vDim[2]

	new Float:verts[8][3]

	verts[0][0] = -x
	verts[0][1] = -y
	verts[0][2] = -z

	verts[1][0] = x
	verts[1][1] = -y
	verts[1][2] = -z

	verts[2][0] = -x
	verts[2][1] = y
	verts[2][2] = -z

	verts[3][0] = -x
	verts[3][1] = -y
	verts[3][2] = z

	verts[4][0] = -x
	verts[4][1] = y
	verts[4][2] = z

	verts[5][0] = x
	verts[5][1] = -y
	verts[5][2] = z

	verts[6][0] = x
	verts[6][1] = y
	verts[6][2] = -z

	verts[7][0] = x
	verts[7][1] = y
	verts[7][2] = z

	vMins[0] = vMins[1] = vMins[2] = 0.0
	vMaxs[0] = vMaxs[1] = vMaxs[2] = 0.0

	for (new i, Float:vPos[3]; i < 8; i++)
	{
		trans_vector(verts[i], mTr, vPos)
		x = vPos[0]; y = vPos[1]; z = vPos[2]

		if (x > vMaxs[0]) vMaxs[0] = x
		if (y > vMaxs[1]) vMaxs[1] = y
		if (z > vMaxs[2]) vMaxs[2] = z

		if (x < vMins[0]) vMins[0] = x
		if (y < vMins[1]) vMins[1] = y
		if (z < vMins[2]) vMins[2] = z
	}
}

stock calc_omni_direction(const Float:fYaw, const iButtons, Float:vDirection[])
{
	new Float:vAngles[3]
	vAngles[1] = fYaw

	new Float:vForwardDir[3], Float:vRightDir[3]
	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForwardDir)
	angle_vector(vAngles, ANGLEVECTOR_RIGHT, vRightDir)

	new Float:fForwardPower, Float:fRightPower
	if (iButtons & IN_FORWARD) fForwardPower += 1.0
	if (iButtons & IN_BACK) fForwardPower -= 1.0
	if (iButtons & IN_MOVERIGHT) fRightPower += 1.0
	if (iButtons & IN_MOVELEFT) fRightPower -= 1.0

	if (fForwardPower == 0.0 && fRightPower == 0.0)
		fForwardPower = 1.0

	xs_vec_mul_scalar(vForwardDir, fForwardPower, vForwardDir)
	xs_vec_mul_scalar(vRightDir, fRightPower, vRightDir)

	xs_vec_add(vForwardDir, vRightDir, vDirection)
	xs_vec_normalize(vDirection, vDirection)
}

stock Float:chance_to_koef(const Float:x)
{
	return 1 / (x / 100)
}

stock bool:check_back_stab(const Float:vAnglesA[3], const Float:vAnglesB[3])
{
	new Float:vForwardDirA[3], Float:vForwardDirB[3]
	angle_vector(vAnglesA, ANGLEVECTOR_FORWARD, vForwardDirA)
	angle_vector(vAnglesB, ANGLEVECTOR_FORWARD, vForwardDirB)

	vForwardDirA[2] = vForwardDirB[2] = 0.0
	xs_vec_normalize(vForwardDirA, vForwardDirA)
	xs_vec_normalize(vForwardDirB, vForwardDirB)

	return xs_vec_dot(vForwardDirA, vForwardDirB) > 0.8
}

stock Float:float_sqr(const Float:x)
{
	return x * x
}

stock float_swap(&Float:a, &Float:b)
{
	new Float:temp = a
	a = b
	b = temp
}

stock get_floor_origin(iEnt, Float:vStart[3], Float:vOrigin[3])
{
	new Float:vEnd[3]
	vEnd[0] = vStart[0]
	vEnd[1] = vStart[1]
	vEnd[2] = -8192.0

	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iEnt, 0)
	get_tr2(0, TR_vecEndPos, vOrigin)
}

stock get_speed_vector(const Float:vOriginA[3], const Float:vOriginB[3], Float:fSpeed, Float:vVelocity[3])
{
	vVelocity[0] = vOriginB[0] - vOriginA[0]
	vVelocity[1] = vOriginB[1] - vOriginA[1]
	vVelocity[2] = vOriginB[2] - vOriginA[2]

	new Float:fMul = floatsqroot(fSpeed*fSpeed / (vVelocity[0]*vVelocity[0] + vVelocity[1]*vVelocity[1] + vVelocity[2]*vVelocity[2]))

	vVelocity[0] *= fMul
	vVelocity[1] *= fMul
	vVelocity[2] *= fMul
}

stock inverse_matrix(const Float:mIn[][], Float:mOut[3][3])
{
	for (new i, j; i < 3; i++)
		for (j = 0; j < 3; j++)
			mOut[i][j] = mIn[j][i]
}

stock bool:is_player_slowed(iPlayer, Float:fDefSpeed)
{
	return kc_player_get_maxspeed(iPlayer) - floatmin(kc_player_get_powerspeed(iPlayer), 0.0) < fDefSpeed
}

stock bool:is_wall_between(Float:vStart[3], Float:vEnd[3], iEnt)
{
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iEnt, 0)

	new Float:fFraction
	get_tr2(0, TR_flFraction, fFraction)

	return fFraction != 1.0
}

stock Float:koef_to_chance(const Float:x)
{
	return 1 / x * 100
}

stock bool:line_intersects_box(Float:vStart[3], Float:vEnd[3], Float:vMin[3], Float:vMax[3], &Float:fDist=0.0)
{
	new Float:vDirection[3]
	xs_vec_sub(vEnd, vStart, vDirection)

	new Float:fTMin = 0.0
	new Float:fTMax = 1.0

	for (new i, Float:fT1, Float:fT2; i < 3; i++)
	{
		if (floatabs(vDirection[i]) < 0.000001)
		{
			if (vStart[i] < vMin[i] || vStart[i] > vMax[i])
				return false
		}
		else
		{
			fT1 = (vMin[i] - vStart[i]) / vDirection[i]
			fT2 = (vMax[i] - vStart[i]) / vDirection[i]

			if (fT1 > fT2)
				float_swap(fT1, fT2)

			if (fT1 > fTMin)
				fTMin = fT1

			if (fT2 < fTMax)
				fTMax = fT2

			fTMin = floatmax(fTMin, fT1)
			fTMax = floatmin(fTMax, fT2)

			if (fTMin > fTMax)
				return false
		}
	}

	new Float:vHitOrigin[3]
	xs_vec_add_scaled(vStart, vDirection, floatmax(0.0, fTMin), vHitOrigin)
	fDist = xs_vec_distance(vHitOrigin, vStart)

	return true
}

stock bool:point_in_cylinder(const Float:vIn[], const Float:vOrigin[],
	const Float:fRadius, const Float:fHeight, const Float:mInvTr[][])
{
	new Float:vPoint[3]
	xs_vec_sub(vIn, vOrigin, vPoint)
	trans_vector(vPoint, mInvTr, vPoint)

	new Float:fHalfHeight = fHeight * 0.5
	if (floatabs(vPoint[2]) > fHalfHeight)
		return false

	new Float:fDistSquar = float_sqr(vPoint[0]) + float_sqr(vPoint[1])
	return fDistSquar <= float_sqr(fRadius)
}

stock send_msg_BlinkAcct(iType,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	static iMsgBlinkAcct
	if (!iMsgBlinkAcct) iMsgBlinkAcct = get_user_msgid("BlinkAcct")

	message_begin_f(iDestType, iMsgBlinkAcct, vDestOrigin, iDestPlayer)
	write_byte(iType)
	message_end()
}

stock send_msg_Damage(iSave, iTake, iFlags, const Float:vOrigin[3],
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	static iMsgDamage
	if (!iMsgDamage) iMsgDamage = get_user_msgid("Damage")

	message_begin_f(iDestType, iMsgDamage, vDestOrigin, iDestPlayer)
	write_byte(iSave)
	write_byte(iTake)
	write_long(iFlags)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	message_end()
}

stock send_msg_Fog(Float:fDistance, const ivColor[3] = {0, 0, 0},
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	static iMsgFog
	if (!iMsgFog) iMsgFog = get_user_msgid("Fog")

	message_begin_f(iDestType, iMsgFog, vDestOrigin, iDestPlayer)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	write_long(_:(fDistance))
	message_end()
}

stock send_msg_ScreenFade(iDurration, iHold, iType, const ivColor[3] = {0, 0, 0}, iAlpha = 0,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	static iMsgScreenFade
	if (!iMsgScreenFade) iMsgScreenFade = get_user_msgid("ScreenFade")

	message_begin_f(iDestType, iMsgScreenFade, vDestOrigin, iDestPlayer)
	write_short(iDurration)
	write_short(iHold)
	write_short(iType)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	write_byte(iAlpha)
	message_end()
}

stock send_msg_ScreenShake(iAmplitude, iDuration, iFrequency,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	static iMsgScreenShake
	if (!iMsgScreenShake) iMsgScreenShake = get_user_msgid("ScreenShake")

	message_begin_f(iDestType, iMsgScreenShake, vDestOrigin, iDestPlayer)
	write_short(iAmplitude)
	write_short(iDuration)
	write_short(iFrequency)
	message_end()
}

stock send_msg_SetFOV(iValue, iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	static iMsgSetFOV
	if (!iMsgSetFOV) iMsgSetFOV = get_user_msgid("SetFOV")

	message_begin_f(iDestType, iMsgSetFOV, vDestOrigin, iDestPlayer)
	write_byte(iValue)
	message_end()
}

stock send_msg_StatusIcon(bool:bEnabled, const szIcon[], const ivColor[3] = {0, 0, 0},
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	static iMsgStatusIcon
	if (!iMsgStatusIcon) iMsgStatusIcon = get_user_msgid("StatusIcon")

	message_begin_f(iDestType, iMsgStatusIcon, vDestOrigin, iDestPlayer)
	write_byte(bEnabled)
	write_string(szIcon)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	message_end()
}

stock send_msg_TE_BEAMCYLINDER(const Float:vCenter[3], const Float:vAxis[3], pSprite,
	iStartFrame, iFrameRate, iLife, iWidth, iAmplitude, const ivColor[3] = {0, 0, 0}, iBrightness, iSpeed,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, vCenter[0])
	engfunc(EngFunc_WriteCoord, vCenter[1])
	engfunc(EngFunc_WriteCoord, vCenter[2])
	engfunc(EngFunc_WriteCoord, vAxis[0])
	engfunc(EngFunc_WriteCoord, vAxis[1])
	engfunc(EngFunc_WriteCoord, vAxis[2])
	write_short(pSprite)
	write_byte(iStartFrame)
	write_byte(iFrameRate)
	write_byte(iLife)
	write_byte(iWidth)
	write_byte(iAmplitude)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	write_byte(iBrightness)
	write_byte(iSpeed)
	message_end()
}

stock send_msg_TE_BEAMENTPOINT(iEnt, const Float:vOrigin[3], pSprite, iStartFrame, iFrameRate, iLife,
	iWidth, iAmplitude, const ivColor[3] = {0, 0, 0}, iBrightness, iSpeed,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BEAMENTPOINT)
	write_short(iEnt)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(pSprite)
	write_byte(iStartFrame)
	write_byte(iFrameRate)
	write_byte(iLife)
	write_byte(iWidth)
	write_byte(iAmplitude)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	write_byte(iBrightness)
	write_byte(iSpeed)
	message_end()
}

stock send_msg_TE_BEAMENTS(iEnt1, iEnt2, pSprite, iStartFrame, iFrameRate, iLife,
	iWidth, iAmplitude, const ivColor[3] = {0, 0, 0}, iBrightness, iSpeed,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BEAMENTS)
	write_short(iEnt1)
	write_short(iEnt2)
	write_short(pSprite)
	write_byte(iStartFrame)
	write_byte(iFrameRate)
	write_byte(iLife)
	write_byte(iWidth)
	write_byte(iAmplitude)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	write_byte(iBrightness)
	write_byte(iSpeed)
	message_end()
}

stock send_msg_TE_BEAMFOLLOW(iEnt, pSprite, iLife, iWidth, const ivColor[3], iBrightness,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BEAMFOLLOW)
	write_short(iEnt)
	write_short(pSprite)
	write_byte(iLife)
	write_byte(iWidth)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	write_byte(iBrightness)
	message_end()
}

stock send_msg_TE_BEAMPOINTS(const Float:vOrigin[3], const Float:vEndOrigin[3], pSprite,
	iStartFrame, iFrameRate, iLife, iWidth, iAmplitude, const ivColor[3] = {0, 0, 0}, iBrightness, iSpeed,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vEndOrigin[0])
	engfunc(EngFunc_WriteCoord, vEndOrigin[1])
	engfunc(EngFunc_WriteCoord, vEndOrigin[2])
	write_short(pSprite)
	write_byte(iStartFrame)
	write_byte(iFrameRate)
	write_byte(iLife)
	write_byte(iWidth)
	write_byte(iAmplitude)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	write_byte(iBrightness)
	write_byte(iSpeed)
	message_end()
}

stock send_msg_TE_BLOODSPRITE(const Float:vOrigin[3], pSprite1, pSprite2, iColor, iScale,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(pSprite1)
	write_short(pSprite2)
	write_byte(iColor)
	write_byte(iScale)
	message_end()
}

stock send_msg_TE_BLOODSTREAM(const Float:vOrigin[3], const Float:vDirection[3], iColor, iSpeed,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BLOODSTREAM)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vDirection[0])
	engfunc(EngFunc_WriteCoord, vDirection[1])
	engfunc(EngFunc_WriteCoord, vDirection[2])
	write_byte(iColor)
	write_byte(iSpeed)
	message_end()
}

stock send_msg_TE_BREAKMODEL(const Float:vOrigin[3], const Float:vSize[3], const Float:vVelocity[3],
	iRandVel, iModelIndex, iNum, iLife, iFlags,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vSize[0])
	engfunc(EngFunc_WriteCoord, vSize[1])
	engfunc(EngFunc_WriteCoord, vSize[2])
	engfunc(EngFunc_WriteCoord, vVelocity[0])
	engfunc(EngFunc_WriteCoord, vVelocity[1])
	engfunc(EngFunc_WriteCoord, vVelocity[2])
	write_byte(iRandVel)
	write_short(iModelIndex)
	write_byte(iNum)
	write_byte(iLife)
	write_byte(iFlags)
	message_end()
}

stock send_msg_TE_BUBBLES(const Float:vMins[3], const Float:vMaxs[3], Float:fHeight, pSprite, iNum, Float:fSpeed,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_BUBBLES)
	engfunc(EngFunc_WriteCoord, vMins[0])
	engfunc(EngFunc_WriteCoord, vMins[1])
	engfunc(EngFunc_WriteCoord, vMins[2])
	engfunc(EngFunc_WriteCoord, vMaxs[0])
	engfunc(EngFunc_WriteCoord, vMaxs[1])
	engfunc(EngFunc_WriteCoord, vMaxs[2])
	engfunc(EngFunc_WriteCoord, fHeight)
	write_short(pSprite)
	write_byte(iNum)
	engfunc(EngFunc_WriteCoord, fSpeed)
	message_end()
}

stock send_msg_TE_DECAL(const Float:vOrigin[3], iDecal, iEnt,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_DECAL)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_byte(iDecal)
	write_short(iEnt)
	message_end()
}

stock send_msg_TE_DLIGHT(const Float:vOrigin[3], iRadius, const ivColor[3], iLife, iDecayRate,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_byte(iRadius)
	write_byte(ivColor[0])
	write_byte(ivColor[1])
	write_byte(ivColor[2])
	write_byte(iLife)
	write_byte(iDecayRate)
	message_end()
}

stock send_msg_TE_EXPLOSION(const Float:vOrigin[3], pSprite, iScale, iFrameRate, iFlags,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(pSprite)
	write_byte(iScale)
	write_byte(iFrameRate)
	write_byte(iFlags)
	message_end()
}

stock send_msg_TE_FIREFIELD(const Float:vOrigin[3], iRadius, pSprite, iNum, iFlags, iDuration,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_FIREFIELD)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(iRadius)
	write_short(pSprite)
	write_byte(iNum)
	write_byte(iFlags)
	write_byte(iDuration)
	message_end()
}

stock send_msg_TE_IMPLOSION(const Float:vOrigin[3], const iRadius, const iCount, const iLife,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_IMPLOSION)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_byte(iRadius)
	write_byte(iCount)
	write_byte(iLife)
	message_end()
}

stock send_msg_TE_KILLBEAM(iEnt,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_KILLBEAM)
	write_short(iEnt)
	message_end()
}

stock send_msg_TE_KILLPLAYERATTACHMENTS(iPlayer,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_KILLPLAYERATTACHMENTS)
	write_byte(iPlayer)
	message_end()
}

stock send_msg_TE_LAVASPLASH(const Float:vOrigin[3],
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_LAVASPLASH)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	message_end()
}

stock send_msg_TE_MODEL(const Float:vOrigin[3], const Float:vVelocity[3], iAngle, iModelIndex, iSoundType, iLife,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vVelocity[0])
	engfunc(EngFunc_WriteCoord, vVelocity[1])
	engfunc(EngFunc_WriteCoord, vVelocity[2])
	write_angle(iAngle)
	write_short(iModelIndex)
	write_byte(iSoundType)
	write_byte(iLife)
	message_end()
}

stock send_msg_TE_PLAYERATTACHMENT(iPlayer, Float:fVOffset, iModelIndex, iLife,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(iPlayer)
	engfunc(EngFunc_WriteCoord, fVOffset)
	write_short(iModelIndex)
	write_short(iLife)
	message_end()
}

stock send_msg_TE_SMOKE(const Float:vOrigin[3], pSprite, iScale, iFrameRate,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(pSprite)
	write_byte(iScale)
	write_byte(iFrameRate)
	message_end()
}

stock send_msg_TE_SPARKS(const Float:vOrigin[3],
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	message_end()
}

stock send_msg_TE_SPRITE(const Float:vOrigin[3], pSprite, iScale, iBrightness,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(pSprite)
	write_byte(iScale)
	write_byte(iBrightness)
	message_end()
}

stock send_msg_TE_SPRITETRAIL(const Float:vStartOrigin[3], const Float:vEndOrigin[3], pSprite, iNum, iLife, iScale, iVelocity, iRandVel,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_SPRITETRAIL)
	engfunc(EngFunc_WriteCoord, vStartOrigin[0])
	engfunc(EngFunc_WriteCoord, vStartOrigin[1])
	engfunc(EngFunc_WriteCoord, vStartOrigin[2])
	engfunc(EngFunc_WriteCoord, vEndOrigin[0])
	engfunc(EngFunc_WriteCoord, vEndOrigin[1])
	engfunc(EngFunc_WriteCoord, vEndOrigin[2])
	write_short(pSprite)
	write_byte(iNum)
	write_byte(iLife)
	write_byte(iScale)
	write_byte(iVelocity)
	write_byte(iRandVel)
	message_end()
}

stock send_msg_TE_TELEPORT(const Float:vOrigin[3],
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_TELEPORT)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	message_end()
}

stock send_msg_TE_WORLDDECAL(const Float:vOrigin[3], iDecal,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	message_begin_f(iDestType, SVC_TEMPENTITY, vDestOrigin, iDestPlayer)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_byte(iDecal)
	message_end()
}

stock send_msg_WeaponList(const szClassName[], iPrimaryAmmoId, iPrimaryAmmoMaxAmount,
	iSecondaryAmmoId, iSecondaryAmmoMaxAmount, iSlotId, iNumberInSlot, iWeaponId, iFlags,
	iDestType = MSG_BROADCAST, const Float:vDestOrigin[3] = {0.0,0.0,0.0}, iDestPlayer = 0)
{
	static iMsgWeaponList
	if (!iMsgWeaponList) iMsgWeaponList = get_user_msgid("WeaponList")

	message_begin_f(iDestType, iMsgWeaponList, vDestOrigin, iDestPlayer)
	write_string(szClassName)
	write_byte(iPrimaryAmmoId)
	write_byte(iPrimaryAmmoMaxAmount)
	write_byte(iSecondaryAmmoId)
	write_byte(iSecondaryAmmoMaxAmount)
	write_byte(iSlotId)
	write_byte(iNumberInSlot)
	write_byte(iWeaponId)
	write_byte(iFlags)
	message_end()
}

stock trans_vector(const Float:vIn[], const Float:mTr[][], Float:vOut[])
{
	new Float:x = vIn[0], Float:y = vIn[1], Float:z = vIn[2]

	vOut[0] = mTr[0][0] * x + mTr[0][1] * y + mTr[0][2] * z
	vOut[1] = mTr[1][0] * x + mTr[1][1] * y + mTr[1][2] * z
	vOut[2] = mTr[2][0] * x + mTr[2][1] * y + mTr[2][2] * z
}
