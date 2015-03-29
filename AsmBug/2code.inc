;---------------------  code window --------------------------------
;
; colors:
;CodeMenuBColor=navy
;CodeMenuBButton=grey
;CodefMenuForButton=navy
;CodeBColor=navy
;CodeFColor=white
;CodeExecFColor=skyblue
;CodeExecBColor=navy
;CodeSelFColor=pink
;CodeSelBColor=navy
;CodeBrkFColor=red
;CodeBrkBColor=navy
;CodeScrollBColor=maroon
;CodeScrollFColor=pink
;
; location 11,0
;   row 11
;   column 0
;
;   width = 65 characters
;   height = screen  size - 11

 extern symbol_process
 extern string_lookup

code_win_setup:
  mov	eax,[ebp+win.s_text_rows]
;  dec	eax
  mov	[code_end_line],eax
  mov	[symbol_process],dword symbol_handler ;sym lookup

  push	ebp
  mov	edx,[preamble+pre.elf_phys_code_start]	;get previous window top adr
  call	physical2offset
  mov	[code_adr_offset],ebp	;set preliminary window top

  mov	edx,[preamble+pre.elf_phys_bss_end]	;get previous window top adr
  call	physical2offset
  mov	[load_end_offset],ebp	;set end of all display data
  pop	ebp
;setup the scroll bar
  cmp	[FontFix],byte 0
  je	cws_50		;jmp if draw characters ok
  mov	eax,'*|-*'
  mov	[up_char],eax
cws_50:  
  call	build_scroll_bar
  call	fill_mouse_scroll
  ret

;-------------------------------------------------------
fill_mouse_scroll:
  mov	esi,csb_data
  mov	ecx,11		;starting row
;set up scroll region
  mov	[scroll_up],byte cl
  lodsb			;get up_char
  inc	ecx
  mov	[scroll_up+1],byte cl
;set pgup scroll region
  lodsb			;get first body char
  inc	ecx
  mov	[scroll_pgup],cl
fms_lp1:
  lodsb
  inc	ecx
  cmp	al,[center_char]
  jne	fms_lp1		;loop till center found
  mov	al,cl
  dec	al
  mov	[scroll_pgup+1],al
;set pgdn scroll region
  mov	[scroll_pgdn],cl
fms_lp2:
  lodsb
  inc	ecx
  cmp	al,[down_char]
  jne	fms_lp2
  mov	al,cl
  dec	al
  mov	[scroll_pgdn+1],al
;set down scroll region
  mov	[scroll_down],cl
  inc	cl
  mov	[scroll_down+1],cl
  ret
;---------------------------------------------------------
build_scroll_bar:
; build scroll bar
  mov	edi,csb_data	;get stuff ptr
  mov	ebx,[code_end_line]
  sub	ebx,12		;compute scroll bar length
  sub	ebx,byte 3	;remove other characters
  mov	edx,ebx
  shr	ebx,1		;divide by 2
  mov	al,[up_char]	;01
  stosb
  mov	ecx,ebx
  mov	al,[body_char]	;19h
  rep	stosb
  mov	al,[center_char]	;02
  stosb
  mov	al,[body_char]	;19h
  mov	ecx,ebx
  test	dl,1
  jz	sc_05
  inc	ecx
sc_05:
  rep	stosb
  mov	al,[down_char]	;01
  stosb

  mov	eax,edi
  sub	eax,csb_data	;compute length of scroll bar
  mov	[csb_data -1],al ;store length of scroll bar

  mov	al,0
  stosb			;terminate table
  ret

;----------------------------------------------------------------
  [section .data]
;---------------
;scroll characters
up_char		db 	01
body_char	db	19h
center_char	db	02h
down_char	db	01

code_end_line	dd 0	;last legal line of display
code_adr_offset	dd 0	;current display offset at top line
load_end_offset dd 0	;end of all blocks loaded in memory
code_adr_ptr	dd 0	;ptr to code_adr_buf
code_data_ptr	dd 0	;ptr to code_data_buf
code_row	dd 0	;current display row

code_adr_buf times 60 dd 0 ;adress associated with line#
code_data_buf times 60 dd 0 ;operand associated with line#

  [section .text]
;-------------------------------------------------------
code_menu:
;display fixed window areas
  mov	ebx,[codeFColor]
  mov	ecx,[codeBColor]
  call	window_id_color
