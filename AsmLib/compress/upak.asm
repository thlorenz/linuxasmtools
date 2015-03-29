
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

  [section .data]
table: db 20h,09h,'etaoisnhrdlup'
  [section .text]

;-----------------------------------------------
;>1 compress
;  upak - move ascii data and uncompress
; INPUTS
;    esi = ptr to ascii string
;    edi - destination for unpacked output string
; OUTPUT:
;    esi = ptr to end of input string (past zero byte)
;    edi = ptr to end of stored string (past zero byte)
; NOTES
;   source file: pak.asm
;<
; * ----------------------------------------------
  global upak
upak:
  lodsb	
  test	al,80h
  mov	dl,al		;save char
  jnz	up_6		;jmp if packed data found
up_4:
  or	al,al
  stosb
  jnz	upak		;jmp if not end of data
  ret

;process packed field
up_6:
  and	eax,byte 078h
  cmp	al,78h
  je	up_20		;jmp if repeat found
;process pair
  shr	eax,3
  mov	ebx,table+14
  sub	ebx,eax
  mov	al,[ebx]	;get char from table
  stosb			;store char
  mov	al,dl		;restore origional byte
  and	eax,byte 7
  mov	ebx,table+7
  sub	ebx,eax
  mov	al,[ebx]
  jmp	short up_4
;process repeat char
up_20:
  and	dl,07		;isolate count
  lodsb			;get repeat char (next char)
  add	dl,2
;ah=count  al=char
up_22:
  stosb
  dec	dl
  jnz	up_22
  jmp	short upak
;------------------------------------

%ifdef DEBUG

;usage  upak <infile> <outfile>

  extern m_setup
  extern m_allocate
  extern block_read_all
  extern block_write_all
  extern str_move
;  extern upak

  global main,_start
main:
_start:
   call     near m_setup
   mov      esi,esp	;get parameter count
   lodsd	;dec parameter count
   dec      eax	;get ptr to executable name
   lodsd	;jmp if (parameter count =1)
   je       short do_exit	;get infile file name paramater
   lodsd	;get path to ebx
   mov      ebx,eax	;get outfile name
   lodsd
   mov      esi,eax
   mov      edi,out_file
   call     near str_move	;set size unknown
   mov      ecx,input_buf
   mov      edx,input_buf_len   
   call     block_read_all
   or       eax,eax
   js	    do_exit
   push     eax			;save size
   add      eax,input_buf	;compute buffer end
   mov      [eax],dword 0	;terminate buffer

   pop      eax
;    eax = length of work buffer
   shl	    eax,1		;make room to expand
   call     near m_allocate	;leave room for size
   mov	edi,eax		;move outbuf ptr
   mov	[outbuf_ptr],eax
   mov	esi,input_buf
   call	upak
   sub	edi,[outbuf_ptr]	;compute size
   mov	esi,edi			;save size
   dec	esi			;remove zero at end

   mov      ebx,out_file	;filename ptr
   xor      edx,edx		;permissions
   mov      ecx,[outbuf_ptr]	;output buffer ptr
   call     near block_write_all
do_exit:
   mov      eax,01H
   int      byte 080H

  [section .data]
outbuf_ptr dd 0
out_file: db 'cc.out'
 times 20 db 0

  [section .bss]
input_buf_len  equ 800000
input_buf:
   resb input_buf_len

%endif

