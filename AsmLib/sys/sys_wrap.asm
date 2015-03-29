
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

 extern read_termios_0
 extern wait_event
 extern bit_test
 extern sys_run_die
 extern file_close
 extern signal_handler_default
 extern str_move
 extern read_term_info_0
 extern output_term_info_0
 extern lib_buf

%ifdef DEBUG
  extern raw_set1
  extern raw_unset1
 extern env_stack
 extern log_str
 extern log_eol
 extern log_hex
 extern log_regtxt
 extern log_terminal_0
 extern log_terminal_x

 [section .text]
 global _start
 global main
_start:
main:    ;080487B4
  cld
  call	env_stack

  mov	eax,the_command
  xor	ebx,ebx
  xor	ecx,ecx
  call	sys_wrap

  mov	esi,log_str2
  call	log_str
  call	log_hex
  call	log_eol

  mov	eax,1
  int	80h

;the_command: db "/bin/bash",0,'-c',0,'vttest',0,0
;the_command: db "/bin/bash",0,0
the_command: db "/bin/bash",0,'-c',0,"nano",0,0
;the_command: db "/bin/bash",0,'-c',0,"kate xx",0,0
;the_command: db "/bin/bash",0,'-c',0,"/home/jeff/asm/test/wrap/show",0,0
log_str1: db 'command1 wrapped status =',0
log_str2: db 'command2 wrapped status =',0

%endif

%ifdef DEBUG
 extern log_signals
%endif

wrap_buf_size	equ	8097

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

;---------------------------------------------------------------
;>1 sys
;   sys_wrap - wrap around an executable and capture in/out
; INPUTS
;    eax = ptr to command (see below)
;    ebx = ptr to optional input (feed) process (see notes) 
;    ecx = ptr to optional output capture process (see notes)
;
;    The command is a series of strings with an extra zero
;              at end of last string.
;
;    examples: db "/bin/ls",0,0                 ;no parameters, full path
;              db "myprogram,0,"parameter1",0,0 ;local executable, one parameter
;              db "/bin/bash",0,'-c',0,"myprogram",0,0 ;shell program
;
;    [enviro_ptrs] - is a global library variable needed to find enviornment
;                    must be initialized by env_stack call at start
;                    of program.
;
; OUTPUT
;    XX......h     abort_flag -1(normal) 0(in wait) 1(abort)
;    ..XX....h     last_kernel_rtn
;    ....XX..h     parent_err_flag, 10h+, code location
;    ......XXh     harvested_child_status
;
;    [child_pid] - the global variable child_pid is available at
;                  sys_wrap executes for possible abort of the child.
;                  This might be possible if a program hangs up and
;                  somehow keyboard intercept or signal detected the
;                  problem.
;    [master_fd] - child terminal fd
; 
; NOTES
;    source file sys_wrap.asm
;     
;    The optional feed process can be set to zero if not needed.
;    If a feed process address is given, it is called after data
;    has been read.  The buffer address is in ecx and the number
;    of bytes read is in edx.  The data has a zero at end.  The
;    feed process can change the data and byte count.  If the byte
;    count is set negative the wrapped child will be aborted.
;    summary:  input:  ecx=buffer      output:  ecx=buffer
;                      edx=byte count           edx=count or abort
;    After returning the data will be sent to childs stdin.
;     
;    The optional capture process is handled like the feed process,
;    After returning the data will be sent to stdout.
;
;    The feed and capture process's need to be used cautiously.
;    They are running as part of the child input/output call and
;    some kernel calls may cause problems.
;     
;<
;---------------------------------------------------------------
  global sys_wrap
sys_wrap:
  mov	[callers_command_ptr],eax
  mov	[users_feed_hook],ebx
  mov	[users_capture_hook],ecx
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

  mov	byte [abort_flag],-1
  xor	eax,eax
  mov	[child_pid],eax
  mov	[master_fd],eax
  mov	[slave_fd],eax
;launch program in pty terminal
  call	ptyopen		;open a psuedo tty and launch executable
;slave is running, ptyopen puts [master_fd] in eax and at [master_fd]
  mov	ebp,20h		;restart error id
  or	eax,eax
  jns	service_slave

abort1:
  jmp	finish
service_slave:
;this is loop for reading & writing psuedo tty stdin/stdout
;zero read readmasks for select call --------------------
service_slave_loop:
;  call	key_flush
ssl_continue:
  inc	byte [abort_flag]
  jnz	abort_jmp1	;jmp if abort request

  mov	esi,select_list	;list of fd's to poll
  mov	eax,0		;wait forever
  call	wait_event	;wait for stdin or slave, returns buffer in ecx

  mov	[event_count],eax ;save return status
  dec	byte [abort_flag]
  jns	abort_jmp1	;exit if abort flag set

  cmp	al,-4		;is this a signal notification
  je	ssl_continue	;jmp if a signal interrupted us
  mov	[event_buf],ecx
  or	eax,eax
  js	abort_jmp1	;jmp if child has died
  jnz	ssl_cont	;jmp if event count found

abort_jmp1:
  jmp	finish			;exit if child dead
