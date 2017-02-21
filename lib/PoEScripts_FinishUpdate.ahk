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

FileMoveDir, %updateScriptPath%, %installPath%, 2
If (ErrorLevel) {
	MsgBox Error while copying new files to %installPath%. Update failed.
	ExitApp
}

; remove 'PoE-' from project name since th start files are named 'Run_ItemInfo/Run_TradeMacro'
scriptStartFile := RegExReplace(projectName, "i).*-", "Run_") . ".ahk"
scriptStartFile := installPath . "\" . scriptStartFile

Run, "%A_AhkPath%" "%scriptStartFile%"
ExitApp