  [section .text align=1]

;---------------------------------------------------
;#1 key_sig
; sigaction - set action for signal
; INPUT
;  ebx = signal number, SIGKILL & SIGSTOP can not be used
;  ecx = one of the following:
;        sa_handler    pointer to handler
;        SIG_DFL(0) - restore default action for this signal
;        SIG_IGN(1) - ignore this signal
;
; OUTPUT
;   eax = results of request
;         0 = success
;       -22 = EINVAL An invalid signal was specified.
;       -14 = EFAULT memory error
;       -4  = EINTR  System call was interrupted.
;
; NOTE
;   source file = sigaction.asm
;
;   All signals that have a handler, disable signals
;   which the handler executes.
;   IF a kernel call is interrupted, the fuction will
;   return a continuation error of -4.  The main program
;   can communicate with its signal handler to find out
;   what signal occured.  
;#
;----------------------------------------------------
  global sigaction
sigaction:
  mov	[sa_handler],ecx
  mov	ecx,sa_handler
  mov	eax,67		;sigaction
  xor	edx,edx		;on save of previous state
  int	byte 80h
;  ebx = signal number, SIGKILL & SIGSTOP can not be used
;  ecx = ptr to sa_structure, or zero to query handler
;        sa_handler  dd ?  <- can be pointer to handler or SIG_DFL(0) or SIG_IGN(1)
;        sa_mask     dd ?  <- signals to block while handler executes
;        sa_flags    dd ?  <- see flags
;        sa_restoref dd ?  (unused)
;
;        The sa_handler field can be either a handler or flag as follows:
;        SIG_DFL(0) - restore default action for this signal
;        SIG_IGN(1) - ignore this signal
;
;        sa_mask gives a mask of signals which should be blocked  during  execu-
;        tion  of  the  signal handler.  In addition, the signal which triggered
;        the handler will be blocked, unless the SA_NODEFER or  SA_NOMASK  flags
;        are used.
;
;        sa_flags  specifies  a  set  of flags which modify the behaviour of the
;        signal handling process. It is formed by the bitwise OR of zero or more
;        of the following:
;
;        SA_NOCLDSTOP 0x00000001
;                     If  signum  is  SIGCHLD, do not receive notification when
;                     child processes stop (i.e., when child processes  receive
;                     one of SIGSTOP, SIGTSTP, SIGTTIN or SIGTTOU).
;
;        SA_ONESHOT or SA_RESETHAND 0x80000000
;                     Restore  the  signal action to the default state once the
;                     signal handler has been called.
;
;        SA_ONSTACK 0x08000000
;                     Call the signal handler on an alternate signal stack pro-
;                     vided  by  sigaltstack(2).   If an alternate stack is not
;                     available, the default stack will be used.
;
;        SA_RESTART 0x10000000
;                     Provide behaviour compatible with BSD signal semantics by
;                     making certain system calls restartable across signals. 
;                     Otherwise, a interrupted kernel read call will return -4
;
;        SA_NOMASK or SA_NODEFER 0x40000000
;                     Do not prevent the signal from being received from within
;                     its own signal handler.
;
;        SA_SIGINFO 0x00000004
;                     The signal handler takes 3 arguments, not one.   In  this
;                     case,  sa_sigaction  should be set instead of sa_handler.
;                     (The sa_sigaction field was added in Linux 2.1.86.)
;
;  edx = optional pointer to save area for old setting
  ret

;------------------
  [section .data]
;If we set SA_RESTART then, interrupted system calls
;do not fail and return -4 (interrupted call error).
sa_handler  dd 0	;handler or SIG_DFL(0) or SIG_IGN(1)
sa_mask     dd -1 	;signals to block while handler executes
sa_flags    dd  0x10000004 ; SA_RESTART,;SA_SIGINFO=4
sa_restoref dd 0  	;(unused)

  [section .text]
