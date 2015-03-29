
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


;-----------------------------------------------
;>1 compress
;  encrypt - simple string encryption
; INPUTS
;    ah = key
;    esi = ptr to ascii string
;    edi - destination for encrypted string (terminating 0 encrypted)
; OUTPUT:
;    esi = ptr to end of input string (past zero byte)
;    edi = ptr to end of stored string (past zero byte)
; NOTES
;   source file: encrypt.asm
;   This routine is not secure, but may be useful for
;   casual encription.
;<
; * ----------------------------------------------
  global encrypt
encrypt:
  mov	al,ah
en_loop:
  xor	al,[esi]
  rol	al,3
  inc	al
  stosb
  inc	esi
  cmp	[esi-1],byte 0
  jnz	en_loop
  ret 	
