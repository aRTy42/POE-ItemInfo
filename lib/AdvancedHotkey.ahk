;_______________________ Hotkey() _______________________
;____ Date: June 2006
;____ AHK version: 1.0.44.06
;____ Platform: WinXP
;____ Authors: Sam & Roland


;#################### Example Gui ########################
/*
#SingleInstance, force

Gui, Margin, 5, 5
Gui, Add, Text,, Hotkey(Options="",Prompt="",Title="",GuiNumber=77)
Gui, Font, s10
Gui, Add, Text, w500
,Options:`n-Keynames/-Symbols -LR -~ -* -UP -Joystick -Mouse -Mods -&& +Default1/2 +OwnerN -Owner -Modal +ReturnKeynames +Tooltips

E1 = Hotkey()
E2 = Hotkey("+Default1 -LR -UP","Please hold down the keys you want to turn into a hotkey:")
E3 = Hotkey("+Default1 -Symbols +ReturnKeynames +Tooltips","","","Hotkey configuration")
E4 = Hotkey("+Default2 -Mouse -Keynames -Modal -LR","Note that you're able to interact with the owner")
E5 = Hotkey("-~ -* -Up -LR +Owner2","This window has no owner, since a non-existen owner (Gui2) was specified")

Gui, Font, s8
Loop, 5
	{
		Gui, Add, Text, w500, % E%a_index% ":"
		Gui, Add, ListView
		, v%a_index% r1 -Hdr -LV0x20 r1 w200 cGreen BackgroundFFFACD gLV_DblClick, 1|2
		LV_ModifyCol(1, 0)
		LV_ModifyCol(2, 195)
	}
Gui, Font, s10
Gui, Add, Text, w500, Note: Double-click on one on one of the ListViews to test the Hotkey dialogue.
Gui, Show, x100 y100 Autosize, Hotkey()	
Return

GuiClose:
ExitApp

LV_DblClick:
If a_guicontrolevent <> DoubleClick
	return
Gui, ListView, %a_guicontrol%
LV_Delete(1)
If a_guicontrol = 1
		LV_Add("","",Hotkey())
else if a_guicontrol = 2
		LV_Add("","",Hotkey("+Default1 -LR -UP","Please hold down the keys you want to turn into a hotkey:"))
else if a_guicontrol = 3
		LV_Add("","",Hotkey("+Default1 -Symbols +ReturnKeynames +Tooltips","","","Hotkey configuration"))
else if a_guicontrol = 4
		LV_Add("","",Hotkey("+Default2 -Mouse -Keynames -Modal -LR","Note that you're able to interact with the owner"))
else if a_guicontrol = 5
		LV_Add("","",Hotkey("-~ -* -Up -LR +Owner2","This window has no owner, since a non-existen owner (Gui2) was specified"))
return
*/

/*
#############################################################################
################################ Funtions ########################################
#############################################################################


************************************************** Remarks: **************************************************
-It would have been to hard (and to messy) to compact everything into a single funtion, so we have a few globals.
	All the globals (and all the subroutines) start with "Hotkey_" though, so this shouldn't be a problem
-Both the keyboard and mouse hook will be installed 
-"Critical" has to be turned off for the thread that called the funtion, to allow the threads in the funtion to run.
 This could cause problems obviously, although turning Critical back on after calling the funtion should work okay in most cases
-When the user clicks "Submit", the funtion will create the hotkey (If non-blank) and check ErrorLevel (and If ErrorLevel <> 0 
	display a Msgbox saying the hotkey is invalid and asking to notify the author). This way you shouldn't have to worry about 
  invalid hotkeys yourself.
-You can easily change the default color and font by editing the default values right at the top of the funtion.
	Should be easy to spot.
-Also, You can easily change the default behavior by changing the Options param right at the top of the funtion
	(for instance: Options = %Options% +Default1 -Mouse). You can also edit the keyList of course.


########################## The main funtion ############################

Note: The following funtions must all be present (they are included here, but I thought 
        I had better mention it):
        
Hotkey(Options="",Prompt="",BottomInfo="",Title="",GuiNumber=77)
AddPrefixSymbols(keys)
KeysToSymbols(s)
Keys()
ToggleOperator(p)
IsHotkeyValid(k)


######## Options ########
Zero or more of the following strings may be present in Options. ; Spaces are optional, 
i.e. "-~-*+Default2" is valid. -/+ are NOT optional, though. I.e. "Owner3" is invalid:

-Keynames/-Symbols: Omits one of the ListViews
-LR: Omit the "left/right modifiers" checkbox (forced for Win95/98/ME)
-~, -*, -Up: Omit one or more of the corresponding checkboxes (forced for Win95/98/ME)
-Joystick/-Mouse: No joystick and/or mouse hotkeys
-Mods: No modifers
-&: No ampersand hotkeys (forced for Win95/98/ME)
+Default1, +Default2: Sets the default button (and omits the Enter key from the keyList)
+Owner*: Sets the owner. Default is A_Gui, or 1 If A_Gui is blank (or none If Gui1 doesn't exist)
-Owner: No owner
-Modal: The dialogue will be owned, but not modal
+ReturnKeynames: Return "Control+Alt+c" instead of "^!c" etc. These can later be converted by calling the KeysToSymbols(s) funtion
+Tooltips: Gives a little info about "~", "*" and "UP" (basically copied from the docs)
*/
 

