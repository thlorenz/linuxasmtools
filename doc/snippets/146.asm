; writev - function example

  global _start
_start:
  mov	eax,146	;writev function#
  mov	ebx,1	;stdout
  mov	ecx,buf_array
  mov	edx,2	;use 2 buffers
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
buf_array:
  dd	msg1
  dd	5
  dd	msg2
  dd	5

msg1	db 0ah,'1234'
  db 0	;filler
msg2    db '5678',0ah
  [section .text]




