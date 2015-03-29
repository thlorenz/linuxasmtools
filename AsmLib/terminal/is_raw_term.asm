
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
  extern lib_buf
  extern read_termios_0


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
    
;>1 terminal
;   is_raw_term - check if stdin is in raw mode
; INPUTS
;    none
; OUTPUT
;   edx = pointer to termios structure
;   flags set for je=raw  jne=cooked
; NOTES
;    source file /crt/is_raw_term.asm
;    lib_buf is temp buffer holding termios
;<
;  * ---------------------------------------------------

  global is_raw_term
is_raw_term:
  mov	edx,lib_buf
  call	read_termios_0
;  * edx = ptr to termios save buffer, size = 36 bytes
;  * struc termio_struc
;  * .c_iflag: resd 1
;  * .c_oflag: resd 1
;  * .c_cflag: resd 1
;  * .c_lflag: resd 1
;  * .c_line: resb 1
;  * .c_cc: resb 19
  test	byte [edx+termio_struc.c_lflag],2
  ret