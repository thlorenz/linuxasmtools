;  extern dword_to_ascii
;  extern ascii_to_dword
  extern dwordto_hexascii
  extern hexascii_to_dword
  extern read_window_size
  extern mouse_enable
  extern str_move
  extern string_form
;%include "string_form.inc"
  extern kbuf
  extern crt_clear
  extern key_decode1
  extern view_buffer

;------------------------------------------------------------------
; build output file name, parse input file, get parameters
; output: carry set if error/no parameters (starts menu)
;
parse:
  mov	esi,esp		;get stack ptr
  lodsd			;get return address (ignore)
  lodsd			;get parameter count
  cmp	al,1
  je	parse_exit1	;jmp if no parameters
  lodsd			;get our filename
pa_loop:
  lodsd			;ger parameter/filename
  or	eax,eax
  jz	parse_exit1	;exit if no parameters
  cmp	word [eax],'-a'
  je	pa_1
  cmp	word [eax],'-f'
  jne	parse_file
  mov	[parse_follow],byte 1
  jmp	short pa_loop
pa_1:
  mov	[parse_attach],byte 1
  lodsd			;get trace filename
parse_file:
  mov	ebp,esi		;save ptr to stack
  mov	esi,eax
;construct output filename
  push	esi
  mov	edi,outfile_name
  call	str_move
  mov	eax,".tra"
  stosd
  pop	esi
;save input file name
  mov	edi,traced_file
  call	str_move	;save file name
;check for parameters
parse_parm_lp:
  mov	esi,[ebp]	;get ptr to next param
  or	esi,esi
  jz	parse_done	;jmp if no parameters provided
;append parameters
  inc	edi		;move past zero at end
  call	str_move
  add	ebp,4
  jmp	short parse_parm_lp

parse_done:
  xor	eax,eax
  stosd			;put zeros at end
  clc
  jmp	short parse_exit2

parse_exit1:
  stc
parse_exit2:
  ret

;************************************************************************
; output:  al=0 continue  1=begin  2=exit
menu:
  call	read_window_size
  call	mouse_enable
  mov	eax,[color]
  call	crt_clear
  call	formsetup
show_form:
  mov	ebp,test_block
  call	string_form

  mov	al,[kbuf]	;get last key
  cmp	al,-1		;mouse?
  je	menu_10		;jmp if mouse
  call	menu_key
  jmp	short menu_20
menu_10:
  call	menu_mouse
menu_20:
  cmp	byte [menu_flag],0
  je	show_form
menu_exit:
  call	extract_data_from_form
  mov	al,[menu_flag]
  ret
;--------------------------------------------------------------------
menu_key:
  mov	esi,key_table
  call	key_decode1
  jc	menu_key	;jmp if error
  call	eax
  cmp	[menu_flag],byte 1  ;0=cont 1=begin 2=exit
  jae	mk_exit1	 ;jmp if begin or exit  
mk_exit2:
  clc		;menu continue flag
  jmp	short mk_exit
mk_exit1:
  stc		;quit menu flag
mk_exit:
  ret
;--------------------------------------------------------------------
menu_mouse:
 xor	eax,eax
 mov	al,[kbuf+3]	;get row
 cmp	al,23		;button row
 jae	mouse_button_line
 sub	al,3		;make  zero based
 shl	eax,2
 add	eax,mouse_table
 mov	eax,[eax]
 jmp	short mm_call
mouse_button_line:
 mov	bl,[kbuf+2]	;get click column
 mov	eax,key_help
 cmp	bl,13
 jb	mm_call		;jmp if help key
 mov	eax,key_list
 cmp	bl,32
 jb	mm_call
 mov	eax,key_exit
 cmp	bl,45
 jb	mm_call
 mov	eax,key_begin 

mm_call:
 call	eax
 cmp	[menu_flag],byte 1
 jae	mm_exit1
mm_exit2:
  clc		;menu continue flag
  jmp	short mm_exit
mm_exit1:
  stc		;quit menu flag
mm_exit:
  ret
