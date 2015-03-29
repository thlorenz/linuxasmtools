
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
;>1 signal
;  signal_wait - wait for signals
; INPUTS  none
; OUTPUT  eax = signal mask indicating which signals occured.
;               After signal has been handled we resume execution.
;               Multiple bits can be set as follows:
;               00000001h = signal#1 SIGHUP
;               00000004h = signal#3 SIGQUIT
; -------          ---       ----    -----------------------------------------------------------
; SIGHUP	     1	     Term    Hangup detected on controlling terminal
;				     or death of controlling process
; SIGINT	     2	     Term    Interrupt from keyboard
; SIGQUIT	     3	     Core    Quit from keyboard
; SIGILL	     4	     Core    Illegal Instruction
; SIGTRAP	     5       Core    Trace/breakpoint trap
; SIGABRT	     6	     Core    Abort signal from abort(3)
; SIGIOT	     6       Core    IOT trap. A synonym for SIGABRT
; SIGBUS	     7       Core    Bus error (bad memory access)
; SIGFPE	     8	     Core    Floating point exception
; SIGKILL	     9	     Term    Kill signal
; SIGUSR1	    10       Term    User-defined signal 1
; SIGSEGV	    11	     Core    Invalid memory reference
; SIGUSR2	    12       Term    User-defined signal 2
; SIGPIPE	    13	     Term    Broken pipe: write to pipe with no readers
; SIGALRM	    14	     Term    Timer signal from alarm(2)
; SIGTERM	    15	     Term    Termination signal
; SIGSTKFLT         16       Term    Stack fault on coprocessor (unused)
; SIGCHLD	    17       Ign     Child stopped or terminated
; SIGCONT	    18   	     Continue if stopped
; SIGSTOP	    19       Stop    Stop process
; SIGTSTP	    20       Stop    Stop typed at tty
; SIGTTIN	    21       Stop    tty input for background process
; SIGTTOU	    22       Stop    tty output for background process
; SIGURG	    23       Ign     Urgent condition on socket (4.2 BSD)
; SIGXCPU	    24       Core    CPU time limit exceeded (4.2 BSD)
; SIGXFSZ	    25       Core    File size limit exceeded (4.2 BSD)
; SIGVTALRM         26       Term    Virtual alarm clock (4.2 BSD)
; SIGPROF	    27       Term    Profiling timer expired
; SIGWINCH	    28       Ign     Window resize signal (4.3 BSD, Sun)
; SIGIO	            29       Term    I/O now possible (4.2 BSD)
; SIGPWR	    30       Term    Power failure (System V)
; SIGINFO	    30  	       A synonym for SIGPWR
; SIGUNUSED         31       Term    Unused signal (will be SIGSYS)
;
; Term   Default action is to terminate the process.
; Ign    Default action is to ignore the signal.
; Core   Default action is to terminate the process and dump core.
; Stop   Default action is to stop the process.
;
; NOTES
;    When first entered signal_wait installs signal handlers
;    for all signals and then watches them.  Any signal handlers
;    installed before signal_wait will not be active.
;
;    The caller can install signal handlers after this but
;    signal_wait will no longer be able to determine the type
;    of signal for callers handler.  Instead it will return a
;    zero status bit when signal occurs.
;    Source file is: sgnal_wait.asm
;<
; *  ----------------------------------------------
;*******
  global signal_wait
signal_wait:
  cmp	byte [installed_flag],0
  jne	start_wait
;install handlers if first time
  call	signal_wait_setup
;wait for next signal
start_wait:
  cmp	dword [sigmask],0	;check if any signals have arrived
  jnz	got_signal		;jmp if signal found
  mov	eax,29
  int	80h
got_signal:
  mov	eax,[sigmask]
  mov	dword [sigmask],0	;clear the mask
  ret
