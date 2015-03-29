
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

;------------------ send_keys_to_window.inc -----------------------

  extern key_translate_table
  extern x_get_input_focus
  extern activate_window
  extern xtest_fake_input
  extern ascii_to_xkey
  extern xtest_version
;---------------------
;>1 xtest
;  send_keys_to_window - send keystrokes to window
; INPUTS
;  eax = window id
;  esi = key string terminated with 0
; OUTPUT:
;  eax = error code if failure
; NOTES
;   source file: send_keys_to_window
;<
; * ----------------------------------------------

  global send_keys_to_window
send_keys_to_window:
  mov	[target_window],eax
  mov	[key_string_ptr],esi
  call	x_get_input_focus
  mov	[initial_window],eax	;save current widow
  call	xtest_version
;switch to target window
  mov	eax,[target_window]
  call	activate_window
  js	sktw_restore		;jmp if error
  mov	esi,[key_string_ptr]
sktw_lp:
  lodsb				;get next key
  or	al,al
  jz	sktw_restore		;jmp if done
;translate key to x code
  push	esi
  call	ascii_to_xkey
  pop	esi
  js	sktw_restore		;jmp if error
sktw_send:
  push	esi
  call	xtest_fake_input
  pop	esi
  jns	sktw_lp
sktw_restore:
  push	eax
  mov	eax,[initial_window]
  call	activate_window
  pop	eax
  or	eax,eax
  ret

;--------
  [section .data]
target_window	dd 0
initial_window	dd 0
key_string_ptr	dd 0

  [section .text]


%ifdef DEBUG
  extern env_stack
  extern x_connect
  extern window_find
  global _start
_start:
  call	env_stack
  call	x_connect
;find xterm window
  mov	al,3		;search for class
  mov	ebx,class_string
  mov	ecx,buffer
  mov	edx,1000	;buffer length
  call	window_find
  mov	eax,[buffer]	;get window id
;  call	x_get_input_focus
  mov	bl,0
  mov	esi,keys
  call	send_keys_to_window
  mov	eax,1
  int	byte 80h

;--------
  [section .data]
keys:  db 'hH',0
class_string db 'xterm',0
buffer	times 1000 db 0
  [section .text]
%endif