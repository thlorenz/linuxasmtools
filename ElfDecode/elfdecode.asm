
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]

  extern popup_menu
  extern file_close
  extern sys_run_wait
  extern crt_clear
  extern env_stack
  extern lib_buf
  extern file_open_rd
  extern block_read
  extern block_open_read
  extern block_open_write
  extern show_hex
  extern hash_restore
  extern show_box
  extern move_cursor
  extern reset_clear_terminal

  global main,_start

main:
_start:
  call	env_stack	;save eniro ptr info
  mov	esi,esp		;setup to get parameters
  cld
  lodsd			;get count
  cmp	eax,byte 2
  je	do_decode	;jmp if no filename
  mov	ecx,err_msg
  call	crt_str
  jmp	error_exit	
do_decode:
  lodsd			;get our name
  lodsd			;get file name ptr
  mov	esi,eax
  mov	edi,filename
  call	str_move
  mov	eax,filename
  call	elfdecode
menu_loop:
  mov	eax,30003730h
  call	crt_clear
  mov	ebp,menu_table
  call	popup_menu
  or	eax,eax		;check if selecton was made
  jz	clean_up	;exit if esc
  cmp	ecx,byte 20	;
  jae	clean_up
  add	ecx,call_menu
  call	[ecx]
  jmp	menu_loop
clean_up:
  mov	[target_file_ptr],eax
  call	del_comment_file
  mov	ebx,header_file
  call	file_delete
  mov	ebx,abug_image
  call	file_delete
  mov	ebx,abug_fimage
  call	file_delete
  mov	ebx,abug_sym
  call	file_delete
  mov	ebx,abug_externs
  call	file_delete
  mov	ebx,abug_lib
  call	file_delete
  mov	ebx,abug_undo
  call	file_delete
  mov	ebx,temp_file
  call	file_delete
error_exit:
;  mov	eax,30003730h
;  call	crt_clear
;  mov	ax,0101h
;  call	move_cursor
  call	reset_clear_terminal
  mov	eax,1
  int	80h
;-----------------------------------------

;-----------------
  [section .data]
call_menu:
  dd show_summary
  dd show_symbols
  dd show_libs
  dd show_externals
  dd show_images

menu_table:
  dd	menu_text
  db	40		;columns
  db	17		;rows
  db	3		;starting col
  db	5		;starting row
  dd	30003634h	;normal color
  dd	30003436h	;button color
  dd	31003037h	;select bar color

menu_text:
 db 1,0ah
 db 1
 db ' ',2,'elf summary',1,' show elf header plus',0ah,0ah
 db ' ',2,'symbols',1,' show symbols',0ah,0ah
 db ' ',2,'dynamic libs',1,' libraries referenced',0ah,0ah
 db ' ',2,'externals',1,' dynamic functions called',0ah,0ah
 db ' ',2,'hex image',1,' image and descriptive flags',0ah,0ah
 db 0ah,0ah
 db 0ah,0ah
 db ' ',2,'-back- (ESC)',1,0ah
 db 0
  
;----------------
  [section .text]

;---------------------------------------------------------------------
show_symbols:
  mov	ebx,temp_file
  mov	edx,0666q	;premissions
  call	block_open_write
  mov	[fd_out],eax	;fd

  call	m_setup
;find size of symbol table file
  mov	ebx,abug_sym
  call	file_status_name ;sym table here?
  js	ss_skip		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size] ;get sym size
  add	eax,4096	;increase size so symbols can be added
  mov	[sym_table_size],eax ;save sym table alloc
;allocate memory for symbol table
  call	m_allocate	;allocate memory
  or	eax,eax
  js	ss_skip
  mov	[symbol_table_ptr],eax
  mov	ebx,abug_sym	;file name
  mov	ecx,eax		;buffer
  mov	edx,[sym_table_size]
  call	hash_restore
ss_skip:

  mov	eax,[preamble+pre.elf_phys_top]
  mov	[ss_stuff_adr],eax
