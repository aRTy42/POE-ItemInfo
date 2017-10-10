﻿; Path of Exile ItemInfo
;
; Script is currently maintained by various people and kept up to date by aRTy42 / IGN: Erinyen
; Forum thread: https://www.pathofexile.com/forum/view-thread/1678678
; GitHub: https://github.com/aRTy42/POE-ItemInfo

#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background
SetWorkingDir, %A_ScriptDir%
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.

;Define exe names for the regular and steam version, for later use at the very end of the script. This needs to be done early, in the "auto-execute section".
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExileSteam.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64Steam.exe

#Include, %A_ScriptDir%\resources\Version.txt
#Include, %A_ScriptDir%\lib\JSON.ahk
#Include, %A_ScriptDir%\lib\DebugPrintArray.ahk


#Include %A_ScriptDir%\resources\Messages.txt
IfNotExist, %A_ScriptDir%\temp
FileCreateDir, %A_ScriptDir%\temp

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
Globals.Set("AboutWindowHeight", 340)
Globals.Set("AboutWindowWidth", 435)
Globals.Set("SettingsUITitle", "PoE Item Info Settings")
Globals.Set("GithubRepo", "POE-ItemInfo")
Globals.Set("GithubUser", "aRTy42")
Globals.Set("ScriptList", [A_ScriptDir "\POE-ItemInfo"])
Globals.Set("UpdateNoteFileList", [[A_ScriptDir "\resources\updates.txt","ItemInfo"]])
argumentProjectName		= %1%
argumentUserDirectory	= %2%
argumentIsDevVersion	= %3%
argumentOverwrittenFiles = %4%
Globals.Set("ProjectName", argumentProjectName)
; make sure not to overwrite these variables if set from another script
global userDirectory		:= userDirectory ? userDirectory : argumentUserDirectory
global isDevVersion			:= isDevVersion  ? isDevVersion  : argumentIsDevVersion
global overwrittenUserFiles	:= overwrittenUserFiles ? overwrittenUserFiles : argumentOverwrittenFiles

global SuspendPOEItemScript = 0

class UserOptions {
	OnlyActiveIfPOEIsFront := 1     ; Set to 1 to make it so the script does nothing if Path of Exile window isn't the frontmost.
									; If 0, the script also works if PoE isn't frontmost. This is handy for have the script parse
									; textual item representations appearing somewhere Else, like in the forums or text files.

	PutResultsOnClipboard := 0      ; Put result text on clipboard (overwriting the textual representation the game put there to begin with)
	ShowUpdateNotifications := 1
	UpdateSkipSelection := 0
	UpdateSkipBackup := 0

	EnableAdditionalMacros := 1		; Enable/disable the entire AdditionalMacros.txt file

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

	ShowAffixBracketTierTotal := 0  ; Appends the total number of tiers for a given affix in parentheses T/#Total
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

	ShowCurrencyValueInChaos := 1   ; Convert the value of currency items into chaos orbs.
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
									; Example: assume the affix line to be mirrored is '#% increased Spell Damage'.
									; If the MirrorLineFieldWidth is set to 18, this field would be shown as '#% increased Spell…'


	; Pixels mouse must move to auto-dismiss tooltip
	MouseMoveThreshold := 40

	; Set this to 1 if you want to have the tooltip disappear after the time frame set below.
	; Otherwise you will have to move the mouse by 5 pixels for the tip to disappear.
	UseTooltipTimeout := 0

	;How many ticks to wait before removing tooltip. 1 tick = 100ms. Example, 50 ticks = 5secends, 75 Ticks = 7.5Secends
	ToolTipTimeoutTicks := 150

	; Font size for the tooltip, leave empty for default
	FontSize := 9

	; Displays the tooltip in virtual screen space at fixed coordinates.
	; Virtual screen space means the complete desktop frame, including any secondary monitors.
	DisplayToolTipAtFixedCoords := 0

	; Coordinates relative to top left corner, increasing by going down and to the right.
	; Only used if DisplayToolTipAtFixedCoords is 1.
	ScreenOffsetX := 0
	ScreenOffsetY := 0
	
	ScanUI()
	{		
		For key, val in this {
			this[key] := GuiGet(key)
		}
	}
}
Opts := new UserOptions()

class Fonts {

	Init(FontSizeFixed, FontSizeUI)
	{
		this.FontSizeFixed	:= FontSizeFixed
		this.FontSizeUI		:= FontSizeUI
		this.FixedFont		:= this.CreateFixedFont(FontSizeFixed)
		this.UIFont			:= this.CreateUIFont(FontSizeUI)
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
	Init() 
	{
		This.Links		:= ""
		This.Sockets	:= ""
		This.Stats		:= ""
		This.NamePlate	:= ""
		This.Affixes	:= ""
		This.AffixTextLines		:= []
		This.UncertainAffixes	:= {}
		This.FullText	:= ""
		This.IndexAffixes := -1
		This.IndexLast	:= -1
		This.PartsLast	:= ""
		This.Rarity		:= ""
		This.Parts		:= []
	}
}
Global ItemData := new ItemData_
ItemData.Init()

class Item_ {
	; Initialize all the Item object attributes to default values
	Init()
	{
		This.Name			:= ""
		This.TypeName		:= ""
		This.Quality		:= ""
		This.BaseLevel		:= ""
		This.RarityLevel	:= ""
		This.BaseType		:= ""
		This.GripType		:= ""
		This.Level			:= ""
		This.MapLevel		:= ""
		This.MapTier		:= ""
		This.MaxSockets		:= ""
		This.SubType		:= ""		
		This.DifficultyRestriction := ""
		This.Implicit		:= []
		This.Charges		:= []
		This.AreaMonsterLevelReq := []
		
		This.HasImplicit	:= False
		This.HasEffect		:= False
		This.IsWeapon		:= False
		This.IsArmour 		:= False
		This.IsHybridArmour := False
		This.IsQuiver 		:= False
		This.IsFlask 		:= False
		This.IsGem			:= False
		This.IsCurrency 	:= False
		This.IsUnidentified := False
		This.IsBelt 		:= False
		This.IsRing 		:= False
		This.IsUnsetRing 	:= False
		This.IsBow			:= False
		This.IsAmulet 		:= False
		This.IsSingleSocket := False
		This.IsFourSocket 	:= False
		This.IsThreeSocket 	:= False
		This.IsMap			:= False
		This.IsTalisman 	:= False
		This.IsJewel 		:= False
		This.IsLeaguestone	:= False
		This.IsDivinationCard := False
		This.IsProphecy		:= False
		This.IsUnique 		:= False
		This.IsRare			:= False
		This.IsCorrupted	:= False
		This.IsMirrored	:= False
		This.IsMapFragment	:= False
		This.IsEssence		:= False
		This.IsRelic		:= False
	}
}
Global Item := new Item_
Item.Init()

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

IfNotExist, %userDirectory%\config.ini
{
	CopyDefaultConfig()
}

; Windows system tray icon
; possible values: poe.ico, poe-bw.ico, poe-web.ico, info.ico
; set before creating the settings UI so it gets used for the settings dialog as well
Menu, Tray, Icon, %A_ScriptDir%\resources\images\poe-bw.ico

ReadConfig()
Sleep, 100

; Use some variables to skip the update check or enable/disable update check feedback.
; The first call on script start shouldn't have any feedback and including ItemInfo in other scripts should call the update once from that other script.
; Under no circumstance set the variable "SkipItemInfoUpdateCall" in this script.
; This code block should only be called when ItemInfo runs by itself, not when it's included in other scripts like PoE-TradeMacro.
; "SkipItemInfoUpdateCall" should be set outside by other scripts.
global firstUpdateCheck := true
If (!SkipItemInfoUpdateCall) {
	GoSub, CheckForUpdates
}
firstUpdateCheck := false

CreateSettingsUI()
If (StrLen(overwrittenUserFiles)) {
	ShowChangedUserFiles()
}
GoSub, AM_AssignHotkeys
GoSub, FetchCurrencyData

Menu, TextFiles, Add, Additional Macros, EditAdditionalMacros
Menu, TextFiles, Add, Map Mod Warnings, EditMapModWarnings
Menu, TextFiles, Add, Custom Macros Example, EditCustomMacrosExample

; Menu tooltip
RelVer := Globals.Get("ReleaseVersion")
Menu, Tray, Tip, Path of Exile Item Info %RelVer%

Menu, Tray, NoStandard
Menu, Tray, Add, Reload Script (Use only this), ReloadScript
Menu, Tray, Add ; Separator
Menu, Tray, Add, About..., MenuTray_About
Menu, Tray, Add, Show all assigned Hotkeys, ShowAssignedHotkeys
Menu, Tray, Add, % Globals.Get("SettingsUITitle", "PoE Item Info Settings"), ShowSettingsUI
Menu, Tray, Add, Check for updates, CheckForUpdates
Menu, Tray, Add, Update Notes, ShowUpdateNotes
Menu, Tray, Add ; Separator
Menu, Tray, Add, Edit Files, :TextFiles
Menu, Tray, Add, Open User Folder, EditOpenUserSettings
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
		IF !IsObject(File)
		{
			MsgBox, 16, Error, File not found and can't write new file.
			return
		}
		File.Close()
		Run, % Filepath
	}
	return

}