;this funtion will Return a (hopfully) valid key combination, either
;as symbols (^!+..) or as keynames (Control+Alt+Shift+Space...)
Hotkey(Options="",Prompt="",BottomInfo="",Title="",GuiNumber=77)
{
	global Hotkey_LeftRightMods,Hotkey_Tilde,Hotkey_Wildcard,Hotkey_UP,Hotkey_Hotkey1,Hotkey_Hotkey2
				,Hotkey_ButtonSubmit,Hotkey_ButtonCancel,Hotkey_DefaultButton,Hotkey_keyList,Hotkey_modList_left_right
				,Hotkey_modList_normal,Hotkey_JoystickButtons,Hotkey_OptionsGlobal,Hotkey_numGui

	;these are all cleared again before the funtion Returns, to be on the safe side
	HotKey_globals = Hotkey_LeftRightMods,Hotkey_Tilde,Hotkey_Wildcard,Hotkey_UP,Hotkey_Hotkey1,Hotkey_Hotkey2
				,Hotkey_ButtonSubmit,Hotkey_ButtonCancel,Hotkey_DefaultButton,Hotkey_keyList,Hotkey_modList_left_right
				,Hotkey_modList_normal,Hotkey_JoystickButtons,Hotkey_OptionsGlobal,Hotkey_numGui

	batch_lines = %A_BatchLines%
	SetBatchLines -1		;this speeds things up a bit (we reset it after the Gui is shown)

	;change these to suit your needs:
	;default colors, etc. 
	defBgColor = 
	defTxtColor = 000000
	defLVBgColor = FFFFFF
	defLVTxtColor1 = Green
	defLVTxtColor2 = 6495ED
	defFontName = Arial
	defFontSize = 8
	defTitle = Hotkey

	;Note: To change the default behavior permenantly, just add:
	;Options = %Options%***MyFavoriteOptions*** 

	;we can't have the special prefix symbols or the & on Win95/98/ME
	;so we just edit the Options param to exclude them
	If A_OSType = WIN32_WINDOWS		
		Options = %Options%-~-*-Up-&-lr

	;this is a bit akward but we have to store the Gui # in a seperate variable
	;because GuiNumber is a parameter and we can't declare it as global
	If GuiNumber <>
		Hotkey_numGui = %GuiNumber%
	Else
		Hotkey_numGui = 77

	;because we use ListViews (who operate on the default Gui), we have
	;to set the default in every thread that operates on the ListViews
	Gui, %Hotkey_numGui%: Default	

	;it's global, so we have to empty it
	Hotkey_JoystickButtons =
	;get a list of joystick buttons
	IfNotInString, Options, -Joystick
	{
	;Query each joystick number to find out which ones exist.
	Loop 32
	   {
		;If the joystick has a name
		GetKeyState, joy_name, %A_Index%JoyName
		If joy_name <>
		 {
		  ;It's our joystick.
		  joy_number = %A_Index%
		  joy_exists = 1
		  break
		 }
	   }
	  ;If we don't have a joystick
	  If joy_number <= 0
	   {
		;record it so.
		joy_exists = 0
	   }
	  ;If we do have a joystick
	  Else
	   {
		;Determine the number of buttons.
		GetKeyState, num_buttons, %joy_number%JoyButtons
		;Go through the buttons
		Loop, %num_buttons%
		 {
		  newButton = Joy%a_index%
		  Hotkey_JoystickButtons = %Hotkey_JoystickButtons%,%newButton%
		 }
		StringTrimLeft, Hotkey_JoystickButtons, Hotkey_JoystickButtons, 1
	   }
	}

	;the main key list. Add (or delete) keys to suit your needs
	Hotkey_keyList =
	( Join
	#|.|,|-|<|+|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|ü|ä|ö|ß|1|2|3|4|5|6|7|8|9|0
	|Numpad0|Numpad1|Numpad2|Numpad3|Numpad4|Numpad5|Numpad6|Numpad7|Numpad8|Numpad9
	|NumpadClear|Right|Left|Up|Down|NumpadDot|Space|Tab|Escape|Backspace|Delete|Insert|Home
	|End|PgUp|PgDn|ScrollLock|CapsLock|NumLock|NumpadDiv|NumpadMult|NumpadAdd|NumpadSub
	|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|F13|F14|F15|F16|AppsKey|PrintScreen|CtrlBreak|Pause|Break
	|Browser_Back|Browser_Forward|Browser_Stop|Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute
	|Volume_Down|Volume_Up|Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media
	|Launch_App1|Launch_App2|Sleep
	)

	;If we have a default button, the Enter key can't be part of the key list
	IfNotInString, Options, +Default
		Hotkey_keyList = %Hotkey_keyList%|Enter

	;add the mouse buttons to the list 
	MouseButtons = LButton|RButton|MButton|XButton1|XButton2
	IfNotInString, Options, -Mouse
		Hotkey_keyList = %Hotkey_keyList%|%MouseButtons%

	;If -LR is present in Options, the two modifier key lists are the same
	;Else we have two different lists. Which one is used depends on whether
	;the "left/right modifiers" checkbox is checked or not
	IfNotInString, Options, -lr
		Hotkey_modList_left_right = LControl,RControl,LAlt,RAlt,LWin,RWin,LShift,RShift
	Else
		Hotkey_modList_left_right = Control,Alt,LWin,RWin,Shift
	Hotkey_modList_normal = Control,Alt,LWin,RWin,Shift

	;these will be turned into hotkeys to override their native funtion
	;(we don't want calculator to launch when the user presses Launch_App1 etc...)
	turnIntoHotkeyList =
	(Join
	PrintScreen|CtrlBreak|Pause|Break
	|Browser_Back|Browser_Forward|Browser_Stop|Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute
	|Volume_Down|Volume_Up|Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media
	|Launch_App1|Launch_App2|Sleep|Control|Alt|LWin|RWin|Shift
	)

	;destroy the Gui, just in case
	Gui, %Hotkey_numGui%: Destroy

	;Owner/modal handling; by default, the Gui is owned, either by %a_gui% or
	;by Gui1 If %a_gui% is blank. If the owner doesn't exist, well, it will not be owned!
	IfNotInString, Options, -Owner
		{
			IfInString, Options, +Owner
				{
					StringMid, owner, Options, InStr(Options, "+Owner") + 7, 2
					If owner not integer
						StringTrimRight, owner, owner, 1
					If owner = 
						StringTrimLeft, owner, Options, InStr(Options, "+Owner") + 5
				}
			Else
			{
					If a_gui <>
						owner = %a_gui%
					Else
						owner = 1
			}
		Gui, %owner%: +LastfoundExist
		IfWinExist
			{
			IfNotInString, Options, -Modal
				Gui, %owner%: +Disabled
			Gui, %Hotkey_numGui%: +Owner%owner%
			}
		Else
			owner =
		}

	;the Gui has no Close button (this way we're flexible with the Gui #)
	Gui, %Hotkey_numGui%:+Lastfound +Toolwindow -SysMenu	
	GuiID := WinExist()		;used for Hotkey, IfWinActive, ahk_id%GuiID%
		
	Gui, %Hotkey_numGui%:Font, s%defFontSize% bold c%defTxtColor%, %defFontName%
	Gui, %Hotkey_numGui%:Margin, 5, 5
	Gui, %Hotkey_numGui%:Color, %defBgColor%
	If prompt <>
		Gui, %Hotkey_numGui%:Add, Text, w220, %Prompt%
	If prompt <>
		Gui, %Hotkey_numGui%:Add, Text, w220 cRed, (Assigning currently requires a script reload)
	IfNotInString, Options, -KeyNames
		Gui, %Hotkey_numGui%:Add, ListView
		, vHotkey_Hotkey1 r1 -Hdr -LV0x20 r1 w220 c%defLVTxtColor1% Background%defLVBgColor%, 1|2
	Else
		Gui, %Hotkey_numGui%:Add, ListView
		, vHotkey_Hotkey1 r1 -Hdr -LV0x20 r1 w220 c%defLVTxtColor1% Background%defLVBgColor% Hidden, 1|2
	LV_ModifyCol(1, 0)
	LV_ModifyCol(2, 195)
	IfInString, Options, -Symbols
		hidden = hidden
	If (InStr(Options, "-Symbols") <> 0 OR InStr(Options, "-KeyNames") <> 0)
		Gui, %Hotkey_numGui%:Add, ListView
		, vHotkey_Hotkey2 r1 -Hdr -LV0x20 r1 w220 c%defLVTxtColor2% Background%defLVBgColor% %hidden% xp yp, 1|2
	Else
		Gui, %Hotkey_numGui%:Add, ListView
		, vHotkey_Hotkey2 r1 -Hdr -LV0x20 r1 w220 c%defLVTxtColor2% Background%defLVBgColor%, 1|2
	LV_ModifyCol(1, 0)
	LV_ModifyCol(2, 195)

	;this is a bit of a mess, because we optionally have to exclude some of these..
	If Options not contains -lr,-mods
		Gui, %Hotkey_numGui%:Add, Checkbox, vHotkey_LeftRightMods, left/right modifiers
		IfNotInString, Options, -~
			{
			Gui, %Hotkey_numGui%:Add, Checkbox, vHotkey_Tilde Section gHotkey_Tilde, ~
			ys = ys
			}
		IfNotInString, Options, -*
			{
			Gui, %Hotkey_numGui%:Add, Checkbox, vHotkey_Wildcard %ys% Section gHotkey_Wildcard, *
			ys = ys
			}				
		Else If ys =
			ys =
		IfNotInString, Options, -Up
			Gui, %Hotkey_numGui%:Add, Checkbox, vHotkey_UP %ys% gHotkey_UP, UP


	Gui, %Hotkey_numGui%:Font, norm
	Gui, %Hotkey_numGui%:Add, Button, vHotkey_ButtonSubmit x62.5 Section w50 h20 gHotkey_Submit, Submit
	Gui, %Hotkey_numGui%:Add, Button, vHotkey_ButtonCancel h20 ys w50 gHotkey_Cancel, Cancel
	Gui, %Hotkey_numGui%:Add, Text, x5 y+10 w220, % BottomInfo
	;the Timer sets focus to this button all the time to avoid key combinations triggering a focused checkbox
	Gui, %Hotkey_numGui%:Add, Button, vHotkey_DefaultButton x0 y0 w0 h0

	;set the default button If called for
	IfInString, Options, +Default
		{
			StringMid, defButton, Options, InStr(Options, "+Default") + 8, 1
			If defButton = 1
				GuiControl, %Hotkey_numGui%:+Default, Hotkey_ButtonSubmit
			Else If defButton = 2
				GuiControl, %Hotkey_numGui%:+Default, Hotkey_ButtonCancel
		}

	;the default title
	If title =
		title = %defTitle%

	;turn these keys into a hotkeys to try
	;and override their native funtion 
	Hotkey, IfWinActive, ahk_id%GuiID%
	Loop, Parse, turnIntoHotkeyList, |
				Hotkey, %a_loopfield%, Return, UseErrorLevel

	IfNotInString, Options, -Mouse
		{
			Hotkey, *WheelUp, Wheel, UseErrorLevel 
			Hotkey, *WheelDown, Wheel, UseErrorLevel
		}

	;If we have an owner, center the Gui on it
	If owner <> 
		{
			Gui, %Hotkey_numGui%:Show, Autosize Hide
			Gui, %owner%: +Lastfound
			WinGetPos, x, y, w, h
			Gui, %Hotkey_numGui%:+Lastfound
			WinGetPos,,,gw,gh
			gx := x + w/2 - gw/2
			gy := y + h/2 - gh/2
			Gui, %Hotkey_numGui%: Show, x%gx% y%gy%, %title%
		}
	Else
		Gui, %Hotkey_numGui%:Show, Autosize, %title%
		
	;400 is about right, but feel free to experiment
	;basically you have to keep the balance between registering new keys fast enough
	;but not registering the release of keys TOO fast
	SetTimer, Hotkey_Hotkey, 400	

	;we need Options to be global so that the other functions can use it
	;so we store it in another variable
	Hotkey_OptionsGlobal = %Options%

	Gui, %Hotkey_numGui%:+Lastfound
	Critical Off		;has to be turned off to allow the other threads to run
	SetBatchLines %batch_lines%		;reset it

	WinWaitClose

	SetTimer, Hotkey_Hotkey, Off		;turn off the timer
	Tooltip		;in case we were displaying a tooltip
	Tooltip,,,,2

	;free all the globals, to be on the safe side:
	Loop, Parse, HotKey_globals, `,
		%a_loopfield% =

	;reset the default Gui
	If owner <>
		Gui, %owner%: Default
	Else If a_gui <> 
		Gui, %a_gui%: Default
	Else
		Gui, 1: Default
		
	;re-enable and activate the owner
	If owner <>
		{
		Gui, %owner%: -Disabled
		Gui, %owner%: Show
		}
		
	Return ReturnValue	

	;####################### Timer ####################

	Hotkey_Hotkey:
	IfWinNotActive, ahk_id%GuiID%
		Return
		
	Gui, %Hotkey_numGui%: Default	

	;If the mouse isn't over a control, set focus to an (invisible) button
	MouseGetPos,,,win,ctrl
	If (win <> GuiID OR ctrl = "")
		{
			GuiControl, Focus, Hotkey_DefaultButton
			Tooltip,,,,2		;we use tooltip1 to display a message Elsewhere, so use #2
		}
	Else IfInString, Hotkey_OptionsGlobal, +Tooltips		;If we want tooltips
		{
			ControlGetText, t, %ctrl%, ahk_id%win%
			If t = ~
				tip = Tilde: When the hotkey fires, its key's`nnative function will not be blocked`n(hidden from the system). 
			Else If t = *
				tip = Wildcard: Fire the hotkey even If extra`nmodifiers are being held down. 
			Else If t = UP
				tip = Causes the hotkey to fire upon release of the key`nrather than when the key is pressed down.
			Else 
				tip =
			Tooltip %tip%,,,2
		}
		
	keys := Keys()			;get the keys that are beeing held down

	;If no keys are down, find out If we're looking at something 
	;like "Control+Alt+" or a valid hotkey, and clear the ListView 
	;in case #1
	If keys =
		{
			Gui, ListView, Hotkey_Hotkey1
			LV_GetText(k, 1, 2)
			;If UP is checked we could have "Ctrl+Alt+ UP", so get rid of the UP
			StringReplace, k, k, %a_space%UP		
			;If the right-most char is a "+" but we don't have "++" (e.g. "Ctrl+Alt++"), clean up
			If (InStr(k, "+","",0) = StrLen(k) AND InStr(k, "++") = 0)
				{
					LV_Delete(1)
					Gui, ListView, Hotkey_Hotkey2
					LV_Delete(1)
					;clear keys_prev in this case
					keys_prev =
				}
			Return		;nothing Else
		}

	;this avoids flickering
	If keys = %keys_prev%
		Return
	keys_prev = %keys%

	;this handles differing between, say, "Space & LButton" and "LButton & Space"
	;by remembering which key was pressed first (otherwise the keys would always
	;be in the order they appear in the keyList
	IfNotInString, keys, +		;If we have only a single key, remember it
		firstKey = %keys%
	;Else If we have more than one but no modifier(s)
	Else If keys not contains %Hotkey_modList_left_right%,%Hotkey_modList_normal%,Win	
		{
			If InStr(keys, firstKey) <> 1		;If they're in the wrong order
				{
					StringLeft, k1, keys, InStr(keys, "+") - 1		;swap them
					StringTrimLeft, k2, keys, InStr(keys, "+") 
					keys = %k2%+%k1%
				}
		}

	;add the special prefix keys from the checkboxes
	keys := AddPrefixSymbols(keys)

	;delete old keys and add new ones
	Gui, %Hotkey_numGui%: ListView, Hotkey_Hotkey1
	LV_Delete(1)
	LV_Add("","",keys)

	Gui, ListView, Hotkey_Hotkey2
	LV_Delete(1)
	LV_Add("","",KeysToSymbols(keys))
	Return

	;############# checkbox labels ###########

	;these all call the same function... easier that way
	Hotkey_Tilde:
	Hotkey_Wildcard:
	Hotkey_Up:
	ToggleOperator(a_guicontrol)
	Return

	;########## Remove the tooltip and the pseudo label for the Hotkey #####

	Hotkey_RemoveTooltip:
	Tooltip
	Return

	Return:
	Return

	;############### The Label for WheelUp&WheelDown ##################

	Wheel:
	StringTrimLeft, w, a_thishotkey, 1		;remove the "*" from WheelUp/Down

	Gui, %Hotkey_numGui%: Default
	Gui, %Hotkey_numGui%: Submit, NoHide

	;in this case only check for modifiers
	IfInString, Hotkey_OptionsGlobal, -&
		{
			mods =
			
			;If -LR is not present in options AND the LR checkbox is checked,
			;use the left/right mod list
			If (InStr(Hotkey_OptionsGlobal, "-LR") = 0 AND Hotkey_LeftRightMods <> 0)
				modList = %Hotkey_modList_left_right%
			Else
				modList = %Hotkey_modList_normal%
				
			Loop, Parse, modList, `,
				{
					If GetKeyState(a_loopfield,"P") <> 1
						continue
					mods = %mods%%a_loopfield%+
				}
			
			If Hotkey_LeftRightMods <> 1
				{
					StringReplace, mods, mods, LWin, Win
					StringReplace, mods, mods, RWin, Win
				}
			
			k = %mods%%w%	;the keys are the modifiers plus WheelUp/down
			
			If k = %k_prev%
				Return
			k_prev = %k%
			
			;add the prefix symbols
			k := AddPrefixSymbols(k)
			
			;add them to the LV and Return
			Gui, ListView, Hotkey_Hotkey1
			LV_Delete(1)
			LV_Add("","",k)
			Gui, ListView, Hotkey_Hotkey2
			LV_Delete(1)
			LV_Add("","",KeysToSymbols(k))
		  Return
		}

	;If "-&" is not present in Options, get all the keys, like in the Hotkey_Hotkey timer:

	k := Keys()			

	;just in case somebody tries mapping "Joy3 & WheelUp" or whatever :)
	If k in %Hotkey_JoystickButtons%
		{
			Tooltip, Note: Joystick buttons are not`nsupported as prefix keys.
			SetTimer, Hotkey_RemoveTooltip, 5000
			k =
		}

	If (InStr(k, "+","",0) <> StrLen(k))	;If it's not something like "Control+Alt+"
		{
		IfInString, k, +		;If we have more than one key, remove all but the first (can't have "a & b & WheelUp")
			StringLeft, k, k, InStr(k, "+","",0)
		Else
			k = %k%+		;turn "Space" into "Space+" etc...
		}
		
	k = %k%%w%		;add WheelUp/Down

	If k = %k_prev%
		Return
	k_prev = %k%

	;add the prefix symbols
	k := AddPrefixSymbols(k)

	;add the keys to the ListViews:
	Gui, ListView, Hotkey_Hotkey1
	LV_Delete(1)
	LV_Add("","",k)
	Gui, ListView, Hotkey_Hotkey2
	LV_Delete(1)
	LV_Add("","",KeysToSymbols(k))
	Return

	;################### Submit & Cancel ##################### 

	Hotkey_Submit:
	Gui, %Hotkey_numGui%: Default
	Gui, ListView, Hotkey_Hotkey1
	LV_GetText(k, 1, 2)
	;call IsHotkeyValid() to find out If this is a "real" hotkey
	;If not, just destroy the Gui and Return
	If IsHotkeyValid(k) = -1
		{
			Gui, %Hotkey_numGui%:Destroy
			Return
		}
	IfNotInString, Options, +ReturnKeynames		;If we should Return symbols, get those
		{
			Gui, ListView, Hotkey_Hotkey2
			LV_GetText(ReturnValue, 1, 2)
		}
	Else
		ReturnValue = %k%	;we got keynames already
	Gui, %Hotkey_numGui%:Destroy
	
	; make single word characters in hotkeys upper case
	; simple version, only works if there are no multi word character strings 
	If (ReturnValue) {
		If (not RegExMatch(ReturnValue, "([\w]{2,})")) {
			StringUpper, ReturnValue, ReturnValue
		}
	}
	
	Return

	Hotkey_Cancel:
	Gui, %Hotkey_numGui%:Destroy
	Return
}

;###################### Other funtions ######################

;this has to bee done in three different places, so it's a seperate funtion
;it checks which checkboxes are checked ... ugh ... and adds the symbols in the right places
;note that we can't have any of the symbols with Joystick buttons, and that " * " and "&"
;can't be present in the same hotkey
AddPrefixSymbols(keys)
{
	global Hotkey_JoystickButtons,Hotkey_Tilde,Hotkey_Wildcard,Hotkey_UP,Hotkey_numGui

	Gui, %Hotkey_numGui%:Submit, NoHide

	;joystick buttons can't have prefix keys, therefore uncheck all the checkboxes
	If keys in %Hotkey_JoystickButtons%	
		{
			GuiControl,, Hotkey_Tilde, 0
			GuiControl,, Hotkey_Wildcard, 0
			GuiControl,, Hotkey_UP, 0
		}
	Else
		{
	If Hotkey_Tilde = 1
		keys = ~%keys%
	If Hotkey_Wildcard = 1
		{
			;the wildcard can't be present together with the ampersand
			If (InStr(KeysToSymbols(keys), "&") = 0)
				keys = *%keys%
			Else
				{
				GuiControl,, Hotkey_Wildcard, 0
				Tooltip, The * prefix is not allowed in hotkeys`nthat use the ampersand (&).
				SetTimer, Hotkey_RemoveTooltip, 5000
				}
		}
	If Hotkey_UP = 1
		keys = %keys%%a_space%UP
	}
	Return keys
}

