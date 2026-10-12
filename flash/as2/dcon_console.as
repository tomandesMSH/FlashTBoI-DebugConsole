// ---------------- Debug Console: Flash edition ----------------
// Compiled on its own (after the generated dcon_data.as: glyph table of the EID font) by flash/tools/make_payload.py;
// the patcher inserts it into frame 1 of the game's root timeline, after the game's own script.
//
// A console like Repentance's debug console. ";" opens it during a run, Esc (or ";") closes it. While it is open the
// game is paused (the game clip's onEnterFrame, its whole game loop, is taken off and put back on close).
// Commands use the game's own functions in the game clip _root.a (sprite 6765):
//  - giveitem c#: powerlevel() with highs = player, as the game gives challenge and character starting items
//  - giveitem t# / k# / p#: a pickup is spawned (spaw) and collected with pillc(), the game's pickup code
//  - spawn: spaw(x, y, r, type) with the game's type codes (5.FF0000000CC for pickups, 5.1 + id / 10000 for pedestals)
//  - goto: the room teleport tar / telf (as cards and the devil door use it)
//  - stage / restart: newstart(), as the trapdoor and holding R use it

_root.dconCfg = {scale:1.6, width:400, lines:12, suggestions:8, alpha:100};
_root.dconColors = {text:0xFFFFFF, echo:0x9A9A9A, error:0xFF6464, ok:0x8CFF8C, hint:0xFFE08C, input:0xFFFFFF, sel:0xFFE08C};
_root.dconAtlas = flash.display.BitmapData.loadBitmap("dcon_atlas");
_root.dconTinted = {};

// ------------------------------------------------------------------ data

// Repentance card ids (k#) -> the game's card value (pickup col) and name
_root.dconCards = [];
_root.dconCards[1] = [11,"0 - The Fool"];
_root.dconCards[2] = [12,"I - The Magician"];
_root.dconCards[3] = [25,"II - The High Priestess"];
_root.dconCards[4] = [26,"III - The Empress"];
_root.dconCards[5] = [22,"IV - The Emperor"];
_root.dconCards[6] = [24,"V - The Hierophant"];
_root.dconCards[7] = [18,"VI - The Lovers"];
_root.dconCards[8] = [17,"VII - The Chariot"];
_root.dconCards[9] = [20,"VIII - Justice"];
_root.dconCards[10] = [13,"IX - The Hermit"];
_root.dconCards[11] = [7,"X - Wheel of Fortune"];
_root.dconCards[12] = [10,"XI - Strength"];
_root.dconCards[13] = [15,"XII - The Hanged Man"];
_root.dconCards[14] = [9,"XIII - Death"];
_root.dconCards[15] = [21,"XIV - Temperance"];
_root.dconCards[16] = [8,"XV - The Devil"];
_root.dconCards[17] = [23,"XVI - The Tower"];
_root.dconCards[18] = [28,"XVII - The Stars"];
_root.dconCards[19] = [14,"XVIII - The Moon"];
_root.dconCards[20] = [27,"XIX - The Sun"];
_root.dconCards[21] = [16,"XX - Judgement"];
_root.dconCards[22] = [19,"XXI - The World"];
_root.dconCards[23] = [71,"2 of Clubs"];
_root.dconCards[24] = [73,"2 of Diamonds"];
_root.dconCards[25] = [70,"2 of Spades"];
_root.dconCards[26] = [72,"2 of Hearts"];
_root.dconCards[31] = [74,"Joker"];

// trinkets: t# is the game's trinket value (29 - 62), names as in the game's pickup code
_root.dconTrinkets = ["Fish Head","Pinky Eye","Push Pin","Liberty Cap","Umbilical Cord","Child's Heart","Curved Horn","Rusted Key","Goat Hoof","Mom's Pearl","Cancer","Red Patch","Match Stick","Lucky Toe","Cursed Skull","Safety Cap","Ace of Spades","Isaac's Fork","The Polaroid","A Missing Page","Bloody Penny","Burnt Penny","Flat Penny","Counterfeit Penny","Tick","Isaac's Head","Maggy's Faith","Judas' Tongue","???'s Soul","Samson's Lock","Cain's Eye","Eve's Bird Foot","The Left Hand","Game Squid"];

// active items (the list in powerlevel() that makes an item the one used with SPACE)
_root.dconActives = [33,34,35,36,37,38,39,40,41,42,43,44,45,47,49,56,58,65,66,77,78,83,84,85,86,93,97,102,105,107,111,123,124,126,127,130,133,135,136,137,145,146,147,158,160,164,166,171,175,177,181,186,192];

// goto s.<name>: the game's room variables (_root.<var>) or fixed room numbers
_root.dconRooms = [["default",35],["treasure","boner"],["shop","shopl"],["boss","bossl"],["miniboss","minb"],["secret","hide"],["supersecret","hide2"],["arcade","gamb"],["curse","cus"],["challenge","chamb"],["library","lib"],["sacrifice","sac"],["devil",166],["angel",166],["error",169]];

