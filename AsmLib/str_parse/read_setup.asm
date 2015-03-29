
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

  extern str_search
  extern file_read_all

;****f* str_parse/read_setup *
; NAME
;>1 str_parse
;  read_setup - read config file and move data
; INPUTS
;    ebp = file name ptr, use $HOME as base
;    edi = buffer to read file into, must be big enoug
;          to hold data
;    esi = table with data move information.
;    ebx = ptr to enviornment pointers
;       table format (esi):
;       ptr to name,  ptr to destination, grouping code (4 ascii chars)
;       zero ptr to name indicates end of table
;       names terminated by space or any char 0-9h
;       grouping code is used to destinguish between two identical names,
;       this is useful when one name has multiple possible destinations.
;     
;       input file format (edi):
;       <ascii name>=<"string"> space <grouping code>
;       ascii name - variable length string without any spaces inside,
;          ends with "=" char.
;       string - any ascii data enclosed in quotes, space after last quote
;       grouping code - any 4 ascii characters matching table grouping code
; OUTPUT
;    if name and grouping match table then the "string" is
;      moved using table destination ptr.
;    stored string is terminated with spaces unitl
;    any char 0-9h encountered
;     
;    if file not found read_setup returns sign bit set
;    for js instruction.
;    if file found and processed, then jns flag bit set
; NOTES
;   source file:  read_setup.asm
;<
; * ----------------------------------------------
;*******

  global read_setup
read_setup:
;  mov	ebp,config_fname
  push	edi			;save buffer ptr
  push	esi			;save control table
  mov	edx,64000  		;assume maximux setup file size is 64000
  mov	ecx,edi			;get buffer ptr
  call	file_read_all
  pop	edi			;get control table
  pop	esi			;get buffer
  jns	rh_10			;jmp if file read
;  mov	byte [first_time_flag],1
  jmp	rh_exit2
;
; process configuration file
;
rh_10:
  add	eax,esi			;compute file end
  mov	ebp,eax
  call	setup_to_table
  xor	eax,eax			;clear sign bit
rh_exit2:
  ret

;-
; extract_setup - move config data from input buffer to program
;  inputs:
;    ebp = file end ptr
;    esi = buffer ptr
;    - match string begin after a 0ah and end with space or "="
;    - followed by data in quotes  "...."
;    edi = control table ptr
;   -  table format:
;   -  ptr to name,  ptr to destination
;   -  zero indicates end of table pairs.
;   -  names terminated by space or any char 0-9h
 
setup_to_table:
  mov	[stt_buf_ptr],esi
  mov	[stt_table_ptr],edi
;
; go through buffer and stuff zero at end of name
;
; strip any leading blanks
stt_lp0:
  mov	ebx,esi		;save buffer location
  lodsb
  cmp	al,' '
  je	stt_lp0
; look for end of label field  
stt_lp1:
  cmp	esi,ebp
  jae	stt_20		;jmp if done parsing items
  lodsb
  cmp	al,' '		;check if space
  jbe	stt_10		;jmp if end of label found
  cmp	al,'='
  jne	stt_lp1		;loop if not end of label
stt_10:
  mov	byte [esi -1],0	;flag end of match string
; now flag end of label definition
stt_lp2:
  lodsb
  cmp	al,'"'	;find start of field
  jne	stt_lp2		;loop till start of data string found
  mov	ecx,esi		;save start of data string
; now search for end of data string
stt_lp3:
  lodsb
  cmp	al,'"'
  jne	stt_lp3
  mov	byte [esi -1],0	;flag end of match string
;
; ebx - points to start of label, string ends with zero
; ecx - points to start of data  field, end with zero
; go check if this label in control table
  push	esi
  push	edi
  push	ebp
  call	process_config_entry
  pop	ebp
  pop	edi
  pop	esi
; find 0ah at end of line or end of file
stt_lp4:
  lodsb
  cmp	esi,ebp
  jae	stt_20		;jmp if end of buffer found
  cmp	al,0ah
  ja	stt_lp4		;loop till end of line found
  jmp	stt_lp0		;go do next line
;
stt_20:
  ret
;--------------------------------------------------------
  [section .data]
stt_buf_ptr	dd	0	;used by read_setup_file
stt_table_ptr	dd	0	;used by read_setup_file
  [section .text]
;--------------------------------------------------------
; ebx - points to start of label, string ends with zero
; ecx - points to start of data  field, end with zero
; esi - points to space infront of ascii code field (grouping)
; [stt_table_ptr] - points to top of control table
; - table format:  name ptr,  string store ptr (end of field has 0-9h), code(grouping) string
; -                name ptr ends wih space, store field needs spaces till end
; -                code(grouping) is 4 ascii characters.
;
process_config_entry:
  mov	ebp,[stt_table_ptr]	;get top of control table
  mov	eax,[esi+1]		;get grouping code
  mov	[grouping_code],eax
pce_lp1:
  mov	esi,ebx			;get setup label from input file
  mov	edi,[ebp]		;get table label ptr
  or	edi,edi
  jz	pce_60			;jmp if end of table, error
  mov	eax,[ebp+8]		;get ascii grouping code
  cmp	eax,[grouping_code]
  jne	pce_lp_end		;skip compare if wrong group
  push	ebx
  push	ecx
  call	str_search		;look for match
  pop	ecx			;restore ptr to start of file data field
  pop	ebx			;restore ptr to start of file label field
  jnc	pce_40			;jmp if match found
pce_lp_end:
  add	ebp,12			;move to next table entry
  jmp	pce_lp1			;loop back to try next table entry
; match found,  move data to destination
pce_40:
  mov	esi,ecx			;get start of file data field  
  mov	edi,[ebp +4]		;get destination ptr
pce_lp2:
  lodsb
  or	al,al			;end of input data?
  jz	pce_50			;jmp if end of input data
  stosb
  jmp	short pce_lp2
; end of input data, fill blanks to end of field
pce_50:
  mov	al,' '
pce_lp3:
  cmp	byte [edi],9
  jbe	pce_60			;jmp if done
  stosb
  jmp	short pce_lp3
; end of table or data moved ok
pce_60:				;end of table encountered
  ret
;--------
  [section .data]
grouping_code:  dd	0
  [section .text]
