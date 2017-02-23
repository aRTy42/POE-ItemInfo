; WinHttpRequest.ahk
;	v1.03 (2016-01-18) - 增加“加载 gzip.dll 失败”提示，防止忘记复制 gzip.dll 到脚本目录。
; 	v1.02 (2015-12-26) - 修复在 XP 系统中解压 gzip 数据失败的问题。
; 	v1.01 (2015-12-07)

/*
	用法:
	WinHttpRequest( URL, ByRef In_POST__Out_Data="", ByRef In_Out_HEADERS="", Options="", ByRef Out_Headers_Obj)
	--------------------------------------------------------------------------------------------
	参数/parameter:
	URL               - 网址
	
	In_POST__Out_Data - POST数据/返回数据。Data / return data
	若该变量为空则进行 GET 请求，否则为 POST / If the variable is empty GET Request, otherwise POST
	
	In_Out_HEADERS    - 请求头/响应头（多个请求头用换行符分隔） / Request header / response header (multiple request head separated by newline)
	
	Options           - 选项（多个选项用换行符分隔） / Option (multiple options separated by newline)
	
	NO_AUTO_REDIRECT - 禁止自动重定向 / Disable automatic redirection
	Timeout: 秒钟 /seconds    - 超时（默认为 30 秒） / Timeout (default is 30 seconds)
	Proxy: IP:端口/Port   - 代理 / proxy
	Codepage: XXX	 - 代码页。例如 Codepage: 65001
	Charset: 编码 / Coding	 - 字符集。例如 Charset: UTF-8
	SaveAs: 文件名 / Filename  - 下载到文件 / Download to file
	Compressed       - 向网站请求 GZIP 压缩数据，并解压。 / Ask the site to request GZIP to compress the data and extract it.
	（需要文件 / Need documentation gzip.dll -- http://pan.baidu.com/s/1pKqKTzt）
	Method: 请求方法 - 可以为 Request method - can be GET/POST/HEAD 其中的一个。 one of them
	这个选项可以省略，除非你需要 HEAD 请求，或者 POST 数据为空时强制使用 POST。
	This option can be omitted unless you need it HEAD Request, or POST data is forced to use POST.
	--------------------------------------------------------------------------------------------
	返回 / Return:
	成功返回 / Successful return -1, 超时返回 / Overtime return (timeout?) 0, 无响应则返回为空 / No response returns empty
	--------------------------------------------------------------------------------------------
	清除 Cookies 的方法: Clear Cookies
	WinHttpRequest( [] )
	--------------------------------------------------------------------------------------------
	示例 Example:
	例1 - GET
	url := "https://www.baidu.com/"
	
	WinHttpRequest(url, ioData := "", ioHdr := "")
			; 也可以简单写成 Can also be simply written WinHttpRequest(url, ioData)，
			; 但是一定要确保 But be sure to make sure ioData Is empty, or is to POST, not GET
	
	MsgBox, % ioData
	
	例2 - POST
	url := "https://www.baidu.com/"
	postData := "key=value&key2=value2"
	reqHeaders =
			(LTrim
				User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:42.0) Gecko/20100101 Firefox/42.0
				Referer: https://www.baidu.com
			)
	WinHttpRequest(url, ioData := postData, ioHdr := reqHeaders)
	
	; Usage is similar to HTTPRequest (by VxE),
	; Please visit the HTTPRequest page (http://goo.gl/CcnNOY) for more details.
	Supported Options:
	; 	NO_AUTO_REDIRECT
	; 	Timeout: <Seconds>
	; 	Proxy: <IP:Port>
	; 	Codepage: <CPnnn>	- e.g. "Codepage: 65001"
	; 	Charset: <Encoding>	- e.g. "Charset: UTF-8"
	; 	SaveAs: <FileName>
	; Return:
	; 	Success = -1, Timeout = 0, No response = Empty String
	; 
	; How to clear cookie:
	; 	WinHttpRequest( [] )
	; 
	; ChangeLog:
	; 	2015-4-25 - Added option "Method: HEAD"
	; 	2014-9-7  - Fixed a bug in "Charset:"
	; 	2014-7-11 - Fixed a bug in "Charset:"
*/

