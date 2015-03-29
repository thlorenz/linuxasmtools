
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
;**********  asmsrc.asm *************************

; asmsrc uses files created by AsmDis, AsmBug to write source file.
; input files are stored in the current
;   abug_header.dat  - status of last executable disassembled
;   abug_image.dat    - load image of last executable
;   abug_fimage.dat   - flags image describing executable
;   abug_sym.dat      - symbol table for last executable
;   abug_externs.txt  - list of extern's if file used dynamic lib
;   abug_lib.txt      - list of dynamic libraries used
;
;              asmsrc <file>
;
;
%macro _mov 2
  push	byte %2
  pop	%1
%endmacro

  extern env_stack
  extern dir_current
  extern dir_access
  extern crt_str,crt_write
  extern str_move
  extern file_status_name
  extern m_setup,m_allocate
;%include "memory.inc"
  extern block_read_all
;  extern crt_clear
  extern hash_lookup
  extern hash_restore
  extern sys_run_die
  extern dis_one,symbol_process
  extern mouse_enable
  extern install_signals
  extern read_window_size,crt_rows,crt_columns
  extern dwordto_hexascii,wordto_hexascii,byteto_hexascii
  extern crt_set_color
  extern blk_bmove
  extern read_stdin
  extern cursor_hide,cursor_unhide
  extern message_box,show_box,kbuf
  extern block_write_all
  extern hash_archive
  extern view_file
  extern block_write
  extern block_open_write
  extern str_end
  extern block_close
  extern reset_clear_terminal
   
global _start
_start:
  cld
  call	env_stack
  call	read_window_size
  call	parse_inputs
  or	eax,eax
  jz	dad_05		;jmp if normal continue
  js	dad_exitj	;exit if error
  mov	eax,[target_file_ptr]
  call	elfdecode
dad_05:
  call	mouse_enable
  call	signal_install
  call	m_setup		;setup the memory manager
;load files into memory
  call	read_files
  or	eax,eax
  jns	dad_10		;jmp if file read ok
;display read error
  mov	eax,err2
  call	show_boxed_msg
dad_exitj:
  jmp	short dad_exit
dad_10:
;set flags in flag image
dad_20:
  xor	eax,eax
  mov	[symbol_process],eax	;disable symbol fill in
  call	code_hunt
  jecxz	dad_25			;jmp if code hunt succesful
  cmp	byte [warn_flag],0
  jne	dad_25
  dec	esi			;go back to instruction that failed
  call	show_warning		;ecx=warn type  esi=offset
dad_25:
  call	data_hunt
dad_30:
  call	open_src_out
  call	write_initial_comments
  test	[preamble+pre.elf_type_flag],byte 1 ;dynamic?
  jnz	write_dynamic_sections 
  call	write_code
  call	write_data
  call	write_bss
  jmp	dad_exit1
;write sections (dymanic file)
write_dynamic_sections:
  call	write_lib_names
  call	write_externs
  call	write_sections
dad_exit1:
  call	reset_clear_terminal
dad_exit:
  _mov	ebx,0
  _mov	eax,1
  int	80h
;-----------------------------------------------------------
open_src_out:
;form output file name
  lea	esi,[preamble+pre.target_file]
  call	str_end
  mov	edi,esi
aw_lp:
  dec	esi
  cmp	esi,preamble+pre.target_file
  je	aw_20			;jmp if no '/' found
aw_10:
  cmp	byte [esi],'/'
  jne	aw_lp			;loop till '/' found
  inc	esi			;move past '/'
  mov	ebx,esi			;set name ptr
  mov	esi,src_string
  call	str_move
  jmp	short aw_30
aw_20:
  mov	esi,src_string
  call	str_move		;append .src
  lea	ebx,[preamble+pre.target_file]
;open output file
aw_30:
  xor	edx,edx			;default attributes
  call	block_open_write
  mov	[file_handle],ebx
  ret
;-----------------------------------------------------------
write_initial_comments:
  mov	edi,lib_buf				;message build area
  mov	esi,rec1	;input file:
  call	str_move
  lea	esi,[preamble+pre.target_file]
  call	move_and_write	;move esi -> edi and write lib_buf

  mov	esi,rec2
  call	str_move
  mov	esi,yes
  test	[preamble+pre.elf_type_flag],byte 1
  jnz	wic_10		
  mov	esi,no
