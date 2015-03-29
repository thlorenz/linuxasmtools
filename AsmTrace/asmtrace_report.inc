;---------------- asmtrace_report.inc ------------------------

  extern dis_one
  extern lib_buf
  extern dword_to_l_ascii
  extern dword_to_hexascii
  extern wordto_hexascii
  extern trace_peek_bytes
  extern trace_peek
;-----------------------------------------------------------------------
; calling dis_one returns the following struc at [eax]
;
struc dis_block	 ;block of data returned to caller 
.warn_flag resb 1 ;bit 01h = warning, nasm can not generate this opcode
		 ;bit 02h = warning seg override found?
                 ;bit 04h = warinng seg register operation found
		 ;bit 08h = warning unusual instruction, retn, push ax,
		 ;bit 10h =
		 ;bit 20h =
		 ;bit 40h =

.error_flag resb 1 ;bit  01h = illegal instruction                C P
		  ;bit  02h = instruction size wrong
		  ;bit  04h = unknown program state      
                  ;bit  08h = unexpected prefix

.instruction_type resb 1 ;bit 00h - normal instruction
                        ;bit 01h - floating point
                        ;bit 02h - conditional jmp
                        ;bit 04h - proteced mode (system) instruction
			;bit 08h - non-conditonal jmp (ret,call,jmp)
                        ;bit 10h -

.operand_type	resb 1  ;bit 01h - jmp adr at operand
                        ;bit 02h - call adr at operand
                        ;bit 04h - read/write byte adr at operand
                        ;bit 08h - read/write word adr at operand
                        ;bit 10h - read/write dword adr at operand
                        ;bit 20h - probable adr in immediate (const) data

.operand 	resd 1  ;address (physical) for jmp,read,write, or operand if actions=0
.inst_length	resd 1	;length of instruction                     S

;
; prefix flags
;
.state_flag:	resb 1 ;0= instruction decoded,return  info.      C P
			  ;40=escape prefix found, continue
			  ;20=seg prefix found, continue
			  ;10=66h opsize found, continue
                          ;08=67h address  size, continue
                          ;04=f2h  repne prefix found
                          ;02=f3h rep prefix found

;the prefix flag is set by non-prefix opcodes and signals
;the end of decode.  It contains legal prefix's for this opcode.

.prefix_flag: resb 1       ;80=found non-prefix opcode, decode done   C P
			  ;40=escape prefix legal for opcode
			  ;20=xx seg prefix legal for opcode
			  ;10=66h opsize prefix legal for opcode
                          ;08=67h address prefix legal for opcode
                          ;04=f3h rep legal for this opcode
                          ;02=f2h  repne legal for this opcode

.inst_end resd   1   ;ptr end of data in instruction_asciiz               S
.inst     resb 140  ;ascii instruction build area                        SP
endstruc
;------------------------------------------------------------------
;write line to ouptput file
; input: ebp = table ptr
report:
  mov	edi,lib_buf		;build buffer
  mov	eax,[ebp+pids.pid_status] ;get process status
  and	al,0c0h			;isolate signal & report bits
  cmp	al,40h			;back of function + report?
  je	do_report		;jmp if report
  cmp	al,0c0h			;signal + report
  je	report_signal		;jmp if signal report needed
  jmp	dr_exit			;exit if not signal report  

report_signal:
;signal report here
  push	edi
  push	esi
  mov	edi,sig_stuff
  mov	ecx,[ebp+pids.pid]	;get process
;  mov	esi,8		;store 2 digets
  call	dword_to_hexascii
  pop	esi
  pop	edi

  mov	esi,sig_msg
  call	str_move
  xor	ecx,ecx
  mov	cl,[ebp+pids.wait_status+1]
  shl	ecx,3		;make quad dword index
  mov	eax,[SIGHUP_msg -8 + ecx]
  stosd			;store signal
  mov	eax,[SIGHUP_msg -4 + ecx]
  stosd
  jmp	dr_60		;go write it
;----
;report control flags are:
;    parse_show_process: db 0 ;
;    parse_show_adr:	  db 0 ;0=no adr
;    parse_show_seq:	  db 1 ;
;    parse_show_fun:     db 1
;    parse_show_regs:  db 0
;    parse_show_extra:  db 0
;    parse_show_disasm: db 0

do_report:
  test	[ebp+pids.pid_status],byte 1
  jz	dr_40			;jmp if not new process
  call	report_new_process	;report new process startup
  jmp	dr_exit

dr_40:
  test	[ebp+pids.pid_status],byte 8	;process died?
  jz	dr_50				;jmp if process alive
  call	report_kernel_function		;report exit function

  mov	ecx,lib_buf	;setup to write disk
  mov	edx,edi
  sub	edx,ecx		;compute length
; input: ecx=buffer
;        edx=length of write
; output: eax=write count or error
;         flags set for js(error)
  call	outfile_write	;write function trace
  call	report_death	;write death report
  jmp	dr_exit
;this process is alive and needs function trace
dr_50:
  call	report_kernel_function
;write buffer
dr_60:
  mov	al,0ah
  stosb

  mov	ecx,lib_buf
  mov	edx,edi
  sub	edx,ecx		;compute length
; input: ecx=buffer
;        edx=length of write
; output: eax=write count or error
;         flags set for js(error)
  call	outfile_write

dr_exit:
  and	[ebp+pids.pid_status],byte ~041h	;clear status
  ret
;--------------
  [section .data]
