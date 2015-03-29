
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
  extern log_str,log_num,log_eol

  [section .text]
;---------------------------------------------------------
;****f* err/log_signals *
; NAME
;>1 log-error
;  log_signals - install signal logging
; INPUTS
;    eax = 1 to enable logging messages to file "log"
;        = 0 to disable logging messages to file "log"
;    ebx = optional pointer to local signal handler.  It
;          is called each time a non-fatal signal occurs.
;          Set ebx=0 if no handler is needed.
; OUTPUT
;    handler called if provided and enabled (see below)
;    global dword [signal_flag] is set to indicate signal
;    occured.  Bits are "or"ed into signal_flag each time a
;    signal occurs.  The flag can be cleared by user.  The
;    library function does not check signal_flag.
;     
;    If the caller provided handler is called the following
;    registers are set:
;      eax = signal number
;      esi = pointer to signal name string
;     
;      signal actions are as follows:
;     
;      name - number logged  handler called            signal_flag bit
;    -------  ------ ------  --------------            ---------------
;     SIGHUP     1    yes    yes                            0x00000001
;     SIGINT     2    yes    yes                            0x00000002
;     SIGQUIT    3    yes    yes                            0x00000004
;     SIGILL     4    yes    no (log_signal aborts program) -
;     SIGTRAP    5    yes    yes                            0x00000010
;     SIGABRT    6    yes    no (log_signal aborts program) 0x00000020
;     SIGIOT     6    yes    no (log_signal aborts program) 0x00000020
;     SIGBUS     7    yes    yes                            0x00000040
;     SIGFPE     8    yes    no (log_signal aborts program) 0x00000080
;     SIGKILL    9     no    no                             -
;     SIGUSR1    10   yes    yes                            0x00000200
;     SIGSEGV    11   yes    no (log_signal aborts program) 0x00000400
;     SIGUSR2    12   yes    yes                            0x00000800
;     SIGPIPE    13   yes    yes                            0x00001000
;     SIGALRM    14   yes    yes                            0x00002000
;     SIGTERM    15   yes    no (log_signal aborts program) 0x00004000
;     SIGSTKFLT  16   yes    yes                            0x00008000
;     SIGCHLD    17   yes    yes                            0x00010000
;     SIGCONT    18   yes    yes                            0x00020000
;     SIGSTOP    19    no    no                             -
;     SIGTSTP    20   yes    yes                            0x00080000
;     SIGTTIN    21   yes    yes                            0x00100000
;     SIGTTOU    22   yes    yes                            0x00200000
;     SIGURG     23   yes    yes                            0x00400000
;     SIGXCPU    24   yes    yes                            0x00800000
;     SIGXFSZ    25   yes    yes                            0x01000000
;     SIGVTALRM  26   yes    yes                            0x02000000
;     SIGPROF    27   yes    yes                            0x04000000
;     SIGWINCH   28   yes    yes                            0x08000000
;     SIGIO      29   yes    yes                            0x10000000
; NOTES
;    source file: log_signals.asm
;     
;    This function can be used for testing or as a
;    signal handler.  Function "err_signal_install"
;    is also available and allows more flexability.
;<
;  * ----------------------------------------------
;*******
  global signal_flag
  global log_signals
log_signals:
  mov	byte [log_flag],al	;save caller logging instructions
  mov	[handler],ebx		;save caller handler
  mov	esi,install_table
  mov	ebx,1			;start with signal #1
ls_loop:
  xor	eax,eax			;clear eax
  lodsb				;get table entry
  or	al,al
  jz	ls_done			;exit if done
  cmp	al,-1
  je	ls_lp_end
;  mov	byte [sig_number],bl
  add	eax,top			;compute handler address
  mov	dword [sig_handler],eax  

  mov	eax,67
  mov	ecx,sig_number
  xor	edx,edx
  int	80h

;  call	log_hex
;  mov	eax,'<rtn'
;  call	log_regtxt
;  mov	eax,ebx
;  call	log_num
;  mov	eax,'<sig'
;  call	log_regtxt
;  call	log_eol

