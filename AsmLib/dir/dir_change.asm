
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
 
;****f* file/dir_change *
; NAME
;>1 dir
;  dir_change - change current working directory
; INPUTS
;    ebx = path of new dir
; OUTPUT
;    eax = negative if error
; NOTES
;   source file: file_dir.asm
;   kernel: chdir (12)
;<
; * ----------------------------------------------
;*******
  global dir_change
dir_change:
  mov	eax,12
  int	80h
  or	eax,eax
  ret
