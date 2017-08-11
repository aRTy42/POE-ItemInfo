<# 
	EDIT variables if you need to bypass cloudflare (user agent and cookies are needed)
	http://www.wikihow.com/View-Cookies -> look for poe.trade cookies (__cfduid and cf_clearance values)
	
	Examples:
	
	$cfduid = "d411cdb0dd67231fb45f4bb4df8e2e3c91500243215"
	$cfClearance = "sasdasdjdfsgdf"
#>
$error.clear()
$useragent = "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36"
$cfduid = ""
$cfClearance = ""

$workDir = split-path -parent $MyInvocation.MyCommand.Definition
$outDir = "$workDir\tempOutput"
$outFile = "$workDir\tempOutput\outresult.txt"

If(!(Test-Path $outDir)) {
	New-Item -ItemType Directory -Force -Path $outDir
}
If (Test-Path $outFile){
	Remove-Item $outFile
}

cd $workDir
cd ..\..
cd lib
$currentDir = Get-Location

[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-us'; & "$currentDir\curl.exe" -ILks -H "User-Agent: $useragent" -H "Cookie: __cfduid= $cfduid; cf_clearance= $cfClearance" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "Accept-Encoding:gzip, deflate" -H "Accept-Language:de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4" -H "Connection:keep-alive" -H "Host:poe.trade" -H "Upgrade-Insecure-Requests:1" "http://poe.trade" | Out-File $outFile

If($error) {
	$error | Add-Content $outFile
}

Invoke-Item $outFile