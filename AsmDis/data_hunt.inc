  extern is_alpha

; input: [mem_header1]
; output: ecx = non_zero for success
;         ecx = 0 for failure
;
data_hunt:
  mov	byte [block_type],0	;set code type
  mov	edx,[preamble+pre.elf_phys_code_start]
  call	set1
  mov	edx,[preamble+pre.elf_phys_code_end]
  call	physical2offset
  call	offset2flag_ptr
  mov	[flag_end_ptr],edx
  mov	[threshold],byte 7
;identify data repeats and strings in code section
  call	do_data_scan
  jecxz	dh_exitj		;exit if error
;setup for data section
  mov	byte [block_type],1	;set data type
  mov	al,2			;writable flag
  call	find_pheader_type
  jz	check_bss		;jmp if no data section
  mov	edx,[ebx+head.phys_start] ;get start of data
  call	set1
  mov	edx,[ebx+head.phys_end] ;get end
  call	physical2offset
  call	offset2flag_ptr
  mov	[flag_end_ptr],edx
  mov	[threshold],byte 3
;identiry  data repeats and strings in data section
  call	do_data_scan
dh_exitj:
  jecxz	dh_exit
check_bss:
;setup for .bss section
;  mov	byte [block_type],2	;set code type
  mov	al,8
  call	find_pheader_type
  jz	dh_exit		;exit if .bss not found
  mov	edx,[ebx+head.phys_start] ;get start of .bss
  call	physical2offset
  call	offset2flag_ptr
  mov	esi,edx
  mov	edx,[ebx+head.phys_end]	;get end of .bss
  call	physical2offset
  call	offset2flag_ptr
;esi=.bss flag ptr   edx=.bss flag end
  or	[esi],byte 08h	;set repeat start
bss_lp:
  inc	esi
  cmp	esi,edx
  jae	dh_exit
  mov	al,[esi]	;get flag
  or	al,al		;any flags set
  jnz	bss_tail	;jmp if flags set
  or	al,40h		;set repeat body bit
bss_tail:
  or	al,08h
  mov	[esi],al
  jmp	short bss_lp
dh_exit:
  ret
;------------------------
set1:
  call	physical2offset
  call	offset2code_ptr
  mov	[image_start_ptr],edx
  call	offset2flag_ptr
  mov	[flag_start_ptr],edx
  ret
;------------------------------------------------
; inputs: see data section below
; output: ecx = non-zero if success
;             = zero if failue
;
;  register usage: ecx=count
;                  ebp= image ptr
;                  edx= flag  ptr
;                  esi= trial image ptr
;                  edi= trial flag ptr
;                  ah = base char at [ebp]
;                  
do_data_scan:
  mov	ebp,[image_start_ptr]
  mov	edx,[flag_start_ptr]
dds_lp:
  mov	esi,ebp			;restart trial image ptr
  mov	edi,edx			;restart trial flag ptr
  xor	ecx,ecx			;restart count
dds_lp2:
  call	get_byte		;returns al=data ah=flag and flags
  js	dds_exitj		;jmp if end of section
  test	ah,80h			;check if code
  jnz	dds_05			;jmp if code
  test	ah,03h			;check if db
  jz	dds_30			;jmp if db type
  jmp	short dds_10		;jmp if other data type
;code was found, scan to end of instruction
dds_05:
  call	get_byte
  cmp	ah,0c0h			;check for code body
  je	dds_05			;jmp if code body found
  dec	ecx
  jmp	short dds_tail2
dds_10:
  test	ah,01h			;check if dw
  jz	dds_20			;jmp if not dw
;dw found, set body bit here
  or	[edi],byte 40h		;set body bit
  _mov	ecx,2
  jmp	short dds_tail2
;check if dd
dds_20:
  test	ah,02h
  jz	dds_tail1		;jmp if not dd
;dd found, set body bits
  or	[edi],byte 40h
  inc	edi
  or	[edi],byte 40h
  inc	edi
  or	[edi],byte 40h
  _mov	ecx,4
  jmp	short dds_tail2
dds_exitj:
  jmp	short dds_exit
;db data found, check if alpha or repeat
dds_30:
  call	alpha_check
  jne	dds_60			;jmp if not alpha
;we have found alpha char, check if more
dds_40:
  call	get_byte
  js	dds_50		;jmp if section end
  jnz	dds_50		;jmp if not db type data or label here
  call	alpha_check
  je	dds_40		;loop if alpha
;set string bits ecx times
dds_50:
  cmp	ecx,[threshold]
  jb	dds_tail1	;jmp if threshold not reached
;  push	ecx 
  mov	esi,edx		;get ptr to start of string flags
  dec	ecx
  push	ecx
  or	[esi],byte 04h	;set string type
  dec	ecx		;
dds_55:
  inc	esi
  or	[esi],byte 44h	;string + body
  loop	dds_55		;loop till done
  pop	ecx
  jmp	short dds_tail2
;non-alpha found, check for repeat
dds_60:
  mov	bl,al		;save char
dds_70:
  call	get_byte	;get next char
  js	dds_80		;jmp if section end
  jnz	dds_80		;jmp if not db type data or label here
  cmp	al,bl		;check if repeat
  je	dds_70		;loop if repeat
;set repeat bits ecx times
dds_80:
  cmp	ecx,[threshold]
  jb	dds_tail1	;jmp if threshold not reached
;  push	ecx 
  mov	esi,edx		;get ptr to start of string flags
  dec	ecx
  push	ecx
  or	[esi],byte 08h	;set repeat type
  dec	ecx		;
dds_85:
  inc	esi
  or	[esi],byte 48h	;repeat + body
  loop	dds_85		;loop till done
  pop	ecx
  jmp	short dds_tail2
dds_tail1:
  _mov	ecx,1
dds_tail2:
  add	ebp,ecx
  add	edx,ecx
  jmp	dds_lp		;loop till done
dds_exit:
  ret  
  
  
;
;------------------------------------------------
; input: esi=trial image ptr
;        edi=trial flag ptr
;        ecx,edx,ebp are in use
; output: al=image data
;         ah=flag
;           js set if - section end
;           jz set if - db data type
;           jc set if - label here
;             else non-db type data/code
;         esi,edi bumped by 1
;
get_byte:
  mov	al,[esi]		;get data byte
  mov	ah,[edi]		;get flag byte
  inc	esi			;move to next byte
  inc	edi			;move to next flag
  inc	ecx
  cmp	[flag_end_ptr],edi
  jb	gb_end			;jmp if end of section
  test	ah,30h
  jnz	gb_label		;jmp if label here
  test	ah,83h			;check if db
  jz	gb_exit			;jmp if normal db
;this is non-db, could be code,dw,dd
  or 	edx,edx			;clear all flags
  jmp	short gb_exit
gb_label:
  stc				;label here, set carry
gb_end:				;sign bit set, end of section
gb_exit:
  ret
;---------------------------------------------
; input:  al = char
; output:
;
alpha_check:
  call	is_alpha
  jne	ac_exit2	;jmp if not alpha
  cmp	al,22h		;check if quote
  jne	ac_exit1
  cmp	al,0		;set not alpha flag for jne
  jmp	short ac_exit2
ac_exit1:
  cmp	al,al
ac_exit2:
  ret
;----------------
  [section .data]
block_type:	dd	0 ;0=code 1=data 2=bss
image_start_ptr dd	0
flag_start_ptr	dd	0
flag_end_ptr	dd	0
threshold	dd	0 ;number of repeat/alpha to accept
  [section .text]
