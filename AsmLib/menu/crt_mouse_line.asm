
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

  extern lib_buf
  extern move_cursor
  extern mov_color
  extern crt_str
  extern left_column,crt_columns

;****f* menu/crt_mouse_line *
; NAME
;>1 menu
;  crt_mouse_line - display line in mouse_decode format
; INPUTS
;    esi = menu line to display (see notes)
;    ah = display row 1+
;    (menu line always starts at column 1)
;    ecx = color for spaces between buttons
;    edx = color for buttons
;     
;    hex color def: aaxxffbb  aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brown 34-blue 35-purple 36-cyan 37-grey
;    attributes 30-normal 31-bold 34-underscore 37-inverse
; OUTPUT
;    menu line displayed
; NOTES
;   file:  crt_mouse_line.asm  (see also mouse_line_decode.asm)
;   The menu line has buttons separated by a number from 0-8.
;   the number represents a count of spaces between buttons.
;    example:
;    line:  db "button1",2,"button2",3,"button3",0
;    (zero  indicates end of line, 2=2 spaces)
;   Colors are in standard format (see crt_color.asm)
;<
; * ----------------------------------------------
;*******
  global crt_mouse_line
crt_mouse_line:
  push	esi
  mov	[space_color],ecx
  mov	[button_color],edx
  mov	al,1
  call	move_cursor		;position cursor
  pop	esi
  call	build_line
  mov	ecx,lib_buf
  call	crt_str
  ret

;------------------------------------------
; build one display line using table
;  input: esi = table ptr
;
build_line:
  mov	edi,lib_buf
  mov	ecx,[left_column]
  xor	edx,edx
  mov	dl,[crt_columns]
  sub	edx,byte 1
;
bl_10:
  lodsb
  cmp	al,8
  jbe	bl_20    		;jmp if spacer between buttons
  call	stuf_char		;store button text
  jns	short bl_10		;loop till end of screen
  jmp	bl_80			;jmp if end of screen
;
; we have encountered a spacer or end of table
;
bl_20:
  push	eax
  mov	eax,[space_color]	;get color to use for spacer
  call	mov_color
  pop	eax
;
  cmp	al,0			;end of table
  je	bl_40			;jmp if end of table
;
; spacer char.
;
bl_22:
  push	eax
  mov	al,' '
  call	stuf_char
  pop	eax
  js	bl_80			;jmp if end of screen
  dec	al
  jnz	bl_22

  mov	eax,[button_color]
  call	mov_color
  jmp	bl_10			;go up and move next button text
;
; we have reached the end of table, fill rest of line with blanks
;
bl_40:
  mov	al,' '
  call	stuf_char
  jns	bl_40
;
; end of screen reached, terminate line
;
bl_80:
  mov	al,0
  stosb				;put zero at end of display
  ret  


;---------------------------
; input: [edi] = stuff point
;          al  = character
;         ecx = scroll left count
;          dl = screen size
; output: if (zero flag) end of line reached
;         if (non zero flag) 
;             either character stored
;                 or ecx decremented if not at zero
;
stuf_char:
  jecxz	sc_active	;jmp if file data scrolled ok
  dec	ecx
  or	edi,edi		;clear zero flag
  ret
sc_active:
  stosb			;move char to lib_buf
  dec	edx
  ret

  [section .data]
space_color	dd	0	;space color
button_color	dd	0	;button color
  [section .text]
