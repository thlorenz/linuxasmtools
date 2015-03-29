
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

  extern save_norm_cursor
  extern restore_alt_cursor
  extern stdout_str
  extern twindow_state
    
;>1 terminal
;   alt_screen - switch to alt terminal screen
; INPUTS
;   none
; OUTPUT
;   none
; NOTES
;    source file: alt_screen.asm
;
;    This function only works on x-terminal
;
;    processing - exit if already in alt window.  This
;                 check uses a global flag (twindow_state)
;                 which tracks state of normal/alt windows.
;                 twindow_state = 1 if in alt window.
;               - call save_norm_cursor
;               - switch to alt window
;               - restore alt cursor posn  
;<
  global alt_screen
;---------------------------
alt_screen:
  cmp	byte [twindow_state],1
  je	as_assert		;jmp if alread in normal window
  call	save_norm_cursor
  mov	ecx,alts_msg
  call	stdout_str
  call	restore_alt_cursor
  mov	byte [twindow_state],1	;set alt window state
  jmp	short as_exit
as_assert:
  mov	ecx,alts_msg
  call	stdout_str
as_exit:
  ret
alts_msg  db  1bh,'[?47h',0
;---------------------------

