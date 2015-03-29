
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
;   output_winsize_0 - output stdin window size
; INPUTS
;    edx = ptr to winsize struc, size = 8 bytes
;   
;    struc wnsize_struc
;    .ws_row:resw 1
;    .ws_col:resw 1
;    .ws_xpixel:resw 1
;    .ws_ypixel:resw 1
;    endstruc
;    wnsize_struc_size
; OUTPUT
;    none
; NOTES
;    source file terminal.asm
;<
;  * ---------------------------------------------------
;*******
    
; NAME
;>1 terminal
;   output_winsize_x - output terminal structure "termios"
; INPUTS
;    ebx = fd (file descriptor) of terminal
;    edx = ptr to winsize struc, size = 8 bytes
;   
;    struc wnsize_struc
;    .ws_row:resw 1
;    .ws_col:resw 1
;    .ws_xpixel:resw 1
;    .ws_ypixel:resw 1
;    endstruc
;    wnsize_struc_size
; OUTPUT
;   none
; NOTES
;    source file terminal.asm
;<
;  * ---------------------------------------------------
;*******

  global output_winsize_x
  global output_winsize_0
output_winsize_0:
  xor	ebx,ebx		;get code for stdin
output_winsize_x:
  mov	ecx,5414h
; mov edx,winsize
  mov	eax,54
  int	80h
  ret
