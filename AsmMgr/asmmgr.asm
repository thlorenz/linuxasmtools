
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
; NAME
;  asmmgr - file manager for assembler IDE
; INPUTS
;  * usage:  asmmgr  <project-path>
; OUTPUT
; NOTES
; * source file: asmmgr.asm
; * ----------------------------------------------

 
;  extern crt_open, crt_close
  extern mouse_enable
  extern crt_clear
  extern str_move
  extern file_read_all,file_write_close
  extern file_read_grow
  extern form
  extern crt_rows,crt_columns
  extern env_home
  extern env_stack
  extern env_shell
;  extern crt_mouse_line
%include "crt_mouse_line.inc"
  extern lib_buf
  extern mov_color
;  extern move_cursor
%include "crt_move.inc"
  extern kbuf
  extern dir_open_indexed
  extern dir_sort_by_type
  extern dir_close_file
  extern dir_change,dir_status
  extern dir_access
  extern dir_current
;;  extern crt_set_color
  extern key_decode1
  extern is_alpha
  extern mouse_line_decode
;  extern crt_win_from_ptrs
  extern crt_window2
  extern crt_line
  extern dword_to_r_ascii
  extern str_search
;  extern sort_selection
  extern find_env_variable,enviro_ptrs
  extern crt_color_at
  extern dir_create
  extern file_simple_read
  extern blk_del_bytes
  extern blk_insert_bytes
  extern install_signals
  extern sys_wrap
  extern alt_screen,normal_screen
  extern winsize
  extern read_window_size
;%include "read_winsize.inc"
  [section .text]

  extern read_stdin
  extern stdout_str
  extern delay
  extern key_poll
  extern raw_set2,raw_unset2
  extern key_flush
  extern str_end
  extern strlen1
  extern str_compare
  extern byte2hexstr
  extern save_cursor_at,restore_cursor_from
  extern cursor_unhide
  extern file_status_name
  extern read_termios_0
  extern output_termios_0
  extern set_memory
  extern get_string

  struc	stat_struc
.st_dev: resd 1
.st_ino: resd 1
.st_mode: resw 1
.st_nlink: resw 1
.st_uid: resw 1
.st_gid: resw 1
.st_rdev: resd 1
.st_size: resd 1
.st_blksize: resd 1
.st_blocks: resd 1
.st_atime: resd 1
.__unused1: resd 1
.st_mtime: resd 1
.__unused2: resd 1
.st_ctime: resd 1
.__unused3: resd 1
.__unused4: resd 1
.__unused5: resd 1
;  ---  stat_struc_size
  endstruc

struc win_struc
.columns:  resb 1	;total columns in window
.rows:     resb 1	;total rows in window
.top_row:  resb 1	;top row
.top_col:  resb 1	;top column
.top_row_ptr resd 1	;ptr to [_index_ptr] for window top
;
.win_status resb 1	;0=uninitialized 1=in memory 2=swaped to temp file
.win_path   resb 200
.row_select resb 1	;row number selected for action
.selected_ptr resd 1	;ptr to row currently selected
.top_index resd 1	;ptr to top of index list
endstruc

; structure describing a directory entry
struc dtype
.d_size	resd 1	;byte size for fstat .st_size
.d_mode	resw 1	;type information from fstat .st_mode 
.d_uid  resw 1  ;owner code
.d_len   resb 1  ;length byte from dent structure
.d_type  resb 1  ;type code 1=dir 2=symlink 3=file
.d_nam resb 1	;directory name (variable length)
endstruc

;
;  Copyright (c) 2004,2005 Jeff Owens
;
;  This program is free software; you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program; if not, write to the Free Software
;  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

setup_buf_size	equ	20000
; (#1#) main **********************************************


[section .text]
  global _start
  global main

; The program begins execution here...... 
;
main:
_start:
  cld
  call	env_stack		;setup env ptr
  call	memory_setup
  call	process_scan
  call	read_window_size
;;  dec	byte [crt_rows]
  mov	ecx,reset_msg
  call	stdout_str
  mov	edx,termios
  call	read_termios_0		;save termios
  call	mouse_enable
  call	signal_install		;install sig_WINCH, (screen resize)
  mov	eax,24			;kernel getuid call
  int	80h
  or	eax,eax			;check if user zero
  jnz	mgr_10			;jmp if not  root
  mov	byte [root_flag],1
  mov	dword [mid_button_color2],31003731h
mgr_10:
  mov	byte [first_time_flag],1
  call	parse			;sets project_name, 0=no name
  or	eax,eax
  js	exit2			;exit if parse error
  call	clear_terminal
restart:
  call	get_tables
  jc	exit2			;exit if requested by "quit" script
  call	setup_window_paths	;clears first time flag, sets path
window_resize:
  call	compute_window_sizes
  mov	byte [window_resize_flag],0	;
main_lp1:
  mov	byte [left_win_status],0	;force dir read
  mov	byte [right_win_status],0	;force dir read
main_lp2:
  call	alt_screen
  call	display_buttons
  call	display_mid_buttons
  call	display_inactive_window
main_lp3:
  call	display_active_window
  call	display_selector_bar
  call	display_status_line
main_lp4:
  call	display_term_line		;returns process to call (eax)
  call	set_win_struc_ptr		;set ebp to struc
  call	eax
  cmp	byte [window_resize_flag],0
  jne	window_resize			;jmp if window resize
  mov	al,[cmd_status]
  or	al,al
  js	exit2				;exit if abort request
  test	al,1
  jnz	main_lp1			;
  test	al,2
  jnz	main_lp2			;default looping state
  test	al,4
  jnz	main_lp3
  jmp	short restart			;assume bit 08 is set
;
exit2:
  mov	eax,10
  mov	ebx,left_fname
  int	80h			;delete temp file at /tmp/left.0

  mov	eax,10
  mov	ebx,right_fname
  int	80h			;delete temp fie at /tmp/right.o

  call	normal_screen
  mov	ecx,reset_msg
  call	stdout_str
  mov	edx,termios
  call	output_termios_0
;  mov	eax,30003730h		;exit screen color
;  call	crt_clear
  xor	ebx,ebx			;set return code
  mov	eax,1
  int	80h
;---------
  [section .data]
reset_msg:	db 1bh,'c',0
;reset_msg:	db 1bh,'!p',0
  [section .text]
;----------------------------------------
; Action Subroutines ********************
;----------------------------------------
; all action routines can set [cmd_status] negative to abort
; setting [cmd_status]=8 says use prepared message
;
;-----------------------------------------------------------------
null_action:
  ret
;-----------------------------------------------------------------
dir_fwd:
  mov	byte [symlink_flag],0	;clear symlink flag, only allow
;                               restore of path for initial entry
;                               of directory.
  call	make_active_selection
  or	al,al
  jz	df_exit			;exit if null path or error
  cmp	al,2			;check if dir or symlink dir
  ja	df_exit			;exit if not dir
  mov	esi,smsg_txt
  lea	edi,[ebp+win_struc.win_path]
  call	str_move
  mov	byte [ebp+win_struc.win_status],0
  cmp	byte [type_code],2	;is this a symlink dir, see make_active_selection
  jne	df_exit1		;exit if not symlink dir
  mov	byte [symlink_flag],1	;set symlink flag for dir_bak
  mov	edi,symlink_buf
  mov	esi,smsg_txt
  call	str_move
df_exit1:
  mov	byte [ebp+win_struc.win_status],0
df_exit:
  ret
;-----------------------------------------------------------------
dir_bak:
  call	set_win_struc_ptr
  lea	esi,[ebp+win_struc.win_path]
  mov	edx,esi			;save start of current path
  cmp	byte [esi +1],0
  je	db_exit			;exit if at root
  cmp	byte [symlink_flag],0
  je	left_10			;jmp if previous dir/file was not a symlink
  push	esi
  mov	edi,esi
  mov	esi,symlink_buf
  call	str_move		;move symlink parent to win_path
  pop	esi  
  mov	byte [symlink_flag],0	;disable symlink_buf
left_10:
  lodsb
  or	al,al
  jnz	left_10			;scan to end of path
left_20:
  dec	esi
  cmp	byte [esi],"/"
  jne	left_20			;loop till start of old path found
  call	save_old_path
  cmp	esi,edx			;check if at root
  je	left_40			;jmp if at root
  mov	byte [esi],0
  jmp	short left_50
left_40:
  mov	byte [esi+1],0		;truncate path
left_50:
  mov	byte [ebp+win_struc.win_status],0
db_exit:
  ret
;----------------------------
save_old_path:
  push	esi
  mov	edi,old_path
  inc	esi		;move past /
sop_10:
  lodsb
  stosb
  cmp	al,'/'
  je	sop_20		;jmp if end of name
  or	al,al
  jnz	sop_10
sop_20:
  mov	byte [edi-1],0	;force zero at end
  pop	esi
  ret
  
;------------------------------------------------------------------
dir_up:
  call	set_win_struc_ptr
  cmp	byte [ebp+win_struc.row_select],3	;select at top of window
  ja	du_40					;jmp if selector not at top
; selector is at top, check if window can move up
  mov	eax,[bss_base]
  mov	eax,[eax+dir._index_ptr]			;get index top
  cmp	dword [ebp+win_struc.top_row_ptr],eax
  je	du_50					;jmp if window at start of file
; move window up one
  sub	dword [ebp+win_struc.top_row_ptr],4
  jmp	short du_45
du_40:
  dec	byte [ebp+win_struc.row_select]
du_45:
  sub	dword [ebp+win_struc.selected_ptr],4
du_50:
  mov	byte [cmd_status],4  
  ret
;-------------------------------------------------------------------
dir_down:
  call	set_win_struc_ptr
  xor	eax,eax
  mov	al,[ebp+win_struc.top_row]
  add	al,[ebp+win_struc.rows]		;compute line beyond last line
  dec	al
  cmp	al,[ebp+win_struc.row_select]	;check if at end of window
  ja	dd_20				;jmp if inside window
; we are at end of window, check if at end of file
  call	page_fwd
;         bh=lines in current page
;         ch=lines in next page
;        eax=0 if end of file found
;         bl=0 if current page full, else blank lines in page
;         cl=0 if next page full, else blank lines in page
  or	ch,ch
  jz	dd_exit			;exit if no lines in next page
  add	dword [ebp+win_struc.top_row_ptr],4
  jmp	short dd_30
dd_20:
  mov	eax,[ebp+win_struc.selected_ptr]
  cmp	dword [eax+4],0
  je	dd_exit					;exit if at end of pointers
;it is ok to move down
  inc	byte [ebp+win_struc.row_select]
dd_30:
  add	dword [ebp+win_struc.selected_ptr],4
dd_exit:
  mov	byte [cmd_status],04			;main_lp3
  ret
;------------------------------------------------------
pgup_key:
  xor	ebx,ebx
  mov	cl,[ebp+win_struc.rows]	;get total rows in this window
  mov	bl,0			;init row counter
  mov	esi,[ebp+win_struc.top_row_ptr] ;get ptr to top win ptr
;check if at top of directory
  mov	eax,[bss_base]
  cmp	esi,[eax+dir._index_ptr]	;at top?
  jne	pk_lp1			;exit if not at top
;put select bar at top if already in top page  
  mov	eax,[ebp+win_struc.top_row_ptr]
  mov	[ebp+win_struc.selected_ptr],eax

  mov	bh,[ebp+win_struc.top_row]
  mov	[ebp+win_struc.row_select],bh
  mov	[cmd_status],byte 4
  jmp	short pk_exit

;move up one page
pk_lp1:
  mov	eax,[bss_base]
  cmp	esi,[eax+dir._index_ptr]	;check if at top of dir
  jbe	pk_at_top
  sub	esi,4			;move up one ptr
  inc	bl
  dec	cl
  jnz	pk_lp1			;loop
;
; esi = top of new window or unchanged if at top already
;  bl = number of rows moved
;  cl = 0 if full window move
pk_at_top:  
  mov	[ebp+win_struc.top_row_ptr],esi ;new window top
  shl	ebx,2			;compute number of ptrs moved
  sub	[ebp+win_struc.selected_ptr],ebx  ;new selection bar ptr


pk_exit:
  ret
;--------------------------------------------------------
pgdn_key:
  call	set_win_struc_ptr
  call	page_fwd
;         bh=lines in current page
;         ch=lines in next page
;        eax=0 if end of file found
;         bl=0 if current page full, else blank lines in page
;         cl=0 if next page full, else blank lines in page
  or	bh,bh		;check for empty page
  je	pgdn_exit	;exit if empty dir
  xor	eax,eax
  mov	al,ch		;get lines in next page
  shl	eax,2		;convert to ptr index
  add	[ebp+win_struc.top_row_ptr],eax ;new window top
  add	[ebp+win_struc.selected_ptr],eax  ;new selection bar ptr
;if this is last page, then move cursor to end of page
  or	ch,ch
  jnz   pgdn_exit	;jmp if not last page
  xor	eax,eax
  mov	al,bh		;get lines in current page
  dec	eax
  shl	eax,2
  add	eax,[ebp+win_struc.top_row_ptr]
  mov	[ebp+win_struc.selected_ptr],eax

  add	bh,[ebp+win_struc.top_row]
  dec	bh
  mov	[ebp+win_struc.row_select],bh
pgdn_exit:
  mov	[cmd_status],byte 4
  ret
;--------------------------------------------------------
tab_key:
  xor	byte [active_window],3
  mov	byte [cmd_status],21h
  ret
;--------------------------------------------------------
left_win_click:
  cmp	byte [active_window],1
  je	rwc_10			;jmp if left window already active
  xor	byte [active_window],3
  jmp	rwc_exit
;--------------------------------------------------------
right_win_click:
  cmp	byte [active_window],1	;check if left window active
  jne	rwc_10			;jmp if right window active
  xor	byte [active_window],3
  jmp	rwc_exit		;select window and exit
;move select pointer
rwc_10:
  call	set_win_struc_ptr	;sets ebp = to active window struc
  mov	al,[ebp+win_struc.top_row]	;row#
  mov	esi,[ebp+win_struc.top_row_ptr] ;sort pointers
rwc_lp:
  cmp	dword [esi+4],0		;check if at end of sort ptrs
  je	rwc_50			;jmp if at end
  cmp	al,[kbuf+3]		;check if at correct row yet
  je	rwc_50
  inc	al			;move to next row
  add	esi,4			;move to next ptr
  jmp	rwc_lp
rwc_50:
  cmp	al,[ebp+win_struc.row_select]
  jne	rwc_60
  jmp	f2_key
rwc_60:
  mov	byte [ebp+win_struc.row_select],al
  mov	dword [ebp+win_struc.selected_ptr],esi
rwc_exit:
  ret
  
;--------------------------------------------------------
f1_key:				;file/directory status
  call	make_active_selection	;builds at smsg_txt
  or	al,al
  jz	f1_abort		;exit if error or null file
  mov	esi,cmd_line
  mov	edi,temp_buf
  call	str_move
  mov	esi,smsg_txt
  call	move_quoted

  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch
  call	cursor_to_end
  mov	byte [cmd_status],61h	;hold selection, use main_lp1, launch msg
f1_abort:
  ret
;--------------
  [section .data]
cmd_line: db 'fileset ',0

key_table1:
  db  0fh,0,1bh,0		;ctrl-o = escape
  db  0
  [section .text]

;--------------------------------------------------------
; f2 open file
;--------------------------------------------------------
f2_key:
  mov	edi,temp_buf
  mov	esi,f2process_cmd
  call	str_move		;move the operation string
  push	edi
  call	make_active_selection	;builds at smsg_txt
  pop	edi
  cmp	al,2			;check if dir
  ja	f2_10			;jmp if file
  jmp	dir_fwd

f2_10: 
  mov	esi,smsg_txt
  call	move_quoted		;move the file (target) string
;check if executable file
  mov	al,0
  stosb				;terminate string
  call	file_status_name	;ebx=filename
  or	eax,eax
  js	f2_20
  mov	bx,[ecx + stat_struc.st_mode]
  test	bx,100q
  mov	eax,smsg_txt		;preload executable
  jnz	f2_20			;jmp if executable
;  test	bx,4000q		;check if directory
;  jz	f2_15			;jmp if not directory
;  jmp	dir_fwd			;jmp if directory
;f2_15:
;call "opener" to handle this file
  mov	eax,temp_buf
f2_20:
  mov	ebx,f3_key_table
  call	launch

  call	cursor_to_end
  mov	byte [cmd_status],61h	;hold selection, use main_lp1
f2_abort:
  ret
;-----------
f2process_cmd db "/usr/bin/opener ",0
;--------------------------------------------------------
; f3 view file
;--------------------------------------------------------
f3_key:
  call	make_active_selection	;builds at smsg_txt
  or	al,al
  jz	f3_abort		;exit if error or null file
  cmp	al,1			;is this a dir
  je	f3_abort		;exit if directory
  mov	esi,f3process_cmd
  mov	edi,temp_buf
  call	str_move
  mov	esi,smsg_txt
  call	move_quoted

  mov	eax,temp_buf
  mov	ebx,f3_key_table
  call	launch
  call	cursor_to_end
  mov	byte [cmd_status],62h	;hold selection, use main_lp2
f3_abort:
  ret
;No keys are watched.
;
f3_key_table:
  db  0
  db  0
  db  0		;

f3process_cmd db "/usr/bin/viewer ",0

;--------------------------------------------------------
; f4 edit file
;--------------------------------------------------------
f4_key:
  call	make_active_selection	;builds at smsg_txt
  or	al,al
  jz	f4_abort		;exit if error or null file
  cmp	al,1			;is this a dir
  je	f4_abort		;exit if directory
  mov	edi,temp_buf
  mov	esi,[edit_cmd_ptr]
  call	str_move
  mov	esi,smsg_txt
  call	move_quoted

  mov	eax,temp_buf
  mov	ebx,f3_key_table
  call	launch
f4_abort:
  mov	byte [cmd_status],62h	;hold selection, use main_lp2
  ret
;---------------
  [section .data]
edit_cmd_ptr: dd	editor
editor:	db 'asmedit ',0
 db 0,0,0,0,0,0,0		;filler to expand name
  [section .text]
;--------------------------------------------------------
; copy file - f5
;--------------------------------------------------------
f5_key:
;display 'copy ->' message
  call	display_status_line	;insure from: file displayed
  mov	ecx,f5_msg1
  mov	eax,[status_line_color]
  mov	bh,[status_line_row]
  mov	bl,1			;column
  call	crt_color_at
;display 'to ->' message
  mov	ecx,f5_msg2
  mov	eax,[status_line_color]
  mov	bh,[terminal_line_row]
  mov	bl,1
  call	crt_color_at
;mov shell command to temp_buf, and use "to" portion for get_string
  mov	edi,temp_buf
  mov	esi,cp_header
  call	str_move		;move 'cp -f   '
;get current selection
  push	edi
  call	make_active_selection
  pop	edi
  or	al,al
  jz	f5_abort		;exit if bad path
  cmp	al,2
  ja	f5_10			;jmp if file
  mov	al,'r'
  stosb
f5_10:
  mov	al,' '
  stosb
  mov	esi,smsg_txt
  call	move_quoted
  mov	al,' '
  stosb
  mov	[buf_ptr],edi		;save file pointer  
; get dest ptr (non active window)
  call	make_inactive_path
  mov	edi,[buf_ptr]
  mov	esi,smsg_txt
  call	str_move		;don't quote this one
;replace file at end of inactive selection with file from copy from->
  push	edi
  mov	esi,[buf_ptr]
f5_lp1:
  dec	esi			;scan back for '/'
  cmp	byte [esi],'/'
  jne	f5_lp1
  inc	esi			;point at copy from-> filename
;
  pop	edi

f5_lp3:
  lodsb
  cmp	al,27h			;is this the ending quote
  je	f5_lp3_end
  stosb
  jmp	short f5_lp3
f5_lp3_end:
  mov	[edi],byte 0		;terminate the string

;setup for string entry, we have filename to highlight
  mov	byte [column],7

  mov	eax,edi			;get string end
  sub	eax,[buf_ptr]		;compute cursor column
  add	al,7			;o_msg_len	;6 ;adjust for term button at front
  mov	byte [cursor_col],al	;save cursor position

  mov	al,[term_row]
  mov	[row],al

  mov	al,[crt_columns]
  sub	al,7			;smsg_len 6
  mov	[swin_size],al

  mov	ebp,get_str_tbl
  call	get_string		;get user inputs
;  cmp	byte [kbuf],0dh		;ok to do copy?
;  je	f5_launch		;jmp if ok to copy
  cmp	byte [kbuf],0ah
  jne	f5_abort		;exit if not <enter> key
f5_launch:
  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch_alt

;build success/fail message
  mov	esi,copy_success_msg
  mov	bl,3			;status_line_color]
  cmp	al,0
  je	cpy_msg
  mov	bl,5			;error_color
  mov	esi,copy_fail_msg
