
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
;****f* process/process_search *
; NAME
;>1 process
;  process_search - search names of active process's
; INPUTS
;    eax = either buffer pointer or continue flag
;          if eax = buffer ptr then this is first call
;          -  and searching will begin
;          if eax = 0 this is a continuation call and
;          -  we will search to next match
;    ebx = buffer size if ptr in eax
;    ecx = match string (asciiz process name)
; OUTPUT
;    eax = (if eax negative an error occured)
;          (if eax = 0 then no match found)
;          (if eax positive = ptr to process data (see below)
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
;    After using this function call process_walk_cleanup to close
;    all open files.
; NOTES
;    source file: process_search.asm
;<
;  * ----------------------------------------------
;*******
  [section .text]
  extern process_walk
  extern str_compare
;
  global process_search
process_search:
  or	eax,eax			;continuation?
  je	ps_40			; jmp if continuation
;  mov	[proc_buf_ptr],eax
;  mov	[proc_buf_size],ebx
  mov	[search_string],ecx
  jmp	short ps_50		;go get next process
;
ps_40:
  xor	eax,eax
ps_50:
  call	process_walk
  or	eax,eax
  jz	ps_exit2		;exit if out of data
  js	ps_exit2		;exit if error  
;
  mov	[process_data_ptr],ecx
  add	ecx,6			;move to name start
  mov	esi,ecx
ps_60:
  cmp	byte [ecx],0ah
  je	ps_70			;jmp if end of name found
  inc	ecx
  jmp	ps_60			;loop till end of name
ps_70:
  mov	byte [ecx],0		;terminate name
  mov	edi,[search_string]
  call	str_compare
  jne	ps_40			;loop if no match
;
ps_exit1:
  mov	eax,[process_data_ptr]	;get match data
ps_exit2:
  or	eax,eax			;set sign flag
  ret

;----------------------
  [section .data]

;proc_buf_ptr	dd	0
;proc_buf_size	dd	0
search_string	dd	0

process_data_ptr dd	0


