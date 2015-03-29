;-------------- memory window --------------------
;
; colors:
;  MemMenuForButton=black
;  MemMenuBakButton=skyblue
;  MemBColor=blue
;  MemFColor=white
;  MemScrollBColor=violet
;  MemScrollFColor=pink
;
; location 24,0
;  column = 24
;  row =0
;  width = 41 characters
;  rows = 11
;
;MemWinAdr=
; ebx  4
; ecx  8
; edx  12
; esi  16
; edi  20
; ebp  24
; eax  28
; r1_ds 32
; r1_es 36
; r1_fs 40
; r1_gs 44
; r1_old_eax 48
; eip  52
; r1_cs 56
; r1_flags 60
; esp  64

  extern hash_lookup
  extern byteto_hexascii
  extern wordto_hexascii
  extern trace_peek
  extern dword_to_lpadded_ascii
;----------------------------------------------------------------
mem_win_setup:
  mov	edx,[MemWinAdr]	;get display address
  or	edx,edx
  jnz	nws_50		;jmp if address set
  mov	al,2			;writable flag
  call	find_pheader_type
  jz	mws_30		;jmp if no data section
  mov	edx,[ebx+head.phys_start]
  jmp	short nws_40
mws_30:
  mov	edx,[preamble+pre.elf_phys_top]
nws_40:
  mov	[MemWinAdr],edx
nws_50:
;check if FontFix needed
  cmp	[FontFix],byte 0
  je	nws_80		;jmp if using draw characters
  mov	esi,char_scroll
  mov	edi,msb_stuff
  mov	ecx,10
  rep	movsb
nws_80:
  ret
;----------------------------------------------------------------
  [section .data]

char_scroll:
 db "*|||--|||*"

memwin_mode	dd 1	;1=db 2=dw 4=dd (must be dword)
mem_adr		dd 0	;current display address
mline_adr_ptr	dd 0	;ptr to mline_adr_buf
mline_data_ptr	dd 0	;ptr to mline_data_buf
mline_row	dd 0	;current display row

mem_buf	times 1 dd 0	;data read from app
mline_adr_buf times 10 dd 0 ;adress associated with line#
mline_data_buf times 10 dd 0 ;data associated with line#

  [section .text]

;---------------------------------------------------------------
mem_menu:
;display fixed window areas
  mov	ebx,[memFColor]
  mov	ecx,[memBColor]
  call	window_id_color
;clear area 
  mov	eax,24			;x location (col)
  xor	ebx,ebx			;y locatin (row)
  mov	ecx,41			;width
  mov	edx,11			;height
  mov	esi,1			;use current color
  call	window_clear_area

;app_mode ;4=app stopped  8=app died 12=running  16=stepOver
  cmp	[app_mode],byte 4 ;stopped?
  je	mm_50

  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color

  mov	al,[app_mode]
  cmp	al,12
  jae	mm_run

  mov	esi,dead_msg
  mov	edi,dead_msg_len
  jmp	short mm_state

mm_run:
  mov	esi,running_msg
  mov	edi,running_msg_len
mm_state:
  mov	ecx,30		;column
  mov	edx,5		;row
  call	window_write_line

  and	[win_bit_map],byte ~8
  jmp	mm_exit		;
;stopped state memory window
mm_50:
  mov	ebx,[memMenuForButton]
  mov	ecx,[memMenuBakButton]
  call	window_id_color

  mov	esi,mem_menu_block
  call	window_write_table

  mov	ebx,[memScrollFColor]
  mov	ecx,[memScrollBColor]
  call	window_id_color

  mov	esi,mem_scroll_block
  call	window_write_table
mm_exit:
  ret
;----------------------------------------------------------------
show_memory:
  test	byte [win_bit_map],1
  jz	sm_10			;jmp if menu in place
  call	mem_menu
sm_10:
  test	[win_bit_map],byte 8
  jnz	sm_15			;jmp if memory dispay
  jmp	sm_exit
sm_15:
  call	show_adr_box

