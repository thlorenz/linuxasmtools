
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
;---------- x_get_input_focus ------------------

  extern x_send_request
  extern x_wait_reply 
  extern delay

;---------------------
;>1 win_info
;  x_get_input_focus - get focus
;    (find out who has active window)
; INPUTS
;    none
; OUTPUT:
;    flags set for js(error) or jns(success)
;    if error eax = error code
;    if success lib_buf and [ecx] contain:
;     db reply 1=success 0=fail
;     db revert_to 0=none 1=pointerroot 2=parent
;     dw sequence#
;     dd 0 (reply length)
;     dd window (window id that has focus)
;        0=no focus, 1=ptr root        
; NOTES
;   source file: x_get_input_focus.asm
;<
; * ----------------------------------------------

  global x_get_input_focus
x_get_input_focus:
  mov	[timeout],byte 3
%ifdef DEBUG
  extern crt_str
  mov	ecx,gif_msg
  call	crt_str
%endif
  mov	ecx,gif_pkt
  mov	edx,gif_pkt_end - gif_pkt
  neg	edx		;indicate reply expected
  call	x_send_request
  js	gif_exit
wait_again:
  call	x_wait_reply
  or	eax,eax
  jns	gif_success
  mov	eax,2
  call	delay
  dec	dword [timeout]
  cmp	[timeout],byte 0
  jne	wait_again
  neg	eax
  jmp	short gif_exit
gif_success:
  mov	eax,[ecx+8]	;get window id
gif_exit:
  ret

;-------------------
  [section .data]
gif_pkt:db 43		;get input focus
	db 0		;unused
	dw 1		;paket length
gif_pkt_end:
timeout	dd 0
  [section .text]

%ifdef DEBUG
gif_msg: db 0ah,'get_input_focus (43) ',0ah,0
%endif

