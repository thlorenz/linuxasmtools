; chmod  - function example

  global _start
_start:
  mov	eax,15		;chmod - change file permissions
  mov	ebx,filename
  mov	ecx,0777q
  int	80h
  mov	eax,1
  int	80h

;---
  [section .data]
filename: db 'test.asm',0

  [section .text]


