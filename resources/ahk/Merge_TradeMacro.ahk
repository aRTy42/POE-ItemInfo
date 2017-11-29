; #####################################################################################################################
; # This script merges TradeMacro, TradeMacroInit, PoE-ItemInfo and AdditionalMacros into one script and executes it.
; # We also have to set some global variables and pass them to the ItemInfo/TradeMacroInit scripts.
; # This is to support using ItemInfo as dependancy for TradeMacro.
; #####################################################################################################################
#Include, %A_ScriptDir%\..\..\lib\PoEScripts_CheckFolderWriteAccess.ahk
#Include, %A_ScriptDir%\..\..\lib\PoEScripts_CompareUserFolderWithScriptFolder.ahk
#Include, %A_ScriptDir%\..\..\lib\PoEScripts_CheckCorrectClientLanguage.ahk
#Include, %A_ScriptDir%\..\..\lib\PoEScripts_CreateTempFolder.ahk
#Include, %A_ScriptDir%\..\..\lib\PoEScripts_HandleUserSettings.ahk

arguments := ""
arg1 	= %1%
scriptDir := FileExist(arg1) ? arg1 : RegExReplace(A_ScriptDir, "(.*)\\[^\\]+\\.*", "$1")
Loop, %0%  ; For each parameter
{
	If (not FileExist(%A_Index%)) {	; we don't want the first argument which is the project scriptdir here
		arguments .= " " Trim(%A_Index%)
	}
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

If (InStr(arguments, "-mergeonly", 0)) {
	onlyMergeFiles := 1
}

/*
	Set ProjectName to create user settings folder in A_MyDocuments
*/
projectName := "PoE-TradeMacro"

/*
	Check some folder permissions
*/

PoEScripts_CheckFolderWriteAccess(A_MyDocuments . "\" . projectName)
PoEScripts_CheckFolderWriteAccess(scriptDir)

If (not PoEScripts_CheckCorrectClientLanguage()) {
	ExitApp
}
If (!PoEScripts_CreateTempFolder(scriptDir, projectName)) {
	ExitApp
}

If (InStr(scriptDir, A_Desktop)) {
	Msgbox, 0x1010, Invalid Installation Path, Executing PoE-TradeMacro from your Desktop (or any of its subfolders) may cause script errors, please choose a different directory.
}

/*
	Set some important variables
*/
FilesToCopyToUserFolder	:= scriptDir . "\resources\default_UserFiles"
overwrittenFiles 		:= PoEScripts_HandleUserSettings(projectName, A_MyDocuments, projectName, FilesToCopyToUserFolder, scriptDir)
isDevelopmentVersion	:= PoEScripts_isDevelopmentVersion(scriptDir)
userDirectory			:= A_MyDocuments . "\" . projectName . isDevelopmentVersion

PoEScripts_CompareUserFolderWithScriptFolder(userDirectory, scriptDir, projectName)

/*
	merge all scripts into `_TradeMacroMain.ahk` and execute it.
*/
info		:= ReadFileToMerge(scriptDir "\resources\ahk\POE-ItemInfo.ahk")
tradeInit := ReadFileToMerge(scriptDir "\resources\ahk\TradeMacroInit.ahk")
trade	:= ReadFileToMerge(scriptDir "\resources\ahk\TradeMacro.ahk")
addMacros := ReadFileToMerge(scriptDir "\resources\ahk\AdditionalMacros.ahk")

info		:= "`n`r`n`r" . info . "`n`r`n`r"
addMacros	:= "`n`r#IfWinActive ahk_group PoEWindowGrp" . "`n`r`n`r" . addMacros . "`n`r`n`r"
addMacros	.= AppendCustomMacros(userDirectory)

CloseScript("_TradeMacroMain.ahk")
CloseScript("_ItemInfoMain.ahk")
FileDelete, %scriptDir%\_TradeMacroMain.ahk
FileDelete, %scriptDir%\_ItemInfoMain.ahk
FileCopy,   %scriptDir%\resources\ahk\TradeMacroInit.ahk, %scriptDir%\_TradeMacroMain.ahk

FileAppend, %info%		, %scriptDir%\_TradeMacroMain.ahk
FileAppend, %addMacros%	, %scriptDir%\_TradeMacroMain.ahk
FileAppend, %trade%		, %scriptDir%\_TradeMacroMain.ahk

; set script hidden
FileSetAttrib, +H, %scriptDir%\_TradeMacroMain.ahk
; pass some parameters to TradeMacroInit
If (not onlyMergeFiles) {
	Run "%A_AhkPath%" "%scriptDir%\_TradeMacroMain.ahk" "%projectName%" "%userDirectory%" "%isDevelopmentVersion%" "%overwrittenFiles%" "isMergedScript" "%skipSplash%"
}

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

ReadFileToMerge(path, fallbackSrcPath = "") {
	fallback := StrLen(fallbackSrcPath) ? "`n`nAs a fallback you can try copying the file manually from """ fallbackSrcPath "" : ""
	If (FileExist(path)) {
		ErrorLevel := 0
		FileRead, file, %path%
		If (ErrorLevel = 1) {
			; file does not exist (should be caught already)
			Msgbox, 4096, Critical file read error, The file "%path%" doesn't exist. %fallback%`n`nClosing Script...
			ExitApp
		} Else If (ErrorLevel = 2) {
			; file is locked or inaccessible
			Msgbox, 4096, Critical file read error, The file "%path%" is locked or inaccessible.`n`nClosing Script...
			ExitApp
		} Else If (ErrorLevel = 3) {
			; the system lacks sufficient memory to load the file
			Msgbox, 4096, Critical file read error, The system lacks sufficient memory to load the file "%path%".`n`nClosing Script...
			ExitApp
		} Else {
			Return file
		}
	} Else {
		Msgbox, 4096, Critical file read error, The file "%path%" doesn't exist. %fallback%`n`nClosing Script...
		ExitApp
	}
}
