
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
;****f* date/raw2ascii *
; NAME
;>1 date
;  raw2ascii - apply zone adjustment to raw system time
; INPUTS
;    eax = raw system time from get_raw_time or file status
;    edi = destination for ascii
;    ebx = format string for ascii output, terminated by zero byte.
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
;      9  -stuff 3 letter zone code
;    example:  db "0-1-2 3:4:5",0  displays year-month-day hour:minute:sec
; OUTPUT
;    ebx - points to time struc (in temporary lib buffer lib_buf)
;      struc time
;       .ct:		resd	1	; raw C time (seconds since the Epoch)
;       .at:		resd	1	; zone adjusted seconds since last Epoch
;       .zo:		resd	1	; time zone offset
;       .zi:		resb	6	; time zone identifier
;       .tz:		resb	10	; time zone name
;       .dc:		resd	1	; days since last Epoch
;       .sc:		resd	1	; seconds
;       .mn:		resd	1	; minutes
;      .hr:		resd	1	; hours
;      .yr:		resd	1	; year
;      .mr:		resd	1	; meridian (0 for AM)
;      .wd:		resd	1	; day of the week (Sunday=0, Saturday=6)
;      .dy:		resd	1	; day of the month
;      .mo:		resd	1	; month (one-based)
;    edi - points to end of stored ascii string
;    ebp - points to end of format string
;    all other registers are not preserved
;    the temp library buffer lib_buf has time structure
; NOTES
;   source file: raw2ascii.asm
;   UNIX system time and file times need to be adjusted by local zone.
;<
; * ----------------------------------------------
;*******

%include "time.inc"

  [section .text];-----------------------------------------------------------

  extern raw2seconds
  extern seconds2bins
  extern bins2ascii
  extern lib_buf

  global raw2ascii
raw2ascii:
  push	edi			;ascii output buffer
  push	ebx			;save format string
  mov	edi,lib_buf+400	;front of lib_buf used later, use end
  call	raw2seconds
  mov	ebp,lib_buf+400	;use end of sceenline
  call	seconds2bins
  mov	ebx,ebp			;data struc ptr -> ebx
  pop	ebp
  pop	edi
  call	bins2ascii
  ret