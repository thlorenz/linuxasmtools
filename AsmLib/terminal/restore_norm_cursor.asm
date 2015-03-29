
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

  extern norm_cursor
  extern restore_cursor_from
    
;>1 terminal
;   restore_norm_cursor - restore cursor for normal window
; INPUTS
;   none
; OUTPUT
;   none
; NOTES
;    source file: restore_norm_cursor.asm
;
;    This function assumes we are on a x-terminal and restores
;    the normal window cursor.  If no cursor has been saved
;    previously, it sets the cursor to 1,1
;<
;------------------------------------------------------------------
  global restore_norm_cursor
restore_norm_cursor:
  mov	esi,norm_cursor
  call	restore_cursor_from
  ret

