;----------------------- asmfile.asm -----------------------------------
;
;   Copyright (C) 2008 Jeff Owens
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
;
; overview: This program is controled by two flags, win_state, shell_state
;  The win_state flag has bits to indicate which window pane is active and
;  whether the file data is in memory.
;
%include "signal.inc"
%include "system.inc"
%include "dcache_colors.inc"
;%include "macro.inc"

;%include "asmfile_struc.inc"
;-------------------- asmfile_struc.inc ----------------------

;--------------------------------------------------
; state flag bit definitions
;--------------------------------------------------
;win_state
is_root equ 08h          ;08 = 1-root state 0-not root           is_root
init_select_bar equ 10h  ;10 = 1-reset selector bar to top

;shell_state
is_partial_cmd equ 01h   ;01 = 1-shell partial cmd sent to shell is_partial_cmd
is_big_shell equ 02h     ;02 = 1-shell big (else 0-shell small)  is_big_shell
wait_for_key equ 04h     ;04 = 1-wait active
wait_for_prompt equ 08h  ;08 = 1-wait active
;-------------------------------------------------
struc win
.columns:  resb 1	;total columns in win
.rows:     resb 1	;total rows in win
.top_row:  resb 1	;starting row
.top_col:  resb 1	;starting column
.top_index_ptr resd 1	;ptr to top of index
.selected_ptr resd 1	;ptr to row currently selected
.display_top_index resd 1 ;top of display
.row_select resb 1	 ;row selected for action
.win_path  resb 200
.win_select_type resb 1   ;type code (char)
.win_select_path resb 200
endstruc

;-------------------------------------------------
;struc dir_block
;.handle			resd 1 ;set by dir_open
;.allocation_end		resd 1 ;end of allocated memory
;.dir_start_ptr		resd 1 ;ptr to start of dir records
;.dir_end_ptr		resd 1 ;ptr to end of dir records
;.index_ptr		resd 1 ;set by dir_index
;.record_count		resd 1 ;set by dir_index
;.work_buf_ptr		resd 1 ;set by dir_sort
;dir_block_struc_size:
;endstruc

;-------------------------------------------------
; structure describing a directory entry (dirent) on disk
;struc dents
;.d_ino	resd 1	;inode number
;.d_off	resd 1	;offset to next dirent from top of file
;.d_reclen resw 1;length of this dirent
;.d_name resb 1	;directory name (variable length)
;endstruc

;after dir_type call the directory data morphs into the following
;struc dtype
;.d_size	resd 1	;byte size for fstat .st_size
;.d_mode	resw 1	;type information from fstat .st_mode 
;.d_uid  resw 1  ;owner code
;.d_sort resb 1  ;sort code
;.d_type  resb 1  ;type code (see below)
;.d_nam resb 1	;directory name (variable length)
;endstruc
;type codes = directory   = / sort=1
;             link to dir = ~ sort=2
;             socket      = = sort=3
;             char dev    = - sort=4
;             block dev   = + sort=5
;             pipe        = | sort=6
;             symlink     = @ sort=7
;             orphan link = ! sort=8
;             executable  = * sort=9
;             normal file = space sort=10
;
;-------------------------------------------------
struc term_info_struc
.ws_row:  resw 1
.ws_col:  resw 1
.ws_xpixel resw 1
.ws_ypixel resw 1
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;term_info_struc_size:
;---------------------------------------------------

; Event types that can be polled for.  These bits may be set in `events'
; to indicate the interesting event types; they will appear in `revents'
; to indicate the status of the file descriptor.
POLLIN		equ 0x001	;There is data to read.  */
POLLPRI		equ 0x002	;There is urgent data to read.  */
POLLOUT		equ 0x004	;Writing now will not block.  */
POLLMSG		equ 0x400	;(not used)
POLLRDHUP	equ 0x2000	;Stream socket peer closed connection or shut down
POLLERR		equ 0x008	;(set by OS) Error condition.
POLLHUP		equ 0x010	;(set by OS) Hung up.
POLLNVAL	equ 0x020	;(set by OS) Invalid polling request.
POLLRDNORM	equ 0x040	;Normal data may be read (same as POLLIN)
POLLRDBAND	equ 0x080	;Priority data may be read (not often useful)
POLLWRNORM	equ 0x100	;Writing now will not block (same as POLLOUT)
POLLWRBAND	equ 0x200	;Priority data may be written

  extern sys_close
  extern vt_columns
  extern vt_stuff_col
  extern rowcol_to_image
  extern delay
  extern vt_out
  extern vt_clear
  extern vt_setup
  extern vt_ptty_setup
  extern vt_ptty_launch
  extern ptty_fd
  extern slave_fd
  extern ptty_pid
  extern sys_read
  extern vt_flush
  extern vt_in
  extern vt_fd
  extern sigchld_pid
  extern vt_set_all_writes

  extern output_winsize_0
  extern env_stack,enviro_ptrs
  extern env_shell
  extern read_termios_0
  extern output_termios_0
  extern stdout_str  
  extern read_window_size,crt_columns,crt_rows
  extern move_cursor
  extern mouse_enable
  extern str_move
  extern dir_status
  extern read_stdin,kbuf
  extern key_poll
  extern crt_clear
  extern crt_write
  extern set_memory
  extern key_decode1
  extern pop_dword
  extern put_dword
  extern put_pop_dword_setup
  extern str_end
  extern blk_del_bytes
  extern blk_insert_bytes
  extern strlen1
  extern dir_access
  extern signal_hit_mask
  extern event_setup
  extern raw_set2,raw_unset2

 extern sys_run_die
 extern file_close
 extern str_move
 extern read_term_info_0
 extern output_term_info_0
 extern wait_event
 extern bit_test

 extern sys_poll
 extern byte_to_ascii
 extern crt_window2
 extern dir_open
 extern dir_index
 extern crt_color_at
 extern crt_window
 extern is_number
 extern key_flush

  extern block_read_all
  extern block_write_all
  extern env_home
  extern str_compare

  extern terminfo_read
  extern terminfo_decode_setup
  extern terminfo_key_decode1
  extern reset_clear_terminal
  extern mouse_check

; The program begins execution here...... 
;
  global _start
_start:
  cld
  call	env_stack		;setup env ptr
  call	memory_setup
  mov	edx,termios
  call	read_termios_0		;save termios
  call	display_reset
  call	keyboard_setup
  call	check_available_plugins	;put ??? in non-available plugins
;  call	process_scan		;check if we already running
;  jnc	mgr_05			;jmp if scan ok
;exit2j:
;  jmp	exit2			;exit if scan found asmfile
mgr_05:
  call	read_bookmark_data	;get bookmark data
  call	mouse_enable		;enable the mouse
  call	signal_install
  mov	eax,24			;kernel getuid call
  int	80h			;check if we are root
  or	eax,eax			;check if user zero
  jnz	mgr_10			;jmp if not root
  or	[win_state],byte is_root	;set root flag
  mov	dword [mid_button_color2],31003731h ;if root buttons=red
mgr_10:
;  call	read_window_size
  call	parse			;get paths if provided
  or	eax,eax
  js	exit2			;exit if parse error
  call	restart_shell_entry
  call	setup_window_paths	;sets path current dir if no parsed
;  mov	esi,vt_setup_block
;  call	vt_setup
resize:
  mov	eax,20000
  call	delay
  call	window_resize

;%include "macro.inc"
;  logstr "crt_rows="
;  logmem [crt_rows]
;  logstr "  crt_columns="
;  logmem [crt_columns]
;  logeol

  mov	eax,[crt_rows]
  mov	[vt_setup_block],eax	;set rows in shell win
  mov	eax,[crt_columns]
  mov	[vt_setup_block+4],eax	;set columns in shell win
  mov	esi,vt_setup_block
  call	vt_setup
  and	[signal_hit_mask],dword ~_WINCH

;read all window data and redisplay both windows
main_lp0:
;display both windows
main_lp1:
  call	display_buttons		;display top buttons
  call	display_mid_buttons	;display mid buttons
  call	read_inactive_win
  call	show_inactive_win
;the following is a kludge, it solves a problem
;with alt-d (asmbug) that leaves garbage in the key
;buffer.  for some reason the flush must be here?
  call	flush_keys
;re-read active window data and redisplay
main_lp2:
  call	read_active_win
;redisplay active window
main_lp3:
  call	check_selector_bar
  call	show_active_win		;display only active win
main_lp4:
;non-dispay entry
  call	display_status_line	;display any messages
  call	display_selector_bar	;setup selection and highlight
main_lp5:
  call	chdir
  and	[win_state],byte ~init_select_bar
;  mov	eax,3			;display 3 line shell
  call	display_shell
;The window resize logic is responding to interrupts and
;needs to check if interrupt occured both before and after
;checking for keys.
;  cmp	[window_resize_flag],byte 0
;  jne	resize
  call	get_input		;returns success/error (eax)
  or	eax,eax			;signal?
  jns	start_action		;jmp if
;check signals here, -2 =signal -3=error
  cmp	eax,-2		;signal?
  jne	main_lp1
  cmp	[signal_hit_mask],dword _WINCH
  je	resize
  jmp	main_lp1		;dummy for now

start_action:
  call	eax	;*****************************
  test	[signal_hit_mask],dword _HUP
  jnz	exit2	;exit is sighup
;decode returns al = -x = error,quit
;                    0-5 = return codes
;
;each command must set hold state to either (set,clear,ignore)
;
  or	al,al
  js	exit2	;exit if error or exit request
  jz	main_lp0
  cmp	al,2
  jb	main_lp1
  je	main_lp2
  cmp	al,4
  jb	main_lp3
  je	main_lp4
  jmp	main_lp5
exit2:
  call	restore_our_termios
  call	write_bookmark_data
  call	reset_clear_terminal
  xor	ebx,ebx		;set return code=0
  mov	eax,1
  int	byte 80h
;---------
  [section .data]
clear_screen  db 1bh,'[2J',0
  [section .text]
;----------------------------------------------------------;
;flags in bh
p1_dir	equ	01h
p1_sel	equ	02h
p2_sel	equ	04h
p2_dir	equ	08h
p_eol   equ	40h
p_clr	equ	80h

;-----------------------------------------------------------
; launch - start shell using sys_wrap
;  inputs:  esi = shell string, or zero for interactive shell
;            bh =
;                p1_dir	equ	01h
;                p1_sel	equ	02h
;                p2_sel	equ	04h
;                p2_dir	equ	08h
;                p_eol  equ	40h -send eol
;                p_clr	equ	80h
;  output:  eax = app exit code
;
launch:
  mov	[shell_cmd_ptr],esi
  mov	[launch_flags],ebx
  call	put_cmd_in_history
;look up shell
launch_20:
  mov	edx,temp_buf		;shell storage point
  call	env_shell
  mov	esi,[shell_cmd_ptr]     ;is this an interactive shell?
;  mov	[shell_cmd_start],esi	;set to zero if no shell cmd
  or	esi,esi
  jz	sc_50		;jmp if interractive shell

launch_30:
;append command to shell
  inc	edi			;move past zero at end
  mov	ax,'-c'
  stosw
  mov	al,0
  stosb
;  mov	[shell_cmd_start],edi
  call	str_move		;move command to "shell -c" string
;insert parameters into buffer
  test	[sc_pbits],byte p1_dir + p1_sel
  jz	sc_50		;jmp if end of parameters
  mov	ax,2720h		;space quote
  stosw
  mov	ebp,[active_win_ptr]
  lea	esi,[ebp+win.win_path]
  test	[sc_pbits],byte p1_dir
  jnz	sc_22		;jmp if dir path
  lea	esi,[ebp+win.win_select_path]
sc_22:
  call	str_move
  mov	ax,2027h		;space quote
  stosw
;check if second parameter
  test	[sc_pbits],byte p2_sel+p2_dir
  jz	sc_50		;jmp if end of parameters
  mov	ax,2720h		;space quote
  stosw
  mov	ebp,[inactive_win_ptr]
  lea	esi,[ebp+win.win_select_path]
  test	[sc_pbits],byte p2_dir
  jz	sc_40		;jmp if file
  lea	esi,[ebp+win.win_path]
sc_40:
  call	str_move
  mov	ax,2027h		;space quote
  stosw
  test	[sc_pbits],byte p2_dir
  jz	sc_50
  mov	al,'/'
  stosb
;write eol to shell window if requested
sc_50:
  push	edi
  test	[sc_pbits],byte p_eol
  jz	sc_60
  mov	ecx,eol
  mov	edx,2
  call	vt_out
;clear shell window if requested
sc_60:
  test	[sc_pbits],byte p_clr
  jz	sc_70
  call	vt_clear
;terminate shell string
sc_70:
  pop	edi
  xor	eax,eax
  stosd				;terminate shell string
;  mov	esi,vt_setup_block
;  call	vt_setup
  mov	eax,temp_buf		;shell command
  mov	[signal_hit_mask],dword 0
  call	vt_ptty_setup
  call	vt_ptty_launch
  call	vt_set_all_writes
  call	vt_flush
;setup for wait event
;  mov	eax,[vt_fd]
;  mov	[pollfd],eax
  mov	eax,[ptty_fd]
  mov	[app_fd],eax

event_loop:
  test	[signal_hit_mask],dword _CHLD	;has child died?
  jnz	SIGCHLD_code			;jmp if a child has died
  mov	[key_evn],word POLLIN + POLLPRI
  mov	[app_evn],word POLLIN + POLLPRI
  mov	ebx,pollfd
  mov  ecx,2        ;number of elements in pollfd
  mov  edx,-1	;wait forever
  call	sys_poll
;return eax =
; +  number of events (0=timeout)
; EBADF  -9 An invalid file descriptor was given in one of the sets.
; EFAULT -14 The array given as argument was not  contained  in  the  calling
;        program’s address space.
; EINTR  -4 A signal occurred before any requested event.
; EINVAL -22 The nfds value exceeds the RLIMIT_NOFILE value.
; ENOMEM -12 There was no space to allocate file descriptor tables.
; [app_rev] and [key_rev] have event flags
  jns	event_waiting
  cmp	eax,-4	;did a signal interrupt?
  je	signal_event  
;if eax=0 then a timeout occured, not
;possible, so must be program error
  jmp	launch_done
;
;possible signal events are WINCH,HUP,CHLD
signal_event:
  mov	eax,[signal_hit_mask]
  cmp	eax,dword _WINCH
  je	SIGWINCH_code
  cmp	eax,dword _CHLD
  je	SIGCHLD_code
  test	[signal_hit_mask],dword _HUP
  jz	event_loop
  jmp	launch_done
event_waiting:
  test	[app_rev],word POLLIN + POLLPRI
  jnz	app_out_event
  test	[key_rev],word POLLIN + POLLPRI	;events of interest (see above)
  jnz	key_event
other_event:
  jmp   launch_done

;************
SIGCHLD_code:  ; child died
  and	[signal_hit_mask],dword ~_CHLD
  mov	eax,[sigchld_pid]
  cmp	eax,[ptty_pid]
  jne	event_loop	;jmp if our child not dead
;harvest exit status of child
keep_waiting:
  mov	ebx,[ptty_pid]
  mov	ecx,execve_status
  xor	edx,edx
  mov	eax,7
  int	80h			;wait for child, PID in ebx
  cmp	eax,-4			;did we interrupt a signal
  je	keep_waiting

  mov	ebx,[ptty_fd]
  call	sys_close
  mov	ebx,[slave_fd]
  call	sys_close
  jmp	launch_done

;************
SIGWINCH_code: ; terminal resize
winch_loop:
  and	[signal_hit_mask],dword ~_WINCH
  mov	eax,-1
  call	delay
  test	[signal_hit_mask],dword _WINCH
  jnz	winch_loop
  call	window_resize
  mov	eax,[crt_rows]
  mov	[vt_setup_block],eax	;set rows in shell win
  mov	eax,[crt_columns]
  mov	[vt_setup_block+4],eax	;set columns in shell win
  mov	esi,vt_setup_block
  call	vt_setup
  jmp	event_loop

;************
app_out_event:
  mov	ecx,wrap_buf
  mov	edx,wrap_buf_size
  mov	ebx,[ptty_fd]
  call	sys_read
  or	eax,eax
  jz	key_event	;exit if no data
  jns	do_app_30	;jmp if good read
  jmp	event_loop

do_app_30:
  mov	edx,eax		;move read size to edx
  call	vt_out		;process data
  call	vt_flush

;************
key_event:
  test	[key_rev], word POLLIN + POLLPRI
  jz	event_loop
  mov	ebx,0
  mov	ecx,wrap_buf
  mov	edx,wrap_buf_size
  call	sys_read
  jz	event_loop		;exit if out of data
  js	event_loop		;jmp if error
  cmp	[wrap_buf],byte 0fh	;ctrl-o?
  je	abort_launch
