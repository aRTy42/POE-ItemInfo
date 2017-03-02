#Include, %A_ScriptDir%\lib\JSON.ahk
#Include, %A_ScriptDir%\lib\zip.ahk
#Include, %A_ScriptDir%\lib\WinHttpRequest.ahk

PoEScripts_Update(user, repo, ReleaseVersion, ShowUpdateNotification, userDirectory, isDevVersion, skipSelection, skipBackup, SplashScreenTitle = "") {
	status := GetLatestRelease(user, repo, ReleaseVersion, ShowUpdateNotification, userDirectory, isDevVersion, skipSelection, skipBackup, SplashScreenTitle)
	Return status
}

GetLatestRelease(user, repo, ReleaseVersion, ShowUpdateNotification, userDirectory, isDevVersion, skipSelection, skipBackup, SplashScreenTitle = "") {
	If (ShowUpdateNotification = 0) {
		return
	}
	HttpObj		:= ComObjCreate("WinHttp.WinHttpRequest.5.1")
	url			:= "https://api.github.com/repos/" . user . "/" . repo . "/releases"
	downloadUrl	:= "https://github.com/" . user . "/" . repo . "/releases"
	html			:= ""
	
	postData		:= ""
	reqHeaders =
		(LTrim
			Content-type: application/html
		)
	options =
		(LTrim
			Charset: UTF-8
			Codepage: 65001
			Method: GET
		)
	
	Try  {
		errorMsg	:= "Update check failed. Please check manually on the Github page for updates.`nThe script will now continue."
		html 	:= PoEScripts_Download(url, ioData := postData, ioHdr := reqHeaders, options, true, false, false, errorMsg)
		
		If (StrLen(html) < 1) {	
			; all download errors should have been catched and handled by the download functions
			; exit the update check to skip all additional error handling
			return
		}	
		
		parsedJSON	:= JSON.Load(html)
		LatestRelease	:= {}
		LastXReleases	:= []
		updateNotes	:= ""
		i := 0
		showReleases	:= 5
		For key, val in parsedJSON {
			i++
			If (i <= showReleases) {
				tempObj := {}
				tempObj.notes 		:= ParseDescription(val.body)
				tempObj.tag 		:= val.tag_name
				tempObj.published 	:= ParsePublishDate(val.published_at)
				tempObj.textBlock 	:= CreateTextBlock(tempObj.notes, tempObj.published, tempObj.tag)
				updateNotes 		.= tempObj.textBlock
				LastXReleases.push(tempObj)
			}
		}
		For key, val in parsedJSON {			
			If (not val.draft) {
				LatestRelease := val				
				Break
			}
		}

		; get download link to zip files (normal release zip and asset zip file)
		UrlParts := StrSplit(LatestRelease.zipball_url, "/")
		downloadFile 		:= UrlParts[UrlParts.MaxIndex()] . ".zip"
		downloadURL_zip 	:= "https://github.com/" . user . "/" . repo . "/archive/" . downloadFile
		downloadURL_asset 	:= ""
		If (LatestRelease.assets.MaxIndex()) {
			For key, val in LatestRelease.assets {
				If (InStr(val.content_type, "zip")) {
					downloadURL_asset := val.browser_download_url
				}
			}
		}
		
		global updateWindow_Project 		:= repo
		global updateWindow_DefaultFolder	:= A_ScriptDir
		global updateWindow_isDevVersion	:= isDevVersion
		global updateWindow_downloadURL	:= StrLen(downloadURL_asset) ? downloadURL_asset : downloadURL_zip
		global updateWindow_skipSelection	:= skipSelection
		global updateWindow_skipBackup	:= skipBackup

		isPrerelease:= LatestRelease.prerelease
		releaseTag  := LatestRelease.tag_name
		releaseURL  := downloadUrl . "/tag/" . releaseTag
		publisedAt  := LatestRelease.published_at
		description := LatestRelease.body
		
		RegExReplace(releaseTag, "^v", releaseTag)
		versions		:= ParseVersionStringsToObject(releaseTag, ReleaseVersion)
		
		newRelease := CompareVersions(versions.latest, versions.current)
		If (newRelease) {
			If(SplashScreenTitle) {
				WinSet, AlwaysOnTop, Off, %SplashScreenTitle%
			}
			Gui, UpdateNotification:Font,, Consolas
			
			boxHeight := isPrerelease ? 80 : 60
			Gui, UpdateNotification:Add, GroupBox, w580 h%boxHeight% cGreen, Update available!			
			If (isPrerelease) {
				Gui, UpdateNotification:Add, Text, x20 yp+20, Warning: This is a pre-release.
				Gui, UpdateNotification:Add, Text, x20 y+10, Installed version:
			} Else {
				Gui, UpdateNotification:Add, Text, x20 yp+20, Installed version:
			}
			
			currentLabel := versions.current.label
			latestLabel  := versions.latest.label
			
			Gui, UpdateNotification:Add, Text, x150 yp+0,  %currentLabel%	
			
			Gui, UpdateNotification:Add, Text, x20 y+0, Latest version:
			
			Gui, UpdateNotification:Add, Text, x150 yp+0,  %latestLabel%
			Gui, UpdateNotification:Add, Link, x+20 yp+0 cBlue, <a href="%releaseURL%">Download it here</a>
			Gui, UpdateNotification:Add, Button, x+20 yp-5 gUpdateScript, Update
			
			Gui, UpdateNotification:Add, Text, x10 cGreen, Update notes:
			Gui, UpdateNotification:Add, Edit, r20 ReadOnly w580 BackgroundTrans, %updateNotes%
			
			Gui, UpdateNotification:Add, Button, gCloseUpdateWindow, Close
			Gui, UpdateNotification:Show, w600 xCenter yCenter, Update 
			ControlFocus, Update, Update
			WinWaitClose, Update
		}
		Else {
			s := "no update"
			Return s
		}
	} Catch e {
		SplashTextOff
		MsgBox,,, % "Update-Check failed, Exception thrown!`n`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
	}
	
	Return
}

