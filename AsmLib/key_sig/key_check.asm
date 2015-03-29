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

  extern tty_fd
  extern lib_buf


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
  extern ks1
;---------------------------------------------------
;>1 key_sig
;key_check - check if key available, but do not read it
; INPUT
;   we must be in raw mode
; OUTPUT
;   ecx=zero if no keys
;   ecx=ptr to key string if key avail.
; NOTE
;    source file key_check.asm
;    he "key" routines work together and other keyboard
;    functions should be avoided.  The "key" family is:
;    key_fread - flush and read
;    key_read - read key
;    key_check - check if key avail.
;    key_put - push a key back to buffer
;<

  global key_check
key_check:
  mov	ecx,ks1		;any keys waiting
  cmp	[ecx],byte 0
  jne	kc_exit		;exit if key avail
  xor	ecx,ecx
kc_exit:
  ret
