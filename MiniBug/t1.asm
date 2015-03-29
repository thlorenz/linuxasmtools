
 global _start
_start:
  call	dummy
rtn:
  mov	eax,1
  int	byte 80h
labelx: db 'x'
labely: db 'y'
labelz: db 'z'
  nop
dummy:	ret
  nop
  [section .data]
label1: db 1
label2: db 2
label3: db 3
  [section .text]
