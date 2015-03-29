
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

;----------------------------------------------------------------
;>1 trace
;  traceme - enable trace for this process
; INPUTS  none
; OUTPUT  none
;
; NOTES
;    "traceme" tells the kernel that this process is to be
;    traced by its parent.  Any signal (except SIGKILL)
;    delivered to this process will cause it to stop and
;    the parent notified via wait.  All exec calls will
;    notify the parent with a SIGCHLD signal.
;    Another way to initiate trace is for another process
;    to call the "trace_attach" function.
;    A typical sequence is:
;        mov	eax,20
;        int	80h			;get our pid
;        mov	[parent_pid],eax
;        mov	eax,2
;        int	80h			;fork
;        mov	[trace_pid],eax
;        or	eax,eax
;        jnz	parent
;        -----  child process  -----------------
;        call	traceme
;        mov	esi,executable_filename
;        call	sys_run_die
;        ------ parent process --------------
;     parent:
;        call	trace_wait		;wait till child stopped
;
;    Source file is: trace.inc
;<
  global traceme
traceme:
  xor	ebx,ebx		;tracme request code
t_entry:
  mov	eax,26
  int	80h
  ret


;----------------------------------------------------------------
;>1 trace
;  trace_attach - attach to a running process
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
; OUTPUT  see trace_wait output
;
; NOTES
;    "trace_attach" attaches to a running process.  The
;    attached process is sent a SIGSTOP and we wait
;    till the child to stops before returning.
;    Another way to attach a process is to use the
;    "traceme" function.
;    Source file is: trace.inc
;<
  global trace_attach
trace_attach:
  mov	ecx,[trace_pid]
  mov	ebx,16		;attach request code
  mov	eax,26
  int	80h
  call	trace_wait
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_detach - detach from a process
; INPUTS  
;         [trace_pid] global variable set to child pid
;                     before calling this function.
; OUTPUT  eax = 0 if success
;               flags set for jz (success)
;                             js (error)
; NOTES
;    "trace_detach" restarts the stopped process after
;    undoing the actions of either "attach" or "traceme".
;    Source file is: trace.inc
;<
  global trace_detach
trace_detach:
  mov	ecx,[trace_pid]
  mov	ebx,17		;detach request code
  mov	eax,26
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_continue - restart a stopped process or send signal
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = 0 - normal restart of child
;               n - signal to be sent to child
;                   This signal is returned by wait4
;                   instead of the SIGCHLD
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
;
; NOTES
;    "trace_continue" continue executing a process
;    by either restarting it or sending it a signal
;    Source file is: trace.inc
;<
  global trace_continue
trace_continue:
  mov	ecx,[trace_pid]
  mov	ebx,7		;continue request code
  xor	edx,edx
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret


;----------------------------------------------------------------
;>1 trace
;  trace_syscall - continue execution till system call
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = signal for child or zero
;               This signal is sent to traced
;               process
;               
; OUTPUT  eax = 0 if success
;               flags set for jz (success)
;                             js (error)
; NOTES
;    "trace_syscall" restarts the stopped process
;    and stops at next syscall entry or exit.  Signals
;    will also stop execution.  Process will appear to
;    be stopped by SIGTRAP signal.
;    Normally, we would wait for target process to
;    stop by doing a wait4 syscall next.
;<
  global trace_syscall
trace_syscall:
  mov	ecx,[trace_pid]
  mov	ebx,24		;syscall request code
  xor	edx,edx
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret


;----------------------------------------------------------------
;>1 trace
;  trace_step - continue execution for one instruction
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = optional signal number to send child
;                   This signal is returned by wait4
;                   instead of the SIGCHLD
;               
; OUTPUT  eax = 0 if success
;               flags set for jz (success)
;                             js (error)
; NOTES
;    "trace_step" restarts the stopped process
;    and stops after next instruction.  Signals
;    will also stop execution.  Process will appear to
;    be stopped by SIGCHLD signal.
;<
  global trace_step
trace_step:
  mov	ecx,[trace_pid]
  mov	ebx,9		;step request code
  xor	edx,edx
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret


;----------------------------------------------------------------
;>1 trace
;  trace_kill - kill a process being traced
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;               
; OUTPUT  eax = 0 if success
;               flags set for jz (sucess)
;                             js (error)
;
; NOTES
;    "trace_kill" sends a SIGKILL to the traced
;    process.
;<
  global trace_kill
trace_kill:
  mov	ecx,[trace_pid]
  mov	ebx,8		;kill request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_regsget - get registers of traced process
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = pointer to register storeage area
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
;   if success ecx points to register structure as follows:
;   struc regs
;     .r_ebx resd 1
;     .r_ecx resd 1
;     .r_edx resd 1
;     .r_esi resd 1
;     .r_edi resd 1
;     .r_ebp resd 1
;     .r_eax resd 1
;     .r_ds  resd 1
;     .r_es  resd 1
;     .r_fs  resd 1
;     .r_gs  resd 1
;     .r_old_eax resd 1
;     .r_eip resd 1
;     .r_cs  resd 1
;     .r_flags resd 1
;     .r_esp resd 1
;     .r_ss  resd 1
;   endstruc
;
; NOTES
;    "trace_regsget" copies the traced process registers
;    to buffer pointed at by -esi-
;<
  global trace_regsget
