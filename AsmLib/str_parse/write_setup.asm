
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
  extern file_write_close
;****f* sys/write_setup *
; NAME
;>1 str_parse
;  write_setup - write config file
; INPUTS
;    ebp = file name ptr, use $HOME as base
;    edi = buffer to build file
;    ebx = table with data move information.
;    eax = enviornment ptr to ptrs
;       table format:
;       ptr to name,  ptr to destination, grouping code
;       zero indicates end of table pairs.
;       names terminated by space or any char 0-9h
;       grouping code is 4 ascii digits used too
;         destinguish between identical names.
;   
; OUTPUT
;    the file name in ebp is written to $HOME dir
;    with: <name>=<destination data><space><grouping code><0ah>
; NOTES
;   source file: write_setup.asm
;   see file read_setup.asm
;<
; * ----------------------------------------------
;*******
  global write_setup
write_setup:
  mov	[ws_env_ptr],eax
  mov	ecx,edi		;save buffer start
ws_lp0:
  mov	esi,[ebx]	;get name ptr
  or	esi,esi
  jz	ws_write	;jmp if end of  table
  cmp	byte [esi],' '	;check if blank field
  jne	ws_lp1		;jmp if field has data
  add	ebx,12
  jmp	short ws_lp0
ws_lp1:
  lodsb
  cmp	al,' '
  jbe	ws_10		;jmp if label moved
  stosb
  jmp	short ws_lp1
; put "=" after label
ws_10:
  mov	al,'='
  stosb			;stuff a =
  mov	al,'"'
  stosb			;stuff a "
; now move data field
  add	ebx,4
  mov	esi,[ebx]	;get data ptr
ws_lp2:
  lodsb
  cmp	al,' '
  jbe	ws_20		;jmp if end of field
  stosb
  jmp	ws_lp2
; put quote at end of entry
ws_20:
  mov	al,'"'
  stosb
  mov	al,' '
  stosb			;put space after data field
  add	ebx,4		;move to  flag field
  mov	eax,[ebx]
  stosd			;store flag
; terminate line
  mov	al,0ah
  stosb
  add	ebx,4		;move to top of next table pair
  jmp	ws_lp0		;loop back and do next table entry
;
; edi = file end ptr
; ebp = filename ptr
; ecx = buffer start
;
ws_write:
  mov	ebx,ebp		;ebx = file name ptr
  mov	eax,ecx		;eax = buffer ptr
  sub	edi,ecx		;compute length of write
  mov	ecx,edi		;ecx = length of write
  mov	esi,0ah		;flags, write to $HOME & attributes in edx
  mov	edx,644q	;file attributes
  mov	ebp,[ws_env_ptr]
  call	file_write_close
  ret
;---------------------------------------
  [section .data]
ws_env_ptr:	dd	0
  [section .text]
;---------------------------------------
