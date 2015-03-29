

  [section .text]
;**********  elf_prep.asm *************************

; elf_prep is helper program to assist disassembly
; files are stored in the current directory by elf_prep:
;   abug_header.dat  - status of last executable disassembled
;   abug_image.dat    - load image of last executable
;   abug_fimage.dat   - flags image describing executable
;   abug_sym.dat      - symbol table for last executable
;   abug_externs.txt  - list of extern's if file used dynamic lib
;   abug_lib.txt      - list of dynamic libraries used
;   abug_comment.dat  - comments extracted from source files
;
; usage:  elf_prep  <input_file> 
;
;
;----------
; design notes:
; See header1.inc for a description of abug_header.dat file
; The image.dat file is mirror of what is loaded into memory. It
; does not include any .bss data.
; The fimage.dat file is a ordering of flag bytes for each byte
; in the image.dat file.  It also has .bss flag bytes at end
; which describe .bss data as it is loaded into memory.
; The system.inc file has a description of flags in fimage.dat
;
%include "system.inc"

%macro _mov 2
  push	byte %2
  pop	%1
%endmacro

  extern env_stack
  extern dir_current
  extern dir_access
  extern str_move
  extern file_status_name
  extern m_setup,m_allocate,m_release
  extern block_read_all
  extern hash_setup
  extern hash_lookup
  extern hash_add
  extern hash_archive
  extern hash_table_ptr
  extern strlen2
  extern block_open_write
  extern block_write
  extern block_close
  extern block_write_all
  extern sys_run_die
  extern file_delete
  extern is_number
  extern str_search
  extern m_close
  extern sort_dword_array3
  extern enviro_ptrs
  extern env_exec

elfdecode:
  mov	[target_file_ptr],eax
  mov	esi,eax
  mov	edi,preamble+pre.target_file
  call	str_move
  call	del_comment_file
  mov	ebx,header_file
  call	file_delete
  mov	ebx,abug_image
  call	file_delete
  mov	ebx,abug_fimage
  call	file_delete
  mov	ebx,abug_sym
  call	file_delete
  mov	ebx,abug_externs
  call	file_delete
  mov	ebx,abug_lib
  call	file_delete
  mov	ebx,abug_undo
  call	file_delete
  call	m_setup		;setup the memory manager
  call	get_file
  or	eax,eax
  jns	ad_02		;jmp if file read
ad_err5:
  mov	[error_code],byte -5
  jmp	ad_exit		;exit if error
ad_02:
  call	process_pheader
  or	eax,eax
  jns	ad_40		;jmp if pheader processed ok
  jmp	short ad_exit
ad_40:
  call	process_sheader
;sort pheader's
  lea	ebp,[preamble+pre.pheader_ptrs]
  xor	edx,edx		;first column
  call	sort_dword_array3
;sort sheader's
  lea	ebp,[preamble+pre.sheader_ptrs]
  xor	edx,edx
  call	sort_dword_array3
  call	complete_preamble ;compute code/data areas
  call	lib_wrapper_check
  call	setup_symbol_table
  or	eax,eax
  jns	ad_50			;jmp if symbol table ready
  mov	[error_code],byte -4
  jmp	short ad_exit
ad_50:
  call	insert_local_labels
  call	process_dynamic_symbols
  call	insert_start_label
  call	write_flag_image
  js	ad_exit		;jmp if error
  call	write_load_image
  call	write_symbol_table
  call	write_comments
  call	write_header
ad_exit:
  call	m_close
  ret
;-------------------
  [section .data]
error_code: db 0
  [section .text]
;-----------------------------------------------------------
write_header:
  mov	ebx,header_file
  xor	edx,edx			;default permissions
  mov	ecx,preamble		;start of header
  mov	esi,header_size
  call	block_write_all
  ret
;-----------------------------------------------------------
;%include "comment.inc"
  extern lib_buf
  extern file_length_name
  extern string_setup
  extern string_add
  extern string_archive
;%include "string.inc"

;
; Note: the stabs format is very confusing and I could not understand
;       the documentaton.  The following was constructed from the output
;       of various assemblers and compilers.
;
struc stabs
.sstr	resd 1	;string data offset if non-zero, and type=?
.stype	resb 1	;type codes 44h=sline 64h=src_filename 84h=include_file 24h=set address
.sother resb 1	;unused 
.sline  resw 1  ;line#
.svalue resd 1	;address, if zero use address from previous type 24h
stabs_rec_size:
endstruc

write_comments:
;read flag image into memory
  mov	eax,[flag_image_buf_size]
  call	m_allocate
  or	eax,eax
  js	wc_exitj	;exit if problem
  mov	[flag_image_buf],eax
  mov	ebx,abug_fimage	;filename
  mov	ecx,eax			;buffer
  mov	edx,[flag_image_buf_size]
  call	block_read_all
;find .stab section
  mov	ebp,[elf_file_ptr]
  mov	edx,'.sta'
  call	find_named_section	;returns esi=header edi=section
wc_lp1:
  or	esi,esi
  js	wc_exitj			;jmp if no debug sections
  cmp	[ebp + ecx + 4],byte 'b'	;is this a dymstr section?
  jne	wc_continue			;jmp if wrong section
  cmp	[ebp + ecx + 5], byte 0
  je	wc_10			;jmp if section found
wc_continue:
  call	fns_continue			;keep looking
  jmp	short wc_lp1			;go check return code
wc_10:
  mov	[stabs_offset],edi
  add	edi,[ebp + esi + elfsection.sh_size] ;compute section end
  mov	[stabs_end_offset],edi

;find strings section
  mov	edx,'.sta'
  call	find_named_section	;returns esi=header edi=section
wc_lp2:
  or	esi,esi
  js	wc_exitj			;jmp if no debug sections
  cmp	[ebp + ecx + 4],dword 'bstr'
  je	wc_20			;jmp if  section found
  call	fns_continue
  jmp	short wc_lp2

wc_exitj:
  jmp	wc_exit
wc_20:
  lea	edi,[ebp + edi]		;get address of section
  mov	[stabs_names_sect_ptr],edi
;open output file
  mov	ebx,comment_filename	;file name
  xor	edx,edx
  call	block_open_write	;open output file, ebx=handle if eax=+
  mov	[comment_file_handle],ebx
;allocate buffer to read source files into
  mov	eax,200000		;buffer for source files
  call	m_allocate
  or	eax,eax
  js	wc_exitj			;exit if allocation error
  mov	[src_file_ptr],eax
  mov	ebp,[elf_file_ptr]
;the ELF file and source file are now in memory
;we have found the .stabs and .stabstr sectons.
;process stabs section entries:
;   dd - string index to find filenames
;   db - entry type 44h=src line  64h=initial file  84h=include file 24=set adr
;   db - ?
;   dw - line#
;   dd - address if type=44h
;
wc_lp3:
  mov	esi,[stabs_offset]
  mov	al,[ebp + esi + stabs.stype]	;get type code  
  cmp	al,64h				;is this a file name
  je	wc_30				;jmp if filename
  cmp	al,84h				;is this a include file
  je	wc_30				;jmp if filename
  cmp	al,24h
  je	wc_28				;jmp if set adr
  cmp	al,44h				;line data?
  je	wc_40				;jmp if line data found
wc_tail:
  mov	esi,[stabs_offset]
  add	esi,stabs_rec_size
  mov	[stabs_offset],esi
  cmp	esi,[stabs_end_offset]
  jne	wc_lp3				;loop if more data
  jmp	wc_60				;go process data in file
wc_28:
  mov	eax,[ebp + esi + stabs.svalue]	;get address
  mov	[line_adr],eax			;save address
  jmp	short wc_tail
;filename was found, open file, 
wc_30:
  mov	byte [wc_flag],0		;enable output, assume file ok
  mov	ebx,[ebp + esi + stabs.sstr]	;get string index
  add	ebx,[stabs_names_sect_ptr]	;index into file names
;if the source compile used one main directory, then ebx is ok.  If
;the source file was specified as /src/xxx.asm or any other directory
;then the partial path is at [ebx].  We need to scan to last '/' and
;require source files be in same dir for asmbug,asmdis,asmsrc to work.
  mov	ecx,ebx				;save ptr to source file
;scan to end
wc_32:
  inc	ebx
  cmp	[ebx],byte 0
  jne	wc_32				;loop till end of file name
;now go back to first "/" or ecx
wc_34:
  dec	ebx
  cmp	ecx,ebx
  je	wc_36				;jmp if start of name found
  cmp	[ebx],byte '/'
  jne	wc_34				;loop till start of name found
  inc	ebx
