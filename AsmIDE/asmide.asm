
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

  extern sys_exit
  extern str_move
  extern crt_line
  extern read_window_size
  extern crt_rows, crt_columns
  extern env_stack
  extern file_access
  extern crt_clear
  extern file_status_name
  extern enviro_ptrs
  extern env_exec
  extern stdout_str
  extern get_text
  extern kbuf
  extern browse_dir_right
  extern move_cursor
  extern read_stdin
  extern crt_set_color
  extern block_write_all
  extern memory_init
  extern file_length_handle
  extern block_read
  extern set_memory
  extern crt_window
  extern move_cursor
  extern file_close
  extern file_rename
  extern file_write_all
  extern blk_insert_bytes
  extern blk_del_bytes
  extern key_decode1
  extern dword_to_l_ascii
  extern blk_find
  extern ascii_to_dword
  extern file_length_name
  extern blk_make_hole
  extern block_read_all
  extern sys_shell_cmd
  extern view_buffer
  extern dir_current
  extern dir_change
  extern reset_clear_terminal

  [section .text align=1]

  global _start
_start:
  call	env_stack	;save stack state
  mov	eax,[compile_color]
  call	crt_clear	;clear screen
  mov	ax,0101h	;cursor position
  call	move_cursor
  call	check_key_files	;check for makefile +
  call	get_current_dir

  call	get_filename
  cmp	[kbuf],byte 1bh	;esc?
  je	aedit_exit2	;exit if esc
  call	select_assembler
  call	check_installed_programs
  jc	aedit_exit2	;exit if error
  call	create_makefile
  jc	aedit_exit2	;exit if error
  call	fill_input_buffer
  call	set_edit_only_win
  mov	eax,[edit_top_line]
  mov	[edit_cursor_row],al	;set initial cursor position
err_lp:  
  call	show_compile_menu
  call	show_compile_window
edit_lp:
  call	show_edit_menu
  call	show_edit_buffer
  call	get_key_and_decode
  call	eax
  cmp	[exit_flag],byte 0
  je	err_lp
aedit_exit1:
  call	write_file	;save file/rename
aedit_exit2:
  call	restore_current_dir
;  mov	eax,[compile_color]
;  call	crt_clear	;clear screen
  call	reset_clear_terminal
  call	sys_exit

;-------------------------------------------------------------------
; *** commands ****
;-------------------------------------------------------------------

;-------------------------------------------------------------------
f1_asmref:
  mov	esi,asmref_execution_string
  call	sys_shell_cmd
  ret
;-------------
  [section .data]
asmref_execution_string: db 'asmref',0
  [section .text]
;-------------------------------------------------------------------
f2_edit_help:
  mov	ecx,asmide_help
  xor	ebx,ebx
  mov	eax,asmide_help_end
  sub	eax,ecx		;compute length of help message
  call	view_buffer
  ret

;----------
  [section .data]
asmide_help:
incbin "asmide_help.inc"
asmide_help_end:
  [section .text]
;-------------------------------------------------------------------
f3_compile:
  call	write_file

  mov	edi,compile_execution_string	;stuff location for cmd
  mov	esi,make_cmd
  call	str_move		;insert "make"
  mov	esi,cmd_tail		
  call	str_move		;insert pipe cmd
;
  mov	esi,compile_execution_string
  call	sys_shell_cmd
 
cm_exit:  
  call	enable_compile_win
  ret
;-------------
  [section .data]

compile_msg_end: dd 0	;ptr to end of message

make_cmd:	db 'make -f asmide_makefile',0
cmd_tail:	db '&> compile_results',0

compile_execution_string  times 150 db 0

  [section .text]
;-------------------------------------------------------------------
f4_debug:
  mov	eax,[compile_color]
  call	crt_clear	;clear screen
  mov	ax,0101h	;cursor position
  call	move_cursor

  mov	esi,input_file
  mov	edi,executable
  call	str_move
  mov	ecx,5		;max back scan
dot_scan:
  mov	[edi],byte ' '
  dec	edi
  cmp	[edi],byte '.'
  je	df_got_dot
  loop	dot_scan
df_got_dot:
  mov	[edi],byte ' '
;compute column
  inc	edi
  mov	[parm_block],edi
  mov	[edi],byte 0		;temp termination
  sub	edi,debugger		;compute column
  inc	edi
  mov	eax,edi
  mov	[parm_col1],al
  mov	[parm_col2],al
;show intro messages
  mov	ecx,debug_intro
  call	stdout_str
;fix end of shell out string
  mov	edi,[parm_block]
  mov	[edi],byte ' '

;ask for parameters
  mov	ebp,parm_block
  call	get_text
;
  mov	esi,[parm_block]
fnd_end:
  lodsb
  cmp	al,' '
  jne	fnd_end
  mov	[esi-1],byte 0		;terminate string
;launch
  mov	esi,debugger
  call	sys_shell_cmd  

  ret
;------------
  [section .data]

debug_intro: db 'Append optional parameters, or just <Enter> to begin',0ah
debugger: db 'minibug '
executable: times 100 db ' '

parm_block:
  dd 0		;buffer ptr
  dd	50
  dd	menu_color
parm_row:
  db	2		;display row
parm_col1:
  db	1		;display column
parm_col2:
  db	1		;initial cursor
  dd	50		;window size
  dd	0		;scroll

  [section .text]
;-------------------------------------------------------------------
;insert file at cursor position
f5_insert_file:
  mov	eax,[compile_color]
  call	crt_clear	;clear screen
  mov	ax,0101h	;cursor position
  call	move_cursor
;clear insert buffer
  mov	edi,insert_file
  mov	ecx,insert_file_buf_size
  mov	al,' '
  rep	stosb
;request filename from user
  mov	eax,[edit_color]
  call	crt_set_color
  mov	ecx,insert_filename_msg
  call	stdout_str
  mov	ebp,filenam_block
  call	get_text
;replace first space with zero
  mov	esi,insert_file
ipn_lp:
  lodsb
  cmp	al,' '
  jne	ipn_lp
  mov	[esi-1],byte 0
;check if file enter key pressed
  cmp	[kbuf],byte 1bh	;escape pressed
  jne	insert_10	;jmp if no esc
  jmp	insert_exit
insert_10:
  cmp	[kbuf],byte 0dh
  je	insert_20	;jmp if possible file entered
  cmp	[kbuf],byte 0ah
  jne	insert_exit
insert_20:
  mov	ebx,insert_file
  cmp	[insert_file],byte ' '	;anything here?
  jne	read_insert		;jmp if name entered
;browse for file name
insert_browse:
;  mov	esi,bss_end
  mov	esi,[editbuf_mem_end_ptr]
  call	browse_dir_right
  or	eax,eax
  jnz	insert_exit		;jmp if no file found
  mov	esi,ebx
  mov	edi,insert_file
  call	str_move
;find file size
read_insert:
  mov	ebx,insert_file
  call	file_length_name
  js	insert_exit		;exit if error
  mov	[insert_length],eax
;make hole at cursor for size of file
  xor	esi,esi			;make hole only
  call	insert_text
;read file into buffer
  mov	ebx,insert_file			;filename
  mov	ecx,[editbuf_cursor_ptr]	;insert point
  mov	edx,[editbuf_mem_end_ptr]
  sub	edx,ecx				;compute buffer size
  call	block_read_all
insert_exit:
  ret


;----------
  [section .data]
insert_file:	times 200 db ' '	;if zero, no insert file provided
insert_file_buf_size equ $ - insert_file

insert_length: dd 0		;
insert_filename_msg: db 0ah
  db 'type <Enter> to browse for source file',0ah
  db 'if new file or name known, enter filename (xxxx.asm)',0ah
  db 'type <esc> to abort',0ah,0

filenam_block:
  dd insert_file
  dd	insert_file_buf_size
  dd	menu_color
insert_row:
  db	5		;display row
  db	1		;display column
  db	1		;initial cursor
  dd	50		;window size
  dd	0		;scroll

  [section .text]

;-------------------------------------------------------------------
;insert bytes into edit buffer
;input: eax=number of bytes
;       esi=ptr to insert data, or zero to just make hole
insert_text:
  or eax,eax
  jz it_exit	;exit if zero bytes inserted
  mov	[insert_data_ptr],esi
  mov	[insert_count],eax
  add	eax,[editbuf_data_end_ptr]
  cmp	eax,[editbuf_mem_end_ptr]
  jb	have_room
