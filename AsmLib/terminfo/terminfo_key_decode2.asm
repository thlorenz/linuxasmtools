
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
;>1 terminfo
;  terminfo_key_decode2 - decode key strings and get process
; INPUTS
;    edx = ptr to input buffer with key strings (zero terminated)
;    esi = decode table with key# and processes,
;
;          The decode table must be preprocessed with
;          terminfo_decode_setup  before it is used.
;
;          First, the table must have padding for allow
;          for expansion with string from terminfo.
;          Usually  3*number_of_entries is enough
;
;          Next, one byte is flag telling
;          terminfo_decode_setup that this table is
;          in decode2  format.  It must equal 2
;
;          The body can have normal key definitons
;          consisting of a key string, followed by
;          a dword process address. If the key
;          possibly appears in a terminfo file it
;          can have a alternate format as follows:
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
;    db 2              ;flag for decode2 formatted table
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
;
;     After processing by terminfo_decode_setup, the table
;     will appear as follows:
;
;    db 1bh,5bh,48h,0  ; pad_home
;    dd gs_home        ; home process 
;    db 1bh,5bh,44h,0  ; pad_left
;    dd gs_left        ; left arrow process
;    db 7fh,0          ; backspace
;    dd gs_backspace   ; backspace process
;    db 0              ;end of table
;
; OUTPUT
;    eax = process pointer or zero if no match
; NOTES
;   source file: terminfo_key_decode2.asm
;   see also crt_open, mouse_enable
;<
; * ----------------------------------------------
;*******
  global terminfo_key_decode2
terminfo_key_decode2:
  mov	edi,edx	;get inkey ptr
check_next:
  cmpsb			;inkey match table entry
  je	first_char_match ;jmp if char match
kd3_10:
  lodsb			;get next table char
  or	al,al		;scan to end of table key string
  jnz	kd3_10		;skip to end of table key
  add	esi,4		;move past process
  cmp	byte [esi],0	;check if end of table
  jne	terminfo_key_decode2	;jmp if another table entry
  xor	eax,eax		;generate fail code
  jmp	short kd3_exit2	;go exit
first_char_match:
  cmp	byte [esi],0	;end of table entry
  jne	check_next	;jmp if no match
  cmp	byte [edi],0	;end of input key?
  jne	kd3_10		;go restart search
get_process:
  inc	esi		;move past zero
kd3_exit:
  lodsd			;get process
kd3_exit2:
  ret
