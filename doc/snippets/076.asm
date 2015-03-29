; get/set rlimit - function example

  global _start
_start:
  mov	eax,76	;getrlimit function#
  mov	ebx,0	;cpu time function
  mov	ecx,buffer
  int	80h

  mov	eax,75	;setrlimit function#
  mov	ebx,0
  mov	ecx,buffer
  int	80h

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
buffer:
 dd	0	;rlim_cur (soft)
 dd	0	;rlim_max (hard)
  [section .text]


