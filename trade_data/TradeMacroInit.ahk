; TradeMacro Add-on to POE-ItemInfo
; IGN: Eruyome, ManicCompression

FileRemoveDir, %A_ScriptDir%/temp, 1
;https://autohotkey.com/boards/viewtopic.php?f=6&t=53
#Include, %A_ScriptDir%/lib/JSON.ahk
; Console https://autohotkey.com/boards/viewtopic.php?f=6&t=2116
#Include, %A_ScriptDir%/lib/Class_Console.ahk
#Include, %A_ScriptDir%/lib/DebugPrintArray.ahk
#Include, %A_ScriptDir%/lib/AssociatedProgram.ahk
#Include, %A_ScriptDir%/trade_data/jsonData.ahk
#Include, %A_ScriptDir%/trade_data/Version.txt

TradeMsgWrongAHKVersion := "AutoHotkey v" . TradeAHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < TradeAHKVersionRequired)
{
	MsgBox, 16, Wrong AutoHotkey Version, % TradeMsgWrongAHKVersion
	ExitApp
}

Menu, Tray, Icon, %A_ScriptDir%\trade_data\poe-trade-bl.ico

TradeFunc_StartSplashScreen()

; empty clipboard on start to fix first search searching random stuff
Clipboard := ""

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

global TradeTempDir := A_ScriptDir . "\temp"
global TradeDataDir := A_ScriptDir . "\trade_data"
global SettingsWindowWidth := 845 
global SavedTradeSettings := false

class TradeUserOptions {
	ShowItemResults := 15		    	; Number of Items shown as search result; defaults to 15 If not set.
	ShowUpdateNotifications := 1		; 1 = show, 0 = don't show
	OpenWithDefaultWin10Fix := 0    	; If your PC asks you what programm to use to open the wiki-link, set this to 1 
	ShowAccountName := 1            	; Show also sellers account name in the results window
	BrowserPath :=                  	; Show also sellers account name in the results window
	OpenUrlsOnEmptyItem := 0			; Open wiki/poe.trade also when no item was checked
	DownloadDataFiles := 0			; 
	DeleteCookies := 1				; Delete Internet Explorer cookies on startup (only poe.trade)
	
	Debug := 0      				; 
	
	PriceCheckHotKey := ^d        	; 
	AdvancedPriceCheckHotKey := ^!s	; 
	OpenWikiHotKey := ^w            	; 
	CustomInputSearch := ^i         	;     
	OpenSearchOnPoeTrade := ^q      	;     
	ShowItemAge := ^e               	;     
	
	PriceCheckEnabled :=1
	AdvancedPriceCheckEnabled :=1
	OpenWikiEnabled :=1
	CustomInputSearchEnabled :=1
	OpenSearchOnPoeTradeEnabled :=1
	ShowItemAgeEnabled :=1
	
	AccountName := ""               	; 
	SearchLeague := "tmpstandard"   	; Defaults to "standard" or "tmpstandard" If there is an active Temp-League at the time of script execution.
									; Possible values: 
									; 	"tmpstandard" (current SC Temp-League) 
									;	"tmphardcore" (current HC Temp-League) 
									;	"standard", 
									;    "hardcore"
	GemLevel := 16                  	; Gem level is ignored in the search unless it's equal or higher than this value
	GemLevelRange := 0              	; Gem level is ignored in the search unless it's equal or higher than this value
	GemQualityRange := 0            	; Use this to set a range to quality gems searches
	OnlineOnly := 1                 	; 1 = search online only; 0 = search offline, too.
	Corrupted := "Either"           	; 1 = yes; 0 = no; 2 = either, This setting gets ignored when you use the search on corrupted items.
	CorruptedOverride := 0          	;
	AdvancedSearchModValueRangeMin := 20 	; 
	AdvancedSearchModValueRangeMax := 20 	; 
	RemoveMultipleListingsFromSameAccount := 0 ;
	PrefillMinValue := 1            	;
	PrefillMaxValue := 1            	;
	CurrencySearchHave := "Chaos Orb" 	;
	BuyoutOnly := 1				;
	ForceMaxLinks := 1				;
	AlternativeCurrencySearch := 0	;
	
	Expire := 3					; cache expire min
}
TradeOpts := new TradeUserOptions()

IfNotExist, %A_ScriptDir%\trade_config.ini
{
	IfNotExist, %TradeDataDir%\trade_defaults.ini
	{
		CreateDefaultTradeConfig()
	}
	CopyDefaultTradeConfig()
}

; Check If Temp-Leagues are active and set defaultLeague accordingly
TradeGlobals.Set("TempLeagueIsRunning", TradeFunc_CheckIfTempLeagueIsRunning())
TradeGlobals.Set("DefaultLeague", (tempLeagueIsRunning > 0) ? "tmpstandard" : "standard")
TradeGlobals.Set("GithubUser", "POE-TradeMacro")
TradeGlobals.Set("GithubRepo", "POE-TradeMacro")
TradeGlobals.Set("ReleaseVersion", TradeReleaseVersion)
TradeGlobals.Set("SettingsUITitle", "PoE (Trade) Item Info Settings")
; set this variable to skip setting the project-name to "PoE-ItemInfo"
UseExternalProjectName := "PoE-TradeMacro"

ReadTradeConfig()
Sleep, 100
; set this variable to skip the update check in "PoE-ItemInfo.ahk"
SkipItemInfoUpdateCall := 1
TradeFunc_ScriptUpdate()

TradeGlobals.Set("Leagues", TradeFunc_GetLeagues())
SearchLeague := (StrLen(TradeOpts.SearchLeague) > 0) ? TradeOpts.SearchLeague : TradeGlobals.Get("DefaultLeague")
TradeGlobals.Set("LeagueName", TradeGlobals.Get("Leagues")[SearchLeague])

If (TradeOpts.AlternativeCurrencySearch) {
	GoSub, ReadPoeNinjaCurrencyData
}
TradeGlobals.Set("VariableUniqueData", TradeUniqueData)
TradeGlobals.Set("ModsData", TradeModsData)
TradeGlobals.Set("CraftingData", TradeFunc_ReadCraftingBases())
TradeGlobals.Set("EnchantmentData", TradeFunc_ReadEnchantments())
TradeGlobals.Set("CorruptedModsData", TradeFunc_ReadCorruptions())
TradeGlobals.Set("CurrencyIDs", object := {})

TradeFunc_ReadCookieData()
; get currency ids from currency.poe.trade
TradeFunc_DoCurrencyRequest("", false, true)
If (TradeOpts.DownloadDataFiles and not TradeOpts.Debug) {
	TradeFunc_DownloadDataFiles()	
}

CreateTradeSettingsUI()
TradeFunc_StopSplashScreen()

