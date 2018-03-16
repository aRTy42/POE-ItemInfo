class Gdip
{
	__New()
	{
		if !DllCall("GetModuleHandle", "str", "gdiplus")
			DllCall("LoadLibrary", "str", "gdiplus")
		VarSetCapacity(si, (A_PtrSize = 8) ? 24 : 16, 0), si := Chr(1)
		DllCall("gdiplus\GdiplusStartup", "uptr*", pToken, "uptr", &si, "uint", 0)
		this.pToken := pToken

		this._New := Gdip.__New
		Gdip.__New := Gdip._DummyNew
	}
	
	_DummyNew()
	{
		return false
	}
	
	__Delete()
	{
		this.Dispose()
	}
	
	Dispose()
	{
		DllCall("gdiplus\GdiplusShutdown", "uptr", this.pToken)
		if (hModule := DllCall("GetModuleHandle", "str", "gdiplus"))
			DllCall("FreeLibrary", "uptr", hModule)
			
		Gdip.__New := this._New
	}
	
	BitmapFromScreen(params*)
	{
		bitmap1 := new Gdip.Bitmap()
		bitmap1.Pointer := bitmap1.BitmapFromScreen(params*)
		return bitmap1
	}
	
	BitmapFromZip(zipObj, file)
	{
		bitmap1 := new Gdip.Bitmap()
		bitmap1.Pointer := bitmap1.BitmapFromZip(zipObj, file)
		return bitmap1
	}
	
	BitmapFromFile(file)
	{
		bitmap1 := new Gdip.Bitmap()
		bitmap1.Pointer := bitmap1.BitmapFromFile(file)
		return bitmap1
	}
	
	class Color
	{
		;ARGB
		;R, G, B
		;A, R, G, B
		__New(params*)
		{
			c := params.MaxIndex()
			if (c = 1)
			{
				this.ARGB := params[1]
			}
			else if (c = 3)
			{
				this.ARGB := (255 << 24) | (params[1] << 16) | (params[2] << 8) | params[3]
			}
			else if (c = 4)
			{
				this.ARGB := (params[1] << 24) | (params[2] << 16) | (params[3] << 8) | params[4]
			}
			else
				throw "Incorrect number of parameters for Color.New()"
			
			this.A := (0xff000000 & this.ARGB) >> 24
			this.R := (0x00ff0000 & this.ARGB) >> 16
			this.G := (0x0000ff00 & this.ARGB) >> 8
			this.B := 0x000000ff & this.ARGB
		}
	}
	
	class Brush
	{
		;ARGB
		;Color
		;R, G, B
		;Color, Color, hatchStyle
		;A, R, G, B
		__New(params*)
		{
			c := params.MaxIndex()
			if (c = 1)
			{
				if (params[1].__Class = "Gdip.Color")
				{
					this.Color := params[1]
					this.Pointer := this.CreateSolid(this.Color.ARGB)
				}
				else
				{
					this.Color := new Gdip.Color(params[1])
					this.Pointer := this.CreateSolid(this.Color.ARGB)
				}
			}
			else if (c = 3)
			{
				if (params[1].__Class = "Gdip.Color")
				{
					this.Color := { "Front": params[1], "Back": params[2] }
					this.HatchStyle := params[3]
					this.Pointer := this.CreateHatch(this.Color.Front.ARGB, this.Color.Back.ARGB, this.HatchStyle)
				}
				else
				{
					this.Color := new Gdip.Color((255 << 24) | (params[1] << 16) | (params[2] << 8) | params[3])
					this.Pointer := this.CreateSolid(this.Color.ARGB)
				}
			}
			else if (c = 4)
			{
				this.Color := new Gdip.Color((params[1] << 24) | (params[2] << 16) | (params[3] << 8) | params[4])
				this.Pointer := this.CreateSolid(this.Color.ARGB)
			}
			else
				throw "Incorrect number of parameters for Brush.New()"
		}
		
		__Delete()
		{
			this.Dispose()
		}
		
		Dispose()
		{			
			try {
				return DllCall("gdiplus\GdipDeleteBrush", "uptr", this.Pointer)	
			} catch e {
				return
			}
		}
		
		CreateSolid(ARGB)
		{
			DllCall("gdiplus\GdipCreateSolidFill", "uint", ARGB, "uptr*", pBrush)
			return pBrush
		}
		
		CreateHatch(ARGBFront, ARGBBack, hatchStyle=0)
		{
			DllCall("gdiplus\GdipCreateHatchBrush", "int", hatchStyle, "uint", ARGBfront, "uint", ARGBback, "uptr*", pBrush)
			return pBrush
		}
	}
	
	class Pen
	{
		;ARGB, w
		;R, G, B, w
		;A, R, G, B, w
		__New(params*)
		{
			c := params.MaxIndex()
			if (c = 2)
			{
				ARGB := params[1]
				width := params[2]
			}
			else if (c = 4)
			{
				ARGB := (255 << 24) | (params[1] << 16) | (params[2] << 8) | params[3]
				width := params[4]
			}
			else if (c = 5)
			{
				ARGB := (params[1] << 24) | (params[2] << 16) | (params[3] << 8) | params[4]
				width := params[5]
			}
			else
				throw "Incorrect number of parameters for Pen.New()"
			this.Pointer := this.CreatePen(ARGB, width)
			this.width := width
		}
		
		__Delete()
		{
			this.Dispose()
		}
		
		Dispose()
		{
			return DllCall("gdiplus\GdipDeletePen", "uptr", this.Pointer)
		}
		
		CreatePen(ARGB, w)
		{
			DllCall("gdiplus\GdipCreatePen1", "UInt", ARGB, "float", w, "int", 2, "uptr*", pPen)
			return pPen
		}
	}
	
	class Drawing
	{
		__New(params*)
		{
			c := params.MaxIndex()
			if (!c)
			{
			}
			else
				throw "Incorrect number of parameters for Bitmap.New()"
		}
		
		FillEllipse(params*)
		{
			return this.obj.FillEllipse(params*)
		}
		
		FillRectangle(params*)
		{
			return this.obj.FillRectangle(params*)
		}
		
		DrawEllipse(params*)
		{
			return this.obj.DrawEllipse(params*)
		}
		
		DrawRectangle(params*)
		{
			return this.obj.DrawRectangle(params*)
		}
		
		DrawImage(params*)
		{
			return this.obj.DrawImage(params*)
		}
		
		DrawLine(params*)
		{
			return this.obj.DrawLine(params*)
		}
		
		FillRoundedRectangle(params*)
		{
			return this.obj.FillRoundedRectangle(params*)
		}
		
		FillPie(params*)
		{
			return this.obj.FillPie(params*)
		}
		
		WriteText(params*)
		{
			return this.obj.WriteText(params*)
		}
	}
	
	class Window extends Gdip.Drawing
	{
		__New(params*)
		{
			;size
			;point, size
			c := params.MaxIndex()
			if (!c)
			{
			}
			else if (c = 1)
			{
				point := new Gdip.Point(0, 0)
				size := params[1]
			}
			else if (c = 2)
			{
				point := params[1]
				size := params[2]
			}
			else
				throw "Incorrect number of parameters for Window.New()"
	
			this.hwnd := DllCall("CreateWindowEx", "uint", 0x80088, "str", "#32770", "ptr", 0, "uint", 0x940A0000
			,"int", point.X, "int", point.Y, "int", size.Width, "int", size.Height, "uptr", 0, "uptr", 0, "uptr", 0, "uptr", 0)
				
			this.point := new Gdip.Point(point.x, point.y)
			this.size := new Gdip.Size(size.width, size.height)
			this.alpha := 255
			this.obj := new Gdip.Object(this.size)
		}
		
		x[]
		{
			get {
				return this.point.x
			}
			set {
				this.point.x := value
			}
		}
		
		y[]
		{
			get {
				return this.point.y
			}
			set {
				this.point.y := value
			}
		}
		
		width[]
		{
			get {
				return this.size.width
			}
		}
		
		height[]
		{
			get {
				return this.size.height
			}
		}
	
		Clear()
		{
			this.obj.Clear()
		}
	
		Update(paramObj=0)
		{
			if (paramObj.x != "")
				this.point.x := paramObj.x
			if (paramObj.y != "")
				this.point.y := paramObj.y
	
			return this.UpdateLayeredWindow(this.hwnd, this.obj.hdc, this.x, this.y, this.width, this.height, this.alpha)
		}
		
		UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", alpha=255)
		{
			if ((x != "") && (y != ""))
				VarSetCapacity(pt, 8), NumPut(x, pt, 0, "uint"), NumPut(y, pt, 4, "uint")
	
			if ((w = "") || (h = ""))
				WinGetPos,,, w, h, ahk_id %hwnd%
				
			return DllCall("UpdateLayeredWindow", "uptr", hwnd, "uptr", 0, "uptr", ((x = "") && (y = "")) ? 0 : &pt, "int64*", w|h<<32, "uptr", hdc, "int64*", 0, "uint", 0, "uint*", alpha<<16|1<<24, "uint", 2)
		}
	}
	
	class Point
	{
		__New(params*)
		{
			c := params.MaxIndex()
			if (c = 2)
			{
				this.X := params[1]
				this.Y := params[2]
			}
			else if (c = 3)
			{
				point1 := params[1]
				this.X := point1.X + params[2]
				this.Y := point1.Y + params[3]
			}
			else
				throw "Incorrect number of parameters for Point.New()"
		}
	}
	
	class Size
	{
		__New(params*)
		{
			c := params.MaxIndex()
			if (c = 2)
			{
				if (IsObject(params[1]))
				{
					this.width := Round(params[1].width * params[2])
					this.height := Round(params[1].height * params[2])
				}
				else
				{
					this.width := params[1]
					this.height := params[2]
				}
			}
			else if (c = 3)
			{
				size1 := params[1]
				this.width := size1.width + params[2]
				this.height := size1.height + params[3]
			}
			else
				throw "Incorrect number of parameters for Size.New()"
		}
	}
	
	class Zip
	{
		;file
		__New(params*)
		{
			c := params.MaxIndex()
			if (c = 1)
			{
				file := FileOpen(params[1], "r")
				this.Handle := file
				this.Files := this.ListFiles(file)
			}
			else
				throw "Incorrect number of parameters for Zip.New()"
		}
		
		Dispose()
		{
			this.Handle.Close()
			this.Handle := ""
			this.Files := ""
		}
		
		__Delete()
		{
			this.Dispose()
		}
		
		GetIndex(file)
		{
			index := -1
			for k, v in this.Files
			{
				if (v.FileName = file)
				{
					index := k
					break
				}
			}
			return index
		}
		
		ListFiles(file)
		{
			fileSize := file.Length
			
			array := []
			;array := {}
			file.Position := fileSize - 46
			
			i := 0
			while(i < 1000 || file.Position <= 5)
			{
				signature := file.ReadUInt()
				if (signature = 0x02014b50)
				{
					i := 0
					file.Seek(16, 1)
					compressedSize := file.ReadInt()
					uncompressedSize := file.ReadInt()
					fileNameLength := file.ReadChar()
					file.Seek(13, 1)
					offset := file.ReadInt()
					fileName := file.Read(fileNameLength)
					if (SubStr(fileName, 0, 1) != "/")
					{
						position := file.Position
						file.Seek(offset, 0)
						localHeader := file.ReadInt()
						if (localHeader = 0x04034b50)
						{
							file.Seek(22, 1)
							fileNameLength := file.ReadChar()
							extraFieldLength := file.ReadChar()
							file.Seek(2, 1)
							fileName := file.Read(fileNameLength)
							StringReplace, fileName, fileName, /, \, All
							extraField := file.Read(extraFieldLength)
							offset := file.Position
							array.Insert({ FileName: fileName, Offset: offset, CompressedSize: compressedSize })
						}
						file.Seek(position, 0)
					}
					pos := -1 * (fileNameLength + 42)
					file.Seek(pos, 1)
				}
				file.Seek(-5, 1)
				i++
			}
			return array
		}
	}
	
	class Bitmap extends Gdip.Drawing
	{
		;size
		;width, height
		;width, height, format
		__New(params*)
		{
			c := params.MaxIndex()
			this._pointer := 0
			if (!c)
			{
				
			}
			else if (c = 1)
			{
				this._pointer := this.CreateBitmap(params[1].width, params[1].height)
			}
			else if (c = 2)
			{
				this._pointer := this.CreateBitmap(params[1], params[2])
			}
			else if (c = 3)
			{
				this._pointer := this.CreateBitmap(params[1], params[2], params[3])
			}
			else
				throw "Incorrect number of parameters for Bitmap.New()"
	
			if (this._pointer != 0)
			{
				width := this.GetImageWidth(this.Pointer)
				height := this.GetImageHeight(this.Pointer)
				this.size := new Gdip.Size(width, height)
				this.obj := new Gdip.Object(this)
			}
		}
	
		Pointer[]
		{
			get {
				return this._pointer
			}
			set {
				this._pointer := value
				width := this.GetImageWidth(this._pointer)
				height := this.GetImageHeight(this._pointer)
				this.size := new Gdip.Size(width, height)
				this.obj := new Gdip.Object(this)
			}
		}
		
		width[]
		{
			get { 
				return this.size.width
			}
		}
		
		height[]
		{
			get {
				return this.size.height
			}
		}
	
		__Delete()
		{
			this.Dispose()
		}
		
		Dispose()
		{
			this.DisposeImage(this._pointer)
			this._pointer := 0
		}
		
		DisposeImage(pBitmap)
		{
			return DllCall("gdiplus\GdipDisposeImage", "uptr", pBitmap)
		}
		
		DeleteGraphics(pGraphics)
		{
		   return DllCall("gdiplus\GdipDeleteGraphics", "uptr", pGraphics)
		}
		
		BitmapFromFile(file)
		{
			DllCall("gdiplus\GdipCreateBitmapFromFile", "uptr", &file, "uptr*", pBitmap)
			return pBitmap
		}
		
		BitmapFromZip(zipObj, file)
		{
			pBitmap := 0
			if (file + 0 > 0)
			{
				pBitmap := this.BitmapFromStream(zipObj.Handle, zipObj.Files[file].Offset, zipObj.Files[file].CompressedSize)
			}
			else
			{
				for k, v in zipObj.Files
				{
					if (v.FileName = file)
					{
						pBitmap := this.BitmapFromStream(zipObj.Handle, v.Offset, v.CompressedSize)
						break
					}
				}
			}
			return pBitmap
		}
		
		BitmapFromStream(file, start, size)
		{
			file.Position := start
			file.RawRead(memoryFile, size)
			hData := DllCall("GlobalAlloc", "uint", 2, "ptr", size, "ptr")
			pData := DllCall("GlobalLock", "ptr", hData, "ptr")
			DllCall("RtlMoveMemory", "ptr", pData, "ptr", &memoryFile, "ptr", size)
			unlock := DllCall("GlobalUnlock", "ptr", hData)
			stream := DllCall("ole32\CreateStreamOnHGlobal", "ptr", hData, "int", 1, "uptr*", pStream)
			DllCall("gdiplus\GdipCreateBitmapFromStream", "ptr", pStream, "uptr*", pBitmap)
			ObjRelease(pStream)
			return pBitmap
		}
		
		;screenNumber (0 default)
		;screenNumber, raster
		;{ hwnd: hwnd }
		;{ hwnd: hwnd }, raster
		;x, y, w, h
		;x, y, w, h, raster
		BitmapFromScreen(params*)
		{
			c := params.MaxIndex()
			obj := new Gdip.Object()
			
			if (c = 1 || c = 2)
			{
				if (IsObject(params[1]))
				{
					hwnd := params[1].hwnd
					if !WinExist( "ahk_id " hwnd)
						return -2
					x := 0, y := 0
					WinGetPos,,, w, h, ahk_id %hwnd%
					hhdc := obj.GetDCEx(hwnd, 3)
				}
				else
				{
					if (screen = 0)
					{
						Sysget, x, 76
						Sysget, y, 77	
						Sysget, w, 78
						Sysget, h, 79
					}
					else
					{
						Sysget, M, Monitor, % params[1]
						x := MLeft, y := MTop, w := MRight-MLeft, h := MBottom-MTop
					}
				}
				raster := params[2] ? params[2] : ""
			}
			else if (c = 4 || c = 5)
			{
				x := params[1], y := params[2], w := params[3], h := params[4]
				raster := params[5] ? params[5] : ""
			}
			else
				throw "Incorrect number of parameters for Bitmap.BitmapFromScreen()"
	
			chdc := obj.CreateCompatibleDC()
			hbm := obj.CreateDIBSection(w, h, chdc)
			obm := obj.SelectObject(chdc, hbm)
			hhdc := hhdc ? hhdc : obj.GetDC()
			obj.BitBlt(chdc, 0, 0, w, h, hhdc, x, y, raster)
			obj.ReleaseDC(hhdc)
			
			pBitmap := this.CreateBitmapFromHBITMAP(hbm)
			obj.SelectObject(chdc, obm)
			obj.DeleteObject(hbm)
			obj.DeleteDC(hhdc)
			obj.DeleteDC(chdc)
			return pBitmap
		}
	
		CreateBitmap(width, height, format=0x26200A)
		{
			DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", width, "int", height, "int", 0, "int", format, "uptr", 0, "uptr*", pBitmap)
			return pBitmap
		}
		
		CreateBitmapFromHBITMAP(hBitmap, palette=0)
		{
			DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "uptr", hBitmap, "uptr", palette, "uptr*", pBitmap)
			return pBitmap
		}
		
		CloneBitmapArea(point, size, format=0x26200A)
		{
			bitmap1 := new Gdip.Bitmap()
			bitmap1.Pointer := this._CloneBitmapArea(this.Pointer, point.X, point.Y, size.Width, size.Height, format)
			return bitmap1
		}
	
		_CloneBitmapArea(pBitmap, x, y, w, h, format=0x26200A)
		{
			DllCall("gdiplus\GdipCloneBitmapArea", "float", x, "float", y, "float", w, "float", h, "int", format, "uptr", pBitmap, "uptr*", pBitmapDest)
			return pBitmapDest
		}
		
		GraphicsFromImage(pBitmap)
		{
			DllCall("gdiplus\GdipGetImageGraphicsContext", "uptr", pBitmap, "uptr*", pGraphics)
			return pGraphics
		}
		
		SaveToFile(output, quality=75)
		{
			return this._SaveBitmapToFile(this.Pointer, output, quality)
		}
		
		_SaveBitmapToFile(pBitmap, output, quality=75)
		{
			SplitPath, output,,, extension
			if extension not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
				return -1
			extension := "." extension
			
			DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
			VarSetCapacity(ci, nSize)
			DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, "uptr", &ci)
			if !(nCount && nSize)
				return -2
				
			Loop, % nCount
			{
				idx := 104*(A_Index-1)
				sString := StrGet(NumGet(ci, idx+56), "UTF-16")
				if !InStr(sString, "*" extension)
					continue
				pCodec := &ci+idx
				break
			}
			
			if !pCodec
				return -3
				
			if (quality != 75)
			{
				if Extension in .JPG,.JPEG,.JPE,.JFIF
				{
					quality := (quality < 0) ? 0 : (quality > 100) ? 100 : quality
					DllCall("gdiplus\GdipGetEncoderParameterListSize", "uptr", pBitmap, "uptr", pCodec, "uint*", nSize)
					VarSetCapacity(EncoderParameters, nSize, 0)
					DllCall("gdiplus\GdipGetEncoderParameterList", "uptr", pBitmap, "uptr", pCodec, "uint", nSize, "uptr", &EncoderParameters)
					Loop, % NumGet(EncoderParameters, "uint")
					{
						pad := (A_PtrSize = 8) ? 4 : 0
						offset := 32 * (A_Index-1) + 4 + pad
						if (NumGet(EncoderParameters, offset+16, "uint") = 1) && (NumGet(EncoderParameters, offset+20, "uint") = 6)
						{
							encoderParams := offset+&EncoderParameters - pad - 4
							NumPut(quality, NumGet(NumPut(4, NumPut(1, encoderParams+0)+20, "uint")), "uint")
							break
						}
					}      
				}
			}
			E := DllCall("gdiplus\GdipSaveImageToFile", "uptr", pBitmap, "uptr", &output, "uptr", pCodec, "uint", encoderParams ? encoderParams : 0)
			return E ? -5 : 0
		}
		
		;Scale
		;Width, Height
		
		;Scale, ReturnNew
		;Width,Height,ReturnNew
		Resize(params*)
		{
			c := params.MaxIndex()
			if (c = 1)
			{
				size := new Gdip.Size(this.size, params[1])
				dispose := true
			}
			else if (c = 2)
			{
				if (params[2] = 0)
				{
					size := new Gdip.Size(this.size, params[1])
					dispose := false
				}
				else
				{
					size := new Gdip.Size(params[1], params[2])
					dispose := true
				}
			}
			else if (c = 3)
			{
				size := new Gdip.Size(params[1], params[2])
				dispose := params[3]
			}
			else
				throw "Incorrect number of parameters for Bitmap.Resize()"
			
	
			obj := new Gdip.Object()
			pBitmap := this.CreateBitmap(size.width, size.height)
			pGraphics := this.GraphicsFromImage(pBitmap)
			E := obj.DrawImage(pGraphics, this, new Gdip.Point(0, 0), size)
			
			if (dispose)
			{
				this.DisposeImage(this._pointer)
				this.DeleteGraphics(pGraphics)
				this._pointer := pBitmap
				this.size := size
				return this
			}
			else
			{
				bitmap := new Gdip.Bitmap()
				bitmap.Pointer := pBitmap
				bitmap.size := size
				this.DeleteGraphics(pGraphics)
				return bitmap
			}
		}
		
		GetImageWidth(pBitmap)
		{
			DllCall("gdiplus\GdipGetImageWidth", "uptr", pBitmap, "uint*", width)
			return width
		}
		
		GetImageHeight(pBitmap)
		{
			DllCall("gdiplus\GdipGetImageHeight", "uptr", pBitmap, "uint*", height)
			return height
		}
	}
	
	class Object
	{
		;size
		;bitmap
		;width, height
		__New(params*)
		{
			c := params.MaxIndex()
			if (!c)
			{
			}
			else if (c = 1)
			{
				if (params[1].__Class = "Gdip.Size")
				{
					this.size := params[1]
					hasGraphics := false
				}
				else
				{
					bitmap1 := params[1]
					this.size := bitmap1.size
					this.pGraphics := bitmap1.GraphicsFromImage(bitmap1.Pointer)
					hasGraphics := true
				}
			}
			else if (c = 2)
			{
				this.size := new Gdip.Size(params[1], params[2])
				hasGraphics := false
			}
			else
				throw "Incorrect number of parameters for Object.New()"
			
			if (!hasGraphics)
			{
				this.hBitmap := this.CreateDIBSection(this.size.width, this.size.height)
				this.hdc := this.CreateCompatibleDC()
				this.hgdiObj := this.SelectObject(this.hdc, this.hBitmap)
				this.pGraphics := this.GraphicsFromHDC(this.hdc)
			}
			this.SetSmoothingMode(this.pGraphics, 4)
			this.SetInterpolationMode(this.pGraphics, 7)
		}
		
		width[]
		{
			get {
				return this.size.width
			}
		}
		
		height[]
		{
			get {
				return this.size.height
			}
		}
		
		__Delete()
		{
			this.Dispose()
		}
		
		Dispose()
		{
			this.SelectObject(this.hdc, this.hgdiObj)
			this.DeleteObject(this.hBitmap)
			this.DeleteDC(this.hdc)
			this.DeleteGraphics(this.pGraphics)
			this.hdc := ""
			this.hgdiObj := ""
			this.hBitmap := ""
			this.pGraphics := ""
		}
		
		CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)
		{
			hdc2 := hdc ? hdc : this.GetDC()
			VarSetCapacity(bi, 40, 0)
	
			NumPut(w, bi, 4, "uint")
			NumPut(h, bi, 8, "uint")
			NumPut(40, bi, 0, "uint")
			NumPut(1, bi, 12, "ushort")
			NumPut(0, bi, 16, "uint")
			NumPut(bpp, bi, 14, "ushort")
	
			hBitmap := DllCall("CreateDIBSection", "uptr", hdc2, "uptr", &bi, "uint", 0, "uptr*", ppvBits, "uptr", 0, "uint", 0)
	
			if !hdc
				this.ReleaseDC(hdc2)
			return hBitmap
		}
		
		CreateCompatibleDC(hdc=0)
		{
			return DllCall("CreateCompatibleDC", "uptr", hdc)
		}
	
		SelectObject(hdc, hgdiObj)
		{
			return DllCall("SelectObject", "uptr", hdc, "uptr", hgdiObj)
		}
		
		GetDC(hwnd=0)
		{
			return DllCall("GetDC", "uptr", hwnd)
		}
		
		GetDCEx(hwnd, flags=0, hrgnClip=0)
		{
			return DllCall("GetDCEx", "uptr", hwnd, "uptr", hrgnClip, "int", flags)
		}
		
		ReleaseDC(hdc, hwnd=0)
		{
			return DllCall("ReleaseDC", "uptr", hwnd, "uptr", hdc)
		}
		
		DeleteObject(hgdiObj)
		{
			return DllCall("DeleteObject", "uptr", hgdiObj)
		}
		
		DeleteDC(hdc)
		{
			return DllCall("DeleteDC", "uptr", hdc)
		}
		
		DeleteGraphics(pGraphics)
		{
			return DllCall("gdiplus\GdipDeleteGraphics", "uptr", pGraphics)
		}
		
		GraphicsFromHDC(hdc)
		{
			DllCall("gdiplus\GdipCreateFromHDC", A_PtrSize ? "UPtr" : "UInt", hdc, A_PtrSize ? "UPtr*" : "UInt*", pGraphics)
			return pGraphics
		}
		
		BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, raster="")
		{
			return DllCall("gdi32\BitBlt", "uptr", dDC, "int", dx, "int", dy, "int", dw, "int", dh, "uptr", sDC, "int", sx, "int", sy, "uint", raster ? raster : 0x00CC0020)
		}
	
		SetSmoothingMode(pGraphics, smoothingMode)
		{
			return DllCall("gdiplus\GdipSetSmoothingMode", "uptr", pGraphics, "int", smoothingMode)
		}
		
		SetInterpolationMode(pGraphics, InterpolationMode)
		{
		   return DllCall("gdiplus\GdipSetInterpolationMode", "uptr", pGraphics, "int", InterpolationMode)
		}
		
		WriteText(content, options=0)
		{
			defaults := { font: "Arial", size: 16, style: ["Bold"], noWrap: false, brush: 0, horizontalAlign: "left", verticalAlign: "middle", rendering: 4, left: 0, top: 0, width: 0, height: 0  }
			styles := { "Regular": 0, "Bold": 1, "Italic": 2, "BoldItalic": 3, "Underline": 4, "Strikeout": 8 }
			horizontalAlignments := { "left": 0, "center": 1, "right": 2 }
			verticalAlignments := { "top": 0, "middle" : 0, "bottom": 0 }
	
			options2 := {}
			for k, v in defaults
			{
				options2[k] := (options.HasKey(k)) ? options[k] : defaults[k]
			}
			options := options2
			
			style := 0
			loop % options.style.MaxIndex()
			{
				if (!styles.HasKey(options.style[A_Index]))
					throw "Bad style for Object.WriteText() - " options.style[A_Index]
				style |= styles[options.style[A_Index]]
			}
	
			options.formatStyle := (options.noWrap) ? 0x4000 | 0x1000 : 0x4000
			
			if (options.brush.__Class != "Gdip.Brush")
				throw "Bad brush for Object.WriteText() - " options.brush
			
			if (!horizontalAlignments.HasKey(options.horizontalAlign))
				throw "Bad alignment for Object.WriteText() - " options.horizontalAlign
			options.horizontalAlign := horizontalAlignments[options.horizontalAlign]
			
			if (!verticalAlignments.HasKey(options.verticalAlign))
				throw "Bad alignment for Object.WriteText() - " options.verticalAlign
			
			options.rendering := ((options.rendering >= 0) && (options.rendering <= 5)) ? options.rendering : 4
	
			hFamily := this.FontFamilyCreate(options.font)
			hFont := this.FontCreate(hFamily, options.size, style)
			hFormat := this.StringFormatCreate(options.formatStyle)
			
			VarSetCapacity(RC, 16)
			NumPut(options.left, RC, 0, "float"), NumPut(options.top, RC, 4, "float")
			NumPut(options.width, RC, 8, "float"), NumPut(options.height, RC, 12, "float")
			
			this.SetStringFormatAlign(hFormat, options.horizontalAlign)
			this.SetTextRenderingHint(this.pGraphics, options.rendering)
			
			measure := this.MeasureString(this.pGraphics, content, hFont, hFormat, RC)
			
			if (options.verticalAlign = "top")
			{
			}
			else if (options.verticalAlign = "middle")
			{
				top := options.top + (options.height - measure.height) / 2
				NumPut(top, RC, 4, "float")
			}
			else if (options.verticalAlign = "bottom")
			{
				top := options.bottom - measure.height
				NumPut(top, RC, 4, "float")
			}
			
			E := this.DrawString(this.pGraphics, content, hFont, hFormat, options.brush.pointer, RC)
			
			this.DeleteStringFormat(hFormat)   
			this.DeleteFont(hFont)
			this.DeleteFontFamily(hFamily)
			return measure
		}
		
		FontFamilyCreate(font)
		{
			DllCall("gdiplus\GdipCreateFontFamilyFromName", "uptr", &font, "uint", 0, "uptr*", hFamily)
			return hFamily
		}
		
		; Regular = 0
		; Bold = 1
		; Italic = 2
		; BoldItalic = 3
		; Underline = 4
		; Strikeout = 8
		FontCreate(hFamily, size, style=0)
		{
			DllCall("gdiplus\GdipCreateFont", "uptr", hFamily, "float", Size, "int", Style, "int", 0, "uptr*", hFont)
			return hFont
		}
		
		; StringFormatFlagsDirectionRightToLeft    = 0x00000001
		; StringFormatFlagsDirectionVertical       = 0x00000002
		; StringFormatFlagsNoFitBlackBox           = 0x00000004
		; StringFormatFlagsDisplayFormatControl    = 0x00000020
		; StringFormatFlagsNoFontFallback          = 0x00000400
		; StringFormatFlagsMeasureTrailingSpaces   = 0x00000800
		; StringFormatFlagsNoWrap                  = 0x00001000
		; StringFormatFlagsLineLimit               = 0x00002000
		; StringFormatFlagsNoClip                  = 0x00004000 
		StringFormatCreate(format=0, lang=0)
		{
			DllCall("gdiplus\GdipCreateStringFormat", "int", format, "int", lang, "uptr*", hFormat)
			return hFormat
		}
		
		; Near = 0
		; Center = 1
		; Far = 2
		SetStringFormatAlign(hFormat, align)
		{
			return DllCall("gdiplus\GdipSetStringFormatAlign", "uptr", hFormat, "int", align)
		}
		
		SetTextRenderingHint(pGraphics, renderingHint)
		{
			return DllCall("gdiplus\GdipSetTextRenderingHint", "uptr", pGraphics, "int", renderingHint)
		}
		
		MeasureString(pGraphics, sString, hFont, hFormat, ByRef RectF)
		{
			VarSetCapacity(RC, 16)
			DllCall("gdiplus\GdipMeasureString", "uptr", pGraphics, "uptr", A_IsUnicode ? &sString : &wString, "int", -1, "uptr", hFont, "uptr", &RectF, "uptr", hFormat, "uptr", &RC, "uint*", Chars, "uint*", Lines)
			return { left: NumGet(RC, 0, "float"), top: NumGet(RC, 4, "float"), width: NumGet(RC, 8, "float"), height: NumGet(RC, 12, "float"), characterCount: chars, lineCount: lines }
		}
		
		DrawString(pGraphics, sString, hFont, hFormat, pBrush, ByRef RectF)
		{
			return DllCall("gdiplus\GdipDrawString", "uptr", pGraphics, "uptr", &sString, "int", -1, "uptr", hFont, "uptr", &RectF, "uptr", hFormat, "uptr", pBrush)
		}
		
		DeleteStringFormat(hFormat)
		{
			return DllCall("gdiplus\GdipDeleteStringFormat", "uptr", hFormat)
		}
		
		DeleteFont(hFont)
		{
			return DllCall("gdiplus\GdipDeleteFont", "uptr", hFont)
		}
		
		DeleteFontFamily(hFamily)
		{
			return DllCall("gdiplus\GdipDeleteFontFamily", "uptr", hFamily)
		}
		
		;pen, point, size
		;pen, x, y, w, h
		;pGraphics, pen, x, y, w, h
		DrawRectangle(params*)
		{
			c := params.MaxIndex()
			if (c = 3)
			{
				pen1 := params[1]
				point1 := params[2]
				size1 := params[3]
				x := point1.x + pen1.width / 2
				y := point1.y + pen1.width / 2
				w := size1.width - pen1.width
				h := size1.height - pen1.width
				E := this._DrawRectangle(this.pGraphics, pen1.Pointer, x, y, w, h)
			}
			else if (c = 5)
			{
				pen1 := params[1]
				x := params[2] + pen1.width / 2
				y := params[3] + pen1.width / 2
				w := params[4] - pen1.width
				h := params[5] - pen1.width
				E := this._DrawRectangle(this.pGraphics, pen1.Pointer, x, y, w, h)
			}
			else if (c = 6)
			{
				E := this._DrawRectangle(params[1], params[2], params[3], params[4], params[5], params[6])
			}
			else
				throw "Incorrect number of parameters for Object.DrawRectangle()"
			return E
		}
	
		_DrawRectangle(pGraphics, pPen, x, y, w, h)
		{
			return DllCall("gdiplus\GdipDrawRectangle", "uptr", pGraphics, "uptr", pPen, "float", x, "float", y, "float", w, "float", h)
		}
		
		;pen, point, size
		;pen, x, y, w, h
		;pGraphics, pen, x, y, w, h
		DrawEllipse(params*)
		{
			c := params.MaxIndex()
			if (c = 3)
			{
				E := this._DrawEllipse(this.pGraphics, params[1].pointer, params[2].x, params[2].y, params[3].width, params[3].height)
			}
			else if (c = 5)
			{
				E := this._DrawEllipse(this.pGraphics, params[1].pointer, params[2], params[3], params[4], params[5])
			}
			else if (c = 6)
			{
				E := this._DrawEllipse(params[1], params[2], params[3], params[4], params[5], params[6])
			}
			else
				throw "Incorrect number of parameters for Object.DrawEllipse()"
			return E
		}
		
		_DrawEllipse(pGraphics, pPen, x, y, w, h)
		{
			return DllCall("gdiplus\GdipDrawEllipse", "uptr", pGraphics, "uptr", pPen, "float", x, "float", y, "float", w, "float", h)
		}
		
		;brush, point, size
		;brush, x, y, w, h
		;pGraphics, brush, x, y, w, h
		FillRectangle(params*)
		{
			c := params.MaxIndex()
			if (c = 3)
			{
				E := this._FillRectangle(this.pGraphics, params[1].Pointer, params[2].x, params[2].y, params[3].width, params[3].height)
			}
			else if (c = 5)
			{
				E := this._FillRectangle(this.pGraphics, params[1].Pointer, params[2], params[3], params[4], params[5])
			}
			else if (c = 6)
			{
				E := this._FillRectangle(params[1], params[2].pointer, params[3], params[4], params[5], params[6])
			}
			else
				throw "Incorrect number of parameters for Object.FillRectangle()"
			return E
		}
		
		_FillRectangle(pGraphics, pBrush, x, y, w, h)
		{
			return DllCall("gdiplus\GdipFillRectangle", "uptr", pGraphics, "uptr", pBrush, "float", x, "float", y, "float", w, "float", h)
		}
		
		;brush, point, size
		;brush, x, y, w, h
		;pGraphics, brush, x, y, w, h
		FillEllipse(params*)
		{
			c := params.MaxIndex()
			if (c = 3)
			{
				E := this._FillEllipse(this.pGraphics, params[1].Pointer, params[2].X, params[2].Y, params[3].Width, params[3].Height)
			}
			else if (c = 5)
			{
				E := this._FillEllipse(this.pGraphics, params[1].Pointer, params[2], params[3], params[4], params[5])
			}
			else if (c = 6)
			{
				E := this._FillEllipse(params[1], params[2].pointer, params[3], params[4], params[5], params[6])
			}
			else
				throw "Incorrect number of parameters for Object.FillEllipse()"
			return E
		}
	
		_FillEllipse(pGraphics, pBrush, x, y, w, h)
		{
			return DllCall("gdiplus\GdipFillEllipse", "uptr", pGraphics, "uptr", pBrush, "float", x, "float", y, "float", w, "float", h)
		}
		
		;brush, point, size, startAngle, sweepAngle
		;brush, x, y, w, h, startAngle, sweepAngle
		;pGraphics, brush, x, y, w, h, startAngle, sweepAngle
		FillPie(params*)
		{
			c := params.MaxIndex()
			if (c = 5)
			{
				E := this._FillPie(this.pGraphics, params[1].pointer, params[2].X, params[2].Y, params[3].Width, params[3].Height, params[4], params[5])
			}
			else if (c = 7)
			{
				E := this._FillPie(this.pGraphics, params[1].pointer, params[2], params[3], params[4], params[5], params[6], params[7])
			}
			else if (c = 8)
			{
				E := this._FillPie(params[1], params[2].pointer, params[3], params[4], params[5], params[6], params[7], params[8])
			}
			else
				throw "Incorrect number of parameters for Object.FillPie()"
			return E
		}
		
		_FillPie(pGraphics, pBrush, x, y, w, h, startAngle, sweepAngle)
		{
			return DllCall("gdiplus\GdipFillPie", "uptr", pGraphics, "uptr", pBrush, "float", x, "float", y, "float", w, "float", h, "float", startAngle, "float", sweepAngle)
		}
		
		;brush, point, size, r
		;brush, x, y, w, h, r
		;pGraphics, brush, x, y, w, h, r
		FillRoundedRectangle(params*)
		{
			c := params.MaxIndex()
			if (c = 4)
			{
				E := this._FillRoundedRectangle(this.pGraphics, params[1].pointer, params[2].X, params[2].Y, params[3].Width, params[3].Height, params[4])
			}
			else if (c = 6)
			{
				E := this._FillRoundedRectangle(this.pGraphics, params[1].pointer, params[2], params[3], params[4], params[5], params[6])
			}
			else if (c = 7)
			{
				E := this._FillRoundedRectangle(params[1], params[2].pointer, params[3], params[4], params[5], params[6], params[7])
			}
			else
				throw "Incorrect number of parameters for Object.FillRoundedRectangle()"
			return E
		}
		
		_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r)
		{
			r := (w <= h) ? (r < w // 2) ? r : w // 2 : (r < h // 2) ? r : h // 2
			path1 := this.CreatePath(0)
			this.AddPathRectangle(path1, x+r, y, w-(2*r), r)
			this.AddPathRectangle(path1, x+r, y+h-r, w-(2*r), r)
			this.AddPathRectangle(path1, x, y+r, r, h-(2*r))
			this.AddPathRectangle(path1, x+w-r, y+r, r, h-(2*r))
			this.AddPathRectangle(path1, x+r, y+r, w-(2*r), h-(2*r))
			this.AddPathPie(path1, x, y, 2*r, 2*r, 180, 90)
			this.AddPathPie(path1, x+w-(2*r), y, 2*r, 2*r, 270, 90)
			this.AddPathPie(path1, x, y+h-(2*r), 2*r, 2*r, 90, 90)
			this.AddPathPie(path1, x+w-(2*r), y+h-(2*r), 2*r, 2*r, 0, 90)
			this.FillPath(pGraphics, pBrush, path1)
			this.DeletePath(path1)
			return r
		}
		
		;pen, point, point
		;pen, x1, y1, x2, y2
		;pGraphics, pen, x1, y1, x2, y2
		DrawLine(params*)
		{
			c := params.MaxIndex()
			if (c = 3)
			{
				E := this._DrawLine(this.pGraphics, params[1].pointer, params[2].X, params[2].Y, params[3].X, params[3].Y)
			}
			if (c = 5)
			{
				E := this._DrawLine(this.pGraphics, params[1].pointer, params[2], params[3], params[4], params[5])
			}
			else if (c = 6)
			{
				E := this._DrawLine(params[1], params[2].pointer, params[3], params[4], params[5], params[6])
			}
			else
				throw "Incorrect number of parameters for Object.DrawLine()"
			return E
		}
		
		_DrawLine(pGraphics, pPen, x1, y1, x2, y2)
		{
			return DllCall("gdiplus\GdipDrawLine", "uptr", pGraphics, "uptr", pPen, "float", x1, "float", y1, "float", x2, "float", y2)
		}
		
		;pen, point, size, r, penWidth
		;pGraphics, pen, x, y, w, h, r, penWidth
		DrawRoundedRectangle(params*)
		{
			c := params.MaxIndex()
			if (c = 4)
			{
				pen1 := params[1]
				E := this._DrawRoundedRectangle(this.pGraphics, pen1.Pointer, params[2].x, params[2].y, params[3].width, params[3].height, params[4], pen1.width)
			}
			else if (c = 7)
			{
				pen1 := params[2]
				E := this._DrawRoundedRectangle(params[1], pen1.Pointer, params[3], params[4], params[5], params[6], params[7], pen1.width)
			}
			else
				throw "Incorrect number of parameters for Object.DrawRoundedRectangle()"
			return E
		}
		
		_DrawRoundedRectangle(pGraphics, pPen, x, y, w, h, r, penWidth)
		{
			pw := penWidth / 2
			
			if (w <= h && (r + pw > w / 2))
			{
				r := (w / 2 > pw) ? w / 2 - pw : 0
			}
			else if (h < w && r + pw > h / 2)
			{
				r := (h / 2 > pw) ? h / 2 - pw : 0
			}
			else if (r < pw / 2)
			{
				r := pw / 2
			}
			r2 := r * 2
			
			path1 := this.CreatePath(0)
			this.AddPathArc(path1, x + pw, y + pw, r2, r2, 180, 90)
			this.AddPathLine(path1, x + pw + r, y + pw, x + w - r - pw, y + pw)
			this.AddPathArc(path1, x + w - r2 - pw, y + pw, r2, r2, 270, 90)
			this.AddPathLine(path1, x + w - pw, y + r + pw, x + w - pw, y + h - r - pw)
			this.AddPathArc(path1, x + w - r2 - pw, y + h - r2 - pw, r2, r2, 0, 90)
			this.AddPathLine(path1, x + w - r - pw, y + h - pw, x + r + pw, y + h - pw)
			this.AddPathArc(path1, x + pw, y + h - r2 - pw, r2, r2, 90, 90)
			this.AddPathLine(path1, x + pw, y + h - r - pw, x + pw, y + r + pw)
			this.ClosePathFigure(path1)
			this.DrawPath(pGraphics, pPen, path1)
			this.DeletePath(path1)
			return r
		}
		
		;1
		;bitmap
		
		;2
		;bitmap,point
		;pGraphics,bitmap
		
		;3
		;bitmap,point,size
		;pGraphics,bitmap,point
		
		;4
		;pGraphics,bitmap,point, size
		
		;5
		;bitmap,point,size,point,size
		DrawImage(params*)
		{
			c := params.MaxIndex()
			if (c = 1)
			{
				bitmap := params[1]
				E := this._DrawImage(this.pGraphics, bitmap.Pointer, 0, 0, bitmap.Width, bitmap.Height, 0, 0, bitmap.Width, bitmap.Height, bitmap.ImageAttr)
			}
			else if (c = 2)
			{
				if (params[1].__Class = "Gdip.Bitmap")
				{
					bitmap := params[1]
					E := this._DrawImage(this.pGraphics, bitmap.Pointer, params[2].X, params[2].Y, bitmap.Width, bitmap.Height, 0, 0, bitmap.Width, bitmap.Height, bitmap.ImageAttr)
				}
				else
				{
					bitmap := params[2]
					E := this._DrawImage(params[1], bitmap.Pointer, params[2].X, params[2].Y, bitmap.Width, bitmap.Height, 0, 0, bitmap.Width, bitmap.Height, bitmap.ImageAttr)
				}
			}
			else if (c = 3)
			{
				if (params[1].__Class = "Gdip.Bitmap")
				{
					bitmap := params[1]
					E := this._DrawImage(this.pGraphics, bitmap.Pointer, params[2].X, params[2].Y, params[3].Width, params[3].Height, 0, 0, bitmap.Width, bitmap.Height, bitmap.ImageAttr)
				}
				else
				{
					bitmap := params[2]
					E := this._DrawImage(params[1], bitmap.Pointer, params[3].X, params[3].Y, bitmap.Width, bitmap.Height, 0, 0, bitmap.Width, bitmap.Height, bitmap.ImageAttr)
				}
			}
			else if (c = 4)
			{
				bitmap := params[2]
				E := this._DrawImage(params[1], bitmap.Pointer, params[3].X, params[3].Y, params[4].Width, params[4].Height, 0, 0, bitmap.Width, bitmap.Height, bitmap.ImageAttr)
			}
			else if (c = 5)
			{
				bitmap := params[1]
				E := this._DrawImage(this.pGraphics, bitmap.Pointer, params[2].X, params[2].Y, params[3].Width, params[3].Height, params[4].X, params[4].Y, params[5].Width, params[5].Height, bitmap.ImageAttr)
			}
			else
				throw "Incorrect number of parameters for Object.DrawImage()"
			return E
		}
		
		_DrawImage(pGraphics, pBitmap, dx, dy, dw, dh, sx, sy, sw, sh, imageAttr=0)
		{
			E := DllCall("gdiplus\GdipDrawImageRectRect", "uptr", pGraphics, "uptr", pBitmap
						, "float", dx, "float", dy, "float", dw, "float", dh
						, "float", sx, "float", sy, "float", sw, "float", sh
						, "int", 2, "uptr", imageAttr, "uptr", 0, "uptr", 0)
			return E
		}
				
		SetImageAttributesColorMatrix(matrix)
		{
			VarSetCapacity(colorMatrix, 100, 0)
			loop 5
			{
				i := A_Index
				loop 5
				{
					NumPut(matrix[i, A_Index], colorMatrix, ((i - 1) * 20) + ((A_Index - 1) * 4), "float")
				}
			}
			
			DllCall("gdiplus\GdipCreateImageAttributes", "uptr*", imageAttr)
			DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "uptr", imageAttr, "int", 1, "int", 1, "uptr", &colorMatrix, "uptr", 0, "int", 0)
			return imageAttr
		}
		
		DisposeImageAttributes(imageAttr)
		{
			return DllCall("gdiplus\GdipDisposeImageAttributes", "uptr", imageAttr)
		}
		
		SetClipRegion(region, combineMode=0)
		{
			return this._SetClipRegion(this.pGraphics, region, combineMode)
		}
		
		_SetClipRegion(pGraphics, region, combineMode=0)
		{
			return DllCall("gdiplus\GdipSetClipRegion", "uptr", pGraphics, "uptr", region, "int", combineMode)
		}
		
		SetClipRect(x, y, w, h, combineMode=0)
		{
			return this._SetClipRect(this.pGraphics, x, y, w, h, combineMode)
		}
		
		; Replace = 0
		; Intersect = 1
		; Union = 2
		; Xor = 3
		; Exclude = 4
		; Complement = 5
		_SetClipRect(pGraphics, x, y, w, h, combineMode=0)
		{
		   return DllCall("gdiplus\GdipSetClipRect", "uptr", pGraphics, "float", x, "float", y, "float", w, "float", h, "int", combineMode)
		}
		
		GetClipRegion()
		{
			return this._GetClipRegion(this.pGraphics)
		}
	
		/*
		CreateRoundRectRgn(point1, point2, radius)
		{
			return DllCall("CreateRoundRectRgn", "int", point1.X, "int", point1.Y, "int", point2.X, "int", point2.Y, "int", r, "int", r)
		}
		*/
		
		_GetClipRegion(pGraphics)
		{
			region := this.CreateRegion()
			DllCall("gdiplus\GdipGetClip", "uptr", pGraphics, "uint*", region)
			return region
		}
		
		FillRegion(pGraphics, pBrush, region)
		{
			return DllCall("gdiplus\GdipFillRegion", "uptr", pGraphics, "uptr", pBrush, "uptr", region)
		}
		
		FillPath(pGraphics, pBrush, path)
		{
			return DllCall("gdiplus\GdipFillPath", "uptr", pGraphics, "uptr", pBrush, "uptr", path)
		}
		
		DrawPath(pGraphics, pPen, path)
		{
			return DllCall("gdiplus\GdipDrawPath", "uptr", pGraphics, "uptr", pPen, "uptr", path)
		}
		
		; Alternate = 0
		; Winding = 1
		CreatePath(brushMode=0)
		{
			DllCall("gdiplus\GdipCreatePath", "int", brushMode, "uptr*", path1)
			return path1
		}
		
		DeletePath(path)
		{
			return DllCall("gdiplus\GdipDeletePath", "uptr", path)
		}
		
		ClosePathFigure(path)
		{
			return DllCall("gdiplus\GdipClosePathFigure", "uptr", path)
		}
		
		AddPathRectangle(path, x, y, w, h)
		{
			return DllCall("gdiplus\GdipAddPathRectangle", "uptr", path, "float", x, "float", y, "float", w, "float", h)
		}
		
		AddPathEllipse(path, x, y, w, h)
		{
			return DllCall("gdiplus\GdipAddPathEllipse", "uptr", path, "float", x, "float", y, "float", w, "float", h)
		}
		
		AddPathArc(path, x, y, w, h, startAngle, sweepAngle)
		{
			return DllCall("gdiplus\GdipAddPathArc", "uptr", path, "float", x, "float", y, "float", w, "float", h, "float", startAngle, "float", sweepAngle)
		}
		
		AddPathPie(path, x, y, w, h, startAngle, sweepAngle)
		{
			return DllCall("gdiplus\GdipAddPathPie", "uptr", path, "float", x, "float", y, "float", w, "float", h, "float", startAngle, "float", sweepAngle)
		}
		
		AddPathLine(path, x1, y1, x2, y2)
		{
			return DllCall("gdiplus\GdipAddPathLine", "uptr", path, "float", x1, "float", y1, "float", x2, "float", y2)
		}
		
		CreateRegion()
		{
			DllCall("gdiplus\GdipCreateRegion", "uint*", region)
			return region
		}
		
		DeleteRegion(region)
		{
			return DllCall("gdiplus\GdipDeleteRegion", "uptr", region)
		}
		
		Clear()
		{
			return this._GraphicsClear(this.pGraphics)
		}
		
		_GraphicsClear(pGraphics, ARGB=0x00ffffff)
		{
			return DllCall("gdiplus\GdipGraphicsClear", "uptr", pGraphics, "int", ARGB)
		}
	}
}