ssl_cont:
  xor	eax,eax			;stdin
  mov	edi,[event_buf]
  call	bit_test
  jc	pp_stdin		;jmp if stdin has data
  jmp	pp_10
;keyboard input found
pp_stdin:
  mov	eax,3			;read
  mov	ebx,0			;stdin
  mov	ecx,wrap_buf		;buffer pointer;;
  mov	edx,wrap_buf_size			;buffer size
  int	80h
  mov	[read_stdin_count],eax
  or	eax,eax
  js	finishj			;exit if error
  jnz	contx			;if user typed eof then exit
finishj:
  jmp	finish
contx:
  add	ecx,eax			;advance kbuf ptr
  mov	byte [ecx],0		;put zero at end
  mov	ecx,wrap_buf		;get data buffer
  mov	edx,eax
;check if caller wants to be called back
  mov	ebx,[users_feed_hook]
  or	ebx,ebx
  jz	write_key		;jmp if no callers hook
  call	ebx
  mov	ebp,36h
  or	edx,edx
;
;ainfo failed because it returns zero if key is handled.
;the following jz was added to fix this problem.

  jz	pp_10			;jmp if ignore requested
  jns	write_key		;jmp if not abort
  mov	eax,edx
  jmp	short finishj		;exit if users done
;write key to child
write_key:
  mov	eax,4
  mov	ebx,[master_fd]
  int	80h
  or	eax,eax
;ainfo returns different counts and requires
;we not track amount written
  jns	pp_10			;jmp if no error
;  js	finishw
;check if correct amount written
;  cmp	eax,[read_stdin_count]	;was correct amount written?
;  je	pp_10			;jmp if write ok
finishw:
  jmp	finish
;--------------
;check if user output for stdout available
pp_10:

%ifdef DEBUG
  call	log_terminal_0
  push	ebx
  mov	ebx,[master_fd]
  call	log_terminal_x
  pop	ebx
%endif

  mov	eax,[master_fd] ;bit number
  mov	edi,[event_buf]
  call	bit_test	;is stdin ready
  jnc	cco_donej	;jmp if stdout not ready
;read the users stdout data
pp_20:
  mov	eax,3		;read
  mov	ebx,[master_fd]	;file descriptor
  mov	ecx,wrap_buf	;buffer
  mov	edx,wrap_buf_size		;max read size
  int	80h		;read data
;check if good read
  or	eax,eax		;
;;  jz	finishj		;if zero read, assume child dead
  jz	cco_donej	;;
  cmp	eax,-4		;check if signal interrupted us
  jne	cco_continue	;jmp if no signal error
  jmp	short pp_20	;;
;;  xor	eax,eax		;set normal return and retry read
cco_donej:
  jmp	short cco_done	;keep trying?
cco_continue:
  js	finishj		;exit if other error occured
  mov	[read_slave_count],eax
  add	ecx,eax		;compute data end
;we have a good read, check if caller want to be called
  mov	ecx,wrap_buf	;buffer to ecx
  mov	edx,eax		;write count -> edx
  mov	ebx,[users_capture_hook]
  or	ebx,ebx
  jz	cco_20		;jmp if no callers hook
  call	ebx
  or	edx,edx
;note:
; the following jz should probably check if there is more
; data to write, but instead it assumes the block of data
; is done.  If we have blocks larger than 8097 this logic
; will fail.  We may need to restore origional write request
;
  jz	cco_done	;jmp if no data to write
  jns	cco_20		;jmp if not abort
  xor	eax,eax		;set good status for return
  jmp	short finish	;exit if users done
cco_20:
  mov	eax,4		;write
  mov	ebx,1		;write to stdout
  int	80h
  mov	ebp,41h		;set error id = 40h
  or	eax,eax
  js	finish		;jmp if write error
  cmp	eax,[read_slave_count]
  jne	finish		;err if not all data written
  cmp	eax,wrap_buf_size		;is this a possible partial buffer?
  je	pp_20		;go try to read more
cco_done:
  jmp	service_slave_loop
;-----------------------------------------------------------------
;------------finish -------------all done, clean up
finish:
  mov	byte [last_kernel_rtn],al	;save al
  mov	byte [parent_err_flag],al
  call	signal_restore		;restore SIGCHLD
;kill child
  mov	eax,37
  mov	ebx,[child_pid]
  or	ebx,ebx
  jz	finish2			;jmp if child not forked yet
  mov	ecx,9			;kill signal
  int	80h
;wait for child to exit
keep_waiting:
  mov	ebx,[child_pid]
  mov	ecx,execve_status
  xor	edx,edx
  mov	eax,7
  int	80h			;wait for child, PID in ebx
  cmp	eax,-4			;did we interrupt a signal
  je	keep_waiting
;get status of child process
  sub	eax,eax
  mov	al,byte [execve_status +1]
  mov	byte [harvested_child_status],al
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
  mov	eax,[status_block]	;get status

%ifdef DEBUG
  call	log_hex
  call	log_eol
%endif

  ret

