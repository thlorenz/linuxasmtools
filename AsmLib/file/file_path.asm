
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
  extern env_home
  extern str_move

;****f* file/build_homepath *
;
; NAME
;>1 file
;  build_homepath - build path using $HOME
; INPUTS
;    ebx = ptr to enviornment pointers
;    edi = buffer
;    ebp = append string (filename or dir/filename)
;          if ebp = 0 no append string is processed
; OUTPUT
;    buffer (passed in edi) has path if eax positive
; NOTES
;    source file: file_path.asm
;<
;  * ----------------------------------------------
;*******
  global build_homepath
build_homepath:
;  push	edi
  call	env_home		;get $HOME directory ebx=env ptr  edi=buffer
  js	fw_18			;jmp if error
;  pop	edi
  jmp	fw_16			;go add file name

;****f* file/get_current_path *
;
; NAME
;>1 file
;  get_current_path - get default (current) dir
; INPUTS
;     ebx = ptr to buffer
;     ecx = buffer size
; OUTPUT
;     eax = negative if error
;     eax = positive, then buffer has path.
; NOTES
;    source file:  file_path.asm
;<
;  * ----------------------------------------------
;*******
  global get_current_path
get_current_path:
  mov	eax,183			;kernel call - get default dir
  int	80h
  or	eax,eax
  ret

;****f* file/build_current_path *
;
; NAME
;>1 file
;  build_current_path - build path using current dir
; INPUTS
;     ebx = ptr to buffer
;     ebp = append string for path, or zero if no append 
; OUTPUT
;     eax = negative if error
;     eax = positive, then buffer has path.
; NOTES
;    source file:  file_path.asm
;<
;  * ----------------------------------------------
;*******
  global build_current_path
build_current_path:
  call	get_current_path
  js	fw_18			;jmp if error
;
; move edi forward to end of our current dir name
;
  mov	edi,ebx			;move path_buf start to edi
fw_15:
  inc	edi
  cmp	byte [edi],0
  jne	fw_15
; entry point for build_homebase
fw_16:
  mov	al,'/'
  stosb
;
; edi = pointer into filename build buffer
;
  mov	esi,ebp
  call	str_move
  xor	eax,eax
fw_18:
  ret
