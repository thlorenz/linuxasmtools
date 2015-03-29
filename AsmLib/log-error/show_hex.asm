
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


;-----------------------------------------
	%define stdout 0x1
	%define stderr 0x2

  extern hex_dump_stdout
  extern byteto_hexascii
  extern wordto_hexascii
  extern dwordto_hexascii

;----------------------------------------------------  
;>1 log-error
;   show_hex - display assorted hex numbers using control table
; INPUTS
;    eax = fd (1=stdout) 
;    esi = control  table
;
;    The control table is normal ascii with embedded
;    codes to indicate where numbers are needed.  Numbers
;    are shown in hex.
;    Embedded codes: -1 = ptr to byte follows
;                    -2 = ptr to word follows
;                    -3 = ptr to dword follows
;                    -4 = actual byte follows
;                    -5 = actual word follows
;                    -6 = actual dword follows
;                    -7 = dmp byte block  | dd count, dd ptr
;                    -8 = dmp word block  | dd count, dd ptr
;                    -9 = dmp dword block | dd count, dd ptr
;                   -10 = ptr to string follows
;                     0 = end of string or end of table if
;                         not processng string
;
; OUTPUT
;   uses current color, see crt_set_color, crt_clear
; EXAMPLE TABLE
;   db 'hex byte =',0
;   db -1	;ptr to hex byte follows
;   dd hex_here ;ptr to hex data
;   db 'hex word =',0
;   db -2	;ptr to hex word follows
;   dd word_here ;ptr to hex data
;   db 0 ;end of table
; NOTES
;   source  file show_hex.asm
;<
;  * ---------------------------------------------------
  global show_hex
show_hex:
  mov	[fd_out],eax		;save fd
sn_lp:
  push	esi
  lodsb				;get next byte from table
  or	al,al
  js	sn_number		;jmp if number here
  jz	sn_done			;zero terminates table
  pop	esi
  mov	ecx,esi
sn_entry:
  call	crt_str
  add	esi,edx			;move ptr fwd
  inc	esi			;adjust for zero at end of str
  jmp	short sn_lp
sn_err:
sn_done:
  pop	esi
  ret
  	
sn_number:
  pop	ecx		;clear the stack
  neg	al
  movzx eax,al
  cmp	al,10
  ja	sn_err
  shl	eax,2
  add	eax,jmp_table -4
  jmp	[eax]

;-----------
  [section .data]
jmp_table:
  dd byte_ptr	;-1
  dd word_ptr	;-2
  dd dword_ptr	;-3
  dd byte_after ;-4
  dd word_after ;-5
  dd dword_after;-6
  dd byte_dmp	;-7
  dd word_dmp	;-8
  dd dword_dump ;-9
  dd str_ptr	;-10

;-------------
  [section .text]
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
byte_ptr:	;-1
  lodsd		;get ptr to data
  mov	al,[eax]	;get data
  mov	edi,hex_build
  call	byteto_hexascii
  jmp	num_tail
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
word_ptr:	;-2
  lodsd		;get ptr to data
  mov	ax,[eax]	;get data
  mov	edi,hex_build
  call	wordto_hexascii
  jmp	num_tail
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
dword_ptr:	;-3
  lodsd		;get ptr to data
  mov	eax,[eax] ;get data
  mov	edi,hex_build
  call	dwordto_hexascii
  jmp	num_tail
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
byte_after: ;-4
  lodsb		;get byte
  mov	edi,hex_build
  call	byteto_hexascii
  jmp	num_tail
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
word_after: ;-5
  lodsw		;get word
  mov	edi,hex_build
  call	wordto_hexascii
  jmp	num_tail
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
dword_after: ;-6
  lodsd		;get dword
  mov	edi,hex_build
  call	dwordto_hexascii
num_tail:
  mov	ecx,hex_build
  call	crt_str
;  add	esi,5			;move to next table entry
  xor	eax,eax
  mov	[hex_build],eax		;clear build area
  mov	[hex_build+4],eax
  jmp	sn_lp
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
str_ptr:	;-10
  lodsd	;get string ptr
  mov	ecx,eax
  call	crt_str
  jmp	sn_lp
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
byte_dmp:	;-7
  lodsd		;get count
  mov	edx,eax
  lodsd		;get ptr to data
  mov	ecx,eax
  mov	ebx,16	;items per line
  mov	eax,1	;bytes per item
  mov	ebp,byteto_hexascii
  call	dump_hex
  jmp	sn_lp  
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
word_dmp:	;-8
  lodsd		;get count
  mov	edx,eax
  lodsd		;get ptr to data
  mov	ecx,eax
  mov	ebx,8	;items per line
  mov	eax,2	;bytes per item
  mov	ebp,wordto_hexascii
  call	dump_hex
  jmp	sn_lp  
