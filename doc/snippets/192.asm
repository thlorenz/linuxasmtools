; mmap2  - function example

  global _start
_start:

  mov	eax,192	;mmap2 function #
  mov	ebx,0	;page
  mov	ecx,2000;size
  mov	edx,3	;prot (anonymous)
  mov	esi,22h	;flags
  mov	edi,-1	;fd (no backing file)
  int	80h	;returns 0 if success

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]

  [section .text]


