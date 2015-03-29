; syslog example:
;

  global _start
_start:
  mov	eax,103		;syslog kernel call
  mov	ebx,3		;read up to ring3, only non-root option
  mov	ecx,buffer
  mov	edx,buffer_size
  int	80h


exit:
  mov	eax,1
  int	byte 80h

;-----------------
  [section .data]

buffer times 20000 db 0
buffer_size equ $ - buffer

 [section .text]




