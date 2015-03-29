
  extern window_rel_table
  extern window_rel_table_setup
;%include "window_rel_table.inc"

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

;----------------------------------------
pop_up_setup:
  call	window_rel_table_setup
  ret

;----------------------------------------
;input: eax = value to work on
;       ebx = x location (column)
;       ecx = y location (row)
pop_up:
  mov	[pop_adr],eax
  mov	[pop_x],ebx
  mov	[pop_y],ecx
;stuff value into text
   mov	edi,pb_stuff
   call	dwordto_hexascii
;set box color
  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color
;clear box
   mov	eax,[pop_x]
   inc	eax	;column
   mov	ebx,[pop_y]
   inc	ebx	;
   inc	ebx	;row
   mov	ecx,23  ;  ecx = width (chars)
   mov	edx,11  ;  edx = height (chars)
   mov	esi,1   ;  esi = flag 1=current color
  call	window_clear_area
;check if font fix active
  cmp	byte [FontFix],0
  jnz	pu_20		;jmp if font fix active
;set border color
  mov	ebx,[popBorderFColor]
  mov	ecx,[popBorderBColor]
  call	window_id_color
  
  mov	eax,[pop_x]	;column
  mov	ebx,[pop_y]	;row
  mov	esi,pop_border_table
  call	window_rel_table
;set box color
pu_20:
  mov	ebx,[popButFColor]
  mov	ecx,[popButBColor]
  call	window_id_color

  mov	eax,[pop_x]	;column
  mov	ebx,[pop_y]	;row
  mov	esi,pop_button_table
  call	window_rel_table

  call	x_wait_event
  cmp	byte [ecx],4		;click?
  jne	pb_exitj		;exit if non-click
;decode click
  movzx	eax,word [ecx+mouse_pkt.eventx]	;get pixel column
  xor	edx,edx
  div	word [ebp+win.s_char_width]
  mov	bl,al		;save column
  sub	bl,[pop_x]

  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  mov	bh,al		;save row
  sub	bh,[pop_y]
;check if in our window
  cmp	bl,24
  ja	pb_exit		;exit if outside window
  cmp	bh,12
  ja	pb_exit		;exit if outside window
;decode button press
  cmp	bh,3
  je	set_mem
  cmp	bh,5
  je	set_code
  cmp	bh,7
  je	set_brk
  cmp	bh,9
  je	set_eip
pb_exitj:
  jmp	pb_exit		;ignore all others
set_mem:
  mov	ecx,[pop_adr]
  mov	[MemWinAdr],ecx
  call	add_mem_history  
  jmp	short pb_display
set_code:
  mov	edx,[pop_adr]
  push	ebp
  call	physical2offset
  mov	[code_adr_offset],ebp
  pop	ebp
  jmp	short pb_display
set_brk:
  mov	edx,[pop_adr]
  call	add_break
  jmp	short pb_display
set_eip:
  mov	eax,[pop_adr]
  mov	[r1_eip],eax
;  mov	esi,regs_1		;move regs to app
;  call	trace_regsset
  or	[win_bit_map],byte 20h	;set center bit
pb_display:
pb_exit:
  or	[win_bit_map],byte 1fh
  ret
;----------------
  [section .data]
pop_adr dd 0	;acting on this adr
pop_x:	dd 0	;column
pop_y:	dd 0	;row

pop_border_table:
;write border (horizontal)
  db 4		;fill line
  dw 1		;column
  dw 0		;row
  db 23		;length of fill
  db 12h	;fill char

  db 4		;fill line
  dw 1		;column
  dw 12		;row
  db 23		;length of fill
  db 12h	;fill char
;write vertical border
  db 8		;write down
  dw 0		;column
  dw 1		;row
  db vert1_len
vert1:
  db 19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h
vert1_len equ $ - vert1

  db 8		;write down
  dw 24		;column
  dw 1		;row
  db vert2_len
vert2:
  db 19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h
vert2_len equ $ - vert2

;add corner characters
  db 12		;write
  dw 0		;column
  dw 0		;row
  db 1		;one character
  db 0dh

  db 12		;write
  dw 24		;column
  dw 0		;row
  db 1		;one character
  db 0ch

  db 12		;write
  dw 0		;column
  dw 12		;row
  db 1		;one character
  db 0eh

  db 12		;write
  dw 24		;column
  dw 12		;row
  db 1		;one character
  db 0bh

  db 12		;write line opcode
  dw 1		;column 1
  dw 1		;row 1
  db pb_len1
pb_txt1:
  db 'operating on '
pb_stuff:
  db '12345678'
  db '  '
pb_len1 equ $ - pb_txt1

  db 0		;end of table
