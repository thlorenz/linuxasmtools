
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
;****f* blk/bit_test *
; NAME
;>1 blk
;   bit_test - test array of bits
; INPUTS
;    eax = bit number
;          (0=bit 1) or 00000001h
;    edi = bit array pointer
; OUTPUT
;    carry = bit set
;    no-carry = bit cleared
;    registers unchanged
; NOTES
;    file bit_test.asm
;    note: see bit_set_list, blk_clear, wait_event
;<
;  * ---------------------------------------------------
;*******
  global bit_test
bit_test:
  push	edx
  mov	edx,eax
  shr	edx,5
  lea	edx,[edx*4 + edi]
  and	eax,1fh
  bt	dword [edx],eax	;check bit
  pop	edx
  ret
;------------------------------