;clear area 
  mov	eax,0			;x location (col)
  mov	ebx,11			;y locatin (row)
  mov	ecx,65			;width
  mov	edx,[code_end_line]	;compute
  sub	edx,ebx			;  height
  mov	esi,1			;use current color
  call	window_clear_area
;set menu color
  mov	ebx,[codeMenuForButton]
  mov	ecx,[codeMenuBButton]
  call	window_id_color
;check if runing or dead memu's needed
  mov	al,[app_mode]
  cmp	al,4
  je	stopped_menu
  cmp	al,8
  je	dead_menu
;running menu
  mov	esi,run_menu_block
  jmp	short cm_50
dead_menu:
  mov	esi,dead_menu_block
  jmp	short cm_50 
stopped_menu:
;show code menu
  mov	esi,code_menu_block
cm_50:
  call	window_write_table
;set scroll bar color
  mov	ebx,[codeScrollFColor]
  mov	ecx,[codeScrollBColor]
  call	window_id_color
;  call	build_scroll_bar
  mov	esi,code_scroll_block
  call	window_write_table
  ret
;----------------------------------------------------------------
;input: ebp = ptr to win structure

show_code:
  test	byte [win_bit_map],1
  jz	sc_10			;jmp if no menu needed
  call	code_menu
;-- code display starts here --
sc_10:
  mov	[code_adr_ptr],dword code_adr_buf
  mov	[code_data_ptr],dword code_data_buf
  mov	byte [code_row],12

  test	byte [win_bit_map],20h
  jz	sc_12		;jmp if no centering needed
  call	center_eip	;set code_adr_offset
sc_12:
  mov	eax,[code_adr_offset]
  push	eax		;save starting code_adr_offset
sc_lp:
  mov	ebp,[code_adr_offset] ;get current offset
  cmp	ebp,[load_end_offset] ;check if at end of loads
  jb	sc_20		      ;jmp if within loads
;buld blank line for display
  mov	edi,lib_buf+100	;start of display line data
  jmp	sc_tail1	;go display blank line
;are we inside a load block?
sc_20:
  call	offset2flag_ptr	;set edx = ptr to flags
  mov	cl,byte [edx]	;get flags
  cmp	cl,7fh		;between load blocks?
  jne	sc_30		;jmp if within load secton
;we are between loads, scan forward to next section
sc_22:
  inc	edx		;bump flag ptr
  inc	ebp		;bump offset
  cmp	[edx],byte 7fh
  je	sc_22		;loop till end of fill area
  mov	[code_adr_offset],ebp	;save new offset
  call	update_adr_array
  mov	esi,gap_msg
  mov	edi,lib_buf+100
  call	str_move
  jmp	sc_tail1	;go display gap msg
;we have valid display data, check if label here
sc_30:
  and	cl,30h		;check if label here
  jz	sc_40 		;jmp if no label here    
  call	build_label
  call	pad_line_end
  call	show_line
  inc	dword [code_row]
  mov	eax,[code_row]
  cmp	eax,[code_end_line]
  jae	sc_done		;jmp if end of display
;display code
sc_40:
  call	show_dis
  jmp	short sc_tail2
;fill  end of line with blanks
sc_tail1:
  call	pad_line_end
;set normal color
  mov	ebp,win_block
  mov	ebx,[codeFColor]
  mov	ecx,[codeBColor]
  push	edi
  call	window_id_color
  pop	edi
;show line
  call	show_line
sc_tail2:
  inc	dword [code_row]
  mov	eax,[code_row]
  cmp	eax,[code_end_line]
  jb	sc_lp		;jmp
sc_done:
  pop	eax
  mov	[code_adr_offset],eax	;restore origional value
  mov	ebp,win_block
  ret
;---------------------
  [section .data]
gap_msg: db '  ---------- gap between load blocks ----------',0
  [section .text]
;-----------------------------------------------------------------
pad_line_end:  
  mov	al,' '
sc_50:
  cmp	edi,lib_buf+164
  jae	sc_52		;jmp if line filled
  stosb
  jmp	short sc_50
sc_52:
  ret
;-----------------------------------------------------------------
update_code_array:
  push	ebp
  push	edi
  push	edx
  mov	ecx,[dis_block]
  jecxz	uca_10			;jmp if no dis_block yet
  mov	eax,[ecx+Dis.operand_]
uca_10:
  mov	edi,[code_data_ptr]
  stosd
  mov	[code_data_ptr],edi
  jmp	short uaa_10
;
; entry point for label entries
update_adr_array:
  push	ebp
  push	edi
  push	edx
  mov	edi,[code_data_ptr]
  xor	eax,eax
  stosd
  mov	[code_data_ptr],edi

