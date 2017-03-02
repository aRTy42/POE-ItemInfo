; Can't get JSON load working inside any Function/Class or in TradeMacroInit
; Works here, though.
; Data is available via global variables
; json scraped with https://github.com/Eruyome/scrapeVariableUniqueItems/

#Include, %A_ScriptDir%\lib\JSON.ahk

; Parse the unique items data
FileRead, JSONFile, %A_ScriptDir%\data_trade\uniques.json
parsedJSON := JSON.Load(JSONFile)
global TradeUniqueData := parsedJSON.uniques

; Parse the unique relic items data
FileRead, JSONFile, %A_ScriptDir%\data_trade\relics.json
parsedJSON := JSON.Load(JSONFile)
global TradeRelicData := parsedJSON.relics

; Parse the poe.trade mods
FileRead, JSONFile, %A_ScriptDir%\data_trade\mods.json
parsedJSON := JSON.Load(JSONFile)
global TradeModsData := parsedJSON.mods


; Download and parse the current leagues
UrlDownloadToFile, http://api.pathofexile.com/leagues?type=main , %A_ScriptDir%\temp\currentLeagues.json

errorMsg := "Parsing the league data (json) from the Path of Exile API failed."
errorMsg .= "`nThis should only happen when the servers are down for maintenance." 
errorMsg .= "`n`nThe script execution will be stopped, please try again at a later time."

Try {
	test := FileExist(A_ScriptDir "\temp\currentLeagues.json")
	If (test) {
		FileRead, JSONFile, %A_ScriptDir%\temp\currentLeagues.json
		parsedJSON := JSON.Load(JSONFile)	
		global LeaguesData := parsedJSON
	}
	Else	{
		MsgBox, 16, PoE-TradeMacro - Error, %errorMsg%	
		ExitApp
	}
} Catch error {
	MsgBox, 16, PoE-TradeMacro - Error, %errorMsg%	
	ExitApp
}


