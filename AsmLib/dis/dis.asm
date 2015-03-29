
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
;***************  file:  dis.asm  *********************

;conditional assembly defines are:
;  debug - standalone debug mode
;  raw_data -  output data statements infront of dis
;  src_mode -  output only instructions
;legal combinations are: debug+raw_data, debug+src_mode
;%define debug
;%define raw_data
;%define src_mode

  extern str_move
  extern lib_buf
  extern byte_to_ascii
  global dis_block

%ifdef debug
%include "dis_file.inc"
%endif

;-------------------------------------------
; design notes:
;  this is a simple brute force disassembler.
;  It uses a table (decode_table) which has one
;  dword for each opcode.  The table is ordered by
;  opcodes and a direct lookup is performed.
;
;  The decode table also includes instructions
;  prefixed by 0fh (escape prefix).  The first
;  byte specifies a processing type or extension
;  if a group of instructions share the same opcode.
;
;  An extension is refered to as a group in Intel
;  documentation and a separate set of tables
;  are used to docode them.  The group instructions
;  are decoded by looking into the second byte of
;  a instruction for a opcode extension.
;
;  The comments at top of decode_table provide
;  more detail. See decode_table.h
;
;  The unused portion of a decode_table dword entry
;  is defined differently for each process called.
;  The comments at top of each process will describe
;  the  opcodes it handles and how the decode_table
;  entry is formated.
;
;--------------------------------------------
;>1 trace
;   dis_one - disassemble one instruction
; INPUTS    ebp = ptr to instruction data
;           eax = instruction address (address at execution time)
;           [symbol_process] - global variable which can be set if
;                 a symbol table process is available to insert
;                 address labels into disassembly string.
;                 When [symbol_process] is non-zero it is called
;                 mov  eax,[symbol_process]
;                 mov  edi,(memory address)
;                 call  eax
;                 ;return eax=0 if symbol found and esi points at str
;                 ;see hash functions for symbol table handler                   
; OUTPUT    eax = ptr to dis_block with disassembly results
;                 [dis_block] - global dis_block location
;
;     dis_block:   ;block of data returned to caller 
;     warn_flag resb 1
;        ;bit 01h = warning, nasm can not generate this opcode
;        ;bit 02h = warning seg override found?
;        ;bit 08h = warning unusual instruction, retn, push ax,
;
;     error_flag resb 1
;        ;bit  01h = illegal instruction 
;        ;bit  02h = instruction size wrong
;        ;bit  04h = unknown program state      
;        ;bit  08h = unexpected prefix
;
;     instruction_type resb 1
;        ;bit 00h - normal instruction
;        ;bit 01h - floating point
;        ;bit 02h - conditional jmp
;        ;bit 04h - proteced mode (system) instruction
;        ;bit 08h - non-conditonal jmp (ret,call,jmp)
;
;     operand_type  resb 1
;        ;bit 01h - jmp adr at operand
;        ;bit 02h - call adr at operand
;        ;bit 04h - read/write byte adr at operand
;        ;bit 08h - read/write word adr at operand
;        ;bit 10h - read/write dword adr at operand
;        ;bit 20h - probable adr in immediate (const) data operand
;
;     operand  resd 1  ;address (physical) for
;                              jmp,read,write, or operand if actions=0
;     inst_length     resd 1  ;length of instruction, including
;                              prefixs 66h,67h,f2h,f3h, but not lock.
;                              segment prefixs set warning flag and
;                              are included on some instructions.
; prefix flags
;
;     state_flag:  resb  1
;        ;0= instruction decoded ok,return info.
;        ;40=escape prefix found, continue
;        ;20=seg prefix found, continue
;        ;10=66h opsize found, continue
;        ;08=67h address  size, continue
;        ;04=f2h  repne prefix found
;        ;02=f3h rep prefix found
;
;     the prefix flag is set by non-prefix opcodes and signals
;     the end of decode.  It contains legal prefix's for this opcode.
;
;     prefix_flag: resb 1
;        ;80=found non-prefix opcode, decode done 
;        ;40=escape prefix legal for opcode
;        ;20=xx seg prefix legal for opcode
;        ;10=66h opsize prefix legal for opcode
;        ;08=67h address prefix legal for opcode
;        ;04=f3h rep legal for this opcode
;        ;02=f2h  repne legal for this opcode
;
;     instruction data begins with a tab and is stored on
;     one line.  It may include prefix  "rep" at
;     front.  If an unknown instruction is found, it is
;     returned as a "db  xx" and the appropiate error flag
;     is set.
;     
;      inst_end resd 1   ;ptr end of data in instruction_asciiz
;      inst     resb 140 ;ascii instruction build area
;
;
; NOTES:  Source file is dis.asm
;<
;--------------------------------------------
  global dis_one
