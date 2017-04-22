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

urls := ["https://api.github.com/repos/PoE-TradeMacro/PoE-TradeMacro/releases", "http://poe.trade", "http://poe.trade/search/seridonomosure"]

Loop, % urls.MaxIndex() {
	HttpObj 	:= ComObjCreate("WinHttp.WinHttpRequest.5.1")
	url			:= urls[A_Index]
	
	console.log("---------------------------------------------------`nDownload test with url : " url)
	
	UrlDownloadToFile, %url%, %A_ScriptDir%\test_temp\urlDownloadToFile%A_Index%_output.txt
	If (!ErrorLevel) {
		FileRead, file, %A_ScriptDir%\test_temp\urlDownloadToFile%A_Index%_output.txt
		console.log("Testing UrlDownloadToFile: No errors.`n Output saved in: " A_ScriptDir "\test_temp\urlDownloadToFile" A_Index "_output.txt" "`nContent Length: " StrLen(file))
	} Else {
		console.log("Testing UrlDownloadToFile: Failed.`nTried saving output to " A_ScriptDir "\test_temp\urlDownloadToFile" A_Index "_output.txt")
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
			console.log("First test downloading to variable using WinHTTP adodb.stream successful. (Catching Errors)" "`nContent Length: " StrLen(html))
		} Else {
			console.log("First test downloading to variable using WinHTTP adodb.stream returned an empty string.")
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
		console.log("Second test downloading to variable using WinHTTP adodb.stream successful. (Not catching Errors)" "`nContent Length: " StrLen(html))	
	} Else {
		console.log("Second test downloading to variable using WinHTTP adodb.stream returned an empty string.")
	}
	console.log("-----------------------------------------")
}