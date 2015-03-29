; fcntl  - file control


  global _start
_start:
  mov	eax,55	;fcntl function#
  xor	ebx,ebx	;set fd = stdin
  mov	ecx,3	;get file status
  int	byte 80h;returns status in eax

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


