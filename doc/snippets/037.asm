; kill  - function example

  global _start
_start:
  mov	eax,20	;getpid function#
  int	80h	;get our pid
  mov	ebx,eax	;move our pid to ebx
  mov	eax,37	;kill function#
  mov	ecx,10	;user signal 1
  int	80h	;kernel call, returns process id

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
  [section .text]


