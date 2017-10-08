#Include, %A_ScriptDir%\lib\Gdip2.ahk

class GdipTooltip
{
	__New() 
	{
		; Initialize Gdip
		this.gdip := new Gdip()
		this.window := new gdip.Window(new gdip.Size(800, 600))
		this.fillBrush := new gdip.Brush(0xE5000000)
		this.borderBrush := new gdip.Brush(0xE5513101)
		this.fontBrush := new gdip.Brush(0xFFFEFEFE)

		this.borderSize := new this.gdip.Size(2, 2)
		this.padding := new this.gdip.Size(5, 5)

		; Start off with a clear window
		this.HideGdiTooltip()
	}

	ShowGdiTooltip(Opts, String, XCoord, YCoord, debug = false)
	{
		; Ignore empty strings
		If(String == "")
			return

		position := new this.gdip.Point(XCoord, YCoord)
		fontSize := Opts.FontSize + 3	

		this.CalculateToolTipDimensions(String, fontSize, ttWidth, ttLineHeight, ttheight)
		
		textAreaWidth	:= ttWidth + (2 * this.padding.width)
		textAreaHeight	:= ttHeight + (2 * this.padding.height)

		If (debug) {
			console.log("[" . String . "]")
			console.log("lineDims: " . lineWidth . "x" . lineHeight)
			console.log("textArea: " . textAreaWidth . "x" . textAreaHeight)
		}

		this.window.Clear()
		this.window.FillRectangle(this.fillBrush, new this.gdip.Point(this.borderSize.width, this.borderSize.height), new this.gdip.Size(textAreaWidth-(this.borderSize.width*2), textAreaHeight-(this.borderSize.height*2)))
		this.window.FillRectangle(this.borderBrush, new this.gdip.Point(0, 0), new this.gdip.Size(this.borderSize.width, textAreaHeight))
		this.window.FillRectangle(this.borderBrush, new this.gdip.Point(textAreaWidth-this.borderSize.width, 0), new this.gdip.Size(this.borderSize.width, textAreaHeight))
		this.window.FillRectangle(this.borderBrush, new this.gdip.Point(0, 0), new gdip.Size(textAreaWidth, this.borderSize.height))
		this.window.FillRectangle(this.borderBrush, new this.gdip.Point(0, textAreaHeight-this.borderSize.height), new gdip.Size(textAreaWidth, this.borderSize.height))
		
		options := {}
		options.font	:= "Consolas"
		options.brush	:= this.fontBrush
		options.width	:= ttWidth
		options.height	:= ttHeight
		options.size	:= fontSize
		options.left	:= this.padding.width
		options.top	:= this.padding.height

		this.window.WriteText(String, options)
		this.window.Update({ x: XCoord, y: YCoord})
	}

	HideGdiTooltip(debug = false)
	{
		If (debug) {
			console.log("HideGdiTooltip")
		}

		this.window.Clear()
		this.window.Update()
	}
	
	CalculateToolTipDimensions(String, fontSize, ByRef ttWidth, ByRef ttLineHeight, ByRef ttHeight) {
		ttWidth	:= 0
		ttHeight	:= 0
		StringArray := StrSplit(String, "`n")
		Loop % StringArray.MaxIndex()
		{
			element := StringArray[a_index]
			dim	:= this.MeasureText(element, fontSize + 1, "Consolas")
			len	:= dim["W"] * (fontSize / 10)
			hi	:= dim["H"] * ((fontSize - 1) / 10)
			
			if (len > ttWidth)
			{
				ttWidth := len
			}
			
			ttHeight += hi
			ttLineHeight := hi
		}	
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

	UpdateFromOptions(Opts)
	{		
		this.AssembleHexARGBColors(Opts, wColor, bColor, tColor)
		;console.log("UpdateFromOptions: " . wColor . " " . bColor . " " . tColor)
		this.fillBrush		:= new gdip.Brush(wColor)
		this.borderBrush	:= new gdip.Brush(bColor)
		this.fontBrush		:= new gdip.Brush(tColor)
	}
	
	AssembleHexARGBColors(Opts, ByRef wColor, ByRef bColor, ByRef tColor) {
		_windowOpacity	:= this.ConvertOpacityFromPercentToHex(Opts.GDIWindowOpacity)
		_borderOpacity	:= this.ConvertOpacityFromPercentToHex(Opts.GDIBorderOpacity)
		_textOpacity	:= this.ConvertOpacityFromPercentToHex(Opts.GDITextOpacity)
		
		wColor	:= _windowOpacity . Opts.GDIWindowColor
		bColor	:= _borderOpacity . Opts.GDIBorderColor
		tColor	:= _textOpacity   . Opts.GDITextColor
	}
	
	ValidateRGBColor(Color, Default) {
		StringUpper, Color, Color
		RegExMatch(Trim(Color), "i)(^[0-9A-F]{6}$)|(^[0-9A-F]{3}$)", hex)
		Return StrLen(hex) ? hex : Default
	}
	
	ValidateOpacity(Opacity, Default) {
		Opacity := Opacity + 0	; convert string to int
		If (not RegExMatch(Opacity, "i)[0-9]+")) {
			Opacity := Default
		}
		
		If (Opacity > 100) {
			Opacity := 100
		} Else If (Opacity < 0) {
			Opacity := 0
		}
		Return Opacity
	}
	
	ConvertOpacityFromPercentToHex(Opacity) {
		percToHex := (Opacity / 100) * 255
		hex		:= this.FHex(percToHex)		
		
		Return hex
	}
	
	FHex( int, pad=0 ) {	; Function by [VxE]. Formats an integer (decimals are truncated) as hex.
						; "Pad" may be the minimum number of digits that should appear on the right of the "0x".
		Static hx := "0123456789ABCDEF"
		If !( 0 < int |= 0 )
			Return !int ? "0x0" : "-" this.FHex( -int, pad )
		s := 1 + Floor( Ln( int ) / Ln( 16 ) )
		h := SubStr( "0x0000000000000000", 1, pad := pad < s ? s + 2 : pad < 16 ? pad + 2 : 18 )
		u := A_IsUnicode = 1
		Loop % s
			NumPut( *( &hx + ( ( int & 15 ) << u ) ), h, pad - A_Index << u, "UChar" ), int >>= 4
		Return h
	}
}
