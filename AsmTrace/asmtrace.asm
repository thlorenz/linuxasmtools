
  [section .text align=1]
;------------- asmtrace.asm ----------------------------------
;
; usage:  asmtrace <Enter>         - starts interactive mode
;         asmtrace <file> <Enter>  - preforms default trace
;         asmtrace <-a> <file> <Enter> - attach to file and trace
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
%include "includes.inc"

;-------------------------------------------------------------
extern env_stack
extern m_setup
extern m_allocate
extern m_release
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
extern trace_step
extern trace_syscall
extern child_pid
;extern reset_clear_terminal
;-------------------------------------------------------------
  [section .text]

  global main, _start
main:
_start:
  call	env_stack		;save stack for exec sys call
  call	m_setup
  call	parse			;get parameters
  jnc	begin_key		;jmp if data setup
  call	menu                    ; al=0 continue  1=begin  2=exit
  cmp	al,1			;esc pressed
  jbe	begin_key		;jmp if ready to trace
  jmp	exit2			;jmp if exit
;open out file
begin_key:
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
  inc	dword [sequence]
  call	check_trigger_on
mloop:
  test	[report_flag],byte 1	;is reporting active
  jz	floop			;jmp if reporting off
  cmp	[parse_show_disasm],byte 0
  je	floop			;jmp if disasm off
  call	step
  jnc	mloop			;jmp if continue
  jmp	exit2			;jmp if all process dead
;function ptrace loop ---
floop:
  call	start_pids
  jnz	f_05		;jmp if pid started
  jmp	exit2		;jmp if all process dead
f_05:
  call	wait_for_stops
  test	[report_flag],byte 1	;reporting on?
  jnz	f_10			;jmp if reports on
;reports are off,check triggers
  call	check_trigger_on
  test	[report_flag],byte 1	;check if reports now on
  jz	f_end			;loop if reports off
  call	show_trace
  jmp	short f_end
;reports are on, check triggers
f_10:
  call	show_trace
  call	check_trigger_off
f_end:
  test	[ebp+pids.pid_status],byte 2	;front of function?
  jnz	mloop				;bump sequence at end of function
  inc	dword [sequence]
  jmp	mloop 
;----------------
 
exit2:
  call	outfile_close
;  call	reset_clear_terminal
  mov	eax,1
  int	byte 80h
;-----------------------------------------------
; function trace logic follows
;-----------------------------------------------
; use table pid_table to show results for all functions
; with the show flag bit set (40h)
show_trace:
  push	ebp
  mov	ebp,pid_table
st_loop:
  cmp	[ebp+pids.pid],dword 0		;end of pid_table
  je	st_exit				;exit if done
  test	[ebp+pids.pid_status],byte 40h	;trace request?
  jz	st_tail			;jmp if not stopped
  call	report
  and	[ebp+pids.pid_status],dword ~40h ;clear show bit
st_tail:
  add	ebp,pids_struc_size		;move to next pid
  jmp	short st_loop			;loop back
st_exit:
  pop	ebp
  ret

;-----------------------------------------------
;use pid_table to start all stopped process
;input: none
;output: eax = 0 if all process dead
;
start_pids:
  mov	[pids_running],dword 0
  mov	ebp,pid_table
;move to end of pid table
sp_loop1:
  cmp	[ebp+pids.pid],dword 0	;end of table
  je	sp_loop2  	;jmp if end of table found
  add	ebp,pids_struc_size ;move to next pid
  jmp	short sp_loop1  ;loop till table end
;start process from end of table to beginning
sp_loop2:
  sub	ebp,pids_struc_size		;move to next pid
;check if this pid needs starting
;  test	[ebp+pids.pid_status],byte 1 + 2 + 4 + 20h + 80h ;stopped?
;  jz	sp_tail		;jmp if not stopped
;  test	[ebp+pids.pid_status],byte 8  ;dead
;  jnz	sp_tail		;jmp if dead

  test	[ebp+pids.pid_status],byte 8 + 10h  ;dead or running?
  jnz	sp_tail		;jmp if dead or running

;start this pid
  mov	eax,[ebp+pids.pid]	;setup for ptrace call
  mov	[trace_pid],eax		;get process id
  mov	esi,[send_signal]	;signal to send
  cmp	byte [parse_show_disasm],0 ;check if function trace on
  jz	sp_function		;jmp if function trace
;we are single stepping, start step
  call	trace_step
  jmp	short sp_started
sp_function:  
;;  cmp	[ebp+pids.r_eax],dword 0fffffdfeh
;;  je	sp_exit 
  call	trace_syscall	;start pid
sp_started:
  mov	[send_signal],dword 0	;set no special signal flag
  js	sp_exit		;jmp if error
  mov	[ebp+pids.pid_status],byte 10h ;set running
