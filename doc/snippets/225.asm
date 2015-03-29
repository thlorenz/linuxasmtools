; readahead  - function example

  global _start
_start:
  mov	eax,5	;function# for open
  mov	ebx,filename
  xor	ecx,ecx	;file access flag, readonly
  xor	edx,edx	;file permissions, use defaults
  int	80h	;kernel call
  mov	ebx,eax	;move fd

  mov	eax,225	;function# for readahead
  mov	ecx,20	;seek offset
  mov	edx,20	;read count
  int	80h	;kernel call

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db 'test.asm',0
  [section .text]