uaa_10:
  mov	ebp,[code_adr_offset]
  call	offset2physical
  mov	eax,edx
  mov	edi,[code_adr_ptr]
  stosd
  mov	[code_adr_ptr],edi
  pop	edx
  pop	edi
  pop	ebp
  ret
;-----------------------------------------------------------------
show_dis:
  call	show_code_adr
  mov	ebp,[code_adr_offset]
  call	offset2physical
  cmp	edx,[r1_eip]
  je	exec_color
;set normal color
  mov	ebp,win_block
  mov	ebx,[codeFColor]
  mov	ecx,[codeBColor]
  call	window_id_color
  jmp	short sd_10
;set eip color
exec_color:
  mov	ebp,win_block
  mov	ebx,[codeExecFColor]
  mov	ecx,[codeExecBColor]
  call	window_id_color
sd_10:
  mov	edi,lib_buf+100
  mov	al,' '
  stosb
  mov	ebp,[code_adr_offset]
;decode flag to find type of line
  call	offset2flag_ptr		;get flag ptr in edx
  mov	al,[edx]		;get flag byte
  call	offset2code_ptr		;set edx to code dis/data
bl_15:
  test	al,80h			;is this code
  jnz	bl_code			;jmp if code
  test	al,04h			;is this a string
  jnz	bl_string
  test	al,08h			;is this a repeat
  jnz	bl_repeat
  test	al,1			;is this a word
  jnz	sd_word
  test	al,2			;is this a dword
  jnz	bl_dword
;assume this is a db, stuff data, bump ebp
sd_byte:
  mov	eax,' db '
  stosd
  mov	al,[edx]	;get byte
  call	byteto_hexascii
  mov	al,'h'
  stosb
  inc	ebp
  jmp	bl_81
;move dw and bump ebp by 2
sd_word:
  mov	eax,' dw '
  stosd
  mov	ax,[edx]
  call	wordto_hexascii
  mov	al,'h'
  stosb
  add	ebp,byte 2
  jmp	short bl_81

bl_string:
  call	make_string
  add	ebp,ecx		;update offset
  jmp	short bl_81

bl_repeat:
  call	make_repeat
  add	ebp,ecx
  jmp	short bl_81

;disassemble code and move to lib_buf, bump ebp
bl_code:
  call	make_code
  jmp	short bl_81

;move dd and bump ebp by 4
bl_dword:
  mov	eax,' dd '
  stosd
  mov	eax,[edx]

  push	edx
  push	edi
  mov	[label_adr],eax
  mov	edi,label_adr	;move physical address to edi
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  pop	edi
  pop	edx
  or	eax,eax
  jnz	bl_dword1
;esi points to symbol name
  add	esi,byte 5
  call	str_move
  jmp	short bl_dword3

bl_dword1:
  mov	eax,[edx]	;get value    
  call	check_range	;check if possible label
  jc	bl_dword2	;jmp if out of range
  mov	[edi],byte 'x'
  inc	edi
  call	dwordto_hexascii
  jmp	short bl_dword3  

;insert non label value
bl_dword2:  
  call	dwordto_hexascii
  mov	al,'h'
  stosb
bl_dword3:
  add	ebp,byte 4
bl_81:
  call	update_code_array
  mov	[code_adr_offset],ebp
;fill blanks to end of line
  mov	al,' '
bl_83:
  cmp	edi,lib_buf+156
  jae	bl_84		;jmp if line filled
  stosb
  jmp	short bl_83
bl_84:
  mov	ebp,win_block
  sub	edi,lib_buf+100		;compute length of line
  cmp	edi,63-8
  jbe	bl_85			;jmp if line length ok
  mov	edi,63-8
bl_85:
  mov	edx,[code_row]		;get row
  mov	ecx,8  			;set column
  mov	esi,lib_buf+100		;data buffer
  call	window_write_line	;show line
bl_90:    
  ret  	       
;----------------
  [section .data]
next_eip	dd 0
  [section .text]
;-----------------------------------------------------------------
;-------------------------------------------------------------
; inputs:;        
;         edi=stuff ptr
;         ebp=offset
;         edx=ptr to flag image entry
;
; output: lib_buf contains complete line for display
;         edi = ptr to end of display line
;         ebp = updated to point at next instruction
make_code:
  call	do_dis
  mov	ecx,eax		;save ptr to dis data
  lea	esi,[eax + Dis.inst_]
  mov	al,' '
  stosb			;add space infront
  inc	esi		;move past tab
  mov	ah,9		;starting column to ah
