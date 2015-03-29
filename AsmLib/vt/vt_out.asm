;---------------------------------------------------
;>1 vt
;vt_out - send text to vt display
; INPUT
;        ecx = ptr to string
;        edx = lenght of string
;        [vt_image] - ptr to top of screen image
;        [color_image_ptr] - top color table
;        [vt_image_write_color]        
;        [vt_rows] - dword
;        [vt_columns] - dword
;        [ptty_fd] dword - used to send reports
;
; OUTPUT
;         edx = number of char's unprocessed
;         ecx = next char or end ptr
;   
; NOTE
;   Normally we read data from ptty_fd and feed
;   the display by using vt_out.  It is also possible
;   to feed arbatrary text to the display.
;<
;---------------------------------------------------
  [section .text align=1]

; sequence label                status   description
; 
; 08       backspace            yes
; 09       tab                  yes
; 0a       linefeed             yes
; 0d       return               yes
; 1b       escape               yes
; 7f       -                    ignore   delete
; 9b       set_csi              yes
; 
; esc 7    save_cursor          yes
; esc 8    restore_cursor       yes
; esc >    numberic_pad         flag
; esc =    app_pad              flag
; esc c    reset                yes
; esc D    esc_D                yes       linefeed
; esc E    cr_lf                yes
; esc H    home                 yes       home cursor
; esc M    reverse              yes       move cursor up
; esc Z    send_id
; 
; esc #3   -                    no        double height line
; esc #4   -                    no        half height line
; esc #5   -                    no        signle width line
; esc #6   -                    no        double width line
; 
; esc [[   restart2             yes       cancel
; esc [@   atsign               yes       insert blanks
; esc [A   csi_A                yes       move cursor up
; esc [B   csi_B                yes       move cursor down
; esc [C   csi_C                yes       move cursor right
; esc [D   csi_D                yes       move cursor left
; esc [E   csi_E                yes       move cursor down
; esc [F   csi_F                yes       move cursor up
; esc [G   csi_G                yes       move to column
; esc [H   csi_H                yes       move cursor (default 1:1)
; esc [J   csi_J                yes       erase from cursor to end
; esc [1J  csi_J                yes       erase from start to cursor
; esc [2J  csi_J                yes       erase screen
; esc [K   csi_K                yes       erase 0=right 1=left 2=line
; esc [L   csi_L                yes       insert blanks
; esc [M   csi_M                yes       delete line
; esc [P   csi_P                yes       delete char in line       
; esc [X   csi_X                yes       erase characters
; esc [a   csi_a                yes       cursor right
; esc [c   csi_c                yes       report
; esc [d   csi_d                yes       cursor to row
; esc [e   csi_e                yes       cursor down
; esc [f   csi_f                yes       cursor (goto csi_H)
; esc [g   csi_g                -         clear tabs
; esc [h   csi_h                flag      set mode
; esc [2h  csi_h                flag      lock keyboard
; esc [4h  csh_h                flag      insert mode
; esc [12h csi_h                flag      set echo off
; esc [20h csi_h                flag      0d=0d,0a
; esc [l   csi_l                flag      reset mode
; esc [2l  csi_l                flag      unlock keys
; esc [4l  csi_l                flag      replace mode
; esc [12l csi_l                flag      echo on
; esc [20l csi_l                flag      0d=0d
; esc [m   csi_m                yes       color (default color)
; esc [1m  csi_m                yes       bold colors
; esc [.;.m csi_m               yes       see color table
; esc [n   csi_n                yes       status reports
; esc [q   csi_q                -         set leds
; esc [r   csi_r                -         set scroll region
; esc [s   csi_s                yes       save cursor
; esc [u   csi_u                yes       restore cursor
; 
; esc [?h  question_h
; esc [?1h   DECCKM             yes       set app keypad
; esc [?3h   DECCOLM            no        80 column mode
; esc [?5h   DECTECM            yes       reverse color 
; esc [?6h   DECOM              no        scroll region=origon
; esc [?7h   DECAWM             yes       wrap
; esc [?8h   DECARM             no        auto repeat
; esc [?10h
; esc [?18h
; esc [?19h
; esc [?21h
; esc [?22h
; esc [?23h
; esc [?24h
; esc [?25h   mouse2
; esc [?1000h _mouse1
; 
; esc [?l  question_l
; esc [?1l   DECCKM             yes       set app keypad
; esc [?3l   DECCOLM            no        reset 80 column mode
; esc [?5l   DECTECM            yes       reverse color
; esc [?6l   DECOM              no        origion = top of win
; esc [?7l   DECWM              yes       no wrap
; esc [?8l   DECARM             no        auto repeat
; esc [?10l
; esc [?18l
; esc [?19l
; esc [?21l
; esc [?22l
; esc [?23l
; esc [?24l
; esc [?25l
; esc [?1000l
; 
; esc %@     sel_default        no         select char set
; esc %G     sel_utf            no         select char set
; esc %8     sel_old            no         select char set
; 
; esc (B     sel_iso            no
; esc (0     sel_vt             no
; esc (U     sel_null           no
; esc (K     sel_user           no
; 
; esc )B     unsel_iso
; esc )0     unsel_vt
; esc )U     unsel_null
; esc )K     unsel_user
; 
; esc ]P     color1
; esc ]R     color2
; esc ]0 <bel> comment          yes
;
;
%include "../include/dcache_colors.inc"
 
  extern rowcol_to_image
  extern vt_rows
  extern vt_columns
  extern vt_image_write_color
  extern vt_image
  extern vt_display_size
  extern vt_set_all_writes
  extern ptty_fd
  extern sys_write
  extern vt_clear
  extern default_color
  extern quick_ascii
  extern vt_image_end
  extern ascii_to_dword
;--------------
;--------------
; input: ecx = ptr to string
;        edx = lenght of string
;        [vt_image] - ptr to top of screen image
;        [color_image_ptr] - top color table
;        [vt_image_write_color]        
;        [vt_rows] - dword
;        [vt_columns] - dword
;        [ptty_fd] dword - used to send reports
;
; output: edx = number of char's unprocessed
;         ecx = next char or end ptr

;--
vt_exit:
  mov	[vt_stuff_col],ebx	;save stuff location
  ret

;----------------------
  global vt_out
vt_out:
;  call	check_termios_wrap
  mov	ebx,[vt_stuff_col]	;get row/col
  call	rowcol_to_image		;set ebp
  jmp	short vt_entry
;
; loop registers ecx = vt input
;                edx = vt input length
;                 bl = stuff column
;                 bh = stuff row
;                ebp = stuff ptr for vt_image
;--
vt_loop:
  inc	ecx		;bump char ptr
  dec	edx		;decrement char's remaining
;--
;--
vt_entry:
  or	edx,edx
  jz	vt_exit		;exit if out of data
  mov	al,[ecx]	;get char
;------- level 1 decode -----
; Control characters can be used in the _middle_ of an escape sequence.
;----------------------------
  cmp	al,9bh
  je	set_csi		;jmp if 9bh "esc["
  cmp	al,7fh		;delete
  je	vt_loop		;ignore delete key
  cmp	al,1bh		;escape?
  ja	char_not_found
  je	escape		;jmp if escape found
  cmp	al,0dh
  je	return
  cmp	al,0ah
  je	linefeed
  cmp	al,0bh
  je	linefeed
  cmp	al,09h
  je	tab
  cmp	al,0eh		;select G1 char's
  je	select_G1
  cmp	al,0fh
  je	select_G0
  cmp	al,8h		;backspace?
  jne	vt_loop		;ignore all others
  jmp	backspace

char_not_found:
  test	[current_flag],byte 80h	;is table active
  jnz	esc_active	;jmp if sequence in progress
  test	al,080h		;possible utf-8 char sequence?
  jnz	utf_check	;jmp if possible utf-8 char
  call	stuff_char
  jmp	short vt_loop  
utf_check:
  and	al,0f0h
  cmp	al,0c0h		;two byte sequence?
  je	two_byte_utf
  cmp	al,0e0h
  je	three_byte_utf
  jmp	short vt_loop	;ignore this char
two_byte_utf:
  inc	ecx
  dec	edx
  mov	al,'*'
  call	stuff_char
  jmp	vt_loop
three_byte_utf:
  add	ecx,byte 2
  sub	edx,byte 2
  mov	al,'*'
  call	stuff_char
  jmp	vt_loop
;-----------------------------------------------------
; level 1 commands
set_csi:
  mov	[current_table],dword csi_table
  mov	[current_flag],byte 81h
  jmp	vt_loop
;----
escape:
  mov	[current_table],dword esc_table
  mov	[current_flag],byte 80h
  jmp	vt_loop
;----
backspace:
  cmp	bl,1		;at left edge
  je	vt_loop		;jmp if at edge
  dec	bl
  call	rowcol_to_image
;blank char under cursor
;  mov	ah,[vt_image_write_color]
;  mov	al,' '
;  or	ax,8080h
;  mov	[ebp],ax 

  jmp	vt_loop
;----
tab:
tab_lp:
  mov	al,' '
  call	stuff_char
  and	bl,7		;at tab?
  jnz	tab_lp
  jmp	vt_loop
;----
;   0ah or ESC D          on unix systems 0ah is cr/lf and 0dh is ?
linefeed:
  push	edx
  cmp	bh,[vt_rows]	;last row?
  jb	do_linefeed	;jmp if in window
  call	scroll_up
;;  dec	bh
  call	rowcol_to_image
  pop	edx
  jmp	vt_loop
do_linefeed:
  inc	bh
  call	rowcol_to_image
  pop	edx
  jmp	vt_loop
;----
return:
  mov	bl,1		;set column =1
  call	rowcol_to_image
  jmp	vt_loop
;----
select_G1:
  mov	al,[G1_char_set]
  mov	[char_set],al
  jmp	vt_loop

select_G0:
  mov	al,[G0_char_set]
  mov	[char_set],al
  jmp	vt_loop
;------------------------------------------------------
; level 1 subroutines
;------------------------------------------------------

;stuff char into image
stuff_char:
  cmp	al,1bh		;check for legal char
  ja	sc_ok		;jmp if char ok
  mov	al,'.'
sc_ok:
  cmp	bl,[vt_columns]		;check right edge of window
;  jb 	do_stuff		;jmp if not at right edge
  jbe 	do_stuff		;jmp if not at right edge
stuff_wrap_check:
;check if wrapping
  cmp	[wrap_flag],byte 0
  je	stuff_exit		;exit if no wrap
sc_row_check:
  cmp	bh,[vt_rows]	;at end of screen?
  jb	do_stuff	;jmp if not at end  
  push	eax
  call	scroll_up
  dec	bh
  call	rowcol_to_image
  pop	eax		;restore char to write
do_stuff:
  test	[char_set],byte 8
  jz	do_stuff2
  cmp	al,60h
  jb	do_stuff2
  mov	al,'*'		;we are in draw mode, use "*"
do_stuff2:
  mov	ah,[vt_image_write_color]
;  cmp	ah,[ebp+1]	;color change
;  je	do_char
  or	ax, 8000h		;set color change flag
;  jmp	short do_bump
do_char:
;  cmp	al,[ebp]	;data change
;  je	do_bump		;jmp if no data change
;  or	al,80h		;set changed flags
;do_bump:
  mov	[ebp],ax	;store char
do_bump2:
  add	ebp,2		;advance stuff ptr
  cmp	bl,[vt_columns]
  jbe	do_bump3
;  jb	do_bump3
  mov	bl,1
  inc	bh
do_bump3:
  inc	bl		;bump column
stuff_exit:
  ret

;-------------------------------------------------
force_scroll:
  mov	bl,1		;move to column 1
;-------------------------------------------------
;set the column to 1 when done.
;scroll data up and blank end line
scroll_up:
  push	ecx
  mov	edi,[vt_image]
  mov	esi,edi
  mov	eax,[vt_columns]
  shl	eax,1		;image bytes per column
  add	esi,eax		;
  mov	ecx,[vt_display_size]
  sub	ecx,[vt_columns];compute move count
  cld
  rep	movsw
;blank the end line
  mov	ecx,[vt_columns]
  mov	ah,[vt_image_write_color]
  mov	al,' '
  rep	stosw
  call	vt_set_all_writes
  pop	ecx
  ret
;-------------------------------------------------
;set the column to 1 when done. set 
scroll_down:
  push	ecx
  mov	edi,[vt_image]
  mov	ecx,[vt_display_size]
  add	edi,ecx	;comute end
  add	edi,ecx	;  of image
  mov	eax,[vt_columns]
  sub	ecx,eax ;compute move length
  mov	esi,edi
  sub	esi,eax	;compute from ptr
  sub	esi,eax ;copute from ptr
  sub	esi,2
  sub	edi,2
  std
  rep	movsw
;blank the top line
  mov	ecx,[vt_columns]
  mov	ah,[vt_image_write_color]
  mov	al,' '
  rep	stosw
  cld
  call	vt_set_all_writes
  pop	ecx
  ret
;------------------------------------------------
; level 2 decode
;------------------------------------------------
; level 2 registers
;                 bl = stuff column
;                 bh = stuff row
;                ebp = stuff ptr for vt_image

esc_active:
  push	ecx		;save input data ptr
  push	edx		;save input char count
  test	[current_flag],byte 01h ;parameter check needed?
  jz	decode_cmd	;jmp if no parameter check
;collect parameters
  cmp	al,'0'
  jb	decode_cmd	;jmp if not 0-9 or ;
  cmp	al,';'
  ja	decode_cmd	;jmp if not 0-9 or ;
  jb	save_par	;jmp if 0-9
  inc	byte [es_flag]
  jmp	restart3	;get next
save_par:
  cmp	byte [es_flag],1
  je	do_par2
  ja	do_par3
do_par1:
  mov	ecx,parm1
  jmp	short do_par_tail
do_par2:
  mov	ecx,parm2
  jmp	short do_par_tail
do_par3:
  mov	ecx,parm3
do_par_tail:
  cmp	[ecx],byte 0
  je	do_tail_stuff
  inc	ecx
  cmp	[ecx],byte 0
  je	do_tail_stuff
  inc	ecx
  cmp	[ecx],byte 0
  je	do_tail_stuff
  inc	ecx
do_tail_stuff:
  mov	[ecx],al
  jmp	restart3
  
decode_cmd:
  mov	esi,[current_table]
  call	scan_table	;check for action, carry=not in table
  jnc	decode2		;jmp if entry found
;char not in table, store and restart
  cmp	[current_table],dword esc_table
  je	keep_char
  jmp	restart1
keep_char:
   mov	[parm1],dword 0
   mov	[parm2],dword 0
   mov	[es_flag],byte 0
   mov	[current_flag],byte 0
   pop	edx
   pop	ecx
   mov	al,[ecx]	;get char again
   call	stuff_char
   jmp	vt_loop  

;;  jc	restart1
decode2:
  test	al,80h		;another table?
  jz	do_process
  mov	[current_table],esi
  mov	[current_flag],al
  jmp	restart3

do_process:
  jmp	esi		;go do process

;come here after command complete
restart1:
  mov	[parm1],dword 0
  mov	[parm2],dword 0
  mov	[parm3],dword 0
  mov	[es_flag],byte 0
restart2:
  mov	[current_flag],byte 0
restart3:
  pop	edx
  pop	ecx
  jmp	vt_loop
;--------------
  [section .data]
es_flag	db 0	;0=collecting par1 1=doing parm2
parm1	dd 0
	db 0	;terminator for parm1
parm2	dd 0
	db 0	;terminator for parm2
parm3	dd 0
	db 0	;terminator for parm3
parm4	db 0	;dummy parm to terminate parameters
  [section .text]
;----------------------------------------------------
;input:   al = char
;         esi = table ptr -> char,flag,(action/table)
;
;output:
;         carry flag - char not found
;         no carry - al=flag from table, 80=tbl 01=parm
;                   esi=action from table
scan_table:
  or	al,al
  jz	ignore_action
st_loop:
  cmp	[esi],al
  je	st_hit	;jmp if char found
  add	esi,6
  cmp	[esi],byte 0
  jne	st_loop
;end of table, return not found
  stc
  jmp	short st_exit2
;return ignore action
ignore_action:
  mov	esi,restart3	;ignore char
  jmp	short st_exit1
st_hit:
  mov	al,[esi+1]	;get flag
  mov	esi,[esi+2]	;get table action/table
st_exit1:
  clc 
st_exit2:
  ret

;-------------------------------------------------
  [section .data]
esc_table:
  db 'c',0
  dd reset

  db 'D',0
  dd esc_D

  db 'E',0
  dd cr_lf

  db 'F',0
  dd esc_F

  db 'G',0
  dd esc_G
  
  db 'H',0
  dd home

  db 'M',0
  dd reverse

  db 'Z',0
  dd send_id

  db '7',0
  dd save_cursor

  db '8',0
  dd restore_cursor

  db '[',81h
  dd csi_table

  db '%',81h
  dd percent_table

  db '#',81h
  dd line_width

  db '(',80h
  dd pren1_table

  db ')',80h
  dd pren2_table

  db '>',0
  dd numeric_pad

  db '=',0
  dd app_pad

  db ']',80h
  dd xterm_table

  db 0		;end of table

  [section .text]
;-------------------------------------------------
; all commands exit to restart2
;          ESC c          Reset to Initial State 
reset:
  mov	ecx,[vt_display_size]
  mov	ah,[vt_image_write_color]
  mov	al,' ' 	;space
  or	ah,80h	;set changed flag
  mov	edi,[vt_image]
  rep	stosw		;clear the screen
  mov	bx,0101h
  call	rowcol_to_image
  jmp	restart2

;          ESC D          Index - Moves the cursor down one line. The cursor
;                         remains  in  the  same  column.  A  scroll  up  is
;                         performed if the cursor moves below line 24.
esc_D:
  pop   edx
  pop	ecx
  jmp	linefeed

;          ESC E          Next Line -  Moves  the cursor to the first column
;                         of the  next line. A scroll up is performed if the
;                         cursor moves below line 24.
cr_lf:
  cmp	bh,[vt_rows]
  jbe	do_cr_lf
  call	scroll_up
do_cr_lf:
  inc	bh
  mov	bl,1
  call	rowcol_to_image
  jmp	restart2

; esc F us graphics char set
;
esc_F:
  mov	[char_set],byte 2
  jmp	restart2

; esc G us/uk ascii
esc_G:
  mov	[char_set],byte 2
  jmp	restart2

;       ESC Z     DECID    DEC private identification. The kernel returns the
;                          string  ESC [ ? 6 c, claiming that it is a  VT102.
send_id:
  push	ebx
  mov	ebx,[ptty_fd]
  mov	ecx,id_to_send
  mov	edx,id_to_send_len
  call	sys_write
  pop	ebx
  jmp	restart2
;-----
  [section .data]
id_to_send: db 1bh,'[0nvt_asm01'
id_to_send_len equ $ - id_to_send
  [section .text]

;          ESC 7          Save cursor - Saves  the  current  cursor position
;                         (line,column),   display    character   attribute,
;                         selected character set, and origin mode.
save_cursor:
  mov	[saved_row_col],ebx
  jmp	restart2

;          ESC 8          Restore Cursor -  Restores the cursor position and
;                         other  saved attributes to the values recorded  by
;                         the last "ESC [  7"  sequence.  If the save cursor
;                         escape sequence has  not been received since PC-VT
;                         was started, no values are restored and the cursor
;                         is moved to the top left margin.
restore_cursor:
  mov	ebx,[saved_row_col]
  call	rowcol_to_image
  jmp	restart2


;          ESC # 3 and ESC # 4
;                         Double  Height  Line,  Top  Half and Double Height
;                         Line, Bottom  Half  -  These  two  sequences  must
;                         always be used in pairs on adjacent  lines. Double
;                         height lines are simulated  in  PC-VT  by blanking
;                         the top line and converting the  bottom  line into
;                         double width  by taking the left half of the line,
;                         inserting  blanks  between   the   characters  and
;                         placing them back down to occupy the  entire line.
;                         Any characters on  the  right half of the line are
;                         lost.;
;
;          ESC # 5        Single Width Line - Converts the current line into
;                         a single  width  line.  PC-VT  simulates  this  by
;                         taking  every  other  character  from the line and
;                         putting them down in  the  left  half of the line.
;                         The right half of the line is blanked.;
;
;          ESC # 6        Double Width Line - Converts the current line into
;                         simulated  double  width  characters by taking the
;                         left half of the  line,  inserting  blanks between
;                         the characters  and  placing  them  back  down  to
;                         occupy  the  entire line. Any  characters  on  the
;                         right  half  of  the  line  are  lost.  The cursor
;                         remains in the  same character position unless the
;                         cursor would  have  moved  off  the  right  of the
;                         screen. In  that case, the cursor is placed at the
;                         right margin.

line_width:
;dump next char.
  pop	edx
  pop	ecx
  inc	ecx
  dec	edx
  push	ecx
  push	edx
  jmp	restart2

numeric_pad:
  mov	[pad_flag],byte 1
  jmp	restart2

app_pad:
  mov	[pad_flag],byte 0
  jmp	restart2

;          ESC H          Cursor Position (Home) - Move  the  cursor  to the
;                         top left  of the screen. Same as the sequence "ESC
;                         [ 1 ; 1 H" or "ESC [ 1 ; 1 f".
home:
  mov	bx,0101h
  call	rowcol_to_image
  jmp	restart2

;          ESC M          Reverse Index  - Moves the cursor up one line. The
;                         cursor remains in the same column.  A  scroll down
;                         is performed if the cursor moves above line 1.
reverse:
  cmp	bh,1		;at top
  ja	do_reverse	;jmp if not at line 1
  call	scroll_down
  mov	bl,1
  call	rowcol_to_image
  jmp	restart2
do_reverse:
  dec	bh
  mov	bl,1
  call	rowcol_to_image
  jmp	restart2

;-------------------------------------------------
  [section .data]
csi_table:
  db '[',0
  dd restart2

  db '?',81h
  dd question_tbl

;       @   ICH       Insert the indicated # of blank characters.
  db '@',1
  dd atsign

;       A   CUU       Move cursor up the indicated # of rows.
  db 'A',0
  dd csi_A

;       B   CUD       Move cursor down the indicated # of rows.
  db 'B',0
  dd csi_B

;       C   CUF       Move cursor right the indicated # of columns.
  db 'C',0
  dd csi_C

;       D   CUB       Move cursor left the indicated # of columns.
  db 'D',0
  dd csi_D

;       E   CNL       Move cursor down the indicated # of rows, to column 1.
  db 'E',0
  dd csi_E

;       F   CPL       Move cursor up the indicated # of rows, to column 1.
  db 'F',0
  dd csi_F

;       G   CHA       Move cursor to indicated column in current row.
  db 'G',0
  dd csi_G

;       H   CUP       Move cursor to the indicated row, column (origin at 1,1).
  db 'H',0
  dd csi_H

;       J   ED        Erase display (default: from cursor to end of display).
;                     ESC [ 1 J: erase from start to cursor.
;                     ESC [ 2 J: erase whole display.
  db 'J',0
  dd csi_J

;       K   EL        Erase line (default: from cursor to end of line).
;                     ESC [ 1 K: erase from start of line to cursor.
;                     ESC [ 2 K: erase whole line.
  db 'K',0
  dd csi_K

;       L   IL        Insert the indicated # of blank lines.
  db 'L',0
  dd csi_L

;       M   DL        Delete the indicated # of lines.
  db 'M',0
  dd csi_M

;       P   DCH       Delete the indicated # of characters on the current line.
  db 'P',0
  dd csi_P

;       X   ECH       Erase the indicated # of characters on the current line.
  db 'X',0
  dd csi_X

;       a   HPR       Move cursor right the indicated # of columns.
  db 'a',0
  dd csi_a

;       c   DA        Answer ESC [ ? 6 c: ‘I am a VT102’.
  db 'c',0
  dd csi_c

;       d   VPA       Move cursor to the indicated row, current column.
  db 'd',0
  dd csi_d

;       e   VPR       Move cursor down the indicated # of rows.
  db 'e',0
  dd csi_e

;       f   HVP       Move cursor to the indicated row, column.
  db 'f',0
  dd csi_f

;       g   TBC       Without parameter: clear tab stop at the current position.
;                     ESC [ 3 g: delete all tab stops.
  db 'g',0
  dd csi_g

;       h   SM        Set Mode (see below).
  db 'h',01h
  dd csi_h

;       l   RM        Reset Mode (see below).
  db 'l',01h
  dd csi_l

;       m   SGR       Set attributes (see below).
  db 'm',01h
  dd csi_m

;       n   DSR       Status report (see below).
  db 'n',01h
  dd csi_n

;       q   DECLL     Set keyboard LEDs.
;                     ESC [ 0 q: clear all LEDs
;                     ESC [ 1 q: set Scroll Lock LED
;                     ESC [ 2 q: set Num Lock LED
;                     ESC [ 3 q: set Caps Lock LED
  db 'q',1
  dd  csi_q

;       r   DECSTBM   Set scrolling region; parameters are top and bottom row.
  db 'r',0
  dd csi_r

;       s   ?         Save cursor location.
  db 's',0
  dd csi_s

;       u   ?         Restore cursor location.
  db 'u',0
  dd csi_u

  db 0	;end of table

  [section .text]
;-------------------------------------------------
;       @   ICH       Insert the indicated # of blank characters.
;          ESC [ Pn @     Insert Character - Inserts Pn  characters starting
;                         at the cursor  position. Character(s) to the right
;                         of the cursor column move right.  Pn,  if omitted,
;                         is assumed to be  1.  Character(s)  moved  off the
;                         right of the display are lost.
atsign:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	atsign_20
  inc	ecx		;set count to 1
atsign_20:
  mov	ah,[vt_image_write_color]
  mov	al,' '
  call	line_insert
  jmp	restart1


;       A   CUU       Move cursor up the indicated # of rows.
;          ESC [ Pn A     Cursor Up  - Moves cursor up Pn lines. If omitted,
;                         Pn is assumed to be 1. If the cursor is already at
;                         the top of the screen, this  sequence  is ignored.
;                         If Pn is  greater than the number of lines  to the
;                         top of the screen, the  cursor is moved to the top
;                         of the screen.
csi_A:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_A_10
  inc	ecx		;set count to 1
csi_A_10:
  sub	bh,cl		;move row up
  jnl	csi_A_20	;jmp if new row ok
  mov	bh,1		;force row 1
csi_A_20:
  call	rowcol_to_image
  jmp	restart1
  

;       B   CUD       Move cursor down the indicated # of rows.
;          ESC [ Pn B     Cursor Down  -  Moves  cursor  down  Pn  lines. If
;                         omitted, Pn is assumed to be 1. If  the  cursor is
;                         already at the bottom of the screen, this sequence
;                         is ignored. If Pn is  greater than  the  number of
;                         lines to the  bottom  of the screen, the cursor is
;                         moved to the bottom of the screen.
csi_B:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_B_10
  inc	ecx		;set count to 1
csi_B_10:
  add	bh,cl		;move row down
  cmp	bh,[vt_rows]
  jbe	csi_B_20	;jmp if new row ok
  mov	bh,[vt_rows]	;force last row 
csi_B_20:
  call	rowcol_to_image
  jmp	restart1

;       C   CUF       Move cursor right the indicated # of columns.
;          ESC [ Pn C     Cursor Right - Moves cursor right  Pn  columns. If
;                         omitted, Pn is assumed to be 1. If  the  cursor is
;                         already at the right margin  of  the  screen, this
;                         sequence is ignored. If  Pn  is   greater than the
;                         number of  columns  to  the  right  margin  of the
;                         screen, the cursor is moved to the right margin of
;                         the screen.
csi_C:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_C_10
  inc	ecx		;set count to 1
csi_C_10:
  add	bl,cl		;move right
  cmp	bl,[vt_columns]
  jbe	csi_C_20	;jmp if cursor ok
  mov	bl,[vt_columns]
csi_C_20:
  call	rowcol_to_image
  jmp	restart1


;       D   CUB       Move cursor left the indicated # of columns.
;          ESC [ Pn D     Cursor Left - Moves  cursor  left  Pn  columns. If
;                         omitted, Pn is assumed to be 1. If  the  cursor is
;                         already at the left  margin  of  the  screen, this
;                         sequence is ignored. If  Pn  is   greater than the
;                         number  of  columns  to  the  left  margin  of the
;                         screen, the  cursor is moved to the left margin of
;                         the screen.
;
csi_D:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_D_10
  inc	ecx		;set count to 1
csi_D_10:
  sub	bl,cl		;move right
  cmp	bl,1
  jnl	csi_D_20	;jmp if cursor ok
  mov	bl,1
csi_D_20:
  call	rowcol_to_image
  jmp	restart1


;       E   CNL       Move cursor down the indicated # of rows, to column 1.
csi_E:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_E_10
  inc	ecx		;set count to 1
csi_E_10:
  add	bh,cl		;move row down
  cmp	bh,[vt_rows]
  jbe	csi_E_20	;jmp if new row ok
  mov	bh,[vt_rows]	;force last row 
csi_E_20:
  mov	bl,1
  call	rowcol_to_image
  jmp	restart1

;       F   CPL       Move cursor up the indicated # of rows, to column 1.
csi_F:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_F_10
  inc	ecx		;set count to 1
csi_F_10:
  sub	bh,cl		;move row up
  jnl	csi_F_20	;jmp if new row ok
  mov	bh,1		;force row 1
csi_F_20:
  mov	bl,1
  call	rowcol_to_image
  jmp	restart1


;       G   CHA       Move cursor to indicated column in current row.
csi_G:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_G_10
  inc	ecx		;set count to 1
csi_G_10:
  mov	bl,cl
  cmp	bl,[vt_columns]
  jbe	csi_G_20	;jmp if cursor ok
  mov	bl,[vt_columns]
csi_G_20:
  call	rowcol_to_image
  jmp	restart1

;       H   CUP       Move cursor to the indicated row, column (origin at 1,1).
;          ESC [ Pl ; Pc H
;                         Cursor  Position  -  Moves  the cursor to absolute
;                         line given by  Pl and absolute column given by Pc.
;                         Pl must be between 1 and 24. Pc must be  between 1
;                         and 80. If omitted, Pl and Pc are assumed to be 1.
;          ESC [ H       Same as "ESC H" (home)
csi_H:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_H_10
  inc	ecx		;set count to 1
csi_H_10:
  mov	bh,cl		;move row 
  cmp	bh,[vt_rows]
  jbe	csi_H_20	;jmp if new row ok
  mov	bh,[vt_rows]	;force row
csi_H_20:
;do column
  mov	esi,parm2
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_H_30	;jmp if column ok
  inc	ecx		;set count to 1
csi_H_30:
  mov	bl,cl
  cmp	bl,[vt_columns]
  jbe	csi_H_40	;jmp if cursor ok
  mov	bl,[vt_columns]
csi_H_40:
  call	rowcol_to_image
  jmp	restart1

;       J   ED        Erase display (default: from cursor to end of display).
;                     ESC [ 1 J: erase from start to cursor.
;                     ESC [ 2 J: erase whole display.
;          ESC [ J        Erase In Display  -  Erases  the  screen  from the
;                         current cursor position to the bottom left  of the
;                         display.
;          ESC [ 0 J      Same as "ESC [ J".
;          ESC [ 1 J      Erase In  Display - Erases the screen from the top
;                         right  of  the   display  to  the  current  cursor
;                         position.
;          ESC [ 2 J      Erase In Display - Erases the entire screen.
csi_J:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
;ecx=parm
  cmp	cl,1
  jb	csi_J_0		;jmp if erase from cursor to end
  je	csi_J_1		;jmp if erase from 1:1 to cursor
;erase entire display
  mov	al,[vt_image_write_color]
  call	vt_clear
  jmp	restart1
;erase from cursor to end
csi_J_0:
  mov	ecx,[vt_display_size]
  shl	ecx,1		;compute buffer size
  mov	esi,[vt_image]
  add	esi,ecx		;compute end of image
  sub	esi,ebp		;compute clear byte count
  shr	esi,1		;convert to word count
  mov	ecx,esi		;ecx=clear count
  mov	edi,ebp		;get edi=starting point
  mov	ah,[vt_image_write_color]
  or	ah,80h
  mov	al,' '	;space
  rep	stosw
  jmp	restart1
;erase from 1:1 to cursor
csi_J_1:
  mov	edi,[vt_image]	;get start of display
  mov	ecx,ebp		;get cursor position
  sub	ecx,edi		;comute byte length
  shr	ecx,1		;convert to word len
  inc	ecx
  mov	ah,[vt_image_write_color]
  or	ah,80h
  mov	al,' '	;space
  rep	stosw
  jmp	restart1


;       K   EL        Erase line (default: from cursor to end of line).
;                     ESC [ 1 K: erase from start of line to cursor.
;                     ESC [ 2 K: erase whole line.
;          ESC [ K        Erase In Line -  Erases  the  line occupied by the
;                         cursor from the cursor to the end of the Line.
;          ESC [ 0 K      Same as "ESC [ K".
;          ESC [ 1 K      Erase In Line -  Erases  the  line occupied by the
;                         cursor from  the  beginning  of  the  line  to the
;                         cursor.
;          ESC [ 2 K      Erase In Line - Erases the entire  line containing
;                         the cursor.
csi_K:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
;ecx=parm
  cmp	cl,1
  jb	csi_K_0		;jmp if erase from cursor to end of line
  je	csi_K_1		;jmp if erase from start of line to cursor
;erase entire line
  push	ebx
  mov	bl,1		;force start of line
  call	rowcol_to_image	;find start of line
  mov	edi,ebp		;save start
  mov	ecx,[vt_columns]
  mov	ah,[vt_image_write_color]
  or	ah,80h
  mov	al,' '	;space
  rep	stosw
  pop	ebx
  call	rowcol_to_image
  jmp	restart1
;erase from cursor to end of line
csi_K_0:
  mov	edi,ebp		;set starting point
  push	ebx
  mov	bl,[vt_columns]
;  cmp	bl,[crt_columns]
;  jae	csi_K_0a
;  mov	bl,[crt_columns]
csi_K_0a:
  call	rowcol_to_image ;find end point
  pop	ebx		;restore cursor
  mov	ecx,ebp
  sub	ecx,edi		;compute byte clear count
  add	ecx,byte 2
  shr	ecx,1		;convert to word count
  
  mov	ah,[vt_image_write_color]
  or	ah,80h
  mov	al,' '	;space
  rep	stosw
  call	rowcol_to_image	;fix ebp
  jmp	restart1
;erase from start of line to cursor
csi_K_1:
  mov	ecx,ebp		;save cursor
  push	ebx
  mov	bl,1
  call	rowcol_to_image	;find start of line
  sub	ecx,ebp		;compute byte clear count
  shr	ecx,1		;compute word clear count
  inc	ecx
  mov	edi,ebp		;set start of line
  
  mov	ah,[vt_image_write_color]
  or	ah,80h
  mov	al,' '	;space
  rep	stosw
  pop	ebx		;restore cursor
  call	rowcol_to_image	;restore image ptr
  jmp	restart1

;       L   IL        Insert the indicated # of blank lines.
;          ESC [ Pn L     Insert Line - Inserts  Pn  lines  before  the line
;                         containing cursor. The  current line and all lines
;                         below it move down the display.  Lines  which move
;                         below the bottom scrolling margin are lost. Pn, if
;                         omitted, is assumed to be 1.
csi_L:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_L_10
  inc	ecx		;set count to 1
;move cusror to start of line
csi_L_10:
  mov	bl,1
  call	rowcol_to_image
;compute number of characters to insert
  mov	eax,[vt_columns]
  mul	ecx
  mov	ecx,eax		;ecx=char insert count
;get insert char
  mov	ah,[vt_image_write_color]
  or	ah,80h
  mov	al,' '	;space
  mov	esi,eax

  mov	esi,ebp		;insert point

  call	blk_word_hole

  call	rowcol_to_image
  jmp	restart1


;       M   DL        Delete the indicated # of lines.
;          ESC [ Pn M     Delete Line - Deletes  Pn  lines  starting  at the
;                         line containing the  cursor and below. Lines below
;                         the deleted lines move  up.  New  blank  lines are
;                         created to fill the bottom of the  scrolling area.
;                         If omitted, Pn is assumed to be 1.
csi_M:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_M_10
  inc	ecx		;set count to 1
;move cusror to start of line
csi_M_10:
  mov	bl,1
  call	rowcol_to_image
;compute number of characters to delete
  mov	eax,[vt_columns]
  mul	ecx
  mov	edx,eax		;edx=char delete count

  mov	edi,ebp		;delete start
  call	delete_char	;in=ecx,edi
  call	rowcol_to_image
  jmp	restart1


;       P   DCH       Delete the indicated # of characters on the current line.
;          ESC [ Pn P     Delete Character - Deletes Pn  characters starting
;                         at the cursor position. Characters to the right of
;                         the   deleted  character(s)  move  left.  Pn,   if
;                         omitted, is assumed to be 1.  Spaces  are inserted
;                         at the right as needed.
csi_P:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  or	ecx,ecx
  jnz	csi_P_10
  inc	ecx		;set count to 1
;find end of line
csi_P_10:
  mov	edi,ebp		;edi = start of delete
  push	ebx
  mov	bl,[vt_columns]
  call	rowcol_to_image
  mov	ebx,ebp		;get end of line
  add	ebx,byte 2	;adjust eol
  mov	edx,ecx		;move del count to edx
;input: edi = delete char start
;       edx = number to delete
;
  mov	esi,edi
  add	esi,byte 2		;build -from-
  mov	ecx,ebx			;get end of line
  sub	ecx,esi		;compute move count
csi_P_20:
  shr	ecx,1		;convert to word count
csi_P_30:
  push	ecx
  push	esi
  push	edi

  call	move_and_flag
;  rep	movsw
  mov	ah,[vt_image_write_color]
  mov	al,' '
  or	ah,80h
  mov	[edi],word ax

  pop	edi
  pop	esi
  pop	ecx

  dec	ecx
  or	ecx,ecx
  js	csi_P_40
;  jecxz	csi_P_40	;jmp if end of buffer
  dec	edx
  jnz	csi_P_30
csi_P_40:
  pop	ebx
  call	rowcol_to_image
  jmp	restart1


;       X   ECH       Erase the indicated # of characters on the current line.
csi_X:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
;erase from cursor
  mov	edi,ebp		;set starting point
  push	ebx
;build blank char
  mov	ah,[vt_image_write_color]
  or	ah,80h
  mov	al,' '	;space
;room to erase another
csi_X_loop:
  cmp	bl,[vt_columns]
  ja	csi_X_done
  stosw
  inc	bl
  loop	csi_X_loop
csi_X_done:
  pop	ebx
  jmp	restart1


;       a   HPR       Move cursor right the indicated # of columns.
csi_a:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
csi_a_loop:
  cmp	bl,[vt_columns]
  ja	csi_a_done
  inc	bl
  loop	csi_a_loop
csi_a_done:
  call	rowcol_to_image
  jmp	restart1

;       c   DA        Answer ESC [ ? 6 c: ‘I am a VT102’.
csi_c:
  push	ebx
  mov	ebx,[ptty_fd]
  mov	ecx,answer_to_send
  mov	edx,answer_to_send_len
  call	sys_write
  pop	ebx
  jmp	restart2
;-----
  [section .data]
answer_to_send: db 1bh,'[?6c'
answer_to_send_len equ $ - answer_to_send
  [section .text]


;       d   VPA       Move cursor to the indicated row, current column.
csi_d:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
csi_d_loop:
  cmp	bh,[vt_rows]
  ja	csi_d_done
  inc	bh
;  loop	csi_d_loop
csi_d_done:
  call	rowcol_to_image
  jmp	restart1

;       e   VPR       Move cursor down the indicated # of rows.
csi_e:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  mov	bl,1
csi_e_loop:
  cmp	bh,[vt_rows]
  ja	csi_e_done
  inc	bh
  loop	csi_e_loop
csi_e_done:
  call	rowcol_to_image
  jmp	restart1

;       f   HVP       Move cursor to the indicated row, column.
;          ESC [ Pl ; Pc f
;                         Same as "ESC [ Pl ; Pc H".
;          ESC [ f        Same as "ESC H" (home).
csi_f:
  jmp	csi_H

;       g   TBC       Without parameter: clear tab stop at the current position.
;                     ESC [ 3 g: delete all tab stops.
;          ESC [ g        Tabulation Clear  - Clears the tab, if any, at the
;                         column position occupied by the cursor.
;          ESC [ 0 g      Same as "ESC [ g".
;          ESC [ 3 g      Tabulation Clear - Clears all tabs.
csi_g:
  jmp	restart1

;       h   SM        Set Mode (see below).
;          ESC [ 2 h      Keyboard Action - The keyboard is locked. Pressing
;                         any key causes PC-VT to  click.  The  message "KBD
;                         LOCKED" is displayed  on  Status  Line  25  of the
;                         screen.
;          ESC [ 4 h      Insert-replacement - Insert mode is  selected. Any
;                         characters received cause the characters currently
;                         on the screen  from  the  cursor  position  to the
;                         right to be  moved  one position to the right. The
;                         newly  received character is then inserted in  the
;                         vacated space.
;
;          ESC [ 12 h     Send-Receive Mode  -  Sets  host  echo. Characters
;                         typed at the keyboard  are  not  locally displayed
;                         unless they are sent back by the host.
;
;          ESC [ 20 h     Linefeed /  New Line - Sets PC-VT to transmit both
;                         a carriage return and linefeed when the  ENTER key
;                         is pressed. Causes received linefeed, formfeed and
;                         vertical tab characters to move the cursor  to the
;                         left margin of the next line.
;
csi_h:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  cmp	cl,2
  je	csi_h_lock
  cmp	cl,4
  je	csi_h_insert
  cmp	cl,12
  je	csi_h_echo
  cmp	cl,20
  jne	csi_h_done
;linefeed control
  or	[csi_h_flag],byte 08h
  jmp	short csi_h_done
csi_h_lock:
  or	[csi_h_flag],byte 01h
  jmp	short csi_h_done
csi_h_insert:
  or	[csi_h_flag],byte 02h
  jmp	short csi_h_done
csi_h_echo:
  or	[csi_h_flag],byte 04h
csi_h_done:
  jmp	restart1	


;       l   RM        Reset Mode (see below).
;          ESC [ 2 l      Keyboard  Action - Unlocks the keyboard.  Pressing
;                         any key causes the character  to  be  sent  to the
;                         host. The "KBD LOCKED" message is cleared from the
;                         Status Line.
;
;          ESC [ 4 l      Insert-replacement - Selects replacement mode. Any
;                         characters  received  overwrite  any characters on
;                         the screen at the  cursor  location.  This  is the
;                         default setting.
;
;          ESC [ 12 l     Send-Receive  Mode  -  Sets local echo. Characters
;                         typed at the keyboard are locally displayed.
;
;          ESC [ 20 l     Linefeed / New Line  -  Resets  PC-VT  to transmit
;                         only   a carriage return when  the  ENTER  key  is
;                         pressed.  Causes  received  linefeed, formfeed and
;                         vertical tab characters to move cursor to the same
;                         column of  the  next  line.  This  is  the default
;                         setting.
;
csi_l:
  mov	esi,parm1
  push	ebx
  call	ascii_to_dword	;result in ecx
  pop	ebx
  cmp	cl,2
  je	csi_l_lock
  cmp	cl,4
  je	csi_l_insert
  cmp	cl,12
  je	csi_l_echo
  cmp	cl,20
  jne	csi_l_done
;linefeed control
  and	[csi_h_flag],byte ~08h
  jmp	short csi_l_done
csi_l_lock:
  and	[csi_h_flag],byte ~01h
  jmp	short csi_l_done
csi_l_insert:
  and	[csi_h_flag],byte ~02h
  jmp	short csi_l_done
csi_l_echo:
  and	[csi_h_flag],byte ~04h
csi_l_done:
  jmp	restart1	

;color   1bh,'[m'             default (same as [0m
;color   1bh,'[0m'        x c normal character attribute
;color   1bh,'[1;.]'      - c set color '.' for underline
;color   1bh,'[1m'        x c bold
;color   1bh,'[21m'       ? c normal intensity
;color   1bh,'[22m'       ? c normal intensity
;color   1bh,'[24m'       ? c underline off
;color   1bh,'[25m'       ? c blink off
;color   1bh,'[27m'       ? c reverse video off
;color   1bh,'[2;.]'      - c set color '.' for dim color
;color   1bh,'[2m'        - c half bright
;color   1bh,'[30m'       x c black foreground
;color   1bh,'[31m'       x c red foreground
;color   1bh,'[32m'       x c green foreground
;color   1bh,'[33m'       x c brown foreground
;color   1bh,'[34m'       x c blue foreground
;color   1bh,'[35m'       x c magenta foreground
;color   1bh,'[36m'       x c cyan foreground
;color   1bh,'[37m'       x c white foreground
;color   1bh,'[40m'       x c black background
;color   1bh,'[41m'       x c red backgound
;color   1bh,'[42m'       x c green background
;color   1bh,'[43m'       x c brown background
;color   1bh,'[44m'       x c blue background
;color   1bh,'[45m'       x c magenta background
;color   1bh,'[46m'       x c cyan background
;color   1bh,'[47m'       x c white background
;color   1bh,'[4m'        x c underscore
;color   1bh,'[5m'        x c blink
;color   1bh,'[7m'        x c inverse

csi_m:
  mov	esi,parm1
csi_m_loop:
  push	ebx
  push	esi
  call	ascii_to_dword	;result in ecx
  pop	esi
  pop	ebx
  cmp	ecx,49
  ja	restart1j	;ignore if out of range
  mov	eax,ecx		;save value
  shl	ecx,2
  add	ecx,csi_m_table
  jmp	[ecx]  

;------------
  [section .data]
csi_m_table:
  dd csi_m_00
  dd csi_m_01
  dd csi_m_02
  dd csi_m_03
  dd csi_m_04
  dd csi_m_05
  dd restart1		;ignore 06
  dd csi_m_07
  dd restart1		;ignore 08
  dd restart1		;ignore 09
  dd csi_m_10
  dd csi_m_11
  dd csi_m_12
  dd restart1		;ignore 13
  dd restart1		;ignore 14
  dd restart1		;ignore 15
  dd restart1		;ignore 16
  dd restart1		;ignore 17
  dd restart1		;ignore 18
  dd restart1		;ignore 19
  dd restart1		;ignore 20
  dd csi_m_21
  dd csi_m_22
  dd csi_m_23
  dd csi_m_24
  dd csi_m_25
  dd restart1		;ignore 26
  dd csi_m_27
  dd restart1		;ignore 28
  dd restart1		;ignore 29
  dd csi_m_30
  dd csi_m_31
  dd csi_m_32
  dd csi_m_33
  dd csi_m_34
  dd csi_m_35
  dd csi_m_36
  dd csi_m_37
  dd csi_m_38
  dd csi_m_39
  dd csi_m_40
  dd csi_m_41
  dd csi_m_42
  dd csi_m_43
  dd csi_m_44
  dd csi_m_45
  dd csi_m_46
  dd csi_m_47
  dd restart1		;ignore 48
  dd csi_m_49
;--------------
  [section .text]

;	case 0:	/* all attributes off */
;		default_attr(vc);
;		break;
csi_m_00:
  mov	al,[default_color]
  jmp	csi_m_tail

;	case 1:
;		vc->vc_intensity = 2;
;		break;
csi_m_01:
  or	[vt_image_write_color],byte 40h
  jmp	csi_m_tail2	

;	case 2:
;		vc->vc_intensity = 0;
;		break;
csi_m_02:
  and	[vt_image_write_color],byte ~40h
  jmp	csi_m_tail2	

;	case 3:
;		vc->vc_italic = 1;
;		break;
csi_m_03:
  jmp	csi_m_tail2	;ignore for now

;	case 4:
;		vc->vc_underline = 1;
;		break;
csi_m_04:
  jmp	csi_m_tail2	;ignore for now

;	case 5:
;		vc->vc_blink = 1;
;		break;
csi_m_05:
  jmp	csi_m_tail2	;ignore for now

;	case 7:
;		vc->vc_reverse = 1;
;		break;
csi_m_07:
  xor	[vt_image_write_color],byte 77q
  jmp	csi_m_tail2	

;	case 10: /* ANSI X3.64-1979 (SCO-ish?)
;		  * Select primary font, don't display
;		  * control chars if defined, don't set
;		  * bit 8 on output.
;		  */
;		vc->vc_translate = set_translate(vc->vc_charset == 0
;				? vc->vc_G0_charset
;				: vc->vc_G1_charset, vc);
;		vc->vc_disp_ctrl = 0;
;		vc->vc_toggle_meta = 0;
;		break;
csi_m_10:
  jmp	csi_m_tail2	;ignore for now

;	case 11: /* ANSI X3.64-1979 (SCO-ish?)
;		  * Select first alternate font, lets
;		  * chars < 32 be displayed as ROM chars.
;		  */
;		vc->vc_translate = set_translate(IBMPC_MAP, vc);
;		vc->vc_disp_ctrl = 1;
;		vc->vc_toggle_meta = 0;
;		break;
csi_m_11:
  jmp	csi_m_tail2	;ignore for now

;	case 12: /* ANSI X3.64-1979 (SCO-ish?)
;		  * Select second alternate font, toggle
;		  * high bit before displaying as ROM char.
;		  */
;		vc->vc_translate = set_translate(IBMPC_MAP, vc);
;		vc->vc_disp_ctrl = 1;
;		vc->vc_toggle_meta = 1;
;		break;
csi_m_12:
  jmp	csi_m_tail2	;ignore for now

;	case 21:
;	case 22:
;		vc->vc_intensity = 1;
;		break;
csi_m_21:
csi_m_22:
  or	[vt_image_write_color],byte 40h
  jmp	csi_m_tail2	
  
;	case 23:
;		vc->vc_italic = 0;
;		break;
csi_m_23:
  jmp	csi_m_tail2	;ignore for now

;	case 24:
;		vc->vc_underline = 0;
;		break;
csi_m_24:
  jmp	csi_m_tail2	;ignore for now

;	case 25:
;		vc->vc_blink = 0;
;		break;
csi_m_25:
  jmp	csi_m_tail2	;ignore for now

;	case 27:
;		vc->vc_reverse = 0;
;		break;
csi_m_27:
  xor	[vt_image_write_color],byte 77q
  jmp	csi_m_tail2	

;-- foreground color --  
csi_m_30:
csi_m_31:
csi_m_32:
csi_m_33:
csi_m_34:
csi_m_35:
csi_m_36:
csi_m_37:
  sub	al,30
  shl	al,3	;position foreground 
  mov	ah,[vt_image_write_color]
  and	ah,~70q	;remove foreground color
  or	al,ah
  jmp	csi_m_tail

;	case 38: /* ANSI X3.64-1979 (SCO-ish?)
;		  * Enables underscore, white foreground
;		  * with white underscore (Linux - use
;		  * default foreground).
;		  */
;		vc->vc_color = (vc->vc_def_color & 0x0f) | (vc->vc_color & 0xf0);
;		vc->vc_underline = 1;
;		break;
csi_m_38:
  mov	al,[vt_image_write_color]
  and	al,~70q	;remove foreground color
  or	al,grey_char
  jmp	csi_m_tail

;	case 39: /* ANSI X3.64-1979 (SCO-ish?)
;		  * Disable underline option.
;		  * Reset colour to default? It did this
;		  * before...
;		  */
;		vc->vc_color = (vc->vc_def_color & 0x0f) | (vc->vc_color & 0xf0);
;		vc->vc_underline = 0;
;		break;
csi_m_39:
;  mov	al,[default_color]
  jmp	csi_m_38	

;-- background colors --
csi_m_40:
csi_m_41:
csi_m_42:
csi_m_43:
csi_m_44:
csi_m_45:
csi_m_46:
csi_m_47:
;do background
  sub	al,40
  mov	ah,[vt_image_write_color]
  and	ah,~07h
  or	al,ah		;insert new background
  jmp	csi_m_tail


;	case 49:
;		vc->vc_color = (vc->vc_def_color & 0xf0) | (vc->vc_color & 0x0f);
;		break;
;default background color
csi_m_49:
  mov	cl,[default_color]
  and	cl,07h		;get default backgourn
  mov	al,[vt_image_write_color]
  and	al,~07h		;remove old background
  or	al,cl		;insert new background
  jmp	csi_m_tail

  

csi_m_tail:
  mov	[vt_image_write_color],al
csi_m_tail2:
  add	esi,5	;move to next parm
  cmp	esi,parm3
  ja	restart1j ;jmp if done
  cmp	[esi],byte 0	;end of parameters
  je	restart1j	;jmp if all parm's processed
  jmp	csi_m_loop

restart1j:
  jmp	restart1



;       n   DSR       Status reports 5=hardware 6=cursor
csi_n:
  mov	ecx,[parm1]
  cmp	cl,'5'		;hardware report?
  je	send_id
  cmp	cl,'6'
  jne	restart1j
;send cursor position as:
; esc,[xx;yyR
  push	ebx
  push	ecx
  push	edx
  push	edi
  mov	word [_trow],'00'
  mov	word [_tcolumn],'00'
  mov	edi,_tcolumn+2
  mov	al,bl		;get col
  push	ebx		;save row/col
  call	quick_ascii
  pop	ebx		;get row/col
  mov	al,bh		;get column
  mov	edi,_trow+2
  call	quick_ascii
;write it out
  mov	ebx,[ptty_fd]
  mov	ecx,vt_cursor
  mov	edx,10
  call	sys_write
  pop	edi
  pop	edx
  pop	ecx
  pop	ebx
  jmp	restart1
;----------------
  [section .data]
vt_cursor:
  db	1bh,'['
_trow:
  db	'000'		;row
  db	';'
_tcolumn:
  db	'000'		;column
  db	'R'
  
 [section .text]

;       q   DECLL     Set keyboard LEDs.
;                     ESC [ 0 q: clear all LEDs
;                     ESC [ 1 q: set Scroll Lock LED
;                     ESC [ 2 q: set Num Lock LED
;                     ESC [ 3 q: set Caps Lock LED
csi_q:
  jmp	restart1

;       r   DECSTBM   Set scrolling region; parameters are top and bottom row.
;         ESC [ Pt ; Pb r
;                        Sets  top  and  bottom  scrolling  margins  -  The
;                        scrolling region includes  display  lines starting
;                        at Pt and ending at Pb inclusive. Pt  and  Pb must
;                        be  between  1  and 24. Pb must be greater than or
;                        equal to Pt. If Pt is omitted, it  defaults  to 1.
;                        If Pb is omitted, it defaults to 24.
csi_r:
  jmp	restart1	;ignore for now

;       s   ?         Save cursor location.
csi_s:
  jmp	save_cursor

;       u   ?         Restore cursor location.
csi_u:
  jmp	restore_cursor


;-------------------------------------------------
;-------------------------------------------------
question_tbl:
;       h   SM        Set Mode (see below).
  db 'h',01h
  dd question_h

;       l   RM        Reset Mode (see below).
  db 'l',01h
  dd question_l

  db 0		;end of table

;-------------------------------------------------
;decoded so far:  esc[? and parameters
;          ESC [ ? 1 h    Cursor Key -  Sets  the  cursor  keys  to generate
;                         Application  Mode  functions.  For the VT102, this
;                         sequence is valid only in Application Keypad mode.
;                         For the VT100, it is valid anytime.
;
;          ESC [ ? 5 h    Screen - Sets the screen  to  reverse  video mode.
;                         The display attribute is set  to  black  on white.
;                         The entire display is flipped to  black  on white.
;                         All   characters received after this sequence  are
;                         displayed in black on white.
;
;          ESC [ ? 6 h    Origin - Sets the  home  position  to the top left
;                         margin of the scrolling region set by the "Set top
;                         and bottom margins" sequence "ESC [ Pt ; Pb r" .
;
;          ESC [ ? 7 h    Autowrap - Sets autowrap on. When the  cursor gets
;                         to the  right  margin  and  another  character  is
;                         received, a carriage  return and linefeed are sent
;                         to the display.
;
;          ESC [ ? 8 h    Autorepeat -  Sets  autorepeat  on.  This  is  the
;                         normal operation  of the IBM PC keyboard. If a key
;                         is held down, it  starts  to  repeatedly  send its
;                         code to the running program. This  is  the default
;                         setting for PC-VT.
;
;          ESC [ ? 18 h   Print Formfeed  On - PC-VT sends a formfeed to the
;                         selected  printer  at the conclusion  of  a  print
;                         screen operation. This is the default setting.
;
;          ESC [ ? 19 h   Print Extent -  The  full screen is printed on the
;                         selected printer  by  the  print  screen sequence.
;                         This is the default setting.
;
;          ESC [ ? 21 h   Receive File - Performs the same  function  as the
;                         CTRL-F3 key on  the keyboard. PC-VT private. Error
;
;          PC-VT v10.0                                 VT100 & 4014 Emulator
;                         code  is  available  with the "ESC  [  ?  1  0  n"
;                         sequence. See Appendix J.
;
;          ESC [ ? 22 h   Transmit File - Performs the same function  as the
;                         CTRL-F4 key on  the keyboard. PC-VT private. Error
;                         code  is  available  with the "ESC  [  ?  1  0  n"
;                         sequence. See Appendix J.
;
;          ESC [ ? 23 h   Special Sequence - This escape sequence causes PC-
;                         VT to send a carriage return to the host. This was
;                         implemented as a debug feature. PC-VT private. See
;                         Appendix J.
;
;          ESC [ ? 24 h   Set Buffer Load -  The  buffer  load  operation is
;                         started. PC-VT private. See Appendix J.
;
;          ESC [ ? 25 h   Change  Directory - Performs the same function  as
;                         the CTRL-F2 key on  the  keyboard.  PC-VT private.
;                         Error code is available  with  the "ESC [ ? 1 0 n"
;                         sequence. See Appendix J
;
;          ESC [ ? 26 h   Terminate PC-VT - Performs  the  same  function as
;                         the CTRL-F8 key on  the  keyboard.  PC-VT private.
;                         See Appendix J.
;
;          ESC [ ? 27 h   Start Up Command.com  - Performs the same function
;                         as the ALT-F key on the  keyboard.  PC-VT private.
;                         Error code is available  with  the "ESC [ ? 1 0 n"
;                         sequence. See Appendix J.
;
;          ESC [ ? 28 h   Select EVE  editor  keypad  support.  Performs the
;                         same function  as setting the EVE bit in the SETUP
;                         B frame. PC-VT private. See Appendix J.
;
;          ESC [ ? 29 h   Select VMS Operating System support.  Performs the
;                         same function  as setting the VMS bit in the SETUP
;                         B frame. PC-VT private. See Appendix J.
;
;          ESC [ ? 38 h   Switch to the 4014 emulator. This  sequence  is an
;                         extension based on the DEC VT240. The PC must have
;                         an IBM Color Graphics Adapter, a Hercules Graphics
;                         Card or  an Everex Edge Card or else this sequence
;                         is ignored.
;
;       ESC [ ? 1 h
;              DECCKM  (default  off):  When set, the cursor keys send an ESC O
;              prefix, rather than ESC [.
;       ESC [ ? 3 h
;              DECCOLM (default off = 80 columns): 80/132 col mode switch.  The
;              driver sources note that this alone does not suffice; some user-
;              mode utility such as resizecons(8) has to  change  the  hardware
;              registers on the console video card.
;       ESC [ ? 5 h
;              DECSCNM (default off): Set reverse-video mode.
;       ESC [ ? 6 h
;              DECOM  (default off): When set, cursor addressing is relative to
;              the upper left corner of the scrolling region.
;       ESC [ ? 7 h
;              DECAWM (default on): Set autowrap on.  In this mode,  a  graphic
;              character  emitted  after column 80 (or column 132 of DECCOLM is
;              on) forces a wrap to the beginning of the following line  first.
;       ESC [ ? 8 h
;              DECARM (default on): Set keyboard autorepreat on.
;       ESC [ ? 9 h
;              X10  Mouse  Reporting (default off): Set reporting mode to 1 (or
;              reset to 0) — see below.
;       ESC [ ? 25 h
;              DECTECM (default on): Make cursor visible.
;       ESC [ ? 1000 h
;              X11 Mouse Reporting (default off): Set reporting mode to  2  (or
;              reset to 0) — see below.
;
; if ending char = 'h' then set
; if ending char = 'l' then reset
;
question_h:
question_l:
question_seq:
  mov	eax,[parm1]

  cmp	ah,'2'		;is this mouse2
  jne	ESquestion_2	;jmp if not 2x
  mov	al,0		;force mouse
  jmp	short ESquestion_3
ESquestion_2:
  test	eax,0f0000000h	;check for [?1000
  jz	ESquestion_3	;jmp if not 1000
  mov	al,9		;force 9

ESquestion_3:
  cmp	al,'9'
  ja	restart1	;ignore if error
  and	eax,byte 0fh	;remove top junk
  shl	eax,2	;convert to dword index
  add	eax,getpars_table
  cmp	[ecx],byte 'h'
  je	ESqueston_jmp
  add	eax,4*10	;select reset entries
ESqueston_jmp:
  mov	eax,[eax]
  jmp	eax
;-------------------------
  [section .data]
getpars_table:
  dd mouse2	;0 [?25
  dd restart1	;1
  dd DECCKM	;2 [?1
  dd DECCOLM	;3 [?3
  dd restart1   ;4
  dd DECTECM	;5 [?5
  dd DECOM	;6
  dd DECAWM	;7
  dd DECARM	;8
  dd _mouse1	;9 [?1000

  dd _mouse2	;0
  dd _restart1  ;1
  dd _DECCKM	;2
  dd _DECCOLM	;3
  dd _restart1   ;4
  dd _DECTECM	;5
  dd _DECOM	;6
  dd _DECAWM	;7
  dd _DECARM	;8
  dd _mouse1	;9

  [section .text]
;-------------------------------------------------

;       ESC [ ? 1 h
;              DECCKM  (default  off):  When set, the cursor keys send an ESC O
;              prefix, rather than ESC [.
DECCKM:
  jmp	restart1

;       ESC [ ? 3 h
;              DECCOLM (default off = 80 columns): 80/132 col mode switch.  The
;              driver sources note that this alone does not suffice; some user-
;              mode utility such as resizecons(8) has to  change  the  hardware
;              registers on the console video card.
DECCOLM:
  jmp	restart1

;       ESC [ ? 5 h
;              DECSCNM (default off): Set reverse-video mode.
DECSCNM:
  jmp	restart1

;       ESC [ ? 6 h
;              DECOM  (default off): When set, cursor addressing is relative to
;              the upper left corner of the scrolling region.
DECOM:
  jmp	restart1

;       ESC [ ? 7 h
;              DECAWM (default on): Set autowrap on.  In this mode,  a  graphic
;              character  emitted  after column 80 (or column 132 of DECCOLM is
;              on) forces a wrap to the beginning of the following line  first.
DECAWM:
  mov	[wrap_flag],byte 1	;enable auto wrap
  jmp	restart1

;       ESC [ ? 8 h
;              DECARM (default on): Set keyboard autorepreat on.
DECARM:
  jmp	restart1

;       ESC [ ? 9 h
;              X10  Mouse  Reporting (default off): Set reporting mode to 1 (or
;              reset to 0) — see below.
mouse1:
  mov	[mouse_flag],byte 1	;enable mouse
  jmp	restart1

;       ESC [ ? 25 h
;              DECTECM (default on): Make cursor visible.
DECTECM:
  jmp	restart1

;       ESC [ ? 1000 h
mouse2:
  mov	[mouse_flag],byte 1	;enable mouse
  jmp	restart1

;-- reset versions of above --

_mouse2:	;0
  mov	[mouse_flag],byte 0	;disable mouse
  jmp	restart1
_DECCKM:	;2
  jmp	restart1
_DECCOLM:	;3
  jmp	restart1
_restart1:	;4
  jmp	restart1
_DECTECM:	;5
  jmp	restart1
_DECOM:		;6
  jmp	restart1
_DECAWM:	;7
  mov	[wrap_flag],byte 0	;disable auto wrap
  jmp	restart1
_DECARM:	;8
  jmp	restart1
_mouse1:	;9
  mov	[mouse_flag],byte 0	;disable mouse
  jmp	restart1

;-------------------------------------------------
  [section .data]
;       ESC %              Start sequence selecting character set
;       ESC % @               Select default (ISO 646 / ISO 8859-1)
;       ESC % G               Select UTF-8
;       ESC % 8               Select UTF-8 (obsolete)
percent_table:
  db '@',0
  dd sel_default

  db 'G',0
  dd sel_utf

  db '8',0
  dd sel_old

  db 0
  [section .text]
;-------------------------------------------------
sel_default:
  mov	[char_set],byte 12h
  jmp	restart3
sel_utf:
  mov	[char_set],byte 14h
  jmp	restart3
sel_old:
  mov	[char_set],byte 2
  jmp	restart3
;-------------------------------------------------
  [section .data]
;       ESC (              Start sequence defining G0 character set
;       ESC ( B               Select default (ISO 8859-1 mapping)
;       ESC ( 0               Select VT100 graphics mapping
;       ESC ( U               Select null mapping - straight to character ROM
;       ESC ( K               Select user mapping - the map that is loaded by
;                             the utility mapscrn(8).
pren1_table:
  db 'B',0
  dd sel_iso

  db "0",0
  dd sel_vt

  db 'U',0
  dd sel_null

  db 'K',0
  dd sel_user

  db 0
  [section .text]
;-------------------------------------------------
sel_iso:
  mov	al,2
  jmp	short sel_tail
sel_vt:
  mov	al,8
  jmp	short sel_tail
sel_null:
  mov	al,2
  jmp	short sel_tail
sel_user:
  mov	al,4

sel_tail:
  mov	[G0_char_set],al
  mov	[char_set],al
  jmp	restart3
;-------------------------------------------------
  [section .data]
;       ESC )              Start sequence defining G1
;                          (followed by one of B, 0, U, K, as above).
;       ESC ( B               Select default (ISO 8859-1 mapping)
;       ESC ( 0               Select VT100 graphics mapping
;       ESC ( U               Select null mapping - straight to character ROM
;       ESC ( K               Select user mapping - the map that is loaded by
;                             the utility mapscrn(8).
pren2_table:
  db 'B',0
  dd unsel_iso

  db "0",0
  dd unsel_vt

  db 'U',0
  dd unsel_null

  db 'K',0
  dd unsel_user

  db 0

  [section .text]
;-------------------------------------------------
unsel_iso:
  mov	al,2
  jmp	short unsel_tail
unsel_vt:
  mov	al,8
  jmp	short unsel_tail
unsel_null:
  mov	al,2
  jmp	short unsel_tail
unsel_user:
  mov	al,4

unsel_tail:
  mov	[G1_char_set],al
  mov	[char_set],al
  jmp	restart3
;-------------------------------------------------
  [section .data]
;       ESC ]     OSC      ESC ] P nrrggbb: set palette, with parameter  given
;                          in  7 hexadecimal  digits after the final P .  Here n
;                          is the color  (0-15),  and  rrggbb  indicates  the
;                          red/green/blue  values  (0-255).
;       ESC  ] R: reset palette
xterm_table:
  db 'P',0
  dd  color1

  db 'R',0
  dd  color2

  db '0',0
  dd  comment

  db 0		;end of table

  [section .text]
;-------------------------------------------------
color1:
  add	ecx,byte 7	;bump char ptr
  sub	edx,byte 7	;dec char's remaining
  cmp	edx,byte 0
  jae	color2		;jmp if count ok
  xor	edx,edx		;set to zero    	
color2:
  jmp	restart3	;ignore

comment:
  pop	edx
  pop	ecx
comment_lp:
  cmp	[ecx],byte 07	;bell ?
  je	comment_exit
  inc	ecx
  dec	edx
  jnz	comment_lp
comment_exit:
  jmp	vt_loop
  
;-------------------------------------------------
;input: edi = delete char start
;       edx = number to delete
;
delete_char:
  mov	esi,edi
  add	esi,byte 2		;build -from-
  mov	ecx,[vt_image_end]
  sub	ecx,esi		;compute move count
;check for delete all
;  mov	eax,edi
;  add	eax,ecx		;compute final edi
;  sub	eax,[vt_image_end]
;  jbe	dc_ok
;  add	ecx,eax		;adjust ecx
dc_ok:
  shr	ecx,1		;convert to word count
dc_loop:
  push	ecx
  push	esi
  push	edi
  call	move_and_flag
;  rep	movsw
  mov	ah,[vt_image_write_color]
  or	ah,80h
  mov	al,' '		;blank
  mov	[edi],word ax

  pop	edi
  pop	esi
  pop	ecx

  dec	ecx
  or	ecx,ecx
  js	dc_done
;  jecxz	dc_done		;jmp if end of buffer
  dec	edx
  jnz	dc_loop
dc_done:
  ret
;-------------------------------------------------
;move_and_flag - move data and set flags
; input esi,edi,ecx for rep movsw
;
move_and_flag:
  lodsw
  or	ax,8000h
  stosw
  loop	move_and_flag
  ret  
;-------------------------------------------------
;  blk_word_hole - insert words into block
; INPUTS
;    esi = insert point
;    ecx = number of words to insert
;    eax = fill words
; OUTPUT
;    ebp = adjusted block end ptr
; NOTES
;   file:
; * ---------------------------------------------
;*******

blk_word_hole:
  push	eax		;save fill char
;check insert size
  mov	eax,[vt_image_end]
  sub	eax,esi		;compute buffer size past insert
  shr	eax,1		;size in words
  cmp	ecx,eax		;check if insert bigger than buffer
  jbe	bwh_setup	;jmp if no overflow
  mov	edi,esi
  mov	ecx,[vt_image_end]
  sub	ecx,edi		;compute move bytes
  shr	ecx,1
  jmp	short bwh_fill2	;jmp if fill only
;compute -to- ptr
bwh_setup:
  mov	edi,esi
  add	edi,ecx
  add	edi,ecx		;compute destination -to-
;check if move will overflow buffer
  mov	eax,[vt_image_end]
  sub	eax,edi
  shr	eax,1
  cmp	eax,ecx		;overflow?
  ja	bwh_ok
  mov	ecx,eax
bwh_ok:
  push	ecx
  call	move_and_flag
;  rep	movsw		;move data
  pop	ecx		;get move count
;setup for fill
  std
  mov	edi,esi
bwh_fill:
  inc	ecx
bwh_fill2:
  pop	eax		;get fill char
  rep	stosw		;clear hole
  cld
  ret
    
;-------------------------------------------------
; insert into line, move existing char's right
;input:  ecx = insert count
;         ax = insert char & color
;        bh=row bl=column
;        ebp=stuff ptr ?
;        [vt_rows]
;        [vt_columns] 
line_insert:
li_loop:
  cmp	bl,[vt_columns]	;at end?
  ja	li_exit		;exit if at end
  push	ecx		;save move count

  mov	edx,[vt_columns]
  sub	dl,bl		;compute move count

  mov	ecx,edx		;move count
  mov	edi,ebp		;current position
  add	edi,ecx
  add	edi,ecx		;compute destination

  mov	esi,edi
  sub	esi,2		;from ptr
  std
  call	move_and_flag
;  rep	movsw		;make room for one char
  cld
  mov	[ebp],ax	;insert char
  add	ebp,2		;move ptr
  inc	bl		;move column

  pop	ecx
  dec	ecx
  jnz	li_loop
li_exit:
  ret
;------------------

;struc termio_struc
;.c_iflag: resd 1
;.c_oflag: resd 1
;.c_cflag: resd 1
;.c_lflag: resd 1
;.c_line: resb 1
;.c_cc: resb 19
;endstruc
;termio_struc_size:

;check_termios_wrap:
;  push	ecx
;  push	edx
;  mov	ebx,[ptty_fd]	;code for stdin
;  mov	ecx,5401h
;  mov	edx,termios_buf
;  mov eax,54
;  int	byte 80h
;  test	[edx+termios_struc.c_lflag],byte 2	;ICANON?
;  jz	ctw_exit	;jmp if in raw mode
;  or	[wrap_flag],byte 1
;ctw_exit:
;  pop	edx
;  pop	ecx
;  ret
;---------------------------------------

struc termios_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termios_struc_size:


  [section .data]
termios_buf:	times termios_struc_size db 0

current_table	dd 0
current_flag	dd 0	; 80=table active  01=command decoded     

;default_color	    db grey_char + black_back
;default_color	    db black_char + grey_back
pad_flag	    db 0 ;0=app 1=numeric
scroll_lock_flag    db 0 ;0=unset 1=set
num_lock_flag	    db 0 ;0=unset 1=set
cap_lock_flag	    db 0 ;0=unset 1=set
scroll_end_line	    db 0 ;start of scroll region
dec_mode	    db 0 ;0=nomral
mouse_flag	    db 0 ;0=mouse off
hide_cursor	    db 0 ;0=visible 1=hidden
esc_paren_mapping   db 0 ;bit flag 0=B,0,U,K unsel
wrap_flag	    db 1 ;0=no wrap 1=wrap
saved_row_col	    dd 0101h  ;saved col,row
csi_h_flag	    db 0 ;01=lock 02=insert 04=echo 08=linefeed

; (A = 1  uk -> G0
; (B = 2  us -> G0
; (K = 4  ?  -> G0
; (0 = 8  draw -> G0 (redefine 60h - 7eh
; (A = 1  uk -> G1
; (B = 2  us -> G1
; (K = 4  ?  -> G1
; (0 = 8  draw -> G1 (redefine 60h - 7eh
; esc F = 2 -> char_set (graphic us)
; esc G = 2  -> char_set
; esc %@ = 12h -> char_set (8259 sel) 
; esc %G = 14h -> char_set (utf-8 enable)
; 0eh = move G1 -> char_set
; 0Fh = move G0 -> char_set
G0_char_set:	    db 0
G1_char_set:        db 0
char_set:	    db 0	;selected G0/G1 is placed here

;The cursor position is same as stuff point. 
 global vt_stuff_col,vt_stuff_row
vt_stuff_col	    db 1
vt_stuff_row	    db 1
		    dw 0 ;filler for row/col


  [section .text]

