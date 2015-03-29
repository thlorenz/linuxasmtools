  [section .data]

; file decode_table.h
;
; The decode tables appear in this order:
;     decode_table       - handles opcodes 0-ff
;     decode_table+256*4 - handles opcodes  0f,00 -> 0f,ff
;     decode_table+512*4 - start of group tables
;      
; All tables have the same format.  The main decode table is indexed by
; opcodes.  The first dword entry is for opcode 00.
; The second dword entry is for opcode 01, etc.
;
; The format for each dword entry is:
;    db zxyyyyyy  where z=? defined by process
;                       x=? defined by process
;                       y=process index (up to 64 entries)
;    db ?         defined by process
;    dw name      index to opcode text (name)
;
; rules: 1. if dword entry = 0 then opcode is undefined
;        2. if process index = 0 then this is a multi-opcode (group)
;           and name field has group number
;
; The decode logic uses the process index to look in table
; of process's and call one.  If the index is zero then
; the group process is called.  A group opcode has multiple
; instructions sharing one opcode and must do another level
; of decode.  The group process extracts the name index from
; main decode entry and this selects the next table.  Next,
; the mod/rm field from second opcode byte provides and index
; into the selected group table.
;
; The fromat of the group tables is same as main decode
; table entries.  The first byte has process index and
; final dw has ptr to text for opcode name.
;----------------------------------------------------------
; 
prefix	equ	80h
noprefix equ	00h
operand_ equ	80h
noperand equ	00h
;--------------------------------------------------------------------
decode_table:

_000	db 08		;type_08
	db 83h		;flag
	dw __add


_001	db 08		;type_08
	db 03h		;flag
	dw __add


_002	db 9		;type_09
	db 084h		;flags
	dw __add


_003	db 9		;type_09
	db 004h		;flags
	dw __add


_004	db 17		;type_17
	db 20h		;20h=imm8
	dw __add


_005	db 17		;type_17
	db 80h		;80h=prefix
	dw __add


_006	db operand_ + 3	;has-operand type_03
	db (1<<7) + (0<<4) + 0 ;warn + seg + type
	dw __push	;push es


_007	db operand_ + 3	;has-operand + type_03
	db (1<<7) + (0<<4) + 0 ;warn + seg + type
	dw __pop       ;pop es


_008	db 08		;type_08
	db 083h		;flag
	dw __or


_009	db 08		;type_08
	db 03h		;flag
	dw __or


_00A	db 9		;type_09
	db 084h		;flags
	dw __or


_00B	db 9		;type_09
	db 004h		;flags
	dw __or


_00C	db 17		;type_17
	db 20h		;20h=imm8
	dw __or


_00D	db 17		;type_17
	db 80h		;80h=prefix
	dw __or


_00E	db operand_ + 3	;type_03
	db (1<<7) + (1<<4) + 0 ; warn + seg + instruction_type
	dw __push	;push cs


_00F	db noprefix + 1	;type_01
	db 40h		;state_flag
	dw __esc	;esc


_010	db 08		;type_08
	db 083h		;flag
        dw __adc


_011	db 08		;type_08
	db 03h		;flag
	dw __adc


_012	db 9		;type_09
	db 084h		;flag
	dw __adc


_013	db 9		;type_09
	db 004h		;flags
	dw __adc


_014	db 17		;type_17
	db 020h		;20h=imm8
	dw __adc


_015	db 17		;type_17
	db 80h		;80h=prefix
	dw __adc


_016	db operand_ + 3	;type_03
	db (1<<7) + (2<<4) + 0 ;warn + seg + instruction_type
	dw __push	;push ss


_017	db operand_ + 3	;type_03
	db (1<<7) + (2<<4) + 0 ;warn_flag + seg + instruction_type
	dw __pop	;pop ss


_018	db 08		;type_08
	db 083h		;flag
	dw __sbb


_019	db 08		;type_08
	db 03h		;flag
	dw __sbb


_01A	db 9		;type_09
	db 084h		;flags
	dw __sbb


_01B	db 9		;type_09
	db 004h		;flags
	dw __sbb


_01C	db 19		;type_19
	db 2		;code2
	dw __sbb


_01D	db 19		;type_19
	db 3		;code3
	dw __sbb


_01E	db operand_ + 3	;type_03
	db (1<<7) + (3<<4) + 0 ;warn_flag + seg + instruction_type
	dw __push	;push ds


_01F	db operand_ + 3	;type_03
	db (1<<7) + (3<<4) + 0 ;warn_flag + seg + instruction_type
	dw __pop	;pop ds


_020	db 08		;type_08
	db 083h		;flag
 	dw __and


_021	db 08		;type_08
	db 03h		;flag
	dw __and


_022	db 9		;type_09
	db 084h		;flags
	dw __and


_023	db 9		;type_09
	db 004h		;flags
	dw __and


_024	db 17		;type_17
	db 20h		;20h=imm8
	dw __and


_025	db 17		;type_17
	db 80h		;80h=prefix
	dw __and


_026	db noprefix + 1 ;(process1) type_01
        db 20h          ; state_flag stuff value
	dw __es


_027	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __daa	;daa


_028	db 08		;type_08
	db 083h		;flag
	dw __sub


_029	db 08		;type_08
	db 03h		;flag
	dw __sub


_02A	db 9		;type_09
	db 084h		;flags
	dw __sub


_02B	db 9		;type_09
	db 004h		;flags
	dw __sub


_02C	db 19		;type_19
	db 2		;code2
	dw __sub


_02D	db 19		;type_19
	db 3		;code3
	dw __sub


_02E	db 1 ;noprefix + 1 (process1) type_01
        db 20h ;state_flag
	dw __cs


_02F	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __das	;das


_030	db 08		;type_08
	db 083h		;flag
	dw __xor


_031	db 08		;type_08
	db 03h		;flag
	dw __xor


_032	db 9		;type_09
	db 084h		;flags
	dw __xor


_033	db 9		;type_09
	db 004h		;flags
	dw __xor


_034	db 19		;type_19
	db 2		;code2
	dw __xor


_035	db 19		;type_19
	db 3		;code3
	dw __xor


_036	db noprefix + 1 ;(process1) type_01
        db 20h		;state_flag contents
	dw __ss


_037	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag +  no seg + instruction_type
	dw __aaa	;aaa


