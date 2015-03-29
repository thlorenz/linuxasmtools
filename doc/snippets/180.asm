; pwrite  - function example

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

  mov	eax,181	;pwrite function #
  mov	ecx,buf2 ;buffer to read into
  mov	edx,4	;number of bytes to read
  mov	esi,0	;offset
  int	80h	;returns 0 if success

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
filename db 'ttemp',0
buf1	db '12345678901234567890'

buf2	db 'abcd'
  [section .text]