cpy_msg:
  mov	[smsg_color_code],bl
  mov	edi,smsg_txt
  call	str_move			;move message
  mov	byte [cmd_status],61h	;prebuild status,keep selector position, lp1
f5_abort:
  ret

;---------
  [section .data]

f5_msg1	db 'copy -> ',0
to_msg_len  equ	6
f5_msg2 db 'to -> ',0
copy_success_msg db 'copy completed',0
copy_fail_msg	db  'copy failed',0
cp_header	db	'cp -f',0

get_str_tbl:
buf_ptr:	dd	0
max_in:		dd	300
color_p:	dd	status_line_color
row		db	0
column		db	0
str_flg		db	0	;no lf in string
cursor_col	db	0
swin_size	dd	0

  [section .text]
;--------------------------------------------------------
; f6 - mv 
;--------------------------------------------------------
f6_key:
;display 'move ->' message
  call	display_status_line	;insure from: file displayed
  mov	ecx,f6_msg1
  mov	eax,[status_line_color]
  mov	bh,[status_line_row]
  mov	bl,1			;column
  call	crt_color_at
;display 'to ->' message
  mov	ecx,f6_msg2
  mov	eax,[status_line_color]
  mov	bh,[terminal_line_row]
  mov	bl,1
  call	crt_color_at
;mov shell command to temp_buf, and use "to" portion for get_string
  mov	edi,temp_buf
  mov	esi,mv_header
  call	str_move		;move 'cp -f   '
;get current selection
  push	edi
  call	make_active_selection
  pop	edi
  or	al,al
  jz	f6_abort		;exit if bad path
;move "from" file name
  mov	esi,smsg_txt
  call	move_quoted
  mov	al,' '
  stosb
  mov	[buf_ptr],edi		;save file pointer  
; get dest ptr (non active window)
  call	make_inactive_path
  mov	edi,[buf_ptr]
  mov	esi,smsg_txt
  call	str_move		;don't quote this one
;replace file at end of inactive selection with file from copy from->
  push	edi
  mov	esi,[buf_ptr]
f6_lp1:
  dec	esi			;scan back for '/'
  cmp	byte [esi],'/'
  jne	f6_lp1
  inc	esi			;point at copy from-> filename
;
  pop	edi

f6_lp3:
  lodsb
  cmp	al,27h			;is this the ending quote
  je	f6_lp3_end
  stosb
  jmp	short f6_lp3
f6_lp3_end:
  mov	[edi],byte 0		;terminate the string

;setup for string entry, we have filename to highlight
  mov	byte [column],7

  mov	eax,edi			;get string end
  sub	eax,[buf_ptr]		;compute cursor column
  add	al,7			;o_msg_len	;6 ;adjust for term button at front
  mov	byte [cursor_col],al	;save cursor position

  mov	al,[term_row]
  mov	[row],al

  mov	al,[crt_columns]
  sub	al,7			;smsg_len 6
  mov	[swin_size],al

  mov	ebp,get_str_tbl
  call	get_string		;get user inputs
  cmp	byte [kbuf],0dh		;ok to do copy?
  je	f6_launch		;jmp if ok to copy
  cmp	byte [kbuf],0ah
  jne	f6_abort		;exit if not <enter> key
f6_launch:
  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch_alt

;build success/fail message
  mov	esi,move_success_msg
  mov	bl,3			;status_line_color]
  cmp	al,0
  je	mov_msg
  mov	bl,5			;error_color
  mov	esi,move_fail_msg
mov_msg:
  mov	[smsg_color_code],bl
  mov	edi,smsg_txt
  call	str_move			;move message
  mov	byte [cmd_status],61h	;prebuild status,keep selector position, lp1
f6_abort:
  ret

;---------
  [section .data]

f6_msg1	db 'copy -> ',0
f6_msg2 db 'to -> ',0
move_success_msg db 'move completed',0
move_fail_msg	db  'move failed',0

mv_header	db	'mv ',0

  [section .text]
;--------------------------------------------------------
; make directory 
;--------------------------------------------------------
f7_key:
  mov	ebx,status_term_colors	;list of colors
  mov	ch,[status_line_row]
  mov	cl,1			;column 1
  mov	dl,[crt_columns]	;display all columns
  mov	esi,mkdir_msg1
  xor	edi,edi			;set sroll to 0
  call	crt_line
;fill temp buffer with blanks
  mov	al,' '
  mov	edi,temp_buf
  xor	ecx,ecx
  mov	cl,[crt_columns]
  rep	stosb

;  call	crt_line

  mov	dword [buf_ptr],temp_buf	
  mov	byte [column],1
  mov	byte [cursor_col],1	;save cursor position
  mov	al,[term_row]
  mov	[row],al
  mov	al,[crt_columns]
  sub	al,7
  mov	[swin_size],al
  mov	ebp,get_str_tbl
  call	get_string		;get user inputs
  cmp	byte [kbuf],0ah		;ok to do copy?
  jne	f7_abort		;exit if not <enter> key
;create directory, ah=cursor column beyond last valid entry
  mov	ebx,temp_buf		;get buffer ptr
  xor	ecx,ecx
  mov	cl,ah			;get column in -bl-
  dec	ecx
  add	ecx,ebx			;point at end of string
  mov	byte [ecx],0		;terminate directory name
  call	dir_create
  mov	byte [cmd_status],21h	;hold selection, re-read directories
f7_abort:
  ret


mkdir_msg1:
  db  3,'Enter name of directory to create below ',0ah

