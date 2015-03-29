; sethostname - function example

  global _start
_start:
  mov	eax,122	;uname function#
  mov	ebx,buffer
  int	80h

  mov	ebx,sys_rel

  mov	eax,74	;sethostname function #
  int	80h	;returns 0 if success
_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
buffer:
sys_name: times 65 db 0
sys_rel: times 65 db 0
sys_release: times 65 db 0
sys_version: times 65 db 0
sys_machine: times 65 db 0
sys_domain: times 65 db 0

  [section .text]


