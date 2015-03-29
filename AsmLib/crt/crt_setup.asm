
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

[section .text]
[absolute 0]
winsize_struc:
.ws_row:resw 1
.ws_col:resw 1
.ws_xpixel:resw 1
.ws_ypixel:resw 1
winsize_struc_size:

[section .text]
[absolute 0]
termios_struc:
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
termios_struc_size:

  [section .text]

  extern crt_rows
  extern crt_columns
;  extern crt_type

;****f* crt/crt_open *
; NAME
;>1 crt
;  crt_open - get crt parameters and setup termios
; INPUTS
;    none
; OUTPUT
;    [crt_rows] - global variable (byte) with row count
;    [crt_columns] - global variable (byte) with collumn count
; NOTES
;    This program is obsolete.  It puts terminal in raw mode
;    and newer library calls do not need terminal in raw mode.

;    source file: crt_setup.asm
;    Call crt_open if interactive terminal programs are utilized.
;    This function provides information about window size and
;    and disables default keyboard handling.  It allows individual
;    keys to be processed without waiting for user to type a <return>.
;<
;  * ----------------------------------------------
;*******
  global crt_open
crt_open:
;  call	crt_type

  mov ecx,5413h
  mov edx,winsize
  call IOctlTerminal		;get term rows (al)  term columns (eax)
;  call	error_check
  mov eax,[edx]
  cmp eax,0x0000FFFF
  jb sd_err
  or eax,eax
  jnz sd_10
sd_err:
  mov eax,0x00500018
;
; setup single window template
;
sd_10:
  mov	[crt_rows],al
  shr eax,16
  mov	[crt_columns],al

  mov ecx,5401h
  call IOctlTerminal0
  mov esi,edx
  mov edi,termios
  mov edx,edi
  push byte termios_struc_size
  pop ecx
  cld
  rep movsb
  mov byte [edx+termios_struc.c_cc+6],1
  and byte [edx+termios_struc.c_lflag+0],(~0000002q & ~0000001q & ~0000010q)
  and byte [edx+termios_struc.c_iflag+1],(~(0002000q>>8) & ~(0000400q>>8))
;  or  byte [edx+termios_struc.c_iflag],40h  ;; map 0ah > 0dh
  mov ecx,5402h
  call IOctlTerminal
  ret
;----------------------------------------------------
;****f* crt/crt_close *
; NAME
;>1 crt
;  crt_close
; INPUTS
;    none
; OUTPUT
;    none
; NOTES
;    This program is obsolete, see crt_open

;    file: crt_setup.asm
;    Call this function if crt_open was called previously.  Normally
;    this function is called before exiting the program.
;<
;  * ----------------------------------------------
;*******
  global crt_close
crt_close:
  mov	ecx,5402h
IOctlTerminal0:
  mov	edx,termios_orig
IOctlTerminal:		;*** entry point for terminal control calls
  xor	ebx,ebx		;get code for stdin
  mov eax,54
  int	80h
  ret

;------------------------------------------------------------

  [section .data]
;
; terminal settings  sent to kernel & termios_orig
  global termios,termios_orig
termios: times termios_struc_size db 0
termios_orig: times termios_struc_size db 0

  global winsize
winsize: times winsize_struc_size db 0

  [section .text]
