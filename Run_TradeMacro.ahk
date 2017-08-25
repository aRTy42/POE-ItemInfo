; #####################################################################################################################
; # This script merges TradeMacro, TradeMacroInit, PoE-ItemInfo and AdditionalMacros into one script and executes it.
; # We also have to set some global variables and pass them to the ItemInfo/TradeMacroInit scripts. 
; # This is to support using ItemInfo as dependancy for TradeMacro.
; #####################################################################################################################
#Include, %A_ScriptDir%\resources\VersionTrade.txt

TradeMsgWrongAHKVersion := "AutoHotkey v" . TradeAHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < TradeAHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % TradeMsgWrongAHKVersion
    ExitApp
}

arguments := ""
Loop, %0%  ; For each parameter
{
	arguments .= " " Trim(%A_Index%)
}

If (!InStr(arguments, "-noelevation", 0)) {
	RunAsAdmin(arguments)
}
If (InStr(arguments, "-nosplash", 0)) {
	skipSplash := 1	
} Else {
	skipSplash := 0
	StartSplashScreen()
}

If (!PoEScripts_CreateTempFolder(A_ScriptDir, "PoE-TradeMacro")) {
	ExitApp
}

If (InStr(A_ScriptDir, A_Desktop)) {
	Msgbox, 0x1010, Invalid Installation Path, Executing PoE-TradeMacro from your Desktop may cause script errors, please choose a different directory.
}

/*	 
	Set ProjectName to create user settings folder in A_MyDocuments
*/
projectName			:= "PoE-TradeMacro"
FilesToCopyToUserFolder	:= ["\resources\config\default_config_trade.ini", "\resources\config\default_config.ini", "\resources\ahk\default_AdditionalMacros.txt", "\resources\ahk\default_MapModWarnings.txt"]
overwrittenFiles 		:= PoEScripts_HandleUserSettings(projectName, A_MyDocuments, projectName, FilesToCopyToUserFolder, A_ScriptDir)
isDevelopmentVersion	:= PoEScripts_isDevelopmentVersion()
userDirectory			:= A_MyDocuments . "\" . projectName . isDevelopmentVersion

PoEScripts_CompareUserFolderWithScriptFolder(userDirectory, A_ScriptDir, projectName)

/*	 
	merge all scripts into `_TradeMacroMain.ahk` and execute it.
*/
info		:= ReadFileToMerge(A_ScriptDir "\resources\ahk\POE-ItemInfo.ahk")
tradeInit := ReadFileToMerge(A_ScriptDir "\resources\ahk\TradeMacroInit.ahk")
trade	:= ReadFileToMerge(A_ScriptDir "\resources\ahk\TradeMacro.ahk")
addMacros := ReadFileToMerge(userDirectory "\AdditionalMacros.txt")

info		:= "`n`r`n`r" . info . "`n`r`n`r"
addMacros	:= "#IfWinActive Path of Exile ahk_class POEWindowClass ahk_group PoEexe" . "`n`r`n`r" . addMacros . "`n`r`n`r"
addMacros	.= AppendCustomMacros(userDirectory)

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
Run "%A_AhkPath%" "%A_ScriptDir%\_TradeMacroMain.ahk" "%projectName%" "%userDirectory%" "%isDevelopmentVersion%" "%overwrittenFiles%" "isMergedScript" "%skipSplash%"

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

RunAsAdmin(arguments) 
{
    ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA"
    If Not A_IsAdmin 
    { 
		If A_IsCompiled 
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath . " " . arguments, str, A_WorkingDir, int, 1) 
		Else 
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """" . " " . arguments, str, A_WorkingDir, int, 1) 
		ExitApp
    }

    Return arguments
}	

StartSplashScreen() {
    SplashTextOn, , 20, PoE-TradeMacro, Merging and starting Scripts...
}

AppendCustomMacros(userDirectory)
{
	If(!InStr(FileExist(userDirectory "\CustomMacros"), "D")) {
		FileCreateDir, %userDirectory%\CustomMacros\
	}
	
	appendedMacros := "`n`n"
	extensions := "txt,ahk"
	Loop %userDirectory%\CustomMacros\*
	{
		If A_LoopFileExt in %extensions% 
		{
			FileRead, tmp, %A_LoopFileFullPath%
			appendedMacros .= "; appended custom macro file: " A_LoopFileName " ---------------------------------------------------"
			appendedMacros .= "`n" tmp "`n`n"
		}
	}
	
	Return appendedMacros
}

ReadFileToMerge(path) {
	If (FileExist(path)) {
		ErrorLevel := 0
		FileRead, file, %path%
		If (ErrorLevel = 1) {
			; file does not exist (should be caught already)
			Msgbox, 4096, Critical file read error, File "%path%" doesn't exist.`n`nClosing Script...
			ExitApp
		} Else If (ErrorLevel = 2) {
			; file is locked or inaccessible
			Msgbox, 4096, Critical file read error, File "%path%" is locked or inaccessible.`n`nClosing Script...
			ExitApp
		} Else If (ErrorLevel = 3) {
			; the system lacks sufficient memory to load the file
			Msgbox, 4096, Critical file read error, The system lacks sufficient memory to load the file "%path%".`n`nClosing Script...
			ExitApp
		} Else {
			Return file	
		}		
	} Else {
		Msgbox, 4096, Critical file read error, File "%path%" doesn't exist.`n`nClosing Script...
		ExitApp		
	}	
}