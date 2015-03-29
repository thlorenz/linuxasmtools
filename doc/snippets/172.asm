; prctl example:


  global _start
_start:
  mov	eax,172		;prctl function#
  mov	ebx,2		;get signal to report kill
  mov	ecx,signal	;ptr to effective
  int	80h

  mov	eax,1
  int	80h

;-----------
  [section .data]
signal	dd	0

;------------
  [section .text]