sss_loop:
  mov	edi,ss_stuff_adr
  mov	ecx,4			;lenght of matchl
  xor	edx,edx			;offset
  call	hash_lookup		;returns eax=0 if match and esi=ptr to match
  or	eax,eax
  jz	ss_found		;jmp if label found
ss_tail:
  inc	dword [ss_stuff_adr]
  mov	eax,[ss_stuff_adr]
  cmp	eax,[preamble+pre.elf_phys_bss_end]
  jne	sss_loop
  jmp	sss_show
ss_found:
  lea	ecx,[esi+sym.sym_ascii]
  mov	[ss_string_ptr],ecx
  mov	esi,sym_entry
  mov	eax,[fd_out]	;get fd
  call	show_hex
  jmp	ss_tail  


sss_show:
  mov	ebx,[fd_out]
  call	file_close

  mov	edi,lib_buf+400
  mov	esi,asmview
  call	str_move
  inc	edi
  mov	esi,temp_file
  call	str_move
  mov	esi,lib_buf+400  
  call	sys_run_wait
  mov	eax,[symbol_table_ptr]
  ret
;-------------
  [section .data]
sym_entry:
  db -6
ss_stuff_adr:
  dd 0
  db ' ',0	;space after address
  db -10	;string ptr
ss_string_ptr:
  dd 0
  db 0ah,0,0



  [section .text]
;---------------------------------------------------------------------
show_libs:
  mov	ebx,abug_lib
  call	file_status_name ;sym table here?
  js	sl_skip		;exit if file not found
  mov	edi,lib_buf+400
  mov	esi,asmview
  call	str_move
  inc	edi
  mov	esi,abug_lib
  call	str_move
  mov	esi,lib_buf+400  
  call	sys_run_wait
sl_skip:
  ret
;---------------------------------------------------------------------
show_externals:
  mov	ebx,abug_externs
  call	file_status_name ;sym table here?
  js	se_skip		;exit if file not found
  mov	edi,lib_buf+400
  mov	esi,asmview
  call	str_move
  inc	edi
  mov	esi,abug_externs
  call	str_move
  mov	esi,lib_buf+400  
  call	sys_run_wait
se_skip:
  ret
;---------------------------------------------------------------------
show_images:
  mov	esi,wait_msg
  call	show_box
  call	m_setup
;find size of symbol table file
  mov	ebx,abug_sym
  call	file_status_name ;sym table here?
  js	si_skip		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size] ;get sym size
  add	eax,4096	;increase size so symbols can be added
  mov	[sym_table_size],eax ;save sym table alloc
;allocate memory for symbol table
  call	m_allocate	;allocate memory
  or	eax,eax
  js	si_skip
  mov	[symbol_table_ptr],eax
  mov	ebx,abug_sym	;file name
  mov	ecx,eax		;buffer
  mov	edx,[sym_table_size]
  call	hash_restore
si_skip:
;open image file
  mov	ebx,abug_image
  call	block_open_read
  mov	[image_fd],eax
  mov	ebx,abug_fimage
  call	block_open_read
  mov	[fimage_fd],eax
;open output file
  mov	ebx,temp_file
  mov	edx,0666q	;premissions
  call	block_open_write
  mov	[fd_out],eax	;fd
;write header
  mov	ecx,si_table1
  call	crt_str

  mov	eax,[preamble+pre.elf_phys_top]
  mov	[si_stuff_adr],eax

;read loop
si_loop:
  mov	edi,si_stuff_adr
  mov	ecx,4			;lenght of matchl
  xor	edx,edx			;offset
  call	hash_lookup		;returns eax=0 if match and esi=ptr to match
  or	eax,eax
  jnz	si_sect			;jmp if label not found
  lea	ecx,[esi+sym.sym_ascii]
  call	crt_str
  mov	ecx,eol
  call	crt_str
;check if section starts here
si_sect:
  lea	esi,[preamble+pre.sheader_ptrs]
  mov	eax,[si_stuff_adr]	;get current address
si_sect_lp:
  mov	edx,[esi]		;get entry ptr
  or	edx,edx
  jz	si_read			;jmp if end of pointers
  cmp	eax,[edx]		;check if section start
  je	si_sect_fnd		;jmp if section found
  add	esi,4
  jmp	si_sect_lp
