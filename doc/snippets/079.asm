; gettimeofday, settimeofday - function example


  global _start
_start:
  mov	eax,78	;gettimeofday function#
  mov	ebx,tv
  mov	ecx,tz	;time zone info (unused)
  int	80h

  mov	eax,79	;settimeofday function#
  mov	ebx,tv	;self function
  mov	ecx,tz	;time zone (unused)
  int	80h

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
tv	dd	0,0
tz	dd	0,0

  [section .text]


