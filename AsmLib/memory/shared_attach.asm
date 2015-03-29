
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
;  shared_attach - attach to a shared memory segment
;  INPUTS     ecx = "shmid" key returned from shared_open
;
;  OUTPUT     eax = "address" needed to access memory or error
;                   if failure.
;
;  NOTE       source file:  shared_attach.asm
;
;             This function is part of a family of functions
;             that work together, including:
;               shared_open   - open shared memory area
;               shared_attach - connect to shared memory area
;               shared_close - detach from shared memory
;           
;             The kernel selects address of shared memory and
;             sets it to read/write.
;
;<
;  * ----------------------------------------------
  extern lib_buf
  global shared_attach
shared_attach:
  mov	eax,117			;sys_ipc
  mov	ebx,15h			;shmat kernel function
; mov	ecx,shmid		;shmid (key) from shared_open
  xor	edx,edx			;attach address (0=kernel choice)
  mov	esi,lib_buf		;buffer to store address
  xor	edi,edi			;read/write access flag, 0=R/W ?
  int	byte 80h
  or	eax,eax
  js	sa_exit
  mov	eax,[lib_buf]		;get memory address
sa_exit:
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

