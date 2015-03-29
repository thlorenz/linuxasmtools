
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
;--------------------------------------------------------------------
;****f* sys/sys_shell *
; NAME
;>1 sys
;  sys_shell - launches local shell
; INPUTS
;    [enviro_ptrs] - global var set by function env_stack
;    the global buffer "lib_buf" is used to build path
; OUTPUT
;    The enviornment varialbe SHELL is used to find shell
;    and it is launched.  The screen is not cleared and
;    the shell inherits the path of parent.
;     
;    al = byte two of execve_status
;    [execve_status] - contains results from execve
;      al = 0 success
;      al = 11 could not launch child
;      al = negative (system error code)
;      flags set for jz,js,jnz,jns jumps
; NOTES
;    source file: sys_shell.asm
;<
;  * ----------------------------------------------
;*******
;  extern crt_close,crt_open
  extern lib_buf,env_shell,sys_ex
  global sys_shell
sys_shell:
;  call	crt_close		;restore terminal state
  mov	edx,lib_buf
  mov	al,'|'
  mov	[edx],al	;put separator on front
  inc	edx
  call	env_shell
  mov	esi,lib_buf
  call	sys_ex
;  call	crt_open
  ret  

