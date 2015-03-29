
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
;****f* date/seconds2timeregs *
; NAME
;>1 date
;  seconds2timeregs - seconds to hour,min,sec registers 
; INPUTS
;    eax = seconds since Jan 1 1970
; OUTPUT
;    eax = seconds since Jan 1 1970
;    edi - dword binary hour
;    cl  - dword binary minute
;    ch  - dword binary seconds
; NOTES
;   source file: seconds2timeregs.asm
;<
; * -
; * ----------------------------------------------
;*******
  
  [section .text]
;
  global seconds2timeregs
seconds2timeregs:
  push	eax
  xor	edx,edx
  mov	ebx,(24 * 60 * 60)
  div	ebx	;compute days since jan 1 1970
  inc	eax	;adjust for remainder (current day)
  mov	eax,edx	;edx = seconds today
  sub	edx,edx
  mov	ebx, 60 * 60
  div	ebx		;eax = hours  edx= seconds remaining
;
  push	eax		;save hours
  mov	eax,edx
  mov	ebx,60
  sub	edx,edx
  div	ebx		;eax = minute  edx=second
;
;  mov	[minute_today],eax
;  mov	[seconds_today],edx
  mov	ah,dl		;move seconds to ah
  mov	ecx,eax
  pop	edi		;get hours
  pop	eax		;restore seconds
  ret

