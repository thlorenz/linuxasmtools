
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
;---------- x_query_font ------------------

;%ifndef DEBUG
  extern x_send_request
  extern x_wait_big_reply
;%endif
  extern str_move

struc font
  resb 1  ;1			 Reply
  resb 1  ;			 unused
  resb 2  ;CARD16		 sequence number
  resb 4  ;7+2n+3m		 reply length
  resb 12 ;CHARINFO		 min-bounds
  resb 4  ;			 unused
  resb 12 ;CHARINFO		 max-bounds
  resb 4  ;			 unused
  resb 2  ;CARD16		 min-char-or-byte2
  resb 2  ;CARD16		 max-char-or-byte2
  resb 2  ;CARD16		 default-char
.num_prop:
  resb 2  ;n			 number of FONTPROPs in properties
  resb 1  ;			 draw-direction
;     0	       LeftToRight
;     1	       RightToLeft
  resb 1  ;CARD8		 min-byte1
  resb 1  ;CARD8		 max-byte1
  resb 1  ;BOOL		 all-chars-exist
.ascent:
  resb 2  ;INT16		 font-ascent
.descent:
  resb 2  ;INT16		 font-descent
  resb 4  ;m			 number of CHARINFOs in char-infos
;  8n LISTofFONTPROP	 properties
;  12m	       LISTofCHARINFOchar-infos
font_struc_len:
endstruc
;---------------------
;>1 win_text
;  x_query_font - check current font state
;    (if open_font failed this will return error)
; INPUTS
;    eax = font id
;    ebx = buffer to hold font info (24000+ bytes)
;    edx = buffer size    
; OUTPUT:
;    failure - eax = negative error code
;    success - eax = char length
;              ebx = char height
;              edx = char ascent
;              ecx = buffer ptr with
;  1  1			 Reply
;  1			 unused
;  2  CARD16		 sequence number
;  4  7+2n+3m		 reply length
;  12 CHARINFO		 min-bounds
;  4			 unused
;  12 CHARINFO		 max-bounds
;  4			 unused
;  2  CARD16		 min-char-or-byte2
;  2  CARD16		 max-char-or-byte2
;  2  CARD16		 default-char
;  2  n			 number of FONTPROPs in properties
;  1			 draw-direction
;     0	       LeftToRight
;     1	       RightToLeft
;  1  CARD8		 min-byte1
;  1  CARD8		 max-byte1
;  1  BOOL		 all-chars-exist
;  2  INT16		 font-ascent
;  2  INT16		 font-descent
;  4  m			 number of CHARINFOs in char-infos
;  8n LISTofFONTPROP	 properties
;  12m	       LISTofCHARINFOchar-infos
;
;
;  FONTPROP
;  4  ATOM		 name
;  4  <32-bits>		 value
;
;
;
;  CHARINFO
;  2  INT16		 left-side-bearing
;  2  INT16		 right-side-bearing
;  2  INT16		 character-width
;  2  INT16		 ascent
;  2  INT16		 descent
;  2  CARD16		 attributes
;
;              
; NOTES
;   source file: x_query_font.asm
;<
; * ----------------------------------------------

  global x_query_font
x_query_font:
  mov	[qf_id],eax
  mov	[qf_buf_size],edx
  push	ebx
  mov	ecx,query_font_request
  mov	edx,query_font_request_len
  neg	edx	;indicate reply expected
  call	x_send_request
  pop	ecx	;get buffer
  js	qf_exit	;exit if error
  push	ecx	;save buffer
  mov	edx,[qf_buf_size] ;buffer length
  call	x_wait_big_reply
  pop	ecx	;restore buffer
  js	qf_exit
  cmp	byte [ecx],1
  je	qf_20		;jmp if reply packet
  mov	eax,-1
  or	eax,eax
  jmp	short qf_exit
qf_20:
;look up height -> ebx
  xor	ebx,ebx
  mov   bx,[ecx+font.ascent]
  push	ebx
  add	bx,[ecx+font.descent]

  xor	eax,eax
  mov	ax,[ecx+font.num_prop]
  shl	eax,3	;multiply by 8
  lea	eax,[ecx+eax+font_struc_len];compute address of first charInfo
  movzx eax,word [eax+4]	;get char width
  pop	edx			;get char ascent
qf_exit:
  ret

;-------------------
  [section .data]
query_font_request:
 db 47	;opcode
 db 0	;unused
qf_pkt_len:
 dw 2	;request lenght in dwords
qf_id:
 dd 0	;font id
query_font_request_len equ $ - query_font_request

qf_buf_size	dd 0

  [section .text]

