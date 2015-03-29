
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

  extern save_cursor
  extern stdout_str
  extern read_stdin
  extern delay
  extern str_move
  extern kbuf
    
  global alt_screen
    
;>1 terminal
;   save_cursor_at - save cursor position
; INPUTS
;   edi = location to save cursor (10 bytes)
; OUTPUT
;   edi = ptr to end of saved cursor
;      format is: db 1bh ;escape char
;                 db '['
;                 db '1' ;ascii row, 1 or 2 digits
;                 db ';' ;separator
;                 db '1' ;ascii column, 1 or 2 digits
;                 db 'H' ;end code (set by restore_cursor_from)
;                 db  0  ;string end
;
; NOTES
;    source file: save_cursor_at.asm
;
;    processing: - send escape sequences to terminal
;                - read return info. from stdin using read_stdin
;                - save returned data at [edi]
;
;<
  global save_cursor_at
save_cursor_at:
  mov	ecx,save_cursor_cmd
  call	stdout_str
  call	read_stdin		;read cursor position
  mov	esi,kbuf
  call	str_move
  ret

save_cursor_cmd: db 1bh,'[6n',0

;----------------------------------
  [section .text]