_038	db 08		;type_08
	db 083h		;flag
	dw __cmp


_039	db 08		;type_08
	db 03h		;flag
	dw __cmp


_03A	db 9		;type_09
	db 084h		;flags
	dw __cmp


_03B	db 9		;type_09
	db 004h		;flags
	dw __cmp


_03C	db 17		;type_17
	db 20h		;20h=imm8
	dw __cmp


_03D	db 17		;type_17
	db 80h		;80h=prefix
	dw __cmp


_03E	db noprefix + 1	;(process1) type_01
        db 20h		;state_flag setting
	dw __ds


_03F	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __aas	;aas


_040	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __inc	; inc (eax,ax)


_041	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __inc	; inc (ecx,cx)


_042	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __inc	; inc (edx,dx)


_043	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __inc	; inc (ebx,bx)


_044	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __inc	; inc (esp,sp)


_045	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __inc	; inc (ebp,bp)


_046	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __inc	; inc (esi,si)


_047	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __inc	; inc (edi,di)


_048	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __dec	; dec (eax,ax)


_049	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __dec	; dec (ecx,cx)


_04A	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __dec	; dec (edx,dx)


_04B	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __dec	; dec (ebx,bx)


_04C	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __dec	; dec (esp,sp)


_04D	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __dec	; dec (ebp,bp)


_04E	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __dec	; dec (esi,si)


_04F	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __dec	; dec (edi,di)


_050	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __push	; push (eax,ax)


_051	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __push	; push (ecx,cx)


_052	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __push	; push (edx,dx)


_053	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __push	; push (ebx,bx)


_054	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __push	; push (esp,sp)


_055	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __push	; push (ebp,bp)


_056	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __push	; push (esi,si)


_057	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __push	; push (edi,di)


_058	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __pop	; pop (eax,ax)


_059	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __pop	; pop (ecx,cx)


_05A	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __pop	; pop (edx,dx)


_05B	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __pop	; pop (ebx,bx)


_05C	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __pop	; pop (esp,sp)


_05D	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __pop	; pop (ebp,bp)


_05E	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __pop	; pop (esi,si)


_05F	db prefix + 2	;(process2) type_02
	db 0		;unused
	dw __pop	; pop (edi,di)


_060	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __pusha	;pusha


_061	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __popa	;popa


_062	db 9		;type_09
	db 014h		;flags
	dw __bound

_063	dw 0	;unused opcode
	dw 0	;unused opcode

_064	db noprefix + 1	;(process1) type_01
	db 20h		;state_flag setting
	dw __fs


_065	db noprefix + 1	;(process1) type_01
	db 20h		;state_flag setting
	dw __gs


_066	db noprefix + 1	;(process1) type_01
	db 10h		;state_flag setting
	dw __opsz


_067	db noprefix + 1	;(process1) type_01
	db 08h		;state_flag setting
	dw __adsz


_068	db 19		;type_19
	db 3		;code3
	dw __push


_069	db 16		;type_16
	db 0bh		;flag
	dw __imul


_06A	db 19		;type_19
	db 1		;code1
	dw __push


_06B	db 15		;type_15
	db 00ah		;flag
	dw __imul


_06C	db 5	;type_05
	db 83h	;prefix_flag setting
	dw __insb


_06D	db prefix + 05	;type_05
	db 93h	;prefix_flag setting
	dw __insd


_06E	db 5	;type_05
	db 83h	;prefix_flag setting
	dw __outsb


_06F	db prefix + 05	;type_05
	db 93h	;prefix_flag setting
	dw __outsd


_070	db 18		;type_18
	db 1		;rel8
	dw __jo


_071	db 18		;type_18
	db 1		;rel8
	dw __jno


_072	db 18		;type_18
	db 1		;rel8
	dw __jc


_073	db 18		;type_18
	db 1		;rel8
	dw __jnc


_074	db 18		;type_18
	db 1		;rel8
	dw __je


_075	db 18		;type_18
	db 1		;rel8
	dw __jne


_076	db 18		;type_18
	db 1		;rel8
	dw __jna


_077	db 18		;type_18
	db 1		;rel8
	dw __ja


_078	db 18		;type_18
	db 1		;rel8
	dw __js


_079	db 18		;type_18
	db 1		;rel8
	dw __jns


_07A	db 18		;type_18
	db 1		;rel8
	dw __jp


_07B	db 18		;type_18
	db 1		;rel8
	dw __jnp


_07C	db 18		;type_18
	db 1
	dw __jl


_07D	db 18		;type_18
	db 1		;rel8
	dw __jnl


_07E	db 18		;type_18
	db 1		;rel8
	dw __jle


_07F	db 18		;type_18
	db 1		;rel8
	dw __jg


_080	dw 0
	dw 1*32	;intel group 1 , our group 1


_081	dw 0
	dw 2*32	;intel group 1 , our group 2

_082	dw 0	;unused opcode
	dw 0	;unused opcode

_083	dw 0
	dw 3*32	;intel group 1 , our group 3


_084	db 08		;type_08
	db 083h		;flag
	dw __test


_085	db 08		;type_08
	db 03h		;flag
	dw __test


_086	db 9		;type_09
	db 084h		;flags
	dw __xchg


_087	db 9		;type_09
	db 004h		;flags
	dw __xchg


_088	db 08		;type_08
	db 083h		;flag
	dw __mov


_089	db 08		;type_08
	db 03h		;flag
	dw __mov


_08A	db 9		;type_09
	db 084h		;flag
	dw __mov


_08B	db 9		;type_09
	db 004h		;flags
	dw __mov

_08C	db 30		;type_30
	db 0
	dw __mov	 

_08D	db 9		;type_09
	db 014h		;flags
	dw __lea

_08E	db 30		;type_30
	db 0
	dw __mov

_08F	db 6		;type_06
	db 0		;flag
	dw __pop


_090	db 4	;type_04
	db 3	;modcol
	dw __xchg ;xchg eax,eax  or xchg ax,ax or nop


_091	db 4	;type_04
	db 3	;modcol
	dw __xchg ;xchg eax,ecx  or xchg ax,cx


_092	db 4	;type_04
	db 3	;modcol
	dw __xchg ;xchg eax,edx or xchg ax,dx


_093	db 4	;type_04
	db 3	;modcol
	dw __xchg ;xchg eax,ebx or xchg ax,bx


