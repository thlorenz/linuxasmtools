
  [section .text]

help_msg:
  mov	eax,4		;write
  xor	ebx,ebx		;stdout
  inc	ebx
  mov	ecx,help_txt
  mov	edx,help_txt_len
  int	80h
  ret

help_txt:
  db 0ah
  db 'tracex usage:  tracex <-r> <-t> <h> filename',0ah
  db '    -r = raw mode display',0ah
  db '    -t = truncate hex dump of functions',0ah
  db '    -h = this help display',0ah
  db 0ah


help_txt_len  equ $ - help_txt


