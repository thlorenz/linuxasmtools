; getdents  - function example

  global _start
_start:
  mov	eax,5	;function# for open
  mov	ebx,filename
  xor	ecx,ecx	;file access flag, readonly
  xor	edx,edx	;file permissions, use defaults
  int	80h	;kernel call

  mov	ebx,eax	;move fd
  mov	eax,220	;getdents function#
  mov	ecx,buffer	;storeage
  mov	edx,20000	;size
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db '/',0
buffer	times 20000 db 0
  [section .text]


