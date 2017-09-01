#SingleInstance, force

url := "https://poe-trademacro.github.io/userCount/index.html"
Try {   
	wb := ComObjCreate("InternetExplorer.Application")
	wb.Visible := False
	wb.Navigate(url)	
	IELoad(wb)
	wb.quit
} Catch error {
	Try {
		wb := ComObjCreate("InternetExplorer.Application")
		wb.Visible := True		
		wb.Navigate(url)
		IELoad(wb)
		wb.quit
	} Catch e {
		ExitApp
	}
}

ExitApp

IELoad(wb)	;You need to send the IE handle to the function unless you define it as global.
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
	Return True
}