
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

  global	blk_find

;****f* blk/blk_find *
; NAME
;>1 blk
;  blk_find - search block of text for string
; INPUTS
;    ebp    end of file ptr(fwd search)  start of file(backwards search)
;    esi    match string
;    edi    search start ptr in buffer
;    edx    scan_direction +1 for forward -1 for reverse find
;    ch     case mask df=ignore case, ff=match case
; OUTPUT
;    ebx         match pointer if no carry (jnc match_found)
;    clobbered   ecx,eax,esi
; NOTES
;    The match string ends with zero and the buffer/block
;    end is put in register ebp if needed (forward search)
;<
;  * -----------------------------------------------------
;*******
;--------------------
;
blk_find:
  sub	edi,edx			;adjust buffer pointer for loop pre-bump
  mov	[find_str],esi
;                               ;adding "dec edi" kills find again.
ft_10:
;  mov ch,[case_mask]		;get case mask
  mov esi,[find_str]		;get match string
;  cld
  lodsb
  or	al,al
  jz	notfnd			;exit if no string entered
;adjust case of match str
  call	check_al_case 
;get first char from buffer
fnd1:
  add edi,edx			;edx = direction of find control
  mov cl,byte [edi]
;adjust case of buffer char
  call	check_cl_case
;compare string characters
fnd6:
  cmp al,cl
  jne fnd8			;loop if no match
;first char. matches, set ebx=match point
fnd2:
  mov ebx,edi
;
; start of matching loop
fnd3:
  lodsb			;get next match string char
  or al,al		;=end?
  jz fnd		;done if match
  call	check_al_case
fnd7:	inc edi
  or	edx,edx		;check if backwards search
  js	fnd7a		;jmp if  backwards search
  cmp	edi,ebp		;check if at end of file
  jae	notfnd		;exit if string not found
fnd7a:
  mov cl,byte [edi]	;get next buffer char
  call	check_cl_case
fnd10:
  cmp al,cl
  jz fnd3		;loop if match
  mov edi,ebx
  jmp ft_10
fnd8:
  or	edx,edx
  js	fnd9		;jmp if back search	
  cmp edi,ebp		;check if at end of file
  jae notfnd
  jmp	fnd1
fnd9:
  cmp edi,ebp		;check if at start of file
  jbe	notfnd
  jmp	fnd1
notfnd:
;  cmp	byte [replace_all_flag],0
;  jne	ft_80			;jmp if not special msg needed
;  mov	dword [special_status_msg_ptr],not_found_msg
ft_80:
  stc
  ret
fnd:
  mov edi,ebx
  clc
  ret
;------------------------
; input: al = ascii
;        ch = mask
check_al_case:
  cmp	al,"a"
  jb	cac_exit
  cmp	al,"z"
  ja	cac_exit
  and	al,ch
cac_exit:
  ret
;--------------------
check_cl_case:
  cmp	cl,"a"
  jb	ccc_exit
  cmp	cl,"z"
  ja	ccc_exit
  and	cl,ch
ccc_exit:
  ret

;------------------------

  [section .data]
find_str dd	0
  [section .text]