;--------------------------------------------------------
; delete file/dir - f8
;--------------------------------------------------------
f8_key:
  call	make_active_selection	;builds at smsg_txt
  or	al,al
  jz	f8_abort		;exit if error or null file
  mov	esi,f8_header
  mov	edi,temp_buf
  call	str_move
;if sym_link fix path at smsg_txt
  cmp	[type_code],byte 6	;sym_link?
  jne	f8_10			;jmp if not sym_link
  mov	esi,smsg_txt
f8_lp:
  lodsb
  or	al,al
  jnz	f8_lp
  mov	[esi-1],byte '/'	;restore '/'
f8_10:
  mov	esi,smsg_txt
  call	move_quoted

  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch_alt
;build success/fail message
  mov	esi,delete_success_msg
  mov	bl,3			;status_line_color]
  cmp	al,0
  je	del_msg
  mov	bl,5			;error_color
  mov	esi,delete_fail_msg
del_msg:
  mov	[smsg_color_code],bl
  mov	edi,smsg_txt
  call	str_move			;move message
f8_abort:
  mov	byte [cmd_status],61h	;prebuild status,keep selector position, lp1
  ret

;-----------
f8_header:  db  'rm -fr ',0
delete_fail_msg: db 'delete failed',0
delete_success_msg: db 'file/directory deleted',0

;-------------------------------------------------------
; F9 - expand (upak)  archive into current dir 
;-------------------------------------------------------
f9_key:
  call	make_active_selection	;builds at smsg_txt
  cmp	al,2
  jbe	f9_abort		;exit if dir,null file, or error
  mov	esi,upak_cmd
  mov	edi,temp_buf
  call	str_move
  mov	esi,smsg_txt
  call	move_quoted

  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch
;build success/fail message
  mov	esi,f9_success_msg
  mov	bl,3			;status_line_color]
  cmp	al,0
  je	f9_msg
  mov	bl,5			;error_color
  mov	esi,f9_fail_msg
f9_msg:
  mov	[smsg_color_code],bl
  mov	edi,smsg_txt
  call	str_move			;move message
f9_abort:
  mov	byte [cmd_status],61h	;prebuild status,keep selector position, lp1
  ret

;----------
upak_cmd:  db '/usr/share/asmmgr/upak ',0
f9_fail_msg: db 'operation failed',0
f9_success_msg: db 'operation succeeded',0
;-------------------------------------------------------
; F10 - pak (tar.gz)  directory into file and place in current dir 
;-------------------------------------------------------
f10_key:
  call	make_active_selection	;builds at smsg_txt
  cmp	al,2
  jbe	f10_abort		;exit if dir,null file, or error
  mov	esi,pak_cmd
  mov	edi,temp_buf
  call	str_move
  mov	esi,smsg_txt
  call	move_quoted

  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch
;build success/fail message
  mov	esi,f9_success_msg
  mov	bl,3			;status_line_color]
  cmp	al,0
  je	f9_msg
  mov	bl,5			;error_color
  mov	esi,f9_fail_msg
f10_msg:
  mov	[smsg_color_code],bl
  mov	edi,smsg_txt
  call	str_move			;move message
f10_abort:
  mov	byte [cmd_status],61h	;prebuild status,keep selector position, lp1
  ret
;------------
pak_cmd:  db '/usr/share/asmmgr/pak ',0
;-------------------------------------------------------
; F11 - compare two ascii files or directories
;-------------------------------------------------------
; call script "compar" which calls "xxdiff"
f11_key:
  call	make_active_selection	;builds at smsg_txt
  cmp	al,0
  jbe	f11_abort		;exit if error
  mov	esi,compare_cmd
  mov	edi,temp_buf+250
  call	str_move
  mov	esi,smsg_txt
  call	move_quoted

  mov	al,' '
  stosb				;put space between files

  push	edi
  call	display_inactive_window
  xor	byte [active_window],3	;fool set_win_struc_ptr
  call	make_active_selection
  xor	byte [active_window],3	;restore correct ptr
  pop	edi
  mov	esi,smsg_txt
  call	move_quoted

  mov	eax,temp_buf+250
  mov	ebx,key_table1
  call	launch
f11_abort:
  mov	byte [cmd_status],62h	;hold selection, use main_lp2
  ret
;----------
compare_cmd:  db '/usr/share/asmmgr/compar ',0
;-------------------------------------------------------
; F12 - print file
;-------------------------------------------------------
f12_key:
  call	make_active_selection	;builds at smsg_txt
  cmp	al,2
  jbe	f12_abort		;exit if dir,null file, or error
  mov	esi,print_cmd
  mov	edi,temp_buf
  call	str_move
  mov	esi,smsg_txt
  call	move_quoted

  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch
  call	cursor_to_end
f12_abort:
  mov	byte [cmd_status],62h	;hold selection, use main_lp2
  ret
;----------
print_cmd:  db '/usr/share/asmmgr/print ',0

;-----------------------------------------
; ctrl-o alt-t terminal
;-----------------------------------------

term_key:		;open terminal
  mov	ecx,crt_strings
  call	stdout_str
  xor	eax,eax		;interactive shell
  mov	ebx,key_table2
  call	launch
  call	mouse_enable
  mov	byte [cmd_status],61h  ;hold selection, reread dirs
  ret

crt_strings: db 0fh	;normal char set
	db 1bh,'[0m',0	;normal attribute
key_table2:
  db 0fh,0,'exit',0ah,0
  db 0
;-----------------------------------------
; > string on terminal line
;-----------------------------------------
term_process:		;called if string entered
  mov	esi,term_data
  mov	edi,temp_buf
tp_1:
  lodsb
  cmp	al,'%'
  jne	tp_2

  push	esi
  push	edi
  call	make_active_selection	;builds at smsg_txt
  pop	edi
  mov	esi,smsg_txt
  call	move_quoted
  pop	esi
  inc	esi			;move past "f"
  lodsb				;get space or zero after "f"
tp_2:
  stosb
  or	al,al
  jnz	tp_1

;execute shell command
  mov	eax,temp_buf		;get command for shell
  mov	ebx,key_table3
  call	launch
  call	clear_term_line
  mov	byte [cmd_status],61h	;hold selection, re-read directories
  ret

key_table3:
  db 0fh,0,03,0
  db 0

;--------------
clear_term_line:
  mov	edi,term_data
  mov	ecx,120
  mov	al,0
  rep	stosb
  ret
;------------------------------------------------------
;-------------------------------------------------------
; alt-f find
;-------------------------------------------------------
find_key:
  mov	esi,find_command
  mov	edi,temp_buf
  call	str_move
  xor	eax,eax
  stosb				;put 0,0 at end
  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch			;call search script


find_exit:
  call	cursor_to_end
  mov	byte [cmd_status],62h		;hold selection, use  main_lp2
  ret

key_table4:
  db  1bh,0,'q',0		;esc = 'q'
  db  0fh,0,'q',0		;ctrl-o = escape
  db 0

find_command:
 db 'asmfind',0
;---------------------
;watch_input:
;  cmp	word [kbuf],001bh;check for escape
;  jne	wi_exit		;exit if not escape
;  mov	byte [kbuf],'q'	;request exit
;wi_exit:
;  xor	eax,eax		;set return code, normal
;  ret
;----------
find_cmd:  db '/usr/share/asmmgr/find ',0
find_show_cmd: db 'less -P"Viewer Usage  (h)help q(exit)$" /tmp/find.tmp',0
fflag: db "_^_~",0
;-----------------------------------
;input: esi = ptr to sting buffer
;       edi = storage point
;output: put space at end
;       edi points at next store char
move_and_quote:
  mov	al,27h			;quote char
  stosb
maq_lp1:
  lodsb
  stosb
  cmp	al,' '
  je	maq_done1		;exit if end of string
  cmp	al,0
  jne	maq_lp1			;loop till all data moved
maq_done1:
  dec	edi
  mov	al,27h			;get quote char
  stosb
  mov	al,' '
  stosb
  ret	
;-------------------------------------------------------
; help, alt-h
;-------------------------------------------------------
help_key:
  mov	eax,help_file
  mov	ebx,f3_key_table
  call	launch
  jmp	dk_exit
help_file: db '/usr/bin/asmview /usr/share/doc/asmref/progs/asmmgr.txt',0
;-------------------------------------------------------

quit_key:
  mov	byte [cmd_status],80h	;set exit state
  ret
;--------------
setup_key:
  mov	esi,alt_s_ptr
  call	do_key
  call	get_config_tbl
  ret
;  jmp	do_key
;-------------------------------------------------------
; alt-1
;-------------------------------------------------------
alt_1_key:
  mov	esi,alt_1_ptr
  jmp	do_key
alt_2_key:
  call	tools_popup
  jmp	dk_exit
;  mov	esi,alt_2_ptr
;  jmp	do_key
alt_3_key:
  mov	esi,alt_3_ptr
  jmp	do_key
alt_4_key:
  mov	esi,alt_4_ptr
  jmp	do_key
alt_5_key:
  mov	esi,alt_5_ptr
  jmp	do_key
alt_6_key:
  mov	esi,alt_6_ptr
  jmp	do_key
alt_7_key:
  mov	esi,alt_7_ptr
  jmp	do_key
alt_8_key:
  mov	esi,alt_8_ptr
  jmp	do_key
alt_9_key:
  mov	esi,alt_9_ptr
  jmp	do_key
alt_0_key:
  mov	esi,alt_0_ptr
  jmp	do_key
; entry point for mouse processing -------------
; input: esi = ptr to pointers for top button line
do_key:

  call	lookup_process
  mov	esi,[esi]		;get string ptr
;  * esi = ptr to program string
;  * -     this is normal shell command string
  mov	edi,temp_buf
  cmp	word [esi],'pw'		;is this a bookmark
  je	dk_exit			;jmp if bookmark

dk_1a:
;  mov	al,'/'			;this is a script or program
;  stosb				;put '/' at front of path
dk_lp1:
  lodsb
  stosb
  cmp	al,0ah
  jbe	dk_ready
  cmp	al,'%'
  jne	dk_lp1			;loop if not insert request
  dec	edi			;move back to '%'

  push	edi
  call	make_active_selection
  pop	edi
  mov	esi,smsg_txt		;;
  call	move_quoted
dk_ready:
;  xor	eax,eax
;  stosd				;terminate buffer

  mov	eax,temp_buf
  mov	ebx,key_table1
  call	launch
  mov	byte [cmd_status],21h	;force restart
dk_exit:
  ret
;-----------------------------------------------------------
; launch - start shell using sys_wrap
;  inputs:  eax = shell string, or zero for interactive shell
;           ebx = key table
;                 format:  key-string1,0,feed-keys,0
;                          key-string2,0,feed-keys,0
;                          0 (end of table)
;                 if the feed-key is a ctrl-c (03h) then it
;                 is not feed to child, instead the child is
;                 aborted.  This allows us to abort some
;                 programs with ctrl-o by giving it a feed-key
;                 of 03h.
;  output:  none
;
launch_alt:
  mov	[no_alt_flag],byte 1
launch:
  mov	[shell_cmd_ptr],eax
  mov	[shell_keys_ptr],ebx
  test	[no_alt_flag],byte 1
  jnz	launch_20		;jmp if no alt screen
  call	normal_screen		;switch to shell window

;look up shell
launch_20:
  mov	edx,lib_buf+600		;shell storage point
  call	env_shell
  mov	esi,[shell_cmd_ptr]     ;is this an interactive shell?
  or	esi,esi
  jz	launch_50		;jmp if interractive shell

;append command to shell
  inc	edi			;move past zero at end
  mov	ax,'-c'
  stosw
  mov	al,0
  stosb
  call	str_move		;move command to "shell -c" string
launch_50:
  xor	eax,eax
  stosd				;terminate shell string
  mov	eax,lib_buf+600
  mov	ebx,shell_feed_watch
  xor	ecx,ecx			;no output capture
  call	sys_wrap
  push	eax			;save status to restore at end
;build success/fail message
  push	eax			;save status
  mov	bl,al
  mov	edi,shell_msg2
  call	byte2hexstr
  pop	eax
  mov	bl,3			;status_line_color]
  or	al,al
  jns	cpy_smsg
  mov	bl,5			;error_color
cpy_smsg:
  mov	esi,shell_msg1
  mov	[smsg_color_code],bl
  mov	edi,smsg_txt
  call	str_move			;move message
;  or	byte [cmd_status],40h	;prebuild status,keep selector position, lp1

  call	flush_keys

  call	adjust_cursor

  call	alt_screen
  call	mouse_enable

  test	[no_alt_flag],byte 1
  jnz	skip_clear
  mov	eax,30003734h
  call	crt_clear
skip_clear:
;
; It appears if the cursor is hidden in the normal window it
; also hides the cursor in the alt window.  If we restore the
; normal window cursor, it does not restore the alt window cursor.
; This problem occured with project button using konsole.
  
  call	cursor_unhide
  call	read_window_size
  mov	byte [window_resize_flag],1

  call	flush_keys
  pop	eax
  mov	[no_alt_flag],byte 0
  ret

;------------
  [section .data]