wic_10:
  call	move_and_write

  mov	esi,rec3
  call	str_move
  mov	esi,yes
  test	[preamble+pre.elf_type_flag],byte 2
  jnz	wic_20		
  mov	esi,no
wic_20:
  call	move_and_write

  mov	esi,rec4
  call	str_move
  mov	esi,yes
  test	[preamble+pre.elf_type_flag],byte 4
  jnz	wic_30		
  mov	esi,no
wic_30:
  call	move_and_write

  mov	esi,rec5
  call	str_move
  mov	esi,yes
  test	[preamble+pre.elf_type_flag],byte 8
  jnz	wic_40		
  mov	esi,no
wic_40:
  call	move_and_write

  test	byte [preamble+pre.elf_type_flag],1h	;check if dynamic
  jnz	wic_dynamic
  mov	esi,static_msg
  jmp	short wic_50
wic_dynamic:
  mov	esi,dynamic_msg
wic_50:
  call	move_and_write
;set start label global
  mov	edi,preamble+pre.elf_phys_exec_entry
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  or	esi,esi
  jz	wic_60		;jmp if not found
;esi points to symbol name
  add	esi,byte 5
  mov	edi,gsm_insert
  call	str_move
  mov	al,0ah
  stosb
  mov	al,0
  stosb
wic_60:
  mov	edi,lib_buf
  mov	esi,global_start_msg
  call	move_and_write

  ret
;--------------
  [section .data]
src_string	db	'.src',0
yes		db	'yes',0
no		db	'no',0

rec1: db 0ah,';Target file: ',0
rec2: db 0ah,';Dynamic Libraries found: ',0
rec3: db 0ah,';Lib startup code wrapper found: ',0
rec4: db 0ah,';Symbol table found: ',0
rec5: db 0ah,';Debug symbols found: ',0

dynamic_msg: db 0ah,0ah
 db ';dynamic load file',0ah
 db '; Compile with:  nasm -felf xxxx.asm -o xxxx.o',0ah
 db ';                gcc xxxx.o -o xxxx',0ah
 db '; (xxxx = filename)',0ah,0ah,0
static_msg: db 0ah,0ah
 db ';static load file',0ah
 db '; Compile with:  nasm -felf xxxx.asm -o xxxx.o',0ah
 db ';                ld xxxx.o -o xxxx',0ah
 db '; (xxxx = filename)',0ah,0ah,0
global_start_msg:
 db 0ah,' global '
gsm_insert db '_start',0ah,0
  times 20 db 0		;needed for expansion of above

  [section .text]
;-------------------------------------------
; input: esi=string to move
;        edi=append point for string
;        [lib_buf] = output string
; output: edi = lib_buf ptr
;
move_and_write:
  call	str_move
  mov	ebx,[file_handle]
  mov	ecx,lib_buf		;buf
  mov	edx,edi			;end of write area
  sub	edx,lib_buf		;compute lenght of write data
  call	block_write
  mov	edi,lib_buf
  ret
;-----------------------------------------------------------
write_lib_names:
  mov	ebx,lib_fname
  mov	ecx,work_buf		;temp buffer
  mov	edx,20000               ;size of buffer
  call	block_read_all
  js	wln_exit		;jmp if error, or no file
 
  mov	ebx,[file_handle]
  mov	ecx,work_buf
  mov	edx,eax			;get size of write
  call	block_write
wln_exit:
  ret

lib_fname:  db '.abug_lib.txt',0  

;-----------------------------------------------------------
write_externs:

  mov	ebx,ext_fname
  mov	ecx,work_buf		;buffer area
  mov	edx,20000               ;;size of buffer
  call	block_read_all
  js	wei_exit		;exit if error

  mov	ebx,[file_handle]
  mov	ecx,work_buf		;buf
  mov	edx,eax			;size of  write
  call	block_write
wei_exit:
 ret

ext_fname:  db '.abug_externs.txt',0

;-----------------------------------------------------------
write_code:
  mov	ebp,preamble+pre.pheader_ptrs-4
wc_lp:
  add	ebp,4		;move to next pheader ptr
  mov	esi,[ebp]	;get ptr
  or	esi,esi		;end of ptrs?
  jz	wc_done		;jmp if end of ptrs

  test	[esi+head.p_flags],byte 1 ;executable block?
  jz	wc_lp	;jmp if not executable

  push	esi
  push	ebp  
  mov	ebx,[file_handle]
  mov	ecx,section_text	;output data
  mov	edx,section_text_end - section_text ;size of  write
  call	block_write
  pop	ebp
  pop	esi