;--------------------------------------------------------------------
key_attach:
  mov	esi,st_t
  call	toggle
  ret
;--------------------------------------------------------------------

key_process:
  mov	esi,st_p
  call	toggle
  ret
;--------------------------------------------------------------------

key_address:
  mov	esi,st_a
  call	toggle
  ret
;--------------------------------------------------------------------

key_seq:
  mov	esi,st_s
  call	toggle
  ret
;--------------------------------------------------------------------

key_functin:
  mov	esi,st_f
  call	toggle
  ret
;--------------------------------------------------------------------

key_reg:
  mov	esi,st_r
  call	toggle
  ret
;--------------------------------------------------------------------

key_extra:
  mov	esi,st_e
  call	toggle
  ret
;--------------------------------------------------------------------

key_dis:
  mov	esi,st_d
  call	toggle
  ret
;--------------------------------------------------------------------

key_help:
  mov	eax,help_end - help_msg
  xor	ebx,ebx
  mov	ecx,help_msg
  call	view_buffer
  ret
;--------------------------------------------------------------------

key_list:
;allocate buffer
  mov	eax,340*20
  call	m_allocate	;out=eax=address of buffer
  mov	[list_buf],eax  ;save buffer
;store kernel function names
  mov	edi,eax		;edi=output buffer
  mov	esi,access	;input data
  mov	[fnumber],dword 0 ;function#
kl_lp:
  push	esi
  mov	ecx,[fnumber]
  call	dword_to_hexascii
  pop	esi
  mov	al,'h'
  stosb
  mov	al,' '
  stosb
  call	str_move
  mov	al,0ah
  stosb
  add	esi,byte 4
kl_skip:
  lodsb
  or	al,al
  jns	kl_skip
  inc	dword [fnumber]
  cmp	byte [esi],0	;done?
  jne	kl_lp	
;view buffer
  mov	ecx,[list_buf]	;get buffer ptr
  xor	ebx,ebx
  mov	eax,edi		;get end of buffer
  sub	eax,ecx		;compute length of data
  call	view_buffer
;release buffer
  mov	eax,[list_buf]
  call	m_release
  ret
;----------
  [section .data]
list_buf dd 0
fnumber dd 0
  [section .text]
;--------------------------------------------------------------------

key_begin:
  mov	byte [menu_flag],1
  ret
;--------------------------------------------------------------------

key_infile:
  mov	eax,string1_def
  mov	[active_string],eax
  ret
;--------------------------------------------------------------------

key_outfile:
  mov	eax,string2_def
  mov	[active_string],eax
  ret
;--------------------------------------------------------------------

key_start_seq:
  mov	eax,string3_def
  mov	[active_string],eax
  ret
;--------------------------------------------------------------------

key_start_adr:
  mov	eax,string4_def
  mov	[active_string],eax
  ret
;--------------------------------------------------------------------

key_start_fun:
  mov	eax,string5_def
  mov	[active_string],eax
  ret
;--------------------------------------------------------------------

key_stop_seq:
  mov	eax,string6_def
  mov	[active_string],eax
  ret
;--------------------------------------------------------------------

key_stop_adr:
  mov	eax,string7_def
  mov	[active_string],eax
  ret
;--------------------------------------------------------------------

key_stop_fun:
  mov	eax,string8_def
  mov	[active_string],eax
  ret
;--------------------------------------------------------------------

key_exit:
  mov	byte [menu_flag],2
  ret

;--------------------------------------------------------------------
;input esi=ptr to
; format  dd 1 string        dd 2 flag       dd 3 num string   dd 0 end
;         dd variable        dd variable     dd variable
;         dd form buf        dd form label   dd form buf

toggle:
  lodsd		;get flag
  lodsd		;get variable
  lodsd		;get label
  mov	esi,eax
  cmp	byte [esi],'('	;off ?
  je	toggle_on
;assume "(" and toggle off
  mov	byte [esi],'('
