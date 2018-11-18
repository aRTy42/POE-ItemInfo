#SingleInstance, force
#NoTrayIcon

itemName		= %1%
itemBase		= %2%
bgColor		= %3%
borderColor	= %4%
fontColor 	= %5%
fontSize		= %6%
mouseX		= %7%
mouseY		= %8%
advanced		= %9%

/*
	Define window criteria for the regular and steam version, for later use at the very end of the script. This needs to be done early, in the "auto-execute section".
	*/
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExileSteam.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64Steam.exe

global itemText := itemName "`n" itemBase
global appAHKGroup := "PoEWindowGroup"
global applicationHwnd := 
global xPos := 0
global yPos := 0
global winWidth := 0
global winHeight := 0
global mousePosX := mouseX
global mousePosY := mouseY
global advancedPreview := advanced
GuiMargin := 2
global borderWidth := 1

If (not StrLen(itemText)) {
	ExitApp
}

/*
	Create a custom font in the case that "Fontin SmallCaps" is not installed on the users system.
	Calculate text dimensions based on font styles (size, font face) and text contents.
	Parse font color (transparency defaults to about 235 when no value is given).
	*/
fC	:= StrSplit(fontColor, " ")
fClr	:= rgbToRGBHex(fC[1], fC[2], fC[3])
fC[4] := fC[4] ? fC[4] : 235				
fS	:= Round(fontSize / 2.5)

; Load font from file, without installation
global CFont := New CustomFont(A_ScriptDir "\..\resources\fonts\Fontin-SmallCaps.ttf")
font := "Fontin SmallCaps"

width := 0
height := 0
size := {}
Loop, Parse, itemText, `n, `r
{
	string := A_LoopField			
	StringReplace, string, string, `r,, All
	StringReplace, string, string, `n,, All
	
	emptyLine := false
	If (not StrLen(string)) {
		string := "A"				; don't prevent emtpy lines, just having a linebreak will break the text measuring 
		emptyLine := true				
	}
	string := " " Trim(string) " "	; add spaces as padding
	
	If (emptyLine) {
		newValue .= "`n"
	} Else {
		newValue .= string "`n"
	}		
	
	If (StrLen(string)) {
		size := Font_DrawText(string, "", "s" fS ", " font, "CALCRECT SINGLELINE NOCLIP")								
		width := width > size.W ? width : size.W
		If (width > 400) {
			width := width * 1.03
		} Else If (width > 200) {
			width := width * 1.05
		} Else {
			width := width * 1.1
		}		
		height += size.H
	}
}
width += 5
sHeight := size.H

/*
	Parse border and background colors (transparency defaults to about 235 when no value is given).
	*/
bgC	:= StrSplit(bgColor, " ")
bgClr:= rgbToRGBHex(bgC[1], bgC[2], bgC[3])
bgC[4] := bgC[4] ? bgC[4] : 235

bC	:= StrSplit(borderColor, " ")
bClr	:= rgbToRGBHex(bC[1], bC[2], bC[3])
bC[4] := bC[4] ? bC[4] : 235

/*
	Create three seperate windows for 
	1. background 
	2. border 
	3. text
	
	Because of the different transparencies this is neccessary.
	*/