;setup bounds for section
  mov	eax,[esi+head.phys_start]
  cmp	eax,[preamble+pre.elf_phys_top]	;is elf header here?
  jne	wc_100				;jmp if no elf header here
  mov	eax,[preamble+pre.elf_phys_code_start] ;skip over header
wc_100:
  sub	eax,[preamble+pre.elf_phys_top]	;compute .text offset
  mov	[section_top_offset],eax
  mov	[display_mode],byte 0

  mov	eax,[esi+head.phys_end]
  sub	eax,[preamble+pre.elf_phys_top]
  mov	[section_end_offset],eax

  push	ebp
  call	write_section
  pop	ebp
  jmp	wc_lp

wc_done:
  ret
;---------
  [section .data]
section_text:
  db 0ah,'  [section .text]',0ah
section_text_end:

  [section .text]
;-----------------------------------------------------------
write_data:
  mov	ebp,preamble+pre.pheader_ptrs-4
wd_lp:
  add	ebp,4		;move to next pheader ptr
  mov	esi,[ebp]	;get ptr
  or	esi,esi		;end of ptrs?
  jz	wd_done		;jmp if end of ptrs
  mov	cl,[esi+head.p_flags] ;get flags
  test	cl,1		 ;executable block?
  jnz	wd_lp		;jmp (ingore) if executable
  test	cl,2		;writable
  jz	wd_lp		;ignore if not writable
  test	cl,8		;bss
  jnz	wd_lp		;ignore if .bss

  push	ebp
  push	esi
  mov	ebx,[file_handle]
  mov	ecx,section_data	;output data
  mov	edx,section_data_end - section_data ;size of  write
  call	block_write
  pop	esi
  pop	ebp

;setup bounds for section
  mov	eax,[esi+head.phys_start]
  sub	eax,[preamble+pre.elf_phys_top]	;compute .text offset
  mov	[section_top_offset],eax
  mov	[display_mode],byte 1

;
  mov	eax,[esi+head.phys_end]
  sub	eax,[preamble+pre.elf_phys_top]
  mov	[section_end_offset],eax

  push	ebp
  call	write_section
  pop	ebp
  jmp	wd_lp
wd_done:
  ret
;---------
  [section .data]
section_data:
  db 0ah,'  [section .data]',0ah
section_data_end:

  [section .text]
;-----------------------------------------------------------
write_bss:
  mov	ebp,preamble+pre.pheader_ptrs-4
wb_lp:
  add	ebp,4		;move to next pheader ptr
  mov	esi,[ebp]	;get ptr
  or	esi,esi		;end of ptrs?
  jz	wb_done		;jmp if end of ptrs
  mov	cl,[esi+head.p_flags] ;get flags
  test	cl,8		 ;executable block?
  jz	wb_lp		;jmp if not .bss block

  push	ebp
  push	esi
  mov	ebx,[file_handle]
  mov	ecx,section_bss	;output data
  mov	edx,section_bss_end - section_bss ;size of  write
  call	block_write
  pop	esi
  pop	ebp

;setup bounds for section
  mov	eax,[esi+head.phys_start]
  sub	eax,[preamble+pre.elf_phys_top]	;compute .text offset
  mov	[section_top_offset],eax
  mov	[display_mode],byte 2

  mov	eax,[esi+head.phys_end]
  sub	eax,[preamble+pre.elf_phys_top]
  mov	[section_end_offset],eax

  push	ebp
  call	write_section
  pop	ebp
  jmp	wb_lp
wb_done:
  mov	ebx,[file_handle]
  call	block_close
  ret
;---------
  [section .data]
section_bss:
  db 0ah,'  [section .bss]',0ah
section_bss_end:

  [section .text]
;-----------------------------------------------------------
write_sections:
  mov	ebp,preamble+pre.sheader_ptrs-4
ws_loop:
  add	ebp,4		;move to next pheader ptr
  mov	ebx,[ebp]	;get ptr
  or	ebx,ebx		;end of ptrs?
  jz	ws_done		;jmp if end of ptrs
  lea	esi,[ebx+sect.sh_name] ;get section name ptr
  cmp	[esi],dword '.tex'
  jne	ws_20		;jmp if not  text section
  call	write_section_name
  mov	al,0		;.text
  jmp	short write_it