// stage numbers: 1 - 8 as in the game, 9 / 10 Sheol (or Cathedral), 11 The Chest
_root.dconStages = [0,"Basement / Cellar 1","Basement / Cellar 2","Caves / Catacombs 1","Caves / Catacombs 2","Depths / Necropolis 1","Depths / Necropolis 2","Womb / Utero 1","Womb / Utero 2","Sheol / Cathedral","Sheol / Cathedral","The Chest"];

// spawn 5.<variant>.<subtype> (Repentance pickup variants) -> the game's pickup frame; subtypes are the game's col
_root.dconPickups = [[10,1,"heart (1 full, 2 half, 3 soul, 4 eternal)"],[20,2,"coin (1 penny, 2 nickel, 3 dime)"],[30,3,"key (1 key, 2 golden key)"],[40,4,"bomb (1 bomb, 2 double, 3 troll)"],[50,5,"chest"],[60,6,"locked chest"],[70,7,"pill (subtype: color 1 - 6)"],[100,10,"collectible (subtype: item id)"],[300,7,"card (subtype: card id)"],[350,7,"trinket (subtype: trinket id)"]];

// debug flags (debug <n>)
_root.dconFlagNames = [];
_root.dconFlagNames[3] = "Infinite HP";
_root.dconFlagNames[4] = "High damage (+40)";
_root.dconFlagNames[8] = "Infinite item charges";
_root.dconFlagNames[9] = "High luck (+50)";
_root.dconFlagNames[10] = "Quick kill (enemies die)";
_root.dconFlags = [];

// ------------------------------------------------------------------ text rendering (EID bitmap font)

function dconTint(color)
{
   var bmp = _root.dconTinted[color];
   if(bmp == undefined)
   {
      bmp = _root.dconAtlas.clone();
      bmp.colorTransform(bmp.rectangle,new flash.geom.ColorTransform((color >> 16 & 255) / 255,(color >> 8 & 255) / 255,(color & 255) / 255,1,0,0,0,0));
      _root.dconTinted[color] = bmp;
   }
   return bmp;
}

function dconTextWidth(str)
{
   var w = 0;
   var i = 0;
   while(i < str.length)
   {
      var gl = _root.dconGlyph[str.charCodeAt(i)];
      if(gl != undefined)
      {
         w += gl[6];
      }
      i++;
   }
   return w;
}

function dconDrawText(canvas, str, x, y, color)
{
   var src = dconTint(color);
   var i = 0;
   while(i < str.length)
   {
      var gl = _root.dconGlyph[str.charCodeAt(i)];
      if(gl != undefined)
      {
         if(gl[2] > 0)
         {
            canvas.copyPixels(src,new flash.geom.Rectangle(gl[0],gl[1],gl[2],gl[3]),new flash.geom.Point(x + gl[4],y + gl[5]),null,null,true);
         }
         x += gl[6];
      }
      i++;
   }
   return x;
}

// greedy word wrap to the console width
function dconWrap(str, width)
{
   var out = [];
   var words = str.split(" ");
   var line = "";
   var i = 0;
   while(i < words.length)
   {
      var next = line == "" ? words[i] : line + " " + words[i];
      if(line != "" && dconTextWidth(next) > width)
      {
         out.push(line);
         line = "  " + words[i];
      }
      else
      {
         line = next;
      }
      i++;
   }
   out.push(line);
   return out;
}

// ------------------------------------------------------------------ catalog (giveitem / remove names)

function dconNorm(str)
{
   var s = str.toLowerCase();
   var out = "";
   var i = 0;
   while(i < s.length)
   {
      var c = s.charCodeAt(i);
      if(c >= 48 && c <= 57 || c >= 97 && c <= 122)
      {
         out += s.charAt(i);
      }
      i++;
   }
   return out;
}

function dconValidItem(id)
{
   var n = _root.st1[id];
   return id >= 1 && id <= 198 && id != 43 && id != 61 && typeof n == "string" && n != "";
}

// every collectible (item names from the game's own table _root.st1), trinket, card and pill color
function dconCatalog()
{
   if(_root.dconCat != undefined)
   {
      return _root.dconCat;
   }
   var cat = [];
   var i = 1;
   while(i <= 198)
   {
      if(dconValidItem(i))
      {
         cat.push({key:"c" + i,kind:"c",id:i,name:_root.st1[i]});
      }
      i++;
   }
   i = 0;
   while(i < _root.dconTrinkets.length)
   {
      cat.push({key:"t" + (i + 29),kind:"t",id:i + 29,name:_root.dconTrinkets[i]});
      i++;
   }
   for(var k in _root.dconCards)
   {
      cat.push({key:"k" + k,kind:"k",id:Number(k),name:_root.dconCards[k][1]});
   }
   i = 1;
   while(i <= 6)
   {
      cat.push({key:"p" + i,kind:"p",id:i,name:"Pill (color " + i + ")"});
      i++;
   }
   i = 0;
   while(i < cat.length)
   {
      cat[i].norm = dconNorm(cat[i].name);
      i++;
   }
   _root.dconCat = cat;
   return cat;
}