wc_36:
;ebx now points at file name
  push	ebx
  push	ebp
  call	check_time
  pop	ebp
  pop	ebx
  mov	ecx,[src_file_ptr]		;get buffer
  mov	edx,200000			;buffer length
  call	block_read_all
  or	eax,eax
  jns	wc_tail				;jmp if source file found
;source not found, disable output till another source file found
  or	[wc_flag],byte 1		;disable output
  jmp	short wc_tail
;write line to file, ebp=base  esi=sect offset
wc_40:
  cmp	[wc_flag],byte 0
  jne	wc_tail				;jmp if output disabled
  mov	eax,[ebp + esi + stabs.svalue]	;get address
;
; yasm appears to put address in first line# and uses offset
; after that?  The following code allows this (kludge?)
; origional logic was -  or eax,eax
;                        jz wc_tail
;              wc_40b:   mov [line_addr],eax

  cmp	[base_adr],dword 0
  jne	wc_40a				;jmp if base set
  or	eax,eax				;is address valid
  jz	wc_tail				;jmp if not valid address
  mov	[base_adr],eax			;set base
  mov	[line_adr],eax
; check if new address is less than base (yasm)
wc_40a:
  cmp	eax,[base_adr]
  jae	wc_40b				;jmp if nasm,gas
  add	eax,[base_adr]			;must be yasm
;
; normal nasm,gas logic, above is for yasm
;
wc_40b:
  mov	[line_adr],eax			;save address
wc_41:
  xor	ecx,ecx
  mov	cx,[ebp + esi + stabs.sline]
  cmp	ecx,[previous_line]
  je	wc_tail				;jmp if duplicate line (macro)
  mov	[previous_line],ecx
;scan source file for line
  mov	esi,[src_file_ptr]
;the .stabs section type is source line, try
;to decode line and determin if code or data.
;If code, set code-here flag.
;then strip off the comment and write it out.
  mov	[data_line_flg],byte 0	;assume code here to start
  call	goto_line		;scan for line, returns esi=line ptr
;process this line
wc_lp4:
  lodsb				;get char from source line
  cmp	al,';'			;is this a comment start
  je	wc_42			;jmp if comment start
  cmp	al,'#'			;gas comment?
  je	wc_42
;if gas also uses '//' as comment we need to check for it here
  cmp	al,0ah
  je	wc_tail			;jmp if end of line and no comment found
  or	al,20h			;force to lower case
  cmp	al,'d'
  jne	wc_lp4			;loop if not possible data statement
;we have found a "d", set flag if it is data statement
  call	data_check
  jmp	short wc_lp4
;we have found a comment
wc_42:
  mov	edi,lib_buf
  mov	eax,[line_adr]
  stosd				;put address in buffer
  cmp	eax,[preamble+pre.elf_phys_code_start]
  jb	wc_46			;jmp if data
  cmp	eax,[preamble+pre.elf_phys_code_end]
  ja	wc_46			;jmp if data
  cmp	[data_line_flg],byte 0	;check if data found
  jnz	wc_46			;jmp if data
;assume we have a code line (non-data) and set code-here bit
  sub	eax,[preamble+pre.elf_phys_top] ;compute offset
  add	eax,[flag_image_buf]	;compute flag address
  or	byte [eax],80h
;move comment to lib_buf
wc_46:
  dec	esi			;move back to comment
wc_lp6:
  lodsb
  stosb
  cmp	al,0ah
  jne	wc_lp6			;loop till line moved
  mov	byte [edi -1],0		;put zero at end
;write line in lib_buf to file
  mov	edx,edi			;compute size of write
  sub	edx,lib_buf		;edx=size
  mov	ebx,[comment_file_handle]
  mov	ecx,lib_buf		;get elf offset for code section
  call	block_write		;write code section
  jmp	wc_tail

wc_60:
;close file, and prepare to read back in
  mov	ebx,[comment_file_handle]
  call	block_close
;write flag image out, and release memory
  mov	ebx,abug_fimage	;file name
  xor	edx,edx			;default permissions
  mov	ecx,[flag_image_buf]
  mov	esi,[flag_image_buf_size]
  call	block_write_all
;release buffer
  mov	eax,[flag_image_buf]
  call	m_release
;release all memory, and build comment database
  mov	eax,[src_file_ptr]
  call	m_release
  mov	eax,[elf_file_ptr]
  call	m_release
;-- comment processing part II --
;read file with address followed by comments back into memory
;process each comment and add to string database
;find size of comment file
  mov	ebx,comment_filename
  call	file_length_name	;find length of name
  mov	[_comment_file_size],eax
  or	eax,eax
  jnz	wc_70			;jmp if comment file found
  call	del_comment_file
  jmp	short wc_exit
wc_70:
  call	m_allocate		;allocate buffer
  mov	[_comment_file_ptr],eax
;allocate a buffer for string database
  mov	eax,[_comment_file_size]
  shl	eax,1			;double size
  add	eax,64			;header size
  push	eax
  call	m_allocate
;setup the string database
  mov	edi,eax			;buffer adr to edi
  pop	ecx			;get size of buffer
  call	string_setup
;read the comment file into memory
  mov	ebx,comment_filename
  mov	ecx,[_comment_file_ptr]	;buffer
  mov	edx,[_comment_file_size]
  call	block_read_all
  or	eax,eax
  js	wc_exit			;jmp if error
;add data from comment file to string database
  mov	esi,[_comment_file_ptr]
  mov	eax,esi			;compute end
  add	eax,[_comment_file_size]
  mov	[comment_file_end_ptr],eax
wc_lp7:
  lodsd			;get key
  call	string_add	;eax=key esi=string
  cmp	esi,[comment_file_end_ptr]
  jb	wc_lp7
;write string database
  mov	ebx,comment_filename
  call	string_archive
  or	[preamble+pre.elf_type_flag],byte 38h ;set comment,src,debug found flag
wc_exit:
  ret
;---------------------------------------------
;input: esi points past a "d" character
;output: [data_line_flg] set to one if data statement
data_check:
  mov	ah,byte [esi -2]	;get preceeding char
  cmp	ah,' '			;check if separator
  je	dc_40			;jmp if possible db,dw,dd
  cmp	ah,09h			;check if separator
  jne	dc_exit			;exit if not  data statement
;we have found <separator> d, now look at next char
dc_40:
  mov	ah,[esi]		;get second char
  or	ah,20h			;force to lower case
  cmp	ah,'b'
  je	dc_60			;jmp if possible data
  cmp	ah,'w'
  je	dc_60			;jmp if possible data
  cmp	ah,'d'
  jne	dc_exit			;exit if not data statement
;check trailing char, is it a separator
dc_60:
  mov	ah,[esi +1]		;get trailing separator
  cmp	ah,' '
  je	dc_80			;jmp if data found
  cmp	ah,09
  jne	dc_exit			;jmp if not data
dc_80:
  or	[data_line_flg],byte 1
dc_exit:
  ret
;---------------------------------------------
; goto_line - scan for line number
;  input:  esi = buffer ptr
;          ecx = line number
;  output: ecx=0 & esi=line ptr
;
goto_line:
  dec	ecx
  jz	gl_exit			;exit if done
gl_eol_lp:
  lodsb
  cmp	al,0ah
  jne	gl_eol_lp		;loop till end of line
  jmp	short goto_line
gl_exit:
  ret
;-------------------------------------------------------------
del_comment_file:
  mov	ebx,comment_filename
  call	file_delete
  ret
;-------------------------------------------------------------
check_time:
  cmp	byte [time_err_flg],0
  jne	ct_exit				;exit if error already shown
  call	file_status_name
  or	eax,eax
  js	ct_exit				;exit if file not found
  mov	eax,[ecx + stat_struc.st_mtime]	;get file time
  mov	ebx,[preamble+pre.target_time]
  cmp	eax,ebx
  jbe	ct_exit				;jmp if time ok
  mov	[error_code],byte -7		;older executable warning
  mov	byte [time_err_flg],1
ct_exit:
  ret
;------------------
  [section .data]
stabs_offset	 dd 0
stabs_end_offset dd 0
stabs_names_sect_ptr dd 0	;ptr to file names
comment_filename db '.abug_comment.dat',0
comment_file_handle: dd 0
_comment_file_size:   dd 0
comment_file_end_ptr: dd 0
src_file_ptr	dd	0
wc_flag:	dd	0	;set non-zero if src file not found
line_adr:	dd	0	;physical address of line
base_adr:	dd	0
previous_line	dd	0	;line number of previous line scanned
_comment_file_ptr dd	0	;ptr to data read from comment file
data_line_flg	db	0	;0=code 1=data line
time_err_flg:	db 0		;set if error has occured
  [section .text]


