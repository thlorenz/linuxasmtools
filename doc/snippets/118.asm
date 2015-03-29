; fsync  - function example

  global _start
_start:
  mov	eax,5	;open
  mov	ebx,filename
  mov	ecx,2
  mov	edx,0
  int	80h
  mov	ebx,eax	;move fd to ebx
  mov	eax,118	;function# for fsync
  int	80h	;kernel call
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename: db "test.asm",0
  [section .text]


