
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
;---------- x_change_attributes ------------------

  extern x_send_request

;---------------------
;>1 win_ctrl
;  x_change_attributes - change a window attribute
; INPUTS
;    ebp = window block
;    eax = mask
;     #x00000001 	 background-pixmap
;     #x00000002 	 background-pixel
;     #x00000004 	 border-pixmap
;     #x00000008 	 border-pixel
;     #x00000010 	 bit-gravity
;     #x00000020 	 win-gravity
;     #x00000040 	 backing-store
;     #x00000080 	 backing-planes
;     #x00000100 	 backing-pixel
;     #x00000200 	 override-redirect
;     #x00000400 	 save-under
;     #x00000800 	 event-mask
;     #x00001000 	 do-not-propagate-mask
;     #x00002000 	 colormap
;     #x00004000 	 cursor
;
;   ebx = value
;
;     4  PIXMAP		 background-pixmap
;        0	       None
;        1	       ParentRelative
;     4  CARD32		 background-pixel
;     4  PIXMAP		 border-pixmap
;        0	       CopyFromParent
;     4  CARD32		 border-pixel
;     1  BITGRAVITY 	 bit-gravity
;     1  WINGRAVITY 	 win-gravity
;     1			 backing-store
;        0	       NotUseful
;        1	       WhenMapped
;        2	       Always
;     4  CARD32		 backing-planes
;     4  CARD32		 backing-pixel
;     1  BOOL		 override-redirect
;     1  BOOL		 save-under
;     4  SETofEVENT 	 event-mask
;     4  SETofDEVICEEVENT	 do-not-propagate-mask
;     4  COLORMAP		 colormap
;        0	       CopyFromParent
;     4  CURSOR		 cursor
;        0	       None
;
;   ecx = window id
;
; OUTPUT:
;    flags set for success-jns  or error-js
;    eax = lenght of reply pkt or negative error
;    ebx = 0 if sequence# in sync
;    ecx = ptr to reply packet
;
; NOTES
;   source file: x_change_attributes.asm
;<
; * ----------------------------------------------

  global x_change_attributes
x_change_attributes:
  mov	[ca_mask],eax
  mov	[ca_mask+4],ebx		;save value
  mov	[ca_id],ecx
%ifdef DEBUG
  mov	ecx,ca_msg
  call	crt_str
%endif
  mov	ecx,change_attributes_request
  mov	edx,change_attributes_request_len
  call	x_send_request
  ret

  [section .data]
change_attributes_request:
 db 2	;opcode
 db 0	;unused
 dw change_attributes_request_len / 4
ca_id:
 dd 0	;GCONTEXT gc (window id)
ca_mask:
 dd 0	;bitmask
 dd 0	;value 
change_attributes_request_len equ $ - change_attributes_request

%ifdef DEBUG
ca_msg: db 0ah,'change_attributes (2)',0ah,0
%endif

  [section .text]

