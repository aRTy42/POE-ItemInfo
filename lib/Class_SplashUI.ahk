class SplashUI
{	
	__New(params*)
	{
		c := params.MaxIndex()
		If (c > 6) {
			throw "Too many parameters passed to SplashUI.New()"
		}
		
		; set defaults
		this.state	:= (params[1] = "" or not params[1]) ? "on" : params[1]
		this.title	:= (params[2] = "" or not params[2]) ? "Splash Screen" : params[2]
		this.message	:= (params[3] = "" or not params[3]) ? "Initializing script" : params[3]		
		this.submessage := (params[4] = "" or not params[4]) ? "" : params[4]		
		this.scriptVersion := (params[5] = "" or not params[5]) ? "" : params[5]		
		this.borderImage := (params[6] = "" or not params[6]) ? "" : params[6]		
		
		; initialize
		this.CreateUI()
	}
	
	CreateUI() {
		Global SplashMessage, SplashSubMessage
		
		;Destroy GUIs in case they still exist
		Gui, SplashUI:Destroy

		Gui, SplashUI:New, +Border -resize -SysMenu -Caption +HwndSplashHwnd 
		Gui, SplashUI:Margin, 10, 2
		Gui, SplashUI:Color, FFFFFF, 000000

		Gui, SplashUI:Add, Progress, w900 h28 x0 y0 c505256 Background505256

		Gui, SplashUI:Font, s12 cFFFFFF bold, Verdana
		Gui, SplashUI:Add, Text, x10 y5 h20 w450 +Center BackgroundTrans, % this.title
		Gui, SplashUI:Font, s7 cFFFFFF norm, Verdana
		Gui, SplashUI:Add, Text, x+-90 yp+6 h20 w90 +Right BackgroundTrans, % this.scriptVersion

		Gui, SplashUI:Font, s10 c000000, Verdana
		Gui, SplashUI:Add, Text, x10 y+5 w450 +Center BackgroundTrans vSplashMessage, % this.message
		
		Gui, SplashUI:Font, s8 c000000, Consolas
		Gui, SplashUI:Add, Text, x10 y+10 w450 r4 +Left BackgroundTrans vSplashSubMessage, % StrLen(this.submessage) ? "- " this.submessage : this.submessage

		Gui, SplashUI:Font, s7 c000000, Verdana
		Gui, SplashUI:Add, Text, x10 y+5 h20 w450 +Right BackgroundTrans, % "AHK v" . A_AHKVersion

		Gui, SplashUI:+LastFound
		Gui, SplashUI:Show, Center w470 NA, % this.title

		WinGetPos, _TTX, _TTY, _TTW, _TTH, ahk_id %SplashHwnd%
		image := this.borderImage
		If (FileExist(image)) {
			WinGetPos, _TTX, _TTY, _TTW, _TTH, ahk_id %SplashHwnd%

			Gui, SplashUI:Add, Picture, w1000 h1 x0 y0, %image%	
			Gui, SplashUI:Add, Picture, w1000 h1 x0 y0, %image%
			
			Gui, SplashUI:Add, Picture, w1 h1000 x0 y0, %image%	
			Gui, SplashUI:Add, Picture, w1 h1000 x0 y0, %image%
			
			_TTH := _TTH -1
			_TTW := _TTW -1
			Gui, SplashUI:Add, Picture, w1000 h1 x0 y%_TTH%, %image%	
			Gui, SplashUI:Add, Picture, w1000 h1 x0 y%_TTH%, %image%
			
			Gui, SplashUI:Add, Picture, w1 h1000 x%_TTW% y1, %image%	
			Gui, SplashUI:Add, Picture, w1 h1000 x%_TTW% y1, %image%
		}
		
		If (state = "off") {
			Gui, SplashUI:Show, Hide
		}
	}
	
	ShowUI() {
		this.state := "on"
		If (this.state = "dead") {
			this.CreateUI()
		} Else {
			Gui, SplashUI:Show
		}		
	}
	
	HideUI() {
		Gui, SplashUI:Show, Hide
		this.state := "off"
	}
	
	DestroyUI() {
		Gui, SplashUI:Destroy
		this.state := "dead"
	}
	
	SetMessage(message) {
		this.message := message
		GuiControl,,SplashMessage, % this.message
		Sleep, 1	; add a small sleep to prevent text field overlapping caused by too fast updates
	}
	SetSubMessage(message) {
		If (StrLen(message)) {
			this.submessage := StrLen(this.submessage) ? this.submessage "`n" : ""
			this.submessage .= "- " message
		} Else {
			this.submessage := this.submessage "`n" ""
		}
		
		arr := StrSplit(this.submessage, "`n") 
		mI := arr.MaxIndex()		
		If (mI > 3) {
			this.submessage := Trim(arr[mI - 2] "`n" arr[mI - 1] "`n" arr[mI])
		}

		GuiControl,,SplashSubMessage, % this.submessage
		Sleep, 1	; add a small sleep to prevent text field overlapping caused by too fast updates
	}
}