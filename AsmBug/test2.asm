; hello  - function example

  global _start
_start:
  mov	eax,4	;write function#
  mov	ebx,1	;stdout
  mov	ecx,msg	;message
  mov	edx,msg_end - msg
  int	80h	;kernel call, returns process id

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
msg	db	0ah,'hello',0ah
msg_end:
  [section .text]


