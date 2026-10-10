// Mirror Sync Dance Controller v1.9
// Place in a prim at your dance area.
// Also place: mirror-slot 1 through mirror-slot 8, plus all dance animations
// (both original and mirrored versions).
//
// Two groups: Group A plays original animations, Group B plays mirrored versions.
// Avatars touch the object to join. Controller assigns them to a group.
// Control via in-world touch menus or the mirror-sync.html web page.

// ============================================================================
// CONFIGURATION
// ============================================================================

integer MAX_SLOTS = 8;          // 1-4 per group, 8 total max

// ============================================================================
// GLOBALS
// ============================================================================

key g_urlReqId;
string g_url = "";

// Slot tracking — parallel lists, indexed by (slotNum - 1)
// Group: 0 = unassigned, 1 = Group A (original), 2 = Group B (mirror)
list g_slotAvatars;     // 8 keys
list g_slotGroups;      // 8 integers
list g_slotPerms;       // 8 integers (0/1)

// Playlist
list g_playlist;        // animation name strings
integer g_playIdx = 0;
integer g_playing = FALSE;
string g_currentAnim = "";

// Explicit pairing — parallel list to g_playlist for Group B animations
list g_playlistB = [];

// Sensor / scan results (transient)
list g_scannedKeys;
list g_scannedNames;

// Notecard reading (async)
key g_ncReqId;
string g_ncName = "";
integer g_ncLine = 0;

// Duration-aware playback
list g_playDurations = [];    // parallel to g_playlist — seconds per anim (0 = manual)
integer g_autoAdvance = FALSE; // auto-advance mode on/off
float g_trackStart = 0.0;    // llGetTime() when current track started (drift-safe)
float g_trackDur = 0.0;      // expected duration of current track

// Menu system
integer g_menuChan;
integer g_menuHandle;
key g_menuUser;
string g_menuContext = "";  // tracks which menu is open

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

initSlots()
{
    g_slotAvatars = [];
    g_slotGroups = [];
    g_slotPerms = [];
    integer i;
    for (i = 0; i < MAX_SLOTS; i++)
    {
        g_slotAvatars += [NULL_KEY];
        g_slotGroups += [0];
        g_slotPerms += [0];
    }
}

// Find a paired/mirrored animation in prim inventory.
// Tries common mirror naming patterns and returns the first match.
// Falls back to the original name if no mirror variant found.
string findPairInInventory(string animName)
{
    string t;
    t = animName + "_Mirror";
    if (llGetInventoryType(t) == INVENTORY_ANIMATION) return t;
    t = animName + " (mirror)";
    if (llGetInventoryType(t) == INVENTORY_ANIMATION) return t;
    t = animName + " [M]";
    if (llGetInventoryType(t) == INVENTORY_ANIMATION) return t;
    t = animName + " (Mirrored)";
    if (llGetInventoryType(t) == INVENTORY_ANIMATION) return t;
    t = animName + " Mirror";
    if (llGetInventoryType(t) == INVENTORY_ANIMATION) return t;
    t = animName + " [Mirrored]";
    if (llGetInventoryType(t) == INVENTORY_ANIMATION) return t;
    return animName;
}

// Find first empty slot, returns 0 if none available
integer findEmptySlot()
{
    integer i;
    for (i = 0; i < MAX_SLOTS; i++)
    {
        if (llList2Key(g_slotAvatars, i) == NULL_KEY)
            return i + 1; // 1-based
    }
    return 0;
}

// Find slot by avatar key, returns 0 if not found
integer findSlotByAvatar(key av)
{
    integer i;
    for (i = 0; i < MAX_SLOTS; i++)
    {
        if (llList2Key(g_slotAvatars, i) == av)
            return i + 1;
    }
    return 0;
}

// Count how many are in each group
integer countGroup(integer group)
{
    integer count = 0;
    integer i;
    for (i = 0; i < MAX_SLOTS; i++)
    {
        if (llList2Integer(g_slotGroups, i) == group
            && llList2Key(g_slotAvatars, i) != NULL_KEY)
            count++;
    }
    return count;
}

// Assign avatar to a slot and group
assignAvatar(key av, integer group)
{
    integer slotNum = findEmptySlot();
    if (slotNum == 0)
    {
        llRegionSayTo(av, 0, "Sorry, all dance slots are full!");
        return;
    }

    integer idx = slotNum - 1;
    g_slotAvatars = llListReplaceList(g_slotAvatars, [av], idx, idx);
    g_slotGroups = llListReplaceList(g_slotGroups, [group], idx, idx);
    g_slotPerms = llListReplaceList(g_slotPerms, [0], idx, idx);

    // Tell slot script to request animation permissions
    llMessageLinked(LINK_THIS, slotNum, "ASSIGN", av);
}

