  extern hexascii2dword
  extern hexascii2word
  extern hexascii2byte

;-------------------------------------------
mem_mouse_?:
  call	mem_help
  ret
;-------------------------------------------
mem_db:
  mov	[memwin_mode],byte 1
  jmp	mpu_exit
;-------------------------------------------

mem_dw:
  mov	[memwin_mode],byte 2
  jmp	mpu_exit
  ret
;-------------------------------------------

mem_dd:
  mov	[memwin_mode],byte 4
  jmp	mpu_exit
  ret
;-------------------------------------------

mem_up:
  call	setup_adr		;sets eax=MemWinAdr
  movzx ebx,byte [memwin_mode]
  sub	eax,ebx
  mov	[MemWinAdr],eax
mu_exit: 
  or	[win_bit_map],byte 8
  ret
;-------------------------------------------

mem_pgup:
  call	setup_adr		;sets eax=MemWinAdr
  movzx	ebx,byte [memwin_mode]
  imul	ebx,10
  sub	eax,ebx
  mov	[MemWinAdr],eax
  or	[win_bit_map],byte 8
  ret
;-------------------------------------------

mem_down:
  call	setup_adr		;sets eax=MemWinAdr
  movzx	ebx,byte [memwin_mode]
  add	eax,ebx	
  mov	[MemWinAdr],eax
md_exit: 
  or	[win_bit_map],byte 8
  ret
;-------------------------------------------

mem_pgdn:
  call	setup_adr		;sets eax=MemWinAdr
;  mov	eax,[MemWinAdr]
  movzx	ebx,byte [memwin_mode]
  imul	ebx,10
  add	eax,ebx
  mov	[MemWinAdr],eax
  or	[win_bit_map],byte 8
  ret
;-------------------------------------------
setup_adr:
  mov	eax,[MemWinAdr]
  cmp	eax,byte 64		;check if  register
  ja	sa_exit			;jmp if not register
  add	eax,regs_1		;index into registers
  mov	eax,[eax]		;get register value
sa_exit:
  ret

  
;-------------------------------------------

mem_pop_up:
  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]
  mov	ebx,eax				;save row
  shl	ebx,2				;convert to dword index
  movzx eax,word [ecx+mouse_pkt.eventx]	;get column
  xor	edx,edx
  div	word [ebp+win.s_char_width]
;eax=click column ebx=row * 4
  cmp	[ecx+mouse_pkt.but],byte 3	;get click type
  je	mpu_menu_pop	;jmp if right click
;left click, if in data, edit field, eax=click column ebx=row*4
  cmp	al,38
  jb	mpu_menu_pop	;jmp if click in address field
;click occured on data area,do edit
  call	edit_memory
  jmp	mpu_exit
;right click, pop up menu on address
mpu_menu_pop:  
  cmp	al,38		;check if break on address
  jb	mpu_address	;jmp if click on address
;click on value, check if dword address here
  cmp	[memwin_mode],byte 4 ;dword display
  jne	mpu_address		;use address if no dword
  add	ebx,mline_data_buf - 4
  mov	eax,[ebx]
  jmp	mpu_save	;go pop up menu
mpu_address:
  add	ebx,mline_adr_buf -4
  mov	eax,[ebx]	;get address value
mpu_save:
  mov	ebx,02		;column
  mov	ecx,0 
;input: eax = value to work on
;       ebx = x location (column)
;       ecx = y location (row)
  call	pop_up
mpu_exit:
  or	[win_bit_map],byte 8
  ret
;-------------------------------------------
; input: eax=column ebx=row*4
;
edit_memory:
  mov	eax,ebx
  shr	eax,2
  mov	[em_row],al	;save row
  mov	eax,ebx		;save row*4
  add	eax,mline_adr_buf -4	;get address
  mov	edx,[eax]		;data address
  mov	[em_mem_adr],edx
  mov	esi,em_value
  call	trace_peek		;get dword from memory-> em_value
;lookup colors
  mov	eax,[stringBColor]
  call	color_num_lookup
  mov	[em_c1],al
  mov	eax,[stringFColor]
  call	color_num_lookup
  mov	[em_c2],al

  mov	eax,[cursorBColor]
  call	color_num_lookup
  mov	[em_c3],al
  mov	eax,[cursorFColor]
  call	color_num_lookup
  mov	[em_c4],al
