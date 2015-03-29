  [section .text]
;*********** type19 ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=??
;                                 x=??
;                                 y=process index
;              db flags  01h = code1
;                        02h = code2
;                        03h = code3
;                        04h = code4
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;


;------------------------------------------------------------------
;type s19

; opcode          prefix 
;                 flag   
; ------           ------ 
; d5 aad imm8        -        s09,1
; d4 aam imm8        -
; cd int imm8
; 6a push imm8
;
; 1c sbb al,imm8              s09,2
; 2c sub al,imm8
; a8 test al,imm8
; 34 xor al,imm8
;
; 1d sbb ax/eax imm16/32   p  s09,3
; 2d sub ax/eax imm16/32   p
; a9 test ax/eax imm16/32  p
; 35 xor ax/eax imm16/32   p
; 68 push  imm16/32        p  s09,3
;
; ca ret imm16                s09,4
; c2 ret imm16                
; 
type_s19:
;
;decode flag field
  mov	al,[edx+1]	;get flag field
;  shr	al,2
;  and	al,0fh		;isolate field (s09,1 ,2 ,3 ,4)
  xor	ebx,ebx
  cmp	al,2
  jb	t9_1		;jmp if type1
  je	t9_2
  cmp	al,4
  jb	t9_3
;must be type 4 (ret imm16)
  mov	bx,[ebp+1]
  call	bin_to_hexascii_h
  add	ebp,byte 3
  or	byte [instruction_type],8 ;set jump flag
  jmp	short t9_2_10  

;type=1 (aad imm8)
t9_1:
  mov	eax,'byte'
  stosd
  mov	al,' '
  stosb
  mov	bl,[ebp+1]
  call	bin_to_hexascii_h
  cmp	byte [ebp],0cdh
  ja	t9_1_10			;jmp if not int imm8/push imm8
  or	byte [warn_flag],8	;set unusual instruction flag
t9_1_10:
  add	ebp,byte 2
  jmp	short t9_2_10
;
; type =2 (sbb al,imm8,  sub al,imm8,   etc.)
;
t9_2:
  mov	eax,'al,0'
  stosd
  mov	bl,[ebp+1]
  call	bin_to_hexascii_h
  add	ebp,byte 2
t9_2_10:
  mov	al,80h			;exit code
  jmp	short t9_90  
;
; type =3 (push ax/eax,imm8/32) 
;
t9_3:
  cmp	byte [ebp],68h		;is this a imm push
  je	t9_3_5			;jmp if "push"
  mov	eax,'eax,'
  test	byte [state_flag],10h	;check prefix 66h state
  jz	t9_3_4a			;jmp if prefix flag inactive
  mov	eax,' ax,'
t9_3_4a:
  stosd

t9_3_5:
  mov	ebx,[ebp+1]
  test	byte [state_flag],10h
  jnz	t9_3_6			;jmp if prefix flag found (word operation)
  mov	al,20h			;immediate data
  call	process_operand_address
  add	ebp,5
  mov	al,90h			;exit code
  jmp	short t9_90

t9_3_6:
  cmp	byte [ebp],68h		;is this a "push imm16"
  jne	t9_3_10			;jmp if not "push imm16"
  or	byte [warn_flag],8
t9_3_10:
  mov	eax,'word'
  stosd
  mov	al,' '
  stosb
  xor	ebx,ebx
  mov	bx,[ebp+1]
  add	ebp,3
  jmp	short t9_3_20

t9_3_15:
  add	ebp,5
t9_3_20:
  call	bin_to_hexascii_h
  mov	al,90h			;exit code

t9_90:
  push	eax
  mov	al,0ah
  stosb				;put eol at end of line
  pop	eax
  ret

;------------------------------------------------------------------
