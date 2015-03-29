; fadvise64 - function example

  global _start
_start:
  mov	eax,5	;function# for open
  mov	ebx,filename
  xor	ecx,ecx	;file access flag, readonly
  xor	edx,edx	;file permissions, use defaults
  int	80h	;kernel call

  mov	ebx,eax

  mov	eax,250	;fadvise64 function#
  mov	ecx,0	;offset
  mov	edx,0	;length
  mov	esi,0	;flag
  mov	edi,0
  int	80h

  mov	eax,1
  int	80h

;---
  [section .data]
filename db 'test.asm',0

  [section .text]