ReadTradeConfig(TradeConfigPath="trade_config.ini")
{
	Global
	IfExist, %TradeConfigPath%
	{
        ; General 		
		TradeOpts.ShowItemResults := TradeFunc_ReadIniValue(TradeConfigPath, "General", "ShowItemResults", TradeOpts.ShowItemResults)
		TradeOpts.ShowUpdateNotifications := TradeFunc_ReadIniValue(TradeConfigPath, "General", "ShowUpdateNotifications", TradeOpts.ShowUpdateNotifications)
		TradeOpts.OpenWithDefaultWin10Fix := TradeFunc_ReadIniValue(TradeConfigPath, "General", "OpenWithDefaultWin10Fix", TradeOpts.OpenWithDefaultWin10Fix)
		TradeOpts.ShowAccountName := TradeFunc_ReadIniValue(TradeConfigPath, "General", "ShowAccountName", TradeOpts.ShowAccountName)
		TradeOpts.OpenUrlsOnEmptyItem := TradeFunc_ReadIniValue(TradeConfigPath, "General", "OpenUrlsOnEmptyItem", TradeOpts.OpenUrlsOnEmptyItem)
		TradeOpts.DownloadDataFiles := TradeFunc_ReadIniValue(TradeConfigPath, "General", "DownloadDataFiles", TradeOpts.DownloadDataFiles)
		TradeOpts.DeleteCookies := TradeFunc_ReadIniValue(TradeConfigPath, "General", "DeleteCookies", TradeOpts.DeleteCookies)
		
        ; Check If browser path is valid, delete ini-entry If not
		BrowserPath := TradeFunc_ReadIniValue(TradeConfigPath, "General", "BrowserPath", TradeOpts.BrowserPath)
		If (TradeFunc_CheckBrowserPath(BrowserPath, false)) {
			TradeOpts.BrowserPath := BrowserPath
		}		
		Else {
			TradeFunc_WriteIniValue("", TradeConfigPath, "General", "BrowserPath")       
		}
		
        ; Debug        
		TradeOpts.Debug := TradeFunc_ReadIniValue(TradeConfigPath, "Debug", "Debug", 0)
		
        ; Hotkeys        
		TradeOpts.PriceCheckHotKey := TradeFunc_ReadIniValue(TradeConfigPath, "Hotkeys", "PriceCheckHotKey", TradeOpts.PriceCheckHotKey)
		TradeOpts.AdvancedPriceCheckHotKey := TradeFunc_ReadIniValue(TradeConfigPath, "Hotkeys", "AdvancedPriceCheckHotKey", TradeOpts.AdvancedPriceCheckHotKey)
		TradeOpts.OpenWikiHotKey := TradeFunc_ReadIniValue(TradeConfigPath, "Hotkeys", "OpenWiki", TradeOpts.OpenWikiHotKey)
		TradeOpts.CustomInputSearchHotKey := TradeFunc_ReadIniValue(TradeConfigPath, "Hotkeys", "CustomInputSearchHotKey", TradeOpts.CustomInputSearchHotKey)
		TradeOpts.OpenSearchOnPoeTradeHotKey := TradeFunc_ReadIniValue(TradeConfigPath, "Hotkeys", "OpenSearchOnPoeTradeHotKey", TradeOpts.OpenSearchOnPoeTradeHotKey)
		TradeOpts.ShowItemAgeHotKey := TradeFunc_ReadIniValue(TradeConfigPath, "Hotkeys", "ShowItemAgeHotKey", TradeOpts.ShowItemAgeHotKey)
		
		TradeOpts.PriceCheckEnabled := TradeFunc_ReadIniValue(TradeConfigPath, "HotkeyStates", "PriceCheckEnabled", TradeOpts.PriceCheckEnabled)        
		TradeOpts.AdvancedPriceCheckEnabled := TradeFunc_ReadIniValue(TradeConfigPath, "HotkeyStates", "AdvancedPriceCheckEnabled", TradeOpts.AdvancedPriceCheckEnabled)        
		TradeOpts.OpenWikiEnabled := TradeFunc_ReadIniValue(TradeConfigPath, "HotkeyStates", "OpenWikiEnabled", TradeOpts.OpenWikiEnabled)        
		TradeOpts.CustomInputSearchEnabled := TradeFunc_ReadIniValue(TradeConfigPath, "HotkeyStates", "CustomInputSearchEnabled", TradeOpts.CustomInputSearchEnabled)        
		TradeOpts.OpenSearchOnPoeTradeEnabled := TradeFunc_ReadIniValue(TradeConfigPath, "HotkeyStates", "OpenSearchOnPoeTradeEnabled", TradeOpts.OpenSearchOnPoeTradeEnabled)        
		TradeOpts.ShowItemAgeEnabled := TradeFunc_ReadIniValue(TradeConfigPath, "HotkeyStates", "ShowItemAgeEnabled", TradeOpts.ShowItemAgeEnabled)        
		
		TradeFunc_AssignAllHotkeys()
		
        ; Search     	
		TradeOpts.AccountName := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "AccountName", TradeOpts.AccountName)	
		TradeOpts.SearchLeague := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "SearchLeague", TradeGlobals.Get("DefaultLeague"))	
		temp := TradeOpts.SearchLeague
		StringLower, temp, temp
		TradeFunc_SetLeagueIfSelectedIsInactive()	
		TradeOpts.SearchLeague := temp
		
		TradeOpts.GemLevel := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "GemLevel", TradeOpts.GemLevel)	
		TradeOpts.GemLevelRange := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "GemLevelRange", TradeOpts.GemLevelRange)	
		TradeOpts.GemQualityRange := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "GemQualityRange", TradeOpts.GemQualityRange)	
		TradeOpts.OnlineOnly := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "OnlineOnly", TradeOpts.OnlineOnly)
		
		TradeOpts.CorruptedOverride := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "CorruptedOverride", TradeOpts.CorruptedOverride)	
		TradeOpts.Corrupted := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "Corrupted", TradeOpts.Corrupted)	
		temp := TradeOpts.Corrupted
		StringUpper, temp, temp, T
		TradeOpts.Corrupted := temp
		
		TradeOpts.AdvancedSearchModValueRangeMin := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "AdvancedSearchModValueRangeMin", TradeOpts.AdvancedSearchModValueRangeMin)	
		TradeOpts.AdvancedSearchModValueRangeMax := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "AdvancedSearchModValueRangeMax", TradeOpts.AdvancedSearchModValueRangeMax)	
		TradeOpts.RemoveMultipleListingsFromSameAccount := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "RemoveMultipleListingsFromSameAccount", TradeOpts.RemoveMultipleListingsFromSameAccount)	
		TradeOpts.PrefillMinValue := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "PrefillMinValue", TradeOpts.PrefillMinValue)	
		TradeOpts.PrefillMaxValue := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "PrefillMaxValue", TradeOpts.PrefillMaxValue)	
		TradeOpts.CurrencySearchHave := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "CurrencySearchHave", TradeOpts.CurrencySearchHave)	
		TradeOpts.BuyoutOnly := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "BuyoutOnly", TradeOpts.BuyoutOnly)	
		TradeOpts.ForceMaxLinks := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "ForceMaxLinks", TradeOpts.ForceMaxLinks)	
		TradeOpts.AlternativeCurrencySearch := TradeFunc_ReadIniValue(TradeConfigPath, "Search", "AlternativeCurrencySearch", TradeOpts.AlternativeCurrencySearch)	
		
        ; Cache        
		TradeOpts.Expire := TradeFunc_ReadIniValue(TradeConfigPath, "Cache", "Expire", TradeOpts.Expire)
	}
}

TradeFunc_AssignAllHotkeys() {
	If (TradeOpts.PriceCheckEnabled) {
		TradeFunc_AssignHotkey(TradeOpts.PriceCheckHotKey, "PriceCheck")
	}
	Else {
		key := TradeOpts.PriceCheckEnabled
		Hotkey, %key% , off, UseErrorLevel
	}
	If (TradeOpts.AdvancedPriceCheckEnabled) {
		TradeFunc_AssignHotkey(TradeOpts.AdvancedPriceCheckHotKey, "AdvancedPriceCheck")
	}
	Else {
		key := TradeOpts.AdvancedPriceCheckEnabled
		Hotkey, %key% , off, UseErrorLevel 
	}
	If (TradeOpts.OpenWikiEnabled) {
		TradeFunc_AssignHotkey(TradeOpts.OpenWikiHotKey, "OpenWiki")
	}
	Else {
		key := TradeOpts.OpenWikiEnabled
		Hotkey, %key% , off, UseErrorLevel 
	}
	If (TradeOpts.CustomInputSearchEnabled) {
		TradeFunc_AssignHotkey(TradeOpts.CustomInputSearchHotKey, "CustomInputSearch")
	}
	Else {
		key := TradeOpts.CustomInputSearchEnabled 
		Hotkey, %key% , off, UseErrorLevel 
	}
	If (TradeOpts.OpenSearchOnPoeTradeEnabled) {
		TradeFunc_AssignHotkey(TradeOpts.OpenSearchOnPoeTradeHotKey, "OpenSearchOnPoeTrade")
	}
	Else {
		key := TradeOpts.OpenSearchOnPoeTradeEnabled
		Hotkey, %key% , off, UseErrorLevel 
	}
	If (TradeOpts.ShowItemAgeEnabled) {
		TradeFunc_AssignHotkey(TradeOpts.ShowItemAgeHotKey, "ShowItemAge")
	}
	Else {
		key := TradeOpts.ShowItemAgeHotKey
		Hotkey, %key% , off, UseErrorLevel
	}
}

