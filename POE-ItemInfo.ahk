; Path of Exile Item Info Tooltip
;
; Version: 1.9.2 (hazydoc / IGN:Sadou) Original Author
; Script is currently maintained by various people and kept up to date by aRTy42 / IGN: Erinyen
; Forum thread: https://www.pathofexile.com/forum/view-thread/1678678
;
; This script was originally based on the POE_iLVL_DPS-Revealer script (v1.2d) found here:
; https://www.pathofexile.com/forum/view-thread/594346
;
; Changes to the POE_iLVL_DPS-Revealer script as recent as it's version 1.4.1 have been
; brought over. Thank you Nipper4369 and Kislorod!
;
; The script has been added to substantially to enable the following features in addition to
; itemlevel and weapon DPS reveal:
;
;   - show total affix statistic for rare items
;   - show possible min-max ranges for all affixes on rare items
;   - reveal the combination of difficult compound affixes (you might be surprised what you find)
;   - show affix ranges for uniques
;   - show map info (thank you, Kislorod and Necrolis)
;   - show max socket info (thank you, Necrolis)
;   - has the ability to convert currency items to chaos orbs (you can adjust the rates by editing
;     <datadir>\CurrencyRates.txt)
;   - adds a system tray icon and proper system tray description tooltip
;
; All of these features are user-adjustable by using a "database" of text files which come
; with the script and are easy to edit by non developers. See header comments in those files
; for format infos and data sources.
;
; Known issues:
;
;     Even though there have been tons of tests made on composite affix combinations, I expect
;     there to be edge cases still that may return an invalid or not found affix bracket.
;     You can see these entries in the affix detail lines if they have the text "n/a" (not available)
;     somewhere in them or if you see an empty range " - *". The star by the way marks ranges
;     that have been added together for a guessed attempt as to the composition of a possible
;     compound affix. If you see this star, take a closer look for a moment to check if the
;     projection is correct. I expect these edge cases to be properly dealt with over time as the
;     script matures. For now I'd estimate that at least 80% of the truly hard cases are correctly
;     identified.
;
;     Some background info: because the game concatenates values from multiple affix sources into
;     one final entry on the ingame tooltip there is no reliable way to work backwards from the
;     composite value to each individual part. For example, Stun Recovery can be added as suffix if
;     it contributes alone, but can also be a prefix if it is a composite of Stun Recovery and
;     Evasion Rating (or others). Because there is one final entry, while prefix and suffix can
;     appear at the same time and will be added together, you can't reliably reverse engineer which
;     affix contributed what part of the composite value. This is akin to taking a random source of
;     numbers, adding them up to one value and then asking someone to work out backwards what the
;     original source values were.
;     Similarily, in cases like boosted Stun Recovery (1) and Evasion Rating (2) on an item in difficult
;     cases there is no 100% reliable way to tell if the prefix "+ Evasion Rating / incr. Stun Recovery"
;     contributed to both stats at once or if the suffix "+ Stun Recovery" contributed to (1)
;     and the prefix "+ Evasion Rating" cotributed to (2) or possibly a combination of both.
;     Often it is possible to make guesses by working your way backwards from both partial affixes, by
;     looking at the affix bracket ranges and the item level to see what is even possible to be there and
;     what isn't. In the worst case for a double compound affix, all four ranges will be possible to be
;     combined.
;
;     I have tested the tooltip on many, many items in game from my own stash and from trade chat
;     and I can say that in the overwhelming majority of cases the tooltip does indeed work correctly.
;
;     IMPORTANT: as you may know, the total amount of affixes (w/o implicit mods) can be 6, of which
;     3 at most are prefixes and likewise 3 at most are suffixes. Be especially weary, then of cases
;     where this prefix/suffix limit is overcapped. It may happen that the tooltip shows 4 suffixes,
;     and 3 prefixes total. In this case the most likely explanation is that the script failed to properly
;     determine composite affixes. Composite affixes ("Comp. Prefix" or "Comp. Suffix" in the tooltip)
;     are two affix lines on the ingame tooltip that together form one single composite affix.
;     Edit v1.4: This hasn't happened for a longer time now, but I am leaving this important note in
;     so end users stay vigilant (assuming anyone even reads this wall of text :)).
;
;   - I do not know which affixes are affected by +% Item Quality. Currently I have functions in place
;     that can boost a range or a single value to adjust for Item Quality but currently these aren't used
;     much. Partially this is also because it is not easy to tell if out-of-bounds cases are the result
;     of faulty input data (I initially pulled data from the PoE mods compendium but later made the PoE
;     homepage the authoritative source overruling data from other sources) or of other unreckognized and
;     unhandled entities or systems.
;
; Todo:
;
;   - handle ranges for implicit mods
;   - find a way to deal with master crafted mods (currently that's a tough one, probably won't be possible)
;   - show max possible for guesstimated ranges
;   - de-globalize the script (almost done)
;   - refactor ParseAffixes into ParseAffixesSimple and ParseAffixesComplex (low priority)
;
; Slinkston edit for Todo for 2.0 additions for hazydoc or someone else knowledgable in coding:
;    - FYI: All of the stuff I have edited has been marked with ; Slinkston edit.  Some may need to be cleaned up or redone if
;      they are done improperly/sloppy.  I have tested all changes with stuff in my stash and with friends, but not every single possibility.
;    - Accuracy is a nightmare.  Anyhow, "of the Assassin - 321 to 360 Accuracy (80) (Bow and Wand)" needs
;      to be addressed for 2.0 or not /shrug.  I have passed on the request to GGG to perhaps mark up their affixes so they are decipherable.
;    - Divination card info would be great such as a) what you can possibly get for the collection, b) where that card drops, and c) what supporter
;      created it (if known).
;    - Jewel support for min/max rolls and what is a suffix and what is a prefix so you know what you may be able to exalt.  9/15/2015 - I just noticed that
;      GGG added jewel affixes, both prefix and suffix, for jewels to their item database.
;    - Legacy item alert on the item would be useful for those players that take breaks and come back without reading all the patch notes and/or
;      not recognizing some item may have changed or not.  This alert can be placed along the bottom with 'quality, valuable, mirrored, etc.'
;      I imagine that this would not be hard to do, but would require a lot of small detail work.  Because all uniques are nerfed/buffed in
;      specific ways, there is no 'quick' and easy way to do this.  There would have to be a specific check for each specific unique item looking
;      at the particular change(s) and compare it to the existing known unique setup vs the legacy setup.  I would be willing to do all the small
;      detail work required for each unique if someone would write the code required for this to work and how this would work with the current uniques.txt
;      list.  This is obviously less valuable of an addition to the PoE-Item-Info script than general upgrades/div cards/jewel support.
;
; Notes:
;
;   - Global values marked with an inline comment "d" are globals for debugging so they can be easily
;     (re-)enabled using global search and replace. Marking variables as global means they will show
;     up in AHK's Variables and contents view of the script.
;
; Needs AutoHotKey v1.1.05 or later
;   from http://ahkscript.org and NOT http://www.autohotkey.com
;   the latter domain was apparently taken over by a for-profit company!
;
; Original credits:
;
;   mcpower - for the base iLVL display of the script 5months ago before Immo.
;   Immo - for the base iLVL display of the script.(Which was taken from mcpower.)
;   olop4444 - for helping me figure out the calculations for Q20 items.
;   Aeons - for a rewrite and fancy tooltips.
;   kongyuyu - for base item level display.
;   Fayted - for testing the script.
;
; Original author's comment:
;
; If you have any questions or comments please post them there as well. If you think you can help
; improve this project. I am looking for contributors. So Pm me if you think you can help.
;
; If you have a issue please post what version you are using.
; Reason being is that something that might be a issue might already be fixed.
;

; Run test suites (see end of script)
; Note: don't set this to true for normal every day use...
; This is just for fellow developers.
RunTests := False

#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.

;Define exe names for the regular and steam version, for later use at the very end of the script. This needs to be done early, in the "auto-execute section".
GroupAdd, PoEexe, ahk_exe PathOfExile.exe
GroupAdd, PoEexe, ahk_exe PathOfExileSteam.exe

#Include %A_ScriptDir%\data\Version.txt

MsgWrongAHKVersion := "AutoHotkey v" . AHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion <= AHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % MsgWrongAHKVersion
    ExitApp
}

#Include %A_ScriptDir%\data\Messages.txt

; Instead of polluting the default namespace with Globals, create our own Globals "namespace".
class Globals {

    Set(name, value) {
        Globals[name] := value
    }

    Get(name, value_default="") {
        result := Globals[name]
        If (result == "") {
            result := value_default
        }
        return result
    }
}
Globals.Set("AHKVersionRequired", AHKVersionRequired)
Globals.Set("ReleaseVersion", ReleaseVersion)
Globals.Set("DataDir", A_ScriptDir . "\data")
Globals.Set("SettingsUIWidth", 545)
Globals.Set("SettingsUIHeight", 710)
Globals.Set("SettingsUITitle", "PoE Item Info Settings")

global SuspendPOEItemScript = 0

class UserOptions {

    OnlyActiveIfPOEIsFront := 1     ; Set to 1 to make it so the script does nothing if Path of Exile window isn't the frontmost.
                                    ; If 0, the script also works if PoE isn't frontmost. This is handy for have the script parse
                                    ; textual item representations appearing somewhere else, like in the forums or text files.

    PutResultsOnClipboard := 0      ; Put result text on clipboard (overwriting the textual representation the game put there to begin with)

    ShowItemLevel := 1              ; Show item level and the item type's base level (enabled by default change to 0 to disable)
    ShowMaxSockets := 1             ; Show the max sockets based on ilvl and type
    ShowDamageCalculations := 1     ; Show damage projections (for weapons only)

    ShowAffixTotals := 1            ; Show total affix statistics
    ShowAffixDetails := 1           ; Show detailed info about affixes
    ShowAffixLevel := 0             ; Show item level of the affix
    ShowAffixBracket := 1           ; Show range for the affix' bracket as is on the item
    ShowAffixMaxPossible := 1       ; Show max possible bracket for an affix based on the item's item level
    ShowAffixBracketTier := 1       ; Show a T# indicator of the tier the affix bracket is in.
                                    ; T1 being the highest possible, T2 second-to-highest and so on

    ShowAffixBracketTierTotal := 1  ; Appends the total number of tiers for a given affix in parentheses T/#Total
                                    ; T4/8 would represent the fourth highest tier, in eight total tiers.

    ShowDarkShrineInfo := 0          ; Appends info about DarkShrine effects of affixes to rares

    TierRelativeToItemLevel := 0    ; When determining the affix bracket tier, take item level into consideration.
                                    ; However, this also means that the lower the item level the less the diversity
                                    ; of possible affix tiers since there aren't as many possibilities. This will
                                    ; give the illusion that a low level item might be really, really good when it
                                    ; has all T1 but in reality it can only have T1 since it's item level is so low
                                    ; it can only ever take the first bracket.
                                    ;
                                    ; If this option is set to 0, the tiers will always display relative to the full
                                    ; range of tiers available, ignoring the item level.

    ShowCurrencyValueInChaos := 0   ; Convert the value of currency items into chaos orbs.
                                    ; This is based on the rates defined in <datadir>\CurrencyRates.txt
                                    ; You should edit this file with the current currency rates.

    MaxSpanStartingFromFirst := 1   ; When showing max possible, don't just show the highest possible affix bracket
                                    ; but construct a pseudo range which spans the lower bound of the lowest possible
                                    ; bracket to the upper bound of the highest possible one.
                                    ;
                                    ; This is usually what you want to see when evaluating an item's worth. The exception
                                    ; being when you want to reroll an affix to the highest possible value within it's
                                    ; current bracket - then you need to see the affix range that is actually on the item
                                    ; right now.

    CompactDoubleRanges := 1        ; Show double ranges as "1-172" instead of "1-8 to 160-172"
    CompactAffixTypes := 1          ; Use compact affix type designations: Suffix = S, Prefix = P, Comp. Suffix = CS, Comp. Prefix = CP

    MirrorAffixLines := 1           ; Show a copy of the affix line in question when showing affix details.
                                    ;
                                    ; For example, would display "Prefix, 5-250" instead of "+246 to Accuracy Rating, Prefix, 5-250".
                                    ; Since the affixes are processed in order one can attribute which is which to the ordering of
                                    ; the lines in the tooltip to the item data in game.

    MirrorLineFieldWidth := 18      ; Mirrored affix line width. Set to a number above 0 to truncate (or pad) to this many characters.
                                    ; Appends AffixDetailEllipsis when truncating.
    ValueRangeFieldWidth := 7       ; Width of field that displays the affix' value range(s). Set to a number larger than 0 to truncate (or pad) to this many characters.
                                    ;
                                    ; Keep in mind that there are sometimes double ranges to be displayed. Like for example on an axe, implicit physical damage might
                                    ; have a lower bound range and a upper bound range. In this case the lower bound range can have at most a 3 digit minimum value,
                                    ; and at most a 3 digit maximum value. To then display just the lower bound (which constitutes one value range field), you would need
                                    ; at least 7 characters (ex: 132-179). To complete the example here is how it would look like with 2 fields (lower and upper bound)
                                    ; 132-179 168-189. Note that you don't need to set 15 as option value to display both fields correctly. As the name implies the option
                                    ; is per field, so a value of 8 can display two 8 character wide fields correctly.

    AffixDetailDelimiter := " "     ; Field delimiter for affix detail lines. This is put between value range fields. If this value were set to a comma, the above
                                    ; double range example would become 132-179,168-189.

    AffixDetailEllipsis := "…"      ; If the MirrorLineFieldWidth is set to a value that is smaller than the actual length of the affix line text
                                    ; the affix line will be cut off and this text will be appended at the end to indicate tha the line was truncated.
                                    ;
                                    ; Usually this is set to the ASCII or Unicode value of the three dot ellipsis (alt code: 0133).
                                    ; Note that the correct display of text characters outside the ASCII standard depend on the file encoding and the
                                    ; AHK version used. For best results, save this file as ANSI encoding which can be read and displayed correctly by
                                    ; either ANSI based AutoHotkey or Unicode based AutoHotkey.
                                    ;
                                    ; Example: assume the affix line to be mirrored is '+#% increased Spell Damage'.
                                    ; If the MirrorLineFieldWidth is set to 18, this field would be shown as '+#% increased Spel…'


    ; Pixels mouse must move to auto-dismiss tooltip
    MouseMoveThreshold := 40

    ; Set this to 1 if you want to have the tooltip disappear after the time frame set below.
    ; Otherwise you will have to move the mouse by 5 pixels for the tip to disappear.
    UseTooltipTimeout := 0

    ;How many ticks to wait before removing tooltip. 1 tick = 100ms. Example, 50 ticks = 5secends, 75 Ticks = 7.5Secends
    ToolTipTimeoutTicks := 150

    ; Font size for the tooltip, leave empty for default
    FontSize := 11

    ; Displays the tooltip in virtual screen space at fixed coordinates.
    ; Virtual screen space means the complete desktop frame, including any secondary monitors.
    DisplayToolTipAtFixedCoords := 0

    ; Coordinates relative to top left corner, increasing by going down and to the right.
    ; Only used if DisplayToolTipAtFixedCoords is 1.
    ScreenOffsetX := 0
    ScreenOffsetY := 0

    ScanUI()
    {
        this.OnlyActiveIfPOEIsFront := GuiGet("OnlyActiveIfPOEIsFront")
        this.PutResultsOnClipboard := GuiGet("PutResultsOnClipboard")
        this.ShowItemLevel := GuiGet("ShowItemLevel")
        this.ShowMaxSockets := GuiGet("ShowMaxSockets")
        this.ShowDamageCalculations := GuiGet("ShowDamageCalculations")
        this.ShowAffixTotals := GuiGet("ShowAffixTotals")
        this.ShowAffixDetails := GuiGet("ShowAffixDetails")
        this.ShowAffixLevel := GuiGet("ShowAffixLevel")
        this.ShowAffixBracket := GuiGet("ShowAffixBracket")
        this.ShowAffixMaxPossible := GuiGet("ShowAffixMaxPossible")
        this.ShowAffixBracketTier := GuiGet("ShowAffixBracketTier")
        this.ShowAffixBracketTierTotal := GuiGet("ShowAffixBracketTierTotal")
        this.TierRelativeToItemLevel := GuiGet("TierRelativeToItemLevel")
        this.ShowDarkShrineInfo := GuiGet("ShowDarkShrineInfo")
        this.ShowCurrencyValueInChaos := GuiGet("ShowCurrencyValueInChaos")
        this.DisplayToolTipAtFixedCoords := GuiGet("DisplayToolTipAtFixedCoords")
        this.ScreenOffsetX := GuiGet("ScreenOffsetX")
        this.ScreenOffsetY := GuiGet("ScreenOffsetY")
        this.MaxSpanStartingFromFirst := GuiGet("MaxSpanStartingFromFirst")
        this.CompactDoubleRanges := GuiGet("CompactDoubleRanges")
        this.CompactAffixTypes := GuiGet("CompactAffixTypes")
        this.MirrorAffixLines := GuiGet("MirrorAffixLines")
        this.MirrorLineFieldWidth := GuiGet("MirrorLineFieldWidth")
        this.ValueRangeFieldWidth := GuiGet("ValueRangeFieldWidth")
        this.AffixDetailDelimiter := GuiGet("AffixDetailDelimiter")
        this.AffixDetailEllipsis := GuiGet("AffixDetailEllipsis")
        this.MouseMoveThreshold := GuiGet("MouseMoveThreshold")
        this.UseTooltipTimeout := GuiGet("UseTooltipTimeout")
        this.ToolTipTimeoutTicks := GuiGet("ToolTipTimeoutTicks")
        this.FontSize := GuiGet("FontSize")
    }
}
Opts := new UserOptions()

class Fonts {

    Init(FontSizeFixed, FontSizeUI)
    {
        this.FontSizeFixed := FontSizeFixed
        this.FontSizeUI := FontSizeUI
        this.FixedFont := this.CreateFixedFont(FontSizeFixed)
        this.UIFont := this.CreateUIFont(FontSizeUI)
    }

    CreateFixedFont(FontSize_)
    {
        Options :=
        If (!(FontSize_ == ""))
        {
            Options = s%FontSize_%
        }
        Gui Font, %Options%, Courier New
        Gui Font, %Options%, Consolas
        Gui Add, Text, HwndHidden,
        SendMessage, 0x31,,,, ahk_id %Hidden%
        return ErrorLevel
    }

    CreateUIFont(FontSize_)
    {
        Options :=
        If (!(FontSize_ == ""))
        {
            Options = s%FontSize_%
        }
        Gui Font, %Options%, Tahoma
        Gui Font, %Options%, Segoe UI
        Gui Add, Text, HwndHidden,
        SendMessage, 0x31,,,, ahk_id %Hidden%
        return ErrorLevel
    }

    Set(NewFont)
    {
        AhkExe := GetAhkExeFilename()
        SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe %AhkExe%
        ; Development versions of AHK
        SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyA32.exe
        SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyU32.exe
        SendMessage, 0x30, NewFont, 1,, ahk_class tooltips_class32 ahk_exe AutoHotkeyU64.exe
    }

    SetFixedFont(FontSize_=-1)
    {
        If (FontSize_ == -1)
        {
            FontSize_ := this.FontSizeFixed
        }
        Else
        {
            this.FontSizeFixed := FontSize_
            this.FixedFont := this.CreateFixedFont(FontSize_)
        }
        this.Set(this.FixedFont)
    }

    SetUIFont(FontSize_=-1)
    {
        If (FontSize_ == -1)
        {
            FontSize_ := this.FontSizeUI
        }
        Else
        {
            this.FontSizeUI := FontSize_
            this.UIFont := this.CreateUIFont(FontSize_)
        }
        this.Set(this.UIFont)
    }

    GetFixedFont()
    {
        return this.FixedFont
    }

    GetUIFont()
    {
        return this.UIFont
    }
}

class ItemData_ {

    Links := ""
    Sockets := ""
    Stats := ""
    NamePlate := ""
    Affixes := ""
    FullText := ""
    IndexAffixes := -1
    IndexLast := -1
    PartsLast := ""
    Rarity := ""
    Parts := []

    ClearParts()
    {
        Loop, % this.Parts.MaxIndex()
        {
            this.Parts.Remove(this.Parts.MaxIndex())
        }
    }
}
ItemData := new ItemData_()

class Item {
    Name := ""
    TypeName := ""
    Quality := ""
    BaseLevel := ""
    RarityLevel := ""
    BaseType := ""
    SubType := ""
    GripType := ""
    Level := ""
    MapLevel := ""
    MaxSockets := ""
    IsUnidentified := ""
    IsCorrupted := ""
    IsGem := ""
    IsCurrency := ""
    IsUnique := ""
    IsRare := ""
    IsBow := ""
    IsFlask := ""
    IsBelt := ""
    IsRing := ""
    IsUnsetRing := ""
    IsAmulet := ""
    IsTalisman := ""
    IsJewel := ""
    IsDivinationCard := ""
    IsSingleSocket := ""
    IsFourSocket := ""
    IsThreeSocket := ""
    IsQuiver := ""
    IsWeapon := ""
    IsMap := ""
    IsMirrored := ""
    HasEffect := ""
}
Item := new Item()

class AffixTotals_ {

    NumPrefixes := 0
    NumSuffixes := 0
    NumTotals := 0

    Reset()
    {
        this.NumPrefixes := 0
        this.NumSuffixes := 0
        this.NumTotals := 0
    }
}
AffixTotals := new AffixTotals_()

class AffixLines_ {

    __New()
    {
        this.Length := 0
    }

    ; Sets fields to empty string
    Clear(Index)
    {
        this[Index] := ""
    }

    ClearAll()
    {
        Loop, % this.MaxIndex()
        {
            this.Clear(A_Index)
        }
    }

    ; Actually removes fields
    Reset()
    {
        Loop, % this.MaxIndex()
        {
            this.Remove(this.MaxIndex())
        }
        this.Length := 0
    }

    Set(Index, Contents)
    {
        this[Index] := Contents
        this.Length := this.MaxIndex()
    }
}
AffixLines := new AffixLines_()

IfNotExist, %A_ScriptDir%\config.ini
{
    IfNotExist, %A_ScriptDir%\data\defaults.ini
    {
        CreateDefaultConfig()
    }
    CopyDefaultConfig()
}

; Windows system tray icon
; possible values: poe.ico, poe-bw.ico, poe-web.ico, info.ico
; set before creating the settings UI so it gets used for the settigns dialog as well
Menu, Tray, Icon, %A_ScriptDir%\data\poe-bw.ico

ReadConfig()
Sleep, 100
CreateSettingsUI()

Menu, TextFiles, Add, Additional Macros, EditAdditionalMacros
Menu, TextFiles, Add, Currency Rates, EditCurrencyRates


; Menu tooltip
RelVer := Globals.Get("ReleaseVersion")
Menu, Tray, Tip, Path of Exile Item Info %RelVer%

Menu, Tray, NoStandard
Menu, Tray, Add, About..., MenuTray_About
Menu, Tray, Add, % Globals.Get("SettingsUITitle", "PoE Item Info Settings"), ShowSettingsUI
Menu, Tray, Add ; Separator
Menu, Tray, Add, Edit, :TextFiles
Menu, Tray, Add ; Separator
Menu, Tray, Standard
Menu, Tray, Default, % Globals.Get("SettingsUITitle", "PoE Item Info Settings")


IfNotExist, %A_ScriptDir%\data
{
    MsgBox, 16, % Msg.DataDirNotFound
    exit
}

#Include %A_ScriptDir%\data\MapList.txt
#Include %A_ScriptDir%\data\DivinationCardList.txt
#Include %A_ScriptDir%\data\GemQualityList.txt


Fonts.Init(Opts.FontSize, 9)

GetAhkExeFilename(Default_="AutoHotkey.exe")
{
    AhkExeFilename := Default_
    If (A_AhkPath)
    {
        StringSplit, AhkPathParts, A_AhkPath, \
        Loop, % AhkPathParts0
        {
            IfInString, AhkPathParts%A_Index%, .exe
            {
                AhkExeFilename := AhkPathParts%A_Index%
                Break
            }
        }
    }
    return AhkExeFilename
}

OpenCreateDataTextFile(Filename)
{
    Filepath := A_ScriptDir . "\data\" . Filename
    IfExist, % Filepath
    {
        Run, % Filepath
    }
    Else
    {
        File := FileOpen(Filepath, "w")
        if !IsObject(File)
        {
            MsgBox, 16, Error, File not found and can't write new file.
            return
        }
        File.Close()
        Run, % Filepath
    }
    return

}

OpenMainDirFile(Filename)
{
    Filepath := A_ScriptDir . "\" . Filename
    IfExist, % Filepath
    {
        Run, % Filepath
    }
    Else
    {
        MsgBox, 16, Error, File not found.
        return
    }
    return

}

ParseAddedDamage(String, DmgType, ByRef DmgLo, ByRef DmgHi)
{
    If(RegExMatch(String, "Adds (\d+) to (\d+) " DmgType " Damage", Match))
    {
        ;StringSplit, Arr, Match, %A_Space%
        ;StringSplit, Arr, Arr2, -
        DmgLo := Match1
        DmgHi := Match2
    }
}

; Function that checks item type name against entries
; from ItemList.txt to get the item's base level
; Added by kongyuyu, changed by hazydoc, vdorie
CheckBaseLevel(ItemTypeName)
{
    ItemListArray = 0
    Loop, Read, %A_ScriptDir%\data\ItemList.txt
    {
        ; This loop retrieves each line from the file, one at a time.
        ItemListArray += 1  ; Keep track of how many items are in the array.
        StringSplit, NameLevel, A_LoopReadLine, |,
        Array%ItemListArray%1 := NameLevel1  ; Store this line in the next array element.
        Array%ItemListArray%2 := NameLevel2
    }

    ResultLength := 0
    ResultIndex := 0

    Loop %ItemListArray% {
        element := Array%A_Index%1

        if (InStr(ItemTypeName, element) != 0 && StrLen(element) > ResultLength)
        {
            ResultIndex := A_Index
            ResultLength := StrLen(element)
        }
    }

    BaseLevel := ""
    if (ResultIndex > 0) {
        BaseLevel := Array%ResultIndex%2
    }
    return BaseLevel
}

CheckRarityLevel(RarityString)
{
    IfInString, RarityString, Normal
        return 1
    IfInString, RarityString, Magic
        return 2
    IfInString, RarityString, Rare
        return 3
    IfInString, RarityString, Unique
        return 4
    return 0 ; unknown rarity. shouldn't happen!
}

