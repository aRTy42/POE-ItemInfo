set /p "=* Internet Explorer... "<NUL
Taskkill /IM "iexplore.exe" /F

set IETemp=%LOCALAPPDATA%\Microsoft\Windows\Tempor~1
if exist "%IETemp%" (
	del /q /s /f "%IETemp%"
	rd /s /q "%IETemp%"
)

set Cookies=%APPDATA%\Microsoft\Windows\Cookies
if exist "%Cookies%" (
	del /q /s /f "%Cookies%"
	rd /s /q "%Cookies%"
)

set Cookies=%LOCALAPPDATA%\Microsoft\Windows\INetCookies
if exist "%Cookies%" (
	del /q /s /f "%Cookies%"
	rd /s /q "%Cookies%"
)

set Cookies="%LOCALAPPDATA%\Microsoft\Windows\INetCookies\Low"
if exist "%Cookies%" (
	del /q /s /f "%Cookies%"
	rd /s /q "%Cookies%"
)

echo Done.
