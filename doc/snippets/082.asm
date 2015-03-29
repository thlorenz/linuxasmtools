; oldselect - function example
;wait for key press

  global _start
_start:
  mov	eax,82	;newselect function#
  mov	ebx,sstruc
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]
sstruc:
 dd	1	;last fd +1
 dd	read_events
 dd	write_events
 dd	except_events
 dd	wait_time

read_events: dd 1	;stdin (0)
write_events: dd 0
except_events: dd 0
wait_time: dd 8	;seconds
	dd 0	;useconds
  [section .text]