// Release a slot
releaseSlot(integer slotNum)
{
    if (slotNum < 1 || slotNum > MAX_SLOTS) return;
    integer idx = slotNum - 1;

    if (llList2Key(g_slotAvatars, idx) != NULL_KEY)
        llMessageLinked(LINK_THIS, slotNum, "RELEASE", "");

    g_slotAvatars = llListReplaceList(g_slotAvatars, [NULL_KEY], idx, idx);
    g_slotGroups = llListReplaceList(g_slotGroups, [0], idx, idx);
    g_slotPerms = llListReplaceList(g_slotPerms, [0], idx, idx);
}

// Play current playlist animation on all occupied slots
playCurrentAnim()
{
    if (llGetListLength(g_playlist) == 0) return;
    if (g_playIdx >= llGetListLength(g_playlist))
        g_playIdx = 0;

    g_currentAnim = llList2String(g_playlist, g_playIdx);
    string mirrorAnim = g_currentAnim;
    if (llGetListLength(g_playlistB) > g_playIdx)
        mirrorAnim = llList2String(g_playlistB, g_playIdx);

    integer i;
    for (i = 0; i < MAX_SLOTS; i++)
    {
        if (llList2Key(g_slotAvatars, i) == NULL_KEY) jump skip;
        if (llList2Integer(g_slotPerms, i) != 1) jump skip;

        integer group = llList2Integer(g_slotGroups, i);
        string animToPlay;
        if (group == 2)
            animToPlay = mirrorAnim;
        else
            animToPlay = g_currentAnim;

        llMessageLinked(LINK_THIS, i + 1, "ANIM|" + animToPlay, "");
        @skip;
    }

    g_playing = TRUE;

    // Auto-advance: tick-based for drift safety
    if (g_autoAdvance && llGetListLength(g_playDurations) > g_playIdx)
    {
        g_trackDur = llList2Float(g_playDurations, g_playIdx);
        if (g_trackDur > 0.0)
        {
            g_trackStart = llGetTime();
            llSetTimerEvent(0.5);
        }
        else
        {
            g_trackDur = 0.0;
            llSetTimerEvent(0.0);
        }
    }

    updateHovertext();
}

// Stop all animations on all slots
stopAllAnims()
{
    llMessageLinked(LINK_THIS, 0, "STOPALL", "");
    g_playing = FALSE;
    g_trackDur = 0.0;
    llSetTimerEvent(0.0);
    updateHovertext();
}

// Advance to next playlist entry (seamless — slot scripts handle stop+start)
advancePlaylist(integer direction)
{
    if (llGetListLength(g_playlist) == 0) return;

    g_playIdx += direction;
    if (g_playIdx >= llGetListLength(g_playlist))
        g_playIdx = 0;
    if (g_playIdx < 0)
        g_playIdx = llGetListLength(g_playlist) - 1;

    playCurrentAnim();
}

// Update hovertext with current status
updateHovertext()
{
    string text = "Mirror Sync Dance";
    if (g_url != "")
        text += "\n" + g_url;

    integer countA = countGroup(1);
    integer countB = countGroup(2);
    text += "\nGroup A: " + (string)countA + "  Group B: " + (string)countB;

    if (g_playing && g_currentAnim != "")
    {
        text += "\nPlaying: " + g_currentAnim + " [" + (string)(g_playIdx + 1) + "/" + (string)llGetListLength(g_playlist) + "]";
        if (g_autoAdvance) text += " [Auto]";
    }
    else if (llGetListLength(g_playlist) > 0)
        text += "\nPlaylist: " + (string)llGetListLength(g_playlist) + " dances (stopped)";
    else
        text += "\nNo playlist loaded";

    integer totalDancers = countA + countB;
    if (totalDancers < MAX_SLOTS)
        text += "\nTouch to join (" + (string)(MAX_SLOTS - totalDancers) + " slots open)";
    else
        text += "\nAll slots full";

    vector color = <0, 1, 0>;
    if (g_url == "") color = <1, 1, 0>;

    llSetText(text, color, 1.0);
}

// Build a status string for HTTP response
string getStatusString()
{
    string out = "SLOTS";
    integer i;
    for (i = 0; i < MAX_SLOTS; i++)
    {
        key av = llList2Key(g_slotAvatars, i);
        if (av != NULL_KEY)
        {
            out += "|" + (string)(i + 1) + ","
                + llKey2Name(av) + ","
                + llList2String(["U", "A", "B"], llList2Integer(g_slotGroups, i)) + ","
                + (string)llList2Integer(g_slotPerms, i);
        }
    }

    out += "||PLAY|" + (string)g_playing + "|" + g_currentAnim
        + "|" + (string)g_playIdx + "|" + (string)llGetListLength(g_playlist);

    // Append scan results if available
    if (llGetListLength(g_scannedKeys) > 0)
    {
        out += "||SCAN";
        integer j;
        for (j = 0; j < llGetListLength(g_scannedKeys) && j < 12; j++)
        {
            out += "|" + llList2String(g_scannedKeys, j) + "," + llList2String(g_scannedNames, j);
        }
    }

    return out;
}

