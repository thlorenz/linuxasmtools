;------------------- file: sbug_map.inc ---------------------
;
;A big problem for debuggers is determing what areas contain
;instructions and where data is.  Also, the debugger has to
;deal with allocated memory, it could be either data or
;instructions.
;
;If debug records are available the job of finding code
;is easier, but "sbug" does not read ELF files and look
;for debug information.  It trys to find code by looking
;at raw instructions and decoding them.
;
;This file describes the method used by sbug to identify
;code areas of a program.  It isn't a perfect.
;
;First, sbug determines the range of accessable memory by
;assuming it was allocated in 4k blocks and trying to access
;each block.  This results in a address range for the initial
;load.
;
;A bit map is created describing each byte within the load
;range.  One byte of loaded program is assigned one byte
;in the bit map.  This byte is set as follows:
;
;  00h - data byte here
;  02h - code (instruction start)
;  01h - code body
;  20h - shadow code (not verified)
;  10h - shadow body (not verified)
;
;The bit map will be utilized by the following:
; map_setup - create the map and set initial bits
; map_lookup - check address
; map_update - set inst. here bit
; map_back - go back one inst. or data byte
; map2adr - convert bit map ptr to address
; adr2map - convert phys adr to bit map adr
;
;the expected load address is 8048000 for start of header
;the expected program code start is 8048080
; allocation blocks = 4096 = 1000h a mask would be 0fffh
;the header is normally 127 bytes of a mask of 7fh 
;
;-------------------------------------------------------
; map_back - go back one inst. or data byte
;  map_back - input: eax = adr
;             output: eax = prev. adr
;
;-------------------------------------------------------

; map_lookup - check address
;  map_lookup - input: eax = adr
;               output: bl = 0 = code start
;                            1 = data
;                            2 = outside load range
;                           -1 = error in map
;
;-------------------------------------------------------
; hunt_shadow - set map bits from disassembly
;  input: [load_code_ptr]
;         [map_code_ptr]
; output:
; note: we start hunting from eip.  Actual code may
;       occur before this, but we do not know where.
;       The elf header length is unreliable and we
;       don't want to call elfdecode because it will
;       write files to this directory.
;
hunt_shadow:
  mov	eax,[load_code_ptr]
  mov	eax,[app_eip]	;temp !!!
  mov	[hunt_adr],eax	;save hunt start loc
  call	adr2map
  jc	hs_donej	;exit if error
  mov	[hunt_map_ptr],eax
hs_loop:
  mov	esi,[hunt_map_ptr]
  mov	eax,[hunt_adr]
hs_sublp1:
  cmp	esi,[map_end_ptr]
  jb	hs_05
hs_donej:
  jmp	hs_done	;jmp if end of load area
hs_05:
 test	byte [esi],3	;is this byte mapped
  jz	hs_10		;jmp if not mapped
  inc	esi
  jmp	hs_sublp1
;we have found unmapped area
hs_10:
  mov	[hunt_map_ptr],esi
  mov	eax,esi
  call	map2adr
  mov	[hunt_adr],eax
;read raw instruction data
hs_do_inst:
  mov	edx,[hunt_adr]		;get start address
  mov	esi,raw_inst
  mov	edi,11			;number of bytes to read
  call	trace_peek_bytes
  js	hs_donej			;exit if done
;disassemble instruction to get length
  mov	eax,[hunt_adr]
  mov	ebp,raw_inst
  call	dis_one
  mov	[mu_block],eax	;save dis block
;check if legal instruction found
  mov	bl,[eax + Dis.error_flg] ;get Dis.error_flg
  or	bl,bl
  jz	hs_set1			;jmp if legal inst
;scan forward to find good code
  mov	esi,[hunt_map_ptr]
skip_fwd:
  cmp	esi,[map_end_ptr]
  jae	hs_done			;exit if done
  test	byte [esi],3
  jnz	hs_15			;jmp if data found
  inc	esi
  jmp	skip_fwd
hs_15:
  mov	[hunt_map_ptr],esi
  mov	eax,esi
  call	map2adr
  mov	[hunt_adr],eax
  jmp	hs_loop
;set shadow bits
hs_set1:
  mov	eax,[hunt_map_ptr]	;get map address
  or	[eax],byte 20h		;set start bit
;set body bits, eax=map adr ebx = index 0,2,4,6
  mov	ecx,[mu_block]	;get dis block ptr
  mov	ecx,[ecx + Dis.inst_len];get length of instruction
  mov	eax,[hunt_map_ptr]	;map address
hs_body_lp:
  inc	eax		;bump inst adr
  dec	ecx		;dec inst length
  jecxz	hs_body_end	;jmp if done
  mov	[hunt_map_ptr],eax
  mov	bh,[eax]	;get old value
  test	bh,03h		;non-shadow map set
  jnz	hs_body_end	;jmp if mapped already
  or	[eax],byte 10h	;set body flag
  jmp	short hs_body_lp
