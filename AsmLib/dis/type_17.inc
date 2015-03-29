  [section .text]
;*********** type17 ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=??
;                                 x=??
;                                 y=process index
;              db flags  80h = prefix legal
;                        40h = "in" instruction
;                        20h = imm8
;                        10h = "out" instruction
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;
;------------------------------------------------------------------

;------------------------------------------------------------------
;type s17

; opcode  prefix
;         flag  
; ------  ------
;14 adc         adc al,imm8 (g1) 
;15 adc    p    adc ax/eax imm (g4)
;04 add         add al,imm8 (g1)
;05 add    p    add ax/eax imm (g4)
;24 and         and al,imm8 (g1)
;25 and    p    and ax/eax imm (g4)
;3c cmp         cmp al,imm8 (g1)
;3d cmp    p    cmp ax/eax imm (g4)
;0c or          or  al,imm8 (g1)
;0d or     p    or  ax/eax imm (g4)

;e4 in          in al,imm8 (g5)
;e5 in     p    in ax/eax,imm8 (g5)
;ec in          in al,dx (g2)
;ed in     p    in ax/eax,dx (g2)

;e6 out         out imm8,al (g6)
;e7 out    p    out imm8,ax/eax (g6)
;ee out         out dx,al (g3)
;ef out    p    out dx,ax/eax (g3)


type_s17:

  mov	al,[edx+1]		;get operand flags
  test	al,40h			;is this an "in" inst
  jnz	t07_4			;jmp if "in"
  test	al,10h			;is this a "out" instruction
  jnz	t07_0			;jmp if 'out' instruction
  jmp	t07_18			;jmp if not "out"
;--------------
;this is a "out" instruction
t07_0:
  test	al,20h			;is first operand an imm8
  jz	t07_2			;jmp if not imm8
  xor	ebx,ebx
  mov	bl,[ebp + 1]		;get imm8
  call	bin_to_hexascii_h
;check if imm8,al
  inc	ebp
  jmp	t07_3
;this is a "out" with "dx" as first operand
t07_2:
  mov	ax,'dx'
  stosw

t07_3:
  inc	ebp
  test	byte [edx+1],80h	;is prefix legal (ax/eax)
  jnz	t07_1			;jmp if (ax/eax)
  mov	eax,',al '
  stosd
  jmp	t07_17

t07_1:
  mov	eax,',ax '
  test	byte [state_flag],10h	;is prefix active
  jnz	t07_1a			;jmp if prefix active
  mov	eax,',eax'
t07_1a:
  stosd
  jmp	t07_17			;done
;-------------
;in instruction
t07_4:
  test	byte [edx+1],80h	;is prefix legal?
  jz	t07_6			;jmp if no prefix, must be "al"
;first operand is ax or eax
  mov	eax,'ax, '
  test	byte [state_flag],10h	;is prefix active
  jnz	t07_5			;jmp if prefix active (ax)
  mov	eax,'eax,'
t07_5:
  stosd
  jmp	short t07_10

;first operand is al
t07_6:
  mov	eax,"al, "
  stosd

;do second operand for in instructions

t07_10:
  test	byte [edx+1],20h	;is this a imm8
  jz	t07_12			;jmp if not imm8
  xor	ebx,ebx
  mov	bl,[ebp + 1]		;get imm8
  call	bin_to_hexascii_h
;check if imm8,al
  add	ebp,2
  jmp	t07_17			;done

t07_12:
  mov	ax,'dx'
  stosw
  inc	ebp
t07_17:
  or	byte [instruction_type],04h
  jmp	t07_90	  


;non in/out instruction
t07_18:
  test	byte [edx+1],80h	;check if prefix legal
  jnz	t07_19			;jmp if ax/eax
  mov	eax,'al, '
  stosd
  xor	ebx,ebx
  mov	bl,[ebp + 1]		;get imm8
  call	bin_to_hexascii_h
  add	ebp,2
  jmp	short t07_90


t07_19:
  test	byte [state_flag],10h	;is prefix active
  jz	t07_20			;jmp if no active prefix
  mov	eax,'ax, '
  stosd
  xor	ebx,ebx
  mov	bx,[ebp + 1]		;get imm8
  call	bin_to_hexascii_h
  add	ebp,3
  jmp	short t07_90

t07_20:
  mov	eax,'eax,'
  stosd
  mov	ebx,[ebp + 1]		;get imm8
  call	bin_to_hexascii_h
  add	ebp,5
  jmp	short t07_90


t07_90:
  mov	al,0ah
  stosb
  mov	al,090h
  ret 
