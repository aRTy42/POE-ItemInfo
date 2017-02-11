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
		versions := ParseVersionStringsToObject(releaseTag, ReleaseVersion)

		description := RegExReplace(description, "iU)\\""", """")
		StringReplace, description, description, \r\n, §, All 
		StringReplace, description, description, \n, §, All 
		
		newRelease := CompareVersions(versions.latest, versions.current)
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
			
			currentLabel := versions.current.label
			latestLabel  := versions.latest.label
			
			Gui, UpdateNotification:Font,, Consolas			
			Gui, UpdateNotification:Add, Text, x100 yp+0,  %currentLabel%			
			Gui, UpdateNotification:Font,,
			
			Gui, UpdateNotification:Add, Link, x+20 yp+0 cBlue, <a href="%releaseURL%">Download it here</a>        
			Gui, UpdateNotification:Add, Text, x20 y+0, Latest version:
			
			Gui, UpdateNotification:Font,, Consolas	
			Gui, UpdateNotification:Add, Text, x100 yp+0,  %latestLabel%
			Gui, UpdateNotification:Font,,
			
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

CompareVersions(latest, current) {
	; new release available if latest is higher than current
	versionHigher 		:= false
	subVersionHigher 	:= false
	
	If (not latest.major and not current.major) {
		Return false
	}
	Else {
		equal := latest.major . latest.minor . latest.patch . "" == current.major . current.minor . current.patch . ""

		If (RemoveLeadingZeros(latest.major) > RemoveLeadingZeros(current.major)) {
			versionHigher := true
		}
		Else If (RemoveLeadingZeros(latest.minor) > RemoveLeadingZeros(current.minor)) {
			versionHigher := true
		}
		Else If (RemoveLeadingZeros(latest.patch) > RemoveLeadingZeros(current.patch)) {
			versionHigher := true
		}
		
		If (latest.subVersion.priority or current.subVersion.priority) {
			If (current.subVersion.priority and latest.fullRelease) {
				subVersionHigher := false
			}
			Else If (latest.subVersion.priority > current.subVersion.priority) {
				subVersionHigher := true
			}
			Else If (RemoveLeadingZeros(latest.subVersion.patch) > RemoveLeadingZeros(current.subVersion.patch)) {
				subVersionHigher := true
			}
		}

		
		If (equal and latest.fullRelease and not current.fullRelease) {
			Return true
		}
		Else If (equal and not subVersionHigher) {
			Return false
		}
		Else If (versionHigher) {
			Return true
		}
		Else If (subVersionHigher) {
			Return true
		}
		Else {
			Return false
		}
	}
}

RemoveLeadingZeros(in) {
	Return LTrim(in, "0")
}

ParseVersionStringsToObject(latest, current) {
     ; requires valid semantic versioning
	; x.x.x
	; x.x.x-alpha.x
	; also possible: beta, rc
	; priority: normal release (no sub version) > rc > beta > alpha
	RegExMatch(latest, "(\d+).(\d+).(\d+)(.*)", latestVersion)
	RegExMatch(current, "(\d+).(\d+).(\d+)(.*)", currentVersion)

	If (StrLen(latest) < 1) {
		MsgBox, 16,, % "Exception thrown! Parsing release information from Github failed."
	}
	
	versions := {}
	versions.latest  := {}
	versions.current := {}

	RegExMatch(latestVersion4,  "i)(rc|beta|alpha)(.?(\d+)(.*)?)?", match_latest)
	RegExMatch(currentVersion4, "i)(rc|beta|alpha)(.?(\d+)(.*)?)?", match_current)

	temp := ["latest", "current"]
	For key, val in temp {
		versions[val].major := %val%Version1
		versions[val].minor := %val%Version2
		versions[val].patch := %val%Version3
		versions[val].label := %val%Version

		If (match_%val%) {	
			versions[val].subVersion := {}
			versions[val].subVersion.identifier:= match_%val%1
			versions[val].subVersion.priority	:= GetVersionIdentifierPriority(versions[val].subVersion.identifier)
			versions[val].subVersion.patch	:= match_%val%3	
		}
		
		versions[val].fullRelease := StrLen(match_%val%) < 1 ? true : false
	}
	
	Return versions
}

GetVersionIdentifierPriority(identifier) {
	If (identifier = "rc") {
		Return 3
	} Else If (identifier = "beta") {
		Return 2
	} Else If (identifier = "alpha") {
		Return 1
	} Else {
		Return 0
	}
}

CloseUpdateWindow:
	Gui, Cancel
Return