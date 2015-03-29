
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
  extern lib_buf
  extern str_move
  extern env_exec  
  extern str_end
  extern enviro_ptrs
;----------------------
;>1 sys
; is_executable_on_path - check if executable available
; INPUTS
;         esi = ptr to executable file name
;         note: executable filename can be full path, local file
;               else the $PATH is searched for file.
;         note: call env_stack to setup enviro_ptrs at start of
;               program.           
; OUTPUT
;         al=0  if executable on path, esi=ptr to full path (in lib_buf+200)
;            1  if executable is local,esi=ptr to full path (in lib_buf+200)
;         al=-1 if file not executable, not found, or enviro_ptrs not setup
; NOTES
;    file /sys/executable_on_path.asm
;    lib_buf is used as work buffer.
;<
;-------------------------------------------------------------------
  global is_executable_on_path
is_executable_on_path:
  mov	edi,lib_buf + 400
  call	str_move
  mov	esi,lib_buf + 400
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
  call	append_entry_string
;check if we have execute access to file
  mov	eax,33		;kernel access call
  mov	ecx,1		;modes read & write & execute
  mov	ebx,lib_buf+200
  int	80h
  or	eax,eax
  jnz	search_path	;jmp if not local
  mov	al,1
  jmp	short spa_done

sys_full:
  mov	eax,33		;kernel access call
  mov	ecx,1		;modes read & write & execute
  mov	ebx,esi
  int	80h
  or	eax,eax
  jnz	spa_fail
  jmp	short fill_lib_buf
;
; this is not a local executable or full path,
; try searching the path
;
search_path:
  mov	ebx,[enviro_ptrs]
  or	ebx,ebx
  jz	spa_fail			;jmp if pointer setup
  mov	ebp,[parse_ptr]
  call	env_exec
  jc	spa_fail			;jmp if name not found
  mov	esi,ebx			;esi=ptr to full path of executable
fill_lib_buf:
  push	esi
  mov	edi,lib_buf+200
  call	str_move
  pop	esi
  xor	eax,eax
  jmp	short spa_done

spa_fail:
  mov	al,-1			;env setup needed
spa_done:
  ret
;-------------
  [section .data]
parse_ptr:  dd	0	;ptr to entry strings
  [section .text]
;------------------------------------------------------------
append_entry_string:
  mov	esi,[parse_ptr]
sp_mov_lp1:
  call	str_move	;append file name
  inc	edi
  cmp	byte [esi],0	;end of all parameters
  jne	sp_mov_lp1	;loop till all parameters moved
  xor	eax,eax
  stosd
  mov	esi,lib_buf+200
  ret
