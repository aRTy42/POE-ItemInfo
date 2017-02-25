PoEScripts_Download(url, ioData, ioHdr, options, useFallback = true, critical = false, binaryDL = false, errorMsg = "") {
	/*
		url		= download url
		postData	= postData 
		reqHeaders= multiple request headers separated by newline
		options	= multiple options separated by newline
		(take a look at WinHttpRequest.ahk)
		
		useFallback = Use UrlDownloadToFile if WinHttp fails, not possible for POST requests or when cookies are required 
		critical	= exit macro if download fails
		binaryDL	= file download (zip for example)
		errorMsg	= optional error message, will be added to default message
	*/

	e := {}
	Try {
		WinHttpRequest(url, ioData, ioHdr, options, Out_Headers_Obj)
		html := ioData
	} Catch e {
		
	}
	
	If (!binaryDL) {
		; Use fallback download if WinHttpRequest fails
		If ((StrLen(html) < 1 or not html or e.what) and useFallback) {
			DownloadFallback(url, html, e, critical, errorMsg)
		} Else If ((StrLen(html) < 1 or not html) and e.what) {
			ThrowError(e)
		} Else If ((StrLen(html) < 1 or not html)) {
			
		}
	}
	; handle binary file downloads
	Else If (InStr(Options, "SaveAs:") and not e.what) {
		; check http status
		If (Out_Headers_Obj["Status"] != 200) {
			MsgBox, 16,, % "Error downloading file. HTTP status: " Out_Headers_Obj["Status"] " " Out_Headers_Obj["Statustext"]
			Return "Error: Wrong Status"
		}
		
		RegExMatch(Options, "i)SaveAs:[ \t]*\K[^\r\n]+", SavePath)
		
		; compare file sizes
		FileGetSize, sizeOnDisk, %SavePath%
		size := Out_Headers_Obj["Content-Length"]
		If (size != sizeOnDisk) {
			html := "Error: Different Size"
		}
	} Else {
		ThrowError(e)
	}
	
	Return html
}

; only works if no post data required/not downloading for example .zip files
DownloadFallback(url, ByRef html, e, critical, errorMsg) {
	ErrorLevel := 0
	fileName := RandomStr() . ".txt"
	
	UrlDownloadToFile, %url%, %A_ScriptDir%\temp\%fileName%
	If (!ErrorLevel) {
		FileRead, html, %A_ScriptDir%\temp\%fileName%
		FileDelete, %A_ScriptDir%\temp\%fileName%
	} Else {
		SplashTextOff
		ThrowError(e, critical, errorMsg)
	}
}

ThrowError(e, critical = false, errorMsg = "") {
	msg := "Exception thrown (download)!"
	msg := StrLen(errorMsg) ? msg "`n`n" errorMsg : msg
	msg .= "`n`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra	
	
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