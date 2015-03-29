
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
;  set_sound_device - mono mode, byte data, samp rate 22050
; INPUTS
;    none
; OUTPUT:
;    eax = device buffer size
;          also in global [gss_buf_size]
; NOTES
;   source file: set_sound_device.asm
;<
; * ----------------------------------------------
%assign SYS_CLOSE       6
  extern total_written

  extern device_handle

  global set_sound_device
set_sound_device:
  mov	[total_written], dword 0

  mov	eax,54		;ioctl kernel call
  mov	ebx,[device_handle]
  mov	ecx,00005000h	;reset
  mov	edx,0
  int	byte 80h

  mov	eax,54		;ioctl kernel call
  mov	ebx,[device_handle]
  mov	ecx,0c0045005h	;SNDCTL_DSP_SETFMT
  mov	edx,snd_format1
  int	byte 80h	;set byte sample mode

  mov	eax,54		;ioctl kernel call
  mov	ebx,[device_handle]
  mov	ecx,0c0045003h	;SNDCTL_DSP_STEREO
  mov	edx,snd_stereo
  int	byte 80h	;set mono mode

  mov   dword eax, 54	;ioctl kernel call
  mov	ebx,[device_handle]
  mov	ecx,0c0045002h	;SOUND_PCM_READ_RATE
  mov	edx,gss_rate
  int	byte 80h	;set rate to 22050 samples/sec
;get device buffer size
  mov	eax,54		;ioctl kernel call
  mov	ebx,[device_handle]
  mov	ecx,0c0045004h	;SNDCL_DSP_GETBLKSIZE
  mov	edx,gss_buf_size
  int	byte 80h	;request gss_buf_size
  mov	eax,[gss_buf_size]
  ret
;----------
  [section .data]
  global gss_buf_size
gss_buf_size:	dd	0
snd_format1:	dd	8	;byte mode
snd_stereo:	dd	0	;mono
gss_rate:	dd	22050	;sample rate, samples per second
  [section .text]
