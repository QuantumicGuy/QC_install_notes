@echo off
(
echo oi
echo orca.inp
echo 8
echo q
)> inputstream.txt

setlocal enabledelayedexpansion
for /r %%i in (*.gjf) do (
echo;
echo Entering Path: [%%i]
Multiwfn %%i < inputstream.txt > nul
move orca.inp %%~pi > nul
rename %%~pi\orca.inp %%~ni.inp
if !errorlevel!==0 (
echo Conversion of %%~ni.gjf to %%~ni.inp finished at !date! !time!) else (
echo Warning: Conversion of %%~ni.gjf to %%~ni.inp failed at !date! !time!)
)
del inputstream.txt 
echo;
echo;
pause