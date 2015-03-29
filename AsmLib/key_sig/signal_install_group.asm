  [section .text align=1]
%include "../include/signal.inc"
  extern sigaction
  extern sys_exit
  extern key_ready
;---------------------------------------------------
;#1 key_sig
; signal_install_group - set action for signal list
; INPUT
;  al  = 0 - if sigio is installed, do not use keyboard handler
;        1 - if sigio is installed, use keyboard handler
;  ah  = 1(install signal) 0(restore default)
;  edx = signal mask (see signal.inc)
;  [abort_signal_jmp] - global variable that can be
;        set to program entry if abort signal occurs.
;        This allows program to save status before
;        death.  If abort_signal_jmp is not set, the
;        program will die.
;        When [abort_signal_jmp] is taken, the esp
;        will have signal stack.  At [esp+4] is
;        signal# of problem. [esp+40] has program
;        address that failed.  
; OUTPUT
;   al = results of request, jns=success js=error
;         0 = success
;       -22 = EINVAL An invalid signal was specified.
;       -14 = EFAULT memory error
;       -4  = EINTR  System call was interrupted.
;   [installed_signal_mask] = bit mask indicating which signals
;       are trapped.
;   individual handlers report as follows
;     SIGCHLD sets ->  global sigchld_pid (pid that died)
;     SIGURG  sets ->  global sigurg_fd (fd causing signal)
;                      global sigurg_status (1=data ready  2=io possible
;     SIGIO   sets ->  global sigio_fd (keyboard fd)
;                      global sigio_status (1=data ready 
;                      program must clear this if handshaking used
;
; NOTE
;   source file = signal_install_group.asm
;
;
;#
;----------------------------------------------------
  global signal_install_group
signal_install_group:
  cmp	al,1
  jne	sig_10
  mov	[sigio_mod],dword sigio_key_handler
sig_10:
  or	[installed_sig_mask],edx	;save mask
  mov	esi,signal_table
sig_loop:
  lodsb				;get signal#
  or	al,al
  jz	sig_done		;jmp if end of table
  movzx ebx,al
  xor	ecx,ecx			;preload SIG_DFL
  cmp	ah,0			;is this restore default mode
  je	sig_skip		;jmp if SIG_DFL mode
  mov	ecx,[esi]		;get handler
sig_skip:
  add	esi,4			;advance to next entry
  ror	edx,1			;advance mask bits
  jnc	sig_loop		;jmp if no action here
;  ebx = signal number, SIGKILL & SIGSTOP can not be used
;  ecx = one of the following:
;        sa_handler    pointer to handler
;        SIG_DFL(0) - restore default action for this signal
;        SIG_IGN(1) - ignore this signal
  or	al,al
  js	sig_loop		;illegal signal
  push	esi
  push	edx
  push	eax
  call	sigaction
  or	eax,eax
  pop	eax
  pop	edx
  pop	esi
  jns	sig_loop	;jmp if no error
sig_done:
  ret

;-------------------------------------------------
; signal handlers are provided information on the stack.
; Each signal may have different stack data, but the general
; form follows:
;
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
; si_pid;      /* Sending process ID */
; si_uid;      /* Real user ID of sending process */
; si_status;   /* Exit value or signal */
; si_utime;    /* User time consumed */
; si_stime;    /* System time consumed */
; si_value;    /* Signal value */
; si_int;      /* POSIX.1b signal */
;*si_ptr;      /* POSIX.1b signal */
;*si_addr;     /* Memory location which caused fault */
; si_band;     /* Band event */
; si_fd;       /* File descriptor */
;
; the si_code field may be unique for each signal, but
; all signals have the following common settings:
;           SI_USER        kill(2) or raise(3)
;           SI_KERNEL      Sent by the kernel.
;           SI_QUEUE       sigqueue(2)
;           SI_TIMER       POSIX timer expired
;           SI_MESGQ       POSIX  message  queue  state  changed  (since  Linux
;                          2.6.6); see mq_notify(3)
;           SI_ASYNCIO     AIO completed
;           SI_SIGIO       queued SIGIO
;           SI_TKILL       tkill(2) or tgkill(2) (since Linux 2.4.19)
;
;---------------------------------------------------
;    abort signals
;        00 00 00 01 bit 0 SIGFPE math error
;        00 00 00 02     1 SIGPIPE pipe error
;        00 00 00 04     2 SIGTERM user terminate request
;        00 00 00 08     3 SIGILL illegal instruction
;        00 00 00 10     4 SIGBUS illegal memory address
;        00 00 00 20     5 SIGSEGV segment (memory) fault
;        00 00 00 40     6 SIGXCPU cpu time limit expire
;        00 00 00 80     7 SIGXFSZ file size too big

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
; _addr;	/* faulting insn/memory ref. */
;
; si_code can contain:
;           FPE_INTDIV     integer divide by zero
;           FPE_INTOVF     integer overflow
;           FPE_FLTDIV     floating point divide by zero
;           FPE_FLTOVF     floating point overflow
;           FPE_FLTUND     floating point underflow
;           FPE_FLTRES     floating point inexact result
;           FPE_FLTINV     floating point invalid operation
;           FPE_FLTSUB     subscript out of range
sigfpe_handler:
  or	[signal_hit_mask],byte 1
;we are in a endless loop at this point, the
;instruction with error, keeps executing.
;To get out of loop we install default handler.
  jmp	goto_end


;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigpipe_handler:
  or	[signal_hit_mask],byte 2
  jmp	goto_end

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigterm_handler:
  or	[signal_hit_mask],byte 4
  jmp	goto_end

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
;	_addr;	/* faulting insn/memory ref. */
;
; si_code can contain:
;           ILL_ILLOPC     illegal opcode
;           ILL_ILLOPN     illegal operand
;           ILL_ILLADR     illegal addressing mode
;           ILL_ILLTRP     illegal trap
;           ILL_PRVOPC     privileged opcode
;           ILL_PRVREG     privileged register
;           ILL_COPROC     coprocessor error
;           ILL_BADSTK     internal stack error
sigill_handler:
  or	[signal_hit_mask],byte 8
  jmp	goto_end

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
; _addr;	/* faulting insn/memory ref. */
;
; si_code values
;
;           BUS_ADRALN     invalid address alignment
;           BUS_ADRERR     nonexistent physical address
;           BUS_OBJERR     object-specific hardware error
sigbus_handler:
  or	[signal_hit_mask],byte 10h
  jmp	goto_end

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
; _addr;	/* faulting insn/memory ref. */
;
; si_code can contain:
;           SEGV_MAPERR    address not mapped to object
;           SEGV_ACCERR    invalid permissions for mapped object
sigsegv_handler:
  or	[signal_hit_mask],byte 20h
  jmp	goto_end

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigxcpu_handler:
  or	[signal_hit_mask],byte 40h
  jmp	goto_end

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigxfsz_handler:
  or	[signal_hit_mask],byte 80h
goto_end:
  mov	eax,[abort_signal_jmp]
  or	eax,eax
  jz	die
  jmp	eax  
die:
  jmp	sys_exit
;                        3 
;    ignore sigals
;        00 00 01 00 bit 8  SIGQUIT keyboard quit key
;        00 00 02 00     9  SIGTSTP keyboard syspend key
;        00 00 04 00     10 SIGTTIN background process reading
;        00 00 08 00     11 SIGTTOU background process writing
;        00 00 10 00     12 SIGABRT abort key (ctrl-a?)


;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigquit_handler:
  or	[signal_hit_mask+1],byte 1
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigtstp_handler:
  or	[signal_hit_mask+1],byte 2
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigttin_handler:
  or	[signal_hit_mask+1],byte 4
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigttou_handler:
  or	[signal_hit_mask+1],byte 8
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigabrt_handler:
  or	[signal_hit_mask+1],byte 10h
  ret
;    
;    info signals
;        00 01 00 00 bit 16 SIGCHLD child died
;        00 02 00 00     17 SIGWINCH terminal resize
;        00 04 00 00     18 SIGTRAP breakpoint/trap occured
;        00 08 00 00     19 SIGUSR1 event #1, user assigned
;        00 10 00 00     20 SIGUSR2 event #2, user assigned
;        00 20 00 00     21 SIGALRM alarm/timer event
;        00 40 00 00     22 SIGURG urgent socket event
;        00 80 00 00     23 SIGIO key available

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
;	_pid;	/* which child */
;	_uid;	/* sender's uid */
;	_status;		/* exit code */
;	_utime;
;	_stime;
;
; si_code values
;           CLD_EXITED     child has exited
;           CLD_KILLED     child was killed
;           CLD_DUMPED     child terminated abnormally
;           CLD_TRAPPED    traced child has trapped
;           CLD_STOPPED    child has stopped
;           CLD_CONTINUED  stopped child has continued (since Linux 2.6.9)
sigchld_handler:
  mov	eax,[esp+28]	;get pid that died
  mov	[sigchld_pid],eax
  or	[signal_hit_mask+2],byte 1
  ret
;---------
  [section .data]
  global sigchld_pid
sigchld_pid: dd 0
  [section .text]
;---------

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigwinch_handler:
  or	[signal_hit_mask+2],byte 2
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
;
; si_code values
;           TRAP_BRKPT     process breakpoint
;           TRAP_TRACE     process trace trap
sigtrap_handler:
  or	[signal_hit_mask+2],byte 4
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigusr1_handler:
  or	[signal_hit_mask+2],byte 8
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigusr2_handler:
  or	[signal_hit_mask+2],byte 10h
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
;	_tid;	/* timer id */
;	_overrun;		/* overrun count */
;	_sigval;	/* same as below */
;	_sys_private;	/* not to be passed to user */
;	_overrun_incr;	/* amount to add to overrun */
sigalrm_handler:
  or	[signal_hit_mask+2],byte 20h
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigurg_handler:
  mov	eax,[esp+32]	;get fd
  mov	[sigurg_fd],eax
  mov	eax,[esp+24]	;get status flag
  mov	[sigurg_status],eax
  or	[signal_hit_mask+2],byte 40h
  ret
;---------
  [section .data]
  global sigurg_fd
sigurg_fd: dd 0
  global sigurg_status
sigurg_status: dd 0	;1=io 2=io possible
  [section .text]
;---------

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
; is _band put in si_code????
; _band;	/* POLL_IN, POLL_OUT, POLL_MSG */
; _fd;
;           POLL_IN        data input available;
;           POLL_OUT       output buffers available
;           POLL_MSG       input message available
;           POLL_ERR       i/o error
;           POLL_PRI       high priority input available
;           POLL_HUP       device disconnected
sigio_handler:
  or	[signal_hit_mask+2],byte 80h
  mov	eax,[esp+32]	;get fd
  mov	[sigio_fd],eax
  mov	eax,[esp+18h]	;get status
  mov	[sigio_status],eax
  ret

sigio_key_handler:
  or	[signal_hit_mask+2],byte 80h
  mov	eax,[esp+32]	;get fd
  mov	[sigio_fd],eax
  cmp	[esp+18h],byte 2	;is this are write possible
  je	sh_exit
  call	key_ready
  js	sh_exit			;exit if no key avail
sh_got_data:
  mov	[sigio_status],byte 1	;set got data
sh_exit:
  ret

;---------
  [section .data]
  global sigio_fd
sigio_fd: dd 0
  global sigio_status
sigio_status: dd 0	;1=io 2=io possible or mouse releas
  [section .text]
;---------
;    other signals
;        01 00 00 00 bit 24 SIGINT control c typed
;        02 00 00 00     25 SIGHUP termnal not available
;        04 00 00 00     26 VTALRM virtual alarm
;        08 00 00 00     27 SIGPROF profile timer
;        10 00 00 00     28 SIGPWR power fail (abort signal)


;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigint_handler:
  or	[signal_hit_mask+3],byte 1
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sighup_handler:
  or	[signal_hit_mask+3],byte 2
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigvtalrm_handler:
  or	[signal_hit_mask+3],byte 4
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigprof_handler:
  or	[signal_hit_mask+3],byte 8
  ret

;-----------------------------------
; esp (stack) on entry =
; (return address)
; si_signo;    /* Signal number */
; si_errno;    /* An errno value */
; si_code;     /* Signal code */
sigpwr_handler:
  or	[signal_hit_mask+3],byte 10h
  jmp	goto_end			;abort signal
;------------------
  [section .data]

;the following table is used to translate a mask
;bit to signal information
signal_table:
;    abort signals (signal_hit_mask+0)
;        00 00 00 01 bit 0 SIGFPE math error
  db SIGFPE
  dd sigfpe_handler
;        00 00 00 02     1 SIGPIPE pipe error
  db SIGPIPE
  dd sigpipe_handler
;        00 00 00 04     2 SIGTERM user terminate request
  db SIGTERM
  dd sigterm_handler
;        00 00 00 08     3 SIGILL illegal instruction
  db SIGILL
  dd sigill_handler
;        00 00 00 10     4 SIGBUS illegal memory address
  db SIGBUS
  dd sigbus_handler
;        00 00 00 20     5 SIGSEGV segment (memory) fault
  db SIGSEGV
  dd sigsegv_handler
;        00 00 00 40     6 SIGXCPU cpu time limit expire
  db SIGXCPU
  dd sigxcpu_handler
;        00 00 00 80     7 SIGXFSZ file size too big
  db SIGXFSZ
  dd sigxfsz_handler
;    ignore sigals (signal_hit_mask+1)
;        00 00 01 00 bit 8  SIGQUIT keyboard quit key
  db SIGQUIT
  dd sigquit_handler
;        00 00 02 00     9  SIGTSTP keyboard syspend key
  db SIGTSTP
  dd sigtstp_handler
;        00 00 04 00     10 SIGTTIN background process reading
  db SIGTTIN
  dd sigttin_handler
;        00 00 08 00     11 SIGTTOU background process writing
  db SIGTTOU
  dd sigttou_handler
;        00 00 10 00     12 SIGABORT abort key (ctrl-a?)
  db SIGABRT
  dd sigabrt_handler
;dummy signal
  db -1			;13
  dd 0
;dummy signal
  db -1			;14
  dd 0
;dummy signal
  db -1			;15
  dd 0
;    info signals (signal_hit_mask+2)
;        00 01 00 00 bit 16 SIGCHLD child died
  db SIGCHLD
  dd sigchld_handler
;        00 02 00 00     17 SIGWINCH terminal resize
  db SIGWINCH
  dd sigwinch_handler
;        00 04 00 00     18 SIGTRAP breakpoint/trap occured
  db SIGTRAP
  dd sigtrap_handler
;        00 08 00 00     19 SIGUSR1 event #1, user assigned
  db SIGUSR1
  dd sigusr1_handler
;        00 10 00 00     20 SIGUSR2 event #2, user assigned
  db SIGUSR2
  dd sigusr2_handler
;        00 20 00 00     21 SIGALRM alarm/timer event
  db SIGALRM
  dd sigalrm_handler
;        00 40 00 00     22 SIGURG urgent socket event
  db SIGURG
  dd sigurg_handler
;        00 80 00 00     23 SIGIO key available
  db SIGIO
sigio_mod:
  dd sigio_handler
;    other signals (signal_hit_mask+3)
;        01 00 00 00 bit 24 SIGINT control c typed
  db SIGINT
  dd sigint_handler
;        02 00 00 00     25 SIGHUP termnal not available
  db SIGHUP
  dd sighup_handler
;        04 00 00 00     26 VTALRM virtual alarm
  db SIGVTALRM
  dd sigvtalrm_handler
;        08 00 00 00     27 SIGPROF profile timer
  db SIGPROF
  dd sigprof_handler
;        10 00 00 00     28 SIGPWR power fail (abort signal)
  db SIGPWR
  dd sigpwr_handler
;
  db 0		;end of table

  global signal_hit_mask,installed_sig_mask
installed_sig_mask	dd 0
signal_hit_mask: dd 0
  global abort_signal_jmp
abort_signal_jmp	dd 0
  [section .text]
