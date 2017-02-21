; #####################################################################################################################
; # This script merges TradeMacro, TradeMacroInit, PoE-ItemInfo and AdditionalMacros into one script and executes it.
; # We also have to set some global variables and pass them to the ItemInfo/TradeMacroInit scripts. 
; # This is to support using ItemInfo as dependancy for TradeMacro.
; #####################################################################################################################
FileRemoveDir, %A_ScriptDir%\temp, 1
FileCreateDir, %A_ScriptDir%\temp
#Include, %A_ScriptDir%\resources\VersionTrade.txt

TradeMsgWrongAHKVersion := "AutoHotkey v" . TradeAHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < TradeAHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % TradeMsgWrongAHKVersion
    ExitApp
}
RunAsAdmin()
StartSplashScreen()

/*	 
	Set ProjectName to create user settings folder in A_MyDocuments
*/
projectName			:= "PoE-TradeMacro"
FilesToCopyToUserFolder	:= ["\resources\config\default_config_trade.ini", "\resources\config\default_config.ini", "\resources\ahk\default_AdditionalMacros.txt"]
overwrittenFiles 		:= PoEScripts_HandleUserSettings(projectName, A_MyDocuments, projectName, FilesToCopyToUserFolder, A_ScriptDir)
isDevelopmentVersion	:= PoEScripts_isDevelopmentVersion()
userDirectory			:= A_MyDocuments . "\" . projectName . isDevelopmentVersion

/*	 
	merge all scripts into `_TradeMacroMain.ahk` and execute it.
*/
FileRead, info		, %A_ScriptDir%\resources\ahk\POE-ItemInfo.ahk
FileRead, tradeInit	, %A_ScriptDir%\resources\ahk\TradeMacroInit.ahk
FileRead, trade	, %A_ScriptDir%\resources\ahk\TradeMacro.ahk
FileRead, addMacros	, %userDirectory%\AdditionalMacros.txt

info := "`n`r`n`r" . info . "`n`r`n`r"
addMacros := "#IfWinActive Path of Exile ahk_class POEWindowClass ahk_group PoEexe" . "`n`r`n`r" . addMacros . "`n`r`n`r"

CloseScript("_TradeMacroMain.ahk")
CloseScript("_ItemInfoMain.ahk")
FileDelete, %A_ScriptDir%\_TradeMacroMain.ahk
FileDelete, %A_ScriptDir%\_ItemInfoMain.ahk
FileCopy,   %A_ScriptDir%\resources\ahk\TradeMacroInit.ahk, %A_ScriptDir%\_TradeMacroMain.ahk

FileAppend, %info%		, %A_ScriptDir%\_TradeMacroMain.ahk
FileAppend, %addMacros%	, %A_ScriptDir%\_TradeMacroMain.ahk
FileAppend, %trade%		, %A_ScriptDir%\_TradeMacroMain.ahk

; set script hidden
FileSetAttrib, +H, %A_ScriptDir%\_TradeMacroMain.ahk
; pass some parameters to TradeMacroInit
Run "%A_AhkPath%" "%A_ScriptDir%\_TradeMacroMain.ahk" "%projectName%" "%userDirectory%" "%isDevelopmentVersion%" "%overwrittenFiles%"

ExitApp


; ####################################################################################################################
; # functions
; ####################################################################################################################

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

StartSplashScreen() {
    SplashTextOn, , 20, PoE-TradeMacro, Merging and starting Scripts...
}