; persona  - function example

  global _start
_start:
  mov	eax,136		;persona function
  mov	ebx,-1		;get current persona
  int	80h

  mov	eax,1
  int	80h

;---
  [section .data]
  [section .text]


