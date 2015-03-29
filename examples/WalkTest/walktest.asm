
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
  extern crt_clear
  extern read_stdin
  extern string_form
  extern kbuf
  extern env_stack
  extern mouse_enable
  extern crt_write
  extern ascii_to_dword
  extern dword_to_ascii

 global _start
_start:
  cld
  call	env_stack
  call	mouse_enable
  mov	eax,[color]
  call	crt_clear

  mov	ebp,test_block
  call	string_form

;convert all values to binary and store at:
; age		;buf1_start
; gender	;buf2_start
; weight	;buf3_start
; rate		;buf4_start
; minutes	;buf5_start = minutes
; seconds       ;but6_start = seconds
  mov	esi,buf1_start
  call	ascii_to_dword
  mov	[age],ecx

  mov	eax,1
  cmp	byte [buf2_start],'m'	;male?
  jne	skip_gender
  mov	[gender],eax		;set make state
skip_gender:

  mov	esi,buf3_start
  call	ascii_to_dword
  mov	[weight],ecx

  mov	esi,buf4_start
  call	ascii_to_dword
  mov	[rate],ecx

  mov	esi,buf5_start
  call	ascii_to_dword		;get minutes
  mov	[minutes],ecx

  mov	esi,buf6_start
  call	ascii_to_dword
  mov	[seconds],ecx

  mov	al,[kbuf]
  cmp	al,1bh			;esc?
  je	show_results		;

;compute results and display
;
; formula
; 132.853-(.0769*weight)-(.3877*age)+(5.315*gender)-(3.2649*walk_minutes)-(.1565*heart_rate)
;scaled by 10000
;[1328530-(769*weight)-(3877*age)+(53150*gender)-(32649*minutes)-(1565*rate)]/10000
;   where gender = 0 for female and 1 for male
;store results at scaled_results
;
  call	compute		;compute scaled_results

;display computed value
show_results:
  mov	eax,[color]
  call	crt_clear
  xor	edx,edx
  mov	eax,[scaled_results]
  mov	ebx,10000
  div	ebx		;compute result, eax=minutes edx=remainder
  push	edx		;save  remainder
  mov	edi,stuff
  call	dword_to_ascii
  mov	al,'.'
  stosb
  pop	eax
  mov	ebx,1000
  cmp	eax,ebx
  jb	use_zero
  xor	edx,edx
  div	ebx
  jmp	use_eax
use_zero:
  mov	eax,0
use_eax:
  or	eax,30h
  stosb
  mov	ecx,result_msg
  mov	edx,result_msg_end - result_msg
  call	crt_write

show_chart:
  mov	ecx,male_chart
  mov	edx,male_chart_end - male_chart
  cmp	byte [buf2_start],'f'
  jne	write_chart
  mov	ecx,female_chart
  mov	edx,female_chart_end - female_chart
write_chart:
  call	crt_write
  call	read_stdin
  mov	eax,1
  int	byte 80h
;-------------------------------------------------------------------------------------------
; formula
; 132.853-(.0769*weight)-(.3877*age)-(5.315*gender)-(3.2649*walk_minutes)-(.1565*heart_rate)
;scaled by 10000
;[1328530-(769*weight)-(3877*age)-(53150*gender)-(32649*minutes)-(1565*rate)]
;   where gender = 0 for female and 1 for male
;store results at scaled_results
;
compute:
  mov	[scaled_results],dword 1328530

  mov	eax,769
  mul	dword [weight]
  sub	[scaled_results],eax

  mov	eax,3877
  mul	dword [age]
  sub	[scaled_results],eax

  mov	eax,63150
  mul	dword [gender]
  add	[scaled_results],eax

  mov	eax,[minutes]
  mul	dword [scale_factor]
  mov	[scaled_minutes],eax
  mov	eax,[seconds]
  mul	dword [scale_factor]
  xor	edx,edx
  mov	ebx,60
  div	ebx
  add	[scaled_minutes],eax
  mov	eax,32649
  mul	dword [scaled_minutes]
  mov	ebx,10000
  div	ebx
  sub	[scaled_results],eax

  mov	eax,1565
  mul	dword [rate]
  sub	[scaled_results],eax
  ret


  [section .data]
;------------
scaled_results: dd	0		;scaled by 10000
scaled_minutes dd 0		;minutes * 10000
scale_factor	dd 10000
;------------