_094	db 4	;type_04
	db 3	;modcol
	dw __xchg ;xchg eax,esp or xchg ax,sp


_095	db 4	;type_04
	db 3	;modcol
	dw __xchg ;xchg eax,ebp or xchg ax,bp


_096	db 4	;type_04
	db 3	;modcol
	dw __xchg ;xchg eax,esi  or xchg ax,si


_097	db 4	;type_04
	db 3	;modcol
	dw __xchg ;xchg eax,edi  or xchg ax,di


_098	db 4	;type_04
	db 4	;modcol
	dw __cwde ;cwde or cbw


_099	db 4	;type_04
	db 5	;modcol
	dw __cdq ;cdq or cwd


_09A	db 18		;type_18
	db 5		;far 
	dw __call


_09B	db noperand + 3	;type_03
	db (1<<7) + 0 + 4	;warn_flag + no seg + instruction_type
	dw __wait	;wait


_09C	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __pushf	;pushf


_09D	db noperand + 3	;type_03
	db 0 + 0 +0	;warn_flag + no seg + instruction_type
	dw __popf	;popf


_09E	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __sahf	;sahf


_09F	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __lahf	;lahf


_0A0	db 21		;type_21
	db 1		;code1
	dw __mov


_0A1	db 21		;type_21
	db 41h		;prefix + code1
	dw __mov


_0A2	db 21		;type_21
	db 0		;
	dw __mov


_0A3	db 21		;type_21
	db 40h		;prefix
	dw __mov


_0A4	db 5	;type_05
	db 83h	;prefix_flag setting
	dw __movsb


_0A5	db prefix + 05	;type_05
	db 93h	;prefix_flag setting
	dw __movsd


_0A6	db 5	;type_05
	db 87h	;prefix_flag setting
	dw __cmpsb


_0A7	db prefix + 05	;type_05
	db 97h	;prefix_flag setting
	dw __cmpsd


_0A8	db 19		;type_19
	db 2		;code2
	dw __test


_0A9	db 19		;type_19
	db 3		;code3
	dw __test


_0AA	db 5	;type_05
	db 83h	;prefix_flag setting
	dw __stosb


_0AB	db prefix + 05	;type_05
	db 93h	;prefix_flag setting
	dw __stosd


_0AC	db 5	;type_05
	db 83h	;prefix_flag setting
	dw __lodsb


_0AD	db prefix + 05	;type_05
	db 93h	;prefix_flag setting
	dw __lodsd


_0AE	db 5	;type_05
	db 87h	;prefix_flag setting
	dw __scasb


_0AF	db prefix + 05	;type_05
	db 97h	;prefix_flag setting
	dw __scasd


_0B0	db 4	;type_04
	db 1	;modcol
	dw __mov ;mov al,imm8


_0B1	db 4	;type_04
	db 1	;modcol
	dw __mov ;mov cl,imm8


_0B2	db 4	;type_04
	db 1	;modcol
	dw __mov ;mov dl,imm8


_0B3	db 4	;type_04
	db 1	;modcol
	dw __mov ;mov bl,imm8


_0B4	db 4	;type_04
	db 1	;modcol
	dw __mov ;mov ah,imm8


_0B5	db 4	;type_04
	db 1	;modcol
	dw __mov ;mov ch,imm8


_0B6	db 4	;type_04
	db 1	;modcol
	dw __mov ;mov dh,imm8


_0B7	db 4	;type_04
	db 1	;modcol
	dw __mov ;mov bh,imm8


_0B8	db 4	;type_04
	db 2	;modcol
	dw __mov ;mov eax,imm32   or  mov ax,imm16


_0B9	db 4	;type_04
	db 2	;modcol
	dw __mov ;mov ecx,imm32  or  mov cx,imm16


_0BA	db 4	;type_04
	db 2	;modcol
	dw __mov ;mov edx,imm32  or  mov dx,imm16


_0BB	db 4	;type_04
	db 2	;modcol
	dw __mov ;mov ebx,imm32  or  mov bx,imm16


_0BC	db 4	;type_04
	db 2	;modcol
	dw __mov ;mov esp,imm32  or  mov sp,imm16


_0BD	db 4	;type_04
	db 2	;modcol
	dw __mov ;mov ebp,imm32  or  mov bp,imm16


_0BE	db 4	;type_04
	db 2	;modcol
	dw __mov ;mov esi,imm32  or  mov si,imm16


_0BF	db 4	;type_04
	db 2	;modcol
	dw __mov ;mov edi,imm32  or  mov di,imm16


_0C0	dw 0
	dw 4*32	;intel group 2,  opcode=c0  our group = 4


_0C1	dw 0
	dw 5*32	;intel group 2,  opcode=c1  our group = 5


_0C2	db 19		;type_19
	db 4		;code4
	dw __ret


_0C3	db noperand + 3	;type_03
	db 0 + 0 + 8	;warn_flag + no seg + instruction_type
	dw __ret	;ret


_0C4	db 9		;type_09
	db 014h		;flags
	dw __les


_0C5	db 9		;type_09
	db 014h		;flags
	dw __lds


_0C6	db 07	;type_07
	db 0a2h	;flag
	dw __mov


_0C7	db 10		;type_10
	db 05h		;flags
	dw __mov


_0C8	db 20		;type_20
	db 3		;code3
	dw __enter


_0C9	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __leave	;leave


_0CA	db 19		;type_19
	db 4		;code4
	dw __retf


_0CB	db noperand + 3	;type_03
	db 0 + 0 + 8	;warn_flag + no seg + instruction_type
	dw __retf	;retf


_0CC	db noperand + 3	;type_03
	db (1<<7) + 0 + 8	;warn_flag + no seg + instruction_type
	dw __int3	;int3


_0CD	db 19		;type_19 ??
	db 1		;code1
	dw __int
; db 005h ;operand 1/2/3


_0CE	db noperand + 3	;type_03
	db (1<<7) + 0 + 4	;warn_flag + no seg + instruction_type
	dw __into	;into


_0CF	db noperand + 3	;type_03
	db (1<<7) + 0 + 4	;warn_flag + no seg + instruction_type
	dw __iret	;iret


_0D0	dw 0
	dw 6*32	;intel group = 2,  opcode=d0,  our group = 6


_0D1	dw 0
	dw 7*32	;intel group = 2,  opcode=d1,  our group = 7