si_sect_fnd:
  lea	ecx,[edx+sect.sh_name]
  call	crt_str
  mov	ecx,eol
  call	crt_str
;read image byte
si_read:
  mov	ebx,[image_fd]	;fd
  mov	ecx,si_stuff_image ;buffer
  mov	edx,1		;read one byte
  call	block_read
  cmp	al,1
  jne	si_show

  mov	ebx,[fimage_fd]
  mov	ecx,si_stuff_fimage
  mov	edx,1
  call	block_read
  cmp	al,1
  jne	si_show
;we have read bytes from the two files.
  mov	esi,si_table2
  mov	eax,[fd_out]	;get fd
  call	show_hex
  add	[si_stuff_adr],dword 1
  jmp	si_loop

si_show:
  mov	ebx,[fd_out]
  call	file_close

  mov	edi,lib_buf+400
  mov	esi,asmview
  call	str_move
  inc	edi
  mov	esi,temp_file
  call	str_move
  mov	esi,lib_buf+400  
  call	sys_run_wait
  mov	eax,[symbol_table_ptr]
  call	m_close
  ret  
;---------------
  [section .data]

sym_table_size	dd 0
symbol_table_ptr dd 0

si_table1:
  db 0ah
  db 'image    data flag',0ah
  db 'address  file set',0ah
  db '-------- ---- ----',0ah,0


si_table2:
  db -6
si_stuff_adr:
  dd 0
  db ' ',0	;space after address
  db -4
si_stuff_image:
  db 0
  db '     ',0	;space after image
  db -4
si_stuff_fimage:
  db 0
  db 0ah,0,0
   
  db 0

image_fd:  dd 0
fimage_fd: dd 0

wait_msg:
  dd	30003634h	;normal color
  dd	wait_text
  dd	wait_text_end
  dd	0		;scroll
  db	40		;columns
  db	17		;rows
  db	5		;starting row
  db	3		;starting column
  dd	30003730h	;outline  color

wait_text: db 0ah,0ah,0ah,'             Working '
wait_text_end:

  [section .text]
;---------------------------------------------------------------------
show_summary:
  mov	ebx,temp_file
  mov	edx,0666q	;premissions
  call	block_open_write
  mov	[fd_out],eax	;fd
;show file name
  mov	ecx,file_msg
  call	crt_str
;show elf_type flag
  mov	ebp,elf_type_tbl
  call	show_numbers
;show preamble addresses
  mov	ebp,map_table
  call	show_numbers
;show app_main
  mov	ebp,app_main
  call	show_numbers
;show pointers in preamble
  mov	ebp,ptr_table
  call	show_numbers
;show program headers

  mov	ecx,phead_msg
  call	crt_str		;show header

  mov	ecx,preamble+pre.pheader_ptrs
sp_loop:
  mov	ebp,ptable  
  mov	[ptable1],ecx	;save address
  mov	esi,[ecx]	;get sect. ptr
  or	esi,esi
  jz	sp_done
  mov	edi,ptable1
  mov	eax,esi
  stosd			;store pointer
  lodsd
  stosd			;store start
  lodsd
  stosd			;store end
  lodsd
  stosd			;store size
  lodsd
  stosd			;store offset
  lodsb
  stosb			;store flag
  push	ecx
  mov	eax,1		;stdout
  call	show_numbers
  pop	ecx
  add	ecx,4		;next phead
  jmp	short sp_loop
sp_done:
  

  mov	ecx,shead_msg
  call	crt_str		;show header

  mov	ecx,preamble+pre.sheader_ptrs
ss_loop:
  mov	ebp,stable  
  mov	[stable1],ecx	;save address
  mov	esi,[ecx]	;get sect. ptr
  or	esi,esi
  jz	ss_done
  mov	edi,stable1
  mov	eax,esi
  stosd			;store pointer
  lodsd
  stosd			;store start
  lodsd
  stosd			;store size
  lodsb
  stosb			;store flag
;store the name
  mov	edi,sname
