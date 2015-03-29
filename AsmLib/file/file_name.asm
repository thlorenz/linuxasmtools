
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
  extern str_move

;****f* file/filename_extract *
;
; NAME
;>1 file
;    filename_extract - extract filename from full path
; INPUTS
;    esi = ptr to buffer for filename
;    edi = ptr to full path
; OUTPUT
;    esi points to end of full path
;    edi points to end end of extracted filename 
; NOTES
;    source file: file_name.asm
;<
;  * ----------------------------------------------
;*******
  global filename_extract
filename_extract:
  xor	eax,eax
fe_lpa:
  scasb			;scan for zero at end of full path
  jne	fe_lpa
  std
  mov	al,'/'
fe_lpb:
  scasb			;scan back to find last "/"
  jne	fe_lpb
  xchg	esi,edi
  add	esi,2
  cld
  call	str_move	;move filename
  ret
;****f* file/filepath_extract *
;
; NAME
;>1 file
;  filepath_extract - extract path from path + name
; INPUTS
;    edi = ptr to full path
;    esi = buffer for path storage
; OUTPUT
;    edi = ptr to end of extracted path
;    esi = ptr to end of full path
;    ebx = ptr inside full path to filename
; NOTES
;    source file: file_name.asm
;<
;  * ----------------------------------------------
;*******
  global filepath_extract
filepath_extract:
  push	edi
  xor	eax,eax
fe_lpc:
  scasb			;find zero at end of full path
  jne	fe_lpc
  std
  mov	al,'/'
fe_lpd:
  scasb			;find last "/"
  jne	fe_lpd
  add	edi,2
  mov	ebx,edi

  mov	edi,esi
  pop	esi
  cld
fe_lpx:
  lodsb
  stosb			;move path
  cmp	esi,ebx
  jne	fe_lpx
  mov	byte [edi],ah	;put zero at end of path
  ret
  	