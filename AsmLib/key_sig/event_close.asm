  [section .text align=1]

  extern signal_install_group
  extern installed_sig_mask
  extern sys_close
  extern tty_fd
  extern termios1

%include "../include/signal.inc"
;---------------------------------------------------
;>1 key_sig
; event_close - close program events
; INPUT
;   none
; OUTPUT
;   none
; NOTE
;   source file = event_close.asm
;<
;----------------------------------------------------
  global event_close
event_close:
;setup signal mask
  mov	ah,0		;set flag to install default handler
  mov	al,0		;ignored
  mov	edx,[installed_sig_mask]
  call	signal_install_group
;save termios and set raw mode
  mov	ebx,[tty_fd]
  mov	ecx,5402h
  mov	edx,termios1
  cmp	[edx],dword 0	;anything there?
  je	ec_tty		;jmp if no termios
  mov	eax,54
  int	80h
;close tty
ec_tty:
  mov	ebx,[tty_fd]
  cmp	ebx,byte 2
  jbe	ec_exit		;exit if not setup
  call	sys_close
ec_exit:
  ret  
;------------------
