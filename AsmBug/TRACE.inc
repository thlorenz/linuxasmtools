 extern log_regtxt
 extern log_hex
 extern log_eol
; extern hex_dump_file
 extern fd_open_flg

socket_trace:
  pushf
  pusha
  push	eax
  mov	eax,"sok "
  call	log_regtxt
  pop	eax
  push	eax
  call	log_hex
  call	log_eol
  mov	ecx,32
  mov	ebx,[fd_open_flg]
  mov	esi,lib_buf
  call	log_hex_dump
  call	log_eol
  pop	eax
  popa
  popf
  ret


;---------------------
;>1 log-error
;  log_hex_dump - dump hex to file
; INPUTS
;    ecx = dump length
;    esi = ptr to binary data
; OUTPUT:
; NOTES
;   source file: hex_dump.asm
;<
; * ----------------------------------------------
  global hex_dump_file
log_hex_dump:
  pusha
hdf_lp:
  lodsb
  push	ecx
  push	esi
  call	log_hex_byte
  pop	esi
  pop	ecx
  loop	hdf_lp
  call	log_eol
  popa
  ret

;---------------------------------------------------------
; NAME
;>1 log-error
;  log_hex_byte - write hex to file called "log"
; INPUTS
;    al = binary number for log file
;          (converted to hex ascii then written)
; OUTPUT
;    none (all registers unchanged)
;    file "log" will have <space>number<space> appended.
; NOTES
;    source file: log.asm
;<
;  * ----------------------------------------------
;*******
  extern byteto_hexascii
  extern file_write
  global log_hex_byte
log_hex_byte:
;  call	log_open
;  pusha
  mov	edi,hex_byte
  call	byteto_hexascii
  mov	ebx,[fd_open_flg]
  mov	edx,3		;write 10 bytes
  mov	ecx,hex_byte	;data to write
  call	file_write
;  popa
  ret
;-----------
  [section .data]
hex_byte: db '00 '
  [section .text]
;---------------------------------------------------------

error_trace:
  push	eax
  mov	eax,'err '
  call	log_regtxt
  pop	eax
  call	log_hex
  call	log_eol
  ret
;--------------------------------------------------------

app_log:
  or	eax,eax
  jz	al_exit		;exit if no change
  push	eax
  mov	eax,'run '
  call	log_regtxt
  pop	eax
  push	eax
  call	log_hex
  mov	eax,[app_status]
  call	log_hex
  call	log_eol
  pop	eax
al_exit:
  ret
;--------------------------------------------------------

app_step_log:
  push	eax
  mov	eax,'stp '
  call	log_regtxt
  pop	eax
  push	eax
  call	log_hex
  mov	eax,[app_status]
  call	log_hex
  call	log_eol
  pop	eax
asl_exit:
  ret
  