// Avatar Mover Script v1.0
// Place inside each mover prim. Set object Description to dancer number (1-12).
// Avatars sit on this prim to join the choreography.
// Movement logic mirrors dancer.lsl; animation is handled by slot scripts in the controller.

integer AVATAR_CHANNEL = -9876544;

integer g_dancerNum = 1;
list g_positions = [];       // [vector, float travel, float sleep, ...] per layer
integer g_layerCount = 0;
vector g_startPos;
rotation g_startRot;
key g_sittingAvatar = NULL_KEY;

default
{
    state_entry()
    {
        g_dancerNum = (integer)llGetObjectDesc();
        if (g_dancerNum < 1 || g_dancerNum > 12)
        {
            g_dancerNum = 1;
            llOwnerSay("WARNING: Set object description to dancer number (1-12). Defaulting to 1.");
        }

        g_startPos = llGetPos();
        g_startRot = llGetRot();

        // Sit target so avatars can sit on this prim
        llSitTarget(<0.0, 0.0, 0.5>, ZERO_ROTATION);

        llListen(AVATAR_CHANNEL, "", "", "");
        llOwnerSay("Mover " + (string)g_dancerNum + " ready at " + (string)g_startPos);
    }

    listen(integer channel, string name, key id, string message)
    {
        // === PLAY: teleport to layer 0 position, then run keyframed motion ===
        if (llSubStringIndex(message, "PLAY|") == 0)
        {
            if (g_layerCount < 1) return;

            list playParts = llParseString2List(message, ["|"], []);
            vector center = (vector)llList2String(playParts, 1);

            vector pos0 = llList2Vector(g_positions, 0);
            float sleep0 = llList2Float(g_positions, 2);
            vector targetStart = center + pos0;

            llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
            llSetRegionPos(targetStart);

            list keyframes = [];
            vector prevPos = pos0;

            if (sleep0 > 0.1)
                keyframes += [ZERO_VECTOR, sleep0];

            integer i;
            for (i = 1; i < g_layerCount; i++)
            {
                integer base = i * 3;
                vector pos = llList2Vector(g_positions, base);
                float travel = llList2Float(g_positions, base + 1);
                float sleep  = llList2Float(g_positions, base + 2);

                vector delta = pos - prevPos;
                float moveTime = travel;
                if (moveTime < 0.15) moveTime = 0.15;
                keyframes += [delta, moveTime];

                if (sleep > 0.1)
                    keyframes += [ZERO_VECTOR, sleep];

                prevPos = pos;
            }

            if (keyframes != [])
                llSetKeyframedMotion(keyframes, [KFM_MODE, KFM_FORWARD, KFM_DATA, KFM_TRANSLATION]);

            llOwnerSay("Mover " + (string)g_dancerNum + " playing from " + (string)targetStart);
            return;
        }

        // === STOP ===
        if (message == "STOP")
        {
            llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
            return;
        }

        // === RESET: return to original position ===
        if (message == "RESET")
        {
            llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
            llSetRegionPos(g_startPos);
            llSetRot(g_startRot);
            g_positions = [];
            g_layerCount = 0;
            llOwnerSay("Mover " + (string)g_dancerNum + " reset");
            return;
        }

        // === LOAD: store choreography data ===
        // Format: DANCER|num|x,y,z,travel,sleep|x,y,z,travel,sleep|...
        if (llSubStringIndex(message, "DANCER|") != 0) return;

        list parts = llParseString2List(message, ["|"], []);
        integer num = (integer)llList2String(parts, 1);
        if (num != g_dancerNum) return;

        g_positions = [];
        g_layerCount = 0;
        integer count = llGetListLength(parts);
        integer i;

        for (i = 2; i < count; i++)
        {
            list seg = llParseString2List(llList2String(parts, i), [","], []);
            vector pos = <(float)llList2String(seg, 0),
                          (float)llList2String(seg, 1),
                          (float)llList2String(seg, 2)>;
            float travel = (float)llList2String(seg, 3);
            float sleep  = (float)llList2String(seg, 4);

            g_positions += [pos, travel, sleep];
            g_layerCount++;
        }

        llOwnerSay("Mover " + (string)g_dancerNum + ": loaded " + (string)g_layerCount + " layers");
    }

    changed(integer change)
    {
        // Avatar sit/unsit detection
        if (change & CHANGED_LINK)
        {
            key sitting = llAvatarOnSitTarget();
            if (sitting != NULL_KEY && g_sittingAvatar == NULL_KEY)
            {
                // Avatar sat down
                g_sittingAvatar = sitting;
                llRegionSay(AVATAR_CHANNEL, "AVATAR_SIT|" + (string)g_dancerNum + "|" + (string)g_sittingAvatar);
                llOwnerSay("Mover " + (string)g_dancerNum + ": " + llKey2Name(g_sittingAvatar) + " seated");
            }
            else if (sitting == NULL_KEY && g_sittingAvatar != NULL_KEY)
            {
                // Avatar stood up
                llRegionSay(AVATAR_CHANNEL, "AVATAR_UNSIT|" + (string)g_dancerNum);
                llOwnerSay("Mover " + (string)g_dancerNum + ": " + llKey2Name(g_sittingAvatar) + " unseated");
                g_sittingAvatar = NULL_KEY;
            }
        }

        // Region restart: re-anchor position
        if (change & CHANGED_REGION_START)
        {
            g_startPos = llGetPos();
            g_startRot = llGetRot();
            llOwnerSay("Mover " + (string)g_dancerNum + " re-anchored after restart");
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}
