
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
;-------------------------------------------------
;>1 xterm
;  win_deiconify - return window to prevous size
;    warning: this may only work on xterm, not other terminals
; INPUTS
;    none
; OUTPUT:
;    none
;    
; NOTES
;   source file: win_deiconify.asm
;<
; * ----------------------------------------------
  extern crt_str

  global win_deiconify
win_deiconify:
  mov	ecx,request
  call	crt_str
  ret

;-------------
  [section .data]
request: db 1bh,"[1t",0
  [section .text]



%ifdef DEBUG
  global main,_start
main:
_start:
  nop
  call	win_deiconify	;eax=h  ebx=witth

  mov	eax,1
  int	byte 80h
;--------

%endif