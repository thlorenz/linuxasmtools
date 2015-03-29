  [section .text]
;*********** type_08  ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=??
;                                 x=??
;                                 y=process index
;              db flag 80h = byte
;                      40h = constant 1
;                      20h = op is immediate
;                      10h = special les,lds instruction
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;
;
; the flag contains following
; t3_rm8_b_	equ	80h       +03h          ;byte             +optype=3 (rm8,regs)
; t3_rm32       equ               +03h          ;                  optype=3 (rm32,regs)

;-----------------------------------------------------------
;
; opcode  prefix      operand                         prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
; 10  adc          -  t3_rm8_b        adc rm8,reg8 
; 00  add          -  t3_rm8_b
; 20  and
; 38  cmp
;0fb0 cmpxchg
; 88  mov
; 08  or
; 18  sbb
; 28  sub
; 84  test
;0fc0 xadd
; 30  xor
;
type_s08:
  mov	bl,[ebp+1]	;get mod/rm byte
  push	ebx
  call	decode_rm
  mov	al,','
  stosb
;extract register
  pop	ebx
  shr	ebx,3
  and	bl,7h		;isolate register code
  test	byte [edx+1],80h;is this a byte register
  jnz	t06_3_20	;jmp if byte register
;check if prefix register adjust
  mov	bh,-1		;get normal register select
  test	byte [state_flag],10h ;prefix flag set
  jz	t06_3_10		;jmp if prefix not set  (dword)
  mov	bh,-2
t06_3_10:
  jmp	short t06_3_50

t06_3_20:
  mov	bh,-3		;get byte register type code
t06_3_50:
  call	stuff_reg
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
  ret

  [section .text]
