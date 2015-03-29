
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

  extern block_open_write
  extern block_write
  extern block_close
  extern str_move
  extern work_buf_ptr
  extern database_record_size

%include "dbs_struc.inc"

;>1 database
;  database_close - close currently active database
; INPUTS
;    none
;         
; OUTPUT
;    eax = program status:
;          positive indicates file written to disk
;          negative values = error return codes.
;                            -1=a database isn't open
;          sign bit is set for js/jns instructions
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
;    The records are written to disk is same order they
;    appear in index.
;
; NOTES
;    source file: database_close.asm
;    related functions: database_close, database_extract
;                       database_insert, database_search
;                     
;<
;  * ----------------------------------------------
dc_error1:
  mov	eax,-1
  jmp	dc_exit


  global database_close
database_close:
  mov	ebp,[work_buf_ptr]
  or	ebp,ebp
  jz	dc_error1		;jmp if no database active
;
; read the data file into work buffer, ebx = path ptr
; if file does not exist, it will be created.
;
  lea	ebx,[ebp+dbs.db_path]	;get path
  xor	edx,edx			;default permissions
  call	block_open_write
  js	dc_exit			;exit if error
;
; write each record to file
;
  mov	ebx,eax			;get file handle to ebx
  mov	edi,[ebp+dbs.db_index]	;get ptr to index list
dc_write_lp:
  cmp	edi,[ebp+dbs.db_index_end];check if done
  jae	dc_20			;jmp if all records written
;
; compute next record size, edi=index ptr
;
  call	database_record_size	;returns size in edx
;
; write the next record, esi=ptr to index, edx=size  ebx=file handle
;
  mov	ecx,[edi]		;get next record ptr
  call	block_write
  js	dc_exit			;exit with error in eax
;
; move to next record
;
  add	edi,4
  jmp	short dc_write_lp
;
; all records have been  written, close the database
;
dc_20:
  call	block_close

; exit with eax=0
    
dc_exit:
  or	eax,eax
  mov	[work_buf_ptr],eax	;set database inactive
  ret


  