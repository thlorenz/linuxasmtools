
  [section .text align=1]
;------------- tracex.asm ----------------------------------
;
; usage:  tracex <filename>
;
; output: the output file name is constructed by appending
;         "tra" to end of <file>.      <file>.tra
;
;-------------------------------------------------------------
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

;%define LOG

; each traced process has a status description 
; called "pids" which is defined below:

struc pids
.pid		resd 1 ;traced process id (pid)
.pid_status	resd 1 ;1=fork 2=stop1 4=stop2 8=dead 10h=run
                       ;20h=ffork  40h=show 80h=signal
.wait_status	resd 1 ;status from the "trace_wait" function
.r_sav_old_eax	resd 1
.r_old_eip	resd 1

.r_sav_ebx resd 1
.r_sav_ecx resd 1
;-- regsiter block start
.r_ebx	resd	1 
.r_ecx	resd	1

.r_edx	resd	1
.r_esi	resd	1
.r_edi	resd	1
.r_ebp	resd	1

.r_eax	resd	1 ;at start of fuction trap this register
                  ;contains 0ffffffdah (documented?).  We
                  ;use this information to detect starts.
.r_ds	resd	1

.r_es	resd	1
.r_fs	resd	1

.r_gs	resd	1
.r_old_eax resd	1 ;at start of function trap this register
                  ;contains function code (documented?)
.r_eip	resd	1
.r_cs	resd	1

.r_efl	resd	1
.r_esp	resd	1
.r_ss	resd	1
pids_struc_size:
endstruc

;each connection to the x server is described
;in table "connections".  The structure for
;individual entries follows:
struc xconn
.fd	resd	1	;socket fd
.pid	resd	1	;process id
.seq	resw	1	;sequence#
.flag	resb	1	;flag 01=first pkt 02=continutation pkt
;xconn_size:
endstruc

;-------------------------------------------------------------
extern env_stack
extern blk_find
;extern m_setup
;extern m_allocate
;extern m_release
extern file_delete
extern block_open_update
extern traceme
extern sys_run_die
extern trace_wait
extern trace_regsset
extern trace_regsget
extern trace_pid
extern block_write
extern block_close
extern trace_syscall
extern child_pid
extern str_move
extern trace_peek_bytes
extern dword_to_ascii

;extern file_exec_path
%include "file_exec_path.inc"

;extern buffer_hex
%include "buffer_hex.inc"
extern lib_buf
;extern dwordto_hexascii
;-------------------------------------------------------------
  [section .text]

  global main, _start
main:
_start:
  call	env_stack		;save stack for exec sys call
;  call	m_setup
  call	parse			;get parameters
  jnc	begin_key		;jmp if parse ok
  jmp	exit2			;exit if error
;open out file
begin_key:
  call	sig_setup
  call	open_outfile
;fork and start application 
  mov	eax,2
  int	byte 80h		;fork
  or	eax,eax
  jnz	t_parent		;jmp if this is us
;-----------  child process  -----------------
  call	traceme			;start ptrace
  mov	esi,traced_file
  call	sys_run_die		;start program to be traced
  mov	eax,1
  int	byte 80h		;should not get here
;-------------- parent process --------------
t_parent:
  mov	[child_pid],eax		;store child pid
  call	wait_for_stops
mloop:
;function ptrace loop ---
  call	start_pids
  js	exit2		;jmp if error
  jz	exit2		;jmp if all process dead
  call	wait_for_stops
  test	[pid_table+4],byte 8		;first process dead?
  jnz	exit2				;exit if first process died
  test	al,04h		;back of function?
  jz	mloop		;jmp if not back
;this is back of function
  mov	edx,[ebp+pids.r_old_eax]	;get function#
  cmp	edx,dword 3			;read function?
  je	xread_check			;jmp if read function
  cmp	edx,dword 4
  je	xwrite_check			;jmp if write function
  cmp	edx,dword 146			;writev function?
  je	xwritev_check			;jmp if writev
  cmp	edx,dword 145			;readv
  je	xreadv_check
  cmp	edx,dword 252			;exit group?
  je	exit2				;exit if program died
  cmp	edx,dword 102			;socket call?
  jne	mloop
  call	connect_check
  jmp	short mloop
