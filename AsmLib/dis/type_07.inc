  [section .text]
;*********** type_07  ****************
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
;------------------------------------------------------------------
;the flag is set as follows:
;t1_rm8_bi	equ	80h + 20h + 02h		;byte + immediate + optype=2
;t1_rm32_i	equ	      20h + 02h		;word/dword + immediate + optype=2
;t1_rm8_bc	equ	80h + 40h + 02h		;byte + constant1 + optype=2
;t1_rm32_c	equ	      40h + 02h		;word/dword + constant1 + optype=2
;---------------------------------------------------------------------
;
; opcode  prefix      operand                         prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
; 80  adc          2  t1_rm8_bi     adc rm8,imm8 
; 80  add          0
; 80  and          4
; 80  cmp          7
; 80  or           1
; 80  sbb          3
; 80  sub          5
; 80  xor          6
;
; c0  rcl          2
; c0  rcr          3
; c0  rol          0
; c0  ror          1
; c0  sar          7
; c0  shl          4
; c0  shr          5
;
; c6  mov          0
; f6  test         0
;
; 83  adc          2  t1_rm32_i    adc rm32,imm8
; 83  add          0
; 83  and          4
; 83  cmp          7
; 83  or           1
; 83  sbb          3
; 83  sub          5
; 83  xor          6
;
; c1  rcl          2
; c1  rcr          3
; c1  rol          0
; c1  ror          1
; c1  sar          7
; c1  shl          4
; c1  shr          5
;
;0fba bt           4
;0fba btc          7
;0fba btr          6
;0fba bts          5
;
; d0  rcl          2	t1_rm8_bc   rcl  bl,1
; d0  rcr          3
; d0  rol          0
; d0  ror          1
; d0  sar          7
; d0  shl          4
; d0  shr          5
;
; d1  rcl          2	t1_rm32_c   rcl  ebx,1
; d1  rcr          3                rcr  bx,1
; d1  rol          0
; d1  ror          1
; d1  sar          7
; d1  shl          4
; d1  shr          5
;


type_s07:
  mov	al,byte [ebp]		;get opcode
;check for opcodes not assembled by nasm
  cmp	al,80h
  je	t6_2_1
  cmp	al,83h
  jne	t6_2_9
t6_2_1:
  mov	al,byte [ebp +1]	;get modrm byte
  and	al,07h			;isolate register
  jnz	t6_2_9			;jmp if not al,eax register
  or	byte [warn_flag],1	;force db hex string
t6_2_9:
  call	decode_rm
  mov	al,','
  stosb
;check if constant one
  xor	ebx,ebx
  mov	bl,1			;preload "1" incase constant 1 type
  test	byte [edx+1],40h
  jnz	t06_02_10		;jmp if constant 1
  mov	eax,'byte'
  stosd
  mov	al,' '
  stosb
  xor	ebx,ebx
  mov	bl,[ebp]
  inc	ebp
t06_02_10:
  call	bin_to_hexascii_h
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
  ret

