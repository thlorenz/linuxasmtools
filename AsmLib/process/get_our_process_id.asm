
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
;---------------------------------------------------
;>1 process
;  get_our_process_id - get our process id
; INPUTS
;    none
; OUTPUT
;    eax = our pid
; NOTES
;    calls kernel function getpid
;    source file: get_our_process_id.asm
;<
  [section .text]
;
  global get_our_process_id
get_our_process_id:
  mov	eax,20			;get our PID
  int	80h			;sys_getpid
  ret
