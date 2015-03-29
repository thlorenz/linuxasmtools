
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
;****f* date/days2ascii *
; NAME
;>1 date
;  days2ascii - convert days to week,day,month, etc.
; INPUTS
;    eax = days since jan 1 1970
;    ebx = buffer for ascii output
;    ebp = format template for ascii output
;    the format string contains two types of data.  Numeric
;    codes "0123456789" and non-numberic ascii characters.
;    Non-numberic characters are passed to the output and
;    not modified.  Any numberic character found is processed
;    as follows:
;      0  -stuff ascii year
;      1  -stuff ascii month
;      2  -stuff ascii day of month
;      6- -stuff short month name
;      6+ -stuff long month name
;      7- -stuff short day of week name
;      7+ -stuff long day of week name
; OUTPUT
;          edi - points at end of output string
;          ebp - points at end of format string
;  Note: the termporary library buffer "lib_buf" is utilized.
;    
; NOTES
;    source file: days2ascii.asm
;<
;  * -
;  * ----------------------------------------------
;*******
;
  extern days2dateregs
  extern regs2ascii

  global days2ascii
days2ascii:
  push	ebx		;save buffer for ascii
  call	days2dateregs
  pop	eax
  call	regs2ascii
  ret
	