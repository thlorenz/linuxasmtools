
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
;  extern block_seek
  extern block_write_all
  extern hash_table_ptr
%include "hash_struc.inc"
;>1 hash
;  hashfile_archive - write current hash data to open file
; INPUTS
;    ebx = hashfile name path
;    [hash_table_ptr] - set by hashfile_setup or
;                       hashfile_restore
; OUTPUT
;    eax=0 if success, else negative error code
;          
; OPERATION
;    First the hash file internal pointers are converted
;    to offsets relative to top of hash table.  The file
;    is then written to disk as a relocatable data file.
;    Finally, the in memory hash file is modfied and the
;    offsets changed back to pointers
;
; NOTES
;    source file: hashfile_archive.asm
;                     
;<
;  * ----------------------------------------------

  global hash_archive
hash_archive:
  push	ebp
  push	ebx				;save file name ptr
  mov	ebp,[hash_table_ptr]		;get hash area pointer
  call	make_hash_offsets

  pop	ebx				;get file path
  mov	ecx,[hash_table_ptr]		;get ptr to hash area
  mov	esi,[ecx+hash.avail_entry_ptr]	;get size of hash table
  xor	edx,edx				;set default permissions
  call	block_write_all
ha_exit:
  mov	ebp,[hash_table_ptr]		;get ptr to hash area
  call	make_hash_pointers
ha_exit2:
  pop	ebp
  ret

;---------------------------------------------------
;    ebp - ponter to hash area
 global make_hash_offsets
make_hash_offsets:
  lea	eax,[ebp+hash.hash_chain_tbl] ;get ptr to chain pointers
  sub	eax,4
hl_lp2:
  add	eax,4
  cmp	eax,[ebp+hash.entries_ptr] ;end of chain ptr table?
  je	hl_done			;exit if done
  mov	esi,[eax]
  or	esi,esi
  jz	hl_lp2			;jmp if empty chain
  sub	[eax],ebp		;convert to offset  
;
; we have found a chain with data
;
  push	eax
hl_lp3:
  mov	eax,[esi]		;get next chain ptr
  or	eax,eax
  jz	hl_lpend		;jmp if no more chains for this entry
  sub	[esi],ebp		;convert to offset
  mov	esi,eax  
  jmp	short hl_lp3
hl_lpend:
  pop	eax
  jmp	short hl_lp2
hl_done:
  sub	[ebp+hash.entries_ptr],ebp
  sub	[ebp+hash.avail_entry_ptr],ebp
  ret
;---------------------------------------------------
;    ebp - ponter to hash area
 global make_hash_pointers
make_hash_pointers:
  add	[ebp+hash.entries_ptr],ebp
  add	[ebp+hash.avail_entry_ptr],ebp
  lea	eax,[ebp+hash.hash_chain_tbl] ;point to top of table
  sub	eax,4
hl_lp4:
  add	eax,4
  cmp	eax,[ebp+hash.entries_ptr] ;end of  chain ponter table?
  je	hl_dn			;exit if done
  mov	esi,[eax]
  or	esi,esi
  jz	hl_lp4			;jmp if empty chain
  add	[eax],ebp		;convert to pointer
  add	esi,ebp
;
; we have found a chain with data
;
  push	eax
hl_lp5:
  mov	eax,[esi]		;get next chain ptr
  or	eax,eax
  jz	hl_lpnd			;jmp if no more chains for this entry
  add	[esi],ebp		;convert to offset  
  add	eax,ebp
  mov	esi,eax
  jmp	short hl_lp5
hl_lpnd:
  pop	eax
  jmp	short hl_lp4
hl_dn:
  ret
;----------------



  