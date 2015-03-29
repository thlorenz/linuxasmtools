
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
  extern output_termios_0
  extern is_raw_term
  extern crt_str
  extern delay
  extern kbuf
  extern str_move
  extern key_mouse2

struc termio_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termio_struc_size:
    
;****f* crt/save_cursor *
; NAME
;>1 crt
;   save_cursor - save current cursor position
; INPUTS
;    none
; OUTPUT
;    [saved_cursor] - global string with cursor info
;    see restore_cursor for format
; NOTES
;    source file save_restore_cursor.asm
;<
;  * ---------------------------------------------------
;*******

;----------------------------------
  global save_cursor
save_cursor:
  call	is_raw_term
  je	sc_32			;jmp if terminal in raw mode
  and	byte [edx + termio_struc.c_lflag],~2  ;set raw mode
  call	output_termios_0
  push	edx
  call	sc_32
  pop	edx
  or	byte [edx + termio_struc.c_lflag],2	;clear raw mode
  call	output_termios_0
  ret

sc_32:				;come here if current mode is raw
  mov	ecx,save_cursor_cmd
  call	crt_str
  mov	eax,100000
  call	delay
  call	key_mouse2		;read cursor position
  mov	esi,kbuf
  mov	edi,saved_cursor
  call	str_move
;erase this line, if echo is enabled in termios then this line may have cursor posn
  mov	ecx,erase_line_cmd
  call	crt_str
  ret
erase_line_cmd: db 1bh,'[2K',0

;----------------------------------
;****f* crt/restore_cursor *
; NAME
;>1 crt
;   restore_cursor - restore cursor position
; INPUTS
;    [saved_cursor] - global string with cursor info
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
  global restore_cursor
restore_cursor:
  mov	esi,saved_cursor
rc_lp:
  lodsb
  or	al,al
  jnz	rc_lp		;loop till end of string
  mov	byte [esi-2],'H' ;stuff set cursor code
  mov	ecx,saved_cursor ;setup for string output
  call	crt_str
  ret
;----------------------------------
;------------
  [section .data]
  global saved_cursor
saved_cursor: db 1bh,'[1;1H',0,0,0,0  ;default cursor is row-1 col-1
save_cursor_cmd: db 1bh,'[6n',0
  [section .text]
