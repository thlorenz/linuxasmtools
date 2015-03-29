; readdir example:


  global _start
_start:
  mov	eax,183		;getcwd
  mov	ebx,our_path
  mov	ecx,100
  int	80h

  mov	eax,5	;open
  mov	ebx,our_path
  xor	ecx,ecx
  xor	edx,edx
  int	80h	;open dir

  mov	ebx,eax	;fd to ebx
  mov	eax,89	;readdir
  mov	ecx,buffer
  int	80h

  mov	eax,1
  int	80h

;------------
;---
  [section .data]
our_path: times 100 db 0
buffer: times 1000 db 0
  [section .text]


