Debug Console for The Binding of Isaac (Flash)
==============================================

The debug console of Rebirth / Repentance for the original Flash version of The Binding of
Isaac (Steam, including Wrath of the Lamb). Press ; during a run to open it.

This package contains NO game files. The patcher builds the modded game from your own copy.


Requirements
------------
- Windows
- The Binding of Isaac (Flash) installed, e.g. from Steam
- For the script version only: Python 3.8 or newer (https://www.python.org/downloads/),
  no extra packages needed


Install
-------
With the exe (Debug_Console_Patcher.exe):
1. Put Debug_Console_Patcher.exe in the folder where you want to keep the game (the
   "Debug Console" folder is created next to it) and double-click it.
2. A game window appears for a few seconds while the patcher reads the game, then closes.
3. At the end, the patcher shows a Steam launch option and copies it to your clipboard
   (see "Steam" below).
4. Start the game with Steam's Play button (after pasting the launch option) or with
   "Debug Console\Debug Console.exe".

With the Python script (this zip):
1. Unzip this folder anywhere.
2. Open a command prompt in this folder and run:

       python debug_console_patcher.py --get-projector

3. Start the game with Steam's Play button (after pasting the launch option it shows) or with
   "Debug Console\Debug Console.exe".

If the game is not in your Steam library, add --game "<folder with Isaac.exe>"
(for the exe: run it from a command prompt with that option).

The exe and --get-projector download Adobe's official Flash Player 32 projector
(flashplayer_32_sa.exe) from fpdownload.macromedia.com and check its fingerprint. You can also put
your own copy into the "Debug Console" folder instead (exe: use --no-projector).


Together with other mods
------------------------
The TBoI Flash Mods installer (https://github.com/tomandesMSH/FlashTBoI-Mods) lets you tick the
mods you want. Or patch another mod's result instead of the original game, e.g.:

    Debug_Console_Patcher.exe --swf "EID Flash\isaac_eid.swf"


Steam
-----
At the end, the patcher shows a launch option like this and copies it to your clipboard:

    "<your folder>\Debug Console\Debug Console.exe" %command%

Paste it into Steam: Library > right-click The Binding of Isaac > Properties > General >
Launch Options. To play the normal game again, clear the Launch Options box.


Commands
--------
giveitem / g <c#|t#|k#|p#|name>   collectible, trinket, card or pill color (1 - 6), e.g. g c12,
                                  g sad onion, giveitem the polaroid, g k1
remove / r <c#|t#|name>           takes a collectible or trinket away
spawn <type>[.<variant>[.<sub>]]  enemies by type (spawn 10), pickups as in Repentance:
                                  5.10 heart, 5.20 coin, 5.30 key, 5.40 bomb, 5.50 chest,
                                  5.60 locked chest, 5.70 pill, 5.100.<id> collectible,
                                  5.300.<id> card, 5.350.<id> trinket
goto s.<room> / goto <number>     default, treasure, shop, boss, miniboss, secret, supersecret,
                                  arcade, curse, challenge, library, sacrifice, devil, angel, error
stage <1 - 11>                    1 - 8, 9 or 10 Sheol / Cathedral, 11 The Chest
restart                           new run
debug <flag>                      3 infinite HP, 4 high damage, 8 infinite item charges,
                                  9 high luck, 10 quick kill
repeat [times], clear, help

Tab completes, Up / Down go through earlier commands, Esc or ; closes the console. The game is
paused while the console is open.


Playing
-------
- The modded game uses the same save as the Steam version. Don't run both at the same time.
  Items given with the console don't unlock anything, but what you do afterwards counts as usual.
- Steam achievements: the launcher sends the achievements you unlock to Steam a few seconds
  later, with the game's own FlashAchievements.exe (Steam must be running). achievements.log
  next to the launcher shows what was sent.
- Your game files are never modified. To uninstall, clear the Steam launch option (if you set
  it) and delete the "Debug Console" folder.


Credits
-------
Font from External Item Descriptions by Wofsauge and contributors:
https://github.com/wofsauge/External-Item-Descriptions
The Binding of Isaac (c) Edmund McMillen & Florian Himsl.
