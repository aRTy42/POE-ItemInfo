#SingleInstance, force

userFolderPath = %1%

; don't use the fallback if it was completed successfully once
; 
global Fallback := True
If (FileExist(userFolderPath "\IEComObjectCall.txt")) {
	Fallback := False
}

url := "https://poe-trademacro.github.io/userCount/index.html"
Try {   
	wb1 := ComObjCreate("InternetExplorer.Application")
	wb1.Visible := False
	wb1.Navigate(url)	
	IELoad(wb1, loaded, userFolderPath)
	wb1.quit
} Catch error {
	If (Fallback) {
		Try {
			wb2 := ComObjCreate("InternetExplorer.Application")
			wb2.Visible := True		
			wb2.Navigate(url)
			IELoad(wb2, loaded, userFolderPath)
			wb2.quit
		} Catch e {
			ExitApp
		}	
	}	
}

ExitApp

IELoad(wb, ByRef loaded = false, path = "")	;You need to send the IE handle to the function unless you define it as global.
{
	i := 0
	If !wb    ;If wb is not a valid pointer then quit
		Return False
	Loop
	{
		Sleep,100
		Try {
			loaded := wb.Document.getElementById("loaded").innerHTML = "Loaded." ? true : false
		} catch e {
		
		}
		i++
	}
	Until ((wb.Document.Readystate = "Complete" and loaded or i = 2000))
	
	If (loaded and not FileExist(path "\IEComObjectCall.txt")) {
		FileAppend, true, %path%\IEComObjectCall.txt
		Fallback := False
	}
	
	Return True
}