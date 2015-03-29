
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
 extern crt_str

  [section .text]

;****f* key_mouse/mouse_enable *
; NAME
;>1 terminal
;  mouse_enable - enable mouse on x terminals
; INPUTS
;     none
; OUTPUT
;     none
; NOTES
;   source file: mouse_enable.asm
;   function crt_open also needed to use mouse
;<
; * ----------------------------------------------
;*******
  global mouse_enable
mouse_enable:
  mov	ecx,mouse_escape
  call	crt_str
  ret  

mouse_escape	db   1bh,"[?1000h",0	;enables mouse reporting

