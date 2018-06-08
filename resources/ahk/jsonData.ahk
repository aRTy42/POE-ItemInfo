; Can't get JSON load working inside any Function/Class or in TradeMacroInit
; Works here, though.
; Data is available via global variables
; json scraped with https://github.com/Eruyome/scrapeVariableUniqueItems/

#Include, %A_ScriptDir%\lib\JSON.ahk

; when using the fallback exe we're missing the parameters passed by the merge script and missed clearing the temp folder
argumentIsMergedScript = %5%
If (argumentIsMergedScript != "isMergedScript") {
	FileRemoveDir, %A_ScriptDir%\temp, 1
	FileCreateDir, %A_ScriptDir%\temp
}

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

; Parse currency names (in-game names mapped to poe.trade names)
FileRead, JSONFile, %A_ScriptDir%\data_trade\currencyNames.json
parsedJSON := JSON.Load(JSONFile)
global TradeCurrencyNames := parsedJSON.currencyNames

; Parse fallback currency IDs
FileRead, JSONFile, %A_ScriptDir%\data_trade\currencyIDs_Fallback.json
parsedJSON := JSON.Load(JSONFile)
global TradeCurrencyIDsFallback := parsedJSON

; Parse the unique items data
FileRead, JSONFile, %A_ScriptDir%\data_trade\currency_tags.json
parsedJSON := JSON.Load(JSONFile)
global TradeCurrencyTags := parsedJSON.tags

; Download and parse the current leagues
postData		:= ""
reqHeaders	:= []
;options		:= "ReturnHeaders: Skip"
options		:= "`n" "RequestType: GET"
reqHeaders.push("Host: api.pathofexile.com")
reqHeaders.push("Connection: keep-alive")
reqHeaders.push("Cache-Control: max-age=0")
reqHeaders.push("Content-type: application/x-www-form-urlencoded; charset=UTF-8")
reqHeaders.push("Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8")
reqHeaders.push("User-Agent: Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36")
parsedLeagueJSON := PoEScripts_Download("http://api.pathofexile.com/leagues?type=main", postData, reqHeaders, options, true, true, false, "", reqHeadersCurl)
TradeFunc_WriteToLogFile("Requesting leagues from api.pathofexile.com...`n`n" "cURL command:`n" reqHeadersCurl "`n`nAnswer: " reqHeaders)
FileDelete, %A_ScriptDir%\temp\currentLeagues.json, 1
FileAppend, %parsedLeagueJSON%, %A_ScriptDir%\temp\currentLeagues.json

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