;-----------------------------------------------------------
; retuns status of write in eax
write_symbol_table:
  mov	ebx,abug_sym
  call	hash_archive
  mov	eax,[_sym_table_ptr]
  call	m_release
  ret
;-----------------------------------------------------------
write_load_image:
  mov	ebx,abug_image		;file name
  xor	edx,edx			;permissions
  call	block_open_write	;open output file, ebx=handle if eax=+
  mov	[image_handle],ebx	;save fd
;setup to write pheader blocks
  lea	ebp,[preamble+pre.pheader_ptrs] ;get pheader ptrs
wli_lp1:
  mov	edi,[ebp]		;get struc ptr
  test	[edi+head.p_flags],byte 8 ;is this .bss section?
  jnz	wli_exit2		;exit if at .bss
  mov	edx,[edi+head.size]	;get size of this block
  mov	ecx,[edi+head.offset]	;get file offset
  add	ecx,[elf_file_ptr]	;compute file address
  mov	ebx,[image_handle]	;get handle
  call	block_write		;write block

  mov	ecx,[edi+head.phys_end] ;get end of this block
  add	ebp,4			;move to next pheadr
  mov	edi,[ebp]		;get next pheader ptr
  or	edi,edi			;end of pheader ptrs
  jz	wli_exit2		;jmp if end of pointers
  mov	[phys_adr],ecx		;save phys block end
;write zeros until start of next pheader
wli_lp2:
  cmp	ecx,[edi+head.phys_start] ;at start of next pheader?
  jae	wli_flush		;jmp if at start of next pheader
;write zeros until next pheader start
  call	write_zeros
  inc	dword [phys_adr]
  mov	ecx,[phys_adr]
  jmp	short wli_lp2
wli_flush:
  call	write_flush
  jmp	wli_lp1
;all pheaders written

wli_exit2:
  mov	ebx,[image_handle]
  call	block_close
  ret

;--------------
  [section .data]
image_handle: dd 0
phys_adr:     dd 0	;current phys address being written
  [section .text]
;-----------------------------------------------------------
write_zeros:
  inc	dword [zero_count]
  cmp	[zero_count],byte 16
  jne	wz_exit
write_flush:
  mov	edx,[zero_count]	;write count
  or	edx,edx
  jz	wz_exit			;exit if count = 0
  mov	ecx,zeros
  mov	ebx,[image_handle]
  call	block_write
  mov	dword [zero_count],0
wz_exit:
  ret
;----------------
  [section .data]
zero_count dd 0
zeros:	times 16 db 0
  [section .text]  
;-----------------------------------------------------------
; write_flag_image
; -allocate memory for flag image
; -set bits in flag image using symbol table
; -write flag image to file
write_flag_image:
  mov	eax,[preamble+pre.elf_phys_bss_end] ;get phys end of flags
  sub	eax,[preamble+pre.elf_phys_top]	    ;compute length of fimage
  mov	[flag_image_buf_size],eax	    ;save size of fimage
  call	m_allocate
  or	eax,eax
  js	wfi_errj	;exit if problem
  mov	[flag_image_buf],eax
;clear the flag image and flag filler blocks as 07fh
  lea	ebp,[preamble+pre.pheader_ptrs]
  mov	edi,eax			;edi=fimage buf ptr
  mov	esi,[ebp]		;get first pheader ptr
wfi_lp1:
  mov	ecx,[esi+head.size]
  xor	eax,eax
  rep	stosb			;clear this pheader area
  mov	ecx,[esi+head.phys_end] ;get end of this block
  add	ebp,4			;move to next pheadr
  mov	esi,[ebp]		;get next pheader ptr
  or	esi,esi
  jz	wfi_20			;jmp if end of pointers
wfi_lp2:
  cmp	ecx,[esi+head.phys_start] ;at start of next pheader?
  jae	wfi_lp1			;jmp if at start of next pheader
  mov	al,7fh			;filler code
  stosb
  inc	ecx			;bump phys adr
  jmp	short wfi_lp2

;set bits in fimage using symbol table
wfi_20:  
  mov	eax,[hash_table_ptr]
  mov	esi,[eax]		;get .entries_ptr
  mov	edx,[eax+4]		;get .avialable_entries_ptr
  dec	edx
;symbol structure = dd chain
;                   dd address
;                   dd type
;                   db name
wfi_lp:
  mov	bl,[esi +8]		;get symbol type
  mov	eax,[esi+4]		;get symbol address
  sub	eax,[preamble+pre.elf_phys_top]	;compute offset
wfi_errj:
  js	wfi_err			;jmp if out of range
  add	eax,[flag_image_buf]	;compute address of flag byte
  mov	[eax],bl		;store flag
wfi_slp_end:
  add	esi,9			;move past symbol header 
;scan to end of symbol name
wfi_slp:
  lodsb				;next sym char
  or	al,al			;end of sym?
  jnz	wfi_slp			;loop till end of sym name

  cmp	esi,edx			;end of symbols?
  jb	wfi_lp			;jmp if more symbols

;write flag image
  mov	ebx,abug_fimage	;file name
  xor	edx,edx			;default permissions
;  mov	edx,0666q		;file permissions
  mov	ecx,[flag_image_buf]
  mov	esi,[flag_image_buf_size]
  call	block_write_all
;release buffer
  mov	eax,[flag_image_buf]
  call	m_release
  xor	eax,eax
  jmp	short wfi_exit
wfi_err:
  mov	eax,-1
wfi_exit:
  or	eax,eax
  ret
;----------
  [section .data]
flag_image_buf: dd 0
flag_image_buf_size dd 0

  [section .text]
;-----------------------------------------------------------
; if library wrapper, add new symbol for program start if
; not already in symbol table.  Also add symbol for program
; entry if different from app_entry and not in table.
; We want to do this sub last so symbols are in table already.
insert_start_label:
  test	[preamble+pre.elf_type_flag],byte 2 ;check if lib wrapper found
  jz	isl_50		;exit if wrapper not found
  mov	eax,[preamble+pre.app_main]
  mov	esi,label_main
  mov	bl,90h		;type=code
  call	_add_label_if
;do we want to us physical2offset here?
  mov	eax,[code_elf_offset]	;get offset to code top
  lea	ebx,[ebp + eax]		;lookup code top address

  mov	eax,[ebx+12]		;get push 1 contents
  mov	esi,push1_txt		;label = libc_csu_fini
  mov	bl,90h			;type=code
  call	_add_label_if		;define libc_csu_fini
  mov	esi,label_start
  jmp	short isl_60
;add label for entry 
isl_50:
  mov	esi,label_main
isl_60:
  mov	eax,[preamble+pre.elf_phys_exec_entry]
  mov	bl,90h			;type=code
  call	_add_label_if
  or	eax,eax			;check if label already used
  jns	isl_exit
  mov	eax,[preamble+pre.elf_phys_exec_entry]
  mov	bl,90h
  mov	esi,label_start2
  call	_add_label_if
;
isl_exit:
  ret
;-----------
  [section .data]
label_main: db "main",0
label_start: db "_start",0
label_start2: db "a_unique_start",0
push1_txt:  db 'libc_csu_fini',0
  [section .text]
;-----------------------------------------------------------------------
process_dynamic_symbols:
;set dymanic_section_ptr for lookup_dynamic_code
  mov	bl,2
  call	find_pheader_by_type
  or	esi,esi
  js	pds_exit		;exit if no dymamic section
  mov	eax,[ebp + esi + elfprog.p_offset]
  lea	eax,[ebp + eax]	;get ptr to dymamic section
  mov	[dynamic_section_ptr],eax

;open file for extern's
pd_05:
  mov	ebx,abug_externs	;file name
  xor	edx,edx			;default attributes
  call	block_open_write
  mov	[dis_externs_handle],ebx

  call	process_rel_dyn
  call	process_rel_plt
  call	process_dynsym
  mov	ebx,[dis_externs_handle]
  call	block_close
  call	write_lib_info
pds_exit:
  ret
;------------
  [section .data]
dis_externs_handle dd	0
  [section .text]
