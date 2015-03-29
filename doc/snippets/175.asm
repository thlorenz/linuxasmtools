; rt_sigprocmask  - function example

  global _start
_start:

child:
  mov	eax,175	;rt_sigprocmask function #
  mov	ebx,0		;;how
  mov	ecx,sigset
  mov	edx,osigset
  mov	esi,8
  int	80h	;returns 0 if success

  mov	eax,175	;rt_sigprocmask function #
  mov	ebx,0		;;how
  mov	ecx,sigset
  mov	edx,osigset
  mov	esi,8
  int	80h	;returns 0 if success
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
sigset:
 dd	3,0	;mask
osigset:
 dd	0,0
  [section .text]


