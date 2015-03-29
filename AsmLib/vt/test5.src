
  [section .text align=1]

%include "../include/macro.inc"
%include "../include/signal.inc"
%include "../include/system.inc"
%include "../include/dcache_colors.inc"

;external library calls follow    
  extern sys_exit
  extern sys_read
  extern sys_write
  extern env_stack
  extern read_window_size

  extern vt_setup
  extern vt_ptty_setup
  extern ptty_pid
  extern vt_out
;%include "vt_out4.inc"

  extern vt_close
  extern vt_ptty_launch
  extern ptty_fd

;%include "vt_flush4.inc"
  extern vt_flush
;%include "vt_in.inc"
  extern vt_in
  extern vt_top_row
  extern vt_top_left_col

  extern event_setup
  extern vt_fd

  extern signal_hit_mask
  extern sigchld_pid
  extern event_close
  extern sys_poll

  extern list_check_front
  extern list_get_from_front
  extern list_put_at_end
  extern list_check_end
 
  global _start
_start:
  call	env_stack
  call	read_window_size	;needed for vt_flush
  mov	esi,vt_setup_block
  call	vt_setup

  mov	eax,launch_name
  call	vt_ptty_setup
  call	vt_flush
  call	vt_ptty_launch
  call	write_help
;
;catch abort signals
;
sig_mask equ	_ABORT+_CHLD+_WINCH
; non abort signals that need checking are _CHLD (child died)  _WINCH (display resize)
  mov	eax,sig_mask	;enable mask
  mov	ebp,cleanup	;send abort signals here
  mov	dl,0		;no keyboard handler
  call	event_setup	;enable signal handlers
  and	[signal_hit_mask],dword ~_WINCH	;clear winch flag
;setup for wait event
  mov	eax,[vt_fd]
  mov	[pollfd],eax
  mov	eax,[ptty_fd]
  mov	[app_fd],eax

event_loop:
  test	[signal_hit_mask],dword _CHLD	;has child died?
  jnz	SIGCHLD_code			;jmp if a child has died
  call	wait_event
;return eax =
; +  number of events (0=timeout)
; EBADF  -9 An invalid file descriptor was given in one of the sets.
; EFAULT -14 The array given as argument was not  contained  in  the  calling
;        program’s address space.
; EINTR  -4 A signal occurred before any requested event.
; EINVAL -22 The nfds value exceeds the RLIMIT_NOFILE value.
; ENOMEM -12 There was no space to allocate file descriptor tables.
; [app_rev] and [key_rev] have event flags
  jns	event_waiting
  cmp	eax,-4	;did a signal interrupt?
  je	signal_event  
;if eax=0 then a timeout occured, not
;possible, so must be program error
  jmp	cleanup
;
;possible signal events are WINCH,HUP,CHLD
signal_event:
  mov	eax,[signal_hit_mask]
  cmp	eax,dword _WINCH
  je	SIGWINCH_code
  cmp	eax,dword _CHLD
  je	SIGCHLD_code
  test	[signal_hit_mask],dword _HUP
  jz	event_loop
; logstr "SIGHUP "
; logeol
  jmp	cleanup
event_waiting:
  test	[app_rev],word POLLIN + POLLPRI
  jnz	app_out_event
  test	[key_rev],word POLLIN + POLLPRI	;events of interest (see above)
  jnz	key_event
other_event:

;  logstr "other event, key_evn="
;  xor	eax,eax
;  mov	ax,[key_rev]
;  logeax
;  logstr ' app_rev='
;  mov	ax,[app_rev]
;  logeax
;  logeol

  jmp   cleanup

;************
SIGCHLD_code:  ; child died
  and	[signal_hit_mask],dword ~_CHLD
  mov	eax,[sigchld_pid]
  cmp	eax,[ptty_pid]
  je	cleanup		;jmp if child dead
  jmp	event_loop	;ignore this signal

;************
SIGWINCH_code: ; terminal resize
winch_loop:
  and	[signal_hit_mask],dword ~_WINCH
  mov	eax,-1
;;  call	delay
  test	[signal_hit_mask],dword _WINCH
  jnz	winch_loop
;;  call	display_setup
  jmp	event_loop
;;  jmp	restart

;************
app_out_event:
  mov	ecx,read_app_buf
  mov	edx,10000
  mov	ebx,[ptty_fd]
  call	sys_read
  or	eax,eax
  jz	key_event	;exit if no data
  jns	do_app_30	;jmp if good read

;  logstr "app read failed with: "
;  logeax
;  logeol
  jmp	event_loop

do_app_30:
  mov	edx,eax		;move read size to edx
  call	vt_out		;process data
  call	vt_flush

;************
key_event:
  test	[key_rev], word POLLIN + POLLPRI
  jz	event_loop
  call	local_vt_in
  jmp	event_loop

