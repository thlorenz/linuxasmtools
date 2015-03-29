
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

struc	menu_struc
.menu_line	resb	1	;menu display line number
.menu_space_color resb	1	;color number for spaces
.menu_color_table resd	1	;ptr to color table
.menu_text	resd	1	;ptr to menu text line
.menu_process	resd	1	;ptr to process for each button
.menu_colors	resd	1	;ptr to color numbers for each button
.menu_keys	resd	1	;ptr to menu keys for each button
endstruc

;>1 menu
;  menu_display - display menu specified by structure
; INPUTS
;    esi = ptr to menu structure (see below)
; OUTPUT
;    none
; OPERATION
;    The normal sequence of events is:
;
;      mov	esi,menu_line_ptrs
;      call	menu_display		;display menu
;      call	read_stdin		;wait for event, ->kbuf
;      mov	esi,menu_line_ptrs
;      call	menu_decode		;menu button pressed?
;      call	eax
;
;    The menu_line_ptrs point to a data structure which
;    describes the menu display, all mouse areas, and key
;    board actions.  An example follows:
;
; menu defiition - define a 2 line button menu
;
; -----
;    menu_line_ptrs:
;      dd	menu_line1_ptrs	;pointer to menu line 1 definition
;      dd	menu_line2_ptrs ;pointer to menu line 2 definition
;      dd	0		;end of pointers
;-------
;    menu_line1_ptrs:
;      db	1		;display at line number
;      db	1		;color number for space between buttons
;      dd	color_table	;color definitions
;      dd	menu1_text	;menu text line
;      dd	menu1_process	;process's to call for each button
;      dd	menu1_colors	;colors associated with each button
;      dd	menu1_keys	;keys associated with each button
;
;    menu_line2_ptrs:
;      db	2		;line number
;      db	1		;space color number
;      dd	color_table
;      dd	menu2_text
;      dd	menu2_process
;      dd	menu2_colors
;      dd	menu2_keys
;------
;      hex color def: aaxxffbb  aa-attr ff-foreground  bb-background
;      30-blk 31-red 32-grn 33-brown 34-blue 35-purple 36-cyan 37-grey
;      attributes 30-normal 31-bold 34-underscore 37-inverse
;    color_table:
;    ct1:   	dd	30003730h	;color 1 grey on black - spaces, page color
;    ct2:   	dd	30003037h	;color 2 black on grey - button text color
;    ct3:    dd	30003437h	;color 3 blue on grey - highlight bar color
;------
;     menu text consists of 'space-counts' and text.  space-counts
;     are encoded as numbers from 1-8.  the end of text line has 'zero' char
;     The following  lines describe two button sets.  Each button set uses
;     two display lines.
;    menu1_text:
;     db 1,'raw(r)',1,'src(s)',1,'code(t)',1,'data(i)',,0
;    menu2_text:                                                                       
;     db 1,' mode ',1,' mode ',1,' area  ',1,' area  ',',0
;
;    menu1_process:
;    menu2_process:
;     dd set_raw, set_src, set_code, set_data
;-------
;    colors for each button on line.  See color table above
;    menu1_colors:  ;first color is for space infront of button
;    menu2_colors:  ;button1 color is at menu1_colors+1
;     db 2,2,2,2,2
;-------
;    menu1_keys:
;    menu2_keys:
;     db	'r',0	;raw mode key
;     db	's',0	;src mode key
;     db	't',0	;code section
;     db	'i',0	;data section
;     db	0 ;end of keys
; ---
;
; NOTES
;    source file: menu_decode.asm
;                     
;<
;  * ----------------------------------------------
  extern move_cursor
  extern crt_str
  extern mov_color
  extern crt_columns
  extern lib_buf

  global menu_display 
menu_display:
md_loop:
  push	esi
  mov	esi,[esi]	;get next ptr
  or	esi,esi
  jz	md_done		;exit if end of lines
  call	display_menu_line
  pop	esi
  add	esi,4
  jmp	short md_loop
md_done:
  pop	esi
  ret

;----------------------------------------------------------
; input:  esi = ptr to menu line table entry as follows:
;               db x   ;display line# 1+
;               db x   ;color number for spaces
;               dd x   ;color table ptr
;               dd x   ;menu text
;               dd x   ;process
;               dd x   ;color numbers ptr
;               dd x   ;menu key definitions
display_menu_line:
  mov	ah,[esi+menu_struc.menu_line]
  mov	al,1
  call	move_cursor		;position cursor
  mov	ecx,[esi+menu_struc.menu_color_table]

  xor	eax,eax
  mov	al,[esi+menu_struc.menu_space_color]
  dec	al
  shl	eax,2
  add	eax,ecx
  mov	eax,[eax]			;get color
  mov	[space_color],eax

  mov	ebp,[esi+menu_struc.menu_colors] ;get table of color numbers
  mov	esi,[esi+menu_struc.menu_text]
  call	build_menu_line
  mov	ecx,lib_buf
  call	crt_str
  ret

;----------------------------------------------------------
; build menu line in lib_buf
;  inputs: esi = input table with text and space counts
;                example:  "text",1,"text",3,"text"
;                produces: "text text   text"
;          ebp = ptr to button color numbers
;          ecx = color table 
;          [space_color] - set by caller
;          
build_menu_line:
  mov	[color_table_ptr],ecx
  mov	edi,lib_buf
  mov	dl,[crt_columns]
  dec	dl
bl_10:
  lodsb
  cmp	al,8
  jbe	bl_20    		;jmp if spacer between buttons
  stosb
  dec	dl
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
  inc	ebp			;move to next button color
  cmp	al,0			;end of table
  je	bl_40			;jmp if end of table
;
; spacer char.
;
bl_22:
  push	eax
  mov	al,' '
  stosb
  dec	dl
  pop	eax
  js	bl_80			;jmp if end of screen
  dec	al
  jnz	bl_22

  xor	eax,eax
  mov	al,[ebp]		;get button color number
  dec	al
  shl	eax,2			;make dword ptr
  add	eax,[color_table_ptr]	;lookup color
  mov	eax,[eax]		;get color
  call	mov_color
  jmp	bl_10			;go up and move next button text
;
; we have reached the end of table, fill rest of line with blanks
;
bl_40:
  mov	al,' '
  stosb
  dec	dl
  jns	bl_40
;
; end of screen reached, terminate line
;
bl_80:
  mov	al,0
  stosb				;put zero at end of display
  ret  

;---------------
  [section .data]
space_color	dd	0	;space color
color_table_ptr	dd	0
  [section .text]

