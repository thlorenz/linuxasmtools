
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
  extern read_window_size
  extern crt_rows,crt_columns


  [section .text]

%include "select_list_struc.inc"
;----------------------------------------------------------------------------------------
;>1 widget
; select_list_setup - setup the select list database
;
; This function is called by select_list_engine to fill
; in defaults.  It is also called by high level routines
; to build structures and calcuate values.  It is mostly
; for library use, but may be useful.
;        
;   INPUTS
;   ------
;
;          ebp = pointer to button definition structures.
;
;          Register -al- has code describing action needed.
;
;           al=1  build structures from text lists in buffer.
;              edi=ptr to top of work area followed by text strings.
;                  work area must be 20+10*(button count) in size.
;              esi=ptr to text strings at end of work area.
;
;              note: text strings can be multi line (using 0ah) and
;                    the last line is terminated by  zero byte.
;
;           al=2  fill in defaults for button structures
;              [ptr2group_ptrs] - has ptr to group ptrs
;              [ptrs2button_defs] - has pointer to list of pointers
;                                   for each button group
;              also set [max_text] - longest button text line size
;                       [max_rows] - max number of button text rows
;                       [max_groups] - number of button groups (columns)
;                       [mrows]  - max number of buttons in a group
;                       [crt_rows] - screen size from kernel call
;                       [crt_columns] - screen size from kernel call
;              
;           al=3  calculate button separation values from known
;                 -win_columns,button_size_columns
;                 -win_rows,button_size_rows
;                 calcuated values will be stored in structure.
;                 sl.button_separation_columns, sl.button_separation_rows
;
;                 note: calculation is for single group window only.
;    
;           al=4  calculate win_rows, win_columns from button_sizes and
;                 separation_sizes.  Calculated values may exceed the
;                 screen size.
;                 calcuated values are stored at: s.win_columns and
;                 sl.win_rows
;
;                 note: calculation is for single group window only.
;
;   OUTPUT
;   ------
;
;           Input option al=1 returns ebp set to start of structures.
;
;           Input option al=2 returns information set in global varialbes
;           as follows:
;
;              byte [crt_rows] - set by calling read_window_size
;              byte [crt_columns] - set by calling read_window_size
;              byte [max_text] - size of longest button text line
;              byte [max_rows] - row count for button with most rows
;              byte [max_groups] - number of button columns (groups)
;
;<
;-------------------------------------------------------------------------             
;-------------------------------------------------------------------------
; inputs: ebp = ptr to  callers structures
;         [ptr2group_ptrs] - ptrs to the button sets
;         [ptrs2button_defs] - sets of pointers for each group (button column)
; output: structures filled out
;    initialized: topdisplay_button > 0 (number of button at top of display)
;                 topdisplay_button_state > 0
;                 topvirtualrow > 0     (current top row virtual number)
;                 edgevirutalcolumn > 0 (scroll)
;
  global select_list_setup                 
select_list_setup:
  cmp	al,1
  je	sls_build_structures
  cmp	al,2
  jne	sls_01
  jmp	sls_set_defaults
sls_01:
  cmp	al,3
  jne	sls_02
  jmp	sls_set_separation
sls_02:
  jmp	sls_set_win_size
;------------------------------------------------
;           al=1  build structures from text lists in buffer.
;              edi=ptr to top of work area followed by text strings.
;              esi=ptr to text strings at end of work area.
;
;              note: text strings can be multi line (using 0ah) and
;                    the last line is terminated by  zero byte.
;
;           ouptut = ebp set to top of structures
;                    button groups set to 1 and total groups set to 1
;
sls_build_structures:
  mov	ebp,edi		;top of work area = top of structures
;
; clear the sl struc area
;
  xor	eax,eax
  mov	ecx,sl_struc_size
  rep	stosb

  mov	byte [ebp+sl.button_groups],1
  lea	edi,[ebp+sl.button_separation_rows+1]   ;point at first button definition
;
; loop here for each button, esi=text ptr  edi=work area ptr
;
sbs_lp2:
;
; clear current button area
;
  push	edi
  xor	eax,eax
  mov	ecx,button_struc_size
  rep	stosb
  pop	edi

  mov	byte [edi+button.button_group],1	;put button in  group 1
  lea	edi,[edi+button.button_text]		;move to text field
;
; move text for this button
;
sbs_lp3:
  lodsb
  stosb
  cmp	al,0
  jne	sbs_lp3
;
; check if all text moved, last text string has 0,0 at end
;
  cmp	byte [esi],0
  jne	sbs_lp2				;jmp if more text
  mov	byte [edi],0			;terminate the structures
  ret
