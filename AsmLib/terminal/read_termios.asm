
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
    
;>1 terminal
;   read_termios_0 - save stdin terminal structure "termios"
; INPUTS
;    edx = ptr to termios save buffer, size = 36 bytes
;    struc termio_struc
;    .c_iflag: resd 1
;    .c_oflag: resd 1
;    .c_cflag: resd 1
;    .c_lflag: resd 1
;    .c_line: resb 1
;    .c_cc: resb 19
;    endstruc
; OUTPUT
;   structure at edx filled in
; NOTES
;    source file: read_termios.asm
;<
;  * ---------------------------------------------------
;*******
    
;****f* crt/read_termios_x *
; NAME
;>1 terminal
;   read_termios_x - save terminal structure "termios"
; INPUTS
;    ebx = fd (file descriptor) of terminal
;    edx = ptr to termios save buffer, size = 36 bytes
;    struc termio_struc
;    .c_iflag: resd 1
;    .c_oflag: resd 1
;    .c_cflag: resd 1
;    .c_lflag: resd 1
;    .c_line: resb 1
;    .c_cc: resb 19
;    endstruc
; OUTPUT
;   structure at edx filled int
; NOTES
;    source file read_termios.asm
;<
;  * ---------------------------------------------------
;*******

   global read_termios_0
   global read_termios_x
read_termios_0:
  xor	ebx,ebx		;get code for stdin
read_termios_x:		;entry to save fd other than stdin
  mov	ecx,5401h
;  mov	edx,termios_orig
  mov eax,54
  int	80h
  ret