;expand edit buffer
  add	eax,2000
  mov	ebx,eax
  call	set_memory
  mov	[editbuf_mem_end_ptr],eax	;set new end point
;make hole at cursor
have_room:
  mov	edi,[editbuf_cursor_ptr]
  mov	ebp,[editbuf_data_end_ptr]
  mov	eax,[insert_count]
  call	blk_make_hole
  mov	[editbuf_data_end_ptr],ebp	;set new end of data
;copy data into hole
  mov	esi,[insert_data_ptr]
  or	esi,esi
  jz	it_exit			;exit if no data avail
  mov	edi,[editbuf_cursor_ptr]
  mov	ecx,[insert_count]
  rep	movsb
it_exit:
  ret
;--------------
  [section .data]
insert_data_ptr:	dd 0
insert_count:		dd 0
  [section .text]  



;-------------------------------------------------------------------
f6_goto_line:
  mov	ebx,menu_color
  mov	ch,[edit_end_menu_line]
  mov	esi,line_msg
  call	build_and_show_line

  mov	eax,[edit_end_menu_line]
  mov	[ln_row1],al
  mov	ebp,line_msg_block
  call	get_text

  mov	esi,line_buffer
  call	ascii_to_dword
  mov	[line_number],ecx
  jecxz	goto_exit		;exit if no line#
  call	goto_line
  call	compute_cursor_data
goto_exit:  
  ret
;----------
  [section .data]
line_msg_block:
  dd line_buffer
  dd line_buffer_len
  dd menu_color
ln_row1:
  db 0		;display row
  db 12		;display column
  db 12		;initial cursor column
  dd 10		;window size
  dd 0		;scroll

line_msg:	db 'Goto Line#:',0
line_buffer	times 10 db ' '
  db 0
line_buffer_len equ $ - line_buffer

line_number	dd	0

;-------------------------------------------------------------------

f7_find:
  mov	ebx,menu_color
  mov	ch,[edit_end_menu_line]
  mov	esi,find_msg
  call	build_and_show_line

  mov	eax,[edit_end_menu_line]
  mov	[fnd_row1],al
  mov	ebp,find_msg_block
  call	get_text

  cmp	[find_buffer],byte " "
  je	find_exit		;exit if buffer empty
;isolate match string
  mov	esi,find_buffer
  mov	edi,match_string
  mov	ecx,find_buffer_len
find_lp:
  lodsb
  cmp	al,' '
  je	find_end		;exit if empty find buffer
  stosb
  loop	find_lp
  jmp	short find_exit		;exit if end not found
;end of string found, terminate match
find_end:
  mov	al,0
  stosb				;terminate find_string
;setup to search buffer
  mov	ebp,[editbuf_data_end_ptr]
  mov	esi,match_string
  mov	edi,[editbuf_cursor_ptr];search from cursor
  inc	edi			;move past current match/cursor position
  mov	edx,1			;search forward
  mov	ch,0dfh			;ignore case
  call	blk_find
  jc	find_exit		;exit if no match
;match was found at ebx
  mov	[editbuf_cursor_ptr],ebx
  mov	esi,ebx
  call	compute_cursor_data
find_exit:
  ret

;----------
  [section .data]
find_msg_block:
  dd find_buffer
  dd find_buffer_len
  dd menu_color
fnd_row1:
  db 0		;display row
fnd_col:
  db 12		;display column
  db 12		;initial cursor column
  dd 40		;window size
  dd 0		;scroll

find_msg:	db 'Search for:',0
find_buffer	times 40 db ' '
  db 0
find_buffer_len equ $ - find_buffer

match_string	times 40 db 0

  [section .text]
;-------------------------------------------------------------------
f8_cut_line:
  mov	edi,[editbuf_cursor_line_ptr]
  cmp	edi,[editbuf_data_end_ptr]
  je	dl_exit			;exit if at end of file
  mov	ebx,edi			;save line begin
  call	next_line
dll_10:
  cmp	edi,[editbuf_data_end_ptr]	;check if at end of file now
  jbe	dll_20			;jmp if not at end of file
  dec	edi
  jmp	short dll_10
dll_20:
  sub	edi,ebx			;compute line length
  mov	eax,edi
dl_cut:  
  mov	edi,ebx			;get start of line
  call	DeleteByte		;remove line
    
  call	KeyHome
dl_exit:
  ret
;-------------------------------------------------------------------
f9_close_err_win:
  call	set_edit_only_win
  ret
;-------------------------------------------------------------------
f10_exit:
  mov	[exit_flag],byte 1
  ret
;----------
  [section .data]
exit_flag:	db 0
  [section .text]


;---------------
alpha_keypress:
  mov	edi,[editbuf_cursor_ptr]
  mov	ebp,[editbuf_data_end_ptr]
  cmp	edi,[editbuf_mem_end_ptr]
  jae	ak_exit			;exit if cursor at end of buffer
  cmp	ebp,[editbuf_mem_end_ptr]
  jb	ak_20			;jmp if buffer not full
;buffer is full
  dec	ebp			;avoid buffer overflow
ak_20:
  mov	eax,1
  mov	esi,kbuf
  call  insert_text	
  mov	[editbuf_data_end_ptr],ebp
ak_exit2:
  cmp	byte [edi-1],0ah	;was 0ah entered?
  jne	ak_exit3		;jmp if normal alpha
  call	down_arrow
  jmp	short ak_exit
ak_exit3:
  call	right_arrow
  mov	[editbuf_dirty],byte 1
ak_exit:
  xor	eax,eax			;set return
  ret
;--------------
delete_key:
  mov	edi,[editbuf_cursor_ptr]	;ptr to deleted byte
  mov	ebp,[editbuf_data_end_ptr]		;current end of data

  cmp	edi,ebp
  jne	dkk_10			;jmp if not equal
  jmp	left_arrow		;we are beyond end of file, try left arrow
dkk_10:
  mov	eax,[editbuf_top_ptr]		;check if empty file
  inc	eax
  cmp	eax,ebp
  je	dkk_exit		;exit if empty file  

  mov	eax,1			;delete one byte
  call	blk_del_bytes
  mov	[editbuf_data_end_ptr],ebp
dkk_exit:
ignore_key:			;entry point for pgup,pgdn keys
  mov	[editbuf_dirty],byte 1
  xor	eax,eax
  ret

;--------------
rubout_key:
  jne	rk_rub			;jmp if normal rubout
  cmp	dword [scroll_count],0
  je	rk_exit			;exit if can't rubout char
rk_rub:
  call	left_arrow
  call	delete_key
rk_exit:
  mov	[editbuf_dirty],byte 1
  xor	eax,eax
  ret

;--------------
;note: if "up" ends up beyond end of line, pad to cursor
up_arrow:
  cmp	dword [cursor_linenr],1
  je	ku_exit			;exit if at to line
  mov	edi,[editbuf_cursor_ptr]
  call	end_prev_line
  call	end_prev_line
  inc	edi			;move to start of line above current
  mov	bl,[edit_cursor_col]
  call	check_cursor_column
  mov	esi,edi			;setup to call compute_cursor_data

  mov	edi,[editbuf_display_page_ptr]	;at top of screen
  cmp	edi,[editbuf_cursor_line_ptr] ;check if at top of screen
  jne	ku_50			;jmp if not at top of scren
  call	end_prev_line
  call	end_prev_line
  inc	edi
  mov	[editbuf_display_page_ptr],edi

ku_50:
  call	compute_cursor_data
ku_exit:
  ret

;--------------
down_arrow:
  mov	edi,[editbuf_cursor_ptr]	;scan
  cmp	edi,[editbuf_data_end_ptr]
  jae	kd_exit			;jmp if at end of file
  call	next_line
  cmp	edi,[editbuf_data_end_ptr]
  jb	kd_05			;jmp if not at end of file
;
; we are at end of file, check for special case, last line ends with 0ah
;
  mov	edi,[editbuf_data_end_ptr]	;force end point, it may have strayed 
  cmp	byte [edi -1],0ah
  jne	kd_exit			;jmp if last line without 0ah at end  
kd_05:
  mov	bl,[edit_cursor_col]
  call	check_cursor_column
  mov	esi,edi
  call	compute_cursor_data
kd_exit:
  ret
;--------------------------  

left_arrow:
  mov	esi,[editbuf_cursor_ptr]
  cmp	esi,[editbuf_top_ptr]
  je	kl_exitx
  dec	esi
  call	compute_cursor_data
