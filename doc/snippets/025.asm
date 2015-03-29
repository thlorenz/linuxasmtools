; stime  - function example

;only root can stime, 

  global _start
_start:
  mov	eax,25	;stime function#
  mov	ebx,time_ptr
  int	80h	;kernel call, returns process id

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
time_ptr: dd 0	;new time in seconds
  [section .text]


