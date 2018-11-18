; TradeMacro Add-on to POE-ItemInfo
; IGN: Eruyome, ManicCompression
#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background

SetWorkingDir, %A_ScriptDir%
;https://autohotkey.com/boards/viewtopic.php?f=6&t=53
#Include, %A_ScriptDir%\lib\JSON.ahk
; Console https://autohotkey.com/boards/viewtopic.php?f=6&t=2116
#Include, %A_ScriptDir%\lib\Class_Console.ahk
#Include, %A_ScriptDir%\lib\DebugPrintArray.ahk
#Include, %A_ScriptDir%\lib\AssociatedProgram.ahk
#Include, %A_ScriptDir%\lib\EasyIni.ahk
#Include, %A_ScriptDir%\lib\ConvertKeyToKeyCode.ahk
#Include, %A_ScriptDir%\resources\ahk\jsonData.ahk
#Include, %A_ScriptDir%\resources\VersionTrade.txt

TradeMsgWrongAHKVersion := "AutoHotkey v" . TradeAHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < TradeAHKVersionRequired)
{
	MsgBox, 16, Wrong AutoHotkey Version, % TradeMsgWrongAHKVersion
	ExitApp
}

Menu, Tray, Icon, %A_ScriptDir%\resources\images\poe-trade-bl.ico
Menu, Tray, Add, Donate, OpenPayPal
Menu, Tray, Add, Open Wiki/FAQ, OpenGithubWikiFromMenu

argumentSkipSplash = %6%
If (not argumentSkipSplash) {
	TradeFunc_StartSplashScreen()
}

class TradeGlobals {
	Set(name, value) {
		TradeGlobals[name] := value
	}

	Get(name, value_default="") {
		result := TradeGlobals[name]
		If (result == "") {
			result := value_default
		}
		Return result
	}
}

global SettingsWindowWidth := 845
global SavedTradeSettings := false

; TODO: enable this after refactoring of ReadTradeConfig()/WriteTradeConfig()
; if (FileExist(userDirectory "\config_trade.ini")) {
; 	TradeOpts_New := class_EasyIni(userDirectory "\config_trade.ini")
; 	TradeOpts_New.Update(A_ScriptDir "\resources\default_UserFiles\config_trade.ini")
; }
; else {
; 	TradeOpts_New := class_EasyIni(A_ScriptDir "\resources\default_UserFiles\config_trade.ini")
; }

TradeOpts_New := class_EasyIni(A_ScriptDir "\resources\default_UserFiles\config_trade.ini")
MakeOldTradeOptsAndVars(TradeOpts_New)


; Check if Temp-Leagues are active and set defaultLeague accordingly
TradeGlobals.Set("TempLeagueIsRunning", TradeFunc_CheckIfTempLeagueIsRunning())
TradeGlobals.Set("EventLeagueIsRunning", TradeFunc_CheckIfTempLeagueIsRunning("event"))
TradeGlobals.Set("DefaultLeague", (TradeFunc_CheckIfTempLeagueIsRunning() > 0) ? "tmpstandard" : "standard")
TradeGlobals.Set("GithubUser", "POE-TradeMacro")
TradeGlobals.Set("GithubRepo", "POE-TradeMacro")
TradeGlobals.Set("ReleaseVersion", TradeReleaseVersion)
global globalUpdateInfo := {}
globalUpdateInfo.repo := TradeGlobals.Get("GithubRepo")
globalUpdateInfo.user := TradeGlobals.Get("GithubUser")
globalUpdateInfo.releaseVersion 	:= TradeGlobals.Get("ReleaseVersion")
globalUpdateInfo.skipSelection 	:= 0
globalUpdateInfo.skipBackup 		:= 0
globalUpdateInfo.skipUpdateCheck 	:= 0

TradeGlobals.Set("SettingsScriptList", ["TradeMacro", "ItemInfo", "Additional Macros"])
TradeGlobals.Set("SettingsUITitle", "PoE (Trade) Item Info Settings")
argumentProjectName		= %1%
argumentUserDirectory	= %2%
argumentIsDevVersion	= %3%
argumentOverwrittenFiles = %4%

; when using the fallback exe we're missing the parameters passed by the merge script
If (!StrLen(argumentProjectName) > 0) {
	fallbackExeMsg := "You're using a compiled version (.exe) of the script which is only intended to be used if the normal version (.ahk script) doesn't work for you."
	fallbackExeMsg .= "`n`nThis version can possibly cause issues that you wouldn't have with the normal script though."
	fallbackExeMsg .= "`n`nUse ""Run_TradeMacro.ahk"" if possible and try it before reporting any issues!"
	fallbackExeMsg .= "`n`n(closes after 10s)..."
	SplashTextOff
	MsgBox, 0x1030, PoE-TradeMacro Fallback, % fallbackExeMsg, 10
	
	argumentProjectName		:= "PoE-TradeMacro"
	FilesToCopyToUserFolder	:= A_ScriptDir . "\resources\default_UserFiles"
	argumentOverwrittenFiles	:= PoEScripts_HandleUserSettings(argumentProjectName, A_MyDocuments, argumentProjectName, FilesToCopyToUserFolder, A_ScriptDir)
	argumentIsDevVersion	:= PoEScripts_isDevelopmentVersion(A_ScriptDir)
	argumentUserDirectory	:= A_MyDocuments . "\" . argumentProjectName . argumentIsDevVersion
	
	If (!PoEScripts_CreateTempFolder(A_ScriptDir, "PoE-TradeMacro")) {
		ExitApp
	}
	PoEScripts_CompareUserFolderWithScriptFolder(argumentUserDirectory, A_ScriptDir, argumentProjectName)
}

TradeGlobals.Set("ProjectName", argumentProjectName)
global userDirectory		:= argumentUserDirectory
global isDevVersion			:= argumentIsDevVersion
global overwrittenUserFiles	:= argumentOverwrittenFiles

; ; Create config file if neccessary and read it
; IfNotExist, %userDirectory%\config_trade.ini
; {
; 	IfNotExist, %A_ScriptDir%\resources\default_UserFiles\config_trade.ini
; 	{
; 		CreateDefaultTradeConfig()
; 	}
; 	CopyDefaultTradeConfig()
; }

TradeFunc_CheckIfCloudFlareBypassNeeded()

TradeGlobals.Set("Leagues", TradeFunc_GetLeagues())
Sleep, 200
ReadTradeConfig("", "config_trade.ini", _updateConfigWrite)
TradeGlobals.Set("LeagueName", TradeGlobals.Get("Leagues")[SearchLeague])

; set this variable to skip the update check in "PoE-ItemInfo.ahk"
SkipItemInfoUpdateCall := 1
firstUpdateCheck := true
TradeFunc_ScriptUpdate()

firstUpdateCheck := false

If (TradeOpts.AlternativeCurrencySearch) {
	GoSub, ReadPoeNinjaCurrencyData
}
TradeGlobals.Set("VariableUniqueData", TradeUniqueData)
TradeGlobals.Set("VariableRelicData",  TradeRelicData)
TradeGlobals.Set("ModsData", TradeModsData)
TradeGlobals.Set("CurrencyTags", TradeCurrencyTags)

TradeGlobals.Set("CraftingData", TradeFunc_ReadCraftingBases())
TradeGlobals.Set("EnchantmentData", TradeFunc_ReadEnchantments())
TradeGlobals.Set("CorruptedModsData", TradeFunc_ReadCorruptions())
TradeGlobals.Set("CurrencyIDs", object := {})
TradeGlobals.Set("FirstSearchTriggered", false)

; get currency ids from currency.poe.trade
TradeFunc_DoCurrencyRequest("", false, true)
If (TradeOpts.DownloadDataFiles and not TradeOpts.Debug) {
	TradeFunc_DownloadDataFiles()
}

CreateTradeSettingsUI()
If (_updateConfigWrite) {
	; some value needs to be written to config because it was invalid and was therefore changed
	WriteTradeConfig()
}
TradeFunc_StopSplashScreen()

; ----------------------------------------------------------- Functions ----------------------------------------------------------------

; TODO: rewrite/remove after refactoring UI
ReadTradeConfig(TradeConfigDir = "", TradeConfigFile = "config_trade.ini", ByRef updateWriteConfig = false)
{
	Global

	If (StrLen(TradeConfigDir) < 1) {
		TradeConfigDir := userDirectory
	}
	TradeConfigPath := StrLen(TradeConfigDir) > 0 ? TradeConfigDir . "\" . TradeConfigFile : TradeConfigFile
	If (FileExist(TradeConfigPath)) {
		TradeOpts_New := class_EasyIni(TradeConfigPath)
		TradeOpts_New.Update(A_ScriptDir "\resources\default_UserFiles\config_trade.ini")
		_temp_SearchLeague := TradeOpts_New.Search.SearchLeague
	}
	If (!TradeFunc_CheckBrowserPath(TradeOpts_New.General.BrowserPath, false)) {
		TradeOpts_New.General.BrowserPath := ""
	}
	If (!TradeFunc_CheckLeague(TradeOpts_New.Search.SearchLeague)) {
		TradeOpts_New.Search.SearchLeague := TradeGlobals.Get("DefaultLeague")
	}
	Else {
		TradeOpts_New.Search.SearchLeague := TradeFunc_CheckIfLeagueIsActive(Format("{:L}", TradeOpts_New.Search.SearchLeague))
	}

	TradeOpts_New.Search.Corrupted := Format("{:T}", TradeOpts_New.Search.Corrupted)

	MakeOldTradeOptsAndVars(TradeOpts_New)
	TradeFunc_SyncUpdateSettings()
	TradeFunc_AssignAllHotkeys()
	If (_temp_SearchLeague != TradeOpts_New.Search.SearchLeague) {
		updateWriteConfig := true
	}
	
	Return
}

TradeFunc_AssignAllHotkeys()
{
	Global
	For keyName, keyVal in TradeOpts_New.Hotkeys {
		If (TradeOpts_New.HotkeyStates[keyName]) {
			TradeFunc_AssignHotkey(keyVal, keyName)
		}
		Else {
			Hotkey, %keyVal%, off, UseErrorLevel
		}
	}
	Return
}

