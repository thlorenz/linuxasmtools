; signprocmask - function example
;
  extern crt_str

  global _start
_start:
  mov	eax,126	;sigprocmask function#
  mov	ebx,0	;block signal
  mov	ecx,unblock_mask
  mov	edx,save_old_mask
  int	80h

  mov	eax,126	;sigprocmask
  mov	ebx,2	;set signal
  mov	ecx,save_old_mask
  mov	edx,save_mod_mask
  int	80h

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
unblock_mask	dd	5
save_old_mask	dd	0
save_mod_mask	dd	0

  [section .text]


