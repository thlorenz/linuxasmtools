
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
;---------- x_query_pointer ------------------

;%ifndef DEBUG
  extern x_send_request
  extern x_wait_big_reply 
;%endif

;---------------------
;>1 mouse
;  x_query_pointer - query pointer position
; INPUTS
;    eax = window id to query
;    ecx = buffer to hold reply packet
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success ecx -> buffer with:
;      db reply 1=success 0=fail
;      db -
;      dw sequence#
;      dd reply length (zero)
;      dd root window id
;      dd child window id (0=no child)
;      dw root x position (pixel column)
;      dw root y position (pixel row)
;      dw child x position (pixel column)
;      dw child y position (pixel row)
;      dw event mask
;         SETofKEYBUTMASK
;          #x0001	 Shift
;          #x0002	 Lock
;          #x0004	 Control
;          #x0008	 Mod1
;          #x0010	 Mod2
;          #x0020	 Mod3
;          #x0040	 Mod4
;          #x0080	 Mod5
;          #x0100	 Button1
;          #x0200	 Button2
;          #x0400	 Button3
;          #x0800	 Button4
;          #x1000	 Button5
;          #xE000	 unused but must be zero
;              
; NOTES
;   source file: x_query_pointer.asm
;<
; * ----------------------------------------------

  global x_query_pointer
x_query_pointer:
  mov	[qt_timeout],dword 4
  push	ecx
  push	edx
  mov	[qt_pki],eax	;save window
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
  ret

;-------------------
  [section .data]
qt_pkt:	db 38		;query pointer opcode
	db 0		;unused
	dw 2		;paket length
qt_pki:	dd 0		;window
qt_pkt_end:
qt_timeout: dd 0
  [section .text]
