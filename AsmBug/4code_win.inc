  extern trace_step
  extern trace_continue
  extern signal_send
  extern trace_kill

;structure at mem_header+mem.
;
;struc mem
;.load_phys_top	resd 1
;.code_phys_start resd 1
;.code_phys_end	 resd 1 ;points one byte beyond last used location
;.data_phys_start resd 1 ;if zero, no data section found
;.data_phys_end   resd 1 ;points one byte beyond last used location
;.bss_phys_start  resd 1 ;if zero, no bss section found
;.bss_phys_end	 resd 1 ;points one byte beyond last used location
;.load_phys_end	resd 1	;does not include .bss section
;
;variable of interest: win_bit_map 20h=center 2h=show code win
;                      code_adr_offset - top of display
;                      Breaks (dd adr,db contents) times 8
;                      regs_1 - current regs (app updated already)
;                      regs_2 - copy regs_1 here before exec
;
; physical2offset - edx(phys) -> ebp(off)
; offset2physical - ebp(off) -> edx(phys)
; offset2flag_ptr - ebp(off) -> edx(ptr)
; offset2code_ptr - ebp(off) -> edx(ptr)
;

;code_adr_buf times 60 dd 0 ;adress associated with line#
;code_data_buf times 60 dd 0 ;operand associated with line#
; 
;add_break: edx=adr out eax=0 for success
;remove_break: edx=adr
;find_break: edx=adr out ecx=0 if not found
;
;dis_block - pointer to last block from dis_one with
;  warn_flag db   0 ;bit 01h = warning, nasm can not generate this opcode
;  error_flag db  	0 ;bit  01h = illegal instruction                C P
;  instruction_type db   0 ;bit 00h - normal instruction
                        ;bit 01h - floating point
                        ;bit 02h - conditional jmp
                        ;bit 04h - proteced mode (system) instruction
			;bit 08h - non-conditonal jmp (ret,call,jmp)
;  operand_type	db   0  ;bit 01h - jmp adr at operand
                        ;bit 02h - call adr at operand
                        ;bit 04h - read/write byte adr at operand
                        ;bit 08h - read/write word adr at operand
                        ;bit 10h - read/write dword adr at operand
                        ;bit 20h - probable adr in immediate (const) data
;  operand 	dd   0  ;address (physical) for jmp,read,write, or operand if actions=0
;  inst_length	dd   0	;length of instruction                     S
;  state_flag:	db  	0 ;0= instruction decoded,return  info.      C P
;  prefix_flag: db   0       ;80=found non-prefix opcode, decode done   C P
;  inst_end dd   0   ;ptr end of data in instruction_asciiz               S
;  inst     times 140 db 0 ;ascii instruction build area                        SP


;-----------------------------------------------------------------
code_go:
  call	move_registers
  mov	esi,regs_1
  call	trace_regsset
  mov	edx,[r1_eip]
  call	find_break	;check if break at eip
  jecxz	cg_20		;jmp if no break at eip
;we need to step over break location
  mov	esi,[send_signal] ;get signal
  mov	[send_signal],dword 0	;clear signal flag
  call	trace_step
  js	cg_err

  xor	eax,eax
  mov	[app_status],eax

  mov	eax,114
  mov	ebx,[trace_pid]
  mov	ecx,app_status
  mov	edx,0				;1=WNOHANG
  xor	esi,esi
  int	byte 80h
;returns eax=err if app dead
;returns eax=0 if no change in status
;returns eax=pid if stop and status filled in

;  call	trace_wait

%ifdef TRACE
  call	app_step_log
%endif

;  cmp	bl,7fh		;normal stop
;  jne	cg_err
;
  mov	esi,regs_1
  call	trace_regsget
  mov	edx,[r1_eip]
  call	find_break	;break here?
  jecxz	cg_20		;jmp if no break here
  jmp	short cg_exit2	;exit if break here
;run to next break
cg_20:
  call	insert_breaks
  xor	esi,esi			;normal restart
  call	trace_continue
  mov	[app_mode],byte 12	;set running mode
  mov	[win_bit_map],byte 3fh	;update menu
  jmp	short cg_exit
cg_err:

cg_exit2:
  mov	[win_bit_map],byte 3fh	;update menu
cg_exit:
  ret

