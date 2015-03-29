
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
  [section .text]
  extern work_buf_ptr
  extern database_record_size
  extern blk_find

%include "dbs_struc.inc"

;>1 database
;  database_search - scan the database for string
; INPUTS
;    edi = ptr to index entry for start of search
;          or if eax=0 start search at top of index.
;    esi = search string in asciiz format.
;         
; OUTPUT
;    eax = -1 if no database active
;          -2 if no match
;           0 if success
;          sign bit is set for js/jns jump
;    edi = ptr to index entry with match
;    ebp = ptr to database structure
;          
; NOTES
;    source file: database_search.asm
;    related functions: database_close, database_extract
;                       database_open, database_search
;                     
;<
;----------------------------------------------------------
;
ds_error1:
  mov	eax,-1
  jmp	ds_exit

  global database_search
database_search:
  mov	ebp,[work_buf_ptr]
  or	ebp,ebp
  jz	ds_error1		;jmp if no database active
;
; save input parameters
;
  mov	[search_index],edi	;save ptr to index entry
  mov	[match_string],esi	;save ptr to asciiz match string

ds_loop:
  cmp	dword [edi],0		;end of list?
  jz	no_match		;jmp if end found
  push	edi			;save index ptr
;
; database_record_size setup edi= ptr to index entry
;                            ebp= ptr to database structure
  mov	ebp,[work_buf_ptr]
  call	database_record_size	;find size of this record -> edx
  mov	ebp,[edi]		;get ptr to record text
  mov	edi,ebp			;set edi = record text
  add	ebp,edx			;compute record end point -> ebp
  mov	esi,[match_string]
  mov	edx,1			;set forward search flag
  mov	ch,0ffh			;set use case flag
;
; blk_find setup ebp=end of record
;                esi=match string
;                edi=search starting point
;                edx=direction +1 or -1
;                ch = mask, ff=match case df=ignore case
;         output: ebx=match ptr if no carry, jnc match_found
;
  call	blk_find
  pop	edi			;restore index ptr
  jnc	match_found		;jmp if success
  add	edi,4
  jmp	short ds_loop		;keep looking

no_match:
  mov	eax,-2
  jmp	short ds_exit
match_found:
  xor	eax,eax			;signal success
ds_exit:
  mov	ebp,[work_buf_ptr]
  or	eax,eax			;set sign bit
  ret

;----------------
  [section .data]
search_index	dd	0
match_string	dd	0	;ptr to match string