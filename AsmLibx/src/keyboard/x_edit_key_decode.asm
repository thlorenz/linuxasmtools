
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
;------------------------------------------------
;>1 keyboard
;  x_edit_key_decode - associate process with key
; INPUTS
;  bl = key code
;  bh = key flag
;  esi = ptr to translation table as follows:
;          table of key codes and processes
;          first table entry is alpha key process
;          middle entries are non alpha keys
;          final process is called if no match
;          A key code consists of flag byte and
;          code byte as returned by x_key_translate.
;    example
;    dd	gs_normal_char ;alpha key process (printable char)
;    dw 00xxh          ; flag,code
;    dd gs_home        ; home process 
;    ds 00xxh          ; flag (00) code (xx)
;    dd gs_left        ; left arrow process
;        .
;    dw 0              ;end of table
;    dd no_match       ;no-match process
;
;           
; OUTPUT
;    eax=pointer to process
;
; NOTES
;   source file: x_key_decode.asm
;<
;------------------------------------
  global x_edit_key_decode
x_edit_key_decode:
  lodsd			;get ascii process
  test	bh,80h
  jz	kd_loop
  jmp	short kd_exit
kd_loop:
  cmp	bx,[esi]
  je	kd_match
  add	esi,6
  cmp	word [esi],0	;end of table
  jne	kd_loop
;no match
kd_match:
  mov	eax,[esi+2]	;get process
kd_exit:
  ret

