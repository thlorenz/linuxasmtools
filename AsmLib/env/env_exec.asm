
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
  extern fstat_buf
  extern lib_buf

  struc	stat_struc
.st_dev: resd 1
.st_ino: resd 1
.st_mode: resw 1
.st_nlink: resw 1
.st_uid: resw 1
.st_gid: resw 1
.st_rdev: resd 1
.st_size: resd 1
.st_blksize: resd 1
.st_blocks: resd 1
.st_atime: resd 1
.__unused1: resd 1
.st_mtime: resd 1
.__unused2: resd 1
.st_ctime: resd 1
.__unused3: resd 1
.__unused4: resd 1
.__unused5: resd 1
;  ---  stat_struc_size
  endstruc

;****f* env/env_exec *
; NAME
;>1 env
;  env_exec - search executable path for program
; INPUTS
;    ebx = pointer to envionmet pointer list
;    ebp = pointer to program name to search for 
; OUTPUT
;    if no-carry ebx = ptr to full path of executable
;    if carry, file was not found.
; NOTES
;    file env_exec.asm  (see also build_current_path)
;    temp buffer "lib_buf" is used to pass executable path
;    back to caller.
;<
;  * ----------------------------------------------
;*******
  global env_exec 
env_exec:
  cmp	byte [ebp],'/'		;is this a full path?
  jne	fp_10			;if not, to search enviornment for name
;the full path was given, check if it exists
  mov	ebx,ebp
  mov	eax,107			;fstat
  int	80h
  rcl	eax,1			;set return status if carry file not found
  jmp	fp_exit			;
;  
; scan the enviornment for PATH entry
fp_10:
  or	ebx,ebx
  jz	fp_50
  mov esi,[ebx]
  or	esi,esi
  jz	near fp_50
  cmp [esi],dword 'PATH'
  jne fp_12
  cmp [esi+4],byte '='
  je fp_20		;jmp if PATH= found
fp_12:
  add ebx,byte 4
  jmp short fp_10
;
; we have found PATH= ,now try each path with our filename
;
fp_20:
  add esi,5			;move past "PATH="
fp_lp2:
  cmp [esi-1],byte 0		;check if end of PATH= entries
  je fp_50			;exit if no matches
;
; move trial path
;
  mov	edi,lib_buf
fp_30:
  lodsb
  stosb
  cmp	al,0
  je	fp_32			;jmp if end of path
  cmp	al,':'
  jne	fp_30			;loop till path moved
fp_32:
  dec	edi
  mov	al,'/'			;append '/' to end of path
  stosb
;
; append our filename to this new path
;
  push esi
  mov esi,ebp		;get pointer to our name
fp_40:
  call	str_move
  pop esi
;
; get status of this trial path + name
;
  mov	ebx,lib_buf
fp_45:
  mov	ecx,lib_buf + 200	;fstat_buf
  mov	eax,107			;fstat
  int	80h
  rcl	eax,1
  jnc	fp_exit			;jmp if we have found our file
  jmp	short fp_lp2		;jmp if this combo failed, try again
fp_50:
 stc				;indicate file not found
fp_exit:
  ret
  
