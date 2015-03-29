
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

  extern stdout_str

;----------------------------------
;>1 terminal
;   restore_cursor_from - restore cursor position
; INPUTS
;    [esi] - global string with cursor info
;      format is: db 1bh ;escape char
;                 db '['
;                 db '1' ;ascii row, 1 or 2 digits
;                 db ';' ;separator
;                 db '1' ;ascii column, 1 or 2 digits
;                 db 'H' ;end code (set by restore_cursor)
;                 db  0  ;string end
; OUTPUT
;    none
; NOTES
;    source file save_restore_cursor.asm
;<
;  * -
;  * ---------------------------------------------------
;*******
  global restore_cursor_from
restore_cursor_from:
;  mov	esi,saved_cursor
  push	esi
rc_lp:
  lodsb
  or	al,al
  jnz	rc_lp		;loop till end of string
  mov	byte [esi-2],'H' ;stuff set cursor code
  pop	ecx              ;restore ptr to cursor string
  call	stdout_str
  ret
;----------------------------------
