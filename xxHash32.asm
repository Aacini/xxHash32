	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;									;
	;	xxHash32.asm - Antonio Perez Ayala aka Aacini			;
	;	antonio.perez.ayala@gmail.com					;
	;	https://www.apaacini.com/					;
	;									;
	;	Example of use of xxh32(input,len,seed) C compliant function	;
	;	contained in xxh32.obj file and written in assembler by Aacini	;
	;									;
	;	1- Install the MASM32 SDK from https://www.masm32.com		;
	;	2- Rename this file to xxHash32.asm (if not already)		;
	;	3- Assemble it using: buildc xxHash32 xxh32.obj			;
	;									;
	;	xxHash32.exe is created; run it for a brief on-screen help	;
	;	You must previously generated the xxh32.obj file		;
	;									;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	include		\masm32\include\masm32rt.inc

	option casemap :none	;case sensitive

.data

EOS	EQU	0
CR	EQU	13
LF	EQU	10
SPACE	EQU	' '
	;
usage	DB	"Generate xxHash32 values from strings  -  Antonio Perez Ayala aka Aacini",CR,LF,CR,LF
	DB	'xxHash32  [seed]  { "string" | variable | StdIn }',CR,LF,CR,LF
	DB	"    seed        Decimal 32-bit signed number.",CR,LF
	DB	'    "string"    String to process enclosed in quotes.',CR,LF
	DB	"    variable    Name of environment variable that contain the string.",CR,LF
	DB	'    StdIn       If Name is "StdIn", several strings are read from keyboard.',CR,LF,CR,LF
	DB	"The xxHash32 value is displayed in hexadecimal and returned in ERRORLEVEL.",CR,LF,CR,LF
	DB	"Example:",CR,LF
	DB	'    C:\> xxHash32.exe "xxHash - Extremely Fast Hash algorithm"',CR,LF
	DB	"    d75d048b",CR,LF
	DB	"    C:\> echo %errorlevel%",CR,LF
	DB	"    -681769845",CR,LF
	DB	"    C:\> IntToHex.bat",CR,LF
	DB	"    d75d048b",CR,LF,CR,LF
	DB	"If several lines are read from a redirected input file, the ERRORLEVEL is the",CR,LF
	DB	"xxHash32 of the hash values of all input lines. This value can serve as a",CR,LF
	DB	"simpler and shorter alternative for MD5 to check the integrity of simple files.",EOS
	;
seed		DD	0
result		DD	0
hexBuffer	DB	"12345678",EOS


.data?		;uninitialized data segment that don't takes space in the generated .exe

MAX_LEN		EQU	10*1024		;max lenght of lines read from StdIn
MAX_LINES	EQU	16*1024		;max number of lines read from StdIn
		;
buffer	DB	MAX_LEN DUP (?)		;buffer for line read
hashes	DD	MAX_LINES DUP (?)	;buffer to store xxh32 values for all lines read


.code


showResult:	;Show the xxHash32 value in 8 hexadecimal digits

	mov	edi, OFFSET hexBuffer	;EDI->hexBuffer
	mov	edx, result		;EDX=result
	mov	ecx, 4			;ECX=byte counter
	;
nextByte:
	rol	edx, 8			;shift high order (left) byte in DL
	mov	ah, dl			;AH=two hex digits in binary
	and	ah, 1111B		;AH=first hex digit
	mov	al, dl			;AL=two digits
	shr	al, 4			;AL=second hex digit
	;
	add	al, '0'			;convert 0..9 digits
	cmp	al, '9'			;digit ok?
	jle	SHORT @F		;yes: jump
	add	al, 'a'-'9'-1		;else: convert a..f digits
@@:
	add	ah, '0'			;the same for other hex digit
	cmp	ah, '9'
	jle	SHORT @F
	add	ah, 'a'-'9'-1
@@:
	mov	[edi], ax		;store two hex digits in buffer
	add	edi, 2			;advance pointer
	dec	ecx			;and repeat for
	jnz	SHORT nextByte		;- 4 bytes
	;
	invoke	crt_puts, OFFSET hexBuffer;show result in hex
	ret				;and return to caller


