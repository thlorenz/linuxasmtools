
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

  extern block_open_update
  extern block_read
  extern block_close
  extern str_move

%include "dbs_struc.inc"

;>1 database
;  database_open - open or create a database file
;    The database remains in memory until the
;    database_close function is called.  While in
;    memory the database insert, extract, search,
;    etc. functions can be used.
;
; INPUTS
;    esi = pointer to database path string.
;          Path string is terminated by zero byte.
;    edi = pointer to record separator string.
;          The first byte is size of string.
;          The max size is 4 bytes including size.
;    ebp = pointer to work buffer.  Size must be
;          large enough to hold database file, 
;          index list, some record keeping, and 
;          appended records.  Size is not checked,
;          but after "database_open" the 'db' structure
;          has sufficient information to do a error
;          check.
;         
; OUTPUT
;    eax = program status:
;          zero indicates the work buffer is setup
;          negative values = error return codes.
;                            -1=a database is open already
;          sign bit is set for js/jns         
;    ebp points to work buffer, first entry is the
;          'db' structure as follows:
;        struc db
;         .db_records resd 1 ;pointer to record area
;         .db_index resd 1 ;pointer to index area
;         .db_index_end resd 1 ;pointer to zero at end of index
;                                can expand to db_append
;         .db_append resd 1 ;pointer to appended record area
;         .db_append_end  resd 1 ;pointer to start of free space.
;         .db_path resb 200 ;copy of file path
;         .db_separation resb 4 ;size followed by separation string
;         .db_end  resd 6 ;copy of record separator codes,
;                                first byte is length of codes.
;        endstruc
;          
; OPERATION
;    The database function is suitable for small lists
;    which need to be updated easily and then stored in
;    a file.
;    Records are separated by a unique code which can
;    not appear with the data itself.  The code is
;    determined by caller.
;    Initially, records are read and indexed by a
;    list of pointers to the records.  The pointers
;    can be sorted by caller or the "insert" function
;    has an option to insert alphabetically.
;    The format of each record is determined by the
;    caller, but sorted databases may want the
;    sort field first.    
; NOTES
;    source file: database_open.asm
;    related functions: database_close, database_extract
;                       database_insert, database_search
;                     
;<
;  * ----------------------------------------------
do_error1:
  mov	eax,-1
  jmp	do_exit
;*******

  global database_open
database_open:
  cmp	dword [work_buf_ptr],0
  jnz	do_error1		;jmp if database already active
  mov	[work_buf_ptr],ebp

  mov	eax,[edi]		;get separator string
  mov	[ebp+dbs.db_separation],eax

  lea	edi,[ebp+dbs.db_path]
  mov	ebx,edi			;save copy of path ptr
  call	str_move		;save path
;
; read the data file into work buffer, ebx = path ptr
; if file does not exist, it will be created.
;
  call	block_open_update
  js	do_exit			;exit if error
  mov	ebx,eax			;get fd (file handle)
  lea	ecx,[ebp+dbs.db_rec_start]
  mov	[ebp+dbs.db_records],ecx ;save ptr to start of records
  mov	edx,100000		;max buffer size
  call	block_read
  js	do_exit			;exit with error in eax
  push	eax			;save read size
  call	block_close
  pop	eax
;
; setup pointers in structure
;
  mov	edi,[ebp+dbs.db_records]
  mov	esi,edi			;save copy of records ptr
  add	edi,eax			;add file size
  mov	[ebp+dbs.db_index],edi	;store ptr to index
;
; index the records, edi = ptr to index store location
;                    esi = ptr to records read from file
iloop:
  cmp	esi,[ebp+dbs.db_index]	;check if eof found
  jae	index_complete
  mov	eax,esi
  stosd				;store index
  call	find_record_end
  jmp	short iloop
;
;the index has been stored, terminate it
;
index_complete:
  mov	[ebp+dbs.db_index_end],edi
  xor	eax,eax
  stosd

  add	edi,4*10		;make room for 10 new index's
  mov	[ebp+dbs.db_append],edi	;start append records here
  mov	[ebp+dbs.db_append_end],edi	;free space at end of appends

; exit with eax=0
    
do_exit:
  or	eax,eax
  jns	do_exit2		;jmp if no errors
  mov	dword [work_buf_ptr],0	;disable this database table
do_exit2:
  ret

;----------------------------------------------------------
; input: edi=index ptr
;        ebp=structure ptr
;        ebx=file handle
;        esi=ptr to record start
; output: esi=ptr to next record
;
find_record_end:
  mov	ah,[ebp+dbs.db_separation+1]	;get first separation char
fre_lp:
  lodsb
  cmp	al,ah
  jne	fre_lp				;loop till separation char found
  cmp	byte [ebp+dbs.db_separation],1	;only 1 separation char?
  je	fre_done			;jmp if only one separation char
;
; do we have more than one separation char?
;
  mov	ah,[ebp+dbs.db_separation+2]    ;get second separaton char
  lodsb
  cmp	al,ah
  je	fre_match2			;jmp if second separation matched
  dec	esi
  jmp	short find_record_end		;restart search
;
; we have matched two separation chars, is there a third?
;
fre_match2:
  cmp	byte [ebp+dbs.db_separation],2
  je	fre_done			;jmp if only two separation chars.

  mov	ah,[ebp+dbs.db_separation+3]    ;get third separaton char
  lodsb
  cmp	al,ah
  je	fre_done			;jmp if last separation matched
  sub	esi,2
  jmp	short find_record_end		;restart search
;
; we have found the record end, compute the record size
;
fre_done:
  ret


;-------------
  [section .data]
  global work_buf_ptr
work_buf_ptr:  dd	0
  [section .text]
