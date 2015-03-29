;---------------------------------------------------
;>1 dcache
;dcache_write_repeat - write repeat to cache
;  stops at edge of screen
;
; INPUT
;    al = repeat char
;    ah = repeat flag, 0=horizontal 1=vertical
;    ecx = repeat count
;    color and cursor location already set
;
;  OUTPUT
;     buffer cursor at end of last write
;     ah=repeat color al=repeat char
;     ecx=0
;     dh=row dl=column
;     edi=image index
;     edp=image buffer
;<
; registers kept: ah=color al=char out
;                 ebx -scratch
;                 ecx -repeat count
;                 dh=row dl=col (track input data)
;                 esi=scratch
;                 edi=index into image
;                 ebp=image top
;
;------------------------------------------------------
  extern image
  extern current_index
  extern stuff
  extern index_to_rowcol
  extern rowcol_to_index
  extern image_write_color
  extern dcache_rows,dcache_columns

  global dcache_write_repeat                 
dcache_write_repeat:
  push	eax
  mov	[repeat_flag],ah	;0=horizontal
  mov	ebp,[image]
  mov	eax,[current_index]
  call	index_to_rowcol
  mov	edx,eax		;dh=row dl=col
  mov	edi,[current_index]
  pop	eax		;restore char to display
  mov	ah,[image_write_color]
dwr_loop:
  jecxz	dwr_tail	;jmp if end of block
  cmp	dh,[dcache_rows]
  ja	dwr_tail	;jmp if at bottom of display
  cmp	dl,[dcache_columns]
  ja	dwr_tail	;jmp=check if more lines
  call	stuff
  dec	ecx
  cmp	[repeat_flag],byte 0
  je	dwr_loop	;jmp if horizontal repeat
  dec	dl
  inc	dh
  push	eax		;save color and char
  mov	eax,edx		;get row/col in eax
  call	rowcol_to_index
  mov	edi,eax		;set new index
  pop	eax		;restore color and char
  jmp	short dwr_loop
; we are done with repeat
dwr_tail:
;compute index from row/col
  cmp	dh,[dcache_rows] ;end of display?
  je	dwr_exit	;jmp if at bottom of screen
  cmp	[repeat_flag],byte 0	;horizontal rep?
  je	dwr_set			;if horizontal rep, stay on line
;this is vertical repeat, move to next line
  inc	dh		;vert repeat, move to next line
  mov	dl,1		;column 1
dwr_set:
  push	eax
  push	ecx
  mov	eax,edx
  call	rowcol_to_index
  mov	edi,eax		;index to edi
  pop	ecx
  pop	eax
dwr_exit:
  mov	[current_index],edi
  ret

;-------------
  [section .data]
repeat_flag:	db 0	;0=horizontal 1=vertical
  [section .text]
