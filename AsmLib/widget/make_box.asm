
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

;------------------------------
;****f* widget/make_box *
; NAME
;>1 widget
;   make_box - display box outline
; INPUTS
;    esi = pointer to structure below
;      db columns inside box
;      db rows inside box
;      db starting row
;      db starting column
;      dd box color (see notes)
;    lib_buf is used to build display lines
; OUTPUT
;   eax = negative system error# or positive if success
; NOTES
;    source file make_box.asm
;    The current window width is not checked, make_box
;    will attempth display even if window size too small.
;      
;    color = aaxxffbb aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse
;<
;  * ---------------------------------------------------
;*******
  extern move_cursor
  extern crt_vertical
  extern crt_horizontal

  global make_box
make_box:
;move cursor to top line start
  mov	al,[esi + 3]	;starting column
  dec	al
  mov	ah,[esi + 2]	;starting row
  dec	ah
  call	move_cursor
;draw top line
  mov	bl,' '		;get box char
  mov	eax,[esi +4]	;get color
  xor	ecx,ecx
  mov	cl,[esi]	;get columns inside box
  add	cl,2
  call	crt_horizontal

;move cursor to botton line start
  mov	al,[esi + 3]	;starting column
  dec	al		;move beyond window
  mov	ah,[esi + 2]	;starting row
  add	ah,[esi + 1]	;compute end of row
  call	move_cursor
;draw bottom line
  mov	bl,' '		;get box char
  mov	eax,[esi +4]	;get color
  xor	ecx,ecx
  mov	cl,[esi]	;get columns inside box
  add	cl,2
  call	crt_horizontal

;draw left box outline
  mov	al,[esi + 3]	;starting column
  dec	al
  mov	ah,[esi + 2]	;starting row
  mov	bl,' '		;box char
  mov	bh,[esi + 1]	;get rows inside box
  call	crt_vertical

;draw right box outline
  mov	al,[esi+3]	;get starting column
  add	al,[esi]	;compute left
  mov	ah,[esi +2]	;get starting row
  mov	bl,' '		;box char
  mov	bh,[esi + 1]	;get row  
  call	crt_vertical
  ret  