winHwnds := []
Loop, 3 {
	GuiName := "ItemNamePlate"

	Gui, %A_Index%:New, +AlwaysOnTop +ToolWindow
	Gui, +Lastfound
	TTHWnd := WinExist()
	winHwnds.push(TTHWnd)
	Gui, %A_Index%:Margin, %GuiMargin%, %GuiMargin%

	; background
	Gui, %A_Index%:Color, %bgClr%
	; font
	Gui, %A_Index%:Font, s%fS%, % font

	/*
		leave emtpy in some loops, just placeholders for autosizing
		*/
	If (A_Index = 3) {
		text1 := itemName
		text2 := itemBase
	} Else {
		text1 := ""
		text2 := ""
	}
	
	If (StrLen(itemName)) {
		Gui, %A_Index%:Add, Text, w%width% h%sHeight% c%fClr% center vT1, % text1
		GuiControl +BackgroundTrans, T1
	}
	If (StrLen(itemBase)) {
		Gui, %A_Index%:Add, Text, w%width% h%sHeight% c%fClr% center y+1 vT2, % text2
		GuiControl +BackgroundTrans, T2
	}

	DetectHiddenWindows, On
	; make window invisible
	WinSet, Transparent, 0, ahk_id %TTHWnd%

	; maximize the window before removing the borders/title bar etc
	; otherwise there will be some remnants visible that aren't really part of the gui
	; "maximize" option or "WinMaximize" don't work because they activate/focus the window.
	Gui, %A_Index%:Show, AutoSize NoActivate, CustomTooltip%A_Index%

	; maximize window using PostMessage / WinMove
	WinMove, ahk_id %TTHWnd%, , 0, 0 , A_ScreenWidth, A_ScreenHeight

	; make tooltip clickthrough and remove borders
	WinSet, ExStyle, +0x20, ahk_id %TTHWnd% ; 0x20 = WS_EX_CLICKTHROUGH
	WinSet, Style, -0xC00000, ahk_id %TTHWnd%

	; restore window to actual size
	Gui, %A_Index%:Show, x%xPos% y%yPos% AutoSize Restore NoActivate, CustomTooltip%A_Index%
	
	;WinGetPos, TTX, TTY, TTW, TTH, ahk_id %TTHwnd%
	If (A_Index != 2) {
		WinGetPos, TTX, TTY, TTW, TTH, ahk_id %TTHwnd%
		xPos := mousePosX
		yPos := mousePosY
		winWidth := TTW
		winHeight := TTH
	}
}

; border window size and position
bwWidth := winWidth + (borderWidth * 2)
bwHeight := winHeight + (borderWidth * 2)
CheckAndCorrectWindowPosition(winHwnds[2], borderWidth, xPos, yPos, bwWidth, bwHeight)

/*
	Move/resize all windows to their final position/dimensions (layer them on top of each other).
	*/
Loop, 3 {
	TTHwnd := winHwnds[A_Index]
	Gui, +Lastfound
	If (A_Index = 1) {
		WinMove, ahk_id %TTHwnd%, , xPos + borderWidth, yPos + borderWidth, 
	} Else If (A_Index = 2) {		
		; add a border to the window, has to be done after auto-resizing the window
		GuiAddBorder(bClr, borderWidth, bwWidth, bwHeight, A_Index, TTHWnd)
		WinMove, ahk_id %TTHwnd%, , xPos, yPos, bwWidth, bwHeight  
	} Else If (A_Index = 3) {
		WinMove, ahk_id %TTHwnd%, , xPos + borderWidth, yPos + borderWidth, 
	}
}
/*
	Make all windows visible again after moving/resizing them, otherwise they can appear at different times,  causing "flickering".
	*/
Loop, 3 {
	TTHwnd := winHwnds[A_Index]
	; make windows visible again
	Gui, +Lastfound
	If (A_Index = 1) {
		bgTrans := bgC[4]
		WinSet, Transparent, %bgTrans%, ahk_id %TTHWnd%
	} Else If (A_Index = 2) {
		bTrans := bc[4]
		WinSet, Transparent, %bTrans%, ahk_id %TTHWnd%
		WinSet, TransColor, %bgClr% 255, ahk_id %TTHWnd%
	} Else If (A_Index = 3) {
		fTrans := fC[4]
		WinSet, Transparent, %fTrans%, ahk_id %TTHWnd%
		WinSet, TransColor, %bgClr% 255, ahk_id %TTHWnd%
	}
}

/*
	Make sure that the overlay gets closed after some time, although the calling script is able to kill it, too. 
	*/
If (advancedPreview) {
	; automatically close the windows after 20 seconds
	SetTimer, CloseWindows, 20000	
} Else {
	; automatically close the windows after 4 seconds
	SetTimer, CloseWindows, 4000
}

