; setdomainename/uname - function example
; must be run as root
;
  extern crt_str

  global _start
_start:
  mov	eax,122	;uname function#
  mov	ebx,buffer
  int	80h

  mov	ebx,sys_domain

;find length of name
  mov	esi,ebx
  mov	ecx,-1
dloop:
  inc	ecx
  lodsb
  or	al,al
  jnz	dloop

  mov	eax,121	;setdomainname function #
  int	80h	;returns 0 if success

  mov	eax,122	;uname function#
  mov	ebx,buffer
  int	80h

  mov	[sys_domain -1],byte 0ah
  mov	ecx,sys_domain -1
  call	crt_str

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


