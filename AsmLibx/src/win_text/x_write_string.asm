
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
;000:<:0010: 32: Request(74): PolyText8 drawable=0x02e00001 gc=0x02e00002 x=0 y=14
;  texts={   delta=0 s='hello world'},{  s='\000'};
;---------- x_write_string ------------------

  extern str_move

%ifndef DEBUG
  extern x_send_request
%endif

;---------------------
;>1 win_text
;  x_write_string - write a string to window 
; INPUTS
;  eax = window id to map
;  ebx = window cid
;  ecx = x location, pixel column (0=left column)
;  edx = y location, pixel row (0=top of window)
;  esi = string
; OUTPUT:
;    "js" flag set for error
;              
; NOTES
;   source file: x_write_string.asm
;<
; * ----------------------------------------------

  global x_write_string
x_write_string:
  mov	[tmp_id],eax
  mov	[tm_gc],ebx
  mov	[tm_x],cx
  mov	[tm_y],dx
  mov	edx,esi		;save string start
  mov	edi,tm_string
  call	str_move	;move the string
  sub	esi,edx		;compute string length
  dec	esi
  mov	edx,esi
  mov	[tm_str_len],dl	;save string length	  
%ifdef DEBUG
  push	edi
  mov	ecx,ws_msg
  call	crt_str
  pop	edi
%endif
;compute length of packet and force to dword boundry
  mov	ecx,tm_pkt
  mov	edx,edi		;get packet end
  sub	edx,ecx		;compute length in edx
tm_adjust:
  test	dl,3
  jz	tm_stuf		;jmp if even
  inc	edx
  jmp	short tm_adjust
tm_stuf:
;store pkt_len/4 in packet
  mov	eax,edx
  shr	eax,2
  mov	[tm_len],ax
  call	x_send_request
  ret



;-----------------
  [section .data]
  global tm_pkt
tm_pkt:
  db 76	;opcode
tm_str_len:
  db 0	;string length
tm_len:
  dw 0			;tmp_len / 4
tmp_id:
  dd 02a00001h		;win id
tm_gc:
  dd 02a00002h		;win gc
tm_x:
  dw 0
tm_y:
  dw 0
tm_string:
  times 256 db 0
  [section .text]

