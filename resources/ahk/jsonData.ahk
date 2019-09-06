; Can't get JSON load working inside any Function/Class or in TradeMacroInit
; Works here, though.
; Data is available via global variables
; json scraped with https://github.com/Eruyome/scrapeVariableUniqueItems/

; when using the fallback exe we're missing the parameters passed by the merge script and missed clearing the temp folder
argumentIsMergedScript = %5%
If (argumentIsMergedScript != "isMergedScript") {
	FileRemoveDir, %A_ScriptDir%\temp, 1
	FileCreateDir, %A_ScriptDir%\temp
}

; Parse the unique items data
global TradeUniqueData := ReadJSONDataFromFile(A_ScriptDir "\data_trade\uniques.json", "uniques")

; Parse the unique relic items data
global TradeRelicData := ReadJSONDataFromFile(A_ScriptDir "\data_trade\relics.json", "relics")

; Parse the poe.trade mods
global TradeModsData := ReadJSONDataFromFile(A_ScriptDir "\data_trade\mods.json", "mods")

; Parse currency names (in-game names mapped to poe.trade names)
global TradeCurrencyNames := ReadJSONDataFromFile(A_ScriptDir "\data_trade\currencyNames.json", "currencyNames")

; Parse fallback currency IDs
global TradeCurrencyIDsFallback := ReadJSONDataFromFile(A_ScriptDir "\data_trade\currencyIDs_Fallback.json")

; Parse the currency tags
global TradeCurrencyTags := ReadJSONDataFromFile(A_ScriptDir "\data_trade\currency_tags.json", "tags")

; Parse item base data (weapons)
global TradeItemBasesWeapons := ReadJSONDataFromFile(A_ScriptDir "\data_trade\item_bases_weapon.json", "item_bases_weapon")

; Parse item base data (armours)
global TradeItemBasesArmours := ReadJSONDataFromFile(A_ScriptDir "\data_trade\item_bases_armour.json", "item_bases_armour")

SplashUI.SetSubMessage("Parsing leagues from GGGs API...")
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
WriteToLogFile("Requesting leagues from api.pathofexile.com...`n`n" "cURL command:`n" reqHeadersCurl "`n`nAnswer: " reqHeaders, "StartupLog.txt", "PoE-TradeMacro")

If (PoEScripts_SaveWriteTextFile(A_ScriptDir "\temp\currentLeagues.json", parsedLeagueJSON, "utf-8", true, true)) {
	WriteToLogFile("Failed to delete " A_ScriptDir "\temp\currentLeagues.json before writing JSON data. `n", "StartupLog.txt", "PoE-TradeMacro")	
}

errorMsg := "Parsing the league data (json) from the Path of Exile API failed."
errorMsg .= "`nThis should only happen when the pathofexile.com servers are down for maintenance or if you have network issues and can't connect to the site." 
errorMsg .= "`n`nMost likely the servers are down, please check by visiting pathofexile.com and try again later."
errorMsg .= "`n`nThe script execution will be stopped."
errorMsg .= "`n`nPlease do not report this issue if the pathofexile.com servers are down for maintenance!"
errorMsg .= "`nNobody can help you in that case, you'll have to wait until they are up again."

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

ReadJSONDataFromFile(filepath, key = "", critical = false) {
	data := 
	
	failed := false
	errorMsg := "Parsing the JSON data from the file """ filepath """ failed."
	errorMsg .= "`n" ""
	
	Try {	
		test := FileExist(filepath)
		If (test) {
			FileRead, JSONFile, %filepath%
			parsedJSON := JSON.Load(JSONFile)
			If (StrLen(key)) {
				data := parsedJSON[key]
			} Else {
				data := parsedJSON
			}
		}
		Else {
			errorMsg .= "`n" "The file doesn't exist."
			failed := true		
		}
	} Catch error {
		errorMsg .= "`n" "The file may contain invalid JSON data which would mean that the file got ""broken."""
		failed := true
	}
	
	If (failed) {
		If (not critical) {
			errorMsg .= "`n`n" "You can continue running the script so that you can go to the settings" 
			errorMsg .= "`n" "menu -> TradeMaco tab -> disable ""Download data files on start"" to make sure that this is not caused by a failed download."
			errorMsg .= "`n`n" "You will have to use the data file from the original script download though to replace the missing/broken one."	
		}		
		errorMsg .= "`n`n" "Repeating the script start could solve this issue."
		
		MsgBox, 16, PoE-TradeMacro - Error, %errorMsg%	
		If (critical) {
			ExitApp
		}
	}

	Return data
}