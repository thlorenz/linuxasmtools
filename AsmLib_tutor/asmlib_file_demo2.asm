  extern sys_exit
  extern dir_access
  extern dir_create
  extern dir_delete

  [section .text]

 global _start
_start:
  mov	ebx,dir_path		;file path
  xor	ecx,ecx			;check if dir exists
  call	dir_access
  or	eax,eax			;check return
  jz	remove_dir		;jmp if directory exists
;create directory
  mov	ebx,dir_path
  call	dir_create		;create directory
  or	eax,eax
  js	test_err1		;jmp if error
  mov	ebx,dir_path
  xor	ecx,ecx			;check if dir exists
  call	dir_access
  or	eax,eax
  jnz	test_err1		;jmp if directory not found
;remove directory
remove_dir:
  mov	ebx,dir_path
  call	dir_delete		;remove directory 
test_err1:
  call	sys_exit


;----------------------
  [section .data]

dir_path:  db  '/tmp/file_demo2',0

;----------------------
  [section .bss]