no_alt_flag	db	0
cursor_save times 12 db 0
erase_left db 1bh,'[1K',0
shell_cmd_ptr dd	0	;shell command string or zero if interactive
shell_keys_ptr dd	0	;ptr to table of watch keya
shell_msg1:    db 'Returned status = '
shell_msg2:    db 0,0,0,0,0
;ignore_error_flag:  db	0	;0=error not expected 1=ignore error (expected)
  [section .text]

;--------------------------------------------------------------
adjust_cursor:
;remove current line from users terminal.
  mov	ecx,erase_left
  call	stdout_str
  mov	edi,cursor_save
  call	save_cursor_at
;check if cursor at end of line
  mov	edi,cursor_save+3
  cmp	[edi],byte ';'
  je	cursor_adjust1
  inc	edi
  cmp	[edi],byte ';'
  jne	cursor_adjust_exit	;exit if unknown format
cursor_adjust1:
  inc	edi
  mov	byte [edi],'1'
  inc	edi
  mov	byte [edi],'H'
  inc	edi
  mov	byte [edi],0

  mov	esi,cursor_save
  call	restore_cursor_from
cursor_adjust_exit:
  ret
;------------------------------------------------------------------
;the following kludge removes any pending keyboard or mouse data.
;It solves a problem with some x programs.  They leave stuff in
;the stdin pipe.  The AsmLibx programs seem to have this problem.

;The problem is probablly a sys_wrap pipe problem.  The last exit
;key click is still in the pipe and not cleared out.  

  extern raw_set1,raw_unset1
flush_keys:
  mov	ecx,18
flush_l:
  push	ecx
  call	raw_set1
  call	key_flush
  call	raw_unset1
  mov	eax, 10
  call	delay
  pop	ecx
  loop	flush_l
  ret
;-------------------------------------------------------
shell_feed_watch:
; input: ecx=buffer edx=read length
  mov	al,[ecx]		;get first byte of key
  or	al,al			;is this ^space
;  jz	fw_out			; jmp if ^space
;  cmp	al,03			;is this a ctrl-c
  jne	fw_decode		;jmp if not abort key
fw_out:
  mov	edx,-1
  jmp	fw_exit
fw_decode:
  mov	esi,[shell_keys_ptr]   	;get key control table
  cld
fw_decode_loop:
  mov	[shell_keys_ptr],esi
  mov	edi,ecx 		;edi=key data from sys_wrap
  call	str_compare		;compare two strings
  je	fw_match		;jmp if strings match
;strings do not match
  mov	esi,[shell_keys_ptr]
  call	str_end			;move to zero byte at end of match str
  inc	esi
  call	str_end			;move to zero byte at end of replace str
  inc	esi
  cmp	byte [esi],0		;at end of table?
  jne	fw_decode_loop		;loop if more table entries
;no match for this key press, return origional key
  jmp	fw_exit
;key found, esi=ptr to zero at end of table string
fw_match:
  inc	esi			;move to replacement string
  mov	edi,ecx			;get data buffer ptr
  mov	edx,-1			;set length to -1
key_stuff_loop:
  lodsb
  stosb
  inc	edx
  or	al,al
  jnz	key_stuff_loop
fw_exit:			;not shell, not ctrl-c,
  ret
;--------------------------------------------------------------------------
extern norm_cursor
extern dword_to_l_ascii

cursor_to_end:
  xor	eax,eax
  mov	al,[crt_rows]		;last row
  mov	edi,cursor_row_stuff
  mov	esi,2
  call	dword_to_l_ascii

  mov	esi,cursor_string
  mov	edi,norm_cursor
  call	str_move
  ret
;------------------------
  [section .data]
cursor_string: db 1bh,'['
cursor_row_stuff:
  db '00;1H',0
  [section .text]
;---------------------------------------------
; sets ebp to window database
; input: [active_window]
; output: ebp = ptr to win_struc
;         esi = ptr to win_path inside win_struc
;
set_win_struc_ptr:
  mov	ebp,left_window
  cmp	byte [active_window],1
  je	swsp_exit
  mov	ebp,right_window
swsp_exit:
  lea	esi,[ebp+win_struc.win_path]
  ret
;--------------------------------------------------------
;make_inactive_path - construct path for inactive selection
; inputs: [active_window]
; output: smsg_txt has path of current selection, if this
;              is a symlink, then smsg_txt has target instead.
;         ebp = win_struc ptr
;         [type_code] and al
;              0 if null dir or can't access
;              1 normal dir
;              2 symlink dir
;              3 file
;              6 symlink file
;
make_inactive_path:
  mov	ebp,left_window
  cmp	byte [active_window],1
  jne	mis_10			;jmp if left window inactive
  mov	ebp,right_window
mis_10:
  mov	edi,smsg_txt		;temp buffer to construct path
  lea	esi,[ebp+win_struc.win_path]
  call	str_move
  cmp	byte [edi-1],'/'	;if at root we
  je	mis_20			; we don't need to add a '/'
  mov	al,'/'
  stosb
mis_20:
  xor	eax,eax
  stosb				;put  zero at end
  ret


;--------------------------------------------------------
;make_active_selection - construct path for current selection
; inputs: [active_window]
; output: smsg_txt has path of current selection, if this
;              is a symlink, then smsg_txt has target instead.
;         ebp = win_struc ptr
;         [type_code] and al
;              0 if null dir or can't access
;              1 normal dir
;              2 symlink dir
;              3 file
;              6 symlink file
;
make_active_selection:
  call	set_win_struc_ptr	;returns ebp=win_struc, esi=sel
mas_entry:
  mov	edi,smsg_txt		;temp buffer to construct path
  lea	esi,[ebp+win_struc.win_path]
  cmp	word [esi],02fh		;are we at root now?
  je	mp_10			;if at root,then skip storing '/'
  call	str_move
mp_10:
  mov	esi,[ebp+win_struc.selected_ptr]
  mov	esi,[esi]		;get index at selection (dtype struc)
  or	esi,esi			;check if no files in this dir
  jz	mp_exit1		;jmp if empty directory
  lea	ebx,[esi+dtype.d_type]	;get ptr to type code
  mov	al,[ebx]		;get type
  mov	[type_code],al		;save type
  lea	esi,[esi+dtype.d_nam]	;get ptr to name string
  mov	al,'/'
  stosb				;put '/' after path base
  call	str_move		;move selection name
  cmp	byte [ebx],2		;is this a symlink
  jne	mp_55			;go check access
;we have found a symlink, check type, read target into lib_buf
  mov	eax,85			;read link sys-call code
  mov	ebx,smsg_txt		;path
  mov	ecx,project_path
  mov	edx,600			;lib_buf_size
  int	80h			;call kernel
  or	eax,eax
  js	mp_exit1		;ignore if error
  add	eax,project_path		;compuae end of data
  mov	byte [eax],0		;put zero at end of data
; check if symlink points to dir
  mov	ebx,project_path
  call	dir_status		;results go to lib_buf [ecx]
  js	mp_exit1		;if error then exit
  mov	eax,0f000h
  and	eax,[ecx+stat_struc.st_mode]
  cmp	ah,40h
  je	mp_50			;jmp if symlink dir
;status says we have a directory, but some /dev entires
;give this status if they point to /proc entry. possibly
;other cases, try nlink field?
;  cmp	[ecx+stat_struc.st_nlink],word 2
;  jne	mp_50			;assume directory
mp_49:
  mov	[type_code],byte 6	;set symlink file  
mp_50:
  mov	esi,active_path		;move symlink so next access check
  mov	edi,smsg_txt		;  works ok.
  call	str_move		;move symlink path to smsg_txt
;check access to file/dir/symlink
mp_55:
  mov	ebx,smsg_txt
  mov	ecx,4			;R_OK is it ok to read
  mov	eax,33			;access kernel call
  int	80h 			;can we read this dir?
  or	eax,eax
  js	mp_exit1		;exit if error
;check if we can enter directory
  cmp	[type_code],byte 1	;is this a directory entry
  jne	mp_exit			;jmp if not dir
;save current directory
  call	dir_current
  mov	esi,ebx
  mov	edi,active_path
  call	str_move
;check if we can switch to new dir
  mov	ebx,smsg_txt
  call	dir_change
;restore origional directory
  push	eax
  mov	ebx,active_path
  call	dir_change
  pop	eax			;restore results of dir change
  or	eax,eax
  jns	mp_exit			;exit if access ok
;
mp_exit1:		;null dir or can't access
  xor	eax,eax
  jmp	short mp_exit2
mp_exit:
  mov	al,[type_code]
mp_exit2:
  ret
;---------------
  [section .data]
type_code:	db	0
  [section .text]

;--------------------------------------------------------
; move_quoted - move a string and add quotes
;  inputs;  [esi] = string to move and quote
;           edi = destination
;  output:  edi points to zero at end of quoted string
;
move_quoted:
  mov	al,27h
  stosb
  call	str_move
  mov	al,27h
  stosb
  xor	eax,eax
  mov	byte [edi],0  
  ret

;------------------------------------
lookup_process:
;check if this is bookmark
  mov	eax,esi
  sub	eax,button_process_ptrs	;find line index
  shr	eax,2			;convert to 1 base
  mov	ah,6			;setup to multiply by size of label entry
  mul	ah 			;set eax to index for label line
  inc	eax			;move past space code to first char of label
  add	eax,button_line1	;look up label for this line
  cmp	byte [eax],1
  jbe	dk_done			;jmp if beyond end of button table
  cmp	byte [eax],'/'		;is this a bookmark?
  jne	dk_process		;jmp if not bookmark
  cmp	byte [kbuf],-1		;is this a mouse click
  je	dk_mouse		;jmp if mouse click

  jmp	short dk_bookmark	;jmp if key press on bookmark
dk_mouse:
  cmp	byte [kbuf+1],0
  jz	dk_bookmark		;jmp if =goto bookmark= request
  call	set_bookmark
  jmp	short dk_done
;process bookmark
dk_bookmark:
  push	esi
  mov	ebx,[esi]
  xor	ecx,ecx
  call	dir_access
  or	eax,eax
  jz	dk_access_ok
  pop	esi
  jmp	short dk_done

dk_access_ok:
  call	set_win_struc_ptr	;set ebp to active window data
  pop	esi
  lea	edi,[ebp+win_struc.win_path]
  mov	esi,[esi]		;get string ptr
  call	str_move
  mov	byte [symlink_flag],0	;disable symlink history
dk_done:
  mov	esi,dummy_ptr
  mov	byte [cmd_status],1
dk_process:
  ret
;
; if bookmark then the following dummy process is returned
dummy_ptr: dd	dummy_action
dummy_action: db 'pwd',0
;---------------------------------------------
; modify /usr/share/asmmgr/top_buttons.tbl to add current
; directory to button x
;
set_bookmark:
  sub	esi,button_process_ptrs-1	;compute button# * 4
  mov	[button_number],esi
;store pointer to current path
  call	set_win_struc_ptr		;set ebp to active window data
  lea	edi,[ebp+win_struc.win_path]	;get ptr to active directory
  mov	[ptr_to_current_path],edi
;read file
  mov	ebp,top_buttons
  mov	ecx,[bss_base]
  mov	edi,ecx				;set current allocaton to bss_base
  mov	al,2
  call	file_read_grow
;  mov	ebx,top_buttons
;  mov	edx,fbuf_size	;max read size
;  mov	ecx,fbuf  	;buffer
;  call	file_simple_read
  or	eax,eax
  js	sb_abort	;jmp if read error
  add	eax,[bss_base]
  mov	[top_buttons_file_end],eax
  mov	byte [eax],0	;put zero at end of file
;expand buffer to allow file expansion
  mov	ebx,eax		;get end of file
  add	ebx,20
  mov	eax,45		;kernel brk (expand memory)
  int	byte 80h

;setup to extract data from file
; format of entry:  "name" "cmd string" eol
  mov	ecx,[button_number]	;get button# zero based
  mov	esi,[bss_base]
sb_lp1:
  call	find_quote
  jc	sb_abort
  dec	ecx			;dec button# * 4
  jnz	sb_lp1			;loop till start of button name
  call	change_button_name
  call	find_quote
  jc	sb_abort
  call	change_button_bookmark
;write file to /usr/share/asmmgr/top_buttons.tbl
  mov	ebx,top_buttons		;file path
  mov	eax,[bss_base]		;buffer start
  mov	ecx,[top_buttons_file_end] ;compute file size
  sub	ecx,[bss_base] 		;compute file size
  mov	edx,666q		;normal attributes
  mov	esi,08h			;use attributes in edx
  call	file_write_close
  call	get_top_buttons_tbl
sb_abort:
  ret

;----------------
  [section .data]
button_number		dd 0	;button number * 4
top_buttons_file_end	dd 0
ptr_to_current_path	dd 0
  [section .text]
;-----------------------------------------
; use end of path for button name
;  inputs:  esi=ptr to current name in (fbuf), length = 5 bytes
;  output:  fbuf - has new name inserted
;           esi=ptr past quote at end of name
;           [ptr_to_current_path] = current path (new bookmark target)
change_button_name:
  mov	edi,esi		;save esi as stuff ptr
  mov	esi,[ptr_to_current_path]
  call	str_end			;find end of string
cbn_lp:
  cmp	byte [esi],'/'
  je	cbn_move
  dec	esi
  jmp	short cbn_lp