;________________________________________________________

;this funtion turns, say, "Control+Alt+Win+Space" into "^!#Space" etc.
;this is handy since when you use the "+ReturnKeynames" option, you can 
;convert to hotkey symbols later using this funtion
KeysToSymbols(s)
{
	global Hotkey_modList_left_right,Hotkey_modList_normal,Hotkey_LeftRightMods,Hotkey_numGui

	Gui, %Hotkey_numGui%:Submit, NoHide
	;grab the correct modList
	If Hotkey_LeftRightMods = 1
		modList = %Hotkey_modList_left_right%
	Else
		modList = %Hotkey_modList_normal%

	;If the keys don't contain a modifier, it has to be something
	;like "a+b", so turn it into "a & b" and Return
	If s not contains %modList%,Win
			{
						StringReplace, s, s, +, %a_space%&%a_space%
						Return s
			}
	;Else, replace the keynames with the appropriate symbols
	StringReplace, s, s, LControl+, <^
	StringReplace, s, s, RControl+, >^
	StringReplace, s, s, Control+, ^
	StringReplace, s, s, LAlt+, <!
	StringReplace, s, s, RAlt+, >!
	StringReplace, s, s, Alt+, !
	StringReplace, s, s, LShift+, <+
	StringReplace, s, s, RShift+, >+
	StringReplace, s, s, Shift+, +
	StringReplace, s, s, LWin+, <#
	StringReplace, s, s, RWin+, >#
	StringReplace, s, s, Win+, #
	Return s
}

;__________________________________________________

;this function checks which keys are beeing held down using the correct modList 
Keys()
{
	global Hotkey_keyList,Hotkey_modList_left_right,Hotkey_modList_normal,Hotkey_LeftRightMods
					,Hotkey_JoystickButtons,Hotkey_OptionsGlobal,Hotkey_numGui

	Gui, %Hotkey_numGui%:Submit, NoHide

	;grab the correct modList
	If Hotkey_LeftRightMods = 1
		modList = %Hotkey_modList_left_right%
	Else
		modList = %Hotkey_modList_normal%

	;If we don't want modifiers, just make it blank
	IfInString, Hotkey_OptionsGlobal, -mods
		modList =

	;check joystick buttons first, since we can have only one
	;and no modifiers. If we find one, just Return it, nothing Else
	Loop, Parse, Hotkey_JoystickButtons, `,
		{
			If GetKeyState(a_loopfield, "P") = 1
				Return a_loopfield
		}

	;check for modifiers
	Loop, Parse, modList, `,
		{
			If GetKeyState(a_loopfield,"P") <> 1
				continue
			mods = %mods%%a_loopfield%+
		}

	;GetKeyState("Win") doesn't work, which is why both modLists include 
	;both variants. So replace L/RWin with Win here If needed
	If Hotkey_LeftRightMods <> 1
		{
			StringReplace, mods, mods, LWin, Win
			StringReplace, mods, mods, RWin, Win
		}

	;check If other keys are beeing held down
	Loop, Parse, Hotkey_keyList, |
		{
			If GetKeyState(a_loopfield,"P") <> 1
				continue
			;If ithe left mouse button is down, check If the user is clicking a control
			;(and ignore it If that's the case)
			If a_loopfield = LButton
				{
					MouseGetPos,,,,ctrl
					If (ctrl <> "" AND InStr(ctrl, "SysListView") = 0)
						continue
				}
			;If we don't want the ampersand (either because specified in options, or
			;because we're on Win95/98/ME, just Return the first key we find (plus mods)
			IfInString, OptionsGlobal, -&
				{
				keys = %mods%%a_loopfield%
				Return keys
				}
			;If this is the second time we get to this point in the loop...
			;we must already have a key -> the user is holding down two keys
			;in this case, ignore any modifiers and just Return our two keys
			If keys <>
				{
				keys = %keys%+%a_loopfield%
				Return keys
				}		
			;Else If keys is still blank, take this key
			keys = %a_loopfield%
		}

	;If we get to this point, the user is holding down only one key (from the keyList)
	;so we can add the modifiers, If we found some
	If mods <>
		keys = %mods%%keys%
	Return %keys%
}

;_______________________________________________________________

;this funtion gets called everytime the user clicks one of the checkboxes
ToggleOperator(p)
{
	global Hotkey_Tilde,Hotkey_Wildcard,Hotkey_UP,Hotkey_JoystickButtons,Hotkey_numGui

	;we need to turn on CaseSense because we could have, say, Up UP :)
	StringCaseSense On	
	AutoTrim Off		;because of the space between the keys and the UP symbol

	Gui, %Hotkey_numGui%:Submit, NoHide

	;this is kinda confusing, but I'm not changing it now...
	ctrl = %p%

	;"p" is a_guicontrol btw...
	If p = Hotkey_Tilde
		p = ~
	Else If p = Hotkey_Wildcard
		p = *
	Else If p = Hotkey_UP
		p = %a_space%UP

	Loop 2
		{
			Gui, ListView, Hotkey_Hotkey%a_index%
			LV_GetText(k%a_index%,1,2)
		}

	;If it's a joytick button, we can't have any special operators
	If Hotkey_JoystickButtons <>
		{
			If k1 in %Hotkey_JoystickButtons%
				{
					GuiControl,, %ctrl%, 0
					Tooltip, This operator is not supported`nfor joystick buttons.
					SetTimer, Hotkey_RemoveTooltip, 5000
					Return
				}
		}

	;If a_guicontrol is not checked (i.e. is was unchecked), 
	;remove the prefix, edit the Listviews and Return
	If %ctrl% <> 1
		{
			StringReplace, k1, k1, %p%
			StringReplace, k2, k2, %p%
			Loop 2
				{
					Gui, ListView, Hotkey_Hotkey%a_index%
					LV_Delete(1)
					LV_Add("","", k%a_index%)
				}
			Return
		}


	If p = ~
		{
			k1 = ~%k1%
			k2 = ~%k2%
		}
	Else If p = *
		{
			IfNotInString, k2, &			;we can't have both " * " and "&" 
				{
					k1 = *%k1%
					k2 = *%k2%
				}
			Else
			{
				GuiControl,, Hotkey_Wildcard, 0
				Tooltip, The * prefix is not allowed in hotkeys`nthat use the ampersand (&).
				SetTimer, Hotkey_RemoveTooltip, 5000
			}
		}
	Else If p contains UP			
		{
			k1 = %k1%%p%
			k2 = %k2%%p%
		}		
	;edit the ListViews
	Loop 2
		{
			Gui, ListView, Hotkey_Hotkey%a_index%
			LV_Delete(1)
			LV_Add("","", k%a_index%)
		}
}

;_____________________________________________________

;this funtion checks If a) it's some kind of a sensible hotkey,
;i.e not Ctrl+Alt+, ~ UP, etc., and b) that it's a valid hotkey
;If it's not, the funtion Returns -1, Else it Returns 1
IsHotkeyValid(k)
{
	If k =
		Return -1
		
	;If UP is checked we could have "Ctrl+Alt+ UP", so get rid of the UP
	StringReplace, k, k, %a_space%UP		
	;If the right-most char is a "+" but we don't have "++" (e.g. "Ctrl+Alt++"),
	;it's not a "real" hotkey - most likely the user clicked okay while 
	;holding down some modifiers. We can't have that...
	If (InStr(k, "+","",0) = StrLen(k) AND InStr(k, "++") = 0)
		Return -1
		
	;these are all valid hotkeys, but we don't really want these either
	If k in ,*,~, UP,*~,~*,* UP,~ UP,*~ UP
		Return -1

	;turn it into a hotkey to check ErrorLevel. 
	;convert to symbols before we do this

	k := KeysToSymbols(k)

	Hotkey, %k%, Return, UseErrorLevel
	If ErrorLevel <> 0
		{
			;Joystick buttons cause an incorrect ErrorLevel on WinXP (see my post in Bug Reports)
			;so ignore it
			If (A_OSType <> "WIN32_WINDOWS" AND ErrorLevel = 51 AND InStr(k, "Joy") <> 0)
				{
					Hotkey, %k%, Return, Off
					Return 1
				}
			Else		;notify user
				{
					ErrorMessage =
						(LTrim
						Sorry, this hotkey (%k%) is invalid.
						To find out why, please look up Error #%ErrorLevel% under the "Hotkey" command in the AHK command list.
						Also, please report this Error to the author of this script so that the bug can be fixed.
						(Note: Press Ctrl+C to copy this message to the clipboard).
						)
					Gui, +OwnDialogs
					Msgbox, 8208, Invalid Hotkey, %ErrorMessage%
					Return -1
				}
		}
	Else		
		Return 1
}