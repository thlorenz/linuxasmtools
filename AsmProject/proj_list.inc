  extern crt_win_from_ptrs
  extern file_read_all
  extern crt_set_color
  extern crt_line
  extern file_write_close
  extern blk_del_bytes
;------------------------------------------------
select_project:
  call	read_project_file
  call	file_to_form
  mov	ebx,standard_colors
  mov	ch,1		;starting row
  mov	cl,1		;starting column
  mov	dl,[proj_win_width] ;total columns
  dec	dl
  mov	dh,[crt_rows]	;total rows
  mov	ebp,display_line_ptrs
  mov	edi,0		;no adjustment
  call	crt_win_from_ptrs
;highlight selected project
  mov	eax,[button_color]
  call	crt_set_color
  mov	esi,[selected_project]
  cmp	dword [esi],0
  je	sp_exit			;exit if no selected project
  mov	ebx,standard_colors	;dummy entry, not used
  mov	ch,byte [p_select_row]	;row
  mov	cl,1			;column
  mov	dl,[proj_win_width]
  dec	dl
  mov	esi,[esi]		;get ptr to data
  xor	edi,edi			;set scroll to 0
  call	crt_line		;esi=ptr to data
sp_exit:
  ret
;------------------------------------------------

  [section .data]
selected_project:  dd	proj_ptrs
p_select_row	   dd	3

max_projects	equ	20

display_line_ptrs:
  dd	header_msg1
  dd	header_msg2
proj_ptrs:
  times max_projects dd	0
last_project: dd 0

header_msg1 db 1,"Projects (ESC=abort",0
header_msg2 db 1,"-------------------",0
  [section .text]
;------------------------------------------------
; legal keys are: up,down,enter,esc

project_key:
  mov	esi,pkey_table
  call	key_decode1
  call	eax
  ret

pkey_table:
  dd	p_ignore	;error state?

    db 1bh,5bh,41h,0		;15 pad_up
  dd	p_up
    db 1bh,5bh,42h,0		;20 pad_down
  dd	p_down

    db 1bh,4fh,41h,0		;15 pad_up
  dd	p_up
    db 1bh,4fh,42h,0		;20 pad_down
  dd	p_down

    db 1bh,4fh,78h,0		;15 pad_up
  dd	p_up
    db 1bh,4fh,72h,0		;20 pad_down
  dd	p_down

    db 1bh,0			;esc
  dd	p_exit
    db 0ah,0			;enter
  dd	p_enter
    db 0dh,0			;enter
  dd	p_enter
    db	0			;end of table
  dd	p_ignore		;no match action
;------------------
p_up:
  mov	esi,[selected_project]
  cmp	esi,proj_ptrs
  je	p_ignore		;jmp if can not move up
  sub	esi,4
  mov	[selected_project],esi
  jmp	short compute_row
;------------------
p_down:
  mov	esi,[selected_project]
  add	esi,4
  cmp	dword [esi],0
  je	p_ignore		;jmp if can not move down
  mov	[selected_project],esi
compute_row:
  sub	esi,proj_ptrs
  shr	esi,2
  add	esi,3
  mov	[p_select_row],esi
  jmp	p_ignore
;---------------------------------------------------------------
; enter key pressed, also entered here from browser to process
; the new,register actions
;---------------------------------------------------------------
p_enter:
  cmp	byte [active_button],1
  jne	p_10			;jmp if not open
;this is a project open request, set start of file = @
  call	write_project_file
  mov	al,0
  jmp	p_quit
;check if delete project request
p_10:
  cmp	byte [active_button],2	;delete?
  jne	p_20			;jmp if not delete
;this is a project delete request, write_project_file handles this
  call	write_project_file	;go write file
  mov	dword [selected_project],proj_ptrs	;re-initialize proj ptr
  mov	byte [p_select_row],3		;re-initialize row ptr
  mov	byte [active_flag],2
  mov	al,1			;re-read project file	
  jmp	p_quit
p_20:				;not delete, check if edit(3)
  cmp	byte [active_button],3
  jne	p_30			;jmp if not edit
;request to edit current selected project
  call	fill_form
  cmp	word [kbuf],01bh	;check if esc pressed in from
  je	p_exit			;exit if esc typed
  call	build_proj
  or	eax,eax
  js	p_exit
  call	write_project_file
  jmp	short p_exit
