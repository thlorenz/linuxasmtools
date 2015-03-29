
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
;---------- window_clear ------------------

%ifndef DEBUG
%include "../../include/window.inc"
%endif
  extern lib_buf
  extern window_write_line
  extern x_send_request
;---------------------
;>1 win_ctrl
;  window_clear - clear window              
; INPUTS
;  ebp = window block ptr
;  eax = 0 for default window color
;        1 for current color seting
;
; OUTPUT:
;    error = sign flag set for js
;    success = sign flag set for jns
;              
; NOTES
;   source file: window_clear.asm
;<
; * ----------------------------------------------

  global window_clear
window_clear:
  or	eax,eax
  jnz	wc_force_color
  mov	eax,[ebp+win.s_win_id]
  mov	[wc_pki],eax	;save window
  mov	eax,[ebp+win.s_win_x]
  mov	[wc_x_loc],eax
  mov	eax,[ebp+win.s_win_width]
  mov	[wc_width],eax
  mov	ecx,wc_pkt
  mov	edx,wc_pkt_end - wc_pkt
  call	x_send_request
  jmp	short wc_exit
wc_force_color:
;fill lib_buf with one line of blanks
  mov	al,' '
  mov	ecx,[ebp+win.s_text_columns]
  push	ecx
  mov	edi,lib_buf
  rep	stosb
  pop	edi				;restore llne length

  mov	edx,[ebp+win.s_text_rows]	;get loop count
wc_loop:
  push	edx		;save current row
  push	edi		;save line length
  mov	ecx,1		;get column
  mov	esi,lib_buf	;string to display
  call	window_write_line
  pop	edi		;restore line len
  pop	edx		;restore current row
  js	wc_exit		;exit if error
  dec	edx
  jnz	wc_loop
wc_exit:
  ret

;-------------------
  [section .data]
  align 4
wc_pkt:db 61		;clear opcode
	db 1		;exposure
	dw 4		;paket length
wc_pki:dd 0		;window
wc_x_loc: dw 0		;x loc
	  dw 0		;y loc
wc_width: dw 0		;width
	  dw 0		;height
wc_pkt_end:
  [section .text]