;adjust window sizes
  mov	edi,em_edit_buf
  mov	al,[memwin_mode]
  xor	ebx,ebx
  mov	bl,al
  shl	ebx,1
  mov	[em_len],bl	;length of window
  mov	[em_block+4],bl ;adjust buffer size
  cmp	al,1		;check if byte mode
  je	byte_edit
  cmp	al,2
  je	word_edit
;dword edit
  mov	eax,[em_value]
  call	dwordto_hexascii
  jmp	short em_string_edit
word_edit:
  mov	eax,[em_value]
  call	wordto_hexascii
  jmp	short em_string_edit  
byte_edit:
  mov	eax,[em_value]
  call	byteto_hexascii
em_string_edit:
  mov	[em_col],byte 40
  mov	[em_col+1],byte 40
  mov	eax,em_block
  call	x_get_text
;convert value back to bin
  mov	esi,em_edit_buf
  mov	al,[memwin_mode]
  cmp	al,1
  je	bin_byte
  cmp	al,2
  je	bin_word
;dword ascii to bin
  call	hexascii2dword	;result to ebx
  mov	[em_value],ebx
  mov	edi,[memwin_mode] ;get number of bytes to store
  mov	edx,[em_mem_adr]  ;get address
  mov	esi,em_value	  ;ptr to data
  call	trace_poke_bytes
  jmp	short em_exit
bin_byte:
  call	hexascii2byte
  mov	[em_value],ebx
  mov	edi,[memwin_mode] ;get number of bytes to store
  mov	edx,[em_mem_adr]  ;get address
  mov	esi,em_value	  ;ptr to data
  call	trace_poke_bytes
  jmp	short em_exit
bin_word:
  call	hexascii2word
  mov	[em_value],ebx
  mov	edi,[memwin_mode] ;get number of bytes to store
  mov	edx,[em_mem_adr]  ;get address
  mov	esi,em_value	  ;ptr to data
  call	trace_poke_bytes
em_exit:
  ret

  
;-------------
  [section .data]
em_mem_adr: dd 0
em_value: dd 0

em_block:
  dd	em_edit_buf
  dd	em_buf_size
em_row:
  db	0		;row
em_col:
  db	40		;column
  db    40		;initial column
em_len:
  dd	24		;window length
  dd	0		;scroll
em_c1:
  dd	0		;stringBColor
em_c2:
  dd	0		;stringFColor
em_c3:
  dd	0		;cursorBColor
em_c4:
  dd	0		;cursorFColor

em_buf_size	equ	8
em_edit_buf:
  times	em_buf_size db ' '
  db	0,0		;extra byte at end of stirng


  [section .text]
;-------------------------------------------
mem_history_bak:
  mov	eax,[mem_history_restore]
  push	eax		;save restore ptr
  mov	eax,[eax]	;get entry
  mov	[MemWinAdr],eax
  pop	eax		;get restore ptr
  sub	eax,4
  cmp	eax,mem_history_buf
  jae	mh_10		;jmp if pointer ok
  mov	eax,mem_history_end ;restart at end
mh_10:
  mov	[mem_history_restore],eax
  or	[win_bit_map],byte 8
  ret
;-------------------------------------------

mem_history_fwd:
  mov	eax,[mem_history_restore]
  add	eax,4
  cmp	eax,mem_history_end + 4
  jb	mh_20		;jmp if pointer ok
  mov	eax,mem_history_buf ;restart at beginning
mh_20:
  mov	[mem_history_restore],eax

  add	eax,4		;move to restore entry
  mov	eax,[eax]	;get entry
  mov	[MemWinAdr],eax
  or	[win_bit_map],byte 8
  ret
;-------------------------------------------

mem_string:
  mov	[search_stuf],dword mem_search_continue
  mov	al,40	;column
  mov	ah,0	;row
  call	calc
;check if solitary register entered
  cmp	[parse_bit_flag],byte 04
  je	ms_50		;jmp if register found
  cmp	ecx,64		;small value?
  ja	ms_60		;jmp if value ok
  mov	eax,ecx
  call	show_MemWinAdr
  jmp	short ms_exit	;skip redisplay and save
ms_50:
  mov	ecx,[reg_index]  
ms_60:
  mov	[MemWinAdr],ecx
  call	add_mem_history
  or	[win_bit_map],byte 8
ms_exit:
  ret
;-------------
  [section .data]
mem_history_buf: times 7 dd 0
mem_history_end: dd 0		;last entry in buffer

