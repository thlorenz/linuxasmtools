extern delay
;------------- asmtrace_step.inc ----------------------------
;-------------------------------------------------------------
  [section .text]
;step newest process that isn't dead or running
;inputs: none
;output: carry = all process dead
;        no carry = continue
;
step:
  mov	ebp,pid_table
step_lp1:
  cmp	[ebp+pids.pid],dword 0	;end of table
  je	step_lp2  	;jmp if end of table found
  add	ebp,pids_struc_size ;move to next pid
  jmp	short step_lp1  ;loop till table end
;start process from end of table to beginning
step_lp2:
  sub	ebp,pids_struc_size	;move to next pid
  or	eax,byte -1		;preload no pids running status
  cmp	ebp,pid_table		;end of table
  jnb	step_05			;jmp if pid found
  jmp	step_98			;exit if all pids dead
step_05:
  and	[ebp+pids.pid_status],byte ~0c1h	;clear show,fork bits
;check if this pid needs starting
  test	[ebp+pids.pid_status],byte 10h	;running?
  jnz	step_lp2		;jmp if running
  test	[ebp+pids.pid_status],byte 8  ;dead
  jnz	step_lp2		;jmp if dead
;check if trigger off
  call	check_trigger_off
  test	[report_flag],byte 1	;triggers now off?
  jnz	step_07			;jmp if triggers on
  jmp	step_99			;exit & continue
;check if fork here
step_07:
;read instruction to be stepped
  mov	edx,[ebp+pids.r_eip]	;read address
  mov	esi,bin_instruction	;bin data
  mov	edi,12			;read length
  call	trace_peek_bytes
;check if this is fork
  cmp	[bin_instruction],word 080cdh	;int 80h?
  jne	step_09		;jmp if not int 80h
  mov	eax,[ebp+pids.r_eax]		;get eax
  mov	[ebp+pids.r_sav_old_eax],eax	;save eax
  call	fork_modify
step_09:
;step this pid
  mov	eax,[ebp+pids.pid]	;setup for ptrace call
  mov	[trace_pid],eax		;get process id
  mov	esi,[send_signal]	;send any pending signals
  mov	[send_signal],dword 0	;set no special signal flag
  call	trace_step
  or	[ebp+pids.pid_status],byte 10h	;set running bit

%ifdef LOG
  call	log_step
%endif
  jns	step_10			;jmp if no error
  jmp	step_98			;jmp if error
step_10:  
  call	trace_wait		;wait for any child stop
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
%ifdef LOG
  call	log_wait
%endif
  or	eax,eax
  jnz	pid_10			;jmp if possible pid
  jmp	step_98			;jmp if all pids dead
pid_10:
;check if this pid is in table
  mov	ebp,pid_table
pid_table_lp:
  cmp	[ebp+pids.pid],dword 0	;end of table?
  je	_new_pid		;jmp if not in table
  cmp	eax,[ebp + pids.pid]	;process found?
  je	_found_pid		;jmp if process match
  add	ebp,pids_struc_size	;move to next process
  jmp	short pid_table_lp	;loop
;ebp points to new pid entry
_new_pid:
  mov	[ebp+pids.pid],eax ;insert pid#
  mov	[ebp+pids.wait_status],ebx ;insert wait4 status
  mov	[trace_pid],eax ;store process_id
  lea	esi,[ebp+pids.r_ebx]
  call	trace_regsget
  mov	eax,[ebp+pids.r_eip]
  mov	[ebp+pids.r_old_eip],eax
  mov	[ebp+pids.pid_status],byte 06h ;set stopped state
  call	report_new_process
;  jmp	step_96
  jmp	step_10
_found_pid:
  mov	[trace_pid],eax	;set this pid for library call
  mov	[ebp+pids.wait_status],ebx
  lea	esi,[ebp+pids.r_ebx]
  call	trace_regsget
;check for signal or process death
  mov	eax,[ebp+pids.wait_status]	;get wait status
;check if dead
  or	al,al
  jz	_dead_pid1		;jmp if process exit
;check if fork in process
  test	[ebp+pids.pid_status],byte 20h
  jz	step_12
  push	eax
  call	_fork_restore
  pop	eax
step_12:
;check if this is signal
  cmp	ax,1100h		;normal exit
  je	step_70			;jmp if normal exit
  cmp	al,7fh			;nornal signal
  jne	_dead_pid		;jmp if unexpected signal
  cmp	ah,05			;break signal
  je	_found_break		;jmp if break signal
  cmp	ax,137fh		;sigstop
  je	step_72			;jmp if start up signal
  mov	[send_signal],ah
  jmp	short _signal_stop	;jmp if signal
;unknown stop?
step_70:
  call	report_death
  mov	[ebp+pids.pid_status],byte 08h
  jmp	step_80  
step_72:
  mov	[ebp+pids.pid_status],byte 4h
  jmp	step_96
_dead_pid1:
  call	show_dis
  or	[ebp+pids.pid_status],byte 8	;set dead flag
  call	report_death
  jmp	short step_99
_signal_stop:
  mov	[ebp+pids.pid_status],byte 0c0h ;signal
  jmp	short step_96
_dead_pid:
  mov	[ebp+pids.pid_status],byte 0c8h	;dead status
  call	report_death
  jmp	short step_96  
;this is existing pid at normal break,
_found_break:
  mov	[ebp+pids.pid_status],byte 44h	;report + backend
step_80:
  call	show_dis  

  mov	eax,[ebp+pids.r_eip]	;get eip
  mov	[ebp+pids.r_old_eip],eax ;save eip

  mov	edi,lib_buf