;---------
pop_button_table:

  db 12
  dw 2
  dw 3
  db pb_len2
pb_txt2:
  db '-> memory window'
pb_len2 equ $ - pb_txt2

  db 12
  dw 2
  dw 5
  db pb_len3
pb_txt3:
  db '-> code window'
pb_len3 equ $ - pb_txt3

  db 12
  dw 2
  dw 7
  db pb_len4
pb_txt4:
  db '-> break window'
pb_len4 equ $ - pb_txt4

  db 12
  dw 2
  dw 9
  db pb_len5
pb_txt5:
  db '-> EIP'
pb_len5 equ $ - pb_txt5

  db 12
  dw 2
  dw 11
  db pb_len6
pb_txt6:
  db ' -cancel- '
pb_len6 equ $ - pb_txt6

  db 0
  
  [section .text]

;-------------------------------------------------------

code_prep:
  mov	ebp,win_block
;lookup string entry colors
  mov	eax,[stringBColor]
  call	color_num_lookup
  mov	[prp_c1],al
  mov	eax,[stringFColor]
  call	color_num_lookup
  mov	[prp_c2],al

  mov	eax,[cursorBColor]
  call	color_num_lookup
  mov	[prp_c3],al
  mov	eax,[cursorFColor]
  call	color_num_lookup
  mov	[prp_c4],al
;restart strng entry column
  mov	[prp_col],byte 20
  mov	[prp_col+1],byte 20

;set box color
  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color
;clear box
   mov	eax,0;column
   mov	ebx,0;row
   mov	ecx,55  ;  ecx = width (chars)
   mov	edx,15  ;  edx = height (chars)
   mov	esi,1   ;  esi = flag 1=current color
  call	window_clear_area

  mov	eax,0;column
  mov	ebx,0;row
  mov	esi,prep_title_table
  call	window_rel_table

;set button color
  mov	ebx,[popButFColor]
  mov	ecx,[popButBColor]
  call	window_id_color

  mov	eax,1;column
  mov	ebx,2;row
  mov	esi,prep_button_table
  call	window_rel_table

  call	x_wait_event
  cmp	byte [ecx],4		;click?
  jne	prep_exitj		;exit if non-click
;decode click
  movzx	eax,word [ecx+mouse_pkt.eventx]	;get pixel column
  xor	edx,edx
  div	word [ebp+win.s_char_width]
  mov	bl,al		;save column
  sub	bl,[pop_x]

  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  mov	bh,al		;save row
  sub	bh,1	;remove starting row
;check if in our window
  cmp	bl,24		;check column
  ja	pb_exit		;exit if outside window
;  cmp	bl,40
;  ja	prep_exitj	;exit if outside window
;decode button press
  cmp	bh,1		;row 1
  je	set_resize
  cmp	bh,3
  je	set_font
  cmp	bh,5
  jne	prp_12
  jmp	set_height
prp_12:
  cmp	bh,7
  jne	prp_14
  jmp	set_parm
prp_14:
  cmp	bh,9
  jne	prp_16
  jmp	set_fontfix
prp_16:
  cmp	bh,11
  jne	prep_exitj	;exit if illegal click
  cmp	bl,8
  ja	prep_exitj	;exit if -cancel- clicked
  jmp	set_reboot
prep_exitj:
  jmp	prep_exit
;---
set_resize:
  mov	[prp_len],byte 1
  mov	[prp_bsize],byte 1
  mov	[prp_row],byte 2
  mov	eax,[AppResize]
  mov	edi,prp_edit_buf
  call	get_bin_parameter	;results in ecx
  mov	[AppResize],ecx
  jmp	code_prep
;---
set_font:
  mov	[prp_len],byte 2
  mov	[prp_row],byte 4
  mov	[prp_bsize],byte 2
  mov   eax,[DebugWinFont]
  mov	edi,prp_edit_buf
  call	get_bin_parameter	;results in ecx
  cmp	cl,8
  jae	sf_11			;jmp if font ok
  mov	cl,8
sf_11:
  cmp	cl,14
  jb	sf_12			;jmp if font ok
  mov	cl,14
sf_12:
  mov	[DebugWinFont],cl
  jmp	code_prep
;---
set_height:
  mov	[prp_len],byte 4
  mov	[prp_row],byte 6
  mov	[prp_bsize],byte 4
  mov	eax,[DebugWinHeight]
  mov	edi,prp_edit_buf
  call	get_bin_parameter	;results in ecx
  cmp	ecx,200
  ja	sh_11			;jmp if height ok
  mov	ecx,200
sh_11:
  mov	[DebugWinHeight],ecx
  jmp	code_prep