;check if new project
p_30:
  cmp	byte [active_button],4
  jne	p_40			;jmp if not a new project
;request to create a new project
  call	fill_form
  cmp	word [kbuf],01bh	;check if esc pressed
  je	p_exit			;exit if esc pressed
  call	build_proj
  or	eax,eax
  js	p_exit			;exit if error in form
  call	write_project_file
  jmp	short p_exit
;check if resgister existing directory as project
p_40:
  cmp	byte [active_button],5
  jne	p_exit
;register existing directory
  call	fill_form
  cmp	word [kbuf],01bh
  je	p_exit			;exit if esc typed in form
  call	build_proj
  or	eax,eax
  js	p_exit			;exit if error in form
  call	write_project_file
;------------------
p_exit:
  mov	byte [active_flag],2	;select buttons
p_ignore:
  mov	al,2
p_quit:
  ret
;-------------------------------------------------
; only mouse clicks in project window come here
; kbuf+3 has click row
;
project_mouse:
  xor	eax,eax
  mov	al,[kbuf+3]
  mov	cl,al		;save row#
  cmp	al,23
  jae	p_ignore	;exit if out of range
  cmp	al,3
  jb	p_ignore	;exit if out of range
  shl	eax,2		;comvert to dword ptr
  add	eax,display_line_ptrs -4
  mov	ebx,[eax]	;get pointer
  or	ebx,ebx
  jz	p_ignore	;exit if no data here
  mov	[selected_project],eax
  mov	byte [p_select_row],cl	;save row# 
  call	file_to_form
  jmp	p_enter
;-------------------------------------------------
; inputs: [active_button] 1=open 2=delete 3=edit 4=new 5=add
;         dbuf has current proj file
;         [proj_file_end_ptr] - points to zero at end of proj file
;         [selected_project] - points to pointer list, which points to name entries
;
write_project_file:
  call	fix_names_in_dbuf	;restore quote at end of :name
  mov	al,byte [active_button]	;get mode
  cmp	al,1			;check if open
  jne	wpf_10			;jmp if not open
;modify selected entry so it will be opened by asmmgr
  mov	esi,[selected_project]
  mov	esi,[esi]		;get data ptr
  or	esi,esi
  jz	wpf_exit		;exit if null entry
wpf_lp1:
  inc	esi
  cmp	word [esi],'"/'		;look for start of file
  jne	wpf_lp1
  inc	esi
  mov	byte [esi],'@'
  jmp	wpf_write		;go write file
;check if delete option requested
wpf_10:
  cmp	al,2			;check if delete
  jne	wpf_20			;jmp if not delete
;delete current selected project
  call	delete_project_entry
  jmp	wpf_write		;go write file
;check if edit mode, al=[active_button]
wpf_20:
  cmp	al,3			;check if edit
  jne	wpf_40			;jmp if not edit
  call	delete_project_entry
  call	form_to_dbuf
  jmp	wpf_write
;check if new project write
wpf_40:
  cmp	al,4			;check if new project
  jne	wpf_60			;jmp if not new project
  call	form_to_dbuf
  jmp	wpf_write
;check if register existing directory as project
wpf_60:
  cmp	al,5
  jne	wpf_exit		;exit if unknown reqest
  call	form_to_dbuf
wpf_write:			;write file in dbuf
  mov	eax,dbuf
  mov	ebx,proj_file		;file name
  mov	ecx,[proj_file_end_ptr]
  sub	ecx,eax			;compute file length -> ecx
  mov	ebp,[enviro_ptrs]
  mov	esi,2			;write to $HOME
  call	file_write_close
wpf_exit:
  ret
;---------------------------------------------------
fix_names_in_dbuf:
  mov	esi,dbuf
fnid_lp:
  lodsb
  or	al,al
  jnz	fnid_lp
  cmp	esi,[proj_file_end_ptr]
  jae	fnid_exit
  mov	byte [esi -1],'"'	;restore quote
  jmp	short fnid_lp
fnid_exit:
  ret
