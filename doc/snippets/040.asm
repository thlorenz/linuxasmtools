; mkdir  - function example

  global _start
_start:
  mov	eax,39	;mkdir function#
  mov	ebx,new_dir
  int	80h

  mov	eax,40	;rmdir function#
  mov	ebx,new_dir
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
new_dir: db 'new_dir',0

  [section .text]