OpenUserDirFile(Filename)
{
	Filepath := userDirectory . "\" . Filename
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

OpenUserSettingsFolder(ProjectName, Dir = "")
{	
    If (!StrLen(Dir)) {
        Dir := userDirectory
    }

    If (!InStr(FileExist(Dir), "D")) {
        FileCreateDir, %Dir%        
    }
    Run, Explorer %Dir%
    return
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

		IF (InStr(ItemTypeName, element) != 0 && StrLen(element) > ResultLength)
		{
			ResultIndex := A_Index
			ResultLength := StrLen(element)
		}
	}

	BaseLevel := ""
	IF (ResultIndex > 0) {
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
			BaseType = Weapon
			SubType = Bow
			GripType = 2H
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
		; Get third line in case of rare or unique item and retrieve the base item name
		LoopField := RegExReplace(A_LoopField, "<<.*>>", "")
		If (RarityLevel > 2)
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
		If (InStr(LoopField, "Amulet") or (InStr(LoopField, "Talisman") and not InStr(LoopField, "Leaguestone")))
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
			IfInString, LoopField, Shaped
			{
				Global shapedMapMatchList
				BaseType = Map
				Loop % shapedMapMatchList.MaxIndex()
				{
					Match := shapedMapMatchList[A_Index]
					IfInString, LoopField, %Match%
					{
						SubType = %Match%
						return
					}
				}
			}
			
			Global mapMatchList
			BaseType = Map
			Loop % mapMatchList.MaxIndex()
			{
				Match := mapMatchList[A_Index]
				IfInString, LoopField, %Match%
				{
					SubType = %Match%
					return
				}
			}

			SubType = Unknown%A_Space%Map
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
		
		; Leaguestones
		IfInString, LoopField, Leaguestone
		{
			RegexMatch(LoopField, "i)(.*)Leaguestone", match)
			RegexMatch(Trim(match1), "i)\b(\w+)\W*$", match) ; match last word
			BaseType = Leaguestone
			SubType := Trim(match1) " Leaguestone"
			return
		}


		; Matching armour types with regular expressions for compact code

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
		; Note: Not using "$" means "Leather" could match "Leather Belt", therefore we first check that the item is not a belt. (belts are currently checked earlier so this is redundant, but the order might change)
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
			IfInString, A_LoopField, note:
			
			; new code added by Bahnzo - The ability to add prices to items causes issues. 
			; Building the code sent from the clipboard differently, and ommiting the line with "Note:" on it partially fixes this.
			; We also have to omit the \newline \return that gets added at the end.
			; Not adding the note to ClipboardContents but its own variable should solve all problems.
			{
				Note := A_LoopField
				; We drop the "note:", but the "--------" has already been added and we don't want it, so we delete the last 8 chars.
				Result := SubStr(Result, 1, -8)
				break                       
			}
			IfInString, A_LoopField, Map drop
			{
				break
			}
			If A_Index = 1                  ; so we start with just adding the first line w/o either a `n or `r
			{
				Result := Result . A_LoopField
			}
			Else
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
				Result := SubStr(Result, 1, -8)
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
	; Temp, I used this for debugging and considering adding it to UserOptions
	; append the result for easier comparison and debugging
	; Clipboard = %Clipboard%`n*******************************************`n`n%String%
}

/*
Puts the data from a file into an array in inverted order, so that tier1 is at array position 1.
Each array element is an object with 8 keys:
	
	Always assinged:
		ilvl: Itemlevel of the bracket/tier
		values: The complete value line from the file
	
	In case of the simple range "1-2" format, otherwise empty string:
		min: min value (1)
		max: min value (2)
	
	In case of the double range "1-2,3-4" format, otherwise empty string:
		minLo: lower min value (1)
		minHi: upper min value (2)
		maxLo: lower max value (3)
		maxHi: upper max value (4)
*/
ArrayFromDatafile(Filename)
{
	ModDataArray := []
	min		:= ""
	max		:= ""
	minLo	:= ""
	minHi	:= ""
	maxLo	:= ""
	maxHi	:= ""
	
	Loop, Read, %A_ScriptDir%\%Filename%
	{
		StringSplit, AffixDataParts, A_LoopReadLine, |,
		RangeItemLevel := AffixDataParts1
		RangeValues := AffixDataParts2
		
		IfInString, RangeValues, `,
		{
			; Example lines from txt file database for double range lookups:
			;  3|1,14-15
			; 13|1-3,35-37
			StringSplit, DoubleRangeParts, RangeValues, `,
			LB := DoubleRangeParts1
			UB := DoubleRangeParts2
			
			IfInString, LB, -
			{
				; Lower bound is a range: #-#
				ParseRange(LB, minLo, minHi)
			}
			Else
			{
				; Lower bound is a single value. Gets assigned to both min.
				minLo := LB
				minHi := LB
			}
			IfInString, UB, -
			{
				; Upper bound is a range: #-#
				ParseRange(UB, maxLo, maxHi)
			}
			Else
			{
				; Upper bound is a single value. Gets assigned to both min.
				maxLo := UB
				maxHi := UB
			}
		}
		Else
		{
			; The whole bracket in RangeValues is in the #-# format (it is no double range). This is the case for most mods.
			ParseRange(RangeValues, min, max)
		}
		
		element := {"ilvl":RangeItemLevel, "values":RangeValues, "min":min, "max":max, "minLo":minLo, "minHi":minHi, "maxLo":maxLo, "maxHi":maxHi}
		ModDataArray.InsertAt(1, element)
	}
	return ModDataArray
}

/*
Parameters:
1) Finds all matching tiers for Value (either number or value range).
2) Uses the ModDataArray provided by ArrayFromDatafile().
3) ItemLevel optional but usually needed for the function to make sense. Tiers that require a higher itemlevel than provided are skipped.

Returns an object with 3 keys:
	tier: The matching tier found for the provided "Value". Empty string if no match or more than one matching tier is found.
	
	If more than one matching tier is found, otherwise empty strings:
	Top: The "best"  tier that matches, so the numerically lowest (!) tier.
	Btm: The "worst" tier that matches, so the numerically highest (!) tier.
*/
LookupTierByValue(Value, ModDataArray, ItemLevel=100)
{
	tier	:= ""
	tierTop	:= ""
	tierBtm	:= ""
	
	Loop
	{
		If( A_Index > ModDataArray.Length() )
		{
			Break
		}
		
		CheckTier := A_Index
		
		If( ModDataArray[CheckTier].ilvl > ItemLevel)
		{
			; Skip line if the ItemLevel is too low for the tier
			Continue
		}
		Else
		{
			IfInString, Value, -
			{
				; Value is a range (due to a double range mod)
				ParseRange(Value, ValueLo, ValueHi)
				
				If( (ModDataArray[CheckTier].minLo <= ValueLo) and (ValueLo <= ModDataArray[CheckTier].minHi) and (ModDataArray[CheckTier].maxLo <= ValueHi) and (ValueHi <= ModDataArray[CheckTier].maxHi) )
				{
					; Both values fit in the brackets
					If(tier="")
					{
						; tier not assigned yet, so fill it. This is put into tierTop later if more than one tier fits.
						tier := CheckTier
					}
					Else
					{
						; otherwise fill tierBtm (and have it potentially overwritten if an even lower match is found later).
						tierBtm := CheckTier
					}
				}
				Continue
			}
			Else
			{
				; Value is a number, not a range
				If( (ModDataArray[CheckTier].min <= Value) and (Value <= ModDataArray[CheckTier].max) )
				{
					; Value fits in the bracket
					If(tier="")
					{
						; tier not assigned yet, so fill it. This is put into tierTop later if more than one tier fits.
						tier := CheckTier
					}
					Else
					{
						; otherwise fill tierBtm (and have it potentially overwritten if an even lower match is found later).
						tierBtm := CheckTier
					}
				}
				Continue
			}
		}
	}
	If(tierBtm)
	{
		; tierBtm was actually used, so more than one tier fits. Thus putting tier into tierTop instead.
		tierTop := tier
		tier := ""
	}
	
	return {"Tier":tier,"Top":tierTop,"Btm":tierBtm}
}


; TODO: LookupAffixBracket and LookupAffixData contain a lot of duplicate code.

; Look up just the most applicable bracket for an affix.
; Most applicable means Value is between bounds of bracket range or
; highest entry possible given the item level.
;
; Returns "#-#" format range
;
; If Value is unspecified ("") return the max possible bracket based on item level
LookupAffixBracket(Filename, ItemLevel, Value="", ByRef BracketItemLevel="", ByRef BracketIndex=0)
{
	AffixItemLevel := 0
	AffixDataIndex := 1
	If (Not Value == "")
	{
		ValueLo := Value             ; Value from ingame tooltip
		ValueHi := Value             ; For single values (which most of them are) ValueLo == ValueHi
		ParseRange(Value, ValueLo, ValueHi)
	}
	LookupIsDoubleRange := False ; For affixes like "Adds +# ... Damage" which have a lower and an upper bound range
	BracketRange := "n/a"
	Loop, Read, %A_ScriptDir%\%Filename%
	{
		
		StringSplit, AffixDataParts, A_LoopReadLine, |,
		RangeLevel := AffixDataParts1
		RangeValues := AffixDataParts2
		If (RangeLevel > ItemLevel)
		{
			Break
		}
		++AffixDataIndex	; Increment after we checked whether we are above ItemLevel
		
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
				; Lower bound is a range: #-#
				ParseRange(LB, LBMin, LBMax)
			}
			IfInString, UB, -
			{
				ParseRange(UB, UBMin, UBMax)
			}
			LBPart = %LBMin%
			UBPart = %UBMax%
			; Record bracket range if it is within bounds of the text file entry
			If (Value == "" or (((ValueLo >= LBMin) and (ValueLo <= LBMax)) and ((ValueHi >= UBMin) and (ValueHi <= UBMax))))
			{
				BracketRange = %LBPart%-%UBPart%
				AffixItemLevel = %RangeLevel%
			}
		}
		Else
		{
			ParseRange(RangeValues, LoVal, HiVal)
			; Record bracket range if it is within bounds of the text file entry
			If (Value == "" or ((ValueLo >= LoVal) and (ValueHi <= HiVal)))
			{
				BracketRange = %LoVal%-%HiVal%
				AffixItemLevel = %RangeLevel%
			}
		}
		If (Value == "")
		{
			AffixItemLevel = %RangeLevel%
		}
	}
	BracketIndex := AffixDataIndex
	BracketItemLevel := AffixItemLevel
	return BracketRange
}

; Look up complete data for an affix. Depending on settings flags
; this may include many things, and will return a string used for
; end user display rather than further calculations.
; Use LookupAffixBracket if you need a range format to do calculations with.
LookupAffixData(Filename, ItemLevel, Value, ByRef BracketItemLevel="", ByRef Tier=0)
{
	Global Opts

	AffixItemLevel := 0
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
		ParseRange(Value, ValueLo, ValueHi)
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
		; Increment MaxTier here and not before the break, because the break is executed when
		; the ItemLevel and thus the MaxTier is exceeded, not once it is met.
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
				ParseRange(LB, LBMin, LBMax)
			}
			IfInString, UB, -
			{
				ParseRange(UB, UBMin, UBMax)
			}
			If (AffixDataIndex == 1)
			{
				StringSplit, FirstDoubleRangeParts, FirstRangeValues, `,
				FRLB := FirstDoubleRangeParts%FirstDoubleRangeParts%1
				FRUB := FirstDoubleRangeParts%FirstDoubleRangeParts%2
				ParseRange(FRUB, FRUBMin, FRUBMax)
				ParseRange(FRLB, FRLBMin, FRLBMax)
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
				AffixItemLevel = %MaxLevel%
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
				ParseRange(FirstRangeValues, FRLoVal, FRHiVal)
			}
			ParseRange(RangeValues, LoVal, HiVal)
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
				AffixItemLevel = %MaxLevel%
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
	BracketItemLevel := AffixItemLevel
	
	return [BracketRange, BracketItemLevel, MaxRange, MaxLevel]
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
ParseRange(RangeChunk, ByRef Lo, ByRef Hi)
{
	IfInString, RangeChunk, -
	{
		StringSplit, RangeParts, RangeChunk, -
		Lo := RegExReplace(RangeParts1, "(\d+?)", "$1")
		Hi := RegExReplace(RangeParts2, "(\d+?)", "$1")
	}
	Else
	{
		Lo := RangeChunk
		Hi := RangeChunk
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

; For Debug purposes. Can be used to unravel an object into a printable format.
ExploreObj(Obj, NewRow="`n", Equal="  =  ", Indent="`t", Depth=12, CurIndent="")
{ 
	for k,v in Obj
		ToReturn .= CurIndent . k . (IsObject(v) && depth>1 ? NewRow . ExploreObj(v, NewRow, Equal, Indent, Depth-1, CurIndent . Indent) : Equal . v) . NewRow

	return RTrim(ToReturn, NewRow)
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

; Formats floating values such as 2.50000 or 3.00000 into 2.5 and 3
NumFormatPointFiveOrInt(Value){
	If( not Mod(Value, 1) )
	{
		return Round(Value)
	}
	Else
	{
		return NumFormat(Value, 0.1)	
	}
}

; Pads a number with prefixed 0s and optionally rounds or appends to specified decimal places width.
NumPad(Num, TotalWidth, DecimalPlaces=0)
{
	myFormat = 0%TotalWidth%.%DecimalPlaces%
	newNum := NumFormat(Num, myFormat)
	return newNum
}

AffixTypeShort(AffixType)
{
	result := RegExReplace(AffixType, "Hybrid ", "Hyb")
	result := RegExReplace(result, "Prefix", "P")
	result := RegExReplace(result, "Suffix", "S")
	return result
}

MakeAffixDetailLine(AffixLine, AffixType, ValueRange, Tier, CountAffixTotals=True)
{
	Global ItemData, AffixTotals
	
	If(CountAffixTotals)
	{
		If(AffixType =="Prefix"){
			AffixTotals.NumPrefixes += 1
		}
		Else If(AffixType =="Suffix"){
			AffixTotals.NumSuffixes += 1
		}
		Else If(AffixType =="Hybrid Prefix"){
			AffixTotals.NumSuffixes += 0.5
		}
		Else If(AffixType =="Hybrid Suffix"){
			AffixTotals.NumSuffixes += 0.5
		}
	}
	
	If(Item.IsJewel)
	{
		TierAndType := AffixTypeShort(AffixType)	; Discard tier since it's always T1
		
		return [AffixLine, ValueRange, TierAndType]
	}
	
	If(IsObject(AffixType))
	{
		; Multiple mods in one line
		TierAndType := ""
		
		For n, AfTy in AffixType
		{
			If(IsObject(Tier[A_Index]))
			{
				; Tier has a range
				If(Tier[A_Index][1] = Tier[A_Index][2])
				{
					Ti := Tier[A_Index][1]
				}
				Else
				{
					Ti := Tier[A_Index][1] . "-" Tier[A_Index][2]
				}
			}
			Else
			{
				Ti := Tier[A_Index]
			}
			
			TierAndType .= "T" . Ti . " " . AffixTypeShort(AfTy) . " + "
		}
		
		TierAndType := SubStr(TierAndType, 1, -3)	; Remove trailing " + " at line end
	}
	Else If(IsObject(Tier))
	{
		; Just one mod in the line, but Tier has a range
		If(Tier[1] = Tier[2])
		{
			Ti := Tier[1]
		}
		Else
		{
			Ti := Tier[1] . "-" Tier[2]
		}
		
		TierAndType := "T" . Ti . " " . AffixTypeShort(AffixType)
	}
	Else
	{
		If Tier is number
		{
			; Just one mod and a single numeric tier
			TierAndType := "T" . Tier . " " . AffixTypeShort(AffixType)
		}
		Else
		{
			; Some special mods like meta crafts provide no Tier, don't use the "T" in that case.
			TierAndType := AffixTypeShort(AffixType)
		}
	}
	
	return [AffixLine, ValueRange, TierAndType]
}

MakeMapAffixLine(AffixLine, MapAffixCount)
{
	Line := [AffixLine, MapAffixCount]
	return Line
}

AppendAffixInfo(Line, AffixPos)
{
	Global AffixLines
	AffixLines.Set(AffixPos, Line)
}

AssembleAffixDetails()
{
	Global Opts, AffixLines, Itemdata
	
	Result := ""
	NumAffixLines := AffixLines.MaxIndex()		; ( Itemdata.AffixTextLines.MaxIndex() > AffixLines.MaxIndex() ) ? Itemdata.AffixTextLines.MaxIndex() : AffixLines.MaxIndex()
	
	TextLineWidth := 20
	TextLineWidthUnique := TextLineWidth + 10
	TextLineWidthJewel  := TextLineWidth + 10
	
	ValueRangeMinWidth := 4
	ValueRange1Width := ValueRangeMinWidth
	ValueRange2Width := ValueRangeMinWidth
	
	Delim := "  "
	Ellipsis := "…"
	
	If(Item.IsUnique)
	{
		Loop, %NumAffixLines%
		{
			CurLine := AffixLines[A_Index]
			AffixLine := CurLine[1]
			ValueRange := CurLine[2]
			
			If(StrLen(AffixLine) > TextLineWidthUnique)
			{
				AffixLine := SubStr(AffixLine, 1, TextLineWidthUnique - 1) . Ellipsis
			}
			Else
			{
				AffixLine := StrPad(AffixLine, TextLineWidthUnique)
			}
			
			ProcessedLine := AffixLine . Delim . ValueRange
			
			Result .= "`n" . ProcessedLine
		}
		
		return Result
	}
	Else
	{
		Loop, %NumAffixLines%
		{
			CurLine := AffixLines[A_Index]
			
			ValueRange := CurLine[2]
			If( ! IsObject(ValueRange) )
			{
				; Text as ValueRange
				continue
			}
			
			If( StrLen(ValueRange[1]) > ValueRange1Width )
			{
				If(ValueRange[2])
				{
					ValueRange1Width := StrLen(ValueRange[1])
				}
				Else If( StrLen(ValueRange[1]) > ValueRange1Width + 5 )
				{
					ValueRange1Width := StrLen(ValueRange[1]) - 5
				}
			}
			
			If( StrLen(ValueRange[3]) > ValueRange2Width )
			{
				ValueRange2Width := StrLen(ValueRange[3])
			}
			
		}
		
		Loop, %NumAffixLines%
		{
			CurLine := AffixLines[A_Index]
			; Any empty line is considered as an Unprocessed Mod
			If(IsObject(CurLine))
			{
				AffixLine := CurLine[1]
				ValueRange := CurLine[2]
				TierAndType := CurLine[3]
				
				If(Item.IsJewel)
				{
					If(StrLen(AffixLine) > TextLineWidthJewel)
					{
						ProcessedLine := SubStr(AffixLine, 1, TextLineWidthJewel - 1) . Ellipsis
					}
					Else
					{
						ProcessedLine := StrPad(AffixLine, TextLineWidthJewel)
					}
					
					; Jewel mods don't have tiers. Display only the ValueRange and the AffixType. TierAndType already holds only the Type here, due to a check in MakeAffixDetailLine().
					ProcessedLine .= Delim . " " . StrPad(ValueRange[1], ValueRange1Width, "left")
					ProcessedLine .= Delim . TierAndType
				}
				Else
				{
					If( ! IsObject(ValueRange) )
					{
						; Text as ValueRange
						If(StrLen(AffixLine) > TextLineWidth + StrLen(Delim) + ValueRange1Width + 5)
						{
							ProcessedLine := SubStr(AffixLine, 1, TextLineWidth + StrLen(Delim) + ValueRange1Width + 5 - 1) . Ellipsis
						}
						Else
						{
							ProcessedLine := StrPad(AffixLine, TextLineWidth + StrLen(Delim) + ValueRange1Width + 5)
						}
						
						ProcessedLine .= Delim . StrPad(StrPad(ValueRange, ValueRange2Width + 5, "left"), ValueRange2Width + 5 + 4, "right")
						ProcessedLine .= " " . TierAndType
					}
					Else
					{
						If(StrLen(AffixLine) > TextLineWidth)
						{
							ProcessedLine := SubStr(AffixLine, 1, TextLineWidth - 1) . Ellipsis
						}
						Else
						{
							ProcessedLine := StrPad(AffixLine, TextLineWidth)
						}
						
						If(ValueRange[2])
						{
							ProcessedLine .= Delim . StrPad(ValueRange[1], ValueRange1Width, "left") . " " . StrPad("(" . ValueRange[2] . ")", 4, "left")
						}
						Else
						{
							ProcessedLine .= Delim . StrPad(StrPad(ValueRange[1], ValueRange1Width, "left"), ValueRange1Width + 5, "right")
						}
						
						ProcessedLine .= Delim . StrPad(ValueRange[3], ValueRange2Width, "left") . " " . StrPad("(" . ValueRange[4] . ")", 4, "left")
						ProcessedLine .= Delim . TierAndType
					}
				}
			}
			Else
			{
				ProcessedLine := "   Unprocessed Essence Mod or unknown Mod"
			}
			
			Result := Result . "`n" . ProcessedLine
		}
	}
	
	return Result
}

AssembleMapAffixes()
{
	Global Opts, AffixLines

	AffixLine =
	NumAffixLines := AffixLines.MaxIndex()
	AffixLineParts := 0
	Loop, %NumAffixLines%
	{
		CurLine := AffixLines[A_Index]
		; Any empty line is considered as an Unprocessed Mod
		If(IsObject(CurLine))
		{
			AffixLine := CurLine[1]
			MapAffixCount := CurLine[2]
			
			ProcessedLine := Format("{1: 2s}) {2:s}", MapAffixCount, AffixLine)
		}
		Else
		{
			ProcessedLine := "   Unknown Mod"
		}
		
		Result := Result . "`n" . ProcessedLine
	}
	return Result
}

; Checks ActualValue against ValueRange, returning 1 if
; ActualValue is within bounds of ValueRange, 0 otherwise.
WithinBounds(ValueRange, ActualValue)
{
	VHi := 0
	VLo := 0
	ParseRange(ValueRange, VLo, VHi)
	Result := 1
	IfInString, ActualValue, -
	{
		AVHi := 0
		AVLo := 0
		ParseRange(ActualValue, AVLo, AVHi)
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

; Get actual value from a line of the ingame tooltip as a number
; that can be used in calculations.
GetActualValue(ActualValueLine)
{
	; Leaves "-" in for negative values, example: "Ventor's Gamble"
	Result := RegExReplace(ActualValueLine, ".*?\+?(-?\d+(?: to -?\d+|\.\d+)?).*", "$1")
	; Formats "1 to 2" as "1-2"
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

AddRange(Range1, Range2)
{
	R1Hi := 0
	R1Lo := 0
	R2Hi := 0
	R2Lo := 0
	ParseRange(Range1, R1Lo, R1Hi)
	ParseRange(Range2, R2Lo, R2Hi)
	FinalHi := R1Hi + R2Hi
	FinalLo := R1Lo + R2Lo
	FinalRange = %FinalLo%-%FinalHi%
	return FinalRange
}

/*
ParseProphecy(ItemData, ByRef Difficulty = "", ByRef SealingCost = "") 
{
	; Will have to be reworked for 3.0
	For key, part in ItemData.Parts {
		RegExMatch(part, "i)(Normal)|(Cruel)|(Merciless) Difficulty", match)
		If (match) {
			Difficulty := match1 . match2 . match3
		}
	}
}
*/


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
		; "during flask effect" and "Life Recovery to Minions" should suffice
		suffixes := ["Dispels", "Removes Bleeding", "Removes Curses on use", "during flask effect", "Adds Knockback", "Life Recovery to Minions"]
		For key, suffix in suffixes {
			If (RegExMatch(A_LoopField, "i)" suffix, match)) {
				If (NumSuffixes < 1)
				{
					NumSuffixes += 1
				}
				Continue
			}
		}
		
		; Prefixes		
		prefixes := ["Recovery Speed", "Amount Recovered", "Charges", "Instant", "Charge when", "Recovery when", "Mana Recovered", "increased Duration", "increased Charge Recovery", "reduced Charges used"]
		For key, prefix in prefixes {
			If (RegExMatch(A_LoopField, "i)" prefix, match)) {
				If (NumPrefixes < 1)
				{
					NumPrefixes += 1
				}
				Continue
			}
		}
	}

	AffixTotals.NumPrefixes := NumPrefixes
	AffixTotals.NumSuffixes := NumSuffixes
}

SetMapInfoLine(AffixType, ByRef MapAffixCount, EnumLabel="")
{
	Global AffixTotals
	
	If(AffixType =="Prefix")
	{
		AffixTotals.NumPrefixes += 1
	}
	Else If(AffixType =="Suffix")
	{
		AffixTotals.NumSuffixes += 1
	}
	
	MapAffixCount += 1
	AppendAffixInfo(MakeMapAffixLine(A_LoopField, MapAffixCount . EnumLabel), A_Index)
}

ParseMapAffixes(ItemDataAffixes)
{
	Global Globals, Opts, AffixTotals, AffixLines

	FileRead, File_MapModWarn, %userDirectory%\MapModWarnings.txt
	MapModWarn := JSON.Load(File_MapModWarn)
	
	ItemDataChunk	:= ItemDataAffixes

	ItemBaseType	:= Item.BaseType
	ItemSubType		:= Item.SubType


	; Reset the AffixLines "array" and other vars
	ResetAffixDetailVars()

	IfInString, ItemDataChunk, Unidentified
	{
		return ; Not interested in unidentified items
	}
	
	MapAffixCount := 0
	TempAffixCount := 0
	
	Index_RareMonst :=
	Index_MonstSlowedTaunted :=
	Index_BossDamageAttackCastSpeed :=
	Index_BossLifeAoE :=
	Index_MonstChaosEleRes :=
	Index_MonstStunLife :=
	Index_MagicMonst :=
	Index_MonstCritChanceMult :=
	Index_PlayerDodgeMonstAccu :=
	Index_PlayerBlockArmour :=
	Index_CannotLeech :=
	Index_MonstMoveAttCastSpeed :=
	
	Count_DmgMod := 0
	String_DmgMod := ""
	
	Flag_TwoAdditionalProj := 0
	Flag_SkillsChain := 0
	
	MapModWarnings := ""

	Loop, Parse, ItemDataAffixes, `n, `r
	{
		If StrLen(A_LoopField) = 0
		{
			Continue ; Not interested in blank lines
		}

		
		; --- ONE LINE AFFIXES ---

		
		If (RegExMatch(A_LoopField, "Area is inhabited by (Abominations|Humanoids|Goatmen|Demons|ranged monsters|Animals|Skeletons|Sea Witches and their Spawn|Undead|Ghosts|Solaris fanatics|Lunaris fanatics)"))
		{
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "Monsters deal \d+% extra Damage as (Fire|Cold|Lightning)"))
		{
			MapModWarnings .= MapModWarn.MonstExtraEleDmg ? "`nExtra Ele Damage" : ""			
			SetMapInfoLine("Prefix", MapAffixCount)
			
			Count_DmgMod += 1
			String_DmgMod := String_DmgMod . ", Extra Ele"
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters reflect \d+% of Elemental Damage"))
		{
			MapModWarnings .= MapModWarn.EleReflect ? "`nEle reflect" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters reflect \d+% of Physical Damage"))
		{
			MapModWarnings .= MapModWarn.PhysReflect ? "`nPhys reflect" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "\+\d+% Monster Physical Damage Reduction"))
		{
			MapModWarnings .= MapModWarn.MonstPhysDmgReduction ? "`nPhys Damage Reduction" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "\d+% less effect of Curses on Monsters"))
		{
			MapModWarnings .= MapModWarn.MonstLessCurse ? "`nLess Curse Effect" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "Monsters have a \d+% chance to avoid Poison, Blind, and Bleed"))
		{
			MapModWarnings .= MapModWarn.MonstAvoidPoisonBlindBleed ? "`nAvoid Poison/Blind/Bleed" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "Monsters have a \d+% chance to cause Elemental Ailments on Hit"))
		{
			MapModWarnings .= MapModWarn.MonstCauseElementalAilments ? "`nCause Elemental Ailments" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "\d+% increased Monster Damage"))
		{
			MapModWarnings .= MapModWarn.MonstIncrDmg ? "`nIncreased Damage" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area is inhabited by 2 additional Rogue Exiles|Area has increased monster variety"))
		{
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area contains many Totems"))
		{
			MapModWarnings .= MapModWarn.ManyTotems ? "`nTotems" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters' skills Chain 2 additional times"))
		{
			MapModWarnings .= MapModWarn.MonstSkillsChain ? "`nSkills Chain" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Flag_SkillsChain := 1
			Continue
		}
		
		If (RegExMatch(A_LoopField, "All Monster Damage from Hits always Ignites"))
		{
			MapModWarnings .= MapModWarn.MonstHitsIgnite ? "`nHits Ignite" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Slaying Enemies close together can attract monsters from Beyond"))
		{
			MapModWarnings .= MapModWarn.Beyond ? "`nBeyond" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area contains two Unique Bosses"))
		{
			MapModWarnings .= MapModWarn.BossTwinned ? "`nTwinned Boss" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters are Hexproof"))
		{
			MapModWarnings .= MapModWarn.MonstHexproof ? "`nHexproof" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters fire 2 additional Projectiles"))
		{
			MapModWarnings .= MapModWarn.MonstTwoAdditionalProj ? "`nAdditional Projectiles" : ""
			SetMapInfoLine("Prefix", MapAffixCount)
			Flag_TwoAdditionalProj := 1
			Continue
		}		
		
		
		
		If (RegExMatch(A_LoopField, "Players are Cursed with Elemental Weakness"))
		{
			MapModWarnings .= MapModWarn.EleWeakness ? "`nEle Weakness" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players are Cursed with Enfeeble"))
		{
			MapModWarnings .= MapModWarn.Enfeeble ? "`nEnfeeble" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players are Cursed with Temporal Chains"))
		{
			MapModWarnings .= MapModWarn.TempChains ? "`nTemp Chains" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players are Cursed with Vulnerability"))
		{
			MapModWarnings .= MapModWarn.Vulnerability ? "`nVulnerability" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			
			Count_DmgMod += 0.5
			String_DmgMod := String_DmgMod . ", Vuln"
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area has patches of burning ground"))
		{
			MapModWarnings .= MapModWarn.BurningGround ? "`nBurning ground" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area has patches of chilled ground"))
		{
			MapModWarnings .= MapModWarn.ChilledGround ? "`nChilled ground" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area has patches of shocking ground"))
		{
			MapModWarnings .= MapModWarn.ShockingGround ? "`nShocking ground" : ""
			SetMapInfoLine("Suffix", MapAffixCount)

			Count_DmgMod += 0.5
			String_DmgMod := String_DmgMod . ", Shocking"
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area has patches of desecrated ground"))
		{
			MapModWarnings .= MapModWarn.DesecratedGround ? "`nDesecrated ground" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players gain \d+% reduced Flask Charges"))
		{
			MapModWarnings .= MapModWarn.PlayerReducedFlaskCharge ? "`nReduced Flask Charges" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters have \d+% increased Area of Effect"))
		{
			MapModWarnings .= MapModWarn.MonstIncrAoE ? "`nIncreased Monster AoE" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players have \d+% less Area of Effect"))
		{
			MapModWarnings .= MapModWarn.PlayerLessAoE ? "`nLess Player AoE" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters have \d+% chance to Avoid Elemental Ailments"))
		{
			MapModWarnings .= MapModWarn.MonstAvoidElementalAilments ? "`nMonsters Avoid Elemental Ailments" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players have \d+% less Recovery Rate of Life and Energy Shield"))
		{
			MapModWarnings .= MapModWarn.LessRecovery ? "`nLess Recovery" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters take \d+% reduced Extra Damage from Critical Strikes"))
		{
			MapModWarnings .= MapModWarn.MonstTakeReducedCritDmg ? "`nReduced Crit Damage" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "-\d+% maximum Player Resistances"))
		{
			MapModWarnings .= MapModWarn.PlayerReducedMaxRes ? "`n-Max Res" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			
			Count_DmgMod += 0.5
			String_DmgMod := String_DmgMod . ", -Max Res"
			Continue
		}

		If (RegExMatch(A_LoopField, "Players have Elemental Equilibrium"))
		{
			MapModWarnings .= MapModWarn.PlayerEleEquilibrium ? "`nEle Equilibrium" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players have Point Blank"))
		{
			MapModWarnings .= MapModWarn.PlayerPointBlank ? "`nPoint Blank" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters Poison on Hit"))
		{
			MapModWarnings .= MapModWarn.MonstHitsPoison ? "`nHits Poison" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players cannot Regenerate Life, Mana or Energy Shield"))
		{
			MapModWarnings .= MapModWarn.NoRegen ? "`nNo Regen" : ""
			SetMapInfoLine("Suffix", MapAffixCount)
			Continue
		}

		
		; --- SIMPLE TWO LINE AFFIXES ---
		
		
		If (RegExMatch(A_LoopField, "Rare Monsters each have a Nemesis Mod|\d+% more Rare Monsters"))
		{
			If (Not Index_RareMonst)
			{
				MapModWarnings .= MapModWarn.MonstRareNemesis ? "`nNemesis" : ""
				SetMapInfoLine("Prefix", MapAffixCount, "a")
				Index_RareMonst := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_RareMonst . "b"), A_Index)
				Continue
			}
		}
		
		If (RegExMatch(A_LoopField, "Monsters cannot be slowed below base speed|Monsters cannot be Taunted"))
		{
			If (Not Index_MonstSlowedTaunted)
			{
				MapModWarnings .= MapModWarn.MonstNotSlowedTaunted ? "`nNot Slowed/Taunted" : ""
				SetMapInfoLine("Prefix", MapAffixCount, "a")
				Index_MonstSlowedTaunted := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstSlowedTaunted . "b"), A_Index)
				Continue
			}
		}
		
		If (RegExMatch(A_LoopField, "Unique Boss deals \d+% increased Damage|Unique Boss has \d+% increased Attack and Cast Speed"))
		{
			If (Not Index_BossDamageAttackCastSpeed)
			{
				MapModWarnings .= MapModWarn.BossDmgAtkCastSpeed ? "`nBoss Damage & Attack/Cast Speed" : ""
				SetMapInfoLine("Prefix", MapAffixCount, "a")
				Index_BossDamageAttackCastSpeed := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_BossDamageAttackCastSpeed . "b"), A_Index)
				Continue
			}
		}
		
		If (RegExMatch(A_LoopField, "Unique Boss has \d+% increased Life|Unique Boss has \d+% increased Area of Effect"))
		{
			If (Not Index_BossLifeAoE)
			{
				MapModWarnings .= MapModWarn.BossLifeAoE ? "`nBoss Life & AoE" : ""
				SetMapInfoLine("Prefix", MapAffixCount, "a")
				Index_BossLifeAoE := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_BossLifeAoE . "b"), A_Index)
				Continue
			}
		}
		
		If (RegExMatch(A_LoopField, "\+\d+% Monster Chaos Resistance|\+\d+% Monster Elemental Resistance"))
		{
			If (Not Index_MonstChaosEleRes)
			{
				MapModWarnings .= MapModWarn.MonstChaosEleRes ? "`nChaos/Ele Res" : ""
				SetMapInfoLine("Prefix", MapAffixCount, "a")
				Index_MonstChaosEleRes := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstChaosEleRes . "b"), A_Index)
				Continue
			}
		}

		
		
		If (RegExMatch(A_LoopField, "\d+% more Magic Monsters|Magic Monster Packs each have a Bloodline Mod"))
		{
			If (Not Index_MagicMonst)
			{
				MapModWarnings .= MapModWarn.MonstMagicBloodlines ? "`nBloodlines" : ""
				SetMapInfoLine("Suffix", MapAffixCount, "a")
				Index_MagicMonst := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MagicMonst . "b"), A_Index)
				Continue
			}
		}
		
		If (RegExMatch(A_LoopField, "Monsters have \d+% increased Critical Strike Chance|\+\d+% to Monster Critical Strike Multiplier"))
		{
			If (Not Index_MonstCritChanceMult)
			{
				MapModWarnings .= MapModWarn.MonstCritChanceMult ? "`nCrit Chance & Multiplier" : ""
				SetMapInfoLine("Suffix", MapAffixCount, "a")
				
				Count_DmgMod += 1
				String_DmgMod := String_DmgMod . ", Crit"
				Index_MonstCritChanceMult := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstCritChanceMult . "b"), A_Index)
				Continue
			}
		}
		
		If (RegExMatch(A_LoopField, "Player Dodge chance is Unlucky|Monsters have \d+% increased Accuracy Rating"))
		{
			If (Not Index_PlayerDodgeMonstAccu)
			{
				MapModWarnings .= MapModWarn.PlayerDodgeMonstAccu ? "`nDodge unlucky / Monster Accuracy" : ""
				SetMapInfoLine("Suffix", MapAffixCount, "a")
				Index_PlayerDodgeMonstAccu := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_PlayerDodgeMonstAccu . "b"), A_Index)
				Continue
			}
		}
		
		If (RegExMatch(A_LoopField, "Players have \d+% reduced Block Chance|Players have \d+% less Armour"))
		{
			If (Not Index_PlayerBlockArmour)
			{
				MapModWarnings .= MapModWarn.PlayerReducedBlockLessArmour ? "`nReduced Block / Less Armour" : ""
				SetMapInfoLine("Suffix", MapAffixCount, "a")
				Index_PlayerBlockArmour := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_PlayerBlockArmour . "b"), A_Index)
				Continue
			}
		}
		
		If (RegExMatch(A_LoopField, "Cannot Leech Life from Monsters|Cannot Leech Mana from Monsters"))
		{
			If (Not Index_CannotLeech)
			{
				MapModWarnings .= MapModWarn.NoLeech ? "`nNo Leech" : ""
				SetMapInfoLine("Suffix", MapAffixCount, "a")
				Index_CannotLeech := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_CannotLeech . "b"), A_Index)
				Continue
			}
		}
		
		; Second part of this affix is further below under complex affixes
		If (RegExMatch(A_LoopField, "Monsters cannot be Stunned"))
		{
			MapModWarnings .= MapModWarn.MonstNotStunned ? "`nNot Stunned" : ""
			
			If (Not Index_MonstStunLife)
			{
				SetMapInfoLine("Prefix", MapAffixCount, "a")
				Index_MonstStunLife := MapAffixCount
				Continue
			}
			Else
			{
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstStunLife . "b"), A_Index)
				Continue
			}
		}
		
		; --- SIMPLE THREE LINE AFFIXES ---

		
		If (RegExMatch(A_LoopField, "\d+% increased Monster Movement Speed|\d+% increased Monster Attack Speed|\d+% increased Monster Cast Speed"))
		{
			If (Not Index_MonstMoveAttCastSpeed)
			{
				MapModWarnings .= MapModWarn.MonstMoveAtkCastSpeed ? "`nMove/Attack/Cast Speed" : ""
				
				Count_DmgMod += 0.5
				String_DmgMod := String_DmgMod . ", Move/Attack/Cast"
				
				MapAffixCount += 1
				Index_MonstMoveAttCastSpeed := MapAffixCount . "a"
				AffixTotals.NumPrefixes += 1
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstMoveAttCastSpeed), A_Index)
				Continue
			}
			Else If InStr (Index_MonstMoveAttCastSpeed, "a")
			{
				Index_MonstMoveAttCastSpeed := StrReplace(Index_MonstMoveAttCastSpeed, "a", "b")
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstMoveAttCastSpeed), A_Index)
				Continue
			}
			Else If InStr (Index_MonstMoveAttCastSpeed, "b")
			{
				Index_MonstMoveAttCastSpeed := StrReplace(Index_MonstMoveAttCastSpeed, "b", "")
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstMoveAttCastSpeed . "c"), A_Index)
				Continue
			}
		}
		
		
		; --- COMPLEX AFFIXES ---
		
		; Pure life:  (20-29)/(30-39)/(40-49)% more Monster Life
		; Hybrid mod: (15-19)/(20-24)/(25-30)% more Monster Life, Monsters cannot be Stunned
		
		If (RegExMatch(A_LoopField, "(\d+)% more Monster Life", RegExMonsterLife))
		{
			MapModWarnings .= MapModWarn.MonstMoreLife ? "`nMore Life" : ""
				
			RegExMatch(ItemData.FullText, "Map Tier: (\d+)", RegExMapTier)
			
			; only hybrid mod
			If ((RegExMapTier1 >= 11 and RegExMonsterLife1 <= 30) or (RegExMapTier1 >= 6 and RegExMonsterLife1 <= 24) or RegExMonsterLife <= 19)
			{
				If (Not Index_MonstStunLife)
				{
					MapAffixCount += 1
					Index_MonstStunLife := MapAffixCount
					AffixTotals.NumPrefixes += 1
					AppendAffixInfo(MakeMapAffixLine(A_LoopField, MapAffixCount . "a"), A_Index)
					Continue
				}
				Else
				{
					AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstStunLife . "b"), A_Index)
					Continue
				}
			}
			
			; pure life mod
			Else If ((RegExMapTier1 >= 11 and RegExMonsterLife1 <= 49) or (RegExMapTier1 >= 6 and RegExMonsterLife1 <= 39) or RegExMonsterLife <= 29)
			{
				MapAffixCount += 1
				AffixTotals.NumPrefixes += 1
				AppendAffixInfo(MakeMapAffixLine(A_LoopField, MapAffixCount), A_Index)
				Continue			
			}
			
			; both mods
			Else
			{			
				If (Not Index_MonstStunLife)
				{
					TempAffixCount := MapAffixCount + 1
					MapAffixCount += 2
					Index_MonstStunLife := TempAffixCount
					AffixTotals.NumPrefixes += 2
					AppendAffixInfo(MakeMapAffixLine(A_LoopField, TempAffixCount . "a+" . MapAffixCount), A_Index)
					Continue
				}
				Else
				{
					MapAffixCount += 1
					AffixTotals.NumPrefixes += 1
					AppendAffixInfo(MakeMapAffixLine(A_LoopField, Index_MonstStunLife . "b+" . MapAffixCount), A_Index)
					Continue
				}

			}
		}
	}
	
	If (Flag_TwoAdditionalProj and Flag_SkillsChain)
	{
		MapModWarnings := MapModWarnings . "`nAdditional Projectiles & Skills Chain"
	}
	
	If (Count_DmgMod >= 1.5)
	{
		String_DmgMod := SubStr(String_DmgMod, 3)
		MapModWarnings := MapModWarnings . "`nMulti Damage: " . String_DmgMod
	}
		
	If (Not MapModWarn.enable_Warnings)
	{
		MapModWarnings := " disabled"
	}
	
	return MapModWarnings
}

ParseLeagueStoneAffixes(ItemDataAffixes, Item) {
	; Placeholder
}

LookupAffixAndSetInfoLine(Filename, AffixType, ItemLevel, Value, AffixLineText:="", AffixLineNum:="")
{	
	If( ! AffixLineText){
		AffixLineText := A_LoopField
	}
	If( ! AffixLineNum){
		AffixLineNum := A_Index
	}
	
	CurrTier := 0
	ValueRange := LookupAffixData(Filename, ItemLevel, Value, "", CurrTier)
	AppendAffixInfo(MakeAffixDetailLine(AffixLineText, AffixType, ValueRange, CurrTier), AffixLineNum)
}

/*
Finds possible tier combinations for a single value (thus from a single affix line) assuming that the value is a combination of two non-hybrid mods (so with no further clues).
*/
SolveTiers_Mod1Mod2(Value, Mod1DataArray, Mod2DataArray, ItemLevel)
{
	Mod1MinVal := Mod1DataArray[Mod1DataArray.MaxIndex()].min
	Mod2MinVal := Mod2DataArray[Mod2DataArray.MaxIndex()].min
	
	If(Mod1MinVal + Mod2MinVal > Value)
	{
		; Value is smaller than smallest possible sum, so it can't be composite
		return
	}
	
	Mod1MinIlvl := Mod1DataArray[Mod1DataArray.MaxIndex()].ilvl
	Mod2MinIlvl := Mod2DataArray[Mod2DataArray.MaxIndex()].ilvl
	
	If( (Mod1MinIlvl > ItemLevel) or (Mod2MinIlvl > ItemLevel) )
	{
		; The ItemLevel is too low to roll both affixes
		return
	}
	
	; Remove the minimal Mod2 value from Value and try to fit the remainder into Mod1 tiers.
	TmpValue := Value - Mod2MinVal
	Mod1Tiers := LookupTierByValue(TmpValue, Mod1DataArray, ItemLevel)
	
	If(Mod1Tiers.Tier)
	{
		; Tier exists, so we already found a working combination
		Mod1TopTier := Mod1Tiers.Tier
		Mod2BtmTier := Mod2DataArray.MaxIndex()
	}
	Else
	{
		; Assuming the min portion for Mod2 was not enough, so look up the highest tier for Mod1, limited by ItemLevel
		Loop
		{
			If( Mod1DataArray[A_Index].ilvl <= ItemLevel )
			{
				Mod1TopTier := A_Index
				Break
			}
		}
		
		; Remove the maximal Mod1 value from Value and try to fit the remainder into Mod2 tiers (giving us the bottom tier for Mod2)
		TmpValue := Value - Mod1DataArray[Mod1TopTier].max
		Mod2Tiers := LookupTierByValue(TmpValue, Mod2DataArray, ItemLevel)
		
		If(Mod2Tiers.Tier)
		{
			; Tier exists, we found a working combination
			Mod2BtmTier := Mod2Tiers.Tier
		}
		Else
		{
			; Can't find a fitting tier. This should only happen when the sum of the max values for both mods is not enough to reach Value (legacy/essence cases)
			return "Legacy?"
		}
	}
	
	; Repeat the same the other way around.
	
	TmpValue := Value - Mod1MinVal
	Mod2Tiers := LookupTierByValue(TmpValue, Mod2DataArray, ItemLevel)
	
	If(Mod2Tiers.Tier)
	{
		Mod2TopTier := Mod2Tiers.Tier
		Mod1BtmTier := Mod1DataArray.MaxIndex()
	}
	Else
	{
		Loop
		{
			If( Mod2DataArray[A_Index].ilvl <= ItemLevel )
			{
				Mod2TopTier := A_Index
				Break
			}
		}
		
		TmpValue := Value - Mod2DataArray[Mod2TopTier].max
		Mod1Tiers := LookupTierByValue(TmpValue, Mod1DataArray, ItemLevel)
		
		If(Mod1Tiers.Tier)
		{
			Mod1BtmTier := Mod1Tiers.Tier
		}
		Else
		{
			return "Legacy?"
		}
	}
	
	return {"Mod1Top":Mod1TopTier,"Mod1Btm":Mod1BtmTier,"Mod2Top":Mod2TopTier,"Mod2Btm":Mod2BtmTier}
}

/*
Finds possible tier combinations for the following case/paramenters:
	ModHybValue: There is one value which is a combination of a normal mod and a hybrid mod.
	HybOnlyValue: The other part of the hybrid mod is plain, so there is no second normal mod combining with the other hybrid part.
	
	ModDataArray: DataArray for the normal mod.
	HybWithModDataArray: DataArray for the part of the hybrid mod that is combined with the normal mod.
	HybOnlyDataArray: DataArray for the plain part of the hybrid mod.
*/
SolveTiers_ModHyb(ModHybValue, HybOnlyValue, ModDataArray, HybWithModDataArray, HybOnlyDataArray, ItemLevel)
{
	HybTiers := LookupTierByValue(HybOnlyValue, HybOnlyDataArray, ItemLevel)
	
	If(not(HybTiers.Tier))
	{
		; HybOnlyValue can't be found as a bare hybrid mod.
		return
	}
	
	; Remove hybrid portion from ModHybValue
	RemainLo := ModHybValue - HybWithModDataArray[HybTiers.Tier].max
	RemainHi := ModHybValue - HybWithModDataArray[HybTiers.Tier].min
	
	RemainHiTiers := LookupTierByValue(RemainHi, ModDataArray, ItemLevel)
	RemainLoTiers := LookupTierByValue(RemainLo, ModDataArray, ItemLevel)
	
	If( RemainHiTiers.Tier and RemainLoTiers.Tier )
	{
		; Both RemainLo/Hi result in a possible tier
		ModTopTier := RemainHiTiers.Tier
		ModBtmTier := RemainLoTiers.Tier
	}
	Else If(RemainHiTiers.Tier)
	{
		; Only RemainHi gives a possible tier, assign that tier to both Top/Btm output results
		ModTopTier := RemainHiTiers.Tier
		ModBtmTier := RemainHiTiers.Tier
	}
	Else If(RemainLoTiers.Tier)
	{
		; Only RemainLo gives a possible tier, assign that tier to both Top/Btm output results
		ModTopTier := RemainLoTiers.Tier
		ModBtmTier := RemainLoTiers.Tier
	}
	Else
	{
		; No matching tier found for both RemainLo/Hi values.
		return
	}
	
	return {"ModTop":ModTopTier,"ModBtm":ModBtmTier,"Hyb":HybTiers.Tier}
}

