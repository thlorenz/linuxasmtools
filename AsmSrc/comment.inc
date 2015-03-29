 extern string_restore
 extern string_lookup

comment_setup:
  test	[preamble+pre.elf_type_flag],byte 20h	;check for comment file
  jz	cs_exit			;exit if no comment file
  mov	ebx,asmdis_comment	;filename
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
  mov	ebx,asmdis_comment	;filename
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
asmdis_comment: db ".abug_comment.dat",0
comment_file_size: dd 0
comment_file_ptr: dd 0
  [section .text]
;-------------------------------------------------------
; check if comment line available for this address
;  inputs:  ah = current column
;           edi = struff ptr
;           ebp = offset
;           [end_of_win_column]
;
comment_check:
  test	[preamble+pre.elf_type_flag],byte 20h	;check for comment file
  jz	cc_exit			;exit if no comment file
  push	eax
  mov	eax,[current_phys_adr]
;  call	offset2physical	;in: ebp=offset  out:edx=physical address
;  mov	eax,edx
  call	string_lookup	;in: eax=key  out: ecx=0 if fail, else esi=string ptr
  pop	eax		;restore current column (ah)
  jecxz	cc_exit
;check if we are at insert column
  mov	al,09h		;tab char
  stosb
;we are at insert point for comment
cc_insert:
  call	str_move
cc_exit:
  ret
