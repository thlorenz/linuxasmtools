  extern trace_wait
  extern process_info_pidn
  extern trace_poke_bytes
  extern byte_to_ascii

;output: eax=process or zero
check_app:
  cmp	[app_mode],byte 12	;app running?
  jae	ca_05			;jmp if app running
  jmp	ca_exit2		;exit if not running
ca_05:
;get status of app -;check if app stopped yet
  xor	eax,eax
  mov	[app_status],eax

  mov	eax,114
  mov	ebx,[trace_pid]
  mov	ecx,app_status
  mov	edx,1				;WNOHANG
  xor	esi,esi
  int	byte 80h
;returns eax=err if app dead
;returns eax=0 if no change in status
;returns eax=pid if stop and status filled in
  or	eax,eax
  js	ca_dead1
  jz	ca_exit2	;exit if app still running
;app has stopped, check status

%ifdef TRACE
  call	app_log
%endif

;get registers
  mov	esi,regs_1
  call	trace_regsget
;check if app killld by signal
  mov	eax,[app_status]	;al=0 process exit, 1-7e killed by -ah- signal
  cmp	al,7fh			;check if stopped
  jne	ca_dead2		;assume app dead due to signal or normal exit
;we have stopped due to signal (ah=signal number)
  movzx ebx,byte ah		;get signal that stopped app
  shl	ebx,2			;make dword
  add	ebx,signal_handlers -4
  call	[ebx]	;------------>  call signal processing
  jmp	short ca_exit
ca_dead1:
  mov	eax,unknown_death
  jmp	short ca_dead3
;signal death, ah=signal number
ca_dead2:
  movzx esi,byte ah		;get signal number
  or	esi,esi
  jnz	ca_dead4		;jmp if signal stop
  mov	eax,app_exit_msg	;normal app exit message
  jmp	short ca_dead3
ca_dead4:
  shl	esi,3			;convert to index
  add	esi,SIGHUP_msg-8	;lookup in  table
;move signal name to msg
  mov	edi,sd_stuff1		;move signal name
  mov	ecx,8
  rep	movsb
  mov	eax,signal_death
ca_dead3:  
  mov	[msg_ptr],eax		;enable msg display
  mov	[app_mode],byte 8	;set dead mode
ca_exit:
  mov	[win_bit_map],byte 3fh	;show windows
ca_exit2:
  ret



;-------------
  [section .data]
signal_death:
  db 2	;event mode setting
  db sd_len
sd_msg:
  db 'App '
  db 'dead '
  db 'by signal '
sd_stuff1:
  db '        '
sd_end:
sd_len equ $ - sd_msg

unknown_death:
  db 2
  db ud_len
ud_msg:
  db 'App unknown death'
ud_end:
ud_len equ $ - ud_msg

app_exit_msg:
  db 2
  db aem_len
aem_msg:
  db 'App normal exit'
aem_end:
aem_len equ $ - aem_msg

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
 dd _sig_30
 dd _sig_31
 dd _sig_32

  [section .text]

;expected signals -------------------------------------------
sigtrap:	;5 breakpoint
  dec	dword [r1_eip]		;fix eip for breakpoint stop

sigstop:	;19 stop request signal
  call	remove_breaks		;clean up app breaks
;check if step over processing
;stepover_restore_flag	db 0 ;1=restore break1  2=remove break2 4=stepover active
;break1: dd 0	;break at eip
;break2: dd 0	;break set on next instruction
  cmp	byte [stepover_restore_flag],0
  je	ca_20		;jmp if stop after "go"
;clean up after stepover
  test	[stepover_restore_flag],byte 1
  jz	ca_10			;jmp if break1 ok
  mov	edx,[break1]
  call	add_break
ca_10:
  test	[stepover_restore_flag],byte 2
  jz	ca_15			;jmp if no break2
  mov	edx,[break2]
  call	remove_break
ca_15:
  mov	[stepover_restore_flag],byte 0
ca_20:
  call	do_status
;check if inside the kernel and replace message with warning
  test	[event_mode],byte 4	;forced stop
  jz	ca_22			;exit if normal stop
  cmp	[r1_eax],dword 0fffffe00h	;inside kernel check
  jne	ca_22		;exit if not inside the kernel
  mov	[msg_ptr],dword kernel_msg
ca_exit3:
  and	[event_mode],byte ~4	;clear forced stop if set
ca_22:
  ret


