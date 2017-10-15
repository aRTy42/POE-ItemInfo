; ignore include errors to support two different paths
#Include, *i CalcChecksum.ahk
#Include, *i %A_ScriptDir%\..\..\lib\CalcChecksum.ahk

#Include, *i JSON.ahk
#Include, *i %A_ScriptDir%\..\..\lib\JSON.ahk

#Include, *i EasyIni.ahk
#Include, *i %A_ScriptDir%\..\..\lib\EasyIni.ahk


PoEScripts_HandleUserSettings(ProjectName, BaseDir, External, sourceDir, scriptDir = "") {
	Dir := BaseDir . "\" . ProjectName

	; check for git files to determine if it's a development version, return a path using the branch name
	devBranch := PoEScripts_isDevelopmentVersion(scriptDir)
	If (StrLen(devBranch)) {
		Dir .= devBranch
	}
	PoEScripts_CreateDirIfNotExist(Dir)

	; copy/replace/update files after checking if it's neccessary (files do not exist, files were changed in latest update)
	PoEScripts_CopyFiles(sourceDir, Dir, fileList)
	Return fileList
}

PoEScripts_CopyFiles(sourceDir, destDir, ByRef fileList) {
	overwrittenFiles := []
	PoEScripts_ConvertOldFiles(sourceDir, destDir, overwrittenFiles)
	PoEScripts_CopyFolderContentsRecursive(sourceDir, destDir, overwrittenFiles)

	; provide data for user notification on what files were updated/replaced and backed up if such
	If (overwrittenFiles.Length()) {
		fileList := ""
		Loop, % overwrittenFiles.Length() {
			If (!InStr(fileList, overwrittenFiles[A_Index])) {
				fileList .= "- " . overwrittenFiles[A_Index] . "`n"
			}
		}
	}
	Return
}

; TODO: this is temporary function and must be removed after a few releases
PoEScripts_ConvertOldFiles(sourceDir, destDir, ByRef overwrittenFiles) {
	If (FileExist(destDir "\MapModWarnings.txt")) {
		PoEScripts_BackupUserFileOnDate(destDir, "MapModWarnings.txt")
		PoEScripts_ConvertMapModsWarnings(destDir)
		FileDelete, %destDir%\MapModWarnings.txt
		overwrittenFiles.Push("MapModWarnings.txt")
	}
	If (!FileExist(destDir "\AdditionalMacros.ini") and FileExist(destDir "\AdditionalMacros.txt")) {
		PoEScripts_BackupUserFileOnDate(destDir, "AdditionalMacros.txt")
		PoEScripts_ConvertAdditionalMacrosSettings(destDir)
		FileDelete, %destDir%\AdditionalMacros.txt
		overwrittenFiles.Push("AdditionalMacros.txt")
	}
	If (FileExist(destDir "\config_trade.ini")) {
		PoeScripts_ConvertOldConfig(sourceDir, destDir, "config_trade.ini", overwrittenFiles)
	}
	If (FileExist(destDir "\config.ini")) {
		PoeScripts_ConvertOldConfig(sourceDir, destDir, "config.ini", overwrittenFiles)
	}
	if (InStr(FileExist(destDir "\data"), "D")) {
		PoEScripts_BackupUserFileOnDate(destDir, "data")
		FileRemoveDir, %destDir%\data, 1
	}
	Return
}

