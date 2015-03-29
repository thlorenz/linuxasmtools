  extern dis_one

;------------- asmbug1_codehunt.inc ----------------------------------------------

hunt_setup:
  mov	eax,[preamble+pre.elf_phys_code_end]
  sub	eax,[preamble+pre.elf_phys_top]
  mov	[hunt_end_offset],eax
  mov	esi,[preamble+pre.elf_phys_code_start]
  sub	esi,[preamble+pre.elf_phys_top]	;compute offset
  mov	[hunt_top_offset],esi
  mov	[do_hunt],byte 1
  ret  

;------------------------------------------
; inputs:  [load_image_ptr]
;          [flag_image_ptr]
;          [mem_header + mem.code_phys_start]
;          [mem_header + mem.code_phys_end]
;          [do_hunt]  flag to enable code_hunt
;                     cleared at end of code_hunt
; output:
;         cl = return code  0=success
;                           1=illegal inst. and code flag set
;                           2=flag error, body bit set at start of inst
;                           3=flag error, code start found while setting
;                             body bits.
;                           4=operand bits incorrect
;         esi =  final offset, or offset of error if failure
; 
code_hunt:
  mov	eax,[do_hunt]
  or	eax,eax
  jz	pcf_exit1
  xor	eax,eax
  mov	[change_flag],eax
  mov	[dis_on_flag],eax
  mov	esi,[hunt_initial_offset]
  mov	[hunt_initial_offset],eax ;disable hunt_initial_offset
  or	esi,esi			;was hunt_initial_offset set
  jnz	pcf_lp4			;jmp if initial offset set
;
; note: changed the following line 
;       mov edx,[preamble+pre.elf_phys_exec_entry]
;       to below, to fix problem with screen scroll if
;       center EIP has gone up to catch area that has not
;       been processed by code_hunt.  Flags have 80 code
;       on instructions, but body bit not set.  Thus, scroll
;       up and down is bizzare.   
  mov	edx,[preamble+pre.elf_phys_code_start]
  call	physical2offset
;  mov	[hunt_initial_offset],ebp
  mov	esi,ebp
;  mov	esi,[hunt_top_offset]	;start at top of code section
;esi=hunt start point.  Hunts till {hunt_end_offset]
pcf_lp4:
  mov	ebx,[flag_image_ptr]
  test	[dis_on_flag], byte 1
  jnz	pcf_11			;jmp code dis active
  test  [ebx + esi],byte 80h	;is code here bit set
  jz	pcf_tail		;jmp if code not found
  mov	byte [dis_on_flag],1	;turn dis on
pcf_11:
  call	set_code_flags
  or	ecx,ecx
  jnz	pcf_exit		;exit if error
pcf_20:
  mov	ecx,[eax + Dis.operand_]
  jecxz pcf_tail		;jmp if no operand
  call	set_operand_flags  
  or	ecx,ecx
  jnz	pcf_tail		;jmp if no error
  mov	cl,4			;set operand error
  jmp	pcf_exit  
pcf_tail:
  inc	esi			;move to next byte
  cmp	esi,[hunt_end_offset] ;loop done ?
  jb	pcf_lp4			;loop till done
  cmp	byte [change_flag],0
  jne	code_hunt	;do it again if changes found
pcf_exit1:
  xor	ecx,ecx
  mov	[do_hunt],ecx
pcf_exit:
  or	cl,cl
  ret   
;----------------------
;code flag bit is set or dis_on_flag = 1
; input:  esi = offset for current instruction
; output: eax = dis code block ptr
;         esi - is offset to next instruction
;         cl = return code  0=success
;                           1=illegal inst. and code flag set
;                           2=flag error, body bit set at start of inst
;                           3=flag error, code start found while setting
;                             body bits.
set_code_flags:
  mov	eax,[preamble+pre.elf_phys_top]
  lea	eax,[eax + esi]		;get physical address
  mov	ebp,[load_image_ptr]
  lea	ebp,[ebp + esi]		;get local ptr to inst. data
  push	esi			;save current offset
  call	dis_one			;returns block ptr in eax
  pop	esi			;restore offset
  mov	ebp,[flag_image_ptr]
  lea	ebp,[esi + ebp]		;get address for flag byte
  mov	bl,[eax + Dis.error_flg]
  or	bl,bl
  jz	scf_12			;jmp if legal instruction found
  mov	[dis_on_flag],byte 0	;turn off code
;  inc	esi			;move to next inst
  xor	ecx,ecx
  jmp	short scf_exit

;  test	[ebp],byte 80h
;  jz	scf_12			;jmp if flag not set for code
;error, code bit set and dis says it is illegal
;  mov	cl,1			;get error code  
;  jmp	short scf_exit
scf_12:
  mov	bh,[eax + Dis.instruction_typ]
  test	bh,08			;is this a non-conditional jmp
  jz	scf_14			;jmp if normal instruction
  mov	[dis_on_flag],byte 0	;turn off code generation
;build flag bits for this instruction
scf_14:
  mov	bl,[ebp]		;get flag
  test	bl,40h			;is body flag set
  jz	scf_15			;jmp if no body flag here
  mov	cl,2
  jmp	short scf_exit		;error, code start with body bit set
scf_15:
  test	bl,80h			;was code bit set already
  jnz	scf_17			;jmp if code here flag already set
  mov	[change_flag],byte 1	;set change occured
scf_16:
  or	[ebp],byte 80h		;set code here bit
scf_17:
  mov	ecx,[eax + Dis.inst_len];get length of instruction
