  [section .text]
;*********** type_11  ****************
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

;-------------------------------------type_s06_6------------
;
; opcode  prefix      operand                         prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
;  d2 rcl         2    t6_rm8_cl (rm8,cl)
;  d2 rcr         3
;  d2 rol         0
;  d2 ror         1
;  d2 sar         7
;  d2 shl         4
;  d2 shr         5
;
;  d3 rcl   p     2    t6_rm32_cl (rm8,cl)
;  d3 rcr   p     3
;  d3 rol   p     0
;  d3 ror   p     1
;  d3 sar   p     7
;  d3 shl   p     4
;  d3 shr   p     5

type_s11:
  call	decode_rm
  mov	al,','
  stosb
  mov	bl,1		;code for cl
  mov	bh,-3		;get byte register type code
  call	stuff_reg
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
  ret