// ============================================================================
// MENU SYSTEM
// ============================================================================

openMenu(key user, string title, list buttons)
{
    if (g_menuHandle) llListenRemove(g_menuHandle);
    g_menuChan = -1 - (integer)llFrand(999999);
    g_menuHandle = llListen(g_menuChan, "", user, "");
    g_menuUser = user;
    llDialog(user, title, buttons, g_menuChan);
    // Only set menu timeout if auto-advance isn't controlling the timer
    if (!g_playing || !g_autoAdvance)
        llSetTimerEvent(60.0);
}

showMainMenu(key user)
{
    g_menuContext = "main";
    string title = "=== Mirror Sync Dance ===\n"
        + "Group A: " + (string)countGroup(1) + "  Group B: " + (string)countGroup(2) + "\n"
        + "Playlist: " + (string)llGetListLength(g_playlist) + " dances";
    if (g_playing)
        title += "\nNow playing: " + g_currentAnim;
    if (g_autoAdvance)
        title += "\nAuto-advance: ON";

    string autoLabel;
    if (g_autoAdvance) autoLabel = "Auto: OFF";
    else autoLabel = "Auto: ON";

    list buttons = ["Scan", "Groups", "Playlist",
                    "Play", "Stop", "Next",
                    "Prev", autoLabel, "Reset"];
    openMenu(user, title, buttons);
}

showScanMenu(key user)
{
    g_menuContext = "scan";
    if (llGetListLength(g_scannedNames) == 0)
    {
        openMenu(user, "No avatars scanned yet.\nClick Scan to search nearby.", ["Scan Now", "Back"]);
        return;
    }

    string title = "Nearby avatars (touch to assign):";
    list buttons = [];
    integer i;
    integer count = llGetListLength(g_scannedNames);
    if (count > 10) count = 10; // llDialog max 12 buttons, save 2 for nav
    for (i = 0; i < count; i++)
    {
        string name = llList2String(g_scannedNames, i);
        // Truncate to 24 chars (llDialog button limit)
        if (llStringLength(name) > 24)
            name = llGetSubString(name, 0, 23);
        buttons += [name];
    }
    buttons += ["Refresh", "Back"];
    openMenu(user, title, buttons);
}

showGroupMenu(key user)
{
    g_menuContext = "groups";
    string title = "--- Group A (Original) ---";
    integer i;
    for (i = 0; i < MAX_SLOTS; i++)
    {
        if (llList2Key(g_slotAvatars, i) != NULL_KEY && llList2Integer(g_slotGroups, i) == 1)
            title += "\n  " + (string)(i+1) + ". " + llKey2Name(llList2Key(g_slotAvatars, i));
    }
    title += "\n--- Group B (Mirror) ---";
    for (i = 0; i < MAX_SLOTS; i++)
    {
        if (llList2Key(g_slotAvatars, i) != NULL_KEY && llList2Integer(g_slotGroups, i) == 2)
            title += "\n  " + (string)(i+1) + ". " + llKey2Name(llList2Key(g_slotAvatars, i));
    }

    openMenu(user, title, ["Swap Slot", "Remove Slot", "Auto Assign",
                           "Release All", "Back"]);
}

showPlaylistMenu(key user)
{
    g_menuContext = "playlist";
    string title = "Playlist (" + (string)llGetListLength(g_playlist) + " dances):";
    integer i;
    integer count = llGetListLength(g_playlist);
    if (count > 5) count = 5;
    for (i = 0; i < count; i++)
    {
        string marker = "  ";
        if (i == g_playIdx) marker = "> ";
        title += "\n" + marker + (string)(i+1) + ". " + llList2String(g_playlist, i);
    }
    if (llGetListLength(g_playlist) > 5)
        title += "\n  ... +" + (string)(llGetListLength(g_playlist) - 5) + " more";

    // Load animations from prim inventory or notecards
    list buttons = ["Load from Inv", "Notecards", "Clear List", "Back"];
    openMenu(user, title, buttons);
}