ls_lp_end:
  inc	ebx
  jmp	short ls_loop
ls_done:
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
  mov	esi,SIGHUP_msg
  jmp	short lc	
SIGINT:  ;       2      yes     yes
  mov	esi,SIGINT_msg
  jmp	short lc
SIGQUIT: ;      3      yes     yes
  mov	esi,SIGQUIT_msg
  jmp	short lc
SIGILL:  ;       4      yes     no (log_signal aborts program)
  mov	esi,SIGILL_msg
  jmp	short la
SIGTRAP: ;      5      yes     yes
  mov	esi,SIGTRAP_msg
  jmp	short lc
SIGABRT: ;      6      yes     no (log_signal aborts program)
  mov	esi,SIGABRT_msg
  jmp	short la
SIGBUS:  ;     7      yes     yes   
  mov	esi,SIGBUS_msg
  jmp	short lc
SIGFPE:  ;    8      yes     no (log_signal aborts program)
  mov	esi,SIGFPE_msg
  jmp	short la
SIGUSR1: ;      10     yes     yes
  mov	esi,SIGUSR1_msg
  jmp	short lc
SIGSEGV: ;      11     yes     no (log_signal aborts program)
  mov	esi,SIGSEGV_msg
la:  jmp	short log_and_abort
SIGUSR2: ;      12     yes     yes
  mov	esi,SIGUSR2_msg
  jmp	short lc
SIGPIPE: ;      13     yes     yes
  mov	esi,SIGPIPE_msg
lc:  jmp	short log_and_call
SIGALRM: ;      14     yes     yes
  mov	esi,SIGALRM_msg
  jmp	short lc
SIGTERM: ;      15     yes     no (log_signal aborts program)
  mov	esi,SIGTERM_msg
  jmp	short la
SIGSTKFLT: ;    16     yes     yes
  mov	esi,SIGSTKFLT_msg
  jmp	short lc
SIGCHLD: ;      17     yes     yes
  mov	esi,SIGCHLD_msg
  jmp	short lc
SIGCONT: ;      18     yes     yes
  mov	esi,SIGCONT_msg
  jmp	short lc
SIGTSTP: ;      20     yes     yes
  mov	esi,SIGTSTP_msg
  jmp	short lc
SIGTTIN: ;      21     yes     yes
  mov	esi,SIGTTIN_msg
  jmp	short lc
SIGTTOU: ;      22     yes     yes
  mov	esi,SIGTTOU_msg
  jmp	short lc
SIGURG:  ;       23     yes     yes
  mov	esi,SIGURG_msg
  jmp	short lc
SIGXCPU: ;      24     yes     yes
  mov	esi,SIGXCPU_msg
  jmp	short lc
SIGXFSZ: ;      25     yes     yes
  mov	esi,SIGXFSZ_msg
  jmp	short lc
SIGVTALRM: ;    26     yes     yes
  mov	esi,SIGVTALRM_msg
  jmp	short lc
SIGPROF: ;      27     yes     yes
  mov	esi,SIGPROF_msg
  jmp	short lc
SIGWINCH: ;     28     yes     yes
  mov	esi,SIGWINCH_msg
  jmp	short lc
SIGIO:   ;        29     yes     yes
  mov	esi,SIGIO_msg
  jmp	short lc
;---------------------------
; input: esi = message
log_and_abort:
  call	write_log
  mov	eax,1
  mov	ebx,-1
  int	80h
;---------------------------
; input: esi=message
log_and_call:
  call	write_log
  cmp	dword [handler],0
  je	lac_exit
  call	[handler]
lac_exit:
  ret
;---------------------------
; input: esi = message to write
; output: file "log" written if enabled
;         [signal_flag] set
write_log:
  xor	eax,eax		;clear eax
  cld
  lodsb			;get flag bit
  dec	eax
  bts	dword [signal_flag],eax
  cmp	byte [log_flag],0
  je	wl_exit		;exit if logging disabled	
  inc	eax
  push	esi		;save message ptr
  push	eax		;save signal number
  mov	esi,sig1_msg
  call	log_str
  pop	eax
  call	log_num
  pop	esi		;restore signal name
  call	log_str
  call	log_eol