;------------------------------------------------
;           al=2  fill in defaults for button structures
;              ebp= ptr to top of structures
;              [ptr2group_ptrs] - has ptr to group ptrs
;              [ptrs2button_defs] - has pointer to list of pointers
;                                   for each button group
;
sls_set_defaults:
;
  mov	byte [mrows],1
  cmp	byte [ebp+sl.box_color],0
  jne	sls_05					;jmp if color provided
  mov	dword [ebp+sl.box_color],30003737h
sls_05:
  cmp	byte [ebp+sl.win_color],0
  jne	sls_10
  mov	dword [ebp+sl.win_color],30003036h
;
; scan button to insert color info. and get counts of max_text,max_rows, max_groups
;
sls_10:
  lea	esi,[ebp+sl.button_separation_rows+1]   ;point at first button definition
  xor	ebx,ebx					;bl=max_rows bh=max_groups
  xor	ecx,ecx					;ecx=max_text
sls_lp1:
  mov	ah,1					;max rows per button
  cmp	byte [esi+button.button_color],0
  jne	sls_12					;jmp if color provided
  mov	dword [esi+button.button_color],30003734h
sls_12:
  cmp	byte [esi+button.button_selected_color],0
  jne	sls_14					;jmp if color provided
  mov	dword [esi+button.button_selected_color],31003334h
sls_14:
;
; count all buttons in first column (group 1)
;
  cmp	byte [esi+button.button_group],1	;is this group 1
  jne	sls_16					;jmp if not group1
  inc	bl					;count button (max_rows)
sls_16:
  mov	bh,[esi+button.button_group]		;assume last group = total groups (columns)
;
; now scan the text to find max size
;
  lea	esi,[esi+button.button_text]		;point at text field
sls_lpx:
  mov	ch,-1
sls_lp2:
  inc	ch
  lodsb
  or	al,al
  jz	sls_18					;jmp if end of text
  cmp	al,0ah
  jne	sls_lp2					;continue counting button text
  inc	ah          				;set multirow flag 
  cmp	ch,cl					;is new count bigger
  jb	sls_lpx				;jmp if earlier count bigger
  mov	cl,ch				;save new biggest count (text size)
  jmp	short sls_lpx
;
; we have found zero at end of text line
;
sls_18:
  cmp	ch,cl					;is new count bigger
  jb	sls_19				;jmp if earlier count bigger
  mov	cl,ch				;save new biggest count (text size)
;
sls_19:
  cmp	ah,[mrows]			;check if rows of text in this button bigger
  jbe	sls_20
  mov	[mrows],ah
;
sls_20:
  cmp	byte [esi],0				;end of buttons?
  jne	sls_lp1
;
; save values from button scan
;
  mov	[max_text],cl
  mov	[max_rows],bl
  mov	[max_groups],bh
  call	read_window_size
  ret
;---------------
  [section .data]
  global max_text
max_text:	db	0	;largest button text line size
  global max_rows
max_rows:	db	0	;number of button in a column
  global max_groups
max_groups:	db	0	;number of button columns
  global mrows
mrows:		db	0	;set if button has more than one row
  [section .text]
;------------------------------------------------
;           al=3  calculate button separation values from known
;                 -win_columns,button_size_columns
;                 -win_rows,button_size_rows
;                 calcuated values will be stored in structure.
;                 sl.button_separation_columns, sl.button_separation_rows
;  note: this only works for single group windows.
;    
sls_set_separation:
;
; we have a button_size, window_size, but no separation size, calcuate it
;
  mov	al,[ebp+sl.win_columns]
  sub	al,[ebp+sl.button_size_columns]
  shr	al,1				;
  mov	[ebp+sl.button_separation_columns],al
;
; calculate separation rows
;
  mov	al,[ebp+sl.button_size_rows]
  mov	bh,[max_rows]			;number of buttons in column
  mul	bh
  mov	ah,al
;-ah- now has total columns use by buttons
  mov	al,[ebp+sl.win_rows]
  sub	al,ah				;al now has free space
  xor	ah,ah				;clear ah
  inc	bh				;divide by button_count + 1
  div	bh
  mov	[ebp+sl.button_separation_rows],al

  ret
;------------------------------------------------
;           al=4  calculate win_rows, win_columns from button_sizes and
;                 separation_sizes.  Calculated values may exceed the
;                 screen size.
;                 calcuated values are stored at: s.win_columns and
;                 sl.win_rows
;
sls_set_win_size:
;
; calculate columns in window
;
  mov	al,[ebp+sl.button_separation_columns]
  shl	al,1					;put separator on both ends
  add	al,[ebp+sl.button_size_columns]
  mov	[ebp+sl.win_columns],al
;
; calculate rows in window
;
  mov	al,[ebp+sl.button_separation_rows]
  add	al,[ebp+sl.button_size_rows]
  mov	bl,[ebp+sl.buttons_per_column]
  mul	bh
  add	al,[ebp+sl.button_separation_rows]
  mov	[ebp+sl.win_rows],al
  ret

