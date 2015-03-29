
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
;**********  asmdis.asm *************************

; asmdis is an interactive disassembler.  The
; files are stored in the current directory by asmdis:
;   abug_header.dat  - status of last executable disassembled
;   abug_image.dat    - load image of last executable
;   abug_fimage.dat   - flags image describing executable
;   abug_sym.dat      - symbol table for last executable
;   abug_externs.txt  - list of extern's if file used dynamic lib
;   abug_lib.txt      - list of dynamic libraries used
;
; If asmdis is started without any parameters it will try to
; continue last secession by loading the above files.  If above
; files are not found it will request a file to disassemble.
; Normally, asmdis is started and the target file is a parameter
; as follows.
;              asmdis <file>
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
  extern crt_clear
  extern hash_lookup
  extern hash_restore
  extern sys_run_die
  extern dis_one,symbol_process
  extern mouse_enable
;  extern crt_type
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
  extern reset_clear_terminal
   
global _start
_start:
  cld
  call	env_stack
  call	read_window_size
  mov	eax,[ct1]	 ;color for screen clear
  call	crt_clear	;clear screen for possible err msg
  call	parse_inputs
  jz	dad_05		;jmp if normal continue
  js	ad_exitj	;exit if error
  mov	eax,[target_file_ptr]
  call	elfdecode
;elfdecode sets [error_code] with warnings and errors,
;but we ignore it.  We may want to show the warnings sometime?
dad_05:
  call	m_setup		;setup the memory manager
  call	mouse_enable
  call	signal_install
;load files into memory
  call	read_files
  or	eax,eax
  jns	ad_10		;jmp if file read ok
;display read error
  mov	eax,err2
  call	show_boxed_msg
ad_exitj:
  jmp	short dad_exit
ad_10:
  call	display_setup	;read display size and set parameters
;set flags in flag image
dad_20:
  xor	eax,eax
  mov	[symbol_process],eax	;disable symbol fill in
  call	code_hunt
  jecxz	ad_25			;jmp if code hunt succesful
  cmp	byte [warn_flag],0
  jne	ad_25
  dec	esi			;go back to instruction that failed
  call	show_warning		;ecx=warn type  esi=offset
ad_25:
  call	data_hunt
ad_30:
  call	display_menu
  mov	eax,[ct1]		;get normal color
  call	crt_set_color
  call	display_page
key_wait:
  call	cursor_hide
  call	read_stdin
  call	cursor_unhide
  call	decode
  call	eax
; return code in eax - negative = exit
;                      zero = redisplay only
;                      one = screen resize?
;                      two = redo hunt
;                      3 = wait key loop
;                      all others = do hunt then redisplay
  or	eax,eax
  js	dad_exit
  jz	ad_30
  dec	eax
  jz	ad_10		;jmp if screen resize
  dec	eax
  jz	dad_20		;jmp if rehunt
  dec	eax
  jz	key_wait
  jmp	short ad_30

dad_exit:
  call	reset_clear_terminal
;  mov	eax,[ct1]	 ;color for screen clear
;  call	crt_clear	;clear screen for possible err msg
  _mov	ebx,0
  _mov	eax,1
  int	80h
;-----------------------------------------------------------
decode:
  mov	esi,menu_line_ptrs
  call	menu_decode		;menu button pressed?
  jns	do_action		;jmp if event found
  call	page_decode
  jns	do_action
  mov	eax,null_key
do_action:
  ret
;------------------------------------------------------------------------
; input: none
; output: eax = process or negative error
;               js/jns flags set
page_decode:
  cmp	byte [kbuf],-1		;check if mouse click
  jne	key_event		;jmp if key press
  call	mouse_event
  jmp	ml_end
key_event:
  mov	eax,dword [kbuf]
  mov	esi,key_decode_table
  call	key_decode3
ml_end:
  or	eax,eax
  ret
;-----------
  [section .data]
