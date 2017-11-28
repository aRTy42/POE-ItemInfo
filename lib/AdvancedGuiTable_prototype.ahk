#SingleInstance,force
#Include, %A_ScriptDir%\DebugPrintArray.ahk

item := {}
item.name := "Gloom Bite"
item.basetype := "Ceremonial Axe"
item.lvl := 61
item.baselvl := 51
item.msockets := 3
item.dps := {}
item.dps.ele := 36.0
item.dps.phys := 147.0
item.dps.total := 183.0
item.dps.chaos := 0.0
item.dps.qphys := 162.3
item.dps.qtotal := 198.3

/*
Item Level:    61     Base Level:    51
Max Sockets:    3
Ele DPS:     36.0     Chaos DPS:    0.0
Phys DPS:   147.0     Q20 Phys:   162.3
Total DPS:  183.0     Q20 Total:  198.3
*/

Gui, TTbg:New, +AlwaysOnTop +ToolWindow +hwndTTbgHWnd
Gui, TTbg:Color, Red
Gui, TT:New, +AlwaysOnTop +ToolWindow +hwndTTHWnd

;--------------
table01 := new Table("TT", "t01", "t01H", 9, "Consolas")
table01.AddCell(1, 1, item.name)
table01.AddCell(2, 1, item.basetype)

;--------------
table02 := new Table("TT", "t02", "t02H", 9, "Consolas")

table02.AddCell(1, 1, "Item Level:", "", "", "", "Trans", "", true)
table02.AddCell(1, 2, item.lvl)
table02.AddCell(1, 3, "", "", "", "", "", "", true)
table02.AddCell(1, 4, "Base Level:", "", "", "", "", "bold", true)
table02.AddCell(1, 5, item.baselvl)

table02.AddCell(2, 1, "Max Sockets:", "", "", "White", "Blue", "", true)
table02.AddCell(2, 2, item.msockets)
table02.AddCell(2, 3, "", "", "", "", "", "", true)
table02.AddCell(2, 4, "")
table02.AddCell(2, 5, "")
	
table02.AddCell(3, 1, "Ele DPS:", "", "", "Red", "", "", true)
table02.AddCell(3, 2, item.dps.ele)
table02.AddCell(3, 3, "", "", "", "", "", "", true)
table02.AddCell(3, 4, "Chaos DPS:", "", "", "", "", "italic", true)
table02.AddCell(3, 5, item.dps.chaos)

table02.AddCell(4, 1, "Phys DPS:", "", "Wingdings", "", "", "", true)
table02.AddCell(4, 2, item.dps.phys)
table02.AddCell(4, 3, "", "", "", "", "", "", true)
table02.AddCell(4, 4, "Q20 Phys:", "", "", "", "", "underline", true)
table02.AddCell(4, 5, item.dps.qphys)

table02.AddCell(5, 1, "Total DPS:", "", "", "", "", "", true)
table02.AddCell(5, 2, item.dps.total)
table02.AddCell(5, 3, "", "", "", "", "", "", true)
table02.AddCell(5, 4, "Q20 Total:", "", "", "", "", "strike", true)
table02.AddCell(5, 5, item.dps.qtotal)

;table01.drawtable()
table02.drawtable()

Gui, TT:Color, FFFFFF
Gui, TT:Show, AutoSize, CustomTooltip

WinSet, ExStyle, +0x20, ahk_id %TTHWnd% ; 0x20 = WS_EX_CLICKTHROUGH
WinSet, TransColor, White 255, ahk_id %TTHWnd%
WinSet, Style, -0xC00000, A

; get text gui dimensions
WinGetPos, ttXPos, ttYPos, ttWidth, ttHeight, ahk_id %TTHWnd%
; show bg gui again, now with dimensions/positions
Gui, TTbg:Show, w%ttWidth% h%ttHeight% x%ttXPos% y %ttYPos%
WinSet, ExStyle, +0x20, ahk_id %TTbgHWnd% ; 0x20 = WS_EX_CLICKTHROUGH
WinSet, Style, -0xC00000, A


; show text gui again to have it on top
Gui, TT:Show, AutoSize, CustomTooltip
;DllCall("SetParent", "uint", TTBGHWnd, "uint", TTHWnd)

Return
GuiClose:
ExitApp


class Table {
	__New(GuiName, assocVar, assocHwnd, fontSize = 9, font = "Verdana", color = "Default") {
		this.assocVar := "v" assocVar
		this.assocHwnd := "hwnd" assocHwnd
		this.GuiName := StrLen(GuiName) ? GuiName ":" : ""
		this.fontSize := fontSize
		this.font := font
		this.fColor := color
		this.rows := []
		this.maxColumns := 0
	}
	
