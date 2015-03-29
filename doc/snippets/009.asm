; link  - function example

  global _start
_start:
  mov	eax,8	;function# for create a file
  mov	ebx,filename	;ptr to asciiz file name
  mov	ecx,0777q	;file permissions (default)
  int	80h
;create link to new file
  mov	eax,9
  mov	ebx,filename	;existing file
  mov	ecx,linked_file ;link name
  int	80h
;delete the link we just created
  mov	eax,10	;function# for unlink
  mov	ebx,linked_file
  int	80h
;delete the origional file we ceated
  mov	eax,10
  mov	ebx,filename
  int	80h
;exit
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
filename: db 'temp_file',0
linked_file db 'link_file',0
  [section .text]


