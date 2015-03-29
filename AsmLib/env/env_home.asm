
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

  [section .text]

;****f* env/env_home *
;
; NAME
;>1 env
;  env_home - search the enviornment for $HOME
; INPUTS
;     ebx = ptr to list of env pointers
;     edi = buffer to store $HOME contents
; OUTPUT
;    edi = ptr to zero at end of $HOME string
; NOTES
;    file:  env_home.asm (see also build_homepath)
;<
;  * ----------------------------------------------
;*******
  global env_home
env_home:
  or	ebx,ebx
  jz	fh_50		;jmp if home path not found
  mov	esi,[ebx]
  or	esi,esi
  jz	fh_50		;jmp if home path not found
  cmp	dword [esi],'HOME'
  jne	fh_12		;jmp if not found yet
  cmp	byte [esi + 4],'='
  je	fh_20		;jmp if HOME found
fh_12:
  add	ebx,byte 4
  jmp	short env_home		;loop  back and keep looking
fh_20:
  add	esi, 5		;move to start of home path
;
; assume edi points at execve_buf
;
  call	str_move
fh_50:
  ret  
