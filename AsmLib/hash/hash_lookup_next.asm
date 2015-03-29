
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
  extern compute_hash_tbl_ptr
  extern hash_table_ptr
  extern previous_chain
  extern match_str,match_str_size,match_offset,string_flag
%include "hash_struc.inc"

;>1 hash
;  hash_lookup_next - search for another match
; INPUTS
;   esi = ptr to last match          
; OUTPUT
;   eax=0 if success, -1 if failure to match
;   esi=ptr to match entry if eax=0
;          
; OPERATION
;   The hash chains are not sorted, so to find duplicate
;   entries this functions is used.
; NOTES
;    source file: hash_lookup.asm
;                     
;<
;  * ----------------------------------------------

  global hash_lookup_next
hash_lookup_next:
  push	ebp
  mov	edx,[match_offset]
  or	edx,edx			;check if we can do a hash lookup
  jnz	hln_full_search		;jmp if no hash lookup needed
;
;get hash entry
;
  mov	eax,esi			;sets eax=hash table ptr
  sub	eax,4			;move back to chain
;
; get chain to next entry
;
  call	search_chain_
  jmp	short hln_exit
;
; do a full table search
;
hln_full_search:
  mov	eax,esi
  sub	eax,8
hln_lp2:
  add	eax,4
  cmp	eax,[ebp+hash.entries_ptr] ;check if at end of pointers
  je	hln_fail			;exit if no match
  mov	esi,[eax]
  jz	hln_lp2			;jmp if empty chain
;
; we have found a chain with data, search it
;
  push	eax
  call	search_chain_		;search the chain
  or	eax,eax
  pop	eax
  jnz	hln_lp2			;loop if no match
  xor	eax,eax
  jmp	short hln_exit		;exit if match found

hln_fail:
  mov	eax,-1  
hln_exit:
  pop	ebp
  ret

;-----------------------------------------------------------------------
; search one hash chain.
;  input:  eax=chain ptr
; output:  eax=0 if match, else -1
;          esi=match entry if eax=0
;
search_chain_:			;entry from full table search calls here
hln_lp1:
  mov	esi,[eax]		;get next chain ptr
  mov	[previous_chain],eax	;save previous chain for hash_remove function
  or	esi,esi
  jnz	hln_srch			;jmp if table has chain for this entry
  mov	eax,-1
  jmp	short sc_exit_		;exit if no match found
;
; we have found a hash chain
;
hln_srch:
  mov	eax,esi			;save ptr to chain
  add	esi,4			;move to data entry
  add	esi,[match_offset]
  mov	edi,[match_str]
  mov	ecx,[match_str_size]
  repe	cmpsb			;compare
  jne	hln_lp1			;jmp if not equal
  mov	ecx,[string_flag]
  or	ecx,ecx
  jns	hln_match		;jmp if not zero terminated string
  cmp	byte [esi],0		;end of symbol
  jne	hln_lp1			;jmp if not equal
;
; match found, set esi to match entry
;
hln_match:
  mov	esi,eax
  add	esi,4			;move to start of entry
  xor	eax,eax			;set success flag
sc_exit_:
  ret


  