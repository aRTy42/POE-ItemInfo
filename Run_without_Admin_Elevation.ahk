; This script merges TradeMacroInit, PoE-ItemInfo and TradeMacro into one script and executes it.
#Include, %A_ScriptDir%/trade_data/Version.txt
TradeMsgWrongAHKVersion := "AutoHotkey v" . TradeAHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < TradeAHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % TradeMsgWrongAHKVersion
    ExitApp
}

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


StartSplashScreen() {
    SplashTextOn, , , Merging and starting Scripts...
}