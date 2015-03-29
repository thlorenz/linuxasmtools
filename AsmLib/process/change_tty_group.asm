
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
;  change_tty_group - assign tty to new group
;  the group controlling a tty is said to be in foreground
;  all others are in background.
; INPUTS
;    eax = new group id
;    ebx = terminal fd (usually 0)
; OUTPUT
;    eax = zero if success else error code
; NOTES
;    calls tcsetpgrp
;    uses lib_buf to hold new group
;    If current process moves stdin to another group the
;    signal SIGTTOU occurs.
;    source file: change_tty_group.asm
;<
  [section .text]
;
  global change_tty_group
change_tty_group:
  mov	[lib_buf],eax
  mov	eax,54
;  mov	ebx,0			;stdin
  mov	ecx,5410h
  mov	edx,lib_buf
  int	80h
  ret

