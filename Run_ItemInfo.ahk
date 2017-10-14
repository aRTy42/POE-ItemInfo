﻿; #####################################################################################################################
; # This script checks if the right AHK version is installed and runs the ItemInfo merge script.
; #####################################################################################################################
#Include *i %A_ScriptDir%\resources\Version.txt

FileRead versionFile, %A_ScriptDir%\resources\Version.txt
error := ErrorLevel
If (not StrLen(AHKVersionRequired) or error) {
	If (RegExMatch(A_ScriptDir, "i)\.zip$")) {
		MsgBox, 16, PoE-ItemInfo - Critical error, % "You are trying to run PoE-ItemInfo from inside a zip-archive, please unzip the whole folder. `n`nClosing script..."
		ExitApp
	} Else {
		MsgBox, 16, PoE-ItemInfo - Critical error, % "Script couldn't read file """ A_ScriptDir "\resources\VersionTrade.txt"". `n`nClosing script..."
		ExitApp
	}
}

MsgWrongAHKVersion := "AutoHotkey v" . AHKVersionRequired . " or later is needed to run this script. It is important not to run version 2.x. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < AHKVersionRequired or A_AhkVersion >= "2.0.00.00")
{	
	MsgBox, 16, Wrong AutoHotkey Version, % AHKVersionRequired
	ExitApp
}

Run "%A_AhkPath%" "%A_ScriptDir%\resources\ahk\Merge_ItemInfo.ahk" "%A_ScriptDir%"
ExitApp