;--------------------------------------------------------
cleanup:
  call	event_close
  call	vt_close
  call	sys_exit

;------------------------------------------------
write_help:
  mov	ecx,help_msg
  mov	edx,help_msg_size
  call	vt_out
  call	vt_flush
  ret
;------------------------------------------------


wait_event:
  mov	[key_evn],word POLLIN + POLLPRI
  mov	[app_evn],word POLLIN + POLLPRI
  mov	ebx,pollfd
  mov  ecx,2        ;number of elements in pollfd
  mov  edx,-1	;wait forever
  call	sys_poll
  ret
;--------------------
wait_io_possible:
  mov	[key_evn],word POLLOUT
  mov	[app_evn],word POLLOUT
  mov	ebx,app_fd
  mov  ecx,1        ;number of elements in pollfd
  mov  edx,-1	;wait forever
  call	sys_poll
  ret

;return eax =
; +  number of events (0=timeout)
; EBADF  An invalid file descriptor was given in one of the sets.
; EFAULT The array given as argument was not  contained  in  the  calling
;        program’s address space.
; EINTR  A signal occurred before any requested event.
; EINVAL The nfds value exceeds the RLIMIT_NOFILE value.
; ENOMEM There was no space to allocate file descriptor tables.
; [app_rev] and [key_rev] have event flags
;--------------
  [section .data]

; Event types that can be polled for.  These bits may be set in `events'
; to indicate the interesting event types; they will appear in `revents'
; to indicate the status of the file descriptor.
POLLIN		equ 0x001	;There is data to read.  */
POLLPRI		equ 0x002	;There is urgent data to read.  */
POLLOUT		equ 0x004	;Writing now will not block.  */
POLLMSG		equ 0x400	;(not used)
POLLRDHUP	equ 0x2000	;Stream socket peer closed connection or shut down
POLLERR		equ 0x008	;(set by OS) Error condition.
POLLHUP		equ 0x010	;(set by OS) Hung up.
POLLNVAL	equ 0x020	;(set by OS) Invalid polling request.
POLLRDNORM	equ 0x040	;Normal data may be read (same as POLLIN)
POLLRDBAND	equ 0x080	;Priority data may be read (not often useful)
POLLWRNORM	equ 0x100	;Writing now will not block (same as POLLOUT)
POLLWRBAND	equ 0x200	;Priority data may be written

pollfd:
          dd 0	;keyboard input fd
key_evn:  dw POLLIN + POLLPRI	;events of interest (see above)
key_rev:  dw 0	;.revents (events that occured)

app_fd    dd 0	;ptty_fd goes here
app_evn:  dw POLLIN + POLLPRI	;events of interest (see above)
app_rev:  dw 0	;.revents (events that occured)

;------------------------------------------------
;---------------------------------------------------


local_vt_in:
  mov	ebx,0
  mov	ecx,key_buf
  mov	edx,2000
  call	sys_read
  jz	vt_in_exit		;exit if out of data
  jns	do_read
;  cmp	eax,-11
;  je	vt_in_exit
  jmp	vt_in_exit

;  logstr "key read failed with: "
;  logeax
;  logstr "  sigio_status="
  
;handle mouse clicks
; mouse click report = <esc> [m 2x 2r 2c  x=button r=row c=col
; cursor report = <esc> [xx;yyR is handled elsewhere.
;
do_read:
  mov	edx,eax		;size of read to edx

  call	vt_in
vt_in_exit:
  ret


;------------------------------------------
;------------------------------------------
;------------------------------------------
  [section .data]


vt_setup_block:
  dd 24	;rows
  dd 80 ;columns
  dd vt_image_buf
  dd 1	;fd
  dd 0	;top row
  dd 0	;top left col
  db grey_char + black_back
  
;launch_name:	db '/home/jeff/bin/vttest',0,'-l',0,0
;launch_name:	db '/bin/bash',0,'-c',0,'/bin/bash',0,0
launch_name:	db '/bin/bash',0,0
;launch_name:	db '/bin/ls',0,0
;launch_name:	db '/bin/less term.asm',0,0
;launch_name: db '/bin/pwd',0,0
;launch_name: db '/usr/bin/strace',0,'-o',0,'xx',0,'/bin/bash',0,0
;launch_name: db '/usr/bin/strace',0,'-o',0,'xx',0,'/home/jeff/work/test2',0,0
;launch_name: db '/usr/bin/crt_test',0,0
vt_image_buf: times 20000 db 0
read_app_buf: times 10000 db 0
key_buf:  times 2000 db 0

help_msg: db "type  exit  to leave vt terminal",0ah,0dh
 db "enter normal shell commands to test",0ah,0dh
help_msg_size equ $ - help_msg
  [section .text]

