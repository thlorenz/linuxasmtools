
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
;---------- x_write_block ------------------

  extern str_move

%ifndef DEBUG
  extern x_send_request
  extern tm_pkt
%endif

struc tm
  		resb 1	;opcode
.tm_str_len	resb 1
.tm_len		resw 1	;pkt len / 4
.tmp_id		resd 1	;win id
.tm_gc		resd 1	;gc id
.tm_x		resw 1	;x column
.tm_y		resw 1	;y row
.tm_string	resb 1	;string
endstruc
;---------------------
;>1 win_text
;  x_write_block - write ascii block to window 
; INPUTS
;  eax = window id to map
;  ebx = window cid
;  ecx = x location, pixel column (0=left edge)
;  edx = y location, pixel row (0=top of win)
;  esi = string
;  edi = string length (max size is 255) 
; OUTPUT:
;   "js" flag set if error
;              
; NOTES
;   source file: x_write_block.asm
;<
; * ----------------------------------------------

  global x_write_block
  global x_write_block_entry1,x_write_block_entry2
x_write_block:
  mov	[tm_pkt+tm.tmp_id],eax
  mov	[tm_pkt+tm.tm_gc],ebx
x_write_block_entry1:
  mov	[tm_pkt+tm.tm_x],cx
  mov	[tm_pkt+tm.tm_y],dx
  mov	edx,esi		;save string start
  mov	ecx,edi		;length -> esi
  mov	[tm_pkt+tm.tm_str_len],cl	;save length
  mov	edi,tm_pkt+tm.tm_string
  rep	movsb		;move the string
x_write_block_entry2:
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
  mov	[tm_pkt+tm.tm_len],ax
  call	x_send_request
  ret



;-----------------
;  [section .data]

  [section .text]

