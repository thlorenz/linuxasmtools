; exit  - function example

  global _start
_start:
  mov	eax,1	;function#
  xor	ebx,ebx	;return code
  int	80h	;kernel call
