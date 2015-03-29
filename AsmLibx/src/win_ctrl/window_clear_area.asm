
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
;---------- window_clear_area ------------------

%ifndef DEBUG
%include "../../include/window.inc"
%endif
  extern lib_buf
  extern window_write_line
  extern x_send_request
;---------------------
;>1 win_ctrl
;  window_clear_area - clear with window color
; INPUTS
;  ebp = window block ptr
;  eax = x location (column)
;  ebx = y location (row)
;  ecx = width (chars)
;  edx = height (chars)
;  esi = flag 0=default window color  1=current color
;        setting.
; OUTPUT:
;    error = sign flag set for js
;    success = sign flag set for jns
;              
; NOTES
;   source file: window_clear_area.asm
;<
; * ----------------------------------------------

  global window_clear_area
window_clear_area:
  or	esi,esi
  jnz	force_color
  push	edx
  dec	eax
  mul	word [ebp+win.s_char_width]
  mov	[wca_x_loc],eax

  mov	eax,ebx
  dec	eax
  mul	word [ebp+win.s_char_height]
  mov	[wca_y_loc],eax

  mov	eax,ecx
  mul	word [ebp+win.s_char_width]
  mov	[wca_width],eax

  pop	eax
  mul	word [ebp+win.s_char_height]  
  mov	[wca_height],eax

  mov	eax,[ebp+win.s_win_id]
  mov	[wca_pki],eax	;save window

  mov	ecx,wca_pkt
  mov	edx,wca_pkt_end - wca_pkt
  call	x_send_request
  jmp	wca_exit

;------
force_color:
  mov	[fc_column],eax
  mov	[fc_row],ebx
  mov	[fc_width],ecx
  mov	[fc_height],edx

;fill lib_buf with one line of blanks
  mov	al,' '
  mov	ecx,[fc_width]
  cmp	ecx,700
  ja	wca_exit		;exit if error
  mov	edi,lib_buf
  rep	stosb

  mov	edx,[ebp+win.s_text_rows]	;get loop count
wca_loop:
  mov	edx,[fc_row]	;get display row
  mov	edi,[fc_width]	;line length
  mov	ecx,[fc_column]	;get column
  mov	esi,lib_buf	;string to display
  call	window_write_line
  js	wca_exit		;exit if error
  inc	dword [fc_row]
  dec	dword [fc_height]
  mov	eax,[fc_height]
  or	eax,eax
  jnz	wca_loop

wca_exit:
  ret

;-------------------
  [section .data]
  align 4
wca_pkt:db 61		;clear opcode
	db 1		;exposure
	dw 4		;paket length
wca_pki:dd 0		;window
wca_x_loc: dw 0		;x loc
wca_y_loc: dw 0		;y loc
wca_width: dw 0		;width
wca_height:dw 0		;height
wca_pkt_end:

fc_column  dd 0
fc_row     dd 0
fc_width   dd 0
fc_height  dd 0
  [section .text]
