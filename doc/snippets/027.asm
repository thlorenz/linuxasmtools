; alarm/pause example:
;
  extern signal_install

  global _start
_start:
  mov	ebx,14		;sig_alarm
  mov	ecx,handler
  call	signal_install

  mov	eax,27		;alarm
  mov	ebx,1		;seconds
  int	80h

  mov	eax,29		;pause
  int	80h

  mov	eax,[got_signal]

  mov	eax,27
  mov	ebx,0
  int	80h
  mov	ebx,eax
exit:
  mov	eax,1
  int	byte 80h


sig_alarm:
  inc	dword [got_signal]
  ret
;-----------------
  [section .data]
handler:
  dd sig_alarm
  dd 0		;mask
  dd 4		;flags
  dd 0

got_signal: dd 0

 [section .text]




