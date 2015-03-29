; waitpid  - function example

  global _start
_start:
  mov	eax,7	;function# for waitpid
  mov	ebx,0	;wait for any process in our group
  mov	ecx,status ;storage point for status
  mov	edx,1	;WNOHANG, return immediatly with status
  int	80h
  mov	bl,[status]
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
status: dd 0
  [section .text]


