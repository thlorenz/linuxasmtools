; sched_setscheduler - function example
; run as root

  global _start
_start:

  xor	ebx,ebx	;set pid=0

  mov	eax,157	;schec_getscheduler function#
  int	80h

  mov	eax,156		;sched_setscheduler
  mov	ecx,2
  mov	edx,policy2
  int	80h

  mov	eax,157	;schec_getscheduler function#
  int	80h

  mov	eax,156		;sched_setscheduler
  mov	ecx,0
  mov	edx,policy0
  int	80h

  mov	eax,157	;schec_getscheduler function#
  int	80h


  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
policy0	dd	0
policy1	dd	1
policy2 dd	1

  [section .text]