to_lp:
  inc	esi
  cmp	byte [esi],'>'
  jne	to_lp
  mov	byte [esi],')'
  jmp	short toggle_exit

toggle_on:
  mov	byte [esi],'<'
t_lp:
  inc	esi
  cmp	byte [esi],')'
  jne	t_lp
  mov	byte [esi],'>'
toggle_exit:
  ret
;--------------------------------------------------------------------
;inputs:
; format  dd 1 numstring        dd 2 flag       dd 0 end
;         dd variable           dd variable
;         dd form buf           dd form label

;select_table:
;  dd  2,parse_attach,key_t
;  dd  3,traced_file,buf1_start
;  dd  3,outfile_name,buf2_start
;  dd  1,start_seq,buf3_start
;  dd  1,start_adr,buf4_start
;  dd  1,start_fun,buf5_start
;  dd  1,stop_seq,buf6_start
;  dd  1,stop_adr,buf7_start
;  dd  1,stop_fun,buf8_start
;  dd  2,parse_show_process,key_p
;  dd  2,parse_show_adr,key_a
;  dd  2,parse_show_seq,key_s
;  dd  2,parse_show_fun,key_f
;  dd  2,parse_show_regs,key_r
;  dd  2,parse_show_extra,key_e
;  dd  2,parse_show_disasm,key_d
;  dd 0 ;end of table

formsetup:
  mov	esi,traced_file
  cmp	byte [esi],0
  je	fs_10		;jmp if no input file
  mov	edi,outfile_name
  call	str_move
  mov	eax,".tra"
  stosd
fs_10:  
  mov	esi,select_table
fs_loop:
  lodsd			;get type
  cmp	al,1
  je	fs_string
  jb	fs_exit
  cmp	al,3
  je	fs_cpy
  jmp	fs_flag
fs_exit:
  ret
fs_cpy:
  lodsd			;get ptr to string
  mov	ebx,eax
  lodsd			;get stuff point
  push	esi
  mov	edi,eax
  mov	esi,ebx
  call	str_move
  mov	byte [edi],' '  ;remove zero at end
  pop	esi
  jmp	short fs_loop

fs_string:
  lodsd			;get ptr to variable
  mov	ebx,[eax]	;get string hex value
  lodsd			;get stuff point
  mov	edi,eax		;get stuff point
  mov	eax,ebx		;get hex value
  or	eax,eax		;check if null value
  jnz	fs_string2
;blank buffer
  mov	al,' '
  mov	ecx,8		;length of buffer
  rep	stosb
  jmp	fs_loop
fs_string2:
  call	dwordto_hexascii
  jmp	fs_loop

fs_flag:
  lodsd			;get ptr to variable
  mov	bl,[eax]	;get value of flag
  lodsd			;get ptr to stuff
  mov	bh,'<'		;preload yes char
  cmp	bl,1		;value=yes
  je	stuf_front
  mov	bh,'('		;no char
stuf_front:
 mov	[eax],bh	;stuff char
;
  mov	bl,'>'		;preload yes end char
  cmp	bh,'<'		;yes char?
  je	find_end
  mov	bl,')'		;end char
;
find_end:
  inc	eax
  cmp	[eax],byte '>'
  je	got_end
  cmp	[eax],byte ')'
  jne	find_end
got_end:
  mov	[eax],bl
  jmp	fs_loop
;--------------------------------------------------------------------
extract_data_from_form:
  mov	esi,select_table
edf_loop:
  lodsd			;get type
  mov	ebx,eax
  lodsd			;get variable
  mov	edx,eax
  lodsd			;get message pointer
  cmp	bl,1
  je	ed_string
  jb	ed_exit
  cmp	bl,3
  je	ed_cpy
  jmp	ed_flag
ed_exit:
  ret

;esi=tableptr  edx=variable  eax=message ptr
ed_cpy:
  push	esi
  mov	edi,edx		;destination
  mov	esi,eax		;message data
ed_cpy_lp:
  lodsb
  cmp	al,' '		;end of strng
  je	ed_cpy_done1
