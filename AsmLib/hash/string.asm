
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
;string database
  [section .data]
 global hash_base_ptr,free_packet_offset,buf_end_offset
hash_base_ptr	    dd	0	;start of data
free_packet_offset  dd	0
buf_end_offset	    dd	0
  [section .text]
;----------------------------------------------------
;>1 hash
;  string_setup - prepare string table for use
;    Hash tables are used for fast access to data.
;    string_setup is called once at the beginning
;    of a program.
;
; INPUTS
;    edi = ptr to start of buffer area. (holds data and string)
;    ecx = buffer size
;
; OUTPUT
;    global variables [hash_base_ptr] same as input (edi)
;                     [free_packet_offset] used internally
;                     [buf_end_offset] same as input (ecx)
;    registers eax,ecx,edi modified
;          
; OPERATION
;    The hash pointers are set to zero and table pointer
;    saved for other functions.  Only one hash table can
;    be in use so only one pointer is kept.  The hash table
;    is followed strings.  String entries are assumed to
;    be terminated by a zero byte.
;
;    The string functions add a chain dword to front of
;    each entry, but this isn't usually of interest to
;    users.  Internally, a hash pointer table is built
;    which points to chains of data entries.
;
;    A string record consists of:
;           1. dword chain (offset)
;           2. dword key
;           3. string
;
;    The buffer size provided to string functions needs to
;    hold the hash table and all the data entries.  Each
;    data entry has an additional 4 bytes added for the
;    chain.
;
;   To  create a in memory string database use:
;        string_setup - create structures
;        string_add   - add entries
;        string_lookup - find entries
;
;   To  write a in memory hash database to file:
;        string_archive -  write data to file
;
;   To  read a hash file into memory use:
;        string_restore - open,read,setup hash,close
;
; NOTES
;    source file: strings.asm
;                     
;<
;  * ----------------------------------------------

  global string_setup
string_setup:
  mov	[hash_base_ptr],edi
  mov	[buf_end_offset],ecx
  mov	[free_packet_offset],dword 64
; clear the hash table buffer
  cld
  xor	eax,eax			;clear eax
  rep	stosb			;clear
  ret

;************************************* hash add **********************************
;>1 hash
;  string_add - add entries to string table
; INPUTS
;  eax = dword key (unique value to identify string,
;        low four bits are used for hash.
;  esi = ptr to string
;  note: function string_setup must be called before
;        using this function.         
; OUTPUT
;    sign bit set for "jns" if near end of buffer
;                      js if buffer has over 100 bytes free
;    esi = ptr to end of string 
;          
; NOTES
;    source file: string.asm
;                     
;<
;  * ----------------------------------------------

  global string_add
string_add:
  push	edi
  push	edx
  mov	ebx,[hash_base_ptr]
  mov	edx,[free_packet_offset]
  lea	edi,[ebx + edx +4]	;get ptr to new packet key
  stosd				;store key
  push	eax			;save key
  xor	eax,eax
  mov	[edi -8],eax		;clear chain
sa_lp:
  lodsb				;get string char
  stosb				;store string in packet
  or	al,al
  jnz	sa_lp			;loop till string stored
  sub	edi,ebx			;compute new free_packet_offset
  mov	[free_packet_offset],edi
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
  sub	edi,[buf_end_offset]	;set sign bit if close to end of buf   
  pop	edx
  pop	edi
  ret

;************************************** hash lookup ****************************

;>1 hash
;  string_lookup - search strings for key
; INPUTS
;   eax = key
; OUTPUT
;   ecx=0 if failure
;   esi=ptr to string if key matches
;   registers ebx,ecx modified
;
; OPERATION
;
; NOTES
;    source file: string.asm
;                     
;<
;  * ----------------------------------------------

  global string_lookup
string_lookup:
  mov	ebx,[hash_base_ptr]
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
  lea	esi,[ebx + ecx +8]	;get ptr to string
sl_fail:
  ret

;************************************* hash archive *********************
  extern block_write_all
;>1 hash
;  string_archive - write current hash data to open file
; INPUTS
;    ebx = hashfile name path
;    [hash_base_ptr] - set by string_setup or
;                       string_restore
; OUTPUT
;    eax=0 if success, else negative error code
;          
; NOTES
;    source file: string.asm
;                     
;<
;  * ----------------------------------------------

  global string_archive
string_archive:
  mov	ecx,[hash_base_ptr]		;get ptr to hash area
  mov	esi,[free_packet_offset]	;get size of hash table
  xor	edx,edx				;set default permissions
  call	block_write_all
  ret


;******************************* hash restore ***************************

  extern block_read_all
;>1 hash
;  string_restore - read open hash file into buffer
; INPUTS
;  ebx = hash file path
;  ecx = buffer
;  edx = buffer length
; OUTPUT
;    eax = bytes read if success, else negative error code
;    [hash_base_ptr] - initialized by hashfile_restore
;          
; OPERATION
;
; NOTES
;    source file: string.asm
;                     
;<
;  * ----------------------------------------------

  global string_restore
string_restore:
  mov	[hash_base_ptr],ecx	;save ptr to hash area
  mov	[buf_end_offset],edx
  call	block_read_all		;read file
  mov	[free_packet_offset],eax
  ret


%ifdef DEBUG

 global main,_start
main:
_start:
  mov	edi,bss_top
  mov	ecx,bss_end - bss_top
  call	string_setup
  mov	eax,12345678h		;key1
  mov	esi,str1
  call	string_add
  jns	err
  mov	eax,11111111h
  mov	esi,str2
  call	string_add
  mov	eax,11h
  mov	esi,str3
  call	string_add

  mov	eax,12345678h
  call	string_lookup
  mov	eax,11111111h
  call	string_lookup
  mov	eax,11h
  call	string_lookup

  mov	ebx,filename
  call	string_archive
  mov	ebx,filename
  mov	ecx,bss_top
  call	string_restore
  mov	eax,11111111h
  call	string_lookup
err:
  mov	eax,1
  int	80h

;--------------
  [section .data]
str1:	db 'test data',0
str2:	db 'move test data',0
str3:	db 'string3',0
filename: db "str_test.dat",0
;--------------
 [section .bss]
bss_top:	resb	2000
bss_end:            
 [section .text]

%endif