;--------------------------------------------------------------
; if library info exists, write it to file dis_lib.tmp
;
; VERNEED gnu.version_r section format
;  dw version  - usually=1
;  dw sub blocks - number of sub records that follow
;  dd string index to lib name in linked section (dynstr)
;  dd index to first sub record
;  dd index to next block (20h if one sub block of 16bytes)
;
write_lib_info:
  mov	ebx,6ffffffeh		;code for VERNEED section
  call	find_typed_section	;returns esi=header offset
  or	esi,esi
  jns	wli_10
  jmp	wli_exit
wli_10:
  mov	edi,[ebp + esi + elfsection.sh_offset]
  lea	edi,[ebp + edi]			;get address of section
  mov	[lib_sect_ptr],edi
  add	edi,[ebp + esi + elfsection.sh_size] ;compute section end
  mov	[lib_section_end],edi
;find the lib string section
  mov	bx,[ebp + esi + elfsection.sh_link] ;get linked section
  call	find_indexed_section
  lea	edi,[ebp + edi]			;get address of strings
  mov	[lib_names_sect],edi

  mov	ebx,abug_lib		;file name
  xor	edx,edx
  call	block_open_write	;open output file, ebx=handle if eax=+
  js	wli_exit 	;exit if error
  mov	[lib_file_fd],ebx

  mov	ebx,[lib_sect_ptr]
; ebx = ptr to dynamic section data
wli_loop3:
  mov	eax,[ebx+4]		;get string index
  mov	esi,[lib_names_sect]
  add	esi,eax			;lookup string
  mov	edi,dis_text2
  call	str_move
  mov	al,0ah
  stosb
;write lib filename to file
  mov	ebx,[lib_file_fd]
  mov	ecx,dis_text1
  sub	edi,ecx			;compute size of write
  mov	edx,edi
  call	block_write

wli_ignore:
  mov	ebx,[lib_sect_ptr]
  mov	eax,[ebx + 12]		;get index to next block
  or	eax,eax
  jz	wli_done		;exit if done
  add	ebx,eax			;move to next section
  mov	[lib_sect_ptr],ebx
  cmp	ebx,[lib_section_end]
  jne	wli_loop3  
wli_done:
  mov	ebx,[lib_file_fd]
  call	block_close
wli_exit:
  ret
;----------------------
  [section .data]
lib_file_fd		dd 0
lib_names_sect:		dd 0	;pointer to lib ascii strings
lib_sect_ptr		dd 0	;pointer to elf dynamic data
lib_section_end		dd 0	;pointer to end of dynamic section

dis_text1:	db ';lib file: '
dis_text2:	times 30 db 0
;lib_msg:	db 0ah,'writing lib info',0
  [section .text]



;--------------------------------------------------------------
process_dynsym:
;scan section dynsym and add entries, first find DYNSYM section
  mov	eax,6
  call	lookup_dynamic_code
  js	pd_exit
  mov	[pds_symtab_ptr],eax
;find the strtab section
  mov	eax,5
  call	lookup_dynamic_code
  js	pd_exit
  mov	[pds_strtab_ptr],eax

; symtab format:
;.st_name   dd  name string index
;.st_value  dd  symbol value
;.st_size   dd  size
;.st_info	resb	1 ;types: 00=NOTYPE 01=OBJECT 02=FUNC 03=SECTION 04=FILE  -or- below
;                          ;bind:  00=LOCAL 10h=GLOBAL 20h=WEAK  -or- with above. 
;.st_other	resb	1 ;unused
;.st_shndx	resw	1 ;associates symbol with section#, if 0fff1h then no section assoc.
;                         ;example: 0=symbol appears in first section, 1=symbol in section 1
;elfsymtab_struc_size:

  mov	ebx,[pds_symtab_ptr]
; ebx = ptr to dynsym section data
pd_loop3:
  mov	eax,[ebx+symtab.st_value]
;  or	eax,eax
;  jz	pd_ignore		;ignore symbol if zero address
  mov	esi,[ebx]		;get string index, ebx+symtab.st_name
  or	esi,esi
  jz	pd_ignore		;skip symbol if no associated string
  add	esi,[pds_strtab_ptr]	;lookup symbol text
  mov	bl,0			;set type=external
  call	_add_label_if

pd_ignore:
  mov	ebx,[pds_symtab_ptr]
  add	ebx,16
  mov	[pds_symtab_ptr],ebx
;check if at end of dnysym table.  this is a kludge beacuse
;we do not know how many entries were in the table.  Instead
;we will check if next entry is legal
  cmp	word [ebx+2],0
  jne	pd_exit			;exit if string index too big
  cmp	byte [ebx+11],0
  jne	pd_exit			;exit if size greater than ffffffh
  cmp	byte [ebx+13],0
  je	pd_loop3		;loop if "other" field zero
; all symbols from dynsym have been added
pd_exit:
  ret
;----------------------------------------------------
process_rel_plt:
;look for .rel.plt section
pd_part1:
  mov	eax,17h
  call	lookup_dynamic_code
  js	prp_exit
  mov	ebx,eax
;look for pltrelsz in bytes
  mov	eax,2	;pltrelsz
  call	lookup_dynamic_code
  js	prp_exit
  shr	eax,3		;convert to entry count
  mov	ecx,eax
  mov	eax,[dis_externs_handle]
  call	pds_engine
prp_exit:
  ret
;-------------------------------------------------------
process_rel_dyn:
;look for .rel.dyn section
  mov	eax,11h
  call	lookup_dynamic_code
  js	prd_exit
  mov	ebx,eax
;look for pltrelsz in bytes
  mov	eax,12h	;relsz
  call	lookup_dynamic_code
  js	prd_exit
  shr	eax,3		;convert to entry count
  mov	ecx,eax
  mov	eax,[dis_externs_handle]
  call	pds_engine
prd_exit:
  ret  
;------------------------------------------------------------
; process either .rel.dyn or .rel.plt blocks
;
; inputs:  eax = file handle for writing exterals and globals
;          ebx = section pointer
;          ecx = number of entries in section
;
; format of .rel.dyn or .rel.plt 
;      value dd - ptr to .got.plt section entry
;      type  db - (see decode table)
;      sym#  db - index into dnysym 0,1,2,3, etc.
;      val2  dw - value (unused?)
;
; format of .got.plt
;      pointers dd - points to "push" part of .plt entry
;
; format of .plt
;      jmp [adr]   - points to .got.plt entry, source code points at jmp
;      push x      - .got.plt entry points here
;      jmp adr     - goes to dynamic linker
;
; symbol address is determined as follows:
;   1. get value from .rel.plt
;   2. get pointer from value (.got.plt data)
;   3. subtract 6
;
pds_engine:
  mov	[pds_count],ecx
  mov	[pds_ptr],ebx
  mov	[pds_handle],eax
;find the dynsym section
  mov	eax,6
  call	lookup_dynamic_code
  js	pds_donej
  mov	[pds_symtab_ptr],eax
;find the strtab section
  mov	eax,5
  call	lookup_dynamic_code
  js	pds_donej
  mov	[pds_strtab_ptr],eax

pds_loop:
  mov	ecx,[pds_count]		;get count
  jecxz	pds_donej		;exit if pds done
;look up symbol string
  mov	ebx,[pds_ptr]
  xor	eax,eax
  mov	al,[ebx+5]		;get symtab index
  shl	eax,4			;multiply by 16
  add	eax,[pds_symtab_ptr]	;index into table
  mov	eax,[eax]		;get string offset
  add	eax,[pds_strtab_ptr]	;lookup in string table
  mov	[sym_name_ptr],eax
  mov	esi,ebx			;copy symtab ptr
;decode function type
  xor	eax,eax
  mov	al,[ebx+4]		;get function type
  cmp	al,10
  jbe	pds_30			;jmp if legal value
pds_donej:
  jmp	pds_done		;exit if bad type
pds_30:
  shl	eax,2			;convert to dword ptr
  add	eax,pds_table
  jmp	[eax]

pds_table:
  dd	R_386_NONE		;0
  dd	R_386_32		;1
  dd	R_386_PC32		;2
  dd	R_386_GOT32		;3
  dd	R_386_PLT32		;4
  dd	R_386_COPY		;5
  dd	R_386_GLOB_DAT		;6
  dd	R_386_JMP_SLOT		;7
  dd	R_386_RELATIVE		;8
  dd	R_386_GOTOFF		;9
  dd	R_386_GOTPC		;10

R_386_NONE:		;0
R_386_32:		;1
R_386_PC32:		;2
R_386_GOT32:		;3
R_386_PLT32:		;4
R_386_COPY:		;5 handled by dnysym scan, ignore
R_386_GLOB_DAT:		;6 sets up linker ptr, ignore
  jmp	pds_lp_end

