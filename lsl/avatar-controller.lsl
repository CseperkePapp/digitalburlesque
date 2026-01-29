// Avatar Choreography Controller Script v1.0
// Place in the controller prim at stage center.
// Also place: avatar-slot 1 through avatar-slot N, and all animation files.
//
// Receives HTTP POST from the web tool.
// Forwards movement commands to mover prims via llRegionSay.
// Forwards animation commands to slot scripts via llMessageLinked.
// Listens for avatar sit/unsit notifications from movers.

integer AVATAR_CHANNEL = -9876544;

key g_urlReqId;
string g_url = "";

// Avatar tracking: parallel list indexed by (dancerNum - 1)
list g_slotAvatars = [];
integer g_maxSlots = 12;

default
{
    state_entry()
    {
        llSetText("Avatar Controller\nRequesting URL...", <1, 1, 0>, 1.0);
        g_urlReqId = llRequestURL();
        llListen(AVATAR_CHANNEL, "", "", "");

        // Initialize slot tracking
        g_slotAvatars = [];
        integer i;
        for (i = 0; i < g_maxSlots; i++)
            g_slotAvatars += [NULL_KEY];
    }

    http_request(key id, string method, string body)
    {
        // === Handle URL grant/deny ===
        if (id == g_urlReqId)
        {
            if (method == URL_REQUEST_GRANTED)
            {
                g_url = body;
                llSetText("Avatar Controller Ready\n" + g_url, <0, 1, 0>, 1.0);
                llOwnerSay("=== Avatar Choreography Controller Ready ===");
                llOwnerSay("Paste this URL into the web tool:");
                llOwnerSay(g_url);
            }
            else
            {
                llSetText("URL Request Failed!", <1, 0, 0>, 1.0);
                llOwnerSay("ERROR: Could not get HTTP URL. Try resetting the script.");
            }
            return;
        }

        // === Handle incoming HTTP requests from web tool ===
        if (method != "POST")
        {
            llHTTPResponse(id, 405, "Use POST");
            return;
        }

        // --- PLAY: forward to movers with center position ---
        if (body == "PLAY")
        {
            vector myPos = llGetPos();
            llRegionSay(AVATAR_CHANNEL, "PLAY|" + (string)myPos);
            llHTTPResponse(id, 200, "PLAY sent");
            llOwnerSay("PLAY sent (center: " + (string)myPos + ")");
            return;
        }

        // --- STOP: forward to movers + stop all animations ---
        if (body == "STOP")
        {
            llRegionSay(AVATAR_CHANNEL, "STOP");
            llMessageLinked(LINK_THIS, 0, "STOPALL", "");
            llHTTPResponse(id, 200, "STOP sent");
            llOwnerSay("STOP sent to all movers and slots");
            return;
        }

        // --- RESET: forward to movers + release all slots ---
        if (body == "RESET")
        {
            llRegionSay(AVATAR_CHANNEL, "RESET");
            llMessageLinked(LINK_THIS, 0, "STOPALL", "");

            integer i;
            for (i = 0; i < g_maxSlots; i++)
            {
                if (llList2Key(g_slotAvatars, i) != NULL_KEY)
                {
                    llMessageLinked(LINK_THIS, i + 1, "RELEASE", "");
                    g_slotAvatars = llListReplaceList(g_slotAvatars, [NULL_KEY], i, i);
                }
            }

            llHTTPResponse(id, 200, "RESET sent");
            llOwnerSay("RESET sent, all avatars released");
            return;
        }

        // --- DANCER data: forward to movers ---
        if (llSubStringIndex(body, "DANCER|") == 0)
        {
            llRegionSay(AVATAR_CHANNEL, body);

            list parts = llParseString2List(body, ["|"], []);
            string dNum = llList2String(parts, 1);
            integer layerCount = llGetListLength(parts) - 2;

            llHTTPResponse(id, 200, "Dancer " + dNum + " loaded");
            llOwnerSay("Loaded avatar dancer " + dNum + " (" + (string)layerCount + " layers)");
            return;
        }

        // --- ANIM|num|animName: start animation on dancer ---
        if (llSubStringIndex(body, "ANIM|") == 0)
        {
            list parts = llParseString2List(body, ["|"], []);
            integer dNum = (integer)llList2String(parts, 1);
            string animName = llList2String(parts, 2);

            llMessageLinked(LINK_THIS, dNum, "ANIM|" + animName, "");
            llHTTPResponse(id, 200, "ANIM " + animName + " sent to dancer " + (string)dNum);
            llOwnerSay("Animation '" + animName + "' -> dancer " + (string)dNum);
            return;
        }

        // --- ANIMSTOP|num|animName or ANIMSTOP|num|ALL ---
        if (llSubStringIndex(body, "ANIMSTOP|") == 0)
        {
            list parts = llParseString2List(body, ["|"], []);
            integer dNum = (integer)llList2String(parts, 1);
            string animName = llList2String(parts, 2);

            if (animName == "ALL")
                llMessageLinked(LINK_THIS, dNum, "STOPALL", "");
            else
                llMessageLinked(LINK_THIS, dNum, "ANIMSTOP|" + animName, "");

            llHTTPResponse(id, 200, "ANIMSTOP sent to dancer " + (string)dNum);
            llOwnerSay("Stop anim '" + animName + "' -> dancer " + (string)dNum);
            return;
        }

        // Unknown command
        llHTTPResponse(id, 400, "Unknown command");
    }

    listen(integer channel, string name, key id, string message)
    {
        // === AVATAR_SIT: mover reports avatar sat down ===
        if (llSubStringIndex(message, "AVATAR_SIT|") == 0)
        {
            list parts = llParseString2List(message, ["|"], []);
            integer dNum = (integer)llList2String(parts, 1);
            key avatarKey = (key)llList2String(parts, 2);

            if (dNum < 1 || dNum > g_maxSlots) return;

            g_slotAvatars = llListReplaceList(g_slotAvatars, [avatarKey], dNum - 1, dNum - 1);
            llMessageLinked(LINK_THIS, dNum, "ASSIGN", avatarKey);
            llOwnerSay("Avatar " + llKey2Name(avatarKey) + " seated on dancer " + (string)dNum);
            return;
        }

        // === AVATAR_UNSIT: mover reports avatar stood up ===
        if (llSubStringIndex(message, "AVATAR_UNSIT|") == 0)
        {
            list parts = llParseString2List(message, ["|"], []);
            integer dNum = (integer)llList2String(parts, 1);

            if (dNum < 1 || dNum > g_maxSlots) return;

            g_slotAvatars = llListReplaceList(g_slotAvatars, [NULL_KEY], dNum - 1, dNum - 1);
            llMessageLinked(LINK_THIS, dNum, "RELEASE", "");
            llOwnerSay("Avatar unseated from dancer " + (string)dNum);
            return;
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }

    changed(integer change)
    {
        if (change & (CHANGED_REGION | CHANGED_REGION_START))
        {
            llSetText("Avatar Controller\nRequesting new URL...", <1, 1, 0>, 1.0);
            g_urlReqId = llRequestURL();
            llOwnerSay("Region change detected, requesting new URL...");
        }
    }
}