;----------------------------------------------------------------
code_step:
  cmp	[app_mode],byte 12
  jb	do_step
;stop running app
  call	stop_app
  jmp	cs_exitx
do_step:
;check if this is dynamic call
  mov	edx,[r1_eip]
  call	physical2offset
  call	offset2code_ptr
  cmp	byte [edx],0e8h	;is this a call?
  jne	do_step2
  mov	ebp,[edx+1]		;get operand
  add	ebp,[r1_eip]		;compute address
  add	ebp,5			;adjust for instruction len
;check if this is a dynamic lib user
  test	[preamble+pre.elf_type_flag],byte 1	;dynamic?
  jz	do_step2		;do step if non-dynamic
;find .plt section
  mov	ebx,preamble+pre.sheader_ptrs-4
cs_lpa:
  add	ebx,4		;next section
  mov	eax,[ebx]	;get section ptr
  or	eax,eax
  jz	do_step2	;jmp if no sections
  cmp	dword [eax+sect.sh_name],'.plt' ;is .plt?
  jne	cs_lpa		;jmp if not .plt
;we have found .plt section, check if call is to .plt
  mov	ebx,[eax+sect.sh_addr] ;get .plt top
  cmp	ebp,ebx		;compare adr to .plt top
  jb	do_step2	;jmp if adr not in .plt
  add	ebx,[eax+sect.sh_size] ;compute .plt end
  cmp	ebp,ebx
  jb	code_stepo	;jmp if in .plt

do_step2:
  call	move_registers
  mov	esi,regs_1
  call	trace_regsset
  mov	esi,[send_signal] ;get signal
  mov	[send_signal],dword 0	;clear signal flag
  call	trace_step

  xor	eax,eax
  mov	[app_status],eax

  mov	eax,114
  mov	ebx,[trace_pid]
  mov	ecx,app_status
  mov	edx,0				;1=WNOHANG
  xor	esi,esi
  int	byte 80h
;returns eax=err if app dead
;returns eax=0 if no change in status
;returns eax=pid if stop and status filled in

%ifdef TRACE
  call	app_step_log
%endif

  call	do_status
  mov	esi,regs_1
  call	trace_regsget
;check ebx status here?
  mov	[win_bit_map],byte 2eh	;update code,regs,mem & center eip
cs_exitx:
  ret
;---------------------------------------------------------------

code_stepo:
  cmp	[app_mode],byte 12
  jb	do_stepo
;stop running app
  call	kill_app1
  jmp	cso_exit
do_stepo:
  mov	[stepover_restore_flag],byte 0
  call	move_registers
  mov	esi,regs_1
  call	trace_regsset
;check if this instruction is terminator
  push	ebp
  mov	edx,[r1_eip]
  call	physical2offset
  call	do_dis
  pop	ebp
  mov	eax,[dis_block]
  mov	al,[eax+2]	;get instruction_type
  test	al,2+8		;check if jmp or other
  jnz	cso_exit	;exit if not good idea
;check if break at eip
  mov	edx,[r1_eip]
  call	find_break	;check if break at eip
  jecxz	cso_20		;jmp if no break at eip
;we need to remove break at eip, and restore later
  mov	edx,[r1_eip]
  mov	[break1],edx
  mov	[stepover_restore_flag],byte 1
  call	remove_break
;check if next instruction already has break?
cso_20:
  call	physical2offset	;edx(phys) -> ebp(off)
  call	next_offset
  call	offset2physical
  call	find_break	;check defined breaks
  jecxz cso_30		;jmp if no break found
  jmp	short cso_40	;next inst. has existing break
;add temp break on next instruction
cso_30:
  mov	[break2],edx	;save temp break adr
  or	[stepover_restore_flag],byte 2
  call	add_break
cso_40:
  or	[stepover_restore_flag],byte 4
  call	insert_breaks
  mov	esi,[send_signal] ;get signal
  mov	[send_signal],dword 0	;clear signal flag
  call	trace_continue
  mov	[app_mode],byte 16	;set running mode
  mov	[win_bit_map],byte 1	;update menu
cso_exit:
  ret
;----------
  [section .data]
stepover_restore_flag	db 0 ;1=restore break1  2=remove break2 4=stepover active
break1: dd 0	;break at eip
break2: dd 0	;break set on next instruction
  [section .text]