_0D2	dw 0
	dw 8*32	;intel group = 2,  opcode=d2,  our group = 8

_0D3	dw 0
	dw 9*32	;intel group = 2,  opcode=d3   our group = 9


_0D4	db 19		;type_19
	db 1		;code1
	dw __aam


_0D5	db 19		;type_19
	db 1		;code1
	dw __aad

_0d6	dw 0	;unused opcode
	dw 0	;unused opcode

_0D7	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __xlatb	;xlatb


_0D8	dw 0
	dw 14*32	;intel float  opcode=d8   our group = 14

_0D9	dw 0
	dw 15*32	;intel float  opcode=d9   our group = 15

_0DA	dw 0
	dw 16*32	;intel float  opcode=da   our group = 16

_0DB	dw 0
	dw 17*32	;intel float  opcode=db   our group = 17

_0DC	dw 0
	dw 18*32	;intel float  opcode=dc   our group = 18

_0DD	dw 0
	dw 19*32	;intel float  opcode=dd   our group = 19

_0DE	dw 0
	dw 20*32	;intel float  opcode=de   our group = 20

_0DF	dw 0
	dw 21*32	;intel float  opcode=df   our group = 21

_0E0	db 18		;type_18
	db 6		;
	dw __loopne


_0E1	db 18		;type_18
	db 6		;
	dw __loope


_0E2	db 18		;type_18
	db 6		;
	dw __loop


_0E3	db 18		;type_18
	db 4		;jecxz type
	dw __jecxz


_0E4	db 17		;type_17
	db 060h		;40h="in inst"  20h=imm8
	dw __in


_0E5	db 17		;type_17
	db 0e0h		;80h=prefix 40h="in inst"  20h=imm8
	dw __in


_0E6	db 17		;type_17
	db 030h		;20h=imm8  10h="out inst"
	dw __out


_0E7	db 17		;type_17
	db 0b0h		;80h=prefix 20h=imm8 10h="out inst"
	dw __out


_0E8	db 18		;type_18
	db 3		;rel32 + type
	dw __call


_0E9	db 18		;type_18
	db 3		;rel32 + type
	dw __jmp


_0EA	db 18		;type_18
	db 5		;far
	dw __jmp


_0EB	db 18		;type_18
	db 1		;rel8
	dw __jmp


_0EC	db 17		;type_17
	db 40h		;40h="in inst"
	dw __in


_0ED	db 17		;type_17
	db 0c0h		;80h=prefix 40h="in inst"
	dw __in


_0EE	db 17		;type_17
	db 010h		;10h="out inst"
	dw __out


_0EF	db 17		;type_17
	db 090h		;80h=prefix 10h="out inst"
	dw __out

;  note: the lock prefix is handled as one byte instruction.
_0F0	db noprefix + 3	;(process3) type_03
	db 00h		;state_flag setting
	dw __lock


_0F1	dw 0	;unused opcode
	dw 0	;unused opcode

_0F2	db noprefix + 1	;(process1) type_01
	db 04h		;state_flag setting
	dw __repne


_0F3	db noprefix + 1	;(process1) type_01
	db 02h		;state_flag setting
	dw __rep


_0F4	db noprefix + 3	;type_03
	db (1<<7) + 0 + 8	;warn_flag + no seg + instruction_type
	dw __hlt	;hlt


_0F5	db noprefix + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __cmc	;cmc


_0F6	dw 0
	dw 10*32	;intel group 3  our group = 10

_0F7	dw 0
	dw 11*32	;intel group 3  our group = 11

_0F8	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __clc	;clc


_0F9	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __stc	;stc


_0FA	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __cli	;cli


_0FB	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __sti 	;sti


_0FC	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type 
	dw __cld	;cld


_0FD	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + no seg + instruction_type
	dw __std	;std


_0FE	dw 0
	dw 12*32	;intel group 4  our group 12

_0FF	dw 0
	dw 13*32	;intel group 5  our group 13

;---------------------------------------------------------------

_100	dd 0		;sldt not implemented


_101	dw 0	;unused opcode
	dw 0	;unused opcode

_102	db 9		;type_09
	db 004h		;flags
	dw __lar


_103	db 9		;type_09
	db 004h		;flags
	dw __lsl


_104	dw 0,0	;unused opcode

_105	dw 0,0	;unused opcode

_106	db noperand + 3	;type_03
	db (1<<7) + 0 + 4	;warn_flag + no seg + instruction_type
	dw __clts

_107	dw 0,0	;unused opcode
_108	dw 0,0	;unused opcode
_109	dw 0,0	;unused opcode
_10a	dw 0,0	;unused opcode
_10b	dw 0,0	;unused opcode
_10c	dw 0,0	;unused opcode
_10d	dw 0,0	;unused opcode
_10e	dw 0,0	;unused opcode
_10f	dw 0,0	;unused opcode
_110	dw 0,0	;unused opcode
_111	dw 0,0	;unused opcode
_112	dw 0,0	;unused opcode
_113	dw 0,0	;unused opcode
_114	dw 0,0	;unused opcode
_115	dw 0,0	;unused opcode
_116	dw 0,0	;unused opcode
_117	dw 0,0	;unused opcode
_118	dw 0,0	;unused opcode
_119	dw 0,0	;unused opcode
_11a	dw 0,0	;unused opcode
_11b	dw 0,0	;unused opcode
_11c	dw 0,0	;unused opcode
_11d	dw 0,0	;unused opcode
_11e	dw 0,0	;unused opcode
_11f	dw 0,0	;unused opcode
_120	dw 0,0	;unused opcode
_121	dw 0,0	;unused opcode
_122	dw 0,0	;unused opcode
_123	dw 0,0	;unused opcode
_124	dw 0,0	;unused opcode
_125	dw 0,0	;unused opcode
_126	dw 0,0	;unused opcode
_127	dw 0,0	;unused opcode
_128	dw 0,0	;unused opcode
_129	dw 0,0	;unused opcode
_12a	dw 0,0	;unused opcode
_12b	dw 0,0	;unused opcode
_12c	dw 0,0	;unused opcode
_12d	dw 0,0	;unused opcode
_12e	dw 0,0	;unused opcode
_12f	dw 0,0	;unused opcode
_130	dw 0,0	;unused opcode
_131	dw 0,0	;unused opcode
_132	dw 0,0	;unused opcode
_133	dw 0,0	;unused opcode
_134	dw 0,0	;unused opcode
_135	dw 0,0	;unused opcode
_136	dw 0,0	;unused opcode
_137	dw 0,0	;unused opcode
_138	dw 0,0	;unused opcode
_139	dw 0,0	;unused opcode
_13a	dw 0,0	;unused opcode
_13b	dw 0,0	;unused opcode
_13c	dw 0,0	;unused opcode
_13d	dw 0,0	;unused opcode
_13e	dw 0,0	;unused opcode
_13f	dw 0,0	;unused opcode

