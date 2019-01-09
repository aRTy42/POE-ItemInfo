; #####################################################################################################################
; # This script merges TradeMacro, TradeMacroInit, PoE-ItemInfo and AdditionalMacros into one script and executes it.
; # We also have to set some global variables and pass them to the ItemInfo/TradeMacroInit scripts.
; # This is to support using ItemInfo as dependancy for TradeMacro.
; #####################################################################################################################
#SingleInstance, Force
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
	SplashTextOff
	RunWait, "%A_AhkPath%" "%scriptDir%\_TradeMacroMain.ahk" "%projectName%" "%userDirectory%" "%isDevelopmentVersion%" "%overwrittenFiles%" "isMergedScript" "%skipSplash%" "%A_ScriptFullPath%", , UseErrorLevel
	If (ErrorLevel) {
		Menu, Tray, Icon, %scriptDir%\resources\images\poe-trade-bl.ico
		GoSub, ShowErrorUI
	}
	Else {
		ExitApp
	}
} Else {
	ExitApp	
}

Return

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
	Else {
		Return Name . " not found"
	}
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
	If (!InStr(FileExist(userDirectory "\CustomMacros"), "D")) {
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


ShowErrorUI:	
	DetectHiddenWindows, On
	Gui, Destroy
	Gui, New
	Gui, +LastFound
	Gui, Color, ffffff, ffffff
	
	Gui, Margin, 10, 10

	Gui, Font, bold s8 cRed, Verdana
	Gui, Add, Text, BackgroundTrans, The script couldn't be run successfully.
	Gui, Font, norm s8 c000000, Verdana
	
	Gui, Add, Text, x15 BackgroundTrans, % "Please first take a look at these resources to try and resolve the issue:"
	Gui, Add, Link, x25 y+5 cBlue BackgroundTrans, <a href="https://github.com/POE-TradeMacro/POE-TradeMacro/wiki/FAQ">- FAQ</a>
	Gui, Add, Link, x25 y+5 cBlue BackgroundTrans, <a href="https://github.com/POE-TradeMacro/POE-TradeMacro/issues">- Github Issues</a>

	Gui, Add, Text, x15 y+15 BackgroundTrans, % "Also make sure that:"
	Gui, Add, Text, x25 y+5 BackgroundTrans, % "- The script folder is properly extracted."
	Gui, Add, Text, x25 y+5 BackgroundTrans, % "- The script folder isn't located in any place that may cause permission issues:"
	Gui, Add, Text, x35 y+5 BackgroundTrans, % "- Desktop or other system directories."
	Gui, Add, Text, x35 y+5 BackgroundTrans, % "- Folders that are being synched by some software."
	Gui, Add, Text, x25 y+5 BackgroundTrans, % "- When having ""duplicate label"" or ""This line does not contain any recognized action"" errors try deleting:"
	Gui, Add, Text, x35 y+5 BackgroundTrans, % "- All files in the folder " A_MyDocuments "\" projectName "\CustomMacros""."
	
	Gui, Add, Text, x15 y+15 BackgroundTrans, % "If the script displayed any error message please copy it or make a screenshot and report the issue."
	Gui, Add, Text, x15 y+5 BackgroundTrans, % "Places to report in preferred and recommended order:"
	Gui, Add, Link, x25 y+5 cBlue BackgroundTrans, <a href="https://github.com/POE-TradeMacro/POE-TradeMacro/issues">- Github Issues</a>
	Gui, Add, Link, x25 y+5 cBlue BackgroundTrans, <a href="https://discord.gg/taKZqWw">- Discord</a>
	Gui, Add, Link, x25 y+5 cBlue BackgroundTrans, <a href="https://www.pathofexile.com/forum/view-thread/1757730">- Forum</a>

	Gui, Add, Text, x0 y0 w0 h0, % "dummycontrol"
	Gui, Show, AutoSize, PoE-TradeMacro run error
	ControlFocus, dummycontrol, PoE-TradeMacro run error
Return

GuiClose:
	ExitApp
Return