key_decode_table:
    db 1bh,5bh,41h,0		;15 pad_up
  dd	up_key
    db 1bh,5bh,35h,7eh,0	;16 pad_pgup
  dd	pgup_key
    db 1bh,5bh,42h,0		;20 pad_down
  dd	down_key
    db 1bh,5bh,36h,7eh,0	;21 pad_pgdn
  dd	pgdn_key

    db 1bh,4fh,41h,0		;15 pad_up
  dd	up_key
    db 1bh,4fh,35h,7eh,0	;16 pad_pgup
  dd	pgup_key
    db 1bh,4fh,42h,0		;20 pad_down
  dd	down_key
    db 1bh,4fh,36h,7eh,0	;21 pad_pgdn
  dd	pgdn_key
    db '4',0			;4
  dd	set_db
    db '5',0			;5
  dd	set_dw
    db '6',0			;6
  dd	set_dd
    db '7',0			;7
  dd	set_string
    db '8',0			;8
  dd	set_datap
    db '9',0			;9
  dd	set_codep

  db 	0		;end of table
  [section .text]
;-----------------------------------------------------------
; key_decode3 - decode key strings using table
; input: esi = table ptr
; output: eax = process or negative error
;               js/jns flag set
;
key_decode3:
kd3_lp:
  mov	edi,kbuf
  cmpsb
  je	frst_char_match
kd3_10:
  lodsb
  or	al,al		;scan to end of table key string
  jnz	kd3_10
  add	esi,4		;move past process
  cmp	byte [esi],0	;check if end of table
  je	kd3_fail		;jmp if no match found in table
  jmp	kd3_lp
frst_char_match:
  cmp	byte [esi],0	;check if all match
  jne	chk_next
  cmp	byte [edi],0
  je	get_action
  jmp	kd3_10		;go restart search
chk_next:
  cmpsb
  je	frst_char_match
  jmp	kd3_10
get_action:
  inc	esi		;move past zero
  lodsd			;get process
  jmp	short kd3_exit
kd3_fail:
  mov	eax,-1
kd3_exit:
  or	eax,eax
  ret
;--------------------- EVENT -------------------------------------
; mouse event occured in main page (non menu area)
mouse_event:
  mov	eax,-1
  or	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
null_key:
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
up_key:
  mov	ebp,[select_bar_offset]
