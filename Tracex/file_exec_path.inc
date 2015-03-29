
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

extern str_end
extern str_move
extern enviro_ptrs
extern file_access
extern env_exec
;---------------------
;>1 file
;  file_exec_path - build full path to executable
; INPUTS
;    esi = ptr to buffer with file name.  It will
;          be replaced with full path name. If full
;          path is entered, it will be checked for
;          access rights.
; OUTPUT:
;    carry set if error - file not executable
;                         or env_stack call needed
;    no carry = full path for executable in buffer
;
; NOTES
;   source file: file_exec_path.asm
;   The input buffer must be big enough to hold
;   the full path to executable file.
;   lib_buf is used as work buffer.  
;<
; * ----------------------------------------------
;--------------------
; inputs: ebx=ptr to name
  global file_exec_path
file_exec_path:
  mov	[parse_ptr],esi
  cmp	byte [esi],'/'		;check if full path
  je	sys_full		;jmp if esi points to full path + parameters
;get local path
  mov	eax,183		;kernel call getcwd
  mov	ebx,lib_buf+200
  mov	ecx,200		;lenght of buffer
  int	80h
;add filename and all parameters to end of path
  mov	esi,ebx
  call	str_end
  mov	edi,esi
  mov	al,'/'
  stosb
  mov	esi,[parse_ptr]
  call	str_move
;check if we have execute access to file
  mov	eax,33		;kernel access call
  mov	ecx,1		;modes read & write & execute
  mov	ebx,lib_buf+200
  int	80h
  or	eax,eax
  jnz	try_path	;jmp if failure
;success - move local path to input buffer
  mov	esi,lib_buf+200
  mov	edi,[parse_ptr]
  call	str_move
  jmp	spa_pass
;
; this is not a local executable or full path,
; try searching the path
;
try_path:
  mov	ebx,[enviro_ptrs]
  or	ebx,ebx
  jz	spa_fail			;jmp if pointer setup
  mov	ebp,[parse_ptr]
  call	env_exec
  jc	spa_fail			;jmp if name not found
  mov	esi,ebx			;esi=ptr to full path of executable
  mov	edi,[parse_ptr]
  call	str_move
  jmp	spa_pass
;
;full path plus parameters at -esi-
;
sys_full:
  mov	ebx,[parse_ptr]
  mov	ecx,1			;execute access check
  call	file_access
  or	eax,eax
  jnz	spa_fail
spa_pass:
  clc
  jmp	short spa_done
spa_fail:
  stc
spa_done:
  ret
;-------------
  [section .data]
parse_ptr:  dd	0	;ptr to entry strings
  [section .text]
;------------------------------------------------------------
