
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
  extern key_poll
  extern read_one_byte
  extern kbuf_end

; NAME
;>1 terminal
;  key_flush - remove keys from stdin
; INPUTS
;    keyboard must be in raw mode
; OUTPUT
;    none
; NOTES
;   source file: key_flush.asm
;<
; * ----------------------------------------------
;*******
;------------------------------------------
; flush keyboard
;
  global key_flush
key_flush:
  mov	ecx,(kbuf_end -1)
  call	key_poll
  jz	fk_done			;jmp if no more keys
  call	read_one_byte
  jmp	short key_flush
fk_done:
  ret