;check if this was a kernel call (int80)
  cmp	[bin_instruction],word 080cdh	;int 80h?
  jne	step_99		;jmp if not int 80h

;report using pid table status
step_96:
  call	report
  inc	dword [sequence]
  and	[ebp+pids.pid_status],byte ~0c1h	;clear status
  jmp	short step_99
step_98:
  stc		;all pids dead flag
  jmp	short step_exit
step_99:
%ifdef LOG
  call	logit
%endif
  clc
step_exit:
  ret

;--------------------------------------------------------------------
fork_modify:
  mov	eax,[ebp+pids.r_eax]	;get function#
; check if fork(2) clone(120) or vfork(190)
  cmp	eax,2		;fork?
  je	sp_fork_found	;jmp if fork
  cmp	eax,120
  jne	_wfs_22			;jmp if not clone
;clone found
  or	[ebp+pids.r_ebx],dword 2000h	;set ptrace bit
  jmp	short _wfs_24
_wfs_22:
  cmp	eax,190
  jne	fm_exit			;jmp if not vfork
;vfork found
sp_fork_found:
  mov	[ebp+pids.r_eax],dword 120	;force clone
  mov	[ebp+pids.r_ebx],dword 2011h	;ptrace bit + sig 11h = stop
  mov	[ebp+pids.r_ecx],dword 0
_wfs_24:
  lea	esi,[ebp+pids.r_ebx]
  call	trace_regsset
  or	[ebp+pids.pid_status],byte 20h		;set fork in process
fm_exit:
 ret
;-----------------------------------------------
;Restore munged fork,vfork,clone data.
_fork_restore:
  mov	[timeout],byte 2
_fr_lp:
  lea	esi,[ebp+pids.r_ebx]
  call	trace_regsget
  or	eax,eax
  jns	_fr_01
;sometimes we get error ffffffd here (no such process).  I
;think this means registers for this process have not been
;updated yet.  If we try again after a delay it works.
  mov	eax,1
  call	delay
  dec	byte [timeout]
  or	[timeout],al
  jp	_fr_lp
_fr_01:
  mov	eax,[ebp+pids.r_sav_old_eax]	;get function number
; check if fork(2) clone(120) or vfork(190)
  cmp	eax,2		;fork?
  jne	_fr_02		;jmp if not fork
;fork found
  mov	[ebp+pids.r_old_eax],eax	;restore fork
  mov	eax,[ebp+pids.r_sav_ebx]
  mov	[ebp+pids.r_ebx],eax
  mov	eax,[ebp+pids.r_sav_ecx]
  mov	[ebp+pids.r_ecx],eax
  jmp	short _fr_10
_fr_02:
  cmp	eax,120
  jne	_fr_04
;clone found
  mov	eax,[ebp+pids.r_sav_ebx]
  mov	[ebp+pids.r_ebx],eax
  jmp	short _fr_10
_fr_04:
  cmp	eax,190
  jne	_fr_10		;jmp if not vfork
;vfork found
  mov	[ebp+pids.r_old_eax],eax	;restore vfork 
  mov	eax,[ebp+pids.r_sav_ebx]
  mov	[ebp+pids.r_ebx],eax
_fr_10:
  lea	esi,[ebp+pids.r_ebx]
  call	trace_regsset
  mov	eax,[ebp+pids.pid_status]
  and	al,~21h				;clear fork bit
  mov	[ebp+pids.pid_status],eax
  ret
;------------
  [section .data]
timeout db 0
  [section .text]
;-----------------------------------------------
show_dis:
  push	ebp
  mov	edi,lib_buf

  cmp	[parse_show_process],byte 0	;process# wanted?
  je	sd_10			;jmp if no process
;-- add process#
  mov	al,09h
  stosb
  mov	eax,'PID='
  stosd
  mov	ecx,[ebp+pids.pid]	;get process
  push	esi
  mov	esi,8		;store 8 digets
  call	dword_to_hexascii
  pop	esi
  mov	al,'H'
  stosb
  mov	al,' '
  stosb
sd_10:
  push	edi
;read instruction to be reported
  mov	edx,[ebp+pids.r_old_eip];read address
  mov	esi,bin_instruction	;bin data
  mov	edi,12			;read length
  call	trace_peek_bytes
  pop	edi

  mov	al,09h
  stosb				;add tabs to front
;disassemble instruction
  mov	eax,[ebp+pids.r_old_eip]	;address
;  mov	eax,[ebp+pids.r_eip]
  mov	ebp,bin_instruction	;bin data ptr
  push	edi
  call	dis_one
%ifdef LOG
  call	log_dis
%endif
  pop	edi
  pop	ebp
;add address
  push	eax			;save ptr to dis data
  mov	ecx,[ebp+pids.r_old_eip]
  mov	esi,8		;store 8 digets
  call	dword_to_hexascii
  mov	al,' '
  stosb
  pop	eax
;move data to out buffer
  lea	esi,[eax + dis_block.inst]
  call	str_move
;strip off any line feeds
if_remove:
  cmp	byte [edi -1],0ah
  je	if_dis_done
  mov	al,0ah
  stosb
if_dis_done:  
  mov	ecx,lib_buf
  mov	edx,edi		;get buffer start
  sub	edx,ecx		;compute length
  call	outfile_write
if_exit:
  ret
;--------
  [section .data]
decode_entry:
name_offset: dw 0
process_id: db 0
struc_id:   db 0
bin_instruction: times 13 db 0
  [section .text]