// entries for "c12", "t47", "k1", "p3" or a (part of a) name; exact names first, then starts, then contains
function dconFind(arg)
{
   var cat = dconCatalog();
   var a = arg.toLowerCase();
   var i = 0;
   var exact = [];
   var starts = [];
   var contains = [];
   var n = dconNorm(a);
   if(n == "")
   {
      return [];
   }
   while(i < cat.length)
   {
      var e = cat[i];
      if(e.key == a)
      {
         return [e];
      }
      if(e.norm == n)
      {
         exact.push(e);
      }
      else if(e.norm.indexOf(n) == 0 || e.key.indexOf(a) == 0 && a.length > 1 && !isNaN(Number(a.substr(1))))
      {
         starts.push(e);
      }
      else if(e.norm.indexOf(n) > 0)
      {
         contains.push(e);
      }
      i++;
   }
   return exact.concat(starts,contains);
}

// ------------------------------------------------------------------ console output

function dconPrint(str, color)
{
   var L = _root.dconLayer;
   var lines = dconWrap(str,_root.dconCfg.width - 8);
   var i = 0;
   while(i < lines.length)
   {
      L.out.push([lines[i],color == undefined ? _root.dconColors.text : color]);
      i++;
   }
   while(L.out.length > 200)
   {
      L.out.shift();
   }
   L.dirty = true;
}

function dconError(str)
{
   dconPrint(str,_root.dconColors.error);
}

function dconOk(str)
{
   dconPrint(str,_root.dconColors.ok);
}

// ------------------------------------------------------------------ commands

function dconGame()
{
   return _root.a;
}

function dconIsActive(id)
{
   var i = 0;
   while(i < _root.dconActives.length)
   {
      if(_root.dconActives[i] == id)
      {
         return true;
      }
      i++;
   }
   return false;
}

// powerlevel() changes these save values when given certain items; the console doesn't unlock anything
function dconSaveLocks()
{
   return [_root.locker[37],_root.locker[40],_root.locker[47],_root.colss[43],_root.colss[61]];
}

function dconRestoreLocks(s)
{
   _root.locker[37] = s[0];
   _root.locker[40] = s[1];
   _root.locker[47] = s[2];
   _root.colss[43] = s[3];
   _root.colss[61] = s[4];
}

function dconGiveCollectible(g, id)
{
   var locks = dconSaveLocks();
   if(dconIsActive(id))
   {
      // the held active item is replaced (powerlevel would otherwise turn the player into the old item's pedestal)
      _root.it = 0;
   }
   g.gofind = true;
   g.lastcra = -100;
   g.player.empty = false;
   g.highs = g.player;
   g.player.it = id;
   g.powerlevel();
   g.gofind = undefined;
   dconRestoreLocks(locks);
}

// spawns about 80 px from Isaac towards the middle of the room (spaw() looks for a free spot near that point), so
// enemies don't appear on top of him
function dconSpawnNear(g, code)
{
   var x = g.player.xp + (g.player.xp < 320 ? 80 : -80);
   return g.spaw(x,g.player.yp,0,code);
}

// trinkets, cards and pills: a pickup is spawned next to Isaac and collected with the game's pickup code, which also
// drops what Isaac was holding
function dconGivePickup(g, col)
{
   var locks = dconSaveLocks();
   var e = dconSpawnNear(g,5.07 + col / 1000000000);
   e.col = col;
   g.highs = e;
   g.pillc(e);
   dconRestoreLocks(locks);
}

function dconCmdGive(args)
{
   if(args == "")
   {
      dconError("Usage: giveitem <c#|t#|k#|p#|name>, e.g. giveitem c12, giveitem sad onion");
      return undefined;
   }
   var found = dconFind(args);
   if(found.length == 0)
   {
      dconError("No item, trinket, card or pill called \"" + args + "\"");
      return undefined;
   }
   var e = found[0];
   var g = dconGame();
   if(e.kind == "c")
   {
      dconGiveCollectible(g,e.id);
   }
   else if(e.kind == "t")
   {
      dconGivePickup(g,e.id);
   }
   else if(e.kind == "k")
   {
      dconGivePickup(g,_root.dconCards[e.id][0]);
   }
   else
   {
      dconGivePickup(g,e.id);
   }
   dconOk("Gave " + e.key + " " + e.name);
}

function dconCmdRemove(args)
{
   var found = dconFind(args);
   var e = found[0];
   var g = dconGame();
   if(args == "" || e == undefined || (e.kind != "c" && e.kind != "t"))
   {
      dconError("Usage: remove <c#|t#|name> (collectibles and trinkets)");
      return undefined;
   }
   if(e.kind == "t")
   {
      if(_root.trix == e.id)
      {
         _root.trix = _root.atrix;
         _root.atrix = undefined;
      }
      else if(_root.atrix == e.id)
      {
         _root.atrix = undefined;
      }
      else
      {
         dconError("Isaac doesn't have " + e.name);
         return undefined;
      }
      dconOk("Removed " + e.key + " " + e.name);
      return undefined;
   }
   if(!(_root.ups[e.id] > 0))
   {
      dconError("Isaac doesn't have " + e.name);
      return undefined;
   }
   _root.ups[e.id] = Math.max(0,_root.ups[e.id] - 1);
   g.ups[e.id] = _root.ups[e.id];
   if(dconIsActive(e.id) && _root.it == e.id - g.itn(e.id))
   {
      _root.it = 0;
   }
   var i = 0;
   while(i < _root.cols.length)
   {
      if(_root.cols[i] == e.id)
      {
         _root.cols.splice(i,1);
         break;
      }
      i++;
   }
   dconOk("Removed " + e.key + " " + e.name + " (its look and some effects stay)");
}

