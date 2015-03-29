
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
  extern draw_table
;-----------------------------------------------------
;>1 draw
; draw_box - use line drawing characters to draw a box
; inputs:
;    esi = ptr to block of data as follows:
;          dd <color>
;          db row
;          db column
;          db vertical size
;          db horizontal size
; outputs:
;    none
; notes:
;   source file  draw_box.asm
;
;<
;-----------------------------------------------------------
  global draw_box
draw_box:
  lodsd			;get color
  mov	[color],eax
  lodsb			;get row
  mov	bl,al		;save row
  mov	[ul_row],al	;top left corner
  mov	[ur_row],al	;top right corner
  mov	[rh_rowt],al	;top line
  inc	al
  mov	[rv_rowl],al	;left bar, repeat down
  mov	[rv_rowr],al	;right bar, repeat down

  lodsb			;get upper left column
  mov	bh,al		;save column
  mov	[ul_col],al	;set upper left column
  mov	[rv_coll],al	;set repeat down, left edge column
  mov	[ll_col],al
  inc	al
  mov	[rh_colt],al	;set upper bar, starting column
  mov	[rh_colb],al	;set lower bar, starting column

  lodsb			;get vertical size
  sub	al,2
  mov	[rv_cntr],al
  mov	[rv_cntl],al
  add	bl,al		;compute botton row
  inc	bl
  mov	[ll_row],bl	;set lower left row for corner
  mov	[rh_rowb],bl	;set lower bar row
  mov	[lr_row],bl	;set lower right row for corner

  lodsb			;get horiontal size
  sub	al,2
  mov	[rh_cntt],al
  mov	[rh_cntb],al
  add	bh,al		;compute right column
  inc	bh
  mov	[ur_col],bh	;upper right corner col
  mov	[lr_col],bh	;lower right corner col
  mov	[rv_colr],bh	;right edge bar column

  mov	esi,control_table
  call	draw_table
  ret

;--------------
  [section .data]
control_table:
	db	5		;draw on

	db	1		;set color
color	dd	0		;color

	db	2		;upper left corner char
ul_row	db	0		;upper left row
ul_col	db	0		;upper left col
	db	'l'		;corner char

	db	2		;upper right corner char
ur_row	db	0		;upper right row
ur_col	db	0		;upper right col
	db	'k'		;corner char

	db	2		;lower left corner char
ll_row	db	0		;lower left row
ll_col	db	0		;lower left col
	db	'm'		;corner char

	db	2		;lower right corner char
lr_row	db	0		;lower right row
lr_col	db	0		;lower right col
	db	'j'		;corner char

	db	3		;repeat horizontal -top line
rh_rowt	db	0		;repeat h row
rh_colt	db	0		;repeat h column
rh_cntt	db	0		;repeat count
	db	'q'		;repeat h char

	db	3		;repeat horizontal -bottom line
rh_rowb	db	0		;repeat h row
rh_colb	db	0		;repeat h column
rh_cntb	db	0		;repeat count
	db	'q'		;repeat h char

	db	4		;repeat vertical (down) - left edge
rv_rowl	db	0		;repeat row
rv_coll	db	0		;repeat col
rv_cntl	db	0		;repeat count
	db	'x'		;repeat char

	db	4		;repeat vertical (down) - right edge
rv_rowr	db	0		;repeat row
rv_colr	db	0		;repeat col
rv_cntr	db	0		;repeat count
	db	'x'		;repeat char

	db	6		;draw off
	db	0		;end of table

  [section .text]