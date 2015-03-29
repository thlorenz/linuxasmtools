; getppid  - function example

  global _start
_start:

  mov	eax,64	;getppid function#
  int	80h	;returns 0 if success

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


