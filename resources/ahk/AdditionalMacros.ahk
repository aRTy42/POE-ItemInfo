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

AM_Init:

	class AM_Options extends UserOptions {
		
	}	
	global AM_Opts := new AM_Options()
	
	AM_Config := {}
	AM_ConfigDefault := class_EasyIni(A_ScriptDir "\resources\default_UserFiles\AdditionalMacros.ini")
	AM_ReadConfig(AM_Config)
	Sleep, 150
Return

AM_AssignHotkeys:
	If (not AM_Config) {
		GoSub, AM_Init
	}
	; TODO: Refactor
	global AM_CharacterName		:= AM_Config["KickYourself"].Character
	global AM_ChannelName		:= AM_Config["JoinChannel"].Channel
	global AM_HighlightArg1		:= AM_Config["HighlightItems"].Arg1
	global AM_HighlightArg2		:= AM_Config["HighlightItems"].Arg2
	global AM_HighlightAltArg1	:= AM_Config["HighlightItemsAlt"].Arg1
	global AM_HighlightAltArg2	:= AM_Config["HighlightItemsAlt"].Arg2
	global AM_KeyToSCState		:= (TradeOpts.KeyToSCState != "") ? TradeOpts.KeyToSCState : AM_Config["General"].General_KeyToSCState

	; AdditionalMacros hotkeys.
	AM_SetHotkeys()

	GoSub, CM_ExecuteCustomMacrosCode_Label
Return

AM_TogglePOEItemScript_HKey:
	TogglePOEItemScript()			; Pause item parsing with the pause key (other macros remain).
Return

AM_Minimize_HKey:
	WinMinimize, A					; Winkey+D minimizes the active PoE window (PoE stays minimized this way).
Return

AM_HighlightItems_HKey:
	HighlightItems(AM_HighlightArg1, AM_HighlightArg2)		; Ctrl+F fills search bars in the stash or vendor screens with the item's name or info you're hovering over.
													; Function parameters, change if needed or wanted:
													;	1. Use broader terms, default = false.
													;	2. Leave the search field after pasting the search terms, default = true.
Return

AM_HighlightItemsAlt_HKey:
	HighlightItems(AM_HighlightAltArg1, AM_HighlightAltArg2)		; Ctrl+Alt+F uses much broader search terms for the highlight function.
Return

AM_LookUpAffixes_HKey:
	LookUpAffixes()				; Opens poeaffix.net in your browser, navigating to the item that you're hovering over.
Return

AM_CloseScripts_HKey:
	CloseScripts()					; Ctrl+Esc closes all running scripts specified by (and including) ItemInfo or TradeMacro.
Return

AM_KickYourself_HKey:
	; Ingame names use underscores and never spaces, but you can easily forget that when typing your name in the ini file.
	; Consequently replacing all spaces here.
	CharName := StrReplace(AM_CharacterName, " ", "_")
	SendInput {Enter}/kick %CharName%{Enter}		; Quickly leave a group by kicking yourself. Only works for one specific character name.
Return

AM_Hideout_HKey:
	SendInput {Enter}/hideout{Enter}{Enter}{Up}{Up}{Esc}	; Go to hideout with F5. Restores the last chat that you were in.
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

AM_OpenOnPoEAntiquary_HKey:
	OpenItemOnPoEAntiquary()					; Opens an item on http://poe-antiquary.xyz to lookup a price history from last leagues.
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

AM_SetHotkeys() {
	Global AM_Config	
	
	If (AM_Config.General.EnableState) {
		For labelIndex, labelName in StrSplit(AM_Config.GetSections("|", "C"), "|") {
			If (labelName != "General") {
				For labelKeyIndex, labelKeyName in StrSplit(AM_Config[labelName].Hotkeys, ", ") {
					If (labelKeyName and labelKeyName != A_Space) {
						AM_Config[labelName].State := AM_ConvertState(AM_Config[labelName].State)						
						stateValue := AM_Config[labelName].State ? "on" : "off"
						
						; TODO: Fix hotkeys not being set without restart
						If (stateValue = "on" and not AM_Config.General.finishedInit) {
							; set hotkeys on init, only set enabled hotkeys to prevent key conflicts with other macros/applications
							Hotkey, % KeyNameToKeyCode(labelKeyName, AM_KeyToSCState), AM_%labelName%_HKey, % stateValue
						} Else If (AM_Config.General.finishedInit) {
							; change hotkey states/keys without a restart (currently not working without the restart)
							Hotkey, % KeyNameToKeyCode(labelKeyName, AM_KeyToSCState), AM_%labelName%_HKey, % stateValue							
							;console.log(labelKeyName ", " KeyNameToKeyCode(labelKeyName, AM_KeyToSCState) ", " "AM_" labelName "_HKey, " stateValue ", " ErrorLevel)
						}		
					}
				}
			}
		}
		
		If (not AM_Config.General.finishedInit) {
			AM_Config.General.finishedInit := true	
		}		
	}
}

