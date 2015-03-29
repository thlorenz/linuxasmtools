
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

;----------------------
;****f* blk/bit_set_list *
; NAME
;>1 blk
;bit_set_list - set bits in array
; INPUTS
;    esi = pointer to list of dword bit values
;          0 = bit 1 or 00000001h
;          -1 = end of list
;          values in increasing order
;    edi = array pointer
; OUTPUT
;    bits set in array
;    esi moved to end of list, beyond -1 entry
; NOTES
;    file bit_set_list.asm
;    note: see bit_test, blk_clear, wait_event
;<
;  * ---------------------------------------------------
;*******
  global bit_set_list
bit_set_list:
  push	edx
  push	eax
sa_loop:
  lodsd			;get bit value
  or	eax,eax
  js	sa_exit		;exit if done (end of list)
  mov	edx,eax
  shr	edx,5
  and	eax,1fh
  lea	edx,[edx*4 + edi] 
  bts	[edx],eax
  jmp	short sa_loop	;loop
sa_exit:
  pop	eax
  pop	edx
  ret
;------------------------------
