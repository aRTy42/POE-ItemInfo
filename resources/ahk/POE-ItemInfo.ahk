; Path of Exile ItemInfo
;
; Script is currently maintained by various people and kept up to date by aRTy42 / IGN: Erinyen
; Forum thread: https://www.pathofexile.com/forum/view-thread/1678678

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
		This.IsMirrored		:= False
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
	tierTop: The "best"  tier that matches, so the numerically lowest (!) tier.
	tierBtm: The "worst" tier that matches, so the numerically highest (!) tier.
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
	
	return {"tier":tier,"tierTop":tierTop,"tierBtm":tierBtm}
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
	FinalRange := AssembleValueRangeFields(BracketRange, BracketItemLevel, MaxRange, MaxLevel)
	return FinalRange
}

AssembleValueRangeFields(BracketRange, BracketItemLevel, MaxRange="", MaxLevel=0)
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
			FinalRange := FinalRange . " " . StrPad("(" . BracketItemLevel . ")", 4, Side="left")
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

MakeMapAffixLine(AffixLine, MapAffixCount)
{
	Line := AffixLine . "|" . MapAffixCount
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
		; Any empty line is considered as an Unprocessed Mod
		IF CurLine
		{
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
		}
		Else
		{
			ProcessedLine := "   Unprocessed Essence Mod or unknown Mod"
		}
		
		Result := Result . "`n" . ProcessedLine
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
		IF CurLine
		{
			ProcessedLine =
			Loop, %AffixLineParts0%
			{
				AffixLineParts%A_Index% =
			}
			StringSplit, AffixLineParts, CurLine, |
			AffixLine := AffixLineParts1
			MapAffixCount := AffixLineParts2
			
			ProcessedLine := Format("{1: 2s}) {2:s}", MapAffixCount, AffixLine)
		}
		Else
		{
			ProcessedLine := "   Unprocessed Essence Mod or unknown Mod"
		}
		
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
			IF (DsAffix = DsEffect1) {
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
	If (ItemQuality == 0)
	{
		return ValueRange
	}
	VRHi := 0
	VRLo := 0
	ParseRange(ValueRange, VRLo, VRHi)
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

RangeMid(Range)
{
	If (Range = 0 or Range = "0" or Range = "0-0")
	{
		return 0
	}
	RHi := 0
	RLo := 0
	ParseRange(Range, RLo, RHi)
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
	ParseRange(Range, RLo, RHi)
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
	ParseRange(Range, RLo, RHi)
	return RHi
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

Map_SetInfoLine(AffixType, ByRef MapAffixCount, EnumLabel="")
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
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "Monsters deal \d+% extra Damage as (Fire|Cold|Lightning)"))
		{
			MapModWarnings .= MapModWarn.MonstExtraEleDmg ? "`nExtra Ele Damage" : ""			
			Map_SetInfoLine("Prefix", MapAffixCount)
			
			Count_DmgMod += 1
			String_DmgMod := String_DmgMod . ", Extra Ele"
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters reflect \d+% of Elemental Damage"))
		{
			MapModWarnings .= MapModWarn.EleReflect ? "`nEle reflect" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters reflect \d+% of Physical Damage"))
		{
			MapModWarnings .= MapModWarn.PhysReflect ? "`nPhys reflect" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "\+\d+% Monster Physical Damage Reduction"))
		{
			MapModWarnings .= MapModWarn.MonstPhysDmgReduction ? "`nPhys Damage Reduction" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "\d+% less effect of Curses on Monsters"))
		{
			MapModWarnings .= MapModWarn.MonstLessCurse ? "`nLess Curse Effect" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "Monsters have a \d+% chance to avoid Poison, Blind, and Bleed"))
		{
			MapModWarnings .= MapModWarn.MonstAvoidPoisonBlindBleed ? "`nAvoid Poison/Blind/Bleed" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "Monsters have a \d+% chance to cause Elemental Ailments on Hit"))
		{
			MapModWarnings .= MapModWarn.MonstCauseElementalAilments ? "`nCause Elemental Ailments" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}

		If (RegExMatch(A_LoopField, "\d+% increased Monster Damage"))
		{
			MapModWarnings .= MapModWarn.MonstIncrDmg ? "`nIncreased Damage" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area is inhabited by 2 additional Rogue Exiles|Area has increased monster variety"))
		{
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area contains many Totems"))
		{
			MapModWarnings .= MapModWarn.ManyTotems ? "`nTotems" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters' skills Chain 2 additional times"))
		{
			MapModWarnings .= MapModWarn.MonstSkillsChain ? "`nSkills Chain" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Flag_SkillsChain := 1
			Continue
		}
		
		If (RegExMatch(A_LoopField, "All Monster Damage from Hits always Ignites"))
		{
			MapModWarnings .= MapModWarn.MonstHitsIgnite ? "`nHits Ignite" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Slaying Enemies close together can attract monsters from Beyond"))
		{
			MapModWarnings .= MapModWarn.Beyond ? "`nBeyond" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area contains two Unique Bosses"))
		{
			MapModWarnings .= MapModWarn.BossTwinned ? "`nTwinned Boss" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters are Hexproof"))
		{
			MapModWarnings .= MapModWarn.MonstHexproof ? "`nHexproof" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters fire 2 additional Projectiles"))
		{
			MapModWarnings .= MapModWarn.MonstTwoAdditionalProj ? "`nAdditional Projectiles" : ""
			Map_SetInfoLine("Prefix", MapAffixCount)
			Flag_TwoAdditionalProj := 1
			Continue
		}		
		
		
		
		If (RegExMatch(A_LoopField, "Players are Cursed with Elemental Weakness"))
		{
			MapModWarnings .= MapModWarn.EleWeakness ? "`nEle Weakness" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players are Cursed with Enfeeble"))
		{
			MapModWarnings .= MapModWarn.Enfeeble ? "`nEnfeeble" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players are Cursed with Temporal Chains"))
		{
			MapModWarnings .= MapModWarn.TempChains ? "`nTemp Chains" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players are Cursed with Vulnerability"))
		{
			MapModWarnings .= MapModWarn.Vulnerability ? "`nVulnerability" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			
			Count_DmgMod += 0.5
			String_DmgMod := String_DmgMod . ", Vuln"
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area has patches of burning ground"))
		{
			MapModWarnings .= MapModWarn.BurningGround ? "`nBurning ground" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area has patches of chilled ground"))
		{
			MapModWarnings .= MapModWarn.ChilledGround ? "`nChilled ground" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area has patches of shocking ground"))
		{
			MapModWarnings .= MapModWarn.ShockingGround ? "`nShocking ground" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)

			Count_DmgMod += 0.5
			String_DmgMod := String_DmgMod . ", Shocking"
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Area has patches of desecrated ground"))
		{
			MapModWarnings .= MapModWarn.DesecratedGround ? "`nDesecrated ground" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players gain \d+% reduced Flask Charges"))
		{
			MapModWarnings .= MapModWarn.PlayerReducedFlaskCharge ? "`nReduced Flask Charges" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters have \d+% increased Area of Effect"))
		{
			MapModWarnings .= MapModWarn.MonstIncrAoE ? "`nIncreased Monster AoE" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players have \d+% less Area of Effect"))
		{
			MapModWarnings .= MapModWarn.PlayerLessAoE ? "`nLess Player AoE" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters have \d+% chance to Avoid Elemental Ailments"))
		{
			MapModWarnings .= MapModWarn.MonstAvoidElementalAilments ? "`nMonsters Avoid Elemental Ailments" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players have \d+% less Recovery Rate of Life and Energy Shield"))
		{
			MapModWarnings .= MapModWarn.LessRecovery ? "`nLess Recovery" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters take \d+% reduced Extra Damage from Critical Strikes"))
		{
			MapModWarnings .= MapModWarn.MonstTakeReducedCritDmg ? "`nReduced Crit Damage" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "-\d+% maximum Player Resistances"))
		{
			MapModWarnings .= MapModWarn.PlayerReducedMaxRes ? "`n-Max Res" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			
			Count_DmgMod += 0.5
			String_DmgMod := String_DmgMod . ", -Max Res"
			Continue
		}

		If (RegExMatch(A_LoopField, "Players have Elemental Equilibrium"))
		{
			MapModWarnings .= MapModWarn.PlayerEleEquilibrium ? "`nEle Equilibrium" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players have Point Blank"))
		{
			MapModWarnings .= MapModWarn.PlayerPointBlank ? "`nPoint Blank" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Monsters Poison on Hit"))
		{
			MapModWarnings .= MapModWarn.MonstHitsPoison ? "`nHits Poison" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}
		
		If (RegExMatch(A_LoopField, "Players cannot Regenerate Life, Mana or Energy Shield"))
		{
			MapModWarnings .= MapModWarn.NoRegen ? "`nNo Regen" : ""
			Map_SetInfoLine("Suffix", MapAffixCount)
			Continue
		}

		
		; --- SIMPLE TWO LINE AFFIXES ---
		
		
		If (RegExMatch(A_LoopField, "Rare Monsters each have a Nemesis Mod|\d+% more Rare Monsters"))
		{
			If (Not Index_RareMonst)
			{
				MapModWarnings .= MapModWarn.MonstRareNemesis ? "`nNemesis" : ""
				Map_SetInfoLine("Prefix", MapAffixCount, "a")
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
				Map_SetInfoLine("Prefix", MapAffixCount, "a")
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
				Map_SetInfoLine("Prefix", MapAffixCount, "a")
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
				Map_SetInfoLine("Prefix", MapAffixCount, "a")
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
				Map_SetInfoLine("Prefix", MapAffixCount, "a")
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
				Map_SetInfoLine("Suffix", MapAffixCount, "a")
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
				Map_SetInfoLine("Suffix", MapAffixCount, "a")
				
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
				Map_SetInfoLine("Suffix", MapAffixCount, "a")
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
				Map_SetInfoLine("Suffix", MapAffixCount, "a")
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
				Map_SetInfoLine("Suffix", MapAffixCount, "a")
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
				Map_SetInfoLine("Prefix", MapAffixCount, "a")
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
; with ByRef BracketItemLevel:
;   ( *)(.+Rest) := CurrValue - RangeMid\((.+)\)\r *(.+) := LookupAffixBracket\((.+?), (.+?), (.+?), (.+?)\)
;   -> $1$4 := LookupRemainingAffixBracket($5, $6, CurrValue, $3, $8)
;
; w/o ByRef BracketItemLevel:
;   ( *)(.+Rest) := CurrValue - RangeMid\((.+)\)\r *(.+) := LookupAffixBracket\((.+?), (.+?), (.+?)\)
;   -> $1$4 := LookupRemainingAffixBracket($5, $6, CurrValue, $3)
;
LookupRemainingAffixBracket(Filename, ItemLevel, CurrValue, Bracket, ByRef BracketItemLevel=0)
{
	RestValue := CurrValue - RangeMid(Bracket)
	RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketItemLevel)
	If (Not IsValidBracket(RemainderBracket))
	{
		RestValue := CurrValue - RangeMin(Bracket)
		RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketItemLevel)
	}
	If (Not IsValidBracket(RemainderBracket))
	{
		RestValue := CurrValue - RangeMax(Bracket)
		RemainderBracket := LookupAffixBracket(Filename, ItemLevel, RestValue, BracketItemLevel)
	}
	return RemainderBracket
}

ParseLeagueStoneAffixes(ItemDataAffixes, Item) {
	; Placeholder
}

LookupAffixAndSetInfoLine(Filename, AffixType, ItemLevel, Value)
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
	Else If(AffixType =="Comp. Prefix")
	{
		AffixTotals.NumSuffixes += 0.5
	}
	Else If(AffixType =="Comp. Suffix")
	{
		AffixTotals.NumSuffixes += 0.5
	}
	
	CurrTier := 0
	ValueRange := LookupAffixData(Filename, ItemLevel, Value, "", CurrTier)
	AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
}




SolveAffixes_Mod1Mod2Hybr()
{

}

SolveAffixes_PreSuf(Num, Filepath1, Filepath2, ItemLevel)
{
	
}









ParseAffixes(ItemDataAffixes, Item)
{
	Global Globals, Opts, AffixTotals, AffixLines, Itemdata

	ItemDataChunk	:= ItemDataAffixes
	
	IfInString, ItemDataChunk, Unidentified
	{
		Return ; Not interested in unidentified items
	}
	
	ItemBaseType	:= Item.BaseType
	ItemSubType		:= Item.SubType
	ItemGripType	:= Item.GripType
	ItemLevel		:= Item.Level
	ItemQuality		:= Item.Quality
	ItemIsHybridArmour := Item.IsHybridArmour

	; Reset the AffixLines "array" and other vars
	ResetAffixDetailVars()

	; Composition flags
	;
	; The pre-pass loop sets line numbers for potentially ambiguous affixes and sets a few markers,
	; so that the composition of these affixes can be checked later.
	
	HasToArmour				:= 0
	HasToEvasion			:= 0
	HasToEnergyShield		:= 0
	HasToMaxLife			:= 0
	
	HasIncrArmour			:= 0
	HasIncrEvasion			:= 0
	HasIncrEnergyShield		:= 0
	HasStunBlockRecovery	:= 0
	
	HasHybridDefences		:= False
	HasIncrArmourAndES		:= 0
	HasIncrArmourAndEvasion	:= 0
	HasIncrEvasionAndES		:= 0

	HasIncrLightRadius		:= 0
	HasToAccuracyRating		:= 0
	HasIncrAccuracyRating	:= 0
	HasIncrPhysDmg			:= 0

	HasSpellDamage			:= 0
	HasMaxMana				:= 0
	HasMultipleCrafted		:= 0
	HasIIQ					:= 0
	
	HasLastLineNumber		:= 0
	AffixDataLines	:= []

	; The following values are used for new style complex affix support
	CAIncAccuracy				:= 0
	CAIncAccuracyAffixLine		:= ""
	CAIncAccuracyAffixLineNo		:= 0
	CAGlobalCritChance			:= 0
	CAGlobalCritChanceAffixLine	:= ""
	CAGlobalCritChanceAffixLineNo	:= 0

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
		
		AffixDataLines.Push( {"Text":A_LoopField, "Num":GetActualValue(A_LoopField)} )
		; AffixDataLines[1].Text stores the full text of the first line (yes, with index 1 and not 0)
		; AffixDataLines[1].Num stores just the extracted number
		
		++HasLastLineNumber		; Counts the affix text lines so that the last line can be checked for being a craft
		
		IfInString, A_LoopField, to Armour
		{
			HasToArmour := A_Index
			Continue
		}
		IfInString, A_LoopField, to Evasion Rating
		{
			HasToEvasion := A_Index
			Continue
		}
		IfInString, A_LoopField, to Energy Shield
		{
			HasToEnergyShield := A_Index
			Continue
		}
		IfInString, A_LoopField, to maximum Life
		{
			HasToMaxLife := A_Index
			Continue
		}
		IfInString, A_LoopField, increased Armour and Evasion	; it's indeed "Evasion" and not "Evasion Rating" here
		{
			HasHybridDefences		:= True
			HasIncrArmourAndEvasion	:= A_Index
			Continue
		}
		IfInString, A_LoopField, increased Armour and Energy Shield
		{
			HasHybridDefences	:= True
			HasIncrArmourAndES	:= A_Index
			Continue
		}
		IfInString, A_LoopField, increased Evasion and Energy Shield	; again "Evasion" and not "Evasion Rating"
		{
			HasHybridDefences	:= True
			HasIncrEvasionAndES	:= A_Index
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
			HasStunBlockRecovery := A_Index
			Continue
		}
		IfInString, A_LoopField, increased Quantity
		{
			HasIIQ := A_Index
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
			HasToAccuracyRating := A_Index
			Continue
		}
		IfInString, A_LoopField, increased Physical Damage
		{
			HasIncrPhysDmg := A_Index
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
		BracketItemLevel := 0

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

			; pure Attack Speed must be checked last
			IfInString, A_LoopField, increased Attack Speed
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
					CAIncAccuracy := CurrValue
					CAIncAccuracyAffixLine := A_LoopField
					CAIncAccuracyAffixLineNo := A_Index
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

			; pure Cast Speed must be checked last
			IfInString, A_LoopField, increased Cast Speed
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

			; Pure Critical Strike Chance must be checked last
			IfInString, A_LoopField, Critical Strike Chance
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
					CAGlobalCritChance			:= CurrValue
					CAGlobalCritChanceAffixLine	:= A_LoopField
					CAGlobalCritChanceAffixLineNo	:= A_Index
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
				LookupAffixAndSetInfoLine("data\jewel\ChanceToIgnite.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Ignite Duration on Enemies
			{
				LookupAffixAndSetInfoLine("data\jewel\IgniteDurationOnEnemies.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Freeze
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToFreeze.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Freeze Duration on Enemies
			{
				LookupAffixAndSetInfoLine("data\jewel\FreezeDurationOnEnemies.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Shock
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToShock.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Shock Duration on Enemies
			{
				LookupAffixAndSetInfoLine("data\jewel\ShockDurationOnEnemies.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to Poison
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToPoison.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Poison Duration
			{
				LookupAffixAndSetInfoLine("data\jewel\PoisonDurationOnEnemies.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, chance to cause Bleeding
			{
				LookupAffixAndSetInfoLine("data\jewel\ChanceToBleed.txt", "Comp. Suffix", ItemLevel, CurrValue)
				Continue
			}
			IfInString, A_LoopField, increased Bleed duration
			{
				LookupAffixAndSetInfoLine("data\jewel\BleedingDurationOnEnemies.txt", "Comp. Suffix", ItemLevel, CurrValue)
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
				AffixTotals.NumSuffixes += 1
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
			; Slinkston edit. Cleaned up the code. I think this is a better approach.
			AffixTotals.NumSuffixes += 1
			If (ItemSubType == "Wand" or ItemSubType == "Bow")
			{
				ValueRange := LookupAffixData("data\AttackSpeed_BowsAndWands.txt", ItemLevel, CurrValue, "", CurrTier)
			} Else If (ItemBaseType == "Weapon")
			{
				ValueRange := LookupAffixData("data\AttackSpeed_Weapons.txt", ItemLevel, CurrValue, "", CurrTier)
			} Else If (ItemSubType == "Shield")
			{
				ValueRange := LookupAffixData("data\AttackSpeed_Shield.txt", ItemLevel, CurrValue, "", CurrTier)
			} Else
			{
				ValueRange := LookupAffixData("data\AttackSpeed_ArmourAndItems.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}

		IfInString, A_LoopField, increased Accuracy Rating
		{
			AffixTotals.NumSuffixes += 1
			ValueRange := LookupAffixData("data\IncrAccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
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
			} Else If (ItemSubtype == "Shield") {
				; The native mod only appears on bases with ES
				ValueRange := LookupAffixData("data\CastSpeedShield.txt", ItemLevel, CurrValue, "", CurrTier)
			} Else {
				; All shields can receive a cast speed master mod.
				; Leaving this as non shield specific if the master mod ever becomes applicable on something else
				ValueRange := LookupAffixData("data\CastSpeedCraft.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			AffixTotals.NumSuffixes += 1
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
			AffixTotals.NumSuffixes += 1
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
			AffixTotals.NumSuffixes += 1
			Continue
		}

		IfInString, A_LoopField, increased Fire Damage
		{
			LookupAffixAndSetInfoLine("data\IncrFireDamage.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Cold Damage
		{
			LookupAffixAndSetInfoLine("data\IncrColdDamage.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, increased Lightning Damage
		{
			LookupAffixAndSetInfoLine("data\IncrLightningDamage.txt", "Suffix", ItemLevel, CurrValue)
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
			LookupAffixAndSetInfoLine("data\BlockChance.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		If RegExMatch(A_LoopField, ".*increased Damage$")
		{
			; Can be either Leo prefix or jewel suffix.
			LookupAffixAndSetInfoLine("data\IncrDamageLeo.txt", "Prefix", ItemLevel, CurrValue)
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

		IfInString, A_LoopField, increased Quantity
		{
			LookupAffixAndSetInfoLine("data\IIQ.txt", "Suffix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Life gained on Kill
		{
			LookupAffixAndSetInfoLine("data\LifeOnKill.txt", "Suffix", ItemLevel, CurrValue)
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
			AffixTotals.NumSuffixes += 1
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

		IfInString, A_LoopField, to Armour
		{
			If(ItemIsHybridArmour == False)
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
					ValueRange := LookupAffixData("data\ToArmourGlovesAndBoots.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\ToArmourArmourAndShield.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				AffixTotals.NumPrefixes += 1
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
				Continue
			}
			Else
			{
				If (ItemSubtype == "Helmet")
				{
					ValueRange := LookupAffixData("data\ToArmourHelmet_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else If (ItemSubtype == "Gloves" or ItemSubType == "Boots")
				{
					ValueRange := LookupAffixData("data\ToArmourGlovesAndBoots_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\ToArmourArmourAndShield_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				AffixTotals.NumPrefixes += 0.5
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Prefix", ValueRange, CurrTier), A_Index)
				Continue
			}
		}
		IfInString, A_LoopField, increased Armour and Evasion
		{
			AffixType		:= "Prefix"
			AEBracketItemLevel := 0
			ValueRange	:= LookupAffixData("data\IncrArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketItemLevel, CurrTier)
			If (HasStunBlockRecovery)
			{
				AEBracketItemLevel2 := AEBracketItemLevel

				AEBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AEBracketItemLevel2)
				If (Not IsValidRange(ValueRange) and IsValidBracket(AEBracket))
				{
					ValueRange := LookupAffixData("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AEBracketItemLevel2, CurrTier)
				}
				AffixType			:= "Comp. Prefix"
				BSRecBracketItemLevel	:= 0
				BSRecValue		:= ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
				BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Hybrid.txt", AEBracketItemLevel2, "", BSRecBracketItemLevel)
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
					BSRecBracketItemLevel	:= 0
					BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketItemLevel)
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
						BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketItemLevel)
					}

					AEBSBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", BSRecBracketItemLevel)

					If (Not WithinBounds(AEBSBracket, CurrValue))
					{
						AEBracket := LookupRemainingAffixBracket("data\IncrArmourAndEvasion.txt", ItemLevel, CurrValue, AEBSBracket)

						If (Not IsValidBracket(AEBracket))
						{
							AEBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
						}
						If (IsValidBracket(AEBracket) and WithinBounds(AEBracket, CurrValue))
						{
							If (AffixTotals.NumPrefixes < 2)
							{
								ValueRange	:= AddRange(AEBSBracket, AEBracket)
								ValueRange	:= MarkAsGuesstimate(ValueRange)
								AffixType		:= "Comp. Prefix+Prefix"
								AffixTotals.NumPrefixes += 1
							}
							Else
							{
								ValueRange	:= LookupAffixData("data\IncrArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketItemLevel2, CurrTier)
								AffixType		:= "Prefix"
							}
						}
						Else
						{
							; Check if it isn't a simple case of Armour and Evasion (Prefix) + Stun Recovery (Suffix)
							BSRecBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRecValue, BSRecBracketItemLevel, CurrTier)
							If (IsValidRange(ValueRange) and IsValidBracket(BSRecBracket))
							{
								; -2 means for later that processing this hybrid defence stat
								; determined that Stun Recovery should be a simple suffix
								BSRecPartial	:= ""
								AffixType		:= "Prefix"
								ValueRange	:= LookupAffixData("data\IncrArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketItemLevel, CurrTier)
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
			AffixTotals.NumPrefixes += 1
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, increased Armour and Energy Shield
		{
			AffixType		:= "Prefix"
			AESBracketItemLevel:= 0
			ValueRange	:= LookupAffixData("data\IncrArmourAndEnergyShield.txt", ItemLevel, CurrValue, AESBracketItemLevel, CurrTier)
			If (HasStunBlockRecovery)
			{
				AESBracketItemLevel2 := AESBracketItemLevel

				AESBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AESBracketItemLevel2)
				If (Not IsValidRange(ValueRange) and IsValidBracket(AESBracket))
				{
					ValueRange := LookupAffixData("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AESBracketItemLevel2, CurrTier)
				}
				AffixType			:= "Comp. Prefix"
				BSRecBracketItemLevel	:= 0
				BSRecValue		:= ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
				BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Hybrid.txt", AESBracketItemLevel2, "", BSRecBracketItemLevel)
				If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(AESBracket))
				{
					BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", AESBracketItemLevel, "", BSRecBracketItemLevel)
				}
				If (Not IsValidBracket(BSRecPartial))
				{
					BSRecBracketItemLevel	:= 0
					BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketItemLevel)
					If (Not IsValidBracket(BSRecPartial))
					{
						BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketItemLevel)
					}

					AESBSBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", BSRecBracketItemLevel)

					If (Not WithinBounds(AESBSBracket, CurrValue))
					{
						AESBracket := LookupRemainingAffixBracket("data\IncrArmourAndEnergyShield.txt", ItemLevel, CurrValue, AESBSBracket)
						If (Not IsValidBracket(AESBracket))
						{
							AESBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
						}
						If (Not WithinBounds(AESBracket, CurrValue))
						{
							ValueRange	:= AddRange(AESBSBracket, AESBracket)
							ValueRange	:= MarkAsGuesstimate(ValueRange)
							AffixType		:= "Comp. Prefix+Prefix"
							AffixTotals.NumPrefixes += 1
						}
					}
					If (WithinBounds(BSRecPartial, BSRecValue))
					{
						; BS Recovery value within bounds, this means BS Rec is all acounted for
						BSRecPartial =
					}
				}
			}
			AffixTotals.NumPrefixes += 1
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, increased Evasion and Energy Shield
		{
			AffixType		:= "Prefix"
			EESBracketItemLevel:= 0
			ValueRange	:= LookupAffixData("data\IncrEvasionAndEnergyShield.txt", ItemLevel, CurrValue, EESBracketItemLevel, CurrTier)
			If (HasStunBlockRecovery)
			{
				EESBracketItemLevel2 := EESBracketItemLevel

				EESBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue, EESBracketItemLevel2)
				If (Not IsValidRange(ValueRange) and IsValidBracket(EESBracket))
				{
					ValueRange := LookupAffixData("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue, EESBracketItemLevel2, CurrTier)
				}

				AffixType			:= "Comp. Prefix"
				BSRecBracketItemLevel	:= 0
				BSRecValue		:= ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
				BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Hybrid.txt", EESBracketItemLevel2, "", BSRecBracketItemLevel)
				If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(EESBracket))
				{
					BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", EESBracketItemLevel, "", BSRecBracketItemLevel)
				}
				If (Not IsValidBracket(BSRecPartial))
				{
					BSRecBracketItemLevel	:= 0
					BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketItemLevel)
					If (Not IsValidBracket(BSRecPartial))
					{
						BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketItemLevel)
					}

					EESBSBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", BSRecBracketItemLevel)

					If (Not WithinBounds(EESBSBracket, CurrValue))
					{
						EESBracket := LookupRemainingAffixBracket("data\IncrEvasionAndEnergyShield.txt", ItemLevel, CurrValue, EESBSBracket)

						If (Not IsValidBracket(EESBracket))
						{
							EESBracket := LookupAffixBracket("data\IncrHybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
						}
						If (Not WithinBounds(EESBracket, CurrValue))
						{
							ValueRange	:= AddRange(EESBSBracket, EESBracket)
							ValueRange	:= MarkAsGuesstimate(ValueRange)
							AffixType		:= "Comp. Prefix+Prefix"
							AffixTotals.NumPrefixes += 1
						}
					}

					If (WithinBounds(BSRecPartial, BSRecValue))
					{
						; BS Recovery value within bounds, this means BS Rec is all acounted for
						BSRecPartial =
					}
				}
			}
			AffixTotals.NumPrefixes += 1
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, increased Armour
		{
			AffixType		:= "Prefix"
			IABracketItemLevel	:= 0
			If (ItemBaseType == "Item")
			{
				; Global (Amulet)
				PrefixPath := "data\IncrArmour_Global.txt"
				PrefixPathOther := "data\IncrArmour_Local.txt"
			}
			Else
			{
				; Local
				PrefixPath := "data\IncrArmour_Local.txt"
				PrefixPathOther := "data\IncrArmour_Global.txt"
			}
			ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IABracketItemLevel, CurrTier)
			If (Not IsValidRange(ValueRange))
			{
				ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, IABracketItemLevel, CurrTier)
			}
			If (HasStunBlockRecovery)
			{
				IABracketItemLevel2 := IABracketItemLevel

				ASRBracket := LookupAffixBracket("data\IncrArmour_StunRecovery.txt", ItemLevel, CurrValue, IABracketItemLevel2)
				If (Not IsValidRange(ValueRange) and IsValidBracket(ASRBracket))
				{
					ValueRange := LookupAffixData("data\IncrArmour_StunRecovery.txt", ItemLevel, CurrValue, IABracketItemLevel2, CurrTier)
				}

				AffixType			:= "Comp. Prefix"
				BSRecBracketItemLevel	:= 0
				BSRecValue		:= ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
				BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Armour.txt", IABracketItemLevel2, "", BSRecBracketItemLevel)
				If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ASRBracket))
				{
					BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", IABracketItemLevel, "", BSRecBracketItemLevel)
				}
				If (Not IsValidBracket(BSRecPartial))
				{
					BSRecBracketItemLevel	:= 0
					BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Armour.txt", ItemLevel, BSRecValue, BSRecBracketItemLevel)
					If (Not IsValidBracket(BSRecPartial))
					{
						BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", ItemLevel, "", BSRecBracketItemLevel)
					}

					IABSBracket := LookupAffixBracket("data\IncrArmour_StunRecovery.txt", BSRecBracketItemLevel)

					If (Not WithinBounds(IABSBracket, CurrValue))
					{
						IABracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IABSBracket)
						If (Not IsValidBracket(IABracket))
						{
							IABracket := LookupAffixBracket(PrefixPath, ItemLevel, CurrValue)
						}
						If (Not WithinBounds(IABracket, CurrValue))
						{
							ValueRange	:= AddRange(IABSBracket, IABracket)
							ValueRange	:= MarkAsGuesstimate(ValueRange)
							AffixType		:= "Comp. Prefix+Prefix"
							AffixTotals.NumPrefixes += 1
						}
					}

					If (WithinBounds(BSRecPartial, BSRecValue))
					{
						; BS Recovery value within bounds, this means BS Rec is all acounted for
						BSRecPartial =
					}
				}
			}
			AffixTotals.NumPrefixes += 1
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			Continue
		}
		
		IfInString, A_LoopField, to Evasion Rating
		{
			If(ItemIsHybridArmour == False)
			{
				; Slinkston edit. I am not sure if using 'Else If' statements are the best way here, but it seems to work.
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
					ValueRange := LookupAffixData("data\ToEvasionGlovesAndBoots.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\ToEvasionArmourAndShield.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				AffixTotals.NumPrefixes += 1
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
				Continue
			}
			Else
			{
				If (ItemSubType == "Helmet")
				{
					ValueRange := LookupAffixData("data\ToEvasionHelmet_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else If (ItemSubType == "Gloves" or ItemSubType == "Boots")
				{
					ValueRange := LookupAffixData("data\ToEvasionGlovesAndBoots_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\ToEvasionArmourAndShield_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				AffixTotals.NumPrefixes += 0.5
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Prefix", ValueRange, CurrTier), A_Index)
				Continue
			}
		}
		IfInString, A_LoopField, increased Evasion Rating
		{
			AffixType		:= "Prefix"
			IEBracketItemLevel := 0
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
			ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IEBracketItemLevel, CurrTier)
			If (Not IsValidRange(ValueRange))
			{
				ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, IEBracketItemLevel, CurrTier)
			}
			If (HasStunBlockRecovery)
			{
				IEBracketItemLevel2 := IEBracketItemLevel

				; Determine composite bracket level and store in IEBracketItemLevel2, for example:
				;   8% increased Evasion
				;   26% increased Stun and Block Recovery
				;   => 8% is bracket level 2 (6-14), so 'B&S Recovery from Evasion' level 2 makes
				;      BSRec partial 6-7
				ERSRBracket := LookupAffixBracket("data\IncrEvasion_StunRecovery.txt", ItemLevel, CurrValue, IEBracketItemLevel2)
				If (Not IsValidRange(ValueRange) and IsValidBracket(ERSRBracket))
				{
					ValueRange := LookupAffixData("data\IncrEvasion_StunRecovery.txt", ItemLevel, CurrValue, IEBracketItemLevel2, CurrTier)
				}

				AffixType			:= "Comp. Prefix"
				BSRecBracketItemLevel	:= 0
				BSRecValue		:= ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
				BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Evasion.txt", IEBracketItemLevel2, "", BSRecBracketItemLevel)
				If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ERSRBracket))
				{
					BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", IEBracketItemLevel, "", BSRecBracketItemLevel)
				}
				If (Not IsValidRange(ValueRange) and (Not IsValidBracket(BSRecPartial) or Not WithinBounds(BSRecPartial, BSRecValue)))
				{
					BSRecBracketItemLevel	:= 0
					BSRecPartial		:= LookupAffixBracket("data\StunRecovery_Evasion.txt", ItemLevel, BSRecValue, BSRecBracketItemLevel)
					If (Not IsValidBracket(BSRecPartial))
					{
						BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", ItemLevel, "", BSRecBracketItemLevel)
					}

					IEBSBracket := LookupAffixBracket("data\IncrEvasion_StunRecovery.txt", BSRecBracketItemLevel)

					If (Not WithinBounds(IEBSBracket, CurrValue))
					{
						IEBracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IEBSBracket)
						If (Not IsValidBracket(IEBracket))
						{
							IEBracket := LookupAffixBracket(PrefixPath, ItemLevel, CurrValue, "")
						}
						If (Not WithinBounds(IEBracket, CurrValue))
						{
							ValueRange	:= AddRange(IEBSBracket, IEBracket)
							ValueRange	:= MarkAsGuesstimate(ValueRange)
							AffixType		:= "Comp. Prefix+Prefix"
							AffixTotals.NumPrefixes += 1
						}
					}

					If (WithinBounds(BSRecPartial, BSRecValue))
					{
						; BS Recovery value within bounds, this means BS Rec is all acounted for
						BSRecPartial =
					}
				}
			}
			AffixTotals.NumPrefixes += 1
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			Continue
		}
		
		IfInString, A_LoopField, to maximum Energy Shield
		{
			If(ItemIsHybridArmour == False)
			{
				; Slinkston Edit. Seems I may have to do the same for EV and AR.
				; AR, EV, and ES items are all correct for Armour, Shields, Helmets, Boots, Gloves, and different jewelry.
				; to max ES is found is all jewelry; Amulet, Belt, and Ring.
				If (ItemSubType == "Amulet" or ItemSubType == "Belt")
				{
					ValueRange := LookupAffixData("data\ToMaxESAmuletAndBelt.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else If (ItemSubType == "Ring")
				{
					ValueRange := LookupAffixData("data\ToMaxESRing.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else If (ItemSubType == "Gloves" or ItemSubtype == "Boots")
				{
					ValueRange := LookupAffixData("data\ToMaxESGlovesAndBoots.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else If (ItemSubType == "Helmet")
				{
					ValueRange := LookupAffixData("data\ToMaxESHelmet.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else If (ItemSubType == "Shield")
				{
					ValueRange := LookupAffixData("data\ToMaxESShield.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\ToMaxESArmour.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				AffixTotals.NumPrefixes += 1
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
				Continue
			}
			Else
			{
				If (ItemSubType == "Gloves" or ItemSubtype == "Boots")
				{
					ValueRange := LookupAffixData("data\ToMaxESGlovesAndBoots_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else If (ItemSubType == "Helmet")
				{
					ValueRange := LookupAffixData("data\ToMaxESHelmet_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				Else
				{
					ValueRange := LookupAffixData("data\ToMaxESArmourAndShield_HybridBase.txt", ItemLevel, CurrValue, "", CurrTier)
				}
				AffixTotals.NumPrefixes += 0.5
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Prefix", ValueRange, CurrTier), A_Index)
				Continue
			}
		}
		
		IfInString, A_LoopField, increased Energy Shield
		{
			AffixType		:= "Prefix"
			IESBracketItemLevel:= 0
			PrefixPath	:= "data\IncrEnergyShield.txt"
			ValueRange	:= LookupAffixData(PrefixPath, ItemLevel, CurrValue, IESBracketItemLevel, CurrTier)

			If (HasStunBlockRecovery)
			{
				IESBracketItemLevel2 := IESBracketItemLevel

				ESSRBracket := LookupAffixBracket("data\IncrEnergyShield_StunRecovery.txt", ItemLevel, CurrValue, IESBracketItemLevel2)
				If (Not IsValidRange(ValueRange) and IsValidBracket(ESSRBracket))
				{
					ValueRange := LookupAffixData("data\IncrEnergyShield_StunRecovery.txt", ItemLevel, CurrValue, IESBracketItemLevel2, CurrTier)
				}

				AffixType			:= "Comp. Prefix"
				BSRecBracketItemLevel	:= 0
				BSRecPartial		:= LookupAffixBracket("data\StunRecovery_EnergyShield.txt", IESBracketItemLevel2, "", BSRecBracketItemLevel)
				BSRecValue		:= ExtractValueFromAffixLine(ItemDataChunk, "increased Stun and Block Recovery")
				If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ESSRBracket))
				{
					BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", IESBracketItemLevel, "", BSRecBracketItemLevel)
				}
				If (Not IsValidBracket(BSRecPartial))
				{
					BSRecBracketItemLevel	:= 0
					BSRecPartial		:= LookupAffixBracket("data\StunRecovery_EnergyShield.txt", ItemLevel, BSRecValue, BSRecBracketItemLevel)
					If (Not IsValidBracket(BSRecPartial))
					{
						BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", ItemLevel, "", BSRecBracketItemLevel)
					}
					IESBSBracket := LookupAffixBracket("data\IncrEnergyShield_StunRecovery.txt", BSRecBracketItemLevel)

					If (Not WithinBounds(IEBSBracket, CurrValue))
					{
						IESBracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IESBSBracket)

						If (Not WithinBounds(IESBracket, CurrValue))
						{
							ValueRange	:= AddRange(IESBSBracket, IESBracket)
							ValueRange	:= MarkAsGuesstimate(ValueRange)
							AffixType		:= "Comp. Prefix+Prefix"
							AffixTotals.NumPrefixes += 1
						}
					}

					If (WithinBounds(BSRecPartial, BSRecValue))
					{
						; BS Recovery value within bounds, this means BS Rec is all acounted for
						BSRecPartial =
					}
				}
			}
			AffixTotals.NumPrefixes += 1
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, increased maximum Energy Shield
		{
			AffixTotals.NumPrefixes += 1
			ValueRange	:= LookupAffixData("data\IncrMaxEnergyShield_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			Continue
		}
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
				ValueRange := LookupAffixData("data\AddedPhysDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
			}

			Else If (ItemSubType == "Quiver")
			{
				ValueRange := LookupAffixData("data\AddedPhysDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Ring")
			{
				ValueRange := LookupAffixData("data\AddedPhysDamage_Rings.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			
			Else If (ItemSubType == "Gloves")
			{
				;Gloves added by Bahnzo
				ValueRange := LookupAffixData("data\AddedPhysDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			Else
			{
				; There is no Else for rare items. Just lookup in 1H for now...
				ValueRange := LookupAffixData("data\AddedPhysDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
			}

			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			AffixTotals.NumPrefixes += 1
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
				ValueRange := LookupAffixData("data\AddedColdDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
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
			AffixTotals.NumPrefixes += 1
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
				ValueRange := LookupAffixData("data\AddedFireDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
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
			AffixTotals.NumPrefixes += 1
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
				ValueRange := LookupAffixData("data\AddedLightningDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
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
			AffixTotals.NumPrefixes += 1
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
				ValueRange := LookupAffixData("data\AddedChaosDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
			AffixTotals.NumPrefixes += 1
			Continue
		}

		IfInString, A_LoopField, Physical Damage to Melee Attackers
		{
			AffixTotals.NumPrefixes += 1
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
			AffixTotals.NumPrefixes += 1
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
			AffixTotals.NumPrefixes += 1
			Continue
		}
		IfInString, A_LoopField, Physical Attack Damage Leeched as
		{
			LookupAffixAndSetInfoLine("data\PhysicalAttackDamageLeeched.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		IfInString, A_LoopField, Movement Speed
		{
			LookupAffixAndSetInfoLine("data\MovementSpeed.txt", "Prefix", ItemLevel, CurrValue)
			Continue
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
		
		; --- MASTER CRAFT ONLY AFFIXES ---
		
		
		; Haku prefix
		IfInString, A_LoopField, to Quality of Socketed Support Gems
		{
			LookupAffixAndSetInfoLine("data\GemQuality_Support.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Elreon prefix
		IfInString, A_LoopField, to Mana Cost of Skills
		{
			LookupAffixAndSetInfoLine("data\ManaCostOfSkills.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Vorici prefix
		IfInString, A_LoopField, increased Life Leeched per Second
		{
			LookupAffixAndSetInfoLine("data\LifeLeechedPerSecond.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Vagan prefix
		IfInString, A_LoopField, Hits can't be Evaded
		{
			LookupAffixAndSetInfoLine("data\HitsCantBeEvaded.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Tora prefix
		IfInString, A_LoopField, Causes Bleeding on Hit
		{
			LookupAffixAndSetInfoLine("data\CausesBleedingOnHit.txt", "Prefix", ItemLevel, CurrValue)
			Continue
		}
		; Tora dual suffixes
		IfInString, A_LoopField, increased Trap Throwing Speed
		{
			AffixTotals.NumSuffixes += 1
			ValueRange	:= LookupAffixData("data\IncrTrapThrowingMineLayingSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, increased Mine Laying Speed
		{
			; No suffix increase because composite with above
			ValueRange	:= LookupAffixData("data\IncrTrapThrowingMineLayingSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
			Continue
		}
		IfInString, A_LoopField, increased Trap Damage
		{
			AffixTotals.NumSuffixes += 1
			ValueRange	:= LookupAffixData("data\IncrTrapMineDamage.txt", ItemLevel, CurrValue, "", CurrTier)
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
	
	If ( HasToArmour or HasToEvasion or HasToEnergyShield or HasToMaxLife )
	{
		
	}
	
	
	/*
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
		If (Item.IsJewel) {
			Break ; No jewel affixes here
		}

		CurrValue := GetActualValue(A_LoopField)

		; "Spell Damage +%" (simple prefix)
		; "Spell Damage +% (1H)" / "Base Maximum Mana" - Limited to sceptres, wands, and daggers.
		; "Spell Damage +% (Staff)" / "Base Maximum Mana"
		IfInString, A_LoopField, increased Spell Damage
		{
			If (Item.IsAmulet) {
				LookupAffixAndSetInfoLine("data\SpellDamage_Amulets.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			} Else If (Item.SubType == "Shield") {
				; Shield have the same pure spell damage affixes as 1 handers, but can't get the hybrid spell dmg/mana
				LookupAffixAndSetInfoLine("data\SpellDamage_1H.txt", "Prefix", ItemLevel, CurrValue)
				Continue
			}

			AffixType := "Prefix"
			If (HasMaxMana)
			{
				SDBracketItemLevel	:= 0
				MMBracketItemLevel	:= 0
				MaxManaValue 	:= ExtractValueFromAffixLine(ItemDataChunk, "maximum Mana")
				If (ItemSubType == "Staff")
				{
					SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_Staff.txt", ItemLevel, CurrValue, SDBracketItemLevel)
					If (Not IsValidBracket(SpellDamageBracket))
					{
						AffixType		:= "Comp. Prefix+Prefix"
						AffixTotals.NumPrefixes += 1

						; Need to find the bracket level by looking at max mana value instead
						MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, MaxManaValue, MMBracketItemLevel)
						If (Not IsValidBracket(MaxManaBracket))
						{
							; This actually means that both the "increased Spell Damage" line and
							; the "to maximum Mana" line are made up of Composite Prefix + Prefix.
							;
							; I haven't seen such an item yet, but you never know. In any case this
							; is completely ambiguous and can't be resolved. Mark line with EstInd
							; so user knows she needs to take a look at it.
							AffixType		:= "Comp. Prefix+Comp. Prefix"
							ValueRange	:= StrPad(EstInd, Opts.ValueRangeFieldWidth + StrLen(EstInd), "left")
						}
						Else
						{
							SpellDamageBracketFromComp	:= LookupAffixBracket("data\SpellDamage_MaxMana_Staff.txt", MMBracketItemLevel)
							SpellDamageBracket			:= LookupRemainingAffixBracket("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, SpellDamageBracketFromComp, SDBracketItemLevel)
							ValueRange				:= AddRange(SpellDamageBracket, SpellDamageBracketFromComp)
							ValueRange				:= MarkAsGuesstimate(ValueRange)
						}
					}
					Else
					{
						ValueRange := LookupAffixData("data\SpellDamage_MaxMana_Staff.txt", ItemLevel, CurrValue, BracketItemLevel, CurrTier)
						MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", BracketItemLevel)
						AffixType := "Comp. Prefix"
					}
				}
				Else
				{
					SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, SDBracketItemLevel)
					If (Not IsValidBracket(SpellDamageBracket))
					{
						AffixType := "Comp. Prefix+Prefix"
						AffixTotals.NumPrefixes += 1

						; Need to find the bracket level by looking at max mana value instead
						MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, MaxManaValue, MMBracketItemLevel)
						If (Not IsValidBracket(MaxManaBracket))
						{
							MaxManaBracket := LookupAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MMBracketItemLevel)
							If (IsValidBracket(MaxManaBracket))
							{
								AffixType	:= "Prefix"
								If (ItemSubType == "Staff")
								{
									ValueRange := LookupAffixData("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, SDBracketItemLevel, CurrTier)
								}
								Else
								{
									ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SDBracketItemLevel, CurrTier)
								}
								ValueRange := StrPad(ValueRange, Opts.ValueRangeFieldWidth, "left")
							}
							Else
							{
								; Must be 1H Spell Damage and Max Mana + 1H Spell Damage (+ Max Mana)
								SD1HBracketItemLevel := 0
								SpellDamage1HBracket := LookupAffixBracket("data\SpellDamage_1H.txt", ItemLevel, "", SD1HBracketItemLevel)
								If (IsValidBracket(SpellDamage1HBracket))
								{
									SpellDamageBracket := LookupRemainingAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, SpellDamage1HBracket, SDBracketItemLevel)
									If (IsValidBracket(SpellDamageBracket))
									{
										MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketItemLevel, "", MMBracketItemLevel)
										; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
										MaxManaBracketRem := LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
										If (Not IsValidBracket(MaxManaBracketRem))
										{
											; Nope, try again: check highest spell damage max mana first then spell damage
											SD1HBracketItemLevel	:= 0
											SpellDamageBracket	:= LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, "", SDBracketItemLevel)
											SpellDamage1HBracket:= LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracket, SD1HBracketItemLevel)
											MaxManaBracket		:= LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketItemLevel, "", MMBracketItemLevel)
											; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
											MaxManaBracketRem	:= LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
											ValueRange		:= AddRange(SpellDamageBracket, SpellDamage1HBracket)
											ValueRange		:= MarkAsGuesstimate(ValueRange)
										}
										Else
										{
											ValueRange := AddRange(SpellDamageBracket, SpellDamage1HBracket)
											ValueRange := MarkAsGuesstimate(ValueRange)
										}
									}
									Else
									{
										SD1HBracketItemLevel	:= 0
										SpellDamageBracket	:= LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, "", SDBracketItemLevel)
										SpellDamage1HBracket:= LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracket, SD1HBracketItemLevel)
										MaxManaBracket		:= LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketItemLevel, "", MMBracketItemLevel)
										; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
										MaxManaBracketRem	:= LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
										ValueRange		:= AddRange(SpellDamageBracket, SpellDamage1HBracket)
										ValueRange		:= MarkAsGuesstimate(ValueRange)
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
							SpellDamageBracketFromComp	:= LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", MMBracketItemLevel)
							SpellDamageBracket			:= LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracketFromComp, SDBracketItemLevel)
							ValueRange				:= AddRange(SpellDamageBracket, SpellDamageBracketFromComp)
							ValueRange				:= MarkAsGuesstimate(ValueRange)
						}
					}
					Else
					{
						ValueRange	:= LookupAffixData("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, BracketItemLevel, CurrTier)
						MaxManaBracket	:= LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", BracketItemLevel)
						AffixType		:= "Comp. Prefix"
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
				AffixTotals.NumPrefixes += 1
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
						AffixTotals.NumPrefixes += 1
						AffixType		:= "Comp. Prefix+Prefix"

						ValueRange	:= LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, CurrValue)
						MaxManaRest	:= CurrValue-RangeMid(MaxManaPartial)

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
							If (AffixTotals.NumPrefixes < 3)
							{
								AffixType	:= "Prefix"
								ValueRange:= LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
								ChangeAffixDetailLine("increased Spell Damage", "Comp. Prefix", "Prefix")
							}
						}
					}
					Else
					{
						; It's on a weapon, there is Spell Damage but no MaxManaPartial or NumPrefixes already is 3
						AffixType	:= "Comp. Prefix"
						ValueRange:= LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, CurrValue)
						If (Not IsValidBracket(ValueRange))
						{
							; incr. Spell Damage is actually a Prefix and not a Comp. Prefix,
							; so Max Mana must be a normal Prefix as well then
							AffixType	:= "Prefix"
							ValueRange:= LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
						}
						Else
						{
							ValueRange:= MarkAsGuesstimate(ValueRange)
						}
					}
					; Check if we still need to increment for the Spell Damage part
					If (AffixTotals.NumPrefixes < 3)
					{
						AffixTotals.NumPrefixes += 1
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
			AffixTotals.NumPrefixes += 1
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
			AffixType	:= "Prefix"
			IPDPath	:= "data\IncrPhysDamage.txt"
			If (HasToAccuracyRating)
			{
				ARIPDPath	:= "data\AccuracyRating_IncrPhysDamage.txt"
				IPDARPath	:= "data\IncrPhysDamage_AccuracyRating.txt"
				ARValue	:= ExtractValueFromAffixLine(ItemDataChunk, "to Accuracy Rating")
				ARPath	:= "data\AccuracyRating_Global.txt"
				If (ItemBaseType == "Weapon")
				{
					ARPath := "data\AccuracyRating_Local.txt"
				}

				; Look up IPD bracket, and use its bracket level to cross reference the corresponding
				; AR bracket. If both check out (are within bounds of their bracket level) case is
				; simple: Comp. Prefix (IPD / AR)
				IPDBracketItemLevel:= 0
				IPDBracket	:= LookupAffixBracket(IPDARPath, ItemLevel, CurrValue, IPDBracketItemLevel)
				ARBracket		:= LookupAffixBracket(ARIPDPath, IPDBracketItemLevel)

				If (HasIncrLightRadius)
				{
					LRValue	:= ExtractValueFromAffixLine(ItemDataChunk, "increased Light Radius")
					; First check if the AR value that comes with the Comp. Prefix AR / Light Radius
					; already covers the complete AR value. If so, from that follows that the Incr.
					; Phys Damage value can only be a Damage Scaling prefix.
					LRBracketItemLevel	:= 0
					LRBracket		:= LookupAffixBracket("data\LightRadius_AccuracyRating.txt", ItemLevel, LRValue, LRBracketItemLevel)
					ARLRBracket	:= LookupAffixBracket("data\AccuracyRating_LightRadius.txt", LRBracketItemLevel)
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
					IPDBracket	:= LookupAffixBracket(IPDPath, ItemLevel, CurrValue)
					ARBracket		:= LookupAffixBracket(ARPath, ItemLevel, ARValue)  ; Also lookup AR as if it were a simple Suffix
					ARIPDBracket	:= LookupAffixBracket(ARIPDPath, ItemLevel, ARValue, ARBracketItemLevel)

					If (IsValidBracket(IPDBracket) and IsValidBracket(ARBracket) and AffixTotals.NumPrefixes < 3)
					{
						HasIncrPhysDmg := 0
						Goto, SimpleIPDPrefix
					}
					ARBracketItemLevel	:= 0
					ARBracket		:= LookupAffixBracket(ARIPDPath, ItemLevel, ARValue, ARBracketItemLevel)
					If (IsValidBracket(ARBracket))
					{
						IPDARBracket	:= LookupAffixBracket(IPDARPath, ARBracketItemLevel)
						IPDBracket	:= LookupRemainingAffixBracket(IPDPath, ItemLevel, CurrValue, IPDARBracket)
						If (IsValidBracket(IPDBracket))
						{
							ValueRange		:= AddRange(IPDARBracket, IPDBracket)
							ValueRange		:= MarkAsGuesstimate(ValueRange)
							ARAffixTypePartial	:= "Comp. Prefix"
							Goto, CompIPDARPrefixPrefix
						}
					}
					If (Not IsValidBracket(IPDBracket) and IsValidBracket(ARBracket))
					{
						If (Not WithinBounds(ARBracket, ARValue))
						{
							ARRest := ARValue - RangeMid(ARBracket)
						}
						IPDBracket := LookupRemainingAffixBracket(IPDPath, ItemLevel, CurrValue, IPDARBracket, IPDBracketItemLevel)
						If (IsValidBracket(IPDBracket))
						{
							ValueRange		:= AddRange(IPDARBracket, IPDBracket)
							ValueRange		:= MarkAsGuesstimate(ValueRange)
							ARAffixTypePartial	:= "Comp. Prefix"
							Goto, CompIPDARPrefixPrefix
						}
						Else If (IsValidBracket(IPDARBracket) and AffixTotals.NumPrefixes < 3)
						{
							IPDBracket := LookupRemainingAffixBracket(IPDPath, ItemLevel, IPDRest, IPDARBracket)
							If (IsValidBracket(IPDBracket))
							{
								AffixTotals.NumPrefixes		+= 1
								ValueRange		:= AddRange(IPDARBracket, IPDBracket)
								ValueRange		:= MarkAsGuesstimate(ValueRange)
								ARAffixTypePartial	:= "Comp. Prefix"
								Goto, CompIPDARPrefixPrefix
							}

						}
					}
					If ((Not IsValidBracket(IPDBracket)) and (Not IsValidBracket(ARBracket)))
					{
						IPDBracket	:= LookupAffixBracket(IPDPath, ItemLevel, "")
						IPDARBracket	:= LookupRemainingAffixBracket(IPDARPath, ItemLevel, CurrValue, IPDBracket, ARBracketItemLevel)
						ARBracket		:= LookupAffixBracket(ARIPDPath, ARBracketItemLevel, "")
						ValueRange	:= AddRange(IPDARBracket, IPDBracket)
						ValueRange	:= MarkAsGuesstimate(ValueRange)
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
					ARValue	:= ExtractValueFromAffixLine(ItemDataChunk, "to Accuracy Rating")
					ARBracket	:= LookupAffixBracket(ARPath, ItemLevel, ARValue)

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
			AffixTotals.NumPrefixes += 1
			ValueRange	:= LookupAffixData("data\IncrPhysDamage.txt", ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			Continue
		CompIPDARPrefix:
			AffixType		:= "Comp. Prefix"
			ValueRange	:= LookupAffixData(IPDARPath, ItemLevel, CurrValue, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			ARPartial		:= ARBracket
			Continue
		CompIPDARPrefixPrefix:
			AffixTotals.NumPrefixes += 1
			AffixType		:= "Comp. Prefix+Prefix"
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			ARPartial		:= ARBracket
			Continue
		}

		IfInString, A_LoopField, increased Stun and Block Recovery
		{
			AffixType := "Prefix"
			If (HasHybridDefences)
			{
				AffixType			:= "Comp. Prefix"
				BSRecAffixPath		:= "data\StunRecovery_Hybrid.txt"
				BSRecAffixBracket	:= LookupAffixBracket(BSRecAffixPath, ItemLevel, CurrValue)
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
							If (AffixTotals.NumSuffixes < 3)
							{
								AffixType			:= "Comp. Prefix+Suffix"
								BSRecAffixBracket	:= LookupRemainingAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, BSRecPartial)
								If (Not IsValidBracket(BSRecAffixBracket))
								{
									AffixType			:= "Comp. Prefix+Prefix"
									BSRecAffixBracket	:= LookupAffixBracket("data\StunRecovery_Prefix.txt", ItemLevel, CurrValue)
									If (Not IsValidBracket(BSRecAffixBracket))
									{
										If (CompStatAffixType == "Comp. Prefix+Prefix" and AffixTotals.NumSuffixes < 3)
										{
											AffixType			:= "Comp. Prefix+Suffix"
											BSRecSuffixBracket	:= LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRest)
											AffixTotals.NumSuffixes		+= 1
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
												BSRecSuffixBracket	:= LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue)
												ValueRange 		:= LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue)
												ValueRange		:= MarkAsGuesstimate(ValueRange)
											}
											Else
											{
												ValueRange := AddRange(BSRecSuffixBracket, BSRecPartial)
												ValueRange := MarkAsGuesstimate(ValueRange)
											}
										}
										Else
										{
											AffixType		:= "Suffix"
											ValueRange	:= LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
											If (AffixTotals.NumSuffixes < 3)
											{
												AffixTotals.NumSuffixes += 1
											}
											ChangeAffixDetailLine(PartialAffixString, "Comp. Prefix" , "Prefix")
										}
									}
									Else
									{
										If (AffixTotals.NumPrefixes < 3)
										{
											AffixTotals.NumPrefixes += 1
										}
									}
								}
								Else
								{
									AffixTotals.NumSuffixes += 1
									ValueRange := AddRange(BSRecPartial, BSRecAffixBracket)
									ValueRange := MarkAsGuesstimate(ValueRange)
								}
							}
						}
					}
					Else
					{
						; Simple Stun Rec suffix
						AffixType		:= "Suffix"
						ValueRange	:= LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
						AffixTotals.NumSuffixes += 1
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
					PartialAffixString	:= "increased Armour"
					BSRecAffixPath		:= "data\StunRecovery_Armour.txt"
				}
				If (HasIncrEvasion)
				{
					PartialAffixString	:= "increased Evasion Rating"
					BSRecAffixPath		:= "data\StunRecovery_Evasion.txt"
				}
				If (HasIncrEnergyShield)
				{
					PartialAffixString	:= "increased Energy Shield"
					BSRecAffixPath		:= "data\StunRecovery_EnergyShield.txt"
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
							If (AffixTotals.NumSuffixes < 3)
							{
								AffixType			:= "Comp. Prefix+Suffix"
								BSRecAffixBracket	:= LookupRemainingAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, BSRecPartial)
								If (Not IsValidBracket(BSRecAffixBracket))
								{
									AffixType			:= "Comp. Prefix+Prefix"
									BSRecAffixBracket	:= LookupAffixBracket("data\StunRecovery_Prefix.txt", ItemLevel, CurrValue)
									If (Not IsValidBracket(BSRecAffixBracket))
									{
										AffixType		:= "Suffix"
										ValueRange	:= LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
										If (AffixTotals.NumSuffixes < 3)
										{
											AffixTotals.NumSuffixes += 1
										}
										ChangeAffixDetailLine(PartialAffixString, "Comp. Prefix" , "Prefix")
									}
									Else
									{
										If (AffixTotals.NumPrefixes < 3)
										{
											AffixTotals.NumPrefixes += 1
										}
									}

								}
								Else
								{
									AffixTotals.NumSuffixes += 1
									ValueRange	:= AddRange(BSRecPartial, BSRecAffixBracket)
									ValueRange	:= MarkAsGuesstimate(ValueRange)
								}
							}
						}
					}
					Else
					{
						BSRecSuffixPath	:= "data\StunRecovery_Suffix.txt"
						BSRecSuffixBracket	:= LookupAffixBracket(BSRecSuffixPath, ItemLevel, CurrValue)
						If (IsValidBracket(BSRecSuffixBracket))
						{
							AffixType		:= "Suffix"
							ValueRange	:= LookupAffixData(BSRecSuffixPath, ItemLevel, CurrValue, "", CurrTier)
							If (AffixTotals.NumSuffixes < 3)
							{
								AffixTotals.NumSuffixes += 1
							}
						}
						Else
						{
							BSRecPrefixPath	:= "data\StunRecovery_Prefix.txt"
							BSRecPrefixBracket	:= LookupAffixBracket(BSRecPrefixPath, ItemLevel, CurrValue)
							ValueRange		:= LookupAffixData(BSRecPrefixPath, ItemLevel, CurrValue, "", CurrTier)
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

			ValueRangeAR	:= "0-0"
			AffixType		:= ""
			IPDAffixType	:= GetAffixTypeFromProcessedLine("increased Physical Damage")
			If (HasIncrLightRadius and Not HasIncrAccuracyRating)
			{
				; "of Shining" and "of Light"
				LightRadiusValue	:= ExtractValueFromAffixLine(ItemDataChunk, "increased Light Radius")

				; Get bracket level of the light radius so we can look up the corresponding AR bracket
				BracketItemLevel	:= 0
				LookupAffixBracket("data\LightRadius_AccuracyRating.txt", ItemLevel, LightRadiusValue, BracketItemLevel)
				ARLRBracket	:= LookupAffixBracket("data\AccuracyRating_LightRadius.txt", BracketItemLevel)

				AffixType		:= AffixType . "Comp. Suffix"
				ValueRange	:= LookupAffixData("data\AccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
				AffixTotals.NumSuffixes += 1

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
								If (AffixTotals.NumPrefixes < 3)
								{
									AffixTotals.NumPrefixes += 1
								}
								ValueRange := CombinedRange
								ValueRange := MarkAsGuesstimate(ValueRange)
								Goto, FinalizeAR
							}
							Else
							{
								AffixTotals.NumSuffixes -= 1
							}
						}

						If (InStr(IPDAffixType, "Comp. Prefix"))
						{
;                            AffixType := "Comp. Prefix+Comp. Suffix+Suffix"
							If (AffixTotals.NumPrefixes < 3)
							{
								AffixTotals.NumPrefixes += 1
							}
						}
					}
					ARBracket		:= LookupRemainingAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, CurrValue, ARLRBracket)
					ValueRange	:= AddRange(ARBracket, ARLRBracket)
					ValueRange	:= MarkAsGuesstimate(ValueRange)
					AffixTotals.NumSuffixes += 1
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
						If (AffixTotals.NumPrefixes < 3)
						{
							AffixTotals.NumPrefixes += 1
						}
						ValueRange := LookupAffixData("data\AccuracyRating_IncrPhysDamage.txt", ItemLevel, RangeMid(ARPartial), "", CurrTier)
						Goto, FinalizeAR
					}

					ARPartialMid	:= RangeMid(ARPartial)
					ARRest		:= CurrValue - ARPartialMid
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
						If (AffixTotals.NumSuffixes < 3)
						{
							AffixTotals.NumSuffixes += 1
						}
						Else
						{
							AffixType := "Comp. Prefix"
							If (AffixTotals.NumPrefixes < 3)
							{
								AffixTotals.NumPrefixes += 2
							}
						}
						AffixTotals.NumPrefixes += 1
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
					If (AffixTotals.NumPrefixes >= 3)
					{
						AffixType := "Suffix"
						If (AffixTotals.NumSuffixes < 3)
						{
							AffixTotals.NumSuffixes += 1
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
						AffixTotals.NumPrefixes += 1
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
					AffixTotals.NumPrefixes += 1
					AffixTotals.NumSuffixes += 1
					;~ ValueRange := LookupAffixData("data\AccuracyRating_IncrPhysDamage.txt", ItemLevel, CurrValue, "", CurrTier)
					ValueRange := AddRange(ARPartial, ValueRangeAR)
					ValueRange := MarkAsGuesstimate(ValueRange)
				}
				; NumPrefixes should be incremented already by "increased Physical Damage" case
				Goto, FinalizeAR
			}
			AffixType		:= "Suffix"
			ValueRange	:= LookupAffixData("data\AccuracyRating_Global.txt", ItemLevel, CurrValue, "", CurrTier)
			AffixTotals.NumSuffixes += 1
			Goto, FinalizeAR

		FinalizeAR:
			If (StrLen(ARAffixTypePartial) > 0 and (Not InStr(AffixType, ARAffixTypePartial)))
			{
				AffixType := ARAffixTypePartial . "+" . AffixType
				If (InStr(ARAffixTypePartial, "Prefix") and AffixTotals.NumPrefixes < 3)
				{
					AffixTotals.NumPrefixes += 1
				}
				Else If (InStr(ARAffixTypePartial, "Suffix") and AffixTotals.NumSuffixes < 3)
				{
					AffixTotals.NumSuffixes += 1
				}
				ARAffixTypePartial =
			}
			AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
			Continue
		}

		IfInString, A_LoopField, increased Rarity
		{
			ActualValue := CurrValue
			If (AffixTotals.NumSuffixes <= 3)
			{
				ValueRange	:= LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, ActualValue)
				ValueRangeAlt	:= LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, ActualValue)
			}
			Else
			{
				ValueRange	:= LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, ActualValue)
				ValueRangeAlt	:= LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, ActualValue)
			}
			If (Not IsValidBracket(ValueRange))
			{
				If (Not IsValidBracket(ValueRangeAlt))
				{
					AffixTotals.NumPrefixes += 1
					AffixTotals.NumSuffixes += 1
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
				If (AffixTotals.NumSuffixes >= 3) {
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
				AffixTotals.NumPrefixes += 1
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
				Continue

			FinalizeIIRAsSuffix:
				AffixTotals.NumSuffixes += 1
				ValueRange	:= LookupAffixData("data\IIR_Suffix.txt", ItemLevel, ActualValue, "", CurrTier)
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
				Continue

			FinalizeIIRAsPrefixAndSuffix:
				ValueRange	:= MarkAsGuesstimate(ValueRange)
				AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix+Suffix", ValueRange, CurrTier), A_Index)
				Continue
		}
	}
	
	*/

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
			If (Item.Rarity == 2 or AffixTotals.NumSuffixes == 1) {
				; On jewels with another suffix already or jewels that can only have 1 suffix (magic items) that single suffix must be the combined one
				AffixTotals.NumSuffixes += 1
				ValueRange	:= LookupAffixData("data\jewel\CritChanceGlobal_Jewels_Acc.txt", ItemLevel, CAGlobalCritChance, "", CurrTier)
				AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, "Comp. Suffix", ValueRange, CurrTier), CAGlobalCritChanceAffixLineNo)
				NextAffixPos	+= 1
				ValueRange	:= LookupAffixData("data\jewel\IncrAccuracyRating_Jewels_Crit.txt", ItemLevel, CAIncAccuracy, "", CurrTier)
				AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, "Comp. Suffix", ValueRange, CurrTier), CAIncAccuracyAffixLineNo)
			} Else {
				; Item has both increased accuracy and global crit chance and can have 2 suffixes: complex affix possible

				has_combined_acc_crit := 0

				If (CAIncAccuracy >= 6 and CAIncAccuracy <= 9) {
					; Accuracy is the result of the combined accuracy/crit_chance affix
					has_combined_acc_crit := 1
					AffixTotals.NumSuffixes += 1
					ValueRange	:= "   6-10    6-10"
					AffixType		:= "Comp. Suffix"
				} Else If (CAIncAccuracy = 10) {
					; IncAccuracy can be either the combined affix or pure accuracy
					If ((CAGlobalCritChance >= 6 and CAGlobalCritChance <= 7) or (CAGlobalCritChance >= 14)) {
						; Because the global crit chance is only possible with the combined affix the accuracy has to be the result of that
						has_combined_acc_crit := 1
						ValueRange	:= "   6-10    6-10"
						AffixType		:= "Comp. Suffix"
					} Else If (CAGlobalCritChance >= 11 and CAGlobalCritChance <= 12) {
						; Global crit chance can only be the pure affix, this means accuracy can't be the combined affix
						ValueRange	:= "  10-14   10-14"
						AffixType		:= "Suffix"
					} Else {
						ValueRange	:= "   6-14    6-14"
						AffixType		:= "Comp. Suffix"
						; TODO: fix handling unknown number of affixes
					}
					AffixTotals.NumSuffixes += 1
				} Else If (CAIncAccuracy >= 11 and CAIncAccuracy <= 14) {
					; Increased accuracy can only be the pure accuracy roll
					AffixTotals.NumSuffixes += 1
					ValueRange	:= "  10-14   10-14"
					AffixType		:= "Suffix"
				} Else If (CAIncAccuracy >= 16) {
					; Increased accuracy can only be a combination of the complex and pure affixes
					has_combined_acc_crit := 1
					AffixTotals.NumSuffixes	+= 2
					ValueRange	:= "  16-24   16-24"
					AffixType		:= "Comp. Suffix"
				}

				AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, AffixType, ValueRange, 1), CAIncAccuracyAffixLineNo)
				NextAffixPos += 1

				If (CAGlobalCritChance >= 6 and CAGlobalCritChance <= 7) {
					; Crit chance is the result of the combined accuracy/crit_chance affix
					; don't update suffix count, should this should have already been done during Inc Accuracy detection
					; AffixTotals.NumSuffixes += 1
					ValueRange	:= "   6-10    6-10"
					AffixType		:= "Comp. Suffix"
				} Else If (CAGlobalCritChance >= 8 and CAGlobalCritChance <= 10) {
					; Crit chance can be either the combined affix or pure crit chance
					If ((CAIncAccuracy >= 6 and CAIncAccuracy <= 9) or (CAIncAccuracy >= 16)) {
						; Because the inc accuracy is only possible with the combined affix the global crit chance also has to be the result of that
						; don't update suffix count, should this should have already been done during Inc Accuracy detection
						; AffixTotals.NumSuffixes += 1
						ValueRange	:= "   6-10    6-10"
						AffixType		:= "Comp. Suffix"
					} Else If (CAIncAccuracy >= 11 and CAIncAccuracy <= 14) {
						; Inc Accuracy can only be the pure affix, this means global crit chance can't be the combined affix
						AffixTotals.NumSuffixes += 1
						ValueRange	:= "   8-12    8-12"
						AffixType		:= "Suffix"
					} Else {
						; TODO: fix handling unknown number of affixes
						ValueRange	:= "   6-12    6-12"
						AffixType		:= "Comp. Suffix"
					}
					AffixTotals.NumSuffixes += 1
				} Else If (CAGlobalCritChance >= 11 and CAGlobalCritChance <= 12) {
					; Crit chance can only be the pure crit chance roll
					AffixTotals.NumSuffixes += 1
					ValueRange	:= "   8-12    8-12"
					AffixType		:= "Suffix"
				} Else If (CAGlobalCritChance >= 14) {
					; Crit chance can only be a combination of the complex and pure affixes
					AffixTotals.NumSuffixes += 1
					ValueRange	:= "  14-22   14-22"
					AffixType		:= "Comp. Suffix"
				}

				AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, AffixType, ValueRange, 1), CAGlobalCritChanceAffixLineNo)
				NextAffixPos += 1
			}
		} Else If (CAGlobalCritChance) {
			; The item only has a global crit chance affix so it isn't complex
			AffixTotals.NumSuffixes += 1
			ValueRange	:= LookupAffixData("data\jewel\CritChanceGlobal_Jewels.txt", ItemLevel, CAGlobalCritChance, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, "Suffix", ValueRange, CurrTier), CAGlobalCritChanceAffixLineNo)
			NextAffixPos	+= 1
		} Else {
			; The item only has an increased accuracy affix so it isn't complex
			AffixTotals.NumSuffixes += 1
			ValueRange	:= LookupAffixData("data\jewel\IncrAccuracyRating_Jewels.txt", ItemLevel, CAIncAccuracy, "", CurrTier)
			AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, "Suffix", ValueRange, CurrTier), CAIncAccuracyAffixLineNo)
			NextAffixPos	+= 1
		}
	}

	Return 
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
		ParseProphecy(ItemData, Difficulty)
		Item.DifficultyRestriction := Difficulty
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

	NumPrefixes		:= NumFormatPointFiveOrInt(AffixTotals.NumPrefixes)
	NumSuffixes		:= NumFormatPointFiveOrInt(AffixTotals.NumSuffixes)
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
	
	If (Item.IsProphecy)
	{
		Restriction := StrLen(Item.DifficultyRestriction) > 0 ? Item.DifficultyRestriction : "None"
		TT := TT . "`n--------`nDifficulty Restriction: " Restriction 
	}

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

CheckIfTempModExists(needle, mods) {
	For key, val in mods {
		If (RegExMatch(val.name, "i)" needle "")) {
			Return true
		}
	}
	Return false
}

; Don't use! Not working correctly yet!
ExtractRareItemTypeName(ItemName)
{
	ItemTypeName := RegExReplace(ItemName, "(.+?) (.+) of (.+)", "$2")
	return ItemTypeName
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
	IfWinActive, ahk_group PoEWindowGrp
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
					If (StrLen(Item.DifficultyRestriction)) {
						terms.push(Item.DifficultyRestriction)
					}					
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
	IfWinActive, ahk_group PoEWindowGrp
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
	IfWinActive, ahk_group PoEWindowGrp
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
			IfWinActive, ahk_group PoEWindowGrp
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
		url  := "http://poeninja.azureedge.net/api/Data/GetCurrencyOverview?league=" . currencyLeague
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

