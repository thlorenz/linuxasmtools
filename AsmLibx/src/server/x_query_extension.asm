
;-----------------------------------------------------------------------
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


;  [section .text align=1]
;---------- x_query_extension ------------------

;%ifndef DEBUG
  extern x_send_request
  extern x_wait_reply
;%endif
  extern str_move

struc qext
  resb 1  ;1			 Reply
  resb 1  ;			 unused
  resb 2  ;CARD16		 sequence number
  resb 4  ; dword count (reply length)
.fl  resb 1  ;0=not present
.op  resb 1  ;major opcode
  resb 1  ;first event
  resb 1  ;first error
  resb 20 ;unused
qext_struc_len:
endstruc
;---------------------
;>1 server
;  x_query_extension - check for x server extension
; INPUTS
;    esi = ptr to extension name
;    ecx = extension name length
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax extension op code
;              ecx = buffer ptr with
;  resb 1  ;1 Reply
;  resb 1  ; unused
;  resb 2  ;sequence number
;  resb 4  ;dword count (reply length)
;  resb 1  ;0=not present
;  resb 1  ;major op code
;  resb 1  ;first-event
;  resb 1  ;first-error
;  resb 20 ;filler
;              
; NOTES
;   source file: x_query_extension.asm
;<
; * ----------------------------------------------

  global x_query_extension
x_query_extension:
  mov	[qef_nl],cx	;store length of name
  mov	edi,qef_name
  cld
  rep	movsb		;move the name
;compute length of packet and force to dword boundry
  mov	ecx,query_extension_request
  mov	edx,edi		;get packet end
  sub	edx,query_extension_request	;compute length in edx
tm_adjust:
  test	dl,3
  jz	tm_stuf		;jmp if even
  inc	edx
  jmp	short tm_adjust
tm_stuf:
;store pkt_len/4 in packet
  mov	eax,edx
  shr	eax,2
  mov	[qef_len],ax

  mov	ecx,query_extension_request
;  mov	edx,(qer_end - query_extension_request)  edx=pkt length
  neg	edx		;indicate reply expected
  call	x_send_request
  js	qfp_exit
  call	x_wait_reply
  js	qfp_exit	;exit if error
  xor	eax,eax
  mov	al,[ecx+qext.op] ;get opcode
  cmp	[ecx+qext.fl], byte 0 ;op found
  jne	qfp_exit	;jmp if no op found
  neg	eax		;set error  
qfp_exit:
  ret


  [section .data]
query_extension_request:
 db 98	;opcode
 db 0	;unused
qef_len:
 dw 0	;request lenght in dwords
qef_nl:
 dw 0	;length of extension name
 dw 0   ;unused
qef_name:
 times 20 db 0 ;name goes here
qef_end:

  [section .text]