// spawn <type>[.<variant>[.<subtype>]]
function dconCmdSpawn(args)
{
   var p = args.split(".");
   var t = Number(p[0]);
   var v = p.length > 1 ? Number(p[1]) : 0;
   var s = p.length > 2 ? Number(p[2]) : 0;
   if(args == "" || isNaN(t) || isNaN(v) || isNaN(s))
   {
      dconError("Usage: spawn <type>[.<variant>[.<subtype>]], e.g. spawn 10 (Gaper), spawn 5.100.12, spawn 5.10.3");
      return undefined;
   }
   var g = dconGame();
   var code;
   if(t == 5)
   {
      var pk = undefined;
      var i = 0;
      while(i < _root.dconPickups.length)
      {
         if(_root.dconPickups[i][0] == v)
         {
            pk = _root.dconPickups[i];
         }
         i++;
      }
      if(pk == undefined)
      {
         dconError("Pickup variants: 10 heart, 20 coin, 30 key, 40 bomb, 50 chest, 60 locked chest, 70 pill, 100 collectible, 300 card, 350 trinket");
         return undefined;
      }
      if(v == 100)
      {
         if(s != 0 && !dconValidItem(s))
         {
            dconError("No collectible " + s);
            return undefined;
         }
         code = 5.1 + s / 10000;
      }
      else
      {
         var col = s;
         if(v == 300 && s != 0)
         {
            if(_root.dconCards[s] == undefined)
            {
               dconError("No card " + s);
               return undefined;
            }
            col = _root.dconCards[s][0];
         }
         if(v == 350 && s != 0 && (s < 29 || s > 62))
         {
            dconError("Trinkets are 29 - 62");
            return undefined;
         }
         if(v == 300 && s == 0)
         {
            col = g.tater();
         }
         if(v == 350 && s == 0)
         {
            col = 29 + random(34);
         }
         if(col > 99)
         {
            col = 0;
         }
         code = 5 + pk[1] / 100 + col / 1000000000;
      }
   }
   else
   {
      if(t < 10 || t > 101 || g.hps[t] == undefined || v < 0 || v > 2)
      {
         dconError("Entity types are 10 - 101 (variant 1 or 2: the game's other versions), pickups 5.<variant>.<subtype>");
         return undefined;
      }
      code = t + v / 10;
   }
   var e = dconSpawnNear(g,code);
   if(t == 5 && pk[1] == 7 && col > 0)
   {
      e.col = col;
   }
   dconOk("Spawned " + args);
}

// room number for "s.<name>" / "<number>", or an error text
function dconRoom(arg)
{
   var a = arg.toLowerCase();
   if(a.indexOf("s.") == 0)
   {
      a = a.substr(2);
   }
   var i = 0;
   while(i < _root.dconRooms.length)
   {
      var r = _root.dconRooms[i];
      if(r[0] == a)
      {
         var n = typeof r[1] == "number" ? r[1] : _root[r[1]];
         if(!(n > 0) || n != 166 && n != 169 && !_root.levz[n])
         {
            return "There is no " + r[0] + " room on this floor";
         }
         if(n == 166 && _root.chaps >= 9)
         {
            return "There is no devil or angel room on this floor";
         }
         return n;
      }
      i++;
   }
   var num = Number(a);
   if(a != "" && !isNaN(num))
   {
      if(num == 166 || num == 169 || _root.levz[num])
      {
         return num;
      }
      return "There is no room " + num + " on this floor";
   }
   return "Usage: goto s.<room> (" + dconRoomNames() + ") or goto <room number>";
}

function dconRoomNames()
{
   var out = [];
   var i = 0;
   while(i < _root.dconRooms.length)
   {
      out.push(_root.dconRooms[i][0]);
      i++;
   }
   return out.join(", ");
}

function dconCmdGoto(args)
{
   var n = dconRoom(args);
   if(typeof n == "string")
   {
      dconError(n);
      return undefined;
   }
   var name = args.toLowerCase();
   dconOk("Going to room " + n + " (" + args + ")");
   dconClose(function()
   {
      var g = dconGame();
      // devil room or its angel version (Wrath of the Lamb's holy room) for the rest of this floor
      if(name == "s.angel" || name == "angel")
      {
         _root.altsat = true;
         _root.levz[166] = "sata";
      }
      else if((name == "s.devil" || name == "devil") && _root.altsat)
      {
         _root.altsat = false;
         _root.levz[166] = "satan";
      }
      g.tar = n;
      g.telf = g.fra + 2;
   });
}

