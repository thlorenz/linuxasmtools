
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
  extern str_move
  extern move_cursor
  extern crt_str
  extern crt_rows,crt_columns

;****f* crt/mov_color *
; NAME
;>1 crt
;  mov_color - copy vt100 string to buffer
; INPUTS
;    eax = color code
;    eax = aaxxffbb aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse
;    edi = location to copy color string
; OUTPUT
;    string is copied, edi points to zero at end of string
;    register esi is preserved
; NOTES
;    file crt_color.asm
;    This function copies and asciiz string (including the zero)
;<
;  * ----------------------------------------------
;*******
 global mov_color
mov_color:
  push	esi
  call	insert_colors
  mov	esi,vt100_color_str
  call	str_move
  pop	esi
  ret

;****f* crt/crt_color_at *
; NAME
;>1 crt
;   crt_color_at - move cursor and display colored line
; INPUTS
;    eax = color (aa??ffbb) attribute,foreground,background
;    bl = column
;    bh = row
;    ecx = message ptr (asciiz)
; OUTPUT
;    colored message string displayed
; NOTES
;    file crt_color.asm
;<
;  * ---------------------------------------------------
;*******
  extern read_window_size

  global crt_color_at
crt_color_at:
  mov	[current_row],bh	;save row
  mov	[current_column],bl	;save column
  mov	[msg_ptr],ecx		;save msg ptr
  call	crt_set_color
  cmp	byte [crt_rows],0	;is the screen size avail.
  jne	cca_10			;jmp if size available
  call	read_window_size	;get screen size
cca_10:
;
; compute message size
;
  mov	esi,[msg_ptr]		;get message ptr
  xor	edx,edx			;size counter
  dec	edx
cca_lp1:
  inc	edx
  lodsb
  or	al,al
  jnz	cca_lp1
  mov	[msg_size],edx		;save size
;
; check if this line is on screen
;
  mov	ah,[current_row]
  cmp	ah,[crt_rows]		;check if row in window
  ja	cca_exit		;exit if beyond window
  mov	al,[current_column]
  cmp	al,[crt_columns]	;check if column on screen
  ja	cca_exit		;exit if beyond window
  call	move_cursor
;
; check if message will overflow
;
  xor	eax,eax
  mov	al,[current_column]
  add	eax,[msg_size]		;compute current_column + message size
  cmp	ax,[crt_columns]
  jbe	cca_30			;jmp if message ok
;
; compute max message size
; it is possible messag will have 0ah embedded inside. we
; will only accept a line at a time to avoid this problem.
;
  xor	edx,edx
  mov	dl,[crt_columns]
  sub	dl,[current_column]
  inc	edx
  jmp	short cca_40  
cca_30:
  mov	edx,[msg_size]
cca_40:
  mov	ecx,[msg_ptr]
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx,1			; stdout
  int 0x80
  
cca_exit:
  ret

;------------------
  [section .data]
current_row	db	0
current_column	db	0
msg_ptr		dd	0
msg_size	dd	0
  [section .text]
;----------------------------------

; input: eax = color data (see below)
; output: vt100 color string built and
insert_colors:
  mov	byte [vcs1],al
  mov	byte [vcs2],ah
  rol	eax,8
  mov	byte [vcs_atr],al
  ret

;****f* crt/crt_set_color *
; NAME
;>1 crt
;  crt_set_color - set color mode for display
; INPUTS
;    eax = color code
;    eax = aaxxffbb  aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brwn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse
; OUTPUT
;    vt100 color string sent to display
; NOTES
;    source file crt_color.asm
;    This function sends vt100 color command to crt
;<
;  * ----------------------------------------------
;*******
  global crt_set_color
crt_set_color:
  call	insert_colors
  mov	ecx,vt100_color_str
  call	crt_str
  ret  

;------------------------------------------------
  [section .data]

 global vt100_color_str
vt100_color_str:
  db	1bh,'['
vcs_atr:
  db	0,'m'
  db	1bh,'[4'
vcs1:
  db	0
  db	'm'
  db	1bh,'[3'
vcs2:
  db	0
  db	'm'
  db	0
  
 [section .text]

