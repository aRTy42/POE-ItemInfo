PoEScripts_SaveWriteTextFile(file, text, encoding = "utf-8", critical = false, renameFallback = false) {
	deleteError := 
	writeError := 
	writeLastError := 
	writeSuccess :=
	
	If (FileExist(file)) {
		FileSetAttrib, -R, %file%
		FileDelete, %file%
		deleteError := A_LastError
		
		If (ErrorLevel) {
			RunWait %comspec% /c "attrib %file% -R && del /F /Q %file%", , Hide
		}
		
		If (FileExist(file) and renameFallback) {
			FileMove, %file%, %file%.tmp, 1
		}
	}
	
	If (not FileExist(file)) {
		FileAppend, %text%, %file%, %encoding%
		writeError := ErrorLevel
		writeLastError := A_LastError
		
		If (not writeError and FileExist(file)) {
			writeSuccess := true
		}
	}
	
	If (not writeSuccess and critical) {
		Return 1
	}
	Else {
		Return 0
	}
}

	