kl_exitx:
  ret

;--------------
right_arrow:
  mov	esi,[editbuf_cursor_ptr]
  cmp	esi,[editbuf_data_end_ptr]
  je	kr_90			;exit if at eof
  inc	esi
  call	compute_cursor_data
kr_90:
  ret

;--------------
pgup_key:
  mov	edi,[editbuf_display_page_ptr]
  call	compute_line
  mov	[crt_top_linenr],edx
  mov	ecx,edx
  call	look_page_up
;
; compute start of line for new cursor position
;  edi=page top ptr  ecx=page top linenr
;
  mov	eax,[crt_top_linenr]
  mov	[crt_top_linenr],ecx	;set new top linenr
  mov	[editbuf_display_page_ptr],edi	;set new top ptr
;
; compute cursor linenr
;
  mov	edx,[cursor_linenr]
  sub	edx,eax			;(old cursor linenr)-(old top linenr)
  add	ecx,edx			;(new top linenr) + above
  mov	[cursor_linenr],ecx

  mov	ecx,edx			;get index into window for cursor
kpu_10:
  jecxz	kpu_12			;jmp if done
  call	next_line		;scan forward to cusrsor line
  dec	ecx
  jmp	kpu_10
;
; edi points at cursor line, find cursor column
;
kpu_12:
  mov	bl,[edit_cursor_col]
  call	check_cursor_column
  mov	esi,[editbuf_cursor_ptr]
  call	compute_cursor_data
  ret
;--------------
pgdn_key:
  mov	edi,[editbuf_display_page_ptr]
  call	compute_line
  mov	[crt_top_linenr],edx
  mov	eax,edx
  xor	ebx,ebx
  mov	bl,[win_rows]
  add	eax,ebx			;compute target top line number
  mov	[target_top_linenr],eax

  mov	eax,[cursor_linenr]
  add	eax,ebx
  mov	[target_cursor_linenr],eax
;
; compute expected values for next display page
;
  mov	esi,[editbuf_display_page_ptr]
  mov	ecx,[crt_top_linenr]
;
; scan buffer to verify display top pointer
;
kpd_30:
  cmp	esi,[editbuf_data_end_ptr]
  je	kpd_95
  lodsb
  cmp	al,0ah
  jne	kpd_30			;loop till end of page

  inc	ecx			;bump page number
  cmp	ecx,[target_top_linenr]
  jne	kpd_30			;loop if not at new top yet
  cmp	esi,[editbuf_data_end_ptr]
  jae	kpd_95			;?
  mov	[crt_top_linenr],ecx	;save new top linenr
  mov	[editbuf_display_page_ptr],esi	;save new top data pointer
;
; scan buffer to verify new cursor pointer is ok
;
  mov	bl,1			;get starting row#
kpd_33:
  cmp	ecx,[target_cursor_linenr]
  je	kpd_36			;jmp if target line# has been reached
kpd_34:
  cmp	esi,[editbuf_data_end_ptr]
  je	kpd_36			;jmp if cursor needs truncating
  lodsb
  cmp	al,0ah
  jne	kpd_34			;loop till end of line
  inc	bl			;bump row number for display
  inc	ecx			;bump cursor line number
  jmp	kpd_33

;
; we have found new cursor linenr and start of new cursor line (esi)
;
kpd_36:
  mov	[edit_cursor_row],bl	;save new cursor row
  mov	[cursor_linenr],ecx	;save new cursor linenr
  mov	edi,esi
  mov	bl,[edit_cursor_col]
  call	check_cursor_column
kpd_90:
  mov	esi,[editbuf_cursor_ptr]
kpd_95:
  call	compute_cursor_data
  ret
;---------
  [section .data]
target_cursor_linenr	dd	0
target_top_linenr	dd	0
  [section .text]

;----------------
KeyHome:
  mov	esi,[editbuf_cursor_line_ptr]
  call	compute_cursor_data
  ret
;---------------  
KeyEnd:
  mov	edi,[editbuf_cursor_ptr]
  call	next_line
  dec	edi
  mov	esi,edi
  call	compute_cursor_data
  ret

;--------------
enter_key:
  mov	byte [kbuf],0ah
  jmp	alpha_keypress
;--------------
unknown_key:
uk_exit3:
  ret

;-------------------------------------------------------------------
get_key_and_decode:
  call	read_stdin
  mov	al,[kbuf]	;get key
  cmp	al,-1		;check if mouse
  je	mouse_handling	;handle the mouse
  mov	esi,key_table
  call	key_decode1
  jmp	gk_exit
mouse_handling:

;temp
  mov	eax,unknown_key

gk_exit:
  ret

;----------------
  [section .data]
key_table:
  dd	alpha_keypress	;alpha handler is always first entry in table

    db	1bh,5bh,44h,0	;left arrow
  dd	left_arrow	;left arrow process
    db	1bh,4fh,44h,0	;left arrow
  dd	left_arrow	;left arrow process
    db	1bh,4fh,74h,0	;left arrow
  dd	left_arrow	;left arrow process

    db 1bh,5bh,43h,0		;pad_right
  dd	right_arrow
    db 1bh,4fh,43h,0		;pad_right
  dd	right_arrow
    db 1bh,4fh,76h,0		;pad_right
  dd	right_arrow

    db 1bh,5bh,41h,0		;pad_up
  dd	up_arrow
    db 1bh,4fh,41h,0		;pad_up
  dd	up_arrow
    db 1bh,4fh,78h,0		;pad_up
  dd	up_arrow

    db 1bh,5bh,42h,0		;pad_down
  dd	down_arrow
    db 1bh,4fh,42h,0		;pad_down
  dd	down_arrow
    db 1bh,4fh,72h,0		;pad_down
  dd	down_arrow

    db 1bh,5bh,33h,7eh,0	;pad_del
  dd	delete_key
    db 1bh,4fh,6eh,0		;pad_del
  dd	delete_key

    db 7fh,0			;backspace
  dd	rubout_key

    db 0dh,0			;enter
  dd	enter_key
    db 0ah,0			;enter
  dd	enter_key

    db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  dd	pgup_key

    db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  dd	pgdn_key

  db 1bh,5bh,48h,0		;14 pad_home
   dd KeyHome				;home
  db 1bh,5bh,31h,7eh,0		;138 home (non-keypad)
   dd KeyHome
  db 1bh,4fh,77h,0		;150 pad_home
   dd KeyHome
  db 1bh,4fh,48h,0
   dd KeyHome

  db 1bh,5bh,46h,0		;19 pad_end
   dd KeyEnd				;end
  db 1bh,5bh,34h,7eh,0		;139 end (non-keypad)
   dd KeyEnd
  db 1bh,4fh,71h,0		;145 pad_end
   dd KeyEnd
  db 1bh,4fh,46h,0
   dd KeyEnd

    db  09,0			;tab
  dd	alpha_keypress

  db 1bh,5bh,31h,31h,7eh,0	;f1
   dd f1_asmref				;help
  db 1bh,4fh,50h,0		;F1
   dd f1_asmref				;help
  db 1bh,5bh,5bh,41h,0		;F1
   dd f1_asmref				;help

  db 1bh,5bh,31h,32h,7eh,0	;f2
   dd f2_edit_help
  db 1bh,4fh,51h,0		; F2
   dd f2_edit_help
  db 1bh,5bh,5bh,42h,0		;f2
   dd f2_edit_help
 
  db 1bh,5bh,31h,33h,7eh,0	;f3
   dd f3_compile
  db 1bh,4fh,52h,0		;F3
   dd f3_compile
  db 1bh,5bh,5bh,43h,0		;f3
   dd f3_compile

  db 1bh,5bh,31h,34h,7eh,0	;f4
   dd f4_debug
  db 1bh,4fh,53h,0		;F4
   dd f4_debug
  db 1bh,5bh,5bh,44h,0		;f4
   dd f4_debug

  db 1bh,5bh,31h,35h,7eh,0	;f5
   dd f5_insert_file				;insert file
  db 1bh,5bh,5bh,45h,0		;f5
   dd f5_insert_file				;insert file

  db 1bh,5bh,31h,37h,7eh,0	;7 f6
   dd f6_goto_line
  db 1bh,5bh,31h,38h,7eh,0	;8 f7
   dd f7_find
  db 1bh,5bh,31h,39h,7eh,0	;9 f8
   dd f8_cut_line
  db 1bh,5bh,32h,30h,7eh,0	;10 f9
   dd f9_close_err_win
  db 1bh,5bh,32h,31h,7eh,0	;11 f10
   dd f10_exit

    db	0		;end of table
  dd	unknown_key	;unknown key handler is always last entry

  [section .text]

