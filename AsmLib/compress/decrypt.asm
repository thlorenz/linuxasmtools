
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
;  decrypt - move ascii data and decrypt
; INPUTS
;     ah = key
;    esi = ptr to ascii string
;    edi - destination for decrypted output string
; OUTPUT:
;    esi = ptr to end of input string (past zero byte)
;    edi = ptr to end of stored string (past zero byte)
; NOTES
;   source file: pak.asm
;<
; * ----------------------------------------------
  global decrypt
decrypt:
  lodsb
  dec	al
  ror	al,3
  xor	al,ah
  stosb
  mov	ah,[esi-1]
  jnz	decrypt
  ret
