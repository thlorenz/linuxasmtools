; rt_sigpending  - function example

  global _start
_start:

child:
  mov	eax,176	;rt_sigpending function #
  mov	ebx,sigset
  mov	ecx,8
  int	80h	;returns 0 if success

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
sigset:
 dd	-1,-1	;mask bits stored for pending signals
  [section .text]


