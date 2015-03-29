
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

  extern is_alpha
;>1 terminfo
;  terminfo_key_decode1 - decode non-aplha key strings and get process
; INPUTS
;    edx = ptr to input buffer with key strings (zero terminated)
;    esi = decode table with key# and processes,
;
;          The decode table must be preprocessed with
;          terminfo_decode_setup  before it is used.
;
;          First, the table can have padding to allow
;          for expansion of strings from terminfo.
;
;          Next, one byte is flag telling
;          terminfo_decode_setup that this table is
;          in decode1  format.  It must equal 1
;
;          The first and last key definitions are
;          dword process address. When a alpha key
;          key is found, the top process is returned.
;          If no alpha or match of key then the
;          dword at end is returned.  The middle entries
;          are non alpha keys defned as follows:
;
;          The body can have normal key definitons
;          consisting of a key string, followed by
;          a dword process address. If the key
;          possibly appears in a terminfo file it
;          can have a alternate format as follows:
;
;
;            db -1        ;start of terminfo format
;            dw x         ;terminfo index
;            dd process   ;address of key handler
;            db operator  ;-2=or -3=and following
;            db (key string)
;            dd process
;                .
;                .
;            db -4        ;end of this terminfo format
;
;     The decode table must be preprocessed with:
;     terminfo_decode_setup.
;
;   unprocessed decode table example
;    times 3*4 db 0    ;padding for expansion of table
;    db 1              ;flag for decode1 formatted table
;    dd	gs_normal_char ;alpha key process
;
;    db -1             ;start terminfo definition
;    dw 12             ;home key value for terminfo
;    dd gs_home        ; home process
;    db -2             ;(or) the following
;    db 1bh,'[3',0     ;key string
;    dd gs_home        ;process
;    db -4             ;end of this terminfo def
; 
;    db -1             ;lookup this key in terminfo
;    dw 14             ;left arrow key code
;    dd gs_left        ; left arrow process
;    db -4             ;no and/or defs
;
;    db 7fh,0          ; backspace
;    dd gs_backspace   ; backspace process
;    db 0              ;end of table
;    dd no_match       ;no-match process
;
;     After processing by terminfo_decode_setup, the table
;     will appear as follows:
;
;    dd	gs_normal_char ;alpha key process
;    db 1bh,5bh,48h,0  ; pad_home
;    dd gs_home        ; home process 
;    db 1bh,5bh,44h,0  ; pad_left
;    dd gs_left        ; left arrow process
;    db 7fh,0          ; backspace
;    dd gs_backspace   ; backspace process
;    db 0              ;end of table
;    dd no_match       ;no-match process
;
; OUTPUT
;    eax = process pointer
; NOTES
;   source file: key_decode1.asm
;   see also crt_open, mouse_enable
;<
; * ----------------------------------------------
;*******
  global terminfo_key_decode1
terminfo_key_decode1:
  mov	al,[edx]	;get input key
  call	is_alpha
  je	ka_exit		;jmp if alpha key
;
; key is not alpha, scan key strings
;
not_alpha:
  add	esi,4		;move past alpha process at top of table
ka_lp:
  mov	edi,edx		;get address of input key
  cmpsb
  je	first_char_match
ka_10:
  lodsb
  or	al,al		;scan to end of table key string
  jnz	ka_10
  add	esi,4		;move past process
  cmp	byte [esi],0	;check if end of table
  je	get_process
  jmp	ka_lp
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
  inc	esi		;move past zero
ka_exit:
  lodsd			;get process
  ret
;-------------------------------------------------
%ifdef DEBUG
 extern terminfo_read
%include "terminfo_decode_setup.inc"
; extern terminfo_decode_setup

  extern env_stack
  global main,_start
main:
_start:
  call	env_stack
  mov	eax,buf
  call	terminfo_read

  mov	eax,decode_table
  call	terminfo_decode_setup

  mov	eax,1
  int	byte 80h

dog: nop
cat: nop
zorro: nop
unknown: nop

;---------
  [section .data]
buf	times 4096 db 0
decode_table:
  times 10 db 0	;pad
  db 1	;flag
  dd	dog
  dw	'1'
  dd	cat
  dw	8000h+66	;f1
  dd	zorro
  db	0	;end of table
  dd	unknown

  [section .text]
%endif