	DrawTable() {
		columnWidths := []		
		rowHeights := []		
		Loop, % this.maxColumns {
			w := 0
			i := A_Index
			For key, row in this.rows {
				w := (w >= row[i].width) ? w : row[i].width
			}
			columnWidths[i] := w
		}
		For key, row in this.rows {
			h := 0
			For k, cell in row {
				h := (h >= cell.height) ? h : cell.height
			}
			rowHeights.push(h) 
		}
		;debugprintarray(columnwidths)
		;debugprintarray(rowHeights)
		
		guiName := this.GuiName
		guiFontOptions := " s" this.fontSize
		guiFontOptions .= StrLen(this.fColor) ? " c" this.fColor : ""
		Gui, %guiName%Font, %guiFontOptions%, % this.font 
		
		shiftY := 0
		For key, row in this.rows {
			shiftY += 15
			For k, cell in row {
				addedBackground := false
				width := columnWidths[k] + 20
				height := rowHeights[key]
				yPos := k = 1 ? " y" shiftY : " yp+0"
				xPos := k = 1 ? " x10" : " x+5"
				
				options := ""
				options .= StrLen(cell.color) ? " c" cell.color : ""				
				options .= " w" width 
				options .= " h" height

				If (cell.bgColor = "Trans") {
					options .= " BackGroundTrans"
				} Else If (StrLen(cell.bgColor)) {
					options .= " BackGroundTrans"
					bgColor := cell.bgColor
					Gui, %guiName%Add, Progress, w%width% h%height% %yPos% %xPos% Background%bgColor%					
					options .= " xp yp"
					addedBackground := true
				}
				
				If (not addedBackground) {
					options .= yPos
					options .= xPos
				}

				If (cell.fColor or cell.font or cell.fontOptions) {
					elementFontOptions := StrLen(cell.fColor) ? " c" cell.fColor : ""
					elementFontOptions .= StrLen(cell.fontOptions) ? " " cell.fontOptions : ""
					elementFont := StrLen(cell.font) ? cell.font : this.font
					Gui, %guiName%Font, %elementFontOptions%, % elementFont 
				}				
				Gui, %guiName%Add, Text, %options%, % cell.value
				If (cell.fColor or cell.font) {
					Gui, %guiName%Font, %guiFontOptions% " norm", % this.font 
				}
				
			}
		}		
	}
	
	AddCell(rowIndex, cellIndex, value, alignment = "right", font = "", fColor = "", bgColor = "", fontOptions = "", isSpacingCell = false) {
		If (not this.rows[rowIndex]) {
			this.rows[rowIndex] := []
		}
		
		this.rows[rowIndex][cellIndex] := {}
		this.rows[rowIndex][cellIndex].value := value
		this.rows[rowIndex][cellIndex].font := StrLen(font) ? font : this.font
		size := this.MeasureText(value, this.fontSize + 1, font)
		this.rows[rowIndex][cellIndex].height := size.H
		this.rows[rowIndex][cellIndex].width := (not StrLen(value) and isSpacingCell) ? 10 : size.W
		this.rows[rowIndex][cellIndex].alignment := StrLen(alignment) ? alignment : "right"		
		this.rows[rowIndex][cellIndex].color := fColor
		this.rows[rowIndex][cellIndex].bgColor := bgColor
		this.rows[rowIndex][cellIndex].fontOptions := fontOptions
		this.maxColumns := cellIndex >= this.maxColumns ? cellIndex : cellIndex > this.maxColumns
		;debugprintarray(this.rows[rowIndex][cellIndex])
	}
	
	MeasureText(Str, FontOpts = "", FontName = "") {
		Static DT_FLAGS := 0x0520 ; DT_SINGLELINE = 0x20, DT_NOCLIP = 0x0100, DT_CALCRECT = 0x0400
		Static WM_GETFONT := 0x31
		Size := {}
		Gui, New
		If (FontOpts <> "") || (FontName <> "")
			Gui, Font, %FontOpts%, %FontName%
		Gui, Add, Text, hwndHWND
		SendMessage, WM_GETFONT, 0, 0, , ahk_id %HWND%
		HFONT := ErrorLevel
		HDC := DllCall("User32.dll\GetDC", "Ptr", HWND, "Ptr")
		DllCall("Gdi32.dll\SelectObject", "Ptr", HDC, "Ptr", HFONT)
		VarSetCapacity(RECT, 16, 0)
		DllCall("User32.dll\DrawText", "Ptr", HDC, "Str", Str, "Int", -1, "Ptr", &RECT, "UInt", DT_FLAGS)
		DllCall("User32.dll\ReleaseDC", "Ptr", HWND, "Ptr", HDC)
		Gui, Destroy
		Size.W := NumGet(RECT,  8, "Int")
		Size.H := NumGet(RECT, 12, "Int")
		Return Size
	}
}
