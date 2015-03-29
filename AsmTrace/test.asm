; openat  - function example

  global _start
_start:
  mov	eax,295	;function# for open
  mov	ebx,filename
  xor	ecx,ecx	;file access flag, readonly
  xor	edx,edx	;file permissions, use defaults
  int	80h	;kernel call
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db 'test.asm',0
  [section .text]