;display data for window
  mov	ebx,[memFColor]
  mov	ecx,[memBColor]
  call	window_id_color

  mov	[mline_row],byte 1		;starting display row
  mov	[mline_adr_ptr],dword mline_adr_buf
  mov	[mline_data_ptr],dword mline_data_buf
;read data from app and display each line
sm_lp:
  mov	edx,[mem_adr]
  mov	esi,mem_buf
  call	trace_peek		;read dword of data
  pushf
  call	add_label_if		;add label if found
  mov	edi,lib_buf+100		;setup build buffer
;check if add_label_if moved us to end of window
  mov	eax,[mline_row]
  cmp	al,11
  jb	sm_38			;jmp if more display room
  popf
  jmp	short sm_exit
sm_38:
  popf
  jz	sm_40			;jmp if good read
;no data here, show message
  mov	esi,no_data_txt
  mov	ecx,no_data_txt_length
  rep	movsb
  jmp	short sm_60		;go display line
;display one line of data
sm_40:
  call	build_line		;build line in lib_buf+100
sm_60:
  mov	ecx,25			;column
  call	display_edi
  call	update_array
;move to next data item
  movzx eax,byte [memwin_mode]
  add	[mem_adr],eax		;move to next address
  inc	dword [mline_row]
  mov	eax,[mline_row]
  cmp	al,11
  jb	sm_lp			;loop till done
sm_exit:
  ret  
;-----------------------------
add_label_if:
  mov	edi,mem_adr	;move physical address to edi
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  or	eax,eax
  jnz	cl_50		;jmp if no label here
;esi points to symbol name
  mov	edi,lib_buf+100
  add	esi,byte 5
  call	str_move
  mov	ecx,25			;column
  call	display_edi
  call	update_array
  inc	dword [mline_row]
cl_50:
  ret
;----------------------------
update_array:
;update map array
  mov	edi,[mline_adr_ptr]
  mov	eax,[mem_adr]
  stosd
  mov	[mline_adr_ptr],edi

  mov	edi,[mline_data_ptr]
  mov	eax,[mem_buf]
  stosd
  mov	[mline_data_ptr],edi
  ret
;-------------------------------
; input: ecx=column for display
display_edi:
  mov	ebp,win_block
  cmp	edi,lib_buf+137
  jae	sm_70			;jmp if line built
  mov	al,' '
  stosb
  jmp	short display_edi
sm_70:
  sub	edi,lib_buf+100		;compute length of line
  cmp	edi,37
  jbe	sm_80			;jmp if line size ok
  mov	edi,37			;truncate line
sm_80:
  mov	edx,[mline_row]		;get row
  mov	esi,lib_buf+100		;data buffer
  call	window_write_line	;show line
  ret
;------------------------------------------------------------

show_adr_box:
;check if register tracking enabled
  mov	eax,[MemWinAdr]		;get address
  cmp	eax,64
  ja	sm_20			;jmp if normal address
  call	show_mem_reg
  jmp	short sm_30
;display address in menu area
sm_20:
  mov	[mem_adr],eax		;store address
  call	show_MemWinAdr
sm_30:
  ret
;---------------------------------------------------
; eax = value to show
;
show_MemWinAdr:
  mov	ebp,win_block
  push	eax			;save value
  mov	ebx,[memMenuForButton]
  mov	ecx,[memMenuBakButton]
  call	window_id_color
  pop	eax			;restore value

  push	eax			;save value
  mov	edi,mem_stuff2
  call	dwordto_hexascii
  pop	eax			;restore value

  push	ebp
  mov	edi,mem_stuff3
  mov	cl,11			;number of char's
  or	eax,eax
  jns	sm_positive
  neg	eax
  mov	byte [edi],'-'
  inc	edi
  mov	cl,10
sm_positive:
  mov	ch,'0'			;pad char
  call	dword_to_lpadded_ascii
  pop	ebp

  mov	esi,mem_menu_adr
  call	window_write_table
  ret
;---------------
  [section .data]
mem_menu_adr:
  db 12		;write text
  dw 40		;column
  dw 0		;row
  db mma_len
