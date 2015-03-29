; ftruncate64 example:


  global _start
_start:
  mov	ebx,filename
  mov	ecx,2
  xor	edx,edx
  mov	eax,5
  int	80h		;open file

  mov	ebx,eax

  mov	eax,194		;ftruncate64
  mov	ecx,388			;new file length
  mov	edx,0
  int	80h			;truncate

  mov	eax,1
  int	80h
;----------
  [section .data] 
filename: db 'test.asm',0
;------------
  [section .text]

;the following is truncated:
;1234567890