AM_ReadConfig(ByRef ConfigObj, ConfigDir = "", ConfigFile = "AdditionalMacros.ini")
{
	defaultFile := A_ScriptDir . "\resources\default_UserFiles\" . ConfigFile
	ConfigDir  := StrLen(ConfigDir) < 1 ? userDirectory : ConfigDir	; userDirectory is global
	ConfigPath := StrLen(ConfigDir) > 0 ? ConfigDir . "\" . ConfigFile : defaultFile
	
	ConfigObj  := class_EasyIni(ConfigPath)
	ConfigObj.Update(defaultFile)
}

AM_WriteConfig(ConfigDir = "", ConfigFile = "AdditionalMacros.ini")
{
	Global AM_Config, AM_ConfigDefault
	
	ConfigDir  := StrLen(ConfigDir) < 1 ? userDirectory : ConfigDir	; userDirectory is global
	ConfigPath := ConfigDir . "\" . ConfigFile
	
	AM_UpdateConfigFromGui(AM_Config, "AM_")
	AM_Config.Save(ConfigPath)
	AM_SetHotkeys()
}

AM_UpdateConfigKeyFromGuiControl(key, controlID) {
	_get := GuiGet(controlID, "", Error)
	return (not Error ? _get : key)
}

AM_UpdateConfigFromGui(ByRef Config, prefix) {
	For section, keys in Config {
		For key, val in keys {			
			controlID := prefix . section "_" key
			If (key = "Hotkeys") {
				_value := ""
				Loop {
					_get := AM_GetHotkeyListViewValue(controlID "_" A_Index, Error)
					If (not Error) {
						_value .= _get ", "
					} Else {
						Break
					}					
				}
				Config.SetKeyVal(section, key, RegExReplace(Trim(_value), "(.*)(,$)", "$1"))
			}
			; descriptions come from the default config file, we don't need to save them in the user config
			Else If (not RegExMatch(key, "i).*_Description$|^Description$")) {				
				Config.SetKeyVal(section, key, AM_UpdateConfigKeyFromGuiControl(Config[section][key], controlID))
			}			
		}	
	}
}

AM_ConvertState(state, reverse = false) {
	If (reverse) {
		state := state = 1 ? "on" : state
		state := state = 0 ? "off" : state	
	} Else {
		state := state = "on" ? 1 : state
		state := state = "off" ? 0 : state	
	}	
	Return state
}

AM_UpdateSettingsUI() {
	Global AM_Config
	
	_AM_sections := StrSplit(AM_Config.GetSections("|", "C"), "|")
	For sectionIndex, sectionName in _AM_sections {	; this enables section sorting		
		If (sectionName != "General") {
			For keyIndex, keyValue in StrSplit(AM_Config[sectionName].Hotkeys, ", ") {	
				HotKeyID := "AM_" sectionName "_HotKeys_" keyIndex
				AM_UpdateHotkeyListView(HotKeyID, keyValue)
			}
		}
		For keyIndex, keyValue in AM_Config[sectionName] {
			If (not RegExMatch(keyIndex, "i)^Hotkeys$|^Description$|.*_Description$")) {
				ControlID := "AM_" sectionName "_" keyIndex
				GuiControl,, %ControlID%, % AM_Config[sectionName][keyIndex]
			}
		}
	}
}

AM_UpdateHotkeyListView(controlID, value) {
	Gui, ListView, %controlID%
	LV_Delete(1)
	LV_Add("","",value)
}

AM_GetHotkeyListViewValue(controlID, ByRef Error = false) {
	GuiControlGet, _g, , %controlID%
	Error := ErrorLevel ? true : false
	Gui, ListView, %controlID%
	LV_GetText(value, 1, 2)
	Return value
}