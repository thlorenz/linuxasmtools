; times  - function example

  extern delay
  extern crt_str

  global _start
_start:
  mov	eax,-1	;delay one second
  call	delay
  mov	ecx,msg
  call	crt_str

  mov	eax,43	;times function#
  mov	ebx,0	;buffer (unused)
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
buffer:
 dd 0	;user time
 dd 0	;system time
 dd 0	;children user time
 dd 0	;children system time
 dd 0
 dd 0
 dd 0
 dd 0
msg: db 'times function',0

  [section .text]


