; fork  - function example

  global _start
_start:
  mov	eax,2	;function#
  int	80h	;kernel call
  or	eax,eax
  jz	child	;jmp if child 
;parent
  mov	eax,1
  int	80h	;exit parent
child:
  nop
  mov	eax,1
  int	80h	;exit child

