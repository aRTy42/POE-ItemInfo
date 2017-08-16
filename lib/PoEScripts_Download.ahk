PoEScripts_Download(url, ioData, ioHdr, options, useFallback = true, critical = false, binaryDL = false, errorMsg = "") {
	/*
		url		= download url
		ioData	= uri encoded postData 
		ioHdr	= array of request headers
		options	= multiple options separated by newline (currently only "SaveAs:",  "Redirect:true/false")
		
		useFallback = Use UrlDownloadToFile if curl fails, not possible for POST requests or when cookies are required 
		critical	= exit macro if download fails
		binaryDL	= file download (zip for example)
		errorMsg	= optional error message, will be added to default message
	*/
	
	; https://curl.haxx.se/download.html -> https://bintray.com/vszakats/generic/curl/
	curl		:= """" A_ScriptDir "\lib\curl.exe"""	
	headers	:= ""
	For key, val in ioHdr {
		headers .= "-H """ val """ "
	}	
	
	redirect := "L"
	PreventErrorMsg := false
	If (StrLen(options)) {
		If (RegExMatch(options, "i)SaveAs:[ \t]*\K[^\r\n]+", SavePath)) {
			commandData	.= " " options " "
			commandHdr	.= ""	
		}
		If (RegExMatch(options, "i)Redirect:\sFalse")) {
			redirect := ""
		}
		If (RegExMatch(options, "i)PreventErrorMsg")) {
			PreventErrorMsg := true
		}
	}
	
	e := {}
	Try {
		commandData	:= curl
		commandHdr	:= curl
		If (binaryDL) {
			commandData .= " -" redirect "Jkv "		; save as file
			If (SavePath) {
				commandData .= "-o """ SavePath """ "	; set target destination and name
			}
		} Else {
			commandData .= " -" redirect "ks --compressed "			
			commandHdr  .= " -I" redirect "ks "
		}
		If (StrLen(headers)) {
			commandData .= headers
			commandHdr  .= headers
		}
		If (StrLen(ioData)) {
			commandData .= "--data """ ioData """ "
		}

		; get data
		html	:= StdOutStream(commandData """" url """")
		;html := ReadConsoleOutputFromFile(commandData """" url """", "commandData") ; alternative function
		
		; get return headers in seperate request
		If (not binaryDL) {			
			If (StrLen(ioData)) {
				commandHdr := commandHdr """" url "?" ioData """"		; add payload to url since you can't use the -I argument with POST requests
			} Else {
				commandHdr := commandHdr """" url """"
			}
			ioHdr := StdOutStream(commandHdr)		
			;ioHrd := ReadConsoleOutputFromFile(commandHdr, "commandHdr") ; alternative function
		}
	} Catch e {
		
	}
	
	goodStatusCode := RegExMatch(ioHdr, "i)HTTP\/1.1 (200 OK|302 Found)")
	If (!binaryDL) {
		; Use fallback download if curl fails
		If ((not goodStatusCode or e.what) and useFallback) {
			DownloadFallback(url, html, e, critical, ioHdr, PreventErrorMsg)
		} Else If (not goodStatusCode and e.what) {
			ThrowError(e, false, ioHdr, PreventErrorMsg)
		}
	}
	; handle binary file downloads
	Else If (not e.what) {
		; check returned request headers
		ioHdr := ParseReturnedHeaders(html)
		If (not goodStatusCode) {
			MsgBox, 16,, % "Error downloading file to " SavePath
			Return "Error: Wrong Status"
		}
		
		; compare file sizes
		FileGetSize, sizeOnDisk, %SavePath%
		RegExMatch(ioHdr, "i)Content-Length:\s(\d+)", size)
		size := size1
		If (size != sizeOnDisk) {
			html := "Error: Different Size"
		}
	} Else {
		ThrowError(e, false, ioHdr, PreventErrorMsg)
	}
	
	Return html
}

ParseReturnedHeaders(output) {
	headerGroups	:= []
	headerGroup	:= ""
	
	Pos		:= 0
	While Pos := RegExMatch(output, "is)\[5 bytes data.*?({|$)", match, Pos + (StrLen(match) ? StrLen(match) : 1)) {
		headerGroups.push(match)
	}
		
	i := headerGroups.Length()
	Loop, % i {
		If (RegExMatch(headerGroups[i], "is)Content-Length")) {
			headerGroup := headerGroups[i]
			break
		}		
		i--
	}
	
	out := ""
	headerGroup := RegExReplace(headerGroup, "im)^<|\[5 bytes data\]|^{")
	Loop, parse, headerGroup, `n, `r 
	{
		If (StrLen(Trim(A_LoopField))) {
			out .= Trim(A_LoopField)
		}
	}
	
	Return out
}

; only works if no post data required/not downloading for example .zip files
DownloadFallback(url, ByRef html, e, critical, errorMsg, PreventErrorMsg = false) {
	ErrorLevel := 0
	fileName := RandomStr() . ".txt"
	
	UrlDownloadToFile, %url%, %A_ScriptDir%\temp\%fileName%
	If (!ErrorLevel) {
		FileRead, html, %A_ScriptDir%\temp\%fileName%
		FileDelete, %A_ScriptDir%\temp\%fileName%
	} Else If (!PreventErrorMsg) {
		SplashTextOff
		msg 		:= "Error while downloading <" url "> using UrlDownloadToFile (DownloadFallback)."
		errorMsg	:= StrLen(errorMsg) ? errorMsg "`n`n" msg : msg
		ThrowError(e, critical, errorMsg)
	}
}

ThrowError(e, critical = false, errorMsg = "", PreventErrorMsg = false) {
	If (PreventErrorMsg) {
		Return
	}
	
	msg := "Exception thrown (download)!"
	If (e.what) {
		msg .= "`n`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra	
	}
	msg := StrLen(errorMsg) ? msg "`n`n" errorMsg : msg
	
	If (critical) {
		MsgBox, 16,, % msg
	} Else {
		MsgBox, % msg
	}	
}

RandomStr(l = 24, i = 48, x = 122) { ; length, lowest and highest Asc value
	Loop, %l% {
		Random, r, i, x
		s .= Chr(r)
	}
	s := RegExReplace(s, "\W", "i") ; only alphanum.
	
	Return, s
}