; execve  - function example

  global _start
_start:
  mov	esi,esp
es_lp:
  lodsd
  or	eax,eax
  jnz	es_lp		;loop till start of env ptrs
  mov	[enviro_ptrs],esi

  mov	ebx,[execve_full_path]
  mov	ecx,execve_full_path
  mov	edx,[enviro_ptrs]
  mov	eax,11		;execve
  int	80h
;---
  [section .data]
enviro_ptrs:	dd 0
filename: db '/bin/ls',0
execve_full_path:	dd	filename
exc_args:		dd	0	;ptr to parameter1

  [section .text]