ss_lp2:
  lodsb
  or	al,al
  jz	ss_name_end
  stosb
  jmp	ss_lp2
ss_name_end:
;fill blanks to end of field
ss_lp3:
  cmp	byte [edi],0ah
  je	ss_show
  mov	byte [edi],' '
  inc	edi
  jmp	short ss_lp3
ss_show:
  push	ecx
  mov	eax,1		;stdout
  call	show_numbers
  pop	ecx
  add	ecx,4		;next phead
  jmp	short ss_loop
ss_done:

  mov	ecx,s_flag_msg
  call	crt_str
  mov	ebx,[fd_out]
  call	file_close

  mov	edi,lib_buf+400
  mov	esi,asmview
  call	str_move
  inc	edi
  mov	esi,temp_file
  call	str_move
  mov	esi,lib_buf+400  
  call	sys_run_wait

  ret  


  [section .text]

;------------------------------------------------------
;%include "show_numbers.inc"
	%define stdout 0x1
	%define stderr 0x2

  extern hex_dump_stdout
  extern byteto_hexascii
  extern wordto_hexascii
  extern dwordto_hexascii

;----------------------------------------------------  
;>1 crt
;   show_numbers - display assorted numbers
; INPUTS
;    [fd_out] global set with fd (1=stdout) 
;    ebp = control  table
;
;    The control table is normal ascii with embedded
;    codes to indicate where numberss are needed.  Numbers
;    are shown in hex.
;    Embedded codes: -1 = ptr to byte follows
;                    -2 = ptr to word follows
;                    -3 = ptr to dword follows
;                    -4 = dump, followed by db count
;                                           dd ptr          
; OUTPUT
;   uses current color, see crt_set_color, crt_clear
; NOTES
;   source  file show_numbers.asm
;<
;  * ---------------------------------------------------
show_numbers:
sn_lp:
  mov	ecx,ebp			;get table ptr
  mov	al,[ecx]		;get first byte
  or	al,al
  js	sn_number		;jmp if number here
  jz	sn_done			;zero terminates table
  call	crt_str
  add	ebp,edx			;move ptr fwd
  inc	ebp			;adjust for zero at end of str
  jmp	short sn_lp
sn_done:
  ret
  	
sn_number:
  cmp	al,-1
  je	sn_byte
  cmp	al,-2
  je	sn_word
  cmp	al,-3
  je	sn_dword
;assume this is block dump
  add	ebp,6			;move to next table entry
  mov	esi,[ecx+2]		;get data ptr
  movzx ecx,byte [ecx+1]	;get length of dump
  call	hex_dump_stdout
  jmp	sn_lp
sn_byte:
  mov	eax,[ecx+1]		;get ptr to data
  mov	al,[eax]		;get data
  mov	edi,hex_build
  call	byteto_hexascii
  jmp	num_tail
sn_word:
  mov	eax,[ecx+1]		;get ptr to data
  mov	ax,[eax]		;get data
  mov	edi,hex_build
  call	wordto_hexascii
  jmp	num_tail
sn_dword:
  mov	eax,[ecx+1]		;get ptr to data
  mov	eax,[eax]		;get data
  mov	edi,hex_build
  call	dwordto_hexascii
num_tail:
  mov	ecx,hex_build
  call	crt_str
  add	ebp,5			;move to next table entry
  xor	eax,eax
  mov	[hex_build],eax		;clear build area
  mov	[hex_build+4],eax
  jmp	sn_lp
;----------------------------
; input: ecx=sting ptr

crt_str:
  xor edx, edx
count_again:	
  cmp [ecx + edx], byte 0x0
  je crt_write
  inc edx
  jmp short count_again

crt_write:
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx,[fd_out]			; file desc. is stdout
  int byte 0x80
  ret
;---------------
  [section .data]
fd_out: dd 1
hex_build: db 0,0,0,0,0,0,0,0,0
  [section .text]

%include "elfdecode.inc"
;---------------
  [section .data]
file_msg: db 0ah,'File decoded='
filename: db 'test',0
	times 100 db 0

