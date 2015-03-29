
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
  extern read_winsize_x
  extern read_termios_x

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
;   read_term_info_0 - save stdin window size and settings
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
;    structure at edx filled in
; NOTES
;    source file read_term_info.asm
;
;    see also: crt_type - returns $TERM usually as "linux" or "xterm"
;              terminal_type - returns code for console,xterm,clone
;              read_winsize_x - returns winsize struc
;              read_term_info_x - returns termios and winsize struc
;              read_window_size - returns text size for console,xterm,clone
;              get_screen_size - returns pixels for xterm or framebuffer
;              win_size - returns xterm pixels or zero if not xterm
;              win_txt_size - returns text size for xterm or zero if other term
;<
;  * ---------------------------------------------------
;*******
    
; NAME
;>1 terminal
;   read_term_info__x - save terminal structure "termios"
; INPUTS
;    ebx = fd (file descriptor) of terminal
;    edx = ptr to winsize struc, size = 44 bytes
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
;   structure at edx filled in
; NOTES
;    source file: read_term_info.asm
;
;    see also: crt_type - returns $TERM usually as "linux" or "xterm"
;              terminal_type - returns code for console,xterm,clone
;              read_winsize_x - returns winsize struc
;              read_term_info_x - returns termios and winsize struc
;              read_window_size - returns text size for console,xterm,clone
;              get_screen_size - returns pixels for xterm or framebuffer
;              win_size - returns xterm pixels or zero if not xterm
;              win_txt_size - returns text size for xterm or zero if other term
;<
;  * ---------------------------------------------------
;*******

  global read_term_info_0
  global read_term_info_x
read_term_info_0:
  xor	ebx,ebx			;get fd for stdin
read_term_info_x:
  call	read_winsize_x
  add	edx,wnsize_struc_size
  call	read_termios_x
  ret

