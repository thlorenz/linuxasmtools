
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]
;%define DEBUG

  extern read_stdin
  extern mouse_enable
  extern kbuf  
  extern crt_line
  extern key_decode1
  extern crt_set_color

struc popup
.mtext resd 1	;menu test with embedded colors
.mcols  resb 1	;total columns
.mrows  resb 1	;total rows
.mcol	resb 1	;starting col
.mrow	resb 1	;starting row
.mcolor1 resd 1 ;normal color
.mcolor2 resd 1 ;button color
.mcolor3 resd 1 ;select bar color
endstruc

;----------------------
;>1 widget
;   popup_menu - popup menu box and wait for key/click
; INPUTS
;    ebp = ptr to popup menu definition, as follows:
;
;        dd menu text ending with zero byte
;        db columns in window
;        db rows in window
;        db starting col
;        db starting row
;        dd normal color (color 1)
;        dd button color (color 2)
;        dd select bar button color (color 3)
;
;     menu text consists of lines ending with 0ah, the last
;     line ends with 0.  Lines can have embedded color codes
;     using byte values of 1,2,3.
;     The box is separated from rest of display by its color,
;     the "normal color" is used to form box"
;
; OUTPUT
;    eax = zero if no selection was made
;        = ptr to start of selected row
;    ecx = selection number times 4, if selection made,
;          first selection number is 0, next is 4, etc.
;
; NOTES
;    file popup_menu.asm
;    1. menu text can have one blank line at top.
;    2. menu items can have blank lines between entries
;    3. normal color is asserted at start of each new line
;        
;<
;  * ---------------------------------------------------
;*******
  global popup_menu
popup_menu:
  cld
  call	mouse_enable
;setup intitial row and line number
  mov	[menu_select_line],byte 0	;
  mov	eax,[ebp + popup.mtext]
pm_set_lp:
  cmp	[eax],byte 0ah			;blank line here?
  ja	pm_set				;jmp if first valid line found
  je	pm_adjust1			;jmp if blank line at select ptr
;first char must be color code, keep checking for blank line
  cmp	[eax+1],byte 0ah
  ja	pm_set				;jmp if first line valid
  add	eax,2				;move to next line
  jmp	short pm_set
pm_adjust1:
  inc	eax
pm_set:
  mov	[menu_select_ptr],eax
;build select color list
  mov	eax,[ebp+popup.mcolor1]		;get normal color
  mov	[select_colors],eax
  mov	eax,[ebp+popup.mcolor3]		;get select button color
  mov	[select_colors+4],eax
pm_lp:
  call	display_window
; get keyboard input
fb_ignore:
  call	read_stdin
  cmp	byte [kbuf],-1		;check if mouse
  je	fb_mouse
;decode key
  mov	esi,key_decode_table3
  call	key_decode1
  jmp	short fb_cont
;decode mouse click
fb_mouse:
  mov	bl,[kbuf+2]		;get mouse column
  mov	bh,[kbuf+3]		;get mouse row
  call	mouse_decode
  or	eax,eax
  jz	pm_lp			;ignore unknown clicks
  jmp	short fb_exit1
fb_cont:
  push	ebp
  call	eax
  pop	ebp
  cmp	al,-1
  je	pm_lp
  or	eax,eax
  jz	fb_exit2
fb_exit:
  mov	eax,[menu_select_ptr]
  xor	ecx,ecx
  mov	cl,[menu_select_line]
fb_exit1:
  shl	ecx,2
fb_exit2:
  ret
;---------------------------------
;INPUTS
; [ebp+popup]			;struc
; menu_select_line: db 0	;current select line index 0,1,2
; menu_select_ptr:  dd 0	;pointer to selected line
fb_up:
  mov	esi,[menu_select_ptr]
fb_up1:
  cmp	esi,[ebp + popup.mtext]
  je	fb_up_exit		;exit if at top
  call	prev_line		; output: esi = ptr to next line