mma_string:
  db '0x'
mem_stuff2:
  times 8 db ' '
  db ' ('
mem_stuff3:
  times 11 db ' '
  db ') '
mma_len equ $ - mma_string

 db 0	;end of table
  [section .text]
;---------------------------------------------------
; lookup up register contents and set for display
; also, show reg name
;
show_mem_reg:
  mov	ebx,[memMenuForButton]
  mov	ecx,[memMenuBakButton]
  call	window_id_color
  mov	eax,[MemWinAdr]
  add	eax,regs_1		;compute ptr to address
  mov	eax,[eax]		;get address from register
  mov	[mem_adr],eax
;display register name
  mov	esi,[MemWinAdr]
  add	esi,reg_list
  mov	edi,mem_stuff1
  movsb
  movsb
  movsb

  mov	esi,mem_menu_reg
  call	window_write_table
  ret
;---------------
  [section .data]
mem_menu_reg:
  db 12
  dw 40		;column
  dw 0		;row
  db 3		;length
mem_stuff1:
  db '   '

 db 4	;fill
 dw 43	;column
 dw 0	;line
 db 21	;length of fill
 db ' '	;fill char
  db 0	;end of table
  [section .text]
;------------------------------------------------------
  [section .data]
mem_menu_block:
  db 12
  dw 25		;column
  dw 0		;row
  db 3		;length
  db ' ? '

  db 12
  dw 29		;column
  dw 0		;row
  db 2		;length
  db 'dB'

  db 12
  dw 32		;column
  dw 0		;row
  db 2		;length
  db 'dW'

  db 12
  dw 35		;column
  dw 0		;row
  db 2		;length
  db 'dD'

  db 12
  dw 38		;column
  dw 0		;row
  db 1		;length
  db '<'

  db 0		;end of table
 
mem_scroll_block:
 db 8	;write down
 dw 64	;column 64
 dw 1	;row
 db 10	;10 chars
msb_stuff:
 db 01,19h,19h,19h,02,02,19h,19h,19h,01
 db 0	;end of  table

regtxt_ptrs:
 dd ebx_txt
 dd ecx_txt
 dd edx_txt
 dd esi_txt
 dd edi_txt
 dd ebp_txt
 dd eax_txt
 dd 0  
 dd 0
 dd 0
 dd 0
 dd 0
 dd eip_txt
 dd 0
 dd 0
 dd esp_txt

no_data_txt:
 db 'address invalid'
no_data_txt_length equ $ - no_data_txt

running_msg: db ' ** APP RUNNING ** '
running_msg_len equ $ - running_msg
dead_msg:    db ' ** APP DEAD **'
dead_msg_len equ $ - dead_msg

  [section .text]
;------------------------------------------------------------
build_line:
  mov	edi,lib_buf+100		;build area
  mov	al,' '
  stosb
  stosb
  mov	eax,[mem_adr]

  call	dwordto_hexascii	;insert address
  mov	al,' '
  stosb				;store space

  cmp	[memwin_mode],byte 2	;check if word
  jb	bl_byte
  je	bl_word
;must be dword
  mov	eax,' dd '
  stosd
  mov	eax,[mem_buf]		;get data
  call	dwordto_hexascii

  push	edi
  mov	edi,mem_buf	;move physical address to edi
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  pop	edi
  or	eax,eax
  jnz	bl_exit		;exit if no label

  mov	al,'('
  stosb
  add	esi,byte 5
  call	str_move
  mov	al,')'
  stosb
  jmp	short bl_exit
;process word data
bl_word:
  mov	eax,' dw '
  stosd
  mov	eax,[mem_buf]		;get data
  call	wordto_hexascii
  jmp	short bl_exit
;process byte
bl_byte:
  mov	eax,' db '
  stosd
  mov	eax,[mem_buf]		;get data
  push	eax
  call	byteto_hexascii
  mov	al,' '
  stosb
  stosb
  mov	al,22h
  stosb
  pop	eax
  stosb
  mov	al,22h
  stosb
bl_exit:
  ret    


;--------------------------------------------------------------

