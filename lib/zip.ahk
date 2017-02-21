/*
    Extract2Folder(Zip, Dest="", Filename="")
 
    Extract contents of a zip file to a folder using Windows Shell
    Based on code by shajul
    (http://www.autohotkey.com/board/topic/60706-native-zip-and-unzip-xpvista7-ahk-l/)
    
    Parameters
        Zip (required)
            If no path is specified then Zip is assumed to be in the Script Folder
        Dest (optional)
            Name of folder to extract to
            If not specified, a folder based on the Zip name is created in the Script Folder
            If a full path is not specified, then the specified folder is created in the Script Folder
        Filename (optional)
            Name of file to extract
            If not specified, the entire contents of Zip are extracted
            Only works for files in the root folder of Zip
            Wildcards not allowed
    
    Example usage:
        Extract2Folder("Test.zip")
            Extracts entire contents of Test.zip to a folder named 'Test' in the Script Folder
            The 'Test' folder will be created if it doesn't exist
            
        Extract2Folder("Test.zip",, "MyFile.txt")
            Extracts 'MyFile.txt' from the root folder of Test.zip to a folder named 'Test' in the Script Folder
            The 'Test' folder will be created if it doesn't exist
            
        Extract2Folder("Test.zip", "AnotherTest", "MyOtherFile.txt")
            Extracts 'MyOtherFile.txt' from the root folder of Test.zip to a folder named 'AnotherTest' in the Script Folder
            The 'AnotherTest' folder will be created if it doesn't exist
 
    Jess Harpur 2013
    It works for me on Windows 7 Home Premium SP1 64bit
    If it doesn't work for you, feel free to alter the code!   
*/
Extract2Folder(Zip, Dest="", Filename="")
{
	SplitPath, Zip,, SourceFolder
	if ! SourceFolder
		Zip := A_ScriptDir . "\" . Zip

	if ! Dest {
		SplitPath, Zip,, DestFolder,, Dest
		Dest := DestFolder . "\" . Dest . "\"
	}
	if SubStr(Dest, 0, 1) <> "\"
		Dest .= "\"
	SplitPath, Dest,,,,,DestDrive
	if ! DestDrive
		Dest := A_ScriptDir . "\" . Dest

	fso := ComObjCreate("Scripting.FileSystemObject")
	If Not fso.FolderExists(Dest)  ;http://www.autohotkey.com/forum/viewtopic.php?p=402574
		fso.CreateFolder(Dest)
	  
	AppObj := ComObjCreate("Shell.Application")
	FolderObj := AppObj.Namespace(Zip)
	if Filename {
		FileObj := FolderObj.ParseName(Filename)
		AppObj.Namespace(Dest).CopyHere(FileObj, 4|16)
	}
	else
	{
		FolderItemsObj := FolderObj.Items()
		AppObj.Namespace(Dest).CopyHere(FolderItemsObj, 4|16)
	}
}