  extern byte_to_ascii

  [section .text]
;------------------------
; signed_ascii_byte
;  al=byte
;  edi=stuff ptr
;
signed_ascii_byte:
  mov	ah,'+'
  or	al,al		;check sign
  jns   sab_20
  mov	ah,'-'
  neg	al
sab_20:
  mov	[edi],ah
  inc	edi
  call	byte_to_ascii
  ret

;------------------------
; bin_to_hexascii_h - stores hex (xx..H) without leading zeros
; inputs: ebx = binary data
;         edi = storage for asciihex
;
bin_to_hexascii_h:
  mov	al,'0'
  stosb
  call	hex_worker
  mov	al,'H'
  stosb
  jmp	short bth
;------------------------
; bin_to_hexascii - stores hex (xx..) without leading zeros
; inputs: ebx = binary data
;         edi = storage for asciihex
;
bin_to_hexascii:
  call	hex_worker
bth:
  mov	byte [edi],0	;put zero at end
  ret
hex_worker:
  mov	eax,ebx
  shr	ebx,4
  and	al,0fh
  add	al,'0'
  cmp	al,'9'
  jle	n_ok
  add	al,'A' - '9' -1
n_ok:
  push	eax
  or	ebx,ebx
  jz	n_done		;jmp if done
  call	hex_worker
n_done:
  pop	eax
  stosb
  ret

;***************  format_text.inc  *************************
;
  [section .text]
;---------------------------------------------------
; stuff_adr - build address entry of form [adr]
;  input: eax = address
;          bl = target size, 1=byte 2=word 3=dword
;         edi = stuff ptr
;  output: edi = ptr to next stuff point
;
stuff_adr:
  mov	[sa_data],eax
  mov	eax,sa_ctrl
  call	format_text
  ret
;---------------------
  [section .data]
sa_ctrl:  db  "[",-5
sa_data:  dd	0
	  db  "]",0
  [section .text]

;---------------------------------------------------
; stuff_db - insert "db" into buffer
;  input: al = hex byte to insert
;         edi = stuff ptr
;  output: edi = ptr to next stuff point
;
stuff_db:
  mov	[sd_data],al
  mov	eax,sd_ctrl
  call	format_text
  ret
;---------------------
  [section .data]
sd_ctrl:  db  "db",09h,-7
sd_data:  db	0,0ah,0
  [section .text]