mem_history_stuf dd mem_history_buf+4
mem_history_restore dd mem_history_buf

  [section .text]
;--------------------------------------------------------
mem_search_continue:
  xor	eax,eax
  cmp	[parse_ptr],eax		;check if no search in process
  je	psc_end			;jmp if no search active
  call	partial_search_again
  or	ecx,ecx
  jnz	psc_success
;got to end without match
  jmp	short psc_end
psc_success:
  mov	[MemWinAdr],ecx
  or	[win_bit_map],byte 8
psc_end:
  ret  
;----------------------------------------------------------
;input ecx = MemWinAdr
;
;update history
; history ptr are:  mem_history_restore -> mem_history_buf
;                                          mem_histroy_buf+4
;                   mem_history_stuff ->   mem_history_buf+8
;
add_mem_history:
  mov	eax,[mem_history_stuf]
  mov	[eax],ecx
  push	eax		;save origional stuff ptr
;advance stuff ptr
  add	eax,4
  cmp	eax,mem_history_buf + 4*8
  jb	ms_70		;jmp if pointer ok
  mov	eax,mem_history_buf
ms_70:
  mov	[mem_history_stuf],eax
;reset restore ptr
  pop	eax		;resotre origional stuff ptr
  sub	eax,4
  cmp	eax,mem_history_buf ;wrap?
  jae	ms_80		;jmp if no wrap
  mov	eax,mem_history_end
ms_80:  
  mov	[mem_history_restore],eax
  ret

;--------------------------------------------------------
extern dword_to_hexascii
extern str_search

struc strdef
._data_buffer_ptr    resd 1 ;+0    blanked or preload with text
._buffer_size        resd 1 ;+4    buffer size, > or = window_size
._display_row        resb 1 ;+12   ;row (1-x)
._display_column     resb 1 ;+13   ;column (1-x)
._initial_cursor_col resb 1 ;+15   ;must be within data area
._window_size        resd 1 ;+16   bytes in window
._scroll             resd 1 ;+20   window scroll right count
._stringBColor       resd 1 ;string background color#
._stringFColor       resd 1 ;string foreground color#
._cursorBColor       resd 1 ;string cursor background color#
._cursorFColor       resd 1 ;string cursor foreground color#
endstruc
;--------------------------------------------------------
;inputs: al = window column
;        ah = window row
; simple calculator.
; if single number entered it is displays as decimal and hex
; if two numbers are entered they need an operator (+ - * /)
;    and the result is displayed as decimal and hex
;
; This code could be improved but it works so why bother.

calc:
  mov	[string_table+strdef._display_column],al
  mov	[string_table+strdef._initial_cursor_col],al
  mov	[string_table+strdef._display_row],ah
  mov	[parse_bit_flag],byte 0
  mov	[previous_op],byte 0
  mov	[calc_sum],dword 0
  mov	[st_scroll],byte 0
;clear the string _buf
  mov	edi,string_buf
  mov	ecx,string_buf_size
  mov	al,' '
  rep	stosb

;color setup
  mov	eax,[stringBColor]
  call	color_num_lookup
  mov	[st_c1],al
  mov	eax,[stringFColor]
  call	color_num_lookup
  mov	[st_c2],al

  mov	eax,[cursorBColor]
  call	color_num_lookup
  mov	[st_c3],al
  mov	eax,[cursorFColor]
  call	color_num_lookup
  mov	[st_c4],al

  mov	eax,string_table
  call	x_get_text
  mov	al,[string_buf]
  cmp	al,' '
  jbe	calc_exit		;exit if nothing entered
;
calc_1:
  mov	esi,string_buf		;get ptr to data
  xor	eax,eax
  mov	[calc_sum],eax
calc_loop:
  call	calc_parse		;sets esi=start edi=ending separator
  cmp	al,0ch			;check if operator
  ja	calc_10			;jmp if not operator
  mov	[previous_op],al	;save operator
  jmp	short calc_loop
;check if value
calc_10:
  cmp	al,10h			;check if value
  ja	calc_exit		;jmp if calc exit
;process value in ecx
  mov	ebx,[previous_op]
  add	ebx,calc_table
  jmp	[ebx]
;--------------
  [section .data]
calc_table:
  dd  calc_plus   ;0
  dd  calc_minus  ;4
  dd  calc_mul    ;8
  dd  calc_div
  dd  calc_exit		;illegal value
  [section .text]