sig_msg: db '-- signal recieved for process '
sig_stuff: db 'xxxxxxxxh = ',0
  [section .text]
;---------------------------------------------------
;input:  ebp = pid table
;        esi = control table ptr
;        edi = lib_buf pointer
report_kernel_function:
;show function name,get function number from eax if disasm
;                   get function number from old_eax if function trace
  cmp	[parse_show_disasm],byte 0
  je	rkf_20		;jmp if disasm off
  mov	esi,[ebp+pids.r_sav_old_eax] ;get function#
  jmp	short rkf_30
rkf_20:
  mov	esi,[ebp+pids.r_old_eax] ;get function#
  or	esi,esi
  jns	rkf_30
;assume this is a signal return, set rt_sigreturn as function
  mov	esi,173
;lookup function table
rkf_30:
  cmp	esi,11			;is this a execve?
  jne	rkf_36			;jmp if not execve
  xor	[execve_toggle],al
  jz	rkf_36			;exit if second execve
  jmp	rkf_90
rkf_36:
  shl	esi,2			;dword index
  add	esi,decode_index	;lookup function table
  mov	esi,[esi]		;get pointer to ctrl entry
  call	str_move		;move name to out buffer
  mov	al,' '
  stosb			;store space
;get return code
  mov	eax,[ebp+pids.r_old_eax] ;get function#
  cmp	[parse_show_disasm],byte 0
  je	rkf_40			;jmp if function trace
  mov	eax,[ebp+pids.r_sav_old_eax] ;get disasm function#
;check if this is exit function
rkf_40:
  cmp	eax,byte 1	 ;is this exit function
  je	rkf_50		;jmp if exit function
  mov	eax,'RTN='
  stosd			;store "rtn="
  mov	ecx,[ebp+pids.r_eax] ;get return code
  push	esi
  mov	esi,8		;store 2 digets
  call	dword_to_hexascii
  pop	esi
  mov	al,'h'
  stosb
  mov	al,' '
  stosb
rkf_50:
;add process number if enabled
  cmp	[parse_show_process],byte 0	;process# wanted?
  je	rkf_60			;jmp if no process
;-- add process#
  mov	eax,'PID='	;PID=
  stosd			;put PID= in buffer
  mov	ecx,[ebp+pids.pid]	;get process
  push	esi
  mov	esi,8		;store 8 digets
  call	dword_to_hexascii ;process# to hex ascii
  pop	esi
  mov	al,'H'
  stosb
  mov	al,' '
  stosb
;add sequence# if enabled
rkf_60:
  cmp	[parse_show_seq],byte 0	;sequence# wanted?
  je	rkf_70			;jmp if no sequence#
;--add sequence#
  mov	eax,'SEQ='
  stosd
  mov	ecx,[sequence]
  push	esi
  mov	esi,8		;store 8 digets
  call	dword_to_hexascii
  pop	esi
  mov	al,'H'
  stosb
  mov	al,' '
  stosb
;add address if enable
rkf_70:
  cmp	[parse_show_adr],byte 0	;address wanted?
  je	rkf_80			;jmp if no address wanted
;-- add adr
  mov	eax,'ADR='
  stosd
  mov	ecx,[ebp+pids.r_eip]
  push	esi
  mov	esi,8		;store 8 digets
  call	dword_to_hexascii
  pop	esi
  mov	al,'H'
  stosb
  mov	al,' '
  stosb

rkf_80:
  cmp	[parse_show_regs],byte 0
  je	rkf_90			;jmp if show regs disabled
  mov	al,0ah
  stosb
  lodsd				;get process
  call	eax			;call processing for function
rkf_90:
  ret
;-------
  [section .data]
execve_toggle: db 0
  [section .text]
;-----------------------------------------------------------------
report_new_process:
  mov	ecx,[ebp+pids.pid]	;get process id
  mov	edi,start_pid
  mov	esi,8		;store 2 digets
  call	dword_to_hexascii

  mov	ecx,start_msg
  mov	edx,start_msg_len
  call	outfile_write
rnp_exit:
  ret

;-----------------------------------------------------------------
report_death:
  mov	ecx,[ebp+pids.pid]	;get process id
  mov	edi,dead_mpid
  call	dword_to_hexascii

  mov	ecx,dead_msg
  mov	edx,dead_msg_len
  call	outfile_write
rd_exit:
  ret
;---------------
  [section .data]
dead_msg           db '-- process '
dead_mpid	   db '00000000h died',0ah
dead_msg_len       equ  $ - dead_msg
start_msg          db '-- process# '
start_pid	   db '00000000h is starting',0ah
start_msg_len      equ  $ - start_msg
  [section .text]
;------------------------------------------------------------------
add_sequence:
  cmp	[parse_show_seq],byte 0
  jz	as_exit		;exit if not wanted
  mov	eax,[sequence]
;al=level, convert to ascii
  push	edi
  mov	edi,as_stuff
  mov	esi,5		;store 2 digets
  push	ebp
  call	dword_to_l_ascii
  pop	ebp
  mov	esi,sequence_txt
  pop	edi
  call	str_move
as_exit:
  ret
;-------
  [section .data]
sequence: dd 0		;sequence number
sequence_txt:
  db '#'
as_stuff:
  db '00000 ',0
  [section .text]
