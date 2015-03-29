
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
;---------- x_freegc ------------------

%ifndef DEBUG
  extern x_send_request
%endif

;---------------------
;>1 win_ctrl
;  x_freegc - discard window information in server
;    (window does not exist after this call)
; INPUTS
;  eax = window id to map
; OUTPUT:
;    none (no reply is expected)
;              
; NOTES
;   source file: x_freegc.asm
;<
; * ----------------------------------------------

  global x_freegc
x_freegc:
  mov	[fgc_id],eax
%ifdef DEBUG
  mov	ecx,fgc_msg
  call	crt_str
%endif
  mov	ecx,fgc_pkt
  mov	edx,fgc_pkt_len
  call	x_send_request
  ret



%ifdef DEBUG
fgc_msg: db 0ah,'freegc (60)',0ah,0
%endif
  [section .text]

;-----------------
  [section .data]
fgc_pkt:
  db 60	;opcode
  db 0	;unused 
  dw 2
fgc_id:
  dd 02a00000h		;win id
fgc_pkt_len: equ $ - fgc_pkt
  [section .text]

