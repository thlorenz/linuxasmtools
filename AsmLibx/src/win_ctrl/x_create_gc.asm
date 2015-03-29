
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
;---------- x_create_gc ------------------

%ifndef DEBUG
  extern x_send_request
%endif

;---------------------
;>1 win_ctrl
;  x_create_gc - create graphic context 
; INPUTS
;    eax = cid id to create
;    ebx = drawable (window id)
;    esi = ptr to value list (including mask at front)
; OUTPUT:
;    none
;              
; NOTES
;   source file: x_create_gc.asm
;<
; * ----------------------------------------------

  global x_create_gc
x_create_gc:
  mov	[cid_id],eax
  mov	[cgr_id],ebx
;store the value list
  mov	edi,cgr_value_list
  lodsd				;get mask
  mov	ecx,eax			;save mask
cg_loop1:
  stosd				;store mask
cg_loop2:
  jecxz	cg_done			;jmp if all values moved
  shl	ecx,1
  jnc	cg_loop2
  lodsd
  jmp	short cg_loop1
cg_done:
  push	edi
  sub	edi,create_gc_request	;compute pkt
  mov	eax,edi			;  dword length
  shr	eax,2
  mov	[cgr_len],ax		;put length in pkt
  pop	edi
%ifdef DEBUG
  push	edi
  mov	ecx,cg__msg
  call	crt_str
  pop	edi
%endif

  mov	ecx,create_gc_request
  sub	edi,ecx			;compute pkt length
  mov	edx,edi
  call	x_send_request
  ret

  [section .data]
create_gc_request:
 db 55	;opcode
 db 0	;unused
cgr_len:
 dw 0
cid_id:
 dd 0		;entry parameter
cgr_id:
 dd 0	      ; fill in at runtime
cgr_value_list:
 times 20 dd 0

create_gc_request_len equ $ - create_gc_request


%ifdef DEBUG
cg__msg: db 0ah,'create_gc (55)',0ah,0
%endif

  [section .text]

