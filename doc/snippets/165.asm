; getresuid example:


  global _start
_start:
  mov	eax,165		;getresuid function#
  mov	ebx,ruid	;ptr to real user id
  mov	ecx,euid	;ptr to effective user id
  mov	edx,suid	;ptr to saved effective user id
  int	80h

  mov	eax,1
  int	80h

;-----------
  [section .data]
ruid: dd 0
euid: dd 0
suid: dd 0
 
;------------
  [section .text]


