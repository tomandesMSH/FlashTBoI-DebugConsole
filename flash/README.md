# Debug Console for The Binding of Isaac (Flash)

Rebirth / Repentance's debug console for the original Flash game
([Steam app 113200](https://store.steampowered.com/app/113200/The_Binding_of_Isaac/), including Wrath of the Lamb and
the Eternal Edition), drawn with EID's bitmap font.

It is built exactly like [EID Flash](https://github.com/tomandesMSH/FlashTBoI-EID/blob/master/flash/README.md) and
[Stats HUD](https://github.com/tomandesMSH/FlashTBoI-StatsHUD/blob/main/flash/README.md): players install it with the
**patcher** (`patcher/`), which builds the modded game from their own copy, so no game files are ever distributed.
See `patcher/README.txt` for the player instructions.

## How it works

The Flash game has no mod API. The Steam build is an MDM Zinc 3 projector that keeps the game SWF encrypted inside
`Isaac.exe`.

- **Release side** (`tools/make_payload.py`): the console code is compiled on its own into a DoAction tag (a
  generated one-frame SWF is filled by FFDec and the tag is taken out again). It is stored in
  `patcher/debug_console_payload.json` with the font atlas and the launcher. The payload contains no game code.
- **Player side** (`patcher/debug_console_patcher.py`, Python standard library only): reads the decrypted SWF from a
  temporary copy of the game, inserts the atlas (`DefineBitsLossless2` + `ExportAssets` "dcon_atlas") and the
  DoAction into frame 1 after the game's own script, writes `Debug Console/isaac_console.swf` and
  `Debug Console/Debug Console.exe`, and prints the Steam launch option.

`--swf` patches another mod's result (EID Flash, Stats HUD) instead; the patcher recognises them by their atlas
exports. All three mods carry the same projector compatibility code (`as2/dcon_host.as`); later copies skip
themselves when `_root.fullf.eidHost` is already set.

## The console

`as2/dcon_console.as` adds `_root.dconLayer` (depth 1048510, above the other mods' overlays) and a `Key` listener.

- **Opening and pausing:** `;` opens it during a run (`_root._currentframe == 2`), once the room has run for 15
  frames (`fra >= 15`, no teleport pending): pausing a room that is still being set up and then spawning into it can
  hang the game's free-spot search (`posw`), so an earlier `;` is kept and the console opens when the room is ready. The game loop is the game clip's
  `onEnterFrame` (`_root.a`, DefineSprite 6765); the console takes it off while open, so the game is paused, and
  puts it back after Esc / Enter / `;` are released (the game would read a held Esc as its pause key). The game
  only polls keys (`Key.isDown`, no listeners), so typing doesn't reach it.
- **Keys:** `Key.getAscii()` returns the key code for punctuation keys in the Flash Player projector (186 for `;`),
  so those are mapped as on a US keyboard.
- **Text:** EID's bitmap font, copied from an atlas into one `BitmapData`, at scale 1.6 (2 screen pixels per font
  pixel at the default 800x600 window).

## How the commands use the game

| Command | Game code |
|---|---|
| `giveitem c#` | `powerlevel()` with `highs = player`, `player.it = id`, `lastcra = -100`: the way the game gives challenge and character starting items (`golev()`). For an active item `_root.it` is cleared first; otherwise `powerlevel()` would turn the player into the old item's pedestal. `gofind` is set so the item isn't added to the save's collection, and the unlocks `powerlevel()` can set (`_root.locker[37/40/47]`) are put back. |
| `giveitem t# / k# / p#` | A pickup is spawned and collected with `pillc()`, the game's trinket/card/pill pickup code, which also drops what Isaac held. Trinket ids are the game's values (29 - 62). Card ids are Rebirth's, mapped to the game's card values with EID Flash's table. Pills are colors 1 - 6 (`_root.piller[color]` only gets an effect when the first pill of the color is taken). |
| `remove` | `_root.ups[id]` and the room copy `ups[id]` (made by `upa()` for every room) minus 1, `_root.it` cleared for the held active item, the item taken out of `_root.cols`; trinkets from `_root.trix` / `_root.atrix`. |
| `spawn` | `spaw(x, y, r, code)` about 80 px from Isaac. Codes: entity type + variant / 10 (the game's alternate versions); pickups `5 + frame / 100 + col / 10^9` (frames: 1 heart, 2 coin, 3 key, 4 bomb, 5 chest, 6 locked chest, 7 card/pill/trinket; col: the kind), pedestals `5.1 + id / 10000` (as in `create()`). |
| `goto` | `tar = room; telf = fra + 2`, the room teleport that cards and the devil door use. Rooms: `_root.boner` (treasure), `shopl`, `bossl`, `minb`, `hide`, `hide2`, `gamb`, `cus`, `chamb`, `lib`, `sac`, 35 (start), 166 (devil), 169 (I AM ERROR). `s.angel` sets `_root.altsat` and `levz[166] = "sata"` (Wrath of the Lamb's holy room) for the rest of the floor. |
| `stage` | `_root.chaps = n - 1; newstart(false, true)`, the trapdoor's next floor without the cutscene. Floors: 1 - 8, 9 Sheol / Cathedral, 11 The Chest (`levn` / `levn2`); the alternate floor (Cellar, ...) is the game's own random choice. |
| `restart` | `newstart(true)`, as holding R does. |
| `debug 3` | Every frame: `player.hp` at least `player.mhp` (soul hearts for ???). |
| `debug 4` | `dmgdo()` (the damage of every tear) is wrapped to add 40; re-applied to each room's game clip. |
| `debug 8` | `_root.itc = 1` (the active item's charge) every frame. |
| `debug 9` | `_root.luck` +50 / -50. |
| `debug 10` | `hurt()` on every enemy each frame, as the Death card does (not shopkeepers or fireplaces). |

## Layout

| Path | Purpose |
|---|---|
| `as2/dcon_host.as` | Projector compatibility (fullscreen, quit), same as EID Flash's; skipped when another mod's copy is there. |
| `as2/dcon_console.as` | The console: data tables, commands, autocomplete, drawing, key handling. |
| `patcher/debug_console_patcher.py` | The player-facing patcher. |
| `patcher/debug_console_payload.json` | Generated by `build.py`: compiled code + atlas + launcher. Contains no game code. |
| `patcher/README.txt` | Player instructions, shipped in the release zip. |
| `launcher/DebugConsoleLauncher.cs` | `Debug Console.exe`: starts the projector with `isaac_console.swf`, ignores Steam's `%command%`, waits for the game. |
| `tools/dcon_assets.py` | Builds the font atlas and glyph table from `resources/font/eid_default.fnt`. |
| `tools/make_payload.py`, `tools/build.py` | Payload and developer build (`--swf` to patch another SWF). |
| `tools/package.py`, `tools/build_exe.py` | Release zip and `Debug_Console_Patcher.exe` (PyInstaller). |
| `tools/swfdump.py` | Dumps `<work>/isaac.swf` with the patcher's dump code. |
| `tools/test/` | `keys.ps1` (keys and `text:` typing), `shot.ps1`, `screen.ps1` for in-game tests. |

## Building

The work directory (`$DEBUG_CONSOLE_WORK`, else `$EID_FLASH_WORK`, default `~/flash-isaac-decomp`, shared with the
other mods; output in `<work>/build/debug_console/`) holds everything derived from the game. **Never commit it.**
Requirements are the same as for EID Flash: Windows, Python 3 with Pillow, Java 21 and JPEXS FFDec in `<work>/tools`.

```sh
python flash/tools/swfdump.py      # once (or reuse the other mods'): writes <work>/isaac.swf
python flash/tools/build.py        # refreshes patcher/debug_console_payload.json -> <work>/build/debug_console/isaac_console.swf
python flash/tools/package.py      # -> <work>/build/debug_console/Debug_Console_<version>.zip
python flash/tools/build_exe.py    # -> <work>/build/debug_console/exe/Debug_Console_Patcher.exe (pip install pyinstaller)
```

## Credits

- Font from External Item Descriptions by Wofsauge and contributors, see `../CREDITS.md`.
- The Binding of Isaac © Edmund McMillen & Florian Himsl. No game code or assets are included here.
