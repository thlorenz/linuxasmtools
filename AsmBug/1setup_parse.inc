  extern str_compare
;-------------- 1setup.inc ----------------------
;input:
; parse states:  asmbug                      <- use history data,verify history data present
;                asmbug <prog> <parmaters>   <- stuff in history,clear existing asmdis files
;                asmbug -a <prog>            <- set flag and lookup pid for program
;                asmbug -h                   <- show help and exit
;output: sign flag set if error
parse:
;check if any parameters
  mov	esi,esp
  lodsd			;clear return address from stack
  lodsd			;get parameter count, 1=none

  push	eax		;save parm count
  lodsd			;get our executable name ptr
  mov	[our_name],eax
  pop	eax

  dec	eax
  jnz	pi_10		;jmp if parameter entered
  call	check_history	;veriify filename in history
  jmp	short pi_exit ;js/jns set indicating if history found
;get parameters
pi_10:
;  lodsd			;eax=our executable name ptr
pi_sw_lp:
  lodsd			;eax=ptr to user parameter
  or	eax,eax
  jz	pi_exit		;exit if all parameters processed
pi_12:
  cmp	word [eax],'-a'
  jne	pi_target
  call	attach_setup
  jmp	short pi_exit
pi_target:
  call	get_target
  js	pi_exit
  mov	edi,LastTargetParm
pi_parm_lp:
  lodsd			;get parameter ptr
  or	eax,eax
  jz	pi_exit2	;exit if no parameters
  push	esi
  mov	esi,eax
  call	str_move
  mov	al,' '
  stosb
  cmp	edi,LastTargetParm + 100 ;overflow?
  ja	pi_err		;exit if error
  pop	esi		;restore stack ptr
  jmp	short pi_parm_lp
pi_err:
  mov	eax,err3
  call	show_error
  or	eax,byte -1
  jmp	short pi_exit
pi_exit2:
  xor	eax,eax
  stosd			;zero end of parmaters
pi_exit:
  or	eax,eax
  ret
;---------
  [section .data]
err3: db 0ah,'parse error',0
  [section .text]
;-------------------------------------------------------------
; parse target filename,check if file
; exists, any other parsed entry is error.
; eax=ptr to parameter
; esi=ptr to stack ptrs 
get_target:
  mov	[gt_name_ptr],eax
  push	esi		;save stack ptr

  mov	edi,LastTarget
  mov	esi,eax			;get parameter ptr
  call	str_compare
  je	gt_10			;jmp if strings the same
;new file entered, zero some fields
  mov	[MemWinAdr],dword 0
;is full path of file provided?
gt_10:
  cmp	byte [eax],'/'
  jne	gt_20			;jmp if not full path
  mov	esi,eax
  mov	edi,lib_buf+200
  call	str_move
  jmp	short gt_30  
;is file in local directory
gt_20:
  call	dir_current		;sets ebx=dir ptr (lib_buf)
  mov	esi,ebx
  mov	edi,lib_buf+200		;filename build area
  call	str_move
  mov	al,'/'
  stosb
  mov	esi,[gt_name_ptr]
  call	str_move
gt_30:
  mov	ebx,lib_buf+200
  mov	ecx,1			;check if executable
  call	file_access
  or	eax,eax
  jz	gt_file_ok		;jmp if access ok
;file not in local directory, check path
  mov	ebx,[enviro_ptrs]
  mov	ebp,[gt_name_ptr]
  call	env_exec
  jc	gt_fail			;jmp if file not found
;move path to remote file
  mov	esi,ebx
  mov	edi,LastTarget
  call	str_move
;  mov	al,'/'
;  stosb
;  mov	esi,[gt_name_ptr]
;  call	str_move
  jmp	short gt_exit1
;file found in local dir, move name
gt_file_ok:
  mov	esi,[gt_name_ptr]
  mov	edi,LastTarget
  call	str_move
  jmp	short gt_exit1
gt_fail:
  mov	eax,err1
gt_fail2:
  call	show_error
  mov	eax,-1
  jmp	short gt_exit
gt_exit1:
  xor	eax,eax
gt_exit:
  or	eax,eax
  pop	esi		;restore esi
  ret
  
;-----------
  [section .data]
gt_name_ptr: dd 0 ;ptr to input file name
  [section .text]  
;-------------------------------------------------------------
;parse filename if present, get pid of target
; eax=ptr to parameter
; esi=ptr to stack ptrs 
attach_setup:
  lodsd			;get next parameter
  call	get_target
  js	as_exit0	;exit if error
  mov	byte [parse_attach],1
;find pid of file at LastTarget
  mov	esi,LastTarget
  cmp	byte [esi],'/'
  jne	as_40		;jmp if not full path
  call	str_end
as_10:
  dec	esi
  cmp	byte [esi],'/'
  jne	as_10		;loop till prior '/' found
  inc	esi		;move to start of name
;setup to search /proc
as_40:
  push	esi
  mov	eax,temp_buf_size
  call	m_allocate	;allocate buffer to read files
  js	as_exit2
  mov	[temp_buf_ptr],eax
  mov	ebx,temp_buf_size
  pop	ecx		;get match string
  call	process_search	;find process
  jz	as_exit0	;jmp if not found
  js	as_exit0	;jmp if not found
;search for pid
  mov	esi,eax		;get buf ptr
  mov	ecx,100		;max serach length
as_50:
  inc	esi
  cmp	[esi],dword 'Pid:'
  je	as_60		;jmp if "Pid:" found
  loop	as_50		;keep looking
  jmp	short as_exit0	;error exit
;we have found string "Pid:"
as_60:
  add	esi,5		;move past "Pid:"
  call	ascii_to_dword
  mov	[attach_pid],ecx
  xor	eax,eax
  jmp	short as_exit1 
as_exit0:
  mov	eax,-1
as_exit1:
  push	eax
  mov	eax,[temp_buf_ptr]
  call	m_release
  pop	eax
as_exit2:
  ret  
;-------------------------------------------------------------
;no parameters found, verify we have a filename in history data 
; eax=ptr to parameter
; esi=ptr to stack ptrs 
check_history:
  cmp	byte [LastTarget],0
  jne	ch_exit
  mov	eax,err2
  call	show_error
  mov	eax,-1
ch_exit:
  ret
;-----------------------
  [section .data]

our_name	dd 0	;ponter to our name
temp_buf_size	equ 10000
temp_buf_ptr:	dd 0
parse_attach:	db 0	;set to 1 if this is attach
attach_pid:	dd 0

asmbug_doc: db '/usr/share/doc/asmref/asmbug.txt',0


err1: db 'File not found',0ah,0
err2: db 'no active debug file',0ah,0
  [section .text]






