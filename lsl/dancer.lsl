// Choreography Dancer Script v4.1
// Place inside each animesh dancer.
// Set the object DESCRIPTION to the dancer number (1-12).
//
// Positions are ABSOLUTE (relative to stage center / controller prim).
// On PLAY, the dancer teleports to its layer 0 position, then moves through layers.

integer CHOREO_CHANNEL = -9876543;

integer g_dancerNum = 1;
list g_positions = [];    // stored as [vector, float travel, float sleep, ...] per layer
integer g_layerCount = 0;
vector g_startPos;
rotation g_startRot;

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

        llListen(CHOREO_CHANNEL, "", "", "");
        llOwnerSay("Dancer " + (string)g_dancerNum + " ready at " + (string)g_startPos);
    }

    listen(integer channel, string name, key id, string message)
    {
        // === PLAY: teleport to layer 0 position, then run keyframed motion ===
        if (llSubStringIndex(message, "PLAY|") == 0)
        {
            if (g_layerCount < 1) return;

            // Parse center position (controller prim location = stage center)
            list playParts = llParseString2List(message, ["|"], []);
            vector center = (vector)llList2String(playParts, 1);

            // Teleport to layer 0 absolute position
            vector pos0 = llList2Vector(g_positions, 0);
            float sleep0 = llList2Float(g_positions, 2);
            vector targetStart = center + pos0;

            llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
            llSetRegionPos(targetStart);

            // Build keyframes for the choreography
            list keyframes = [];
            vector prevPos = pos0;

            // Sleep at starting position
            if (sleep0 > 0.1)
                keyframes += [ZERO_VECTOR, sleep0];

            // Move through subsequent layers
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

            llOwnerSay("Dancer " + (string)g_dancerNum + " playing from " + (string)targetStart);
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
            llOwnerSay("Dancer " + (string)g_dancerNum + " reset");
            return;
        }

        // === LOAD: store choreography data ===
        // Format: DANCER|num|x,y,z,travel,sleep|x,y,z,travel,sleep|...
        // Positions are absolute (relative to stage center)
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

        llOwnerSay("Dancer " + (string)g_dancerNum + ": loaded " + (string)g_layerCount + " layers");
    }

    on_rez(integer param)
    {
        llResetScript();
    }

    changed(integer change)
    {
        if (change & CHANGED_REGION_START)
        {
            g_startPos = llGetPos();
            g_startRot = llGetRot();
            llOwnerSay("Dancer " + (string)g_dancerNum + " re-anchored after restart");
        }
    }
}
