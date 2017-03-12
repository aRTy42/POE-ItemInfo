; #####################################################################################################################
; # Finishes the script update
; # 
; # This has to be done from an external script so that the script directory can be overwritten 
; # without killing the update midway.
; #####################################################################################################################

#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background

parentScriptDir	= %1%
updateScriptPath	= %2%
installPath		= %3%
projectName		= %4%
scriptName		= %5%

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

	RunWait %comspec% /c rename "%updateScriptPath%" "%installFolder%",,hide
	RunWait %comspec% /c rd /s /q "%installPath%",,hide	
	RunWait %comspec% /c robocopy /s "%renamedUpdatePath%" "%installPath%",,hide
	
	; parse output??
} Catch e {
	MsgBox,,, % "Exception thrown while copying new files to " installPath ". Update failed!`n`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
	ExitApp
}

; remove 'PoE-' from project name since th start files are named 'Run_ItemInfo/Run_TradeMacro'
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