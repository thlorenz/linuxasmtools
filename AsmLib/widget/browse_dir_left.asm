
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


;*********************************************************************

;-----------------------------------------------------------------
  [section .text]
;
; NAME
;>1 widget
;  browse_dir_left - browse directories in left half of display
;
;  The functions calls browse_dir and assumes defaults for most
;  parameters.
;
; INPUTS
;    esi = pointer to end of .bss section which will be used
;          to allocate memory for buffers.
;
;     the following keys are recognized:
;      right arrow - move into directory
;      left arrow  - go back one directory
;      up arrow    - move file select bar up
;      down arrow  - move file select bar down
;      pgup/pgdn   - move page up or down
;      ESC         - exit without selecting
;      enter       - exit and select file
;
;    mouse clicks also select files
;
; OUTPUT
;    eax = negative if error.  -1=escape typed.
;          zero indicates success.
;    ebx = ptr to full path if eax=0
;
; NOTES
;   source file: browse_dir_left.asm
;
;<

;------------
; colors = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse

  extern browse_dir
  extern read_window_size
  extern crt_rows,crt_columns
  extern env_home2

;----------------------------------------------------------------
;----------------------------------------------------------------
  global browse_dir_left
browse_dir_left:
  mov	[wrk_buf_ptr],esi
  mov	esi,wrk_buf_ptr	;get ptr to structure
  cmp	byte [crt_rows],0
  jne	dbl_20			;jmp if row data available
  call	read_window_size
dbl_20:
  mov	al,[crt_columns]
  shr	al,1
  mov	[win_clumns],al

  xor	eax,eax
  mov	al,[crt_rows]
  mov	[win_rws],al

  mov	ebx,pathx
  mov	ecx,129			;size of pathx
  mov	eax,183			;get cwd
  int	80h

;  mov	edi,pathx
;  call	env_home2

  mov	esi,wrk_buf_ptr		;get struc ptr
  call	browse_dir
  ret

  [section .data]
;
; input data block from caller
;
wrk_buf_ptr:        dd 0	;pointer to work area size=64,000 > 120,000 bytes
;                               buffer size depends upon size of directories read.
dirclr             dd 31003334h	;color of directories in list
linkclr            dd 30003334h       ;color of symlinks in list
selectclr          dd 30003436h       ;color of select bar
fileclr            dd 30003734h	;normal window color, and list color
win_loc_row     db 1       ;top row number for window
win_loc_column  db 1	;top left column number
win_rws:            db 0	;number of rows in our window
win_clumns:         db 0	;number of columns
box_flg	     db 1	;0=no box 1=box
start_path_ptr    dd pathx	;path to start browsing

pathx times 130 db 0
;


