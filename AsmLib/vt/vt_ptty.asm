
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
 extern str_move
 extern read_term_info_0
 extern output_term_info_0
 extern lib_buf


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
;   vt_ptty_setup - wrap around an executable and capture in/out
; INPUTS
;    eax = ptr to command (see below)
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
;
;    [ptty_fd] - child terminal fd
;    If a signal is wanted for the ptty_fd, set it up
;    before calling vt_ptty_launch.  If no signal the
;    ptty_fd needs to be polled and serviced.
; 
; NOTES
;    source file vt_ptty.asm
;     
;<
;---------------------------------------------------------------
  global vt_ptty_setup
vt_ptty_setup:
  mov	[callers_command_ptr],eax
;get termios, used to set and restore tty modes
  mov	edx,child_termios
  call	read_term_info_0
;save state for SIGCHLD,SIGING,SIGQUIT signals & add handler
;  call	signal_setup

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

  xor	eax,eax
  mov	[ptty_pid],eax
  mov	[ptty_fd],eax
  mov	[slave_fd],eax
;launch program in pty terminal
;-----------------------------------------------------------------
;ptyopen:    ;08048ADA
;open master psuedo tty
  mov	eax,5			;open kernel call
  mov	ebx,ptmx_path
  mov	ecx,02			;O_RDRW
  int	80h			;open /dev/ptmx
  mov	[ptty_fd],eax
  or	eax,eax
  js	ptyopen_abort
;open slave psuedo terminal
;call grantpt to set slave permissions
  mov	ebx,eax			;set ebx -> ptty_fd
  mov	eax,54			;ioctl kernel call
  mov	ecx,80045430h		;grantpt ioctl
  mov	edx,ptty_number
  int	80h
  or	eax,eax
  js	ptyopen_abort
;build name of pts
  mov	eax,[ptty_number]
  or	al,'0'
  mov	[pts_path2],al
;unlock the slave (unlockpt)
  mov	eax,54			;ioctl kernel call
;  mov	ebx,[ptty_fd]
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
  ret
;-------------------------------------------------
; launch program in ptty
;OUTPUT:
;    [ptty_pid] - the global variable ptty_pid is available at
;                  vt_ptty executes for possible abort of the child.
;                  This might be possible if a program hangs up and
;                  somehow keyboard intercept or signal detected the
;                  problem.
;
  global vt_ptty_launch
vt_ptty_launch:
;fork duplicates program, including signal handling, open fd's etc.
;     only pending signals are cleared and PID changed.
;fork ---- fork
  mov	eax,2		;fork
  int	80h
  mov	[ptty_pid],eax
  or	eax,eax
  jz	child_processing
;parent path -- exit ---
;return(master)
parent_return:
  mov	eax,[ptty_fd]
ptyopen_abort:
  ret
  
;child processing ---------------------------- child -----------

child_processing:
;get rid of current controlling terminal
;make child tty a controlling tty so that /dev/tty points to us
  mov	eax,66
  int	80h		;setsid
;close master fd, no longer needed
  mov	ebx,[ptty_fd]
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
  mov	dword [child_termios+term_info_struc.c_iflag],4500H
;  mov	dword [child_termios+term_info_struc.c_iflag],dword 0100h
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

;------------------------------------------------------------------
  [section .data]

callers_command_ptr dd	0	;ptr to callers command

  global ptty_pid
ptty_pid	dd	0
  global slave_fd
slave_fd	dd	0

  global ptty_fd
ptty_fd	dd	0


ptmx_path	db	'/dev/ptmx',0
pts_path1	db	'/dev/pts/'
pts_path2	db	0,0,0,0
blockx:		dd	0
ptty_number	times 4 db 0


child_termios times term_info_struc_size db 0


  [section .text]

