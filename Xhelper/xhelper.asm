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
;------------------ xhelper ---------------------------

  extern env_stack
  extern crt_str,crt_write
  extern file_length_name
  extern m_setup
  extern m_allocate
  extern block_read_all
  extern dword_to_ascii
  extern get_raw_time
  extern list_put_at_front
  extern process_search
  extern process_walk_cleanup
  extern list_get_from_front
  extern file_status_name
  extern sys_fork_run
  extern delay
  extern ascii_to_dword
  extern kill_process
  extern hexascii_to_byte
  extern process_walk
  extern lib_buf
  extern dwordto_hexascii
  extern str_move
  extern blk_find
  
;asmlibx
  extern window_find
  extern x_connect
  extern x_get_geometry
  extern window_move_resize
  extern xtest_fake_input
  extern get_client_list
  extern wm_name
  extern win_associated_pid
  extern x_get_input_focus
  extern activate_window
  extern x_translate_coordinates
  extern x_flush
  extern xtest_move_mouse
  extern xtest_click
  extern xtest_version
  extern x_get_geometry
;
; input:  x-hhelper <cmd-file> <-h>
;         where:
;                <ctrl-file> = name of file with control langage
;                <-h>        = show help
;                <-x>        = use x server window list, default
;                              is to use window manager list.
;
;         note: no parameters results in "state" display

global _start
_start:
  cld
  call	env_stack		;save stack enviornment ptr
  call	m_setup
  call	x_connect
  call	parse_user_parameters	;get file names
  jnc	read_cmds		;jmp if no error
  jmp	xhelper_exit
read_cmds:
  cmp	eax,1			;was this a help/status run
  je	xhelper_exitj		;exit if help/status run
;find size of control file
  mov	ebx,[cmd_filename_ptr]
  call	file_length_name	;return length in eax
  jns	allocate_cmd
  mov	al,3
  call	report_error_pre
xhelper_exitj:
  jmp	xhelper_exit
allocate_cmd:
;allocate memory for control file
  mov	[cmd_buf_length],eax
  mov	[cmd_buf_end_ptr],eax	;start end computation
  call	m_allocate
  jnc	memory_save
  mov	al,2			;memory setup error
  jmp	short errorj
memory_save:
  mov	[cmd_buf_top_ptr],eax
  mov	[cmd_buf_ptr],eax
;  mov	[cmd_buf_restart],eax
  add	[cmd_buf_end_ptr],eax	; end computation
;read command file
  mov	ebx,[cmd_filename_ptr]
  mov	ecx,[cmd_buf_top_ptr]
  mov	edx,[cmd_buf_length]
  call	block_read_all
  jns	init_start

errorj:
  mov	al,3
  call	report_error_pre
  jmp	xhelper_exit
init_start:
  mov	ecx,[goto_label_ptr]
  jecxz	init_time
  mov	esi,ecx
  push	esi
  mov	edi,window_name
  call	str_move
  mov	al,':'
  stosb
  mov	[edi],byte 0		;terminate string

  mov	esi,window_name		;search string
  mov	ebp,[cmd_buf_end_ptr]	;end of search block
  mov	edi,[cmd_buf_top_ptr]	;top of search block
  mov	edx,1			;search forward
  mov	ch,0ffh			;match case
  call	blk_find
  jnc	goto_set		;jmp if label found
  mov	al,13
  call	report_error_pre
  jmp	xhelper_exitj

goto_set:
;we have found label, restart parse
  mov	[cmd_buf_ptr],ebx	;restart parse (goto)
init_time:
  call	set_time		;start timeouts
  call	x_get_input_focus
  js	xhelper_loop
  mov	[our_win_id],eax	;save our window id
  call	x_get_geometry		;get our window location
  mov	eax,[ecx+12]		;get x,y location
  mov	[our_win_location],eax
  mov	eax,[ecx+16]
  mov	[our_win_location+4],eax
xhelper_loop:
  call	lookup_cmd
  jnc	do_cmd
  cmp	esi,[cmd_buf_end_ptr]
  jae	xhelper_exit		;jmp if end of buffer
do_cmd:
  test	[xhelper_status],byte 2	;if skip active?
  jz	cmd_call		;jmp if no skip
;inside "if" and skipping, only process "if" command nesting
  cmp	eax,endif		;if/endif inside skip?
  je	cmd_call		;handle endif
  ja	xhelper_loop		;skip all non-if commands
;save current status if another "if" encountered
  push	esi
  push	eax
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  call	list_put_at_front	;save status
  pop	eax
  pop	esi
  jmp	short xhelper_loop
cmd_call:
  call	eax			;------------- do command -------------
  test	[xhelper_status],byte 081h	;done/error flag
  jz	xhelper_loop

xhelper_exit:
  cmp	[initial_win_sav_flag],byte 0
  jne	exit2			;jmp if no win save
  mov	eax,[our_win_id]
  or	eax,eax
  jz	exit2
  call	activate_window
  mov	eax,[our_win_id]
  mov	esi,our_win_location
  call	window_move_resize
