; ignore include errors to support two different paths
#Include, *i CalcChecksum.ahk
#Include, *i %A_ScriptDir%\..\..\lib\CalcChecksum.ahk

PoEScripts_HandleUserSettings(ProjectName, BaseDir, External, sourceDir, scriptDir = "") {
	Dir := BaseDir . "\" . ProjectName
	
	; check for git files to determine if it's a development version, return a path using the branch name
	devBranch := PoEScripts_isDevelopmentVersion(scriptDir)
	If (StrLen(devBranch)) {
		Dir := Dir . devBranch
	}
	
	PoEScripts_CreateDirIfNotExist(Dir)
	
	; copy files after checking if it's neccessary (files do not exist, files were changed in latest update)
	PoEScripts_CopyFiles(sourceDir, Dir, fileList)
	
	Return fileList
}

PoEScripts_CopyFiles(SrcDir, DestDir, ByRef fileList) {
	tempObj 		:= PoEScripts_ParseFileHashes(DestDir)
	hashes 		:= tempObj.dynamic
	hashes_locked 	:= tempObj.static

	fileNames		:= []
	overwrittenFiles := []
	PoEScripts_CopyFolderContentsRecursive(SrcDir, DestDir, fileNames, hashes, hashes_locked, overwrittenFiles)
	
	; recreate hashes file and fill it with array/object contents
	FileDelete, %DestDir%\data\FileHashes.txt
	For key, hash in hashes {
		; make sure to write only hashes for files that we wanted to copy over,  removing files not included in the new release
		For k, name in fileNames {
			If (key == name) {
				PoEScripts_CreateDirIfNotExist(DestDir "\data")
				FileAppend, %key% = %hash%`n, %DestDir%\data\FileHashes.txt
			}			
		}
	}
	
	; give the user some notification on what files were overwritten and backed up
	If (overwrittenFiles.Length()) {
		fileList := ""
		Loop, % overwrittenFiles.Length() {
			fileList .= "- " . overwrittenFiles[A_Index] . "`n"
		}
	}
}

PoEScripts_CopyFolderContentsRecursive(SourcePattern, DestinationFolder, ByRef fileNames, ByRef hashes, ByRef hashes_locked, ByRef overwrittenFiles, DoOverwrite = false) {
	; Copies all files and folders matching SourcePattern into the folder named DestinationFolder (recursively), skipping empty folders.
	If (!InStr(FileExist(DestinationFolder), "D")) {
		count := 0
		Loop, %SourcePattern%\*.*, 1, 1
			count++
		If (count > 0) {
			FileCreateDir, %DestinationFolder%
		} Else {
			Return
		}
	}

	FileRemoveDir, %DestinationFolder%\temp, 1
	FileCreateDir, %DestinationFolder%\temp
	
	Loop %SourcePattern%\*.*, 1
	{
		If (InStr(FileExist(A_LoopFileFullPath), "D")) {
			PoEScripts_CopyFolderContentsRecursive(A_LoopFileFullPath, DestinationFolder "\" A_LoopFileName, fileNames, hashes, hashes_locked, overwrittenFiles, DoOverwrite)
		} Else If (not RegExMatch(A_LoopFileFullPath, "i)\.bak$")) {
			SplitPath, A_LoopFileFullPath, f_name, f_dir, f_ext, f_name_no_ext, f_drive
			file_orig := A_LoopFileFullPath
			RegExMatch(f_name_no_ext, "i)(_dontOverwrite)", dontOverwrite)
			file_name := RegExReplace(f_name_no_ext, "i)_dontOverwrite", "") . "." . f_ext
			FileCopy, %A_LoopFileFullPath%, %DestinationFolder%\temp\%file_name%, 1
			file		:= f_dir . "\" . file_name
			fileNames.push(file_name)
			
			; hash the file from the new script version
			If (not StrLen(dontOverwrite)) {			
				sourceHash := HashFile(DestinationFolder . "\temp\" . file_name, "SHA")
				hashes[file_name] := sourceHash
			}

			; if the file from the new release was changed since the last release or does not exist, copy it over
			If (PoEScripts_CopyNeeded(file_name, DestinationFolder, sourceHash, hashes_locked, dontOverwrite)) {
				; remember which files we will overwrite and create backups
				If (FileExist(DestinationFolder "\" file_name)) {
					overwrittenFiles.push(file_name)
					PoEScripts_CreateDirIfNotExist(DestinationFolder "\backup")
					FileMove, %DestinationFolder%\%file_name%, %DestinationFolder%\backup\%file_name%, 1
				}				
				ErrorLevel := 0
				FileCopy, %DestinationFolder%\temp\%file_name%, %DestinationFolder%\%file_name%, 1
				If (ErrorLevel) {
					Msgbox % "File: " file_name "could not be copied to the user folder. Please make sure this folder is not protected/readonly."
				}
			}	
			FileDelete, %DestinationFolder%\temp\%file_name%
		}
	}
	FileRemoveDir, %DestinationFolder%\temp, 1
	
	Return
}

PoEScripts_CopyNeeded(file, targetDir, sourceHash, hashes_locked, dontOverwrite = "") {
	SplitPath, file, f_name, f_dir, f_ext, f_name_no_ext, f_drive
	
	If (FileExist(targetDir . "\" . f_name)) {
		; file exists already in target folder
		If (PoEScripts_CompareFileHashes(f_name, sourceHash, hashes_locked) and not StrLen(dontOverwrite)) {
			; file hashes are different -> default file was changed since last release
			Return 1
		}
		Else {
			Return 0	
		}		
	}
	Else {
		; file doesn't exist in target folder
		Return 1
	}
}

PoEScripts_ParseFileHashes(Dir) {
	hashes := {}
	hashes.dynamic := {}
	hashes.static  := {}
	FileRead, fileData, %Dir%\data\FileHashes.txt

	Loop, Parse, fileData, `n, `r
	{
		RegExMatch(A_LoopField, "(.*)\s=\s(.*)", match)
		hashes.dynamic[Trim(match1)] := Trim(match2)
		hashes.static[Trim(match1)]  := Trim(match2) 
	}	

	Return hashes
}

PoEScripts_CompareFileHashes(name, sourceHash, hashes_locked) {
	If (hashes_locked[name] != sourceHash) {
		Return 1
	}
	Return 0
}

PoEScripts_CreateDirIfNotExist(directory) {	
	If (!InStr(FileExist(directory), "D")) {
		FileCreateDir, %directory%
	}
}

PoEScripts_isDevelopmentVersion(directory = "") {
	directory := StrLen(directory) ? directory : A_ScriptDir
	If (FileExist(directory "\.git")) {
		If (FileExist(directory "\.git\HEAD")) {
			FileRead, head, %directory%\.git\HEAD
			branch := ""
			Loop, Parse, head, `n, `r
			{
				RegExMatch(A_LoopField, "ref:.*\/(.*)", refs)
				If (StrLen(refs1)) {
					branch := "\dev_" . refs1
				}
			}
			Return branch
		}
		Else {			
			Return ""
		} 
	}
	Else {
		Return ""
	}
}