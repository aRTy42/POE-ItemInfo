#Include CalcChecksum.ahk

PoEScripts_UserSettings(ProjectName, External, FilesToCopy, Dir = "") {	
	If (!StrLen(Dir)) {
		Dir := A_MyDocuments . "\" . ProjectName
	}
	
	; External is set if the user settings folder is handled by another script
	If (External) {
		; copy files after checking if it's neccessary (files do not exist, files were changed in latest update)
		; copy .ini files and additionalMacros.txt to A_MyDocuments/ProjectName
		PoEScripts_CopyFiles(FilesToCopy, Dir)
	}
	Else {		
		If (!InStr(FileExist(Dir), "D")) {
			;FileCreateDir, %Dir%        
		}		
		
		; copy files after checking if it's neccessary (files do not exist, files were changed in latest update)
		; this handles the external scripts files
		;PoEScripts_CopyFiles(FilesToCopy, Dir)
	}

}

PoEScripts_CopyFiles(Files, Dir) {
	For key, file in Files {
		If (FileExist(file)) {		
			If(PoEScripts_CopyNeeded(file, Dir)) {
				FileCopy, %file%, %Dir%
				SplitPath, file, name
				; hash copied file
				targetHash := HashFile(Dir . "\" . name, "SHA")
				
				; write hash to a text file
				If (!FileExist(Dir . "\FileHashes.txt")) {
					FileAppend, %name%:%targetHash%`n, %Dir%\FileHashes.txt
				}
				Else {					
					hashes := {}
					; parse file line by line and write names/hashes to array/object
					FileRead, fileData, %Dir%\FileHashes.txt
					MsgBox % "data: " fileData
					Loop, Parse, fileData, `n, `r
					{
						RegExMatch(A_LoopField, "(.*):(.*)", match)
						hashes[Trim(match1)] := Trim(match2)
					}				
					
					; delete file and write it new with array/object contents
					FileDelete, %Dir%\FileHashes.txt
					For key, hash in hashes {
						MsgBox % key ", " hash
						If (key == name) {
							hashes[key] := targetHash
						}
						FileAppend, %key%:%hash%`n, %Dir%\FileHashes.txt
					}
				}
			}			
		}
	}
}

PoEScripts_CopyNeeded(file, targetDir) {
	SplitPath, file, name, dir, ext, name_no_ext, drive
	
	If (FileExist(targetDir . "\" . name)) {
		MsgBox file exists already in target folder
		If (PoEScripts_CompareFileHashes(file, targetDir . "\" . name, targetDir)) {
			MsgBox file hashes are different = file was changed			
			return 1
		}
		Else {
			return 0	
		}		
	}
	Else {
		MsgBox file doesn't exist in target folder
		return 1
	}
}

PoEScripts_CompareFileHashes(sourceFile, targetFile, targetDir) {
	sourceHash := HashFile(sourceFile, "SHA")
	
	hashes := {}
	; parse file line by line and write names/hashes to array/object
	FileRead, fileData, %targetDir%\FileHashes.txt
	Loop, Parse, fileData, `n, `r
	{
		RegExMatch(A_LoopField, "(.*):(.*)", match)
		hashes[Trim(match1)] := Trim(match2)
	}
	
	For key, hash in hashes {
		If (key == name) {
			If (sourceHash != hash) {
				return 1
			}
		}
	}	
	
	return 0
}