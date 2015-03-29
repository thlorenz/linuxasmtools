
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
;****f* date/seconds2dateregs *
; NAME
;>1 date
;  seconds2dateregs - convert seconds to week,day,month, etc.
; INPUTS
;    eax = seconds since jan 1 1970 
; OUTPUT
;    eax days_since_1970 - total days since 1970
;    dh  [day_of_week] - 0=wednesday 1=thursday...-> 0=sunday
;    ebx year - current year
;    dl  day_of_month - 1 based
;    esi month_number - 1 based
;    register ecx is restored 
; NOTES
;   source file: seconds2dateregs.asm
;    
;   see also date_get
;<
; * ----------------------------------------------
;*******


  [section .text]
  extern days2dateregs
;
  global seconds2dateregs
seconds2dateregs:
  push	edi
  push	ecx
;  mov	eax,[adjusted_seconds]
  xor	edx,edx
  mov	ebx,(24 * 60 * 60)
  div	ebx	;compute days since jan 1 1970
  call	days2dateregs
  pop	ecx
  pop	edi
  ret
