; getresgid example:


  global _start
_start:
  mov	eax,211		;getresgid function#
  mov	ebx,real	;ptr to real
  mov	ecx,effective	;ptr to effective
  mov	edx,saved	;ptr to saved
  int	80h

  mov	eax,1
  int	80h

;-----------
  [section .data]
real	dd	0
effective dd	0
saved	dd	0

;------------
  [section .text]


