; TradeMacro Add-on to POE-ItemInfo v0.1
; IGN: ManicCompression
; Notes:
; 1. To enable debug output, find the out() function and uncomment
;
; Todo:
; Support for modifiers
; Allow user to customize which mod and value to use

#Include, %A_ScriptDir%/lib/JSON.ahk
#Include, %A_ScriptDir%/trade_data/uniqueData.ahk

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
FileRemoveDir, %TradeTempDir%, 1
FileCreateDir, %TradeTempDir%

class TradeUserOptions {
    ShowItemResults := 15		    ; Number of Items shown as search result; defaults to 15 if not set.
	ShowUpdateNotifications := 1	; 1 = show, 0 = don't show
    Debug := 0      				; 
	
    PriceCheckHotKey := ^x        	; 
    OpenWiki := ^w             		; 
    CustomInputSearch := ^i         ;     
    
    SearchLeague := "tmpstandard"   ; Defaults to "standard" or "tmpstandard" if there is an active Temp-League at the time of script execution.
									; Possible values: 
									; 	"tmpstandard" (current SC Temp-League) 
									;	"tmphardcore" (current HC Temp-League) 
									;	"standard", 
									;   "hardcore"
	
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
TradeGlobals.Set("GithubUser", "thirdy")
TradeGlobals.Set("GithubRepo", "POE-TradeMacro")
TradeGlobals.Set("ReleaseVersion", "1.0.0")

;FunctionGetLatestRelease()
ReadTradeConfig()
Sleep, 100

TradeGlobals.Set("Leagues", FunctionGETLeagues())
TradeGlobals.Set("LeagueName", TradeGlobals.Get("Leagues")[TradeOpts.SearchLeague])
TradeGlobals.Set("VariableUniqueData", TradeUniqueData)

ReadTradeConfig(TradeConfigPath="trade_config.ini")
{
    Global
    IfExist, %TradeConfigPath%
    {
        ; General 		
        TradeOpts.ShowItemResults := ReadIniValue(TradeConfigPath, "General", "ShowItemResults", TradeOpts.ShowItemResults)
		TradeOpts.ShowUpdateNotifications := ReadIniValue(TradeConfigPath, "General", "ShowUpdateNotifications", TradeOpts.ShowUpdateNotifications)

        ; Debug        
        TradeOpts.Debug := ReadIniValue(TradeConfigPath, "Debug", "Debug", 0)
        
        ; Hotkeys        
        TradeOpts.PriceCheckHotKey := ReadIniValue(TradeConfigPath, "Hotkeys", "PriceCheckHotKey", TradeOpts.PriceCheckHotKey)
        TradeOpts.OpenWiki := ReadIniValue(TradeConfigPath, "Hotkeys", "OpenWiki", TradeOpts.OpenWiki)
        TradeOpts.CustomInputSearch := ReadIniValue(TradeConfigPath, "Hotkeys", "CustomInputSearchHotKey", TradeOpts.CustomInputSearch)

		AssignHotkey(TradeOpts.PriceCheckHotKey, "PriceCheck")
		AssignHotkey(TradeOpts.OpenWiki, "OpenWiki")
		AssignHotkey(TradeOpts.CustomInputSearch, "CustomInputSearch")
		
        ; Search     	
		TradeOpts.SearchLeague := ReadIniValue(TradeConfigPath, "Search", "SearchLeague", TradeOpts.Get("DefaultLeague"))	
        SetLeagueIfSelectedIsInactive()
		
        ; Cache        
        TradeOpts.Expire := ReadIniValue(TradeConfigPath, "Cache", "Expire", TradeOpts.Expire)
    }
}

WriteTradeConfig(TradeConfigPath="trade_config.ini")
{  
	Global
    ; General        
	WriteIniValue(TradeOpts.ShowItemResults, TradeConfigPath, "General", "ShowItemResults")

	; Debug	
	WriteIniValue(TradeOpts.Debug, TradeConfigPath, "Debug", "Debug")
	
	; Hotkeys	
	WriteIniValue(TradeOpts.PriceCheckHotKey, TradeConfigPath, "Hotkeys", "PriceCheckHotKey")
	WriteIniValue(TradeOpts.OpenWiki, TradeConfigPath, "Hotkeys", "OpenWiki")
	
	; Search	
	WriteIniValue(TradeOpts.SearchLeague, TradeConfigPath, "Search", "SearchLeague")
	
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
ReadIniValue(iniFilePath, Section = "Misc", IniKey="", DefaultValue = "")
{
	IniRead, OutputVar, %iniFilePath%, %Section%, %IniKey%
	If (!OutputVar | RegExMatch(OutputVar, "^ERROR$")) { 
		OutputVar := DefaultValue
        ; Somehow reading some ini-values is not working with IniRead
        ; Fallback for these cases via FileReadLine        
        Loop {
            FileReadLine, line, %iniFilePath%, %A_Index%
            If ErrorLevel
            break
            If InStr(line, IniKey, false) {
                RegExMatch(line, "= *(.*)", value)
                If (StrLen(value1) = 0) {
                    OutputVar := DefaultValue
                    
                }
                Else {
                    OutputVar := value1
                }                
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
    url := "https://github.com/" . user . "/" . repo . "/releases"
    tagsUrl = url . "/tags"
    HttpObj.Open("GET",url)
    HttpObj.SetRequestHeader("Content-type","application/html")
    HttpObj.Send("")
    HttpObj.WaitForResponse()
    
    html := HttpObj.ResponseText
    tag := StrX( html,  "<span class=""tag-name",N,0,  "</span>", 1,0, N )
	MsgBox % tag
    RegExMatch(tag, "i)>(.*)<", match)
    tag := match1
    
    RegExMatch(tag, "(\d+).(\d+).(\d+)(.*)", latestVersion)
    RegExMatch(TradeGlobals.Get("ReleaseVersion"), "(\d+).(\d+).(\d+)(.*)", currentVersion)
    
    Loop, 3 {
        If (latestVersion%A_Index% > currentVersion%A_Index%) {            
			Run %url%
            break
        }
    }
}