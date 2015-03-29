
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
;---------------- list_check_end.asm -------------------

struc list
.list_buf_top_ptr resd 1
.list_buf_end_ptr resd 1
.list_entry_size resd 1
.list_start_ptr resd 1
.list_tail_ptr resd 1
endstruc

;  extern last_buf_put_adr

;---------------------
;>1 list
;  list_check_end - check list end, do not remove
; INPUTS
;    edx = llst control block
;      struc list
;      .list_buf_top_ptr resd 1
;      .list_buf_end_ptr resd 1
;      .list_entry_size resd 1
;      .list_start_ptr resd 1
;      .list_tail_ptr resd 1
;      endstruc
;
; OUTPUT:
;    flag set (jns) if entry found
;      esi = ptr to data
;      eax = 0
;      edx,ebp unchanged
;    flag set (js) if no data on list
;      esi,edx,ebp  unchanged
;      eax = -1 
;        
; NOTES
;   source file: list_check_end.asm
;   A full list will have a one entry gap
;   between the list_start_ptr and list_tail_ptr.
;   The list pointers cycle around the buffer
;   and entries can be removed from start or
;   end of list.
;
;   see also: list_put_at_front
;             list_put_at_end
;             list_first_out
;<
; * ----------------------------------------------
  global list_check_end
list_check_end:
  mov	esi,[edx+list.list_tail_ptr]
  cmp	esi,[edx+list.list_start_ptr]
  jne	have_data		;jmp if list has data
  mov	eax,-1
  jmp	short list_check_end_exit

have_data:
;move pointer back to previous entry
  cmp	esi,[edx+list.list_buf_top_ptr]	;at top of list?
  je	at_top				;jmp if at top
  sub	esi,[edx+list.list_entry_size]
  jmp	short got_end_ptr
at_top:
;special kludge, save last entry adr for list_check_end, it needs
;this to wrap ptr back to end.  The buffer may have padding at end
;and we don't know exactly where last entry starts.
  mov	eax,[edx+list.list_buf_end_ptr]
  sub	eax,[edx+list.list_buf_top_ptr]	;compute buffer size
  mov	ecx,[edx+list.list_entry_size]	;get entry size
  push	edx				;save control block ptr
  sub	edx,edx
  div	ecx				;compute padding at end of buffer
  mov	ecx,edx				;move pad to ecx
  pop	edx				;restore control block ptr
  mov	esi,[edx+list.list_buf_end_ptr]
  sub	esi,ecx				;remove pad
  sub	esi,[edx+list.list_entry_size]	;move to start of last pkt
got_end_ptr:
  xor	eax,eax			;set success flag
list_check_end_exit:
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
  call	list_check_end

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
	db 0	;padding
buffer_end:

data1	dd	1
	dd	2
	dd	3

  [section .text]
%endif
