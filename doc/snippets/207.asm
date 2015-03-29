; fchown example:


  global _start
_start:
  mov	ebx,filename
  mov	ecx,2
  xor	edx,edx
  mov	eax,5
  int	80h		;open file

  mov	ebx,eax

  mov	eax,207			;fchown
  mov	ecx,0		;new file owner
  mov	edx,0		;new file group
  int	80h			;truncate

  mov	eax,1
  int	80h
;----------
  [section .data] 
filename: db 'test.asm',0
;------------
  [section .text]

