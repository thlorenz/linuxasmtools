; capget  - function example
;run as root

  global _start
_start:

  mov	eax,184	;capget function #
  mov	ebx,buf1
  mov	ecx,buf2
  int	80h	;returns 0 if success

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
buf1 dd	19980330h
     dd 0		;pid
buf2 times 100 dd 0

  [section .text]


