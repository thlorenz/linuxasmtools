; getpriority/setpriority example:


  global _start
_start:
  mov	eax,24		;getuid -get current user id
  int	80h		;getuid
  mov	ecx,eax
  push	eax		;save user id

  mov	eax,96		;get priority
  mov	ebx,2		;get priority for user id
  int	80h		;get priority
  mov	edx,eax		;save priority

  mov	eax,97		;set priority
  mov	ebx,2		;set priority for user
  pop	ecx		;get user id
  int	80h		;set priority

  mov	eax,1
  int	80h
;----------
  [section .data] 
  [section .text]

