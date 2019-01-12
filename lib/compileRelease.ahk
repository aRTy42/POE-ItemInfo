#SingleInstance, force

RunWait, ..\Run_TradeMacro.ahk -mergeonly
While (!FileExist(A_ScriptDir "\..\_TradeMacroMain.ahk")) {
	Sleep, 500
}

SplitPath, A_AhkPath,, AhkDir
RunWait %comspec% /c ""%AhkDir%"\Compiler\Ahk2Exe.exe /in "..\_TradeMacroMain.ahk" /out "..\release\Fallback.exe" /icon "..\resources\images\fb.ico""

/*
fallbackExe := A_ScriptDir "..\release\Fallback.exe"
RunWait %comspec% /c "git update-index --chmod=+x "%fallbackExe%""
*/
ExitApp