PoEScripts_ConvertOldConfig(sourceDir, destDir, fileFullName, ByRef overwrittenFiles) {
	OldConfigObj := PoEScripts_TrimEndingSpacesInKeys(class_EasyIni(destDir "\" fileFullName))
	if (InStr(fileFullName, "config_trade.ini")) {
		OldConfigObj := PoEScripts_RenameKeysTradeConfig(OldConfigObj)
	}
	NewConfigObj := class_EasyIni(sourceDir "\" fileFullName)
	if (!InStr(OldConfigObj.GetTopComments(), "Converted")) {
		PoEScripts_BackupUserFileOnDate(destDir, fileFullName)
		for sectionName, sectionKeys in NewConfigObj {
			if OldConfigObj.HasKey(sectionName) {
				for keyName, keyVal in NewConfigObj[sectionName] {
					if OldConfigObj[sectionName].HasKey(keyName) {
						keyValNew := OldConfigObj[sectionName, keyName]
						RegExMatch(keyValNew, """(.*?)""", foundQuotes)
						if (foundQuotes1 and InStr(fileFullName, "config_trade.ini")) {
							keyValNew := foundQuotes1
						}
						NewConfigObj.SetKeyVal(sectionName, keyName, keyValNew)
					}
				}
			}
		}
		FormatTime, ConvertedAt, A_NowUTC, dd-MM-yyyy
		NewConfigObj.AddTopComment("Converted with PoeScripts_ConvertOldConfig() on " ConvertedAt " / DO NOT EDIT OR REMOVE THIS COMMENT MANUALLY")
		NewConfigObj.Save(destDir "\" fileFullName)
		overwrittenFiles.Push(fileFullName)
	}
	Return
}

PoEScripts_ConvertAdditionalMacrosSettings(destDir) {
	FileRead, File_AdditionalMacros, %destDir%\AdditionalMacros.txt
	labelList := []
	_Pos := 1
	While (_Pos := RegExMatch(File_AdditionalMacros, "i)(global\sAM_.*)", labelStr, _Pos + StrLen(labelStr))) {
		labelList.Push(labelStr)
	}
	AdditionalMacros_INI := class_EasyIni()
	AdditionalMacros_INI.AddSection("General")
	AdditionalMacros_INI.AddKey("General", "KeyToSCState", 0)
	for labelIndex, labelContent in labelList {
		labelHotkeys := ""
		RegExMatch(labelContent, "(AM_.*?)\s", labelName)
		AdditionalMacros_INI.AddSection(labelName1)
		RegExMatch(labelContent, "\[(.*)\]", paramStr)
		for paramIndex, paramContent in StrSplit(paramStr1, ", ") {
			StringReplace, paramContent, paramContent, ",,All
			StringReplace, paramContent, paramContent, [,,All
			StringReplace, paramContent, paramContent, ],,All
			if (paramIndex == 1) {
				AdditionalMacros_INI.AddKey(labelName1, "State", paramContent)
			}
			else if (InStr(labelName1, "KickYourself") and paramIndex == 3){
				AdditionalMacros_INI.AddKey(labelName1, "CharacterName", paramContent)
			}
			else {
				if (labelHotkeys == "") {
					labelHotkeys := paramContent
				}
				else {
					labelHotkeys .= ", " paramContent
				}
			}
		}
		AdditionalMacros_INI.AddKey(labelName1, "Hotkeys", labelHotkeys)
	}
	FormatTime, ConvertedAt, A_NowUTC, dd-MM-yyyy
	AdditionalMacros_INI.AddTopComment("Converted with PoEScripts_ConvertAdditionalMacrosSettings() on " ConvertedAt " / DO NOT EDIT OR REMOVE THIS COMMENT MANUALLY")
	AdditionalMacros_INI.Save(destDir "\AdditionalMacros.ini")
	Return
}

PoEScripts_ConvertMapModsWarnings(destDir) {
	FileRead, MapModWarnings_TXT, %destDir%\MapModWarnings.txt
	MapModWarnings_JSON := JSON.Load(MapModWarnings_TXT)
	MapModWarnings_INI := class_EasyIni()
	;secGeneral := "General"
	secAffixes := "Affixes"
	;MapModWarnings_INI.AddSection(secGeneral)
	MapModWarnings_INI.AddSection(secAffixes)
	;If (MapModWarnings_JSON.HasKey("enable_Warnings")) {
	;	MapModWarnings_INI.AddKey(secGeneral, "enable_Warnings", MapModWarnings_JSON.enable_Warnings)
	;	MapModWarnings_JSON.Delete("enable_Warnings")
	;}
	For keyName, keyVal in MapModWarnings_JSON {
		MapModWarnings_INI.AddKey(secAffixes, keyName, keyVal)
	}
	FormatTime, ConvertedAt, A_NowUTC, dd-MM-yyyy
	MapModWarnings_INI.AddTopComment("Converted with PoEScripts_ConvertMapModsWarnings() on " ConvertedAt " / DO NOT EDIT OR REMOVE THIS COMMENT MANUALLY")
	MapModWarnings_INI.Save(destDir "\MapModWarnings.ini")
	Return
}

PoEScripts_CopyFolderContentsRecursive(SourcePath, DestDir, ByRef overwrittenFiles, DoOverwrite = false) {
	If (!InStr(FileExist(DestDir), "D")) {
		count := 0
		Loop, %SourcePath%\*.*, 1, 1
		{
			count++
		}
		If (count > 0) {
			FileCreateDir, %DestDir%
		}
		Else {
			Return
		}
	}
	Loop %SourcePath%\*.*, 1
	{
		If (InStr(FileExist(A_LoopFileFullPath), "D")) {
			PoEScripts_CopyFolderContentsRecursive(A_LoopFileFullPath, DestDir "\" A_LoopFileName, overwrittenFiles, DoOverwrite)
		}
		Else {
			fileAction := PoEScripts_GetActionForFile(A_LoopFileFullPath, DestDir)
			PoEScripts_DoActionForFile(fileAction, A_LoopFileFullPath, DestDir, overwrittenFiles)
		}
	}
	Return
}

PoEScripts_CleanFileName(fileName, removeStr="") {
	RegExMatch(fileName, "i)(" removeStr ")", removeThis)
	fileName_cleaned := RegExReplace(FileName, removeThis, "")
	Return fileName_cleaned
}

PoEScripts_TrimEndingSpacesInKeys(ConfigObject) {
	for sectionName, sectionKeys in ConfigObject {
    keyNamesList := StrSplit(ConfigObject.GetKeys(sectionName, "|", "C"), "|")
		for keyIndex, keyName in keyNamesList {
      RegExMatch(keyName, "^(.*?)\s*$", keyNameNew)
      ConfigObject.RenameKey(sectionName, keyName, keyNameNew1)
		}
	}
	Return ConfigObject
}

PoEScripts_RenameKeysTradeConfig(ConfigObject) {
	for sectionName, sectionKeys in ConfigObject {
		for keyName, keyVal in sectionKeys {
      keyNamesList := StrSplit(ConfigObject.GetKeys(sectionName, "|", "C"), "|")
      if (sectionName == "Hotkeys" or sectionName == "HotkeyStates") {
        for keyIndex, keyName in keyNamesList {
          if (sectionName == "Hotkeys") {
            RegExMatch(keyName, "i)^(.*?)Hotkey", keyNameNew)
          }
          if (sectionName == "HotkeyStates") {
            RegExMatch(keyName, "i)^(.*?)Enabled", keyNameNew)
          }
          if (keyNameNew1) {
            ConfigObject.RenameKey(sectionName, keyName, keyNameNew1)
          }
        }
      }
		}
	}
	Return ConfigObject
}

PoEScripts_GetActionForFile(filePath, destDir) {
	; List of possible actions:
	; - skip (=0)
	; - copy (=1)
	; - update (=2)
	; - replace (=3)
	SplitPath, filePath, fileFullName, fileDir, fileExt, fileName, fileDrive
	If (!RegExMatch(fileExt, "i)bak$")) {
		fileFullName_cleaned := PoEScripts_CleanFileName(fileFullName, "_dontOverwrite")
		If (!FileExist(DestDir "\" fileFullName_cleaned)) {
			Return 1
		}
		Else {
			If (fileFullName == fileFullName_cleaned) {
				If (RegExMatch(fileExt, "i)ini$")) {
					If (!class_EasyIni(destDir "\" fileFullName).Compare(fileDir "\" fileFullName)) {
						Return 2
					}
				}
				Else {
					Return 3
				}
			}
		}
	}
	Return 0
}

PoEScripts_DoActionForFile(fileAction, filePath, destDir, ByRef overwrittenFiles) {
	If (fileAction == 0) {
		Return
	}
	SplitPath, filePath, fileFullName, fileDir, fileExt, fileName, fileDrive
	fileFullName_cleaned := PoEScripts_CleanFileName(fileFullName, "_dontOverwrite")
	If (fileAction == 1) {
		FileCopy, %filePath%, %destDir%\%fileFullName_cleaned%, 1
		Return
	}
	Else {
		If (fileAction == 2) {
			; make backup
			PoEScripts_BackupUserFileOnDate(destDir, fileFullName)
			; load file into object
			destIniObj := class_EasyIni(destDir "\" fileFullName)
			; update object with source file
			destIniObj.Update(filePath)
			; TODO: add top comment with update date/script release version?
			; save changes to file
			destIniObj.Save(destDir "\" fileFullName)
			;overwrittenFiles.Push(fileFullName)
		}
		Else If (fileAction == 3) {
			; make backup
			PoEScripts_BackupUserFileOnDate(destDir, fileFullName_cleaned)
			; replace file
			FileCopy %filePath%, %destDir%\%fileFullName_cleaned%, 1
			overwrittenFiles.Push(fileFullName_cleaned)
		}
		Else {
			MsgBox, Unknown file action
			Return
		}
	}
	Return
}

PoEScripts_CreateDirIfNotExist(directory) {
	If (!InStr(FileExist(directory), "D")) {
		FileCreateDir, %directory%
	}
	Return
}

PoEScripts_BackupUserFileOnDate(destDir, fileFullName)
{
	if (FileExist(destDir "\" fileFullName)) {
		FormatTime, BackupOnDate, A_NowUTC, dd_MM_yyyy
		PoEScripts_CreateDirIfNotExist(destDir "\backup")
		PoEScripts_CreateDirIfNotExist(destDir "\backup\" BackupOnDate)
		if (!InStr(FileExist(destDir "\" fileFullName), "D")) {
			FileCopy, %destDir%\%fileFullName%, %destDir%\backup\%BackupOnDate%\%fileFullName%, 1
		}
		else {
			FileCopyDir, %destDir%\%fileFullName%, %destDir%\backup\%BackupOnDate%\%fileFullName%, 1
		}
	}
	Return
}

PoEScripts_isDevelopmentVersion(directory = "") {
	directory := StrLen(directory) ? directory : A_ScriptDir
	branch := ""
	If (FileExist(directory "\.git")) {
		If (FileExist(directory "\.git\HEAD")) {
			FileRead, head, %directory%\.git\HEAD
			Loop, Parse, head, `n, `r
			{
				RegExMatch(A_LoopField, "ref:.*\/(.*)", refs)
				If (StrLen(refs1)) {
					branch := "\dev_" . refs1
				}
			}
		}
	}
	Return branch
}