xread_check:
  call	read_check
  jmp	short mloop
xwrite_check:
  call	write_check
  jmp	short mloop
xwritev_check:
  call	writev_check
  jmp	short mloop
xreadv_check:
  call	readv_check
  jmp	short mloop
;----------------
exit2:
  call	outfile_close
  mov	eax,1
  int	byte 80h
;-----------------------------------------------
; use table pid_table (ebp) to decode x functions
; We are at back end of kernel function
read_check:
  call	fd_check
  jnc	rc_exit				;jmp if fd not found
  mov	eax,[ebp+pids.r_eax]		;get return code
  or	eax,eax
  js	rc_exit				;if error, ignore this read
  mov	ebx,[active_socket]
  test	[ebx+xconn.flag],byte 1		;first packet after connect?
  jz	rc_10				;jmp if into communication
  cmp	[ebp+pids.r_edx],dword 32	;check if possible auth packet
  jb	rc_exit				;jmp if not auth packet
  jmp	short rc_first			;jmp if first real packet
;extract x packets
rc_10:
  mov	edx,[ebp+pids.r_ecx]		;buffer address
  mov	edi,[ebp+pids.r_eax]		;length of data
  push	edi				;save length
  mov	esi,temp_buf
  call	trace_peek_bytes
  pop	ecx				;restore length of block
  cmp	[raw_mode],byte 1
  jne	rc_pkt_ck			;jmp if not raw mode
  call	show_raw_read_packets
  jmp	short rc_exit
rc_pkt_ck:
  call	decode_read_packets
  jmp	short rc_exit
rc_first:
  and	[ebx+xconn.flag],byte ~1			;clear first time flag
rc_exit:
  ret
;-----------------------------------------------
; use table pid_table (ebp) to decode x functions
; We are at back end of kernel function
write_check:
  call	fd_check
  jnc	wc_exit
  mov	eax,[ebp+pids.r_eax]		;get return code
  or	eax,eax
  js	wc_exit				;if error, ignore this read
;extract x packets
  mov	edx,[ebp+pids.r_ecx]		;buffer address
  mov	edi,[ebp+pids.r_eax]		;length of data
  push	edi				;save length
  mov	esi,temp_buf
  call	trace_peek_bytes
  pop	ecx				;restore length of block
  cmp	[raw_mode],byte 1
  jne	wc_pkt_ck			;jmp if not raw mode
  call	show_raw_write_packets
  jmp	short wc_exit
wc_pkt_ck:
  call	decode_write_packets
wc_exit:
  ret
;-----------------------------------------------
; use table pid_table (ebp) to decode x functions
; We are at back end of kernel function
writev_check:
  call	fd_check
  jnc	wv_exit
  mov	eax,[ebp+pids.r_eax]		;get return code
  or	eax,eax
  js	wv_exit				;if error, ignore this read
  call	simulate_write			;build buffer
;extract x packets
  mov	ecx,[ebp+pids.r_edx]		;get length of write buffer
  cmp	[raw_mode],byte 1
  jne	wv_pkt_ck			;jmp if not raw mode
  call	show_raw_write_packets
  jmp	short wv_exit
wv_pkt_ck:
  call	decode_write_packets
wv_exit:
  ret
;-----------------------------------------------
; use table pid_table (ebp) to decode x functions
; We are at back end of kernel function
readv_check:
  call	fd_check
  jnc	rv_exit
  mov	eax,[ebp+pids.r_eax]		;get return code
  or	eax,eax
  js	rv_exit				;if error, ignore this read
  call	simulate_write			;build buffer
;extract x packets
  mov	ecx,[ebp+pids.r_eax]		;get length of read
  cmp	[raw_mode],byte 1
  jne	rv_pkt_ck			;jmp if not raw mode
  call	show_raw_read_packets
  jmp	short rv_exit
rv_pkt_ck:
  call	decode_read_packets
rv_exit:
  ret
;-----------------------------------------------
; use table pid_table (ebp) to decode x functions
; We are at back end of kernel function
connect_check:
  cmp	[ebp+pids.r_ebx],dword 3	;is this a listen for connection
  jne	cc_exit				;jmp if not connect
