
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
;---------- x_destroy_window ------------------

%ifndef DEBUG
  extern x_send_request
%endif

;---------------------
;>1 win_ctrl
;  x_destroy_window - destroy window
; INPUTS
;  eax = window id to destroy
; OUTPUT:
;    none (no reply is expected)
;              
; NOTES
;   source file: x_destroy_window.asm
;<
; * ----------------------------------------------

  global x_destroy_window
x_destroy_window:
  mov	[dw_id],eax
%ifdef DEBUG
  mov	ecx,dw_msg
  call	crt_str
%endif
  mov	ecx,dw_pkt
  mov	edx,dw_pkt_len
  call	x_send_request
  ret



%ifdef DEBUG
dw_msg: db 0ah,'destroy_window (60)',0ah,0
%endif
  [section .text]

;-----------------
  [section .data]
dw_pkt:
  db 60	;opcode
  db 0	;unused 
  dw 2
dw_id:
  dd 02a00000h		;win id
dw_pkt_len: equ $ - dw_pkt
  [section .text]

