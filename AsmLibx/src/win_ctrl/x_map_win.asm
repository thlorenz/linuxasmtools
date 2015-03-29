
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
;---------- x_map_win ------------------

%ifndef DEBUG
  extern x_send_request
%endif

;---------------------
;>1 win_ctrl
;  x_map_win - show window 
; INPUTS
;  eax = window id to map
; OUTPUT:
;    none (no reply is expected)
;              
; NOTES
;   source file: x_map_win.asm
;<
; * ----------------------------------------------

  global x_map_win
x_map_win:
  mov	[map_win_id],eax
%ifdef DEBUG
  mov	ecx,xmw_msg
  call	crt_str
%endif
  mov	ecx,map_win
  mov	edx,map_win_len
  call	x_send_request
  ret



;-----------------
  [section .data]
map_win:
  db 8	;opcode
  db 0	;unused 
  dw map_win_len / 4
map_win_id:
  dd 02a00001h		;win id
map_win_len: equ $ - map_win

%ifdef DEBUG
xmw_msg: db 0ah,'map_win (08)',0ah,0
%endif
  [section .text]