; TODO: rewrite/remove after refactoring UI
WriteTradeConfig(TradeConfigDir = "", TradeConfigFile = "config_trade.ini") {
	Global
	If (StrLen(TradeConfigDir) < 1) {
		TradeConfigDir := userDirectory
	}
	TradeConfigPath := StrLen(TradeConfigDir) > 0 ? TradeConfigDir . "\" . TradeConfigFile : TradeConfigFile


	If (!TradeFunc_CheckBrowserPath(BrowserPath, true)) {
		BrowserPath := ""
	}
	oldLeague := TradeOpts.SearchLeague
	oldAltCurrencySearch := TradeOpts.AlternativeCurrencySearch

	UpdateOldTradeOptsFromVars()

	TradeOpts.SearchLeague := TradeFunc_CheckIfLeagueIsActive(TradeOpts.SearchLeague)
	oldLeagueName := TradeGlobals.Get("LeagueName")
	newLeagueName := TradeGlobals.Get("Leagues")[TradeOpts.SearchLeague]
	TradeGlobals.Set("LeagueName", TradeGlobals.Get("Leagues")[TradeOpts.SearchLeague])
	If (oldLeagueName != newLeagueName) {
		TempChangingLeagueInProgress := True
		GoSub, ReadPoeNinjaCurrencyData
	}

	; Get currency data only if league was changed while alternate search is active or alternate search was changed from disabled to enabled
	If ((TradeOpts.SearchLeague != oldLeague and AlternativeCurrencySearch) or (AlternativeCurrencySearch and oldAltCurrencySearch != AlternativeCurrencySearch)) {
		GoSub, ReadPoeNinjaCurrencyData
	}
	TradeOpts_New := UpdateNewTradeOptsFromOld(TradeOpts_New)
	TradeFunc_SyncUpdateSettings()
	TradeFunc_AssignAllHotkeys()
	TradeOpts_New.Save(TradeConfigPath)
	
	Return
}

; NB: this is temporary hack
MakeOldTradeOptsAndVars(ConfigObject)
{
	Global
	TradeOpts := {}
	for sectionName, sectionKeys in ConfigObject {
		for keyName, keyVal in sectionKeys {
			if (sectionName == "Hotkeys") {
				keyName := keyName "HotKey"
				keyVal := KeyNameToKeyCode(keyVal, ConfigObject.General.KeyToSCState)
			}
			if (sectionName == "HotkeyStates") {
				keyName := keyName "Enabled"
			}
			%keyName% := keyVal
			TradeOpts.Insert(keyName, keyVal)
		}
	}
	return
}

; NB: this is temporary hack
UpdateNewTradeOptsFromOld(ConfigObject)
{
	Global
	for sectionName, sectionKeys in ConfigObject {
		for keyName, keyVal in sectionKeys {
			keyNameTemp := keyName
			if (sectionName == "Hotkeys") {
				keyNameTemp := keyName "HotKey"
				keyValTemp := KeyNameToKeyCode(TradeOpts[keyNameTemp], TradeOpts.KeyToSCState)
			}
			else if (sectionName == "HotkeyStates") {
				keyNameTemp := keyName "Enabled"
				keyValTemp := TradeOpts[keyNameTemp]
			}
			else {
				keyValTemp := TradeOpts[keyNameTemp]
			}
			ConfigObject[sectionName, keyName] := keyValTemp
		}
	}
	return ConfigObject
}

; NB: this is temporary hack
UpdateOldTradeOptsFromVars()
{
	Global
	for key, val in TradeOpts {
		TradeOpts[key] := %key%
	}
	return
}

TradeFunc_CheckLeague(LeagueName)
{
	LeagueName := Format("{:L}", LeagueName)	
	For key, val in TradeGlobals.Get("Leagues") {
		temp_LeagueName := Format("{:L}",  RegExReplace(val, "i)\s", ""))
		If (LeagueName == temp_LeagueName) {
			Return true
		}
	}
	
	If (RegExMatch(LeagueName, "i)Standard|Hardcore|TmpStandard|TmpHardcore")) {
		Return true
	}
	Return false
}

CopyDefaultTradeConfig() {
	FileCopy, %A_ScriptDir%\resources\default_UserFiles\config_trade.ini, %userDirectory%, 1
	;FileMove, %userDirectory%\default_config_trade.ini, %userDirectory%\config_trade.ini
	;FileDelete, %userDirectory%\default_config_trade.ini
}

RemoveTradeConfig() {
	FileDelete, %userDirectory%\config_trade.ini
}

CreateDefaultTradeConfig() {
	path := A_ScriptDir "\resources\default_UserFiles\config_trade.ini"
	WriteTradeConfig(path)
}

TradeFunc_CheckIfLeagueIsActive(LeagueName) {
	; Check if league from Ini is set to an inactive league and change it to the corresponding active one, for example tmpstandard to standard
	; Leagues not supported with any API (beta leagues) and events (some races and SSF events) are being removed while reading the config when they are not supported by poe.trade anymore
	If (RegExMatch(LeagueName, "i)tmp(standard)|tmp(hardcore)", match) and not TradeGlobals.Get("TempLeagueIsRunning")) {
		LeagueName := match1 ? "standard" : "hardcore"
	} 
	If (RegExMatch(LeagueName, "i)(hc|hardcore).*event|(event)", match) and not RegExMatch(LeagueName, "i)ssf") and not TradeGlobals.Get("EventLeagueIsRunning")) {
		LeagueName := match1 ? "hardcore" : "standard"
	}
	
	return LeagueName
}

; ------------------ ASSIGN HOTKEY AND HANDLE ERRORS ------------------
TradeFunc_AssignHotkey(Key, Label) {
	Key := KeyNameToKeyCode(Key, TradeOpts.KeyToSCState)
	Hotkey, %Key%, %Label%, UseErrorLevel
	If (ErrorLevel)	{
		If (errorlevel = 1)
			str := str . "`nASCII " . Key . " - 1) The Label parameter specifies a nonexistent label name."
		Else If (errorlevel = 2)
			str := str . "`nASCII " . Key . " - 2) The KeyName parameter specifies one or more keys that are either not recognized or not supported by the current keyboard layout/language. Switching to the english layout should solve this for now."
		Else If (errorlevel = 3)
			str := str . "`nASCII " . Key . " - 3) Unsupported prefix key. For example, using the mouse wheel as a prefix in a hotkey such as WheelDown & Enter is not supported."
		Else If (errorlevel = 4)
			str := str . "`nASCII " . Key . " - 4) The KeyName parameter is not suitable for use with the AltTab or ShiftAltTab actions. A combination of two keys is required. For example: RControl & RShift::AltTab."
		Else If (errorlevel = 5)
			str := str . "`nASCII " . Key . " - 5) The command attempted to modify a nonexistent hotkey."
		Else If (errorlevel = 6)
			str := str . "`nASCII " . Key . " - 6) The command attempted to modify a nonexistent variant of an existing hotkey. To solve this, use Hotkey IfWin to set the criteria to match those of the hotkey to be modified."
		Else If (errorlevel = 50)
			str := str . "`nASCII " . Key . " - 50) Windows 95/98/Me: The command completed successfully but the operating system refused to activate the hotkey. This is usually caused by the hotkey being "" ASCII " . int . " - in use"" by some other script or application (or the OS itself). This occurs only on Windows 95/98/Me because on other operating systems, the program will resort to the keyboard hook to override the refusal."
		Else If (errorlevel = 51)
			str := str . "`nASCII " . Key . " - 51) Windows 95/98/Me: The command completed successfully but the hotkey is not supported on Windows 95/98/Me. For example, mouse hotkeys and prefix hotkeys such as a & b are not supported."
		Else If (errorlevel = 98)
			str := str . "`nASCII " . Key . " - 98) Creating this hotkey would exceed the 1000-hotkey-per-script limit (however, each hotkey can have an unlimited number of variants, and there is no limit to the number of hotstrings)."
		Else If (errorlevel = 99)
			str := str . "`nASCII " . Key . " - 99) Out of memory. This is very rare and usually happens only when the operating system has become unstable."

		MsgBox, %str%
	}
}

; ------------------ GET LEAGUES ------------------
TradeFunc_GetLeagues() {
     ;Loop over league info and get league names
	leagues		:= {}
	poeTradeLeagues:= TradeGlobals.Get("AvailableLeagues")
	hardcore := "hardcore"
	standard := "standard"

	For key, val in LeaguesData {
		If (!val.event and not RegExMatch(val.id, "i)^SSF"))  {
			If (val.id = standard) {
				leagues[standard] := val.id
			}
			Else If (val.id = hardcore) {
				leagues[hardcore] := val.id
			}
			Else If (InStr(val.id, hardcore)) {
				leagues["tmp" hardcore] := val.id
			}
			Else {
				leagues["tmp" standard] := val.id
			}
		}
		Else {
			For i, value in poeTradeLeagues {
				If (value = val.id) {
					trimmedValue := Format("{:L}", RegExReplace(value, "i)\s", ""))
					leagues[trimmedValue] := value
				}
			}
		}
	}

	; add additional supported leagues like beta leagues (no league API for them)
	; make sure there are no duplicate temp leagues (hardcoded keys)
	For j, value in poeTradeLeagues {
		trimmedValue := Format("{:L}", RegExReplace(value, "i)\s", ""))
		If (not leagues[trimmedValue]) {
			found := false
			For i, l in leagues {
				If (value = l) {
					found := true
				}
			}
			If (not found) {
				leagues[trimmedValue] := value
			}
		}
	}
	
	Return leagues
}

; ------------------ CHECK IF A TEMP-LEAGUE IS ACTIVE ------------------
; ltype : event for flashback and similiar events, "" otherwise
TradeFunc_CheckIfTempLeagueIsRunning(ltype = "") {
	tempLeagueDates := TradeFunc_GetTempLeagueDates(ltype)

	If (!tempLeagueDates) {
		hcEvent := RegExMatch(TradeOpts.SearchLeague, "i)(hardcore|hc).*event")
		defaultLeague := (RegExMatch(TradeOpts.SearchLeague, "i)standard|event") and not hcEvent) ? "standard" : "hardcore"
		Return 0
	}

	UTCTimestamp := TradeFunc_GetTimestampUTC()
	UTCFormatStr := "yyyy-MM-dd'T'HH:mm:ss'Z'"
	FormatTime, TimeStr, %UTCTimestamp% L0x0407, %UTCFormatStr%

	timeDiffStart := TradeFunc_DateParse(TimeStr) - TradeFunc_DateParse(tempLeagueDates["start"])
	timeDiffEnd   := TradeFunc_DateParse(TimeStr) - TradeFunc_DateParse(tempLeagueDates["end"])

	If (timeDiffStart > 0 && timeDiffEnd < 0) {
		; Current datetime is between temp league start and end date
		defaultLeague := (not RegExMatch(TradeOpts.SearchLeague, "i)event")) ? "tmpstandard" : "event"
		Return 1
	}
	Else {
		defaultLeague := "standard"
		Return 0
	}
}

TradeFunc_GetTimestampUTC() {
	; http://msdn.microsoft.com/en-us/library/ms724390
	VarSetCapacity(ST, 16, 0) ; SYSTEMTIME structure
	DllCall("Kernel32.dll\GetSystemTime", "Ptr", &ST)
	Return NumGet(ST, 0, "UShort")                        ; year   : 4 digits until 10000
        . SubStr("0" . NumGet(ST,  2, "UShort"), -1)     ; month  : 2 digits forced
        . SubStr("0" . NumGet(ST,  6, "UShort"), -1)     ; day    : 2 digits forced
        . SubStr("0" . NumGet(ST,  8, "UShort"), -1)     ; hour   : 2 digits forced
        . SubStr("0" . NumGet(ST, 10, "UShort"), -1)     ; minute : 2 digits forced
        . SubStr("0" . NumGet(ST, 12, "UShort"), -1)     ; second : 2 digits forced
}