ws_done:
  ret

ws_20:
  cmp	[esi],dword '.rod'
  jne	ws_30		;jmp if not rodata section
  call	write_section_name
  mov	al,1		;.rodata
  jmp	short write_it

ws_30:
  cmp	[esi],dword '.dat'
  jne	ws_40		;jmp if not .data
  call	write_section_name
  mov	al,1
  jmp	short write_it

ws_40:
  cmp	[esi],dword '.bss'
  jne	ws_loop
  call	write_section_name
  mov	al,2		;.bss
write_it:
  mov	[display_mode],al
  mov	eax,[ebx+sect.sh_addr]
  sub	eax,[preamble+pre.elf_phys_top]	;compute .text offset
  mov	[section_top_offset],eax

  add	eax,[ebx+sect.sh_size]		;compute phys end
  mov	[section_end_offset],eax

  push	ebp
  call	write_section
  pop	ebp
  jmp	ws_loop

;-----------------------------------------
write_section_name:
  push	ebp
  push	ebx
  mov	edi,lib_buf
  push	esi
  mov	esi,name_pre
  call	str_move
  pop	esi
  call	str_move
  mov	al,']'
  stosb
  mov	al,0ah
  stosb
  mov	edx,edi
  sub	edx,lib_buf	;compute length
  mov	ecx,lib_buf
  mov	ebx,[file_handle]
  call	block_write
  pop	ebx
  pop	ebp
  ret
;----------
  [section .data]
name_pre: db '  [section ',0
  [section .text]  
;-----------------------------------------------------------
;write section
%include "write_section.inc"
;-----------------------------------------------------------
;data_hunt:
%include "data_hunt.inc"
;-----------------------------------------------------------
%include "code_hunt.inc"
;-----------------------------------------------------------
; check if symbol within "load" range
;  input: eax=address
;  output: carry set if out of range
;
check_range:
  cmp	eax,[preamble+pre.elf_phys_top]
  jb	cr_bad
  cmp	eax,[preamble+pre.elf_phys_bss_end]
  jb	cr_good		 ;jmp if symbol within load range
cr_bad:
  stc
  jmp	short cr_exit
cr_good:
  clc
cr_exit:
  ret
;-----------------------------------------------------------
;return eax= negative if error
; store pointers to files: [load_image_ptr]
;                          [flag_image_ptr]
;                          [symbol_table_ptr]
read_files:
;set section sizes, assume "preamble" build or read already
  mov	eax,[preamble+pre.elf_phys_code_end] ;get code end
  sub	eax,[preamble+pre.elf_phys_top]	;compute offset
  mov	[code_section_end_off],eax
;find data section size
  mov	al,2		;writable flag
  call	find_pheader_type
  jz	rf_bss		;jmp if no writeable blocks
  mov	eax,[ebx+head.size]	
  mov	[data_section_size],eax
;find .bss section size
rf_bss:
  mov	al,8
  call	find_pheader_type
  jz	no_bss		;jmp if no .bss blocks
  mov	eax,[ebx+head.size]
  mov	[bss_section_size],eax
no_bss:
;find size of load image file
  mov	ebx,abug_image
  call	file_status_name
  js	rf_exitj		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size]
  mov	[load_image_size],eax
;allocate memory for load image
  call	m_allocate
  or	eax,eax
  js	rf_exitj
;read load image into memory
  mov	[load_image_ptr],eax
  mov	ecx,eax		;buffer to ecx
  mov	edx,[load_image_size]	;file size
  mov	ebx,abug_image	;file name
  call	block_read_all		;open and read file
  or	eax,eax
  js	rf_exitj

;find size of flag image file
  mov	ebx,abug_fimage
  call	file_status_name
rf_exitj:
  js	rf_exit		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size]
  mov	[flag_image_size],eax
;allocate memory for flag image
  call	m_allocate
  or	eax,eax
  js	rf_exit
;read flag image into memory
  mov	[flag_image_ptr],eax
  mov	ecx,eax		;buffer to ecx
  mov	edx,[flag_image_size]	;file size
  mov	ebx,abug_fimage	;file name
  call	block_read_all		;open and read file
  or	eax,eax
  js	rf_exit

;find size of symbol table file
  mov	ebx,abug_sym
  call	file_status_name
  js	rf_exit		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size]
  add	eax,4096	;increase size so symbols can be added
  mov	[sym_table_size],eax
