  extern stdout_str
  extern signal_install
  extern byte_to_ascii
  extern sys_exit
  extern hex_dump_stdout
  extern get_our_process_id
  extern signal_send
  extern delay
  extern read_stdin,kbuf
  extern is_number
  extern ascii_to_dword
  extern byteto_hexascii
  extern dwordto_hexascii

; This is a demo and documentation program for signals on Linux.
; It includes parts of "man" pages and other documents.
; The program does the following:
;  1. installs all catchable signals
;  2. displays a message and waits for emtry of signal#
;  3. send signal entered
;  4. report results
;      * the ctrl-c key will cause a signal and special message
;      * the q <enter>    key will fall into a divide by  zero error
;                         and terminate
;      * any other "key <enter>" will be displayed and continue
;        waiting for keys
;
; program was compiled using nasm as follows:
;	nasm -g -felf -o asmlib_signal_demo.o asmlib_signal_demo.asm
;	ld -e main -o asmlib_signal_demo asmlib_signal_demo.o

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
  global  _start
_start:
  call	get_our_process_id
  mov	[our_pid],eax		;save our id for signal_send
;capture all signals
  mov	ecx,install_msg
  call	stdout_str	;display startup message

  mov	ebx,1	;starting signal#
  mov	[signal#],ebx

install_loop:
  mov	ebx,[signal#]
  mov	ecx,signal_block
  cmp	ebx,31
  je	install_done

  call	signal_install
  or	eax,eax
  js	install_tail
;display installed signal
  mov	al,[signal#]
  mov	edi,signal_ascii
  call	byte_to_ascii
  mov	al,' '
  stosb
  mov	al,0
  stosb
  mov	ecx,signal_ascii
  call	stdout_str
install_tail:
  inc	dword [signal#]	;move to next signal
  jmp	install_loop
install_done:
  mov	ecx,eol
  call	stdout_str

get_signal:
;get signal#
  mov	ecx,request_msg
  call	stdout_str
  mov	[sig_ascii_ptr],dword sig_ascii
next_input:
  call	read_stdin
  mov	al,[kbuf]
  cmp	al,0dh		;eol
  je	send_signal
  cmp	al,0ah
  je	send_signal
  call	is_number
  jne	get_signal
  mov	edi,[sig_ascii_ptr]
  stosb
  mov	[sig_ascii_ptr],edi
  mov	[last_char],al
  mov	ecx,last_char
  call	stdout_str	;echo last char
  jmp	next_input
  
;send signal
send_signal:
  mov	edi,[sig_ascii_ptr]
  mov	[edi],byte 0	;terminate signal
  mov	esi,sig_ascii
  call	ascii_to_dword
  mov	[signal#],ecx	;save signal#
  jecxz	get_signal

  mov	ebx,[our_pid]
  mov	ecx,[signal#]		;signal to send
  call	signal_send
;wait for signal confirm
  mov	eax,-1
  call	delay

  cmp	[trapped_signal],dword 0
  je	no_signal
;
  mov	ecx,main_continue_msg
  call	stdout_str
  jmp	now_what
no_signal:
  mov	ecx,main_no_msg
  call	stdout_str
now_what:
  mov	ecx,now_what_msg
  call	stdout_str
  call	read_stdin
  cmp	[kbuf],byte 'y'
  je	get_signal
  jmp	short exit2
;


exit2:	call	sys_exit
;--------------------------------------
 [section .data]
our_pid		dd 0	;our process id
signal#		dd 0	;signal active
table_ptr	dd 0	;ptr to signal_table
install_msg	db 0ah,0ah,'The following signals installed OK',0ah,0
signal_ascii:	db 0,0,0,0,0
eol:		db 0ah,0

last_char:	db 0,0

main_continue_msg: db 0ah,'program continuing after signal trap',0
main_no_msg:       db 0ah,'program continuing, no trap detected',0
now_what_msg:      db 0ah,'continue (y/n)',0

request_msg:
 db 0ah
 db 'menu of signals to send',0ah
 db '--------------------------------------------------------------',0ah
 db ' 1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL',0ah
 db ' 5) SIGTRAP      6) SIGIOT       7) SIGBUS       8) SIGFPE',0ah
 db ' 9) SIGKILL     10) SIGUSR1     11) SIGSEGV     12) SIGUSR2',0ah
 db '13) SIGPIPE     14) SIGALRM     15) SIGTERM     17) SIGCHLD',0ah
 db '18) SIGCONT     19) SIGSTOP     20) SIGTSTP     21) SIGTTIN',0ah
 db '22) SIGTTOU     23) SIGURG      24) SIGXCPU     25) SIGXFSZ',0ah
 db '26) SIGVTALRM   27) SIGPROF     28) SIGWINCH    29) SIGIO',0ah
 db '30) SIGPWR',0ah
 db '--------------------------------------------------------------',0ah
 db 'enter signal# ->',0

sig_ascii_ptr	dd	sig_ascii
sig_ascii:	times 10 db 0

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
;        I'll explain why this is a good idea later, when I discuss how to
;        write a good signal handler. The sa_mask field has no effect on
;        this behavior, but the sa_flags field does let a program override
;        this.
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
;               SA_SIGINFO    0X0000 0004
;               SA_ONESTACK   0x0800 0000
;               SA_RESTART    0X1000 0000
;               SA_NODEFER    0X4000 0000   alias SA_NODEFER
;               SA_RESETHAND  0X8000 0000   alias SA_ONESHOT
;               SA_RESTORER   0X0400 0000
;              
; The fifth field in each signal_table entry is SA_RESTORER. This field is not used

signal_block:
 dd signal_handler	;handler
 dd 0			;mask of signals to ignore while processing
 dd 4			;flags
 dd 0			;unused

;--------------------------------------
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
; Signal	  Value	    Action   Comment
; -------------------------------------------------------------------------
; SIGHUP	     1	     Term    Hangup detected on controlling terminal
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
; SIGBUS	      7        Core    Bus error (bad memory access)
; SIGPOLL		       Term    Pollable event (Sys V). Synonym of SIGIO
; SIGPROF	      27       Term    Profiling timer expired
; SIGTRAP	      5	       Core    Trace/breakpoint trap
; SIGURG	      23       Ign     Urgent condition on socket (4.2 BSD)
; SIGVTALRM           26       Term    Virtual alarm clock (4.2 BSD)
; SIGXCPU	      24       Core    CPU time limit exceeded (4.2 BSD)
; SIGXFSZ	      25       Core    File size limit exceeded (4.2 BSD)
; SIGIOT	      6	       Core    IOT trap. A synonym for SIGABRT
; SIGSTKFLT          16       Term    Stack fault on coprocessor (unused)
; SIGIO	             29       Term    I/O now possible (4.2 BSD)
; SIGPWR	      30       Term    Power failure (System V)
; SIGINFO	       -  	       A synonym for SIGPWR
; SIGLOST	      -        Term    File lock lost
; SIGWINCH	      28       Ign     Window resize signal (4.3 BSD, Sun)
; SIGUNUSED           31       Term    Unused signal (will be SIGSYS)
;
;------------------------------------------------------

; The second field is a a pointer to our local handler
;------------------------------------------------------

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

;  	      SIGSEGV - segment error			     
;  +------------+---------------------------------------+
;  |SEGV_MAPERR | address not mapped to object	        =1
;  |SEGV_ACCERR | invalid permissions for mapped object =2
;
signal_handler:
  mov	ecx,sig_trap
  call	stdout_str
  mov	esi,esp
  mov	eax,[esi+4]	;get signal#
  mov	[trapped_signal],eax

  mov	edi,sig_sig#
  call	byteto_hexascii
  mov	eax,[trapped_signal]
  mov	edi,sig_sig#2
  call	byteto_hexascii

  mov	esi,[esi+8]	;get ptr to siginfo
  lodsd			;get signal#
  lodsd			;get error no
  mov	edi,sig_err
  call	dwordto_hexascii

  lodsd			;get code
  mov	edi,sig_code
  call	dwordto_hexascii

  lodsd			;get pid
  mov	edi,sig_pid
  call	dwordto_hexascii

  mov	ecx,sig_msg1
  call	stdout_str
  ret
  
  [section .data]
sig_trap: db 0ah,'--- signal trap - all reported data in hex ---',0ah,0
trapped_signal	dd 0
sig_msg1: db 'stack(1)=return address',0ah
          db 'stack(2)=signal# - '
sig_sig#  db '    ',0ah
          db 'stack(3)=siginfo ptr -> signo-'
sig_sig#2 db '    errno-'
sig_err   db '         code-'
sig_code  db '         pid-'
sig_pid   db '        ',0ah
          db 'stack(4)=ucontext ptr -> ',0ah,0


 