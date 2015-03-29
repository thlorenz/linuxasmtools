; getsid - function example

  global _start
_start:
  mov	eax,147	;getsid function#
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
  [section .text]




