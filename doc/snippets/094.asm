; fchmod example:


  global _start
_start:
  mov	ebx,filename
  mov	ecx,2
  xor	edx,edx
  mov	eax,5
  int	80h		;open file

  mov	ebx,eax

  mov	eax,94			;fchmod
  mov	ecx,0777q		;new file permissions
  int	80h			;truncate

  mov	eax,1
  int	80h
;----------
  [section .data] 
filename: db 'test.asm',0
;------------
  [section .text]