R_386_JMP_SLOT:		;7 normal processing for dynamic symbols
  mov	eax,[esi]	;get pointer to .got section
  call	physical2_local
  mov	eax,[eax]	;get contents of .got pointer, ptr to .got.plt entry
  sub	eax,6		;move up to jmp slot
;add this function to symbol table
  mov	bl,0		;set type to external
  mov	esi,[sym_name_ptr]
  call	_add_label_if
  mov	esi,[sym_name_ptr]
;if __gmon_start label then ignore it
  cmp	dword [esi],'__gm'
  jne	pds_40			;jmp if not gmon label
  cmp	dword [esi+4],'on_s'
  je	pds_50			;jmp if this is gmon label
;add this function to externals file
pds_40:
  mov	esi,[sym_name_ptr]
  mov	edi,pds_insert
;  mov	edi,sym_name
  call	str_move
  mov	al,0ah
  stosb
;write extern function to file
  mov	ebx,[pds_handle]
  mov	ecx,pds_extern
  sub	edi,ecx			;compute size of write
  mov	edx,edi
  call	block_write
pds_50:
  jmp	short pds_lp_end

R_386_RELATIVE:		;8
R_386_GOTOFF:		;9
R_386_GOTPC:		;10

pds_lp_end:
  dec	dword [pds_count]
  add	dword [pds_ptr],8
  jmp	pds_loop
;
; all entries have been processed
;
pds_done:
  ret

;--------------
  [section .data]
pds_count	dd	0	;loop count
pds_ptr		dd	0	;entry pointer, 8-bytes per entry
pds_handle	dd	0	;file handle
pds_symtab_ptr	dd	0	;pointer to symtab section
pds_strtab_ptr	dd	0	;pointer to string table
pds_extern	db	' extern '
pds_insert:	times 120 db 0
sym_name_ptr:   dd	0
  [section .text]  
;------------------------------------------------------------
; find code in dynamic section
;  input:  eax=code
;  output: eax=value of code or -1 if not found
;
lookup_dynamic_code:
  push	esi
  mov	esi,[dynamic_section_ptr]
ldc_lp1:
  cmp	[esi],eax		;get key code
  je	ldc_done		;jmp if found
  add	esi,8			;move to next entry
  cmp	dword [esi],byte 0
  jne	ldc_lp1			;loop if more entries
  _mov	eax,-1
  jmp	short ldc_exit
ldc_done:
  mov	eax,[esi+4]		;get second dword
  cmp	eax,[load1_phys_adr]
  jb	ldc_exit		;jmp if not address
  cmp	eax,[preamble+pre.elf_phys_code_end]
  ja	ldc_exit		;jmp if not address
;convert physical address to local address
  call	physical2_local
ldc_exit:
  pop	esi
  or	eax,eax			;set sign flag bit
  ret  
;--------------
  [section .data]
dynamic_section_ptr: dd 0	;ptr to dymanic section
load1_phys_adr:	     dd 0
  [section .text]
;-------------------------------------------------------
;convert physical address to local elf file ptr
; input eax=physical addess
;       ebp=top of elf file ptr
; output eax=local
;
physical2_local:
  push	edx
  push	ecx
  lea	edx,[preamble+pre.pheader_ptrs]
pl_lp:
  mov	ecx,[edx]	;get pheader entry
  jecxz	pl_exit2	;jmp if not found
  cmp	eax,[ecx+head.phys_end]
  jb	pl_10		;jmp if here
  add	edx,4		;move to next pointer
  jmp	short pl_lp	;keep looking
;address is in this pheader
pl_10:
  sub	eax,[ecx+head.phys_start] ;remove section phys start
  add	eax,[ecx+head.offset]	  ;index into section
  add	eax,[elf_file_ptr]	;convert to local address
pl_exit2:
  pop	ecx
  pop	edx
  ret

;-----------------------------------------------------------------------
insert_local_labels:
;find address of symtab section  
  mov	edx,'.sym'
  call	find_named_section	;returns esi=header edi=section
  or	esi,esi
  js	ill_exitj			;exit if section not found
  or	[preamble+pre.elf_type_flag],byte 4 ;set symbols found
;compute end of symtab for loop end check
  mov	ebx,[ebp + esi + elfsection.sh_size] ;get size of symbol table
  lea	ecx,[ebp + edi]			;get address of secton
  mov	[symtab_address],ecx
  add	ecx,ebx				;compute end of section
  mov	[symtab_end_ptr],ecx		;save end for loop check

;find address of strings section
  mov	bl,[ebp + esi + elfsection.sh_link]
  call	find_indexed_section	;returns esi=header edi=section
  or	esi,esi
  jns	ill_20			;jmp if string found
ill_exitj:
  jmp	ill_exit		;exit if strings not found

ill_20:
  lea	eax,[ebp +edi]		;get symtab strings address
  mov	[sym_strings],eax
;lookup name string for this symtab entry
ill_loop:
  mov	ecx,[symtab_address]
  mov	eax,[ecx]		;get string index
  or	eax,eax
  jz	ill_ignore		;ignore symbol if no string name
  mov	esi,[sym_strings]
  add	esi,eax			;index into strings
;esi points at string for this symbol, get address
  mov	eax,[ecx+symtab.st_value]
  call	within_load
  jc	ill_ignore		;jmp if not in load section
;  or	eax,eax
;  jz	ill_ignore		;ignore symbol if address=0
  mov	bh,[ecx+symtab.st_info] ;get type 
  and	bh,0fh			;isolate type bits
; 00=NOTYPE 01=OBJECT 02=FUNC 03=SECTION 04=FILE
  mov	bl,10h			;preload data type
  or	bh,bh
  jz	ill_add			;jmp if NOTYYPE
  dec	bh			;check if data (1) OBJECT
  jz	ill_add
  mov	bl,90h			;preload code type
  dec	bh			;check if code (st_info=2)
  jnz	ill_ignore		;jmp if not code label
ill_add:
  call	_add_label_if
ill_ignore:
  mov	ecx,[symtab_address]
  add	ecx,elfsymtab_struc_size
  mov	[symtab_address],ecx
  cmp	ecx,[symtab_end_ptr]
  jne	ill_loop  
ill_exit:
  ret

;------------
  [section .data]
symtab_address: dd 0
symtab_end_ptr: dd 0
sym_strings:	dd 0	;address of symtab strings section
  [section .text]
;----------------------------------------------------------
; eax= address
; output: carry set if address not in load section
;
within_load:
  push ebx
  push ebp

  mov	ebp,preamble+pre.pheader_ptrs -4
wl_lp:
  add	ebp,4
  mov	ebx,[ebp]
  or	ebx,ebx
  jz	wl_bad_exit
  cmp	eax,[ebx+head.phys_start]
  jb	wl_bad_exit
  cmp	eax,[ebx+head.phys_end]
  jb	wl_good_exit
  jmp	short wl_lp
wl_bad_exit:
  stc
  jmp	short wl_exit
wl_good_exit:
  clc  
wl_exit:
  pop	ebp
  pop	ebx
  ret
;-----------------------------------------------------------
; add label if it is not a duplicate and within range
;
;input:  esi = ptr to symbol name
;        eax = symbol address
;         bl = symbol type, 00=extern else flag image bits
;
;output: eax = 0 (success)
;              1 address found and type info updated
;              -1 (name used already)
_add_label_if:
  mov	[sym_type],bl		;save type
  call	_check_range
  jc	ali_exit		;exit if out of range
  mov	[sym_adr],eax
  mov	[ali_name_ptr],esi
;check if address already in table
  mov	edi,sym_adr
  mov	ecx,4			;lenght of matchl
  xor	edx,edx			;offset
  call	hash_lookup		;returns eax=0 if match and esi=ptr to match
  or	eax,eax
  jnz	ali_50			;jmp if label not found
;label was found, update the type info 
  mov	bl,[sym_type]
  or	[esi + sym.sym_typ],bl
  _mov	eax,1
  jmp	short ali_exit
   
;this is a new label, check if name already used
ali_50:
  mov	edi,[ali_name_ptr]
  call	strlen2			;get lenght of string -> ecx
  mov	edx,5			;offset
  neg	ecx			;set string flag
  call	hash_lookup		;returns eax=0 if match and esi=ptr to match
  or	eax,eax
  jnz	ali_80			;jmp if label name not in table
  _mov	eax,-1
  jmp	short ali_exit		;jmp if name used
