
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
;---------- x_list_fonts ------------------

;%ifndef DEBUG
  extern x_send_request
  extern x_wait_big_reply
;%endif
  extern str_move

struc fnt
  resb 1  ;1			 Reply
  resb 1  ;			 unused
  resb 2  ;CARD16		 sequence number
  resb 4  ;		 reply length
.num_strings:
  resb 2  ;number of name strings
  resb 22 ;unused
.strings:
  resb 1  ;font strings
fnt_struc_len:
endstruc
;---------------------
;>1 win_text
;  x_list_fonts - list fonts that match pattern
; INPUTS
;    eax = work buffer of size 24000+
;    edx = buffer size
;    esi = font patterns ptr.  Each pattern is
;          terminated with zero byte, last pattern
;          has additional zero.
; OUTPUT:
;    failure - eax = negative of error, or -1 if
;                    no string found.
;              flag set for "js"
;
;    success - flag set for "jns"
;              esi = ptr to font text
;              ecx = ptr to buffer with
;               resb 1  ;1  Reply
;               resb 1  ;    unused
;               resb 2  ;    sequence number
;               resb 4  ;    reply length
;               resb 2  ;number of name strings
;               resb 22 ;unused
;               resb 1  ;font string (first byte of string is length)
;
;               This function returns zero or one string.               
;              
; NOTES
;   source file: x_list_fonts.asm
;<
; * ----------------------------------------------

  global x_list_fonts
x_list_fonts:
  mov	[lf_buf],eax
  mov	[lf_buf_size],edx
;loop through mask table looking for font.
x_list_loop:
  mov	edi,lf_mask
  call	str_move
  mov	[input_string_ptr],esi ;save input string ptr
  push	edi
  sub	edi,lf_mask	;compute length
  mov	eax,edi
  mov	[lf_pattern_len],ax
  pop	edi
;compute pak len/4
  sub	edi,list_font_request
  mov	eax,edi
;adjust packet length to be dwords
of_len_00:
  test	al,byte 3
  jz	of_len_10
  or	al,3
  inc	eax
;convert length to dword count
of_len_10:
  mov	edx,eax		;compute pkt length for write
  shr	eax,2
  mov	[lf_pkt_len],ax
  mov	ecx,list_font_request
  neg	edx		;indicate reply expected
  call	x_send_request
  js	lf_exit
  mov	ecx,[lf_buf]	;work buffer
  mov	edx,[lf_buf_size]
  call	x_wait_big_reply
  js	lf_exit
  cmp	byte [ecx],1	;reply pkt
  jne	lf_error	;jmp if error packet or other
  mov	esi,[input_string_ptr]
  cmp	dword [ecx+fnt.num_strings],0
  jne	got_string	;jmp if font found
;last input pattern did not match any fonts
  cmp	byte [esi],0	;end of all strings?
  jne	x_list_loop
lf_error:
  mov	eax,-1
  jmp	short lf_exit
got_string:
  lea	esi,[ecx+fnt.strings] ;get ptr to font name
;insert zero at end of font string
  movzx	eax,byte [esi]	;get string length
  add	esi,eax
  inc	esi
  mov	byte [esi],0
  sub	esi,eax
;  extern log_str
;  call	log_str
lf_exit:
  or	eax,eax
  ret


  [section .data]

lf_buf		  dd 0	;work buffer ptr
lf_buf_size	  dd 0
input_string_ptr: dd 0

list_font_request:
 db 49	;opcode
 db 0	;unused
lf_pkt_len:
 dw 2	;request lenght in dwords
lf_max:
 dw 1	;maximum fonts returned
lf_pattern_len:
 dw 0
lf_mask:
 times 20 db 0	;font pattern

  [section .text]