TradeFunc_DateParse(str) {
    ; Parse ISO 8601 Formatted Date/Time to YYYYMMDDHH24MISS timestamp
	str := RegExReplace(str, "i)-|T|:|Z")
	Return str
}

TradeFunc_GetTempLeagueDates(ltype = "") {
	tempLeagueDates := []

	For key, val in LeaguesData {
		If (val.endAt and val.startAt) {
			If (not val.event and (not ltype or ltype != "event")) {
				tempLeagueDates["start"] := val.startAt
				tempLeagueDates["end"] := val.endAt
				Return tempLeagueDates	
			}
			Else If (ltype = "event") {
				ssf := false
				Loop, % val.rules.Length() {
					If (val.rules[A_Index].name = "Solo" or InStr(val.id, "SSF ")) {
						ssf := true
					}
				}
				
				If (not ssf) {
					tempLeagueDates["start"] := val.startAt
					tempLeagueDates["end"] := val.endAt
					Return tempLeagueDates
				}
			}			
		}
	}
	Return 0
}


;----------------------- Handle available script updates ---------------------------------------
TradeFunc_ScriptUpdate() {
	If (firstUpdateCheck) {
		ShowUpdateNotification := TradeOpts.ShowUpdateNotifications
	} Else {
		ShowUpdateNotification := 1
	}
	SplashScreenTitle := "PoE-TradeMacro"
	PoEScripts_Update(globalUpdateInfo.user, globalUpdateInfo.repo, globalUpdateInfo.releaseVersion, ShowUpdateNotification, userDirectory, isDevVersion, globalUpdateInfo.skipSelection, globalUpdateInfo.skipBackup, SplashScreenTitle, TradeOpts.Debug)
}