;add new symbol to table
ali_80:
  mov	esi,[ali_name_ptr]
  mov	edi,sym_name
  call	str_move
  mov	esi,sym_adr		;start of entry
  call	hash_add
  xor	eax,eax			;set success flag
ali_exit:
  ret
;-----------
  [section .data]
ali_name_ptr:	dd	0
;symbol build area:
sym_adr:	dd 0		;symbol table entry - address
sym_type:	db 0		;symbol type, 1xh=data 9xh=code 00=ext
sym_name:	times 90 db 0	;symbol name

  [section .text]

;-----------------------------------------------------------
; check if symbol within "load" range
;  input: eax=address
;  output: carry set if out of range
;
_check_range:
  cmp	eax,[preamble+pre.elf_phys_top]
  jb	_cr_bad
  cmp	eax,[preamble+pre.elf_phys_bss_end]
  jb	_cr_good
_cr_bad:
  stc
  jmp	short _cr_exit
_cr_good:
  clc
_cr_exit:
  ret
;-----------------------------------------------------------
; setup_symbol_table
;
setup_symbol_table:
  push	ebp
  mov	ebp,[elf_file_ptr]
  mov	edx,'.sym'
  call	find_named_section	;returns esi=header edi=section
;  call	find_sheader_name		;check for symbol table
  or	esi,esi
  js	sst_20				;jmp if no symbol table found
  mov	eax,[ebp + esi + elfsection.sh_size]
  shl	eax,1			;double size
  mov	[symtbl_size],eax
;look for dynamic symbols
sst_20:
  mov	edx,'.dyn'
  call	find_named_section	;returns esi=header edi=section
;  call	find_sheader_name
sst_30:
  or	esi,esi
  js	sst_allocate			;jmp if no dynnamic sections
  cmp	[ebp + ecx + 3],dword 'nstr'	;is this a dymstr section?
  je	sst_40				;jmp if dymstr section
  call	fns_continue			;keep looking
  jmp	short sst_30
;save size of dynsym section
sst_40:
  mov	eax,[ebp + esi + elfsection.sh_size]
  shl	eax,1
  add	[symtbl_size],eax
sst_allocate:
;allocate memory
  mov	eax,[symtbl_size]
  call	m_allocate
  or	eax,eax
  js	sst_exit			;exit if error
  mov	[_sym_table_ptr],eax
  mov	edi,eax				;location for symbol table
  add	eax,[symtbl_size]			;calculate buffer end
  mov	ecx,eax
  mov	al,0fh				;one byte hash mask (16 chains)
  mov	ebx,5				;skip val if search for end index
  call	hash_setup
sst_exit:
  pop	ebp
  ret
;----------------
  [section .data]
symtbl_size:  dd  200		;default size is 200 bytes
  [section .text]
;-----------------------------------------------------------
lib_wrapper_check:
;compute file buffer location for entry point
  mov	ebp,preamble+pre.pheader_ptrs
  mov	eax,[preamble+pre.elf_phys_exec_entry]
;search for pheader with entry point
lwc_lp:
  mov	ebx,[ebp]	;get ptr to head struc
  cmp	eax,[ebx+head.phys_end]	;is entry here?
  jbe	lwc_fnd		;jmp if section with entry
  add	ebp,4
  jmp	lwc_lp
;lookup up data for entry point
lwc_fnd:
  sub	eax,[ebx+head.phys_start] ;compute offset into block
  add	eax,[ebx+head.offset]	;compute offset into file
  add	eax,[elf_file_ptr]	;index into file
;
; try to set pointers to origional code before linker additions
;
  cmp	dword [eax],895eed31h	;check if standard start up code
  jne	isl_80			;exit if unknown code
  mov	ebx,eax			;save code address
;
  mov	eax,[ebx+24]		;get push 3 contents
;check if this is possible start address
  cmp	eax,[preamble+pre.elf_phys_code_start]
  jb	isl_80			;jmp if not code start
  cmp	eax,[preamble+pre.elf_phys_code_end]
  ja	isl_80			;jmp if not in code section
  mov	[preamble+pre.app_main],eax
  or	[preamble+pre.elf_type_flag],byte 2h ;set wrapper found flag
isl_80:
  ret
;-----------------------------------------------------------
complete_preamble:
  mov	ebp,preamble+pre.pheader_ptrs

  mov	ebx,[ebp]	;get ptr to head struc
  mov	eax,[ebx+head.phys_start] ;get start of first block
  mov	[preamble+pre.elf_phys_top],eax ;save top (elf header)
;find first executable (code) block
cp_lp1:
  mov	ebx,[ebp]	;get current head struc
  or	ebx,ebx
  jnz	cp_05		;jmp if entry found
  or	[phead+head.p_flags],byte 1 ;force first phead to executable
  jmp	short complete_preamble	;go try again
cp_05:
  test	[ebx+head.p_flags],byte 1
  jnz	cp_10		;jmp if executable section found
  add	ebp,4		;move to next ptr
  jmp	short cp_lp1
cp_10:
  mov	eax,[ebx+head.offset]	;get offset into file
  mov	[code_elf_offset],eax
  mov	eax,[ebx+head.phys_start] ;get code start
  mov	[preamble+pre.elf_phys_code_start],eax
;find end of code block
;assume this block is end of code also
  add	eax,[ebx+head.size]	;compute block end
;check if another executable block is present
cp_21:
  add	ebp,4
  mov	ebx,[ebp]
  or	ebx,ebx
  jz	cp_22		;jmp if end of pheaders
  test	[ebx+head.p_flags],byte 1 ;executable?
  jz	cp_21		;loop till executable found
;executable found, set code end value
  mov	eax,[ebx+head.phys_start]
  add	eax,[ebx+head.size]
  jmp	cp_21		;loop looking for more
;set end of code 
cp_22:
  mov	[preamble+pre.elf_phys_code_end],eax ;save code end
;look for end of load (file data)
;scan to end to see if .bss section present
cp_lp2:
  sub	ebp,4		;move back to prev block
  mov	ebx,[ebp]	;get head struc ptr
  test	[ebx+head.p_flags],byte 8 ;bss ?
  jz	got_last_ph	;jmp if no bss on end
  sub	ebp,4		;move back to prev block
got_last_ph:
  mov	ebx,[ebp]	;get head struc ptr
  mov	eax,[ebx+head.phys_start] ;get start adr
  add	eax,[ebx+head.size]  ;compute end of block
  mov	[preamble+pre.elf_phys_load_end],eax ;save load end
;find end of .bss area
  add	ebp,4		;start .bss hunt
  mov	ebx,[ebp]	;get next head struc
  or	ebx,ebx		;is .bss at end?
  jz	have_end	;jmp if no .bss
  mov	eax,[ebx+head.phys_start]
  add	eax,[ebx+head.size]
have_end:
  mov	[preamble+pre.elf_phys_bss_end],eax

;fine tune the .elf_phys_code_start variable
  mov	edx,preamble+pre.sheader_ptrs ;check for .text
cp_lp3:
  mov	ebp,[elf_file_ptr]
  mov	edx,'.tex'
  call	find_named_section ;returns esi=header edi=section
  or	esi,esi		;was .text found?
  js	cp_20		;jmp if not found
;we have found .tex? section, save offset and address
  mov	eax,[ebp + esi+elfsection.sh_addr] ;get phys addr
  mov	[preamble+pre.elf_phys_code_start],eax
  mov	eax,[ebp+esi+elfsection.sh_offset] ;get offset
  mov	[code_elf_offset],eax
  jmp	short cp_exit
;no sections were found, check if elf-header at top of code area
cp_20:
  mov	eax,[preamble+pre.elf_phys_top]	;check if code has elf-header
  cmp	eax,[preamble+pre.elf_phys_code_start] ;elfheader here?
  jne	cp_exit		;exit if no header at top of code
;the code has elf-header at top, adjust start
  mov	ebp,[elf_file_ptr]
;Note: we assume elf-header is 80h because munged headers can have
;      a bad value for size of header.
  mov	ecx,[ebp+elfheader.e_hsize]	;get elfheader size
  cmp	ecx,80h
  jbe	cp_25		;jmp if header size ok
  mov	ecx,80h
cp_25:
  add	eax,ecx	;compute end of header
  mov	ebx,[preamble+pre.elf_phys_exec_entry] ;get entry point
  cmp	ebx,eax	 	;entry point inside header?
  ja	cp_30		;jmp if entry inside header
;entry point is inside header, set as code start
  mov	[preamble+pre.elf_phys_code_start],ebx
  jmp	cp_exit
