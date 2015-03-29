
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

;****f* str/str_search *
; NAME
;>1 str_cmp
;  str_search - search string for match
; INPUTS
;    esi = input asciiz string terminated with 0-9h
;    edi = string to search, terminated with 0-9h
; OUTPUT
;    carry set if no match
;    no carry if match and registers =
;      esi - points to end of matching string
;      edi - points to end of matched string
;      edx - points to start of matching string
;      ebx - points to start of matched string 
; NOTES
;   source file:  str_search.asm
;<
; * ----------------------------------------------
;*******
  global str_search
str_search:
  dec	edi    			;adjust buffer pointer for loop pre-bump
  mov	edx,esi			;save match string start
match_first_char:
  mov esi,edx			;restore match string start
  lodsb
  cmp	al,9
  jbe	notfound		;jmp if no string matches
;get first char from buffer
found1:
  inc	edi			;move forward in scan buffer
;compare string characters
found6:
  cmp al,byte [edi]		;check next char. in buffer
  jne found8			;loop if no match
;first char. matches, set ebx=match point
found2:
  mov ebx,edi
; start of matching loop
found3:
  lodsb			;get next match string char
  cmp	al,9		;=end?
  jbe	found		;done if match
found7:
  inc	edi
  cmp	byte [edi],9
  jbe	notfound	;exit if string not found
  cmp al,byte [edi]	;compare next char in buffer
  jz found3		;loop if match
  mov edi,ebx		;restore buffer scan location before partial match
  jmp	short match_first_char ;go restart match loop
found8:
  cmp byte [edi],9	;check if end of buffer
  ja	found1		;jmp if not end yet
notfound:
  stc
  ret
found:
  clc
  ret

