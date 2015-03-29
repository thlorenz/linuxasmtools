; truncate64 example:


  global _start
_start:
  mov	eax,193			;truncate64
  mov	ebx,filename
  mov	ecx,345			;new file length (low bits)
  mov	edx,0			;new file length (high bits)
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