/*
Finds possible tier combinations for the following case/paramenters:
	There are three mods: two normal ones in different affix lines and a hybrid mod that combines with both.
	
	Value1/Value2: Values.
	Mod1DataArray: DataArray for the normal mod part of Value1.
	Mod2DataArray: DataArray for the normal mod part of Value2.
	Hyb1DataArray: DataArray for the hybrid mod part of Value1.
	Hyb2DataArray: DataArray for the hybrid mod part of Value2.
*/
SolveTiers_Mod1Mod2Hyb(Value1, Value2, Mod1DataArray, Mod2DataArray, Hyb1DataArray, Hyb2DataArray, ItemLevel)
{
	Mod1HybTiers := SolveTiers_Mod1Mod2(Value1, Mod1DataArray, Hyb1DataArray, ItemLevel)
	Mod2HybTiers := SolveTiers_Mod1Mod2(Value2, Mod2DataArray, Hyb2DataArray, ItemLevel)
	
	If(not( IsObject(Mod1HybTiers) and IsObject(Mod2HybTiers) ))
	{
		; Checking that both results are objects and thus contain tiers
		return
	}
	
	; Assign non-hybrid tiers into local variables because they might need to be corrected/overwritten.
	; It is always a ".Mod1" key that contains the tier here due to the order of SolveTiers_Mod1Mod2() from above.
	Mod1TopTier := Mod1HybTiers.Mod1Top
	Mod1BtmTier := Mod1HybTiers.Mod1Btm
	Mod2TopTier := Mod2HybTiers.Mod1Top
	Mod2BtmTier := Mod2HybTiers.Mod1Btm
	
	; Get the overlap of both theoretical hybrid tier ranges, because the actual hybrid tier(s) must be valid for both.
	; It is always a ".Mod2" key which contains the hybrid tier here due to the order of SolveTiers_Mod1Mod2() from above.
	; Picking the worse (numerically greater) "top" and the better (numerically lesser) "btm".
	HybTopTier := (Mod1HybTiers.Mod2Top > Mod2HybTiers.Mod2Top) ? Mod1HybTiers.Mod2Top : Mod2HybTiers.Mod2Top
	HybBtmTier := (Mod1HybTiers.Mod2Btm < Mod2HybTiers.Mod2Btm) ? Mod1HybTiers.Mod2Btm : Mod2HybTiers.Mod2Btm
	
	If(HybTopTier > HybBtmTier)
	{
		; Check that HybTopTier is not worse (numerically higher) than HybBtmTier.
		return
	}
	
	; Check if any hybrid tier was actually changed and re-calculate the corresponding non-hybrid tier.
	If(Mod1HybTiers.Mod2Top != HybTopTier)
	{
		TmpValue := Value1 - Hyb1DataArray[HybTopTier].max
		Mod1BtmTier := LookupTierByValue(TmpValue, Mod1DataArray, ItemLevel).Tier
	}
	Else If(Mod2HybTiers.Mod2Top != HybTopTier)
	{
		TmpValue := Value2 - Hyb2DataArray[HybTopTier].max
		Mod2BtmTier := LookupTierByValue(TmpValue, Mod2DataArray, ItemLevel).Tier
	}
	
	If(Mod1HybTiers.Mod2Btm != HybBtmTier)
	{
		TmpValue := Value1 - Hyb1DataArray[HybBtmTier].min
		Mod1TopTier := LookupTierByValue(TmpValue, Mod1DataArray, ItemLevel).Tier
	}
	Else If(Mod2HybTiers.Mod2Btm != HybBtmTier)
	{
		TmpValue := Value2 - Hyb2DataArray[HybBtmTier].min
		Mod2TopTier := LookupTierByValue(TmpValue, Mod2DataArray, ItemLevel).Tier
	}
	
	return {"Mod1Top":Mod1TopTier,"Mod1Btm":Mod1BtmTier,"Mod2Top":Mod2TopTier,"Mod2Btm":Mod2BtmTier,"HybTop":HybTopTier,"HybBtm":HybBtmTier}
}

GetValueRangeIlvlFormat(Mod1DataArray, Mod1Tiers, Mod2DataArray="", Mod2Tier="")
{
	result := []
	
	If(IsObject(Mod2DataArray) and Mod2Tier)
	{
		If(IsObject(Mod1Tiers))
		{
			BtmMin := Mod1DataArray[Mod1Tiers[2]].min + Mod2DataArray[Mod2Tier].min
			BtmMax := Mod1DataArray[Mod1Tiers[2]].max + Mod2DataArray[Mod2Tier].max
			TopMin := Mod1DataArray[Mod1Tiers[1]].min + Mod2DataArray[Mod2Tier].min
			TopMax := Mod1DataArray[Mod1Tiers[1]].max + Mod2DataArray[Mod2Tier].max
			
			result[1] := BtmMin . "-" . BtmMax . "|" . TopMin . "-" . TopMax
			result[2] := 0
		}
		Else
		{
			result[1] := Mod1DataArray[Mod1Tiers].min + Mod2DataArray[Mod2Tier].min . "-" . Mod1DataArray[Mod1Tiers].max + Mod2DataArray[Mod2Tier].max
			result[2] := Mod1DataArray[Mod1Tiers].ilvl
		}
		
		result[3] := Mod1DataArray[Mod1DataArray.MaxIndex()].min + Mod2DataArray[Mod2DataArray.MaxIndex()].min . "-" . Mod1DataArray[1].max + Mod2DataArray[1].max
		result[4] := (Mod1DataArray[1].ilvl > Mod2DataArray[1].ilvl) ? Mod1DataArray[1].ilvl : Mod2DataArray[1].ilvl
	}
	Else
	{
		If(IsObject(Mod1Tiers))
		{
			If(Mod1DataArray[Mod1Tiers[2]].minLo and Mod1DataArray[Mod1Tiers[1]].maxHi)
			{
				BtmMin := Mod1DataArray[Mod1Tiers[2]].minLo
				BtmMax := Mod1DataArray[Mod1Tiers[2]].maxHi
				TopMin := Mod1DataArray[Mod1Tiers[1]].minLo
				TopMax := Mod1DataArray[Mod1Tiers[1]].maxHi
				
				result[1] := BtmMin . "-" . BtmMax . "|" . TopMin . "-" . TopMax
				result[2] := 0
				result[3] := Mod1DataArray[Mod1DataArray.MaxIndex()].minLo . "-" . Mod1DataArray[1].maxHi
				result[4] := Mod1DataArray[1].ilvl
			}
			Else
			{
				BtmMin := Mod1DataArray[Mod1Tiers[2]].min
				BtmMax := Mod1DataArray[Mod1Tiers[2]].max
				TopMin := Mod1DataArray[Mod1Tiers[1]].min
				TopMax := Mod1DataArray[Mod1Tiers[1]].max
				
				result[1] := BtmMin . "-" . BtmMax . "|" . TopMin . "-" . TopMax
				result[2] := 0
				result[3] := Mod1DataArray[Mod1DataArray.MaxIndex()].min . "-" . Mod1DataArray[1].max
				result[4] := Mod1DataArray[1].ilvl
			}
			
			
		}
		Else
		{
			If(Mod1DataArray[Mod1Tiers].minLo and Mod1DataArray[Mod1Tiers].maxHi)
			{
				result[1] := Mod1DataArray[Mod1Tiers].minLo . "-" . Mod1DataArray[Mod1Tiers].maxHi
				result[2] := Mod1DataArray[Mod1Tiers].ilvl
				result[3] := Mod1DataArray[Mod1DataArray.MaxIndex()].minLo . "-" . Mod1DataArray[1].maxHi
				result[4] := Mod1DataArray[1].ilvl
			}
			Else
			{
				result[1] := Mod1DataArray[Mod1Tiers].min . "-" . Mod1DataArray[Mod1Tiers].max
				result[2] := Mod1DataArray[Mod1Tiers].ilvl
				result[3] := Mod1DataArray[Mod1DataArray.MaxIndex()].min . "-" . Mod1DataArray[1].max
				result[4] := Mod1DataArray[1].ilvl
			}
		}
	}
	
	return result
}


GetValueRangesWithinTiers(Value, Mod1DataArray, Mod2DataArray, Mod1TopTier, Mod1BtmTier, Mod2TopTier, Mod2BtmTier)
{
	If( (Mod1TopTier = Mod1BtmTier) and (Mod2TopTier = Mod2BtmTier) )
	{
		result := []
		result[1] := (Mod1DataArray[Mod1TopTier].min + Mod2DataArray[Mod2BtmTier].min) . "-" . (Mod1DataArray[Mod1TopTier].max + Mod2DataArray[Mod2BtmTier].max)
		result[2] := 0
		result[3] := Mod1DataArray[Mod1DataArray.MaxIndex()].min + Mod2DataArray[Mod2DataArray.MaxIndex()].min . "-" . Mod1DataArray[1].max + Mod2DataArray[1].max
		result[4] := (Mod1DataArray[1].ilvl > Mod2DataArray[1].ilvl) ? Mod1DataArray[1].ilvl : Mod2DataArray[1].ilvl
		
		return result
	}
	
	; Concept:
	; Inner loop t: Start with Mod1TopTier and get worse (numerically higher).
	; Outer loop b: Start with Mod2BtmTier and get better (numerically lower).
	; Record lowest/highest range found where value still fits. The outer values take precedence here,
	;   so RangeTop is primarily defined by RangeTopMax (e.g. 100-109 is "higher" than 105-108) and RangeBtm by RangeBtmMin (e.g. 50-59 is "lower" than 51-54).
	
	RangeBtmMin := Mod1DataArray[Mod1TopTier].min + Mod2DataArray[Mod2BtmTier].min
	RangeBtmMax := Mod1DataArray[Mod1TopTier].max + Mod2DataArray[Mod2BtmTier].max
	RangeTopMin := RangeBtmMin
	RangeTopMax := RangeBtmMax
	
	; Start at t+1 because we assigned the t/b combination as the initial range values already.
	t := Mod1TopTier + 1
	b := Mod2BtmTier
	
	; We don't need to check t starting from Mod1TopTier each loop, we can use the best/first t from the previous b loop.
	t_RestartIndex := Mod1TopTier
	
	While(b >= Mod2TopTier)
	{
		While(t <= Mod1BtmTier)
		{
			TmpMin := Mod1DataArray[t].min + Mod2DataArray[b].min
			TmpMax := Mod1DataArray[t].max + Mod2DataArray[b].max
			; Increment t here because we might break/continue the loop just below.
			++t
			
			If(not( (TmpMin <= Value) and (Value <= TmpMax) ))
			{
				If(t_RestartIndex)
				{
					; Value not within Tmp-Range, but we have a t_RestartIndex, so we had matching Tmp-Ranges for this b value
					;   but the Tmp-Ranges are getting too low for "Value" now. Break t loop to check next b, start t at t_RestartIndex and set t_RestartIndex to 0 (see loop end).
					break
				}
				; Value not within Tmp-Range and we have no t_RestartIndex, so the Tmp-Range is still too high for "Value". Restart t loop with continue.
				Else continue
			}
			
			If(not(t_RestartIndex))
			{
				; Value is within Tmp-Range (because section above was passed) and we have no t_RestartIndex yet.
				; This means this is the first matching range found for this b. Record this t (and remove the increment from the loop start).
				t_RestartIndex := (t-1)
			}
			
			If(TmpMin <= RangeBtmMin)
			{
				If(TmpMin < RangeBtmMin)
				{
					RangeBtmMin := TmpMin
					RangeBtmMax := TmpMax
				}
				Else If(TmpMax < RangeBtmMax)
				{
					RangeBtmMax := TmpMax
				}
			}
			
			If(TmpMax >= RangeTopMax)
			{
				If(TmpMax > RangeTopMax)
				{
					RangeTopMax := TmpMax
					RangeTopMin := TmpMin
				}
				Else If(TmpMin > RangeTopMin)
				{
					RangeTopMin := TmpMin
				}
			}
		}
		
		--b
		t := t_RestartIndex
		t_RestartIndex := 0
	}
	
	result := []
	result[1] := RangeBtmMin . "-" . RangeBtmMax . "|" . RangeTopMin . "-" . RangeTopMax
	result[2] := 0
	result[3] := Mod1DataArray[Mod1DataArray.MaxIndex()].min + Mod2DataArray[Mod2DataArray.MaxIndex()].min . "-" . Mod1DataArray[1].max + Mod2DataArray[1].max
	result[4] := (Mod1DataArray[1].ilvl > Mod2DataArray[1].ilvl) ? Mod1DataArray[1].ilvl : Mod2DataArray[1].ilvl
	
	return result
}

SolveAffixes_Mod1Mod2Hyb(Keyname, LineNum1, LineNum2, Value1, Value2, Mod1Type, Mod2Type, HybType, Filename1, Filename2, FilenameHyb1, FilenameHyb2, ItemLevel)
{
	Global Itemdata
	Itemdata.UncertainAffixes[Keyname] := {}
	
	Mod1DataArray := ArrayFromDatafile(Filename1)
	Mod2DataArray := ArrayFromDatafile(Filename2)
	Hyb1DataArray := ArrayFromDatafile(FilenameHyb1)
	Hyb2DataArray := ArrayFromDatafile(FilenameHyb2)
	
	Mod1Tiers := LookupTierByValue(Value1, Mod1DataArray, ItemLevel)
	Mod2Tiers := LookupTierByValue(Value2, Mod2DataArray, ItemLevel)
	Hyb1Tiers := LookupTierByValue(Value1, Hyb1DataArray, ItemLevel)
	Hyb2Tiers := LookupTierByValue(Value2, Hyb2DataArray, ItemLevel)
	
	Mod1HybTiers := SolveTiers_ModHyb(Value1, Value2, Mod1DataArray, Hyb1DataArray, Hyb2DataArray, ItemLevel)
	Mod2HybTiers := SolveTiers_ModHyb(Value2, Value1, Mod2DataArray, Hyb2DataArray, Hyb1DataArray, ItemLevel)
	
	Mod1Mod2HybTiers := SolveTiers_Mod1Mod2Hyb(Value1, Value2, Mod1DataArray, Mod2DataArray, Hyb1DataArray, Hyb2DataArray, ItemLevel)
	
	If(Mod1Tiers.Tier and Mod2Tiers.Tier)
	{
		PrefixCount := 0
		SuffixCount := 0
		PrefixCount += (Mod1Type ~= "Prefix") ? 1 : 0
		PrefixCount += (Mod2Type ~= "Prefix") ? 1 : 0
		SuffixCount += (Mod1Type ~= "Suffix") ? 1 : 0
		SuffixCount += (Mod2Type ~= "Suffix") ? 1 : 0
		
		ValueRange1 := GetValueRangeIlvlFormat(Mod1DataArray, Mod1Tiers.Tier)
		LineTxt1 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum1].Text, Mod1Type, ValueRange1, Mod1Tiers.Tier, False)
		
		ValueRange2 := GetValueRangeIlvlFormat(Mod2DataArray, Mod2Tiers.Tier)
		LineTxt2 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum2].Text, Mod2Type, ValueRange2, Mod2Tiers.Tier, False)
		
		Itemdata.UncertainAffixes[Keyname][1] := [PrefixCount, SuffixCount, LineNum1, LineTxt1, LineNum2, LineTxt2]
	}
	
	If(Hyb1Tiers.Tier and Hyb2Tiers.Tier and (Hyb1Tiers.Tier = Hyb2Tiers.Tier))
	{
		PrefixCount := 0
		SuffixCount := 0
		PrefixCount += (HybType ~= "Hybrid Prefix") ? 1 : 0
		SuffixCount += (HybType ~= "Hybrid Prefix") ? 1 : 0
		
		ValueRange1 := GetValueRangeIlvlFormat(Hyb1DataArray, Hyb1Tiers.Tier)
		LineTxt1 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum1].Text, HybType, ValueRange1, Hyb1Tiers.Tier, False)
		
		ValueRange2 := GetValueRangeIlvlFormat(Hyb2DataArray, Hyb2Tiers.Tier)
		LineTxt2 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum2].Text, HybType, ValueRange2, Hyb2Tiers.Tier, False)
		
		Itemdata.UncertainAffixes[Keyname][2] := [PrefixCount, SuffixCount, LineNum1, LineTxt1, LineNum2, LineTxt2]
	}
	
	If(IsObject(Mod1HybTiers))
	{
		PrefixCount := 0
		SuffixCount := 0
		PrefixCount += (Mod1Type ~= "Prefix") ? 1 : 0
		PrefixCount += (HybType ~= "Hybrid Prefix") ? 1 : 0
		SuffixCount += (Mod1Type ~= "Suffix") ? 1 : 0
		SuffixCount += (HybType ~= "Hybrid Suffix") ? 1 : 0
		
		ValueRange1 := GetValueRangeIlvlFormat(Mod1DataArray, [Mod1HybTiers.ModTop, Mod1HybTiers.ModBtm], Hyb1DataArray, Mod1HybTiers.Hyb)
		LineTxt1 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum1].Text, [Mod1Type, HybType], ValueRange1, [[Mod1HybTiers.ModTop, Mod1HybTiers.ModBtm], Mod1HybTiers.Hyb], False)
		
		ValueRange2 := GetValueRangeIlvlFormat(Hyb2DataArray, Hyb2Tiers.Tier)
		LineTxt2 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum2].Text, HybType, ValueRange2, Mod1HybTiers.Hyb, False)
		
		Itemdata.UncertainAffixes[Keyname][3] := [PrefixCount, SuffixCount, LineNum1, LineTxt1, LineNum2, LineTxt2]
	}
	
	If(IsObject(Mod2HybTiers))
	{
		PrefixCount := 0
		SuffixCount := 0
		PrefixCount += (Mod2Type ~= "Prefix") ? 1 : 0
		PrefixCount += (HybType ~= "Hybrid Prefix") ? 1 : 0
		SuffixCount += (Mod2Type ~= "Suffix") ? 1 : 0
		SuffixCount += (HybType ~= "Hybrid Suffix") ? 1 : 0
		
		ValueRange1 := GetValueRangeIlvlFormat(Hyb1DataArray, Hyb1Tiers.Tier)
		LineTxt1 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum1].Text, HybType, ValueRange1, Mod2HybTiers.Hyb, False)
		
		ValueRange2 := GetValueRangeIlvlFormat(Mod2DataArray, [Mod2HybTiers.ModTop, Mod2HybTiers.ModBtm], Hyb2DataArray, Mod2HybTiers.Hyb)
		LineTxt2 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum2].Text, [Mod2Type, HybType], ValueRange2, [[Mod2HybTiers.ModTop, Mod2HybTiers.ModBtm], Mod2HybTiers.Hyb], False)
		
		Itemdata.UncertainAffixes[Keyname][4] := [PrefixCount, SuffixCount, LineNum1, LineTxt1, LineNum2, LineTxt2]
	}
	
	If(IsObject(Mod1Mod2HybTiers))
	{
		PrefixCount := 0
		SuffixCount := 0
		PrefixCount += (Mod1Type ~= "Prefix") ? 1 : 0
		PrefixCount += (Mod2Type ~= "Prefix") ? 1 : 0
		PrefixCount += (HybType ~= "Hybrid Prefix") ? 1 : 0
		SuffixCount += (Mod1Type ~= "Suffix") ? 1 : 0
		SuffixCount += (Mod2Type ~= "Suffix") ? 1 : 0
		SuffixCount += (HybType ~= "Hybrid Suffix") ? 1 : 0
		
		ValueRange1 := GetValueRangesWithinTiers(Value1, Mod1DataArray, Hyb1DataArray, Mod1Mod2HybTiers.Mod1Top, Mod1Mod2HybTiers.Mod1Btm, Mod1Mod2HybTiers.HybTop, Mod1Mod2HybTiers.HybBtm)
		LineTxt1 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum1].Text, [Mod1Type, HybType], ValueRange1, [[Mod1Mod2HybTiers.Mod1Top, Mod1Mod2HybTiers.Mod1Btm], [Mod1Mod2HybTiers.HybTop, Mod1Mod2HybTiers.HybBtm]], False)
		
		ValueRange2 := GetValueRangesWithinTiers(Value2, Mod2DataArray, Hyb2DataArray, Mod1Mod2HybTiers.Mod2Top, Mod1Mod2HybTiers.Mod2Btm, Mod1Mod2HybTiers.HybTop, Mod1Mod2HybTiers.HybBtm)
		LineTxt2 := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum2].Text, [Mod2Type, HybType], ValueRange2, [[Mod1Mod2HybTiers.Mod2Top, Mod1Mod2HybTiers.Mod2Btm], [Mod1Mod2HybTiers.HybTop, Mod1Mod2HybTiers.HybBtm]], False)
		
		Itemdata.UncertainAffixes[Keyname][5] := [PrefixCount, SuffixCount, LineNum1, LineTxt1, LineNum2, LineTxt2]
	}
}

SolveAffixes_PreSuf(Keyname, LineNum, Value, Filename1, Filename2, ItemLevel)
{
	Global Itemdata, AffixTotals
	Itemdata.UncertainAffixes[Keyname] := {}
	
	Mod1DataArray := ArrayFromDatafile(Filename1)
	Mod2DataArray := ArrayFromDatafile(Filename2)
	
	Mod1Tiers := LookupTierByValue(Value, Mod1DataArray, ItemLevel)
	Mod2Tiers := LookupTierByValue(Value, Mod2DataArray, ItemLevel)
	Mod1Mod2Tiers := SolveTiers_Mod1Mod2(Value, Mod1DataArray, Mod2DataArray, ItemLevel)
	
	If(Mod1Tiers.Tier)
	{
		ValueRange := GetValueRangeIlvlFormat(Mod1DataArray, Mod1Tiers.Tier)
		LineTxt := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum].Text, "Prefix", ValueRange, Mod1Tiers.Tier, False)
		Itemdata.UncertainAffixes[Keyname][1] := [1, 0, LineNum, LineTxt]
	}
	
	If(Mod2Tiers.Tier)
	{
		ValueRange := GetValueRangeIlvlFormat(Mod2DataArray, Mod2Tiers.Tier)
		LineTxt := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum].Text, "Suffix", ValueRange, Mod2Tiers.Tier, False)
		Itemdata.UncertainAffixes[Keyname][2] := [0, 1, LineNum, LineTxt]
	}
	
	If(IsObject(Mod1Mod2Tiers))
	{
		ValueRange := GetValueRangesWithinTiers(Value, Mod1DataArray, Mod2DataArray, Mod1Mod2Tiers.Mod1Top, Mod1Mod2Tiers.Mod1Btm, Mod1Mod2Tiers.Mod2Top, Mod1Mod2Tiers.Mod2Btm)
		LineTxt := MakeAffixDetailLine(Itemdata.AffixTextLines[LineNum].Text, ["Prefix", "Suffix"], ValueRange, [[Mod1Mod2Tiers.Mod1Top, Mod1Mod2Tiers.Mod1Btm] , [Mod1Mod2Tiers.Mod2Top, Mod1Mod2Tiers.Mod2Btm]], False)
		Itemdata.UncertainAffixes[Keyname][3] := [1, 1, LineNum, LineTxt]
	}
}

