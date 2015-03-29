  extern crt_write
  extern block_read_all
  extern sys_exit

  global _start,main
main:
_start:
  mov	ecx,cpu_msg	;message ptr
  mov	edx,cpu_msg_size	;message length
  call	crt_write	;kernel call

  mov	ebx,cpuinfo_path
  mov	ecx,buffer
  mov	edx,buffer_size
  call	block_read_all
  or	eax,eax
  js	sc_exit		;exit if error

  mov	edx,eax		;size to edx
  mov	ecx,buffer	;data ptr
  call	crt_write

sc_exit:
  call	sys_exit

;----------
  [section .data]
cpuinfo_path: db '/proc/cpuinfo',0
cpu_msg:
incbin "cpu.inc"
cpu_msg_size	equ $ - cpu_msg
  [section .text]
;------------------------------------------------
  [section .bss]

buffer	resb	200
buffer_size equ $ - buffer


	