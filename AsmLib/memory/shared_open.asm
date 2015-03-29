
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
;  shared_open - open a shared memory segment
;
;  INPUTS    ecx = A unique key used by all processes
;                  to access shared memory, or if set to
;                  zero (IPC_PRIVATE) this is a private
;                  allocation, available to child after fork.
;                  Warning, only first level children see
;                  IPC_PRIVATE memory.  
;            edx = number of bytes to allocate 
;            esi = mode.
;                  The first user of shared memory sets the
;                  create bit and succeeding users leave the
;                  create bit off.  The bits are:
;
;                  IPC_CREAT=00001000q   - create initial segment
;                  IPC_EXCL=00002000q    - give error if segment exists
;                  owner read=00000400q 
;                  owner write=00000200q
;                  group read=00000040q
;                  group write=00000020q
;                  other read=00000004q
;                  other write=00000002q
;
;  OUTPUT     eax = "shmid key" needed to access memory or -1 if
;                   failure.  key is called "shmid" in docs
;
;  NOTE       source file:  shared_open.asm
;
;             This function is part of a family of functions
;             that work together, including:
;               shared_open - open shared memory area
;               shared_attach - connect to shared memory area
;               shared_close - detach from shared memory
;           
;             The kernel selects address of shared memory and
;             sets it to read/write.
;
;             This function is used to create shared memory and
;             by other processes to get the "shmid key" needed
;             to access shared memory.  A typical operation:
;               call shared_open ;create or ask for access to memory
;               call shared_attach ;attach to shared memory
;               (access memory here)
;               call shared_close ;our process is done with memory
;<
;  * ----------------------------------------------

  global shared_open
shared_open:
  mov	eax,117			;sys_ipc
  mov	ebx,17h			;shmget kernel function
;  xor	ecx,ecx			;key = IPC_PRIVATE (see kernel includes)
;  mov	edx,size		;from caller
;  mov	esi,01666q		;read/write access permision+IPC_CREATE
  xor	edi,edi
  int	byte 80h
  ret

;--------------------------------------------
%ifdef DEBUG
  extern shared_attach
  extern shared_close

  global main,_start
main:
_start:
  nop
  mov	ecx,0			;key (private)
  mov	edx,20			;size
  mov	esi,01666q		;create + R/W everyone
  call	shared_open

  push	eax
  mov	ecx,eax
  call	shared_attach

  pop	ecx
  call	shared_close

  mov	eax,1
  int	byte 80h
;--------
  [section .data]

%endif