cbn_move:
  mov	ecx,5			;move 5 bytes
cbn_lp2:
  lodsb
  or	al,al
  jz	cbn_lp3
  stosb
  dec	ecx
  jnz	cbn_lp2			;loop till 5 bytes moved
cbn_lp3:
  jecxz	cbn_done
  mov	al,' '
  stosb
  dec	ecx
  jmp	cbn_lp3  
cbn_done:
  inc	edi		;move past quote
  mov	esi,edi
  ret
;-----------------------------------------
; cut current bookmark from file and insert new one.
; adjust file size, and rewrite it.
;  inputs:  esi=ptr to old bookmark path
;           [win_struc.win_path] = ptr to current path
;           [ptr_to_current_path] = current path (new bookmark target)
;  ouptut:  fbuf - contains new path data and is ready to write
;           [top_buttons_file_end] updated
;
change_button_bookmark:
  push	esi			;save ptr to current button path
  mov	edi,esi
;scan for length of current path
  xor	ecx,ecx
cbb_lp:
  lodsb
  cmp	al,'"'
  je	cbb_10
  inc	ecx
  jmp	short cbb_lp
;setup to delete old path
cbb_10:
;  dec	ecx			;;;
  mov	eax,ecx			;delete area size 
  mov	ebp,[top_buttons_file_end]
;  dec	ebp			;;;
; eax=old path size  edi=ptr to delete block top  ebp=end of file ptr
  call	blk_del_bytes		;remove old path
  mov	esi,[ptr_to_current_path]
  call	strlen1			;set ecx=string length
  mov	eax,ecx			;string length -> eax
;  mov	ebp,[top_buttons_file_end]
  pop	edi			;restore ptr to path insert point
; edi=insert point, ebp=file/blk end ptr  eax=insert length  esi=ptr to insert data
  call	blk_insert_bytes
  mov	[top_buttons_file_end],ebp
  ret
;----------------------------------------
; general Subroutines *******************
;----------------------------------------

;---------------------------------------------
; input: ebp = ptr to window parameters
; output: bh=lines in current page
;         ch=lines in next page
;        eax=0 if end of file found
;         bl=0 if current page full, else blank lines in page
;         cl=0 if next page full, else blank lines in page
page_fwd:
  xor	ebx,ebx
  mov	bl,[ebp+win_struc.rows]	;get total rows in this window
  mov	cl,bl
  mov	ch,0
  mov	esi,[ebp+win_struc.top_row_ptr]
  mov	bh,0			;row counter
pf_lp1:
  lodsd
  or	eax,eax			;end of ptrs
  jz	pf_exit
  inc	bh
  dec	bl
  jnz	pf_lp1			;loop back
;
; bh now has number of lines in current page, (win size)
;
pf_lp2:
  lodsd
  or	eax,eax
  jz	pf_exit
  inc	ch
  dec	cl
  jnz	pf_lp2
pf_exit:
  ret
  
;---------------------------------------------
; display_active_window
;  if no windows are active, display left window & set active
;
display_active_window:
  mov	al,[active_window]	;0=none 1=left 2=right
  cmp	al,2
  jne	daw_left
  call	display_right_window
  jmp	short daw_exit
daw_left:
  mov	byte [active_window],1	;set left window active
daw_display:
  call	display_left_window
daw_exit:
  ret
;---------------------------------------------
; display_inactive_window
;  if no windows are active display right window
display_inactive_window:
  mov	al,[active_window]	;0=none 1=left 2=right
  cmp	al,2
  je	diw_left
  call	display_right_window
  jmp	short diw_exit
diw_left:
  call	display_left_window
diw_exit:
  ret

;---------------------------------------------
; display_right_window
;
display_right_window:
  cmp	byte [left_win_status],1	;is left window active
  jne	drw_10				;jmp if left window not active
  call	save_left_window
drw_10:
  cmp	byte [right_win_status],2	;is right window swapped
  jne	drw_20				;jmp if right not swapped
drw_15:
  call	restore_right_window
drw_20:
  cmp	byte [right_win_status],0	;is right winddow uninitialized
  jnz	drw_30				;jmp if right window read previously
  call	open_right_window
  jnz	drw_90				;jmp if error opening window
drw_30:
  mov	ebx,active_win_colors
  cmp	byte [active_window],2		;check if right window active
  je	drw_40				;jmp if right window active
  mov	ebx,inactive_win_colors
drw_40:
  mov	ch,[top_right_row]
  mov	cl,[top_right_col]
  mov	dl,[right_columns]
  mov	dh,[right_rows]
  mov	ebp,[rtop_row_ptr]
  cmp	dword [ebp],0		;check for empty directory
  jne	drw_45			;jmp if files found
  mov	ebp,no_files_ptr
  xor	edi,edi
  jmp	short drw_50
drw_45:
;  mov	edi,-11			;set adjustment to 11
drw_50:
  call	crt_win_from_ptrs	;display window
drw_90:
  ret
;	
;---------------------------------------------
display_left_window:
  cmp	byte [right_win_status],1	;is right window active
  jne	dlw_10				;jmp if right window not active
  call	save_right_window
dlw_10:
  cmp	byte [left_win_status],2	;is left window swapped
  jne	dlw_20				;jmp if left not swapped
dlw_15:
  call	restore_left_window
dlw_20:
  cmp	byte [left_win_status],0	;is left winddow uninitialized
  jnz	dlw_30				;jmp if left window read previously
  call	open_left_window
  jnz	dlw_90				;jmp if error opening window
dlw_30:
  mov	ebx,active_win_colors
  cmp	byte [active_window],1		;check if left window active
  je	dlw_40				;jmp if left window active   
  mov	ebx,inactive_win_colors
dlw_40:
  mov	ch,[top_left_row]
  mov	cl,[top_left_col]
  mov	dl,[left_columns]
  mov	dh,[left_rows]
  mov	ebp,[ltop_row_ptr]
  cmp	dword [ebp],0		;check for empty directory
  jne	dlw_45			;jmp if files found
  mov	ebp,no_files_ptr
  xor	edi,edi
  jmp	short dlw_50
dlw_45:
;  mov	edi,-11			;set adjustment to -11
dlw_50:
  call	crt_win_from_ptrs	;display window
dlw_90:
  ret

;---------
no_files_ptr:
  dd	no_files_msg
  dd	0
no_files_msg: db 1," -- empty directory --",0ah
;---------------------------------------------
save_left_window:
  mov	ebx,left_fname		;file path
  mov	eax,[bss_base]	;buffer start
  mov	ecx,[eax+dir._allocation_end]
  sub	ecx,eax			;file length to ecx
  mov	edx,666q		;normal attributes
  mov	esi,08h			;use attributes in edx
  call	file_write_close
  mov	byte [left_win_status],2 ;set swapped out
  ret
;------------
  [section .data]
left_fname: db '/tmp/left.'
left_stuff: db '0',0
  [section .text]
;------------	
;---------------------------------------------	
save_right_window:
  mov	ebx,right_fname
  mov	eax,[bss_base]	;was sort_pointers
  mov	ecx,[eax+dir._allocation_end]
  sub	ecx,eax          	;compute length of write
  mov	edx,666q		;normal attributes
  mov	esi,08h			;write to /tmp
  call	file_write_close
  mov	byte [right_win_status],2 ;set swapped out
  ret
;------------
  [section .data]
right_fname: db '/tmp/right.'
right_stuff: db '0',0
  [section .text]
;------------	
;---------------------------------------------
restore_left_window:
  mov	ebp,left_fname	
  mov	ecx,[bss_base]		;sort_pointers
  mov	edi,[ecx+dir._allocation_end]
  mov	al,1			;full path provided
  call	file_read_grow
  js	rlw_exit
  mov	byte [left_win_status],1
rlw_exit:
  ret
;---------------------------------------------	
restore_right_window:
  mov	ebp,right_fname	
  mov	ecx,[bss_base]
  mov	edi,[ecx+dir._allocation_end]
  mov	al,1			;full path provided
  call	file_read_grow
  js	rrw_exit
  mov	byte [right_win_status],1
rrw_exit:
  ret
;---------------------------------------------
;
open_left_window:
  mov	ebx,left_win_path
  call	open_window
  jnz	olw_exit			;exit if error
  mov	byte [left_win_status],1	;set in memory
  mov	ebp,left_window
 call	check_selector_bar
 xor	eax,eax				;signal success	
olw_exit:
  ret
;---------------------------------------------
open_right_window:
  mov	ebx,right_win_path
  call	open_window
  jnz	orw_exit			;exit if error
  mov	byte [right_win_status],1	;set in memory state
  mov	ebp,right_window
  call	check_selector_bar	
  sub	eax,eax				;signal success
orw_exit:
  ret
;---------------------------------------------
; inputs:  ebx = path to open
;          [project_path] - contains current path
; output: eax = 0 if success, jz, jnz flag set
;
open_window:
  mov	[ow_path],ebx		;save path
  call	dir_change
  js	ow_exit
  mov	esi,ebx
  mov	edi,project_path
  call	str_move  

  mov	esi,ebx
  mov	edi,temp_buf
  call	str_move
  cmp	byte [edi -1], '/'
  je	xxx
  mov	word [edi],2fh
xxx:

;setup for directory read and sort
  mov	eax,[bss_base]
  call	dir_open_indexed
  mov	esi,temp_buf
  call	dir_sort_by_type
  mov	eax,[bss_base]
  sub	[eax+dir._record_count],dword 2	;remove "." and ".." files
  add	[eax+dir._index_ptr],dword 8	;remove "." and ".."
  call	dir_close_file
  jmp	short ow_cont
;
; an error occured, go back to origional directory
;
ow_back:
  mov	esi,project_path
  call	str_end
ow_lp1:
  dec	esi
  cmp	byte [esi],'/'
  jne	ow_lp1		;loop till end of path found
  mov	byte [esi],0		;truncate path
  mov	ebx,project_path
  jmp	short open_window
;if a new directory was read, the index may have
;changed location.  Existing variables will be wrong
;and need to be adjusted.
;  top_row_ptr  and  selected_ptr
ow_cont:
  mov	eax,[ow_path]		;setup to chech which window is opened
  mov	ebp,right_window
  cmp	eax,right_win_path
  je	ow_setup		;jmp if right window
  mov	ebp,left_window
ow_setup:
  mov	ebx,[bss_base]
  mov	eax,[ebp+win_struc.top_index]
  or	eax,eax			;check first time
  jz	ow_set			;initialize if first time

  sub	eax,[ebx+dir._index_ptr]	;compute adjustment
  jz	ow_exit2			;exit if index location ok
  sub	[ebp+win_struc.top_row_ptr],eax
  sub	[ebp+win_struc.selected_ptr],eax
  mov	eax,[ebx+dir._index_ptr]
  mov	[ebp+win_struc.top_index],eax
  jmp	short ow_exit2
ow_set:
  mov	eax,[ebx+dir._index_ptr]
  mov	[ebp+win_struc.top_index],eax
  mov	[ebp+win_struc.selected_ptr],eax
  mov	[ebp+win_struc.top_row_ptr],eax
ow_exit2:
  xor	eax,eax
ow_exit:
  or	eax,eax
  ret
;---------
  [section .data]
ow_path:  dd	0
  [section .text]
;---------------------------------------------
; input ebp = active window ptr

check_selector_bar:
  test	byte [cmd_status],20h		;check if selector bar unchanged
  jz	csb_20				;jmp if selector bar can be reset
;
; adjust select bar if off window or out of sort_pointers range
;  first, scan down from top of pointers to selected ptr
  mov	esi,[bss_base]
  mov	esi,[esi+dir._index_ptr]	;was sort_pointers
  mov	edi,[ebp+win_struc.selected_ptr]
  cmp	esi,edi			;check if at top of window
  je	csb_20			;force top and avoid code below(may be empty dir)
csb_lp1:
  cmp	dword [esi],0		;check for end of pointers
  je	csb_2
  cmp	esi,edi
  je	csb_3			;jmp if selector found
  add	esi,4
  jmp	short csb_lp1
;the select pointer was not found. set new select pointer
csb_2:
  sub	esi,4			;move up one position
;verify the window top pointer is ok (page)
csb_3:
  mov	[ebp+win_struc.selected_ptr],esi	;store new/old ptr
  mov	edi,[ebp+win_struc.top_row_ptr]		;get display top ptr
csb_3a:
  cmp	esi,edi
  jae	csb_4					;jmp if ptr beyond top (normal)
  sub	dword [ebp+win_struc.top_row_ptr],4
  jmp	short csb_3				;adjust top window pointer
;check if pointer beyond end of window
csb_4:
  mov	eax,esi					;selector to eax
  sub	eax,edi					;compute delta
  shr	eax,2					;convert to index
;;  add	al,[ebp+win_struc.top_row]		;
  cmp	al,[ebp+win_struc.rows]			;are we inside window
  jbe	csb_5					;jmp if selector inside window
;pointer is beyond end of window
  add	edi,4					;move window down 1
  jmp	short csb_3a				;try again
;the pointer(esi) is now inside window edi=window top ptr
csb_5:
  mov	[ebp+win_struc.top_row_ptr],edi		;save top row ptr