WinHttpRequest( URL, ByRef In_POST__Out_Data="", ByRef In_Out_HEADERS="", Options="" , ByRef Out_Headers_Obj = "")
{
	static nothing := ComObjError(0) ; 禁用 COM 错误提示 / Disable COM error messages
	static oHTTP   := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	static oADO    := ComObjCreate("adodb.stream")
	
	If IsObject(URL) ; 如果第一个参数是数组，则重新创建 WinHttp 对象，以便清除 Cookies / If the first argument is an array, re-create the WinHttp object to clear Cookies
		Return oHTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	
	; Clear cookie
	If (In_POST__Out_Data != "") || InStr(Options, "Method: POST")
		oHTTP.Open("POST", URL, True)
	Else If InStr(Options, "Method: HEAD")
		oHTTP.Open("HEAD", URL, True)
	Else
		oHTTP.Open("GET", URL, True)
	
	; POST or GET
	If In_Out_HEADERS
	{
		In_Out_HEADERS := Trim(In_Out_HEADERS, " `t`r`n")
		Loop, Parse, In_Out_HEADERS, `n, `r
		{
			If !( _pos := InStr(A_LoopField, ":") )
				Continue
			
			Header_Name  := SubStr(A_LoopField, 1, _pos-1)
			Header_Value := SubStr(A_LoopField, _pos+1)
			
			If (  Trim(Header_Value) != ""  )
				oHTTP.SetRequestHeader( Header_Name, Header_Value )
		}
	}
	
	If (In_POST__Out_Data != "") && !InStr(In_Out_HEADERS, "Content-Type:")
		oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	
	; 解析选项 / Resolution options
	If Options
	{
		Loop, Parse, Options, `n, `r
		{
			If ( _pos := InStr(A_LoopField, "Timeout:") )
				Timeout := SubStr(A_LoopField, _pos+8)
			Else If ( _pos := InStr(A_LoopField, "Proxy:") )
				oHTTP.SetProxy( 2, SubStr(A_LoopField, _pos+6) )
			Else If ( _pos := InStr(A_LoopField, "Codepage:") )
				oHTTP.Option(2) := SubStr(A_LoopField, _pos+9)
		}
		
		oHTTP.Option(6) := InStr(Options, "NO_AUTO_REDIRECT") ? 0 : 1
		
		If InStr(Options, "Compressed")
			oHTTP.SetRequestHeader("Accept-Encoding", "gzip, deflate")
	}
	
	If (Timeout > 30)
		oHTTP.SetTimeouts(0, 60000, 30000, Timeout * 1000)
	
	; Send
	oHTTP.Send(In_POST__Out_Data)
	retCode := oHTTP.WaitForResponse(Timeout ? Timeout : -1)	; EMPTY = no response

	; 处理返回结果 / Processing returns the result
	If InStr(Options, "Compressed")
	&& (oHTTP.GetResponseHeader("Content-Encoding") = "gzip") {
		body := oHTTP.ResponseBody
		size := body.MaxIndex() + 1
		
		VarSetCapacity(data, size)
		DllCall("oleaut32\SafeArrayAccessData", "ptr", ComObjValue(body), "ptr*", pdata)
		DllCall("RtlMoveMemory", "ptr", &data, "ptr", pdata, "ptr", size)
		DllCall("oleaut32\SafeArrayUnaccessData", "ptr", ComObjValue(body))

		size := GZIP_DecompressBuffer(data, size)

		; 不可以直接 ComObjValue(oHTTP.ResponseBody)！
		; 需要先将 oHTTP.ResponseBody 赋值给变量，如 body，然后再 ComObjValue(body)。
		; 直接 ComObjValue(oHTTP.ResponseBody) 会导致在 XP 系统无法获取 gzip 文件的未压缩大小。
		
		If InStr(Options, "SaveAs:") {
			RegExMatch(Options, "i)SaveAs:[ \t]*\K[^\r\n]+", SavePath)
			FileOpen(SavePath, "w").RawWrite(&data, size)
		} Else {
			RegExMatch(Options, "i)Charset:[ \t]*\K[\w-]+", Encoding)
			In_POST__Out_Data := StrGet(&data, size, Encoding)
		}
	}
	Else If InStr(Options, "SaveAs:")
	{
		RegExMatch(Options, "i)SaveAs:[ \t]*\K[^\r\n]+", SavePath)
		
		oADO.Type := 1 ; adTypeBinary = 1
		oADO.Open()
		oADO.Write( oHTTP.ResponseBody )
		oADO.SaveToFile( SavePath, 2 )
		oADO.Close()
		
		In_POST__Out_Data := ""
	}
	Else If InStr(Options, "Charset:")
	{
		RegExMatch(Options, "i)Charset:[ \t]*\K[\w-]+", Encoding)
		
		oADO.Type     := 1 ; adTypeBinary = 1
		oADO.Mode     := 3 ; adModeReadWrite = 3
		oADO.Open()
		oADO.Write( oHTTP.ResponseBody )
		oADO.Position := 0
		oADO.Type     := 2 ; adTypeText = 2
		oADO.Charset  := Encoding
		In_POST__Out_Data := IsByRef(In_POST__Out_Data) ? oADO.ReadText() : ""
		oADO.Close()
	}
	Else
		In_POST__Out_Data := IsByRef(In_POST__Out_Data) ? oHTTP.ResponseText : ""
	
	
	Out_Headers_Obj := {} 
	var := oHTTP.GetAllResponseHeaders()
	Loop, Parse, var, `n, `r 
	{
		RegExMatch(A_LoopField, "i)(.*?):(.*)", match)
		Out_Headers_Obj[Trim(match1)] := Trim(match2)
	}

	Out_Headers_Obj.Status 		:= oHTTP.Status
	Out_Headers_Obj.StatusText 	:= oHTTP.StatusText
	
	In_Out_HEADERS := "HTTP/1.1 " oHTTP.Status " " oHTTP.StatusText "`n" oHTTP.GetAllResponseHeaders()
	
	Return retCode ; 成功返回 -1, 超时返回 0, 无响应则返回为空
}



