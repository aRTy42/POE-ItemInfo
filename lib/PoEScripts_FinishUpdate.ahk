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

;debug - use manually copied test folder instead of downloaded file from github
;updateScriptPath := A_Temp "\" projectName "\test"
;FileCopyDir, %updateScriptPath%, %installPath%, 1

; remove 'PoE-' from project name since th start files are named 'Run_ItemInfo/Run_TradeMacro'
scriptStartFile := RegExReplace(projectName, "i).*-", "Run_") . ".ahk"
scriptStartFile := installPath . "\" . scriptStartFile

Run, "%A_AhkPath%" "%scriptStartFile%"
; debug - use old filename if downloading TradeMaco <= 1.7.3-beta from github
;Run, %A_AhkPath% %installPath%\Run_only_this.ahk
ExitApp