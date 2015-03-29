
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

;----------------- window_event_decode.inc ----------------------------

  extern lib_buf
%ifndef DEBUG
  extern socket_fd
%endif
  extern x_read_socket

;--------- window_event_decode -------------


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
;  window_event_decode - wait for events and decode actions
; INPUTS
;    ebp = ptr to window block
;    edi = ptr to x command to call, if zero
;          no command is called.
;          If command is called, all events are
;          handled until command completes.
;          window_event_decode exits when command is done.
;          If no command is passed, window_event_decode
;          waits foreveer.
;
;    eax = ptr to event processing list.  The list
;          is used to process all packets from the
;          server.
;
;           dd  Error              ;0
;           dd  CommandDone        ;1
;           dd  KeyPress           ;2
;           dd  KeyRelease         ;3
;           dd  ButtonPress        ;4
;           dd  ButtonRelease      ;5
;           dd  MotionNotify       ;6
;           dd  EnterNotify        ;7
;           dd  LeaveNotify        ;8
;           dd  FocusIn            ;9
;           dd  FocusOut           ;10
;           dd  KeymapNotify       ;11
;           dd  Expose             ;12
;           dd  GraphicsExpose     ;13
;           dd  NoExpose           ;14
;           dd  VisibilityNotify   ;15
;           dd  CreateNotify       ;16
;           dd  DestroyNotify		;17
;           dd  UnmapNotify		;18
;           dd  MapNotify		;19
;           dd  MapRequest		;20
;           dd  ReparentNotify		;21
;           dd  ConfigureNotify		;22
;           dd  ConfigureRequest	;23
;           dd  GravityNotify		;24
;           dd  ResizeRequest		;25
;           dd  CirculateNotify		;26
;           dd  CirculateRequest	;27
;           dd  PropertyNotify		;28
;           dd  SelectionClear		;29
;           dd  SelectionRequest	;30
;           dd  SelectionNotify		;31
;           dd  ColormapNotify		;32
;           dd  ClientMessage		;33
;           dd  MappingNotify		;34
;
;          The events after last enabled event are
;          not used, and the table can be truncated
;          to save memory.
;
;          actions can force window_event_decode to exit
;          by returning a negative.  The negative
;          value of 80000000h is treated as a normal
;          exit without error.
;
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
;               
; NOTES
;   source file: window_event_decode.asm
;   This function works in two modes.  If a action
;   is provided it returns after doing the action.
;   Any events found will also be processed.
;   If no action is passed, then this function wait
;   forever and processes events.
;<
; * ----------------------------------------------
;input; eax=socket fd to wait for
  global window_event_decode
window_event_decode:
  mov	[process_list_ptr],eax
  or	edi,edi		;check if x command passed
  jz	we_50		;jmp if no pre command
  call	edi
we_10:
  cmp	eax,-5		;unexpected event?
  jne	we_exit		;exit if action done
  movzx eax,byte [ecx]	;get packet code
  shl	eax,2		;convert to dword ptr
  add	eax,[process_list_ptr]
  call	[eax]		;call process
  or	eax,eax
  jns	we_20		;jmp if normal continue
  test	eax,7fffffffh	;check for normal exit force
  jz	we_exit1
we_20:
  mov	eax,-1		;wait forever
  mov	ecx,lib_buf	;buffer
  mov	edx,700		;buffer length
  call	x_read_socket
  jns	we_exit
  jmp	short we_10
we_50:
  mov	eax,-1		;wait forever
  mov	ecx,lib_buf	;buffer
  mov	edx,700		;buffer length
  call	x_read_socket
  jns	do_process
  cmp	al,-5
  jne	we_exit		;exit if error
do_process:
  movzx eax,byte [ecx]	;get packet code
  shl	eax,2		;convert to dword ptr
  add	eax,[process_list_ptr]
  call	[eax]		;call process
  or	eax,eax
  jns	we_50		;jmp if normal continue
  test	eax,7fffffffh	;check for normal exit force
  jnz	we_exit
we_exit1:
  xor	eax,eax
we_exit:
  or	eax,eax
  ret

  [section .data]
process_list_ptr: dd 0
  [section .text]
