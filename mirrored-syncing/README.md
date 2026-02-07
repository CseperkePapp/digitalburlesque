# Mirror Sync Dance System v1.1

Two-group mirrored animation sync for Second Life. Group A plays original animations, Group B plays the mirrored versions — all in sync.

Control via in-world touch menus or the web control page.

## Files

| File | Description |
|------|-------------|
| `mirror-controller.lsl` | Master controller — HTTP-in bridge, group management, playlist, menus, scanning |
| `mirror-slot.lsl` | Per-avatar animation handler (copy as "mirror-slot 1" through "mirror-slot 8") |
| `mirror-sync.html` | Web control page — open in any browser |

## Setup in Second Life

1. **Create a prim** at your dance area (box, cylinder, whatever you like).
2. **Add scripts to the prim:**
   - Drop in `mirror-controller.lsl`
   - Drop in `mirror-slot.lsl`, then copy it 7 more times and rename each copy:
     `mirror-slot 1`, `mirror-slot 2`, `mirror-slot 3`, ... `mirror-slot 8`
3. **Add dance animations** to the same prim's inventory — both the originals and their mirrored versions. For example:
   ```
   Dakota_Burlesque_1
   Dakota_Burlesque_1_Mirror
   Bento_Charleston_2
   Bento_Charleston_2_Mirror
   ```
4. **Copy the URL** shown in the prim's hovertext.
5. **Open `mirror-sync.html`** in your browser, paste the URL, and click Connect.

## How It Works

### Joining the Dance

**In-world:** Avatars touch the controller prim. They receive an animation permission dialog. Once accepted, they're auto-assigned to whichever group has fewer members.

**From the web page:** Click Scan to find nearby avatars (or add them manually by name + UUID), then assign them to Group A or Group B.

### Mirror Naming Rules (Multi-Rule Auto-Detect)

Different animation creators use different naming conventions for mirrored versions. The controller supports **multiple rules** — it tries each one in order and uses the first match found in the prim's inventory.

All 6 rules are enabled by default — no configuration needed, it just works:

| Rule | Creator example | Original | Mirrored |
|------|----------------|----------|----------|
| `{name}_Mirror` | Vegas Showgirls | `Vegas_Showgirls_1` | `Vegas_Showgirls_1_Mirror` |
| `{name} (mirror)` | Bento Charleston | `Bento Charleston 1` | `Bento Charleston 1 (mirror)` |
| `{name} [M]` | Jasmine PARAGON | `Jasmine - Body & Booty Groove 01_PARAGON` | `Jasmine - Body & Booty Groove 01_PARAGON [M]` |
| `{name} (Mirrored)` | Jortay PARAGON | `Jortay - Heels Dance 08_PARAGON` | `Jortay - Heels Dance 08_PARAGON (Mirrored)` |
| `{name} Mirror` | Slow Burlesque (Abra) | `Slow_Burlesque_1_Abra` | `Slow_Burlesque_1_Abra Mirror` |
| `{name} [Mirrored]` | Nicole/Venetia PARAGON | `Nicole - Buttons Heels Dance 01_PARAGON` | `Nicole - Buttons Heels Dance 01_PARAGON [Mirrored]` |

**How it works:** When Group B needs to play an animation, the controller tries each rule in order and checks the prim inventory for a match. The first animation name found is used. For example, with `Bento Charleston 1`:

1. Tries `Bento Charleston 1_Mirror` — not in inventory
2. Tries `Bento Charleston 1 (mirror)` — found, plays it

You can also add custom rules for other naming conventions via the web page or in-world menu.

**In-world:** Touch > Mirror Rule — click rules to toggle them on/off. Rules are saved in the prim's object description.

**Web page:** Toggle preset rules or add custom ones. Click "Send to SL" to push to the controller.

**Loading playlists from inventory:** The "Load from Inv" button automatically skips mirror-named animations, so only original animations appear in the playlist.

### Playlist

**In-world:** Touch > Playlist > Load from Inv — loads all animations from the prim's inventory.

**Web page:** Type animation names into the playlist editor and click Add. Then click "Send to SL" to push the playlist to the controller.

### Playback

When you hit **Play**:
- Group A avatars play the original animation name
- Group B avatars play the mirrored animation name (derived from the rule)
- All animations start in the same script frame for sync

Use **Next** / **Prev** to advance through the playlist. **Stop** halts all animations. **Reset** stops everything and releases all dancers.

## In-World Menu

Touch the controller prim to open the menu:

```
Main Menu
├── Scan .............. Find nearby avatars, tap a name to add them
├── Groups ............ View/manage Group A & B assignments
│   ├── Swap Slot ..... Move a dancer between A and B
│   ├── Remove Slot ... Release a specific dancer
│   ├── Auto Assign ... Alternate all dancers A, B, A, B...
│   └── Release All ... Stop and release everyone
├── Playlist .......... Manage the dance queue
│   ├── Load from Inv . Load all animations from prim inventory
│   └── Clear List .... Empty the playlist
├── Play .............. Start the current animation
├── Stop .............. Stop all animations
├── Next / Prev ....... Advance or go back in playlist
├── Mirror Rule ....... Choose the naming pattern
└── Reset ............. Full reset — stop, release all, clear playlist
```

## Web Control Page

Open `mirror-sync.html` in any browser. Features:

- **Connection** — paste the HTTP-in URL from hovertext
- **Mirror Rule** — set the naming pattern with live preview
- **Avatar Scanner** — scan nearby or add manually by name + UUID
- **Group Management** — two columns (A / B) with move and remove buttons
- **Animation Library** — master list of all your dances with tags/sets (toggle with the Library button in the toolbar)
  - **Bulk Import** — paste `playlists.txt` content to import all dances with auto-tagged sets
  - **Tag Filter** — dropdown to filter by set/tag, search box to filter by name
  - **Drag & Drop** — drag dances from the library into the playlist at any position
  - Double-click or click **+** to add a dance to the end of the playlist
  - **Add All to Playlist** — adds all currently filtered dances at once
- **Saved Playlists** — save, load, and manage named playlists
  - Save / Save As / Load / Delete
  - Export / Import individual playlists as `.json` files
- **Playlist Editor** — add, remove, reorder animations; send to SL
- **Transport** — Play, Stop, Next, Prev, Reset
- **Log** — timestamped history of all actions

Project state (including library and saved playlists) auto-saves to browser localStorage. Use Export/Import for backup.

## Communication

| Channel | Usage |
|---------|-------|
| `-9876545` | Reserved for this system (does not conflict with choreographer `-9876543` or avatar system `-9876544`) |
| HTTP POST | Web page sends commands to the controller's HTTP-in URL |
| Link messages | Controller communicates with slot scripts inside the same prim |

## Limits

- **8 dancers max** (4 per group)
- Both the original and mirrored animation files must exist in the prim's inventory
- HTTP-in URLs are temporary — if the region restarts, copy the new URL from hovertext
- Avatars must accept the animation permission dialog to dance
