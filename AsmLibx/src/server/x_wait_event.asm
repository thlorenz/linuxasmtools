
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
;--------- x_wait_event -------------

  extern lib_buf
  extern list_check_front
  extern x_read_socket
  extern list_block

; /* Event names.  Used in "type" field in XEvent structures.  Not to be
; confused with event masks above.  They start from 2 because 0 and 1
; are reserved in the protocol for errors and replies. */
; (from Numit_or)
%define KeyPress		2
%define KeyRelease		3
%define ButtonPress		4
%define ButtonRelease		5
%define MotionNotify		6
%define EnterNotify		7
%define LeaveNotify		8
%define FocusIn			9
%define FocusOut		10
%define KeymapNotify		11
%define Expose			12
%define GraphicsExpose		13
%define NoExpose		14
%define VisibilityNotify	15
%define CreateNotify		16
%define DestroyNotify		17
%define UnmapNotify		18
%define MapNotify		19
%define MapRequest		20
%define ReparentNotify		21
%define ConfigureNotify		22
%define ConfigureRequest	23
%define GravityNotify		24
%define ResizeRequest		25
%define CirculateNotify		26
%define CirculateRequest	27
%define PropertyNotify		28
%define SelectionClear		29
%define SelectionRequest	30
%define SelectionNotify		31
%define ColormapNotify		32
%define ClientMessage		33
%define MappingNotify		34
%define LASTEvent		35	; /* must be bigger than any event # */
struc XAnyEvent
.type		resd	1 ;
.serial		resd	1 ; # of last request processed by server
.send_event	resd	1 ; true if this came from a SendEvent request
.display	resd	1 ; Display the event was read from
.window		resd	1 ; window on which event was requested in event mask
endstruc
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
;  x_wait_event - wait forever and read event packet
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
;   source file: x_wait_event.asm
;   If replies are pending this function will
;   return an error of -1
;<
; * ----------------------------------------------
  global x_wait_event
x_wait_event:
  mov	edx,list_block
  call	list_check_front
  jns	we_exit		;exit if reply pending
  mov	eax,-1		;wait forever
  mov	ecx,lib_buf	;buffer
  mov	edx,700		;buffer length
  call	x_read_socket
we_exit:
  ret