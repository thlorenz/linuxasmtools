; sched_setparam - function example

  global _start
_start:

  mov	eax,2	;fork function#
  int	80h	;kernel call
  or	eax,eax
  jnz	parent

child:
  mov	eax,29
  int	80h	;pause
  nop
  mov	eax,1
  int	80h	;exit child



parent:
  mov	ebx,eax

  mov	eax,155	;schec_getparam function#
  mov	ecx,param_get1
  int	80h

  mov	eax,154
  mov	ecx,param_set
  int	80h

  mov	eax,155
  mov	ecx,param_get2
  int	80h

  mov	eax,154
  mov	ecx,param_get1
  int	80h

  mov	eax,155
  mov	ecx,param_get3
  int	80h
; kill child
  mov	eax,37
  mov	ecx,9	;sigkill
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]

param_get1	dd	0
param_set	dd	0	;5
param_get2	dd	0
param_get3	dd	0

  [section .text]