_140	db 9		;type_09
	db 004h		;flags
	dw __cmovo


_141	db 9		;type_09
	db 004h		;flags
	dw __cmovno


_142	db 9		;type_09
	db 004h		;flags
	dw __cmovc


_143	db 9		;type_09
	db 004h		;flags
	dw __cmovnc


_144	db 9		;type_09
	db 004h		;flags
	dw __cmove


_145	db 9		;type_09
	db 004h		;flags
	dw __cmovne


_146	db 9		;type_09
	db 004h		;flags
	dw __cmovna


_147	db 9		;type_09
	db 004h		;flags
	dw __cmova


_148	db 9		;type_09
	db 004h		;flags
	dw __cmovs


_149	db 9		;type_09
	db 004h		;flags
	dw __cmovns


_14A	db 9		;type_09
	db 004h		;flags
	dw __cmovp


_14B	db 9		;type_09
	db 004h		;flags
	dw __cmovnp


_14C	db 9		;type_09
	db 004h		;flags
	dw __cmovl


_14D	db 9		;type_09
	db 004h		;flags
	dw __cmovnl


_14E	db 9		;type_09
	db 004h		;flags
	dw __cmovle


_14F	db 9		;type_09
	db 004h		;flags
	dw __cmovg

_150	dw 0,0	;unused opcode
_151	dw 0,0	;unused opcode
_152	dw 0,0	;unused opcode
_153	dw 0,0	;unused opcode
_154	dw 0,0	;unused opcode
_155	dw 0,0	;unused opcode
_156	dw 0,0	;unused opcode
_157	dw 0,0	;unused opcode
_158	dw 0,0	;unused opcode
_159	dw 0,0	;unused opcode
_15a	dw 0,0	;unused opcode
_15b	dw 0,0	;unused opcode
_15c	dw 0,0	;unused opcode
_15d	dw 0,0	;unused opcode
_15e	dw 0,0	;unused opcode
_15f	dw 0,0	;unused opcode
_160	dw 0,0	;unused opcode
_161	dw 0,0	;unused opcode
_162	dw 0,0	;unused opcode
_163	dw 0,0	;unused opcode
_164	dw 0,0	;unused opcode
_165	dw 0,0	;unused opcode
_166	dw 0,0	;unused opcode
_167	dw 0,0	;unused opcode
_168	dw 0,0	;unused opcode
_169	dw 0,0	;unused opcode
_16a	dw 0,0	;unused opcode
_16b	dw 0,0	;unused opcode
_16c	dw 0,0	;unused opcode
_16d	dw 0,0	;unused opcode
_16e	dw 0,0	;unused opcode
_16f	dw 0,0	;unused opcode
_170	dw 0,0	;unused opcode
_171	dw 0,0	;unused opcode
_172	dw 0,0	;unused opcode
_173	dw 0,0	;unused opcode
_174	dw 0,0	;unused opcode
_175	dw 0,0	;unused opcode
_176	dw 0,0	;unused opcode


_177	dd 0	;emms instruction not implemented

_178	dw 0,0	;unused opcode
_179	dw 0,0	;unused opcode
_17a	dw 0,0	;unused opcode
_17b	dw 0,0	;unused opcode
_17c	dw 0,0	;unused opcode
_17d	dw 0,0	;unused opcode
_17e	dw 0,0	;unused opcode
_17f	dw 0,0	;unused opcode

_180	db 18		;type_18
	db 2		;rel32
	dw __jo


_181	db 18		;type_18
	db 2		;rel32
	dw __jno


_182	db 18		;type_18
	db 2		;rel32
	dw __jc


_183	db 18		;type_18
	db 2		;rel32
	dw __jnc


_184	db 18		;type_18
	db 2		;rel32
	dw __je


_185	db 18		;type_18
	db 2		;rel32
	dw __jne


_186	db 18		;type_18
	db 2		;rel32
	dw __jna


_187	db 18		;type_18
	db 2		;rel32
	dw __ja


_188	db 18		;type_18
	db 2		;rel32
	dw __js


_189	db 18		;type_18
	db 2		;rel32
	dw __jns


_18A	db 18		;type_18
	db 2		;rel32
	dw __jp


_18B	db 18		;type_18
	db 2		;rel32
	dw __jnp


_18C	db 18		;type_18
	db 2		;rel32
	dw __jl


_18D	db 18		;type_18
	db 2		;rel32
	dw __jnl


_18E	db 18		;type_18
	db 2		;rel32
	dw __jle


_18F	db 18		;type_18
	db 2		;rel32
	dw __jg


_190	db 6	;type_06
	db 80h	;80h=byte flag
	dw __seto

_191	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setno


_192	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setc


_193	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setnc


_194	db 6	;type_06
	db 80h	;80h=byte flag
	dw __sete


_195	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setne


_196	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setna


_197	db 6	;type_06
	db 80h	;80h=byte flag
	dw __seta


_198	db 6	;type_06
	db 80h	;80h=byte flag
	dw __sets


_199	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setns


_19A	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setp


_19B	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setnp


_19C	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setl


_19D	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setnl


_19E	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setng


_19F	db 6	;type_06
	db 80h	;80h=byte flag
	dw __setg


_1A0	db operand_ + 3	;type_03  with operand
	db (1<<7) + (4<<4) + 0 ;warn_flag + seg + instruction_type
	dw __push	;push fs


_1A1	db operand_ + 3	;type_03 with operand
	db (1<<7) + (4<<4) + 0 ;warn_flag + seg + instruction_type
	dw __pop	;pop fs


_1A2	db noperand + 3	;type_03
	db 0 + 0 + 0	;warn_flag + seg + instruction_type
	dw __cpuid	;cpuid


_1A3	db 08		;type_08
	db 03h		;flag
	dw __bt


