
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
;   save_norm_cursor - save cursor and assume normal window active
; INPUTS
;   none
; OUTPUT
;   none
; NOTES
;    source file: save_norm_cursor
;
;    save_norm_cursor assumes we are in normal terminal window
;    and saves cursor position in global "norm_cursor".
;<
  global save_norm_cursor
save_norm_cursor:
  mov	edi,norm_cursor
  call	save_cursor_at
  ret
;------------------------------------------------------------------
  [section .data]
  global norm_cursor
norm_cursor	db  1bh,'[1;1H',0,0,0,0,0,0,0,0,0,0


