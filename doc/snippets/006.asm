; close  - function example

  global _start
_start:
  mov	eax,5	;function# for open
  mov	ebx,filename
  xor	ecx,ecx	;file access flag, readonly
  xor	edx,ecx	;file permissions, use defaults
  int	80h	;kernel call - open file
  or	eax,eax ;any errors?
  js	_exit	;exit if error
  mov	ebx,eax ;move fd to ebx
  mov	eax,6	;close kernel function
  int	80h	;kernel call - close file
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db 'test.asm',0
  [section .text]


