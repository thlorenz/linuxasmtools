
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
;  make_sound - play square wave
; INPUTS
;    eax = duration in ms
;    ebx = frequency of sound
; OUTPUT:
;    eax = negative if parameter error
; NOTES
;   source file: get_sound_status.asm
;   This function calls:
;     compute_wave_count
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
;   make_sound sets the byte format.
;<
; * ----------------------------------------------
  extern compute_wave_count
  extern open_sound_device
  extern compute_samples_per_wave
  extern lib_buf
  extern write_sound_device
  extern flush_sound_device
  extern close_sound_device
  extern set_sound_device
  
;
  global make_sound
make_sound:
  mov	[length],eax
  mov	[freq],ebx
  call	compute_wave_count 
  or	eax,eax
  jns	ms_10			;jmp if parameters ok
  jmp	ms_exit
ms_10:
  mov	[number_of_waves],eax	;save number of waves
  call	open_sound_device

  call	set_sound_device
  mov	[device_buf_size],eax	;save buffer size

  mov	ebx,[freq]		;hertz
  mov	eax,22050		;samples per second  
  call	compute_samples_per_wave;returns eax=samp/wave
  mov	[samples_per_wave],eax

sound_loop:
  mov	al,0ffh
  mov	edi,lib_buf
  mov	ecx,[samples_per_wave]
  shr	ecx,1			;divide by 2
  rep	stosb			;fill buffer
  mov	ecx,lib_buf
  mov	edx,[samples_per_wave]
  shr	edx,1
  call	write_sound_device

  mov	al,000h
  mov	edi,lib_buf
  mov	ecx,[samples_per_wave]
  shr	ecx,1			;divide by 2
  rep	stosb			;fill buffer
  mov	ecx,lib_buf
  mov	edx,[samples_per_wave]
  shr	edx,1
  call	write_sound_device

  dec	dword [number_of_waves]
  jnz	sound_loop
  
  call	flush_sound_device
  call	close_sound_device
ms_exit:
  ret
;-----
  [section .data]
freq	dd	0		;test value
length	dd	0		;length in mili-seconds
number_of_waves dd	0		;wave count
device_buf_size dd 0
samples_per_wave dd 0
samples_per_second dd 22050	;also in set_sound_device
  [section .text]
;----
