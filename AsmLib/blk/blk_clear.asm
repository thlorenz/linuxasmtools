
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
;****f* blk/blk_clear *
; NAME
;>1 blk
;   blk_clear - clear array of bytes
; INPUTS
;    ecx = size of array (byte count)
;    edi = array pointer
;    the CLD flag is set
; OUTPUT
;    ecx = 0
;    edi = unchanged
; NOTES
;    file blk_clear.asm
;    note: see bit_set_list, bit_test, wait_event
;<
;  * ---------------------------------------------------
;*******
  global blk_clear
blk_clear:
  push	eax
  push	edi
  xor	eax,eax
  rep	stosb
  pop	edi
  pop	eax
  ret