mc_lp1:
  lodsb			;get byte
  or	al,al
  jz	mc_40		;jmp if done
  cmp	al,09h		;tab?
  jne	mc_tail		;jmp if not  tab
mc_tab:
  mov	byte [edi],' '	;insert space
  inc	edi
  inc	ah
  test	ah,07
  jnz	mc_tab
  jmp	short mc_lp1
mc_tail:
  stosb			;store character
  inc	ah
  jmp	short mc_lp1  
mc_40:
  push	ecx
  push	ebp
  dec	edi		;move back over 0ah char
  call	comment_check
  pop	ebp
  pop	ecx
  mov	eax,[ecx + Dis.inst_len]
  add	ebp,eax		;update offset to next inst
;  mov	[code_adr_offset],ebp
;check if this line is at eip
  mov	eax,[r1_eip]
  cmp	eax,[line_phys_adr]
  jne	mc_50		;jmp if not at eip
  call	offset2physical
  mov	[next_eip],edx	;save address of next inst.
mc_50:
  ret
;-------
  [section .data]
line_phys_adr:	dd 0
  [section .text]
;-------------------------------------------------------------
; input: ebp = offset
; output: eax=dis block ptr
;         ebp unchanged
;
do_dis:
  push	ebp
  call	offset2physical
  mov	[line_phys_adr],edx ;save physical adr
  mov	eax,edx		;physical address to eax
  call	offset2code_ptr
  mov	ebp,edx		;code ptr to ebp
  push	edi
  call	dis_one
  mov	[dis_block],eax
  pop	edi
  pop	ebp		;restore offset
  ret
;------------
  [section .data]
dis_block dd 0
  [section .text]
;-------------------------------------------------------------
; inputs:;        
;         edi=stuff ptr
;         ebp=offset
;         edx=ptr to flag image entry
;
; output: lib_buf contains complete line for display
;         edi = ptr to end of display line
;         ecx = number of bytes in string

make_string:
  mov	eax,' db '
  stosd
  mov	al,22h		;quote
  stosb
  mov	ecx,40		;max string length
  mov	esi,edx		;esi = ptr to code
  call	offset2flag_ptr ;set edx = flag ptr
ms_lp:
  movsb			;move byte of string data
  inc	edx		;move to next flag
  cmp	[edx],byte 44h	;check for string body
  jne	ms_30		;jmp if end of string
  dec	ecx
  jnz	ms_lp		;loop back if room for more
ms_30:
  mov	al,22h		;quote
  stosb			;terminate string
;compute number of bytes stored
ms_40:
  call	offset2code_ptr	;recompute starting offset -> edx
  sub	esi,edx		;compute number of bytes stored
  mov	ecx,esi
  ret

;-------------------------------------------------------------
; inputs:;        
;         edi=stuff ptr
;         ebp=offset
;         edx=ptr to flag image entry
;
; output: lib_buf contains complete line for display
;         edi = ptr to end of display line
;         ecx = number of bytes in string
make_repeat:
  mov	eax,' tim'
  stosd
  mov	eax,'es  '
  stosd

  xor	eax,eax		;set count to  zero
  mov	esi,edx		;esi = ptr to code   
  call	offset2flag_ptr ;set edx = flag ptr
mr_lp:
  inc	eax
  inc	edx
  cmp	[edx],byte 48h	;is next byte a repeat
  je	mr_lp
;
  call	dwordto_hexascii ;store count
  mov	eax,'h db'
  stosd			;put "h" at end of count
  mov	al,' '
  stosb
  xor	eax,eax
  mov	al,[esi]	;get repeat value
mr_30:
  call	byteto_hexascii
  mov	al,'h'
  stosb

;compute number of bytes stored
mr_40:
  mov	eax,edx		;save flag ptr
  call	offset2flag_ptr	;recompute starting offset -> edx
  sub	eax,edx		;compute number of bytes stored
  mov	ecx,eax
  ret

;-----------------------------------------------------------------
;input: [Breaks] - breakpoints
;       codeBrkFColor,codeBrkBColor
;       codeBColor,codeFColor
;       [code_adr_offset]
;output: [sca_physical]  = physical address
;
show_code_adr:
  mov	edi,lib_buf+100
  mov	ebp,[code_adr_offset]
  call	offset2physical
  mov	eax,edx
  mov	[sca_physical],eax
  call	dwordto_hexascii