;entry  point is outside the elf header, use end of header as code start
cp_30:
  mov	[preamble+pre.elf_phys_code_start],eax ;set code at end of elf-header
cp_exit:
  ret

;-----------------------------------------------------------
; ebp = elf header ptr
;
process_sheader:
  cmp	word [ebp + elfheader.e_shnum],0 ;any section headers?
  jz	ps_errj		;jmp if no sections found
;find section with names
  mov	bx,[ebp + elfheader.e_shstrndx]
  call	find_indexed_section		;find name section
  or	esi,esi
  jns	ps_10
ps_errj:
  jmp	ps_err
ps_10:
  mov	[names_section_offset],edi

  mov	esi,[ebp + elfheader.e_shoff]
  mov	[shead_num],byte 0		;setup for next_sheader

ps_lp1:
  mov	edx,[shead_stuff_ptr]

  mov	eax,[ebp + esi + elfsection.sh_addr] ;get phys adr
  or	eax,eax				;lodable section?
  jz	ps_next
  mov	[edx+sect.sh_addr],eax		;save address
  mov	eax,[ebp + esi + elfsection.sh_size]
  mov	[edx+sect.sh_size],eax		;save size
  mov	eax,[ebp + esi + elfsection.sh_flags]
  mov	[edx+sect.sh_flags],eax
;lookup section name
  mov	ecx,[ebp + esi + elfsection.sh_name] ;get name section offset
  add	ecx,[names_section_offset]		;index into names
  push	esi
  lea	esi,[ebp + ecx]		;get ptr to name
  lea	edi,[edx+sect.sh_name]
  call	str_move
  pop	esi
  inc	edi
;move to next stuff point
  mov	ebx,[shead_ptrs_ptr]
  mov	[ebx],edx
  add	ebx,4
  mov	[shead_ptrs_ptr],ebx
  mov	[shead_stuff_ptr],edi
;move to next section
ps_next:
  mov	eax,[shead_num]
  call	next_sheader
  mov	[shead_num],al
  or	esi,esi
  js	ps_exit
  jmp	ps_lp1
ps_err:
  mov	eax,-1
ps_exit:
  or	eax,eax
  ret
;------------
  [section .data]
shead_num	dd 0		;curent section#
names_section_offset dd 0	;section with name strings
shead_ptrs_ptr dd preamble+pre.sheader_ptrs	;pointer to pointers in preamble
shead_stuff_ptr	dd shead
  [section .text]

;-----------------------------------------------------------
; save load section bounds from pheader
;  INPUT:  ebp = ptr to elf header
;  OUTPUT: eax = negative if error, else positive
;
;  Only p_type =LOAD are processed here.
;
process_pheader:
;check for dynamic section
  mov	bl,2	;type 2 = dynamic
  call	find_pheader_by_type
  or	esi,esi
  js	pp_05	;jmp if dynamic section not found
  or	[preamble+pre.elf_type_flag],byte 1 ;set dynamic flag
;look at first loadable section in pheader
pp_05:
  mov	bl,1	;type 1 = loadable
  call	find_pheader_by_type
  or	esi,esi
  jns	pp_10				;jmp if load header found
  jmp	pp_exit	;exit if error

pp_10:
  mov	eax,[ebp + esi + elfprog.p_addr] ;get physical adr
  mov	[load1_phys_adr],eax
pp_lp1:
  mov	edx,[phead_stuff_ptr]
  mov	ebx,[ebp + esi + elfprog.p_virtual] ;get phys adr
  mov	[edx+head.phys_start],ebx
  mov	ecx,[ebp + esi + elfprog.p_filesz]
  cmp	ecx,[elf_file_size]		;safety check
  jb	pp_fsave			;jmp if file size ok
  mov	ecx,[elf_file_size]		;force file size
pp_fsave:
  mov	[edx+head.size],ecx		;save file size
  jecxz	pp_bss_fnd			;jmp if empty block
  add	ebx,ecx				;compute phys end
  mov	[edx+head.phys_end],ebx	;save end of block
  mov	eax,[ebp + esi + elfprog.p_offset]
  mov   [edx+head.offset],eax
  mov	eax,[ebp+esi+elfprog.p_flags]
  mov	[edx+head.p_flags],al
;move to next stuff point
  mov	ebx,[phead_ptrs_ptr]
  mov	[ebx],edx
  add	ebx,4
  mov	[phead_ptrs_ptr],ebx
  add	edx,head_struc_size
  mov	[phead_stuff_ptr],edx
;check if .bss block here ecx=file size
pp_bss_fnd:
  mov	eax,[ebp+esi+elfprog.p_flags]
  mov	ebx,[ebp + esi + elfprog.p_memsz]
  cmp	ecx,ebx		;do we need a .bss
  je	pp_tail		;jmp if no .bss
;append a .bss block
  or	al,08h		;or in .bss bit
  mov	[edx+head.p_flags],al

  sub	ebx,ecx		;compute .bss size
  cmp	ebx,10000000h	;safety check
  jb	pp_fsave2
  mov	ebx,[elf_file_size]	;force size
pp_fsave2:
  mov	[edx+head.size],ebx ;save .bss size
  mov	eax,[ebp + esi + elfprog.p_virtual] ;get phys adr
  add	eax,[ebp + esi + elfprog.p_filesz] ;compute .bss start
  mov	[edx+head.phys_start],eax
  add	eax,ebx			;compute .bss end
  mov	[edx+head.phys_end],eax

  mov	ebx,[phead_ptrs_ptr]	;move phead ptr fwd
  mov	[ebx],edx
  add	ebx,4			;advance ptr
  mov	[phead_ptrs_ptr],ebx	;save new ptr
  add	edx,head_struc_size	;add size of head struc
  mov	[phead_stuff_ptr],edx	;save new stuff ptr
pp_tail:
  call	next_pheader
  or	esi,esi
  js	pp_exit
  mov	eax,[ebp + esi + elfprog.p_type]
  test	al,1		;LOAD block
  jnz	pp_lp1
;----
pp_exit:
  xor	eax,eax
  ret
;------------
  [section .data]
phead_ptrs_ptr dd preamble+pre.pheader_ptrs	;pointer to pointers in preamble
phead_stuff_ptr	dd phead		;ptr to build area for 
  [section .text]
;-------------------------------------------------------
; INPUT edx="name" of section
;       ebp=elf header pointer
; OUTPUT: esi= offset of header or -1 if not found
;         edi= offset of section
;         ecx= offset of section name in strings
find_named_section:
  mov	ebp,[elf_file_ptr]
  xor	ecx,ecx
  mov	cx,word [ebp + elfheader.e_shnum] ;any section headers?
  jecxz	fns_exit1	;jmp if headers not found
  cmp	cl,60		;check if illegal value
  jb	fns_lookup	;jmp if possible section headers
fns_exit1:
  or	[preamble+pre.elf_type_flag],byte 40h
  _mov	esi,-1
  jmp	short fns_exit
fns_lookup:
  mov	bx,[ebp + elfheader.e_shstrndx] ;get section# for strings
  call	find_indexed_section		;get ptr to section header for strings
  or	esi,esi
  js	fns_exit			;exit if not found
  mov	esi,[ebp + elfheader.e_shoff]
  mov	al, 1			;start search from section 1
fns_loop:
  mov	ecx,[ebp + esi + elfsection.sh_name] ;get name section-offset
  add	ecx,edi				;index into names
  mov	[sec_data_off],edi		;save ptr to section data
  cmp	[ebp + ecx],edx			;check if name matches
  jne	fns_continue			;jmp if names do not match
  mov	edi,[ebp + esi + elfsection.sh_offset] ;get section offset
  jmp	short fns_exit			;exit if names match
;entry point with:
; esi=last section offset
;  al=last section index
; edx=name to match
fns_continue:
  mov	edi,[sec_data_off]		;needed, if called externally
  call	next_sheader
  or	esi,esi
  jns	fns_loop			;loop till name found
fns_exit:
  ret
;----------------
  [section .data]
sec_data_off: dd 0
  [section .text]
;----------------
;  INPUT: bl=section header index (1+ section 0 is ignored)
;         ebp = elf header pointer
;  OUTPUT: esi = offset of header or -1 if not found
;          edi = offset of section data
;          ebp,ebx unchanged
;
find_indexed_section:
  mov	ebp,[elf_file_ptr]
  cmp	word [ebp + elfheader.e_shnum],0 ;any section headers?
  jz	fis_err		;jmp if no sections found
fis_lookup:
  mov	esi,[ebp + elfheader.e_shoff]
  xor	eax,eax		;initialize index counter -> 0