;this could be a new connection
  mov	eax,[ebp+pids.r_eax]		;get return code (fd)
  or	eax,eax
  js	cc_exit				;jmp if conncecton failed
;eax = new fd for connection,verify it is for x server
  mov	edx,[ebp+pids.r_ecx]
  mov	edi,12
  mov	esi,conn_buf
  call	trace_peek_bytes		;get pointers (0,path,len)
;now read path
  mov	edx,[conn_buf+4]		;buffer address
  mov	edi,[conn_buf+8]		;length of data
  push	edi				;save length
  mov	esi,temp_buf
  call	trace_peek_bytes
;search for X11 server
  mov	esi,cstring
  mov	edi,temp_buf
  pop	ecx				;restore lenght
  push	ebp
  mov	ebp,edi
  add	ebp,ecx				;compute buffer end
  mov	edx,1				;forward search
  mov	ch,-1				;match case
  call	blk_find
  pop	ebp
  jc	cc_exit				;exit if not found
;
;It appears a connection can drop and be reinitialized.
;This caused a bug, we had two duplicate fd's in the
;table and the second one was ignored.
;The fix was to reuse the old fd if it appears again.
;
  mov	ebx,connections-xconn_size	;get table of connections
  mov	eax,[conn_buf]			;get fd
  mov	edx,[trace_wait_pid]		;get id for current process
clp:
  add	ebx,xconn_size
  cmp	[ebx+xconn.pid],edx		;same process
  jne	clp_tail			;jmp if different process
  cmp	[ebx+xconn.fd],eax		;same fd
  je	cc_reuse			;jmp if this connection existed
clp_tail:
  cmp	[ebx+xconn.fd],dword 0
  jne	clp				;loop till slot found
cc_reuse:
  mov	[ebx+xconn.fd],eax		;save fd
  mov	[ebx+xconn.pid],edx		;save pid
  mov	[ebx+xconn.flag],byte 1			;store initial connect flag
cc_exit:
  ret

;-------------------
  [section .data]
cstring: db 'X11',0
conn_buf: dd 0,0,0	;(fd,*path,lenght)
  [section .text]
;--------------------------------------------------------------
simulate_write:
  mov	esi,temp_buf			;output buffer
  mov	ebx,[ebp+pids.r_ecx]		;get buffers ptr
  mov	ecx,[ebp+pids.r_edx]		;get number of buffers
sw_lp:
  push	ebx			;save buffer list
  push	ecx			;save buffer count
  push	esi			;save big buf ptr
  mov	edx,ebx			;get adr of list
  mov	esi,sim_adr		;get stuff ptr
  mov	edi,8			;get byte count
  call	trace_peek_bytes	;read one buffer info
  pop	esi			;restore big buf ptr
  pop	ecx			;restore buffer count
  pop	ebx			;restore buffer list
  mov	edx,[sim_adr]			;get buffer ptr
  mov	edi,[sim_len]			;get length
  push	ebx			;save buffer list ptr
  push	ecx			;save buffer count
  push	esi			;save big buf ptr
  push	edi			;save length of current buf
  call	trace_peek_bytes
  pop	edi			;restore length of buf just read
  pop	esi			;restore buf buf ptr
  pop	ecx			;restore buffer count
  pop	ebx			;restore buffer list ptr
  js	sw_exit			;exit if error
  add	esi,edi				;advance store buffer
  add	ebx,8				;move to next buffer
  loop	sw_lp			;loop back if more buffers
  mov	edx,temp_buf		;modify/simulate a write function
  mov	[ebp+pids.r_ecx],edx		;buffer address
  sub	esi,edx				;compute buffer length
  mov	[ebp+pids.r_edx],esi		;length of data
sw_exit:
  ret
;----------
  [section .data]
sim_adr	dd 0
sim_len dd 0
  [section .text]
;--------------------------------------------------------------
;decode_read_packets
;input: temp_buf has data
;       ecx = length of temp buf data
show_raw_read_packets:
  push	ecx
;build header line for raw mode
  mov	eax,[ebp+pids.r_ebx]		;get fd
  mov	edi,resp
  call	dword_to_ascii
  mov	ecx,separator
  mov	edx,separator_len
  call	outfile_write
  pop	ecx
  mov	esi,temp_buf
