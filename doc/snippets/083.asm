; symlink - function example

  global _start
_start:
  mov	eax,83	;symlink function#
  mov	ebx,old_path
  mov	ecx,new_path
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
old_path: db 'existingfile',0
new_path: db 'newname',0
  [section .text]


