
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
;%define DEBUG
; parse_token.asm
  extern lib_buf

  [section .text]
;****f* sys/parse_token *
; NAME
;>1 str_parse
;  parse_token - scan buffer for next token
; INPUTS
;    eax = pointer to writable input block
;
;    input block definition
;      dd <pointer to scan buffer start>
;      dd <pointer to scan buffer end>
;      db <separator character list>
;         eol (0ah) is assumed separator and
;         should not be on list.  List appears
;         as:  db " ","x",0  Last zero byte terminates
;      db 0 ;end of separator list
;
; OUTPUT
;    if <zero flag> token parsed and lib_buf holds token.
;                   The token is terminated with zero char.
;                   The input block scan start is updated
;                   to point at token end (separator char).
;       <carry flag> the end of line was reached at
;                   last parse, or no tokens on this line.
;       <sign flag> The end of scan buffer has been reached,
;                   no more tokens available.
;
;    all registers are unchanged
;
; NOTES
;   source file: parse_token.asm
;<
; * ----------------------------------------------
;*******
  global parse_token
parse_token:
  pusha
  mov	ecx,eax		;save block ptr
  mov	esi,[eax]	;get scan buffer ptr
  mov	ebp,[eax+4]	;get end of scan buffer
  lea	ebx,[eax+8]	;get ptr to separator characters
  mov	edi,lib_buf	;output stuff
  cmp	esi,ebp
  jb	pt_05		;jmp if not end of buffer
  sub	eax,ebx		;set sign big  
  jmp	short pt_exit	;sign bit set
pt_05:
  cmp	byte [esi],0ah	;end of line
  jne	pt_10		;jmp if not eol
  inc	esi		;move to next char
  stc
  jmp	pt_exit
;scan for token esi=scan start edi=block end ebx=separators
;remove all separators at start of token first
pt_10:
  call	is_separator	;returns char in al, flags
  jnc	pt_20		;jmp if non separator found
;  inc	esi		;move past separator
  cmp	esi,ebp		;end of buffer
  jae	pt_exit		;exit with sign bit set (end of buf)
  cmp	al,0ah		;check of eol
  jne	pt_10
  or	al,al		;clear zero flag, clear sign flag
  stc
  jmp	short pt_exit
;we are at start of token, move to lib buf
pt_20:
  stosb			;store char
  call	is_separator
  jnc	pt_20		;jmp if token body
;we have found end of token
  dec	esi		;move back
  mov	[edi],byte 0	;terminate token string
  xor	eax,eax		;set zero flag for exit
pt_exit:
  mov	[ecx],esi	;store new buffer ptr
  popa
  ret  

;---------------------------------------
; inupts:
;   esi=buf ptr  ebx=separator charactors  ebp=buffer end  edx available
; outputs:
;   esi=next char ptr, jc flag set if last char was separator
;                      or end of buffer found
;       
is_separator:
  mov	edx,ebx		;get ptr to separators
  lodsb			;get char from buffer
is_lp:
  cmp	esi,ebp
  ja	is_exit2	;end of buf = separator
  cmp	byte [edx],0
  je	is_exit1	;jmp if not separator
  cmp	al,0ah
  je	is_exit2	;eol
  cmp	al,[edx]	;separator
  je	is_exit2	;jmp if separator found
  inc	edx
  jmp	short is_lp
is_exit2:
  stc
  jmp	short is_exit
is_exit1:
  clc			;set non-separator flag
is_exit:
  ret
  [section .text]
;---------------------------------------