sp_tail:
  mov	eax,[ebp+pids.pid_status]
  and	eax,byte 10h		;isolate running flag
  or	[pids_running],eax	;set running flag
  cmp	ebp,pid_table
  jne	sp_loop2	;jmp if more pids to check
sp_exit:
  mov	eax,[pids_running]
  or	eax,eax		;if any pids running set eax non-zero
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
;check if this pid is in table
  mov	ebp,pid_table
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
  call	report_new_process	;report new process
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
;  mov	[ebp+pids.pid_status],byte 1 + 40h + 80h	;preload
;  cmp	[ebp+pids.r_old_eax],dword 120 ;is a fork in process
  mov	al,1 + 2+ 40h+ 80h
  jmp	wfs_exit2
dead_pid:
  mov	[ebp+pids.pid_status],byte 8
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

  cmp	byte [parse_follow],0
  mov	al,2
  je	wfs_exit2		;jmp if not following forks
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
;  jmp	short wfs_exit2

wfs_exit2:
  mov	[ebp+pids.pid_status],al
%ifdef LOG
  call	logit
%endif
  ret
;-------------
  [section .data]
trace_wait_pid: dd 0	;returned pid, or error code
wait_stat:	dd 0	;from ebx
  [section .text]

;-----------------------------------------------
;Restore munged fork,vfork,clone data.
fork_restore:
  cmp	byte [parse_follow],0
  je	fr_10		;exit if not following forks
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
;-----------------------------------------------------------------
;inputs: ebp = ptr to pids struc
;  start_seq      dd 1
;  start_adr	  dd 0
;  start_fun	  dd 0
;output:
;  report_flag	db 0	;bit 01=reports active 02=report state change
;
check_trigger_on:
  mov	ecx,[sequence]
  cmp	[parse_show_disasm],byte 0
  je	cto_20		;jmp if no disasm
;if this is disasm then check if starting on seq#1
;if true, then also allow start on seq#0
  jecxz	ct_on
;normal path for both disasm and function mode
cto_20:
  cmp	ecx,[start_seq]
  je	ct_on		;jmp if trigger sequence
  mov	ecx,[ebp+pids.r_eip]
  jecxz	cto_exit	;exit if null eip
  cmp	ecx,[start_adr]
  je	ct_on		;jmp if address trigger match
  mov	ecx,[start_fun]
  jecxz	cto_exit	;exit if function trigger disabled
;check function type here
  cmp	ecx,[ebp+pids.r_old_eax]
  jne	cto_exit	;jmp if not trigger function
ct_on:
  mov	[report_flag],byte 3
  call	report_on_off
cto_exit:	
  ret
;-----------------------------------------------------------------
;inputs: ebp = ptr to pids struc
;   stop_seq          dd 0
;   stop_adr          dd 0
;   stop_fun          dd 1
;output:
;    report_flag db 0	;bit 1=reports on bit2=state change
check_trigger_off:
  mov	ecx,[stop_seq]
  jecxz	ctt_20		;jmp if no stop seq. active
  cmp	ecx,[sequence]
  je	ctt_off		;jmp if trigger sequence
ctt_20:
  mov	ecx,[ebp+pids.r_eip]
  jecxz	ctt_exit	;exit if null eip
  cmp	ecx,[stop_adr]
  je	ctt_off		;jmp if address trigger match
  mov	ecx,[stop_fun]
  jecxz	cto_exit	;jmp if function trigger disabled
;check function type here
  cmp	ecx,[ebp+pids.r_old_eax]
  jne	ctt_exit	;jmp if not trigger function
ctt_off:
  mov	[report_flag],byte 2
  call	report_on_off
ctt_exit:	
  ret
;-----------------------------------------------------------------

report_on_off:
  test	[report_flag],byte 2 ;state change?
  jz	rsc_50		     ;jmp if no change in reporting
  test	[report_flag],byte 1 ;check if reports on
  jnz	rsc_report_on
  mov	ecx,report_off_msg
  mov	edx,report_off_msg_len
  jmp	short rsc_40
rsc_report_on:
  mov	ecx,report_on_msg
  mov	edx,report_on_msg_len
rsc_40:
  call	outfile_write
rsc_50:
  and	byte [report_flag],~2 ;clear report change
  ret
;---------------
  [section .data]
report_off_msg     db '-- trace reporting disabled-',0ah
report_off_msg_len equ	$ - report_off_msg
report_on_msg      db '-- trace reporting enabled',0ah
report_on_msg_len  equ  $ - report_on_msg
  [section .text]
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
%include "parse_and_menu.inc"
%include "asmtrace_report.inc"
%include "log.inc"
;-------------------------------------------------------------
  [section .data]

report_flag	db 0	;bit 01=reports active 02=report state change
send_signal	dd 0	;signal to send

pid_table:
  times 400 dd 0
%include "asmtrace_step.inc"
%include "decode_descrip.inc"
%include "decode_ptr.inc"
%include "signal_descript.inc"
%include "write_hex_line.inc"
  [section .text]


