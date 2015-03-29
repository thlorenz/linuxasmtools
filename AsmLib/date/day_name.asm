
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
;****f* date/day_name *
; NAME
;>1 date
;  day_name - lookup name for day
; INPUTS
;    ecx = day code, 0=sun 1=mons etc.
; OUTPUT
;    esi = pointer to full asciiz name.
;    
; NOTES
;   source file: day_name.asm
;<
; * -
; * ----------------------------------------------
;*******

  [section .text]
;
  global day_name
day_name:
  mov	esi,day_list
nd_lp1:
  jecxz	nd_done
nd_lp2:
  lodsb
  or	al,al
  jnz	nd_lp2	
  dec	ecx
  jmp	nd_lp1
nd_done:
  ret

day_list:
  db	'Sunday',0
  db	'Monday',0
  db	'Tuesday',0
  db	'Wednesday',0
  db	'Thursday',0
  db	'Friday',0
  db	'Saturday',0
