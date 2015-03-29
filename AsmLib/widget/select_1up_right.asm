
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

%include "select_list_struc.inc"
  extern  select_list_setup
  extern  select_list_engine
  extern max_text,max_rows,max_groups,mrows
  extern crt_rows,crt_columns
;
  [section .text]

;----------------------------------------------------------------------------------------
;>1 widget
; select_1up_list_right - display selection list on right half of screen
;
; This is a high level function that calls select_list_engine to
; display a selection window.  To keep the calling interface simple
; the colors and other  values will be assumed.
;
;   INPUTS
;   ------
;
;      edi=ptr to top of work area.
;          work area size =  20+(size of text strings)+ 10*(button count).
;      esi=ptr to text strings
;
;      Select_1up_list_right needs a list of text strings to
;      place in buttons and a work area to setup for select_list_engine.
;
;      Text strings can be multi line (using 0ah) and
;      the last line is terminated by  zero byte.
;      The last text string needs to have another zero
;      byte indicating no more string follow.
;
;   OUTPUT
;   ------
;
;    eax = return code
;
;          When selected, the buttons return a code
;          describing its position.
;          Positions are encoded in two bytes in eax
;          as ah=group number,  al=row number.  These
;          are not physical row and columns, they are
;          button positions.  the frist button is 1,1.
;          The button below it is 1,2.
;
;                1,1             2,1
;
;                1,2             2,2
;
;          If a error is found eax will contain -1.
;
;          ESC key press returns eax=0
;
;   Since select_1up_list_right only has one group of buttons
;   all return values will have ah=1 and al=the button number.
;
;   The work area will be modified to suit the select_list_engine and
;   must be writable.
;
;   source file: select_1up_right.asm
;<
;-------------------------------------------------------------------------             
  global select_1up_list_right
select_1up_list_right:
  mov	al,1
  call	select_list_setup	;setup structures for select_list_engine
;
; ebp is now set to top of structures
;
  mov	al,2
  call	select_list_setup	;fill in defaults for colors and following
;              [ptr2group_ptrs] - has ptr to group ptrs
;              [ptrs2button_defs] - has pointer to list of pointers
;                                   for each button group
;              also set [max_text] - longest button text line size
;                       [mrows] - max number of button text rows
;                       [max_groups] - number of button groups (columns)
;                       [max_rows] - number of buttons in group
;                       [crt_rows] - screen size from kernel call
;                       [crt_columns] - screen size from kernel call
;              

; now begin filling in the structure

  mov	byte [ebp+sl.button_groups],1		;only one column of buttons
  mov	al,[crt_rows]
  sub	al,2					;remove boarder rows
  mov	byte [ebp+sl.win_rows],al		;use all screen rows
  mov	al,[crt_columns]
  test	al,1					;check if odd number of columns
  jne	slr_10					;jmp if even number of columns
  inc	al
slr_10:
  shr	al,1
  mov	byte [ebp+sl.win_columns],al		;use right half of screen
  inc	al					;convert to 1 based location
  mov	byte [ebp+sl.win_left_column],al	;put window on right
  mov	byte [ebp+sl.win_top_row],2		;put window at top
;compute button size
  mov	al,[max_text]
  mov	[ebp+sl.button_size_columns],al
  mov	al,[max_rows]
  mov	[ebp+sl.buttons_per_column],al
  mov	al,[mrows]
  mov	[ebp+sl.button_size_rows],al
;
;compute separation values
;
  mov	al,3
  call	select_list_setup
;
; everything is now setup, call select_list_engine
;
  call	select_list_engine
  ret


