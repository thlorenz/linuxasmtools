; acct  - function example
;this test must run as root, otherwise it gives error

  global _start
_start:
;create accounting file
  mov	eax,5	;function# for open
  mov	ebx,acct_log
  mov	ecx,102q ;file access flag,  create rw
  xor	edx,edx	;file permissions, use defaults
  int	80h	;kernel call
;close accounting file
  mov	ebx,eax
  mov	eax,6	;close
  int	80h

;turn accounting on and record in existing file acct_log
  mov	eax,51	;acct function#
  mov	ebx,acct_log
  int	80h	;returns 0 if success

  mov	eax,51	;acct function#
  mov	ebx,0
  int	80h	;returns 0 if success

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
acct_log: db "acct_log",0
  [section .text]


