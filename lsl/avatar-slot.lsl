// Avatar Slot Script v1.0
// Copy this script and rename to "avatar-slot 1", "avatar-slot 2", etc.
// Place all copies in the controller prim alongside avatar-controller.lsl
// and all dance animation files.
//
// Each slot handles animation permissions and playback for one avatar.

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
        // Parse slot number from script name, e.g. "avatar-slot 1" -> 1
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

        if (g_slotNum < 1 || g_slotNum > 12)
        {
            llOwnerSay("WARNING: Could not parse slot number from script name '" + myName + "'. Rename to 'avatar-slot N'.");
            g_slotNum = 0;
            return;
        }

        llOwnerSay("Avatar slot " + (string)g_slotNum + " ready");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        // num = dancer number (must match our slot) or 0 for broadcast
        if (num != g_slotNum && num != 0) return;
        if (g_slotNum == 0) return; // not initialized

        // --- ASSIGN: avatar sat on this dancer's mover ---
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
            llOwnerSay("Slot " + (string)g_slotNum + ": requesting permissions from " + llKey2Name(g_avatarKey));
            return;
        }

        // --- RELEASE: avatar stood up ---
        if (str == "RELEASE")
        {
            if (g_avatarKey != NULL_KEY && g_hasPerms)
            {
                stopAllAnims();
            }
            g_avatarKey = NULL_KEY;
            g_hasPerms = FALSE;
            g_activeAnims = [];
            llOwnerSay("Slot " + (string)g_slotNum + ": released");
            return;
        }

        // --- ANIM|animName: start animation ---
        if (llSubStringIndex(str, "ANIM|") == 0)
        {
            if (g_avatarKey == NULL_KEY || !g_hasPerms) return;

            string animName = llGetSubString(str, 5, -1);
            llStartAnimation(animName);

            if (llListFindList(g_activeAnims, [animName]) == -1)
                g_activeAnims += [animName];

            llOwnerSay("Slot " + (string)g_slotNum + ": playing '" + animName + "'");
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

            llOwnerSay("Slot " + (string)g_slotNum + ": stopped '" + animName + "'");
            return;
        }

        // --- STOPALL: stop all animations ---
        if (str == "STOPALL")
        {
            if (g_avatarKey == NULL_KEY || !g_hasPerms) return;
            stopAllAnims();
            llOwnerSay("Slot " + (string)g_slotNum + ": all animations stopped");
            return;
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            g_hasPerms = TRUE;
            llOwnerSay("Slot " + (string)g_slotNum + ": permission granted by " + llKey2Name(g_avatarKey));
        }
        else
        {
            g_hasPerms = FALSE;
            llOwnerSay("Slot " + (string)g_slotNum + ": permission DENIED by " + llKey2Name(g_avatarKey));
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}
