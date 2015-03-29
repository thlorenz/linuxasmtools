
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
	%define stderr 0x2

struc timer
.type         resd 1 ;0=realtime
.sigev_value  resd 1 ;passed to signal handler
.sigev_signo  resd 1 ;signal number
.sigev_notify resd 1 ;0= signal 1+ for threads
.sigev_compat resd 1 ;thread stuff (not used)
.timer_id     resd 1 ;filled in by timer_create
.period_sec   resd 1 ;used by settime
.period_nsec  resd 1 ;used by settime
.expire_sec   resd 1 ;used by settime
.expire_nsec  resd 1 ;used by settime
.get_psec     resd 1 ;used by gettime
.get_pnsec    resd 1 ;used by gettime
.get_esec     resd 1 ;used by gettime
.get_ensec    resd 1 ;used by gettime
endstruc

;>1 timer
;  timer_gettime - get timer state
; INPUTS
;     ebx = ptr to struc -> timer
;
;    timer struc
;    .type         resd 1  ;create - sets to zero for realtime timer
;    .sigev_value  resd 1  ;create - passed to signal handler
;    .sigev_signo  resd 1  ;create - signal # to generate
;    .sigev_notify resd 1  ;create - 0 to create signal
;    .sigev_compat resd 1  ;ignored
;    .timer_id     resd 1  ;create - filled in with timer id
;    .period_sec   resd 1  ;settime - active sec
;    .period_nsec  resd 1  ;settime - active nsec
;    .expire_sec   resd 1  ;settime - countdown sec
;    .expire_nsec  resd 1  ;settime - countdown nsec
;    .get_psec     resd 1  ;gettime - current state (doesn't change)
;    .get_pnsec    resd 1  ;gettime - current state (doesn't change)
;    .get_esec     resd 1  ;gettime - seconds (counting down)
;    .get_ensec    resd 1  ;gettime - nsec (counting down)
;    endstruc
;
;    The .period_xxx and .expire_xxx fields will be
;    filled in by this call
;
; OUTPUT
;    eax = return code, 0=success, else neg. system error
;    ebx = ptr to struc (timer)
; NOTES
;    file: timer_settime.asm
;<
;  * ----------------------------------------------
;*******
  global timer_gettime
timer_gettime:
  push	ebx
  lea	ecx,[ebx+timer.get_psec] ;get new time
  mov	ebx,[ebx+timer.timer_id] ;id 
  mov	eax,261			;kernel call
  int	byte 80h
  pop	ebx		;restore struc ptr
  ret
