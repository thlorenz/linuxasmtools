
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
  extern crt_clear,dword_to_l_ascii,crt_str
;****f* err/err_number *
; NAME
;>1 log-error
;  err_number - display error number
; INPUTS
;    eax = error number (either + or -)
; OUTPUT
;    none
; NOTES
;    clear screen, displays error number, waits for any key
;<
;  * ----------------------------------------------
;*******
 global err_number
err_number:
  push	eax
  mov	eax,30003730h		;get color
  call	crt_clear		;clear the screen
  pop	eax
  or	eax,eax
  jns	eh_10
  neg	eax
eh_10:
  mov	edi,err2      
  mov	esi,3
  call	dword_to_l_ascii
;
  mov	ecx,err1
  call	crt_str
  mov	ecx,err3
  call	crt_str
;
; read one key
;
  mov	eax,3			;read
  mov	ebx,1			;stdin
  mov	ecx,err2		;buffer
  int	80h
eh_exit:
  ret

 [section .data]
err1: db 0ah,'Error #'
err2: db 0,0,0,0
err3: db 0ah,'press <Enter> to continue',0ah,0