_1A4	db 12		;type_12
	db 027h		;flag
	dw __shld


_1A5	db 12		;type_12
	db 047h		;flag
	dw __shld

_1A6	dw 0,0	;unused opcode
_1A7	dw 0,0	;unused opcode

_1A8	db operand_ + 3	;type_03 with operand
	db (1<<7) + (5<<4) + 0 ;warn_flag + seg + instruction_type
	dw __push	;push gs


_1A9	db operand_ + 3	;type_03 with operand
	db (1<<7) + (5<<4) + 0 ;warn_flag + seg + instruction_type
	dw __pop	;pop gs

_1AA	dw 0,0	;unused opcode

_1AB	db 08		;type_08
	db 03h		;flag
	dw __bts


_1AC	db 12		;type_12
	db 027h		;flag
	dw __shrd


_1AD	db 12		;type_12
	db 047h		;flag
	dw __shrd

_1AE	dw 0,0	;unused opcode

_1AF	db 9		;type_09
	db 004h		;flags
	dw __imul


_1B0	db 08		;type_08
	db 083h		;flag
	dw __cmpxchg


_1B1	db 08		;type_08
	db 03h		;flag
	dw __cmpxchg


_1B2	db 9		;type_09
	db 014h		;flags
	dw __lss


_1B3	db 08		;type_08
	db 03h		;flag
	dw __btr


_1B4	db 9		;type_09
	db 014h		;flags
	dw __lfs


_1B5	db 9		;type_09
	db 014h		;flags
	dw __lgs


_1B6	db 13		;type_13
	db 088h		;flag
	dw __movzx


_1B7	db 14		;type_14
	db 009h		;flag
	dw __movzx

_1B8	dw 0,0	;unused opcode
_1B9	dw 0,0	;unused opcode

_1BA	dw 0
	dw 22*32	;intel group 8  opcode 0f,ba  our group 22

_1BB	db 08		;type_08
	db 03h		;flag
	dw __btc


_1BC	db 9		;type_09
	db 004h		;flags
	dw __bsf


_1BD	db 9		;type_09
	db 004h		;flags
	dw __bsr


_1BE	db 13		;type_13
	db 088h		;flag
	dw __movsx


_1BF	db 14		;type_14
	db 009h		;flag
	dw __movsx


_1C0	db 08		;type_08
	db 083h		;flag
	dw __xadd


_1C1	db 08		;type_08
	db 03h		;flag
	dw __xadd

_1C2	dw 0,0	;unused opcode
_1C3	dw 0,0	;unused opcode
_1C4	dw 0,0	;unused opcode
_1C5	dw 0,0	;unused opcode
_1C6	dw 0,0	;unused opcode
_1C7	dw 0,0	;unused opcode

_1C8	db 20		;type_20
	db 2		;code2
	dw __bswap


_1C9	db 20		;type_20
	db 2		;code2
	dw __bswap


_1CA	db 20		;type_20
	db 2		;code2
	dw __bswap


_1CB	db 20		;type_20
	db 2		;code2
	dw __bswap


_1CC	db 20		;type_20
	db 2		;code2
	dw __bswap


_1CD	db 20		;type_20
	db 2		;code2
	dw __bswap


_1CE	db 20		;type_20
	db 2		;code2
	dw __bswap


_1CF	db 20		;type_20
	db 2		;code2
	dw __bswap

_1D0	dw 0,0	;unused opcode
_1D1	dw 0,0	;unused opcode
_1D2	dw 0,0	;unused opcode
_1D3	dw 0,0	;unused opcode
_1D4	dw 0,0	;unused opcode
_1D5	dw 0,0	;unused opcode
_1D6	dw 0,0	;unused opcode
_1D7	dw 0,0	;unused opcode
_1D8	dw 0,0	;unused opcode
_1D9	dw 0,0	;unused opcode
_1Da	dw 0,0	;unused opcode
_1Db	dw 0,0	;unused opcode
_1Dc	dw 0,0	;unused opcode
_1Dd	dw 0,0	;unused opcode
_1De	dw 0,0	;unused opcode
_1Df	dw 0,0	;unused opcode

_1E0	dw 0,0	;unused opcode
_1E1	dw 0,0	;unused opcode
_1E2	dw 0,0	;unused opcode
_1E3	dw 0,0	;unused opcode
_1E4	dw 0,0	;unused opcode
_1E5	dw 0,0	;unused opcode
_1E6	dw 0,0	;unused opcode
_1E7	dw 0,0	;unused opcode
_1E8	dw 0,0	;unused opcode
_1E9	dw 0,0	;unused opcode
_1Ea	dw 0,0	;unused opcode
_1Eb	dw 0,0	;unused opcode
_1Ec	dw 0,0	;unused opcode
_1Ed	dw 0,0	;unused opcode
_1Ee	dw 0,0	;unused opcode
_1Ef	dw 0,0	;unused opcode

_1F0	dw 0,0	;unused opcode
_1F1	dw 0,0	;unused opcode
_1F2	dw 0,0	;unused opcode
_1F3	dw 0,0	;unused opcode
_1F4	dw 0,0	;unused opcode
_1F5	dw 0,0	;unused opcode
_1F6	dw 0,0	;unused opcode
_1F7	dw 0,0	;unused opcode
_1F8	dw 0,0	;unused opcode
_1F9	dw 0,0	;unused opcode
_1Fa	dw 0,0	;unused opcode
_1Fb	dw 0,0	;unused opcode
_1Fc	dw 0,0	;unused opcode
_1Fd	dw 0,0	;unused opcode
_1Fe	dw 0,0	;unused opcode
_1Ff	dw 0,0	;unused opcode

;--------------------------------------------------------------------
; group tables, each table has 8 entries.
;--------------------------------------------------------------------

;---------intel group 1   opcode=80h  our group 1*32
group01:	;intel group 1   opcode=80h  our group 1*32

  db 7		;type_07
  db 0a2h	;flag (see process)
  dw __add	;add rm8,imm8

  db 7		;type_07 (process)
  db 0a2h	;flag (see process)
  dw __or

  db 7		;type_07 (process)
  db 0a2h	;flag (see process)
  dw __adc

  db 7		;type_07 (process)
  db 0a2h	;flag (see process)
  dw __sbb

  db 7		;type_07
  db 0a2h	;flag (see process)
  dw __and

  db 7		;type_07 (process)
  db 0a2h	;flag
  dw __sub	;instruction name

  db 7		;type_07 (process)
  db 0a2h	;flag (see process)
  dw __xor	;instruction name

  db 7		;type_07
  db 0a2h	;flag (see process)
  dw __cmp