;-------------------------------------------------------------------------
; in-> ecx=table entry start  esi=table entry +1  out-> esi=ptr next entry
; input: esi -> count,ptr
dword_dump: ;-9
  lodsd		;get count
  mov	edx,eax
  lodsd		;get ptr to data
  mov	ecx,eax
  mov	ebx,8	;items per line
  mov	eax,4	;bytes per item
  mov	ebp,dwordto_hexascii
  call	dump_hex
  jmp	sn_lp  
;----------------------------
; input: ebx = number of items per line
;        edx = total item count
;        ebp = converter
;        eax = item byte size
;        ecx = ptr to dump data
; output: esi unchanged
dump_hex:
  mov	[item_byte_size],eax
  mov	[items_per_line],ebx
dh_loop:
  mov	eax,[ecx]	;get dump data (either byte,word,dword)
  mov	edi,hex_build
  push	ecx		;save ptr to data
  push	edx		;save total items remaining
  push	ebx
  call	ebp
  mov	ecx,hex_build
  call	crt_str		;show data
  pop	ebx
  pop	edx		;restore total items remaining
  pop	ecx		;restore ptr to data
  add	ecx,[item_byte_size] ;advance to next item
  dec	edx		;decrement total remaining
  jz	dh_done		;jmp if all items shown
  dec	ebx		;items per line
  jnz	dh_20		;jmp if more items for this line
;end of line:
  push	ecx		;save ptr to data
  push	edx		;save total items remaining
  mov	ecx,eol
  call	crt_str		;terminate line
  pop	edx		;restore total items remaining
  pop	ecx		;restore ptr to data
  mov	ebx,[items_per_line]
  jmp	dh_loop
;more data for this line
dh_20:
  push	ecx		;save ptr to data
  push	edx		;save total items remaining
  push	ebx
  mov	ecx,space
  call	crt_str
  pop	ebx
  pop	edx		;restore total items remaining
  pop	ecx		;restore ptr to data
  jmp	dh_loop
dh_done:
  ret
  
;---------------
  [section .data]
item_byte_size dd 0
items_per_line dd 0
  [section .text]

;----------------------------
; input: ecx=sting ptr
; output: edx=length of string ecx=string ptr
crt_str:
  xor edx, edx
count_again:	
  cmp [ecx + edx], byte 0x0
  je crt_write
  inc edx
  jmp short count_again

crt_write:
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx,[fd_out]			; file desc. is stdout
  int byte 0x80
  ret
;---------------
  [section .data]
fd_out: dd 0
hex_build: db 0,0,0,0,0,0,0,0,0
eol	db 0ah,0
space	db ' ',0

  [section .text]

;--------------------------------------------------------------
%ifdef DEBUG

  global main,_start

main:
_start:
  mov	eax,1		;stdout
  mov	esi,ctable
  call	show_hex

  mov	eax,1
  int	80h

;--------------
  [section .data]
ctable:
   db 0ah
   db 'hex byte =',0
   db -1	;ptr to hex byte follows
   dd hex_here ;ptr to hex data
   db 0ah,0

   db 'hex word =',0
   db -2	;ptr to hex word follows
   dd word_here ;ptr to hex data
   db 0ah,0

   db 'hex dword =',0
   db -3	;ptr to hex word follows
   dd dword_here ;ptr to hex data
   db 0ah,0

   db 'inline byte',0
   db -4
   db 12h
   db 0ah,0

   db 'inline word',0
   db -5
   dw 1234h
   db 0ah,0

   db 'inline dword',0
   db -6
   dd 12345678h
   db 0ah,0

   db -7
   dd 17	;dump 17 bytes
   dd some_bytes
   db 0ah,0

   db -8
   dd 17
   dd some_words
   db 0ah,0

   db -9
   dd 17
   dd some_dwords
   db 0ah,0

   db -10
   dd string_ptr

   db -10
   dd string2

   db 0 ;end of table

hex_here  db 12h
word_here dw 1234h
dword_here dd 12345678h

some_bytes: db 1,2,3,4,5,6,7,8,9,1,2,34,5,6,7,8,9,1,2,3,4,5,6,7
some_words: dw 1,2,3,4,5,6,7,8,9,1,2,34,5,6,7,8,9,1,2,3,4,5,6,7
some_dwords: dd 1,2,3,4,5,6,7,8,9,1,2,34,5,6,7,8,9,1,2,3,4,5,6,7
string_ptr: db 'test string',0ah,0
string2: db 'string2',0ah,0

  [section .text]
%endif


