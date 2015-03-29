
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
;----------------------------------------------------------------
;>1 signal
;  signal_send - send signal
; INPUTS  ebx = process id (pid) to recieve signal
;         ecx = signal number, or zero
;               A zero does not send a signal, but does
;               do error checking.  This may be useful
;               to determine if a process exists or
;               a signal can be sent to process.
; OUTPUT  success (0)
;         EINVAL (-22) invalid signal
;         ESRCH  (-3)  pid not found
;         EPERM  (-1)  insufficient permissions
;   
; NOTES
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signal_send
signal_send:
  mov	eax,37		;kill function
  int	80h
  ret

  