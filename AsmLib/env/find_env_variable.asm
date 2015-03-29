
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
  [section .text]
;---------------------------------------
;****f* env/find_env_variable *
; NAME
;>1 env
;  find_env_variable - search enviornment for variable name
; INPUTS
;    [enviro_ptrs] - setup by env_stack
;    ecx = ptr to variable name (asciiz)
;    edx = storage point for variable contents
; OUTPUT
;    data stored at edx, if edi is preloaded with
;    a zero it can be checked to see if variable found
;    edi - if success, edi points to end of varaible stored
; NOTES
;   source file:  find_env_variable.asm
;<
; * ----------------------------------------------
;*******
  extern enviro_ptrs,str_move,str_match
  global find_env_variable
find_env_variable:
  mov	ebx,[enviro_ptrs]
fev_10:
  or	ebx,ebx
  jz	fev_50
  mov edi,[ebx]
  or	edi,edi
  jz	near fev_50
  mov	esi,ecx		;get input variable name ptr
  call	str_match
  jne fev_12
  cmp [edi],byte '='
  je fev_20		;jmp if var= found
fev_12:
  add ebx,byte 4
  jmp short fev_10
;
; match found, store it
;
fev_20:
  inc	edi		;move past "="
  mov	esi,edi
  mov	edi,edx
  call	str_move
fev_50:
  ret
