PoE_Scripts_CheckFolderWriteAccess(Folder, critical = true) {
	access := FolderWriteAccess(Folder) 
	
	msg := "The script is not able to write any file to " Folder ".`nYour user may not have the necessary permissions. "
	msg .= "While it may be possible to manually copy and create files in this folder it doesn't work programmatically.`n`n"
	msg .= "The reason for this could be your AntiVir software blocking Autohotkey from modifying files in this directory!"
	
	If (not access) {
		If (critical) {
			msg .= "`n`nClosing Script..."
			Msgbox, 0x1010, Critical permission error, % msg
			ExitApp		
		} Else {			
			Msgbox, 4096, Permission error, % msg
		}
	}
	Return access
}

FolderWriteAccess(Folder) {
	If InStr( FileExist(Folder), "D" ) {
		FileAppend,,%Folder%\fa.tmp
		rval := ! ErrorLevel
		FileDelete, %Folder%\fa.tmp
		Return rval 
	} Return - 1  
}

	
