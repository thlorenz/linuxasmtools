
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
    
;>1 terminal
;   set_screen_size - set scroll limits for terminal
; INPUTS
;    al = ending row (max 255)
;    ah = ending column (max 255)
;    ebx = display  fd (usually 1)
; OUTPUT
;   none
; NOTES
;    source file set_screen_size.asm
;<
;  * ---------------------------------------------------
;*******
  extern crt_str

  global set_screen_size
set_screen_size:
;set screen size
  mov	[ss_row],al		;  screen
  mov	[ss_col],ah

  mov	eax,54
;  mov	ebx,0		;stdio
  mov	ecx,5414h	;ioctl TIOCGWINSZ
  mov	edx,scrn_size
  int	byte 80h	;set screen size
  ret
;--------
  [section .data]
scrn_size:
ss_row: dw 0
ss_col: dw 0
ss_x	dw 0
ss_y	dw 0

  [section .text]

