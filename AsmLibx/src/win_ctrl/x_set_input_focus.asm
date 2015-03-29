
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
;---------- x_set_input_focus ------------------

%ifndef DEBUG
  extern x_send_request
%endif

;---------------------
;>1 win_ctrl
;  x_set_input_focus - set input focus
; INPUTS
;    eax = window id
; OUTPUT:
;    none
; NOTES
;   source file: x_set_input_focus.asm
;<
; * ----------------------------------------------

  global x_set_input_focus
x_set_input_focus:
  mov	[sif_win],eax
%ifdef DEBUG
  mov	ecx,sif_msg
  call	crt_str
%endif
  mov	ecx,sif_pkt
  mov	edx,sif_pkt_end - sif_pkt
  call	x_send_request
  ret

;-------------------
  [section .data]
sif_pkt:db 42		;set input focus
	db 2		;revert to parent
	dw 3		;paket length
sif_win:dd 0		;window
	dd 0		;timestamp 0=current time
sif_pkt_end:
  [section .text]

%ifdef DEBUG
sif_msg: db 0ah,'set_input_focus (42) ',0ah,0
%endif

