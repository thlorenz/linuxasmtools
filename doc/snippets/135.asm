; sysfs  - function example

  global _start
_start:
  mov	eax,135		;sysfs function
  mov	ebx,1		;optiion
  mov	ecx,buffer1
  mov	edx,0
  int	80h

  mov	eax,1
  int	80h

;---
  [section .data]
buffer1: db 'proc',0
buffer2: times 100 db 0
  [section .text]


