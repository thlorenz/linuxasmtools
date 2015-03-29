
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

  extern save_cursor_at

    
;>1 terminal
;   save_alt_cursor - save cursor and assume alt window active
; INPUTS
;   none
; OUTPUT
;   none
; NOTES
;    source file: save_alt_cursor
;
;    This function only works on x-terminal
;
;    The current window cursor is saved at global
;    location "alt_cursor"
;      format is: db 1bh ;escape char
;                 db '['
;                 db '1' ;ascii row, 1 or 2 digits
;                 db ';' ;separator
;                 db '1' ;ascii column, 1 or 2 digits
;                 db 'H' ;end code (set by restore_cursor)
;                 db  0  ;string end
;<
  global save_alt_cursor
;------------------------------------------------------------------
save_alt_cursor:
  mov	edi,alt_cursor
  call	save_cursor_at
  ret
;------------------------------------------------------------------
  [section .data]
  global alt_cursor

alt_cursor	db	1bh,'[1;1H',0,0,0,0,0,0,0,0,0,0,0,0

