
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

%include "dbs_struc.inc"

;>1 database
;  database_record_size - compute size of record in database
; INPUTS
;    edi = ptr to index entry for target record
;    ebp = database structure pointer
;         
; OUTPUT
;    edx = size of record
;    ebx,ebp unchanged
;          
; NOTES
;    source file: database_record_size.asm
;    related functions: database_close, database_extract
;                       database_open, database_search
;                     
;<
;----------------------------------------------------------
; input: edi=index ptr
;        ebp=structure ptr
;        ebx=file handle
;
; output: edx=record size
;
  global database_record_size
database_record_size:
  mov	esi,[edi]			;get ptr to start of record
  mov	edx,esi				;save record start
crs_restart_lp:
  mov	ah,[ebp+dbs.db_separation+1]	;get first separation char
crs_lp:
  lodsb
  cmp	al,ah
  jne	crs_lp				;loop till separation char found
  cmp	byte [ebp+dbs.db_separation],1	;only 1 separation char?
  je	crs_done			;jmp if only one separation char
;
; do we have more than one separation char?
;
crs_match1:
  mov	ah,[ebp+dbs.db_separation+2]    ;get second separaton char
  lodsb
  cmp	al,ah
  je	crs_match2			;jmp if second char matched
  dec	esi
  jmp	short crs_restart_lp		;loop if no match
;
; we have matched two separation chars, is there a third?
;
crs_match2:
  cmp	byte [ebp+dbs.db_separation],2
  je	crs_done			;jmp if only two separation chars.

  mov	ah,[ebp+dbs.db_separation+3]    ;get third separaton char
  lodsb
  cmp	al,ah
  je	crs_done			;jmp if third char. matched
  sub	esi,2
  jmp	short crs_restart_lp		;loop back and retry
;
; we have found the record end, compute the record size
;
crs_done:
  sub	esi,edx				;end-start
  mov	edx,esi				;delta to edx
  ret