WriteTradeConfig(TradeConfigPath="trade_config.ini")
{  
	Global
	
	ValidBrowserPath := TradeFunc_CheckBrowserPath(BrowserPath, true)
	
    ; workaround for settings options not being assigned to TradeOpts    
	If (SavedTradeSettings) {
		TradeOpts.ShowItemResults := ShowItemResults
		TradeOpts.ShowUpdateNotifications := ShowUpdateNotifications
		TradeOpts.OpenWithDefaultWin10Fix := OpenWithDefaultWin10Fix
		TradeOpts.ShowAccountName := ShowAccountName
		TradeOpts.OpenUrlsOnEmptyItem := OpenUrlsOnEmptyItem
		TradeOpts.DownloadDataFiles := DownloadDataFiles
		TradeOpts.DeleteCookies := DeleteCookies
		TradeOpts.Debug := Debug
		
		If (ValidBrowserPath) {
			TradeOpts.BrowserPath := BrowserPath            
		}
		Else {
			TradeOpts.BrowserPath := ""      
		}
		
		TradeOpts.PriceCheckHotKey := PriceCheckHotKey
		TradeOpts.AdvancedPriceCheckHotKey := AdvancedPriceCheckHotKey
		TradeOpts.OpenWikiHotKey := OpenWikiHotKey
		TradeOpts.CustomInputSearchHotKey := CustomInputSearchHotKey
		TradeOpts.OpenSearchOnPoeTradeHotKey := OpenSearchOnPoeTradeHotKey
		TradeOpts.ShowItemAgeHotKey := ShowItemAgeHotKey
		
		TradeOpts.PriceCheckEnabled := PriceCheckEnabled
		TradeOpts.AdvancedPriceCheckEnabled := AdvancedPriceCheckEnabled
		TradeOpts.OpenWikiEnabled := OpenWikiEnabled
		TradeOpts.CustomInputSearchEnabled := CustomInputSearchEnabled
		TradeOpts.OpenSearchOnPoeTradeEnabled := OpenSearchOnPoeTradeEnabled
		TradeOpts.ShowItemAgeEnabled := ShowItemAgeEnabled
		
		TradeFunc_AssignAllHotkeys()
		
		TradeOpts.AccountName := AccountName
		tempOldLeague := TradeOpts.SearchLeague
		TradeOpts.SearchLeague := SearchLeague
		
		TradeFunc_SetLeagueIfSelectedIsInactive()        
		TradeGlobals.Set("LeagueName", TradeGlobals.Get("Leagues")[TradeOpts.SearchLeague])		
		
		tempOldAltCurrencySearch := TradeOpts.AlternativeCurrencySearch
		TradeOpts.AlternativeCurrencySearch := AlternativeCurrencySearch
		
		; Get currency data only if league was changed while alternate search is active or alternate search was changed from disabled to enabled
		If ((TradeOpts.SearchLeague != tempOldLeague and AlternativeCurrencySearch) or (AlternativeCurrencySearch and tempOldAltCurrencySearch != AlternativeCurrencySearch)) {			
			GoSub, ReadPoeNinjaCurrencyData	
		}
		
		TradeOpts.GemLevel := GemLevel
		TradeOpts.GemLevelRange := GemLevelRange
		TradeOpts.GemQualityRange := GemQualityRange
		TradeOpts.OnlineOnly := OnlineOnly
		TradeOpts.Corrupted := Corrupted
		TradeOpts.CorruptedOverride := CorruptedOverride
		TradeOpts.AdvancedSearchModValueRangeMin := AdvancedSearchModValueRangeMin
		TradeOpts.AdvancedSearchModValueRangeMax := AdvancedSearchModValueRangeMax
		TradeOpts.RemoveMultipleListingsFromSameAccount := RemoveMultipleListingsFromSameAccount
		TradeOpts.PrefillMinValue := PrefillMinValue
		TradeOpts.PrefillMaxValue := PrefillMaxValue
		TradeOpts.CurrencySearchHave := CurrencySearchHave
		TradeOpts.BuyoutOnly := BuyoutOnly
		TradeOpts.ForceMaxLinks := ForceMaxLinks
	}        
	SavedTradeSettings := false
	
    ; General        
	TradeFunc_WriteIniValue(TradeOpts.ShowItemResults, TradeConfigPath, "General", "ShowItemResults")
	TradeFunc_WriteIniValue(TradeOpts.ShowUpdateNotifications, TradeConfigPath, "General", "ShowUpdateNotifications")
	TradeFunc_WriteIniValue(TradeOpts.OpenWithDefaultWin10Fix, TradeConfigPath, "General", "OpenWithDefaultWin10Fix")
	TradeFunc_WriteIniValue(TradeOpts.ShowAccountName, TradeConfigPath, "General", "ShowAccountName")   
	TradeFunc_WriteIniValue(TradeOpts.OpenUrlsOnEmptyItem, TradeConfigPath, "General", "OpenUrlsOnEmptyItem")   
	TradeFunc_WriteIniValue(TradeOpts.DownloadDataFiles, TradeConfigPath, "General", "DownloadDataFiles")   
	TradeFunc_WriteIniValue(TradeOpts.DeleteCookies, TradeConfigPath, "General", "DeleteCookies")   
	
	If (ValidBrowserPath) {
		TradeFunc_WriteIniValue(TradeOpts.BrowserPath, TradeConfigPath, "General", "BrowserPath")           
	}
	Else {
		TradeFunc_WriteIniValue("", TradeConfigPath, "General", "BrowserPath")           
	}
	
	; Debug	
	TradeFunc_WriteIniValue(TradeOpts.Debug, TradeConfigPath, "Debug", "Debug")
	
	; Hotkeys	
	TradeFunc_WriteIniValue(TradeOpts.PriceCheckHotKey, TradeConfigPath, "Hotkeys", "PriceCheckHotKey")
	TradeFunc_WriteIniValue(TradeOpts.AdvancedPriceCheckHotKey, TradeConfigPath, "Hotkeys", "AdvancedPriceCheckHotKey")
	TradeFunc_WriteIniValue(TradeOpts.OpenWikiHotKey, TradeConfigPath, "Hotkeys", "OpenWikiHotKey")
	TradeFunc_WriteIniValue(TradeOpts.CustomInputSearchHotKey, TradeConfigPath, "Hotkeys", "CustomInputSearchHotKey")
	TradeFunc_WriteIniValue(TradeOpts.OpenSearchOnPoeTradeHotKey, TradeConfigPath, "Hotkeys", "OpenSearchOnPoeTradeHotKey")
	TradeFunc_WriteIniValue(TradeOpts.ShowItemAgeHotKey, TradeConfigPath, "Hotkeys", "ShowItemAgeHotKey")
	
	TradeFunc_WriteIniValue(TradeOpts.PriceCheckEnabled, TradeConfigPath, "HotkeyStates", "PriceCheckEnabled")
	TradeFunc_WriteIniValue(TradeOpts.AdvancedPriceCheckEnabled, TradeConfigPath, "HotkeyStates", "AdvancedPriceCheckEnabled")
	TradeFunc_WriteIniValue(TradeOpts.OpenWikiEnabled, TradeConfigPath, "HotkeyStates", "OpenWikiEnabled")
	TradeFunc_WriteIniValue(TradeOpts.CustomInputSearchEnabled, TradeConfigPath, "HotkeyStates", "CustomInputSearchEnabled")
	TradeFunc_WriteIniValue(TradeOpts.OpenSearchOnPoeTradeEnabled, TradeConfigPath, "HotkeyStates", "OpenSearchOnPoeTradeEnabled")
	TradeFunc_WriteIniValue(TradeOpts.ShowItemAgeEnabled, TradeConfigPath, "HotkeyStates", "ShowItemAgeEnabled")
	
	; Search	
	TradeFunc_WriteIniValue(TradeOpts.AccountName, TradeConfigPath, "Search", "AccountName")
	TradeFunc_WriteIniValue(TradeOpts.SearchLeague, TradeConfigPath, "Search", "SearchLeague")
	TradeFunc_WriteIniValue(TradeOpts.GemLevel, TradeConfigPath, "Search", "GemLevel")
	TradeFunc_WriteIniValue(TradeOpts.GemLevelRange, TradeConfigPath, "Search", "GemLevelRange")
	TradeFunc_WriteIniValue(TradeOpts.GemQualityRange, TradeConfigPath, "Search", "GemQualityRange")
	TradeFunc_WriteIniValue(TradeOpts.OnlineOnly, TradeConfigPath, "Search", "OnlineOnly")
	TradeFunc_WriteIniValue(TradeOpts.CorruptedOverride, TradeConfigPath, "Search", "CorruptedOverride")
	TradeFunc_WriteIniValue(TradeOpts.Corrupted, TradeConfigPath, "Search", "Corrupted")
	TradeFunc_WriteIniValue(TradeOpts.AdvancedSearchModValueRangeMin, TradeConfigPath, "Search", "AdvancedSearchModValueRangeMin")
	TradeFunc_WriteIniValue(TradeOpts.AdvancedSearchModValueRangeMax, TradeConfigPath, "Search", "AdvancedSearchModValueRangeMax")
	TradeFunc_WriteIniValue(TradeOpts.RemoveMultipleListingsFromSameAccount, TradeConfigPath, "Search", "RemoveMultipleListingsFromSameAccount")
	TradeFunc_WriteIniValue(TradeOpts.PrefillMinValue, TradeConfigPath, "Search", "PrefillMinValue")
	TradeFunc_WriteIniValue(TradeOpts.PrefillMaxValue, TradeConfigPath, "Search", "PrefillMaxValue")
	TradeFunc_WriteIniValue(TradeOpts.CurrencySearchHave, TradeConfigPath, "Search", "CurrencySearchHave")
	TradeFunc_WriteIniValue(TradeOpts.BuyoutOnly, TradeConfigPath, "Search", "BuyoutOnly")
	TradeFunc_WriteIniValue(TradeOpts.ForceMaxLinks, TradeConfigPath, "Search", "ForceMaxLinks")
	TradeFunc_WriteIniValue(TradeOpts.AlternativeCurrencySearch, TradeConfigPath, "Search", "AlternativeCurrencySearch")
	
	; Cache	
	TradeFunc_WriteIniValue(TradeOpts.Expire, TradeConfigPath, "Cache", "Expire")
}

