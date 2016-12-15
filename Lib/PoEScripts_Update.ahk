PoEScripts_Update(user, repo, ReleaseVersion, ShowUpdateNotification) {
	GetLatestRelease(user, repo, ReleaseVersion, ShowUpdateNotification)
	;MsgBox Hey, this LibFunction handles update checks and updates
}

GetLatestRelease(user, repo, ReleaseVersion, ShowUpdateNotification) {
	If (ShowUpdateNotification = 0) {
		return
	}
	HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	url := "https://api.github.com/repos/" . user . "/" . repo . "/releases/latest"
	
	Try  {
		Encoding := "utf-8"
		HttpObj.Open("GET",url)
		HttpObj.SetRequestHeader("Content-type","application/html")
		HttpObj.Send("")
		HttpObj.WaitForResponse()   
		html := HttpObj.ResponseText
		
		If Encoding {
			oADO          := ComObjCreate("adodb.stream")
			oADO.Type     := 1
			oADO.Mode     := 3
			oADO.Open()
			oADO.Write( HttpObj.ResponseBody)
			oADO.Position := 0
			oADO.Type     := 2
			oADO.Charset  := Encoding
			html := oADO.ReadText()
			oADO.Close()
		}
		
		RegExMatch(html, "i)""tag_name"":""(.*?)""", tag)
		RegExMatch(html, "i)""name"":""(.*?)""", vName)
		RegExMatch(html, "i)""html_url"":""(.*?)""", url)
		
		tag := tag1
		vName := vName1
		url := url1    
		
		RegExReplace(tag, "^v", tag)
          ; works only in x.x.x format
		RegExMatch(tag, "(\d+).(\d+).(\d+)(.*)", latestVersion)
		RegExMatch(ReleaseVersion, "(\d+).(\d+).(\d+)(.*)", currentVersion)
		RegExMatch(html,  "i)""body"":""(.*?)""", description)
		StringReplace, description, description1, \r\n, ~, All 

		newRelease := false
		Loop {			
			If (not latestVersion%A_Index% and not currentVersion%A_Index%) {
				break
			}
			Else If (latestVersion%A_Index% > currentVersion%A_Index%) {
				;MsgBox % latestVersion%A_Index% "`n" currentVersion%A_Index%
				newRelease := true
			}			
		}

		If (newRelease) {
			Gui, UpdateNotification:Add, Text, cGreen, Update available!
			Gui, UpdateNotification:Add, Text, , Your installed version is <%currentVersion%>.`nThe latest version is <%latestVersion%>.
			Gui, UpdateNotification:Add, Link, cBlue, <a href="%url%">Download it here</a>        
			
			Loop, Parse, description, ~
				Gui, UpdateNotification:Add, Text, w320, % "- " A_LoopField
			
			Gui, UpdateNotification:Add, Button, gCloseUpdateWindow, Close
			yPos := A_ScreenHeight / 2 + 40
			Gui, UpdateNotification:Show, w400 Y%yPos%, Update 
			ControlFocus, Close, Update
			WinWaitClose, Update
		}
	} Catch e {
		MsgBox % "Update-Check failed, Github is probably down."
	}
	Return
}

CloseUpdateWindow:
	Gui, Cancel
Return