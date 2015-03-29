
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
;---------- window_create ------------------
%ifndef DEBUG
%include "../../include/window.inc"
%endif
  extern x_configure_window
;%include "x_configure_window.inc"

  extern x_map_win
  extern x_wait_event
  extern x_get_input_focus
  extern delay
  extern x_flush
  extern x_wm_hints
;%include "x_wm_hints.inc"

;---------------------
;>1 win_ctrl
;  window_create - create x window
;  Font and window size from window_pre can be used
;  to set window size and position.  From this the total
;  character rows and columns is calculated and the widow
;  is mapped (displayed).
;  
; INPUTS
;  function window_pre must be called first.
;  ebp = window block created by window_pre
;
;  esi = ptr to window size request as follows:
;        resw 1 ;x pixel column location
;        resw 1 ;y pixel row location
;        resw 1 ;screen width in pixels
;        resw 1 ;screen height in pixels
; OUTPUT:
;    error = sign flag set
;
;     The window is maped (visable)
;     Keyboard, mouse, and expose events are enabled.
;              
; NOTES
;   source file: window_create.asm
;<
; * ----------------------------------------------
;-------------------------------------------------

  global window_create
window_create:
  mov	[in_block_ptr],esi
;setup the win_block
  mov	eax,[esi+4]	;get window width and height
  mov	[ebp+win.s_win_width],eax

  mov	eax,[ebp+win.s_win_id]
  mov	ebx,0fh		;mask
  mov	esi,[in_block_ptr]
  call	x_configure_window
  js	wa_exit

  mov	eax,[ebp+win.s_win_id]
  mov	esi,[in_block_ptr]
  call	x_wm_hints

  mov	eax,[ebp+win.s_win_id]	;get our window id  
  call	x_map_win
  js	wa_exit

;compute total rows on screen
  movzx	eax,word [ebp+win.s_win_height]
  xor	edx,edx
  div	dword [ebp+win.s_char_height]
  mov	[ebp+win.s_text_rows],eax
  movzx	eax,word [ebp+win.s_win_width]
  xor	edx,edx
  div	dword [ebp+win.s_char_width]
  mov	[ebp+win.s_text_columns],eax
;
;We had problems with windows being blank in applications.
;The following code was added to fix this problem.

  call	x_wait_event		;wait for expose event

;the following call to focus_wait hangs on Fedora.  It
;times out because window does not start with focus.
;
;  call	focus_wait

wa_exit:
  ret
;------------------------------------------------------

;-----------------------
  [section .data]
looper db 0
  [section .text]

;------------------------
focus_wait:
wait_for_mapping:
  call	x_get_input_focus	;get focus
  js	wa_done
  mov	eax,[ebp+win.s_win_id]
  cmp	eax,[ecx+8]		;are we focused?
  je	wa_done
  mov	eax,2
  call	delay
  jmp	short wait_for_mapping
wa_done:
  ret
;-----------------
  [section .data]

in_block_ptr: dd 0

 [section .text]

