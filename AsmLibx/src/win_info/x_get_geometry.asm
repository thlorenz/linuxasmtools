
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
;---------- x_get_geometry ------------------

  extern x_send_request
  extern x_wait_reply 
;---------------------
;>1 win_info
;  x_get_geometry - get window geometry
; INPUTS
;    eax = window id to query
; OUTPUT:
;    flag set (jns) if success
;      eax = return from socket read (size of read)
;    flag set (js) if err, eax=error code
;
;    if success, ecx points to lib_buf with:
;     db reply, 1=ok 0=failure
;     db depth
;     dw sequence#
;     dd 0 (reply length)
;     dd window (root id)
;     dw x location of win, pixel column
;     dw y location of win, pixel row
;     dw width, pixel width
;     dw height, pixel height
;     dw border width
;
;     !! Note: the x,y location is relative to parents
;              origon.  Often these values are zero if
;              outside parent.  The border width is also
;              zero, and all three are zero for pixmaps.
;         
; NOTES
;   source file: x_get_geometry.asm
;<
; * ----------------------------------------------

  global x_get_geometry
x_get_geometry:
  mov	[gg_pki],eax	;save window
%ifdef DEBUG
  extern crt_str
  mov	ecx,gg_msg
  call	crt_str
%endif
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
gg_pkt:	db 14		;GetGeometry opcode
	db 0		;unused
	dw 2		;paket length 2 dwords
gg_pki:	dd 0		;drawable
gg_pkt_end:
  [section .text]

%ifdef DEBUG
gg_msg: db 0ah,'get_geometry (0eh)',0ah,0
%endif

