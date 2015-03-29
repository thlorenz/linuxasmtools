
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
;---------------- list_get_from_front.asm -------------------

struc list
.list_buf_top_ptr resd 1
.list_buf_end_ptr resd 1
.list_entry_size resd 1
.list_start_ptr resd 1
.list_tail_ptr resd 1
endstruc


;---------------------
;>1 list
;  list_get_from_front - return entry from top of list
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
; OUTPUT:
;    flag set (jns) if success
;      esi = ptr to data
;      edx,ebp unchanged
;    flag set (js) if no data on list
;      edx,ebp  unchanged 
;        
; NOTES
;   source file: list_get_from_front.asm
;   A full list will have a one entry gap
;   between the list_start_ptr and list_tail_ptr.
;   The list pointers cycle around the buffer
;   and entries can be removed from start or
;   end of list.
;<
; * ----------------------------------------------
  global list_get_from_front
list_get_from_front:
  mov	esi,[edx+list.list_start_ptr]
  cmp	esi,[edx+list.list_tail_ptr]
  jne	have_data
  mov	eax,-1
  jmp	short list_get_from_front_exit

have_data:
;move pointer forward to next entry
  mov	eax,esi
  add	eax,[edx+list.list_entry_size]
  cmp	eax,[edx+list.list_buf_end_ptr]
  jb	update_start_ptr		;jmp if not at end 
  mov	eax,[edx+list.list_buf_top_ptr]	;start at top
update_start_ptr:
  mov	[edx+list.list_start_ptr],eax
  xor	eax,eax			;set success flag
list_get_from_front_exit:
  or	eax,eax
  ret

;---------------------
  [section .text]

%ifdef DEBUG
  extern list_put_at_front
  global main,_start
main:
_start:
  mov	edx,control_block
  mov	esi,data1
  call	list_put_at_front
  call	list_put_at_front
  call	list_put_at_front
  call	list_get_from_front
  call	list_get_from_front
  call	list_get_from_front

  mov   eax, 1
  int	byte 80h
;--------
  [section .data]

control_block:
       dd buffer     ;top of buffer
       dd buffer_end ;end of buffer
       dd 4          ;each entry x bytes long
       dd buffer+8     ;first entry ptr
       dd buffer+8     ;last entry ptr


buffer: times 3 dd 0
	db 0
buffer_end:

data1	dd	1
	dd	2
	dd	3

  [section .text]
%endif