;-----------------------------------------------------------------
ptyopen:    ;08048ADA
;open master psuedo tty
  mov	eax,5			;open kernel call
  mov	ebx,ptmx_path
  mov	ecx,02			;O_RDRW
  int	80h			;open /dev/ptmx
  mov	[master_fd],eax
  or	eax,eax
  js	ptyopen_abort
;open slave psuedo terminal
;call grantpt to set slave permissions
  mov	ebx,eax			;set ebx -> master_fd
  mov	eax,54			;ioctl kernel call
  mov	ecx,80045430h		;grantpt ioctl
  mov	edx,wrap_buf
  int	80h
  or	eax,eax
  js	ptyopen_abort
;build name of pts
  mov	eax,[wrap_buf]
  or	al,'0'
  mov	[pts_path2],al
;unlock the slave (unlockpt)
  mov	eax,54			;ioctl kernel call
;  mov	ebx,[master_fd]
  mov	ecx,40045431h		;TIOCSPLTLCK
  mov	edx,blockx		;this appears to be needed!
;old code had mov edx,blockx here (blockx = 0)?
  int	80h
  or	eax,eax
  js	ptyopen_abort
; open slave
  mov	eax,5
  mov	ebx,pts_path1
  mov	ecx,102h	;O_RDWR O_NOCTTY
  mov	edx,0
  int	80h
  mov	[slave_fd],eax

;fork duplicates program, including signal handling, open fd's etc.
;     only pending signals are cleared and PID changed.
;fork ---- fork
  mov	eax,2		;fork
  int	80h
  mov	[child_pid],eax
  or	eax,eax
  jz	child_processing
;parent path -- exit ---
;return(master)
parent_return:
  mov	eax,[master_fd]
ptyopen_abort:
  ret
  
;child processing ---------------------------- child -----------

child_processing:
;get rid of current controlling terminal
;make child tty a controlling tty so that /dev/tty points to us
  mov	eax,66
  int	80h		;setsid
;close master fd, no longer needed
  mov	ebx,[master_fd]
  call	file_close
;dup2 stdin
  mov	eax,63		;dup2
  mov	ebx,[slave_fd]
  xor	ecx,ecx		;stdin
  int	80h
;dup2 stdout
  mov	eax,63		;dup2
  mov	ebx,[slave_fd]
  inc	ecx		;ecx->1 (stdout)
  int	80h
;dup stderr
  mov	eax,63		;dup2
  mov	ebx,[slave_fd]
  inc	ecx		;ecx -> 2 (stderr)
  int	80h
;close slave_fd, don't need anymore, it is now stdin,stdout,stderr
  mov	ebx,[slave_fd]
  call	file_close
  mov	[slave_fd],dword 0
  mov	dword [child_termios+term_info_struc.c_iflag],dword 0100h
  mov	dword [child_termios+term_info_struc.c_lflag],dword 8a3bh
;now set new tty mode
  mov	edx,child_termios
  call	output_term_info_0

;execute command ----  exec ----
; execve passes PID and open fd's on.  Signals are
; set to their defualt state.  The SIGCHLD state is
; undetermined if set to SIG_IGN (no handler)
; pending signals are cleared.
  mov	esi,[callers_command_ptr]
  call	sys_run_die
;should not get here
  mov	eax,1
  int	80h			;exit
;end of child processing ----

%ifdef DEBUG
;------------------------------------------------------------------
; eax = signal number
; esi = ptr to signal name string

sig_handler:
  cmp	eax,17		;SIGCHLD ?
  jne	SIGCHLD_exit
%endif
SIGCHLD_trap:
  inc	byte [abort_flag]		;set abort flag
  jz	SIGCHLD_exit			;jmp if not in I/O wait
;trigger select action if waiting
  mov	ecx,pts_path2
  mov	edx,1
  mov	eax,4
  mov	ebx,[master_fd]
  int	80h
SIGCHLD_exit:
  ret
;------------------------------------------------------------------
signal_setup:
  mov	eax,67
  mov	ebx,17		;SIGCHLD
  mov	ecx,SIG_block
%ifdef DEBUG
  mov	dword [ecx],sig_handler
%endif
  xor	edx,edx		;disable save of previous state
  int	80h
  ret  
;------------------------------------------------------------------
signal_restore:
%ifdef DEBUG
  mov	ebx,1
sr_loop:
  push	ebx
  call	signal_handler_default
  pop	ebx
  inc	ebx
  cmp	ebx,31
  jb	sr_loop
  ret
%endif
  
  mov	ebx,17
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

;start status block
status_block:
harvested_child_status db 0
parent_err_flag	       db 0
last_kernel_rtn        db 0
abort_flag             db -1	;-1(normal) 0(in wait) 1(abort)

  global child_pid
child_pid	dd	0
slave_fd	dd	0
read_stdin_count	dd	0		;amount read from stdin
read_slave_count	dd	0		;amoun

  global master_fd
select_list:
stdin_fd	dd	0		;do not remove
master_fd	dd	0
		dd	-1		;end of select list
event_count	dd	0		;number of events from select
event_buf: dd	0	;holds ptr to event bits

users_feed_hook	dd	0
users_capture_hook dd	0

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

