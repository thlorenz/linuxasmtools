

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
;  lz_decompress - Lempel-Ziv data uncompressor
; INPUTS
;    esi = ptr to input data block
;          created by lz_compress
;    edi = ptr to output buffer
;   
;    Output buffer size can be found in first dword
;    of input block from lz_compress.
;   
; OUTPUT:
;    eax = length of decompressed data block
;
;    All registers are changed.
;
;    The compressed block has dword at front with origional
;    size of block before compression.  This is followed
;    by compressed data.
;
; NOTES
;   source file: lz_decompress.asm
;
;   The compressor/decompressor perform as follows
;   when processing a 753246 length text file:
;
;   deCompressor  code  decompress
;   name          size  time      
;   ---------     ----  -----     
;   lz_decompress 146   014ms     
;   upak          070   018ms     
;   gzip          big   009ms     
;
;<
; * ----------------------------------------------
  global lz_decompress

lz_decompress:
   sub      esp,4		;create variable area
   mov      ebx,[esi]		;get size of output block
   add      esi,4		;advance input ptr
   mov      [esp],edi		;save output buffer

   mov      ax,008000H	;initialize tag
   add      ebx,edi	;set ebx to end of outbuf
lz_decompress.literal:
   movsb
   cmp      edi,ebx
   jnc      near  lz_decompress.donedepacking
lz_decompress.nexttag:
   add      ax,ax
   jne      short z13.stillbitsleft
   lodsw
;   mov      ax,word [esi]
;   lea      esi, [esi+02H]
   adc      ax,ax	;
z13.stillbitsleft:
   jnc      short lz_decompress.literal
   mov      ecx,01H
z14.getmore:
   add      ax,ax
   jne      short z15.stillbitsleft
   lodsw
;   mov      ax,word [esi]
;   lea      esi, [esi+02H]
   adc      ax,ax
z15.stillbitsleft:
   adc      ecx,ecx
   add      ax,ax
   jne      short z16.stillbitsleft
   lodsw
;   mov      ax,word [esi]
;   lea      esi, [esi+02H]
   adc      ax,ax
z16.stillbitsleft:
   jc       short z14.getmore	
   mov      edx,01H
z17.getmore:
   add      ax,ax
   jne      short z18.stillbitsleft
   lodsw
;   mov      ax,word [esi]
;   lea      esi, [esi+02H]
   adc      ax,ax
z18.stillbitsleft:
   adc      edx,edx
   add      ax,ax
   jne      short z19.stillbitsleft
   lodsw
;   mov      ax,word [esi]
;   lea      esi, [esi+02H]
   adc      ax,ax
z19.stillbitsleft:
   jc       short z17.getmore	;
   add      ecx,byte 02H	;
   shl      edx,byte 08H	;
   mov      dl,byte [esi]	;
   inc      esi	;
   add      edx,0FFFFFE01H	;
;   push     esi
   mov      ebp,esi
   mov      esi,edi
   sub      esi,edx
   rep      movsb   
;   pop      esi	;
   mov      esi,ebp	;restore esi
   cmp      edi,ebx
   jc       near  lz_decompress.nexttag	;
lz_decompress.donedepacking:
   mov      eax,edi	;
   sub      eax,[esp]		;compute length
   add      esp,4
   ret     

%ifdef DEBUG

  extern m_setup
  extern m_allocate
  extern mmap_open_ro
  extern block_write_all
  extern str_move

  [section .text]

  global main,_start
main:
_start:
   call     near m_setup
   mov      esi,esp	;
   lodsd		;get parameter count
   dec      eax		;dec parameter count
   lodsd		;get ptr to executable name
   je       short do_exit	;jmp if (parameter count=1
   lodsd			;get file name parameter
   mov      ebx,eax		;get path to ebx
   lodsd			;get outfile name
   mov      esi,eax
   mov      edi,out_file
   call     near str_move	;set size unknown
   xor      ecx,ecx
   call     near mmap_open_ro
   or       eax,eax
   js       do_exit
   mov      eax,dword [ecx]	;decompressed block len
   push     ecx
   call     near m_allocate	;allocate outbuf
   mov      edi,eax		;set edi=outbuf
   mov      [out_buf],eax	;save output buffer
   pop      esi			;restore input buffer
   call     near lz_decompress
   mov      ebx,out_file	;get outfile name
   xor      edx,edx		;set default permissions
   mov      ecx,[out_buf]	;get outbuf ptr
   mov      esi,eax		;out buf size
   call     near block_write_all
do_exit:
   mov      eax,01H
   int      byte 080H

  [section .data]
out_buf	dd 0
out_file:
   db "d.out"
   times  0000002Bh db 000h
%endif

