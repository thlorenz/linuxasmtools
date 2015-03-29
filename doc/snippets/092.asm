; truncate example:


  global _start
_start:
  mov	eax,92			;truncate
  mov	ebx,filename
  mov	ecx,286			;new file length
  int	80h			;truncate

  mov	eax,1
  int	80h
;----------
  [section .data] 
filename: db 'test.asm',0
;------------
  [section .text]

;the following is removed:
;123