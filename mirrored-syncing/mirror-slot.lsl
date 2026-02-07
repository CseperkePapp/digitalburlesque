// Mirror Slot Script v1.2
// Copy this script and rename to "mirror-slot 1", "mirror-slot 2", etc. (up to 8).
// Place all copies in the controller prim alongside mirror-controller.lsl
// and all dance animation files (both original and mirrored versions).
//
// Each slot handles animation permissions and playback for one avatar.
// The controller tells each slot which animation to play (already resolved
// to the correct name — original for Group A, mirrored for Group B).

integer g_slotNum = 0;
key g_avatarKey = NULL_KEY;
integer g_hasPerms = FALSE;
list g_activeAnims = [];

stopAllAnims()
{
    integer i;
    integer count = llGetListLength(g_activeAnims);
    for (i = 0; i < count; i++)
    {
        llStopAnimation(llList2String(g_activeAnims, i));
    }
    g_activeAnims = [];
}

default
{
    state_entry()
    {
        // Parse slot number from script name, e.g. "mirror-slot 3" -> 3
        string myName = llGetScriptName();
        integer lastSpace = -1;
        integer i;
        integer len = llStringLength(myName);
        for (i = 0; i < len; i++)
        {
            if (llGetSubString(myName, i, i) == " ")
                lastSpace = i;
        }

        if (lastSpace >= 0)
            g_slotNum = (integer)llGetSubString(myName, lastSpace + 1, -1);

        if (g_slotNum < 1 || g_slotNum > 8)
        {
            llOwnerSay("WARNING: Could not parse slot number from script name '" + myName + "'. Rename to 'mirror-slot N' (1-8).");
            g_slotNum = 0;
            return;
        }

        llOwnerSay("Mirror slot " + (string)g_slotNum + " ready");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        // num = slot number (must match ours) or 0 for broadcast
        if (num != g_slotNum && num != 0) return;
        if (g_slotNum == 0) return;

        // --- ASSIGN: controller wants us to request perms from this avatar ---
        if (str == "ASSIGN")
        {
            if (g_avatarKey != NULL_KEY && g_hasPerms)
            {
                stopAllAnims();
            }

            g_avatarKey = id;
            g_hasPerms = FALSE;
            g_activeAnims = [];

            llRequestPermissions(g_avatarKey, PERMISSION_TRIGGER_ANIMATION);
            llOwnerSay("Mirror slot " + (string)g_slotNum + ": requesting permissions from " + llKey2Name(g_avatarKey));
            return;
        }

        // --- RELEASE: controller wants us to drop this avatar ---
        if (str == "RELEASE")
        {
            if (g_avatarKey != NULL_KEY && g_hasPerms)
            {
                stopAllAnims();
            }
            g_avatarKey = NULL_KEY;
            g_hasPerms = FALSE;
            g_activeAnims = [];
            llOwnerSay("Mirror slot " + (string)g_slotNum + ": released");
            return;
        }

        // --- ANIM|animName: start animation (seamless transition) ---
        if (llSubStringIndex(str, "ANIM|") == 0)
        {
            if (g_avatarKey == NULL_KEY || !g_hasPerms) return;

            string animName = llGetSubString(str, 5, -1);

            // Stop old animations first for seamless transition
            stopAllAnims();

            llStartAnimation(animName);
            g_activeAnims = [animName];

            llOwnerSay("Mirror slot " + (string)g_slotNum + ": playing '" + animName + "'");
            return;
        }

        // --- ANIMSTOP|animName: stop specific animation ---
        if (llSubStringIndex(str, "ANIMSTOP|") == 0)
        {
            if (g_avatarKey == NULL_KEY || !g_hasPerms) return;

            string animName = llGetSubString(str, 9, -1);
            llStopAnimation(animName);

            integer idx = llListFindList(g_activeAnims, [animName]);
            if (idx != -1)
                g_activeAnims = llDeleteSubList(g_activeAnims, idx, idx);

            llOwnerSay("Mirror slot " + (string)g_slotNum + ": stopped '" + animName + "'");
            return;
        }

        // --- STOPALL: stop all animations ---
        if (str == "STOPALL")
        {
            if (g_avatarKey == NULL_KEY || !g_hasPerms) return;
            stopAllAnims();
            llOwnerSay("Mirror slot " + (string)g_slotNum + ": all animations stopped");
            return;
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            g_hasPerms = TRUE;
            llOwnerSay("Mirror slot " + (string)g_slotNum + ": permission granted by " + llKey2Name(g_avatarKey));
            // Report success to controller
            llMessageLinked(LINK_THIS, g_slotNum, "PERMS_OK", g_avatarKey);
        }
        else
        {
            g_hasPerms = FALSE;
            llOwnerSay("Mirror slot " + (string)g_slotNum + ": permission DENIED by " + llKey2Name(g_avatarKey));
            // Report failure to controller
            llMessageLinked(LINK_THIS, g_slotNum, "PERMS_FAIL", g_avatarKey);
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}
