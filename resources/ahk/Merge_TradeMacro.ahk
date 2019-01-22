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
#Include, %A_ScriptDir%\..\..\lib\PoEScripts_CheckInvalidScriptFolder.ahk
#Include, %A_ScriptDir%\..\..\lib\Class_SplashUI.ahk
#Include, %A_ScriptDir%\..\..\resources\VersionTrade.txt

arguments := ""
arg1 	= %1%
global scriptDir := FileExist(arg1) ? arg1 : RegExReplace(A_ScriptDir, "(.*)\\[^\\]+\\.*", "$1")
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
	StartSplashScreen(TradeReleaseVersion)
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
PoEScripts_CheckInvalidScriptFolder(scriptDir, "PoE-TradeMacro")

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
SplashUI.SetSubMessage("Merging and starting Scripts...")

tradeInit := ReadFileToMerge(file01 := scriptDir "\resources\ahk\TradeMacroInit.ahk")
info		:= ReadFileToMerge(file02 := scriptDir "\resources\ahk\POE-ItemInfo.ahk")
addMacros := ReadFileToMerge(file03 := scriptDir "\resources\ahk\AdditionalMacros.ahk")
trade	:= ReadFileToMerge(file04 := scriptDir "\resources\ahk\TradeMacro.ahk")

info		:= "`n`r`n`r" . info . "`n`r`n`r"
addMacros	:= "`n`r#IfWinActive ahk_group PoEWindowGrp" . "`n`r`n`r" . addMacros . "`n`r`n`r"
addMacros	.= AppendCustomMacros(userDirectory)

CloseScript("_TradeMacroMain.ahk")
CloseScript("_ItemInfoMain.ahk")

global outputFile := scriptDir "\_TradeMacroMain.ahk"
FileDelete, %outputFile%
FileDelete, %scriptDir%\_ItemInfoMain.ahk
; trademacro init
FileCopy,   %scriptDir%\resources\ahk\TradeMacroInit.ahk, %outputFile%
; iteminfo
FileAppend, % "`r`n`r`n/* ###--- Merged File: " file02 " ---~~~  `r`n*/`r`n", %outputFile%
FileAppend, %info%		, %outputFile%
; additional macros
FileAppend, % "`r`n`r`n/* ###--- Merged File: " file03 " ---~~~  `r`n*/`r`n", %outputFile%
FileAppend, %addMacros%	, %outputFile%
; trademacro
FileAppend, % "`r`n`r`n/* ###--- Merged File: " file04 " ---~~~  `r`n*/`r`n", %outputFile%
FileAppend, %trade%		, %outputFile%

; set script hidden
FileSetAttrib, +H, %outputFile%

