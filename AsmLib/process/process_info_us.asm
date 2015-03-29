
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
;****f* process/process_info_us *
; NAME
;>1 process
;  process_info_us - get our process information
; INPUTS
;    none
; OUTPUT
;    eax = number of bytes of data in buffer lib_buf
;          (if eax negative an error occured)
;    ebx = our process id (binary)
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
; NOTES
;    source file: process_info_us.asm
;<
;  * ----------------------------------------------
;*******
  [section .text]
;
  extern file_simple_read,lib_buf
  global process_info_us
process_info_us:
  mov	ebx,our_info_file	;file path
  mov	ecx,lib_buf		;buffer
  mov	edx,600			;buffer size
  call	file_simple_read
  push	eax
  mov	eax,20			;get our PID
  int	80h			;sys_getpid
  mov	ebx,eax			;move PID to ebx
  pop	eax			;restore buffer data count
  ret

our_info_file: db "/proc/self/status",0