
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
;---------- window_color ------------------

%ifndef DEBUG
%include "../../include/window.inc"
  extern x_change_gc_colors
%endif
  extern color_id_table
;---------------------
;>1 win_color
;  window_color - set color number active
; INPUTS
;  ebp = window block ptr
;  ebx = foreground color number (see below)
;  ecx = backgruond color number (see below)
;       white        ;color #00
;       grey         ;       04
;       skyblue              08
;       blue                 12
;       navy                 16
;       cyan                 20
;       green                24
;       yellow               28
;       gold                 32
;       tan                  36
;       brown                40
;       orange               44
;       red                  48
;       maroon               52
;       pink                 56
;       violet               60
;       purple               64
;       black                68

; OUTPUT:
;    error = sign flag set for js
;    success = sign flag set fo jns
; NOTES
;   source file: window_create.asm
;   Color selection stays active for window writes
;   and clears.  If fonts are changed, the default
;   colors are restored from window create.  
;<
; * ----------------------------------------------
;---------------------
;>1 win_color
;  window_id_color - set color id's active
; INPUTS
;  ebp = window block ptr
;  ebx = foreground color id
;  ecx = backgruond color id
;
; OUTPUT:
;    error = sign flag set for js
;    success = sign flag set fo jns
; NOTES
;   source file: window_create.asm
;   Color selection stays active for window writes
;   and clears.  If fonts are changed, the default
;   colors are restored from window create.  
;<
; * ----------------------------------------------

  global window_color
  global window_id_color
window_color:
  add	ebx,color_id_table
  mov	ebx,[ebx]		;get color id

  add	ecx,color_id_table
  mov	ecx,[ecx]		;get color id
window_id_color:
  cmp	ebx,[bcolor_id]
  jne	wc_new_colors
  cmp	ecx,[fcolor_id]
  je	wc_exit			;eixt if colors unchanged
wc_new_colors:
  mov	[bcolor_id],ebx
  mov	[fcolor_id],ecx
 mov	eax,[ebp+win.s_cid_1]
 call	x_change_gc_colors
wc_exit:
  ret
;-----------------
  [section .data]
bcolor_id:	dd 0 ;last background color
fcolor_id:	dd 0 ;last foreground color
  [section .text]
