; This script merges TradeMacroInit, PoE-ItemInfo and TradeMacro into one script and executes it.
RunAsAdmin()
StartSplashScreen()

FileRead, info, POE-ItemInfo.ahk
FileRead, tradeInit, %A_ScriptDir%\trade_data\TradeMacroInit.ahk
FileRead, trade, %A_ScriptDir%\trade_data\TradeMacro.ahk

info := "`n`r`n`r" . info . "`n`r`n`r"
CloseScript("main.ahk")
FileDelete, %A_ScriptDir%\main.ahk
FileCopy, %A_ScriptDir%\trade_data\TradeMacroInit.ahk, %A_ScriptDir%\main.ahk
FileAppend, %info%, %A_ScriptDir%\main.ahk
FileAppend, %trade%, %A_ScriptDir%\main.ahk

Run %A_ScriptDir%\main.ahk
ExitApp 

CloseScript(Name)
{
	DetectHiddenWindows On
	SetTitleMatchMode RegEx
	IfWinExist, i)%Name%.* ahk_class AutoHotkey
		{
		WinClose
		WinWaitClose, i)%Name%.* ahk_class AutoHotkey, , 2
		If ErrorLevel
			return "Unable to close " . Name
		else
			return "Closed " . Name
		}
	else
		return Name . " not found"
}

RunAsAdmin() 
{
    ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA" 
    if not A_IsAdmin 
    { 
        If A_IsCompiled 
           DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath, str, A_WorkingDir, int, 1) 
        Else 
           DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1) 
        ExitApp 
    }
}	

StartSplashScreen() {
    SplashTextOn, , , Merging and starting Scripts...
}