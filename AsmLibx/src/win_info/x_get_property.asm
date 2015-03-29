
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
;---------- x_get_property ------------------

  extern x_send_request
  extern x_wait_big_reply 
 
;---------------------
;>1 win_info
;  x_get_property - get property status
; INPUTS
;    eax = window id to query
;    ecx = buffer
;    edx = buffer length
;    esi = property (atom)
;    edi = type (atom)
;          pre defined atoms
;            PRIMARY         1      WM_NORMAL_HINTS  40
;            SECONDARY       2      WM_SIZE_HINTS    41
;            ARC             3      WM_ZOOM_HINTS    42
;            ATOM            4      MIN_SPACE        43
;            BITMAP          5      NORM_SPACE       44
;            CARDINAL        6      MAX_SPACE        45
;            COLORMAP        7      END_SPACE        46
;            CURSOR          8      SUPERSCRIPT_X    47
;            CUT_BUFFER0     9      SUPERSCRIPT_Y    48
;            CUT_BUFFER1     10      SUBSCRIPT_X     49
;            CUT_BUFFER2     11      SUBSCRIPT_Y     50
;            CUT_BUFFER3     12      UNDERLINE_POSITION  51
;            CUT_BUFFER4     13      UNDERLINE_THICKNESS 52
;            CUT_BUFFER5     14      STRIKEOUT_ASCENT 53
;            CUT_BUFFER6     15      STRIKEOUT_DESCENT 54
;            CUT_BUFFER7     16      ITALIC_ANGLE     55
;            DRAWABLE        17      X_HEIGHT         56
;            FONT            18      QUAD_WIDTH       57
;            INTEGER         19      WEIGHT           58
;            PIXMAP          20      POINT_SIZE       59
;            POINT           21      RESOLUTION       60
;            RECTANGLE       22      COPYRIGHT        61
;            RESOURCE_MANAGER 23      NOTICE          62
;            RGB_COLOR_MAP   24      FONT_NAME        63
;            RGB_BEST_MAP    25      FAMILY_NAME      64
;            RGB_BLUE_MAP    26      FULL_NAME        65
;            RGB_DEFAULT_MAP 27      CAP_HEIGHT       66
;            RGB_GRAY_MAP    28      WM_CLASS         67
;            RGB_GREEN_MAP   29      WM_TRANSIENT_FOR 68
;            RGB_RED_MAP     30
;            STRING          31
;            VISUALID        32
;            WINDOW          33
;            WM_COMMAND      34
;            WM_HINTS        35
;            WM_CLIENT_MACHINE 36
;            WM_ICON_NAME    37
;            WM_ICON_SIZE    38
;            WM_NAME         39


; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success ecx
;      db reply 1=success 0=fail
;      db format
;      dw sequence#
;      dd reply length (dword count)
;      dd type
;      dd bytes-after
;      dd length of value
;         0 for format 0
;         n for format 8
;         n/2 for format 16
;         n/4 for format 32
;      times 12 unused
;      dd list of byte
;              
; NOTES
;   source file: x_get_property.asm
;<
; * ----------------------------------------------

  global x_get_property
x_get_property:
  push	ecx
  push	edx
  mov	[gpp_pki],eax	;save window
  mov	[gpp_pka],esi	;save property id
  mov	[gpp_pkx],edi	;save type
  mov	[gpp_buf],edx	;save max length?
%ifdef DEBUG
  extern crt_str
  mov	ecx,gpp_msg
  call	crt_str
%endif
  mov	ecx,gpp_pkt
  mov	edx,gpp_pkt_end - gpp_pkt
  neg	edx		;indicate reply expected
  call	x_send_request
  pop	edx
  pop	ecx
  js	gp_exit
  call	x_wait_big_reply
gp_exit:
  ret

;-------------------
  [section .data]
gpp_pkt:	db 20		;query pointer opcode
		db 0		;delete flag
		dw 6		;paket length
gpp_pki:	dd 0		;window
gpp_pka: 	dd 0		;property (ATOM)
gpp_pkx: 	dd 0		;type 
		dd 0		;long offset
gpp_buf:	dd 0		;long length
gpp_pkt_end:
  [section .text]
%ifdef DEBUG
gpp_msg: db 0ah,'get_property (14h)',0ah,0
%endif