;----------------------- Trade Settings UI (added onto ItemInfos Settings UI) ---------------------------------------
CreateTradeSettingsUI()
{
	Global

	Fonts.SetUIFont()
	
	Scripts := TradeGlobals.Get("SettingsScriptList")
	TabNames := ""
	Loop, % Scripts.Length() {
		name := Scripts[A_Index]
		TabNames .= name "|"
	}

	StringTrimRight, TabNames, TabNames, 1
	Gui, Add, Tab3, Choose1 h660 x0, %TabNames%

	/* 
		General
	*/

	GuiAddGroupBox("[TradeMacro] General", "x7 y+7 w310 h380")

    ; Note: window handles (hwnd) are only needed if a UI tooltip should be attached.

	GuiAddText("Show Items:", "x17 yp+28 w230 h20 0x0100", "LblShowItemResults", "LblShowItemResultsH")
	AddToolTip(LblShowItemResultsH, "Number of items displayed in search results.")
	GuiAddEdit(TradeOpts.ShowItemResults, "x+10 yp-2 w50 h20", "ShowItemResults", "ShowItemResultsH")

	GuiAddCheckbox("Show Account Name", "x17 yp+24 w260 h30", TradeOpts.ShowAccountName, "ShowAccountName", "ShowAccountNameH")
	AddToolTip(ShowAccountNameH, "Show sellers account name in search results tooltip.")

	GuiAddCheckbox("Update: Show Notifications", "x17 yp+30 w260 h30", TradeOpts.ShowUpdateNotifications, "ShowUpdateNotifications", "ShowUpdateNotificationsH")
	AddToolTip(ShowUpdateNotificationsH, "Notifies you when there's a new release available.")

	GuiAddCheckbox("Update: Skip folder selection", "x17 yp+30 w260 h30", TradeOpts.UpdateSkipSelection, "UpdateSkipSelection", "UpdateSkipSelectionH")
	AddToolTip(UpdateSkipSelectionH, "Skips selecting an update location.`nThe current script directory will be used as default.")

	GuiAddCheckbox("Update: Skip backup", "x17 yp+30 w260 h30", TradeOpts.UpdateSkipBackup, "UpdateSkipBackup", "UpdateSkipBackupH")
	AddToolTip(UpdateSkipBackupH, "Skips making a backup of the install location/folder.")

	GuiAddCheckbox("Open browser Win10 fix", "x17 yp+30 w260 h30", TradeOpts.OpenWithDefaultWin10Fix, "OpenWithDefaultWin10Fix", "OpenWithDefaultWin10FixH")
	AddToolTip(OpenWithDefaultWin10FixH, " If your PC always asks you what program to use to open`n the wiki-link, enable this to let ahk find your default`nprogram from the registry.")

	GuiAddText("Browser Path:", "x17 yp+35 w100 h20 0x0100", "LblBrowserPath", "LblBrowserPathH")
	AddToolTip(LblBrowserPathH, "Optional: Set the path to the browser (.exe) to open Urls with.")
	GuiAddEdit(TradeOpts.BrowserPath, "x+10 yp-2 w180 h20", "BrowserPath", "BrowserPathH")

	GuiAddCheckbox("Copy urls to clipboard.", "x17 yp+23 w260 h30", TradeOpts.CopyUrlToClipboard, "CopyUrlToClipboard", "CopyUrlToClipboardH")
	AddToolTip(CopyUrlToClipboardH, "Copies urls to your clipboard instead of directly opening them.")

	GuiAddCheckbox("Enable ""Url shortcuts"" without item hover.", "x17 yp+30 w260 h30", TradeOpts.OpenUrlsOnEmptyItem, "OpenUrlsOnEmptyItem", "OpenUrlsOnEmptyItemH")
	AddToolTip(OpenUrlsOnEmptyItemH, "This enables the ctrl+q and ctrl+w shortcuts`neven without hovering over an item.`nBe careful!")

	GuiAddCheckbox("Download Data Files on start", "x17 yp+30 w260 h30", TradeOpts.DownloadDataFiles, "DownloadDataFiles", "DownloadDataFilesH")
	AddToolTip(DownloadDataFilesH, "Downloads all data files (mods, enchantments etc) on every script start.`nBy disabling this, these files are only updated with new releases.`nDisabling is not recommended.")

	GuiAddCheckbox("Delete cookies on start", "x17 yp+30 w210 h30", TradeOpts.DeleteCookies, "DeleteCookies", "DeleteCookiesH")
	AddToolTip(DeleteCookiesH, "Delete Internet Explorer cookies.`nThe default option (all) is preferred.`n`nThis will be skipped if no cookies are needed to access poe.trade.")
	GuiAddDropDownList("All|poe.trade", "x+10 yp+4 w70", TradeOpts.CookieSelect, "CookieSelect", "CookieSelectH")

	GuiAddCheckbox("Use poedb.tw instead of the wiki.", "x17 yp+27 w260 h30 0x0100", TradeOpts.WikiAlternative, "WikiAlternative", "WikiAlternativeH")
	AddToolTip(WikiAlternativeH, "Use poedb.tw to open a page with information`nabout your item/item base.")

	/* 
		Search
	*/

	GuiAddGroupBox("[TradeMacro] Search", "x327 y35 w310 h625")

	GuiAddText("League:", "x337 yp+28 w160 h20 0x0100", "LblSearchLeague", "LblSearchLeagueH")
	AddToolTip(LblSearchLeagueH, "Defaults to ""Standard"" or ""TmpStandard"" If there is a`nTemp-League active at the time of script execution.`n`n""TmpStandard"" and ""TmpHardcore"" are automatically replaced`nwith their permanent counterparts If no Temp-League is active.")
	LeagueList := TradeFunc_GetDelimitedLeagueList()
	GuiAddDropDownList(LeagueList, "x+10 yp-4", TradeOpts.SearchLeague, "SearchLeague", "SearchLeagueH")

	GuiAddText("Account Name:", "x337 yp+34 w160 h20 0x0100", "LblAccountName", "LblAccountNameH")
	AddToolTip(LblAccountNameH, "Your Account Name used to check your item's age.")
	GuiAddEdit(TradeOpts.AccountName, "x+10 yp-2 w120 h20", "AccountName", "AccountNameH")
	
	; gem section start
	GuiAddText("Gem Lvl:", "x337 yp+32 w54 h20 0x0100", "LblGemLevel", "LblGemLevelH")
	AddToolTip(LblGemLevelH, "Gem level is ignored in the search unless it's equal`nor higher than this value.`n`nSet to something like 30 to completely ignore the level.")
	GuiAddEdit(TradeOpts.GemLevel, "x+1 yp-2 w33 h20", "GemLevel", "GemLevelH")

	GuiAddText("Lvl Range:", "x+5 yp+2 w63 h20 0x0100", "LblGemLevelRange", "LblGemLevelRangeH")
	AddToolTip(LblGemLevelRangeH, "Uses Gem level option to create a range around it.`n `nSetting it to 0 ignores this option.")
	GuiAddEdit(TradeOpts.GemLevelRange, "x+1 yp-2 w33 h20", "GemLevelRange", "GemLevelRangeH")

	GuiAddText("Q. Range:", "x+5 yp+2 w62 h20 0x0100", "LblGemQualityRange", "LblGemQualityRangeH")
	AddToolTip(LblGemQualityRangeH, "Use this to set a range to quality Gem searches. For example a range of 1`n searches 14% - 16% when you have a 15% Quality Gem.`nSetting it to 0 (default) uses your Gems quality as min_quality`nwithout max_quality in your search.")
	GuiAddEdit(TradeOpts.GemQualityRange, "x+1 yp-2 w33 h20", "GemQualityRange", "GemQualityRangeH")
	; gem section end
	
	; gem xp section start
	GuiAddCheckbox("Use Gem XP", "x337 yp+24 w100 h30 0x0100", TradeOpts.UseGemXP, "UseGemXP", "UseGemXPH")
	AddToolTip(UseGemXP, "Use gem experience in the search.`n`nWorks for gems with a level of 19 and higher or`nEnhance, Empower and Enlighten.")
	
	GuiAddText("Gem XP threshold:", "x467 yp+8 w115 h20 0x0100", "LblGemXPThreshold", "LblGemXPThresholdH")
	AddToolTip(LblGemXPThresholdH, "Gem experience won't be used in the search if`nlower than this value.")
	GuiAddEdit(TradeOpts.GemXPThreshold, "x+10 yp-2 w35 h20", "GemXPThreshold", "GemXPThresholdH")
	; gem xp section end

	GuiAddText("Mod Range Modifier (%):", "x337 yp+32 w190 h20 0x0100", "LblAdvancedSearchModValueRange", "LblAdvancedSearchModValueRangeH")
	AddToolTip(LblAdvancedSearchModValueRangeH, "Advanced search lets you select the items mods to include in your`nsearch and lets you set their min/max values.`n`nThese min/max values are pre-filled, to calculate them we look at`nthe difference between the mods theoretical max and min value and`ntreat it as 100%.`n`nWe then use this modifier as a percentage of this differences to`ncreate a range (min/max value) to search in. ")
	GuiAddEdit(TradeOpts.AdvancedSearchModValueRangeMin, "x+10 yp-2 w35 h20", "AdvancedSearchModValueRangeMin", "AdvancedSearchModValueRangeMinH")
	GuiAddText(" -", "x+5 yp+2 w10 h20 0x0100", "LblAdvancedSearchModValueRangeSpacer", "LblAdvancedSearchModValueRangeSpacerH")
	GuiAddEdit(TradeOpts.AdvancedSearchModValueRangeMax, "x+5 yp-2 w35 h20", "AdvancedSearchModValueRangeMax", "AdvancedSearchModValueRangeMaxH")

	GuiAddText("Corrupted:", "x337 yp+32 w150 h20 0x0100", "LblCorrupted", "LblCorruptedH")
	AddToolTip(LblCorruptedH, "Default = search results have the same corrupted state as the checked item.`nUse this option to override that and always search as selected.")
	GuiAddDropDownList("Either|Yes|No", "x+10 yp-4 w52", TradeOpts.Corrupted, "Corrupted", "CorruptedH")
	GuiAddCheckbox("Override", "x+10 yp+4 0x0100", TradeOpts.CorruptedOverride, "CorruptedOverride", "CorruptedOverrideH", "TradeSettingsUI_ChkCorruptedOverride")

	GoSub, TradeSettingsUI_ChkCorruptedOverride

	CurrencyList := TradeFunc_GetDelimitedCurrencyListString()
	GuiAddText("Currency Search:", "x337 yp+30 w160 h20 0x0100", "LblCurrencySearchHave", "LblCurrencySearchHaveH")
	AddToolTip(LblCurrencySearchHaveH, "This settings sets the currency that you`nwant to use as ""have"" for the currency search.")
	GuiAddDropDownList(CurrencyList, "x+10 yp-4", TradeOpts.CurrencySearchHave, "CurrencySearchHave", "CurrencySearchHaveH")

	GuiAddText("Secondary Currency:", "x337 yp+30 w160 h20 0x0100", "LblCurrencySearchHave2", "LblCurrencySearchHave2H")
	AddToolTip(LblCurrencySearchHave2H, "This setting sets the currency that you`nwant to use as ""have"" when searching for`nthe above selected currency.")
	GuiAddDropDownList(CurrencyList, "x+10 yp-4", TradeOpts.CurrencySearchHave2, "CurrencySearchHave2", "CurrencySearchHave2H")

	; option group start
	GuiAddCheckbox("Use the ""exact currency"" option.", "x337 yp+27 w280 h20", TradeOpts.ExactCurrencySearch, "ExactCurrencySearch", "ExactCurrencySearchH")
	AddToolTip(ExactCurrencySearchH, "Searches for exact currencies, will ignore results not listed as these.`nOnly applicable to searches using poe.trade.`n`nUses the selected currencies from the ""Currency Search"" and ""Secondary Search"" option.`nSecondary currency will be used for a second search if no results are found.")
	
	; option group start
	GuiAddCheckbox("Show prices as chaos equivalent.", "x337 yp+25 w280 h20", TradeOpts.ShowPricesAsChaosEquiv, "ShowPricesAsChaosEquiv", "ShowPricesAsChaosEquivH")
	AddToolTip(ShowPricesAsChaosEquivH, "Shows all prices as their chaos equivalent.")

	; option group start
	GuiAddCheckbox("Online only", "x337 yp+25 w145 h20 0x0100", TradeOpts.OnlineOnly, "OnlineOnly", "OnlineOnlyH")

	GuiAddCheckbox("Buyout only", "x482 yp0 w145 h20 0x0100", TradeOpts.BuyoutOnly, "BuyoutOnly", "BuyoutOnlyH")
	AddToolTip(BuyoutOnlyH, "This option only takes affect when opening the search on poe.trade.")

	; option group start
	GuiAddCheckbox("Force max links (certain corrupted items).", "x337 yp+25 w280 h20", TradeOpts.ForceMaxLinks, "ForceMaxLinks", "ForceMaxLinksH")
	AddToolTip(ForceMaxLinksH, "Searches for corrupted 3/4 max-socket unique items always use`nthe maximum amount of links if your item is fully linked.")
	
	; option group start
	GuiAddCheckbox("Remove multiple Listings from same Account.", "x337 yp+25 w280 h20", TradeOpts.RemoveMultipleListingsFromSameAccount, "RemoveMultipleListingsFromSameAccount", "RemoveMultipleListingsFromSameAccountH")
	AddToolTip(RemoveMultipleListingsFromSameAccountH, "Removes multiple listings from the same account from`nyour search results (to combat market manipulators).`n`nThe removed items are also removed from the average and`nmedian price calculations.")
	
	; option group start
	GuiAddCheckbox("Alternative currency search.", "x337 yp+25 w280 h20", TradeOpts.AlternativeCurrencySearch, "AlternativeCurrencySearch", "AlternativeCurrencySearchH")
	AddToolTip(AlternativeCurrencySearchH, "Shows historical data of the searched currency.`nProvided by poe.ninja.")
	
	; option group start
	GuiAddCheckbox("Open items on poe.ninja.", "x337 yp+25 w280 h20", TradeOpts.PoENinjaSearch, "PoENinjaSearch", "PoENinjaSearchH")
	AddToolTip(PoENinjaSearchH, "Opens items on poe.ninja instead of poe.trade when using the ""Search (poe.trade)"" hotkey.`n`nOnly works on certain supported item types:`nDiv cards, prophecies, maps, uniques, essences, helmet enchants (have priority over item).")
	
	; option group start
	GuiAddCheckbox("Use predicted pricing.", "x337 yp+25 w145 h20", TradeOpts.UsePredictedItemPricing, "UsePredictedItemPricing", "UsePredictedItemPricingH")
	AddToolTip(UsePredictedItemPricingH, "Use predicted item pricing via machine-learning algorithms.`nReplaces the default search, works with magic/rare/unique items.`n`nProvided by poeprices.info.")

	; option group start
	GuiAddCheckbox("Use feedback Gui.", "x482 yp+0 w120 h20", TradeOpts.UsePredictedItemPricingGui, "UsePredictedItemPricingGui", "UsePredictedItemPricingGuiH")
	AddToolTip(UsePredictedItemPricingGuiH, "Use a Gui instead of the default tooltip to display results.`nYou can send some feedback to improve this feature.")

	; header
	GuiAddText("Pre-Select Options (Advanced Search)", "x337 yp+43 w280 h20 0x0100 cDA4F49", "", "")
	GuiAddText("-------------------------------------------------------------", "x337 yp+6 w280 h20 0x0100 cDA4F49", "", "")

	; option group start
	GuiAddCheckbox("Pre-Fill Min-Values", "x337 yp+16 w145 h20", TradeOpts.PrefillMinValue, "PrefillMinValue", "PrefillMinValueH")
	AddToolTip(PrefillMinValueH, "Automatically fill the min-values in the advanced search GUI.")

	GuiAddCheckbox("Pre-Fill Max-Values", "x482 yp0 w145 h20", TradeOpts.PrefillMaxValue, "PrefillMaxValue", "PrefillMaxValueH")
	AddToolTip(PrefillMaxValueH, "Automatically fill the max-values in the advanced search GUI.")

	; option group start
	GuiAddCheckbox("Normal mods", "x337 yp+20 w135 h20", TradeOpts.AdvancedSearchCheckMods, "AdvancedSearchCheckMods", "AdvancedSearchCheckModsH")
	AddToolTip(AdvancedSearchCheckModsH, "Selects all normal mods (no pseudo mods)`nwhen creating the advanced search GUI.")

	GuiAddCheckbox("Total Ele Resistances", "x482 yp0 w145 h20", TradeOpts.AdvancedSearchCheckTotalEleRes, "AdvancedSearchCheckTotalEleRes", "AdvancedSearchCheckTotalEleResH")
	AddToolTip(AdvancedSearchCheckTotalEleResH, "Selects the total elemental resistances pseudo mod`nwhen creating the advanced search GUI.")

	; option group start
	GuiAddCheckbox("Life", "x337 yp+20 w50 h20", TradeOpts.AdvancedSearchCheckTotalLife, "AdvancedSearchCheckTotalLife", "AdvancedSearchCheckTotalLifeH")
	AddToolTip(AdvancedSearchCheckTotalLifeH, "Selects the total flat life pseudo mod or flat life mod and`n percent maximum increased life mod when creating the advanced search GUI.")

	GuiAddCheckbox("ES Mod", "x390 yp0 w60 h20", TradeOpts.AdvancedSearchCheckES, "AdvancedSearchCheckES", "AdvancedSearchCheckESH")
	AddToolTip(AdvancedSearchCheckESH, "Selects the flat energy shield mod and percent maximum increased `nenergy shield mod when creating the advanced search GUI.")

	GuiAddCheckbox("ES Defense Total", "x482 yp0 w135 h20", TradeOpts.AdvancedSearchCheckTotalES, "AdvancedSearchCheckTotalES", "AdvancedSearchCheckTotalESH")
	AddToolTip(AdvancedSearchCheckTotalESH, "Selects the energy shield total defense, for example on `narmour pieces when creating the advanced search GUI.")

	; option group start
	GuiAddCheckbox("Elemental DPS", "x337 yp+20 w135 h20", TradeOpts.AdvancedSearchCheckEDPS, "AdvancedSearchCheckEDPS", "AdvancedSearchCheckEDPSH")
	AddToolTip(AdvancedSearchCheckEDPSH, "Selects elemental damage per second`nwhen creating the advanced search GUI.")

	GuiAddCheckbox("Physical DPS", "x482 yp0 w135 h20", TradeOpts.AdvancedSearchCheckPDPS, "AdvancedSearchCheckPDPS", "AdvancedSearchCheckPDPSH")
	AddToolTip(AdvancedSearchCheckPDPSH, "Selects physical damage per second`nwhen creating the advanced search GUI.")

	; option group start
	GuiAddCheckbox("Minimum Item Level", "x337 yp+20 w135 h20", TradeOpts.AdvancedSearchCheckILVL, "AdvancedSearchCheckILVL", "AdvancedSearchCheckILVLH")
	AddToolTip(AdvancedSearchCheckILVLH, "Selects the items itemlevel as minimum itemlevel`nwhen creating the advanced search GUI.")

	GuiAddCheckbox("Item Base", "x482 yp0 w135 h20", TradeOpts.AdvancedSearchCheckBase, "AdvancedSearchCheckBase", "AdvancedSearchCheckBaseH")
	AddToolTip(AdvancedSearchCheckBaseH, "Selects the item base`nwhen creating the advanced search GUI.")

	;Gui, Add, Link, x337 yp+43 w280 cBlue BackgroundTrans, <a href="https://github.com/POE-TradeMacro/POE-TradeMacro/wiki/Options">Options Wiki-Page</a>

	/* 
		Hotkeys 
	*/

	GuiAddGroupBox("[TradeMacro] Hotkeys", "x647 y35 w310 h295")

	GuiAddCheckbox("Price Check:", "x657 yp+26 w165 h20 0x0100", TradeOpts.PriceCheckEnabled, "PriceCheckEnabled", "PriceCheckEnabledH")
	AddToolTip(PriceCheckEnabledH, "Check item prices.")
	GuiAddHotkey(TradeOpts.PriceCheckHotKey, "x+1 yp-2 w124 h20", "PriceCheckHotKey", "PriceCheckHotKeyH")
	AddToolTip(PriceCheckHotKeyH, "Press key/key combination.`nDefault: ctrl + d")

	GuiAddCheckbox("Advanced Price Check:", "x657 yp+32 w165 h20 0x010", TradeOpts.AdvancedPriceCheckEnabled, "AdvancedPriceCheckEnabled", "AdvancedPriceCheckEnabledH")
	AddToolTip(AdvancedPriceCheckEnabledH, "Select mods to include in your search`nbefore checking prices.")
	GuiAddHotkey(TradeOpts.AdvancedPriceCheckHotKey, "x+1 yp-2 w124 h20", "AdvancedPriceCheckHotKey", "AdvancedPriceCheckHotKeyH")
	AddToolTip(AdvancedPriceCheckHotKeyH, "Press key/key combination.`nDefault: ctrl + alt + d")

	GuiAddCheckbox("Custom Search:", "x657 yp+32 w165 h20 0x0100", TradeOpts.CustomInputSearchEnabled, "CustomInputSearchEnabled", "CustomInputSearchEnabledH")
	AddToolTip(CustomInputSearchEnabledH, "Custom text input search.")	
	GuiAddHotkey(TradeOpts.CustomInputSearchHotKey, "x+1 yp-2 w124 h20", "CustomInputSearchHotKey", "CustomInputSearchHotKeyH")
	AddToolTip(CustomInputSearchHotKeyH, "Press key/key combination.`nDefault: ctrl + i")

	GuiAddCheckbox("Search (poe.trade):", "x657 yp+32 w165 h20 0x0100", TradeOpts.OpenSearchOnPoeTradeEnabled, "OpenSearchOnPoeTradeEnabled", "OpenSearchOnPoeTradeEnabledH")
	AddToolTip(OpenSearchOnPoeTradeEnabledH, "Open your search on poe.trade instead of showing`na tooltip with results.")
	GuiAddHotkey(TradeOpts.OpenSearchOnPoeTradeHotKey, "x+1 yp-2 w124 h20", "OpenSearchOnPoeTradeHotKey", "OpenSearchOnPoeTradeHotKeyH")
	AddToolTip(OpenSearchOnPoeTradeHotKeyH, "Press key/key combination.`nDefault: ctrl + q")

	GuiAddCheckbox("Search (poeapp.com):", "x657 yp+32 w165 h20 0x0100", TradeOpts.OpenSearchOnPoEAppEnabled, "OpenSearchOnPoEAppEnabled", "OpenSearchOnPoEAppEnabledH")
	AddToolTip(OpenSearchOnPoEAppEnabledH, "Open your search on poeapp.com instead of showing`na tooltip with results.")
	GuiAddHotkey(TradeOpts.OpenSearchOnPoEAppHotKey, "x+1 yp-2 w124 h20", "OpenSearchOnPoEAppHotKey", "OpenSearchOnPoEAppHotKeyH")
	AddToolTip(OpenSearchOnPoEAppHotKeyH, "Press key/key combination.`nDefault: ctrl + shift + q")

	GuiAddCheckbox("Open Item (Wiki):", "x657 yp+32 w165 h20 0x0100", TradeOpts.OpenWikiEnabled, "OpenWikiEnabled", "OpenWikiEnabledH")
	AddToolTip(OpenWikiEnabledH, "Open your items page on the PoE-Wiki.")
	GuiAddHotkey(TradeOpts.OpenWikiHotKey, "x+1 yp-2 w124 h20", "OpenWikiHotKey", "OpenWikiHotKeyH")
	AddToolTip(OpenWikiHotKeyH, "Press key/key combination.`nDefault: ctrl + w")

	GuiAddCheckbox("Show Item Age:", "x657 yp+32 w165 h20 0x010", TradeOpts.ShowItemAgeEnabled, "ShowItemAgeEnabled", "ShowItemAgeEnabledH")
	AddToolTip(ShowItemAgeEnabledH, "Checks your item's age.")
	GuiAddHotkey(TradeOpts.ShowItemAgeHotkey, "x+1 yp-2 w124 h20", "ShowItemAgeHotkey", "ShowItemAgeHotkeyH")
	AddToolTip(ShowItemAgeHotkeyH, "Press key/key combination.`nDefault: ctrl + e")
	
	GuiAddCheckbox("Change League:", "x657 yp+32 w165 h20 0x0100", TradeOpts.ChangeLeagueEnabled, "ChangeLeagueEnabled", "ChangeLeagueEnabledH")
	AddToolTip(ChangeLeagueEnabledH, "Changes the league you're searching for the item in.")
	GuiAddHotkey(TradeOpts.ChangeLeagueHotkey, "x+1 yp-2 w124 h20", "ChangeLeagueHotkey", "ChangeLeagueHotkeyH")
	AddToolTip(ChangeLeagueHotkeyH, "Press key/key combination.`nDefault: ctrl + l")
	
	GuiAddCheckbox("Get currency ratio note:", "x657 yp+32 w165 h20 0x0100", TradeOpts.SetCurrencyRatio, "SetCurrencyRatio", "SetCurrencyRatioH")
	AddToolTip(SetCurrencyRatioH, "Copies an item note for premium tabs to your clipboard`nthat creates a valid currency ratio on all trade sites.")
	GuiAddHotkey(TradeOpts.SetCurrencyRatioHotkey, "x+1 yp-2 w124 h20", "SetCurrencyRatioHotkey", "SetCurrencyRatioHotkeyH")
	AddToolTip(SetCurrencyRatioHotkeyH, "Press key/key combination.`nDefault: alt + r")

	Gui, Add, Link, x657 yp+35 w210 h20 cBlue BackgroundTrans, <a href="http://www.autohotkey.com/docs/Hotkeys.htm">Hotkey Options</a>

	/* 
		Cookies
	*/

	GuiAddGroupBox("[TradeMacro] Manual cookie selection", "x647 yp+40 w310 h160")

	GuiAddCheckbox("Overwrite automatic cookie retrieval.", "x657 yp+20 w250 h30", TradeOpts.UseManualCookies, "UseManualCookies", "UseManualCookiesH")
	AddToolTip(UseManualCookiesH, "Use your own cookies instead of automatically retrieving`nthem from Internet Explorer.")

	GuiAddText("User-Agent:", "x657 yp+32 w120 h20 0x0100", "LblUserAgent", "LblUserAgentH")
	AddToolTip(LblUserAgentH, "Your browsers user-agent. See 'How to'.")
	GuiAddEdit(TradeOpts.UserAgent, "x+10 yp-2 w160 h20", "UserAgent", "UserAgentH")

	GuiAddText("__cfduid:", "x657 yp+30 w120 h20 0x0100", "LblCfdUid", "LblCfdUidH")
	AddToolTip(LblCfdUidH, "'__cfduid' cookie. See 'How to'.")
	GuiAddEdit(TradeOpts.CfdUid, "x+10 yp-2 w160 h20", "CfdUid", "CfdUidH")

	GuiAddText("cf_clearance:", "x657 yp+30 w120 h20 0x0100", "LblCfClearance", "LblCfClearanceH")
	AddToolTip(LblCfClearanceH, "'cf_clearance' cookie. See 'How to'.")
	GuiAddEdit(TradeOpts.CfClearance, "x+10 yp-2 w160 h20", "CfClearance", "CfClearanceH")

	Gui, Add, Link, x657 yp+28 w210 h20 cBlue BackgroundTrans, <a href="https://github.com/PoE-TradeMacro/POE-TradeMacro/wiki/Cookie-retrieval">How to</a>
	
	/* 
		Buttons
	*/
	
	GuiAddText("Mouse over settings to see a detailed description.", "x657 yp+40 w300 h30")

	GuiAddCheckbox("Debug Output", "x657 yp+13 w100 h25", TradeOpts.Debug, "Debug", "DebugH")
	AddToolTip(DebugH, "Don't use this unless you're developing!")

	GuiAddButton("Defaults", "x659 y+10 w90 h23", "TradeSettingsUI_BtnDefaults")
	GuiAddButton("Ok", "Default x+5 yp+0 w90 h23", "TradeSettingsUI_BtnOK")
	GuiAddButton("Cancel", "x+5 yp+0 w90 h23", "TradeSettingsUI_BtnCancel")

	GuiAddText("Use these buttons to change TradeMacro settings (ItemInfo has it's own buttons).", "x657 y+10 w300 h50 cRed")

	Gui, Tab, 2
}