;------------------------------------------------------------------
;decode table equates are:
;zero	equ	0	;end of string
;_bx	equ	1	;start of ebx def
;_cx	equ	2	;start of ecx def
;_dx	equ	3	;start of edx def
;_si	equ	4	;start of edi def
;_di	equ	5	;start of esi def
;_bp	equ	6	;start of ebp def
;_txt	equ	7	;name of value follows as asciiz
;_buf1	equ	8	;last reg is ptr, reg edx has length (dumps hex bytes)
;_struc_byte  equ	9	;last reg is ptr,  db 'asciiz text'... ends with 0
;_struc_word  equ	10	;last reg is ptr,  db 'asciiz text'... ends with 0
;_struc_dword  equ	11	;last reg is ptr,  db 'asciiz text'... ends with 0
;_eol	equ	12	;insert eol
;
;_end	equ	-1	;end of definition
;
;-------------------------------------------------------------------
; processing functions from decode table
;-------------------------------------------------------------------
; inputs:  esi=ptr to control table
;          edi=output stuff ptr
; output: edi points to end of data (0ah is added by caller)
;
p_generic:
;  mov	al,0ah
;  stosb
p_loop:
  xor	eax,eax
  lodsb		;get control code
  cmp	al,-1
  je	p_generic_exit
  shl	eax,2	;convert to dword index
  add	eax,reg_code_table
  call	[eax]
  jmp	short p_loop
p_generic_exit:
  ret
;--------------
  [section .data]
reg_code_table:
  dd	p_generic_exit	;0 (error)
  dd	p_ebx		;1 ebx
  dd	p_ecx		;2
  dd	p_edx		;3
  dd	p_esi		;4
  dd	p_edi		;5
  dd	p_ebp		;6
  dd	p_text		;7
  dd	p_buf1		;8
  dd	p_struc_byte	;9
  dd	p_struc_word	;10
  dd	p_struc_dword	;11
  dd	p_eol		;12
  dd	p_buf2		;13
  dd	p_scan		;14
  dd    p_ptr		;15

  [section .text]
;------------

; inputs: esi=control table
;         edi=output bufrer
;         ebp=pid table ptr
;output:
;         esi,edi updated
;         [last_make_hex] = last reg value
p_ebx:
  mov	al,' '
  stosb
  mov	eax,'ebx='
  stosd
  mov	ecx,[ebp+pids.r_ebx]
  call	make_hex
  ret
p_ecx:
  mov	al,' '
  stosb
  mov	eax,'ecx='
  stosd
  mov	ecx,[ebp+pids.r_ecx]
  call	make_hex
  ret
p_edx:
  mov	al,' '
  stosb
  mov	eax,'edx='
  stosd
  mov	ecx,[ebp+pids.r_edx]
  call	make_hex
  ret
p_esi:
  mov	al,' '
  stosb
  mov	eax,'esi='
  stosd
  mov	ecx,[ebp+pids.r_esi]
  call	make_hex
  ret
p_edi:
  mov	al,' '
  stosb
  mov	eax,'edi='
  stosd
  mov	ecx,[ebp+pids.r_edi]
  call	make_hex
  ret
p_ebp:
  mov	al,' '
  stosb
  mov	eax,'ebp='
  stosd
  mov	ecx,[ebp+pids.r_ebp]
  call	make_hex
  ret
; inputs: esi=control table
;         edi=output bufrer
;         ebp=pid table ptr
;         [last_make_hex] = last reg value
p_text:
  lodsb
  stosb
  cmp	al,0
  jne	p_text
  dec	edi
  mov	al,' '
  stosb
  ret
;
; inputs: esi=control table
;         edi=output bufrer
;         ebp=pid table ptr
;         [last_make_hex] = last reg value (app address)
;         [ebp+pids.r_edx] = lenght of dump
p_buf1:
  mov	eax,[ebp+pids.r_edx] ;length
  or	eax,eax
  jz	p_buf1_exit
  cmp	eax,byte 0fh
  jbe	p_buf10
  mov	al,0fh	
p_buf10:
  movzx	ecx,al	;move length
  push	esi
  mov	esi,[last_make_hex]
  call	buffer_hex_line
  pop	esi
p_buf1_exit:
  ret

; inputs: esi=control table
;         edi=output bufrer
;         ebp=pid table ptr
;         [last_make_hex] = last reg value
p_struc_byte:
  mov	ebx,[last_make_hex]	;assume this is ptr
  or	ebx,ebx
  jz	p_struc_byte_done
  call	get_app_data	;mov	al,[ebx]
  inc	dword [last_make_hex]
  call	byteto_hexascii
p_struc_byte_done:
  ret

; inputs: esi=control table
;         edi=output bufrer
;         ebp=pid table ptr
;         [last_make_hex] = last reg value
p_struc_word:
  mov	ebx,[last_make_hex]	;assume this is ptr
  or	ebx,ebx
  jz	p_struc_word_done
  call	get_app_data	;mov	al,[ebx]
  add	dword [last_make_hex],2
  call	wordto_hexascii
p_struc_word_done:
  ret

; inputs: esi=control table
;         edi=output bufrer
;         ebp=pid table ptr
;         [last_make_hex] = last reg value
p_struc_dword:
  mov	ebx,[last_make_hex]	;assume this is ptr
  or	ebx,ebx
  jz	p_struc_dword_done
  call	get_app_data	;mov	al,[ebx]
  add	dword [last_make_hex],4
  call	dwordto_hexascii
p_struc_dword_done:
  ret

p_eol:
  mov	al,0ah
  stosb
  ret

