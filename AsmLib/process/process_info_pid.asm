
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
;****f* process/process_info_pid *
; NAME
;>1 process
;  process_info_pid - get information for process (x)
; INPUTS
;    esi = ptr to asciiz pid string
; OUTPUT
;    eax = number of bytes of data in buffer lib_buf
;          (if eax negative an error occured)
;    ecx = pointer to data in lib_buf (see below)
;         Name:	init
;         State:	S (sleeping)
;         SleepAVG:	90%
;         Tgid:	1
;         Pid:	1
;         PPid:	0
;         TracerPid:	0
;         Uid:	0	0	0	0
;         Gid:	0	0	0	0
;         FDSize:	32
;         Groups:	
;         VmSize:	    1408 kB
;         VmLck:	       0 kB
;         VmRSS:	     496 kB
;         VmData:	     148 kB
;         VmStk:	       4 kB
;         VmExe:	      28 kB
;         VmLib:	    1204 kB
;         Threads:	1
;         SigPnd:	0000000000000000
;         ShdPnd:	0000000000000000
;         SigBlk:	0000000000000000
;         SigIgn:	ffffffff57f0d8fc
;         SigCgt:	00000000280b2603
;         CapInh:	0000000000000000
;         CapPrm:	00000000ffffffff
;         CapEff:	00000000fffffeff
;    The above data is held in a temporary buffer (lib_buf) and
;    may be destroyed by other library functions.  All entries of
;    form xxxx: begin at left edge and are followed by a <tab>.  The\
;    end of each entry is a <0ah> end of line character.  No binary
;    data is in lib_buf buffer.
;
;    The "state:" entry may contain:
;         "U" unknown pid
;         "S" sleeping
;         "R" running
;         "T" stopped
;         "Z" zombie
;         "D" uninteruptable wait
;
; NOTES
;    source file: process_info_pid.asm
;<
;  * ----------------------------------------------
;*******
  [section .text]
;
  extern file_simple_read,lib_buf,str_move
  global process_info_pid
process_info_pid:
  mov	edi,tpf_insert
  call	str_move
  mov	esi,tpf_append
  call	str_move
;
  mov	ebx,target_proc_file
  mov	ecx,lib_buf		;buffer
  mov	edx,600			;buffer size
  call	file_simple_read
  ret

  [section .data]

target_proc_file:
  db "/proc/"
tpf_insert:
  times	20 db 0
tpf_append:
  db	'/status',0