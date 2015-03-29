
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
;  create_group - make our process a new group leader
; INPUTS
;    ebx = our pid (becomes group gpid)
;          if ebx = 0 the current pid is used
; OUTPUT
;    eax = zero if success
;          a negative value is error code
; NOTES
;    calls setpgid
;    The new group becomes a group leader and it pid=gid
;    for the group.
;    source file: create_group.asm
;<
  [section .text]
;
  global create_group
create_group:
  mov	eax,57
  xor	ecx,ecx		;use pid as new group gid
  int	80h
  ret