Return 

CloseWindows:
	ExitApp
Return

rgbToRGBHex(r, g = 0, b = 0) {	
	; won't work without IntegerFast when called from a Label
	SetFormat, IntegerFast, % (f := A_FormatInteger) = "D" ? "H" : f
	h := r + 0 . g + 0 . b + 0
	SetFormat, Integer, %f%
	
	;res := "0x" . RegExReplace(RegExReplace(h, "0x(.)(?=$|0x)", "0$1"), "0x")
	res := RegExReplace(RegExReplace(h, "0x(.)(?=$|0x)", "0$1"), "0x")
	Return, res
}

Set_Parent_by_id(Window_ID, Gui_Number) ; title text is the start of the title of the window, gui number is e.g. 99 
{ 
  Gui, %Gui_Number%: +LastFound 
  Return DllCall("SetParent", "uint", WinExist(), "uint", Window_ID) ; success = handle to previous parent, failure =null 
}

; ==================================================================================================================================
; Function	GuiAddBorder
;			Draws a region onto the Gui to create a border around it.
; Parameters:
; 		Color        -  border color as used with the 'Gui, Color, ...' command, must be a "string"
; 		Width        -  the width of the border in pixels
; 		pW, pH	   -  the width and height of the parent window.
; 		GuiName	   -  the name of the parent window.
; 		parentHwnd   -  the ahk_id of the parent window.
;                 			You should not pass other control options!
;
; Return: 
;			Nothing. Changes an existing Gui window.
; ==================================================================================================================================
GuiAddBorder(Color, Width, pW, pH, GuiName = "", parentHwnd = "") {		
	LFW := WinExist() 				; save the last-found window, if any
	If (not GuiName and parentHwnd) {		
		DefGui := A_DefaultGui 		; save the current default GUI		
	}

	Try {
		Gui, %GuiName%Border:New, +Parent%parentHwnd% +LastFound -Caption +hwndBorderW
		Gui, %GuiName%Border:Color, %Color%
		X1 := Width, X2 := pW - Width, Y1 := Width, Y2 := pH - Width
		WinSet, Region, 0-0 %pW%-0 %pW%-%pH% 0-%pH% 0-0   %X1%-%Y1% %X2%-%Y1% %X2%-%Y2% %X1%-%Y2% %X1%-%Y1%, ahk_id %BorderW%
		Gui, %GuiName%Border:Show, x0 y0 w%pW% h%pH%
		createdBorder := true
	} Catch e {
		Msgbox Creating ToolTip border failed because target window doesn't exist.
	}
	
	If (not GuiName and parentHwnd) {	
		Gui, %DefGui%:Default 		; restore the default Gui
	}
	
	If (LFW)						; restore the last-found window, if any
		WinExist(LFW)
}

