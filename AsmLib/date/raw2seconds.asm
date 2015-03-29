
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
;****f* date/raw2seconds *
; NAME
;>1 date
;  raw2seconds - apply zone adjustment to raw system time
; INPUTS
;    eax = raw system time from get_raw_time
;    edi = pointer to short form of time structure
;      struc time
;       .ct:		resd	1	; raw C time (seconds since the Epoch)
;       .at:		resd	1	; zone adjusted seconds since last Epoch
;       .zo:		resd	1	; time zone offset
;       .zi:		resb	6	; time zone identifier
;       .tz:		resb	10	; time zone name
; OUTPUT
;    eax - seconds since Jan 1 1970 adjusted for zone
;    also, fields .ct through .tz are filled out if zone data found.
;    if zone not found, only .ct .at .zo and .zi are filled in
; NOTES
;   source file: raw2seconds
;   UNIX system time and file times need to be adjusted by local zone.
;<
; * ----------------------------------------------
;*******

%include "time.inc"

  [section .text];-----------------------------------------------------------

  extern mmap_open_ro
  extern lib_buf

  global raw2seconds
raw2seconds:
  mov	[edi + time.ct],eax		;save raw time
  xor	eax,eax
  mov	[edi+time.zo],eax		;clear .zo
;  xor	edx,edx
;  cmp	edx,[byte edi + time.tz]	;check if zone info avail
;  jnz	skipzoning

  mov	eax,[zone_file_ptr]		;get previously saved ptr
  or	eax,eax				;check if saved previously
  jnz	extract_zone_info		;jmp if ptr found
  mov	ebx,tzfilename		;/etc/localtime
  mov	edx,lib_buf
  call	mmap_open_ro			;returns ptr to file data in ecx
  mov	edx,0				;;
  mov	eax,ecx
  js	skipzoning

; At the top of the localtime file is a sequence of integers
; indicating the size of the various parts of the file. Following
; this is a list of time changes for this zone. (See tzfile(5) for a
; fuller description of the structure of this file.) The program runs
; through the list backwards, finding the current subsequence of
; linear time.
  mov	[zone_file_ptr],eax
extract_zone_info:
  mov	ebx, [byte eax + 32]
  bswap	ebx
  mov	esi, [byte eax + 36]
  bswap	esi
  lea	esi, [esi*2 + esi]
  mov	ecx, ebx
  add	eax, byte 44
.tmchgloop:
  dec	ecx
  jz	.tmchgloopexit
  mov	edx, [eax + ecx*4]
  bswap	edx
  cmp	edx, [edi + time.ct]
  jg	.tmchgloop
.tmchgloopexit:

; The index of the current subsequence gives us the offset into the
; next array, which itself contains indexes into the array of the
; current attributes of the time zone. These attributes give the
; offset from GMT in seconds (which is stored in zo), a flag
; indicating whether or not Daylight Savings is in effect, and a
; pointer to the current time zone's name (which is stored in tz).

  lea	eax, [eax + ebx*4]
  movzx	ecx, byte [eax + ecx]
  add	eax, ebx
  lea	ecx, [ecx*2 + ecx]
  mov	edx, [eax + ecx*2]
  bswap	edx
  mov	[edi + time.zo], edx
  movzx	ecx, byte [byte eax + ecx*2 + 5]
  lea	eax, [eax + esi*2]
  fild	qword [eax + ecx]
  fistp	qword [edi + time.tz]

; The current offset from GMT in seconds is then changed into hours
; and minutes. These are used to create a string of the form +HHMM,
; stored in zi.

skipzoning:
  mov	al, '+'
  or	edx, edx
  jns	.eastward
  mov	al, '-'
  neg	edx
.eastward:
  mov	[edi + time.zi], al
  xchg	eax, edx
  cdq
  lea	ebx, [byte edx + 60]
  div	ebx
  cdq
  div	ebx
  aam
  xchg	eax, edx
  aam
  shl	edx, 16
  lea	eax, [edx + eax + '0000']
  bswap	eax
  mov	[edi + time.zi + 1], eax

; The current time is loaded into eax, the offset for the time zone
; is applied. If this makes the current time negative, a year is
; added to the time, and the start of the Epoch is moved back. The
; day of the week of the start of the Epoch is stored in esi and on
; the stack.

;	mov	ecx, 1969;
;	mov	eax, [edi+time.ct]		;top of tmf;
;	add	eax,[edi+time.zo]
;	jge	.positivetime
;	add	eax, 365 * 24 * 60 * 60
;	dec	ecx
;.positivetime:
;	mov	[edi+time.at],eax	;save adjusted time *******************


  mov	eax, [edi + time.ct]
  add	eax, [edi + time.zo]
  jge	.positivetime
  mov	eax,0			;force epoch time if negative
.positivetime:
  mov	[edi + time.at],eax		;save adjusted seconds
  ret

; The pathname of the time zone file.

tzfilename:	db	'/etc/localtime', 0

  [section .data]
zone_file_ptr	dd	0
