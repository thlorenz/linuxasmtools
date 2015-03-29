
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

;---------- x_open_font ------------------

%ifndef DEBUG
  extern x_send_request
%endif
  extern str_move
  extern lib_buf

struc ofp
  resb 1	;db 45	;opcode
  resb 1	;db 0	;unused 
.of_pkt_length:
  resw 1	;dw open_font_len / 4
  resd 1	;dd 02a00001h		;win id
.font_length:
  resw 1	;dw 0
  resw 1	;dw 0		;unused
.font_str:
ofp_len:
endstruc

;---------------------
;>1 win_text
;  x_open_font - look for a named font
; INPUTS
;  eax = font id to assign
;  esi = font string
; OUTPUT:
;    none (no reply is expected)
;              
; NOTES
;   source file: x_open_font.asm
;<
; * ----------------------------------------------

  global x_open_font
x_open_font:
  mov	[open_font_id],eax
;build packet in lib_buf
  mov	edi,lib_buf
  push	esi
  mov	esi,open_font
  mov	ecx,ofp_len
  rep	movsb		;move packet
  pop	esi
  call	str_move	;move font name
;compute font string length  
  push	edi
  lea	eax,[lib_buf+ofp.font_str]
  sub	edi,eax		;compute length
  mov	eax,edi
  mov	[lib_buf + ofp.font_length],ax
  pop	edi
;compute pak len/4
  sub	edi,lib_buf
  mov	eax,edi
  test	al,byte 3
  jz	xof_10		;jmp if on dword boundry
  or	al,3
  inc	eax
xof_10:
  mov	edx,eax		;compute pkt length for write
  shr	eax,2
  mov	[lib_buf+ofp.of_pkt_length],ax
;send packet to server
  mov	ecx,lib_buf	;packet to send
  call	x_send_request
  ret



;-----------------
  [section .data]
open_font:
  db 45	;opcode
  db 0	;unused 
of_pkt_len:
  dw open_font_len / 4
open_font_id:
  dd 02a00001h		;win id
font_len:
  dw 0
  dw 0		;unused
font_string:
;open_font_end:
open_font_len equ $ - open_font

  [section .text]

