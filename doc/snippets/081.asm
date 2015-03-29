; getgroups - function example


  global _start
_start:
  mov	eax,80	;getgroups function#
  mov	ebx,2000 ;buffer size
  mov	ecx,buffer	;
  int	80h

  mov	ebx,eax	;move size to ebx
  mov	eax,81	;setgroups
  mov	ecx,buffer
  int	80h

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
buffer	times 2000 db 0
  [section .text]


