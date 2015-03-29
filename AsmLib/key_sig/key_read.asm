;-------------------------------------------------

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
;   along with this program.  If not, see <http://www.gnu.org/licenses/.


  [section .text align=1]

  extern ks1,ks2

struc termio_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termio_struc_size:

;---------------------------------------------------
;>1 key_sig
;key_flush - flush any pending keys
; INPUT
;   event_setup must be called first to set
;   keyboard in raw mode to flush keys
; OUTPUT
;   none
; NOTE 
;   source file key_read.asm
;   The "key" routines work together and other keyboard
;   functions should be avoided.  The "key" family is:
;   key_fread - flush and read
;   key_read - read key
;   key_check - check if key avail.
;   key_put - push a key back to buffer
;<
;-----------------------------------------------------
  global key_flush
key_flush:
  xor	eax,eax
  mov	[ks1],eax
  mov	[ks2],eax
  ret

;---------------------------------------------------
;>1 key_sig
;key_remove - delete key in ks1 buffer
; INPUT
;   keyboard must be in raw mode to read individual
;   keys.  See key_raw and key_unraw funtions.
; OUTPUT
;   ecx=ptr to key string or zero if no keys avail
;     if mouse press, key string format is:
;        ff,bb,cc,rr (flag,button,column,row)
;        where: ff =   -1 (byte)
;               bb =   (byte) 0=left but  1=middle 2=right 3=release
;               cc =   binary column (byte)
;               rr =   binary row (byte)
; NOTE
;      source file key_read.asm
;<
;-----------------------------------------------------------    
  extern sys_read
  global key_remove
key_remove:
  mov	ecx,ks1
  cmp	[ecx],byte 0
  jne	kr_exit		;jmp if key found
  xor	ecx,ecx		;set no keys avail
  jmp	short kr_exit2	;exit if no keys
kr_exit:
  mov	edi,ks1		;move ks2 to ks1
  mov	esi,ks2
  movsd
  movsd
  movsd
  movsd
  mov	[ks2],byte 0	;set ks2 empty
kr_exit2:
  ret
