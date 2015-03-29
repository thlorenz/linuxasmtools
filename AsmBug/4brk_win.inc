  extern blk_del_bytes

%ifndef DEBUG
struc mouse_pkt
.code	resb 1		;code = 4(press) 5(release) 6(MotionNotify)
.but	resb 1		;evemt window code
.seq	resw 1		;pkt sequence#
.time	resd 1		;time of event
.root	resd 1		;root win id
.ewinn	resd 1		;event win id
.cwin	resd 1		;child win (0=none)
.rootx	resw 1		;root pix column
.rooty	resw 1		;root pix row
.eventx resw 1		;event pix column
.eventy resw 1		;event pix row
.mask	resw 1		;event bits
.same	resb 1		;same screen bool
	resb 1		;unused
;mask bits are:
; 10-numlock 08-alt 04-ctrl 02-caplock 01-shift
endstruc
%endif

;--------------------------
brk_add:
  mov	eax,'    '
  mov	[bbuf],eax
  mov	[bbuf+4],eax		;clear the buffer
;set colors
  mov	eax,[stringBColor]
  call	color_num_lookup
  mov	[b_stringBColor],al
  mov	eax,[stringFColor]
  call	color_num_lookup
  mov	[b_stringFColor],al

  mov	eax,[cursorBColor]
  call	color_num_lookup
  mov	[b_cursorBColor],al
  mov	eax,[cursorFColor]
  call	color_num_lookup
  mov	[b_cursorFColor],al

  mov	ebp,win_block
  mov	eax,brk_block1
  call	x_get_text


  mov	[b_initial_cursor_col],byte 16
  mov	esi,bbuf
  call	hexascii_to_dword ;returns ecx

  mov	edx,ecx
  call	add_break

be_exit:
  or	[win_bit_map],byte 11h
  ret
;------------
  [section .data]


brk_block1:
b_data_buffer_ptr    dd bbuf ;cleared or preload with text
b_buffer_size        dd 8 ;buffer size, must be >= window size
b_display_row        db 0 ;row (1-x)
b_display_column     db 16 ;column (1-x)
b_initial_cursor_col db 16 ;must be within data area
b_window_size        dd 8 ;bytes in window
b_scroll             dd 0 ;adjustment to start of data (window scroll)
b_stringBColor       dd 0 ;string background color#
b_stringFColor       dd 0 ;string foreground color#
b_cursorBColor       dd 0 ;string cursor background color#
b_cursorFColor       dd 0 ;string cursor foreground color#

bbuf times 9 db 0

  [section .text]
;------------------------------------------

;-------------------------
;clear all breaks
brk_zap:
  mov	edi,Breaks
  mov	ecx,max_breaks * 5
  xor	eax,eax
  rep   stosb			;clear breaks
  or	[win_bit_map],byte 12h	;show break and code windows
  ret  
;-------------------------
;show help
brk_?:
  call	break_help
  ret

;-------------------------
;toggle break, or pop up menu on value
;left click = menu
;right click = toggle
brk_pop_up:
  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  xor	ebx,ebx
  mov	bl,al		;save row
  dec	bl
  imul	ebx,5		;index into
  add	ebx,Breaks	;  breaks
  mov	eax,[ebx]	;get break value
  or	eax,eax
  jz	bpu_exit	;exit if null value
  mov	bl,[ecx+mouse_pkt.but]	;get click type
  cmp	bl,3		;right click
  je	bpu_menu	;jmp if right click
  cmp	bl,1		;left click
  jne	bpu_exit	;exit if unknown click
;this was a left click, toggle break
  mov	edx,eax
  call  remove_break
  mov	[win_bit_map],byte 1fh
  jmp	short bpu_exit 	
bpu_menu:
  mov	ebx,14		;column
  mov	ecx,0 
;input: eax = value to work on
;       ebx = x location (column)
;       ecx = y location (row)
  call	pop_up
  
bpu_exit:
  ret


;--------------------------------------------------
; input:  edx = break address
; output: eax = zero if success
;             = non-zero if error
;               Possible errors are: out of range
;                                    too many breaks
; all registers clobbered
add_break:
  push	ebp
  call	find_break
  jecxz	not_found
  jmp	abb_exit		;exit if break exists
not_found:
  mov	ebx,Breaks
  cmp	edx,[preamble+pre.elf_phys_code_start]
  jb	abb_err_exit		;exit if out of range
  cmp	edx,[preamble+pre.elf_phys_code_end]
  jb	abb_07			;jmp if adr ok
  cmp	edx,[preamble+pre.elf_phys_load_end]
  ja	abb_err_exit
  mov	[msg_ptr],dword break_warning
;if data here, enable code disassembly
abb_07:
  push	edx
  push	ebx
  call	physical2offset
  call	offset2flag_ptr
  or	byte [edx],80h		;set code here
  mov	byte [do_hunt],1
  mov	[hunt_initial_offset],ebp
  call	code_hunt
  pop	ebx
  pop	edx
;find free slot at end of list
  mov	ecx,max_breaks		;max break count
  xor	eax,eax
abb_lp:
  cmp	[ebx],eax
  je	abb_10			;jmp if hole found
  add	ebx,5
  loop	abb_lp			;loop till hole found
  jmp	abb_err_exit	
;insert break here
abb_10:
  mov	[ebx],edx
  add	ebx,4			;move to restore stuff point
;get restore data
  call	physical2offset		;set ebp=offset
  call	offset2code_ptr		;set edx=code ptr
  mov	dl,[edx]		;get restore data
  mov	[ebx],dl
  jmp	short abb_exit
abb_err_exit:
  mov	[msg_ptr],dword break_error
  mov	eax,-1
abb_exit:
  pop	ebp
  ret  

;--------------
  [section .data]
break_warning: db 00 ;
	db bw_len
bw_txt: db 'Warning - break in data section'
bw_len equ $ - bw_txt

break_error: db 00
	db be_len
be_txt: db 'Too many breaks'
be_len equ $ -  be_txt

  [section .text]
;--------------------------------------------------
; input: edx = break to remove
remove_break:
  push	ebp
  call	find_break
  jecxz	rbb_exit		;exit if not found
;break found at [ebx]
rbb_10:
  mov	eax,5			;remove 5 bytes
  lea	ebp,[Breaks + (5 * max_breaks)] 
  mov	edi,ebx ;top of delete area
  call	blk_del_bytes
  xor	eax,eax
  mov	[Breaks + (5*(max_breaks -1))],eax
rbb_exit:
  pop	ebp
  ret
;--------------------------------------------------
; input:  edx = absolute break address
; output: ecx=0 if not found
;         ecx=x if found & ebp=shared memory ptr
;                          [ebx] = break ptr
find_break:
  mov	ecx,max_breaks
  mov	ebx,Breaks
rbb_lp:
  cmp	[ebx],edx
  je	fb_exit			;jmp if break found
  add	ebx,5
  loop	rbb_lp			;loop till break found
fb_exit:
  ret

;-------------------------------------------------
; toggle_break
; input: eax = address
;
toggle_break:
  mov	edx,eax
  call	find_break
  jecxz	tb_add		;jmp if add
  call	remove_break
  jmp	short tb_exit
tb_add:
  call	add_break
tb_exit:
  ret

