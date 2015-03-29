
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
;----------------------------------------------------------------
  [section .text]

 extern read_termios_0
; extern wait_event
; extern bit_test
 extern sys_run_die
 extern file_close
 extern signal_handler_default
 extern str_move
 extern read_term_info_0
 extern output_term_info_0
 extern lib_buf
 extern traceme
 extern delay
 extern signal_send

wrap_buf_size	equ	200

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

struc termios_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termios_struc_size:

%macro _mov 2
  push	byte %2
  pop	%1
%endmacro

;---------------------------------------------------------------
;>1 sys
;   launch_app - wrap app and setup for feed with launch_feed
; INPUTS
;    eax = ptr to command (see below)
;    The command is a series of strings with an extra zero
;              at end of last string.
;    examples: db "/bin/ls",0,0                 ;no parameters, full path
;              db "myprogram,0,"parameter1",0,0 ;local executable, one parameter
;              db "/bin/bash",0,'-c',0,"myprogram",0,0 ;shell program
;
;    ebx = 0 - normal launch
;          1 - tracme launch
;
;    [enviro_ptrs] - is a global library variable needed to find enviornment
;                    must be initialized by env_stack call at start
;                    of program.
;                    If full path is provided or file is local, then
;                    enviro_ptrs is not needed.
; OUTPUT
;    eax if negative, error
;        if positive then it is child process id
;
; NOTES
;    source file is launch.asm     
;<
;---------------------------------------------------------------
  global launch_app
launch_app:
  mov	[callers_command_ptr],eax
  mov	[launch_flag],ebx
;save copy of origional termios to restore
  mov	edx,saved_termios
  call	read_term_info_0
;get termios, used to set and restore tty modes
  mov	edx,child_termios
  call	read_term_info_0
;save state for SIGCHLD,SIGING,SIGQUIT signals & add handler
  call	signal_setup

;set parent tty mode interfacing with user
;The parent must allow the child to control the terminal by not
;doing any translations or processing of the data.  The child should
;be set to the terminal defaults initially.
;clear c_iflag INLCR,IGNCR,IUCLC,IXON
  mov	dword [child_termios+term_info_struc.c_iflag],000H
;clear c_oflag OPOST
  mov	dword [child_termios+term_info_struc.c_oflag],5h
;set lflag
  mov	dword [child_termios+term_info_struc.c_cflag],0bfh
;clear c_lflag ICANON,ISIG,ECHO
  mov	dword [child_termios+term_info_struc.c_lflag],8a30h
;set c_cc .VMIN
  mov	byte [child_termios+term_info_struc.c_cc +6],byte 01H
;set c_cc .VTIME
  mov	byte [child_termios+term_info_struc.c_cc +5],byte 00H
;now set new tty mode
  mov	edx,child_termios
  call	output_term_info_0

  mov	byte [abort_flag],0
  xor	eax,eax
  mov	[child_process],eax
  mov	[master_fd],eax
  mov	[slave_fd],eax
;launch program in pty terminal
  call	ptyopen		;open a psuedo tty and launch executable
;slave is running, ptyopen puts [process_id] in eax
  push	eax	;save child process id
  mov	eax,100
  call	delay	;give child time to run
  pop	ebx	;get child id
  xor	eax,eax	;send 0 signal (error check)
  call	signal_send
  ret		;return eax negative if error
;-----------------------------------------------------------------
;>1 sys
;  launch_kill - kill a process started by launch_app 
; INPUT:  none
; OUTPUT: none
; NOTES: see also launch_feed, launch_app
;<1

  global launch_kill
launch_kill:
  call	signal_restore		;restore SIGCHLD
;kill child
  _mov	eax,37
  mov	ebx,[child_process]
  or	ebx,ebx
  jz	finish2			;jmp if child not forked yet
  _mov	ecx,9			;kill signal
  int	byte 80h
;wait for child to exit
keep_waiting:
  mov	ebx,[child_process]
  mov	ecx,execve_status
  xor	edx,edx
  _mov	eax,7
  int	byte 80h			;wait for child, PID in ebx
  cmp	eax,byte -4			;did we interrupt a signal
  je	keep_waiting
;get status of child process
  sub	eax,eax
  mov	al,byte [execve_status +1]
finish2:
  mov	ebx,[master_fd]
  or	ebx,ebx			;check if open
  jz	finish3			;jmp if not open
  call	file_close
finish3:
  mov	ebx,[slave_fd]
  or	ebx,ebx
  jz	finish4			;jmp if not open
  call	file_close
finish4:
  mov	edx,saved_termios
  call	output_term_info_0
  ret

;------------------------------------------------------------
;>1 sys
;  launch_feed - feed data to process started by launch_app
; INPUT:
;        ecx = buffer with key
;        edx = amount of data to write
; OUTPUT: error       - eax negative
;         done        - eax=write count
; NOTES: see also launch_app, launch_kill
;<1
;--------------------------------------------------------------
  global launch_feed
launch_feed:
;write key to child
  mov	ebx,[master_fd]
  _mov	eax,4
  int	byte 80h
  ret

;-----------------------------------------------------------------
ptyopen:    ;08048ADA
;open master psuedo tty
  _mov	eax,5			;open kernel call
  mov	ebx,ptmx_path
  _mov	ecx,02			;O_RDRW
  int	byte 80h			;open /dev/ptmx
  mov	[master_fd],eax
  or	eax,eax
  js	ptyopen_abort
