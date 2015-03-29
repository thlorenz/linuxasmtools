
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
;  open_sound_device - open /dev/dsp
; INPUTS
;    none
; OUTPUT:
;    eax = handle if success
;        = negative kernel error if failure
; NOTES
;   source file: open_sound_device.asm
;   This function is normally part of the following
;   series of functions:
;     open_sound_device
;     set_sound_device
;     compute_samples_per_wave
;     write_sound_device
;     flush_sound_device
;     close_sound_device
;   The sound device feeds a DAC (digital to analog
;   converter) and has several formats.  The data
;   sent to DAC forms a wave and the wave frequency
;   is determined by data amptitude.  For byte format,
;   80h is the wave center point, and the two extreems
;   are 00h and 0ffh
;<
; * ----------------------------------------------
%assign SYS_OPEN        5
%assign O_RDWR        000002q

  global open_sound_device
open_sound_device:
  mov     dword eax, SYS_OPEN
  mov     dword ebx, device
  mov     dword ecx, O_RDWR
  int     byte  080h
  mov	[device_handle],eax
  ret
;----
  [section .data]
device:         db      "/dev/dsp", 0
  global device_handle
device_handle	dd	0
  [section .text]
;----
