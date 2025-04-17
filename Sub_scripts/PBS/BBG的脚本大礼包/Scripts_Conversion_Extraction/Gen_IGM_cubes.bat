@echo off
(
echo 20
echo 10
echo 2
echo 1-282
echo 283-321
echo 3
echo 3
echo 0
echo 0
echo q
)> inputstream.txt

setlocal enabledelayedexpansion
for /r %%i in (*.xyz) do (
echo;
echo Entering Path: [%%i]
Multiwfn %%i < inputstream.txt > nul
del dg_intra.cub > nul
del dg.cub > nul
rename dg_inter.cub %%~ni_dg_inter.cub
rename sl2r.cub %%~ni_sl2r.cub
move %%~ni_dg_inter.cub %%~pi > nul
move %%~ni_sl2r.cub %%~pi > nul
if !errorlevel!==0 (
echo Generation of IGM cube files finished at !date! !time!) else (
echo Warning: Generation of IGM cube files failed at !date! !time!)
)
del inputstream.txt 
echo;
echo;
pause