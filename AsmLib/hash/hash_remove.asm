
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
  extern hash_lookup
  extern previous_chain

;>1 hash
;  hash_remove - remove one entry from data set
; INPUTS
;   edi = ptr to search string
;   ecx = search match size
;         set ecx negative if string (zero termination checked)
;   edx = search offset into entry (0=first byte compared)
;         note: if edx is non zero a non-hash lookup
;         is used.  This will be slower because every
;         entry will be searched, starting at top of table.          
;         
; OUTPUT
;    eax = 0 if successful
; OPERATION
;    hash_remove does not reclaim memory and should not
;    be used if numerous deletes are needed.  If the data
;    is written to disk it will retain the hole left
;    by removed entries.
;
; NOTES
;    source file: hash_remove.asm
;                     
;<
;  * ----------------------------------------------

  global hash_remove
hash_remove:
  call	hash_lookup
  or	eax,eax
  jnz	hr_exit		;exit if remove failed
  mov	ebx,[previous_chain]
;
; esi points at match entry, move back to chain
;
  sub	esi,4		;move back to chain pointer
  mov	eax,[esi]	;get ptr to next entry
  mov	[ebx],eax	;rechain
hr_exit:
  ret


  