
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
;---------------- list_put_at_end.asm -------------------

struc list
.list_buf_top_ptr resd 1
.list_buf_end_ptr resd 1
.list_entry_size resd 1
.list_start_ptr resd 1
.list_tail_ptr resd 1
endstruc
;---------------------
;>1 list
;  list_put_at_end - add entry to end of list
; INPUTS
;    edx = list control block
;      struc list
;      .list_buf_top_ptr resd 1
;      .list_buf_end_ptr resd 1
;      .list_entry_size resd 1
;      .list_start_ptr resd 1
;      .list_tail_ptr resd 1
;      endstruc
;
;    Initially the control block for a empty
;    list could be set as follows by caller:
;       dd buffer     ;top of buffer
;       dd buffer_end ;end of buffer
;       dd x          ;each entry x bytes long
;       dd buffer     ;first entry ptr
;       dd buffer     ;last entry ptr
;
;    esi = ptr to data of length
;          liss_entry_size
;
; OUTPUT:
;    flag set (jns) if success
;      esi = will be advanced by size of entry
;      edx,ebp unchanged
;    flag set (js) if no room
;      esi,edx,ebp  unchanged 
;
;    if data wraps in buffer, the global
;    [last_buf_put_at_end_adr] will be set        
; NOTES
;   source file: list_put_at_end.asm
;   A full list will have a one entry gap
;   between the list_start_ptr and list_tail_ptr.
;   The list pointers cycle around the buffer
;   and entries can be removed from start or
;   end of list.
;<
; * ----------------------------------------------
  global list_put_at_end
list_put_at_end:
  call	next_put_at_end	;eax=next stuff  edi=current stuff
  cmp	eax,[edx+list.list_start_ptr]	;room for another entry
  jne	have_room
  mov   eax, -1
  jmp	short list_put_at_end_exit
have_room:
  mov	ecx,[edx+list.list_entry_size]
  rep	movsb
;the following is done last for thread safety
  mov	[edx+list.list_tail_ptr],eax
list_put_at_end_exit:
  or	eax,eax
  ret

;---------------------
; compute next put ptr
;input: edx = control block
;       esi,ebp not available
;output: eax=next ptr ptr
;        edi=current stuff ptr
;
next_put_at_end:
  mov	eax,[edx+list.list_tail_ptr]	;get ptr to last entry
  mov	edi,eax				;save stuff ptr
  add	eax,[edx+list.list_entry_size]	;move ptr forward
  cmp	eax,[edx+list.list_buf_end_ptr]	;beyond end of buffer
  jb	np_exit				;jmp if ok
  mov	eax,[edx+list.list_buf_top_ptr] ;restart put at top of buffer
np_exit:
  ret
;---------------------
;---------------------
  [section .text]

%ifdef DEBUG
  global main,_start
main:
_start:
  mov	edx,control_block
  mov	esi,data1
  call	list_put_at_end
  call	list_put_at_end
  call	list_put_at_end

  mov   eax, 1
  int	byte 80h
;--------
  [section .data]

control_block:
       dd buffer     ;top of buffer
       dd buffer_end ;end of buffer
       dd 4          ;each entry x bytes long
       dd buffer+4     ;first entry ptr
       dd buffer+4     ;last entry ptr


buffer: times 3 dd 0
	db 0
buffer_end:

data1	dd	1
	dd	2
	dd	3

  [section .text]
%endif
