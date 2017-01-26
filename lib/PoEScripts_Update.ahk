#Include, %A_ScriptDir%\lib\JSON.ahk
#Include, %A_ScriptDir%\lib\DebugPrintArray.ahk

PoEScripts_Update(user, repo, ReleaseVersion, ShowUpdateNotification, SplashScreenTitle = "") {
	GetLatestRelease(user, repo, ReleaseVersion, ShowUpdateNotification, SplashScreenTitle)
}

GetLatestRelease(user, repo, ReleaseVersion, ShowUpdateNotification, SplashScreenTitle = "") {
	If (ShowUpdateNotification = 0) {
		return
	}
	HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	url := "https://api.github.com/repos/" . user . "/" . repo . "/releases"
	downloadUrl := "https://github.com/" . user . "/" . repo . "/releases"
	
	Try  {
		Encoding := "utf-8"
		HttpObj.Open("GET",url)
		HttpObj.SetRequestHeader("Content-type","application/html")
		HttpObj.Send("")
		HttpObj.WaitForResponse()

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
		} Catch e {			
			html := HttpObj.ResponseText
			If (TradeOpts.Debug) {
				MsgBox, 16,, % "Exception thrown!`n`nwhat: " e.what "`nfile: " e.file	"`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
			}
		}
		
		parsedJSON := JSON.Load(html)
		LatestRelease := {}		
		For key, val in parsedJSON {
			If (not val.draft) {
				LatestRelease := val				
				Break
			}
		}
		
		; get download link to zip files (normal release zip and asset zip file)
		downloadURL_zip := LatestRelease.zipball_url
		If (LatestRelease.assets.Length()) {
			For key, val in LatestRelease.assets {
				If (val.content_type = "application/zip") {
					downloadURL_asset := val.browser_download_url
				}
			}
		}
		
		isPrerelease:= LatestRelease.prerelease
		releaseTag  := LatestRelease.tag_name
		releaseURL  := downloadUrl . "/tag/" . releaseTag
		publisedAt  := LatestRelease.published_at
		description := LatestRelease.body
		
		RegExReplace(releaseTag, "^v", releaseTag)
          ; works only in x.x.x format (valid semantic versioning)
		RegExMatch(releaseTag, "(\d+).(\d+).(\d+)(.*)", latestVersion)
		RegExMatch(ReleaseVersion, "(\d+).(\d+).(\d+)(.*)", currentVersion)
		
		If (StrLen(releaseTag) < 1) {
			MsgBox, 16,, % "Exception thrown! Parsing release information from Github failed."
		}
		
		description := RegExReplace(description, "iU)\\""", """")
		StringReplace, description, description, \r\n, §, All 
		StringReplace, description, description, \n, §, All 
		
		newRelease := false
		Loop {			
			If (not latestVersion%A_Index% and not currentVersion%A_Index%) {
				break
			}
			Else If (latestVersion%A_Index% > currentVersion%A_Index%) {
				newRelease := true
			}			
		}

		If (newRelease) {
			If(SplashScreenTitle) {
				WinSet, AlwaysOnTop, Off, %SplashScreenTitle%	
			}
			;Gui, UpdateNotification:Add, Text, cGreen, Update available!
			boxHeight := isPrerelease ? 80 : 60
			Gui, UpdateNotification:Add, GroupBox, w380 h%boxHeight% cGreen, Update available!
			If (isPrerelease) {
				Gui, UpdateNotification:Add, Text, x20 yp+20, Warning: This is a pre-release.
				Gui, UpdateNotification:Add, Text, x20 y+10, Installed version:
			} Else {
				Gui, UpdateNotification:Add, Text, x20 yp+20, Installed version:
			}

			Gui, UpdateNotification:Add, Text, x100 yp+0, <%currentVersion%>.
			Gui, UpdateNotification:Add, Link, x+20 yp+0 cBlue, <a href="%releaseURL%">Download it here</a>        
			Gui, UpdateNotification:Add, Text, x20 y+0, Latest version:
			Gui, UpdateNotification:Add, Text, x100 yp+0, <%latestVersion%>.			
			
			Gui, UpdateNotification:Add, Text, x10 cGreen, Update notes:		
			Loop, Parse, description, §
			{
				If(StrLen(A_LoopField) > 1) {
					Gui, UpdateNotification:Add, Text, w320 x10 y+5, % "- " A_LoopField				
				}
			}
			
			Gui, UpdateNotification:Add, Button, gCloseUpdateWindow, Close
			Gui, UpdateNotification:Show, w400 xCenter yCenter, Update 
			ControlFocus, Close, Update
			WinWaitClose, Update
		}
	} Catch e {
		MsgBox,,, % "Update-Check failed, Exception thrown!`n`nwhat: " e.what "`nfile: " e.file	"`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
	}
	Return
}

CloseUpdateWindow:
	Gui, Cancel
Return