;---
set_parm:
  mov	[prp_len],byte 10	;window size
  mov	[prp_block],dword LastTargetParm
  mov	[prp_bsize],byte 40	;buffer size
  mov	edi,prp_edit_buf

  mov	[prp_row],byte 8

  mov	eax,prp_block
  call	x_get_text
  jmp	code_prep
;---
set_fontfix:
  mov	[prp_len],byte 1
  mov	[prp_bsize],byte 1
  mov	[prp_row],byte 10
  mov	eax,[FontFix]
  mov	edi,prp_edit_buf
  call	get_bin_parameter	;results in ecx
  mov	[FontFix],ecx
  jmp	code_prep
;---
set_reboot:
  mov	ebp,win_block
  call	window_kill
  call	x_flush
  call	write_history
  call	app_win_restore
  call	x_get_input_focus
  call	x_disconnect

  mov	esi,[our_name]
  mov	edi,history_data	;overwrite unneeded history data
  push	edi
  call	str_move
  xor	eax,eax
  stosd				;put double zero at end
  pop	esi
  call	sys_run_die

prp_done:
  mov	[prp_block],dword prp_edit_buf	;restore buffer just incase
;---
prep_exit:
  or	[win_bit_map],byte 1fh
  ret
;----------------------------------
;input: eax=value
;output ecx=value
get_bin_parameter:
  call	dword_to_ascii
  mov	eax,prp_block
  call	x_get_text
;convert value back to bin
  mov	esi,prp_edit_buf
  call	ascii_to_dword	;result to ecx
  ret
;---------------------
  [section .data]

prp_value dd 0

prp_block:
  dd	prp_edit_buf
prp_bsize:
  dd	prp_buf_size
prp_row:
  db	0		;row
prp_col:
  db	40		;column
  db    40		;initial column
prp_len:
  dd	24		;window length
  dd	0		;scroll
prp_c1:
  dd	0		;stringBColor
prp_c2:
  dd	0		;stringFColor
prp_c3:
  dd	0		;cursorBColor
prp_c4:
  dd	0		;cursorFColor

prp_buf_size	equ	8
prp_edit_buf:
  times	prp_buf_size db ' '
  db	0,0		;extra byte at end of stirng


prep_title_table:
  db 12		;write text
  dw 0
  dw 0
  db pbt_len6
pbt_txt6:
  db 'Select Item to modify'
pbt_len6 equ $ - pbt_txt6

  db 12		;write text
  dw 0
  dw 14
  db pbt_len7
pbt_txt7:
  db 'restart prog to see changes'
pbt_len7 equ $ - pbt_txt7

  db 12		;write text
  dw 30		;column
  dw 2		;row
  db pbt_len8
pbt_txt8:
  db '<-(term only) 1=yes 0=no'
pbt_len8 equ $ - pbt_txt8

  db 12		;write text
  dw 30		;column
  dw 4
  db pbt_len9
pbt_txt9:
  db '<-8,9,10,11,12'
pbt_len9 equ $ - pbt_txt9

  db 12		;write text
  dw 30		;column
  dw 6
  db pbt_len0
pbt_txt0:
  db '<- pixel height'
pbt_len0 equ $ - pbt_txt0

  db 12		;write text
  dw 30		;column
  dw 10
  db pbt_lenx
pbt_txtx:
  db '<- 0=draw char 1=std font'
pbt_lenx equ $ - pbt_txtx

  db 0		;end of table
;--------------------

prep_button_table:
  db 12		;write text
  dw 2
  dw 0
  db pbt_len2
pbt_txt2:
  db 'AppResize'
pbt_len2 equ $ - pbt_txt2

  db 12
  dw 2
  dw 2
  db pbt_len3
pbt_txt3:
  db 'DebugWinFont'
pbt_len3 equ $ - pbt_txt3

  db 12
  dw 2
  dw 4
  db pbt_len4
pbt_txt4:
  db 'DebugWinHeight'
pbt_len4 equ $ - pbt_txt4

  db 12
  dw 2
  dw 6
  db pbt_len5
pbt_txt5:
  db 'LastTargetParm'
pbt_len5 equ $ - pbt_txt5

  db 12
  dw 2
  dw 8
  db pbt_leny
pbt_txty:
  db 'FontFix'
pbt_leny equ $ - pbt_txty

  db 12
  dw 2
  dw 10
  db pbt_lena
pbt_txta:
  db '-restart-'
pbt_lena equ $ - pbt_txta

  db 12
  dw 13
  dw 10
  db pbt_lenb
pbt_txtb:
  db '-exit-'
pbt_lenb equ $ - pbt_txtb

  db 0	;end of table
;------------
  [section .text]

