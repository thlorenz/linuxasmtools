; getuid  - function example

  extern delay
  extern crt_str

  global _start
_start:
  mov	eax,47	;getuid function#
  int	80h	;returns UID in eax

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]

  [section .text]