CopyDefaultTradeConfig()
{
	FileCopy, %TradeDataDir%\trade_defaults.ini, %A_ScriptDir%
	FileMove, %A_ScriptDir%\trade_defaults.ini, %A_ScriptDir%\trade_config.ini
}

RemoveTradeConfig()
{
	FileDelete, %A_ScriptDir%\trade_config.ini
}

CreateDefaultTradeConfig()
{
	WriteTradeConfig(%TradeDataDir% . "\trade_defaults.ini")
}

TradeFunc_SetLeagueIfSelectedIsInactive() 
{	
	; Check If league from Ini is set to an inactive league and change it to the corresponding active one, for example tmpstandard to standard	
	If (InStr(TradeOpts.SearchLeague, "tmp") && TradeGlobals.Get("TempLeagueIsRunning") = 0) {
		If (InStr(TradeOpts.SearchLeague, "standard")) {
			TradeOpts.SearchLeague := "standard"
		}
		Else {
			TradeOpts.SearchLeague := "hardcore"
		}		
	}
}

; ------------------ READ INI AND CHECK IF VARIABLES ARE SET ------------------ 
TradeFunc_ReadIniValue(iniFilePath, Section = "General", IniKey="", DefaultValue = "")
{
	IniRead, OutputVar, %iniFilePath%, %Section%, %IniKey%
	If (!OutputVar | RegExMatch(OutputVar, "^ERROR$")) { 
		OutputVar := DefaultValue
        ; Somehow reading some ini-values is not working with IniRead
        ; Fallback for these cases via FileReadLine 
		lastSection := ""        
		Loop {
			FileReadLine, line, %iniFilePath%, %A_Index%
			If ErrorLevel
				break
			
			l := StrLen(IniKey)
			NewStr := SubStr(Trim(line), 1 , l)
			RegExMatch(line, "i)\[(.*)\]", match)
			If (not InStr(line, ";") and match) {
				lastSection := match1
			}
			
			If (NewStr = IniKey and lastSection = Section) {
				RegExMatch(line, "= *(.*)", value)
				If (StrLen(value1) = 0) {
					OutputVar := DefaultValue                    
				}
				Else {
					OutputVar := value1
				}              
                ;MsgBox % "`n`n`n`n" lastSection ": " IniKey  " = " OutputVar 
			}
		}
	}   
	Return OutputVar
}

TradeFunc_WriteIniValue(Val, TradeConfigPath, Section_, Key)
{
	IniWrite, %Val%, %TradeConfigPath%, %Section_%, %Key%
}

