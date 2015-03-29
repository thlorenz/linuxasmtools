; read  - function example

  global _start
_start:
  mov	eax,3	;function# for read
  mov	ebx,0	;fd (0=stdin)
  mov	ecx,buffer
  mov	edx,1	;read one byte
  int	80h	;kernel call
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
buffer db 0
  [section .text]


