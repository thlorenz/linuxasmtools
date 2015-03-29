
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
;------------------------------
;>1 process
;  join_group - join a process to (existing) group
; INPUTS
;    ebx = pid joining group (usually current pid)
;          0 = use current pid
;    ecx = gpid to join
; OUTPUT
;    eax = 0 if success
;          a negative value is error code
; NOTES
;    calls setpgid.
;    only groups in same scession can be joined, so
;    check session first.
;    source file: join_group.asm
;<
  [section .text]
;
  global join_group
join_group:
  mov	eax,57		;setpgid
  int	80h
  ret
