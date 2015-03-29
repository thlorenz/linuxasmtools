
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
;---------- x_change_gc_colors ------------------

%ifndef DEBUG
  extern x_send_request
%endif


;---------------------
;>1 win_color
;  x_change_gc_colors - set active colors for window
;    (next window write will use these colors)
; INPUTS
;    eax = window id
;    ebx = foreground color
;    ecx = background color
; OUTPUT:
;    none
;              
; NOTES
;   source file: x_change_gc_colors.asm
;<
; * ----------------------------------------------

  global x_change_gc_colors
x_change_gc_colors:
  mov	[cgc_id],eax
  mov	[foreground_color],ebx	;colors id
  mov	[background_color],ecx
%ifdef DEBUG
  mov	ecx,cgc_msg
  call	crt_str
%endif
  mov	ecx,change_gc_colors_request
  mov	edx,change_gc_colors_request_len
  call	x_send_request
  ret

  global cgcr_pkt
  [section .data]
cgcr_pkt:
change_gc_colors_request:
 db 56	;opcode
 db 0	;unused
 dw change_gc_colors_request_len / 4
cgc_id:
 dd 0	;GCONTEXT gc (window id)
 dd 4 | 8 	;4=foreground , 8=background 	;mask
foreground_color:
 dd 0000ffffh	;background
background_color:
 dd 0
change_gc_colors_request_len equ $ - change_gc_colors_request

%ifdef DEBUG
cgc_msg: db 0ah,'change_gc_colors (56)',0ah,0
%endif

  [section .text]