;abort signals ------------
sigkill:	;9
sigabrt:	;6
  call	do_status
  mov	[event_mode],byte 1
  ret 

;report signals -----------
sigill:	;4 illegal instructon
sigsegv:	;11 memory error
 call	do_status
 mov	[event_mode],byte 4
 ret

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
_sig_30:
_sig_31:
_sig_32:
  mov	eax,[r1_eax]
  or	eax,eax		;negative=inside kernel?
  js	inside_kernel
;  mov	eax,[r1_old_eax]
  jmp	short sig_cont1
inside_kernel:
  xor	eax,eax
;;  mov	[r1_eax],eax	;tell kernel to continue
;;  mov	esi,regs_1
;;  call	trace_regsset
sig_cont1:
  movzx esi,byte [app_status+1]
  call	trace_continue
  ret  

;-----------------------------------------------------------------
do_status:
  mov	eax,[app_status]
  cmp	al,0		;check app exit
  jne	ds_10
;app normal exit
  mov	byte [app_mode],8 ;app_mode = dead
  mov	eax,'exit'
  mov	[sm_stuff1],eax

  mov	edi,sm_stuff1+5
  mov	eax,'code'
  stosd
  mov	al,' '
  stosb
  mov	al,[app_status+1]
  call	byte_to_ascii
  mov	al,' '
sm_lpx:
  stosb
  cmp	edi,sm_end
  jne	sm_lpx
  or	byte [event_mode],2	;warning flag
  jmp	short ds_90
;check if app normal stop
ds_10:
  cmp	al,7fh
  jne	ds_20		;jmp if app killed
;normal stop
  mov	byte [app_mode],4 ;app_mode = stop
  mov	eax,'stop'
  mov	[sm_stuff1],eax
  jmp	short add_signal
;app killed by signal
ds_20:
  mov	byte [app_mode],8 ;app_mode = killed
  mov	eax,'kill'
  mov	[sm_stuff1],eax

add_signal:	
  movzx eax,byte [app_status+1]
  shl	eax,3
  add	eax,SIGHUP_msg - 8
  mov	ebx,[eax]
  mov	ecx,[eax+4]
ds_80:
  mov	[sm_stuff2],ebx
  mov	[sm_stuff2+4],ecx

ds_90:
  mov	eax,stop_msg
  mov	[msg_ptr],eax
  ret
;-------------
  [section .data]
stop_msg:
  db 0	;event mode setting
  db sm_len
sm_msg:
  db 'App '
sm_stuff1:
  db 'stop '
  db 'by signal '
sm_stuff2:
  db '        '
sm_end:
sm_len equ $ - sm_msg


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
SIGIO_msg: db     'SIGIO   '  ;29
           db     'sig_30  '
           db     'sig_31  '  ;31
           db     'sig_32  '  ;32

kernel_msg:
  db 2	;event mode setting
  db k_len
kernel_msg_txt:
  db 'Warning-stop inside kernel,EAX->0 will exit'
k_len equ $ - kernel_msg_txt

  [section .text]
;-----------------------------------------------------------------
remove_breaks:
  mov	esi,Breaks
rb_lp:
  mov	edx,[esi]			;get poke address
  or	edx,edx
  jz	rb_done				;jmp if end of breaks
  add	esi,4
  mov	al,[esi]			;get data
  push	esi
  mov	[restore_data],al
  mov	esi,restore_data
  mov	edi,1				;get number of bytes
  call	trace_poke_bytes
  pop	esi
  inc	esi
  jmp	short rb_lp
rb_done:
  ret
;------------
  [section .data]
restore_data: db 0
  [section .text]
;--------------------------------
; inputs: none
; output: eax is negative means error, if positive then
;         al= "U" unknown pid
;             "S" sleeping
;             "R" running
;             "T" stopped
;             "Z" zombie
;             "D" dead
check_state:
  mov	eax,[trace_pid]
  call	process_info_pidn	;lib_buf has ascii strings with info
  or	eax,eax
  js	ccs_exit			;exit if error
  mov	edi,lib_buf
  cld
  mov	al,09h			;tab
cs_loop1:
  scasb	
  jne	cs_loop1
cs_loop2:
  scasb	
  jne	cs_loop2
;we are now at second tab, and data we want is next byte
  xor	eax,eax
  mov	al,[edi]		;get status character
ccs_exit:
  ret

;----------------
  [section .data]
app_status  dd 0  
  [section .text]