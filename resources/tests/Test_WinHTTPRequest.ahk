#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background

SetWorkingDir, %A_ScriptDir%
#Include, %A_ScriptDir%\..\..\lib\JSON.ahk
#Include, %A_ScriptDir%\..\..\lib\Class_Console.ahk
#Include, %A_ScriptDir%\..\..\lib\DebugPrintArray.ahk

FileRemoveDir, %A_ScriptDir%\test_temp, 1
FileCreateDir, %A_ScriptDir%\test_temp

Class_Console("console",0,335,600,900,,,,9)
console.show()

HttpObj 	:= ComObjCreate("WinHttp.WinHttpRequest.5.1")
url 		:= "https://api.github.com/repos/PoE-TradeMacro/PoE-TradeMacro/releases"
downloadUrl := "https://github.com/PoE-TradeMacro/PoE-TradeMacro/releases"

UrlDownloadToFile, %url%, %A_ScriptDir%\test_temp\urlDownloadToFile_output.txt
If (!ErrorLevel) {
	console.log("Testing UrlDownloadToFile: No errors.`n Output saved in: " A_ScriptDir "\test_temp\urlDownloadToFile_output.txt")
} Else {
	console.log("Testing UrlDownloadToFile: Failed.`nTried saving output to " A_ScriptDir "\test_temp\urlDownloadToFile_output.txt")
}

Encoding := "utf-8"
HttpObj.Open("GET",url)
HttpObj.SetRequestHeader("Content-type","application/html")
HttpObj.Send("")
HttpObj.WaitForResponse()


; Test with catching errors
Try {				
	If Encoding {
		oADO          := ComObjCreate("adodb.stream")
		oADO.Type     := 1
		oADO.Mode     := 3
		oADO.Open()
		oADO.Write(HttpObj.ResponseBody)
		oADO.Position := 0
		oADO.Type     := 2
		oADO.Charset  := Encoding
		html := oADO.ReadText()
		oADO.Close()
	}
	If (StrLen(html) > 0) {
		console.log("First test downloading to variable using WinHTTP adodb.stream successful.")	
	} Else {
		console.log("First test downloading to variable using WinHTTP adodb.stream returned empty string.")
	}
} Catch e {
	console.log("Exception thrown!`n`nwhat: " e.what "`nfile: " e.file	"`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra)
}

; Test without catching errors
If Encoding {
	oADO          := ComObjCreate("adodb.stream")
	oADO.Type     := 1
	oADO.Mode     := 3
	oADO.Open()
	oADO.Write(HttpObj.ResponseBody)
	oADO.Position := 0
	oADO.Type     := 2
	oADO.Charset  := Encoding
	html := oADO.ReadText()
	oADO.Close()
}

If (StrLen(html) > 0) {
	console.log("Second test downloading to variable using WinHTTP adodb.stream successful.")	
} Else {
	console.log("Second test downloading to variable using WinHTTP adodb.stream returned empty string.")
}