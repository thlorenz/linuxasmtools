
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
  extern hash_buffer_end
  extern hash_table_ptr
%include "hash_struc.inc"
;>1 hash
;  hash_add - add entries to hash table
; INPUTS
;  esi = ptr to data entry.
;  note: function hash_setup must be called before
;        using this function.         
; OUTPUT
;    eax = positive if success
;    eax = -1 if out of room
;          
; OPERATION
;    The size of this entry is found and the buffer checked
;    to see if room is available.  If space is available
;    the hash chain is found and the entry added to chain.
;
; NOTES
;    source file: hash_add.asm
;                     
;<
;  * ----------------------------------------------

  global hash_add
hash_add:
  push	ebp
  mov	ebp,[hash_table_ptr]	;get table info ptr
  mov	edi,esi
  add	esi,[ebp+hash.field]	;move to search field
;
; loop to find entry size
;
ha_lp1:
  lodsb
  or	al,al
  jnz	ha_lp1			;loop till end of entry
  sub	esi,edi			;compute size of entry
  mov	ecx,esi			;save size
  add	esi,4			;add in room for chain ptr
  add	esi,[ebp+hash.avail_entry_ptr] ;compute new avail ptr
  cmp	esi,[hash_buffer_end]	;room?
  ja	ha_exit1		;jmp if no room
;
; check if hash index has chain for this entry
;   ecx=size of this entry
;   edi=new entry data ptr
;
  call	compute_hash_tbl_ptr	;hash table ptr
;
; check if hash table chain has any entries
;
ha_lp3:
  mov	ebx,[eax]		;get first chain
  or	ebx,ebx			;check if end of chain
  jz	ha_insert		;jmp if insert point
  mov	eax,ebx
  jmp	short ha_lp3		;loop till end of chain
;
; end of chain found
;  eax = location to store chain ptr
;   ecx=size of this entry
;   edi=new entry data ptr
;
ha_insert:  
  mov	esi,[ebp+hash.avail_entry_ptr]
  mov	[eax],esi		;store ptr to our new entry
;
; move new entry to table
;
  xchg	esi,edi
  xor	eax,eax			;set success flag
  stosd				;put zero chain, we are last entry
  rep	movsb			;move entry to table
  mov	[ebp+hash.avail_entry_ptr],edi ;update next_available_entry_ptr 
ha_exit2:
  jmp	short ha_exit3
ha_exit1:
  mov	eax,-1			;set out of room state
ha_exit3:
  pop	ebp
  ret

;----------------------------------------------------------
  global compute_hash_tbl_ptr
compute_hash_tbl_ptr:
;
; check if hash index has chain for this entry
; inputs:
;   edi=new entry data ptr
;   untouched registers
;       ecx=size of this entry
; output:
;   eax= hash table ptr
;
  xor	eax,eax
  mov	al,[edi]		;get high data byte
  and	al,[ebp+hash.mask]	;mask bits of interest
;
; convert byte hash index to dword index
;
ha_30:
  shl	eax,2
  lea	ebx,[ebp+hash.hash_chain_tbl]	;index into hash table
  add	eax,ebx
  ret

  