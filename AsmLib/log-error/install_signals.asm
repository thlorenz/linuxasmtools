
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


;----------------------------------------------------------------------
;  This program is free software; you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program; if not, write to the Free Software
;  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;----------------------------------------------------------------------
;

  [section .text]

;Standard Signals
; Linux supports the standard signals listed below.
;
; The  entries  in  the  "Action" column of the table specify the default
; action for the signal, as follows:
;
; Term   Default action is to terminate the process.
; Ign    Default action is to ignore the signal.
; Core   Default action is to terminate the process and dump core.
; Stop   Default action is to stop the process.
;
; First the signals described in the original POSIX.1 standard.
;
; Signal	  Value	    Action   Comment
; -------------------------------------------------------------------------
; SIGHUP	     1	     Term    Hangup detected on controlling terminal
;				     or death of controlling process
; SIGINT	     2	     Term    Interrupt from keyboard
; SIGQUIT	     3	     Core    Quit from keyboard
; SIGILL	     4	     Core    Illegal Instruction
; SIGABRT	     6	     Core    Abort signal from abort(3)
; SIGFPE	     8	     Core    Floating point exception
; SIGKILL	     9	     Term    Kill signal
; SIGSEGV	    11	     Core    Invalid memory reference
; SIGPIPE	    13	     Term    Broken pipe: write to pipe with no readers
; SIGALRM	    14	     Term    Timer signal from alarm(2)
; SIGTERM	    15	     Term    Termination signal
; SIGUSR1	    10       Term    User-defined signal 1
; SIGUSR2	    12       Term    User-defined signal 2
; SIGCHLD	    17       Ign     Child stopped or terminated
; SIGCONT	    18   	     Continue if stopped
; SIGSTOP	    19       Stop    Stop process
; SIGTSTP	    20       Stop    Stop typed at tty
; SIGTTIN	    21       Stop    tty input for background process
; SIGTTOU	    22       Stop    tty output for background process
;
; The signals SIGKILL and SIGSTOP cannot be caught, blocked, or  ignored.
;
; Next the signals not in the POSIX.1 standard
; -------------------------------------------------------------------------
; SIGBUS	      7        Core    Bus error (bad memory access)
; SIGPOLL		       Term    Pollable event (Sys V). Synonym of SIGIO
; SIGPROF	      27       Term    Profiling timer expired
; SIGTRAP	      5	       Core    Trace/breakpoint trap
; SIGURG	      23       Ign     Urgent condition on socket (4.2 BSD)
; SIGVTALRM           26       Term    Virtual alarm clock (4.2 BSD)
; SIGXCPU	      24       Core    CPU time limit exceeded (4.2 BSD)
; SIGXFSZ	      25       Core    File size limit exceeded (4.2 BSD)
;
; Up to and including Linux 2.2, the default behaviour for SIGSYS,  SIGX-
; CPU,  SIGXFSZ,  and SIGBUS
; was to terminate the process (without a core  dump).
; Linux  2.4  conforms to  the  POSIX
; 1003.1-2001  requirements  for  these  signals, terminating the process
; with a core dump.
;
; Next various other signals.
;
; Signal	    Value     Action   Comment
; --------------------------------------------------------------------
; SIGIOT	      6	       Core    IOT trap. A synonym for SIGABRT
; SIGSTKFLT          16       Term    Stack fault on coprocessor (unused)
; SIGIO	             29       Term    I/O now possible (4.2 BSD)
; SIGPWR	      30       Term    Power failure (System V)
; SIGINFO	       -  	       A synonym for SIGPWR
; SIGLOST	      -        Term    File lock lost
; SIGWINCH	      28       Ign     Window resize signal (4.3 BSD, Sun)
; SIGUNUSED           31       Term    Unused signal (will be SIGSYS)
;
; SIGPWR (which is not  specified in  POSIX  1003.1-2001)  is  typically
; ignored by default on those other Unices where it appears.
;
; SIGIO  (which  is  not  specified  in  POSIX 1003.1-2001) is ignored by
; default on several other Unices.
;
;Real-time Signals
; Linux supports real-time signals as originally defined in  the  POSIX.4
; real-time  extensions  (and  now included in POSIX 1003.1-2001).	 Linux
; supports 32 real-time  signals, numbered  from 32  (SIGRTMIN)	to  63
; (SIGRTMAX).   (Programs should always refer to real-time signals using
; notation SIGRTMIN+n, since the range of real-time signal numbers varies
; across Unices.)