; ------------------ ASSIGN HOTKEY AND HANDLE ERRORS ------------------ 
TradeFunc_AssignHotkey(Key, Label){
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
TradeFunc_GetLeagues(){	
     ;Loop over league info and get league names    
	leagues := []
	For key, val in LeaguesData {
		If (!val.event)  {
			If (val.id = "Standard") {
				leagues["standard"] := val.id			
			}
			Else If (val.id = "Hardcore") {
				leagues["hardcore"] := val.id			
			}
			Else If (InStr(val.id, "Hardcore")) {
				leagues["tmphardcore"] := val.id			
			}
			Else {
				leagues["tmpstandard"] := val.id			
			}
		}
	}
	Return leagues
}

; ------------------ CHECK IF A TEMP-LEAGUE IS ACTIVE ------------------ 
TradeFunc_CheckIfTempLeagueIsRunning() {
	tempLeagueDates := TradeFunc_GetTempLeagueDates()
	
	If (!tempLeagueDates) {
		If (InStr(TradeOpts.SearchLeague, "standard")) {
			defaultLeague := "standard"
		}
		Else {
			defaultLeague := "hardcore"
		}
		Return 0
	}

	UTCTimestamp := TradeFunc_GetTimestampUTC()
	UTCFormatStr := "yyyy-MM-dd'T'HH:mm:ss'Z'"
	FormatTime, TimeStr, %UTCTimestamp%, %UTCFormatStr%
	
	timeDiffStart := TradeFunc_DateParse(TimeStr) - TradeFunc_DateParse(tempLeagueDates["start"])
	timeDiffEnd   := TradeFunc_DateParse(TimeStr) - TradeFunc_DateParse(tempLeagueDates["end"])
	
	If (timeDiffStart > 0 && timeDiffEnd < 0) {
        ; Current datetime is between temp league start and end date
		defaultLeague := "tmpstandard"
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

TradeFunc_GetTempLeagueDates(){
	tempLeagueDates := []
	For key, val in LeaguesData {
		If (val.endAt and val.startAt and not val.event) {
			tempLeagueDates["start"] := val.startAt
			tempLeagueDates["end"] := val.endAt
			Return tempLeagueDates
		}
	}
	Return 0
}


;----------------------- Handle available script updates ---------------------------------------
TradeFunc_ScriptUpdate() {
	repo := TradeGlobals.Get("GithubRepo")
	user := TradeGlobals.Get("GithubUser")
	ReleaseVersion := TradeGlobals.Get("ReleaseVersion")
	ShowUpdateNotification := TradeOpts.ShowUpdateNotifications
	SplashScreenTitle := "PoE-TradeMacro"
	PoEScripts_Update(user, repo, ReleaseVersion, ShowUpdateNotification, SplashScreenTitle)
}

;----------------------- Trade Settings UI (added onto ItemInfos Settings UI) ---------------------------------------

CreateTradeSettingsUI() 
{
	Global
	
	GuiAddGroupBox("", "x541 y-50 w2 h1000")
	
    ; General 
	
	GuiAddGroupBox("[TradeMacro] General", "x547 y15 w260 h306")
	
    ; Note: window handles (hwnd) are only needed If a UI tooltip should be attached.
	
	GuiAddText("Show Items:", "x557 yp+28 w160 h20 0x0100", "LblShowItemResults", "LblShowItemResultsH")
	AddToolTip(LblShowItemResultsH, "Number of items displayed in search results.")
	GuiAddEdit(TradeOpts.ShowItemResults, "x+10 yp-2 w50 h20", "ShowItemResults", "ShowItemResultsH")
	
	GuiAddCheckbox("Show Account Name", "x557 yp+24 w210 h30", TradeOpts.ShowAccountName, "ShowAccountName", "ShowAccountNameH")
	AddToolTip(ShowAccountNameH, "Show sellers account name in search results tooltip.")
	
	GuiAddCheckbox("Show Update Notifications", "x557 yp+30 w210 h30", TradeOpts.ShowUpdateNotifications, "ShowUpdateNotifications", "ShowUpdateNotificationsH")
	AddToolTip(ShowUpdateNotificationsH, "Notifies you when there's a new stable`n release available.")
	
	GuiAddCheckbox("Open browser Win10 fix", "x557 yp+30 w210 h30", TradeOpts.OpenWithDefaultWin10Fix, "OpenWithDefaultWin10Fix", "OpenWithDefaultWin10FixH")
	AddToolTip(OpenWithDefaultWin10FixH, " If your PC always asks you what program to use to open`n the wiki-link, enable this to let ahk find your default`nprogram from the registry.")
	
	GuiAddText("Browser Path:", "x557 yp+38 w70 h20 0x0100", "LblBrowserPath", "LblBrowserPathH")
	AddToolTip(LblBrowserPathH, "Optional: Set the path to the browser (.exe) to open Urls with.")
	GuiAddEdit(TradeOpts.BrowserPath, "x+10 yp-2 w150 h20", "BrowserPath", "BrowserPathH")
	
	GuiAddCheckbox("Enable ""Url shortcuts"" without item hover.", "x557 yp+30 w220 h30", TradeOpts.OpenUrlsOnEmptyItem, "OpenUrlsOnEmptyItem", "OpenUrlsOnEmptyItemH")
	AddToolTip(OpenUrlsOnEmptyItemH, "This enables the ctrl+q and ctrl+w shortcuts`neven without hovering over an item.`nBe careful!")
	
	GuiAddCheckbox("Debug Output", "x557 yp+30 w100 h30 cRed", TradeOpts.Debug, "Debug", "DebugH")
	AddToolTip(DebugH, "Don't use this unless you're developing!")
	
	GuiAddCheckbox("Download Data Files on start", "x557 yp+30 w200 h30", TradeOpts.DownloadDataFiles, "DownloadDataFiles", "DownloadDataFilesH")
	AddToolTip(DownloadDataFilesH, "Downloads all data files (mods, enchantments etc) on every script start.`nBy disabling this, these files are only updated with new releases.`nDisabling is not recommended.")
	
	GuiAddCheckbox("Delete cookies on start", "x557 yp+30 w200 h30", TradeOpts.DeleteCookies, "DeleteCookies", "DeleteCookiesH")
	AddToolTip(DeleteCookiesH, "Delete Internet Explorer's poe.trade cookies.")
	
    ; Hotkeys
	
	GuiAddGroupBox("[TradeMacro] Hotkeys", "x547 yp+65 w260 h235")
	
	GuiAddText("Price Check Hotkey:", "x557 yp+28 w160 h20 0x0100", "LblPriceCheckHotKey", "LblPriceCheckHotKeyH")
	AddToolTip(LblPriceCheckHotKeyH, "Check item prices.")
	GuiAddEdit(TradeOpts.PriceCheckHotKey, "x+10 yp-2 w50 h20", "PriceCheckHotKey", "PriceCheckHotKeyH")
	AddToolTip(PriceCheckHotKeyH, "Default: ctrl + d")
	GuiAddCheckbox("", "x+5 yp-6 w30 h30", TradeOpts.PriceCheckEnabled, "PriceCheckEnabled", "PriceCheckEnabledH")
	AddToolTip(PriceCheckEnabledH, "Enable Hotkey.")
	
	GuiAddText("Advanced Price Check Hotkey:", "x557 yp+38 w160 h20 0x0100", "LblAdvancedPriceCheckHotKey", "LblAdvancedPriceCheckHotKeyH")
	AddToolTip(LblAdvancedPriceCheckHotKeyH, "Select mods to include in your search`nbefore checking prices.")
	GuiAddEdit(TradeOpts.AdvancedPriceCheckHotKey, "x+10 yp-2 w50 h20", "AdvancedPriceCheckHotKey", "AdvancedPriceCheckHotKeyH")
	AddToolTip(AdvancedPriceCheckHotKeyH, "Default: ctrl + alt + d")
	GuiAddCheckbox("", "x+5 yp-6 w30 h30", TradeOpts.AdvancedPriceCheckEnabled, "AdvancedPriceCheckEnabled", "AdvancedPriceCheckEnabledH")
	AddToolTip(AdvancedPriceCheckEnabledH, "Enable Hotkey.")
	
	GuiAddText("Custom Input Search:", "x557 yp+38 w160 h20 0x0100", "LblCustomInputSearchHotkey", "LblCustomInputSearchHotkeyH")
	AddToolTip(LblCustomInputSearchHotkeyH, "Custom text input search.")
	GuiAddEdit(TradeOpts.CustomInputSearchHotkey, "x+10 yp-2 w50 h20", "CustomInputSearchHotkey", "CustomInputSearchHotkeyH")
	AddToolTip(CustomInputSearchHotkeyH, "Default: ctrl + i")
	GuiAddCheckbox("", "x+5 yp-6 w30 h30", TradeOpts.CustomInputSearchEnabled, "CustomInputSearchEnabled", "CustomInputSearchEnabledH")
	AddToolTip(CustomInputSearchEnabledH, "Enable Hotkey.")
	
	GuiAddText("Open Search on poe.trade:", "x557 yp+38 w160 h20 0x0100", "LblOpenSearchOnPoeTradeHotKey", "LblOpenSearchOnPoeTradeHotKeyH")
	AddToolTip(LblOpenSearchOnPoeTradeHotKeyH, "Open your search on poe.trade instead of showing`na tooltip with results.")
	GuiAddEdit(TradeOpts.OpenSearchOnPoeTradeHotKey, "x+10 yp-2 w50 h20", "OpenSearchOnPoeTradeHotKey", "OpenSearchOnPoeTradeHotKeyH")
	AddToolTip(OpenSearchOnPoeTradeHotKeyH, "Default: ctrl + q")
	GuiAddCheckbox("", "x+5 yp-6 w30 h30", TradeOpts.OpenSearchOnPoeTradeEnabled, "OpenSearchOnPoeTradeEnabled", "OpenSearchOnPoeTradeEnabledH")
	AddToolTip(OpenSearchOnPoeTradeEnabledH, "Enable Hotkey.")
	
	GuiAddText("Open Item on Wiki:", "x557 yp+38 w160 h20 0x0100", "LblOpenWikiHotkey", "LblOpenWikiHotkeyH")
	AddToolTip(LblOpenWikiHotKeyH, "Open your items page on the PoE-Wiki.")
	GuiAddEdit(TradeOpts.OpenWikiHotKey, "x+10 yp-2 w50 h20", "OpenWikiHotKey", "OpenWikiHotKeyH")
	AddToolTip(OpenWikiHotKeyH, "Default: ctrl + w")
	GuiAddCheckbox("", "x+5 yp-6 w30 h30", TradeOpts.OpenWikiEnabled, "OpenWikiEnabled", "OpenWikiEnabledH")
	AddToolTip(OpenWikiEnabledH, "Enable Hotkey.")
	
	GuiAddText("Show Item Age:", "x557 yp+38 w160 h20 0x0100", "LblShowItemAgeHotkey", "LblShowItemAgeHotkeyH")
	AddToolTip(LblShowItemAgeHotkeyH, "Checks your item's age.")
	GuiAddEdit(TradeOpts.ShowItemAgeHotkey, "x+10 yp-2 w50 h20", "ShowItemAgeHotkey", "ShowItemAgeHotkeyH")
	AddToolTip(ShowItemAgeHotkeyH, "Default: ctrl + a")
	GuiAddCheckbox("", "x+5 yp-6 w30 h30", TradeOpts.ShowItemAgeEnabled, "ShowItemAgeEnabled", "ShowItemAgeEnabledH")
	AddToolTip(ShowItemAgeEnabledH, "Enable Hotkey.")
	
	Gui, Add, Link, x557 yp+32 w160 h20 cBlue, <a href="http://www.autohotkey.com/docs/Hotkeys.htm">Hotkey Options</a>
	
    ; Search
	
	GuiAddGroupBox("[TradeMacro] Search", "x817 y15 w260 h555")
	
	GuiAddText("League:", "x827 yp+28 w100 h20 0x0100", "LblSearchLeague", "LblSearchLeagueH")
	AddToolTip(LblSearchLeagueH, "Defaults to ""standard"" or ""tmpstandard"" If there is a`nTemp-League active at the time of script execution.`n`n""tmpstandard"" and ""tmphardcore"" are automatically replaced`nwith their permanent counterparts If no Temp-League is active.")
	GuiAddDropDownList("tmpstandard|tmphardcore|standard|hardcore", "x+10 yp-2", TradeOpts.SearchLeague, "SearchLeague", "SearchLeagueH")
	
	GuiAddText("Account Name:", "x827 yp+32 w100 h20 0x0100", "LblAccountName", "LblAccountNameH")
	AddToolTip(LblAccountNameH, "Your Account Name used to check your item's age.")
	GuiAddEdit(TradeOpts.AccountName, "x+10 yp-2 w120 h20", "AccountName", "AccountNameH")
	
	GuiAddText("Gem Level:", "x827 yp+32 w170 h20 0x0100", "LblGemLevel", "LblGemLevelH")
	AddToolTip(LblGemLevelH, "Gem level is ignored in the search unless it's equal`nor higher than this value.`n`nSet to something like 30 to completely ignore the level.")
	GuiAddEdit(TradeOpts.GemLevel, "x+10 yp-2 w50 h20", "GemLevel", "GemLevelH")
	
	GuiAddText("Gem Level Range:", "x827 yp+32 w170 h20 0x0100", "LblGemLevelRange", "LblGemLevelRangeH")
	AddToolTip(LblGemLevelRangeH, "Uses GemLevel option to create a range around it.`n `nSetting it to 0 ignores this option.")
	GuiAddEdit(TradeOpts.GemLevelRange, "x+10 yp-2 w50 h20", "GemLevelRange", "GemLevelRangeH")
	
	GuiAddText("Gem Quality Range:", "x827 yp+32 w170 h20 0x0100", "LblGemQualityRange", "LblGemQualityRangeH")
	AddToolTip(LblGemQualityRangeH, "Use this to set a range to quality Gem searches. For example a range of 1`n searches 14% - 16% when you have a 15% Quality Gem.`nSetting it to 0 (default) uses your Gems quality as min_quality`nwithout max_quality in your search.")
	GuiAddEdit(TradeOpts.GemQualityRange, "x+10 yp-2 w50 h20", "GemQualityRange", "GemQualityRangeH")
	
	GuiAddText("Mod Range Modifier (%):", "x827 yp+32 w130 h20 0x0100", "LblAdvancedSearchModValueRange", "LblAdvancedSearchModValueRangeH")
	AddToolTip(LblAdvancedSearchModValueRangeH, "Advanced search lets you select the items mods to include in your`nsearch and lets you set their min/max values.`n`nThese min/max values are pre-filled, to calculate them we look at`nthe difference between the mods theoretical max and min value and`ntreat it as 100%.`n`nWe then use this modifier as a percentage of this differences to`ncreate a range (min/max value) to search in. ")
	GuiAddEdit(TradeOpts.AdvancedSearchModValueRangeMin, "x+10 yp-2 w35 h20", "AdvancedSearchModValueRangeMin", "AdvancedSearchModValueRangeMinH")
	GuiAddText(" -", "x+5 yp+2 w10 h20 0x0100", "LblAdvancedSearchModValueRangeSpacer", "LblAdvancedSearchModValueRangeSpacerH")
	GuiAddEdit(TradeOpts.AdvancedSearchModValueRangeMax, "x+5 yp-2 w35 h20", "AdvancedSearchModValueRangeMax", "AdvancedSearchModValueRangeMaxH")
	
	GuiAddText("Corrupted:", "x827 yp+32 w100 h20 0x0100", "LblCorrupted", "LblCorruptedH")
	AddToolTip(LblCorruptedH, "Default = search results have the same corrupted state as the checked item.`nUse this option to override that and always search as selected.")
	GuiAddDropDownList("Either|Yes|No", "x+10 yp-2 w52", TradeOpts.Corrupted, "Corrupted", "CorruptedH")
	GuiAddCheckbox("Override", "x+10 yp+2 0x0100", TradeOpts.CorruptedOverride, "CorruptedOverride", "CorruptedOverrideH", "TradeSettingsUI_ChkCorruptedOverride")
	
	GoSub, TradeSettingsUI_ChkCorruptedOverride
	
	CurrencyList := ""
	CurrencyTemp := TradeGlobals.Get("CurrencyIDs")	
	For currName, currID in CurrencyTemp {   
		CurrencyList .= "|" . currName
	}
	GuiAddText("Currency Search:", "x827 yp+30 w100 h20 0x0100", "LblCurrencySearchHave", "LblCurrencySearchHaveH")
	AddToolTip(LblCurrencySearchHaveH, "This settings sets the currency that you`nwant to use as ""have"" for the currency search.")
	GuiAddDropDownList(CurrencyList, "x+10 yp-2", TradeOpts.CurrencySearchHave, "CurrencySearchHave", "CurrencySearchHaveH")
	
	GuiAddCheckbox("Online only", "x827 yp+22 w210 h35 0x0100", TradeOpts.OnlineOnly, "OnlineOnly", "OnlineOnlyH")
	
	GuiAddCheckbox("Buyout only (Search on poe.trade)", "x827 yp+30 w210 h35 0x0100", TradeOpts.BuyoutOnly, "BuyoutOnly", "BuyoutOnlyH")
	AddToolTip(BuyoutOnlyH, "This option only takes affect when opening the search on poe.trade.")
	
	GuiAddCheckbox("Remove multiple Listings from same Account", "x827 yp+28 w230 h40", TradeOpts.RemoveMultipleListingsFromSameAccount, "RemoveMultipleListingsFromSameAccount", "RemoveMultipleListingsFromSameAccountH")
	AddToolTip(RemoveMultipleListingsFromSameAccountH, "Removes multiple listings from the same account from`nyour search results (to combat market manipulators).`n`nThe removed items are also removed from the average and`nmedian price calculations.")
	
	GuiAddCheckbox("Pre-Fill Min-Values", "x827 yp+30 w230 h40", TradeOpts.PrefillMinValue, "PrefillMinValue", "PrefillMinValueH")
	AddToolTip(PrefillMinValueH, "Automatically fill the min-values in the advanced search GUI.")
	GuiAddCheckbox("Pre-Fill Max-Values", "x827 yp+30 w230 h40", TradeOpts.PrefillMinValue, "PrefillMaxValue", "PrefillMaxValueH")
	AddToolTip(PrefillMaxValueH, "Automatically fill the max-values in the advanced search GUI.")
	
	GuiAddCheckbox("Force max links (certain corrupted items)", "x827 yp+30 w230 h40", TradeOpts.ForceMaxLinks, "ForceMaxLinks", "ForceMaxLinksH")
	AddToolTip(ForceMaxLinksH, "Corrupted 3/4 max-socket unique items always use`nmax links if your item is fully linked.")
	
	GuiAddCheckbox("Alternative currency search", "x827 yp+30 w230 h40", TradeOpts.AlternativeCurrencySearch, "AlternativeCurrencySearch", "AlternativeCurrencySearchH")
	AddToolTip(AlternativeCurrencySearchH, "Shows historical data of the searched currency.")
	
	Gui, Add, Link, x827 yp+43 w230 cBlue, <a href="https://github.com/POE-TradeMacro/POE-TradeMacro/wiki/Options">Options Wiki-Page</a>
	
	GuiAddText("Mouse over settings to see what these settings do exactly.", "x827 y585 w250 h30")
	
	GuiAddButton("[Trade] Defaults", "x822 y640 w90 h23", "TradeSettingsUI_BtnDefaults")
	GuiAddButton("[Trade] OK", "Default x+5 y640 w75 h23", "TradeSettingsUI_BtnOK")
	GuiAddButton("[Trade] Cancel", "x+5 y640 w80 h23", "TradeSettingsUI_BtnCancel")
	
	GuiAddText("Use these Buttons to change TradeMacro Settings only.", "x827 y+10 w250 h50 cRed")
	GuiAddText("Use these Buttons to change Item Info Settings only.", "x287 yp+0 w250 h50 cRed")
}

UpdateTradeSettingsUI()
{    
	Global
	
	GuiControl,, ShowItemResults, % TradeOpts.ShowItemResults
	GuiControl,, ShowAccountName, % TradeOpts.ShowAccountName
	GuiControl,, BrowserPath, % TradeOpts.BrowserPath
	GuiControl,, ShowUpdateNotifications, % TradeOpts.ShowUpdateNotifications
	GuiControl,, OpenWithDefaultWin10Fix, % TradeOpts.OpenWithDefaultWin10Fix
	GuiControl,, BrowserPath, % TradeOpts.BrowserPath
	GuiControl,, Debug, % TradeOpts.Debug
	
	GuiControl,, PriceCheckHotKey, % TradeOpts.PriceCheckHotKey
	GuiControl,, AdvancedPriceCheckHotKey, % TradeOpts.AdvancedPriceCheckHotKey
	GuiControl,, CustomInputSearchHotkey, % TradeOpts.CustomInputSearchHotkey
	GuiControl,, OpenSearchOnPoeTradeHotKey, % TradeOpts.OpenSearchOnPoeTradeHotKey
	GuiControl,, OpenWikiHotKey, % TradeOpts.OpenWikiHotKey
	GuiControl,, ShowItemAgeHotKey, % TradeOpts.ShowItemAgeHotKey
	
	GuiControl,, SearchLeague, % TradeOpts.SearchLeague
	GuiControl,, AccountName, % TradeOpts.AccountName
	GuiControl,, GemLevel, % TradeOpts.GemLevel
	GuiControl,, GemQualityRange, % TradeOpts.GemQualityRange
	GuiControl,, AdvancedSearchModValueRangeMin, % TradeOpts.AdvancedSearchModValueRangeMin
	GuiControl,, AdvancedSearchModValueRangeMax, % TradeOpts.AdvancedSearchModValueRangeMax
	GuiControl,, CurrencySearchHave, % TradeOpts.CurrencySearchHave
	GuiControl,, Corrupted, % TradeOpts.Corrupted
	GuiControl,, OnlineOnly, % TradeOpts.OnlineOnly
	GuiControl,, PrefillMinValue, % TradeOpts.PrefillMinValue
	GuiControl,, PrefillMaxValue, % TradeOpts.PrefillMaxValue
	GuiControl,, RemoveMultipleListingsFromSameAccount, % TradeOpts.RemoveMultipleListingsFromSameAccount
}

TradeFunc_ReadCraftingBases(){
	bases := []
	Loop, Read, %A_ScriptDir%\trade_data\crafting_bases.txt
	{
		bases.push(A_LoopReadLine)
	}
	Return bases    
}

TradeFunc_ReadEnchantments(){
	enchantments := {}
	enchantments.boots   := []
	enchantments.helmet  := []
	enchantments.gloves  := []
	
	Loop, Read, %A_ScriptDir%\trade_data\boot_enchantment_mods.txt
	{
		If (StrLen(Trim(A_LoopReadLine)) > 0) {        
			enchantments.boots.push(A_LoopReadLine)            
		}
	}
	Loop, Read, %A_ScriptDir%\trade_data\helmet_enchantment_mods.txt
	{
		If (StrLen(Trim(A_LoopReadLine)) > 0) {
			enchantments.helmet.push(A_LoopReadLine)
		}
	}
	Loop, Read, %A_ScriptDir%\trade_data\glove_enchantment_mods.txt
	{
		If (StrLen(Trim(A_LoopReadLine)) > 0) {
			enchantments.gloves.push(A_LoopReadLine)
		}
	}
	Return enchantments    
}

TradeFunc_ReadCorruptions(){
	mods := []    
	
	Loop, read, %A_ScriptDir%\trade_data\item_corrupted_mods.txt
	{
		If (StrLen(Trim(A_LoopReadLine)) > 0) {        
			mods.push(A_LoopReadLine)            
		}
	}
	Return mods
}

TradeFunc_CheckBrowserPath(path, showMsg){
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

TradeFunc_DownloadDataFiles() {
	; disabled while using debug mode 	
	owner := TradeGlobals.Get("GithubUser", "POE-TradeMacro")
	repo  := TradeGlobals.Get("GithubRepo", "POE-TradeMacro")
	url   := "https://raw.githubusercontent.com/" . owner . "/" . repo . "/master/trade_data/"
	dir = %A_ScriptDir%\trade_data
	bakDir = %A_ScriptDir%\trade_data\old_data_files
	files := ["boot_enchantment_mods.txt","crafting_bases.txt","glove_enchantment_mods.txt","helmet_enchantment_mods.txt","item_corrupted_mods.txt","mods.json","uniques.json"]		
	
	; create .bak files and download (overwrite) data files
	; if downlaoded file exists move .bak-file to backup folder, otherwise restore .bak-file 
	Loop % files.Length() {
		file := files[A_Index]
		filePath = %dir%\%file%
		FileCopy, %filePath%, %filePath%.bak
		UrlDownloadToFile, %url%%file%, %filePath%
		
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

TradeFunc_ReadCookieData() {
	SplashTextOn, 450, 40, PoE-TradeMacro, Reading user-agent and cookies from poe.trade, this can take`nup a few seconds if your Internet Explorer doesn't have the cookies cached.
	
	If (TradeOpts.DeleteCookies) {
		TradeFunc_DeleteCookies()
	}
	
	; compile the c# script reading the user-agent and cookies
	DotNetFrameworkInstallation := TradeFunc_GetLatestDotNetInstallation()
	DotNetFrameworkPath := DotNetFrameworkInstallation.Path
	CompilerExe := "csc.exe"
	
	If (TradeOpts.Debug) {
		RunWait %comspec% /c ""%DotNetFrameworkPath%%CompilerExe%" /target:exe  /out:"%A_ScriptDir%\temp\getCookieData.exe" "%A_ScriptDir%\Lib\getCookieData.cs""
	}
	Else {
		RunWait %comspec% /c ""%DotNetFrameworkPath%%CompilerExe%" /target:exe  /out:"%A_ScriptDir%\temp\getCookieData.exe" "%A_ScriptDir%\Lib\getCookieData.cs"", , Hide
	}
	
	Try {		
		If (!FileExist(A_ScriptDir "\temp\getCookieData.exe")) {
			CompiledExeNotFound := 1			
			If (DotNetFrameworkInstallation.Major < 4) {
				WrongNetFrameworkVersion := 1
			}
		}
		Else {
			RunWait %A_ScriptDir%\temp\getCookieData.exe, , Hide		
		}
	} Catch e {
		CompiledExeNotFound := 1
	}		
	
	; read user-agent and cookies
	ErrorLevel := 0
	If (FileExist(A_ScriptDir "\temp\cookie_data.txt")) {
		FileRead, cookieFile, %A_ScriptDir%\temp\cookie_data.txt
		Loop, parse, cookieFile, `n`r
		{
			RegExMatch(A_LoopField, "i)(.*)\s?=", key)
			RegExMatch(A_LoopField, "i)=\s?(.*)", value)

			If (InStr(key1, "useragent")) {
				TradeGlobals.Set("UserAgent", Trim(value1))
			}
			Else If (InStr(key1, "cfduid")) {		   
				TradeGlobals.Set("cfduid", Trim(value1))
			} 
			Else If (InStr(key1, "cf_clearance")) {
				TradeGlobals.Set("cfClearance", Trim(value1))
			}		
		}
		
		If (StrLen(TradeGlobals.Get("UserAgent")) < 1) {
			ErrorLevel := 1
		}
		If (StrLen(TradeGlobals.Get("cfduid")) < 1) {
			ErrorLevel := 1
		}
		If (StrLen(TradeGlobals.Get("cfClearance")) < 1) {
			ErrorLevel := 1
		}	
	}
	Else {
		CookieFileNotFound := 1
	}
	
	If (!ErrorLevel) { 
		If (!TradeFunc_TestCloudflareBypass("http://poe.trade", TradeGlobals.Get("UserAgent"), TradeGlobals.Get("cfduid"), TradeGlobals.Get("cfClearance"))) {
			BypassFailed := 1
		}
	}

	SplashTextOff		
	If (ErrorLevel or BypassFailed or CompiledExeNotFound) {
		; collect debug information
		CookieFile := (!CookieFileNotFound) ? "Cookie file found." : "Cookie file not found."
		Cookies := (!ErrorLevel) ? "Retrieving cookies successful." : "Retrieving cookies failed."
		OSInfo := TradeFunc_GetOSInfo()
		Compilation := (!CompiledExeNotFound) ? "Compiling 'getCookieData' script successful." : "Compiling 'getCookieData' script failed."
		NetFramework := "Net Framework used for compiling: v" DotNetFrameworkInstallation.Number 
		RegRead, IEVersion, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Internet Explorer, svcVersion
		If (!IEVersion) {
			RegRead, IEVersion, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Internet Explorer\Version Vector, IE
		}
		IE := "Internet Explorer: v" IEVersion
		
		WinSet, AlwaysOnTop, Off, PoE-TradeMacro
		
		If (CompiledExeNotFound) {			
			Gui, CookieWindow:Add, Text, cRed, <ScriptDirectory\temp\getCookieData.exe> not found!
			Gui, CookieWindow:Add, Text, , - It seems compiling and moving the .exe file failed.
			If (WrongNetFrameworkVersion) {
				Gui, CookieWindow:Add, Text, , `n- Net Framework 4 is required (for now) but it seems you don't have it.
				Gui, CookieWindow:Add, Link, cBlue, <a href="https://www.microsoft.com/en-us/download/details.aspx?id=17851">Download it here</a> 
			}
		}
		Else If (BypassFailed) {
			Gui, CookieWindow:Add, Text, cRed, Bypassing poe.trades CloudFlare protection failed!
			Gui, CookieWindow:Add, Text, , - Cookies and user-agent were retrieved.`n- Lowered/disabled Internet Explorer security settings can cause this to fail.
			cookiesDeleted := (TradeOpts.DeleteCookies) ? "Cookies were deleted on script start." : ""
			Gui, CookieWindow:Add, Text, , - %cookiesDeleted% Please try again or test the compiled`n  script <ScriptDirectory\PoE-TradeMacro.exe>.`n- Make sure that you're not using any proxy server.				
		}
		Else {
			Gui, CookieWindow:Add, Text, cRed, Reading Cookie data failed!
			If (CookieFileNotFound) {
				Gui, CookieWindow:Add, Text, , - File <ScriptDirectory\temp\cookie_data.txt> could not be found.
			}
			Else {
				cookiesDeleted := (TradeOpts.DeleteCookies) ? "Cookies were deleted on script start." : ""
				Gui, CookieWindow:Add, Text, , - The contents of <ScriptDirectory\temp\cookie_data.txt> seem to be invalid/incomplete. `n- %cookiesDeleted% Please try again or test the compiled`n  script <ScriptDirectory\PoE-TradeMacro.exe>.	
			}
		}
		
		Gui, CookieWindow:Add, Link, cBlue, Report on <a href="https://github.com/PoE-TradeMacro/POE-TradeMacro/issues/149#issuecomment-268639184">Github</a>, <a href="https://discord.gg/taKZqWw">Discord</a>, <a href="https://www.pathofexile.com/forum/view-thread/1757730/">the forum</a>.
		Gui, CookieWindow:Add, Text, , Please also provide this information in your report.
		Gui, CookieWindow:Add, Edit, r5 ReadOnly w430, %CookieFile% `n%Cookies% `n%OSInfo% `n%Compilation% `n%NetFramework% `n%IE%
		
		Gui, CookieWindow:Add, Button, y+10 gOpenCookieFile, Open cookie file
		Gui, CookieWindow:Add, Button, yp+0 x+10 gCloseCookieWindow, Close
		Gui, CookieWindow:Show, w450 xCenter yCenter, Notice
		ControlFocus, Close, Notice
		WinWaitClose, Notice
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

TradeFunc_TestCloudflareBypass(Url, UserAgent, cfduid, cfClearance) {
	ComObjError(0)
	Encoding := "utf-8"
	HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	
	HttpObj.Open("GET",Url)
	HttpObj.SetRequestHeader("User-Agent", UserAgent)
	HttpObj.SetRequestHeader("Cookie","__cfduid=" cfduid "; cf_clearance=" cfClearance)
	HttpObj.Send()
	HttpObj.WaitForResponse()
	html := HttpObj.ResponseText
	
	If Encoding {
		oADO          := ComObjCreate("adodb.stream")
		oADO.Type     := 1
		oADO.Mode     := 3
		oADO.Open()
		oADO.Write( HttpObj.ResponseBody )
		oADO.Position := 0
		oADO.Type     := 2
		oADO.Charset  := Encoding
		html := oADO.ReadText()
		oADO.Close()
	}
	
	If A_LastError
		MsgBox % "Error while testing CloudFlare bypass.`n" A_LastError
	
	If (InStr(html, "Path of Exile")) {
		Return 1
	}
	Else {
		Return 0
	}
}

TradeFunc_DeleteCookies() {
	appData := RegExReplace(A_AppData, "i)Roaming", "")
	; Win XP, Win 7, Win8/10
	paths := [appData "Local Settings\Temporary Internet Files", appData "Roaming\Microsoft\Windows\Cookies", appData "Local\Microsoft\Windows\INetCookies"]

	For key, path in paths {
		If (FileExist(path)) {
			Loop Files, %path%\*.txt, R 
			{ 
				FileRead, contents, %A_LoopFileFullPath%
				RegExMatch(contents, "i)poe\.trade", match)
				If (match) {
					FileDelete, %A_LoopFileFullPath%
				}			
			}		
		}
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
	SplashTextOn, , 20, PoE-TradeMacro, Initializing script...
}
TradeFunc_StopSplashScreen() {
	SplashTextOff 
	
	If(TradeOpts.Debug) {
		MsgBox % "Debug mode enabled! Disable in settings-menu unless you're developing!"
		Class_Console("console",0,335,600,900,,,,9)
		console.show()
	}    
	
    ; Let timer run until SettingsUIWidth is set and overwrite some options.
	SetTimer, OverwriteSettingsWidthTimer, 500
	SetTimer, OverwriteSettingsNameTimer, 500
	GoSub, ReadPoeNinjaCurrencyData
}

