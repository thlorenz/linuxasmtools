
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
;  close_sound_device - close /dev/dsp
; INPUTS
;    none
; OUTPUT:
;    eax = negative kernel error if failure
; NOTES
;   source file: close_sound_device.asm
;<
; * ----------------------------------------------
%assign SYS_CLOSE       6
  extern device_handle

  global close_sound_device
close_sound_device:
  mov     dword eax, SYS_CLOSE
  mov     dword ebx, [device_handle]
  int     byte  080h
  ret
;----
