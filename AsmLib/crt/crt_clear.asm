
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

  extern crt_str
  extern crt_set_color
  extern crt_vertical
  extern crt_columns
 
;----------------------------------
;****f* crt/crt_clear *
;
; NAME
;>1 crt
;  crt_clear - clear the screen
; INPUTS
;    eax = screen color
; OUTPUT
;    screen is cleared
; NOTES
;    file crt_vertical.asm
;    see function crt_set_color for color info
;<
;  * ----------------------------------------------
;*******
  global crt_clear
crt_clear:
  call	crt_set_color
  mov	ecx,clear_msg
  call	crt_str
  ret
clear_msg: db 1bh,'[H',1bh,'[2J',0

%ifdef DEBUG
  [section .text]

  global main,_start
main:
_start:
  nop
  mov	ecx,clear
  call	crt_str
  mov	eax,1
  int	byte 80h
;--------
  [section .data]

clear: db 1bh,'[2J',0

  [section .text]
%endif

