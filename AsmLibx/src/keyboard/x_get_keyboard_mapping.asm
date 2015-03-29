
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
;---------- x_get_keyboard_mapping ------------------

;%ifndef DEBUG
  extern x_send_request
;%endif
  extern x_wait_big_reply
;---------------------
;>1 keyboard
;  x_get_keyboard_mapping - get map file for keyboard
; INPUTS
;  eax = buffer of size 4000+ to hold map
; OUTPUT:
;    buffer has map unless eax negative
;              
; NOTES
;   source file: x_get_keyboard_mapping.asm
;<
; * ----------------------------------------------
  extern c_min_keycode

  global x_get_keyboard_mapping
x_get_keyboard_mapping:
  push	eax
  mov	ax,[c_min_keycode]
  sub	ah,al			;compute count
  mov	[gkm_key_start],ax	;setup key range in pkt
  mov	ecx,gkm_pkt
  mov	edx,gkm_pkt_len
  neg	edx
  call	x_send_request
  pop	ecx			;get buffer
  js	gkm_exit
;  mov	ecx,[buffer]
  mov	edx,4000
  call	x_wait_big_reply
gkm_exit:
  ret


;-----------------
  [section .data]
gkm_pkt:
  db 101	;opcode
  db 0	;unused 
  dw 2
gkm_key_start:
  db 0
gkm_key_end:
  db 0
  db 0,0	;padding
gkm_pkt_len: equ $ - gkm_pkt
  [section .text]

