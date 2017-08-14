SET workDir=%~dp0
start powershell -noprofile -command "&{ start-process powershell -ArgumentList '-noprofile -file %workDir%\curl_test.ps1' -verb RunAs}"