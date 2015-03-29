
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
;>1 env
;  lib_data - common data used by crt functions  
; INPUTS
;    see env_stack, crt_open sets crt_rows & crt_columns
; OUTPUT
; NOTES
;    file lib_data.asm
;     
;    crt_rows (byte) set by crt_open
;    crt_columns (byte) set by crt_open
;     
;      scratch variables -------------------
;    crt_left_column - used by many
;    data_end_ptr - used by many
;    win_columns - used by many
;    lib_buf - 600 byte buffer
;     
;      default color definitions -----------
;      norm_text_color dd 30003734h ;used for inactive window
;      grey-foreground=7 blue-backgound=4 0=norm attr
;     
;      bold_edit_color dd 31003734h ; active window in edit mode
;      grey-foreground=7 blue-backgound=4 0=bold attr
;     
;      bold_cmd_color dd 31003334h ; active window in command mode
;      grey-foreground=7 blue-backgound=4 0=bold attr
;     
;      high_text_color dd 31003634h ;used for highlighting block
;      grey-foreground=7 blue-backgound=4 0=inver attr
;     
;      asm_text_color dd 31003234h ;used to highlight comments ";"
;      cyan-foreground=6 blue-backgound=4 0=norm attr
;     
;      status_color dd 30003036h ;used for status line
;      status_color1 dd 31003336h ; special data on status line
;      status_color2 dd 31003331h ; error messags or macro record
;      exit_screen_color dd 31003334h ; error messags on status line
;<
;  * ----------------------------------------------
;*******

  [section .text]

   nop

  [section .data]
  global left_column
;  global crt_rows,crt_columns,terminal
;terminal	 db 0	;0=unknown 1=console 2=xterm-clone 3=xterm
;crt_rows 	 db 0	;lines of text
;crt_columns	 db 0	;characters on line

left_column	dd	0

 global crt_left_column
 global win_columns
 global lib_buf
 global data_end_ptr
 global enviro_ptrs,stack_env_ptr

stack_env_ptr:
enviro_ptrs	dd	0		;from entry stack
crt_left_column dd	0
data_end_ptr	dd	0
win_columns	db	0
lib_buf	times 700 db 0
  global norm_text_color,bold_edit_color
  global high_text_color,asm_text_color
  global status_color,status_color1,status_color2
  global exit_screen_color

;------------------------------------------------------------------------
; colors = aaxxffbb  (aa-attribute ff-foreground  bb-background)
;   30-black 31-red 32-green 33-brown 34-blue 35-purple 36-cyan 37-grey
;   attributes 30-normal 31-bold 34-underscore 37-inverse
norm_text_color	dd 30003734h ;used for inactive window
;			     ;grey-foreground=7 blue-backgound=4 0=norm attr
bold_edit_color	dd 31003734h ;used for active window in edit mode
;			     ;grey-foreground=7 blue-backgound=4 0=bold attr
bold_cmd_color	dd 31003334h ;used for active window in command mode
;			     ;grey-foreground=7 blue-backgound=4 0=bold attr
high_text_color	dd 31003634h ;used for highlighting block
;			     ;grey-foreground=7 blue-backgound=4 0=inver attr
asm_text_color	dd 31003234h ;used to highlight comments ";"
;			     ;cyan-foreground=6 blue-backgound=4 0=norm attr
status_color	dd 30003036h ;used for status line
status_color1	dd 31003336h ;used for special data on status line
status_color2	dd 31003331h ;used for error messags or macro record
exit_screen_color dd 31003334h ;used for error messags on status line


  global kbuf
  global kbuf_end
kbuf  times 37 db 0
kbuf_end equ $
	db	0	;end of kbuf stuff for extra zero

  [section .text]