;****f* err/install_signals *
;
; NAME
;>1 log-error
;  install_signals - install signals
; INPUTS
;     ebp = pointer to  table describing each signal to install.
;     The table is terminated with a zero byte in the signal number
;     field.
;       Sanple table entry for to install the SIGILL signal.
;     db 4			;signal illegal action SIGILL
;     dd handleIll		;handler for signal
;     dd 0
;     dd 4			;set siginfo telling kernel to pass status data to handler
;     dd 0			;always zero
;   
; NOTES
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global install_signals
install_signals:
is_loop:
	sub	ebx,ebx
	mov	bl,[ebp]	;get signal number
	inc	ebp		;move to top of sa_block
	mov	eax,67		;kernel code for sigaction
	mov	ecx,ebp
	xor	edx,edx
	int	80h		;install signal handler
;        call	error_check
	add	ebp,16		;move to next table entry
	cmp	byte [ebp],0	;done?
	jnz	is_loop		;loop till done
	ret
;------------------------------------------------------
; Signals are installed using the information in signal_table.
; The signal_table can have multiple signals described and each
; description reqrires 5 entries as follows:
;
; The first byte of a signal_table entry indicates which
; signal we plan to install.  The available signals are:
;
;  1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL
;  5) SIGTRAP      6) SIGIOT       7) SIGBUS       8) SIGFPE
;  9) SIGKILL     10) SIGUSR1     11) SIGSEGV     12) SIGUSR2
; 13) SIGPIPE     14) SIGALRM     15) SIGTERM     17) SIGCHLD
; 18) SIGCONT     19) SIGSTOP     20) SIGTSTP     21) SIGTTIN
; 22) SIGTTOU     23) SIGURG      24) SIGXCPU     25) SIGXFSZ
; 26) SIGVTALRM   27) SIGPROF     28) SIGWINCH    29) SIGIO
; 30) SIGPWR

; The second field is a a pointer to our local handler

; The third field in signal_table is sa_mask 
;        The  sa_mask, specifies which signals
;        should be blocked when the signal handler is being run. A blocked
;        signal is not delivered until it is unblocked. By letting the
;        program specify an arbitrary set of signals that should be blocked
;        when a given signal is being caught, the kernel makes it quite easy
;        to have a signal handler catch a number of different signals and
;        still never be reinvoked while it's already running.
;
;        By default, the kernel always blocks a signal when its signal
;        handler is being run. For example, when a SIGCHLD signal handler is
;        running, the kernel will block other SIGCHLDs from being delivered;
;
; The fourth field in signal_table is sa_flags 
;        The sa_flags field is a bitmask of various flags logically ORed
;        together, the combination of which specifies the kernel's behavior
;        when the signal is received. The values it may contain are:
;
;        SA_NOCLDSTOP: A SIGCHLD signal is normally generated when one of a
;        process's children has terminated or stopped. If this flag is
;        specified, SIGCHLD is generated only when a child process has
;        terminated, stopped children will not cause any signal.
;
;        SA_NOMASK: Remember that a program can't use the sa_mask field of
;        sigaction to allow a signal to be sent while its signal handler is
;        currently running? This flag gives the opposite behavior, allowing
;        a signal handler to be interrupted by the delivery of the same
;        signal.
;
;        SA_NOMASK: For several reasons, SA_ NOMASK is a very bad idea,
;        since it makes it impossible to write a properly functioning signal
;        handler. It's included in the POSIX signal API because many old
;        versions of Unix provided this behavior (this is one of the
;        behaviors the term "unreliable signals" describes), and the POSIX
;        group wanted to be able to emulate that behavior for old
;        applications that relied on it.
;
;        SA_ONESHOT: If this flag is specified, as soon as the signal
;        handler for this signal is run, the kernel will reset the signal
;        handler for this signal to SIG_DFL. Like SA_NOMASK, this is a bad
;        idea. (In fact, this is the other behavior associated with
;        unreliable signal implementations.) It is provided for two reasons.
;        The first is to enable emulation of older platforms. The second is
;        that ANSI C requires this type of signal behavior, and POSIX had to
;        live with that not-so-bright decision.
;
;        SA_RESTART: Normally slow system calls return EINTR when a signal
;        is delivered while they are running. If SA_RESTART is specified,
;        the system calls don't return (the kernel automatically restarts
;        them) after a signal is delivered to the process. I talked last
;        month about why this is handy.
;
;               SA_NOCLDSTOP  0x0000 0001
;               SA_NOCLDWAIT  0x0000 0002
;               SA_SIGINFO    0X0000 0004	;returns status info about signal
;               SA_ONESTACK   0x0800 0000
;               SA_RESTART    0X1000 0000
;               SA_NODEFER    0X4000 0000   alias SA_NODEFER
;               SA_RESETHAND  0X8000 0000   alias SA_ONESHOT
;               SA_RESTORER   0X0400 0000
;              
; The fifth field in each signal_table entry is SA_RESTORER. This field is not used
;------------------------------------------------------
; signal_table is used to install signal handlers

