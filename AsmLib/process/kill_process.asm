
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
;  kill_process - send kill signal to process
; INPUTS
;    ebx = pid to kill
;          0 = kill all processes in group
; OUTPUT
;    eax = 0 if success
;          a negative value is error code
; NOTES
;    source file: kill_process.asm
;<
  [section .text]
;
  global kill_process
kill_process:
  mov	eax,37		;kill kernel call
  mov	ecx,9		;kill signal  
  int	byte 80h
  ret
