
  extern file_simple_read
  extern file_open
  extern file_write
  extern file_close
  extern byte_to_hexascii
  extern dword2hexstr

  global  main,_start
main:
_start:
  mov	ebx,file_name
  mov	ecx,buf
  mov	edx,buf_size
  call	file_simple_read
  or	eax,eax
  jns	df_05
df_exitj:
  jmp	df_exit		;jmp if error
df_05:
  add	eax,buf
  mov	[file_end_ptr],eax
;open output file
  mov	ebx,out_file
  mov	ecx,1102q
  mov	edx,644q
  call	file_open
  mov	[out_fd],eax
  or	eax,eax
  js	df_exitj		;exit if error
;add header block to file
  mov	ebx,eax		;get fd
  mov	edx,header_strings_size
  mov	ecx,header_strings
  call	file_write
;  mov	dword [symbol_process],sym_process

df_loop:
  mov	ebp,[dis_data_ptr]
  mov	eax,[dis_pc]		;get instruction address
  call	dis_one
;;  test	byte [error_flag],0
;;  jne	df_exit
;add comments to end of dis output
  mov	edi,[inst_end]
  dec	edi			;back up to 0ah and overwrite
  mov	esi,msg1
  call	str_move		;add ':' to file
  mov	al,[error_flag]
  call	byte_to_hexascii
  stosw

  mov	esi,msg2
  call	str_move		;add warn_flag
  mov	al,[warn_flag]
  call	byte_to_hexascii
  stosw

  mov	esi,msg3
  call	str_move		;add warn_flag
  mov	al,[instruction_type]
  call	byte_to_hexascii
  stosw

  mov	esi,msg4		;add address operand flag
  call	str_move
  mov	al,[operand_type]
  call	byte_to_hexascii
  stosw

  mov	esi,msg5		;add operand address
  call	str_move
  mov	ebx,[operand]
  call	dword2hexstr

  mov	al,0ah			;add new end of line
  stosb
  mov	[inst_end],edi
;write data to output file
  mov	ebx,[out_fd]
  mov	ecx,inst		;instruction buffer
  inc	ecx			;move past tab
  mov	edx,[inst_end]
  sub	edx,ecx			;compute length
  call	file_write
  
  xor	eax,eax
  mov	al,[inst_length]
  add	dword [dis_pc],eax
  add	eax,[dis_data_ptr]
  mov	[dis_data_ptr],eax
  cmp	eax,[file_end_ptr]
  jb	df_loop
  

df_exit:
  xor	ebx,ebx
  mov	eax,1
  int	80h

  extern message_box

error_message:
  mov	esi,display_info
  call	message_box
  jmp	df_exit
;---------------------------
sym_process:
  mov	eax,1		;signal symbol not found
  ret

display_info:
  dd	30003730h
  dd	mesg1
  dd	mesg1_end
  dd	0		;scroll
  db	30
  db	5
  db	5
  db	5
  dd	30003037h

mesg1: db "process type s00   ",0ah
       db "program error          ",0ah
       db 0ah
       db "press <enter> to continue"
mesg1_end db	0
;------------------------------------------
  [section .data]
out_file:	db	"_dis.out",0
out_fd		dd	0

dis_data_ptr	dd	buf
dis_pc		dd	0

header_strings:	db	0ah,'BITS 32',0ah
header_strings_size equ $ - header_strings

file_name	db	'_nasm.out.bin',0
file_end_ptr	dd	0
buf_size	equ	20000
buf: times buf_size db 0

msg1	db	' ;err=',0
msg2	db	' warn=',0
msg3    db      ' typ=',0
msg4	db	' act=',0
msg5	db	' adr=',0

  [section .text]
