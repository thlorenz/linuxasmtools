; ioperm example:
; produce a sound on internal speaker, we
; need to run this is root user or use "sudo ./xxxx"
;

  global _start
_start:
  mov	eax,101		;ioperm kernel call
  mov	ebx,61h		;starting port
  mov	ecx,1		;number of ports to enable
  mov	edx,1		;enable flag
  int	byte 80h	;enable port
  or	eax,eax
  js	err_exit

  mov	edx,20000	;duration
  in	al,61h
  and	al,0feh
again:
  or	al,2
  out	61h,al
  mov	ecx,300		;frequency
wait1:
  loop	wait1
  and	al,0fdh
  out	61h,al
  mov	ecx,300
wait2:
  loop	wait2
  dec	edx
  jnz	again
  jmp	exit

err_exit:
  mov	eax,4		;write
  mov	ebx,1		;stdout
  mov	ecx,msg
  mov	edx,msg_length
  int	byte 80h

exit:
  mov	eax,1
  int	byte 80h

;-----------------
  [section .data]

msg:
 db 'ioperm kernel call failed, are we root?',0ah
msg_length  equ $ - msg


