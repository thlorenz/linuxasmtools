
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


struc termio_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc
;termio_struc_size:

extern lib_buf
extern read_termios_0
extern output_termios_0


;------------------------------------------    
;>1 terminal
;   raw_set1 - switch stdin to raw mode
; INPUTS
;   none
; OUTPUT
;   [termios1] is a global library structure which
;              is set to previous state of termios.
;   lib_buf contains modified termios that was output
; NOTES
;    source file: raw_set.asm
;
;    The current termios state is saved at global
;    variable "termios1" as follows:
;      c_iflag: resd 1
;      c_oflag: resd 1
;      c_cflag: resd 1
;      c_lflag: resd 1
;      c_line:  resb 1
;      c_cc:    resb 19 ; total size is 36 bytes
;    The new termios is created with the following bits
;      c_iflag bit ICRNL (0100) map input CR to NL set
;      c_lflag bits ICANON (0002) and ECHO (0008) cleared,
;                   this sets us in raw mode witout echo 
;
;    The buffer "lib_buf" is used as temp work buffer
;    Use function raw_unset1 to restore termios1
;<
  global raw_set1
raw_set1:
  mov	edx,termios1
  call	read_termios_0
  mov	edx,lib_buf
  call	read_termios_0
  and	byte [edx + termio_struc.c_lflag],~0bh ;set raw mode
  or	byte [edx + termio_struc.c_iflag +1],01 ;
  and	byte [edx + termio_struc.c_iflag+1],~14h ;disable IXON,IXOFF
  call	output_termios_0
  ret  

;----------------------------------------------------------    
;>1 terminal
;   raw_set2 - switch stdin to raw mode
; INPUTS
;   none
; OUTPUT
;   [termios2] is set to current termios state then
;   copied to lib_buf and modified to set raw mode.
; NOTES
;    source file: raw_set.asm
;
;    This function is called by "read_stdin" and should not
;    be called by code that also calls "read_stdin"  while
;    termios data is saved in "termios2"
;
;    The current termios state is saved at global
;    variable "termios2" as follows:
;      c_iflag: resd 1
;      c_oflag: resd 1
;      c_cflag: resd 1
;      c_lflag: resd 1
;      c_line:  resb 1
;      c_cc:    resb 19 ; total size is 36 bytes
;    The new termios is created with the following bits
;      c_iflag bit ICRNL (0100) map input CR to NL set
;      c_lflag bits ICANON (0002) and ECHO (0008) cleared,
;                   this sets us in raw mode witout echo 
;
;    The buffer "lib_buf" is used as temp work buffer
;    Use function raw_unset1 to restore termios2
;<
  global raw_set2
raw_set2:
  mov	edx,termios2
  call	read_termios_0
  mov	edx,lib_buf
  call	read_termios_0
  and	byte [edx + termio_struc.c_lflag],~0bh ;set raw mode, no echo
  or	byte [edx + termio_struc.c_iflag +1],01 ;
  and	byte [edx + termio_struc.c_iflag+1],~14h ;disable IXON,IXOFF
  call	output_termios_0
  ret  

;--------------------------------------------------------
;>1 terminal
;   raw_unset1 - restore termios saved with raw_set1
; INPUTS
;   [termios1] is global library structure with new
;              termios data
; OUTPUT
;   none
; NOTES
;    source file: raw_set.asm
;<
  global raw_unset1
raw_unset1:
  mov	edx,termios1		;restore termios
  call	output_termios_0
  ret
;--------------------------------------------------------
;>1 terminal
;   raw_unset2 - restore termios saved with raw_set2
; INPUTS
;   [termios2] - global library structure with termios
;                to restore      
; OUTPUT
;   none
; NOTES
;    source file: raw_set.asm
;<
  global raw_unset2
raw_unset2:
  mov	edx,termios2		;restore termios
  call	output_termios_0
  ret
;--------------------------------------------------------
  [section .data]
termios1:  times 36 db 0
termios2:  times 36 db 0


