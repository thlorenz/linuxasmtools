
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
;  compute_samples_per_wave - compute samples per wave
; INPUT  ebx = frequency
;        eax = samples per second
; OUTPUT  eax = samples per wave or negative error
; NOTES
;   source file: compute_samples_per_wave
;<
; * ----------------------------------------------
  global compute_samples_per_wave
compute_samples_per_wave:
  xor	edx,edx
  div	ebx		;divide rate/freq
  and	eax,~1		;force even sample count
  ret
;----