dis_one:
  cld
  mov	[starting_data_ptr],ebp
  mov	[current_data_ptr],ebp
  mov	[instruction_pc],eax
;initialize the data block
  xor	edx,edx
  mov	[warn_flag],edx		;clear warn_flag,error_flag,operand_type,operand_flag
  mov	[state_flag],edx
  mov	[operand],edx

;setup the store pointer and buffer, this is preserved
  mov	edi,inst			;get stuff ptr
  mov	al,9
  stosb					;stuff tab

dis_loop:
  mov	ebp,[current_data_ptr]  
  xor	edx,edx			;
  mov	dl,[ebp]		;get opcode
;look up opcode in table
  mov	[opcode1],dl		;save this opcode  
  test	byte [state_flag],40h	;escape prefix found
  jz	dis_10			;jmp if no escape prefix active
  add	edx,100h		;move to second half of table
dis_10:
  shl	edx,2			;convert to dword index
  add	edx,decode_table
;decode table format = db process_index
;                         if zero then multi opecode, next dw has group
;                      db process data
;                      dw opcode text ptr if first dw has process
;                         group index if first dw zero
;                      if both words zero then unknown opcode decoded
  mov	eax,[edx]		;get table entry
  mov	ebx,eax			;save for process
  or	eax,eax
  jz	error_returnj		;jmp if unknown opcode
  and	eax,3fh			;isolate process_id
  cmp	al,1			;check process type
  ja	normal_process		;jmp if opcode 2-ff
  je	lookup_process		;jmp if opcode = 1 (prefix)
;this is a group process, look up group
  mov	al,[ebp+1]		;get instruction byte with mod/rm
  and	al,38h			;isolate mod/rm reg/opcode field
  shr	eax,1			;convert to dword index
  add	ax,[edx+2]		;get group table ptr
  add	eax,group01-32		;index into group tables
  mov	edx,eax			;save ptr to decode table
  mov	eax,[eax]		;get processing
  or	eax,eax
error_returnj:
  jz	error_return		;exit if unused opcode
  and	eax,3fh			;isolate process
;this is normal process, stuff opcode text
normal_process:
  push	eax
  xor	eax,eax
  mov	ax,[edx+2]	;get opcode text ptr
  add	eax,names
  mov	esi,eax
  call	str_move
  mov	al,09h		;get tab
  stosb
  pop	eax
;look up process address
lookup_process:
  shl	eax,2			;convert to dword index
  add	eax,process_table
call_process:
;---
; registers ebp=instruction ptr
;           edi=stuff ptr
;           edx=decode_table ptr
;           ebx=decode_table entry
  call	[eax]		;call process, eax -> table  *****************
;--- al=0 if continue, extension found, else al=legal prefix's

;check if error
  cmp	byte [error_flag],0
  jne	error_return
	
;check if done
  or	al,al			;done? - legal_prefix's are stored if done
  jnz	dis_50			;jmp if done

;move to next opcode
  inc	dword [current_data_ptr]
  jmp	dis_loop
;---
; al=legal prefix's returned by process.
; f2/f3 rep  - legal only for string instructions
;    xx seg  - legal for memory reference instructions only, give warning
;    66 opsize - legal for some instructions
;    67 adrsiz - legal for memory access instructions
;check if assembled instruction has legal prefix's attached
dis_50:
  mov	[prefix_flag],al

;if last opcode started with 0fh and did not produce an error
;assume 0fh opcode is legal
  test	byte [state_flag],40h	;did last opcode start with 0fh
  jz	dis_60			;jmp if not (escape) 0fh opcode
  or	byte [prefix_flag],40h	;set 0fh as legal prefix
dis_60:
;  mov	al,[prefix_flag]	;get legal prefix's
  and	al,7fh			;remove done bit
  mov	ah,al			;save copy
  or	al,[state_flag]		;if any new bit is set, then error
  cmp	al,ah			;same?
  je	do_done			;jmp if prefix's ok
