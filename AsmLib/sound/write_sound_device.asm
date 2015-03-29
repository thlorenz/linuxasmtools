
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
;----------------------------------------------------------
;>1 sound
;  write_sound_device - write to /dev/dsp
; INPUTS
;    ecx = sample buffer ptr
;    edx = number of bytes to write
;    global [gss_buf_size]
; OUTPUT:
;    eax = number of bytes written
;        = negative kernel error if failure
; NOTES
;   source file: write_sound_device.asm
;<
; * ----------------------------------------------
%assign SYS_WRITE       4
  extern gss_buf_size
  extern device_handle

  global write_sound_device
write_sound_device:
  mov     dword eax, SYS_WRITE
  mov     dword ebx, [device_handle]
  int     byte  080h
  or	eax,eax
  js	wsd_exit
  add	[total_written],eax
  mov	ebx,[gss_buf_size]
  cmp	ebx,[total_written]
  ja	wsd_exit		;jmp if flush count ok
  sub	[total_written],ebx	;adjust total count
wsd_exit:
  ret
;----
  [section .data]
  global total_written
total_written dd 0
  [section .text]
