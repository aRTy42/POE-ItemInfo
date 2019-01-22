PoEScripts_CheckInvalidScriptFolder(currentDir, project, critical = false) {
	valid := true
	
	SplitPath, currentDir, FileName, Dir, Extension, NameNoExt, Drive

	msg := ""
	If (InStr(currentDir, A_Desktop)) {
		valid := false
		msg := "your Desktop (or any of its subfolders)"
	}
	If (currentDir = drive) {
		valid := false
		msg := "any drive root"
	}
	
	If (not valid) {
		msg := "Executing " project " from " msg " may cause script or permission errors, please choose a different directory."
		msg .= "`n`n" "Current script directory: """ currentDir """"		
		
		If (not critical) {
			msg .= "`n`n" "Do not report this! Just ignore it or move your script folder to somewhere else."
			msg .= "`n`n" "The script will continue to execute but it is highly recommended to use a different path."
			Msgbox, 0x1030, %project% Problematic Installation Path, % msg
		} Else {
			SplashTextOff
			SplashUI.DestroyUI()
			msg .= "`n`n" "Do not report this, it is intended behaviour! Move your script folder to somewhere else!"
			Msgbox, 0x1010, %project% Invalid Installation Path, % msg
		}	

		If (critical) {
			ExitApp
		}
	}
}