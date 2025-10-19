	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;									;
	;	xxh32 - Copyright (C) 2012-2023 Yann Collet			;
	;	https://github.com/Cyan4973/xxHash				;
	;									;
	;	Simplified xxh32 version and assembler translation written by	;
	;	Antonio Perez Ayala aka Aacini					;
	;	antonio.perez.ayala@gmail.com					;
	;	https://www.apaacini.com/					;
	;									;
	;	1- Install the MASM32 SDK from https://www.masm32.com		;
	;	2- Rename this file to xxh32.asm (if not already)		;
	;	3- Create the object file with: 				;
	;	   \masm32\bin\ml /c /coff xxh32.asm				; 
	;									;
	;	The created xxh32.obj file include the xxh32 C compliant	;
	;	function you can directly link to any Windows C program.	;
	;									;
	;	To generate Linux compatible object code, use the appropriate	;
	;	switches in ml.exe or any other assembler or linker used	;
	;									;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	.486			;create 32 bit code
	.model flat, stdcall	;32 bit memory model
	option casemap :none	;case sensitive


						;// Rotate left an uint32 (circular shift)
						;uint32_t rotl(uint32_t v, int x) {
						;    return (v << x) | (v >> (32 - x));
						;}
						;
						;// Read 1 byte as uint8
						;uint8_t read_u8(const char* input, int pos) {
						;    return static_cast<uint8_t>(input[pos]);
						;}
						;
						;// Read 4 bytes as uint32 little-endian
						;uint32_t read_u32le(const char* input, int pos) {
						;    uint32_t b0 = read_u8(input, pos + 0);
						;    uint32_t b1 = read_u8(input, pos + 1);
						;    uint32_t b2 = read_u8(input, pos + 2);
						;    uint32_t b3 = read_u8(input, pos + 3);
						;    return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
						;}
.data						;
						;// xxHash32 Prime numbers
PRIME32_1	EQU	9E3779B1H		;#define PRIME32_1 0x9E3779B1U
PRIME32_2	EQU	85EBCA77H		;#define PRIME32_2 0x85EBCA77U
PRIME32_3	EQU	0C2B2AE3DH		;#define PRIME32_3 0xC2B2AE3DU
PRIME32_4	EQU	27D4EB2FH		;#define PRIME32_4 0x27D4EB2FU
PRIME32_5	EQU	165667B1H		;#define PRIME32_5 0x165667B1U
						;
blocks16	DD	?			;int blocks16;
rest		DD	?			;int rest;

	;Equivalent CPU registers: EAX=v1, EBX=v2, ECX=v3, EDX=v4, ESI=p (*input[pos]), EDI=d for auxiliary operations
	;EAX is also h32: the returned value. blocks16 and rest are the only int32 (DWORD) memory variables used

.code

	PUBLIC	xxh32		;name of exported procedure in the .obj file