;now adjust column (row_select) if necessary
  mov	eax,esi					;get select ptr
  sub	eax,edi					;subtract window top ptr
  shr	eax,2					;convert to 1 based index
  add	al,[ebp+win_struc.top_row]		;compute new select row
  mov	[ebp+win_struc.row_select],al
  jmp	short csb_30				;continue or exit???
;
; set default state - bar at top of window
;
csb_20:
  mov	byte [ebp+win_struc.row_select],3	;set row to top
  mov	eax,[bss_base]
  mov	eax,[eax+dir._index_ptr]
  mov	dword [ebp+win_struc.top_row_ptr],eax	;sort_pointers
  mov	dword [ebp+win_struc.selected_ptr],eax	;sort_pointers
;  and	byte [cmd_status],~20h	;clear flag if set 
csb_30:
  cmp	byte [old_path],0	;check if old path needs highlighting
  je	short csb_exit		;exit if no old path available
;
; search for old path and set as "selected"
;
  mov	edx,[bss_base]
  mov	edx,[edx+dir._index_ptr]	;sort_pointers
  mov	ecx,1			;for column tracking
try_again:
  mov	esi,[edx]		;get next pointer
  or	esi,esi			;check for empty dir
  jz	no_match		;jmp if null dir
  add	esi,10			;move past code
  mov	edi,old_path
cmp_loop:
  mov	al,[esi]
  or	al,[edi]
  jz	ds_match		;jmp if match found
  cmpsb
  jne	ds_next			;jmp if this entry does not match
  jmp	cmp_loop
ds_next:
  add	edx,4
  inc	ecx
  cmp	dword [edx],0
  jne	try_again
  jmp	no_match
ds_match:
  xor	ebx,ebx
  mov	bl,[ebp+win_struc.rows] ;get row count for this window
;  sub	ebx,3			;compute size of window
  cmp	ecx,ebx
  jbe	ds_set_selector
  sub	ecx,ebx
  shl	ebx,2
  add	[ebp+win_struc.top_row_ptr],ebx	;adjust page top ptr
  jmp	ds_match
ds_set_selector:
  mov	[ebp+win_struc.selected_ptr],edx ;set new select ptr
  add	cl,2
  mov	[ebp+win_struc.row_select],cl	;set new row
no_match:
  mov	byte [old_path],0	;disable old path till next left arrow
csb_exit:
  ret

;---------------------------------------------
; buffer sort_buf now has code,asciiz file.
; [_index_ptr] has dword pointer to sort_buf entries.
; call kernel and get code describing each file
;  input:  [project_path] = current directory
;

;--------------------------------------------------------------
display_selector_bar:
  mov	al,[active_window]
  cmp	al,1
  je	dsb_left
  cmp	al,2
  jne	dsb_exit
; display right selector bar
  mov	ch,[right_row_select]
  mov	cl,[top_right_col]	;column x
  mov	dl,[right_columns]	;display xx columns    
  mov	esi,[rselected_ptr]	;get ptr to sort pointers
  jmp	short dsb_call
;
dsb_left:
  mov	ch,[left_row_select]
  mov	cl,[top_left_col]	;column x
  mov	dl,[left_columns]	;display xx columns    
  mov	esi,[lselected_ptr]
dsb_call:
  mov	esi,[esi]		;get line pointer
  or	esi,esi			;check for null file
  jz	dsb_exit
  push	ecx
  push	edx
  call	build_line
  pop	edx
  pop	ecx
  mov	ebx,select_line_colors	;list of colors
  xor	edi,edi			;set scroll to  zero
  call	crt_line
dsb_exit:
  ret  
;--------------------------------------------------------------
; display_status_line
; inputs:  [cmd_status] - 80h=  abort state (should never reach here)
;                          bit 40h=1 display pre built message
;                            see [smsg_color], [smsg_txt]
display_status_line:
  mov	ebx,status_term_colors	;list of colors
  mov	ch,[status_line_row]
  mov	cl,1			;column 1
  mov	dl,10			;display 10 columns    
  mov	esi,status_line_msg
  xor	edi,edi			;set scroll to zero
  call	crt_line
;
  test	byte [cmd_status],40h
  jz	dsl_path		;jmp if standard path display
; display prebuild message
  mov	esi,smsg_color_code
  jmp	dsl_show
;
; display selector path
;
dsl_path:
  call	make_active_selection
  or	al,al
  jz	dsl_exit		;jmp if error or no file
  mov	esi,smsg_txt

dsl_show:
  mov	ebx,status_term_colors	;list of colors
  mov	ch,[status_line_row]
  mov	cl,term_intro_len			;column
  mov	dl,[crt_columns]
  sub	dl,cl			;compute number of colmuns to display
  inc	dl			;adjust columns to fix "sub" result
  xor	edi,edi			;set scroll to  zero
  call	crt_line
  mov	byte [cmd_status],2	;set default state for next time
dsl_exit:
  ret
;---------------------------------------------
; display_term_line
; output: eax = process pointer
;
display_term_line:
  mov	ebx,status_term_colors 	;list of colors
  mov	ch,[terminal_line_row]
  mov	cl,1			;column 1
  mov	dl,[crt_columns]	;number of columns to display
  mov	esi,term_line_msg
  xor	edi,edi			;set scroll to zero
  call	crt_line

;  mov	ah,[terminal_line_row]
;  mov	al,term_intro_len +1
;  call	move_cursor

  cmp	byte [term_cursor],11		;are we at start of line
  je	dtl_05				;jmp if at start of line

  cmp	byte [term_data],0		;empty buffer
  jne	dtl_50				;jmp if buffer has data
dtl_05:
  mov	ah,[terminal_line_row]
  mov	al,term_intro_len +1
  call	move_cursor
	
; looking for first alpha char.
  call	raw_set2
  call	key_flush
;
; note: A reoccuring problem with key data echoed on screen was
;       fixed by adding the key_flush before doing a poll wait.
;       The delay also seemed to help but may be unnecessary.
;       The problem gets worse when many proocess's area active
;       or loaded into memory.
;
dtl_06:
  call	key_poll
  jnz	dtl_07				;jmp if key available
  mov	eax,1000
  call	delay
  cmp	byte [window_resize_flag],0
  je	dtl_06				;loop if no WINCH signal
  call	raw_unset2
  mov	word [kbuf],1bh			;dummy key to allow window resize
  jmp	short dtl_09
dtl_07:
  call	raw_unset2
  call	read_stdin
dtl_09:
  mov	al,[kbuf]			;al = key
dtl_10:
  call	is_alpha			;check if key 20h-7eh
  jne	dtl_57				;jmp if not alpha
; alpha found, start string entry
  mov	byte [term_data],al		;put char in string
; now call key_string2
  mov	al,11			;get starting column
  mov	[term_column],al
  inc	al
  mov	[term_cursor],al	;store current cursor posn

  mov	ah,[crt_columns]	;compute lenght
  sub	ah,al			; of string
  inc	ah
  mov	[term_string_length],ah
dtl_50:
  mov	ebp,term_entry_table
  call	get_string
  mov	byte [term_cursor],ah	;keep this cursor position for now
  cmp	byte [kbuf],0ah
  jne	dtl_53			;jmp if not 0ah in kbyf
  mov	byte [kbuf],0dh
dtl_53:
  cmp	word [kbuf],001bh
  jne	dtl_55			;jmp if not esc
  call	clear_term_line
  mov	byte [term_cursor],11
  jmp	display_term_line
dtl_55:
  cmp	ah,11			;are we at start
  jne	dtl_60			;no, data is in buffer
  mov	byte [term_data],0	;disable string input
dtl_57:
  cmp	byte [kbuf],0dh
  jne	dtl_60			;jmp if not at start
  mov	eax,f2_key		;if buffer line empty, call open
  jmp	short dtl_exit
dtl_60:
  cmp	byte [kbuf],0dh
  jne	dtl_70			;jmp if not 0dh
  mov	eax,term_process
  jmp	short dtl_exit		;jmp if terminal process
dtl_70:
; decode key/mouse in kbuf
  cmp	byte [kbuf],-1		;check if mouse
  je	decode_mouse
; decode key in kbuf
  cmp	byte [kbuf],0		;is this ^space
  jne	dtl_80
  mov	eax,term_key
  jmp	short dtl_exit
dtl_80:
  mov	esi,key_table
  call	key_decode1
  jmp	dtl_exit		;exit with eax set
decode_mouse:
  call	mouse_decode
dtl_exit:
  ret
;---------------
  [section .data]
term_entry_table:
  dd	term_data
term_string_length:
  dd	140		;max string length
  dd	active_term_line_color
term_row:
  db	0		;row
term_column:
  db	0		;column
term_flags:
  db	00011100b 	;no 0dh in string,no home,end,right,left
term_cursor:
  db	0		;initial cursor column
wwin_size:
  dd	60

;  [section .text]
;--------------
key_table:
  dd	null_action	;error state?

    db 1bh,'1',0		;alt-1
  dd	alt_1_key
    db 0b1h,0
  dd	alt_1_key
    db 0c2h,0b1h,0
  dd	alt_1_key

    db 1bh,'2',0		;alt-2
  dd	alt_2_key
    db 0b2h,0
  dd	alt_2_key
    db 0c2h,0b2h,0
  dd	alt_2_key

    db 1bh,'3',0		;alt-3
  dd	alt_3_key
    db 0b3h,0
  dd	alt_3_key
    db 0c2h,0b3h,0
  dd	alt_3_key

    db 1bh,'4',0		;alt-4
  dd	alt_4_key
    db 0b4h,0
  dd	alt_4_key
    db 0c2h,0b4h,0
  dd	alt_4_key

    db 1bh,'5',0		;alt-5
  dd	alt_5_key
    db 0b5h,0
  dd	alt_5_key
    db 0c2h,0b5h,0
  dd	alt_5_key

    db 1bh,'6',0		;alt-6
  dd	alt_6_key
    db 0b6h,0
  dd	alt_6_key
    db 0c2h,0b6h,0
  dd	alt_6_key

    db 1bh,'7',0		;alt-7
  dd	alt_7_key
    db 0b7h,0
  dd	alt_7_key

    db 1bh,'8',0		;alt-8
  dd	alt_8_key
    db 0b8h,0
  dd	alt_8_key

    db 1bh,'9',0		;alt-9
  dd	alt_9_key
    db 0b9h,0
  dd	alt_9_key

    db 1bh,'0',0		;alt-0
  dd	alt_0_key
    db 0b0h,0
  dd	alt_0_key

    db 1bh,'h',0		;alt-h
  dd	help_key
    db 0e8h,0
  dd	help_key 
    db 0c3h,0a8h,0
  dd	help_key

    db 1bh,'f',0		;alt-f
  dd	find_key
    db 0e6h,0
  dd	find_key
    db 0c3h,0a6h,0
  dd	find_key

    db 1bh,'q',0		;alt-q 
  dd	quit_key
    db 0f1h,0
  dd	quit_key
    db 0c3h,0b1h,0
  dd	quit_key

    db 1bh,'s',0		;alt-s
  dd	setup_key
    db 0f3h,0
  dd	setup_key
    db 0c3h,0b3h,0
  dd	setup_key

    db 1bh,'t',0		;alt-t
  dd	term_key
    db 0f4h,0
  dd	term_key
    db 0fh,0			;ctrl-o
  dd	term_key
    db 1bh,4fh,50h,0		;f1
  dd	f1_key
    db 1bh,4fh,51h,0		;f2
  dd	f2_key
    db 1bh,4fh,52h,0		;f3
  dd	f3_key
    db 1bh,4fh,53h,0		;f4
  dd	f4_key
    db 1bh,5bh,5bh,41h,0	;f1
  dd	f1_key
    db 1bh,5bh,5bh,42h,0	;f2
  dd	f2_key
    db 1bh,5bh,5bh,43h,0	;f3
  dd	f3_key
    db 1bh,5bh,5bh,44h,0	;f4
  dd	f4_key
    db 1bh,5bh,5bh,45h,0	;f5
  dd	f5_key
    db 1bh,5bh,31h,31h,7eh,0	;2 f1
  dd	f1_key
    db 1bh,5bh,31h,32h,7eh,0	;3 f2
  dd	f2_key
    db 1bh,5bh,31h,33h,7eh,0	;4 f3
  dd	f3_key
    db 1bh,5bh,31h,34h,7eh,0	;5 f4
  dd	f4_key
    db 1bh,5bh,31h,35h,7eh,0	;6 f5
  dd	f5_key
    db 1bh,5bh,31h,37h,7eh,0	;7 f6
  dd	f6_key
    db 1bh,5bh,31h,38h,7eh,0	;8 f7
  dd	f7_key
    db 1bh,5bh,31h,39h,7eh,0	;9 f8
  dd	f8_key
    db 1bh,5bh,32h,30h,7eh,0	;10 f9
  dd	f9_key
    db 1bh,5bh,32h,31h,7eh,0	;11 f10
  dd	f10_key
    db 1bh,5bh,32h,33h,7eh,0	;12 f11
  dd	f11_key
    db 1bh,5bh,32h,34h,7eh,0	;13 f12
  dd	f12_key

    db 1bh,5bh,41h,0		;15 pad_up
  dd	dir_up
    db 1bh,5bh,35h,7eh,0	;16 pad_pgup
  dd	pgup_key
    db 1bh,5bh,44h,0		;17 pad_left
  dd	dir_bak
    db 1bh,5bh,43h,0		;18 pad_right
  dd	dir_fwd
    db 1bh,5bh,42h,0		;20 pad_down
  dd	dir_down
    db 1bh,5bh,36h,7eh,0	;21 pad_pgdn
  dd	pgdn_key

    db 1bh,4fh,41h,0		;15 pad_up
  dd	dir_up
    db 1bh,4fh,35h,7eh,0	;16 pad_pgup
  dd	pgup_key
    db 1bh,4fh,44h,0		;17 pad_left
  dd	dir_bak
    db 1bh,4fh,43h,0		;18 pad_right
  dd	dir_fwd
    db 1bh,4fh,42h,0		;20 pad_down
  dd	dir_down
    db 1bh,4fh,36h,7eh,0	;21 pad_pgdn
  dd	pgdn_key

    db 1bh,4fh,78h,0		;15 pad_up
  dd	dir_up
    db 1bh,4fh,79h,0		;16 pad_pgup
  dd	pgup_key
    db 1bh,4fh,74h,0		;17 pad_left
  dd	dir_bak
    db 1bh,4fh,76h,0		;18 pad_right
  dd	dir_fwd
    db 1bh,4fh,72h,0		;20 pad_down
  dd	dir_down
    db 1bh,4fh,73h,0		;21 pad_pgdn
  dd	pgdn_key

    db 9,0			;tab
  dd	tab_key
    db 0ah,0			;enter
  dd	f2_key			; use open function
    db 0dh,0
  dd	f2_key

    db 18h,0			;ctrl-x
  dd	quit_key
    db 1bh,78h,0		;alt-x
  dd	quit_key
    db 0f8h,0			;alt-x
  dd	quit_key
    db 0c3h,0b8h,0		;alt-x
  dd	quit_key

  db    0			;end of table
  dd	null_action		;no match action


  [section .text]
