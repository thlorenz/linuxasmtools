
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
  extern lib_buf
;------------------------------
;>1 process
;  get_tty_group - get group controling the tty
; INPUTS
;    ebx = fd for tty
; OUTPUT
;    eax = tpgid (terminal group) or error if negative
; NOTES
;    calls TIOCGPGRP ioctl
;    source file: get_tty_group.asm
;<
  [section .text]
;
  global get_tty_group
get_tty_group:
  mov	eax,54
;ebx=fd
  mov	ecx,540fh	;TIOCGPGRP  
  mov	edx,lib_buf
  int	80h
  or	eax,eax
  js	gtg_exit	;jmp if error
  mov	eax,[lib_buf]
gtg_exit:
  ret

