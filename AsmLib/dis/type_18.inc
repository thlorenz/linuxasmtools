  [section .text]
;*********** type18 ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=??
;                                 x=??
;                                 y=process index
;              db flags  01h = rel8
;                        02h = rel32
;                        03h = rel32 +
;                        04h = jcxz
;                        05h = far call/jmp
;                        06h = rel8, loop,loopne,loope
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;
;------------------------------------------------------------------

;------------------------------------------------------------------
;type s18

; opcode  prefix 
;         flag   
; ------  ------ 
;  70 jo    -    type=1 (edx+1, bits 3ch)  rel8
;  71 jno
;  72 jb
;  73 jnb
;  74 jz
;  75 jnz
;  76 jbe
;  77 ja
;  78 js
;  79 jns
;  7a jp
;  7b jnp
;  7c jl
;  7d jnl
;  7e jle
;  7f jg
;  eb jmp
;
;0f80 jo    -    type=2 (edx+1, bits 3ch)     rel32
;0f81 jno
;0f82 jb
;0f83 jnb
;0f84 jz
;0f85 jnz
;0f86 jbe
;0f87 ja
;0f88 js
;0f89 jns
;0f8a jp
;0f8b jnp
;0f8c jl
;0f8d jnl
;0f8e jle
;0f8f jg
;
;  e9 jmp  near  type=3
;  e8 call near
;
;  e3 jcxz       type=4
;
;  ea jmp far    type=5
;  9a call far      
;
;  e0 loopne	;type=6
;  e1 loope
;  e2 loop
; 
type_s18:
;decode flag field
  mov	al,[edx+1]	;get flag field
;  shr	al,2
;  and	al,0fh		;isolate field 1=rel8 2=rel32 3=rel32(no 0f) 4=jcxz 5=jmp far
  xor	ebx,ebx
  cmp	al,2
  jb	t08_rel8
  ja	t08_04
  jmp	t08_rel32
t08_04:
  cmp	al,4
  jb	t08_06		;jmp t08_rel32_jmp
  jne	t08_10
  jmp	t08_jcxz
;;  jmp	t08_loop
t08_06:
  jmp	t08_rel32_jmp
t08_10:
  cmp	al,6
  je	t08_loop
;this must be jmp far (opcode=0eah)              type=5
; instruction form is jmp xxx:xxx  length is 7
  xor	ebx,ebx
  mov	bx,[ebp+5]
  call	bin_to_hexascii_h
  mov	al,':'
  stosb
  mov	ebx,[ebp+1]
  mov	al,1				;jmp operand
  call	process_operand_address
  or	byte [warn_flag],8h
  mov	ah,[ebp]			;get opcode
  mov	al,8				;pre load code for jmp
  cmp	ah,0eah				;jmp instruction?
  je	t08_11
  mov	al,0				;if call the instruction_type=0
t08_11:
  or	byte [instruction_type],al
  mov	al,02h				;preload call flag
  cmp	byte [ebp],9ah			;is this a call instruction
  je	t08_12				;jmp if call
  mov	al,01
t08_12:
  mov	[operand_type],al
  add	ebp,byte 7
  mov	al,80h			;exit code
  jmp	t08_90  

;near conditional jumps                          type=1
t08_rel8:
  mov	eax,'shor'
  stosd
  mov	ax,'t '
  stosb
t08_loop:
  mov	al,[ebp+1]
  cbw
  cwde
  mov	ebx,eax
  mov	cl,2
  call	stuff_rel
  mov	ah,[ebp]		;get op code
  add	ebp,byte 2
  mov	al,80h			;exit code
  cmp	ah,0ebh			;check if jmp near
  je	t08j			;jmp if jmp near
  jmp	t08_90

;rel32 conditional jumps                          type=2
t08_rel32:
  mov	eax,'near'
  stosd
  mov	al,' '
  stosb
  mov	ebx,[ebp+1]
  mov	cl,6
  call	stuff_rel
  add	ebp,byte 5
  mov	al,0c0h			;exit code
  jmp	short t08_90

;jmp rel32                                        type=3
t08_rel32_jmp:
  mov	eax,'near'
  stosd
  mov	ebx,[ebp+1]
  mov	cl,5
  call	stuff_rel
  mov	ah,[ebp]		;get op code
  add	ebp,byte 5
  mov	al,080h			;exit code
  mov	cl,01h			;preload operand_type for jmp
  cmp	ah,0e8h			;is this a call
  je	t08_rel32_10		;jmp if call (instruction_type=0 operand_type=2
;this is a jmp, set instruction_type=08 operand_type=1
  mov	byte [operand_type],1
t08j:
  jmp	short t08_89
;this is a call, set instruction_type=0 operand_type=2
t08_rel32_10:
  mov	byte [operand_type],2
  jmp	short t08_88

;jcxz rel32, and rel8 with prefix 67h              type=4
t08_jcxz:
  test	byte [state_flag],08h	;67h prefix active
  jz	t08_jcxz_2		;jmp if prefix acitive (jcxz)
;this is a jecxz
  mov	eax,'jcxz'
  mov	[edi-6],eax
  mov	[edi-2],byte ' '
  mov	cl,3			;3 byte adjust
  jmp	short t08_jcxz_3
;  mov	ebx,[ebp+1]
;  mov	cl,2
;  jmp	short t08_jcxz_4
t08_jcxz_2:
  mov	cl,2
t08_jcxz_3:
  mov	al,[ebp+1]
  cbw
  cwde
  mov	ebx,eax
t08_jcxz_4:
 call	stuff_rel  
  add	ebp,byte 2
;  test	byte [state_flag],08h
;  jnz   t08_jcxz_6
;  add	ebp,byte 2
t08_jcxz_6:
  mov	al,088h			;exit code
  jmp	short t08_90

t08_89:
  or	byte [instruction_type],8  ;set jmp bit
t08_88:
  and	byte [instruction_type],~2 ;remove relative jmp bit
t08_90:
  push	eax
  mov	al,0ah
  stosb				;put eol at end of line
  pop	eax
  ret

;------------------------------------------------------------------
; inputs:  cl  = adjustment to ebx for instruction size
;          ebx = rel8 or rel32 (sign extended)
;
stuff_rel:
  push	ebx		;save address adjustment
  mov	al,cl		;convert cl
  cbw
  cwde			;  to word value
  mov	ecx,eax

  mov	[stuff_sv1],edi		;save stuff point
  mov	ax,' $'
  stosw
  or	ebx,ebx
  js	sr_40		;jmp if negative
  add	ebx,ecx
  mov	al,'+'
  stosb
  jmp	short sr_50
sr_40:
  mov	al,'-'
  stosb
  neg	ebx 
  sub	ebx,ecx
sr_50:
  call	bin_to_hexascii_h
  pop	ebx
;  or	ebx,ebx
  add	ebx,ecx			;adjust for instruction size
  add	ebx,[instruction_pc]	;form physical address
  mov	[operand],ebx
  or	byte [instruction_type],2
  or	byte [operand_type],1
;check if symbol table entry
  mov	eax,[symbol_process]
  or	eax,eax
  jz	sr_80			;jmp if no symbol table process
  push	edi
  mov	edi,ebx
  push	ebp
  call	eax
  pop	ebp
  pop	edi
  or	eax,eax
  jnz	sr_80			;jmp if no symbol found
  mov	edi,[stuff_sv1]
  mov	byte [edi],' '
  inc	edi
  call	str_move  
sr_80:
  ret

  [section .data]
stuff_sv1 dd 0
  [section .text]