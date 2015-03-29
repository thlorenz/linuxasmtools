
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
;---------- x_query_tree ------------------

  extern x_send_request
  extern x_wait_big_reply 

;---------------------
;>1 win_info
;  x_query_tree - get list of windows
; INPUTS
;    eax = window id to query
;    ecx = buffer for data
;    edx = buffer length
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success ecx -> buffer with:
;      db reply 1=success 0=fail
;      db -
;      dw sequence#
;      dd reply length
;      dd root window id
;      dd parent window id (0=no parent)
;      dw number of child windows
;      times 14 (unused)
;      list of windows
;              
; NOTES
;   source file: x_query_tree.asm
;<
; * ----------------------------------------------

  global x_query_tree
x_query_tree:
  mov	[qt_timeout],dword 4
  push	ecx
  push	edx
  mov	[qt_pki],eax	;save window
%ifdef DEBUG
  extern crt_str
  mov	ecx,qt_msg
  call	crt_str
%endif
x_query_retry:
  mov	ecx,qt_pkt
  mov	edx,qt_pkt_end - qt_pkt
  neg	edx		;indicate reply expected
  call	x_send_request
  pop	edx
  pop	ecx
  js	qt_exit
  push	edx
  push	ecx
  call	x_wait_big_reply
  pop	ecx
  pop	edx
  cmp	eax,-1		;retry ?
  jne	qt_exit
  dec	dword [qt_timeout]
  mov	eax,[qt_timeout]
  or	eax,eax
  jz	qt_err
  push	ecx
  push	edx
  jmp	x_query_retry
qt_err:
  mov	eax,-1
qt_exit:
  or	eax,eax
  ret

;-------------------
  [section .data]
qt_pkt:	db 15		;query tree opcode
	db 0		;unused
	dw 2		;paket length
qt_pki:	dd 0		;window
qt_pkt_end:
qt_timeout: dd 0
%ifdef DEBUG
qt_msg: db 0ah,'query_tree (0fh)',0ah,0
%endif
  [section .text]