;---------------------------------------------
; input: kbuf has mouse info. as follows:
;         byte 1 = -1
;         byte 2 = button 0-3
;         byte 3 = column 1+
;         byte 4 = row 1+
; output: eax = process
;
mouse_decode:
  mov	bl,[kbuf+2]	;get click column
  mov	bh,[kbuf+3]	;get row
  cmp	bh,2		;check if top button row
  ja	md_10		;jmp if not top row
; decode top button line
  mov	esi,button_line1
  mov	edi,button_keys
;mouse_line_decode:
  call	mouse_line_decode
  jecxz  md_null		;jmp if no key found
  mov	eax,ecx
  jmp	md_exit
; check if botton lines
md_10:
  cmp	bh,[status_line_row]
  jb	md_20		;jmp if not status llne click
  cmp	bl,7		;check column of click
  ja	md_null
  mov	eax,term_key
  jmp	md_exit
; click was in window or mid button column
md_20:
  cmp	bl,[top_mid_col]
  jb	md_30		;jmp if left window click
  cmp	bl,[top_right_col]
  jae	md_40		;jmp if right window click
; click was on mid button column
  xor	eax,eax
  mov	al,bh
  sub	al,3		;convert to index 0+
  shr	eax,1
  shl	eax,2
  add	eax,mid_button_table
  mov	eax,[eax]	;get process
  jmp	md_exit
;click was on left window
md_30:
  mov	eax,left_win_click
  jmp	short md_exit
; click was on right window
md_40:
  mov	eax,right_win_click
  jmp	short md_exit
md_null:
  mov	eax,null_action
md_exit:
  ret

mid_button_table:
  dd	f1_key
  dd	f2_key
  dd	f3_key
  dd	f4_key
  dd	f5_key
  dd	f6_key
  dd	f7_key
  dd	f8_key
  dd	f9_key
  dd	f10_key
  dd	f11_key
  dd	f12_key
  dd	find_key
  dd	null_action
  dd	null_action
  dd	null_action
  dd	null_action
  dd	null_action
  dd	null_action
;---------------------------------------------
; display_mid_buttons - display mid button window
;
display_mid_buttons:
  mov	ebx,mid_button_colors
  mov	ch,[top_mid_row]
  mov	cl,[top_mid_col]
  mov	dl,[mid_columns]
  mov	dh,[mid_rows]
  mov	esi,mid_window_def
  call	crt_window2
  ret	


;----------------------------------------
; display_buttons - show buttons at top of display
;  inputs: [crt_columns]
;
display_buttons:
  mov	esi,button_line1
  mov	ah,1			;row 1
  mov	ecx,[button_spacer_color]
  mov	edx,[button_color1]
  call	crt_mouse_line
;
  mov	esi,button_line2
  mov	ah,2			;row 1
  mov	ecx,[button_spacer_color]
  mov	edx,[button_color1]
  call	crt_mouse_line
  ret

;---------------
; these tables are used by mouse decode, keypress's, and display_buttons
; the button_line1 and button_buffer are modified by contents of file top_buttons.tbl

  [section .data]
button_line1:
  db 1,' Quit',1,'Setup',1,' Help',1,' Proj',1,'tools',1,' Make',1,'debug',1,'/home',1,'/home',1,'/home',1,'/home',1,'/    ',1,'/    ',1,0
  times 30 db 0 ;padding if above line expands                                                                                                                     
button_line2:                                                                                                                                                 
  db 1,'alt-q',1,'alt-s',1,'alt-h',1,'alt-1',1,'alt-2',1,'alt-3',1,'alt-4',1,'alt-5',1,'alt-6',1,'alt-7',1,'alt-8',1,'alt-9',1,'alt-0',1,0
button_keys:
  dd quit_key,setup_key,  help_key,  alt_1_key,alt_2_key,alt_3_key,alt_4_key,alt_5_key,alt_6_key,alt_7_key,alt_8_key,alt_9_key,alt_0_key,0
button_process_ptrs:                                                                                                                                           
  dd  alt_q_,   alt_s_,   alt_h_,     alt_1,    alt_2,    alt_3,    alt_4,    alt_5,    alt_6,    alt_7,    alt_8,     alt_9,    alt_0,0
; equates used by key press routines to find process to launch
alt_q_ptr	equ	button_process_ptrs
alt_s_ptr	equ	alt_q_ptr + 4
alt_h_ptr	equ	alt_s_ptr + 4
alt_1_ptr	equ	alt_h_ptr + 4
alt_2_ptr	equ	alt_1_ptr + 4
alt_3_ptr	equ	alt_2_ptr + 4
alt_4_ptr	equ	alt_3_ptr + 4
alt_5_ptr	equ	alt_4_ptr + 4
alt_6_ptr	equ	alt_5_ptr + 4
alt_7_ptr	equ	alt_6_ptr + 4
alt_8_ptr	equ	alt_7_ptr + 4
alt_9_ptr	equ	alt_8_ptr + 4
alt_0_ptr	equ	alt_9_ptr + 4

button_buffer:
alt_q_   db       "/usr/share/asmmgr/quit",0
alt_s_   db       "/usr/share/asmmgr/setup",0
alt_h_   db       "/",0
alt_1    db       "/",0
alt_2    db       "/",0
alt_3    db       "/usr/share/asmmgr/make",0
alt_4    db       "/usr/share/asmmgr/debug",0
alt_5    db       "/home",0
alt_6    db       "/home",0
alt_7    db       "/home",0
alt_8    db       "/home",0
alt_9    db       "/",0
alt_0    db       "/",0
	times 400 db 0  ;padding if above expands

;------
  [section .text]
;-----------------------------------------------
; setup_window_paths
;  if first time then set window paths to $HOME
;  if not first time then,
;    set window paths to default dir & default path
;    path data is stored in form, from config file
setup_window_paths:
  cmp	byte [first_time_flag],1
  jne	swp_25			;jmp if not first time

;first time, check if parse found anything
swp_20:
  mov	byte [first_time_flag],0
  cmp	byte [project_path],0
  jz	swp_30			;jmp if no parsed data
;parse data found, move to left window
swp_25:
  mov	esi,project_path
  mov	edi,left_win_path
  call	str_move
  jmp	swp_60

;initial entry, no parse data, set both windows to cwd
swp_30:
  mov	eax,183			;get current working directory
  mov	ebx,left_win_path
  mov	ecx,200			;length of buffer
  int	80h
swp_60:
  cmp	byte [right_win_path],0
  jnz	swp_80			;exit if left win path has data
  mov	eax,183			;get current working directory
  mov	ebx,right_win_path
  mov	ecx,200
  int	80h
swp_80:
  ret
;------------
  
;---------------------------------------
; compute_window_sizes
;  inputs:  [crt_rows] - display rows
;           [crt_columns] - display columns
;  outputs: see window database
;
mid_win_size	equ	7

compute_window_sizes:
  xor	eax,eax
; compute number of columns in each window
  mov	al,[crt_columns]
  push	eax
  sub	al,mid_win_size		;remove middle window columns
  shr	eax,1			;divide by two
  mov	byte [left_columns],al
  mov	byte [mid_columns],mid_win_size
  pop	ebx			;restore total columns
  sub	bl,al			;compute right column
  sub	bl,mid_win_size		;size
  mov	byte [right_columns],bl
; compute window starting column locations
  mov	byte [top_left_col],1
  inc	al
  mov	byte [top_mid_col],al
  add	al,mid_win_size
  mov	byte [top_right_col],al
; compute number of rows in each window
  mov	al,[crt_rows]
  sub	al,4			;remove status & button lines
  mov	[left_rows],al
  mov	[mid_rows],al
  mov	[right_rows],al
; compute starting row for each window
  mov	byte [top_left_row],3
  mov	byte [top_mid_row],3
  mov	byte [top_right_row],3
; set status line rows
  mov	al,[crt_rows]
  mov	[terminal_line_row],al
  mov	[term_row],al
  dec	al
  mov	[status_line_row],al
  ret	

;---------------------------------------
; input:  esp = entry stack
; output: eax = negative if error
parse:
  mov	byte [project_path],0 ;clear project name
  mov	esi,esp
  lodsd			;get return address
  lodsd			;get parameter count
  cmp	eax,2
  jb	parse_exit2	;exit if no name input
  lodsd			;get name
  lodsd			;get first parameter
  mov	[stack_ptr],esi
  mov	esi,eax
  mov	edi,project_path
  call	str_move
  mov	ebx,project_path
  call	dir_status
  js	parse_exit	;exit if path does not exist

  mov	esi,[stack_ptr]	;restore stack ptr
  lodsd
  or	eax,eax
  jz	parse_exit	;exit if only one path
  mov	esi,eax
  mov	edi,right_win_path
  call	str_move
  mov	ebx,right_win_path
  call	dir_status	;set eax negative if error
parse_exit:
  jns	parse_exit2	;jmp if no errors
  push	eax
  mov	ecx,parse_err_msg
  call	stdout_str
  call	read_stdin
  pop	eax  
parse_exit2:
  ret
;-----------
  [section .data]
stack_ptr:  dd	0
parse_err_msg: db 0ah,'Bad path',0ah,0
  [section .text]
;--------------------------------------------------------------------
; input: [first_time_flag] set if initial entry, parse data dominates
; outputs: carry set if quit request
;          [edit_cmd_ptr] set
;          [path_request] set temp_buf 
get_tables:
  call	get_top_buttons_tbl
  call	get_config_tbl
  ret
;---------------------------------------
;read file top_buttons.tbl and modify the following:
;  button_line1 - holds button text
;  button_process_ptrs - holds pointers to shell commands
;  button_buffer - holds shell commands
;
get_top_buttons_tbl:
;read file
  mov	ebx,top_buttons
  mov	edx,setup_buf_size
  mov	ecx,[bss_base]
  call	file_simple_read
  js	gtbt_abort	;jmp if read error
  add	eax,[bss_base]
  mov	byte [eax],0	;put zero at end of file
;setup to extract data from file
; format of entry:  "name" "cmd string" eol
  mov	esi,[bss_base]
  mov	edi,button_buffer	;button shell strings
  mov	ebp,button_process_ptrs ;button shell strings ptrs
  mov	edx,button_line1	;button name destination
gtbt_lp1:
  call	find_quote
  jc	gtbt_abort
  call	store_button_name
  call	find_quote
  jc	gtbt_abort
  call	store_cmd_string
gtbt_lp2:
  lodsb
  or	al,al
  jz	gtbt_abort
  cmp	al,0ah		;look for end of line
  jne	gtbt_lp2
  jmp	gtbt_lp1
gtbt_abort:
  ret

  [section .data]
top_buttons:  db "/usr/share/asmmgr/top_buttons.tbl",0
  [section .text]
;---------------------------------------
; set carry if exit request
get_config_tbl:
;  mov	ebx,[enviro_ptrs]
  mov	edi,temp_buf
;  call	env_home	;get our path
  mov	esi,config_tbl
  call	str_move
;read file
  mov	ebx,temp_buf
  mov	edx,setup_buf_size
  mov	ecx,[bss_base]
  call	file_simple_read
  js	gct_abort	;jmp if read error
  mov	[gct_filesize],eax	;save file size
  add	eax,[bss_base]
  mov	byte [eax],0	;put zero at end of file
; scan table for data
  mov	esi,[bss_base]