fis_loop:		;first section is null, 
  call	next_sheader
  or	esi,esi
  js	fis_exit	;exit if not found
  cmp	al,bl
  jne	fis_loop	;loop if more sections
  mov	edi,[ebp + esi + elfsection.sh_offset]
  jmp	short fis_exit
fis_err:
  _mov	esi,-1
fis_exit:
  ret   
;----------------
; find_typed_section
;  INPUT: ebx=section type
;         ebp = elf header pointer
;  OUTPUT: esi = ptr to header or -1 if not found
;          ebp,ebx unchanged
;         
find_typed_section:
  mov	esi,[ebp + elfheader.e_shoff]
  or	esi,esi
  jnz	fts_10		;jmp if sections found
  _mov	esi,-1
  jmp	short fts_exit
fts_10:
  mov	al,0	;initialize header index
fts_loop:
  cmp	ebx,[ebp + esi + elfsection.sh_type]
  je	fts_exit	;exit if done
  call	next_sheader
  or	esi,esi
  jns	fts_loop
fts_exit:
  ret   
;----------------
; next_sheader - next program header
;  INPUT:  ebp = ptr to top of elf file
;          esi = offset to current section
;           al = previous section #
;           ah = section type (not used here)
;  OUTPUT: ebp - unchanged
;          esi = offset of next section, or -1 if at end
;           al = next section # if esi positive
;
next_sheader:
  cmp	al,[ebp + elfheader.e_shnum]
  je	ns_at_end
  add	esi,40
  inc	al		;bump pheader number
  ret
ns_at_end:
  mov	esi,-1
  ret 
;----------------
; find_pheader_by_type
;  INPUT: bl=section type
;         ebp = elf header pointer
;  OUTPUT: esi = ptr to header or -1 if not found
;          ebp,ebx unchanged
;          al = psection  number
;         
find_pheader_by_type:
   mov	[phead_num],byte 0		;setup for next_pheader
   mov	esi,[ebp + elfheader.e_phoff]
  mov	al,1		;initialize header index
fpbt_loop:
  cmp	bl,[ebp + esi + elfprog.p_type]
  je	fpbt_exit	;exit if done
  call	next_pheader
  or	esi,esi
  jns	fpbt_loop
fpbt_exit:
  ret   

;----------------
; next_pheader - next program header
;  INPUT:  ebp = ptr to top of elf file
;          esi = offset to current section
;           al = previous psection #
;          [phead_num] = starting phead number (0=first)
;  OUTPUT: ebp - unchanged
;          esi = offset of next section, or -1 if at end
;           al = next section # if esi positive
;
next_pheader:
  mov	al,[phead_num]
  inc	al
  mov	[phead_num],al
  cmp	al,[ebp + elfheader.e_phnum]
  jae	np_at_end
;  add	esi,[ebp + elfheader.e_phensize] ;section header size (32)
  add	esi,32
  ret
np_at_end:
  mov	esi,-1
  ret
;------------------
  [section .data]
phead_num	db 0	;counter
  [section .text] 
;          
;-----------------------------------------------------------
get_file:
  mov	eax,[target_file_ptr]
  call	dir_current	;puts current working dir in lib_buf
  mov	ecx,7		;check for  read/write/execute
  call	dir_access
  or	eax,eax
  jp	ad_05		;jmp if current directory can be accessed
;error, can not access current dir
  mov	[error_code],byte -1
  jmp	gf_exit1
ad_05:
  mov	ebx,[target_file_ptr]
  call	file_status_name ;get file size
  jns	ad_20		;jmp if file found
  mov	ebp,[target_file_ptr]
  cmp	[ebp],byte '/'
  je	ad_08		;jmp if bad path
;check if this file on path
  mov	ebx,[enviro_ptrs]
  call	env_exec
  jc	ad_08			;jmp if file not found
  mov	esi,ebx			;get full path
  mov	edi,[target_file_ptr]
  call	str_move		;add path to name
  mov	ebx,[target_file_ptr]
  call	file_status_name ;get file size
  jns	ad_20		;jmp if file found
ad_08:
;file not found, give error and exit
  mov	byte [error_code],-2
  jmp	gf_exit1
;allocate memory for file
ad_20:
  mov	ax,[ecx+stat_struc.st_mode]
  and	ax,170000q			;isolate type
  cmp	ax,120000q
  jne	ad_21				;jmp if not symlink
;read name of symlink file
  mov	eax,85
  mov	ebx,[target_file_ptr]
  mov	ecx,[target_file_ptr]
  mov	edx,100			;buffer size
  int	byte 80h
  or	eax,eax
  js	ad_08			;jmp if error
  add	ecx,eax			;compute end of name
  mov	[ecx],byte 0		;terminate name
  call	file_status_name
  js	ad_08			;jmp if error
ad_21:
  mov	ebx,[ecx + stat_struc.st_mtime] ;get file time
  mov	[preamble+pre.target_time],ebx
  mov	eax,[ecx+stat_struc.st_size] ;get file size
  mov	[elf_file_size],eax	     ;save size
  call	m_allocate
  or	eax,eax
  js	gf_exit1		;jmp if error
  mov	[elf_file_ptr],eax
  mov	ecx,eax		;set ecx to buffer
;read elf file into memory
  mov	ebx,[target_file_ptr]
  mov	edx,[elf_file_size]  
  call	block_read_all
  or	eax,eax
  js	ad_24		;exit if error
;verify elf file is valid
ad_22:
  mov	ebp,[elf_file_ptr]
  cmp	dword [ebp],464c457fh
  je	ad_26		;jmp if file format ok
ad_24:
  mov	[error_code],byte -3
  jmp	gf_exit1	;exit file not in elf format
;save entry point for execution
ad_26:
  mov	eax,[ebp + elfheader.e_entry]
  mov	[preamble+pre.elf_phys_exec_entry],eax
  jmp	short gf_exit2
gf_exit1:
  _mov	eax,-1
gf_exit2:
  ret
;--------------------------------------------------

;-----------------------
  [section .data]
target_file_ptr	dd	0
;
_sym_table_ptr dd	0 ;     (local)       (relocated local)

elf_file_size	dd	0 ;size of elf file image


header_file: db ".abug_header.dat",0	;image of header1
abug_image: db ".abug_image.dat",0 ;load image
abug_fimage: db ".abug_fimage.dat",0 ;flag image
abug_sym:    db ".abug_sym.dat",0
abug_externs db ".abug_externs.txt",0
abug_lib:    db ".abug_lib.txt",0
abug_undo:   db ".abug_undo.dat",0

;----------- file map.inc -------------------
;  [section .data]
;
elf_file_ptr	dd 0	;

;---------------------------------------------------------------------
  [section .text]
struc pre
.elf_type_flag	resd 1 ;00000001h - dynamic section found
                        ;00000002h - lib wrapper for HLL found
                        ;00000004h - symbol table found
                        ;00000008h - debug section found
                        ;00000010h - source file found
                        ;00000020h - debug comments found
                        ;00000040h - no sections found (bit set)
.elf_phys_top		resd 1 ;start of elf header
.elf_phys_code_start	resd 1 ;code start,.data may proceed,may be in header
.elf_phys_exec_entry	resd 1 ;start of execution
.elf_phys_code_end	resd 1 ;code end
.elf_phys_load_end	resd 1 ;end of file data, .bss may follow
.elf_phys_bss_end	resd 1 ;end of everything
.app_main	resd 1 ;set if lib code at .elf_phys_exec_entry
.pheader_ptrs:	resd 8 ;last ptr is zero to signal end of list
.sheader_ptrs:	resd 27
.target_time	resd 2
.target_file	resb 128-16
pre_struc_size:
endstruc


struc head
.phys_start	resd 1	;load address for block
.phys_end	resd 1	;end address for block (beyond last byte)
.size		resd 1	;size of block
.offset		resd 1	;offset into fimage.dat and image.dat
.p_flags	resb 1	;flag from pheader
head_struc_size:
endstruc

struc sect
.sh_addr	resd 1	;phys load address
.sh_size	resd 1	;size of this section
.sh_flags	resb 1 ;bits 01h=writeable 02h=allocate 04h=execute
.sh_name	resb 10	;ascii name string (variable len)
sect_struc_size:
endstruc


  [section .data]

preamble times pre_struc_size db 0
phead times (head_struc_size * 8) db 0
shead times (sect_struc_size * 26) db 0
header_size	equ $ - preamble		;used to write out header

 [section .bss]

code_elf_offset	resd 1 ;offset of code section in elf file