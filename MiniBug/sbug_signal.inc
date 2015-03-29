report_signal:
  mov	edi,msg_build+1		;past flag
  mov	[append_msg_ptr],edi	;enable msg display
  mov	esi,pre_msg
  call	str_move
;we have stopped due to signal (ah=signal number)
;put signal into buffer
  movzx esi,byte [app_status+1]
  shl	esi,3
  add	esi,SIGHUP_msg - 8
  movsd		;move signal
  movsd		;name

  movzx ebx,byte [app_status+1]
  shl	ebx,2			;make dword
  add	ebx,signal_handlers -4
  call	[ebx]	;------------>  call signal processing
  ret

;When a signal occurs the app is stopped and we can harvest status
;If we stopped inside the kernel app-eax- has a special code
;It is possible to continue from signals inside the kernel by
;  modifying the app eax register.
;  Setting eax=0 may exit kernel with status=0, If
;  we leave eax unchanged the kernel may continue (if not fatal
;  signal type).
;  if inside the kernel, r1_old_eax has function entry eax (function#)
;
; stop inside kernel - r1_eax negative -clear r1-eax to exit kernel
; stop inside program  r1-eax positive
;
  [section .data]

signal_handlers:
 dd sighup	;1
 dd sigint	;2
 dd sigquit	;3
 dd sigill	;4 illegal instructon
 dd sigtrap	;5 breakpoint
 dd sigabrt	;6 
 dd sigbus	;7
 dd sigfpe	;8
 dd sigkill	;9
 dd sigusr1	;10
 dd sigsegv	;11 memory error
 dd sigusr2	;12
 dd sigpipe	;13
 dd sigalrm	;14
 dd sigterm	;15
 dd sigstkflt	;16
 dd sigchld	;17 child exited
 dd sigcont	;18
 dd sigstop	;19 stop request signal
 dd sigtstp	;20
 dd sigttin	;21
 dd sigttou	;22
 dd sigurg
 dd sigxcpu
 dd sigxfsz
 dd sigvtalr
 dd sigprof
 dd sigwinch	;28 terminal resize
 dd sigio
 dd unknown
 dd unknown
 dd unknown
 dd unknown

  [section .text]

;expected signals -------------------------------------------
sigtrap:	;5 breakpoint
;  dec	dword [app_eip]		;fix eip for breakpoint stop

sigstop:	;19 stop request signal
  or	[app_mode],byte 10h	;force window update
  ret


;abort signals ------------
sigkill:	;9
sigabrt:	;6
  mov	esi,abort_msg
  call	str_move
  mov	[msg_build],byte 1
  or	[app_mode],byte 10h	;force window update
  ret 
;---
  [section .data]
abort_msg: db ' app aborting',0
  [section .text]

;report signals -----------
sigill:	;4 illegal instructon
sigsegv:	;11 memory error
 mov	esi,stop_msg
 call	str_move
  mov	[msg_build],byte 3	;hold msg, dead   
  or	[app_mode],byte 10h	;force window update
 ret
;------
  [section .data]
stop_msg: db ' app stopped',0
  [section .text]

;ignore signals -----------
;past problems:
; 1. If "asmbug asmmgr" then use F2 key in asmmgr, we hang.
;    The childs child exits and we get a SIGCHLD while asmmgr
;    is inside the kernel with a "wait4" function.  The fix
;    was to check r1_eax for negative state ( fffffdfe was found)
;    and clear it if found.  Then write app registers back and
;    continue.
;
sighup:	;1
sigint:	;2
sigquit:	;3
sigbus:	;7
sigfpe:	;8
sigusr1:	;10
sigusr2:	;12
sigpipe:	;13
sigalrm:	;14
sigterm:	;15
sigstkflt:	;16
sigchld:	;17 child exited
sigcont:	;18
sigtstp:	;20
sigttin:	;21
sigttou:	;22
sigurg:
sigxcpu:
sigxfsz:
sigvtalr:
sigprof:
sigwinch:	;terminal resize
sigio:
unknown:
 mov	esi,ignore_msg
 call	str_move
  mov	eax,[app_eax]
  or	eax,eax		;negative=inside kernel?
  js	inside_kernel
  mov	eax,[app_old_eax]
  jmp	short sig_cont1
inside_kernel:
  xor	eax,eax
  mov	[app_eax],eax	;tell kernel to continue
  mov	esi,app_regs
  call	trace_regsset
sig_cont1:
  movzx esi,byte [app_status+1] ;get signal to send
  call	trace_continue
  mov	[msg_build],byte 0
  or	[app_mode],byte 11h	;force window update
 ret
;------
  [section .data]
ignore_msg: db ' passed to app',0

SIGHUP_msg: db    'SIGHUP  ' ;1
SIGINT_msg: db    'SIGINT  '
SIGQUIT_msg: db   'SIGQUIT '
SIGILL_msg: db    'SIGILL  '
SIGTRAP_msg: db   'SIGTRAP ' ;5
SIGABRT_msg: db   'SIGABRT '
SIGBUS_msg: db    'SIGBUS  '
SIGFPE_msg: db    'SIGFPE  '
SIGKILL_msg: db   'SIGKILL '
SIGUSR1_msg: db   'SIGUSR1 ' ;10
SIGSEGV_msg: db   'SIGSEGV ' ;11
SIGUSR2_msg: db   'SIGUSR2 ' ;12
SIGPIPE_msg: db   'SIGPIPE '
SIGALRM_msg: db   'SIGALRM '
SIGTERM_msg: db   'SIGTERM '
SIGSTKFLT_msg: db 'SIGSTKFL'
SIGCHLD_msg: db   'SIGCHLD ' ;17
SIGCONT_msg: db   'SIGCONT '
SIGSTOP_msg: db   'SIGSTOP '
SIGTSTP_msg: db   'SIGTSTP '
SIGTTIN_msg: db   'SIGTTIN '
SIGTTOU_msg: db   'SIGTTOU '
SIGURG_msg: db    'SIGURG  '
SIGXCPU_msg: db   'SIGXCPU '
SIGXFSZ_msg: db   'SIGXFSZ '
SIGVTALRM_msg: db 'SIGVTALR'
SIGPROF_msg: db   'SIGPROF '
SIGWINCH_msg: db  'SIGWINCH'
SIGIO_msg: db     'SIGIO   '
           db	  'UNKNOWN '
	   db	  'UNKNOWN '
	   db	  'UNKNOWN '
	   db	  'UNKNOWN '
	   db	  'UNKNOWN '

pre_msg:   db ' Signal ',0
msg_build: times 30 db 0
  [section .text]