;check if breakpoint at this address
  mov	esi,Breaks
  mov	ebx,[sca_physical]
sca_lp:
  lodsd
  or	eax,eax
  jz	sca_norm	;jmp if no breaks found
  inc	esi		;move past value in break list
  cmp	eax,ebx
  jne	sca_lp		;jmp if no match
;break at this address
  mov	ebp,win_block
  mov	ebx,[codeBrkFColor]
  mov	ecx,[codeBrkBColor]
  call	window_id_color
  jmp	short sca_20
sca_norm:
  mov	ebp,win_block
  mov	ebx,[codeFColor]
  mov	ecx,[codeBColor]
  call	window_id_color

sca_20:
  mov	edi,lib_buf+108	;end of data
  call	show_line
  ret
;------------
  [section .data]
sca_physical dd 0
  [section .text]
;-----------------------------------------------------------------
;input: [code_adr_offset]
;       edx = flag ptr
;output: edi points to end of label
build_label:
  push	edx
  mov	ebp,win_block
  mov	ebx,[codeFColor]
  mov	ecx,[codeBColor]
  call	window_id_color

  call	update_adr_array
  mov	edi,lib_buf + 100	;build area
  pop	edx		;restore flag ptr
;check if generated label or in symbol table
  test	[edx],byte 10h	;check if symbol table has label
  jnz	dl_50		;jmp if label in symbol table
;construct label from offset
  mov	al,'x'
  stosb			;put x infront
  mov	ebp,[code_adr_offset]
  call	offset2physical
  mov	eax,edx
  call	dwordto_hexascii
  mov	al,':'
  stosb
  jmp	short dl_76
;get label from symbol table
dl_50:
  push	edi
  mov	ebp,[code_adr_offset]
  call	offset2physical
  mov	[label_adr],edx
  mov	edi,label_adr	;move physical address to edi
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  pop	edi
  or	esi,esi		;was label found?
  jnz	dl_60		;jmp if label found
  mov	esi,fix_me	;get program bug signal
  jmp	short dl_62
dl_60:
  add	esi,5		;move to label text
dl_62:
  call	str_move	;move label
  cmp	byte [edi -1],':'
  je	dl_76		;jmp label has ":"
  mov	al,':'
  stosb
dl_76:
;lib_buf + 100 has label
  ret
;------------
  [section .data]
label_adr	dd 0
fix_me: db 'FiX_ME ------',0
  [section .text]
;-----------------------------------------------------------------
; input: lib_buf+100 has data, edi=end ptr
show_line:
  mov	ebp,win_block
  sub	edi,lib_buf+100		;compute length of line
  mov	edx,[code_row]		;get row
  xor	ecx,ecx			;set column
  mov	esi,lib_buf+100		;data buffer
  call	window_write_line	;show line
  ret
;-----------------------------------------------------------------
;input: [r1_eip]
;output: [code_adr_offset]
center_eip:
  mov	edx,[r1_eip]
  mov	ebx,edx			;save phys adr of eip
  call	physical2offset
  call	offset2flag_ptr		;set edx=ptr to flags
; [flag_image_ptr] - points to top of flags
;flag image table structure, bit definitions
;
; 0xxx xxxx - data
; 1xxx xxxx - code
;
; x0xx xxxx - start of data/instruction
; x1xx xxxx - data/instruction body
;
; xx00 xxxx - no label here
; xx01 xxxx - symbol table has label for this location
; xx10 xxxx - label hit, type in low 4 bits
; xx11 xxxx - symbol table has label & hits, type in low 4 bits
;
  mov	ecx,5	;max backtrack count
ce_lp:
  cmp	ebx,[preamble+pre.elf_phys_code_start]
  jbe	ce_50		;jmp if at top of .code
;  cmp	edx,[flag_image_ptr]
;  jbe	ce_50		;jmp if at top of data
  dec	edx		;move flag_image ptr
  dec	ebx		;move physical address
  test	byte [edx],40h
  jnz	ce_lp		;loop till inst start
;at start of inst/data
  test	byte [edx],30h	;check if label here
  jz	ce_10		;jmp if no label here
  dec	ecx
  jecxz	ce_50		;jmp if loop expired
ce_10:
  loop	ce_lp
ce_50:
  sub	edx,[flag_image_ptr]	;compute offset
  mov	[code_adr_offset],edx
  ret  
;-------------------------------------------------------------
;called by dis_one when possible symbol encountered
; input: edi = physical address or operand value
; output: eax = 0 if symbol found  esi=string ptr
;
symbol_handler:
  push	ebp
