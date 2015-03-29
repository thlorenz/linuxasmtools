; rt_sigaction  - function example

  global _start
_start:

child:
  mov	eax,174	;rt_sigaction function #
  mov	ebx,dword 11	;signal#
  mov	ecx,our_handler
  mov	edx,old_handler		;old_handler
  mov	esi,8
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
 dd	10000000h	;flag
 dd	0h	;?
 dd	0	;?
old_handler:
 dd	0,0,0,0
  [section .text]


