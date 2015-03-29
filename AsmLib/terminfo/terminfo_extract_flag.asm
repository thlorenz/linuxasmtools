
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
  extern terminfo_flags
  [section .text]

;>1 terminfo
;  terminfo_extract_flag - get boolean from terminfo
; INPUTS
;     the routines env_stack and terminfo_read must be
;       called before using this function. Also the
;       buffer filled by terminfo_read must be unmodified.
;     eax = flag number as follows:
;        auto_left_margin               [0]
;        auto_right_margin              [1]
;        no_esc_ctlc                    [2]
;        ceol_standout_glitch           [3]
;        eat_newline_glitch             [4]
;        erase_overstrike               [5]
;        generic_type                   [6]
;        hard_copy                      [7]
;        has_meta_key                   [8]
;        has_status_line                [9]
;        insert_null_glitch             [10]
;        memory_above                   [11]
;        memory_below                   [12]
;        move_insert_mode               [13]
;        move_standout_mode             [14]
;        over_strike                    [15]
;        status_line_esc_ok             [16]
;        dest_tabs_magic_smso           [17]
;        tilde_glitch                   [18]
;        transparent_underline          [19]
;        xon_xoff                       [20]
;        needs_xon_xoff                 [21]
;        prtr_silent                    [22]
;        hard_cursor                    [23]
;        non_rev_rmcup                  [24]
;        no_pad_char                    [25]
;        non_dest_scroll_region         [26]
;        can_change                     [27]
;        back_color_erase               [28]
;        hue_lightness_saturation       [29]
;        col_addr_glitch                [30]
;        cr_cancels_micro_mode          [31]
;        has_print_wheel                [32]
;        row_addr_glitch                [33]
;        semi_auto_right_margin         [34]
;        cpi_changes_res                [35]
;        lpi_changes_res                [36]
; OUTPUT
;     al = boolean
; NOTES
;   Source file: terminfo_extract_flag.asm
;   See asmref terminfo entry for more information
;<
; * ----------------------------------------------
; extern terminfo_flags
;*******
  global terminfo_extract_flag
terminfo_extract_flag:
  mov	ebx,[terminfo_flags]
  or	ebx,ebx
  jz	tef_exit		;exit if terminfo not available
  add	eax,ebx
  mov	al,[eax]
tef_exit:
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
  call	terminfo_extract_flag
  mov	eax,1
  int	byte 80h

;---------
  [section .data]
buf	times 4096 db 0
  [section .text]
%endif

