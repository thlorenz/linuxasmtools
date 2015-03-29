  [section .text align=1]
%include "../include/signal.inc"

  extern signal_install_group
  extern installed_sig_mask
  extern get_our_process_id
;---------------------------------------------------
;>1 key_sig
; signal_attach - set action for signal
; INPUT
;  eax = signal# to attach
;        SIGIO used by key_setup, other choices
;        are SIGURG,SIGUSR1,SIGUSR2
;  ebx = fd to attach
;  ecx = signal mask in signal_mask format (see signal.inc)
;   dl = 0 if not SIGIO or keyborad handling not wanted, 1=keyboard sigio
; OUTPUT
;   al = results of request, jns=success js=error
;         0 = success
;       -22 = EINVAL An invalid signal was specified.
;       -14 = EFAULT memory error
;       -4  = EINTR  System call was interrupted.
;
; NOTE
;   source file = signal_attach.asm
;
;<
;----------------------------------------------------
  global signal_attach
signal_attach:
  or	[installed_sig_mask],ecx	;set mask bit
  mov	[sa_fd],ebx		;save fd
  mov	[sa_sig],eax		;save signal#
  mov	edx,ecx			;mask
  mov	ah,1			;set our handler
  mov	al,dl			;get sigio flag
  call	signal_install_group
  js	sa_exit
;get process and tty
  call	get_our_process_id
  mov	edx,eax
;set owner
  mov	eax,55
  mov	ebx,[sa_fd]
  mov	ecx,8			;F_SETOWN
;  mov	edx,[our_id]
  int	byte 80h
  or	eax,eax
  js	sa_exit			;exit if error
;set state flags
  mov	eax,55
;  mov	ebx,[sa_fd]
  mov	ecx,4			;F_SETFL
  mov	edx,024000q		;O_ASYNC O_NONBLOCK
;  mov	edx,020000q		;O_ASYNC
  int	byte 80h
  or	eax,eax
  js	sa_exit
;set alt signal
  mov	eax,55
;  mov	ebx,[sa_fd]
  mov	ecx,10			;F_SETSIG
  mov	edx,[sa_sig]		;signal#
  int	byte 80h
sa_exit:
  or	eax,eax			;set flags
  ret
;------------
  [section .data]
sa_fd:	dd	0
sa_sig: dd 	0
our_id: dd	0
  [section .text]