color:	dd	30003734h

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
 db 18	;ending row
 db 60  ;ending column
 db 1	;starting row
 db 1	;startng column
 dd string1_def ;string with cursor
 dd 30003634h	;text color
 dd 30003136h	;string color
 dd test_form	;form def ptr

test_form:
 db ' The walk test steps are: ',0ah
 db '  1. walk briskly for one mile.',0ah
 db '  2. measure total time and immediately take pulse.',0ah
 db '  3. fill out the following form',0ah
 db 0ah
 db 'age: '
string1_def:
 db -1  ;start of string def
 db 6	;row
 db 06	;column
 db 06	;current cursor posn
 db 0	;scroll
 db 3  ;window size
 db buf1_end - buf1_start ;buf size (max=127)
 db -2	;end of string def
buf1_start:
 db "   "
buf1_end:
 db ' ',0ah,0ah

 db 'gender (m) or (f) '
string2_def:
 db -1  ;start of string def
 db 8	;row
 db 19	;column
 db 19	;current cursor posn
 db 0	;scroll
 db 1  ;window size
 db buf2_end - buf2_start ;buf size (max=127)
 db -2	;end of string def
buf2_start:
 db 'm'
buf2_end:
 db ' ',0ah,0ah

 db 'weight '
string3_def:
 db -1  ;start of string def
 db 10	;row
 db 08	;column
 db 08	;current cursor posn
 db 0	;scroll
 db 3  ;window size
 db buf3_end - buf3_start ;buf size (max=127)
 db -2	;end of string def
buf3_start:
 db '   '
buf3_end:
 db ' pounds'
 db ' ',0ah,0ah

 db 'heart rate '
string4_def:
 db -1  ;start of string def
 db 12	;row
 db 12	;column
 db 12	;current cursor posn
 db 0	;scroll
 db 3  ;window size
 db buf4_end - buf4_start ;buf size (max=127)
 db -2	;end of string def
buf4_start:
 db '   '
buf4_end:
 db ' (BPM)'
 db ' ',0ah,0ah

 db 'walk time '
string5_def:
 db -1  ;start of string def
 db 14	;row
 db 11	;column
 db 11	;current cursor posn
 db 0	;scroll
 db 2  ;window size
 db buf5_end - buf5_start ;buf size (max=127)
 db -2	;end of string def
buf5_start:
 db '  '
buf5_end:
 db ' (minutes)'
 db ' ',0ah

 db '          '
string6_def:
 db -1  ;start of string def
 db 15	;row
 db 11	;column
 db 11	;current cursor posn
 db 0	;scroll
 db 2  ;window size
 db buf6_end - buf6_start ;buf size (max=127)
 db -2	;end of string def
buf6_start:
 db '  '
buf6_end:
 db ' (seconds)'
 db ' ',0ah,0ah

 db '  <Enter>=compute  <ESC>=exit',0

male_chart:
 db 'chart for males',0ah
 db 0ah
 db ' ages   poor    average    good',0ah
 db ' -----  ----    ---------  ----',0ah
 db ' 20-29  <37.1   37.1-44.2  44.3+',0ah
 db ' 30-39  <35.3   35.3-42.4  42.5+',0ah
 db ' 40-49  <33.0   33.0-39.9  40.0+',0ah
 db ' 50-59  <31.4   31.4-39.3  39.4+',0ah
 db ' 60+    <28.3   28.3-36.1  36.2+',0ah
 db 0ah
 db 'Press any key to continue'
male_chart_end:

female_chart:
 db 'chart for females',0ah
 db 0ah
 db ' ages   poor    average    good',0ah
 db ' -----  ----    ---------  ----',0ah
 db ' 20-29  <30.6   30.6-36.6  36.7+',0ah
 db ' 30-39  <28.7   28.7-34.6  34.7+',0ah
 db ' 40-49  <26.5   26.5-32.3  32.4+',0ah
 db ' 50-59  <25.1   35.1-31.3  31.4+',0ah
 db ' 60+    <21.9   21.9-28.2  28.3+',0ah
 db 0ah
 db 'Press any key to continue'
female_chart_end:
 
age	dd 0
gender	dd 0
weight	dd 0
rate	dd 0
minutes	dd 0
seconds dd 0

result_msg:
 db 0ah
 db 'fitness result = '
stuff:
 db '      ',0ah
result_msg_end:

  [section .text]


