  [section .text]
;*********** type20 ****************

;------------------------------------------------------------------
;type s20

; opcode  prefix  prefix 66     prefix 66
;         flag    inactive*     active
; ------  ------  -----------   -------------
;0fc8 bswap  -    reg32                         s10,2
;0fc9 bswap
;0fca bswap
;0fcb bswap
;0fcc bswap
;0fcd bswap
;0fce bswap
;0fcf bswap
; c8 enter   -    imm16,imm8                    s10,3
;
type_s20:
;decode flag field
  mov	al,[edx+1]	;get flag field
  xor	ebx,ebx
  cmp	al,2
  je	t10_2
;type3 (enter) imm16,imm8
t10_3:
  xor	ebx,ebx
  mov	bx,[ebp+1]
  call	bin_to_hexascii_h
  mov	al,','
  stosb
  xor	ebx,ebx
  mov	bl,[ebp+3]
  call	bin_to_hexascii_h
  add	ebp,4
  mov	al,0ah
  stosb				;put eol at end of line
  mov	al,80h
  ret


;type2 (bswap)  reg32
t10_2:
  xor	ebx,ebx
  mov	bl,[ebp]		;get opcode
  and	bl,07h			;convert to register code
  mov	bh,-1			;preload code for eax.ecx,edx,etc
  call	stuff_reg		;cx=opcode index  bl=register index
  mov	al,0ah
  stosb				;terminate string
  mov	al,0c0h			;signal done + prefix 66h legal
  inc	ebp			;move to next instruction byte
  ret



;------------------------------------------------------------------
