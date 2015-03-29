q; -- source template - edit as needed --
  [section .text]
  extern sys_exit
  global _start,main

extern sys_getuid
extern stdout_str
extern crt_write

extern byte_to_ascii
extern sys_ioperm

main:
_start:
  call	sys_getuid
  or	eax,eax		;check if root
  jz	we_root
  mov	ecx,warning
  call	stdout_str
  jmp	cmos_exit

we_root:  
  mov	ecx,cmos_msg
  mov	edx,cmos_msg_size
  call	crt_write

  mov	ebx,70h	;starting port
  mov	ecx,2	;number of ports
  mov	edx,1	;enable
  call	sys_ioperm
  js	cmos_exit

  mov	esi,[cmos_table_ptr]
cmos_read_loop:
  mov	al,[esi]	;get address
  cmp	al,-1
  je	cmos_exit	;exit if end of table
  call	read_cmos	;read byte
  mov	edi,cmos_value
  call	byte_to_ascii
  mov	[edi],byte 0ah	;terminate value string
  inc	edi
  mov	[edi],byte 0

  inc	esi		;move past address
  mov	ecx,esi		;get ptr to text
  call	stdout_str
  mov	ecx,cmos_value
  call	stdout_str

cmos_next_table:
  lodsb
  or	al,al
  jnz	cmos_next_table
  jmp	short cmos_read_loop

cmos_exit:
  call	sys_exit	;library call example
;----------------------------------------------
;input: al=address
;output: al=data
read_cmos:
  mov	dx,70h	;adr select port
  out	dx,al	;select adr
  call	waitx
  mov	dx,71h	;data port
  in	al,dx	;read data
  ret
;---------------------------------------------
waitx:
  movzx	ecx,dl
wx: loop wx
  ret
;---------------------------------------------
  
 [section .data]

cmos_table:
 db  06h        ;Day of the Week
 db  'address 06 (day of week) = ',0

 db  07h        ;Day of the Month
 db  'address 07 (day of month) = ',0

 db  08h        ;Month
 db  'address 08 (month) = ',0

 db  09h        ;Year
 db  'address 9 (year) = ',0

 db  -1		;end of table

cmos_table_ptr	dd cmos_table
cmos_value	times 5 db 0

warning: db 0ah,'Root access required',0ah,0

cmos_msg:
incbin "cmos.inc"
cmos_msg_size equ $ - cmos_msg