;----------------------------------------
install_table:
  db  SIGHUP-top   ;    1      yes     yes
  db  SIGINT-top   ;    2      yes     yes
  db  SIGQUIT-top  ;    3      yes     yes
  db  SIGILL-top   ;    4      yes     no (log_signal aborts program)
  db  SIGTRAP-top  ;    5      yes     yes
  db  SIGABRT-top  ;    6      yes     no (log_signal aborts program)
  db  SIGBUS-top   ;    7      yes     yes   
  db  SIGFPE-top   ;    8      yes     no (log_signal aborts program)
  db  -1           ;SIGKILL 9       no     no
  db  SIGUSR1-top  ;    10     yes     yes
  db  SIGSEGV-top  ;    11     yes     no (log_signal aborts program)
  db  SIGUSR2-top  ;    12     yes     yes
  db  SIGPIPE-top  ;    13     yes     yes
  db  SIGALRM-top  ;    14     yes     yes
  db  SIGTERM-top  ;    15     yes     no (log_signal aborts program)
  db  SIGSTKFLT-top;    16     yes     yes
  db  SIGCHLD-top  ;    17     yes     yes
  db  SIGCONT-top  ;    18     yes     yes
  db  -1           ;SIGSTOP 19      no     no
  db  SIGTSTP-top  ;    20     yes     yes
  db  SIGTTIN-top  ;    21     yes     yes
  db  SIGTTOU-top  ;    22     yes     yes
  db  SIGURG-top   ;    23     yes     yes
  db  SIGXCPU-top  ;    24     yes     yes
  db  SIGXFSZ-top  ;    25     yes     yes
  db  SIGVTALRM-top;    26     yes     yes
  db  SIGPROF-top  ;    27     yes     yes
  db  SIGWINCH-top ;    28     yes     yes
  db  SIGIO-top    ;    29     yes     yes
  db  0 ;	end of table

top:
  db	0		;dummy entry to fix loop check
SIGHUP:
  mov	al,1
  jmp	short sig_rtn1
SIGINT:  ;       2      yes     yes
  mov	al,2
  jmp	short sig_rtn1
SIGQUIT: ;      3      yes     yes
  mov	al,4
  jmp	short sig_rtn1
SIGILL:  ;       4      yes     no (log_signal aborts program)
  mov	al,8
  jmp	short sig_rtn1
SIGTRAP: ;      5      yes     yes
  mov	al,10h
  jmp	short sig_rtn1
SIGABRT: ;      6      yes     no (log_signal aborts program)
  mov	al,20h
  jmp	short sig_rtn1
SIGBUS:  ;     7      yes     yes   
  mov	al,40h
  jmp	short sig_rtn1
SIGFPE:  ;    8      yes     no (log_signal aborts program)
  mov	al,80h
sig_rtn1:
  or	byte [sigmask],al
  jmp	sig_rtn5

;SIGKILL        9      01h

SIGUSR1: ;      10     yes     yes
  mov	al,02h
  jmp	short sig_rtn2
SIGSEGV: ;      11     yes     no (log_signal aborts program)
  mov	al,04h
 jmp	short  sig_rtn2
SIGUSR2: ;      12     yes     yes
  mov	al,08h
  jmp	short sig_rtn2
SIGPIPE: ;      13     yes     yes
  mov	al,10h
  jmp	short sig_rtn2
SIGALRM: ;      14     yes     yes
  mov	al,20h
  jmp	short sig_rtn2
SIGTERM: ;      15     yes     no (log_signal aborts program)
  mov	al,40h
  jmp	short sig_rtn2
SIGSTKFLT: ;    16     yes     yes
  mov	al,80h
sig_rtn2:
  or	byte [sigmask+1],al
  jmp	sig_rtn5

SIGCHLD: ;      17     yes     yes
  mov	al,01h
  jmp	short sig_rtn3
SIGCONT: ;      18     yes     yes
  mov	al,02h
  jmp	short sig_rtn3

;SIGSTOP        19       04h

SIGTSTP: ;      20     yes     yes
  mov	al,08h
  jmp	short sig_rtn3
SIGTTIN: ;      21     yes     yes
  mov	al,10h
  jmp	short sig_rtn3
