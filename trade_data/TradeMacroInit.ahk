; TradeMacro Add-on to POE-ItemInfo
; IGN: Eruyome, ManicCompression

#Include, %A_ScriptDir%/lib/JSON.ahk
#Include, %A_ScriptDir%/lib/AssociatedProgram.ahk
#Include, %A_ScriptDir%/trade_data/uniqueData.ahk
#Include, %A_ScriptDir%/trade_data/Version.txt

TradeMsgWrongAHKVersion := "AutoHotkey v" . TradeAHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < TradeAHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % TradeMsgWrongAHKVersion
    ExitApp
}

Menu, Tray, Icon, %A_ScriptDir%\trade_data\poe-trade-bl.ico

StartSplashScreen()

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
        return result
    }
}

global TradeTempDir := A_ScriptDir . "\temp"
global TradeDataDir := A_ScriptDir . "\trade_data"
global SettingsWindowWidth := 845 
global SavedTradeSettings := false

FileRemoveDir, %TradeTempDir%, 1
FileCreateDir, %TradeTempDir%

class TradeUserOptions {
    ShowItemResults := 15		    ; Number of Items shown as search result; defaults to 15 if not set.
	ShowUpdateNotifications := 1	; 1 = show, 0 = don't show
    OpenWithDefaultWin10Fix := 0    ; If your PC asks you what programm to use to open the wiki-link, set this to 1 
    ShowAccountName := 1            ; Show also sellers account name in the results window
    BrowserPath :=                  ; Show also sellers account name in the results window
    
    Debug := 0      				; 
	
    PriceCheckHotKey := ^d        	; 
    AdvancedPriceCheckHotKey := ^!s ; 
    OpenWikiHotKey := ^w            ; 
    CustomInputSearch := ^i         ;     
    OpenSearchOnPoeTrade := ^q      ;     
    ShowItemAge := ^a               ;     
    
    PriceCheckEnabled :=1
    AdvancedPriceCheckEnabled :=1
    OpenWikiEnabled :=1
    CustomInputSearchEnabled :=1
    OpenSearchOnPoeTradeEnabled :=1
    ShowItemAgeEnabled :=1
    
    AccountName := ""               ; 
    SearchLeague := "tmpstandard"   ; Defaults to "standard" or "tmpstandard" if there is an active Temp-League at the time of script execution.
									; Possible values: 
									; 	"tmpstandard" (current SC Temp-League) 
									;	"tmphardcore" (current HC Temp-League) 
									;	"standard", 
									;   "hardcore"
    GemLevel := 16                  ; Gem level is ignored in the search unless it's equal or higher than this value
    GemQualityRange := 0            ; Use this to set a range to quality gems searches
	OnlineOnly := 1                 ; 1 = search online only; 0 = search offline, too.
	Corrupted := "Either"           ; 1 = yes; 0 = no; 2 = either, This setting gets ignored when you use the search on corrupted items.
	AdvancedSearchModValueRange := 20 ; 
    RemoveMultipleListingsFromSameAccount := 0 ;
    PrefillMinValue := 1            ;
    PrefillMaxValue := 1            ;
    CurrencySearchHave := "Chaos Orb" ;
    
