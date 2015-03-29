
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
;****f* env/env_shell *
; NAME
;>1 env
;  env_shell - search enviornment for SHELL=
; INPUTS
;    edx = ptr to buffer (shell path storage)
; OUTPUT
;    [edx] - contains SHELL= string or /bin/sh if
;            not found
;     edi - points to end of stored string
; NOTES
;   source file: env_shell.asm
;<
; * ----------------------------------------------
;*******
  extern find_env_variable,str_move
  global env_shell
env_shell:
  mov	ecx,shell_var
  mov	byte [edx],0		;preload not found state
  call	find_env_variable
  cmp	byte [edx],0
  jne	fs_exit
;
; variable was not found
;
  mov	esi,shell_default
  mov	edi,edx			;get storage buffer ptr
  call	str_move  
fs_exit:
  ret

shell_var	db 'SHELL',0
shell_default	db '/bin/sh',0
