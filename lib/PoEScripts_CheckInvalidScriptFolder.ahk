PoEScripts_CheckInvalidScriptFolder(currentDir, project, critical = true) {
	valid := true
	
	SplitPath, currentDir, FileName, Dir, Extension, NameNoExt, Drive
	
	;msgbox % currentDir "`n" filename  "`n" dir  "`n" extension "`n" namenoext "`n" drive  "`n"  "`n" A_Desktop  "`n" A_ScriptDir "`n" A_ScriptName "`n" 
	
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
			msg .= "`n`n" "The script will continue to execute but it is highly recommended to use a different path."
			Msgbox, 0x1010, %project% Problematic Installation Path, % msg
		} Else {
			SplashTextOff
			Msgbox, 0x1010, %project% Invalid Installation Path, % msg
		}	
		
		If (critical) {
			ExitApp
		}
	}
}