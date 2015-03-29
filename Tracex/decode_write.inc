  [section .text]

extern wordto_hexascii

decode_write_packets:
  mov	ebx,[active_socket]		;get fd table
  test	[ebx+xconn.flag],byte 1		;first write packet after connect?
  jz	dwp_20				;jmp if not first
;this is authorizing packet
  mov	ecx,auth
  mov	edx,auth_len
  call	outfile_write
  jmp	dwp_exit
;this is normal packet block, show each packet
dwp_20:
  mov	ecx,[ebp+pids.r_edx]		;length of data
  mov	[dbuf_size],ecx			;save data count
  mov	esi,temp_buf			;buffer ptr
  mov	[dbuf_ptr],esi			;save buffer ptr
;processing pkt loop, esi=data ptr 
dwp_lp:
  xor	eax,eax
  lodsb					;get opcode

  cmp	eax,170				;unplanned extension?
  jbe	normal_wpkt			;jmp if normal write pkt
;this is a dynamic extension
dwp_22:
  mov	edi,ext_stuf
  call	byteto_hexascii
  mov	[edi],byte 0			;terminate string
  mov	esi,ext_name
  jmp	dwp_30

;this in a normal pkt, range 0-127
normal_wpkt:
  shl	eax,3				;multiply by 8
  add	eax,decode_table -8		;index into table
  mov	ebx,[eax]			;get ascii name ptr
  or	ebx,ebx
  jnz	dwp_26				;jmp if pkt in table
  mov	al,[esi-1]			;restore opcode
  jmp	short dwp_22
dwp_26:
  mov	[wf_name_ptr],ebx		;save name ptr  
  mov	ebx,[eax+4]			;get function decode ptr
  mov	[wf_info_ptr],ebx
;show function name
  mov	esi,[wf_name_ptr]
dwp_30:
  mov	ebx,[active_socket]
  inc	word [ebx+xconn.seq]		;bump sequence#  
  mov	edi,lib_buf
  call	str_move
  mov	ecx,lib_buf
  mov	edx,edi
  sub	edx,lib_buf			;compute length
  call	outfile_write
;show sequence#
  mov	ebx,[active_socket]
  xor	eax,eax
  mov	ax,[ebx+xconn.seq]
  push	eax				;save extension
  mov	edi,seq_stuff
  call	wordto_hexascii
  mov	ecx,seq_string
  mov	edx,edi
  sub	edx,seq_string
  call	outfile_write
;check if this is extension query
  mov	eax,[wf_name_ptr]
  cmp	eax,QueryExtension
  pop	eax				;restore seq#
  jne	dwp_40				;jmp if not extension query
  mov	[query_extension_seq],eax	;save extension
;save extension name
  mov	esi,[dbuf_ptr]
  xor	ecx,ecx
  mov	cx,[esi+4]		;get length of name
  lea	esi,[esi+8]		;get ptr to name
  mov	edi,[name_expansion_ptr]
  call	str_move		;save name
  inc	edi			;include zero in name
  mov	[next_name_ptr],edi
dwp_40:


;add  ----


;add lf at end
  mov	ecx,crlf
  mov	edx,1
  call	outfile_write
;add hex dump of packet
  mov	esi,[dbuf_ptr]			;get pkt data ptr
  xor	ecx,ecx
  mov	cx,[esi+2]			;get packet length
  shl	ecx,2				;convert from dword cnt to byte cnt
dwp_lp2:
  mov	edi,lib_buf
  call	buffer_hex
  push	esi
  push	ecx
  mov	ecx,lib_buf
  mov	edx,edi		;get ending ptr
  sub	edx,ecx		;compute length
  call	outfile_write
  pop	ecx
  pop	esi
  cmp	[truncate_mode],byte 0
  jne	dwp_tail	;exit if truncate mode
  or	ecx,ecx
  jz	dwp_tail
  jns	dwp_lp2		;loop if more data
dwp_tail:
;add lf at end
  mov	ecx,crlf
  mov	edx,1
  call	outfile_write
;check for another packet to process
  mov	esi,[dbuf_ptr]
  xor	eax,eax
  mov	ax,[esi+2]			;get packet length
  shl	eax,2				;convert from dword cnt to byte cnt
  jnz	dwp_50				;jmp if length ok

  mov	ecx,help			;;;test code, leave in for now
  mov	edx,6
  call	outfile_write
  jmp	dwp_exit

dwp_50:
  add	esi,eax				;move to next pkt
  mov	[dbuf_ptr],esi

  mov	ecx,[dbuf_size]
  sub	ecx,eax				;reduce size of remaining data
  mov	[dbuf_size],ecx

  jecxz dwp_exit			;exit if done
  jns	dwp_lp				;loop for all packets  
dwp_exit:
  ret
;---------
  [section .data]
help	db '-help-'

dbuf_ptr:	dd 0	;buffer pointer
dbuf_size:	dd 0	;data left in buffer
wf_name_ptr:	dd 0	;ptr to current function name
wf_info_ptr:	dd 0	;ptr to function decode info

ext_name:	db 'Ext_'
ext_stuf:	db '    '
crlf	db 0ah
seq_string:	db ' request#='
seq_stuff:	db '       '
auth: db 0ah,'Authorization packet written',0ah,0ah
auth_len	equ $ - auth
  [section .text]
