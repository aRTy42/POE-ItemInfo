;###########----------------------- Additional Macros -------------------------###########
;# Use AdditionaMacros.ini in the user folder to enable/disable hotkeys and set a key    #
;# combination.                                                                          #
;#                                                                                       #
;# You shouldn't add your own macros here, but you can add them in the user folders      #
;# subfolder "CustomMacros\". All files there will be appended.                          #
;# Please make sure that any issues that you are experiencing aren't related to your own #
;# macros before reporting them.                                                         #
;# For example, paste the line "^Space::SendInput {Enter}/oos{Enter}" in an ".ahk" file, #
;# place it in the CustomMacros folder and you have your macro ready. It's that easy.    #
;#                                                                                       #
;# Hotkeys you can use: https://autohotkey.com/docs/KeyList.htm.                         #
;# Autohotkey Quick Reference: https://autohotkey.com/docs/AutoHotkey.htm.               #
;# Using a hotkey in your custom macro that is assigned in this scrip but set to "off"   #
;# won't work since that hotkey exists but is disabled. Use the hotkey command to        #
;# overwrite and enable it: https://autohotkey.com/docs/commands/Hotkey.htm.             #
;#                                                                                       #
;# Declaring variables or executing code outside of functions, labels or hotkeys won't   #
;# work in AdditionalMacros or your custom macros. Read more about it here:              #
;# https://autohotkey.com/docs/Scripts.htm#auto (script auto-execute section).           #
;# Function calls via hotkeys work though.                                               #
;#                                                                                       #
;# AutoHotkey IDE's and Editor setups (NotePad++, Sublime, Vim):                         #
;# https://github.com/ahkscript/awesome-AutoHotkey#integrated-development-environment    #
;#                                                                                       #
;# Curated list of awesome AHK libs, lib distributions, scripts, tools and resources:    #
;# https://github.com/ahkscript/awesome-AutoHotkey                                       #
;#                                                                                       #
;#                                                                                       #
;# AdditionalMacros Wiki entry:                                                          #
;#     https://github.com/PoE-TradeMacro/POE-TradeMacro/wiki/AdditionalMacros            #
;###########-------------------------------------------------------------------###########

AM_AssignHotkeys:
	global AM_Config := class_EasyIni(argumentUserDirectory "\AdditionalMacros.ini")
	global AM_CharacterName		:= AM_Config["AM_KickYourself"].CharacterName
	global AM_ChannelName		:= AM_Config["AM_JoinChannel"].ChannelName
	global AM_HighlightArg1		:= AM_Config["AM_HighlightItems"].Arg1
	global AM_HighlightArg2		:= AM_Config["AM_HighlightItems"].Arg2	
	global AM_HighlightAltArg1	:= AM_Config["AM_HighlightItemsAlt"].Arg1
	global AM_HighlightAltArg2	:= AM_Config["AM_HighlightItemsAlt"].Arg2
	global AM_KeyToSCState		:= (TradeOpts.KeyToSCState != "") ? TradeOpts.KeyToSCState : AM_Config["General"].KeyToSCState

	; This option can be set in the settings menu (ItemInfo tab) to completely disable assigning
	; AdditionalMacros hotkeys.
	If (Opts.EnableAdditionalMacros) {
		for labelIndex, labelName in StrSplit(AM_Config.GetSections("|", "C"), "|") {
			if (labelName != "General") {
				for labelKeyIndex, labelKeyName in StrSplit(AM_Config[labelName].Hotkeys, ", ") {
					Hotkey, % KeyNameToKeyCode(labelKeyName, AM_KeyToSCState), %labelName%_HKey, % AM_Config[labelName].State
				}
			}
		}
	}

	GoSub, CM_ExecuteCustomMacrosCode_Label
Return

AM_TogglePOEItemScript_HKey:
	TogglePOEItemScript()			; Pause item parsing with the pause key (other macros remain).
Return

AM_Minimize_HKey:
	WinMinimize, A					; Winkey+D minimizes the active PoE window (PoE stays minimized this way).
Return

AM_HighlightItems_HKey:
	HighlightItems(%AM_HighlightArg1%,%AM_HighlightArg2%)		; Ctrl+F fills search bars in the stash or vendor screens with the item's name or info you're hovering over.
													; Function parameters, change if needed or wanted:
													;	1. Use broader terms, default = false.
													;	2. Leave the search field after pasting the search terms, default = true.
Return

AM_HighlightItemsAlt_HKey:
	HighlightItems(%AM_HighlightAltArg1%,%AM_HighlightAltArg2%)		; Ctrl+Alt+F uses much broader search terms for the highlight function.
Return

AM_LookUpAffixes_HKey:
	LookUpAffixes()				; Opens poeaffix.net in your browser, navigating to the item that you're hovering over.
Return

AM_CloseScripts_HKey:
	CloseScripts()					; Ctrl+Esc closes all running scripts specified by (and including) ItemInfo or TradeMacro.
Return

AM_KickYourself_HKey:
	SendInput {Enter}/kick %AM_CharacterName%{Enter}		; Quickly leave a group by kicking yourself. Only works for one specific character name.
Return

AM_Hideout_HKey:
	SendInput {Enter}/hideout{Enter}					; Go to hideout with F5.
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
	Send {Left}			; Holding right mouse button+scroll up scrolls through stash tabs leftward.
Return

AM_SendCtrlC_HKey:
	SendInput ^c			; Ctrl+right mouse button sends ctrl+c.
Return

AM_Remaining_HKey:
	SendInput {Enter}/remaining{Enter}			; Mobs remaining with F9.
Return

AM_JoinChannel_HKey:
	SendInput {Enter}/%AM_ChannelName%{Enter}		; Join a channel with F10. Default = global 820.
Return

AM_SetAfkMessage_HKey:
	setAfkMessage()						; Pastes afk message to your chat and marks "X" so you can type in the estimated time.
Return

AM_AdvancedItemInfo_HKey:
	AdvancedItemInfoExt()					; Opens an item on pathof.info for an advanced affix breakdown.
Return

AM_WhoisLastWhisper_HKey:
	KeyWait, Ctrl							; Sends "/whois lastWhisperCharacterName" when keys are released (not when pressed).
	KeyWait, Alt
	SendInput {Enter}{Home}{Del}/whois{Space}{Enter}
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
