
%ifndef DEBUG
struc	menu_struc
.menu_line	resb	1	;menu display line number
.menu_columns	resb	1	;number of columns in menu
.menu_space_color resb	1	;color number for spaces
.menu_color_table resd	1	;ptr to color table
.menu_text	resd	1	;ptr to menu text line
.menu_process	resd	1	;ptr to process for each button
.menu_colors	resd	1	;ptr to color numbers for each button
.menu_keys	resd	1	;ptr to menu keys for each button
endstruc
%endif

;>1 menu
;  menu_decode - decode menu key/mouse event
; INPUTS
;    esi = ptr to menu structure (see below)
;    [kbuf] has key/mouse
;     if kbuf starts with byte of -1 then
;     it is a mouse click and following bytes are:
;      button(0-3), column(1-x), row(1-x)
;      button = 0=left 1=middle 2=right 3=release
; OUTPUT
;    eax = process or negative if no match
;          js/jns flag set
; OPERATION
;    The event in "kbuf" is compared to each menu line
;    line description.  If a match is found the specified
;    process is returned.
;
;    The normal sequence of events is:
;
;      mov	esi,menu_line_ptrs
;      call	menu_display		;display menu
;      call	read_stdin		;wait for event, ->kbuf
;      mov	esi,menu_line_ptrs
;      call	menu_decode		;menu button pressed?
;      call	eax
;
;    The menu_line_ptrs point to a data structure which
;    describes the menu display, all mouse areas, and key
;    board actions.  An example follows:
;
; menu defiition - define a 2 line button menu
;
; -----
;    menu_line_ptrs:
;      dd	menu_line1_ptrs	;pointer to menu line 1 definition
;      dd	menu_line2_ptrs ;pointer to menu line 2 definition
;      dd	0		;end of pointers
;-------
;    menu_line1_ptrs:
;      db	1		;display at line number
;      db	1		;color number for space between buttons
;      dd	color_table	;color definitions
;      dd	menu1_text	;menu text line
;      dd	menu1_process	;process's to call for each button
;      dd	menu1_colors	;colors associated with each button
;      dd	menu1_keys	;keys associated with each button
;
;    menu_line2_ptrs:
;      db	2		;line number
;      db	1		;space color number
;      dd	color_table
;      dd	menu2_text
;      dd	menu2_process
;      dd	menu2_colors
;      dd	menu2_keys
;------
;      hex color def: aaxxffbb  aa-attr ff-foreground  bb-background
;      30-blk 31-red 32-grn 33-brown 34-blue 35-purple 36-cyan 37-grey
;      attributes 30-normal 31-bold 34-underscore 37-inverse
;    color_table:
;    ct1:   	dd	30003730h	;color 1 grey on black - spaces, page color
;    ct2:   	dd	30003037h	;color 2 black on grey - button text color
;    ct3:    dd	30003437h	;color 3 blue on grey - highlight bar color
;------
;     menu text consists of 'space-counts' and text.  space-counts
;     are encoded as numbers from 1-8.  the end of text line has 'zero' char
;     The following  lines describe two button sets.  Each button set uses
;     two display lines.
;    menu1_text:
;     db 1,'raw(r)',1,'src(s)',1,'code(t)',1,'data(i)',,0
;    menu2_text:                                                                       
;     db 1,' mode ',1,' mode ',1,' area  ',1,' area  ',',0
;
;    menu1_process:
;    menu2_process:
;     dd set_raw, set_src, set_code, set_data
;-------
;    colors for each button on line.  See color table above
;    menu1_colors:
;    menu2_colors:
;     db 2,2,2,2
;-------
;    menu1_keys:
;    menu2_keys:
;     db	'r',0	;raw mode key
;     db	's',0	;src mode key
;     db	't',0	;code section
;     db	'i',0	;data section
;     db	0 ;end of keys
; ---
;
; NOTES
;    source file: menu_decode.asm
;                     
;<
;  * ----------------------------------------------

  extern kbuf
  extern crt_columns

  global menu_decode
menu_decode:
mud_loop:
  push	esi
  mov	esi,[esi]	;get next ptr
  or	esi,esi
  jz	mud_done	;exit if end of lines
  call	look_for_event  ;set eax -> process if found, else neg
  pop	esi
  jns	mud_exit	;jmp if event found
  add	esi,4
  jmp	short mud_loop
mud_done:
  pop	esi
mud_exit:
  or	eax,eax
  ret
;----------------------------------------------------------
; input:  esi = ptr to menu line table entry as follows:
;               db x   ;display line# 1+
;               db x   ;color number for spaces
;               dd x   ;color table ptr
;               dd x   ;menu text
;               dd x   ;process
;               dd x   ;color numbers ptr
;               dd x   ;menu key definitions
;         [kbuf] has key/mouse
; output: eax = event process if found
;               else eax = -1
;               flags set for js/jns
look_for_event:
  mov	ebp,[esi+menu_struc.menu_process]
  cmp	byte [kbuf],-1
  je	lfe_mouse		;jmp if mouse event
;key press event possible
  mov	esi,[esi+menu_struc.menu_keys]
ka_lp:
  mov	edi,kbuf
  cmpsb
  je	first_char_match
ka_10:
  lodsb
  or	al,al		;scan to end of table key string
  jnz	ka_10
  add	ebp,byte 4	;move to next process
  cmp	byte [esi],0	;check if end of table
  je	ka_fail_exit
  jmp	short ka_lp
first_char_match:
  cmp	byte [esi],0	;check if all match
  jne	check_next
  cmp	byte [edi],0
  je	get_process
  jmp	ka_10		;go restart search
check_next:
  cmpsb
  je	first_char_match
  jmp	ka_10
get_process:
  mov	eax,[ebp]	;get process
  jmp	short ka_exit
ka_fail_exit:
  mov	eax,-1  
  jmp	ka_exit
;check for mouse event ------
lfe_mouse:
  mov	al,[esi]	;get menu line number
  cmp	al,[kbuf+3]	;check click line
  jne	ka_fail_exit	;exit if wrong line
  mov	esi,[esi+menu_struc.menu_text]
;if first button has 'space' in front, adjust ebp
  cmp	byte [esi],8
  ja	lfe_20
  sub	ebp,4
;ebp = ptr to process's    esi=ptr to menu text line
;kbuf has (-1,button,col,row)
lfe_20:
  mov	cl,1		;starting column
lfe_loop:
  cmp	cl,[crt_columns]
  jae	ka_fail_exit
  cmp	cl,[kbuf+2]	;column match
  je	get_process	;jmp if match
  lodsb
  cmp	al,8
  jbe	lfe_30
  inc	cl
  jmp	short lfe_loop
lfe_30:
  add	cl,al		;move column
  add	ebp,4		;move to next process
  jmp	short lfe_loop
ka_exit:
  or	eax,eax		;set flags
  ret

