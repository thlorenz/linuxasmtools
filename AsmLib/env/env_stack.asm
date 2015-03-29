
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

  extern enviro_ptrs

;****f* env/env_stack *
; NAME
;>1 env
;  env_stack - find stack ptrs to enviornment
; INPUTS
;    esp = stack ptr before any pops or pushes
; OUTPUT
;    ebp = ptr to enviroment pointers
;    [enviro_ptrs] set also
; NOTES
;    source file:  env_stack.asm
;<
;  * ----------------------------------------------
;*******
  global env_stack
env_stack:
  cld
  mov	esi,esp
es_lp:
  lodsd
  or	eax,eax
  jnz	es_lp		;loop till start of env ptrs
  mov	ebp,esi
  mov	[enviro_ptrs],esi
  ret
