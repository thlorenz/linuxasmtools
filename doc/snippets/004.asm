; write  - function example

  global _start
_start:
  mov	eax,4	;function# for write
  mov	ebx,1	;fd (1=stdout)
  mov	ecx,buffer
  mov	edx,6	;write 6 bytes
  int	80h	;kernel call
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
buffer db 'hello',0ah
  [section .text]


