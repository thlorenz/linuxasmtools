
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
;---------- x_change_gc_font ------------------

%ifndef DEBUG
  extern x_send_request
%endif

;000:<:000f: 28: Request(56): ChangeGC gc=0x02e00002  values={background=0x0000ffff
;  line-width=2 join-style=Bevel(0x02) font=0x02e00003}

;---------------------
;>1 win_text
;  x_change_gc_font - change active font
;    (next window write will use this font)
; INPUTS
;    eax = window id
;    ebx = font id
; OUTPUT:
;    none
;              
; NOTES
;   source file: x_change_gc_font.asm
;<
; * ----------------------------------------------

  global x_change_gc_font
x_change_gc_font:
  mov	[cgf_id],eax
  mov	[cgf_fid],ebx	;font id
%ifdef DEBUG
  mov	ecx,cgf_msg
  call	crt_str
%endif
  mov	ecx,change_gc_font_request
  mov	edx,change_gc_font_request_len
  call	x_send_request
  ret

  [section .data]
change_gc_font_request:
 db 56	;opcode
 db 0	;unused
 dw change_gc_font_request_len / 4
cgf_id:
 dd 0	;GCONTEXT gc (window id)
 dd  10h | 80h | 4000h	;background,width,join,font 	;mask
;                               10h = line-width
;                               80h = join-style
;                             4000h = font
 dd 2		;line width
 dd 2		;join-style=bevel
cgf_fid:
 dd 0		;font id
change_gc_font_request_len equ $ - change_gc_font_request

%ifdef DEBUG
cgf_msg: db 0ah,'change_gc_font (56)',0ah,0
%endif

  [section .text]

