
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
;---------- x_reparent_window ------------------

;%ifndef DEBUG
  extern x_send_request
;%endif


;---------------------
;>1 win_ctrl
;  x_reparent_window - get list of windows
; INPUTS
;    eax = window id of new parent
;    ebx = window id of target window
;
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;              
; NOTES
;   source file: x_reparent_window.asm
;<
; * ----------------------------------------------

  
  global x_reparent_window
x_reparent_window:
  mov	[xrw_new_parent],eax	;save id
  mov	[xrw_mod_id],ebx

  mov	ecx,xrw_pkt
  mov	edx,xrw_pkt_len
  call	x_send_request
  ret

;------------------------
  [section .data]
xrw_pkt:
  db 07		;configure window opcode
  db 0		;unused
  dw 4		;request length
xrw_mod_id:
  dd 0
xrw_new_parent:
  dd 0
xrw_x:
  dw 0
xrw_y:
  dw 0
xrw_pkt_len	equ $ - xrw_pkt
  [section .text]

