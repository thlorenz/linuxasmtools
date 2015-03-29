; rename  - function example

  global _start
_start:
  mov	eax,38	;rename function#
  mov	ebx,old_path
  mov	ecx,new_path
  int	80h

  mov	eax,38
  mov	ebx,new_path
  mov	ecx,old_path
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
old_path: db 'test.asm',0
new_path: db 'new.asm',0

  [section .text]