;
; inputs: esi=control table
;         edi=output bufrer
;         ebp=pid table ptr
;         [last_make_hex] = last reg value (ptr to app data)
p_buf2:
  push	esi
  mov	esi,[last_make_hex]
  call	buffer_ahex_line ; esi=in ptr  edi=stuff ptr
;scan to end of test string at [last_make_hex]
  mov	edx,[last_make_hex]
  call	scan_to_zero
  mov	[last_make_hex],edx	;save end of text string ptr
p_buf2_exit:
  pop	esi
  ret

;
; inputs: esi=control table
;         edi=output bufrer
;         ebp=pid table ptr
;         [last_make_hex] = last reg value (ptr to app data)
;scan to start of next text string
p_scan:
  push	esi
  mov	edx,[last_make_hex]
  call	scan_to_nonzero
  mov	[last_make_hex],edx
  pop	esi
  ret
;-------------------------------
; edx = address to scan
scan_to_zero:
  push	esi
  push	edi
  push	ebp
stz_lp:
  mov	esi,app_data
  push	edx		;save app address
  call	trace_peek	;read app data
  pop	edx		;restore app address
  or	eax,eax
  js	stz_exit	;exit if app address bad
  mov	al,[app_data]
  cmp	al, 0ah ;end of app string?
  jb	stz_exit	;exit if non-ascii
  cmp	al,80h
  ja	stz_exit	;exit if non-ascii
  inc	edx
  jmp	short stz_lp
stz_exit:
  pop	ebp
  pop	edi
  pop	esi
  ret

;-------------------------------
scan_to_nonzero:
  pusha
  mov	esi,app_data
  call	trace_peek
  popa
  cmp	[app_data],byte 0
  jne	stn_exit
  inc	edx
  jmp	short scan_to_nonzero
stn_exit:
  ret

p_ptr:
  pusha
  mov	edx,[last_make_hex]
  mov	esi,app_data
  call	trace_peek
  popa
  mov	ecx,[app_data]
  jecxz	p_ptr_exit
  call	make_hex
p_ptr_exit:
  ret

;-------------------------------
;get_app_data:
; ebx=address
get_app_data:
  pusha
  mov	edx,ebx
  mov	esi,app_data
  call	trace_peek
  popa
  mov	eax,[app_data]
  ret

;--------------
  [section .data]
app_data: dd 0
  [section .text]
;------------------------------
input: 
make_hex:
  mov	[last_make_hex],ecx
  call	dword_to_hexascii
  mov	al,'h'
  stosb
  mov	al,' '
  stosb
  ret
;--------------
  [section .data]
last_make_hex: dd 0
  [section .text]

;--------------------------------------------------------------------------------
; inputs:  esi=ptr to control table
;          edi=output stuff ptr
; output: edi points to end of data (0ah is added by caller)

p_socket:
  call	p_ebx
  mov	esi,[ebp+pids.r_ebx]
  cmp	esi,byte 17h
  ja	p_socket_exit	;exit if error
;add text for sub opcode
  or	esi,esi
  jz	p_socket_exit
  dec	esi		;make zero based
  shl	esi,2		;convert to dword index
  push	esi
  add	esi,socket_op_txt
  mov	esi,[esi]	;get ptr to text
  call	str_move
  mov	al,0ah
  stosb
;process sub opcode
  pop	eax		;get sub opcode*4  
  add	eax,socket_op_p
  mov	esi,[eax]
  call	p_generic
p_socket_exit:
  ret

;-------------
  [section .data]
socket_op_txt:
 dd sys_socket_txt	;1
 dd sys_bind_txt	;2
 dd sys_connect_txt	;3
 dd sys_listen_txt	;4
 dd sys_accept_txt	;5
 dd sys_getsockname_txt ;6
 dd sys_getpeername_txt	;7
 dd sys_socketpair_txt	;8
 dd sys_send_txt	;9
 dd sys_sendto_txt	;10
 dd sys_recv_txt	;11
 dd sys_recvfrom_txt	;12
 dd sys_shutdown_txt	;13
 dd sys_setsockopt_txt	;14
 dd sys_getsockopt_txt	;15
 dd sys_sendmsg_txt	;16
 dd sys_recvmsg_txt	;17

socket_op_p:
 dd sys_socket_p
 dd sys_bind_p
 dd sys_connect_p
 dd sys_listen_p
 dd sys_accept_p	;5
 dd sys_getsockname_p ;6
 dd sys_getpeername_p	;7
 dd sys_socketpair_p	;8
 dd sys_send_p	;9
 dd sys_sendto_p	;10
 dd sys_recv_p	;11
 dd sys_recvfrom_p	;12
 dd sys_shutdown_p	;13
 dd sys_setsockopt_p	;14
 dd sys_getsockopt_p	;15
 dd sys_sendmsg_p	;16
 dd sys_recvmsg_p	;17

sys_socket_txt		db 'sys_socket (create socket)',0
sys_bind_txt	db 'sys_bind (bind name)',0
sys_connect_txt	db 'sys_connect (connect to socket)',0
sys_listen_txt	db 'sys_listen (listen for connection)',0
sys_accept_txt	db 'sys_accept (accept connection)',0 ;5
sys_getsockname_txt db 'sys_getsockname',0 ;6
sys_getpeername_txt	db 'sys_getpeername',0 ;7
sys_socketpair_txt	db 'sys_socketpair',0 ;8
sys_send_txt	db 'sys_send',0 ;9
sys_sendto_txt	db 'sys_sendto',0 ;10
sys_recv_txt	db 'sys_recv',0 ;11
sys_recvfrom_txt	db 'sys_recvfrom',0 ;12
sys_shutdown_txt	db 'sys_shutdown',0 ;13
sys_setsockopt_txt	db 'sys_setsockopt',0 ;14
sys_getsockopt_txt	db 'sys_getsockopt',0 ;15
sys_sendmsg_txt	db 'sys_sendmsg',0 ;16
sys_recvmsg_txt	db 'sys_recvmsg',0 ;17

