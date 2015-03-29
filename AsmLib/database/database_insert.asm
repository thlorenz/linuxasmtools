
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

%include "dbs_struc.inc"

;>1 database
;  database_insert - insert record into open database
; INPUTS
;    esi = pointer to record
;    ecx = size of record without separation characters
;          used in database, we will append separation chars.
;    al=0 to  append, al=1 to  insert alphabetically.
;         
; OUTPUT
;    eax = positive if success
;          negative if error, -1=no database active
;          sign bit is set for js/jns instructions.
;    ebp = ptr to database structure
;          
; OPERATION
;    record is copied to database and separation characters
;    added.  The index list is updated.
;
; NOTES
;    source file: database_insert.asm
;    related functions: database_close, database_extract
;                       database_open, database_search
;                     
;<
;  * ----------------------------------------------
di_error1:
  mov	eax,-1
  jmp	di_exit
;-------------

  global database_insert
database_insert:
  mov	ebp,[work_buf_ptr]
  or	ebp,ebp
  jz	di_error1		;jmp if no database active
;
; save input parameters
;
  mov	[insert_text],esi
  mov	[insert_size],ecx
  mov	[insert_type],al	
;
; check if room to add another record
;
  mov	edi,[ebp+dbs.db_index_end]	;get end of index's
  mov	eax,[ebp+dbs.db_append]		;get append address
  sub	eax,4				;move up into index area
  cmp	edi,eax                         ;are we at end of index
  jb	di_20				;jmp if room for another index
;
; we are out of room, close the database and reopen it
;
  call	database_close			;write out current changes
  js	di_exitj
  mov	esi,[ebp+dbs.db_path]		;get path ptr
  mov	edi,[ebp+dbs.db_separation]	;get separator string ptr
  call	database_open
  js	di_exit
;
; move record to append area
;
di_20:
  mov	edi,[ebp+dbs.db_append_end]
  mov	[inserted_record_ptr],edi	;save for later
  mov	esi,[insert_text]
  mov	ecx,[insert_size]
  rep	movsb
  mov	cl,[ebp+dbs.db_separation]	;get separation char. count
  lea	esi,[ebp+dbs.db_separation+1]	;point at first separation char
  rep	movsb				;move separators
;
; update pointers for stored record
;
  mov	[ebp+dbs.db_append_end],edi	;update store point for next record
;
; check type of insert
;
  cmp	byte [insert_type],0
  jne	di_alpha			;jmp if alpabatize
;
; append this record at end, eax=ptr to our new record
;
  mov	edi,[ebp+dbs.db_index_end]	;get ptr to end of index
  mov	eax,[inserted_record_ptr]
  stosd					;store pointer to inserted record
  mov	[ebp+dbs.db_index_end],edi	;update index end
  xor	eax,eax
  stosd					;put zero index next
di_exitj:
  jmp	short di_exit
;
; append this record alphabetically
;
di_alpha:
  mov	eax,[insert_text]
  mov	ebx,[ebp+dbs.db_index]		;get index ptr
di_lp2:
  mov	esi,[ebx]			;get ptr to next string
  or	esi,esi				;end of index?
  je	di_here				;jmp if end of index
  mov	edi,eax				;get ptr to insert string
  mov	ecx,[insert_size]
  repe	cmpsb				;compare the two strings
  ja	di_here				;jmp if insert point found
  add	ebx,4				;move to next record
  jmp	di_lp2				;
;
; insert index at [ebx], could be at end or beginning
;
di_here:
  mov	eax,[inserted_record_ptr]
di_lp3:
  xchg	eax,[ebx]
  add	ebx,4				;move to next index
  or	eax,eax				;was last record at end
  jnz	di_lp3				;loop till end of index
  mov	[ebx],eax			;put zero at end of index
  mov	[ebp+dbs.db_index_end],ebx
di_exit:
  or	eax,eax
  ret

;-----------------
  [section .data]

insert_text:	dd	0		;ptr to record in callers buffer.
insert_size	dd	0		;size of insert record (excluding separators)
insert_type	db	0		;0=append 1=insert
inserted_record_ptr dd	0		;ptr to record in our buffer

  [section .text]


  