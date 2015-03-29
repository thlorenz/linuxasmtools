
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

extern env_stack

 global _start,begin
begin:
_start:
  call	env_stack
  mov	eax,ls_program
  mov	ebx,buffer
  mov	ecx,buffer_size
  call	sys_pipe_capture
  mov	eax,1
  int	80h		;exit
;-----------------
  [section .data]
ls_program: db '/bin/ls',0
buffer_size	equ 1000
buffer times buffer_size db 0
  [section .text]
;---------------------------------------------------------
;****f* sys/sys_pipe_capture *
; NAME
;>1 sys
;  sys_pipe_capture - launch program and capture its stdout
;    (the sys_wrap function is a better choice, this function
;     is becoming obsolete)
; INPUTS
;    [enviro_ptrs] - global set by calling env_stack
;    eax = ptr to program string
;          this is normal shell command string
;    ebx = buffer to hold output from program
;    ecx = size of buffer
; OUTPUT
;    eax = shell program exit status (in -al-)
;          (if eax negative an error occured)
;    ebx = updated buffer ptr after data stored.
; NOTES
;    source file: sys_pipe_capture.asm
;<
;  * ----------------------------------------------
;*******
  [section .text]
  extern enviro_ptrs

;
  global sys_pipe_capture
sys_pipe_capture:
  mov	[callers_cmd],eax
  mov	[output_buf_ptr],ebx
  mov	[output_buf_size],ecx
  mov	eax,42		;pipe
  mov	ebx,filides
  int	80h
; fork
  mov	eax,2		;fork
  int	80h
  or	eax,eax
  jz	child_process
; parent process continues, eax = child PID
  mov	[child_pid],eax
  mov	eax,6		;close
  mov	ebx,[write_fd]	;  pipe for writing
  int	80h
;read data from pipe
  mov	ecx,[output_buf_ptr]
read_lp:
  mov	eax,3		;read
  mov	ebx,[read_fd]
  mov	edx,[output_buf_size]
  int	80h
  or	eax,eax
  jz	read_done	;jmp if child finished sending
  js	abort_jmp
  add	ecx,eax		;move pointer in read buf
  sub	[output_buf_size],eax
abort_jmp:
  js	abort
  jmp	short read_lp
;close pipe
read_done:
  mov	[buf_ptr],ecx
  mov	eax,6
  mov	ebx,[read_fd]	;close parent pipe
  int	80h
  or	eax,eax
  js	abort
;wait for child to exit
  mov	ebx,[child_pid]
  mov	ecx,execve_status
  xor	edx,edx
  mov	eax,7
  int	80h			;wait for child, PID in ebx
;get buffer ptr
  mov	ebx,[buf_ptr]
;get status of child process
  mov	al,byte [execve_status +1]
  or	al,al
  ret  
;-------------------
child_process:
  mov	eax,6		;close
  mov	ebx,[read_fd]	;  pipe for reading
  int	80h

  mov	eax,63		;dup2
  mov	ebx,[write_fd]
  mov	ecx,1		;swap write_fd with stdout
  int	80h

  mov	eax,6		;close write pipe
  mov	ebx,[write_fd]
  int	80h
; execute shell program
  mov	ebx,[execve_full_path]
  mov	ecx,execve_full_path
  mov	edx,[enviro_ptrs]
  mov	eax,11		;execve
  int	80h
;
; if we get here all attempts to execute a program failed
;
abort:
  mov	eax,6		;close write pipe
  mov	ebx,[read_fd]
  int	80h
  mov	eax,6		;close write pipe
  mov	ebx,[write_fd]
  int	80h
  
  mov	ebx,11h			;no child process
  mov	eax,1
  int	80h			;abort out
;--------------------------------------------
 [section .data]

shell_string:		db	'/bin/sh',0
shell_parm:		db	'-c',0

execve_full_path:	dd	shell_string
exc_args:		dd	shell_parm	;ptr to parameter1
callers_cmd:		dd	0	;ptr to parameter2
			dd	0	;ptr to parameter3
			dd	0

execve_status		db	0,0,0,0,0,0,0,0

output_buf_ptr: dd	0 ; buffer to hold results
output_buf_size: dd	0 ;size of output buffer
buf_ptr		dd	0

filides:		;filled in by pipe function
read_fd: dd	0
write_fd: dd	0
;
; child data area
child_pid  dd	0