;------------------------------------------------------
; stuff_op - format "name"
;  input: ecx = name index (word offset from "names)
;
stuff_op:
  mov	[so_data],cx		;save opcode name index
  mov	eax,so_ctrl
  call	format_text
  ret 
;---------------------
  [section .data]
so_ctrl:  db -8
so_data:  dw	0
	db	0	;end of data
  [section .text]

;------------------------------------------------------
; stuff_reg - format "reg"
;   input:         bl = register number (0,1,2)
;                  bh = register type -1 = eax,ecx,etc
;                            -2 = ax,cx,etc
;                            -3 = al,cl,etc.
;                            -4 = es,...
;
stuff_reg:
  mov	[sr_regc],bh
  mov	[sr_regv],bl
  mov	eax,sr_ctrl
  call	format_text
  ret 
;---------------------
  [section .data]
sr_ctrl:
sr_regc:  db 0		;register type
sr_regv:  db 0		;register index
	   db 0		;end of list
  [section .text]

;------------------------------------------------------
; stuff_op_reg - format "name" and "register"
;  input: cx = name index (word offset from "names)
;         bl = register number (0,1,2)
;         bh = register type -1 = eax,ecx,etc
;                            -2 = ax,cx,etc
;                            -3 = al,cl,etc.
;                            -4 = es,...
;
stuff_op_reg:
  mov	[sor_name],cx		;save opcode name index
  mov	[sor_regc],bh
  mov	[sor_regv],bl
  mov	eax,sor_ctrl
  call	format_text
  ret 
;---------------------
  [section .data]
sor_ctrl:  db -8
sor_name:  dw	0
	   db 09h
sor_regc:  db 0		;register type
sor_regv:  db 0		;register index
	   db 0		;end of list
  [section .text]

;------------------------------------------------------
; stuff_reg_hex - format "register","hex"
;  input: bl = register number, 0=eax 1=ecx (see reg_table)
;         bh = register type -1 = eax,ecx,etc
;                            -2 = ax,cx,etc
;                            -3 = al,cl,etc.
;                            -4 = es,...
;         ecx = value to convert to hex and store
;
stuff_reg_hex:
  mov	[srh_regc],bh
  mov	[srh_regv],bl
  mov	bh,-5		;get code for hex value size
  mov	[srh_hexc],bh
  mov	[srh_hexv],ecx
  mov	eax,srh_ctrl
  call	format_text
  ret 
;---------------------
  [section .data]
srh_ctrl:;  db 9
srh_regc:  db 0		;register type
srh_regv:  db 0		;retister value
           db ','	;comma
srh_hexc:  db 0		;immediate data size
srh_hexv:  dd 0		;immdediate value
           db 0ah,0
  [section .text]

;------------------------------------------------------
; stuff_reg_reg - format "register","register""
;  input: cl = register number1, 0=eax 1=ecx (see reg_table)
;         bl = register number2, 0=eac 1=ecx
;         bh = register type -1 = eax,ecx,etc
;                            -2 = ax,cx,etc
;                            -3 = al,cl,etc.
;                            -4 = es,...

;
stuff_reg_reg:
  mov	[frr_regc1],bh
  mov	[frr_regc2],bh
  mov   [frr_regv1],cl
  mov	[frr_regv2],bl
  mov	eax,frr_ctrl
  call	format_text
  ret 
;---------------------
  [section .data]
frr_ctrl:;  db 9
frr_regc1  db 0
frr_regv1  db 0
           db ','	;comma
frr_regc2  db 0
frr_regv2  db 0
           db 0ah,0
  [section .text]


;----------------------------------------------------
; reg_stuff - find string address for register and store it.
;  inputs:  al=register index ( 0=eax 1=ecx 2=edx etc. )
;           ebx = ptr to register strings
;           edi = storage ptr
;           direction flag is set (cld)
;  output: ebx,eax modified
;          edi = ptr to next stuff point
;
reg_stuff:
  push	esi
  mov	esi,ebx
  mov	bl,al
rl_lp1:
  or	bl,bl
  jz	rl_done		;jmp if text found
rl_lp2:  
  lodsb
  or	al,al
  jnz	rl_lp2		;loop till end of string
  dec	bl
  jmp	short rl_lp1
rl_done:
  call	str_move
  pop	esi
  ret
  

;----------------------------------------------------
;   *    format_text       - format strings    *
;----------------------------------------------------

;----------------------------------------------------
; input: eax = ptr to control string as follows:
;            byte 00 = done
;            byte -1 = register code follows for: (0)eax, (1)ecx,edx,ebx,etc.
;            byte -2 = register code follows for: (0)ax (1)cx (2)dx etc.
;            byte -3 = register code follows for: (0)al (1)cl etc.
;            byte -4 = register code follows for: (0)es etc.
;            byte -5 = dword value follows
;            byte -6 = word value follows
;            byte -7 = byte value follows
;            byte -8 = names index follows (word)
;            byte +n = ascii character to stuff directly
;
;        edi = stuff point
;
; output: edi = end of string ptr
;              
format_text:
  push	esi
  mov	esi,eax
ft_loop:
  xor	eax,eax		;clear eax for convert to hex routine
  lodsb
  cmp	al,0
  je	ft_done
  inc	al
  jz	ft_reg1		;jmp if eax,ecx,etc.
  inc	al
  jz	ft_reg2		;jmp if ax,cx,etc.
  inc	al
  jz	ft_reg3		;jmp if al,cl,etc.
  inc	al
  jz	ft_reg4		;jmp if es,.. etc.
  inc	al
  jz	ft_dword	;jmp if byte value
  inc	al
  jz	ft_word		;jmp if word value
  inc	al
  jz	ft_byte 	;jmp if dword value
  inc	al
  jz	ft_name		;jmp if word name index follows
;must be a normal ascii char
  sub	al,8
  stosb
  jmp	ft_loop

ft_reg1:
  mov	ebx,registers
  jmp	short ft_lookup
ft_reg2:
  mov	ebx,regs_mode16
  jmp	short ft_lookup
ft_reg3:
  mov	ebx,regs_byte
  jmp	short ft_lookup
ft_reg4:
  mov	ebx,regs_seg
ft_lookup:
  lodsb			;get register code
  call	reg_stuff
  jmp	ft_loop
ft_byte:
  lodsb
  jmp	short ft_convert 
ft_word:
  lodsw
  jmp	short ft_convert
ft_dword:
  lodsd
ft_convert:
  mov	ebx,eax
  mov	al,'0'
  stosb
  call	bin_to_hexascii_h
;  mov	al,'h'
;  stosb
  jmp	ft_loop
ft_name:
  lodsw			;get name index
  add	eax,names
  push	esi
  mov	esi,eax
  call	str_move
  pop	esi
  jmp	ft_loop
  
ft_done:
  pop	esi
  ret


;----------------------------------------------------------------------
; decode_rm - decode rm field
;
;  inputs: ebp = instruction ptr
;          edx = decode entry info:
;          [skip_size_flag] - 0=store dword/word/byte  1=no size info 2=tword 3=qword 4=word
;  output: ebp = at end of instruction
;           al = legal prefix's plus done code
;
;    format of decode entry:
;      [process index]
;      [flags-xxxx]
;      [name-index (word)]
;
;      for sx=06 the operand types are:
;
;      operand flag format:
;        80h = byte/dword flag (b-byte)
;        40h = second operand is a constant 1 (c-constant1) 
;        20h = second operand is immediate (i=immediate)
;        10h = special lds,les 
;   [state_flag] - has prefix info. 40h=escape prefix
;
decode_rm:
  push	edx
  mov	byte [prefix_bits],80h	;set exit code
;if mod=0,1,2 then insert byte/word/dword keyword
  mov	al,[ebp+1]
  and	al,0c0h		;isolate mod field
  cmp	al,0c0h		;is this a register op
  je	dr_10		;jmp if  register op (no keyword needed)
  or	byte [prefix_bits],20h	;prefix for seg regs is legal
  mov	esi,_byte
  test	byte [edx+1],80h ;is this a byte operation
  jnz	dr_05		;jmp if byte operation
  add	esi,5
  test	byte [state_flag],10h ;prefix flag set
  jnz	dr_05		;jmp if prefix set, (word)
  add	esi,5		;assume this is a dword
dr_05:
  mov	[dr_op_size],esi ;save size if operand_type flag needed
  cmp	byte [skip_size_flag],0
  je	dr_09		;jmp if normal dword/word/byte stuff
  mov	esi,_tword
  cmp	byte [skip_size_flag],2
  je	dr_09		;jmp if "tword" force
  mov	esi,_qword
  cmp	byte [skip_size_flag],3
  je	dr_09		;jmp if "qword"
  mov	esi,_word
  cmp	byte [skip_size_flag],4
  jne	dr_10		;skip dword/word/byte stuff if flag = 1
dr_09:
  call	str_move	;stuff "byte,word,dword"
  mov	al,' '
  stosb
dr_10:
  test	byte [state_flag],40h	;is this an 0fh (escaped) instruction
  jz	dr_12		;jmp if not escaped opcode
  or	byte [prefix_bits],40h		;set escape prefix is legal
dr_12:
  test	byte [edx+1],80h	;is this a byte operation
  jnz	dr_14			;jmp if byte
  or	byte [prefix_bits],10h	;set prefix 66h legal
dr_14:  
  xor	eax,eax
  mov	al,[ebp+1]	;get mod/rm byte
  mov	bl,al		;save mod/rm
  and	al,07		;isolate rm field
  shr	bl,3
  and	bl,18h		;isolate mod field
  or	al,bl		;combine into one value
  shl	eax,1		;convert to word index
  add	eax,dr_table	;look up processing
  xor	ebx,ebx
  mov	bx,[eax]	;get index to process
  add	ebx,dr_ref	;convert to 32-bit address
  call	ebx		;call process
  pop	edx
  ret 
       
;---------------------------------------------
dr_table:		;decode table for modrm
  dw	mem_eax - dr_ref	;mod=00 rm=000
  dw	mem_ecx - dr_ref	;mod-00 rm=001
  dw	mem_edx - dr_ref      ;mod-00 rm=010
  dw	mem_ebx - dr_ref      ;mod=00 rm=011
  dw	sib_1   - dr_ref      ;mod=00 rm=100
  dw	disp32  - dr_ref      ;mod=00 rm=101
  dw	mem_esi - dr_ref      ;mod=00 rm=110
  dw	mem_edi - dr_ref      ;mod=00 rm=111

  dw	mem8_eax - dr_ref	;mod=01 rm=000
  dw	mem8_ecx - dr_ref	;mod-01 rm=001
  dw	mem8_edx - dr_ref     ;mod-01 rm=010
  dw	mem8_ebx - dr_ref     ;mod=01 rm=011
  dw	sib_2    - dr_ref     ;mod=01 rm=100
  dw	mem8_ebp - dr_ref     ;mod=01 rm=101
  dw	mem8_esi - dr_ref     ;mod=01 rm=110
  dw	mem8_edi - dr_ref     ;mod=01 rm=111

  dw	mem32_eax - dr_ref	;mod=10 rm=000
  dw	mem32_ecx - dr_ref	;mod-10 rm=001
  dw	mem32_edx - dr_ref    ;mod-10 rm=010
  dw	mem32_ebx - dr_ref    ;mod=10 rm=011
  dw	sib_3     - dr_ref    ;mod=10 rm=100
  dw	mem32_ebp - dr_ref    ;mod=10 rm=101
  dw	mem32_esi - dr_ref    ;mod=10 rm=110
  dw	mem32_edi - dr_ref    ;mod=10 rm=111

  dw	reg_eax_x - dr_ref    ;mod=11 rm=000
  dw	reg_ecx_x - dr_ref    ;mod-11 rm=001
  dw	reg_edx_x - dr_ref    ;mod-11 rm=010
  dw	reg_ebx_x - dr_ref    ;mod=11 rm=011
  dw	reg_esp_x - dr_ref    ;mod=11 rm=100
  dw	reg_ebp_x - dr_ref    ;mod=11 rm=101
  dw	reg_esi_x - dr_ref    ;mod=11 rm=110
  dw	reg_edi_x - dr_ref    ;mod=11 rm=111
 
;----------------------------------------------
dr_ref:			;reference point for modrm decode routines

;-------- mod/rm field decode ---- **** mod = 00 *************************
mem_eax:
  mov	bl,0	;ebx,bl,bx
  call	mod_00_common
  ret
;-------- mod/rm field decode ----
mem_ecx:
  mov	bl,1	;ebx,bl,bx
  call	mod_00_common
  ret
;-------- mod/rm field decode ----
mem_edx:
  mov	bl,2	;ebx,bl,bx
  call	mod_00_common
  ret
;-------- mod/rm field decode ----
mem_ebx:
  mov	bl,3	;ebx,bl,bx
  call	mod_00_common
  ret
;-------- mod/rm field decode ----
sib_1:
  mov	al,'['
  stosb
  call	check_seg_prefix
  call	decode_sib  ;stuff sib data and bump ebp
  mov	al,']'
  stosb
  ret
;-------- mod/rm field decode ----
disp32:
  mov	al,'['
  stosb
  mov	ebx,[ebp+2]			;get address
  call	process_operand_data
  mov	al,']'
  stosb
  add	ebp,6				;move to next instruction
  ret
;-------- mod/rm field decode ----
mem_esi:
  mov	bl,6	;ebx,bl,bx
  call	mod_00_common
  ret
;-------- mod/rm field decode ----
mem_edi:
  mov	bl,7	;ebx,bl,bx
  call	mod_00_common
  ret

;-----
mod_00_common:
  mov	al,'['
  stosb
  call	check_seg_prefix
  mov	bh,-1	;register type=32 bit ebx
  call	stuff_reg
  mov	al,']'
  stosb
  add	ebp,2	;move to next instruction
  ret

;-------- mod/rm field decode ----  **** mod=01 *******************************
mem8_eax:
  mov	bl,0	;eax,al,ax
  call	mod_01_common
  ret
;-------- mod/rm field decode ----
mem8_ecx:
  mov	bl,1	;ecx,cl,cx
  call	mod_01_common
  ret
;-------- mod/rm field decode ----
mem8_edx:
  mov	bl,2	;edx,dl,dx
  call	mod_01_common
  ret
;-------- mod/rm field decode ----
mem8_ebx:
  mov	bl,3	;ebx,bl,bx
  call	mod_01_common
  ret
;-------- mod/rm field decode ----
sib_2:
  mov	al,'['
  stosb
  call	check_seg_prefix
  call	decode_sib  ;stuff sib data and bump ebp
;  mov	al,'+'
;  stosb
;  xor	ebx,ebx
  mov	al,[ebp]
  call	signed_ascii_byte
  inc	ebp  
  mov	al,']'
  stosb
  ret
;-------- mod/rm field decode ----
mem8_ebp:
  mov	bl,5	;ebp
  call	mod_01_common
  ret
;-------- mod/rm field decode ----
mem8_esi:
  mov	bl,6	;esi
  call	mod_01_common
  ret
;-------- mod/rm field decode ----
mem8_edi:
  mov	bl,7	;edi
  call	mod_01_common
  ret
;-----
mod_01_common:
  mov	al,'['
  stosb
  call	check_seg_prefix
  mov	bh,-1	;register type=32 bit ebx
  call	stuff_reg
  add	ebp,byte 2	;move to displacement
  mov	al,'+'
  stosb
  xor	ebx,ebx
  mov	bl,[ebp]			;get displacement

  test	bl,80h			;is this a negative number?
  jz	mod_01_05		;jmp if not negative
  dec	edi			;move back to overwrite '+'
  neg	bl
  mov	al,'-'
  stosb
  mov	al,bl
  push	edx
  call	byte_to_ascii
  pop	edx
  jmp	short mod_01_10
mod_01_05:

  call	bin_to_hexascii_h
mod_01_10:
  inc	ebp  
  mov	al,']'
  stosb
  ret

;-------- mod/rm field decode ---- **** mod = 10 ****************************
mem32_eax:
  mov	bl,0	;eax,al,ax
  call	mod_10_common
  ret
;-------- mod/rm field decode ----
mem32_ecx:
  mov	bl,1	;ecx,cl,cx
  call	mod_10_common
  ret
;-------- mod/rm field decode ----
mem32_edx:
  mov	bl,2	;edx,dl,dx
  call	mod_10_common
  ret
;-------- mod/rm field decode ----
mem32_ebx:
  mov	bl,3	;edx,dl,dx
  call	mod_10_common
  ret
;-------- mod/rm field decode ----
sib_3:
  mov	al,'['
  stosb
  call	check_seg_prefix
  call	decode_sib  ;stuff sib data and bump ebp
  mov	al,'+'
  stosb
  mov	ebx,[ebp]			;get displacement
  call	process_operand_data
  add	ebp,byte 4
  mov	al,']'
  stosb
  ret
;-------- mod/rm field decode ----
mem32_ebp:
  mov	bl,5	;ebp
  call	mod_10_common
  ret
;-------- mod/rm field decode ----
mem32_esi:
  mov	bl,6	;esi
  call	mod_10_common
  ret
;-------- mod/rm field decode ----
mem32_edi:
  mov	bl,7	;edi
  call	mod_10_common
  ret

;-----
mod_10_common:
  mov	al,'['
  stosb
  call	check_seg_prefix
  mov	bh,-1	;register type=32 bit ebx
  call	stuff_reg
  add	ebp,byte 2	;move to displacement
  mov	al,'+'
  stosb
  mov	ebx,[ebp]			;get displacement
  call	process_operand_data
  add	ebp,byte 4
  mov	al,']'
  stosb
  ret

;-------- mod/rm field decode ----  **** mod = 11 *****************************
reg_eax_x:
;  ret
;-------- mod/rm field decode ----
reg_ecx_x:
;  ret
;-------- mod/rm field decode ----
reg_edx_x:
;  ret
;-------- mod/rm field decode ----
reg_ebx_x:
;  ret
;-------- mod/rm field decode ----
reg_esp_x:
;  ret
;-------- mod/rm field decode ----
reg_ebp_x:
;  ret
;-------- mod/rm field decode ----
reg_esi_x:
;  ret
;-------- mod/rm field decode ----
reg_edi_x:

  mov	bl,[ebp+1]		;get mod/rm
  and	bl,7h			;isolate register code
  mov	bh,-3			;preload byte register code
  test	byte [edx + 1],80h	;is this a byte instruction
  jnz	rdx_10			;jmp if byte instruction
  mov	bh,-2			;preload register code for ax,cx,dx,bx
  test	byte [state_flag],10h	;is prefix 66h active?
  jnz	rdx_10			;jmp if prefix active, (use ax,cx,dx...)
  mov	bh,-1			;select register set eax,ecx,...
rdx_10:
  call	stuff_reg
  add	ebp,byte 2
  ret

;--------------------------------------------
; decode_sib - handle all sib bytes
;  inputs: ebp=current opcode ptr
;          edx=decode entry
;          edi=stuff ptr
; output: ebp = points to next byte after sib data
decode_sib:
  mov	byte [ebp_adjust],3
  mov	al,[ebp+2]	;get sib byte
  mov	ah,al		;save sib
;  and	al,38h		;isolate index field
;  cmp	al,20h		;illegal value here?
;  jne	ds_10		;jmp if value ok
;  or	byte [error_flag],01	;set illegal istruction
;  jmp	ds_80		;exit
;ds_10:
;  mov	al,ah		;get sib byte again
  and	al,07h		;isolate base
  cmp	al,5		;special case base=5
  jne	ds_40		;jmp if not special case
;base = 5, if mod=0 32bit disp follows, otherwise use ebp
  mov	al,[ebp+1]	;get mod/rm byte
  and	al,0c0h		;isolate mod field
  cmp	al,0		;is this mode=0
  jne	ds_40		;jmp if ebp to be used
  mov	ebx,[ebp+3]	;get displacement
  call	process_operand_data
  mov	byte [ebp_adjust],7
  jmp	ds_60		;go do register in index field
;process register in base field
ds_40:
  mov	bl,ah		;get sib byte
  and	bl,07h		;isolate register code
  mov	bh,-1		;code for eax,ecx,edx,etc.
  call	stuff_reg
;if index=100 then only one  register
  mov	bl,[ebp+2]	;get sib byte
  and	bl,38h		;isolate index field
  cmp	bl,20h		;index=100 
  je	ds_80		;jmp if index=100
;process register in index field
ds_60:
  mov	al,'+'
  stosb
  mov	bl,[ebp+2]	;get sib byte
  shr	bl,3		;right justify index field
  and	bl,07h
  mov	bh,-1
  call	stuff_reg
;if sib index = 100 then no scale factor is needed
  mov	al,[ebp+2]	;get sib byte
  mov	ah,al		;save sib
  and	al,38h		;isolate index field
  cmp	al,20h		;illegal value here?
  je	ds_80		;jmp if value ok
;add scale factor if present
  mov	ah,[ebp+2]	;get sib byte
  shr	ah,6		;right justify scale factor
  or	ah,ah
  jz	ds_80		;jmp if no scale factor
  mov	al,'*'
  stosb
  mov	al,'2'
  dec	ah
  jz	ds_70		;jmp if scale factor 2
  mov	al,'4'
  dec	ah
  jz	ds_70		;jmp if scale factor 4
  mov	al,'8'
ds_70:
  stosb
ds_80:
  add	ebp,[ebp_adjust]
  ret
;--------------------
  [section .data]
ebp_adjust:	dd	3	;default instrction size
prefix_bits:	db	0
skip_size_flag	db	0	;0= dword/word/byte stuff  1=no stuff  2=tword 3=qword
_tword db 'tword',0
_qword db 'qword',0
  [section .text]
;--------------------------------------------
;
check_seg_prefix:
  test	byte [state_flag],20h	;seg prefix found?
  jz	csp_exit		;exit if no prefix found
  push	ebx
  xor	eax,eax
  mov	al,[last_prefix_name]
  add	eax,regs_seg
  mov	esi,eax
  call	str_move
  mov	al,':'
  stosb
  pop	ebx
csp_exit:
  ret


;--------------------------------------------------
; set flags if memory address found
; INPUTS
;  ebx=operand/address
;  edi=stuff ptr for hex or label
;  al = 01 - jmp address
;       02 - call address
;       20 - immediate
;        0 - decode [dr_op_size] ptr
; OUTPUT
;    [operand] - set to ebx
;    [operand_type] set to 1-jmp 2-call 4-bytePTR 8-wordPTR 10-dwordPTR
;
process_operand_data:
  xor	eax,eax
process_operand_address:
  mov	[operand],ebx
  cmp	al,20h			;is this immediate data
  jne	pod_20			;jmp if not immediate
;this is an immediate value, check if possible address
;  cmp	ebx,08000000h
;  jb	pod_80			;jmp if not in address range
;  cmp	ebx,09000000h
;  ja	pod_80			;jmp if not in address range
  jmp	short pod_40
;lookup size of data item
pod_20:
;this is a possible address, check if type known
  or	al,al
  jnz	pod_40			;jump if addr type known
;  push	eax
  mov	eax,[dr_op_size]
  mov	eax,[eax]		;get size string
  cmp	al,'b'
  je	pod_byte
  cmp	al,'w'
  je	pod_word
  mov	al,10h			;dword
  jmp	short pod_20
pod_byte:
  mov	al,04h			;byte
  jmp	short pod_20
pod_word:
  mov	al,08h			;word
pod_40:
  or	byte [operand_type],al
;check if symbol table lookup available
; ebx = address
  mov	eax,[symbol_process]
  or	eax,eax
  jz	pod_80
;call symbol table lookup
  push	ebx
  push	edi
  mov	edi,ebx
  call	eax
  pop	edi
  pop	ebx
  or	eax,eax			;check if found
  jnz	pod_80			;jmp if symbol not found
  call	str_move		;move symbol
  jmp	short pod_exit
pod_80:
  call	bin_to_hexascii_h
pod_exit:
  ret
  

;----
  [section .data]
dr_op_size:	dd	0
  [section .text]
  
