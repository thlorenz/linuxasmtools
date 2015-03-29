  [section .text]
;*********** type_12  ****************
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

;-------------------------------------type_s06_7------------
;
; opcode  prefix      operand                         prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
;0fa4 shld  p         rm32,reg32,imm8   operand=27h
;0fa5 shld  p         rm32,reg32,cl     operand=47h
;0fac shrd  p         rm32,reg32,imm8   operand=27h
;0fad shrd  p         rm32,reg32,cl     operand=47h

type_s12:
  mov	bl,[ebp+1]	;get modrm byte
  push	ebx
  call	decode_rm
  mov	al,','
  stosb
  pop	ebx		;restore modrm byte
  shr	bl,3
  and	bl,07h		;isolate register code
  test	byte [state_flag],10h	;prefix 66h active?
  mov	bh,-1		;get code for eax,ecx,etc.
  jz	t06_07_10	;jmp if 32bit register
  mov	bh,-2		;get code for ax,cx,etc.
;32bit register mode
t06_07_10:
  call	stuff_reg
  mov	al,','
  stosb
  test	byte [edx+1],20h ;check if immedate inst
  jnz	t06_07_30	;jmp if immediate byte follows
;shift count in register cl
  mov	bl,1		;code for cl
  mov	bh,-3		;get byte register type code
  call	stuff_reg
  jmp	short t06_07_60
;immediate byte follows instruction
t06_07_30:
  xor	ebx,ebx
  mov	bl,[ebp]	;get immediate shift value
  inc	ebp
  call	bin_to_hexascii_h
t06_07_60:  
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
  ret

  [section .text]
