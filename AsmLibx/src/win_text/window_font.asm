
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
;---------- window_font ------------------

%ifndef DEBUG
%include "../../include/window.inc"
%endif
;%include "x_query_font.inc"
  extern x_query_font

  extern x_open_font
;%include "x_open_font.inc"

  extern x_change_gc_font
  extern x_send_request

  extern x_list_fonts
;%include "x_list_fonts.inc"

struc font
  resb 1  ;1			 Reply
  resb 1  ;			 unused
  resb 2  ;CARD16		 sequence number
  resb 4  ;7+2n+3m		 reply length
  resb 12 ;CHARINFO		 min-bounds
  resb 4  ;			 unused
  resb 12 ;CHARINFO		 max-bounds
  resb 4  ;			 unused
  resb 2  ;CARD16		 min-char-or-byte2
  resb 2  ;CARD16		 max-char-or-byte2
  resb 2  ;CARD16		 default-char
.num_prop:
  resb 2  ;n			 number of FONTPROPs in properties
  resb 1  ;			 draw-direction
;     0	       LeftToRight
;     1	       RightToLeft
  resb 1  ;CARD8		 min-byte1
  resb 1  ;CARD8		 max-byte1
  resb 1  ;BOOL		 all-chars-exist
.ascent:
  resb 2  ;INT16		 font-ascent
.descent:
  resb 2  ;INT16		 font-descent
  resb 4  ;m			 number of CHARINFOs in char-infos
;  8n LISTofFONTPROP	 properties
;  12m	       LISTofCHARINFOchar-infos
font_struc_len:
endstruc

;---------------------
;>1 win_text
;  window_font - set a new window font
; INPUTS
;  ebp = window block with following filled in:
;  .s_font - dword font width size code starting with 8
;               size codes are: 8,9,10,11,12,14
;  .s_font_id resd 1	;font id, set by window_pre,
;
; eax = buffer to hold font info (24000 bytes or more)
; edx = buffer size
;
; OUTPUT:
;    error = sign flag set for "js"
;    success - returns the following items in window block
;       .s_char_width  resd 1
;       .s_char_height resd 1
;              
; NOTES
;   source file: window_create.asm
;   If font selection fails, it may be necessary to try a
;   another font string.
;   Font alias are at /etc/X11/fonts/misc/xfonts-base.alias
;                     /usr/share/fonts/X11/misc/fonts.alias
;   If a fixed font of the desired width is not found, another
;   font may be selected, or an error returned.
;<
; * ----------------------------------------------

  global window_font
window_font:
  mov	[wf_buffer],eax
  mov	[wf_buf_size],edx
  mov	eax,[wf_font]		;previous font?
  or	eax,eax
  jz	wf_assign
  mov	ecx,close_font_pkt
  mov	edx,8			;packet length
  call	x_send_request
  xor	eax,eax
  mov	[wf_font],eax		;set no font open
wf_assign:
  mov	esi,[ebp+win.s_font]	;get font info
;esi is size code - 8,9,10,11,12,13,14,15,16
  sub	esi,8
  jns	wf_05
  jmp	wf_exit		;exit if error
wf_05:
  shl	esi,2		;make dword ptr
  add	esi,font_ptrs
  mov	esi,[esi]	;get ptr to font patterns  
got_strings:
  mov	eax,[wf_buffer]
  mov	edx,[wf_buf_size]
  call	x_list_fonts	;check if font can be found
  js	wf_exit			;exit if error
;esi now points to legal font pattern
  mov	eax,[ebp+win.s_font_id]
  call	x_open_font
  js	wf_exit			;exit if error
;000:<:000f: 28: Request(56): ChangeGC gc=0x02e00002  values={background=0x0000ffff
;  line-width=2 join-style=Bevel(0x02) font=0x02e00003}
  mov	ebx,[ebp+win.s_font_id]	;font id xx00003
  mov	[wf_font],ebx
  mov	eax,[ebp+win.s_cid_1]	;window gc id xx00002
  call	x_change_gc_font
  js	wf_exit

  mov	eax,[wf_font]		;get new font id
  mov	ebx,[wf_buffer]
  mov	edx,[wf_buf_size]
  call	x_query_font
  js	wf_exit
  mov	[ebp+win.s_char_width],eax
  mov	[ebp+win.s_char_height],ebx
  mov	[ebp+win.s_char_ascent],edx
wf_exit:
  or	eax,eax
  ret

;------------
  [section .data]
wf_buffer dd 0
wf_buf_size dd 0

close_font_pkt:
          db 46	;x opcode
	  db 0	;unused
	  dw 2	;request length
wf_font	  dd 0

font_ptrs:
 dd font8
 dd font9
 dd font10
 dd font11
 dd font12
 dd font13
 dd font14
 dd font15
 dd font16
 dd font17
 dd font18
;                  db '*-helvetica-*-18-*',0
;   Some font strings to try: '*-Times-*-14-*',0
;                             '*-fixed-bold-*-18-*',0
;                             '10x20*',0
;                             '*-fixed-*-20-*',0
;   

font8:  db "8x16",0,'8x*',0
font9:  db "9x15",0,'9x*',0
font10: db '10x20',0,'10x*',0
font11: db '11x22',0,'11x*',0
font12: db '12x24',0,'12x*',0
font13: db '13x*',0,'13*',0
font14: db '14x28',0,'14x*',0
font15: db '15x*',0
font16: db '16x32',0,'16x*',0
font17: db '17*',0
font18:	db '18*',0
	db '*-fixed-*-20-*',0
	db '*-fixed-*-24-*',0
	db 0				;end of table

  [section .text]
