PoEScripts_CompareUserFolderWithScriptFolder(userPath, scriptPath, project, exit = true) {
	If (userPath = scriptPath) {
		action := exit ? "move/install" : "install"
		msg := "The " project " macro can't be run from the " project " user settings folder. Please " action " the macro to a different location."
		msg .= "`n`nInvalid location: `n        " userPath		
		msg .= exit ? "`n`nScript will be closed." : ""
		
		SplashTextOff
		If (exit) {		
			MsgBox, 16, Invalid %project% Script Location, % msg
			ExitApp	
		} Else {
			Return msg
		}
	}
	Return
}