ed_stuff:
  stosb
  jmp	short ed_cpy_lp
;one parameter saved, check if another
ed_cpy_done1:
  xor	eax,eax		;terminate string
  stosb
  lodsb			;get next byte
  cmp	al,' '
  jne	ed_stuff
ed_cp_done2:
  xor	eax,eax
  stosb			;terminale all strings
  pop	esi
  jmp	short edf_loop

;esi=tableptr  edx=variable  eax=message ptr
ed_string:
  push	esi
  mov	edi,edx		;destination
  mov	esi,eax		;source
  call	hexascii_to_dword
  mov	[edi],ecx	;store results
  pop	esi
  jmp	edf_loop

;esi=tableptr  edx=variable  eax=message ptr
ed_flag:
  mov	bl,[eax]	;get flag "<"=on "("=off
  mov	bh,0		;preload off
  cmp	bl,'<'
  je	ed_on
  mov	byte [edx],0	;set off
  jmp	edf_loop
ed_on:
  mov	byte [edx],1	;set on
  jmp	edf_loop



;-----------------------------------------------------
dummy: ret
;---------------
  [section .data]

menu_flag db 0 ;0=continue 1=begin 2=exit program

; format  dd 1 string        dd 2 flag       dd 3 num string   dd 0 end
;         dd variable        dd variable     dd variable
;         dd form buf        dd form label   dd form buf

select_table:
st_t:
  dd  2,parse_attach,key_t
st_f1:
  dd  3,traced_file,buf1_start
st_f2:
  dd  3,outfile_name,buf2_start
st_f3:
  dd  1,start_seq,buf3_start
st_f4:
  dd  1,start_adr,buf4_start
st_f5:
  dd  1,start_fun,buf5_start
st_f6:
  dd  1,stop_seq,buf6_start
st_f7:
  dd  1,stop_adr,buf7_start
st_f8:
  dd  1,stop_fun,buf8_start
st_p:
  dd  2,parse_show_process,key_p
st_a:
  dd  2,parse_show_adr,key_a
st_s:
  dd  2,parse_show_seq,key_s
st_f:
  dd  2,parse_show_fun,key_f
st_r:
  dd  2,parse_show_regs,key_r
st_e:
  dd  2,parse_show_extra,key_e
st_d:
  dd  2,parse_show_disasm,key_d
  dd 0 ;end of table

;------------------------------------------------------------------------
key_table:
 dd dummy

 db 1bh,'t',0	;alt-t
 dd key_attach

 db 1bh,'p',0	;alt-p
 dd key_process

 db 1bh,'a',0	;alt-a
 dd key_address

 db 1bh,'s',0	;alt-s
 dd key_seq

 db 1bh,'f',0	;alf-f
 dd key_functin

 db 1bh,'r',0	;alt-r
 dd key_reg

 db 1bh,'e',0	;alt-e
 dd key_extra

 db 1bh,'d',0	;alt-d
 dd key_dis

 db 1bh,'h',0	;alt-h
 dd key_help

 db 1bh,'l',0	;alt-l
 dd key_list

 db 1bh,'b',0	;alt-b
 dd key_begin
;----
 db 1bh,0c3h,0b5h,0	;alt-t
 dd key_attach

 db 1bh,0c3h,0b1h,0	;alt-p
 dd key_process

 db 1bh,0c3h,0a1h,0	;alt-a
 dd key_address

 db 1bh,0c3h,0b4h,0	;alt-s
 dd key_seq

 db 1bh,0c3h,0a6h,0	;alf-f
 dd key_functin

 db 1bh,0c3h,0b2h,0	;alt-r
 dd key_reg

 db 1bh,0c3h,0a5h,0	;alt-e
 dd key_extra

 db 1bh,0c3h,0a4h,0	;alt-d
 dd key_dis

 db 1bh,0c3h,0a8h,0	;alt-h
 dd key_help

 db 1bh,0c3h,0ach,0	;alt-l
 dd key_list

 db 1bh,0c3h,0a2h,0	;alt-b
 dd key_begin
