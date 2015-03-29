; getpgrp - function example

  global _start
_start:

child:
  mov	eax,65	;getpgrp function #
  int	80h	;returns 0 if success
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


