
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
%include "hash_struc.inc"

;>1 hash
;  hash_lookup - search data entries for match
; INPUTS
;   edi = ptr to search string
;   ecx = search match size
;         if string set ecx negative (checks for zero termination)
;   edx = search offset into table entry.
;         note: The hash is computed for byte zero of each
;         table entry.  if edx is non zero we can not
;         use the computed hash, and a non-hash lookup
;         is used.  This will be slower because every
;         entry will be searched, starting at top of table.          
; OUTPUT
;   eax=0 if success, -1 if failure to match
;   esi=ptr to match entry if eax=0
;          
; OPERATION
;
; NOTES
;    source file: hash_lookup.asm
;                     
;<
;  * ----------------------------------------------

  global hash_lookup
hash_lookup:
  mov	[string_flag],ecx
  or	ecx,ecx
  jns	hl_10
  neg	ecx  
hl_10:
  push	ebp
  mov	ebp,[hash_table_ptr]
  mov	[match_str],edi
  mov	[match_str_size],ecx
  mov	[match_offset],edx
  or	edx,edx			;check if we can do a hash lookup
  jnz	hl_full_search		;jmp if no hash lookup needed
;
;get hash entry
;
  call	compute_hash_tbl_ptr	;sets eax=hash table ptr
;
; get chain to next entry
;
  call	search_chain
  jmp	short hl_exit
;
; do a full table search
;
hl_full_search:
  lea	eax,[ebp+hash.hash_chain_tbl]	;point to top of table
  sub	eax,4
hl_lp2:
  add	eax,4
  cmp	eax,[ebp+hash.entries_ptr] ;check if at end of pointers
  je	hl_fail			;exit if no match
  mov	esi,[eax]
  or	esi,esi
  jz	hl_lp2			;jmp if empty chain
;
; we have found a chain with data, search it
;
  push	eax
  call	search_chain		;search the chain
  or	eax,eax
  pop	eax
  jnz	hl_lp2			;loop if no match
hl_exit1:
  xor	eax,eax
  jmp	short hl_exit		;exit if match found

hl_fail:
  mov	eax,-1  
hl_exit:
  pop	ebp
  ret
;----------------
  [section .data]
string_flag: dd 0
  [section .text]

;-----------------------------------------------------------------------
; search one hash chain.
;  input:  eax=chain ptr
; output:  eax=0 if match, else -1
;          esi=match entry if eax=0
;
search_chain:			;entry from full table search calls here
hl_lp1:
  mov	esi,[eax]		;get next chain ptr
  mov	[previous_chain],eax	;save previous chain for hash_remove function
  or	esi,esi
  jnz	hl_srch			;jmp if table has chain for this entry
  mov	eax,-1
  jmp	short sc_exit		;exit if no match found
;
; we have found a hash chain
;
hl_srch:
  mov	eax,esi			;save ptr to chain
  add	esi,4			;move to data entry
  add	esi,[match_offset]
  mov	edi,[match_str]
  mov	ecx,[match_str_size]
  repe	cmpsb			;compare
  jne	hl_lp1			;jmp if not equal
  mov	ecx,[string_flag]
  or	ecx,ecx
  jns	hl_match		;jmp if not zero terminated string
  cmp	byte [esi],0		;end of symbol
  jne	hl_lp1
;
; match found, set esi to match entry
;
hl_match:
  mov	esi,eax
  add	esi,4			;move to start of entry
  xor	eax,eax			;set success flag
sc_exit:
  ret



;----------------------
  [section .data]
 global match_str,match_str_size,match_offset
match_str:	dd	0
match_str_size	dd	0
match_offset	dd	0
 global previous_chain
previous_chain: dd	0	;used by hash_remove to rechain
  [section .text]

  