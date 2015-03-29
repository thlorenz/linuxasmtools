  [section .text]
;*********** type_10  ****************
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

;-------------------------------------type_s06_5------------
;
; opcode  prefix      operand                         prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
;  81 adc          2   t5_rm32_i (rm32,imm32)
;  81 add          0
;  81 and          4
;  81 cmp          7
;  c7 mov          0
;  81 or           1
;  81 sbb          3
;  81 sub          5
;  f7 test         0
;  81 xor          6


type_s10:
;check for special instructions which nasm will not assemble
  mov	al,[ebp+1]		;get modrm byte
  mov	bl,al
  and	al,0c0h			;isolate mod
  cmp	al,0c0h			;is this a mod=3
  jne	t06_05_0		;jmp if not mod=3
;if mod=3 and "mov" instruction then set flag
  cmp	byte [ebp],0c7h		;mov?
  je	t06_05_x		;jmp if mov instruction
;if mod=3 and register=eax then set flag
  and	bl,7h			;isolate register field
  or	bl,bl			;check if eax
  jnz	t06_05_0		;jmp if not eax
t06_05_x:
  or	byte [warn_flag],1	;set flag to convert inst. to db

t06_05_0:
  call	decode_rm
  mov	al,','
  stosb
  test	byte [state_flag],10h	;prefix 66h?
  jnz	t06_05_1		;jmp if word operation
  mov	eax,'dwor'
  stosd
  mov	al,'d'
  stosb
  mov	ebx,[ebp]		;get operand
  mov	al,20h			;imm32 data
  stosb				;store space
  call	process_operand_address
  add	ebp,4
  jmp	short t06_05_20
t06_05_1:
  mov	eax,'word'
  stosd
  xor	ebx,ebx
  mov	bx,[ebp]
  add	ebp,byte 2    
t06_05_10:
  mov	al,' '
  stosb
  call	bin_to_hexascii_h
t06_05_20:
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
  ret

  [section .text]
