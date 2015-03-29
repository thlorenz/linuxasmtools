; sysctl - function example

  global _start
_start:
  mov	eax,149	;sysctl function#
  mov	ebx,sysctl_struc
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit

;---
  [section .data]
sysctl_struc:
name_ptr:	dd	name
name_len:	dd	2
oldvalue_ptr	dd	old_value
oldvalue_len	dd	old_len
newvalue_ptr	dd	0
newvalue_len	dd	0

name:	dd	01
	dd	01
	dd	02
old_value: times 2000 db 0
old_len    dd	2000

  [section .text]




