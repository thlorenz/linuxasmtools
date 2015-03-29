; sigaction  - function example

  global _start
_start:

child:
  mov	eax,67	;sigaction function #
  mov	ebx,dword 11	;signal#
  mov	ecx,our_handler
  mov	edx,old_handler
;  xor	edx,edx
  int	80h	;returns 0 if success
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
handler:
  ret
;---
  [section .data]
our_handler:
 dd	handler
 dd	-1	;mask
 dd	0	;flag
 dd	0
old_handler:
 dd	0,0,0,0
  [section .text]


