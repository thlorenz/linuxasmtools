
  extern sys_getuid
  extern stdout_str
  extern block_open_read
  extern block_seek
  extern sys_exit
  extern crt_write
  extern block_read
  extern str_move
  extern dwordto_hexascii

;-----------------------------------------------

struc dmi
.name	resb 5	;_DMI_
.cksum	resb 1	;checksum
.size	resw 1	;length of table including all structures
.adr	resd 1	;address of first table structure
.count	resb 1	;number of structures in table
.rev	resb 1	;revision#
endstruc

struc block
.type	resb 1	;block type
.size	resb 1	;block length
.handle resw 1	;handle
.code	resb 1	;0=no strings 1=name 2=version 3=date
endstruc


  global _start,main
main:
_start:
  call	sys_getuid
  or	eax,eax		;check if root
  jz	we_are_root
  mov	ecx,warning
  call	stdout_str
  jmp	do_exit

we_are_root:  
  mov	ecx,bios_msg
  mov	edx,bios_msg_size
  call	crt_write

  mov	ebx,mem_dev
  call	block_open_read
  or	eax,eax
  jns	find_dmi
  mov	ecx,warning2
  call	stdout_str
  jmp	do_exit

find_dmi:
  mov	[mem_handle],eax
  mov	ebx,eax		;handle to ebx
  mov	ecx,0e0000h	;seek offset
  mov	[current_seek],ecx
  call	block_seek
  mov	ebp,1fffh	;max loop
;read loop, ebx=handle
dmi_search:
  mov	ecx,buffer
  mov	edx,16		;size of read
  call	block_read	;read 16 bytes
  cmp	[ecx],dword '_DMI'
  je	got_dmi
  add	[current_seek],dword 16
  dec	ebp		;timeout
  jnz	dmi_search
;show error, dmi not found
  mov	ecx,warning3
  call	stdout_str
  jmp	do_exit

got_dmi:
  mov	eax,[current_seek]
  mov	edi,tb_stuff
  call	dwordto_hexascii
  mov	ecx,tb_msg
  call	stdout_str

  mov	ecx,buffer
  mov	al,[ecx+dmi.count]  ;get block count
  mov	[blocks],al
  mov	ecx,[ecx + dmi.adr]	;get table offset
  mov	[current_seek],ecx

block_loop:
  cmp	[blocks],byte 0
  je	do_exit		;exit if all blocks processed 
  mov	ebx,[mem_handle] ;setup seek
  mov	ecx,[current_seek] ;get seek offset
  call	block_seek

  mov	ecx,buffer
  mov	edx,200		;size of read
  call	block_read	;read block

  call	process_block
  add	[current_seek],eax
no_strings:
  dec	byte [blocks]
  jmp	short block_loop

do_exit:
  call	sys_exit

;----------------------------------------------------
;input: buffer has current block
;output: eax = block size
process_block:
  mov	esi,buffer
  cmp	[esi+block.code],byte 0	;any strings
  je	pb_exit1		;exit if no string
  xor	eax,eax
  mov	al,[esi+block.size]
  add	esi,eax			;move to strings
  call	process_name
  cmp	[esi],byte 0		;another string
  je	pb_tail			;jmp if no more strings
  call	process_version
  cmp	[esi],byte 0		;another string
  je	pb_tail			;jmp if no more strings
  call	process_date
flush_loop:
  cmp	[esi],byte 0		;expected end of strings
  je	pb_tail
  mov	edi,msg_buf
  call	str_move
  inc	edi
  jmp	flush_loop
pb_tail:
  inc	esi			;move past 0
  sub	esi,buffer		;compute lenght of block, including strings
  mov	eax,esi
  jmp	short pb_exit2

pb_exit1:
  xor	eax,eax
  mov	al,[buffer+block.size]
pb_exit2:
  ret

;----------------------------------------------------
;input: data in buffer
;       esi=string ptr
;output: esi=ptr to end of string (beyond 0)
process_name:
  mov	edi,msg_buf
  call	str_move
  mov	al,0ah
  stosb
  mov	al,0
  stosb
  mov	al,[buffer]	;get type code
  cmp	al,2
  jae	pn_exit		;ignore all types greater than 2

  mov	ecx,bios_vendor
  cmp	al,0
  je	show_pn
  mov	ecx,mainboard_vendor
show_pn:
  call	stdout_str
  
  mov	ecx,msg_buf
  call	stdout_str
pn_exit:
  inc	edi		;move past zero at end of string
  ret
;----------------------------------------------------
;input: data in buffer
;       esi=string ptr
;output: esi=ptr to end of string (beyond 0)
process_version:
  mov	edi,msg_buf
  call	str_move
  mov	al,0ah
  stosb
  mov	al,0
  stosb
  mov	al,[buffer]	;get type code
  cmp	al,2
  jae	pv_exit		;ignore all types greater than 2

  mov	ecx,bios_version
  cmp	al,0
  je	show_pv
  mov	ecx,mainboard_type
show_pv:
  call	stdout_str

  mov	ecx,msg_buf
  call	stdout_str
pv_exit:
  inc	edi		;move past zero at end of string
  ret
;----------------------------------------------------
;input: data in buffer
;       esi=string ptr
;output: esi=ptr to end of string (beyond 0)
process_date:
  mov	edi,msg_buf
  call	str_move
  mov	al,0ah
  stosb
  mov	al,0
  stosb
  mov	al,[buffer]	;get type code
  cmp	al,2
  jae	pd_exit		;ignore all types greater than 2

  mov	ecx,bios_date
  cmp	al,0
  je	pd_show
  mov	ecx,mainboard_version
pd_show:
  call	stdout_str

  mov	ecx,msg_buf
  call	stdout_str
pd_exit:
  inc	edi		;move past zero at end of string
  ret
;----------------------------------------------------
;----------------------------------------------------
 [section .data]
mem_dev db '/dev/mem',0
mem_handle dd 0
current_seek dd 0
blocks	db 0	;number of blocks found

warning: db 0ah,'  Error - Root access needed',0ah,0
warning2: db 0ah,'  Error - Can not access /dev/mem',0ah,0
warning3: db 0ah,'  Error - bios header not found',0ah,0

tb_msg: db '  bios string (_DMI_) found at: '
tb_stuff: db 'xxxxxxxx',0ah,0

msg_buf	times 100 db 0

bios_msg:
incbin "bios.inc"
bios_msg_size equ $ - bios_msg

bios_vendor: db "  BIOS vendor = ",0
bios_version: db "  BIOS version = ",0
bios_date:    db "  BIOS date = ",0
mainboard_vendor: db "  Mainboard vendor = ",0
mainboard_type:	db "  Mainboard type = ",0
mainboard_version: db "  Mainboard version = ",0

buffer	times 1024 db 0
	