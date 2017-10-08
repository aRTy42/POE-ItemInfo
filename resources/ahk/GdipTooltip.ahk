; AutoHotkey
; Language:       	English 
; Authors:		esunder | https://github.com/esunder
;				Eruyome |	https://github.com/eruyome
;
; Class Function:
;	GDI+ Tooltip
;	
; Functions need the following arguments to set color options:
;	- Window/Border/Font Color in RBG ("000000" - "FFFFFF").
;	- Window/Border/Font Opacity in percent (0 - 100).

#Include, %A_ScriptDir%\lib\Gdip2.ahk

class GdipTooltip
{
	__New(boSize = 2, padding = 5, w = 800, h = 600, wColor = "0xE5000000", bColor = "0xE57A7A7A", fColor = "0xFFFFFFFF", innerBorder = false) 
	{
		; Initialize Gdip
		this.gdip				:= new Gdip()
		this.window			:= new gdip.Window(new gdip.Size(w, h))
		this.fillBrush			:= new gdip.Brush(wColor)
		this.borderBrush 		:= new gdip.Brush(bColor)
		this.borderBrushInner	:= new gdip.Brush(0xE50000FF)
		this.fontBrush			:= new gdip.Brush(fColor)
		
		this.innerBorder	:= innerBorder	
		this.borderSize	:= new this.gdip.Size(boSize, boSize)
		this.padding		:= new this.gdip.Size(padding, padding)
		
		; Start off with a clear window
		this.HideGdiTooltip()
	}

	ShowGdiTooltip(fontSize, String, XCoord, YCoord, debug = false)
	{
		; Ignore empty strings
		If (String == "")
			return

		position := new this.gdip.Point(XCoord, YCoord)
		fontSize := fontSize + 3	

		this.CalculateToolTipDimensions(String, fontSize, ttWidth, ttLineHeight, ttheight)
		
		textAreaWidth	:= Ceil(ttWidth + (2 * this.padding.width))
		textAreaHeight	:= Ceil(ttHeight + (2 * this.padding.height))

		this.window.Clear()
		this.window.size.width	:= textAreaWidth  + this.borderSize.width
		this.window.size.height	:= textAreaHeight + this.borderSize.height
		this.window.FillRectangle(this.fillBrush, new this.gdip.Point(this.borderSize.width, this.borderSize.height), new this.gdip.Size(textAreaWidth-(this.borderSize.width*2), textAreaHeight-(this.borderSize.height*2)))

		; optional inner border - default = false
		If (this.innerBorder) {
			this.window.FillRectangle(this.borderBrushInner, new this.gdip.Point(this.borderSize.width, this.borderSize.height), new this.gdip.Size(this.borderSize.width, textAreaHeight - this.borderSize.height))
			this.window.FillRectangle(this.borderBrushInner, new this.gdip.Point(textAreaWidth - this.borderSize.width - this.borderSize.width, 0), new this.gdip.Size(this.borderSize.width, textAreaHeight - this.borderSize.height))
			this.window.FillRectangle(this.borderBrushInner, new this.gdip.Point(this.borderSize.width, this.borderSize.height), new gdip.Size(textAreaWidth - this.borderSize.width, this.borderSize.height))
			this.window.FillRectangle(this.borderBrushInner, new this.gdip.Point(0, textAreaHeight - this.borderSize.height - this.borderSize.height), new gdip.Size(textAreaWidth - this.borderSize.width, this.borderSize.height))
		}
		
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
	
	SetInnerBorder(state = true, luminosityFactor = 0, argbColorHex = "") {
		this.innerBorder := state
		
		; use passed color 
		argbColorHex := RegExReplace(Trim(argbColorHex), "i)^0x")
		If (StrLen(argbColorHex)) {
			argbColorHex := "0x" this.ValidateRGBColor(argbColorHex, "E5FFFFFF", true)
			this.borderBrushInner := new gdip.Brush(argbColorHex)
		} 
		; darken/lighten the default borders color
		Else If (luminosityFactor > 0 or luminosityFactor < 0) {
			_r := this.ChangeLuminosity(this.borderBrush.Color.r, luminosityFactor)
			_g := this.ChangeLuminosity(this.borderBrush.Color.g, luminosityFactor)
			_b := this.ChangeLuminosity(this.borderBrush.Color.b, luminosityFactor)
			_a := this.borderBrush.Color.a	
			this.borderBrushInner := new gdip.Brush(_a, _r, _g, _b)			
		}
	}	
	
	SetBorderSize(w, h) {
		this.borderSize := new this.gdip.Size(w, h)
	}
	SetPadding(w, h) {
		this.padding := new this.gdip.Size(w, h)
	}

	HideGdiTooltip(debug = false)
	{
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
		ttWidth := Ceil(ttWidth)
		ttHeight := Ceil(ttHeight)
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
	
	ValidateRGBColor(Color, Default, hasOpacity = false) {
		StringUpper, Color, Color
		If (hasOpacity) {
			RegExMatch(Trim(Color), "i)(^[0-9A-F]{8}$)", hex)	
		} Else {
			RegExMatch(Trim(Color), "i)(^[0-9A-F]{6}$)", hex)
		}
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
	
	ChangeLuminosity(c, l = 0) {
		black := 0
		white := 255
		
		If (l > 0) {
			l := l > 1 ? 1 : l
		} Else {
			l := l < -1 ? -1 : l
		}
		
		c := Round(this.Min(this.Max(0, c + (c * l)), 255))	
		;c := this.Min(this.Max(black, c + (l * white)) , white)
		Return Round(c)
	}
	
	Min(x,x1="",x2="",x3="",x4="",x5="",x6="",x7="",x8="",x9="") { 
	   Loop 
		 IfEqual x%A_Index%,,Break 
		 Else If (x  > x%A_Index%) 
				x := x%A_Index% 
	   Return x 
	}
	
	Max(x,x1="",x2="",x3="",x4="",x5="",x6="",x7="",x8="",x9="") { 
	   Loop 
		 IfEqual x%A_Index%,,Break 
		 Else If (x  < x%A_Index%) 
				x := x%A_Index% 
	   Return x 
	}
}