	Expire := 3						; cache expire min
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

; Check if Temp-Leagues are active and set defaultLeague accordingly
TradeGlobals.Set("TempLeagueIsRunning", FunctionCheckIfTempLeagueIsRunning())
TradeGlobals.Set("DefaultLeague", (tempLeagueIsRunning > 0) ? "tmpstandard" : "standard")
TradeGlobals.Set("GithubUser", "POE-TradeMacro")
TradeGlobals.Set("GithubRepo", "POE-TradeMacro")
TradeGlobals.Set("ReleaseVersion", TradeReleaseVersion)
TradeGlobals.Set("SettingsUITitle", "PoE (Trade) Item Info Settings")

FunctionGetLatestRelease()
ReadTradeConfig()
Sleep, 100

TradeGlobals.Set("Leagues", FunctionGETLeagues())
TradeGlobals.Set("LeagueName", TradeGlobals.Get("Leagues")[TradeOpts.SearchLeague])
TradeGlobals.Set("VariableUniqueData", TradeUniqueData)
TradeGlobals.Set("ModsData", TradeModsData)
TradeGlobals.Set("CraftingData", ReadCraftingBases())
TradeGlobals.Set("EnchantmentData", ReadEnchantments())
TradeGlobals.Set("CorruptedModsData", ReadCorruptions())
TradeGlobals.Set("CurrencyIDs", object := {})

; get currency ids from currency.poe.trade
FunctionDoCurrencyRequest("", false, true)

CreateTradeSettingsUI()
StopSplashScreen()


ReadTradeConfig(TradeConfigPath="trade_config.ini")
{
    Global
    IfExist, %TradeConfigPath%
    {
        ; General 		
        TradeOpts.ShowItemResults := ReadIniValue(TradeConfigPath, "General", "ShowItemResults", TradeOpts.ShowItemResults)
		TradeOpts.ShowUpdateNotifications := ReadIniValue(TradeConfigPath, "General", "ShowUpdateNotifications", TradeOpts.ShowUpdateNotifications)
		TradeOpts.OpenWithDefaultWin10Fix := ReadIniValue(TradeConfigPath, "General", "OpenWithDefaultWin10Fix", TradeOpts.OpenWithDefaultWin10Fix)
		TradeOpts.ShowAccountName := ReadIniValue(TradeConfigPath, "General", "ShowAccountName", TradeOpts.ShowAccountName)
        
        ; Check if browser path is valid, delete ini-entry if not
        BrowserPath := ReadIniValue(TradeConfigPath, "General", "BrowserPath", TradeOpts.BrowserPath)
        If (CheckBrowserPath(BrowserPath, false)) {
            TradeOpts.BrowserPath := BrowserPath
        }		
        Else {
            WriteIniValue("", TradeConfigPath, "General", "BrowserPath")       
        }

        ; Debug        
        TradeOpts.Debug := ReadIniValue(TradeConfigPath, "Debug", "Debug", 0)
        
        ; Hotkeys        
        TradeOpts.PriceCheckHotKey := ReadIniValue(TradeConfigPath, "Hotkeys", "PriceCheckHotKey", TradeOpts.PriceCheckHotKey)
        TradeOpts.AdvancedPriceCheckHotKey := ReadIniValue(TradeConfigPath, "Hotkeys", "AdvancedPriceCheckHotKey", TradeOpts.AdvancedPriceCheckHotKey)
        TradeOpts.OpenWikiHotKey := ReadIniValue(TradeConfigPath, "Hotkeys", "OpenWiki", TradeOpts.OpenWikiHotKey)
        TradeOpts.CustomInputSearchHotKey := ReadIniValue(TradeConfigPath, "Hotkeys", "CustomInputSearchHotKey", TradeOpts.CustomInputSearchHotKey)
        TradeOpts.OpenSearchOnPoeTradeHotKey := ReadIniValue(TradeConfigPath, "Hotkeys", "OpenSearchOnPoeTradeHotKey", TradeOpts.OpenSearchOnPoeTradeHotKey)
        TradeOpts.ShowItemAgeHotKey := ReadIniValue(TradeConfigPath, "Hotkeys", "ShowItemAgeHotKey", TradeOpts.ShowItemAgeHotKey)
        
        TradeOpts.PriceCheckEnabled := ReadIniValue(TradeConfigPath, "HotkeyStates", "PriceCheckEnabled", TradeOpts.PriceCheckEnabled)        
        TradeOpts.AdvancedPriceCheckEnabled := ReadIniValue(TradeConfigPath, "HotkeyStates", "AdvancedPriceCheckEnabled", TradeOpts.AdvancedPriceCheckEnabled)        
        TradeOpts.OpenWikiEnabled := ReadIniValue(TradeConfigPath, "HotkeyStates", "OpenWikiEnabled", TradeOpts.OpenWikiEnabled)        
        TradeOpts.CustomInputSearchEnabled := ReadIniValue(TradeConfigPath, "HotkeyStates", "CustomInputSearchEnabled", TradeOpts.CustomInputSearchEnabled)        
        TradeOpts.OpenSearchOnPoeTradeEnabled := ReadIniValue(TradeConfigPath, "HotkeyStates", "OpenSearchOnPoeTradeEnabled", TradeOpts.OpenSearchOnPoeTradeEnabled)        
        TradeOpts.ShowItemAgeEnabled := ReadIniValue(TradeConfigPath, "HotkeyStates", "ShowItemAgeEnabled", TradeOpts.ShowItemAgeEnabled)        

		AssignAllHotkeys()
		
        ; Search     	
		TradeOpts.AccountName := ReadIniValue(TradeConfigPath, "Search", "AccountName", TradeOpts.AccountName)	
		TradeOpts.SearchLeague := ReadIniValue(TradeConfigPath, "Search", "SearchLeague", TradeGlobals.Get("DefaultLeague"))	
        temp := TradeOpts.SearchLeague
        StringLower, temp, temp
        SetLeagueIfSelectedIsInactive()	
        TradeOpts.SearchLeague := temp
        
		TradeOpts.GemLevel := ReadIniValue(TradeConfigPath, "Search", "GemLevel", TradeOpts.GemLevel)	
		TradeOpts.GemQualityRange := ReadIniValue(TradeConfigPath, "Search", "GemQualityRange", TradeOpts.GemQualityRange)	
		TradeOpts.OnlineOnly := ReadIniValue(TradeConfigPath, "Search", "OnlineOnly", TradeOpts.OnlineOnly)
        
		TradeOpts.Corrupted := ReadIniValue(TradeConfigPath, "Search", "Corrupted", TradeOpts.Corrupted)	
        temp := TradeOpts.Corrupted
        StringUpper, temp, temp, T
        TradeOpts.Corrupted := temp
        
		TradeOpts.AdvancedSearchModValueRange := ReadIniValue(TradeConfigPath, "Search", "AdvancedSearchModValueRange", TradeOpts.AdvancedSearchModValueRange)	
		TradeOpts.RemoveMultipleListingsFromSameAccount := ReadIniValue(TradeConfigPath, "Search", "RemoveMultipleListingsFromSameAccount", TradeOpts.RemoveMultipleListingsFromSameAccount)	
		TradeOpts.PrefillMinValue := ReadIniValue(TradeConfigPath, "Search", "PrefillMinValue", TradeOpts.PrefillMinValue)	
		TradeOpts.PrefillMaxValue := ReadIniValue(TradeConfigPath, "Search", "PrefillMaxValue", TradeOpts.PrefillMaxValue)	
		TradeOpts.CurrencySearchHave := ReadIniValue(TradeConfigPath, "Search", "CurrencySearchHave", TradeOpts.CurrencySearchHave)	
		
        ; Cache        
        TradeOpts.Expire := ReadIniValue(TradeConfigPath, "Cache", "Expire", TradeOpts.Expire)
    }
}

AssignAllHotkeys() {
    If (TradeOpts.PriceCheckEnabled) {
        AssignHotkey(TradeOpts.PriceCheckHotKey, "PriceCheck")
    }
    If (TradeOpts.AdvancedPriceCheckEnabled) {
        AssignHotkey(TradeOpts.AdvancedPriceCheckHotKey, "AdvancedPriceCheck")
    }
    If (TradeOpts.OpenWikiEnabled) {
        AssignHotkey(TradeOpts.OpenWikiHotKey, "OpenWiki")
    }
    If (TradeOpts.CustomInputSearchEnabled) {
        AssignHotkey(TradeOpts.CustomInputSearchHotKey, "CustomInputSearch")
    }
    If (TradeOpts.OpenSearchOnPoeTradeEnabled) {
        AssignHotkey(TradeOpts.OpenSearchOnPoeTradeHotKey, "OpenSearchOnPoeTrade")
    }
    If (TradeOpts.ShowItemAgeEnabled) {
        AssignHotkey(TradeOpts.ShowItemAgeHotKey, "ShowItemAge")
    }
}

WriteTradeConfig(TradeConfigPath="trade_config.ini")
{  
	Global
       
    ValidBrowserPath := CheckBrowserPath(BrowserPath, true)

    ; workaround for settings options not being assigned to TradeOpts    
    If (SavedTradeSettings) {
        TradeOpts.ShowItemResults := ShowItemResults
        TradeOpts.ShowUpdateNotifications := ShowUpdateNotifications
        TradeOpts.OpenWithDefaultWin10Fix := OpenWithDefaultWin10Fix
        TradeOpts.ShowAccountName := ShowAccountName
        
        If(ValidBrowserPath) {
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
        
        AssignAllHotkeys()
        
        TradeOpts.AccountName := AccountName
        TradeOpts.SearchLeague := SearchLeague
        SetLeagueIfSelectedIsInactive()        
        TradeGlobals.Set("LeagueName", TradeGlobals.Get("Leagues")[TradeOpts.SearchLeague])
        
        TradeOpts.GemLevel := GemLevel
        TradeOpts.GemQualityRange := GemQualityRange
        TradeOpts.OnlineOnly := OnlineOnly
        TradeOpts.Corrupted := Corrupted
        TradeOpts.AdvancedSearchModValueRange := AdvancedSearchModValueRange
        TradeOpts.RemoveMultipleListingsFromSameAccount := RemoveMultipleListingsFromSameAccount
        TradeOpts.PrefillMinValue := PrefillMinValue
        TradeOpts.PrefillMaxValue := PrefillMaxValue
        TradeOpts.CurrencySearchHave := CurrencySearchHave
    }        
    SavedTradeSettings := false
    
    ; General        
	WriteIniValue(TradeOpts.ShowItemResults, TradeConfigPath, "General", "ShowItemResults")
	WriteIniValue(TradeOpts.ShowUpdateNotifications, TradeConfigPath, "General", "ShowUpdateNotifications")
	WriteIniValue(TradeOpts.OpenWithDefaultWin10Fix, TradeConfigPath, "General", "OpenWithDefaultWin10Fix")
	WriteIniValue(TradeOpts.ShowAccountName, TradeConfigPath, "General", "ShowAccountName")   

    If(ValidBrowserPath) {
        WriteIniValue(TradeOpts.BrowserPath, TradeConfigPath, "General", "BrowserPath")           
    }
    Else {
        WriteIniValue("", TradeConfigPath, "General", "BrowserPath")           
    }

	; Debug	
	WriteIniValue(TradeOpts.Debug, TradeConfigPath, "Debug", "Debug")
	
	; Hotkeys	
	WriteIniValue(TradeOpts.PriceCheckHotKey, TradeConfigPath, "Hotkeys", "PriceCheckHotKey")
	WriteIniValue(TradeOpts.AdvancedPriceCheckHotKey, TradeConfigPath, "Hotkeys", "AdvancedPriceCheckHotKey")
	WriteIniValue(TradeOpts.OpenWikiHotKey, TradeConfigPath, "Hotkeys", "OpenWikiHotKey")
	WriteIniValue(TradeOpts.CustomInputSearchHotKey, TradeConfigPath, "Hotkeys", "CustomInputSearchHotKey")
	WriteIniValue(TradeOpts.OpenSearchOnPoeTradeHotKey, TradeConfigPath, "Hotkeys", "OpenSearchOnPoeTradeHotKey")
	WriteIniValue(TradeOpts.ShowItemAgeHotKey, TradeConfigPath, "Hotkeys", "ShowItemAgeHotKey")
	
	; Search	
	WriteIniValue(TradeOpts.AccountName, TradeConfigPath, "Search", "AccountName")
	WriteIniValue(TradeOpts.SearchLeague, TradeConfigPath, "Search", "SearchLeague")
	WriteIniValue(TradeOpts.GemLevel, TradeConfigPath, "Search", "GemLevel")
	WriteIniValue(TradeOpts.GemQualityRange, TradeConfigPath, "Search", "GemQualityRange")
	WriteIniValue(TradeOpts.OnlineOnly, TradeConfigPath, "Search", "OnlineOnly")
	WriteIniValue(TradeOpts.Corrupted, TradeConfigPath, "Search", "Corrupted")
	WriteIniValue(TradeOpts.AdvancedSearchModValueRange, TradeConfigPath, "Search", "AdvancedSearchModValueRange")
	WriteIniValue(TradeOpts.RemoveMultipleListingsFromSameAccount, TradeConfigPath, "Search", "RemoveMultipleListingsFromSameAccount")
    WriteIniValue(TradeOpts.PrefillMinValue, TradeConfigPath, "Search", "PrefillMinValue")
	WriteIniValue(TradeOpts.PrefillMaxValue, TradeConfigPath, "Search", "PrefillMaxValue")
	WriteIniValue(TradeOpts.CurrencySearchHave, TradeConfigPath, "Search", "CurrencySearchHave")
    
	; Cache	
	WriteIniValue(TradeOpts.Expire, TradeConfigPath, "Cache", "Expire")
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

SetLeagueIfSelectedIsInactive() 
{	
	; Check if league from Ini is set to an inactive league and change it to the corresponding active one, for example tmpstandard to standard	
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
ReadIniValue(iniFilePath, Section = "General", IniKey="", DefaultValue = "")
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
            If(not InStr(line, ";") and match) {
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

WriteIniValue(Val, TradeConfigPath, Section_, Key)
{
    IniWrite, %Val%, %TradeConfigPath%, %Section_%, %Key%
}

; ------------------ ASSIGN HOTKEY AND HANDLE ERRORS ------------------ 
AssignHotkey(Key, Label){
    Hotkey, %Key%, %Label%, UseErrorLevel
    if (ErrorLevel)	{
		if (errorlevel = 1)
			str := str . "`nASCII " . Key . " - 1) The Label parameter specifies a nonexistent label name."
		else if (errorlevel = 2)
			str := str . "`nASCII " . Key . " - 2) The KeyName parameter specifies one or more keys that are either not recognized or not supported by the current keyboard layout/language."
		else if (errorlevel = 3)
			str := str . "`nASCII " . Key . " - 3) Unsupported prefix key. For example, using the mouse wheel as a prefix in a hotkey such as WheelDown & Enter is not supported."
		else if (errorlevel = 4)
			str := str . "`nASCII " . Key . " - 4) The KeyName parameter is not suitable for use with the AltTab or ShiftAltTab actions. A combination of two keys is required. For example: RControl & RShift::AltTab."
		else if (errorlevel = 5)
			str := str . "`nASCII " . Key . " - 5) The command attempted to modify a nonexistent hotkey."
		else if (errorlevel = 6)
			str := str . "`nASCII " . Key . " - 6) The command attempted to modify a nonexistent variant of an existing hotkey. To solve this, use Hotkey IfWin to set the criteria to match those of the hotkey to be modified."
		else if (errorlevel = 50)
			str := str . "`nASCII " . Key . " - 50) Windows 95/98/Me: The command completed successfully but the operating system refused to activate the hotkey. This is usually caused by the hotkey being "" ASCII " . int . " - in use"" by some other script or application (or the OS itself). This occurs only on Windows 95/98/Me because on other operating systems, the program will resort to the keyboard hook to override the refusal."
		else if (errorlevel = 51)
			str := str . "`nASCII " . Key . " - 51) Windows 95/98/Me: The command completed successfully but the hotkey is not supported on Windows 95/98/Me. For example, mouse hotkeys and prefix hotkeys such as a & b are not supported."
		else if (errorlevel = 98)
			str := str . "`nASCII " . Key . " - 98) Creating this hotkey would exceed the 1000-hotkey-per-script limit (however, each hotkey can have an unlimited number of variants, and there is no limit to the number of hotstrings)."
		else if (errorlevel = 99)
			str := str . "`nASCII " . Key . " - 99) Out of memory. This is very rare and usually happens only when the operating system has become unstable."

        MsgBox, %str%
	}
}

; ------------------ GET LEAGUES ------------------ 
FunctionGETLeagues(){
    JSON := FunctionGetLeaguesJSON()   	
    FileRead, JSONFile, %TradeTempDir%\leagues.json  
    ; too dumb to parse the file to JSON Object, skipping this step
    ;parsedJSON 	:= JSON.Load(JSONFile)	
        
    ; Loop over league info and get league names    
    leagues := []
	Loop, Parse, JSONFile, `n, `r
	{				
        If RegExMatch(A_LoopField,"iOm)id *: *""(.*)""",leagueNames) {
            If (RegExMatch(leagueNames[1], "i)^Standard$")) {
                leagues["standard"] := leagueNames[1]
            }
            Else If (RegExMatch(leagueNames[1], "i)^Hardcore$")) {
                leagues["hardcore"] := leagueNames[1]
            }
            Else If InStr(leagueNames[1], "Hardcore", false) {
                leagues["tmphardcore"] := leagueNames[1]
            }
            Else {
                leagues["tmpstandard"] := leagueNames[1]
            }
        }        
	}
	Return leagues
}

FunctionGetLeaguesJSON(){
    HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    HttpObj.Open("GET","http://api.pathofexile.com/leagues?type=main&compact=1")
    HttpObj.SetRequestHeader("Content-type","application/json")
    HttpObj.Send("")
    HttpObj.WaitForResponse()
    
    ; Trying to format the string as JSON
    json := "{""results"":" . HttpObj.ResponseText . "}"    
    json := RegExReplace(HttpObj.ResponseText, ",", ",`r`n`" A_Tab) 
    json := RegExReplace(json, "{", "{`r`n`" A_Tab)
    json := RegExReplace(json, "}", "`r`n`}")    
    json := RegExReplace(json, "},", A_Tab "},")
    json := RegExReplace(json, "\[", "[`r`n`" A_Tab)
    json := RegExReplace(json, "\]", "`r`n`]")
    json := RegExReplace(json, "m)}$", A_Tab "}")
    json := RegExReplace(json, """(.*)"":", A_Tab "$1 : ")
    
    ;MsgBox % json
    FileDelete, %TradeTempDir%\leagues.json
    FileAppend, %json%, %TradeTempDir%\leagues.json
    
    Return, json
}

; ------------------ CHECK IF A TEMP-LEAGUE IS ACTIVE ------------------ 
FunctionCheckIfTempLeagueIsRunning() {
    tempLeagueDates := FunctionGetTempLeagueDates()
    
    UTCTimestamp := GetTimestampUTC()
    UTCFormatStr := "yyyy-MM-dd'T'HH:mm:ss'Z'"
    FormatTime, TimeStr, %UTCTimestamp%, %UTCFormatStr%
    
    timeDiffStart := DateParse(TimeStr) - DateParse(tempLeagueDates["start"])
    timeDiffEnd := DateParse(TimeStr) - DateParse(tempLeagueDates["end"])

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

DateParse(str) {
    ; Parse ISO 8601 Formatted Date/Time to YYYYMMDDHH24MISS timestamp
    str := RegExReplace(str, "i)-|T|:|Z")
    Return str
}

FunctionGetTempLeagueDates(){
    JSON := FunctionGetLeaguesJSON()    
    FileRead, JSONFile, %TradeTempDir%\leagues.json  
    ; too dumb to parse the file to JSON Object, skipping this step
    ;parsedJSON 	:= JSON.Load(JSONFile)	
     
    ; complicated way to find start and end dates of temp leagues since JSON.load is not working 
    foundStart := 
    foundEnd := 
    lastOpenBracket := 0
    lastCloseBracket := 0
    tempLeagueDates := []
    
	Loop, Parse, JSONFile, `n, `r
	{			
        If (InStr(A_LoopField, "{", false)) {
            lastOpenBracket := A_Index
        }
        Else If (InStr(A_LoopField, "}", false)) {
            lastCloseBracket := A_Index
        }        
        
        ; Find startAt and remember line number
        If RegExMatch(A_LoopField,"iOm)startAt *: *""(.*)""",dates) {
            If (StrLen(dates[1]) > 0)  {
                foundStart := A_index
                start := dates[1]
            }
        }            
        Else If RegExMatch(A_LoopField,"iOm)endAt *: *""(.*)""",dates) {
            If (!RegExMatch(dates[1], "i)null")) {
                foundEnd := A_Index
                end := dates[1]
            }       
        }
        
        If (foundStart > lastCloseBracket && foundEnd > lastCloseBracket) {
            tempLeagueDates["start"] := start
            tempLeagueDates["end"] := end
            Return tempLeagueDates
        }          
    }
}

;----------------------- Check if newer Release is available ---------------------------------------
FunctionGetLatestRelease() {
	If (TradeOpts.ShowUpdateNotification = 0) {
		return
	}
	repo := TradeGlobals.Get("GithubRepo")
	user := TradeGlobals.Get("GithubUser")
    HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    url := "https://api.github.com/repos/" . user . "/" . repo . "/releases/latest"

    ;https://api.github.com/repos/thirdy/POE-TradeMacro/releases/latest 
    Try  {
        HttpObj.Open("GET",url)
        HttpObj.SetRequestHeader("Content-type","application/html")
        HttpObj.Send("")
        HttpObj.WaitForResponse()   
        html := HttpObj.ResponseText

        RegExMatch(html, "i)""tag_name"":""(.*?)""", tag)
        RegExMatch(html, "i)""name"":""(.*?)""", vName)
        RegExMatch(html, "i)""html_url"":""(.*?)""", url)

        tag := tag1
        vName := vName1
        url := url1    
        
        RegExReplace(tag, "^v", tag)
        ; works only in x.x.x format
        RegExMatch(tag, "(\d+).(\d+).(\d+)(.*)", latestVersion)
        RegExMatch(TradeGlobals.Get("ReleaseVersion"), "(\d+).(\d+).(\d+)(.*)", currentVersion)    
            
        If (latestVersion > currentVersion) {
            Gui, UpdateNotification:Add, Text, cGreen, Update available!
            Gui, UpdateNotification:Add, Text, , Your installed version is <%currentVersion%>, the lastest version is <%latestVersion%>.
            Gui, UpdateNotification:Add, Link, cBlue, <a href="%url%">Download it here</a>        
            Gui, UpdateNotification:Add, Button, gCloseUpdateWindow, Close
            Gui, UpdateNotification:Show, w350 , Update 
        }
    } catch e {
        MsgBox % "Update-Check failed, Github is probably down."
    }
    return
}

;----------------------- Trade Settings UI (added onto ItemInfos Settings UI) ---------------------------------------

CreateTradeSettingsUI() 
{
    Global
    
    GuiAddGroupBox("", "x541 y-50 w2 h1000")
    
    ; General 

    GuiAddGroupBox("[TradeMacro] General", "x547 y15 w260 h186")
    
    ; Note: window handles (hwnd) are only needed if a UI tooltip should be attached.
    
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

    ; Hotkeys
    
    GuiAddGroupBox("[TradeMacro] Hotkeys", "x547 yp+65 w260 h235")
    
    GuiAddText("Price Check Hotkey:", "x557 yp+28 w160 h20 0x0100", "LblPriceCheckHotKey", "LblPriceCheckHotKeyH")
    AddToolTip(LblPriceCheckHotKeyH, "Check item prices.")
    GuiAddEdit(TradeOpts.PriceCheckHotKey, "x+10 yp-2 w50 h20", "PriceCheckHotKey", "PriceCheckHotKeyH")
    AddToolTip(PriceCheckHotKeyH, "Default: ctrl + d")
    
    GuiAddText("Advanced Price Check Hotkey:", "x557 yp+32 w160 h20 0x0100", "LblAdvancedPriceCheckHotKey", "LblAdvancedPriceCheckHotKeyH")
    AddToolTip(LblAdvancedPriceCheckHotKeyH, "Select mods to include in your search`nbefore checking prices.")
    GuiAddEdit(TradeOpts.AdvancedPriceCheckHotKey, "x+10 yp-2 w50 h20", "AdvancedPriceCheckHotKey", "AdvancedPriceCheckHotKeyH")
    AddToolTip(AdvancedPriceCheckHotKeyH, "Default: ctrl + alt + d")
    
    GuiAddText("Custom Input Search:", "x557 yp+32 w160 h20 0x0100", "LblCustomInputSearchHotkey", "LblCustomInputSearchHotkeyH")
    AddToolTip(LblCustomInputSearchHotkeyH, "Custom text input search.")
    GuiAddEdit(TradeOpts.CustomInputSearchHotkey, "x+10 yp-2 w50 h20", "CustomInputSearchHotkey", "CustomInputSearchHotkeyH")
    AddToolTip(CustomInputSearchHotkeyH, "Default: ctrl + i")
    
    GuiAddText("Open Search on poe.trade:", "x557 yp+32 w160 h20 0x0100", "LblOpenSearchOnPoeTradeHotKey", "LblOpenSearchOnPoeTradeHotKeyH")
    AddToolTip(LblOpenSearchOnPoeTradeHotKeyH, "Open your search on poe.trade instead of showing`na tooltip with results.")
    GuiAddEdit(TradeOpts.OpenSearchOnPoeTradeHotKey, "x+10 yp-2 w50 h20", "OpenSearchOnPoeTradeHotKey", "OpenSearchOnPoeTradeHotKeyH")
    AddToolTip(OpenSearchOnPoeTradeHotKeyH, "Default: ctrl + q")
    
    GuiAddText("Open Item on Wiki:", "x557 yp+32 w160 h20 0x0100", "LblOpenWikiHotkey", "LblOpenWikiHotkeyH")
    AddToolTip(LblOpenWikiHotKeyH, "Open your items page on the PoE-Wiki.")
    GuiAddEdit(TradeOpts.OpenWikiHotKey, "x+10 yp-2 w50 h20", "OpenWikiHotKey", "OpenWikiHotKeyH")
    AddToolTip(OpenWikiHotKeyH, "Default: ctrl + w")
    
    GuiAddText("Show Item Age:", "x557 yp+32 w160 h20 0x0100", "LblShowItemAgeHotkey", "LblShowItemAgeHotkeyH")
    AddToolTip(LblShowItemAgeHotkeyH, "Checks your item's age.")
    GuiAddEdit(TradeOpts.ShowItemAgeHotkey, "x+10 yp-2 w50 h20", "ShowItemAgeHotkey", "ShowItemAgeHotkeyH")
    AddToolTip(ShowItemAgeHotkeyH, "Default: ctrl + a")
    
    Gui, Add, Link, x557 yp+32 w160 h20 cBlue, <a href="http://www.autohotkey.com/docs/Hotkeys.htm">Hotkey Options</a>
    
    ; Search
    
    GuiAddGroupBox("[TradeMacro] Search", "x817 y15 w260 h555")
    
    GuiAddText("League:", "x827 yp+28 w100 h20 0x0100", "LblSearchLeague", "LblSearchLeagueH")
    AddToolTip(LblSearchLeagueH, "Defaults to ""standard"" or ""tmpstandard"" if there is a`nTemp-League active at the time of script execution.`n`n""tmpstandard"" and ""tmphardcore"" are automatically replaced`nwith their permanent counterparts if no Temp-League is active.")
    GuiAddDropDownList("tmpstandard|tmphardcore|standard|hardcore", "x+10 yp-2", TradeOpts.SearchLeague, "SearchLeague", "SearchLeagueH")
    
    GuiAddText("Account Name:", "x827 yp+32 w100 h20 0x0100", "LblAccountName", "LblAccountNameH")
    AddToolTip(LblAccountNameH, "Your Account Name used to check your item's age.")
    GuiAddEdit(TradeOpts.AccountName, "x+10 yp-2 w120 h20", "AccountName", "AccountNameH")
    
    GuiAddText("Gem Level:", "x827 yp+32 w170 h20 0x0100", "LblGemLevel", "LblGemLevelH")
    AddToolTip(LblGemLevelH, "Gem level is ignored in the search unless it's equal`nor higher than this value.`n`nSet to something like 30 to completely ignore the level.")
    GuiAddEdit(TradeOpts.GemLevel, "x+10 yp-2 w50 h20", "GemLevel", "GemLevelH")
    
    GuiAddText("Gem Quality Range:", "x827 yp+32 w170 h20 0x0100", "LblGemQualityRange", "LblGemQualityRangeH")
    AddToolTip(LblGemQualityRangeH, "Use this to set a range to quality Gem searches. For example a range of 1`n searches 14% - 16% when you have a 15% Quality Gem.`nSetting it to 0 (default) uses your Gems quality as min_quality`nwithout max_quality in your search.")
    GuiAddEdit(TradeOpts.GemQualityRange, "x+10 yp-2 w50 h20", "GemQualityRange", "GemQualityRangeH")
    
    GuiAddText("Mod Range Modifier (%):", "x827 yp+32 w170 h20 0x0100", "LblAdvancedSearchModValueRange", "LblAdvancedSearchModValueRangeH")
    AddToolTip(LblAdvancedSearchModValueRangeH, "Advanced search lets you select the items mods to include in your`nsearch and lets you set their min/max values.`n`nThese min/max values are pre-filled, to calculate them we look at`nthe difference between the mods theoretical max and min value and`ntreat it as 100%.`n`nWe then use this modifier as a percentage of this differences to`ncreate a range (min/max value) to search in. ")
    GuiAddEdit(TradeOpts.AdvancedSearchModValueRange, "x+10 yp-2 w50 h20", "AdvancedSearchModValueRange", "AdvancedSearchModValueRangeH")
    
    GuiAddText("Corrupted:", "x827 yp+32 w100 h20 0x0100", "LblCorrupted", "LblCorruptedH")
    AddToolTip(LblCorruptedH, "This setting gets ignored when you use`nthe search on corrupted items.")
    GuiAddDropDownList("Either|Yes|No", "x+10 yp-2", TradeOpts.Corrupted, "Corrupted", "CorruptedH")
    
    CurrencyList := ""
    CurrencyTemp := TradeGlobals.Get("CurrencyIDs")
    For currName, currID in CurrencyTemp {        
        CurrencyList .= "|" . currName 
    }    
    GuiAddText("Currency Search:", "x827 yp+32 w100 h20 0x0100", "LblCurrencySearchHave", "LblCurrencySearchHaveH")
    AddToolTip(LblCurrencySearchHaveH, "This settings sets the currency that you`nwant to use as ""have"" for the currency search.")
    GuiAddDropDownList(CurrencyList, "x+10 yp-2", TradeOpts.CurrencySearchHave, "CurrencySearchHave", "CurrencySearchHaveH")
    
    GuiAddCheckbox("Online only", "x827 yp+22 w210 h35 0x0100", TradeOpts.OnlineOnly, "OnlineOnly", "OnlineOnlyH")
    
    GuiAddCheckbox("Remove multiple Listings from same Account", "x827 yp+28 w230 h40", TradeOpts.RemoveMultipleListingsFromSameAccount, "RemoveMultipleListingsFromSameAccount", "RemoveMultipleListingsFromSameAccountH")
    AddToolTip(RemoveMultipleListingsFromSameAccountH, "Removes multiple listings from the same account from`nyour search results (to combat market manipulators).`n`nThe removed items are also removed from the average and`nmedian price calculations.")
    
    GuiAddCheckbox("Pre-Fill Min-Values", "x827 yp+30 w230 h40", TradeOpts.PrefillMinValue, "PrefillMinValue", "PrefillMinValueH")
    AddToolTip(PrefillMinValueH, "Automatically fill the min-values in the advanced search GUI.")
    GuiAddCheckbox("Pre-Fill Max-Values", "x827 yp+30 w230 h40", TradeOpts.PrefillMinValue, "PrefillMaxValue", "PrefillMaxValueH")
    AddToolTip(PrefillMaxValueH, "Automatically fill the max-values in the advanced search GUI.")
    
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
    GuiControl,, AdvancedSearchModValueRange, % TradeOpts.AdvancedSearchModValueRange
    GuiControl,, CurrencySearchHave, % TradeOpts.CurrencySearchHave
    GuiControl,, Corrupted, % TradeOpts.Corrupted
    GuiControl,, OnlineOnly, % TradeOpts.OnlineOnly
    GuiControl,, PrefillMinValue, % TradeOpts.PrefillMinValue
    GuiControl,, PrefillMaxValue, % TradeOpts.PrefillMaxValue
    GuiControl,, RemoveMultipleListingsFromSameAccount, % TradeOpts.RemoveMultipleListingsFromSameAccount
}

ReadCraftingBases(){
    bases := []
    Loop, read, %A_ScriptDir%\trade_data\crafting_bases.txt
    {
        bases.push(A_LoopReadLine)
    }
    return bases    
}

ReadEnchantments(){
    enchantments := {}
    enchantments.boots   := []
    enchantments.helmet  := []
    enchantments.gloves  := []
    
    Loop, read, %A_ScriptDir%\trade_data\boot_enchantment_mods.txt
    {
        If (StrLen(Trim(A_LoopReadLine)) > 0) {        
            enchantments.boots.push(A_LoopReadLine)            
        }
    }
    Loop, read, %A_ScriptDir%\trade_data\helmet_enchantment_mods.txt
    {
        If (StrLen(Trim(A_LoopReadLine)) > 0) {
            enchantments.helmet.push(A_LoopReadLine)
        }
    }
    Loop, read, %A_ScriptDir%\trade_data\glove_enchantment_mods.txt
    {
        If (StrLen(Trim(A_LoopReadLine)) > 0) {
            enchantments.gloves.push(A_LoopReadLine)
        }
    }
    return enchantments    
}

ReadCorruptions(){
    mods := []    
    
    Loop, read, %A_ScriptDir%\trade_data\item_corrupted_mods.txt
    {
        If (StrLen(Trim(A_LoopReadLine)) > 0) {        
            mods.push(A_LoopReadLine)            
        }
    }
    return mods
}

CheckBrowserPath(path, showMsg){
    If (path) {
        path := RegExReplace(path, "i)\/", "\")
        AttributeString := FileExist(path)
        If (not AttributeString) {
            If (showMsg) {
                MsgBox % "Invalid FilePath."
            }            
            return false
        }
        Else {
            return AttributeString
        }
    }    
}

;----------------------- SplashScreens ---------------------------------------
StartSplashScreen() {
    SplashTextOn, , , Initializing PoE-TradeMacro...
}
StopSplashScreen() {
    SplashTextOff 
    ; Let timer run until SettingsUIWidth is set and overwrite some options.
    SetTimer, OverwriteSettingsWidthTimer, 500
    SetTimer, OverwriteSettingsNameTimer, 500
}


