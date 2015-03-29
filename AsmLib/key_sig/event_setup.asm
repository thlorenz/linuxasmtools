  [section .text align=1]

  extern signal_install_group
  extern signal_attach
  extern abort_signal_jmp
  extern open_tty
  extern lib_buf

%include "../include/signal.inc"
  extern installed_sig_mask
;---------------------------------------------------
;>1 key_sig
; event_setup - set program events
; INPUT
;  eax = signal_mask, signals to setup.  If set to -1
;        all possible signals will be set up.  It will
;        still be necessary to call routines that attach
;        to signals, such as key_setup and signal_attach.
;  dl = keyboard flag, if set=1 then SIGIO handles keyboard
;  ebp = abort signal code ptr to handle cleanup and exit.
;        This value is stored at [abort_signal_jmp]
;        Set ebp=0 to avoid calling our program (the kernels
;        default handler will abort the program).  The abort
;        signals are listed next, plus SIGPWR.
;    abort signals (signal_flag+0)
;        00 00 00 01 bit 0 SIGFPE math error
;        00 00 00 02     1 SIGPIPE pipe error
;        00 00 00 04     2 SIGTERM user terminate request
;        00 00 00 08     3 SIGILL illegal instruction
;        00 00 00 10     4 SIGBUS illegal memory address
;        00 00 00 20     5 SIGSEGV segment (memory) fault
;        00 00 00 40     6 SIGXCPU cpu time limit expire
;        00 00 00 80     7 SIGXFSZ file size too big
;    ignore sigals (signal_flag+1)
;        00 00 01 00 bit 8  SIGQUIT keyboard quit key
;        00 00 02 00     9  SIGTSTP keyboard syspend key
;        00 00 04 00     10 SIGTTIN background process reading
;        00 00 08 00     11 SIGTTOU background process writing
;        00 00 10 00     12 SIGABORT abort key (ctrl-a?)
;    info signals (signal_flag+2)
;        00 01 00 00 bit 16 SIGCHLD child died
;        00 02 00 00     17 SIGWINCH terminal resize
;        00 04 00 00     18 SIGTRAP breakpoint/trap occured
;        00 08 00 00     19 SIGUSR1 event #1, user assigned
;        00 10 00 00     20 SIGUSR2 event #2, user assigned
;        00 20 00 00     21 SIGALRM alarm/timer event
;        00 40 00 00     22 SIGURG urgent socket event
;        00 80 00 00     23 SIGIO key available
;    other signals (signal_flag+3)
;        01 00 00 00 bit 24 SIGINT control c typed
;        02 00 00 00     25 SIGHUP termnal not available
;        04 00 00 00     26 VTALRM virtual alarm
;        08 00 00 00     27 SIGPROF profile timer
;        10 00 00 00     28 SIGPWR power fail (abort signal)
; 
; OUTPUT
;   eax = results of request
;         0 = success
;       -22 = EINVAL An invalid signal was specified.
;       -14 = EFAULT memory error
;       -4  = EINTR  System call was interrupted.
;
; NOTE
;   source file = event_setup.asm
;<
;----------------------------------------------------
  global event_setup
event_setup:
  mov	[abort_signal_jmp],ebp
  mov	[event_mask],eax
;setup signal mask
es_20:
  mov	al,dl	;get keyboard flag
  mov	edx,[event_mask]
  mov	ah,1	;force non-zero (install handler)
  call	signal_install_group
  ret  
;------------------
  [section .data]
event_mask:  dd 0

  [section .text]
