; umask  - function example

  global _start
_start:

  mov	eax,60	;umask function#
  mov	ebx,0777q ;set default to 777q
  int	80h	;returns 0 if success

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