;signal_table:
; db 4			;signal illegal action SIGILL
; dd handleIll
; dd 0
; dd 4			;set siginfo telling kernel to pass status data to handler
; dd 0
;
;  db 5			;signal trap action SIGTRAP
;  dd handleTrap
;  dd 0
;  dd 4
;  dd 0
;
;  db 8			;signal floating point action SIGFPE
;  dd handleFPE
;  dd 0
;  dd 4
;  dd 0

;  db 9			;we are being killed
;  dd handleKill	;note:  we can't handle this signal, it is automatic
;  dd 0
;  dd 0
;  dd 0

;  db 11			;signal number,  segv action SIGSEGV
;  dd handleSegv		;sa_handler
;  dd 0			;sa_mask
;  dd 4			;sa_flags, 4=SA_SIGINFO (puts info on stack)
;  dd 0			;sa_restorer (unused)
;
;  note: the following do not have SIGINFO bit set, so handler isn't
;        passed any parameters.


;  db 15			;we are being asked to terminate
;  dd handleTerm
 ; dd 0
 ; dd 0
;  dd 0

;  db 28			;enable SIGWINCH window resize
;  dd handleWINCH
;  dd 0
;  dd 0
;  dd 0

;  note: the following do not have SIGINFO bit set, so handler isn't
;        passed any parameters.

;  db 28			;enable SIGWINCH window resize
;  dd handleWINCH
;  dd 0
;  dd 0
;  dd 0

;  db 2			;enable SIGINT ctrl-c if TERMIOS allows
;  dd handleCtrlc
;  dd 0
;  dd 0
;  dd 0

; db 18		
; dd handler
; dd 0
; dd 0
; dd 0

;  db 0			;end of table indicator

;---------------------------------------------------
;
; Signal handlers are passed three parameters if    
; SA_SIGINFO was specified in sa_flags.  They are:
; signal number, ptr to siginfo_t, ptr to ucontext_t
; These parmaters are on the stack (see example handlers)
;
;	      siginfo_t {
;	0	  int	   si_signo;  /* Signal number */
;	4	  int	   si_errno;  /* An errno value */
;	8	  int	   si_code;   /* Signal code */
;	  	  pid_t	   si_pid;    /* Sending process ID */
;	  	  uid_t	   si_uid;    /* Real user ID of sending process */
;	  	  int	   si_status; /* Exit value or signal */
;	  	  clock_t  si_utime;  /* User time consumed */
;	  	  clock_t  si_stime;  /* System time consumed */
;	  	  sigval_t si_value;  /* Signal value */
;	  	  int	   si_int;    /* POSIX.1b signal */
;	  	  void *   si_ptr;    /* POSIX.1b signal */
;	  	  void *   si_addr;   /* Memory location which caused fault */
;	  	  int	   si_band;   /* Band event */
;	  	  int	   si_fd;     /* File descriptor */
;	      }
;  si_signo,  si_errno  and si_code are defined for all signals.  The rest
;  of the struct may be a union, so that one should only read  the	fields
;  that  are  meaningful  for the given signal.  kill(2), POSIX.1b signals
;  and SIGCHLD fill in si_pid and si_uid.	SIGCHLD also fills in  si_sta-
;  tus,  si_utime  and  si_stime.	si_int and si_ptr are specified by the
;  sender of the POSIX.1b signal.  SIGILL, SIGFPE, SIGSEGV and SIGBUS fill
;  in si_addr with the address of the fault.  SIGPOLL fills in si_band and
;  si_fd.
;
;  si_code indicates why this signal was sent.  It is a value, not a  bit-
;  mask.   The values which are possible for any signal are listed in this
;  table:
;    	      si_code	
;  +-----------+------------------------+
;   Value	     Signal origin	     
;  +-----------+------------------------+
;   SI_USER      kill, sigsend or raise =0  
;   SI_KERNEL    The kernel		=80h
;   SI_QUEUE     sigqueue		=-1
;   SI_TIMER     timer expired	        =-2
;   SI_MESGQ     mesq state changed	=-3
;   SI_ASYNCIO   AIO completed	        =-4
;   SI_SIGIO     queued SIGIO	        =-5

;---------------------------------------------------
; signal handlers follow
;---------------------------------------------------

; we are being asked to stop by kernel or terminal
;  
;handleTerm:
;  mov	eax,112
;  jmp	Raise