;-------------------------------------

sys_socket_p:
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   family=',0,_struc_dword,_eol
 db _txt,'   flags=',0,_struc_dword,_eol
 db _txt,'   protocol=',0,_struc_dword,_eol
 db _end

sys_bind_p:
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   ptr to bind struc=',0,_struc_dword,_eol
 db _end

sys_connect_p:
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   adr=',0,_struc_dword,_eol
 db _txt,'   size=',0,_struc_dword,_eol
 db _end

sys_listen_p:
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   queue length=',0,_struc_dword,_eol
 db _end

sys_accept_p:	;5
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   adr ptr=',0,_struc_dword,_eol
 db _txt,'   ??? ptr=',0,_struc_dword,_eol
 db _end

sys_getsockname_p: ;6
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _txt,'   buf size=',0,_struc_dword,_eol
 db _end

sys_getpeername_p:	;7
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _txt,'   buf size=',0,_struc_dword,_eol
 db _end

sys_socketpair_p:	;8
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   domain=',0,_struc_dword,_eol
 db _txt,'   flags=',0,_struc_dword,_eol
 db _txt,'   protocol=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _end

sys_send_p:	;9
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _txt,'   buf size=',0,_struc_dword,_eol
 db _txt,'   flags=',0,_struc_dword,_eol
 db _end

sys_sendto_p:	;10
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _txt,'   buf size=',0,_struc_dword,_eol
 db _txt,'   flags=',0,_struc_dword,_eol
 db _txt,'   addr struc ptr=',0,_struc_dword,_eol
 db _txt,'   addr struc size=',0,_struc_dword,_eol
 db _end

sys_recv_p:	;11
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _txt,'   buf size=',0,_struc_dword,_eol
 db _txt,'   flags=',0,_struc_dword,_eol
 db _end

sys_recvfrom_p:	;12
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _txt,'   buf size=',0,_struc_dword,_eol
 db _txt,'   flags=',0,_struc_dword,_eol
 db _txt,'   addr struc ptr=',0,_struc_dword,_eol
 db _txt,'   addr struc size=',0,_struc_dword,_eol
 db _end

sys_shutdown_p:	;13
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   cmd=',0,_struc_dword,_eol
 db _end

sys_setsockopt_p:	;14
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   protocol=',0,_struc_dword,_eol
 db _txt,'   option=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _txt,'   buf size=',0,_struc_dword,_eol
 db _end

sys_getsockopt_p:	;15
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   level=',0,_struc_dword,_eol
 db _txt,'   option=',0,_struc_dword,_eol
 db _txt,'   buf ptr=',0,_struc_dword,_eol
 db _txt,'   buf size=',0,_struc_dword,_eol
 db _end

sys_sendmsg_p:	;16
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   msg header ptr=',0,_struc_dword,_eol
 db _txt,'   flags=',0,_struc_dword,_eol
 db _end

sys_recvmsg_p:	;17
 db _cx,_txt,'socket struc ->',0,_eol
 db _txt,'   fd=',0,_struc_dword,_eol
 db _txt,'   msg header ptr=',0,_struc_dword,_eol
 db _txt,'   flags=',0,_struc_dword,_eol
 db _end
;--------------------------------------------------------------------------------
; inputs:  esi=ptr to control table
;          edi=output stuff ptr
; output: edi points to end of data (0ah is added by caller)

p_ipc:
  call	p_ebx
  mov	esi,[ebp+pids.r_ebx]
  cmp	esi,byte 18h
  ja	p_ipc_exit	;exit if error
;add text for sub opcode
  shl	esi,2		;convert to dword index
  push	esi
  add	esi,ipc_op_txt-4
  mov	esi,[esi]	;get ptr to text
  call	str_move
  mov	al,0ah
  stosb
;process sub opcode
  pop	eax		;get sub opcode*4  
  add	eax,ipc_op_p-4
  mov	esi,[eax]
  call	p_generic
p_ipc_exit:
  ret

;-------------
  [section .data]
ipc_op_txt:
 dd sys_SEMOP_txt ;		 1 - semaphore operation
 dd sys_SEMGET_txt ;		 2 - semaphore get
 dd sys_SEMCTL_txt ;		 3 - semaphore control
 dd sys_SEMTIMEDOP_txt ;	 4 - semaphore operation mod
 dd ipc_dummy		;	 5
 dd ipc_dummy		;	 6
 dd ipc_dummy		;	 7
 dd ipc_dummy		;	 8
 dd ipc_dummy		;	 9
 dd ipc_dummy		;	10
 dd sys_MSGSND_txt ;		11 - messages
 dd sys_MSGRCV_txt ;		12 - message recieve
 dd sys_MSGGET_txt ;		13 - message get
 dd sys_MSGCTL_txt ;		14 - message control
 dd ipc_dummy		;	15
 dd ipc_dummy		;	16
 dd ipc_dummy		;	17
 dd ipc_dummy		;	18
 dd ipc_dummy		;	19
 dd ipc_dummy		;	20
 dd sys_SHMAT_txt ;		21 - shared memory attach
 dd sys_SHMDT_txt ;		22 - shared memory detatch
 dd sys_SHMGET_txt ;		23 - shared memory get
 dd sys_SHMCTL_txt ;		24 - shared memory control

