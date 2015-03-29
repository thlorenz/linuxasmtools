; getpgid - function example
;
  extern crt_str

  global _start
_start:
  mov	eax,132	;getpgid_syms function#
  mov	ebx,0	;return current pgid
  int	80h

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]

  [section .text]