;----
 db 0f5h,0	;alt-t
 dd key_attach

 db 0f0h,0	;alt-p
 dd key_process

 db 0e1h,0	;alt-a
 dd key_address

 db 0f3h,0	;alt-s
 dd key_seq

 db 0e7h,0	;alf-f
 dd key_functin

 db 0f2h,0	;alt-r
 dd key_reg

 db 0e5h,0	;alt-e
 dd key_extra

 db 0e4h,0	;alt-d
 dd key_dis

 db 0e8h,0	;alt-h
 dd key_help

 db 0ech,0	;alt-l
 dd key_list

 db 0e2h,0	;alt-b
 dd key_begin
;---
  db 1bh,4fh,50h,0		; F1
  dd key_infile

  db 1bh,4fh,51h,0		; F2
  dd key_outfile

  db 1bh,4fh,52h,0		; F3
  dd key_start_seq

  db 1bh,4fh,53h,0		; F4
  dd key_start_adr

  db 1bh,5bh,5bh,41h,0		; F1
  dd key_infile

  db 1bh,5bh,5bh,42h,0		; f2
  dd key_outfile

  db 1bh,5bh,5bh,43h,0		; f3
  dd key_start_seq

  db 1bh,5bh,5bh,44h,0		 ;f4
  dd key_start_adr

  db 1bh,5bh,5bh,45h,0		 ;f5
  dd key_start_fun

  db 1bh,5bh,31h,31h,7eh,0	;f1
  dd key_infile

  db 1bh,5bh,31h,32h,7eh,0	;f2
  dd key_outfile

  db 1bh,5bh,31h,33h,7eh,0	;f3
  dd key_start_seq

  db 1bh,5bh,31h,34h,7eh,0	;f4
  dd key_start_adr

  db 1bh,5bh,31h,35h,7eh,0	;f5
  dd key_start_fun

  db 1bh,5bh,31h,37h,7eh,0	;f6
  dd key_stop_seq

  db 1bh,5bh,31h,38h,7eh,0	;f7
  dd key_stop_adr

  db 1bh,5bh,31h,39h,7eh,0	;f8
  dd key_stop_fun

  db 0dh,0
  dd key_begin

  db 0ah,0
  dd key_begin

  dd 1bh,0
  dd key_exit

    db 0              ; end of table 
  dd dummy		;default process
;------------------------------------------------------------------------

mouse_table:
 dd key_attach
 dd key_infile
 dd key_outfile
 dd dummy
 dd key_start_seq
 dd key_start_adr
 dd key_start_fun
 dd dummy
 dd key_stop_seq
 dd key_stop_adr
 dd key_stop_fun
 dd dummy
 dd key_process
 dd key_address
 dd key_seq
 dd key_functin
 dd key_reg
 dd key_extra
 dd key_dis
 dd dummy
 dd key_help
 dd key_list
 dd key_begin
 dd key_exit
 dd dummy
 dd dummy

;------------------------------------------------------------------------
;  string_form - get string data for form
; INPUTS
;    ebp = ptr to info block
;          note: info block must be in writable
;                data section.  Text data must
;                also be writable.
;          note: string_form input can continue
;                by calling with same input block
;
;          info block is defined as follows:
;
;          struc in_block
;           .iendrow resb 1 ;rows in window
;           .iendcol resb 1 ;ending column
;           .istart_row resb 1 ;starting row
;           .istart_col resb 1 ;startng column
;           .icursor resd 1 ;ptr to string block with active cursor
;           .icolor1 resd 1 ;body color
;           .icolor2 resd 1 ;highlight/string color
;           .itext  resd 1 ;ptr to text
;          endstruc
;
;          the text pointed at by .itext has normal text and
;          imbedded string using the following format:
;
;          struc str_def
;           .srow  resb 1 ;row
;           .scol  resb 1 ;col
;           .scur  resb 1 ;cursor column
;           .scroll  resb 1 ;scroll counter
;           .wsize  resb 1 ;columns in string window
;           .bsize  resb 1 ;size of buffer, (max=127)
;          endstruc
;
;          the text can also have areas highlighted with .icolor2
;          by enclosing them with "<" and ">".
; 
; OUTPUT
;    kbuf = non recognized key