;set instruction body flags
scf_body_lp:
  dec	ecx
  jecxz scf_exit		;jmp if instruction body bits set
  inc	esi			;bump offset to next inst byte
  inc	ebp			;move to next flag byte
  mov	bl,[ebp]		;get current flag
  and	bl,0c0h
  cmp	bl,80h			;check if code start here
  jne	scf_20			;jmp if possible body
  mov	cl,3
  jmp	scf_exit		;error jmp, code body with code start flag set
scf_20:
  mov	[ebp],byte 0c0h		;set flag byte
  jmp	short scf_body_lp
;check if this instruction has a operand
scf_exit:
  ret
;-----------------------------------------------------------
; input:  eax = dis block ptr
;         esi = offset of next instruction, not current
;         ecx = operand
;
; output: cl = flag bits set if success
;         ecx = 0 if error
set_operand_flags:
  push	eax			;save dis block ptr
  mov	eax,ecx			;phys adr > eax
  call	check_range		;check if operand possible address
  jnc	sof_10			;jmp if range ok
  pop	eax
  jmp	sof_ignore
sof_10:
  mov	edx,ecx			;operand -> edx
  call	physical2offset		;get possible offset for this operand -> ebp
  call	offset2flag_ptr		;edx=ptr to flag for operand
  pop	eax			;restore dis block ptr
  mov	cl,[eax + Dis.operand_typ]
; ebp=offset for operand  cl=operand type edx=operand flag ptr   
  test	cl,01h			 ;is this a jmp adr
  jnz	sof_66			;jmp if jmp operand
  test	cl,02h			;is this a call adr
  jnz	sof_68			;jmp if call adr
  test	cl,20h			;check if immediate
  jnz	sof_70			;jmp if immediate data
;this is a data operand (4,byte 8,word 10,dword)
  test	[edx],byte 80h		;is this area set to code
  jnz	sof_65			;jmp if code area
  or	cl,cl
  jz	sof_ignore		;jmp if unknown operand
  shr	cl,2			;build flag byte for data
sof_65:
  mov	cl,20h			;add label hit bit
  jmp	short sof_90		;jmp to flag set
;set flag for jmp at destination, esi=current offset ecx=operand     
sof_66:
  test	[edx],byte 40h		;check if body flag set
  jnz	sof_err			;jmp if body flag set here
  mov	cl,0a1h
  test	[edx],byte 80h		;check if code here bit set already
  jz	sof_80			;jmp if new code hit
  jmp	short sof_90
;set flag for call at destination
sof_68:
  test	[edx],byte 40h		;check if body flag set
  jnz	sof_err			;jmp if body flag set here
  mov	cl,0a2h
  test	[edx],byte 80h		;check if code here bit set already
  jz	sof_80			;jmp if new code hit
  jmp	short sof_90
;set flag for immediate data destination
sof_70:
  mov	ch,[edx]		;get current flag
  and	ch,0c0h			;isolate code and body flags
  cmp	ch,0c0h
  je	sof_err			;jmp if label inside inst. body
  mov	cl,20h			;add label hit bit
  and	[edx],byte ~40h		;clear body bit incase this is data area
  jmp	short sof_90
sof_ignore:
  mov	ecx,1			;ignore code
  jmp	short sof_exit
sof_err:
  xor	ecx,ecx
  jmp	short sof_exit
sof_80:
  mov	[change_flag],byte 1	;set change occurred flag
sof_90:
  or	byte [edx],cl
sof_exit:
  ret

;-----------------------------------------------------------
; check if symbol within "load" range
;  input: eax=address
;  output: carry set if out of range
;
check_range:
  cmp	eax,[preamble+pre.elf_phys_top]
  jb	cr_bad
  cmp	eax,[preamble+pre.elf_phys_bss_end]
  jb	cr_good		 ;jmp if symbol within load range
cr_bad:
  stc
  jmp	short cr_exit
cr_good:
  clc
cr_exit:
  ret
;-----------------------------------------------------------
; input: edx = physical address
; output: no carry ebp = offset of physical address
;         carry = out of range, ebp set to zero
physical2offset:
  cmp	edx,[preamble+pre.elf_phys_top]
  jb	ph_bad
  cmp	edx,[preamble+pre.elf_phys_bss_end]
  ja	ph_bad		;jmp if out of range
ph_ok:
  mov	ebp,edx
  sub	ebp,[preamble+pre.elf_phys_top]
  clc
  jmp	short ph_exit
ph_bad:
  xor	ebp,ebp		;set offset zero
  stc
ph_exit:
  ret
;-----------------------------------------------------------
; input: ebp=offset
; output: edx=physical address
offset2physical:
  mov	edx,ebp
  add	edx,[preamble+pre.elf_phys_top]
  ret
;-----------------------------------------------------------
; input: ebp=offset
; output: edx=ptr to code in load_image
offset2code_ptr:
  mov	edx,ebp
  add	edx,[load_image_ptr]
  ret
;-----------------------------------------------------------
; input:  ebp=offset
; output: edx=ptr to flag image data
offset2flag_ptr:
  mov	edx,ebp
  add	edx,[flag_image_ptr]
  ret


;--------------
  [section .data align=4]
dis_on_flag	dd 0		;set non zero if code dis active
change_flag	dd 0		;set if new information set into flags
hunt_top_offset	dd 0		;offset into image,flag sections
hunt_end_offset dd 0
hunt_initial_offset dd 0	;set externaly, first pass starts here
;                               ; if zero, use hunt_top_offset instead
do_hunt		dd 0		;set non-zero to enable code hunt
  [section .text]


