 extern read_stdin

 global _start
_start:
  nop
  jmp	short _start
  call	read_stdin
  mov	eax,1
  int	byte 80h
