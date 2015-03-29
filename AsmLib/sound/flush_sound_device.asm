
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
;  flush_sound_device - write remaining bytes
; INPUTS
;    [total_written] - dword of buffer write count
;    [gss_buf_size] - size of device buffer
; OUTPUT:
;    eax = number of bytes written
;        = negative kernel error if failure
; NOTES
;   source file: flush_sound_device.asm
;   This function is normally part of the following
;   series of functions:
;     open_sound_device
;     set_sound_device
;     compute_samples_per_wave
;     write_sound_device
;     flush_sound_device
;     close_sound_device
;<
; * ----------------------------------------------
  extern total_written
  extern gss_buf_size
  extern lib_buf
  extern write_sound_device

  global flush_sound_device
flush_sound_device:
  mov	eax,[gss_buf_size]
  sub	eax,[total_written]	;compute bytes remaining
fsd_loop:
  cmp	eax,700
  jbe	fsd_entry		;complete flush
  sub	eax,700
  push	eax
  mov	eax,700
  call	fsd_entry
  pop	eax
  jmp	short fsd_loop
fsd_entry:
  or	eax,eax
  jz	fsd_exit
  push	eax
  mov	ecx,eax
  mov	edi,lib_buf
  mov	al,80h
  rep	stosb
  pop	edx			;get output count
  mov	ecx,lib_buf
  call	write_sound_device
fsd_exit:
  ret  