error_return:
  or	byte [error_flag],01
  mov	edi,inst+1
  mov	ebp,[starting_data_ptr]
  mov	al,[ebp]		;get first opcode
  inc	ebp
  call	stuff_db
do_done:
  sub	ebp,[starting_data_ptr]
  mov	[inst_length],ebp	;save length

%ifdef raw_data
  call	make_db_inst
  jmp	short do_done2
%endif

%ifdef src_mode
  jmp	short do_done2
%endif

%ifdef debug
  test	byte [warn_flag],01h	;convert instruction to "db"?
  jz	do_done2
  call	make_db_inst
%endif

do_done2:
  mov	[inst_end],edi
  xor	eax,eax
  stosb				;put zero at end of stuff buf
  mov	eax,dis_block
  ret
;----------------------------------------------------------
  [section .data]

current_data_ptr:	dd	0

process_table:
  dd	0		;group (already handled)
  dd	type_s01	;prefix
  dd	type_s02	;assumed registers
  dd	type_s03	;simple single byte instruction
  dd	type_s04	;misc single byte opcodes
  dd	type_s05	;string instructions
  dd	type_s06	;rm8
  dd	type_s07
  dd	type_s08
  dd	type_s09
  dd	type_s10
  dd	type_s11
  dd	type_s12
  dd	type_s13
  dd	type_s14
  dd	type_s15
  dd	type_s16
  dd	type_s17
  dd	type_s18
  dd	type_s19
  dd	type_s20
  dd	type_s21
  dd	type_s22
  dd	type_s23
  dd	type_s24
  dd	type_s25
  dd	type_s26
  dd	type_s27
  dd	type_s28
  dd	type_s29
  dd	type_s30

  [section .text]
%ifdef debug
;----------------------------------------------------------
;  input:  inst_length (dword)
;          inst (instruction asciiz stuff buffer)
;          edi = ptr to end of istruction stuff area
;          starting_data_ptr  
;  output: edi=ptr to end of instruction stuff area 
;
make_db_inst:
  mov	edi,lib_buf
  mov	esi,inst
;find end of instruction
  push	esi
mdi_lp1:
  lodsb
  cmp	al,0ah
  jne	mdi_lp1
  dec	esi
  mov	byte [esi],0		;put zero at end of instruction
  pop	esi
;save instruction at lib_buf
  call	str_move		;save instruction
  mov	edx,[inst_length]	;get length
  mov	esi,[starting_data_ptr]
  mov	edi,inst		;get inst asciiz stuff buffer
  mov	eax,' db '
  stosd
mdi_lp2:
  xor	ebx,ebx
  mov	al,'0'
  stosb				;stuff leading zero
  lodsb
  mov	bl,al
  call	bin_to_hexascii_h
  dec	edx
  jz	mdi_done
  mov	al,','
  stosb				;stuff comma after byte
  jmp	mdi_lp2			;loop till all bytes stored
;put space and comment char at end
mdi_done:
  mov	ax,3b20h
  stosw
  mov	esi,lib_buf
  inc	esi			;move past tab at front
  call	str_move
  mov	al,0ah
  stosb
  mov	[inst_end],edi
  ret
%endif  
;----------------------------------------------------------
%include "type_01.inc"
%include "type_02.inc"
%include "type_03.inc"
%include "type_04.inc"
%include "type_05.inc"
%include "type_06.inc"
%include "type_07.inc"
%include "type_08.inc"
%include "type_09.inc"
%include "type_10.inc"
%include "type_11.inc"
%include "type_12.inc"
%include "type_13.inc"
%include "type_14.inc"
%include "type_15.inc"
%include "type_16.inc"
%include "type_17.inc"
%include "type_18.inc"
%include "type_19.inc"
%include "type_20.inc"
%include "type_21.inc"
%include "type_22.inc"
%include "type_23.inc"
%include "type_24.inc"
%include "type_25.inc"
%include "type_26.inc"
%include "type_27.inc"
%include "type_28.inc"
%include "type_29.inc"
%include "type_30.inc"

;%include "type12_19.inc"
%include "subs.inc"
  [section .data]
%include "decode_names.h"
%include "decode_table.h"

 [section .data]
  global symbol_process
symbol_process	dd 0	;ptr to symbol table lookup routine
last_prefix_name dw 0
opcode1	db	0	;opcode
starting_data_ptr	dd	0
instruction_pc		dd	0

%include "decode_results.h"
;%include "decode_equates.h"

