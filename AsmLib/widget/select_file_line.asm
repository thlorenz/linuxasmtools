
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
  extern crt_rows,crt_columns
  extern read_window_size
  extern block_read_all
  extern select_buffer_line
;----------------------
;>1 widget
;   select_file_line - view a buffer and select line
; INPUTS
;    esi = buffer pointer for file data
;    ebx = filename ptr
;    edx = buffer length
;    ecx = ignore (scroll left) for file data
; OUTPUT
;    eax = zero if no selection was made or error
;        = ptr to start of selected row
; OPERATION
;    The screen size is optained from kernel and used
;    to display page of file data.  Keys and mouse data
;    is used to scroll up/down the data and make a
;    selection.
; NOTES
;    file select_file_line.asm
;<
;  * ---------------------------------------------------
;*******
  global select_file_line
select_file_line:
  mov	[_buffer],esi
  mov	[_sel_ptr],esi
  add	esi,edx
  dec	esi		;move back to 0ah
  mov	[_buf_end_ptr],esi
  mov	[_scroll],ecx
;open file
  mov	ecx,[_buffer]	;get buffer ptr
  call	block_read_all
  or	eax,eax
  js	sfl_exit1	;exit if read error
;get screen size
  mov	al,[crt_rows]
  or	al,al
  jnz	sfl_10		;jmp if size already set
  call	read_window_size
  mov	al,[edx]	;get rows
sfl_10:
  mov	[_win_rows],al
  mov	al,[crt_columns]
  mov	[_win_cols],al
;display and select
  mov	esi,select_block
  call	select_buffer_line
  jmp	short sfl_exit
sfl_exit1:
  xor	eax,eax
sfl_exit:
  ret
;----------------------------------------------
  [section .data]

select_block:				;inputs for crt_window
_color		dd	30003437h
_buffer		dd	0
_buf_end_ptr	dd	0
_scroll		dd	0
_win_cols	db	0	;win columns
_win_rows	db	0	;win rows
_start_row	db	1
_start_col	db	1
_sel_ptr	dd	0	;ptr to select bar line
_select_color   dd	30003634h	;color for select line


;----------------------------------------------
  [section .text]

