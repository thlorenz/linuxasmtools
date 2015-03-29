
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
  extern terminfo_numbers
  [section .text]

;>1 terminfo
;  terminfo_extract_number - get value from terminfo
; INPUTS
;     the routines env_stack and terminfo_read must be
;       called before using this function. Also the
;       buffer filled by terminfo_read must be unmodified.
;     eax = number index as follows:
;       columns                        [0]
;       init_tabs                      [1]
;       lines                          [2]
;       lines_of_memory                [3]
;       magic_cookie_glitch            [4]
;       padding_baud_rate              [5]
;       virtual_terminal               [6]
;       width_status_line              [7]
;       num_labels                     [8]
;       label_height                   [9]
;       label_width                    [10]
;       max_attributes                 [11]
;       maximum_windows                [12]
;       max_colors                     [13]
;       max_pairs                      [14]
;       no_color_video                 [15]
;       buffer_capacity                [16]
;       dot_vert_spacing               [17]
;       dot_horz_spacing               [18]
;       max_micro_address              [19]
;       max_micro_jump                 [20]
;       micro_col_size                 [21]
;       micro_line_size                [22]
;       number_of_pins                 [23]
;       output_res_char                [24]
;       output_res_line                [25]
;       output_res_horz_inch           [26]
;       output_res_vert_inch           [27]
;       print_rate                     [28]
;       wide_char_size                 [29]
;       buttons                        [30]
;       bit_image_entwining            [31]
;       bit_image_type                 [32]
; OUTPUT
;     ax = value
; NOTES
;   Source file: terminfo_extract_number.asm
;   See asmref terminfo entry for more information
;<
; * ----------------------------------------------
; extern terminfo_flags
;*******
  global terminfo_extract_number
terminfo_extract_number:
  shl	eax,1
  mov	ebx,[terminfo_numbers]
  or	ebx,ebx
  jz	ten_exit		;jmp if terminfo not available
  add	eax,ebx
  mov	ax,[eax]
ten_exit:
  ret
;-------------------------------------------------
%ifdef DEBUG
%include "terminfo_read.inc"

  extern env_stack
  global main,_start
main:
_start:
  call	env_stack
  mov	eax,buf
  call	terminfo_read
  mov	eax,1			;get second flag
  call	terminfo_extract_number
  mov	eax,1
  int	byte 80h

;---------
  [section .data]
buf	times 4096 db 0
  [section .text]
%endif

