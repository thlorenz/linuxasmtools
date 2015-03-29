
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
  extern output_winsize_x
  extern output_termios_x

  [section .text]

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
    

; NAME
;>1 terminal
;   output_term_info_0 - output stdin window size and settings
; INPUTS
;    edx = ptr to info struc, size = 44 bytes
;    struc term_info_struc
;    .ws_row:resw 1		;winsize struc
;    .ws_col:resw 1
;    .ws_xpixel:resw 1
;    .ws_ypixel:resw 1
;    .c_iflag: resd 1		;termios struc
;    .c_oflag: resd 1
;    .c_cflag: resd 1
;    .c_lflag: resd 1
;    .c_line: resb 1
;    .c_cc: resb 19
; OUTPUT
;    structure at edx filled int
; NOTES
;    source file: output_term_info.asm
;<
;  * ---------------------------------------------------
;*******
    
; NAME
;>1 terminal
;   output_term_info_x - output terminal structure "termios"
; INPUTS
;    ebx = fd (file descriptor) of terminal
;    edx = ptr to winsize struc, size = 44 bytes
;    struc term_info_struc
;
;    .ws_row:resw 1		;winsize struc
;    .ws_col:resw 1
;    .ws_xpixel:resw 1
;    .ws_ypixel:resw 1
;    .c_iflag: resd 1		;termios struc
;    .c_oflag: resd 1
;    .c_cflag: resd 1
;    .c_lflag: resd 1
;    .c_line: resb 1
;    .c_cc: resb 19
; OUTPUT
;   structure at edx filled in 
; NOTES
;    source file: output_term_info.asm
;<
;  * ---------------------------------------------------
;*******

  global output_term_info_x
  global output_term_info_0
output_term_info_0:
  xor	ebx,ebx			;get fd for stdin
output_term_info_x:
  call	output_winsize_x
  add	edx,wnsize_struc_size
  call	output_termios_x
  ret

