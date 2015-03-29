; sigsuspend - function example

;this test pauses process, enter ctrl-c to continue

  global _start
_start:

child:
  mov	eax,72	;sigsuspend function #
  mov	ebx,-1	;mask
  int	80h	;returns 0 if success
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