elf_type_tbl:
 db 0ah,'elf_type_flag=',0,-3
 dd preamble+pre.elf_type_flag
 db 0ah,'   (40-NoSect 20-comments 10-src 8-debug 4-syms 2-lib 1-dynamic)',0ah,0
 db 0 ;end of table
;--------------------------
map_table:
 db 'top       =',0,-3
 dd preamble+pre.elf_phys_top

 db ' code_start=',0,-3
 dd preamble+pre.elf_phys_code_start

 db ' entry    =',0,-3
 dd preamble+pre.elf_phys_exec_entry

 db 0ah,0

 db 'code_end  =',0,-3
 dd preamble+pre.elf_phys_code_end

 db ' load_end  =',0,-3
 dd preamble+pre.elf_phys_load_end

 db ' bss_end  =',0,-3
 dd preamble+pre.elf_phys_bss_end
 db 0ah,0,0 ;end of table
;--------------------------

app_main:
 db 'app_main=',0,-3
 dd preamble+pre.app_main
 db ' entry if lib put header at front',0ah,0
 db 0

;------------------------

;show pheader pointers in preamble

ptr_table:
 db 'pheader_ptrs=',0
 db -3
 dd preamble+pre.pheader_ptrs
 db ' ',0
 db -3
 dd preamble+pre.pheader_ptrs+4
 db ' ',0
 db -3
 dd preamble+pre.pheader_ptrs+8
 db ' ',0
 db -3
 dd preamble+pre.pheader_ptrs+12
 db ' ',0
 db -3
 dd preamble+pre.pheader_ptrs+16
 db ' ',0
 db -3
 dd preamble+pre.pheader_ptrs+20

;show sheader pointers in preamble

 db 0ah,'sheader_ptrs=',0
 db -3
 dd preamble+pre.sheader_ptrs
 db ' ',0
 db -3
 dd preamble+pre.sheader_ptrs+4
 db ' ',0
 db -3
 dd preamble+pre.sheader_ptrs+8
 db ' ',0
 db -3
 dd preamble+pre.sheader_ptrs+12
 db ' ',0
 db -3
 dd preamble+pre.sheader_ptrs+16
 db ' ',0
 db -3
 dd preamble+pre.sheader_ptrs+20
 db 0ah,0ah,0,0	;end of table
;--------------------------------------

phead_msg:
 db ' head-ptr strt-adr end-adr  size     offset   p_flag',0ah
 db ' -------- -------- -------- -------- -------- --------',0ah,0

ptable:
 db ' ',0,-3
 dd ptable1	;address

 db ' ',0,-3
 dd ptable2	;phys_start

 db ' ',0,-3
 dd ptable3	;phys_end

 db ' ',0,-3
 dd ptable4	;size

 db ' ',0,-3
 dd ptable5	;offset

 db ' ',0,-1
 dd ptable6	;p_flags
 db 0ah,0
 db 0	;end of table

ptable1 dd 0
ptable2 dd 0
ptable3 dd 0
ptable4 dd 0
ptable5 dd 0
ptable6 db 0

;----------------------------------------------

shead_msg:
 db '  (p_flag  8=bss 4=read 2=write 1=exec)',0ah
 db 0ah
 db ' sect-ptr strt-adr size     s_flag   name',0ah
 db ' -------- -------- -------- -------- ----------------------',0ah,0

stable:
 db ' ',0,-3
 dd stable1	;address

 db ' ',0,-3
 dd stable2	;phys_start

 db ' ',0,-3
 dd stable3	;size

 db ' ',0,-1
 dd stable4	;s_flags
 db '       '
sname:
 db '                   ',0ah,0

 db 0	;end of table

stable1 dd 0
stable2 dd 0
stable3 dd 0
stable4 db 0

s_flag_msg:
 db '  (s_flag  4=execute 2=allocaate 1=writeable',0ah,0

;--------------
eol	db 0ah,0
temp_file	db 'temp_file',0
asmview		db 'asmview',0
err_msg:
  db 0ah,'elfdecode requires a file name',0ah
  db 'restart with  - elfdecode <filename> -',0ah,0

  [section .text]

