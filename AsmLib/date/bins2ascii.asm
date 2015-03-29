
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
; bins2ascii - format date
;  input: ebx = time/date data structure pointer
;         ebp = format string pointer
;         edi = output buffer pointer
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
;      9  -stuff 3 letter zone code
;<

%include "time.inc"

  extern str_move
  extern is_number
  extern dword_to_lpadded_ascii
  extern day_name
  extern month_name

  global bins2ascii
bins2ascii:			;beware, recursion here
  cmp	byte [ebp],0
  je	df_exit		;exit if done
  xor	eax,eax
  mov	al,[ebp]
  inc	ebp
  call	is_number
  jne	df_stuff
  and	al,0fh
  shl	eax,2
  add	eax,fmt_process_tbl
  call	[eax]
  jmp	short bins2ascii
df_stuff:
  stosb
  jmp	short bins2ascii
df_exit:
  ret

fmt_process_tbl:
  dd	process_year	;0
  dd	process_month	;1
  dd	process_day_of_month ;2
  dd	process_hour	;3
  dd	process_minute	;4
  dd	process_second	;5
  dd	process_month_name ;6
  dd	process_day_name ;7
  dd	process_am_pm	;8
  dd	process_zone	;9

process_year:
  mov	eax,[ebx + time.yr]
  mov	cl,4		;store 4 digets
  jmp	short pn2

process_month:	;1
  mov	eax,[ebx + time.mo]
  and	eax,0ffh
  jmp	short pn1

process_day_of_month: ;2
  mov	eax,[ebx + time.dy]
  and	eax,0ffh
  jmp	short pn1

process_hour:	;3
  mov	eax,[ebx + time.hr]
  and	eax,0ffh
  jmp	short pn1

process_minute:	;4
  mov	eax,[ebx + time.mn]
  and	eax,0ffh
  jmp	short pn1

process_second:	;5
  mov	eax,[ebx + time.sc]
  and	eax,0ffh
pn1:
  mov	cl,2		;store 4 digets
pn2:
  mov	ch,'0'		;pad char
  push	ebx
  push	ebp
  call	dword_to_lpadded_ascii
  pop	ebp
  pop	ebx
  ret

process_month_name: ;6
  mov	ecx,[ebx + time.mo]
  and	ecx,0ffh
  call	month_name
  jmp	short pn3

process_day_name: ;7
  mov	ecx,[ebx + time.wd]
  and	ecx,0ffh
  call	day_name
pn3:
  mov	al,[ebp]	;get +/- flat
  inc	ebp		;move to next fmt char
  cmp	al,'-'
  je	p_truncate
  call	str_move
  ret
p_truncate:
  movsb
  movsb
  movsb
  ret

process_am_pm:	;8
  mov	ax,'AM'
  mov	cl,[ebx + time.mr]
  or	cl,cl
  jz	pap_stuff
  mov	ax,'PM'
pap_stuff:
  stosw
  ret
  
process_zone:	;9
  lea	esi,[ebx+time.tz]
  call	str_move
  ret
