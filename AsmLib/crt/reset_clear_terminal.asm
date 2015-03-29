
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
;   reset_clear_terminal - terminal soft reset plus clear
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

  global reset_clear_terminal
reset_clear_terminal:
  mov	ecx,strings
  call	crt_str
  ret

  [section .data]
strings:
 db 1bh,'[?1l'	;app cursor keys
; db 1bh,'[?3l'	;80 col mode
 db 1bh,'[?4l'	;replace mode
 db 1bh,'[?5l'	;normal video (not reverse)
 db 1bh,'[?6l'	;normal cursor mode
 db 1bh,'[?7l'	;no wrap
 db 1bh,'[?8h'	;auto repeat keys
; db 1bh,'[?40h'	;allow 80-132 col mode
 db 1bh,'[0m'	;default color
 db 1bh,'>'	;nornal key pad
; db 1bh,'[999;999H'	;move cursor
; db 1bh,'[99B'	;cursor down 99 times
 db 1bh,'[H'	;move cursor to 1;1
 db 1bh,'[2J'	;clear screen
 db 1bh,'[r'	;default scroll region
 db 0		;end of setup