;  	      SIGSEGV - segment error			     
;  +------------+---------------------------------------+
;  |SEGV_MAPERR | address not mapped to object	        =1
;  |SEGV_ACCERR | invalid permissions for mapped object =2
;
; This signal handles segment violations and always forces
; an exit.  Some information is found by looking into kernel
; code and isn't described in this document.
;
;handleSegv:
;	mov	eax,dword [esp + 8]	;get siginfo_t ptr
;   	mov    eax,DWORD [eax+68]	;reach into kernel
;  	cmp    eax,0x4
;   	je     DoINTO
;    	cmp    eax,0x5
;    	je     DoBOUND
;  	mov    eax,0127		;code for "memory access violation"
;    	jmp    Raise
;
;DoINTO:	mov    eax,0128		;code for "Integer overflow (INTO instr)"
;  	jmp    Raise
;
;DoBOUND:mov    eax,0129		;code for "Bounds violation (BOUND instruction)
;   	jmp    Raise
;---------------------------------------------------

;      SIGTRAP - signal handler		 
;  +-----------+--------------------+
;  |TRAP_BRKPT | process breakpoint =1
;  |TRAP_TRACE | process trace trap =2
;
;handleTrap:
;   	mov    eax,DWORD [esp+8]	;get siginfo_t ptr
;     	mov    eax,DWORD [eax+8]	;get si_code
;    	cmp    eax,0x2
;   	jne    ht_false			;jmp if TRAP_BRKPT
;  	mov    eax,0130			;assume this is TRAP_TRACE
;  	jmp    Raise
;
;ht_false:
;  	mov    eax,0131			;get unique error number
;    	jmp    Raise
;-----------------------------------------------------
 
;    SIGILL - illegal operation signal handler		      
;  +-----------+-------------------------+
;  |ILL_ILLOPC | illegal opcode	         =1
;  |ILL_ILLOPN | illegal operand	 =2
;  |ILL_ILLADR | illegal addressing mode =3
;  |ILL_ILLTRP | illegal trap	         =4
;  |ILL_PRVOPC | privileged opcode	 =5
;  |ILL_PRVREG | privileged register     =6
;  |ILL_COPROC | coprocessor error	 =7
;  |ILL_BADSTK | internal stack error    =8

;handleIll:
;   	mov    eax,DWORD [esp+8]	;get siginfo_t ptr
;     	mov    eax,DWORD [eax+8]	;get si_code
;        add	eax,131
;   	jmp    Raise

;---------------------------------------------------


;     SIGFPE - floating point math error		       
;  +-----------+----------------------------------+
;  |FPE_INTDIV | integer divide by zero	          =1
;  |FPE_INTOVF | integer overflow		  =2
;  |FPE_FLTDIV | floating point divide by zero    =3
;  |FPE_FLTOVF | floating point overflow	  =4
;  |FPE_FLTUND | floating point underflow	  =5
;  |FPE_FLTRES | floating point inexact result    =6
;  |FPE_FLTINV | floating point invalid operation =7
;  |FPE_FLTSUB | subscript out of range	          =8
;
; used to translate signal code to exception number
; if code not in table use 0x24 as result
;-------------
; SIGFPE signal handler entry point
;handleFPE:
;  mov	eax,[esp + 8]
;  mov    eax,DWORD [eax+8]
;  add	eax,139
;
; display a message and exit
;---- entry point --------- error# in eax ***

;Raise:
;  mov	byte [launch_flag],0		;pre load launch and wait
;  cmp	al,112				;check if we are going down
;  jne	Raise2
;  mov	byte [launch_flag],1		;lanuch and continue if die request
;Raise2:
;  mov	edi,err_str
;  mov	esi,3		;store 3 digets
;  call	dword_to_ascii
;
; setup to launch error handler
;
;  mov	byte [path_flag],4		;look for error in .a
;  mov	eax,err_name
;  call	launch_engine
;
;  jmp	abort_exit
;--------------------------------------------------------
; [section .data]
;err_name: db 'a_error '
;err_str:  db 0,0,0,0
; [section .text]
;--------------------------------------------------------
; signal handler for terminal resize (WINCH)
;
;handleWINCH:
;  mov	ecx,winch_msg
;  call	display_asciiz
;  ret

; [section .data]
;winch_msg: db "window resize occured",0ah,0
; [section .text]
;-------------------------------------------------------
; signal handler for SIGINT , usually control-c char
;
; [section .data]
;gotit_msg: db "Control-C caught",0ah,0
; [section .text]

;handleCtrlc:
;  mov	ecx,gotit_msg
;  call	display_asciiz
;  ret
