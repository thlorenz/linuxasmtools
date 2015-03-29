; It appears all reply packets are 32 bytes long.  If additional
; data is available the length field has a number.
;--------------------------------------------------------------
decode_read_packets:
  mov	ecx,[ebp+pids.r_eax]		;length of data
  mov	[dbuf_size],ecx			;save data count
  mov	esi,temp_buf			;buffer ptr
  mov	[dbuf_ptr],esi			;save buffer ptr
;check if this is continuation of pkt
  mov	ebx,[active_socket]
  test	[ebx+xconn.flag],byte 2
  jz	drp_lpa				;jmp if not continuation
;-------
;all continuation of read packets, comes here to
;dump contents.
  mov	eax,[continue]			;remove this block of data
  sub	eax,ecx				; from continue
  mov	[continue],eax			;   packet size
  jz	drp_clear			;jmp if all data read
  jns	drp_cont			;jmp if more data comming
drp_clear:  
  and	[ebx+xconn.flag],byte ~2	;clear the flag
;add continuation header
drp_cont:
  xor	eax,eax
  mov	ax,[continue_seq]
  mov	edi,cont_stuf
  call	wordto_hexascii
  mov	ecx,cont_name
  mov	edx,cont_len
  call	outfile_write

drp_dlp:
  mov	ecx,[dbuf_size]
  call	drp_hex_dump
;add lf at end
  mov	ecx,crlf
  mov	edx,1
  call	outfile_write
  jmp	drp_done
;--------
;non-continuation (normal) packets come here.
;processing pkt loop, esi=data ptr 
drp_lpa:
;decode packet type using reply_table to decode them.
; reply table format is:  dd ascii_name_ptr
;                         dd processing ptrs
  xor	eax,eax
  mov	al,[esi]	;get packet op code
  cmp	al,35
  jbe	event_ok	;jmp if within range
  mov	al,36		;force unknown event
event_ok:
  shl	eax,3				;multiply by 8
  add	eax,reply_table 		;index into table
  mov	ebx,[eax]			;get ascii name ptr
  mov	[rp_name_ptr],ebx		;save name ptr  
  mov	ebx,[eax+4]			;get function decode ptr
  mov	[rp_info_ptr],ebx
;show function name
  mov	esi,[rp_name_ptr]
  mov	edi,lib_buf
  call	str_move
  mov	ecx,lib_buf
  mov	edx,edi
  sub	edx,lib_buf			;compute length
  call	outfile_write
;show sequence# if this is a reply packet
  mov	al,[temp_buf]		;get first byte of buffer
  cmp	al,1			;reply packet
  jne	drp_skip		;jmp if not reply packet


;show sequence#
  mov	ax,[temp_buf+2]		;get sequence from packet
  mov	edi,rseq_stuff
  call	wordto_hexascii
  mov	ecx,rseq_string
  mov	edx,edi
  sub	edx,rseq_string
  call	outfile_write
;check if this is reply to query_extension
  mov	eax,[next_name_ptr]
  or	eax,eax
  jz	drp_skip		;jmp if not reply to query_extension
;check if correct sequence#
  mov	bx,[temp_buf+2]		;get sequence#
  cmp	[query_extension_seq],bx
  jne	drp_skip
  mov	bl,[temp_buf+8]		;get bool (present flag)
  or	bl,bl
  jz	drp_reset		;jmp if extension not present
;advance ptr and save extension data
  xor	ebx,ebx
  mov	bl,[temp_buf+9]		;get opcode
  shl	ebx,3
  add	ebx,decode_table-8
  mov	ecx,[name_expansion_ptr]
  mov	[ebx],ecx		;insert ptr to name
  mov	[ebx+4],dword _NoOperation ;add dummy processing
  mov	[name_expansion_ptr],eax ;advance ptr
drp_reset:
  mov	[next_name_ptr],dword 0


drp_skip:


;add  ---- we can add a enhanced dump of packet
;contents here, the plan is to use decode table
;with existing hooks.  Additional entries would
;have bytes of:  name-index,offset-into-pkt,type
;These would continue till zero byte found.


;add lf at end
  mov	ecx,crlf
  mov	edx,1
  call	outfile_write

;add hex dump of packet
  mov	ecx,[ebp+pids.r_eax]		;get size of read
  call	drp_hex_dump
;add lf at end
  mov	ecx,crlf
  mov	edx,1
  call	outfile_write
;if this is a reply packet, check if more data coming
  mov	al,[temp_buf]		;get first byte of buffer
  cmp	al,1			;reply packet
  jne	drp_done		;jmp if not reply packet
;check if continuation packet comming
  mov	esi,[dbuf_ptr]
  mov	eax,[esi+4]	;get next packet size
  or	eax,eax
  jz	drp_done	;jmp if no continuation
  shl	eax,2		;convert to dword count
  mov	[continue],eax	;save continuation size-;;should be in socket table? 
  mov	ax,[esi+2]	;get continue seq
  mov	[continue_seq],ax ;save seq number
  mov	ebx,[active_socket]
  or	[ebx+xconn.flag],byte 02 ;set continuation pkt
drp_done:
  ret
;---------------------------------------------------------
;input: ecx = size of packet
;
drp_hex_dump:
  mov	esi,[dbuf_ptr]			;get pkt data ptr
dhd_loop:
  mov	edi,lib_buf
;    ecx = dump length (16 bytes or less)
;    esi = ptr to binary data 
;    edi = output buffer ptr
  call	buffer_hex
  push	esi
  push	ecx
  mov	ecx,lib_buf
  mov	edx,edi		;get ending ptr
  sub	edx,ecx		;compute length
  call	outfile_write
  pop	ecx
  pop	esi
  cmp	byte [truncate_mode],0
  jne	dhd_exit	;exit if truncate mode active
  or	ecx,ecx
  jecxz	dhd_exit
  jns	dhd_loop
dhd_exit:  
  ret

;---------
  [section .data]
rseq_string:	db '-reply-to#'
rseq_stuff:	db '     '
continue	dd 0		;;;temp length of continue
continue_seq	dd 0		;;;temp continue seq
rp_name_ptr	dd 0		;function name ptr
rp_info_ptr	dd 0		;function processing ptr

cont_name:	db '-continuation of reply#'
cont_stuf:	db '    ',0ah
cont_len	equ $-cont_name
  [section .text]
