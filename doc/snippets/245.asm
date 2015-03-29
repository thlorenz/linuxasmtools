; aio copy - function example


  global _start
_start:
  mov	eax,5	;open
  mov	ebx,filename1
  xor	ecx,ecx
  xor	edx,edx
  int	80h
  mov	[file1_fd],eax

  mov	eax,5	;open
  mov	ebx,filename2
  mov	ecx,41h	;create
  mov	edx,1b5h ;permissions
  int	80h
  mov	[file2_fd],eax


  mov	eax,245		;io setup
  mov	ebx,2		;number of events
  mov	ecx,context_ptr
  int	80h

;setup for io submit

  mov	eax,[file1_fd]
  mov	[read_fd],eax  

  mov	eax,248		;io_submit
  mov	ebx,[context_ptr]
  mov	ecx,1		;number of events to submit
  mov	edx,iocb_array
  int	80h

;get event status

event_lp:
  mov	eax,247		;io_getevents
  mov	ebx,[context_ptr]
  mov	ecx,1		;get one event
  mov	edx,2		;max events
  mov	esi,event_save
  mov	edi,0		;timeout
  int	80h

  cmp	[rtn1],dword 0
  je	event_lp

_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;handler for event
;this code is not called, it is used in some programs?
; how do we eanble this read done signal?
read_done:
  nop
  ret


;---
  [section .data]

filename1: db 'test.asm',0
filename2: db 'test.cpy',0
file1_fd   dd 0
file2_fd   dd 0
context_ptr dd 0

iocb1:		;read control block
  dd	read_done	;handler
  dd	0		;padding

  dq	0		;key
  dw	0		;opcode 0=read
  dw	0		;priority
read_fd:
  dd	0		;fd  
  dd	read_buf	;buffer
  dd	0		;padding

  dd	read_buf_size
  dd	0		;padding

  dq	0		;offset

read_buf: times 10000 db 0
read_buf_size equ $ - read_buf

iocb_array: dd	iocb1
            dd	0	;padding?

event_save:
  dq 0		;completion handler
  dq 0		;iocb ptr
rtn1:
  dq 0		;return code
  dq 0		;return code 
;