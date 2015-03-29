
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
;---------- window_write_lines ------------------

%ifndef DEBUG
%include "../../include/window.inc"
%endif

  extern window_write_line
  extern x_write_block
;---------------------
;>1 win_text
;  window_write_lines - write lines to area
; INPUTS
;  ebp = window block ptr
;  edx = text block ptr, contains
;        dd number of rows in area
;        dd number of columns in area
;        dd starting row (0=top of window)
;        dd starting column (0=left edge)
;        dd text block ptr, lines end with 0ah,
;           end of text has zero byte
;
; OUTPUT:
;    error = sign flag set for js
;        eax = negative error code
;    success
;        eax = postive value
;              
; NOTES
;   source file: window_write_lines.asm
;<
; * ----------------------------------------------

struc wblk
.rows	resd	1 ;number of rows
.cols	resd	1 ;number of columns
.row_num resd	1 ;starting row
.col_num resd   1 ;starting column
.text_ptr resd	1 ;ptr to text block
endstruc

  global window_write_lines
window_write_lines:
  mov	eax,[edx+wblk.col_num]	;get startng column
  cmp	eax,[ebp+win.s_text_columns]
  ja	wwl_done		;jmp if area off screen
  mov	eax,[edx+wblk.row_num]	;get starting row
  mov	[current_row],eax	;save starting row
  add	eax,[edx+wblk.rows]	;compute final row
  mov	[final_row],eax
  mov	esi,[edx+wblk.text_ptr]
  mov	[block_ptr],edx
wwl_lp1:
  mov	ebx,esi		;save start of line
;scan to end of line
wwl_lp2:
  lodsb
  or	al,al
  jz	wwl_10
  cmp	al,0ah
  jne	wwl_lp2
wwl_10:
  dec	esi		;move back to 0ah or 0
;compute length of line
  mov	edi,esi
  sub	edi,ebx		;compute line length
  cmp	edi,[edx+wblk.cols]
  jbe	wwl_20		;jmp if column ok
  mov	edi,[edx+wblk.cols]
wwl_20:
  mov	ecx,[edx+wblk.col_num]	;get startng column
  mov	edx,[current_row]
  cmp	edx,[ebp+win.s_text_rows]
  ja	wwl_done	;jmp if row off screen
;ecx=col edx=row esi=msg edi=length
  push	esi		;save current pointer
  mov	esi,ebx		;get origional line start
  call	window_write_line
  pop	esi
  mov	edx,[block_ptr]
  cmp	byte [esi],0
  je	wwl_done	;jmp if end of block
  inc	esi		;move past 0ah
  inc	dword [current_row]
  mov	eax,[current_row]
  cmp	eax,[final_row]
  jbe	wwl_lp1
wwl_done:
  ret
;----------
  [section .data]
current_row:	dd 0
final_row:	dd 0
block_ptr:	dd 0
  [section .text]

