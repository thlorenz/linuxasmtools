; sysinfo  - function example

  global _start
_start:
  mov	eax,116	;function#
  mov	ebx,buffer
  int	80h	;kernel call

  mov	eax,1
  int	80h

;-----------
  [section .data]
buffer: times 100 dd 0
  [section .text]


