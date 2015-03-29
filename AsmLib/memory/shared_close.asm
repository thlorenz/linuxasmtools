
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


;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 memory
;  shared_close - close a shared memory segment
;  INPUTS     ecx = "shmid" key returned from shared_allocate
;
;  OUTPUT     eax = zero if success, else -1 if failure.
;
;  NOTE       source file:  shared_close.asm
;
;             This function is part of a family of functions
;             that work together, including:
;               shared_open   - open shared memory area
;               shared_attach - connect to shared memory area
;               shared_close - detach from shared memory
;           
;             Each user of shared memory must execute this call.
;             When the last user releases memory, it will be
;             destroyed.
;
;<
;  * ----------------------------------------------

  global shared_close
shared_close:
  mov	eax,117			;sys_ipc
  mov	ebx,18h			;shmctl kernel function
; mov	ecx,shmid		;shmid (key) from shared_open
  xor	edx,edx			;release shared memory (IPC_RMID)
  xor	esi,esi			;probably not needed
  int	byte 80h
  ret


%ifdef DEBUG
  global main,_start
main:
_start:
  nop

  mov	eax,1
  int	byte 80h
;--------
  [section .data]

%endif

