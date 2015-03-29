; lseek  - function example

  global _start
_start:
  mov	eax,5	;function# for open
  mov	ebx,filename
  xor	ecx,ecx	;file access flag, readonly
  xor	edx,ecx	;file permissions, use defaults
  int	80h	;kernel call, open file and return fd

  mov	ebx,eax	;fd to ebx
  mov	eax,19	;lseek kernel call
  mov	ecx,2	;offset to seek to
  mov	edx,0	;move relative to start of file
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db 'test.asm',0
  [section .text]


