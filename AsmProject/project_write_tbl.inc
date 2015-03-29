  extern database_open
  extern message_box
  extern database_close
  extern database_extract
  extern database_insert
  extern database_search

%include "dbs_struc.inc"
;-------------------------------------------------
; inputs: al = open_flag 0=database closed  1=database open (edit mode)
;         dbuf has current proj file
;         [proj_file_end_ptr] - points to zero at end of proj file
;         [selected_project] - points to pointer list, which points to name entries
;
project_write_tbl:
  mov	[open_flag],al		;save flag for later
  mov	esi,buf1		;get ptr to project name
  mov	edi,tname		;record stuff point
  call	stuff_string
  mov	[zero_ptr],edi		;save ptr to zero, it will be removed
;
; move project path to template
;
  mov	esi,buf3
  mov	edi,tpath
  call	stuff_string
  mov	al,'/'
  stosb
  mov	esi,buf2
  call	stuff_string
;
; move project assembler to template
;
  mov	esi,buf4
  mov	edi,tassembler
  call	stuff_string
;
; move project debugger to template
;
  mov	esi,buf5
  mov	edi,tdebugger
  call	stuff_string
;
; open the project file or create it
;
  mov	esi,proj_file		;database path
  mov	edi,proj_record_separator
  mov	ebp,dbuf		;work area
  cmp	byte [open_flag],1	;is database already open
  je	pwt_10			; jmp if database already open (edit mode)
  call	database_open		;returns ebp pointing to struc
  js	pwt_error		;jmp if error
;
; search for our project
;
pwt_10:
  mov	edi,[ebp+dbs.db_index]	;get ptr to top of index list
pwt_search:
  mov	esi,tname
  mov	edx,[zero_ptr]		;get location of tname end
  mov	byte [edx],0		;put zero at end for now
  call	database_search		;returns eax=0 if success
  mov	edx,[zero_ptr]		;restore space at end
  mov	byte [edx],' '		;  of project name
  js	pwt_insert		;jmp if no matching  record
;
; we have found a match, verify it is the right one, edi=index ptr
;
  push	edi			;save index ptr
  mov	esi,[edi]		;get ptr to record
  add	esi,5			;move past 'name='
  mov	edi,tname
  mov	ecx,19
  repe	cmpsb			;compare names
  pop	eax			;restore index ptr
  je	pwt_found
;
; this record does not match, move to next one
;
  mov	edi,eax
  add	edi,4
  jmp	pwt_search		;keep looking if wrong project
;
; we have found our project entry in database, delete it
;
pwt_found:
  xor	edi,edi			;no copy of this record
  call	database_extract	;remove the record
  js	pwt_error
;
; insert new record into database
;
pwt_insert:     
  mov	esi,record_template
  mov	ecx,record_template_size
  mov	al,1			;do alpahbetic insert
  call	database_insert
  js	pwt_error
;
  call	database_close		;write new file
  js	pwt_error
  ret

;---------------------
pwt_error:
  mov	esi,err_box
  call	message_box
  ret

err_box:
  dd	30003730h		;box color
  dd	err_msg
  dd	err_msg_end
  dd	0			;scroll
  db	30			;columns
  db	6			;rows
  db	5			;location-row
  db    10			;location-column
  dd	31003333h		;box color

err_msg: db ' Error updating file',0ah
         db ' project.tbl',0ah
         db ' -any key to continue',0
err_msg_end:
;
;---------------------------------------------------
; move data from esi -> edi until space found on input
stuff_string:
  lodsb
  stosb
  cmp	al,' '
  ja	stuff_string
  dec	edi			;move back to space
  ret

;-------------------------------------------------
  [section .data]

open_flag  db 0  ; 0=database closed  1=database open (edit menu)
proj_file: db '/usr/share/asmmgr/project.tbl',0
proj_record_separator db 3,0ah,'~',0ah
;
; the record_template is written to the database.
; It must have a constant length and is used to
; read or write records.
;
record_template:
          db 'name='
tname     db       '                    ',0ah
          db 'path='
tpath     db       '                                                                                                    ',0ah
          db 'assembler='
tassembler db           '                    ',0ah
          db 'debugger='
tdebugger db           '                     ',0ah
record_template_size equ $ - record_template

zero_ptr  dd	0

  [section .text]

