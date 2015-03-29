; lchown  - function example

;only root can change ownership of files.  If this
;isn't run as root "lchown" will return error -1
;
  global _start
_start:
  mov	eax,24		;kernel call for getuid
  int	80h		;get user id
  mov	ecx,eax		;user id to ecx

  mov	eax,16		;lchown - change file owner
  mov	ebx,filename
  mov	edx,-1		;do not change  group id
  int	80h
  mov	eax,1
  int	80h

;---
  [section .data]
filename: db 'test.asm',0

  [section .text]


