; sigpending - function example


  global _start
_start:

child:
  mov	eax,73	;sigpending function #
  mov	ebx,buffer
  int	80h	;returns 0 if success
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
buffer	dd	0,0,0,0

  [section .text]