;---------intel group 1   opcode=81h  our group 2

  db 10		;type_10
  db 05h	;flag
  dw __add

  db 10		;type_10
  db 05h	;flag
  dw __or

  db 10		;type_10
  db 05h	;flag
  dw __adc

  db 10		;type_10
  db 05h	;flag
  dw __sbb

  db 10		;type_10
  db 05h	;flag
  dw __and

  db 10		;type_10
  db 05h	;flag
  dw __sub

  db 10		;type_10
  db 05h	;flag
  dw __xor

  db 10		;type_10
  db 05h	;flag
  dw __cmp

;---------intel group 1   opcode=82h  our group x*32 (unused ??)


;---------intel group 1   opcode=83h  our group 3

  db 07		;type_07
  db 022h	;flag
  dw __add

  db 07		;type_07
  db 022h	;flag
  dw __or

  db 07		;type_07
  db 022h	;flag
  dw __adc

  db 07		;type_07
  db 022h	;flag
  dw __sbb

  db 07		;type_07
  db 022h	;flag
  dw __and

  db 07		;type_07
  db 022h	;flag
  dw __sub

  db 07		;type_07
  db 022h	;flag
  dw __xor

  db 07		;type_07
  db 022h	;flag
  dw __cmp


;---------intel group 2   opcode=c0h  our group 4

  db 07		;type_07
  db 0a2h	;flag
  dw __rol

  db 07		;type_07
  db 0a2h	;flag
  dw __ror

  db 07		;type_07
  db 0a2h	;flag
  dw __rcl

  db 07		;type_07
  db 0a2h	;flag
  dw __rcr

  db 07		;type_07
  db 0a2h	;flag  
  dw __shl

  db 07		;type_07
  db 0a2h	;flag
  dw __shr

  dd 0	;dummy for unused slot

  db 07		;type_07
  db 0a2h	;flag
  dw __sar


;---------intel group 2   opcode=c1h  our group 5

  db 07		;type_07
  db 022h	;flag
  dw __rol

  db 07		;type_07
  db 022h	;flag
  dw __ror

  db 07		;type_07
  db 022h	;flag
  dw __rcl

  db 07		;type_07
  db 022h	;flag
  dw __rcr

  db 07		;type_07
  db 022h	;flag
  dw __shl

  db 07		;type_07
  db 022h	;flag
  dw __shr

 dd 0	;dummy unused slot

  db 07		;type_07
  db 022h	;flag
  dw __sar


;---------intel group 2   opcode=d0h  our group 6

  db 07		;type_07
  db 0c2h	;flag
  dw __rol

  db 07		;type_07
  db 0c2h	;flag
  dw __ror

  db 07		;type_07
  db 0c2h	;flag
  dw __rcl

  db 07		;type_07
  db 0c2h	;flag
  dw __rcr

  db 07		;type_07
  db 0c2h	;flag
  dw __shl

  db 07		;type_07
  db 0c2h	;flag
  dw __shr

  dd 0	;dummy for unused slot

  db 07		;type_07
  db 0c2h	;flag
  dw __sar

;---------intel group 2   opcode=d1h  our group 7

  db 07		;type_07
  db 042h	;flag
  dw __rol

  db 07		;type_07
  db 042h	;flag
  dw __ror

  db 07		;type_07
  db 042h	;flag
  dw __rcl

  db 07		;type_07
  db 042h	;flag
  dw __rcr

  db 07		;type_07
  db 042h	;flag
  dw __shl

  db 07		;type_07
  db 042h	;flag
  dw __shr

  dd 0  ;dummy for unused slot

  db 07		;type_07
  db 042h	;flag
  dw __sar


;---------intel group 2   opcode=d2h  our group 8
 
  db 11		;type_11
  db 086h	;flag
  dw __rol

  db 11		;type_11
  db 086h	;flag
  dw __ror

  db 11		;type_11
  db 086h	;flag
  dw __rcl

  db 11		;type_11
  db 086h	;flag
  dw __rcr

  db 11		;type_11
  db 086h	;flag
  dw __shl

  db 11		;type_11
  db 086h	;flag
  dw __shr

  dd 0	;dummy for unused slot

  db 11		;type_11
  db 086h	;flag
  dw __sar


;---------intel group 2   opcode=d3h  our group 9

  db 11		;type_11
  db 006h	;flag
  dw __rol

  db 11		;type_11
  db 006h	;flag
  dw __ror

  db 11		;type_11
  db 006h	;flag
  dw __rcl

  db 11		;type_11
  db 006h	;flag
  dw __rcr

  db 11		;type_11
  db 006h	;flag
  dw __shl

  db 11		;type_11
  db 006h	;flag
  dw __shr

  dd 0 ;dummy for unused slot

  db 11		;type_11
  db 006h	;flag
  dw __sar


;---------intel group 3   opcode=f6h  our group 10*32

  db 07		;type_07
  db 0a2h	;flag
  dw __test

; db dummy for mod/rm 04
  dd 0

  db 6		;type_06
  db 80h	;80h=byte flag
  dw __not	;not rm8

  db 6		;type_06
  db 80h	;80h=byte flag
  dw __neg	;neg rm8

  db 6		;type_06
  db 80h	;80h=byte flag
  dw __mul	;mul rm8

  db 6		;type_06
  db 80h	;80h=byte flag
  dw __imul	;imul rm8

  db 6		;type_06
  db 80h	;80h=byte flag
  dw __div	;div rm8

  db 6		;type_06
  db 80h	;80h=byte flag
  dw __idiv	;idiv rm8

;---------intel group 3   opcode=f7h  our group 11

  db 10		;type_10
  db 00h	;flag
  dw __test

; dummy for mod/rm 04
  dd 0

  db 6		;type_06
  db 00h	;flag
  dw __not

  db 6		;type_06
  db 00h	;flag
  dw __neg

  db 6		;type_06
  db 0		;flag
  dw __mul

  db 6		;type_06
  db 0		;flag
  dw __imul

  db 6		;type_06
  db 0		;flag
  dw __div

  db 6		;type_06
  db 0		;flag
  dw __idiv


