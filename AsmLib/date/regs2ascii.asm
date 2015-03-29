
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
;>1 date
; regs2ascii - format date
;  input: eax = output buffer for asciiz date string
;         ebp = format string pointer (see below)
;         ebx = year
;          cl = minute
;          ch = second
;          dl = day of month
;          dh = day of week
;         esi = month number
;         edi = hour
;         note: seconds2timeregs,seconds2dateregs can provide
;               year,month,day,hour,minute,sec and day of week
;  output: edi - points at end of output string
;          ebp - points at end of format string
; 
;    the format string contains two types of data.  Numeric
;    codes "0123456789" and non-numberic ascii characters.
;    Non-numberic characters are passed to the output and
;    not modified.  Any numberic character found is processed
;    as follows:
;      0  -stuff ascii year
;      1  -stuff ascii month
;      2  -stuff ascii day of month
;      3  -stuff ascii hour
;      4  -stuff ascii minute
;      5  -stuff ascii second
;      6- -stuff short month name
;      6+ -stuff long month name
;      7- -stuff short day of week name
;      7+ -stuff long day of week name
;      8  -stuff AM/PM
;
;  Note: the termporary library buffer "lib_buf" is utilized.
;<
%include "time.inc"

  extern str_move
  extern lib_buf
  extern bins2ascii

  global regs2ascii
regs2ascii:			;beware, recursion here
  mov	[lib_buf + time.yr],ebx
  mov	ebx,lib_buf
  mov	[ebx + time.hr],edi
  mov	[ebx + time.mn],cl
  mov	[ebx + time.sc],ch
  mov	[ebx + time.wd],dh
  mov	[ebx + time.dy],dl
  mov	[ebx + time.mo],esi
  mov	cl,0			;preload AM flag
  cmp	edi,12			;is hour over 12
  jbe	stuff1
  mov	cl,1			;get PM flag
stuff1:
  mov	[ebx + time.mr],cl ;save AM/PM flag
  
  mov	edi,eax			;move buffer pointer to edi
  call	bins2ascii
  ret

	