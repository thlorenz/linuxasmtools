
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
;***************  file:  file_access.asm **************


;--------------------------------------------
;>1 file
;   file_access - check if file can be accessed
; INPUTS    ebx = ptr to file path
;           ecx = bit flag for type of access wanted
;                 0=path existence check
;                 1=execute access
;                 2=write access
;                 4=read access
;                 example:  ecx=3 for execute & write check
;
; OUTPUT    eax =  zero if access ok, else negative error
;
; NOTES:  Source file is file_acces.asm
;<
;--------------------------------------------
;--------------------------------------------
;>1 dir
;   dir_access - check if file can be accessed
; INPUTS    ebx = ptr to dir path
;           ecx = type of access wanted
;                 0=path existence check
;                 1=execute access
;                 2=write access
;                 4=read access
;
;
; OUTPUT    eax =  zero if access ok, else negative error
;
; NOTES:  Source file is file_acces.asm
;<
;--------------------------------------------
  global file_access
  global dir_access
dir_access:
file_access:
  mov	eax,33
  int	byte 80h
  ret
;----------------------------------------------
%ifdef DEBUG

  extern lib_buf
global main,_start
main:
_start:
  mov	eax,183
  mov	ebx,lib_buf
  mov	ecx,300
  int	byte 80h
  mov	ecx,0		;exist
  call	dir_access
  mov	ecx,1
  call	dir_access
  
  mov	eax,1
  int	byte 80h

%endif