;                                 carry = at top now
;                                 no-carry = not at top
  call	is_blank		;blank line
  je	fb_up1
fb_up_success:
  mov	[menu_select_ptr],esi
  dec	byte [menu_select_line]

fb_up_exit:
  mov	al,-1   
  ret

;-----------------------
;INPUTS
; [ebp+popup]			;struc
; menu_select_line: db 0	;current select line index 0,1,2
; menu_select_ptr:  dd 0	;pointer to selected line
fb_down:
  mov	esi,[menu_select_ptr]
fb_down1:
  cmp	[esi],byte 0
  je	fb_down_exit		;exit if can't go down
  call	next_line               ; output: esi = ptr to next line
;                                 carry = at bottom 
  jc	fb_down_exit		;exit if cant go down
  call	is_blank
  je	fb_down1		;jmp if blank line
fb_down_success:
  mov	[menu_select_ptr],esi
  inc	byte [menu_select_line]
fb_down_exit:
  mov	al,-1
  ret

;-----------------------
enter_key:
  mov	eax,[menu_select_ptr]
  ret
;-----------------------
quit:
  xor	eax,eax
  mov	[menu_select_ptr],eax
  ret
;-----------------------
unknown_key:
  mov	al,-1
  ret
;----------------------------------------------
; input: esi = ptr to line start
; output: esi = ptr to next line
;         carry = at top now
;        no-carry = not at top
;
prev_line:
  cmp	esi,[ebp + popup.mtext]	;check if at top
  jbe	pl_top
  dec	esi
  cmp	esi,[ebp + popup.mtext]	;check if at top
  je	pl_top
  cmp	byte [esi -1],0ah
  jne	prev_line
  clc
  jmp	short pl_exit
pl_top:
  stc
pl_exit:
  ret
  
;----------------------------------------------
; input: esi = ptr to current line start
; output: esi = ptr to next line
;         carry = at bottom 
next_line:
  cmp	[esi],byte 0
  je	nl_end		;jmp if at end
  lodsb
  cmp	al,0ah
  jne	next_line
  clc
  jmp	short nl_exit
nl_end:
  stc	
nl_exit:
  ret

;----------------------------------------------
; input: esi=text ptr
; output: equal flag set if blank line (je)
is_blank:
  push	esi
is_blank_lp:
  lodsb
  or	al,al
  je	is_blank_exit	;exit if end of line
  cmp	al,0ah
  je	is_blank_exit	;jmp if blank line
  cmp	al,20h		;non text char
  jbe	is_blank_lp	;jmp if non-text char
is_blank_exit:
  pop	esi
  ret

;----------------------------------------------
;find text at mouse click
;
; input; bl = column
;        bh=row 1 based
;        ebp = popup struc ptr
; output: eax = start of line where click occured
;               else zero if click elsewhere
;
mouse_decode:
  cmp	bl,[ebp+popup.mcol]	;check if inside window
  jb	mk_fail			;exit if left of window
;  add	bl,[ebp+popup.mcols]	;compute window end column
;  cmp	bl,[ebp+popup.mcol]
;  ja	mk_fail			;exit if right of window
  cmp	bh,[ebp+popup.mrow]
  jb	mk_fail			;exit if above first row
  
  mov	esi,[ebp + popup.mtext]
  xor	ecx,ecx
  dec	ecx			;setup for loop
  inc	bh			;adjust row
md_loop1:
  call	is_blank
  je	skip_index
  inc	ecx
skip_index:
  dec	bh			;decrement row
  cmp	bh,[ebp+popup.mrow]	;check if at click row
  jnz	md_loop2		;jmp if still looking
  call	is_blank
  je	mk_fail			;jmp if blank line
  jmp	short mk_got		;jmp if valid line
md_loop2:
  lodsb
  cmp	al,0ah
  je	md_loop1		;jmp if end of line
  or	al,al
  jne	md_loop2		;loop if not end of text