;---------------------------------------------------------------
code_find:
  mov	[search_stuf],dword code_find_continue
  mov	al,30	;column
  mov	ah,11	;row
  call	calc
;check range of ecx, and use if ok
  mov	eax,ecx
  call	check_range
  jc	cf_show	;exit of outside load image
  mov	edx,eax
cfc_success:
  push	ebp
  call	physical2offset
  mov	[code_adr_offset],ebp
  pop	ebp
cf_show:
  call	show_calc_out
  or	[win_bit_map],byte 02h	;show code and center eip
  ret
;---------------------------------------------------
code_find_continue:
  call	partial_search_again
  mov	edx,ecx
  mov	eax,ecx
  or	ecx,ecx
  jnz	cfc_success
;got to end without match
cfc_end:
  ret  

;---------------------------------------------------
; eax = value to show
;
show_calc_out:
  mov	ebp,win_block
  push	eax			;save value
  mov	ebx,[codeMenuForButton]
  mov	ecx,[codeMenuBButton]
  call	window_id_color
  pop	eax			;restore value

  push	eax			;save value
  mov	edi,code_stuff2
  call	dwordto_hexascii
  pop	eax			;restore value

  push	ebp
  mov	edi,code_stuff3
  or	eax,eax
  mov	cl,11			;number of char's
  jns	sco_positive
  neg	eax
  mov	byte [edi],'-'
  inc	edi
  mov	cl,10
sco_positive:
  mov	ch,'0'			;pad char
  call	dword_to_lpadded_ascii
  pop	ebp

  mov	esi,code_menu_adr
  call	window_write_table
  ret
;---------------
  [section .data]
code_menu_adr:
  db 12		;write text
  dw 30		;column
  dw 11		;row
  db cma_len
cma_string:
  db '0x'
code_stuff2:
  times 8 db ' '
  db ' ('
code_stuff3:
  times 11 db ' '
  db ') '
cma_len equ $ - cma_string

 db 0	;end of table
  [section .text]

;---------------------------------------------------------------
code_quit:
  mov	[event_mode],byte 1	;set exit
  ret
;---------------------------------------------------------------
code_up:
  push	ebp
  mov	ebp,[code_adr_offset]
  call	previous_offset
  jc	cu_exit		;exit if at top
  mov	[code_adr_offset],ebp
  or	[win_bit_map],byte 02h
cu_exit:
  pop	ebp
  ret
;---------------------------------------------------------------
;
code_pgup:
  push	ebp
  mov	ecx,[code_end_line]
  sub	ecx,13			;compute lines in code win
  mov	ebp,[code_adr_offset]	;get offset at top of code win
cp_lp:
  call	offset2flag_ptr
  test	[edx],byte 30h		;check if label here
  jz	cp_11			;jmp if no label
  dec	ecx
  jbe	cp_top			;jmp if page full
cp_11:
  call	previous_offset
  jc	cp_top			;jmp if at top now
  loop	cp_lp
cp_top:
  mov	[code_adr_offset],ebp
  or	[win_bit_map],byte 02h
  pop	ebp
  ret

;---------------------------------------------------------------
code_down:
  push	ebp
  mov	ebp,[code_adr_offset]
  call	next_offset
  jc	cd_exit		;exit if at end
  mov	[code_adr_offset],ebp
  or	[win_bit_map],byte 02h
cd_exit:
  pop	ebp
  ret

;--------------------------------------------------------------
code_pgdn:
  push	ebp
;compute lines in code win
  mov	ecx,[code_end_line]
  sub	ecx,13			;compute lines in code win
  mov	ebp,[code_adr_offset]	;get offset at top of code win
cpp_lp:
  call	offset2flag_ptr
  test	[edx],byte 30h		;check if label here
  jz	ccpp_10			;jmp if no label
  dec	ecx
  jbe	cpp_end			;jmp if page full
ccpp_10:
  call	next_offset
  jc	cpp_end2		;jmp if at end now
  loop	cpp_lp
cpp_end:
  mov	[code_adr_offset],ebp
cpp_end2:
  or	[win_bit_map],byte 02h
  pop	ebp
  ret
