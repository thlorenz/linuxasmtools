; geteuid  - function example


  global _start
_start:
  mov	eax,49	;geteuid function#
  int	80h	;returns EUID in eax

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
  [section .text]


