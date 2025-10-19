@echo off
setlocal EnableDelayedExpansion


rem xxHash32 - Copyright (C) 2012-2023 Yann Collet
rem https://github.com/Cyan4973/xxHash

rem xxHash32.bat translation to Windows Batch file by Antonio Perez Ayala aka Aacini
rem Based on a simplified C version of original xxh32 code also written by Aacini
rem antonio.perez.ayala@gmail.com
rem https://www.apaacini.com


rem Definition of auxiliary variables and "functions" (macros)

rem UNSIGNED shift right
set "shr(val,bits)=v=(val),^!shr2(bits)"
set "shr2(bits)=b=(bits),(  ( (v&0x7FFFFFFF) >> b ) | ( ( (v>>31) & 1 ) << (31 - b) )  )"
rem Example: set /A "result=(%shr(val,bits):val=h32%:bits=15!)"    // <- Outmost parentheses mandatory!

rem Rotate left (circular shift to left, use an *unsigned* shift right)
set "rotl(val,bits)=v=(val),^!rotl2(bits)"
set "rotl2(bits)=b=(bits),(   (v << b) | (  ( (v&0x7FFFFFFF) >> (32-b) ) | ( ( (v>>31) & 1 ) << (b-1) )  )   )"
rem Example: set /A "result=(%rotl(val,bits):val=v1%:bits=13!)"    // <- Outmost parentheses mandatory!

rem UNSIGNED 32-bit multiplication
set "mul(A,B)=XH=((A)>>16)&0xFFFF,XL=(A)&0xFFFF,^!mul2(B)"
set "mul2(B)=YH=((B)>>16)&0xFFFF,YL=(B)&0xFFFF,((XH*YL+XL*YH)<<16)+XL*YL"
rem Example: set /A "result=(%mul(A,B):A=d%:B=PRIME32_3!)"    // <- Outmost parentheses mandatory!

rem Auxiliary variables to read 1 byte as uint8
set "ascii= ^!"#$%%^&'()*+,-./0123456789:;^<=^>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^^^^_`abcdefghijklmnopqrstuvwxyz{^|}~⌂"
for /L %%i in (32,1,127) do set "u8[!ascii:~0,1!]=%%i" & set "ascii=!ascii:~1!"
set "lowcase=abcdefghijklmnopqrstuvwxyz"
set "special=/=61 /^!33 /*42 /:58 /~126"

rem Auxiliary variables for "syntactic sugar"
set "set /A=for /F "tokens=1-5 delims==(,) " %%a in ("
set "end/A=) do call :%%b %%a %%c %%d %%e"

rem xxHash32 Prime Numbers
set /A "PRIME32_1=0x9E3779B1, PRIME32_2=0x85EBCA77, PRIME32_3=0xC2B2AE3D, PRIME32_4=0x27D4EB2F, PRIME32_5=0x165667B1"

rem Initialization complete,
goto Main


rem Definition of auxiliary subroutines

rem Read 4 bytes as uint32 little-endian
rem return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
:read_u32le u32le = input, pos
rem         %1      %2     %3
set /A "posPlus3=%3+3, %1=0"
for /L %%p in (%posPlus3%,-1,%3) do (
    %set /A% "byte = read_u8(input,%%p)" %end/A%
    set /A "%1=(%1<<8)|byte"
)
exit /B


rem Read 1 byte as uint8
:read_u8 u8 = input, pos
rem      %1   %2     %3
rem All this stuff is just to get around the limitations in special characters management
set "%1=94" & rem *Very* special case for "^" caret
for /F "eol=^ delims=" %%c in ("!input:~%3,1!") do (
   set "test=!special:*/%%c=!"
   if not "!test!" == "!special!" (
      for /F "delims== " %%n in ("!test!") do set "%1=%%n"
   ) else (
      set "%1=!u8[%%c]!"
      if not "!lowcase:%%c=%%c!" == "%lowcase%" set /A "%1-=32"
   )
)
exit /B


