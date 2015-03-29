
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
  extern read_term_info_x
  extern dword_to_hexascii
  extern byte_to_hexascii
  extern lib_buf

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
    
;****f* err/log_terminal_0 *
; NAME
;>1 log-error
;   log_terminal_0 - log termios and win size for stdin
; INPUTS
;   none
; OUTPUT
;   none
; NOTES
;   source file log_terminal.asm
;<
;  * ---------------------------------------------------
;*******
;--------------------------------
    
;****f* err/log_terminal_x *
; NAME
;>1 log-error
;   log_terminal_x - log termios and win size for stdin
; INPUTS
;    ebx = fd (file descriptor)
; OUTPUT
;   none
; NOTES
;    source file log_terminal.asm
;<
;  * ---------------------------------------------------
;*******
;--------------------------------
; eax = ascii identifier
;
  extern log_eol
  extern log_str
  extern log_hex
  extern log_num

  global log_terminal_0
  global log_terminal_x
log_terminal_0:
  xor	ebx,ebx
log_terminal_x:
  pusha
  call	log_eol
  mov	esi,fd_msg
  call	log_str
  mov	eax,ebx
  call	log_hex

  mov	esi,winsize_msg
  call	log_str
  mov	edx,our_buf
  call	read_term_info_x
  mov	eax,[ws_row_]
  call	log_hex

  call	log_eol			;end of line

  mov	esi,termios_msg
  call	log_str
  mov	edi,lib_buf		;storage point
  mov	esi,termios_buf		;input ptr
  mov	ebp,4			;loop counter

lt_loop1:
  lodsd
  mov	ecx,eax
  call	dword_to_hexascii
  mov	al,' '
  stosb
  dec	ebp
  jnz	lt_loop1

  mov	ebp,12			;loop counter
lt_loop2:
  lodsb
  call	byte_to_hexascii
  stosw
  mov	al,' '
  stosb
  dec	ebp
  jnz	lt_loop2

  mov	byte [edi],0
  mov	esi,lib_buf
  call	log_str

  popa
  ret

  [section .data]
winsize_msg: db	' WinSize=',0
termios_msg: db 'Termios=',0
fd_msg:	     db 'fd=',0

our_buf:
ws_row_:	dw	0
ws_col_:	dw	0
ws_xpixel_:	dw	0
ws_ypixel_:	dw	0
termios_buf:
c_iflag_:	dd	0
c_oflag_:	dd	0
c_cflag_:	dd	0
c_lflag_:	dd	0
c_line_:	db	0
c_cc_: times 19	db 0

  [section .text]