xxh32   PROTO   input:DWORD, len:DWORD, seed:DWORD	;uint32_t xxh32(const char* input, int len, uint32_t seed) {

Main	PROC

        invoke  GetCommandLine		;EAX -> Command Line
        mov     esi, eax		;ESI -> Command Line
	;
skipMyName:
	mov	al, [esi]		;load next char		|	lodsb
	inc	esi			;and advance pointer	|
	or	al, al			;line ends?
	jz	SHORT showUsage		;yes: jump
	cmp	al, SPACE		;my name ends?
	jne	SHORT skipMyName	;no: go back
	;
findFirstArg:
	mov	al, [esi]		;load next char		|	lodsb
	inc	esi			;and advance pointer	|
	or	al, al			;line ends?
	jz	SHORT showUsage		;yes: jump
	cmp	al, SPACE		;arg found?
	je	SHORT findFirstArg	;no: go back
	;
	cmp	WORD PTR [esi-1], '?/'	;arg is "/?"?
	jne	SHORT checkNumber	;no: continue
	;
showUsage:
	invoke	crt_puts, OFFSET usage	;show usage
	jmp	quit			;and quit

checkNumber:
	cmp	al, '-'			;is neg sign?
	je	SHORT @F		;yes: is number
	cmp	al, '0'			;below '0'?
	jb	SHORT checkString	;yes: no number
	cmp	al, '9'			;above '9'?
	ja	SHORT checkString	;yes: no number
	;
@@:
	dec	esi			;ESI->seed
	invoke	crt_atoi, esi		;EAX = atoi(seed)
	mov	seed, eax		;store seed
	jmp	SHORT skipMyName	;and go back to omit the seed

checkString:
	cmp	al, '"'			;arg is "string"?
	jne	SHORT checkStdIn	;no: continue
	;
	mov	ebx, esi		;EBX -> string"
	;
findStrEnd:
	mov	al, [esi]		;load next char		|	lodsb
	inc	esi			;and advance pointer	|
	or	al, al			;line ends?
	jz	SHORT @F		;yes: string ends
	cmp	al, '"'			;string ends?
	jne	SHORT findStrEnd	;no: go back
	;
@@:
	sub	esi, ebx		;ESI = string lenght + 1
	dec	esi			;Ok
	invoke	xxh32, ebx, esi, seed	;EAX = xxh32(string:DWORD, len:DWORD, seed:DWORD)
	jmp	showResultAndEnd	;and jump to end

checkStdIn:
	cmp	DWORD PTR [esi-1], "IdtS";arg is "StdI
	jne	SHORT checkVarName	;
	cmp	WORD PTR [esi+3], 'n'	;             n"?
	je	SHORT @F		;yes: continue
	cmp	WORD PTR [esi+3], ' n'	;             n "?
	jne	SHORT checkVarName	;no: jump
	;
@@:
	xor	ebx, ebx		;EBX=0	as index for hashes[ebx]
	;
nextLine:
	mov	esi, OFFSET buffer	;ESI->line buffer
	invoke	crt_gets, esi, MAX_LEN	;read line, EAX=0 if error
	or	eax, eax		;error (EOF)?
	jz	SHORT endOfFile		;yes: jump
	;
findLineEnd:
	mov	al, [esi]		;load next char		|	lodsb
	inc	esi			;and advance pointer	|
	or	al, al			;line ends?
	jnz	SHORT findLineEnd	;no: go back
	;
	cmp	BYTE PTR [esi-2], CR	;last char was a CR?
	jne	SHORT @F		;no: continue
	dec	esi			;else: remove it
	;
@@:
	sub	esi, OFFSET buffer + 1	;ESI = line lenght
	invoke	xxh32, ADDR buffer, esi, seed	;EAX = xxh32(string:DWORD, len:DWORD, seed:DWORD)
	mov	hashes[ebx], eax	;store h32 in the array of hashes
	add	ebx, 4			;and increment the index
	mov	result, eax		;store result here
	call	showResult		;to show it
	jmp	SHORT nextLine		;and go back for next line
	;
endOfFile:				;get the xxh32 of the xxh32'es of all lines in the file (xxh32^2)
	invoke	xxh32, ADDR hashes, ebx, seed	;EAX = xxh32(string:DWORD, len:DWORD, seed:DWORD)
	mov	result, eax		;store result here
	jmp	SHORT quit		;and return it in ERRORLEVEL (no show it)

checkVarName:
	dec	esi			;ESI->varName
	mov	ebx, OFFSET buffer	;EBX->buffer
	;
@@:
	mov	al, [esi]		;load next char		|lodsb
	inc	esi			;and advance pointer	|
	or	al, al			;varName ends?
	jz	SHORT @F		;yes: continue
	cmp	al, SPACE		;varName ends in space?
	je	SHORT @F		;yes: continue
	;
	mov	[ebx], al		;store the char
	inc	ebx			;advance pointer
	jmp	SHORT @B		;and go back for next char
	;
@@:
	mov	BYTE PTR [ebx], 0	;store varName delimiter
	invoke	crt_getenv, ADDR buffer	;EAX = getenv(varName)
	or	eax, eax		;varName found?
	jz	SHORT quit		;no: terminate with 0
	;
	mov	esi, eax		;ESI->varContents
	mov	ebx, eax		;EBX: the same
	;
findVarEnd:
	mov	al, [esi]		;load next char		|	lodsb
	inc	esi			;and advance pointer	|
	or	al, al			;varContents ends?
	jnz	SHORT findVarEnd	;no: go back
	;
	sub	esi, ebx		;ESI = string lenght + 1
	dec	esi			;Ok
	invoke	xxh32, ebx, esi, seed	;EAX = xxh32(input:DWORD, len:DWORD, seed:DWORD)
;;;	jmp	SHORT showResultAndEnd	;and jump to end
	;
showResultAndEnd:
	mov	result, eax		;store result
	call	showResult		;show result in hexadecimal
	;
quit:
	invoke	crt_exit, result	;return the result in ERRORLEVEL

Main	ENDP

	end	Main

