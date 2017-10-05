#Include, %A_ScriptDir%\lib\Gdip2.ahk

class GdipTooltip
{
	__New() 
	{
		; Initialize Gdip
		this.gdip := new Gdip()
		this.window := new gdip.Window(new gdip.Size(800, 600))
		this.fillBrush := new gdip.Brush(0xE1000000)
		this.borderBrush := new gdip.Brush(0xE191603B)
		this.fontBrush := new gdip.Brush(0xE1FFFFFF)

		this.borderSize := new this.gdip.Size(2, 2)
		this.padding := new this.gdip.Size(5, 5)

		; Start off with a clear window
		this.HideGdiTooltip()
	}

	ShowGdiTooltip(String, XCoord, YCoord, debug = false)
	{
		; Ignore empty strings
		If(String == "")
			return

		position := new this.gdip.Point(XCoord, YCoord)

		lineWidth := this.CalcStringWidth(String)
		lineHeight := this.CalcStringHeight(String)

		if (lineWidth == 0) {
			lineWidth := 1
		}
		if (lineHeight == 0) {
			lineHeight := 1
		}

		lineWidth := lineWidth * 8

		if (lineWidth > 800) {
			lineWidth := 800
		}
		
		lineHeight := lineHeight * 14
		
		if (lineHeight > 600) {
			lineHeight := 600
		}

		textAreaWidth := lineWidth + (2*this.padding.width)
		textAreaHeight := lineHeight + (2*this.padding.height)

		If (debug)
		{
			console.log("[" . String . "]")
			console.log("lineDims: " . lineWidth . "x" . lineHeight)
			console.log("textArea: " . textAreaWidth . "x" . textAreaHeight)
		}
		
		;console.log("lineDims: " . lineWidth . "x" . lineHeight . "`n" . "textArea: " . textAreaWidth . "x" . textAreaHeight)
		;this.window.Update({ x: XCoord, y: YCoord})

		this.window.Clear()
		this.window.FillRectangle(this.fillBrush, new this.gdip.Point(this.borderSize.width, this.borderSize.height), new this.gdip.Size(textAreaWidth-(this.borderSize.width*2), textAreaHeight-(this.borderSize.height*2)))
		this.window.FillRectangle(this.borderBrush, new this.gdip.Point(0, 0), new this.gdip.Size(this.borderSize.width, textAreaHeight))
		this.window.FillRectangle(this.borderBrush, new this.gdip.Point(textAreaWidth-this.borderSize.width, 0), new this.gdip.Size(this.borderSize.width, textAreaHeight))
		this.window.FillRectangle(this.borderBrush, new this.gdip.Point(0, 0), new gdip.Size(textAreaWidth, this.borderSize.height))
		this.window.FillRectangle(this.borderBrush, new this.gdip.Point(0, textAreaHeight-this.borderSize.height), new gdip.Size(textAreaWidth, this.borderSize.height))

		options := {}
		options.font := "Consolas"
		options.brush := this.fontBrush
		options.width := lineWidth
		options.height := lineHeight
		options.size := 12
		options.left := this.padding.width
		options.top := this.padding.height

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

	CalcStringWidth(String)
	{
		width := 0
		StringArray := StrSplit(String, "`n")
		Loop % StringArray.MaxIndex()
		{
			element := StringArray[a_index]
			len := StrLen(element)
			
			if (len > width)
			{
				width := len
			}
		}

		return width
	}

	CalcStringHeight(String)
	{
		StringReplace, String, String, `n, `n, UseErrorLevel
		height := ErrorLevel
		return height
	}

	UpdateFromOptions(Opts)
	{
		;console.log("UpdateFromOptions: " . Ops.GDIWindowColor . " " . Opts.GDIBorderColor . " " . Opts.GDITextColor)
		this.fillBrush := new gdip.Brush(Opts.GDIWindowColor)
		this.borderBrush := new gdip.Brush(Opts.GDIBorderColor)
		this.fontBrush := new gdip.Brush(Opts.GDITextColor)
	}
}
