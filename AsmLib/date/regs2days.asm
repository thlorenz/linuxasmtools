
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
;****f* date/regs2days *
; NAME
;>1 date
;  regs2days - convert day,month,year to days since 1970
; INPUTS
;    edx = binary year 1970-2099
;    ah = binary month 1-12
;    al = binary day 1-31
; OUTPUT
;    eax = days elapsed since Jan 1 1970
; NOTES
;   source file: regs2days.asm
;<
; * ----------------------------------------------
;*******
  [section .text]
;  extern leap_check
  extern days_in_month
  extern leap_count
;
  global regs2days
regs2days:
  pusha
  mov	byte [month],ah
  xor	ecx,ecx
  mov	cl,al
  dec	ecx		;adjust for current day (not counted till over)
  mov	[sum],ecx	;set sum=days in current month
  mov	[year],edx
; now count up days in previous months this year
  mov	esi,1		;starting month
rd_10:
  dec	dword [month]
  jz	rd_20		;jmp if done
  mov	ebx,esi
  call  days_in_month
  xor	eax,eax
  mov	al,bl
  add	[sum],eax
  inc	esi		;mov to next month
  jmp	rd_10		;loop back for next month
; compute number of previous leap years
rd_20:
  mov	eax,[year]
  call	leap_count
  add	[sum],eax	;add in all leap days
; compute days in previous years
  mov	eax,[year]
  sub	eax,1970
  mov	ebx,365
  mul	ebx		;years * 365
  add	[sum],eax	;sum = total days
  popa
  mov	eax,[sum]
  ret    

  [section .data]
year	dd	0
month	dd	0
sum	dd	0
  [section .text]

