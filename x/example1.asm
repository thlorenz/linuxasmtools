

extern env_stack
extern crt_write
extern x_list_extension

global _start
_start:
  call	env_stack
  call	x_list_extension
  call	show_extensions
 
  mov	eax,01
  int	byte 80h



show_extensions:
  lea	esi,[ecx+32]
  xor	eax,eax
  mov	al,[ecx+1]	;get number of items returned
  mov	ebp,eax		;save count
show_loop:
  call	line_feed
  lea	ecx,[esi+1]
  xor	edx,edx
  mov	dl,[esi]	;get length of name
  add	esi,edx		;move to next name
  inc	esi
  call	crt_write

  dec	ebp
  jnz	show_loop
  call	line_feed
  ret

line_feed:
  mov	ecx,crlf
  mov	edx,1
  call	crt_write
  ret
;-----------
  [section .data]
crlf:	db 0ah
  [section .text]
