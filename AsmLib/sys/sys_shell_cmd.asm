
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
;--------------------------------------------------------------------
;****f* sys/sys_shell_cmd *
; NAME
;>1 sys
;  sys_shell_cmd - launches local shell
; INPUTS
;    [enviro_ptrs] - global var set by function env_stack
;    esi = ptr to shell commands
;          example: db  "ls -a;ls",0
;    the global buffer "lib_buf" is used to build path
; OUTPUT
;    The enviornment varialbe SHELL is used to find shell
;    and it is launched.  The screen is not cleared and
;    the shell inherits the path of parent.
;     
;    failure - eax= negative error code
;
;    possible
;    success - eax=pid of completed process
;              
;              if bl=0 then bh=process exit code
;              if bl=1-7e then bh=signal that killed process
;              if bl=7f then bh=signal that stopped process
;              if bl=ff then bh=signal that continued process
;    flags set for "js" and "jns" on eax state
; NOTES
;    source file: sys_shell_cmd.asm
;<
;  * ----------------------------------------------
;*******
  extern lib_buf,str_move
  extern env_shell,sys_run_wait
  global sys_shell_cmd
sys_shell_cmd:
  push	esi
  mov	edx,lib_buf
  call	env_shell	;stores shell path at lib_buf
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
  mov	esi,lib_buf
  call	sys_run_wait
  ret

shell_cmd:  db '-lc',0
