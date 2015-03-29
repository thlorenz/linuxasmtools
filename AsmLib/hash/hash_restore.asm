
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
  extern block_read_all
  extern hash_table_ptr
  extern make_hash_pointers
  extern hash_buffer_end
  extern file_length_handle
%include "hash_struc.inc"
;>1 hash
;  hashfile_restore - read open hash file into buffer
; INPUTS
;  ebx = hash file path
;  ecx = buffer
;  edx = buffer length
; OUTPUT
;    eax = bytes read if success, else negative error code
;    [hash_table_ptr] - initialized by hashfile_restore
;          
; OPERATION
;
; NOTES
;    source file: hashfile_restore.asm
;                     
;<
;  * ----------------------------------------------

  global hash_restore
hash_restore:
  mov	[hash_table_ptr],ecx	;save ptr to hash area
  mov	[hash_buffer_end],edx
  add	[hash_buffer_end],ebp	;compute buffer end
  call	block_read_all		;read file
  js	hr_exit			;exit if error
  
  push	eax			;save size read
  mov	ebp,[hash_table_ptr]	;get hash area ptr
;  add	eax,ebp			;compute end of area
;  mov	[ebp+hash.avail_entry_ptr],eax ;save expansion area ptr

  call	make_hash_pointers
  pop	eax			;restore size read
hr_exit:  
  ret


  