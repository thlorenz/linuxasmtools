
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
;---------- x_get_selection_owner ------------

  extern x_send_request
  extern x_wait_reply 

;---------------------
;>1 win_info
;  x_get_selection_owner - get selection owner
; INPUTS
;    none
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;    
;    if success ecx -> lib_buf which contains:
;     db reply 1=success 0=failure
;     db -
;     dw sequence#
;     dd 0 (reply length)
;     dd WINDOW (0=no owner) else ?
;
; NOTES
;   source file: x_get_selection_owner.asm
;   We request owner of atom WINDOW, don't
;   know if this is ueeful?
;<
; * ----------------------------------------------

  global x_query_pointer
x_get_selection_owner:
%ifdef DEBUG
  extern crt_str
  mov	ecx,gso_msg
  call	crt_str
%endif
  mov	ecx,pkt2
  mov	edx,pkt2_end - pkt2
  neg	edx		;indicate reply expected
  call	x_send_request
  js	gso_exit
  call	x_wait_reply
gso_exit:
  ret

;-------------------
  [section .data]
pkt2:	db 23		;query pointer opcode
	db 0		;unused
	dw 2		;paket length
pk2:	dd 33		;window
pkt2_end:
  [section .text]
%ifdef DEBUG
gso_msg: db 0ah,'get_selection_owner (17h)',0ah,0
%endif