; ==================================================================================================================================
; Function	CheckAndCorrectWindowPosition
;			Checks on which monitor the ToolTIp should be drawn.
;			Checks whether the ToolTip can be drawn at current mouseposition while making sure that the ToolTip is visible entirely.
;			Corrects positioning as needed.
; Parameters:
; 		GuiName	- Name of the ToolTip gui.
;		TTHwnd	- Handle of the ToolTip Gui.
;		TTX		- ToolTip x coordinate.
;		TTY		- ToolTip y coordinate.
;		TTW		- ToolTip width.
;		TTH		- ToolTip height.
; 		centered	- Centers the ToolTip on the screen, vertically and horizontally.
;
; Return: 
;			1 if the ToolTip fits on the screen, 0 if not.
; ==================================================================================================================================
; 	CheckAndCorrectWindowPosition(GuiIDs, parentWindow, xPos, yPos, bwWidth, bwHeight)
CheckAndCorrectWindowPosition(GuiID, borderWidth, TTX, TTY, TTW, TTH) {
	Global xPos, yPos, mousePosX, mousePosY
	
	WinGet, applicationHwnd, ID, ahk_group PoEWindowGroup
	
	; get monitor info
	monitors := MDMF_Enum()
	; get the display monitor that has the largest area of intersection with the specified window
	; returned 0 = no intersection/no specified window
	appOnMonitorHwnd := MDMF_FromHWND(applicationHwnd)
	
	boundingRectangle := {}
	For, key, monitor in monitors {
		useMonitor := false
		isOnMonitorX := (xPos >= monitor.Left) and (xPos <= monitor.Right)
		isOnMonitorY := (yPos >= monitor.top) and (yPos <= monitor.bottom)
		isOnMonitor  := isOnMonitorX and isOnMonitorY
		useAppTarget := ((appAHKGroup or applicationHwnd) and appOnMonitorHwnd)
		
		If (not useFixedCoords) {
			; if we don't use fixed coords, use the monitor where the application is on to draw the tooltip, no matter where the mouse is,
			; unless there is no application specified
			If ((appOnMonitorHwnd = monitor.handle) or (not useAppTarget and isOnMonitor)) {
				useMonitor := true					
			}
		}
		Else {				
			If (isOnMonitor) {
				useMonitor := true
			}
		}
		
		If (useMonitor) {
			boundingRectangle.top := monitor.top
			boundingRectangle.left := monitor.left
			boundingRectangle.bottom := monitor.bottom
			boundingRectangle.right := monitor.right
			boundingRectangle.h := monitor.name
		}		
	}	
	
	; cursor size
	SysGet, CursorW, 13
	SysGet, CursorH, 14
	
	; position the tooltip beside the cursor
	originalCursorY := mousePosY
	TTY := mousePosY
	TTY := TTY - Round(TTH / 3)
	TTX := TTX + CursorW + 3
	
	nTTX := TTX
	nTTY := TTY
	
	; negative left = left non-primary monitor
	If (boundingRectangle.left < 0) {
		xOffset := boundingRectangle.right + (TTX + TTW)
		If (xOffset > boundingRectangle.right) {
			nTTX := TTX - xOffset
		}
		If (TTX < boundingRectangle.left) {
			nTTX := boundingRectangle.left
		}
	}
	Else {
		xOffset := boundingRectangle.right - (TTX + TTW)
		If (xOffset < boundingRectangle.left) {
			nTTX := TTX + xOffset
		}
		If (TTX < boundingRectangle.left) {
			nTTX := boundingRectangle.left
		}
	}
	
	yOffset := boundingRectangle.bottom - (TTY + TTH)
	yOffsetTop := originalCursorY - TTH - 3
	If (yOffset < boundingRectangle.top) {			
		If (yOffsetTop >= boundingRectangle.top) {
			; move tooltip over cursor
			nTTY := yOffsetTop
		}
		Else {
			nTTY := TTY + yOffset
		}
	}
	If (TTY < boundingRectangle.top) {
		nTTY := boundingRectangle.top
	}

	TTHwnd := GuiID
	If (nTTX != TTX or nTTY != TTY) {
		yPos := nTTY		
		
		If (nTTX + TTW > mousePosX){
			xPos := nTTX - ((nTTX + TTW + 5) - mousePosX)
		} 
		Else {
			xPos := nTTX	
		}		
	} Else {
		xPos := TTX
		yPos := TTY
	}
		
	Return 1
}

