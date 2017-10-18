Introduction
------------

**PoE-ItemInfo** grew out of smaller scripts. It is included in the even bigger PoE-TradeMacro (see "Links").

ItemInfo itself brings the following features:
* Affix overview on all items, in particular:
  * Roll ranges and roll tier classification for rare/magic equipment
  * Roll ranges for uniques, flasks and jewels
* Maps: infos such as the 3->1 vendor recipe result, bosses, layout and possible divination cards
  * Optional "Map Mod Warnings" when certain affixes are present
* Divination Cards: drop locations
* Gems: display the quality effect
* Calculate chaos value of other currency items with ratios fetched from http://poe.ninja/
* Optional "Additional Macros" for fast hideout travel (via chat command), faster stash tab selection and more

Many of these features are user-adjustable in the settings menu or corresponding .ini files.

Links
-----
ItemInfo Forum Thread: https://www.pathofexile.com/forum/view-thread/1678678  
TradeMacro GitHub page: https://poe-trademacro.github.io/  
TradeMacro Forum Thread: https://www.pathofexile.com/forum/view-thread/1757730  

Requirements
------------
A recent AutoHotkey version. You can get AutoHotkey from http://ahkscript.org/  
Use the typical version which is v1.1.xx, do **not** use v2 from "Other Releases".

Known Issues
------------
The script is not always right. Take it as a helper, not as dead certainty.

Essence mods are not marked in any way, so the script will treat them as a regular mod or mark them as unknown.  
Crafted mods are marked ingame, but not in the data visible to the script. The script recognizes a few crafted mods, but will treat the majority as regular mods or mark them as unknown.

Attribution
-----------
Foundations created by
* Nipper4369 and original authors (http://www.pathofexile.com/forum/view-thread/594346)  
* Hazydoc (https://www.pathofexile.com/forum/view-thread/790438)  

Extended, updated and curated by Slinkston and Bahnzo from Oct 2015 - Apr 2016 (https://www.pathofexile.com/forum/view-thread/1463814)  
Currently extended, updated and curated by aRTy42 and Eruyome (TradeMacro)

Contributors
------------
See AUTHORS.txt for contributor info.
