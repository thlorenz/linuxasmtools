; newselect - function example
;wait for key press

  global _start
_start:
  mov	eax,142	;newselect function#
  mov	ebx,1	;high fd +1
  mov	ecx,read_events
  mov	edx,0	;write events
  mov	esi,0	;except events
  mov	edi,wait_time
  int	80h

  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]

read_events: dd 1	;stdin (0)
write_events: dd 0
except_events: dd 0
wait_time: dd 8	;seconds
	dd 0	;useconds
  [section .text]


