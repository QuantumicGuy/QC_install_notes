@echo off
(
echo 100
echo 2
echo 1
echo;
echo 0
echo q
)> inputstream.txt

setlocal enabledelayedexpansion
for /r %%i in (*.fchk) do (
echo;
echo Entering Path: [%%i]
Multiwfn %%i < inputstream.txt > nul
move %%~ni.pdb %%~pi > nul
if !errorlevel!==0 (
echo Conversion of %%~ni.fchk to %%~ni.pdb finished at !date! !time!) else (
echo Warning: Conversion of %%~ni.fchk to %%~ni.pdb failed at !date! !time!)
)
del inputstream.txt 
echo;
echo;
pause