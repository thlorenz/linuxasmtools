
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
    
;>1 crt
;   reset_soft - terminal soft reset
; INPUTS
;    none
; OUTPUT
;   none
; NOTES
;    source file reset_soft.asm
;<
;  * ---------------------------------------------------
;*******
  extern crt_str

  global reset_soft
reset_soft:
  mov	ecx,strings
  call	crt_str
  ret

  [section .data]
strings:
 db 1bh,'[!p',1bh,'[?3;4l',1bh,'[4l',1bh,'>',0
  [section .text]

;esc [!p 	soft reset
;esc [?3;4l  	80 column, normal scroll
;esc [4l	replace mode
;esc >		normal keypad
