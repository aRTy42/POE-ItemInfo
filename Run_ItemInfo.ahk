; ####################################################################################################
; # This script merges PoE-ItemInfo and AdditionalMacros into one script and executes it.
; # We also have to set some global variables and pass them to the ItemInfo script. 
; # This is to support using ItemInfo as dependancy for other tools.
; ####################################################################################################

FileRemoveDir, %A_ScriptDir%\temp, 1
FileCreateDir, %A_ScriptDir%\temp
#Include, %A_ScriptDir%\resources\Version.txt

MsgWrongAHKVersion := "AutoHotkey v" . AHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < AHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % MsgWrongAHKVersion
    ExitApp
}
RunAsAdmin()

/*	 
	Set ProjectName to create user settings folder in A_MyDocuments
*/
projectName			:= "PoE-ItemInfo"
FilesToCopyToUserFolder	:= ["\resources\config\default_config.ini", "\resources\ahk\default_AdditionalMacros.txt"]   
overwrittenFiles 		:= PoEScripts_HandleUserSettings(projectName, A_MyDocuments, "", FilesToCopyToUserFolder, A_ScriptDir)
isDevelopmentVersion	:= PoEScripts_isDevelopmentVersion()
userDirectory			:= A_MyDocuments . "\" . projectName . isDevelopmentVersion

/*
	merge all scripts into `_ItemInfoMain.ahk` and execute it.
*/
FileRead, info		, %A_ScriptDir%\resources\ahk\POE-ItemInfo.ahk
FileRead, addMacros	, %userDirectory%\AdditionalMacros.txt

info := info . "`n`r`n`r"
addMacros := "#IfWinActive Path of Exile ahk_class POEWindowClass ahk_group PoEexe" . "`n`r`n`r" . addMacros

CloseScript("ItemInfoMain.ahk")
FileDelete, %A_ScriptDir%\_ItemInfoMain.ahk
FileCopy,   %A_ScriptDir%\resources\ahk\POE-ItemInfo.ahk, %A_ScriptDir%\_ItemInfoMain.ahk

FileAppend, %test%		, %A_ScriptDir%\_ItemInfoMain.ahk
FileAppend, %addMacros%	, %A_ScriptDir%\_ItemInfoMain.ahk

; set script hidden
FileSetAttrib, +H, %A_ScriptDir%\_ItemInfoMain.ahk
; pass some parameters to ItemInfo
Run "%A_AhkPath%" "%A_ScriptDir%\_ItemInfoMain.ahk" "%projectName%" "%userDirectory%" "%isDevelopmentVersion%" "%overwrittenFiles%"

ExitApp 


; ####################################################################################################
; # functions
; ####################################################################################################

CloseScript(Name)
{
	DetectHiddenWindows On
	SetTitleMatchMode RegEx
	IfWinExist, i)%Name%.* ahk_class AutoHotkey
		{
		WinClose
		WinWaitClose, i)%Name%.* ahk_class AutoHotkey, , 2
		If ErrorLevel
			Return "Unable to close " . Name
		Else
			Return "Closed " . Name
		}
	Else
		Return Name . " not found"
}

RunAsAdmin() 
{
    ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA" 
    If Not A_IsAdmin 
    { 
		If A_IsCompiled 
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath, str, A_WorkingDir, int, 1) 
		Else 
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1) 
		ExitApp 
    }
}