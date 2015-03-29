
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
  extern crt_open,crt_close
  extern sys_shell_cmd
  extern reset_terminal
  extern sys_win_alt
  extern sys_win_normal
  extern mouse_enable

  [section .text]

struc wnsize_struc
.ws_row:resw 1
.ws_col:resw 1
.ws_xpixel:resw 1
.ws_ypixel:resw 1
endstruc
;wnsize_struc_size

struc termio_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termio_struc_size:

    
;****f* sys/sys_shell_plus *
; NAME
;>1 sys
;   sys_shell_plus - execute shell and restore terminal state
; INPUTS
;    eax = shell command string ptr
;     bl = flags   01h = crt_open has been called 
;                  02h = use alternate screen
; OUTPUT
;   eax = negative if error
; NOTES
;    source file sys_shell_plus
;<
;  * ---------------------------------------------------
;*******
;--------------------------------

  global sys_shell_plus
sys_shell_plus:
  push	eax
  mov	[ssp_flag],bl		;save flags
  test	bl,1
  jz	ssp_10			;jmp if crt_open not active
  call	crt_close
ssp_10:
  test	byte [ssp_flag],2	;check if alt window wanted
  jz	ssp_20			;jmp if no alt window
  call	sys_win_alt		;select alternate window
ssp_20:
  pop	esi
;  * esi = ptr to program string
;  * -     this is normal shell command string
  call	sys_shell_cmd
  push	eax			;save copy return code
  test	byte [ssp_flag],2
  jz	ssp_40			;jmp if not alt window in use
  call	sys_win_normal
ssp_40:
  call	reset_terminal
  test	byte [ssp_flag],1	;check if crt was open
  jz	ssp_60			;jmp if crt_open call inactive
  call	crt_open
ssp_60:
  call	mouse_enable
  pop	eax			;restore copy return code
 ret
;----------
  [section .data]
ssp_flag:  db	0
  [section .text]

