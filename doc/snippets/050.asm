; getegid  - function example


  global _start
_start:
  mov	eax,50	;getegid function#
  int	80h	;returns EUID in eax

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


