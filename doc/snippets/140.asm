; llseek  - function example

  global _start
_start:
  mov	eax,5	;function# for open
  mov	ebx,filename
  xor	ecx,ecx	;file access flag, readonly
  xor	edx,edx	;file permissions, use defaults
  int	80h	;kernel call

  mov	ebx,eax	;move fd
  mov	eax,140	;llseek function#
  mov	ecx,0	;high
  mov	edx,2	;low
  mov	esi,result
  mov	edi,0	;whence
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename db 'test.asm',0
result	dd	0,0
  [section .text]


