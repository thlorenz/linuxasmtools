; brk  - function example

  extern delay
  extern crt_str

  global _start
_start:
  mov	eax,45 ;brk function#
  mov	ebx,0	;request start of allocatable mem
  int	80h

  mov	ebx,eax	;get mem start in ebx
  mov	eax,45
  add	ebx,4096	;allocate
  int	80h

  mov	eax,45
  xor	ebx,ebx	;request start of mem
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]

  [section .text]


