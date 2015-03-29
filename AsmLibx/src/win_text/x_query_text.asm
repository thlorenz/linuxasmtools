
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
;---------- x_query_text ------------------

%ifndef DEBUG
  extern x_send_request
  extern x_wait_reply
  extern lib_buf
%endif
  extern str_move

struc text_extent
  resb 1  ;1			 Reply
  resb 1  ;			 draw-direction
;     0	       LeftToRight
;     1	       RightToLeft
  resb 2  ;CARD16		 sequence number
  resb 4  ;0			 reply length
.te_ascent:
  resb 2  ;INT16		 font-ascent
.te_descent:
  resb 2  ;INT16		 font-descent
  resb 2  ;INT16		 overall-ascent
  resb 2  ;INT16		 overall-descent
.te_width:
  resb 4  ;INT32		 overall-width
  resb 4  ;INT32		 overall-left
  resb 4  ;INT32		 overall-right
  resb 4  ;			 unused
endstruc
;---------------------
;>1 win_text
;  x_query_text - get lenght of text string
;    (this is mostly for non-fixed fonts that have
;     varing character length.  Use fixed fonts!)
; INPUTS
;    ebp = window block
;    eax = font id
;    esi = string ptr
;
; OUTPUT:
;    failure: eax=negative error code
;             flags set for js
;    success: flag set for jns
;    eax = char length
;    ebx = char height
;    ecx = ptr to font struc (in lib_buf)
;     1  1			 Reply
;     1			 draw-direction
;        0	       LeftToRight
;        1	       RightToLeft
;     2  CARD16		 sequence number
;     4  0			 reply length
;     2  INT16		 font-ascent (pixels)
;     2  INT16		 font-descent (pixels)
;     2  INT16		 overall-ascent (pixels)
;     2  INT16		 overall-descent (pixels)
;     4  INT32		 overall-width (pixels)
;     4  INT32		 overall-left (pixels)
;     4  INT32		 overall-right (pixels)
;     4			 unused
;              
; NOTES
;   source file: x_query_text.asm
;<
; * ----------------------------------------------

  global x_query_text
x_query_text:
  mov	[qt_id],eax
  mov	edi,qt_string
  call	str_move	;move sting
  sub	edi,query_text_request		;compute length of pkt
  mov	edx,edi				;length in edx
  mov	al,dl
  and	al,1				;isolate odd length
  mov	[odd_bool],al
qt_00:
  test	dl,3				;dword boundry?
  je	qt_10				;jmp if on boundry
  inc	edx
  jmp	short qt_00
qt_10:
  mov	eax,edx
  shr	eax,2
  mov	[qt_pkt_len],ax
%ifdef DEBUG
  push	edx
  mov	ecx,qt_msg
  call	crt_str
  pop	edx
%endif
  mov	ecx,query_text_request
;  mov	edx,query_text_request_len
  neg	edx		;indicate reply expected
  call	x_send_request
  js	qf_exit		;exit if error
  call	x_wait_reply		;
  js	qf_exit
  cmp	[ecx],byte 1	;good reply
  je	qf_ok
  mov	eax,-1
  or	eax,eax		;set error flag
  jmp	short qf_exit
qf_ok:
  mov	ecx,lib_buf
  xor	ebx,ebx
  mov	bx,[ecx+text_extent.te_ascent]
  add	bx,[ecx+text_extent.te_descent]	;char height
  xor	eax,eax
  mov	ax,[ecx+text_extent.te_width]
  movzx	dx,[ecx+text_extent.te_ascent]  
qf_exit:
  ret

  [section .data]
query_text_request:
 db 48	;opcode
odd_bool:
 db 0	;odd length flag 1=true
qt_pkt_len:
 dw 0	;request lenght in dwords
qt_id:
 dd 0	;font id
qt_string:
 times 100 db 0

%ifdef DEBUG
qt_msg: db 0ah,'query_text (2)',0ah,0
%endif

  [section .text]

