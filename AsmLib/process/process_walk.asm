
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
;****f* process/process_walk *
; NAME
;>1 process
;  process_walk - walk through active process's
; INPUTS
;    eax = either buffer pointer or continue flag
;          if eax = buffer ptr then this is first call
;          -  and walking will begin
;          if eax = 0 this is a continuation call and
;          -  we will walk to next process
;    ebx = buffer size if ptr in eax
;          For most systems a good size is 8096 bytes.
; OUTPUT
;    eax = number of bytes of data in buffer lib_buf
;        - (if eax negative an error occured)
;        - (if eax =  zero we are done walking)
;    ecx = pointer to data in lib_buf (example below)
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
;    form xxxx: begin at left edge and are followed by a <tab>.  The
;    end of each entry is a <0ah> end of line character.  No binary
;    data is in lib_buf buffer.
;    Open files are closed when end of process data is signaled by
;    no more data.  If walk does not reach the end, the open file
;    handle "proc_handle" should be closed by caller.  A good
;    way to do this is by calling "process_walk_cleanup" after
;    using process_walk. 
; NOTES
;    source file: process_walk.asm
;<
;  * ----------------------------------------------
;*******
  [section .text]
;
  extern file_simple_read,lib_buf
  extern file_open,file_close
  extern str_move
  extern is_number

  global process_walk
process_walk:
  or	eax,eax			;continuation?
  je	pw_40			; jmp if continuation
  mov	[proc_buf_ptr],eax
  mov	[proc_buf_size],ebx
;
  mov	ebx,proc_path
  xor	ecx,ecx			;access flags rd_only
  call	file_open		;open /proc
  jns	pw_10			;jmp if open ok
  jmp	pw_exit			;exit if error
pw_10:
  mov	[proc_handle],eax
; get system table, using getdents kernel call
pw_20:
  mov	eax,141
  mov	ebx,[proc_handle]
  mov	ecx,[proc_buf_ptr]
  mov	edx,[proc_buf_size]
  int	80h			;sys_getdents
; returns zero if out of data, else buffer has record
; of form:  dd (inode number)
;           dd (offset from top of table to next record)
;           dw (size of this record)
;           db (name of this entry)
  or	eax,eax
  jnz	pw_continue1		;jmp if data read
  call	file_close
  jmp	short pw_exit		;exit if at end
pw_continue1:
  mov	[bytes_in_buffer],eax	;save read size
  mov	[current_dents_rec_ptr],ecx
;
;look at next record 
;
pw_40:
  cmp	dword [bytes_in_buffer],0
  je	pw_20				;if buffer empty read next
  mov	ebx,[current_dents_rec_ptr]
  mov	al,[ebx+10]			;get first char of name
  call	is_number
  je	pw_continue2			;jmp if entry is a named process
  mov	ax,[ebx+8]
  add	[current_dents_rec_ptr],eax
  sub	[bytes_in_buffer],eax
  jmp	short pw_40			;try next record
 
;
pw_continue2:
  lea	esi,[ebx+10]			;get ptr to name
  mov	edi,proc_append
  call	str_move
  mov	esi,status_append
  call	str_move

  mov	ebx,proc_build
  mov	ecx,lib_buf		;buffer
  mov	edx,600			;buffer size
  call	file_simple_read
; setup for next record
  push	eax
  xor	eax,eax
  mov	ebx,[current_dents_rec_ptr]
  mov	ax,[ebx+8]
  add	[current_dents_rec_ptr],eax
  sub	[bytes_in_buffer],eax
  pop	eax
pw_exit:
  ret

;----------------------
  [section .data]

proc_buf_ptr	dd	0
proc_buf_size	dd	0

  global proc_handle
proc_handle	dd	0

bytes_in_buffer	dd	0
current_dents_rec_ptr	dd	0

proc_path	db	'/proc',0
our_info_file: db "/proc/self"
status_append:	db	"/status",0

proc_build:	db	'/proc/'
proc_append:	times   20 db 0
;-------------------------------------------------------------
  [section .text]
; NAME
;>1 process
;  process_walk_cleanup - close all walk files 
; INPUTS
;    none
; OUTPUT
;    none
; NOTES
;    source file: process_walk.asm
;    Use this call after all calls to process walk are
;    finished.
;<
;  * ----------------------------------------------
;*******
;

  global process_walk_cleanup
process_walk_cleanup:
  mov	ebx,[proc_handle]
  call	file_close
  ret  