;------------------------------------------------------------
code_mouse_?:
  call	code_help
  ret

;-----------------------------------------------------------
; input:  ebp = current offset
; output: ebp = next offset if no  carry
;               else, edx unchanged if at top of section.
next_offset:
  mov	[no_starting_offset],ebp
  call	offset2flag_ptr
no_lp:
  inc	ebp
  inc	edx
  test	byte [edx],40h
  jnz	no_lp		;loop if not start of inst/data
  call	offset2physical
  cmp	edx,[preamble+pre.elf_phys_load_end]
  jb	no_ok		;jmp if address in range
  mov	ebp,[no_starting_offset]
  stc
  jmp	short no_exit
;next offset found ok
no_ok:
  clc
no_exit:
  ret
;------------
  [section .data]
no_starting_offset dd 0
  [section .text]
;-----------------------------------------------------------
; input:  ebp = current offset
; output: ebp = previus offset if no  carry
;               else, edx unchanged if at top of section.
previous_offset:
  mov	[no_starting_offset],ebp
po_lp:
  dec	ebp
  call	offset2physical
  cmp	edx,[preamble+pre.elf_phys_top]
  jb	po_at_top	;jmp if at top
  call	offset2flag_ptr
  test	byte [edx],40h	;start of inst/data?
  jnz	po_lp
  clc
  jmp	short po_exit  
po_at_top:
  mov	ebp,[no_starting_offset]
  stc
po_exit:
  ret

;-----------------------------------------------------------------
insert_breaks:
  mov	esi,Breaks
  mov	ecx,8
ib_lp:
  mov	edx,[esi]			;get poke address
  or	edx,edx
  jz	ib_done				;jmp if end of breaks
  push	esi
  mov	esi,trap_code			;get pointer to data
  mov	edi,1				;get number of bytes
  push	ecx
  call	trace_poke_bytes
  pop	ecx
  pop	esi
  add	esi,5
  loop	ib_lp
ib_done:
  ret
;-------------
  [section .data]
trap_code db 0cch
  [section .text]

;-----------------------------------------------------------------
;remove_breaks: - see 3event_trace.inc

;----------------------------------------------------------------
;move regs_1 to regs_2 for changed test in reg window
move_registers:
  mov	esi,regs_1
  mov	edi,regs_2
  mov	ecx,17
  rep	movsd
  ret
;----------------------------------------------------------------
code_popup_adr:
  push	code_adr_buf
  jmp	short cpo_entry

;  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
;  xor	edx,edx
; ; div	word [ebp+win.s_char_height]
;  sub	eax,byte 12
;  mov	ebx,eax				;save row
;  shl	ebx,2				;convert to dword index

;  pop	eax
;  add	ebx,eax		;code_adr_buf
;  mov	eax,[ebx]
;  mov	ebx,20		;column
;  mov	ecx,11		;row
;  call	pop_up
;  or	[win_bit_map],byte 2
;  ret
;----------------------------------------------------------------
code_popup_operand:
  push	code_data_buf
cpo_entry:
  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  sub	eax,byte 12
  mov	ebx,eax				;save row
  shl	ebx,2				;convert to dword index
  pop	eax
  add	ebx,eax		;code_data_buf
  mov	eax,[ebx]
  or	eax,eax		;check if operand present
  jz	cpo_exit	;exit if no operand

;check if break toggle or menu
  mov	bl,[ecx+mouse_pkt.but]
  cmp	bl,1		;check if left click
  jne	cpo_20		;jmp if right click
  call	toggle_break
  or	[win_bit_map],byte 1eh
  jmp	short cpo_exit
cpo_20:
  mov	ebx,20		;column
  mov	ecx,11		;row
  call	pop_up
  or	[win_bit_map],byte 2
cpo_exit:
  ret

;----------------
  [section .text]

;stop running application
stop_app:
  mov	ebx,[trace_pid]
  mov	ecx,19		;stop signal
  call	signal_send
  or	[event_mode],byte 4	;set forced stop flag
;we may need to detach and reattach?
  ret
;-----------------------------
kill_app1:
  mov	ebx,[trace_pid]
  mov	ecx,9		;kill signal
  call	signal_send

  call	trace_kill	;kill ptrace
  mov	[win_bit_map],byte 3fh
  ret




