
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
; ----------- file hash_setup.asm ----------------
%include "hash_struc.inc"
;>1 hash
;  hash_setup - prepare hash table for use
;    Hash tables are used for fast access to data.
;    Tables of symbols or other ascii strings can
;    be hashed or other data groups.
;    hash_setup is called once at the beginning
;    of a program.
;
; INPUTS
;    edi = ptr to start of buffer area. (holds data and hash)
;    ecx = end of buffer ptr (beyond last available location)
;     al = hash mask 01h,03h,07h,0fh,1fh,3fh,7fh,0ffh
;    ebx = minimum hash entry size, search for
;          zero at end of entry begins at start+ebx
;
;    note: It is possible to hash complex records or fixed
;          or variable length.  The only constraints are
;          that variable data be at the end and not contain
;          any zeros.  To include data with zero bytes, put
;          it at the front of a entry and set -ebx- to skip
;          over it.  Another constraint is that the first
;          byte is used as a hash key.  This works for
;          symbol tables where the address is first but may
;          not work with other data sets.          
; OUTPUT
;    global variables [hash_table_ptr] used internally
;                     [hash_buffer_end] used internally
;          
; OPERATION
;    The hash pointers are set to zero and table pointer
;    saved for other functions.  Only one hash table can
;    be in use so only one pointer is kept.  The hash table
;    is followed by data entries and they must be
;    included in the buffer size.  The entries are assumed
;    to be terminated by a zero byte.  The search for an
;    entry end begins at the minimum entry size and continues
;    until a zero byte is found.
;
;    A typical symbol table entry could be constructed
;    as:
;        dd <adr>  ;address of symbol
;        db <string> ;ascii label
;        db 0        ;end of label
;
;    The hash functions add a chain dword to front of
;    each entry, but this isn't usually of interest to
;    users.  Internally, a hash pointer table is built
;    which points to chains of data entries.
;
;    The first byte of a hash entry is used as the
;    hash key.  A hash ponter table will require 2
;    dwords if a mask of 01h is used. (see table below)
;
;    To avoid huge hash tables it is a good idea to choose
;    a mask with few bits set.  The legal mask values are:
;    0ffh,07fh,03fh,01fh,0fh,07h,03h,01h
;
;    The buffer size provided to hash functions needs to
;    hold the hash table and all the data entries.  Each
;    data entry has an additional 4 bytes added for the
;    chain.  The hash table size can be found from the
;    following table:
;
;    hash      table-size  
;    mask      (bytes)     
;    -------   ------------
;      01h      8          
;      03h      16         
;      07h      32         
;      0fh      64         
;      1fh      128        
;      3fh      256        
;      7fh      512        
;      ffh      1024       
;
;   To  create a in memory hash database use:
;        hash_setup - create structures
;        hash_add   - add entries
;        hash_remove - remove entries
;        hash_lookup - find entries
;
;   To  write a in memory hash database to file:
;        hash_archive -  write data to file
;
;   To  read a hash file into memory use:
;        hash_restore - open,read,setup hash,close
;
; NOTES
;    source file: hash_setup.asm
;                     
;<
;  * ----------------------------------------------

  global hash_setup
hash_setup:
  mov	[hash_table_ptr],edi	;save buffer pointer
  mov	[hash_buffer_end],ecx	;save buffer end
;
; clear the hash table buffer
;
  push	edi
  push	eax
  push	ebx
  sub	ecx,edi			;compute buffer size
  xor	eax,eax			;clear eax
  rep	stosb			;clear
  pop	ebx
  pop	eax
  pop	edi
;
  mov	[edi+hash.mask],al	;save mask
  mov	[edi+hash.field],ebx	;save eor search start field
;
;compute start of entries
;
  xor	eax,eax
  mov	al,[edi+hash.mask]	;get mask to compute ptr table size
  inc	eax			;add in an extra dword
  shl	eax,2			;convert to dword count
  add	eax,hash.hash_chain_tbl	;add in start of chain table
  add	eax,edi			;add in hash area start
  mov	dword [edi+hash.avail_entry_ptr],eax
  mov	dword [edi+hash.entries_ptr],eax
  ret

;-------------------
  [section .data]
 global hash_table_ptr
hash_table_ptr:	 dd	0	;ptr to top of buffer
 global hash_buffer_end
hash_buffer_end: dd	0	;ptr to end of buffer
  [section .text]
;-------------------
  