ParseItemType(ItemDataStats, ItemDataNamePlate, ByRef BaseType, ByRef SubType, ByRef GripType, IsMapFragment, RarityLevel)
{
    ; Grip type only matters for weapons at this point. For all others it will be 'None'.
    GripType = None

    ; Check stats section first as weapons usually have their sub type as first line
    Loop, Parse, ItemDataStats, `n, `r
    {
        IfInString, A_LoopField, One Handed Axe
        {
            BaseType = Weapon
            SubType = Axe
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Two Handed Axe
        {
            BaseType = Weapon
            SubType = Axe
            GripType = 2H
            return
        }
        IfInString, A_LoopField, One Handed Mace
        {
            BaseType = Weapon
            SubType = Mace
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Two Handed Mace
        {
            BaseType = Weapon
            SubType = Mace
            GripType = 2H
            return
        }
        IfInString, A_LoopField, Sceptre
        {
            BaseType = Weapon
            SubType = Sceptre
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Staff
        {
            BaseType = Weapon
            SubType = Staff
            GripType = 2H
            return
        }
        IfInString, A_LoopField, One Handed Sword
        {
            BaseType = Weapon
            SubType = Sword
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Two Handed Sword
        {
            BaseType = Weapon
            SubType = Sword
            GripType = 2H
            return
        }
        IfInString, A_LoopField, Dagger
        {
            BaseType = Weapon
            SubType = Dagger
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Claw
        {
            BaseType = Weapon
            SubType = Claw
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Bow
        {
            ; Not really sure if I should classify bow as 2H (because that would make sense)
            ; but you can equip a quiver in 2nd hand slot, so it could be 1H?
            BaseType = Weapon
            SubType = Bow
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Wand
        {
            BaseType = Weapon
            SubType = Wand
            GripType = 1H
            return
        }
    }

    ; Check name plate section
    Loop, Parse, ItemDataNamePlate, `n, `r
    {
        ; Get third line in case of unique item and retrieve the base item name
        LoopField := RegExReplace(A_LoopField, "<<.*>>", "")
        If (RarityLevel = 4)
        {
            Loop, Parse, ItemDataNamePlate, `n, `r
            {
                If (A_Index = 3) {
                   LoopField := Trim(A_LoopField) ? Trim(A_LoopField) : LoopField
                }
            }
        }

        ; Belts, Amulets, Rings, Quivers, Flasks
        IfInString, LoopField, Rustic Sash
        {
            BaseType = Item
            SubType = Belt
            return
        }
        IfInString, LoopField, Belt
        {
            BaseType = Item
            SubType = Belt
            return
        }
        If (InStr(LoopField, "Amulet") or InStr(LoopField, "Talisman"))
        {
            BaseType = Item
            SubType = Amulet
            return
        }

        If(RegExMatch(LoopField, "\bRing\b"))
        {
            BaseType = Item
            SubType = Ring
            return
        }
        IfInString, LoopField, Quiver
        {
            BaseType = Item
            SubType = Quiver
            return
        }
        IfInString, LoopField, Flask
        {
            BaseType = Item
            SubType = Flask
            return
        }
        IfInString, LoopField, %A_Space%Map
        {
            Global matchList
            BaseType = Map
            Loop % matchList.MaxIndex()
            {
                Match := matchList[A_Index]
                IfInString, LoopField, %Match%
                {
                    SubType = %Match%
                    return
                }
            }

            SubType = Unknown%A_Space%Map
            return
        }
        ; Dry Peninsula fix
        IfInString, LoopField, Dry%A_Space%Peninsula
        {
            BaseType = Map
            SubType = Dry%A_Space%Peninsula
            return
        }

        ; Jewels
        IfInString, LoopField, Cobalt%A_Space%Jewel
        {
            BaseType = Jewel
            SubType = Cobalt Jewel
            return
        }
        IfInString, LoopField, Crimson%A_Space%Jewel
        {
            BaseType = Jewel
            SubType = Crimson Jewel
            return
        }
        IfInString, LoopField, Viridian%A_Space%Jewel
        {
            BaseType = Jewel
            SubType = Viridian Jewel
            return
        }
        IfInString, LoopField, Prismatic%A_Space%Jewel
        {
            BaseType = Jewel
            SubType = Prismatic Jewel
            return
        }


        ; Matching armour types with regular expressions to reduce
        ;    potential mismatches due to the huge base item name variety and
        ;    the word lists used for the randomly assigned (first line) item name.

        ; "$" means line end, "|" is the usual "or" operator.
        ; Using "$" perfectly matches all normal and rare items but completely fails on magic items.
        ; I don't see a reason why "$" should be used.
        ; There should be 2 solutions here:
        ;   1. Don't use "$".
        ;   2. Use Trim(RegExReplace(A_LoopField, "i) of .*", "")) to remove the suffix from magic items first.

        ; Shields
        If (RegExMatch(LoopField, "Buckler|Bundle|Shield"))
        {
            BaseType = Armour
            SubType = Shield
            return
        }

        ; Gloves
        If (RegExMatch(LoopField, "Gauntlets|Gloves|Mitts"))
        {
            BaseType = Armour
            SubType = Gloves
            return
        }

        ; Boots
        If (RegExMatch(LoopField, "Boots|Greaves|Slippers"))
        {
            BaseType = Armour
            SubType = Boots
            return
        }

        ; Helmets
        If (RegExMatch(LoopField, "Bascinet|Burgonet|Cage|Circlet|Crown|Hood|Helm|Helmet|Mask|Sallet|Tricorne"))
        {
            BaseType = Armour
            SubType = Helmet
            return
        }

        ; Note: Body armours can have "Pelt" in their randomly assigned name,
        ;    explicitly matching the three pelt base items to be safe.

        If (RegExMatch(LoopField, "Iron Hat|Leather Cap|Rusted Coif|Wolf Pelt|Ursine Pelt|Lion Pelt"))
        {
            BaseType = Armour
            SubType = Helmet
            return
        }

        ; BodyArmour
        ; Note: Not using "$" could match "Leather Belt", therefore we first check that the item is not a belt.
        If (!RegExMatch(LoopField, "Belt"))
        {
            If (RegExMatch(LoopField, "Armour|Brigandine|Chainmail|Coat|Doublet|Garb|Hauberk|Jacket|Lamellar|Leather|Plate|Raiment|Regalia|Ringmail|Robe|Tunic|Vest|Vestment"))
            {
                BaseType = Armour
                SubType = BodyArmour
                return
            }
        }


        If (RegExMatch(LoopField, "Chestplate|Full Dragonscale|Full Wyrmscale|Necromancer Silks|Shabby Jerkin|Silken Wrap"))
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
    }

    If (IsMapFragment) {
        SubType = MapFragment
        return
    }
}

GetClipboardContents(DropNewlines=False)
{
    Result =
    Note =
    If Not DropNewlines
    {
        Loop, Parse, Clipboard, `n, `r
        {   
            IfInString, A_LoopField, note:  ; new code added by Bahnzo - The ability to add prices to items causes issues. Building the code sent from the clipboard
            {                               ; differently, and ommiting the line with "Note:" on it partially fixes this. We also have to omit the \newline \return
                Note := A_LoopField         ; that gets added at the end
                break                       ; Not adding the note to ClipboardContents but its own variable should solve all problems
            }
			IfInString, A_LoopField, Map drop
			{
				break
			}
            If A_Index = 1                  ; so we start with just adding the first line w/o either a `n or `r 
            {
                Result := Result . A_LoopField
            }
            else
            {
                Result := Result . "`r`n" . A_LoopField  ; and then adding those before adding lines. This makes sure there are no trailing `n or `r. 
                ;Result := Result . A_LoopField . "`r`n"  ; the original line, left in for clarity. 
            }
        }
    }
    Else
    {   
        Loop, Parse, Clipboard, `n, `r
        {
            IfInString, A_LoopField, note:
            {
                Note := A_LoopField
                break
            }
            Result := Result . A_LoopField
        }
    }
        
    RegExMatch(Trim(Note), "i)^Note: (.*)", match)
    Globals.Set("ItemNote", match1)
    
    return Result
}

SetClipboardContents(String)
{
    Clipboard := String
}

; Splits StrInput on StrDelimiter. Returns an object that has a 'length' field
; containing the number of parts and 0 .. (length) fields containing the substrings.
; Example: if parts is the object returned by this function, then
;   'parts.length' gives the number of parts
;   'parts[1]' gives the first part (if there is one)
; Note: if StrDelimiter is not present in StrInput, length == 1 and parts[1] == StrInput
; Note2: as per AHK docs, parts.(Min|Max)Index() also work of course.
SplitString(StrInput, StrDelimiter)
{
    TempDelim := "``"
    Chunks := Object()
    StringReplace, TempResult, StrInput, %StrDelimiter%, %TempDelim%, All
    StringSplit, Parts, TempResult, %TempDelim%
    Chunks["length"] := Parts0
    Loop, %Parts0%
    {
        Chunks[A_Index] := Parts%A_Index%
    }
    return Chunks
}

; TODO: LookupAffixBracket and LookupAffixData contain a lot of duplicate code.

; Look up just the most applicable bracket for an affix.
; Most applicable means Value is between bounds of bracket range or
; highest entry possible given the item level.
;
; Returns "#-#" format range
;
; If Value is unspecified ("") return the max possible
; bracket based on item level
LookupAffixBracket(Filename, ItemLevel, Value="", ByRef BracketLevel="", ByRef BracketIndex=0)
{
    AffixLevel := 0
    AffixDataIndex := 0
    If (Not Value == "")
    {
        ValueLo := Value             ; Value from ingame tooltip
        ValueHi := Value             ; For single values (which most of them are) ValueLo == ValueHi
        ParseRange(Value, ValueHi, ValueLo)
    }
    LookupIsDoubleRange := False ; For affixes like "Adds +# ... Damage" which have a lower and an upper bound range
    BracketRange := "n/a"
    Loop, Read, %A_ScriptDir%\%Filename%
    {
        AffixDataIndex += 1
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeLevel := AffixDataParts1
        RangeValues := AffixDataParts2
        If (RangeLevel > ItemLevel)
        {
            AffixDataIndex -= 1 ; Since we added 1 above, before we noticed range level is above item level
            Break
        }
        IfInString, RangeValues, `,
        {
            LookupIsDoubleRange := True
        }
        If (LookupIsDoubleRange)
        {
            ; Example lines from txt file database for double range lookups:
            ;  3|1,14-15
            ; 13|1-3,35-37
            StringSplit, DoubleRangeParts, RangeValues, `,
            LB := DoubleRangeParts%DoubleRangeParts%1
            UB := DoubleRangeParts%DoubleRangeParts%2
            ; Default case: lower bound is single value: #
            ; see level 3 case in example lines above
            LBMin := LB
            LBMax := LB
            UBMin := UB
            UBMax := UB
            IfInString, LB, -
            {
                ; Lower bound is a range: #-#q
                ParseRange(LB, LBMax, LBMin)
            }
            IfInString, UB, -
            {
                ParseRange(UB, UBMax, UBMin)
            }
            LBPart = %LBMin%
            UBPart = %UBMax%
            ; Record bracket range if it is within bounds of the text file entry
            If (Value == "" or (((ValueLo >= LBMin) and (ValueLo <= LBMax)) and ((ValueHi >= UBMin) and (ValueHi <= UBMax))))
            {
                BracketRange = %LBPart%-%UBPart%
                AffixLevel = %RangeLevel%
            }
        }
        Else
        {
            ParseRange(RangeValues, HiVal, LoVal)
            ; Record bracket range if it is within bounds of the text file entry
            If (Value == "" or ((ValueLo >= LoVal) and (ValueHi <= HiVal)))
            {
                BracketRange = %LoVal%-%HiVal%
                AffixLevel = %RangeLevel%
            }
        }
        If (Value == "")
        {
            AffixLevel = %RangeLevel%
        }
    }
    BracketIndex := AffixDataIndex
    BracketLevel := AffixLevel
    return BracketRange
}

; Look up complete data for an affix. Depending on settings flags
; this may include many things, and will return a string used for
; end user display rather than further calculations.
; Use LookupAffixBracket if you need a range format to do calculations with.
LookupAffixData(Filename, ItemLevel, Value, ByRef BracketLevel="", ByRef Tier=0)
{
    Global Opts

    AffixLevel := 0
    AffixDataIndex := 0
    ValueLo := Value             ; Value from ingame tooltip
    ValueHi := Value             ; For single values (which most of them are) ValueLo == ValueHi
    ValueIsMinMax := False       ; Treat Value as min/max units (#-#) or as single unit (#)
    LookupIsDoubleRange := False ; For affixes like "Adds +# ... Damage" which have a lower and an upper bound range
    FirstRangeValues =
    BracketRange := "n/a"
    MaxRange =
    FinalRange =
    MaxLevel := 1
    RangeLevel := 1
    Tier := 0
    MaxTier := 0
    IfInString, Value, -
    {
        ParseRange(Value, ValueHi, ValueLo)
        ValueIsMinMax := True
    }
    ; TODO refactor pre-pass into its own method
    ; Pre-pass to determine max tier
    Loop, Read, %A_ScriptDir%\%Filename%
    {
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeLevel := AffixDataParts1
        If (Globals.Get("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel) and (RangeLevel > ItemLevel))
        {
            Break
        }
        ; Yes, this is correct incrementing MaxTier here and not before the break!
        MaxTier += 1
    }

    Loop, Read, %A_ScriptDir%\%Filename%
    {
        AffixDataIndex += 1
        StringSplit, AffixDataParts, A_LoopReadLine, |,
        RangeValues := AffixDataParts2
        RangeLevel := AffixDataParts1
        If (AffixDataIndex == 1)
        {
            FirstRangeValues := RangeValues
        }
        If (Globals.Get("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel) and (RangeLevel > ItemLevel))
        {
            Break
        }
        MaxLevel := RangeLevel
        IfInString, RangeValues, `,
        {
            LookupIsDoubleRange := True
        }
        If (LookupIsDoubleRange)
        {
            ; Variables for min/max double ranges, like in the "Adds +# ... Damage" case
            ;       Global LBMin     ; (L)ower (B)ound minium value
            ;       Global LBMax     ; (L)ower (B)ound maximum value
            ;       GLobal UBMin     ; (U)pper (B)ound minimum value
            ;       GLobal UBMax     ; (U)pper (B)ound maximum value
            ;       ; same, just for the first range's values
            ;       Global FRLBMin
            ;       Global FRLBMax
            ;       Global FRUBMin
            ;       Global FRUBMax
            ; Example lines from txt file database for double range lookups:
            ;  3|1,14-15
            ; 13|1-3,35-37
            StringSplit, DoubleRangeParts, RangeValues, `,
            LB := DoubleRangeParts%DoubleRangeParts%1
            UB := DoubleRangeParts%DoubleRangeParts%2
            ; Default case: lower bound is single value: #
            ; see level 3 case in example lines above
            LBMin := LB
            LBMax := LB
            UBMin := UB
            UBMax := UB
            IfInString, LB, -
            {
                ; Lower bound is a range: #-#
                ParseRange(LB, LBMax, LBMin)
            }
            IfInString, UB, -
            {
                ParseRange(UB, UBMax, UBMin)
            }
            If (AffixDataIndex == 1)
            {
                StringSplit, FirstDoubleRangeParts, FirstRangeValues, `,
                FRLB := FirstDoubleRangeParts%FirstDoubleRangeParts%1
                FRUB := FirstDoubleRangeParts%FirstDoubleRangeParts%2
                ParseRange(FRUB, FRUBMax, FRUBMin)
                ParseRange(FRLB, FRLBMax, FRLBMin)
            }
            If ((LBMin == LBMax) or Opts.CompactDoubleRanges)
            {
                LBPart = %LBMin%
            }
            Else
            {
                LBPart = %LBMin%-%LBMax%
            }
            If ((UBMin == UBMax) or Opts.CompactDoubleRanges)
            {
                UBPart = %UBMax%
            }
            Else
            {
                UBPart = %UBMin%-%UBMax%
            }
            If ((FRLBMin == FRLBMax) or Opts.CompactDoubleRanges)
            {
                FRLBPart = %FRLBMin%
            }
            Else
            {
                FRLBPart = %FRLBMin%-%FRLBMax%
            }
            If (Opts.CompactDoubleRanges)
            {
                MiddlePart := "-"
            }
            Else
            {
                MiddlePart := " to "
            }
            ; Record bracket range if it is withing bounds of the text file entry
            If (((ValueLo >= LBMin) and (ValueLo <= LBMax)) and ((ValueHi >= UBMin) and (ValueHi <= UBMax)))
            {
                BracketRange = %LBPart%%MiddlePart%%UBPart%
                AffixLevel = %MaxLevel%
                Tier := ((MaxTier - AffixDataIndex) + 1)
                If (Opts.ShowAffixBracketTierTotal)
                {
                    Tier := Tier . "/" . MaxTier
                }
            }
            ; Record max possible range regardless of within bounds
            If (Opts.MaxSpanStartingFromFirst)
            {
                MaxRange = %FRLBPart%%MiddlePart%%UBPart%
            }
            Else
            {
                MaxRange = %LBPart%%MiddlePart%%UBPart%
            }
        }
        Else
        {
            If (AffixDataIndex = 1)
            {
                ParseRange(FirstRangeValues, FRHiVal, FRLoVal)
            }
            ParseRange(RangeValues, HiVal, LoVal)
            ; Record bracket range if it is within bounds of the text file entry
            If ((ValueLo >= LoVal) and (ValueHi <= HiVal))
            {
                If (LoVal = HiVal)
                {
                    BracketRange = %LoVal%
                }
                Else
                {
                    BracketRange = %LoVal%-%HiVal%
                }
                AffixLevel = %MaxLevel%
                Tier := ((MaxTier - AffixDataIndex) + 1)

                If (Opts.ShowAffixBracketTierTotal)
                {
                    Tier := Tier . "/" . MaxTier
                }
            }
            ; Record max possible range regardless of within bounds
            If (Opts.MaxSpanStartingFromFirst)
            {
                MaxRange = %FRLoVal%-%HiVal%
            }
            Else
            {
                MaxRange = %LoVal%-%HiVal%
            }
        }
    }
    BracketLevel := AffixLevel
    FinalRange := AssembleValueRangeFields(BracketRange, BracketLevel, MaxRange, MaxLevel)
    return FinalRange
}

AssembleValueRangeFields(BracketRange, BracketLevel, MaxRange="", MaxLevel=0)
{
    Global Opts

    If (Opts.ShowAffixBracket)
    {
        FinalRange := BracketRange
        If (Opts.ValueRangeFieldWidth > 0)
        {
            FinalRange := StrPad(FinalRange, Opts.ValueRangeFieldWidth, "left")
        }
        If (Opts.ShowAffixLevel)
        {
            FinalRange := FinalRange . " " . StrPad("(" . BracketLevel . ")", 4, Side="left")
        }
        Else
        {
            FinalRange := FinalRange . Opts.AffixDetailDelimiter
        }
    }
    If (MaxRange and Opts.ShowAffixMaxPossible)
    {
        If (Opts.ValueRangeFieldWidth > 0)
        {
            MaxRange := StrPad(MaxRange, Opts.ValueRangeFieldWidth, "left")
        }
        FinalRange := FinalRange . MaxRange
        If (Opts.ShowAffixLevel)
        {
            FinalRange := FinalRange . " " . StrPad("(" . MaxLevel . ")", 4, Side="left")
        }
    }
    return FinalRange
}

ParseRarity(ItemData_NamePlate)
{
    Loop, Parse, ItemData_NamePlate, `n, `r
    {
        IfInString, A_LoopField, Rarity:
        {
            StringReplace, RarityReplace, A_LoopField, :%A_Space%, :, All
            StringSplit, RarityParts, RarityReplace, :
            Break
        }
    }
    return RarityParts%RarityParts%2
}

Assert(expr, msg)
{
    If (Not (expr))
    {
        MsgBox, 4112, Assertion Failure, %msg%
        ExitApp
    }
}

GetItemDataChunk(ItemDataText, MatchWord)
{
    Assert(StrLen(MatchWord) > 0, "GetItemDataChunk: parameter 'MatchWord' can't be empty")

    StringReplace, TempResult, ItemDataText, --------`r`n, ``, All
    StringSplit, ItemDataChunks, TempResult, ``
    Loop, %ItemDataChunks0%
    {
        IfInString, ItemDataChunks%A_Index%, %MatchWord%
        {
            return ItemDataChunks%A_Index%
        }
    }
}

ParseQuality(ItemDataNamePlate)
{
    ItemQuality := 0
    Loop, Parse, ItemDataNamePlate, `n, `r
    {
        If (StrLen(A_LoopField) = 0)
        {
            Break
        }
        IfInString, A_LoopField, Unidentified
        {
            Break
        }
        IfInString, A_LoopField, Quality:
        {
            ItemQuality := RegExReplace(A_LoopField, "Quality: \+(\d+)% .*", "$1")
            Break
        }
    }
    return ItemQuality
}

ParseAugmentations(ItemDataChunk, ByRef AffixCSVList)
{
    CurAugment := ItemDataChunk
    Loop, Parse, ItemDataChunk, `n, `r
    {
        CurAugment := A_LoopField
        Globals.Set("CurAugment", A_LoopField)
        IfInString, A_LoopField, Requirements:
        {
            ; too far - Requirements: is already the next chunk
            Break
        }
        IfInString, A_LoopField, (augmented)
        {
            StringSplit, LineParts, A_LoopField, :
            AffixCSVList := AffixCSVList . "'"  . LineParts%LineParts%1 . "'"
            AffixCSVList := AffixCSVList . ", "
        }
    }
    AffixCSVList := SubStr(AffixCSVList, 1, -2)
}

ParseRequirements(ItemDataChunk, ByRef Level, ByRef Attributes, ByRef Values="")
{
    IfNotInString, ItemDataChunk, Requirements
    {
        return
    }
    Attr =
    AttrValues =
    Delim := ","
    DelimLen := StrLen(Delim)
    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, A_LoopField, Str
        {
            Attr := Attr . "Str" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, Dex
        {
            Attr := Attr . "Dex" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, Int
        {
            Attr := Attr . "Int" . Delim
            AttrValues := AttrValues . GetColonValue(A_LoopField) . Delim
        }
        IfInString, A_LoopField, Level
        {
            Level := GetColonValue(A_LoopField)
        }
    }
    ; Chop off last Delim
    If (SubStr(Attr, -(DelimLen-1)) == Delim)
    {
        Attr := SubStr(Attr, 1, -(DelimLen))
    }
    If (SubStr(AttrValues, -(DelimLen-1)) == Delim)
    {
        AttrValues := SubStr(AttrValues, 1, -(DelimLen))
    }
    Attributes := Attr
    Values := AttrValues
}

; Parses #low-#high and sets Hi to #high and Lo to #low
; if RangeChunk is just a single value (#) it will set both
; Hi and Lo to this single value (effectively making the range 1-1 if # was 1)
ParseRange(RangeChunk, ByRef Hi, ByRef Lo)
{
    IfInString, RangeChunk, -
    {
        StringSplit, RangeParts, RangeChunk, -
        Lo := RegExReplace(RangeParts1, "(\d+?)", "$1")
        Hi := RegExReplace(RangeParts2, "(\d+?)", "$1")
    }
    Else
    {
        Hi := RangeChunk
        Lo := RangeChunk
    }
}

ParseItemLevel(ItemDataText)
{
    ; XXX
    ; Add support for The Awakening Closed Beta
    ; Once TA is released we won't need to support both occurences of
    ; the word "Item level" any more...
    ItemDataChunk := GetItemDataChunk(ItemDataText, "Itemlevel:")
    If (StrLen(ItemDataChunk) <= 0)
    {
        ItemDataChunk := GetItemDataChunk(ItemDataText, "Item Level:")
    }

    Assert(StrLen(ItemDataChunk) > 0, "ParseItemLevel: couldn't parse item data chunk")

    Loop, Parse, ItemDataChunk, `n, `r
    {
        IfInString, A_LoopField, Itemlevel:
        {
            StringSplit, ItemLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(ItemLevelParts2)
            return Result
        }
        IfInString, A_LoopField, Item Level:
        {
            StringSplit, ItemLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(ItemLevelParts3)
            return Result
        }
    }
}

;;hixxie fixed. Shows MapLevel for any map base.
ParseMapLevel(ItemDataText)
{
    ItemDataChunk := GetItemDataChunk(ItemDataText, "MapTier:")
    If (StrLen(ItemDataChunk) <= 0)
    {
        ItemDataChunk := GetItemDataChunk(ItemDataText, "Map Tier:")
    }

    Assert(StrLen(ItemDataChunk) > 0, "ParseMapLevel: couldn't parse item data chunk")

    Loop, Parse, ItemDataChunk, `n, `r
    {
        IfInString, A_LoopField, MapTier:
        {
            StringSplit, MapLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(MapLevelParts2)
            return Result
        }
        IfInString, A_LoopField, Map Tier:
        {
            StringSplit, MapLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(MapLevelParts3) + 67
            return Result
        }
    }
}



ParseGemLevel(ItemDataText, PartialString="Level:")
{
    ItemDataChunk := GetItemDataChunk(ItemDataText, PartialString)
    Loop, Parse, ItemDataChunk, `n, `r
    {
        IfInString, A_LoopField, %PartialString%
        {
            StringSplit, ItemLevelParts, A_LoopField, %A_Space%
            Result := StrTrimWhitespace(ItemLevelParts2)
            return Result
        }
    }
}

StrMult(Char, Times)
{
    Result =
    Loop, %Times%
    {
        Result := Result . Char
    }
    return Result
}

StrTrimSpaceLeft(String)
{
    return RegExReplace(String, " *(.+?)", "$1")
}

StrTrimSpaceRight(String)
{
    return RegExReplace(String, "(.+?) *$", "$1")
}

StrTrimSpace(String)
{
    return RegExReplace(String, " *(.+?) *", "$1")
}

StrTrimWhitespace(String)
{
    return RegExReplace(String, "[ \r\n\t]*(.+?)[ \r\n\t]*", "$1")
}

; Pads a string with a multiple of PadChar to become a wanted total length.
; Note that Side is the side that is padded not the anchored side.
; Meaning, if you pad right side, the text will move left. If Side was an
; anchor instead, the text would move right if anchored right.
StrPad(String, Length, Side="right", PadChar=" ")
{
    StringLen, Len, String
    AddLen := Length-Len
    If (AddLen <= 0)
    {
        return String
    }
    Pad := StrMult(PadChar, AddLen)
    If (Side == "right")
    {
        Result := String . Pad
    }
    Else
    {
        Result := Pad . String
    }
    return Result
}

; Prefix a string s with another string prefix.
; Does nothing if s is already prefixed.
StrPrefix(s, prefix) {
    If (s == "") {
        return ""
    } Else {
        If (SubStr(s, 1, StrLen(prefix)) == prefix) {
            return s ; Nothing to do
        } Else {
            return prefix . s
        }
    }
}

BoolToString(flag) {
    If (flag == True) {
        return "True"
    } Else {
        return "False"
    }
    return "False"
}

; Formats a number with SetFormat (leaving A_FormatFloat unchanged)
; Returns formatted Num as string.
NumFormat(Num, Format)
{
    oldFormat := A_FormatFloat
    newNum := Num
    SetFormat, FloatFast, %Format%
    newNum += 0.0 ; convert to float, which applies SetFormat
    newNum := newNum . "" ; convert to string so the next SetFormat doesn't apply
    SetFormat, FloatFast, %oldFormat%
    return newNum
}

; Pads a number with prefixed 0s and optionally rounds or appends to specified decimal places width.
NumPad(Num, TotalWidth, DecimalPlaces=0)
{
    myFormat = 0%TotalWidth%.%DecimalPlaces%
    newNum := NumFormat(Num, myFormat)
    return newNum
}

; Estimate indicator, marks end user display values as guesstimated so they can take a look at it.
MarkAsGuesstimate(ValueRange, Side="left", Indicator=" * ")
{
    Global Globals, Opts
    Globals.Set("MarkedAsGuess", True)
    return StrPad(ValueRange . Indicator, Opts.ValueRangeFieldWidth + StrLen(Indicator), Side)
}

MakeAffixDetailLine(AffixLine, AffixType, ValueRange, Tier)
{
    Global ItemData
    Delim := "|" ; Internal delimiter, used as string split char later - do not change to the user adjustable delimiter
    Line := AffixLine . Delim . ValueRange . Delim . AffixType
    If (ItemData.Rarity == "Rare" or ItemData.Rarity == "Magic")
    {
        Line := Line . Delim . Tier
    }
    return Line
}

AppendAffixInfo(Line, AffixPos)
{
    Global AffixLines
    AffixLines.Set(AffixPos, Line)
}

AssembleAffixDetails()
{
    Global Opts, AffixLines

    AffixLine =
    AffixType =
    ValueRange =
    AffixTier =
    NumAffixLines := AffixLines.MaxIndex()
    AffixLineParts := 0
    Loop, %NumAffixLines%
    {
        CurLine := AffixLines[A_Index]
        ProcessedLine =
        Loop, %AffixLineParts0%
        {
            AffixLineParts%A_Index% =
        }
        StringSplit, AffixLineParts, CurLine, |
        AffixLine := AffixLineParts1
        ValueRange := AffixLineParts2
        AffixType := AffixLineParts3
        AffixTier := AffixLineParts4

        Delim := Opts.AffixDetailDelimiter
        Ellipsis := Opts.AffixDetailEllipsis

        If (Opts.ValueRangeFieldWidth > 0)
        {
            ValueRange := StrPad(ValueRange, Opts.ValueRangeFieldWidth, "left")
        }
        If (Opts.MirrorAffixLines == 1)
        {
            If (Opts.MirrorLineFieldWidth > 0)
            {
                If ( Not Item.IsUnique )
                {
                    If(StrLen(AffixLine) > Opts.MirrorLineFieldWidth)
                    {
                        AffixLine := StrTrimSpaceRight(SubStr(AffixLine, 1, Opts.MirrorLineFieldWidth)) . Ellipsis
                    }
                    AffixLine := StrPad(AffixLine, Opts.MirrorLineFieldWidth + StrLen(Ellipsis))
                }
                Else
                {
                    If(StrLen(AffixLine) > Opts.MirrorLineFieldWidth + 10)
                    {
                        AffixLine := StrTrimSpaceRight(SubStr(AffixLine, 1, Opts.MirrorLineFieldWidth + 10)) . Ellipsis
                    }
                    AffixLine := StrPad(AffixLine, Opts.MirrorLineFieldWidth + 10 + StrLen(Ellipsis))
                }
            }
            ProcessedLine := AffixLine . Delim
        }
        IfInString, ValueRange, *
        {
            ValueRangeString := StrPad(ValueRange, (Opts.ValueRangeFieldWidth * 2) + (StrLen(Opts.AffixDetailDelimiter)))
        }
        Else
        {
            ValueRangeString := ValueRange
        }
        ProcessedLine := ProcessedLine . ValueRangeString . Delim
        If (Opts.ShowAffixBracketTier == 1 and Not (ItemDataRarity == "Unique") and Not StrLen(AffixTier) = 0)
        {
            If (InStr(ValueRange, "*") and Opts.ShowAffixBracketTier)
            {
                TierString := "   "
                AdditionalPadding := ""
                If (Opts.ShowAffixLevel or Opts.ShowAffixBracketTotalTier)
                {
                    TierString := ""
                }
                If (Opts.ShowAffixLevel)
                {
                    AdditionalPadding := AdditionalPadding . StrMult(" ", Opts.ValueRangeFieldWidth)
                }
                If (Opts.ShowAffixBracketTierTotal)
                {
                    AdditionalPadding := AdditionalPadding . StrMult(" ", Opts.ValueRangeFieldWidth)

                }
                TierString := TierString . AdditionalPadding
            }
            Else
            {
                AddedWidth := 0
                If (Opts.ShowAffixBracketTierTotal)
                {
                    AddedWidth += 2

                }
                TierString := StrPad("T" . AffixTier, 3+AddedWidth, "left")
            }
            ProcessedLine := ProcessedLine . TierString . Delim
        }
        ProcessedLine := ProcessedLine . AffixType . Delim
        Result := Result . "`n" . ProcessedLine
    }
    return Result
}

AssembleDarkShrineInfo()
{
    Global Item, ItemData

    AffixString := ItemData.Affixes
    Found := 0

    affixloop:
    Loop, Parse, AffixString, `n, `r
    {
        AffixLine := A_LoopField

        If (AffixLine == "" or AffixLine == "Unidentified" ) {
            ; ignore empty affixes and unidentified items
            continue affixloop
        }

        Found := Found + 1

        DsAffix := ""
        If (RegExMatch(AffixLine,"[0-9.]+% "))
        {
            DsAffix := RegExReplace(AffixLine,"[0-9.]+% ","#% ")
        } Else If (RegExMatch(AffixLine,"^\+[0-9.]+ ")) {
            DsAffix := RegExReplace(AffixLine,"^\+[0-9.]+ ","+# ")
        } Else If (RegExMatch(AffixLine,"^\-[0-9.]+ ")) {
            ; Needed for Elreon's mod on jewelry
            DsAffix := RegExReplace(AffixLine,"^\-[0-9.]+ ","-# ")
        } Else If (RegExMatch(AffixLine,"^[0-9.]+ ")) {
            DsAffix := RegExReplace(AffixLine,"^[0-9.]+ ","# ")
        } Else If (RegExMatch(AffixLine," [0-9]+-[0-9]+ ")) {
            DsAffix := RegExReplace(AffixLine," [0-9]+-[0-9]+ "," #-# ")
        } Else If (RegExMatch(AffixLine,"gain [0-9]+ (Power|Frenzy|Endurance) Charge")) {
            ; Fixes recognition of affixes like "Monsters gain # Endurance Charges every 20 seconds"
            DsAffix := RegExReplace(AffixLine,"gain [0-9]+ ","gain # ")
        } Else If (RegExMatch(AffixLine,"fire [0-9]+ additional Projectiles")) {
            ; Fixes recognition of "Monsters fire # additional Projectiles" affix
            DsAffix := RegExReplace(AffixLine,"[0-9]+","#")
        } Else If (RegExMatch(AffixLine,"^Reflects [0-9]+")) {
            ; Fixes recognition of "Reflects # Physical Damage to Melee Attackers" affix
            DsAffix := RegExReplace(AffixLine,"[0-9]+","#")
        }Else {
            DsAffix := AffixLine
        }

        Result := Result . "`n " . DsAffix . ":"

        ; DarkShrineEffects.txt
        ; File with known effects based on POE wiki and http://poe.rivsoft.net/shrines/shrines.js  by https://www.reddit.com/user/d07RiV
        Loop, Read, %A_ScriptDir%\data\DarkShrineEffects.txt
        {
            ; This loop retrieves each line from the file, one at a time.
            StringSplit, DsEffect, A_LoopReadLine, |,
            if (DsAffix = DsEffect1) {
                If ((Item.IsRing or Item.IsAmulet or Item.IsBelt or Item.IsJewel) and (DsAffix = "+# to Evasion Rating" or DsAffix = "#% Increased Evasion Rating")) {
                    ; Evasion rating on jewelry and jewels has a different effect than Evasion rating on other rares
                    Result := Result . "`n  - Always watch your back (jewelry only)`n  -- Three rare monsters spawn around the darkshrine"
                } Else If ((Item.IsJewel) and (DsAffix = "#% increased Critical Strike Chance for Spells")) {
                    ; Crit chance for spells on jewels has a different effect than on other rares
                    Result := Result . "`n  - Keeper of the wand (jewel only)`n  -- A rare monster in the area will drop five rare wands"
                } Else If ((Item.IsJewel) and (DsAffix = "#% increased Accuracy Rating")) {
                    ; Accuracy on jewels has a different effect than on other rares
                    Result := Result . "`n  - Shroud your path in the fog of war (jewel only)`n  -- Grants permanent Shrouded shrine"
                } Else If ((Item.IsRing or Item.IsAmulet or Item.IsBelt) and InStr(DsAffix,"Adds #-# Chaos Damage")) {
                    ; Flat added chaos damage on jewelry (elreon mod) has a different effect than on weapons (according to wiki)
                    Result := Result . "`n  - Feel the corruption in your veins (jewelry only)`n  -- Monsters poison on hit"
                } Else {
                    Result := Result . "`n  - " . DsEffect3 . "`n  -- " . DsEffect2
                }
                ; TODO: maybe use DsEffect 5 to display warning about complex affixes
                ; We found the affix so we can continue with the next affix
                continue affixloop
            }
        }

        Result := Result . "`n  - Unknown"

    }

    If (Found <= 2 and not Item.IsUnidentified) {
        Result := Result . "`n 2-affix rare:`n  - Try again`n  -- Consumes the item, Darkshrine may be used again"
    }

    If (ItemData.Links == 5) {
        Result := Result .  "`n 5-Linked:`n  - You win some and you lose some`n  -- Randomizes the numerical values of explicit mods on a random item"
    } Else If (ItemData.Links == 6) {
        Result := Result .  "`n 6-Linked:`n  - The ultimate gamble, but only for those who are prepared`n  -- All items on the ground are affected by an Orb of Chance"
    }


    If (Item.IsCorrupted) {
        Result := Result .  "`n Corrupted:`n  - The influence of vaal continues long after their civilization has crumbled`n  -- Opens portals to a corrupted area"
    }

    If (Item.Quality == 20) {
        Result := Result .  "`n 20% Quality:`n  - Wait, what was that sound?`n  -- Random item gets a skin transfer"
    }

    If (Item.IsMirrored) {
        Result := Result .  "`n Mirrored:`n  - The little things add up`n  -- Rerolls the implicit mod on a random item"
    }

    If (Item.IsUnidentified) {
        Result := Result .  "`n Unidentified:`n  - Same effect as if the item is identified first"
    }

    return Result

}

; Same as AdjustRangeForQuality, except that Value is just
; a single value and not a range.
AdjustValueForQuality(Value, ItemQuality, Direction="up")
{
    If (ItemQuality < 1)
        return Value
    Divisor := ItemQuality / 100
    If (Direction == "up")
    {
        Result := Round(Value + (Value * Divisor))
    }
    Else
    {
        Result := Round(Value - (Value * Divisor))
    }
    return Result
}

; Adjust an affix' range for +% Quality on an item.
; For example: given the range 10-20 and item quality +15%
; the result would be 11.5-23 which is currently rounded up
; to 12-23. Note that Direction does not play a part in rounding
; rather it controls if adjusting up towards quality increase or
; down from quality increase (to get the original value back)
AdjustRangeForQuality(ValueRange, ItemQuality, Direction="up")
{
    If (ItemQuality = 0)
    {
        return ValueRange
    }
    VRHi := 0
    VRLo := 0
    ParseRange(ValueRange, VRHi, VRLo)
    Divisor := ItemQuality / 100
    If (Direction == "up")
    {
        VRHi := Round(VRHi + (VRHi * Divisor))
        VRLo := Round(VRLo + (VRLo * Divisor))
    }
    Else
    {
        VRHi := Round(VRHi - (VRHi * Divisor))
        VRLo := Round(VRLo - (VRLo * Divisor))
    }
    If (VRLo == VRHi)
    {
        ValueRange = %VRLo%
    }
    Else
    {
        ValueRange = %VRLo%-%VRHi%
    }
    return ValueRange
}

; Checks ActualValue against ValueRange, returning 1 if
; ActualValue is within bounds of ValueRange, 0 otherwise.
WithinBounds(ValueRange, ActualValue)
{
    VHi := 0
    VLo := 0
    ParseRange(ValueRange, VHi, VLo)
    Result := 1
    IfInString, ActualValue, -
    {
        AVHi := 0
        AVLo := 0
        ParseRange(ActualValue, AVHi, AVLo)
        If ((AVLo < VLo) or (AVHi > VHi))
        {
            Result := 0
        }
    }
    Else
    {
        If ((ActualValue < VLo) or (ActualValue > VHi))
        {
            Result := 0
        }
    }
    return Result
}

GetAffixTypeFromProcessedLine(PartialAffixString)
{
    Global AffixLines
    NumAffixLines := AffixLines.MaxIndex()
    Loop, %NumAffixLines%
    {
        AffixLine := AffixLines[A_Index]
        IfInString, AffixLine, %PartialAffixString%
        {
            StringSplit, AffixLineParts, AffixLine, |
            return AffixLineParts3
        }
    }
}

; Get actual value from a line of the ingame tooltip as a number
; that can be used in calculations.
GetActualValue(ActualValueLine)
{
    Result := RegExReplace(ActualValueLine, ".*?\+?(\d+(?: to \d+|\.\d+)?).*", "$1")
    StringReplace, Result, Result, %A_SPACE%to%A_SPACE%, -
    return Result
}

; Get value from a colon line, e.g. given the line "Level: 57", returns the number 57
GetColonValue(Line)
{
    IfInString, Line, :
    {
        StringSplit, LineParts, Line, :
        Result := StrTrimSpace(LineParts%LineParts%2)
        return Result
    }
}

RangeMid(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    RSum := RHi+RLo
    If (RSum == 0)
    {
        return 0
    }
    return Floor((RHi+RLo)/2)
}

RangeMin(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    return RLo
}

RangeMax(Range)
{
    If (Range = 0 or Range = "0" or Range = "0-0")
    {
        return 0
    }
    RHi := 0
    RLo := 0
    ParseRange(Range, RHi, RLo)
    return RHi
}

AddRange(Range1, Range2)
{
    R1Hi := 0
    R1Lo := 0
    R2Hi := 0
    R2Lo := 0
    ParseRange(Range1, R1Hi, R1Lo)
    ParseRange(Range2, R2Hi, R2Lo)
    FinalHi := R1Hi + R2Hi
    FinalLo := R1Lo + R2Lo
    FinalRange = %FinalLo%-%FinalHi%
    return FinalRange
}

; Used to check return values from LookupAffixBracket()
IsValidBracket(Bracket)
{
    If (Bracket == "n/a")
    {
        return False
    }
    return True
}

; Used to check return values from LookupAffixData()
IsValidRange(Bracket)
{
    IfInString, Bracket, n/a
    {
        return False
    }
    return True
}

; Note that while ExtractCompAffixBalance() can be run on processed data
; that has compact affix type declarations (or not) for this function to
; work properly, make sure to run it on data that has compact affix types
; turned off. The reason being that it is hard to count prefixes by there
; being a "P" in a line that also has mirrored affix descriptions.
ExtractTotalAffixBalance(ProcessedData, ByRef Prefixes, ByRef Suffixes, ByRef CompPrefixes, ByRef CompSuffixes)
{
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, Comp. Prefix
        {
            CompPrefixes += 1
        }
        IfInString, AffixLine, Comp. Suffix
        {
            CompSuffixes += 1
        }
    }
    ProcessedData := RegExReplace(ProcessedData, "Comp\. Prefix", "")
    ProcessedData := RegExReplace(ProcessedData, "Comp\. Suffix", "")
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, Prefix
        {
            Prefixes += 1
        }
        IfInString, AffixLine, Suffix
        {
            Suffixes += 1
        }
    }
}

ExtractCompositeAffixBalance(ProcessedData, ByRef CompPrefixes, ByRef CompSuffixes)
{
    Loop, Parse, ProcessedData, `n, `r
    {
        AffixLine := A_LoopField
        IfInString, AffixLine, Comp. Prefix
        {
            CompPrefixes += 1
        }
        IfInString, AffixLine, Comp. Suffix
        {
            CompSuffixes += 1
        }
    }
}

ParseFlaskAffixes(ItemDataAffixes)
{
    Global AffixTotals

    IfInString, ItemDataChunk, Unidentified
    {
        return ; Not interested in unidentified items
    }

    NumPrefixes := 0
    NumSuffixes := 0

    Loop, Parse, ItemDataAffixes, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Continue ; Not interested in blank lines
        }

        ; Suffixes

        IfInString, A_LoopField, Dispels
        {
            ; Covers Shock, Burning and Frozen and Chilled
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Removes Bleeding
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Removes Curses on use
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, during flask effect
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Adds Knockback
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Life Recovery to Minions
        {
            If (NumSuffixes < 1)
            {
                NumSuffixes += 1
            }
            Continue
        }

        ; Prefixes

        IfInString, A_LoopField, Recovery Speed
        {
            If (NumPrefixes < 1)
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Amount Recovered
        {
            If (NumPrefixes < 1)
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Charges
        {
            If (NumPrefixes < 1)
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Instant
        {
            If (NumPrefixes < 1)
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Charge when
        {
            If (NumPrefixes < 1)
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Recovery when
        {
            If (NumPrefixes < 1)
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Mana Recovered
        {
            If (NumPrefixes < 1)
            {
                NumPrefixes += 1
            }
            Continue
        }
        IfInString, A_LoopField, Life Recovered
        {
            If (NumPrefixes < 1)
            {
                NumPrefixes += 1
            }
            Continue
        }
    }

    AffixTotals.NumPrefixes := NumPrefixes
    AffixTotals.NumSuffixes := NumSuffixes
}

; Try looking up the remainder bracket based on Bracket
; This is done by calculating the rest value in three
; different ways, falling through if not successful:
;
; 1) CurrValue - RangeMid(Bracket)
; 2) CurrValue - RangeMin(Bracket)
; 3) CurrValue - RangeMax(Bracket)
;
; (Internal: RegExr x-forms):
;
; with ByRef BracketLevel:
;   ( *)(.+Rest) := CurrValue - RangeMid\((.+)\)\r *(.+) := LookupAffixBracket\((.+?), (.+?), (.+?), (.+?)\)
;   -> $1$4 := LookupRemainingAffixBracket($5, $6, CurrValue, $3, $8)
;
; w/o ByRef BracketLevel:
;   ( *)(.+Rest) := CurrValue - RangeMid\((.+)\)\r *(.+) := LookupAffixBracket\((.+?), (.+?), (.+?)\)
;   -> $1$4 := LookupRemainingAffixBracket($5, $6, CurrValue, $3)
;
LookupRemainingAffixBracket(Filename, ItemLevel, CurrValue, Bracket, ByRef BracketLevel=0)
{
    RestValue := CurrValue - RangeMid(Bracket)
    RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketLevel)
    If (Not IsValidBracket(RemainderBracket))
    {
        RestValue := CurrValue - RangeMin(Bracket)
        RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketLevel)
    }
    If (Not IsValidBracket(RemainderBracket))
    {
        RestValue := CurrValue - RangeMax(Bracket)
        RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketLevel)
    }
    return RemainderBracket
}

ParseAffixes(ItemDataAffixes, Item)
{
    Global Globals, Opts, AffixTotals, AffixLines

    ItemDataChunk := ItemDataAffixes

    ItemBaseType := Item.BaseType
    ItemSubType := Item.SubType
    ItemGripType := Item.GripType
    ItemLevel := Item.Level
    ItemQuality := Item.Quality

     ; Reset the AffixLines "array" and other vars
    ResetAffixDetailVars()

    ; Keeps track of how many affix lines we have so they can be assembled later.
    ; Acts as a loop index variable when iterating each affix data part.
    NumPrefixes := 0
    NumSuffixes := 0

    ; Composition flags
    ;
    ; These are required for descision making later, when guesstimating
    ; sources for parts of a value from composite and/or same name affixes.
    ; They will be set to the line number where they occur in the pre-pass
    ; loop, so that details for that line can be changed later after we
    ; have more clues for possible compositions.
    HasIIQ := 0
    HasIncrArmour := 0
    HasIncrEvasion := 0
    HasIncrEnergyShield := 0
    HasHybridDefences := 0
    HasIncrArmourAndES := 0
    HasIncrArmourAndEvasion := 0
    HasIncrEvasionAndES := 0
    HasIncrLightRadius := 0
    HasIncrAccuracyRating := 0
    HasIncrPhysDmg := 0
    HasToAccuracyRating := 0
    HasStunRecovery := 0
    HasSpellDamage := 0
    HasMaxMana := 0
    HasMultipleCrafted := 0

    ; The following values are used for new style complex affix support
    CAIncAccuracy := 0
    CAIncAccuracyAffixLine := ""
    CAIncAccuracyAffixLineNo := 0
    CAGlobalCritChance := 0
    CAGlobalCritChanceAffixLine := ""
    CAGlobalCritChanceAffixLineNo := 0

    ; Max mana already accounted for in case of Composite Prefix+Prefix
    ; "Spell Damage / Max Mana" + "Max Mana"
    MaxManaPartial =

    ; Accuracy Rating already accounted for in case of
    ;   Composite Prefix + Composite Suffix:
    ;       "increased Physical Damage / to Accuracy Rating" +
    ;       "to Accuracy Rating / Light Radius"
    ;   Composite Prefix + Suffix:
    ;       "increased Physical Damage / to Accuracy Rating" +
    ;       "to Accuracy Rating"
    ARPartial =
    ARAffixTypePartial =

    ; Partial for the former "Block and Stun Recovery"
    ; With PoE v1.3+ called just "increased Stun Recovery"
    ; With PoE v2.3.2+ called "increased Stun and Block Recovery"
    BSRecPartial =

    ; --- PRE-PASS ---

    ; To determine composition flags
    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }

        IfInString, A_LoopField, increased Light Radius
        {
            HasIncrLightRadius := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Quantity
        {
            HasIIQ := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Physical Damage
        {
            HasIncrPhysDmg := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Accuracy Rating
        {
            HasIncrAccuracyRating := A_Index
            Continue
        }
        IfInString, A_LoopField, to Accuracy Rating
        {
            HasToAccuracyRating := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Armour and Evasion
        {
            HasHybridDefences := A_Index
            HasIncrArmourAndEvasion := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Armour and Energy Shield
        {
            HasHybridDefences := A_Index
            HasIncrArmourAndES := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Evasion and Energy Shield
        {
            HasHybridDefences := A_Index
            HasIncrEvasionAndES := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Armour
        {
            HasIncrArmour := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Evasion Rating
        {
            HasIncrEvasion := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Energy Shield
        {
            HasIncrEnergyShield := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Stun and Block Recovery
        {
            HasStunRecovery := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Spell Damage
        {
            HasSpellDamage := A_Index
            Continue
        }
        IfInString, A_LoopField, to maximum Mana
        {
            HasMaxMana := A_Index
            Continue
        }
        IfInString, A_Loopfield, Can have multiple Crafted Mods
        {
            HasMultipleCrafted := A_Index
            Continue
        }
    }

    ; Note: yes, these superlong IfInString structures suck, but hey,
    ; AHK sucks as an object-oriented scripting language, so bite me.
    ;
    ; But in all seriousness, there are two main parts - Simple and
    ; Complex Affixes - which could be refactored into their own helper
    ; methods.

    ; --- SIMPLE AFFIXES ---

    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }

        CurrValue := GetActualValue(A_LoopField)
        CurrTier := 0
        BracketLevel := 0

        ; --- SIMPLE JEWEL AFFIXES ---

        If (Item.IsJewel)
        {
            IfInString, A_LoopField, increased Area Damage
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\AreaDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Attack and Cast Speed
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\AttackAndCastSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*increased Attack Speed with (One|Two) Handed Melee Weapons")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\AttackSpeedWith1H2HMelee.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Attack Speed while holding a Shield
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\AttackSpeedWhileHoldingShield.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Attack Speed while Dual Wielding
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\AttackSpeedWhileDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*increased Attack Speed with (Axes|Bows|Claws|Daggers|Maces|Staves|Swords|Wands)")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\AttackSpeedWithWeapontype.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }

            ; pure Attack Speed must be checked last
            IfInString, A_LoopField, increased Attack Speed
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\AttackSpeed_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }

            IfInString, A_LoopField, increased Accuracy Rating
            {
                If(Item.SubType = "Cobalt Jewel" or Item.SubType = "Crimson Jewel")
                {
                    ; Cobalt and Crimson jewels can't get the combined increased accuracy/crit chance affix
                    NumSuffixes += 1
                    ValueRange := LookupAffixData("data\jewel\IncrAccuracyRating_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                    AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                    Continue
                }
                Else
                {
                    ; increased Accuracy Rating on Viridian and Prismatic jewels is a complex affix and handled later
                    CAIncAccuracy := CurrValue
                    CAIncAccuracyAffixLine := A_LoopField
                    CAIncAccuracyAffixLineNo := A_Index
                    Continue
                }
            }

            IfInString, A_LoopField, to all Attributes
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ToAllAttributes_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }

            If RegExMatch(A_LoopField, ".*to (Strength|Dexterity|Intelligence) and (Strength|Dexterity|Intelligence)")
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\To2Attributes_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*to (Strength|Dexterity|Intelligence)")
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\To1Attribute_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*increased Cast Speed (with|while) .*")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\CastSpeedWithWhile.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }

            ; pure Cast Speed must be checked last
            IfInString, A_LoopField, increased Cast Speed
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\CastSpeed_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Critical Strike Chance for Spells
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\CritChanceSpells_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Melee Critical Strike Chance
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\MeleeCritChance.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Critical Strike Chance with Elemental Skills
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\CritChanceElementalSkills.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*increased Critical Strike Chance with (Fire|Cold|Lightning) Skills")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\CritChanceFireColdLightningSkills.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*increased Critical Strike Chance with (One|Two) Handed Melee Weapons")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\CritChanceWith1H2HMelee.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Weapon Critical Strike Chance while Dual Wielding
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\WeaponCritChanceDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }

            ; Pure Critical Strike Chance must be checked last
            IfInString, A_LoopField, Critical Strike Chance
            {
                If (Item.SubType = "Cobalt Jewel" or Item.SubType = "Crimson Jewel" )
                {
                    ; Cobalt and Crimson jewels can't get the combined increased accuracy/crit chance affix
                    NumSuffixes += 1
                    ValueRange := LookupAffixData("data\jewel\CritChanceGlobal_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                    AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                    Continue
                }
                Else
                {
                    ; Crit chance on Viridian and Prismatic Jewels is a complex affix that is handled later
                    CAGlobalCritChance := CurrValue
                    CAGlobalCritChanceAffixLine := A_LoopField
                    CAGlobalCritChanceAffixLineNo := A_Index
                    Continue
                }
            }

            IfInString, A_LoopField, to Melee Critical Strike Multiplier
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\CritMeleeMultiplier.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, to Critical Strike Multiplier for Spells
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\CritMultiplierSpells.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, to Critical Strike Multiplier with Elemental Skills
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\CritMultiplierElementalSkills.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*to Critical Strike Multiplier with (Fire|Cold|Lightning) Skills")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\CritMultiplierFireColdLightningSkills.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*to Critical Strike Multiplier with (One|Two) Handed Melee Weapons")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\CritMultiplierWith1H2HMelee.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, to Critical Strike Multiplier while Dual Wielding
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\CritMultiplierWhileDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, Critical Strike Multiplier
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\CritMultiplierGlobal_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, chance to Ignite
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ChanceToIgnite.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Ignite Duration on Enemies
            {
                ; Don't increase number of suffixes, combined with "chance to Ignite" this is just 1 suffix
                ValueRange := LookupAffixData("data\jewel\IgniteDurationOnEnemies.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, chance to Freeze
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ChanceToFreeze.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Freeze Duration on Enemies
            {
                ; Don't increase number of suffixes, combined with "chance to Freeze" this is just 1 suffix
                ValueRange := LookupAffixData("data\jewel\FreezeDurationOnEnemies.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, chance to Shock
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ChanceToShock.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Shock Duration on Enemies
            {
                ; Don't increase number of suffixes, combined with "chance to Shock" this is just 1 suffix
                ValueRange := LookupAffixData("data\jewel\ShockDurationOnEnemies.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*increased (Fire|Cold|Lightning) Damage")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrFireColdLightningDamage_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, "Minions have .* Chance to Block")
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\MinionBlockChance.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*(Chance to Block|Block Chance).*")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\BlockChance_ChanceToBlock_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            ; This needs to come before plain "increased Damage"
            IfInString, A_LoopField, increased Damage over Time
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\DamageOverTime.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, "Minions deal .* increased Damage")
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\MinionsDealIncrDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Damage
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, chance to Knock Enemies Back on hit
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\KnockBackOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, Life gained for each Enemy hit by your Attacks
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\LifeOnHit_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, Energy Shield gained for each Enemy hit by your Attacks
            {
                ValueRange := LookupAffixData("data\jewel\ESOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
                NumSuffixes += 1
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, Mana gained for each Enemy hit by your Attacks
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ManaOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, reduced Mana Cost of Skills
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ReducedManaCost.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }

            IfInString, A_LoopField, increased Mana Regeneration Rate
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\ManaRegen_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Melee Damage
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\MeleeDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Projectile Damage
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ProjectileDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Projectile Speed
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ProjectileSpeed_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }

            IfInString, A_LoopField, to all Elemental Resistances
            {
                NumSuffixes += 1
                ; "to all Elemental Resistances" matches multiple affixes
                If InStr(A_LoopField, "Minions have")
                {
                    ValueRange := LookupAffixData("data\jewel\ToAllResist_Jewels_Minions.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else If InStr(A_LoopField, "Totems gain")
                {
                    ValueRange := LookupAffixData("data\jewel\ToAllResist_Jewels_Totems.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    ValueRange := LookupAffixData("data\jewel\ToAllResist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*to (Fire|Cold|Lightning) and (Fire|Cold|Lightning) Resistances")
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\To2Resist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*to (Fire|Cold|Lightning) Resistance")
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\To1Resist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, to Chaos Resistance
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\ToChaosResist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Stun Duration on Enemies
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\StunDuration_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*increased Physical Damage with (Axes|Bows|Claws|Daggers|Maces|Staves|Swords|Wands)")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrPhysDamageWithWeapontype.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Melee Physical Damage while holding a Shield
            {
                ; Only valid for Jewels at this time
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrMeleePhysDamageWhileHoldingShield.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Physical Weapon Damage while Dual Wielding
            {
                ; Only valid for Jewels at this time
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrPhysWeaponDamageDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If RegExMatch(A_LoopField, ".*increased Physical Damage with (One|Two) Handed Melee Weapons")
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrPhysDamageWith1H2HMelee.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Physical Damage
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrPhysDamage_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Totem Damage
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrTotemDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Totem Life
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrTotemLife.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Trap Throwing Speed
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrTrapThrowingSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Trap Damage
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrTrapDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Mine Laying Speed
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrMineLayingSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Mine Damage
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrMineDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Chaos Damage
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrChaosDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            If ( InStr(A_LoopField,"increased maximum Life"))
            {
                If InStr(A_LoopField,"Minions have") {
                    ValueRange := LookupAffixData("data\jewel\MinionIncrMaximumLife.txt", ItemLevel, CurrValue, "", CurrTier)
                } Else {
                    ValueRange := LookupAffixData("data\jewel\IncrMaximumLife.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                NumPrefixes += 1
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Armour
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrArmour_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }

            IfInString, A_LoopField, increased Evasion Rating
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrEvasion_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Energy Shield Recharge Rate
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\EnergyShieldRechargeRate.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, faster start of Energy Shield Recharge
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\FasterStartOfEnergyShieldRecharge.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased maximum Energy Shield
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrMaxEnergyShield_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, Physical Attack Damage Leeched as
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\PhysicalAttackDamageLeeched_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Spell Damage while Dual Wielding
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\SpellDamageDualWielding_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Spell Damage while holding a Shield
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\SpellDamageHoldingShield_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Spell Damage while wielding a Staff
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\SpellDamageWieldingStaff_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Spell Damage
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\SpellDamage_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased maximum Mana
            {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\jewel\IncrMaximumMana_Jewel.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Stun and Block Recovery
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\StunRecovery_Suffix_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, increased Rarity
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\IIR_Suffix_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
        }




        ; Suffixes

        IfInString, A_LoopField, increased Attack Speed
        {
            ; Slinkston edit. Cleaned up the code. I think this is a better approach.
            NumSuffixes += 1
            If (ItemSubType == "Wand" or ItemSubType == "Bow")
            {
                ValueRange := LookupAffixData("data\AttackSpeed_BowsAndWands.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (ItemBaseType == "Weapon")
            {
                ValueRange := LookupAffixData("data\AttackSpeed_Weapons.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else
            {
                ValueRange := LookupAffixData("data\AttackSpeed_ArmourAndItems.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, increased Accuracy Rating
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrAccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, to all Attributes
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToAllAttributes.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        If RegExMatch(A_LoopField, ".*to (Strength|Dexterity|Intelligence)")
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\To1Attribute.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, increased Cast Speed
        {
            ; Slinkston edit
            If (ItemGripType == "1H") {
                ; wands and scepters
                ValueRange := LookupAffixData("data\CastSpeed_1H.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (ItemGripType == "2H") {
                ; staves
                ValueRange := LookupAffixData("data\CastSpeed_2H.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.IsAmulet) {
                ValueRange := LookupAffixData("data\CastSpeedAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.IsRing) {
                ValueRange := LookupAffixData("data\CastSpeedRings.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ; Shields can receive a cast speed master mod.
                ; Leaving this as non shield specific if the master mod ever applicable on something else
                ValueRange := LookupAffixData("data\CastSpeedCraft.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, increased Critical Strike Chance for Spells
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\CritChanceSpells.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        ; Pure Critical Strike Chance must be checked last
        IfInString, A_LoopField, Critical Strike Chance
        {
            If (ItemBaseType == "Weapon")
            {
                ValueRange := LookupAffixData("data\CritChanceLocal.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\CritChanceGlobal.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, Critical Strike Multiplier
        {
            ; Slinkston edit
            If (ItemBaseType == "Weapon")
            {
                ValueRange := LookupAffixData("data\CritMultiplierLocal.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\CritMultiplierGlobal.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            NumSuffixes += 1
            Continue
        }

        IfInString, A_LoopField, increased Fire Damage
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrFireDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Cold Damage
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrColdDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Lightning Damage
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrLightningDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Light Radius
        {
            ValueRange := LookupAffixData("data\LightRadius_AccuracyRating.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Chance to Block
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\BlockChance.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Damage
        {
            ; Can be either Leo prefix or jewel suffix.
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrDamageLeo.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Flask affixes (on belts)
        IfInString, A_LoopField, reduced Flask Charges used
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskChargesUsed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Flask Charges gained
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskChargesGained.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Flask effect duration
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskDuration.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, increased Quantity
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IIQ.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Life gained on Kill
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\LifeOnKill.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Life gained for each Enemy hit ; Cuts off the rest to accommodate both "by Attacks" and "by your Attacks"
        {
            ; Slinkston edit. This isn't necessary at this point in time, but if either were to gain an additional ilvl affix down the road this would already be in place
            If (ItemBaseType == "Weapon") {
                ValueRange := LookupAffixData("data\LifeOnHitLocal.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else {
                ValueRange := LookupAffixData("data\LifeOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Life Regenerated per second
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\LifeRegen.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Mana Gained on Kill
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ManaOnKill.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Mana Regeneration Rate
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ManaRegen.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Projectile Speed
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ProjectileSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, reduced Attribute Requirements
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ReducedAttrReqs.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to all Elemental Resistances
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToAllResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Fire Resistance
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToFireResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Cold Resistance
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToColdResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Lightning Resistance
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToLightningResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Chaos Resistance
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToChaosResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Stun Duration on Enemies
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\StunDuration.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, reduced Enemy Stun Threshold
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\StunThreshold.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }

        ; Prefixes

        IfInString, A_LoopField, to Armour
        {
            ; Slinkston edit. AR, EV, and ES items are all correct for Armour, Shields, Helmets, Boots, Gloves, and different jewelry.
            ; to Armour has Belt, but does not have Ring or Amulet.
            If (ItemSubType == "Belt")
            {
                ValueRange := LookupAffixData("data\ToArmourBelt.txt", ItemLevel, CurrValue, "", CurrTier)
            }
        Else If (ItemSubtype == "Helmet")
        {
            ValueRange := LookupAffixData("data\ToArmourHelmet.txt", ItemLevel, CurrValue, "", CurrTier)
        }
            Else If (ItemSubtype == "Gloves" or ItemSubType == "Boots")
            {
                ValueRange := LookupAffixData("data\ToArmourGlovesandBoots.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\ToArmourArmourandShield.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        IfInString, A_LoopField, increased Armour and Evasion
        {
            AffixType := "Prefix"
            AEBracketLevel := 0
            ValueRange := LookupAffixData("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketLevel, CurrTier)
            If (HasStunRecovery)
            {
                AEBracketLevel2 := AEBracketLevel

                AEBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AEBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(AEBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AEBracketLevel2, CurrTier)
                }
                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", AEBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(AEBracket))
                {
                    ; This means that we are actually dealing with a Prefix + Comp. Prefix.
                    ; To get the part for the hybrid defence that is contributed by the straight prefix,
                    ; lookup the bracket level for the B&S Recovery line and then work out the partials
                    ; for the hybrid stat from the bracket level of B&S Recovery.
                    ;
                    ; For example:
                    ;   87% increased Armour and Evasion
                    ;   7% increased Stun and Block Recovery
                    ;
                    ;   1) 7% B&S indicates bracket level 2 (6-7)
                    ;   2) Lookup bracket level 2 from the hybrid stat + block and stun recovery table
                    ;      This works out to be 6-14.
                    ;   3) Subtract 6-14 from 87 to get the rest contributed by the hybrid stat as pure prefix.
                    ;
                    ; Currently when subtracting a range from a single value we just use the range's
                    ; max as single value. This may need changing depending on circumstance but it
                    ; works for now. EDIT: no longer the case, now uses RangeMid(...). EDIT2: Rest value calc
                    ; now routed through LookupRemainingAffixBracket() which uses trickle-down through all
                    ; three Range... functions. #'s below NOT YET changed to reflect that...
                    ;   87-10 = 77
                    ;   4) lookup affix data for increased Armour and Evasion with value of 77
                    ;
                    ; We now know, this is a Comp. Prefix+Prefix
                    ;
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        ; This means that the hybrid stat is a Comp. Prefix (Hybrid)+Prefix and SR is a Comp. Prefix (Hybrid)+Suffix.
                        ;
                        ; For example the following case:
                        ;   Item Level: 58
                        ;   107% increased Armour and Evasion (AE)
                        ;   ...
                        ;   30% increased Stun and Block Recovery (SR)
                        ;
                        ; Based on item level, 33-41 is the max contribution for AE of HybridDefences_StunRecovery (Comp. Prefix),
                        ; 12-13 is the max contribution for Stun Rec of StunRecovery_Hybrid (Comp. Prefix), 23-25 is the max contribution
                        ; for SR of StunRecovery_Suffix (Suffix)
                        ;
                        ; Obviously this is ambiguous and tough to resolve, but we'll try anyway...
                        ;
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    AEBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(AEBSBracket, CurrValue))
                    {
                        AEBracket := LookupRemainingAffixBracket("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBSBracket)

                        If (Not IsValidBracket(AEBracket))
                        {
                            AEBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (IsValidBracket(AEBracket) and WithinBounds(AEBracket, CurrValue))
                        {
                            If (NumPrefixes < 2)
                            {
                                ValueRange := AddRange(AEBSBracket, AEBracket)
                                ValueRange := MarkAsGuesstimate(ValueRange)
                                AffixType := "Comp. Prefix+Prefix"
                                NumPrefixes += 1
                            }
                            Else
                            {
                                ValueRange := LookupAffixData("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketLevel2, CurrTier)
                                AffixType := "Prefix"
                            }
                        }
                        Else
                        {
                            ; Check if it isn't a simple case of Armour and Evasion (Prefix) + Stun Recovery (Suffix)
                            BSRecBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRecValue, BSRecBracketLevel, CurrTier)
                            If (IsValidRange(ValueRange) and IsValidBracket(BSRecBracket))
                            {
                                ; -2 means for later that processing this hybrid defence stat
                                ; determined that Stun Recovery should be a simple suffix
                                BSRecPartial := ""
                                AffixType := "Prefix"
                                ValueRange := LookupAffixData("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketLevel, CurrTier)
                            }
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Armour and Energy Shield
        {
            AffixType := "Prefix"
            AESBracketLevel := 0
            ValueRange := LookupAffixData("data\ArmourAndEnergyShield.txt", ItemLevel, CurrValue, AESBracketLevel, CurrTier)
            If (HasStunRecovery)
            {
                AESBracketLevel2 := AESBracketLevel

                AESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AESBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(AESBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AESBracketLevel2, CurrTier)
                }
                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", AESBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(AESBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", AESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    AESBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(AESBSBracket, CurrValue))
                    {
                        AESBracket := LookupRemainingAffixBracket("data\ArmourAndEnergyShield.txt", ItemLevel, CurrValue, AESBSBracket)
                        If (Not IsValidBracket(AESBracket))
                        {
                            AESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(AESBracket, CurrValue))
                        {
                            ValueRange := AddRange(AESBSBracket, AESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }
                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Evasion and Energy Shield
        {
            AffixType := "Prefix"
            EESBracketLevel := 0
            ValueRange := LookupAffixData("data\EvasionAndEnergyShield.txt", ItemLevel, CurrValue, EESBracketLevel, CurrTier)
            If (HasStunRecovery)
            {
                EESBracketLevel2 := EESBracketLevel

                EESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, EESBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(EESBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, EESBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", EESBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(EESBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", EESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    EESBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(EESBSBracket, CurrValue))
                    {
                        EESBracket := LookupRemainingAffixBracket("data\EvasionAndEnergyShield.txt", ItemLevel, CurrValue, EESBSBracket)

                        If (Not IsValidBracket(EESBracket))
                        {
                            EESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(EESBracket, CurrValue))
                        {
                            ValueRange := AddRange(EESBSBracket, EESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Armour
        {
            AffixType := "Prefix"
            IABracketLevel := 0
            If (ItemBaseType == "Item")
            {
                ; Global
                PrefixPath := "data\IncrArmour_Items.txt"
                PrefixPathOther := "data\IncrArmour_WeaponsAndArmour.txt"
            }
            Else
            {
                ; Local
                PrefixPath := "data\IncrArmour_WeaponsAndArmour.txt"
                PrefixPathOther := "data\IncrArmour_Items.txt"
            }
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IABracketLevel, CurrTier)
            If (Not IsValidRange(ValueRange))
            {
                ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, IABracketLevel, CurrTier)
            }
            If (HasStunRecovery)
            {
                IABracketLevel2 := IABracketLevel

                ASRBracket := LookupAffixBracket("data\Armour_StunRecovery.txt", ItemLevel, CurrValue, IABracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(ASRBracket))
                {
                    ValueRange := LookupAffixData("data\Armour_StunRecovery.txt", ItemLevel, CurrValue, IABracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", IABracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ASRBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", IABracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    IABSBracket := LookupAffixBracket("data\Armour_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IABSBracket, CurrValue))
                    {
                        IABracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IABSBracket)
                        If (Not IsValidBracket(IABracket))
                        {
                            IABracket := LookupAffixBracket(PrefixPath, ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(IABracket, CurrValue))
                        {
                            ValueRange := AddRange(IABSBracket, IABracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Evasion Rating
        {
            ; Slinkston edit. I am not sure if using 'else if' statements are the best way here, but it seems to work.
            ; AR, EV, and ES items are all correct for Armour, Shields, Helmets, Boots, Gloves, and different jewelry.
            ; to Evasion Rating has Ring, but does not have Belt or Amulet.
            If (ItemSubType == "Ring")
            {
                ValueRange := LookupAffixData("data\ToEvasionRing.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Helmet")
            {
                ValueRange := LookupAffixData("data\ToEvasionHelmet.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Gloves" or ItemSubType == "Boots")
            {
                ValueRange := LookupAffixData("data\ToEvasionGlovesandBoots.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\ToEvasionArmourandShield.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Evasion Rating
        {
            AffixType := "Prefix"
            IEBracketLevel := 0
            If (ItemBaseType == "Item")
            {
                ; Global
                PrefixPath := "data\IncrEvasion_Items.txt"
                PrefixPathOther := "data\IncrEvasion_Armour.txt"
            }
            Else
            {
                ; Local
                PrefixPath := "data\IncrEvasion_Armour.txt"
                PrefixPathOther := "data\IncrEvasion_Items.txt"
            }
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IEBracketLevel, CurrTier)
            If (Not IsValidRange(ValueRange))
            {
                ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, IEBracketLevel, CurrTier)
            }
            If (HasStunRecovery)
            {
                IEBracketLevel2 := IEBracketLevel

                ; Determine composite bracket level and store in IEBracketLevel2, for example:
                ;   8% increased Evasion
                ;   26% increased Stun and Block Recovery
                ;   => 8% is bracket level 2 (6-14), so 'B&S Recovery from Evasion' level 2 makes
                ;      BSRec partial 6-7
                ERSRBracket := LookupAffixBracket("data\Evasion_StunRecovery.txt", ItemLevel, CurrValue, IEBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(ERSRBracket))
                {
                    ValueRange := LookupAffixData("data\Evasion_StunRecovery.txt", ItemLevel, CurrValue, IEBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", IEBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ERSRBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", IEBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidRange(ValueRange) and (Not IsValidBracket(BSRecPartial) or Not WithinBounds(BSRecPartial, BSRecValue)))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    IEBSBracket := LookupAffixBracket("data\Evasion_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IEBSBracket, CurrValue))
                    {
                        IEBracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IEBSBracket)
                        If (Not IsValidBracket(IEBracket))
                        {
                            IEBracket := LookupAffixBracket(PrefixPath, ItemLevel, CurrValue, "")
                        }
                        If (Not WithinBounds(IEBracket, CurrValue))
                        {
                            ValueRange := AddRange(IEBSBracket, IEBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to maximum Energy Shield
        {
            ; Slinkston Edit. Seems I may have to do the same for EV and AR.
            ; AR, EV, and ES items are all correct for Armour, Shields, Helmets, Boots, Gloves, and different jewelry.
            ; to max ES is found is all jewelry; Amulet, Belt, and Ring.
            PrefixType := "Prefix"
            If (ItemSubType == "Amulet" or ItemSubType == "Belt")
            {
                ValueRange := LookupAffixData("data\ToMaxESAmuletandBelt.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Ring")
            {
                ValueRange := LookupAffixData("data\ToMaxESRing.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Gloves" or ItemSubtype == "Boots")
            {
                ValueRange := LookupAffixData("data\ToMaxESGlovesandBoots.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Helmet")
            {
                ValueRange := LookupAffixData("data\ToMaxESHelmet.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\ToMaxESArmourandShield.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }

        IfInString, A_LoopField, increased Energy Shield
        {
            AffixType := "Prefix"
            IESBracketLevel := 0
            PrefixPath := "data\IncrEnergyShield.txt"
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IESBracketLevel, CurrTier)

            If (HasStunRecovery)
            {
                IESBracketLevel2 := IESBracketLevel

                ESSRBracket := LookupAffixBracket("data\EnergyShield_StunRecovery.txt", ItemLevel, CurrValue, IESBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(ESSRBracket))
                {
                    ValueRange := LookupAffixData("data\EnergyShield_StunRecovery.txt", ItemLevel, CurrValue, IESBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", IESBracketLevel2, "", BSRecBracketLevel)
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ESSRBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", IESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", ItemLevel, "", BSRecBracketLevel)
                    }
                    IESBSBracket := LookupAffixBracket("data\EnergyShield_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IEBSBracket, CurrValue))
                    {
                        IESBracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IESBSBracket)

                        If (Not WithinBounds(IESBracket, CurrValue))
                        {
                            ValueRange := AddRange(IESBSBracket, IESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased maximum Energy Shield
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrMaxEnergyShield_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        If RegExMatch(A_LoopField, "Adds \d+? to \d+? Physical Damage")
        {
            If (ItemBaseType == "Weapon")
            {
                If (ItemSubType == "Bow")
                {
                    ValueRange := LookupAffixData("data\AddedPhysDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (ItemGripType == "1H") ; One handed weapons
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                }
            }
            Else
            {
                If (ItemSubType == "Amulet")
                {
                    ValueRange := LookupAffixData("data\AddedPhysDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                }

                Else
                {
                    If (ItemSubType == "Quiver")
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        If (ItemSubType == "Ring")
                        {
                            ValueRange := LookupAffixData("data\AddedPhysDamage_Rings.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ;Gloves added by Bahnzo
                            If (ItemSubType == "Gloves")
                            {
                                ValueRange := LookupAffixData("data\AddedPhysDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
                            }
                            Else
                            {
                            ; There is no Else for rare items, but some uniques have added phys damage.
                            ; Just lookup in 1H for now...
                            ValueRange := LookupAffixData("data\AddedPhysDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                            }
                        }
                    }
                }
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        If RegExMatch(A_LoopField, "Adds \d+? to \d+? Cold Damage")
        {
        ; Slinkston edit: Thanks to Moth1 on the forums for the suggestion of nesting the ele dmg and ele dmg to spells!
            If RegExMatch(A_LoopField, "Adds \d+? to \d+? Cold Damage to Spells")
        {
        If (ItemGripType == "1H")
        {
            ValueRange := LookupAffixData("data\SpellAddedCold1H.txt", ItemLevel, CurrValue, "", CurrTier)
        }
        Else ; 2 handed weapons. This may need to be changed if bows get added spell damage since they are categorized as 1H, but doubtful.
        {
            ValueRange := LookupAffixData("data\SpellAddedCold2H.txt", ItemLevel, CurrValue, "", CurrTier)
        }
        }
        Else
        {
        If (ItemSubType == "Amulet" or ItemSubType == "Ring")
        {
            ValueRange := LookupAffixData("data\AddedColdDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
        }
        Else
        {
            If (ItemSubType == "Gloves")
            {
            ValueRange := LookupAffixData("data\AddedColdDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                If (ItemSubType == "Quiver")
                {
                ValueRange := LookupAffixData("data\AddedColdDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (ItemGripType == "1H")
                    {
                    ValueRange := LookupAffixData("data\AddedColdDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\AddedColdDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                }
            }
        }
        }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        If RegExMatch(A_LoopField, "Adds \d+? to \d+? Fire Damage")
        {
        ; Slinkston edit: Thanks to Moth1 on the forums for the suggestion of nesting the ele dmg and ele dmg to spells!
            If RegExMatch(A_LoopField, "Adds \d+? to \d+? Fire Damage to Spells")
        {
        If (ItemGripType == "1H")
        {
            ValueRange := LookupAffixData("data\SpellAddedFire1H.txt", ItemLevel, CurrValue, "", CurrTier)
        }
            Else ; 2 handed weapons. This may need to be changed if bows get added spell damage since they are categorized as 1H, but doubtful.
            {
            ValueRange := LookupAffixData("data\SpellAddedFire2H.txt", ItemLevel, CurrValue, "", CurrTier)
            }

        }
        Else
        {
        If (ItemSubType == "Amulet" or ItemSubType == "Ring")
        {
            ValueRange := LookupAffixData("data\AddedFireDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
        }
            Else
            {
            If (ItemSubType == "Gloves")
            {
                ValueRange := LookupAffixData("data\AddedFireDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
            }
                Else
                {
                If (ItemSubType == "Quiver")
                {
                    ValueRange := LookupAffixData("data\AddedFireDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                    Else
                    {
                    If (ItemGripType == "1H") ; One handed weapons
                    {
                        ValueRange := LookupAffixData("data\AddedFireDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                        Else
                        {
                        ValueRange := LookupAffixData("data\AddedFireDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
            }
        }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        If RegExMatch(A_LoopField, "Adds \d+? to \d+? Lightning Damage")
        {
        ; Slinkston edit: Thanks to Moth1 on the forums for the suggestion of nesting the ele dmg and ele dmg to spells!
            If RegExMatch(A_LoopField, "Adds \d+? to \d+? Lightning Damage to Spells")
        {
        If (ItemGripType == "1H")
        {
            ValueRange := LookupAffixData("data\SpellAddedLightning1H.txt", ItemLevel, CurrValue, "", CurrTier)
        }
            Else ; 2 handed weapons. This may need to be changed if bows get added spell damage since they are categorized as 1H, but doubtful.
            {
            ValueRange := LookupAffixData("data\SpellAddedLightning2H.txt", ItemLevel, CurrValue, "", CurrTier)
            }
        }
        Else
        {
        If (ItemSubType == "Amulet" or ItemSubType == "Ring")
        {
            ValueRange := LookupAffixData("data\AddedLightningDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
        }
            Else
            {
            If (ItemSubType == "Gloves")
            {
                ValueRange := LookupAffixData("data\AddedLightningDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
            }
                Else
                {
                If (ItemSubType == "Quiver")
                {
                    ValueRange := LookupAffixData("data\AddedLightningDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                    Else
                    {
                    If (ItemGripType == "1H") ; One handed weapons
                    {
                        ValueRange := LookupAffixData("data\AddedLightningDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                        Else
                        {
                        ValueRange := LookupAffixData("data\AddedLightningDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
            }
        }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }

        If RegExMatch(A_LoopField, "Adds \d+? to \d+? Chaos Damage")
        {
            If (ItemGripType == "1H")
            {
                ValueRange := LookupAffixData("data\AddedChaosDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemGripType == "2H")
            {
                ValueRange := LookupAffixData("data\AddedChaosDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Amulet" or ItemSubType == "Ring")
            {
                ; Master modded prefix
                ValueRange := LookupAffixData("data\AddedChaosDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }

        IfInString, A_LoopField, Physical Damage to Melee Attackers
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\PhysDamagereturn.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, to Level of Socketed
        {
            If (InStr(A_LoopField, "Minion"))
            {
                ValueRange := LookupAffixData("data\GemLevel_Minion.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (InStr(A_LoopField, "Fire") or InStr(A_LoopField, "Cold") or InStr(A_LoopField, "Lightning"))
            {
                ValueRange := LookupAffixData("data\GemLevel_Elemental.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (InStr(A_LoopField, "Melee"))
            {
                ValueRange := LookupAffixData("data\GemLevel_Melee.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (InStr(A_LoopField, "Bow"))
            {
                ValueRange := LookupAffixData("data\GemLevel_Bow.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (InStr(A_LoopField, "Chaos"))
            {
                ValueRange := LookupAffixData("data\GemLevel_Chaos.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            ; Catarina prefix
            Else If (InStr(A_LoopField, "Support"))
            {
                ValueRange := LookupAffixData("data\GemLevel_Support.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (InStr(A_LoopField, "Socketed Gems"))
            {
                ValueRange := LookupAffixData("data\GemLevel.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, maximum Life
        {
            If (ItemSubType == "Amulet" or ItemSubType == "Boots" or ItemSubType == "Gloves")
            {
                ValueRange := LookupAffixData("data\MaxLifeAmuletBootsGloves.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Belt" or ItemSubType == "Helmet" or ItemSubType == "Quiver")
            {
                ValueRange := LookupAffixData("data\MaxLifeBeltHelmetQuiver.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "BodyArmour")
            {
                ValueRange := LookupAffixData("data\MaxLifeBodyArmour.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Shield")
            {
                ValueRange := LookupAffixData("data\MaxLifeShield.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Ring")
            {
                ValueRange := LookupAffixData("data\MaxLifeRing.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\MaxLife.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        IfInString, A_LoopField, Physical Attack Damage Leeched as
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\PhysicalAttackDamageLeeched.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Movement Speed
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\MovementSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
    IfInString, A_LoopField, increased Elemental Damage with Weapons
        {
        ; Slinkston edit. I originally screwed this up , but it is now fixed.
            NumPrefixes += 1
        ValueRange := LookupAffixData("data\IncrWeaponElementalDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }

        ; Flask effects (on belts)
        IfInString, A_LoopField, increased Flask Mana Recovery rate
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\FlaskManaRecoveryRate.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Flask Life Recovery rate
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\FlaskLifeRecoveryRate.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }

        ; Haku prefix
        IfInString, A_LoopField, to Quality of Socketed Support Gems
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\GemQuality_Support.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Elreon prefix
        IfInString, A_LoopField, to Mana Cost of Skills
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\ManaCostOfSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Vorici prefix
        IfInString, A_LoopField, increased Life Leeched per Second
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\LifeLeechedPerSecond.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Vagan prefix
        IfInString, A_LoopField, Hits can't be Evaded
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\HitsCantBeEvaded.txt", ItemLevel, 1, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Tora prefix
        IfInString, A_LoopField, Causes Bleeding on Hit
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CausesBleedingOnHit.txt", ItemLevel, 1, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Tora dual suffixes
        IfInString, A_LoopField, increased Trap Throwing Speed
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrTrapThrowingMineLayingSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Mine Laying Speed
        {
            ; No suffix increase because composite with above
            ValueRange := LookupAffixData("data\IncrTrapThrowingMineLayingSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Trap Damage
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrTrapMineDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Mine Damage
        {
            ; No suffix increase because composite with above
            ValueRange := LookupAffixData("data\IncrTrapMineDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
    }

    ; --- COMPLEX AFFIXES ---

    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }

        CurrValue := GetActualValue(A_LoopField)

        If (Item.IsJewel) {
            Continue
        }

        ; "Spell Damage +%" (simple prefix)
        ; "Spell Damage +% (1H)" / "Base Maximum Mana" - Limited to sceptres, wands, and daggers.
        ; "Spell Damage +% (Staff)" / "Base Maximum Mana"
        IfInString, A_LoopField, increased Spell Damage
        {
            If (Item.IsAmulet) {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\SpellDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            } Else If (Item.SubType == "Shield") {
                NumPrefixes += 1
                ; Shield have the same pure spell damage affixes as 1 handers, but can't get the hybrid spell dmg/mana
                ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }

            AffixType := "Prefix"
            If (HasMaxMana)
            {
                SDBracketLevel := 0
                MMBracketLevel := 0
                MaxManaValue := ExtractValueFromAffixLine(ItemDataChunk, "maximum Mana")
                If (ItemSubType == "Staff")
                {
                    SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_Staff.txt", ItemLevel, CurrValue, SDBracketLevel)
                    If (Not IsValidBracket(SpellDamageBracket))
                    {
                        AffixType := "Comp. Prefix+Prefix"
                        NumPrefixes += 1

                        ; Need to find the bracket level by looking at max mana value instead
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                        If (Not IsValidBracket(MaxManaBracket))
                        {
                            ; This actually means that both the "increased Spell Damage" line and
                            ; the "to maximum Mana" line are made up of Composite Prefix + Prefix.
                            ;
                            ; I haven't seen such an item yet, but you never know. In any case this
                            ; is completely ambiguous and can't be resolved. Mark line with EstInd
                            ; so user knows she needs to take a look at it.
                            AffixType := "Comp. Prefix+Comp. Prefix"
                            ValueRange := StrPad(EstInd, Opts.ValueRangeFieldWidth + StrLen(EstInd), "left")
                        }
                        Else
                        {
                            SpellDamageBracketFromComp := LookupAffixBracket("data\SpellDamage_MaxMana_Staff.txt", MMBracketLevel)
                            SpellDamageBracket := LookupRemainingAffixBracket("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, SpellDamageBracketFromComp, SDBracketLevel)
                            ValueRange := AddRange(SpellDamageBracket, SpellDamageBracketFromComp)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\SpellDamage_MaxMana_Staff.txt", ItemLevel, CurrValue, BracketLevel, CurrTier)
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", BracketLevel)
                        AffixType := "Comp. Prefix"
                    }
                }
                Else
                {
                    SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, SDBracketLevel)
                    If (Not IsValidBracket(SpellDamageBracket))
                    {
                        AffixType := "Comp. Prefix+Prefix"
                        NumPrefixes += 1

                        ; Need to find the bracket level by looking at max mana value instead
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                        If (Not IsValidBracket(MaxManaBracket))
                        {
                            MaxManaBracket := LookupAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                            If (IsValidBracket(MaxManaBracket))
                            {
                                AffixType := "Prefix"
                                If (ItemSubType == "Staff")
                                {
                                    ValueRange := LookupAffixData("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, SDBracketLevel, CurrTier)
                                }
                                Else
                                {
                                    ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SDBracketLevel, CurrTier)
                                }
                                ValueRange := StrPad(ValueRange, Opts.ValueRangeFieldWidth, "left")
                            }
                            Else
                            {
                                ; Must be 1H Spell Damage and Max Mana + 1H Spell Damage (+ Max Mana)
                                SD1HBracketLevel := 0
                                SpellDamage1HBracket := LookupAffixBracket("data\SpellDamage_1H.txt", ItemLevel, "", SD1HBracketLevel)
                                If (IsValidBracket(SpellDamage1HBracket))
                                {
                                    SpellDamageBracket := LookupRemainingAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, SpellDamage1HBracket, SDBracketLevel)
                                    If (IsValidBracket(SpellDamageBracket))
                                    {
                                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketLevel, "", MMBracketLevel)
                                        ; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
                                        MaxManaBracketRem := LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
                                        If (Not IsValidBracket(MaxManaBracketRem))
                                        {
                                            ; Nope, try again: check highest spell damage max mana first then spell damage
                                            SD1HBracketLevel := 0
                                            SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, "", SDBracketLevel)
                                            SpellDamage1HBracket := LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracket, SD1HBracketLevel)
                                            MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketLevel, "", MMBracketLevel)
                                            ; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
                                            MaxManaBracketRem := LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
                                            ValueRange := AddRange(SpellDamageBracket, SpellDamage1HBracket)
                                            ValueRange := MarkAsGuesstimate(ValueRange)
                                        }
                                        Else
                                        {
                                            ValueRange := AddRange(SpellDamageBracket, SpellDamage1HBracket)
                                            ValueRange := MarkAsGuesstimate(ValueRange)
                                        }
                                    }
                                    Else
                                    {
                                        SD1HBracketLevel := 0
                                        SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, "", SDBracketLevel)
                                        SpellDamage1HBracket := LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracket, SD1HBracketLevel)
                                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketLevel, "", MMBracketLevel)
                                        ; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
                                        MaxManaBracketRem := LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
                                        ValueRange := AddRange(SpellDamageBracket, SpellDamage1HBracket)
                                        ValueRange := MarkAsGuesstimate(ValueRange)
                                    }
                                }
                                Else
                                {
                                    ShowUnhandledCaseDialog()
                                    ValueRange := StrPad("n/a", Opts.ValueRangeFieldWidth, "left")
                                }
                            }
                        }
                        Else
                        {
                            SpellDamageBracketFromComp := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", MMBracketLevel)
                            SpellDamageBracket := LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracketFromComp, SDBracketLevel)
                            ValueRange := AddRange(SpellDamageBracket, SpellDamageBracketFromComp)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, BracketLevel, CurrTier)
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", BracketLevel)
                        AffixType := "Comp. Prefix"
                    }
                }
                ; If MaxManaValue falls within bounds of MaxManaBracket this means the max mana value is already fully accounted for
                If (WithinBounds(MaxManaBracket, MaxManaValue))
                {
                    MaxManaPartial =
                }
                Else
                {
                    MaxManaPartial := MaxManaBracket
                }
            }
            Else
            {
                If (ItemSubType == "Staff")
                {
                    ValueRange := LookupAffixData("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                NumPrefixes += 1
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        ; "Base Maximum Mana" (simple Prefix)
        ; "1H Spell Damage" / "Base Maximum Mana" (complex Prefix)
        ; "Staff Spell Damage" / "Base Maximum Mana" (complex Prefix)
        IfInString, A_LoopField, maximum Mana
        {
            AffixType := "Prefix"
            If (ItemBaseType == "Weapon")
            {
                If (HasSpellDamage)
                {
                    If (MaxManaPartial and Not WithinBounds(MaxManaPartial, CurrValue))
                    {
                        NumPrefixes += 1
                        AffixType := "Comp. Prefix+Prefix"

                        ValueRange := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, CurrValue)
                        MaxManaRest := CurrValue-RangeMid(MaxManaPartial)

                        If (MaxManaRest >= 15) ; 15 because the lowest possible value at this time for Max Mana is 15 at bracket level 1
                        {
                            ; Lookup remaining Max Mana bracket that comes from Max Mana being concatenated as simple prefix
                            ValueRange1 := LookupAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaRest)
                            ValueRange2 := MaxManaPartial

                            ; Add these ranges together to get an estimated range
                            ValueRange := AddRange(ValueRange1, ValueRange2)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                        Else
                        {
                            ; Could be that the spell damage affix is actually a pure spell damage affix
                            ; (w/o the added max mana) so this would mean max mana is a pure prefix - if
                            ; NumPrefixes allows it, ofc...
                            If (NumPrefixes < 3)
                            {
                                AffixType := "Prefix"
                                ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
                                ChangeAffixDetailLine("increased Spell Damage", "Comp. Prefix", "Prefix")
                            }
                        }
                    }
                    Else
                    {
                        ; It's on a weapon, there is Spell Damage but no MaxManaPartial or NumPrefixes already is 3
                        AffixType := "Comp. Prefix"
                        ValueRange := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, CurrValue)
                        If (Not IsValidBracket(ValueRange))
                        {
                            ; incr. Spell Damage is actually a Prefix and not a Comp. Prefix,
                            ; so Max Mana must be a normal Prefix as well then
                            AffixType := "Prefix"
                            ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    ; Check if we still need to increment for the Spell Damage part
                    If (NumPrefixes < 3)
                    {
                        NumPrefixes += 1
                    }
                }
                Else
                {
                    ; It's on a weapon but there is no Spell Damage, which makes it a simple Prefix
                    Goto, SimpleMaxManaPrefix
                }
            }
            Else
            {
                ; Armour...
                ; Max Mana cannot appear on belts but I won't exclude them for now
                ; to future-proof against when max mana on belts might be added.
                Goto, SimpleMaxManaPrefix
            }

            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue

        SimpleMaxManaPrefix:
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        ; "Local Physical Damage +%" (simple Prefix)
        ; "Local Physical Damage +%" / "Local Accuracy Rating" (complex Prefix)
        ; - on Weapons (local)and Jewels (global)
        ; - needs to come before Accuracy Rating stuff (!)
        IfInString, A_LoopField, increased Physical Damage
        {
            AffixType := "Prefix"
            IPDPath := "data\IncrPhysDamage.txt"
            If (HasToAccuracyRating)
            {
                ARIPDPath := "data\AccuracyRating_IncrPhysDamage.txt"
                IPDARPath := "data\IncrPhysDamage_AccuracyRating.txt"
                ARValue := ExtractValueFromAffixLine(ItemDataChunk, "to Accuracy Rating")
                ARPath := "data\AccuracyRating_Global.txt"
                If (ItemBaseType == "Weapon")
                {
                    ARPath := "data\AccuracyRating_Local.txt"
                }

                ; Look up IPD bracket, and use its bracket level to cross reference the corresponding
                ; AR bracket. If both check out (are within bounds of their bracket level) case is
                ; simple: Comp. Prefix (IPD / AR)
                IPDBracketLevel := 0
                IPDBracket := LookupAffixBracket(IPDARPath, ItemLevel, CurrValue, IPDBracketLevel)
                ARBracket := LookupAffixBracket(ARIPDPath, IPDBracketLevel)

                If (HasIncrLightRadius)
                {
                    LRValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Light Radius")
                    ; First check if the AR value that comes with the Comp. Prefix AR / Light Radius
                    ; already covers the complete AR value. If so, from that follows that the Incr.
                    ; Phys Damage value can only be a Damage Scaling prefix.
                    LRBracketLevel := 0
                    LRBracket := LookupAffixBracket("data\LightRadius_AccuracyRating.txt", ItemLevel, LRValue, LRBracketLevel)
                    ARLRBracket := LookupAffixBracket("data\AccuracyRating_LightRadius.txt", LRBracketLevel)
                    If (IsValidBracket(ARLRBracket))
                    {
                        If (WithinBounds(ARLRBracket, ARValue) and WithinBounds(IPDBracket, CurrValue))
                        {
                            Goto, SimpleIPDPrefix
                        }
                    }
                }

                If (IsValidBracket(IPDBracket) and IsValidBracket(ARBracket))
                {
                    Goto, CompIPDARPrefix
                }

                If (Not IsValidBracket(IPDBracket))
                {
                    IPDBracket := LookupAffixBracket(IPDPath, ItemLevel, CurrValue)
                    ARBracket := LookupAffixBracket(ARPath, ItemLevel, ARValue)  ; Also lookup AR as if it were a simple Suffix
                    ARIPDBracket := LookupAffixBracket(ARIPDPath, ItemLevel, ARValue, ARBracketLevel)

                    If (IsValidBracket(IPDBracket) and IsValidBracket(ARBracket) and NumPrefixes < 3)
                    {
                        HasIncrPhysDmg := 0
                        Goto, SimpleIPDPrefix
                    }
                    ARBracketLevel := 0
                    ARBracket := LookupAffixBracket(ARIPDPath, ItemLevel, ARValue, ARBracketLevel)
                    If (IsValidBracket(ARBracket))
                    {
                        IPDARBracket := LookupAffixBracket(IPDARPath, ARBracketLevel)
                        IPDBracket := LookupRemainingAffixBracket(IPDPath, ItemLevel, CurrValue, IPDARBracket)
                        If (IsValidBracket(IPDBracket))
                        {
                            ValueRange := AddRange(IPDARBracket, IPDBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            ARAffixTypePartial := "Comp. Prefix"
                            Goto, CompIPDARPrefixPrefix
                        }
                    }
                    If (Not IsValidBracket(IPDBracket) and IsValidBracket(ARBracket))
                    {
                        If (Not WithinBounds(ARBracket, ARValue))
                        {
                            ARRest := ARValue - RangeMid(ARBracket)
                        }
                        IPDBracket := LookupRemainingAffixBracket(IPDPath, ItemLevel, CurrValue, IPDARBracket, IPDBracketLevel)
                        If (IsValidBracket(IPDBracket))
                        {
                            ValueRange := AddRange(IPDARBracket, IPDBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            ARAffixTypePartial := "Comp. Prefix"
                            Goto, CompIPDARPrefixPrefix
                        }
                        Else If (IsValidBracket(IPDARBracket) and NumPrefixes < 3)
                        {
                            IPDBracket := LookupRemainingAffixBracket(IPDPath, ItemLevel, IPDRest, IPDARBracket)
                            If (IsValidBracket(IPDBracket))
                            {
                                NumPrefixes += 1
                                ValueRange := AddRange(IPDARBracket, IPDBracket)
                                ValueRange := MarkAsGuesstimate(ValueRange)
                                ARAffixTypePartial := "Comp. Prefix"
                                Goto, CompIPDARPrefixPrefix
                            }

                        }
                    }
                    If ((Not IsValidBracket(IPDBracket)) and (Not IsValidBracket(ARBracket)))
                    {
                        IPDBracket := LookupAffixBracket(IPDPath, ItemLevel, "")
                        IPDARBracket := LookupRemainingAffixBracket(IPDARPath, ItemLevel, CurrValue, IPDBracket, ARBracketLevel)
                        ARBracket := LookupAffixBracket(ARIPDPath, ARBracketLevel, "")
                        ValueRange := AddRange(IPDARBracket, IPDBracket)
                        ValueRange := MarkAsGuesstimate(ValueRange)
                        Goto, CompIPDARPrefixPrefix
                    }
                }

                If ((Not IsValidBracket(IPDBracket)) and (Not IsValidBracket(ARBracket)))
                {
                    HasIncrPhysDmg := 0
                    Goto, CompIPDARPrefixPrefix
                }

                If (IsValidBracket(ARBracket))
                {
                    ; AR bracket not found in the composite IPD/AR table
                    ARValue := ExtractValueFromAffixLine(ItemDataChunk, "to Accuracy Rating")
                    ARBracket := LookupAffixBracket(ARPath, ItemLevel, ARValue)

                    Goto, CompIPDARPrefix
                }
                If (IsValidBracket(IPDBracket))
                {
                    ; AR bracket was found in the comp. IPD/AR table, but not the IPD bracket
                    Goto, SimpleIPDPrefix
                }
                Else
                {
                    ValueRange := LookupAffixData(IPDPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            Else
            {
                Goto, SimpleIPDPrefix
            }

            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue

        SimpleIPDPrefix:
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        CompIPDARPrefix:
            AffixType := "Comp. Prefix"
            ValueRange := LookupAffixData(IPDARPath, ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            ARPartial := ARBracket
            Continue
        CompIPDARPrefixPrefix:
            NumPrefixes += 1
            AffixType := "Comp. Prefix+Prefix"
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            ARPartial := ARBracket
            Continue
        }

        IfInString, A_LoopField, increased Stun and Block Recovery
        {
            AffixType := "Prefix"
            If (HasHybridDefences)
            {
                AffixType := "Comp. Prefix"
                BSRecAffixPath := "data\StunRecovery_Hybrid.txt"
                BSRecAffixBracket := LookupAffixBracket(BSRecAffixPath, ItemLevel, CurrValue)
                If (Not IsValidBracket(BSRecAffixBracket))
                {
                    CompStatAffixType =
                    If (HasIncrArmourAndEvasion)
                    {
                        PartialAffixString := "increased Armour and Evasion"
                    }
                    If (HasIncrEvasionAndES)
                    {
                        PartialAffixString := "increased Evasion and Energy Shield"
                    }
                    If (HasIncrArmourAndES)
                    {
                        PartialAffixString := "increased Armour and Energy Shield"
                    }
                    CompStatAffixType := GetAffixTypeFromProcessedLine(PartialAffixString)
                    If (BSRecPartial)
                    {
                        If (WithinBounds(BSRecPartial, CurrValue))
                        {
                            IfInString, CompStatAffixType, Comp. Prefix
                            {
                                AffixType := CompStatAffixType
                            }
                        }
                        Else
                        {
                            If (NumSuffixes < 3)
                            {
                                AffixType := "Comp. Prefix+Suffix"
                                BSRecAffixBracket := LookupRemainingAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, BSRecPartial)
                                If (Not IsValidBracket(BSRecAffixBracket))
                                {
                                    AffixType := "Comp. Prefix+Prefix"
                                    BSRecAffixBracket := LookupAffixBracket("data\StunRecovery_Prefix.txt", ItemLevel, CurrValue)
                                    If (Not IsValidBracket(BSRecAffixBracket))
                                    {
                                        If (CompStatAffixType == "Comp. Prefix+Prefix" and NumSuffixes < 3)
                                        {
                                            AffixType := "Comp. Prefix+Suffix"
                                            BSRecSuffixBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRest)
                                            NumSuffixes += 1
                                            If (Not IsValidBracket(BSRecSuffixBracket))
                                            {
                                                ; TODO: properly deal with this quick fix!
                                                ;
                                                ; if this point is reached this means that the parts that give to
                                                ; increased armor/evasion/es/hybrid + stun recovery need to fully be
                                                ; re-evaluated.
                                                ;
                                                ; take an ilvl 62 item with these 2 lines:
                                                ;
                                                ;   118% increased Armour and Evasion
                                                ;   24% increased Stun and Block Recovery
                                                ;
                                                ; Since it's ilvl 62, we assume the hybrid + stun recovery bracket to be the
                                                ; highest possible (lvl 60 bracket), which is 42-50. So that's max 50 of the
                                                ; 118 dealth with.
                                                ; Consequently, that puts the stun recovery partial at 14-15 for the lvl 60 bracket.
                                                ; This now leaves, 68 of hybrid defence to account for, which we can do by assuming
                                                ; the remainder to come from a hybrid defence prefix. So that's incr. Armour and Evasion
                                                ; identified as CP+P
                                                ; However, here come's the problem, our lvl 60 bracket had 14-15 stun recovery which
                                                ; assuming max, leaves 9 remainder (24-15) to account for. Should be easy, right?
                                                ; Just assume the rest comes from a stun recovery suffix and look it up. Except the
                                                ; lowest possible entry for a stun recovery suffix is 11! Leaving us with the issues that
                                                ; we know that CP+P is right for the hybrid + stun recovery line and CP+S is right for the
                                                ; stun recovery line.
                                                ; Most likely, what is wrong is the assumption earlier to take the highest possible
                                                ; hybrid + stun recovery bracket. Problem is that wasn't apparent when hybrid defences
                                                ; was processed.
                                                ; At this point, a quick fix what I am doing is I just look up the complete stun recovery
                                                ; value as if it were a suffix completely but still mark it as CP+S.
                                                ; To deal with this correctly I would need to reprocess the hybrid + stun recovery line here
                                                ; with a different ratio of the CP part to the P part to get a lower BSRecPartial.
                                                ;
                                                BSRecSuffixBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue)
                                                ValueRange := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue)
                                                ValueRange := MarkAsGuesstimate(ValueRange)
                                            }
                                            Else
                                            {
                                                ValueRange := AddRange(BSRecSuffixBracket, BSRecPartial)
                                                ValueRange := MarkAsGuesstimate(ValueRange)
                                            }
                                        }
                                        Else
                                        {
                                            AffixType := "Suffix"
                                            ValueRange := LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
                                            If (NumSuffixes < 3)
                                            {
                                                NumSuffixes += 1
                                            }
                                            ChangeAffixDetailLine(PartialAffixString, "Comp. Prefix" , "Prefix")
                                        }
                                    }
                                    Else
                                    {
                                        If (NumPrefixes < 3)
                                        {
                                            NumPrefixes += 1
                                        }
                                    }
                                }
                                Else
                                {
                                    NumSuffixes += 1
                                    ValueRange := AddRange(BSRecPartial, BSRecAffixBracket)
                                    ValueRange := MarkAsGuesstimate(ValueRange)
                                }
                            }
                        }
                    }
                    Else
                    {
                        ; Simple Stun Rec suffix
                        AffixType := "Suffix"
                        ValueRange := LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
                        NumSuffixes += 1
                    }
                }
                Else
                {
                    ValueRange := LookupAffixData(BSRecAffixPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            Else
            {
                AffixType := "Comp. Prefix"
                If (HasIncrArmour)
                {
                    PartialAffixString := "increased Armour"
                    BSRecAffixPath := "data\StunRecovery_Armour.txt"
                }
                If (HasIncrEvasion)
                {
                    PartialAffixString := "increased Evasion Rating"
                    BSRecAffixPath := "data\StunRecovery_Evasion.txt"
                }
                If (HasIncrEnergyShield)
                {
                    PartialAffixString := "increased Energy Shield"
                    BSRecAffixPath := "data\StunRecovery_EnergyShield.txt"
                }
                BSRecAffixBracket := LookupAffixBracket(BSRecAffixPath, ItemLevel, CurrValue)
                If (Not IsValidBracket(BSRecAffixBracket))
                {
                    CompStatAffixType := GetAffixTypeFromProcessedLine(PartialAffixString)
                    If (BSRecPartial)
                    {
                        If (WithinBounds(BSRecPartial, CurrValue))
                        {
                            IfInString, CompStatAffixType, Comp. Prefix
                            {
                                AffixType := CompStatAffixType
                            }
                        }
                        Else
                        {
                            If (NumSuffixes < 3)
                            {
                                AffixType := "Comp. Prefix+Suffix"
                                BSRecAffixBracket := LookupRemainingAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, BSRecPartial)
                                If (Not IsValidBracket(BSRecAffixBracket))
                                {
                                    AffixType := "Comp. Prefix+Prefix"
                                    BSRecAffixBracket := LookupAffixBracket("data\StunRecovery_Prefix.txt", ItemLevel, CurrValue)
                                    If (Not IsValidBracket(BSRecAffixBracket))
                                    {
                                        AffixType := "Suffix"
                                        ValueRange := LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
                                        If (NumSuffixes < 3)
                                        {
                                            NumSuffixes += 1
                                        }
                                        ChangeAffixDetailLine(PartialAffixString, "Comp. Prefix" , "Prefix")
                                    }
                                    Else
                                    {
                                        If (NumPrefixes < 3)
                                        {
                                            NumPrefixes += 1
                                        }
                                    }

                                }
                                Else
                                {
                                    NumSuffixes += 1
                                    ValueRange := AddRange(BSRecPartial, BSRecAffixBracket)
                                    ValueRange := MarkAsGuesstimate(ValueRange)
                                }
                            }
                        }
                    }
                    Else
                    {
                        BSRecSuffixPath := "data\StunRecovery_Suffix.txt"
                        BSRecSuffixBracket := LookupAffixBracket(BSRecSuffixPath, ItemLevel, CurrValue)
                        If (IsValidBracket(BSRecSuffixBracket))
                        {
                            AffixType := "Suffix"
                            ValueRange := LookupAffixData(BSRecSuffixPath, ItemLevel, CurrValue, "", CurrTier)
                            If (NumSuffixes < 3)
                            {
                                NumSuffixes += 1
                            }
                        }
                        Else
                        {
                            BSRecPrefixPath := "data\StunRecovery_Prefix.txt"
                            BSRecPrefixBracket := LookupAffixBracket(BSRecPrefixPath, ItemLevel, CurrValue)
                            ValueRange := LookupAffixData(BSRecPrefixPath, ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
                Else
                {
                    ValueRange := LookupAffixData(BSRecAffixPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        ; AR is one tough beast... currently there are the following affixes affecting AR:
        ;   1) "Accuracy Rating" (Suffix)
        ;   2) "Local Accuracy Rating" (Suffix)
        ;   3) "Light Radius / + Accuracy Rating" (Suffix) - only the first 2 entries, bc last entry combines LR with #% increased Accuracy Rating instead!
        ;   4) "Local Physical Dmg +% / Local Accuracy Rating" (Prefix)

        ; The difficulty lies in those cases that combine multiples of these affixes into one final display value.
        ; Currently I try and tackle this by using a trickle-through partial balance approach. That is, go from
        ; most special case to most normal, while subtracting the value that each case most likely contributes
        ; until you have a value left that can be found in the most nominal case.
        ;
        ; Important to note here:
        ;   ARPartial will be set during the "increased Physical Damage" case above

        IfInString, A_LoopField, to Accuracy Rating
        {
            ; Trickle-through order:
            ;   1) increased AR, Light Radius, all except Belts, Comp. Suffix
            ;   2) to AR, Light Radius, all except Belts, Comp. Suffix
            ;   3) increased Phys Damage, to AR, Weapons, Prefix
            ;   4) to AR, all except Belts, Suffix

            ValueRangeAR := "0-0"
            AffixType := ""
            IPDAffixType := GetAffixTypeFromProcessedLine("increased Physical Damage")
            If (HasIncrLightRadius and Not HasIncrAccuracyRating)
            {
                ; "of Shining" and "of Light"
                LightRadiusValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Light Radius")

                ; Get bracket level of the light radius so we can look up the corresponding AR bracket
                BracketLevel := 0
                LookupAffixBracket("data\LightRadius_AccuracyRating.txt", ItemLevel, LightRadiusValue, BracketLevel)
                ARLRBracket := LookupAffixBracket("data\AccuracyRating_LightRadius.txt", BracketLevel)

                AffixType := AffixType . "Comp. Suffix"
                ValueRange := LookupAffixData("data\AccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
                NumSuffixes += 1

                If (ARPartial)
                {
                    ; Append this affix' contribution to our partial AR range
                    ARPartial := AddRange(ARPartial, ARLRBracket)
                }
                ; Test if candidate range already covers current  AR value
                If (WithinBounds(ARLRBracket, CurrValue))
                {
                    Goto, FinalizeAR
                }
                Else
                {
                    AffixType := "Comp. Suffix+Suffix"
                    If (HasIncrPhysDmg)
                    {
                        If (ARPartial)
                        {
                            CombinedRange := AddRange(ARLRBracket, ARPartial)
                            AffixType := "Comp. Prefix+Comp. Suffix"

                            If (WithinBounds(CombinedRange, CurrValue))
                            {
                                If (NumPrefixes < 3)
                                {
                                    NumPrefixes += 1
                                }
                                ValueRange := CombinedRange
                                ValueRange := MarkAsGuesstimate(ValueRange)
                                Goto, FinalizeAR
                            }
                            Else
                            {
                                NumSuffixes -= 1
                            }
                        }

                        If (InStr(IPDAffixType, "Comp. Prefix"))
                        {
;                            AffixType := "Comp. Prefix+Comp. Suffix+Suffix"
                            If (NumPrefixes < 3)
                            {
                                NumPrefixes += 1
                            }
                        }
                    }
                    ARBracket := LookupRemainingAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, CurrValue, ARLRBracket)
                    ValueRange := AddRange(ARBracket, ARLRBracket)
                    ValueRange := MarkAsGuesstimate(ValueRange)
                    NumSuffixes += 1
                    Goto, FinalizeAR
                }
            }
            If (ItemBaseType == "Weapon" and HasIncrPhysDmg)
            {
                ; This is one of the trickiest cases currently (EDIT: nope, I have seen trickier stuff still ;D)
                ;
                ; If this If-construct is reached that means the item has multiple composites:
                ;   "To Accuracy Rating / Increased Light Radius" and
                ;   "Increased Physical Damage / To Accuracy Rating".
                ;
                ; On top of that it might also contain part "To Accuracy Rating" suffix, all of which are
                ; concatenated into one single "to Accuracy Rating" entry.
                ; Currently it handles most cases, if not all, but I still have a feeling I am missing
                ; something... (EDIT: a feeling I won't be able to shake ever with master crafted affixes now)
                ;
                ; GGG, if you are reading this: please add special markup for affix compositions!
                ;
                If (ARPartial)
                {
                    If (WithinBounds(ARPartial, CurrValue))
                    {
                        AffixType := "Comp. Prefix"
                        If (NumPrefixes < 3)
                        {
                            NumPrefixes += 1
                        }
                        ValueRange := LookupAffixData("data\AccuracyRating_IncrPhysDamage.txt", ItemLevel, RangeMid(ARPartial), "", CurrTier)
                        Goto, FinalizeAR
                    }

                    ARPartialMid := RangeMid(ARPartial)
                    ARRest := CurrValue - ARPartialMid
                    If (ItemSubType == "Mace" and ItemGripType == "2H")
                    {
                        ARBracket := LookupAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, ARRest)
                    }
                    Else
                    {
                        ARBracket := LookupAffixBracket("data\AccuracyRating_Local.txt", ItemLevel, ARRest)
                    }

                    If (IsValidBracket(ARBracket))
                    {
                        AffixType := "Comp. Prefix+Suffix"
                        If (NumSuffixes < 3)
                        {
                            NumSuffixes += 1
                        }
                        Else
                        {
                            AffixType := "Comp. Prefix"
                            If (NumPrefixes < 3)
                            {
                                NumPrefixes += 2
                            }
                        }
                        NumPrefixes += 1
                        ValueRange := AddRange(ARBracket, ARPartial)
                        ValueRange := MarkAsGuesstimate(ValueRange)

                        Goto, FinalizeAR
                    }
                }
                Else
                {
                    ActualValue := CurrValue
                }

                ValueRangeAR := LookupAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, ActualValue)
                If (IsValidBracket(ValueRangeAR))
                {
                    If (NumPrefixes >= 3)
                    {
                        AffixType := "Suffix"
                        If (NumSuffixes < 3)
                        {
                            NumSuffixes += 1
                        }
                        ValueRange := LookupAffixData("data\AccuracyRating_Local.txt", ItemLevel, ActualValue, "", CurrTier)
                    }
                    Else
                    {
                        IfInString, IPDAffixType, Comp. Prefix
                        {
                            AffixType := "Comp. Prefix"
                        }
                        Else
                        {
                            AffixType := "Prefix"
                        }
                        NumPrefixes += 1
                    }
                    Goto, FinalizeAR
                }
                Else
                {
                    ARValueRest := CurrValue - (RangeMid(ValueRangeAR))
                    If (HasIncrLightRadius and Not HasIncrAccuracyRating)
                    {
                        AffixType := "Comp. Prefix+Comp. Suffix+Suffix"
                    }
                    Else
                    {
                        AffixType := "Comp. Prefix+Suffix"
                    }
                    NumPrefixes += 1
                    NumSuffixes += 1
                    ;~ ValueRange := LookupAffixData("data\AccuracyRating_IncrPhysDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                    ValueRange := AddRange(ARPartial, ValueRangeAR)
                    ValueRange := MarkAsGuesstimate(ValueRange)
                }
                ; NumPrefixes should be incremented already by "increased Physical Damage" case
                Goto, FinalizeAR
            }
            AffixType := "Suffix"
            ValueRange := LookupAffixData("data\AccuracyRating_Global.txt", ItemLevel, CurrValue, "", CurrTier)
            NumSuffixes += 1
            Goto, FinalizeAR

        FinalizeAR:
            If (StrLen(ARAffixTypePartial) > 0 and (Not InStr(AffixType, ARAffixTypePartial)))
            {
                AffixType := ARAffixTypePartial . "+" . AffixType
                If (InStr(ARAffixTypePartial, "Prefix") and NumPrefixes < 3)
                {
                    NumPrefixes += 1
                }
                Else If (InStr(ARAffixTypePartial, "Suffix") and NumSuffixes < 3)
                {
                    NumSuffixes += 1
                }
                ARAffixTypePartial =
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, increased Rarity
        {
            ActualValue := CurrValue
            If (NumSuffixes <= 3)
            {
                ValueRange := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, ActualValue)
                ValueRangeAlt := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, ActualValue)
            }
            Else
            {
                ValueRange := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, ActualValue)
                ValueRangeAlt := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, ActualValue)
            }
            If (Not IsValidBracket(ValueRange))
            {
                If (Not IsValidBracket(ValueRangeAlt))
                {
                    NumPrefixes += 1
                    NumSuffixes += 1
                    ; Try to reverse engineer composition of both ranges
                    PrefixDivisor := 1
                    SuffixDivisor := 1
                    Loop
                    {
                        ValueRangeSuffix := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, Floor(ActualValue/SuffixDivisor))
                        ValueRangePrefix := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, Floor(ActualValue/PrefixDivisor))
                        If (Not IsValidBracket(ValueRangeSuffix))
                        {
                            SuffixDivisor += 0.25
                        }
                        If (Not IsValidBracket(ValueRangePrefix))
                        {
                            PrefixDivisor += 0.25
                        }
                        If ((IsValidBracket(ValueRangeSuffix)) and (IsValidBracket(ValueRangePrefix)))
                        {
                            Break
                        }
                    }
                    ValueRange := AddRange(ValueRangePrefix, ValueRangeSuffix)
                    Goto, FinalizeIIRAsPrefixAndSuffix
                }
                Else
                {
                    ValueRange := ValueRangePrefix
                    Goto, FinalizeIIRAsPrefix
                }
            }
            Else
            {
                If (NumSuffixes >= 3) {
                    Goto, FinalizeIIRAsPrefix
                }
                Goto, FinalizeIIRAsSuffix
            }

            FinalizeIIRAsPrefix:
                ; Slinkston edit
        If (ItemSubType == "Ring" or ItemSubType == "Amulet")
        {
            ValueRange := LookupAffixData("data\IIR_PrefixRingAndAmulet.txt", ItemLevel, ActualValue, "", CurrTier)
        }
            Else
            {
            ValueRange := LookupAffixData("data\IIR_Prefix.txt", ItemLevel, ActualValue, "", CurrTier)
            }
                NumPrefixes += 1
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue

            FinalizeIIRAsSuffix:
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\IIR_Suffix.txt", ItemLevel, ActualValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue

            FinalizeIIRAsPrefixAndSuffix:
                ValueRange := MarkAsGuesstimate(ValueRange)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix+Suffix", ValueRange, CurrTier), A_Index)
                Continue
        }
    }

    ; --- CRAFTED --- (Preliminary Support)

    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }

        IfInString, A_LoopField, Can have multiple Crafted Mods
        {
            AppendAffixInfo(A_Loopfield, A_Index)
        }
        IfInString, A_LoopField, to Weapon range
        {
            AppendAffixInfo(A_Loopfield, A_Index)
        }
    }


    ; --- COMPLEX AFFIXES JEWELS ---
    ; The plan was to use a recursive function to test all possible combinations in a way that could be easily adapted for any complex affix.
    ; Unfortunately AutoHotkey doesn't like combining recursive functions and ByRef.
    ; https://autohotkey.com/board/topic/70635-byref-limitation/
    ; Until this problem in AutoHotkey is solved or an alternative, universal, method is found the code below handles accuracy/crit chance on jewels only.
    If (Item.SubType == "Viridian Jewel" and (CAIncAccuracy or CAGlobalCritChance)) {
        If (CAIncAccuracy and CAGlobalCritChance) {
            If (Item.Rarity == 2 or NumSuffixes == 1) {
                ; On jewels with another suffix already or jewels that can only have 1 suffix (magic items) that single suffix must be the combined one
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\jewel\CritChanceGlobal_Jewels_Acc.txt", ItemLevel, CAGlobalCritChance, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, "Comp. Suffix", ValueRange, CurrTier), CAGlobalCritChanceAffixLineNo)
                NextAffixPos += 1
                ValueRange := LookupAffixData("data\jewel\IncrAccuracyRating_Jewels_Crit.txt", ItemLevel, CAIncAccuracy, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, "Comp. Suffix", ValueRange, CurrTier), CAIncAccuracyAffixLineNo)
            } Else {
                ; Item has both increased accuracy and global crit chance and can have 2 suffixes: complex affix possible

                has_combined_acc_crit := 0

                If (CAIncAccuracy >= 6 and CAIncAccuracy <= 9) {
                    ; Accuracy is the result of the combined accuracy/crit_chance affix
                    has_combined_acc_crit := 1
                    NumSuffixes += 1
                    ValueRange := "   6-10    6-10"
                    AffixType := "Comp. Suffix"
                } Else If (CAIncAccuracy = 10) {
                    ; IncAccuracy can be either the combined affix or pure accuracy
                    If ((CAGlobalCritChance >= 6 and CAGlobalCritChance <= 7) or (CAGlobalCritChance >= 14)) {
                        ; Because the global crit chance is only possible with the combined affix the accuracy has to be the result of that
                        has_combined_acc_crit := 1
                        ValueRange := "   6-10    6-10"
                        AffixType := "Comp. Suffix"
                    } Else If (CAGlobalCritChance >= 11 and CAGlobalCritChance <= 12) {
                        ; Global crit chance can only be the pure affix, this means accuracy can't be the combined affix
                        ValueRange := "  10-14   10-14"
                        AffixType := "Suffix"
                    } Else {
                        ValueRange := "   6-14    6-14"
                        AffixType := "Comp. Suffix"
                        ; TODO: fix handling unknown number of affixes
                    }
                    NumSuffixes += 1
                } Else If (CAIncAccuracy >= 11 and CAIncAccuracy <= 14) {
                    ; Increased accuracy can only be the pure accuracy roll
                    NumSuffixes += 1
                    ValueRange := "  10-14   10-14"
                    AffixType := "Suffix"
                } Else If (CAIncAccuracy >= 16) {
                    ; Increased accuracy can only be a combination of the complex and pure affixes
                    has_combined_acc_crit := 1
                    NumSuffixes += 2
                    ValueRange := "  16-24   16-24"
                    AffixType := "Comp. Suffix"
                }

                AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, AffixType, ValueRange, 1), CAIncAccuracyAffixLineNo)
                NextAffixPos += 1

                If (CAGlobalCritChance >= 6 and CAGlobalCritChance <= 7) {
                    ; Crit chance is the result of the combined accuracy/crit_chance affix
                    ; don't update suffix count, should this should have already been done during Inc Accuracy detection
                    ; NumSuffixes += 1
                    ValueRange := "   6-10    6-10"
                    AffixType := "Comp. Suffix"
                } Else If (CAGlobalCritChance >= 8 and CAGlobalCritChance <= 10) {
                    ; Crit chance can be either the combined affix or pure crit chance
                    If ((CAIncAccuracy >= 6 and CAIncAccuracy <= 9) or (CAIncAccuracy >= 16)) {
                        ; Because the inc accuracy is only possible with the combined affix the global crit chance also has to be the result of that
                        ; don't update suffix count, should this should have already been done during Inc Accuracy detection
                        ; NumSuffixes += 1
                        ValueRange := "   6-10    6-10"
                        AffixType := "Comp. Suffix"
                    } Else If (CAIncAccuracy >= 11 and CAIncAccuracy <= 14) {
                        ; Inc Accuracy can only be the pure affix, this means global crit chance can't be the combined affix
                        NumSuffixes += 1
                        ValueRange := "   8-12    8-12"
                        AffixType := "Suffix"
                    } Else {
                        ; TODO: fix handling unknown number of affixes
                        ValueRange := "   6-12    6-12"
                        AffixType := "Comp. Suffix"
                    }
                    NumSuffixes += 1
                } Else If (CAGlobalCritChance >= 11 and CAGlobalCritChance <= 12) {
                    ; Crit chance can only be the pure crit chance roll
                    NumSuffixes += 1
                    ValueRange := "   8-12    8-12"
                    AffixType := "Suffix"
                } Else If (CAGlobalCritChance >= 14) {
                    ; Crit chance can only be a combination of the complex and pure affixes
                    NumSuffixes += 1
                    ValueRange := "  14-22   14-22"
                    AffixType := "Comp. Suffix"
                }

                AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, AffixType, ValueRange, 1), CAGlobalCritChanceAffixLineNo)
                NextAffixPos += 1
            }
        } Else If (CAGlobalCritChance) {
            ; The item only has a global crit chance affix so it isn't complex
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\jewel\CritChanceGlobal_Jewels.txt", ItemLevel, CAGlobalCritChance, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, "Suffix", ValueRange, CurrTier), CAGlobalCritChanceAffixLineNo)
            NextAffixPos += 1
        } Else {
            ; The item only has an increased accuracy affix so it isn't complex
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\jewel\IncrAccuracyRating_Jewels.txt", ItemLevel, CAIncAccuracy, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, "Suffix", ValueRange, CurrTier), CAIncAccuracyAffixLineNo)
            NextAffixPos += 1
        }
    }

    AffixTotals.NumPrefixes := NumPrefixes
    AffixTotals.NumSuffixes := NumSuffixes
}

;

; Change a detail line that was already processed and added to the
; AffixLines "stack". This can be used for example to change the
; affix type when more is known about a possible affix combo.
;
; For example with a IPD / AR combo, if IPD was thought to be a
; Prefix but later (when processing AR) found to be a Composite
; Prefix.
ChangeAffixDetailLine(PartialAffixString, SearchRegex, ReplaceRegex)
{
    Global AffixLines
    NumAffixLines := AffixLines.MaxIndex()
    Loop, %NumAffixLines%
    {
        CurAffixLine := AffixLines[A_Index]
        IfInString, CurAffixLine, %PartialAffixString%
        {
            NewLine := RegExReplace(CurAffixLine, SearchRegex, ReplaceRegex)
            AffixLines.Set(A_Index, NewLine)
            return True
        }
    }
    return False
}

ExtractValueFromAffixLine(ItemDataChunk, PartialAffixString)
{
    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }

        CurrValue := GetActualValue(A_LoopField)

        IfInString, A_LoopField, %PartialAffixString%
        {
            return CurrValue
        }
    }
}

ResetAffixDetailVars()
{
    Global AffixLines, AffixTotals, Globals
    AffixLines.Reset()
    AffixTotals.Reset()
    Globals.Set("MarkedAsGuess", False)
}

IsEmptyString(String)
{
    If (StrLen(String) == 0)
    {
        return True
    }
    Else
    {
        String := RegExReplace(String, "[\r\n ]", "")
        If (StrLen(String) < 1)
        {
            return True
        }
    }
    return False
}

PreProcessContents(CBContents)
{
    ; --- Place fixes for data inconsistencies here ---

    ; Remove the line that indicates an item cannot be used due to missing character stats
    Needle := "You cannot use this item. Its stats will be ignored`r`n--------`r`n"
    StringReplace, CBContents, CBContents, %Needle%,
    ; Replace double seperator lines with one seperator line
    Needle := "--------`r`n--------`r`n"
    StringReplace, CBContents, CBContents, %Needle%, --------`r`n, All

    return CBContents
}

PostProcessData(ParsedData)
{
    Global Opts

    Result := ParsedData
    If (Opts.CompactAffixTypes > 0)
    {
        StringReplace, TempResult, ParsedData, --------`n, ``, All
        StringSplit, ParsedDataChunks, TempResult, ``

        Result =
        Loop, %ParsedDataChunks0%
        {
            CurrChunk := ParsedDataChunks%A_Index%
            If IsEmptyString(CurrChunk)
            {
                Continue
            }
            If (InStr(CurrChunk, "Comp.") and Not InStr(CurrChunk, "Affixes"))
            {
                CurrChunk := RegExReplace(CurrChunk, "Comp\. ", "C")
            }
            If (InStr(CurrChunk, "Suffix") and Not InStr(CurrChunk, "Affixes"))
            {
                CurrChunk := RegExReplace(CurrChunk, "Suffix", "S")
            }
            If (InStr(CurrChunk, "Prefix") and Not InStr(CurrChunk, "Affixes"))
            {
                CurrChunk := RegExReplace(CurrChunk, "Prefix", "P")
            }
            If (A_Index < ParsedDataChunks0)
            {
                Result := Result . CurrChunk . "--------`r`n"
            }
            Else
            {
                Result := Result . CurrChunk
            }
        }
    }
    return Result
}

ParseClipBoardChanges()
{
    Global Opts, Globals

    CBContents := GetClipboardContents()
    CBContents := PreProcessContents(CBContents)

    Globals.Set("ItemText", CBContents)

    If (GetKeyState("Shift"))
    {
        Globals.Set("TierRelativeToItemLevelOverride", !Opts.TierRelativeToItemLevel)
    }
    Else
    {
        Globals.Set("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel)
    }

    ParsedData := ParseItemData(CBContents)
    ParsedData := PostProcessData(ParsedData)

    If (Opts.PutResultsOnClipboard > 0)
    {
        SetClipboardContents(ParsedData)
    }
    ShowToolTip(ParsedData)
}

AssembleDamageDetails(FullItemData)
{
    Quality := 0
    AttackSpeed := 0
    PhysMult := 0
    PhysLo := 0
    PhysHi := 0
    FireLo := 0
    FireHi := 0
    ColdLo := 0
    ColdHi := 0
    LighLo := 0
    LighHi := 0
    ChaoLo := 0
    ChaoHi := 0

    MainHFireLo := 0
    MainHFireHi := 0
    MainHColdLo := 0
    MainHColdHi := 0
    MainHLighLo := 0
    MainHLighHi := 0
    MainHChaoLo := 0
    MainHChaoHi := 0

    OffHFireLo := 0
    OffHFireHi := 0
    OffHColdLo := 0
    OffHColdHi := 0
    OffHLighLo := 0
    OffHLighHi := 0
    OffHChaoLo := 0
    OffHChaoHi := 0


    Loop, Parse, FullItemData, `n, `r
    {
        ; Get quality
        IfInString, A_LoopField, Quality:
        {
            StringSplit, Arr, A_LoopField, %A_Space%, +`%
            Quality := Arr2
            Continue
        }

        ; Get total physical damage
        IfInString, A_LoopField, Physical Damage:
        {
            StringSplit, Arr, A_LoopField, %A_Space%
            StringSplit, Arr, Arr3, -
            PhysLo := Arr1
            PhysHi := Arr2
            Continue
        }

        ; Get attack speed
        IfInString, A_LoopField, Attacks per Second:
        {
            StringSplit, Arr, A_LoopField, %A_Space%
            AttackSpeed := Arr4
            Continue
        }

        ; Get percentage physical damage increase
        IfInString, A_LoopField, increased Physical Damage
        {
            StringSplit, Arr, A_LoopField, %A_Space%, `%
            PhysMult := Arr1
            Continue
        }

        ; Skip ele/chaos damage to spells being added
        IfInString, A_LoopField, Damage to Spells
            Goto, SkipAddedDamageParse

        ; Parse added damage
        ; Differentiate general mods from main hand and off hand only
        ; Examples for main/off: Dyadus, Wings of Entropy

        IfInString, A_LoopField, in Main Hand
        {
            ParseAddedDamage(A_LoopField, "Fire", MainHFireLo, MainHFireHi)
            ParseAddedDamage(A_LoopField, "Cold", MainHColdLo, MainHColdHi)
            ParseAddedDamage(A_LoopField, "Lightning", MainHLighLo, MainHLighHi)
            ParseAddedDamage(A_LoopField, "Chaos", MainHChaoLo, MainHChaoHi)
        }
        else IfInString, A_LoopField, in Off Hand
        {
            ParseAddedDamage(A_LoopField, "Fire", OffHFireLo, OffHFireHi)
            ParseAddedDamage(A_LoopField, "Cold", OffHColdLo, OffHColdHi)
            ParseAddedDamage(A_LoopField, "Lightning", OffHLighLo, OffHLighHi)
            ParseAddedDamage(A_LoopField, "Chaos", OffHChaoLo, OffHChaoHi)
        }
        else
        {
            ParseAddedDamage(A_LoopField, "Fire", FireLo, FireHi)
            ParseAddedDamage(A_LoopField, "Cold", ColdLo, ColdHi)
            ParseAddedDamage(A_LoopField, "Lightning", LighLo, LighHi)
            ParseAddedDamage(A_LoopField, "Chaos", ChaoLo, ChaoHi)
        }

        SkipAddedDamageParse:
    }

    Result =

    SetFormat, FloatFast, 5.1
    PhysDps := ((PhysLo + PhysHi) / 2) * AttackSpeed
    Result = %Result%`nPhys DPS:   %PhysDps%

    EleDps := ((FireLo + FireHi + ColdLo + ColdHi + LighLo + LighHi) / 2) * AttackSpeed
    MainHEleDps := ((MainHFireLo + MainHFireHi + MainHColdLo + MainHColdHi + MainHLighLo + MainHLighHi) / 2) * AttackSpeed
    OffHEleDps := ((OffHFireLo + OffHFireHi + OffHColdLo + OffHColdHi + OffHLighLo + OffHLighHi) / 2) * AttackSpeed
    ChaosDps := ((ChaoLo + ChaoHi) / 2) * AttackSpeed
    MainHChaosDps := ((MainHChaoLo + MainHChaoHi) / 2) * AttackSpeed
    OffHChaosDps := ((OffHChaoLo + OffHChaoHi) / 2) * AttackSpeed

    If ( MainHEleDps > 0 or OffHEleDps > 0 or MainHChaosDps > 0 or OffHChaosDps > 0 )
    {
        twoColDisplay := true
        TotalMainHEleDps := MainHEleDps + EleDps
        TotalOffHEleDps := OffHEleDps + EleDps
        TotalMainHChaosDps := MainHChaosDps + ChaosDps
        TotalOffHChaosDps := OffHChaosDps + ChaosDps
    }
    else twoColDisplay := false

    If ( MainHEleDps > 0 or OffHEleDps > 0 )
    {
        Result = %Result%`nElem DPS:   %TotalMainHEleDps% MainH | %TotalOffHEleDps% OffH
    }
    else Result = %Result%`nElem DPS:   %EleDps%

    If ( MainHChaosDps > 0 or OffHChaosDps > 0 )
    {
        Result = %Result%`nChaos DPS:  %TotalMainHChaosDps% MainH | %TotalOffHChaosDps% OffH
    }
    else Result = %Result%`nChaos DPS:  %ChaosDps%

    If ( twoColDisplay )
    {
        TotalMainHDps := PhysDps + TotalMainHEleDps + TotalMainHChaosDps
        TotalOffHDps := PhysDps + TotalOffHEleDps + TotalOffHChaosDps
        Result = %Result%`nTotal DPS:  %TotalMainHDps% MainH | %TotalOffHDps% OffH
    }
    else
    {
        TotalDps := PhysDps + EleDps + ChaosDps
        Result = %Result%`nTotal DPS:  %TotalDps%
    }

    ; Only show Q20 values if item is not Q20
    If (Quality < 20) {
        TotalPhysMult := (PhysMult + Quality + 100) / 100
        BasePhysDps := PhysDps / TotalPhysMult
        Q20Dps := BasePhysDps * ((PhysMult + 120) / 100)

        If ( twoColDisplay )
        {
            Q20MainHDps := Q20Dps + TotalMainHEleDps + TotalMainHChaosDps
            Q20OffHDps := Q20Dps + TotalOffHEleDps + TotalOffHChaosDps
            Result = %Result%`nQ20 DPS:    %Q20MainHDps% MainH | %Q20OffHDps% OffH
        }
        else
        {
            Q20Dps := Q20Dps + EleDps + ChaosDps
            Result = %Result%`nQ20 DPS:    %Q20Dps%
        }
    }

    Item.DamageDetails.MainHEleDps := MainHEleDps
    Item.DamageDetails.OffHEleDps := OffHEleDps
    Item.DamageDetails.MainHChaosDps := MainHChaosDps
    Item.DamageDetails.OffHChaosDps := OffHChaosDps
    Item.DamageDetails.TotalMainHDps := TotalMainHDps
    Item.DamageDetails.TotalOffHDps := TotalOffHDps
    Item.DamageDetails.TotalMainHEleDps := TotalMainHEleDps
    Item.DamageDetails.TotalOffHEleDps := TotalOffHEleDps
    Item.DamageDetails.TotalMainHChaosDps := TotalMainHChaosDps
    Item.DamageDetails.TotalOffHChaosDps := TotalOffHChaosDps
    Item.DamageDetails.Q20MainHDps := Q20MainHDps
    Item.DamageDetails.Q20OffHDps := Q20OffHDps
    Item.DamageDetails.BasePhysDps := BasePhysDps
    Item.DamageDetails.TotalPhysMult := TotalPhysMult

    Item.DamageDetails.Q20Dps  := Q20Dps
    Item.DamageDetails.Quality := Quality
    Item.DamageDetails.PhysDps := PhysDps
    Item.DamageDetails.EleDps  := EleDps
    Item.DamageDetails.TotalDps:= TotalDps
    Item.DamageDetails.ChaosDps:= ChaosDps

    return Result
}

; ParseItemName fixed by user: uldo_.  Thanks!
ParseItemName(ItemDataChunk, ByRef ItemName, ByRef ItemTypeName, AffixCount = "")
{
    Loop, Parse, ItemDataChunk, `n, `r
    {
        If (A_Index == 1)
        {
            IfNotInString, A_LoopField, Rarity:
            {
                return
            }
            Else
            {
                Continue
            }
        }

        If (StrLen(A_LoopField) == 0 or A_LoopField == "--------" or A_Index > 3)
        {
            return
        }

        If (A_Index = 2)
        {
            If InStr(A_LoopField, ">>")
            {
                StringGetPos, pos, A_LoopField, >>, R
                ItemName := SubStr(A_LoopField, pos+3)
            }
            Else
            {
                ItemName := A_LoopField
            }
            ; Normal items don't have a third line and the item name equals the typename if we sanitize it ("superior").
            If (RegExMatch(ItemDataChunk, "i)Rarity.*?:.*?Normal"))
            {
                ItemTypeName := Trim(RegExReplace(ItemName, "i)Superior", ""))
            }
            ; Magic items don't have a third line.
            ; Sanitizing the item name is a bit more complicated but should work with the following assumptions:
            ;   1. The suffix always begins with " of".
            ;   2. The prefix consists of only 1 word, never more.
            ; We need to know the AffixCount for this though.
            Else If (AffixCount > 0) {
                If (RegExMatch(ItemDataChunk, "i)Rarity.*?:.*?Magic"))
                {
                    ItemTypeName := Trim(RegExReplace(ItemName, "i) of .*", "", matchCount))
                    If (matchCount and AffixCount > 1)
                    {
                        ; We replaced the suffix and have 2 affixes, therefore we must also have a prefix that we can replace.
                        ItemTypeName := Trim(RegExReplace(ItemTypeName, "iU)^.* ", ""))
                    }
                }
            }
        }

        If (A_Index = 3)
        {
            ItemTypeName := A_LoopField
        }
    }
}

UniqueHasFatedVariant(ItemName)
{
    Loop, Read, %A_ScriptDir%\data\UniqueHasFatedVariant.txt
    {
        Line := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(Line))
        {
            Continue
        }
        IfInString, ItemName, %Line%
        {
            return True
        }
    }
    return False
}

ParseLinks(ItemDataText)
{
    HighestLink := 0
    Loop, Parse, ItemDataText, `n, `r
    {
        IfInString, A_LoopField, Sockets
        {
            LinksString := GetColonValue(A_LoopField)
            If (RegExMatch(LinksString, ".-.-.-.-.-."))
            {
                HighestLink := 6
                Break
            }
            If (RegExMatch(LinksString, ".-.-.-.-."))
            {
                HighestLink := 5
                Break
            }
            If (RegExMatch(LinksString, ".-.-.-."))
            {
                HighestLink := 4
                Break
            }
            If (RegExMatch(LinksString, ".-.-."))
            {
                HighestLink := 3
                Break
            }
            If (RegExMatch(LinksString, ".-."))
            {
                HighestLink := 2
                Break
            }
        }
    }
    return HighestLink
}

ParseSockets(ItemDataText)
{
    SocketsCount := 0
    Loop, Parse, ItemDataText, `n, `r
    {
        IfInString, A_LoopField, Sockets
        {
            LinksString := GetColonValue(A_LoopField)
            before := StrLen(LinksString)
            LinksString := RegExReplace(LinksString, "[RGBW]", "")
            after := StrLen(LinksString)
            SocketsCount := before - after
        }
    }
    return SocketsCount
}

; TODO: find a way to poll this date from the web!

; Converts a currency stack to Chaos by looking up the
; conversion ratio from CurrencyRates.txt
ConvertCurrency(ItemName, ItemStats)
{
    If (InStr(ItemName, "Shard"))
    {
        IsShard := True
        ItemName := "Orb of " . SubStr(ItemName, 1, -StrLen(" Shard"))
    }
    If (InStr(ItemName, "Fragment"))
    {
        IsFragment := True
        ItemName := "Scroll of Wisdom"
    }
    StackSize := SubStr(ItemStats, StrLen("Stack Size:  "))
    StringSplit, StackSizeParts, StackSize, /
    If (IsShard or IsFragment)
    {
        SetFormat, FloatFast, 5.3
        StackSize := StackSizeParts1 / StackSizeParts2
    }
    Else
    {
        SetFormat, FloatFast, 5.2
        StackSize := StackSizeParts1
    }
    ValueInChaos := 0
    Loop, Read, %A_ScriptDir%\data\CurrencyRates.txt
    {
        Line := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(Line))
        {
            Continue
        }
        IfInString, Line, %ItemName%
        {
            StringSplit, LineParts, Line, |
            ChaosRatio := LineParts2
            StringSplit, ChaosRatioParts,ChaosRatio, :
            ChaosMult := ChaosRatioParts2 / ChaosRatioParts1
            ValueInChaos := (ChaosMult * StackSize)
            return ValueInChaos
        }
    }
    return ValueInChaos
}

FindUnique(ItemName)
{
    Loop, Read, %A_ScriptDir%\data\Uniques.txt
    {
        Line := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(Line))
        {
            Continue
        }
        IfInString, Line, %ItemName%
        {
            return True
        }
    }
    return False
}

; Strip comments at line end, e.g. "Bla bla bla ; comment" -> "Bla bla bla"
StripLineCommentRight(Line)
{
    IfNotInString, Line, `;
    {
        return Line
    }
    ProcessedLine := RegExReplace(Line, "(.+?)([ \t]*;.+)", "$1")
    If IsEmptyString(ProcessedLine)
    {
        return Line
    }
    return ProcessedLine
}

; Return True if line begins with comment character (;)
; or if it is blank (that is, it only has 2 characters
; at most (newline and carriage return)
SkipLine(Line)
{
    IfInString, Line, `;
    {
        ; Comment
        return True
    }
    If (StrLen(Line) <= 2)
    {
        ; Blank line (at most \r\n)
        return True
    }
    return False
}

; Parse unique affixes from text file database.
; Has wanted side effect of populating AffixLines "array" vars.
; return True if the unique was found the database
ParseUnique(ItemName)
{
    Global Opts, AffixLines

    Delim := "|"
    ResetAffixDetailVars()
    UniqueFound := False
    Loop, Read, %A_ScriptDir%\data\Uniques.txt
    {
        ALine := StripLineCommentRight(A_LoopReadLine)
        If (SkipLine(ALine))
        {
            Continue
        }
        IfInString, ALine, %ItemName%
        {
            StringSplit, LineParts, ALine, |
            NumLineParts := LineParts0
            NumAffixLines := NumLineParts-1 ; exclude item name at first pos
            UniqueFound := True
            AppendImplicitSep := False
            Idx := 1
            If (Opts.ShowAffixDetails == False)
            {
                return UniqueFound
            }
            Loop, % (NumLineParts)
            {
                If (A_Index > 1)
                {
                    ProcessedLine =
                    CurLinePart := LineParts%A_Index%
                    IfInString, CurLinePart, :
                    {
                        StringSplit, CurLineParts, CurLinePart, :
                        AffixLine := CurLineParts2
                        ValueRange := CurLineParts1
                        IfInString, ValueRange, @
                        {
                            AppendImplicitSep := True
                            StringReplace, ValueRange, ValueRange, @
                        }
                        ; Make "Attacks per Second" float ranges to be like a double range.
                        ; Since a 2 decimal precision float value is 4 chars wide (#.##)
                        ; when including the radix point this means a float value range
                        ; is then 9 chars wide. Replacing the "-" with a "," effectively
                        ; makes it so that float ranges are treated as double ranges and
                        ; distributes the bounds over both value range fields. This may
                        ; or may not be desirable. On the plus side things will align
                        ; nicely, but on the negative side, it will be a bit unclearer that
                        ; both float values constitute a range and not two isolated values.
                        ;ValueRange := RegExReplace(ValueRange, "(\d+\.\d+)-(\d+\.\d+)", "$1,$2") ; DISABLED for now
                        IfInString, ValueRange, `,
                        {
                            ; Double range
                            StringSplit, VRParts, ValueRange, `,
                            LowerBound := VRParts1
                            UpperBound := VRParts2
                            StringSplit, LowerBoundParts, LowerBound, -
                            StringSplit, UpperBoundParts, UpperBound, -
                            LBMin := LowerBoundParts1
                            LBMax := LowerBoundParts2
                            UBMin := UpperBoundParts1
                            UBMax := UpperBoundParts2
                            If (Opts.CompactDoubleRanges)
                            {
                                ValueRange := StrPad(LBMin . "-" . UBMax, Opts.ValueRangeFieldWidth, "left")
                            }
                            Else
                            {
                                ValueRange := StrPad(LowerBound, Opts.ValueRangeFieldWidth, "left") . Opts.AffixDetailDelimiter . StrPad(UpperBound, Opts.ValueRangeFieldWidth, "left")
                            }
                        }
                        ProcessedLine := AffixLine . Delim . StrPad(ValueRange, Opts.ValueRangeFieldWidth, "left")
                        If (AppendImplicitSep)
                        {
                            ProcessedLine := ProcessedLine . "`n" . "--------"
                            AppendImplicitSep := False
                        }
                        AffixLines.Set(Idx, ProcessedLine)
                    }
                    Else
                    {
                        AffixLines.Set(Idx, CurLinePart)
                    }
                    Idx += 1
                }
            }
            return UniqueFound
        }
    }
    return UniqueFound
}

ItemIsMirrored(ItemDataText)
{
    Loop, Parse, ItemDataText, `n, `r
    {
        RegExMatch(Trim(A_LoopField), "i)^Mirrored$", match)
        If (match) {
            return True
        }
    }
    return False
}

; ########### MAIN PARSE FUNCTION ##############

; Invocation stack (simplified) for full item parse:
;
;   (timer watches clipboard contents)
;   (on clipboard changed) ->
;
;   ParseClipBoardChanges()
;       PreProcessContents()
;       ParseItemData()
;           (get item details by calling many other Parse... functions)
;           ParseAffixes()
;               (on affix match found) ->
;                   LookupAffixData()
;                       AssembleValueRangeFields()
;                   LookupAffixBracket()
;                   LookupRemainingAffixBracket()
;                   AppendAffixInfo(MakeAffixDetailLine()) ; appends to global AffixLines table
;           (is Weapon) ->
;               AssembleDamageDetails()
;           AssembleAffixDetails() ; uses global AffixLines table
;       PostProcessData()
;       ShowToolTip()
;
ParseItemData(ItemDataText, ByRef RarityLevel="")
{
    Global Item, ItemData, AffixTotals, uniqueMapList, mapList, matchList, divinationCardList, gemQualityList

    ItemDataPartsIndexLast =
    ItemDataPartsIndexAffixes =
    ItemDataPartsLast =
    ItemDataNamePlate =
    ItemDataStats =
    ItemDataAffixes =
    ItemDataRequirements =
    ItemDataRarity =
    ItemDataLinks =
    ItemName =
    ItemTypeName =
    ItemQuality =
    ItemLevel =
    ItemMaxSockets =
    ItemBaseType =
    ItemSubType =
    ItemGripType =
    BaseLevel =
    RarityLevel =
    TempResult =

    Item.DamageDetails := {}
    Item.IsWeapon := False
    Item.IsArmour := False
    Item.IsQuiver := False
    Item.IsFlask := False
    Item.IsGem := False
    Item.IsCurrency := False
    Item.IsUnidentified := False
    Item.IsBelt := False
    Item.IsRing := False
    Item.IsUnsetRing := False
    Item.IsBow := False
    Item.IsAmulet := False
    Item.IsSingleSocket := False
    Item.IsFourSocket := False
    Item.IsThreeSocket := False
    Item.IsMap := False
    Item.IsTalisman := False
    Item.IsJewel := False
    Item.IsDivinationCard := False
    Item.IsUnique := False
    Item.IsRare := False
    Item.IsCorrupted := False
    Item.IsMirrored := False
    Item.HasEffect := False
    Item.HasImplicit := False
    Item.IsMapFragment := False
    Item.IsEssence := False

    ResetAffixDetailVars()

    ItemData.FullText := ItemDataText

    Loop, Parse, ItemDataText, `n, `r
    {
        RegExMatch(Trim(A_LoopField), "i)^Corrupted$", match)
        If (match) {
            Item.IsCorrupted := True
        }
    }

    ; AHK only allows splitting on single chars, so first
    ; replace the split string (\r\n--------\r\n) with AHK's escape char (`)
    ; then do the actual string splitting...
    StringReplace, TempResult, ItemDataText, `r`n--------`r`n, ``, All
    StringSplit, ItemDataParts, TempResult, ``,

    ItemData.NamePlate := ItemDataParts1
    ItemData.Stats := ItemDataParts2

    ItemDataIndexLast := ItemDataParts0
    ItemDataPartsLast := ItemDataParts%ItemDataIndexLast%

    ItemData.ClearParts()
    Loop, %ItemDataParts0%
    {
        ItemData.Parts[A_Index] := ItemDataParts%A_Index%
    }
    ItemData.PartsLast := ItemDataPartsLast
    ItemData.IndexLast := ItemDataIndexLast

    ; ItemData.Requirements := GetItemDataChunk(ItemDataText, "Requirements:")
    ; ParseRequirements(ItemData.Requirements, RequiredLevel, RequiredAttributes, RequiredAttributeValues)

    ParseItemName(ItemData.NamePlate, ItemName, ItemTypeName)
    If (Not ItemName)
    {
        return
    }
    Item.Name := ItemName
    Item.TypeName := ItemTypeName

    IfInString, ItemDataText, Unidentified
    {
        If (Item.Name != "Scroll of Wisdom")
        {
            Item.IsUnidentified := True
        }
    }

    Item.Quality := ParseQuality(ItemData.Stats)

    ; This function should return the second part of the "Rarity: ..." line
    ; in the case of "Rarity: Unique" it should return "Unique"
    ItemData.Rarity := ParseRarity(ItemData.NamePlate)

    ItemData.Links := ParseLinks(ItemDataText)
    ItemData.Sockets := ParseSockets(ItemDataText)

    Item.IsUnique := False
    If (InStr(ItemData.Rarity, "Unique"))
    {
        Item.IsUnique := True
    }

    If (InStr(ItemData.Rarity, "Rare"))
    {
        Item.IsRare := True
    }

    ; Divination Card detection = Normal rarity with stack size (100% valid??)
    If (InStr(ItemData.Rarity, "Divination Card") and InStr(ItemDataText, "Stack Size:"))
    {
        Item.IsDivinationCard := True
        Item.BaseType := "Divination Card"
    }

    Item.IsGem := (InStr(ItemData.Rarity, "Gem"))
    Item.IsCurrency := (InStr(ItemData.Rarity, "Currency"))

    If (Not (InStr(ItemDataText, "Itemlevel:") or InStr(ItemDataText, "Item Level:")) and Not Item.IsGem and Not Item.IsCurrency and Not Item.IsDivinationCard)
    {
        return Item.Name
    }

    If (Item.IsGem)
    {
        RarityLevel := 0
        Item.Level := ParseGemLevel(ItemDataText, "Level:")
        ItemLevelWord := "Gem Level:"
        Item.BaseType := "Jewelry"
    }
    Else
    {

        If (Item.IsCurrency and Opts.ShowCurrencyValueInChaos == 1)
        {
            ValueInChaos := ConvertCurrency(Item.Name, ItemData.Stats)
            If (ValueInChaos)
            {
                CurrencyDetails := ValueInChaos . " Chaos"
            }
        }
        ; Don't do this on Divination Cards or this script crashes on trying to do the ParseItemLevel
        Else If (Not Item.IsCurrency and Not Item.IsDivinationCard)
        {
            If (RegExMatch(Item.Name, "i)^Sacrifice At") or RegExMatch(Item.Name, "i)^Fragment of") or RegExMatch(Item.Name, "i)^Mortal ") or RegExMatch(Item.Name, "i)^Offering to ") or RegExMatch(Item.Name, "i)'s Key$"))
            {
                Item.IsMapFragment := True
            }

            RarityLevel := CheckRarityLevel(ItemData.Rarity)
            Item.Level := ParseItemLevel(ItemDataText)
            ItemLevelWord := "Item Level:"
            ParseItemType(ItemData.Stats, ItemData.NamePlate, ItemBaseType, ItemSubType, ItemGripType, Item.IsMapFragment, RarityLevel)
            Item.BaseType := ItemBaseType
            Item.SubType := ItemSubType
            Item.GripType := ItemGripType
        }
    }

    Item.RarityLevel := RarityLevel

    Item.IsBow := (Item.SubType == "Bow")
    Item.IsFlask := (Item.SubType == "Flask")
    Item.IsBelt := (Item.SubType == "Belt")
    Item.IsRing := (Item.SubType == "Ring")
    Item.IsUnsetRing := (Item.IsRing and InStr(ItemData.NamePlate, "Unset Ring"))
    Item.IsAmulet := (Item.SubType == "Amulet")
    Item.IsTalisman := (Item.IsAmulet and InStr(ItemData.NamePlate, "Talisman") and !InStr(ItemData.NamePlate, "Amulet"))
    Item.IsSingleSocket := (IsUnsetRing)
    Item.IsFourSocket := (Item.SubType == "Gloves" or Item.SubType == "Boots" or Item.SubType == "Helmet")
    Item.IsThreeSocket := ((Item.GripType == "1H" or Item.SubType == "Shield") and Not Item.IsBow)
    Item.IsQuiver := (Item.SubType == "Quiver")
    Item.IsWeapon := (Item.BaseType == "Weapon")
    Item.IsArmour := (Item.BaseType == "Armour")
    Item.IsMap := (Item.BaseType == "Map")
    Item.IsJewel := (Item.BaseType == "Jewel")
    Item.IsMirrored := (ItemIsMirrored(ItemDataText) and Not Item.IsCurrency)
    Item.IsEssence := Item.IsCurrency and RegExMatch(Item.Name, "i)Essence of |Remnant of Corruption")
    Item.Note := Globals.Get("ItemNote")

    TempStr := ItemData.PartsLast
    Loop, Parse, TempStr, `n, `r
    {
        RegExMatch(Trim(A_LoopField), "i)^Has ", match)
        If (match) {
            Item.HasEffect := True
        }
    }

    If Item.IsTalisman {
        Loop, Read, %A_ScriptDir%\data\TalismanTiers.txt
        {
            ; This loop retrieves each line from the file, one at a time.
            StringSplit, TalismanData, A_LoopReadLine, |,
            If InStr(ItemData.NamePlate, TalismanData1) {
                Item.TalismanTier := TalismanData2
            }
        }
    }

    ItemDataIndexAffixes := ItemData.IndexLast - GetNegativeAffixOffset(Item)
    If (ItemDataIndexAffixes <= 0)
    {
        ; ItemDataParts doesn't have the parts/text we need. Bail.
        ; This might be because the clipboard is completely empty.
        return
    }
    ItemData.Affixes := ItemDataParts%ItemDataIndexAffixes%
    ItemData.IndexAffixes := ItemDataIndexAffixes

    ; Retrieve items implicit mod if it has one
    If (Item.IsWeapon or Item.IsArmour or Item.IsRing or Item.IsBelt or Item.IsAmulet) {
        ; Magic and higher rarity
        If (RarityLevel > 1) {
            ItemDataIndexImplicit := ItemData.IndexLast - GetNegativeAffixOffset(Item) - 1
        }
        ; Normal rarity
        Else {
            ItemDataIndexImplicit := ItemData.IndexLast - GetNegativeAffixOffset(Item)
        }
        ; Check that there is no ":" in the retrieved text = can only be an implicit mod
        If (!InStr(ItemDataParts%ItemDataIndexImplicit%, ":")) {
            Item.Implicit := ItemDataParts%ItemDataIndexImplicit%
            Item.hasImplicit := True
        }
    }

    ItemData.Stats := ItemDataParts2

    If (Item.IsFlask)
    {
        ParseFlaskAffixes(ItemData.Affixes)
    }
    Else If (RarityLevel > 1 and RarityLevel < 4 and Item.IsMap = False)  ; Code added by Bahnzo to avoid maps showing affixes
    {
        ParseAffixes(ItemData.Affixes, Item)
    }
    NumPrefixes := AffixTotals.NumPrefixes
    NumSuffixes := AffixTotals.NumSuffixes
    TotalAffixes := NumPrefixes + NumSuffixes
    AffixTotals.NumTotals := TotalAffixes

    ; We need to call this function a second time because now we know the AffixCount.
    ParseItemName(ItemData.NamePlate, ItemName, ItemTypeName, TotalAffixes)
    Item.TypeName := ItemTypeName

    ; Start assembling the text for the tooltip
    TT := Item.Name
    If (Item.TypeName && (Item.TypeName != Item.Name))
    {
        TT := TT . "`n" . Item.TypeName
    }

    If (Item.IsCurrency)
    {
        TT := TT . "`n" . CurrencyDetails
        Goto, ParseItemDataEnd
    }

    If (Opts.ShowItemLevel == 1 and Not (Item.IsMap or Item.IsCurrency or Item.IsDivinationCard))
    {
        TT := TT . "`n"
        TT := TT . ItemLevelWord . "   " . StrPad(Item.Level, 3, Side="left")

        If Item.IsTalisman {
            TT := TT . "`nTalisman Tier: " . StrPad(Item.TalismanTier, 2, Side="left")
        }
        If (Not Item.IsFlask)
        {
            ;;Item.BaseLevel := CheckBaseLevel(Item.TypeName)

            ;;Hixxie: fixed! Shows base level for any item rarity, rings/jewelry, etc
            If(Item.RarityLevel < 3)
            {
                Item.BaseLevel := CheckBaseLevel(Item.Name)
            }
            else if (Item.IsUnidentified)
            {
                Item.BaseLevel := CheckBaseLevel(Item.Name)
            }
            Else
            {
                Item.BaseLevel := CheckBaseLevel(Item.TypeName)
            }

            If (Item.BaseLevel)
            {
                TT := TT . "`n" . "Base Level:   " . StrPad(Item.BaseLevel, 3, Side="left")
            }
        }
    }

    If (Opts.ShowMaxSockets == 1 and (Item.IsWeapon or Item.IsArmour))
    {
        If (Item.Level >= 50)
        {
            Item.MaxSockets := 6
        }
        Else If (Item.Level >= 35)
        {
            Item.MaxSockets := 5
        }
        Else If (Item.Level >= 25)
        {
            Item.MaxSockets := 4
        }
        Else If (Item.Level >= 1)
        {
            Item.MaxSockets := 3
        }
        Else
        {
            Item.MaxSockets := 2
        }

        If(Item.IsFourSocket and Item.MaxSockets > 4)
        {
            Item.MaxSockets := 4
        }
        Else If(Item.IsThreeSocket and Item.MaxSockets > 3)
        {
            Item.MaxSockets := 3
        }
        Else If(Item.IsSingleSocket)
        {
            Item.MaxSockets := 1
        }

        If (Not Item.IsRing or Item.IsUnsetRing)
        {
            TT := TT . "`n"
            TT := TT . "Max Sockets:    "
            TT := TT . Item.MaxSockets
        }
    }

    If (Opts.ShowDamageCalculations == 1 and Item.IsWeapon)
    {
        TT := TT . AssembleDamageDetails(ItemDataText)
    }

    If (Item.IsDivinationCard)
    {
        If (divinationCardList[Item.Name] != "")
        {
            CardDescription := divinationCardList[Item.Name]
        }
        Else
        {
            CardDescription := divinationCardList["Unknown Card"]
        }

        TT := TT . "`n--------`n" . CardDescription
    }

    If (Item.IsMap)
    {
        /*
        Item.MapLevel := ParseMapLevel(ItemDataText)

        ;;hixxie fixed
        MapLevelText := Item.MapLevel
        TT = %TT%`nMap Level: %MapLevelText%
        */

        If (Item.IsUnique)
        {
            MapDescription := uniqueMapList[Item.SubType]
        }
        Else
        {
            MapDescription := mapList[Item.SubType]
        }

        TT = %TT%`n%MapDescription%
    }

    If (Item.IsGem)
    {
        If (gemQualityList[Item.Name] != "")
        {
            GemQualityDescription := gemQualityList[Item.Name]
        }
        Else
        {
            GemQualityDescription := gemQualityList["Unknown Gem"]
        }

        TT := TT . "`nQuality 20%:`n" . GemQualityDescription
    }

    If (Item.hasImplicit and not Item.IsUnique) {
        Implicit := Item.Implicit
        TT = %TT%`n--------`n%Implicit%
    }

    If (RarityLevel > 1 and RarityLevel < 4)
    {
        ; Append affix info if rarity is greater than normal (white)
        ; Affix total statistic
        If (Opts.ShowAffixTotals = 1)
        {
            If (NumPrefixes = 1)
            {
                WordPrefixes = Prefix
            }
            Else
            {
                WordPrefixes = Prefixes
            }
            If (NumSuffixes = 1)
            {
                WordSuffixes = Suffix
            }
            Else
            {
                WordSuffixes = Suffixes
            }

            PrefixLine =
            If (NumPrefixes > 0)
            {
                PrefixLine = `n   %NumPrefixes% %WordPrefixes%
            }

            SuffixLine =
            If (NumSuffixes > 0)
            {
                SuffixLine = `n   %NumSuffixes% %WordSuffixes%
            }

            AffixStats =
            If (TotalAffixes > 0 and Not Item.IsUnidentified)
            {
                AffixStats = Affixes (%TotalAffixes%):%PrefixLine%%SuffixLine%
                TT = %TT%`n--------`n%AffixStats%
            }
        }

        ; Detailed affix range infos
        If (Opts.ShowAffixDetails == 1)
        {
            If (Not Item.IsFlask and Not Item.IsUnidentified and Not Item.IsMap)
            {
                AffixDetails := AssembleAffixDetails()
                TT = %TT%`n--------%AffixDetails%
           }
        }
    }
    Else If (ItemData.Rarity == "Unique")
    {
        If (FindUnique(Item.Name) == False and Not Item.IsUnidentified)
        {
            TT = %TT%`n--------`nUnique item currently not supported
        }
        Else If (Opts.ShowAffixDetails == True and Not Item.IsUnidentified)
        {
            ParseUnique(Item.Name)
            AffixDetails := AssembleAffixDetails()
            TT = %TT%`n--------%AffixDetails%
        }
    }

    If (Item.IsUnidentified and (Item.Name != "Scroll of Wisdom") and Not Item.IsMap)
    {
        TT = %TT%`n--------`nUnidentified
    }

    If (UniqueHasFatedVariant(Item.Name))
    {
        TT = %TT%`n--------`nHas Fated Variant
    }

    If (Item.IsMirrored)
    {
        TT = %TT%`n--------`nMirrored
    }

    If (Opts.ShowDarkShrineInfo == 1 and (RarityLevel == 3 or RarityLevel == 2))
    {
        TT = %TT%`n--------`nPossible DarkShrine effects:

        DarkShrineInfo := AssembleDarkShrineInfo()
        TT = %TT%%DarkShrineInfo%
    }

    return TT

    ParseItemDataEnd:
        return TT
}

GetNegativeAffixOffset(Item)
{
    NegativeAffixOffset := 0
    If (Item.IsFlask or Item.IsUnique or Item.IsTalisman)
    {
        ; Uniques as well as flasks have descriptive text as last item,
        ; so decrement item index to get to the item before last one
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.IsMap)
    {
        ; Maps have a descriptive text as the last item
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.IsJewel)
    {
        ; Jewels, like maps and flask, have a descriptive text as the last item
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.HasEffect)
    {
        ; Same with weapon skins or other effects
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.IsCorrupted)
    {
        ; And corrupted items
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    If (Item.IsMirrored)
    {
        ; And mirrored items
        NegativeAffixOffset := NegativeAffixOffset + 1
    }
    return NegativeAffixOffset
}

; Don't use! Not working correctly yet!
ExtractRareItemTypeName(ItemName)
{
    ItemTypeName := RegExReplace(ItemName, "(.+?) (.+) of (.+)", "$2")
    return ItemTypeName
}

; Show tooltip, with fixed width font
ShowToolTip(String, Centered = true)
{
    Global X, Y, ToolTipTimeout, Opts

    ; Get position of mouse cursor
    MouseGetPos, X, Y

    If (Not Opts.DisplayToolTipAtFixedCoords)
    {
        If (Centered) 
        {
            ScreenOffsetY := A_ScreenHeight / 2
            ScreenOffsetX := A_ScreenWidth / 2

            XCoord := 0 + ScreenOffsetX
            YCoord := 0 + ScreenOffsetY

            ToolTip, %String%, XCoord, YCoord
            Fonts.SetFixedFont()
            ToolTip, %String%, XCoord, YCoord
        }
        Else 
        {
            ToolTip, %String%, X - 135, Y + 35
            Fonts.SetFixedFont()
            ToolTip, %String%, X - 135, Y + 35
        }
    }
    Else
    {
        CoordMode, ToolTip, Screen
        ;~ GetScreenInfo()
        ;~ TotalScreenWidth := Globals.Get("TotalScreenWidth", 0)
        ;~ HalfWidth := Round(TotalScreenWidth / 2)

        ;~ SecondMonitorTopLeftX := HalfWidth
        ;~ SecondMonitorTopLeftY := 0
        ScreenOffsetY := Opts.ScreenOffsetY
        ScreenOffsetX := Opts.ScreenOffsetX

        XCoord := 0 + ScreenOffsetX
        YCoord := 0 + ScreenOffsetY

        ToolTip, %String%, XCoord, YCoord
        Fonts.SetFixedFont()
        ToolTip, %String%, XCoord, YCoord
    }
    ;Fonts.SetFixedFont()

    ; Set up count variable and start timer for tooltip timeout
    ToolTipTimeout := 0
    SetTimer, ToolTipTimer, 100
}

; ############## TESTS #################

Globals.Set("TestCaseSeparator", "####################")

RunRareTestSuite(Path, SuiteNumber)
{
    Global AffixTotals

    NumTestCases := 0
    Loop, Read, %Path%
    {
        IfInString, A_LoopReadLine, % Globals.TestCaseSeparator
        {
            NumTestCases += 1
            Continue
        }
        TestCaseText := A_LoopReadLine
        TestCases%NumTestCases% := TestCases%NumTestCases% . TestCaseText . "`r`n"
    }

    Failures := 0
    Successes := 0
    FailureNumbers =
    TestCase =
    Loop, %NumTestCases%
    {
        TestCase := TestCases%A_Index%

        RarityLevel := 0
        TestCaseResult := ParseItemData(TestCase, RarityLevel)
        NumPrefixes := AffixTotals.NumPrefixes
        NumSuffixes := AffixTotals.NumSuffixes

        StringReplace, TempResult, TestCaseResult, --------, ``, All
        StringSplit, TestCaseResultParts, TempResult, ``

        NameAndDPSPart := TestCaseResultParts1
        TotalAffixStatsPart := TestCaseResultParts2
        AffixCompositionPart := TestCaseResultParts3

        ; failure conditions
        TotalAffixes := 0
        TotalAffixes := NumPrefixes + NumSuffixes
        InvalidTotalAffixNumber := (TotalAffixes > 6)
        BracketLookupFailed := InStr(TestCaseResult, "n/a")
        CompositeRangeCalcFailed := InStr(TestCaseResult, " - ")

        Prefixes := 0
        Suffixes := 0
        CompPrefixes := 0
        CompSuffixes := 0
        ExtractTotalAffixBalance(AffixCompositionPart, Prefixes, Suffixes, CompPrefixes, CompSuffixes)

        HasDanglingComposites := False
        If (Mod(CompPrefixes, 2)) ; True, if not evenly divisible by 2
        {
            HasDanglingComposites := True
        }
        If (Mod(CompSuffixes, 2))
        {
            HasDanglingComposites := True
        }

        TotalCountByAffixTypes := (Floor(CompPrefixes / 2) + Floor(CompSuffixes / 2) + Prefixes + Suffixes)

        AffixTypesCountedIncorrectly := (Not (TotalCountByAffixTypes == TotalAffixes))
        If (InvalidTotalAffixNumber or BracketLookupFailed or CompositeRangeCalcFailed or HasDanglingComposites or AffixTypesCountedIncorrectly)
        {
            Failures += 1
            FailureNumbers := FailureNumbers . A_Index . ","
        }
        Else
        {
            Successes += 1
        }
        ; needed so global variables can be yanked from memory and reset between calls
        ; (if you reload the script really fast globals vars that are out of date can
        ; cause failures when there are none)
        Sleep, 1
    }

    Result := "Suite " . SuiteNumber . ": " . StrPad(Successes, 5, "left") . " OK" . ", " . StrPad(Failures, 5, "left")  . " Failed"
    If (Failures > 0)
    {
        FailureNumbers := SubStr(FailureNumbers, 1, -1)
        Result := Result . " (" . FailureNumbers . ")"
    }
    return Result
}

RunUniqueTestSuite(Path, SuiteNumber)
{
    Global AffixTotals

    NumTestCases := 0
    Loop, Read, %Path%
    {
        IfInString, A_LoopReadLine, % Globals.TestCaseSeparator
        {
            NumTestCases += 1
            Continue
        }
        TestCaseText := A_LoopReadLine
        TestCases%NumTestCases% := TestCases%NumTestCases% . TestCaseText . "`r`n"
    }

    Failures := 0
    Successes := 0
    FailureNumbers =
    TestCase =
    Loop, %NumTestCases%
    {
        TestCase := TestCases%A_Index%
        TestCaseResult := ParseItemData(TestCase)

        FailedToSepImplicit := InStr(TestCaseResult, "@")  ; failed to properly seperate implicit from normal affixes
        ; TODO: add more unique item test failure conditions

        If (FailedToSepImplicit)
        {
            Failures += 1
            FailureNumbers := FailureNumbers . A_Index . ","
        }
        Else
        {
            Successes += 1
        }
        ; needed so global variables can be yanked from memory and reset between calls
        ; (if you reload the script really fast globals vars that are out of date can
        ; cause failures where there are none)
        Sleep, 1
    }

    Result := "Suite " . SuiteNumber . ": " . StrPad(Successes, 5, "left") . " OK" . ", " . StrPad(Failures, 5, "left")  . " Failed"
    If (Failures > 0)
    {
        FailureNumbers := SubStr(FailureNumbers, 1, -1)
        Result := Result . " (" . FailureNumbers . ")"
    }
    return Result
}

RunAllTests()
{
    ; change this to the number of available test suites
    TestDataBasePath = %A_ScriptDir%\extras\tests

    NumRareTestSuites := 5
    RareResults := "Rare Items"
    Loop, %NumRareTestSuites%
    {
        If (A_Index > 0) ; change condition to only run certain tests
        {
            TestSuitePath = %TestDataBasePath%\Rares%A_Index%.txt
            TestSuiteResult := RunRareTestSuite(TestSuitePath, A_Index)
            RareResults := RareResults . "`n    " . TestSuiteResult
        }
    }

    NumUniqueTestSuites := 1
    UniqResults := "Unique Items"
    Loop, %NumUniqueTestSuites%
    {
        If (A_Index > 0) ; change condition to only run certain tests
        {
            TestSuitePath = %TestDataBasePath%\Uniques%A_Index%.txt
            TestSuiteResult := RunUniqueTestSuite(TestSuitePath, A_Index)
            UniqResults := UniqResults . "`n    " . TestSuiteResult
        }
    }

    MsgBox, %RareResults%`n`n%UniqResults%
}

; ########### TESTS ############

If (RunTests)
{
    RunAllTests()
}

; ############ GUI #############

GuiSet(ControlID, Param3="", SubCmd="")
{
    If (!(SubCmd == "")) {
        GuiControl, %SubCmd%, %ControlID%, %Param3%
    } Else {
        GuiControl,, %ControlID%, %Param3%
    }
}

GuiGet(ControlID, DefaultValue="")
{
    curVal =
    GuiControlGet, curVal,, %ControlID%, %DefaultValue%
    return curVal
}

GuiAdd(ControlType, Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Param4="", GuiName="")
{
    Global
    Local av, ah, al
    av := StrPrefix(AssocVar, "v")
    al := StrPrefix(AssocLabel, "g")
    ah := StrPrefix(AssocHwnd, "hwnd")
    GuiName := (StrLen(GuiName) > 0) ? Trim(GuiName) . ":Add" : "Add"
    Gui, %GuiName%, %ControlType%, %PositionInfo% %av% %al% %ah% %Param4%, %Contents%
}

GuiAddButton(Contents, PositionInfo, AssocLabel="", AssocVar="", AssocHwnd="", Options="", GuiName="")
{
    GuiAdd("Button", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddGroupBox(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
    GuiAdd("GroupBox", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddCheckbox(Contents, PositionInfo, CheckedState=0, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
    GuiAdd("Checkbox", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, "Checked" . CheckedState . " " . Options, GuiName)
}

GuiAddText(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
    ; static controls like Text need "0x0100" added to their options for the tooltip to work
    ; either add it always here or don't forget to add it manually when using this function
    GuiAdd("Text", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddEdit(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
    GuiAdd("Edit", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddDropDownList(Contents, PositionInfo, Selected="", AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
    ; usage : add list items as a | delimited string, for example = "item1|item2|item3"
    ListItems := StrSplit(Contents, "|")
    Contents := ""
    Loop % ListItems.MaxIndex() {
        Contents .= Trim(ListItems[A_Index]) . "|"
        ; add second | to mark pre-select list item
        if (Trim(ListItems[A_Index]) == Selected) {
            Contents .= "|"
        }
    }
    GuiAdd("DropDownList", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

AddToolTip(con, text, Modify=0){
    Static TThwnd, GuiHwnd
    TInfo =
    UInt := "UInt"
    Ptr := (A_PtrSize ? "Ptr" : UInt)
    PtrSize := (A_PtrSize ? A_PtrSize : 4)
    Str := "Str"
    ; defines from Windows MFC commctrl.h
    WM_USER := 0x400
    TTM_ADDTOOL := (A_IsUnicode ? WM_USER+50 : WM_USER+4)           ; used to add a tool, and assign it to a control
    TTM_UPDATETIPTEXT := (A_IsUnicode ? WM_USER+57 : WM_USER+12)    ; used to adjust the text of a tip
    TTM_SETMAXTIPWIDTH := WM_USER+24                                ; allows the use of multiline tooltips
    TTF_IDISHWND := 1
    TTF_CENTERTIP := 2
    TTF_RTLREADING := 4
    TTF_SUBCLASS := 16
    TTF_TRACK := 0x0020
    TTF_ABSOLUTE := 0x0080
    TTF_TRANSPARENT := 0x0100
    TTF_PARSELINKS := 0x1000
    If (!TThwnd) {
        Gui, +LastFound
        GuiHwnd := WinExist()
        TThwnd := DllCall("CreateWindowEx"
                    ,UInt,0
                    ,Str,"tooltips_class32"
                    ,UInt,0
                    ,UInt,2147483648
                    ,UInt,-2147483648
                    ,UInt,-2147483648
                    ,UInt,-2147483648
                    ,UInt,-2147483648
                    ,UInt,GuiHwnd
                    ,UInt,0
                    ,UInt,0
                    ,UInt,0)
    }
    ; TOOLINFO structure
    cbSize := 6*4+6*PtrSize
    uFlags := TTF_IDISHWND|TTF_SUBCLASS|TTF_PARSELINKS
    VarSetCapacity(TInfo, cbSize, 0)
    NumPut(cbSize, TInfo)
    NumPut(uFlags, TInfo, 4)
    NumPut(GuiHwnd, TInfo, 8)
    NumPut(con, TInfo, 8+PtrSize)
    NumPut(&text, TInfo, 6*4+3*PtrSize)
    NumPut(0,TInfo, 6*4+6*PtrSize)
    DetectHiddenWindows, On
    If (!Modify) {
        DllCall("SendMessage"
            ,Ptr,TThwnd
            ,UInt,TTM_ADDTOOL
            ,Ptr,0
            ,Ptr,&TInfo
            ,Ptr)
        DllCall("SendMessage"
            ,Ptr,TThwnd
            ,UInt,TTM_SETMAXTIPWIDTH
            ,Ptr,0
            ,Ptr,A_ScreenWidth)
    }
    DllCall("SendMessage"
        ,Ptr,TThwnd
        ,UInt,TTM_UPDATETIPTEXT
        ,Ptr,0
        ,Ptr,&TInfo
        ,Ptr)

}

GetScreenInfo()
{
    SysGet, TotalScreenWidth, 78
    SysGet, TotalscreenHeight, 79
    SysGet, MonitorCount, 80

    Globals.Set("MonitorCount", MonitorCount)
    Globals.Set("TotalScreenWidth", TotalScreenWidth)
    Globals.Set("TotalScreenHeight", TotalscreenHeight)
}

; ######### UNHANDLED CASE DIALOG ############

ShowUnhandledCaseDialog()
{
    Global Msg, Globals
    Static UnhDlg_EditItemText

    Gui, 3:New,, Unhandled Case
    Gui, 3:Color, FFFFFF
    Gui, 3:Add, Picture, x25 y25 w36 h36, %A_ScriptDir%\data\info.png
    Gui, 3:Add, Text, x65 y31 w500 h100, % Msg.Unhandled
    Gui, 3:Add, Edit, x65 y96 w400 h120 ReadOnly vUnhDlg_EditItemText, % Globals.Get("ItemText", "Error: could'nt get item text (system clipboard modified?). Please try again or report the item manually.")
    Gui, 3:Add, Text, x-5 y230 w500 h50 -Background
    Gui, 3:Add, Button, x195 y245 w100 h25 gUnhandledDlg_ShowItemText, Show In Notepad
    Gui, 3:Add, Button, x300 y245 w90 h25 gVisitForumsThread, Forums Thread
    Gui, 3:Add, Button, x395 y245 w86 h25 gUnhandledDlg_OK Default, OK
    Gui, 3:Show, Center w490 h280,
    Gui, Font, s10, Courier New
    Gui, Font, s9, Consolas
    GuiControl, Font, UnhDlg_EditItemText
    return
}

; ######### SETTINGS ############

; (Internal: RegExr x-forms)
; GroupBox
;   Gui, Add, GroupBox, (.+?) , (.+) -> ; $2 \n\n    GuiAddGroupBox("$2", "$1")
; Checkbox (with label)
;   Gui, Add, (.+?), (.+?) hwnd(.+?) v(.+?) g(.+?) Checked%(.+)%, (.+) -> GuiAdd$1("$7", "$2", Opts.$6, "$4", "$3", "$5")
; Checkbox /w/o label)
;   Gui, Add, (.+?), (.+?) hwnd(.+?) v(.+?) Checked%(.+)%, (.+) -> GuiAdd$1("$6", "$2", Opts.$5, "$4", "$3")
; Edit
;   Gui, Add, Edit, (.+?) hwnd(.+?) v(.+?), %(.+)% -> GuiAddEdit(Opts.$4, "$1", "$3", "", "$2")
; Text
;   Gui, Add, Text, (.+?) hwnd(.+?) v(.+?), (.+) -> GuiAddText("$4", "$1", "$3", "", "$2")
; Button
;   Gui, Add, Button, (.+?) g(.+?), (.+) -> GuiAddButton("$3", "$1", "", "$2", "")

CreateSettingsUI()
{
    Global
    ; General

    GuiAddGroupBox("General", "x7 y15 w260 h90")

    ; Note: window handles (hwnd) are only needed if a UI tooltip should be attached.

    GuiAddCheckbox("Only show tooltip if PoE is frontmost", "x17 y35 w210 h30", Opts.OnlyActiveIfPOEIsFront, "OnlyActiveIfPOEIsFront", "OnlyActiveIfPOEIsFrontH")
    AddToolTip(OnlyActiveIfPOEIsFrontH, "If checked the script does nothing if the`nPath of Exile window isn't the frontmost")
    GuiAddCheckbox("Put tooltip results on clipboard", "x17 y65 w210 h30", Opts.PutResultsOnClipboard, "PutResultsOnClipboard", "PutResultsOnClipboardH")
    AddToolTip(PutResultsOnClipboardH, "Put tooltip result text onto the system clipboard`n(overwriting the item info text PoE put there to begin with)")

    ; Display

    GuiAddGroupBox("Display", "x7 y115 w260 h150")

    GuiAddCheckbox("Show item level (gear)", "x17 y135 w240 h30", Opts.ShowItemLevel, "ShowItemLevel")
    GuiAddCheckbox("Show max sockets based on item lvl (gear)", "x17 y165 w240 h30", Opts.ShowMaxSockets, "ShowMaxSockets", "ShowMaxSocketsH")
    AddToolTip(ShowMaxSocketsH, "Show maximum amount of sockets the item can have`nbased on its item level")
    GuiAddCheckbox("Show damage calculations (weapons)", "x17 y195 w240 h30", Opts.ShowDamageCalculations, "ShowDamageCalculations")
    GuiAddCheckbox("Show currency value in chaos", "x17 y225 w240 h30", Opts.ShowCurrencyValueInChaos, "ShowCurrencyValueInChaos")

    ; Tooltip

    GuiAddGroupBox("Tooltip", "x7 y275 w260 h185")

    GuiAddCheckBox("Use tooltip timeout", "x17 y290 w210 h30", Opts.UseTooltipTimeout, "UseTooltipTimeout", "UseTooltipTimeoutH", "SettingsUI_ChkUseTooltipTimeout")
    AddToolTip(UseTooltipTimeoutH, "Hide tooltip automatically after x amount of ticks have passed")
        GuiAddText("Timeout ticks (1 tick = 100ms):", "x27 y322 w150 h20", "LblToolTipTimeoutTicks")
        GuiAddEdit(Opts.ToolTipTimeoutTicks, "x187 y320 w50 h20", "ToolTipTimeoutTicks")

    GuiAddCheckbox("Display at fixed coordinates", "x17 y340 w230 h30", Opts.DisplayToolTipAtFixedCoords, "DisplayToolTipAtFixedCoords", "DisplayToolTipAtFixedCoordsH", "SettingsUI_ChkDisplayToolTipAtFixedCoords")
    AddToolTip(DisplayToolTipAtFixedCoordsH, "Show tooltip in virtual screen space at the fixed`ncoordinates given below. Virtual screen space means`nthe full desktop frame, including any secondary`nmonitors. Coords are relative to the top left edge`nand increase going down and to the right.")
        GuiAddText("X:", "x37 y372 w20 h20", "LblScreenOffsetX")
        GuiAddEdit(Opts.ScreenOffsetX, "x55 y370 w40 h20", "ScreenOffsetX")
        GuiAddText("Y:", "x105 y372 w20 h20", "LblScreenOffsetY")
        GuiAddEdit(Opts.ScreenOffsetY, "x125 y370 w40 h20", "ScreenOffsetY")

    GuiAddText("Mousemove threshold (px):", "x17 y402 w160 h20 0x0100", "LblMouseMoveThreshold", "LblMouseMoveThresholdH")
    AddToolTip(LblMouseMoveThresholdH, "Hide tooltip automatically after the mouse has moved x amount of pixels")
    GuiAddEdit(Opts.MouseMoveThreshold, "x187 y400 w50 h20", "MouseMoveThreshold", "MouseMoveThresholdH")

    GuiAddText("Font Size:", "x17 y432 w160 h20", "LblFontSize")
    GuiAddEdit(Opts.FontSize, "x187 y430 w50 h20", "FontSize")

    ; Display - Affixes

    GuiAddGroupBox("Display - Affixes", "x277 y15 w260 h360")

    GuiAddCheckbox("Show affix totals", "x287 y35 w210 h30", Opts.ShowAffixTotals, "ShowAffixTotals", "ShowAffixTotalsH")
    AddToolTip(ShowAffixTotalsH, "Show a statistic how many prefixes and suffixes`nthe item has")
    GuiAddCheckbox("Show affix details", "x287 y65 w210 h30", Opts.ShowAffixDetails, "ShowAffixDetails", "ShowAffixDetailsH", "SettingsUI_ChkShowAffixDetails")
    AddToolTip(ShowAffixDetailsH, "Show detailed affix breakdown. Note that crafted mods are not`nsupported and some ranges are guesstimated (marked with a *)")
        GuiAddCheckbox("Mirror affix lines", "x307 y95 w190 h30", Opts.MirrorAffixLines, "MirrorAffixLines", "MirrorAffixLinesH")
        AddToolTip(MirrorAffixLinesH, "Display truncated affix names within the breakdown")
    GuiAddCheckbox("Show affix level", "x287 y125 w210 h30", Opts.ShowAffixLevel, "ShowAffixLevel", "ShowAffixLevelH")
        AddToolTip(ShowAffixLevelH, "Show item level of the displayed affix value bracket")
    GuiAddCheckbox("Show affix bracket", "x287 y155 w210 h30", Opts.ShowAffixBracket, "ShowAffixBracket", "ShowAffixBracketH")
        AddToolTip(ShowAffixBracketH, "Show affix value bracket as is on the item")
    GuiAddCheckbox("Show affix max possible", "x287 y185 w210 h30", Opts.ShowAffixMaxPossible, "ShowAffixMaxPossible", "ShowAffixMaxPossibleH", "SettingsUI_ChkShowAffixMaxPossible")
        AddToolTip(ShowAffixMaxPossibleH, "Show max possible affix value bracket")
        GuiAddCheckbox("Max span starting from first", "x307 y215 w190 h30", Opts.MaxSpanStartingFromFirst, "MaxSpanStartingFromFirst", "MaxSpanStartingFromFirstH")
        AddToolTip(MaxSpanStartingFromFirstH, "Construct a pseudo range by combining the lowest possible`naffix value bracket with the max possible based on item level")
    GuiAddCheckbox("Show affix bracket tier", "x287 y245 w210 h30", Opts.ShowAffixBracketTier, "ShowAffixBracketTier", "ShowAffixBracketTierH", "SettingsUI_ChkShowAffixBracketTier")
        AddToolTip(ShowAffixBracketTierH, "Display affix bracket tier in reverse ordering,`nT1 being the best possible roll.")
        GuiAddCheckbox("Tier relative to item lvl", "x307 y275 w190 h20", Opts.TierRelativeToItemLevel, "TierRelativeToItemLevel", "TierRelativeToItemLevelH")
        GuiAddText("(hold Shift to toggle temporarily)", "x330 y295 w190 h20", "LblTierRelativeToItemLevelOverrideNote")
        AddToolTip(TierRelativeToItemLevelH, "When showing affix bracket tier, make T1 being best possible`ntaking item level into account.")
        GuiAddCheckbox("Show affix bracket tier total", "x307 y315 w190 h20", Opts.ShowAffixBracketTierTotal, "ShowAffixBracketTierTotal", "ShowAffixBracketTierTotalH")
        AddToolTip(ShowAffixBracketTierTotalH, "Show number of total affix bracket tiers in format T/N,`n where T = tier on item, N = number of total tiers available")
    GuiAddCheckbox("Show Darkshrine information", "x287 y345 w210 h20", Opts.ShowDarkShrineInfo, "ShowDarkShrineInfo", "ShowDarkShrineInfoH")
    AddToolTip(ShowDarkShrineInfoH, "Show information about possible Darkshrine effects")

    ; Display - Results

    GuiAddGroupBox("Display - Results", "x277 y385 w260 h185")

    GuiAddCheckbox("Compact double ranges", "x287 y400  w210 h30", Opts.CompactDoubleRanges, "CompactDoubleRanges", "CompactDoubleRangesH")
    AddToolTip(CompactDoubleRangesH, "Show double ranges as one range,`ne.g. x-y (to) z-w becomes x-w")
    GuiAddCheckbox("Compact affix types", "x287 y430 w210 h30", Opts.CompactAffixTypes, "CompactAffixTypes", "CompactAffixTypesH")
    AddToolTip(CompactAffixTypesH, "Replace affix type with a short-hand version,`ne.g. P=Prefix, S=Suffix, CP=Composite")

    GuiAddText("Mirror line field width:", "x287 y467 w110 h20", "LblMirrorLineFieldWidth")
    GuiAddEdit(Opts.MirrorLineFieldWidth, "x407 y465 w40 h20", "MirrorLineFieldWidth")
    GuiAddText("Value range field width:", "x287 y492 w120 h20", "LblValueRangeFieldWidth")
    GuiAddEdit(Opts.ValueRangeFieldWidth, "x407 y490 w40 h20", "ValueRangeFieldWidth")
    GuiAddText("Affix detail delimiter:", "x287 y517 w120 h20", "LblAffixDetailDelimiter")
    GuiAddEdit(Opts.AffixDetailDelimiter, "x407 y515 w40 h20", "AffixDetailDelimiter")
    GuiAddText("Affix detail ellipsis:", "x287 y542 w120 h20", "LblAffixDetailEllipsis")
    GuiAddEdit(Opts.AffixDetailEllipsis, "x407 y540 w40 h20", "AffixDetailEllipsis")



    GuiAddText("Mouse over settings or see the beginning of the PoE-Item-Info.ahk script for comments on what these settings do exactly.", "x277 y585 w250 h60")

    GuiAddButton("&Defaults", "x287 y640 w80 h23", "SettingsUI_BtnDefaults")
    GuiAddButton("&OK", "Default x372 y640 w75 h23", "SettingsUI_BtnOK")
    GuiAddButton("&Cancel", "x452 y640 w80 h23", "SettingsUI_BtnCancel")
}

UpdateSettingsUI()
{
    Global

    GuiControl,, OnlyActiveIfPOEIsFront, % Opts.OnlyActiveIfPOEIsFront
    GuiControl,, PutResultsOnClipboard, % Opts.PutResultsOnClipboard
    GuiControl,, ShowItemLevel, % Opts.ShowItemLevel
    GuiControl,, ShowMaxSockets, % Opts.ShowMaxSockets
    GuiControl,, ShowDamageCalculations, % Opts.ShowDamageCalculations
    GuiControl,, ShowCurrencyValueInChaos, % Opts.ShowCurrencyValueInChaos
    GuiControl,, DisplayToolTipAtFixedCoords, % Opts.DisplayToolTipAtFixedCoords
    If (Opts.DisplayToolTipAtFixedCoords == False)
    {
        GuiControl, Disable, LblScreenOffsetX
        GuiControl, Disable, ScreenOffsetX
        GuiControl, Disable, LblScreenOffsetY
        GuiControl, Disable, ScreenOffsetY
    }
    Else
    {
        GuiControl, Enable, LblScreenOffsetX
        GuiControl, Enable, ScreenOffsetX
        GuiControl, Enable, LblScreenOffsetY
        GuiControl, Enable, ScreenOffsetY
    }
    ;~ GetScreenInfo()
    ;~ If (Globals.Get("MonitorCount", 1) > 1)
    ;~ {
        ;~ GuiControl,, DisplayToolTipAtFixedCoords, % Opts.DisplayToolTipAtFixedCoords
        ;~ GuiControl,, ScreenOffsetX, % Opts.ScreenOffsetX
        ;~ GuiControl,, ScreenOffsetY, % Opts.ScreenOffsetY
        ;~ GuiControl, Enable, DisplayToolTipAtFixedCoords
        ;~ GuiControl, Enable, LblScreenOffsetX
        ;~ GuiControl, Enable, ScreenOffsetX
        ;~ GuiControl, Enable, LblScreenOffsetY
        ;~ GuiControl, Enable, ScreenOffsetY
    ;~ }
    ;~ Else
    ;~ {
        ;~ GuiControl,, DisplayToolTipAtFixedCoords, 0
        ;~ GuiControl,, ScreenOffsetX, 0
        ;~ GuiControl,, ScreenOffsetY, 0
        ;~ GuiControl, Disable, DisplayToolTipAtFixedCoords
        ;~ GuiControl, Disable, LblScreenOffsetX
        ;~ GuiControl, Disable, ScreenOffsetX
        ;~ GuiControl, Disable, LblScreenOffsetY
        ;~ GuiControl, Disable, ScreenOffsetY
    ;~ }

    GuiControl,, ShowAffixTotals, % Opts.ShowAffixTotals
    GuiControl,, ShowAffixDetails, % Opts.ShowAffixDetails
    If (Opts.ShowAffixDetails == False)
    {
        GuiControl, Disable, MirrorAffixLines
    }
    Else
    {
        GuiControl, Enable, MirrorAffixLines
    }
    GuiControl,, MirrorAffixLines, % Opts.MirrorAffixLines
    GuiControl,, ShowAffixLevel, % Opts.ShowAffixLevel
    GuiControl,, ShowAffixBracket, % Opts.ShowAffixBracket
    GuiControl,, ShowAffixMaxPossible, % Opts.ShowAffixMaxPossible
    If (Opts.ShowAffixMaxPossible == False)
    {
        GuiControl, Disable, MaxSpanStartingFromFirst
    }
    Else
    {
        GuiControl, Enable, MaxSpanStartingFromFirst
    }
    GuiControl,, MaxSpanStartingFromFirst, % Opts.MaxSpanStartingFromFirst
    GuiControl,, ShowAffixBracketTier, % Opts.ShowAffixBracketTier
    GuiControl,, ShowAffixBracketTierTotal, % Opts.ShowAffixBracketTierTotal
    If (Opts.ShowAffixBracketTier == False)
    {
        GuiControl, Disable, TierRelativeToItemLevel
        GuiControl, Disable, ShowAffixBracketTierTotal
    }
    Else
    {
        GuiControl, Enable, TierRelativeToItemLevel
        GuiControl, Enable, ShowAffixBracketTierTotal
    }
    GuiControl,, TierRelativeToItemLevel, % Opts.TierRelativeToItemLevel
    GuiControl,, ShowDarkShrineInfo, % Opts.ShowDarkShrineInfo

    GuiControl,, CompactDoubleRanges, % Opts.CompactDoubleRanges
    GuiControl,, CompactAffixTypes, % Opts.CompactAffixTypes
    GuiControl,, MirrorLineFieldWidth, % Opts.MirrorLineFieldWidth
    GuiControl,, ValueRangeFieldWidth, % Opts.ValueRangeFieldWidth
    GuiControl,, AffixDetailDelimiter, % Opts.AffixDetailDelimiter
    GuiControl,, AffixDetailEllipsis, % Opts.AffixDetailEllipsis

    GuiControl,, UseTooltipTimeout, % Opts.UseTooltipTimeout
    If (Opts.UseTooltipTimeout == False)
    {
        GuiControl, Disable, LblToolTipTimeoutTicks
        GuiControl, Disable, ToolTipTimeoutTicks
    }
    Else
    {
        GuiControl, Enable, LblToolTipTimeoutTicks
        GuiControl, Enable, ToolTipTimeoutTicks
    }
    GuiControl,, ToolTipTimeoutTicks, % Opts.ToolTipTimeoutTicks
    GuiControl,, MouseMoveThreshold, % Opts.MouseMoveThreshold
    GuiControl,, FontSize, % Opts.FontSize
}

ShowSettingsUI()
{
    ; remove POE-Item-Info tooltip if still visible
    SetTimer, ToolTipTimer, Off
    ToolTip
    Fonts.SetUIFont(9)
    SettingsUIWidth := Globals.Get("SettingsUIWidth", 545)
    SettingsUIHeight := Globals.Get("SettingsUIHeight", 710)
    SettingsUITitle := Globals.Get("SettingsUITitle", "PoE Item Info Settings")
    Gui, Show, w%SettingsUIWidth% h%SettingsUIHeight%, %SettingsUITitle%
}

IniRead(ConfigPath, Section_, Key, Default_)
{
    Result := ""
    IniRead, Result, %ConfigPath%, %Section_%, %Key%, %Default_%
    return Result
}

IniWrite(Val, ConfigPath, Section_, Key)
{
    IniWrite, %Val%, %ConfigPath%, %Section_%, %Key%
}

ReadConfig(ConfigPath="config.ini")
{
    Global
    IfExist, %ConfigPath%
    {
        ; General

        Opts.OnlyActiveIfPOEIsFront := IniRead(ConfigPath, "General", "OnlyActiveIfPOEIsFront", Opts.OnlyActiveIfPOEIsFront)
        Opts.PutResultsOnClipboard := IniRead(ConfigPath, "General", "PutResultsOnClipboard", Opts.PutResultsOnClipboard)

        ; Display

        Opts.ShowItemLevel := IniRead(ConfigPath, "Display", "ShowItemLevel", Opts.ShowItemLevel)
        Opts.ShowMaxSockets := IniRead(ConfigPath, "Display", "ShowMaxSockets", Opts.ShowMaxSockets)
        Opts.ShowDamageCalculations := IniRead(ConfigPath, "Display", "ShowDamageCalculations", Opts.ShowDamageCalculations)
        Opts.ShowCurrencyValueInChaos := IniRead(ConfigPath, "Display", "ShowCurrencyValueInChaos", Opts.ShowCurrencyValueInChaos)

        ; Display - Affixes

        Opts.ShowAffixTotals := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixTotals", Opts.ShowAffixTotals)
        Opts.ShowAffixDetails := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixDetails", Opts.ShowAffixDetails)
        Opts.MirrorAffixLines := IniRead(ConfigPath, "DisplayAffixes", "MirrorAffixLines", Opts.MirrorAffixLines)
        Opts.ShowAffixLevel := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixLevel", Opts.ShowAffixLevel)
        Opts.ShowAffixBracket := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixBracket", Opts.ShowAffixBracket)
        Opts.ShowAffixMaxPossible := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixMaxPossible", Opts.ShowAffixMaxPossible)
        Opts.MaxSpanStartingFromFirst := IniRead(ConfigPath, "DisplayAffixes", "MaxSpanStartingFromFirst", Opts.MaxSpanStartingFromFirst)
        Opts.ShowAffixBracketTier := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixBracketTier", Opts.ShowAffixBracketTier)
        Opts.TierRelativeToItemLevel := IniRead(ConfigPath, "DisplayAffixes", "TierRelativeToItemLevel", Opts.TierRelativeToItemLevel)
        Opts.ShowAffixBracketTierTotal := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixBracketTierTotal", Opts.ShowAffixBracketTierTotal)
        Opts.ShowDarkShrineInfo := IniRead(ConfigPath, "DisplayAffixes", "ShowDarkShrineInfo", Opts.ShowDarkShrineInfo)

        ; Display - Results

        Opts.CompactDoubleRanges := IniRead(ConfigPath, "DisplayResults", "CompactDoubleRanges", Opts.CompactDoubleRanges)
        Opts.CompactAffixTypes := IniRead(ConfigPath, "DisplayResults", "CompactAffixTypes", Opts.CompactAffixTypes)
        Opts.MirrorLineFieldWidth := IniRead(ConfigPath, "DisplayResults", "MirrorLineFieldWidth", Opts.MirrorLineFieldWidth)
        Opts.ValueRangeFieldWidth := IniRead(ConfigPath, "DisplayResults", "ValueRangeFieldWidth", Opts.ValueRangeFieldWidth)
        Opts.AffixDetailDelimiter := IniRead(ConfigPath, "DisplayResults", "AffixDetailDelimiter", Opts.AffixDetailDelimiter)
        Opts.AffixDetailEllipsis := IniRead(ConfigPath, "DisplayResults", "AffixDetailEllipsis", Opts.AffixDetailEllipsis)

        ; Tooltip

        Opts.MouseMoveThreshold := IniRead(ConfigPath, "Tooltip", "MouseMoveThreshold", Opts.MouseMoveThreshold)
        Opts.UseTooltipTimeout := IniRead(ConfigPath, "Tooltip", "UseTooltipTimeout", Opts.UseTooltipTimeout)
        Opts.DisplayToolTipAtFixedCoords := IniRead(ConfigPath, "Tooltip", "DisplayToolTipAtFixedCoords", Opts.DisplayToolTipAtFixedCoords)
        Opts.ScreenOffsetX := IniRead(ConfigPath, "Tooltip", "ScreenOffsetX", Opts.ScreenOffsetX)
        Opts.ScreenOffsetY := IniRead(ConfigPath, "Tooltip", "ScreenOffsetY", Opts.ScreenOffsetY)
        Opts.ToolTipTimeoutTicks := IniRead(ConfigPath, "Tooltip", "ToolTipTimeoutTicks", Opts.ToolTipTimeoutTicks)
        Opts.FontSize := IniRead(ConfigPath, "Tooltip", "FontSize", Opts.FontSize)
    }
}

WriteConfig(ConfigPath="config.ini")
{
    Global
    Opts.ScanUI()

    ; General

    IniWrite(Opts.OnlyActiveIfPOEIsFront, ConfigPath, "General", "OnlyActiveIfPOEIsFront")
    IniWrite(Opts.PutResultsOnClipboard, ConfigPath, "General", "PutResultsOnClipboard")

    ; Display

    IniWrite(Opts.ShowItemLevel, ConfigPath, "Display", "ShowItemLevel")
    IniWrite(Opts.ShowMaxSockets, ConfigPath, "Display", "ShowMaxSockets")
    IniWrite(Opts.ShowDamageCalculations, ConfigPath, "Display", "ShowDamageCalculations")
    IniWrite(Opts.ShowCurrencyValueInChaos, ConfigPath, "Display", "ShowCurrencyValueInChaos")

    ; Display - Affixes

    IniWrite(Opts.ShowAffixTotals, ConfigPath, "DisplayAffixes", "ShowAffixTotals")
    IniWrite(Opts.ShowAffixDetails, ConfigPath, "DisplayAffixes", "ShowAffixDetails")
    IniWrite(Opts.MirrorAffixLines, ConfigPath, "DisplayAffixes", "MirrorAffixLines")
    IniWrite(Opts.ShowAffixLevel, ConfigPath, "DisplayAffixes", "ShowAffixLevel")
    IniWrite(Opts.ShowAffixBracket, ConfigPath, "DisplayAffixes", "ShowAffixBracket")
    IniWrite(Opts.ShowAffixMaxPossible, ConfigPath, "DisplayAffixes", "ShowAffixMaxPossible")
    IniWrite(Opts.MaxSpanStartingFromFirst, ConfigPath, "DisplayAffixes", "MaxSpanStartingFromFirst")
    IniWrite(Opts.ShowAffixBracketTier, ConfigPath, "DisplayAffixes", "ShowAffixBracketTier")
    IniWrite(Opts.TierRelativeToItemLevel, ConfigPath, "DisplayAffixes", "TierRelativeToItemLevel")
    IniWrite(Opts.ShowAffixBracketTierTotal, ConfigPath, "DisplayAffixes", "ShowAffixBracketTierTotal")
    IniWrite(Opts.ShowDarkShrineInfo, ConfigPath, "DisplayAffixes", "ShowDarkShrineInfo")

    ; Display - Results

    IniWrite(Opts.CompactDoubleRanges, ConfigPath, "DisplayResults", "CompactDoubleRanges")
    IniWrite(Opts.CompactAffixTypes, ConfigPath, "DisplayResults", "CompactAffixTypes")
    IniWrite(Opts.MirrorLineFieldWidth, ConfigPath, "DisplayResults", "MirrorLineFieldWidth")
    IniWrite(Opts.ValueRangeFieldWidth, ConfigPath, "DisplayResults", "ValueRangeFieldWidth")
    If IsEmptyString(Opts.AffixDetailDelimiter)
    {
        IniWrite("""" . Opts.AffixDetailDelimiter . """", ConfigPath, "DisplayResults", "AffixDetailDelimiter")
    }
    Else
    {
        IniWrite(Opts.AffixDetailDelimiter, ConfigPath, "DisplayResults", "AffixDetailDelimiter")
    }
    IniWrite(Opts.AffixDetailEllipsis, ConfigPath, "DisplayResults", "AffixDetailEllipsis")

    ; Tooltip

    IniWrite(Opts.MouseMoveThreshold, ConfigPath, "Tooltip", "MouseMoveThreshold")
    IniWrite(Opts.UseTooltipTimeout, ConfigPath, "Tooltip", "UseTooltipTimeout")
    IniWrite(Opts.DisplayToolTipAtFixedCoords, ConfigPath, "Tooltip", "DisplayToolTipAtFixedCoords")
    IniWrite(Opts.ScreenOffsetX, ConfigPath, "Tooltip", "ScreenOffsetX")
    IniWrite(Opts.ScreenOffsetY, ConfigPath, "Tooltip", "ScreenOffsetY")
    IniWrite(Opts.ToolTipTimeoutTicks, ConfigPath, "Tooltip", "ToolTipTimeoutTicks")
    IniWrite(Opts.FontSize, ConfigPath, "Tooltip", "FontSize")
}

CopyDefaultConfig()
{
    FileCopy, %A_ScriptDir%\data\defaults.ini, %A_ScriptDir%
    FileMove, %A_ScriptDir%\defaults.ini, %A_ScriptDir%\config.ini
}

RemoveConfig()
{
    FileDelete, %A_ScriptDir%\config.ini
}

CreateDefaultConfig()
{
    WriteConfig(A_ScriptDir . "\data\defaults.ini")
}

GetContributors(AuthorsPerLine=0)
{
    IfNotExist, %A_ScriptDir%\AUTHORS.txt
    {
        return "`r`n AUTHORS.txt missing `r`n"
    }
    Authors := "`r`n"
    i := 0
    Loop, Read, %A_ScriptDir%\AUTHORS.txt, `r, `n
    {
        Authors := Authors . A_LoopReadLine . " "
        i += 1
        if (AuthorsPerLine != 0 and mod(i, AuthorsPerLine) == 0) ; every four authors
        {
            Authors := Authors . "`r`n"
        }
    }
    return Authors
}

; ########### TIMERS ############

; Tick every 100 ms
; Remove tooltip if mouse is moved or 5 seconds pass
ToolTipTimer:
    Global Opts, ToolTipTimeout
    ToolTipTimeout += 1
    MouseGetPos, CurrX, CurrY
    MouseMoved := (CurrX - X) ** 2 + (CurrY - Y) ** 2 > Opts.MouseMoveThreshold ** 2
    If (MouseMoved or ((UseTooltipTimeout == 1) and (ToolTipTimeout >= Opts.ToolTipTimeoutTicks)))
    {
        SetTimer, ToolTipTimer, Off
        ToolTip
    }
    return

OnClipBoardChange:
    Global Opts
    if SuspendPOEItemScript = 0
    {
        If (Opts.OnlyActiveIfPOEIsFront)
        {
            ; do nothing if Path of Exile isn't the foremost window
            IfWinActive, Path of Exile ahk_class Direct3DWindowClass
            {
                ParseClipBoardChanges()
            }
        }
        Else
        {
            ; if running tests parse clipboard regardless if PoE is foremost
            ; so we can check individual cases from test case text files
            ParseClipBoardChanges()
        }
    }
    return

ShowSettingsUI:
    ReadConfig()
    Sleep, 50
    UpdateSettingsUI()
    Sleep, 50
    ShowSettingsUI()
    return

SettingsUI_BtnOK:
    Global Opts
    Gui, Submit
    Sleep, 50
    WriteConfig()
    UpdateSettingsUI()
    Fonts.SetFixedFont(GuiGet("FontSize", Opts.FontSize))
    return

SettingsUI_BtnCancel:
    Gui, Cancel
    return

SettingsUI_BtnDefaults:
    Gui, Cancel
    RemoveConfig()
    Sleep, 75
    CopyDefaultConfig()
    Sleep, 75
    ReadConfig()
    Sleep, 75
    UpdateSettingsUI()
    ShowSettingsUI()
    return

SettingsUI_ChkShowGemEvaluation:
    GuiControlGet, IsChecked,, ShowGemEvaluation
    If (Not IsChecked)
    {
        GuiControl, Disable, LblGemQualityThreshold
        GuiControl, Disable, GemQualityValueThreshold
    }
    Else
    {
        GuiControl, Enable, LblGemQualityThreshold
        GuiControl, Enable, GemQualityValueThreshold
    }
    return

SettingsUI_ChkShowAffixDetails:
    GuiControlGet, IsChecked,, ShowAffixDetails
    If (Not IsChecked)
    {
        GuiControl, Disable, MirrorAffixLines
    }
    Else
    {
        GuiControl, Enable, MirrorAffixLines
    }
    return

SettingsUI_ChkShowAffixMaxPossible:
    GuiControlGet, IsChecked,, ShowAffixMaxPossible
    If (Not IsChecked)
    {
        GuiControl, Disable, MaxSpanStartingFromFirst
    }
    Else
    {
        GuiControl, Enable, MaxSpanStartingFromFirst
    }
    return

SettingsUI_ChkShowAffixBracketTier:
    GuiControlGet, IsChecked,, ShowAffixBracketTier
    If (Not IsChecked)
    {
        GuiControl, Disable, TierRelativeToItemLevel
        GuiControl, Disable, ShowAffixBracketTierTotal
    }
    Else
    {
        GuiControl, Enable, TierRelativeToItemLevel
        GuiControl, Enable, ShowAffixBracketTierTotal
    }
    return

SettingsUI_ChkUseTooltipTimeout:
    GuiControlGet, IsChecked,, UseTooltipTimeout
    If (Not IsChecked)
    {
        GuiControl, Disable, LblToolTipTimeoutTicks
        GuiControl, Disable, ToolTipTimeoutTicks
    }
    Else
    {
        GuiControl, Enable, LblToolTipTimeoutTicks
        GuiControl, Enable, ToolTipTimeoutTicks
    }
    return

SettingsUI_ChkDisplayToolTipAtFixedCoords:
    GuiControlGet, IsChecked,, DisplayToolTipAtFixedCoords
    If (Not IsChecked)
    {
        GuiControl, Disable, LblScreenOffsetX
        GuiControl, Disable, ScreenOffsetX
        GuiControl, Disable, LblScreenOffsetY
        GuiControl, Disable, ScreenOffsetY
    }
    Else
    {
        GuiControl, Enable, LblScreenOffsetX
        GuiControl, Enable, ScreenOffsetX
        GuiControl, Enable, LblScreenOffsetY
        GuiControl, Enable, ScreenOffsetY
    }
    return

MenuTray_About:
    IfNotEqual, FirstTimeA, No
    {
        Authors := GetContributors(0)
        RelVer := Globals.get("ReleaseVersion")
        Gui, 2:+owner1 -Caption +Border
        Gui, 2:Font, S10 CA03410,verdana
        Gui, 2:Add, Text, x260 y27 w170 h20 Center, Release %RelVer%
        Gui, 2:Add, Button, 0x8000 x316 y300 w70 h21, Close
        Gui, 2:Add, Picture, 0x1000 x17 y16 w230 h180 gAboutDlg_Fishing, %A_ScriptDir%\data\splash.png
        Gui, 2:Font, Underline C3571AC,verdana
        Gui, 2:Add, Text, x260 y57 w170 h20 gVisitForumsThread Center, PoE forums thread
        Gui, 2:Add, Text, x260 y87 w170 h20 gAboutDlg_AhkHome Center, AutoHotkey homepage
        Gui, 2:Add, Text, x260 y117 w170 h20 gAboutDlg_GitHub Center, PoE-Item-Info GitHub
        Gui, 2:Font, S7 CDefault normal, Verdana
        Gui, 2:Add, Text, x16 y207 w410 h80,
        (LTrim
        Shows affix breakdowns and other useful infos for any item or item link.

        Usage: Set PoE to Windowed Fullscreen mode and hover over any item or item link. Press Ctrl+C to show a tooltip.

        (c) %A_YYYY% Hazydoc, Nipper4369 and contributors:
        )
        Gui, 2:Add, Text, x16 y277 w270 h80, %Authors%

        FirstTimeA = No
    }

    Gui, 2:Show, h340 w435, About..

    ; Release counter animation
    tmpH = 0
    Loop, 20
    {
        tmpH += 1
        ControlMove, Static1,,,, %tmpH%, About..
        Sleep, 100
    }
    return

AboutDlg_Fishing:
    ; See, GGG Chris, I have your best interests at heart. Hire me! :)
    MsgBox, 32, Did You Know?, Fishing is reel!
    return

AboutDlg_AhkHome:
    Run, https://autohotkey.com/
    return

AboutDlg_GitHub:
    Run, https://github.com/aRTy42/POE-ItemInfo
    return

VisitForumsThread:
    Run, https://www.pathofexile.com/forum/view-thread/1678678
    return

2ButtonClose:
2GuiClose:
    WinGet, AbtWndID, ID, About..
    DllCall("AnimateWindow", "Int", AbtWndID, "Int", 500, "Int", 0x00090010)
    WinActivate, ahk_id %MainWndID%
    return

EditAdditionalMacros:
    OpenMainDirFile("AdditionalMacros.txt")
    return

EditCurrencyRates:
    OpenCreateDataTextFile("CurrencyRates.txt")
    return

3GuiClose:
    Gui, 3:Cancel
    return

UnhandledDlg_ShowItemText:
    Run, Notepad.exe
    WinActivate
    Send, ^v
    return

UnhandledDlg_OK:
    Gui, 3:Submit
    return

TogglePOEItemScript()
{
    if SuspendPOEItemScript = 0
    {
        SuspendPOEItemScript = 1
        ToolTip, POE ItemInfo Script is PAUSED!
    }
    else
    {
        SuspendPOEItemScript = 0
        ToolTip
    }

}

; ############ ADD YOUR OWN MACROS HERE #############
#IfWinActive Path of Exile ahk_class Direct3DWindowClass ahk_group PoEexe

Pause::TogglePOEItemScript()

#Include %A_ScriptDir%/AdditionalMacros.txt