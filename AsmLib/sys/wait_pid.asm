
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
;----------------------
;***** sys/wait_pid *
; NAME
;>1 sys
;   wait_pid - wait for a process to change state
; INPUTS
;    ebx = (-1)      wait for any child
;          (-group#) wait for group
;          0         wait for child in our group
;          pid       wait for individual process by  pid
;    edx = 0 wait for child
;          1 WNOHANG, return status immediatly if no child has exited.
;            If no children are waiting then return without updating
;            status, this means we need to preload status with a value.
;          2 WUNTRACED, return if child stopped   
;
; OUTPUT
;    eax = positive pid if success, status in edx
;        = negative error, only -1 is defined.
;
;    The format of status in edx is:
;      if bl=0 then process exited, return status in bh
;         if bh=0 it could be return code or no process found.
;      if bl=(1-7e) then bh = signal that killed process
;      if bl=7fh then bh = signal that stopped process
;      if bl=ffh then bh = signal that continued process
; NOTES
;    source file wait_pid.asm
;    note: see also wait_event
;<
;  * ---------------------------------------------------
;*******
  global wait_pid
wait_pid:
  xor	eax,eax
  mov	[status_save],eax
  mov	eax,7		;wait pid system call
; mov	ebx,pid info
  mov	ecx,status_save
; mov	edx,code
  int	byte 80h
  mov	edx,[status_save]
  ret

  [section .data]
status_save:	dd	0

  [section .text]