TradeFunc_GetDelimitedLeagueList() {
	AvailableLeagues	:= TradeGlobals.Get("Leagues")
	TempLeagueList		:= []
	i := 0
	For key, league in AvailableLeagues {
		TempLeagueList[i] := key
		i++
	}
	Loop, % i {
		i--
		LeagueList .= (i = 0) ? TempLeagueList[i] : TempLeagueList[i] "|"
	}
	Return Format("{:L}", LeagueList)
}

TradeFunc_GetDelimitedCurrencyListString() {
	CurrencyList := ""
	CurrencyTemp := TradeGlobals.Get("CurrencyIDs")
	CurrencyTemp := TradeCurrencyNames.eng

	For currName, currID in CurrencyTemp {
		name := RegExReplace(currName,  "i)_", " ")
		; only use real currency items here
		RegExMatch(name, "i)fragment| set|essence| key|breachstone|mortal|sacrifice|remnant|splinter|blessing|offering| vessel", skip)
		If (!skip) {
			CurrencyList .= "|" . name
		}
	}
	Return CurrencyList
}

; NB: temporary hack
UpdateTradeSettingsUI()
{
	Global
	for keyName, keyVal in TradeOpts {
		if (keyName == "CookieSelect") {
			GuiUpdateDropdownList("All|poe.trade", keyVal, keyName)
		}
		else if (keyName == "SearchLeague") {
			GuiUpdateDropdownList(TradeFunc_GetDelimitedLeagueList(), keyVal, keyName)
		}
		else if (keyName == "CurrencySearchHave" || keyName == "CurrencySearchHave2") {
			GuiUpdateDropdownList(TradeFunc_GetDelimitedCurrencyListString(), keyVal, keyName)
		}
		else {
			GuiControl,, %keyName%, %keyVal%
		}
	}
	return
}

