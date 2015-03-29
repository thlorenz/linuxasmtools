
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
;--------- x_wait_reply -------------

  extern lib_buf
  extern list_check_front
  extern x_read_socket
  extern list_block

;struc XAnyEvent
;.type		resd	1 ;
;.serial		resd	1 ; # of last request processed by server
;.send_event	resd	1 ; true if this came from a SendEvent request
;.display	resd	1 ; Display the event was read from
;.window		resd	1 ; window on which event was requested in event mask
;endstruc

struc XKeyEvent
.type		resd	1; of event
.serial		resd	1; # of last request processed by server
.send_event	resd	1; true if this came from a SendEvent request
.display	resd	1; Display the event was read from
.window		resd	1;         "event" window it is reported relative to
.root		resd	1;         root window that the event occurred on
.subwindow	resd	1; child window
.time		resd	1; milliseconds
.x		resd	1
.y		resd	1; pointer x, y coordinates in event window
.x_root 	resd	1
.y_root		resd	1; coordinates relative to root
.state		resd	1; key or button mask
.keycode	resd	1; detail
.same_screen	resd	1; same screen flag
endstruc
struc XButtonEvent
.type		resd	1; of event
.serial		resd	1; # of last request processed by server
.send_event	resd	1; true if this came from a SendEvent request
.display	resd	1; Display the event was read from
.window		resd	1;         "event" window it is reported relative to
.root		resd	1;         root window that the event occurred on
.subwindow	resd	1; child window
.time		resd	1; milliseconds
.x		resd	1
.y		resd	1; pointer x, y coordinates in event window
.x_root		resd	1
.y_root		resd	1; coordinates relative to root
.state		resd	1; key or button mask
.button		resd	1; detail
.same_screen	resd	1; same screen flag
endstruc

;---------------------
;>1 server
;  x_wait_reply - wait for xx milliseconds for reply
; INPUTS
;    none 
; OUTPUT:
;    failure - eax=negative error code
;              flags set for js
;           -1=reply read error (buffer error)
;           -2=error packet in buffer
;           -3=reply out of sequence
;           -4=timeout expired or servers in tryagain loop
;           -5=unexpected event while waiting for reply.
;           -6=socket dead
;           -x=all other errors are from kernel
;    success - eax = number of bytes read from server
;              ecx = pointer to reply buffer info.            
;              (see file event_info.inc for buffer data)    
; NOTES
;   source file: x_wait_reply.asm
;   If replies are not pending this function will
;   return an error of -1
;   If reply does not occur within 2 seconds a timeout
;   error will be returned
;<
; * ----------------------------------------------
;input; eax=socket fd to wait for
  global x_wait_reply
x_wait_reply:
  mov	edx,list_block
  call	list_check_front
  js	wr_exit		;exit if no reply pending
  mov	eax,2000	;wait for 2 seconds max
  mov	ecx,lib_buf	;buffer
  mov	edx,700		;buffer length
  call	x_read_socket
wr_exit:
  ret