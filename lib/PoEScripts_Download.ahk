﻿PoEScripts_Download(url, ioData, ByRef ioHdr, options, useFallback = true, critical = false, binaryDL = false, errorMsg = "", ByRef reqHeadersCurl = "", handleAccessForbidden = true) {
	/*
		url		= download url
		ioData	= uri encoded postData 
		ioHdr	= array of request headers
		options	= multiple options separated by newline (currently only "SaveAs:",  "Redirect:true/false")
		
		useFallback = Use UrlDownloadToFile if curl fails, not possible for POST requests or when cookies are required 
		critical	= exit macro if download fails
		binaryDL	= file download (zip for example)
		errorMsg	= optional error message, will be added to default message
		reqHeadersCurl = returns the returned headers from the curl request 
		handleAccessForbidden = "true" throws an error message if "403 Forbidden" is returned, "false" prevents it, returning "403 Forbidden" to enable custom error handling
	*/
	
	; https://curl.haxx.se/download.html -> https://bintray.com/vszakats/generic/curl/
	curl		:= """" A_ScriptDir "\lib\curl.exe"" "	
	headers	:= ""
	cookies	:= ""
	For key, val in ioHdr {
		val := Trim(RegExReplace(val, "i)(.*?)\s*:\s*(.*)", "$1:$2"))
		headers .= "-H """ val """ "
		
		If (RegExMatch(val, "i)^Cookie:(.*)", cookie)) {
			cookies .= cookie1 " "		
		}
	}	
	cookies := StrLen(cookies) ? "-b """ Trim(cookies) """ " : ""
	
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
		commandData	:= ""		; console curl command to return data/content 
		commandHdr	:= ""		; console curl command to return headers
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
			If (StrLen(cookies)) {
				commandData .= cookies
				commandHdr  .= cookies
			}
		}
		If (StrLen(ioData)) {
			commandData .= "--data """ ioData """ "
		}

		; get data
		html	:= StdOutStream(curl """" url """" commandData)
		;html := ReadConsoleOutputFromFile(commandData """" url """", "commandData") ; alternative function
		
		; get return headers in seperate request
		If (not binaryDL) {
			If (StrLen(ioData)) {
				commandHdr := curl """" url "?" ioData """" commandHdr		; add payload to url since you can't use the -I argument with POST requests
			} Else {
				commandHdr := curl """" url """" commandHdr
			}
			ioHdr := StdOutStream(commandHdr)
			;ioHrd := ReadConsoleOutputFromFile(commandHdr, "commandHdr") ; alternative function
		}
		reqHeadersCurl := commandHdr
	} Catch e {
		
	}

	goodStatusCode := RegExMatch(ioHdr, "i)HTTP\/1.1 (200 OK|302 Found)")
	If (RegExMatch(ioHdr, "i)HTTP\/1.1 403 Forbidden") and not handleAccessForbidden) {
		PreventErrorMsg		:= true
		handleAccessForbidden	:= "403 Forbidden"
	}
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
		goodStatusCode := RegExMatch(ioHdr, "i)HTTP\/1.1 (200 OK|302 Found)")
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
		errorMsg	:= StrLen(errorMsg) ? msg "`n`n" errorMsg : msg
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
	
	If (RegExMatch(errorMsg, "i)HTTP\/1.1 403 Forbidden")) {
		cookiesRequired := "Access forbidden, a likely reason for this is that necessary cookies are missing.`nYou may have to use"
	}
	msg := StrLen(cookiesRequired) ? msg "`n`n" cookiesRequired : msg
	
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