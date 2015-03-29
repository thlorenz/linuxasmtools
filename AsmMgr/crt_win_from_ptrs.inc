
  extern crt_line
;---------------------------------------------
;  crt_win_from_ptrs - display window using ptrs to lines
; INPUTS
;    ebx = ptr to color table
;    ch  = starting row
;    cl  = starting col
;    dl = number of cols
;    dh = number of rows
;    ebp = ptr to list of line ptrs
;    edi = adjustment to pointers in pointer list (ebp).
;          negative number ok, display starts at [ptr + edi]       
;    each line terminated with 0ah or 0
;    codes 1-9 found in line are color info.
; OUTPUT
;    display line is built in  temp_buf and displayed
; NOTES
;   source file: crt_ptr_window.asm
; * ----------------------------------------------
  global crt_win_from_ptrs
crt_win_from_ptrs:
swfp_lp:
  mov	esi,[ebp]	;get ptr to next line
  or	esi,esi		;check if end of table
  jnz	swfp_10		;jmp if line ok
  mov	esi,swfp_blank
  sub	ebp,4		;move to prev line
  jmp	short swfp_20
swfp_10:
  push	ecx
  push	edx
  push	ebx
  push	ebp
  call	build_line
  pop	ebp
  pop	ebx
  pop	edx
  pop	ecx
swfp_20:
;  push	edi
  push	ecx
  push	edx
  push	ebx
  xor	edi,edi		;set scroll to zero
  call	crt_line
  pop	ebx
  pop	edx
  pop	ecx
;  pop	edi
  inc	ch		;move to next row
  add	ebp,4		;move to next line
  dec	dh
  jnz	swfp_lp		;loop till done
  ret

swfp_blank:  db ' ',0ah
;---------------------------------------------
; INPUT esi = ptr to record
; structure describing a directory entry
;struc dtype
;.d_size	resd 1	;byte size for fstat .st_size
;.d_mode	resw 1	;type information from fstat .st_mode 
;.d_uid  resw 1  ;owner code
;.d_len   resb 1  ;length byte from dent structure
;.d_type  resb 1  ;type code 1=dir 2=symlink 3=file
;.d_nam resb 1	;directory name (variable length)
;endstruc
;
; OUTPUT: esi=temp_buf with line
;
build_line:
  mov	edi,temp_buf		;location for line
;check if empty  directory message
  cmp	esi,no_files_msg
  je	bl_skip			;jmp if empty dir
  mov	al,2
  stosb				;store color code 2
  mov	eax,'    '
  stosd
  stosd
  push	edi
  dec	edi
  cmp	byte [esi+dtype.d_type],1 ;is this a dir
  je	skip_dir_size
  mov	eax,[esi+dtype.d_size]	;get file size
  call	dword_to_r_ascii
skip_dir_size:
  pop	edi
;store space color
  mov	al,1
  stosb				;store color code 1
  mov	al,' '
  stosb				;put space after file size
  cmp	byte [esi+dtype.d_type],1 ;is this a dir
  je	normal_color		;use normal color if dir
;check if executable
  test	word [esi+dtype.d_mode],100q
  jz	normal_color
  mov	al,3			;exec color
  jmp	short stuff_color
normal_color:
  mov	al,1
stuff_color:
  stosb
  xor	ecx,ecx
  mov	cl,[esi+dtype.d_type]	;get type code
  add	ecx,code_table -1
  mov	al,[ecx]
  stosb				;store code
  lea	esi,[esi + dtype.d_nam] ;get name
bl_skip:
  call	str_move
  mov	esi,temp_buf
  ret

code_table: db '/@ '
;----------------------------------------