;-----------------------------------
; scan back to find previous page
;  input: edi = ptr inside current top line
;         ecx = current line#
;         [win_rows] = size of page
;         editbuf = top of file
; output: edi = start of prev page
;         ecx = line #
look_page_up:
  xor	eax,eax
  mov	al,[win_rows]
lpu_10:
  call	end_prev_line
  cmp	edi,[editbuf_top_ptr]
  jb	lpu_20
  jne	lpu_11
  dec	ecx
  jmp	lpu_21
lpu_11:
  dec	ecx
  dec	eax
  jnz	lpu_10
  call	end_prev_line
lpu_20:
  inc	edi
lpu_21:
  ret  
;

;------------------------------------------------------------
;
; functions for INSERTING, COPYING and DELETING chars in text
;
; inputs: eax = number of bytes to delete
;         edi = beginning of block to delete
;         [editbuf_data_end_ptr] = end of file
;
DeleteByte:
  or eax,eax
  jz db_exit		;jmp if delete count = 0
  mov ecx,[editbuf_data_end_ptr]
  cmp edi,ecx
  jb  db_ok		;jmp if inside buffer
  stc			;set error flag
  jmp	short db_exit
db_ok:
  push edi
  sub ecx,edi
  lea esi,[edi+eax]
  sub ecx,eax
  inc ecx
  cld
  rep movsb
  neg eax
  pop edi		;
  mov	byte [editbuf_dirty],1
  add [editbuf_data_end_ptr],eax
  clc
db_exit:
  ret
;---------------------------
; set paramaters from cursor column [edit_cursor_col]
; input: bl = cursor column (1 based)
;        edi = pointer somewhere in cursor row
; output: editbuf_cursor_line_ptr
;         edit_cursor_col (cursor column)
;         edi, editbuf_cursor_ptr
;
check_cursor_column:
  mov	byte [edit_cursor_col],bl		;store column
  call	end_prev_line
  inc	edi				;move to start of current line
  mov	[editbuf_cursor_line_ptr],edi	;store line start
  xor	ebx,ebx
  mov	bl,[edit_cursor_col]
  add	ebx,[scroll_count]		;include scroll position
  xor	eax,eax
ccr_10:
  inc	eax				;make eax "1" based counter
  cmp	eax,ebx				;check if at match point
  je	ccr_50				;jmp if match
  cmp	byte [edi],09h			;check if sitting on tab
  jne	ccr_30				;jmp if not tab
  test	al,07
  jnz	ccr_10				;loop till tab expansion done
ccr_30:
  cmp	byte [edi],0ah
  je	ccr_50				;jmp if at end of line, no match
  inc	edi
  jmp	ccr_10				;move to next char
;
; we have found a match, edi = match  al,bl = virtual column
;
ccr_50:
  mov	dword [editbuf_cursor_ptr],edi	;save cursor ptr
ccr_exit:
  ret


;------------------------------------------------------------
; compute_cursor_data - set all cursor variables from cursor_ptr
;  inpusts:  esi = cursor
;
compute_cursor_data:
  mov	ebp,[editbuf_top_ptr]
  mov	[editbuf_cursor_ptr],esi	;save cursor
ccd_01:
  cmp	esi,ebp			;check if at top of file
  je	ccd_11			;jmp if cursor at top of file
;
; scan back to start of line - to set editbuf_cursor_line_ptr
;
ccd_02:
  dec	esi
  cmp	byte [esi],0ah
  je	ccd_10			;exit if prev found
  cmp	esi,ebp			;esi = editbuf
  jne	ccd_02			;loop till start of line
  jmp	ccd_11
ccd_10:
  inc	esi
ccd_11:
  mov	[editbuf_cursor_line_ptr],esi	;save start of line with cursor
;
; scan back to set editbuf_display_page_ptr and crt_row
;
  mov	bl,1			;row 1
  mov	bh,[win_rows]		;total rows
ccd_12:
  cmp	esi,ebp			;esi = editbuf
  je	ccd_20			;go set values if at top of file
ccd_14:
  dec	esi
  cmp	byte [esi],0ah
  je	ccd_15			;loop till start of line
  cmp	esi,ebp			;exi = editbuf
  je	ccd_20			;go set values
  jmp	ccd_14
ccd_15:
  inc	esi			;check if we have found old editbuf_display_page_ptr
  cmp	esi,[editbuf_display_page_ptr]
  je	ccd_20			;jmp if we have found old editbuf_display_page_ptr
  dec	esi			;restore esi

  inc	bl
  dec	bh
  jnz	ccd_12			;loop till top of screen
  inc	esi			;move past 0ah to line start
  dec	bl			
;
ccd_20:
  mov	[editbuf_display_page_ptr],esi	;set display top ptr
  add	bl,[edit_top_line]	
  dec	bl			
  mov	[edit_cursor_row],bl		;set row#
;
; now set column for display
;
  mov	edi,[editbuf_cursor_ptr]
  call	set_cursor_from_ptr
  mov	edi,[editbuf_cursor_ptr]
  call	compute_line		;set [cursor_linenr]
  mov	[cursor_linenr],edx
;
; compute crt_top_linenr
;
  xor	eax,eax
  mov	al,[edit_cursor_row]	;get display row
  sub	al,[edit_top_line]
  sub	edx,eax
  mov	[crt_top_linenr],edx

  ret  
;-------------------------
; set paramaters from cursor pointer
; input: edi = pointer to cursor data
;        edit_cursor_row - assumes cursor row is correct
; output: editbuf_cursor_ptr  (stored)
;         edit_cursor_col - updated column
;         editbuf_cursor_line_ptr
;         scroll_count
;         
set_cursor_from_ptr:
  push	edi
  mov	[editbuf_cursor_ptr],edi
  mov	ebx,edi			;save cursor ptr
  call	end_prev_line
  inc	edi			;move to start of current line
  mov	[editbuf_cursor_line_ptr],edi
;
; count text columns to cursor ptr (expanding tabs) (can be dword value)
;  edi = start of line
  mov	eax,1			;start line column at 1
ccp_05:
  cmp	edi,ebx
  je	ccp_50			;jmp if at match point
  cmp	byte [edi],09h		;check if on tab
  jne	ccp_20			;jmp if not tab
  dec	eax		
ccp_10:
  inc	eax
  test	al,07
  jnz	ccp_10			;skip for tab
  inc	eax		
  jmp	ccp_32
ccp_20:
  cmp	byte [edi],0ah		;check if at end of line
  je	ccp_50			;fix pointer if at end of line
ccp_30:
  inc	eax
ccp_32:
  inc	edi				;move to next char
  jmp	ccp_05
;
; we are now at cursor ptr, eax = 1 based column
;
ccp_50:
  sub	eax,[scroll_count]		;remove scroll columns
  jbe	ccp_left			;jmp if cursor outside window left
;
; check if cursor inside window
;
  push	ecx
  sub	ecx,ecx
  mov	cl,[win_columns]		;get crt columns
  cmp	eax,ecx				;are we inside crt window?
  pop	ecx
  jbe	ccp_60				;jmp if inside window
;
; we are not in window, window is to our right
;
  add	eax,[scroll_count]		;restore index
  inc	dword [scroll_count]
  jmp	ccp_50				;scroll left and try again
;
; cursor is outside window left
;
ccp_left:
  add	eax,[scroll_count]		;restore cursor index
  dec	dword [scroll_count]
  jmp	ccp_50				;scroll right and try again
;
; cursor is inside window, convert to physical coordinate
;
ccp_60:
  mov	byte [edit_cursor_col],al		;store column
  pop	edi
  ret


;-----------------------
; move to end of previous line
; input: edi = ptr somewhere inside current line, possibly on 0ah
; output: edi = ptr to end of previous line
;
end_prev_line:
  dec	edi
  cmp	byte [edi],0ah
  jne	end_prev_line
  ret
;------------------------
; move to next line
; input:  edi = ptr somewhere inside current line
; output: edi = pointer to start (past 0ah) of next line
;
nl_lp:
  inc	edi