TradeFunc_SyncUpdateSettings(){
	globalUpdateInfo.skipSelection 	:= TradeOpts.UpdateSkipSelection
	globalUpdateInfo.skipBackup 		:= TradeOpts.UpdateSkipBackup
	globalUpdateInfo.skipUpdateCheck 	:= TradeOpts.ShowUpdateNotification
}

TradeFunc_CreateTradeAboutWindow() {
	IfNotEqual, FirstTimeA, No
	{
		Authors := TradeFunc_GetContributors(0)
		RelVer := TradeGlobals.get("ReleaseVersion")
		Gui, About:Font, S10 CA03410,verdana

		Gui, About:Add, Text, x705 y27 w170 h20 Center, Release %RelVer%
		Gui, About:Add, Picture, 0x1000 x462 y16 w230 h180, %A_ScriptDir%\resources\images\splash-bl.png
		Gui, About:Font, Underline C3571AC,verdana
		Gui, About:Add, Text, x705 y57 w170 h20 gTradeVisitForumsThread Center, PoE forums thread
		Gui, About:Add, Text, x705 y87 w170 h20 gTradeAboutDlg_GitHub Center, PoE-TradeMacro GitHub
		Gui, About:Add, Text, x705 y117 w170 h20 gOpenGithubWikiFromMenu Center, PoE-TradeMacro Wiki/FAQ
		Gui, About:Font, S7 CDefault normal, Verdana
		Gui, About:Add, Text, x461 y207 w410 h90,
		(LTrim
		This builds on top of PoE-ItemInfo which provides very useful item information on ctrl+c.
		With TradeMacro, price checking is added via ctrl+d, ctrl+alt+d or ctrl+i.
		You can also open the items wiki page via ctrl+w or open the item search on poe.trade instead via ctrl+q.

		(c) %A_YYYY% Eruyome and contributors:
		)
		Gui, About:Add, Text, x461 y297 w270 h80, %Authors%
	}
}

