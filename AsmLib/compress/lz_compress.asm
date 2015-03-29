
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
;
;----------------------------------------------------------------------
;  This program is based upon a modified version code with the
;  following header.
;;
;; Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
;; All Rights Reserved
;;
;; http://www.ibsensoftware.com/
;;
;; This software is provided 'as-is', without any express
;; or implied warranty.  In no event will the authors be
;; held liable for any damages arising from the use of
;; this software.
;;
;; Permission is granted to anyone to use this software
;; for any purpose, including commercial applications,
;; and to alter it and redistribute it freely, subject to
;; the following restrictions:
;;
;; 1. The origin of this software must not be
;;    misrepresented; you must not claim that you
;;    wrote the original software. If you use this
;;    software in a product, an acknowledgment in
;;    the product documentation would be appreciated
;;    but is not required.
;;
;; 2. Altered source versions must be plainly marked
;;    as such, and must not be misrepresented as
;;    being the original software.
;;
;; 3. This notice may not be removed or altered from
;;    any source distribution.
;;


  [section .text align=4]
;>1 compress
;  lz_compress - Lempel-Ziv data compressor
; INPUTS
;    esi = ptr to input data block
;    edi = ptr to output buffer
;    ebx = length input data block
;    edx = ptr to work buffer
;    eax = length of work buffer
;   
;    Output buffer size can be larger than the input
;    buffer if the input data is already compressed.
;    A safe value for the output buffer is:
;   
;    (input buffer size) + 64 + ((input buffer size)/8)
;
;    Work buffer size must be also be a mask size as
;    follows:  2000h, 4000h, 8000h, 10000h 20000h
;              40000h 80000h 100000h 200000h
;    
; OUTPUT:
;    eax = length of compressed data block if positive
;        = zero if input block is zero
;
;    All registers are changed.
;
;    The compressed block has dword at front with origional
;    size of block before compression.  This is followed
;    by compressed data.  If the input block has zero
;    length, no  output block is created.
;
; NOTES
;   source file: lz_compress.asm
;
;   The compressor/decompressor performs as follows
;   when processing a 753246 byte text file:
;
;   Compressor   code  compress   compressed 
;   name         size  time       data size
;   ---------    ----  -----      ----------
;   lz_compress  770   019ms        82759
;   pak          089   027ms       461191
;   gzip         big   044ms       135571
;
;<
; * ----------------------------------------------
;
struc dat
.inbuf       resd 1 ;ptr to input buffer
.outbuf      resd 1 ;ptr to output buffer
.inbuf_len   resd 1 ;length of input data
.workbuf     resd 1 ;ptr to work buf
.workbuf_len resd 1 ;length of workbuf
.wrk4        resd 1 ;workbuf_size / 4
.wrk4m1      resd 1 ;workbuf_size/4 -1
.lim$        resd 1 ;
.bpt$        resd 1 ;
.ecx_save    resd 1
.edx_save    resd 1
.ebx_save    resd 1
.eax_save    resd 1
.esi_save    resd 1
sizedat:
endstruc

  global lz_compress
lz_compress:
  sub	esp, byte sizedat
  mov	[esp+dat.inbuf],esi
  mov	[esp+dat.outbuf],edi
  mov	[esp+dat.inbuf_len],ebx
  mov	[esp+dat.workbuf],edx
  mov	[esp+dat.workbuf_len],eax

  shr	eax,2			;workbuf size /4
  mov	[esp+dat.wrk4],eax	;save wrk4
  dec	eax			;(workbuf size / 4) - 1
  mov	[esp+dat.wrk4m1],eax	;save wrk4m1
;check for null input
  or	ebx,ebx			;check inbuf length
  jz	EODdonej		;exit if zero lenght
;clear the workbuf
  xor	eax,eax			;set workbuf to zero
  mov	edi,edx			;setup to clear workbuf
  mov	ecx,[esp+dat.wrk4]
  rep	stosd
