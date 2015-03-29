  extern database_copy_record

  [section .text]

;---------------------
ps_error:
  mov	esi,err_box2
  call	message_box
ps_exitj:
  mov	eax,-1
  ret

;-------------------------------------------------
; inputs: none
; output: eax = 0 if success and ebx= ptr to index if success, else negative error
;               -1 = no projects found
;               negative for system errors
;
project_select:
;
; open the project file or create it
;
  mov	esi,proj_file		;database path
  mov	edi,proj_record_separator
  mov	ebp,dbuf		;work area
  call	database_open		;returns ebp pointing to struc
  js	ps_error		;jmp if error
;
; check if any projects found
;
  mov	ebx,[ebp+dbs.db_index]	;get ptr to index
  mov	eax,[ebp+dbs.db_index_end]
  cmp	eax,ebx
  jne	ps_10			;jmp if at least one project defined
  mov	eax,-1
  jmp	ps_exit
;
; copy project names to default_path
;
ps_10:
  mov	ebx,[ebp+dbs.db_index]	;get ptr to index
  mov	edi,default_path	;destination
ds_lp1:
  mov	esi,[ebx]		;get ptr to string
  or	esi,esi
  jz	ds_20			;jmp if all strings moved
  add	esi,5			;move past 'name=' infront of name
  call	stuff_string		;move string
  xor	eax,eax
  stosb				;put zero at end of string
  add	ebx,4			;move to next index
  jmp	short ds_lp1
;
; show available projects
;
ds_20:
  stosb				;add final zero to strings
  mov	edi,buf_top		;buffer to create menu
  mov	esi,default_path	;text strings
  call	select_1up_list_left
  or	eax,eax
  js	ps_exitj		;exit if error
  or	al,al
  jz	ps_exitj		;exit if escape pressed
;
; move selected record to template
; 
  xor	ebx,ebx
  mov	bl,al
  dec	ebx			;create zero based index
  shl	ebx,2			;create dword index
  mov	ebp,dbuf		;get ptr to database struc
  mov	eax,[ebp+dbs.db_index]	;get ptr to index
  add	eax,ebx			;index into table
;
; eax = ptr to index, copy record to template
;
  mov	[selected_index_ptr],eax
  mov	edi,record_template
  call	database_copy_record
;
; move data to form
;
  mov	esi,tname
  mov	edi,buf1
  call	stuff_string
;
; find directory for this project, scan to end of tpath
;
  mov	esi,tpath
ds_lp2:
  lodsb
  or	al,al
  jnz	ds_lp2			;loop till end
;
; scan back to '/'
ds_lp3:
  dec	esi
  cmp	byte [esi],'/'
  jne	ds_lp3
;
  mov	byte [esi],0		;terminate the path
  mov	[zero_ptr],esi
;
; move directory to  buf2
;
  inc	esi
  mov	edi,esi
  mov	edi,buf2
  call	stuff_string
  mov	esi,tpath
  mov	edi,buf3
  call	stuff_string
  mov	byte [edi],' '		;force space at end
;
  mov	esi,tassembler
  mov	edi,buf4
  call	stuff_string
;
  mov	esi,tdebugger
  mov	edi,buf5
  call	stuff_string
;
; restore the '/' just incase
;
  mov	esi,[zero_ptr]
  mov	byte [esi],'/'
  xor	eax,eax
  mov	ebx,[selected_index_ptr]
ps_exit:
  ret

err_box2:
  dd	30003730h		;box color
  dd	err_msg2
  dd	err_msg_end2
  dd	0			;scroll
  db	30			;columns
  db	6			;rows
  db	5			;location-row
  db    10			;location-column
  dd	31003333h		;box color

err_msg2: db ' Error reading file',0ah
         db ' project.tbl',0ah
         db ' -any key to continue',0
err_msg_end2:
;

;-----------------------
  [section .data]
selected_index_ptr	dd	0
  [section .text]
