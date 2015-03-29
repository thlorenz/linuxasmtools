
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
;------------------ window_event_enable ------------------------

%include "../../include/window.inc"

  extern x_change_attributes
;---------------------
;>1 server
;  window_event_enable - enable window events
; INPUTS
;  ebp = window block
;  ebx = flag bits for events of interest
;    0x00000001 KeyPress
;    0x00000002 KeyRelease
;    0x00000004 ButtonPress
;    0x00000008 ButtonRelease
;    0x00000010 EnterWindow
;    0x00000020 LeaveWindow
;    0x00000040 PointerMotion
;    0x00000080 PointerMotionHint
;    0x00000100 Button1Motion
;    0x00000200 Button2Motion
;    0x00000400 Button3Motion
;    0x00000800 Button4Motion
;    0x00001000 Button5Motion
;    0x00002000 ButtonMotion
;    0x00004000 KeymapState
;    0x00008000 Exposure
;    0x00010000 VisibilityChange
;    0x00020000 StructureNotify
;    0x00040000 ResizeRedirect
;    0x00080000 SubstructureNotify
;    0x00100000 SubstructureRedirect
;    0x00200000 FocusChange
;    0x00400000 PropertyChange
;    0x00800000 ColormapChange
;    0x01000000 OwnerGrabButton
;    0xFE000000 unused but must be zero
; OUTPUT:
;    error = sign flag set
;    success - returns the following items in window block
;              
; NOTES
;   source file: window_event_enable.asm
;<
; * ----------------------------------------------

  global window_event_enable
window_event_enable:
  mov	eax,800h		;event mask bit
;  mov	ebx,1+4			;keypress + button press
  mov	ecx,[ebp+win.s_win_id]	;get window 
  call	x_change_attributes
  ret

 [section .text]

