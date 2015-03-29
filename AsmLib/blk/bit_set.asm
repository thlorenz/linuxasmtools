
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
;****f* blk/bit_set *
; NAME
;>1 blk
;bit_set - set bit in array
; INPUTS
;    eax = bit number, zero based
;          eax(0) sets bit 1 (00000001h)
;          eax(32) sets first bit of second dword in array
;    edi = array pointer
; OUTPUT
;    bit set in array
;    eax,edx modified
; NOTES
;    file bit_set.asm
;    note: see bit_test, blk_clear, wait_event
;<
;  * ---------------------------------------------------
;*******
  global bit_set
bit_set:
  mov	edx,eax
  shr	edx,5
  and	eax,1fh
  lea	edx,[edx*4 + edi] 
  bts	[edx],eax
  ret
