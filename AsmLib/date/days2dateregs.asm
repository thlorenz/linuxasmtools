
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
;****f* date/days2dateregs *
; NAME
;>1 date
;  days2dateregs - convert days to week,day,month, etc.
; INPUTS
;    eax = days since jan 1 1970
; OUTPUT
;    eax days_since_1970 - total days since 1970
;    dh  [day_of_week] - 0=wednesday 1=thursday...-> 0=sunday
;    ebx year - current year
;    dl  day_of_month - 1 based
;    esi month_number - 1 based
; NOTES
;   source file: days2dateregs.asm
;<
; * -
; * ----------------------------------------------
;*******
  extern leap_check
  extern days_in_month
;
  global days2dateregs
days2dateregs:
  mov	[days_since_1970],eax
;
; now compute the day of the week
;
  xor	edx,edx
  mov	ebx,7
  div	ebx
  or	edx,edx			;check if remainder
  mov	[day_of_week],dl	;0=wednesday 1=thursday 2=friday
;
; determine current year
;
  mov	ecx,[days_since_1970]
  mov	edi,1969	;starting year
yr_lp:
  inc	edi		;start with year 1970+
  mov	ebx,365		;days in non-leap year
  mov	eax,edi		;year -> eax
  call	leap_check
  jnc	not_leap	;jmp if not leap year
  mov	ebx,366		;days in leap year
not_leap:
  sub	ecx,ebx		;remove days for this year
  jnc	yr_lp		;jmp if more days remain for removal
yr_done:
  add	ecx,ebx		;restore days
  
;  mov	[year],edi	;save year
;
; edi = current year
; ecx = day of year
; ebx = 365 if normal year 364 if leap year
;
  mov	esi,0		;sub month days starting with feb
month_loop:
  inc	esi		;start with feb (1)
  mov	eax,edi		;year to eax
  mov	ebx,esi		;month# to dl
  call	days_in_month
  sub	ecx,ebx		;sub month days from days in year
  jnc	month_loop	;loop if more days remain
  add	ecx,ebx		;restore 
;
; edi = current year
; ecx = day of month
; esi = month#

  inc	ecx		;adjust month day to be 1 based
  mov	eax,[days_since_1970]
  mov	ebx,edi		;current year to ebx
; mov	esi,esi		;month#
  mov	edx,ecx		;day of month to dl
  mov	dh,[day_of_week]

  add	dh,4			;adjust day of week (see .adw)
  cmp	dh,7			;too much?
  jb	s_done			;jmp if done
  sub	dh,7			;fix day of week
s_done:
  ret

 [section .data]
;year dd	0
days_since_1970 dd	0	;days since 1970
day_of_week dd 0