ParseAffixes(ItemDataAffixes, Item)
{
	Global Globals, Opts, AffixTotals, AffixLines, Itemdata
	
	ItemDataChunk	:= ItemDataAffixes
	
	IfInString, ItemDataChunk, Unidentified
	{
		Return ; Not interested in unidentified items
	}
	
	ItemBaseType		:= Item.BaseType
	ItemSubType		:= Item.SubType
	ItemGripType		:= Item.GripType
	ItemLevel			:= Item.Level
	ItemQuality		:= Item.Quality
	ItemIsHybridArmour	:= Item.IsHybridArmour
	
	; Reset the AffixLines "array" and other vars
	ResetAffixDetailVars()
	
	; Composition flags
	;
	; The pre-pass loop sets line numbers or markers for potentially ambiguous affixes,
	; so that the composition of these affixes can be checked later.
	
	If ( ! Item.IsJewel)
	{
		HasToArmour			:= 0
		HasToEvasion			:= 0
		HasToEnergyShield		:= 0
		HasToMaxLife			:= 0
		HasToArmourCraft		:= 0
		HasToEvasionCraft		:= 0
		HasToEnergyShieldCraft	:= 0
		HasToMaxLifeCraft		:= 0
		
		HasIncrArmour			:= 0
		HasIncrEvasion			:= 0
		HasIncrEnergyShield		:= 0
		HasStunBlockRecovery	:= 0
		HasIncrArmourCraft		:= 0
		HasIncrEvasionCraft		:= 0
		HasIncrEnergyShieldCraft	:= 0
		
		HasIncrArmourAndES			:= 0
		HasIncrArmourAndEvasion		:= 0
		HasIncrEvasionAndES			:= 0
		HasIncrArmourAndESCraft		:= 0
		HasIncrArmourAndEvasionCraft	:= 0
		HasIncrEvasionAndESCraft		:= 0
		
		HasToAccuracyRating		:= 0
		HasIncrPhysDmg			:= 0
		HasIncrLightRadius		:= 0
		HasToAccuracyRatingCraft	:= 0
		HasIncrPhysDmgCraft		:= 0
		
		HasIncrRarity			:= 0
		HasIncrRarityCraft		:= 0
		
		HasMaxMana			:= 0
		HasMaxManaCraft		:= 0
		
		HasIncrSpellDamage		:= 0
		HasIncrFireDamage		:= 0
		HasIncrColdDamage		:= 0
		HasIncrLightningDamage	:= 0
		HasIncrSpellDamageCraft		:= 0
		HasIncrFireDamageCraft		:= 0
		HasIncrColdDamageCraft		:= 0
		HasIncrLightningDamageCraft	:= 0
		
		HasIncrSpellDamagePrefix	:= 0
		HasIncrSpellOrElePrefix	:= 0
		
		
		HasMultipleCrafted		:= 0
		HasLastLineNumber		:= 0
		
		
		
		; --- PRE-PASS ---
		Loop, Parse, ItemDataChunk, `n, `r
		{
			If StrLen(A_LoopField) = 0
			{
				Continue ; Not interested in blank lines
			}
			
			Itemdata.AffixTextLines.Push( {"Text":A_LoopField, "Value":GetActualValue(A_LoopField)} )
			; AffixTextLines[1].Text stores the full text of the first line (yes, with index 1 and not 0)
			; AffixTextLines[1].Value stores just the extracted value
			
			++HasLastLineNumber		; Counts the affix text lines so that the last line can be checked for being a craft
			
			IfInString, A_LoopField, to Armour
			{
				If(HasToArmour){
					HasToArmourCraft := A_Index
				}Else{
					HasToArmour := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, to Evasion Rating
			{
				If(HasToEvasion){
					HasToEvasionCraft := A_Index
				}Else{
					HasToEvasion := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, to Energy Shield
			{
				If(HasToEnergyShield){
					HasToEnergyShieldCraft := A_Index
				}Else{
					HasToEnergyShield := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, to maximum Life
			{
				If(HasToMaxLife){
					HasToMaxLifeCraft := A_Index
				}Else{
					HasToMaxLife := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Armour and Evasion	; it's indeed "Evasion" and not "Evasion Rating" here
			{
				If(HasIncrArmourAndEvasion){
					HasIncrArmourAndEvasionCraft := A_Index
				}Else{
					HasIncrArmourAndEvasion := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Armour and Energy Shield
			{
				If(HasIncrArmourAndES){
					HasIncrArmourAndESCraft := A_Index
				}Else{
					HasIncrArmourAndES := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Evasion and Energy Shield	; again "Evasion" and not "Evasion Rating"
			{
				If(HasIncrEvasionAndES){
					HasIncrEvasionAndESCraft := A_Index
				}Else{
					HasIncrEvasionAndES := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Armour
			{
				If(HasIncrArmour){
					HasIncrArmourCraft := A_Index
				}Else{
					HasIncrArmour := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Evasion Rating
			{
				If(HasIncrEvasion){
					HasIncrEvasionCraft := A_Index
				}Else{
					HasIncrEvasion := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Energy Shield
			{
				If(HasIncrEnergyShield){
					HasIncrEnergyShieldCraft := A_Index
				}Else{
					HasIncrEnergyShield := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Stun and Block Recovery
			{
				HasStunBlockRecovery := A_Index
				Continue
			}
			IfInString, A_LoopField, increased Light Radius
			{
				HasIncrLightRadius := A_Index
				Continue
			}
			IfInString, A_LoopField, increased Accuracy Rating
			{
				HasIncrAccuracyRating := A_Index
				Continue
			}
			IfInString, A_LoopField, to Accuracy Rating
			{
				If(HasToAccuracyRating){
					HasToAccuracyRatingCraft := A_Index
				}Else{
					HasToAccuracyRating := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Physical Damage
			{
				If(HasIncrPhysDmg){
					HasIncrPhysDmgCraft := A_Index
				}Else{
					HasIncrPhysDmg := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Rarity of Items found
			{
				If(HasIncrRarity){
					HasIncrRarityCraft := A_Index
				}Else{
					HasIncrRarity := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, to maximum Mana
			{
				If(HasMaxMana){
					HasMaxManaCraft := A_Index
				}Else{
					HasMaxMana := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Spell Damage
			{
				If(HasIncrSpellDamage){
					HasIncrSpellDamageCraft := A_Index
					HasIncrSpellDamagePrefix := HasIncrSpellDamageCraft
					HasIncrSpellOrElePrefix := HasIncrSpellDamagePrefix
				}Else{
					HasIncrSpellDamage := A_Index
				}
				Continue
			}
			/*
			IfInString, A_LoopField, increased Fire Damage
			{
				If(HasIncrFireDamage){
					HasIncrFireDamageCraft := A_Index
					HasIncrFireDamagePrefix := HasIncrFireDamage
					HasIncrSpellOrElePrefix := HasIncrFireDamagePrefix
				}Else{
					HasIncrFireDamage := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Cold Damage
			{
				If(HasIncrColdDamage){
					HasIncrColdDamageCraft := A_Index
					HasIncrColdDamagePrefix := HasIncrColdDamage
					HasIncrSpellOrElePrefix := HasIncrColdDamagePrefix
				}Else{
					HasIncrColdDamage := A_Index
				}
				Continue
			}
			IfInString, A_LoopField, increased Lightning Damage
			{
				If(HasIncrLightningDamage){
					HasIncrLightningDamageCraft := A_Index
					HasIncrLightningDamagePrefix := HasIncrLightningDamage
					HasIncrSpellOrElePrefix := HasIncrLightningDamagePrefix
				}Else{
					HasIncrLightningDamage := A_Index
				}
				Continue
			}
			*/
			
			
			
			; GetActualValue(A_LoopField)
			
			IfInString, A_Loopfield, Can have multiple Crafted Mods
			{
				HasMultipleCrafted := A_Index
				Continue
			}
		}
	}
	Else
	{
		; Jewels get their own Pre-Pass
		
		; --- PRE-PASS ---
		Loop, Parse, ItemDataChunk, `n, `r
		{
			If StrLen(A_LoopField) = 0
			{
				Continue ; Not interested in blank lines
			}
			
			Itemdata.AffixTextLines.Push( {"Text":A_LoopField, "Value":GetActualValue(A_LoopField)} )
			
			++HasLastLineNumber
		}
		
	}
	
	; Prepare AffixLines. If a line isn't matched, it will later be recognized as unmatched because the entry is empty instead of undefined.
	Loop, %HasLastLineNumber%
	{
		AffixLines.Set(A_Index, "")
	}
	
	
	; --- SIMPLE AFFIXES ---
	
	Loop, Parse, ItemDataChunk, `n, `r
	{
		If StrLen(A_LoopField) = 0
		{
			Continue ; Not interested in blank lines
		}
		IfInString, ItemDataChunk, Unidentified
		{
			Break ; Not interested in unidentified items
		}
		
		CurrValue := GetActualValue(A_LoopField)
		CurrTier := 0
		
		
		; --- SIMPLE JEWEL AFFIXES ---
		
		If (Item.IsJewel)
		{
			IfInString, A_LoopField, increased Area Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\AreaDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Attack and Cast Speed
			{
				LookupAffixAndSetInfoLine("data\jewel\AttackAndCastSpeed.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased Attack Speed with (One|Two) Handed Melee Weapons")
			{
				LookupAffixAndSetInfoLine("data\jewel\AttackSpeedWith1H2HMelee.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Attack Speed while holding a Shield
			{
				LookupAffixAndSetInfoLine("data\jewel\AttackSpeedWhileHoldingShield.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Attack Speed while Dual Wielding
			{
				LookupAffixAndSetInfoLine("data\jewel\AttackSpeedWhileDualWielding.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased Attack Speed with (Axes|Bows|Claws|Daggers|Maces|Staves|Swords|Wands)")
			{
				LookupAffixAndSetInfoLine("data\jewel\AttackSpeedWithWeapontype.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			
			; Pure Attack Speed must be checked last if RegEx line end isn't used
			If RegExMatch(A_LoopField, ".*increased Attack Speed$")
			{
				LookupAffixAndSetInfoLine("data\jewel\AttackSpeed_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			
			IfInString, A_LoopField, increased Accuracy Rating
			{
				If(Item.SubType = "Cobalt Jewel" or Item.SubType = "Crimson Jewel")
				{
					; Cobalt and Crimson jewels can't get the combined increased accuracy/crit chance affix
					LookupAffixAndSetInfoLine("data\jewel\IncrAccuracyRating_Jewels.txt", "Suffix", ItemLevel, CurrValue)
					Continue
				}
				Else
				{
					; increased Accuracy Rating on Viridian and Prismatic jewels is a complex affix and handled later
					Continue
				}
			}
			
			IfInString, A_LoopField, to all Attributes
			{
				LookupAffixAndSetInfoLine("data\jewel\ToAllAttributes_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			
			If RegExMatch(A_LoopField, ".*to (Strength|Dexterity|Intelligence) and (Strength|Dexterity|Intelligence)")
			{
				LookupAffixAndSetInfoLine("data\jewel\To2Attributes_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*to (Strength|Dexterity|Intelligence)")
			{
				LookupAffixAndSetInfoLine("data\jewel\To1Attribute_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased Cast Speed (with|while) .*")
			{
				LookupAffixAndSetInfoLine("data\jewel\CastSpeedWithWhile.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			
			; pure Cast Speed must be checked last if RegEx line end isn't used
			If RegExMatch(A_LoopField, ".*increased Cast Speed$")
			{
				LookupAffixAndSetInfoLine("data\jewel\CastSpeed_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Critical Strike Chance for Spells
			{
				LookupAffixAndSetInfoLine("data\jewel\CritChanceSpells_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Melee Critical Strike Chance
			{
				LookupAffixAndSetInfoLine("data\jewel\MeleeCritChance.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Critical Strike Chance with Elemental Skills
			{
				LookupAffixAndSetInfoLine("data\jewel\CritChanceElementalSkills.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased Critical Strike Chance with (Fire|Cold|Lightning) Skills")
			{
				LookupAffixAndSetInfoLine("data\jewel\CritChanceFireColdLightningSkills.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased Critical Strike Chance with (One|Two) Handed Melee Weapons")
			{
				LookupAffixAndSetInfoLine("data\jewel\CritChanceWith1H2HMelee.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Weapon Critical Strike Chance while Dual Wielding
			{
				LookupAffixAndSetInfoLine("data\jewel\WeaponCritChanceDualWielding.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			
			IfInString, A_LoopField, increased Global Critical Strike Chance
			{
				If (Item.SubType = "Cobalt Jewel" or Item.SubType = "Crimson Jewel" )
				{
					; Cobalt and Crimson jewels can't get the combined increased accuracy/crit chance affix
					LookupAffixAndSetInfoLine("data\jewel\CritChanceGlobal_Jewels.txt", "Suffix", ItemLevel, CurrValue)
					Continue
				}
				Else
				{
					; Crit chance on Viridian and Prismatic Jewels is a complex affix that is handled later
					Continue
				}
			}
			
			IfInString, A_LoopField, to Melee Critical Strike Multiplier
			{
				LookupAffixAndSetInfoLine("data\jewel\CritMeleeMultiplier.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, to Critical Strike Multiplier for Spells
			{
				LookupAffixAndSetInfoLine("data\jewel\CritMultiplierSpells.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, to Critical Strike Multiplier with Elemental Skills
			{
				LookupAffixAndSetInfoLine("data\jewel\CritMultiplierElementalSkills.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*to Critical Strike Multiplier with (Fire|Cold|Lightning) Skills")
			{
				LookupAffixAndSetInfoLine("data\jewel\CritMultiplierFireColdLightningSkills.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*to Critical Strike Multiplier with (One|Two) Handed Melee Weapons")
			{
				LookupAffixAndSetInfoLine("data\jewel\CritMultiplierWith1H2HMelee.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, to Critical Strike Multiplier while Dual Wielding
			{
				LookupAffixAndSetInfoLine("data\jewel\CritMultiplierWhileDualWielding.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, Critical Strike Multiplier
			{
				LookupAffixAndSetInfoLine("data\jewel\CritMultiplierGlobal_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Ignite
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToIgnite.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Ignite Duration on Enemies
			{
				LookupAffixAndSetInfoLine("data\jewel\IgniteDurationOnEnemies.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Freeze
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToFreeze.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Freeze Duration on Enemies
			{
				LookupAffixAndSetInfoLine("data\jewel\FreezeDurationOnEnemies.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Shock
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToShock.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Shock Duration on Enemies
			{
				LookupAffixAndSetInfoLine("data\jewel\ShockDurationOnEnemies.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Poison
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToPoison.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Poison Duration
			{
				LookupAffixAndSetInfoLine("data\jewel\PoisonDurationOnEnemies.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to cause Bleeding
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToBleed.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Bleed duration
			{
				LookupAffixAndSetInfoLine("data\jewel\BleedingDurationOnEnemies.txt", "Hybrid Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Burning Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrBurningDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Damage with Bleeding
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrBleedingDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Damage with Poison
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrPoisonDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased (Fire|Cold|Lightning) Damage")
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrFireColdLightningDamage_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, "Minions have .* Chance to Block")
			{
				LookupAffixAndSetInfoLine("data\jewel\MinionBlockChance.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*(Chance to Block|Block Chance).*")
			{
				LookupAffixAndSetInfoLine("data\jewel\BlockChance_ChanceToBlock_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Damage over Time
			{
				LookupAffixAndSetInfoLine("data\jewel\DamageOverTime.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, "Minions deal .* increased Damage")
			{
				LookupAffixAndSetInfoLine("data\jewel\MinionsDealIncrDamage.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased Damage$")
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Knock Enemies Back on hit
			{
				LookupAffixAndSetInfoLine("data\jewel\KnockBackOnHit.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, Life gained for each Enemy hit by your Attacks
			{
				LookupAffixAndSetInfoLine("data\jewel\LifeOnHit_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, Energy Shield gained for each Enemy hit by your Attacks
			{
				LookupAffixAndSetInfoLine("data\jewel\ESOnHit.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, Mana gained for each Enemy hit by your Attacks
			{
				LookupAffixAndSetInfoLine("data\jewel\ManaOnHit.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, reduced Mana Cost of Skills
			{
				LookupAffixAndSetInfoLine("data\jewel\ReducedManaCost.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Mana Regeneration Rate
			{
				LookupAffixAndSetInfoLine("data\jewel\ManaRegen_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Melee Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\MeleeDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Projectile Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\ProjectileDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Projectile Speed
			{
				LookupAffixAndSetInfoLine("data\jewel\ProjectileSpeed_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, to all Elemental Resistances
			{
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
				LookupAffixAndSetInfoLine("data\jewel\To2Resist_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*to (Fire|Cold|Lightning) Resistance")
			{
				LookupAffixAndSetInfoLine("data\jewel\To1Resist_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, to Chaos Resistance
			{
				LookupAffixAndSetInfoLine("data\jewel\ToChaosResist_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Stun Duration on Enemies
			{
				LookupAffixAndSetInfoLine("data\jewel\StunDuration_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased Physical Damage with (Axes|Bows|Claws|Daggers|Maces|Staves|Swords|Wands)")
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrPhysDamageWithWeapontype.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Melee Physical Damage while holding a Shield
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrMeleePhysDamageWhileHoldingShield.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Physical Weapon Damage while Dual Wielding
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrPhysWeaponDamageDualWielding.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			If RegExMatch(A_LoopField, ".*increased Physical Damage with (One|Two) Handed Melee Weapons")
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrPhysDamageWith1H2HMelee.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Physical Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrPhysDamage_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Totem Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrTotemDamage.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Totem Life
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrTotemLife.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Trap Throwing Speed
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrTrapThrowingSpeed.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Trap Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrTrapDamage.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Mine Laying Speed
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrMineLayingSpeed.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Mine Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrMineDamage.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Chaos Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrChaosDamage.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			If ( InStr(A_LoopField,"increased maximum Life"))
			{
				If InStr(A_LoopField,"Minions have")
				{
					FilePath := "data\jewel\MinionIncrMaximumLife.txt"
				}
				Else
				{
					FilePath := "data\jewel\IncrMaximumLife.txt"
				}
				LookupAffixAndSetInfoLine(FilePath, "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Armour
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrArmour_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Evasion Rating
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrEvasion_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Energy Shield Recharge Rate
			{
				LookupAffixAndSetInfoLine("data\jewel\EnergyShieldRechargeRate.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, faster start of Energy Shield Recharge
			{
				LookupAffixAndSetInfoLine("data\jewel\FasterStartOfEnergyShieldRecharge.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased maximum Energy Shield
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrMaxEnergyShield_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, Physical Attack Damage Leeched as
			{
				LookupAffixAndSetInfoLine("data\jewel\PhysicalAttackDamageLeeched_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Spell Damage while Dual Wielding
			{
				LookupAffixAndSetInfoLine("data\jewel\SpellDamageDualWielding_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Spell Damage while holding a Shield
			{
				LookupAffixAndSetInfoLine("data\jewel\SpellDamageHoldingShield_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Spell Damage while wielding a Staff
			{
				LookupAffixAndSetInfoLine("data\jewel\SpellDamageWieldingStaff_Jewels.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Spell Damage
			{
				LookupAffixAndSetInfoLine("data\jewel\SpellDamage_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased maximum Mana
			{
				LookupAffixAndSetInfoLine("data\jewel\IncrMaximumMana_Jewel.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Stun and Block Recovery
			{
				LookupAffixAndSetInfoLine("data\jewel\StunRecovery_Suffix_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Rarity
			{
				LookupAffixAndSetInfoLine("data\jewel\IIR_Suffix_Jewels.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
		} ; End of Jewel Affixes
		
		
		
		
		; Suffixes
		
		IfInString, A_LoopField, increased Attack Speed
		{
			If (ItemSubType == "Wand" or ItemSubType == "Bow")
			{
				ValueRange := LookupAffixData("data\AttackSpeed_BowsAndWands.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (ItemBaseType == "Weapon")
			{
				ValueRange := LookupAffixData("data\AttackSpeed_Weapons.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (ItemSubType == "Shield")
			{
				ValueRange := LookupAffixData("data\AttackSpeed_Shield.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else
			{
				ValueRange := LookupAffixData("data\AttackSpeed_ArmourAndItems.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		
		IfInString, A_LoopField, increased Accuracy Rating
		{
			ValueRange := LookupAffixData("data\IncrAccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Hybrid Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		
		IfInString, A_LoopField, to all Attributes
		{
			LookupAffixAndSetInfoLine("data\ToAllAttributes.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		
		If RegExMatch(A_LoopField, ".*to (Strength|Dexterity|Intelligence)")
		{
			LookupAffixAndSetInfoLine("data\To1Attribute.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		
		IfInString, A_LoopField, increased Cast Speed
		{
			If (ItemGripType == "1H") {
				; wands and scepters
				ValueRange := LookupAffixData("data\CastSpeed_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (ItemGripType == "2H") {
				; staves
				ValueRange := LookupAffixData("data\CastSpeed_2H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (Item.IsAmulet) {
				ValueRange := LookupAffixData("data\CastSpeedAmulet.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (Item.IsRing) {
				ValueRange := LookupAffixData("data\CastSpeedRing.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (ItemSubtype == "Shield") {
				; The native mod only appears on bases with ES
				ValueRange := LookupAffixData("data\CastSpeedShield.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else {
				; All shields can receive a cast speed master mod.
				; Leaving this as non shield specific if the master mod ever becomes applicable on something else
				ValueRange := LookupAffixData("data\CastSpeedCraft.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		
		IfInString, A_LoopField, increased Critical Strike Chance for Spells
		{
			LookupAffixAndSetInfoLine("data\CritChanceSpells.txt", "Suffix", ItemLevel, CurrValue)
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
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		
		IfInString, A_LoopField, Critical Strike Multiplier
		{
			If (ItemBaseType == "Weapon")
			{
				ValueRange := LookupAffixData("data\CritMultiplierLocal.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else
			{
				ValueRange := LookupAffixData("data\CritMultiplierGlobal.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, increased Light Radius
		{
			; T1 comes with "increased Accuracy Rating", T2-3 with "to increased Accuracy Rating"
			; This part can always be assigned now. The Accuracy will be solved later in case it's T2-3 and it forms a complex affix.
			ValueRange := LookupAffixData("data\LightRadius_AccuracyRating.txt", ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Hybrid Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, increased Accuracy Rating
		{
			; This variant comes always with Light Radius, see above.
			ValueRange := LookupAffixData("data\IncrAccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Hybrid Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, Chance to Block
		{
			LookupAffixAndSetInfoLine("data\BlockChance.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		; Flask affixes (on belts)
		IfInString, A_LoopField, reduced Flask Charges used
		{
			LookupAffixAndSetInfoLine("data\FlaskChargesUsed.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Flask Charges gained
		{
			LookupAffixAndSetInfoLine("data\FlaskChargesGained.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Flask effect duration
		{
			LookupAffixAndSetInfoLine("data\FlaskDuration.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		
		IfInString, A_LoopField, increased Quantity of Items found
		{
			LookupAffixAndSetInfoLine("data\IncrQuantity.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Life gained on Kill
		{
			LookupAffixAndSetInfoLine("data\LifeOnKill.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Life gained for each Enemy hit ; Cuts off the rest to accommodate both "by Attacks" and "by your Attacks"
		{
			If (ItemBaseType == "Weapon") {
				ValueRange := LookupAffixData("data\LifeOnHit_Weapon.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else {
				ValueRange := LookupAffixData("data\LifeOnHit_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, of Life Regenerated per second
		{
			LookupAffixAndSetInfoLine("data\LifeRegenPercent.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}		
		IfInString, A_LoopField, Life Regenerated per second
		{
			LookupAffixAndSetInfoLine("data\LifeRegen.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Mana Gained on Kill
		{
			LookupAffixAndSetInfoLine("data\ManaOnKill.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Mana Regeneration Rate
		{
			LookupAffixAndSetInfoLine("data\ManaRegen.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Projectile Speed
		{
			LookupAffixAndSetInfoLine("data\ProjectileSpeed.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, reduced Attribute Requirements
		{
			LookupAffixAndSetInfoLine("data\ReducedAttrReqs.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, to all Elemental Resistances
		{
			LookupAffixAndSetInfoLine("data\ToAllResist.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, to Fire Resistance
		{
			LookupAffixAndSetInfoLine("data\ToFireResist.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, to Cold Resistance
		{
			LookupAffixAndSetInfoLine("data\ToColdResist.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, to Lightning Resistance
		{
			LookupAffixAndSetInfoLine("data\ToLightningResist.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, to Chaos Resistance
		{
			LookupAffixAndSetInfoLine("data\ToChaosResist.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Stun Duration on Enemies
		{
			LookupAffixAndSetInfoLine("data\StunDuration.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, reduced Enemy Stun Threshold
		{
			LookupAffixAndSetInfoLine("data\StunThreshold.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, additional Physical Damage Reduction
		{
			LookupAffixAndSetInfoLine("data\AdditionalPhysicalDamageReduction.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, chance to Dodge Attacks
		{
			If (ItemSubtype == "BodyArmour")
			{
				LookupAffixAndSetInfoLine("data\ChanceToDodgeAttacks_BodyArmour.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			Else If (ItemSubtype == "Shield")
			{
				LookupAffixAndSetInfoLine("data\ChanceToDodgeAttacks_Shield.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
		}
		IfInString, A_LoopField, of Energy Shield Regenerated per second
		{
			LookupAffixAndSetInfoLine("data\EnergyShieldRegeneratedPerSecond.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, additional Block Chance against Projectiles
		{
			LookupAffixAndSetInfoLine("data\AdditionalBlockChanceAgainstProjectiles.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, chance to Avoid being Stunned
		{
			LookupAffixAndSetInfoLine("data\ChanceToAvoidBeingStunned.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, chance to Avoid Elemental Ailments
		{
			LookupAffixAndSetInfoLine("data\ChanceToAvoidElementalAilments.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, chance to Dodge Spell Damage
		{
			LookupAffixAndSetInfoLine("data\ChanceToDodgeSpellDamage.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Chance to Block Spells
		{
			LookupAffixAndSetInfoLine("data\ChanceToBlockSpells.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Life gained when you Block
		{
			LookupAffixAndSetInfoLine("data\LifeOnBlock.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Mana gained when you Block
		{
			LookupAffixAndSetInfoLine("data\ManaOnBlock.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Attack and Cast Speed
		{
			LookupAffixAndSetInfoLine("data\AttackAndCastSpeed_Shield.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		If (ItemBaseType == "Weapon")
		{
			IfInString, A_LoopField, Chance to Ignite
			{
				LookupAffixAndSetInfoLine("data\ChanceToIgnite.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, Chance to Freeze
			{
				LookupAffixAndSetInfoLine("data\ChanceToFreeze.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, Chance to Shock
			{
				LookupAffixAndSetInfoLine("data\ChanceToShock.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to cause Bleeding on Hit
			{
				If(CurrValue = 25)
				{
					; Vagan/Tora prefix
					AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Prefix", "Vgn7|Buy:Tora4", ""), A_Index)
					Continue
				}
				
				LookupAffixAndSetInfoLine("data\ChanceToBleed.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Poison on Hit
			{
				LookupAffixAndSetInfoLine("data\ChanceToPoison.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Burning Damage
			{
				LookupAffixAndSetInfoLine("data\IncrBurningDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Damage with Poison
			{
				LookupAffixAndSetInfoLine("data\IncrPoisonDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Damage with Bleeding
			{
				LookupAffixAndSetInfoLine("data\IncrBleedingDamage.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Poison Duration
			{
				LookupAffixAndSetInfoLine("data\PoisonDuration.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Bleed duration
			{
				LookupAffixAndSetInfoLine("data\BleedDuration.txt", "Suffix", ItemLevel, CurrValue)
				Continue
			}
		}
		
		
		; Prefixes
		
		If RegExMatch(A_LoopField, "Adds \d+? to \d+? Physical Damage")
		{
			If (ItemBaseType == "Weapon")
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
			Else If (ItemSubType == "Amulet")
			{
				ValueRange := LookupAffixData("data\AddedPhysDamage_Amulet.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (ItemSubType == "Quiver")
			{
				ValueRange := LookupAffixData("data\AddedPhysDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (ItemSubType == "Ring")
			{
				ValueRange := LookupAffixData("data\AddedPhysDamage_Ring.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (ItemSubType == "Gloves")
			{
				ValueRange := LookupAffixData("data\AddedPhysDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else
			{
				; There is no Else for rare items. Just lookup in 1H for now...
				ValueRange := LookupAffixData("data\AddedPhysDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			Continue
		}
		
		If RegExMatch(A_LoopField, "Adds \d+? to \d+? Cold Damage")
		{
			If RegExMatch(A_LoopField, "Adds \d+? to \d+? Cold Damage to Spells")
			{
				If (ItemGripType == "1H")
				{
					ValueRange := LookupAffixData("data\SpellAddedCold1H.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\SpellAddedCold2H.txt", ItemLevel, CurrValue, "", CurrTier)
				}
			}
			
			Else If (ItemSubType == "Amulet" or ItemSubType == "Ring")
			{
				ValueRange := LookupAffixData("data\AddedColdDamage_AmuletRing.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Gloves")
			{
				ValueRange := LookupAffixData("data\AddedColdDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Quiver")
			{
				ValueRange := LookupAffixData("data\AddedColdDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemGripType == "1H")
			{
				ValueRange := LookupAffixData("data\AddedColdDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Bow")
			{
				; Added ele damage for bows follows 1H tiers
				ValueRange := LookupAffixData("data\AddedColdDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else
			{
				ValueRange := LookupAffixData("data\AddedColdDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			Continue
		}
		If RegExMatch(A_LoopField, "Adds \d+? to \d+? Fire Damage")
		{
			If RegExMatch(A_LoopField, "Adds \d+? to \d+? Fire Damage to Spells")
			{
				If (ItemGripType == "1H")
				{
					ValueRange := LookupAffixData("data\SpellAddedFire1H.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\SpellAddedFire2H.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				
			}
			Else If (ItemSubType == "Amulet" or ItemSubType == "Ring")
			{
				ValueRange := LookupAffixData("data\AddedFireDamage_AmuletRing.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Gloves")
			{
				ValueRange := LookupAffixData("data\AddedFireDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Quiver")
			{
				ValueRange := LookupAffixData("data\AddedFireDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemGripType == "1H") ; One handed weapons
			{
				ValueRange := LookupAffixData("data\AddedFireDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Bow")
			{
				; Added ele damage for bows follows 1H tiers
				ValueRange := LookupAffixData("data\AddedFireDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else
			{
				ValueRange := LookupAffixData("data\AddedFireDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			Continue
		}
		If RegExMatch(A_LoopField, "Adds \d+? to \d+? Lightning Damage")
		{
			If RegExMatch(A_LoopField, "Adds \d+? to \d+? Lightning Damage to Spells")
			{
				If (ItemGripType == "1H")
				{
					ValueRange := LookupAffixData("data\SpellAddedLightning1H.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\SpellAddedLightning2H.txt", ItemLevel, CurrValue, "", CurrTier)
				}
			}
			
			Else If (ItemSubType == "Amulet" or ItemSubType == "Ring")
			{
				ValueRange := LookupAffixData("data\AddedLightningDamage_AmuletRing.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Gloves")
			{
				ValueRange := LookupAffixData("data\AddedLightningDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Quiver")
			{
				ValueRange := LookupAffixData("data\AddedLightningDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemGripType == "1H") ; One handed weapons
			{
				ValueRange := LookupAffixData("data\AddedLightningDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Bow")
			{
				; Added ele damage for bows follows 1H tiers
				ValueRange := LookupAffixData("data\AddedLightningDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else
			{
				ValueRange := LookupAffixData("data\AddedLightningDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			Continue
		}
		
		If RegExMatch(A_LoopField, "Adds \d+? to \d+? Chaos Damage")
		{
			If (ItemGripType == "1H")
			{
				ValueRange := LookupAffixData("data\AddedChaosDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Bow")
			{
				; Added ele damage for bows follows 1H tiers
				ValueRange := LookupAffixData("data\AddedChaosDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemGripType == "2H")
			{
				ValueRange := LookupAffixData("data\AddedChaosDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else If (ItemSubType == "Amulet" or ItemSubType == "Ring")
			{
				; Master modded prefix
				ValueRange := LookupAffixData("data\AddedChaosDamage_AmuletRing.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			Continue
		}
		
		IfInString, A_LoopField, increased maximum Energy Shield
		{
			; Contrary to %Armour and %Evasion this one has a unique wording due to "maximum" and is clearly from Amulets (or Legacy Rings)
			LookupAffixAndSetInfoLine("data\IncrMaxEnergyShield_Amulet.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		
		IfInString, A_LoopField, Physical Damage to Melee Attackers
		{
			ValueRange	:= LookupAffixData("data\PhysDamagereturn.txt", ItemLevel, CurrValue, "", CurrTier)
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
				If (ItemSubType == "Ring")
				{
					ValueRange := LookupAffixData("data\GemLevel_UnsetRing.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\GemLevel.txt", ItemLevel, CurrValue, "", CurrTier)
				}
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			Continue
		}
		
		IfInString, A_LoopField, Physical Attack Damage Leeched as
		{
			LookupAffixAndSetInfoLine("data\PhysicalAttackDamageLeeched.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Movement Speed
		{
			If (ItemSubType == "Boots")
			{
				LookupAffixAndSetInfoLine("data\MovementSpeed_Boots.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			Else If (ItemSubType == "Belt")
			{
				LookupAffixAndSetInfoLine("data\MovementSpeed_Belt.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
		}
		IfInString, A_LoopField, increased Elemental Damage with Attack Skills
		{
			If (ItemBaseType == "Weapon")
			{
				; Because GGG apparently thought having the exact same iLvls and tiers except for one single percentage point is necessary
				LookupAffixAndSetInfoLine("data\IncrElementalDamageWithAttackSkills_Weapon.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			Else
			{
				LookupAffixAndSetInfoLine("data\IncrElementalDamageWithAttackSkills.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
		}
		; Flask effects (on belts)
		IfInString, A_LoopField, increased Flask Mana Recovery rate
		{
			LookupAffixAndSetInfoLine("data\FlaskManaRecoveryRate.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Flask Life Recovery rate
		{
			LookupAffixAndSetInfoLine("data\FlaskLifeRecoveryRate.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		
		If (ItemSubType == "Shield"){
			IfInString, A_LoopField, increased Physical Damage
			{
				LookupAffixAndSetInfoLine("data\IncrPhysDamage_Shield.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Elemental Damage
			{
				LookupAffixAndSetInfoLine("data\IncrEleDamage_Shield.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Attack Damage
			{
				LookupAffixAndSetInfoLine("data\IncrAttackDamage_Shield.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}
		}
		
		; --- MASTER CRAFT/BUY ONLY AFFIXES ---
		
		; Can be either Leo prefix or jewel suffix. Jewels are checked already, so it's Leo.
		If RegExMatch(A_LoopField, ".*increased Damage$")
		{
			LookupAffixAndSetInfoLine("data\IncrDamageLeo.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Haku prefix
		IfInString, A_LoopField, to Quality of Socketed Support Gems
		{
			LookupAffixAndSetInfoLine("data\GemQuality_Support.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Elreon prefix
		IfInString, A_LoopField, to Mana Cost of Skills
		{
			CurrValue := Abs(CurrValue)	; Turn potentially negative number into positive.
			LookupAffixAndSetInfoLine("data\ManaCostOfSkills.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Vorici prefix
		IfInString, A_LoopField, increased Life Leeched per Second
		{
			LookupAffixAndSetInfoLine("data\LifeLeechedPerSecond.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Tora dual suffixes
		IfInString, A_LoopField, increased Trap Throwing Speed
		{
			LookupAffixAndSetInfoLine("data\IncrTrapThrowingMineLayingSpeed.txt", "Hybrid Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Mine Laying Speed
		{
			LookupAffixAndSetInfoLine("data\IncrTrapThrowingMineLayingSpeed.txt", "Hybrid Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Trap Damage
		{
			LookupAffixAndSetInfoLine("data\IncrTrapMineDamage.txt", "Hybrid Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Mine Damage
		{
			LookupAffixAndSetInfoLine("data\IncrTrapMineDamage.txt", "Hybrid Suffix", ItemLevel, CurrValue)
			Continue
		}
		; Vagan suffix
		IfInString, A_LoopField, to Weapon range
		{
			LookupAffixAndSetInfoLine("data\ToWeaponRange.txt", "Suffix", ItemLevel, CurrValue)
		}
		
		
		; Vagan prefix
		IfInString, A_LoopField, Gems in this item are Supported by Lvl 1 Blood Magic
		{
			AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Prefix", "Vagan 7", ""), A_Index)
			Continue
		}
		; Vagan prefix
		IfInString, A_LoopField, Hits can't be Evaded
		{
			AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Prefix", "Buy:Vagan 4", ""), A_Index)
			Continue
		}
		
		
		; Meta Craft Mods
		
		IfInString, A_LoopField, Can have multiple Crafted Mods
		{
			AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Suffix", "Elreon 8", ""), A_Index)
			Continue
		}
		IfInString, A_LoopField, Prefixes Cannot Be Changed
		{
			AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Suffix", "Haku 8", ""), A_Index)
			Continue
		}
		IfInString, A_LoopField, Suffixes Cannot Be Changed
		{
			AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Prefix", "Tora 8", ""), A_Index)
			Continue
		}
		IfInString, A_LoopField, Cannot roll Attack Mods
		{
			AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Suffix", "Cata 8", ""), A_Index)
			Continue
		}
		IfInString, A_LoopField, Cannot roll Caster Mods
		{
			AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Suffix", "Vagan 8", ""), A_Index)
			Continue
		}
		IfInString, A_LoopField, Cannot roll Mods with Required Lvl above Lvl 28
		{
			AppendAffixInfo(MakeAffixDetailLine(A_Loopfield, "Suffix", "Leo 8", ""), A_Index)
			Continue
		}
	}
	
	
	; --- COMPLEX AFFIXES ---
	
	
	If (HasIncrRarity)
	{
		If (ItemSubType == "Amulet" or ItemSubType == "Ring")
		{
			PrefixFile := "data\IncrRarity_Prefix_AmuletRing.txt"
			SuffixFile := "data\IncrRarity_Suffix_AmuletRingHelmet.txt"
			
			If (HasIncrRarityCraft)
			{
				SuffixFile := "data\IncrRarity_Suffix_Craft.txt"
				
				LineNum := HasIncrRarityCraft
				LineTxt := Itemdata.AffixTextLines[LineNum].Text
				Value   := Itemdata.AffixTextLines[LineNum].Value
				LookupAffixAndSetInfoLine(SuffixFile, "Suffix", ItemLevel, Value, LineTxt, LineNum)
				
				LineNum := HasIncrRarity
				LineTxt := Itemdata.AffixTextLines[LineNum].Text
				Value   := Itemdata.AffixTextLines[LineNum].Value
				LookupAffixAndSetInfoLine(PrefixFile, "Prefix", ItemLevel, Value, LineTxt, LineNum)
			}
			Else
			{
				LineNum := HasIncrRarity
				LineTxt := Itemdata.AffixTextLines[LineNum].Text
				Value   := Itemdata.AffixTextLines[LineNum].Value
				
				SolveAffixes_PreSuf("Rarity", LineNum, Value, PrefixFile, SuffixFile, ItemLevel)
			}
		}
		Else If (ItemSubType == "Helmet")
		{
			PrefixFile := "data\IncrRarity_Prefix_Helmet.txt"
			SuffixFile := "data\IncrRarity_Suffix_AmuletRingHelmet.txt"
			
			LineNum := HasIncrRarity
			LineTxt := Itemdata.AffixTextLines[LineNum].Text
			Value   := Itemdata.AffixTextLines[LineNum].Value
			
			SolveAffixes_PreSuf("Rarity", LineNum, Value, PrefixFile, SuffixFile, ItemLevel)
		}
		Else If (ItemSubType == "Gloves" or ItemSubType == "Boots")
		{
			PrefixFile := "data\IncrRarity_Prefix_GlovesBoots.txt"
			SuffixFile := "data\IncrRarity_Suffix_GlovesBoots.txt"
			
			LineNum := HasIncrRarity
			LineTxt := Itemdata.AffixTextLines[LineNum].Text
			Value   := Itemdata.AffixTextLines[LineNum].Value
			
			SolveAffixes_PreSuf("Rarity", LineNum, Value, PrefixFile, SuffixFile, ItemLevel)
		}
	}
	
	
	
	
	
	
	
	
	
	
	; TODO: more fancy stuff with uncertain affixes.
	
	TmpAffixLines := []
	i := AffixLines.MaxIndex()
	
	Loop, %i%
	{
		TmpAffixLines[A_Index] := AffixLines[A_Index]
	}
	
	;DebugFile := FileOpen("DebugFile.txt", "w")
	;DebugFile.Write(ExploreObj(TmpAffixLines) . "`n`n---`n`n")
	;DebugFile.Write(ExploreObj(Itemdata.UncertainAffixes) . "`n`n---`n`n")
	
	For junk1, grp in Itemdata.UncertainAffixes
	{
		For junk2, entry in grp
		{
			For key, val in [3,5]
			{
				If(entry[val])
				{
					If(IsObject(TmpAffixLines[entry[val]]))
					{
						TmpAffixLines[entry[val]].Push(entry[val+1])
					}
					Else
					{
						TmpAffixLines[entry[val]] := [entry[val+1]]
					}
					
				}
			}
		}
	}
	
	;DebugFile.Write(ExploreObj(TmpAffixLines) . "`n`n---`n`n")
	
	AffixLines.Reset()
	
	i := 1
	For junk1, line in TmpAffixLines
	{
		If(IsObject(line))
		{
			For junk2, subline in line
			{
				If(IsObject(subline))
				{
					AffixLines.Set(i, subline)
					++i
				}
				Else
				{
					AffixLines.Set(i, line)
					++i
					break
				}
			}
		}
		Else
		{
			AffixLines.Set(i, line)
			++i
		}
	}
	
	;DebugFile.Write(ExploreObj(AffixLines) . "`n`n---`n`n")
	;DebugFile.Close()
	return
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

ParseClipBoardChanges(debug = false)
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
	
	
	If (StrLen(ParsedData) and !Opts.OnlyActiveIfPOEIsFront and debug) {	
		AddLogEntry(ParsedData, CBContents)
	}
	
	ShowToolTip(ParsedData)
}

AddLogEntry(ParsedData, RawData) {
	logFileRaw	:= userDirectory "\parsingLogRaw.txt"
	logFileParsed	:= userDirectory "\parsingLog.txt"
	
	line		:= "----------------------------------------------------------"
	timeStamp	:= ""
	ID 		:= MD5(RawData)
	UTCTimestamp := GetTimestampUTC()
	UTCFormatStr := "yyyy-MM-dd'T'HH:mm'Z'"
	FormatTime, TimeStr, %UTCTimestamp%, %UTCFormatStr%
	
	entry	:= line "`n" TimeStr " - ID: " ID "`n" line "`n`n"  
	entryRaw	:= entry . RawData "`n`n"
	entryParsed := entry . ParsedData "`n`n"
	
	FileAppend, %entryRaw%, %logFileRaw%
	FileAppend, %entryParsed%, %logFileParsed%
}

MD5(string, case := False)    ; by SKAN | rewritten by jNizM
{
	static MD5_DIGEST_LENGTH := 16
	hModule := DllCall("LoadLibrary", "Str", "advapi32.dll", "Ptr")
, VarSetCapacity(MD5_CTX, 104, 0), DllCall("advapi32\MD5Init", "Ptr", &MD5_CTX)
, DllCall("advapi32\MD5Update", "Ptr", &MD5_CTX, "AStr", string, "UInt", StrLen(string))
, DllCall("advapi32\MD5Final", "Ptr", &MD5_CTX)
	loop % MD5_DIGEST_LENGTH
		o .= Format("{:02" (case ? "X" : "x") "}", NumGet(MD5_CTX, 87 + A_Index, "UChar"))
	return o, DllCall("FreeLibrary", "Ptr", hModule)
}

GetTimestampUTC() { ; http://msdn.microsoft.com/en-us/library/ms724390
	VarSetCapacity(ST, 16, 0) ; SYSTEMTIME structure
	DllCall("Kernel32.dll\GetSystemTime", "Ptr", &ST)
	Return NumGet(ST, 0, "UShort")                        ; year   : 4 digits until 10000
	. SubStr("0" . NumGet(ST,  2, "UShort"), -1)     ; month  : 2 digits forced
	. SubStr("0" . NumGet(ST,  6, "UShort"), -1)     ; day    : 2 digits forced
	. SubStr("0" . NumGet(ST,  8, "UShort"), -1)     ; hour   : 2 digits forced
	. SubStr("0" . NumGet(ST, 10, "UShort"), -1)     ; minute : 2 digits forced
	. SubStr("0" . NumGet(ST, 12, "UShort"), -1)     ; second : 2 digits forced
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

AssembleDamageDetails(FullItemData)
{
	Quality := 0
	AttacksPerSecond := 0
	AttackSpeedIncr := 0
	PhysIncr := 0
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
			AttacksPerSecond := Arr4
			Continue
		}
		
	; Get percentage attack speed increase
		IfInString, A_LoopField, increased Attack Speed
		{
			StringSplit, Arr, A_LoopField, %A_Space%, `%
			AttackSpeedIncr += Arr1		; There are a few weapons with an AS implicit, so we ADD all relevant lines here
			Continue
		}
		
	; Get percentage physical damage increase
		IfInString, A_LoopField, increased Physical Damage
		{
			StringSplit, Arr, A_LoopField, %A_Space%, `%
			PhysIncr := Arr1
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
		Else IfInString, A_LoopField, in Off Hand
		{
			ParseAddedDamage(A_LoopField, "Fire", OffHFireLo, OffHFireHi)
			ParseAddedDamage(A_LoopField, "Cold", OffHColdLo, OffHColdHi)
			ParseAddedDamage(A_LoopField, "Lightning", OffHLighLo, OffHLighHi)
			ParseAddedDamage(A_LoopField, "Chaos", OffHChaoLo, OffHChaoHi)
		}
		Else
		{
			ParseAddedDamage(A_LoopField, "Fire", FireLo, FireHi)
			ParseAddedDamage(A_LoopField, "Cold", ColdLo, ColdHi)
			ParseAddedDamage(A_LoopField, "Lightning", LighLo, LighHi)
			ParseAddedDamage(A_LoopField, "Chaos", ChaoLo, ChaoHi)
		}
		
		SkipAddedDamageParse:
	}
	
	Result =
	
	If ( AttackSpeedIncr > 0 )
	{
		BaseAttackSpeed := AttacksPerSecond / (AttackSpeedIncr / 100 + 1)
	; The BaseAttackSpeed's second decimal place is always 0 or 5, so for example 1.24 should actually be 1.25
	; We check how far off it is
		ModVal := Mod(BaseAttackSpeed, 0.05)
	; And effectively round to the nearest 0.05
		BaseAttackSpeed += (ModVal > 0.025) ? (0.05 - ModVal) : (- ModVal)
	; Now we put the AttacksPerSecond back together
		AttacksPerSecond := BaseAttackSpeed * (AttackSpeedIncr / 100 + 1)	
	}
	
	
	SetFormat, FloatFast, 5.1
	PhysDps	:= ((PhysLo + PhysHi) / 2) * AttacksPerSecond
	Result	= %Result%`nPhys DPS:   %PhysDps%
	
	EleDps		:= ((FireLo + FireHi + ColdLo + ColdHi + LighLo + LighHi) / 2) * AttacksPerSecond
	MainHEleDps	:= ((MainHFireLo + MainHFireHi + MainHColdLo + MainHColdHi + MainHLighLo + MainHLighHi) / 2) * AttacksPerSecond
	OffHEleDps	:= ((OffHFireLo + OffHFireHi + OffHColdLo + OffHColdHi + OffHLighLo + OffHLighHi) / 2) * AttacksPerSecond
	ChaosDps		:= ((ChaoLo + ChaoHi) / 2) * AttacksPerSecond
	MainHChaosDps	:= ((MainHChaoLo + MainHChaoHi) / 2) * AttacksPerSecond
	OffHChaosDps	:= ((OffHChaoLo + OffHChaoHi) / 2) * AttacksPerSecond
	
	If ( MainHEleDps > 0 or OffHEleDps > 0 or MainHChaosDps > 0 or OffHChaosDps > 0 )
	{
		twoColDisplay		:= true
		TotalMainHEleDps	:= MainHEleDps + EleDps
		TotalOffHEleDps	:= OffHEleDps + EleDps
		TotalMainHChaosDps	:= MainHChaosDps + ChaosDps
		TotalOffHChaosDps	:= OffHChaosDps + ChaosDps
	}
	Else twoColDisplay := false
		
	If ( MainHEleDps > 0 or OffHEleDps > 0 )
	{
		Result = %Result%`nElem DPS:   %TotalMainHEleDps% MainH | %TotalOffHEleDps% OffH
	}
	Else Result = %Result%`nElem DPS:   %EleDps%
		
	If ( MainHChaosDps > 0 or OffHChaosDps > 0 )
	{
		Result = %Result%`nChaos DPS:  %TotalMainHChaosDps% MainH | %TotalOffHChaosDps% OffH
	}
	Else Result = %Result%`nChaos DPS:  %ChaosDps%
		
	If ( twoColDisplay )
	{
		TotalMainHDps	:= PhysDps + TotalMainHEleDps + TotalMainHChaosDps
		TotalOffHDps	:= PhysDps + TotalOffHEleDps + TotalOffHChaosDps
		Result		= %Result%`nTotal DPS:  %TotalMainHDps% MainH | %TotalOffHDps% OffH
	}
	Else
	{
		TotalDps	:= PhysDps + EleDps + ChaosDps
		Result	= %Result%`nTotal DPS:  %TotalDps%
	}
	
	; Only show Q20 values if item is not Q20
	If (Quality < 20) {
		Q20Dps := Q20PhysDps := PhysDps * (PhysIncr + 120) / (PhysIncr + Quality + 100)
		
		If ( twoColDisplay )
		{
			Q20MainHDps	:= Q20Dps + TotalMainHEleDps + TotalMainHChaosDps
			Q20OffHDps	:= Q20Dps + TotalOffHEleDps + TotalOffHChaosDps
			Result		= %Result%`nQ20 DPS:    %Q20MainHDps% MainH | %Q20OffHDps% OffH
		}
		Else
		{
			Q20Dps	:= Q20Dps + EleDps + ChaosDps
			If (Q20Dps != Q20PhysDps) {
				Result	= %Result%`nQ20 PDPS:   %Q20PhysDps%	
			}			
			Result	= %Result%`nQ20 DPS:    %Q20Dps%
		}
	}
	
	Item.DamageDetails					:= {}
	Item.DamageDetails.MainHEleDps		:= MainHEleDps
	Item.DamageDetails.OffHEleDps			:= OffHEleDps
	Item.DamageDetails.MainHChaosDps		:= MainHChaosDps
	Item.DamageDetails.OffHChaosDps		:= OffHChaosDps
	Item.DamageDetails.TotalMainHDps		:= TotalMainHDps
	Item.DamageDetails.TotalOffHDps		:= TotalOffHDps
	Item.DamageDetails.TotalMainHEleDps	:= TotalMainHEleDps
	Item.DamageDetails.TotalOffHEleDps		:= TotalOffHEleDps
	Item.DamageDetails.TotalMainHChaosDps	:= TotalMainHChaosDps
	Item.DamageDetails.TotalOffHChaosDps	:= TotalOffHChaosDps
	Item.DamageDetails.Q20MainHDps		:= Q20MainHDps
	Item.DamageDetails.Q20OffHDps			:= Q20OffHDps
	
	Item.DamageDetails.Quality			:= Quality
	Item.DamageDetails.PhysDps			:= PhysDps
	Item.DamageDetails.EleDps			:= EleDps
	Item.DamageDetails.ChaosDps			:= ChaosDps
	Item.DamageDetails.TotalDps			:= TotalDps
	Item.DamageDetails.Q20PhysDps			:= Q20PhysDps
	Item.DamageDetails.Q20Dps			:= Q20Dps
	
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
				Return
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
					If ((matchCount and AffixCount > 1) or (not matchCount and AffixCount = 1))
					{
						; We replaced the suffix and have 2 affixes, therefore we must also have a prefix that we can replace.
						; OR we didn't replace the suffix but have 1 mod, therefore we must have a prefix that we can replace.
						ItemTypeName := Trim(RegExReplace(ItemTypeName, "iU)^.* ", ""))
						Return
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
		If(ItemName == Line)
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
			LinksString	:= GetColonValue(A_LoopField)
			before		:= StrLen(LinksString)
			LinksString	:= RegExReplace(LinksString, "[RGBW]", "")
			after		:= StrLen(LinksString)
			SocketsCount	:= before - after
		}
	}
	return SocketsCount
}

ParseCharges(stats)
{
	charges := {}
	Loop, Parse, stats, `n, `r 
	{
		LoopField := RegExReplace(A_Loopfield, "i)\s\(augmented\)", "")
		; Flasks
		RegExMatch(LoopField, "i)Consumes (\d+) of (\d+) Charges on use.*", max)		
		If (max) {
			charges.usage	:= max1
			charges.max	:= max2
		}		
		RegExMatch(LoopField, "i)Currently has (\d+) Charge.*", current)
		If (current) {
			charges.current:= current1
		}
		
		; Leaguestones	
		RegExMatch(LoopField, "i)Currently has (\d+) of (\d+) Charge.*", max)
		If (max) {
			charges.usage	:= 1
			charges.max	:= max2
			charges.current:= max1
		}		
	}
	
	return charges
}

ParseAreaMonsterLevelRequirement(stats)
{
	requirements := {}
	Loop,  Parse, stats, `n, `r 
	{
		RegExMatch(A_LoopField, "i)Can only be used in Areas with Monster Level(.*)", req)
		RegExMatch(req1, "i)(\d+).*", lvl)
		RegExMatch(req1, "i)below|above|higher|lower", logicalOperator)
		
		If (lvl) {
			requirements.lvl	:= Trim(lvl1)
		}
		If (logicalOperator) {
			requirements.logicalOperator := Trim(logicalOperator)
		}
	}	
	return requirements
}

; Converts a currency stack to Chaos by looking up the
; conversion ratio from CurrencyRates.txt or downloaded ratios from poe.ninja
ConvertCurrency(ItemName, ItemStats, ByRef dataSource)
{
	If (InStr(ItemName, "Shard"))
	{
		IsShard	:= True
		ItemName	:= "Orb of " . SubStr(ItemName, 1, -StrLen(" Shard"))
	}
	If (InStr(ItemName, "Fragment"))
	{
		IsFragment:= True
		ItemName	:= "Scroll of Wisdom"
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
		StackSize := RegExReplace(StackSizeParts1, "i)[^0-9a-z]")
	}
	
	; Update currency rates from poe.ninja
	last	:= Globals.Get("LastCurrencyUpdate")
	diff	:= A_NowUTC
	EnvSub, diff, %last%, Minutes
	If (diff > 180 or !last) {
		; no data or older than 3 hours
		GoSub, FetchCurrencyData
	}
	
	; Use downloaded currency rates if they exist, otherwise use hardcoded fallback 
	fallback		:= A_ScriptDir . "\data\CurrencyRates.txt"
	ninjaRates	:= [A_ScriptDir . "\temp\CurrencyRates_tmpstandard.txt", A_ScriptDir . "\temp\CurrencyRates_tmphardcore.txt", A_ScriptDir . "\temp\CurrencyRates_Standard.txt", A_ScriptDir . "\temp\CurrencyRates_Hardcore.txt"]
	result		:= []
	
	Loop, % ninjaRates.Length() 
	{
		dataSource := "Currency rates powered by poe.ninja`n`n"
		If (FileExist(ninjaRates[A_Index])) 
		{
			ValueInChaos	:= 0
			leagueName	:= ""
			file			:= ninjaRates[A_Index]
			Loop, Read, %file%
			{			
				Line := Trim(A_LoopReadLine)
				RegExMatch(Line, "i)^;(.*)", match)
				If (match) {
					leagueName := match1 . ": "
					Continue
				}
				
				IfInString, Line, %ItemName%
				{
					StringSplit, LineParts, Line, |
					ChaosRatio	:= LineParts2
					StringSplit, ChaosRatioParts,ChaosRatio, :
					ChaosMult		:= ChaosRatioParts2 / ChaosRatioParts1
					ValueInChaos	:= (ChaosMult * StackSize)
				}
			}
			
			If (ValueInChaos) {
				tmp := [leagueName, ValueInChaos, ChaosRatio]
				result.push(tmp)
			}
		}
	}
	
	; fallback - condition : no results found so far
	If (!result.Length()) {
		ValueInChaos	:= 0
		dataSource	:= "Fallback <\data\CurrencyRates.txt>`n`n"
		leagueName	:= "Hardcoded rates: "
		
		Loop, Read, %fallback%
		{
			Line := StripLineCommentRight(A_LoopReadLine)
			If (SkipLine(Line))
			{
				Continue
			}
			IfInString, Line, %ItemName%
			{
				StringSplit, LineParts, Line, |
				ChaosRatio	:= LineParts2
				StringSplit, ChaosRatioParts,ChaosRatio, :
				ChaosMult		:= ChaosRatioParts2 / ChaosRatioParts1
				ValueInChaos	:= (ChaosMult * StackSize)
			}
		}
		
		If (ValueInChaos) {
			tmp := [leagueName, ValueInChaos, ChaosRatio]
			result.push(tmp)
		}
	}
	
	return result
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
								ValueRange := LBMin . "-" . UBMax
							}
							Else
							{
								ValueRange := LowerBound . " " . UpperBound
							}
						}
						
						ValueRange := StrPad(ValueRange, 7, "left")
						
						If (AppendImplicitSep)
						{
							ValueRange .= "`n--------"
							AppendImplicitSep := False
						}
						
						ProcessedLine := [AffixLine, ValueRange]
						
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

ItemIsHybridArmour(ItemDataText)
{
	DefenseStatCount := 0
	Loop, Parse, ItemDataText, `n, `r
	{
		If RegExMatch(Trim(A_LoopField), "^(Armour|Evasion Rating|Energy Shield): \d+( \(augmented\))?$")
		{
			DefenseStatCount += 1
		}
	}
	return (DefenseStatCount > 1) ? True : False
}


/*
########### MAIN PARSE FUNCTION ##############

Invocation stack (simplified) for full item parse:

(timer watches clipboard contents)
(on clipboard changed) ->

ParseClipBoardChanges()
  PreProcessContents()
    ParseItemData()
      (get item details by calling many other Parse... functions)
      ParseAffixes()
        (on affix match found) ->
        Simple affixes:
          LookupAffixAndSetInfoLine()
            AppendAffixInfo(MakeAffixDetailLine()) ; appends to global AffixLines table
        Complex affixes:
          Use functions depending on Pre-Pass flags, set by ParseAffixes()
            Put results into Itemdata.UncertainAffixes
              Decide which ones are possible regarding prefix/suffix limit and append them to global AffixLines table
    PostProcessData()
    ShowToolTip()
*/
ParseItemData(ItemDataText, ByRef RarityLevel="")
{
	Global AffixTotals, uniqueMapList, mapList, mapMatchList, shapedMapMatchList, divinationCardList, gemQualityList
	
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
	Variation =
	
	Item.Init()
	ItemData.Init()
	
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
	
	ItemData.NamePlate	:= ItemDataParts1
	ItemData.Stats		:= ItemDataParts2
	
	ItemDataIndexLast := ItemDataParts0
	ItemDataPartsLast := ItemDataParts%ItemDataIndexLast%
	
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
	Item.Name		:= ItemName
	Item.TypeName	:= ItemTypeName
	
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
	ItemData.Rarity	:= ParseRarity(ItemData.NamePlate)
	
	ItemData.Links		:= ParseLinks(ItemDataText)
	ItemData.Sockets	:= ParseSockets(ItemDataText)
	
	Item.Charges		:= ParseCharges(ItemData.Stats)
	
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
	; Cards like "The Void" don't have a stack size
	If (InStr(ItemData.Rarity, "Divination Card"))
	{
		Item.IsDivinationCard := True
		Item.BaseType := "Divination Card"
	}
	
	; Prophecy Orb detection	
	If (InStr(ItemData.PartsLast, "to add this prophecy to"))
	{
		Item.IsProphecy := True
		Item.BaseType := "Prophecy"		
		; ParseProphecy(ItemData, Difficulty)
		; Item.DifficultyRestriction := Difficulty
	}
	
	Item.IsGem	:= (InStr(ItemData.Rarity, "Gem"))
	Item.IsCurrency:= (InStr(ItemData.Rarity, "Currency"))
	
	If (Not (InStr(ItemDataText, "Itemlevel:") or InStr(ItemDataText, "Item Level:")) and Not Item.IsGem and Not Item.IsCurrency and Not Item.IsDivinationCard and Not Item.IsProphecy)
	{
		return Item.Name
	}
	
	If (Item.IsGem)
	{
		RarityLevel	:= 0
		Item.Level	:= ParseGemLevel(ItemDataText, "Level:")
		ItemLevelWord	:= "Gem Level:"
		Item.BaseType	:= "Gem"
	}
	Else
	{
		If (Item.IsCurrency and Opts.ShowCurrencyValueInChaos == 1)
		{
			dataSource	:= ""
			ValueInChaos	:= ConvertCurrency(Item.Name, ItemData.Stats, dataSource)
			If (ValueInChaos.Length() and not Item.Name == "Chaos Orb")
			{
				CurrencyDetails := "`n" . dataSource
				Loop, % ValueInChaos.Length() 
				{
					CurrencyDetails .= ValueInChaos[A_Index][1] . "" . ValueInChaos[A_Index][2] . " Chaos (" . ValueInChaos[A_Index][3] . "c)`n"
				}
			}
		}
		
		; Don't do this on Divination Cards or this script crashes on trying to do the ParseItemLevel
		Else If (Not Item.IsCurrency and Not Item.IsDivinationCard and Not Item.IsProphecy)
		{
			regex := ["^Sacrifice At", "^Fragment of", "^Mortal ", "^Offering to ", "'s Key$", "Ancient Reliquary Key"]
			For key, val in regex {
				If (RegExMatch(Item.Name, "i)" val "")) {
					Item.IsMapFragment := True
					Break
				}
			}
			
			RarityLevel	:= CheckRarityLevel(ItemData.Rarity)
			Item.Level	:= ParseItemLevel(ItemDataText)
			ItemLevelWord	:= "Item Level:"
			ParseItemType(ItemData.Stats, ItemData.NamePlate, ItemBaseType, ItemSubType, ItemGripType, Item.IsMapFragment, RarityLevel)
			Item.BaseType	:= ItemBaseType
			Item.SubType	:= ItemSubType
			Item.GripType	:= ItemGripType
		}
	}
	
	Item.RarityLevel	:= RarityLevel
	
	Item.IsBow			:= (Item.SubType == "Bow")
	Item.IsFlask		:= (Item.SubType == "Flask")
	Item.IsBelt			:= (Item.SubType == "Belt")
	Item.IsRing			:= (Item.SubType == "Ring")
	Item.IsUnsetRing	:= (Item.IsRing and InStr(ItemData.NamePlate, "Unset Ring"))
	Item.IsAmulet		:= (Item.SubType == "Amulet")
	Item.IsTalisman		:= (Item.IsAmulet and InStr(ItemData.NamePlate, "Talisman") and !InStr(ItemData.NamePlate, "Amulet"))
	Item.IsSingleSocket	:= (IsUnsetRing)
	Item.IsFourSocket	:= (Item.SubType == "Gloves" or Item.SubType == "Boots" or Item.SubType == "Helmet")
	Item.IsThreeSocket	:= (Item.GripType == "1H" or Item.SubType == "Shield")
	Item.IsQuiver		:= (Item.SubType == "Quiver")
	Item.IsWeapon		:= (Item.BaseType == "Weapon")
	Item.IsArmour		:= (Item.BaseType == "Armour")
	Item.IsHybridArmour	:= (ItemIsHybridArmour(ItemDataText))
	Item.IsMap			:= (Item.BaseType == "Map")
	Item.IsLeaguestone	:= (Item.BaseType == "Leaguestone")
	Item.IsJewel		:= (Item.BaseType == "Jewel")
	Item.IsMirrored		:= (ItemIsMirrored(ItemDataText) and Not Item.IsCurrency)
	Item.IsEssence		:= Item.IsCurrency and RegExMatch(Item.Name, "i)Essence of |Remnant of Corruption")
	Item.Note			:= Globals.Get("ItemNote")	
	
	If (Item.IsLeaguestone) {		
		Item.AreaMonsterLevelReq	:= ParseAreaMonsterLevelRequirement(ItemData.Stats)
	}
	
	TempStr := ItemData.PartsLast
	Loop, Parse, TempStr, `n, `r
	{
		RegExMatch(Trim(A_LoopField), "i)^Has ", match)
		If (match) {
			Item.HasEffect := True
		}		
		; parse item variations like relics (variation of it's unique counterpart)		
		If (RegExMatch(Trim(A_LoopField), "i)Relic Unique", match)) {
			Item.IsRelic := true
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
	
	If (Item.IsLeagueStone) {
		ItemDataIndexAffixes := ItemDataIndexAffixes - 1
	}
	ItemData.Affixes := ItemDataParts%ItemDataIndexAffixes%
	ItemData.IndexAffixes := ItemDataIndexAffixes
	
	; Retrieve items implicit mod if it has one
	If (Item.IsWeapon or Item.IsArmour or Item.IsRing or Item.IsBelt or Item.IsAmulet or Item.IsJewel) {
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
			tempImplicit	:= ItemDataParts%ItemDataIndexImplicit%
			Loop, Parse, tempImplicit, `n, `r
			{
				Item.Implicit.push(A_LoopField)
			}
			Item.hasImplicit := True	
		}
	}
	
	ItemData.Stats := ItemDataParts2
	
	If (Item.IsFlask)
	{
		ParseFlaskAffixes(ItemData.Affixes)
	}
	Else If (RarityLevel > 1 and RarityLevel < 4 and Item.IsMap = False and not Item.IsLeaguestone)  ; Code added by Bahnzo to avoid maps showing affixes
	{
		ParseAffixes(ItemData.Affixes, Item)
	}
	Else If (RarityLevel > 1 and RarityLevel < 4 and Item.IsMap = True)
	{
		MapModWarnings := ParseMapAffixes(ItemData.Affixes)
	}
	Else If (RarityLevel > 1 and RarityLevel < 4 and Item.IsLeaguestone)
	{
		ParseLeagueStoneAffixes(ItemData.Affixes, Item)
	}
	
	NumPrefixes	:= NumFormatPointFiveOrInt(AffixTotals.NumPrefixes)
	NumSuffixes	:= NumFormatPointFiveOrInt(AffixTotals.NumSuffixes)
	TotalAffixes	:= NumFormatPointFiveOrInt(AffixTotals.NumPrefixes + AffixTotals.NumSuffixes)
	AffixTotals.NumTotals := TotalAffixes
	
	; We need to call this function a second time because now we know the AffixCount.
	ParseItemName(ItemData.NamePlate, ItemName, ItemTypeName, TotalAffixes)
	Item.TypeName := ItemTypeName
	
	pseudoMods := PreparePseudoModCreation(ItemData.Affixes, Item.Implicit, RarityLevel, Item.isMap)
	
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
			If (Item.RarityLevel < 3)
			{
				Item.BaseLevel := CheckBaseLevel(Item.Name)
			}
			Else If (Item.IsUnidentified)
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
		
		If (Item.IsFourSocket and Item.MaxSockets > 4)
		{
			Item.MaxSockets := 4
		}
		Else If (Item.IsThreeSocket and Item.MaxSockets > 3)
		{
			Item.MaxSockets := 3
		}
		Else If (Item.IsSingleSocket)
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
	
	/*
	If (Item.IsProphecy)
	{
		Restriction := StrLen(Item.DifficultyRestriction) > 0 ? Item.DifficultyRestriction : "None"
		TT := TT . "`n--------`nDifficulty Restriction: " Restriction 
	}
	*/
	
	If (Item.IsMap)
	{		
		Item.MapLevel := ParseMapLevel(ItemDataText)
		Item.MapTier  := Item.MapLevel - 67
		
		/*
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
		
		If (RarityLevel > 1 and RarityLevel < 4 and Not Item.IsUnidentified)
		{
			AffixDetails := AssembleMapAffixes()
			MapAffixCount := AffixTotals.NumPrefixes + AffixTotals.NumSuffixes
			TT = %TT%`n`n-----------`nMods (%MapAffixCount%):%AffixDetails%
			
			If (MapModWarnings)
			{
				TT = %TT%`n`nMod warnings:%MapModWarnings%
			}
			Else
			{
				TT = %TT%`n`nMod warnings:`nnone
			}
		}
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
			If (TotalAffixes > 0 and Not Item.IsUnidentified and Not Item.IsMap)
			{
				AffixStats = Affixes (%TotalAffixes%):%PrefixLine%%SuffixLine%
				TT = %TT%`n--------`n%AffixStats%
			}
		}
		
		If (Item.hasImplicit and not Item.IsUnique) {
			Implicit	:= ""
			maxIndex 	:= Item.Implicit.MaxIndex()
			Loop, % maxIndex {
				Implicit .= (A_Index < maxIndex) ? Item.Implicit[A_Index] "`n" : Item.Implicit[A_Index]
			}
			TT = %TT%`n--------`n%Implicit%
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
	
	If (pseudoMods.Length())
	{
		TT = %TT%`n--------
		For key, val in pseudoMods
		{
			pseudoMod := "(pseudo) " val.name_orig
			TT = %TT%`n%pseudoMod%
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
	
	return TT
	
	ParseItemDataEnd:
	return TT
}

GetNegativeAffixOffset(Item)
{
	NegativeAffixOffset := 0
	If (Item.IsUnique or Item.IsTalisman)
	{
		; Uniques and Talismans have a flavour text, so decrement item index to account for that.
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.IsFlask)
	{
		; Flasks have an info text
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.IsMap)
	{
		; Maps have an info text
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.IsJewel)
	{
		; Jewels have an info text
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.HasEffect)
	{
		; Weapon skins and other effects get a line that points them out
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.IsCorrupted)
	{
		; Corrupted items have "Corrupted" as a line
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.IsMirrored)
	{
		; Mirrored items have "Mirrored" as a line
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	return NegativeAffixOffset
}

; ### TODO: Fix issue for white items, currently receiving duplicate infos (affixes and implicit containing the same line)
; Prepare item affixes to create pseudo mods, taken from PoE-TradeMacro
; Moved from TradeMacro to ItemInfo to avoid duplicate code, please be careful with any changes
PreparePseudoModCreation(Affixes, Implicit, Rarity, isMap = false) {
	; ### TODO: remove blank lines ( rare cases, maybe from crafted mods )

	mods := []
	; ### Append Implicits if any
	modStrings := Implicit	
	For i, modString in modStrings {
		tempMods := ModStringToObject(modString, true)
		For i, tempMod in tempMods {
			mods.push(tempMod)
		}
	}	
	
	; ### Convert affix lines to mod objects
	modStrings := StrSplit(Affixes, "`n")	
	For i, modString in modStrings {
		tempMods := ModStringToObject(modString, false)
		For i, tempMod in tempMods {
			mods.push(tempMod)
		}
	}

	; return only pseudoMods, this is changed from PoE-TradeMacro where all mods are returned.
	mods := CreatePseudoMods(mods)

	Return mods
}

; Convert mod strings to objects while seperating combined mods like "+#% to Fire and Lightning Resitances"
; Moved from TradeMacro to ItemInfo to avoid duplicate code, please be careful with any changes
ModStringToObject(string, isImplicit) {
	StringReplace, val, string, `r,, All
	StringReplace, val, val, `n,, All
	values := []
	
	; Collect all numeric values in the mod-string
	Pos        := 0
	While Pos := RegExMatch(val, "i)(-?[.0-9]+)", value, Pos + (StrLen(value) ? StrLen(value) : 1)) {
		values.push(value)
	}

	; Collect all resists/attributes that are combined in one mod
	Matches := []
	
	If (RegexMatch(val, "i)to (Strength|Dexterity|Intelligence) and (Strength|Dexterity|Intelligence)$", attribute)) {
		IF ( attribute1 AND attribute2 ) {
			Matches.push(attribute1)
			Matches.push(attribute2)
		}
	}
	
	type := ""
	; Matching "x% fire and cold resistance" or "x% to cold resist", excluding "to maximum cold resistance" and "damage penetrates x% cold resistance"
	If (RegExMatch(val, "i)to ((cold|fire|lightning)( and (cold|fire|lightning))?) resistance")) {
		type := "Resistance"
		If (RegExMatch(val, "i)fire")) {
			Matches.push("Fire")
		}
		If (RegExMatch(val, "i)cold")) {
			Matches.push("Cold")
		}
		If (RegExMatch(val, "i)lightning")) {
			Matches.push("Lightning")
		}
	}
	
	; Vanguard Belt implicit for example (flat AR + EV)
	If (RegExMatch(val, "i)([.0-9]+) to (Armour|Evasion Rating|Energy Shield) and (Armour|Evasion Rating|Energy Shield)")) {
		type := "Defense"
		If (RegExMatch(val, "i)Armour")) {
			Matches.push("Armour")
		}
		If (RegExMatch(val, "i)Evasion Rating")) {
			Matches.push("Evasion Rating")
		}
		If (RegExMatch(val, "i)Energy Shield")) {
			Matches.push("Energy Shield")
		}
	}
	
	; Create single mod from every collected resist/attribute
	Loop % Matches.Length() {
		RegExMatch(val, "i)(Resistance)", match)
		; differentiate between negative and positive values; flat and increased attributes
		sign := "+"
		type := RegExMatch(val, "i)increased", inc) ? "% increased " : " to "		
		If (inc) {
			sign := ""
		}		
		If (RegExMatch(val, "i)^-")) {
			sign := "-"
		}		
		Matches[A_Index] := match1 ? sign . "#% to " . Matches[A_Index] . " " . match1 : sign . "#" . type . "" . Matches[A_Index]
	}
	
	If (RegExMatch(val, "i)to all attributes|to all elemental (Resistances)", match)) {
		resist := match1 ? true : false
		Matches[1] := resist ? "+#% to Fire Resistance" : "+# to Strength"
		Matches[2] := resist ? "+#% to Lightning Resistance" : "+# to Intelligence"
		Matches[3] := resist ? "+#% to Cold Resistance" : "+# to Dexterity"
	}
	
	; Use original mod-string if no combination is found
	Matches[1] := Matches.Length() > 0 ? Matches[1] : val

	;
	arr := []
	Loop % (Matches.Length() ? Matches.Length() : 1) {
		temp := {}
		temp.name_orig := Matches[A_Index]
		Loop {
			temp.name_orig := RegExReplace(temp.name_orig, "-?#", values[A_Index], Count, 1)
			If (!Count) {
				break
			}
		}

		temp.values	:= values
		; mods with negative values inputted in the value fields are not supported on poe.trade, so searching for "-1 maximum charges/frenzy charges" is not possible
		; unless there is a mod "-# maximum charges"
		s			:= RegExReplace(Matches[A_Index], "i)(-?)[.0-9]+", "$1#")
		temp.name		:= RegExReplace(s, "i)# ?to ? #", "#", isRange)
		temp.isVariable:= false
		temp.type		:= (isImplicit and Matches.Length() <= 1) ? "implicit" : "explicit"
		arr.push(temp)
	}
	
	Return arr
}

; Moved from TradeMacro to ItemInfo to avoid duplicate code, please be careful with any changes
CreatePseudoMods(mods, returnAllMods := False) {
	tempMods := []
	lifeFlat := 0
	manaFlat := 0
	energyShieldFlat := 0
	energyShieldPercent := 0
	energyShieldPercentGlobal := 0
	evasionRatingPercentGlobal := 0
	
	rarityItemsFoundPercent := 0
	
	accuracyRatingFlat := 0
	globalCritChancePercent := 0
	globalCritMultiplierPercent := 0
	critChanceForSpellsPercent := 0

	spellDmg_Percent := 0
	attackDmg_Percent := 0
	
	; Attributes
	strengthFlat := 0
	dexterityFlat := 0
	intelligenceFlat := 0
	allAttributesFlat := 0
	strengthPercent := 0
	dexterityPercent := 0
	intelligencePercent := 0
	allAttributesPercent := 0
	
	; Resistances
	coldResist := 0
	fireResist := 0
	lightningResist := 0
	chaosResist := 0
	toAllElementalResist := 0

	; Damages
	meleePhysDmgGlobal_Percent := 0
	
	dmgTypes := ["elemental", "fire", "cold", "lightning"]
	For key, type in dmgTypes {		
		%type%Dmg_Percent := 0
		%type%Dmg_AttacksPercent := 0
		%type%Dmg_SpellsPercent := 0
		%type%Dmg_AttacksFlatLow := 0
		%type%Dmg_AttacksFlatHi := 0		
		%type%Dmg_SpellsFlatLow := 0
		%type%Dmg_SpellsFlatHi := 0
		%type%Dmg_FlatLow := 0
		%type%Dmg_FlatHi := 0
	}

	/* BREAKPOINT
	; ########################################################################
	; ###	Combine values from mods of same types 
	; ###		- also assign simplifiedName to the found mod for easier comparison later without duplicating precious regex
	; ########################################################################
	*/

	; Note that at this point combined mods/attributes have already been separated into two mods
	; like '+ x % to fire and lightning resist' would be '+ x % to fire resist' AND '+ x % to lightning resist' as 2 different mods
	For key, mod in mods {
		; ### Base stats
		; life and mana
		If (RegExMatch(mod.name, "i)to maximum (Life|Mana)$", stat)) {
			%stat1%Flat := %stat1%Flat + mod.values[1]
			mod.simplifiedName := "xToMaximum" stat1
		}
		; flat energy shield
		Else If (RegExMatch(mod.name, "i)to maximum Energy Shield$")) {
			energyShieldFlat := energyShieldFlat + mod.values[1]
			mod.simplifiedName := "xToMaximumEnergyShield"
		}
		; percent energy shield
		Else If (RegExMatch(mod.name, "i)increased maximum Energy Shield$")) {
			energyShieldPercent := energyShieldPercent + mod.values[1]
			mod.simplifiedName := "xIncreasedMaximumEnergyShield"
		}
		
		; ### Items found
		; rarity
		Else If (RegExMatch(mod.name, "i)increased Rarity of items found$")) {
			rarityItemsFoundPercent := rarityItemsFoundPercent + mod.values[1]
			mod.simplifiedName := "xIncreasedRarityOfItemsFound"
		}
		
		; ### crits
		Else If (RegExMatch(mod.name, "i)increased Global Critical Strike Chance$")) {
			globalCritChancePercent := globalCritChancePercent + mod.values[1]
			mod.simplifiedName := "xIncreasedGlobalCriticalChance"
		}
		Else If (RegExMatch(mod.name, "i)to Global Critical Strike Multiplier$")) {
			globalCritMultiplierPercent := globalCritMultiplierPercent + mod.values[1]
			mod.simplifiedName := "xIncreasedGlobalCriticalMultiplier"
		}
		Else If (RegExMatch(mod.name, "i)increased Critical Strike Chance for Spells$")) {
			critChanceForSpellsPercent := critChanceForSpellsPercent + mod.values[1]
			mod.simplifiedName := "xIncreasedCriticalSpells"
		}
		
		; ### Attributes
		; all flat attributes
		Else If (RegExMatch(mod.name, "i)to All Attributes$")) {
			allAttributesFlat := allAttributesFlat + mod.values[1]
			mod.simplifiedName := "xToAllAttributes"
		}
		; single flat attributes
		Else If (RegExMatch(mod.name, "i)to (Intelligence|Dexterity|Strength)$", attribute)) {
			%attribute1%Flat := %attribute1%Flat + mod.values[1]
			mod.simplifiedName := "xTo" . attribute1
		}
		; % increased attributes
		Else If (RegExMatch(mod.name, "i)increased (Intelligence|Dexterity|Strength)$", attribute)) {
			%attribute1%Percent := %attribute1%Percent + mod.values[1]
			mod.simplifiedName := "xIncreased" . attribute1 . "Percentage"
		}

		; ### Resistances
		; % to all resistances ( careful about 'max all resistances' )
		Else If (RegExMatch(mod.name, "i)to all Elemental Resistances$")) {
			toAllElementalResist := toAllElementalResist + mod.values[1]
			mod.simplifiedName := "xToAllElementalResistances"
		}
		; % to base resistances
		Else If (RegExMatch(mod.name, "i)to (Cold|Fire|Lightning|Chaos) Resistance$", resistType)) {
			%resistType1%Resist := %resistType1%Resist + mod.values[1]
			mod.simplifiedName := "xTo" resistType1 "Resistance"
		}
		
		; ### Percent damages
		; % increased elemental damage
		Else If (RegExMatch(mod.name, "i)increased (Cold|Fire|Lightning|Elemental) damage$", element)) {
			%element1%Dmg_Percent := %element1%Dmg_Percent + mod.values[1]
			mod.simplifiedName := "xIncreased" element1 "Damage"
		}
		; % elemental damage with weapons
		Else If (RegExMatch(mod.name, "i)(Cold|Fire|Lightning|Elemental) damage with attack skills", element)) {
			%element1%Dmg_AttacksPercent := %element1%Dmg_AttacksPercent + mod.values[1]
			mod.simplifiedName := "xIncreased" element1 "DamageAttacks"
		}
		
		; ### Flat Damages
		; flat 'element' damage; source: weapons
		Else If (RegExMatch(mod.name, "i)adds .* (Cold|Fire|Lightning|Elemental) damage$", element)) {
			element := element1
			%element%Dmg_FlatLow := %element%Dmg_FlatLow + mod.values[1]
			%element%Dmg_FlatHi  := %element%Dmg_FlatHi  + mod.values[2]
			mod.simplifiedName := "xFlat" element "Damage"
		}
		; flat 'element' damage; source: various (wands/rings/amulets etc)
		Else If (RegExMatch(mod.name, "i)adds .* (Cold|Fire|Lightning|Elemental) damage to (Attacks|Spells)$", element)) {
			%element1%Dmg_%element2%FlatLow := %element1%Dmg_%element2%FlatLow + mod.values[1]
			%element1%Dmg_%element2%FlatHi  := %element1%Dmg_%element2%FlatHi  + mod.values[2]			
			ElementalDmg_%element2%FlatLow  += %element1%Dmg_%element2%FlatLow
			ElementalDmg_%element2%FlatHi   += %element1%Dmg_%element2%FlatHi
			mod.simplifiedName := "xFlat" element1 "Damage" element2
		}
		; this would catch any * Spell * Damage * ( we might need to be more precise here )
		Else If (RegExMatch(mod.name, "i)spell") and RegExMatch(mod.name, "i)damage") and not RegExMatch(mod.name, "i)chance|multiplier")) {
			spellDmg_Percent := spellDmg_Percent + mod.values[1]
			mod.simplifiedName := "xIncreasedSpellDamage" 
		}
		
		; ### remaining mods that can be derived from attributes (str|dex|int)
		; flat accuracy rating
		Else If (RegExMatch(mod.name, "i)to accuracy rating$")) {
			accuracyRatingFlat := accuracyRatingFlat + mod.values[1]
		}	
	}
	
	/* BREAKPOINT
	; ########################################################################
	; ###	Spread global values to their sub element
	; ### 	- like % all Elemental to the base elementals	
	; ########################################################################
	*/

	; ### Attributes
	; flat attributes
	If (allAttributesFlat) {
		strengthFlat		:= strengthFlat + allAttributesFlat
		dexterityFlat		:= dexterityFlat + allAttributesFlat
		intelligenceFlat 	:= intelligenceFlat + allAttributesFlat
	}
	
	; spread attributes to their corresponding stats they give
	If (strengthFlat) {
		lifeFlat := lifeFlat + Floor(strengthFlat/2)
		meleePhysDmgGlobal_Percent := meleePhysDmgGlobal_Percent + Floor(strengthFlat/5)
	}
	If (intelligenceFlat) {
		manaFlat := manaFlat + Floor(intelligenceFlat/2)
		energyShieldPercentGlobal := Floor(intelligenceFlat/5)
	}
	If (dexterityFlat) {
		accuracyRatingFlat := accuracyRatingFlat + Floor(dexterityFlat*2)
		evasionRatingPercentGlobal := Floor(dexterityFlat/5)
	}

	; ###  Elemental Damage - % increased
	fireDmg_Percent	:= fireDmg_Percent + elementalDmg_Percent
	coldDmg_Percent	:= coldDmg_Percent + elementalDmg_Percent
	lightningDmg_Percent:= lightningDmg_Percent + elementalDmg_Percent
	
	; ### Elemental damage - attack skills % increased
	; ### - spreads Elemental damage with attack skills to each 'element' damage with attack skills and adds related % increased 'element' damage
	fireDmg_AttacksPercent      	:= fireDmg_AttacksPercent + elementalDmg_AttacksPercent + fireDmg_Percent
	coldDmg_AttacksPercent		:= coldDmg_AttacksPercent + elementalDmg_AttacksPercent + coldDmg_Percent
	lightningDmg_AttacksPercent	:= lightningDmg_AttacksPercent + elementalDmg_AttacksPercent + lightningDmg_Percent
	
	; ### Elemental damage - Spells % increased
	; ### - spreads % spell damage to each % 'element' spell damage and adds related % increased 'element' damage
	fireDmg_SpellsPercent 		:= fireDmg_SpellsPercent + spellDmg_Percent + fireDmg_Percent
	coldDmg_SpellsPercent 		:= coldDmg_SpellsPercent + spellDmg_Percent + coldDmg_Percent
	lightningDmg_SpellsPercent	:= lightningDmg_SpellsPercent + spellDmg_Percent + lightningDmg_Percent

	; ### Elemental Resistances
	; ### - spreads % to all Elemental Resistances to the base resist
	; ### - also calculates the totalElementalResistance and totalResistance	
	totalElementalResistance := 0	
	For i, element in ["Fire", "Cold", "Lightning"] {
		%element%Resist := %element%Resist + toAllElementalResist		
		totalElementalResistance := totalElementalResistance + %element%Resist
	}
	totalResistance := totalElementalResistance + chaosResist
	
	/* BREAKPOINT
	; ########################################################################
	; ###	Generate ALL the pseudo mods from the non 0 values combined above
	; ###	- just remember the spreading logic above when assigning the temp mods inherited values references in possibleParentSimplifiedNames
	; ########################################################################
	*/

	; ### Generate Basic Stats pseudos
	If (lifeFlat > 0) {
		temp := {}
		temp.values		:= [lifeFlat]
		temp.name_orig		:= "+" . lifeFlat . " to maximum Life"
		temp.name			:= "+# to maximum Life"
		temp.simplifiedName	:= "xToMaximumLife"
		temp.exception		:= true
		temp.possibleParentSimplifiedNames := ["xToMaximumLife"]
		tempMods.push(temp)
	}
	If (manaFlat > 0) {
		temp := {}
		temp.values		:= [manaFlat]
		temp.name_orig		:= "+" . manaFlat . " to maximum Mana"
		temp.name			:= "+# to maximum Mana"
		temp.simplifiedName	:= "xToMaximumMana"
		temp.possibleParentSimplifiedNames := ["xToMaximumMana"]
		tempMods.push(temp)
	}
	If (energyShieldFlat > 0) {
		temp := {}
		temp.values		:= [energyShieldFlat]
		temp.name_orig		:= "+" . energyShieldFlat . " to maximum Energy Shield"
		temp.name			:= "+# to maximum Energy Shield"
		temp.simplifiedName	:= "xToMaximumEnergyShield"
		temp.possibleParentSimplifiedNames := ["xToMaximumEnergyShield"]
		tempMods.push(temp)
	}
	If (energyShieldPercent > 0) {
		temp := {}
		temp.values		:= [energyShieldPercent]
		temp.name_orig		:= energyShieldPercent . "% increased maximum Energy Shield"
		temp.name			:= "#% increased maximum Energy Shield"
		temp.simplifiedName	:= "xIncreasedMaximumEnergyShield"
		temp.possibleParentSimplifiedNames := ["xIncreasedMaximumEnergyShield"]
		tempMods.push(temp)
	}
	; ### Generate rarity item found pseudo
	If (rarityItemsFoundPercent > 0) {
		temp := {}
		temp.values		:= [rarityItemsFoundPercent]
		temp.name_orig		:= rarityItemsFoundPercent . "% increased Rarity of items found"
		temp.name			:= "#% increased Rarity of items found"
		temp.simplifiedName	:= "xIncreasedRarityOfItemsFound"
		temp.possibleParentSimplifiedNames := ["xIncreasedRarityOfItemsFound"]
		tempMods.push(temp)
	}
	; ### Generate crit pseudos	
	If (globalCritChancePercent > 0) {
		temp := {}
		temp.values		:= [globalCritChancePercent]
		temp.name_orig		:= globalCritChancePercent . "% increased Global Critical Strike Chance"
		temp.name			:= "#% increased Global Critical Strike Chance"
		temp.simplifiedName	:= "xIncreasedGlobalCriticalChance"
		temp.possibleParentSimplifiedNames := ["xIncreasedGlobalCriticalChance"]
		tempMods.push(temp)
	}
	If (globalCritMultiplierPercent > 0) {
		temp := {}
		temp.values		:= [globalCritMultiplierPercent]
		temp.name_orig		:= "+" . globalCritMultiplierPercent . "% to Global Critical Strike Multiplier"
		temp.name			:= "+#% to Global Critical Strike Multiplier"
		temp.simplifiedName	:= "xIncreasedGlobalCriticalMultiplier"
		temp.possibleParentSimplifiedNames := ["xIncreasedGlobalCriticalMultiplier"]
		tempMods.push(temp)
	}
	If (critChanceForSpellsPercent > 0) {
		temp := {}
		temp.values		:= [critChanceForSpellsPercent]
		temp.name_orig		:= critChanceForSpellsPercent . "% increased Critical Strike Chance for Spells"
		temp.name			:= "#% increased Critical Strike Chance for Spells"
		temp.simplifiedName	:= "xIncreasedCriticalSpells"
		temp.possibleParentSimplifiedNames := ["xIncreasedCriticalSpells"]
		tempMods.push(temp)
	}
	; ### Generate Attributes pseudos
	For i, attribute in ["Strength", "Dexterity", "Intelligence"] {
		If ( %attribute%Flat > 0 ) {
			temp := {}
			temp.values		:= [%attribute%Flat]
			temp.name_orig		:= "+" .  %attribute%Flat . " to " .  attribute
			temp.name			:= "+# to " . attribute
			temp.simplifiedName	:= "xTo" attribute
			temp.possibleParentSimplifiedNames := ["xTo" attribute, "xToAllAttributes"]
			tempMods.push(temp)
		}
	}
	; cumulative all attributes mods
	If (allAttributesFlat > 0) {
		temp := {}
		temp.values		:= [allAttributesFlat]
		temp.name_orig		:= "+" . allAttributesFlat . " to all Attributes"
		temp.name			:= "+#% to all Attributes"
		temp.simplifiedName	:= "xToAllAttributes"
		temp.possibleParentSimplifiedNames := ["xToAllAttributes"]
		tempMods.push(temp)
	}
	
	; ### Generate Resists pseudos
	For i, element in ["Fire", "Cold", "Lightning"] {
		If ( %element%Resist > 0) {
			temp := {}
			temp.values		:= [%element%Resist]
			temp.name_orig		:= "+" %element%Resist "% to " element " Resistance"
			temp.name			:= "+#% to " element " Resistance"
			temp.simplifiedName	:= "xTo" element "Resistance"
			temp.possibleParentSimplifiedNames := ["xTo" element "Resistance", "xToAllElementalResistances"]
			temp.hideForTradeMacro := true
			tempMods.push(temp)
		}
	}
	If (toAllElementalResist > 0) {
		temp := {}
		temp.values		:= [toAllElementalResist]
		temp.name_orig		:= "+" . toAllElementalResist . "% to all Elemental Resistances"
		temp.name			:= "+#% to all Elemental Resistances"
		temp.simplifiedName	:= "xToAllElementalResistances"
		temp.exception		:= true
		temp.possibleParentSimplifiedNames := ["xToAllElementalResistances"]
		temp.hideForTradeMacro := true
		tempMods.push(temp)
	}
	; Note that total resistances are calculated values with no possible child mods, so they have no simplifiedName
	If (totalElementalResistance > 0) {
		temp := {}
		temp.values		:= [totalElementalResistance]
		temp.name_orig		:= "+" . totalElementalResistance . "% total Elemental Resistance"
		temp.name			:= "+#% total Elemental Resistance"
		temp.exception		:= true
		temp.possibleParentSimplifiedNames := ["xToFireResistance", "xToColdResistance", "xToLightningResistance", "xToAllElementalResistances"]
		tempMods.push(temp)
	}
	; without chaos resist, this would have the same value as totalElementalResistance
	If ((totalResistance > 0) AND (chaosResist > 0)) {
		temp := {}
		temp.values		:= [totalResistance]
		temp.name_orig		:= "+" . totalResistance . "% total Resistance"
		temp.name			:= "+#% total Resistance"
		temp.exception		:= true
		temp.possibleParentSimplifiedNames := ["xToFireResistance", "xToColdResistance", "xToLightningResistance", "xToAllElementalResistances", "xToChaosResistance"]
		tempMods.push(temp)
	}
	
	; ### Generate remaining pseudos derived from attributes
	If (meleePhysDmgGlobal_Percent > 0) {
		temp := {}
		temp.values		:= [meleePhysDmgGlobal_Percent]
		temp.name_orig		:= meleePhysDmgGlobal_Percent . "% increased Melee Physical Damage"
		temp.name			:= "#% increased Melee Physical Damage"
		temp.simplifiedName	:= "xIncreasedMeleePhysicalDamage"
		temp.possibleParentSimplifiedNames := ["xIncreasedMeleePhysicalDamage"]
		temp.hideForTradeMacro := true
		tempMods.push(temp)
	}
	If (energyShieldPercentGlobal > 0) {
		temp := {}
		temp.values		:= [energyShieldPercentGlobal]
		temp.name_orig		:= energyShieldPercentGlobal . "% increased Energy Shield (Global)"
		temp.name			:= "#% increased Energy Shield (Global)"
		temp.simplifiedName	:= "xIncreasedEnergyShieldPercentGlobal"
		temp.possibleParentSimplifiedNames := ["xIncreasedEnergyShieldPercentGlobal"]
		temp.hideForTradeMacro := true
		tempMods.push(temp)
	}
	If (evasionRatingPercentGlobal > 0) {
		temp := {}
		temp.values		:= [evasionRatingPercentGlobal]
		temp.name_orig		:= evasionRatingPercentGlobal . "% increased Evasion (Global)"
		temp.name			:= "#% increased Evasion (Global)"
		temp.simplifiedName	:= "xIncreasedEvasionRatingPercentGlobal"
		temp.possibleParentSimplifiedNames := ["xIncreasedEvasionRatingPercentGlobal"]
		temp.hideForTradeMacro := true
		tempMods.push(temp)
	}
	If (accuracyRatingFlat > 0) {
		temp := {}
		temp.values		:= [accuracyRatingFlat]
		temp.name_orig		:= "+" . accuracyRatingFlat . " to Accuracy Rating"
		temp.name			:= "+# to Accuracy Rating"
		temp.simplifiedName	:= "xToAccuracyRating"
		temp.possibleParentSimplifiedNames := ["xToAccuracyRating"]
		tempMods.push(temp)
	}

	; ### Generate Damages pseudos
	; spell damage global
	If (spellDmg_Percent > 0) {
		temp := {}
		temp.values		:= [spellDmg_Percent]
		temp.name_orig		:= spellDmg_Percent . "% increased Spell Damage"
		temp.name			:= "#% increased Spell Damage"
		temp.simplifiedName	:= "xIncreasedSpellDamage"
		temp.possibleParentSimplifiedNames := ["xIncreasedSpellDamage"]
		tempMods.push(temp)
	}
	
	; other damages
	percentDamageModSuffixes := [" Damage", " Damage with Attack Skills", " Spell Damage"]
	flatDamageModSuffixes    := ["", " to Attacks", " to Spells"]
	
	For i, element in dmgTypes {
		StringUpper, element, element, T
		
		For j, dmgType in ["", "Attacks",  "Spells"]	{			
			; ### Percentage damages
			If (%element%Dmg_%dmgType%Percent > 0) {
				modSuffix := percentDamageModSuffixes[j]
				temp := {}
				temp.values		:= [%element%Dmg_%dmgType%Percent]
				temp.name_orig		:= %element%Dmg_%dmgType%Percent "% increased " element . modSuffix
				temp.name			:= "#% increased " element . modSuffix
				temp.simplifiedName	:= "xIncreased" element "Damage" dmgType
				temp.possibleParentSimplifiedNames := ["xIncreased" element "Damage" dmgType, "xIncreased" element "Damage"]
				( element != "Elemental" ) ? temp.possibleParentSimplifiedNames.push("xIncreasedElementalDamage" dmgType) : False
				( dmgType == "Spells" ) ? temp.possibleParentSimplifiedNames.push("xIncreasedSpellDamage") : False
				tempMods.push(temp)
			}
			; ### Flat damages
			If (%element%Dmg_%dmgType%FlatLow > 0 or %element%Dmg_%dmgType%FlatHi > 0) {				
				modSuffix := flatDamageModSuffixes[j]
				temp := {}
				temp.values		:= [%element%Dmg_%dmgType%FlatLow, %element%Dmg_%dmgType%FlatHi]
				temp.name_orig		:= "Adds " %element%Dmg_%dmgType%FlatLow " to " %element%Dmg_%dmgType%FlatHi " " element " Damage" modSuffix
				temp.name			:= "Adds # " element " Damage" modSuffix
				temp.simplifiedName	:= "xFlat" element "Damage" dmgType
				temp.possibleParentSimplifiedNames := ["xFlat" element "Damage" dmgType]
				If (element != "Elemental") {
					temp.possibleParentSimplifiedNames.push("xFlatElementalDamage" dmgType)
				} Else {
					temp.possibleParentSimplifiedNames := []
					For e, el in dmgTypes {
						StringUpper, upperEl, el, T
						temp.possibleParentSimplifiedNames.push("xFlat" upperEl "Damage" dmgType)
					}
				}
				tempMods.push(temp)
			}
		}
	}

	/* BREAKPOINT
	; ########################################################################
	; ###	Filter/Remove unwanted pseudos
	; ###	Only keep pseudos with values higher than other related mods
	; ###	TODO:	Improve/Simplify this part, so far I just copy/pasted code and doing ALMOST the same thing in each loop
	; ###			We could exit inner loop as soon as higher is set to false, I'll check the docs later
	; ########################################################################
	*/

	; This 1st pass is for TradeMacro 
	; remove pseudos that are shadowed by an original mod ONLY if they have the same name
	; inherited values not taken into account for this 1st pass
	; ex ( '25% increased Cold Spell Damage' is shadowed by '%25 increased Spell Damage' ) BUT don't have same name

	allPseudoMods := []
	For i, tempMod in tempMods {
		higher := true
		For j, mod in mods {
			; check for mods with same name
			; Eruyome: Is there any reason to use simplifiedName here? This can fail for pseudo mods like total ele resists
			; Eruyome: It's possible to match empty simplified names and compare the values of different mods with each other that way
			
			;If ( tempMod.simplifiedName == mod.simplifiedName ) {
			If ( tempMod.name == mod.name ) {
				; check if it's a flat damage mod
				If (mod.values[2]) {
					mv := Round((mod.values[1] + mod.values[2]) / 2, 3)
					tv := Round((tempMod.values[1] + tempMod.values[2]) / 2, 3)
					If (tv <= mv) {
						higher := false
					}
				}
				Else {
					If (tempMod.values[1] <= mod.values[1]) {
						higher := false
					}
				}
			}
		}
		; add the tempMod to pseudos if it has greater values, or no parent
		If (higher or (tempMod.exception and returnAllMods)) {
			tempMod.isVariable:= false
			tempMod.type := "pseudo"
			allPseudoMods.push(tempMod)
		}
	}

	; 2nd pass
	; now we remove pseudos that are shadowed by an original mod they inherited from
	; ex ( '25% increased Cold Spell Damage' is shadowed by '%25 increased Spell Damage' )
	tempPseudoMods := []
	For i, tempMod in allPseudoMods {
		higher := true
		For j, mod in mods {
			; check if it's a parent mod
			isParentMod := false
			For k, simplifiedName in tempMod.possibleParentSimplifiedNames {
				If (mod.simplifiedName == simplifiedName) {
					isParentMod := true
					; TODO: match found we could exit loop here
				}
			}
			If ( isParentMod ) {
				; check if it's a flat damage mod
				If (mod.values[2]) {
					mv := Round((mod.values[1] + mod.values[2]) / 2, 3)
					tv := Round((tempMod.values[1] + tempMod.values[2]) / 2, 3)
					If (tv <= mv) {
						higher := false
					}
				}
				Else {
					If (tempMod.values[1] <= mod.values[1]) {
						higher := false
					}
				}
			}
		}
		; add the tempMod to pseudos if it has greater values, or no parent		
		If (higher or (tempMod.exception and returnAllMods)) {
			tempMod.isVariable:= false
			tempMod.type := "pseudo"
			tempPseudoMods.push(tempMod)
		}
	}

	; 3rd Pass
	; same logic as above but compare pseudo with other pseudos
	; remove pseudos that are shadowed by another pseudo
	; ex ( '25% increased Cold Spell Damage' is shadowed by '%25 increased Spell Damage' )
	; must also avoid removing itself 
	
	pseudoMods := []
	For i, tempPseudoA in tempPseudoMods {
		higher := true
		For j, tempPseudoB in tempPseudoMods {
			; skip if its the same object
			If ( i != j ) {
				; check if it's a parent mod
				isParentMod := false
				For k, simplifiedName in tempPseudoA.possibleParentSimplifiedNames {
					if (tempPseudoB.simplifiedName == simplifiedName) {
						isParentMod := true
						; TODO: match found we could exit loop here
					}
				}
				If ( isParentMod ) {
					; check if it's a flat damage mod
					If (tempPseudoB.values[2]) {
						mv := Round((tempPseudoB.values[1] + tempPseudoB.values[2]) / 2, 3)
						tv := Round((tempPseudoA.values[1] + tempPseudoA.values[2]) / 2, 3)
						If (tv <= mv) {
							higher := false
						}
					}
					Else {
						If (tempPseudoA.values[1] <= tempPseudoB.values[1]) {
							higher := false
						}
					}
				}
			}
		}
		; add the tempMod to pseudos if it has greater values, or no parent
		If (higher) {
			tempPseudoA.isVariable:= false
			tempPseudoA.type := "pseudo"
			pseudoMods.push(tempPseudoA)
		}
	}

	; ### This is mostly for TradeMacro
	; returns all original mods and the pseudo mods if requested
	If (returnAllMods) {
		returnedMods := mods
		For i, mod in pseudoMods {
			returnedMods.push(mod)			
		}
		Return returnedMods
	}
	
	Return pseudoMods
}

; Show tooltip, with fixed width font
ShowToolTip(String, Centered = false)
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
			XCoord := (X - 135 >= 0) ? X - 135 : 0
			YCoord := (Y +  35 >= 0) ? Y +  35 : 0
			ToolTip, %String%, XCoord, YCoord
			Fonts.SetFixedFont()
			ToolTip, %String%, XCoord, YCoord
		}
	}
	Else
	{
		CoordMode, ToolTip, Screen
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
	
	If (ControlType = "GroupBox") {
		Gui, Font, cDA4F49
		Options := Param4
	}
	Else {
		Options := Param4 . " BackgroundTrans "
	}		
	
	GuiName := (StrLen(GuiName) > 0) ? Trim(GuiName) . ":Add" : "Add"
	Gui, %GuiName%, %ControlType%, %PositionInfo% %av% %al% %ah% %Options%, %Contents%
	Gui, Font
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

GuiAddHotkey(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("Hotkey", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddDropDownList(Contents, PositionInfo, Selected="", AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	; usage : add list items as a | delimited string, for example = "item1|item2|item3"
	ListItems := StrSplit(Contents, "|")
	Contents := ""
	Loop % ListItems.MaxIndex() {
		Contents .= Trim(ListItems[A_Index]) . "|"
		; add second | to mark pre-select list item
		If (Trim(ListItems[A_Index]) == Selected) {
			Contents .= "|"
		}
	}
	GuiAdd("DropDownList", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiUpdateDropdownList(Contents="", Selected="", AssocVar="", Options="", GuiName="") {
	GuiName := (StrLen(GuiName) > 0) ? Trim(GuiName) . ":" . AssocVar : "" . AssocVar
	
	If (StrLen(Contents) > 0) {
		; usage : add list items as a | delimited string, for example = "item1|item2|item3"
		ListItems := StrSplit(Contents, "|")
		; prepend the list with a pipe to re-create the list instead of appending it
		Contents := "|"
		Loop % ListItems.MaxIndex() {
			Contents .= Trim(ListItems[A_Index]) . "|"
			; add second | to mark pre-select list item
			If (Trim(ListItems[A_Index]) == Selected) {
				Contents .= "|"
			}
		}
		GuiControl, , %GuiName%, %Contents%
	}
	
	If (StrLen(Selected)) > 0 {
		; falls back to "ChooseString" if param3 is not an integer
		GuiControl, Choose, %GuiName% , %Selected%  	
	}	
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

; ######### UNHANDLED CASE DIALOG ############

ShowUnhandledCaseDialog()
{
	Global Msg, Globals
	Static UnhDlg_EditItemText

	Gui, 3:New,, Unhandled Case
	Gui, 3:Color, FFFFFF
	Gui, 3:Add, Picture, x25 y25 w36 h36, %A_ScriptDir%\resources\images\info.png
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
	generalHeight := SkipItemInfoUpdateCall ? "120" : "210"
	GuiAddGroupBox("General", "x7 y+15 w260 h" generalHeight " Section")

	; Note: window handles (hwnd) are only needed if a UI tooltip should be attached.

	GuiAddCheckbox("Only show tooltip if PoE is frontmost", "xs10 ys20 w210 h30", Opts.OnlyActiveIfPOEIsFront, "OnlyActiveIfPOEIsFront", "OnlyActiveIfPOEIsFrontH")
	AddToolTip(OnlyActiveIfPOEIsFrontH, "If checked the script does nothing if the`nPath of Exile window isn't the frontmost")
	GuiAddCheckbox("Put tooltip results on clipboard", "xs10 ys50 w210 h30", Opts.PutResultsOnClipboard, "PutResultsOnClipboard", "PutResultsOnClipboardH")
	AddToolTip(PutResultsOnClipboardH, "Put tooltip result text onto the system clipboard`n(overwriting the item info text PoE put there to begin with)")	
	GuiAddCheckbox("Enable Additional Macros", "xs10 ys80 w210 h30", Opts.EnableAdditionalMacros, "EnableAdditionalMacros", "EnableAdditionalMacrosH")
	AddToolTip(EnableAdditionalMacrosH, "Enables or disables the entire 'AdditionalMacros.txt' file.`nNeeds a script reload to take effect.")
	If (!SkipItemInfoUpdateCall) {
		GuiAddCheckbox("Update: Show Notifications", "xs10 ys110 w210 h30", Opts.ShowUpdateNotification, "ShowUpdateNotification", "ShowUpdateNotificationH")
		AddToolTip(ShowUpdateNotificationH, "Notifies you when there's a new release available.")		
		GuiAddCheckbox("Update: Skip folder selection", "xs10 ys140 w210 h30", Opts.UpdateSkipSelection, "UpdateSkipSelection", "UpdateSkipSelectionH")
		AddToolTip(UpdateSkipSelectionH, "Skips selecting an update location.`nThe current script directory will be used as default.")	
		GuiAddCheckbox("Update: Skip backup", "xs10 ys170 w210 h30", Opts.UpdateSkipBackup, "UpdateSkipBackup", "UpdateSkipBackupH")
		AddToolTip(UpdateSkipBackupH, "Skips making a backup of the install location/folder.")
	}		

	; Display

	GuiAddGroupBox("Display", "x7 y+20 w260 h150 Section")

	GuiAddCheckbox("Show item level (gear)", "xs10 ys20 w240 h30", Opts.ShowItemLevel, "ShowItemLevel")
	GuiAddCheckbox("Show max sockets based on item lvl (gear)", "xs10 ys50 w240 h30", Opts.ShowMaxSockets, "ShowMaxSockets", "ShowMaxSocketsH")
	AddToolTip(ShowMaxSocketsH, "Show maximum amount of sockets the item can have`nbased on its item level")
	GuiAddCheckbox("Show damage calculations (weapons)", "xs10 ys80 w240 h30", Opts.ShowDamageCalculations, "ShowDamageCalculations")
	GuiAddCheckbox("Show currency value in chaos", "xs10 ys110 w240 h30", Opts.ShowCurrencyValueInChaos, "ShowCurrencyValueInChaos")

	; Tooltip

	GuiAddGroupBox("Tooltip", "x7 y+20 w260 h185 Section")

	GuiAddCheckBox("Use tooltip timeout", "xs10 ys20 w210", Opts.UseTooltipTimeout, "UseTooltipTimeout", "UseTooltipTimeoutH", "SettingsUI_ChkUseTooltipTimeout")
	AddToolTip(UseTooltipTimeoutH, "Hide tooltip automatically after x amount of ticks have passed")
		GuiAddText("Timeout ticks (1 tick = 100ms):", "xs20 ys45 w150", "LblToolTipTimeoutTicks")
		GuiAddEdit(Opts.ToolTipTimeoutTicks, "xs180 ys41 w50 Number", "ToolTipTimeoutTicks")

	GuiAddCheckbox("Display at fixed coordinates", "xs10 ys70 w230", Opts.DisplayToolTipAtFixedCoords, "DisplayToolTipAtFixedCoords", "DisplayToolTipAtFixedCoordsH", "SettingsUI_ChkDisplayToolTipAtFixedCoords")
	AddToolTip(DisplayToolTipAtFixedCoordsH, "Show tooltip in virtual screen space at the fixed`ncoordinates given below. Virtual screen space means`nthe full desktop frame, including any secondary`nmonitors. Coords are relative to the top left edge`nand increase going down and to the right.")
		GuiAddText("X:", "xs30 ys97 w20", "LblScreenOffsetX")
		GuiAddEdit(Opts.ScreenOffsetX, "xs48 ys93 w40", "ScreenOffsetX")
		GuiAddText("Y:", "xs98 ys97 w20", "LblScreenOffsetY")
		GuiAddEdit(Opts.ScreenOffsetY, "xs118 ys93 w40", "ScreenOffsetY")

	GuiAddText("Mousemove threshold (px):", "xs10 ys127 w160 h20 0x0100", "LblMouseMoveThreshold", "LblMouseMoveThresholdH")
	AddToolTip(LblMouseMoveThresholdH, "Hide tooltip automatically after the mouse has moved x amount of pixels")
	GuiAddEdit(Opts.MouseMoveThreshold, "xs180 ys125 w50 h20 Number", "MouseMoveThreshold", "MouseMoveThresholdH")

	GuiAddText("Font Size:", "xs10 ys157 w160 h20", "LblFontSize")
	GuiAddEdit(Opts.FontSize, "xs180 ys155 w50 h20 Number", "FontSize")

	; Display - Affixes

	; This groupbox is positioned relative to the last control (first column), this is not optimal but makes it possible to wrap these groupboxes in Tabs without further repositing.
	displayAffixesPos := SkipItemInfoUpdateCall ? "415" : "505"
	GuiAddGroupBox("Display - Affixes", "xs270 yp-" displayAffixesPos " w260 h360 Section")

	GuiAddCheckbox("Show affix totals", "xs10 ys20 w210 h30", Opts.ShowAffixTotals, "ShowAffixTotals", "ShowAffixTotalsH")
	AddToolTip(ShowAffixTotalsH, "Show a statistic how many prefixes and suffixes`nthe item has")
	GuiAddCheckbox("Show affix details", "xs10 ys50 w210 h30", Opts.ShowAffixDetails, "ShowAffixDetails", "ShowAffixDetailsH", "SettingsUI_ChkShowAffixDetails")
	AddToolTip(ShowAffixDetailsH, "Show detailed affix breakdown. Note that crafted mods are not`nsupported and some ranges are guesstimated (marked with a *)")
		GuiAddCheckbox("Mirror affix lines", "xs30 ys80 w190 h30", Opts.MirrorAffixLines, "MirrorAffixLines", "MirrorAffixLinesH")
		AddToolTip(MirrorAffixLinesH, "Display truncated affix names within the breakdown")
	GuiAddCheckbox("Show affix level", "xs10 ys110 w210 h30", Opts.ShowAffixLevel, "ShowAffixLevel", "ShowAffixLevelH")
		AddToolTip(ShowAffixLevelH, "Show item level of the displayed affix value bracket")
	GuiAddCheckbox("Show affix bracket", "xs10 ys140 w210 h30", Opts.ShowAffixBracket, "ShowAffixBracket", "ShowAffixBracketH")
		AddToolTip(ShowAffixBracketH, "Show affix value bracket as is on the item")
	GuiAddCheckbox("Show affix max possible", "xs10 ys170 w210 h30", Opts.ShowAffixMaxPossible, "ShowAffixMaxPossible", "ShowAffixMaxPossibleH", "SettingsUI_ChkShowAffixMaxPossible")
		AddToolTip(ShowAffixMaxPossibleH, "Show max possible affix value bracket")
		GuiAddCheckbox("Max span starting from first", "xs30 ys200 w190 h30", Opts.MaxSpanStartingFromFirst, "MaxSpanStartingFromFirst", "MaxSpanStartingFromFirstH")
		AddToolTip(MaxSpanStartingFromFirstH, "Construct a pseudo range by combining the lowest possible`naffix value bracket with the max possible based on item level")
	GuiAddCheckbox("Show affix bracket tier", "xs10 ys230 w210 h30", Opts.ShowAffixBracketTier, "ShowAffixBracketTier", "ShowAffixBracketTierH", "SettingsUI_ChkShowAffixBracketTier")
		AddToolTip(ShowAffixBracketTierH, "Display affix bracket tier in reverse ordering,`nT1 being the best possible roll.")
		GuiAddCheckbox("Tier relative to item lvl", "xs30 ys260 w190 h20", Opts.TierRelativeToItemLevel, "TierRelativeToItemLevel", "TierRelativeToItemLevelH")
		GuiAddText("(hold Shift to toggle temporarily)", "xs50 ys280 w190 h20", "LblTierRelativeToItemLevelOverrideNote")
		AddToolTip(TierRelativeToItemLevelH, "When showing affix bracket tier, make T1 being best possible`ntaking item level into account.")
		GuiAddCheckbox("Show affix bracket tier total", "xs30 ys300 w190 h20", Opts.ShowAffixBracketTierTotal, "ShowAffixBracketTierTotal", "ShowAffixBracketTierTotalH")
		AddToolTip(ShowAffixBracketTierTotalH, "Show number of total affix bracket tiers in format T/N,`n where T = tier on item, N = number of total tiers available")
	GuiAddCheckbox("Show Darkshrine information", "xs10 ys330 w210 h20", Opts.ShowDarkShrineInfo, "ShowDarkShrineInfo", "ShowDarkShrineInfoH")
	AddToolTip(ShowDarkShrineInfoH, "Show information about possible Darkshrine effects")

	; Display - Results

	GuiAddGroupBox("Display - Results", "xs y+20 w260 h185 Section")

	GuiAddCheckbox("Compact double ranges", "xs10 ys20 w210 h30", Opts.CompactDoubleRanges, "CompactDoubleRanges", "CompactDoubleRangesH")
	AddToolTip(CompactDoubleRangesH, "Show double ranges as one range,`ne.g. x-y (to) z-w becomes x-w")
	GuiAddCheckbox("Compact affix types", "xs10 ys50 w210 h30", Opts.CompactAffixTypes, "CompactAffixTypes", "CompactAffixTypesH")
	AddToolTip(CompactAffixTypesH, "Replace affix type with a short-hand version,`ne.g. P=Prefix, S=Suffix, CP=Composite")


	GuiAddText("Mirror line field width:", "xs10 ys87 w110 h20", "LblMirrorLineFieldWidth")
	GuiAddEdit(Opts.MirrorLineFieldWidth, "xs130 ys85 w40 h20 Number", "MirrorLineFieldWidth")
	GuiAddText("Value range field width:", "xs10 ys112 w120 h20", "LblValueRangeFieldWidth")
	GuiAddEdit(Opts.ValueRangeFieldWidth, "xs130 ys110 w40 h20 Number", "ValueRangeFieldWidth")
	GuiAddText("Affix detail delimiter:", "xs10 ys137 w120 h20", "LblAffixDetailDelimiter")
	GuiAddEdit(Opts.AffixDetailDelimiter, "xs130 ys135 w40 h20", "AffixDetailDelimiter")
	GuiAddText("Affix detail ellipsis:", "xs10 ys162 w120 h20", "LblAffixDetailEllipsis")
	GuiAddEdit(Opts.AffixDetailEllipsis, "xs130 ys160 w40 h20", "AffixDetailEllipsis")

	GuiAddText("Mouse over settings or see the beginning of the PoE-Item-Info.ahk script for comments on what these settings do exactly.", "x277 yp+40 w250 h60")

	GuiAddButton("&Defaults", "x287 yp+55 w80 h23", "SettingsUI_BtnDefaults")
	GuiAddButton("&OK", "Default x372 yp+0 w75 h23", "SettingsUI_BtnOK")
	GuiAddButton("&Cancel", "x452 yp+0 w80 h23", "SettingsUI_BtnCancel")
	
	; close tabs in case some other script added some
	Gui, Tab
}

UpdateSettingsUI()
{
	Global

	GuiControl,, OnlyActiveIfPOEIsFront, % Opts.OnlyActiveIfPOEIsFront
	GuiControl,, PutResultsOnClipboard, % Opts.PutResultsOnClipboard
	GuiControl,, EnableAdditionalMacros, % Opts.EnableAdditionalMacros
	If (!SkipItemInfoUpdateCall) {
		GuiControl,, ShowUpdateNotifications, % Opts.ShowUpdateNotifications
		GuiControl,, UpdateSkipSelection, % Opts.UpdateSkipSelection
		GuiControl,, UpdateSkipBackup, % Opts.UpdateSkipBackup
	}
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

ShowUpdateNotes()
{
	; remove POE-Item-Info tooltip if still visible
	SetTimer, ToolTipTimer, Off
	ToolTip
	Gui, UpdateNotes:Destroy
	Fonts.SetUIFont(9)

	Files := Globals.Get("UpdateNoteFileList")
	
	TabNames := ""
	Loop, % Files.Length() {
		name := Files[A_Index][2]
		TabNames .= name "|"
	}
	
	StringTrimRight, TabNames, TabNames, 1
	PreSelect := Files.Length()
	Gui, UpdateNotes:Add, Tab3, Choose%PreSelect%, %TabNames%
	
	Loop, % Files.Length() {
		file := Files[A_Index][1]
		FileRead, notes, %file%
		Gui, UpdateNotes:Add, Edit, r50 ReadOnly w700 BackgroundTrans, %notes%		
		
		NextTab := A_Index + 1
		Gui, UpdateNotes:Tab, %NextTab%
	}
	Gui, UpdateNotes:Tab	
	
	SettingsUIWidth := 745
	SettingsUIHeight := 710
	SettingsUITitle := "Update Notes"
	Gui, UpdateNotes:Show, w%SettingsUIWidth% h%SettingsUIHeight%, %SettingsUITitle%
}

ShowChangedUserFiles()
{
	Gui, ChangedUserFiles:Destroy
	
	Gui, ChangedUserFiles:Add, Text, , Following user files were changed in the last update and `nwere overwritten (old files were backed up):
	
	Loop, Parse, overwrittenUserFiles, `n
	{
		If (StrLen(A_Loopfield) > 0) {
			Gui, ChangedUserFiles:Add, Text, y+5, %A_LoopField%	
		}		
	}
	Gui, ChangedUserFiles:Add, Button, y+10 gChangedUserFilesWindow_Cancel, Close
	Gui, ChangedUserFiles:Add, Button, x+10 yp+0 gChangedUserFilesWindow_OpenFolder, Open user folder
	Gui, ChangedUserFiles:Show, w300, Changed User Files
	ControlFocus, Close, Changed User Files
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

ReadConfig(ConfigDir = "", ConfigFile = "config.ini")
{
	Global
	If (StrLen(ConfigDir) < 1) {
		ConfigDir := userDirectory
	}
	ConfigPath := StrLen(ConfigDir) > 0 ? ConfigDir . "\" . ConfigFile : ConfigFile

	IfExist, %ConfigPath%
	{
		; General

		Opts.OnlyActiveIfPOEIsFront := IniRead(ConfigPath, "General", "OnlyActiveIfPOEIsFront", Opts.OnlyActiveIfPOEIsFront)
		Opts.PutResultsOnClipboard := IniRead(ConfigPath, "General", "PutResultsOnClipboard", Opts.PutResultsOnClipboard)
		Opts.EnableAdditionalMacros := IniRead(ConfigPath, "General", "EnableAdditionalMacros", Opts.EnableAdditionalMacros)
		Opts.ShowUpdateNotifications := IniRead(ConfigPath, "General", "ShowUpdateNotifications", Opts.ShowUpdateNotifications)
		Opts.UpdateSkipSelection := IniRead(ConfigPath, "General", "UpdateSkipSelection", Opts.UpdateSkipSelection)
		Opts.UpdateSkipBackup := IniRead(ConfigPath, "General", "UpdateSkipBackup", Opts.UpdateSkipBackup)

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

WriteConfig(ConfigDir = "", ConfigFile = "config.ini")
{
	Global
	If (StrLen(ConfigDir) < 1) {
		ConfigDir := userDirectory
	}
	ConfigPath := StrLen(ConfigDir) > 0 ? ConfigDir . "\" . ConfigFile : ConfigFile

	Opts.ScanUI()

	; General

	IniWrite(Opts.OnlyActiveIfPOEIsFront, ConfigPath, "General", "OnlyActiveIfPOEIsFront")
	IniWrite(Opts.PutResultsOnClipboard, ConfigPath, "General", "PutResultsOnClipboard")
	IniWrite(Opts.EnableAdditionalMacros, ConfigPath, "General", "EnableAdditionalMacros")
	IniWrite(Opts.ShowUpdateNotifications, ConfigPath, "General", "ShowUpdateNotifications")
	IniWrite(Opts.UpdateSkipSelection, ConfigPath, "General", "UpdateSkipSelection")
	IniWrite(Opts.UpdateSkipBackup, ConfigPath, "General", "UpdateSkipBackup")

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
	FileCopy, %A_ScriptDir%\resources\config\default_config.ini, %userDirectory%\config.ini
}

RemoveConfig()
{
	FileDelete, %userDirectory%\config.ini
}

StdOutStream(sCmd, Callback = "") {
	/*
		Runs commands in a hidden cmdlet window and returns the output.
	*/
							; Modified  :  Eruyome 18-June-2017
	Static StrGet := "StrGet"	; Modified  :  SKAN 31-Aug-2013 http://goo.gl/j8XJXY                             
							; Thanks to :  HotKeyIt         http://goo.gl/IsH1zs                                   
							; Original  :  Sean 20-Feb-2007 http://goo.gl/mxCdn
	64Bit := A_PtrSize=8
	
	DllCall( "CreatePipe", UIntP,hPipeRead, UIntP,hPipeWrite, UInt,0, UInt,0 )
	DllCall( "SetHandleInformation", UInt,hPipeWrite, UInt,1, UInt,1 )
	
	If 64Bit {
		VarSetCapacity( STARTUPINFO, 104, 0 )		; STARTUPINFO          ;  http://goo.gl/fZf24
		NumPut( 68,         STARTUPINFO,  0 )		; cbSize
		NumPut( 0x100,      STARTUPINFO, 60 )		; dwFlags    =>  STARTF_USESTDHANDLES = 0x100 
		NumPut( hPipeWrite, STARTUPINFO, 88 )		; hStdOutput
		NumPut( hPipeWrite, STARTUPINFO, 96 )		; hStdError
		
		VarSetCapacity( PROCESS_INFORMATION, 32 )	; PROCESS_INFORMATION  ;  http://goo.gl/b9BaI  
	} Else {
		VarSetCapacity( STARTUPINFO, 68,  0 )		; STARTUPINFO          ;  http://goo.gl/fZf24
		NumPut( 68,         STARTUPINFO,  0 )		; cbSize
		NumPut( 0x100,      STARTUPINFO, 44 )		; dwFlags    =>  STARTF_USESTDHANDLES = 0x100 
		NumPut( hPipeWrite, STARTUPINFO, 60 )		; hStdOutput
		NumPut( hPipeWrite, STARTUPINFO, 64 )		; hStdError
		
		VarSetCapacity( PROCESS_INFORMATION, 32 )	; PROCESS_INFORMATION  ;  http://goo.gl/b9BaI  
	}	    

	If ! DllCall( "CreateProcess", UInt,0, UInt,&sCmd, UInt,0, UInt,0 ;  http://goo.gl/USC5a
				, UInt,1, UInt,0x08000000, UInt,0, UInt,0
				, UInt,&STARTUPINFO, UInt,&PROCESS_INFORMATION ) 
	Return "" 
	, DllCall( "CloseHandle", UInt,hPipeWrite )
	, DllCall( "CloseHandle", UInt,hPipeRead )
	, DllCall( "SetLastError", Int,-1 )

	hProcess := NumGet( PROCESS_INFORMATION, 0 )
	If 64Bit {
		hThread  := NumGet( PROCESS_INFORMATION, 8 )
	} Else {
		hThread  := NumGet( PROCESS_INFORMATION, 4 )
	}

	DllCall( "CloseHandle", UInt,hPipeWrite )

	AIC := ( SubStr( A_AhkVersion, 1, 3 ) = "1.0" )                   ;  A_IsClassic 
	VarSetCapacity( Buffer, 4096, 0 ), nSz := 0 

	While DllCall( "ReadFile", UInt,hPipeRead, UInt,&Buffer, UInt,4094, UIntP,nSz, Int,0 ) {
		tOutput := ( AIC && NumPut( 0, Buffer, nSz, "Char" ) && VarSetCapacity( Buffer,-1 ) ) 
				? Buffer : %StrGet%( &Buffer, nSz, "CP850" )

		Isfunc( Callback ) ? %Callback%( tOutput, A_Index ) : sOutput .= tOutput
	}                   

	DllCall( "GetExitCodeProcess", UInt,hProcess, UIntP,ExitCode )
	DllCall( "CloseHandle",  UInt,hProcess  )
	DllCall( "CloseHandle",  UInt,hThread   )
	DllCall( "CloseHandle",  UInt,hPipeRead )
	DllCall( "SetLastError", UInt,ExitCode  )

	Return Isfunc( Callback ) ? %Callback%( "", 0 ) : sOutput      
}

ReadConsoleOutputFromFile(command, fileName) {
	file := "temp\" fileName ".txt"
	RunWait %comspec% /c "chcp 1251 /f >nul 2>&1 & %command% > %file%", , Hide  
	FileRead, io, %file%
	
	Return io
}

StrPutVar(Str, ByRef Var, Enc = "") {
	Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
	VarSetCapacity(Var, Len, 0)
	Return, StrPut(Str, &Var, Enc)
}

UriEncode(Uri, Enc = "UTF-8")	{
	StrPutVar(Uri, Var, Enc)
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	Loop
	{
		Code := NumGet(Var, A_Index - 1, "UChar")
		If (!Code)
			Break
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			Res .= Chr(Code)
		Else
			Res .= "%" . SubStr(Code + 0x100, -1)
	}
	SetFormat, IntegerFast, %f%
	Return, Res
}

ScriptInfo(Command) {
	; https://autohotkey.com/boards/viewtopic.php?t=9656
	; Command must be "ListLines", "ListVars", "ListHotkeys" or "KeyHistory".
    static hEdit := 0, pfn, bkp
    if !hEdit {
        hEdit := DllCall("GetWindow", "ptr", A_ScriptHwnd, "uint", 5, "ptr")
        user32 := DllCall("GetModuleHandle", "str", "user32.dll", "ptr")
        pfn := [], bkp := []
        for i, fn in ["SetForegroundWindow", "ShowWindow"] {
            pfn[i] := DllCall("GetProcAddress", "ptr", user32, "astr", fn, "ptr")
            DllCall("VirtualProtect", "ptr", pfn[i], "ptr", 8, "uint", 0x40, "uint*", 0)
            bkp[i] := NumGet(pfn[i], 0, "int64")
        }
    }
 
    if (A_PtrSize=8) {  ; Disable SetForegroundWindow and ShowWindow.
        NumPut(0x0000C300000001B8, pfn[1], 0, "int64")  ; return TRUE
        NumPut(0x0000C300000001B8, pfn[2], 0, "int64")  ; return TRUE
    } else {
        NumPut(0x0004C200000001B8, pfn[1], 0, "int64")  ; return TRUE
        NumPut(0x0008C200000001B8, pfn[2], 0, "int64")  ; return TRUE
    }
 
    static cmds := {ListLines:65406, ListVars:65407, ListHotkeys:65408, KeyHistory:65409}
    cmds[Command] ? DllCall("SendMessage", "ptr", A_ScriptHwnd, "uint", 0x111, "ptr", cmds[Command], "ptr", 0) : 0
 
    NumPut(bkp[1], pfn[1], 0, "int64")  ; Enable SetForegroundWindow.
    NumPut(bkp[2], pfn[2], 0, "int64")  ; Enable ShowWindow.
 
    ControlGetText, text,, ahk_id %hEdit%
    return text
}

GetContributors(AuthorsPerLine=0)
{
	IfNotExist, %A_ScriptDir%\resources\AUTHORS.txt
	{
		return "`r`n AUTHORS.txt missing `r`n"
	}
	Authors := "`r`n"
	i := 0
	Loop, Read, %A_ScriptDir%\resources\AUTHORS.txt, `r, `n
	{
		Authors := Authors . A_LoopReadLine . " "
		i += 1
		IF (AuthorsPerLine != 0 and mod(i, AuthorsPerLine) == 0) ; every four authors
		{
			Authors := Authors . "`r`n"
		}
	}
	return Authors
}

ShowAssignedHotkeys() {
	scriptInfo	:= ScriptInfo("ListHotkeys")
	hotkeys		:= []
	
	Loop, Parse, scriptInfo, `n`r, 
	{
		line		:= RegExReplace(A_Loopfield, "[\t]", "|")
		line		:= RegExReplace(line, "\|(?!\s)", "| ") . "|"
		fields	:= []
		
		If (StrLen(line)) {
			Pos		:= 0
			While Pos	:= RegExMatch(line, "i)(.*?\|+)", value, Pos + (StrLen(value) ? StrLen(value) : 1)) {
				fields.push(Trim(RegExReplace(value1, "\|")))
			}
			If (StrLen(fields[1]) and not InStr(fields[1], "--------")) {				
				hotkeys.push(fields)	
			}
		}
	}

	Gui, ShowHotkeys:Add, Text, , List of this scripts assigned hotkeys.
	Gui, ShowHotkeys:Default
	Gui, Font, , Courier New
	Gui, Font, , Consolas
	Gui, ShowHotkeys:Add, ListView, r25 w800 NoSortHdr Grid ReadOnly, Type | Enabled | Level | Running | Key combination	
	For key, val in hotkeys {	
		If (key != 1) {
			LV_Add("", val*)
			LV_ModifyCol()
		}
	}
	
	i := 0
	Loop % LV_GetCount("Column")
	{
		i++
		LV_ModifyCol(a_index,"AutoHdr")
	}
	
	text := "reg: The hotkey is implemented via the operating system's RegisterHotkey() function." . "`n"
	text .= "reg(no): Same as above except that this hotkey is inactive (due to being unsupported, disabled, or suspended)." . "`n"
	text .= "k-hook: The hotkey is implemented via the keyboard hook." . "`n"
	text .= "m-hook: The hotkey is implemented via the mouse hook." . "`n"
	text .= "2-hooks: The hotkey requires both the hooks mentioned above." . "`n"
	text .= "joypoll: The hotkey is implemented by polling the joystick at regular intervals." . "`n"
	text .= "`n"
	text .= "Enabled: Hotkey is assigned but enabled/disabled [on/off] via the Hotkey command." . "`n"
	
	Gui, ShowHotkeys:Add, Text, , % text
	
	Gui, ShowHotkeys:Show, w820 xCenter yCenter, Assigned Hotkeys
	Gui, 1:Default
	Gui, Font
}

CloseScripts() {
	; Close all active scripts listed in Globals.Get("ScriptList").
	; Can be used with scripts extending/including ItemInfo (TradeMacro for example) by adding to/altering this list.
	; Shortcut is placed in AdditionalMacros.txt
	
	scripts := Globals.Get("ScriptList")	
	currentScript := A_ScriptDir . "\" . A_ScriptName
	SplitPath, currentScript, , , ext, currentscript_name_no_ext
	currentScript :=  A_ScriptDir . "\" . currentscript_name_no_ext
	
	DetectHiddenWindows, On 

	Loop, % scripts.Length() {
		scriptPath := scripts[A_Index]
	
		; close current script last (with ExitApp)
		If (currentScript != scriptPath) {
			WinClose, %scriptPath% ahk_class AutoHotkey
		}
	}
	ExitApp
}

HighlightItems(broadTerms = false, leaveSearchField = true) {
	; Highlights items via stash search (also in vendor search)
	IfWinActive, Path of Exile ahk_class POEWindowClass 
	{
		Global Item, Opts, Globals, ItemData
		
		ClipBoardTemp := Clipboard
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
		
		; Parse the clipboard contents twice.
		; If the clipboard contains valid item data before we send ctrl + c to try and parse an item via ctrl + f then don't restore that clipboard data later on.
		; This prevents the highlighting function to fill search fields with data from previous item parsings/manual data copying since 
		; that clipboard data would always be restored again.
		Loop, 2 {
			If (A_Index = 2) {
				Clipboard := 
				Send ^{sc02E}	; ^{c}
				Sleep 100		
			}
			CBContents := GetClipboardContents()
			CBContents := PreProcessContents(CBContents)		
			Globals.Set("ItemText", CBContents)
			Globals.Set("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel)		
			ParsedData := ParseItemData(CBContents)
			If (A_Index = 1 and Item.Name) {
				dontRestoreClipboard := true
			}
		}

		If (Item.Name) {
			rarity := ""
			If (Item.RarityLevel = 2) {
				rarity := "magic"
			} Else If (Item.RarityLevel = 3) {
				rarity := "rare"
			} Else If (Item.RarityLevel = 4) {
				rarity := "unique"
			}
		
			terms := []
			; uniques / gems / div cards
			If (Item.IsUnique or Item.IsGem or Item.IsDivinationCard) {
				If (broadTerms) {
					If (Item.IsUnique) {
						terms.push("Rarity: Unique")
					} Else {
						terms.push("Rarity: " Item.BaseType)
					}					
				} Else {
					If (Item.IsUnique) {
						terms.push("Rarity: Unique")
					} Else {
						terms.push("Rarity: " Item.BaseType)
					}
					terms.push(Item.Name)
				}
			}
			; prophecies
			Else If (Item.IsProphecy) {
				If (broadTerms) {
					terms.push("this prophecy")
				} Else {
					terms.push("this prophecy")
					terms.push(Item.Name)
				}
			}
			; essences
			Else If (Item.IsEssence) {
				If (broadTerms) {
					terms.push("Rarity: Currency")
					terms.push("Essence")
				} Else {
					terms.push(Item.Name)
				}
			}
			; currency
			Else If (Item.IsCurrency) {
				If (broadTerms) {
					terms.push("Currency")
				} Else {
					terms.push(Item.Name)
				}
			}
			; maps
			Else If (Item.IsMap) {				
				If (broadTerms) {
					terms.push(" Map")
				} Else {
					terms.push(Item.SubType)
					terms.push("tier:" Item.MapTier)
				}
			}
			; flasks
			Else If (Item.IsFlask) {
				If (broadTerms) {
					terms.push("Consumes")
					terms.push(Item.SubType)
				} Else {
					terms.push(Item.TypeName)
				}		
			}
			; leaguestones
			Else If (Item.IsLeaguestone) {
				If (broadTerms) {
					terms.push(Item.BaseType)
				} Else {
					terms.push(Item.SubType)
				}				
			}
			; jewels
			Else If (Item.IsJewel) {
				If (broadTerms) {
					terms.push(Item.BaseType)
				} Else {					
					terms.push(Item.TypeName)
					terms.push(rarity)
				}	
			}
			; offerings / sacrifice and mortal fragments / guardian fragments / council keys / breachstones 
			Else If (RegExMatch(Item.Name, "i)Sacrifice At") or RegExMatch(Item.Name, "i)Fragment of") or RegExMatch(Item.Name, "i)Mortal ") or RegExMatch(Item.Name, "i)Offering to ") or RegExMatch(Item.Name, "i)'s Key") or RegExMatch(Item.Name, "i)Breachstone") or RegExMatch(Item.Name, "i)Reliquary Key")) {				
				If (broadTerms) {
					tmpName := RegExReplace(Item.Name, "i)(Sacrifice At).*|(Fragment of).*|(Mortal).*|.*('s Key)|.*(Breachstone)|(Reliquary Key)", "$1$2$3$4$5$6") 
					terms.push(tmpName)
				} Else {
					terms.push(Item.Name)
				}
			}
			; other items (weapons, armour pieces, jewelry etc)
			Else {			
				If (broadTerms) {
					If (Item.IsWeapon or Item.IsAmulet or Item.IsRing or Item.IsBelt or InStr(Item.SubType, "Shield")) {
						; add the term "Chance to Block" to remove items with "Energy Shield" from "Shield" searches
						If (InStr(Item.SubType, "Shield")) {
							terms.push("Chance to Block")
						}
						
						; add grip type to differentiate 1 and 2 handed weapons
						If (Item.GripType == "1H" and RegExMatch(Item.Subtype, "i)Sword|Mace|Axe")) {
							prefix := "One Handed"
						} Else If (Item.GripType == "2H") {
							prefix := "Two Handed"
						}
						
						; Handle Talismans, they have SubType "Amulet" but this won't be found ingame.
						If (Item.IsTalisman) {
							term := "Talisman Tier:"
						} Else {
							; add a space since all these terms have a preceding one, this reduces the chance of accidental matches
							; for example "Ring" found in "Voidbringers" or "during Flask effect"
							term := " " Item.SubType
						}						
						
						terms.push(prefix . term)	
					}
					; armour pieces are a bit special, the ingame information doesn't include "armour/body armour" or something alike. 
					; we can use the item defenses though to match armour pieces with the same defense types (can't differentiate between "Body Armour" and "Helmet").
					Else If (InStr(Item.BaseType, "Armour")) {
						For key, val in ItemData.Parts {
							If (RegExMatch(val, "i)(Energy Shield:)|(Armour:)|(Evasion Rating:)", match)) {
								Loop, 3 {
									If (StrLen(match%A_Index%)) {
										terms.push(match%A_Index%)
									}
								}
							}
						}
					}
				} Else {
					terms.push(Item.TypeName)
				}
			}
		}

		If (terms.length() > 0) {
			SendInput ^{sc021} ; sc021 = f
			searchText =
			For key, val in terms {		
				searchText = %searchText% "%val%"			
			}

			; the search field has a 50 character limit, we have to close the last term with a quotation mark
			If (StrLen(searchText) > 50) {
				newString := SubStr(searchText, 1, 50)
				temp := RegExReplace(newString, "i)""", Replacement = "", QuotationMarks)
				; make sure we have an equal amount of quotation marks (all terms properly enclosed)
				If (QuotationMarks&1) {					
					searchText := RegExReplace(newString, "i).$", """")				
				}
			}

			Clipboard := searchText
			Sleep 10
			SendEvent ^{sc02f}		; ctrl + v
			If (leaveSearchField) {
				SendInput {sc01c}	; enter
			} Else {
				SendInput ^{sc01e}	; ctrl + a
			}
		} Else {			
			SendInput ^{sc021}		; send ctrl + f in case we don't have information to input
		}

		Sleep, 10
		If (!dontRestoreClipboard) {
			Clipboard := ClipBoardTemp
		}		
		SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	}
}

AdvancedItemInfoExt() {
	IfWinActive, Path of Exile ahk_class POEWindowClass 
	{
		Global Item, Opts, Globals, ItemData
		
		ClipBoardTemp := Clipboard
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event
		
		Clipboard := 
		Send ^{sc02E}	; ^{c}
		Sleep 100		
		
		CBContents := GetClipboardContents()
		CBContents := PreProcessContents(CBContents)		
		Globals.Set("ItemText", CBContents)
		Globals.Set("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel)		
		ParsedData := ParseItemData(CBContents)
		
		If (Item.Name) {			
			itemTextBase64 := ""
			FileDelete, %A_ScriptDir%\temp\itemText.txt
			FileAppend, %CBContents%, %A_ScriptDir%\temp\itemText.txt, utf-8
			command		:= "certutil -encode -f ""%cd%\temp\itemText.txt"" ""%cd%\temp\base64ItemText.txt"" & type ""%cd%\temp\base64ItemText.txt"""
			itemTextBase64	:= ReadConsoleOutputFromFile(command, "encodeToBase64.txt")
			itemTextBase64	:= Trim(RegExReplace(itemTextBase64, "i)-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|77u/", ""))				
			itemTextBase64	:= UriEncode(itemTextBase64)
			itemTextBase64	:= RegExReplace(itemTextBase64, "i)^(%0D)?(%0A)?|((%0D)?(%0A)?)+$", "")
			url 			:= "http://pathof.info/?item=" itemTextBase64
			openWith := AssociatedProgram("html")
			OpenWebPageWith(openWith, Url)
		}
		SuspendPOEItemScript = 0
	}	
}

OpenWebPageWith(application, url) {
	If (InStr(application, "iexplore")) {
		ie := ComObjCreate("InternetExplorer.Application")
		ie.Visible:=True
		ie.Navigate(url)
	} Else {
		; while this should work with IE there may be cases where it doesn't
		Run, "%application%" -new-tab "%Url%"
	}
	Return
}

LookUpAffixes() {
	/*
		Opens item base on poeaffix.net
	*/
	IfWinActive, Path of Exile ahk_class POEWindowClass 
	{
		Global Item, Opts, Globals, ItemData
		
		ClipBoardTemp := Clipboard
		SuspendPOEItemScript = 1 ; This allows us to handle the clipboard change event		
		
		Clipboard := 
		Send ^{sc02E}	; ^{c}
		Sleep 100		
		
		CBContents := GetClipboardContents()
		CBContents := PreProcessContents(CBContents)		
		Globals.Set("ItemText", CBContents)
		Globals.Set("TierRelativeToItemLevelOverride", Opts.TierRelativeToItemLevel)		
		ParsedData := ParseItemData(CBContents)
		If (Item.Name) {
			dontRestoreClipboard := true
		}

		If (Item.Name) {
			url := "http://poeaffix.net/" 
			If (RegExMatch(Item.TypeName, "i)Sacrificial Garb")) {
				url 		.= "ch-garb" ; ".html"
			} Else {
				ev		:= RegExMatch(ItemData.Stats, "i)Evasion Rating") ? "ev" : ""
				ar		:= RegExMatch(ItemData.Stats, "i)Armour") ? "ar" : ""
				es		:= RegExMatch(ItemData.Stats, "i)Energy Shield") ? "es" : ""
				RegExMatch(Item.SubType, "i)Axe|Sword|Mace|Sceptre|Bow|Staff|Wand|Fish|Dagger", weapon)
				RegExMatch(Item.Subtype, "i)Amulet|Ring|Belt|Quiver|Flask", accessory)
				RegExMatch(Item.Subtype, "i)Cobalt|Viridian|Crimson", jewel)
				
				suffix	:= ar . ev . es . weapon . accessory . jewel
				StringLower, suffix, suffix
				
				boots	:= RegExMatch(Item.Subtype, "i)Boots") ? "bt" : ""
				chest 	:= RegExMatch(Item.Subtype, "i)BodyArmour") ? "ch" : ""
				gloves 	:= RegExMatch(Item.Subtype, "i)Gloves") ? "gl" : ""
				helmet 	:= RegExMatch(Item.Subtype, "i)Helmet") ? "hm" : ""
				shield 	:= RegExMatch(Item.Subtype, "i)Shield") ? "sh" : ""
				ac		:= StrLen(accessory) ? "ac" : ""
				jw		:= StrLen(jewel) ? "jw" : ""
				gripType 	:= Item.GripType != "None" ? Item.GripType : ""
				
				prefix	:= boots . chest . gloves . helmet . shield . gripType . ac . jw
				StringLower, prefix, prefix
				
				url		.= prefix "-" suffix ; ".html"
			}			
			openWith := AssociatedProgram("html")
			OpenWebPageWith(openWith, Url)
		}
		
		Sleep, 10
		If (!dontRestoreClipboard) {
			Clipboard := ClipBoardTemp
		}		
		SuspendPOEItemScript = 0 ; Allow Item info to handle clipboard change event
	}
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
	IF SuspendPOEItemScript = 0
	{
		If (Opts.OnlyActiveIfPOEIsFront)
		{
			; do nothing if Path of Exile isn't the foremost window
			IfWinActive, Path of Exile ahk_class POEWindowClass
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
	
ShowUpdateNotes:
	ShowUpdateNotes()
	return

ChangedUserFilesWindow_Cancel:
	Gui, ChangedUserFiles:Cancel
	return

ChangedUserFilesWindow_OpenFolder:
	Gui, ChangedUserFiles:Cancel
	GoSub, EditOpenUserSettings
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
		Gui, About:+owner1 -Caption +Border
		Gui, About:Font, S10 CA03410,verdana
		Gui, About:Add, Text, x260 y27 w170 h20 Center, Release %RelVer%
		Gui, About:Add, Button, 0x8000 x316 y300 w70 h21, Close
		Gui, About:Add, Picture, 0x1000 x17 y16 w230 h180, %A_ScriptDir%\resources\images\splash.png
		Gui, About:Font, Underline C3571AC,verdana
		Gui, About:Add, Text, x260 y57 w170 h20 gVisitForumsThread Center, PoE forums thread
		Gui, About:Add, Text, x260 y87 w170 h20 gAboutDlg_AhkHome Center, AutoHotkey homepage
		Gui, About:Add, Text, x260 y117 w170 h20 gAboutDlg_GitHub Center, PoE-ItemInfo GitHub
		Gui, About:Font, S7 CDefault normal, Verdana
		Gui, About:Add, Text, x16 y207 w410 h80,
		(LTrim
		Shows affix breakdowns and other useful infos for any item or item link.

		Usage: Set PoE to Windowed Fullscreen mode and hover over any item or item link. Press Ctrl+C to show a tooltip.

		(c) %A_YYYY% Hazydoc, Nipper4369 and contributors:
		)
		Gui, About:Add, Text, x16 y277 w270 h80, %Authors%

		FirstTimeA = No
	}
	
	height := Globals.Get("AboutWindowHeight", 340)
	width  := Globals.Get("AboutWindowWidth", 435)
	Gui, About:Show, h%height% w%width%, About..

	; Release counter animation
	tmpH = 0
	Loop, 20
	{
		tmpH += 1
		ControlMove, Static1,,,, %tmpH%, About..
		Sleep, 100
	}
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

AboutButtonClose:
AboutGuiClose:
	WinGet, AbtWndID, ID, About..
	DllCall("AnimateWindow", "Int", AbtWndID, "Int", 500, "Int", 0x00090010)
	WinActivate, ahk_id %MainWndID%
	return

EditOpenUserSettings:
    OpenUserSettingsFolder(Globals.Get("ProjectName"))
    return

EditAdditionalMacros:
	OpenUserDirFile("AdditionalMacros.txt")
	return

EditMapModWarnings:
	OpenUserDirFile("MapModWarnings.txt")
	return
	
EditCustomMacrosExample:
	OpenUserDirFile("CustomMacros\customMacros_example.txt")
	return

EditCurrencyRates:
	OpenCreateDataTextFile("CurrencyRates.txt")
	return
	
ReloadScript:
	scriptName := RegExReplace(Globals.Get("ProjectName"), "i)poe-", "Run_") . ".ahk"
	Run, "%A_AhkPath%" "%A_ScriptDir%\%scriptName%"
	return
	
ShowAssignedHotkeys:
	ShowAssignedHotkeys()
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
	
CheckForUpdates:
	If (not globalUpdateInfo.repo) {
		global globalUpdateInfo := {}
	}
	If (not SkipItemInfoUpdateCall) {
		globalUpdateInfo.repo := Globals.Get("GithubRepo")
		globalUpdateInfo.user := Globals.Get("GithubUser")
		globalUpdateInfo.releaseVersion	:= Globals.Get("ReleaseVersion")
		globalUpdateInfo.skipSelection	:= Opts.UpdateSkipSelection
		globalUpdateInfo.skipBackup		:= Opts.UpdateSkipBackup
		globalUpdateInfo.skipUpdateCheck	:= Opts.ShowUpdateNotifications
		SplashScreenTitle := "PoE-ItemInfo"
	}
	
	hasUpdate := PoEScripts_Update(globalUpdateInfo.user, globalUpdateInfo.repo, globalUpdateInfo.releaseVersion, globalUpdateInfo.skipUpdateCheck, userDirectory, isDevVersion, globalUpdateInfo.skipSelection, globalUpdateInfo.skipBackup)
	If (hasUpdate = "no update" and not firstUpdateCheck) {
		SplashTextOn, , , No update available
		Sleep 2000
		SplashTextOff
	}
Return
	
FetchCurrencyData:
	CurrencyDataJSON := {}
	currencyLeagues := ["Standard", "Hardcore", "tmpstandard", "tmphardcore"]
	
	Loop, % currencyLeagues.Length() {
		currencyLeague := currencyLeagues[A_Index]
		url  := "http://poe.ninja/api/Data/GetCurrencyOverview?league=" . currencyLeague
		file := A_ScriptDir . "\temp\currencyData_" . currencyLeague . ".json"
		UrlDownloadToFile, %url% , %file%

		Try {
			If (FileExist(file)) {
				FileRead, JSONFile, %file%
				parsedJSON := JSON.Load(JSONFile)				
				CurrencyDataJSON[currencyLeague] := parsedJSON.lines
				ParsedAtLeastOneLeague := True
			}
			Else	{
				CurrencyDataJSON[currencyLeague] := null
			}
		} Catch error {
			errorMsg := "Parsing the currency data (json) from poe.ninja failed for league:"
			errorMsg .= "`n" currencyLeague 
			;MsgBox, 16, PoE-ItemInfo - Error, %errorMsg%
		}
	}
	
	If (ParsedAtLeastOneLeague) {
		Globals.Set("LastCurrencyUpdate", A_NowUTC)
	}
	
	; parse JSON and write files to disk (like \data\CurrencyRates.txt)
	For league, data in CurrencyDataJSON {
		ratesFile := A_ScriptDir . "\temp\currencyRates_" . league . ".txt"
		ratesJSONFile := A_ScriptDir . "\temp\currencyData_" . league . ".json"
		FileDelete, %ratesFile% 
		FileDelete, %ratesJSONFile% 
		
		If (league == "tmpstandard" or league == "tmphardcore" ) {
			comment := InStr(league, "standard") ? ";Challenge Standard`n" : ";Challenge Hardcore`n"
		}
		Else {
			comment := ";Permanent " . league . "`n"
		}
		FileAppend, %comment%, %ratesFile%
		
		Loop, % data.Length() {
			cName       := data[A_Index].currencyTypeName
			cChaosEquiv := data[A_Index].chaosEquivalent
			
			If (cChaosEquiv >= 1) {
				cChaosQuantity := ZeroTrim(Round(cChaosEquiv, 2))
				cOwnQuantity   := 1
			}
			Else {
				cChaosQuantity := 1 
				cOwnQuantity   := ZeroTrim(Round(1 / cChaosEquiv, 2))
			}			
			
			result := cName . "|" . cOwnQuantity . ":" . cChaosQuantity . "`n"
			FileAppend, %result%, %ratesFile%
		}
	}
	
	CurrencyDataJSON :=
Return

ZeroTrim(number) {
	; Trim trailing zeros from numbers
	
	RegExMatch(number, "(\d+)\.?(.+)?", match)
	If (StrLen(match2) < 1) {
		Return number
	} Else {
		trail := RegExReplace(match2, "0+$", "")
		number := (StrLen(trail) > 0) ? match1 "." trail : match1
		Return number
	}
}

TogglePOEItemScript()
{
	IF SuspendPOEItemScript = 0
	{
		SuspendPOEItemScript = 1
		ShowToolTip("Item parsing PAUSED")
	}
	Else
	{
		SuspendPOEItemScript = 0
		ShowToolTip("Item parsing ENABLED")
	}
}

; ############ (user) macros #############
; macros are being appended here by merge script
