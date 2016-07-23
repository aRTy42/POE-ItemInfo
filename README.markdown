Introduction
------------

**PoE Item Info** is a heavily extended version of the PoE Item Level and DPS Revealer script.

The script has been added to substantially to enable the following features in addition to
itemlevel and weapon DPS reveal:

- show total affix statistic for rare items
- show possible min-max ranges for all affixes on rare items
- reveal the combination of difficult compound affixes (you might be surprised what you find)
- show affix ranges for uniques
- show map info
- show max sockets info
- has the ability to convert currency items to chaos orbs (you can adjust the rates by editing
    `data\CurrencyRates.txt`)
- optional macros for fast hideout travel (via chat command), faster stash tab selection and more.
- adds a system tray icon and proper system tray description tooltip

All of these features are user-adjustable by using a "database" of text files which come
with the script and are easy to edit by non developers. See header comments in those files
for format infos and data sources.

Please note that the PoE Item Level and DPS Revealer script and PoE Item Info have been merged
into this version.

PoE Forums Thread
-----------------

https://www.pathofexile.com/forum/view-thread/1678678

Requirements
------------

AutoHotkey v1.1.05 or newer. You can get AutoHotkey from https://autohotkey.com


Known Issues
------------

The script is not always right. Take it as a helper, not as dead certainty.

Even though there have been lots of tests made on composite affix combinations, I expect there
to be odd edge cases still that may return an invalid or not found affix bracket. In general,
be alert when it comes to composite affixes.

You can see these entries in the affix detail lines if they have the text `n/a` (not available)
somewhere in them or if you see an empty range ` - *`.

The star, by the way, marks ranges that have been added together for a guessed attempt as to the
composition of a possible compound affix.

If you see this star, take a closer look for a moment to check if the projection is correct.
I expect these edge cases to be properly dealt with over time as the script matures.

See start of script for some more background info on these issues.

Contributors
------------

See AUTHORS.txt for contributor info.

Attribution
-----------

Created by Nipper4369 and original authors.  
Created by hazydoc / IGN: Sadou
Updated/Curated by Slinkston and Bahnzo from Oct 2015 - Apr 2016
currently Updated/Curated by aRTy42

Supersedes the POE_iLVL_DPS-Revealer script.

See http://www.pathofexile.com/forum/view-thread/594346 for original author info.