;---------------
calc_plus:
  add	[calc_sum],ecx
  jmp	short calc_loop
calc_minus:
  sub	[calc_sum],ecx
  jmp	short calc_loop
calc_mul:
  mov	eax,[calc_sum]
  mul	ecx
  mov	[calc_sum],eax
  jmp	short calc_loop
calc_div:
  mov	eax,[calc_sum]
  xor	edx,edx
  jecxz	calc_exit
  div	ecx
  mov	[calc_sum],eax	;save results
  jmp	short calc_loop  
;
calc_exit:
  mov	ecx,[calc_sum]
  ret  
;-------
; parse string for calc
;  input: esi = string ptr
;         
;  output: esi = next parse posn
;          eax = 00 operator found "+"
;                04 operator -
;                08 operator *
;                12 operator /
;                16 value found (in ecx)
;                20 end or error
;          ecx = value if eax=10h
;          parse_bit_flag  db 1=op found 2=value 4=reg
;          reg_index       dd set if reg found
;
calc_parse:
  push	ebp
  mov	al,14h		;preload end of parse
cp_03:
  cmp	byte [esi],0	;end of parse
  je	cpp_exitj	;exit if no more data		
;remove leading spaces
  cmp	byte [esi],' '
  jne	cpp_05		;jmp if not space
  inc	esi
  jmp	short cp_03
;check for operator
cpp_05:
  xor	eax,eax		;preload "+" code
  cmp	byte [esi],"+"
  je	op_found	;jmp if "+" found
  mov	al,04
  cmp	byte [esi],'-'
  je	op_found
  mov	al,08
  cmp	byte [esi],'*'
  je	op_found
  mov	al,0ch
  cmp	byte [esi],'/'
  jne	cpp_10		;jmp if not operator
op_found:
  or	[parse_bit_flag],byte 01
  inc	esi		;move past operator
cpp_exitj:
  jmp	cpp_exit
;check if hex value
cpp_10:
  cmp	word [esi],'0x'
  jne	cpp_20		;jmp if not hex
  add	esi,2		;move to start of value
  call	hexascii_to_dword
  dec	esi
  jmp	cp_value_exit1
;check if number
cpp_20:
  cmp	byte [esi],'0'
  jb	cp_40		;jmp if not decimal
  cmp	byte [esi],'9'
  ja	cp_40		;jmp if not decimal
  call	ascii_to_dword
  dec	esi		;move back to terminating char
  jmp	cp_value_exit1
;check if register, must be lower case reg
cp_40:
  mov	eax,[esi]
  mov	[token],eax
  mov	byte [token+3],0
  mov	[parse_ptr],esi
  mov	esi,token
  mov	edi,reg_list
  call	lookup_token
  jne	cp_50		;jmp if register not found
;ecx=register index
  or	[parse_bit_flag],byte 04
  shl	ecx,2		;make dword value
  mov	[reg_index],ecx
  add	ecx,regs_1
  mov	ecx,[ecx]	;get register value
  mov	esi,[parse_ptr]
  add	esi,byte 3	;move past reg name
  jmp	cp_value_exit
;check if label
cp_50:
  mov	esi,[parse_ptr]
  mov	edi,esi		;save label start
cp_52:
  lodsb
  cmp	al,' '
  je	cp_54		;jmp if end of label
  or	al,al
  jnz	cp_52		;loop till end of label
cp_54:
  dec	esi
  sub	esi,edi		;compute label length
  mov	[parse_len],esi ;save length
  mov	ecx,esi		;ecx = length of label
  mov	edx,5		;offset into record
  call	hash_lookup
  or	eax,eax
  jnz	cp_60		;jmp if no match
  mov	ecx,[esi]
  mov	esi,[parse_ptr]
  add	esi,[parse_len]
  jmp	short cp_value_exit1
;check for partial match
cp_60:
  call	partial_search	;return value in ecx if "Je" flag
  mov	esi,[parse_ptr]
  add	esi,[parse_len]	;update esi to next parse point
  mov	al,14h		;return error code
  jecxz	cpp_exit		;jmp if no match
cp_value_exit1:
  or	[parse_bit_flag],byte 02
cp_value_exit:
  mov	al,10h
cpp_exit:
  pop	ebp
  ret

;-----------------
  [section .data]
calc_sum	dd 0
previous_op	dd 0