;add input size to output block
  mov	edi,[esp+dat.outbuf]	;restore outbuf
  mov	[edi],ebx		;stuff inbuf len in outbuf
  add	edi,byte 4		;advance outbuf ptr
;assumed registers are
; esi = inbuf ptr
; edi = outbuf ptr
; ebx = input buf length
   lea      eax, [ebx+esi-4]	; limit = source + length - 4
   mov      dword [esp+dat.lim$],eax ;set lim$
   mov      dword [esp+dat.bpt$],esi ;set bpt$
   test     ebx,ebx		;check imbuf length
EODdonej:
   je       near  EODdone	;jmp if inbuf empty	
   movsb
;   mov      al,byte [esi]	;get first inbuf byte
;   inc      esi			;
;   mov      byte [edi],al	;store in outbuf
;   inc      edi			
   cmp      ebx,byte 01H	;inbuf length = 1
   je       near  EODdone	;jmp if inbuf length =1
   mov      bp,001H		;init tag
   mov      edx,edi		;
   add      edi,byte 02H
   jmp      short nexttagcheck	;
no_match:
   test     ebp,ebp
   jne      short z23.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
;add a 0-bit to current tag word
z23.bitsleft:
   add      bp,bp
   jnc      short z23.done
   mov      word [edx],bp
   xor      ebp,ebp	;
z23.done:
   movsb
;   mov      al,byte [esi]	;
;   inc      esi	;
;   mov      byte [edi],al	;
;   inc      edi	;
nexttagcheck:
   cmp      esi,dword [esp+dat.lim$]	;are we done?
   jae      near  donepacking		;jmp if done
nexttag:
   mov      ecx,dword [esp+dat.workbuf]	;get table ptr
   mov      ebx,esi			;ebx = buffer - backptr
   mov      esi,dword [esp+dat.bpt$]	; 
   sub      ebx,esi
;hash next 4 bytes
update:
   mov	    [esp+dat.ecx_save],ecx	;push ecx
   movzx    eax,byte [esi]
   imul     eax,eax,013DH
   movzx    ecx,byte [esi+01H]
   add      eax,ecx
   imul     eax,eax,013DH
   movzx    ecx,byte [esi+02H]
   add      eax,ecx
   imul     eax,eax,013DH
   movzx    ecx,byte [esi+03H]
   add      eax,ecx
   and      eax,[esp+dat.wrk4m1]
   mov      ecx,[esp+dat.ecx_save]	;pop      ecx				;

   mov      dword [ecx+eax*4],esi	;lookuptable[hash] = backptr
   inc      esi				;++backptr
   dec      ebx
   jne      short update		;
   mov      dword [esp+dat.bpt$],esi	;esi is now back to current pos
;hash next 4 bytes
   mov      [esp+dat.ecx_save],ecx	;push     ecx
   movzx    eax,byte [esi]
   imul     eax,eax,013DH
   movzx    ecx,byte [esi+01H]
   add      eax,ecx
   imul     eax,eax,013DH
   movzx    ecx,byte [esi+02H]
   add      eax,ecx
   imul     eax,eax,013DH
   movzx    ecx,byte [esi+03H]
   add      eax,ecx
   and      eax,[esp+dat.wrk4m1]
   mov      ecx,[esp+dat.ecx_save]	;pop      ecx

   mov      ebx,dword [ecx+eax*4]	;ebx=lookuptable[hash]
   test     ebx,ebx			;match?
   je       near  no_match		;jmp if no match
   mov      ecx,dword [esp+dat.lim$]	;get max allowed match len
   sub      ecx,esi	;
   add      ecx,byte 04H

   mov      [esp+dat.edx_save],edx	;push     edx
   xor      eax,eax	;
compare:
   mov      dl,byte [ebx+eax]		;compare possible match with current
   cmp      dl,byte [esi+eax]
   jne      short matchlen_found
   inc      eax
   dec      ecx
   jne      short compare
