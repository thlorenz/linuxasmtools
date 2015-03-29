; nice  - function example

  global _start
_start:
  mov	eax,34	;nice function#
  mov	ebx,1	;priority  reduction amount
  int	80h	;kernel call, returns process id

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
  [section .text]


