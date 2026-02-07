// List Animations v1.0
// Drop into a prim — touch to list all animations in its inventory.
// Outputs name and count to owner chat.

default
{
    touch_start(integer total)
    {
        integer count = llGetInventoryNumber(INVENTORY_ANIMATION);
        if (count == 0)
        {
            llOwnerSay("No animations found in this prim.");
            return;
        }

        llOwnerSay("=== " + (string)count + " animations ===");
        integer i;
        for (i = 0; i < count; i++)
        {
            llOwnerSay((string)(i + 1) + ". " + llGetInventoryName(INVENTORY_ANIMATION, i));
        }
        llOwnerSay("=== end ===");
    }
}