next_line:
  cmp	byte [edi],0ah
  jne	nl_lp
  inc	edi
  ret


;------------------------
; move to line number in ecx
;  input: ecx = line number
;  output: display data updated
;
goto_line:
  mov	edi,[editbuf_top_ptr]		;start at top of file
  xor	eax,eax
gl_10:
  inc	eax			;bump line count
  cmp	eax,ecx
  je	gl_match		;jmp if line found
  cmp	edi,[editbuf_data_end_ptr]
  jae	gl_30			;jmp if at end of file
  call	next_line
  jmp	gl_10			;loop
gl_30:
  cmp	eax,1
  je	gl_exit			;jmp if empty file
  dec	eax
  call	end_prev_line
  call	end_prev_line
  inc	edi
gl_match:
  call	center_cursor
gl_exit:
  ret

;---------------------------
; compute line number from pointer
;  input:  edi = cursor ptr
;  output: edx = line number
;  
compute_line:
  push edi
  mov esi,[editbuf_top_ptr]			;get text start
  xchg esi,edi			;edi=start of text  esi=cursor position?
;
; compute current line#
;
  push ecx
  xor edx,edx
  cld

cl_lp:
  inc edx			;count line
  mov ecx,999999
  mov al,0ah
  repne scasb			;scan for 0ah
  mov eax,999998			;find eol
  sub eax,ecx			;eax = distance to end
  cmp edi,esi			;at cursor posn?
  jbe cl_lp			;loop till end
  
  pop ecx
  pop edi
  ret
;-------------------------------
; center cursor line
;  input: edi = current cursor ptr
;
center_cursor:
  cmp	edi,[editbuf_top_ptr]
  jae	cc_05			;jmp if pointer ok
  mov	edi,[editbuf_top_ptr]
cc_05:
  push	edi
  xor	ecx,ecx
  mov	cl,[win_rows]
  shr	ecx,1
cc_lp:
  cmp	edi,[editbuf_top_ptr]
  jbe	cc_11		;jmp if at top of file
  call	end_prev_line
  dec	ecx
  jnz	cc_lp
cc_10:
  inc	edi		;move to start of line
cc_11:
  cmp	edi,[editbuf_top_ptr]
  jb	cc_11a
  cmp	byte [edi-1],0ah ;check if at beginning of line
  je	cc_12
  dec	edi
  jmp	cc_11
cc_11a:
  mov	edi,[editbuf_top_ptr]
cc_12:  
  mov	[editbuf_display_page_ptr],edi
  call	compute_line
  mov	[crt_top_linenr],edx
;
  pop	edi
  call	set_cursor_from_ptr
  call	check_cursor_row
  call	compute_line
  mov	[cursor_linenr],edx
  ret
;----------------------------
; check cursor row
;  input: none
;         assumes [editbuf_display_page_ptr] and [editbuf_cursor_ptr] are correct
; output: [edit_cursor_row] (row)
;
check_cursor_row:
  push	edi
  mov	edi,[editbuf_display_page_ptr]
  mov	ebx,[editbuf_cursor_ptr]
  mov	eax,0			;starting row count
ccr_lp:
  call	next_line
  cmp	edi,ebx
  ja	ccr_match
  inc	eax
  jmp	ccr_lp
ccr_match:
  inc	al	;???
  mov	[edit_cursor_row],al	;store row
  pop	edi
  ret  

;-------------------------------------------------------------------
show_edit_buffer:
  mov	eax,[edit_top_line]
  mov	[start_row],al
  mov	ebx,[edit_end_line]
  sub	ebx,eax
  inc	bl
  mov	[win_rows],bl
  mov	eax,[editbuf_display_page_ptr]
  mov	[win_data_ptr],eax
  mov	eax,[editbuf_data_end_ptr]
  mov	[end_data_ptr],eax
  mov	esi,window_def
  call	crt_window
  mov	ah,[edit_cursor_row]
  mov	al,[edit_cursor_col]
  call	move_cursor
  ret
;-----------------
  [section .data]
;window structure
window_def:
page_color:	dd	30003436h	;window color
win_data_ptr:	dd	0
end_data_ptr:	dd	0
scroll_count	dd	0	;right/left window scroll count
win_columns	db	0	;window columns (1 based)
win_rows	db	0	;window rows (1 based)
start_row	db	0	;starting window row (1 based)
start_col	db	1	;starting window column (1 based)

  [section .text]
;-------------------------------------------------------------------
;ask if update/cancel, rename origional file
write_file:
  cmp	[new_source_flag],byte 0 ;check if existing file
  jnz	cf_write	;jmp if new file
  cmp	[editbuf_dirty],byte 0
  jz	cf_exit		;exit if nothing changed
  mov	esi,input_file
  mov	edi,input_file_backup
  call	str_move
  mov	[edi],word '~'	;replace end with ~
;rename input file to backup
cf_rename:
  mov	ebx,input_file
  mov	ecx,input_file_backup
  call	file_rename
;write edit buffer
cf_write:
  mov	ebx,input_file
  mov	ecx,[editbuf_top_ptr]
  mov	esi,[editbuf_data_end_ptr]
  sub	esi,ecx		;compute size of write
  xor	edx,edx		;default permissions
  call	block_write_all
cf_exit:
  mov	[editbuf_dirty],byte 0
  ret
;-----------
  [section .data]
input_file_backup: times 20 db 0
  [section .text]
;------------------------------------------------------------------
  [section .data]

input_file	times 200 db " "
input_file_buf_size equ $ - input_file
input_file_base times 100 db 0
input_file_ext_ptr:	dd 0

input_filename_msg: db 0ah
  db 'type <Enter> to browse for source file',0ah
  db 'if new file or name known, enter filename (xxx.nasm,xxx.fasm,etc.)',0ah
  db 'type <esc> to abort',0ah,0

filename_block:
  dd input_file
  dd	input_file_buf_size
  dd	menu_color
  db	5		;display row
  db	1		;display column
  db	1		;initial cursor
  dd	50		;window size
  dd	0		;scroll


makefile:
 db '######################################################',0ah
 db '#',0ah
 db '# modify the following as needed',0ah
 db '# select assembler, nasm, fasm, as, yasm',0ah
 db '#',0ah
 db 'assembler = '
make_assembler: db 'fasm',0ah
 db '#input file name xxxx.yyy is converted to base.ext in following:',0ah
 db 'base = '
make_base: db '                                                      ',0ah
 db 'ext = '
make_ext: db '          ',0ah
 db '  ',0ah
 db '######################################################',0ah
 db 'all:  touch $(base)',0ah
 db '',0ah
 db 'touch:',0ah
 db '	touch $(base).$(ext)',0ah
 db '',0ah
 db 'ifeq "$(assembler)" "nasm"',0ah
 db '$(base):	$(base).o',0ah
 db '	ld -static -o $(base) $(base).o /usr/lib/asmlib.a',0ah
 db '$(base).o:	$(base).$(ext)',0ah
 db '	nasm -g -felf $(base).$(ext)',0ah
 db 'endif',0ah
 db '',0ah
 db 'ifeq "$(assembler)" "as"',0ah
 db '$(base):	$(base).o',0ah
 db '	ld -static -o $(base) $(base).o /usr/lib/asmlib.a',0ah
 db '$(base).o:	$(base).$(ext)',0ah
 db '	as --gstabs $(base).$(ext) -o $(base).o',0ah
 db 'endif',0ah
 db '',0ah
 db 'ifeq "$(assembler)" "yasm"',0ah
 db '$(base):	$(base).o',0ah
 db '	ld -static -o $(base) $(base).o /usr/lib/asmlib.a',0ah
 db '$(base).o:	$(base).$(ext)',0ah
 db '	yasm -g stabs -f elf -o $(base).o $(base).$(ext)',0ah
 db 'endif',0ah
 db '',0ah
 db 'ifeq "$(assembler)" "fasm"',0ah
 db '$(base):	$(base).o',0ah
 db '	ld -static -o $(base) $(base).o /usr/lib/asmlib.a',0ah
 db '$(base).o:	$(base).$(ext)',0ah
 db '	fasm  $(base).$(ext)  $(base).o',0ah
 db 'endif',0ah
makefile_end:

asm_as:
  db '# source template - edit as needed',0ah
  db '.text',0ah
  db '.extern sys_exit',0ah
  db '.globl _start',0ah
  db '_start:',0ah
  db ' movl $4, %eax		#write code',0ah
  db ' movl $1, %ebx		#stdout',0ah
  db ' movl $message, %ecx	#message ptr',0ah
  db ' movl $15, %edx		#message length',0ah
  db ' int $0x80		#kernel call',0ah
  db ' call sys_exit		#exit',0ah
  db '.data',0ah
  db 'message:',0ah
  db ' .ascii "\nHello, World!\n"',0ah
asm_as_end:

asm_nasm_yasm:
  db '; -- source template - edit as needed --',0ah
  db '  [section .text]',0ah
  db '  extern sys_exit',0ah
  db '  global _start,main',0ah
  db 'main:',0ah
  db '_start:',0ah
  db '  mov	eax,4		;write function',0ah
  db '  mov	ebx,1		;stdout',0ah
  db '  mov	ecx,message	;message ptr',0ah
  db '  mov	edx,15		;message length',0ah
  db '  int	80h		;kernel call',0ah
  db '  call	sys_exit	;library call example',0ah
  db 0ah
  db ' [section .data]',0ah
  db "message db 0ah,'Hello, World!',0ah",0ah
asm_nasm_yasm_end:

asm_fasm:
  db '; -- source template - edit as needed',0ah
  db 'format ELF',0ah
  db 0ah
  db 'section ',27h,'.text',27h,' executable',0ah
  db 0ah
  db ' extrn sys_exit',0ah
  db ' public _start',0ah
  db '_start:',0ah
  db '',0ah
  db '	mov	eax,4	;write code',0ah
  db '	mov	ebx,1	;stdout',0ah
  db '	mov	ecx,msg	;message',0ah
  db '	mov	edx,msg_size',0ah
  db '	int	0x80		;write kernel call',0ah
  db 0ah
  db '	call	sys_exit	;library call example',0ah
  db 0ah
  db 'section ',27h,'.data',27h,'writeable',0ah
  db 0ah
  db "msg db 'Hello world!',0ah",0ah
  db 'msg_size = $-msg',0ah
  db 0ah
asm_fasm_end:

  [section .text]
;---------------------------------------------------------------
; determine filename and assembler type
;
get_filename:
  mov	esi,esp		;get stack pointer
  lodsd			;remove return address
  lodsd			;get number of parameters
  mov	ecx,eax		;save parameter count
  lodsd			;get first parameters, this is always our program name
  lodsd			;get possible filename ptr
  or	eax,eax
  jz	parse_no_file1	;jmp if filenot found
;check if file exists
  mov	esi,eax		;file ptr to esi
  mov	ebx,eax		;set ebx for block_open
  mov	edi,input_file
  call	str_move	;save filename
  jmp	check_for_file
;file name not provided by caller
; ask user if - browse for file?
;             - select filename
;             (fall through to templetate query)
parse_no_file1:
;clear input buffer
  mov	edi,input_file
  mov	ecx,input_file_buf_size
  mov	al,' '
  rep	stosb
;request filename from user
  mov	eax,[edit_color]
  call	crt_set_color
  mov	ecx,input_filename_msg
  call	stdout_str
  mov	ebp,filename_block
  call	get_text
;replace first space with zero
  mov	esi,input_file
pn_lp:
  lodsb
  cmp	al,' '
  jne	pn_lp
  mov	[esi-1],byte 0
;check if file enter key pressed
  cmp	[kbuf],byte 1bh	;escape pressed
  jne	parse_10	;jmp if no esc
  jmp	parse_exit
parse_10:
  cmp	[kbuf],byte 0dh
  je	parse_20	;jmp if possible file entered
  cmp	[kbuf],byte 0ah
  jne	parse_no_file1
parse_20:
  mov	ebx,input_file
  cmp	[input_file],byte 0	;anything here?
  jnz	check_for_file
;browse for file name
  mov	esi,bss_end
  call	browse_dir_right
  or	eax,eax
  jnz	parse_no_file1		;jmp if no file found
  mov	esi,ebx
  push	esi
  mov	edi,input_file
  call	str_move
  pop	esi
  mov	eax,[compile_color]
  call	crt_clear	;clear screen
  mov	ax,0101h
  call	move_cursor

check_for_file:
  mov	ebx,input_file
  mov	ecx,6	;check for read/write access
  call	file_access
  or	eax,eax
  jz	parse_setup_check	;jmp if access ok
;
;file name provided,but file not found.
; ask user if - setup template file?
;             - start with blank file?
parse_no_file2:
  or	[new_source_flag],byte 1

parse_setup_check:
  call	switch_to_source_dir
  call	check_assembler
  cmp	[make_assembler_type],byte 0
  jne	parse_exit		;exit if assembler known
  cmp	[makefile_found_flag],byte 0
  je	get_assembler
;read makefile and extract assembler type
  mov	ebx,tool_table+1	;makefile_name
  mov	ecx,work_buf
  mov	edx,2000		;work buf size
  call	block_read_all

  mov	eax,[work_buf + (make_assembler - makefile)]
;    1. as',0ah
;    2. nasm',0ah
;    3. yasm',0ah
;    4. fasm',0ah,0
  cmp	ax,'as'
  jne	try_nasm
  mov	al,'1'
  jmp	short pa_stuff
try_nasm:
  cmp	eax,'nasm'
  jne	try_yasm
  mov	al,'2'
  jmp	short pa_stuff
try_yasm:
  cmp	eax,'yasm'
  jne	try_fasm
  mov	al,'3'
  jmp	short pa_stuff
try_fasm:
  cmp	eax,'fasm'
  jne	get_assembler	;jmp if unknown assembler
  mov	al,'4'
pa_stuff:
  mov	[kbuf],al
  call	store_assembler
  jmp	short parse_exit
get_assembler:
  call	select_assembler
  cmp	[make_assembler_type],byte 0
  jne	parse_exit
  mov	[kbuf],byte 1bh	;force error          
parse_exit:
  ret
;-------------
  [section .data]
 db 0
new_source_flag	db 0
  [section .text]
;---------------------------------------------------------------
;output: carry set if error msg
; check for make,ld, target assembler
check_installed_programs:
  cmp	[touch_found_flag],byte 0
  jne	cip_10		;jmp if touch found
  mov	ecx,touch_warn
  call	stdout_str
  jmp	cip_error  
cip_10:
  cmp	[make_found_flag],byte 0
  jne	cip_20		;jmp if make found
  mov	ecx,make_warn
  call	stdout_str
  jmp	short cip_error
cip_20:
  cmp	[ld_found_flag],byte 0
  jne	cip_30		;jmp if ld found
  mov	ecx,ld_warn
  call	stdout_str
  jmp	short cip_error
cip_30:
  mov	al,[make_assembler_type]
;    1. as',0ah
;    2. nasm',0ah
;    3. yasm',0ah
;    4. fasm',0ah,0
  cmp	al,1
  jne	cip_40
;check as
  cmp	[as_found_flag],byte 0
  jne	cip_exit
  mov	ecx,as_warn
  call	stdout_str
  jmp	short cip_error
cip_40:
  cmp	al,2
  jne	cip_60
;check nasm
  cmp	[nasm_found_flag],byte 0
  jne	cip_exit
  mov	ecx,nasm_warn
  call	stdout_str
  jmp	short cip_error
cip_60:
  cmp	al,3
  jne	cip_80
;check yasm
  cmp	[fasm_found_flag],byte 0
  jne	cip_exit
  mov	ecx,yasm_warn
  call	stdout_str
  jmp	short cip_error
cip_80:
  cmp	al,4
  jne	cip_error
;check fasm
  cmp	[fasm_found_flag],byte 0
  jne	cip_exit
  mov	ecx,fasm_warn
  call	stdout_str
;  jmp	short cip_error
cip_error:
  mov	ecx,press_key
  call	stdout_str
  call	read_stdin
  stc
  jmp	short cip_exit2
cip_exit:
  clc
cip_exit2:
  ret
;-------------
   [section .data]
touch_warn: db 0ah,'Error, touch utillty not available',0ah,0
make_warn: db 0ah,'Error, make utility not available',0ah,0
ld_warn: db 0ah,'Error, linker -ld- not available',0ah,0
as_warn: db 0ah,'Error, assembler -as- not available',0ah,0
nasm_warn: db 0ah,'Error, assembler -nasm- not available',0ah,0
yasm_warn: db 0ah,'Error, assembler -yasm- not available',0ah,0
fasm_warn: db 0ah,'Error, assembler -fasm- not available',0ah,0
press_key: db 'Press any key to continue',0
   [section .text]
