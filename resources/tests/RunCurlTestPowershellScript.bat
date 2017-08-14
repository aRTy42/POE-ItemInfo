SET workDir=%~dp0
start powershell -noprofile -command "&{ start-process powershell -ArgumentList '-noprofile -executionpolicy remotesigned -file %workDir%\curl_test.ps1' -verb RunAs}"