  [section .text]
;*********** type_15  ****************
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

;-------------------------------------type_s06_10 ------------
;
; opcode  prefix      operand                         prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
;  6b imul            reg32/16 rm32/16 imm8

type_s15:
  xor	ebx,ebx
  mov	bl,[ebp+1]	;get modrm byte
  shr	ebx,3
  and	bl,7h		;isolate register code
;check if prefix register adjust
  mov	bh,-1
  test	byte [state_flag],10h
  jz	t06_10_10
  mov	bh,-2		;get normal register select
t06_10_10:
 call	stuff_reg
  mov	al,','
  stosb
  call	decode_rm
  mov	al,','
  stosb
  mov	eax,'byte'
  stosd
  mov	al,' '
  stosb
  xor	ebx,ebx		
  mov	bl,[ebp]
  inc	ebp
  call	bin_to_hexascii_h
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
  ret

  [section .text]
