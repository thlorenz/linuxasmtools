
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

  extern str_move
  extern work_buf_ptr
  extern database_open
  extern database_close
  extern blk_del_bytes
  extern database_record_size

%include "dbs_struc.inc"

;>1 database
;  database_extract - extract record (cut) and save copy
; INPUTS
;    edi = storage point for new record or zero to delete
;    eax = pointer to index entry for record to extract
;         
; OUTPUT
;    eax = size of record extracted or zero if delete
;        = negative if error, -1=database not open
;    ebp = ptr to database structure
;          
; OPERATION
;    record is copied or deleted.
;    added.  The index list is updated.
;
; NOTES
;    source file: database_extract.asm
;    related functions: database_close, database_extract
;                       database_open, database_search
;                     
;<
;  * ----------------------------------------------
de_error1:
  mov	eax,-1
  jmp	de_exit
;-------------

  global database_extract
database_extract:
  xor	ebx,ebx
  mov	[extract_size],ebx	;clear extract size
  mov	ebp,[work_buf_ptr]
  or	ebp,ebp
  jz	de_error1		;jmp if no database active
;
; save input parameters
;
  mov	[store_ptr],edi
  mov	[target_index],eax
;
; save copy of record if requested
;
  or	edi,edi
  jz	de_20			;jmp if this is pure delete

  call	copy_record
;
; remove the index for this  record
;
de_20:
  call	delete_record
  
de_exit:
  mov	eax,[extract_size]
  ret

;>1 database
;  database_copy_record - copy record to buffer
; INPUTS
;    edi = storage point for new record
;    eax = pointer to index entry for record to copy
;         
; OUTPUT
;    eax = size of record copied
;        = negative if error, -1=database not open
;    ebp = ptr to database structure
;          
; NOTES
;    source file: database_extract.asm
;    related functions: database_close, database_extract
;                       database_open, database_search
;                     
;<
;  * ----------------------------------------------
dc_error1:
  mov	eax,-1
  jmp	dc_exit
;-------------

  global database_copy_record
database_copy_record:
  xor	ebx,ebx
  mov	[extract_size],ebx	;clear extract size
  mov	ebp,[work_buf_ptr]
  or	ebp,ebp
  jz	dc_error1		;jmp if no database active
;
; save input parameters
;
  mov	[store_ptr],edi
  mov	[target_index],eax
  call	copy_record
dc_exit:
  mov	eax,[extract_size]
  ret


;-----------------
  [section .data]

store_ptr:	dd	0		;stuff place for deleted record
target_index	dd	0		;index ptr for record to delete
extract_size	dd	0		;extract size if record copied
  [section .text]

;------------------------------------------------------------------
; inputs:  ebp = database struc ptr
;          eax = ptr to record index entry
;          [store_ptr] - destination for record
;
; output: none
copy_record:
;
; save copy of target record
;
  mov	edi,eax
  call	database_record_size	;returns size in edx
;
; remove separator size, from record size
;
  xor	ecx,ecx
  mov	cl,[ebp+dbs.db_separation] ;get size of separator string
  neg	ecx
  add	ecx,edx			;compute new size
  mov	[extract_size],ecx
  mov	esi,[edi]		;get ptr to start of record
  mov	edi,[store_ptr]
  rep	movsb			;move data
  ret

;------------------------------------------------------------
; input: ebp = database structure ptr
;        [target_index] = ptr to index entry to delete
;
delete_record:
  push	ebp
  mov	eax,4			;number of bytes to delete
  mov	edi,[target_index]	;get delete point
  mov	ebp,[ebp+dbs.db_index_end] ;get end of index
  call	blk_del_bytes
  pop	eax			;restore struc ptr
;
; adjust index end point
;
  mov	[eax+dbs.db_index_end],ebp
  xor	ebx,ebx
  mov	[ebp],ebx		;put zero at end of index list
;
; update index end ptr
;
  mov	ebx,ebp			;save index end point
  mov	ebp,eax			;set ebp to struc ptr
  mov	[ebp+dbs.db_index_end],ebx ;save new index end point
  ret

  