; ======================================================================================================================
; Multiple Display Monitors Functions -> msdn.microsoft.com/en-us/library/dd145072(v=vs.85).aspx =======================
; ======================================================================================================================
; Enumerates display monitors and returns an object containing the properties of all monitors or the specified monitor.
; ======================================================================================================================
MDMF_Enum(HMON := "") {
   Static EnumProc := RegisterCallback("MDMF_EnumProc")	   
   Static Monitors := {}
   If (HMON = "") ; new enumeration
	  Monitors := {}
   If (Monitors.MaxIndex() = "") ; enumerate
	  If !DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", EnumProc, "Ptr", &Monitors, "UInt")
		 Return False
   Return (HMON = "") ? Monitors : Monitors.HasKey(HMON) ? Monitors[HMON] : False
}
; ======================================================================================================================
;  Callback function that is called by the MDMF_Enum function.
; ======================================================================================================================
MDMF_EnumProc(HMON, HDC, PRECT, ObjectAddr) {
   Monitors := Object(ObjectAddr)
   Monitors[HMON] := MDMF_GetInfo(HMON)
   Return True
}
; ======================================================================================================================
;  Retrieves the display monitor that has the largest area of intersection with a specified window.
; ======================================================================================================================
MDMF_FromHWND(HWND) {
   Return DllCall("User32.dll\MonitorFromWindow", "Ptr", HWND, "UInt", 0, "UPtr")
}
; ======================================================================================================================
; Retrieves the display monitor that contains a specified point.
; If either X or Y is empty, the function will use the current cursor position for this value.
; ======================================================================================================================
MDMF_FromPoint(X := "", Y := "") {
   VarSetCapacity(PT, 8, 0)
   If (X = "") || (Y = "") {
	  DllCall("User32.dll\GetCursorPos", "Ptr", &PT)
	  If (X = "")
		 X := NumGet(PT, 0, "Int")
	  If (Y = "")
		 Y := NumGet(PT, 4, "Int")
   }
   Return DllCall("User32.dll\MonitorFromPoint", "Int64", (X & 0xFFFFFFFF) | (Y << 32), "UInt", 0, "UPtr")
}
; ======================================================================================================================
; Retrieves the display monitor that has the largest area of intersection with a specified rectangle.
; Parameters are consistent with the common AHK definition of a rectangle, which is X, Y, W, H instead of
; Left, Top, Right, Bottom.
; ======================================================================================================================
MDMF_FromRect(X, Y, W, H) {
   VarSetCapacity(RC, 16, 0)
   NumPut(X, RC, 0, "Int"), NumPut(Y, RC, 4, Int), NumPut(X + W, RC, 8, "Int"), NumPut(Y + H, RC, 12, "Int")
   Return DllCall("User32.dll\MonitorFromRect", "Ptr", &RC, "UInt", 0, "UPtr")
}
; ======================================================================================================================
; Retrieves information about a display monitor.
; ======================================================================================================================
MDMF_GetInfo(HMON) {
   NumPut(VarSetCapacity(MIEX, 40 + (32 << !!A_IsUnicode)), MIEX, 0, "UInt")
   If DllCall("User32.dll\GetMonitorInfo", "Ptr", HMON, "Ptr", &MIEX) {
	  MonName := StrGet(&MIEX + 40, 32)    ; CCHDEVICENAME = 32
	  MonNum := RegExReplace(MonName, ".*(\d+)$", "$1")
	  obj := {Name:      (Name := StrGet(&MIEX + 40, 32))
			, Handle:	 HMON
			, Num:       RegExReplace(Name, ".*(\d+)$", "$1")
			, Left:      NumGet(MIEX, 4, "Int")    ; display rectangle
			, Top:       NumGet(MIEX, 8, "Int")    ; "
			, Right:     NumGet(MIEX, 12, "Int")   ; "
			, Bottom:    NumGet(MIEX, 16, "Int")   ; "
			;, WALeft:    NumGet(MIEX, 20, "Int")   ; work area
			;, WATop:     NumGet(MIEX, 24, "Int")   ; "
			;, WARight:   NumGet(MIEX, 28, "Int")   ; "
			;, WABottom:  NumGet(MIEX, 32, "Int")   ; "
			, Primary:   NumGet(MIEX, 36, "UInt")} ; contains a non-zero value for the primary monitor.
		
		obj.W := Abs(obj.Right - obj.Left)   ; "
		obj.H := Abs(obj.Top - obj.Bottom)   ; "	
		return obj
   }
   Return False
}

