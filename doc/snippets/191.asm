; ugetrlimit  - function example

  global _start
_start:

  mov	eax,191	;ugetrlimit function #
  mov	ebx,0	;our resource
  mov	ecx,rlimit
  int	80h	;returns 0 if success

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
rlimit times 100 dd 0

  [section .text]


