@echo off
setlocal EnableDelayedExpansion & set "number=%errorlevel%"

rem Convert a 32-bits signed integer into 8 hexadecimal digits
rem If no value is given in the parameter, it takes the current ERRORLEVEL
rem The parameter can be a SET /A arithmetic expression

set "hexDigit=0123456789abcdef"
if "%~1" neq "" set /A "number=(%~1)"
set /A "sign=(number>>28)&8, number&=0x7FFFFFFF"
set "hex="
for /L %%i in (1,1,8) do (
   set /A "fourBits=(%%i&sign)+number%%16, number/=16"
   for %%h in (!fourBits!) do set "hex=!hexDigit:~%%h,1!!hex!"
)
echo %hex%
exit /B
