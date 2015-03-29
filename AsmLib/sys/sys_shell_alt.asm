
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
;****f* sys/sys_shell_alt *
; NAME
;>1 sys
;  sys_shell_alt - launches local shell in alternate window
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
;    source file: sys_shell_alt.asm
;<
;  * ----------------------------------------------
;*******
  extern crt_str,crt_clear,terminal_type,sys_shell
  global sys_shell_alt
sys_shell_alt:
  call	sys_win_alt
  cmp	byte [terminal_type],0
  je	ssa_20		;skip vt100 codes if console
  jmp	short ssa_30
ssa_20:
  mov	eax,30003730h	;get color
  call	crt_clear
ssa_30:
  call	sys_shell
  call	sys_win_normal
ssa_40:
  ret
  
shell_normal	db	1bh,'[?47l',0
shell_alt	db	1bh,'[?47h',0

;****f* sys/sys_win_alt *
; NAME
;>1 sys
;  sys_win_alt - switches to Vt100 alt windows
; INPUTS
;    check if in console before using this function
; OUTPUT
;    alternate terminal window selected
; NOTES
;    source file: sys_shell_alt.asm
;<
;  * ----------------------------------------------
;*******

  global sys_win_alt
sys_win_alt:
;  cmp	byte [terminal_type],0
;  je	swa_exit		;skip vt100 codes if console
  mov	ecx,shell_alt
  call	crt_str
swa_exit:
  ret

;****f* sys/sys_win_normal *
; NAME
;>1 sys
;  sys_win_normal - selects normal Vt100 windows
; INPUTS
;  check if in console before calling
; OUTPUT
;  normal terminal window selected
; NOTES
;  source file: sys_shell_alt.asm
;<
;  * ----------------------------------------------
;*******

  global sys_win_normal
sys_win_normal:
;  cmp	byte [terminal_type],0
;  je	swn_exit		;skip vt100 codes if console
  mov	ecx,shell_normal
  call	crt_str
swn_exit:
  ret

