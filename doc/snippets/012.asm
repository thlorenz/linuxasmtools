; chdir  - function example

  global _start
_start:
  mov	eax,12		;chdir - change directory
  mov	ebx,new_dir
  int	80h
;setup to list current directory by
;executing "ls"
  mov	esi,esp
es_lp:
  lodsd
  or	eax,eax
  jnz	es_lp		;loop till start of env ptrs
  mov	[enviro_ptrs],esi
;execute "ls" program
  mov	eax,11
  mov	ebx,[execve_full_path]
  mov	ecx,execve_full_path
  mov	edx,[enviro_ptrs]
  int	80h

;---
  [section .data]
new_dir:	db '/',0
enviro_ptrs:	dd 0
filename: db '/bin/ls',0
execve_full_path:	dd	filename
exc_args:		dd	0	;ptr to parameter1
  [section .text]


