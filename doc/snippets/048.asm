; signal  - function example


  global _start
_start:
  mov	eax,48	;signal function#
  mov	ebx,10	;signal user1
  mov	ecx,handler
  int	80h	;returns UID in eax

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
handler:		;dummy handler
  ret
;---
  [section .data]
  [section .text]


