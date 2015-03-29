;------------------  breakpoint display --------------------
;
; colors:
;   BrkMenuForButton=white
;   BrkMenuBakButton=black
;   BrkBColor=black
;   BrkFColor=white
;
; location 0,14
;   column 14 (zero based)
;   row 0
;   width 10
;   rows=11
;
; verify breaks at "Breaks" are legal and remove bad breaks
brk_win_setup:
  mov	esi,Breaks
  mov	edi,esi
  push	ebp
  mov	ecx,8		;loop count
bws_lp:
  lodsd			;get next break
  or	eax,eax
  jz	bws_done	;jmp if end of breaks
  mov	edx,eax
  mov	ebx,eax
  call	physical2offset
  jc	bws_lp		;jmp if error
  call	offset2code_ptr
  lodsb
  cmp	al,[edx]
  jne	bws_tail	;ignore this break if data mismatch
  mov	[edi],ebx
  add	edi,4
  stosb
bws_tail:
  loop	bws_lp
bws_done:
  xor	eax,eax
bws_lp2:
  cmp	edi,Breaks+4*8
  jae	bws_exit
  stosd
  jmp	short bws_lp2
bws_exit:
  pop	ebp
  ret
;-------------------------------------------------------------------
show_breaks:
  test	byte [win_bit_map],1
  jz	sb_10			;jmp if menu in place
  call	brk_menu
;display break values
sb_10:
  mov	ebx,[brkFColor]
  mov	ecx,[brkBColor]
  call	window_id_color
 
  mov	eax,14 			;x location (col)
  mov	ebx,1  			;y locatin (row)
  mov	ecx,10			;width
  mov	edx,10			;height
  mov	esi,1			;use current color
  call	window_clear_area

  mov	[reg_row],dword 1
  mov	esi,Breaks	;get ptr to breaks
sb_lp:
  lodsd			;get break
  or	eax,eax
  jz	sb_done		;jmp if end of breaks
  push	esi
  mov	edi,reg_build	;get build area
  call	dwordto_hexascii

  mov	ecx,15		;column
  mov	edx,[reg_row]
  mov	esi,reg_build
  mov	edi,8
  call	window_write_line
  inc	dword [reg_row]
  pop	esi
  inc	esi		;move past value
  jmp	short sb_lp
sb_done:
  ret
;-----------------------------------------------------
brk_menu:
;display fixed window areas
  mov	ebx,[brkFColor]
  mov	ecx,[brkBColor]
  call	window_id_color
 
  mov	eax,14 			;x location (col)
  xor	ebx,ebx			;y locatin (row)
  mov	ecx,10			;width
  mov	edx,1			;height
  mov	esi,1			;use current color
  call	window_clear_area
;     regMenuForButton=blue
;     regMenuBButton=skyblue
  mov	ebx,[brkMenuForButton]
  mov	ecx,[brkMenuBakButton]
  call	window_id_color

  mov	esi,brk_menu_block
  call	window_write_table
  ret
;---------------
  [section .data]

brk_menu_block:
  db 12
  dw 14		;column
  dw 0		;row
  db 1		;length
  db '?'

  db 12
  dw 16		;column
  dw 0		;row
  db 3		;length
  db 'Add'

  db 12
  dw 20		;column
  dw 0		;row
  db 3		;length
  db 'Zap'

  db 0


  [section .text]



