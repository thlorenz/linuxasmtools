
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
.sigev_value  resd 1 ;
.sigev_signo  resd 1 ;signal number
.sigev_notify resd 1 ;0=gen signal 1+ for threads
.sigev_compat resd 1 ;thread stuff (not used)
.timer_id     resd 1 ;filled in by timer_create
.period_sec   resd 1 ;used by settime,gettime
.period_nsec  resd 1 ;used by settime,gettime
.expire_sec   resd 1
.expire_nsec  resd 1
endstruc

;>1 timer
;  timer_create - create posix timer
; INPUTS
;     ebx = ptr to struc -> timer
;
;    timer struc
;    .type         resd 1
;    .sigev_value  resd 1
;    .sigev_signo  resd 1
;    .sigev_notify resd 1
;    .sigev_compat resd 1
;    .timer_id     resd 1
;    .period_sec   resd 1
;    .period_nsec  resd 1
;    .expire_sec   resd 1
;    .expire_nsec  resd 1
;    endstruc
;
;    Set .type to zero for realtime timer, for other possible
;      values see time.h.
;    Set .sigev_value to anything code passed to signal handler
;    Set .sigev_signo to signal number to generate when timer
;      expires.
;    Set .sigev_notify 0 for signal notification
;    All other fields are ignored
;
; OUTPUT
;    eax = return code, 0=success, else neg. system error
;    ebx = ptr to struc (timer)
; NOTES
;    file: timer_create.asm
;<
;  * ----------------------------------------------
;*******
  global timer_create
timer_create:
  push	ebx
  lea	edx,[ebx+timer.timer_id] ;id storage ptr
  lea	ecx,[ebx+timer.sigev_value] ;sigevent struc ptr
  mov	ebx,[ebx]		;get type
  mov	eax,259			;kernel call
  int	byte 80h
  pop	ebx		;restore struc ptr
  ret

;>1 timer
;  timer_delete - delete posix timer
; INPUTS
;     ebx = ptr to struc -> timer
;
;    timer struc
;    .type         resd 1
;    .sigev_value  resd 1
;    .sigev_signo  resd 1
;    .sigev_notify resd 1
;    .sigev_compat resd 1
;    .timer_id     resd 1
;    .period_sec   resd 1
;    .period_nsec  resd 1
;    .expire_sec   resd 1
;    .expire_nsec  resd 1
;    endstruc
;
; OUTPUT
;    eax = return code, 0=success, else neg. system error
;    ebx = ptr to struc (timer)
; NOTES
;    file: timer_delete.asm
;<
;  * ----------------------------------------------
;*******
  global timer_delete
timer_delete:
  push	ebx
  mov	ebx,[ebx+timer.timer_id] ;id storage ptr
  mov	eax,263			;kernel call
  int	byte 80h
  pop	ebx		;restore struc ptr
  ret

;-------------------------------------
 global _start,main
_start:
main:
  mov	ebx,timer_create_struc
  call	timer_create

  call	timer_delete

  mov	eax,1
  int	byte 80h

;-----------------
  [section .data]

timer_create_struc:
tc_type         dd 0 ;
tc_sigev_value  dd 0 ;
tc_sigev_signo  dd 10 ;SIGUSER1
tc_sigev_notify dd 0 ;
tc_sigev_compat dd 0 ;
tc_timer_id     dd 0 ;
tc_period_sec   dd 0 ;
tc_period_nsec  dd 0 ;
tc_expire_sec   dd 0 ;
tc_expire_nsec  dd 0 ;

  [section .text]


  