  extern color_num_lookup
  extern x_get_text
  extern trace_regsset

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

;------------------------------------------
reg_mouse_?:
  call	reg_help
  ret
;------------------------------------------
reg_value_click:
  mov	bl,[ecx+mouse_pkt.but]	;get click type
  cmp	bl,1		;left click
  je	reg_edit	;jmp if left click
  jmp	reg_pop_up
;-----------------
reg_edit:
  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  cmp	al,0
  jne	re_40		;jmp if range ok
  jmp	re_exit
re_40:
  mov	[r_display_row],al
  shl	eax,3		;make index
  add	eax,reg_tbl-8	;look up table
  mov	eax,[eax]	;get register ptr
  mov	[reg_ptr],eax		;save reg ptr
  mov	eax,[eax]	;get register value
  mov	edi,rbuf
  call	dwordto_hexascii
;set colors
  mov	eax,[stringBColor]
  call	color_num_lookup
  mov	[r_stringBColor],al
  mov	eax,[stringFColor]
  call	color_num_lookup
  mov	[r_stringFColor],al

  mov	eax,[cursorBColor]
  call	color_num_lookup
  mov	[r_cursorBColor],al
  mov	eax,[cursorFColor]
  call	color_num_lookup
  mov	[r_cursorFColor],al

  mov	ebp,win_block
  mov	eax,reg_block1
  call	x_get_text

  mov	[r_initial_cursor_col],byte 5
  mov	esi,rbuf
  call	hexascii_to_dword ;returns ecx

  mov	edi,[reg_ptr]
  mov	[edi],ecx	;store new register value

;  mov	esi,regs_1
;  call	trace_regsset
re_exit:
  or	[win_bit_map],byte 4 + 8;show regs+mem(reg tracking)
  ret
  
;------------
  [section .data]

reg_ptr		dd 0

reg_block1:
r_data_buffer_ptr    dd rbuf ;cleared or preload with text
r_buffer_size        dd 8 ;buffer size, must be >= window size
r_display_row        db 0 ;row (1-x)
r_display_column     db 5 ;column (1-x)
r_initial_cursor_col db 5 ;must be within data area
r_window_size        dd 8 ;bytes in window
r_scroll             dd 0 ;adjustment to start of data (window scroll)
r_stringBColor       dd 0 ;string background color#
r_stringFColor       dd 0 ;string foreground color#
r_cursorBColor       dd 0 ;string cursor background color#
r_cursorFColor       dd 0 ;string cursor foreground color#

rbuf times 9 db 0

  [section .text]
;------------------------------------------

;reg_tbl:
;  dd r1_eax,r2_eax
;  dd r1_ebx,r2_ebx
;  dd r1_ecx,r2_ecx
;  dd r1_edx,r2_edx
;  dd r1_esi,r2_esi
;  dd r1_edi,r2_edi
;  dd r1_ebp,r2_ebp
;  dd r1_esp,r2_esp
;  dd r1_eip,r2_eip
;  dd 0

reg_name_click:
  mov	bl,[ecx+mouse_pkt.but]	;get click type
  cmp	bl,3		;right click
  je	reg_pop_up	;jmp if right click

;set register tracking for mem window
  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  add	eax,reg_translate-1
  mov	al,[eax]		;get register code
  movzx ecx,al
  jmp	ms_60
;-------------------
  [section .data]
reg_translate:
 db 24 ;eax
 db 00 ;ebx
 db 04 ;ecx
 db 08 ;edx
 db 12 ;esi
 db 16 ;edi
 db 20 ;ebp
 db 60 ;esp
 db 48 ;eip

  [section .text]

reg_pop_up:
  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  xor	ebx,ebx
  mov	bl,al		;save row
  dec	bl
  cmp	bl,8
  ja	rpu_exit	;eixt if out of range
  shl	ebx,3		;make index
  add	ebx,reg_tbl	;look up table
  mov	eax,[ebx]	;get register ptr
  mov	eax,[eax]	;get register value
;check if break toggle or menu
;  mov	bl,[ecx+mouse_pkt.but]
;  cmp	bl,1		;check if left click
;  jne	rpu_20		;jmp if right click
;  call	toggle_break
;  or	[win_bit_map],byte 1eh
;  jmp	short rpu_exit
;rpu_20:
  mov	ebx,1
  mov	ecx,1 
;input: eax = value to work on
;       ebx = x location (column)
;       ecx = y location (row)
  call	pop_up
rpu_exit:
  ret


