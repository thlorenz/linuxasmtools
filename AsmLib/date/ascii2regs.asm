
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
;****f* date/ascii2regs *
; NAME
;>1 date
;  ascii2regs - convert ascii year,month,day to bin year,month,day
; INPUTS
;    esi = ptr to ascii string "yyymmdd" without separators
; OUTPUT
;    edx = binary year
;    ah = binary month 1-12
;    al = binary day of month 1-31
; NOTES
;   source file: ascii2regs.asm
;<
; * ----------------------------------------------
;*******
  extern ascii_to_dword

  [section .text]
;
  global ascii2regs
ascii2regs:
  lodsd				;get year
  mov	[ayear],eax
  lodsw
  mov	[amonth],ax
  lodsw
  mov	[aday],ax

  mov	esi,ayear
  call	ascii_to_dword		;get bin year
  push	ecx			;save year
  mov	esi,amonth
  call	ascii_to_dword  	;get bin month
  push	ecx			;save month
  mov	esi,aday
  call	ascii_to_dword  	;get bin day
;
; convert date to days since 1970
;
  mov	al,cl			;position day_of_month
  pop	edx			;get month
  mov	ah,dl			;position month_number
  pop	edx			;get year
  ret

;---------------
  [section .data]
ayear	db	'xxxx',0
amonth	db	'xx',0
aday	db	'xx',0
  [section .text]
