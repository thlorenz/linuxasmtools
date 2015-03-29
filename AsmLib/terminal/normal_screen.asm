
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

  extern save_alt_cursor
  extern restore_norm_cursor
  extern stdout_str
    
;>1 terminal
;   normal_screen - switch to normal terminal screen
; INPUTS
;   none
; OUTPUT
;   none
; NOTES
;    source file: alt_screen.asm
;
;    this function works in x-terminal
;
;    processing - exit if already in normal window.  This
;                 check uses a global flag (twindow_state)
;                 which tracks state of normal/alt windows.
;                 twindow_state = 0 if in normal window.
;               - call save_alt_cursor.
;               - switch to normal window
;               - restore normal window cursor position
;<
  global normal_screen
normal_screen:
  cmp	byte [twindow_state],0
  je	ns_assert		;jmp if alread in normal window
  call	save_alt_cursor
  mov	ecx,norms_msg
  call	stdout_str
  call	restore_norm_cursor
  mov	byte [twindow_state],0
  jmp	short ns_exit
ns_assert:
  mov	ecx,norms_msg
  call	stdout_str
ns_exit:
  ret
norms_msg  db  1bh,'[?47l',0

;----------------------------------
  [section .data]
  global twindow_state
twindow_state	db	0	;0=normal screen 1=altscreen
