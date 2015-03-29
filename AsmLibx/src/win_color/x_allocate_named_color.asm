
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
;---------- x_allocate_named_color ------------------

%ifndef DEBUG
  extern x_send_request
  extern x_wait_reply
%endif
  extern str_move


struc anc_reply
  resb 1 ;reply code
  resb 1 ;unused
  resw 1 ;sequence#
  resd 1 ;reply length
.pixel:
  resd 1 ;color code
  resw 1 ;red
  resw 1 ;green
  resw 1 ;blue
  resw 1 ;visual red
  resw 1 ;visual green
  resw 1 ;visual blue
endstruc

;---------------------
;>1 win_color
;  x_allocate_named_color - ask for color id
;    Ask server for color id of ascii name.
; INPUTS
;    ebp = window block
;    eax = color map
;    esi = name string (max size 15 characters)    
;
; OUTPUT:
;    flags set for jns-success  js-error
;    eax = return code from x_wait1 or error code
;          all negative numbers are error
;    ebx = color id or zero if failure
;    ecx = pointer to buffer with x struc
;       resb 1 ;reply code 1=ok
;       resb 1 ;unused
;       resw 1 ;sequence#
;       resd 1 ;reply length
;       resd 1 ;color code (ebx)
;       resw 1 ;red
;       resw 1 ;green
;       resw 1 ;blue
;       resw 1 ;visual red
;       resw 1 ;visual green
;       resw 1 ;visual blue
;              
; NOTES
;   source file: x_allocate_named_color.asm
;<
; * ----------------------------------------------

  global x_allocate_named_color
x_allocate_named_color:
  mov	[anc_color_map],eax

  mov	edi,anc_string
  call	str_move	;move sting
  sub	edi,allocate_named_color_request ;compute length of pkt
  mov	edx,edi				;length in edx
;compute string length
  sub	edi,12				;remove pkt top
  mov	eax,edi
  mov	[anc_name_len],ax

%ifdef DEBUG
  push	edx				;save packet length
  mov	ecx,anc_msg
  call	crt_str
  pop	edx			;get packet lenght
%endif

anc_00:
  test	dl,3				;dword boundry?
  je	anc_10				;jmp if on boundry
  inc	edx
  jmp	short anc_00
anc_10:
  mov	eax,edx
  shr	eax,2
  mov	[anc_pkt_len],ax

  mov	ecx,allocate_named_color_request
;  mov	edx,allocate_named_color_request_len
  neg	edx			;indicate reply
  call	x_send_request
  js	anc_exit
  call	x_wait_reply		;get response
  js	anc_exit
  mov	ebx,[ecx+anc_reply.pixel]
  cmp	[ecx],byte 01		;was response ok
  je	anc_exit
  mov	eax,-1
anc_exit:
  or	eax,eax
  ret

  [section .data]
allocate_named_color_request:
 db 85	;opcode
 db 0	;unused
anc_pkt_len:
 dw 2	;request lenght in dwords
anc_color_map:
 dd 0
anc_name_len:
 dw 0
 dw 0		;unused
anc_string:
  times 16 db 0

%ifdef DEBUG
anc_msg: db 0ah,'allocate_named_color (2)',0ah,0
%endif

  [section .text]