TradeFunc_GetContributors(AuthorsPerLine=0)
{
	IfNotExist, %A_ScriptDir%\resources\AUTHORS_Trade.txt
	{
		return "`r`n AUTHORS.txt missing `r`n"
	}
	Authors := "`r`n"
	i := 0
	Loop, Read, %A_ScriptDir%\resources\AUTHORS_Trade.txt, `r, `n
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

TradeFunc_ReadCraftingBases() {
	bases := []
	Loop, Read, %A_ScriptDir%\data_trade\crafting_bases.txt
	{
		bases.push(A_LoopReadLine)
	}
	Return bases
}

TradeFunc_ReadEnchantments() {
	enchantments := {}
	enchantments.boots   := []
	enchantments.helmet  := []
	enchantments.gloves  := []

	Loop, Read, %A_ScriptDir%\data_trade\boot_enchantment_mods.txt
	{
		If (StrLen(Trim(A_LoopReadLine)) > 0) {
			enchantments.boots.push(A_LoopReadLine)
		}
	}
	Loop, Read, %A_ScriptDir%\data_trade\helmet_enchantment_mods.txt
	{
		If (StrLen(Trim(A_LoopReadLine)) > 0) {
			enchantments.helmet.push(A_LoopReadLine)
		}
	}
	Loop, Read, %A_ScriptDir%\data_trade\glove_enchantment_mods.txt
	{
		If (StrLen(Trim(A_LoopReadLine)) > 0) {
			enchantments.gloves.push(A_LoopReadLine)
		}
	}
	Return enchantments
}

TradeFunc_ReadCorruptions() {
	mods := []

	Loop, read, %A_ScriptDir%\data_trade\item_corrupted_mods.txt
	{
		If (StrLen(Trim(A_LoopReadLine)) > 0) {
			mods.push(A_LoopReadLine)
		}
	}
	Return mods
}

TradeFunc_CheckBrowserPath(path, showMsg) {
	If (StrLen(path) > 1) {
		path := RegExReplace(path, "i)\/", "\")
		AttributeString := FileExist(path)
		If (not AttributeString) {
			If (showMsg) {
				MsgBox % "Invalid FilePath."
			}
			Return false
		}
		Else {
			Return AttributeString
		}
	}
	Else {
		Return false
	}
}

; parse poe.trades gem names, other item types from the search form and available leagues
TradeFunc_ParseSearchFormOptions() {
	FileRead, html, %A_ScriptDir%\temp\poe_trade_search_form_options.txt

	RegExMatch(html, "i)(var)?\s*(items_types\s*=\s*{.*?})", types)
	itemTypes := RegExReplace(types2, "i)items_types\s*=", "{""items_types"" :")
	itemTypes .= "}"
	parsedJSON := JSON.Load(itemTypes)

	availableLeagues := []
	RegExMatch(html, "isU)<select.*name=""league"".*<\/select>", leagues)
	Pos := 0
	While Pos := RegExMatch(leagues, "iU)option.*value=""(.*)"".*>", option, Pos + (StrLen(option) ? StrLen(option) : 1)) {
		availableLeagues.push(option1)
	}
	
	exactCurrencyOptions := {}
	exactCurrencyOptions.poetrade := {}
	RegExMatch(html, "i)(<select.*?name=""buyout_currency"".*<\/select>)", currencies)
	Pos := 0
	While Pos := RegExMatch(currencies1, "iU)option.*value=""(.*)"".*>(.*)<\/option>", option, Pos + (StrLen(option) ? StrLen(option) : 1)) {
		If (not RegExMatch(option1, "i)^(1|0)$") and option1) {
			exactCurrencyOptions.poetrade[RegExReplace(option2, "i)&#39;", "'")] := option1	
		}		
	}	

	TradeGlobals.Set("ItemTypeList", parsedJSON.items_types)
	TradeGlobals.Set("GemNameList", parsedJSON.items_types.gem)
	TradeGlobals.Set("ExactCurrencySearchOptions", exactCurrencyOptions)
	TradeGlobals.Set("AvailableLeagues", availableLeagues)
	itemTypes :=
	availableLeagues :=

	FileDelete, %A_ScriptDir%\temp\poe_trade_search_form_options.txt
}

TradeFunc_DownloadDataFiles() {
	; disabled while using debug mode
	owner	:= TradeGlobals.Get("GithubUser", "POE-TradeMacro")
	repo 	:= TradeGlobals.Get("GithubRepo", "POE-TradeMacro")
	url		:= "https://raw.githubusercontent.com/" . owner . "/" . repo . "/master/data_trade/"
	dir		= %A_ScriptDir%\data_trade
	bakDir	= %A_ScriptDir%\data_trade\old_data_files
	files	:= ["boot_enchantment_mods.txt", "crafting_bases.txt", "glove_enchantment_mods.txt", "helmet_enchantment_mods.txt"
				, "mods.json", "uniques.json", "relics.json", "item_bases_armour.json", "item_bases_weapon.json"]

	; create .bak files and download (overwrite) data files
	; if downloaded file exists move .bak-file to backup folder, otherwise restore .bak-file
	Loop % files.Length() {
		file := files[A_Index]
		filePath = %dir%\%file%
		FileCopy, %filePath%, %filePath%.bak
		output := PoEScripts_Download(url . file, postData := "", ioHdr := reqHeaders := "", options := "", false, false, false, "", reqHeadersCurl)
		If (A_Index = 1) {
			logMsg := "Data file download from " url "...`n`n" "cURL command:`n" reqHeadersCurl "`n`nAnswer:`n" ioHdr
			WriteToLogFile(logMsg, "StartupLog.txt", "PoE-TradeMacro")
		}

		FileDelete, %filePath%
		FileAppend, %output%, %filePath%

		Sleep,50
		If (FileExist(filePath) and not ErrorLevel) {
			FileMove, %filePath%.bak, %bakDir%\%file%
		}
		Else {
			FileMove, %dir%\%file%.bak, %dir%\%file%
		}
		ErrorLevel := 0
	}
	FileDelete, %dir%\*.bak
}

TradeFunc_CheckIfCloudFlareBypassNeeded() {
	; call this function without parameters to access poe.trade without cookies
	; if it succeeds we don't need any cookies
	If (!TradeFunc_TestCloudflareBypass("http://poe.trade", "", "", "", false, "PreventErrorMsg")) {
		TradeFunc_ReadCookieData()
	}
}

TradeFunc_ReadCookieData() {
	If (!TradeOpts.UseManualCookies) {
		SplashTextOn, 500, 40, PoE-TradeMacro, Reading user-agent and cookies from poe.trade, this can take`na few seconds if your Internet Explorer doesn't have the cookies cached.

		If (TradeOpts.DeleteCookies) {
			TradeFunc_ClearWebHistory()
		}

		; compile the c# script reading the user-agent and cookies
		DotNetFrameworkInstallation := TradeFunc_GetLatestDotNetInstallation()
		DotNetFrameworkPath := DotNetFrameworkInstallation.Path
		CompilerExe := "csc.exe"

		If (TradeOpts.Debug) {
			RunWait %comspec% /c "chcp 1251 & "%DotNetFrameworkPath%%CompilerExe%" /target:exe  /out:"%A_ScriptDir%\temp\getCookieData.exe" "%A_ScriptDir%\lib\getCookieData.cs""
		}
		Else {
			RunWait %comspec% /c "chcp 1251 & "%DotNetFrameworkPath%%CompilerExe%" /target:exe  /out:"%A_ScriptDir%\temp\getCookieData.exe" "%A_ScriptDir%\lib\getCookieData.cs"", , Hide
		}

		Try {
			If (!FileExist(A_ScriptDir "\temp\getCookieData.exe")) {
				CompiledExeNotFound := 1
				If (DotNetFrameworkInstallation.Major < 2) {
					WrongNetFrameworkVersion := 1
				}
			}
			Else {
				SetTimer, Kill_CookieDataExe, -15000
				global cdePID :=
				RunWait,  %A_ScriptDir%\temp\getCookieData.exe, , Hide, cdePID
			}
		} Catch e {
			CompiledExeNotFound := 1
		}

		; read user-agent and cookies
		CookieErrorLevel := 0
		If (FileExist(A_ScriptDir "\temp\cookie_data.txt")) {
			FileRead, cookieFile, %A_ScriptDir%\temp\cookie_data.txt
			Loop, parse, cookieFile, `n`r
			{
				RegExMatch(A_LoopField, "i)(.*)\s?=", key)
				RegExMatch(A_LoopField, "i)=\s?(.*)", value)

				If (InStr(key1, "useragent")) {
					url := "http://www.whatsmyua.info/"
					Try {
						wb := ComObjCreate("InternetExplorer.Application")
						wb.Visible := False
						wb.Navigate(url)
						TradeFunc_IELoad(wb)
						ua := wb.document.getElementById("rawUa").innerHTML
						;ua := RegExReplace(ua, "i)[^:]*:\s?+", "")
						ua := Trim(RegExReplace(ua, "i)rawUa:", ""))
						wb.quit
					} Catch e {

					}

					; user agent read via c# script seems to be wrong (at least sometimes)
					ua := (ua = Trim(value1)) ? Trim(value1) : ua
					; remove feature tokens from user agent since they aren't included since IE 9.0 anymore but navigator.userAgent still contains them
					featureTokenRegPaths := ["SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\5.0\User Agent\Post Platform", "SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\5.0\User Agent\Pre Platform"]
					featureTokenRegRoots := ["HKEY_LOCAL_MACHINE", "HKEY_CURRENT_USER"]

					For key, root in featureTokenRegRoots {
						For k, path in featureTokenRegPaths {
							Loop %root%, %path%, 1, 1
							{
								If (A_LoopRegType <> "KEY") {
									RegRead Value
									ua := RegExReplace(ua, "i)\s?+" A_LoopRegName "\s?+;", "")
								}
							}
						}
					}

					TradeGlobals.Set("UserAgent", Trim(ua))
				}
				Else If (InStr(key1, "cfduid")) {
					TradeGlobals.Set("cfduid", Trim(value1))
				}
				Else If (InStr(key1, "cf_clearance")) {
					TradeGlobals.Set("cfClearance", Trim(value1))
				}
			}
		}
		Else {
			CookieFileNotFound := 1
		}
	}
	Else {
		; use useragent/cookies from settings instead
		SplashTextOn, 500, 20, PoE-TradeMacro, Testing CloudFlare bypass using manual set user-agent/cookies.
		TradeGlobals.Set("UserAgent", TradeOpts.UserAgent)
		TradeGlobals.Set("cfduid", TradeOpts.CfdUid)
		TradeGlobals.Set("cfClearance", TradeOpts.CfClearance)
	}

	; check if useragent/cookies are all set
	cookiesSuccessfullyRead := 0
	If (StrLen(TradeGlobals.Get("UserAgent")) < 1) {
		CookieErrorLevel := 1
		cookiesSuccessfullyRead++
	}
	If (StrLen(TradeGlobals.Get("cfduid")) < 1) {
		CookieErrorLevel := 1
		cookiesSuccessfullyRead++
	}
	If (StrLen(TradeGlobals.Get("cfClearance")) < 1) {
		CookieErrorLevel := 1
		cookiesSuccessfullyRead++
	}

	; test connection to poe.trade
	If (!CookieErrorLevel) {
		accessForbidden := ""
		If (!TradeFunc_TestCloudflareBypass("http://poe.trade", TradeGlobals.Get("UserAgent"), TradeGlobals.Get("cfduid"), TradeGlobals.Get("cfClearance"), true, "", accessForbidden)) {
			BypassFailed := 1
		}
	}

	SplashTextOff
	If (CookieErrorLevel or BypassFailed or CompiledExeNotFound) {
		; collect debug information
		ScriptVersion	:= TradeGlobals.Get("ReleaseVersion")
		CookieFile	:= (!CookieFileNotFound) ? "Cookie file found." : "Cookie file not found."
		Cookies		:= (!CookieErrorLevel) ? "Retrieving cookies successful." : "Retrieving cookies failed."
		OSInfo		:= TradeFunc_GetOSInfo()
		Compilation	:= (!CompiledExeNotFound) ? "Compiling 'getCookieData' script successful." : "Compiling 'getCookieData' script failed."
		NetFramework	:= DotNetFrameworkInstallation.Number  ? "Net Framework used for compiling: v" DotNetFrameworkInstallation.Number : "Using manual cookies"
		RegRead, IEVersion, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Internet Explorer, svcVersion
		If (!IEVersion) {
			RegRead, IEVersion, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Internet Explorer\Version Vector, IE
		}
		IE := "Internet Explorer: v" IEVersion

		; create GUI window
		WinSet, AlwaysOnTop, Off, PoE-TradeMacro

		; something went wrong while compiling the script
		If (CompiledExeNotFound and not TradeOpts.UseManualCookies) {
			Gui, CookieWindow:Add, Text, cRed, <ScriptDirectory\temp\getCookieData.exe> not found!
			Gui, CookieWindow:Add, Text, , - It seems compiling and moving the .exe file failed.
			If (WrongNetFrameworkVersion) {
				Gui, CookieWindow:Add, Text, , `n- Net Framework 2 is required but it seems you don't have it.
				Gui, CookieWindow:Add, Link, cBlue, <a href="https://www.microsoft.com/en-us/download/details.aspx?id=17851">Download it here</a>
			}
		}
		; something went wrong while testing the connection to poe.trade
		Else If (BypassFailed or CookieErrorLevel) {
			If (StrLen(accessForbidden)) {
				Gui, CookieWindow:Add, Text, cRed, Bypassing poe.trades CloudFlare protection failed! Reason: Access forbidden.
				Gui, CookieWindow:Add, Text, , - Cookies and user-agent were retrieved.`n- Lowered/disabled Internet Explorer security settings can cause this to fail.
				cookiesDeleted := (TradeOpts.DeleteCookies and not TradeOpts.UseManualCookies) ? "Cookies were deleted on script start." : ""
				If (StrLen(cookiesDeleted)) {
					Gui, CookieWindow:Add, Text, , - %cookiesDeleted% Please try again and make sure that `n  you're not using any proxy server.
				}
				Gui, CookieWindow:Add, Text, , The connection test sometimes fails while using the correct user-agent/cookies. `nJust try it again to be sure.
				Gui, CookieWindow:Add, Text, , You can also try setting the cookies manually in the settings menu.

				text := "It's likely that you need valid cookies to access the requested page, which you don't have.`n"
				text .= "A possible reason for this is that the requested page is protected not only by a Javascript challenge but also by`n"
				text .= "a Captcha challenge which cannot be solved by the macro.`n"
				text .= "You can either read your browsers cookies manually and add them to the settings menu under 'Manual cookie `n"
				text .= "selection' or open your Internet Explorer, browse the requested page, manually solve the challenge and restart`n"
				text .= "the macro."
				Gui, CookieWindow:Add, Text, , % text

				Gui, CookieWindow:Add, Button, gOpenPageInInternetExplorer, Open IE
				Gui, CookieWindow:Add, Button, x+10 yp+0 gReloadScriptAtCookieError, Reload macro (challenge has to be solved)
			} Else {
				Gui, CookieWindow:Add, Text, cRed, Accessing poe.trade using cURL failed!
			}

			; something went wrong while reading the cookies
			If (CookieFileNotFound or CookieErrorLevel) {
				Gui, CookieWindow:Add, Text, cRed x10, Reading Cookie data failed!

				If (CookieFileNotFound) {
					Gui, CookieWindow:Add, Text, , - File <ProjectFolder\temp\cookie_data.txt> could not be found.
				}
				Else {
					text := ""
					cookiesDeleted := (TradeOpts.DeleteCookies and not TradeOpts.UseManualCookies) ? "`n- Cookies were deleted on script start." : ""
					If (!TradeOpts.UseManualCookies) {
						text .= "- The contents of <ProjectFolder\temp\cookie_data.txt> may be invalid." %cookiesDeleted% "`n"
					}
					Else {
						text .= "- The user-agent/cookies set in the settings menu may be invalid." %cookiesDeleted% "`n"
						text .= "  Make sure your cf_clearance is complete, it likely consists of 2 parts seperated by a '-'."
					}

					If (cookiesSuccessfullyRead < 3) {
						textC := StrLen(TradeGlobals.Get("UserAgent")) ? "- User-Agent found, " : "- User-Agent missing, "
						textC .= StrLen(TradeGlobals.Get("cfduid")) ? "cfduid found, " : "cfduid missing, "
						textC .= StrLen(TradeGlobals.Get("cfClearance")) ? "cf_clearance found, " : "cf_clearance missing.`n"
						text .= textC
					}
					text .= "- Your cookies will change every few days (make sure they are correct/refreshed)."
					Gui, CookieWindow:Add, Text, , %text%
				}
			}
		}

		Gui, CookieWindow:Add, Text, cRed x10, Make sure that no file in the PoE-TradeMacro folder is blocked by your antivirus software/firewall, `nnotably the file "lib\curl.exe".
		Gui, CookieWindow:Add, Text, cRed x10, Using a cellular hotspot via your mobile phone can also be the cause of this issue, try avoiding it!
		Gui, CookieWindow:Add, Link, cBlue, Take a look at the <a href="https://github.com/PoE-TradeMacro/POE-TradeMacro/wiki/FAQ">FAQ</a> first, especially the parts mentioning "cURL".
		Gui, CookieWindow:Add, Link, cBlue, Report on <a href="https://github.com/PoE-TradeMacro/POE-TradeMacro/issues/149#issuecomment-268639184">Github</a>, <a href="https://discord.gg/taKZqWw">Discord</a>, <a href="https://www.pathofexile.com/forum/view-thread/1757730/">the forum</a>.
		Gui, CookieWindow:Add, Text, , Please also provide this information in your report.
		Gui, CookieWindow:Add, Edit, r8 ReadOnly w530, %ScriptVersion% `n%CookieFile% `n%Cookies% `n%OSInfo% `n%Compilation% `n%NetFramework% `n%IE%
		Gui, CookieWindow:Add, Text, , Continue the script to access the settings menu or to use searches opening your Browser directly.
		If (!TradeOpts.UseManualCookies) {
			Gui, CookieWindow:Add, Button, y+10 gOpenCookieFile, Open cookie file
			Gui, CookieWindow:Add, Button, yp+0 x+10 gCloseCookieWindow, Continue
		}
		Else {
			Gui, CookieWindow:Add, Button, y+10 gCloseCookieWindow, Continue
		}

		If (!TradeOpts.UseManualCookies) {
			Gui, CookieWindow:Add, Text, x10, Delete Internet Explorer's poe.trade cookies and restart the script.
			Gui, CookieWindow:Add, Button, gDeleteCookies, Delete cookies
		}
		Gui, CookieWindow:Show, w550 xCenter yCenter, Notice
		ControlFocus, Continue, Notice
		WinWaitClose, Notice
	}
}

TradeFunc_IELoad(wb)	;You need to send the IE handle to the function unless you define it as global.
{
	Try {
		If !wb	;If wb is not a valid pointer then quit
			Return False

		Loop		;Otherwise sleep for .1 seconds until the page starts loading
			Sleep,500
		Until (wb.busy)

		Loop		;Once it starts loading wait until completes
			Sleep,100
		Until (!wb.busy)

		i := 0
		Loop		;optional check to wait for the page to completely load
		{
			Sleep, 100
			i++
			Try {
				ready := wb.Document.Readystate
			} Catch e {

			}
		}
		Until (ready = "Complete" or i = 200)

		Return True
	} Catch e {
		Return False
	}
}

TradeFunc_GetLatestDotNetInstallation() {
	Versions := []

	; Collect all versions with an "InstallPath" key and value
	SubKey := "Software\Microsoft\NET Framework Setup\NDP"
	Loop, 2
	{
		Loop HKEY_LOCAL_MACHINE, %SubKey%, 1, 1
		{
			Version := {}
			If (A_LoopRegType <> "KEY")
				RegRead Value

			RegExMatch(A_LoopRegSubKey, "i)\\v(\d+(\.\d+)?(\.\d+)?)", match)
			If (match) {
				If (A_LoopRegName = "InstallPath" and StrLen(Value)) {
					foundVersion := false
					Loop, % Versions.Length() {
						If (Versions[A_Index].Number "" == match1 "") {
							Versions[A_Index].Path   := Value
							foundVersion := true
						}
					}
					If (!foundVersion) {
						Version.Number := match1
						RegExMatch(Version.Number, "(\d+)(.\d+)?(.\d+)?", match)
						Version.Major  := RegExReplace(match1, "i)\.", "")
						Version.Minor  := RegExReplace(match2, "i)\.", "")
						Version.Patch  := RegExReplace(match3, "i)\.", "")
						Version.Path   := Value
						Versions.push(Version)
					}
				}
			}
		    ;Msgbox % A_LoopRegKey " - " A_LoopRegSubKey "`n" A_LoopRegType " - " A_LoopRegName " - " Value
		}

		; If an installation was found break the loop, else look through Wow6432Node to find 32bit versions installed in 64 bit systems
		If (Versions.Length()) {
			Break
		}
		Else {
			SubKey := "Software\Wow6432Node\Microsoft\NET Framework Setup\NDP"
		}
	}

	; Find the highest/latest version
	LatestDotNetInstall := {}
	Loop, % Versions.Length() {
		If (!LatestDotNetInstall.Number) {
			LatestDotNetInstall := Versions[A_Index]
		}

		RegExMatch(Versions[A_Index], "(\d+).(\d+).(\d+)(.*)", versioning)
		RegExMatch(LatestDotNetInstall, "(\d+).(\d+).(\d+)(.*)", versioningLatest)

		If (not versioning%A_Index% and not versioningLatest%A_Index%) {
			break
		}
		Else If (versioning%A_Index% > versioningLatest%A_Index%) {
			LatestDotNetInstall := Versions[A_Index]
		}
	}

	Return LatestDotNetInstall
}