xxh32	PROC	input:DWORD,len:DWORD,seed:DWORD;uint32_t xxh32(const char* input, int len, uint32_t seed) {
	push	ebx		;protect
	push	esi		;- standard
	push	edi		;- - registers
	;
	mov	esi, input	;p->input	;    int pos = 0;
						;
	mov	eax, seed			;    // h32 = v1 = seed;
						;
	mov	edi, len	;aux=len
	mov	blocks16, edi	;blocks16=len
	and	edi, 1111B	;aux%=16
	mov	rest, edi			;    rest = len % 16;
	shr	blocks16, 4	;(set Zero flag);    blocks16 = len / 16;
	;
						;    // XXH32 PROCESS BLOCKS OF 16 BYTES
	jz	ELSE1		;flag set by SHR;   if (blocks16 > 0) {
	mov	ebx, eax	;v2=seed
	mov	ecx, eax	;v3=seed
	mov	edx, eax	;v4=seed
						;        uint32_t v1 = seed + PRIME32_1 + PRIME32_2;
	add	eax, PRIME32_1+PRIME32_2;v1+=PRIME32_1+PRIME32_2
	add	ebx, PRIME32_2	;v2+=PRIME32_2	;        uint32_t v2 = seed + PRIME32_2;
						;        uint32_t v3 = seed;
	sub	edx, PRIME32_1	;v4-=PRIME32_1	;        uint32_t v4 = seed - PRIME32_1;
						;
FOR1:						;        for ( int i = 1; i <= blocks16; i++ ) {
						;
	imul	edi, DWORD PTR[esi], PRIME32_2	;            d = read_u32le(input, pos + 0*4) * PRIME32_2;
	add	eax, edi			;            v1 += d;
	rol	eax, 13				;            v1 = rotl32(v1, 13);
	imul	eax, PRIME32_1			;            v1 *= PRIME32_1;
						;
	imul	edi, DWORD PTR[esi+4], PRIME32_2;            d = read_u32le(input, pos + 1*4) * PRIME32_2;
	add	ebx, edi			;            v2 += d;
	rol	ebx, 13				;            v2 = rotl(v2, 13);
	imul	ebx, PRIME32_1			;            v2 *= PRIME32_1;
						;
	imul	edi, DWORD PTR[esi+8], PRIME32_2;            d = read_u32le(input, pos + 2*4) * PRIME32_2;
	add	ecx, edi			;            v3 += d;
	rol	ecx, 13				;            v3 = rotl(v3, 13);
	imul	ecx, PRIME32_1			;            v3 *= PRIME32_1;
						;
	imul	edi, DWORD PTR[esi+12], PRIME32_2;           d = read_u32le(input, pos + 3*4) * PRIME32_2;
	add	edx, edi			;            v4 += d;
	rol	edx, 13				;            v4 = rotl(v4, 13);
	imul	edx, PRIME32_1			;            v4 *= PRIME32_1;
						;
	add	esi, 16				;            pos += 16;
	dec	blocks16
	jnz	SHORT FOR1
ENDFOR1:					;        }
						;
	rol	eax, 1		;h32=rotl(v1,1)	;        uint32_t h32 = rotl(v1, 1) + rotl(v2, 7) + rotl(v3, 12) + rotl(v4, 18);
	rol	ebx, 7		;v2=rotl(v2,7)
	add	eax, ebx	;h32+=v2
	rol	ecx, 12		;v3=rotl(v3,12)
	add	eax, ecx	;h32+=v3
	rol	edx, 18		;v4=rotl(v4,18)
	add	eax, edx	;h32+=v4
	jmp	SHORT ENDIF1
ELSE1:						;    } else {
						;        // If len less 16: initialize with seed + PRIME32_5
	add	eax, PRIME32_5	;h32+=PRIME32_5	;        h32 = seed + PRIME32_5;
ENDIF1:						;    }
						;
	add	eax, len			;    h32 += len;
						;
						;    // XXH32 PROCESS BLOCKS OF 4 BYTES
	mov	ecx, rest	;aux=rest	;
	shr	ecx, 2		;(set Zero flag);    int blocks4 = rest / 4;
	jz	SHORT ENDFOR2	;flag set by SHR;
FOR2:						;    for ( i = 1; i <= blocks4; i++ ) {
	imul	edi, DWORD PTR [esi], PRIME32_3	;        d = read_u32le(input, pos) * PRIME32_3;
	add	eax, edi			;        h32 += d;
	rol	eax, 17				;        h32 = rotl(h32, 17);
	imul	eax, PRIME32_4			;        h32 *= PRIME32_4;
	add	esi, 4				;        pos += 4;
	dec	ecx
	jnz	SHORT FOR2
ENDFOR2:					;    }
						;
						;    // XXH32 PROCESS BLOCKS OF 1 BYTE
	mov	ecx, rest	;aux=rest	;
	and	ecx, 11B	;(set Zero flag);    int blocks1 = rest % 4;
	jz	SHORT ENDFOR3	;flag set by AND;
FOR3:						;    for ( i = 1; i <= blocks1; i++ ) {
	movzx	edi, BYTE PTR [esi]		;        d = read_u8(input, pos);
	imul	edi, PRIME32_5			;        d *= PRIME32_5;
	add	eax, edi			;        h32 += d;
	rol	eax, 11				;        h32 = rotl(h32, 11);
	imul	eax, PRIME32_1			;        h32 *= PRIME32_1; 
	inc	esi				;        pos += 1;
	dec	ecx
	jnz	SHORT FOR3
ENDFOR3:					;    }
						;
						;    // Avalanche
	mov	edi, eax	;aux=h32	;    h32 ^= h32 >> 15;
	shr	edi, 15		;aux=h32 >> 15
	xor	eax, edi	;h32^=h32 >> 15
	imul	eax, PRIME32_2	;h32*=PRIME32_2	;    h32 *= PRIME32_2;
	mov	edi, eax	;aux=h32	;    h32 ^= h32 >> 13;
	shr	edi, 13		;aux=h32 >> 13
	xor	eax, edi	;h32^=h32 >> 13
	imul	eax, PRIME32_3	;h32*=PRIME32_3	;    h32 *= PRIME32_3;
	mov	edi, eax	;aux=h32	;    h32 ^= h32 >> 16;
	shr	edi, 16		;aux=h32 >> 16
	xor	eax, edi	;h32^=h32 >> 16
						;
	pop	edi		;recover
	pop	esi		;- standard
	pop	ebx		;- - registers

	ret	;eax				;    return h32;
xxh32	ENDP					;}


	end