;---------intel group 4   opcode=feh  our group 12*32

  db 6	;type_06
  db 80h	;80=byte operation flag
  dw __inc	;inc rm8

  db 6	;type_06
  db 80h	;80=byte operation
  dw __dec	;dec rm8

  dd 0	;dummy for unused slot
  dd 0	;dummy for unused slot
  dd 0	;dummy for unused slot
  dd 0	;dummy for unused slot
  dd 0	;dummy for unused slot
  dd 0	;dummy for unused slot

;---------intel group 5   opcode=ffh  our group 13

  db 6		;type_06
  db 0		;flag
  dw __inc

  db 6		;type_06
  db 0		;flag
  dw __dec

  db 6		;type_06
  db 0		;flag
  dw __call

  db 6		;type_06
  db 0		;flag
  dw __call

  db 6		;type_06
  db 0		;flag
  dw __jmp

  db 6		;type_06
  db 0		;flag
  dw __jmp

  db 6		;type_06
  db 0		;flag
  dw __push

; dummy for mod/rm 1c
 dd 0

;---------intel float    opcode=d8h  our group 14

  db 22		;type_22
  db 0		;unused
  dw __fadd

  db 22		;type_22
  db 0
  dw __fmul

  db 22		;type_22
  db 0		;unused
  dw __fcom

  db 22		;type_22
  db 0		;unused
  dw __fcomp

  db 22		;type_22
  db 0		;unused
  dw __fsub

  db 22		;type_22
  db 0		;unused
  dw __fsubr

  db 22		;type_22
  db 0		;unused
  dw __fdiv

  db 22		;type_22
  db 0		;unused
  dw __fdivr

;---------intel float    opcode=d9h  our group 15

  db 23		;type_23
  db 0		;
  dw __fld

  db 23		;type_23
  db 04h	;
  dw __fnop

  db 23		;type_23
  db 08h	;
  dw __fst

  db 23		;type_23
  db 0ch	;
  dw __fstp

  db 23		;type_23
  db 10h	;
  dw __fldenv

  db 23		;type_23
  db 14h	;
  dw __fldcw

  db 23		;type_23
  db 18h	;
  dw __fnstenv

  db 23		;type_23
  db 1ch	;
  dw __fnstcw

;---------intel float    opcode=dah  our group 16

  db 24		;type_24
  db 0
  dw __fiadd

  db 24		;type_24
  db 4		;unused
  dw __fimul

  db 24		;type_24
  db 8h		;unused
  dw __ficom

  db 24		;type_24
  db 0ch	;unused
  dw __ficomp

  db 24		;type_24
  db 10h	;unused
  dw __fisub

  db 24		;type_24
  db 14h	;unused
  dw __fisubr

  db 24		;type_24
  db 18h	;unused
  dw __fidiv

  db 24		;type_24
  db 1ch	;unused
  dw __fidivr


;---------intel float    opcode=dbh  our group 17

  db 25		;type_25
  db 00		;unused
 dw __fild

  db 25		;type_25
  db 04h	;unused
 dw __nop

  db 25		;type_25
  db 08h	;unused
  dw __fist

  db 25		;type_25
  db 0ch	;unused
  dw __fistp

  db 25		;type_25
  db 10h	;unused
  dw __nop

  db 25		;type_25
  db 14h	;unused
  dw __fld


  db 25		;type_25
  db 18h	;not used
  dw __nop

  db 25		;type_25
  db 1ch	;unused
  dw __fstp

;---------intel float    opcode=dch  our group 18

  db 26		;type_26
  db 0		;not used
  dw __fadd

  db 26		;type_26
  db 04h	;not used
  dw __fmul

  db 26		;type_26
  db 08h	;not used
  dw __fcom

  db 26		;type_26
  db 0ch	;not used
  dw __fcomp

  db 26		;type_26
  db 10h	;not used
  dw __fsub

  db 26		;type_26
  db 14h	;not used
  dw __fsubr

  db 26		;type_26
  db 18h	;not used
  dw __fdiv

  db 26		;type_26
  db 1ch	;not used
  dw __fdivr

;---------intel float    opcode=ddh  our group 19

  db 27		;type_27
  db 0		;
  dw __fld

  db 27		;type_27
  db 4		;
  dw __fnop

  db 27		;type_27
  db 08h	;
  dw __fst

  db 27		;type_27
  db 0ch	;
  dw __fstp

  db 27		;type_27
  db 10h	;
  dw __frstor

  db 27		;type_27
  db 14h	;
  dw __fnop

  db 27		;type_27
  db 18h	;
  dw __fnsave

  db 27		;type_27
  db 1ch	;
  dw __fnstsw

;---------intel float    opcode=deh  our group 20

  db 28		;type_28
  db 0
  dw __fiadd

  db 28		;type_28
  db 04h	;
  dw __fimul

  db 28		;type_28
  db 08h	;
  dw __ficom

  db 28		;type_28
  db 0ch
  dw __ficomp

  db 28		;type_28
  db 10h
  dw __fisub

  db 28		;type_28
  db 14h
  dw __fisubr

  db 28		;type_28
  db 18h
  dw __fidiv

  db 28		;type_28
  db 1ch
  dw __fidivr

;---------intel float    opcode=dfh  our group 21

  db 29		;type_29
  db 0
  dw __fild

  db 29		;type_29
  db 04h	;
  dw __fnop

  db 29		;type_29
  db 08h	;
  dw __fist

  db 29		;type_29
  db 0ch	;
  dw __fistp

  db 29		;type_29
  db 10h
  dw __fbld

  db 29		;type_29
  db 14h
  dw __fild

  db 29		;type_29
  db 18h
  dw __fbstp

  db 29		;type_29
  db 1ch
  dw __fistp

;---------intel group 8    opcode=0f,ba  our group 22

; dummy mod/rm 00
 dd 0

; dummy mod/rm 01
 dd 0

; dummy mod/rm 02
 dd 0

; dummy mod/rm 03
 dd 0

  db 07		;type_07
  db 022h	;flag
  dw __bt

  db 07		;type_07
  db 022h	;flag
  dw __bts

  db 07		;type_07
  db 022h	;flag
  dw __btr

  db 07		;type_07
  db 022h	;flag
  dw __btc


