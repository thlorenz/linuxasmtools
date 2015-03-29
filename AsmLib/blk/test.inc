
; ----------- test code --------------
;  jmp	.t
;.msg  db	0ah,'we arrived at ----',0ah,0
;.t: pusha
;   mov	ecx,.msg
;      call	msg
;      popa
;----------- test code ---------------
;-------------------------------
; display_asciiz - output string
;  input: ecx - ponter to string
;
	%define stdout 0x1
	%define stderr 0x2

msg:
  xor edx, edx
.count_again:	
  cmp [ecx + edx], byte 0x0
  je .done_count
  inc edx
  jmp .count_again
.done_count:	
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, 1		;	; file desc. is stdout
  int 0x80
  ret
