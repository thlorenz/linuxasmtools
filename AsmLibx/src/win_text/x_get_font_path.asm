
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
;---------- x_get_font_path ------------------

;%ifndef DEBUG
  extern x_send_request
  extern x_wait_reply
;%endif
  extern str_move

struc fontp
  resb 1  ;1			 Reply
  resb 1  ;			 unused
  resb 2  ;CARD16		 sequence number
  resb 4  ; dword count (reply length)
  resb 2  ;number of name strings
  resb 22 ;unused
  resb 1  ;font strings, first byte is length
fontp_struc_len:
endstruc
;---------------------
;>1 win_text
;  x_get_font_path - get paths used for font search
; INPUTS
;    none
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax positive read length and flag set "jns"
;              ecx = buffer ptr with
;  resb 1  ;1			 Reply
;  resb 1  ;			 unused
;  resb 2  ;CARD16		 sequence number
;  resb 4  ;dword count (reply length)
;  resb 2  ;number of name strings
;  resb 22 ;unused
;  resb 1  ;font strings (first byte of string is length)
;              
; NOTES
;   source file: x_get_font_path.asm
;<
; * ----------------------------------------------

  global x_get_font_path
x_get_font_path:
  mov	ecx,get_font_path_request
  mov	edx,gfpr_end - get_font_path_request
  neg	edx		;indicate reply expected
  call	x_send_request
  js	gfp_exit
  call	x_wait_reply
gfp_exit:
  ret


  [section .data]
get_font_path_request:
 db 52	;opcode
 db 0	;unused
 dw 1	;request lenght in dwords
gfpr_end:

  [section .text]

