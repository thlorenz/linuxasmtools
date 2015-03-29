
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
;****f* date/seconds2bins *
;
; NAME
;>1 date
;  seconds2bins - convert seconds to year,month,day,hr, etc.
; INPUTS
;         ebp = ptr to time structure, see time.inc
;         [ebp + time.at] = adjusted seconds
;   
; OUTPUT
;    the time structure is filled in as follows:
;          [ebp + time.sc current seconds
;          [ebp + time.mn current minute
;          [ebp + time.hr current hour
;          [ebp + time.mr meridian 0=AM
;          [ebp + time.dc days since last epoch
;          [ebp + time.yr current year
;          [ebp + time.dy day of month
;          [ebp + time.mo month number, one based 
; NOTES
;    source file: seconds2bins.asm
;<
;  * ----------------------------------------------
;*******
;-----------------------------------------------------------------
;
%include "time.inc"
; eax holds the number of seconds since the Epoch. This is divided by
; 60 to get the current number of seconds, by 60 again to get the
; current number of minutes, and then by 24 to get the current number
; of hours.
  global seconds2bins
seconds2bins:
  mov	eax,[ebp + time.at]	;get adjusted seconds
  mov	esi,4			;get epoch day of week
  xor	edx,edx			;clear high dword 
  lea	ebx, [byte edx + 60]
  div	ebx
  mov	[ebp + time.sc], edx	;save current second
  cdq
  div	ebx
  mov	[ebp + time.mn], edx	;save current minute
  mov	bl, 24
  cdq
  div	ebx
  mov	[ebp + time.hr], edx	;save current hour

; The hours are also tested to determine the current side of the
; meridian, and the hours of the meridian.

  sub	edx, byte 12
  setae	byte [ebp + time.mr]	;save maridian 0=AM

; eax now holds the number of days since the Epoch. This is divided
; by seven, after offsetting by the value in esi, to determine the
; current day of the week.

  mov	[ebp + time.dc],eax	;save days since last Epoch
  add	eax, esi
  mov	bl, 7
  cdq
  div	ebx
  mov	[ebp + time.wd], edx	;save day of week 0=sunday
  mov	eax,[ebp + time.dc]	;get days since last Epoch

; A year's worth of days are successively subtracted from eax until
; the current year is determined. The program takes advantage of the
; fact that every 4th year is a leap year within the range of our
; Epoch.

  mov	bh, 1
  mov	ecx,1969		;get epoch year-1
.yrloop:
  mov	bl, 110
  inc	ecx
  test	cl, 3
  jz	.leap
  dec	ebx
.leap:
  sub	eax, ebx
  jge	.yrloop
  add	eax, ebx
  mov	[ebp + time.yr], ecx	;save current year

; eax now holds the day of the year, and this is saved in esi. ebx is
; altered to hold a string of pairs of bits indicating the length of
; each month over 28 days. Each month's worth of days are
; successively subtracted from eax until the current month, and thus
; the current day of the month, is determined.

  mov	esi, eax
  add	ebx, 11000000001110111011111011101100b - 365
  xor	ecx, ecx
  cdq
.moloop:
  mov	dl, 7
  shld	edx, ebx, 2
  ror	ebx, 2
  inc	ecx
  sub	eax, edx
  jge	.moloop
  add	eax, edx
  inc	eax
  lea	edi,[ebp + time.dy] ;get storage address for .dy
;  mov	ebp,edi
;  add	edi, time.dy
  stosd			;.dy day of month
  xchg	eax, ecx
  stosd			;.mo month, one based

  ret

