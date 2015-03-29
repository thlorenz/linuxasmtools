 
  extern file_status_name
  extern hash_restore
  extern string_restore
  extern x_wait_event
  extern trace_pid
  extern trace_attach
  extern wait_pid
  extern traceme
  extern sys_run_die
;----------------


;-------------- 1setup.inc ----------------------
;launch elf_prep to work on target program
; output: js flag set if error
elf_prep:
  call	elfdecode
  mov	edi,lib_buf+600
  mov	[msg_ptr],edi		;init for status msg
;check if elf_prep had error
  mov	bh,[error_code]
  or	bh,bh
  jnz	ap_exit4		;jmp if error found
;show normal file stop msg
  mov	al,0
  stosb				;store event_mode
  stosb				;store msg length (dummy)
  mov	esi,ap_success_msg
  call	str_move
  mov	esi,LastTarget
  call	str_move
  sub	edi,lib_buf+602
  mov	eax,edi
  mov	[lib_buf+601],al
  jmp	short ap_exit5
;decode error in -bh-
ap_exit4:
  mov	al,3		;warning + exit
  stosb
  xor	eax,eax
  stosb			;store dummy message length
  neg	bh
  mov	al,bh		;get error number
;  push	eax		;save error number
  shl	eax,2		;make dword index
  add	eax,error_list -4
  mov	esi,[eax]
  call	str_move
  sub	edi,lib_buf+602
  mov	eax,edi
  mov	[lib_buf+601],al ;put message length into msg
  cmp	bh,7
  jne	ap_exit4a	;jmp if fatal
  and	[lib_buf+600],byte ~1 ;remove exit bit
  xor	eax,eax
  jmp	short ap_exit5
ap_exit4a:
  mov	eax,-1
ap_exit5:
  or	eax,eax		;set flags
  ret

;------------
  [section .data]

ap_success_msg:
 db 'app loaded and stopped - ',0

error_list:
  dd err1_
  dd err2_
  dd err3_
  dd err4_
  dd err5_
  dd err6_
  dd err7_

err1_: db 'Cant write to current directory',0ah,0
err2_: db 'File not found',0ah,0
err3_: db 'ELF format error',0ah,0
err4_: db 'Insufficient Memory',0ah,0
err5_: db 'Cant access file',0ah,0
err6_: db 'File format wrong',0ah,0
err7_: db 'Source newer than executable',0
;------------------
  [section .text]
;-----------------------------------------------------------
;return eax= negative if error
; store pointers to files: [load_image_ptr]
;                          [flag_image_ptr]
;                          [symbol_table_ptr]
; already defined (mem_header)
read_files:
  xor	eax,eax
  cmp	[preamble+pre.elf_phys_top],eax
  jnz	rf_05		;jmp if preamble in memory
  mov	ebx,header_file
  mov	ecx,preamble
  mov	edx,2000	;dummy size
  call	block_read_all
  or	eax,eax
  js	rf_exitj		;jmp if header not found
;find size of load image file
rf_05:
  mov	ebx,abug_image
  call	file_status_name
  js	rf_exitj		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size]
  mov	[load_image_size],eax
;allocate memory for load image
  call	m_allocate
  or	eax,eax
  js	rf_exitj
;read load image into memory
  mov	[load_image_ptr],eax
  mov	ecx,eax		;buffer to ecx
  mov	edx,[load_image_size]	;file size
  mov	ebx,abug_image	;file name
  call	block_read_all		;open and read file
  or	eax,eax
  js	rf_exitj

;find size of flag image file
  mov	ebx,abug_fimage
  call	file_status_name
rf_exitj:
  js	rf_exit		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size]
  mov	[flag_image_size],eax
;allocate memory for flag image
  call	m_allocate
  or	eax,eax
  js	rf_exit
;read flag image into memory
  mov	[flag_image_ptr],eax
  mov	ecx,eax		;buffer to ecx
  mov	edx,[flag_image_size]	;file size
  mov	ebx,abug_fimage	;file name
  call	block_read_all		;open and read file
  or	eax,eax
  js	rf_exit