ipc_op_p:
 dd sys_SEMOP_p ;		 1 - semaphore operation
 dd sys_SEMGET_p ;		 2 - semaphore get
 dd sys_SEMCTL_p ;		 3 - semaphore control
 dd sys_SEMTIMEDOP_p ;	 4 - semaphore operation mod
 dd ipc_dummyp		;	 5
 dd ipc_dummyp		;	 6
 dd ipc_dummyp		;	 7
 dd ipc_dummyp		;	 8
 dd ipc_dummyp		;	 9
 dd ipc_dummyp		;	10
 dd sys_MSGSND_p ;		11 - messages
 dd sys_MSGRCV_p ;		12 - message recieve
 dd sys_MSGGET_p ;		13 - message get
 dd sys_MSGCTL_p ;		14 - message control
 dd ipc_dummyp		;	15
 dd ipc_dummyp		;	16
 dd ipc_dummyp		;	17
 dd ipc_dummyp		;	18
 dd ipc_dummyp		;	19
 dd ipc_dummyp		;	20
 dd sys_SHMAT_p ;		21 - shared memory attach
 dd sys_SHMDT_p ;		22 - shared memory detatch
 dd sys_SHMGET_p ;		23 - shared memory get
 dd sys_SHMCTL_p ;		24 - shared memory control

ipc_dummy db 'ipc_dummy',0
sys_SEMOP_txt	db 'sys_SEMOP (semaphore operation)',0
sys_SEMGET_txt	db 'sys_SEMGET (semaphore get)',0
sys_SEMCTL_txt	db 'sys_SEMCTL (semaphore control)',0
sys_SEMTIMEDOP_txt db 'sys_SEMTIMEDOP (semaphore operation mod)',0
sys_MSGSND_txt	db 'sys_MSGSND (message send)',0
sys_MSGRCV_txt	db 'sys_MSGRCV (message recieve)',0
sys_MSGGET_txt	db 'sys_MSGGET (message get)',0
sys_MSGCTL_txt	db 'sys_MSGCTL (message control)',0
sys_SHMAT_txt	db 'sys_SHMAT (shared memory attach)',0
sys_SHMDT_txt	db 'sys_SHMDT (shared memory detatch)',0
sys_SHMGET_txt	db 'sys_SHMGET (shared memory get)',0
sys_SHMCTL_txt	db 'sys_SHMCTL (shared memory control)',0

ipc_dummyp:
 db _end

sys_SEMOP_p: ;		 1 - semaphore operation
 db _cx,_txt,'   semaphore id',0,_eol
 db _dx,_txt,'   array ptr',0,_eol
 db _si,_txt,'   number of operations',0,_eol
 db _end

sys_SEMGET_p: ;		 2 - semaphore get
 db _cx,_txt,'   key value',0,_eol
 db _dx,_txt,'   sempahore number',0,_eol
 db _si,_txt,'   op flags',0,_eol
 db _end

sys_SEMCTL_p: ;		 3 - semaphore control
 db _cx,_txt,'   semaphore id',0,_eol
 db _dx,_txt,'   index',0,_eol
 db _si,_txt,'   operation',0,_eol
 db _di,_txt,'   ptr to integer',0,_eol
 db _end

sys_SEMTIMEDOP_p: ;	 4 - semaphore operation mod
 db _cx,_txt,'   semaphore id',0,_eol
 db _dx,_txt,'   ptr to array',0,_eol
 db _si,_txt,'   number of operations',0,_eol
 db _end

sys_MSGSND_p: ;		11 - messages
 db _cx,_txt,'   msqid (message queue id)',0,_eol
 db _dx,_txt,'   max size',0,_eol
 db _si,_txt,'   opflags',0,_eol
 db _di,_txt,'   ptr to msg',0,_eol
 db _end


sys_MSGRCV_p: ;		12 - message recieve
 db _cx,_txt,'   msqid (message queue id)',0,_eol
 db _dx,_txt,'   max size',0,_eol
 db _si,_txt,'   type of msg',0,_eol
 db _di,_txt,'   ipc_kludge',0,_eol
 db _end

sys_MSGGET_p: ;		13 - message get
 db _cx,_txt,'   key value',0,_eol
 db _dx,_txt,'   flags',0,_eol
 db _end

sys_MSGCTL_p: ;		14 - message control
 db _cx,_txt,'   msqid (message queue id)',0,_eol
 db _dx,_txt,'   cmd',0,_eol
 db _si,_txt,'   parameter',0,_eol
 db _end

sys_SHMAT_p: ;		21 - shared memory attach
 db _cx,_txt,'   shmid (from SHMGET)',0,_eol
 db _dx,_txt,'   address',0,_eol
 db _si,_txt,'   flag',0,_eol
 db _end

sys_SHMDT_p: ;		22 - shared memory detatch
 db _cx,_txt,'   address',0,_eol
 db _end

sys_SHMGET_p: ;		23 - shared memory get
 db _cx,_txt,'   key',0,_eol
 db _dx,_txt,'   size',0,_eol
 db _si,_txt,'   flags',0,_eol
 db _end

sys_SHMCTL_p: ;		24 - shared memory control
 db _cx,_txt,'   shmid (from SHMGET)',0,_eol
 db _dx,_txt,'   code (cmd to perform)',0,_eol
 db _si,_txt,'   ptr to buffer',0,_eol
 db _end

