
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
;
;record database
  [section .data]
 global record_base_ptr,free_record_offset,buffer_end_offset
record_base_ptr	    dd	0	;start of data
free_record_offset  dd	0
buffer_end_offset   dd	0
record_size	    dd	0	;excluding the chain and key dwords
  [section .text]
;----------------------------------------------------
;>1 hash
;  record_setup - prepare record table for use
;    Hash tables are used for fast access to data.
;    record_setup is called once at the beginning
;    of a program.
;
; INPUTS
;    edi = ptr to start of buffer area. (holds data and record)
;    ecx = buffer size
;    eax = record size
;
; OUTPUT
;    global variables [record_base_ptr] same as input (edi)
;                     [free_record_offset] used internally
;                     [buffer_end_offset] same as input (ecx)
;    registers eax,ecx,edi modified
;          
; OPERATION
;    The hash pointers are set to zero and table pointer
;    saved for other functions.  Only one hash table can
;    be in use so only one pointer is kept.  The hash table
;    is followed records.  record entries are assumed to
;    be terminated by a zero byte.
;
;    The record functions add a chain dword to front of
;    each entry, but this isn't usually of interest to
;    users.  Internally, a hash pointer table is built
;    which points to chains of data entries.
;
;    A record record consists of:
;           1. dword chain (offset)
;           2. dword key
;           3. record
;
;    The buffer size provided to record functions needs to
;    hold the hash table and all the data entries.  Each
;    data entry has an additional 4 bytes added for the
;    chain.
;
;   To  create a in memory record database use:
;        record_setup - create structures
;        record_add   - add entries
;        record_lookup - find entries
;
;   To  write the database to file:
;        record_archive -  write data to file
;
;   To  read the database into memory use:
;        record_restore - open,read,setup hash,close
;
; NOTES
;    source file: records.asm
;                     
;<
;  * ----------------------------------------------

  global record_setup
record_setup:
  mov	[record_base_ptr],edi
  mov	[buffer_end_offset],ecx
  mov	[record_size],eax
  mov	[free_record_offset],dword 64
; clear the hash table buffer
  cld
  xor	eax,eax			;clear eax
  rep	stosb			;clear
  ret

;************************************* hash add **********************************
;>1 hash
;  record_add - add entries to record table
; INPUTS
;  eax = dword key (unique value to identify record,
;        low four bits are used for hash.
;  esi = ptr to record
;  note: function record_setup must be called before
;        using this function.         
; OUTPUT
;    sign bit set for "jns" if near end of buffer
;                      js if buffer has over 100 bytes free 
;          
; NOTES
;    source file: record.asm
;                     
;<
;  * ----------------------------------------------

  global record_add
record_add:
  push	edi
  push	edx
  mov	ebx,[record_base_ptr]
  mov	edx,[free_record_offset]
  lea	edi,[ebx + edx +4]	;get ptr to new packet key
  stosd				;store key
  push	eax			;save key
;move record data into packet
  mov	ecx,[record_size]
  rep	movsb			;move data
  sub	edi,ebx			;compute new free_record_offset
  mov	[free_record_offset],edi
;do hash lookup
  pop	eax			;restore key
  and	eax,byte 0fh		;isolate hash mask
  shl	eax,2			;convert to dword index
ha_lp2:
  mov	ecx,[ebx + eax]		;get hash entry
  jecxz	ha_insert		;jmp if no hash chain yet
  mov	eax,ecx
  jmp	short ha_lp2		;loop till end of chain
ha_insert:
  mov	[ebx+eax],edx		;chain to new packet
  add	edi,100
  sub	edi,[buffer_end_offset]	;set sign bit if close to end of buf   
  pop	edx
  pop	edi
  ret

;************************************** hash lookup ****************************

;>1 hash
;  record_lookup - search records for key
; INPUTS
;   eax = key
; OUTPUT
;   ecx=0 if failure
;   esi=ptr to record if key matches
;   registers ebx,ecx modified
;
; OPERATION
;
; NOTES
;    source file: record.asm
;                     
;<
;  * ----------------------------------------------

  global record_lookup
record_lookup:
  mov	ebx,[record_base_ptr]
; check if hash has entry for this key
  mov	ecx,eax			;save key
  and	ecx,byte 0fh		;isolate hash mask
  shl	ecx,2			;convert to dword index
sl_lp2:
  mov	ecx,[ebx + ecx]		;get hash entry
  jecxz	sl_fail			;jmp if no hash match
  cmp	[ebx + ecx +4],eax	;does key match?
  jne	sl_lp2			;jmp if no match
sl_match:
  lea	esi,[ebx + ecx +8]	;get ptr to record
sl_fail:
  ret

;************************************* hash archive *********************
  extern block_write_all
;>1 hash
;  record_archive - write current hash data to open file
; INPUTS
;    ebx = hashfile name path
;    [record_base_ptr] - set by record_setup or
;                       record_restore
; OUTPUT
;    eax=0 if success, else negative error code
;          
; NOTES
;    source file: record.asm
;                     
;<
;  * ----------------------------------------------

  global record_archive
record_archive:
  mov	ecx,[record_base_ptr]		;get ptr to hash area
  mov	esi,[free_record_offset]	;get size of hash table
  xor	edx,edx				;set default permissions
  call	block_write_all
  ret


;******************************* hash restore ***************************

  extern block_read_all
;>1 hash
;  record_restore - read open hash file into buffer
; INPUTS
;  ebx = hash file path
;  ecx = buffer
;  edx = buffer length
; OUTPUT
;    eax = bytes read if success, else negative error code
;    [record_base_ptr] - initialized by hashfile_restore
;          
; OPERATION
;
; NOTES
;    source file: record.asm
;                     
;<
;  * ----------------------------------------------

  global record_restore
record_restore:
  mov	[record_base_ptr],ecx	;save ptr to hash area
  mov	[buffer_end_offset],edx
  call	block_read_all		;read file
  mov	[free_record_offset],eax
  ret


%ifdef DEBUG

 global main,_start
main:
_start:
  mov	edi,bss_top
  mov	ecx,bss_end - bss_top
  mov	eax,4			;record size
  call	record_setup
  mov	eax,12345678h		;key1
  mov	esi,str1
  call	record_add
  jns	err
  mov	eax,11111111h
  mov	esi,str2
  call	record_add
  mov	eax,11h
  mov	esi,str3
  call	record_add

  mov	eax,12345678h
  call	record_lookup
  mov	eax,11111111h
  call	record_lookup
  mov	eax,11h
  call	record_lookup

  mov	ebx,filename
  call	record_archive
  mov	ebx,filename
  mov	ecx,bss_top
  call	record_restore
  mov	eax,11111111h
  call	record_lookup
err:
  mov	eax,1
  int	80h

;--------------
  [section .data]
str1:	db 'rec1',0
str2:	db 'rec2',0
str3:	db 'rec3',0
filename: db "rec_test.dat",0
;--------------
 [section .bss]
bss_top:	resb	2000
bss_end:            
 [section .text]

%endif