;move select bar up one instruction
  call	offset2flag_ptr		;get flag ptr in edx
  call	previous_offset		;set edx->prev.flag ptr  ebp=prev code image offset
  jc	up_key_exit		;exit if at top (can't go up)
  mov	[select_bar_offset],ebp ;set new select bar
  cmp	ebp,[win_top_offset]
  jae	up_key_exit
  mov	[win_top_offset],ebp
up_key_exit:
  xor	eax,eax
  ret  
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
down_key:
  mov	ebp,[select_bar_offset]
;move select bar down one
  call	offset2flag_ptr		;get flag ptr in edx
  call	next_offset
  jc	down_key_exit		;exit if at bottom already
  mov	[select_bar_offset],ebp
;check if top win offset needs to move down
  cmp	ebp,[last_offset]	;is ebp at last display point
  jb	down_key_exit		;jmp if not at end
;check if label on next instruction at bottom
  test	byte [edx],30h		;check if label here
  jz	dk_10			;jmp if no label
  mov	ebp,[win_top_offset]
  call	offset2flag_ptr
  call	next_offset
  mov	[win_top_offset],ebp	;move wondow top down 1
dk_10:
;we are at end of page data, move top down
  mov	ebp,[win_top_offset]
  call	offset2flag_ptr
  call	next_offset
  mov	[win_top_offset],ebp	;move wondow top down 1
  
down_key_exit:
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
pgup_key:
  mov	ebp,[win_top_offset]
  call	offset2flag_ptr		;get flag ptr in edx
  xor	ecx,ecx
  mov	cl,[display_lines]	;size exclucing menu lines
pk_lp:
  test	[edx],byte 30h		;check if label here
  jz	pk_10			;jmp if no label
  dec	ecx
  jbe	pk_top			;jmp if label at end of window
pk_10:
  call	previous_offset
  jc	pk_top			;jmp if at top
  dec	ecx
  ja	pk_lp			;loop till page up done
pk_top:
  mov	[win_top_offset],ebp
  mov	[select_bar_offset],ebp
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
pgdn_key:
  mov	ebp,[last_offset]
  mov	[win_top_offset],ebp
  mov	[select_bar_offset],ebp
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
show_code:
  call	page_setup
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
show_data:
  mov	al,2		;writeable flag
  call	find_pheader_type
  jz	sd_err		;jmp if no writeable block
  test	[ebx+head.p_flags],byte 8 ;bss?
  jz	sd_20		;jmp if not .bss
sd_err:
  mov	eax,no_data_msg
  call	show_boxed_msg
  jmp	short sd_exit

sd_20:
  mov	edx,[ebx+head.phys_start]
  mov	[display_mode],byte 1
  call	physical2offset
  mov	[section_top_offset],ebp
  mov	[win_top_offset],ebp
  mov	[select_bar_offset],ebp
  mov	edx,[ebx+head.phys_end]
  call	physical2offset
  mov	[section_end_offset],ebp
sd_exit:
  xor	eax,eax
  ret  
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
show_bss:
  mov	al,8
  call	find_pheader_type
  jnz	sb_20		;jmp if bss found
sb_err:
  mov	eax,no_bss_msg
  call	show_boxed_msg
  jmp	short sb_exit

sb_20:
  mov	edx,[ebx+head.phys_start] ;get block phys start
  mov	[display_mode],byte 2
  call	physical2offset
  mov	[section_top_offset],ebp
  mov	[win_top_offset],ebp
  mov	[select_bar_offset],ebp
  mov	edx,[ebx+head.phys_end]	;get block end
  call	physical2offset
  mov	[section_end_offset],ebp
sb_exit:
  xor	eax,eax
  ret  
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
show_help:
  mov	ebx,help_filename
  call	view_file
  xor	eax,eax
  ret
;-------
  [section .data]
help_filename:
  db "/usr/share/doc/asmref/asmdis_help.txt",0
  [section .text]
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
abort_exit:
  _mov	eax,-1
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
save_exit:
  mov	ebx,asmdis_fimage	;filename
  xor	edx,edx			;permissions
  mov	ecx,[flag_image_ptr]	;data ptr
  mov	esi,[flag_image_size]
  call	block_write_all

  mov	ebx,asmdis_sym  
  call	hash_archive
  _mov	eax,-1
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
code_here:
  mov	ebx,asmdis_undo		;filename
  xor	edx,edx			;permissions
  mov	ecx,[flag_image_ptr]	;data ptr
  mov	esi,[flag_image_size]
  call	block_write_all

  mov	ebp,[select_bar_offset]
  mov	[force_hunt_top],ebp	;revise hunt start point
  call	offset2flag_ptr
  or	[edx],byte 80h
  _mov	eax,2
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
%include "data_here.inc"
;--------------------- EVENT -------------------------------------
set_db:
  mov	ebp,[select_bar_offset]
  call	offset2flag_ptr
set_db_lp:
  and	[edx],byte ~0cfh
  inc	edx
  cmp	byte [edx],0c0h ;check if inside code body
  je	set_db_lp
set_db_exit:
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
set_dw:
  mov	ebp,[select_bar_offset]
  call	offset2flag_ptr
  mov	al,[edx]		;get flag
  and	al,~0cfh
  or	al,1
  mov	[edx],al
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
set_dd:
  mov	ebp,[select_bar_offset]
  call	offset2flag_ptr
  mov	al,[edx]
  and	al,~0cfh
  or	al,2
  mov	[edx],al
  inc	edx
  or	[edx],byte 40h
  inc	edx
  or	[edx],byte 40h
  inc	edx
  or	[edx],byte 40h
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
set_string:
  mov	ebp,[select_bar_offset]
  call	offset2flag_ptr
  mov	al,[edx]
  and	al,~0cfh
  or	al,04h
  mov	[edx],al
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
set_datap:
  mov	ebp,[select_bar_offset]
  call	offset2flag_ptr
  mov	al,[edx]
  and	al,~0cfh
  or	al,2
  mov	[edx],al
  xor	eax,eax
  ret
  
;--------------------- EVENT -------------------------------------
set_codep:
  mov	ebp,[select_bar_offset]
  call	offset2code_ptr
  mov	ebx,[edx]	;get data
  cmp	ebx,[preamble+pre.elf_phys_code_start]
  jb	sc_exit		;exit if not in code section
  cmp	ebx,[preamble+pre.elf_phys_code_end]
  ja	sc_exit		;exit if not in code section

  call	offset2flag_ptr
  mov	al,[edx]
  and	al,~0cfh
  or	al,2
  mov	[edx],al
;
  mov	edx,ebx
  call	physical2offset
  call	offset2flag_ptr
  or	[edx],byte 80h	;set code here
sc_exit:  
  _mov	eax,2
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
label_here:
  mov	ebp,[select_bar_offset]
  call	offset2flag_ptr
  mov	al,[edx]
  or	al,20h
  mov	[edx],al
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
undo_last:
  mov	ecx,[flag_image_ptr]	;buffer to ecx
  mov	edx,[flag_image_size]	;file size
  mov	ebx,asmdis_undo		;file name
  call	block_read_all		;open and read file
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
;section_top_offset resd 1	;offset from load_image_ptr
;win_top_offset     resd 1	;offset currently at top of window
;select_bar_offset  resd 1	;offset of select bar
goto_top:
  mov	eax,[section_top_offset]
  mov	[win_top_offset],eax
  mov	[select_bar_offset],eax
  xor	eax,eax
  ret
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
goto_end:
  mov	eax,[section_end_offset]
  sub	eax,[section_top_offset]
  xor	ebx,ebx
  mov	bl,[display_lines]
  sub	eax,ebx				;check if at end
  js	ge_exit				;exit if at end
  add	eax,[section_top_offset]
  mov	[win_top_offset],eax
  mov	[select_bar_offset],eax
ge_exit:
  xor	eax,eax
  ret 
;--------------------- EVENT -------------------------------------
;in=our_adr out= -(exit) 0(redisplay) 1(resize) +(hunt&redisplay)
;find:
;-----------------------------------------------------------
; input:  edx = current flag ptr
;         ebp = current offset
; output: edx = next flag ptr if no carry
;         ebp = next offset if no  carry
;               else, edx unchanged if at top of section.
next_offset:
  cmp	ebp,[section_end_offset]
  jb	no_loop			;jmp if within section
  stc
  jmp	short no_exit
no_loop:
  inc	ebp
  inc	edx
  test	byte [edx],40h
  jnz	no_loop			;loop till start found
  cmp	ebp,[section_end_offset]
  jb	not_at_end
  call	previous_offset
not_at_end:
  clc
no_exit:
  ret

;-----------------------------------------------------------
; input:  edx = current flag ptr
;         ebp = current offset
; output: edx = previous flag ptr if no carry
;         ebp = previus offset if no  carry
;               else, edx unchanged if at top of section.
previous_offset:
  cmp	ebp,[section_top_offset]
  ja	po_loop		;jmp if not at top yet
  stc
  jmp	short po_exit	;jmp if at top of section
po_loop:
  dec	ebp
  dec	edx
  test	byte [edx],40h	;body here
  jnz	po_loop		;jmp if body found
  clc
po_exit:
  ret

;-----------------------------------------------------------
;display_page:
%include "page.inc"
;-----------------------------------------------------------
;display_menu:
;decode_menu:
%include "menu.inc"
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
  mov	ebx,asmdis_image
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
  mov	ebx,asmdis_image	;file name
  call	block_read_all		;open and read file
  or	eax,eax
  js	rf_exitj

;find size of flag image file
  mov	ebx,asmdis_fimage
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
  mov	ebx,asmdis_fimage	;file name
  call	block_read_all		;open and read file
  or	eax,eax
  js	rf_exit

;find size of symbol table file
  mov	ebx,asmdis_sym
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
  mov	ebx,asmdis_sym	;file name
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
  db 'File required, try:  asmdis <file> ',0ah,0
  [section .text]
;------------------------------------------------------------
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
display_setup:
  call	read_window_size
  call	menu_setup
  call	page_setup
  ret
;-----------------------------------------------------------
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
%include "../ElfDecode/elfdecode.inc"
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

;%include "system.inc"

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

asmdis_txt: db "asmdis",0,0

history_file: db ".abug_header.dat",0	;image of header1
asmdis_image: db ".abug_image.dat",0 ;load image
asmdis_fimage: db ".abug_fimage.dat",0 ;flag image
asmdis_sym:    db ".abug_sym.dat",0
asmdis_undo:  db ".abug_undo.dat",0
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
;-----------------------
;-----------------------

;bss_end:		;memory managed by memory_manager follows

