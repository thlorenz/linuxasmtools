;display variables
;display_mode	resd 1	;0=code 1=data 2=bss
;section_top_offset resd 1	;offset from load_image_ptr
;win_top_offset     resd 1	;offset currently at top of window
;select_bar_offset  resd 1	;offset of select bar
;section_end_offset resd 1	;end of current section;
;
;display_lines      resb 1	;lines for page , add 4 if menu included
;top_of_win_line    resb 1	;line# at top of page, (menu above)
;end_of_win_line    resb 1	;start of memu at end of page
;top_of_win_column  resb 1
;comment_column	    resb 1
;end_of_win_column  resb 1
;

page_setup:
  xor	eax,eax
  mov	[section_top_offset],eax
  mov	[display_mode],byte 0

  mov	edx,[preamble+pre.elf_phys_exec_entry]
  call	physical2offset
  mov	[win_top_offset],ebp
  mov	[select_bar_offset],ebp
;
  mov	eax,[preamble+pre.elf_phys_bss_end]	;get code end
  sub	eax,[preamble+pre.elf_phys_top]		;compute offset
  mov	[section_end_offset],eax

  mov	[top_of_win_line],byte 3 ;start of page on line 3
  mov	al,[crt_rows]
  sub	al,4			;remove menu lines
  mov	[display_lines],al
  add	al,2
  mov	[end_of_win_line],al

  mov	[top_of_win_column],byte 1
  mov	[comment_column],byte 35
  mov	al,[crt_columns]
  mov	[end_of_win_column],al
  ret

;-------------------------------------------------------------
display_page:
  mov	ebp,[win_top_offset]
  mov	ah,[top_of_win_line]
  mov	[dp_row],ah
  mov	[symbol_process],dword symbol_handler ;sym lookup
dp_lp1:
  mov	eax,[ct1]		;get normal color
  mov	[line_color],eax	;set color
  mov	edi,lib_buf
  mov	ah,[dp_row]
  mov	al,[top_of_win_column]	;column for cursor
  call	move_cursor
  cmp	ebp,[section_end_offset] ;out of data?
  jb	dp_02			;jmp if more data
  jmp	dp_60			;jmp if at end of section
dp_02:
  mov	ah,[dp_row]
  cmp	ah,[end_of_win_line]	;end of display area
  ja	dp_90j			;jmp if at end of display
  call	offset2flag_ptr		;sets edx to flags
  mov	cl,[edx]		;get flag
  cmp	cl,7fh			;is this the gap?
  jne	dp_05
;we are at a gap, move past
dp_gap_lp:
  inc	ebp
  inc	edx
  cmp	byte  [edx],7fh
  je	dp_gap_lp		;loop till end of gap
;display gap message
  push	edx
  mov	esi,gap_msg
  mov	edi,lib_buf
  call	str_move
  call	write_line
  call	set_map
  pop	edx
  mov	edi,lib_buf
  mov	ah,[dp_row]
  cmp	ah,[end_of_win_line]	;end of display
  ja	dp_90j  
dp_05:
  mov	cl,[edx]		;get byte
  test	cl, 30h			;check if label here
  jz	dp_10			;jmp if no label here
  call	dp_label		;stuff label in lib_buf
  call	write_line
  mov	ah,[dp_row]
  cmp	ah,[end_of_win_line]	;end of display area
  jbe	dp_09			;jmp if more lines on display
dp_90j:
  jmp	dp_90			;jmp if at end of display
dp_09:
  mov	al,[top_of_win_column]	;column for cursor
  call	move_cursor
  mov	edi,lib_buf		;restart line ptr
;build line
dp_10:
  call	set_map			;add offset to map array
  call	build_line
;display contents of lib_buf
dp_20:
  call	write_line
  jmp	dp_lp1
;we are out of data, fill to end of display
dp_60:
  mov	[last_offset],ebp
  mov	ah,[dp_row]
  cmp	ah,[end_of_win_line]	;end of display
  ja	dp_95			;jmp if at end of display
;write blank line
  mov	al,[top_of_win_column] ;get starting column
dp_70:
  mov	byte [edi],' '
  inc	edi			;bump stuff ptr
  inc	al			;bump column
  cmp	al,[end_of_win_column]
  jb	dp_70
  jmp	short dp_20		;go write blank line
  
dp_90:
  mov	[last_offset],ebp
dp_95:
  ret
;-----------------
  [section .data]
gap_msg: db ' ---- load block gap ----',0ah,0
  [section .text]

;-------------------------------------------------------------
; inputs: edi = stuff end ptr
;         [lib_buf] = line of data
; 
write_line:
  mov	eax,[line_color]
  call	crt_set_color
  mov	ecx,lib_buf		;output buffer
  mov	edx,edi
  sub	edx,ecx			;compute length of write
  call	crt_write
  inc	byte [dp_row]		;bump display row
  ret
;-------------------------------------------------------------
; inputs:      
;         edi=stuff ptr
;         ebp=offset or -1 if label here
;         edx=ptr to flag image entry
;
; set map using offset in ebp, and index with row
set_map:
  xor	ebx,ebx
  mov	bl,[dp_row]	;current row to ebx
  dec	ebx		;make row  zero based
  shl	ebx,2		;convert to dword index
  add	ebx,display_map ;index into array
  mov	[ebx],ebp	;store offset
  ret

;-------------------------------------------------------------
; inputs:        
;         edi=stuff ptr
;         ebp=offset
;         edx=ptr to flag image entry
;
; output: line stored at lib_buf
;         edi points to end of line
;
build_line:
  mov	[bl_initial_offset],ebp
  mov	eax,[ct1]		;normal color
  cmp	ebp,[select_bar_offset]
  jne	bl_05			;jmp if not select bar line
  mov	eax,[ct3]		;get select bar color