;allocate memory for symbol table
  call	m_allocate
  or	eax,eax
  js	rf_exit
  mov	[symbol_table_ptr],eax
  mov	ebx,abug_sym	;file name
  mov	ecx,eax		;buffer
  mov	edx,[sym_table_size]
  call	hash_restore
;allocate memory and  read comment file if available
  call	comment_setup
rf_exit:
  ret

;-----------------------------------------------------------
; output:  eax negative = error
;          eax zero = continue, files built
;          eax non-zero and positive, call elfdecode
parse_inputs:
  call	dir_current	;puts current working dir in lib_buf
  mov	ecx,7		;check for  read/write/execute
  call	dir_access
  or	eax,eax
  jp	pi_05		;jmp if current directory can be accessed
;error, can not access current dir
  mov	eax,err1
  call	show_boxed_msg
  jmp	pi_exit1
pi_05:
;check if filename provided
  mov	esi,esp
  lodsd			;clear return address from stack
  lodsd			;get parameter count, 1=none
  dec	eax
  jnz	pi_10		;jmp if parameter entered
;no filename was provided, check if history file exists
;The history file is a image of header1
  mov	ebx,history_file
  mov	ecx,preamble
  mov	edx,20000	;dummy size
  call	block_read_all
  or	eax,eax
  js	pi_err			;jmp if history not found
;adjust addresses in history file
  mov	ebx,phead	;first .head adr
  sub	ebx,[preamble+pre.pheader_ptrs]	;compute delta
;add delta to each address
  mov	esi,preamble+pre.pheader_ptrs
  mov	edi,esi
adjust_loop:
  lodsd
  or	eax,eax
  jz	update_tail
  add	eax,ebx
update_tail:
  stosd
  cmp	esi,preamble+pre.target_time	;are we done
  jb	adjust_loop	
 
  jmp	pi_exit3		;jmp if history found
;no history file and no parametes, what now?
pi_err:
  mov	ecx,help_msg
  call	crt_str
  jmp	pi_exit1
;get target file to disassemble
pi_10:
  lodsd			;eax=our executable name ptr
  lodsd			;eax=ptr to user parameter
  mov	[target_file_ptr],eax ;save filename ptr
  mov	esi,eax
  mov	edi,preamble+pre.target_file
  call	str_move
  mov	eax,1		;enable elfdecode execution
  jmp	pi_exit2
pi_exit3:
  xor	eax,eax
  jmp	short pi_exit2
pi_exit1:
  _mov	eax,-1
pi_exit2:
  or	eax,eax
  ret
;--------------------
  [section .data]
help_msg: db 0ah,0ah
  db 'File required, try:  asmsrc <file> ',0ah,0
history_file: db ".abug_header.dat",0	;image of header1
  [section .text]
;-----------------------------------------------------------
; input: edx = physical address
; output: ebp = offset of physical address
physical2offset:
  mov	ebp,edx
  sub	ebp,[preamble+pre.elf_phys_top]
  ret
;-----------------------------------------------------------
; input: ebp=offset
; output: edx=physical address
offset2physical:
  mov	edx,ebp
  add	edx,[preamble+pre.elf_phys_top]
  ret
;-----------------------------------------------------------
; input: ebp=offset
; output: edx=ptr to code in load_image
offset2code_ptr:
  mov	edx,ebp
  add	edx,[load_image_ptr]
  ret
;-----------------------------------------------------------
; input:  ebp=offset
; output: edx=ptr to flag image data
offset2flag_ptr:
  mov	edx,ebp
  add	edx,[flag_image_ptr]
  ret
;-----------------------------------------------------------
;input: al = type code 1=exec 2=write 4=read 8=bss
;output: if "jnz" true then ebx=ptr to head struc
;        if "jz" true then pheader not found 
find_pheader_type:
  lea	esi,[preamble+pre.pheader_ptrs]
fpt_lp:
  mov	ebx,[esi]	;get pointer
  or	ebx,ebx
  jz	fpt_fail	;jmp if not found
  test	[ebx+head.p_flags],al ;check type
  jnz	fpt_found	;jmp if found
  add	esi,4
  jmp	short fpt_lp
fpt_fail:
fpt_found:
  ret

