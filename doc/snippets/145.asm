; readv - function example

  global _start
_start:
  mov	eax,5	;function# for open
  mov	ebx,filename
  xor	ecx,ecx	;file access flag, readonly
  xor	edx,edx	;file permissions, use defaults
  int	80h	;kernel call

  mov	ebx,eax	;move fd

  mov	eax,145	;readv function#
  mov	ecx,buf_array
  mov	edx,2	;use 2 buffers
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db 'test.asm',0
buf_array:
  dd	buf1
  dd	5
  dd	buf2
  dd	2000

buf1  times 5 db 0
  db 0	;filler
buf2 times 2000 db 0
  [section .text]




