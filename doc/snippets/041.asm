; dup  - function example

  global _start
_start:
  mov	eax,41	;dup file descriptor function#
  mov	ebx,1	;stdout
  int	80h

  mov	ebx,eax	;move fd
  mov	eax,6	;close (remove fd) function#
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]

  [section .text]


