:: EDIT variables if you need to bypass cloudflare (user agent and cookies are needed)
:: http://www.wikihow.com/View-Cookies -> look for poe.trade cookies (__cfduid and cf_clearance values)
:: Examples (no quotation marks, no spaces in front of the variable values)
:: SET cfduid=d411cdb0dd67231fb45f4bb4df8e2e3c91500243215
:: SET cfClearance=sasdasdjdfsgdf

@echo off
SET useragent=Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36
SET cfduid=
SET cfClearance=

SET workDir=%~dp0
SET outDir="%workDir%tempOutput"
SET outFile="%workDir%tempOutput\outresult.txt"
if not exist %outDir% mkdir %outDir%
del %outDir%\outresult.txt
cd %workDir%
cd ..\..
cd lib

@echo on
echo(
"%cd%\curl.exe" -ILks -H "User-Agent: %useragent%" -H "Cookie: __cfduid= %cfduid%; cf_clearance= %cfClearance%" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "Accept-Encoding:gzip, deflate" -H "Accept-Language:de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4" -H "Connection:keep-alive" -H "Host:poe.trade" -H "Upgrade-Insecure-Requests:1" "http://poe.trade" >> %outFile%
