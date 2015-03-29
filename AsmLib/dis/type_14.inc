  [section .text]
;*********** type_14  ****************
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

;-------------------------------------type_s06_9------------
;
; opcode  prefix      operand                         prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
;0fbf movsz           reg32 rm16
;0fb7 movzx           reg32 rm16

type_s14:
  test	byte [state_flag],10h	;prefix is error
  mov	al,80h			;preload done code
  jnz	t06_9_exit
  xor	ebx,ebx
  mov	bl,[ebp+1]	;get modrm byte
  shr	ebx,3
  and	bl,7h		;isolate register code
  mov	bh,-1		;get normal register select
  call	stuff_reg
  mov	al,','
  stosb
  or	byte [state_flag],10h	;set prefix flag
  call	decode_rm
  and	byte [state_flag],~10h	;remove prefix flag
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
t06_9_exit:
  ret

  [section .text]
