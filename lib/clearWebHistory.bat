set /p "=* Internet Explorer... "<NUL
Taskkill /IM "iexplore.exe" /F

set IETemp=%LOCALAPPDATA%\Microsoft\Windows\Tempor~1
if exist "%IETemp%" (
	del /q /s /f "%IETemp%"
	rd /s /q "%IETemp%"
)

set Cookies=%APPDATA%\Microsoft\Windows\Cookies
if exist "%Cookies%" (
	pushd %Cookies%
	for /f "delims=" %%f in ('dir /b') do (
		findstr /m "poe\.trade" %%f
		if %errorlevel%==0 (
			del /q /s /f  %%f
		)	
	)
	popd
)

set Cookies=%LOCALAPPDATA%\Microsoft\Windows\INetCookies

if exist "%Cookies%" (
	pushd %Cookies%
	for /f "delims=" %%f in ('dir /b') do (
		findstr /m "poe\.trade" %%f
		if %errorlevel%==0 (
			del /q /s /f  %%f
		)	
	)
	popd
)

set Cookies="%LOCALAPPDATA%\Microsoft\Windows\INetCookies\Low"
if exist "%Cookies%" (
	pushd %Cookies%
	for /f "delims=" %%f in ('dir /b') do (
		findstr /m "poe\.trade" %%f
		if %errorlevel%==0 (
			del /q /s /f  %%f
		)	
	)
	popd
)

echo Done.

