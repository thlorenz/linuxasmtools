  extern sys_exit
  extern stdout_str
  extern delay
  extern sys_fork_run
  extern kill_process
  extern check_process  
;----------------------------------------------------
; This program demonstrates starting a process
;
; compile with:
;  nasm -felf -g asmlib_process_demo.asm
;  ld asmlib_process_demo.o -o asmlib_process_demo /usr/lib/asmlib.a
;
;----------------------------------------------------
; this is beginning of demo, it starts a process,
; displays a message, then waits for child process
; to start. 
  [section .text]

  global _start
_start:
  mov	esi,child_process_name
  call	sys_fork_run
  or	eax,eax		;check if success
  js	do_exit		;goto exit if error
  mov	[child_pid],eax	;save process id for child
;check if child process is running
check_loop:
  mov	ebx,[child_pid]
  call	check_process	;get child status
; al contains status as follows
;  'U' unknown pid
;  'S' sleeping
;  'R' running
;  'T' stopped
;  'D' uninterruptable
;  'Z' zombie
  cmp	al,'U'
  je	check_loop	;loop till process created
;
  mov	ecx,demo_msg1	;get message
  call	stdout_str	;display message
;kill child process
  mov	ebx,[child_pid]
  call	kill_process
  or	eax,eax		;zero = success
  jnz	do_exit		;exit if error

  mov	ecx,demo_msg2	;get message 2
  call	stdout_str	;display message 2
  mov	eax,-2		;delay 2 seconds
  call	delay

do_exit:
  call	sys_exit	;all done
  
;--------------------------------------------------
  [section .data]
child_process_name: db 'dummy_process',0
child_pid	dd 0	;process id for child
demo_msg1:	db 0ah,'child process started and running',0ah
		db 'sending kill message to child',0
demo_msg2:	db 0ah,'child process killed',0ah,0


;