mk_fail:
  xor	eax,eax
  jmp	short mk_end2
mk_got:
  mov	eax,esi
;failure, click not found on valid entry
mk_end2:
  ret  
;----------------------------------------------

;--------------------------------------------------------------
; display_window
;  input: ebp = struc ptr
;         [menu_select_ptr]

display_window:
  mov	ch,[ebp + popup.mrow]	;starting row
  mov	dl,[ebp + popup.mcols]	;max line length
  mov	esi,[ebp + popup.mtext]	;display data ptr
  mov	dh,[ebp + popup.mrows]	;max rows to display
dw_lp:
  lea	ebx,[ebp+popup.mcolor1]	;color list
  mov	cl,[ebp + popup.mcol]	;starting col
  push	ebx
  push	ecx
  push	edx
  cmp	esi,[menu_select_ptr]	;is this select line
  jne	dw_show			;jmp if not select ptr
  mov	ebx,select_colors	;adjust colors for select
dw_show:
  xor	edi,edi			;scroll = 0 
  call	crt_line
  mov	eax,[ebp+popup.mcolor1]
  call	crt_set_color		;restore normal color
  pop	edx
  pop	ecx
  pop	ebx
  cmp	byte [esi-1],0ah	;did we reach end of line?
  je	dw_tail
  cmp	byte [esi],0ah		;are we at end of data
  jb	dw_tail
;scan to end of line
dw_scan:
  lodsb
  cmp	al,0ah			;scan to end of line
  ja	dw_scan
dw_tail:
  inc	ch		;move to next row
  dec	dh
  jz	dw_end		;jmp if end of window
  cmp	byte [esi],0	;check if at end of data
  jne	dw_lp		;jmp if another line available
  mov	esi,dummy_line
  jmp	short dw_lp
dw_end:
  ret

;===========================================================
  [section .data]

dummy_line:
  db	0ah,0

key_decode_table3:
  dd	unknown_key	;alpha key

  db 1bh,5bh,41h,0		;15 pad_up
  dd fb_up

  db 1bh,4fh,41h,0		;15 pad_up
  dd fb_up

  db 1bh,4fh,78h,0		;15 pad_up
  dd fb_up

  db 1bh,5bh,42h,0		;20 pad_down
  dd fb_down

  db 1bh,4fh,42h,0		;20 pad_down
  dd fb_down

  db 1bh,4fh,72h,0		;20 pad_down
  dd fb_down


  db 1bh,0			;ESC
  dd quit

  db 0dh,0			;enter key
  dd enter_key

  db 0ah,0			;enter key
  dd enter_key

  db 0		;enc of table
  dd unknown_key ;unknown key trap
  
;----------------------------------------------

menu_select_line: db 0	;current select line index 0,1,2
menu_select_ptr:  dd 0	;pointer to selected line

select_colors:
  dd 0	;normal line color (color 1)
  dd 0	;select bar button color

  [section .text]
;---------------------------------------------------------------

%ifdef DEBUG
  global main,_start
main:
_start:
  nop
  mov	ebp,test_data
  call	popup_menu

  mov	eax,1
  int	byte 80h
;--------
  [section .data]
test_data:
  dd	menu_text
  db	30		;columns
  db	15		;rows
  db	3		;starting col
  db	5		;starting row
  dd	30003634h	;normal color
  dd	30003436h	;button color
  dd	31003037h	;select bar color

menu_text:
terminal_menu: db 1,0ah
 db 1
 db ' ',2,'terminal intro',1,0ah,0ah
 db ' ',2,'ascii characters',1,' character encoding',0ah,0ah
 db ' ',2,'ascii controls',1,' vt sequences',0ah,0ah
 db ' ',2,'termios',1,' terminal setup',0ah,0ah
 db 0ah,0ah
 db 0ah,0ah
 db ' ',2,'-back- (ESC)',1,0ah
 db 0

%endif

  [section .text]