;-------------------------------------


  [section .text]
;--------------------------------------------------------------------------------
; inputs:  esi=ptr to control table
;          edi=output stuff ptr
; output: edi points to end of data (0ah is added by caller)

p_fcntl:
  call	p_ebx		;fd
  mov	esi,fcntl_msg1
;append text for "fd"
p_fcntl_mv:
  lodsb
  stosb
  cmp	al,0
  jne	p_fcntl_mv
  dec	edi
;show command reg (ecx)
  call	p_ecx
  mov	esi,[ebp+pids.r_ecx]
  cmp	esi,byte 7h
  ja	p_fcntl_exit	;exit if error
;add text for sub opcode
  shl	esi,2		;convert to dword index
  push	esi
  add	esi,fcntl_op_txt
  mov	esi,[esi]	;get ptr to text
  call	str_move
  mov	al,0ah
  stosb
;process sub opcode
  pop	eax		;get sub opcode*4  
  add	eax,fcntl_op_p
  mov	esi,[eax]
  call	p_generic
p_fcntl_exit:
  ret

;---------------------
  [section .data]
fcntl_msg1: db ' fd',0ah,0

fcntl_op_txt:
 dd	fdupfd
 dd	fgetfd
 dd	fsetfd
 dd	fgetfl
 dd	fsetfl
 dd	fgetlk
 dd	fsetlk
 dd	fsetlkw  ;7

fdupfd	db ' F_DUPFD (0) Duplicate file descriptor',0
fgetfd	db ' F_GETFD (1) Get file descriptor flags',0
fsetfd	db ' F_SETFD (2) Set file descriptor flags',0
fgetfl	db ' F_GETFL (3) Get file status flags',0
fsetfl	db ' F_SETFL (4) Set file status flags',0
fgetlk	db ' F_GETLK (5) Get record locking info',0
fsetlk	db ' F_SETLK (6) Set record locking info (non-blocking)',0
fsetlkw db ' F_SETLKW (7) Set record locking info (blocking)',0

fcntl_op_p:
 dd	p_fdupfd
 dd	p_fgetfd
 dd	p_fsetfd
 dd	p_fgetfl
 dd	p_fsetfl
 dd	p_fgetlk
 dd	p_fsetlk
 dd	p_fsetlkw  ;7


p_fdupfd:
 db _dx,_txt,' duplicate fd',0,_eol
 db _end

p_fgetfd:
 db _dx,_txt,' fd',0,_eol
 db _end

p_fsetfd:
 db _dx,_txt,' fd',0,_eol
 db _end

p_fgetfl:
 db _dx,_txt,' status',0,_eol
 db _end

p_fsetfl:
 db _dx,_txt,' status',0,_eol
 db _end

p_fgetlk:
 db _dx,_txt,' locking info',0,_eol
 db _end

p_fsetlk:
 db _dx,_txt,' locking info',0,_eol
 db _end

p_fsetlkw:  ;7
 db _dx,_txt,'  record locking info',0,_eol
 db _end

;--------------------------------------------------------------------------------
; inputs:  esi=ptr to control table
;          edi=output stuff ptr
; output: edi points to end of data (0ah is added by caller)

p_key:
  call	p_ebx
  mov	esi,[ebp+pids.r_ebx]
  cmp	esi,byte 18h
  ja	p_key_exit	;exit if error
;add text for sub opcode
  shl	esi,2		;convert to dword index
  push	esi
  add	esi,key_op_txt
  mov	esi,[esi]	;get ptr to text
  call	str_move
  mov	al,0ah
  stosb
;process sub opcode
  pop	eax		;get sub opcode*4  
  add	eax,key_op_p
  mov	esi,[eax]
  call	p_generic
p_key_exit:
  ret

;-------------
  [section .data]
key_op_txt:
  dd GET_KEYRING_ID_txt		;0  ask for a keyring's ID  
  dd JOIN_SESSION_KEYRING_txt	;1  join or start named session keyring  
  dd UPDATE_txt			;2  update a key  
  dd REVOKE_txt			;3  revoke a key  
  dd CHOWN_txt			;4  set ownership of a key  
  dd SETPERM_txt			;5  set perms on a key  
  dd DESCRIBE_txt			;6  describe a key  
  dd CLEAR_txt			;7  clear contents of a keyring  
  dd LINK_txt			;8  link a key into a keyring  
  dd UNLINK_txt			;9  unlink a key from a keyring  
  dd SEARCH_txt			;10  search for a key in a keyring  
  dd READ_txt			;11  read a key or keyring's contents  
  dd INSTANTIATE_txt		;12  instantiate a partially constructed key  
  dd NEGATE_txt			;13  negate a partially constructed key  
  dd SET_REQKEY_KEYRING_txt	;14  set default request-key keyring  
  dd SET_TIMEOUT_txt		;15  set key timeout  
  dd ASSUME_AUTHORITY_txt		;16  assume request_key() authorisation 