matchlen_found:
   mov      edx,[esp+dat.edx_save]	;pop      edx	

   cmp      eax,byte 04H		;match too short?
   jc       near  no_match	;
   mov      ecx,esi			;
   sub      ecx,ebx			;ecx=match position
;add 1 bit to current tag word
   test     ebp,ebp
   jne      short z26.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z26.bitsleft:
   add      bp,bp
   inc      bp
   jnc      short z26.done
   mov      word [edx],bp
   xor      ebp,ebp	;
z26.done:
   add      esi,eax			;update esi to next position
   sub      eax,byte 02H	;matchlen >=4, so sub 2
;output gamma coding of matchlen-2
   mov      [esp+dat.ebx_save],ebx	;push     ebx
   mov      [esp+dat.eax_save],eax	;push     eax
   shr      eax,01H
   mov      ebx,01H
z27.revmore:
   shr      eax,01H
   je       short z31.done
   adc      ebx,ebx
   jmp      short z27.revmore
z27.outmore:
   jc       short z28.onebit
   test     ebp,ebp
   jne      short z29.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z29.bitsleft:
   add      bp,bp
   jnc      short z29.done
   mov      word [edx],bp
   xor      ebp,ebp
z29.done:
   jmp      short z30.done
z28.onebit:
   test     ebp,ebp
   jne      short z30.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z30.bitsleft:
   add      bp,bp
   inc      bp
   jnc      short z30.done
   mov      word [edx],bp
   xor      ebp,ebp
z30.done:
   test     ebp,ebp
   jne      short z31.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z31.bitsleft:
   add      bp,bp
   inc      bp
   jnc      short z31.done
   mov      word [edx],bp
   xor      ebp,ebp
z31.done:
   shr      ebx,01H
   jne      short z27.outmore
   mov      eax,[esp+dat.eax_save]	;pop      eax
   shr      eax,01H
   jc       short z32.onebit
   test     ebp,ebp
   jne      short z33.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z33.bitsleft:
   add      bp,bp
   jnc      short z33.done
   mov      word [edx],bp
   xor      ebp,ebp
z33.done:
   jmp      short z34.done
z32.onebit:
   test     ebp,ebp
   jne      short z34.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z34.bitsleft:
   add      bp,bp
   inc      bp
   jnc      short z34.done
   mov      word [edx],bp
   xor      ebp,ebp
z34.done:
   test     ebp,ebp
   jne      short z35.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z35.bitsleft:
   add      bp,bp
   jnc      short z35.done
   mov      word [edx],bp
   xor      ebp,ebp
z35.done:
   mov      ebx,[esp+dat.ebx_save]	;pop      ebx	;

   dec      ecx			;matchpos > 0, so sub 1
   mov      eax,ecx		;eax = (matchpos >> 8) +2
   shr      eax,byte 08H	;
   add      eax,byte 02H	;
;output gamma coding of (matchpos >> 8) +
   mov      [esp+dat.ebx_save],ebx	;push     ebx
   mov      [esp+dat.eax_save],eax	;push     eax
   shr      eax,01H
   mov      ebx,01H
z36.revmore:
   shr      eax,01H
   je       short z40.done
   adc      ebx,ebx
   jmp      short z36.revmore
z36.outmore:
   jc       short z37.onebit
   test     ebp,ebp
   jne      short z38.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z38.bitsleft:
   add      bp,bp
   jnc      short z38.done
   mov      word [edx],bp
   xor      ebp,ebp
z38.done:
   jmp      short z39.done
z37.onebit:
   test     ebp,ebp
   jne      short z39.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z39.bitsleft:
   add      bp,bp
   inc      bp
   jnc      short z39.done
   mov      word [edx],bp
   xor      ebp,ebp
z39.done:
   test     ebp,ebp
   jne      short z40.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z40.bitsleft:
   add      bp,bp
   inc      bp
   jnc      short z40.done
   mov      word [edx],bp
   xor      ebp,ebp
