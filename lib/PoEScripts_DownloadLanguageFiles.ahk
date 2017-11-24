PoEScripts_DownloadLanguageFiles(ByRef currentLocale, dlAll = false, SplashTitle = "", SplashText = "", onlyParseFiles = false) {
	; onlyParseFiles = skip downloading anything for development purposes (if the data files exist).
	currentLocale := PoEScripts_GetClientLanguage()
	If (currentLocale = "en" or not currentLocale) {
		Return
	}
	
	SplashTextOn, 300, 20, %SplashTitle%, %SplashText%
	
	lang := PoEScripts_ParseAvailableLanguages(onlyParseFiles)
	translationData := {}
	
	If (dlAll) {
		For key, l in lang {
			translationData := PoEScripts_DownloadFileSet(key, l, onlyParseFiles)
		}
	} Else If (not currentLocale = "en" and currentLocale) {
		translationData.currentLocale := currentLocale
		translationData.localized	:= PoEScripts_DownloadFileSet(currentLocale, lang[currentLocale], onlyParseFiles)
		translationData.default	 	:= PoEScripts_DownloadFileSet("en", lang["en"], onlyParseFiles)
	}
	
	If (onlyParseFiles) {
		dumpObj := JSON.Dump(translationData)
		FileDelete, %A_ScriptDir%\data\lang\lang.json
		FileAppend, %dumpObj%, %A_ScriptDir%\data\lang\lang.json
	}
	
	SplashTextOff
	Return translationData
}

PoEScripts_GetClientLanguage() {
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
	
	readFile	:= ""
	For key, val in configs {
		IniRead, language, %val%, LANGUAGE, language
		If (language != "ERROR") {
			Return language
		}
	}
	Return false
}

PoEScripts_DownloadFileSet(short, long, skipDL = false) {
	returnObj := {}
	prefix := short = "en" ? "www" : short

	files := []
	For key, val in ["stats", "static", "items"] {
		files.push(["https://" prefix ".pathofexile.com/api/trade/data/" val, short "_" val ".json", val])
	}	
	If (short != "en") {
		files.push(["http://web.poecdn.com/js/translate." long ".js", short "_basic.json", "basic"])
	}

	; download (overwrite) data files
	; if downloaded files have a size rename them, overwriting the ones already existing
	dir = %A_ScriptDir%\data\lang
	If (not FileExist(dir)) {
		FileCreateDir, %dir%
	}
	
	Loop % files.MaxIndex() {
		url := files[A_Index][1]
		file:= files[A_Index][2]
		filePath = %dir%\%file%
		isJavaScriptFile := RegExMatch(url, ".*\.js$")
		
		skipDL := FileExist(filePath) and skipDL ? true : false
		If (not skipDL) {
			console.log("dl")
			reqHeaders	:= []
			reqHeaders.push("Connection: keep-alive")
			reqHeaders.push("Cache-Control: max-age=0")
			reqHeaders.push("Upgrade-Insecure-Requests: 1")
			reqHeaders.push("Accept: */*")
			reqHeaders.push("Accept-Language: de,en-US;q=0.7,en;q=0.3")
			
			ioHdr := reqHeaders
			If (InStr(url, "web.poecdn.com")) {
				ioHdr.push("Host: web.poecdn.com")
			} Else {
				ioHdr.push("Host: " prefix ".pathofexile.com")
			}
			output :=  PoEScripts_Download(url, postData := "", ioHdr := reqHeaders, "SaveAs: " filePath "_temp", true, false, true)
		}
		
		; TODO: refactor this unnessecary complicated code
		If (skipDL) {
			FileGetSize, sizeOnDisk, %filePath%
			If (isJavaScriptFile) {				
				FileRead, jsFile, %filepath%
			}
		} Else {
			FileGetSize, sizeOnDisk, %filePath%_temp
			If (isJavaScriptFile) {				
				FileRead, jsFile, %filepath%_temp
			}
			FileDelete, %filePath%
		}
		
		If (sizeOnDisk) {
			If (isJavaScriptFile and not skipDL) {
				jsToObj := {}
				JSON := PoEScripts_ConvertJSVariableFileToJSON(jsFile, jsToObj)
				FileAppend, %JSON%, %filePath%, utf-8
			} Else If (not skipDL) {				
				FileMove, %filePath%_temp, %filePath%
			}
		}
		FileDelete, %filePath%_temp
		
		parsedJSON := {}
		If (sizeOnDisk) {
			FileRead, JSONFile, %filePath%
			Try {
				If (isJavaScriptFile and not skipDL) {
					returnObj[files[A_Index][3]] := jsToObj
				} Else {
					parsedJSON := JSON.Load(JSONFile)					
					returnObj[files[A_Index][3]] := parsedJSON.result
				}
			} Catch e {
				; TODO: improve error handling
				MsgBox, % "Failed to parse language file: " filePath 
			}
		}
	}

	Return returnObj
}

