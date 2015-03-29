; access  - function example

  global _start
_start:
  mov	eax,33	;access function#
  mov	ebx,filename
  mov	ecx,0
  int	80h	;kernel call, returns process id

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db 'test.asm',0
  [section .text]


