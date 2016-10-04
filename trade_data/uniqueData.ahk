; Can't get JSON load working inside any Function/Class or in TradeMacroInit
; Works here, though.
; Data is available via global variables
; json scraped with https://github.com/Eruyome/scrapeVariableUniqueItems/

#Include, %A_ScriptDir%/lib/JSON.ahk

FileRead, JSONFile, %A_ScriptDir%/trade_data/uniques.json
parsedJSON 	:= JSON.Load(JSONFile)
global TradeUniqueData := parsedJSON.uniques
