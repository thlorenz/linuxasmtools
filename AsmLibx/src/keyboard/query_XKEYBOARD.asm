;-----------------------------------------------------------------------
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

 extern x_query_extension


;---------------------
;>1 xtest
;  query_XKEYBOARD - get XKEYBOARD op code
; INPUTS
;    none
; OUTPUT:
;    failure - eax = negative error code
;              flags set for "js"
;    success - eax = XKEYBOARD op code
;              
; NOTES
;   source file: query_XKEYBOARD.asm
;<
; * ----------------------------------------------

  global query_XKEYBOARD
query_XKEYBOARD:
  mov	eax,[saved_query]
  or	eax,eax
  jnz	qx_exit2		;exit of already set

  mov	esi,query_text
  mov	ecx,5
  call	x_query_extension
  mov	[saved_query],eax
qx_exit2:
  or	eax,eax
  ret


  [section .data]
saved_query:	dd 0
query_text	db 'XKEYBOARD'
  [section .text]

