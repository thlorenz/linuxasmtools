
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
;---------- x_translate_coordinates ------------------

  extern x_send_request
  extern x_wait_reply 
;---------------------
;>1 win_info
;  x_translate_coordinates - get abs win location
;    return location relative to root win
; INPUTS
;    eax = window id to query
; OUTPUT:
;    flag set (jns) if success
;      eax = return from socket read (size of read)
;    flag set (js) if err, eax=error code
;
;    if success, ecx points to lib_buf with:
;     db reply, 1=ok 0=failure
;     db unused
;     dw sequence#
;     dd 0 unused
;     dd child window
;     dw x location of win, pixel column
;     dw y location of win, pixel row
;
; NOTES
;   source file: x_translate_coordinates.asm
;<
; * ----------------------------------------------

  extern root_win_id

  global x_translate_coordinates
x_translate_coordinates:
  mov	[gg_pki],eax	;save window
  mov	eax,[root_win_id]
  mov	[root_win],eax
  mov	ecx,gg_pkt
  mov	edx,gg_pkt_end - gg_pkt
  neg	edx		;indicate reply expected
  call	x_send_request
  js	gg_exit
  call	x_wait_reply
gg_exit:
  ret

;-------------------
  [section .data]
gg_pkt:	db 40		;TranslateGeometry opcode
	db 0		;unused
	dw 4		;paket length 2 dwords
gg_pki:	dd 0		;target windowj
root_win: dd 0		;root win id
	dw 0		;x base
	dw 0		;y base
gg_pkt_end:
  [section .text]

%ifdef DEBUG
  extern env_stack
  extern x_connect
  global _start
_start:
  call	env_stack
  call	x_connect
  mov	eax,2000003h
  call	x_translate_coordinates
  mov	eax,1
  int	80h

%endif

