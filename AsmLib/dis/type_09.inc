  [section .text]
;*********** type_09  ****************
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
;-------------------------------------------------
;
; opcode  prefix      operand                         prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
;  12 adc   -         t04_rm8   (reg8,rm8)
;  02 add
;  22 and
;  3a cmp
;  0a or
;  1a sbb
;  2a sub
;  86 xchg
;  32 xor
;
;  8a mov   P
;  13 adc   p         t4_rm32 (reg32,rm32)
;  03 add   p
;  23 and   p
;0fbc bsf   p
;0fbd bsr   p
;0f47 cmova p
;0f42 cmovc p
;0f44 cmove p
;0f4f cmovg p
;0f4c cmovl p
;0f4e cmovle p
;0f46 cmovna p
;0f43 cmovnc p
;0f45 cmovne p
;0f4d cmovnl p
;0f41 cmovno p
;0f4b cmovnp p
;0f49 cmovns p
;0f40 cmovo p
;0f4a cmovp p
;0f48 cmovs p
;  3b cmp   p
;0faf imul  p
;0f02 lar   p
;
;  c5 lds   p
;  c4 les   p
;0fb4 lfs   p
;0fb5 lgs   p
;0fb2 lss   p
;
;0f03 lsl   p   
;  8b mov   p
;  0b or    p
;  1b sbb   p
;  2b sub   p
;  87 xchg  p
;  33 xor   p
;
;  8d lea   p
;  62 bound p
;
;special flag, byte two of decode table, bits modrm(3ch) set to 1 if lds,les,lss,etc.
;              this is a special case where reg,reg isn't legal and no "byte,word,.."
;              is needed.

type_s09:
  mov	bl,[ebp+1]	;get mod/rm byte
  mov	al,bl
  test	byte [edx+1],10h ;special case flag set, lds,les,etc. remove byte,word
  jz	t06_4_06	;jmp if not special case
;if this is a mod=11 then error
  and	al,0c0h		;isolate mod byte
  cmp	al,0c0h		;is this a reg,reg decoding
  jne	t06_4_06	;jmp if not reg,reg
  or	byte [error_flag],1
  jmp	t06_4_60

t06_4_06:
  and	al,0c0h		;isolate mod bits
  cmp	al,0c0h		;is this a reg,reg decoding
  jne	t06_4_07	;jmp if not  reg,reg
  cmp	byte [ebp],8bh	;is this a 'mov'
  je	t06_4_6a	;jmp if 'mov'
  cmp	byte [ebp],3ah
  ja	t06_4_07	;jmp if not correct opcode value
  cmp	byte [ebp],2	;is this a 'lar' or 'add'
  jne	t06_4_6a	;jmp if not 'lar' or 'add'
  test	byte [state_flag],40h	;escape prefix?
  jnz	t06_4_07	;jmp if lar
t06_4_6a:
  or	byte [warn_flag],1	;set flag to convert inst. to db

t06_4_07:
;extract register
  shr	ebx,3
  and	bl,7h		;isolate register code
  test	byte [edx+1],80h;is this a byte register
  jnz	t06_4_20	;jmp if byte register
;check if prefix register adjust
  mov	bh,-1		;get normal register select
  test	byte [state_flag],10h ;prefix flag set
  jz	t06_4_10		;jmp if prefix not set  (dword)
  mov	bh,-2
t06_4_10:
  jmp	short t06_4_50
t06_4_20:
  mov	bh,-3		;get byte register type code
t06_4_50:
  call	stuff_reg
  mov	al,','
  stosb
  call	decode_rm
  test	byte [edx+1],10h ;special case flag set, lds,les,etc. remove byte,word
  jz	t06_4_60	;jmp if not special case
  mov	byte [edi],0
  mov	esi,inst
  mov	edi,esi
t06_4_lp1:
  lodsb
  stosb
  cmp	al,','
  jne	t06_4_lp1
t06_4_lp2:
  lodsb
  cmp	al,' '
  jne	t06_4_lp2
t06_4_lp3:
  stosb
  lodsb
  cmp	al,0
  jne	t06_4_lp3
t06_4_60:
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
  ret
