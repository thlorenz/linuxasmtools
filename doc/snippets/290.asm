; ioprio_get - function example

  global _start
_start:

  mov	eax,290	;ioprio_get function#
  mov	ebx,2	;operation
  mov	ecx,0	;base priority
  int	80h

  mov	eax,1
  int	80h

;---
  [section .data]

  [section .text]