PoEScripts_ConvertJSVariableFileToJSON(file, ByRef obj) {	
	; it seems that the file contains multiple duplicate entries
	; they either need to be filtered out or the json file needs a different structure
	
	; make sure to have one key-value pair per line
	objSrc := RegExReplace(file, ";", ";`r`n")
	obj := {}
	obj.result := []

	Loop, parse, objSrc, `n, `r
	{
		If (StrLen(A_LoopField)) {
			RegExMatch(Trim(A_LoopField), ".*?\['(.*?)'\]\s+=\s+'(.*?)'.*", keyValuePair)
			
			Loop, 2 {
				keyValuePair%A_Index% := RegExReplace(keyValuePair%A_Index%, """", """")					
			}
			
			If (not obj[keyValuePair1] and StrLen(keyValuePair2)) {
				_t := {}
				_t.default := keyValuePair1
				_t.localized := keyValuePair2
				obj.result.push(_t)
			}				
		}			
	}
	json := JSON.Dump(obj)

	; old code to convert the file to valid json
	/*
	If (false) {
		json := file
		; escape some characters
		json := RegExReplace(Trim(json), "\\'", "\\'")
		json := RegExReplace(Trim(json), """", "\""")
		
		; duplicates would need to be removed
		If (false) {
			; convert JS object properties to JSON properties
			json := RegExReplace(Trim(json), ".*?\['(.*?)'\]\s+=\s+'(.*?)'.*", """$1"":""$2""")
			; add an object definition and wrap properties within curly braces
			json := RegExReplace(Trim(json), "s)(.*var.*?;.*?)("".*"")", "{""result"":[{$2}]}")
			; replace linebreaks with ,
			json := RegExReplace(Trim(json), "s)\r\n", ",")
			json := RegExReplace(Trim(json), "s),{2,}", ",")
			; remove trailing garbage
			json := RegExReplace(Trim(json), "s)(.*})(.*)", "$1")	
		}
		
		; different structure, numerical index instead of associative keys
		If (true) {
			; convert JS object properties to JSON properties
			json := RegExReplace(Trim(json), ".*?\['(.*?)'\]\s+=\s+'(.*?)'.*", "{""$1"":""$2""}")
			; add an object definition and wrap properties within curly braces
			json := RegExReplace(Trim(json), "s)(.*var.*?;.*?)({.*})", "{""result"":[$2]}")
			; replace linebreaks with ,
			json := RegExReplace(Trim(json), "s)\r\n", ",")
			json := RegExReplace(Trim(json), "s),{2,}", ",")
			; remove trailing garbage
			json := RegExReplace(Trim(json), "s)(.*})(.*)", "$1")	
		}
		
		;json := JSON.Dump(obj)		
		;console.log(json)		
	}
	*/

	; Returning this json text and saving it as a file works and produces valid JSON, but
	; for some reason JSON.load() can't parse it though after that without a scriptreload.
	Return json
}

PoEScripts_ParseAvailableLanguages(returnDefaults = false) {
	languages := {}
	
	If (not returnDefaults) {		
		url 	:= "https://www.pathofexile.com/trade"
		options	:= ""
		
		reqHeaders	:= []
		reqHeaders.push("Host: www.pathofexile.com")
		reqHeaders.push("Connection: keep-alive")
		reqHeaders.push("Cache-Control: max-age=0")
		reqHeaders.push("Upgrade-Insecure-Requests: 1")
		reqHeaders.push("Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8")

		html := PoEScripts_Download(url, postData, reqHeaders, options, false)

		If (StrLen(html)) {
			Pos := 0
			While Pos := RegExMatch(html, "i)hreflang=""(\w*)-?(\w*)""", lang, Pos + (StrLen(lang) ? StrLen(lang) : 1)) {
				If (lang2) {
					StringLower, lang, lang2
				} Else {
					StringLower, lang, lang1
				}			
				languages[lang] := lang2 ? lang1 "_" lang2 : lang
			}
		}
	}
	If (not languages.en) {
		languages["br"] := "pt_BR"
		languages["de"] := "de_DE"
		languages["en"] := "en"
		languages["es"] := "es_ES"
		languages["fr"] := "fr_FR"
		languages["ru"] := "ru_RU"
		languages["th"] := "th_TH"
	}

	Return languages
}