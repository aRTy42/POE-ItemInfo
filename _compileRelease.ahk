If (!FileExist(A_ScriptDir "\_TradeMacroMain.ahk")) {
	RunWait, Run_TradeMacro.ahk
	While (!FileExist(A_ScriptDir "\_TradeMacroMain.ahk")) {
		Sleep, 500
	}
}

SplitPath, A_AhkPath,, AhkDir
RunWait %comspec% /c ""%AhkDir%"\Compiler\Ahk2Exe.exe /in "_TradeMacroMain.ahk" /out "Fallback.exe" /icon "resources\images\fb.ico""
;RunWait %comspec% /c "git update-index --chmod=+x "%AhkDir%\"Fallback.exe""
ExitApp