; #####################################################################################################################
; # Finishes the script update
; # 
; # This has to be done from an external script so that the script directory can be overwritten 
; # without killing the update midway.
; #####################################################################################################################

#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background
SetWorkingDir, %A_ScriptDir%

parentScriptDir	= %1%
updateScriptPath	= %2%
installPath		= %3%
projectName		= %4%
scriptName		= %5%
debug			= %6%

Try {
	RunAsAdmin()
	DetectHiddenWindows On
	SetTitleMatchMode RegEx
	IfWinExist, i)%scriptName%.* ahk_class AutoHotkey
	{
		WinClose
		WinWaitClose, i)%scriptName%.* ahk_class AutoHotkey, , 2		
	}
	
	RegExMatch(updateScriptPath, "(.*)\\.*", updateParentDir)
	RegExMatch(installPath, "(.*)\\.*", installParentDir)
	installFolder		:= RegExReplace(installPath, "(.*\\)")
	renamedUpdatePath	:= updateParentDir1 "\" installFolder
	installParentDir	:= installParentDir1
	
	If (debug) {
		RunWait, "copyUpdate.bat" "%updateScriptPath%" "%installPath%" "%installFolder%" "%installPath%_tempInstall" "%installFolder%_tempInstall" "1" && pause, , 
	} Else {
		RunWait, "copyUpdate.bat" "%updateScriptPath%" "%installPath%" "%installFolder%" "%installPath%_tempInstall" "%installFolder%_tempInstall", , hide
	}	

	If (FileExist("exitCode.txt")) {
		FileRead, exitCode, exitCode.txt
		code := ""
		Loop, Parse, exitCode, `n, `r 
		{
			If (StrLen(A_LoopField)) {
				code := Trim(A_LoopField)
			}
		}
		
		scriptStartFile := RegExReplace(projectName, "i).*-", "Run_") . ".ahk"
		
		If (code = 1) {
			; do nothing
		} Else If (code = 17) {
			; renaming tempInstall to install folder via batch failed, try again with AHK
			FileMoveDir, %installPath%_tempInstall, %installPath%, R
			If (ErrorLevel) {
				; also failed, use tempInstall to run the script
				installPath := %installPath% "_tempInstall"
			}
		} Else {
			MsgBox,,, % "Exception thrown while copying new files to " installPath ". Update failed!`n`n" ParseExitCode(code)
			ExitApp
		}		
	} Else {
		MsgBox,,, % "Exception thrown while copying new files to " installPath ". Update failed!`n`n Update scripted failed to run."
		ExitApp		
	}
} Catch e {
	MsgBox,,, % "Exception thrown while copying new files to " installPath ". Update failed!`n`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
	ExitApp
}

; remove 'PoE-' from project name since the start files are named 'Run_ItemInfo/Run_TradeMacro'
scriptStartFile := RegExReplace(projectName, "i).*-", "Run_") . ".ahk"
scriptStartFile := installPath . "\" . scriptStartFile

Run, "%A_AhkPath%" "%scriptStartFile%"
ExitApp

RunAsAdmin() {
	Loop, %0%  ; For each parameter:
	{
		param := %A_Index%  ; Fetch the contents of the variable whose name is contained in A_Index.
		params .= A_Space . param
	}
	ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA"
	 
	If not A_IsAdmin
	{
		If A_IsCompiled
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath, str, params , str, A_WorkingDir, int, 1)
		Else
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """" . A_Space . params, str, A_WorkingDir, int, 1)
		ExitApp
	}
}

ParseExitCode(code) {
	; https://ss64.com/nt/robocopy-exit.html
	msg := ""
	if (code = 17) {
		msg := "Install directory could not be emptied. Cancelled update."
	}
	else if (code = 16) {
		msg := "***FATAL ERROR***"
	}
	else if (code = 15) {
		msg := "OKCOPY + FAIL + MISMATCHES + XTRA"
	}
	else if (code = 14) {
		msg := "FAIL + MISMATCHES + XTRA"
	}
	else if (code = 13) {
		msg := "OKCOPY + FAIL + MISMATCHES"
	}
	else if (code = 12) {
		msg := "FAIL + MISMATCHES"
	}
	else if (code = 11) {
		msg := "OKCOPY + FAIL + XTRA"
	}
	else if (code = 10) {
		msg := "FAIL + XTRA"
	}
	else if (code = 9) {
		msg := "OKCOPY + FAIL"
	}
	else if (code = 8) {
		msg := "Some files or directories could not be copied.`n(copy errors occurred and the retry limit was exceeded)."
	}
	else if (code = 7) {
		msg := "Files were copied, a file mismatch was present, and additional files were present."
	}
	else if (code = 6) {
		msg := "Additional files and mismatched files exist. No files were copied and no failures were encountered.`nThis means that the files already exist in the destination directory."
	}
	else if (code = 5) {
		msg := "Some files were copied. Some files were mismatched. No failure was encountered."
	}
	else if (code = 4) {
		msg := "Some Mismatched files or directories were detected."
	}
	else if (code = 3) {
		msg := "Some files were copied. Additional files were present. No failure was encountered."
	}
	else if (code = 2) {
		msg := "Some Extra files or directories were detected. No files were copied."
	}
	else if (code = 1) {
		msg := "One or more files were copied successfully (that is, new files have arrived)."
	}
	else if (code = 0) {
		msg := "No errors occurred, and no copying was done.`nThe source and destination directory trees are completely synchronized."
	}
	
	return msg
}