parse_bit_flag	db 0	;1=operator 2=value 3=register
reg_index	dd 0
token	times 4 db 0
parse_ptr: dd 0
parse_len: dd 0

reg_list:
 db 'ebx',0	; ebx  4
 db 'ecx',0	; ecx  8
 db 'edx',0	; edx  12
 db 'esi',0	; esi  16
 db 'edi',0	; edi  20
 db 'ebp',0	; ebp  24
 db 'eax',0	; eax  28
 db 'ebx',0	;dummy ; r1_ds 32
 db 'ebx',0	;dummy; r1_es 36
 db 'ebx',0	;dummy; r1_fs 40
 db 'ebx',0	;dummy; r1_gs 44
 db 'ebx',0	;dummy; r1_old_eax 48
 db 'eip',0	; eip  52
 db 'ebx',0	;dummy; r1_cs 56
 db 'ebx',0	;dummy; r1_flags 60
 db 'esp',0	; esp  64
 db 0		;end of list
;---------------
search_ptr: dd 0
sym_table_end: dd 0	;ptr to end of symbol table

;-------------------
  [section .text]
;------------------------------------------------------------
;search symbol table
; input: [parse_ptr] = match string
;        [parse_len] = length of match string
;        [symbol_table_ptr]
;        [sym_table_size]
;        [sym_table_end]
; output: [search_ptr] - set to last match or 0 if end of table found
;         ecx = address from symbol, or  zero if failed
;       ebp - preserved
; the symbol table file starts with data + hash as follows:
;  .entries_ptr dd ;ptr to symbol entries
;  .avail_entries dd ;ptr to free space
;  .field         dd ; index into records (ignore)
;  .mask	  dd ; size of hash 
;  .hash_table  (variable size)
;  (.start of entries here)
partial_search:
  xor	eax,eax
  mov	[search_ptr],eax

;-------------------------------------------------------------
;input: [search_ptr] - last search loc. 0=start from top
;        (see partial_search)
;output:[search_ptr] updated
;       ecx = results
;       ebp - preserved 
partial_search_again:
  push	ebp
  mov	edi,[search_ptr]
  or	edi,edi
  jnz	psc_10		;jmp if search in process
  mov	eax,[symbol_table_ptr]
  mov	edi,[eax]	;get ptr to entries
  add	eax,[sym_table_size]
  mov	[sym_table_end],eax
;edi points to entries:
;  dd chain
;  dd address of sym
;  db type
;  db name string
;
psc_10:
psc_lp:
  cmp	edi,[sym_table_end]
  jae	psc_fail		;jmp if end of table
    
  add	edi,4			;move to data entry
  mov	ecx,[edi]		;get symbol address
  push	ecx			;save symbol address
  add	edi,5			;move to symbol text
  mov	esi,[parse_ptr]
  add	esi,[parse_len]
  mov	byte [esi],0		;terminate match string
  push  esi			;save ptr to str end
  sub	esi,[parse_len]		;restore start of match str
  push	edi			;save sym table string start
  call	str_search
  pop	edi			;restore sym table string start
  pop	esi			;restore ptr to end of match str
  mov	byte [esi],' '		;replace zero at end with blank
  pop	ecx			;restore symbol address
  pushf				;save str_search result falg
;scan to end of this record
psc_lp2:
  inc	edi
  cmp	byte [edi],0		;end of string?
  jne	psc_lp2			;loop till end of string
  inc	edi
psc_20:
  mov	[search_ptr],edi	;save search point
  popf
  jc	psc_lp			;jmp if no match
  jmp	short psc_exit		;exit with ecx=address
;name not found, restart search
psc_fail:
  xor	ecx,ecx
  mov	[search_ptr],ecx
psc_exit:
  pop	ebp
  ret
  
;-------------------
  [section .data]

op1	db 0
vala	dd 0
op2	db 0

string_table:
  dd	string_buf
  dd	string_buf_size
st_row:
  db	0		;row
st_col:
  db	40		;column
  db    40		;initial column
st_len:
  dd	24		;window length
st_scroll:
  dd	0		;scroll
st_c1:
  dd	0		;stringBColor
st_c2:
  dd	0		;stringFColor
st_c3:
  dd	0		;cursorBColor
st_c4:
  dd	0		;cursorFColor

string_buf_size	equ	40
string_buf:
  times	string_buf_size db ' '
  db	0,0		;extra byte at end of stirng

;----------------
  [section .text]

