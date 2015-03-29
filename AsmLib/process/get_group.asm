
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
;------------------------------
;>1 process
;  get_group - get group id for process (x)
; INPUTS
;    ebx = process id
; OUTPUT
;    eax = group id for process passed in eax
;          if error a negative error code in eax
; NOTES
;    calls kernel function getpgid(x)
;    source file: get_group.asm
;<
  [section .text]
;
  global get_group
get_group:
  mov	eax,132
  int	80h
  ret
