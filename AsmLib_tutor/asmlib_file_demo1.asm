  extern sys_exit
  extern block_open_update
  extern block_write
  extern block_seek
  extern block_read
  extern block_close
  extern file_delete

  [section .text]

 global _start
_start:
  mov	ebx,file_path		;file path
  xor	ecx,ecx			;use default file premissions
  call	block_open_update
  or	eax,eax			;any errors?
  js	test_err1		;exit if error
  mov	[file_handle],ebx	;save file handle
;now write data to file
  mov	ecx,file_write_data
  mov	edx,file_size
  call	block_write
;seek to start of file
  mov	ebx,[file_handle]
  xor	ecx,ecx			;seek to start of file
  call	block_seek
;read data back from file
  mov	ebx,[file_handle]
  mov	ecx,file_read_data
  mov	edx,file_size
  call	block_read
;verify we read file
  cmp	[file_read_data],byte 55h
  jne	test_err1
  cmp	[file_read_data+file_size-1],byte 55h
  jne	test_err1
;close file
  mov	ebx,[file_handle]
  call	block_close
  mov	ebx,file_path
  call	file_delete
test_err1:
  call	sys_exit


;----------------------
  [section .data]

file_path:  db  '/tmp/file_demo1',0
file_handle: dd 0
file_write_data: times 100 db 55h
file_size	equ $ - file_write_data

;----------------------
  [section .bss]
file_read_data:	resb 100