drp_lp:
  mov	edi,lib_buf
  call	buffer_hex
  push	esi
  push	ecx
  mov	ecx,lib_buf
  mov	edx,edi		;get ending ptr
  sub	edx,ecx		;compute length
  call	outfile_write
  pop	ecx
  pop	esi
  cmp	[truncate_mode],byte 1
  je	drp_exit	;exit if truncate mode
  or	ecx,ecx
  jz	drp_exit
  jns	drp_lp		;loop if more data
drp_exit:
  ret
;-------------
  [section .data]
separator: db 0ah,'--read-- fd='
resp:	   db '        ',0ah
separator_len	equ	$ - separator
  [section .text]
;--------------------------------------------------------------
;decode_write_packets
;input: temp_buf has data
;       ecx = length of temp buf data
show_raw_write_packets:
  push	ecx
;build header line for raw mode
  mov	eax,[ebp+pids.r_ebx]		;get fd
  mov	edi,wesp
  call	dword_to_ascii
  mov	ecx,wseparator
  mov	edx,wseparator_len
  call	outfile_write
  pop	ecx
  mov	esi,temp_buf
srw_lp:
  mov	edi,lib_buf
  call	buffer_hex
  push	esi
  push	ecx
  mov	ecx,lib_buf
  mov	edx,edi		;get ending ptr
  sub	edx,ecx		;compute length
  call	outfile_write
  pop	ecx
  pop	esi
  cmp	[truncate_mode],byte 1
  je	srw_exit	;exit if truncate mode
  or	ecx,ecx
  jz	srw_exit
  jns	srw_lp		;loop if more data
srw_exit:
  ret
;-------------
  [section .data]
wseparator: db 0ah,'--write-- fd='
wesp:	db '        ',0ah
wseparator_len	equ	$ - wseparator
  [section .text]
;------------------------------------------------------------------
;---------------------
;input: 
;output:
; set carry if connection found
; ebx points to fd table if carry
fd_check:
  mov	eax,[ebp+pids.r_eax]	;get return code
  or	eax,eax
  js	fc_fail			;fail if error
  mov	ebx,connections		;get table ptr
  mov	ecx,[ebp+pids.r_ebx]	;get fd
  mov	edx,[trace_wait_pid]	;get current process
fc_loop:
  mov	eax,[ebx+xconn.pid]
  cmp	edx,eax
  jne	fc_tail			;jmp if wrong process
  mov	eax,[ebx+xconn.fd]	;get connection
  cmp	ecx,eax
  je	fc_got
fc_tail:
  or	eax,eax
  jz	fc_fail
  add	ebx,xconn_size
  jmp	short fc_loop
fc_fail:
  clc
  jmp	fc_exit
fc_got:
  stc
  mov	[active_socket],ebx
fc_exit:
  ret
;------
  [section .data]
active_socket: dd 0
  [section .text]
;-----------------------------------------------
;use pid_table to start all stopped process
;input: none
;output: eax = 0 if all process dead
;
start_pids:
  xor	eax,eax
  mov	[pids_running],eax
  mov	ebp,pid_table
  cmp	[ebp],eax		;empty table?
  je	sp_exit1  
;move to end of pid table
sp_loop1:
  cmp	[ebp+pids.pid],eax	;end of table
  je	sp_loop2  	;jmp if end of table found
  add	ebp,pids_struc_size ;move to next pid
  jmp	short sp_loop1  ;loop till table end
;start process from end of table to beginning
sp_loop2:
  sub	ebp,pids_struc_size		;move to next pid
  test	[ebp+pids.pid_status],byte 8 + 10h  ;dead or running?
  jnz	sp_tail		;jmp if dead or running

;start this pid
  mov	eax,[ebp+pids.pid]	;setup for ptrace call
  mov	[trace_pid],eax		;get process id
  mov	esi,[send_signal]	;signal to send
sp_function:  
  call	trace_syscall	;start pid
  mov	[send_signal],dword 0	;set no special signal flag
sp_started:
  js	sp_exit2	;jmp if error
  mov	[ebp+pids.pid_status],byte 10h ;set running
