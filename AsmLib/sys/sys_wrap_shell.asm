
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

  [section .text]  

%ifdef DEBUG
 extern env_stack

 global _start
 global main
_start:
main:    ;080487B4
  cld
  call	env_stack

  mov	esi,the_command
  xor	ebx,ebx
  xor	ecx,ecx
  call	sys_wrap_shell

  mov	eax,1
  int	80h

the_command: db "ls",0,0

%endif
;--------------------------------------------------------------------
; NAME
;>1 sys
;  sys_wrap_shell - launches command in wrapped shell
;
; INPUTS
;    esi = ptr to command (see below)
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
; NOTES
;    source file: sys_wrap_shell.asm
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
;  * ----------------------------------------------
;*******
  extern lib_buf,str_move
  extern env_shell
  extern sys_wrap
  global sys_wrap_shell
sys_wrap_shell:
  push	ebx		;save feed process
  push	ecx		;save capture process
  push	esi		;save command ptr
  mov	edx,lib_buf+500
  call	env_shell	;stores shell path at lib_buf+500
  xor	eax,eax
  stosb			;put zero after executable path
  mov	esi,shell_cmd
  call	str_move
  stosb			;put zero after -c
;  mov	al,60h
;  stosb			;quote
  pop	esi		;restore input parameters
  call	str_move
;  mov	al,60h
;  stosb
  xor	eax,eax
  stosd			;add final zero byte
  mov	eax,lib_buf+500
  pop	ecx		;restore capture process
  pop	ebx		;restore feed process
  call	sys_wrap
  ret

shell_cmd:  db '-c',0


