; setsid  - function example

  global _start
_start:

  mov	eax,2	;fork
  int	80h
  or	eax,eax
  jz	child
;parent
  jmp	short _exit

child:
  mov	eax,66	;setsid function #
  int	80h	;returns 0 if success
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


