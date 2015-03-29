
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
;----------------------------------------------------------------
;>1 signal
;  signal_mask_get - get current signal mask
; INPUTS  none
; OUTPUT  eax (0) success
;             (-1) error 
;         ebx mask bits if eax=0
; NOTES
;    Source file: signal_mask.asm
;    Masked bit only apply to installed signals, not to default
;       handlers.
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signal_mask_get
signal_mask_get:
  mov	eax,126
  mov	ebx,0		;block bits "or" into  mask
  mov	ecx,zero_dword	;bits to block (none)
  mov	edx,mask	;save of old mask
  int	80h
  mov	ebx,[edx]	;get mask bits
  ret

  [section .data]
zero_dword dd	0
mask	   dd	0
  [section .text]

;----------------------------------------------------------------
;>1 signal
;  signal_mask_set - set signal mask (store) bits
; INPUTS  ecx = ptr to dword with signal bits
;               0000 0001 = signal 1
;               0001 0000 = signal 17
; OUTPUT  eax (0) success
;             (-1) error   
; NOTES
;    Source file: signal_mask.asm
;    Masked bit only apply to installed signals, not to default
;       handlers.
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signal_mask_set
signal_mask_set:
  mov	ebx,2		;set "set" flag
  jmp	short signal_mask


;----------------------------------------------------------------
;>1 signal
;  signal_mask_block - block signal handler (OR) into mask
; INPUTS  ecx = ptr to dword with signal bits
;               0000 0001 = signal 1
;               0001 0000 = signal 17
; OUTPUT  eax (0) success
;             (-1) error   
; NOTES
;    Source file: signal_mask.asm
;    Masked bit only apply to installed signals, not to default
;       handlers.
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signal_mask_block
signal_mask_block:
  mov	ebx,0		;set block flag
  jmp	short signal_mask


;----------------------------------------------------------------
;>1 signal
;  signal_mask_unblock - unblock signal handler (AND) with mask
; INPUTS  ecx = ptr to dword with signal bits
;               0000 0001 = signal 1
;               0001 0000 = signal 17
; OUTPUT  eax (0) success
;             (-1) error   
; NOTES
;    Source file: signal_mask.asm
;    Masked bit only apply to installed signals, not to default
;       handlers.
;    See file /err/install_signals for more documentation.
;<
; *  ----------------------------------------------
;*******
  global signal_mask_unblock
signal_mask_unblock:
  mov	ebx,1		;set unblock flag
signal_mask:
  mov	eax,126
  xor	edx,edx		;no save of old mask
  int	80h
  ret


  