;open slave psuedo terminal
;call grantpt to set slave permissions
  mov	ebx,eax			;set ebx -> master_fd
  _mov	eax,54			;ioctl kernel call
  mov	ecx,80045430h		;grantpt ioctl
  mov	edx,wrap_buf
  int	byte 80h
  or	eax,eax
  js	ptyopen_abort
;build name of pts
  mov	eax,[wrap_buf]
  or	al,'0'
  mov	[pts_path2],al
;unlock the slave (unlockpt)
  _mov	eax,54			;ioctl kernel call
;  mov	ebx,[master_fd]
  mov	ecx,40045431h		;TIOCSPLTLCK
  mov	edx,blockx		;this appears to be needed!
;old code had mov edx,blockx here (blockx = 0)?
  int	byte 80h
  or	eax,eax
  js	ptyopen_abort
; open slave
  _mov	eax,5
  mov	ebx,pts_path1
  mov	ecx,102h	;O_RDWR O_NOCTTY
  xor	edx,edx
  int	byte 80h
  mov	[slave_fd],eax

;fork duplicates program, including signal handling, open fd's etc.
;     only pending signals are cleared and PID changed.
;fork ---- fork
  _mov	eax,2		;fork
  int	byte 80h
  mov	[child_process],eax
  or	eax,eax
  jz	child_processing
;parent path -- exit ---
parent_return:
  mov	eax,[child_process]
ptyopen_abort:
  ret
  
;child processing ---------------------------- child -----------

child_processing:
;get rid of current controlling terminal
;make child tty a controlling tty so that /dev/tty points to us
  _mov	eax,66
  int	byte 80h		;setsid
;close master fd, no longer needed
  mov	ebx,[master_fd]
  call	file_close
;dup2 stdin
  _mov	eax,63		;dup2
  mov	ebx,[slave_fd]
  xor	ecx,ecx		;stdin
  int	byte 80h
;dup2 stdout
  _mov	eax,63		;dup2
  mov	ebx,[slave_fd]
  inc	ecx		;ecx->1 (stdout)
;  int	byte 80h
;dup stderr
  _mov	eax,63		;dup2
  mov	ebx,[slave_fd]
  inc	ecx		;ecx -> 2 (stderr)
;  int	byte 80h
;close slave_fd, don't need anymore, it is now stdin,stdout,stderr
  mov	ebx,[slave_fd]
  call	file_close
  mov	dword [child_termios+term_info_struc.c_iflag],dword 0100h
  mov	dword [child_termios+term_info_struc.c_lflag],dword 8a3bh
;now set new tty mode
  mov	edx,child_termios
  call	output_term_info_0

  test	[launch_flag],byte 1	;check if trace enabled
  jz	skip_tracme
  call	traceme
skip_tracme:
;execute command ----  exec ----
; execve passes PID and open fd's on.  Signals are
; set to their defualt state.  The SIGCHLD state is
; undetermined if set to SIG_IGN (no handler)
; pending signals are cleared.
  mov	esi,[callers_command_ptr]
  call	sys_run_die
;should not get here
  _mov	eax,1
  int	byte 80h			;exit
;end of child processing ----

;------------------------------------------------------------------
; eax = signal number
; esi = ptr to signal name string

SIGCHLD_trap:
  inc	byte [abort_flag]		;set abort flag
  jz	SIGCHLD_exit			;jmp if not in I/O wait
;trigger select action if waiting
  mov	ecx,pts_path2
  _mov	edx,1
  _mov	eax,4
  mov	ebx,[master_fd]
  int	byte 80h
SIGCHLD_exit:
  ret
;------------------------------------------------------------------
signal_setup:
  _mov	eax,67
  _mov	ebx,17		;SIGCHLD
  mov	ecx,SIG_block
  xor	edx,edx		;disable save of previous state
  int	byte 80h
  ret  
;------------------------------------------------------------------
signal_restore:
  _mov	ebx,17
  call	signal_handler_default
  ret

;--------------------------
  [section .data]
SIG_block: dd	SIGCHLD_trap	;handler
           dd	0		;mask
	   dd	0		;flags
	   dd	0		;unused

;------------------------------------------------------------------

callers_command_ptr dd	0	;ptr to callers command
launch_flag	    dd  0	;0=normal launch 1=tracme launch
abort_flag             db 0	;0=no abort

;  global child_process
child_process	dd	0
slave_fd	dd	0
read_slave_count dd	0		;amoun
switch_key_ptr	dd	0
master_fd	dd	0

select_list:
stdin_fd	dd	0		;do not remove
		dd	-1		;end of select list
event_count	dd	0		;number of events from select
event_buf: dd	0	;holds ptr to event bits


ptmx_path	db	'/dev/ptmx',0
pts_path1	db	'/dev/pts/'
pts_path2	db	0,0,0,0
blockx:		dd	0

saved_termios times term_info_struc_size db 0

child_termios times term_info_struc_size db 0

;termios	      times termios_struc_size db 0

execve_status		db	0,0,0,0,0,0,0,0

wrap_buf	times wrap_buf_size db 0

  [section .text]

