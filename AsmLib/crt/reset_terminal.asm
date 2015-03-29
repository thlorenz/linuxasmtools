
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
    
;****f* crt/reset_terminal *
; NAME
;>1 crt
;   reset_terminal - output vt-100 setup strings
; INPUTS
;    none
; OUTPUT
;   none
; NOTES
;    source file reset_terminal.asm
;<
;  * ---------------------------------------------------
;*******
  extern crt_str

  global reset_terminal
reset_terminal:
  mov	esi,exit_table
  call	send_strings
  ret

send_strings:
is_loop:
  lodsd
  or	eax,eax
  jz	is_done
  push	esi
  mov	ecx,eax
  call	crt_str
  pop	esi
  jmp	is_loop
is_done:
  ret

exit_table:
  dd	e1
  dd	e2
  dd	e3
  dd	e4
  dd	e5
  dd	e6
  dd	e7
  dd	e8
  dd	e9
  dd	e10
  dd	0

e1  db  1bh,'7',0		;save cursor
e2  db	1bh,'[?1l',0
e3  db	1bh,'[?3l',0
e4  db	1bh,'[?5l',0
e5  db	1bh,'[?6l',0
e6  db	1bh,'[?7h',0
e7  db	1bh,'[?8h',0
e8  db  1bh,'[r',1bh,'[0m',0
e9  db  1bh,'8',0
e10 db  1bh,'[?25h',0		;unhide the cursor

