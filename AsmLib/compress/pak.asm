
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
;----------file pak.asm ---------------------
;ascii data is packed into a byte as follows:
; 10000000b - setting high bit says a pack on this byte
; 1xxxx---b - table of common characters encoded here, if
;             xxxx = 1111 then a repeat is active
; 1----xxxb - second char encoded here from same table
;             if repeat, this is count
;example: 10001000b is 'te' encoded in one byte
;--------------------------------------------
;>1 compress
;  pak - move ascii data and compress
; INPUTS
;    esi = ptr to ascii string
;    ebx - destination for packed output string
; OUTPUT:
;    esi = ptr to end of input string (past zero)
;    ebx = ptr to end of stored string (past zero)
; NOTES
;   source file: pak.asm
;   pak uses a simple algrothm that works
;   best if ascii strings have a lot of repeated
;   characters in a row.  For ascii strings without
;   repeats it can achieve 20-30 percent
;   compression.  It is mostly used for speed
;   and its ability to compress data as it
;   copies.
;<
; * ----------------------------------------------
  global pak
pak:
  lodsb			;get next char
  or	al,al
  mov	ah,al		;save copy of char
  jz	mp_90		;jmp if done
  cmp	ax,[esi]	;check for repeat
  je	mp_50
;scan table for first char
mp_10:
  mov	edi,table
  push	byte 15		;mov ecx,15
  pop	ecx		;mov ecx,15
  repne	scasb		;scan for char
  jne	mp_80		;jmp if normal char store
  mov	dl,cl
  shl	dl,3		;position code
;see if second char in table
  mov	al,[esi]
  mov	edi,table
  push	byte 8		;mov ecx,8
  pop	ecx		;mov ecx,8
  repne	scasb		;check table
  je	mp_20		;jmp if both chars in table
;second char not in table
  mov	al,ah		;restore origonal byte
  jmp	short mp_80	;go store first char  
;both chars in table, add current to edx
mp_20:
  inc	esi		;move past pair
  or	dl,cl
  mov	al,dl
  or	al,80h
  jmp	short mp_80

;repeat found, al=match char
mp_50:
  xor	ecx,ecx
  inc	esi		;move past matches so far
mp_55:
  cmp	byte [esi],al
  jne	mp_60		;jmp if end of  repeats
  inc	esi
  inc	ecx
  cmp	ecx,byte 7
  jb	mp_55		;loop till max repeat
;repeat count in ecx, char in al
mp_60:
  mov	dl,0f8h		;set repeat code
  or	dl,cl		;insert repeat count
  mov	[ebx],dl
  inc	ebx
mp_80:
  mov	[ebx],al
  inc	ebx
  jmp	short pak
mp_90:
  mov	[ebx],al
  inc	ebx
  ret
;------------
  [section .data]
table: db 20h,09h,'etaoisnhrdlup'
  [section .text]

%ifdef DEBUG

;usage  pak <infile> <outfile>

  extern m_setup
  extern m_allocate
  extern block_read_all
  extern block_write_all
  extern str_move
;  extern pak

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
   mov      [eax],byte 0	;terminate buffer

   pop      eax
;    eax = length of work buffer
   call     near m_allocate	;leave room for size
   mov	ebx,eax		;move outbuf ptr
   mov	[outbuf_ptr],eax
   mov	esi,input_buf
   call	pak
   sub	ebx,[outbuf_ptr]	;compute size
   mov	esi,ebx			;save size

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