/*
	Kill the merged script if it's running already. This prevents the error parser to read text from the wrong window which could be from the already running script.
	Pass some parameters so the script.
	Parse runtime errors and show a GUI to help players with handling and reporting issues.
*/
If (not onlyMergeFiles) {
	DetectHiddenWindows, On
	SetTitleMatchMode, 1
	WinClose, %scriptDir%\_TradeMacroMain.ahk ahk_class AutoHotkey, , 0
	WinKill, %scriptDir%\_TradeMacroMain.ahk ahk_class AutoHotkey, , 0
	
	SplashUI.DestroyUI()
	Run, "%A_AhkPath%" "%scriptDir%\_TradeMacroMain.ahk" "%projectName%" "%userDirectory%" "%isDevelopmentVersion%" "%overwrittenFiles%" "isMergedScript" "%skipSplash%" "%A_ScriptFullPath%", , UseErrorLevel, OutputVarPID

	; Check whether the called script is still running to detect script crashes, in favour of using runwait + errorlevel
	; The advantage here is that we can read the text from the crash error window.
	; This requires the merge script being closed by the called script though.
	scriptRunning := true
	global errorWindowText := ""

	Loop {
		Sleep, 100
		Process, Exist, %OutputVarPID%
		If (ErrorLevel = 0) {
			scriptRunning := false
		}

		DetectHiddenWindows, On
		SetTitleMatchMode, 1
		IfWinNotExist, %outputFile% ahk_class AutoHotkey
		{
			;scriptRunning := false
		}
	} Until (not scriptRunning)
	
	SetTitleMatchMode, 1
	DetectHiddenText, On
	WinGetText, errorWindowText, % "_TradeMacroMain.ahk"

	Menu, Tray, Icon, %scriptDir%\resources\images\poe-trade-bl.ico
	GoSub, ShowErrorUI
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

StartSplashScreen(version) {
	global SplashUI := new SplashUI("on", "PoE-TradeMacro", "Initializing PoE-TradeMacro...", "- Checking permission and access to some folders...", version, scriptDir "\resources\images\greydot.png")
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
			appendedMacros .= "`r`n`r`n/* ###--- Merged File: " A_LoopFileFullPath " ---~~~  `r`n*/`r`n"
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

	If (StrLen(errorWindowText)) {
		Gui, Font, bold s8 c000000, Verdana
		Gui, Add, Text, x15 y+15 BackgroundTrans, % "Parsed runtime error:"
		errorMsg := ParseRuntimeError(errorWindowText, outputFile, errorFile)
		Gui, Font, bold norm
		Gui, Add, Text, x15 y+7 BackgroundTrans, % errorMsg
		
		solution := GetSolution(errorMsg, errorFile)
		If (solution) {
			Gui, Font, bold s8 c000000, Verdana
			Gui, Add, Text, x15 y+15 BackgroundTrans, % "Possible solution:"
			Gui, Font, bold norm
			Gui, Add, Text, x15 y+7 BackgroundTrans, % solution
		}		
		
		Gui, Font, bold s8 c000000, Verdana
		Gui, Add, Text, x15 y+15 BackgroundTrans, % "Original runtime error:"
		Gui, Font, bold norm
		originalMsg := Trim(RegExReplace(errorWindowText, "i)^Ok(\r\n)?"))
		originalMsg := Trim(RegExReplace(originalMsg, "i)(\r\n)?The program will exit\.$"))		
		Gui, Add, Edit, x16 y+7 w600 r6 ReadOnly BackgroundTrans, % originalMsg
		
		Gui, Add, Button, x15 y+10 gCopyError, Copy error to clipboard
	}

	Gui, Add, Text, x0 y0 w0 h0, % "dummycontrol"
	Gui, Show, AutoSize, PoE-TradeMacro run error
	ControlFocus, dummycontrol, PoE-TradeMacro run error
Return

CopyError:
	ClipBoard := errorWindowText
	ToolTip, Copied
	SetTimer, RemoveToolTip, 1500
Return

RemoveToolTip:
	SetTimer, RemoveToolTip, Off
	ToolTip
Return

ParseRuntimeError(e, mergedFile, ByRef errorFile) {
	errorLine := 
	If (RegExMatch(e, "i)Error at line (\d+)\.", lineNr)) {
		errorLine := lineNr1	
	}
	
	FileRead, rF, %mergedFile%	
	files:= []
	
	lines := []
	Loop, Parse, rF, `n, `r
	{
		lines.push(A_LoopField)
	}
	
	For key, val in lines {
		If (RegExMatch(val, "i)###---\sMerged File:\s(.*)\s---\~\~\~", mf)) {
			If (mf) {		
				f := {}
				;f.name := RegExReplace(mf1, "i)(.*)(CustomMacros\\.*)$|(.*)(resources\\ahk\\.*)$", "$2$4")
				f.name := mf1
				f.start := A_Index				
				files.push(f)
			}
		}
	}

	errorFile := ""	
	Loop, % files.MaxIndex() {
		If (A_Index = 1 and errorLine < files[A_Index].start) {
			errorFile := scriptDir "\resources\ahk\TradeMacroInit.ahk"
			Break
		}
		If (errorLine > files[A_Index].start) {
			If (A_Index = files.MaxIndex()) {
				errorFile := files[A_Index].name
			}
			Else If (errorLine < files[A_Index + 1].start) {
				errorFile := files[A_Index].name
			}
			Else {
				errorFile := files[A_Index + 1].name
			}			
		}
	}

	errorMsg := "Error at line " errorLine ". This should be caused by the source file: `n" errorFile
	Return errorMsg
}

GetSolution(msg, file) {
	solution := ""
	If (RegExMatch(file, "i)customMacros_example\.txt$")) {
		solution := "Try deleting the source file:`n" file
		Return solution
	}
}

GuiClose:
	ExitApp
Return