;---------------------------------------------------
;form_to_dbuf - insert current form data in dbuf
; inputs: 
;         dbuf has current proj file
;         [proj_file_end_ptr] - points to zero at end of proj file
;         [selected_project] - points to pointer list, which points to name entries
; output:
;    project entry  ":xxxx"              <-- project name
;                   "_location"  "xxx"   <-- project location
;                   "_assembler" "xxx"   <--
;                   "_debug"     "xxx"   <--
;
form_to_dbuf:
  mov	edi,[proj_file_end_ptr]	;destination for our form data
  mov	al,0ah		;lf
  stosb
  mov	al,'"'
  stosb
  mov	al,':'
  stosb
  mov	esi,buf1
  cmp	byte [esi],' '	;check for no name
  jne	ftd_05		;jmp if name found
  mov	esi,new_name
ftd_05:
  call	stuff_string	;move name
  mov	al,'"'
  stosb			;terminate name
;now do location
  mov	esi,p_loc
  call	str_move	;move location str
  mov	al,'"'
  stosb			;quote infront of path
  mov	esi,buf3	;project path
  call	stuff_string
  mov	esi,buf2	;project dir
  cmp	byte [esi],'/'
  je	ftd_10
  mov	al,'/'
  stosb
  cmp	byte [esi],' '
  jne	ftd_10		;jmp if project directory found
  mov	esi,new_name
ftd_10:
  call	stuff_string
  mov	al,'"'
  stosb			;terminal quote for location line
;now do assembler
  mov	esi,p_asm
  call	str_move	;move "_assembler" 
  mov	al,'"'
  stosb			;preceeding quote for assembler name
  mov	esi,buf4
  call	stuff_string
  mov	al,'"'
  stosb
;now do debugger
  mov	esi,p_bug
  call	str_move
  mov	al,'"'
  stosb
  mov	esi,buf5
  call	stuff_string
  mov	al,'"'
  stosb
  mov	al,0ah
  stosb
  stosb
;store new file end position
  mov	[proj_file_end_ptr],edi
  ret
 		

;-----------
p_loc:	db	0ah,'"_location" ',0
p_asm:	db	0ah,'"_assembler" ',0
p_bug:	db	0ah,'"_debug" ',0
new_name db	'new',0
;---------------------------------------------------
; move data from esi -> edi until space found on input
stuff_string:
  lodsb
  stosb
  cmp	al,' '
  ja	stuff_string
  dec	edi			;move back to space
  ret
;---------------------------------------------------
; delete project entry from dbuf
;
delete_project_entry:
  mov	esi,[selected_project]
  mov	esi,[esi]		;get data ptr
  or	esi,esi			;check if null entry
  jz	dpe_exit		;exit if no change
;scan back to start of entry
dpe_lp1:
  dec	esi
  cmp	byte [esi -1],0ah
  jne	dpe_lp1
  mov	edi,esi			;save start of delete area
;find end of delete area
dpe_lp2
  lodsb
  or	al,al
  jz	dpe_20			;jmp if end of file found
  cmp	word [esi],'":'		;check if start of next entry
  jne	dpe_lp2			;loop till end of entry
;end of entry found, compute size
dpe_20:
  dec	esi
  mov	eax,esi			;eax = entry end ptr
  sub	eax,edi			;compte length
  mov	ebp,[proj_file_end_ptr]
  call	blk_del_bytes
  mov	[proj_file_end_ptr],ebp	;save new file end ptr
dpe_exit:
  ret

;-------------------------------------------------
read_project_file:
  mov	ebp,proj_file	;file name
  mov	edx,max		;size of buffer
  mov	ecx,dbuf	;buffer
  mov	ebx,[enviro_ptrs]
  mov	al,2
  call	file_read_all
  js	rpf_exit	;exit if error
  add	eax,dbuf
  mov	word [eax],0	;put zero at end of data
  mov	[proj_file_end_ptr],eax
;scan for project names
  mov	esi,dbuf
  mov	edi,proj_ptrs
rpf_lp:
  inc	esi
  cmp	word [esi],0
  je	rpf_exit
  cmp	word [esi],'":'
  jne	rpf_lp		;loop till project name found
;save pointer to this project name
  add	esi,2
  mov	[edi],esi
  add	edi,4		;move to next pointer store loc
;find end of name
rpf_lp2:
  inc	esi
  cmp	byte [esi],'"'
  jne	rpf_lp2
  mov	byte [esi],0	;terminate name
  jmp	short rpf_lp	;go look for another name
rpf_exit:
  xor	eax,eax
rpf_lp3:
  stosd
  cmp	edi,last_project
  jb	rpf_lp3
  ret
;-------------------------------------------------
proj_file: db '.asmide/mgr/project.tbl',0