function dconCmdStage(args)
{
   var n = Number(args);
   if(args == "" || isNaN(n) || n < 1 || n > 11 || n != Math.floor(n))
   {
      dconError("Usage: stage <1 - 11>: 1 - 8, 9 or 10 Sheol / Cathedral, 11 The Chest");
      return undefined;
   }
   if(n == 10)
   {
      n = 9;
   }
   dconOk("Going to " + _root.dconStages[n]);
   dconClose(function()
   {
      _root.chaps = n - 1;
      _root.fade = true;
      dconGame().newstart(false,true);
   });
}

function dconCmdRestart(args)
{
   dconOk("Restarting");
   dconClose(function()
   {
      _root.fade = true;
      dconGame().newstart(true);
   });
}

function dconCmdDebug(args)
{
   var n = Number(args);
   if(args == "" || _root.dconFlagNames[n] == undefined)
   {
      if(args != "")
      {
         dconError("Debug flag " + args + " doesn't exist in the Flash version");
      }
      var k = 0;
      while(k < _root.dconFlagNames.length)
      {
         if(_root.dconFlagNames[k] != undefined)
         {
            dconPrint("  " + k + ": " + _root.dconFlagNames[k] + (_root.dconFlags[k] ? "  [on]" : ""),_root.dconColors.hint);
         }
         k++;
      }
      return undefined;
   }
   _root.dconFlags[n] = !_root.dconFlags[n];
   if(n == 9)
   {
      _root.luck += _root.dconFlags[n] ? 50 : -50;
   }
   dconOk(_root.dconFlagNames[n] + (_root.dconFlags[n] ? " on" : " off"));
}

function dconCmdClear(args)
{
   _root.dconLayer.out = [];
   _root.dconLayer.dirty = true;
}

function dconCmdHelp(args)
{
   var c = dconCommand(args);
   if(args != "" && c != undefined)
   {
      dconPrint(c.usage,_root.dconColors.hint);
      dconPrint("  " + c.help);
      return undefined;
   }
   var i = 0;
   while(i < _root.dconCommands.length)
   {
      c = _root.dconCommands[i];
      dconPrint(c.name + (c.alias ? " (" + c.alias + ")" : "") + " - " + c.help,_root.dconColors.hint);
      i++;
   }
   dconPrint("Tab completes, Up / Down go through earlier commands, Esc or ; closes.",_root.dconColors.echo);
}

function dconCmdRepeat(args)
{
   var n = args == "" ? 1 : Number(args);
   var L = _root.dconLayer;
   if(isNaN(n) || n < 1 || L.lastCmd == undefined)
   {
      dconError("Usage: repeat [times], after another command");
      return undefined;
   }
   var i = 0;
   while(i < Math.min(n,100))
   {
      dconRun(L.lastCmd,true);
      i++;
   }
}

_root.dconCommands = [
   {name:"giveitem",alias:"g",fn:dconCmdGive,usage:"giveitem <c#|t#|k#|p#|name>",help:"Gives a collectible (c), trinket (t), card (k) or pill color (p) by id or name"},
   {name:"remove",alias:"r",fn:dconCmdRemove,usage:"remove <c#|t#|name>",help:"Takes a collectible or trinket away"},
   {name:"spawn",fn:dconCmdSpawn,usage:"spawn <type>[.<variant>[.<subtype>]]",help:"Spawns an entity next to Isaac: enemies 10 - 101, pickups 5.<variant>.<subtype>"},
   {name:"goto",fn:dconCmdGoto,usage:"goto s.<room> | goto <room number>",help:"Teleports to a room of this floor: " + dconRoomNames()},
   {name:"stage",fn:dconCmdStage,usage:"stage <1 - 11>",help:"Goes to a floor: 1 - 8, 9 or 10 Sheol / Cathedral, 11 The Chest"},
   {name:"restart",fn:dconCmdRestart,usage:"restart",help:"Starts a new run"},
   {name:"debug",fn:dconCmdDebug,usage:"debug <flag>",help:"Toggles a debug flag: 3 infinite HP, 4 high damage, 8 infinite charges, 9 high luck, 10 quick kill"},
   {name:"repeat",fn:dconCmdRepeat,usage:"repeat [times]",help:"Runs the last command again"},
   {name:"clear",fn:dconCmdClear,usage:"clear",help:"Clears the console"},
   {name:"help",fn:dconCmdHelp,usage:"help [command]",help:"Lists the commands"}
];

function dconCommand(name)
{
   var n = name.toLowerCase();
   var i = 0;
   while(i < _root.dconCommands.length)
   {
      var c = _root.dconCommands[i];
      if(c.name == n || c.alias == n)
      {
         return c;
      }
      i++;
   }
   return undefined;
}

function dconSplit(line)
{
   var s = line;
   while(s.charAt(0) == " ")
   {
      s = s.substr(1);
   }
   while(s.length > 0 && s.charAt(s.length - 1) == " ")
   {
      s = s.substr(0,s.length - 1);
   }
   var sp = s.indexOf(" ");
   if(sp < 0)
   {
      return [s,""];
   }
   var rest = s.substr(sp + 1);
   while(rest.charAt(0) == " ")
   {
      rest = rest.substr(1);
   }
   return [s.substr(0,sp),rest];
}

