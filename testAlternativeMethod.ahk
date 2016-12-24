payload := "league=Breach&type=&base=&name=Abyssus&dmg_min=&dmg_max=&aps_min=&aps_max=&crit_min=&crit_max=&dps_min=&dps_max=&edps_min=&edps_max=&pdps_min=&pdps_max=&armour_min=&armour_max=&evasion_min=&evasion_max=&shield_min=&shield_max=&block_min=&block_max=&sockets_min=&sockets_max=&link_min=&link_max=&sockets_r=&sockets_g=&sockets_b=&sockets_w=&linked_r=&linked_g=&linked_b=&linked_w=&rlevel_min=&rlevel_max=&rstr_min=&rstr_max=&rdex_min=&rdex_max=&rint_min=&rint_max=&mod_name=&mod_min=&mod_max=&group_type=And&group_min=&group_max=&group_count=1&q_min=&q_max=&level_min=&level_max=&ilvl_min=&ilvl_max=&rarity=&seller=&thread=&identified=&corrupted=0&online=x&has_buyout=1&altart=&capquality=x&buyout_min=&buyout_max=&buyout_currency=&crafted=&enchanted="
StartTime := A_TickCount

wb:=ComObjCreate("InternetExplorer.Application")

wb.Visible:=0,wb.Navigate("about:<!DOCTYPE html><meta http-equiv='X-UA-Compatible' content='IE=edge'>")


While(!Instr(rs,4)||StrLen(rs)<500)
	rs.=wb.ReadyState

document := wb.document ; shortcut
window := wb.document.parentWindow ; shortcut
my_form := document.createElement("Form")
my_form.name := "myForm"
my_form.method := "POST"
my_form.action := "http://poe.trade/search"
Loop, Parse, payload, `&
{
	params := StrSplit(A_LoopField, "=")
	key := params[1]
	value := params[2]
	my_tb := document.createElement("INPUT")
	my_tb.type := "TEXT"
	my_tb.name := key
	my_tb.value := value
	my_form.appendChild(my_tb)
}

document.body.appendChild(my_form)
my_form.submit()
While(wb.LocationURL = "http://poe.trade/" || wb.LocationURL = "about:" || wb.Busy)
{
	Sleep 50
}
url := wb.LocationURL
html := document.documentElement.outerHTML

ElapsedTime := (A_TickCount - StartTime) / 1000

FileDelete, %A_ScriptDir%\results.html
FileAppend, %html%, %A_ScriptDir%\results.html
wb.Quit
MsgBox, The search url is %url% and the html is in %A_ScriptDir%\results.html `n`n %ElapsedTime% milliseconds have elapsed.
Esc::ExitApp