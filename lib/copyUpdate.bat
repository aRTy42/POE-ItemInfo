echo off

set updateScriptPath=%1
set installPath=%2
set installFolder=%3
set tempInstallPath=%4
set tempInstallFolder=%5
set debug=%6
set robocopyExe=%SystemRoot%\System32\robocopy.exe
set findStrExe=%SystemRoot%\System32\findstr.exe

if %%debug EQU 1 (
	if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
)

if not exist %updateScriptPath% (
	dir /b /a %installPath%"\*" | >nul %findStrExe% "^" && (set extractedFilesExist=1) || (set extractedFilesExist=0)
	if %%extractedFilesExist EQU 0 (
		set error="Folder with extracted update files is empty."
		set errorL=20
	) else (
		set error="Folder with extracted update files does not exist."
		set errorL=19
	)
	goto EndScript
)

:: create temporary install folder 
:: if the installation of new files fails we don't want to have the script deleted completely
if exist %tempInstallPath% (
	rd /s /q %tempInstallPath%
	if exist %tempInstallPath% rd /s /q %tempInstallPath% || rem
	if exist %tempInstallPath% (
		echo.
		echo Executed command: rd /s /q %tempInstallPath%
		echo Failed to remove/clear temporary installation folder. 
		echo.
	)
)
mkdir %tempInstallPath%

if not exist %tempInstallPath% (
	set error="Failed to create temporary install folder. Cancelled update."
	set errorL=18
	goto EndScript
)

:: copy new script files to temp install directory
:: https://ss64.com/nt/robocopy-exit.html
echo Executing command: %robocopyExe% %updateScriptPath% %tempInstallPath% /s /NFL /NDL /NJH /NJS /nc /np
%robocopyExe% %updateScriptPath% %tempInstallPath% /s /NFL /NDL /NJH /NJS /nc /np 
if %ERRORLEVEL% EQU 16 set errorL=%ERRORLEVEL% & set error="***FATAL ERROR***" & goto EndScript
if %ERRORLEVEL% EQU 15 set errorL=%ERRORLEVEL% & set error="OKCOPY + FAIL + MISMATCHES + XTRA" & goto EndScript
if %ERRORLEVEL% EQU 14 set errorL=%ERRORLEVEL% & set error="FAIL + MISMATCHES + XTRA" & goto EndScript
if %ERRORLEVEL% EQU 13 set errorL=%ERRORLEVEL% & set error="OKCOPY + FAIL + MISMATCHES" & goto EndScript
if %ERRORLEVEL% EQU 12 set errorL=%ERRORLEVEL% & set error="FAIL + MISMATCHES" & goto EndScript
if %ERRORLEVEL% EQU 11 set errorL=%ERRORLEVEL% & set error="OKCOPY + FAIL + XTRA" & goto EndScript
if %ERRORLEVEL% EQU 10 set errorL=%ERRORLEVEL% & set error="FAIL + XTRA" & goto EndScript
if %ERRORLEVEL% EQU 9 set errorL=%ERRORLEVEL% & set error="OKCOPY + FAIL" & goto EndScript
if %ERRORLEVEL% EQU 8 set errorL=%ERRORLEVEL% & set error="FAIL" & goto EndScript
if %ERRORLEVEL% EQU 7 set errorL=%ERRORLEVEL% & set error="OKCOPY + MISMATCHES + XTRA" & goto EndScript
if %ERRORLEVEL% EQU 6 set errorL=%ERRORLEVEL% & set error="MISMATCHES + XTRA" & goto EndScript
if %ERRORLEVEL% EQU 5 set errorL=%ERRORLEVEL% & set error="OKCOPY + MISMATCHES" & goto EndScript
if %ERRORLEVEL% EQU 4 set errorL=%ERRORLEVEL% & set error="MISMATCHES" & goto EndScript
if %ERRORLEVEL% EQU 3 set errorL=%ERRORLEVEL% & set error="OKCOPY + XTRA" & goto EndScript
if %ERRORLEVEL% EQU 2 set errorL=%ERRORLEVEL% & set error="XTRA" & goto EndScript
if %ERRORLEVEL% EQU 1 set errorL=%ERRORLEVEL% & set error="OKCOPY" & goto SwapInstalls
if %ERRORLEVEL% EQU 0 set errorL=%ERRORLEVEL% & set error="No Change" & goto EndScript

:SwapInstalls
:: delete install folder (old script) and rename temp install folder to install folder
if exist %installPath% (
	rd /s /q %installPath%
	if exist %installPath% rd /s /q %installPath% || rem
	if exist %installPath% (
		echo.
		echo executed command: rd /s /q %installPath%
		echo Failed to remove/clear installation folder. 
		echo.
	)
)

if exist %installPath% (
	dir /b /a %installPath%"\*" | >nul %findStrExe% "^" && (set clearInstallDir=0) || set clearInstallDir=1
) else (
	set clearInstallDir=1
)

if %clearInstallDir% EQU 1 (
	echo Executing command: %robocopyExe% %tempInstallPath% %installPath% /E /MOVE /NFL /NDL /NJH /nc /np
	%robocopyExe% %tempInstallPath% %installPath% /E /MOVE /NFL /NDL /NJH /nc /np
	if %ERRORLEVEL% NEQ 1 (
		echo Swap directories, rename/move temp folder to install folder:
		echo. robocopy ERRORLEVEL: %ERRORLEVEL%
		echo. temp               : %tempInstallPath%
		echo. install            : %installPath%
		echo. 
		set error2="Failed to rename temp install folder to install folder. Using temp install folder to run the script."
		set errorL2=17
		goto EndScript
	) else (
		set error2="OKCOPY"
		set errorL2=%ERRORLEVEL%
		if exist %tempInstallPath% (
			rd /s /q %tempInstallPath%
			if exist %tempInstallPath% rd /s /q %tempInstallPath% || rem
			if exist %tempInstallPath% (
				echo.
				echo Executed command: rd /s /q %tempInstallPath%
				echo Cleanup: Failed to clear temporary installation folder. 
				echo.
			)
		)
	)
) else (
	set error2="Failed to rename temp install folder to install folder. Using temp install folder to run the script."
	set errorL2=17
	goto EndScript
)
goto EndScript

:EndScript
:: clean directory again
if exist %updateScriptPath% (
	for /f %%i in ('rd /s /q %updateScriptPath%') do set test=%%i
)
echo - Copy "update files" to "temp install folder": 
echo.  - Error/Exit Code: %error%
echo.  - Errorlevel: %errorL%
echo. 
echo - Copy "temp install folder" to "install folder":
echo.  - Error/Exit Code: %error2%
echo.  - Errorlevel: %errorL2%
echo. 

:: write exit code to file
echo %errorL% >exitCode.txt

::pause