;-----------------------------------------------------------
;
; input: esi=offset of error
;        ecx=error type
;           1-illegal inst
;           2-embedded inst
;           3-embedded inst
;           4-operand
;
show_warning:
  mov	dword [warn_type],'code'
  mov	dword [warn_type+4],'    '
  cmp	cl,4
  jne	sw_40
  mov	dword [warn_type],'oper'
  mov	dword [warn_type+4],'and '
sw_40:
  add	esi,[preamble+pre.elf_phys_top]
  mov	eax,esi
  mov	edi,warn_adr
  call	dwordto_hexascii
  mov	eax,warn_msg
  call	show_boxed_msg
  cmp	byte [kbuf],'c'
  jne	sw_exit
  mov	[warn_flag],byte 1
sw_exit:
  ret
;--------------------
  [section .data]

warn_flag: db 0	;0=allow warnings 1=disable warnings

warn_msg:
 db 'Warning at '
warn_adr:
 db '        ',0ah
 db 'check '
warn_type:
 db 'operand ',0ah
;db 'code    '
 db 'w-warn c-warn off',0

;-----------------------------------------------------------
; input: eax=message ptr
;
show_boxed_msg:
  mov	[msg_stuff1],eax
  mov	esi,eax
sbm_lp:
  lodsb
  or	al,al
  jnz	sbm_lp
  dec	esi
  mov	[msg_end1],esi
  mov	esi,msg_block
  call	message_box
  ret
;------------
  [section .data]
msg_block:
  dd  30003436h	;color
msg_stuff1:
  dd  0
msg_end1:
  dd  0
  dd  0		;scroll
  db  20	;columns inside box
  db  4		;rows inside box
  db  4		;starting row
  db  8		;starting column
  dd  30003634h	;box outline color

  [section .text]
;-----------------------------------------------------------
signal_install:
  mov	ebp,signal_table
  call	install_signals
  ret

signal_uninstall:
  mov	dword [sig_mod1],0
  call	signal_install
  mov	dword [sig_mod1],winch_signal
  ret

winch_signal:
;  mov	byte [setup_flag],1
  ret
;--------------------------------------------------
  [section .data align=4]

signal_table:
  db	28
sig_mod1:
  dd	winch_signal
  dd	0
  dd	0
  dd	0
  db	0		;end of install table

;%include "../ElfDecode/system.inc"
%include "../ElfDecode/elfdecode.inc"

  [section .data align=4]
;-----------------------
;
overlay:
load_image_ptr	dd	0 ;     shared or relocated local)
flag_image_ptr	dd	0 ;     shared or relocated local)
symbol_table_ptr dd	0 ;     (relocated local)

load_image_size	dd	0
flag_image_size dd	0
sym_table_size	dd	0

code_section_end_off dd	0
data_section_size  dd	0
bss_section_size   dd	0

err1: db 0ah,'Error, can not access'
	db 0ah,' current directory',0ah,0
err2: db 0ah,'Error, can not access'
	db 0ah,' file',0ah,0
err4: db 0ah,'Error, Insufficient memory',0ah,0
err5: db 0ah,'Error, Code flag'
	db 0ah,' image corrupted',0ah,0
no_data_msg: db "no data section,"
	db 0ah," Press any key",0
no_bss_msg:  db "no .bss section,"
	db 0ah," Press any key",0

;asmpre_txt:
;pre_browse: db "asmpre",0,"-",0
;asmsrc_txt: db "asmsrc",0,0

;history_file: db ".asmdis_history.dat",0	;image of header1
;asmdis_image: db ".asmdis_image.dat",0 ;load image
;asmdis_fimage: db ".asmdis_fimage.dat",0 ;flag image
;asmdis_sym:    db ".asmdis_sym.dat",0
;asmdis_undo:  db ".asmdis_undo.dat",0
;-----------------------

  [section .bss align=4]

;display variables
display_mode	resd 1	;0=code 1=data 2=bss
section_top_offset resd 1	;offset from load_image_ptr
win_top_offset     resd 1	;offset currently at top of window
select_bar_offset  resd 1	;offset of select bar
section_end_offset resd 1	;end of current section

display_lines      resb 1	;lines for display page, add 4 to include menu
top_of_win_line    resb 1       ;list at top of page (menu above)
end_of_win_line    resb 1	;start of memu at end of page
top_of_win_column  resb 1
comment_column     resb 1	;start of comment
end_of_win_column  resb 1

file_handle	resd	1	;output file
;-----------------------
;-----------------------
work_buf:   resb	20000
;bss_end:		;memory managed by memory_manager follows