test_block:
 db 24	;ending row
 db 60  ;ending column
 db 1	;starting row
 db 1	;startng column
active_string:
 dd string1_def ;string with cursor
color:
 dd 30003634h	;text color
 dd 30003036h	;string color
 dd test_form	;form def ptr

test_form:
 db ' AsmTrace Setup (all numbers in hex)',0ah
 db 0ah

 db 'Attach to running process:' 
key_t: db '(alt-t)',0ah

 db 'Program to trace: (f1) '
string1_def:
 db -1  ;start of string def
 db 4	;row
 db 24	;column
 db 24	;current cursor posn
 db 0	;scroll
 db 20  ;window size
 dd buf1_end - buf1_start ;buf size (max=127)
 db -2	;end of string def
buf1_start:
 times 90 db " "
buf1_end:
 db ' ',0ah

 db 'Output file:      (f2) '
string2_def:
 db -1  ;start of string def
 db 5	;row
 db 24	;column
 db 24	;current cursor posn
 db 0	;scroll
 db 20  ;window size
 dd buf2_end - buf2_start ;buf size (max=127)
 db -2	;end of string def
buf2_start:
 times 20 db ' '
buf2_end:
 db ' ',0ah

 db 0ah

 db 'Start tracing at: seq# (f3) '
string3_def:
 db -1  ;start of string def
 db 07	;row
 db 29	;column
 db 29	;current cursor posn
 db 0	;scroll
 db 8  ;window size
 dd buf3_end - buf3_start ;buf size (max=127)
 db -2	;end of string def
buf3_start:
 db '1       '
buf3_end:
 db ' (0=disable)',0ah

 db '                  adr# (f4) '
string4_def:
 db -1  ;start of string def
 db 08	;row
 db 29	;column
 db 29	;current cursor posn
 db 0	;scroll
 db 8  ;window size
 dd buf4_end - buf4_start ;buf size (max=127)
 db -2	;end of string def
buf4_start:
 times 8 db ' '
buf4_end:
 db ' (at kernel function)',0ah

 db '                  fun# (f5) '
string5_def:
 db -1  ;start of string def
 db 09	;row
 db 29	;column
 db 29	;current cursor posn
 db 0	;scroll
 db 8  ;window size
 dd buf5_end - buf5_start ;buf size (max=127)
 db -2	;end of string def
buf5_start:
 times 8 db ' '
buf5_end:
 db ' (kernel function#)'
 db ' ',0ah

 db 0ah

 db 'Stop tracing at:  seq# (f6) '
string6_def:
 db -1  ;start of string def
 db 11	;row
 db 29	;column
 db 29	;current cursor posn
 db 0	;scroll
 db 8  ;window size
 dd buf6_end - buf6_start ;buf size (max=127)
 db -2	;end of string def
buf6_start:
 times 8 db ' '
buf6_end:
 db ' ',0ah

 db '                  adr# (f7) '
string7_def:
 db -1  ;start of string def
 db 12	;row
 db 29	;column
 db 29	;current cursor posn
 db 0	;scroll
 db 8  ;window size
 dd buf7_end - buf7_start ;buf size (max=127)
 db -2	;end of string def
buf7_start:
 times 8 db ' '
buf7_end:
 db ' (at kernel function)',0ah

 db '                  fun# (f8) '
string8_def:
 db -1  ;start of string def
 db 13	;row
 db 29	;column
 db 29	;current cursor posn
 db 0	;scroll
 db 8  ;window size
 dd buf8_end - buf8_start ;buf size (max=127)
 db -2	;end of string def
buf8_start:
 db '1       '
buf8_end:
 db ' (kernel function#)'
 db ' ',0ah

 db 0ah

 db 'Show:  Process#   '
key_p: db '(alt-p)',0ah
 db '       Address    '