hs_body_end:
  mov	[hunt_map_ptr],eax
  call	map2adr
  mov	[hunt_adr],eax
  jmp	hs_loop
hs_done:  
  ret
;-------------------------------------------------------
; code_hunt - set map bits from simulated execution
;  input: [load_code_ptr]
;         [map_code_ptr]
; output:
hunt_exec:
  mov	[changed_flag],byte 0
  mov	eax,[load_code_ptr]
hunt_entry:	;enter here with eax = hunt start point
  mov	[hunt_adr],eax	;save hunt start loc
  call	adr2map
  jc	ch_end		;exit if outside map
  mov	[hunt_map_ptr],eax
;dis is off, hunt for map bit
ch1_loop:
  mov	eax,[hunt_map_ptr]
  cmp	eax,[map_end_ptr]
  jae	ch2_tail	;jmp if end of map
  mov	bl,[eax]	;get flag
  test	bl,2		;inst start
  jnz	ch_10		;jmp if start found
ch1_tail:
  inc	dword [hunt_map_ptr]
  inc	dword [hunt_adr]
  jmp	short ch1_loop
ch_10:
  mov	eax,[hunt_adr]
ch2_loop:
  call	map_update
  mov	eax,[mu_adr]	;get next inst adr
  mov	[hunt_adr],eax
  cmp	[dis_on_flag],byte 0
  je	ch_20		;jmp if dis off
  jmp	short ch2_loop
;
ch_20:
  call	adr2map		;get map ptr
  js	ch_end		;exit if out of range
  mov	[hunt_map_ptr],eax
  jmp	ch1_tail  
;
ch2_tail:
  cmp	[changed_flag],byte 0
  je	ch_end
;The following instruction caused the program htop
;to fail.  Could not set break on some instructions.
;
  jmp	hunt_exec	;go do it again
ch_end:
  ret
;--------
  [section .data]
dis_on_flag:	db 0
hunt_map_ptr:	dd 0 ;map ptr
hunt_adr:	dd 0 ;app physical adr
  [section .text]
;-------------------------------------------------------
;input: eax=phys adr bl=value to set (01=body 02=inst start)
map_set:
  call	adr2map
  jc	ms_exit		;exit if out of range
  mov	bh,[eax]	;get old value
  or	[eax],bl
  cmp	bh,[eax]	;did value change?
  je	ms_exit
  or	[changed_flag],byte 1
ms_exit:
  ret 
;-------------------------------------------------------
; map_update - set inst. here bit
;  map_update - input: eax = physical code adr
; output: [mu_adr] has next inst adr
;    1. do dis to get length
;    2. set flag bits + body bits
;    3. check operand, and set flags for inst start
map_update:
  mov	[mu_adr],eax		;save address
  mov	edx,eax			;address to edx
  mov	esi,raw_inst
  mov	edi,11			;number of bytes to read
  call	trace_peek_bytes
;disassemble instruction to get length
  mov	eax,[mu_adr]
  mov	ebp,raw_inst
  call	dis_one
  mov	[mu_block],eax	;save dis block
  mov	[dis_on_flag],byte 0	;turn off code
;check if legal instruction found
  mov	bl,[eax + Dis.error_flg] ;get Dis.error_flg
  or	bl,bl
  jnz	mu_done			;jmp if illegal instruction found
  mov	bh,[eax + Dis.instruction_typ]
  test	bh,08			;is this a non-conditional jmp
  jz	mu_set1			;jmp if normal instruction
  mov	[dis_on_flag],byte 0	;turn off code generation
  jmp	short mu_set2		;
mu_set1:
  mov	[dis_on_flag],byte 1	;enable disassembly
mu_set2:
;set bit in map
  mov	eax,[mu_adr]	;get app address
  mov	bl,02h		;inst start flag
  call	map_set		;set inst start flag
;set body bits, eax=map adr ebx = index 0,2,4,6
  mov	ecx,[mu_block]	;get dis block ptr
  mov	ecx,[ecx + Dis.inst_len];get length of instruction
  mov	bl,1		;body flag
  mov	eax,[mu_adr]	;app address
mu_body_lp:
  inc	eax		;bump inst adr
  dec	ecx		;dec inst length
  jecxz	mu_body_end	;jmp if done
  push	eax
  call	map_set
  pop	eax		;restore inst adr
  jmp	short mu_body_lp
mu_body_end:
  mov	[mu_adr],eax	;save inst adr
;set operand bits
  mov	eax,[mu_block]		;restore dis block ptr
  mov	cl,[eax + Dis.operand_typ] ;get Dis.operand_typ
  mov	eax,[eax + Dis.operand_] ;get operand