gct_lp:
  call	find_quote
  jc	gct_exit1	;exit if end of table
  cmp	dword [esi],'exit'
  je	gct_quit
  cmp	dword [esi],'path'
  je	gct_path
  cmp	dword [esi],'edit'
  je	gct_edit
gct_find_eol:
  lodsb
  cmp	al,0
  je	gct_exit1	;exit if end of file
  cmp	al,0ah
  jne	gct_find_eol	;loop till end of line
  jmp 	short gct_lp  
;check value of quit request
gct_quit:
  add	esi,5		;move past "exit"
  call	find_quote
  cmp	byte [esi],'0'
  je	gct_find_eol	;jmp if not exit force
;we need to exit, rewrite config file
  mov	byte [esi],'0'
gct_update_file:
  mov	ebx,temp_buf		;file name
  mov	eax,[bss_base]		;buffer
  mov	ecx,[gct_filesize]
  mov	esi,01
  call	file_write_close
  jmp	gct_abort
  
gct_path:
  add	esi,5		;move past "path"
  call	find_quote
  cmp	byte [esi],'"'	;check for empty entry
  jne	gct_path2
;no path is entered, path_request -> 0
  mov	byte [path_request],0
  jmp	short gct_find_eol	;keep parsing
;we have a new path, move to temp_buf
gct_path2:
  push	esi
  mov	edi,temp_buf	;put new path in
  call	store_cmd_entry
  mov	byte [path_request],1
;remove path from file
  pop	edi		;get string start
  push	esi		;save parse location
  mov	eax,esi		;get string end
  sub	eax,edi		;compute string length
  dec	eax
  sub	[gct_filesize],eax	;save new file size
  mov	ebp,[bss_base]
  add	ebp,setup_buf_size	;end of file
  call	blk_del_bytes
;rewrite config file
;  mov	ebx,[enviro_ptrs]
  mov	edi,temp_buf
;  call	env_home	;get our path
  mov	esi,config_tbl
  call	str_move
  mov	ebx,temp_buf		;file name
  mov	eax,[bss_base]		;buffer
  mov	ecx,[gct_filesize]
  mov	esi,01
  call	file_write_close
  pop	esi		;restore parse location
  jmp	gct_find_eol	;go look for another entry

gct_edit:
  add	esi,5		;move past "path"
  call	find_quote
  mov	edi,editor
  call	store_cmd_entry
  dec	edi
  mov	al,' '
  stosb
  mov	al,0
  stosb
  jmp	gct_find_eol

gct_exit1:
  clc
  jmp	short gct_exit
gct_abort:		;come here if "quit" requested in table
  stc
gct_exit:
  ret
;-------------
  [section .data]
gct_filesize	dd	0

config_tbl: db '/usr/share/asmmgr/config.tbl',0

  [section .text]
;---------------------------------------
;input: esi = buffer (fbuf) ptr (points at start of cmd string)
;       edi = storage for button shell string
;       ebp = storage for button shell string pointers
;       edx = storage for button name, format 1,"     ",1,"     "

store_cmd_string:
  mov	[ebp],edi	;save pointer to this string
  add	ebp,4
store_cmd_entry:
scs_lp1:
  lodsb
  cmp	al,'"'		;check for end of string
  je	scs_string_end	;jmp if end of string
  stosb
  jmp	scs_lp1		;loop till string moved
scs_string_end:
  mov	al,0
  stosb			;put zero at end of string
  ret	

;---------------------------------------
;input: esi = buffer (fbuf) ptr (points at start of name text)
;       edi = storage for button shell string
;       ebp = storage for button shell string pointers
;       edx = storage for button name, format 1,"     ",1,"     "
store_button_name:
  cmp	byte [edx],1	;find expected 1
  jne	sbn_exit	;exit if error
  inc	edx		;move past 1
  lodsd			;get name
  mov	[edx],eax	;store 4 bytes
  add	edx,4
  lodsb			;get last byte of name
  mov	byte [edx],al	;store last byte of name
  inc	edx		;move to next 1
  inc	esi		;move past ending quote
sbn_exit:
  ret

;---------------------------------------
; input: esi = ptr to buffer
; output: carry set if end of buffer 
find_quote:
  lodsb
  or	al,al
  jz	fq_abort
  cmp	al,'"'		;check for start name field
  jne	find_quote	;loop till quote found
  clc
  jmp	fq_exit
fq_abort:
  stc
fq_exit:
  ret  
  
;---------------------------------------
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
  call	read_window_size
  mov	byte [window_resize_flag],1
  ret

;read_window_size:
;  mov	edx,winsize
;  call	read_winsize_0
;  mov	eax,[edx]
;  mov	[crt_rows],al
;  shr	eax,16
;  mov	[crt_columns],al
;  ret

;----------
  [section .data]
signal_table:
  db	28
sig_mod1:
  dd	winch_signal
  dd	0
  dd	0
  dd	0
  db	0		;end of install table
  [section .text]
;-----------------------------------------------
clear_terminal:
  call	normal_screen
  mov	eax,30003734h
  call	crt_clear
;
  call	clear_term_line	;clear input line
  ret
;--------------------------------------------------------------
; scan process table to see if multiple copies of "a" are
; executing.
;
  extern process_search
process_scan:
  mov	ebx,[bss_base]
  add	ebx,setup_buf_size	;buffer size
  call	set_memory
  mov	eax,[bss_base]		;buffer start
  mov	ebx,20000		;buffer size
  mov	ecx,our_name
ps_25:
  call	process_search
  or	eax,eax
  jz	ps_41			;jmp if end of process table
  js	ps_81			;jmp if error
; we have found a match
  inc	byte [match_cnt]
  xor	eax,eax			;set continue flag
  jmp	short ps_25
; adjust file names
ps_41:
  mov	al,[match_cnt]
  or	al,al
  jz	ps_81			;jmp if error
;the number of matches is in -al- , modify temp file name
  dec	al
  add	[right_stuff],al
  add	[left_stuff],al
  cmp	al,0
  je	ps_81			;jmp if we are only asmmgr running
  mov	ecx,warn_msg
  call	stdout_str
  call	read_stdin
ps_81:
  ret
;-----------------------
memory_setup:
  mov	eax,45
  xor	ebx,ebx
  int	byte 80h
  mov	[bss_base],eax
  mov	[rtop_row_ptr],eax
  ret
;-----------------------
;-----------------------
  [section .data]

our_name:  db 'asmmgr',0

warn_msg: db 1bh,'[2J',0ah	;erase screen 
	  db 'Warning, another copy of asmmgr is executing',0ah
	  db 'Some control keys may not work, (ctrl-o,F3)',0ah
	  db 'Press any key to continue',0ah,0

match_cnt:  db 0
  [section .text]  
;---------------------------------------------------------------
 [section .text]

;%include "sys_wrap.inc"
%include "crt_win_from_ptrs.inc"
%include "tools.inc"
;---------------------------------------
;%include "get_string.inc"
;---------------------------------------
  [section .data]

first_time_flag:  db	0	;1=first time 0=not first
root_flag	db	0	;0=normal user  1=root

;shell_var	db 'SHELL',0
;shell_default	db '/bin/sh',0

;---- start of window database -------
active_window  db 0		;0=none 1=left 2=right

left_window:
left_columns:  db 0
left_rows:     db 0
top_left_row:  db 0
top_left_col:  db 0
ltop_row_ptr:  dd 0
;
left_win_status db 0	 ;0=uninitialized 1=in memory 2=swaped to temp file
left_win_path	times 200 db 0
left_row_select db 3	 ;row selected for action
lselected_ptr   dd 0	;ptr to row currently selected
ltop_index_ptr	dd 0	;ptr to top of index

mid_window:
mid_buf_end:  dd 0		;end of all data, not just this window
mid_columns:  db 0
mid_rows:     db 0
top_mid_row:  db 0
top_mid_col:  db 0


right_window:
right_columns:  db 0
right_rows:     db 0
top_right_row:  db 0
top_right_col:  db 0
rtop_row_ptr    dd 0  ;ptr to row at top of window
;
right_win_status db 0 ;0=uninitialized 1=active 2=swaped to temp file
right_win_path	times 200 db 0
right_row_select db 3 ;row selected for action
rselected_ptr   dd 0		;ptr to row currently selected
rtop_index_ptr	dd 0	;top of index list for all records

;   hex color def: aaxxffbb aa-attr ff-foreground bb-background
;   30-blk 31-red 32-grn 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse

select_line_colors:
select_line_color	dd	31003736h	;color 1
select_line_size_color	dd	30003036h	;color 2
			dd	30003036h	;color 3 (for executables)

active_win_colors:
active_win_color	dd	31003734h	;color 1
active_win_size_color	dd	31003334h	;color 2 file size
			dd	31003234h	;color 3 executble
;select_line_colors:
;select_line_color	dd	31003736h	;color 1
;select_line_size_color	dd	30003036h	;color 2

inactive_win_colors:
inactive_win_color	dd	31003434h	;color 1
inactive_win_size_color dd	31003434h	;color 2
			dd	31003434h	;color 3

mid_button_colors:
mid_button_color1	dd	31003730h	;color 1
mid_button_color2	dd	30003037h	;color 2

status_term_colors:
button_color1:		dd	31003730h	;color 1
button_spacer_color	dd	30003734h	;color 2
;status_line_color	dd	31003733h	;color 3
status_line_color	dd	34003037h	;color 3
term_line_color		dd	30003037h	;color 4
error_color:
cursor_color		dd	30003133h	;color 5
active_term_line_color	dd	31003730h

mid_window_def:
  db 2,'status',0ah
  db 2,' F1   ',0ah
  db 1,'open  ',0ah
  db 1,' F2   ',0ah
  db 2,'view  ',0ah
  db 2,' F3   ',0ah
  db 1,'edit  ',0ah
  db 1,' F4   ',0ah
  db 2,'copy  ',0ah
  db 2,' F5   ',0ah
  db 1,'move  ',0ah
  db 1,' F6   ',0ah
  db 2,'mkdir ',0ah
  db 2,' F7   ',0ah
  db 1,'delete',0ah
  db 1,' F8   ',0ah
  db 2,'unpack',0ah
  db 2,' F9   ',0ah
  db 1,'tar.gz',0ah
  db 1,' F10  ',0ah
  db 2,'cmpar ',0ah
  db 2,' F11  ',0ah
  db 1,'print ',0ah
  db 1,' F12  ',0ah
  db 2,'find  ',0ah
  db 2,'alt-f ',0ah
  db 1,'      ',0ah
  db 1,'      ',0ah
  db 2,'      ',0ah
  db 2,'      ',0ah
  db 1,'      ',0ah
  db 1,'      ',0ah
  db 2,'      ',0ah
  db 2,'      ',0ah
  db 1,'      ',0ah
  db 1,'      ',0ah
  db 2,'      ',0ah
  db 2,'      ',0ah
  db 1,'      ',0ah
  db 1,'      ',0ah
  db 2,'      ',0ah
  db 2,'      ',0ah
  db 1,'      ',0ah
  db 1,'      ',0ah
  db 2,'      ',0ah
  db 2,'      ',0ah
  db 1,'      ',0ah
  db 1,'      ',0ah
  db 2,'      ',0ah
  db 2,'      ',0ah
  db 1,'      ',0ah
  db 1,'      ',0ah

status_line_row   db 0
terminal_line_row db 0
;--- end of window database -----

cmd_status	db	2		;big 80h  = abort
;                                       ;bit 40h = status line has prebuild msg
;                                       ;bit 20h = hold selection ptr position
;                                       ;bit 08h restart
;                                       ;bit 04h main_lp3
;                                       ;bit 02h main_lp2
;                                       ;bit 01h main_lp1
status_line_msg:
  db  2,' ',1,'term ',2,'  ',3,' ',0ah
term_line_msg:
  db  2,' ',1,'ctl-o',2,'  ',4,' >',0ah
term_intro_len	equ	10

path_request	db	0	;0=no  request 1=project requested path in temp_buf

symlink_flag	db	0	;0=current path not symlink
window_resize_flag db	0
  
	
termios:
c_iflag	dd	0
c_oflag dd	0
c_cflag dd	0
c_lflag dd	0
c_line	dd	0
cc_c	times 19 db 0
;---------------------------------------

%include "setup_table.inc"

  [section .bss]

bss_base	resd	1	;memory pointer

old_path	resb	60	;left arrow save for selector
;prebuilt message for status line
smsg_color_code	resb	1		;color number
smsg_txt	resb 200
term_data	resb	120
active_path	resb	260
project_path	resb	260
symlink_buf	resb	240	;used by dir_bak
temp_buf	resb	640

;---------------------------------------
; the following area is managed by library sort
; functions and others.  The following table describes
; the current state
;---------------------------------------
; everything beyond this point is allocatable
;---------------------------------------

;struc dir_block
struc dir
._handle			resd 1 ;set by dir_open
._allocation_end		resd 1 ;end of allocated memory
._dir_start_ptr		resd 1 ;ptr to start of dir records
._dir_end_ptr		resd 1 ;ptr to end of dir records
._index_ptr		resd 1 ;set by dir_index
._record_count		resd 1 ;set by dir_index
._work_buf_ptr		resd 1 ;set by dir_sort
endstruc
;