function dconRun(line, repeated)
{
   var parts = dconSplit(line);
   if(parts[0] == "")
   {
      return undefined;
   }
   var c = dconCommand(parts[0]);
   if(c == undefined)
   {
      dconError("Unknown command \"" + parts[0] + "\" (type help)");
      return undefined;
   }
   if(c.name != "repeat" && !repeated)
   {
      _root.dconLayer.lastCmd = line;
   }
   c.fn(parts[1]);
}

// ------------------------------------------------------------------ autocomplete

// [display text, completed input] for the current input
function dconSuggest(input)
{
   var out = [];
   var parts = dconSplit(input);
   var hasArg = input.indexOf(" ") >= 0;
   var i = 0;
   if(!hasArg)
   {
      if(parts[0] == "")
      {
         return out;
      }
      while(i < _root.dconCommands.length)
      {
         var c = _root.dconCommands[i];
         if(c.name.indexOf(parts[0].toLowerCase()) == 0 || c.alias == parts[0].toLowerCase())
         {
            out.push([c.usage,c.name + " "]);
         }
         i++;
      }
      return out;
   }
   var cmd = dconCommand(parts[0]);
   if(cmd == undefined)
   {
      return out;
   }
   var arg = parts[1];
   var lower = arg.toLowerCase();
   var pre = parts[0] + " ";
   if(cmd.name == "giveitem" || cmd.name == "remove")
   {
      if(arg == "")
      {
         return out;
      }
      var found = dconFind(arg);
      while(i < found.length && out.length < 50)
      {
         if(cmd.name == "giveitem" || found[i].kind == "c" || found[i].kind == "t")
         {
            out.push([found[i].key + "  " + found[i].name,pre + found[i].key]);
         }
         i++;
      }
   }
   else if(cmd.name == "goto")
   {
      while(i < _root.dconRooms.length)
      {
         var r = "s." + _root.dconRooms[i][0];
         if(r.indexOf(lower) == 0 || _root.dconRooms[i][0].indexOf(lower) == 0)
         {
            out.push([r,pre + r]);
         }
         i++;
      }
   }
   else if(cmd.name == "stage")
   {
      i = 1;
      while(i <= 11)
      {
         if(String(i).indexOf(arg) == 0)
         {
            out.push([i + "  " + _root.dconStages[i],pre + i]);
         }
         i++;
      }
   }
   else if(cmd.name == "debug")
   {
      i = 0;
      while(i < _root.dconFlagNames.length)
      {
         if(_root.dconFlagNames[i] != undefined && String(i).indexOf(arg) == 0)
         {
            out.push([i + "  " + _root.dconFlagNames[i],pre + i]);
         }
         i++;
      }
   }
   else if(cmd.name == "spawn")
   {
      while(i < _root.dconPickups.length)
      {
         var sp = "5." + _root.dconPickups[i][0];
         if(sp.indexOf(lower) == 0 || lower.indexOf(sp + ".") == 0 && false)
         {
            out.push([sp + "  " + _root.dconPickups[i][2],pre + sp]);
         }
         i++;
      }
   }
   else if(cmd.name == "help")
   {
      while(i < _root.dconCommands.length)
      {
         if(_root.dconCommands[i].name.indexOf(lower) == 0)
         {
            out.push([_root.dconCommands[i].name,pre + _root.dconCommands[i].name]);
         }
         i++;
      }
   }
   return out;
}

// ------------------------------------------------------------------ drawing

function dconRedraw(L)
{
   var cfg = _root.dconCfg;
   var lh = _root.dconLineHeight;
   var cv = L.canvas;
   var W = cfg.width;
   cv.fillRect(cv.rectangle,0);
   var boxH = 4 + (cfg.lines + 1) * lh + 4;
   cv.fillRect(new flash.geom.Rectangle(0,0,W,boxH),0xF0101014);
   cv.fillRect(new flash.geom.Rectangle(0,boxH - 1,W,1),0xFF5A5A64);
   // output, newest at the bottom
   var first = Math.max(0,L.out.length - cfg.lines);
   var y = 4 + (cfg.lines - (L.out.length - first)) * lh;
   var i = first;
   while(i < L.out.length)
   {
      dconDrawText(cv,L.out[i][0],4,y - 2,L.out[i][1]);
      y += lh;
      i++;
   }
   // input line with the caret
   var iy = 4 + cfg.lines * lh;
   cv.fillRect(new flash.geom.Rectangle(0,iy - 1,W,1),0x60FFFFFF);
   var x = dconDrawText(cv,"> ",4,iy - 1,_root.dconColors.echo);
   dconDrawText(cv,L.input,x,iy - 1,_root.dconColors.input);
   if(L.blink < 16)
   {
      var cx = x + dconTextWidth(L.input.substr(0,L.caret));
      cv.fillRect(new flash.geom.Rectangle(cx,iy + 1,1,lh - 2),0xFFFFFFFF);
   }
   // suggestions under the console
   var sug = L.sug;
   if(sug.length > 0)
   {
      var count = Math.min(sug.length,cfg.suggestions);
      var top = Math.max(0,Math.min(L.sel - count + 1,sug.length - count));
      var sw = 0;
      i = 0;
      while(i < count)
      {
         sw = Math.max(sw,dconTextWidth(sug[top + i][0]));
         i++;
      }
      var sh = count * lh + 4 + (sug.length > count ? lh : 0);
      cv.fillRect(new flash.geom.Rectangle(4,boxH,sw + 10,sh),0xF0181820);
      i = 0;
      while(i < count)
      {
         var idx = top + i;
         dconDrawText(cv,sug[idx][0],9,boxH + 1 + i * lh,idx == L.sel ? _root.dconColors.sel : _root.dconColors.echo);
         i++;
      }
      if(sug.length > count)
      {
         dconDrawText(cv,"... " + (sug.length - count) + " more",9,boxH + 1 + count * lh,_root.dconColors.echo);
      }
   }
   L.dirty = false;
}

// ------------------------------------------------------------------ open / close, keys

function dconOpen()
{
   var L = _root.dconLayer;
   var g = dconGame();
   L.isOpen = true;
   L.closing = false;
   L.game = g;
   // pause: take the game loop off the game clip
   L.loop = g.onEnterFrame;
   g.onEnterFrame = undefined;
   if(!L.greeted)
   {
      L.greeted = true;
      dconPrint("Debug Console - type help for the commands",_root.dconColors.hint);
   }
   L.input = "";
   L.caret = 0;
   L.hist = -1;
   L.sug = [];
   L.sel = -1;
   L.blink = 0;
   L._visible = true;
   L.dirty = true;
}

// closes the console; after() runs once the game loop is back
function dconClose(after)
{
   var L = _root.dconLayer;
   L.isOpen = false;
   L.closing = true;
   L.after = after;
   L._visible = false;
}

function dconResume(L)
{
   if(_root.a == L.game && L.game.onEnterFrame == undefined && L.loop != undefined)
   {
      L.game.onEnterFrame = L.loop;
   }
   L.loop = undefined;
   L.closing = false;
   var f = L.after;
   L.after = undefined;
   if(f != undefined)
   {
      f();
   }
}

function dconSetInput(L, str, caret)
{
   L.input = str;
   L.caret = caret == undefined ? str.length : caret;
   L.sug = dconSuggest(str);
   L.sel = -1;
   L.blink = 0;
   L.dirty = true;
}

// Flash reports the key code instead of the character for punctuation keys (e.g. 186 for ";"); map them as on a
// US keyboard: [key code, character, character with shift]
_root.dconPunct = [[186,";",":"],[187,"=","+"],[188,",","<"],[189,"-","_"],[190,".",">"],[191,"/","?"],[192,"`","~"],[219,"[","{"],[220,"\\","|"],[221,"]","}"],[222,"'","\""]];

function dconChar(code, ascii)
{
   if(ascii >= 32 && ascii <= 126)
   {
      return ascii;
   }
   var i = 0;
   while(i < _root.dconPunct.length)
   {
      var p = _root.dconPunct[i];
      if(p[0] == code)
      {
         return (Key.dconIsDown(16) ? p[2] : p[1]).charCodeAt(0);
      }
      i++;
   }
   return 0;
}

function dconKey()
{
   var L = _root.dconLayer;
   var code = Key.getCode();
   var ch = dconChar(code,Key.getAscii());
   if(!L.isOpen)
   {
      if(ch == 59 && !L.closing && _root._currentframe == 2 && _root.a.player != undefined && _root.a.onEnterFrame != undefined)
      {
         // opened once the room has run for a moment (dconReady): pausing a room that is still being set up and
         // spawning into it can hang the game's spot search (posw)
         L.pendingOpen = _root.a;
      }
      return undefined;
   }
   if(code == 27 || ch == 59)
   {
      dconClose();
      return undefined;
   }
   if(code == 13)
   {
      var line = L.input;
      if(dconSplit(line)[0] != "")
      {
         dconPrint("> " + line,_root.dconColors.echo);
         if(L.cmds[L.cmds.length - 1] != line)
         {
            L.cmds.push(line);
         }
      }
      dconSetInput(L,"");
      L.hist = -1;
      dconRun(line,false);
      return undefined;
   }
   if(code == 9)
   {
      if(L.sug.length > 0)
      {
         var keep = L.sug;
         var sel = (L.sel + 1) % keep.length;
         L.input = keep[sel][1];
         L.caret = L.input.length;
         L.sug = keep;
         L.sel = sel;
         if(keep.length == 1)
         {
            dconSetInput(L,L.input);
         }
         L.dirty = true;
      }
      return undefined;
   }
   if(code == 38 || code == 40)
   {
      if(L.cmds.length > 0)
      {
         if(code == 38)
         {
            L.hist = L.hist < 0 ? L.cmds.length - 1 : Math.max(0,L.hist - 1);
         }
         else if(L.hist >= 0)
         {
            L.hist++;
         }
         if(L.hist >= 0 && L.hist < L.cmds.length)
         {
            dconSetInput(L,L.cmds[L.hist]);
         }
         else
         {
            L.hist = -1;
            dconSetInput(L,"");
         }
      }
      return undefined;
   }
   if(code == 8)
   {
      if(L.caret > 0)
      {
         dconSetInput(L,L.input.substr(0,L.caret - 1) + L.input.substr(L.caret),L.caret - 1);
      }
      return undefined;
   }
   if(code == 46)
   {
      dconSetInput(L,L.input.substr(0,L.caret) + L.input.substr(L.caret + 1),L.caret);
      return undefined;
   }
   if(code == 37 || code == 39 || code == 36 || code == 35)
   {
      L.caret = code == 36 ? 0 : (code == 35 ? L.input.length : Math.max(0,Math.min(L.input.length,L.caret + (code == 37 ? -1 : 1))));
      L.blink = 0;
      L.dirty = true;
      return undefined;
   }
   if(ch >= 32 && ch <= 126 && L.input.length < 120)
   {
      dconSetInput(L,L.input.substr(0,L.caret) + String.fromCharCode(ch) + L.input.substr(L.caret),L.caret + 1);
   }
}

// debug flags, applied every frame while the game runs
function dconApplyFlags(g)
{
   var F = _root.dconFlags;
   if(F[3])
   {
      g.player.hp = Math.max(g.player.hp,g.player.mhp);
      if(g.player.mhp < 1)
      {
         _root.armor = Math.max(_root.armor,3);
      }
   }
   if(F[4] && !g.dmgdo.dcon)
   {
      var orig = g.dmgdo;
      g.dmgdo = function()
      {
         return arguments.callee.orig.apply(this,arguments) + 40;
      };
      g.dmgdo.orig = orig;
      g.dmgdo.dcon = true;
   }
   else if(!F[4] && g.dmgdo.dcon)
   {
      g.dmgdo = g.dmgdo.orig;
   }
   if(F[8] && _root.it > 0)
   {
      _root.itc = 1;
   }
   if(F[10])
   {
      var i = 0;
      while(i < g.ball.length)
      {
         var e = g.ball[i];
         // as the Death card does it: the game's hurt() on each enemy (not shopkeepers 17 and fireplaces 33)
         if(e.s > 9 && e.s != 17 && e.s != 33 && e.hp > 0 && e != g.player)
         {
            g.hurt(e,e.hp + 100);
         }
         i++;
      }
   }
}

_root.createEmptyMovieClip("dconLayer",1048510);
_root.dconLayer.canvas = new flash.display.BitmapData(_root.dconCfg.width,(_root.dconCfg.lines + 1 + _root.dconCfg.suggestions + 1) * _root.dconLineHeight + 16,true,0);
_root.dconLayer.createEmptyMovieClip("pic",1);
_root.dconLayer.pic.attachBitmap(_root.dconLayer.canvas,1,"never",false);
_root.dconLayer._xscale = _root.dconLayer._yscale = _root.dconCfg.scale * 100;
_root.dconLayer._alpha = _root.dconCfg.alpha;
_root.dconLayer._visible = false;
_root.dconLayer.out = [];
_root.dconLayer.cmds = [];
_root.dconLayer.input = "";
_root.dconLayer.sug = [];
_root.dconLayer.onKeyDown = dconKey;
Key.addListener(_root.dconLayer);

// The root timeline polls keys outside the game loop (M mutes, I changes the quality, H / F the window mode, ...),
// so typing would trigger them. While the console is open (or closing), Key.isDown reports no keys to the game and
// the other mods; the console reads the keys with the original (Key.dconIsDown).
if(Key.dconIsDown == undefined)
{
   Key.dconIsDown = Key.isDown;
   ASSetPropFlags(Key,"isDown",0,4);
   Key.isDown = function(code)
   {
      if(_root.dconLayer.isOpen || _root.dconLayer.closing)
      {
         return false;
      }
      return Key.dconIsDown(code);
   };
}

_root.dconLayer.onEnterFrame = function()
{
   var g = _root.a;
   if(this.isOpen)
   {
      // closed by leaving the game (e.g. the game's own reset)
      if(_root._currentframe != 2 || g != this.game)
      {
         dconClose();
         return undefined;
      }
      this.blink = (this.blink + 1) % 32;
      if(this.blink == 0 || this.blink == 16)
      {
         this.dirty = true;
      }
      if(this.dirty)
      {
         dconRedraw(this);
      }
      return undefined;
   }
   // give the game loop back once Esc / Enter / ; are released (the game would take Esc as its pause key)
   if(this.closing && !Key.dconIsDown(27) && !Key.dconIsDown(13) && !Key.dconIsDown(186))
   {
      dconResume(this);
   }
   if(!this.closing && _root._currentframe == 2 && g.player != undefined && g.onEnterFrame != undefined)
   {
      dconApplyFlags(g);
      if(this.pendingOpen == g && g.fra >= 15 && g.telf == undefined)
      {
         this.pendingOpen = undefined;
         dconOpen();
      }
   }
   else if(_root._currentframe != 2)
   {
      this.pendingOpen = undefined;
   }
};
// ---------------- end Debug Console ----------------