sp_tail:
  mov	eax,[ebp+pids.pid_status]
  and	eax,byte 10h		;isolate running flag
  or	[pids_running],eax	;set running flag
  cmp	ebp,pid_table
  jne	sp_loop2	;jmp if more pids to check
sp_exit:
  mov	eax,[pids_running]
sp_exit1:
  or	eax,eax		;if any pids running set eax non-zero
sp_exit2:
  ret
;-----------
  [section .data]
pids_running: dd 0
  [section .text]
;-------------------------------------------------------------
; wait for process stop and handle forked processes
;inputs: none
;output: ebp = pids struc ptr
;         al = last .pid_status
wait_for_stops:
  mov	eax,114			;wait4
  mov	ebx,-1			;wait for any child
  mov	ecx,wait_stat		;store status here
  mov	edx,40000000h		;options
  xor	esi,esi			;rusage
  mov	[ecx],esi		;clear status area
  int	80h
  mov	ebx,[ecx]		;get status

;decode child stop status
;         if eax negative then error, else ebx is:
;         ebx = child status if eax = child pid
;            bl=status (7fh)-normal trace stop
;                      (00) -exception code in status
;            bh=signal if status non zero else exception
;                      signal was not caught
;
;    The format of status in ebx if eax positive:
;
;    byte 1                   byte 2
;    (bl in trace_wait call)  (bh in trace_wait call)
;    -----------------------  -----------------------
;    0   =process exited      kernel exit call reg "bl"
;    1-7e=process killed      signal# that killed process
;    7f  =process stopped     signal# that stopped process
;    ff  =process continued   singal# that continued process
;
;         examples:  ebx=0200 exception signal occured
;                    ebx=0b7f illegal segment register set by code
;                    ebx=087f divide by zero
;                    ebx=0037 unknown signal 37h sent by ptrace_step
;                    ebx=normal if int3 is encountered and no handler
;                               has been setup.
;

  mov	[trace_wait_pid],eax	;save process id
  mov	ebp,pid_table
  or	eax,eax			;
  jz	force_exit		;
  js	force_exit 		;
;check if this pid is in table
  cmp	eax,-1
  je	wfs_exit2j
pid_table_loop:
  cmp	[ebp+pids.pid],dword 0	;end of table?
  je	new_pid		;jmp if not in table
  cmp	eax,[ebp + pids.pid]	;process found?
  je	found_pid		;jmp if process match
  add	ebp,pids_struc_size	;move to next process
  jmp	short pid_table_loop	;loop
;this is either initial process stop, or traceing a fork
;ebp points to new pid entry
new_pid:
  push	eax		;save process id
  push	ebx		;save wait4 status
  mov	[trace_pid],eax ;store process_id
  mov	[ebp+pids.pid],eax ;insert pid#
  mov	[ebp+pids.wait_status],ebx ;insert wait4 status
  lea	esi,[ebp+pids.r_ebx] ;setup to read regs
  call	trace_regsget	;read registers
  pop	ebx		;restore wait4 return
  pop	eax		;restore process id
  or	eax,eax
  js	dead_pid	;jmp if error
  cmp	ebx,dword 137fh ;sigstop?
  je	np_temp
  cmp	ebx,dword 117fh ;sigchld?
  je	dead_pid	;jmp if dead pid
  cmp	ebx,dword 057fh	;sigtrap? initial stop or break?
  jne	dead_pid
np_temp:
  mov	al,1 + 2+ 40h+ 80h
  jmp	wfs_exit2
force_exit:		;force exit of program
  xor	eax,eax
  mov	[ebp],eax	;clear the pid table

dead_pid:
;  mov	[ebp+pids.pid_status],byte 8
  mov	al,8 + 40h 		;dead status
wfs_exit2j:
  jmp	wfs_exit2
;---
;existing pid was found, process it
found_pid:
  mov	[trace_pid],eax	;set this pid for library call
  mov	[ebp+pids.wait_status],ebx
  lea	esi,[ebp+pids.r_ebx]
  call	trace_regsget
;if regsget fails we have a dead pid,
  or	eax,eax
  js	dead_pid
