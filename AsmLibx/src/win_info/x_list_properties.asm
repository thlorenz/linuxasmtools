
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
;---------- x_list_properties ------------------

  extern x_send_request
  extern x_wait_big_reply

;---------------------
;>1 win_info
;  x_list_properties - get list of atoms (properties)
; INPUTS
;    eax = window id to query
;    ecx = buffer
;    edx = buffer length
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success ecx -> lib_buf with:
;      db reply 1=success 0=fail
;      db -
;      dw sequence#
;      dd reply length
;      dw number of atoms
;      times 22 (unused)
;      dd list of atoms
;              
; NOTES
;   source file: x_list_properties.asm
;<
; * ----------------------------------------------

  global x_list_properties
x_list_properties:
  push	ecx
  push	edx
  mov	[lp_pki],eax	;save window
%ifdef DEBUG
  extern crt_str
  mov	ecx,lp_msg
  call	crt_str
%endif
  mov	ecx,lp_pkt
  mov	edx,lp_pkt_end - lp_pkt
  neg	edx		;indicate reply expected
  call	x_send_request
  pop	edx
  pop	ecx
  js	lp_exit
  call	x_wait_big_reply
lp_exit:
  ret

;-------------------
  [section .data]
lp_pkt:	db 21		;query pointer opcode
	db 0		;unused
	dw 2		;paket length
lp_pki:	dd 0		;window
lp_pkt_end:
  [section .text]
%ifdef DEBUG
lp_msg: db 0ah,'list_properties (15h)',0ah,0
%endif