wl_exit:
  ret

sig1_msg: db 'Signal ',0
;---------------------------
  [section .data]

; signal install template
sig_number:
; db 4   ;signal illegal action SIGILL
sig_handler:
 dd 0   ;handleIll
 dd 0
 dd 0	;4   ;set siginfo telling kernel to pass status data to handler
 dd 0
 dd 0

handler:	dd	0	;handler provided by caller
signal_flag:	dd	0	;bit flag, see top
log_flag:	db	0	;0=no logging to file

; Term   Default action is to terminate the process.
; Ign    Default action is to ignore the signal.
; Core   Default action is to terminate the process and dump core.
; Stop   Default action is to stop the process.
;----------------------------
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
; SIGBUS	      7        Core    Bus error (bad memory access)
; SIGPOLL		       Term    Pollable event (Sys V). Synonym of SIGIO
; SIGPROF	      27       Term    Profiling timer expired
; SIGTRAP	      5	       Core    Trace/breakpoint trap
; SIGURG	      23       Ign     Urgent condition on socket (4.2 BSD)
; SIGVTALRM           26       Term    Virtual alarm clock (4.2 BSD)
; SIGXCPU	      24       Core    CPU time limit exceeded (4.2 BSD)
; SIGXFSZ	      25       Core    File size limit exceeded (4.2 BSD)
; --------------------------------------------------------------------
; SIGIOT	      6	       Core    IOT trap. A synonym for SIGABRT
; SIGSTKFLT          16       Term    Stack fault on coprocessor (unused)
; SIGIO	             29       Term    I/O now possible (4.2 BSD)
; SIGPWR	      30       Term    Power failure (System V)
; SIGINFO	       -  	       A synonym for SIGPWR
; SIGLOST	      -        Term    File lock lost
; SIGWINCH	      28       Ign     Window resize signal (4.3 BSD, Sun)
; SIGUNUSED           31       Term    Unused signal (will be SIGSYS)

SIGHUP_msg: db	1,'SIGHUP',0
SIGINT_msg: db 2,'SIGINT',0 
SIGQUIT_msg: db 3,'SIGQUIT',0 
SIGILL_msg: db 4,'SIGILL',0 
SIGTRAP_msg: db 5,'SIGTRAP',0 
SIGABRT_msg: db 6,'SIGABRT',0 
SIGBUS_msg: db 7,'SIGBUS',0 ;
SIGFPE_msg: db 8,'SIGFPE',0 ;
SIGUSR1_msg: db 10,'SIGUSR1',0 
SIGSEGV_msg: db 11,'SIGSEGV',0 
SIGUSR2_msg: db 12,'SIGUSR2',0 
SIGPIPE_msg: db 13,'SIGPIPE',0 
SIGALRM_msg: db 14,'SIGALRM',0 
SIGTERM_msg: db 15,'SIGTERM',0 
SIGSTKFLT_msg: db 16,'SIGSTKFLT',0 
SIGCHLD_msg: db 17,'SIGCHLD',0 
SIGCONT_msg: db 18,'SIGCONT',0 
SIGTSTP_msg: db 20,'SIGTSTP',0 
SIGTTIN_msg: db 21,'SIGTTIN',0 
SIGTTOU_msg: db 22,'SIGTTOU',0 
SIGURG_msg: db 23,'SIGURG',0 ;;
SIGXCPU_msg: db 24,'SIGXCPU',0 
SIGXFSZ_msg: db 25,'SIGXFSZ',0 
SIGVTALRM_msg: db 26,'SIGVTALRM',0 
SIGPROF_msg: db 27,'SIGPROF',0 
SIGWINCH_msg: db 28,'SIGWINCH',0 
SIGIO_msg: db 29,'SIGIO',0 ; 

