; chown  - function example
;run as root

  global _start
_start:

  mov	eax,5	;function# for open
  mov	ebx,filename
  mov	ecx,102q	;file access flag, rw
  mov	edx,777q	;file permissions
  int	80h	;kernel call

  mov	ebx,eax	;save fd

  mov	eax,4	;write
  mov	ecx,buf1
  mov	edx,20
  int	80h

  mov	eax,6	;close
  int	80h

  mov	eax,182	;chown function #
  mov	ebx,filename ;file
  mov	ecx,0	;owner
  mov	edx,0	;group
  int	80h	;returns 0 if success

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
filename db 'ttemp',0
buf1	db '12345678901234567890'

  [section .text]