;check if dead
  mov	eax,[trace_wait_pid]	;get wait eax
  or	eax,eax
  js	dead_pid
  mov	eax,[wait_stat]		;get wait ebx
  or	eax,eax
  jz	dead_pid		;jmp if process exit
;check if this is signal
  cmp	al,7fh			;nornal signal
  jne	dead_pid		;jmp if unexpected signal
  cmp	ah,05			;break signal
  je	found_break		;jmp if break signal
  cmp	ah,11h			;stop?
  jne	signal_stop		;jmp if signal
;this is a child stop, the child pid is in child eax
;register?

signal_stop:
  mov	[send_signal],ah	;save signal number
  mov	al, 40h + 80h
  jmp	wfs_exit2
;this is existing pid at normal break,
;check if front or back
found_break:
  cmp	[ebp+pids.r_eax],dword 0ffffffdah
  je	front
;this is a normal trace stop at end of function
back:
  cmp	[ebp+pids.r_old_eax],dword 120	;back end of fork?
  jne	back2	;jmp if not fork back end
  call	fork_restore
  lea	esi,[ebp+pids.r_ebx]
  call	trace_regsset
back2:
  mov	al,4 + 40h			;stop 2
  jmp	wfs_exit2
;this is normal trace stop at start of function
front:
;  inc	dword [sequence]	;bump sequence number
;save regs
  mov	eax,[ebp+pids.r_ebx]
  mov	[ebp+pids.r_sav_ebx],eax
  mov	eax,[ebp+pids.r_ecx]
  mov	[ebp+pids.r_sav_ecx],eax
  mov	eax,[ebp+pids.r_old_eax]
  mov	[ebp+pids.r_sav_old_eax],eax

;  mov	eax,[ebp+pids.r_old_eax]	;get function number
; check if fork(2) clone(120) or vfork(190)
  cmp	eax,2		;fork?
  jne	wfs_20		;jmp if not fork
;fork found
  mov	[ebp+pids.r_old_eax],dword 120	;force clone
  mov	[ebp+pids.r_ebx],dword 2011h	;ptrace bit + sig 11h = stop
  mov	[ebp+pids.r_ecx],dword 0
  jmp	short wfs_24
wfs_20:
  cmp	eax,120
  jne	wfs_22			;jmp if not clone
;clone found
  or	[ebp+pids.r_ebx],dword 2000h	;set ptrace bit
  jmp	short wfs_24
wfs_22:
  cmp	eax,190
  mov	al,2 			;preload function start (front)
  jne	wfs_exit2		;jmp if not vfork
;vfork found
  mov	[ebp+pids.r_old_eax],dword 120	;force clone
  mov	[ebp+pids.r_ebx],dword 2011h	;ptrace bit + sig 11h = stop
  mov	[ebp+pids.r_ecx],dword 0
wfs_24:
  lea	esi,[ebp+pids.r_ebx]
  call	trace_regsset
  mov	al,20h + 2h		;

wfs_exit2:
  mov	[ebp+pids.pid_status],al
  ret
;-------------
  [section .data]
trace_wait_pid: dd 0	;returned pid, or error code
wait_stat:	dd 0	;from ebx
  [section .text]

;-----------------------------------------------
;Restore munged fork,vfork,clone data.
fork_restore:
  mov	eax,[ebp+pids.r_sav_old_eax]	;get function number
; check if fork(2) clone(120) or vfork(190)
  cmp	eax,2		;fork?
  jne	fr_02		;jmp if not fork
;fork found
  mov	[ebp+pids.r_old_eax],eax	;restore fork
  mov	eax,[ebp+pids.r_sav_ebx]
  mov	[ebp+pids.r_ebx],eax
  mov	eax,[ebp+pids.r_sav_ecx]
  mov	[ebp+pids.r_ecx],eax
  jmp	short fr_10
fr_02:
  cmp	eax,120
  jne	fr_04
;clone found
  mov	eax,[ebp+pids.r_sav_ebx]
  mov	[ebp+pids.r_ebx],eax
  jmp	short fr_10
fr_04:
  cmp	eax,190
  jne	fr_10		;jmp if not vfork
;vfork found
  mov	[ebp+pids.r_old_eax],eax	;restore vfork 
  mov	eax,[ebp+pids.r_sav_ebx]
  mov	[ebp+pids.r_ebx],eax