rem xxHash 32 subroutine
:xxh32	h32 = input, len, seed  (	//	xxh32(const char* input, int len, uint32_t seed) {
rem     %1    %2     %3   %4

    set "input=!%2!"
    set /A "len=%3, seed=%4"

    set /A "blocks16=len/16, rest=len%%16, pos=0"

    rem // XXH32 PROCESS BLOCKS OF 16 BYTES
    if %blocks16% gtr 0 (

        set /A "v1 = seed + PRIME32_1 + PRIME32_2, v2 = seed + PRIME32_2, v3 = seed, v4 = seed - PRIME32_1"

        for /L %%i in (1; 1; %blocks16%) do (

            set /A "pos0=pos+0*4, pos1=pos+1*4, pos2=pos+2*4, pos3=pos+3*4"

            %set /A% "d = read_u32le(input,!pos0!)" %end/A%
            set /A "v1 += (%mul(A,B):A=d%:B=PRIME32_2!)"
            set /A "v1 = (%rotl(val,bits):val=v1%:bits=13!)"
            set /A "v1 = (%mul(A,B):A=v1%:B=PRIME32_1!)"

            %set /A% "d = read_u32le(input,!pos1!)" %end/A%
            set /A "v2 += (%mul(A,B):A=d%:B=PRIME32_2!)"
            set /A "v2 = (%rotl(val,bits):val=v2%:bits=13!)"
            set /A "v2 = (%mul(A,B):A=v2%:B=PRIME32_1!)"

            %set /A% "d = read_u32le(input,!pos2!)" %end/A%
            set /A "v3 += (%mul(A,B):A=d%:B=PRIME32_2!)"
            set /A "v3 = (%rotl(val,bits):val=v3%:bits=13!)"
            set /A "v3 = (%mul(A,B):A=v3%:B=PRIME32_1!)"

            %set /A% "d = read_u32le(input,!pos3!)" %end/A%
            set /A "v4 += (%mul(A,B):A=d%:B=PRIME32_2!)"
            set /A "v4 = (%rotl(val,bits):val=v4%:bits=13!)"
            set /A "v4 = (%mul(A,B):A=v4%:B=PRIME32_1!)"

            set /A pos += 16

        )

        set /A "h32 = (%rotl(val,bits):val=v1%:bits=1!) + (%rotl(val,bits):val=v2%:bits=7!) + (%rotl(val,bits):val=v3%:bits=12!) + (%rotl(val,bits):val=v4%:bits=18!)"

    ) else (

        rem // If len less 16: initialize with seed + PRIME32_5
        set /A "h32 = seed + PRIME32_5"

    )

    set /A h32 += len

    rem // XXH32 PROCESS BLOCKS OF 4 BYTES
    set /A blocks4 = rest / 4
    for /L %%i in (1; 1; %blocks4%) do (
        %set /A% "d = read_u32le(input,!pos!)" %end/A%
        set /A "h32 += (%mul(A,B):A=d%:B=PRIME32_3!)"
        set /A "h32 = (%rotl(val,bits):val=h32%:bits=17!)"
        set /A "h32 = (%mul(A,B):A=h32%:B=PRIME32_4!)"
        set /A pos += 4
    )

    rem // XXH32 PROCESS BLOCKS OF 1 BYTE
    set /A blocks1 = rest %% 4
    for /L %%i in (1; 1; %blocks1%) do (
        %set /A% "d = read_u8(input,!pos!)" %end/A%
        set /A "h32 += (%mul(A,B):A=d%:B=PRIME32_5!)"
        set /A "h32 = (%rotl(val,bits):val=h32%:bits=11!)"
        set /A "h32 = (%mul(A,B):A=h32%:B=PRIME32_1!)"
        set /A pos += 1
    )

    rem // Avalanche
    set /A "h32 ^^= (%shr(val,bits):val=h32%:bits=15!)"
    set /A "h32   = (%mul(A,B):A=h32%:B=PRIME32_2!)"
    set /A "h32 ^^= (%shr(val,bits):val=h32%:bits=13!)"
    set /A "h32   = (%mul(A,B):A=h32%:B=PRIME32_3!)"
    set /A "h32 ^^= (%shr(val,bits):val=h32%:bits=16!)"

    set /A %1 = h32
    exit /B

)



:strLen len = str
set "str=0!%2!"
set /A "b=0x80, %1=0"
for /L %%# in (1,1,8) do for %%b in (!b!) do (
   if not "!str:~%%b!" == "" set "str=!str:~%%b!" & set /A %1+=b
   set /A "b>>=1"
)
exit /B



:intToHex hex = int
set "hexDigit=0123456789ABCDEF"
set /A "number=%2, sign=(number>>28)&8, number&=0x7FFFFFFF"
set "%1="
for /L %%i in (1,1,8) do (
   set /A "fourBits=(%%i&sign)+number%%16, number/=16"
   for %%h in (!fourBits!) do set "%1=!hexDigit:~%%h,1!!%1!"
)
exit /B



:Main

set /P "string=String: "
if errorlevel 1 goto :EOF

%set /A% "len = strLen(string)" %end/A%
%set /A% "hash = xxh32(string,len,0)" %end/A%
%set /A% "hex = intToHex(hash)" %end/A%
echo xxh32:  %hex%
echo/

goto Main