;this label could be a dynamic symbol that fails range
;or map test, check symbol table first
  mov	[label_adr],edi
  mov	edi,label_adr	;move physical address to edi
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  or	esi,esi
  jz	sh_check	;jmp if no sym tbl entry
  add	esi,5
  xor	eax,eax		;signal that label was found
  jmp	short sh_exit

sh_check:
  mov	eax,[label_adr]	;get operand address in eax
  call	check_range	;check if within range
  jc	sh_90		;jmp if out of  range
  mov	edx,eax
  call	physical2offset
  call	offset2flag_ptr
  mov	al,[edx]	;get flag
  test	al,10h		;check if symbol table has label
  jnz	sh_90		;jmp if symbol table had entry (error)
  test	al,20h
  jz	sh_90		;jmp if no label here
;make label for this location
  mov	eax,[label_adr]	;physical address -> eax
  mov	edi,label_build
  mov	[edi],byte 'x'
  inc	edi
  call	dwordto_hexascii
  mov	[edi],byte 0
  mov	esi,label_build
  xor	eax,eax		;signal that label was found
  jmp	short sh_exit
sh_90:
  or	byte al,1	;set flag for no label found
sh_exit:
  pop	ebp
  ret
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
  call	offset2physical	;in: ebp=offset  out:edx=physical address
  mov	eax,edx
  call	string_lookup	;in: eax=key  out: ecx=0 if fail, else esi=string ptr
  pop	eax		;restore current column (ah)
  jecxz	cc_exit
;check if we are at insert column
  mov	al,20h		;space char
cc_lp1:
  cmp	ah,63		;check if column beyond window
  jae	cc_exit		;exit if no  room for comment
  cmp	ah,30		;comment column
  jae	cc_insert
  stosb
  inc	ah
  jmp	short cc_lp1	;loop till column xx found
;we are at insert point for comment
cc_insert:
  lodsb
  or	al,al
  jz	cc_exit
  stosb			;move char
  inc	ah
  cmp	ah,63		;end of win column
  jb	cc_insert	;continue if not at end yet
cc_exit:
  ret
;---------------
  [section .data]
label_build	times 12 db 0

code_menu_block:
  db 12
  dw 01		;column
  dw 11		;row
  db 3		;length
  db ' ? '

  db 12
  dw 05		;column
  dw 11		;row
  db 2		;length
  db 'Go'

  db 12
  dw 08		;column
  dw 11		;row
  db 4		;length
  db 'Step'

  db 12
  dw 13		;column
  dw 11		;row
  db 5		;length
  db 'stepO'

  db 12
  dw 19		;column
  dw 11		;row
  db 4		;length
  db 'Prep'

  db 12
  dw 24		;column
  dw 11		;row
  db 4
  db 'Find'

  db 12
  dw 59		;column
  dw 11		;row
  db 4		;length
  db 'Quit'

  db 0		;end of table

run_menu_block:
;  db 12
;  dw 00		;column
;  dw 11		;row
;  db 7		;length
;  db 'running'

  db 12
  dw 08		;column
  dw 11		;row
  db 4		;length
  db 'Stop'

  db 12
  dw 13		;column
  dw 11		;row
  db 5		;length
  db 'Kill '

  db 12
  dw 19		;column
  dw 11		;row
  db 4		;length
  db 'Prep'

  db 12
  dw 24		;column
  dw 11		;row
  db 4
  db 'Find'

  db 12
  dw 59		;column
  dw 11		;row
  db 4		;length
  db 'Quit'

  db 0		;end of table

dead_menu_block:
;  db 12
;  dw 01		;column
;  dw 11		;row
;  db 7		;length
;  db 'dead!!!'

  db 12
  dw 08		;column
  dw 11		;row
  db 4		;length
  db '----'

  db 12
  dw 13		;column
  dw 11		;row
  db 5		;length
  db '-----'

  db 12
  dw 19		;column
  dw 11		;row
  db 4		;length
  db 'Prep'

  db 12
  dw 24		;column
  dw 11		;row
  db 4
  db 'Find'

  db 12
  dw 59		;column
  dw 11		;row
  db 4		;length
  db 'Quit'

  db 0		;end of table

 
code_scroll_block:
 db 8	;write down
 dw 64	;column 64
 dw 12	;row
 db 0	;xx chars
; db 01,19h,19h,19h,02,02,19h,19h,19h,01
csb_data:
 times 80 db 0
 db 0	;end of  table

  [section .text]