showNotecardMenu(key user)
{
    g_menuContext = "notecards";
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    if (count == 0)
    {
        openMenu(user, "No notecards found in prim inventory.\nDrop notecard files into this prim.", ["Back"]);
        return;
    }

    string title = "Select a notecard to load:";
    list buttons = [];
    integer i;
    if (count > 10) count = 10; // llDialog max 12 buttons, save 2 for nav
    for (i = 0; i < count; i++)
    {
        string name = llGetInventoryName(INVENTORY_NOTECARD, i);
        // Truncate to 24 chars (llDialog button limit)
        if (llStringLength(name) > 24)
            name = llGetSubString(name, 0, 23);
        buttons += [name];
    }
    buttons += ["Back"];
    openMenu(user, title, buttons);
}

// Parse duration string — supports both "32.6" (seconds) and "1:32.6" (mm:ss)
float parseDuration(string s)
{
    integer ci = llSubStringIndex(s, ":");
    if (ci > 0)
        return (float)llGetSubString(s, 0, ci - 1) * 60.0
             + (float)llGetSubString(s, ci + 1, -1);
    return (float)s;
}

// Check if an animation name looks like a mirror derivative (simple suffix check)
integer isMirrorName(string animName)
{
    integer len = llStringLength(animName);
    if (len > 7 && llGetSubString(animName, -7, -1) == "_Mirror") return TRUE;
    if (len > 9 && llGetSubString(animName, -9, -1) == " (mirror)") return TRUE;
    if (len > 4 && llGetSubString(animName, -4, -1) == " [M]") return TRUE;
    if (len > 11 && llGetSubString(animName, -11, -1) == " (Mirrored)") return TRUE;
    if (len > 7 && llGetSubString(animName, -7, -1) == " Mirror") return TRUE;
    if (len > 11 && llGetSubString(animName, -11, -1) == " [Mirrored]") return TRUE;
    return FALSE;
}

// Start async read of a notecard into the playlist
startReadNotecard(string name)
{
    if (llGetInventoryType(name) != INVENTORY_NOTECARD)
    {
        llOwnerSay("Notecard '" + name + "' not found in inventory");
        return;
    }
    g_ncName = name;
    g_ncLine = 0;
    g_playlist = [];
    g_playlistB = [];
    g_playDurations = [];
    g_playIdx = 0;
    g_ncReqId = llGetNotecardLine(name, 0);
}

// Load original (non-mirror) animation names from prim inventory into playlist
loadPlaylistFromInventory()
{
    g_playlist = [];
    g_playlistB = [];
    g_playDurations = [];
    integer count = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    for (i = 0; i < count; i++)
    {
        string name = llGetInventoryName(INVENTORY_ANIMATION, i);
        if (!isMirrorName(name))
        {
            g_playlist += [name];
            g_playlistB += [findPairInInventory(name)];
        }
    }
    g_playIdx = 0;
}

// ============================================================================
// MAIN STATE
// ============================================================================

