; unlink  - function example

  global _start
_start:
  mov	eax,8	;function# for create a file
  mov	ebx,filename	;ptr to asciiz file name
  xor	ecx,ecx		;file permissions (default)
  int	80h
;delete the file we just created
  mov	eax,10	;function# for unlink
  mov	ebx,filename
  int	80h
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename: db 'temp_file',0
  [section .text]