;---------------------------------------------------------------
;we have make a assembler selection, use to build a makefile
;set carry if fatal error
create_makefile:
  mov	esi,input_file
;put zero at end of input filename
cm_lp:
  lodsb
  cmp	al,0
  je	cm_end
  cmp	al,' '
  jne	cm_lp
cm_end:
  mov	[esi-1],byte 0
;move back to start of extension
  mov	ecx,7
cm_lp2:
  cmp	[esi],byte '.'
  je	cm_dot
  dec	esi
  loop	cm_lp2
  jmp	cm_error
;we are now pointing at dot
cm_dot:
  inc	esi
  mov	[input_file_ext_ptr],esi
;scan back to start of filename
cm_lp3:
  cmp	esi,input_file
  je	cm_start2
  cmp	[esi],byte '/'
  je	cm_start1
  dec	esi
  jmp	short cm_lp3
cm_start1:
  inc	esi		;move past '/'
cm_start2:
;move base to input_file_base
  mov	edi,input_file_base
cm_lp4:
  lodsb			;get char
  cmp	al,'.'		;end of base?
  je	cm_base_end
  stosb
  jmp	short cm_lp4
cm_base_end:
  mov	al,0
  stosb
;put base name in makefile
  mov	esi,input_file_base
  mov	edi,make_base
  call	str_move
  mov	[edi],byte 0ah
;put extensin name in makefile
  mov	esi,[input_file_ext_ptr]
  mov	edi,make_ext
  call	str_move
  mov	[edi],byte 0ah
;put assembler in makefile
  mov	al,[make_assembler_type]
  or	al,30h
  mov	[kbuf],al
  call	store_assembler

; write makefile
  mov	ebx,tool_table+1	;makefile_name
  mov	ecx,makefile		;ptr to data
  mov	esi,makefile_end	;compute length
  sub	esi,ecx			; of write
  xor	edx,edx			;default permissions
  call	block_write_all		;write file
  jmp	short cm_exit1

cm_error:
  mov	ecx,file_error
  call	stdout_str
  call	read_stdin
  stc
  jmp	short cm_exit2
cm_exit1:
  clc
cm_exit2:
  ret
;------------
  [section .data]
file_error: db 0ah,'Error - source file extension incorrect',0ah
	    db 'Press any key to continue',0
  [section .text]
;---------------------------------------------------------------
fill_input_buffer:
  call	memory_init
  mov	[editbuf_top_ptr],eax		;save memory start
  mov	[editbuf_display_page_ptr],eax	;top display page
  mov	[editbuf_cursor_ptr],eax

  cmp	[new_source_flag],byte 0
  jne	rif_10			;jmp if new file

;check if file size available
  mov	ebx,input_file
;read file size
  call	file_length_name	;returns size in eax
  add	eax,[editbuf_top_ptr]	;compute end of edit data
rif_05:
  mov	[editbuf_data_end_ptr],eax
rif_10:
  add	eax,8000h		;add in work area
  mov	[editbuf_mem_end_ptr],eax
;allocate full buffer
  mov	ebx,eax			;memory end to ebx
  call	set_memory		;expand buffer
  cmp	[new_source_flag],byte 0
  jne	fib_template		;jmp if new file

;read file into buffer
  mov	ebx,input_file
  mov	ecx,[editbuf_top_ptr]
  mov	edx,[editbuf_mem_end_ptr]
  sub	edx,ecx
  call	block_read_all
  jmp	at_exit  

fib_template:
;write template to input buffer
  cmp	[make_assembler_type],byte 0 ;is assembler type known
  jne	have_assembler
  call	select_assembler
;    1. as',0ah
;    2. nasm',0ah
;    3. yasm',0ah
;    4. fasm',0ah,0
have_assembler:
  mov	al,[make_assembler_type]
  cmp	al,1
  je	bup_48	;jmp if gas
  cmp	al,2	;assembler=nasm?
  je	bup_50
  cmp	al,3	;assembler=yasm?
  je	bup_50
  cmp	al,4	;assembler=fasm?
  je	bup_52
  jmp	at_exit
;setup to write 'gas' source
bup_48:
  mov	eax,asm_as
  mov	ecx,asm_as_end
  sub	ecx,eax			;compute length of write
  jmp	short bup_58		;go write file
bup_50:
  mov	eax,asm_nasm_yasm
  mov	ecx,asm_nasm_yasm_end
  sub	ecx,eax
  jmp	short bup_58
bup_52:
  mov	eax,asm_fasm
  mov	ecx,asm_fasm_end
  sub	ecx,eax
;eax=template ptr
;ecx=template length
;write template to buffer
bup_58:
  mov	esi,eax
  mov	edi,[editbuf_top_ptr]
  rep	movsb			;move template
  mov	[editbuf_data_end_ptr],edi
at_exit:
  mov	eax,[editbuf_data_end_ptr]
  mov	[eax],byte 0ah
  mov	eax,[editbuf_top_ptr]
  mov	[eax-1],byte 0ah
  ret
;---------------------------------------------------------------
check_assembler:
  mov	esi,input_file
ca_lp:
  lodsb
  cmp	al,0
  je	ca_end
  cmp	al,' '
  jne	ca_lp	;loop till end of name
ca_end:
;    1. as',0ah
;    2. nasm',0ah
;    3. yasm',0ah
;    4. fasm',0ah,0
  sub	esi,3
  cmp	[esi],word '.s'
  je	set_as
  sub	esi,2
  cmp	[esi],dword 'nasm'
  je	set_nasm
  cmp	[esi],dword 'fasm'
  je	set_fasm
  cmp	[esi],dword 'yasm'
  jne	ca_exit
set_yasm:
  mov	al,'3'
  jmp	short ca_stuff
set_as:
  mov	al,'1'
  jmp	short ca_stuff
set_nasm:
  mov	al,'2'
  jmp	short ca_stuff
set_fasm:
  mov	al,'4'
ca_stuff:
  mov	[kbuf],al
  call	store_assembler
ca_exit:
  ret  
;---------------------------------------------------------------
select_assembler:
  cmp	[make_assembler_type],byte 0
  jne	psc_asm_end		;exit if assembler already known
  mov	ecx,assembler_msg
  call	stdout_str
  call	read_stdin
store_assembler:
  mov	al,[kbuf]
  cmp	al,'1'
  jne	try__nasm
  mov	eax,0a0a0a0ah
  mov	ax,'as'
  jmp	short stuff_assembler
try__nasm:
  cmp	al,'2'
  jne	try__yasm
  mov	eax,'nasm'
  jmp	short stuff_assembler

try__yasm:
  cmp	al,'3'
  jne	try__fasm
  mov	eax,'yasm'
  jmp	short stuff_assembler

try__fasm:
  cmp	al,'4'
  jne	psc_asm_end
  mov	eax,'fasm'
stuff_assembler:
  mov	[make_assembler],eax
  mov	al,[kbuf]
  and	al,7			;isolate assebler code
  mov	[make_assembler_type],al
psc_asm_end:
  ret
;-------------------------
[section .data]
make_assembler_type: db 0

assembler_msg:
  db '-- Enter number (1-4) of assembler --',0ah
  db '   1. as',0ah
  db '   2. nasm',0ah
  db '   3. yasm',0ah
  db '   4. fasm',0ah,0


[section .text]
;-------------------------------------------------------------------
check_key_files:
  mov	esi,tool_table
ttf_lp:
  mov	ebp,esi
ttf_lp1:
  lodsb
  or	al,al
  jnz	ttf_lp1			;loop till zero at end of name

  cmp	byte [ebp],'.'		;local file?
  je	ttf_local		;jmp if local file
  cmp	byte [ebp],'/'
  jne	ttf_exec		;jmp if executable
;absolute path found, check if available
  mov	ebx,ebp
  push	esi
  call	file_status_name
  pop	esi
  lodsd				;get flag ptr
  js	ttf_skip		;jmp if file not found
  jmp	ttf_set_flag
;check for local file
ttf_local:
  inc	ebp
  mov	ebx,ebp
  push	esi
  call	file_status_name
  pop	esi
  lodsd				;get flag ptr
  js	ttf_skip		;jmp if file not found
  jmp	ttf_set_flag

