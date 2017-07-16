#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent ; Stay open in background

GroupAdd, PoEexe, ahk_exe PathOfExile.exe
GroupAdd, PoEexe, ahk_exe PathOfExileSteam.exe
GroupAdd, PoEexe, ahk_exe PathOfExile_x64.exe
GroupAdd, PoEexe, ahk_exe PathOfExile_x64Steam.exe

#IfWinActive Path of Exile ahk_class POEWindowClass ahk_group PoEexe

EnableAdditionalMacros := true

; Assign and enable/disable the hotkeys here
AM_TogglePOEItemScript	:= ["on", "Pause"]
AM_Minimize				:= ["on", "#D"]
AM_HighlightItems		:= ["on", "^F"]
AM_HighlightItemsAlt	:= ["on", "^!F"]
AM_CloseScripts			:= ["off", "^Escape"]
AM_KickYourself			:= ["on", "F4", "Input your character name here"]
AM_Hideout				:= ["on", "F5"]
AM_ScrollTabRight		:= ["on", "^WheelDown", "~RButton & WheelDown"]
AM_ScrollTabLeft		:= ["on", "^WheelUp", "~RButton & WheelUp"]
AM_SendCtrlC			:= ["on", "^RButton"]
AM_Remaining			:= ["on", "F9"]
AM_JoinGlobal820		:= ["on", "F10"]
AM_SetAfkMessage		:= ["on", "F11"]

If (EnableAdditionalMacros) {
	Hotkey, % AM_TogglePOEItemScript[2]	, AM_TogglePOEItemScript_HKey	, % AM_TogglePOEItemScript[1]
	Hotkey, % AM_Minimize[2]			, AM_Minimize_HKey				, % AM_Minimize[1]
	Hotkey, % AM_HighlightItems[2]		, AM_HighlightItems_HKey		, % AM_HighlightItems[1]
	Hotkey, % AM_HighlightItemsAlt[2]	, AM_HighlightItemsAlt_HKey		, % AM_HighlightItemsAlt[1]
	Hotkey, % AM_CloseScripts[2]		, AM_CloseScripts_HKey			, % AM_CloseScripts[1]
	Hotkey, % AM_KickYourself[2]		, AM_KickYourself_HKey			, % AM_KickYourself[1]
	Hotkey, % AM_Hideout[2]				, AM_Hideout_HKey				, % AM_Hideout[1]
	Hotkey, % AM_ScrollTabRight[2]		, AM_ScrollTabRight_HKey		, % AM_ScrollTabRight[1]
	Hotkey, % AM_ScrollTabLeft[2]		, AM_ScrollTabLeft_HKey			, % AM_ScrollTabLeft[1]
	Hotkey, % AM_ScrollTabRight[3]		, AM_ScrollTabRightAlt_HKey		, % AM_ScrollTabRight[1]
	Hotkey, % AM_ScrollTabLeft[3]		, AM_ScrollTabLeftAlt_HKey		, % AM_ScrollTabLeft[1]
	Hotkey, % AM_SendCtrlC[2]			, AM_SendCtrlC_HKey				, % AM_SendCtrlC[1]
	Hotkey, % AM_Remaining[2]			, AM_Remaining_HKey				, % AM_Remaining[1]
	Hotkey, % AM_JoinGlobal820[2]		, AM_JoinGlobal820_HKey			, % AM_JoinGlobal820[1]
	Hotkey, % AM_SetAfkMessage[2]		, AM_SetAfkMessage_HKey			, % AM_SetAfkMessage[1]
}

AM_TogglePOEItemScript_HKey:
	;TogglePOEItemScript()			; Pause item parsing with the pause key (other macros remain).
Return

AM_Minimize_HKey:
	WinMinimize, A					; Winkey+D minimizes the active PoE window (PoE stays minimized this way).
Return 

AM_HighlightItems_HKey:
	;HighlightItems(false,true)		; Ctrl+F fills search bars in the stash or vendor screens with the item's name or info you're hovering over.
										; Function parameters, change if needed or wanted:
										;	1. Use broader terms, default = false.
										;	2. Leave the search field after pasting the search terms, default = true.
Return

AM_HighlightItemsAlt_HKey:
	;HighlightItems(true,true)		; Ctrl+Alt+F uses much broader search terms for the highlight function.
Return

AM_CloseScripts_HKey:
	;CloseScripts()					; Ctrl+Esc closes all running scripts specified by (and including) ItemInfo or TradeMacro.
Return

AM_KickYourself_HKey:
	charName := AM_KickYourself[3]
	SendInput {Enter}/kick %charName%{Enter}		; Quickly leave a group by kicking yourself. Only works for one specific character name.
Return

AM_Hideout_HKey:
	SendInput {Enter}/hideout{Enter}				; Go to hideout with F5.
Return

AM_ScrollTabRight_HKey:
	SendInput {Right}		; Ctrl+scroll down scrolls through stash tabs rightward.
Return
AM_ScrollTabLeft_HKey:
	SendInput {Left}		; Ctrl+scroll up scrolls through stash tabs leftward.
Return
	
AM_ScrollTabRightAlt_HKey:	
	Send {Right}			; Holding right mouse button+scroll down scrolls through stash tabs rightward
Return
AM_ScrollTabLeftAlt_HKey:
	Send {Left}				; Holding right mouse button+scroll up scrolls through stash tabs leftward.
Return

AM_SendCtrlC_HKey:
	SendInput ^c			; Ctrl+right mouse button sends ctrl+c.
Return

AM_Remaining_HKey:
	SendInput {Enter}/remaining{Enter}		; Mobs remaining with F9.
Return

AM_JoinGlobal820_HKey:
	SendInput {Enter}/global 820{Enter}		; Join a channel with F10.
Return

AM_SetAfkMessage_HKey:
	setAfkMessage()							; Pastes afk message to your chat and marks "X" so you can type in the estimated time.
Return

setAfkMessage(){		
	T1 := A_Now
	T2 := A_NowUTC
	EnvSub, T1, %T2%, M
	TZD := "UTC +" Round( T1/60, 2 )
	FormatTime, currentTime, A_NowUTC, HH:mm
	clipboard := "/afk AFK for about X minutes, since " currentTime " (" TZD "). Leave a message and I'll reply."
	
	IfWinActive, Path of Exile ahk_class POEWindowClass 
	{
		SendInput {Enter} ^{v} {Home}
		Pos := RegExMatch(clipboard, " X ")
		If (Pos) {
			Loop {
				SendInput {Right}
				If (A_Index > Pos) {
					Break
				}
			}
			Send {Shift Down} 
			Sleep 100
			Send {Right} 
			Sleep 100
			Send {Shift Up} 
		}
	}		
}