ParseDescription(description) {
	description := RegExReplace(description, "iU)\\""", """")
	StringReplace, description, description, \r\n, §, All 
	StringReplace, description, description, \n, §, All

	Return description
}

ParsePublishDate(date) {	
	TimeStr := RegExReplace(date, "i)-|T|:|Z")	
	FormatTime, TimeStr, %TimeStr%, ShortDate
	Return TimeStr
}

CreateTextBlock(description, date, tag) {
	block := "-----------------------------------------------------------------------------------------" . "`n"
	block .= "[" . date . "]  Version: " . tag . "`n"
	block .= "-----------------------------------------------------------------------------------------" . "`n"
	block .= description . "`n`n"
	
	Return block
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
		
		Loop,  1 {
			majorSmaller := RemoveLeadingZeros(latest.major) < RemoveLeadingZeros(current.major)
			If (RemoveLeadingZeros(latest.major) > RemoveLeadingZeros(current.major)) {
				versionHigher := true
				break
			}
			
			minorSmaller := RemoveLeadingZeros(latest.minor) < RemoveLeadingZeros(current.minor)
			If (RemoveLeadingZeros(latest.minor) > RemoveLeadingZeros(current.minor) and not majorSmaller) {
				versionHigher := true
				break
			}
			
			If (RemoveLeadingZeros(latest.patch) > RemoveLeadingZeros(current.patch) and not (minorSmaller or majorSmaller)) {
				versionHigher := true
				break
			}
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
		Else If (subVersionHigher and not current.fullRelease) {
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

UpdateScript(url, project, defaultDir, isDevVersion, skipSelection, skipBackup) {	
	prompt := "Please select the folder you want to install/extract " project " to.`n"
	prompt .= "Selecting an existing folder will ask for confirmation and will back up that folder, for example 'MyFolder_backup'."
	
	defaultFolder := RegExReplace(defaultDir, "i)[^\\]+$", "")
	; append '_devUpdate' to the folder if it's a development version (.git folder exists)
	defaultFolder := StrLen(isDevVersion) > 0 ? defaultFolder . project . "_devUpdate" : defaultFolder . project
	; check for equality but ignore case sensitivity (prefer current script dir)
	defaultFolder := (defaultFolder != defaultDir) ? defaultFolder : defaultDir
	
	; create dev folder if it doesn't exist, remove it later if not used
	createdFolder := false
	If (!InStr(FileExist(defaultFolder), "D")) {
		createdFolder := true
		FileCreateDir, %defaultFolder%
	}
	
	If (not skipSelection) {
		FileSelectFolder, InstallPath, *%defaultFolder%, 1, %prompt%
	} Else {
		InstallPath := defaultFolder
	}
	
	If (ErrorLevel) {
		; dialog canceled, do nothing
		Return
	} 
	If (InstallPath = ) {
		MsgBox, You didn't select a folder.
		Return
	}	    
	Else {		
		; remove created dev folder if unused
		If (createdFolder and defaultFolder != InstallPath) {
			FileRemoveDir, %defaultFolder%, 1
		}
		
		; check if install folder is readonly/temporary or an invalid location
		validPath := CheckForValidInstallFolder(InstallPath)
		If (!validPath) {
			Return
		}

		; check if install folder is empty 
		If (not IsEmpty(InstallPath)) {
			If (not skipBackup) {
				MsgBox, 4,, Folder (%InstallPath%) is not empty, overwrite it after making a backup?
				IfMsgBox Yes 
				{			
					Gui, Cancel
					; remove backup folder if it already exists
					If (InStr(FileExist(InstallPath "_backup"), "D")) {
						FileRemoveDir, %InstallPath%_backup, 1
					}
					FileMoveDir, %InstallPath%, %InstallPath%_backup, R  ; Simple rename.
				}
				IfMsgBox No 
				{
					Return
				}
			}
			Else {
				Gui, Cancel
			}
		}
		Else {		
			Gui, Cancel
		}
		
		savePath := "" ; ByRef
		If (DownloadRelease(url, project, savePath)) {
			folderName := ExtractRelease(savePath, project)			
			If (StrLen(folderName)) {
				; successfully downloaded and extracted release.zip to %A_Temp%\%Project%\ext
				; copy script to %A_Temp%\%Project%
				SplitPath, savePath, , saveDir
				externalScript := saveDir . "\PoEScripts_FinishUpdate.ahk"
				FileCopy, %A_ScriptDir%\lib\PoEScripts_FinishUpdate.ahk, %externalScript%, 1
				
				; try to run the script and exit the app
				; this needs to be done so that we can overwrite the current scripts directory
				If (FileExist(externalScript)) {
					Run "%A_AhkPath%" "%externalScript%" "%A_ScriptDir%" "%folderName%" "%InstallPath%" "%project%"
					If (ErrorLevel) {
						MsgBox Update failed, couldn't launch 'FinishUpdate' script. File not found.
					}
				}
				Else {
					MsgBox Update failed, couldn't launch 'FinishUpdate' script.
				}				
				ExitApp
			}
		}		
	}
}

CheckForValidInstallFolder(path, ByRef r = "", ByRef t = ""){
	; http://www.installmate.com/support/im9/using/symbols/functions/csidls.htm
	; https://autohotkey.com/board/topic/9399-function-getcommonpath-get-path-to-standard-system-folder/
	IfInString, Attributes, T	; temporary
	{
		t := "temporary"
	}
	IfInString, Attributes, R	; readonly
	{
		r := "readonly"
	}
	
	If (Strlen(r) > 0 or StrLen(t) > 0) {
		s := r 
		s := StrLen(r) > 0 ? " and " t : t
		msg := path " is a " s " folder. `n`nUpdate cancelled."
		MsgBox % msg
		Return false
	}
	
	; could also use ahk variables like A_Temp, this should be a bit more flexible and has more possible paths
	CSIDL := {}
	CSIDL.FONTS				:= "0x0014"	; C:\Windows\Fonts 
	CSIDL.LOCAL_APPDATA			:= "0x001C"	; non roaming, user\Local Settings\Application Data
	CSIDL.MYMUSIC				:= "0x000d"	; "My Music" folder 
	CSIDL.MYPICTURES			:= "0x0027"	; My Pictures, new for Win2K 
	CSIDL.PERSONAL				:= "0x0005"	; My Documents 
	CSIDL.PROGRAM_FILES_COMMON	:= "0x002b"	; C:\Program Files\Common 
	CSIDL.PROGRAM_FILES			:= "0x0026"	; C:\Program Files 		
	CSIDL.PROGRAM_FILES_COMMONX86	:= "0x2C"		; C:\Program Files\Common 
	CSIDL.PROGRAM_FILESX86		:= "0x2A"		; C:\Program Files 
	CSIDL.PROGRAMS				:= "0x0002"	; C:\Documents and Settings\username\Start Menu\Programs 
	CSIDL.RESOURCES			:= "0x0038"	; %windir%\Resources\, For theme and other windows resources. 
	CSIDL.STARTMENU			:= "0x000b"	; C:\Documents and Settings\username\Start Menu 
	CSIDL.STARTUP				:= "0x0007"	; C:\Documents and Settings\username\Start Menu\Programs\Startup. 
	CSIDL.SYSTEM				:= "0x0025"	; GetSystemDirectory() 
	CSIDL.SYSTEMX86			:= "0x29"		; GetSystemDirectory() 
	CSIDL.WINDOWS				:= "0x0024"	; GetWindowsDirectory()
	CSIDL.DRIVES				:= "0x0011"
	CSIDL.DESKTOP				:= "0x0000"
	CSIDL.DESKTOPDIRECTORY		:= "0x0010"
	CSIDL.DESKTOPDIRECTORY		:= "0x0010"
	
	invalid := false
	For key, val in CSIDL {		
		invalidPath := GetCommonPath(val)
		If (path = invalidPath) {			
			invalid := true
			Break
		}
	}
	
	SplitPath, path, , , , , f_drive
	If (path = f_drive "\") {
		invalid := true
	}	
	
	If (invalid) {
		msg := "< " path " > is not a valid install location. Please choose a different location or create a sub folder. `n`nUpdate cancelled."
		MsgBox % msg 
		Return false
	}
	
	Return true
}

GetCommonPath(csidl) {
	val := csidl
	VarSetCapacity(fpath, 256) 
	DllCall( "shell32\SHGetFolderPath", "uint", 0, "int", val, "uint", 0, "int", 0, "str", fpath)
	return %fpath% 
}

DownloadRelease(url, project, ByRef savePath) {	
	SplashTextOn, 300, 20, %project% update, Downloading .zip archive...
	
	savePath := A_Temp . "\" . project . "\" . "release.zip"
	If (!InStr(FileExist(A_Temp "\" project), "D")) {
		FileCreateDir, %A_Temp%\%project%
	}
	
	postData := ""
	reqHeaders =
		(LTrim
			Content-type: application/octet-stream
			User-Agent: %project%
		)
	options =
		(LTrim
			Charset: UTF-8
			Codepage: 65001
			SaveAs: %savePath%
			Method: GET
		)	
	response := PoEScripts_Download(url, ioData := postData, ioHdr := reqHeaders, options, true, true, true)
	SplashTextOff
	
	If (response == "Error: Wrong Status") {
		Return False
	}
	
	If (response == "Error: Different Size") {
		MsgBox, 5,, % "Error: size of downloaded file is incorrect.`n`nUpdate has been cancelled."
		IfMsgBox, Retry
		{
			DownloadRelease(URL, project, savePath)			
		}
		IfMsgBox, Cancel 
		{
			Return False	
		}
	}	
	
	Return True
}

ExtractRelease(file, project) {
	SplitPath, file, f_name, f_dir, f_ext, f_name_no_ext, f_drive
	sUnz := f_dir "\ext"  ; Directory to unzip files	
	; empty extraction sub-directory
	Try {
		FileRemoveDir, %sUnz%, 1	
	} Catch e {
		
	}
	FileCreateDir, %sUnz%
	
	; extract release.zip
	SplashTextOn, 300, 20, %project% update, Extracting downloaded .zip archive...
	Extract2Folder(file,sUnz)
	SplashTextOff
	
	; find folder name of extracted archive (to be sure we know the right one)
	Number := 0
	Loop, %sUnz%\*, 1, 0
	{
		folderName = %A_LoopFileLongPath%
		Number++
	}
	
	; zip archive was extracted directly into the folder, not by creating a sub folder first
	If (Number > 1) {
		folderName := sUnz
	}
	
	Return folderName
}

IsEmpty(Dir){
	Loop %Dir%\*.*, 0, 1
		return 0
	return 1
}

CloseUpdateWindow:
	Gui, Cancel
Return

UpdateScript:
	UpdateScript(updateWindow_downloadURL, updateWindow_Project, updateWindow_DefaultFolder, updateWindow_isDevVersion, updateWindow_skipSelection, updateWindow_skipBackup)	
Return