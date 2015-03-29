
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

;****f* date/days_in_month *
; NAME
;>1 date
;  days_in_month - returns number of days in month
; INPUTS
;    bl = binary month number, 1=january
;    edx = binary year
; OUTPUT
;    bl =  number of days in month
; NOTES
;   source file: days_in_month.asm
;<
; * ----------------------------------------------
;*******
  extern leap_check

  [section .text]
;
  global days_in_month
days_in_month:
        push	edx
        xor	eax,eax
	mov	al,bl
	mov	bl,[eax + day_in_month -1]
	cmp	bl,28		;is this feb
	pop	eax
	jne	md_exit
	call	leap_check	;adjust for leap year
	jnc	md_exit
	inc	bl
md_exit:
	ret

 global day_in_month
day_in_month:
	db	31		;days in January
	db	28		; February
	db	31		;days in March
	db	30		;days in April
	db	31		;days in May
	db	30		;days in June
	db	31		;days in July
	db	31		;days in August
	db	30		;days in September
	db	31		;days in October
	db	30		;days in November
	db	31		;days in December

