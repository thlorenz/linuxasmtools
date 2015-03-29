
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
  extern cursor_hide
  extern cursor_unhide
;--------------------------------------------------------
;****f* widget/message_box *
; NAME
;>1 widget
;   message_box - display message and wait for key press
; INPUTS
;    esi = pointer to structure below
;      dd window color (see notes)
;      dd data pointer.
;      dd end of data ptr, beyond last display char
;      dd initial scroll left/right position
;      db columns inside box
;      db rows inside box
;      db starting row
;      db starting column
;      dd outline box color (see notes)
;         (set to zero to disable outline)
;    lib_buf is used to build display lines
; OUTPUT
;   eax = return state of lib function key_mouse1
;   [kbuf] contains key press
; NOTES
;    source file message_box.asm
;    The current window width is not checked, message_box
;    will attempth display even if window size too small.
;      
;    color = aaxxffbb aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse
;<
;  * ---------------------------------------------------
;*******
  extern read_stdin
  extern show_box
  global message_box
message_box:
  call	show_box
  call	cursor_hide
  call	read_stdin
  call	cursor_unhide
  ret
