; setreuid  - function example

  global _start
_start:

child:
  mov	eax,70	;setreuid function #
  mov	ebx,-1
  mov	ecx,-1
  int	80h	;returns 0 if success
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