key_op_p:
  dd GET_KEYRING_ID_p		;0  ask for a keyring's ID  
  dd JOIN_SESSION_KEYRING_p	;1  join or start named session keyring  
  dd UPDATE_p			;2  update a key  
  dd REVOKE_p			;3  revoke a key  
  dd CHOWN_p			;4  set ownership of a key  
  dd SETPERM_p			;5  set perms on a key  
  dd DESCRIBE_p			;6  describe a key  
  dd CLEAR_p			;7  clear contents of a keyring  
  dd LINK_p			;8  link a key into a keyring  
  dd UNLINK_p			;9  unlink a key from a keyring  
  dd SEARCH_p			;10  search for a key in a keyring  
  dd READ_p			;11  read a key or keyring's contents  
  dd INSTANTIATE_p		;12  instantiate a partially constructed key  
  dd NEGATE_p			;13  negate a partially constructed key  
  dd SET_REQKEY_KEYRING_p	;14  set default request-key keyring  
  dd SET_TIMEOUT_p		;15  set key timeout  
  dd ASSUME_AUTHORITY_p		;16  assume request_key() authorisation 



GET_KEYRING_ID_txt	db ' ask for a keyring ID',0  
JOIN_SESSION_KEYRING_txt db ' join or start named session keyring',0  
UPDATE_txt		db ' update a key',0  
REVOKE_txt		db ' revoke a key',0  
CHOWN_txt		db ' set ownership',0
SETPERM_txt		db ' set perms on a key',0  
DESCRIBE_txt		db ' describe a key',0  
CLEAR_txt		db ' clear contents of a keyring',0  
LINK_txt		db ' link a key into a keyring',0  
UNLINK_txt		db ' unlink a key from a keyring',0  
SEARCH_txt		db ' search for a key in a keyring',0  
READ_txt		db ' read a key or keyrings contents',0  
INSTANTIATE_txt		db ' instantiate a partially constructed key',0  
NEGATE_txt		db ' negate a partially constructed key',0
SET_REQKEY_KEYRING_txt	db ' set default request-key keyring',0
SET_TIMEOUT_txt		db ' set key timeout',0
ASSUME_AUTHORITY_txt	db ' assume request_key() authorisation',0 



GET_KEYRING_ID_p: ;		0  ask for a keyring's ID  
 db _cx,_txt,' serial#',0,_eol
 db _dx,_txt,' create flag 0=no x=yes',0,_eol
 db _end

JOIN_SESSION_KEYRING_p: ;	1  join or start named session keyring  
 db _cx,_txt,' keyring name = ',0,_buf2,_eol
 db _end

UPDATE_p:	;			2  update a key  
 db _cx,_txt,' key serial#',0,_eol
 db _dx,_txt,' payload ptr',0,_eol
 db _si,_txt,' size of payload buf',0,_eol
 db _end

REVOKE_p:	;			3  revoke a key  
 db _cx,_txt,' key serial#',0,_eol
 db _end

CHOWN_p:	;			4  set ownership of a key  
 db _cx,_txt,' serial#',0,_eol
 db _dx,_txt,' UID',0,_eol
 db _si,_txt,' GID',0,_eol
 db _end

SETPERM_p:	;		5  set perms on a key  
 db _cx,_txt,' key serial#',0,_eol
 db _dx,_txt,' mask',0,_eol
 db _end

DESCRIBE_p:	;		6  describe a key  
 db _cx,_txt,' serial#',0,_eol
 db _dx,_txt,' buffer ptr ->',0,_eol
   db _txt,'  type ',0,_struc_dword,_eol
   db _txt,'  uid  ',0,_struc_dword,_eol
   db _txt,'  gid  ',0,_struc_dword,_eol
   db _txt,'  perm ',0,_struc_dword,_eol
   db _txt,'  desc ',0,_buf2,_eol
 db _si,_txt,' size of buffer',0,_eol
 db _end

CLEAR_p:	;			7  clear contents of a keyring  
 db _cx,_txt,' serial#',0,_eol
 db _end

LINK_p:	;			8  link a key into a keyring  
 db _cx,_txt,' key serial#',0,_eol
 db _dx,_txt,' keyring serial#',0,_eol
 db _end

UNLINK_p:	;			9  unlink a key from a keyring  
 db _cx,_txt,' key serial#',0,_eol
 db _dx,_txt,' keyring serial#',0,_eol
 db _end

SEARCH_p:	;			10  search for a key in a keyring  
 db _cx,_txt,' keyring serial#',0,_eol
 db _dx,_txt,' type string = ',0,_buf2,_eol
 db _si,_txt,' desc string = ',0,_buf2,_eol
 db _end

READ_p:	;			11  read a key or keyring's contents  
 db _cx,_txt,' key serial#',0,_eol
 db _dx,_txt,' payload ptr',0,_eol
 db _si,_txt,' size of payload buf',0,_eol
 db _end

INSTANTIATE_p:	;		12  instantiate a partially constructed key  
 db _cx,_txt,' serial#',0,_eol
 db _dx,_txt,' payload ptr',0,_eol
 db _si,_txt,' size of payload buf',0,_eol
 db _di,_txt,' keyring serial#',0,_eol
 db _end

NEGATE_p:	;			13  negate a partially constructed key  
 db _cx,_txt,' key serial#',0,_eol
 db _dx,_txt,' key lifetime in sec',0,_eol
 db _si,_txt,' keyring serial#',0,_eol
 db _end

SET_REQKEY_KEYRING_p:	;	14  set default request-key keyring  
 db _cx,_txt,' destination',0,_eol
 db _end

SET_TIMEOUT_p:	;		15  set key timeout  
 db _cx,_txt,' key serial#',0,_eol
 db _dx,_txt,' timeout in seconds',0,_eol
 db _end

ASSUME_AUTHORITY_p:	;	16  assume request_key() authorisation 
 db _cx,_txt,' key serial#',0,_eol
 db _end


;-------------------------------------



  [section .text]
