
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
;---------- x_get_window_attributes ------------------

  extern x_wait_reply
  extern x_send_request
;---------------------
;>1 win_info
;  x_get_window_attributes - get window attributes
; INPUTS
;    eax = window id to query
; OUTPUT:
;    fail state
;     flags - set for js
;     eax = negative error, -1=timeout,else sys err
;    success state          
;     flag set (jns) if success
;     eax = number of reply bytes in buffer
;     ebx = 0 if packet has is in sync with write
;     ecx = buffer ptr (lib_buf) 
;
;    if success ecx -> lib_buf with:
;      db reply 1=success 0=fail
;      db flag 0=NotUseful 1=WhenMapped 2=always
;      dw sequence#
;      dd 3 (reply length)
;      dd visual id
;      dw class 1=inputOutput 2=inputOnly
;      db bit gravety
;      db win gravety
;      dd backing planes
;      dd backing pixel
;      db save under (bool) 1=yes 0=no
;      db map is installed (bool)
;      db map state (0=unmapped 1=unviewable 2=viewable)
;      db override redirect (bool) 0=no
;      dd color map (0=none)
;      dd all event mask
;      dd your event mask
;      dw SETofDEVICEEVENT
;              
; NOTES
;   source file: x_get_window_attributes.asm
;<
; * ----------------------------------------------

  global x_get_window_attributes
x_get_window_attributes:
  mov	[gwa_pki],eax	;save window
%ifdef DEBUG
 extern crt_str
  mov	ecx,gwa_msg
  call	crt_str
%endif
  mov	ecx,gwa_pkt
  mov	edx,gwa_pkt_end - gwa_pkt
  neg	edx		;indicate reply expected
  call	x_send_request
  js	gwa_exit	;exit if error
  call	x_wait_reply
gwa_exit:
  ret

;-------------------
  [section .data]
  align 4
gwa_pkt:db 3		;get window attributs opcode
	db 0		;unused
	dw 2		;paket length
gwa_pki:dd 0		;window
gwa_pkt_end:
%ifdef DEBUG
gwa_msg: db 0ah,'get_window_attributes (3h)',0ah,0
%endif
  [section .text]
