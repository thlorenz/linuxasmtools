; wait4  - function example

  global _start
_start:
  mov	eax,2	;function#
  int	80h	;kernel call
  or	eax,eax
  jz	child	;jmp if child 
;parent
  mov	ebx,eax	;get pid
  mov	ecx,status
  mov	edx,0	;options
  mov	esi,0	;rusage ptr
  mov	eax,114
  int	80h
  mov	ebx,[status]

  mov	eax,1
  int	80h	;exit parent
child:
  nop
  mov	eax,1
  int	80h	;exit child

;-----------
  [section .data]
status: dd 0
  [section .text]


