
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
;****f* date/get_raw_time *
; NAME
;>1 date
;  get_raw_time - get raw time from kernel
; INPUTS
;    none
; OUTPUT
;    eax - raw seconds since Jan 1 1970
;    ebx - raw microseconds
; NOTES
;   source file: get_raw_time.asm
;    
;   see date_get function before using this function.
;<
; * ----------------------------------------------
;*******


  [section .text]
;
  global  get_raw_time
get_raw_time:
	xor	ecx, ecx	;no time zone record 
	mov	ebx, sys_raw_seconds	;store seconds & microseconds here
	mov	eax,78
	int	80h
	mov	eax,[sys_raw_seconds]		;get seconds
	mov	ebx,[sys_raw_seconds + 4]	;get microseconds
	ret	

  [section .data]
sys_raw_seconds:  dd	0,0
  [section .text]

  [section .text]