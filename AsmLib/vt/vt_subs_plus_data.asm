  [section .text align=1]
;-------------------------------------------------

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
;   along with this program.  If not, see <http://www.gnu.org/licenses/.

%include "../include/dcache_colors.inc"

  [section .text align=1]

;-------------------------------------
; input: al=value
;        edi=stuff end point
  global quick_ascii
quick_ascii:
  push	byte 10
  pop	ecx
  and	eax,0ffh		;isolate al
to_entry:
  xor	edx,edx
  div	ecx
  or	dl,30h
  mov	byte [edi],dl
  dec	edi  
  or	eax,eax
  jnz	to_entry
  ret
;---------------------------------------------
  [section .data]
vt100_cursor:
  db	1bh,'['
vt_row:
  db	'000'		;row
  db	';'
vt_column:
  db	'000'		;column
  db	'H'
vt100_end:
  
 [section .text]
;---------------------------------------------------
;#1 vt
; vt_str - send string to display
; INPUT
;   ecx=string ptr
; OUTPUT
;   none
; NOTE
;#
;----------------------------------------------------
  extern sys_write
  global vt_str
vt_str:
  xor edx, edx
.count_again:	
  cmp [ecx + edx], byte 0x0
  je .done_count
  inc edx
  jmp .count_again
.done_count:	
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx,[vt_fd]		; file desc.
  int 0x80
  ret

;---------------------------------------------------
;color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
;-----------------------------------------------------
  [section .data]
  global vt_rows,vt_columns

;--- input block starts here -----
vt_rows: dd 0
vt_columns: dd 0

;vt_image buffer ends with "0"
;format (word) bit 15 = color/text changed flag
;                  14-8 = color code
;                  7-0 = char
  global vt_image
vt_image:  dd 0 ;ptr to image table
  global vt_fd
vt_fd:	dd 0
;window position
  global vt_top_row,vt_top_left_col
vt_top_row: dd 0	;window starting row 0+
vt_top_left_col: dd 0	;window starting column 0+
  global default_color
default_color	    db grey_char + black_back
;--- input block ends here ----

  global vt_display_size
vt_display_size:    dd 0	;size in characters
  global vt_image_write_color
vt_image_write_color: db 0
  global vt_image_end
vt_image_end:	dd 0	;ptr beyond last char

  [section .text]