TradeFunc_TestCloudflareBypass(Url, UserAgent="", cfduid="", cfClearance="", useCookies=false, PreventErrorMsg = "", ByRef forbiddenAccess = "") {
	postData		:= ""
	options		:= ""
	options		.= "`n" PreventErrorMsg

	reqHeaders	:= []
	authHeaders	:= []
	If (StrLen(UserAgent)) {
		reqHeaders.push("User-Agent: " UserAgent)
		authHeaders.push("User-Agent: " UserAgent)
		reqHeaders.push("Cookie: __cfduid=" cfduid "; cf_clearance=" cfClearance)
		authHeaders.push("Cookie: __cfduid=" cfduid "; cf_clearance=" cfClearance)
	} Else {
		reqHeaders.push("User-Agent:Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36")
	}

	reqHeaders.push("Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8")
	reqHeaders.push("Accept-Encoding:gzip, deflate")
	reqHeaders.push("Accept-Language:de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4")
	reqHeaders.push("Connection:keep-alive")
	reqHeaders.push("Upgrade-Insecure-Requests:1")

	html := ""
	html := PoEScripts_Download(Url, ioData := postData, ioHdr := reqHeaders, options, false, false, false, "", reqHeadersCurl, handleAccessForbidden := false)
	logMsg := "Testing CloudFlare bypass, connecting to " url "...`n`n" "cURL command:`n" reqHeadersCurl "`n`nAnswer:`n" ioHdr
	WriteToLogFile(logMsg, "StartupLog.txt", "PoE-TradeMacro")

	; pathofexile.com link in page footer (forum thread)
	RegExMatch(html, "i)pathofexile", match)
	If (match) {
		FileDelete, %A_ScriptDir%\temp\poe_trade_search_form_options.txt
		FileAppend, %html%, %A_ScriptDir%\temp\poe_trade_search_form_options.txt, utf-8
		TradeFunc_ParseSearchFormOptions()
		Return 1
	}
	Else If (not RegExMatch(ioHdr, "i)HTTP\/1.1 200 OK") and not StrLen(PreventErrorMsg) and not InStr(handleAccessForbidden, "Forbidden")) {
		TradeFunc_HandleConnectionFailure(authHeaders, ioHdr, url)
	}
	Else {
		FileDelete, %A_ScriptDir%\temp\poe_trade_gem_names.txt
		forbiddenAccess := handleAccessForbidden
		Return 0
	}
}

TradeFunc_HandleConnectionFailure(authHeaders, returnedHeaders, url = "") {
	SplashTextOff
	Gui, ConnectionFailure:Add, Text, x10 cRed, Request to %url% using cookies failed!
	text := "You can continue to run PoE-TradeMacro with limited functionality.`nThe only searches that will work are the ones`ndirectly openend in your browser."
	Gui, ConnectionFailure:Add, Text, , % text

	headers := ""
	For key, val in authHeaders {
		headers .= val "`n"
	}

	headers .= "`n--------------------------------`n`n" returnedHeaders

	Gui, ConnectionFailure:Add, Edit, r6 ReadOnly w430, %headers%
	LinkText := "Take a look at the <a href=""https://github.com/PoE-TradeMacro/POE-TradeMacro/wiki/FAQ"">FAQ</a>, especially the parts mentioning ""cURL""."
	Gui, ConnectionFailure:Add, Link, x10 y+10 cBlue, % LinkText

	Gui, ConnectionFailure:Add, Button, gContinueAtConnectionFailure, Continue
	Gui, ConnectionFailure:Show, w450 xCenter yCenter, Connection Failure

	ControlFocus, %LinkText%, Connection Failure
}

TradeFunc_ClearWebHistory() {
	; use this to delete all cookies
	ValidCmdList 	= Files,Cookies,History,Forms,Passwords,All,All2
	Files 		= 8 ; Clear Temporary Internet Files
	Cookies 		= 2 ; Clear Cookies
	History 		= 1 ; Clear History
	Forms 		= 16 ; Clear Form Data
	Passwords 	= 32 ; Clear Passwords
	All 			= 255 ; Clear all
	All2 		= 4351 ; Clear All and Also delete files and settings stored by add-ons

	If (!TradeOpts.CookieSelect == "All") {
		RunWait %comspec% /c "chcp 1251 & "%A_ScriptDir%\lib\clearWebHistory.bat"", , Hide
	}
	Else {
		DllCall("InetCpl.cpl\ClearMyTracksByProcess", uint, 2)
		; Fallback in case of enabled IE protected mode: http://www.winhelponline.com/blog/clear-ie-cache-command-line-rundll32/
		RunWait %comspec% /c "chcp 1251 & "%A_ScriptDir%\lib\clearWebHistoryAll.bat"", , Hide
	}

}

TradeFunc_GetOSInfo() {
	objWMIService := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\" . A_ComputerName . "\root\cimv2")
	colOS := objWMIService.ExecQuery("Select * from Win32_OperatingSystem")._NewEnum
	Versions := []
	Versions.Insert(e:=["5.1.2600","Windows XP, Service Pack 3"])
	Versions.Insert(e:=["6.0.6000","Windows Vista"])
	Versions.Insert(e:=["6.0.6002","Windows Vista, Service Pack 2"])
	Versions.Insert(e:=["6.0.6001","Server 2008"])
	Versions.Insert(e:=["6.1.7601","Windows 7"])
	Versions.Insert(e:=["6.1.8400","Windows Home Server 2011"])
	Versions.Insert(e:=["6.2.9200","Windows 8"])
	Versions.Insert(e:=["6.3.9200","Windows 8.1"])
	Versions.Insert(e:=["6.3.9600","Windows 8.1, Update 1"])
	Versions.Insert(e:=["10.0.10240","Windows 10"])

	While colOS[objOS] {
	;	MsgBox % "OS version: " . objOS.Version . " Service Pack " . objOS.ServicePackMajorVersion . " Build number " . objOS.BuildNumber
	}

	For i, e in Versions {
		If (e[1] = objOS.Version) {
			r := e[2] " (" A_OSVersion ")"
		}
		Else r := "Windows Version: " objOS.Version " (" A_OSVersion ")"
	}
	If ((FileExist("C:\Program Files (x86)")) ? 1 : 0)
		r .= ", 64bit."

	Return r
}

;----------------------- SplashScreens ---------------------------------------
TradeFunc_StartSplashScreen() {
	;SplashTextOn, , 20, PoE-TradeMacro, Initializing script...
	/*
	initArray := ["Sending Einhar to catch some canaries...", "Burying Sunder and KB in the Depths...", "Hiring Keanu Reeves as a cart driver...", "Hiring a wheely good escort...", 
	"Preparing GPU to mine Azurite...",  "Loading spell block... 3%... aborting...", "Exploring reddit's first infinite salt mine...", "Awakening the balrogs...", 
	"Sending the dark elves into some arc delves..."]
	*/
	initArray := ["Initializing script...", "Preparing Einhars welcoming party...", "Uninstalling Battle.net...", "Investigating the so-called ""Immortals""...", "Starting mobile app...", "Hunting some old friends..."]
	
	Random, randomNum, 1, initArray.MaxIndex()
	SplashTextOn, 300, 20, PoE-TradeMacro, % initArray[randomNum]
}

TradeFunc_StopSplashScreen() {
	SplashTextOff

	If (TradeOpts.Debug) {
		Menu, Tray, Add ; Separator
		Menu, Tray, Add, Test Item Pricing, DebugTestItemPricing
		Menu, Tray, Add ; Separator
		MsgBox, 4096, PoE-TradeMacro, Debug mode enabled! Disable in settings-menu unless you're developing!, 2
		Class_Console("console",0,335,650,900,,,,9)
		console.show()
		SetTimer, BringPoEWindowToFrontAfterInit, 1000

		gemList := TradeGlobals.Get("GemNameList")
		If(gemList.Length()) {
			console.log("Fetching gem names successful.")
		}
		Else {
			console.log("Fetching gem names failed.")
		}
	}

     ; Let timer run until ItemInfos global settings are set to overwrite them.
	SetTimer, OverwriteSettingsWidthTimer, 250
	SetTimer, OverwriteSettingsHeightTimer, 250
	SetTimer, OverwriteAboutWindowSizesTimer, 250
	SetTimer, OverwriteSettingsNameTimer, 250
	SetTimer, ChangeScriptListsTimer, 250
	SetTimer, OverwriteUpdateOptionsTimer, 250
	GoSub, ReadPoeNinjaCurrencyData
	GoSub, TrackUserCount
}