;check for executable
ttf_exec:
  mov	ebx,[enviro_ptrs]
  push	esi
  call	env_exec		;search for executable
  pop	esi
  lodsd				;get flag
  jc	ttf_skip		;jmp if file not found
ttf_set_flag:
  or	byte [eax],1		;file found, set flag
ttf_skip:
  cmp	byte [esi],0		;end of table?
  jnz	ttf_lp			;jmp if more data

ttf_exit:
  ret
;-------------
  [section .data]
;
; a "." in front of name says to look local
;
tool_table:
  db '.asmide_makefile',0
  dd makefile_found_flag
  db 'touch',0
  dd touch_found_flag
  db 'as',0
  dd as_found_flag
  db 'yasm',0
  dd yasm_found_flag
  db 'fasm',0
  dd fasm_found_flag
  db 'nasm',0
  dd nasm_found_flag
  db 'ld',0
  dd ld_found_flag
  db 'make',0
  dd make_found_flag
  db 'bash',0
  dd bash_found_flag
  db '/usr/lib/asmlib.a',0
  dd asmlib_found_flag
  db 0			;end of table

touch_found_flag:	db 0
makefile_found_flag:	db 0
make_found_flag:	db 0
as_found_flag:		db 0
yasm_found_flag:	db 0
fasm_found_flag:	db 0
nasm_found_flag:	db 0
ld_found_flag:		db 0
bash_found_flag:	db 0
asmlib_found_flag	db 0

  [section .text]
;-------------------------------------------------------------------
show_edit_menu:
  mov	ebx,menu_color
  mov	ch,[edit_top_menu_line]
  mov	esi,sem_menu1
  call	build_and_show_line

;fill in status line row & column
  mov	eax,[cursor_linenr]
  mov	edi,ascii_linenr
  mov	esi,5		;digits to store
  call	dword_to_l_ascii

  mov	eax,[edit_cursor_col]
  add	eax,[scroll_count]
  mov	edi,ascii_column
  mov	esi,3
  call	dword_to_l_ascii
  
;show edit menu end
;inputs:  ebx = ptr to color table
;          ch = display row
;         esi = message with embedded color codes
  mov	ebx,menu_color
  mov	ch,[edit_end_menu_line]
  mov	esi,sem_menu2
  call	build_and_show_line

  ret

;-------------------
  [section .data]
sem_menu1:	db 1,' ',2,'F1',1,'=AsmRef ',2,'F2',1,'=help ',2,'F3',1,'=compile ',2,'F4',1,'=debug ',2,'F10',1,'=quit',0
sem_menu1_end	equ $ - sem_menu1 

sem_menu2:	db 1,'Line=',2
ascii_linenr:   db '      ',1,'Column= ',2
ascii_column:   db '    ',1,' ',2,'F5',1,'=insrt ',2,'F6',1,'=goto ',2,'F7',1,'=find ',2,'F8',1,'delete line',0
sem_menu2_end	equ $ - sem_menu2 
  [section .text]
;-------------------------------------------------------------------
show_compile_menu:
  mov	ecx,[compile_menu_line]
  jecxz	scm_exit	;exit if compile menu inactive

  mov	eax,[edit_color]
  call	crt_clear

  mov	ebx,menu_color
  mov	ch,1
  mov	esi,scm_text
  call	build_and_show_line

scm_exit:
  ret

scm_text:	db 1,'Compile output -- ',2,'F9',1,' = close error window',0
scm_end	equ $ - scm_text  
;-------------------------------------------------------------------
show_compile_window:
  cmp	[compile_menu_line],dword 0
  je	scw_exit
  mov	ax,0201h
  call	move_cursor
  mov	eax,[edit_color]
  call	crt_set_color
;  mov	ecx,compile_header
;  call	stdout_str
;show file compile_results
  mov	ebx,compile_results_filename
  mov	ecx,work_buf
  mov	edx,2000	;max buffer size
  call	block_read_all

  add	eax,work_buf	;compute end of data
  mov	[win_data_end],eax
  mov	al,[crt_columns]
  mov	[win_cols],al
  mov	al,[compile_end_line]
  sub	al,3
  mov	[wn_rows],al
  mov	esi,win_block
  call	crt_window
scw_exit:
  ret
;--------------
  [section .data]
compile_results_filename: db 'compile_results',0

win_block:
  dd 30003734h	;color
  dd work_buf	;data buffer
win_data_end:
  dd 0
  dd 0		;scroll
win_cols:
  db 0		;window columns
wn_rows:
  db 0		;window rows
  db 3		;starting row
  db 1		;starting column
  [section .text]
;-------------------------------------------------------------------
;inputs:  ebx = ptr to color table
;          ch = display row
;         esi = message with embedded color codes
build_and_show_line:
  push	ecx
  mov	edi,work_buf
  call	str_move
  mov	edx,edi		;get end of msg
  sub	edx,work_buf	;compute msg length
  mov	ecx,[crt_columns]
  sub	ecx,edx		;compute padding  
  js	bas_skip	;jmp if overflow
  mov	al,' '
  rep	stosb
bas_skip:
  mov	[edi],byte 0ah	;terminate line

  pop	ecx
  mov	cl,1		;startng column
  mov	dl,[crt_columns];end column
  mov	esi,work_buf
  xor	edi,edi		;no scroll
  call	crt_line
  ret
;---------------------------------------------------------------------
enable_compile_win:
  call	read_window_size
  mov	eax,[crt_rows]
  mov	[edit_end_menu_line],eax
  dec	eax
  mov	[edit_end_line],eax

  mov	[compile_menu_line],dword 1
  sub	eax,11		;size of compile window+1
  mov	[compile_end_line],eax
  inc	eax
  mov	[edit_top_menu_line],eax
  inc	eax
  mov	[edit_top_line],eax
  mov	esi,[editbuf_cursor_ptr]
  call	compute_cursor_data
  ret
;-------------------------------------------------------------------
set_edit_only_win:
  call	read_window_size
  mov	eax,[crt_rows]
  mov	[edit_end_menu_line],eax
  dec	eax
  mov	[edit_end_line],eax
  mov	[edit_top_line],dword 2
  mov	[edit_top_menu_line],dword 1
  mov	[compile_menu_line],dword 0
  mov	eax,[crt_columns]
  mov	[win_columns],al
  mov	esi,[editbuf_cursor_ptr]
  call	compute_cursor_data
  ret
;-------------------------------------------------------------------
switch_to_source_dir:
  mov	esi,input_file
  mov	edi,source_path
  call	str_move  
;scan back till start of first '/'
st_lp1:
  cmp	edi,source_path
  je	st_none		;jmp if no extended path
  cmp	[edi],byte '/'
  je	st_got
  dec	edi
  jmp	short st_lp1
;we have found full path
st_got:
  mov	[edi],byte 0	;terminate path
  mov	ebx,source_path
  call	dir_change
st_none:
  ret
;---------
  [section .data]
source_path:	times 120 db 0
  [section .text]
;-------------------------------------------------------------------
get_current_dir:
  call	dir_current
  mov	esi,ebx		;get path ptr
  mov	ecx,eax		;get length
  mov	edi,entry_path
  rep	movsb
  ret
;---------
  [section .data]
entry_path:
  times	120 db 0
  [section .text]
;-------------------------------------------------------------------
restore_current_dir:
  mov	ebx,entry_path
  call	dir_change
  ret
;-------------------------------------------------------------------
  [section .data]

;edit buffer records
editbuf_top_ptr:	dd	0	;top of file
editbuf_display_page_ptr: dd	0	;top of display page
editbuf_cursor_ptr:	dd	0	;ptr to cursor
editbuf_data_end_ptr:	dd	0	;end of file
editbuf_mem_end_ptr	dd	0	

editbuf_dirty		dd	0
editbuf_cursor_line_ptr	dd	0
cursor_linenr		dd	1

;window definition
compile_menu_line	dd 0	;=0 if no compile window
compile_end_line	dd 0	;
edit_top_menu_line	dd 0	;=1 if no compile window
edit_top_line		dd 0	;=2 if no compile window
edit_end_line		dd 0
edit_end_menu_line	dd 0

crt_top_linenr:		dd 0
edit_cursor_row		dd 0 
edit_cursor_col		dd 1

;color settings
menu_color:	dd 30003037h
menu_highligh_color dd 30003234h
compile_color:	dd 30003734h
edit_color:	dd 30003734h

;-------------------------------------------------------------------
  [section .bss]
work_buf:	resb	4000
bss_end: