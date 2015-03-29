; time  - function example

  global _start
_start:
  mov	eax,13		;time - get time
  xor	ebx,ebx		;return time in eax
  int	80h
  mov	eax,1
  int	80h

;---
  [section .data]
time_buffer:

  [section .text]


