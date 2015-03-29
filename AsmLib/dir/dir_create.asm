
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

;****f* file/dir_create *
; NAME
;>1 dir
;  dir_create - create a new directory
; INPUTS
;    ebx = path of new directory
; OUTPUT
;    eax = negative error# if problem
; NOTES
;   source file: file_dir.asm
;   kernel: mkdir(39)
;   This function creates a user read/write directory
;   if other directories are needed use kernel call
;<
; * ----------------------------------------------
;*******
  global dir_create
dir_create:
  mov	eax,39
  mov	ecx,40755q		;read/write flag
  int	80h			;create /home/xxxx/a
  or	eax,eax			;set sign bit incase error reported
  ret