; ebp=offset for operand  cl=operand type edx=operand flag ptr   
  test	cl,01h			 ;is this a jmp adr
  jnz	mu_set			;jmp if jmp operand
  test	cl,02h			;is this a call adr
  jz	mu_done			;jmp if not call adr
mu_set:
  mov	bl,2			;code start flag
  call	map_set			;set flag for operand
mu_done:
  ret
;-------
  [section .data]
mu_adr:		dd 0	;address
raw_inst:	times 11 db 0
changed_flag:	db 0	;set 1 if flag changed
mu_block:	dd 0
  [section .text]
;-------------------------------------------------------
; map_setup - create the map and set initial bits
;  map_setup - no parameters
;    1. scan memory for range
;    2. allocate memory for bit map
;    3. starting at eip do code hunt and set bits
map_setup:
  mov	edx,[app_eip]	;get eip
  and	edx,~0fffh	;form starting 4k boundry
;look for top of load memory
ms_top_loop:
  push	edx		;save mem adr
  mov	esi,peek_results
  call	trace_peek
  pop	edx
  js	ms_top
  sub	edx,1000h	;4k
  jmp	short ms_top_loop
ms_top:
  add	edx,1000h	;restore last good access
  mov	[load_header_ptr],edx	;save top
;get size of header
  push	edx		;save header start
  lea	edx,[edx+elfheader.e_hsize] 
  mov	esi,peek_results ;data buffer
  call	trace_peek	;read header size
  pop	edx		;restore header start
  js	ms_header
  xor	ecx,ecx
  mov	cx,[peek_results]	;get size of header
  add	edx,ecx		;compute end of header
ms_header:
  mov	[load_code_ptr],edx
;look for bottom
  mov	edx,[load_header_ptr]
ms_end_loop:
  push	edx
  mov	esi,peek_results
  call	trace_peek
  pop	edx
  js	ms_end
  add	edx,1000h	;4k
  jmp	short ms_end_loop
ms_end:
  dec	edx		;restore last good access
  mov	[load_end_ptr],edx	;save end
;kludge --- for now ------------------------------- 
  mov	edx,[_elf_phys_code_end];from elfdecode     
  mov	[load_end_ptr],edx      ;                   
;---------------------------------------------------
;compute size of map
  mov	eax,edx
  sub	eax,[load_header_ptr]
  push	eax		;save alloc size
  add	eax,10h		;add padding at end
  call	m_allocate
  mov	[map_header_ptr],eax
  pop	ebx		;restore alloc size
  mov	ecx,ebx		;save alloc size
  add	ebx,eax		;compute map end
  mov	[map_end_ptr],ebx
;clear the map
  mov	edi,eax		;start of map to edi
  xor	eax,eax
  rep	stosb		;clear the map
;set load_code_ptr by guessing
; note: this is a kludge, someday we may want
;       to decode the elf file?
  mov	eax,[app_eip]
  cmp	eax,8048080h
  jb	ms_code_set
  mov	eax,8048080h	;force to 8048080
ms_code_set:
  mov	[load_code_ptr],eax
;set map code ptr from load
  sub	eax,[load_header_ptr] ;compute delta
  add	eax,[map_header_ptr]
  mov	[map_code_ptr],eax
;do code hunt and set bits
  mov	eax,[app_eip]
  call	map_update	;set bits in map
  call	hunt_exec
  call	hunt_shadow    
  ret
;-------
  [section .data]
peek_results	dd 0
poke_results	dd 0
  [section .text]
;-------------------------------------------------------
; map2adr - convert bit map ptr to address
;  map2adr - input: eax = map adr
;            output: eax = physical adr
;
map2adr:
  sub	eax,[map_header_ptr]	;compute map index
  add	eax,[load_header_ptr]
  ret
;-------------------------------------------------------
; adr2map - convert phys adr to bit map adr
;  adr2map - input: eax = physical adr
;            output: eax = map adr
;            carry flag set if out of range
adr2map:
  sub	eax,[load_header_ptr]	;compute byte index
  js	a2m_range_err
a2m_ok:
  add	eax,[map_header_ptr]	;compute map adr
  cmp	eax,[map_end_ptr]
  ja	a2m_range_err
  clc
  ret
a2m_range_err:
  stc
  ret

;-------------------------------------------------------
;check_map - check if hunt needed & within map

check_map:
  mov	eax,[app_eip]
  call	adr2map		;get map address
  jc	cm_exit2	;exit if outside map
;check if hunt needed
  test	[eax],byte 02	;known code here?
  jnz	cm_exit1

  mov	eax,[app_eip]
  call	map_update

  mov	eax,[app_eip]		;set eax to app adr
  call	hunt_entry	;set bits in map
cm_exit1:
  clc
  jmp	short cm_exit
cm_exit2:
  mov	eax,[app_eip]
  mov	[dis_win_top],eax
cm_exit:
  ret
  
  [section .text]
   