exit2:
  call	x_get_input_focus
  mov	ecx,show_msg2
  call	crt_str		;display eol
  mov	ebx,[xhelper_err#]
  mov	eax,1
  int	byte 80h
;--------
  [section .data]
;cmd_buf_restart:	dd 0	;top of commands
  [section .text]
;----------------------------------------------------------------
;commands
;----------------------------------------------------------------

;----------------------------------------------------------------
if_program:
  call	parse_next_parameter
  push	esi
  jc	if_program_exit
;save current status
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  push	ecx			;save program name str ptr
  call	list_put_at_front	;save status
  pop	ecx			;restore name string ptr
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,program_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if program exists
  mov	ecx,program_name
  mov	eax,work_buf
  mov	ebx,work_buf_size
  call	process_search
  push	eax
  call	process_walk_cleanup
  pop	eax
  or	eax,eax
  js	if_program_error	;jmp if error
  jnz	if_program_exit		;exit if program found
;program was not found, start skip
ip_50:			;not found
  or	[xhelper_status],byte 2	;set -if- skip active
  jmp	short if_program_exit
if_program_error:
  mov	al,5
  call	report_error
if_program_exit:
  pop	esi
  ret
;-------------
  [section .data]
program_name:	times 200 db 0
  [section .text]

;----------------------------------------------------------------
if_no_program:
  call	parse_next_parameter
  push	esi
  jc	ifn_program_exit
;save current status
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  push	ecx			;save program name str ptr
  call	list_put_at_front	;save status
  pop	ecx			;restore name string ptr
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,program_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if program exists
  mov	ecx,program_name
  mov	eax,work_buf
  mov	ebx,work_buf_size
  call	process_search
  push	eax
  call	process_walk_cleanup
  pop	eax
  or	eax,eax
  js	ifn_program_error	;jmp if error
  jz	ifn_program_exit	;exit if program not found
;program was found, start skip
ifn_50:			;not found
  or	[xhelper_status],byte 2	;set -if- skip active
  jmp	short ifn_program_exit
ifn_program_error:
  mov	al,5			;process search error
  call	report_error
ifn_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
if_window:
  call	parse_next_parameter
  push	esi
  jc	iw_program_exit
;save current status
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  push	ecx			;save program name str ptr
  call	list_put_at_front	;save status
  pop	ecx			;restore name string ptr
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,window_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if window exists
  call	get_windows
  js	iw_program_error	;jmp if error
  mov	eax,[ecx]		;get first match
  or	eax,eax
  jnz	iw_program_exit		;exit if window found
;program was not found, start skip
  or	[xhelper_status],byte 2	;set -if- skip active
  jmp	short iw_program_exit
iw_program_error:
  mov	al,6
  call	report_error
iw_program_exit:
  pop	esi
  ret
;---------------------------------
get_windows:
  mov	al,[window_list_flag]	;0=search window mgr titles
  mov	ebx,window_name
  mov	ecx,work_buf
  mov	edx,work_buf_size
  call	window_find		;jns if success
  ret

;-------------
  [section .data]
window_name:	times 200 db 0
  [section .text]

;----------------------------------------------------------------
if_no_window:
  call	parse_next_parameter
  push	esi
  jc	inw_program_error 
;save current status
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  push	ecx			;save program name str ptr
  call	list_put_at_front	;save status
  pop	ecx			;restore name string ptr
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,window_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if window exists
  call	get_windows
;  mov	al,2			;search window mgr titles
;  mov	ebx,window_name
;  mov	ecx,work_buf
;  mov	edx,work_buf_size
;  call	window_find		;jns if success
  js	inw_program_exit	;jmp if error
  mov	eax,[ecx]		;get first match
  or	eax,eax
  jz	inw_program_exit	;exit if window not found
;program was found, start skip
  or	[xhelper_status],byte 2	;set -if- skip active
  jmp	short iw_program_exit
inw_program_error:
  mov	al,6			;program search error
  call	report_error
inw_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
if_file:
  call	parse_next_parameter
  push	esi
  jc	ix_program_exit
;save current status
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  push	ecx			;save program name str ptr
  call	list_put_at_front	;save status
  pop	ecx			;restore name string ptr
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,file_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if file exists
  mov	ebx,file_name
  call	file_status_name	;returns eax negative if no file
  jns	ix_program_exit		;exit if file found
;file was not found, start skip
  or	[xhelper_status],byte 2	;set -if- skip active
  jmp	short ix_program_exit
ix_program_exit:
  pop	esi
  ret
;-------------
  [section .data]
file_name:	times 200 db 0
  [section .text]

;----------------------------------------------------------------
if_no_file:
  call	parse_next_parameter
  push	esi
  jc	inx_program_exit
;save current status
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  push	ecx			;save program name str ptr
  call	list_put_at_front	;save status
  pop	ecx			;restore name string ptr
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,file_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if file exists
  mov	ebx,file_name
  call	file_status_name	;returns eax negative if no file
  js	inx_program_exit	;exit if file not found
;file was not found, start skip
  or	[xhelper_status],byte 2	;set -if- skip active
  jmp	short inx_program_exit
inx_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
if_timeout:
  push	esi
;save current status
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  call	list_put_at_front	;save status
;check if timeout
  cmp	[timeout_flag],byte 0	;timeout?
  jnz	it_exit			;jmp if timeout
  or	[xhelper_status],byte 2	;set -it- skip active, timeout
it_exit:
  pop	esi
  ret
;----------------------------------------------------------------
if_no_timeout:
  push	esi
;save current status
  mov	esi,xhelper_status	;input ptr
  mov	edx,list_block
  call	list_put_at_front	;save status
;check if timeout
  cmp	[timeout_flag],byte 0	;timeout?
  jz	int_exit		;jmp if no timeout
  or	[xhelper_status],byte 2	;set -it- skip active, timeout
int_exit:
  pop	esi
  ret
;----------------------------------------------------------------
endif:
  mov	edx,list_block
  call	list_get_from_front
  js	_endif_error
  mov	eax,[esi]	;get data
  mov	[xhelper_status],eax
  jmp	_endif_exit
_endif_error:
  mov	al,7
  call	report_error
_endif_exit:
  ret

;----------------------------------------------------------------
;the above commands must be first for "if" logic test:
;----------------------------------------------------------------
;----------------------------------------------------------------
run:
  call	parse_next_parameter
  push	esi
  jc	run_program_exit
  call	build_run_data	;ecx=input work_buf = output
  or	eax,eax
  js	run_program_err  
  mov	esi,work_buf
  call	sys_fork_run
  or	eax,eax
  jns	run_program_exit	
run_program_err:
  mov	al,8
  call	report_error
run_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
wait_program:
  mov	[timeout_flag],byte 0
  call	parse_next_parameter
  push	esi
  jc	wp_program_exit
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,program_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if program exists
wp_loop:
  mov	ecx,program_name
  mov	eax,work_buf
  mov	ebx,work_buf_size
  call	process_search
  push	eax
  call	process_walk_cleanup
  pop	eax
  or	eax,eax
  js	wp_program_err		;jmp if error
  jnz	wp_program_exit		;exit if program found
;program was not found, delay and keep looking
  cmp	[micro_timeout_target],dword 0
  je	wp_continue		;jmp if wait forever
;check if timeout has expired
  call	get_time
  cmp	eax,[micro_timeout_target]
  jb	wp_continue
  mov	[timeout_flag],byte 1
  jmp	short wp_program_exit	
wp_continue:
  mov	eax,2
  call	delay
  jmp	wp_loop
wp_program_err:
  mov	al,5		;program search error
  call	report_error
wp_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
wait_no_program:
  mov	[timeout_flag],byte 0
  call	parse_next_parameter
  push	esi
  jnc	wnp_program_save
  jmp	wnp_program_exit
wnp_program_save:
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,program_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if program exists
wnp_loop:
  mov	ecx,program_name
  mov	eax,work_buf
  mov	ebx,work_buf_size
  call	process_search
  push	eax
  call	process_walk_cleanup
  pop	eax
  or	eax,eax
  js	wnp_program_err		;jmp if error
  jz	wnp_program_exit	;exit if program not found
;program was found, is it dead?
  mov	esi,eax
  mov	ecx,100
wnp_find_lp:
  cmp	[esi],dword 'ate:'	;look for state
  je	wnp_state		;jmp if program state found
  inc	esi
  loop	wnp_find_lp
  jmp	short wnp_program_err
wnp_state:
  add	esi,byte 5		;move to program status
;  cmp	[esi],byte 'D'	;disk sleep?
;  je	wnp_program_exit	;exit if disk sleep
  cmp	[esi],byte 'Z'
  je	wnp_program_exit	;exit if zombie
;program was found, delay and keep waiting
  cmp	[micro_timeout_target],dword 0
  je	wnp_continue
;check if timeout has expired
  call	get_time
  cmp	eax,[micro_timeout_target]
  jb	wnp_continue
  mov	[timeout_flag],byte 1
  jmp	short wnp_program_exit	
wnp_continue:
  mov	eax,2
  call	delay
  jmp	wnp_loop
wnp_program_err:
  mov	al,5		;program search error
  call	report_error
wnp_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
wait_window:
  mov	[timeout_flag],byte 0
  call	parse_next_parameter
  push	esi
  jc	ww_program_exit
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,window_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if program exists
ww_loop:
  call	get_windows
;  mov	al,2			;search window mgr titles
;  mov	ebx,window_name
;  mov	ecx,work_buf
;  mov	edx,work_buf_size
;  call	window_find		;jns if success
  js	ww_program_err		;jmp if error
  mov	eax,[ecx]		;get first match
  or	eax,eax
  jnz	ww_program_exit		;exit if window found
;window was not found, start skip
  cmp	[micro_timeout_target],dword 0
  je	ww_continue		;jmp if wait forever
;check if timeout has expired
  call	get_time
  cmp	eax,[micro_timeout_target]
  jb	ww_continue
  mov	[timeout_flag],byte 1
  jmp	short ww_program_exit	
ww_continue:
  mov	eax,2
  call	delay
  jmp	ww_loop
ww_program_err:
  mov	al,6		;window search error
  call	report_error
ww_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
wait_no_window:
  mov	[timeout_flag],byte 0
  call	parse_next_parameter
  push	esi
  jc	wnw_program_exit	;exit if error
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,window_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if program exists
wnw_loop:
  call	get_windows
;  mov	al,2			;search window mgr titles
;  mov	ebx,window_name
;  mov	ecx,work_buf
;  mov	edx,work_buf_size
;  call	window_find		;jns if success
  js	wnw_program_err		;jmp if error
  mov	eax,[ecx]		;get first match
  or	eax,eax
  jz	wnw_program_exit	;exit if window not found
;window was not found, start skip
  cmp	[micro_timeout_target],dword 0
  je	wnw_continue		;jmp if wait forever
;check if timeout has expired
  call	get_time
  cmp	eax,[micro_timeout_target]
  jb	wnw_continue
  mov	[timeout_flag],byte 1
  jmp	short wnw_program_exit	
wnw_continue:
  mov	eax,2
  call	delay
  jmp	wnw_loop
wnw_program_err:
  mov	al,6
  call	report_error
wnw_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
wait_file:
  mov	[timeout_flag],byte 0
  call	parse_next_parameter
  push	esi
  jc	wf_program_exit		;exit if error
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,file_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if file exists
wf_loop:
  mov	ebx,file_name
  call	file_status_name	;returns eax negative if no file
  jns	inx_program_exit	;exit if file found
;file was not found, start skip
  cmp	[micro_timeout_target],dword 0
  je	wf_continue		;jmp if wait forever
;check if timeout has expired
  call	get_time
  cmp	eax,[micro_timeout_target]
  jb	wf_continue
  mov	[timeout_flag],byte 1
  jmp	short wf_program_exit	
wf_continue:
  mov	eax,2
  call	delay
  jmp	wf_loop
wf_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
wait_no_file:
  mov	[timeout_flag],byte 0
  call	parse_next_parameter
  push	esi
  jc	wnf_program_exit
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,file_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if file exists
wnf_loop:
  mov	ebx,file_name
  call	file_status_name	;returns eax negative if no file
  js	inx_program_exit	;exit if file not found
;file was not found, start skip
  cmp	[micro_timeout_target],dword 0
  je	wnf_continue		;jmp if wait forever
;check if timeout has expired
  call	get_time
  cmp	eax,[micro_timeout_target]
  jb	wnf_continue
  mov	[timeout_flag],byte 1
  jmp	short wnf_program_exit	
wnf_continue:
  mov	eax,2
  call	delay
  jmp	wnf_loop
wnf_program_exit:
  pop	esi
  ret
;----------------------------------------------------------------
kill:
  push	esi
  call	parse_next_parameter
  jc	kill_exit		;exit if error
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,program_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if program exists
  mov	ecx,program_name
  mov	eax,work_buf
  mov	ebx,work_buf_size
  call	process_search
  push	eax
  call	process_walk_cleanup
  pop	eax
  or	eax,eax
  js	kill_error		;jmp if error
  jz	kill_error		;jmp if program not found
;get pid for this process
  mov	esi,eax
  mov	ecx,100			;max search length
pid_loop:
  cmp	[esi],dword 'Pid:'
  je	got_pid
  inc	esi
  loop	pid_loop
  jmp	short kill_error
got_pid:
  add	esi,5
  call	ascii_to_dword		;set ecx to pid
  mov	ebx,ecx
  call	kill_process
  jmp	short kill_exit
kill_error:
  mov	al,5			;program search error
  call	report_error
kill_exit:
  pop	esi
  ret
;----------------------------------------------------------------
stop:
  or	[xhelper_status],byte 01h	;done flag
  ret

;----------------------------------------------------------------
;show token text or string
show:
  push	esi
  call	parse_next_parameter
  jc	_show_exit	;exit if error
;sting entered
  mov	ecx,show_msg2
  call	crt_str
;now write string
  mov	ecx,[string_start]
  mov	edx,[string_end]
  sub	edx,ecx		;compute length
  call	crt_write
  jmp	short _show_exit
_show_exit:
  pop	esi
  ret
;----
  [section .data]
show_msg2:	db 0ah,0
  [section .text]
;----------------------------------------------------------------
; command format:  ^move_window ("win") ("x-position") ("y-position")
move_window:
  push	esi
  call	parse_next_parameter	;get window string
  jnc	move_on			;jmp if parse ok
  jmp	move_exit  	;exit if error
move_on:
  push	esi
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,window_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
  pop	esi
;get x position for window
  call	parse_next_parameter
  jc	move_exit
  push	esi
  mov	esi,ecx
  call	ascii_to_dword
  mov	[x_position],cx
  pop	esi
;get y position for window
  call	parse_next_parameter
move_errorj:
  jc	move_exit
  mov	esi,ecx
  call	ascii_to_dword
  mov	[y_position],cx
;check if window exists
  call	get_windows
;  mov	al,2			;search window mgr titles
;  mov	ebx,window_name
;  mov	ecx,work_buf
;  mov	edx,work_buf_size
;  call	window_find		;jns if success
  js	move_error		;jmp if error
  mov	eax,[ecx]		;get first match
  mov	[window_id],eax		;save id
  or	eax,eax
  jz	move_error		;exit if window not found
;get current window geometry
  call	x_get_geometry
  js	move_error
  mov	bx,[ecx+16]	;get width
  mov	[x_width],bx
  mov	bx,[ecx+18]	;get height
  mov	[y_height],bx
;move the window 
  mov	eax,[window_id]
  mov	esi,move_resize_block
  call	window_move_resize
  jmp	short move_exit
move_error:
 mov	al,6			;window find error
 call	report_error
move_exit:
  pop	esi
  ret
;------------
  [section .data]
window_id:	dd 0
move_resize_block:
x_position:   dw 0 ;new x pixel column
y_position:   dw 0 ;new y pixel row
x_width:      dw 0 ;new window width in pixels
y_height:     dw 0 ;new window height in pixels

  [section .text]
;----------------------------------------------------------------
resize_window:
  push	esi
  call	parse_next_parameter	;get window string
  jnc	rw_on			;jmp if parse ok
  jmp	resize_exit		;exit if error
rw_on:
;move program name to temp buffer
  mov	esi,ecx
  mov	edi,window_name
  mov	ecx,[string_end]
  sub	ecx,esi			;get win title length
  rep	movsb			;save title string
  mov	byte [edi],0		;terminate string
;get x size for window
  call	parse_next_parameter	;get x size
  jc	resize_exitj
  push	esi
  mov	esi,ecx
  call	ascii_to_dword		;x size to binary
  mov	[x_width],cx
  pop	esi
;get y size for window
  call	parse_next_parameter	;get y size for window
resize_exitj:
  jc	resize_exit
  push	esi
  mov	esi,ecx
  call	ascii_to_dword		;y size to binary
  mov	[y_height],cx
  pop	esi
;check if window exists
  call	get_windows
;  mov	al,2			;search window mgr titles
;  mov	ebx,window_name
;  mov	ecx,work_buf
;  mov	edx,work_buf_size
;  call	window_find		;jns if win id found
  js	resize_error		;jmp if error
  mov	eax,[ecx]		;get first match
  mov	[window_id],eax		;save id
  or	eax,eax
  jz	resize_error		;exit if window not found
;get current window geometry

  mov	eax,[window_id]
  call	x_translate_coordinates

  mov	bx,[ecx+12]	;get x position
  mov	[x_position],bx
  mov	bx,[ecx+14]	;get y position
  mov	[y_position],bx
;resize the window 
  mov	eax,[window_id]		;setup to resize win
  mov	esi,move_resize_block
  call	window_move_resize	;resize window
  jmp	short resize_exit
resize_error:
 mov	al,6			;window search error
 call	report_error
resize_exit:
  pop	esi
  ret
;----------------------------------------------------------------
activate_window_:
  call	parse_next_parameter
  jc	aw_exit
  push	esi
;move windoow name to temp buffer
  mov	esi,ecx
  mov	edi,window_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	byte [edi],0		;terminate string
;check if window exists
  call	get_windows
  js	aw_error		;jmp if error
  mov	eax,[ecx]		;get first match
  or	eax,eax
  jz	aw_error	;exit if window not found
;
  call	activate_window
  jns	aw_exit
aw_err2:
  mov	al,11
  call	report_error
  jmp	short aw_exit
aw_error:
  mov	al,6		;window find error
  call	report_error
aw_exit:
  pop	esi
  ret
;----------------------------------------------------------------
;window activate must be called before using
send_key:
  push	esi
;get keys to send
  call	parse_next_parameter
  jc	sk_error
  push	esi
  mov	esi,ecx
  call	hexascii_to_byte
  mov	[key_flag],al
  pop	esi
  call	parse_next_parameter
  jc	sk_error
  mov	esi,ecx
  call	hexascii_to_byte
  mov	[key_code],al
;setup to send key
  mov	ah,[key_flag]
  mov	al,[key_code]
  call	xtest_fake_input
  js	sk_error1		;jmp if error
  call	x_flush
  jmp	short sk_exit
;sk_error2:
;  mov	al,12
;  call	report_error
;  jmp	short sk_exit
sk_error1:
  mov	al,10		;key send failed
  call	report_error
  jmp	short sk_exit
sk_error:
  mov	al,6
  call	report_error
sk_exit:
  pop	esi
  ret
;-----------
  [section .data]
key_flag:	db 0
key_code:	db 0
  [section .text]
;----------------------------------------------------------------
set_timeout:
  push	esi
  call	parse_next_parameter
  jc	st_exit
  mov	esi,ecx
  call	ascii_to_dword	;convert to bin
  mov	eax,ecx		;move sec to eax
  jecxz	st_set		;jmp if zeroing timeout
;convert seconds to usec
  xor	edx,edx
  mov	ecx,1000000
  mul	ecx		;compute usec wait
  push	eax		;save wait
  call	get_time
  pop	ebx		;restore wait
  add	eax,ebx		;compute timeout end
st_set:
  mov	[micro_timeout_target],eax
st_exit:
  pop	esi
  ret
;----------------------------------------------------------------
dump:		;show current state of windows
  push	esi
  mov	[window_name],dword 0	;enable display of all windows
  call	show_windows
  jns	dump_on		;jmp if no error
;error occured
  mov	al,9
  call	report_error
  jmp	short dump_exit
dump_on:
  call	show_programs
dump_exit:
  pop	esi
  ret
;----------------------------------------------------------------
sleep:
  push	esi
  call	parse_next_parameter
  jc	sleep_exit
  mov	esi,ecx
  call	ascii_to_dword	;convert to bin
  mov	eax,ecx		;move sec to eax
  neg	eax
  call	delay		;sleep for x seconds
sleep_exit:
  pop	esi
  ret
;----------------------------------------------------------------
goto:
  push	esi
  call	parse_next_parameter
  jc	goto_exit
;move lable name to temp buffer
  mov	esi,ecx
  mov	edi,window_name
  mov	ecx,[string_end]
  sub	ecx,esi
  rep	movsb
  mov	al,':'
  stosb
  mov	byte [edi],0		;terminate string
;setup for search, ecx=match 
  mov	esi,window_name		;match string
  mov	ebp,[cmd_buf_end_ptr]	;end of search block
  mov	edi,[cmd_buf_top_ptr]	;top of search block
  mov	edx,1			;search forward
  mov	ch,0ffh			;match case
  call	blk_find
  jc	goto_exit		;exit if not found
;we have found label, restart parse
  mov	[cmd_buf_ptr],ebx	;restart parse (goto)
  clc
  pop	esi
  mov	esi,ebx			;restart parse
  jmp	short goto_exit2
goto_exit:
  pop	esi
goto_exit2:
  ret
;----------------------------------------------------------------
move_mouse:
  push	esi
;  push	esi
;  call	xtest_version
;  pop	esi
;get x position for window
  call	parse_next_parameter	;get x position (pixel col)
  jc	mmove_error
  push	esi
  mov	esi,ecx
  call	ascii_to_dword
  mov	[mx_position],cx
  pop	esi
;get y position for window
  call	parse_next_parameter	;get y position (pixel row)
mmove_errorj:
  jc	mmove_error
  mov	esi,ecx
  call	ascii_to_dword
  mov	[my_position],cx
;move the mouse
  mov	ax,[mx_position]
  mov	bx,[my_position]
  call	xtest_move_mouse
  call	x_flush
  jmp	short mmove_exit
mmove_error:
 mov	al,6			;window search error
 call	report_error
mmove_exit:
  pop	esi
  ret
;------
  [section .data]
mx_position:	dw	0
my_position:	dw	0
  [section .text]
;----------------------------------------------------------------
click_mouse:
  push	esi
;  push	esi
;  call	xtest_version
;  pop	esi
  call	parse_next_parameter	;get click type
  jnc	click_on		;jmp if parse ok
  jmp	click_error  	;exit if error
click_on:
  cmp	[ecx],dword 'righ'
  jne	click_10
  mov	al,3			;right click
  jmp	short do_click

click_10:
  cmp	[ecx],dword 'midd'
  jne	click_20
  mov	al,2			;middle click
  jmp	short do_click

click_20:
  cmp	[ecx],dword 'left'
  jne	click_error
  mov	al,1			;left click

;click the mouse
do_click:			;al=click type
  call	xtest_click
  call	x_flush
  jmp	short click_exit
click_error:
 mov	al,6			;window search error
 call	report_error
click_exit:
  pop	esi

  ret
;----------------------------------------------------------------
set_time:
  call	get_raw_time
  mov	[base_seconds],eax
  mov	[micro_base],ebx
  ret
;----------------------------------------------------------------
;output: eax = current micro time
get_time:
  call	get_raw_time
  sub	eax,[base_seconds]
  mov	ecx,1000000		;one million
  xor	edx,edx
  mul	ecx
  add	eax,ebx
  mov	[micro_current],eax
  ret
;----------------------------------------------------------------
;parse_next_parameter - get following string or token
;input: esi points at parse start point
;output: carry set = error
;                    esi unchanged
;                    edi restored
;                    eax = error number
;        nocarry = success
;                  esi updated to end of parse
;                  edi unchanged
;                  ecx = string start
;note:
;     
;     
;
parse_next_parameter:
  mov	[parse_start],esi
  push	edi
pn_lp:
  cmp	esi,[cmd_buf_end_ptr]
  jae	pn_error	;exit if error
  cmp	[esi],byte '^'
  je	pn_error	;exit if command found
  cmp	[esi],word '("' ;start of string
  je	pn_string	;jmp if string found
pn_tail:
  inc	esi
  jmp	short pn_lp	;keep looking
;
pn_error:
  mov	al,4
  call	report_error
  stc
  mov	esi,[parse_start] ;restore parse point
  jmp	pn_exit

;parse string
pn_string:
  add	esi,2	;move past ("
  mov	[string_start],esi
;move and expand tokens
pn_mv_lp2:
  cmp	[esi],word '")'		;check for ")
  je	pn_string_end
  inc	esi
  cmp	[cmd_buf_end_ptr],esi
  je	pn_error
  jmp	short pn_mv_lp2		;loop till end of string
pn_string_end:
  mov	[string_end],esi
  mov	ecx,[string_start]
pn_success2:
  clc		;set success flag 
pn_exit:
  pop	edi
  ret
;--------
  [section .data]
parse_start: dd 0
string_start:	dd 0
string_end:	dd 0

  [section .text]        
;----------------------------------------------------------------
;lookup_cmd - convert command string to process ptr
;    cmd_buf_ptr
;    cmd_buf_end_ptr
;output: carry set if end of buffer
;        eax=cmd process if success
;
lookup_cmd:
  mov	esi,[cmd_buf_ptr]
nc_loop:
  cmp	esi,[cmd_buf_end_ptr]
  jae	nc_done_exit
  cmp	word [esi],'("'	;string start?
  jne	nc_skip1
  or	[xhelper_status],byte 04 ;set string start
nc_skip1:
  cmp	word [esi],'")'	;string end
  jne	nc_skip2
  and	[xhelper_status],byte ~4
nc_skip2:
  lodsb
  cmp	al,'^'
  jne	nc_loop	;loop till command found
  test	[xhelper_status],byte 4
  jnz	nc_loop		;jmp = ignore cmd if in string

  push	esi
  dec	esi	;move back to ^
  mov	edi,commands
  call	lookup_list
  pop	esi
  jc	nc_loop		;loop if not legal token
;token index is in ecx
  shl	ecx,2		;make dword index
  add	ecx,cmd_process_list
  mov	eax,[ecx]
  clc
  jmp	short nc_exit
nc_done_exit:
  stc
nc_exit:
  mov	[cmd_buf_ptr],esi ;update esi
  ret
;---------------------------------------------------------------
;inputs: esi = parse ptr
;        edi = search table
;output: if no carry - ecx=index, esi points past parameter
;        if carry - not found, esi restored
lookup_list:
  mov	[ll_token_ptr],esi
  xor	ecx,ecx		;set index to  zero
ll_lp1:
  cmp	[edi],byte 0	;end of this list token
  je	ll_found
  cmpsb
  je	ll_lp1		;keep comparing if match
  inc	ecx
;move to next list token
ll_skip_lp:
  inc	edi
  mov	al,[edi]
  or	al,al
  jnz	ll_skip_lp	;loop till next token
  mov	esi,[ll_token_ptr] ;restart token start
  inc	edi		;move past zero at end
ll_lp2:
  cmp	byte [edi],0
  jne	short ll_lp1	;jmp if table has more entries
  stc
  mov	esi,[ll_token_ptr] ;restore esi
  jmp	short ll_exit
ll_found:
  clc
ll_exit:
  ret
;-------------
  [section .data]
ll_token_ptr: dd 0
  [section .text]
;----------------------------------------------------------------
;build_run_data - setup for run
;input: ecx = string ptr
;output: see sys_fork_run format in work_buf
;
build_run_data:
  mov	esi,ecx
  mov	edi,work_buf
brd_lp:
  lodsb
  cmp	al,' '
  jne	brd_20
  mov	al,0
  jmp	short brd_stuff
brd_20:
  cmp	al,'"'
  je	brd_done
brd_stuff:
  stosb
  jmp	brd_lp
brd_done:
  xor	eax,eax
  stosd			;terminate data
  ret
;----------------------------------------------------------------
; parse_user_inputs - get parameters
; input: esp has one push
;output: carry set if error
;        success = file names set
;
parse_user_parameters:
  mov	esi,esp		;get stack ptr
  lodsd			;get return address (ignore)
  lodsd			;number of parameters
  mov	ecx,eax
  dec	ecx
  jecxz	state_display
  lodsd			;get our filename (ignore)
  lodsd			;get first parameter
  or	eax,eax
  jz	state_display
  jmp	short pup_ck1
pup_loop:
  lodsd			;get parameter ptr
  or	eax,eax
  jnz	pup_ck1		;jmp if parameter found
  cmp	[cmd_filename_ptr],eax ;check if filename entered
  jz	state_display	;jmp if no filename (state display)
  jmp	short pup_ok
pup_ck1:
  cmp	word [eax],'-x'
  jne	pup_ck2
  mov	[window_list_flag],byte 0 ;enable x server window list
  jmp	short pup_loop  
pup_ck2:
  cmp	word [eax],'-s'
  jne	pup_ck3
  mov	[initial_win_sav_flag],byte 1
  jmp	short pup_loop

pup_ck3:
  cmp	dword [eax],'-got'
  jne	pup_ck4
;parse goto label
  lodsd
  mov	[goto_label_ptr],eax
  jmp	short pup_loop

pup_ck4:
  cmp	word [eax],'-h'
  je	pup_help		;jmp if help
  mov	[cmd_filename_ptr],eax	;assume this is command file name
  jmp	short pup_loop

;show state message
state_display:
  call	show_windows
  call	show_programs
pup_help:
  mov	ecx,help_msg
  call	crt_str
  jmp	short parse_error
pup_ok:
  clc
  jmp	short parse_exit
parse_error:
  stc
parse_exit:
  ret
;-----------
  [section .data]
goto_label_ptr	dd 0

help_msg: db 0ah,'-- xhelper help --',0ah
  db 'xhelper <cmd file>  <- batch mode with command file',0ah
  db 'xhelper -h          <- help message',0ah
  db 'xhelper             <- state display',0ah
  db 0ah
  db ' -- command file contents --',0ah
  db '^run ("program")    begin a programs execution',0ah
  db '^kill ("program")   kill a executing program',0ah
  db '^stop               end of xhelper commands',0ah
  db '^sleep ("seconds")  sleep',0ah
  db '^dump               show current state',0ah
  db '^show ("message")   show message',0ah
  db '^goto ("label")     jmp to label',0ah
  db 0ah
  db '^set_timeout ("seconds") setup for wait functions',0ah
  db '^wait_program ("name")  wait for program to start',0ah
  db '^wait_no_program ("name")   wait for program to end',0ah
  db '^wait_windor ("name")     wait for window',0ah
  db '^wait_no_window ("name")  wait for no window',0ah
  db '^wait_file ("file")       wait for file to exist',0ah
  db '^wait_no_file ("file")    wait for no file',0ah
  db 0ah
  db '^if_program ("name")',0ah
  db '^if_no_program ("name")',0ah
  db '^if_window ("name")',0ah
  db '^if_no_window ("name")',0ah
  db '^if_file ("name")',0ah
  db '^if_no_file ("name")',0ah
  db '^if_timeout',0ah
  db '^if_no_timeout',0ah
  db '^endif',0ah
  db 0ah
  db '^move_window ("x") ("y")',0ah
  db '^resize_window ("x") ("y")',0ah
  db '^activate_window ("name")',0ah
  db '^send_keys ("flag") ("xkey")',0ah
  db 0		;end of help

  [section .text]
;----------------------------------------------------------------
show_windows:
  mov	ecx,window_msg
  call	crt_str
  call	get_windows
  js	sw_exitjj		;jmp if error
  mov	esi,work_buf
  mov	edi,window_list
sw_lpx:
  lodsd
  stosd
  or	eax,eax
  jz	sw_moved
  jmp	sw_lpx

sw_moved:
  mov	ecx,window_list
sw_loop:
  mov	[sw_win_ptr],ecx
  mov	edi,display_line
  mov	[sw_stuff_ptr],edi
  mov	eax,[ecx]		;get window id
  mov	[window_id],eax
  or	eax,eax
  jnz	sw_continue
sw_exitjj:
  jmp	sw_exit			;exit if end of list
sw_continue:
;show id
  call	dwordto_hexascii
  mov	al,' '
  stosb

  mov	[sw_stuff_ptr],edi
  mov	eax,[window_id]
  call	wm_name			;returns ecx->name
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success ecx -> returned packet
;               edi = pointer to name
;               eax = length of name

  jns	sw_ck2
  jmp	sw_exit	;exit if error
sw_ck2:
  or	eax,eax
  jnz	sw_save	;jmp if name found
sw_tailj:
  jmp	sw_tail	;skip zero length names
sw_save:
  mov	esi,edi
  mov	edi,[sw_stuff_ptr]
  mov	ecx,eax		;get name length
  mov	al,[esi]
  cmp	al,'!'
  jb	sw_tailj
  cmp	al,'z'
  ja	sw_tailj
  rep	movsb		;save name
  mov	al,' '
  stosb

  mov	esi,geom_msg
  call	str_move

  mov	eax,[window_id]
  push	edi         
  call	x_translate_coordinates
  pop	edi

  xor	eax,eax
  mov	ax,[ecx+12]
  push	ecx
  call	dword_to_ascii
  pop	ecx
  mov	al,' '
  stosb

  xor	eax,eax
  mov	ax,[ecx+14]
  push	ecx
  call	dword_to_ascii
  pop	ecx
  mov	al,' '
  stosb


  mov	eax,[window_id]
  push	edi
  call	x_get_geometry		;returns ecx -> pkt
  pop	edi
;    if success, ecx points to lib_buf with:
;     db reply, 1=ok 0=failure
;     db depth
;     dw sequence#
;     dd 0 (reply length)
;     dd window (root id)
;     dw x location of win, pixel column
;     dw y location of win, pixel row
;     dw width, pixel width
;     dw height, pixel height
;     dw border width
;
;     !! Note: the x,y location is relative to parents
;              origon.  Often these values are zero if
;              outside parent.  The border width is also
;              zero, and all three are zero for pixmaps.

  xor	eax,eax
  mov	ax,[ecx+16]
  push	ecx
  call	dword_to_ascii
  pop	ecx
  mov	al,' '
  stosb

  xor	eax,eax
  mov	ax,[ecx+18]
  call	dword_to_ascii
  mov	al,' '
  stosb

  mov	esi,pid_msg
  call	str_move

  mov	eax,[window_id]
  push	edi
  call	win_associated_pid
  pop	edi
sw_exitj:
  js	sw_exit
  call	dword_to_ascii
  mov	al,' '
  stosb

  push	edi
  call	x_get_input_focus	;get focused window

;extern log_hex
;extern log_eol
;  call	log_hex
;  call	log_eol

  pop	edi
  js	sw_exit			;exit if error
  cmp	eax,[window_id]
  je	focused
  mov	esi,not_focused_msg
  jmp	stuff1
focused:
  mov	esi,focused_msg
stuff1:
  call	str_move
  mov	al,0ah
  stosb
  xor	eax,eax
  stosb
  mov	ecx,display_line
  call	crt_str
sw_tail:
  mov	ecx,[sw_win_ptr]			;restore list ptr
  add	ecx,4
  jmp	sw_loop
sw_exit:
  ret
;----------
  [section .data]
window_msg:	db 0ah,' -- window list --',0ah,0
not_focused_msg: db 'unfocused',0
focused_msg:     db 'focused',0
window_list_flag db 2	;2=use wm list, 0=use x list
window_list: times 300 dd 0
display_line:	times 300 db 0
geom_msg: db 'geometry(x,y position x,y size)= ',0
pid_msg:  db 'PID=',0
sw_stuff_ptr	dd 0
sw_win_ptr	dd 0
  [section .text]
;----------------------------------------------------------------

show_programs:
  mov	ecx,program_msg
  call	crt_str
  
  mov	eax,work_buf
  mov	ebx,work_buf_size
sp_loop:
  call	process_walk
  or	eax,eax
  jz	sp_exit		;exit if done
;    ecx = pointer to data in lib_buf (example below)
;         Name:	init
;         State:	S (sleeping)
;         SleepAVG:	90%
;         Tgid:	1
;         Pid:	1
;         PPid:	0
;         TracerPid:	0
;         Uid:	0	0	0	0
;         Gid:	0	0	0	0
;         FDSize:	32
;         Groups:	
;         VmSize:	    1408 kB
;         VmLck:	       0 kB
;         VmRSS:	     496 kB
;         VmData:	     148 kB
;         VmStk:	       4 kB
;         VmExe:	      28 kB
;         VmLib:	    1204 kB
;         Threads:	1
;         SigPnd:	0000000000000000
;         ShdPnd:	0000000000000000
;         SigBlk:	0000000000000000
;         SigIgn:	ffffffff57f0d8fc
;         SigCgt:	00000000280b2603
;         CapInh:	0000000000000000
;         CapPrm:	00000000ffffffff
;         CapEff:	00000000fffffeff

  mov	edi,display_line
  mov	esi,ecx		;get data ptr
  call	str_move2

;find state
find_state_lp:
  cmp	[esi],dword 'ate:'
  je	found_state
  inc	esi
  jmp	short find_state_lp
found_state:
  sub	esi,2
  call	str_move2

;find Pid:
find_pid_lp:
  cmp	[esi],dword 'Pid:'
  je	found_pid
  inc	esi
  jmp	short find_pid_lp
found_pid:
  call	str_move2

  mov	al,0ah
  stosb
  xor	eax,eax
  stosb			;terminate line

  mov	ecx,display_line
  call	crt_str

  xor	eax,eax		;set continue flag
  jmp	sp_loop

sp_exit:
  call	process_walk_cleanup
  ret
;-----------
  [section .data]
program_msg:  db 0ah,' -- program list --',0ah,0
  [section .text]
;---------------------------------------------------------------
str_move2:
  lodsb
  cmp	al,09		;tab?
  jne	str_move2a
  mov	al,' '
  jmp	short str_stuff
str_move2a:
  cmp	al,0dh
  jbe	str_move2_done
str_stuff:
  stosb
  jmp	str_move2
str_move2_done:
  mov	eax,'    '
  stosd			;add space at end
  ret
;----------------------------------------------------------------
;report_error - set error exit info, and show message
;inputs: esi=parse point, or zero if not parse error
;        al = error number
;output:
report_error_pre:
  xor	esi,esi		;no line number display
  jmp	short report_error_entry

report_error:
  mov	esi,[cmd_buf_ptr]
report_error_entry:
  or	[xhelper_status],byte 80h	;set error exit
  mov	[xhelper_err#],al
  or	esi,esi
  jz	re_skip1	;jmp if no line number report
;look up current line#
  mov	ebx,esi
  mov	esi,[cmd_buf_top_ptr]
  xor	ecx,ecx		;init line#
re_line_lp1:
  inc	ecx		;bump line#
re_line_lp2:
  cmp	esi,[cmd_buf_end_ptr]
  jae	re_skip1	;jmp if line not found
  cmp	esi,ebx
  jae	re_got_line
  lodsb
  cmp	al,0ah
  jbe	re_line_lp1	;jmp if new line
  jmp	short re_line_lp2
;show line message
re_got_line:
  mov	eax,ecx
  mov	edi,line_stuff
  call	dword_to_ascii
  mov	ecx,line_msg
  call	crt_str
re_skip1:  
  mov	eax,[xhelper_err#]
  shl	eax,2		;convert to dword ptr
  add	eax,error_ptrs-4
  mov	ecx,[eax]	;get error ptr
  call	crt_str
  ret
;------
  [section .data]
line_msg: db 0ah
  db 'xhelper Error while processng command line# '
line_stuff:
  db '              ',0

error_ptrs:
  dd err1
  dd err2
  dd err3
  dd err4
  dd err5
  dd err6
  dd err7
  dd err8
  dd err9
  dd err10
  dd err11
  dd err12
  dd err13
  dd err14
  dd err15
  dd err16
  dd err17
  dd err18
  dd err19
  dd err20
  dd err21
  dd err22
  dd err23
  dd err24
  dd err25
  dd err26
  dd err27

err1: db 0ah
 db 'usage: xhelper <cmd_file> <-h>',0ah
 db '       xhelper   (no parameters = dump window state)',0ah,0
err2: db 0ah
 db 'memory allocation error',0ah,0
err3: db 0ah
 db 'control file read error',0ah,0
err4: db 0ah
 db 'Parameter parse error',0ah,0
err5: db 0ah
 db 'Program search error',0ah,0
err6: db 0ah
 db 'Window locate error',0ah,0
err7: db 0ah
 db '-if_nesting error',0ah,0
err8: db 0ah
 db '-run- setup error',0ah,0
err9: db 0ah
 db '-dump- failed',0ah,0
err10 db 0ah
 db '-send key- failed',0ah,0
err11 db 0ah
 db 'can not activate window',0ah,0
err12 db 0ah
 db 'can not get xtest version',0ah,0
err13: db 0ah
 db 'startup goto label not found',0ah,0
err14: db 0ah

err15: db 0ah

err16: db 0ah
err17: db 0ah

err18: db 0ah

err19: db 0ah

err20: db 0ah
err21: db 0ah
err22: db 0ah
err23: db 0ah
err24: db 0ah
err25: db 0ah
err26: db 0ah
err27: db 0ah
  
;----------------------------------------------------------------
;data
;----------------------------------------------------------------
initial_win_sav_flag	db 0  ;0= save 1= no save

xhelper_status	dd 0	;01h = normal exit
;                       ;02h = "if" ignore active
;                       ;04h =
;                       ;08h =
;                       ;80h=error exit
xhelper_err#	dd 0	;

cmd_filename_ptr	dd 0
cmd_buf_length:		dd 0
cmd_buf_top_ptr:	dd 0
cmd_buf_ptr:		dd 0	;processing position
cmd_buf_end_ptr:	dd 0

our_win_id:	dd 0
our_win_location:
	dw 0	;x location
	dw 0	;y location
	dw 0	;width
	dw 0	;height
;----
; commands
;----
commands:
 db '^if_program',0		;if
 db '^if_no_program',0		;if
 db '^if_window',0
 db '^if_no_window',0
 db '^if_file',0
 db '^if_no_file',0
 db '^if_timeout',0
 db '^if_no_timeout',0
 db '^endif',0
;the above commands must be first for "if" logic test
 db '^run',0		;run program
 db '^wait_program',0
 db '^wait_no_program',0
 db '^wait_window',0
 db '^wait_no_window',0
 db '^wait_file',0
 db '^wait_no_file',0
 db '^kill',0
 db '^stop',0			;end of commands
 db '^show',0			;show message
 db '^move_window',0
 db '^resize_window',0
 db '^activate_window',0
 db '^send_key',0
 db '^set_timeout',0
 db '^dump',0
 db '^sleep',0
 db '^goto',0
 db '^move_mouse',0
 db '^click_mouse',0
 db 0

cmd_process_list:
 dd if_program
 dd if_no_program
 dd if_window
 dd if_no_window
 dd if_file
 dd if_no_file
 dd if_timeout
 dd if_no_timeout
 dd endif
;the above commands must be first for "if" logic test
 dd run
 dd wait_program
 dd wait_no_program
 dd wait_window
 dd wait_no_window
 dd wait_file
 dd wait_no_file
 dd kill
 dd stop
 dd show
 dd move_window
 dd resize_window
 dd activate_window_
 dd send_key
 dd set_timeout
 dd dump
 dd sleep
 dd goto
 dd move_mouse
 dd click_mouse

;----------------
base_seconds:	dd 0
micro_base:	dd 0
micro_current:	dd 0		;set by get_time
micro_timeout_target: dd 0	;set by timeout command
timeout_flag	dd 0		;0=no timeout  1=timeout
;----------------
;if nesting block
;----------------
list_block:
 dd	list_buf     ;list buf top
 dd	list_buf_end ;list buf end
 dd	4	     ;list entry size
 dd	list_buf     ;list start ptr
 dd	list_buf     ;list tail ptr

list_buf	times 8 dd 0
list_buf_end:

;-----------------------------------------------------------------------
  [section .bss]
work_buf_size	equ	3*4048
work_buf	resb	work_buf_size


