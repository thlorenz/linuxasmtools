; setuid  - function example

;only root can umount, 

  global _start
_start:
  mov	eax,24	;getuid function#
  int	80h	;kernel call, returns process id

  mov	ebx,eax ;move uid to ebx
  mov	eax,23	;setuid function#
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]

  [section .text]