key_a: db '(alt-a)',0ah
 db '       Sequence#  '
key_s: db '<alt-s>',0ah
 db '       Function   '
key_f: db '<alt-f>',0ah
 db '       Registers  '
key_r: db '(alt-r)',0ah
 db '       Extras     '
key_e: db '(alt-e)',0ah
 db '       Disassebly '
key_d db '(alt-d)',0ah

 db 0ah

 db '<Help alt-h > <Lst Fun# alt-l > <Cancel ESC > <Begin Enter >',0

;------------------------------------------------------------------------
help_msg:
 db ' AsmTrace Help',0ah
 db ' -------------',0ah,0ah
 db 'AsmTrace can be started as follows:',0ah
 db '    asmtrace <Enter>             - starts interactive mode',0ah
 db '    asmtrace <file> <Enter>      - preforms default trace',0ah
 db '    asmtrace <-a> <file> <Enter> - attach to file and trace',0ah
 db 0ah
 db 'AsmTrace default output is to a file ending with ".tra".  The',0ah
 db 'name of the file is obtained from the input file with appended',0ah
 db '.tra',0ah
 db 0ah
 db 'The default mode is to trace the entire file and show sequence',0ah
 db 'numbers and kernel functions.  If different trace setup is',0ah
 db 'desired, the interactive mode can be used.  It is started',0ah
 db 'by executing AsmTrace without any parameters.',0ah
 db 0ah
 db 'Interactive mode allows control over area traced and amount',0ah
 db 'of data stored.  It begins by showing a form with highlighted',0ah
 db 'areas that can be filled in.  To select an item either click',0ah
 db 'on it or type the indicated key. ',0ah
 db 0ah
 db 'Summary of form',0ah
 db 0ah
 db ' key    description',0ah
 db ' -----  --------------------------------------------------------',0ah
 db 0ah
 db ' alt-t  attach to executing program and trace it',0ah
 db ' F1     enter name of executable to trace',0ah
 db ' F2     enter name of output file (optional)',0ah
 db 0ah
 db ' F3     enter sequence# that triggers tracing',0ah
 db ' F4     enter address that triggers tracing',0ah
 db ' F5     enter kernel function# that triggers tracing',0ah
 db 0ah
 db ' F6     enter sequence# that stops tracing',0ah
 db ' F7     enter address that stops tracing',0ah
 db ' F8     enter kernel function# that stops tracing',0ah
 db 0ah
 db ' alt-p  show process# in output',0ah
 db ' alt-a  show instruction address in output',0ah
 db ' alt-s  show sequence# in output',0ah
 db ' alt-f  show kernel function info',0ah
 db ' alt-r  show registers',0ah
 db ' alt-e  show extra information if avail',0ah
 db ' alt-d  show disassembly (forces single step, slow!',0ah
 db 0ah
 db ' alt-h  display this help',0ah
 db ' alt-l  show list of kernel functions',0ah
 db ' ESC    exit with doing trace',0ah
 db ' alt-b  begin trace, also Enter key works',0ah
 db 0ah
 db 'Tracing can be triggered by first sequence#, or address,',0ah
 db 'or function# found.  Tracing stops when any stop trigger',0ah
 db 'is found.  It is possible to turn trace on and off several',0ah
 db 'times',0ah
 db 0ah
help_end:
;------------------------------------------------------------------------

traced_file:
 db 0,0
 times 180 db 0
outfile_name:
 db '?.tra'
 times 180 db 0

start_seq         dd 1
start_adr	  dd 0
start_fun	  dd 0
stop_seq          dd 0
stop_adr          dd 0
stop_fun          dd 0

parse_attach:     db 0
parse_follow:	  db 0	;0=no follow 1=follow

parse_show_process: db 0 ;
parse_show_adr:	  db 1 ;0=no adr
parse_show_seq:	  db 1 ;
parse_show_fun:     db 1
parse_show_regs:  db 1
parse_show_extra:  db 0
parse_show_disasm: db 0


  [section .text]
