; clone  - function example

  global _start
_start:
  mov	eax,120	;clone function#
  mov	ebx,11h	;flags (signal for child exit)
  mov	ecx,0	;stack (kernel assigned)
  mov	edx,0	;registers (kernel assigned)
  int	80h
  or	eax,eax
  jz	child
parent:
  mov	ebx,0
  mov	eax,1
  int	80h

child:
  nop
  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
  [section .text]


