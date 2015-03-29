
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
;----------------------------------------------------------
;****f* date/month_name *
; NAME
;>1 date
;  month_name - lookup name for month
; INPUTS
;    ecx = month code, 1=january 2= feb etc.
; OUTPUT
;    esi = pointer to full asciiz name.
; NOTES
;   source file: month_name.asm
;<
; * -
; * ----------------------------------------------
;*******
  [section .text]
;
  global month_name
month_name:
  mov	esi,month_list
nm_lp1:
  dec	ecx
  jecxz	nm_done
nm_lp2:
  lodsb
  or	al,al
  jnz	nm_lp2	
  jmp	nm_lp1
nm_done:
  ret

month_list	db	'January',0
  db	'February',0
  db	'March',0
  db	'April',0
  db	'May',0
  db	'June',0
  db	'July',0
  db	'August',0
  db	'September',0
  db	'October',0
  db	'November',0
  db	'December',0

