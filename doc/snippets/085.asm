; symlink example:   create,link,view,unlink


  global _start
_start:
  mov	eax,8	;function# for create a file
  mov	ebx,initial_file	;ptr to asciiz file name
  xor	ecx,ecx		;file permissions (default)
  int	80h		;create file

  mov	eax,83	;symlink function#
  mov	ebx,initial_file
  mov	ecx,linked_file
  int	80h		;symlink

  mov	eax,85		;read link
  mov	ebx,linked_file
  mov	ecx,buffer
  mov	edx,1000
  int	80h		;readllnk
  
; unlink  - function example

  mov	eax,10	;function# for unlink a file
  mov	ebx,linked_file	;ptr to asciiz file name
  xor	ecx,ecx		;file permissions (default)
  int	80h		;unlink linked file

;-----------
; hardlink example:  link,view,unlink

; link  - function example
;create link to new file
  mov	eax,9
  mov	ebx,initial_file ;existing file
  mov	ecx,linked_file ;link name
  int	80h		;hardlink

  mov	eax,85		;read link
  mov	ebx,linked_file
  mov	ecx,buffer
  mov	edx,1000
  int	80h		;readlink (fails on hardlinks)
  
  mov	eax,10	;function# for unlink a file
  mov	ebx,linked_file	;ptr to asciiz file name
  xor	ecx,ecx		;file permissions (default)
  int	80h		;unlink linked_file

  mov	eax,85		;read link
  mov	ebx,initial_file
  mov	ecx,buffer
  mov	edx,1000
  int	80h		;readlink (should be gone)
  
;delete the link (should fail, file does not exist)
  mov	eax,10	;function# for unlink
  mov	ebx,linked_file
  int	80h		;delete link file (should fail)
;delete the origional file we ceated
  mov	eax,10
  mov	ebx,initial_file
  int	80h		;delete initial_file
;exit
  mov	eax,1	;exit function#
  int	80h	;exit

;------------
;---
  [section .data]
initial_file: db 'initial_file',0
linked_file: db 'linked_file',0
buffer: times 1000 db 0
  [section .text]