fr_10:
  ret
;------------------------------------------------------------------
; input: ecx=buffer
;        edx=length of write
; output: eax=write count or error
;         flags set for js(error)
outfile_write:
  mov	ebx,[outfile_handle]
  call	block_write
  ret
;------------------------------------------------------------------
outfile_close:
  mov	ebx,[outfile_handle]
  call	block_close
  ret
;------------------------------------------------------------------
open_outfile:
  mov	ebx,outfile_name
  push	ebx
  call	file_delete
  pop	ebx
  xor	edx,edx			;default permissions
  call	block_open_update
  mov	[outfile_handle],eax
  ret
;------
  [section .data]
outfile_handle: dd 0

;-------------------------------------------------------------
  [section .text]

parse:
  mov	esi,esp
  lodsd			;get return address
  lodsd			;get parameter count
  dec	eax			;dec parameter count
  jz	short help_or_error	;jmp if no parameters entered
  lodsd			;get ptr to our executable name
parse_loop:
  or	eax,eax
  jnz	parse_05		;jmp if parameter avail
  jmp	parse_fail
parse_05:
  lodsd  			;get next parameter
  cmp	[eax],byte '-'
  jne	parse_outfile
;parse parameters
  cmp	[eax+1],byte 't'
  jne	parse_10		;jmp if not truncate mode
  mov	[truncate_mode],byte 1
  jmp	short parse_loop
parse_10:
  cmp	[eax+1],byte 'h'
  jne	parse_20
help_or_error:
  call	help_msg
  jmp	parse_fail
parse_20:
  cmp	[eax+1],byte 'r'	;raw mode
  jne	parse_loop		;jmp if not raw mode
  mov	[raw_mode],byte 1
  jmp	short parse_loop
parse_outfile:
  mov	[env_stack_ptr],esi	;save parm ptr
  mov	edi,traced_file
  mov	[file_parm],eax		;save file ptr
  mov	esi,eax
  or	esi,esi
  jz	parse_fail		;jmp if no file
  mov	ebx,esi			;save for later
  push	esi
  call	str_move
;build full path for file
  mov	esi,traced_file
  call	file_exec_path
  pop	esi
  jnc	parse_25
  jmp	short parse_fail
parse_25:
;add parameters to traced file
  push	esi
  mov	esi,[env_stack_ptr]	;get input parameters ptr
parse_30:
  lodsd
  or	eax,eax
  jz	parse_40		;jmp if no more parameters
  mov	byte [edi],0
  inc	edi			;insert zero between parameters
  push	esi
  mov	esi,eax
  call	str_move		;move data
  pop	esi
  jmp	parse_30
parse_40:
  xor	eax,eax
  stosd
  pop	esi

parse_50:
  mov	edi,outfile_name
  call	str_move
  mov	esi,out_tail
  call	str_move
  clc
  jmp	parse_exit
parse_fail:
  stc
parse_exit:
  ret
;----------
  [section .data]
env_stack_ptr	dd 0
traced_file	times 100 db 0
outfile_name	times 100 db 0
out_tail: db '.tra',0
file_parm: dd 0
  [section .text]
;-------------------------------------------------------------

extern signal_mask_block

sig_setup:
  mov	ecx,blocked
  call	signal_mask_block
  ret
;-------
  [section .data]
blocked	dd	010101000000000111b
  [section .text]
;-------------------------------------------------------------

;-------------------------------------------------------------
%include "decode_read.inc"
%include "decode_write.inc"
%include "decode_table.inc"
%include "reply_table.inc"
%include "help.inc"
;-------------------------------------------------------------
  [section .data]

raw_mode	db 0	;0=no  raw  1=raw
truncate_mode	db 0	;0=no truncate 1=truncate
send_signal	dd 0	;signal to send

pid_table:
  times pids_struc_size * 42 db 0

;table format, dd pid,
;              db flag	01h bit is first time flag
;                       02h bit is read block expected
;              dw sequence
;              db ?
connections:
  times 9*xconn_size+1 dd 0		;up to 8 connections

  [section .bss]

temp_buf resb 40000h	;buffer for x data


