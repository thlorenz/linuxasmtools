; include file signal.inc

;linux signal definitons from /usr/include/.. signal.h

SIGHUP	equ	 1
SIGINT	equ	 2
SIGQUIT	equ	 3
SIGILL	equ	 4
SIGTRAP	equ	 5
SIGABRT	equ	 6
SIGIOT	equ	 6
SIGBUS	equ	 7
SIGFPE	equ	 8
SIGKILL	equ	 9
SIGUSR1	equ	10
SIGSEGV	equ	11
SIGUSR2	equ	12
SIGPIPE	equ	13
SIGALRM	equ	14
SIGTERM	equ	15
SIGSTKFLT	equ 16
SIGCHLD	equ	17
SIGCONT	equ	18
SIGSTOP	equ	19
SIGTSTP	equ	20
SIGTTIN	equ	21
SIGTTOU	equ	22
SIGURG	equ	23
SIGXCPU	equ	24
SIGXFSZ	equ	25
SIGVTALRM	equ 26
SIGPROF	equ	27
SIGWINCH	equ 28
SIGIO	equ	29
SIGPOLL	equ	SIGIO
SIGPWR	equ	30
SIGSYS	equ	31

;*
;* SA_FLAGS values:
;*
;* SA_ONSTACK indicates that a registered stack_t will be used.
;* SA_RESTART flag to get restarting signals (which were the default long ago)
;* SA_NOCLDSTOP flag to turn off SIGCHLD when children stop.
;* SA_RESETHAND clears the handler when the signal is delivered.
;* SA_NOCLDWAIT flag on SIGCHLD to inhibit zombies.
;* SA_NODEFER prevents the current signal from being masked in the handler.
;*
;* SA_ONESHOT and SA_NOMASK are the historical Linux names for the Single
;* Unix names RESETHAND and NODEFER respectively.
;*/
SA_NOCLDSTOP	equ 0x00000001
SA_NOCLDWAIT	equ 0x00000002
SA_SIGINFO	equ 0x00000004
SA_ONSTACK	equ 0x08000000
SA_RESTART	equ 0x10000000
SA_NODEFER	equ 0x40000000
SA_RESETHAND	equ 0x80000000
SA_NOMASK	equ SA_NODEFER
SA_ONESHOT	equ SA_RESETHAND
SA_RESTORER	equ 0x04000000


SIG_BLOCK    equ      0	; for blocking signals */
SIG_UNBLOCK  equ      1	; for unblocking signals */
SIG_SETMASK  equ      2	; for setting the signal mask */


SIG_DFL	equ 0 ; default signal handling */
SIG_IGN	equ 1 ; ignore signal */
SIG_ERR	equ -1 ; error return from signal */

;mask bits used by variable signal_flag, and function signal_install_group
;   The bit flags are ordered by priority and function groups to
;   make decoding easier.
;   Signal handlers set these flags in "signal_flag"  The signal_install_group
;   function uses same bit flags as input.
;   global dword variable "signal_flag" is organized as follows:
;
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

_HUP	equ	 02000000h	;signal 1
_INT	equ	 01000000h	;signal 2
_QUIT	equ	 00000100h	;signal 3
_ILL	equ	 00000008h	;signal 4
_TRAP	equ	 00040000h	;signal 5
_ABRT	equ	 00001000h	;signal 6
_BUS	equ	 00000010h	;signal 7
_FPE	equ	 00000001h	;signal 8 math error
_KILL	equ	 00000000h      ;signal 9 ** can not be caught
_USR1	equ	 00080000h	;signal 10
_SEGV	equ	 00000020h	;signal 11
_USR2	equ	 00100000h	;signal 12
_PIPE	equ	 00000002h	;signal 13
_ALRM	equ	 00200000h	;signal 14
_TERM	equ	 00000004h	;signal 15
_STKFLT	equ      00000000h	;signal 16 ** stack fault (unused)
_CHLD	equ	 00010000h	;signal 17
_CONT	equ	 00000000h	;signal 18 ** continue (avoid using)
_STOP	equ	 00000000h	;signal 19 ** can not be caught
_TSTP	equ	 00000200h      ;signal 20
_TTIN	equ	 00000400h	;signal 21
_TTOU	equ	 00000800h	;signal 22
_URG	equ	 00400000h	;signal 23
_XCPU	equ	 00000040h	;signal 24
_XFSZ	equ	 00000080h	;signal 25
_VTALRM	equ      04000000h	;signal 26
_PROF	equ	 08000000h	;signal 27
_WINCH	equ      00020000h	;signal 28
_IO	equ	 00800000h	;signal 29
_PWR	equ	 10000000h	;signal 30
_SYS	equ	 00000000h	;signal 31 ** unused

;The following mask collects all signals that can abort
;a program but can be caught.  They are useful for saving
;data before the program exits.  After these signals are
;caught the handler should do "exit" function.
;
_ABORT	equ _FPE|_PIPE|_TERM|_ILL|_BUS|_SEGV|_XCPU|_XFSZ|_QUIT|_ABRT|_HUP|_INT|_PWR