GZIP_DecompressBuffer( ByRef var, nSz ) { ; 'Microsoft GZIP Compression DLL' SKAN 20-Sep-2010
; Decompress routine for 'no-name single file GZIP', available in process memory.
; Forum post :  www.autohotkey.com/forum/viewtopic.php?p=384875#384875
; Modified by Lexikos 25-Apr-2015 to accept the data size as a parameter.
	
; Modified version by tmplinshi
	static hModule, _
	static GZIP_InitDecompression, GZIP_CreateDecompression, GZIP_Decompress
     , GZIP_DestroyDecompression, GZIP_DeInitDecompression

	If !hModule {
		If !hModule := DllCall("LoadLibrary", "Str", "gzip.dll", "Ptr")		
		;If !hModule := DllCall(A_ScriptDir "\lib\gzip.dll", "Str", "gzip.dll", "Ptr")
		{			
			MsgBox % "Error: Loading gzip.dll failed! Exiting App."
			ExitApp
		}
		For k, v in ["InitDecompression","CreateDecompression","Decompress","DestroyDecompression","DeInitDecompression"]
			GZIP_%v% := DllCall("GetProcAddress", Ptr, hModule, "AStr", v, "Ptr")
		
		_ := { base: {__Delete: "GZIP_DecompressBuffer"} }
	}
	If !_ 
		Return DllCall("FreeLibrary", "Ptr", hModule)
	
	vSz :=  NumGet( var,nsz-4 ), VarSetCapacity( out,vsz,0 )
	DllCall( GZIP_InitDecompression )
	DllCall( GZIP_CreateDecompression, UIntP,CTX, UInt,1 )
	If ( DllCall( GZIP_Decompress, UInt,CTX, UInt,&var, UInt,nsz, UInt,&Out, UInt,vsz
    , UIntP,input_used, UIntP,output_used ) = 0 && ( Ok := ( output_used = vsz ) ) )
		VarSetCapacity( var,64 ), VarSetCapacity( var,0 ), VarSetCapacity( var,vsz,32 )
    , DllCall( "RtlMoveMemory", UInt,&var, UInt,&out, UInt,vsz )
	DllCall( GZIP_DestroyDecompression, UInt,CTX ),  DllCall( GZIP_DeInitDecompression )
	Return Ok ? vsz : 0
}