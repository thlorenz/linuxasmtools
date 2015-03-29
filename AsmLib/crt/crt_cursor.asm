
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
  extern crt_str

;--------------------------------------------------------------
;>1 crt
; cursor_hide - hide the cursor
;   inputs:
;      none
;   outputs:
;      none, register ecx modified
;   operation:
;      call vt-100 control sequence ESC "[?25l" to hide cursor
;   note:
;      source file: crt_cursor.asm          
;<
;-------------------------------------------------------------------------             
  global cursor_hide
cursor_hide:
  mov	ecx,hide_string
  call	crt_str
  ret
  [section .data]
hide_string:  db 1bh,'[?25l',0
  [section .text]
;-------------------------------------------------------------------------
;>1 crt
; cursor_unhide - unhide the cursor
;   inputs:
;      none
;   outputs:
;      none, register ecx modified
;   operation:
;      call vt-100 control sequence ESC "[?25h" to unhide cursor
;   note:
;      source file: crt_cursor.asm          
;          
;<
;-------------------------------------------------------------------------             
  global cursor_unhide
cursor_unhide:
  mov	ecx,unhide_string
  call	crt_str
  ret
  [section .data]
unhide_string db 1bh,'[?25h',0
  [section .text]