trace_regsget:
  mov	ecx,[trace_pid]
  xor	edx,edx		;unused register
  mov	ebx,12		;getregs request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_regsset - set registers of traced process
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = pointer to register storeage area
;   struc regs
;     .r_ebx resd 1
;     .r_ecx resd 1
;     .r_edx resd 1
;     .r_esi resd 1
;     .r_edi resd 1
;     .r_ebp resd 1
;     .r_eax resd 1
;     .r_ds  resd 1
;     .r_es  resd 1
;     .r_fs  resd 1
;     .r_gs  resd 1
;     .r_old_eax resd 1
;     .r_eip resd 1
;     .r_cs  resd 1
;     .r_flags resd 1
;     .r_esp resd 1
;     .r_ss  resd 1
;   endstruc
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
;
; NOTES
;    "trace_regsset" copies the data to traced process
;    registers.
;<
  global trace_regsset
trace_regsset:
  mov	ecx,[trace_pid]
  mov	ebx,13		;getregs request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_peek - get data from traced process memory
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         edx = address within target process
;         esi = pointer to storage dword
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
; NOTES
;    "trace_peek" copies data from the traced process
;    to our buffer.
;<
  global trace_peek
trace_peek:
  mov	ecx,[trace_pid]
  mov	ebx,2		;peekdata request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_peek_bytes - get string from traced process memory
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         edx = address within target process
;         esi = pointer to storage dword
;         edi = number of bytes to read
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
; NOTES
;    "trace_peek" copies data from the traced process
;    to our buffer.
;<
  global trace_peek_bytes
trace_peek_bytes:
  test	edi,0fffffffch	;is count greater than 3
  jz	tpb_50		;jmp if count 3 or less
;count is 4 or greater
  call	trace_peek
  js	tpb_done	;jmp if error
  sub	edi,4		;adjust count
  add	esi,4		;move forward in buffer
  add	edx,4		;move forward in child memory
  jmp	short trace_peek_bytes
;count is 3 or less
tpb_50:
  or	edi,edi
  jz	tpb_done	;jmp if no more bytes to read
  push	esi		;save buffer
  mov	esi,trace_status;temporary buffer
  call	trace_peek
  pop	ecx		;restore callers buffer ptr
  js	tpb_done	;jmp if error
  xchg	edi,ecx
;edi=callers buffer  ecx=count  esi=ptr to dword read
  cld
  rep	movsb
tpb_done:
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_poke - store data into traced process menory
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         edx = address within target process
;         esi = data to stuff           
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
; NOTES
;    "trace_poke" copies data from our buffer to
;    traced process
;<
  global trace_poke
trace_poke:
  mov	ecx,[trace_pid]
  mov	ebx,5		;pokedata request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_poke_bytes - store string into traced process
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         edx = address within target process
;         esi = pointer to stuff data
;         edi = count of bytes to store
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
; NOTES
;    "trace_poke" copies data from our buffer to
;    traced process
;<
  global trace_poke_bytes
trace_poke_bytes:
  test	edi,0fffffffch	;is count greater than 3
  jz	tpb_40		;jmp if count 3 or less
;count is 4 or greater
  push	esi		;save ptr to input data
  mov	esi,[esi]	;get data
  call	trace_poke
  pop	esi		;restore input data ptr
  js	tp_done		;jmp if error
  sub	edi,4		;adjust count
  add	esi,4		;move forward in buffer
  add	edx,4		;move forward in child memory
  jmp	short trace_poke_bytes
;count is 3 or less, read dword from child and
;insert partial data, then write out adjusted dword
; edi = count of remaining bytes
; esi = ptr to input buffer
; edx = output address (in child memory) 
tpb_40:
  push	esi		;save buffer pointer
  mov	esi,trace_status
  call	trace_peek	;get current contents of child mem
  pop	esi
  js	tp_done
  mov	ecx,edi		;count to ecx
;  mov	edi,esi		;edi = input buffer ptr
  mov	edi,trace_status
  cld
  rep	movsb		;move partial data to dword from child
;write final dword
  mov	esi,[trace_status];restore buffer
  call	trace_poke	;write final dword
tp_done:
  or	eax,eax
  ret    

;----------------------------------------------------------------
;>1 trace
;  trace_wait - wait for any child to stop
; INPUTS   [trace_pid] is set by parent
;          this is a global variable
; OUTPUT
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;
;         if eax negative then error, else ebx is:
;         ebx = child status if eax = child pid
;            bl=status (7fh)-normal trace stop
;                      (00) -exception code in status
;            bh=signal if status non zero else exception
;                      signal was not caught
;
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
; NOTES
;    Any signal to child will stop at trace_wait before delivery.
;    To send the signal to child see: trace_step,trace_cont, or
;    trace_syscall.
;    Source file: trace.asm
;<
  global trace_wait
trace_wait:
;  mov	ecx,[trace_pid]
  mov	eax,114			;wait4
  mov	ebx,-1			;wait for any child
  mov	ecx,trace_status	;store status here
  xor	edx,edx			;options
  xor	esi,esi			;rusage
  mov	[ecx],esi		;clear status area
  int	80h
  mov	ebx,[ecx]		;get status
;eax = pid, or error
;ebx = status word
  ret
;---------
  [section .data]
trace_status dd	0
global trace_pid
trace_pid    dd 0
  [section .text]