SIGTTOU: ;      22     yes     yes
  mov	al,20h
  jmp	short sig_rtn3
SIGURG:  ;       23     yes     yes
  mov	al,40h
  jmp	short sig_rtn3
SIGXCPU: ;      24     yes     yes
  mov	al,80h
sig_rtn3:
  or	byte [sigmask+2],al
  jmp	sig_rtn5

SIGXFSZ: ;      25     yes     yes
  mov	al,01h
  jmp	short sig_rtn4
SIGVTALRM: ;    26     yes     yes
  mov	al,02h
  jmp	short sig_rtn4
SIGPROF: ;      27     yes     yes
  mov	al,04h
  jmp	short sig_rtn4
SIGWINCH: ;     28     yes     yes
  mov	al,08h
  jmp	short sig_rtn4
SIGIO:   ;        29     yes     yes
  mov	al,10h
sig_rtn4:
  or	byte [sigmask+3],al

sig_rtn5:
  ret
;---
  [section .data]

installed_flag	db 0	;set to 1 after handlers installed

sigmask	dd	0	;signal bit flag
; signal install template
sig_number:
; db 4   ;signal illegal action SIGILL
sig_handler:
 dd 0   ;handleIll
 dd 0
 dd 0	;4   ;set siginfo telling kernel to pass status data to handler
 dd 0
 dd 0

;signal_flag:	dd	0	;bit flag, see top
  [section .text]

;----------------------------------------------------------------
;>1 signal
;  signal_wait_setup - optional setup for signal_wait function
; INPUTS  none
; OUTPUT  none
;
; NOTES: Use this function to avoid race conditions.  It sets
;        up signal handlers for the signal_wait function call.
;        It is needed if signals can occur before the signal_wait
;        function is ready for them.  If this setup is done at top
;        of a program it will detect any signals that occur and
;        the signal_wait can be called at any time, even if the
;        signal has already occured.
;        If race conditions do not exist, then this function can
;        be ignored and signal_wait will set up when called.
;<
; *  ----------------------------------------------
;*******

  global signal_wait_setup
signal_wait_setup:
  mov	esi,install_table
  mov	ebx,1			;start with signal #1
ls_loop:
  xor	eax,eax			;clear eax
  lodsb				;get table entry
  or	al,al
  jz	ls_done			;exit if done
  cmp	al,-1
  je	ls_lp_end
  add	eax,top			;compute handler address
  mov	dword [sig_handler],eax  
  mov	eax,67
  mov	ecx,sig_number
  int	80h
ls_lp_end:
  inc	ebx
  jmp	short ls_loop
ls_done:
  mov	byte [installed_flag],1
  ret
;----------------------------------------------------------------
;>1 signal
;  signal_wait_blind - wait for any signal that is handled.
; INPUTS  none
; OUTPUT  none
;
; NOTES: returns to caller after the signal handler exits.
;        The type of signal is not known.
;<
; *  ----------------------------------------------
;*******

global signal_wait_blind
signal_wait_blind:
  mov	eax,29
  int	80h
  ret

;----------------------------------------------------------------
;>1 signal
;  signal_wait_child - wait for child termination signal
; INPUTS  ebx = child pid (process id)
; OUTPUT
;         We resume execution before signal is handled
;         with registers set as follows:
;         eax= pid if signal, and status is in ecx
;              0 if child terminated, no status in ecx
;         cl = status byte 7fh = ptrace stop
;         ch = possibly a signal number
;         
; NOTES:  see man page for "waitpid" for information
;         on status byte and options.
;         This function uses the kernel waitpid(7) call.
;         Source file is: signal_wait.asm       
;<
; *  ----------------------------------------------
;*******

global signal_wait_child
signal_wait_child:
  mov	ecx,status		;pointer to status store area
  xor	eax,eax
  mov	[ecx],eax		;clear status word
  mov	edx,1			;WNOHANG - returns if child terminated
  mov	eax,7			;kernel call waitpid
  int	80h
  mov	ecx,[status]
  ret
  [section .data]
status	dd	0
  [section .text]