bl_05:
  mov	[line_color],eax
  call	offset2physical
  mov	eax,edx
  call	dwordto_hexascii
  cmp	byte [display_mode],2	;is this bss data
  jne	bl_decode
  jmp	bl_repeat
;  mov	eax,' res'
;  stosd
;  mov	eax,'b 1 '
;  stosd
;  jmp	bl_byte2
;decode flag to find type of line
bl_decode:
  call	offset2flag_ptr		;get flag ptr in edx
  mov	al,[edx]		;get flag byte
  call	offset2code_ptr		;set edx to code dis/data
  test	al,80h			;is this code
  jnz	bl_code			;jmp if code
  test	al,04h			;is this a string
  jnz	bl_string
  test	al,08h			;is this a repeat
  jnz	bl_repeat
  test	al,1			;is this a word
  jnz	bl_word
  test	al,2			;is this a dword
  jnz	bl_dword
;assume this is a db, stuff data, bump ebp
bl_byte:
  mov	eax,' db '
  stosd
  mov	al,[edx]	;get byte
  call	byteto_hexascii
  mov	al,'h'
  stosb
bl_byte2:
  inc	ebp
  jmp	bl_81
;move dw and bump ebp by 2
bl_word:
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
  jmp	short bl_81

;fill blanks to end of display line
bl_81:
  call	compute_column		;returns column in ah
  push	ebp
  mov	ebp,[bl_initial_offset]
  call	comment_check		;add comments if found
  pop	ebp
  cmp	ah,[end_of_win_column]
  jb	bl_82			;jmp if blanks needed at end of line
  je	bl_90			;jmp if line lenght ok
;line is too long, truncate
bl_81a:
  dec   edi
  dec	ah
  cmp	ah,[end_of_win_column]
  je	bl_90
  ja	bl_81a

bl_82:
  mov	al,' '
bl_83:
  stosb
  inc	ah
  cmp	ah,[end_of_win_column]	;at end
  jne	bl_83			;loop till filled
bl_90:    
  ret  	       
;----------------
  [section .data]
bl_initial_offset dd 0
  [section .text]
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
  push	ebp
  call	offset2physical
  mov	eax,edx		;physical address to eax
  call	offset2code_ptr
  mov	ebp,edx		;code ptr to ebp
  push	edi
  call	dis_one
  pop	edi
  pop	ebp		;restore offset
  mov	ecx,eax		;save ptr to dis data
  lea	esi,[eax + Dis.inst_]
  mov	al,' '
  stosb			;add space infront
  inc	esi		;move past tab
  call	compute_column	;starting column to ah
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
  dec	edi		;move back over 0ah char
  mov	eax,[ecx + Dis.inst_len]
  add	ebp,eax		;update offset to next inst
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
;  cmp	byte [esi],0	;is next byte a  zero
;  jne	ms_40		;jmp if not zero
;  mov	eax,',0  '
;  stosd			;put zero on end
;  inc	esi
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
  cmp	byte [display_mode],2
  je	mr_30		;jmp if in .bss section
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
;-------------------------------------------------------------
; inputs:;        
;         edi=stuff ptr
;         ebp=offset
;         edx=ptr to flag image entry
;
; output: lib_buf contains complete line for display
;         edi = ptr to end of display line
; put spaces in lib_buf
; add sym label or generate label
; fill lib_buf to end of display.
; update display map using row, set offset negative (label)
dp_label:
  push	ebp		;negative offset indicates label in map
  mov	ebp, -1
  call	set_map		;set map
  pop	ebp		;restore offset
  mov	eax,'    '
  stosd
;  stosd
;check if generated label or in symbol table
  test	[edx],byte 10h	;check if symbol table has label
  jnz	dl_50		;jmp if label in symbol table
;construct label from offset
  mov	al,'x'
  stosb			;put x infront
  call	offset2physical
  mov	eax,edx
  call	dwordto_hexascii
  mov	al,':'
  stosb
  call	compute_column	;returns column in ah
  jmp	short dl_80
;get label from symbol table
dl_50:
  push	edi
  call	offset2physical
  mov	[label_adr],edx
  mov	edi,label_adr	;move physical address to edi
  mov	ecx,4
  xor	edx,edx		;use hash
  call	hash_lookup
  pop	edi
  add	esi,5		;move to label text
  call	str_move	;move label
  cmp	byte [edi -1],':'
  je	dl_60		;jmp label has ":"
  mov	al,':'
  stosb
dl_60:
;compute current display column
  call	compute_column	;returns column in ah
;fill blanks to end of line, bl=current column
dl_80:
  mov	al,' '
dl_82:
  stosb
  inc	ah
  cmp	ah,[end_of_win_column]
  jne	dl_82			;loop till line filled    
  ret
;-------------------------------------------------------------
; input: edi = current stuff point in lib_buf
; output: ah=column
;
compute_column:
  mov	eax,edi
  sub	eax,lib_buf
  add	al,[top_of_win_column]
  mov	ah,al
;  dec	eax		;adjust for columns starting at 1
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
;-------------------------------------------------------------
  [section .data]
dp_row		dd 0	;current display row 1+
last_offset	dd 0	;last offset displayed
label_adr	dd 0	;used for hash_lookup
line_color	dd 0
label_build	times 12 db 0
;display_map row 1 = 0 (menu)
;            row 2 = 0 (menu)
;            row 3 = offset of label(-1)
;            etc.
display_map	times 50 dd 80000000h ;offsets, labels(-1) 80000000h = menu area or not used

  [section .text]
%include "comment.inc"