;find size of symbol table file
  mov	ebx,abug_sym
  call	file_status_name
  js	rf_exit		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size]
  add	eax,4096	;increase size so symbols can be added
  mov	[sym_table_size],eax
;allocate memory for symbol table
  call	m_allocate
  or	eax,eax
  js	rf_exit
  mov	[symbol_table_ptr],eax
  mov	ebx,abug_sym	;file name
  mov	ecx,eax		;buffer
  mov	edx,[sym_table_size]
  call	hash_restore
;allocate memory and  read comment file if available
  call	comment_setup
rf_exit:
  ret
;----------------------------------------------------------
comment_setup:
  test	[preamble+pre.elf_type_flag],byte 20h	;check for comment file
  jz	cs_exit			;exit if no comment file
  mov	ebx,abug_comment	;filename
  call	file_status_name
  js	cs_exit		;exit if file not found
  mov	eax,[ecx+stat_struc.st_size]
  mov	[comment_file_size],eax
;allocate memory for comment file
  call	m_allocate
  or	eax,eax
  js	cs_err			;exit if memory allocation error
  mov	[comment_file_ptr],eax
;read file into memory
  mov	ebx,abug_comment	;filename
  mov	ecx,[comment_file_ptr]
  mov	edx,[comment_file_size]
  call	string_restore
  jmp	short cs_exit
cs_err:
  and	[preamble+pre.elf_type_flag],byte ~20h
cs_exit:
  ret
;------------------
  [section .data]
abug_comment: db ".abug_comment.dat",0
comment_file_size: dd 0
comment_file_ptr: dd 0
;------------
;hheader_file: db ".abug_header.dat",0	;image of header1
;abug_image: db ".abug_image.dat",0 ;load image
;abug_fimage: db ".abug_fimage.dat",0 ;flag image
;abug_sym:    db ".abug_sym.dat",0
;abug_undo:  db ".abug_undo.dat",0

load_image_size:	dd 0
load_image_ptr:		dd 0

flag_image_size:	dd 0
flag_image_ptr:		dd 0

sym_table_size:		dd 0
symbol_table_ptr:	dd 0

;---------------
;mem_header times mem_struc_size db 0


;---------------------------------------------------------------------
  [section .text]

launch_target:
  cmp	byte [parse_attach],0
  jz	lt_50		;jmp if normal launch
;this is a attach
  mov	eax,[attach_pid]
  mov	[trace_pid],eax	;setup global variable
  call	trace_attach
  jmp	short lt_60  

;fork duplicates program, including signal handling, open fd's etc.
;     only pending signals are cleared and PID changed.
;fork ---- fork

lt_50:
  mov	eax,2		;fork
  int	byte 80h
  or	eax,eax
  jz	child_processing
;parent path -- exit ---
  mov	[trace_pid],eax
;lt_wait:
  mov	ebx,[trace_pid]	;process to wait for
  mov	edx,0		;wait forever

  xor	esi,esi
  call	trace_wait
lt_60:
  mov	[app_mode],byte 4	;set app stopped state
;get initial registers
  mov	esi,regs_1
  call	trace_regsget
  ret
  
;child processing ---------------------------- child -----------

child_processing:
  call	traceme
;execute command ----  exec ----
; execve passes PID and open fd's on.  Signals are
; set to their defualt state.  The SIGCHLD state is
; undetermined if set to SIG_IGN (no handler)
; pending signals are cleared.
  mov	esi,LastTarget
  mov	edi,lib_buf+400
  call	str_move
  inc	edi
  mov	esi,LastTargetParm
cp_lpy:
  lodsb
  or	al,al
  jz	ccp_50		;jmp if end of parameters
  cmp	al,' '
  jne	ccp_10		;jmp if not space
  mov	al,0
ccp_10:
  stosb
  jmp	short cp_lpy
;start app -----------
ccp_50:
  mov	dword [edi],0	;terminate parameters
  mov	esi,lib_buf+400
  call	sys_run_die
;should not get here
  mov	eax,1
  int	byte 80h			;exit
;end of child processing ----
  ret

