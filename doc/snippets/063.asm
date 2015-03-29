; dup2  - function example

  global _start
_start:

  mov	eax,63	;dup2 function#
  mov	ebx,1	;old fd
  mov	ecx,100
  int	80h	;returns 0 if success

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