z40.done:
   shr      ebx,01H
   jne      short z36.outmore
   mov      eax,[esp+dat.eax_save]	;pop      eax
   shr      eax,01H
   jc       short z41.onebit
   test     ebp,ebp
   jne      short z42.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z42.bitsleft:
   add      bp,bp
   jnc      short z42.done
   mov      word [edx],bp
   xor      ebp,ebp
z42.done:
   jmp      short z43.done
z41.onebit:
   test     ebp,ebp
   jne      short z43.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z43.bitsleft:
   add      bp,bp
   inc      bp
   jnc      short z43.done
   mov      word [edx],bp
   xor      ebp,ebp
z43.done:
   test     ebp,ebp
   jne      short z44.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z44.bitsleft:
   add      bp,bp
   jnc      short z44.done
   mov      word [edx],bp
   xor      ebp,ebp
z44.done:
   mov      ebx,[esp+dat.ebx_save]	;pop      ebx
   mov      byte [edi],cl	;output low 8 bits of matchpos
   inc      edi	;
   cmp      esi,dword [esp+dat.lim$]	;are we done?
   jc       near  nexttag	; jmp if not done yet
donepacking:
   mov      ebx,dword [esp+dat.lim$]	;ebx=source + len
   add      ebx,byte 04H
   jmp      short check_final_literals	; 0-bit = literal
final_literals:
   test     ebp,ebp
   jne      short z45.bitsleft
   mov      edx,edi
   inc      ebp
   add      edi,byte 02H
z45.bitsleft:
   add      bp,bp
   jnc      short z45.done
   mov      word [edx],bp
   xor      ebp,ebp
z45.done:
   mov      al,byte [esi]	;
   inc      esi	;
   mov      byte [edi],al	;
   inc      edi
check_final_literals:
   cmp      esi,ebx
   jc       short final_literals	;
   test     ebp,ebp		;do we need to fix last tag?
   je       short EODdone	;jmp if tag ok
doEOD:
   add      bp,bp		;shift last tag into position
   jnc      short doEOD		;
   mov      word [edx],bp	;insert last tag
EODdone:
   mov      eax,edi		 ;
   sub      eax,dword [esp+dat.outbuf] ;return length of packed block
   add      esp,byte sizedat
   ret     

;-------------------------------------------------------------
%ifdef DEBUG

;usage  lz_compress <infile> <outfile>

  extern m_setup
  extern m_allocate
  extern mmap_open_ro
  extern block_write_all
  extern str_move
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
   xor      ecx,ecx
   call     near mmap_open_ro
   or       eax,eax
   js	    do_exit
;    esi = ptr to input data block
;    edi = ptr to output buffer
;    ebx = length input data block
;    edx = ptr to work buffer
;    eax = length of work buffer
   mov	esi,ecx		;imbuf
   mov	ebx,eax		;inbuf size

   or	eax,eax		;exit if zero length file (error)
   js	do_exit

   shr	eax,3		;inbuf_size /8
   add	eax,ebx		;
   add	eax,byte 64	;computed outbuf size in eax

   push	esi
   push	ebx
   call     near m_allocate	;leave room for size
   mov	edi,eax		;move outbuf ptr
   mov	[outbuf_ptr],eax
   pop	ebx		;restore inbuf size
   pop	esi		;restore inbuf

   mov	edx,work_buf
   mov	eax,work_buf_len
   call     near lz_compress

   mov      ebx,out_file	;filename ptr
   xor      edx,edx		;permissions
   mov      ecx,[outbuf_ptr]	;output buffer ptr
   mov      esi,eax		;output buffer length
   call     near block_write_all
do_exit:
   mov      eax,01H
   int      byte 080H

  [section .data]
outbuf_ptr dd 0
out_file: db 'cc.out'
 times 20 db 0

  [section .bss]
work_buf_len  equ 10000h	;64k
work_buf:
   resb work_buf_len
%endif