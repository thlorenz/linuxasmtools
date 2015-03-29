; getpid  - function example

  global _start
_start:
  mov	eax,20	;function# for getpid
  int	80h	;kernel call, returns process id

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db 'test.asm',0
  [section .text]


