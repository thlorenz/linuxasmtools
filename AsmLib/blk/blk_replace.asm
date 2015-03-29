
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
  extern blk_find
  extern str_len
  extern blk_del_bytes
  extern blk_insert_bytes

  [section .text]

;****f* blk/blk_replace *
;
; NAME
;>1 blk
;  blk_replace - replace first match in buffer
; INPUTS
;    eax = ptr to replacement string
;    ch  = search case mask, dfh=ignore 0ffh=use case
;    esi = match string ptr
;    edi = buffer search startng point
;    ebp = eof (end of data in buffer)
; OUTPUT
;    carry flag set if no replacement occured
;    ebp = adusted file end ptr if any replaces occured
;    edi = ptr to end of inserted string
; NOTES
;   all registers are destroyed
;   file blk_replace.asm
;   This function is being depreciated, use
;   blk_freplace instead.
;<
; * ---------------------------------------------
;*******
  global blk_replace
blk_replace:
  mov	[srch_start_ptr],edi
  mov	[replace_str_ptr],eax
  mov	[case_mask],ch
  mov	[match_str_ptr],esi
  mov	[buf_end],ebp
  call	str_len			;get match str length
  mov	[match_str_len],ecx
  xchg	esi,eax
  call	str_len
  mov	[replace_str_len],ecx
  mov	esi,eax			;restore match str ptr

br_entry:
  mov	ch,[case_mask]
  mov	edx,1			;set forward search
  call	blk_find		;look for match
  jc	br_exit			;exit if no match
;
; ebx = match point
;
  mov	[match_ptr],ebx		;save match point
;
; remove match string from buffer
;
  mov	eax,[match_str_len]
  mov	edi,ebx			;ptr to match str
;;  mov	ebp,[buf_end]
  call	blk_del_bytes		;remove match string
;
; make hole and insert replace string
;
  mov	edi,[match_ptr]
; ebp = end of buffer
  mov	eax,[replace_str_len]
  mov	esi,[replace_str_ptr]
  call	blk_insert_bytes
  add	edi,[replace_str_len]   ;adjust edi to end of replace string
  clc				;indicate replace occured 
br_exit:	
  ret

;****f* blk/blk_replace_all *
;
; NAME
;>1 blk
;  blk_replace_all - replace all matches in buffer
; INPUTS
;    eax = ptr to replacement string
;    ch  = search case mask, dfh=ignore 0ffh=use case
;    esi = match string ptr
;    edi = buffer search startng point
;    ebp = eof (end of data in buffer)
; OUTPUT
;    ebp = adusted file end ptr if any replaces occured
;    edi = ptr to end of inserted string
; NOTES
;    all registers destroyed
;    file blk_replace.asm
;   This function is being depreciated, use
;   blk_freplace_all instead.
;<
;  * ----------------------------------------------
;*******
  global blk_replace_all
blk_replace_all:
  call	blk_replace
  jc	bra_exit		;jmp if no replaces occured
;
; setup to do another replace
;
bra_again:
  mov	eax,[replace_str_ptr]
  mov	esi,[match_str_ptr]
  call	br_entry		;go do another replace
  jnc	bra_again		;jmp if replace found
bra_exit:
  ret
		

  [section .data]
buf_end		dd	0
match_str_ptr	dd	0	;asciiz string
replace_str_ptr dd	0	;asciiz string
case_mask	db	0
srch_start_ptr	dd	0

match_str_len	dd	0
replace_str_len	dd	0
match_ptr	dd	0
  [section .text]
