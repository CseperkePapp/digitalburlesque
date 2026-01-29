// Choreography Controller Script v4.1
// Place in a single control prim on stage.
// Receives HTTP POST from the web tool, forwards to dancer scripts.

integer CHOREO_CHANNEL = -9876543;

key g_urlReqId;
string g_url = "";

default
{
    state_entry()
    {
        llSetText("Choreography Controller\nRequesting URL...", <1, 1, 0>, 1.0);
        g_urlReqId = llRequestURL();
        llListen(CHOREO_CHANNEL, "", "", "");
    }

    http_request(key id, string method, string body)
    {
        // === Handle URL grant/deny ===
        if (id == g_urlReqId)
        {
            if (method == URL_REQUEST_GRANTED)
            {
                g_url = body;
                llSetText("Controller Ready\n" + g_url, <0, 1, 0>, 1.0);
                llOwnerSay("=== Choreography Controller Ready ===");
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
        if (method == "POST")
        {
            // PLAY: include controller position as stage center reference
            if (body == "PLAY")
            {
                vector myPos = llGetPos();
                llRegionSay(CHOREO_CHANNEL, "PLAY|" + (string)myPos);
                llHTTPResponse(id, 200, "PLAY sent");
                llOwnerSay("PLAY sent (center: " + (string)myPos + ")");
                return;
            }

            // STOP, RESET
            if (body == "STOP" || body == "RESET")
            {
                llRegionSay(CHOREO_CHANNEL, body);
                llHTTPResponse(id, 200, body + " sent");
                llOwnerSay(body + " command sent to all dancers");
                return;
            }

            // Dancer data: DANCER|num|x,y,z,t,s|...
            if (llSubStringIndex(body, "DANCER|") == 0)
            {
                llRegionSay(CHOREO_CHANNEL, body);

                // Extract dancer number for feedback
                list parts = llParseString2List(body, ["|"], []);
                string dNum = llList2String(parts, 1);
                integer layerCount = llGetListLength(parts) - 2;

                llHTTPResponse(id, 200, "Dancer " + dNum + " loaded");
                llOwnerSay("Loaded dancer " + dNum + " (" + (string)layerCount + " layers)");
                return;
            }

            // Unknown command
            llHTTPResponse(id, 400, "Unknown command");
        }
        else
        {
            llHTTPResponse(id, 405, "Use POST");
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        // Reserved for future dancer feedback
    }

    on_rez(integer param)
    {
        llResetScript();
    }

    changed(integer change)
    {
        if (change & (CHANGED_REGION | CHANGED_REGION_START))
        {
            // Region restart invalidates URL - request a new one
            llSetText("Controller\nRequesting new URL...", <1, 1, 0>, 1.0);
            g_urlReqId = llRequestURL();
            llOwnerSay("Region change detected, requesting new URL...");
        }
    }
}
