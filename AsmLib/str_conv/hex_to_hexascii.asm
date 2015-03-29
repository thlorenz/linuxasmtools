
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
;*******
;>1 str_conv
;  dwordto_hexascii - convert one dword to hex ascii and store
; INPUTS
;     eax = dword of data
;     edi = storage point for hex ascii
; OUTPUT
;    eight ascii characters stored at [edi]
;      edi points beyond last stored char.
;      eax modified
; NOTES
;    source file: hex2str.asm
;    See also: dword2hexascii
;    The library has numerous hex converstions, this one is
;    very compact and moderatly fast, It is the prefered choice.
;<
;  * ----------------------------------------------
;*******
  global dwordto_hexascii
;*******
;>1 str_conv
;  wordto_hexascii - convert one word to hex ascii and store
; INPUTS
;     eax = word of data
;     edi = storage point for hex ascii
; OUTPUT
;    four ascii characters stored at [edi]
;      edi points beyond last stored char.
;      eax modified
; NOTES
;    source file: hex2str.asm
;    The input word must be in a cleared ebx register
;    See also: word2hexascii
;    The library has numerous hex converstions, this one is
;    very compact and moderatly fast, It is the prefered choice.
;<
;  * ----------------------------------------------
;*******
  global wordto_hexascii
;****f* str_conv/byteto_hexascii *
; NAME
;>1 str_conv
;  byteto_hexascii - convert one byte to hex ascii and store
; INPUTS
;     eax = byte of data
;     edi = storage point for hex ascii
; OUTPUT
;    two ascii characters stored at [edi]
;      edi points beyond last stored char.
;      eax modified
; NOTES
;    source file: hex2str.asm
;    The input word must be in a cleared ebx register.
;    See also: word2hexascii
;    The library has numerous hex converstions, this one is
;    very compact and moderatly fast, It is the prefered choice.
;<
;  * ----------------------------------------------
  global byteto_hexascii
;-------------
;>1 str_conv
;  nibbleto_hexascii - convert 4-bits to hex ascii and store
; INPUTS
;     al  = hex value
;     edi = storage point for ascii
; OUTPUT
;    one ascii character stored at [edi]
;      edi incremented by one
;      eax is shifted right 3 bits
; NOTES
;    source file: hex2str.asm
;    See also: nibble2hexascii
;    The library has numerous hex converstions, this one is
;    very compact and moderatly fast, It is the prefered choice.
;<
;  * ----------------------------------------------
  global nibbleto_hexascii
;--------------------------------------------------
dwordto_hexascii:
        push    eax
        shr     eax,16          ;do high word first
        call    wordto_hexascii
        pop     eax
wordto_hexascii:
        push    eax
        shr     eax,8           ;do high byte first
        call    byteto_hexascii
        pop     eax
byteto_hexascii:
        push    eax
        shr     eax,4           ;do high nibble first
        call    nibbleto_hexascii 
        pop     eax
nibbleto_hexascii:
        and     eax,0fh         ;isolate nibble
        add     al,'0'          ;convert to ascii
        cmp     al,'9'          ;valid digit?
        jbe     hexdone          ;yes
        add     al,7            ;use alpha range
hexdone:
        mov     [edi],al        ;store result
        inc     edi             ;next position
        ret
  [section .text]
;*******

;--------------------------------------------------
%ifdef DEBUG
  global main,_start
main:
_start:
  nop
  mov	eax,0eh
  mov	edi,nibble_buf
  call	nibbleto_hexascii

  mov	eax,1eh
  mov	edi,byte_buf
  call	byteto_hexascii

  mov	eax,12efh
  mov	edi,word_buf
  call  wordto_hexascii

  mov	eax,1234cdefh
  mov	edi,dword_buf
  call  dwordto_hexascii

  mov	eax,1
  int	byte 80h
;--------
  [section .data]
nibble_buf: db 0
byte_buf:   dw 0
word_buf:   dd 0
dword_buf:  dd 0,0
            dd 0
%endif
    