; ==================================================================================================================================
; Original script by majkinetor.
; Fixed by Eruyome.
;	
; https://github.com/majkinetor/mm-autohotkey/blob/master/Font/Font.ahk
;	
; Function:		CreateFont
;				Creates the font and optinally, sets it for the control.
; Parameters:
;				hCtrl 	- Handle of the control. If omitted, function will create font and return its handle.
;				Font  	- AHK font defintion ("s10 italic, Courier New"). If you already have created font, pass its handle here.
;				bRedraw	- If this parameter is TRUE, the control redraws itself. By default 1.
; Returns:	
;				Font handle.
; ==================================================================================================================================
CreateFont(HCtrl="", Font="", BRedraw=1) {
	static WM_SETFONT := 0x30

	;if Font is not integer
	if (not RegExMatch(Trim(Font), "^\d+$"))
	{
		StringSplit, Font, Font, `,,%A_Space%%A_Tab%
		fontStyle := Font1, fontFace := Font2

	  ;parse font 
		italic      := InStr(Font1, "italic")    ?  1    :  0 
		underline   := InStr(Font1, "underline") ?  1    :  0 
		strikeout   := InStr(Font1, "strikeout") ?  1    :  0 
		weight      := InStr(Font1, "bold")      ? 700   : 400 

	  ;height 
		RegExMatch(Font1, "(?<=[S|s])(\d{1,2})(?=[ ,]*)", height) 
		ifEqual, height,, SetEnv, height, 10
		RegRead, LogPixels, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontDPI, LogPixels 
		height := -DllCall("MulDiv", "int", Height, "int", LogPixels, "int", 72) 
	
		IfEqual, Font2,,SetEnv Font2, MS Sans Serif
	 ;create font 
		hFont   := DllCall("CreateFont", "int",  height, "int",  0, "int",  0, "int", 0
						  ,"int",  weight,   "Uint", italic,   "Uint", underline 
						  ,"uint", strikeOut, "Uint", nCharSet, "Uint", 0, "Uint", 0, "Uint", 0, "Uint", 0, "str", Font2, "Uint")
	} else hFont := Font
	ifNotEqual, HCtrl,,SendMessage, WM_SETFONT, hFont, BRedraw,,ahk_id %HCtrl%
	return hFont
}

; ==================================================================================================================================
;
; Original script by majkinetor.
; Fixed by Eruyome.
;
; https://github.com/majkinetor/mm-autohotkey/blob/master/Font/Font.ahk
;
; Function:	DrawText
;			Draws text using specified font on device context or calculates width and height of the text.
; Parameters: 
;		Text		- Text to be drawn or measured. 
;		DC		- Device context to use. If omitted, function will use Desktop's DC.
;		Font		- If string, font description in AHK syntax. If number, font handle. If omitted, uses the system font to calculate text metrics.
;		Flags	- Drawing/Calculating flags. Space separated combination of flag names. For the description of the flags see <http://msdn.microsoft.com/en-us/library/ms901121.aspx>.
;		Rect		- Bounding rectangle. Space separated list of left,top,right,bottom coordinates. 
;				  Width could also be used with CALCRECT WORDBREAK style to calculate word-wrapped height of the text given its width.
;				
; Flags:
;			CALCRECT, BOTTOM, CALCRECT, CENTER, VCENTER, TABSTOP, SINGLELINE, RIGHT, NOPREFIX, NOCLIP, INTERNAL, EXPANDTABS, AHKSIZE.
; Returns:
;			Decimal number. Width "." Height of text. If AHKSIZE flag is set, the size will be returned as w%w% h%h%
; ==================================================================================================================================	
Font_DrawText(Text, DC="", Font="", Flags="", Rect="") {
	static DT_AHKSIZE=0, DT_CALCRECT=0x400, DT_WORDBREAK=0x10, DT_BOTTOM=0x8, DT_CENTER=0x1, DT_VCENTER=0x4, DT_TABSTOP=0x80, DT_SINGLELINE=0x20, DT_RIGHT=0x2, DT_NOPREFIX=0x800, DT_NOCLIP=0x100, DT_INTERNAL=0x1000, DT_EXPANDTABS=0x40

	hFlag := (Rect = "") ? DT_NOCLIP : 0

	StringSplit, Rect, Rect, %A_Space%
	loop, parse, Flags, %A_Space%
		ifEqual, A_LoopField,,continue
		else hFlag |= DT_%A_LoopField%

	if (RegExMatch(Trim(Font), "^\d+$")) {
		hFont := Font, bUserHandle := 1
	}
	else if (Font != "") {
		hFont := CreateFont( "", Font)
	}
	else {
		hFlag |= DT_INTERNAL
	}

	IfEqual, hDC,,SetEnv, hDC, % DllCall("GetDC", "Uint", 0, "Uint")
	ifNotEqual, hFont,, SetEnv, hOldFont, % DllCall("SelectObject", "Uint", hDC, "Uint", hFont)

	VarSetCapacity(RECT, 16)
	if (Rect0 != 0)
		loop, 4
			NumPut(Rect%A_Index%, RECT, (A_Index-1)*4)

	h := DllCall("DrawTextA", "Uint", hDC, "Str", Text, "int", StrLen(Text), "uint", &RECT, "uint", hFlag)

	;clean
	ifNotEqual, hOldFont,,DllCall("SelectObject", "Uint", hDC, "Uint", hOldFont) 
	ifNotEqual, bUserHandle, 1, DllCall("DeleteObject", "Uint", hFont)
	ifNotEqual, DC,,DllCall("ReleaseDC", "Uint", 0, "Uint", hDC) 
	
	w	:= NumGet(RECT, 8, "Int")
	
	return InStr(Flags, "AHKSIZE") ? "w" w " h" h : { "W" : w, "H": h }
}

;==================================================================
/*
	CustomFont v2.00 (2016-2-24)
	---------------------------------------------------------
	Description: Load font from file or resource, without needed install to system.
	---------------------------------------------------------
	Useage Examples:

		* Load From File
			font1 := New CustomFont("ewatch.ttf")
			Gui, Font, s100, ewatch

		* Load From Resource
			Gui, Add, Text, HWNDhCtrl w400 h200, 12345
			font2 := New CustomFont("res:ewatch.ttf", "ewatch", 80) ; <- Add a res: prefix to the resource name.
			font2.ApplyTo(hCtrl)

		* The fonts will removed automatically when script exits.
		  To remove a font manually, just clear the variable (e.g. font1 := "").
*/
Class CustomFont
{
	static FR_PRIVATE  := 0x10

	__New(FontFile, FontName="", FontSize=30) {
		if RegExMatch(FontFile, "i)res:\K.*", _FontFile) {
			this.AddFromResource(_FontFile, FontName, FontSize)
		} else {
			this.AddFromFile(FontFile)
		}
	}

	AddFromFile(FontFile) {
		DllCall( "AddFontResourceEx", "Str", FontFile, "UInt", this.FR_PRIVATE, "UInt", 0 )
		this.data := FontFile
	}

	AddFromResource(ResourceName, FontName, FontSize = 30) {
		static FW_NORMAL := 400, DEFAULT_CHARSET := 0x1

		nSize    := this.ResRead(fData, ResourceName)
		fh       := DllCall( "AddFontMemResourceEx", "Ptr", &fData, "UInt", nSize, "UInt", 0, "UIntP", nFonts )
		hFont    := DllCall( "CreateFont", Int,FontSize, Int,0, Int,0, Int,0, UInt,FW_NORMAL, UInt,0
		            , Int,0, Int,0, UInt,DEFAULT_CHARSET, Int,0, Int,0, Int,0, Int,0, Str,FontName )

		this.data := {fh: fh, hFont: hFont}
	}

	ApplyTo(hCtrl) {
		SendMessage, 0x30, this.data.hFont, 1,, ahk_id %hCtrl%
	}

	__Delete() {
		if IsObject(this.data) {
			DllCall( "RemoveFontMemResourceEx", "UInt", this.data.fh    )
			DllCall( "DeleteObject"           , "UInt", this.data.hFont )
		} else {
			DllCall( "RemoveFontResourceEx"   , "Str", this.data, "UInt", this.FR_PRIVATE, "UInt", 0 )
		}
	}

	; ResRead() By SKAN, from http://www.autohotkey.com/board/topic/57631-crazy-scripting-resource-only-dll-for-dummies-36l-v07/?p=609282
	ResRead( ByRef Var, Key ) {
		VarSetCapacity( Var, 128 ), VarSetCapacity( Var, 0 )
		If ! ( A_IsCompiled ) {
			FileGetSize, nSize, %Key%
			FileRead, Var, *c %Key%
			Return nSize
		}

		If hMod := DllCall( "GetModuleHandle", UInt,0 )
			If hRes := DllCall( "FindResource", UInt,hMod, Str,Key, UInt,10 )
				If hData := DllCall( "LoadResource", UInt,hMod, UInt,hRes )
					If pData := DllCall( "LockResource", UInt,hData )
						Return VarSetCapacity( Var, nSize := DllCall( "SizeofResource", UInt,hMod, UInt,hRes ) )
							,  DllCall( "RtlMoveMemory", Str,Var, UInt,pData, UInt,nSize )
		Return 0
	}
}
;=========================================================================



;--------- http://ahkscript.org/boards/viewtopic.php?f=6&t=791 ---
;--        from user cyruz
;-- Last edited by cyruz on Sun Mar 09, 2014 12:51 pm, edited 6 times in total
StdoutToVar_CreateProcess(sCmd, sDir:="", ByRef nExitCode:=0) {
    DllCall( "CreatePipe",           PtrP,hStdOutRd, PtrP,hStdOutWr, Ptr,0, UInt,0 )
    DllCall( "SetHandleInformation", Ptr,hStdOutWr,  UInt,1,         UInt,1        )

            VarSetCapacity( pi, (A_PtrSize == 4) ? 16 : 24,  0 )
    siSz := VarSetCapacity( si, (A_PtrSize == 4) ? 68 : 104, 0 )
    NumPut( siSz,      si,  0,                          "UInt" )
    NumPut( 0x100,     si,  (A_PtrSize == 4) ? 44 : 60, "UInt" )
    NumPut( hStdInRd,  si,  (A_PtrSize == 4) ? 56 : 80, "Ptr"  )
    NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 60 : 88, "Ptr"  )
    NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 64 : 96, "Ptr"  )

    If ( !DllCall( "CreateProcess", Ptr,0, Ptr,&sCmd, Ptr,0, Ptr,0, Int,True, UInt,0x08000000
                                  , Ptr,0, Ptr,sDir?&sDir:0, Ptr,&si, Ptr,&pi ) )
        Return ""
      , DllCall( "CloseHandle", Ptr,hStdOutWr )
      , DllCall( "CloseHandle", Ptr,hStdOutRd )

    DllCall( "CloseHandle", Ptr,hStdOutWr ) ; The write pipe must be closed before reading the stdout.
    VarSetCapacity(sTemp, 4095)
    While ( DllCall( "ReadFile", Ptr,hStdOutRd, Ptr,&sTemp, UInt,4095, PtrP,nSize, Ptr,0 ) )
        sOutput .= StrGet(&sTemp, nSize, A_FileEncoding)

    DllCall( "GetExitCodeProcess", Ptr,NumGet(pi,0), Ptr,&nExitCode ), nExitCode := NumGet(nExitCode)
    DllCall( "CloseHandle",        Ptr,NumGet(pi,0)                 )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,A_PtrSize)         )
    DllCall( "CloseHandle",        Ptr,hStdOutRd                    )
    Return sOutput
}
;------------------------------------------------------------------------------------------------------
;======================================================================================================