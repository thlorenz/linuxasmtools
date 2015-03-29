
%ifdef LOG
  [section .text]
;------------------------
; input: ebp = pointer to control structure (pids)
; output: data logged to file
logit:
extern log_regtxt
extern log_eol
extern fd_open_flg
extern file_write
  pusha
  mov	eax,'pid='
  call	log_regtxt
  mov	eax,[ebp+pids.pid]
  call	log_hex

  mov	eax,'ax1 '
  call	log_regtxt
  mov	eax,[ebp+pids.r_eax]
  call	log_hex

  mov	eax,'ax2 '
  call	log_regtxt
  mov	eax,[ebp+pids.r_old_eax]
  call	log_hex

  mov	eax,'eip='
  call	log_regtxt
  mov	eax,[ebp+pids.r_eip]
  cmp	[parse_show_disasm],byte 0
  je	logit5
  test	[report_flag],byte 1
  jz	logit5			;use eip if reporting off
  mov	eax,[ebp+pids.r_old_eip]
logit5:
  call	log_hex

  mov	eax,'stat'
  call	log_regtxt
  mov	eax,[ebp+pids.wait_status]
  pusha
  mov	edi,hex_number
  mov	ecx,eax			;hex in ecx
  call	dword_to_hexascii
  mov	ebx,[fd_open_flg]
  mov	edx,4			;write 10 bytes
  mov	ecx,hex_number_start+4	;data to write
  call	file_write
  popa

  mov	eax,' flg'
  call	log_regtxt
  mov	eax,[ebp+pids.pid_status]
  pusha
  mov	edi,hex_number
  mov	ecx,eax			;hex in ecx
  call	dword_to_hexascii
  mov	ebx,[fd_open_flg]
  mov	edx,2			;write 10 bytes
  mov	ecx,hex_number_start+6	;data to write
  call	file_write
  popa

  call	log_eol
  call	log_eol
  popa
  ret
;---------------------------------------------------------------
log_step:
  pusha
  mov	eax,'step'
  call	log_regtxt
  mov	eax, ' pid'
  call	log_regtxt
  mov	eax,[trace_pid]
  call	log_hex
  call	log_eol
  popa
  ret

;---------------------------------------------------------------
log_wait:
  pusha
  pushf
  mov	[w_return],eax
  mov	[w_stat],ebx
  mov	eax,'wait'
  call	log_regtxt
  mov	eax,' rtn'
  call	log_regtxt
  mov	eax,[w_return]
  call	log_hex
  mov	eax,' st='
  call	log_regtxt
  mov	eax,[w_stat]
  call	log_hex
  call	log_eol
  popf
  popa
  ret

;---------------------------------------------------------------
log_dis:
  pusha
  lea	esi,[eax+dis_block.inst]
  mov	ecx,esi
ldis_lp:
  lodsb
  or	al,al
  jnz	ldis_lp
  mov	edx,esi
  sub	edx,ecx
  dec	edx
  mov	ebx,[fd_open_flg]
  call	file_write
  popa
  ret

;------------------------------
;  log_hex - write hex to file called "log"
; INPUTS
;    eax = binary number for log file
;          (converted to hex ascii then written)
; OUTPUT
;    none (all registers unchanged)
;    file "log" will have <space>number<space> appended.
; NOTES
;    source file: log.asm
  extern log_open
log_hex:
  call	log_open
  pusha
  mov	edi,hex_number
  mov	ecx,eax			;hex in ecx
  call	dword_to_hexascii
  mov	ebx,[fd_open_flg]
  mov	edx,9			;write 10 bytes
  mov	ecx,hex_number_start	;data to write
  call	file_write
  popa
  ret
;-----------
  [section .data]
hex_number_start:
hex_number: db '00000000 '

w_return	dd 0
w_stat		dd 0

  [section .text]


%endif