default
{
    state_entry()
    {
        initSlots();

        llSetText("Mirror Sync Dance\nRequesting URL...", <1, 1, 0>, 1.0);
        g_urlReqId = llRequestURL();

        updateHovertext();
        llOwnerSay("Mirror Sync Dance Controller v1.9 ready");
    }

    // ========================================================================
    // HTTP — web page communication
    // ========================================================================

    http_request(key id, string method, string body)
    {
        // --- URL grant/deny ---
        if (id == g_urlReqId)
        {
            if (method == URL_REQUEST_GRANTED)
            {
                g_url = body;
                llOwnerSay("URL: " + g_url);
            }
            else
                llOwnerSay("ERROR: Could not get HTTP URL. Try resetting.");
            updateHovertext();
            return;
        }

        if (method != "POST")
        {
            llHTTPResponse(id, 405, "Use POST");
            return;
        }

        // --- SCAN: trigger avatar sensor ---
        if (body == "SCAN")
        {
            llSensor("", "", AGENT, 20.0, PI);
            llHTTPResponse(id, 200, "Scanning...");
            return;
        }

        // --- STATUS: return current state ---
        if (body == "STATUS")
        {
            llHTTPResponse(id, 200, getStatusString());
            return;
        }

        // --- PING: diagnostic heartbeat ---
        if (body == "PING")
        {
            llHTTPResponse(id, 200, "PONG|" + (string)llGetTime()
                + "|" + (string)g_playIdx + "|" + (string)g_playing
                + "|" + (string)g_autoAdvance);
            return;
        }

        // --- INVITE|avatarKey|group ---
        if (llSubStringIndex(body, "INVITE|") == 0)
        {
            list parts = llParseString2List(body, ["|"], []);
            key av = (key)llList2String(parts, 1);
            integer group = 1;
            if (llList2String(parts, 2) == "B") group = 2;

            if (findSlotByAvatar(av) > 0)
            {
                llHTTPResponse(id, 200, "Already assigned");
                return;
            }

            assignAvatar(av, group);
            llHTTPResponse(id, 200, "Invited");
            return;
        }

        // --- REMOVE|slotNum ---
        if (llSubStringIndex(body, "REMOVE|") == 0)
        {
            integer slotNum = (integer)llGetSubString(body, 7, -1);
            releaseSlot(slotNum);
            llHTTPResponse(id, 200, "Removed");
            updateHovertext();
            return;
        }

        // --- SETGROUP|slotNum|A or B ---
        if (llSubStringIndex(body, "SETGROUP|") == 0)
        {
            list parts = llParseString2List(body, ["|"], []);
            integer slotNum = (integer)llList2String(parts, 1);
            integer group = 1;
            if (llList2String(parts, 2) == "B") group = 2;

            if (slotNum >= 1 && slotNum <= MAX_SLOTS)
                g_slotGroups = llListReplaceList(g_slotGroups, [group], slotNum - 1, slotNum - 1);
            llHTTPResponse(id, 200, "Group set");
            updateHovertext();
            return;
        }

        // --- PLAYLIST|orig,pair:dur|... (pair and duration optional) ---
        if (llSubStringIndex(body, "PLAYLIST|") == 0)
        {
            list parts = llParseString2List(llGetSubString(body, 9, -1), ["|"], []);
            g_playlist = [];
            g_playlistB = [];
            g_playDurations = [];
            integer p;
            for (p = 0; p < llGetListLength(parts); p++)
            {
                string entry = llList2String(parts, p);
                string namePart = entry;
                float dur = 0.0;
                integer colonIdx = llSubStringIndex(entry, ":");
                if (colonIdx > 0)
                {
                    namePart = llGetSubString(entry, 0, colonIdx - 1);
                    dur = parseDuration(llGetSubString(entry, colonIdx + 1, -1));
                }
                string orig = namePart;
                string pair = namePart;
                integer commaIdx = llSubStringIndex(namePart, ",");
                if (commaIdx > 0)
                {
                    orig = llGetSubString(namePart, 0, commaIdx - 1);
                    pair = llGetSubString(namePart, commaIdx + 1, -1);
                }
                g_playlist += [orig];
                g_playlistB += [pair];
                g_playDurations += [dur];
            }
            g_playIdx = 0;
            llHTTPResponse(id, 200, "Playlist: " + (string)llGetListLength(g_playlist));
            updateHovertext();
            return;
        }

        // --- LOADNOTE|notecardName ---
        if (llSubStringIndex(body, "LOADNOTE|") == 0)
        {
            startReadNotecard(llGetSubString(body, 9, -1));
            llHTTPResponse(id, 200, "Loading notecard");
            return;
        }

        // --- AUTOPLAY|ON or AUTOPLAY|OFF ---
        if (llSubStringIndex(body, "AUTOPLAY|") == 0)
        {
            string mode = llGetSubString(body, 9, -1);
            if (mode == "ON")
            {
                g_autoAdvance = TRUE;
                if (g_playing && llGetListLength(g_playDurations) > g_playIdx)
                {
                    g_trackDur = llList2Float(g_playDurations, g_playIdx);
                    if (g_trackDur > 0.0)
                    {
                        g_trackStart = llGetTime();
                        llSetTimerEvent(0.5);
                    }
                }
                llHTTPResponse(id, 200, "Auto ON");
            }
            else
            {
                g_autoAdvance = FALSE;
                g_trackDur = 0.0;
                llSetTimerEvent(0.0);
                llHTTPResponse(id, 200, "Auto OFF");
            }
            updateHovertext();
            return;
        }

        // --- PLAY ---
        if (body == "PLAY")
        {
            playCurrentAnim();
            llHTTPResponse(id, 200, "Playing");
            return;
        }

        // --- NEXT ---
        if (body == "NEXT")
        {
            advancePlaylist(1);
            llHTTPResponse(id, 200, "Next");
            return;
        }

        // --- PREV ---
        if (body == "PREV")
        {
            advancePlaylist(-1);
            llHTTPResponse(id, 200, "Prev");
            return;
        }

        // --- STOP ---
        if (body == "STOP")
        {
            stopAllAnims();
            llHTTPResponse(id, 200, "Stopped");
            return;
        }

        // --- RESET ---
        if (body == "RESET")
        {
            stopAllAnims();
            integer i;
            for (i = 0; i < MAX_SLOTS; i++)
            {
                if (llList2Key(g_slotAvatars, i) != NULL_KEY)
                    releaseSlot(i + 1);
            }
            g_playlist = [];
            g_playlistB = [];
            g_playDurations = [];
            g_playIdx = 0;
            g_currentAnim = "";
            g_autoAdvance = FALSE;
            llHTTPResponse(id, 200, "Reset");
            updateHovertext();
            return;
        }

        llHTTPResponse(id, 400, "Unknown command");
    }

    // ========================================================================
    // TOUCH — in-world menu
    // ========================================================================

    touch_start(integer total)
    {
        key user = llDetectedKey(0);

        // Owner always gets the full control menu
        if (user == llGetOwner())
        {
            showMainMenu(user);
            return;
        }

        // Non-owner already dancing — offer to leave
        integer existingSlot = findSlotByAvatar(user);
        if (existingSlot > 0)
        {
            g_menuContext = "leave";
            openMenu(user, "You're already dancing!\nTouch Leave to stop and leave the dance.", ["Leave", "Stay"]);
            return;
        }

        // Non-owner, not assigned — auto-join if slots available
        integer slot = findEmptySlot();
        if (slot == 0)
        {
            llRegionSayTo(user, 0, "Sorry, all dance slots are full!");
            return;
        }

        // Auto-assign to the group with fewer members
        integer group;
        if (countGroup(1) <= countGroup(2))
            group = 1;
        else
            group = 2;

        assignAvatar(user, group);
        llRegionSayTo(user, 0, "Welcome! You've been added to Group "
            + llList2String(["?", "A", "B"], group)
            + ". Please accept the animation permission to start dancing!");
    }

    // ========================================================================
    // SENSOR — avatar scanning
    // ========================================================================

    sensor(integer num)
    {
        g_scannedKeys = [];
        g_scannedNames = [];
        integer i;
        for (i = 0; i < num && i < 16; i++)
        {
            key av = llDetectedKey(i);
            if (findSlotByAvatar(av) == 0)
            {
                g_scannedKeys += [av];
                g_scannedNames += [llDetectedName(i)];
            }
        }

        if (g_menuContext == "scan" && g_menuUser != NULL_KEY)
            showScanMenu(g_menuUser);
    }

    no_sensor()
    {
        g_scannedKeys = [];
        g_scannedNames = [];
    }

    // ========================================================================
    // LISTEN — dialog menu responses
    // ========================================================================

    listen(integer channel, string name, key id, string message)
    {
        if (channel != g_menuChan) return;

        // --- Main Menu ---
        if (g_menuContext == "main")
        {
            if (message == "Scan")
            {
                llSensor("", "", AGENT, 20.0, PI);
                showScanMenu(id);
            }
            else if (message == "Groups")
                showGroupMenu(id);
            else if (message == "Playlist")
                showPlaylistMenu(id);
            else if (message == "Play")
            {
                playCurrentAnim();
                showMainMenu(id);
            }
            else if (message == "Stop")
            {
                stopAllAnims();
                showMainMenu(id);
            }
            else if (message == "Next")
            {
                advancePlaylist(1);
                showMainMenu(id);
            }
            else if (message == "Prev")
            {
                advancePlaylist(-1);
                showMainMenu(id);
            }
            else if (message == "Auto: ON")
            {
                g_autoAdvance = TRUE;
                if (g_playing && llGetListLength(g_playDurations) > g_playIdx)
                {
                    g_trackDur = llList2Float(g_playDurations, g_playIdx);
                    if (g_trackDur > 0.0)
                    {
                        g_trackStart = llGetTime();
                        llSetTimerEvent(0.5);
                    }
                }
                showMainMenu(id);
            }
            else if (message == "Auto: OFF")
            {
                g_autoAdvance = FALSE;
                g_trackDur = 0.0;
                llSetTimerEvent(0.0);
                showMainMenu(id);
            }
            else if (message == "Reset")
            {
                stopAllAnims();
                integer i;
                for (i = 0; i < MAX_SLOTS; i++)
                {
                    if (llList2Key(g_slotAvatars, i) != NULL_KEY)
                        releaseSlot(i + 1);
                }
                g_playlist = [];
                g_playlistB = [];
                g_playDurations = [];
                g_playIdx = 0;
                g_currentAnim = "";
                g_autoAdvance = FALSE;
                updateHovertext();
                showMainMenu(id);
            }
            return;
        }

        // --- Scan Menu ---
        if (g_menuContext == "scan")
        {
            if (message == "Back")
            {
                showMainMenu(id);
                return;
            }
            if (message == "Scan Now" || message == "Refresh")
            {
                llSensor("", "", AGENT, 20.0, PI);
                showScanMenu(id);
                return;
            }

            // User selected an avatar name — find and assign
            integer i;
            for (i = 0; i < llGetListLength(g_scannedNames); i++)
            {
                string sName = llList2String(g_scannedNames, i);
                if (llStringLength(sName) > 24)
                    sName = llGetSubString(sName, 0, 23);
                if (sName == message)
                {
                    key av = llList2Key(g_scannedKeys, i);
                    integer group;
                    if (countGroup(1) <= countGroup(2))
                        group = 1;
                    else
                        group = 2;

                    assignAvatar(av, group);
                    g_scannedKeys = llDeleteSubList(g_scannedKeys, i, i);
                    g_scannedNames = llDeleteSubList(g_scannedNames, i, i);
                    updateHovertext();
                    showScanMenu(id);
                    return;
                }
            }
            showScanMenu(id);
            return;
        }

        // --- Group Menu ---
        if (g_menuContext == "groups")
        {
            if (message == "Back")
            {
                showMainMenu(id);
                return;
            }
            if (message == "Auto Assign")
            {
                integer toggle = 1;
                integer i;
                for (i = 0; i < MAX_SLOTS; i++)
                {
                    if (llList2Key(g_slotAvatars, i) != NULL_KEY)
                    {
                        g_slotGroups = llListReplaceList(g_slotGroups, [toggle], i, i);
                        if (toggle == 1) toggle = 2;
                        else toggle = 1;
                    }
                }
                updateHovertext();
                showGroupMenu(id);
                return;
            }
            if (message == "Release All")
            {
                stopAllAnims();
                integer i;
                for (i = 0; i < MAX_SLOTS; i++)
                {
                    if (llList2Key(g_slotAvatars, i) != NULL_KEY)
                        releaseSlot(i + 1);
                }
                updateHovertext();
                showGroupMenu(id);
                return;
            }
            if (message == "Swap Slot")
            {
                g_menuContext = "swap";
                list buttons = [];
                integer i;
                for (i = 0; i < MAX_SLOTS; i++)
                {
                    if (llList2Key(g_slotAvatars, i) != NULL_KEY)
                    {
                        string grp = llList2String(["?", "A", "B"], llList2Integer(g_slotGroups, i));
                        buttons += [(string)(i+1) + " " + grp];
                    }
                }
                buttons += ["Back"];
                openMenu(id, "Select slot to swap group (A<->B):", buttons);
                return;
            }
            if (message == "Remove Slot")
            {
                g_menuContext = "remove";
                list buttons = [];
                integer i;
                for (i = 0; i < MAX_SLOTS; i++)
                {
                    if (llList2Key(g_slotAvatars, i) != NULL_KEY)
                        buttons += [(string)(i+1) + " " + llKey2Name(llList2Key(g_slotAvatars, i))];
                }
                buttons += ["Back"];
                openMenu(id, "Select slot to remove:", buttons);
                return;
            }
            return;
        }

        // --- Swap submenu ---
        if (g_menuContext == "swap")
        {
            if (message == "Back")
            {
                showGroupMenu(id);
                return;
            }
            integer slotNum = (integer)message;
            if (slotNum >= 1 && slotNum <= MAX_SLOTS)
            {
                integer curGroup = llList2Integer(g_slotGroups, slotNum - 1);
                integer newGroup;
                if (curGroup == 1) newGroup = 2;
                else newGroup = 1;
                g_slotGroups = llListReplaceList(g_slotGroups, [newGroup], slotNum - 1, slotNum - 1);
                updateHovertext();
            }
            showGroupMenu(id);
            return;
        }

        // --- Remove submenu ---
        if (g_menuContext == "remove")
        {
            if (message == "Back")
            {
                showGroupMenu(id);
                return;
            }
            integer slotNum = (integer)message;
            if (slotNum >= 1 && slotNum <= MAX_SLOTS)
            {
                releaseSlot(slotNum);
                updateHovertext();
            }
            showGroupMenu(id);
            return;
        }

        // --- Leave Menu (non-owner dancers) ---
        if (g_menuContext == "leave")
        {
            if (message == "Leave")
            {
                integer slotNum = findSlotByAvatar(id);
                if (slotNum > 0)
                {
                    releaseSlot(slotNum);
                    llRegionSayTo(id, 0, "You've left the dance. Touch again to rejoin!");
                    updateHovertext();
                }
            }
            return;
        }

        // --- Playlist Menu ---
        if (g_menuContext == "playlist")
        {
            if (message == "Back")
            {
                showMainMenu(id);
                return;
            }
            if (message == "Load from Inv")
            {
                loadPlaylistFromInventory();
                updateHovertext();
                showPlaylistMenu(id);
                return;
            }
            if (message == "Notecards")
            {
                showNotecardMenu(id);
                return;
            }
            if (message == "Clear List")
            {
                g_playlist = [];
                g_playlistB = [];
                g_playDurations = [];
                g_playIdx = 0;
                updateHovertext();
                showPlaylistMenu(id);
                return;
            }
            return;
        }

        // --- Notecards submenu ---
        if (g_menuContext == "notecards")
        {
            if (message == "Back")
            {
                showPlaylistMenu(id);
                return;
            }
            integer nc;
            integer ncCount = llGetInventoryNumber(INVENTORY_NOTECARD);
            for (nc = 0; nc < ncCount; nc++)
            {
                string ncName = llGetInventoryName(INVENTORY_NOTECARD, nc);
                string truncated = ncName;
                if (llStringLength(truncated) > 24)
                    truncated = llGetSubString(truncated, 0, 23);
                if (truncated == message)
                {
                    startReadNotecard(ncName);
                    showPlaylistMenu(id);
                    return;
                }
            }
            showPlaylistMenu(id);
            return;
        }
    }

    // ========================================================================
    // LINK MESSAGE — slot permission reports
    // ========================================================================

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (str == "PERMS_OK")
        {
            if (num >= 1 && num <= MAX_SLOTS)
            {
                g_slotPerms = llListReplaceList(g_slotPerms, [1], num - 1, num - 1);
                updateHovertext();

                // If already playing, start this avatar's animation too
                if (g_playing && g_currentAnim != "")
                {
                    integer group = llList2Integer(g_slotGroups, num - 1);
                    string animToPlay = g_currentAnim;
                    if (group == 2 && llGetListLength(g_playlistB) > g_playIdx)
                        animToPlay = llList2String(g_playlistB, g_playIdx);
                    llMessageLinked(LINK_THIS, num, "ANIM|" + animToPlay, "");
                }
            }
        }
        else if (str == "PERMS_FAIL")
        {
            if (num >= 1 && num <= MAX_SLOTS)
            {
                releaseSlot(num);
                updateHovertext();
            }
        }
    }

    // ========================================================================
    // DATASERVER — notecard reading
    // ========================================================================

    dataserver(key id, string data)
    {
        if (id != g_ncReqId) return;

        if (data == EOF)
        {
            llOwnerSay("Loaded " + g_ncName + ": " + (string)llGetListLength(g_playlist) + " dances");
            g_ncName = "";
            updateHovertext();

            if (g_menuContext == "notecards" && g_menuUser != NULL_KEY)
                showPlaylistMenu(g_menuUser);
            return;
        }

        // Process line: trim, skip empty/comments/mirror names
        // Supports name,pair:duration format (e.g. "Bento Cabaret 1,Bento Cabaret 1_Mirror:32.6")
        // Also supports name:duration (auto-pairs from inventory)
        string trimmed = llStringTrim(data, STRING_TRIM);
        if (trimmed != "" && llGetSubString(trimmed, 0, 0) != "#")
        {
            string animName = trimmed;
            string pairName;
            float dur = 0.0;
            integer colonIdx = llSubStringIndex(trimmed, ":");
            if (colonIdx > 0)
            {
                animName = llGetSubString(trimmed, 0, colonIdx - 1);
                dur = parseDuration(llGetSubString(trimmed, colonIdx + 1, -1));
            }
            integer commaIdx = llSubStringIndex(animName, ",");
            if (commaIdx > 0)
            {
                pairName = llGetSubString(animName, commaIdx + 1, -1);
                animName = llGetSubString(animName, 0, commaIdx - 1);
            }
            else
                pairName = findPairInInventory(animName);
            if (!isMirrorName(animName))
            {
                g_playlist += [animName];
                g_playlistB += [pairName];
                g_playDurations += [dur];
            }
        }

        g_ncLine++;
        g_ncReqId = llGetNotecardLine(g_ncName, g_ncLine);
    }

    // ========================================================================
    // TIMER — menu timeout / auto-advance
    // ========================================================================

    timer()
    {
        if (g_playing && g_autoAdvance)
        {
            if (g_trackDur > 0.0 && (llGetTime() - g_trackStart) >= g_trackDur)
                advancePlaylist(1);
            // else: tick not elapsed yet, timer fires again in 0.5s
        }
        else
        {
            llSetTimerEvent(0.0);
            if (g_menuHandle)
            {
                llListenRemove(g_menuHandle);
                g_menuHandle = 0;
            }
            g_menuContext = "";
            g_scannedKeys = [];
            g_scannedNames = [];
        }
    }

    // ========================================================================
    // LIFECYCLE
    // ========================================================================

    on_rez(integer param)
    {
        llResetScript();
    }

    changed(integer change)
    {
        if (change & (CHANGED_REGION | CHANGED_REGION_START))
        {
            llSetText("Mirror Sync Dance\nRequesting new URL...", <1, 1, 0>, 1.0);
            g_urlReqId = llRequestURL();
        }
    }
}
