#SingleInstance, force

cmFile	:= A_MyDocuments "\PoE-TradeMacro\dev_dev\CustomMacros\customMacros_example.txt"
tmpPath	:= A_ScriptDir "\temp"
tmpScript	:= tmpPath "\cmCompileTest.ahk"

If (FileExist(tmpScript)) {
	FileDelete, %tmpScript%
}

FileRead, cmContents, %cmFile%
FileAppend, %cmContents%, %tmpScript%

RunWait, "%A_AhkPath%" /ErrorStdOut "%tmpScript%", , UseErrorLevel
If (ErrorLevel) {
	; script cannot successfully be run, probably syntax errors
	msgbox % errorlevel
}

; cleanup
;FileDelete, %tmpScript%

ExitApp
