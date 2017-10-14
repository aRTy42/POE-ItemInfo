PoEScripts_CheckCorrectClientLanguage() {	
	iniPath		:= A_MyDocuments . "\My Games\Path of Exile\"
	configs 		:= []
	productionIni	:= iniPath . "production_Config.ini"
	betaIni		:= iniPath . "beta_Config.ini"	
	
	configs.push(productionIni)
	configs.push(betaIni)
	If (not FileExist(productionIni) and not FileExist(betaIni)) {
		Loop %iniPath%\*.ini
		{
			configs.push(iniPath . A_LoopFileName)		
		}	
	}
	
	wrongLanguage	:= false
	readFile		:= ""
	For key, val in configs {
		IniRead, language, %val%, LANGUAGE, language
		If (language != "ERROR") {
			If (language != "en") {
				wrongLanguage := true
			}
			RegExMatch(val, "i)([^\\]+)\.[^\\]+$", readFile)
			Break
		}
	}

	If (wrongLanguage) {
		msg := "It seems that you aren't using 'English' as your game clients language, according to the file '" readFile "'." "`n`n"
		msg .= "As long as GGG doesn't add a way to get the items data in english when using different game clients, this script won't work with those languages." "`n`n"
		msg .= "Please change your language or click 'continue' if you want to start the script anyway."
		
		MsgBox, 0x1012, Wrong PoE Game Client Language, % msg
		
		IfMsgBox, Ignore 
		{
			Return 1
		}
		IfMsgBox, Retry
		{
			PoEScripts_CheckCorrectClientLanguage()
		}
		IfMsgBox, Cancel 
		{
			Return 0
		}	
		IfMsgBox, Abort 
		{
			Return 0
		}
	}
	Return 1
}