;handle mouse clicks
; mouse click report = <esc> [m 2x 2r 2c  x=button r=row c=col
; cursor report = <esc> [xx;yyR is handled elsewhere.
;
  mov	edx,eax		;size of read to edx
  call	vt_in
  jmp	event_loop

abort_launch:
;kill child
  mov	eax,37
  mov	ebx,[ptty_pid]
  mov	ecx,SIGKILL	;
  int	80h
  jmp	event_loop
	
launch_done:
  ret
;------------------------------------------



;------------
  [section .data]
execve_status:	dd 0,0

vt_setup_block:
  dd 24	;rows
  dd 80 ;columns
  dd vt_image_buf
  dd 1	;fd
  dd 0	;top row
  dd 0	;top left col
  db grey_char + black_back


shell_cmd_ptr dd	0	;shell command string or zero if interactive
launch_flags db 0	;bl ?
sc_pbits     db 0	;bh bit flags 01=clear 02=
             dw 0	;padding
eol	db 0ah,0dh
  [section .text]

;----------------------------------------------------------
put_cmd_in_history:
  mov	esi,[shell_cmd_ptr]
  or	esi,esi
  jz	pcih_exit	;exit if interactive shell
  mov	edi,lib_buf	;build output in lib_buf
  mov	ax,'->'
  stosw			;store prompt
  call	str_move
  mov	al,0ah
  stosb
  mov	al,0dh
  stosb
  mov	ecx,lib_buf
  mov	edx,edi
  sub	edx,ecx
  call	vt_out
pcih_exit:
  ret
;----------------------------------------------------------
zero_end_of_term_data:
  mov	esi,term_data+term_data_size -2
f8_lp:
  mov	al,[esi]
  cmp	al,0
  je	f8_tail		;jmp if zero
  cmp	[esi],byte ' '
  jne	f8_end		;jmp if end of string found
f8_tail:
  dec	esi
  cmp	esi,term_data
  jne	f8_lp		;loop till end found
f8_end:
  inc	esi
  xor	eax,eax
  mov	[esi],eax		;terminate string
  ret

;--------------------------------------------------------------------
; commands
;--------------------------------------------------------------------

;execute command in full shell
shell_cmd:
  cmp	[term_cursor],byte 3
  jne	sc_entered_cmd
;operate on selected file
  mov	ebp,[active_win_ptr]
  mov	al,[ebp+win.win_select_type]
  cmp	al,' '
  je	f3_key
  cmp	al,'/'
  je	dir_fwd
  cmp	al,'*'
  jne	sc_exit		;exit if can't operate
  lea	esi,[ebp+win.win_select_path]
  jmp	short sc_launch

sc_entered_cmd:
  call	zero_end_of_term_data
  mov	esi,term_data	;get command
sc_launch:
  mov	bh,0;p_eol	;preceed with eol
  call	launch
  call	restart_shell_entry  
sc_exit:
  mov	al,1		;reread all windows
  ret



;set bookmarks shift-fx
;-------------------------------------------------------------------
book1:
  mov	al,1
  jmp	short book_entry
;-------------------------------------------------------------------
book2:
  mov	al,2
  jmp	short book_entry
;-------------------------------------------------------------------
book3:
  mov	al,3
  jmp	short book_entry
;-------------------------------------------------------------------
book4:
  mov	al,4
  jmp	short book_entry
;-------------------------------------------------------------------
book5:
  mov	al,5
  jmp	short book_entry
;-------------------------------------------------------------------
book6:
  mov	al,6
  jmp	short book_entry
;-------------------------------------------------------------------
book7:
  mov	al,7
  jmp	short book_entry
;-------------------------------------------------------------------
book8:
  mov	al,8
  jmp	short book_entry
;-------------------------------------------------------------------
book9:
  mov	al,9
  jmp	short book_entry
;-------------------------------------------------------------------
book0:
  mov	al,10
book_entry:
  push	eax
  call	change_button_name
  pop	ecx
  call	change_button_bookmark
  mov	al,1	;reread all windows
  ret

;restore booklmark path commands, alt-1 to alt-0
;-------------------------------------------------------------------
alt_1_key:
  mov	cl,1
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_2_key:
  mov	cl,2
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_3_key:
  mov	cl,3
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_4_key:
  mov	cl,4
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_5_key:
  mov	cl,5
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_6_key:
  mov	cl,6
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_7_key:
  mov	cl,7
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_8_key:
  mov	cl,8
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_9_key:
  mov	cl,9
  jmp	short alt_entry
;-------------------------------------------------------------------
alt_0_key:
  mov	cl,10
alt_entry:
  call	find_bookmark_path	;returns esi -> path
  push	esi
  mov	ebx,esi
  xor	ecx,ecx			;dir access
  call	dir_access
  pop	esi
  or	eax,eax
  jnz	alt_exit		;jmp if can accesss path
  mov	edi,[active_win_ptr]
;reinitialize select ptr and display top
  mov	eax,[edi+win.top_index_ptr]
  mov	[edi+win.selected_ptr],eax
  mov	[edi+win.display_top_index],eax
  mov	[edi+win.row_select],byte 3
;move new path to active window
  lea	edi,[edi+win.win_path]	;get path ptr
  call	str_move		;change path
  or	[win_state],byte init_select_bar
alt_exit:
  mov	al,0	;re-read and redisplay
  ret

;-------------------------------------------------------------------
f1_key:
  xor	eax,eax			;preload null action
  cmp	[mid_status_key+1],byte '?';is this file available?
  je	f1_exit			;exit if program unavailable
  mov	esi,f1_legal
  call	check_file
  jz	f1_exit			;exit if illegal file type

  mov	esi,f1_header		;command
  mov	bh,p1_sel		;one parameter, select ptr
  call	launch
f1_exit:
  mov	al,1
  ret
;---------
  [section .data]
f1_header	db	'fileset',0
f1_pad		db	0,0,0,0,0,0
f1_legal	db	'@/* ',0
  [section .text]
;-------------------------------------------------------------------
f2_key:
  cmp	[mid_find_key+1],byte '?';is this file available?
  je	f2_exit			;exit if program unavailable

  mov	esi,f2_header		;command
  mov	bh,0			;no parameters
  call	launch
f2_exit:
  mov	al,1
  ret
;---------
  [section .data]
f2_header	db	'asmfind',0
f2_pad		db	0,0,0,0,0,0
  [section .text]
;-------------------------------------------------------------------
f3_key:
  cmp	[mid_view_key+1],byte '?';is this file available?
  je	f3_exit			;exit if program unavailable
  mov	esi,f3_legal
  call	check_file
  jz	f3_exit

  mov	esi,f3_header		;command
  mov	bh,p1_sel		;one parameter, select ptr
  call	launch
f3_exit:
  mov	al,1
  ret

;---------
  [section .data]
f3_header	db	'/usr/share/asmfile/less',0
f3_pad		db	0,0,0,0,0
f3_legal	db	' @*',0
  [section .text]
;-------------------------------------------------------------------
f4_key:
  cmp	[mid_edit_key+1],byte '?';is this file available?
  je	f4_exit			;exit if program unavailable
  mov	esi,f4_legal
  call	check_file
  jz	f3_exit

  mov	esi,f4_header		;command
  mov	bl,p1_sel		;one parameter, select ptr
  call	launch
f4_exit:
  mov	al,1
  ret

;---------
  [section .data]
f4_header	db	'asmedit',0
f4_pad		db	0,0,0,0,0,0
f4_legal	db	' @',0
  [section .text]
;-------------------------------------------------------------------
f5_key:                                             ;copyi
  mov	al,0
  call	cp_mv_engine
  mov	al,1
  ret

;-------------------------------------------------------------------
f6_key:
  mov	al,1
  call	cp_mv_engine
  mov	al,1
  ret
;-------------------------------------------------------------------
;input: al=0 (copy)  al=1 (move)
cp_mv_engine:
  mov	[cp_mv_flag],al
  mov	esi,cp_mv_legal
  call	check_file
  jz	cm_exit

  mov	edi,term_data	;msg build area
  mov	esi,cp_msg1
  cmp	[cp_mv_flag],byte 0
  je	cm_10
  mov	esi,mv_msg1
cm_10:
  call	str_move	;move "cp -> "
;get current selection for "copy ->"
  mov	ebp,[active_win_ptr]
  lea	esi,[ebp+win.win_select_path]
  call	str_move
;display 'from'
  mov	ecx,term_data
  mov	eax,[status_line_colors]
  mov	bh,[shell_win_row]
  inc	bh
  mov	bl,1
  call	crt_color_at
;setup to get destination
  mov	ecx,to_msg
  mov	eax,[status_line_colors]
  mov	bh,[shell_win_row]
  add	bh,2
  mov	bl,1
  call	crt_color_at
;setup for get_text
  mov	edi,term_data
  mov	ebp,[inactive_win_ptr]
  lea	esi,[ebp+win.win_path]
  call	move_and_modify

;build launch command
  mov	edi,wrap_buf		;build area
  mov	esi,cp_header
  cmp	[cp_mv_flag],byte 0	;copy?
  je	cm_copy			;jmp if copy
  mov	esi,mv_header
cm_copy:
  call	str_move
;modify the copy header if directory
  mov	ebp,[active_win_ptr]
  cmp	[cp_mv_flag],byte 0	;copy?
  jne	cm_move			;jmp if move
  mov	al,[ebp+win.win_select_type]
  cmp	al,'~'			;sym dir
  je	cm_recurse			;jmp if normal file
  cmp	al,'/'
  jne	cm_move			;jmp if not dir
cm_recurse:
  mov	al,'r'
  stosb
cm_move:
  mov	al,' '
  stosb
  lea	esi,[ebp+win.win_select_path]
  call	str_move
;now move destination
  mov	al,' '
  stosb
  mov	esi,term_data
cm_lp:
  lodsb
  cmp	al,' '
  je	cm_lp_end
  stosb
  cmp	al,0
  jne	cm_lp
cm_lp_end:
  xor	eax,eax
  stosd				;terminate cmd  
 
  mov	esi,wrap_buf		;command
  mov	bh,0
  call	launch
cm_exit:
  call	restart_shell_entry	;clear get_text entry line
  mov	al,1
  ret

;---------
  [section .data]
cp_mv_flag	db 0 ;0=copy 1=move
cp_mv_legal	db '/ @~*',0
cp_msg1	db 'cp -> ',0
mv_msg1 db 'mv -> ',0
to_msg: db 'to -> ',0

cp_header	db	'cp -f',0
mv_header	db	'mv ',0

get_str_tbl:
buf_ptr:	dd	term_data
max_in:		dd	120
color_p:	dd	status_line_colors
row		db	0
column		db	7
cursor_col	db	0
swin_size	dd	0  ;window size
sscroll		dd	0	;scroll

  [section .text]
;-------------------------------------------------------------------
;input: esi = data to be moved
;       edi = destination for esi (term_data + 7)
;output: term_data has completed string
;
move_and_modify:
  mov	[buf_ptr],edi
  call	str_move		;don't quote this one

;setup for string entry, we have filename to highlight
;  mov	byte [column],7

  mov	eax,edi			;get string end
  sub	eax,term_data		;compute cursor column
  add	eax,7			;o_msg_len	;6 ;adjust for term button at front
  mov	byte [cursor_col],al	;save cursor position

;pad end of buffer
  mov	al,' '
cm_pad_lp:
  cmp	edi,term_data+term_data_size -1
  je	cm_30			;jmp if buffer padded
  stosb
  jmp	short cm_pad_lp
cm_30:

  mov	al,[shell_win_row]
  add	al,2
  mov	[row],al

  mov	al,[crt_columns]
  sub	al,6			;smsg_len 6
  mov	[swin_size],al

  mov	ebp,get_str_tbl
  call	get_text		;get user inputs
  ret
;------------------------------------------------------------------------
f7_key:
;setup to get destination
  mov	ecx,f7_header
  mov	eax,[status_line_colors]
  mov	bh,[shell_win_row]
  add	bh,2
  mov	bl,1
  call	crt_color_at
;setup for get_text
  mov	edi,term_data
  mov	ebp,[active_win_ptr]
  lea	esi,[ebp+win.win_path]
  call	move_and_modify
;put zero at end of string
  mov	esi,term_data
f7_lp:
  lodsb
  or	al,al
  jnz	f7_lp
  mov	al,'/'
  stosb
  xor	eax,eax
  mov	[esi],eax		;terminate string
  mov	esi,term_data
  mov	bh,0			;no parameters
;build command in wrap_buf
  mov	esi,f7_header
  mov	edi,wrap_buf
  call	str_move
  mov	esi,term_data
  call	str_move
  mov	esi,wrap_buf
  call	launch
f7_exit:
  call	restart_shell_entry
  mov	al,1
  ret
;---------
  [section .data]
f7_header	db	'mkdir ',0
  [section .text]
;-------------------------------------------------------------------
f8_key:
  mov	ebp,[active_win_ptr]
  mov	al,[ebp+win.win_select_type]
del_file:
;setup to get destination
  mov	ecx,f8_show
  mov	eax,[status_line_colors]
  mov	bh,[shell_win_row]
  add	bh,2
  mov	bl,1
  call	crt_color_at
;setup for get_text
  mov	edi,term_data
  mov	ebp,[active_win_ptr]
  lea	esi,[ebp+win.win_select_path]
  call	move_and_modify
;put zero at end of string
  call	zero_end_of_term_data
  mov	esi,term_data
  mov	bh,0			;no parameters
;build command in wrap_buf
  mov	esi,f8_header
  mov	edi,wrap_buf
  call	str_move
  mov	esi,term_data
  mov	al,27h
  stosb
  call	str_move
  mov	al,27h
  stosb
  xor	eax,eax
  stosd
  mov	esi,wrap_buf
  mov	bh,0		;no parameters
  call	launch
f8_exit:
  call	restart_shell_entry
  mov	al,1
  ret
;---------
  [section .data]
f8_show		db	'rm -f ',0
f8_header	db	'rm -fr ',0
  [section .text]
;-------------------------------------------------------------------
f9_key:
  mov	ebp,[active_win_ptr]
  mov	al,[ebp+win.win_select_type]
  cmp	al,' '	;normal file?
  je	upack_file
  jmp	f9_exit
  
upack_file:
  mov	esi,f9_header		;command
  mov	bh,p1_sel
  call	launch
f9_exit:
  mov	al,1
  ret
;---------
  [section .data]
f9_header  db '/usr/share/asmfile/upak ',0
  [section .text]
;-------------------------------------------------------------------
f10_key:
  mov	ebp,[active_win_ptr]
  mov	al,[ebp+win.win_select_type]
  cmp	al,'/'	;dir?
  jne	f10_exit
  
pack_dir:
  mov	esi,f10_header		;command
  mov	bh,p1_sel		;one parameter, select ptr
  call	launch
f10_exit:
  mov	al,1
  ret
;---------
  [section .data]
f10_header  db '/usr/share/asmfile/pak ',0
  [section .text]
;-------------------------------------------------------------------
f11_key:
  cmp	[mid_compare_key+1],byte '?';is this file available?
  je	f11_exit		;exit if program unavailable

  mov	esi,f11_header		;command
  mov	bh,p1_sel+p2_sel	;one parameter, select ptr
  call	launch
f11_exit:
  mov	al,1
  ret
;---------
  [section .data]
f11_header	db '/usr/share/asmfile/compar ',0
  [section .text]
;-------------------------------------------------------------------
f12_key:
  mov	ebp,[active_win_ptr]
  mov	al,[ebp+win.win_select_type]
  cmp	al,' '	;normal file?
  jne	f12_exit
  
print_file:
  mov	esi,f12_header		;command
  mov	bh,p1_sel		;one parameter, select ptr
  call	launch
f12_exit:
  mov	al,1
  ret
;------------
  [section .data]
f12_header:  db '/usr/share/asmfile/print',0
  [section .text]
;-------------------------------------------------------------------
dir_up:
  mov	ebp,[active_win_ptr]
  cmp	byte [ebp+win.row_select],3	;select at top of window
  ja	du_40					;jmp if selector not at top
; selector is at top, check if window can move up
  mov	eax,[ebp+win.display_top_index]		;get top of display
  cmp	dword [ebp+win.top_index_ptr],eax	;at top of index?
  je	du_50					;jmp if window at start of file
; move window up one
  sub	dword [ebp+win.display_top_index],4
  jmp	short du_45
du_40:
  dec	byte [ebp+win.row_select]
du_45:
  sub	dword [ebp+win.selected_ptr],4
du_50:
  mov	al,3	;show active win
  ret
;-------------------------------------------------------------------
dir_down:
  mov	ebp,[active_win_ptr]
;check if at end of window
  xor	eax,eax
  mov	al,[ebp+win.top_row]	;get top of win row#
  add	al,[ebp+win.rows]	;compute line beyond last line
  dec	al
  cmp	al,[ebp+win.row_select]	;check if at end of window
  ja	ddd_20			;jmp if inside window
; we are at end of window, check if at end of file
  call	page_fwd
;         bh=lines in current page
;         ch=lines in next page
;        eax=0 if end of file found
;         bl=0 if current page full, else blank lines in page
;         cl=0 if next page full, else blank lines in page
  or	ch,ch
  jz	ddd_exit			;exit if no lines in next page
  add	dword [ebp+win.display_top_index],4 ;advance display top index
  jmp	short ddd_30
ddd_20:
  mov	eax,[ebp+win.selected_ptr]	;get selector index
  cmp	dword [eax+4],0			;more data follows?
  je	ddd_exit			;exit if at end of pointers
;it is ok to move down
  inc	byte [ebp+win.row_select]	;advance select row#
ddd_30:
  add	dword [ebp+win.selected_ptr],4	;advance select index
ddd_exit:
  mov	al,3		;main_lp3
  ret
;---------------
;-------------------------------------------------------------------
pgup_key:
  mov	ebp,[active_win_ptr]
  xor	ebx,ebx
  mov	cl,[ebp+win.rows]	;get total rows in this window
  mov	bl,0			;init row counter
  mov	esi,[ebp+win.display_top_index] ;get ptr to top win ptr
;check if at top of directory
  cmp	esi,[ebp+win.top_index_ptr]	;at top?
  jne	pk_lp1			;exit if not at top
;put select bar at top if already in top page  
  mov	eax,[ebp+win.display_top_index]
  mov	[ebp+win.selected_ptr],eax

  mov	bh,[ebp+win.top_row]
  mov	[ebp+win.row_select],bh
  jmp	short pk_exit

;move up one page
pk_lp1:
  cmp	esi,[ebp+win.top_index_ptr]	;check if at top of dir
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
  mov	[ebp+win.display_top_index],esi ;new window top
  shl	ebx,2			;compute number of ptrs moved
  sub	[ebp+win.selected_ptr],ebx  ;new selection bar ptr

pk_exit:
  mov	al,3
  ret
;-------------------------------------------------------------------
pgdn_key:
  mov	ebp,[active_win_ptr]
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
  add	[ebp+win.display_top_index],eax ;new window top
  add	[ebp+win.selected_ptr],eax  ;new selection bar ptr
;if this is last page, then move cursor to end of page
  or	ch,ch
  jnz   pgdn_exit	;jmp if not last page
  xor	eax,eax
  mov	al,bh		;get lines in current page
  dec	eax
  shl	eax,2
  add	eax,[ebp+win.display_top_index]
  mov	[ebp+win.selected_ptr],eax

  add	bh,[ebp+win.top_row]
  dec	bh
  mov	[ebp+win.row_select],bh
pgdn_exit:
  mov	al,3
  ret
;-------------------------------------------------------------------
dir_fwd:
  mov	ebp,[active_win_ptr]
  mov	eax,[ebp+win.selected_ptr]
  mov	eax,[eax]			;get ptr to dtype structure
  or	eax,eax			;any files here?
  jz	df_exit			;exit if no files
  mov	al,[eax+dtype.d_type]		;get type code
  cmp	al,'/'
  je	df_normal_dir			;jmp if normal dir
  cmp	al,'~'				;sym link dir
  je	df_10			;jmp if sym link dir
  jmp	df_exit			;exit if not symlink dir
;read sym link target
df_10:
  mov	eax,85
  lea	ebx,[ebp+win.win_select_path]	;get dir path
  mov	ecx,lib_buf+200			;buffer
  mov	edx,200				;buffer size
  int	byte 80h			;read symlink target
  or	eax,eax
  js	df_exit				;exit if error
  add	eax,lib_buf+200			;compute end of data
  mov	[eax],byte 0			;put zero at end
  push	ecx				;save path
  call	dir_current		;put path in lib_buf
  mov	edi,ebx			;get ptr to path
  add	edi,eax			;move to end of current path
  mov	al,'/'
  stosb				;add / to end
  pop	esi
  call	str_move		;append sym dir

  mov	ebx,lib_buf		;
  mov	ecx,4			;access read
  call	dir_access
  or	eax,eax
  jnz	df_exit			;exit if can't access
  mov	esi,lib_buf		;restore path ptr
  lea	edi,[ebp+win.win_path]		;destination=win_path
  call	str_move
  jmp	short df_50
df_normal_dir:
  lea	ebx,[ebp+win.win_select_path]
  mov	ecx,4		;check for read access
  call	dir_access
  or	eax,eax
  jnz	df_exit		;exit if access failed

  lea	esi,[ebp+win.win_select_path]
  lea	edi,[ebp+win.win_path]
  call	str_move
df_50:
;set display to top of dir
  mov	eax,[ebp+win.top_index_ptr]
  mov	[ebp+win.display_top_index],eax
  mov	[ebp+win.selected_ptr],eax
  mov	[ebp+win.row_select],byte 3
  or	[win_state],byte init_select_bar
df_exit:
  mov	al,2
  ret
;-------------------------------------------------------------------
dir_bak:
  mov	ebp,[active_win_ptr]
  lea	esi,[ebp+win.win_path]
  mov	edx,esi			;save start of current path
  cmp	byte [esi +1],0
  je	db_exit			;exit if at root
left_10:
  lodsb
  or	al,al
  jnz	left_10			;scan to end of path
left_20:
  dec	esi
  cmp	byte [esi],"/"
  jne	left_20			;loop till start of old path found
  cmp	esi,edx			;check if at root
  je	left_40			;jmp if at root
  mov	byte [esi],0		;truncate path
  inc	esi
  mov	[old_dir_name_ptr],esi
  jmp	short left_50
left_40:
;this is a kludge to handle root truncation
;esi points to /??? at root, we want to keep the '/' and put zero after
;this distroys the name, so we move it for [old_dir_name_ptr]
  push	esi
  add	esi,100
  mov	edi,esi
  inc	edi
  std
  mov	ecx,100
  rep	movsb
  cld
  inc	edi
  mov	[old_dir_name_ptr],edi
  pop	esi
  mov	byte [esi+1],0		;truncate path
left_50:

;we need to save this path so it can be highlilghted in lower window
;for now just go to top
  mov	eax,[ebp+win.top_index_ptr]
  mov	[ebp+win.display_top_index],eax
  mov	[ebp+win.selected_ptr],eax
  mov	[ebp+win.row_select],byte 3
db_exit:
  mov	al,2
  ret
;--------------
  [section .data]
old_dir_name_ptr	dd 0
  [section .text]
;-------------------------------------------------------------------
tab_key:
  mov	eax,left_window
  mov	ebx,right_window
  cmp	[active_win_ptr],eax	;left window?
  je	do_tab			;jmp if left active
;right window active, tab left
  xchg	eax,ebx
do_tab:
  mov	[active_win_ptr],ebx
  mov	[inactive_win_ptr],eax
;send directory move cmd to shell
  mov	al,1
  ret

;-------------------------------------------------------------------
shell_key:
;  mov	eax,[crt_rows]		;display full screen shell
;  dec	eax
;  call	display_shell
  xor	esi,esi			;command
  mov	bh,p_eol
  call	launch
  mov	al,1
  ret
;-------------------------------------------------------------------
help_key:
  mov	esi,help_block
  call	crt_window
  call	read_stdin
  mov	al,1
  ret
;----------
  [section .data]
help_block:
  dd	30003730h	;color for page
  dd	help_msg	;message ptr
  dd	help_msg_end	;end of msg
  dd	0		;scroll
  db	60		;window columns
  db	20		;window rows
  db	1		;starting row
  db	1		;starting column
  [section .text]
;-------------------------------------------------------------------
tool_key:
  call	tools_popup
  mov	al,1
  ret
;-------------------------------------------------------------------
quit_key:
  or	eax,byte -1
  ret

;-------------------------------------------------------------------
null_action:
  mov	al,4
  ret
;-------------------
shell_action:
  mov	al,4		;no redisplay needed
  ret
;-----------------------------
;bl=click column bh=click row
mouse_right:
  cmp	[active_win_ptr],dword right_window
  je	mr_10		;jmp if pane selected already
  push	ebx
  call	tab_key
  pop	ebx
mr_10:
  mov	ebp,right_window
  jmp	short mouse_common

;-----------------------------
;bl=click column bh=click row
mouse_left:
  cmp	[active_win_ptr],dword left_window
  je	ml_10		;jmp if pane selected already
  push	ebx
  call	tab_key
  pop	ebx
ml_10:
  mov	ebp,left_window

;bl=click column bh=click row
;ebp = win data ptr
mouse_common:
  cmp	bh,[ebp+win.row_select]
  je	mc_50		;jmp if already selected
;select this row
  xor	eax,eax
  xor	ecx,ecx
  mov	al,bh		;get row
  mov	cl,[ebp+win.row_select]
  sub	eax,ecx		;compute delta
  shl	eax,2		;multiply by 4
  add	[ebp+win.selected_ptr],eax	;adjust index ptr
  mov	[ebp+win.row_select],bh	;save new row
  jmp	short mc_exit
;row already selected, execute or enter
;this code is entered from handle_stdin
mc_50:
  cmp	[ebp+win.win_select_type],byte '*'	;executable?
  jne	mc_60			;jmp if not executable
;execute at click
  lea	esi,[ebp+win.win_select_path]	;command
  mov	bh,0			;feed_big_wait_prompt
  call	launch
  mov	al,1
  jmp	short mc_exit2

;check if click on directory
mc_60:
  cmp	[ebp+win.win_select_type],byte '/'
  je	dir_fwd
  cmp	[ebp+win.win_select_type],byte ' '	;normal file?
  je	f3_key  
mc_exit:
  mov	al,1
mc_exit2:
  ret
;--------------------------------------------------------------------
; processing
;--------------------------------------------------------------------
;-----------------------------------------
; use end of path for button name
;  inputs:  al=button# 
;  output:  book_line1 updated
change_button_name:
  xor	ebx,ebx
  mov	bl,al		;get button#
  dec	ebx		;make zero based
  mov	edi,ebx
  shl	edi,2		;mul by 4
  add	edi,ebx
  add	edi,ebx		;mul by 6
  add	edi,book_line1+1;get ptr to insert point

  mov	ebp,[active_win_ptr]
  lea	esi,[ebp+win.win_path]	;get current dir
  call	str_end			;find end of string
cbn_lp:
  cmp	byte [esi],'/'
  je	cbn_move
  dec	esi
  jmp	short cbn_lp
cbn_move:
  mov	ecx,5			;move 5 bytes
  inc	esi
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
  ret
;-----------------------------------------
; cut current bookmark from file and insert new one.
; adjust file size, and rewrite it.
;  inputs:  cl = button number, 1=first button
;  ouptut:  book_buffer updated
;
change_button_bookmark:
  call	find_bookmark_path	;in: cl=book#  out: esi=path
;find length of this string
  push	esi			;save ptr to current button path
  mov	edi,esi
;scan for length of current path
  xor	ecx,ecx
cbb_lp:
  lodsb
  or	al,al
  je	cbb_10
  inc	ecx
  jmp	short cbb_lp
;setup to delete old path
cbb_10:
  mov	eax,ecx			;delete area size 
  mov	ebp,[book_buffer_end_ptr]
; eax=old path size  edi=ptr to delete block top  ebp=end of file ptr
  call	blk_del_bytes		;remove old path
  mov	esi,[active_win_ptr]
  lea	esi,[esi+win.win_path]	;get current path
  call	strlen1			;set ecx=string length
  mov	eax,ecx			;string length -> eax
  pop	edi			;restore ptr to path insert point
; edi=insert point, ebp=file/blk end ptr  eax=insert length  esi=ptr to insert data
  call	blk_insert_bytes
  mov	[book_buffer_end_ptr],ebp
  ret

;----------------------------------------------------------
;input: cl=bookmark#  out: esi=path ptr
find_bookmark_path:
  mov	esi,book_buffer
;find path string for this button
cbb_lp1:
  dec	cl
  jz	cbb_got_string
cbb_lp2:
  lodsb
  or	al,al
  jnz	cbb_lp2
  jmp	short cbb_lp1
cbb_got_string:
  ret

;---------------------------------------------
; input: ebp = ptr to window parameters
; output: bh=lines in current page
;         ch=lines in next page
;        eax=0 if end of file found
;         bl=0 if current page full, else blank lines in page
;         cl=0 if next page full, else blank lines in page
page_fwd:
  xor	ebx,ebx
  mov	bl,[ebp+win.rows]	;get total rows in this window
  mov	cl,bl
  mov	ch,0
  mov	esi,[ebp+win.display_top_index]
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
;--------------------------------------------------------------------------
;input eax=number of lines to display
display_shell:
  mov	ebx,[vt_stuff_col]
  cmp	bh,2
  ja	ds_ok
  mov	bh,3  
ds_ok:
  mov	bl,1		;force left edge
  call	rowcol_to_image
  mov	eax,[vt_columns]
  shl	eax,2
  sub	ebp,eax		;compute start of data
;move two history lines to lib_buf
  mov	esi,ebp
  mov	edi,lib_buf
  mov	ecx,[vt_columns]
ds_mv1:
  lodsw
  stosb
  loop	ds_mv1
  mov	al,0ah
  stosb
  mov	ecx,[vt_columns]
ds_mv2:
  lodsw
  stosb
  loop	ds_mv2
;
  mov	al,0
  stosb		;put zero at end
;move cursor
  mov	ah,[shell_win_row]
  mov	al,1
  call	move_cursor
  mov	eax,30003037h	;color
  call	crt_set_color
  mov	ecx,lib_buf
  call	crt_str
ds_exit:
  ret

  [section .data]
shell_win_row	db	0	;shell top row, set by init
  [section .text]
;-----------------------
;--------------------------------------------------------------------------
;wait for keyboard input
;output: if eax = -2 signal
;           eax = -3 error
;           all others normal data
;        if eax positive = function address to call
;
get_input:
  call	mouse_enable
;display prompt
  mov	eax,[shell_color]
  mov	ebx,[crt_rows]
  shl	ebx,8		;move row to bh
  mov	bl,1		;column 1
  mov	ecx,prompt_str
  call	crt_color_at
; looking for first alpha char.
  call	raw_set2
;;  call	key_flush
;
; note: A reoccuring problem with key data echoed on screen was
;       fixed by adding the key_flush before doing a poll wait.
;       The delay also seemed to help but may be unnecessary.
;       The problem gets worse when many proocess's area active
;       or loaded into memory.
;
  mov	ebp,term_entry_table
  call	get_text
  mov	byte [term_cursor],ah	;keep this cursor position for now
  call	raw_unset2

  cmp	byte [kbuf],0ah
  jne	dtl_53			;jmp if not 0ah in kbuf
  mov	byte [kbuf],0dh
dtl_53:
; decode key/mouse in kbuf
  mov	al,[kbuf]
  cmp	al,-1
  je	decode_mouse
  cmp	al,-2			;signal?
  je	dtl_error
  cmp	al,-3
  je	dtl_error
  
; decode key in kbuf
dtl_80:
  mov	esi,key_table
  mov	edx,kbuf
  call	terminfo_key_decode1
  jmp	short dtl_exit
dtl_error:
  or	eax,dword 0ffffff00h	;set eax negative
  jmp	dtl_exit		;exit if error or signal
decode_mouse:
  call	handle_mouse
dtl_exit:
  ret
;---------------
  [section .data]
term_entry_table:
  dd	term_data
term_string_length:
  dd	140		;max string length
  dd	shell_color
term_row:
  db	0		;row, set by compute_win_sizes
term_column:
  db	3		;column
term_cursor:
  db	3		;initial cursor column
wwin_size:
  dd	60		;set by compute_win_sizes
  dd	0		;scroll

prompt_str	db '->',0

  [section .text]
;-------------------------------------------------------------------
restart_shell_entry:
  mov	edi,term_data
  mov	ecx,[term_string_length]
  mov	al,' '
  rep	stosb
  mov	[term_cursor],byte 3
  ret
;-------------------------------------------------------------------
; output: carry if mouse action decoded, eax = processing
;         else eax is set back to shell_action
;
handle_mouse:
  mov	esi,left_shift_table
  cmp	[kbuf+1],byte 0h	;left shift key?
  je	md_decode
  mov	esi,right_shift_table
md_decode:	
  call	mouse_decode
  jnz	ce_got_action
;check if mouse inside window
  mov	bl,[kbuf+2]	;get click column
  mov	bh,[kbuf+3]	;get row
  cmp	bh,[top_left_row]
  jb	ce_unknown_key
  cmp	bh,[status_line_row]
  jae	ce_unknown_key
  cmp	bl,[top_right_col]
  jae	md_right
  mov	eax,mouse_left
  jmp	short ce_got_action
md_right:
  mov	eax,mouse_right  
  jmp	short ce_got_action

ce_unknown_key:
  mov	eax,null_action
ce_got_action:
  ret
;-------------
  [section .data]
left_shift_table:
  db	2	;starting column
  db	6	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	shell_key

  db	08	;starting column
  db	12	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	tool_key

  db	14	;starting column
  db	18	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	help_key

  db	19	;starting column
  db	23	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	quit_key

;bookmark buttons

alt_1_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_1_key

alt_2_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_2_key

alt_3_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_3_key

alt_4_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_4_key

alt_5_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_5_key

alt_6_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_6_key

alt_7_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_7_key

alt_8_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_8_key

alt_9_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_9_key

alt_0_mod:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	alt_0_key

;mid button pointers

f1_mod:
  db	00	;starting column
  db	00	;ending column
  db	03	;starting row
  db	04	;ending row
  dd	f1_key

f2_mod:
  db	00	;starting column
  db	00	;ending column
  db	05	;starting row
  db	06	;ending row
  dd	f2_key

f3_mod:
  db	00	;starting column
  db	00	;ending column
  db	07	;starting row
  db	08	;ending row
  dd	f3_key

f4_mod:
  db	00	;starting column
  db	00	;ending column
  db	09	;starting row
  db	10	;ending row
  dd	f4_key

f5_mod:
  db	00	;starting column
  db	00	;ending column
  db	11	;starting row
  db	12	;ending row
  dd	f5_key

f6_mod:
  db	00	;starting column
  db	00	;ending column
  db	13	;starting row
  db	14	;ending row
  dd	f6_key

f7_mod:
  db	00	;starting column
  db	00	;ending column
  db	15	;starting row
  db	16	;ending row
  dd	f7_key

f8_mod:
  db	00	;starting column
  db	00	;ending column
  db	17	;starting row
  db	18	;ending row
  dd	f8_key

f9_mod:
  db	00	;starting column
  db	00	;ending column
  db	19	;starting row
  db	20	;ending row
  dd	f9_key

f10_mod:
  db	00	;starting column
  db	00	;ending column
  db	21	;starting row
  db	22	;ending row
  dd	f10_key

f11_mod:
  db	00	;starting column
  db	00	;ending column
  db	23	;starting row
  db	24	;ending row
  dd	f11_key

f12_mod:
  db	00	;starting column
  db	00	;ending column
  db	25	;starting row
  db	26	;ending row
  dd	f12_key

  dd	0	;end of table

;bookmark buttons
right_shift_table:
alt_1_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book1

alt_2_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book2

alt_3_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book3

alt_4_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book4

alt_5_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book5

alt_6_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book6

alt_7_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book7

alt_8_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book8

alt_9_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book9

alt_0_md:
  db	00	;starting column
  db	00	;ending column
  db	1	;starting row
  db	2	;ending row
  dd	book0

  dd	0	;end of table
;---------------------------------------------------------------------
;------------------------------------------------------------------------
restore_our_termios:
 mov	edx,termios
 cmp	dword [edx],0
 je	rot_exit
 call	output_termios_0
rot_exit:
 ret


;%include "asmfile_shell.inc"
;-----------------------------------------------
;#init
;%include "asmfile_init.inc"
;---------------------- asmfile_init.inc ------------------------

  [section .text]

setup_buf_size	equ	20000
sig_mask equ	_ABORT+_CHLD+_WINCH+_HUP
;---------------------------------------
signal_install:
; non abort signals that need checking are _CHLD (child died)  _WINCH (display resize)
  mov	eax,sig_mask	;enable mask
  mov	ebp,exit2	;send abort signals here
  mov	dl,0		;no keyboard handler
  call	event_setup	;enable signal handlers
  ret
;
;-----------------------
  [section .data]

our_name:  db 'asmfile',0
gnome_term_name: db 'gnome-terminal',0

warn_msg: db 1bh,'[2J',0ah	;erase screen 
	  db 'Warning, another copy of asmfile is executing',0ah
	  db 'Press any key to continue',0ah,0
gwarn_msg: db 1bh,'[2J',0ah	;erase screen 
	  db 'Warning, gnome-terminal may block function keys, try konsole,xterm,aterm, etc',0ah
	  db 'Press any key to continue',0ah,0
match_cnt:  db 0
  [section .text]

;-----------------------
initial_size	equ 20000
memory_setup:
  mov	eax,45
  xor	ebx,ebx
  int	byte 80h
  mov	[wrk_buf_ptr],eax
  mov	[rtop_row_ptr],eax
;allocate initial buffer
  mov	ebx,eax
  add	ebx,initial_size
  mov	eax,45
  int	80h
  ret
;-----------------------
;---------------------------------------
; input:  esp = entry stack
; output: eax = negative if error
parse:
  mov	esi,esp
  lodsd			;get return address
  lodsd			;get parameter count
  cmp	eax,2
  jb	parse_exit2	;exit if no name input
  lodsd			;get name
  lodsd			;get first parameter
  mov	[stack_ptr],esi
  mov	esi,eax
  mov	edi,left_win_path
  call	str_move
  mov	ebx,left_win_path
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
;-----------------------------------------------
; setup_window_paths
;    set window paths if not set by parse
setup_window_paths:
;first time, check if parse found anything
  cmp	byte [left_win_path],0
  jnz	swp_20			;jmp if parsed data
  mov	eax,183			;get current working directory
  mov	ebx,left_win_path
  mov	ecx,200			;length of buffer
  int	80h
swp_20:
  mov	esi,left_win_path
  mov	edi,lwin_select_path
  call	str_move

swp_30:
  cmp	byte [right_win_path],0
  jnz	swp_50			;exit if left win path has data
  mov	eax,183			;get current working directory
  mov	ebx,right_win_path
  mov	ecx,200
  int	80h
swp_50:
  mov	esi,right_win_path
  mov	edi,rwin_select_path
  call	str_move
swp_80:
  ret
;------------

read_bookmark_data:
  mov	ebx,[enviro_ptrs]
  mov	edi,temp_buf
  call	env_home		;find home directory
  mov	esi,bookmark_file
  call	str_move

  mov	ebx,temp_buf
  mov	ecx,book_line1	;buffer
  mov	edx,book_buffer_end_ptr - button_line1		;max file size
  call	block_read_all
  js	rbd_exit	;exit if file not found
  add	eax,book_line1	;compute file end
  mov	[book_buffer_end_ptr],eax
rbd_exit:
  ret

write_bookmark_data:
  mov	ebx,[enviro_ptrs]
  mov	edi,temp_buf
  call	env_home		;find home directory
  mov	esi,bookmark_file
  call	str_move

  mov	ebx,temp_buf
  mov	edx,666q	;default permissions
  mov	ecx,book_line1	;data to write
  mov	esi,[book_buffer_end_ptr]
  sub	esi,ecx		;compute length of write
  call	block_write_all
  ret
;---------
  [section .data]
bookmark_file:	db '/.asmfile_bookmarks',0
  [section .text]
;------------------------------------------------------------
adjust_mouse_decode:
;do bookmarks first
  mov	bl,[top_mid_col]
  mov	bh,bl
  add	bh,5	;bl-column start  bh=column end

  mov	ecx,10	;loop count
  mov	edi,alt_1_mod
  mov	edx,alt_1_md
amd_lp1:
  mov	[edi],bx	;modify mouse columns
  mov	[edx],bx
  add	bx,0606h	;adjust columns
  add	edi,8		;move to next button
  add	edx,8
  loop	amd_lp1
;now addust mid buttons
  mov	bl,[top_mid_col]
  mov	bh,bl
  add	bh,5		;compute ending column
  mov	ecx,12		;loop count
  mov	edi,f1_mod
amd_lp2:
  mov	[edi],bx
  add	edi,8
  loop	amd_lp2
  ret


;-----------------------------------------------
;#display
;%include "asmfile_display.inc"
;-------------------- asmmgr_display.inc ---------------------------
; display_status_line
; inputs:
;          [status_msg_ptr] - pointer to message if bit set
;                             message can have color codes 
display_status_line:
  mov	esi,[status_msg_ptr]
  or	esi,esi
  jnz	dsl_show	;jmp if msg pending
;
; display selector path
;
dsl_path:
  mov	ebp,[active_win_ptr]
  lea	esi,[ebp+win.win_path]
  lea	edi,[ebp+win.win_select_path+1]
  call	str_move
  mov	al,'/'
  stosb
  mov	esi,[ebp+win.selected_ptr]
  mov	esi,[esi]		;get ptr to dtype struc
  or	esi,esi			;check for empty dir
  jz	dsl_exit		;jmp if empty dir
  lea	esi,[esi+dtype.d_nam]	;move to name field
  call	str_move

  lea	esi,[ebp+win.win_select_path]
  mov	byte [esi],1		;force color 1
dsl_show:
;pad end of message
  mov	edi,temp_buf
  mov	ecx,[crt_columns]	;get max size
dsl_lp1:
  lodsb
  cmp	al,0
  je	dsl_pad
  stosb
  cmp	al,9
  jb	dsl_lp1			;loop if color code
  loop	dsl_lp1			;dec ecx if non-color code
dsl_pad:
  mov	al,' '			;pad char
  jecxz	dsl_term
  or	ecx,ecx
  jns	dsl_lp2
  add	edi,ecx		;move back to end
  jmp	short dsl_term
dsl_lp2:
  stosb
  loop	dsl_lp2			;pad line
dsl_term:
;terminate msg
  mov	al,0
  stosb

  mov	esi,temp_buf		;get message
  mov	ebx,status_line_colors	;list of colors
  mov	ch,[status_line_row]
  mov	cl,1			;column
  mov	dl,[crt_columns]
  xor	edi,edi			;set scroll to  zero
  call	crt_line
dsl_exit:
  xor	eax,eax
  mov	[status_msg_ptr],eax	;set no messages pending
  ret
;----------
  [section .data]
status_msg_ptr	dd 0	;filled in by others
  [section .text]
;-------------------------------------------------------------------
display_selector_bar:
  mov	ebp,[active_win_ptr]
  call	build_select_path
  jz	dsb_exit		;exit if empty directory
  mov	ch,[ebp+win.row_select]	;get select row
  mov	cl,[ebp+win.top_col]	;get select col
  mov	dl,[ebp+win.columns]	;get max columns
  mov	esi,[ebp+win.selected_ptr]

  mov	esi,[esi]		;get line pointer
  push	ecx
  push	edx
  call	build_line
  pop	edx
  pop	ecx
  mov	ebx,select_line_colors	;list of colors
  xor	edi,edi			;set scroll to  zero
  call	crt_line
dsb_exit:
  mov	[old_dir_name_ptr],dword 0
  ret
;----------------------------------------------------------------
;input: ebp = win data ptr
;output: flags set for jz=empty dir  
build_select_path:
;move directory base
  lea	esi,[ebp+win.win_path]
  lea	edi,[ebp+win.win_select_path]
  cmp	[esi+1],byte 0		;is this root dir
  je	dsb_root_skip		;skip one "/" if root
  call	str_move
dsb_root_skip:
;append '/'
  mov	[edi],byte '/'
  inc	edi
;move selected file/dir
  mov	esi,[ebp+win.selected_ptr]
  mov	esi,[esi]	;get dtype ptr
  or	esi,esi
  jz	bsp_exit		;exit if null file

  mov	al,[esi+dtype.d_type]
  mov	[ebp+win.win_select_type],al ;save type
;setup to save path
  lea	esi,[esi+dtype.d_nam]
  call	str_move
bsp_exit:
  or	esi,esi		;set flag, zero=empty directory
  ret

;-------------------------------------------------------------------
; input ebp = active window ptr

check_selector_bar:
;
; adjust select bar if off window or out of sort_pointers range
;  first, scan down from top of pointers to selected ptr
  mov	esi,[ebp+win.top_index_ptr]	;top of pointers
  mov	edi,[ebp+win.selected_ptr]
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
  mov	[ebp+win.selected_ptr],esi	;store new/old ptr
  mov	edi,[ebp+win.display_top_index]		;get display top ptr
csb_3a:
  cmp	esi,edi
  jae	csb_4					;jmp if ptr beyond top (normal)
  sub	dword [ebp+win.display_top_index],4
  jmp	short csb_3				;adjust top window pointer
;check if pointer beyond end of window
csb_4:
  mov	eax,esi					;selector to eax
  sub	eax,edi					;compute delta
  shr	eax,2					;convert to index
  cmp	al,[ebp+win.rows]			;are we inside window
  jbe	csb_5					;jmp if selector inside window
;pointer is beyond end of window
  add	edi,4					;move window down 1
  jmp	short csb_3a				;try again
;the pointer(esi) is now inside window edi=window top ptr
csb_5:
  mov	[ebp+win.display_top_index],edi		;save top row ptr
;now adjust column (row_select) if necessary
  mov	eax,esi					;get select ptr
  sub	eax,edi					;subtract window top ptr
  shr	eax,2					;convert to 1 based index
  add	al,[ebp+win.top_row]		;compute new select row
  mov	[ebp+win.row_select],al
  jmp	short csb_30				;continue or exit???
;
; set default state - bar at top of window
;
csb_20:
  mov	byte [ebp+win.row_select],3	;set row to top
  mov	eax,[ebp+win.top_index_ptr]
  mov	dword [ebp+win.display_top_index],eax
  mov	dword [ebp+win.selected_ptr],eax
csb_30:
  cmp	byte [old_dir_name_ptr],0	;check if old path needs highlighting
  je	short csb_exit		;exit if no old path available
;
; search for old path and set as "selected"
;
  mov	edx,[ebp+win.top_index_ptr]	;sort_pointers
  mov	ecx,1			;for column tracking
try_again:
  mov	esi,[edx]		;get next pointer
  or	esi,esi			;check for empty dir
  jz	no_match		;jmp if null dir
  add	esi,10			;move past code
  mov	edi,[old_dir_name_ptr]
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
  mov	bl,[ebp+win.rows] ;get row count for this window
  cmp	ecx,ebx
  jbe	ds_set_selector
  sub	ecx,ebx
  shl	ebx,2
  add	[ebp+win.display_top_index],ebx	;adjust page top ptr
  jmp	ds_match
ds_set_selector:
  mov	[ebp+win.selected_ptr],edx ;set new select ptr
  add	cl,2
  mov	[ebp+win.row_select],cl	;set new row
no_match:
  mov	[old_dir_name_ptr],dword 0	;disable old path till next left arrow
csb_exit:
  ret

;-------------------------------------------------------------------
show_inactive_win:
  mov	ebp,[inactive_win_ptr]
  mov	esi,dim_colors
  jmp	short display_win
show_active_win:
  mov	ebp,[active_win_ptr]
  mov	esi,dirclr
;display either left or right directory list
;inputs: ebp = window data
;        esi = color list
display_win:
  mov	edi,dircolor
  mov	ecx,7
  rep	movsd		;save colors
  mov	eax,[ebp]	;get top of win struc
  mov	[dw_columns],eax ;save columns,rows,top_row,top_column
  mov	ebp,[ebp+win.display_top_index]	;get top index

  mov	cl,[dw_rows]	;get lines to display
  mov	bh,[dw_top_row]	;starting display row
;check if empty dir
  cmp	[ebp],dword 0	;check if any files
  jnz	dd_lp		;jmp if files found
  mov	bl,[dw_top_col]
  mov	eax,[filecolor]
  push	ecx
  push	ebx
  push	ebp
  call	no_files
  pop	ebp
  pop	ebx
  pop	ecx
  dec	cl		;dec line count
  inc	bh		;bump line#
  jmp	dd_50		;go fill end with blanks
;
; move line to lib_buf
;

dd_lp:
  mov	ch,[dw_columns]
  mov	edi,lib_buf		;get pointer to line build area
  mov	esi,[ebp]		;get pointer to line data
  cmp	esi,0
  jne	dd_10			;jmp if more data
  jmp	dd_50			;jmp if out of data
dd_10:

  mov	eax,'    '
  stosd
  stosd
  sub	ch,9			;adjust column count for size
  push	edi
  dec	edi
  cmp	byte [esi+dtype.d_type],'*' ;is this a executable
  je	show_size
  cmp	byte [esi+dtype.d_type],' ' ;is this a file
  jne	skip_dir_sz
show_size:
  mov	eax,[esi+dtype.d_size]	;get file size
  push	ecx
  push	ebx
  call	dword_to_r_ascii
  pop	ebx
  pop	ecx
skip_dir_sz:
  pop	edi
;store space
  mov	al,' '
  stosb				;put space after file size
;display file name
  lea	esi,[esi+dtype.d_type]	;move to filename
dd_lp2:
  lodsb
  stosb
  cmp	al,0
  je	dd_14			;jmp if end of line found
  dec	ch
  jnz	dd_lp2			;loop till line moved
  jmp	dd_20
dd_14:
  dec	edi			;fill rest of line with blanks
  mov	al,' '
dd_16:
  stosb
  dec	ch
  jnz	dd_16
;
dd_20:
  mov	byte [edi],0		;put zero at end of line
  mov	esi,lib_buf		;move back start of line

  mov	dl,[esi+9]		;get code
  mov	eax,[execolor]
  cmp	dl,'*'
  je	dd_30
  mov	eax,[dircolor]
  cmp	dl,'/'			;check if 
  je	dd_30			;jmp if dir
  mov	eax,[linkcolor]
  cmp	dl,"@"
  je	dd_30
  cmp	dl,'~'
  je	dd_30			;jmp if link to dir
  cmp	dl,' '
  mov	eax,[filecolor]
  je	dd_30			;jmp if file
  mov	eax,[devcolor]
  cmp	dl,'-'
  je	dd_30
  cmp	dl,'+'
  je	dd_30  
  mov	eax,[misccolor]          
dd_30:
  push	ebx
  push	ecx
  mov	bl,[dw_top_col]
  mov	ecx,lib_buf		;get display text
  call	crt_color_at	;display message
  pop	ecx
  pop	ebx

  add	ebp,4
  inc	bh
  dec	cl
  jz	dd_60			;exit if end of window
  jmp	dd_lp
;
; end of data was reached before end of window, fill rest of screen
;  bh=display row  cl=number of rows to fill
dd_50:
  mov	edi,lib_buf
  mov	al,' '
  mov	ch,[dw_columns]
dd_52:
  stosb
  dec	ch
  jnz	dd_52
  mov	al,0
  stosb			;put zero at end
dd_54:
  mov	eax,[filecolor]
  push	ecx
  push	ebx
  mov	bl,[dw_top_col]
  mov	ecx,lib_buf	;get display text
  call	crt_color_at	;display message
  pop	ebx
  pop	ecx
  inc	bh
  dec	cl
  jnz	dd_54			;exit if end of window

dd_60:
  ret

;--------
  [section .data]
dircolor           dd 31003734h ;color of directories in list
linkcolor          dd 30003634h ;color of symlinks in list
selectcolor        dd 30003436h ;color of select bar
filecolor          dd 30003734h ;normal window color, and list color
execolor           dd 30003234h ;green
devcolor           dd 30003334h ;red
misccolor          dd 30003034h ;black

dw_columns	db 0
dw_rows		db 0
dw_top_row	db 0
dw_top_col	db 0

 [section .text]
;----------------------
no_files:
  push	eax
  push	ebx
  mov	edi,temp_buf
  mov	esi,no_files_msg
  call	str_move
  xor	ebx,ebx
  mov	bl,[dw_columns]
  add	ebx,temp_buf			;compute end

  mov	al,' '
nf_lp:
  cmp	ebx,edi
  je	nf_filled
  jb	nf_fix	;jmp if beyond window
  stosb
  jmp	short nf_lp
nf_fix:
  mov	edi,ebx
nf_filled:
  mov	[edi],byte 0
  pop	ebx
  pop	eax	
  mov	ecx,temp_buf	;get display text
  call	crt_color_at	;display message
  ret
;----------------- crt_win_from_ptrs.inc ------------------

  extern dword_to_r_ascii
  extern crt_line

;---------------------------------------------
; INPUT esi = ptr to record
; structure describing a directory entry
;struc dtype
;.d_size	resd 1	;byte size for fstat .st_size
;.d_mode	resw 1	;type information from fstat .st_mode 
;.d_uid  resw 1  ;owner code
;.d_len   resb 1  ;length byte from dent structure
;.d_type  resb 1  ;type code 1=dir 2=symlink 3=file
;.d_nam resb 1	;directory name (variable length)
;endstruc
;
; OUTPUT: esi=wrap_buf with line
;
build_line:
  mov	edi,wrap_buf		;location for line
;check if empty  directory message
  cmp	esi,no_files_msg
  je	bl_skip			;jmp if empty dir
  mov	al,2
  stosb				;store color code 2
  mov	eax,'    '
  stosd
  stosd
  push	edi
  dec	edi
  cmp	byte [esi+dtype.d_type],' ' ;is this a file?
  je	bl_50
  cmp	byte [esi+dtype.d_type],'*' ;is this executable?
  jne	skip_dir_size
bl_50:
  mov	eax,[esi+dtype.d_size]	;get file size
  call	dword_to_r_ascii
skip_dir_size:
  pop	edi
;store space color
  mov	al,' '
  stosb				;put space after file size
  lea	esi,[esi + dtype.d_type] ;get name
bl_skip:
  call	str_move
  mov	esi,wrap_buf
  ret

no_files_msg	db 'empty directory',0
;----------------------------------------
;-------------------------------------------------------------------
read_inactive_win:
  mov	ebp,[inactive_win_ptr]
  jmp	short read_window_data
read_active_win:
  mov	ebp,[active_win_ptr]

;read window data into memory, sort, add type
;input: ebp = window data
;output: eax = ptr to index top, "." and ".." entries removed
;        ebx = ptr to dir_block
;        ebp = ptr to win struc
read_window_data:
  mov	eax,[wrk_buf_ptr]	;bss_start
  lea	ebx,[ebp+win.win_path]
  call	dir_open	;returns dir_block ptr in eax
;   .handle			;set by dir_open
;   .allocation_end		;end of allocated memory
;   .dir_start_ptr		;ptr to start of dir records
;   .dir_end_ptr		;ptr to end of dir records
;   .index_ptr	                ;set by dir_index
;   .record_count		;set by dir_index
;   .work_buf_ptr		;set by dir_sort

;temp trap for program error
  or	eax,eax
  jns	rwd_01
trap1:
  mov	ecx,abort_msg
  call	crt_str
  call	read_stdin
  jmp	exit2

  [section .data]
abort_msg: db 0ah,'!!! program error in read_win_data !!!',0ah,0
  [section .text]

rwd_01:
  mov	[dir_block_pointer],eax
  call	dir_index
  or	eax,eax
  js	trap1
;get pointers from dir_block
  lea	esi,[ebp+win.win_path]
;dir_type need a "/" at end of path, so we put
;our path in temp_buf and add a "/"
  mov	edi,temp_buf
  call	str_move
  mov	[edi],byte '/'
  inc	edi
  mov	[edi],byte 0
  mov	esi,temp_buf

  mov	eax,[dir_block_pointer]
  push	ebp			;save win block ptr
  call	dir_sort_by_type	
  pop	ebp			;restore win block ptr
  mov	ebx,[dir_block_pointer]
  sub	[ebx+dir_block.record_count],dword 2
  
  mov	eax,[ebx+dir_block.index_ptr]
  add	eax,8		;remove '.' and '..' at top of dir
;check if reset select bar requeted
  test	[win_state],byte init_select_bar
  jz	rwd_fix		;jmp if no init requested
;reset the select bar
  mov	[ebp+win.top_index_ptr],eax
  mov	[ebp+win.selected_ptr],eax
  mov	[ebp+win.display_top_index],eax
  mov	[ebp+win.row_select],byte 3
  call	build_select_path
  jmp	rwd_exit
rwd_fix:
  call	adjust_and_hold
rwd_exit:
  ret
;-------------
  [section .data]
dir_block_pointer	dd 0
  [section .text]
;---------------------------------------
;input: eax=index ptr
;       ebp=win data ptr
;
adjust_and_hold:
  cmp	eax,[ebp+win.top_index_ptr]	;has index moved
  je	aah2				;jmp if index unchanged
;index has moved
  mov	ebx,[ebp+win.top_index_ptr]
  mov	ecx,[ebp+win.selected_ptr]
  sub	ecx,ebx			;ecx=target countdown
  shr	ecx,2

  xor	edx,edx
  mov	dl,[ebp+win.rows]	;total rows
  shr	edx,1			;edx=top_countdown

  mov	edi,eax			;new select index
  mov	esi,eax			;new display top index
aah_lp:
  mov	ebx,[edi]		;get select dtype
  or	ebx,ebx			;check if end of list
  jz	aah_50			;jmp if done
  jecxz aah_60			;jmp if at target
  dec	ecx			;dec target countdown
  add	edi,4			;bump target index
  cmp	edx,0
  jne	aah_20			;jmp if top not moving
  add	esi,4			;bump top display index
  jmp	aah_lp
aah_20:
  dec	edx			;dec display top countdown
  jmp	aah_lp

aah_50:
  cmp	edi,eax		;at top
  je	aah_60		;jmp if at top
  sub	edi,4
  cmp	esi,eax		;top at top
  je	aah_60
aah_60:
  mov	[ebp+win.top_index_ptr],eax
  mov	[ebp+win.selected_ptr],edi
  mov	[ebp+win.display_top_index],esi
;compute row
  xor	eax,eax
  mov	al,[ebp+win.rows]	;total rows
  shr	eax,1			;eax=top_countdown
  sub	eax,edx			;compute row countdown used
  add	eax,6
  mov	[ebp+win.row_select],al


  	  
aah2:
  call	build_select_path
aah_exit:    
  ret
;--------------------------------------------
window_resize:
  call	read_window_size
;for unknown reason the window size is incorrect when launched
;from icon.  This only occurs sometime, but appears to be fixed
;by reading size again. 
  call	read_window_size
window_resize2:
  call	compute_window_sizes	;compute sizes of windows
  call	adjust_mouse_decode	;adjust mouse decode for button locations
  ret
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
  mov	ax,[crt_columns]
  push	eax
  sub	eax,mid_win_size		;remove middle window columns
  shr	eax,1			;divide by two
  mov	byte [left_columns],al
  mov	byte [mid_columns],mid_win_size
  pop	ebx			;restore total columns
  sub	ebx,eax			;compute right column
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
  sub	al,6
  mov	[left_rows],al
  mov	[right_rows],al
  mov	[mid_rows],al
; compute starting row for each window
  mov	byte [top_left_row],3
  mov	byte [top_mid_row],3
  mov	byte [top_right_row],3
; set status line rows
  mov	al,[crt_rows]
  sub	al,3
  mov	[status_line_row],al
;set shell window row
  mov	al,[crt_rows]
  sub	al,2
  mov	[shell_win_row],al
;setup shell input line
  mov	al,[crt_columns]
  mov	[term_row],al
  mov	eax,[crt_columns]
  sub	eax,byte 2
  mov	[wwin_size],eax
;force read of window data
  or	[win_state],byte init_select_bar
  ret	
;----------------------------------------
; display_buttons - show buttons at top of display
;  inputs: [crt_columns]
;
display_buttons:
  mov	esi,button_line1
  mov	ah,1			;row 1
  mov	al,1			;column
  mov	ecx,[button_spacer_color]
  mov	edx,[button_color1]
  call	crt_mouse_line
;
  mov	esi,button_line2
  mov	ah,2			;row 1
  mov	al,1			;column1
  mov	ecx,[button_spacer_color]
  mov	edx,[button_color1]
  call	crt_mouse_line

  mov	esi,book_line1
  mov	ah,1			;row 1
  mov	al,[top_mid_col]	;column
  mov	ecx,[button_spacer_color]
  mov	edx,[button_color2]
  call	crt_mouse_line
;
  mov	esi,book_line2
  mov	ah,2			;row 1
  mov	al,[top_mid_col]	;column1
  mov	ecx,[button_spacer_color]
  mov	edx,[button_color2]
  call	crt_mouse_line
  ret

;---------------
; these tables are used by mouse decode, keypress's, and display_buttons
; the button_line1 and button_buffer are modified by contents of file top_buttons.tbl

  [section .data]
button_line1:
  db 1,'Shell',1,'Tools',1,'Help ',1,'Quit ',1,0
button_line2:                                                                                                                                                 
  db 1,'ctl-o',1,'alt-t',1,'alt-h',1,'alt-q',1,0

;- data below written to disk file asmfile_bookmarks
book_line1:
  db 1,'/    ',1,'/    ',1,'/    ',1,'/    ',1,'/    ',1,'/    ',1,'/    ',1,'/    ',1,'/    ',1,'/    ',1,0
book_line2:                                                                                                                                                 
  db 1,'alt-1',1,'alt-2',1,'alt-3',1,'alt-4',1,'alt-5',1,'alt-6',1,'alt-7',1,'alt-8',1,'alt-9',1,'alt-0',1,0

book_buffer:
         db       "/",0
         db       "/",0
         db       "/",0
         db       "/",0
         db       "/",0
         db       "/",0
         db       "/",0
         db       "/",0 
         db       "/",0
         db       "/",0
book_buffer_end:
 times 1024 db 0	;expansion
;- data in file asmfile_bookmarks, ends at [book_buffer_end_ptr]
book_buffer_end_ptr: dd book_buffer_end
;------
  [section .text]
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
;-------------
  [section .data]
mid_window_def:
  db 2,'status',0ah
mid_status_key:
  db 2,' F1   ',0ah
  db 1,'find  ',0ah
mid_find_key:
  db 1,' F2   ',0ah
  db 2,'view  ',0ah
mid_view_key:
  db 2,' F3   ',0ah
  db 1,'edit  ',0ah
mid_edit_key:
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
mid_unpack_key:
  db 2,' F9   ',0ah
  db 1,'tar.gz',0ah
mid_tar_key:
  db 1,' F10  ',0ah
  db 2,'cmpar ',0ah
mid_compare_key:
  db 2,' F11  ',0ah
  db 1,'print ',0ah
mid_print_key:
  db 1,' F12  ',0ah
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
  db 2,'      ',0ah
  db 2,'      ',0ah
  db 1,'      ',0ah
  db 1,'      ',0ah
 [section .text]


;-----------------------------------------------
;%include "crt_mouse_line.inc"
;---------------------- crt_mouse.inc --------------------------

  [section .text]

  extern lib_buf
  extern mov_color
  extern crt_str
  extern left_column,crt_columns

;****f* menu/crt_mouse_line *
; NAME
;>1 menu
;  crt_mouse_line - display line in mouse_decode format
; INPUTS
;    esi = menu line to display (see notes)
;    ah = display row 1+
;    al = column to start
;    (menu line always starts at column 1)
;    ecx = color for spaces between buttons
;    edx = color for buttons
;     
;    hex color def: aaxxffbb  aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brown 34-blue 35-purple 36-cyan 37-grey
;    attributes 30-normal 31-bold 34-underscore 37-inverse
; OUTPUT
;    menu line displayed
; NOTES
;   file:  crt_mouse_line.asm  (see also mouse_line_decode.asm)
;   The menu line has buttons separated by a number from 0-8.
;   the number represents a count of spaces between buttons.
;    example:
;    line:  db "button1",2,"button2",3,"button3",0
;    (zero  indicates end of line, 2=2 spaces)
;   Colors are in standard format (see crt_color.asm)
;<
; * ----------------------------------------------
;*******
  global crt_mouse_line
crt_mouse_line:
  push	esi
  mov	[space_color],ecx
  mov	[button_color_],edx
  mov	[starting_col],al
  call	move_cursor		;position cursor
  pop	esi
  call	make_line
  mov	ecx,lib_buf
  call	crt_str
  ret

;------------------------------------------
; build one display line using table
;  input: esi = table ptr
;
make_line:
  mov	edi,lib_buf
  mov	ecx,[left_column]
  xor	edx,edx
  mov	dl,[crt_columns]
  sub	dl,[top_right_col]	;compute line length
  cmp	[starting_col],byte 1
  jbe	bl_10
  add	dl,mid_win_size		;adjust for right win
;
bl_10:
  lodsb
  cmp	al,8
  jbe	bl_20    		;jmp if spacer between buttons
  call	stuf_char		;store button text
  jns	short bl_10		;loop till end of screen
  jmp	bl_80			;jmp if end of screen
;
; we have encountered a spacer or end of table
;
bl_20:
  push	eax
  mov	eax,[space_color]	;get color to use for spacer
  call	mov_color
  pop	eax
;
  cmp	al,0			;end of table
  je	bl_40			;jmp if end of table
;
; spacer char.
;
bl_22:
  push	eax
  mov	al,' '
  call	stuf_char
  pop	eax
  js	bl_80			;jmp if end of screen
  dec	al
  jnz	bl_22

  mov	eax,[button_color_]
  call	mov_color
  jmp	bl_10			;go up and move next button text
;
; we have reached the end of table, fill rest of line with blanks
;
bl_40:
  mov	al,' '
  call	stuf_char
  jns	bl_40
;
; end of screen reached, terminate line
;
bl_80:
  mov	al,0
  stosb				;put zero at end of display
  ret  


;---------------------------
; input: [edi] = stuff point
;          al  = character
;         ecx = scroll left count
;          dl = screen size
; output: if (zero flag) end of line reached
;         if (non zero flag) 
;             either character stored
;                 or ecx decremented if not at zero
;
stuf_char:
  jecxz	sc_active	;jmp if file data scrolled ok
  dec	ecx
  or	edi,edi		;clear zero flag
  ret
sc_active:
  stosb			;move char to lib_buf
  dec	edx
  ret

  [section .data]
space_color	dd	0	;space color
button_color_	dd	0	;button color
starting_col	db	0
  [section .text]
;%include "dir_sort_by_type.inc"
;-------------------- dir_sort_by_type.inc --------------------------

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
  extern sort_merge

;-------------------------------------------

%ifndef DEBUG
struc dir_block
.handle			resd 1 ;set by dir_open
.allocation_end		resd 1 ;end of allocated memory
.dir_start_ptr		resd 1 ;ptr to start of dir records
.dir_end_ptr		resd 1 ;ptr to end of dir records
.index_ptr		resd 1 ;set by dir_index
.record_count		resd 1 ;set by dir_index
.work_buf_ptr		resd 1 ;set by dir_sort
dir_block_struc_size:
endstruc
%endif

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -( SEARCH  )
;>1 dir
;  dir_sort_by_type - sort a opened and indexed directory
;  INPUTS
;     esi = ptr to directory path matching dir_block.
;           path ends with '/'
;     eax = ptr to dir_block with status of target dir
;
;  OUTPUT     eax = negative if error, else it contains
;                   a ptr to the following block.
;
;     struc dir_block
;      .handle			;set by dir_open
;      .allocation_end		;end of allocated memory
;      .dir_start_ptr		;ptr to start of dir records
;      .dir_end_ptr		;ptr to end of dir records
;      .index_ptr		;set by dir_index
;      .record_count		;set by dir_index
;      .work_buf_ptr		;set by dir_sort
;      dir_block_struc_size
;     endstruc
;
;  NOTE
;     source file is dir_open.asm
;     related functions are: dir_open - allocate memory & read
;                            dir_index - allocate memory & index
;                            dir_open_indexed - dir_open + dir_index
;                            dir_sort - allocate memory & sort
;                            dir_open_sorted - open,index,sort
;                            dir_close_file - release file
;                            dir_close_memory - release memory
;                            dir_close - release file and memory
;
;<
;  * ----------------------------------------------

  global dir_sort_by_type
dir_sort_by_type:
  cld
  call	dir_type		;fill in type information
  mov	[dir_block_ptr],eax	;save dir block
;allocate memory for index
  mov	ecx,[eax + dir_block.record_count]
  shl	ecx,2			;compute total bytes in index
  mov	ebx,[eax + dir_block.allocation_end]
  add	ebx,ecx			;compute end of index
  add	ebx,8			;add extra memory

  mov	eax,45
  int	80h			;allocate memory
  or	eax,eax
  js	ds_error		;jmp if allocaton  error
  mov	edx,[dir_block_ptr]
  mov	[edx + dir_block.allocation_end],eax    
  mov	eax,edx			;set eax=dir_block
;setup for sort
  mov	ebp,[eax + dir_block.index_ptr]
  mov	ebx,20		;length of sort key
  mov	ecx,[eax + dir_block.record_count]
  mov	edx,8		;sort on  name field of dirent
  call	sort_merge
  mov	eax,[dir_block_ptr]
ds_error:
  ret

;------------

  [section .data]
dir_block_ptr:	dd	0

  [section .text]
;----------------------- dir_type -----------------------------------

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

  [section .text]  
  extern dir_status
  extern lib_buf
  extern str_move
  extern dir_change
  extern dir_current
;-------------------------------------------

%ifdef DEBUG
struc dir_block
.handle			resd 1 ;set by dir_open
.allocation_end		resd 1 ;end of allocated memory
.dir_start_ptr		resd 1 ;ptr to start of dir records
.dir_end_ptr		resd 1 ;ptr to end of dir records
.index_ptr		resd 1 ;set by dir_index
.record_count		resd 1 ;set by dir_index
.work_buf_ptr		resd 1 ;set by dir_sort
dir_block_struc_size:
endstruc
%endif

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


; structure describing a directory entry
struc dtype
.d_size	resd 1	;byte size for fstat .st_size
.d_mode	resw 1	;type information from fstat .st_mode 
.d_uid  resw 1  ;owner code
.d_sort resb 1  ;sort code
.d_type  resb 1  ;type code (see below)
.d_nam resb 1	;directory name (variable length)
endstruc
;type codes = directory   = / sort=1
;             link to dir = ~ sort=2
;             socket      = = sort=3
;             char dev    = - sort=4
;             block dev   = + sort=5
;             pipe        = | sort=6
;             symlink     = @ sort=7
;             orphan link = ! sort=8
;             executable  = * sort=9
;             normal file = space sort=10
;

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 dir
;  dir_type - Add type information to indexed directory
;     dir_type is called by dir_sort_by_name and dir_sort_by_type.
;     Normally it is not called as a standalone function.
;  INPUTS
;     esi = ptr to path of this directory (ends with '/')
;     eax = ptr to open dir_block
;
;     struc dir_block
;      .handle			;set by dir_open
;      .allocation_end		;end of allocated memory
;      .dir_start_ptr		;ptr to start of dir records
;      .dir_end_ptr		;ptr to end of dir records
;      .index_ptr		;set by dir_index
;      .record_count		;set by dir_index
;      .work_buf_ptr		;set by dir_sort
;      dir_block_struc_size
;     endstruc
;
;     Note: dir_type is usually called after dir_index
;           or dir_open_indexed
;
;  OUTPUT     eax = negative if error, else it contains
;                   a ptr to the dir_block
;     The index now points to a directory entries with
;     the following structure:
;
;     struc dtype
;      .d_size	resd 1	;byte size for fstat .st_size
;      .d_mode	resw 1	;type information from fstat .st_mode 
;      .d_uid   resw 1  ;owner code
;      .d_sort  resb 1  ;length byte from dent structure
;      .d_type  resb 1  ;type code (see below)
;      .d_nam resb 1	;directory name (variable length)
;     endstruc
;type codes = directory   = / sort=1
;             link to dir = ~ sort=2
;             socket      = = sort=3
;             char dev    = - sort=4
;             block dev   = + sort=5
;             pipe        = | sort=6
;             symlink     = @ sort=7
;             orphan link = ! sort=8
;             executable  = * sort=9
;             normal file = space sort=10
;
;  NOTE
;     source file is dir_type.asm
;     related functions are: dir_open - allocate memory & read
;                            dir_index - allocate memory & index
;                            dir_open_indexed - dir_open + dir_index
;                            dir_sort - allocate memory & sort
;                            dir_open_sorted - open,index,sort
;                            dir_close_file - release file
;                            dir_close_memory - release memory
;                            dir_close - release file and memory
;
;<
;  * ----------------------------------------------
;store file codes in dirent's, put codes infront of file name.

  global dir_type
dir_type:
  push	eax
  mov	[our_path],esi
  mov	ebp,[eax + dir_block.index_ptr]	;sort_pointers
gt_loop1:
  mov	edi,[ebp]
  or	edi,edi
  jz	gt_donej		;jmp if empty directory
  add	edi,10			;move to filename
  mov	esi,[our_path]
  call	build_path1

  mov	ebx,[our_path]		;default_path
  call	dir_status

  or	eax,eax
  jns	gt_fill			;jmp if file found
;found we get error -75 with some character devices.
;If we assume all errors are char. devices it seems to work.
  jmp	char_dev
gt_donej:
  jmp	gt_err			;jmp if file not found
gt_fill:
  mov	ebx,[ebp]		;get pointer to dtype struc
;store st_size from fstat -> d_size
  mov	eax,[ecx+stat_struc.st_size]
  mov	[ebx + dtype.d_size],eax
;store st_mode from fstat -> d_type
  mov	ax,[ecx+stat_struc.st_mode]
  mov	[ebx + dtype.d_mode],ax
;store st_uid for fstat -> d_uid
  mov	ax,[ecx+stat_struc.st_uid]
  mov	[ebx + dtype.d_uid],ax
;
; decode file type
;
  mov	al,0e0h
  and	al,[ecx+stat_struc.st_mode+1]
  shr	al,5	;0=pipe 1=char 2=dir 3=block 4=file 5=sym 6=sock
;   
  dec	al
  js	pipe
  jz	char_dev
  sub	al,2
  js	directory
  jz	block_dev
  sub	al,2
  js	file_type
  jz	symlink
;assume socket
  mov	al,"3"	;sort
  mov	ah,'='
  jmp	short gt_store
pipe:
  mov	al,"6"
  mov	ah,'|'
  jmp	short gt_store
char_dev:
  mov	al,'4'
  mov	ah,'-'
  jmp	short gt_store
directory:
  mov	al,"1"
  mov	ah,'/'
  jmp	short gt_store
block_dev:
  mov	al,'5'
  mov	ah,'+'
  jmp	short gt_store
file_type:
  mov	al,'9'	;sort
  mov	ah,'*'	;execute
  test	[ecx+stat_struc.st_mode],word 01001001b ;any execute bits set?
  jnz	gt_store	;jmp if executeable
  mov	al,'a'	;normal file
  mov	ah,' '  ;normal file = space
  jmp	short gt_store
;check if directory or orphan
symlink:
  call	handle_link
;store sort & type al=sort ah=type
gt_store:
  mov	ebx,[ebp]		;get pointer to name
  mov	[ebx + dtype.d_sort],ax ;al=sort key ah=d_type
;move to next index 
  add	ebp,4
  jmp	gt_loop1
gt_err:

gt_done:
  pop	eax
  ret
;
;-----------------------------------------------------------------
;handle_link:

handle_link:
;we have found a symlink, check type, read target into lib_buf
  mov	esi,[our_path]
  mov	edi,lib_buf+400	;buf+400 origional path
  call	str_move

  mov	eax,85			;read link sys-call code
  mov	ebx,lib_buf+400		;buf+400 origional path
  mov	ecx,lib_buf+200		;buf+200 for symlink target
  mov	edx,400			;lib_buf_size
  int	80h			;call kernel
  or	eax,eax
  js	mp_exitj		;ignore if error
  add	eax,lib_buf+200		;compute end of data
  mov	byte [eax],0		;put zero at end of data
; check if symlink points to dir
  mov	ebx,lib_buf+200		;buf+200 symlink target
  call	dir_status		;results go to lib_buf [ecx]
mp_exitj:
  js	mp_orphan		;if error then exit
  mov	eax,0f000h
  and	eax,[ecx+stat_struc.st_mode]
  cmp	ah,80h
  mov	al,'@'			;symlink file
  je	mp_50			;jmp if symlink file
;status says we have a directory, but some /dev entires
;give this status if they point to /proc entry. possibly
;other cases, try nlink field?
mp_49:
  mov	al,'~'			;symlink dir
mp_50:
  mov	[symlink_flag],al	;set local flag
;check access to file/dir/symlink
mp_55:
  mov	ebx,lib_buf+200		;buf+200 symlink target
  mov	ecx,4			;R_OK is it ok to read
  mov	eax,33			;access kernel call
  int	80h 			;can we read this dir?
  or	eax,eax
  js	mp_orphan		;exit if error
;check if we can enter directory
  cmp	[symlink_flag],byte '~'	;is this a directory entry
  jne	mp_file			;jmp if not dir
;check if we can switch to new dir
  mov	ebx,lib_buf+200		;buf+200 symlink target
  call	dir_change
;restore origional directory
  push	eax
  mov	ebx,lib_buf+400		;buf+400 origional path
  call	dir_change
  pop	eax			;restore results of dir change
  or	eax,eax
  js	mp_orphan		;exit if access failed
;directory access ok
  mov	al,'2'		;sort for sym dir
  mov	ah,'~'
  jmp	short mp_exit
mp_file:
  mov	al,'7'		;sym link file
  mov	ah,'@'
  jmp	short mp_exit
mp_orphan:
  mov	al,'8'
  mov	ah,'!'
mp_exit:
  ret

;--------
  [section .data]
symlink_flag:	db 0	;"@"=file "~"=dir
  [section .text]
;-----------------------------------------------------------------
; build path for execution or open
;  input: edi = filename
;         esi = path base ending with '/'
;
build_path1:
  lodsb
  cmp	al,0
  jne	build_path1	;loop till end of path
  dec	esi
bpp_lp1:
  cmp	byte [esi],'/'
  je	bpp_append
  dec	esi
  jmp	short bpp_lp1	;scan back till '/' found
bpp_append:
  xchg	esi,edi
  inc	edi		;move past '/'
bpp_lp2:
  lodsb
  stosb
  cmp	al,0
  jne	bpp_lp2		;loop till name appended
  ret

  [section .data]
our_path	dd	0
  [section .text]

;---------------------------------------------------------------
;-----------------------------------------------
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

  extern read_stdin
  extern mouse_enable
  extern kbuf  
  extern crt_line
  extern key_decode1
  extern crt_set_color

struc popup
.mtext resd 1	;menu test with embedded colors
.mcols  resb 1	;total columns
.mrows  resb 1	;total rows
.mcol	resb 1	;starting col
.mrow	resb 1	;starting row
.mcolor1 resd 1 ;normal color
.mcolor2 resd 1 ;button color
.mcolor3 resd 1 ;select bar color
endstruc

;----------------------
;>1 widget
;   popup_menu - popup menu box and wait for key/click
; INPUTS
;    ebp = ptr to popup menu definition, as follows:
;
;        dd menu text ending with zero byte
;        db columns in window
;        db rows in window
;        db starting col
;        db starting row
;        dd normal color (color 1)
;        dd button color (color 2)
;        dd select bar button color (color 3)
;
;     menu text consists of lines ending with 0ah, the last
;     line ends with 0.  Lines can have embedded color codes
;     using byte values of 1,2,3.
;     The box is separated from rest of display by its color,
;     the "normal color" is used to form box"
;
; OUTPUT
;    eax = zero if no selection was made
;        = ptr to start of selected row
;    ecx = selection number times 4, if selection made,
;          first selection number is 0, next is 4, etc.
;
; NOTES
;    file popup_menu.asm
;    1. menu text can have one blank line at top.
;    2. menu items can have blank lines between entries
;    3. normal color is asserted at start of each new line
;        
;<
;  * ---------------------------------------------------
;*******
  global popup_menu
popup_menu:
  cld
  call	mouse_enable
;setup intitial row and line number
  mov	[menu_select_line],byte 0	;
  mov	eax,[ebp + popup.mtext]
pm_set_lp:
  cmp	[eax],byte 0ah			;blank line here?
  ja	pm_set				;jmp if first valid line found
  je	pm_adjust1			;jmp if blank line at select ptr
;first char must be color code, keep checking for blank line
  cmp	[eax+1],byte 0ah
  ja	pm_set				;jmp if first line valid
  add	eax,2				;move to next line
  jmp	short pm_set
pm_adjust1:
  inc	eax
pm_set:
  mov	[menu_select_ptr],eax
;build select color list
  mov	eax,[ebp+popup.mcolor1]		;get normal color
  mov	[select_colors],eax
  mov	eax,[ebp+popup.mcolor3]		;get select button color
  mov	[select_colors+4],eax
pm_lp:
  call	display_wind
; get keyboard input
fb_ignore:
  call	read_stdin
  cmp	byte [kbuf],-1		;check if mouse
  je	fb_mouse
;decode key
  mov	edx,kbuf
  mov	esi,key_decode_table3
  call	terminfo_key_decode1
  jmp	short fb_cont
;decode mouse click
fb_mouse:
  mov	bl,[kbuf+2]		;get mouse column
  mov	bh,[kbuf+3]		;get mouse row
  call	mouse_decode_
  or	eax,eax
  jz	pm_lp			;ignore unknown clicks
  jmp	short fb_exit1
fb_cont:
  push	ebp
  call	eax
  pop	ebp
  cmp	al,-1
  je	pm_lp
  or	eax,eax
  jz	fb_exit2
fb_exit:
  mov	eax,[menu_select_ptr]
  xor	ecx,ecx
  mov	cl,[menu_select_line]
fb_exit1:
  shl	ecx,2
fb_exit2:
  ret
;---------------------------------
;INPUTS
; [ebp+popup]			;struc
; menu_select_line: db 0	;current select line index 0,1,2
; menu_select_ptr:  dd 0	;pointer to selected line
fb_up:
  mov	esi,[menu_select_ptr]
fb_up1:
  cmp	esi,[ebp + popup.mtext]
  je	fb_up_exit		;exit if at top
  call	prev_line		; output: esi = ptr to next line
;                                 carry = at top now
;                                 no-carry = not at top
  call	is_blank		;blank line
  je	fb_up1
fb_up_success:
  mov	[menu_select_ptr],esi
  dec	byte [menu_select_line]

fb_up_exit:
  mov	al,-1   
  ret

;-----------------------
;INPUTS
; [ebp+popup]			;struc
; menu_select_line: db 0	;current select line index 0,1,2
; menu_select_ptr:  dd 0	;pointer to selected line
fb_down:
  mov	esi,[menu_select_ptr]
fb_down1:
  cmp	[esi],byte 0
  je	fb_down_exit		;exit if can't go down
  call	next_line               ; output: esi = ptr to next line
;                                 carry = at bottom 
  jc	fb_down_exit		;exit if cant go down
  call	is_blank
  je	fb_down1		;jmp if blank line
fb_down_success:
  mov	[menu_select_ptr],esi
  inc	byte [menu_select_line]
fb_down_exit:
  mov	al,-1
  ret

;-----------------------
enter_key:
  mov	eax,[menu_select_ptr]
  ret
;-----------------------
quit:
  xor	eax,eax
  mov	[menu_select_ptr],eax
  ret
;-----------------------
unknown_key:
  xor	eax,eax
  ret
;----------------------------------------------
; input: esi = ptr to line start
; output: esi = ptr to next line
;         carry = at top now
;        no-carry = not at top
;
prev_line:
  cmp	esi,[ebp + popup.mtext]	;check if at top
  jbe	pl_top
  dec	esi
  cmp	esi,[ebp + popup.mtext]	;check if at top
  je	pl_top
  cmp	byte [esi -1],0ah
  jne	prev_line
  clc
  jmp	short pl_exit
pl_top:
  stc
pl_exit:
  ret
  
;----------------------------------------------
; input: esi = ptr to current line start
; output: esi = ptr to next line
;         carry = at bottom 
next_line:
  cmp	[esi],byte 0
  je	nl_end		;jmp if at end
  lodsb
  cmp	al,0ah
  jne	next_line
  clc
  jmp	short nl_exit
nl_end:
  stc	
nl_exit:
  ret

;----------------------------------------------
; input: esi=text ptr
; output: equal flag set if blank line (je)
is_blank:
  push	esi
is_blank_lp:
  lodsb
  or	al,al
  je	is_blank_exit	;exit if end of line
  cmp	al,0ah
  je	is_blank_exit	;jmp if blank line
  cmp	al,20h		;non text char
  jbe	is_blank_lp	;jmp if non-text char
is_blank_exit:
  pop	esi
  ret

;----------------------------------------------
;find text at mouse click
;
; input; bl = column
;        bh=row 1 based
;        ebp = popup struc ptr
; output: eax = start of line where click occured
;               else zero if click elsewhere
;
mouse_decode_:
  cmp	bl,[ebp+popup.mcol]	;check if inside window
  jb	mk_fail			;exit if left of window
  cmp	bh,[ebp+popup.mrow]
  jb	mk_fail			;exit if above first row
  
  mov	esi,[ebp + popup.mtext]
  xor	ecx,ecx
  dec	ecx			;setup for loop
  inc	bh			;adjust row
md_loop1:
  call	is_blank
  je	skip_index
  inc	ecx
skip_index:
  dec	bh			;decrement row
  cmp	bh,[ebp+popup.mrow]	;check if at click row
  jnz	md_loop2		;jmp if still looking
  call	is_blank
  je	mk_fail			;jmp if blank line
  jmp	short mk_got		;jmp if valid line
md_loop2:
  lodsb
  cmp	al,0ah
  je	md_loop1		;jmp if end of line
  or	al,al
  jne	md_loop2		;loop if not end of text
mk_fail:
  xor	eax,eax
  jmp	short mk_end2
mk_got:
  mov	eax,esi
;failure, click not found on valid entry
mk_end2:
  ret  
;----------------------------------------------

;--------------------------------------------------------------
; display_wind
;  input: ebp = struc ptr
;         [menu_select_ptr]

display_wind:
  mov	ch,[ebp + popup.mrow]	;starting row
  mov	dl,[ebp + popup.mcols]	;max line length
  mov	esi,[ebp + popup.mtext]	;display data ptr
  mov	dh,[ebp + popup.mrows]	;max rows to display
dw_lp:
  lea	ebx,[ebp+popup.mcolor1]	;color list
  mov	cl,[ebp + popup.mcol]	;starting col
  push	ebx
  push	ecx
  push	edx
  cmp	esi,[menu_select_ptr]	;is this select line
  jne	dw_show			;jmp if not select ptr
  mov	ebx,select_colors	;adjust colors for select
dw_show:
  xor	edi,edi			;scroll = 0 
  call	crt_line
  mov	eax,[ebp+popup.mcolor1]
  call	crt_set_color		;restore normal color
  pop	edx
  pop	ecx
  pop	ebx
  cmp	byte [esi-1],0ah	;did we reach end of line?
  je	dw_tail
  cmp	byte [esi],0ah		;are we at end of data
  jb	dw_tail
;scan to end of line
dw_scan:
  lodsb
  cmp	al,0ah			;scan to end of line
  ja	dw_scan
dw_tail:
  inc	ch		;move to next row
  dec	dh
  jz	dw_end		;jmp if end of window
  cmp	byte [esi],0	;check if at end of data
  jne	dw_lp		;jmp if another line available
  mov	esi,dummy_line
  jmp	short dw_lp
dw_end:
  ret

;===========================================================
  [section .data]

dummy_line:
  db	0ah,0

key_decode_table3:
  dd	unknown_key	;alpha key

  db 1bh,5bh,41h,0		;15 pad_up
  dd fb_up

  db 1bh,4fh,41h,0		;15 pad_up
  dd fb_up

  db 1bh,4fh,78h,0		;15 pad_up
  dd fb_up

  db 1bh,5bh,42h,0		;20 pad_down
  dd fb_down

  db 1bh,4fh,42h,0		;20 pad_down
  dd fb_down

  db 1bh,4fh,72h,0		;20 pad_down
  dd fb_down


  db 1bh,0			;ESC
  dd quit

  db 0dh,0			;enter key
  dd enter_key

  db 0ah,0			;enter key
  dd enter_key

  db 0		;enc of table
  dd unknown_key ;unknown key trap
  
;----------------------------------------------

menu_select_line: db 0	;current select line index 0,1,2
menu_select_ptr:  dd 0	;pointer to selected line

select_colors:
  dd 0	;normal line color (color 1)
  dd 0	;select bar button color

  [section .text]
;---------------------------------------------------------------

%ifdef DEBUG
  global main,_start
main:
_start:
  nop
  mov	ebp,test_data
  call	popup_menu

  mov	eax,1
  int	byte 80h
;--------
  [section .data]
test_data:
  dd	menu_text
  db	30		;columns
  db	15		;rows
  db	3		;starting col
  db	5		;starting row
  dd	30003634h	;normal color
  dd	30003436h	;button color
  dd	31003037h	;select bar color

menu_text:
terminal_menu: db 1,0ah
 db 1
 db ' ',2,'terminal intro',1,0ah,0ah
 db ' ',2,'ascii characters',1,' character encoding',0ah,0ah
 db ' ',2,'ascii controls',1,' vt sequences',0ah,0ah
 db ' ',2,'termios',1,' terminal setup',0ah,0ah
 db 0ah,0ah
 db 0ah,0ah
 db ' ',2,'-back- (ESC)',1,0ah
 db 0

%endif

  [section .text]


;-------- tools.inc ------------
;
tools_popup:
  mov	esi,tp_msg
  mov	eax,tp_list
  mov	[menu_block],esi
  mov	[process_ptrs],eax
sm_loop:
  mov	ebp,menu_block
  call	popup_menu
  or	eax,eax
  jnz	do_selection

  mov	esi,key_table
  mov	edx,kbuf
  call	terminfo_key_decode1
  call	eax
  jmp	short sm_exit
do_selection:
  add	ecx,tp_list
  call	[ecx]
sm_exit:
  ret

tp_list:
 dd t_reference
 dd t_color
 dd t_dis
 dd t_src
 dd t_timer
 dd t_plan
 dd t_key_echo
 dd t_key_proj
 dd t_key_make
 dd t_key_debug
 dd t_exit
;------------------------------
;alt-i
t_reference:
  cmp	[t_mod1],byte '?';is this file available?
  je	t_ref_exit	;exit if program unavailable

  mov	esi,asmref		;command
  mov	bh,0			;no parameters
  call	launch
t_ref_exit:
  mov	al,1
  ret
;---------
  [section .data]
asmref:   db 'asmref',0
asmref_pad db 0,0,0,0,0,0
  [section .text]
;-----------------------------------  
t_color:
  cmp	[t_mod2],byte '?';is this file available?
  je	t_color_exit	;exit if program unavailable

  mov	esi,asmcolor		;command
  mov	bh,0			;feed_big_wait_prompt
  call	launch
t_color_exit:
  mov	al,1
  ret
;---------
  [section .data]
asmcolor:   db 'asmcolor',0
asmcolor_pad db 0,0,0,0,0
  [section .text]
;-----------------------------------  
t_dis:
  cmp	[t_mod3],byte '?';is this file available?
  je	t_dis_exit	;exit if program unavailable
  mov	esi,dis_legal
  call	check_file
  jz	t_dis_exit			;exit if illegal file type

  mov	esi,asmdis		;command
  mov	bh,p1_sel+p_eol		;one parameter, select ptr
  call	launch
t_dis_exit:
  mov	al,1
  ret
;---------
  [section .data]
dis_legal db '*',0
asmdis:   db 'asmdis',0
asmdis_pad db 0,0,0,0,0,0
  [section .text]
;-----------------------------------  
t_src:
  cmp	[t_mod4],byte '?';is this file available?
  je	t_src_exit	;exit if program unavailable
  mov	esi,src_legal
  call	check_file
  jz	t_src_exit			;exit if illegal file type

  mov	esi,asmsrc		;command
  mov	bh,p1_sel	;one parameter, select ptr
  call	launch
t_src_exit:
  mov	al,1
  ret
  [section .data]
src_legal db '*',0
asmsrc:   db 'asmsrc',0
asmsrc_pad db 0,0,0,0,0,0
  [section .text]
;-----------------------------------  
t_timer:
  cmp	[t_mod5],byte '?';is this file available?
  je	t_tim_exit	;exit if program unavailable

  mov	esi,asmtimer		;command
  mov	bh,p1_sel+p_clr		;one parameter, select ptr
  call	launch
t_tim_exit:
  mov	al,1
  ret
  [section .data]
asmtimer: db 'asmtimer',0
asmtimer_pad db 0,0,0,0,0
  [section .text]
;-----------------------------------  
t_plan:
  cmp	[t_mod6],byte '?';is this file available?
  je	t_plan_exit	;exit if program unavailable

  mov	esi,asmplan		;command
  mov	bh,0			;
  call	launch
t_plan_exit:
  mov	al,1
  ret
  [section .data]
asmplan:  db 'asmplan',0
asmplan_pad db 0,0,0,0,0,0
  [section .text]
;-----------------------------------  
t_key_echo:
  cmp	[t_mod7],byte '?';is this file available?
  je	t_key_exit	;exit if program unavailable

  mov	esi,key_echo		;command
  mov	bh,p_clr
  call	launch
t_key_exit:
  mov	al,1
  ret
  [section .data]
key_echo: db 'key_echo',0
key_echo_pad db 0,0,0,0,0,0,0,0
  [section .text]
;-----------------------------------  
t_key_proj:
  cmp	[t_mod8],byte '?';is this file available?
  je	t_proj_exit	;exit if program unavailable

  mov	esi,asmproject		;command
  mov	bh,0			;
  call	launch
t_proj_exit:
  mov	al,1
  ret

  [section .data]
asmproject: db 'asmproject',0
asmproject_pad db 0,0,0,0,0,0
  [section .text]
;-----------------------------------  
t_key_make:
  cmp	[t_mod9],byte '?';is this file available?
  je	t_make_exit	;exit if program unavailable

  mov	esi,make  		;command
  mov	bh,p_eol		;one parameter, select ptr
  call	launch
t_make_exit:
  mov	al,1
  ret
  [section .data]
make:	db 'make',0
make_pad db 0,0,0,0,0,0,0
  [section .text]
;-----------------------------------  
  extern sys_run_wait
t_key_debug:
  cmp	[t_mod10],byte '?';is this file available?
  je	t_debug_exit	;exit if program unavailable
  mov	esi,debug_legal
  call	check_file
  jz	t_debug_exit			;exit if illegal file type

  mov	esi,debug  		;command
  mov	bh,p_eol+p1_sel		;one parameter, select ptr
  call	launch
t_debug_exit:
  mov	al,1
  ret

  [section .data]
debug_legal db '*',0
debug:	db 'asmbug',0
debug_pad db 0,0,0,0,0,0
  [section .text]
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
  pop	ecx
  loop	flush_l
  ret
;-----------------------------------  
t_exit:
  ret

  [section .data]
;
tp_msg: db 1,0ah
 db ' ',2,'Info (AsmRef)  - '
t_mod1	db 'alt-i',1,0ah,0ah
 db ' ',2,'Colors         - '
t_mod2	db 'alt-c',1,0ah,0ah
 db ' ',2,'Un-assembler   - '
t_mod3	db 'alt-u',1,0ah,0ah
 db ' ',2,'Sourceer       - '
t_mod4	db 'alt-a',1,0ah,0ah
 db ' ',2,'Execution timer- '
t_mod5	db 'alt-e',1,0ah,0ah
 db ' ',2,'Planner        - '
t_mod6	db 'alt-p',1,0ah,0ah
 db ' ',2,'keyboard echo  - '
t_mod7	db 'alt-k',1,0ah,0ah
 db ' ',2,'project        - '
t_mod8	db 'alt-j',1,0ah,0ah
 db ' ',2,'make           - '
t_mod9	db 'alt-m',1,0ah,0ah
 db ' ',2,'debug          - '
t_mod10	db 'alt-d',1,0ah,0ah
 db ' ',2,'-cancel-       - esc',1,0ah,0ah,0


;------
  [section .data]

process_ptrs dd 0	;ptr to process list

menu_block:
  dd 0		;text
  db 40		;total columns
  db 23		;total rows
  db 9		;starting column
  db 1		;starting row
menu_colors:
  dd	30003436h	;normal color
  dd	30003634h	;button color
  dd	31003037h	;select bar color
  

  [section .text]

;---------------------------------------------------------------
;-----------------------------------------------
;%include "get_cursor.inc"
;---------------------------------------------------------------
;%include "asmfile_plugins.inc"
;------------- asmfile_plugins.inc ----------------------

  extern env_exec
  extern enviro_ptrs

check_available_plugins:
  mov	ebx,[enviro_ptrs]
  mov	ebp,[scripts_ptr]
  call	env_exec	;carry=not found
  jnc	move_name	;jmp if script found
  mov	ebx,[enviro_ptrs]
  mov	ebp,[plugins_ptr]
  call	env_exec	;carry=not found
  jnc	move_name	;jmp if name found
;neither name or script was found, put "????" in button
  mov	eax,'????'
  mov	ebx,[plug_zap_ptr]
  mov	ebx,[ebx]
  mov	[ebx],eax
  jmp	short next_plugin
move_name:
  mov	esi,ebp
  mov	edi,[exec_zap_ptr]
  mov	edi,[edi]
  call	str_move
  mov	al,' '
  stosb			;put space at end
next_plugin:
  add	[plug_zap_ptr],dword 4
  add	[exec_zap_ptr],dword 4

  mov	esi,[plugins_ptr]
  call	str_end
  inc	esi
  mov	[plugins_ptr],esi

  mov	esi,[scripts_ptr]
  call	str_end
  inc	esi
  mov	[scripts_ptr],esi

  mov	eax,[plug_zap_ptr]
  mov	eax,[eax]
  or	eax,eax
  jnz	check_available_plugins
  ret

;-----------------------------
  [section .data]

plugins_ptr	dd	plugins
scripts_ptr	dd	scripts
plug_zap_ptr	dd	plugin_zap
exec_zap_ptr	dd	executable_zap

;plugin names
plugins:
	db	'fileset',0
	db	'asmref',0
	db	'asmcolor',0
	db	'asmdis',0
	db	'asmsrc',0
	db	'asmtimer',0
	db	'asmplan',0
	db	'asmproject',0
	db	'make',0
	db	'key_echo',0
	db	'asmbug',0
	db	'asmfind',0
	db	'/usr/share/asmfile/viewer',0
	db	'asmedit',0
	db	'/usr/share/asmfile/upak',0
	db	'/usr/share/asmfile/pak',0
	db	'/usr/share/asmfile/compar',0
	db	'/usr/share/asmfile/print',0
scripts:
	db	'asmfile_chmod',0
	db	'asmfile_docs',0
	db	'asmfile_colors',0
	db	'asmfile_dis',0
	db	'asmfile_src',0
	db	'asmfile_timer',0
	db	'asmfile_plan',0
	db	'asmfile_project',0
	db	'asmfile_make',0
	db	'asmfile_key_echo',0
	db	'asmfile_debug',0
	db	'asmfile_find',0
	db	'asmfile_view',0
	db	'asmfile_edit',0
	db	'asmfile_upak',0
	db	'asmfile_pak',0
	db	'asmfile_compare',0
	db	'asmfile_print',0

;this table points to text on buttons.  If executable isn't
;available, this area is set to "????"
plugin_zap:
	dd	mid_status_key+1	;put "????" here if not available
	dd	t_mod1			;asmref
	dd	t_mod2			;asmcolor
	dd	t_mod3			;asmdis
	dd	t_mod4			;asmsrc
	dd	t_mod5			;asmtimer
	dd	t_mod6			;asmplan
	dd	t_mod8			;asmproj
	dd	t_mod9			;'make',0
	dd	t_mod7			;'key_echo',0
	dd	t_mod10			;'asmbug',0
	dd	mid_find_key+1
	dd	mid_view_key+1
	dd	mid_edit_key+1
	dd	mid_unpack_key+1
	dd	mid_tar_key+1
	dd	mid_compare_key+1
	dd	mid_print_key+1
	dd	0			;end of list
;test table points to executable called, it will be set to
;either script or executable name
executable_zap:
	dd	f1_header	;asmfile_chmod
	dd	asmref		;asmfile_docs
	dd	asmcolor	;asmfile_colors
	dd	asmdis		;asmfile_dis
	dd	asmsrc		;asmfile_src
	dd	asmtimer	;asmfile_timer
	dd	asmplan		;asmfile_plan
	dd	asmproject	;asmfile_project
	dd	make		;asmfile_makea
	dd	key_echo	;asmfile_key_echo
	dd	debug		;asmfile_debug
	dd	f2_header	;asmfile_find
	dd	f3_header	;asmfile_view
	dd	f4_header	;asmfile_edit
	dd	f9_header	;asmfile_upak
	dd	f10_header	;asmfile_pak
	dd	f11_header	;asmfile_compare
	dd	f12_header	;asmfile_print

  [section .text]

;---------------------------------------------------------------

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
;%define DEBUG
%undef DEBUG
%define LIBRARY

  [section .text]  
;-------------------------------------------

  extern  move_cursor
  extern  read_stdin
  extern  kbuf
  extern  key_decode1
  extern  crt_columns,crt_rows
  extern  read_window_size
  extern  crt_write
  extern  crt_set_color

struc strdef
._data_buffer_ptr    resd 1 ;+0    cleared or preload with text
._buffer_size        resd 1 ;+4    buffer size, must be >= window size
._color_ptr          resd 1 ;+8    (see file crt_data.asm)
._display_row        resb 1 ;+12   ;row (1-x)
._display_column     resb 1 ;+13   ;column (1-x)
._initial_cursor_col resb 1 ;+15   ;must be within data area
._window_size        resd 1 ;+16   bytes in window
._scroll             resd 1 ;      adjustment to start of data (window scroll)
endstruc

;****f* key_mouse/key_string1 *
; NAME
;>1 terminal
;  get_text - get string in scrolled window line
;    Read string into buffer using optional window size.
;    Unknown keys can be returned to caller for processing
;    or ignored by get_text.
; INPUTS
;    ebp= pointer to table with following structure:
;
;    struc strdef
;    ._data_buffer_ptr    resd 1 ;+0    blanked or preload with text
;    ._buffer_size        resd 1 ;+4    buffer size, > or = window_size
;    ._color ptr          resd 1 ;+8    (see file crt_data.asm)
;    ._display_row        resb 1 ;+12   ;row (1-x)
;    ._display_column     resb 1 ;+13   ;column (1-x)
;    ._initial_cursor_col resb 1 ;+15   ;must be within data area
;    ._window_size        resd 1 ;+16   bytes in window
;    ._scroll             resd 1 ;+20   window scroll right count
;    endstruc
;
;    note: the input block is updated by get_text and must
;          be writable.  This allows get_text entry to continue
;          from last entry when called over and over.
;
;    note: get_text is always in insert mode.
;    
;    note: The Initial cursor column must equal the display column
;      or within the range of "display_column" + window_size"
;      Thus, if "display_column=5" and "window_size"=2 then
;      "initial cursor" can be 5 or 6
;      If window_size extends beyond physical right edge of screen
;      it will be truncated.
;
;    note: the initial buffer is assumed to contain text or
;          blanks.  At exit the whole buffer is retruned with
;          edits.
;           
; OUTPUT
;    ebp=pointer to input table (unchanged)
;    [kbuf] has key press that caused exit
;           -1 if mouse
;           -2 if signal hup,winch
;           -3 if error
;
;    note: get_text uses right/left arrow, rubout, del
;          home, end, and mouse click within window.  All
;          other non-text data will force exit.
;
; EXAMPLE
;    call  mouse_enable	;library call to enable mouse
;    mov  ebp,string_block
;  key_loop:
;    call get_text
;
;    [section .data]
;   string_block:
;   data_buffer_ptr    dd buf ;+0    cleared or preload with text
;   buffer_size        dd 100 ;+4    buffer size
;   color_ptr          dd color1 ;+8    (see file crt_data.asm)
;   display_row        db   1 ;+12   ;row (1-x)
;   display_column     db   1 ;+13   ;column (1-x)
;   initial_cursor_col db   1 ;+15   ;must be within data area
;   window_size        dd  80 ;+16   bytes in window
;   scroll             dd   0 ;+20   no scroll initially
;
;   color1 dd 30003730h
;   buf times buffer_size db ' '
;
; NOTES
;   source file: get_text.asm
;   see also, get_string
;<
; * ----------------------------------------------
;*******

  global get_text
get_text:
  call	initialize
gs_loop:
  call	display_string
  mov	al,[ebp+strdef._initial_cursor_col]
  mov	ah,[ebp+strdef._display_row]
  call	move_cursor			;position cursor
;read keyboard
gt_wait:
  mov	[key_evn],word POLLIN + POLLPRI
  mov	ebx,pollfd
  mov  ecx,1        ;number of elements in pollfd
  mov  edx,-1	;wait forever
  call	sys_poll
  jns	key_waiting
  cmp	eax,-4	;did a signal interrupt?
  je	sig_event  
  mov	[kbuf],byte -3
  jmp	gs_exit
sig_event:
  mov	[kbuf],byte -2
  jmp	gs_exit
key_waiting:
  test	[key_rev],word POLLIN + POLLPRI
  jz	gt_wait 
  mov	eax,3
  mov	ebx,0
  mov	ecx,kbuf
  mov	edx,20
  int	byte 80h
  or	eax,eax
  js	key_waiting
  add	ecx,eax
  mov	[ecx],byte 0	;terminate char
  call	mouse_check
;  call	read_stdin
;decode keys or clicks
  cmp	byte [kbuf],-1
  jne	gs_30				;jmp if not mouse click
  mov	al,[ebp+strdef._display_row]
  cmp	byte [kbuf + 3],al		;check if mouse click on edit line
  jne	gs_exit				;jmp if mouse not on edit line
gs_20:
  call	process_mouse
  jmp	short gs_40			;go look at exit code
;process key press
gs_30:
  cmp	[kbuf],byte '%'
  jne	gs_38				;jmp if not %
;replace % with path
  mov	esi,[active_win_ptr]
  lea	esi,[esi+win.win_select_path]
gs_mv_lp:
  lodsb
  or	al,al
  jz	gs_loop				;continue to next key
  mov	[kbuf],al			;feed char to gs_normal_char
  push	esi
  call	gs_normal_char
  pop	esi
  jmp	short gs_mv_lp
;decode char and get process to handle
gs_38:
  mov	edx,kbuf
  mov	esi,key_action_tbl
  call	terminfo_key_decode1
  call	eax
;any non zero return tells us to exit
gs_40:
  or	al,al
  jns	gs_loop				;loop for another key
;exit and return registers
gs_exit:
  mov	ah,[ebp+strdef._initial_cursor_col]
  ret

;------------------------------------------------
; keyboard processing
;------------------------------------------------
unknown_input:
  mov	al,-1
  ret
;-------------
gs_normal_char:
  mov	ebx,[buf_end]
  mov	eax,[str_ptr]
  dec	ebx
  cmp	eax,ebx      			;check if room for another char
  jb	gs_10				;jmp if room
;we are at end of buffer, stuff and exit
  mov	bl,[kbuf]
  mov	[eax],bl
  jmp	short gs_right_exit		;
;
; make hole to stuff char
;
gs_10:
  std
  mov	edi,[buf_end]
  dec	edi
  mov	esi,edi
  dec	esi
gs_21:
  movsb
  cmp	edi,eax				;are we at hole
  jne	gs_21
  cld
  mov	al,[kbuf]			;get char
  mov	byte [edi],al
;-----------------
gs_right:
  mov	esi,[str_ptr]
  inc	esi
  cmp	esi,[buf_end]			;check if buffer ok
  jae	gs_right_exit			;jmp if no more buffer

  mov	al,[ebp+strdef._initial_cursor_col]
  cmp	al,[win_end_col]
  je	gs_right_scroll			;jmp if at right edge
;display ok to > buffer space ok also
  inc	byte [ebp+strdef._initial_cursor_col]		;move cursor fwd
  inc	dword [str_ptr]			;move ptr fwd
  jmp	short gs_right_exit

gs_right_scroll:
  inc	dword [ebp+strdef._scroll]
  inc	dword [str_ptr]  
gs_right_exit:
  xor	eax,eax			;normal return
  ret

;-----------------
gs_home:
  mov	[ebp+strdef._scroll],dword 0
  mov	eax,[ebp+strdef._data_buffer_ptr]
  mov	[str_ptr],eax
  mov	[ebp+strdef._initial_cursor_col],byte 1
  xor	eax,eax
  ret
;-----------------
gs_end:
;scan to end of string
  mov	esi,[ebp+strdef._data_buffer_ptr]
  mov	bl,[ebp+strdef._display_column]
gs_end_lp:
  cmp	esi,[buf_end]			;check for specail cas at end
  je	gs_end_50
  cmp	bl,[win_end_col]
  jne	gs_end_10			;jmp if not at end of widow
  inc	dword [ebp+strdef._scroll]
  dec	bl
gs_end_10:
  inc	esi
  inc	bl
  jmp	short gs_end_lp
;esi points at end  bl=column  [ebp+strdef._scroll] is updated
gs_end_50:
  cmp	esi,[buf_end]
  jne	gs_end_60			;jmp if not special case
  dec	esi
  cmp	[ebp+strdef._scroll],dword 0
  je	gs_end_55
  dec	dword [ebp+strdef._scroll]
  jmp	short gs_end_60
gs_end_55:
  dec	bl
  jmp	short gs_end_70
gs_end_60:
  mov	[str_ptr],esi
  mov	[ebp+strdef._initial_cursor_col],bl
gs_end_70:
  xor	eax,eax		;normal return
  ret

;-----------------
gs_left:
  mov	eax,[str_ptr]
  cmp	eax,[ebp+strdef._data_buffer_ptr]
  je	gs_left_exit			;jmp if at beginning of buffer
  mov	al,[ebp+strdef._initial_cursor_col]		;get cursor posn
  cmp	al,[ebp+strdef._display_column]
  je	gs_left_scroll			;jmp if at left edge already

  dec	byte [ebp+strdef._initial_cursor_col]
  dec	dword [str_ptr]
  jmp	gs_left_exit

gs_left_scroll:
  cmp	dword [ebp+strdef._scroll],0
  je	gs_left_exit
  dec	dword [ebp+strdef._scroll]
  dec	dword [str_ptr]
gs_left_exit:
  xor	eax,eax		;normal return
  ret

;-----------------
gs_del:
  mov	esi,[str_ptr]
  mov	edi,esi
  inc	esi
  cmp	esi,[buf_end] 
  je	gs_del_stuf			;if at end, just do stuff
gs_del_lp:
  cmp	esi,[buf_end]
  jae	gs_del_stuf
  movsb
  cmp	edi,[buf_end]
  jne	gs_del_lp
gs_del_stuf:
  mov	byte [edi],' '
gs_del_exit:
  xor	eax,eax			;normal return
  ret

;-----------------
gs_backspace:
  mov	esi,[str_ptr]
  mov	edi,esi
  dec	edi
  cmp	esi,[ebp+strdef._data_buffer_ptr] 
  je	gs_bak_exit			;ignore operation if at beginning
gs_bak_lp:
  movsb
  mov	byte [edi],' '			;blank prev. position
  cmp	esi,[buf_end]
  jb	gs_bak_lp			;loop till everything moved
;update pointers and check for scroll
  mov	bl,[ebp+strdef._initial_cursor_col]
  cmp	bl,[ebp+strdef._display_column]	;are we at left edge
  je	gs_bak_20			;jmp if at edge
;normal backspace inside string
  dec	dword [str_ptr]
  dec	byte [ebp+strdef._initial_cursor_col]
  jmp	short gs_bak_exit
;backspace at left edge of window
;we can assume [ebp+strdef._scroll] is non zero because of previous buffer check
gs_bak_20:
  dec	dword [ebp+strdef._scroll]
  dec	dword [str_ptr]
gs_bak_exit:
  xor	eax,eax		;nomral return
  ret

;------------------------------------------------
; set cursor from mouse click
; we know the click occured on edit line, but it may
; not be in our window.
process_mouse:
  mov	al,[kbuf+2]			;get mouse column
  mov	ah,[ebp+strdef._display_column]	;get starting column
  cmp	al,ah
  jb	unknown_input			;exit if left of string
  cmp	al,[win_end_col]		;check window end
  ja	unknown_input			;exit if right of string entery  
;compute new cursor posn
  xor	ecx,ecx
  mov	cl,al				;get click column
  xor	ebx,ebx
  mov	bl,[ebp+strdef._initial_cursor_col]		;get current column
  sub	ecx,ebx
  mov	[ebp+strdef._initial_cursor_col],al		;use mouse click column
  add	[str_ptr],ecx			;adjust pointer
  xor	eax,eax			;normal return
  ret
;------------------------------------------------
;  input:  ebp -> data buffer ptr         +0    (dword)  has zero or preload
;                 buffer_size             +4    (dword)
;                 color ptr               +8    (dword)
;                 display row             +12   (db)	;str display loc
;                 display column          +13   (db)
;          [win_end_col] = end of display
;          [ebp+strdef._scroll] = amount of data to skip over
;          
display_string:
  mov	eax,[ebp+strdef._color_ptr] ;get color ptr
  mov	eax,[eax]		;get color
  call	crt_set_color

  mov	ah,[ebp+strdef._display_row];get row
  mov	al,[ebp+strdef._display_column]	;display column
  call	move_cursor

  mov	ecx,[ebp+strdef._data_buffer_ptr]
  add	ecx,[ebp+strdef._scroll]
  xor	edx,edx
  mov	dl,[ebp+strdef._window_size]
  call	crt_write
  ret
;------------------------------------------------
;check if crt_columns and crt_rows set
;process callers inputs
;check display window size
;clear line or line end

initialize:
  mov	eax,[ebp+strdef._data_buffer_ptr]
  add	eax,[ebp+strdef._buffer_size] ;compute end of buffer
  mov	[buf_end],eax

;check if physical screen size available
  cmp	[crt_columns],byte 0
  jne	init_10
  call	read_window_size
init_10:
  mov	al,[ebp+strdef._window_size]
  add	al,[ebp+strdef._display_column]  ;compute window end
  dec	al			;adjust for testing
;check if win_end_col is legal, (fits our screen)
  cmp	al,[crt_columns]
  jbe	init_18		;jmp if window ok
  mov	al,[crt_columns]
init_18:
  mov	[win_end_col],al

; set str_ptr
  mov	edi,[ebp+strdef._data_buffer_ptr]
  xor	eax,eax
  mov	al,[ebp+strdef._initial_cursor_col]
  sub	al,[ebp+strdef._display_column]
  add	edi,eax
  mov	[str_ptr],edi			;set edit point
  ret

;------------------------------------------------
; This  table is used by get_text to decode keys
;  format: 1. first dword = process for normal text
;          2. series of key-strings & process's
;          3. zero - end of key-strings
;          4. dword = process for no previous match
;
key_action_tbl:
  dd	gs_normal_char		;alpha key process
  db 1bh,5bh,48h,0		; pad_home
   dd gs_home
  db 1bh,5bh,31h,7eh,0		;138 home (non-keypad)
   dd gs_home
  db 1bh,4fh,77h,0		;150 pad_home
   dd gs_home
;  db 1bh,5bh,44h,0		; pad_left
;   dd gs_left
;  db 1bh,4fh,74h,0		;143 pad_left
;   dd gs_left
  db 1bh,5bh,34h,7eh,0		;139 end (non-keypad)
   dd gs_left
;  db 1bh,5bh,43h,0		; pad_right
;   dd gs_right
;  db 1bh,4fh,76h,0		;144 pad_right
;   dd gs_right
  db 1bh,5bh,46h,0		; pad_end
   dd gs_end
  db 1bh,4fh,71h,0		;145 pad_end
   dd gs_end
  db 1bh,5bh,33h,7eh,0		; pad_del
   dd gs_del
  db 1bh,4fh,6eh,0		;149 pad_del
   dd gs_del
  db 7fh,0			; backspace
   dd gs_backspace
  db 80h,0
   dd gs_backspace
  db 08,0			;140 backspace
   dd gs_backspace
  db 0		;end of table
  dd unknown_input		;no-match process


 [section .data align=4]

;-----------------------------------------------------------

buf_end		dd	0	;one location beyond data in buffer
str_ptr		dd	0	;current string edit point
win_end_col	db	0	;window end column (inside window) 

pollfd:
          dd 0	;keyboard input fd
key_evn:  dw POLLIN + POLLPRI	;events of interest (see above)
key_rev:  dw 0	;.revents (events that occured)

app_fd    dd 0	;ptty_fd goes here
app_evn:  dw POLLIN + POLLPRI	;events of interest (see above)
app_rev:  dw 0	;.revents (events that occured)

 [section .text]
;----------------------------------------------------------

  [section .text align=1]
;---------------------
;>1 mouse
;  mouse_decode - associate process with screen area
; INPUTS
;  [kbuf] = mouse data from mouse_check
;  esi = decode table ptr
;        decode table entries:
;                              db (starting col) character
;                              db (ending col) character
;                              db (starting row) character
;                              db [ending row)  character
;                              dd process adr
;                                     .
;                              dd 0 ;end of table
; OUTPUT:
;    eax = 0 if no process found for click area
;          process address if click in table
;    flags set for jz (no process) or jnz (process found)
;              
; NOTES
;   source file: mouse_decode
;<
; * ----------------------------------------------

  global mouse_decode
mouse_decode:
  mov	bx,[kbuf+2]	;bl=col  bh=row
;bl=click column  bh=click row
xmd_loop:
  lodsd        		;get next entry
  or	eax,eax
  jz	xmd_exit	;exit if no button at click
;al=starting column
  cmp	bl,al
  jb	xmd_next
  cmp	bl,ah
  ja	xmd_next
;column matches, check row
  shr	eax,16
  cmp	bh,al
  jb	xmd_next	;jmp if row wrong
  cmp	bh,ah
  ja	xmd_next
  lodsd			;get process
  jmp	short xmd_exit
xmd_next:
  lodsd			;move past process
  jmp	short xmd_loop
xmd_exit:
  or	eax,eax
  ret

 [section .text]
;----------------------------------------------------------------------
display_reset:
  mov	ecx,setup_msg
  call	crt_str
  ret
;---------
  [section .data]
setup_msg: db 1bh,'[r',0fh,1bh,'[!p',1bh,'[?3;4l',1bh,'[4l',1bh,'>',0
  [section .text]
;----------------------------------------------------------------------
keyboard_setup:
  mov	eax,wrap_buf
  call	terminfo_read
  mov	eax,key_table
  call	terminfo_decode_setup
  ret
;----------------------------------------------------------------------
;change directory to active window path
chdir:
  mov	ebp,[active_win_ptr]
;send directory move cmd to kernel
  mov	eax,12	;change dir
  lea	ebx,[ebp+win.win_path]
  int	byte 80h
  ret
;----------------------------------------------------------------------
;input: esi = list of legal file type codes.
;       file at select bar
;output: [status_msg_prt] set if error
;        jz flag set if illegal
;        
check_file:
  mov	ebp,[active_win_ptr]
  mov	ah,[ebp+win.win_select_type]
cf_lp:
  lodsb			;get next legal file type
  cmp	al,ah
  je	cf_exit		;exit if legal
  cmp	al,0
  jne	cf_lp
;we failed to find legal type, ah=current file type
  mov	esi,dr_type
  cmp	ah,'/'		;dir type
  je	cf_got_type	;jmp if dir
  add	esi,byte 8	;move to next entry
  cmp	ah,'~'		;symlink to dir?
  je	cf_got_type
  add	esi,byte 8
  cmp	ah,'='		;socket?  
  je	cf_got_type
  add	esi,byte 8
  cmp	ah,'@'		;symlink? 
  je	cf_got_type
  add	esi,byte 8
  cmp	ah,'*'		;executable?
  je	cf_got_type
  add	esi,byte 8
  cmp	ah,' '		;normal file?
  je	cf_got_type
  add	esi,byte 8
  cmp	ah,'-'		;char device?
  je	cf_got_type
  add	esi,byte 8
  cmp	ah,'+'		;block device?
  je	cf_got_type
  add	esi,byte 8
  cmp	ah,'|'		;pipe?  
  je	cf_got_type
  add	esi,byte 8
  cmp	ah,'!'		;orphan?  
  je	cf_got_type
  add	esi,byte 8
;esi points to 8 char. type string
cf_got_type:  
  lodsd			;get first 4 bytes
  mov	[cf_insert],eax ;modify error message
  lodsd
  mov	[cf_insert+4],eax ;finish inserting type
  mov	eax,cf_msg	;get message ptr
  mov	[status_msg_ptr],eax	;enable error msg
  xor	eax,eax		;set fail flag
 
cf_exit:
  or	al,al		;set zero flag if illegal
  ret
;----------------------------------------------------------------------

struc termios_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termios_struc_size:

;----------------------------------------------------------------------
  [section .data]
;----------------------------------------------------------------------
cf_msg: db 2,'Illegal file selected, type = '
cf_insert:   db '        ',0
dr_type:     db 'dir     '
             db 'dir link'
             db 'socket  '
             db 'symlink '
             db 'execute '
             db 'file    '
             db 'char dev'
             db 'blk dev '
             db 'pipe    '
             db 'orphan  '
             db 'error   '  ;should never access here, program error!
;--------------

def_begin	equ	-1
def_or		equ	-2
def_and		equ	-3
def_end		equ	-4

key_table:
  times 3*8 db 0	;padding
  db	1		;key_decode1 format

  dd	shell_action	;error state?

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

  db def_begin
  dw 218
  dd book1
  db def_or
    db 1bh,4fh,32h,50h,0	;shift-f1
  dd	book1
    db 1bh,5bh,31h,3bh,32h,50h,0
  dd	book1
  db def_end

  db def_begin
  dw 219
  dd book2
  db def_or
    db 1bh,4fh,32h,51h,0	;shift-f2
  dd	book2
    db 1bh,5bh,31h,3bh,32h,51h,0
  dd	book2
  db def_end

  db def_begin
  dw 220
  dd book3
  db def_or
    db 1bh,4fh,32h,52h,0	;shift-f3
  dd	book3
    db 1bh,5bh,31h,3bh,32h,52h,0
  dd	book3
  db def_end

  db def_begin
  dw 221
  dd book4
  db def_or
    db 1bh,4fh,32h,53h,0	;shift-f4
  dd	book4
    db 1bh,5bh,31h,3bh,32h,53h,0
  dd	book4
  db def_end

  db def_begin
  dw 222
  dd book5
  db def_or
    db 1bh,5bh,31h,35h,3bh,32h,7eh,0	;shift-f5
  dd	book5
  db def_end

  db def_begin
  dw 223
  dd book6
  db def_or
    db 1bh,5bh,31h,37h,3bh,32h,7eh,0	;shift-f6
  dd	book6
  db def_end

  db def_begin
  dw 224
  dd book7
  db def_or
    db 1bh,5bh,31h,38h,3bh,32h,7eh,0	;shift-f7
  dd	book7
  db def_end

  db def_begin
  dw 225
  dd book8
  db def_or
    db 1bh,5bh,31h,39h,3bh,32h,7eh,0	;shift-f8
  dd	book8
  db def_end

  db def_begin
  dw 226
  dd	book9
  db def_or
    db 1bh,5bh,32h,30h,3bh,32h,7eh,0	;shift-f9
  dd	book9
  db def_end

  db def_begin
  dw 227
  dd book0
  db def_or
    db 1bh,5bh,32h,31h,3bh,32h,7eh,0	;shift-f10
  dd	book0
  db def_end

    db 1bh,'h',0		;alt-h
  dd	help_key
    db 0e8h,0
  dd	help_key 
    db 0c3h,0a8h,0
  dd	help_key

    db 1bh,'q',0		;alt-q 
  dd	quit_key
    db 0f1h,0
  dd	quit_key
    db 0c3h,0b1h,0
  dd	quit_key

    db 3,0			;ctrl-o
  dd	shell_key
    db 0fh,0
  dd	shell_key

    db 1bh,'t',0		;alt-t
  dd	tool_key
    db 0f4h,0
  dd	tool_key
    db 0c3h,0b4h,0
  dd    tool_key

    db 1bh,'i',0		;alt-i
  dd	t_reference
    db 0c3h,0a9h,0
  dd	t_reference

    db 1bh,'c',0		;alt-c
  dd	t_color
    db 0c3h,0a3h,0
  dd	t_color

    db 1bh,'u',0		;alt-u
  dd	t_dis
    db 0c3h,0b5h,0
  dd	t_dis

    db 1bh,'a',0		;alt-a
  dd	t_src
    db 0c3h,0a1h,0
  dd	t_src

    db 1bh,'e',0		;alt-e
  dd	t_timer
    db 0c3h,0a5h,0
  dd	t_timer

    db 1bh,'p',0		;alt-p
  dd	t_plan
    db 0c3h,0b0h,0
  dd	t_plan

    db 1bh,'k',0		;alt-k
  dd	t_key_echo
    db 0c3h,0abh,0
  dd	t_key_echo

    db 1bh,'j',0		;alt-j
  dd	t_key_proj
    db 0c3h,0aah,0
  dd	t_key_proj

    db 1bh,'m',0		;alt-m
  dd	t_key_make
    db 0c3h,0adh,0
  dd	t_key_make

    db 1bh,'d',0		;alt-d
  dd	t_key_debug
    db 0c3h,0a4h,0
  dd	t_key_debug

;  db def_begin
;  dw 66
;  dd f1_key
;  db def_or
    db 1bh,4fh,50h,0		;f1
  dd	f1_key
    db 1bh,5bh,31h,31h,7eh,0	;2 f1
  dd	f1_key
    db 1bh,5bh,5bh,41h,0	;f1
  dd	f1_key
;  db def_end

;  db def_begin
;  dw 68
;  dd f2_key
;  db def_or
    db 1bh,4fh,51h,0		;f2
  dd	f2_key
    db 1bh,5bh,31h,32h,7eh,0	;3 f2
  dd	f2_key
    db 1bh,5bh,5bh,42h,0	;f2
  dd	f2_key
;  db def_end

;  db def_begin
;  dw 69
;  dd f3_key
;  db def_or
    db 1bh,4fh,52h,0		;f3
  dd	f3_key
    db 1bh,5bh,31h,33h,7eh,0	;4 f3
  dd	f3_key
    db 1bh,5bh,5bh,43h,0	;f3
  dd	f3_key
;  db def_end

;  db def_begin
;  dw 70
;  dd f4_key
;  db def_or
    db 1bh,4fh,53h,0		;f4
  dd	f4_key
    db 1bh,5bh,31h,34h,7eh,0	;5 f4
  dd	f4_key
    db 1bh,5bh,5bh,44h,0	;f4
  dd	f4_key
;  db def_end

;  db def_begin
;  dw 71
;  dd f5_key
;  db def_or
    db 1bh,5bh,31h,35h,7eh,0	;6 f5
  dd	f5_key
    db 1bh,5bh,5bh,45h,0	;f5
  dd	f5_key
;  db def_end

;  db def_begin
;  dw 72
;  dd f6_key
;  db def_or
    db 1bh,5bh,31h,37h,7eh,0	;7 f6
  dd	f6_key
;  db def_end

  db def_begin
  dw 73
  dd f7_key
  db def_or
    db 1bh,5bh,31h,38h,7eh,0	;8 f7
  dd	f7_key
  db def_end

  db def_begin
  dw 74
  dd f8_key
  db def_or
    db 1bh,5bh,31h,39h,7eh,0	;9 f8
  dd	f8_key
  db def_end

  db def_begin
  dw 75
  dd f9_key
  db def_or
    db 1bh,5bh,32h,30h,7eh,0	;10 f9
  dd	f9_key
  db def_end

  db def_begin
  dw 67
  dd f10_key
  db def_or
    db 1bh,5bh,32h,31h,7eh,0	;11 f10
  dd	f10_key
  db def_end

  db def_begin
  dw 216
  dd f11_key
  db def_or
    db 1bh,5bh,32h,33h,7eh,0	;12 f11
  dd	f11_key
  db def_end

  db def_begin
  dw 217
  dd f12_key
  db def_or
    db 1bh,5bh,32h,34h,7eh,0	;13 f12
  dd	f12_key
  db def_end

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

    db 0dh,0
  dd	shell_cmd

  db    0			;end of table
  dd	null_action		;no match action



win_state		db 0 ;see struc include
shell_state		db 0 ;see struc include
active_win_ptr	dd left_window ;pointer to active win, left_window or right_widow
inactive_win_ptr dd right_window
status_line_row dd 0
;
;--------------------- start of window database -----------------------

left_window:
left_columns:  db 0
left_rows:     db 0
top_left_row:  db 0
top_left_col:  db 0
ltop_index_ptr dd 0	;ptr to top of index
lselected_ptr   dd 0	;ptr to row currently selected
ldisplay_top_index dd 0 ;display top
left_row_select db 3	 ;selected row (actual display row)
;
left_win_path	times 200 db 0
lwin_select_type db 0   ;type code (char)
lwin_select_path times 200  db 0
;-------------------
mid_window:
mid_buf_end:  dd 0		;end of all data, not just this window
mid_columns:  db 0
mid_rows:     db 0
top_mid_row:  db 0
top_mid_col:  db 0

;-------------------
right_window:
right_columns:  db 0
right_rows:     db 0
top_right_row:  db 0
top_right_col:  db 0
rtop_row_ptr equ $
rtop_index_ptr	dd 0	;top of index list for all records
rselected_ptr   dd 0		;ptr to row currently selected
rdisplay_top_index dd 0
right_row_select db 3 ;selected row (actual display row)
;
right_win_path	times 200 db 0
rwin_select_type db 0   ;type code (char)
rwin_select_path times 200  db 0

;--------------------------------------------------------------------------
;   hex color def: aaxxffbb aa-attr ff-foreground bb-background
;   30-blk 31-red 32-grn 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse
shell_color		dd	30003037h
select_line_colors:
select_line_color	dd	31003736h	;color 1
select_line_size_color	dd	30003036h	;color 2
			dd	30003036h	;color 3 (for executables)

status_line_colors:
			dd	31003730h	;color 1 (normal status
			dd	31003336h	;color 2 (warning color)
			dd	34003036h	;color 3 (big shell menu line)

mid_button_colors:
mid_button_color1	dd	31003730h	;color 1
mid_button_color2	dd	30003037h	;color 2

button_color1:		dd	31003730h	;color 1
button_spacer_color	dd	30003734h	;color 2
button_color2:		dd	31003730h	;bookmark color

dirclr           dd 31003734h ;color of directories in list
linkclr          dd 30003634h ;color of symlinks in list
selectclr        dd 30003436h ;color of select bar
fileclr          dd 30003734h ;normal window color, and list color
execlr           dd 30003234h ;green
devclr           dd 30003334h ;red
miscclr          dd 30003034h ;black

dim_colors:
		dd	31003434h
		dd	31003434h
		dd	31003434h
		dd	31003434h
		dd	31003434h
		dd	31003434h
		dd	31003434h

;note: the app window uses default color, ctrl seq db 1bh,"[0m"
;the following value produces a greyer color, and is used by init.
app_win_color	dd 31003037h


help_msg:
incbin "help.inc"
help_msg_end:	db 0
;------------------------------------------------------------------
  [section .bss]
;------------------------------------------------------------------

shell_pid	resd 1
	
termios:
c_iflag	resd 1
c_oflag resd 1
c_cflag resd 1
c_lflag resd 1
c_line	resd 1
cc_c	resb 19

term_data_size	equ	160
term_data	resb term_data_size	;status line build area

temp_buf_size	equ 400
temp_buf	resb temp_buf_size	;used by display_window


;wrap buf is used to read and write to application using sys_wrap
;it can be used as temp buf 
wrap_buf_size	equ 8096
wrap_buf	resb wrap_buf_size

vt_image_buf_size	equ	2*8096
vt_image_buf	resb vt_image_buf_size

;work buf is used to hold sorted directory data
wrk_buf_ptr	resd 1	;memory basetouch *.asm
