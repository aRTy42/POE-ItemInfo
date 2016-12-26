If (!FileExist(A_ScriptDir "\main.ahk")) {
	RunWait, Run_Only_This.ahk
	While (!FileExist(A_ScriptDir "\main.ahk")) {
		Sleep, 500
	}
}

SplitPath, A_AhkPath,, AhkDir
RunWait %comspec% /c ""%AhkDir%"\Compiler\Ahk2Exe.exe /in "main.ahk" /out "PoE-TradeMacro.exe" /icon "trade_data\poe-trade-bl.ico""
ExitApp